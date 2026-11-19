class_name FlyDirector
extends Node
## Vol hors combat (passe systèmes 2, `docs/tech/systemes-2.md` §2.8, T24–T25) : lancé depuis
## l'écran Carte (bouton « S'ENVOLER » d'une ville ouverte, Q-4) ; Boot ferme le menu puis
## appelle [method fly]. Mise en scène : compagnon rentré, « {pokemon} s'envole très haut ! »,
## le joueur s'efface ([constant TAKEOFF_SECONDS]), changement de carte habituel vers le point
## d'arrivée (`fly_points.json`, devant le Centre), « {pokemon} redescend. », joueur libre.
## L'autosave d'arrivée est celui de [signal SceneRouter.map_entered].
##
## Toutes les dépendances sont injectées ([method setup]) : testable sans Boot.

signal flight_started(zone: StringName)
signal flight_finished(zone: StringName)

const MOVE: StringName = &"fly"
const TAKEOFF_DIALOGUE: StringName = &"fly_takeoff"
const LANDING_DIALOGUE: StringName = &"fly_landing"
## Effacement du joueur à l'envol (secondes) [D].
const TAKEOFF_SECONDS: float = 0.6
const INPUT_REASON: StringName = &"fly"
## Orientation à l'arrivée [D] : face à l'écran, dos au Centre.
const ARRIVAL_FACING: Vector2i = Vector2i.DOWN
## Animation du Vol (remarque de Kevin sur S24, 2026-11-19 : « on apparaît et disparaît
## juste ») : le porteur sort de sa Ball au-dessus du joueur, ils montent hors de l'écran
## (la caméra reste au sol), le ciel montre le porteur qui traverse ([DragonFlightOverlay]),
## puis ils redescendent du haut de l'écran sur le point d'arrivée et le porteur rentre.
## Hauteur de sortie (px, plus haut que le demi-écran au zoom 1), durées (s) [D].
const RISE_HEIGHT: float = 1250.0
const RISE_SECONDS: float = 0.9
const LAND_SECONDS: float = 1.0
const SKY_CROSSING: float = 1.6
## Son de l'envol (`data/audio/sfx.json`).
const TAKEOFF_SFX: StringName = &"ambient_fly_away"

## J23 : cartes où ce voyage est refusé (Parc Safari, `SafariConfig.maps`), posées par Boot.
var no_fly_maps: Dictionary[StringName, bool] = {}
## Posés par Boot ; tous facultatifs (sans eux, l'ancien fondu du joueur, testable sans scène).
## Ciel du trajet (partagé avec le vol sur Dracolosse du Johto).
var overlay: DragonFlightOverlay
## `func(party_index: int) -> Dictionary` : { "species": StringName, "artwork": Texture2D }
## du Pokémon nommé par [method FieldMoves.status] (le porteur).
var carrier_source: Callable
## `func(id: StringName) -> void` : joue un son.
var sfx: Callable
## « Réduire les animations » : ni montée ni descente (fondu), ciel en image fixe.
var reduce_motion: bool = false
## JOH0 (JH-18) : `func(map_id: StringName) -> StringName`, la région d'une carte (Boot :
## `ZoneLibrary.region_of`) ; `func() -> bool`, le Vol entre régions est-il permis (faux pendant
## l'acte 1). Non valides : aucun contrôle de région.
var region_source: Callable
var cross_source: Callable
var _rules: FlyRules
## func() -> Dictionary : cartes découvertes (`GameState.discovered_maps`).
var _discovered: Callable = Callable()
## func(move: StringName) -> FieldMoves.Result.
var _field_check: Callable = Callable()
var _caves: CaveLibrary
## func() -> GameMap.
var _current_map: Callable = Callable()
var _player: Player
var _runner: DialogueRunner
var _router: Node
var _companion: CompanionController
var _flying: bool = false


func setup(rules: FlyRules, discovered: Callable, field_check: Callable, caves: CaveLibrary,
		current_map: Callable, player: Player, runner: DialogueRunner, router: Node,
		companion: CompanionController = null) -> void:
	_rules = rules
	_discovered = discovered
	_field_check = field_check
	_caves = caves
	_current_map = current_map
	_player = player
	_runner = runner
	_router = router
	_companion = companion


func is_flying() -> bool:
	return _flying


