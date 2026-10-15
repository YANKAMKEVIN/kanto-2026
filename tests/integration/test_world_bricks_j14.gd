extends GutTest
## Briques de monde du jalon 14 (jalon-14.md §2.8) sur une carte : PNJ à une autre place
## (« moved »), décor qui suit les drapeaux (FlagGate + lueur « hint »), tirage « one_in » du
## DialogueRunner ; et leur branchement dans le vrai Boot (lueur qui suit un drapeau levé en
## cours de visite, aléatoire de la partie pour les dialogues).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const NPCS := "res://tests/fixtures/npcs/"
const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const ROCKET_START := Vector2i(13, 2)
const ROCKET_MOVED := Vector2i(16, 3)
## Drapeau propre à ce test (Boot : GameState partagé, remis à zéro après).
const BOOT_FLAG := &"test_j14_flag_gate"
const BILL := {
	"bill": {"speaker": "Léo", "variants": [
		{"one_in": 3, "pages": ["Rare"]},
		{"pages": ["Normal"]},
	]},
}


## Carte 20 × 18 sans tuiles, PNJ de tests/fixtures/npcs/moved_map.json.
func _make_map() -> GameMap:
	var map := GameMap.new()
	map.name = "MovedMap"
	map.map_id = &"moved_map"
	map.npcs_dir = NPCS
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns"]:
		var node := Node2D.new()
		node.name = group
		map.add_child(node)
	(map.get_node(^"Entities") as Node2D).y_sort_enabled = true
	return map


