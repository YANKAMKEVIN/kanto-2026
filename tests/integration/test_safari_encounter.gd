extends GutTest
## Rencontre Safari de bout en bout (J23, T13 ; dossier 26 §5, `jalon-23.md` §2.3) avec la vraie
## scène Boot. Les cartes du Parc n'existant pas encore dans cette branche, la Route 1 est déclarée
## « carte du Parc » pour le test ([method EncounterDirector.set_safari_config]) ; la rencontre
## part de [method EncounterDirector.start_encounter], comme la pêche. Vérifie : aucun Pokémon
## allié en scène (dos du joueur), grille à quatre boutons, ni XP ni argent, capture → Stockage si
## l'équipe est pleine, dernière Ball (capture ou non) qui termine le combat et la visite,
## Pokédex vu / capturé, aucune rencontre sans visite active.

const STARTER := &"charmander"
const PARTY_SEED := 999
const FADE := 0.05
const TIMEOUT := 12.0
const FOE := &"nidoran_m"
const FOE_LEVEL := 22

var _boot: Boot
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	await wait_process_frames(2)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	var config := SafariConfig.new()
	assert_true(config.set_from_dict({"fee": 500, "balls": 30, "steps": 500, "ball_bonus": 2.0,
		"maps": ["route_1"], "end_map": "safari_zone_gate", "end_spawn": "end_of_visit"}))
	_boot.get_encounter_director().set_safari_config(config)


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]


# --- Mise en place -----------------------------------------------------------------------------

## Nouvelle partie (graine [param seed]) avec [param size] Pokémon et une visite de
## [param balls] Balls (inactive si 0).
func _new_game(seed: int, size: int, balls: int) -> void:
	GameState.new_game(seed)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	GameState.starter_species = STARTER
	var data := _boot.get_pokemon_data()
	var party := Party.new()
	for i: int in size:
		party.add(PokemonFactory.create(data, STARTER, 20, GameRng.new(PARTY_SEED + i)))
	GameState.party = party
	GameState.money = 1234
	var visit := SafariVisit.new()
	if balls > 0:
		visit.active = true
		visit.steps_left = 100
		visit.balls_left = balls
	GameState.safari = visit


## Vrai si le premier lancer capture avec la graine [param seed] (même consommation que le jeu :
## création du sauvage, puis CaptureCalc au taux de l'espèce × 2).
func _first_ball_catches(seed: int) -> bool:
	var data := _boot.get_pokemon_data()
	var rng := GameRng.new(seed)
	var foe := PokemonFactory.create(data, FOE, FOE_LEVEL, rng)
	var battle := SafariBattle.new(foe, data, _visit(5), 2.0, rng)
	battle.start()
	for event: BattleEvent in battle.submit(BattleAction.safari_ball()):
		if event.kind == BattleEvent.Kind.CAUGHT:
			return true
	return false


func _visit(balls: int) -> SafariVisit:
	var visit := SafariVisit.new()
	visit.active = true
	visit.steps_left = 100
	visit.balls_left = balls
	return visit


func _seed(caught: bool) -> int:
	for seed: int in range(0, 500):
		if _first_ball_catches(seed) == caught:
			return seed
	return -1


## Pilote la rencontre Safari : joue [param plan] (identifiants de la grille), une action par
## menu, ferme la carte de capture ; relève l'état de la scène au premier menu. Renvoie
## { outcome, menu: {...}, card: {...} }.
func _drive(plan: Array[StringName]) -> Dictionary:
	var enc := _boot.get_encounter_director()
	var director := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var stage := _boot.get_battle_stage()
	var report := {"outcome": Battle.Outcome.NONE, "menu": {}, "card": {}}
	enc.encounter_finished.connect(func(o: int) -> void: report["outcome"] = o)
	var step := 0
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		var card := director.get_capture_card()
		var safari := director.get_safari_battle()
		if card != null and card.is_waiting():
			report["card"] = {"result": card.get_result_text()}
			card.skip()
		elif safari != null and safari.get_state() == SafariBattle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.ACTIONS and step < plan.size():
			if report["menu"].is_empty():
				var grid := hud.get_action_grid()
				report["menu"] = {
					"ball": grid.get_button(ActionGrid.ATTACK).text,
					"bait": grid.get_button(ActionGrid.BAG).text,
					"rock": grid.get_button(ActionGrid.TEAM).text,
					"run": grid.get_button(ActionGrid.RUN).text,
					"all_enabled": ActionGrid.ACTIONS.all(grid.is_action_enabled),
					"ally_visible": stage.get_sprite(BattleEvent.SideId.PLAYER).visible,
					"own_card": hud.get_card(BattleHud.Side.PLAYER).is_shown(),
					"pips": hud.get_party_pips().is_shown(),
					"trainer": stage.is_trainer_shown(),
					"battle": director.get_battle(),
				}
			hud.action_selected.emit(plan[step])
			step += 1
		await wait_process_frames(1)
	assert_false(enc.is_running(), "la rencontre s'est terminée")
	return report


