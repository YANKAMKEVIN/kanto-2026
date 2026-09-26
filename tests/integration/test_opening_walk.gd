extends GutTest
## Déroulé d'ouverture (jalon 2 §2.6, §4.2–4.4, T5) avec la vraie scène Boot et l'autoload
## SceneRouter, entrées injectées (Input.action_press) et images du moteur :
## chambre → escalier → rez-de-chaussée → tapis → Bourg Palette en (36, 9) face au sud,
## titre « Bourg Palette / Kanto » affiché une fois ; rentrer puis ressortir n'en affiche
## pas d'autre.

const DIRECTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up", Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
}
## Temps maximal d'un segment de marche ou d'une transition (secondes réelles).
const TIMEOUT_MS := 6000

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
	assert_eq(_last_arrival(), [&"player_house_1f", Vector2i(2, 4), Vector2i.DOWN])
	assert_eq(_titles.size(), 0, "aucun titre en intérieur")
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
	await _walk_to(Vector2i(3, 7))
	await _walk_to(Vector2i(6, 7))
	await _walk_through(Vector2i.DOWN)
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
