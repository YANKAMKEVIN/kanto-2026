extends GutTest
## Arène de Carmin de bout en bout (jalon 16 T14, jalon-16.md §2.6, §2.9 ; dossier 19 §9, §13 ;
## textes n° 30 à 44 du §0.5) avec la vraie scène Boot, la vraie carte `vermilion_gym` et ses PNJ,
## les vraies données (puzzle, Dresseurs, Major Bob, badge, CT24), les vraies entrées (`move_*`,
## `interact`), l'autoload SceneRouter (fondus raccourcis), le combat instantané et une
## sauvegarde en mémoire :
## - puzzle Rouge/Bleu strict (G-8) joué en fouillant les vraies poubelles : premier tiré au
##   hasard, second voisin, erreur = remise à zéro et nouveau tirage, résolu pour toujours ;
##   sortir de l'Arène oublie la progression ;
## - victoire : n° 36 → carte « MAJOR BOB » → combat → n° 39 → « BADGE FOUDRE » → n° 40 → CT24
##   (n° 42, une fois) ; 2 400 ₽, Grand moment « badge », sauvegarde ; ensuite n° 44 ;
## - défaite : n° 37, réveil au Centre de Carmin sans perte d'argent, puzzle toujours résolu ;
##   reprise n° 38 sans introduction ni carte ;
## - partie badgée sans CT24 : rattrapage (n° 43 puis 42), une seule fois ;
## - les trois Dresseurs sont évitables ; guide n° 31.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const PUZZLE_START := "res://tools/debug_start/vermilion_gym_map.json"
const SOLVED_START := "res://tools/debug_start/vermilion_gym_solved.json"
const NO_TM_START := "res://tools/debug_start/thunder_no_tm.json"
const SAVE_PATH := "user://test_vermilion_gym_sequence_save.json"
const GYM := &"vermilion_gym"
const DATE := "2026-10-16T18:00:00"
const FADE := 0.05
const TIMEOUT_MS := 12000
const SCENE_TIMEOUT_MS := 120000
const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const ENTRANCE := Vector2i(8, 12)
const SURGE_CELL := Vector2i(8, 3)
const TALK_CELL := Vector2i(8, 4)
const BIN_XS: Array[int] = [2, 5, 8, 11, 14]
const BIN_YS: Array[int] = [7, 9, 11]
const TRAINERS: Array[StringName] = [&"gentleman_louis", &"rocker_axel", &"sailor_marc"]
const NOTHING := "Rien… juste des papiers froissés."
const FIRST := "Un interrupteur !\nLe premier verrou cède."
const SOLVED := "Le second interrupteur !\nLa barrière s'ouvre !"
const RESET := "Mauvais interrupteur !\nLes verrous se referment."
const GUIDE: Array[String] = [
	"Major Bob s'est retranché derrière une barrière électrique !",
	"Les interrupteurs sont cachés dans les poubelles. Il en faut deux, côte à côte.",
	"Une erreur, et tout se remet à zéro.",
]
## Indice du type Sol avant le Badge Foudre (décision de Kevin du 2026-10-16, R-3 + indice) :
## texte proposé par Claude, en brouillon jusqu'à sa relecture.
const GUIDE_HINT: Array[String] = [
	"Et un conseil : ses Pokémon sont tous de type Électrik.",
	"Un Pokémon de type Sol ne craint pas leurs décharges !",
]
const INTRO: Array[String] = [
	"Hé, petit ! Tu as réussi à ouvrir ma barrière ?",
	"Pas mal. Mais ici, c'est l'électricité qui commande.", "Voyons si tu tiens le choc !",
]
const LOST_LINES: Array[String] = ["Trop lent, petit !", "Reviens quand tu tiendras la charge."]
const RESUME := "Encore toi ? J'aime ça. En position !"
const WON_LINES: Array[String] = ["Ouch ! Tu m'as bien secoué.", "Du cran, petit. Tu as gagné."]
const BADGE_LINES: Array[String] = [
	"Voici le Badge Foudre.", "Il prouve que tu as tenu le choc face à Major Bob.",
]
const TM_GIVE := "Prends aussi ceci."
const TM_USE := "C'est la CT24, Tonnerre. Un Pokémon qui l'apprend la garde, et tu peux t'en resservir."
const TM_LATE := "J'allais oublier."
const AFTER := "Fais bon usage du Badge Foudre !"
const CARD := "card:MAJOR BOB/Champion d'Arène de Carmin"
const CAPTION := "caption:BADGE FOUDRE"
const TM_TOAST := "toast:CT24 — Tonnerre / obtenue"

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
## Ce qui s'est passé, dans l'ordre : « page:<texte> », « card:<nom>/<titre> », « battle »,
## « caption:<texte> », « toast:<titre> / <détail> ».
var _events: Array[String] = []
var _vibrations: Array[int] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_events.clear()
	_vibrations.clear()
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"interact")


