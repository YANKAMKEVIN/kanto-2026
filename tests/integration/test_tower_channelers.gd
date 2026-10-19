extends GutTest
## Les 9 Exorcistes de la Tour Pokémon (3F à 6F, jalon 19 T14, `jalon-19.md` §2.5 ; dossier 22
## §8, §15.4, §15.7, §16 n° 2) sur la **vraie scène Boot avec ses PNJ** :
## - aux bons étages, aux bonnes cases, d'après les grilles `tools/plans/` ;
## - E3, E8 et E9 inévitables, les six autres évitables (recherche de chemin hors de leur vue,
##   les PNJ comme obstacles) ;
## - répliques « avant » (voix d'esprit), « défaite » et « après », mot pour mot ;
## - victoire : Fantominus « vu », `beaten_<id>` posé et gardé après un rechargement, l'Exorciste
##   ne défie plus ;
## - défaite contre E3 : réveil au dernier point de repos (Lavanville), E3 encore à battre.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const FADE := 0.05
const TIMEOUT := 25.0
const SIZE := Vector2i(20, 18)
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Étage → [grille, point d'arrivée, case d'objectif : escalier du palier suivant (6F : le
## déclencheur du SPECTRE)].
const FLOORS: Dictionary = {
	&"pokemon_tower_3f": ["res://tools/plans/pokemon_tower_3f.txt", &"arrivee_T23",
		Vector2i(18, 9)],
	&"pokemon_tower_4f": ["res://tools/plans/pokemon_tower_4f.txt", &"arrivee_T34",
		Vector2i(3, 9)],
	&"pokemon_tower_5f": ["res://tools/plans/pokemon_tower_5f.txt", &"arrivee_T45",
		Vector2i(18, 9)],
	&"pokemon_tower_6f": ["res://tools/plans/pokemon_tower_6f.txt", &"arrivee_T56",
		Vector2i(10, 16)],
}
## Exorciste → [étage, prénom].
const CHANNELERS: Dictionary = {
	1: [&"pokemon_tower_3f", "Hortense"], 2: [&"pokemon_tower_3f", "Odile"],
	3: [&"pokemon_tower_4f", "Solange"], 4: [&"pokemon_tower_4f", "Mireille"],
	5: [&"pokemon_tower_5f", "Bérénice"], 6: [&"pokemon_tower_5f", "Marthe"],
	7: [&"pokemon_tower_5f", "Ysée"], 8: [&"pokemon_tower_6f", "Paulette"],
	9: [&"pokemon_tower_6f", "Clémence"],
}
const INEVITABLE: Array[int] = [3, 8, 9]
## Répliques « avant » (dossier 22 §15.4), dans l'ordre E1 à E9.
const BEFORE: Array[String] = [
	"Laisse… nous…", "Tu… n'as… rien… à faire… ici…", "Plus… haut… personne… ne… monte…",
	"Froid… si… froid…", "Rends… les… nous…", "Qui… es… tu… ?", "Silence… silence…",
	"Ne… monte… pas…", "Elle… attend… son… petit…",
]
const AFTER: Dictionary = {
	1: ["Qu'est-ce que… J'étais possédée ?", "Les esprits sont trop nombreux, cette fois."],
	3: ["Ces spectres qu'on ne voit pas…", "Seul un Scope Sylphe permettrait de voir leur vrai "
		+ "visage."],
	5: ["Je n'avais jamais vu les esprits aussi troublés.", "Quelqu'un les a blessés."],
	9: ["Là-haut… il y a une présence plus forte que les autres.", "Une mère, je crois."],
}
const AFTER_OTHERS: Array[String] = ["Merci… Je me sens plus légère."]
const DEFEATED: String = "Les esprits… se taisent…"
## Hortense (3F) : case, orientation ; le joueur se place à deux cases de sa vue.
const E1_CELL := Vector2i(12, 3)

var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _spotted: Array[StringName] = []
var _battles: Array[StringName] = []
var _saved_router: Array = []
var _dialogues := DialogueLibrary.new()


func before_all() -> void:
	_dialogues.load_dir()


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-19T14:00:00")
	_pages.clear()
	_spotted.clear()
	_battles.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _plan_of(map_id: StringName) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(FLOORS[map_id][0]), plan.error)
	return plan


func _start(map_id: StringName, spawn: StringName, facing: Vector2i, party: Array[Pokemon],
		flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.new_game(11)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.rng = GameRng.new(11)
	for member: Pokemon in party:
		GameState.party.add(member)
	GameState.starter_species = party[0].species_id
	GameState.ensure_unique_uids()
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	_boot.get_battle_director().battle_started.connect(func(id: StringName) -> void:
		_battles.append(id))
	_boot.get_trainer_watcher().trainer_spotted.connect(
		func(npc_id: StringName, _trainer: StringName) -> void: _spotted.append(npc_id))
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))


