extends SceneTree
## Construit les six cartes de la Tour Radio de Doublonville (Chapitre Johto, jalon JOH5,
## `docs/tech/jalon-joh5.md` §2.1) : `goldenrod_radio_tower_1f` à `_5f` d'après
## `tools/plans/radio_tower_1f.txt` … `radio_tower_5f.txt` (grilles validées le 2026-11-02, elles
## font foi) et la cabine `goldenrod_radio_tower_elevator` sur la grille de la cabine de la Sylphe
## (`sylphe_ascenseur.txt`) [D].
##
##   godot --headless --path . -s res://tools/build_joh5_radio_tower.gd   (code 2 : masques écrits,
##   godot --headless --path . --import                                  importer puis relancer)
##
## Modèle : `tools/build_silph_co.gd` (même légende de grille). Image peinte (passe d'ambiance du
## lot 2, `tools/art/joh_ambiance_lot2.py`, vues `tour-radio-*-vue-generale-v1.png`) : carrelage et
## mobilier propres à la Tour ([constant FURNITURE] : comptoir `c`, rayonnages `r`, pupitres `p`,
## tables), vitres `V` en parois de verre translucides ([method _place_glass]) et baie sur la ville
## au 5F ; murs, escaliers et plantes de la Sylphe. La grille est relue pour l'image (`S` → mur,
## `c r p V` → mobilier, `user://joh5_plans/`), les cases bloquées restent celles de la vraie grille.
## - `spawn` : Marker2D de `Spawns` (une case de la position = son nom ; plusieurs : `_1`, `_2`).
## - `escalier` : [WarpPoint] STEP_ON vers `vers=`, arrivée tournée comme le point cible.
## - `warp` (1F) : sortie PUSH ↓ vers `goldenrod_city:retour_tour_radio` (« Doublonville » à venir
##   tant que la carte du JOH3 manque).
## - `ascenseur` : porte STEP_ON vers la cabine, ouverte **avec `johto_cenere_defeated`** ;
##   `examen_ascenseur` : point EXAMINER (scène `goldenrod_radio_elevator`) tant qu'elle est en panne.
## - `declencheur` : [EventTriggerPoint] sur toutes les cases de la position (scène du plan §2.3).
## - `porte_cle` : [FlagGate] bloquante (fermée tant que son drapeau d'ouverture est bas, panneau
##   sombre provisoire) et un point EXAMINER sur la case (scène de la porte).
## - `examen`, `decor`, `cache` : points EXAMINER. Dresseurs, PNJ et objets visibles : données
##   (`data/npcs/goldenrod_radio_tower_<n>f.json`, `tools/gen_joh5_data.py`).
## Cartes intérieures (`interior = true`, `interiors.json`) [D] ; lumière `office` ; titre
## « Tour Radio ».

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const Kit := preload("res://tools/cave_map_kit.gd")
const ModuleWalls := preload("res://tools/module_walls.gd")
const TILE: int = 96
const STEP_ON: int = 0
const PUSH: int = 1
const KIND_EXAMINE: int = 1
const INTERIORS: String = "res://assets/world/interiors/"
const OUT_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const TMP_PLANS: String = "user://joh5_plans/"
const CAR_SHELL_PATH: String = INTERIORS + "int_silph_co_elevator_coque.png"
const GROUND_FLOOR: String = "res://assets/world/ground/ground_carrelage_radio_01.png"
const STUDIO_FLOOR: String = "res://assets/world/ground/ground_moquette_sylphe_01.png"
const GROUND_MASS: String = "res://assets/world/ground/ground_masse_batiment_01.png"
const BORDER_COLOR := Color(0.47, 0.48, 0.51)
const NO_RUBBLE_MARK: String = "~"
const WALL_MARK: String = "#"
const WALL_PREFIX: String = "relief_mur_sylphe"
## Caractères de la grille relus pour l'image provisoire : mobilier ou mur.
const AS_FURNITURE: String = "crpV"
const AS_WALL: String = "S"
const PLANT: String = "int_plante_sylphe_01"
## Mobilier peint, par étage : [objet, pied (cases), nœud, échelle] ; posé sans emprise sur les
## cases bloquées de la grille. Les `M` d'une seule case sont des plantes.
const FURNITURE: Dictionary = {
	1: [["int_comptoir_radio_01", Vector2(12, 6), "Comptoir", Vector2.ONE],
		["prop_banc_01", Vector2(7, 10), "Banc0", Vector2.ONE],
		["prop_banc_01", Vector2(17, 10), "Banc1", Vector2.ONE]],
	2: [["int_table_studio_01", Vector2(9, 5), "TableStudio0", Vector2(0.9, 0.9)],
		["int_table_studio_01", Vector2(15, 5), "TableStudio1", Vector2(0.9, 0.9)],
		["int_pupitre_orateur_radio_01", Vector2(12, 15), "PupitreOrateur", Vector2.ONE]],
	3: [["int_rayonnage_archives_01", Vector2(6, 5), "Rayonnage0", Vector2.ONE],
		["int_rayonnage_archives_01", Vector2(18, 4), "Rayonnage1", Vector2(1.0, 0.62)],
		["int_rayonnage_archives_01", Vector2(17, 7), "Rayonnage2", Vector2(0.75, 0.62)],
		["int_rayonnage_archives_01", Vector2(8, 9), "Rayonnage3", Vector2.ONE],
		["int_rayonnage_archives_01", Vector2(6, 13), "Rayonnage4", Vector2.ONE]],
	4: [["int_mur_ecrans_radio_01", Vector2(12, 2), "MurEcrans", Vector2.ONE],
		["int_pupitre_regie_01", Vector2(8.5, 6), "Regie0", Vector2.ONE],
		["int_pupitre_regie_01", Vector2(15.5, 6), "Regie1", Vector2.ONE],
		["int_pupitre_regie_01", Vector2(8.5, 11), "Regie2", Vector2.ONE],
		["int_pupitre_regie_01", Vector2(15.5, 11), "Regie3", Vector2.ONE]],
	5: [["int_bureau_chen_01", Vector2(3, 3), "BureauDirecteur", Vector2(0.72, 0.72)],
		["int_table_diffusion_01", Vector2(12, 10), "TableDiffusion", Vector2(1.0, 0.9)]],
}
## Sols de studio, par étage (cases) ; teinte de la moquette [D].
const STUDIOS: Dictionary = {2: [Rect2i(7, 2, 4, 9), Rect2i(13, 2, 4, 9)]}
const STUDIO_TINT := Color(0.62, 0.68, 0.8)
const GLASS_H: String = "int_vitre_studio_h_01"
const GLASS_V: String = "int_vitre_studio_v_01"
const GLASS_ALPHA: float = 0.55
## Largeur d'affichage de la paroi vue par la tranche.
const GLASS_V_SCALE: float = 2.0
## Baie sur la ville du 5F : rangée, module, hauteur étirée à une rangée [D].
const BAY: String = "int_baie_ville_01"
const BAY_FLOOR: int = 5
const BAY_ROW: int = 14
const BAY_SCALE_Y: float = 1.5
const LOGO: String = "int_logo_radio_01"
const LOGO_FOOT := Vector2(1152.0, 97.0)
const LOGO_SCALE: float = 0.84
const ENTRANCE: String = "int_porte_entree_radio_01"
const ENTRANCE_FOOT := Vector2(12.0, 16.0)
const ENTRANCE_SCALE: float = 0.72
const LOCKED_DOOR: String = "int_porte_sylphe_v_01"
const STAIRS_UP: String = "int_escalier_sylphe_monte_01"
const STAIRS_DOWN: String = "int_escalier_sylphe_descend_01"
const ELEVATOR_DOOR: String = "int_porte_ascenseur_sylphe_01"
const DOOR_SILL: String = "decal_seuil_sylphe_01"
const DOORMAT: String = "int_paillasson_sylphe_01"
const DISPLAY_NAME: String = "Tour Radio"
const LIGHT_PROFILE: StringName = &"office"
const CAR_MAP: StringName = &"goldenrod_radio_tower_elevator"
const CAR_ENTRANCE: StringName = &"entrance"
const CAR_EXIT_MAP: StringName = &"goldenrod_radio_tower_1f"
const ELEVATOR_SPAWN: StringName = &"from_elevator"
const ELEVATOR_FLAG: StringName = &"johto_cenere_defeated"
const PANEL_DIALOGUE: StringName = &"elevator_panel"
const EXIT_MAP: StringName = &"goldenrod_city"
const EXIT_SPAWN: StringName = &"retour_tour_radio"
const EXIT_COMING_SOON: String = "Doublonville"
## Scène de chaque déclencheur (plan §2.3).
const TRIGGER_SCENES: Dictionary = {
	"scene_impostor": &"goldenrod_radio_impostor",
	"scene_sortie": &"goldenrod_radio_exit",
	"scene_cenere": &"goldenrod_radio_cenere",
	"scene_bureau": &"goldenrod_radio_office",
}
## Dialogue (ou scène) de chaque point d'examen, par identifiant de grille.
const EXAMINE_DIALOGUES: Dictionary = {
	"examen_ascenseur": &"goldenrod_radio_elevator",
	"pupitre_diffusion": &"goldenrod_radio_console",
	"escalier_secours": &"goldenrod_radio_emergency_stairs",
	"haut_parleur": &"goldenrod_radio_loudspeaker",
}
## Portes fermées : dialogue (ou scène) d'OUVRIR.
const DOOR_DIALOGUES: Dictionary = {
	"porte_reserve": &"goldenrod_radio_reserve_door",
	"porte_bureau": &"goldenrod_radio_office_locked",
}

