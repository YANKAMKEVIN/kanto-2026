extends GutTest
## La vie de Safrania occupée puis libérée (jalon 26 T9 et T13 ; `docs/tech/jalon-26.md` §2.2, §3) sur
## les **vraies cartes et leurs PNJ** (`data/npcs/saffron_*.json`) :
## - ville : les PNJ sont ceux de la grille `safrania.txt` (cases, orientations, conditions
##   `unless` / `if` sur `silph_giovanni_defeated`) ; sbires, garde de l'Arène et garde de la Sylphe
##   présents pendant l'occupation et absents après ; habitants et gens de la libération l'inverse ;
## - **le sbire de l'Arène ferme la porte de l'Arène** (T26-02) pendant l'occupation et disparaît à
##   la libération ; **la porte du Dojo reste libre** (aucun PNJ ni drapeau devant ou dessus) ;
## - textes [D] validés d'avance (T26-01 à T26-03, T26-19, huit poteaux) mot pour mot ;
## - maisons habitées **sans remise de CT** (Q26-3) ; seule la Pépite cachée du Copieur (une fois) ;
## - aucune condition de Badge dans les données de la vie ;
## - cette suite lit les données : le drapeau est posé à la main (la scène de Giovanni : T12).

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FLAG := &"silph_giovanni_defeated"
const DIALOGUES := "res://data/dialogues/saffron_life.json"
const CUTSCENES := "res://data/cutscenes/saffron_life.json"
## Intérieurs → grille de la carte.
const INTERIORS := {
	&"saffron_center": "safrania_centre", &"saffron_mart": "safrania_boutique",
	&"saffron_psychic_house": "safrania_maison_psy",
	&"saffron_pidgey_house": "safrania_maison_roucool",
	&"saffron_copycat_house_1f": "safrania_maison_copieur_1f",
	&"saffron_copycat_house_2f": "safrania_maison_copieur_2f",
}
## Textes validés d'avance (2026-10-21) : dialogue → [locuteur, pages].
const CITY_TEXTS := {
	&"saffron_rocket": ["Sbire Rocket", ["Safrania est à nous. Circule, gamin."]],
	&"saffron_rocket_gym": ["Sbire Rocket", ["L'Arène est fermée. Ordre du patron."]],
	&"saffron_resident_occupied": ["Habitant",
		["Ils sont entrés dans la Sylphe SARL… Plus personne n'ose sortir."]],
	&"saffron_resident_free": ["Habitant",
		["La Team Rocket est partie ! Safrania respire enfin."]],
}
## Poteaux décoratifs devenus lisibles [D] : position de la grille → [dialogue, texte].
const SIGNS := {
	"panneau_dojo": [&"saffron_dojo_sign", "DOJO DE SAFRANIA\nL'art du combat à mains nues."],
	"panneau_boutique": [&"saffron_mart_sign", "BOUTIQUE POKÉMON\nTout pour le Dresseur."],
	"panneau_sylphe": [&"saffron_silph_sign", "SYLPHE SARL\nLe progrès au service des Pokémon."],
	"panneau_centre": [&"saffron_center_sign", "CENTRE POKÉMON\nSoignez vos compagnons."],
	"panneau_psy": [&"saffron_psychic_sign", "MAISON DE M. PSY\nLe voyant de Safrania."],
	"conseils_1": [&"saffron_tips_1", "CONSEILS DU DRESSEUR\nGarde toujours quelques Antidotes."],
	"conseils_2": [&"saffron_tips_2",
		"CONSEILS DU DRESSEUR\nUn Pokémon fatigué, c'est un Centre à visiter."],
	"panneau_produit": [&"saffron_product_sign",
		"DERNIER PRODUIT DE LA SYLPHE\nUne Ball inégalée, bientôt en vente !"],
}

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _items: ItemLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	assert_true(_dialogues.load_dir())
	_cutscenes = CutsceneLibrary.new()
	assert_true(_cutscenes.load_dir())
	_items = ItemLibrary.new()
	_items.load_dir()


