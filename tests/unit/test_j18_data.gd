extends GutTest
## Données du jalon 18 hors Dresseurs (T16 ; docs/tech/jalon-18.md §4.6, §4.8–4.10, §4.13,
## §4.14) : rencontres (dossier 21 §3.2, §4.4, §5.4), textes T-3, T-5 à T-10, T-17 à T-41, T-56
## (lot validé par Kevin le 2026-10-14) et A-1 à A-9 (annexe A du plan, validée le 2026-10-15)
## **mot pour mot**, PNJ et objets aux cases réservées des grilles, objectifs, zones, compagnon.
## Flash (T-2, moteur), légende multiple et points d'examen des cartes : après la clôture du J17
## (T17, T18, T20, T24). Fichier séparé des tests partagés que d'autres jalons modifient.

const DOSSIER := "res://docs/design/dossier-21-grotte-sombre-lavanville.md"
const PLAN := "res://docs/tech/jalon-18.md"
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

## Table → [carte, terrain, [espèce, niveau min, niveau max, poids]…] (poids [D] du dossier).
const TABLES := {
	&"route_9_grass": [&"route_9", &"grass", [[&"rattata", 14, 17, 30], [&"spearow", 13, 17, 35],
		[&"ekans", 11, 17, 18], [&"sandshrew", 11, 17, 17]]],
	&"route_10_grass": [&"route_10", &"grass", [[&"voltorb", 14, 17, 30],
		[&"spearow", 13, 17, 35], [&"ekans", 11, 17, 18], [&"sandshrew", 11, 17, 17]]],
	&"dark_cave_1f_rubble": [&"dark_cave_1f", &"rubble", [[&"zubat", 15, 18, 45],
		[&"geodude", 16, 17, 25], [&"machop", 15, 17, 20], [&"onix", 13, 15, 10]]],
	&"dark_cave_b1f_rubble": [&"dark_cave_b1f", &"rubble", [[&"zubat", 16, 18, 35],
		[&"geodude", 16, 18, 30], [&"machop", 15, 17, 20], [&"onix", 13, 17, 15]]],
}
## Texte du lot → [dialogue, forme] ; forme « sign » : chaque « / » du dossier est un retour à
## la ligne du panneau ; « speech » : pages et lignes jointes par une espace.
const TEXTS := {
	"T-3": [&"dark_cave_too_dark", "speech"],
	"T-5": [&"route_10_cave_sign", "sign"],
	"T-6": [&"dark_cave_1f_sign", "speech"],
	"T-7": [&"route_10_hiker", "speech"],
	"T-8": [&"dark_cave_column", "speech"],
	"T-9": [&"dark_cave_roots", "speech"],
	"T-10": [&"dark_cave_crack", "speech"],
	"T-18": [&"lavender_town_sign", "sign"],
	"T-19": [&"lavender_tower_sign", "sign"],
	"T-20": [&"lavender_pokemon_house_sign", "sign"],
	"T-21": [&"lavender_girl", "speech"],
	"T-22": [&"lavender_young_man", "speech"],
	"T-23": [&"lavender_passerby", "speech"],
	"T-24": [&"lavender_bouquet_woman", "speech"],
	"T-27": [&"lavender_house_1_old_lady", "speech"],
	"T-30": [&"pokemon_tower_keeper", "speech"],
	"T-31": [&"pokemon_tower_visitor_f", "speech"],
	"T-32": [&"pokemon_tower_visitor_m", "speech"],
	"T-33": [&"pokemon_tower_girl", "speech"],
	"T-36": [&"pokemon_tower_grave_1", "speech"],
	"T-37": [&"pokemon_tower_grave_2", "speech"],
	"T-38": [&"pokemon_tower_grave_3", "speech"],
	"T-39": [&"pokemon_tower_grave_4", "speech"],
	"T-40": [&"pokemon_tower_grave_5", "speech"],
	"T-41": [&"pokemon_tower_grave", "speech"],
}
## Textes dits en deux temps (première fois, puis ensuite) : [dialogue, variante].
const TWO_STEP := {
	# J19 (T20) : T-25 est remplacé par §15.6.1 (`test_lavender_j19`) ; T-26 garde sa place.
	"T-26": [&"pokemon_house_kid", 1],
}
## J19 (T16) : T-34 et T-35 (Exorciste) sont remplacés par la scène `tower_guardian` et le
## texte §15.1.5 du dossier 22 (`test_pokemon_tower_1f_j19`, `test_tower_texts`).
## Le couple de la maison 2 dit le même texte (T-28), chacun avec son nom.
const COUPLE: Array[StringName] = [&"lavender_house_2_wife", &"lavender_house_2_husband"]
## PNJ (hors Dresseurs) : carte → identifiant de la grille → [apparence, dialogue, verbe].
const NPCS := {
	&"route_9": {
		&"route_9_item_1": [&"object/poke_ball_ground", &"route_9_item_1", Interaction.Kind.TAKE],
		&"route_9_item_2": [&"object/poke_ball_ground", &"route_9_item_2", Interaction.Kind.TAKE],
		&"route_9_item_3": [&"object/poke_ball_ground", &"route_9_item_3", Interaction.Kind.TAKE],
		&"piafabec_1": [&"pokemon/spearow", &"", Interaction.Kind.TALK],
		&"racaillou_1": [&"pokemon/geodude", &"", Interaction.Kind.TALK],
	},
	&"route_10": {
		&"randonneur": [&"mountaineer", &"route_10_hiker", Interaction.Kind.TALK],
		&"route_10_item_1": [&"object/poke_ball_ground", &"route_10_item_1",
			Interaction.Kind.TAKE],
	},
	&"dark_cave_1f": {
		&"dark_cave_1f_item_1": [&"object/poke_ball_ground", &"dark_cave_1f_item_1",
			Interaction.Kind.TAKE],
		&"dark_cave_1f_item_2": [&"object/poke_ball_ground", &"dark_cave_1f_item_2",
			Interaction.Kind.TAKE],
	},
	&"dark_cave_b1f": {
		&"dark_cave_b1f_item_1": [&"object/poke_ball_ground", &"dark_cave_b1f_item_1",
			Interaction.Kind.TAKE],
	},
	&"lavender_town": {
		&"l1_fillette": [&"lass_young", &"lavender_girl", Interaction.Kind.TALK],
		&"l2_jeune_homme": [&"youngster", &"lavender_young_man", Interaction.Kind.TALK],
		&"l3_passant": [&"traveler", &"lavender_passerby", Interaction.Kind.TALK],
		&"l4_femme_bouquet": [&"lass", &"lavender_bouquet_woman", Interaction.Kind.TALK],
	},
	&"pokemon_house": {
		&"rondoudou": [&"pokemon/jigglypuff", &"", Interaction.Kind.TALK],
		&"enfant": [&"kid", &"pokemon_house_kid", Interaction.Kind.TALK],
		&"nidoran_f": [&"pokemon/nidoran_f", &"", Interaction.Kind.TALK],
	},
	&"lavender_house_1": {
		&"habitante": [&"old_man", &"lavender_house_1_old_lady", Interaction.Kind.TALK],
	},
	&"lavender_house_2": {
		&"habitant_1": [&"traveler", &"lavender_house_2_husband", Interaction.Kind.TALK],
		&"habitant_2": [&"lass", &"lavender_house_2_wife", Interaction.Kind.TALK],
	},
	&"pokemon_tower_1f": {
		&"gardien": [&"old_man", &"pokemon_tower_keeper", Interaction.Kind.TALK],
		&"visiteuse": [&"lass", &"pokemon_tower_visitor_f", Interaction.Kind.TALK],
		&"visiteur": [&"traveler", &"pokemon_tower_visitor_m", Interaction.Kind.TALK],
		&"jeune_fille": [&"lass_young", &"pokemon_tower_girl", Interaction.Kind.TALK],
		&"exorciste_gardienne": [&"channeler", &"pokemon_tower_exorcist",
			Interaction.Kind.TALK],
	},
}
const PLANS := {
	&"route_9": "res://tools/plans/route_9.txt",
	&"route_10": "res://tools/plans/route_10.txt",
	&"dark_cave_1f": "res://tools/plans/grotte_sombre_1f.txt",
	&"dark_cave_b1f": "res://tools/plans/grotte_sombre_b1f.txt",
	&"lavender_town": "res://tools/plans/lavanville.txt",
	&"pokemon_house": "res://tools/plans/lavanville_maison_pokemon.txt",
	&"lavender_house_1": "res://tools/plans/lavanville_maison_1.txt",
	&"lavender_house_2": "res://tools/plans/lavanville_maison_2.txt",
	&"pokemon_tower_1f": "res://tools/plans/tour_pokemon_rdc.txt",
}
## Objets (§4.9) : scène → [objet, quantité, PNJ à retirer (vide : objet caché)].
const ITEMS := {
	&"route_9_item_1": [&"super_potion", 1, &"route_9_item_1"],
	&"route_9_item_2": [&"antidote", 1, &"route_9_item_2"],
	&"route_9_item_3": [&"poke_ball", 2, &"route_9_item_3"],
	&"route_10_item_1": [&"super_potion", 1, &"route_10_item_1"],
	&"dark_cave_1f_item_1": [&"escape_rope", 1, &"dark_cave_1f_item_1"],
	&"dark_cave_1f_item_2": [&"antidote", 1, &"dark_cave_1f_item_2"],
	&"dark_cave_b1f_item_1": [&"super_potion", 1, &"dark_cave_b1f_item_1"],
	&"dark_cave_b1f_hidden_1": [&"super_potion", 1, &""],
}
## Objectifs (§4.13) : identifiant → [condition, levée].
const OBJECTIVES := [
	[&"tower_later", [&"tower_medium_talked"], []],
	[&"visit_tower", [&"lavender_reached"], [&"tower_medium_talked"]],
	[&"reach_lavender", [&"dark_cave_crossed"], [&"lavender_reached"]],
	[&"cross_dark_cave", [&"route_10_reached"], [&"dark_cave_crossed"]],
	[&"cross_route_9", [&"route_9_entered"], [&"route_10_reached"]],
]