var _root: Node2D
var _map_id: StringName
var _plans: Dictionary[StringName, PlanGrid] = {}
var _maps: Dictionary[StringName, Array] = {}
var _errors: int = 0
var _masks_written: int = 0
var _kit: Object


func _init() -> void:
	for n: int in range(1, 6):
		_maps[StringName("goldenrod_radio_tower_%df" % n)] = ["GoldenrodRadioTower%dF" % n,
			"radio_tower_%df" % n]
	_maps[CAR_MAP] = ["GoldenrodRadioTowerElevator", "sylphe_ascenseur"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP_PLANS))
	for map_id: StringName in _maps:
		var plan := PlanGrid.new()
		var path := "res://tools/plans/%s.txt" % _maps[map_id][1]
		if not plan.load_file(path):
			push_error("build_joh5_radio_tower : grille %s illisible (%s)" % [path, plan.error])
			quit(1)
			return
		_plans[map_id] = plan
	for map_id: StringName in _maps:
		_build(map_id)
	if _errors > 0:
		quit(1)
	elif _masks_written > 0:
		print("build_joh5_radio_tower : %d masque(s) écrit(s) ; importer (--import) puis relancer"
			% _masks_written)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName) -> void:
	_map_id = map_id
	var plan: PlanGrid = _plans[map_id]
	var size := Vector2i(plan.width, plan.height)
	var entities: Node2D
	if map_id == CAR_MAP:
		entities = _make_car_root(size)
	else:
		entities = _make_floor_root(map_id, plan, size)
	if entities == null:
		return
	_root.set(&"interior", true)
	var ids: Array = plan.positions.keys()
	ids.sort()
	for id: String in ids:
		var cell: Vector2i = plan.cell_of(id)
		var cells: Array[Vector2i] = plan.cells_at(id)
		cells.sort()
		match String(plan.positions[id]["kind"]):
			"spawn":
				for index: int in cells.size():
					var marker := Marker2D.new()
					marker.name = id if index == 0 else "%s_%d" % [id, index]
					marker.position = _world(cells[index])
					_attach(_root.get_node(^"Spawns"), marker)
			"escalier":
				_add_stairs(plan, id, cell)
			"ascenseur":
				var door := _warp("ElevatorDoor", cell, STEP_ON, Vector2i.ZERO, CAR_MAP,
					CAR_ENTRANCE, Vector2i.UP)
				var only_after: Array[StringName] = [ELEVATOR_FLAG]
				door.set(&"if_flags", only_after)
			"sortie":
				for index: int in cells.size():
					_warp("CarDoor%d" % index, cells[index], STEP_ON, Vector2i.ZERO, CAR_EXIT_MAP,
						ELEVATOR_SPAWN, Vector2i.DOWN)
			"panneau":
				_add_point("ElevatorPanel", cell, Vector2i.UP, PANEL_DIALOGUE, KIND_EXAMINE, [], [])
			"warp":
				var exists := ResourceLoader.exists(OUT_DIR + "%s.tscn" % EXIT_MAP)
				for index: int in cells.size():
					# Une arrivée par case à Doublonville (`retour_tour_radio`, `_1`).
					var spawn := EXIT_SPAWN if index == 0 else StringName("%s_%d" % [EXIT_SPAWN, index])
					var exit := _warp("Exit%d" % index, cells[index], PUSH, Vector2i.DOWN, EXIT_MAP,
						spawn, Vector2i.DOWN)
					if not exists:
						exit.set(&"coming_soon", EXIT_COMING_SOON)
			"declencheur":
				var trigger := Marker2D.new()
				trigger.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
				trigger.name = id
				trigger.position = _world(cells[0])
				trigger.set(&"size", cells[cells.size() - 1] - cells[0] + Vector2i.ONE)
				trigger.set(&"cutscene_id", TRIGGER_SCENES[id])
				_attach(_root.get_node(^"Triggers"), trigger)
			"examen", "decor":
				if not EXAMINE_DIALOGUES.has(id):
					continue  # décor sans texte (Poké Balls du bureau : un PNJ objet)
				var unless := _flags(plan, id, "actif_sans")
				if id == "haut_parleur":
					unless.append(ELEVATOR_FLAG)  # T-1 en boucle jusqu'à la défaite de Cenere [D]
				_add_point("Examine_%s" % id, cell, Vector2i.ZERO, EXAMINE_DIALOGUES[id],
					KIND_EXAMINE, _flags(plan, id, "actif_avec"), unless)
			"cache":
				_add_point("Hidden_%s" % id, cell, Vector2i.ZERO, StringName(id), KIND_EXAMINE, [],
					[StringName("got_%s" % id)])
			"porte_cle":
				_add_locked_door(entities, plan, id, cell)
	var blocked: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			if not plan.is_walkable(Vector2i(x, y)):
				blocked.append(Vector2i(x, y))
	_root.set(&"blocked_cells", blocked)
	if _kit != null and not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(_kit.get(&"errors"))])
		_errors += 1
		_root.free()
		return
	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_DIR + "%s.tscn" % map_id)
	print("%s : %s (%d cases bloquées, %d passages)" % [map_id, error_string(err),
		blocked.size(), _root.get_node(^"Warps").get_child_count()])
	if err != OK:
		_errors += 1
	_root.free()


