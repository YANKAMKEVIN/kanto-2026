extends GutTest
## Route 16 est et raccord de Céladopole (jalon 21 T22, docs/tech/jalon-21.md §2.10, §2.12 ;
## dossier 24 §9, §10.2, §15.7, §15.8) sur la vraie scène `route_16` : **grille de la scène = grille
## fonctionnelle** `tools/plans/route_16.txt` case par case, raccord de Céladopole aller-retour
## (`obstacle_ouest` retiré), Ronflex 2 × 2 sans contournement (recherche de chemin), cases libres
## après `snorlax_route_16_done`, porte du poste « à venir », aucune herbe ni rencontre, aucun texte
## sur le Vélo (L-4), indépendance des drapeaux (aucune donnée du Ronflex 16 ne cite
## `snorlax_route_12_*`), dialogue et scène du réveil, métadonnées (lumière, zone, fond de combat),
## budgets (nœuds, halos), départ `snorlax_16_qa`.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MAP_PATH := "res://game/world/maps/route_16.tscn"
const CITY_PATH := "res://game/world/maps/celadon_city.tscn"
const PLAN_PATH := "res://tools/plans/route_16.txt"
const SIZE := Vector2i(44, 28)
const WALKABLE := "=D"
const NODE_BUDGET := 3000
const HALO_BUDGET := 16
const DONE := &"snorlax_route_16_done"
const EAST: Array[Vector2i] = [Vector2i(43, 21), Vector2i(43, 22), Vector2i(43, 23)]
## Triées (x puis y), comme `Array.sort()` les rend.
const SNORLAX: Array[Vector2i] = [Vector2i(24, 22), Vector2i(24, 23), Vector2i(25, 22),
	Vector2i(25, 23)]
const FACE: Array[Vector2i] = [Vector2i(26, 22), Vector2i(26, 23)]
const DOOR: Array[Vector2i] = [Vector2i(15, 20), Vector2i(16, 20)]
## Fichiers de données du Ronflex 16 (dialogues et scènes).
const DATA_FILES: Array[String] = [
	"res://data/dialogues/j21_snorlax_16.json", "res://data/cutscenes/j21_snorlax_16.json",
]
const START_PATH := "res://tools/debug_start/snorlax_16_qa.json"

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_plan.walkable = WALKABLE
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


func _flags(raised: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


## Raccord est : arrivée sans aucun drapeau (Ronflex à sa place).
func _asleep() -> void:
	_map.apply_flag_gates(_flags([]))


func _done() -> void:
	_map.apply_flag_gates(_flags([DONE]))


func test_metadata_light_zone_and_battle_decor() -> void:
	assert_eq(_map.map_id, &"route_16")
	assert_eq(_map.display_name, "Route 16")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour", "lumière golden_hour [D]")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"route_16"), &"golden_hour")
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq(zones.zone_of(&"route_16"), &"route_16")
	var zone := zones.get_zone(&"route_16")
	assert_eq(zone.name, "Route 16")
	assert_eq(zone.description, "Une route boisée à l'ouest de Céladopole.", "§15.8.4")
	var decors := BattleDecorCatalog.load_file()
	var decor := decors.default_for(&"route_16")
	assert_not_null(decor)
	if decor != null:
		assert_eq(decor.id, &"route_5_6_prairie", "fond de combat [D]")


func test_scene_grid_is_the_functional_grid() -> void:
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var solid := not _plan.is_walkable(cell)
			if _grid.is_solid(cell) != solid or _grid.is_tall_grass(cell):
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell), _grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/route_16.txt")
	assert_eq(_plan.cells_of("h").size(), 0, "aucune herbe dans la grille")


