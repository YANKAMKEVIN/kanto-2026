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
##  - Nouvelle partie : confirmation si une sauvegarde valide existe, puis rideau,
##    [signal title_closed], **introduction du Prof. Chen** (OUV.2 : [signal intro_opened], Boot
##    pose le labo en mode décor ; [IntroStage] + [IntroPlayer] sur la boîte de dialogue du jeu,
##    prénoms du joueur et du rival **en mémoire seulement**) ; à la fin de la dernière réplique,
##    **commit** ([OpeningCommit] : copie `save.previous.json`, construction de la partie par le
##    [Callable] de Boot **avec les prénoms choisis**, écriture atomique), puis (OUV.3) le
##    portrait du joueur rétrécit et se dissout, fondu au blanc chaud, [signal intro_closed] et [signal new_game_entered] ; avec une sauvegarde d'une version plus
##    récente, rien n'est écrit. Abandon (application tuée) pendant l'introduction : rien n'a été
##    écrit, l'ancienne sauvegarde est intacte (§3.7) ;
##  - Paramètres : le [SettingsScreen] sans « Sauvegarder maintenant » ; chaque réglage changé est
##    relayé à Boot ([signal settings_changed]) qui l'écrit dans `settings.json` et l'applique.
## [method autosave_allowed] est **la** garde d'autosave de Boot : faux tant que la partie n'est
## pas reprise ou écrite (titre, Paramètres, confirmation, commit, arrière-plan compris).

## On quitte le titre (rideau baissé) : le décor doit être libéré, **avant** le commit ou la
## reprise.
signal title_closed
## Introduction (OUV.2) : rideau baissé, titre retiré ; Boot pose le décor du labo.
signal intro_opened
## Fin de l'introduction (après le commit, rideau baissé) : Boot libère le décor du labo.
signal intro_closed
## Continuer : la partie lue au lancement (déjà migrée), à charger dans l'état.
signal resumed(save: Dictionary)
## Nouvelle partie construite (et écrite si permis) : entrer dans la chambre. [param warning] :
## message à montrer (échec d'écriture, « unsaved ») ou "".
signal new_game_entered(warning: String)
## Un réglage a changé depuis le titre (à écrire et appliquer).
signal settings_changed(settings: GameSettings)

const TITLE_SCENE: PackedScene = preload("res://game/ui/opening/title_screen.tscn")
const INTRO_STAGE_SCENE: PackedScene = preload("res://game/ui/opening/intro_stage.tscn")
## Boîte de dialogue créée par le directeur quand on ne lui en donne pas (tests sans Boot).
const DIALOGUE_BOX_SCENE: PackedScene = preload("res://game/ui/dialogue/dialogue_box.tscn")
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
## Introduction (OUV.2) : la boîte de dialogue du jeu (Boot), la scène et son lecteur.
var _box: DialogueBox
var _intro_script := IntroScript.new()
var _stage: IntroStage
var _intro: IntroPlayer
var _backdrop_blur: bool = true
## Prénoms choisis dans l'introduction (vides : défauts de [OpeningNames]).
var _player_name: String = ""
var _rival_name: String = ""
## Vrai une fois la fin de l'introduction jouée (rideau blanc chaud) : la chambre apparaît depuis
## le blanc ([method entry_fade_time]).
var _sent_off: bool = false


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


## Boîte de dialogue de l'introduction (celle du jeu). Sans elle, le directeur crée la sienne.
func set_dialogue_box(box: DialogueBox) -> void:
	_box = box


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
		_fade.fade_in(fade_time(UiTokens.TITLE_FADE_IN))


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
	if _intro != null:
		# Introduction : le clavier se ferme, puis rien (§5.5).
		_intro.handle_back()
		return true
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
	_backdrop_blur = backdrop_blur
	if _stage != null:
		_stage.set_backdrop_blur(backdrop_blur)
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


## Scène de l'introduction (null hors de l'introduction).
func get_intro_stage() -> IntroStage:
	return _stage


## Lecteur de l'introduction (null hors de l'introduction).
func get_intro() -> IntroPlayer:
	return _intro


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


## Nouvelle partie : rideau, titre retiré, puis l'introduction (OUV.2) sur le labo en mode décor.
## Script illisible (données en erreur) : on passe directement au commit avec les prénoms par
## défaut, comme en OUV.1, plutôt que de bloquer la partie.
func _play_intro() -> void:
	await _close_title()
	if not _intro_script.is_loaded() and not _intro_script.load_file():
		push_error("Ouverture : introduction illisible, prénoms par défaut")
		_on_intro_finished("", "")
		return
	intro_opened.emit()
	if _box == null:
		_box = DIALOGUE_BOX_SCENE.instantiate() as DialogueBox
		add_child(_box)
	_stage = INTRO_STAGE_SCENE.instantiate() as IntroStage
	_stage.speed_scale = speed_scale
	_stage.reduce_motion = _settings != null and _settings.reduce_motion
	add_child(_stage)
	_stage.set_backdrop_blur(_backdrop_blur)
	_intro = IntroPlayer.new()
	_intro.name = "IntroPlayer"
	_intro.chars_per_second = _settings.chars_per_second() if _settings != null \
		else UiTokens.DIALOG_CHARS_PER_SECOND
	add_child(_intro)
	_intro.setup(_intro_script, _names, _stage, _box)
	_intro.finished.connect(_on_intro_finished)
	print("Ouverture : introduction du Prof. Chen")
	if _fade != null:
		_fade.set_opaque(true)
		_fade.fade_in(fade_time(UiTokens.INTRO_FADE_IN))
	_intro.start()


