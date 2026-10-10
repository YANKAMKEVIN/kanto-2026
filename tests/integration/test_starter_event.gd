extends GutTest
## Choix du starter de bout en bout (jalon-04.md §13.3 à §13.6, T3), avec la vraie scène
## Boot au labo, l'autoload SceneRouter (fondus raccourcis), texte instantané et entrées
## injectées. Départ : drapeaux { oak_met, oak_lab_reunion } (Chen et le rival au labo), puis
## starter_offered (fin du discours de Chen) : le choix s'ouvre.
## Pour chacun des 3 starters : RENCONTRER (bouton, fiche, contrôles cachés), CHOISIR (le
## vrai bouton de la fiche), la scène starter_chosen : le Pokémon choisi finit sur la case que
## regarde le joueur, les 5 répliques dans l'ordre avec les bons noms (dont « Ça devrait
## être intéressant. », décision n° 16), l'équipe vide jusqu'à « réciproque », le rival
## prend le bon Pokémon,
## qui finit à côté de lui ; rival_challenged ; joueur libre, contrôles visibles. Puis
## sortie du labo, entrée dans les hautes herbes sans pensée, retour au labo : seul le starter
## restant est sur la table (Observer).
## Sortie empêchée pendant le choix (§13.6) : « bas » tenu depuis (7, 8) → réplique de Chen,
## recul, toujours au labo ; libre avant starter_offered.

const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const TIMEOUT_MS := 8000
## Prénom du rival injecté (OUV.2 : l'étiquette « {rival} » des données affiche le prénom).
const RIVAL := "Régis"
const FADE := 0.05
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]
## Espèce choisie → [colonne de rencontre, Pokémon du rival, case finale du joueur (il
## recule d'un pas sans se retourner s'il y a la place : décision n° 16 et correction du
## saut du rival), case d'atterrissage de son Pokémon (à côté de lui)].
const CASES: Dictionary[StringName, Array] = {
	&"bulbasaur": [10, &"charmander", Vector2i(10, 7), Vector2i(11, 6)],
	&"charmander": [11, &"squirtle", Vector2i(11, 7), Vector2i(10, 7)],
	&"squirtle": [12, &"bulbasaur", Vector2i(12, 6), Vector2i(13, 6)],
}
## Où le rival s'arrête en partant (data/cutscenes/starter.json) : au-dessus de la boîte de
## dialogue, pas derrière la plante de l'entrée.
const RIVAL_STOP := Vector2i(7, 7)
const SCENE_LINES: Array = [
	["Prof. Chen", "On dirait que le choix est réciproque."],
	[RIVAL, "Alors ce sera toi."],
	[RIVAL, "Ça devrait être intéressant."],
	[RIVAL, "Attends."],
	[RIVAL, "On ne va quand même pas partir sans savoir ce qu'ils savent faire."],
]
const NAMES: Dictionary[StringName, String] = {
	&"bulbasaur": "BULBIZARRE", &"charmander": "SALAMÈCHE", &"squirtle": "CARAPUCE",
}

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
	GameState.rival_name = RIVAL
	_player = _boot.get_player()
	await wait_process_frames(2)
	# Combat instantané (le déroulé du combat a ses propres tests) : le choix reste à vitesse
	# réelle pour les sauts et regards.
	_boot.get_battle_director().speed_scale = 0.0
	GameState.flags.set_flag(&"oak_met")
	GameState.flags.set_flag(&"oak_lab_reunion")
	_boot.get_map().refresh_npcs(GameState.flags)


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"run")
	Input.action_release(&"interact")


func test_choose_bulbasaur() -> void:
	await _choose(&"bulbasaur")


func test_choose_charmander() -> void:
	await _choose(&"charmander")


func test_choose_squirtle() -> void:
	await _choose(&"squirtle")


