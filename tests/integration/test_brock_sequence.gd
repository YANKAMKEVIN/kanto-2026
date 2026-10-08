extends GutTest
## Pierre de bout en bout (jalon-10.md §2.6–§2.8, T9) avec la vraie scène Boot, la vraie scène
## `pewter_gym_brock`, les vraies données (Dresseur, carte, badge), l'autoload SceneRouter (fondus
## raccourcis), le combat instantané et une sauvegarde en mémoire. L'Arène n'existe pas encore
## (T13, T17) : Pierre (sa description de `data/npcs/pewter_gym.json`) est posé devant le joueur
## sur Jadielle, et on lui parle (son dialogue lance la scène, comme en jeu).
## - victoire : introduction → carte « PIERRE » → combat → « Bien joué. » → « BADGE ROCHE » (une
##   vibration légère) → réplique du badge ; `brock_met`, `badge_boulder`, 1 300 ₽, Grand moment
##   « badge » avec le souvenir de l'équipe, objectif « continuer vers la Route 3. », sauvegarde ;
##   Pierre ne relance plus la scène (allusion au rival) ;
## - défaite : réplique de défaite, réveil (aucun argent perdu, ni badge ni moment) ; au retour, la
##   reprise sans introduction, la carte de nouveau, puis la victoire.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const GYM_START := "res://tools/debug_start/pewter_gym.json"
const WEAK_START := "res://tools/debug_start/brock_weak.json"
const SAVE_PATH := "user://test_brock_sequence_save.json"
const DATE := "2026-10-08T18:00:00"
const FADE := 0.05
const SCENE_TIMEOUT_MS := 90000
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


## Boot (sauvegarde en mémoire) sur Jadielle, partie de [param start_path] ; [param strong] :
## l'équipe devient un Salamèche Nv. 40 (Flammèche) pour gagner à coup sûr.
func _start(start_path: String, strong: bool) -> void:
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
	if strong:
		_make_strong()
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_director().battle_started.connect(func(_id: StringName) -> void:
		_events.append("battle"))
	await wait_process_frames(3)


func _make_strong() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 40,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)


## Pose Pierre sur une case libre voisine du joueur, le joueur tourné vers lui.
func _place_brock() -> Npc:
	var map := _boot.get_map()
	var spec := NpcRoster.load_for_map(&"pewter_gym").get_spec(&"brock")
	for direction: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		var cell := _player.get_cell() + direction
		if map.get_grid().is_free(cell) and map.get_npc(&"brock") == null:
			spec.cell = cell
			spec.facing = -direction
			_player.face(direction)
			return map.add_npc(spec)
	return null


## Parle à Pierre et déroule tout (pages, carte, combat piloté, légende, réveil éventuel).
func _talk_to_brock() -> bool:
	var brock := _place_brock()
	assert_not_null(brock, "Pierre posé devant le joueur")
	if brock == null:
		return false
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var hud := _boot.get_hud()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	assert_true(runner.play(brock.get_spec().dialogue, brock, _boot.get_map()))
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


func test_victory_badge_moment_objective_and_save() -> void:
	await _start(GYM_START, true)
	var money := GameState.money
	assert_eq(_objective(), "obtenir le Badge Roche.")
	assert_true(await _talk_to_brock(), "le combat a eu lieu")
	assert_eq(_index("page:" + INTRO), 0, "l'introduction d'abord")
	assert_eq(_index("page:" + RESUME), -1, "pas de reprise la première fois")
	_assert_victory_order()
	assert_true(GameState.flags.has_flag(&"brock_met"))
	assert_true(GameState.flags.has_flag(&"badge_boulder"))
	assert_eq(GameState.money, money + 1300)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1, "vibration légère, une fois")
	var moments := _badge_moments()
	assert_eq(moments.size(), 1, "Grand moment « badge »")
	if moments.size() == 1:
		assert_eq(moments[0]["map"], "viridian_city", "carte où Pierre a été battu")
		var details: Dictionary = moments[0]["details"]
		assert_eq(BadgeMoment.badge_of(details), &"boulder")
		var team := BadgeMoment.team_of(details)
		assert_eq(team.size(), 1)
		if team.size() == 1:
			assert_eq(team[0]["species"], GameState.party.get_all()[0].species_id)
			assert_eq(team[0]["level"], GameState.party.get_all()[0].level,
				"niveau après le bilan d'XP")
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
	var brock := _boot.get_map().get_npc(&"brock")
	assert_true(_boot.get_dialogue_runner().play(brock.get_spec().dialogue, brock,
		_boot.get_map()))
	await wait_process_frames(2)
	assert_eq(_boot.get_dialogue_box().get_text(), RIVAL_HINT)
	assert_false(_boot.get_cutscene_director().is_running())
	assert_push_error_count(0)


func test_defeat_then_resume_without_the_introduction() -> void:
	await _start(WEAK_START, false)
	var money := GameState.money
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
	assert_eq(_boot.get_map().map_id, &"player_house_1f", "réveil (aucun Centre enregistré)")
	assert_true(GameState.flags.has_flag(&"beaten_pewter_gym_liam"), "Liam reste battu")
	assert_eq(_objective(), "obtenir le Badge Roche.", "objectif inchangé")
	# Retour devant Pierre, mieux préparé : la reprise, la carte, la victoire.
	_make_strong()
	_events.clear()
	assert_true(await _talk_to_brock(), "second combat")
	assert_eq(_index("page:" + RESUME), 0, "reprise courte")
	assert_eq(_index("page:" + INTRO), -1, "pas d'introduction rejouée")
	_assert_victory_order()
	assert_true(GameState.flags.has_flag(&"badge_boulder"))
	assert_eq(_badge_moments().size(), 1)
	assert_eq(_vibrations.count(UiTokens.HAPTIC_BADGE_MS), 1)
	assert_push_error_count(0)
