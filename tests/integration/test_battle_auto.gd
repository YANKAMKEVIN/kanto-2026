extends GutTest
## Mode auto (demande de Kevin du 2026-11-12) avec la vraie scène Boot sur la Route 1 :
## l'interrupteur AUTO n'est offert qu'en combat sauvage et seulement si le réglage caché est
## activé ; activé, le Pokémon en jeu finit le combat seul ; son K.O. coupe le mode auto et le
## choix du suivant redevient manuel ; jamais contre un Dresseur.

const STARTER := &"charmander"
const FADE := 0.05
const TIMEOUT := 12.0
const SELF_KO_MOVE := &"self_destruct"

var _boot: Boot
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	GameState.new_game(7)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = STARTER
	GameState.party = Party.new()
	_add(STARTER, 20)


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]


func _add(species: StringName, level: int) -> Pokemon:
	var pokemon := PokemonFactory.create(_boot.get_pokemon_data(), species, level,
		GameRng.new(999))
	GameState.party.add(pokemon)
	return pokemon


## Lance une rencontre sauvage et attend la grille d'actions du premier tour.
func _start_wild(species: StringName, level: int) -> void:
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(species, level, &"route_1_grass")))
	await _wait_actions()


func _wait_actions() -> void:
	var hud := _boot.get_battle_hud()
	var director := _boot.get_battle_director()
	await wait_until(func() -> bool:
		return director.is_running() and director.get_battle() != null \
			and director.get_battle().get_state() == Battle.State.CHOOSING \
			and hud.get_zone() == BattleHud.Zone.ACTIONS, TIMEOUT)


## Ferme le bilan de fin de combat s'il attend, jusqu'à la fin de la rencontre.
func _finish_encounter() -> void:
	var enc := _boot.get_encounter_director()
	var director := _boot.get_battle_director()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		director.handle_back()
		await wait_process_frames(1)
	assert_false(enc.is_running(), "la rencontre s'est terminée")


func test_the_switch_is_hidden_without_the_setting() -> void:
	await _start_wild(&"rattata", 2)
	var hud := _boot.get_battle_hud()
	assert_false(hud.get_auto_button().visible, "réglage désactivé : pas d'interrupteur")
	hud.auto_toggled.emit(true)
	assert_false(_boot.get_battle_director().is_auto(), "le mode auto ne s'active pas")
	hud.action_selected.emit(ActionGrid.RUN)
	await _finish_encounter()


func test_auto_wins_a_wild_battle_alone_then_resets() -> void:
	var director := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	director.auto_offered = true
	var outcomes: Array[int] = []
	director.battle_finished.connect(func(_id: StringName, outcome: int) -> void:
		outcomes.append(outcome))
	await _start_wild(&"rattata", 2)
	# Vibrations de la HUD actives, sans vibration réelle.
	var real_haptics := Haptics.enabled
	Haptics.enabled = false
	hud.haptics_enabled = true
	assert_true(hud.get_auto_button().visible, "interrupteur offert en combat sauvage")
	assert_false(hud.is_auto_on(), "désactivé au début du combat")
	# Combat instantané : il se joue en entier dès l'activation ; on note l'état à chaque
	# événement.
	var seen: Array[bool] = []
	director.event_played.connect(func(_event: BattleEvent) -> void:
		seen.append(director.is_auto()))
	hud.get_auto_button().button_pressed = true
	await _finish_encounter()
	assert_false(seen.is_empty(), "des tours ont été joués")
	assert_false(seen.has(false), "le mode auto a joué tous les tours")
	assert_eq(outcomes, [Battle.Outcome.WIN] as Array[int], "victoire sans aucun choix du joueur")
	assert_false(director.is_auto(), "coupé à la fin du combat")
	assert_false(hud.get_auto_button().visible, "interrupteur retiré")
	assert_eq(hud.message_hold_scale, 1.0, "tenue des messages rendue")
	assert_eq(_boot.get_battle_stage().fx_speed, 1.0, "vitesse des effets rendue")
	assert_true(hud.haptics_enabled, "vibrations rendues")
	Haptics.enabled = real_haptics
	assert_push_error_count(0)


func test_auto_turned_on_from_the_moves_takes_over() -> void:
	var director := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	director.auto_offered = true
	await _start_wild(&"rattata", 2)
	hud.action_selected.emit(ActionGrid.ATTACK)
	await wait_until(func() -> bool: return hud.get_zone() == BattleHud.Zone.MOVES, TIMEOUT)
	hud.get_auto_button().button_pressed = true
	await _finish_encounter()
	assert_eq(director.get_battle(), null)
	assert_push_error_count(0)


