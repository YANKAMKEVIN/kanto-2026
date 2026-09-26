extends GutTest
## Déroulé d'ouverture (jalon 2 §2.6, §4.2–4.4, T5) avec la vraie scène Boot et l'autoload
## SceneRouter, entrées injectées (Input.action_press) et images du moteur :
## chambre → escalier → rez-de-chaussée → tapis → Bourg Palette en (36, 9) face au sud,
## titre « Bourg Palette / Kanto » affiché une fois ; rentrer puis ressortir n'en affiche
## pas d'autre.
## Jalon 3A (T3) : à la première descente, Maman parle d'elle-même (le joueur ne bouge pas,
## même move_down tenu) ; on avance le dialogue avec `interact`. En revenant, lui parler
## donne sa seconde réplique.

const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
## Temps maximal d'un segment de marche ou d'une transition (secondes réelles).
const TIMEOUT_MS := 6000
const MOM_FIRST := "Bonjour ! Tu es enfin réveillé ?"
const MOM_AGAIN := "Tu sors ? Profite de cette belle journée."
## Au pied de l'escalier (2, 4), le joueur se tourne vers Maman (7, 4).
const ARRIVAL_1F := [&"player_house_1f", Vector2i(2, 4), Vector2i.RIGHT]

var _boot: Boot
var _player: Player
var _titles: Array[Array] = []
## Arrivées : [map_id, case, orientation] relevées dans map_entered (avant toute image).
var _arrivals: Array[Array] = []


func before_each() -> void:
	_titles.clear()
	_arrivals.clear()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.zone_announced.connect(func(zone: String, region: String) -> void:
		_titles.append([zone, region]))
	add_child_autofree(_boot)
	_player = _boot.get_player()
	SceneRouter.map_entered.connect(_on_map_entered)


func after_each() -> void:
	if SceneRouter.map_entered.is_connected(_on_map_entered):
		SceneRouter.map_entered.disconnect(_on_map_entered)
	for action: StringName in DIRECTIONS.values():
		Input.action_release(action)
	Input.action_release(&"run")
	Input.action_release(&"interact")


func _on_map_entered(map: GameMap) -> void:
	_arrivals.append([map.map_id, _player.get_cell(), _player.get_facing()])


# --- Marche pilotée par les actions ---------------------------------------------------

## Marche en ligne droite jusqu'à [param goal] (même ligne ou même colonne), puis s'arrête.
func _walk_to(goal: Vector2i) -> void:
	var delta := goal - _player.get_cell()
	assert_true(delta.x == 0 or delta.y == 0, "segment droit vers %s" % goal)
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
		await wait_process_frames(1)
	Input.action_release(action)
	assert_eq(_player.get_cell(), goal, "arrivé en %s" % goal)


## Tient [param direction] jusqu'au passage suivant (porte, tapis, escalier), puis relâche
## une fois la nouvelle carte visible.
func _walk_through(direction: Vector2i) -> void:
	var action: StringName = DIRECTIONS[direction]
	var entered := _arrivals.size()
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	Input.action_press(action)
	while _arrivals.size() == entered and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
	Input.action_release(action)
	assert_eq(_arrivals.size(), entered + 1, "passage franchi en tenant %s" % direction)
	# Laisse finir un éventuel pas enchaîné après l'arrivée (doigt resté posé).
	await wait_until(func() -> bool: return not _player.is_moving(), 1.0)


## Appuie sur `interact` (une image) jusqu'à la fin du dialogue en cours ; renvoie les
## textes des pages vues.
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


## Chambre → escalier → rez-de-chaussée ; Maman parle d'elle-même, on l'écoute jusqu'au bout.
func _come_down_and_listen_to_mom() -> void:
	await _walk_to(Vector2i(3, 7))
	await _walk_to(Vector2i(6, 7))
	await _walk_through(Vector2i.DOWN)
	assert_eq(_last_arrival(), ARRIVAL_1F)
	var texts := await _finish_dialogue()
	assert_eq(texts.front() if not texts.is_empty() else "", MOM_FIRST)


func _last_arrival() -> Array:
	return _arrivals.back() if not _arrivals.is_empty() else []


# --- Tests ------------------------------------------------------------------------------

