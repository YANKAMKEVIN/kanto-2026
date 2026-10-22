class_name InvisibleWallHint
extends Node2D
## Murs invisibles de l'Arène de Koga (jalon 23, T17 ; `jalon-23.md` §2.13, dossier 26 §10.1,
## N-15) : nœud `InvisibleWalls` posé dans la carte par `tools/build_fuchsia_gym.gd`.
##
## Les cases de [member cells] sont des cases **bloquées ordinaires** de la carte
## ([member GameMap.blocked_cells]) : ce nœud ne change rien au déplacement. Il ne fait que
## l'**indice au contact** : quand le joueur se cogne ([signal Player.bumped], une fois par
## poussée) contre une de ces cases, vibration courte ([Haptics]) et frémissement
## [constant SHIVER_TIME] s d'un panneau translucide sur la case (placeholder : un rectangle clair,
## comme une cloison de papier), puis plus rien. Aucun texte (texte 45), rien de permanent. Un mur
## ordinaire ne déclenche rien.
##
## Le joueur est trouvé par son groupe ([constant Player.GROUP]) dès qu'il entre dans la carte.

## Un indice a été montré sur [param cell] (tests).
signal hinted(cell: Vector2i)

## Taille d'une case (px).
const TILE: int = 96
## Durée du frémissement (s), dossier 26 §10.1.
const SHIVER_TIME: float = 0.4
## Vibration courte (ms) [D].
const HAPTIC_MS: int = 20
## Opacité maximale du panneau [D].
const PANEL_ALPHA: float = 0.35
## Amplitude du tremblement horizontal (px) [D].
const SHAKE_PX: float = 4.0
## Couleur du panneau (papier de dojo) [D].
const PANEL_COLOR := Color(0.96, 0.93, 0.85)

## Cases des murs invisibles (« i » de la grille).
@export var cells: Array[Vector2i] = []

var _player: Player
## Case et temps écoulé du frémissement en cours (temps ≥ SHIVER_TIME : aucun).
var _cell: Vector2i = Vector2i(-1, -1)
var _time: float = SHIVER_TIME


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		var found := get_tree().get_first_node_in_group(Player.GROUP) as Player
		if found != null:
			attach(found)
	if _time < SHIVER_TIME:
		_time = minf(_time + delta, SHIVER_TIME)
		queue_redraw()


## Branche le joueur (appelé tout seul ; les tests peuvent l'appeler).
func attach(player: Player) -> void:
	if is_instance_valid(_player) and _player.bumped.is_connected(_on_bumped):
		_player.bumped.disconnect(_on_bumped)
	_player = player
	if _player != null:
		_player.bumped.connect(_on_bumped)


## Vrai si [param cell] est un mur invisible.
func is_invisible_wall(cell: Vector2i) -> bool:
	return cells.has(cell)


## Vrai pendant le frémissement.
func is_shivering() -> bool:
	return _time < SHIVER_TIME


## Indice au contact de [param cell] : sans effet si ce n'est pas un mur invisible.
func hint(cell: Vector2i) -> bool:
	if not is_invisible_wall(cell):
		return false
	Haptics.vibrate(HAPTIC_MS)
	_cell = cell
	_time = 0.0
	queue_redraw()
	hinted.emit(cell)
	return true


func _on_bumped(direction: Vector2i) -> void:
	if is_instance_valid(_player) and _player.is_inside_tree() \
			and _player.get_parent() != null and is_ancestor_of_map(_player):
		hint(_player.get_cell() + direction)


## Le joueur est dans la même carte que ce nœud (il passe d'une carte à l'autre).
func is_ancestor_of_map(player: Node) -> bool:
	var map := get_parent()
	return map != null and map.is_ancestor_of(player)


func _draw() -> void:
	if _time >= SHIVER_TIME:
		return
	var t := _time / SHIVER_TIME
	var alpha := PANEL_ALPHA * sin(PI * t)
	var offset := sin(t * TAU * 4.0) * SHAKE_PX * (1.0 - t)
	var rect := Rect2(Vector2(_cell * TILE) + Vector2(offset + 6.0, -18.0),
		Vector2(TILE - 12.0, TILE + 12.0))
	draw_rect(rect, Color(PANEL_COLOR, alpha))
	draw_rect(rect, Color(PANEL_COLOR.darkened(0.4), alpha), false, 3.0)
	for i: int in range(1, 3):
		var x := rect.position.x + rect.size.x * i / 3.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y),
			Color(PANEL_COLOR.darkened(0.4), alpha * 0.7), 2.0)