## Boot (sauvegarde en mémoire) dans l'Arène, à l'entrée, partie de [param start_path].
## [param strong] : équipe remplacée par un Salamèche Nv. 60 (Flammèche).
func _start(start_path: String, strong: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = GYM
	_boot.start_spawn = &"entrance"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(start_path, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(11)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_director().battle_started.connect(func(_id: StringName) -> void:
		_events.append("battle"))
	if strong:
		_make_strong()
	await wait_process_frames(2)
	# Les PNJ sont posés selon les drapeaux au chargement de la carte : on la recharge.
	await _enter_gym()
	assert_eq(_player.get_cell(), ENTRANCE)


func _enter_gym() -> void:
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	_boot.get_battle_director().speed_scale = 0.0
	assert_eq(_boot.get_map().map_id, GYM)


func _make_strong() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 60,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)


func _make_weak() -> void:
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 5,
		GameState.rng))


## Les trois Dresseurs battus : aucun défi ne coupe la marche (leur évitement a son test).
func _beat_the_trainers() -> void:
	for id: String in ["gentleman_louis", "rocker_axel", "sailor_marc"]:
		GameState.flags.set_flag(StringName("beaten_vermilion_gym_" + id))


## Case de la poubelle [param slot] (1..15, ligne par ligne, comme la grille validée).
func _bin_cell(slot: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(BIN_XS[(slot - 1) % 5], BIN_YS[(slot - 1) / 5])


## Marche jusqu'à [param goal] par le chemin le plus court de la vraie grille.
func _walk_path(goal: Vector2i) -> void:
	if _player.get_cell() == goal:
		return
	var path := _boot.get_map().get_grid().find_path(_player.get_cell(), goal, _player)
	assert_false(path.is_empty(), "un chemin mène en %s" % goal)
	var cell := _player.get_cell()
	for direction: Vector2i in path:
		cell += direction
		await _walk_to(cell)
	assert_eq(_player.get_cell(), goal)


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


## Va devant la poubelle [param slot] (au sud si possible, sinon au nord), la fouille et déroule
## le dialogue (et la scène de la barrière). Pages lues, dans l'ordre.
func _search(slot: int) -> Array[String]:
	var bin := _bin_cell(slot)
	var grid := _boot.get_map().get_grid()
	var stand := bin + Vector2i.DOWN
	var facing := Vector2i.UP
	if grid.find_path(_player.get_cell(), stand, _player).is_empty() \
			and _player.get_cell() != stand:
		stand = bin + Vector2i.UP
		facing = Vector2i.DOWN
	await _walk_path(stand)
	_player.face(facing)
	_events.clear()
	await _interact_and_run()
	return _pages()


## Bouton d'interaction, puis tout : pages, carte, combat piloté, légende, toast, réveil.
func _interact_and_run() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var hud := _boot.get_hud()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var toast := hud.get_toast()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var card_seen := false
	var caption_seen := false
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		var card := hud.get_champion_card()
		if card.is_showing() and not card_seen:
			_events.append("card:%s/%s" % [card.get_name_text(), card.get_title_text()])
			card.skip_hold()
		card_seen = card.is_showing()
		var caption := hud.get_caption()
		if caption.is_showing() and not caption_seen:
			_events.append("caption:" + caption.text)
		caption_seen = caption.is_showing()
		if toast.visible:
			var shown := "toast:%s / %s" % [toast.get_title_text(), toast.get_detail_text()]
			if _events.is_empty() or _events.back() != shown:
				_events.append(shown)
		await wait_process_frames(1)
		if box.is_open():
			var page := "page:" + box.get_text()
			if _events.is_empty() or _events.back() != page:
				_events.append(page)
			box.advance_requested.emit()
	await wait_process_frames(3)


## Devant Major Bob, lui parle. Vrai si un combat a eu lieu.
func _talk_to_surge() -> bool:
	await _walk_path(TALK_CELL)
	_player.face(Vector2i.UP)
	await _interact_and_run()
	return _events.has("battle")


func _index(event: String) -> int:
	return _events.find(event)


func _pages() -> Array[String]:
	var found: Array[String] = []
	for event: String in _events:
		if event.begins_with("page:"):
			found.append(event.trim_prefix("page:"))
	return found


func _badge_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == String(BadgeMoment.TYPE):
			found.append(moment)
	return found


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _objective() -> String:
	var objectives := ObjectiveLibrary.new()
	objectives.load_file()
	return objectives.current(GameState.flags)


func _barrier_count() -> int:
	var count := 0
	for npc: Npc in _boot.get_map().get_npcs():
		if String(npc.get_id()).begins_with("vermilion_gym_barrier_"):
			count += 1
	return count


# --- Données et carte -------------------------------------------------------------------------

func test_surge_data_and_texts_match_the_validated_lot() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(&"vermilion_gym_surge")
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch, "change de Pokémon (Kevin, R-19)")
	assert_eq(trainer.prize_money, 2400, "défaut du plan")
	assert_eq([trainer.card_name, trainer.card_title], ["MAJOR BOB", "Champion d'Arène de Carmin"])
	var team := library.build_team(&"vermilion_gym_surge", &"charmander", GameRng.new(1))
	assert_eq(team.get_all().map(func(p: Pokemon) -> Array: return [p.species_id, p.level]),
		[[&"voltorb", 21], [&"pikachu", 18], [&"raichu", 24]])
	# Décision de Kevin du 2026-10-16 (R-3) : niveaux gardés, Raichu sans Tonnerre.
	assert_eq(team.get_all().map(func(p: Pokemon) -> Array:
		return p.moves.map(func(m: MoveSlot) -> StringName: return m.move_id)), [
			[&"tackle", &"screech", &"sonic_boom"],
			[&"thunder_shock", &"thunder_wave", &"quick_attack"],
			[&"thunder_shock", &"thunder_wave", &"quick_attack"],
		])
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), "\n".join(dialogues.get_errors()))
	var expected: Dictionary[StringName, Array] = {
		&"vermilion_gym_surge_intro": INTRO,
		&"vermilion_gym_surge_lost": LOST_LINES,
		&"vermilion_gym_surge_resume": [RESUME],
		&"vermilion_gym_surge_won": WON_LINES,
		&"vermilion_gym_surge_badge": BADGE_LINES,
		&"vermilion_gym_surge_tm": [TM_GIVE],
		&"vermilion_gym_surge_tm_use": [TM_USE],
		&"vermilion_gym_surge_tm_late": [TM_LATE],
		&"vermilion_gym_guide": GUIDE + GUIDE_HINT,
		&"vermilion_gym_sign": ["ARÈNE DE CARMIN\nChampion : Major Bob — L'homme électrique"],
	}
	for id: StringName in expected:
		var dialogue := dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		if dialogue == null:
			continue
		var texts: Array = []
		for page: DialoguePage in dialogue.variants[0].pages:
			texts.append(page.text)
		assert_eq(texts, expected[id], "texte validé : %s" % id)


