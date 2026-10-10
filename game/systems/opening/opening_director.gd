class_name OpeningDirector
extends Node
## Directeur de l'ouverture (OUV.1, dossier 13 §3.1, §3.7, §5 ; docs/tech/ouverture.md §3).
##
## Créé par Boot **seulement** quand Boot est la scène principale lancée par le moteur, sans
## départ de débogage. Il tient la machine d'états ([OpeningFlow]) et le contenu du titre
## ([TitleMenuModel]), montre l'écran ([TitleScreen]) et **exécute les effets** :
##  - au lancement ([method run]) : lecture de la sauvegarde (une corrompue est mise de côté par
##    [SaveSystem], comme avant) ; **aucune écriture** ensuite tant que le titre est affiché ;
##  - Continuer : rideau, [signal title_closed] (Boot libère le décor), puis [signal resumed] avec
##    le dictionnaire lu ;
##  - Nouvelle partie : confirmation si une sauvegarde valide existe, puis (OUV.1, provisoire :
##    l'introduction arrive en OUV.2) rideau, [signal title_closed], **commit** ([OpeningCommit] :
##    copie `save.previous.json`, construction de la partie par le [Callable] de Boot, écriture
##    atomique) et [signal new_game_entered] ; avec une sauvegarde d'une version plus récente, rien
##    n'est écrit ;
##  - Paramètres : le [SettingsScreen] sans « Sauvegarder maintenant » ; chaque réglage changé est
##    relayé à Boot ([signal settings_changed]) qui l'écrit dans `settings.json` et l'applique.
## [method autosave_allowed] est **la** garde d'autosave de Boot : faux tant que la partie n'est
## pas reprise ou écrite (titre, Paramètres, confirmation, commit, arrière-plan compris).

## On quitte le titre (rideau baissé) : le décor doit être libéré, **avant** le commit ou la
## reprise.
signal title_closed
## Continuer : la partie lue au lancement (déjà migrée), à charger dans l'état.
signal resumed(save: Dictionary)
## Nouvelle partie construite (et écrite si permis) : entrer dans la chambre. [param warning] :
## message à montrer (échec d'écriture, « unsaved ») ou "".
signal new_game_entered(warning: String)
## Un réglage a changé depuis le titre (à écrire et appliquer).
signal settings_changed(settings: GameSettings)

const TITLE_SCENE: PackedScene = preload("res://game/ui/opening/title_screen.tscn")
## Suffixe de la copie de sécurité d'une nouvelle partie, à côté de la sauvegarde
## (`user://save.json` → `user://save.previous.json`, [constant OpeningCommit.PREVIOUS_PATH]).
const PREVIOUS_SUFFIX: String = ".previous.json"

## Durées multipliées (0 = instantané, pour les tests) : fondus et écrans.
var speed_scale: float = 1.0

var _flow: OpeningFlow
var _model: TitleMenuModel
var _texts := TitleTexts.new()
var _names := OpeningNames.new()
var _save: SaveSystem
var _save_content: Dictionary = {}
## `func(player_name: String, rival_name: String) -> Dictionary` : prépare la nouvelle partie
## dans l'état du jeu et rend son dictionnaire de sauvegarde (Boot).
var _build_new_game: Callable
var _built: bool = false
var _fade: ScreenFade
var _settings: GameSettings
var _device_quality: GameSettings.Graphics = GameSettings.Graphics.HIGH
var _zone_name_of: Callable
var _badge_flags: Array[StringName] = []
var _screen: TitleScreen
## Vrai pendant la sortie du titre (rideau) : plus aucun toucher n'est pris.
var _leaving: bool = false
## Vrai une fois la partie reprise ou la nouvelle partie construite.
var _finished: bool = false
var _warning: String = ""
var _last_commit: int = -1


## Branche le directeur avant [method run]. [param save_system] : la sauvegarde (null : aucune,
## rien n'est jamais écrit). [param zone_name_of] : `func(map_id) -> String` ; [param badge_flags]
## : drapeaux des badges (carte Continuer).
func setup(save_system: SaveSystem, build_new_game: Callable, fade: ScreenFade,
		settings: GameSettings, device_quality: GameSettings.Graphics, zone_name_of: Callable,
		badge_flags: Array[StringName]) -> void:
	_save = save_system
	_build_new_game = build_new_game
	_fade = fade
	_settings = settings
	_device_quality = device_quality
	_zone_name_of = zone_name_of
	_badge_flags = badge_flags


