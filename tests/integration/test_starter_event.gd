extends GutTest
## Choix du starter de bout en bout (jalon-04.md §13.3 à §13.6, T3), avec la vraie scène
## Boot au labo, l'autoload SceneRouter (fondus raccourcis), texte instantané et entrées
## injectées. Départ : drapeaux { oak_met, oak_lab_reunion } (Chen et le rival au labo), puis
## starter_offered (fin du discours de Chen) : le choix s'ouvre.
## Pour chacun des 3 starters : RENCONTRER (bouton, fiche, contrôles cachés), CHOISIR (le
## vrai bouton de la fiche), la scène starter_chosen : le Pokémon choisi finit sur la case que
## regarde le joueur, les 4 répliques dans l'ordre avec les bons noms (aucune « Ça devrait
## être intéressant. »), l'équipe vide jusqu'à « réciproque », le rival prend le bon Pokémon,
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
const FADE := 0.05
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]
## Espèce choisie → [colonne de rencontre, Pokémon du rival, case finale du joueur].
const CASES: Dictionary[StringName, Array] = {
	&"bulbasaur": [10, &"charmander", Vector2i(10, 7)],
	&"charmander": [11, &"squirtle", Vector2i(11, 7)],
	&"squirtle": [12, &"bulbasaur", Vector2i(11, 6)],
}
## Où le rival s'arrête en partant (data/cutscenes/starter.json) : au-dessus de la boîte de
## dialogue, pas derrière la plante de l'entrée.
const RIVAL_STOP := Vector2i(8, 7)
const SCENE_LINES: Array = [
	["Prof. Chen", "On dirait que le choix est réciproque."],
	["Rival", "Alors ce sera toi."],
	["Rival", "Attends."],
	["Rival", "On ne va quand même pas partir sans savoir ce qu'ils savent faire."],
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
	_player = _boot.get_player()
	await wait_process_frames(2)
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
	var deadline := Time.get_ticks_msec() + 30000
	while director.is_running() and Time.get_ticks_msec() < deadline:
		was_free = was_free or _player.is_input_enabled()
		controls_seen = controls_seen or hud.are_controls_visible()
		await wait_process_frames(1)
		if box.is_open():
			var page := [box.get_speaker_text(), box.get_text()]
			if pages.is_empty() or pages.back() != page:
				pages.append(page)
				party_at.append(GameState.party.size())
			box.advance_requested.emit()
	assert_false(director.is_running(), "scène terminée")
	assert_false(was_free, "joueur jamais libre pendant la scène")
	assert_false(controls_seen, "aucun contrôle pendant la scène")
	assert_eq(pages, SCENE_LINES, "répliques dans l'ordre")
	assert_eq(party_at, [0, 1, 1, 1] as Array[int], "équipe vide jusqu'à « réciproque »")
	# Le Pokémon du joueur, devant lui.
	var mine := lab.get_npc(species)
	assert_eq(_player.get_cell(), CASES[species][2], "pas du joueur")
	assert_eq(mine.get_cell(), _player.get_cell() + _player.get_facing(),
		"le Pokémon est sur la case que regarde le joueur")
	assert_eq(mine.get_lift(), 0.0, "descendu de la table")
	# Le Pokémon du rival, à côté de lui.
	var rival := lab.get_npc(&"rival")
	var theirs := lab.get_npc(rival_species)
	assert_eq(rival.get_cell(), RIVAL_STOP, "le rival est parti vers la sortie")
	var gap := theirs.get_cell() - rival.get_cell()
	assert_eq(absi(gap.x) + absi(gap.y), 1, "son Pokémon à côté de lui")
	assert_eq(theirs.get_lift(), 0.0)
	assert_eq(rival.get_facing(), Grid.dominant_direction(rival.get_cell(),
		_player.get_cell()), "il regarde le joueur")
	# État de partie.
	assert_eq(GameState.party.size(), 1)
	assert_eq(GameState.party.get_lead().species_id, species)
	assert_eq(GameState.party.get_lead().level, 5)
	assert_eq(GameState.starter_species, species)
	for flag: StringName in [&"starter_chosen", &"rival_challenged",
			StarterChoice.taken_flag(species), StarterChoice.taken_flag(rival_species)]:
		assert_true(GameState.flags.has_flag(flag), String(flag))
	assert_true(_player.is_input_enabled(), "joueur libre")
	assert_true(hud.are_controls_visible(), "contrôles visibles")
	await _leave_the_lab()
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