## Cabine : coque peinte de la Sylphe (`Shell`, 384 × 384).
func _make_car_root(size: Vector2i) -> Node2D:
	_kit = null
	_root = Node2D.new()
	_root.name = _maps[CAR_MAP][0]
	_root.set_script(load("res://game/world/map.gd"))
	_root.set(&"map_id", CAR_MAP)
	_root.set(&"display_name", DISPLAY_NAME)
	_root.set(&"size", size)
	_root.set(&"light_profile", LIGHT_PROFILE)
	var shell := Sprite2D.new()
	shell.name = "Shell"
	shell.texture = load(CAR_SHELL_PATH)
	shell.centered = false
	shell.z_index = -3
	_attach(_root, shell)
	if shell.texture == null or shell.texture.get_size() != Vector2(size * TILE):
		push_error("%s : coque absente ou ≠ %s cases" % [CAR_MAP, size])
		_errors += 1
		_root.free()
		return null
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(_root, entities)
	entities.unique_name_in_owner = true
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		_attach(_root, node)
	return entities


## Étage en modules sur le kit (modèle `build_silph_co.gd`) : la grille relue pour l'image
## (`r p c` → `M`, `V S` → `#`).
func _make_floor_root(map_id: StringName, plan: PlanGrid, size: Vector2i) -> Node2D:
	var floor_number := int(String(map_id).trim_prefix("goldenrod_radio_tower_").trim_suffix("f"))
	var seed_base := 5500 + floor_number * 10
	var art_path := _art_plan(_maps[map_id][1])
	if art_path.is_empty():
		_errors += 1
		return null
	var art_plan := PlanGrid.new()
	art_plan.load_file(art_path)
	_kit = Kit.new(art_path, size, seed_base + 1, seed_base + 2, plan.walkable)
	_kit.set(&"floor_texture_path", GROUND_FLOOR)
	_kit.set(&"rubble_texture_path", GROUND_FLOOR)
	_kit.set(&"mass_texture_path", GROUND_MASS)
	_kit.set(&"border_color", BORDER_COLOR)
	_kit.set(&"rubble_mark", NO_RUBBLE_MARK)
	_kit.set(&"rubble_is_logic", false)
	_kit.set(&"wall_marks", WALL_MARK)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(_kit.get(&"errors"))])
		_errors += 1
		return null
	_root = _kit.call(&"make_root", _maps[map_id][0], map_id, DISPLAY_NAME, LIGHT_PROFILE)
	if not _kit.call(&"add_ground", MASK_PATH % map_id):
		if not (_kit.get(&"errors") as PackedStringArray).is_empty():
			push_error("%s :\n%s" % [map_id, "\n".join(_kit.get(&"errors"))])
			_errors += 1
		else:
			_masks_written += 1
		_kit.call(&"discard")
		return null
	for layer_name: String in ["Ground", "Detail", "Obstacles"]:
		var layer := _root.get_node(layer_name)
		_root.remove_child(layer)
		layer.free()
	_place_floor_bands(art_plan)
	var walls: Vector3i = ModuleWalls.new(_kit, WALL_PREFIX, WALL_MARK, WALL_MARK,
		seed_base + 3).place()
	var props := _place_furniture(art_plan, floor_number)
	props += _place_glass(plan, floor_number)
	var marks := _place_floor_marks(plan)
	if floor_number == 1:
		_place_hall()
	_place_studio_floors(floor_number)
	if plan.positions.has("escalier_secours"):
		_kit.call(&"add_sprite", _kit.get(&"entities"), LOCKED_DOOR,
			_world(plan.cell_of("escalier_secours")), "PorteSecours")
	print("%s : murs %d faces / %d côtés / %d couronnes, %d meubles, %d marques au sol" % [
		map_id, walls.x, walls.y, walls.z, props, marks])
	return _kit.get(&"entities")