## Lit la sauvegarde, construit le titre et le montre (fondu depuis le noir).
func run() -> void:
	_texts.load_file()
	_names.load_file()
	var status := OpeningFlow.SaveStatus.NONE
	if _save != null and _save.has_save():
		_save_content = _save.read()
		status = OpeningFlow.status_from_read(_save.last_status)
	_flow = OpeningFlow.new(status)
	var summary: SaveSummary = null
	if status == OpeningFlow.SaveStatus.VALID:
		summary = SaveSummary.from_save(_save_content, _zone_name_of, _badge_flags,
			_names.default_name(OpeningNames.ROLE_PLAYER))
	_model = TitleMenuModel.build(status, summary, _texts)
	_screen = TITLE_SCENE.instantiate() as TitleScreen
	_screen.speed_scale = speed_scale
	add_child(_screen)
	_screen.entry_chosen.connect(choose)
	_screen.confirm_chosen.connect(confirm)
	_screen.settings_back_requested.connect(handle_back)
	_screen.setting_changed.connect(change_setting)
	_screen.show_title(_model)
	if _settings != null:
		_screen.set_left_handed(_settings.left_handed)
	print("Ouverture : titre (sauvegarde %s)" % OpeningFlow.SaveStatus.find_key(status))
	if _fade != null:
		_fade.set_opaque(true)
		_fade.fade_in(UiTokens.TITLE_FADE_IN * speed_scale)


## Une entrée du titre est touchée.
func choose(entry: StringName) -> void:
	if _leaving or _finished or _flow == null:
		return
	match entry:
		TitleMenuModel.ENTRY_CONTINUE:
			if _flow.handle(OpeningFlow.Action.CONTINUE):
				_leave_title()
		TitleMenuModel.ENTRY_NEW_GAME:
			if not _flow.handle(OpeningFlow.Action.NEW_GAME):
				return
			if _flow.screen() == OpeningFlow.Screen.CONFIRM_OVERWRITE:
				_screen.show_confirm(_confirm_view())
			else:
				_play_intro()
		TitleMenuModel.ENTRY_SETTINGS:
			if _flow.handle(OpeningFlow.Action.SETTINGS):
				_show_settings()


## Réponse de la carte de confirmation (vrai : « Nouvelle partie »).
func confirm(confirmed: bool) -> void:
	if _leaving or _flow == null or _flow.screen() != OpeningFlow.Screen.CONFIRM_OVERWRITE:
		return
	if confirmed:
		_flow.handle(OpeningFlow.Action.CONFIRM)
		_play_intro()
	else:
		_flow.handle(OpeningFlow.Action.CANCEL)


## Retour (Android, Échap, « ‹ » des Paramètres) : ferme les Paramètres ou la confirmation ;
## sans effet au titre (jamais de sortie du jeu, §5.2). Vrai si l'ouverture l'a pris (toujours,
## tant qu'elle est active).
func handle_back() -> bool:
	if _finished or _flow == null:
		return false
	if _leaving:
		return true
	match _flow.screen():
		OpeningFlow.Screen.SETTINGS:
			_flow.handle(OpeningFlow.Action.BACK)
			_screen.hide_settings()
		OpeningFlow.Screen.CONFIRM_OVERWRITE:
			_flow.handle(OpeningFlow.Action.BACK)
			_screen.hide_confirm()
	return true


## Un réglage changé dans les Paramètres du titre : appliqué aux réglages courants, relayé à Boot
## (écriture de `settings.json`, effet), puis la vue est rafraîchie.
func change_setting(key: StringName, value: Variant) -> void:
	if _settings == null or _flow == null or _flow.screen() != OpeningFlow.Screen.SETTINGS:
		return
	if not _settings.set_value(key, value):
		return
	settings_changed.emit(_settings)
	_show_settings()


## Réglages appliqués (Boot, à chaque changement) : main du joueur, flou du fond.
func apply_settings(settings: GameSettings, backdrop_blur: bool) -> void:
	_settings = settings
	if _screen != null:
		_screen.set_left_handed(settings.left_handed)
		_screen.set_backdrop_blur(backdrop_blur)
		UiPrefsApplier.apply(_screen)