func test_east_link_with_celadon_round_trip() -> void:
	var city := (load(CITY_PATH) as PackedScene).instantiate() as GameMap
	add_child(city)
	for i: int in 3:
		var y := 21 + i
		# Route 16 → Céladopole : PUSH → sur la rangée du raccord.
		var out := _map.get_warps().find_on_push(EAST[i], Vector2i.RIGHT)
		assert_not_null(out, "warp_est (43, %d)" % y)
		if out == null:
			continue
		assert_eq(out.target_map, &"celadon_city")
		assert_true(city.has_spawn(out.target_spawn), "arrivée %s" % out.target_spawn)
		assert_eq(city.get_spawn_cell(out.target_spawn), Vector2i(1, y), "(1, %d)" % y)
		assert_eq(out.facing, Vector2i.RIGHT, "arrivée tournée →")
		# Céladopole → Route 16 : le warp ouest de la même rangée rend la case de départ.
		var back := city.get_warps().find_on_push(Vector2i(0, y), Vector2i.LEFT)
		assert_not_null(back, "warp_ouest (0, %d)" % y)
		if back == null:
			continue
		assert_eq(back.target_map, &"route_16")
		assert_true(_map.has_spawn(back.target_spawn))
		assert_eq(_map.get_spawn_cell(back.target_spawn), EAST[i], "même rangée au retour")
		assert_eq(back.facing, Vector2i.LEFT, "arrivée tournée ←")
		assert_false(_grid.is_solid(_map.get_spawn_cell(back.target_spawn)))
		assert_false(city.get_grid().is_solid(city.get_spawn_cell(out.target_spawn)))
	# Les noms de la grille (`from_celadon`, `from_route_16`) existent (rangée du milieu).
	assert_eq(_map.get_spawn_cell(&"from_celadon"), EAST[1])
	assert_eq(city.get_spawn_cell(&"from_route_16"), Vector2i(1, 22))
	# `obstacle_ouest` (haie et talus du J20) est retiré avec son texte.
	for point: Node in city.get_node(^"Interactables").get_children():
		assert_ne((point as InteractPoint).dialogue_id, &"celadon_west_block")
	assert_null(city.find_child("WestBlock", true, false), "examen obstacle_ouest absent")
	for x: int in range(0, 4):
		for y: int in [21, 22, 23]:
			assert_false(city.get_grid().is_solid(Vector2i(x, y)), "chemin (%d, %d)" % [x, y])
	city.free()
	assert_eq(_map.get_warps().size(), 5, "3 cases de raccord + 2 de porte, rien d'autre")


func test_snorlax_blocks_the_bottleneck_without_detour() -> void:
	_asleep()
	for cell: Vector2i in SNORLAX:
		assert_true(_grid.is_occupied(cell), "Ronflex occupe %s" % cell)
	var start := _map.get_spawn_cell(&"from_celadon")
	var reached := _grid.find_reachable(start)
	for cell: Vector2i in FACE:
		assert_true(reached.has(cell), "case en face de lui atteinte %s" % cell)
	for cell: Vector2i in DOOR + [Vector2i(15, 21), Vector2i(23, 22), Vector2i(23, 23),
			Vector2i(22, 22)]:
		assert_false(reached.has(cell), "%s inatteignable tant qu'il dort (aucun contournement)" % cell)
	# La voie haute et l'arbre en décor ne sont jamais atteints, avec ou sans Ronflex.
	_done()
	var open := _grid.find_reachable(start)
	for cell: Vector2i in _plan.cells_of("Y") + _plan.cells_of("W") + _plan.cells_of("P"):
		assert_false(open.has(cell), "décor infranchissable %s" % cell)
	_asleep()
	# Même résultat sur le relief seul : Ronflex est bien la seule fermeture.
	var bare := GridPaths.relief(_grid, SIZE)
	var bare_reach := GridPaths.distances(bare, [start])
	assert_true(bare_reach.has(DOOR[0]), "sans Ronflex, la porte du poste est atteinte")


func test_cells_are_free_after_snorlax_is_done() -> void:
	var start := _map.get_spawn_cell(&"from_celadon")
	_done()
	for cell: Vector2i in SNORLAX:
		assert_false(_grid.is_occupied(cell), "libre : %s" % cell)
		assert_true(_grid.is_free(cell), "praticable : %s" % cell)
	var reached := _grid.find_reachable(start)
	for cell: Vector2i in DOOR + [Vector2i(15, 21), Vector2i(23, 22), Vector2i(11, 22)]:
		assert_true(reached.has(cell), "%s atteint après _done" % cell)
	assert_eq(GridPaths.cut_off(_grid, start).size(), 0, "tout le chemin est relié")
	var gate := _map.find_child("Ronflex", true, false) as FlagGate
	assert_not_null(gate)
	if gate != null:
		assert_false(gate.visible, "Ronflex caché")
	_asleep()
	assert_true(gate.visible, "Ronflex revient sans le drapeau (sauvegarde sans _done)")


