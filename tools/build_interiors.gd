extends SceneTree
## Construit les cartes d'intérieur du jalon 2 (docs/tech/jalon-02.md §4.3 à §4.7) :
##   player_house_2f, player_house_1f, rival_house, oak_lab
##
##   godot --headless --path . -s res://tools/build_interiors.gd
##   godot --headless --path . --import
##
## Chaque pièce est décrite en tables : sol, murs, tapis (Detail), props, spawns, warps,
## points d'examen (`interactables`, facultatif ; jalon-03.md §3.2), déclencheurs de scène
## (`triggers`, facultatif ; jalon-04.md §13.6 : tapis de sortie du labo).
## Coordonnées en cases (x vers l'est, y vers le sud), rectangles inclusifs
## [x0, y0, x1, y1]. Props : ancre = case en bas à gauche (voir §4.1).
## Les tapis (rug_*) sont enfants du calque `Detail` : dessinés sur le sol, sous le joueur.
## Deux gabarits de murs :
##   BACK : mur du fond sur les rangées 0–1, pas de murs latéraux (vide sombre en coupe) ;
##   BOX  : murs sur les quatre côtés (fond 0–1, colonnes 0 et W−1, rangée H−1),
##          sauf les cases listées dans `openings` (escalier qui descend).
## Variantes de parquet tirées avec une graine fixe : cartes reproductibles.

const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/interior/"
const SEED: int = 2026
## Warp.Trigger (les scripts d'outil lisent les enums par valeur).
const STEP_ON: int = 0
const PUSH: int = 1
## Interaction.Kind (valeurs) : verbe des points d'examen.
const EXAMINE: int = 1
const BACK: String = "back"
const BOX: String = "box"

var _tiles: GDScript
var _rng := RandomNumberGenerator.new()
var _scenes: Dictionary = {}


func _init() -> void:
	_tiles = load("res://game/world/interior_tiles.gd")
	for room: Dictionary in _rooms():
		_build(room)
	quit()


# --- Plans des pièces --------------------------------------------------------------

func _rooms() -> Array[Dictionary]:
	return [_player_house_2f(), _player_house_1f(), _rival_house(), _oak_lab()]


## §4.3 — chambre du joueur, 14 × 10, murs sur 4 côtés, escalier ↓ en bas au centre.
## Référence : docs/design/reference/chambre-joueur-v1.webp.
func _player_house_2f() -> Dictionary:
	return {
		"id": &"player_house_2f", "node": "PlayerHouse2F", "size": Vector2i(14, 10),
		"floor": "FLOOR_WOOD", "wall": "WALL_HOUSE", "walls": BOX,
		"openings": [Vector2i(6, 9), Vector2i(7, 9)],
		"ground": [["STAIRS_DOWN", [6, 9, 7, 9]]],
		"detail": [],
		# Tête du lit (sprite 2 × 3, empreinte 2 × 2) : sans cela, poche fermée en (1..2, 2).
		"blocked": [Vector2i(1, 2), Vector2i(2, 2)],
		"props": [
			["poster", [2, 1], "PosterMountain"],
			["poster", [3, 1], "PosterPokeball"],
			["window_curtains", [6, 1], "Window"],
			["wall_map", [11, 1], "KantoMap"],
			["bed", [1, 4], "Bed"],
			["nightstand_lamp", [3, 2], "Nightstand"],
			["small_shelf", [4, 2], "SmallShelf"],
			["laptop_desk", [6, 2], "Desk"],
			["desk_chair", [7, 3], "DeskChair"],
			["tall_bookshelf", [9, 3], "Bookshelf"],
			["rug_pokeball", [5, 6], "RugPokeball"],
			["travel_bag", [1, 5], "TravelBag"],
			["tv_console_side", [12, 5], "TvConsole"],
			["plant", [1, 7], "PlantWest"],
			["plant", [12, 6], "PlantEast"],
			["door_side", [13, 7], "SideDoor"],
			["low_cabinet", [1, 8], "LowCabinet"],
			["rug_check", [6, 8], "RugStairs"],
			["low_cabinet_small", [9, 8], "CapCabinet"],
			["pokeball_crate", [10, 8], "PokeballCrate"],
		],
		"spawns": {"start": Vector2i(3, 4), "stairs": Vector2i(6, 8)},
		"warps": [
			["StairsDownW", Vector2i(6, 9), STEP_ON, Vector2i.DOWN,
				&"player_house_1f", &"stairs"],
			["StairsDownE", Vector2i(7, 9), STEP_ON, Vector2i.DOWN,
				&"player_house_1f", &"stairs"],
		],
	}


