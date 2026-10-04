extends GutTest
## Données des points de repos (jalon-07.md §3.3, T6) : data/world/rest_points.json avec les
## vraies cartes, leurs points d'apparition et les vrais dialogues. Le Centre de Jadielle y
## entre au T8, avec sa carte et « nurse_wakeup » (data/dialogues/viridian_center.json).

const STATE_SCRIPT := "res://game/autoload/game_state.gd"

var _library: RestPointLibrary


func before_all() -> void:
	_library = RestPointLibrary.new()
	_library.load_file()


func test_file_loads_without_error() -> void:
	var library := RestPointLibrary.new()
	assert_true(library.load_file(), "data/world/rest_points.json se charge")
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_gt(library.size(), 0)


func test_every_point_is_on_a_real_map_spawn_with_a_real_wakeup_dialogue() -> void:
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	for map_id: StringName in _library.get_maps():
		var point := _library.get_point(map_id)
		assert_true(MapCatalog.has_map(map_id), "carte « %s »" % map_id)
		if not MapCatalog.has_map(map_id):
			continue
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		assert_true(map.has_spawn(point.spawn), "%s : point « %s »" % [map_id, point.spawn])
		map.free()
		assert_true(dialogues.has_dialogue(point.wakeup_dialogue),
			"%s : dialogue « %s »" % [map_id, point.wakeup_dialogue])


func test_new_game_rest_point_is_home_and_never_registers() -> void:
	var state: Node = autofree((load(STATE_SCRIPT) as GDScript).new())
	var home := _library.get_point(state.heal_map)
	assert_not_null(home, "la maison a son point de repos")
	assert_eq(home.spawn, state.heal_spawn)
	assert_eq(home.facing, Vector2i.UP, "tourné vers Maman")
	assert_eq(home.wakeup_dialogue, &"mom_wakeup")
	assert_false(home.registers, "Maman ne réenregistre pas la maison (dossier 09 §7)")


func test_registered_toast_is_the_dossier_09_text() -> void:
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(" — ".join(_library.registered_toast(zones.get_zone(&"viridian_city").name)),
		"Point de repos enregistré — Jadielle", "dossier 09 §19 (titre — détail)")