func test_bedroom_to_stairs_to_ground_floor_to_pallet_town() -> void:
	assert_eq(_boot.get_map().map_id, &"player_house_2f")
	assert_eq(_titles.size(), 0, "aucun titre au démarrage")
	# Chambre : (3, 4) → (3, 7) → (6, 7), puis descendre l'escalier (6, 9).
	await _walk_to(Vector2i(3, 7))
	await _walk_to(Vector2i(6, 7))
	await _walk_through(Vector2i.DOWN)
	assert_eq(_last_arrival(), ARRIVAL_1F)
	assert_eq(_titles.size(), 0, "aucun titre en intérieur")
	# Maman parle d'elle-même : le joueur ne bouge pas, même en tenant move_down.
	var runner := _boot.get_dialogue_runner()
	assert_true(runner.is_running(), "dialogue automatique lancé à l'arrivée")
	assert_eq(runner.get_dialogue_id(), &"mom")
	assert_false(_boot.get_hud().are_controls_visible(), "contrôles cachés")
	Input.action_press(&"move_down")
	await wait_seconds(0.6)
	assert_eq(_player.get_cell(), Vector2i(2, 4), "immobile pendant le dialogue")
	assert_false(_player.is_moving())
	assert_true(_boot.get_dialogue_box().is_open())
	assert_eq(_boot.get_dialogue_box().get_speaker_text(), "Maman")
	assert_eq(_boot.get_dialogue_box().get_text(), MOM_FIRST)
	Input.action_release(&"move_down")
	var texts := await _finish_dialogue()
	assert_eq(texts.size(), 2, "deux pages")
	assert_true(GameState.flags.has_flag(&"mom_greeted"))
	assert_true(_player.is_input_enabled(), "contrôle rendu")
	assert_true(_boot.get_hud().are_controls_visible())
	# Rez-de-chaussée : au pied de l'escalier → (2, 7) → (7, 7) → tapis (7, 8) → dehors.
	await _walk_to(Vector2i(2, 7))
	await _walk_to(Vector2i(7, 7))
	await _walk_through(Vector2i.DOWN)
	assert_eq(_last_arrival(), [&"pallet_town", Vector2i(36, 9), Vector2i.DOWN])
	assert_eq(_boot.get_map().map_id, &"pallet_town")
	assert_eq(_titles, [["Bourg Palette", "Kanto"]] as Array[Array], "titre affiché une fois")
	assert_true(_boot.get_hud().get_zone_title().is_showing())


func test_reentering_and_leaving_again_shows_no_second_title() -> void:
	# Même départ, sortie rapide par le même chemin.
	await _come_down_and_listen_to_mom()
	await _walk_to(Vector2i(2, 7))
	await _walk_to(Vector2i(7, 7))
	await _walk_through(Vector2i.DOWN)
	assert_eq(_titles.size(), 1)
	# Dehors : on s'écarte d'une case, puis on remonte dans la porte (36, 9).
	await _walk_to(Vector2i(36, 10))
	await _walk_through(Vector2i.UP)
	assert_eq(_last_arrival(), [&"player_house_1f", Vector2i(7, 8), Vector2i.UP])
	assert_false(_boot.get_hud().get_zone_title().is_showing(), "titre masqué en entrant")
	# Retour sur le tapis (un pas vers le haut a pu s'enchaîner), puis sortie.
	await _walk_to(Vector2i(7, 7))
	await _walk_to(Vector2i(7, 8))
	await _walk_through(Vector2i.DOWN)
	assert_eq(_last_arrival(), [&"pallet_town", Vector2i(36, 9), Vector2i.DOWN])
	assert_eq(_titles.size(), 1, "pas de second titre")
	assert_false(_boot.get_hud().get_zone_title().is_showing())


func test_mom_says_her_second_line_after_going_out_and_back() -> void:
	await _come_down_and_listen_to_mom()
	await _walk_to(Vector2i(2, 7))
	await _walk_to(Vector2i(7, 7))
	await _walk_through(Vector2i.DOWN)
	assert_eq(_boot.get_map().map_id, &"pallet_town")
	await _walk_to(Vector2i(36, 10))
	await _walk_through(Vector2i.UP)
	assert_eq(_boot.get_map().map_id, &"player_house_1f")
	assert_false(_boot.get_dialogue_runner().is_running(), "pas de relance à l'arrivée")
	# Face à Maman (7, 4) depuis (7, 5) : bouton contextuel « Parler ».
	await _walk_to(Vector2i(7, 5))
	await wait_process_frames(2)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target, "Maman devant le joueur")
	if target != null:
		assert_eq(target.kind, Interaction.Kind.TALK)
	assert_eq(_boot.get_hud().get_interact_button().get_verb(), &"talk")
	Input.action_press(&"interact")
	await wait_process_frames(1)
	Input.action_release(&"interact")
	await wait_process_frames(1)
	assert_true(_boot.get_dialogue_runner().is_running(), "E lance le dialogue")
	assert_eq(_boot.get_dialogue_box().get_text(), MOM_AGAIN)
	var texts := await _finish_dialogue()
	assert_eq(texts.front() if not texts.is_empty() else "", MOM_AGAIN)