func _strong_team() -> Array[Pokemon]:
	var data := _boot.get_pokemon_data() if _boot != null else _load_data()
	var team: Array[Pokemon] = []
	var kadabra := PokemonFactory.create(data, &"kadabra", 70, GameRng.new(5))
	kadabra.moves.clear()
	kadabra.moves.append(MoveSlot.new(&"psychic", 10))
	team.append(kadabra)
	return team


func _load_data() -> PokemonData:
	var data := PokemonData.new()
	data.load_dir()
	return data


func _weak_team() -> Array[Pokemon]:
	var team: Array[Pokemon] = []
	var rattata := PokemonFactory.create(_load_data(), &"rattata", 2, GameRng.new(5))
	rattata.moves.clear()
	rattata.moves.append(MoveSlot.new(&"tackle", 35))
	team.append(rattata)
	return team


## Déroule la scène en cours (pages, combat piloté : ATTAQUE puis la première capacité).
func _play_through() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running() or battle_director.is_running()
			or SceneRouter.is_transitioning()) and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	assert_false(director.is_running(), "scène finie")
	await wait_process_frames(5)


func _talk_to(npc_id: StringName) -> void:
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	if npc == null:
		return
	for other: Npc in map.get_npcs():
		other.set_routine_held(true)
	for direction: Vector2i in DIRECTIONS:
		var from := npc.get_cell() + direction
		if map.get_grid().is_free(from):
			map.spawn_player_at(_player, from, -direction)
			break
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _play_through()


func _texts(id: StringName) -> Array[String]:
	var lines: Array[String] = []
	for page: DialoguePage in _dialogues.get_dialogue(id).variants[0].pages:
		lines.append(page.text.replace("\n", " "))
	return lines


# --- Données : étages, cases, textes -------------------------------------------------------

func test_nine_channelers_stand_on_their_plan_cells() -> void:
	var seen := 0
	for map_id: StringName in FLOORS:
		var plan := _plan_of(map_id)
		var specs := NpcRoster.load_for_map(map_id).get_present(null)
		var trainers: Dictionary = {}
		for spec: NpcSpec in specs:
			if not spec.trainer_id.is_empty():
				trainers[spec.id] = spec
		for n: int in CHANNELERS:
			var info: Array = CHANNELERS[n]
			var id := "tower_channeler_%d" % n
			if info[0] != map_id:
				assert_false(trainers.has(StringName(id)), "%s absent de %s" % [id, map_id])
				continue
			seen += 1
			assert_true(trainers.has(StringName(id)), "%s présent sur %s" % [id, map_id])
			if not trainers.has(StringName(id)):
				continue
			var spec: NpcSpec = trainers[StringName(id)]
			assert_eq(spec.cell, plan.cell_of(id), "%s : case du plan" % id)
			assert_eq(spec.facing, Grid.direction_from_name(plan.attr(id, "facing")), id)
			assert_eq(spec.sight, int(plan.attr(id, "sight")), "%s : vue" % id)
			assert_eq(spec.trainer_id, StringName(id), id)
			assert_eq(spec.sprite, &"channeler", "%s : apparence" % id)
			assert_eq(String(plan.attr(id, "prenom")), info[1], "%s : prénom du plan" % id)
		assert_eq(trainers.size(), CHANNELERS.values().filter(
			func(i: Array) -> bool: return i[0] == map_id).size(), "%s : Dresseurs" % map_id)
	assert_eq(seen, 9, "9 Exorcistes")
	var library := TrainerLibrary.new(_load_data())
	library.load_dir()
	for n: int in CHANNELERS:
		var trainer := library.get_trainer(StringName("tower_channeler_%d" % n))
		assert_not_null(trainer, "Dresseur %d" % n)
		if trainer != null:
			assert_eq(trainer.name, "Exorciste %s" % CHANNELERS[n][1])


