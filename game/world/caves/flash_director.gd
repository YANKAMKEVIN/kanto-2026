class_name FlashDirector
extends Node
## Mise en scène automatique de Flash à l'arrivée sur une carte obscure (jalon 17 T24 ; dossier
## 20 §8.1, H-7 ; `jalon-17.md` §2.11 ; contrat commun avec le J18, `jalon-18.md` §3.3). Possédé
## par Boot, un seul pour tout le jeu. **Aucune règle ici** : l'action d'arrivée vient de
## [method FlashRules.entry_action], la disponibilité et le lanceur de [FieldMoves] (rappel
## [member check_flash] posé par Boot).
##
## Arrivée (écran visible, partie stable — sinon l'action attend : [member can_start]) :
## - AUTO : verrou du joueur ([constant LOCK_REASON]) → le Pokémon apparaît (le compagnon s'il
##   est le lanceur : petit saut et « ♪ » ; sinon, espèce à planche peinte : il sort de sa Ball
##   sur la case derrière le joueur ; sinon rien) → bandeau « {pokemon} utilise Flash ! » (T-17,
##   légende du HUD) → éclair ([ScreenFlash]) → [method DarknessController.open] → verrou levé,
##   [signal flash_used]. Durée ≈ [constant APPEAR] + un éclair + l'ouverture (≈ 1,2 s).
## - WARN : le dialogue [constant WARN_DIALOGUE] (T-3 du dossier 21), s'il existe dans les données.
## Une fois par arrivée ; rien n'est sauvegardé. Attentes en tweens (temps simulable en test).

## Mise en scène commencée (verrou posé) : Boot rafraîchit les contrôles.
signal cue_started
## Halo ouvert, verrou levé : fin de la mise en scène sur [param map_id].
signal flash_used(map_id: StringName)

## Raison du verrou du joueur pendant la mise en scène ([method Player.set_input_enabled]).
const LOCK_REASON: StringName = &"flash"
const MOVE: StringName = &"flash"
## Avertissement sans Flash (dossier 21 T-3, validé ; `data/dialogues/dark_caves.json`).
const WARN_DIALOGUE: StringName = &"dark_cave_too_dark"
## Temps laissé à l'apparition du Pokémon avant le bandeau (s) [D] : celui de sa sortie de Ball.
const APPEAR: float = Companion.BURST
## Tenue du bandeau (s) [D] : il reste lisible pendant l'éclair et l'ouverture du halo.
const BANNER_HOLD: float = 1.2

## Rappel () -> FieldMoves.Result : état de Flash pour la partie en cours (posé par Boot).
var check_flash: Callable
## Rappel () -> bool : vrai quand une action d'arrivée peut commencer (partie stable).
var can_start: Callable
## « Réduire les animations » : saut et sortie de Ball adoucis (l'ouverture, elle, suit le
## réglage du [DarknessController]).
var reduce_motion: bool = false

## État de la partie (GameState ou un double de test) : son équipe.
var _state: Node
var _darkness: DarknessController
var _caves: CaveLibrary
var _field_moves: FieldMoves
var _hud: ExplorationHud
var _runner: DialogueRunner
var _library: DialogueLibrary
var _player: Player
var _companion: CompanionController
var _catalog: CompanionCatalog
var _map: GameMap
var _pending: FlashRules.Entry = FlashRules.Entry.NONE
var _running: bool = false
var _tween: Tween
var _cameo: Companion
## Nombre de mises en scène jouées depuis le lancement (QA, tests : « une fois par arrivée »).
var _cue_count: int = 0


func _init() -> void:
	name = "FlashDirector"
	set_process(false)


func _process(_delta: float) -> void:
	if _pending != FlashRules.Entry.NONE and (not can_start.is_valid() or can_start.call()):
		var action := _pending
		_pending = FlashRules.Entry.NONE
		set_process(false)
		_run(action)


func setup(state: Node, darkness: DarknessController, caves: CaveLibrary,
		field_moves: FieldMoves, hud: ExplorationHud, runner: DialogueRunner,
		library: DialogueLibrary, player: Player, companion: CompanionController,
		catalog: CompanionCatalog) -> void:
	_state = state
	_darkness = darkness
	_caves = caves
	_field_moves = field_moves
	_hud = hud
	_runner = runner
	_library = library
	_player = player
	_companion = companion
	_catalog = catalog


## Vrai si Flash est disponible pour la partie en cours (CS05 au Sac, un Pokémon compatible).
func is_available() -> bool:
	return _check().state == FieldMoves.State.READY


## Nouvelle carte (écran noir) : une mise en scène en attente ou en cours est abandonnée.
func on_map_changed(_map_changed: GameMap) -> void:
	cancel()


## Arrivée sur [param map] depuis [param from_map] (&"" : démarrage) : action d'arrivée, jouée
## dès que la partie est stable.
func on_map_entered(map: GameMap, from_map: StringName) -> void:
	cancel()
	_map = map
	var map_id := map.map_id if is_instance_valid(map) else &""
	_pending = FlashRules.entry_action(from_map, map_id, _caves, is_available())
	set_process(_pending != FlashRules.Entry.NONE)