func test_a_ko_stops_auto_and_the_next_pokemon_is_chosen_by_hand() -> void:
	var director := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	director.auto_offered = true
	GameState.party.get_lead().hp = 1
	var second := _add(&"squirtle", 30)
	await _start_wild(&"rattata", 40)
	hud.get_auto_button().button_pressed = true
	await wait_until(func() -> bool:
		return director.get_battle() != null and director.get_battle().needs_replacement() \
			and director.get_party_panel() != null, TIMEOUT)
	assert_true(director.get_battle().needs_replacement(), "le Pokémon du mode auto est K.O.")
	assert_false(director.is_auto(), "le mode auto s'est arrêté")
	assert_false(hud.is_auto_on(), "interrupteur revenu sur désactivé")
	assert_eq(GameState.party.get_lead().hp, 0)
	assert_gt(second.hp, 0, "aucun changement automatique")
	director.get_party_panel().pokemon_chosen.emit(1)
	await _wait_actions()
	assert_false(director.is_auto(), "le suivant se joue à la main")
	hud.action_selected.emit(ActionGrid.RUN)
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while director.is_running() and Time.get_ticks_msec() < deadline:
		if hud.get_zone() == BattleHud.Zone.ACTIONS \
				and director.get_battle().get_state() == Battle.State.CHOOSING:
			hud.action_selected.emit(ActionGrid.RUN)
		await wait_process_frames(1)
	await _finish_encounter()


func test_no_auto_against_a_trainer() -> void:
	var director := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	director.auto_offered = true
	var actors: Dictionary[StringName, StringName] = {}
	var runner := func() -> void: await director.run(&"rival_lab", _boot.get_map(), actors)
	runner.call()
	await _wait_actions()
	assert_false(hud.get_auto_button().visible, "pas d'interrupteur contre un Dresseur")
	hud.auto_toggled.emit(true)
	assert_false(director.is_auto(), "jamais de mode auto contre un Dresseur")
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while director.is_running() and Time.get_ticks_msec() < deadline:
		director.handle_back()
		if director.get_battle() != null \
				and director.get_battle().get_state() == Battle.State.CHOOSING:
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_false(director.is_running())


## Le mode auto attaque : jamais une capacité de statut tant qu'une attaque porte.
func test_auto_plays_attacks_not_status_moves() -> void:
	var director := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var data := _boot.get_pokemon_data()
	director.auto_offered = true
	var used: Array[StringName] = []
	director.event_played.connect(func(event: BattleEvent) -> void:
		if event.kind == BattleEvent.Kind.MOVE_USED and event.side == BattleEvent.SideId.PLAYER:
			used.append(event.move_id))
	await _start_wild(&"onix", 8)
	hud.get_auto_button().button_pressed = true
	await _finish_encounter()
	assert_false(used.is_empty(), "le Pokémon a attaqué")
	for move_id: StringName in used:
		assert_false(BattleAI.is_status_move(data.get_move(move_id)), String(move_id))


## Sous ¼ des PV, l'IA jouerait Destruction : le mode auto ne met jamais son Pokémon K.O. seul.
func test_auto_never_plays_a_self_ko_move() -> void:
	var director := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var data := _boot.get_pokemon_data()
	director.auto_offered = true
	var lead := GameState.party.get_lead()
	lead.moves[0] = MoveSlot.new(SELF_KO_MOVE, 5)
	lead.moves[0].pp = 5
	lead.hp = maxi(lead.hp / 5, 1)
	assert_not_null(data.get_move(SELF_KO_MOVE).effect_of(MoveEffect.Kind.SELF_KO))
	var used: Array[StringName] = []
	director.event_played.connect(func(event: BattleEvent) -> void:
		if event.kind == BattleEvent.Kind.MOVE_USED and event.side == BattleEvent.SideId.PLAYER:
			used.append(event.move_id))
	await _start_wild(&"rattata", 2)
	hud.get_auto_button().button_pressed = true
	await _finish_encounter()
	assert_false(used.is_empty(), "le Pokémon a attaqué")
	assert_false(used.has(SELF_KO_MOVE), "jamais d'auto-K.O. en mode auto")
	assert_gt(lead.hp, 0)