func _load_map(id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _plan(name: String) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/%s.txt" % name), plan.error)
	return plan


func _flags(liberated: bool) -> StoryFlags:
	var flags := StoryFlags.new()
	if liberated:
		flags.set_flag(FLAG)
	return flags


func _flag_list(word: String) -> Array[StringName]:
	var list: Array[StringName] = []
	if not word.is_empty():
		list.append(StringName(word))
	return list


func _text(id: StringName) -> Array:
	var texts: Array = []
	for page: DialoguePage in _dialogues.get_dialogue(id).variants[0].pages:
		texts.append(DialogueTokens.apply_agreements(page.text, {}))
	return texts


# --- La ville : les PNJ sont ceux de la grille ----------------------------------------------

func test_city_npcs_are_the_plan_ones_with_their_conditions() -> void:
	var plan := _plan("safrania")
	var roster := NpcRoster.load_for_map(&"saffron_city")
	assert_eq(roster.get_errors().size(), 0, str(roster.get_errors()))
	var wanted := 0
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "pnj":
			continue
		wanted += 1
		var spec: NpcSpec = null
		for candidate: NpcSpec in roster.get_all():
			if candidate.id == StringName(id):
				spec = candidate
		assert_not_null(spec, "%s posé" % id)
		if spec == null:
			continue
		assert_eq(spec.cell, plan.cells_at(id)[0], "%s : case de la grille" % id)
		assert_eq(spec.facing, Grid.direction_from_name(plan.attr(id, "facing")),
			"%s : orientation" % id)
		assert_false(spec.is_trainer(), "%s : aucun combat (sbires de la rue)" % id)
		assert_eq(spec.unless_flags, _flag_list(plan.attr(id, "unless")), id)
		assert_eq(spec.if_flags, _flag_list(plan.attr(id, "if")), id)
		assert_true(_dialogues.has_dialogue(spec.dialogue), "%s : dialogue %s" % [id, spec.dialogue])
		if plan.attr(id, "mouvement") == "gauche_droite":
			assert_true(spec.has_route(), "%s : va-et-vient de la grille" % id)
	assert_eq(roster.get_all().size(), wanted, "aucun PNJ hors de la grille")


func test_occupied_then_liberated_presence() -> void:
	var plan := _plan("safrania")
	var roster := NpcRoster.load_for_map(&"saffron_city")
	var occupied: Array[StringName] = []
	var freed: Array[StringName] = []
	for spec: NpcSpec in roster.get_all():
		if spec.is_present(_flags(false)):
			occupied.append(spec.id)
		if spec.is_present(_flags(true)):
			freed.append(spec.id)
	var wanted_occupied: Array[StringName] = []
	var wanted_freed: Array[StringName] = []
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "pnj":
			continue
		if plan.attr(id, "if").is_empty():
			wanted_occupied.append(StringName(id))
		if plan.attr(id, "unless").is_empty():
			wanted_freed.append(StringName(id))
	occupied.sort()
	wanted_occupied.sort()
	freed.sort()
	wanted_freed.sort()
	assert_eq(occupied, wanted_occupied, "occupation : sbires, gardes et habitant inquiet")
	assert_eq(freed, wanted_freed, "libération : habitant, scientifique, employés, gentleman…")
	assert_eq(occupied.size(), 9, "six sbires de rue, garde de l'Arène (le 7e), garde de la Sylphe, habitant")
	assert_eq(freed.size(), 7, "habitant, scientifique, deux employés, gentleman, Roucarnage, rockeur")
	for id: StringName in occupied:
		assert_false(freed.has(id), "%s : jamais les deux à la fois" % id)


func test_live_map_follows_the_flag() -> void:
	var map := _load_map(&"saffron_city")
	map.refresh_npcs(_flags(false))
	assert_not_null(map.get_npc(&"garde_arene"))
	assert_not_null(map.get_npc(&"sbire_1"))
	assert_not_null(map.get_npc(&"habitant_occupe"))
	assert_null(map.get_npc(&"habitant_libre"))
	assert_null(map.get_npc(&"lib_scientifique"))
	map.refresh_npcs(_flags(true))
	assert_null(map.get_npc(&"garde_arene"), "l'Arène n'est plus gardée")
	assert_null(map.get_npc(&"sbire_1"))
	assert_null(map.get_npc(&"garde_sylphe"))
	assert_null(map.get_npc(&"habitant_occupe"))
	assert_not_null(map.get_npc(&"habitant_libre"))
	assert_not_null(map.get_npc(&"lib_scientifique"))
	assert_not_null(map.get_npc(&"lib_roucarnage"))


# --- Arène fermée par le sbire, Dojo libre -----------------------------------------------------

func test_gym_door_is_shut_by_the_guard_then_free_and_the_dojo_never() -> void:
	var plan := _plan("safrania")
	var map := _load_map(&"saffron_city")
	map.refresh_npcs(_flags(false))
	var gym_door: Vector2i = plan.cells_at("porte_arene")[0]
	var guard := map.get_npc(&"garde_arene")
	assert_eq(guard.get_cell(), gym_door + Vector2i.DOWN,
		"devant l'unique case de la porte de l'Arène")
	assert_false(guard.get_spec().has_route(), "il ne bouge pas : il ferme la porte")
	assert_eq(guard.get_spec().dialogue, &"saffron_rocket_gym")
	assert_false(map.get_grid().is_free(gym_door + Vector2i.DOWN), "case occupée")
	assert_eq(plan.cells_at("porte_arene").size(), 1, "une case : le sbire la ferme à lui seul")
	# Le Dojo : aucun PNJ sur ses cases ni devant elles, jamais.
	var dojo_cells := plan.cells_at("porte_dojo")
	for state: bool in [false, true]:
		map.refresh_npcs(_flags(state))
		for cell: Vector2i in dojo_cells:
			for check: Vector2i in [cell, cell + Vector2i.DOWN]:
				assert_true(map.get_grid().is_free(check),
					"Dojo %s libre (libéré : %s)" % [check, state])
	for spec: NpcSpec in NpcRoster.load_for_map(&"saffron_city").get_all():
		for cell: Vector2i in dojo_cells:
			assert_ne(spec.cell, cell + Vector2i.DOWN, "%s : pas devant le Dojo" % spec.id)
			assert_ne(spec.cell, cell, "%s : pas sur le Dojo" % spec.id)
	map.refresh_npcs(_flags(true))
	assert_true(map.get_grid().is_free(gym_door + Vector2i.DOWN),
		"libérée : la porte de l'Arène s'ouvre")


func test_the_three_shut_buildings_are_the_rb_ones() -> void:
	# RB : le sbire ferme la maison du Copieur, celle du Roucool et l'Arène ; ni le Centre, ni la
	# Boutique, ni la Sylphe, ni M. Psy, ni le Dojo (grille).
	var plan := _plan("safrania")
	var shut: Array[String] = []
	for door: String in ["porte_copieur", "porte_roucool", "porte_arene", "porte_dojo",
			"porte_boutique", "porte_sylphe", "porte_centre", "porte_psy"]:
		var front: Vector2i = plan.cells_at(door)[0] + Vector2i.DOWN
		for spec: NpcSpec in NpcRoster.load_for_map(&"saffron_city").get_all():
			if spec.cell == front and spec.unless_flags.has(FLAG):
				shut.append(door)
	shut.sort()
	assert_eq(shut, ["porte_arene", "porte_copieur", "porte_roucool"] as Array[String])


# --- Textes ----------------------------------------------------------------------------------

func test_city_texts_are_the_validated_ones() -> void:
	for id: StringName in CITY_TEXTS:
		assert_true(_dialogues.has_dialogue(id), String(id))
		var dialogue := _dialogues.get_dialogue(id)
		assert_eq(dialogue.speaker, CITY_TEXTS[id][0], String(id))
		assert_eq(_text(id), CITY_TEXTS[id][1], String(id))
	for spec: NpcSpec in NpcRoster.load_for_map(&"saffron_city").get_all():
		if spec.id == &"habitant_occupe":
			assert_eq(spec.dialogue, &"saffron_resident_occupied", "T26-03")
		if spec.id == &"habitant_libre":
			assert_eq(spec.dialogue, &"saffron_resident_free", "T26-19")
		if String(spec.id).begins_with("sbire_"):
			assert_eq(spec.dialogue, &"saffron_rocket", "T26-01")
		if spec.id == &"garde_arene":
			assert_eq(spec.dialogue, &"saffron_rocket_gym", "T26-02")


func test_the_eight_decorative_posts_are_readable_signs() -> void:
	var plan := _plan("safrania")
	var map := _load_map(&"saffron_city")
	for id: String in SIGNS:
		var cell: Vector2i = plan.cells_at(id)[0]
		var parts := plan.attr(id, "depuis").split(",")
		var from := Vector2i(int(parts[0]), int(parts[1]))
		var point := map.get_interactions().find(cell, cell - from)
		assert_not_null(point, "%s : lisible depuis %s" % [id, from])
		if point == null:
			continue
		assert_eq(point.dialogue_id, SIGNS[id][0], id)
		assert_eq(_text(SIGNS[id][0]), [SIGNS[id][1]], "%s : texte court [D]" % id)
		assert_true((SIGNS[id][1] as String).length() < 90, "%s : court" % id)


# --- Intérieurs ------------------------------------------------------------------------------

func test_every_interior_has_exactly_the_npcs_of_its_plan() -> void:
	for id: StringName in INTERIORS:
		var plan := _plan(INTERIORS[id])
		var map := _load_map(id)
		var wanted: Array[Vector2i] = []
		for pos: String in plan.positions:
			if plan.positions[pos]["kind"] == "pnj":
				wanted.append(plan.cells_at(pos)[0])
		var cells: Array[Vector2i] = []
		for npc: Npc in map.get_npcs():
			cells.append(npc.get_cell())
		wanted.sort()
		cells.sort()
		assert_eq(cells, wanted, "%s : les PNJ sont ceux de la grille" % id)
		for pos: String in plan.positions:
			if plan.positions[pos]["kind"] != "pnj":
				continue
			var cell: Vector2i = plan.cells_at(pos)[0]
			for npc: Npc in map.get_npcs():
				if npc.get_cell() == cell:
					assert_eq(npc.get_spec().facing,
						Grid.direction_from_name(plan.attr(pos, "facing")),
						"%s %s : orientation" % [id, pos])
					if not npc.get_spec().dialogue.is_empty():
						assert_true(_dialogues.has_dialogue(npc.get_spec().dialogue),
							"%s %s : dialogue" % [id, pos])


func test_centre_and_mart_keep_their_counters() -> void:
	var center := _load_map(&"saffron_center")
	assert_not_null(center.get_npc(&"nurse"), "infirmière derrière son comptoir")
	assert_eq(center.get_npc(&"nurse").get_spec().sprite, &"nurse")
	var mart := _load_map(&"saffron_mart")
	assert_not_null(mart.get_npc(&"clerk"), "vendeur")
	assert_eq(mart.get_npc(&"clerk").get_spec().sprite, &"clerk")


func test_houses_are_inhabited_and_hand_out_no_tm() -> void:
	# Q26-3 : maisons habitées, SANS remise de CT. Seul don : la Pépite cachée du Copieur.
	for id: StringName in INTERIORS:
		if id == &"saffron_center" or id == &"saffron_mart":
			continue
		assert_gt(_load_map(id).get_npcs().size(), 0, "%s habitée" % id)
	var gives: Array[String] = []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CUTSCENES))
	for id: String in data:
		for variant: Dictionary in data[id]["variants"]:
			for step: Dictionary in variant["steps"]:
				if step.has("give"):
					gives.append("%s:%s" % [id, step["give"]])
	assert_eq(gives, ["saffron_copycat_hidden_1:nugget"] as Array[String],
		"aucune CT dans les scènes de Safrania (la CT29 est dans j32_ct.json, N-22)")
	assert_eq(_dialogues.get_dialogue(&"saffron_mr_psychic").variants.size(), 2,
		"M. Psy : le don de la CT29 (N-22), puis son texte habituel")