var _dossier: String
var _plan: String
var _dialogues: DialogueLibrary


func before_all() -> void:
	_dossier = FileAccess.get_file_as_string(DOSSIER)
	_plan = FileAccess.get_file_as_string(PLAN)
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()


# --- Rencontres --------------------------------------------------------------------------

func test_encounter_tables_follow_the_dossier() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var lib := EncounterLibrary.new(data)
	assert_true(lib.load_dir(), "\n".join(lib.get_errors()))
	for id: StringName in TABLES:
		var row: Array = TABLES[id]
		var table := lib.get_table(row[0], row[1])
		assert_not_null(table, String(id))
		if table == null:
			continue
		assert_eq(table.id, id)
		assert_eq([table.rate, table.ramp_from, table.ramp_max], [25, 15, 20],
			"%s : taux et rampe du J12" % id)
		var slots: Array = []
		for slot: EncounterSlot in table.slots:
			slots.append([slot.species, slot.min_level, slot.max_level, slot.weight])
		assert_eq(slots, row[2], String(id))
	assert_null(lib.get_table(&"dark_cave_1f", &"grass"), "grotte : gravats seulement (I-10)")


# --- Textes mot pour mot -----------------------------------------------------------------

func test_texts_are_the_validated_lot() -> void:
	assert_eq(_dialogues.get_errors().size(), 0, "\n".join(_dialogues.get_errors()))
	for tag: String in TEXTS:
		var quotes := _quotes(_dossier, tag)
		assert_gt(quotes.size(), 0, tag)
		var dialogue := _dialogues.get_dialogue(TEXTS[tag][0])
		assert_not_null(dialogue, tag)
		if dialogue == null:
			continue
		assert_eq(dialogue.variants.size(), 1, tag)
		assert_false(dialogue.draft, tag)
		assert_eq(_text_of(dialogue.variants[0], TEXTS[tag][1]), " ".join(quotes), tag)


