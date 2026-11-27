extends GutTest
## Retours de Kevin sur Johto (RC 0.38.0 sur S24, 2026-11-27) : garde-fous de chaque correction.
## - Erreur 2 : la porte de l'ascenseur en panne de la Tour Radio ne laisse plus entrer dans le mur ;
##   plus généralement, une porte ou un escalier conditionnel de Johto ne s'ouvre pas avant l'heure.
## - Erreur 3 : le toit du Grand Magasin de Doublonville suit le jour et la nuit, comme les autres
##   extérieurs de Johto.
## - Erreur 4 : les portes peintes des façades sans intérieur disent qu'elles sont fermées.
## - Erreur 5 : les Sbires Rocket de Johto voient toute la ligne dégagée devant eux.
## - Erreur 6 : le combat du Souterrain n'a plus un décor extérieur de jour.
## - Erreur 7 : le panneau du Souterrain n'est plus coincé dans une niche.

const MAPS_DIR := "res://game/world/maps/"
const ELEVATOR := Vector2i(18, 0)
const ELEVATOR_FLAG: StringName = &"johto_cenere_defeated"
## Façades sans intérieur : carte → [case de la porte, case d'où on l'examine, dialogue].
const CLOSED_DOORS: Dictionary = {
	"goldenrod_city": [Vector2i(59, 45), Vector2i(59, 46), &"goldenrod_city_gare_fermee"],
	"route_43": [Vector2i(15, 24), Vector2i(15, 25), &"route_43_peage_ferme"],
}
## Cartes de Johto où un passage (porte, escalier) ne s'ouvre qu'avec un drapeau.
const CONDITIONAL_WARP_MAPS: Array[String] = [
	"goldenrod_radio_tower_1f", "goldenrod_radio_tower_2f", "goldenrod_radio_tower_3f",
	"goldenrod_radio_tower_4f", "goldenrod_radio_tower_5f", "ecruteak_city", "dragons_den_1f",
	"mahogany_souvenir_shop",
]
const NPC_DIR := "res://data/npcs/"
const J22Ids := preload("res://tests/helpers/j22_ids.gd")
const KANTO_ROCKET_MAPS: Array[String] = [
	"celadon_game_corner", "mt_moon_b1f", "mt_moon_b2f", "pokemon_tower_7f",
]


func _map(map_id: String, flags: StoryFlags = StoryFlags.new()) -> GameMap:
	var packed := load(MAPS_DIR + map_id + ".tscn") as PackedScene
	assert_not_null(packed, map_id)
	var map := packed.instantiate() as GameMap
	add_child_autofree(map)
	map.apply_flag_gates(flags)
	return map


func _cell(node: Node2D) -> Vector2i:
	return Vector2i(floori(node.position.x / 96.0), floori(node.position.y / 96.0) - 1)


func test_broken_elevator_door_is_closed_until_cenere_and_examined_from_the_front() -> void:
	for floor_number: int in [1, 2, 3, 4, 5]:
		var map_id := "goldenrod_radio_tower_%df" % floor_number
		var map := _map(map_id)
		assert_false(map.get_grid().can_enter(ELEVATOR, Vector2i.UP),
			"%s : la porte en panne ne laisse pas entrer dans le mur" % map_id)
		var examine := map.get_interactions().find(ELEVATOR, Vector2i.UP)
		assert_not_null(examine, "%s : EXAMINER depuis la case devant" % map_id)
		if examine != null:
			assert_eq(examine.dialogue_id, &"goldenrod_radio_elevator")
		var after := StoryFlags.new()
		after.set_flag(ELEVATOR_FLAG)
		var open := _map(map_id, after)
		assert_true(open.get_grid().can_enter(ELEVATOR, Vector2i.UP),
			"%s : après Cenere, la cabine s'ouvre" % map_id)


func test_no_conditional_warp_of_johto_lets_the_player_in_before_its_flag() -> void:
	for map_id: String in CONDITIONAL_WARP_MAPS:
		var map := _map(map_id)
		var found := 0
		for warp: Node in map.get_node(^"Warps").get_children():
			var needed: Array[StringName] = warp.get(&"if_flags")
			if needed.is_empty():
				continue
			found += 1
			var cell := _cell(warp as Node2D)
			assert_false(map.get_grid().can_enter(cell, Vector2i.UP)
					and map.get_grid().can_enter(cell, Vector2i.DOWN)
					and map.get_grid().can_enter(cell, Vector2i.LEFT)
					and map.get_grid().can_enter(cell, Vector2i.RIGHT)
					and _is_wall_cell(map, cell),
				"%s : %s %s s'ouvre sans %s" % [map_id, warp.name, cell, needed])
		assert_gt(found, 0, "%s : un passage conditionnel" % map_id)