func test_copycat_nugget_is_a_hidden_object_found_once() -> void:
	var map := _load_map(&"saffron_copycat_house_2f")
	var plan := _plan("safrania_maison_copieur_2f")
	var cell: Vector2i = plan.cells_at("copycat_hidden_1")[0]
	var point := map.get_interactions().find(cell, Vector2i.UP)
	assert_not_null(point, "Pépite cachée examinée depuis le sud, tournée vers le haut")
	if point == null:
		return
	assert_eq(point.dialogue_id, &"saffron_copycat_hidden_1")
	assert_eq(point.unless_flags, [&"got_saffron_copycat_hidden_1"] as Array[StringName])
	assert_true(_items.has_item(&"nugget"))
	var cutscene := _cutscenes.get_cutscene(&"saffron_copycat_hidden_1")
	assert_eq(cutscene.variants.size(), 1, "une seule fois")
	assert_eq(cutscene.variants[0].unless_flags,
		[&"got_saffron_copycat_hidden_1"] as Array[StringName])
	assert_eq(_dialogues.get_dialogue(&"saffron_copycat_hidden_1").variants[0].cutscene,
		&"saffron_copycat_hidden_1")
	assert_eq(_text(&"saffron_copycat_hidden_1_text"), ["{player} trouve une Pépite !"])
	for examine: String in ["ordinateur", "console"]:
		var spot: Vector2i = plan.cells_at(examine)[0]
		assert_not_null(map.get_interactions().find(spot, Vector2i.UP), examine)
	var pidgey := _load_map(&"saffron_pidgey_house")
	var letter: Vector2i = _plan("safrania_maison_roucool").cells_at("lettre")[0]
	assert_not_null(pidgey.get_interactions().find(letter, Vector2i.DOWN), "lettre")


# --- Aucune condition de Badge ---------------------------------------------------------------

func test_no_badge_condition_in_the_life_data() -> void:
	var paths: Array[String] = [DIALOGUES, CUTSCENES, "res://data/npcs/saffron_city.json"]
	for id: StringName in INTERIORS:
		paths.append("res://data/npcs/%s.json" % id)
	for path: String in paths:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.is_empty(), path)
		assert_false(text.contains("badge"), "%s : aucune condition de Badge" % path)
	assert_true(FileAccess.get_file_as_string("res://data/npcs/saffron_city.json")
		.contains(String(FLAG)))
