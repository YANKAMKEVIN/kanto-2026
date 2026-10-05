extends GutTest
## Rival n° 2 sur la Route 22 (jalon 7 T25, jalon-07.md §8 ; dossier 09 §13–§15, §19 ; Q-13),
## avec la vraie scène Boot, la vraie carte, l'autoload SceneRouter (fondus raccourcis), le
## combat instantané et une sauvegarde en mémoire :
## - sans `pokedex_activated` : ni rival ni jeune Dresseur, traverser le déclencheur ne lance rien ;
## - avec le drapeau (départ `route_22`, équipe renforcée pour gagner) : le rival, son Pokémon
##   (paire `taken_*`), le jeune Dresseur et son Rattata face à face ; en haut de l'escalier, un
##   pas vers l'ouest lance la scène : « Sérieusement… ? », les Pokémon rappelés, « Tu hésites
##   trop. », le rival vient au joueur, ses répliques, le combat (SAC actif) ; victoire →
##   `rival_route22_won`, 280 ₽ gagnés, moment « Combat contre le rival » (victoire), répliques
##   de victoire seulement, il part, le jeune Dresseur aussi ; la scène ne se rejoue plus ;
## - défaite (départ `rival_2_weak`) → `rival_route22_lost`, répliques de défaite seulement,
##   étape `wake_up` : réveil chez Maman (aucun Centre enregistré) ou au Centre de Jadielle,
##   équipe soignée, aucun argent perdu, sauvegarde écrite au réveil, moment (défaite).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const ROUTE_START := "res://tools/debug_start/route_22.json"
const WEAK_START := "res://tools/debug_start/rival_2_weak.json"
const SAVE_PATH := "user://test_rival_route22_save.json"
const DATE := "2026-10-05T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 8000
const SCENE_TIMEOUT_MS := 90000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
## Du pied de l'escalier (stair_foot) au haut de l'escalier, puis le pas vers l'ouest qui
## déclenche (case du déclencheur RivalVista).
const STAIR_TOP := Vector2i(16, 13)
const TRIGGER_CELL := Vector2i(14, 13)
const SCENE_NPCS: Array[StringName] = [&"rival", &"youngster", &"youngster_rattata"]
const OPENING: Array[String] = [
	"Sérieusement… ?", "Tu hésites trop.", "Tiens.",
	"Toi aussi, tu es venu voir jusqu'où cette route mène ?", "Ça tombe bien.",
	"Voyons ce que tu as appris depuis notre premier combat.",
]
const WIN_LINES: Array[String] = [
	"…D'accord.", "Tu progresses vite.", "Mais moi aussi.",
	"On verra lequel de nous deux arrive le plus loin.",
]
const LOSE_LINES: Array[String] = [
	"Tu t'es amélioré.", "Mais pas assez.",
	"La prochaine fois, ne me laisse pas autant d'avance.",
]

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _bag_enabled: Array[bool] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_pages.clear()
	_bag_enabled.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"interact")