func _flags(names: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


## Lueur « hint » sous une porte de drapeaux, ajoutée à `Entities`.
func _add_hint(map: GameMap, if_flags: Array[StringName],
		unless_flags: Array[StringName]) -> FlagGate:
	var gate := FlagGate.new()
	gate.name = "HintGate"
	gate.if_flags = if_flags
	gate.unless_flags = unless_flags
	var glow := LightGlow.new()
	glow.glow_type = &"hint"
	gate.add_child(glow)
	map.get_entities().add_child(gate)
	return gate


# --- « moved » ----------------------------------------------------------------------------

func test_new_game_places_the_npc_at_its_start_cell() -> void:
	var map := _make_map()
	add_child_autofree(map)
	map.refresh_npcs(_flags([]))
	var rocket := map.get_npc(&"rocket")
	assert_eq(rocket.get_cell(), ROCKET_START)
	assert_eq(rocket.get_spec().facing, Vector2i.UP)
	assert_push_error_count(0)


func test_arrival_with_the_flag_places_the_npc_at_its_moved_cell() -> void:
	var map := _make_map()
	add_child_autofree(map)
	map.refresh_npcs(_flags([&"rocket_spotted"]))
	var rocket := map.get_npc(&"rocket")
	assert_eq(rocket.get_cell(), ROCKET_MOVED)
	assert_eq(rocket.get_spec().facing, Vector2i.LEFT)
	assert_same(map.get_grid().get_occupant(ROCKET_MOVED), rocket)
	assert_false(map.get_grid().is_occupied(ROCKET_START), "case de départ libre")
	map.refresh_npcs(_flags([&"rocket_spotted"]))
	assert_same(map.get_npc(&"rocket"), rocket, "pas recréé une seconde fois")
	assert_eq(map.get_npcs().size(), 2, "pas de doublon")
	assert_push_error_count(0)


func test_flag_raised_during_the_visit_does_not_move_the_npc() -> void:
	var map := _make_map()
	add_child_autofree(map)
	var flags := _flags([])
	map.refresh_npcs(flags)
	var rocket := map.get_npc(&"rocket")
	flags.set_flag(&"rocket_spotted")
	map.apply_flag_gates(flags)
	assert_same(map.get_npc(&"rocket"), rocket)
	assert_eq(rocket.get_cell(), ROCKET_START, "reste où il est (où la scène l'a mené)")


func test_unless_still_removes_a_moved_npc() -> void:
	var map := _make_map()
	add_child_autofree(map)
	map.refresh_npcs(_flags([&"rocket_spotted", &"rocket_beaten"]))
	assert_null(map.get_npc(&"rocket"))
	assert_false(map.get_grid().is_occupied(ROCKET_MOVED))
	assert_push_error_count(0)


# --- FlagGate ------------------------------------------------------------------------------

func test_refresh_applies_the_flag_gates() -> void:
	var map := _make_map()
	var gate := _add_hint(map, [&"bill_met"], [&"bill_screen_checked"])
	add_child_autofree(map)
	map.refresh_npcs(_flags([]))
	assert_false(gate.visible, "avant la rencontre : pas de lueur")
	map.refresh_npcs(_flags([&"bill_met"]))
	assert_true(gate.visible)
	assert_true((gate.get_child(0) as LightGlow).is_lit(), "type « hint » connu")
	map.refresh_npcs(_flags([&"bill_met", &"bill_screen_checked"]))
	assert_false(gate.visible)
	assert_push_error_count(0)


func test_apply_flag_gates_follows_a_set_during_the_visit() -> void:
	var map := _make_map()
	var gate := _add_hint(map, [&"bill_met"], [])
	add_child_autofree(map)
	var flags := _flags([])
	map.refresh_npcs(flags)
	assert_false(gate.visible)
	flags.set_flag(&"bill_met")
	map.apply_flag_gates(flags)
	assert_true(gate.visible)


func test_gates_of_another_map_are_left_alone() -> void:
	var map := _make_map()
	add_child_autofree(map)
	var other := _make_map()
	other.map_id = &"other"
	var foreign := _add_hint(other, [&"never"], [])
	add_child_autofree(other)
	map.apply_flag_gates(_flags([]))
	assert_true(foreign.visible, "seule la carte appelée est réglée")


# --- one_in dans le DialogueRunner ----------------------------------------------------------

func _runner(rng: GameRng) -> DialogueRunner:
	var library := DialogueLibrary.new()
	library.add_from_dict(BILL, "test")
	var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(box)
	var runner := DialogueRunner.new()
	runner.chars_per_second = 0.0
	add_child_autofree(runner)
	runner.setup(library, StoryFlags.new(), box, null)
	if rng != null:
		runner.rng_source = func() -> GameRng: return rng
	return runner


func _first_page(runner: DialogueRunner) -> String:
	return runner.get_session().get_page().text


## Joue « bill » avec un lecteur neuf (la fermeture de la boîte prend du temps réel) et rend
## sa première page.
func _play_once(rng: GameRng) -> String:
	var runner := _runner(rng)
	assert_true(runner.play(&"bill"))
	return _first_page(runner)


func test_runner_draws_with_its_rng() -> void:
	var rng := ScriptedRng.new([1, 2])
	assert_eq(_play_once(rng), "Rare", "tirage gagné")
	assert_eq(_play_once(rng), "Normal", "tirage perdu : variante suivante")
	assert_eq(rng.calls, 2)


func test_runner_without_rng_skips_the_random_variant() -> void:
	assert_eq(_play_once(null), "Normal")


func test_runner_with_a_seed_is_reproducible() -> void:
	var picks: Array[Array] = []
	for attempt: int in 2:
		var rng := GameRng.new(42)
		var seen: Array[String] = []
		for i: int in 12:
			seen.append(_play_once(rng))
		picks.append(seen)
	assert_eq(picks[0], picks[1], "même graine, mêmes répliques")
	assert_true(picks[0].has("Rare") and picks[0].has("Normal"), str(picks[0]))


# --- Boot ------------------------------------------------------------------------------------

func test_boot_gate_follows_a_flag_raised_during_the_visit() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	GameState.flags.set_flag(BOOT_FLAG, false)
	var map := boot.get_map()
	var gate := _add_hint(map, [BOOT_FLAG], [])
	map.apply_flag_gates(GameState.flags)
	assert_false(gate.visible)
	GameState.flags.set_flag(BOOT_FLAG)
	assert_true(gate.visible, "lueur allumée sans changement de carte")
	GameState.flags.set_flag(BOOT_FLAG, false)
	assert_false(gate.visible)


func test_boot_gives_the_game_rng_to_the_dialogue_runner() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	var runner := boot.get_dialogue_runner()
	assert_true(runner.rng_source.is_valid())
	assert_same(runner.rng_source.call(), GameState.rng)
