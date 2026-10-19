extends GutTest
## Série 18 intégrée (J16 T10, fiche `serie-18-ss-anne.md`) : enveloppes des pièces du S.S. Anne
## et de l'Arène de Carmin à la taille de leur grille (sorties élargies à 2 cases), meubles et
## objets, effet de Coupe, apparences (capitaine et capitaine malade, Major Bob, gentleman,
## rockeur, hôtesse, passagère), barrière, icônes du Sac, décors de combat et cartes habillées.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const CATALOGUE := "res://assets/world/catalogue.json"
const TILE := 96
## Enveloppe → taille de la grille en cases.
const SHELLS: Dictionary = {
	"int_ss_anne_pont_principal_coque": Vector2i(26, 13),
	"int_ss_anne_couloir_coque": Vector2i(18, 7),
	"int_ss_anne_cabine_capitaine_coque": Vector2i(14, 10),
	"int_ss_anne_restaurant_coque": Vector2i(18, 11),
	"int_ss_anne_pont_inferieur_coque": Vector2i(22, 11),
	"int_ss_anne_cabine_coque": Vector2i(12, 9),
	"int_arene_carmin_coque": Vector2i(17, 15),
}
## Meuble → largeur en cases (pixels = largeur × 96).
const FURNITURE: Dictionary = {
	"int_banquette_ss_anne_01": 2, "int_comptoir_accueil_ss_anne_01": 4,
	"int_table_restaurant_01": 2, "int_comptoir_cuisine_01": 4, "int_lit_cabine_01": 2,
	"int_armoire_cabine_01": 1, "int_table_hublot_01": 2, "int_bureau_capitaine_01": 3,
	"int_lavabo_cabine_01": 1, "int_table_cartes_01": 2, "int_caisses_cale_01": 2,
	"int_caisses_cale_02": 3, "int_armoire_electrique_01": 1, "int_armoire_electrique_02": 1,
	"prop_chaises_longues_01": 2, "prop_bouee_01": 1,
}
const LOOKS: Array[String] = ["captain", "captain_sick", "surge", "gentleman", "rocker",
	"hostess", "passenger_f"]
const ROOMS: Array[String] = ["ss_anne_main_deck", "ss_anne_captain_corridor",
	"ss_anne_captain_room", "ss_anne_restaurant", "ss_anne_lower_deck", "ss_anne_outer_deck",
	"ss_anne_cabin_a", "ss_anne_cabin_b", "ss_anne_cabin_c", "vermilion_gym"]

var _catalogue: Dictionary = {}


func before_all() -> void:
	_catalogue = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))


func test_shells_match_their_grid() -> void:
	for id: String in SHELLS:
		var size: Array = _catalogue["images"][id]["taille"]
		assert_eq(Vector2i(int(size[0]), int(size[1])), SHELLS[id] * TILE, id)


func test_cabin_exits_are_two_cells_wide() -> void:
	# Défaut du T2 corrigé à la préparation : la sortie peinte couvre les 2 cases `X` de la
	# grille (cabines (5..6, 7) : moquette bleue ; cabine du capitaine (6..7, 8) : seuil de
	# parquet), d'un bord à l'autre, sans montant de bois.
	_assert_floor_across("int_ss_anne_cabine_coque", 7, 5, func(c: Color) -> bool:
		return c.b > c.r + 0.1)
	_assert_floor_across("int_ss_anne_cabine_capitaine_coque", 8, 6, func(c: Color) -> bool:
		return c.r > 0.6 and c.g > 0.4)


func test_furniture_is_whole_cells_wide_with_a_scene() -> void:
	for id: String in FURNITURE:
		var size: Array = _catalogue["objets"][id]["taille"]
		assert_eq(int(size[0]), int(FURNITURE[id]) * TILE, "%s : largeur" % id)
		var packed := load("res://game/world/props/painted/%s.tscn" % id) as PackedScene
		assert_not_null(packed, id)
		if packed == null:
			continue
		var prop := packed.instantiate() as WorldProp
		add_child_autofree(prop)
		assert_eq(prop.footprint.size(), PaintedPropRules.footprint(StringName(id)).size(), id)


func test_fifteen_bins_share_one_image() -> void:
	# G-8 / dossier 19 §9 : aucune poubelle ne se distingue.
	var map := _map("vermilion_gym")
	var textures: Dictionary = {}
	for node: Node in map.get_node(^"Entities").get_children():
		if String(node.name).begins_with("Trash"):
			textures[(node.get_node(^"Sprite") as Sprite2D).texture.resource_path] = true
	assert_eq(textures.size(), 1)
	assert_eq(map.get_node(^"Entities").get_children().filter(
		func(n: Node) -> bool: return String(n.name).begins_with("Trash")).size(), 15)


func test_cut_effect_has_four_frames_of_one_size() -> void:
	var size: Variant = null
	for i in 4:
		var entry: Dictionary = _catalogue["images"]["fx_coupe_%02d" % (i + 1)]
		assert_true(ResourceLoader.exists(entry["fichier"]), entry["fichier"])
		if size == null:
			size = entry["taille"]
		assert_eq(entry["taille"], size, "même cellule pour les 4 images")