## Fin de la dernière réplique de Chen (§3.7) : commit **avant** toute animation, avec les prénoms
## choisis ; puis rétrécissement et blanc chaud ([method _send_off], OUV.3), introduction retirée,
## [signal intro_closed], chambre (Boot la montre en fondu depuis le blanc).
func _on_intro_finished(player_name: String, rival_name: String) -> void:
	_player_name = player_name
	_rival_name = rival_name
	_leaving = true
	_flow.handle(OpeningFlow.Action.INTRO_FINISHED)
	var effects := _flow.take_effects()
	if effects.has(OpeningFlow.Effect.WRITE_NEW_GAME):
		_commit()
		effects = _flow.take_effects()
	if effects.has(OpeningFlow.Effect.WARN_UNSAVED):
		_warning = _texts.text(TitleTexts.GROUP_MESSAGES, &"unsaved")
	if _fade != null and _intro != null:
		await _send_off()
	_close_intro()
	if effects.has(OpeningFlow.Effect.ENTER_BEDROOM):
		if not _built:
			_build_once()
		_finished = true
		new_game_entered.emit(_warning)


## Introduction retirée (scène et lecteur), puis [signal intro_closed].
func _close_intro() -> void:
	if _intro != null:
		remove_child(_intro)
		_intro.queue_free()
		_intro = null
	if _stage != null:
		remove_child(_stage)
		_stage.queue_free()
		_stage = null
	intro_closed.emit()


## Fin de l'introduction (OUV.3, dossier 13 §4 plans 8 et 9), **après** le commit : le portrait
## du joueur rétrécit et se dissout dans la lumière ([method IntroStage.send_off]) ; au milieu du
## rétrécissement part le **fondu au blanc chaud** ; rend la main quand le blanc est opaque.
## « Réduire les animations » : pas de rétrécissement, fondu au blanc direct et raccourci.
## Rien n'est écrit ici : un abandon pendant l'animation laisse la nouvelle partie (déjà écrite
## dans la chambre), jamais un entre-deux.
func _send_off() -> void:
	_sent_off = true
	var shrink := _stage.send_off() if _stage != null else 0.0
	var lead := shrink * UiTokens.INTRO_SEND_OFF_LEAD
	if lead > 0.0:
		await create_tween().tween_interval(lead).finished
	await _fade.fade_out(fade_time(UiTokens.INTRO_WHITE_OUT), UiTokens.INTRO_WHITE)


## Durée du fondu d'entrée dans la partie (Boot) : depuis le blanc chaud après l'introduction,
## depuis le noir après Continuer (ou une introduction illisible).
func entry_fade_time() -> float:
	if _sent_off:
		return fade_time(UiTokens.INTRO_WHITE_IN)
	return fade_time(UiTokens.TITLE_GAME_FADE_IN)


## Durée d'un fondu de l'ouverture : [param base] × [member speed_scale], raccourcie par « Réduire
## les animations » (× INTRO_REDUCED, dossier 13 §7).
func fade_time(base: float) -> float:
	var reduced := _settings != null and _settings.reduce_motion
	return base * speed_scale * (UiTokens.INTRO_REDUCED if reduced else 1.0)


## Continuer : rideau, titre fermé, reprise.
func _leave_title() -> void:
	await _close_title()
	_run_effects(_flow.take_effects())


## Coroutine : rideau baissé, écran titre retiré, [signal title_closed].
func _close_title() -> void:
	_leaving = true
	if _fade != null:
		await _fade.fade_out(fade_time(UiTokens.TITLE_FADE_OUT))
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
				_commit()
				_run_effects(_flow.take_effects())
				return
			OpeningFlow.Effect.ENTER_BEDROOM:
				if not _built:
					_build_once()
				_finished = true
				new_game_entered.emit(_warning)


## Le commit (dossier 13 §3.7) ; le flux passe en DONE (ses effets restent à prendre).
func _commit() -> void:
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


func _build_once() -> Dictionary:
	_built = true
	if not _build_new_game.is_valid():
		return {}
	var player_name := _player_name if not _player_name.is_empty() \
		else _names.default_name(OpeningNames.ROLE_PLAYER)
	var rival_name := _rival_name if not _rival_name.is_empty() \
		else _names.default_name(OpeningNames.ROLE_RIVAL)
	var built: Variant = _build_new_game.call(player_name, rival_name)
	return built if built is Dictionary else {}