func test_texts_said_in_two_steps() -> void:
	for tag: String in TWO_STEP:
		var dialogue := _dialogues.get_dialogue(TWO_STEP[tag][0])
		assert_not_null(dialogue, tag)
		if dialogue == null:
			continue
		var variant: DialogueVariant = dialogue.variants[TWO_STEP[tag][1]]
		assert_eq(_text_of(variant, "speech"), " ".join(_quotes(_dossier, tag)), tag)
	# J19 (T16) : l'Exorciste ne pose plus `tower_medium_talked` (variantes du dossier 22 §15.1).
	var exorcist := _dialogues.get_dialogue(&"pokemon_tower_exorcist")
	assert_eq(exorcist.variants.size(), 2)
	assert_eq(exorcist.variants[0].if_flags, [&"tower_stairs_open"] as Array[StringName])
	assert_eq(exorcist.variants[1].unless_flags, [&"tower_stairs_open"] as Array[StringName])
	assert_eq(exorcist.variants[1].cutscene, &"tower_guardian")


func test_the_couple_says_the_same_text() -> void:
	for id: StringName in COUPLE:
		var dialogue := _dialogues.get_dialogue(id)
		assert_eq(_text_of(dialogue.variants[0], "speech"), " ".join(_quotes(_dossier, "T-28")),
			String(id))
	assert_eq(_dialogues.get_dialogue(COUPLE[0]).speaker, "Habitante")
	assert_eq(_dialogues.get_dialogue(COUPLE[1]).speaker, "Habitant")


