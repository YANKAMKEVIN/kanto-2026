extends GutTest
## Vie du jalon 29 (`docs/tech/jalon-29.md` §2.2 à §2.7, §5) : huit contrôles de Badge (possession
## seulement, un Badge manquant n'arrête que son poste, recul d'une case), rival n° 7 distinct du
## n° 2 (présent avec le Badge Terre, rejouable après défaite), Sulfura unique (politique
## d'Artikodin), Plateau Indigo (point de repos, Vol, porte « À venir », rien d'automatique), départs
## de débogage.

const TOOL_STARTS := "res://tools/debug_start/"
const STARTS: Array[String] = ["route_22_final_bulbasaur", "route_22_final_charmander",
	"route_22_final_squirtle", "route_22_final_weak", "route_23_seven", "route_23_all",
	"victory_road_1f", "victory_road_2f", "victory_road_3f", "moltres", "indigo_plateau"]
## Contrôles : scène → [Badge, garde].
const CHECKS: Dictionary = {
	&"route_22_gate_check": [&"badge_boulder", &"route_22_gate_guard"],
	&"route_23_check_7": [&"badge_cascade", &"route_23_guard_7"],
	&"route_23_check_6": [&"badge_thunder", &"route_23_guard_6"],
	&"route_23_check_5": [&"badge_rainbow", &"route_23_guard_5"],
	&"route_23_check_4": [&"badge_soul", &"route_23_guard_4"],
	&"route_23_check_3": [&"badge_marsh", &"route_23_guard_3"],
	&"route_23_check_2": [&"badge_volcano", &"route_23_guard_2"],
	&"route_23_check_1": [&"badge_earth", &"route_23_guard_1"],
}
const BADGES: Array[StringName] = [&"badge_boulder", &"badge_cascade", &"badge_thunder",
	&"badge_rainbow", &"badge_soul", &"badge_marsh", &"badge_volcano", &"badge_earth"]

var _cutscenes: CutsceneLibrary
var _dialogues: DialogueLibrary


func before_all() -> void:
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()


