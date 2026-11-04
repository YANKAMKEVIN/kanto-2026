class_name CurrentGate
extends FlagGate
## Courants d'eau qui suivent les drapeaux d'histoire (Chapitre Johto, JOH1, `jalon-joh1.md`
## §2.2) : le chenal de la salle 2 de la grotte marine pousse vers le sud tant que l'acte 1 dure
## (`unless johto_team_returned`), puis se calme (la grotte se traverse dans les deux sens).
##
## Généralisation de l'état des étages des Îles Écume ([SeafoamFloorGate], qui lit ses huit
## drapeaux dans `seafoam.json`) : ici, une simple [FlagGate] sans dessin propre, dont les
## [member cells] (case → direction cardinale) sont posées sur la grille quand la porte est ouverte
## ([method FlagGate.is_open]) et effacées sinon ([method GridWorld.set_current] avec ZERO).
## Réglée comme toute porte de drapeaux : à l'arrivée sur la carte (avant le joueur), à chaque
## drapeau changé, à chaque reconstruction de la grille ([method GameMap.apply_flag_gates]).
## Les courants actifs sont dessinés comme aux Îles Écume (eau vive `ground_courant_01` qui défile
## dans le sens du flux, chevrons clairs) ; calmes, l'eau de la carte reste seule.
## Les courants **permanents** d'une carte n'ont pas besoin d'elle ([member GameMap.current_cells]).

## Case → direction du flux (cardinale).
@export var cells: Dictionary[Vector2i, Vector2i] = {}

const CURRENT_IMAGE: Texture2D = preload("res://assets/world/ground/ground_courant_01.png")
const CURRENT_SPEED: float = 120.0
const CURRENT_ALPHA: float = 0.8
const CHEVRON_COLOR := Color(0.92, 0.98, 1.0, 0.75)

var _flags: StoryFlags = null
## Courants dessinés (actifs) : case → direction.
var _drawn: Dictionary[Vector2i, Vector2i] = {}
var _time: float = 0.0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _process(delta: float) -> void:
	if _drawn.is_empty():
		return
	_time = fmod(_time + delta, 3600.0)
	queue_redraw()


## Mémorise les drapeaux ; la porte reste visible (c'est le dessin qui suit l'état).
func apply(flags: StoryFlags) -> void:
	_flags = flags
	visible = true


## Vrai si les courants sont actifs avec les drapeaux connus.
func is_active() -> bool:
	return is_open(_current_flags())


## Pose ou efface les courants de [member cells] dans [param grid] selon les drapeaux.
func apply_to_grid(grid: GridWorld) -> void:
	if grid == null:
		return
	var active := is_active()
	for cell: Vector2i in cells:
		grid.set_current(cell, cells[cell] if active else Vector2i.ZERO)
	_drawn = cells.duplicate() if active else ({} as Dictionary[Vector2i, Vector2i])
	queue_redraw()


## Cases des courants actifs (tests, outils).
func active_cells() -> Dictionary[Vector2i, Vector2i]:
	return _drawn.duplicate()


func _draw() -> void:
	var tile := float(Grid.TILE_SIZE)
	var half := tile / 2.0
	for cell: Vector2i in _drawn:
		var center := (Vector2(cell) + Vector2(0.5, 0.5)) * tile - position
		var dir := Vector2(_drawn[cell])
		var across := Vector2(-dir.y, dir.x) * -1.0
		var source := Rect2(center.dot(across) - half, center.dot(dir) - half - _time * CURRENT_SPEED,
			tile, tile)
		draw_set_transform(center, dir.angle() - PI / 2.0)
		draw_texture_rect_region(CURRENT_IMAGE, Rect2(-half, -half, tile, tile), source,
			Color(1.0, 1.0, 1.0, CURRENT_ALPHA))
		draw_set_transform(Vector2.ZERO)
		var side := Vector2(-dir.y, dir.x)
		for offset: float in [-18.0, 14.0]:
			var tip := center + dir * (offset + 14.0)
			draw_polyline(PackedVector2Array([tip - dir * 16.0 + side * 16.0, tip,
				tip - dir * 16.0 - side * 16.0]), CHEVRON_COLOR, 6.0)


func _current_flags() -> StoryFlags:
	if _flags != null:
		return _flags
	var tree := Engine.get_main_loop() as SceneTree
	var game_state: Node = tree.root.get_node_or_null(^"GameState") if tree != null else null
	if game_state != null:
		return game_state.get(&"flags") as StoryFlags
	return null