func test_snorlax_node_gate_and_point() -> void:
	var gate := _map.find_child("Ronflex", true, false) as FlagGate
	assert_not_null(gate, "FlagGate « Ronflex »")
	if gate != null:
		assert_eq(gate.unless_flags, [DONE] as Array[StringName])
		var cells := gate.blocking_cells.duplicate()
		cells.sort()
		assert_eq(cells, SNORLAX, "bloque ses 2 × 2 cases")
		var props := gate.get_node_or_null(^"Snorlax")
		assert_not_null(props, "nœud Snorlax (sprite endormi)")
		if props != null:
			assert_true(props.is_in_group(&"scene_props"), "groupe scene_props")
			assert_not_null(props.get_node_or_null(^"Sprite"))
	var points: Array[InteractPoint] = []
	for node: Node in _map.get_node(^"Interactables").get_children():
		points.append(node as InteractPoint)
	assert_eq(points.size(), 1, "AUCUN examen : le seul point est celui de Ronflex")
	var point := points[0]
	assert_eq(point.dialogue_id, &"snorlax_route_16")
	assert_eq(point.size, Vector2i(2, 2))
	assert_eq(point.unless_flags, [DONE] as Array[StringName])
	assert_eq(point.flute_cutscene, &"snorlax_route_16_wake")
	var cells := point.get_cells()
	cells.sort()
	assert_eq(cells, SNORLAX)
	# La Flûte : une cible, sur les 4 cases ; touchée depuis les cases face_ronflex.
	var targets := _map.flute_targets()
	assert_eq(targets.size(), 1)
	var flags := _flags([])
	for cell: Vector2i in FACE:
		assert_eq(PokeFluteRules.field_target(targets, cell, flags), &"snorlax_route_16_wake")
	assert_eq(PokeFluteRules.field_target(targets, Vector2i(40, 22), flags), &"", "trop loin")
	assert_eq(PokeFluteRules.field_target(targets, FACE[0], _flags([DONE])), &"",
		"plus de cible après _done")
	var faces := _plan.cells_at("face_ronflex")
	faces.sort()
	assert_eq(faces, FACE, "repères face_ronflex")


func test_poste_door_is_coming_soon_without_text_about_the_bike() -> void:
	for cell: Vector2i in DOOR:
		var warp := _map.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(warp, "porte du poste %s" % cell)
		if warp == null:
			continue
		assert_true(warp.is_coming_soon(), "« à venir »")
		assert_eq(warp.coming_soon, "Route 16")
		assert_true(_map.has_spawn(warp.target_spawn))
		var back := _map.get_spawn_cell(warp.target_spawn)
		assert_false(_grid.is_solid(back))
		assert_eq(back.y, 21, "retour sur le parvis")
		assert_ne(warp.facing, Vector2i.ZERO)


func test_no_grass_no_encounter_no_trainer_no_item() -> void:
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			assert_false(_grid.is_tall_grass(Vector2i(x, y)))
	for file: String in DirAccess.get_files_at("res://data/encounters/"):
		if file.get_extension() != "json":
			continue
		var text := FileAccess.get_file_as_string("res://data/encounters/" + file)
		assert_false(text.contains("route_16"), "%s : aucune rencontre sur la Route 16" % file)
	assert_eq(_map.get_npcs().size(), 0, "aucun PNJ ni Dresseur")
	assert_eq(_map.get_triggers().get_all().size(), 3, "seule la scène silencieuse du titre de zone (2e colonne)")
	for trigger: EventTrigger in _map.get_triggers().get_all():
		assert_eq(trigger.cutscene_id, &"route_16_visited")
		assert_eq(trigger.cell.x, 42)


func test_no_text_mentions_the_bike() -> void:
	var texts: Array[String] = [_map.display_name, _map.region]
	for warp: Warp in _map.get_warps().get_all():
		texts.append(warp.coming_soon)
	var zones := ZoneLibrary.new()
	zones.load_file()
	var zone := zones.get_zone(&"route_16")
	texts.append_array([zone.name, zone.subtitle, zone.description])
	for file: String in DATA_FILES:
		texts.append(FileAccess.get_file_as_string(file))
	for point: Node in _map.get_node(^"Interactables").get_children():
		var dialogue := DialogueLibrary.new()
		assert_true(dialogue.load_dir())
		for variant: DialogueVariant in dialogue.get_dialogue(
				(point as InteractPoint).dialogue_id).variants:
			for page: DialoguePage in variant.pages:
				texts.append(page.text)
	for text: String in texts:
		var lower := text.to_lower()
		for banned: String in ["vélo", "velo", "bicyclette", "cycl"]:
			assert_false(lower.contains(banned), "« %s » contient « %s »" % [text.left(40), banned])