## §4.4 — rez-de-chaussée du joueur, 14 × 10, murs sur 4 côtés, porte dans le mur bas.
## Référence : docs/design/reference/ouverture-storyboard-v1.webp, cases 3 et 4.
func _player_house_1f() -> Dictionary:
	return {
		"id": &"player_house_1f", "node": "PlayerHouse1F", "size": Vector2i(14, 10),
		"floor": "FLOOR_WOOD", "wall": "WALL_HOUSE", "walls": BOX,
		"openings": [],
		"ground": [["STAIRS_UP", [1, 2, 2, 3]]],
		"detail": [["MAT", [7, 8, 7, 8]]],
		"blocked": [],
		"props": [
			["window", [5, 1], "WindowKitchen"],
			["window", [11, 1], "WindowLiving"],
			["stairs_up_side", [1, 3], "Stairs"],
			["fridge", [3, 2], "Fridge"],
			["kitchen_counter", [4, 2], "Kitchen"],
			["rug_plaid", [2, 6], "RugPlaid"],
			["dining_table", [3, 5], "DiningTable"],
			# Jalon 3A : petit-déjeuner posé sur la table (après elle : dessiné dessus).
			["breakfast", [3, 5], "Breakfast"],
			["sofa", [9, 4], "Sofa"],
			["rug_living", [9, 7], "RugLiving"],
			["coffee_table", [9, 6], "CoffeeTable"],
			["tv_console_side", [12, 6], "TvConsole"],
			["plant", [1, 7], "PlantWest"],
			["plant", [12, 7], "PlantEast"],
			["low_cabinet", [1, 8], "LowCabinet"],
			["coat_rack", [6, 8], "CoatRack"],
			["dresser_pokeball", [9, 8], "Dresser"],
			["front_door", [7, 9], "FrontDoor"],
		],
		"spawns": {"entrance": Vector2i(7, 8), "stairs": Vector2i(2, 4)},
		# Jalon 3A (§3.2) : la table à manger (3..5, 4..5) s'examine de tous côtés.
		"interactables": [
			["BreakfastTable", Vector2i(3, 5), Vector2i(3, 2), Vector2i.ZERO,
				"breakfast_table"],
		],
		"warps": [
			["StairsUpW", Vector2i(1, 3), STEP_ON, Vector2i.UP, &"player_house_2f", &"stairs"],
			["StairsUpE", Vector2i(2, 3), STEP_ON, Vector2i.UP, &"player_house_2f", &"stairs"],
			["Exit", Vector2i(7, 8), PUSH, Vector2i.DOWN, &"pallet_town", &"player_house_door"],
		],
	}