func test_lines_before_defeated_and_after_word_for_word() -> void:
	for n: int in range(1, 10):
		var key := StringName("tower_channeler_%d" % n)
		var before := _dialogues.get_dialogue(StringName("%s_before" % key))
		assert_not_null(before, "%s : avant" % key)
		var pages: Array = before.variants[0].pages
		assert_eq(pages.size(), 1, key)
		assert_eq(pages[0].text, BEFORE[n - 1], "%s : réplique d'avant" % key)
		assert_eq(pages[0].voice, &"spirit", "%s : voix d'esprit" % key)
		var defeated := _dialogues.get_dialogue(StringName("%s_defeated" % key))
		assert_eq(defeated.variants[0].pages[0].text, DEFEATED, "%s : défaite" % key)
		assert_eq(defeated.variants[0].pages[0].voice, &"spirit")
		var expected: Array = AFTER.get(n, AFTER_OTHERS)
		assert_eq(_texts(StringName("%s_after" % key)), expected, "%s : après" % key)


# --- Inévitables / évitables ---------------------------------------------------------------

## Cases vues par [param npc] (sa ligne de vue sur la vraie grille, PNJ compris).
func _seen_cells(grid: GridWorld, npc: Npc, sight: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for k: int in range(1, sight + 1):
		var cell := npc.get_cell() + npc.get_facing() * k
		if not grid.is_in_bounds(cell) or grid.is_solid(cell) or grid.is_water(cell) \
				or grid.is_occupied(cell):
			break
		cells.append(cell)
	return cells


func _check_floor(map_id: StringName) -> void:
	var info: Array = FLOORS[map_id]
	await _start(map_id, info[1], Vector2i.DOWN, _strong_team())
	var map := _boot.get_map()
	var npcs := map.get_npcs()
	var start := map.get_spawn_cell(info[1])
	var goal: Vector2i = info[2]
	var blocked_npcs: Array[Vector2i] = []
	for npc: Npc in npcs:
		blocked_npcs.append(npc.get_cell())
	for npc: Npc in npcs:
		var id := String(npc.get_id())
		if not id.begins_with("tower_channeler_"):
			continue
		var n := int(id.trim_prefix("tower_channeler_"))
		var spec_sight := int(_plan_of(map_id).attr(id, "sight"))
		var relief := GridPaths.relief(map.get_grid(), SIZE)
		for cell: Vector2i in blocked_npcs:
			relief.set_solid(cell)
		for cell: Vector2i in _seen_cells(map.get_grid(), npc, spec_sight):
			relief.set_solid(cell)
		var reach := GridPaths.distances(relief, [start], {goal: true})
		if INEVITABLE.has(n):
			assert_false(reach.has(goal), "E%d inévitable : %s hors de sa vue" % [n, goal])
		else:
			assert_true(reach.has(goal), "E%d évitable : %s atteignable hors de sa vue" % [n, goal])
	_boot.queue_free()
	await wait_process_frames(2)


func test_3f_channelers_are_avoidable() -> void:
	await _check_floor(&"pokemon_tower_3f")


func test_4f_e3_is_unavoidable_and_e4_avoidable() -> void:
	await _check_floor(&"pokemon_tower_4f")


func test_5f_channelers_are_avoidable() -> void:
	await _check_floor(&"pokemon_tower_5f")


func test_6f_e8_and_e9_are_unavoidable() -> void:
	await _check_floor(&"pokemon_tower_6f")


# --- Combat : victoire ---------------------------------------------------------------------

func test_e1_spots_fights_is_beaten_and_stays_beaten() -> void:
	await _start(&"pokemon_tower_3f", &"arrivee_T23", Vector2i.RIGHT, _strong_team())
	var map := _boot.get_map()
	map.spawn_player_at(_player, E1_CELL + Vector2i.LEFT * 3, Vector2i.RIGHT)
	await wait_process_frames(3)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return not _spotted.is_empty(), TIMEOUT)
	Input.action_release(&"move_right")
	assert_eq(_spotted, [&"tower_channeler_1"] as Array[StringName], "E1 voit le joueur")
	await _play_through()
	assert_eq(_battles, [&"tower_channeler_1"] as Array[StringName], "un combat")
	assert_true(GameState.flags.has_flag(&"beaten_tower_channeler_1"), "battue")
	var expected: Array[String] = [BEFORE[0], DEFEATED]
	assert_eq(_pages, expected, "répliques « avant » puis « défaite »")
	assert_true(GameState.pokedex.is_seen(&"gastly"), "Fantominus vu après le combat")
	# Rechargement : le drapeau survit à une sauvegarde.
	var saved := GameState.to_dict()
	GameState.new_game(3)
	assert_false(GameState.flags.has_flag(&"beaten_tower_channeler_1"))
	assert_true(GameState.load_dict(saved, _boot.get_pokemon_data()), "partie rechargée")
	assert_true(GameState.flags.has_flag(&"beaten_tower_channeler_1"), "gardé au rechargement")
	# Battue : elle ne défie plus et dit sa réplique « après ».
	_spotted.clear()
	_pages.clear()
	map.spawn_player_at(_player, E1_CELL + Vector2i.LEFT * 3, Vector2i.RIGHT)
	await wait_process_frames(3)
	Input.action_press(&"move_right")
	await wait_until(func() -> bool: return _player.get_cell().x >= E1_CELL.x - 1, TIMEOUT)
	Input.action_release(&"move_right")
	await wait_process_frames(20)
	assert_eq(_spotted, [] as Array[StringName], "ne défie plus")
	await _talk_to(&"tower_channeler_1")
	var after: Array[String] = []
	for page: String in _pages:
		after.append(page.replace("\n", " "))
	assert_eq(after, _texts(&"tower_channeler_1_after"), "réplique « après »")
	assert_push_error_count(0)