## Copie de la grille [param name] pour l'image (`user://joh5_plans/`) ; "" en cas d'erreur.
func _art_plan(name: String) -> String:
	var source := FileAccess.get_file_as_string("res://tools/plans/%s.txt" % name)
	if source.is_empty():
		push_error("build_joh5_radio_tower : grille %s vide" % name)
		return ""
	var out := PackedStringArray()
	var in_grid := false
	for line: String in source.split("\n"):
		if line.begins_with("GRILLE"):
			in_grid = true
		elif line.begins_with("FIN"):
			in_grid = false
		elif in_grid and line.length() > 3:
			var row := line.substr(3)
			for mark: String in AS_FURNITURE:
				row = row.replace(mark, "M")
			for mark: String in AS_WALL:
				row = row.replace(mark, "#")
			line = line.substr(0, 3) + row
		out.append(line)
	var path := TMP_PLANS + "%s.txt" % name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("build_joh5_radio_tower : écriture de %s impossible" % path)
		return ""
	file.store_string("\n".join(out))
	file.close()
	return path


## Plantes (`M` d'une seule case) et mobilier peint de l'étage.
func _place_furniture(plan: PlanGrid, floor_number: int) -> int:
	var entities: Node2D = _kit.get(&"entities")
	var count := 0
	for entry: Array in FURNITURE[floor_number]:
		var prop: Node2D = _kit.call(&"add_prop", entities, entry[0], (entry[1] as Vector2) * TILE,
			entry[2])
		prop.set(&"footprint", [] as Array[Vector2i])
		prop.scale = entry[3]
		count += 1
	var seen: Dictionary[Vector2i, bool] = {}
	for start: Vector2i in plan.cells_of("M"):
		if seen.has(start):
			continue
		var patch: Array[Vector2i] = []
		var stack: Array[Vector2i] = [start]
		seen[start] = true
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			patch.append(cell)
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = cell + step
				if not seen.has(next) and next.x >= 0 and next.y >= 0 and next.x < plan.width \
						and next.y < plan.height and plan.at(next) == "M":
					seen[next] = true
					stack.append(next)
		if patch.size() == 1:
			_kit.call(&"add_prop_at", entities, PLANT, patch[0], "Furniture%03d" % count)
			count += 1
	return count


