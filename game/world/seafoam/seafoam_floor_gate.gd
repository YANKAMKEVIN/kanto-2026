class_name SeafoamFloorGate
extends FlagGate
## État d'un étage des Îles Écume posé sur la grille de la carte (jalon 24, T15 ; dossier 27
## §7.1, §7.4) : un [FlagGate] sans dessin, réglé par [method GameMap.apply_flag_gates] à
## l'arrivée (avant le joueur) et à chaque drapeau changé, puis à chaque reconstruction de la
## grille.
## - **Niveaux de sol** (collisions par paires de Rouge/Bleu) : [member low_cells],
##   [member high_cells], [member stairs_cells] ([method GridWorld.set_level]) ;
## - **courants** : actifs ou calmes selon les 8 drapeaux ([method SeafoamState.Floor.apply_to]).
## Sans drapeaux connus (grille construite avant l'arrivée), ceux de [code]GameState[/code].

## Étage (identifiant de la carte) dans `data/world/seafoam.json`.
@export var floor_id: StringName = &""
@export var low_cells: Array[Vector2i] = []
@export var high_cells: Array[Vector2i] = []
@export var stairs_cells: Array[Vector2i] = []

static var _state: SeafoamState = null

var _flags: StoryFlags = null


## Données des étages (chargées une fois).
static func state() -> SeafoamState:
	if _state == null:
		_state = SeafoamState.new()
		if not _state.load_file():
			push_error("SeafoamFloorGate : %s" % ", ".join(_state.get_errors()))
	return _state


func apply(flags: StoryFlags) -> void:
	_flags = flags
	visible = true


func apply_to_grid(grid: GridWorld) -> void:
	if grid == null:
		return
	for cell: Vector2i in low_cells:
		grid.set_level(cell, GridWorld.Level.LOW)
	for cell: Vector2i in high_cells:
		grid.set_level(cell, GridWorld.Level.HIGH)
	for cell: Vector2i in stairs_cells:
		grid.set_level(cell, GridWorld.Level.STAIRS)
	var floor_state := state().floor_state(floor_id, _current_flags())
	if floor_state != null:
		floor_state.apply_to(grid)


## État de l'étage avec les drapeaux connus (null : étage inconnu).
func floor_state() -> SeafoamState.Floor:
	return state().floor_state(floor_id, _current_flags())


func _current_flags() -> StoryFlags:
	if _flags != null:
		return _flags
	var tree := Engine.get_main_loop() as SceneTree
	var game_state: Node = tree.root.get_node_or_null(^"GameState") if tree != null else null
	if game_state != null:
		return game_state.get(&"flags") as StoryFlags
	return null