func _start() -> bool:
	return _boot.get_encounter_director().start_encounter(
		WildEncounter.new(FOE, FOE_LEVEL, &""))


# --- Tests -------------------------------------------------------------------------------------

func test_safari_menu_without_ally_and_run_leaves_everything_unchanged() -> void:
	_new_game(1, 1, 3)
	var exp_before := GameState.party.get_lead().experience
	assert_true(_start(), "rencontre Safari lancée")
	var report := await _drive([ActionGrid.RUN])
	var menu: Dictionary = report["menu"]
	assert_eq(menu.get("ball"), "SAFARI BALL ×3", "compteur de Balls sur le bouton")
	assert_eq(menu.get("bait"), "APPÂT")
	assert_eq(menu.get("rock"), "CAILLOU")
	assert_eq(menu.get("run"), "FUIR")
	assert_true(menu.get("all_enabled", false), "quatre boutons actifs")
	assert_false(menu.get("ally_visible", true), "aucun Pokémon allié en scène")
	assert_false(menu.get("own_card", true), "ni carte du joueur")
	assert_false(menu.get("pips", true), "ni pastilles d'équipe")
	assert_true(menu.get("trainer", false), "le dos du joueur à la place")
	assert_null(menu.get("battle"), "aucun moteur de combat ordinaire")
	assert_eq(report["outcome"], Battle.Outcome.FLED, "FUIR toujours réussi")
	assert_eq(GameState.money, 1234, "ni argent")
	assert_eq(GameState.party.get_lead().experience, exp_before, "ni XP")
	assert_true(GameState.safari.active, "visite toujours en cours")
	assert_eq(GameState.safari.balls_left, 3, "aucune Ball lancée")
	assert_true(GameState.pokedex.is_seen(FOE), "vu à l'apparition")
	assert_false(GameState.pokedex.is_caught(FOE))
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_eq(_boot.get_battle_hud().get_action_grid().get_button(ActionGrid.ATTACK).text,
		"ATTAQUER", "libellés rendus après la rencontre")
	assert_push_error_count(0)


func test_last_ball_capture_with_a_full_team_goes_to_storage_and_ends_the_visit() -> void:
	var seed := _seed(true)
	assert_gt(seed, -1, "une graine : capture au premier lancer")
	if seed < 0:
		return
	_new_game(seed, 6, 1)
	var stored: Array = []
	_boot.get_battle_director().pokemon_caught.connect(
		func(_p: Pokemon, in_storage: bool) -> void: stored.append(in_storage))
	assert_true(_start())
	var report := await _drive([ActionGrid.ATTACK])
	assert_eq(report["outcome"], Battle.Outcome.CAUGHT)
	assert_eq(stored, [true], "équipe pleine : Stockage")
	assert_eq(GameState.party.size(), 6)
	assert_eq(GameState.storage.size(), 1, "rangé au Stockage")
	assert_true(GameState.pokedex.is_caught(FOE), "capturé au Pokédex")
	assert_false(GameState.safari.active, "la dernière Ball termine la visite")
	assert_eq(GameState.safari.balls_left, 0)
	assert_eq(GameState.money, 1234, "ni argent")
	assert_push_error_count(0)


func test_last_ball_without_capture_ends_the_battle_and_the_visit() -> void:
	var seed := _seed(false)
	assert_gt(seed, -1, "une graine : le premier lancer échoue")
	if seed < 0:
		return
	_new_game(seed, 1, 1)
	assert_true(_start())
	var report := await _drive([ActionGrid.ATTACK])
	assert_eq(report["outcome"], Battle.Outcome.FLED, "[D] fin sans capture")
	assert_false(GameState.pokedex.is_caught(FOE))
	assert_false(GameState.safari.active, "visite terminée")
	assert_eq(GameState.storage.size(), 0)
	assert_eq(GameState.party.size(), 1)
	assert_true(_player.is_input_enabled())
	assert_push_error_count(0)


func test_bait_and_rock_turns_play_through() -> void:
	_new_game(3, 1, 5)
	assert_true(_start())
	var report := await _drive([ActionGrid.BAG, ActionGrid.TEAM, ActionGrid.BAG,
		ActionGrid.TEAM, ActionGrid.RUN])
	assert_true(report["outcome"] in [Battle.Outcome.FLED, Battle.Outcome.FOE_FLED],
		"FUIR, ou le Pokémon s'est enfui avant")
	assert_true(GameState.safari.active)
	assert_eq(GameState.safari.balls_left, 5, "appât et caillou ne coûtent aucune Ball")
	assert_push_error_count(0)


func test_no_encounter_in_the_park_without_an_active_visit() -> void:
	_new_game(1, 1, 0)
	assert_false(_start(), "aucune rencontre sans visite")
	assert_false(_boot.get_encounter_director().is_running())
	assert_false(GameState.pokedex.is_seen(FOE), "rien n'est vu")