func test_people_of_the_gym_and_avoidable_trainers() -> void:
	await _start(SOLVED_START)
	var map := _boot.get_map()
	assert_eq(_barrier_count(), 0, "puzzle résolu : barrière absente")
	var surge := map.get_npc(&"surge")
	assert_not_null(surge)
	assert_eq(surge.get_cell(), SURGE_CELL, "zone du Champion, derrière la barrière")
	assert_eq(map.get_npc(&"gym_guide").get_cell(), Vector2i(10, 12))
	var expected: Dictionary[StringName, Array] = {
		&"gentleman_louis": [Vector2i(3, 8), &"vermilion_gym_gentleman_louis"],
		&"rocker_axel": [Vector2i(12, 10), &"vermilion_gym_rocker_axel"],
		&"sailor_marc": [Vector2i(12, 6), &"vermilion_gym_sailor_marc"],
	}
	var grid := map.get_grid()
	var seen: Array[Vector2i] = []
	for id: StringName in TRAINERS:
		var npc := map.get_npc(id)
		assert_not_null(npc, String(id))
		if npc == null:
			continue
		var spec := npc.get_spec()
		assert_eq([npc.get_cell(), spec.trainer_id], expected[id])
		for k: int in range(1, spec.sight + 1):
			var cell := spec.cell + spec.facing * k
			if TrainerRules.sight_distance(grid, spec.cell, spec.facing, spec.sight, cell) == k:
				seen.append(cell)
	assert_eq(seen.size(), 9, "trois cases vues chacun")
	for cell: Vector2i in seen:
		grid.set_solid(cell)
	var reach := grid.find_reachable(ENTRANCE, _player)
	assert_true(reach.has(TALK_CELL), "Major Bob s'atteint sans être vu (Dresseurs évitables)")
	# Poubelles fouillables sans être vu : toutes, la 15 comprise (Axel avancé d'une case vers
	# l'ouest, en (12, 10), décision de Kevin du 2026-10-16 : on rejoint (13, 11) par (13, 9)).
	for slot: int in range(1, 16):
		var bin := _bin_cell(slot)
		var near := false
		for direction: Vector2i in DIRECTIONS:
			near = near or reach.has(bin + direction)
		assert_true(near, "poubelle %d fouillable sans être vu" % slot)
	for cell: Vector2i in seen:
		grid.set_solid(cell, false)
	assert_push_error_count(0)


