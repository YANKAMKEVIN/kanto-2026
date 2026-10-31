extends GutTest
## Événement de la Route 1, de bout en bout (jalon 3B §3.4, T4), avec la vraie scène Boot,
## l'autoload SceneRouter (fondus raccourcis), texte instantané et entrées injectées :
## move_up tenu jusqu'au gel sur la case avant les herbes, « ??? », Chen qui arrive, ses
## répliques, le suivi, le labo (Chen en (8, 4), rival en (9, 6), joueur en (7, 7)), les
## quatre répliques avec « Rival » et « Prof. Chen », puis le contrôle rendu. Pendant la
## scène, le joueur ne fait que les pas scriptés et les contrôles restent cachés. Ensuite :
## Maya et sa nouvelle réplique, sortie du labo, pensée et recul aux herbes, chambre du
## rival vide. Même scénario sur les deux colonnes du chemin.
## Jalon 4 (T1) : après « Et pourtant, tu es toujours là. », les 4 répliques du Prof. Chen
## (il regarde la table à la 3e, revient vers le joueur à la 4e), starter_offered levé,
## contrôle rendu ; les starters s'observent encore (le choix n'est pas encore branché).
## Jalon 4 (T3) : après le discours, le choix est ouvert (légende, « Rencontrer » sur les
## trois starters) et la sortie du labo est empêchée (« Pas si vite. … », recul d'un pas) :
## la pensée des herbes, devenue inaccessible en jeu, est vérifiée en ramenant le joueur
## dans Bourg Palette par le routeur.

const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
const TIMEOUT_MS := 8000
## Prénom du rival injecté (OUV.2 : l'étiquette « {rival} » des données affiche le prénom).
const RIVAL := "Régis"
## Durée des fondus pendant le test (au lieu d'environ 0,45 s).
const FADE := 0.05
const REUNION: Array = [
	[RIVAL, "Enfin."],
	["Prof. Chen", "Un peu de patience."],
	[RIVAL, "Ça fait une heure que tu dis ça."],
	["Prof. Chen", "Et pourtant, tu es toujours là."],
]
const OFFER: Array = [
	["Prof. Chen", "Vous voulez tous les deux découvrir Kanto."],
	["Prof. Chen", "Mais découvrir ce monde sans aide serait une mauvaise idée."],
	["Prof. Chen", "Eux aussi ont encore beaucoup à découvrir."],
	["Prof. Chen", "Alors... pourquoi ne pas commencer ensemble ?"],
]

var _boot: Boot
var _player: Player
var _fades: Array[float] = []
## Pages vues pendant la scène : [locuteur, texte], sans doublon consécutif.
var _pages: Array[Array] = []
## Cases de chaque pas terminé du joueur pendant la scène.
var _steps: Array[Vector2i] = []
var _controls_seen := false
## Orientations relevées au début de chaque page du labo : [page, rival, Chen].
var _lab_facings: Array[Array] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_pages.clear()
	_steps.clear()
	_lab_facings.clear()
	_controls_seen = false
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.start_map = &"pallet_town"
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	GameState.rival_name = RIVAL
	_player = _boot.get_player()
	_player.moved.connect(func(cell: Vector2i) -> void:
		if _boot.get_cutscene_director().is_running():
			_steps.append(cell))
	_boot.get_dialogue_runner().page_started.connect(_on_page_started)


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"run")
	Input.action_release(&"interact")


func _on_page_started(_index: int) -> void:
	var map := _boot.get_map()
	if map.map_id != &"oak_lab" or map.get_npc(&"rival") == null:
		return
	_lab_facings.append([_boot.get_dialogue_box().get_text(),
		map.get_npc(&"rival").get_facing(), map.get_npc(&"oak").get_facing()])


func test_route1_event_from_the_left_column() -> void:
	await _play_event(23)


func test_route1_event_from_the_right_column() -> void:
	await _play_event(24)


