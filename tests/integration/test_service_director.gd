extends GutTest
## ServiceDirector (jalon 7 T8, jalon-07.md §3.3.2) hors de Boot : soin simple, soin d'un Centre
## sans carte (attente de la durée du rituel, aucun point de repos), sur la vraie carte du Centre
## (machine, point de repos enregistré une seule fois), actions inconnues ou à venir refusées.
## T12 : `open_shop` demande la boutique de la carte courante (sans carte : refusée).

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
	var started := Time.get_ticks_msec()
	await _services.run_action(&"center_heal")
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	assert_between(seconds, 1.3, 2.0, "durée du rituel (%.2f s)" % seconds)
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


func test_unknown_and_pending_actions_are_reported() -> void:
	var shops: Array[StringName] = []
	_services.shop_requested.connect(shops.append)
	await _services.run_action(&"teleport")
	await _services.run_action(&"open_shop")
	await _services.run_action(&"open_storage")
	assert_push_error_count(3, "inconnue, Boutique sans carte, Stockage à venir")
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
