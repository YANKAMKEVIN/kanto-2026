extends GutTest
## Premier combat contre le rival, de bout en bout (jalon-04.md §14.11 T8), avec la vraie
## scène Boot au labo, l'autoload SceneRouter (fondus raccourcis), texte et animations de
## combat instantanés, et des graines choisies pour GAGNER et pour PERDRE, pour chacun des 3
## starters (le joueur choisit toujours sa 1re capacité).
## Vérifie, pour les 6 cas : le choix, la scène, le combat, la fin ; l'issue attendue et ses
## drapeaux (rival_lab_won / _lost, rival_battle_done, rival_left_lab, rival_challenged) ; les
## répliques du rival de l'issue seulement, puis les 3 répliques du Prof. Chen, « Une dernière
## chose. », la toast « Poké Balls ×5 » et « Ajoutées au Sac », les 2 dernières répliques ;
## bag.count_of(poke_ball) == 5 ; rival et starter du joueur absents ; équipe : 1 Pokémon, PV
## pleins ; joueur libre, contrôles visibles ; aucune réplique répétée du 4A (« réciproque »
## une seule fois, jamais rejouée après le combat). Retour au labo : rival absent, starter
## restant sur la table.

const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const TIMEOUT_MS := 8000
const FADE := 0.05
## Espèce choisie → [colonne de rencontre, Pokémon du rival].
const CASES: Dictionary[StringName, Array] = {
	&"bulbasaur": [10, &"charmander"],
	&"charmander": [11, &"squirtle"],
	&"squirtle": [12, &"bulbasaur"],
}
const WIN_LINES: Array[String] = [
	"...Pas mal.", "On a encore du travail.", "La prochaine fois, ce sera différent.",
	"Essaie de ne pas trop prendre de retard.",
]
const LOSE_LINES: Array[String] = [
	"Pas mal pour un premier combat.", "Mais je t'avais prévenu : j'étais prêt.",
	"Rattrape-moi quand tu le seras aussi.",
]
const OAK_LINES: Array[String] = [
	"Pour un premier combat, c'était honorable.",
	"Mais gagner n'est qu'une partie de ce qu'un Dresseur doit apprendre.",
	"Apprends à connaître ton Pokémon. Il fera de même avec toi.",
	"Une dernière chose.",
]
const LEVEL := 5

var _boot: Boot
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.start_map = &"oak_lab"
	_boot.start_spawn = &"entrance"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	await wait_process_frames(2)
	_boot.get_battle_director().speed_scale = 0.0


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"interact")


func test_bulbasaur_wins() -> void:
	await _play_battle(&"bulbasaur", Battle.Outcome.WIN)


func test_bulbasaur_loses() -> void:
	await _play_battle(&"bulbasaur", Battle.Outcome.LOSS)


func test_charmander_wins() -> void:
	await _play_battle(&"charmander", Battle.Outcome.WIN)


func test_charmander_loses() -> void:
	await _play_battle(&"charmander", Battle.Outcome.LOSS)


func test_squirtle_wins() -> void:
	await _play_battle(&"squirtle", Battle.Outcome.WIN)


func test_squirtle_loses() -> void:
	await _play_battle(&"squirtle", Battle.Outcome.LOSS)