func test_route_9_sign_and_annex_a() -> void:
	var sign := _text_of(_dialogues.get_dialogue(&"route_9_sign").variants[0], "sign")
	assert_true(_dossier.contains("Panneau « %s »" % sign), "§3.1 : « %s »" % sign)
	assert_eq(_text_of(_dialogues.get_dialogue(&"route_10_center_sign").variants[0], "sign"),
		_quotes(_plan, "A-9")[0], "A-9")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file(), "\n".join(zones.get_errors()))
	var expected := {
		&"route_9": ["A-1", "A-2"], &"route_10": ["A-3", "A-4"], &"dark_cave": ["A-5", "A-6"],
		&"lavender_town": ["A-7", "A-8"],
	}
	for id: StringName in expected:
		var zone := zones.get_zone(id)
		assert_not_null(zone, String(id))
		if zone == null:
			continue
		assert_eq(zone.subtitle, _quotes(_plan, expected[id][0])[0], String(id))
		assert_eq(zone.description, _quotes(_plan, expected[id][1])[0], String(id))
		assert_false(zone.draft, String(id))


func test_arrival_caption_is_in_the_list_form() -> void:
	# T-17 : l'arrivée à Lavanville est versée dans first_exit.json (forme liste, T24) ;
	# Bourg Palette (OUV.3) est inchangé.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/opening/first_exit.json"))
	var arrivals: Array = data["arrivals"]
	assert_eq(arrivals.size(), 2)
	assert_eq([arrivals[0]["map"], arrivals[0]["from"]], ["pallet_town", "player_house_1f"])
	assert_eq([arrivals[1]["map"], arrivals[1]["from"]], ["lavender_town", "route_10"])
	var zones := ZoneLibrary.new()
	zones.load_file()
	var title := "%s / %s" % [zones.get_zone(&"lavender_town").name.to_upper(),
		arrivals[1]["subtitle"]]
	assert_eq(title, _quotes(_dossier, "T-17")[0], "T-17")
	var caption := FirstExitCaption.new()
	assert_true(caption.load_file(), "first_exit.json")
	assert_eq(caption.get_map(), &"pallet_town")
	assert_eq(caption.get_maps(), [&"pallet_town", &"lavender_town"] as Array[StringName])
	assert_false(FileAccess.file_exists("res://data/opening/first_exit_j18.json"))


func test_coming_soon_labels_are_t29() -> void:
	# T-29 : libellés « À venir » des bords de Lavanville (écran existant, nom en capitales).
	# La colonne « Élément » de T-29 cite elle-même « À venir » : on garde les deux libellés.
	var quotes := _quotes(_dossier, "T-29").slice(1)
	assert_eq(quotes, ["ROUTE 8 — À venir", "ROUTE 12 — À venir"])
	var map := (load(MapCatalog.scene_path(&"lavender_town")) as PackedScene).instantiate()
	var labels: Array[String] = []
	for node: Node in map.find_children("*", "", true, false):
		if node is WarpPoint and (node as WarpPoint).coming_soon.begins_with("Route"):
			var label := "%s — À venir" % (node as WarpPoint).coming_soon.to_upper()
			if not labels.has(label):
				labels.append(label)
	map.free()
	labels.sort()
	assert_eq(labels, ["ROUTE 12 — À venir", "ROUTE 8 — À venir"] as Array[String])