func _play_event(column: int) -> void:
	var director := _boot.get_cutscene_director()
	var hud := _boot.get_hud()
	var map := _boot.get_map()
	_player.enter_map(map.get_grid(), Vector2i(column, 6), Vector2i.UP, map.get_pixel_rect())
	# Marche vers les herbes, move_up tenu : gel sur la case juste avant.
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return director.is_running(), 5.0)
	assert_true(director.is_running(), "scène lancée")
	assert_eq(_player.get_cell(), Vector2i(column, 3), "gel en (%d, 3)" % column)
	await wait_seconds(0.3)
	assert_eq(_player.get_cell(), Vector2i(column, 3), "aucun pas de plus, move_up tenu")
	# Toute la scène : on avance chaque page, on surveille contrôles et orientations.
	var oak_cell := Vector2i(-1, -1)
	var oak_met_before_follow := false
	var deadline := Time.get_ticks_msec() + 30000
	while director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if director.is_running():
			_controls_seen = _controls_seen or hud.are_controls_visible()
		var box := _boot.get_dialogue_box()
		if box.is_open():
			var page := [box.get_speaker_text(), box.get_text()]
			if _pages.is_empty() or _pages.back() != page:
				_pages.append(page)
			if box.get_speaker_text() == "Prof. Chen" and _boot.get_map().map_id == \
					&"pallet_town":
				oak_cell = _boot.get_map().get_npc(&"oak").get_cell()
			box.advance_requested.emit()
		if _steps.size() == 1 and oak_met_before_follow == false:
			oak_met_before_follow = GameState.flags.has_flag(&"oak_met")
	Input.action_release(&"move_up")
	assert_false(director.is_running(), "scène terminée")
	var other := 47 - column
	assert_eq(oak_cell, Vector2i(other, 3), "Chen arrêté sur l'autre colonne")
	assert_true(oak_met_before_follow, "oak_met levé avant le suivi")
	# Pages, dans l'ordre, avec les bons noms.
	var expected: Array = [["???", "Hé ! Attends !"],
		["Prof. Chen", "Tu allais vraiment entrer là-dedans tout seul ?"],
		["Prof. Chen",
			"Les Pokémon qui vivent ici ne sont pas tous aussi tranquilles que ceux du village."],
		["Prof. Chen", "Sans Pokémon à tes côtés, tu prends un risque inutile."],
		["Prof. Chen", "...Viens avec moi."]]
	expected.append_array(REUNION)
	expected.append_array(OFFER)
	assert_eq(_pages, expected)
	# Seulement les pas scriptés, après le pas qui a déclenché la scène : suivi (8 pas, le
	# premier sur la case de Chen), puis deux pas dans le labo.
	var scripted: Array[Vector2i] = [Vector2i(column, 3), Vector2i(other, 3)]
	for y: int in range(4, 11):
		scripted.append(Vector2i(other, y))
	scripted.append_array([Vector2i(7, 8), Vector2i(7, 7)] as Array[Vector2i])
	assert_eq(_steps, scripted, "le joueur n'a fait que les pas scriptés")
	assert_false(_controls_seen, "contrôles cachés pendant toute la scène")
	# Au labo.
	var lab := _boot.get_map()
	assert_eq(lab.map_id, &"oak_lab")
	assert_eq(_player.get_cell(), Vector2i(7, 7))
	assert_not_null(lab.get_npc(&"oak"))
	assert_not_null(lab.get_npc(&"rival"))
	if lab.get_npc(&"oak") == null or lab.get_npc(&"rival") == null:
		return
	assert_eq(lab.get_npc(&"oak").get_cell(), Vector2i(8, 4))
	assert_eq(lab.get_npc(&"rival").get_cell(), Vector2i(9, 6))
	assert_not_null(lab.get_npc(&"maya"))
	# Le rival regarde Chen puis le joueur (gauche) avant « Enfin. » ; chacun se tourne vers
	# celui à qui il répond.
	assert_eq(_lab_facings, [
		["Enfin.", Vector2i.LEFT, Vector2i.DOWN],
		["Un peu de patience.", Vector2i.LEFT, Vector2i.DOWN],
		["Ça fait une heure que tu dis ça.", Vector2i.UP, Vector2i.DOWN],
		["Et pourtant, tu es toujours là.", Vector2i.UP, Vector2i.DOWN],
		# Proposition : Chen regarde les trois Pokémon (table à sa droite) à la 3e, puis
		# revient vers le joueur (7, 7), sous lui.
		["Vous voulez tous les deux découvrir Kanto.", Vector2i.UP, Vector2i.DOWN],
		["Mais découvrir ce monde sans aide serait une mauvaise idée.", Vector2i.UP,
			Vector2i.DOWN],
		["Eux aussi ont encore beaucoup à découvrir.", Vector2i.UP, Vector2i.RIGHT],
		["Alors... pourquoi ne pas commencer ensemble ?", Vector2i.UP, Vector2i.DOWN],
	])
	assert_true(GameState.flags.has_flag(&"oak_met"))
	assert_true(GameState.flags.has_flag(&"oak_lab_reunion"))
	assert_true(GameState.flags.has_flag(&"starter_offered"), "Chen a proposé")
	assert_false(GameState.flags.has_flag(&"starter_chosen"))
	await wait_process_frames(1)
	_starters_ready_to_meet(lab)
	assert_true(hud.get_caption().visible, "légende « CHOISIS TON PREMIER PARTENAIRE »")
	assert_true(_player.is_input_enabled(), "contrôle rendu")
	assert_true(hud.are_controls_visible(), "contrôles visibles")
	await _talk_to_maya()
	await _exit_is_blocked()
	await SceneRouter.change_map(&"pallet_town", &"oak_lab_door", Vector2i.DOWN)
	await wait_process_frames(2)
	await _grass_thought(column)
	await _rival_room_is_empty()
	assert_push_error_count(0)


## Choix ouvert (T3) : les trois starters sont sur la table, « Rencontrer ».
func _starters_ready_to_meet(lab: GameMap) -> void:
	assert_true(_boot.get_starter_choice().is_open(), "choix ouvert")
	for id: StringName in [&"bulbasaur", &"charmander", &"squirtle"]:
		var npc := lab.get_npc(id)
		assert_not_null(npc, "%s sur la table" % id)
		if npc == null:
			continue
		assert_true(npc.has_interaction_override(), "%s : surcharge" % id)
		assert_eq(npc.get_interaction().kind, Interaction.Kind.MEET, "%s : Rencontrer" % id)
		assert_eq(npc.get_lift(), 56.0, "%s : toujours sur la table" % id)