func _flags(list: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in list:
		flags.set_flag(flag)
	return flags


func _steps(variant: CutsceneVariant) -> Array[CutsceneStep]:
	return variant.steps if variant != null else [] as Array[CutsceneStep]


func _moves_player_back(variant: CutsceneVariant) -> bool:
	for step: CutsceneStep in _steps(variant):
		if step.kind == CutsceneStep.Kind.MOVE and step.actor == &"player" \
				and step.path.size() == 1 and step.path[0] == Vector2i.DOWN:
			return true
	return false


func test_each_check_reads_only_its_badge() -> void:
	for scene: StringName in CHECKS:
		var badge: StringName = CHECKS[scene][0]
		var cutscene := _cutscenes.get_cutscene(scene)
		assert_not_null(cutscene, String(scene))
		if cutscene == null:
			continue
		var others: Array[StringName] = BADGES.filter(func(b: StringName) -> bool: return b != badge)
		var without := cutscene.pick(_flags(others))
		assert_true(_moves_player_back(without), "%s : sans %s, recul" % [scene, badge])
		var with_all := cutscene.pick(_flags(BADGES))
		assert_not_null(with_all, "%s : avec le Badge, « Tu peux passer »" % scene)
		assert_false(_moves_player_back(with_all), "%s : avec le Badge, pas de recul" % scene)
		var only := cutscene.pick(_flags([badge]))
		assert_false(_moves_player_back(only), "%s : son seul Badge suffit (ordre libre)" % scene)
		var passed := _flags(BADGES)
		passed.set_flag(StringName(String(scene) + "_passed"))
		assert_null(cutscene.pick(passed), "%s : dit une fois, puis silence" % scene)


func test_checks_and_guards_use_existing_dialogues() -> void:
	for scene: StringName in CHECKS:
		var guard: StringName = CHECKS[scene][1]
		assert_true(_dialogues.has_dialogue(guard), "%s : on parle au garde" % guard)
		for variant: CutsceneVariant in _cutscenes.get_cutscene(scene).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.DIALOGUE:
					assert_true(_dialogues.has_dialogue(step.dialogue_id), String(step.dialogue_id))


func test_rival_7_is_distinct_from_rival_2() -> void:
	var roster := NpcRoster.load_for_map(&"route_22_west")
	var present := func(flags: StoryFlags) -> bool:
		return roster.get_present(flags).any(func(s: NpcSpec) -> bool: return s.id == &"rival_final")
	assert_false(present.call(_flags([&"badge_cascade"])), "absent sans le Badge Terre")
	assert_true(present.call(_flags([&"badge_earth"])), "présent avec le Badge Terre")
	assert_true(present.call(_flags([&"badge_earth", &"rival_route22_won"])),
		"indépendant de la victoire du n° 2")
	assert_false(present.call(_flags([&"badge_earth", &"rival_route22_final_won"])), "parti battu")
	var scene := _cutscenes.get_cutscene(&"rival_route22_final")
	assert_not_null(scene)
	var variant := scene.pick(_flags([&"badge_earth"]))
	var battle: CutsceneStep = null
	for step: CutsceneStep in _steps(variant):
		if step.kind == CutsceneStep.Kind.BATTLE:
			battle = step
		assert_false(step.flags.has(&"rival_route22_won") or step.flags.has(&"rival_route22_lost"),
			"le combat n° 7 ne touche pas aux drapeaux du n° 2")
	assert_not_null(battle)
	if battle != null:
		assert_eq(battle.trainer_id, &"rival_route22_final")
		assert_eq(battle.win_flags, [&"rival_route22_final_won"] as Array[StringName])
		assert_true(battle.lose_flags.is_empty(), "défaite : rien, il reste (rejouable)")
	assert_null(scene.pick(_flags([&"badge_earth", &"rival_route22_final_won"])))
	# La scène du n° 2 (J7) reste celle du J7.
	var rival_2 := _cutscenes.get_cutscene(&"rival_route22")
	assert_not_null(rival_2.pick(_flags([&"pokedex_activated"])))


func test_moltres_is_a_single_static_encounter() -> void:
	var roster := NpcRoster.load_for_map(&"victory_road_2f")
	var present := func(flags: StoryFlags) -> bool:
		return roster.get_present(flags).any(func(s: NpcSpec) -> bool: return s.id == &"moltres")
	assert_true(present.call(_flags([])))
	assert_false(present.call(_flags([&"moltres_done"])), "jamais deux Sulfura")
	var variant := _cutscenes.get_cutscene(&"moltres").pick(_flags([]))
	var wild: CutsceneStep = null
	for step: CutsceneStep in _steps(variant):
		if step.kind == CutsceneStep.Kind.WILD_BATTLE:
			wild = step
	assert_not_null(wild)
	if wild != null:
		assert_eq([wild.species, wild.level, wild.intro, wild.actor],
			[&"moltres", 50, &"legendary", &"moltres"])
		assert_not_null(wild.static_encounter)
		if wild.static_encounter != null:
			assert_eq([wild.static_encounter.done_flag, wild.static_encounter.caught_flag],
				[&"moltres_done", &"moltres_caught"])
	assert_null(_cutscenes.get_cutscene(&"moltres").pick(_flags([&"moltres_done"])))


func test_indigo_plateau_rest_fly_and_league_door() -> void:
	var rest := RestPointLibrary.new()
	rest.load_file()
	assert_true(rest.has_point(&"indigo_plateau_lobby"), "point de repos")
	var lobby := (load(MapCatalog.scene_path(&"indigo_plateau_lobby")) as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(lobby)
	# J30 (fusion du J29, `jalon-30.md` §10.8) : la porte mène à la salle d'Olga ; la question du
	# garde (T30-01) est posée sur la case devant elle.
	var door: Warp = null
	for warp: Warp in lobby.get_warps().get_all():
		if warp.target_map == &"league_lorelei":
			door = warp
	assert_not_null(door, "porte de la Ligue")
	if door != null:
		assert_eq([door.cell, door.target_spawn], [Vector2i(12, 3), &"from_lobby"])
		assert_eq(door.coming_soon, "")
	var triggers := lobby.get_triggers().get_all()
	assert_eq(triggers.size(), 1, "seulement la question du garde")
	if triggers.size() == 1:
		assert_eq([triggers[0].cell, triggers[0].cutscene_id],
			[Vector2i(12, 4), &"league_guard_door"])
	var plateau := (load(MapCatalog.scene_path(&"indigo_plateau")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(plateau)
	assert_true(plateau.has_spawn(&"from_center"), "arrivée du Vol (fly_points.json)")
	assert_true(plateau.get_triggers().is_empty())


func test_debug_starts_load_and_stand_on_their_spawn() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	for name: String in STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", data, items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		assert_true(MapCatalog.has_map(start.map), "%s : %s" % [name, start.map])
		if MapCatalog.has_map(start.map):
			var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
				as GameMap
			add_child_autofree(map)
			assert_true(map.has_spawn(start.spawn), "%s : %s" % [name, start.spawn])


## QA A17 du 2026-10-23 : l'hôte du hall (T29-10) était posé en (3, 6), juste derrière la
## banquette ouest (cellule (3, 7)) : on ne voyait que le haut de sa tête. Aucun PNJ du hall ne se
## tient sur la rangée d'une banquette ni juste au-dessus, à moins d'une case de son centre.
func test_indigo_plateau_lobby_npcs_not_hidden_by_benches() -> void:
	var lobby := (load(MapCatalog.scene_path(&"indigo_plateau_lobby")) as PackedScene) \
		.instantiate() as GameMap
	add_child_autofree(lobby)
	var benches: Array[Vector2i] = []
	for name: String in ["BenchWest", "BenchEast"]:
		var bench := lobby.find_child(name, true, false) as Node2D
		assert_not_null(bench, name)
		if bench != null:
			benches.append(Vector2i(floori(bench.position.x / 96.0), floori(bench.position.y / 96.0)))
	var file := FileAccess.open("res://data/npcs/indigo_plateau_lobby.json", FileAccess.READ)
	var npcs: Dictionary = JSON.parse_string(file.get_as_text())
	for id: String in npcs:
		var raw: Array = npcs[id]["cell"]
		var cell := Vector2i(int(raw[0]), int(raw[1]))
		for bench: Vector2i in benches:
			var hidden := absi(cell.x - bench.x) <= 1 and cell.y >= bench.y - 1 and cell.y <= bench.y
			assert_false(hidden, "%s en %s caché par la banquette %s" % [id, cell, bench])