func test_objectives_are_t56_in_lower_case_and_in_order() -> void:
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	var quotes := _quotes(_dossier, "T-56")
	assert_eq(quotes.size(), 5)
	var ids := library.get_ids()
	# Les objectifs du J19 (clôture T24) passent devant : ceux du J18 suivent, groupés.
	var first := ids.find(OBJECTIVES[0][0])
	assert_eq(ids.slice(0, first), [&"see_the_ghosts", &"climb_tower"] as Array[StringName])
	for i: int in OBJECTIVES.size():
		assert_eq(ids[first + i], OBJECTIVES[i][0], "objectifs du J18 groupés (§4.13)")
	# T-56 dans l'ordre du voyage ; OBJECTIVES dans l'ordre inverse (le plus avancé d'abord).
	var flags := StoryFlags.new()
	assert_eq(library.current_id(flags) in [&"tower_later", &"visit_tower", &"reach_lavender",
		&"cross_dark_cave", &"cross_route_9"], false, "rien du J18 avant la Route 9")
	var steps := [&"route_9_entered", &"route_10_reached", &"dark_cave_crossed",
		&"lavender_reached", &"tower_medium_talked"]
	for i: int in steps.size():
		flags.set_flag(steps[i])
		var expected: String = quotes[i]
		expected = expected.left(1).to_lower() + expected.substr(1)
		assert_eq(library.current(flags), expected, String(steps[i]))
		assert_eq(library.current_id(flags), OBJECTIVES[OBJECTIVES.size() - 1 - i][0])


func test_objective_flags_are_raised_by_cutscenes_and_dialogues() -> void:
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir(), "\n".join(cutscenes.get_errors()))
	for flag: StringName in [&"route_9_entered", &"route_10_reached", &"dark_cave_crossed",
			&"lavender_reached"]:
		var cutscene := cutscenes.get_cutscene(flag)
		assert_not_null(cutscene, String(flag))
		if cutscene == null:
			continue
		assert_eq(cutscene.variants.size(), 1)
		assert_eq(cutscene.variants[0].unless_flags, [flag] as Array[StringName])
		var steps := cutscene.variants[0].steps
		assert_eq(steps.size(), 1, "%s : en silence" % flag)
		assert_eq(steps[0].kind, CutsceneStep.Kind.SET_FLAGS)
		assert_eq(steps[0].flags, [flag] as Array[StringName])
	# T16 : plus aucun dialogue de la Tour ne pose `tower_medium_talked` (objectif du J18 inchangé
	# dans les données ; la scène du J19 pose `tower_stairs_open`).
	assert_false(_dialogues.get_set_flags().has(&"tower_medium_talked"))


# --- PNJ, objets -------------------------------------------------------------------------

func test_npcs_stand_on_their_reserved_cells() -> void:
	for map_id: StringName in NPCS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(PLANS[map_id]), String(map_id))
		var roster := NpcRoster.load_for_map(map_id)
		assert_eq(roster.get_errors().size(), 0, "\n".join(roster.get_errors()))
		for id: StringName in NPCS[map_id]:
			var row: Array = NPCS[map_id][id]
			var spec := roster.get_spec(id)
			assert_not_null(spec, "%s : %s" % [map_id, id])
			if spec == null:
				continue
			assert_true(plan.positions.has(String(id)), "%s : %s dans la grille" % [map_id, id])
			assert_eq(spec.cell, plan.cell_of(String(id)), "%s : %s" % [map_id, id])
			var facing := plan.attr(String(id), "facing")
			if not facing.is_empty():
				assert_eq(spec.facing, Grid.direction_from_name(facing), String(id))
			assert_eq([spec.sprite, spec.dialogue, spec.verb], row, String(id))
			if not spec.dialogue.is_empty():
				assert_true(_dialogues.has_dialogue(spec.dialogue), String(spec.dialogue))


func test_exorcist_steps_aside_with_the_j19_flag() -> void:
	var roster := NpcRoster.load_for_map(&"pokemon_tower_1f")
	var spec := roster.get_spec(&"exorciste_gardienne")
	assert_true(spec.unless_flags.is_empty(), "J19 (T16) : plus de `unless`, elle ne disparaît pas")
	assert_eq(spec.cell, Vector2i(17, 3), "seule case d'accès à l'escalier (17, 2)")
	assert_eq(spec.moved_if_flags, [&"tower_stairs_open"] as Array[StringName])
	assert_eq(spec.moved_cell, Vector2i(18, 3))
	assert_eq(spec.moved_facing, Vector2i.LEFT)
	var flags := StoryFlags.new()
	flags.set_flag(&"tower_medium_talked")
	assert_true(spec.is_present(flags))
	assert_eq(spec.placed_for(flags).cell, Vector2i(17, 3), "toujours en (17, 3) sans le drapeau")
	flags.set_flag(&"tower_stairs_open")
	assert_true(spec.is_present(flags), "elle reste dans la salle")
	assert_eq(spec.placed_for(flags).cell, Vector2i(18, 3), "(18, 3) avec le drapeau")