func _play_battle(species: StringName, outcome: int) -> void:
	var seed := _seed_for(species, outcome)
	assert_gt(seed, -1, "%s : une graine pour l'issue %d" % [species, outcome])
	if seed < 0:
		return
	# Nouvelle partie de graine choisie, puis l'état du labo pendant le choix.
	GameState.new_game(seed)
	GameState.flags.set_flag(&"oak_met")
	GameState.flags.set_flag(&"oak_lab_reunion")
	_boot.get_map().refresh_npcs(GameState.flags)
	var hud := _boot.get_hud()
	var sheet := _boot.get_starter_sheet()
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var lab := _boot.get_map()
	var column: int = CASES[species][0]
	var rival_species: StringName = CASES[species][1]
	var toast: Array = []
	director.item_given.connect(func(item: StringName, count: int) -> void:
		toast.append([item, count]))
	GameState.flags.set_flag(&"starter_offered")
	# RENCONTRER puis CHOISIR.
	await _walk_path(Vector2i(column, 6))
	await _walk_to(Vector2i(column, 5))
	await wait_process_frames(2)
	await _press_interact()
	assert_true(sheet.is_open(), "%s : fiche ouverte" % species)
	await wait_process_frames(2)
	sheet.get_choose_button().pressed.emit()
	assert_true(director.is_running(), "%s : scène lancée" % species)
	# Déroule la scène : dialogues avancés, combat piloté (ATTAQUER puis 1re capacité).
	var pages: Array[String] = []
	var reciprocal_count := 0
	var seen_battle := false
	var deadline := Time.get_ticks_msec() + 60000
	while director.is_running() and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			seen_battle = true
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			var text := box.get_text()
			if pages.is_empty() or pages.back() != text:
				pages.append(text)
				if text == "On dirait que le choix est réciproque.":
					reciprocal_count += 1
			box.advance_requested.emit()
	assert_false(director.is_running(), "%s : scène terminée" % species)
	assert_true(seen_battle, "%s : le combat a eu lieu" % species)
	# Issue et drapeaux.
	var won := outcome == Battle.Outcome.WIN
	assert_eq(GameState.flags.has_flag(&"rival_lab_won"), won, "%s : rival_lab_won" % species)
	assert_eq(GameState.flags.has_flag(&"rival_lab_lost"), not won, "%s : rival_lab_lost" % species)
	for flag: StringName in [&"rival_battle_done", &"rival_left_lab", &"rival_challenged",
			&"starter_chosen"]:
		assert_true(GameState.flags.has_flag(flag), "%s : %s" % [species, flag])
	# Répliques de l'issue seulement, puis celles du Prof. Chen.
	var expected := WIN_LINES if won else LOSE_LINES
	var forbidden := LOSE_LINES if won else WIN_LINES
	for line: String in expected:
		assert_true(pages.has(line), "%s : « %s » jouée" % [species, line])
	for line: String in forbidden:
		assert_false(pages.has(line), "%s : « %s » PAS jouée (autre issue)" % [species, line])
	for line: String in OAK_LINES:
		assert_true(pages.has(line), "%s : Chen « %s »" % [species, line])
	assert_true(pages.has("Utilise-les avec discernement."), "%s : dernière réplique" % species)
	# Aucune réplique répétée du 4A : « réciproque » une seule fois (pendant le choix).
	assert_eq(reciprocal_count, 1, "%s : « réciproque » jouée une seule fois" % species)
	# Les 5 Poké Balls (toast + Sac).
	assert_eq(toast, [[&"poke_ball", 5]], "%s : une remise de 5 Poké Balls" % species)
	assert_eq(GameState.bag.count_of(&"poke_ball"), 5, "%s : 5 Poké Balls dans le Sac" % species)
	# Rival et starters partis ; équipe soignée ; joueur libre.
	assert_null(lab.get_npc(&"rival"), "%s : le rival a quitté le labo" % species)
	assert_null(lab.get_npc(species), "%s : le starter est rentré dans sa Ball" % species)
	assert_null(lab.get_npc(rival_species), "%s : celui du rival aussi" % species)
	assert_eq(GameState.party.size(), 1)
	assert_eq(GameState.party.get_lead().species_id, species)
	var lead := GameState.party.get_lead()
	assert_eq(lead.hp, lead.max_hp(), "%s : équipe soignée" % species)
	assert_true(_player.is_input_enabled(), "%s : joueur libre" % species)
	assert_true(hud.are_controls_visible(), "%s : contrôles visibles" % species)
	# Retour au labo : rival absent, seul le starter restant est sur la table.
	await _back_in_the_lab(species, rival_species)
	assert_push_error_count(0)


## Graine qui donne [param outcome] contre le rival avec le starter [param species] ; reproduit
## exactement la consommation d'aléatoire du jeu (starter du joueur créé, puis équipe du rival,
## puis submit de la 1re capacité). −1 si aucune sous la limite.
func _seed_for(species: StringName, outcome: int) -> int:
	var data := _boot.get_pokemon_data()
	var trainers := _boot.get_trainer_library()
	var trainer := trainers.get_trainer(&"rival_lab")
	for seed: int in range(0, 1500):
		var rng := GameRng.new(seed)
		var party := Party.new()
		party.add(PokemonFactory.create(data, species, LEVEL, rng))
		var foes := trainers.build_team(&"rival_lab", species, rng)
		var battle := Battle.new(BattleSide.new(party, true),
			BattleSide.new(foes, false, trainer.name, trainer.make_ai()), data, rng)
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING:
			battle.submit(BattleAction.move(0))
		if battle.get_outcome() == outcome:
			return seed
	return -1


func _back_in_the_lab(species: StringName, rival_species: StringName) -> void:
	await SceneRouter.change_map(&"oak_lab", &"entrance", Vector2i.UP)
	await wait_process_frames(2)
	var lab := _boot.get_map()
	assert_null(lab.get_npc(&"rival"), "rival absent en revenant")
	for id: StringName in [&"bulbasaur", &"charmander", &"squirtle"]:
		var npc := lab.get_npc(id)
		if id == species or id == rival_species:
			assert_null(npc, "%s a quitté la table" % id)
		else:
			assert_not_null(npc, "%s toujours sur la table" % id)


# --- Entrées -----------------------------------------------------------------------------

func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(1)
	Input.action_release(&"interact")
	await wait_process_frames(1)


func _walk_path(goal: Vector2i) -> void:
	var path := _boot.get_map().get_grid().find_path(_player.get_cell(), goal, _player)
	var cell := _player.get_cell()
	var i := 0
	while i < path.size():
		var direction := path[i]
		while i < path.size() and path[i] == direction:
			cell += direction
			i += 1
		await _walk_to(cell)


func _walk_to(goal: Vector2i) -> void:
	var delta := goal - _player.get_cell()
	if delta == Vector2i.ZERO:
		return
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var action: StringName = DIRECTIONS[direction]
	var blocked := not _boot.get_map().get_grid().is_free(goal)
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	Input.action_press(action)
	while Time.get_ticks_msec() < deadline:
		var cell := _player.get_cell()
		if blocked and _player.get_facing() == direction and cell + direction == goal:
			break
		if _player.is_moving() and cell + direction == goal:
			Input.action_release(action)
		if cell == goal and not _player.is_moving():
			break
		await wait_process_frames(1)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), 2.0)