# --- Combat : défaite ----------------------------------------------------------------------

func test_losing_to_e3_wakes_at_the_rest_point_and_e3_remains() -> void:
	await _start(&"pokemon_tower_4f", &"arrivee_T34", Vector2i.LEFT, _weak_team())
	GameState.heal_map = &"lavender_center"
	GameState.heal_spawn = &"heal"
	var map := _boot.get_map()
	map.spawn_player_at(_player, Vector2i(16, 9), Vector2i.LEFT)
	await wait_process_frames(3)
	Input.action_press(&"move_left")
	await wait_until(func() -> bool: return not _spotted.is_empty(), TIMEOUT)
	Input.action_release(&"move_left")
	assert_eq(_spotted, [&"tower_channeler_3"] as Array[StringName], "E3 voit le joueur")
	await _play_through()
	await wait_until(func() -> bool: return (_boot.get_map().map_id == &"lavender_center"
		and _boot.is_stable()), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"lavender_center", "réveil au Centre de Lavanville")
	assert_false(GameState.flags.has_flag(&"beaten_tower_channeler_3"), "E3 pas battue")
	assert_eq(_battles, [&"tower_channeler_3"] as Array[StringName])
	# Retour à la Tour : E3 est toujours là, à battre.
	var fourth := load(MapCatalog.scene_path(&"pokemon_tower_4f")) as PackedScene
	assert_not_null(fourth)
	SceneRouter.change_map(&"pokemon_tower_4f", &"arrivee_T34", Vector2i.LEFT)
	await wait_until(func() -> bool: return (_boot.get_map().map_id == &"pokemon_tower_4f"
		and _boot.is_stable() and not SceneRouter.is_transitioning()), TIMEOUT)
	var npc := _boot.get_map().get_npc(&"tower_channeler_3")
	assert_not_null(npc, "E3 toujours là")
	if npc != null:
		assert_eq(npc.get_cell(), Vector2i(15, 7))
	assert_push_error_count(0)