## Avant le Badge Foudre : la règle (n° 31, validé) puis l'indice du type Sol (brouillon) ;
## après : la règle seule.
func test_guide_says_the_rule_and_the_ground_hint() -> void:
	await _start(PUZZLE_START)
	await _walk_path(Vector2i(9, 12))
	_player.face(Vector2i.RIGHT)
	await _interact_and_run()
	assert_eq(_pages(), GUIDE + GUIDE_HINT)
	GameState.flags.set_flag(&"badge_thunder")
	_player.face(Vector2i.RIGHT)
	_events.clear()
	await _interact_and_run()
	assert_eq(_pages(), GUIDE, "après le Badge Foudre : plus d'indice")
	assert_push_error_count(0)


## Poubelle n° 15 (14, 11) fouillée à pied sans jamais entrer dans une vue (Axel en (12, 10)) :
## aucun combat.
func test_bin_15_is_searched_without_a_battle() -> void:
	await _start(PUZZLE_START)
	var route: Array[Vector2i] = [Vector2i(7, 12), Vector2i(7, 11), Vector2i(7, 10),
		Vector2i(7, 9), Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8),
		Vector2i(11, 8), Vector2i(12, 8), Vector2i(12, 9), Vector2i(13, 9), Vector2i(13, 10),
		Vector2i(13, 11)]
	_events.clear()
	for cell: Vector2i in route:
		await _walk_to(cell)
		assert_eq(_player.get_cell(), cell, "pas à pas, hors de toute vue")
	_player.face(Vector2i.RIGHT)
	await _interact_and_run()
	assert_false(_events.has("battle"), "aucun Dresseur ne voit le joueur")
	var puzzle := _boot.get_active_puzzle(&"vermilion_gym")
	assert_not_null(puzzle, "la poubelle 15 a bien été fouillée")
	if puzzle != null:
		assert_eq(_pages(), [FIRST] if puzzle.first() == 15 else [NOTHING])
	for id: StringName in TRAINERS:
		assert_false(GameState.flags.has_flag(StringName("beaten_" + String(
			_boot.get_map().get_npc(id).get_spec().trainer_id))), "%s pas affronté" % id)
	assert_push_error_count(0)


# --- Puzzle -----------------------------------------------------------------------------------

func test_puzzle_strict_on_the_real_map() -> void:
	await _start(PUZZLE_START)
	_beat_the_trainers()
	assert_eq(_barrier_count(), 3, "barrière fermée")
	assert_false(_boot.get_map().get_grid().find_reachable(ENTRANCE, _player).has(TALK_CELL))
	assert_eq(_objective(), "ouvrir le passage vers Major Bob.")
	# Première fouille : le premier interrupteur est tiré à ce moment.
	var pages := await _search(13)
	var puzzle := _boot.get_active_puzzle(&"vermilion_gym")
	assert_not_null(puzzle, "puzzle tiré à la première fouille")
	var first := puzzle.first()
	assert_between(first, 1, 15)
	assert_eq(pages, [FIRST] if first == 13 else [NOTHING])
	if first != 13:
		assert_eq(await _search(first), [FIRST], "le premier interrupteur")
	assert_true(puzzle.is_first_found())
	var second := puzzle.second()
	assert_true(puzzle.neighbors(first).has(second), "le second est un voisin orthogonal")
	# Erreur : toute autre poubelle, y compris le premier → remise à zéro et nouveau tirage.
	assert_eq(await _search(first), [RESET], "GYM-04")
	assert_false(puzzle.is_first_found(), "remise à zéro")
	assert_eq(_barrier_count(), 3, "barrière toujours fermée")
	assert_false(GameState.flags.has_flag(&"vermilion_gym_puzzle_solved"))
	first = puzzle.first()
	assert_eq(await _search(first), [FIRST])
	second = puzzle.second()
	assert_true(puzzle.neighbors(first).has(second))
	assert_eq(await _search(second), [SOLVED], "GYM-03")
	assert_true(GameState.flags.has_flag(&"vermilion_gym_puzzle_solved"))
	assert_eq(_barrier_count(), 0, "barrière ouverte")
	assert_null(_boot.get_active_puzzle(&"vermilion_gym"), "plus aucun tirage")
	assert_true(_boot.get_map().get_grid().find_reachable(_player.get_cell(), _player)
		.has(TALK_CELL), "Major Bob accessible")
	assert_eq(_objective(), "affronter Major Bob.")
	# Résolu pour toujours : une poubelle ne contient plus rien, la barrière ne revient pas.
	assert_eq(await _search(second), [NOTHING])
	await SceneRouter.change_map(&"vermilion_city", &"from_gym", Vector2i.DOWN)
	await wait_process_frames(3)
	await _enter_gym()
	assert_eq(_barrier_count(), 0, "toujours ouverte au retour")
	await wait_until(func() -> bool:
		return (_saved().get("flags", []) as Array).has("vermilion_gym_puzzle_solved"), 5.0)
	assert_true((_saved().get("flags", []) as Array).has("vermilion_gym_puzzle_solved"),
		"résolution sauvegardée")
	assert_push_error_count(0)