func _choose(species: StringName) -> void:
	var hud := _boot.get_hud()
	var sheet := _boot.get_starter_sheet()
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var lab := _boot.get_map()
	var column: int = CASES[species][0]
	var rival_species: StringName = CASES[species][1]
	GameState.flags.set_flag(&"starter_offered")
	assert_true(_boot.get_starter_choice().is_open(), "choix ouvert")
	assert_true(hud.get_caption().is_showing(), "légende")
	# RENCONTRER, face au starter.
	await _walk_path(Vector2i(column, 6))
	await _walk_to(Vector2i(column, 5))
	await wait_process_frames(2)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "starter devant le joueur")
	if target == null:
		return
	assert_eq(target.kind, Interaction.Kind.MEET, "RENCONTRER")
	assert_eq(target.source, lab.get_npc(species))
	assert_eq(hud.get_interact_button().get_verb(), &"meet")
	await _press_interact()
	assert_true(sheet.is_open(), "fiche ouverte")
	assert_eq(sheet.get_name_text(), NAMES[species])
	assert_false(hud.are_controls_visible(), "contrôles cachés pendant la fiche")
	assert_true(_player.is_blocked_by(StarterChoice.REASON))
	await wait_seconds(0.3)
	# CHOISIR : le vrai bouton ; le joueur n'est jamais libre ensuite jusqu'à la fin.
	sheet.get_choose_button().pressed.emit()
	assert_true(director.is_running(), "scène lancée")
	assert_false(_player.is_input_enabled())
	var pages: Array[Array] = []
	var party_at: Array[int] = []
	var controls_seen := false
	var was_free := false
	var start_cell := _player.get_cell()
	var start_facing := _player.get_facing()
	var moved := false
	var turned_while_moving := false
	var turned_away := false
	var chosen := lab.get_npc(species)
	var theirs := lab.get_npc(rival_species)
	var rival := lab.get_npc(&"rival")
	# Positions relevées pendant la dernière réplique (ensuite, les Pokémon rentrent dans leur
	# Poké Ball) : [joueur, orientation, son Pokémon, orientation, lift, rival, orientation,
	# Pokémon du rival, lift].
	var at_challenge: Array = []
	# Jalon 4B : après « On ne va quand même pas… », le combat s'enchaîne dans la même scène ;
	# on le pilote (ATTAQUER puis la 1re capacité) et on gate les vérifications de la phase de
	# choix (le joueur peut ensuite se tourner vers Chen, sans tourner le dos à son Pokémon
	# rentré dans sa Ball).
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	var seen_battle := false
	var deadline := Time.get_ticks_msec() + 60000
	while director.is_running() and Time.get_ticks_msec() < deadline:
		was_free = was_free or _player.is_input_enabled()
		if battle_director.is_running():
			seen_battle = true
		if not seen_battle:
			if _player.is_moving():
				turned_while_moving = turned_while_moving or _player.get_facing() != start_facing
			if _player.get_cell() != start_cell and _player.get_cell() != CASES[species][2]:
				moved = true
			# Jamais dos à son Pokémon (décision n° 16), pendant la phase de choix.
			if is_instance_valid(chosen) and chosen.is_inside_tree():
				var to_mine := Vector2(chosen.get_cell() - _player.get_cell())
				turned_away = turned_away or to_mine.dot(Vector2(_player.get_facing())) < 0.0
		controls_seen = controls_seen or hud.are_controls_visible()
		var battle := battle_director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match battle_hud.get_zone():
				BattleHud.Zone.ACTIONS:
					battle_hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			var page := [box.get_speaker_text(), box.get_text()]
			if pages.is_empty() or pages.back() != page:
				pages.append(page)
				party_at.append(GameState.party.size())
				if page == SCENE_LINES.back():
					at_challenge = [_player.get_cell(), _player.get_facing(), chosen.get_cell(),
						chosen.get_facing(), chosen.get_lift(), rival.get_cell(),
						rival.get_facing(), theirs.get_cell(), theirs.get_lift()]
			box.advance_requested.emit()
	assert_false(director.is_running(), "scène terminée")
	assert_true(seen_battle, "le combat a eu lieu")
	assert_false(was_free, "joueur jamais libre pendant la scène")
	assert_false(moved, "le joueur ne fait qu'un pas en arrière (ou aucun)")
	assert_false(turned_while_moving, "il recule sans se retourner")
	assert_false(turned_away, "le joueur ne tourne jamais le dos à son Pokémon")
	assert_false(controls_seen, "aucun contrôle pendant la scène")
	assert_eq(pages.slice(0, 5), SCENE_LINES, "répliques du choix dans l'ordre")
	assert_eq(party_at.slice(0, 5), [0, 1, 1, 1, 1] as Array[int],
		"équipe vide jusqu'à « réciproque »")
	assert_eq(at_challenge.size(), 9, "positions relevées à la dernière réplique")
	if at_challenge.size() != 9:
		return
	# Le Pokémon du joueur, à côté de lui ; le joueur n'a pas bougé et le regarde.
	var player_cell: Vector2i = at_challenge[0]
	var player_facing: Vector2i = at_challenge[1]
	assert_eq(player_cell, CASES[species][2], "case du joueur")
	assert_eq(at_challenge[2], CASES[species][3], "à côté du joueur")
	var toward: Vector2i = (at_challenge[2] as Vector2i) - player_cell
	assert_eq(player_facing, Vector2i(signi(toward.x), 0), "le joueur regarde son Pokémon")
	assert_eq(at_challenge[3], -player_facing, "ils se regardent")
	assert_eq(at_challenge[4], 0.0, "descendu de la table")
	# Le Pokémon du rival, à côté de lui.
	var rival_cell: Vector2i = at_challenge[5]
	assert_eq(rival_cell, RIVAL_STOP, "le rival est parti vers la sortie")
	var gap: Vector2i = (at_challenge[7] as Vector2i) - rival_cell
	assert_eq(absi(gap.x) + absi(gap.y), 1, "son Pokémon à côté de lui")
	assert_eq(gap.y, 0, "côte à côte, pas derrière sa tête")
	assert_eq(at_challenge[8], 0.0)
	assert_eq(at_challenge[6], Grid.dominant_direction(rival_cell, player_cell),
		"il regarde le joueur")
	# Fin de la séquence (4B) : les deux Pokémon ont rejoint leur Poké Ball (le starter du
	# joueur tout à la fin, décision n° 17), leurs cases sont libres ; le rival a quitté le labo.
	assert_null(lab.get_npc(species), "son Pokémon est rentré dans sa Poké Ball")
	assert_null(lab.get_npc(rival_species), "celui du rival aussi")
	assert_false(lab.get_grid().is_occupied(CASES[species][3]), "case libérée")
	assert_false(lab.get_grid().is_occupied(at_challenge[7]), "case libérée")
	assert_null(lab.get_npc(&"rival"), "le rival a quitté le labo (rival_left_lab)")
	assert_eq(_player.get_cell(), player_cell)
	# État de partie et Sac : équipe soignée, 5 Poké Balls.
	assert_eq(GameState.party.size(), 1)
	assert_eq(GameState.party.get_lead().species_id, species)
	assert_eq(GameState.party.get_lead().level, 5)
	assert_eq(GameState.party.get_lead().hp, GameState.party.get_lead().max_hp(), "soigné")
	assert_eq(GameState.starter_species, species)
	assert_eq(GameState.bag.count_of(&"poke_ball"), 5, "5 Poké Balls dans le Sac")
	for flag: StringName in [&"starter_chosen", &"rival_challenged", &"rival_battle_done",
			&"rival_left_lab", StarterChoice.taken_flag(species),
			StarterChoice.taken_flag(rival_species)]:
		assert_true(GameState.flags.has_flag(flag), String(flag))
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_true(hud.are_controls_visible(), "contrôles visibles")
	await _leave_the_lab()
	assert_null(_boot.get_map().get_npc(species), "son Pokémon ne le suit pas dehors")
	await _enter_the_grass()
	await _back_in_the_lab(species, rival_species)
	assert_push_error_count(0)


