extends GutTest
## Lot 32N (N-22) : toutes les CT sauf la CT31 Copie (écartée) s'obtiennent. Chaque CT a son objet
## et sa capacité ; chaque CT est donnée (scène), échangée, vendue ou ramassée ; les neuf CT du sol
## ajoutées par ce lot sont sur une case libre, atteignable à pied depuis l'arrivée de la carte.

const DISCARDED := 31
## CT du sol ajoutées par le lot : carte → [PNJ « objet », case].
const PICKS: Dictionary[StringName, Array] = {
	&"route_4": [&"route_4_tm04", Vector2i(19, 16)],
	&"ss_anne_lower_deck": [&"ss_anne_lower_deck_tm08", Vector2i(2, 8)],
	&"mt_moon_b1f": [&"mt_moon_b1f_tm12", Vector2i(31, 6)],
	&"route_12": [&"route_12_tm16", Vector2i(16, 26)],
	&"route_24": [&"route_24_tm45", Vector2i(19, 3)],
	&"route_9": [&"route_9_tm30", Vector2i(22, 27)],
	&"silph_co_2f": [&"silph_co_2f_tm36", Vector2i(17, 15)],
	&"viridian_city": [&"viridian_city_tm42", Vector2i(48, 18)],
	&"ss_anne_cabin_a": [&"ss_anne_cabin_a_tm44", Vector2i(9, 5)],
}


func _json_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "json":
			files.append(dir_path.path_join(file))
	return files


## Numéros de CT donnés par un pas « give » (toutes les scènes) ou vendus (boutiques).
func _obtainable() -> Dictionary[int, bool]:
	var found: Dictionary[int, bool] = {}
	var text := ""
	for path: String in _json_files("res://data/cutscenes") + _json_files("res://data/shops"):
		text += FileAccess.get_file_as_string(path)
	var regex := RegEx.new()
	regex.compile("\"(?:give|item)\": \"tm(\\d\\d)\"")
	for match: RegExMatch in regex.search_all(text):
		found[int(match.get_string(1))] = true
	return found


func test_every_tm_but_the_copy_is_obtainable() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	var data := PokemonData.new()
	data.load_dir()
	var tms: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/pokemon/tm_compatibility.json"))["tms"]
	var obtainable := _obtainable()
	var missing: Array[int] = []
	for number: int in range(1, 51):
		var id := StringName("tm%02d" % number)
		if number == DISCARDED:
			assert_null(items.get_item(id), "CT31 Copie : écartée (N-22)")
			assert_false(obtainable.has(number), "CT31 : aucun don")
			continue
		var item := items.get_item(id)
		assert_not_null(item, "objet %s" % id)
		if item != null:
			assert_eq(item.tm_number, number, String(id))
			assert_eq(String(item.teaches), String(tms["%02d" % number]), String(id))
			assert_not_null(data.get_move(item.teaches), "capacité de %s" % id)
		if not obtainable.has(number):
			missing.append(number)
	assert_eq(missing, [] as Array[int], "CT inobtenables")
	assert_eq(obtainable.size(), 49, "49 CT sur 50")


func test_the_ground_tms_are_free_and_reachable() -> void:
	for map_id: StringName in PICKS:
		var scene := load("res://game/world/maps/%s.tscn" % map_id) as PackedScene
		var map := scene.instantiate() as GameMap
		add_child_autofree(map)
		await wait_process_frames(1)
		var npc_id: StringName = PICKS[map_id][0]
		var cell: Vector2i = PICKS[map_id][1]
		var npc := map.get_npc(npc_id)
		assert_not_null(npc, "%s : PNJ objet posé" % npc_id)
		if npc == null:
			continue
		assert_eq(npc.get_cell(), cell, String(npc_id))
		var grid := map.get_grid()
		assert_false(grid.is_solid(cell), "%s : case non solide" % npc_id)
		var spawns := map.get_node("Spawns").get_children()
		var start := Vector2i(int(spawns[0].position.x / 96.0),
			mini(int(spawns[0].position.y / 96.0), map.size.y - 1))
		var reach := grid.find_reachable(start)
		var next_to := false
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			next_to = next_to or reach.has(cell + direction)
		assert_true(next_to, "%s : une case voisine est atteignable" % npc_id)