## §4.5 — maison du rival, un seul niveau, 18 × 11, murs sur 4 côtés et cloisons.
## Référence : docs/design/reference/maison-rival-v1.webp (sans l'Évoli, erreur de la
## référence). Écarts au plan (±1 case) :
## - fenêtre de la cuisine en (3..4, 1) : la hotte (5, 1..2) la masquait en (4..5, 1) ;
## - porte-manteau en (12, 7), à la place du bout de cloison de la salle de bain : en (11, 7)
##   il fermait le recoin (11, 8) et toute la salle de bain (poche inaccessible) ;
## - bureau d'angle en L (11..12, 2) + (11, 3) : la chaise (12, 3) occupe le coin du L.
func _rival_house() -> Dictionary:
	var props: Array = [
		["window", [3, 1], "WindowKitchen"],
		["window", [13, 1], "WindowBedroom"],
		["rival_posters", [15, 1], "Posters"],
		["fridge", [1, 2], "Fridge"],
		["kitchen_counter", [2, 2], "Kitchen"],
		["range_hood_stove", [5, 2], "Stove"],
		["stairs_up_wide", [7, 4], "Stairs"],
		["low_cabinet_small", [8, 5], "UnderStairsCabinet"],
		["dining_table", [2, 5], "DiningTable"],
		["wall_tv_side", [1, 7], "WallTv"],
		["rug_living_blue", [2, 9], "RugLiving"],
		["sofa", [3, 7], "Sofa"],
		["coffee_table", [3, 8], "CoffeeTable"],
		["plant", [1, 9], "PlantLivingWest"],
		["plant", [6, 9], "PlantLivingEast"],
		["corner_desk_pc", [11, 3], "CornerDesk"],
		["gamer_chair", [12, 3], "GamerChair"],
		["dresser", [13, 2], "Dresser"],
		["rug_bedroom_grey", [12, 5], "RugBedroom"],
		["bed_pokeball", [15, 4], "Bed"],
		# Jalon 3A (Q3) : carte de Kanto dépliée, sac ouvert et affaires sur le lit.
		["bed_items", [15, 4], "BedItems"],
		["nightstand_bag", [16, 5], "Nightstand"],
		["coat_rack", [12, 7], "CoatRack"],
		["shoe_rack", [11, 9], "ShoeRack"],
		["bathroom_sink", [13, 7], "BathroomSink"],
		["shower", [16, 8], "Shower"],
		["rug_bath", [13, 9], "RugBath"],
		["plant", [12, 9], "PlantBathroom"],  # hors du bouton courir (coin bas-droit)
		["front_door", [9, 10], "FrontDoor"],
	]
	# Cloisons : chambre (10, 2..4), salle de bain (12..16, 6), murets du couloir d'entrée.
	var partitions: Array[Vector2i] = []
	for y: int in range(2, 5):
		partitions.append(Vector2i(10, y))
	for y: int in range(7, 10):
		partitions.append(Vector2i(7, y))
		partitions.append(Vector2i(10, y))
	for cell: Vector2i in partitions:
		props.append(["partition", [cell.x, cell.y], "Partition_%d_%d" % [cell.x, cell.y]])
	for x: int in range(12, 17):
		props.append(["partition_h", [x, 6], "Partition_%d_6" % x])
	return {
		"id": &"rival_house", "node": "RivalHouse", "size": Vector2i(18, 11),
		"floor": "FLOOR_WOOD", "wall": "WALL_HOUSE", "walls": BOX,
		"openings": [],
		"ground": [],
		"detail": [["MAT", [9, 9, 9, 9]]],
		"blocked": [],
		"props": props,
		"spawns": {"entrance": Vector2i(9, 9)},
		"warps": [
			["Exit", Vector2i(9, 9), PUSH, Vector2i.DOWN, &"pallet_town", &"rival_house_door"],
		],
		# Jalon 3A (§3.2, Q3) : la carte de Kanto sur le lit (15..16, 2..4), de tous côtés.
		"interactables": [
			["KantoMap", Vector2i(15, 4), Vector2i(2, 3), Vector2i.ZERO, "rival_kanto_map"],
		],
	}