func test_snorlax_16_data_never_cites_the_route_12_flags() -> void:
	var pattern := RegEx.create_from_string("snorlax_route_(\\d+)_")
	for file: String in DATA_FILES:
		var text := FileAccess.get_file_as_string(file)
		assert_false(text.contains("snorlax_route_12"), "%s : aucun drapeau de la Route 12" % file)
		assert_false(text.contains("snorlax_route_11"), "%s : aucun drapeau de la Route 11" % file)
		for found: RegExMatch in pattern.search_all(text):
			assert_eq(found.get_string(1), "16", "%s : %s" % [file, found.get_string()])
	# Les drapeaux de la scène (étapes, variantes) et de la carte.
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	var wake := cutscenes.get_cutscene(&"snorlax_route_16_wake")
	assert_not_null(wake)
	var cited: Array[StringName] = []
	for variant: CutsceneVariant in wake.variants:
		cited.append_array(variant.if_flags + variant.unless_flags)
		for step: CutsceneStep in variant.steps:
			cited.append_array(step.flags + step.win_flags + step.lose_flags + step.catch_flags
				+ step.if_flags + step.unless_flags)
	var gate := _map.find_child("Ronflex", true, false) as FlagGate
	cited.append_array(gate.unless_flags)
	for point: Node in _map.get_node(^"Interactables").get_children():
		cited.append_array((point as InteractPoint).unless_flags)
	assert_gt(cited.size(), 8)
	for flag: StringName in cited:
		assert_true(String(flag).begins_with("snorlax_route_16_"), String(flag))


func test_snorlax_dialogue_follows_the_plan_table() -> void:
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	var snorlax := dialogues.get_dialogue(&"snorlax_route_16")
	assert_not_null(snorlax)
	assert_true(snorlax.narration)
	var v := snorlax.variants
	assert_eq(v.size(), 4, "4 lignes du tableau §2.10")
	assert_eq(v[0].if_items, [&"poke_flute"] as Array[StringName])
	assert_eq(v[0].if_flags, [&"snorlax_route_16_woken"] as Array[StringName])
	assert_eq(v[0].pages[0].text, "Ronflex dort de nouveau.", "§15.7.5")
	assert_eq(v[0].pages[1].text, "Il ronfle comme si de rien n'était.")
	assert_eq(v[0].pages[-1].text, "Jouer de la Poké Flûte ?", "§15.6.7")
	assert_eq(v[1].if_items, [&"poke_flute"] as Array[StringName])
	assert_eq(v[1].pages[0].text, "Jouer de la Poké Flûte ?")
	for i: int in 2:
		assert_not_null(v[i].choice)
		assert_eq(v[i].choice.confirm_label, "OUI")
		assert_eq(v[i].choice.cancel_label, "NON")
		assert_eq(v[i].choice.confirm_cutscene, &"snorlax_route_16_wake")
	assert_eq(v[2].unless_flags, [&"snorlax_route_16_seen"] as Array[StringName])
	assert_eq(v[2].set_flags, [&"snorlax_route_16_seen"] as Array[StringName])
	# T-6 / T-7 : mot pour mot ceux de `route_11_snorlax` (J17).
	var old := dialogues.get_dialogue(&"route_11_snorlax")
	for pair: Array in [[2, 0], [3, 1]]:
		var new_pages: Array[String] = []
		var old_pages: Array[String] = []
		for page: DialoguePage in v[pair[0]].pages:
			new_pages.append(page.text)
		for page: DialoguePage in old.variants[pair[1]].pages:
			old_pages.append(page.text)
		assert_eq(new_pages, old_pages, "T-%d" % (6 + pair[1]))
	var texts := {
		&"snorlax_flute_played_16": ["{player} joue de la Poké Flûte."],
		&"snorlax_wakes_16": ["Ronflex se réveille !", "Il attaque, de très mauvaise humeur !"],
		&"snorlax_calms_16": ["Ronflex se calme…",
			"Avec un grand bâillement, il retourne dans les montagnes."],
		&"snorlax_sleeps_16": ["Ronflex bâille…", "et se rendort aussitôt."],
	}
	for id: StringName in texts:
		var dialogue := dialogues.get_dialogue(id)
		assert_not_null(dialogue, id)
		var pages: Array[String] = []
		for page: DialoguePage in dialogue.variants[0].pages:
			pages.append(page.text)
		assert_eq(pages, texts[id], id)


