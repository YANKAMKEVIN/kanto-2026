extends GutTest
## Ascenseur de la Sylphe SARL (jalon 26, T7 ; `docs/tech/jalon-26.md` §2.2 ; mécanique du J20,
## `game/world/elevator/`) avec les vraies données et les vraies cartes :
## - entrée `silph_co` de `elevators.json` : cabine `silph_co_elevator`, 11 étages 1F → 11F dans
##   l'ordre, sans clé ; chaque étage a sa porte et son arrivée `from_elevator` une case devant ;
## - depuis chaque étage, seul l'étage courant est grisé ; la sortie est réorientée vers lui ;
## - vraie Boot : 1F → cabine → panneau (sans Carte ni clé) → 11F → sortie au 11F devant la porte ;
##   puis retour au 5F.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/silph_1f.json"
const SAVE_PATH := "user://test_silph_elevator.json"
const CAR := &"silph_co_elevator"
## Case sous le panneau d'étages (3, 0) de la cabine (grille `sylphe_ascenseur.txt`).
const UNDER_PANEL := Vector2i(3, 1)
const LABELS: Array[String] = ["1F", "2F", "3F", "4F", "5F", "6F", "7F", "8F", "9F", "10F",
	"11F"]
const TIMEOUT := 15.0

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


func _spec() -> ElevatorData:
	var library := ElevatorLibrary.new()
	assert_true(library.load_file())
	return library.get_elevator(&"silph_co")


func test_the_silph_lift_serves_eleven_floors_without_a_key() -> void:
	var spec := _spec()
	assert_not_null(spec)
	if spec == null:
		return
	assert_eq(spec.car, CAR)
	assert_false(spec.needs_key(), "sans clé (RB)")
	assert_eq(spec.floors.map(func(f: Dictionary) -> String: return f["label"]), LABELS)
	for index: int in spec.floors.size():
		var entry: Dictionary = spec.floors[index]
		var map_id := StringName("silph_co_%df" % (index + 1))
		assert_eq(StringName(entry["map"]), map_id)
		assert_eq(StringName(entry["spawn"]), &"from_elevator")
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(&"from_elevator"), String(map_id))
		var arrival := map.get_spawn_cell(&"from_elevator")
		assert_false(map.get_grid().is_solid(arrival), "%s : arrivée praticable" % map_id)
		var door := map.get_warps().get_at(arrival + Vector2i.UP)
		assert_eq(door.size(), 1, "%s : porte de l'ascenseur au-dessus de l'arrivée" % map_id)
		if door.size() == 1:
			assert_eq([door[0].target_map, door[0].target_spawn], [CAR, &"entrance"])
	assert_true(ElevatorRules.can_operate(spec, Bag.new()), "Sac vide : le panneau répond")


func test_from_every_floor_only_the_current_one_is_greyed() -> void:
	var spec := _spec()
	if spec == null:
		return
	var all := spec.floor_ids()
	assert_eq(all.size(), 11)
	for index: int in all.size():
		var floor_map := StringName("silph_co_%df" % (index + 1))
		var current := ElevatorRules.entry_floor(spec, floor_map)
		assert_eq(current, all[index], "on entre depuis %s" % floor_map)
		var view := ElevatorPanelView.build(spec, current)
		assert_eq(view.current_floor(), current)
		var expected := all.duplicate()
		expected.erase(current)
		assert_eq(view.choosable_ids(), expected, "%s : aucun étage grisé à tort" % floor_map)
		assert_eq(ElevatorRules.exit_target(spec, current)["map"], floor_map,
			"sortie vers %s" % floor_map)
		for wanted: StringName in expected:
			assert_eq(ElevatorRules.choose(spec, current, wanted, Bag.new()),
				ElevatorRules.Status.OK, "%s → %s" % [current, wanted])


func test_ride_from_the_first_floor_to_the_eleventh_and_walk_out_there() -> void:
	await _play.start(START)
	var director := _play.boot.get_elevator_director()
	assert_eq(_play.map_id(), &"silph_co_1f")
	await _play.walk_to(Vector2i(20, 0))
	assert_eq(_play.map_id(), CAR, "dans la cabine")
	assert_eq(_play.player.get_cell(), Vector2i(1, 2), "arrivée devant les portes")
	assert_eq(director.get_current_floor(), &"1f")
	await _ride_to(&"11f")
	await _walk_out()
	assert_eq(_play.map_id(), &"silph_co_11f", "sortie au 11F")
	assert_eq(_play.player.get_cell(), Vector2i(13, 1), "devant la porte de l'ascenseur")
	# Retour par l'ascenseur, vers le 5F.
	await _play.step(Vector2i.UP)
	assert_eq(_play.map_id(), CAR)
	assert_eq(director.get_current_floor(), &"11f", "on vient du 11F")
	await _ride_to(&"5f")
	await _walk_out()
	assert_eq(_play.map_id(), &"silph_co_5f", "sortie au 5F")
	assert_eq(_play.player.get_cell(), Vector2i(20, 1))
	assert_push_error_count(0)


func _ride_to(floor_id: StringName) -> void:
	var director := _play.boot.get_elevator_director()
	await _play.walk_to(UNDER_PANEL)
	assert_eq(_play.player.get_cell(), UNDER_PANEL, "sous le panneau")
	await _play.interact(Vector2i.UP)
	await wait_until(func() -> bool: return director.is_panel_open(), 5.0)
	assert_true(director.is_panel_open(), "panneau ouvert sans clé")
	assert_eq(_play.pages(), [] as Array[String], "aucun refus")
	var view := director.panel_view()
	assert_eq(view.floors.map(func(f: Dictionary) -> String: return f["label"]), LABELS)
	assert_false(view.choosable_ids().has(director.get_current_floor()), "étage courant grisé")
	assert_eq(view.choosable_ids().size(), 10, "les dix autres étages")
	director.get_panel().floor_chosen.emit(floor_id)
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	assert_eq(director.get_current_floor(), floor_id)


## Sortie à pied par la porte de gauche de la cabine (1, 3).
func _walk_out() -> void:
	await _play.walk_to(Vector2i(1, 3))
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