## Réponse de [method FlyRules.can_fly_to] pour la carte et la partie courantes.
func check(zone: StringName) -> FlyRules.Check:
	var map: GameMap = _current_map.call() if _current_map.is_valid() else null
	if _rules == null or not is_instance_valid(map):
		return FlyRules.Check.BUSY
	var state := FieldMoves.State.NO_HM
	if _field_check.is_valid():
		var result: Variant = _field_check.call(MOVE)
		if result is FieldMoves.Result:
			state = (result as FieldMoves.Result).state
	var cave := _caves != null and _caves.is_cave(map.map_id)
	# J23 (dossier 26 §4) : Vol refusé dans le Parc Safari, comme dans une grotte.
	cave = cave or no_fly_maps.has(map.map_id)
	var discovered: Dictionary = _discovered.call() if _discovered.is_valid() else {}
	var traits := FlyRules.traits_of(map.interior, cave)
	# Jalon 30 (T8) : carte marquée « no_fly » (salles de la Ligue).
	traits.no_fly = traits.no_fly or map.no_fly
	var from_region: StringName = region_source.call(map.map_id) if region_source.is_valid() \
		else &""
	var cross: bool = bool(cross_source.call()) if cross_source.is_valid() else true
	return _rules.can_fly_to(zone, state, traits, discovered, _flying, from_region, cross)


## Vrai si le bouton « S'ENVOLER » est proposé pour [param zone] (menu).
func can_fly_to(zone: StringName) -> bool:
	return check(zone) == FlyRules.Check.OK


## Envol vers [param zone] (coroutine). Sans effet si [method check] refuse.
func fly(zone: StringName) -> void:
	if check(zone) != FlyRules.Check.OK:
		return
	var point := _rules.get_point(zone)
	_flying = true
	flight_started.emit(zone)
	_player.set_input_enabled(false, INPUT_REASON)
	if _companion != null:
		_companion.on_cutscene_started()
	await _say(TAKEOFF_DIALOGUE)
	var carrier := _make_carrier()
	var artwork: Texture2D = carrier.get_meta(&"artwork") if carrier != null \
		and carrier.has_meta(&"artwork") else null
	var animated := is_inside_tree() and not reduce_motion
	if animated:
		await _take_off(carrier)
	elif is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_player, ^"modulate:a", 0.0, TAKEOFF_SECONDS)
		await tween.finished
	if overlay != null and is_inside_tree():
		overlay.reduce_motion = reduce_motion
		await overlay.play(DragonFlightOverlay.OUT, artwork, SKY_CROSSING)
	await _router.change_map(point.map, point.spawn, ARRIVAL_FACING)
	if is_instance_valid(_player):
		_player.modulate.a = 1.0
		if animated:
			_set_lift(RISE_HEIGHT, carrier)
			if carrier != null:
				carrier.show_now()
	if overlay != null and is_inside_tree():
		await overlay.finish()
	if animated and is_instance_valid(_player):
		await _land(carrier)
	if carrier != null:
		carrier.queue_free()
	await _say(LANDING_DIALOGUE)
	if _companion != null:
		_companion.on_cutscene_finished()
	_player.set_input_enabled(true, INPUT_REASON)
	_flying = false
	flight_finished.emit(zone)


## Le porteur au-dessus de la tête du joueur ; null sans source ou sans visuel.
func _make_carrier() -> FlyCarrier:
	if not carrier_source.is_valid() or not is_instance_valid(_player):
		return null
	var index := -1
	if _field_check.is_valid():
		var result: Variant = _field_check.call(MOVE)
		if result is FieldMoves.Result:
			index = (result as FieldMoves.Result).pokemon_index
	var info: Variant = carrier_source.call(index)
	if not info is Dictionary or (info as Dictionary).is_empty():
		return null
	var species: StringName = StringName(str((info as Dictionary).get("species", "")))
	var artwork := (info as Dictionary).get("artwork", null) as Texture2D
	var carrier := FlyCarrier.new()
	if not carrier.set_species(species, artwork):
		carrier.free()
		return null
	carrier.set_meta(&"artwork", artwork)
	_player.add_child(carrier)
	return carrier


func _take_off(carrier: FlyCarrier) -> void:
	if carrier != null:
		await carrier.pop_out()
	if sfx.is_valid():
		sfx.call(TAKEOFF_SFX)
	var tween := create_tween()
	tween.tween_method(_set_lift.bind(carrier), 0.0, RISE_HEIGHT, RISE_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


func _land(carrier: FlyCarrier) -> void:
	var tween := create_tween()
	tween.tween_method(_set_lift.bind(carrier), RISE_HEIGHT, 0.0, LAND_SECONDS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	_set_lift(0.0, carrier)
	if carrier != null:
		await carrier.pop_in()


func _set_lift(height: float, carrier: FlyCarrier) -> void:
	if is_instance_valid(_player):
		_player.flight_lift = height
	if carrier != null and is_instance_valid(carrier):
		carrier.lift = height


func _say(dialogue_id: StringName) -> void:
	if _runner == null:
		return
	var map: GameMap = _current_map.call() if _current_map.is_valid() else null
	if _runner.play(dialogue_id, null, map):
		await _runner.dialogue_finished