func test_leaving_the_gym_forgets_the_first_switch() -> void:
	await _start(PUZZLE_START)
	_beat_the_trainers()
	await _search(13)
	var puzzle := _boot.get_active_puzzle(&"vermilion_gym")
	assert_not_null(puzzle)
	if puzzle.first() != 13:
		await _search(puzzle.first())
	assert_true(puzzle.is_first_found())
	await SceneRouter.change_map(&"vermilion_city", &"from_gym", Vector2i.DOWN)
	await wait_process_frames(3)
	var city := _boot.get_map()
	assert_eq(city.map_id, &"vermilion_city")
	assert_eq(_player.get_cell(), city.get_spawn_cell(&"from_gym"),
		"devant l'Arène, sur la case de l'arbuste coupé")
	await _enter_gym()
	assert_null(_boot.get_active_puzzle(&"vermilion_gym"), "progression effacée")
	assert_eq(_barrier_count(), 3)
	assert_false(GameState.flags.has_flag(&"vermilion_gym_puzzle_solved"))
	assert_push_error_count(0)


# --- Major Bob : victoire ---------------------------------------------------------------------

func test_victory_badge_tm_moment_objective_and_save() -> void:
	await _start(SOLVED_START, true)
	_beat_the_trainers()
	var money := GameState.money
	assert_eq(_objective(), "affronter Major Bob.")
	assert_true(await _talk_to_surge(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + WON_LINES + BADGE_LINES + [TM_GIVE, TM_USE]:
		assert_true(pages.has(line), "« %s » jouée" % line)
	for line: String in LOST_LINES + [RESUME, TM_LATE]:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index("page:" + INTRO[0]), 0, "l'introduction d'abord")
	var card := _index(CARD)
	assert_gt(card, _index("page:" + INTRO[2]), "la carte après l'introduction")
	assert_gt(_index("battle"), card, "la carte avant le combat")
	assert_gt(_index("page:" + WON_LINES[0]), _index("battle"))
	assert_gt(_index(CAPTION), _index("page:" + WON_LINES[1]), "légende ensuite")
	assert_gt(_index("page:" + BADGE_LINES[0]), _index(CAPTION))
	assert_gt(_index("page:" + TM_GIVE), _index("page:" + BADGE_LINES[1]))
	assert_gt(_index(TM_TOAST), _index("page:" + TM_GIVE), "le toast de la CT24")
	assert_gt(_index("page:" + TM_USE), _index("page:" + TM_GIVE))
	for flag: StringName in [&"surge_met", &"badge_thunder", &"tm24_received"]:
		assert_true(GameState.flags.has_flag(flag), String(flag))
	assert_eq(GameState.bag.count_of(&"tm24"), 1, "CT24 au Sac")
	assert_eq(GameState.money, money + 2400)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1, "vibration légère, une fois")
	assert_eq(_boot.get_map().map_id, GYM, "toujours dans l'Arène")
	var moments := _badge_moments()
	assert_eq(moments.size(), 1, "Grand moment « badge »")
	if moments.size() == 1:
		assert_eq(moments[0]["map"], "vermilion_gym")
		assert_eq(BadgeMoment.badge_of(moments[0]["details"]), &"thunder")
	assert_ne(_objective(), "affronter Major Bob.", "objectif de l'Arène terminé")
	assert_true(_player.is_input_enabled(), "joueur libre")
	await wait_until(func() -> bool:
		return (_saved().get("flags", []) as Array).has("badge_thunder"), 5.0)
	var saved_flags: Array = _saved().get("flags", [])
	assert_true(saved_flags.has("badge_thunder"), "badge sauvegardé")
	assert_true(saved_flags.has("tm24_received"))
	# Lui reparler : n° 44, plus de scène ni de CT.
	_events.clear()
	_player.face(Vector2i.UP)
	await _interact_and_run()
	assert_eq(_pages(), [AFTER])
	assert_eq(_index("battle"), -1)
	assert_eq(GameState.bag.count_of(&"tm24"), 1, "une seule CT24")
	assert_eq(_badge_moments().size(), 1)
	assert_push_error_count(0)