func test_cut_slash_plays_the_painted_frames() -> void:
	var slash := CutSlash.new()
	add_child_autofree(slash)
	assert_eq(slash.get_frame(), -1)
	var clock := TweenClock.new(get_tree())
	slash.play(0.35)
	clock.run_until(func() -> bool: return slash.get_progress() > 0.5)
	assert_between(slash.get_frame(), 1, 2)
	clock.run_until(func() -> bool: return slash.get_progress() >= 1.0)
	clock.step()
	assert_eq(slash.get_frame(), 3)
	clock.release()


func test_looks_have_frames_with_idle() -> void:
	for look: String in LOOKS:
		var path := "res://assets/sprites/characters/painted/%s_frames.tres" % look
		var frames := load(path) as SpriteFrames
		assert_not_null(frames, path)
		if frames == null:
			continue
		for animation: StringName in [&"idle_down", &"idle_up", &"walk_down", &"walk_left"]:
			assert_true(frames.has_animation(animation), "%s : %s" % [path, animation])


func test_sick_captain_breathes_bent_over() -> void:
	# Dossier 19 §6 : penché sur son lavabo, animation courte (2 images de dos) ; de face, il
	# est soulagé (une image, autre que la face du capitaine).
	var sick := load("res://assets/sprites/characters/painted/captain_sick_frames.tres") \
		as SpriteFrames
	var well := load("res://assets/sprites/characters/painted/captain_frames.tres") as SpriteFrames
	assert_eq(sick.get_frame_count(&"idle_up"), 2)
	assert_eq(sick.get_frame_count(&"idle_down"), 1)
	assert_ne(sick.get_frame_texture(&"idle_down", 0).get_image().get_data(),
		well.get_frame_texture(&"idle_down", 0).get_image().get_data())


func test_npcs_use_the_final_looks() -> void:
	var expected: Dictionary = {
		"ss_anne_main_deck": {"armand": "gentleman", "hotesse": "hostess"},
		"ss_anne_restaurant": {"emile": "gentleman", "convive": "passenger_f", "serveur": "clerk"},
		"ss_anne_cabin_c": {"victor": "gentleman"},
		"ss_anne_outer_deck": {"passagere": "passenger_f"},
		"ss_anne_captain_room": {"ss_anne_captain": "captain_sick",
			"ss_anne_captain_well": "captain"},
		"vermilion_gym": {"surge": "surge", "gentleman_louis": "gentleman",
			"rocker_axel": "rocker", "vermilion_gym_barrier_2": "object/electric_barrier"},
	}
	for file: String in expected:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/npcs/%s.json" % file))
		for npc: String in expected[file]:
			assert_eq(String(data[npc]["sprite"]), String(expected[file][npc]), "%s/%s" % [file,
				npc])


func test_barrier_is_drawn_by_the_middle_segment() -> void:
	var middle := load("res://assets/sprites/objects/painted/electric_barrier_frames.tres") \
		as SpriteFrames
	var side := load("res://assets/sprites/objects/painted/electric_barrier_side_frames.tres") \
		as SpriteFrames
	assert_not_null(middle)
	assert_not_null(side)
	# 3,5 cases : pylônes à cheval sur les machines voisines.
	assert_eq(middle.get_frame_texture(&"idle_down", 0).get_width(), 336)
	assert_true(_map("vermilion_gym").has_node(^"Entities/BarrierPylons"))


func test_bag_icons_are_256_squares() -> void:
	for id: String in ["paralyze_heal", "awakening"]:
		var image := Image.load_from_file(
			ProjectSettings.globalize_path("res://assets/ui/items/%s.webp" % id))
		assert_not_null(image, id)
		if image != null:
			assert_eq(image.get_size(), Vector2i(256, 256), id)


func test_battle_decors_are_placed_on_every_room() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/battle/decors.json"))
	for id: String in ["ss_anne_salon", "ss_anne_pont", "vermilion_gym_salle"]:
		var decor: Dictionary = data["decors"][id]
		assert_true(ResourceLoader.exists(decor["back"]), id)
	for room: String in ROOMS:
		var expected := "ss_anne_salon"
		if room == "ss_anne_outer_deck":
			expected = "ss_anne_pont"
		elif room == "vermilion_gym":
			expected = "vermilion_gym_salle"
		assert_eq(String(data["places"][room][0]["decor"]), expected, room)


func test_rooms_are_dressed_without_placeholder() -> void:
	for room: String in ROOMS:
		var map := _map(room)
		assert_false(map.has_node(^"PlaceholderDecor"), room)
		if room == "ss_anne_outer_deck":
			assert_true(map.has_node(^"PaintedGround"), room)
			assert_true(map.has_node(^"Entities/Superstructure"), room)
		else:
			assert_true(map.has_node(^"Shell"), room)
		assert_lt(_count(map), 3000, room)


func _map(id: String) -> Node:
	var map := (load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate()
	autofree(map)
	return map


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func _assert_floor_across(id: String, row: int, first: int, is_floor: Callable) -> void:
	var image := Image.load_from_file(
		ProjectSettings.globalize_path(String(_catalogue["images"][id]["fichier"])))
	var y := row * TILE + 72  # bas de la case : le seuil sous le mur du bas
	var walls := 0
	for x in range(first * TILE + 8, (first + 2) * TILE - 8, 4):
		if not is_floor.call(image.get_pixel(x, y)):
			walls += 1
	assert_eq(walls, 0, "%s : sortie de 2 cases" % id)