## Sortie empêchée pendant le choix (jalon-04.md §13.6) : Chen parle, recul, toujours au labo.
func _exit_is_blocked() -> void:
	await _walk_path(Vector2i(7, 8))
	var director := _boot.get_cutscene_director()
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return director.is_running(), 5.0)
	await wait_until(func() -> bool: return _boot.get_dialogue_box().is_open(), 3.0)
	Input.action_release(&"move_down")
	assert_eq(_boot.get_dialogue_box().get_speaker_text(), "Prof. Chen")
	assert_eq(_boot.get_dialogue_box().get_text(),
		"Pas si vite. Tu n'as pas encore choisi ton partenaire.")
	await _finish_dialogue()
	await wait_until(func() -> bool: return not director.is_running(), 3.0)
	assert_eq(_boot.get_map().map_id, &"oak_lab", "toujours au labo")
	assert_eq(_player.get_cell(), Vector2i(7, 8), "recul d'un pas")
	assert_true(_player.is_input_enabled())


## Maya (5, 3), parlée depuis (5, 4) : « Ah, le professeur est revenu. »
func _talk_to_maya() -> void:
	await _walk_path(Vector2i(5, 4))
	await _walk_to(Vector2i(5, 3))  # tourne vers Maya (case occupée)
	await wait_process_frames(2)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "Maya devant le joueur")
	Input.action_press(&"interact")
	await wait_process_frames(1)
	Input.action_release(&"interact")
	await wait_process_frames(1)
	var texts := await _finish_dialogue()
	assert_eq(texts, ["Ah, le professeur est revenu.",
		"Et à voir son air, j'imagine qu'il a encore quelque chose en tête."] as Array[String])
	# Chen et le rival ont une réplique d'attente jusqu'au jalon 4 (décision de Kevin).
	assert_eq(_boot.get_map().get_npc(&"oak").get_interaction().dialogue_id, &"oak_lab_waiting")
	assert_eq(_boot.get_map().get_npc(&"rival").get_interaction().dialogue_id, &"rival_lab_waiting")


## Après l'événement : la pensée, puis un pas en arrière ; jamais dans les herbes.
func _grass_thought(column: int) -> void:
	var map := _boot.get_map()
	var director := _boot.get_cutscene_director()
	_player.enter_map(map.get_grid(), Vector2i(column, 5), Vector2i.UP, map.get_pixel_rect())
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return director.is_running(), 5.0)
	assert_eq(_player.get_cell(), Vector2i(column, 3))
	await wait_until(func() -> bool: return _boot.get_dialogue_box().is_open(), 3.0)
	Input.action_release(&"move_up")
	assert_eq(_boot.get_dialogue_box().get_speaker_text(), "")
	assert_true(_boot.get_dialogue_box().is_narration())
	assert_eq(_boot.get_dialogue_box().get_text(), "Je ne devrais pas aller là sans Pokémon.")
	await _finish_dialogue()
	await wait_until(func() -> bool: return not director.is_running(), 3.0)
	assert_eq(_player.get_cell(), Vector2i(column, 4), "recul d'un pas")
	assert_eq(_player.get_facing(), Vector2i.DOWN)
	assert_true(_player.is_input_enabled())


func _rival_room_is_empty() -> void:
	await SceneRouter.change_map(&"rival_house", &"entrance", Vector2i.UP)
	await wait_process_frames(2)  # sortir de l'émission du signal du fondu
	var map := _boot.get_map()
	assert_eq(map.map_id, &"rival_house")
	assert_null(map.get_npc(&"rival"), "le rival n'est plus chez lui")
	assert_true(map.get_npcs().is_empty())
	assert_false(map.get_grid().is_occupied(Vector2i(13, 4)))


# --- Entrées ---------------------------------------------------------------------------

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


## Marche en ligne droite jusqu'à [param goal] ; une case occupée : se tourne seulement.
func _walk_to(goal: Vector2i) -> void:
	var delta := goal - _player.get_cell()
	if delta == Vector2i.ZERO:
		return
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var action: StringName = DIRECTIONS[direction]
	var blocked := _boot.get_map().get_grid().is_occupied(goal)
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	Input.action_press(action)
	while Time.get_ticks_msec() < deadline:
		var cell := _player.get_cell()
		if blocked and _player.get_facing() == direction:
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


## Appuie sur `interact` jusqu'à la fin du dialogue ; renvoie les textes des pages vues.
func _finish_dialogue() -> Array[String]:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var texts: Array[String] = []
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open() and (texts.is_empty() or texts.back() != box.get_text()):
			texts.append(box.get_text())
		Input.action_press(&"interact")
		await wait_process_frames(1)
		Input.action_release(&"interact")
		await wait_process_frames(1)
	assert_false(runner.is_running(), "dialogue terminé")
	return texts