# --- Major Bob : défaite et reprise -----------------------------------------------------------

func test_defeat_wakes_at_vermilion_center_puzzle_stays_solved_then_resume() -> void:
	await _start(SOLVED_START)
	_beat_the_trainers()
	_make_weak()
	GameState.heal_map = &"vermilion_center"
	GameState.heal_spawn = &"heal"
	var money := GameState.money
	assert_true(await _talk_to_surge(), "le combat a eu lieu")
	var pages := _pages()
	for line: String in INTRO + LOST_LINES:
		assert_true(pages.has(line), "« %s » jouée" % line)
	assert_gt(_index("page:" + LOST_LINES[0]), _index("battle"), "défaite après le combat")
	assert_gt(_index(CARD), -1, "carte à la première rencontre")
	for line: String in WON_LINES + BADGE_LINES + [TM_GIVE]:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_eq(_index(CAPTION), -1, "pas de badge")
	assert_true(GameState.flags.has_flag(&"surge_met"))
	assert_false(GameState.flags.has_flag(&"badge_thunder"))
	assert_false(GameState.flags.has_flag(&"tm24_received"))
	assert_eq(GameState.bag.count_of(&"tm24"), 0)
	assert_true(_badge_moments().is_empty())
	assert_eq(GameState.money, money, "aucun argent perdu")
	assert_eq(_boot.get_map().map_id, &"vermilion_center", "réveil au Centre de Carmin")
	var lead := GameState.party.get_lead()
	assert_eq(lead.hp, lead.max_hp(), "soigné")
	assert_true(GameState.flags.has_flag(&"vermilion_gym_puzzle_solved"), "puzzle résolu")
	assert_eq(_objective(), "affronter Major Bob.", "objectif inchangé")
	# Retour : barrière toujours ouverte, n° 38 sans introduction ni carte, puis la victoire.
	await _enter_gym()
	assert_eq(_barrier_count(), 0, "barrière ouverte même après la défaite")
	_make_strong()
	_events.clear()
	assert_true(await _talk_to_surge(), "second combat")
	pages = _pages()
	assert_eq(_index("page:" + RESUME), 0, "reprise courte")
	for line: String in INTRO:
		assert_false(pages.has(line), "« %s » PAS rejouée" % line)
	assert_eq(_index(CARD), -1, "pas de carte aux reprises")
	assert_gt(_index(CAPTION), _index("battle"))
	assert_true(GameState.flags.has_flag(&"badge_thunder"))
	assert_eq(_badge_moments().size(), 1)
	assert_eq(GameState.bag.count_of(&"tm24"), 1)
	assert_push_error_count(0)


# --- Rattrapage de la CT24 --------------------------------------------------------------------

func test_a_badged_game_without_the_tm_gets_it_once() -> void:
	await _start(NO_TM_START)
	assert_false(GameState.flags.has_flag(&"tm24_received"))
	assert_false(await _talk_to_surge(), "aucun combat")
	assert_eq(_pages(), [TM_LATE, TM_GIVE, TM_USE])
	assert_true(_events.has(TM_TOAST))
	assert_eq(GameState.bag.count_of(&"tm24"), 1)
	assert_true(GameState.flags.has_flag(&"tm24_received"))
	_events.clear()
	_player.face(Vector2i.UP)
	await _interact_and_run()
	assert_eq(_pages(), [AFTER], "plus de remise, la parole d'après")
	assert_eq(GameState.bag.count_of(&"tm24"), 1, "une seule CT24")
	assert_push_error_count(0)