func test_wake_cutscene_uses_existing_steps_only() -> void:
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir(), "\n".join(cutscenes.get_errors()))
	var wake := cutscenes.get_cutscene(&"snorlax_route_16_wake")
	assert_not_null(wake)
	assert_eq(wake.variants.size(), 1)
	var variant: CutsceneVariant = wake.variants[0]
	assert_eq(variant.unless_flags, [DONE] as Array[StringName])
	var kinds: Array[CutsceneStep.Kind] = []
	for step: CutsceneStep in variant.steps:
		kinds.append(step.kind)
	assert_eq(kinds, [CutsceneStep.Kind.DIALOGUE, CutsceneStep.Kind.DIALOGUE,
		CutsceneStep.Kind.SET_FLAGS, CutsceneStep.Kind.WILD_BATTLE, CutsceneStep.Kind.DIALOGUE,
		CutsceneStep.Kind.DIALOGUE] as Array[CutsceneStep.Kind])
	var steps := variant.steps
	assert_eq(steps[0].dialogue_id, &"snorlax_flute_played_16")
	assert_eq(steps[1].dialogue_id, &"snorlax_wakes_16")
	assert_eq(steps[2].flags, [&"snorlax_route_16_awake", &"snorlax_route_16_woken"] as Array[StringName])
	assert_eq(steps[3].species, &"snorlax")
	assert_eq(steps[3].level, 30)
	assert_eq(steps[3].win_flags, [DONE] as Array[StringName])
	assert_eq(steps[3].catch_flags, [DONE, &"snorlax_route_16_caught"] as Array[StringName])
	assert_eq(steps[4].dialogue_id, &"snorlax_calms_16")
	assert_eq(steps[4].if_flags, [DONE] as Array[StringName])
	assert_eq(steps[4].unless_flags, [&"snorlax_route_16_caught"] as Array[StringName])
	assert_eq(steps[5].dialogue_id, &"snorlax_sleeps_16")
	assert_eq(steps[5].unless_flags, [DONE] as Array[StringName])
	# Titre de zone : drapeau posé une seule fois.
	var visited := cutscenes.get_cutscene(&"route_16_visited")
	assert_not_null(visited)
	assert_eq(visited.variants[0].unless_flags, [&"route_16_visited"] as Array[StringName])
	assert_eq(visited.variants[0].steps[0].flags, [&"route_16_visited"] as Array[StringName])


func test_budgets_no_light2d_and_painted_ground() -> void:
	assert_lte(GridPaths.count_nodes(_map), NODE_BUDGET, "≤ 3 000 nœuds")
	assert_lte(_map.find_children("*", "LightGlow", true, false).size(), HALO_BUDGET, "≤ 16 halos")
	assert_eq(_map.find_children("*", "Light2D", true, false).size(), 0, "aucune Light2D")
	assert_not_null(_map.get_node_or_null(^"PaintedGround"), "sol peint")
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_the_qa_start_stands_in_front_of_snorlax_with_the_flute() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	var start := DebugStart.new()
	assert_true(start.load_file(START_PATH, data, items), "\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"route_16", &"face_ronflex", Vector2i.LEFT])
	assert_eq(_map.get_spawn_cell(start.spawn), Vector2i(26, 22))
	assert_eq(int(start.bag[&"poke_flute"]), 1)
	assert_eq(int(start.bag[&"poke_ball"]), 1)
	assert_true(start.flags.has(&"got_poke_flute"))
	for flag: StringName in [&"snorlax_route_16_done", &"snorlax_route_16_woken",
			&"snorlax_route_16_awake", &"route_16_visited"]:
		assert_false(start.flags.has(flag), String(flag))
	var sleeper := 0
	for member: Dictionary in start.party:
		if member.get("status", "") == "sleep":
			sleeper += 1
	assert_eq(sleeper, 1, "un Pokémon endormi dans l'équipe")