## Une case de passage « dans le mur » : bordée de cases bloquées de part et d'autre (gauche et
## droite), comme une porte dans un mur nord.
func _is_wall_cell(map: GameMap, cell: Vector2i) -> bool:
	var grid := map.get_grid()
	return not grid.can_enter(cell + Vector2i.LEFT, Vector2i.LEFT) \
		and not grid.can_enter(cell + Vector2i.RIGHT, Vector2i.RIGHT)


func test_dept_store_roof_follows_johto_day_and_night() -> void:
	var map := _map("goldenrod_dept_store_roof")
	assert_eq(map.light_profile, LightingLibrary.AUTO_PROFILE)
	var lighting := LightingLibrary.new()
	assert_true(lighting.load_file(), "\n".join(lighting.get_errors()))
	assert_eq(lighting.get_map_profile(&"goldenrod_dept_store_roof"), LightingLibrary.AUTO_PROFILE)


func test_closed_facade_doors_say_they_are_closed() -> void:
	var texts := DialogueLibrary.new()
	assert_true(texts.load_dir(), "dialogues")
	for map_id: String in CLOSED_DOORS:
		var entry: Array = CLOSED_DOORS[map_id]
		var map := _map(map_id)
		var door: Vector2i = entry[0]
		assert_true(map.get_grid().can_enter(entry[1], Vector2i.UP), "%s : devant la porte" % map_id)
		var examine := map.get_interactions().find(door, Vector2i.UP)
		assert_not_null(examine, "%s : EXAMINER la porte %s" % [map_id, door])
		if examine != null:
			assert_eq(examine.dialogue_id, entry[2])
			assert_true(texts.has_dialogue(entry[2]), "texte %s" % entry[2])


## Les fichiers `johr_*` sont écartés des grands registres (`j22_ids.gd`) : chacun de leurs
## dialogues est une porte fermée vérifiée ci-dessus, aucun n'est orphelin.
func test_closed_door_texts_are_all_used() -> void:
	var ids: Array = J22Ids.in_dir("res://data/dialogues/", "johr_").keys()
	var used: Array = []
	for map_id: String in CLOSED_DOORS:
		used.append((CLOSED_DOORS[map_id] as Array)[2])
	ids.sort()
	used.sort()
	assert_eq(ids, used)


func test_johto_rocket_grunts_see_the_whole_clear_line() -> void:
	var count := 0
	for file: String in DirAccess.get_files_at(NPC_DIR):
		var map_id := file.get_basename()
		if not file.ends_with(".json") or map_id in KANTO_ROCKET_MAPS \
				or map_id.begins_with("rocket_hideout") or map_id.begins_with("silph_co"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(NPC_DIR + file))
		if not data is Dictionary:
			continue
		for key: Variant in data:
			var npc: Variant = data[key]
			if not (npc is Dictionary and npc.get("trainer") is Dictionary
					and String(npc.get("sprite", "")).begins_with("rocket_grunt")):
				continue
			var sight := int(npc["trainer"]["sight"])
			if sight == 0:
				continue  # alarme du repaire : déclenché par une scène, pas par la vue
			count += 1
			assert_eq(sight, TrainerRules.SIGHT_MAX, "%s / %s : portée de vue" % [map_id, key])
	assert_gt(count, 30, "Sbires de Johto trouvés")


func test_underground_battle_is_not_an_outdoor_decor() -> void:
	var catalog := BattleDecorCatalog.load_file()
	var decor := catalog.default_for(&"goldenrod_underground")
	assert_not_null(decor)
	if decor != null:
		assert_eq(decor.id, &"rocket_hideout_repaire")


func test_underground_sign_stands_in_the_gallery() -> void:
	var map := _map("goldenrod_underground")
	var sign := Vector2i(4, 8)
	assert_false(map.get_grid().can_enter(sign, Vector2i.DOWN), "le panneau occupe sa case")
	for side: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var from := sign - side
		assert_true(map.get_grid().can_enter(from, side), "case %s libre" % from)
		var point := map.get_interactions().find(sign, side)
		assert_not_null(point, "lu depuis %s" % from)
	assert_null(map.get_interactions().find(Vector2i(4, 4), Vector2i.UP), "plus rien dans la niche")
