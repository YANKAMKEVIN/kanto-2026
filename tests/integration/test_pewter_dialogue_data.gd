extends GutTest
## Dialogues, scènes et PNJ du jalon 10 (T8 ; docs/tech/jalon-10.md §2.5, §2.6, §2.10–§2.12),
## avant leurs cartes : noms affichés du lot validé (textes-brouillon-j10.md, D), réactions au
## badge seulement chez qui peut savoir (arbitrage 6), Pierre (scène écrite, allusion au rival
## après le badge), Liam (trois répliques), garde de la Route 3 (Q-2), et cases des PNJ = cases
## des grilles corrigées au T1 (tools/plans/). Mot pour mot : test_dialogue_data.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const LOT := "res://docs/design/textes/textes-brouillon-j10.md"
## Cases praticables des grilles extérieures (celles de tools/art/plan_check_argenta.py).
const OUTDOOR_WALKABLE := ".=hvDp"
## Carte → [grille, PNJ → position de la grille].
const NPC_PLAN := {
	&"route_2_north": ["res://tools/plans/route_2_nord.txt", {
		&"mountaineer": "montagnard", &"route_2_north_ball_1": "potion",
	}],
	&"pewter_city": ["res://tools/plans/argenta.txt", {
		&"stonemason": "tailleur", &"stonemason_geodude": "racaillou_tailleur",
		&"kid": "enfant", &"visitor": "visiteuse", &"old_man": "vieil_habitant",
		&"lass": "jeune_dresseuse", &"museum_clerk": "employe_musee",
		&"route_3_guard": "garde_route_3", &"route_3_guard_aside": "garde_route_3_apres",
	}],
	&"pewter_gym": ["res://tools/plans/argenta_arene.txt", {
		&"brock": "pierre", &"camper_liam": "liam", &"gym_guide": "guide",
	}],
	&"pewter_museum_science": ["res://tools/plans/argenta_musee_science.txt", {
		&"researcher": "chercheur", &"researcher_f": "chercheuse",
	}],
	# Jalon 10 (T13) : grilles des maisons (défauts de la règle 4).
	&"pewter_house_mason": ["res://tools/plans/argenta_maison_tailleur.txt", {
		&"partner": "compagne", &"kid": "enfant",
	}],
	&"pewter_house_researcher": ["res://tools/plans/argenta_maison_chercheuse.txt", {
		&"researcher": "chercheuse",
	}],
}

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()


func _texts(variant: DialogueVariant) -> Array[String]:
	var texts: Array[String] = []
	for page: DialoguePage in variant.pages:
		texts.append(page.text)
	return texts


func test_speakers_are_the_validated_names() -> void:
	# Lot D (n° 26 à 41) ; panneaux sans locuteur ; vitrines, journal, éboulis, porte du
	# laboratoire et panneau d'exposition en narration.
	var expected: Dictionary[StringName, Array] = {
		&"route_2_north_sign": ["", false], &"route_2_north_mountaineer": ["Montagnard", false],
		&"route_2_north_rockslide": ["", true],
		&"pewter_city_sign": ["", false], &"pewter_museum_sign": ["", false],
		&"pewter_gym_sign": ["", false], &"pewter_stonemason": ["Tailleur de pierre", false],
		&"pewter_kid": ["Enfant", false], &"pewter_visitor": ["Visiteuse", false],
		&"pewter_old_man": ["Vieil homme", false], &"pewter_lass": ["Dresseuse", false],
		&"pewter_museum_clerk": ["Employé du Musée", false],
		&"pewter_route_3_guard": ["Garde", false], &"pewter_route_3_guard_rule": ["Garde", false],
		&"pewter_route_3_guard_cleared": ["Garde", false],
		&"pewter_museum_dome": ["", true], &"pewter_museum_helix": ["", true],
		&"pewter_museum_moon_stone": ["", true], &"pewter_museum_journal": ["", true],
		&"pewter_museum_science_panel": ["", true], &"pewter_museum_lab_sign": ["", false],
		&"pewter_museum_lab_door": ["", true],
		&"pewter_museum_researcher": ["Chercheur", false],
		&"pewter_museum_researcher_f": ["Chercheuse", false],
		&"pewter_gym_guide": ["Guide", false], &"pewter_gym_liam_before": ["Campeur Liam", false],
		&"pewter_gym_liam_defeated": ["Campeur Liam", false],
		&"pewter_gym_liam_after": ["Campeur Liam", false], &"pewter_gym_brock": ["Pierre", false],
		&"pewter_gym_brock_intro": ["Pierre", false], &"pewter_gym_brock_resume": ["Pierre", false],
		&"pewter_gym_brock_won": ["Pierre", false], &"pewter_gym_brock_badge": ["Pierre", false],
		&"pewter_gym_brock_lost": ["Pierre", false],
		&"pewter_house_mason_partner": ["Habitante", false],
		&"pewter_house_mason_kid": ["Enfant", false],
		&"pewter_house_researcher": ["Chercheuse", false],
	}
	var lot := FileAccess.get_file_as_string(LOT)
	for id: StringName in expected:
		var dialogue := _dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		if dialogue == null:
			continue
		assert_eq([dialogue.speaker, dialogue.narration], expected[id], String(id))
		if not dialogue.speaker.is_empty():
			assert_true(lot.contains("| « %s » |" % dialogue.speaker), "%s : nom du lot" % id)