## Vitres `V` : étendues est-ouest en panneaux de verre répétés (un seul sprite par étendue), cases
## seules du nord au sud en paroi vue par la tranche ; baie sur la ville au 5F. Renvoie leur nombre.
func _place_glass(plan: PlanGrid, floor_number: int) -> int:
	var entities: Node2D = _kit.get(&"entities")
	var count := 0
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			if plan.at(Vector2i(x, y)) != "V" or _is_upright_glass(plan, Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while plan.at(Vector2i(x, y)) == "V" and not _is_upright_glass(plan, Vector2i(x, y)):
				x += 1
			var width := x - start
			var bay := floor_number == BAY_FLOOR and y == BAY_ROW
			var foot := Vector2((start + width / 2.0) * TILE, (y + 1) * TILE)
			var sprite: Sprite2D = _kit.call(&"add_sprite", entities, BAY if bay else GLASS_H,
				foot, "Glass%02d" % count)
			_repeat(sprite, foot, Vector2(width * TILE, sprite.texture.get_height()))
			if bay:
				sprite.scale.y = BAY_SCALE_Y
			else:
				sprite.modulate.a = GLASS_ALPHA
			count += 1
	for x: int in plan.width:
		var y := 0
		while y < plan.height:
			if not _is_upright_glass(plan, Vector2i(x, y)):
				y += 1
				continue
			var start := y
			while _is_upright_glass(plan, Vector2i(x, y)):
				y += 1
			var foot := Vector2((x + 0.5) * TILE, y * TILE)
			var sprite: Sprite2D = _kit.call(&"add_sprite", entities, GLASS_V, foot,
				"GlassSide%02d" % count)
			_repeat(sprite, foot, Vector2(sprite.texture.get_width(), (y - start) * TILE + 40.0))
			sprite.scale.x = GLASS_V_SCALE
			sprite.modulate.a = GLASS_ALPHA + 0.2
			count += 1
	return count


## Case de verre d'une paroi nord-sud : du verre au nord et au sud.
func _is_upright_glass(plan: PlanGrid, cell: Vector2i) -> bool:
	return plan.at(cell) == "V" and plan.at(cell + Vector2i.UP) == "V" \
		and plan.at(cell + Vector2i.DOWN) == "V"


## Image répétée sur [param size] (pixels), pied [param foot] au milieu du bas (le nœud reste au
## pied : tri des personnages).
func _repeat(sprite: Sprite2D, foot: Vector2, size: Vector2) -> void:
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.centered = true
	sprite.offset = Vector2(0.0, -size.y / 2.0)
	sprite.position = foot


## Carrelage en bandes aux bords droits (le sol peint du kit, fait pour les grottes, a des bords
## déchiquetés), sous les murs.
func _place_floor_bands(plan: PlanGrid) -> void:
	var texture: Texture2D = load(GROUND_FLOOR)
	for y: int in plan.height:
		var x := 0
		while x < plan.width:
			if plan.at(Vector2i(x, y)) == WALL_MARK:
				x += 1
				continue
			var start := x
			while x < plan.width and plan.at(Vector2i(x, y)) != WALL_MARK:
				x += 1
			var sprite := Sprite2D.new()
			sprite.name = "Band%02d_%02d" % [y, start]
			sprite.texture = texture
			sprite.centered = false
			sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			sprite.region_enabled = true
			sprite.region_rect = Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE)
			sprite.position = Vector2(start * TILE, y * TILE)
			_kit.call(&"attach", _kit.get(&"decals"), sprite)