## La garde d'autosave de Boot : vrai seulement quand la partie est stable sur le disque
## (reprise, ou nouvelle partie écrite) ; faux au titre, dans les Paramètres, la confirmation,
## pendant la sortie du titre et le commit, après un échec d'écriture, et toujours avec une
## sauvegarde d'une version plus récente.
func autosave_allowed() -> bool:
	return _finished and _flow != null and _flow.autosave_allowed()


## Vrai tant que l'ouverture occupe l'écran (le jeu n'a pas encore démarré).
func is_active() -> bool:
	return _flow != null and not _finished


func is_finished() -> bool:
	return _finished


func get_flow() -> OpeningFlow:
	return _flow


func get_model() -> TitleMenuModel:
	return _model


## L'écran titre (null une fois le titre quitté).
func get_screen() -> TitleScreen:
	return _screen


## Résultat du dernier commit ([enum OpeningCommit.Result]), -1 s'il n'y en a pas eu.
func get_last_commit() -> int:
	return _last_commit


## Chemin de la copie de sécurité pour la sauvegarde [param save_path].
static func previous_path_for(save_path: String) -> String:
	return save_path.get_basename() + PREVIOUS_SUFFIX


func _show_settings() -> void:
	_screen.show_settings(SettingsViews.build(_settings if _settings != null
		else GameSettings.new(), _device_quality, false, false))


func _confirm_view() -> ChoiceView:
	var view := ChoiceView.new(_model.confirm_title, _model.confirm_accept,
		_model.confirm_cancel)
	var lines := PackedStringArray()
	for line: String in [_model.confirm_summary, _model.confirm_body]:
		if not line.is_empty():
			lines.append(line)
	view.detail = "\n".join(lines)
	return view


## OUV.1, provisoire : pas encore d'introduction (OUV.2) ; Nouvelle partie va droit au commit,
## avec les prénoms par défaut, puis à la chambre.
func _play_intro() -> void:
	await _close_title()
	_flow.handle(OpeningFlow.Action.INTRO_FINISHED)
	_run_effects(_flow.take_effects())


## Continuer : rideau, titre fermé, reprise.
func _leave_title() -> void:
	await _close_title()
	_run_effects(_flow.take_effects())


## Coroutine : rideau baissé, écran titre retiré, [signal title_closed].
func _close_title() -> void:
	_leaving = true
	if _fade != null:
		await _fade.fade_out(UiTokens.TITLE_FADE_OUT * speed_scale)
	if _screen != null:
		remove_child(_screen)
		_screen.queue_free()
		_screen = null
	title_closed.emit()


func _run_effects(effects: Array[OpeningFlow.Effect]) -> void:
	if effects.has(OpeningFlow.Effect.WARN_UNSAVED):
		_warning = _texts.text(TitleTexts.GROUP_MESSAGES, &"unsaved")
	for effect: OpeningFlow.Effect in effects:
		match effect:
			OpeningFlow.Effect.RESUME_SAVE:
				_finished = true
				resumed.emit(_save_content)
			OpeningFlow.Effect.WRITE_NEW_GAME:
				# La copie de sécurité (BACKUP_PREVIOUS) fait partie du commit.
				_write_new_game()
				return
			OpeningFlow.Effect.ENTER_BEDROOM:
				if not _built:
					_build_once()
				_finished = true
				new_game_entered.emit(_warning)


## Le commit (dossier 13 §3.7), puis la suite du flux selon son résultat.
func _write_new_game() -> void:
	var ok := false
	if _save != null:
		var commit := OpeningCommit.new(_save.fs, _save.path, previous_path_for(_save.path))
		_last_commit = commit.run(_build_once)
		ok = _last_commit == OpeningCommit.Result.OK
		if ok:
			print("Ouverture : nouvelle partie écrite (%s)" % _save.path)
		else:
			push_warning("Ouverture : nouvelle partie NON écrite (%s) : %s"
				% [OpeningCommit.Result.find_key(_last_commit), commit.last_error])
	_flow.handle(OpeningFlow.Action.COMMIT_SUCCEEDED if ok
		else OpeningFlow.Action.COMMIT_FAILED)
	_run_effects(_flow.take_effects())


func _build_once() -> Dictionary:
	_built = true
	if not _build_new_game.is_valid():
		return {}
	var built: Variant = _build_new_game.call(_names.default_name(OpeningNames.ROLE_PLAYER),
		_names.default_name(OpeningNames.ROLE_RIVAL))
	return built if built is Dictionary else {}
