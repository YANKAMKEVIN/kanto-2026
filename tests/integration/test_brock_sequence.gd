extends GutTest
## Pierre de bout en bout (jalon-10.md §2.6–§2.8, T9 ; **rejoué dans l'Arène au T17**) avec la
## vraie scène Boot, la vraie carte `pewter_gym` et ses PNJ, la vraie scène `pewter_gym_brock`,
## les vraies données (Dresseur, carte, badge), les vraies entrées (`move_*`, `interact`),
## l'autoload SceneRouter (fondus raccourcis), le combat instantané et une sauvegarde en mémoire.
## - victoire : départ « Carapuce » du T16 (Carapuce N12, Roucool N10), détour par l'est (Liam
##   évité), on parle à Pierre depuis (7, 3) ; graine cherchée (Écume à chaque tour, victoire
##   sans K.O.) ; introduction → carte « PIERRE » → combat → « Bien joué. » → « BADGE ROCHE »
##   (une vibration légère) → réplique du badge ; `brock_met`, `badge_boulder`, 1 300 ₽, Grand
##   moment « badge » sur `pewter_gym` avec le souvenir de l'équipe, objectif « continuer vers
##   la Route 3. », sauvegarde ; Pierre ne relance plus la scène (allusion au rival) ;
## - défaite : départ `brock_weak` (Liam battu) après un soin au Centre d'Argenta : réplique de
##   défaite, réveil **au Centre d'Argenta** (aucun argent perdu, ni badge ni moment) ; retour à
##   l'Arène, Liam ne défie plus, la reprise sans introduction, la carte de nouveau, la victoire.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const TrainerSeed := preload("res://tests/helpers/trainer_seed.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SQUIRTLE_START := "res://tools/debug_start/brock_squirtle.json"
const WEAK_START := "res://tools/debug_start/brock_weak.json"
const SAVE_PATH := "user://test_brock_sequence_save.json"
const GYM := &"pewter_gym"
const DATE := "2026-10-08T18:00:00"
const FADE := 0.05
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 90000
const WALK_STOP := &"test_walk_stop"
const ENTRANCE := Vector2i(7, 9)
## Case d'où l'on parle à Pierre (7, 2), tourné ↑.
const TALK_CELL := Vector2i(7, 3)
## Écume, 3e capacité de Carapuce N12.
const BUBBLE := 2
const INTRO := "Je suis Pierre, Champion d'Argenta.\nMes Pokémon ont été entraînés pour tenir bon."
const RESUME := "Prêt à essayer autrement ?"
const WON := "Bien joué.\nMes Pokémon n'ont pas tenu face aux tiens."
const BADGE_LINE := "C'est la preuve de ta victoire\nà l'Arène d'Argenta."
const LOST := "Une équipe solide ne suffit pas.\nReviens avec une autre approche."
const RIVAL_HINT := "Un autre Dresseur de Bourg Palette\nest passé récemment."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
## Ce qui s'est passé, dans l'ordre : « page:<texte> », « card:<nom>/<titre> », « battle »,
## « caption:<texte> ».
var _events: Array[String] = []
var _vibrations: Array[int] = []
var _spotted: Array[StringName] = []
## Capacité jouée à chaque tour du combat piloté.
var _move_index := 0
## Case où [method _walk] arrête le joueur (voir [method _on_player_moved]).
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_events.clear()
	_vibrations.clear()
	_spotted.clear()
	_move_index = 0
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot (sauvegarde en mémoire) dans l'Arène, joueur à l'entrée tourné ↑, partie de
## [param start_path].
func _start(start_path: String) -> void:
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
	GameState.rng = GameRng.new(7)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_director().battle_started.connect(func(_id: StringName) -> void:
		_events.append("battle"))
	_boot.get_trainer_watcher().trainer_spotted.connect(
		func(npc_id: StringName, _trainer: StringName) -> void: _spotted.append(npc_id))
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)
	assert_eq(_boot.get_map().map_id, GYM)
	assert_eq(_player.get_cell(), ENTRANCE)


func _make_strong() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 40,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)
	_move_index = 0


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