## §4.7 — laboratoire de Chen, 16 × 11, murs sur 4 côtés : tient dans l'écran.
## Référence : docs/design/reference/labo-chen-v1.png. Écarts au plan (±1 case) :
## - décors muraux (carte de Kanto, grande fenêtre, affiche) sur la rangée haute du mur
##   (y 0) : les meubles hauts de la rangée 2 débordent sur la rangée 1 ;
## - table des starters en (10..12, 4..5) : en (11..13) elle fermait la case (13, 3) ;
## - canapé en (1, 6..7) : en (2, 6..7) il fermait les cases (1, 6..7).
func _oak_lab() -> Dictionary:
	return {
		"id": &"oak_lab", "node": "OakLab", "size": Vector2i(16, 11),
		# Tapis Poké Ball (rug_pokeball en (6, 7), 4 × 3 cases) : arène du combat (§14.4).
		"battle_arena": Rect2i(6, 5, 4, 3),
		"floor": "FLOOR_LAB", "wall": "WALL_LAB", "walls": BOX,
		"openings": [],
		"ground": [],
		"detail": [["MAT", [7, 9, 7, 9]]],
		"blocked": [],
		"props": [
			["wall_map", [4, 0], "KantoMap"],
			["window_lab", [6, 0], "Window"],
			["pokemon_poster", [10, 0], "Poster"],
			["aquarium", [1, 2], "Aquarium"],
			["incubator", [2, 3], "Incubator"],
			["lab_computers", [4, 2], "Computers"],
			["oak_desk", [7, 2], "OakDesk"],
			["desk_chair", [8, 3], "DeskChair"],
			["file_cabinet", [10, 2], "FileCabinet"],
			["tall_bookshelf", [11, 3], "Bookshelf"],
			["fridge", [13, 2], "Fridge"],
			["display_case", [14, 4], "DisplayCase"],
			["long_counter", [1, 5], "LongCounter"],
			["rug_pokeball", [6, 7], "RugPokeball"],
			["rug_red", [2, 8], "RugRed"],
			["starter_table", [10, 5], "StarterTable"],
			["sofa_side", [1, 7], "Sofa"],
			["coffee_table", [3, 7], "CoffeeTable"],
			["lab_bench", [11, 8], "Bench"],
			["wall_screen_side", [14, 7], "WallScreen"],
			["stairs_deco", [1, 9], "Stairs"],
			["plant", [6, 8], "PlantRug"],
			["stool", [12, 7], "Stool"],
			["plant", [4, 9], "PlantStairs"],
			["plant", [9, 9], "PlantEntrance"],
			["plant", [14, 8], "PlantCorner"],  # hors du bouton courir (coin bas-droit)
			["lab_doorway", [7, 10], "Doorway"],
		],
		"spawns": {"entrance": Vector2i(7, 9)},
		"warps": [
			["Exit", Vector2i(7, 9), PUSH, Vector2i.DOWN, &"pallet_town", &"oak_lab_door"],
		],
		# Sortie empêchée pendant le choix du starter (jalon-04.md §13.6) : on arrive sur le
		# tapis de trois côtés, la scène (oak_lab_exit) passe avant la poussée du warp PUSH.
		"triggers": [
			["LabExit", Vector2i(7, 9), Vector2i.ONE, Vector2i.ZERO, &"oak_lab_exit"],
		],
	}


# --- Construction ------------------------------------------------------------------

func _build(room: Dictionary) -> void:
	_rng.seed = SEED + String(room["id"]).hash()
	var size: Vector2i = room["size"]
	var root := Node2D.new()
	root.name = room["node"]
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", room["id"])
	root.set(&"display_name", "Bourg Palette")
	root.set(&"region", "Kanto")
	root.set(&"size", size)
	if room.has("battle_arena"):
		root.set(&"battle_arena", room["battle_arena"])
	root.set(&"interior", true)
	var blocked: Array[Vector2i] = []
	blocked.assign(room["blocked"])
	root.set(&"blocked_cells", blocked)
	var tileset: TileSet = load(_tiles.TILESET_PATH)
	var ground := _add_layer(root, "Ground", tileset)
	var detail := _add_layer(root, "Detail", tileset)
	var obstacles := _add_layer(root, "Obstacles", tileset)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)

	var walls := _wall_cells(room)
	_paint_floor(ground, room, walls)
	_paint_walls(obstacles, room, walls)
	for entry: Array in room["ground"]:
		_paint_rect(ground, entry[0], entry[1], 0)
	for entry: Array in room["detail"]:
		_paint_rect(detail, entry[0], entry[1], entry[2] if entry.size() > 2 else 0)
	for entry: Array in room["props"]:
		# Tapis sous `Detail` : au-dessus du sol, sous les entités (pas de y-sort).
		var parent: Node = detail if String(entry[0]).begins_with("rug_") else entities
		_add_prop(root, parent, entry[0], Vector2i(entry[1][0], entry[1][1]), entry[2])
	var spawns: Dictionary = room["spawns"]
	for spawn_name: String in spawns:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _world(spawns[spawn_name])
		_attach(root, root.get_node(^"Spawns"), marker)
	var warp_script: GDScript = load("res://game/world/warp_point.gd")
	for warp: Array in room["warps"]:
		var point := Marker2D.new()
		point.set_script(warp_script)
		point.name = warp[0]
		point.position = _world(warp[1])
		point.set(&"trigger", warp[2])
		point.set(&"direction", warp[3])
		point.set(&"target_map", warp[4])
		point.set(&"target_spawn", warp[5])
		_attach(root, root.get_node(^"Warps"), point)
	_add_interactables(root, room.get("interactables", []))
	_add_triggers(root, room.get("triggers", []))

	var path := MAPS_DIR + String(room["id"]) + ".tscn"
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (%d entités, %d warps)" % [room["id"], error_string(err),
		entities.get_child_count(), (room["warps"] as Array).size()])
	root.free()