## Hall : logo sur le mur du fond et double porte d'entrée, sous les personnages.
func _place_hall() -> void:
	var logo: Node2D = _kit.call(&"add_prop", _kit.get(&"entities"), LOGO, LOGO_FOOT, "Logo")
	logo.set(&"footprint", [] as Array[Vector2i])
	logo.scale = Vector2.ONE * LOGO_SCALE
	var door: Node2D = _kit.call(&"add_prop", _kit.get(&"decals"), ENTRANCE, ENTRANCE_FOOT * TILE,
		"Entree")
	door.set(&"footprint", [] as Array[Vector2i])
	door.scale = Vector2.ONE * ENTRANCE_SCALE


## Moquette des studios, en décor au sol.
func _place_studio_floors(floor_number: int) -> void:
	var index := 0
	for rect: Rect2i in STUDIOS.get(floor_number, []):
		var sprite := Sprite2D.new()
		sprite.name = "Studio%d" % index
		sprite.texture = load(STUDIO_FLOOR)
		sprite.centered = false
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, Vector2(rect.size * TILE))
		sprite.position = Vector2(rect.position * TILE)
		sprite.modulate = STUDIO_TINT
		_kit.call(&"attach", _kit.get(&"decals"), sprite)
		index += 1


## Au sol : escaliers `U` / `D`, porte d'ascenseur `L`, seuils `K`, paillasson `E`.
func _place_floor_marks(plan: PlanGrid) -> int:
	var count := 0
	for entry: Array in [["U", STAIRS_UP, "StairsUp"], ["D", STAIRS_DOWN, "StairsDown"],
			["L", ELEVATOR_DOOR, "ElevatorDoorPanel"], ["K", DOOR_SILL, "DoorSill"]]:
		for cell: Vector2i in plan.cells_of(entry[0]):
			_kit.call(&"add_floor_prop", entry[1], cell, "%s%03d" % [entry[2], count])
			count += 1
	var exits: Array[Vector2i] = plan.cells_of("E")
	exits.sort()
	for index: int in range(1, exits.size(), 2):
		_kit.call(&"add_floor_prop", DOORMAT, exits[index], "Doormat%d" % index)
		count += 1
	return count