## Arrivé sur la case visée : direction relâchée et joueur bloqué un instant, dans le signal du
## pas (le pas suivant ne s'enchaîne pas, comme devant une porte).
func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


## Maintient la direction jusqu'à [param until] (ou jusqu'à ce qu'une scène bloque le joueur).
func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Détour par l'est (hors de la vision de Liam) jusqu'à la case devant Pierre.
func _walk_detour() -> void:
	await _walk(Vector2i.UP, Vector2i(7, 8))
	await _walk(Vector2i.RIGHT, Vector2i(10, 8))
	await _walk(Vector2i.UP, Vector2i(10, 3))
	await _walk(Vector2i.LEFT, TALK_CELL)


## Parle à Pierre (le joueur est devant lui, bouton d'interaction) et déroule tout (pages,
## carte, combat piloté, légende, réveil éventuel).
func _talk_to_brock() -> bool:
	assert_eq(_player.get_cell(), TALK_CELL, "devant Pierre")
	_player.face(Vector2i.UP)
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var hud := _boot.get_hud()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	assert_eq(director.get_cutscene_id(), &"pewter_gym_brock", "la parole lance la scène")
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
						battle_hud.move_selected.emit(_move_index)
		var card := hud.get_champion_card()
		if card.is_showing() and not card_seen:
			card_seen = true
			_events.append("card:%s/%s" % [card.get_name_text(), card.get_title_text()])
			card.skip_hold()
		card_seen = card.is_showing()
		var caption := hud.get_caption()
		if caption.is_showing() and not caption_seen:
			_events.append("caption:" + caption.text)
		caption_seen = caption.is_showing()
		await wait_process_frames(1)
		if box.is_open():
			var text := box.get_text()
			var page := "page:" + text
			if _events.is_empty() or _events.back() != page:
				_events.append(page)
			box.advance_requested.emit()
	await wait_process_frames(3)
	return _events.has("battle")


func _index(event: String) -> int:
	return _events.find(event)


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


## Ordre de la victoire : … carte → combat → « Bien joué. » → « BADGE ROCHE » → réplique du badge.
func _assert_victory_order() -> void:
	var card := _index("card:PIERRE/Champion d'Arène d'Argenta")
	assert_gt(card, -1, "carte de présentation de Pierre")
	assert_gt(_index("battle"), card, "la carte avant le combat")
	assert_gt(_index("page:" + WON), _index("battle"))
	assert_gt(_index("caption:BADGE ROCHE"), _index("page:" + WON), "« BADGE ROCHE » ensuite")
	assert_gt(_index("page:" + BADGE_LINE), _index("caption:BADGE ROCHE"), "puis la réplique")
	assert_eq(_index("page:" + LOST), -1, "pas de réplique de défaite")