## Après le choix : on sort (plus de scène sur le tapis).
func _leave_the_lab() -> void:
	await _walk_path(Vector2i(7, 9))
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return (_boot.get_map().map_id == &"pallet_town"
		and not SceneRouter.is_transitioning()), 5.0)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not _player.is_moving(), 2.0)
	assert_eq(_boot.get_map().map_id, &"pallet_town", "sorti du labo")


## Plus de pensée : on entre dans les hautes herbes (23, 2).
func _enter_the_grass() -> void:
	var map := _boot.get_map()
	var director := _boot.get_cutscene_director()
	_player.enter_map(map.get_grid(), Vector2i(23, 6), Vector2i.UP, map.get_pixel_rect())
	var ran := [false]
	var watch := func(_id: StringName) -> void: ran[0] = true
	director.cutscene_started.connect(watch)
	await _walk_to(Vector2i(23, 2))
	director.cutscene_started.disconnect(watch)
	assert_false(ran[0], "aucune scène aux herbes")
	assert_false(_boot.get_dialogue_box().is_open(), "pas de pensée")
	assert_eq(_player.get_cell(), Vector2i(23, 2), "dans les hautes herbes")


func _back_in_the_lab(species: StringName, rival_species: StringName) -> void:
	await SceneRouter.change_map(&"oak_lab", &"entrance", Vector2i.UP)
	await wait_process_frames(2)
	var lab := _boot.get_map()
	assert_eq(lab.map_id, &"oak_lab")
	for id: StringName in STARTERS:
		var npc := lab.get_npc(id)
		if id == species or id == rival_species:
			assert_null(npc, "%s a quitté la table" % id)
			continue
		assert_not_null(npc, "%s toujours sur la table" % id)
		if npc != null:
			assert_eq(npc.get_lift(), 56.0)
			assert_eq(npc.get_interaction().kind, Interaction.Kind.OBSERVE, "Observer")
	assert_false(_boot.get_starter_choice().is_open())
	assert_false(_boot.get_hud().get_caption().is_showing(), "plus de légende")