func test_only_who_can_know_reacts_to_the_badge() -> void:
	# Arbitrage 6 : l'enfant, la jeune Dresseuse, le guide, le Montagnard (qui le remarque) ;
	# Pierre (allusion au rival après la victoire, arbitrage 19).
	var reacting: Array[StringName] = []
	for id: StringName in _dialogues.get_ids():
		var name := String(id)
		if not (name.begins_with("pewter_") or name.begins_with("route_2_north")):
			continue
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			if variant.if_flags.has(&"badge_boulder"):
				reacting.append(id)
	assert_eq(reacting, [&"pewter_gym_brock", &"pewter_gym_guide", &"pewter_kid",
		&"pewter_lass", &"route_2_north_mountaineer"] as Array[StringName])
	var flags := StoryFlags.new()
	var kid := _dialogues.get_dialogue(&"pewter_kid")
	assert_eq(_texts(kid.pick(flags)), ["Pierre connaît tout sur les Pokémon Roche !"]
		as Array[String])
	flags.set_flag(&"badge_boulder")
	assert_eq(_texts(kid.pick(flags)), ["Tu l'as vraiment battu ?!"] as Array[String])


func test_brock_talks_through_his_scene_until_the_badge() -> void:
	var brock := _dialogues.get_dialogue(&"pewter_gym_brock")
	var flags := StoryFlags.new()
	var before := brock.pick(flags)
	assert_eq(before.cutscene, &"pewter_gym_brock")
	assert_true(before.pages.is_empty(), "la scène porte l'introduction")
	flags.set_flag(&"badge_boulder")
	assert_eq(_texts(brock.pick(flags)), ["Un autre Dresseur de Bourg Palette\nest passé récemment.",
		"Vous avez des façons de combattre\ntrès différentes."] as Array[String])
	# Scène : introduction la première fois, reprise ensuite (brock_met), combat qui lève le badge,
	# victoire puis réplique du badge, ou défaite puis réveil.
	var scene := _cutscenes.get_cutscene(&"pewter_gym_brock")
	assert_eq(scene.variants.size(), 1)
	assert_eq(scene.variants[0].unless_flags, [&"badge_boulder"] as Array[StringName])
	var kinds: Array[StringName] = []
	for step: CutsceneStep in scene.variants[0].steps:
		kinds.append(CutsceneStep.kind_name(step.kind))
	assert_eq(kinds, [&"face", &"dialogue", &"dialogue", &"champion_card", &"set", &"battle",
		&"wait", &"dialogue", &"badge", &"dialogue", &"dialogue", &"wake_up"] as Array[StringName])
	var steps := scene.variants[0].steps
	assert_eq([steps[1].dialogue_id, steps[1].unless_flags],
		[&"pewter_gym_brock_intro", [&"brock_met"] as Array[StringName]])
	assert_eq([steps[2].dialogue_id, steps[2].if_flags],
		[&"pewter_gym_brock_resume", [&"brock_met"] as Array[StringName]])
	# Jalon 10 (QA 10C, défaut retenu par Kevin) : la carte de présentation seulement au premier
	# combat (avant que brock_met soit posé), jamais aux revanches.
	assert_eq([steps[3].trainer_id, steps[3].if_flags, steps[3].unless_flags],
		[&"pewter_gym_brock", [] as Array[StringName], [&"brock_met"] as Array[StringName]])
	assert_eq(steps[4].flags, [&"brock_met"] as Array[StringName])
	assert_eq([steps[5].trainer_id, steps[5].win_flags],
		[&"pewter_gym_brock", [&"badge_boulder"] as Array[StringName]])
	assert_eq(steps[7].dialogue_id, &"pewter_gym_brock_won")
	# « BADGE ROCHE » entre la réplique de victoire et celle du badge (dossier 12 §13).
	assert_eq([steps[8].badge_id, steps[8].if_flags],
		[&"boulder", [&"badge_boulder"] as Array[StringName]])
	assert_eq(steps[9].dialogue_id, &"pewter_gym_brock_badge")
	assert_eq(steps[10].dialogue_id, &"pewter_gym_brock_lost")