func test_victory_in_the_gym_badge_moment_objective_and_save() -> void:
	await _start(SQUIRTLE_START)
	var money := GameState.money
	assert_eq(_objective(), "obtenir le Badge Roche.")
	await _walk_detour()
	assert_eq(_spotted, [] as Array[StringName], "Liam évité par le détour")
	# Écume à chaque tour ; graine d'une victoire sans K.O. du côté du joueur.
	_move_index = BUBBLE
	var seed := TrainerSeed.find(&"pewter_gym_brock", GameState.party,
		GameState.starter_species, _boot.get_pokemon_data(), _boot.get_item_library(),
		_move_index)
	assert_gt(seed, -1, "une victoire de Carapuce contre Pierre")
	GameState.rng = GameRng.new(seed)
	assert_true(await _talk_to_brock(), "le combat a eu lieu")
	assert_eq(_index("page:" + INTRO), 0, "l'introduction d'abord")
	assert_eq(_index("page:" + RESUME), -1, "pas de reprise la première fois")
	_assert_victory_order()
	assert_true(GameState.flags.has_flag(&"brock_met"))
	assert_true(GameState.flags.has_flag(&"badge_boulder"))
	assert_false(GameState.flags.has_flag(&"beaten_pewter_gym_liam"), "Liam évité, pas battu")
	assert_eq(GameState.money, money + 1300)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1, "vibration légère, une fois")
	assert_eq(_boot.get_map().map_id, GYM, "toujours dans l'Arène")
	var moments := _badge_moments()
	assert_eq(moments.size(), 1, "Grand moment « badge »")
	if moments.size() == 1:
		assert_eq(moments[0]["map"], "pewter_gym", "carte où Pierre a été battu")
		var details: Dictionary = moments[0]["details"]
		assert_eq(BadgeMoment.badge_of(details), &"boulder")
		var team := BadgeMoment.team_of(details)
		var party := GameState.party.get_all()
		assert_eq(team.size(), party.size(), "toute l'équipe")
		for i: int in mini(team.size(), party.size()):
			assert_eq(team[i]["species"], party[i].species_id)
			assert_eq(team[i]["level"], party[i].level, "niveau après le bilan d'XP")
	assert_eq(_objective(), "continuer vers la Route 3.")
	assert_true(_player.is_input_enabled(), "joueur libre")
	await wait_until(func() -> bool:
		return (_saved().get("flags", []) as Array).has("badge_boulder"), 5.0)
	var saved := _saved()
	assert_true((saved.get("flags", []) as Array).has("badge_boulder"), "badge sauvegardé")
	var saved_badges := 0
	for moment: Variant in saved.get("moments", []):
		if moment is Dictionary and (moment as Dictionary).get("type") == "badge":
			saved_badges += 1
	assert_eq(saved_badges, 1, "moment sauvegardé")
	# Lui reparler : l'allusion au rival, plus de scène.
	_events.clear()
	_player.face(Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_process_frames(2)
	assert_eq(_boot.get_dialogue_box().get_text(), RIVAL_HINT)
	assert_false(_boot.get_cutscene_director().is_running())
	assert_push_error_count(0)


func test_defeat_wakes_at_the_pewter_center_then_resume_without_the_introduction() -> void:
	await _start(WEAK_START)
	# Soigné au Centre d'Argenta avant de venir : c'est le dernier point de repos.
	GameState.heal_map = &"pewter_center"
	GameState.heal_spawn = &"heal"
	var money := GameState.money
	await _walk(Vector2i.UP, TALK_CELL)
	assert_eq(_spotted, [] as Array[StringName], "Liam battu : pas de défi")
	assert_true(await _talk_to_brock(), "le combat a eu lieu")
	assert_eq(_index("page:" + INTRO), 0)
	assert_gt(_index("card:PIERRE/Champion d'Arène d'Argenta"), 0)
	assert_gt(_index("page:" + LOST), _index("battle"), "réplique de défaite")
	assert_eq(_index("page:" + WON), -1)
	assert_eq(_index("caption:BADGE ROCHE"), -1, "pas de badge")
	assert_true(GameState.flags.has_flag(&"brock_met"), "première rencontre mémorisée")
	assert_false(GameState.flags.has_flag(&"badge_boulder"))
	assert_true(_badge_moments().is_empty())
	assert_eq(GameState.money, money, "aucun argent perdu")
	assert_eq(_boot.get_map().map_id, &"pewter_center", "réveil au Centre d'Argenta")
	var lead := GameState.party.get_lead()
	assert_eq(lead.hp, lead.max_hp(), "soigné")
	assert_true(GameState.flags.has_flag(&"beaten_pewter_gym_liam"), "Liam reste battu")
	assert_eq(_objective(), "obtenir le Badge Roche.", "objectif inchangé")
	# Retour à l'Arène, mieux préparé : Liam ne défie plus, la reprise, la carte, la victoire.
	await SceneRouter.change_map(GYM, &"entrance", Vector2i.UP)
	await wait_process_frames(3)
	assert_eq(_player.get_cell(), ENTRANCE)
	_make_strong()
	_events.clear()
	await _walk(Vector2i.UP, TALK_CELL)
	assert_eq(_spotted, [] as Array[StringName], "toujours pas de défi de Liam")
	assert_true(await _talk_to_brock(), "second combat")
	assert_eq(_index("page:" + RESUME), 0, "reprise courte")
	assert_eq(_index("page:" + INTRO), -1, "pas d'introduction rejouée")
	_assert_victory_order()
	assert_true(GameState.flags.has_flag(&"badge_boulder"))
	assert_eq(_badge_moments().size(), 1)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1)
	assert_push_error_count(0)