func test_items_are_given_once() -> void:
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	for id: StringName in ITEMS:
		var row: Array = ITEMS[id]
		assert_not_null(items.get_item(row[0]), String(row[0]))
		var dialogue := _dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		if dialogue != null:
			assert_eq(dialogue.variants[0].cutscene, id)
		var cutscene := cutscenes.get_cutscene(id)
		assert_not_null(cutscene, String(id))
		if cutscene == null:
			continue
		var got := StringName("got_%s" % id)
		assert_eq(cutscene.variants.size(), 1)
		assert_eq(cutscene.variants[0].unless_flags, [got] as Array[StringName])
		var kinds: Array = []
		for step: CutsceneStep in cutscene.variants[0].steps:
			kinds.append(step.kind)
			if step.kind == CutsceneStep.Kind.GIVE:
				assert_eq([step.item_id, step.count, step.found], [row[0], row[1], true],
					String(id))
			if step.kind == CutsceneStep.Kind.DESPAWN:
				assert_eq(step.actor, row[2], String(id))
			if step.kind == CutsceneStep.Kind.SET_FLAGS:
				assert_eq(step.flags, [got] as Array[StringName])
		var expected: Array = [CutsceneStep.Kind.GIVE, CutsceneStep.Kind.SET_FLAGS]
		if not (row[2] as StringName).is_empty():
			expected.push_front(CutsceneStep.Kind.DESPAWN)
		assert_eq(kinds, expected, String(id))


func test_items_and_hidden_item_match_the_grids() -> void:
	var expected := {
		&"route_9_item_1": [&"route_9", "super_potion", "1"],
		&"route_9_item_2": [&"route_9", "antidote", "1"],
		&"route_9_item_3": [&"route_9", "poke_ball", "2"],
		&"route_10_item_1": [&"route_10", "super_potion", "1"],
		&"dark_cave_1f_item_1": [&"dark_cave_1f", "escape_rope", "1"],
		&"dark_cave_1f_item_2": [&"dark_cave_1f", "antidote", "1"],
		&"dark_cave_b1f_item_1": [&"dark_cave_b1f", "super_potion", "1"],
		&"dark_cave_b1f_hidden_1": [&"dark_cave_b1f", "super_potion", "1"],
	}
	for id: StringName in expected:
		var row: Array = expected[id]
		var plan := PlanGrid.new()
		plan.load_file(PLANS[row[0]])
		assert_eq(plan.attr(String(id), "item"), row[1], String(id))
		var qty := plan.attr(String(id), "qty")
		assert_eq(qty if not qty.is_empty() else "1", row[2], String(id))
		assert_eq(String(ITEMS[id][0]), row[1])
		assert_eq(str(ITEMS[id][1]), row[2])


func test_companion_cave_context_and_route_10_nurse() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/pokemon/companions.json"))
	for map_id: String in ["dark_cave_1f", "dark_cave_b1f"]:
		assert_eq(data["contexts"].get(map_id), "cave", map_id)
	var nurse := NpcRoster.load_for_map(&"route_10_center").get_spec(&"nurse")
	assert_not_null(nurse, "infirmière du Centre de la Route 10")
	if nurse != null:
		assert_eq([nurse.cell, nurse.sprite], [Vector2i(7, 3), &"nurse"])


# --- Outils ------------------------------------------------------------------------------

## Texte d'une variante : pages jointes par une espace ; dans une page, un retour à la ligne vaut
## une espace (« speech ») ou « / » (« sign », panneau à titre).
func _text_of(variant: DialogueVariant, form: String) -> String:
	var texts: Array[String] = []
	for page: DialoguePage in variant.pages:
		assert_lte(page.text.split("\n").size(), 2, "bulle de deux lignes au plus")
		texts.append(page.text.replace("\n", " / " if form == "sign" else " "))
	return " ".join(texts)


## Textes « … » de la ligne de tableau [param tag] (« T-37 », « A-1 ») de [param source].
func _quotes(source: String, tag: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.create_from_string("« (.+?) »")
	for line: String in source.split("\n"):
		if line.begins_with("| %s |" % tag):
			for m: RegExMatch in regex.search_all(line):
				found.append(m.get_string(1))
	return found