## Boot (sauvegarde en mémoire), partie de [param start_path], puis arrivée sur la Route 22 au
## pied de l'escalier (comme Boot : PNJ présents selon les drapeaux à l'écran noir).
## [param drop] : drapeaux retirés du départ ; [param strong] : starter remplacé par un
## Salamèche Nv. 40 (Flammèche) pour gagner à coup sûr.
func _start(start_path: String, drop: Array[StringName] = [], strong: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"viridian_city"
	_boot.start_spawn = &"from_route_22"
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(7)
	for flag: StringName in drop:
		GameState.flags.set_flag(flag, false)
	if strong:
		var data := _boot.get_pokemon_data()
		var champion := PokemonFactory.create(data, &"charmander", 40, GameState.rng)
		champion.moves.clear()
		champion.moves.append(MoveSlot.new(&"ember", 25))
		GameState.party.remove_at(0)
		GameState.party.add(champion)
		GameState.party.move(GameState.party.size() - 1, 0)
	await wait_process_frames(2)
	await SceneRouter.change_map(&"route_22", &"stair_foot", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_eq(_boot.get_map().map_id, &"route_22")


## Monte l'escalier puis fait le pas vers l'ouest qui déclenche la scène.
func _climb_and_step_west() -> void:
	await _walk_to(Vector2i(16, 15))
	await _walk_to(STAIR_TOP)
	await _walk_to(Vector2i(15, 13))
	await _walk_to(TRIGGER_CELL)
	await wait_process_frames(2)


## Déroule la scène (et le mot du réveil) : pages avancées, combat piloté (SAC regardé à
## chaque choix d'action, puis ATTAQUER et la 1re capacité).
func _play_through() -> bool:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var seen_battle := false
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			seen_battle = true
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						_bag_enabled.append(battle_hud.get_action_grid().is_action_enabled(
							ActionGrid.BAG))
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			var text := box.get_text()
			if _pages.is_empty() or _pages.back() != text:
				_pages.append(text)
			box.advance_requested.emit()
	await wait_process_frames(3)
	return seen_battle


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _rival_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == String(GameState.MOMENT_RIVAL_BATTLE):
			found.append(moment)
	return found


# --- Sans le Pokédex --------------------------------------------------------------------------

func test_nothing_happens_before_the_pokedex_is_activated() -> void:
	await _start(ROUTE_START, [&"pokedex_activated"])
	var map := _boot.get_map()
	for id: StringName in SCENE_NPCS + [&"rival_squirtle"]:
		assert_null(map.get_npc(id), "%s absent avant l'activation" % id)
	await _climb_and_step_west()
	assert_eq(_player.get_cell(), TRIGGER_CELL, "le pas a eu lieu")
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène")
	await _walk_to(Vector2i(11, 13))
	assert_eq(_player.get_cell(), Vector2i(11, 13), "le point de vue est libre")
	assert_false(GameState.flags.has_flag(&"rival_route22_won"))
	assert_false(GameState.flags.has_flag(&"rival_route22_lost"))
	assert_push_error_count(0)


# --- Victoire ---------------------------------------------------------------------------------

func test_victory_pays_records_the_moment_and_never_replays() -> void:
	await _start(ROUTE_START, [], true)
	var map := _boot.get_map()
	for id: StringName in SCENE_NPCS + [&"rival_squirtle"]:
		assert_not_null(map.get_npc(id), "%s présent (Pokédex activé)" % id)
	for id: StringName in [&"rival_charmander", &"rival_bulbasaur"]:
		assert_null(map.get_npc(id), "%s absent : le rival a pris Carapuce" % id)
	var money := GameState.money
	await _climb_and_step_west()
	assert_true(_boot.get_cutscene_director().is_running(), "scène lancée par le pas vers l'ouest")
	assert_true(await _play_through(), "le combat a eu lieu")
	assert_true(GameState.flags.has_flag(&"rival_route22_won"))
	assert_false(GameState.flags.has_flag(&"rival_route22_lost"))
	for line: String in OPENING + WIN_LINES:
		assert_true(_pages.has(line), "« %s » jouée" % line)
	for line: String in LOSE_LINES:
		assert_false(_pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_pages.find(OPENING[0]), 0, "la scène commence par le jeune Dresseur")
	assert_eq(GameState.money, money + 280, "35 × Nv. 8")
	assert_true(_bag_enabled.size() > 0 and _bag_enabled.all(func(on: bool) -> bool: return on),
		"SAC actif contre le rival")
	var moments := _rival_moments()
	assert_eq(moments.size(), 1, "un moment « Combat contre le rival »")
	if moments.size() == 1:
		assert_eq(moments[0].get("map"), "route_22")
		assert_eq((moments[0].get("details", {}) as Dictionary).get("outcome"), "win")
		assert_eq((moments[0].get("details", {}) as Dictionary).get("trainer"), "rival_route22")
	map = _boot.get_map()
	assert_eq(map.map_id, &"route_22", "on reste sur la Route 22")
	for id: StringName in SCENE_NPCS + [&"rival_squirtle"]:
		assert_null(map.get_npc(id), "%s parti" % id)
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_eq(_player.get_cell(), TRIGGER_CELL, "le joueur n'a pas bougé")
	# La scène ne se rejoue plus : retraverser le déclencheur, revenir sur la carte.
	await _walk_to(Vector2i(15, 13))
	await _walk_to(TRIGGER_CELL)
	assert_false(_boot.get_cutscene_director().is_running(), "aucune scène rejouée")
	await SceneRouter.change_map(&"route_22", &"stair_foot", Vector2i.UP)
	await wait_process_frames(3)
	for id: StringName in SCENE_NPCS + [&"rival_squirtle"]:
		assert_null(_boot.get_map().get_npc(id), "%s absent en revenant" % id)
	await _climb_and_step_west()
	assert_false(_boot.get_cutscene_director().is_running(), "toujours rien")
	assert_eq(_rival_moments().size(), 1)
	assert_true(_saved().get("flags", []).has("rival_route22_won"), "victoire sauvegardée")
	assert_push_error_count(0)


# --- Défaite ----------------------------------------------------------------------------------

func test_defeat_wakes_up_at_home_without_losing_money() -> void:
	await _start(WEAK_START)
	var money := GameState.money
	await _climb_and_step_west()
	assert_true(_boot.get_cutscene_director().is_running(), "scène lancée")
	var writes := _writes()
	assert_true(await _play_through(), "le combat a eu lieu")
	assert_true(GameState.flags.has_flag(&"rival_route22_lost"))
	assert_false(GameState.flags.has_flag(&"rival_route22_won"))
	for line: String in OPENING + LOSE_LINES:
		assert_true(_pages.has(line), "« %s » jouée" % line)
	for line: String in WIN_LINES:
		assert_false(_pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_boot.get_map().map_id, &"player_house_1f", "réveil chez Maman")
	assert_eq(_player.get_cell(), _boot.get_map().get_spawn_cell(&"heal"))
	assert_true(_pages.back() != LOSE_LINES.back(), "le mot de Maman suit la défaite")
	assert_eq(GameState.money, money, "aucun argent perdu")
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, pokemon.max_hp(), "équipe soignée")
	var moments := _rival_moments()
	assert_eq(moments.size(), 1)
	if moments.size() == 1:
		assert_eq((moments[0].get("details", {}) as Dictionary).get("outcome"), "loss")
	assert_gt(_writes(), writes, "sauvegarde écrite")
	var saved := _saved()
	assert_true((saved.get("flags", []) as Array).has("rival_route22_lost"), "défaite écrite")
	assert_eq(int(saved.get("money", -1)), money)
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_false(_boot.get_cutscene_director().is_running())
	# Retour sur la Route 22 : plus personne, plus de scène.
	await SceneRouter.change_map(&"route_22", &"stair_foot", Vector2i.UP)
	await wait_process_frames(3)
	for id: StringName in SCENE_NPCS + [&"rival_squirtle"]:
		assert_null(_boot.get_map().get_npc(id), "%s absent après la défaite" % id)
	await _climb_and_step_west()
	assert_false(_boot.get_cutscene_director().is_running(), "la scène ne se rejoue plus")
	assert_push_error_count(0)


func test_defeat_wakes_up_at_the_last_center_used() -> void:
	await _start(WEAK_START)
	GameState.heal_map = &"viridian_center"
	GameState.heal_spawn = &"heal"
	await _climb_and_step_west()
	assert_true(await _play_through(), "le combat a eu lieu")
	assert_true(GameState.flags.has_flag(&"rival_route22_lost"))
	assert_eq(_boot.get_map().map_id, &"viridian_center", "réveil au Centre")
	assert_true(_pages.has("Voilà. Tout le monde est en pleine forme."), "mot de l'infirmière")
	assert_eq(GameState.money, 3000)
	assert_true(_player.is_input_enabled())
	assert_push_error_count(0)


# --- Entrées ----------------------------------------------------------------------------------

func _walk_to(goal: Vector2i) -> void:
	var delta := goal - _player.get_cell()
	if delta == Vector2i.ZERO:
		return
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var action: StringName = DIRECTIONS[direction]
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	Input.action_press(action)
	while Time.get_ticks_msec() < deadline:
		var cell := _player.get_cell()
		if _player.is_moving() and cell + direction == goal:
			Input.action_release(action)
		if cell == goal and not _player.is_moving():
			break
		if not _player.is_input_enabled():
			break
		await wait_process_frames(1)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), 2.0)