## Points d'examen : [nœud, ancre, size, facing, dialogue, verbe]. Ancre = case en bas à
## gauche ; size en cases ; facing ZERO = de tous côtés ; verbe = Interaction.Kind (valeur).
func _add_interactables(root: Node, entries: Array) -> void:
	var point_script: GDScript = load("res://game/world/interactions/interact_point.gd")
	for entry: Array in entries:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"facing", entry[3])
		point.set(&"dialogue_id", StringName(entry[4]))
		point.set(&"kind", entry[5] if entry.size() > 5 else EXAMINE)
		_attach(root, root.get_node(^"Interactables"), point)


## Déclencheurs de scène : [nœud, ancre, size, direction, scène]. Ancre = case en bas à
## gauche ; direction ZERO = pas venu de n'importe quel côté.
func _add_triggers(root: Node, entries: Array) -> void:
	var point_script: GDScript = load("res://game/world/triggers/event_trigger_point.gd")
	for entry: Array in entries:
		var point := Marker2D.new()
		point.set_script(point_script)
		point.name = entry[0]
		point.position = _world(entry[1])
		point.set(&"size", entry[2])
		point.set(&"direction", entry[3])
		point.set(&"cutscene_id", StringName(entry[4]))
		_attach(root, root.get_node(^"Triggers"), point)


## Cases de mur selon le gabarit (dictionnaire case → vrai).
func _wall_cells(room: Dictionary) -> Dictionary:
	var size: Vector2i = room["size"]
	var openings: Array = room["openings"]
	var cells := {}
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var wall := y <= 1
			if room["walls"] == BOX:
				wall = wall or x == 0 or x == size.x - 1 or y == size.y - 1
			if wall and not cell in openings:
				cells[cell] = true
	return cells


func _paint_floor(layer: TileMapLayer, room: Dictionary, walls: Dictionary) -> void:
	var kind := _kind(room["floor"])
	var size: Vector2i = room["size"]
	for y: int in size.y:
		for x: int in size.x:
			if walls.has(Vector2i(x, y)):
				continue
			var variant := _rng.randi_range(0, _tiles.variant_count(kind) - 1)
			layer.set_cell(Vector2i(x, y), _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))


## Murs : rangée basse du mur du fond avec plinthe, le reste en partie haute.
func _paint_walls(layer: TileMapLayer, room: Dictionary, walls: Dictionary) -> void:
	var kind := _kind(room["wall"])
	for cell: Vector2i in walls:
		var variant: int = _tiles.WALL_BASEBOARD if cell.y == 1 else _tiles.WALL_UPPER
		layer.set_cell(cell, _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))


func _paint_rect(layer: TileMapLayer, kind_name: String, r: Array, variant: int) -> void:
	var kind := _kind(kind_name)
	for y: int in range(r[1], r[3] + 1):
		for x: int in range(r[0], r[2] + 1):
			layer.set_cell(Vector2i(x, y), _tiles.SOURCE_ID, _tiles.atlas_coords(kind, variant))


func _kind(kind_name: String) -> int:
	return _tiles.Kind[kind_name]


func _world(cell: Vector2i) -> Vector2:
	var tile: int = 96
	return Vector2(cell.x * tile + tile / 2.0, (cell.y + 1) * tile)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _add_layer(root: Node, layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	_attach(root, root, layer)
	return layer


func _scene(scene_name: String) -> PackedScene:
	if not _scenes.has(scene_name):
		_scenes[scene_name] = load(PROPS_DIR + scene_name + ".tscn")
	return _scenes[scene_name]


func _add_prop(root: Node, entities: Node, scene_name: String, cell: Vector2i,
		node_name: String) -> void:
	# État d'édition : pack() ne garde que la position, l'empreinte reste dans la scène.
	var prop := _scene(scene_name).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.name = node_name
	prop.position = _world(cell)
	_attach(root, entities, prop)