## Abandonne l'action en attente ou la mise en scène en cours (verrou levé, Pokémon retiré).
func cancel() -> void:
	_pending = FlashRules.Entry.NONE
	set_process(false)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _darkness != null and _darkness.opened.is_connected(_on_opened):
		_darkness.opened.disconnect(_on_opened)
	_free_cameo()
	if _running:
		_running = false
		if is_instance_valid(_player):
			_player.set_input_enabled(true, LOCK_REASON)


## Vrai pendant la mise en scène (verrou posé).
func is_running() -> bool:
	return _running


## Vrai si une action d'arrivée attend que la partie soit stable.
func is_pending() -> bool:
	return _pending != FlashRules.Entry.NONE


func get_cue_count() -> int:
	return _cue_count


## Pokémon montré hors compagnon pendant la mise en scène (null sinon).
func get_cameo() -> Companion:
	return _cameo


func _check() -> FieldMoves.Result:
	if check_flash.is_valid():
		var result: Variant = check_flash.call()
		if result is FieldMoves.Result:
			return result
	return FieldMoves.Result.new()


func _run(action: FlashRules.Entry) -> void:
	match action:
		FlashRules.Entry.AUTO:
			_play_cue()
		FlashRules.Entry.WARN:
			if _runner != null and _library != null and _library.has_dialogue(WARN_DIALOGUE):
				_runner.play(WARN_DIALOGUE, null, _map)


func _play_cue() -> void:
	var result := _check()
	_running = true
	_cue_count += 1
	_player.set_input_enabled(false, LOCK_REASON)
	_show_user(result)
	cue_started.emit()
	var reduced := _hud != null and _hud.get_screen_flash().reduced
	_tween = create_tween()
	_tween.tween_interval(APPEAR)
	_tween.tween_callback(_show_banner.bind(result.pokemon_name))
	_tween.tween_callback(_flash_screen)
	_tween.tween_interval(ScreenFlash.duration_of(1, reduced))
	_tween.tween_callback(_open_halo)


## Le Pokémon lanceur apparaît : le compagnon montré s'il est le lanceur (petit saut, « ♪ ») ;
## sinon, une espèce à planche peinte sort de sa Ball derrière le joueur (case libre) ; sinon
## rien (le bandeau le nomme). Case : [method _cameo_cell].
func _show_user(result: FieldMoves.Result) -> void:
	var party: Party = _state.get(&"party") if _state != null else null
	var user := party.get_at(result.pokemon_index) if party != null else null
	if user == null:
		return
	if _companion != null and _companion.is_shown() and _companion.get_chosen() == user:
		_companion.get_node_2d().hop()
		_companion.get_node_2d().show_emote(EmoteBubble.NOTE)
		return
	if _catalog == null or not _catalog.is_eligible_species(user.species_id) \
			or not is_instance_valid(_map) or _map.get_entities() == null \
			or _map.get_grid() == null:
		return
	var cell := _cameo_cell()
	if cell == CompanionTrail.NONE:
		return
	_cameo = Companion.new()
	_cameo.name = "FlashCameo"
	_cameo.reduce_motion = reduce_motion
	if not _cameo.set_species(user.species_id, _catalog.sprite_of(user.species_id),
			_catalog.is_flying(user.species_id)):
		_free_cameo()
		return
	_map.get_entities().add_child(_cameo)
	_cameo.place(cell, _player.get_facing())
	_cameo.appear()


## Case du Pokémon montré : derrière le joueur, sinon à sa gauche ou à sa droite ; libre et hors
## passage (porte, échelle, bord) ; [constant CompanionTrail.NONE] si aucune.
func _cameo_cell() -> Vector2i:
	var facing := _player.get_facing()
	var side := Vector2i(facing.y, -facing.x)
	var grid := _map.get_grid()
	for offset: Vector2i in [-facing, side, -side]:
		var cell := _player.get_cell() + offset
		if grid.is_free(cell) and _map.get_warps().get_at(cell).is_empty():
			return cell
	return CompanionTrail.NONE


func _show_banner(pokemon_name: String) -> void:
	var text := _field_moves.cue_text(MOVE, pokemon_name) if _field_moves != null else ""
	if _hud != null and not text.is_empty():
		_hud.show_caption(text, BANNER_HOLD)


func _flash_screen() -> void:
	if _hud != null:
		_hud.get_screen_flash().play(1)


func _open_halo() -> void:
	_tween = null
	_darkness.opened.connect(_on_opened, CONNECT_ONE_SHOT)
	_darkness.open()


func _on_opened() -> void:
	_running = false
	_dismiss_cameo()
	_player.set_input_enabled(true, LOCK_REASON)
	flash_used.emit(_map.map_id if is_instance_valid(_map) else &"")


## Le Pokémon montré rentre dans sa Ball, puis il est libéré.
func _dismiss_cameo() -> void:
	if _cameo == null:
		return
	var cameo := _cameo
	_cameo = null
	await cameo.withdraw()
	if is_instance_valid(cameo):
		cameo.queue_free()


func _free_cameo() -> void:
	if _cameo != null and is_instance_valid(_cameo):
		_cameo.queue_free()
	_cameo = null