func _add_stairs(plan: PlanGrid, id: String, cell: Vector2i) -> void:
	var vers := plan.attr(id, "vers")
	var target := StringName(vers.get_slice(":", 0))
	var spawn := vers.get_slice(":", 1)
	var target_plan: PlanGrid = _plans.get(target)
	if target_plan == null or not target_plan.positions.has(spawn):
		push_error("%s : escalier %s → %s introuvable" % [_map_id, id, vers])
		_errors += 1
		return
	_warp("Stairs_%s" % id.replace("vers_", "to_"), cell, STEP_ON, Vector2i.ZERO, target,
		StringName(spawn), _facing(target_plan.attr(spawn, "facing")))


## Porte fermée (réserve, bureau) : [FlagGate] bloquante jusqu'au drapeau d'ouverture
## (`drapeau=`, sinon `cle=`), porte peinte ; point OUVRIR sur la case.
func _add_locked_door(entities: Node2D, plan: PlanGrid, id: String, cell: Vector2i) -> void:
	var open_flag := plan.attr(id, "drapeau")
	if open_flag.is_empty():
		open_flag = plan.attr(id, "cle")
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "LockedDoor_%s" % id
	gate.position = Vector2(cell.x * TILE, cell.y * TILE)
	var unless: Array[StringName] = [StringName(open_flag)]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = [cell]
	gate.set(&"blocking_cells", blocking)
	_attach(entities, gate)
	# Au niveau des personnages (trié par la case) : au-dessus du sol peint et du seuil.
	var panel: Sprite2D = _kit.call(&"add_sprite", gate, LOCKED_DOOR,
		Vector2(TILE / 2.0, float(TILE)), "Panel")
	panel.z_index = 0
	# EXAMINER (pas OUVRIR : ce verbe va au KeyDoorDirector des portes à carte).
	_add_point("Open_%s" % id, cell, Vector2i.ZERO, DOOR_DIALOGUES[id], KIND_EXAMINE, [],
		[StringName(open_flag)])


func _flags(plan: PlanGrid, id: String, key: String) -> Array[StringName]:
	var out: Array[StringName] = []
	var text := plan.attr(id, key)
	if text.is_empty():
		return out
	for flag: String in text.split(","):
		out.append(StringName(flag))
	return out


func _warp(node_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i) -> Marker2D:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	_attach(_root.get_node(^"Warps"), point)
	return point


func _add_point(node_name: String, cell: Vector2i, facing: Vector2i, dialogue: StringName,
		kind: int, if_flags: Array, unless: Array) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"dialogue_id", dialogue)
	point.set(&"kind", kind)
	point.set(&"size", Vector2i.ONE)
	point.set(&"facing", facing)
	var ifs: Array[StringName] = []
	ifs.assign(if_flags)
	point.set(&"if_flags", ifs)
	var flags: Array[StringName] = []
	flags.assign(unless)
	point.set(&"unless_flags", flags)
	_attach(_root.get_node(^"Interactables"), point)


func _facing(word: String) -> Vector2i:
	return {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
		"right": Vector2i.RIGHT}.get(word, Vector2i.DOWN)


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = _root