# --- Sortie du labo ----------------------------------------------------------------------

func test_exit_is_blocked_during_the_choice() -> void:
	GameState.flags.set_flag(&"starter_offered")
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var oak := _boot.get_map().get_npc(&"oak")
	await _walk_path(Vector2i(7, 8))
	var changes := [0]
	var count := func(_map: GameMap) -> void: changes[0] += 1
	SceneRouter.map_changed.connect(count)
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return box.is_open(), 5.0)
	assert_true(director.is_running())
	assert_eq(director.get_cutscene_id(), &"oak_lab_exit")
	assert_eq(_player.get_cell(), Vector2i(7, 9), "arrivé sur le tapis")
	assert_eq(box.get_speaker_text(), "Prof. Chen")
	assert_eq(box.get_text(), "Pas si vite. Tu n'as pas encore choisi ton partenaire.")
	assert_eq(oak.get_facing(), Grid.dominant_direction(oak.get_cell(), Vector2i(7, 9)),
		"Chen s'est tourné vers le joueur")
	assert_false(_boot.get_hud().are_controls_visible())
	assert_false(Input.is_action_pressed(&"move_down"), "contrôles cachés : bas relâché")
	await _finish_dialogue()
	await wait_until(func() -> bool: return not director.is_running(), 3.0)
	await wait_seconds(0.3)
	SceneRouter.map_changed.disconnect(count)
	assert_eq(changes[0], 0, "aucun changement de carte")
	assert_false(SceneRouter.is_transitioning())
	assert_eq(_boot.get_map().map_id, &"oak_lab", "toujours au labo")
	assert_eq(_player.get_cell(), Vector2i(7, 8), "recul d'un pas")
	assert_true(_player.is_input_enabled())
	assert_true(_boot.get_starter_choice().is_open(), "choix toujours ouvert")
	assert_push_error_count(0)


func test_exit_is_free_before_the_offer() -> void:
	assert_false(GameState.flags.has_flag(&"starter_offered"))
	await _leave_the_lab()
	assert_push_error_count(0)


# --- Entrées -----------------------------------------------------------------------------

func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(1)
	Input.action_release(&"interact")
	await wait_process_frames(1)


## Suit le plus court chemin vers [param goal] par segments droits.
func _walk_path(goal: Vector2i) -> void:
	var path := _boot.get_map().get_grid().find_path(_player.get_cell(), goal, _player)
	assert_false(path.is_empty() and _player.get_cell() != goal, "chemin vers %s" % goal)
	var cell := _player.get_cell()
	var i := 0
	while i < path.size():
		var direction := path[i]
		while i < path.size() and path[i] == direction:
			cell += direction
			i += 1
		await _walk_to(cell)


## Marche en ligne droite jusqu'à [param goal] ; case prise ou solide : se tourne seulement.
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
	if not blocked:
		assert_eq(_player.get_cell(), goal, "arrivé en %s" % goal)


func _finish_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		box.advance_requested.emit()
	assert_false(runner.is_running(), "dialogue terminé")