func test_liam_has_three_lines() -> void:
	var lines: Array[String] = []
	for suffix: String in ["_before", "_defeated", "_after"]:
		var dialogue := _dialogues.get_dialogue(StringName("pewter_gym_liam" + suffix))
		assert_eq(dialogue.variants.size(), 1, suffix)
		lines.append_array(_texts(dialogue.variants[0]))
	assert_eq(lines, ["Pour atteindre Pierre, il faudra\nd'abord passer par moi !",
		"D'accord… Tu es prêt.", "Pierre est encore plus solide."] as Array[String])
	var roster := NpcRoster.load_for_map(&"pewter_gym")
	var liam := roster.get_spec(&"camper_liam")
	assert_true(liam.is_trainer())
	assert_eq([liam.trainer_id, liam.sight, liam.before_dialogue, liam.dialogue],
		[&"pewter_gym_liam", 5, &"pewter_gym_liam_before", &"pewter_gym_liam_after"])
	# Jalon 10 (T9) : la réplique « vaincu », dite une fois juste après la victoire.
	assert_eq(liam.defeated_dialogue, &"pewter_gym_liam_defeated")
	var sequence := TrainerEncounter.build(&"camper_liam", liam, TrainerEncounter.TALKED_TO)
	var said: Array[StringName] = []
	for step: CutsceneStep in sequence.steps:
		if step.kind == CutsceneStep.Kind.DIALOGUE:
			said.append(step.dialogue_id)
	assert_eq(said, [&"pewter_gym_liam_before", &"pewter_gym_liam_defeated"]
		as Array[StringName], "avant, puis « D'accord… Tu es prêt. » à la victoire")
	assert_eq(liam.facing, Vector2i.RIGHT)
	assert_false(roster.get_spec(&"brock").is_trainer(), "Pierre : on vient lui parler")


func test_route_3_guard_rule_then_one_step_aside_after_the_badge() -> void:
	var scene := _cutscenes.get_cutscene(&"route_3_guard")
	var flags := StoryFlags.new()
	flags.set_flag(&"pewter_arrived")
	var before := scene.pick(flags)
	assert_same(before, scene.variants[0])
	var last := before.steps.back() as CutsceneStep
	assert_eq([last.actor, last.path, last.keep_facing],
		[NpcRoster.PLAYER_ID, [Vector2i.LEFT] as Array[Vector2i], true], "recul d'une case")
	assert_same(scene.pick(flags), before, "rejouée à chaque passage sans le badge")
	flags.set_flag(&"badge_boulder")
	var after := scene.pick(flags)
	assert_same(after, scene.variants[1])
	assert_eq((after.steps.back() as CutsceneStep).flags,
		[&"route_3_guard_cleared"] as Array[StringName])
	flags.set_flag(&"route_3_guard_cleared")
	assert_null(scene.pick(flags), "une seule fois (Q-2)")
	var roster := NpcRoster.load_for_map(&"pewter_city")
	assert_eq(roster.get_spec(&"route_3_guard").unless_flags,
		[&"route_3_guard_cleared"] as Array[StringName])
	assert_eq(roster.get_spec(&"route_3_guard_aside").if_flags,
		[&"route_3_guard_cleared"] as Array[StringName])
	assert_eq(roster.get_spec(&"route_3_guard_aside").cell,
		roster.get_spec(&"route_3_guard").cell + Vector2i.UP, "un pas de côté vers le nord")


func test_npcs_stand_on_their_grid_positions() -> void:
	for map_id: StringName in NPC_PLAN:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(NPC_PLAN[map_id][0]), plan.error)
		var places: Dictionary = NPC_PLAN[map_id][1]
		var roster := NpcRoster.load_for_map(map_id)
		assert_eq(roster.get_errors().size(), 0, String(map_id))
		var ids: Array[StringName] = []
		for spec: NpcSpec in roster.get_all():
			ids.append(spec.id)
			assert_true(places.has(spec.id), "%s : %s placé par la grille" % [map_id, spec.id])
			if not places.has(spec.id):
				continue
			var position: Dictionary = plan.positions.get(places[spec.id], {})
			assert_false(position.is_empty(), "%s : position %s" % [map_id, places[spec.id]])
			var allowed: Array = position.get("cells", [])
			var cells: Array[Vector2i] = [spec.cell]
			cells.append_array(spec.route_cells)
			for cell: Vector2i in cells:
				assert_true(allowed.has(cell), "%s : %s en %s" % [map_id, spec.id, cell])
				if map_id in [&"route_2_north", &"pewter_city"]:
					assert_true(OUTDOOR_WALKABLE.contains(plan.at(cell)),
						"%s : %s sur une case praticable (%s)" % [map_id, spec.id, cell])
		assert_eq(ids.size(), places.size(), String(map_id))


func test_one_model_per_map() -> void:
	# Défaut du plan (§1.4) : jamais deux fois le même modèle sur une carte (sauf le garde, une
	# seule personne en deux entrées exclusives).
	for map_id: StringName in NPC_PLAN:
		var seen: Dictionary = {}
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			if spec.id == &"route_3_guard_aside":
				continue
			assert_false(seen.has(spec.sprite), "%s : %s deux fois" % [map_id, spec.sprite])
			seen[spec.sprite] = true
