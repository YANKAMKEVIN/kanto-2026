extends GutTest
## ServiceDirector (jalon 7 T8, jalon-07.md §3.3.2) hors de Boot : soin simple, soin d'un Centre
## sans carte (attente de la durée du rituel, aucun point de repos), sur la vraie carte du Centre
## (machine, point de repos enregistré une seule fois), actions inconnues ou à venir refusées.
## T12 : `open_shop` demande la boutique de la carte courante (sans carte : refusée).

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const CENTER := "res://game/world/maps/viridian_center.tscn"
const MART := "res://game/world/maps/viridian_mart.tscn"

var _state: Node
var _points: RestPointLibrary
var _services: ServiceDirector
var _healed: Array[Array] = []
var _vibrations: Array[int] = []


func before_each() -> void:
	_healed.clear()
	_vibrations.clear()
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)
	var data := PokemonData.new()
	data.load_dir()
	_state = GameStateScript.new()
	add_child_autofree(_state)
	for species: StringName in [&"charmander", &"pidgey", &"rattata"]:
		var pokemon := PokemonFactory.create(data, species, 5, GameRng.new(3))
		pokemon.hp = 0
		_state.party.add(pokemon)
	_points = RestPointLibrary.new()
	_points.load_file()
	_services = ServiceDirector.new()
	add_child_autofree(_services)
	_services.setup(_state, _points)
	_services.reduce_motion = true
	_services.center_healed.connect(func(map_id: StringName, registered: bool) -> void:
		_healed.append([map_id, registered]))


func after_each() -> void:
	Haptics.reset()


func _all_healed() -> bool:
	for pokemon: Pokemon in _state.party.get_all():
		if pokemon.hp < pokemon.max_hp():
			return false
	return true


func test_ritual_duration_follows_reduce_motion() -> void:
	_services.reduce_motion = false
	assert_eq(_services.ritual_duration(), UiTokens.CENTER_HEAL)
	assert_almost_eq(UiTokens.CENTER_HEAL, 3.0, 0.001, "environ 3 s (dossier 09 §7)")
	_services.reduce_motion = true
	assert_almost_eq(_services.ritual_duration(), UiTokens.CENTER_HEAL * 0.5, 0.001)


func test_heal_heals_without_ritual_nor_rest_point() -> void:
	await _services.run_action(&"heal")
	assert_true(_all_healed())
	assert_eq(_healed.size(), 0, "Maman : pas de rituel")
	assert_eq(_state.heal_map, &"player_house_1f")
	assert_eq(_vibrations.size(), 0)


func test_center_heal_without_a_map_waits_the_ritual_and_registers_nothing() -> void:
	# Temps simulé (TweenClock) : la durée se compte en pas, quelle que soit la charge.
	var clock := TweenClock.new(get_tree())
	var done: Array[bool] = [false]
	var run := func() -> void:
		await _services.run_action(&"center_heal")
		done[0] = true
	run.call()
	assert_true(_services.is_running(), "le rituel attend")
	var steps := clock.run_until(func() -> bool: return done[0], 5.0)
	clock.release()
	var seconds := steps * TweenClock.STEP
	var expected := _services.ritual_duration()
	assert_between(seconds, expected - 0.0001, expected + TweenClock.STEP + 0.0001,
		"durée du rituel (%.3f s pour %.2f s)" % [seconds, expected])
	assert_true(_all_healed())
	assert_eq(_healed, [[&"", false]] as Array[Array])
	assert_eq(_vibrations, [UiTokens.CENTER_HEAL_HAPTIC_MS] as Array[int])
	assert_false(_services.is_running())


func test_center_heal_on_the_center_registers_it_once() -> void:
	var map := (load(CENTER) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	_services.set_map(map)
	await _services.run_action(&"center_heal")
	assert_true(_all_healed())
	assert_eq(_healed, [[&"viridian_center", true]] as Array[Array], "point de repos changé")
	assert_eq(_state.heal_map, &"viridian_center")
	assert_eq(_vibrations.size(), 1, "vibration à l'éclat")
	assert_eq(map.get_npc(&"nurse").get_facing(), Vector2i.DOWN, "l'infirmière est revenue")
	await _services.run_action(&"center_heal")
	assert_eq(_healed[1], [&"viridian_center", false], "même Centre : rien de changé")
	# Le rituel rend la main **pendant** l'émission de `animation_finished` de la machine : sans
	# cette image, le test finit dans cette émission et GUT libère la carte (donc l'AnimationPlayer
	# qui émet) → plantage de Godot (signal 11), constaté sous Linux headless.
	await wait_process_frames(1)


func test_unknown_and_mapless_actions_are_reported() -> void:
	var shops: Array[StringName] = []
	_services.shop_requested.connect(shops.append)
	await _services.run_action(&"teleport")
	await _services.run_action(&"open_shop")
	await _services.run_action(&"open_storage")
	assert_push_error_count(3, "inconnue, Boutique sans carte, Stockage sans carte")
	assert_false(_all_healed(), "rien n'est fait")
	assert_eq(shops.size(), 0, "pas de boutique sans carte")


func test_open_shop_asks_for_the_shop_of_the_current_map() -> void:
	var map := (load(MART) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	_services.set_map(map)
	var shops: Array[StringName] = []
	_services.shop_requested.connect(shops.append)
	await _services.run_action(&"open_shop")
	assert_eq(shops, [&"viridian_mart"] as Array[StringName], "la boutique porte l'id de sa carte")
	assert_false(_services.is_running(), "rend la main tout de suite")
	assert_false(_all_healed(), "aucun soin")


func test_open_storage_asks_for_the_storage_and_returns_at_once() -> void:
	var map := (load(CENTER) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	_services.set_map(map)
	var asked: Array[bool] = []
	_services.storage_requested.connect(func() -> void: asked.append(true))
	await _services.run_action(&"open_storage")
	assert_eq(asked.size(), 1, "le Stockage est demandé")
	assert_false(_services.is_running(), "rend la main tout de suite")
	assert_false(_all_healed(), "aucun soin")
	assert_push_error_count(0)


## Jalon 20 (§2.9.1) : un vendeur ouvre sa boutique (clé « shop »), pas celle de la carte.
func test_open_shop_with_a_shop_id_asks_for_that_shop() -> void:
	var map := (load(MART) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	_services.set_map(map)
	var shops: Array[StringName] = []
	_services.shop_requested.connect(shops.append)
	await _services.run_action(&"open_shop", &"celadon_dept_5f")
	await _services.run_action(&"open_shop")
	assert_eq(shops, [&"celadon_dept_5f", &"viridian_mart"] as Array[StringName])
