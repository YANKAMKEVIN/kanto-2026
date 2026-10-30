extends SceneTree
## Lot DAF.10b (`tools/art/daf10b.py`, fiche `docs/design/fiches-assets/daf-10b/fiche.md`, RP-273,
## RP-274, RP-272 pour les façades des postes) : repeint les routes du sud de Kanto écrites en
## tuiles provisoires par `build_j22_maps.gd` (Routes 12 sud, 13, 14, 15, 16 ouest, 17, 18) et
## `build_j24_sea.gd` (Routes 19, 20, 21, la mer).
##
## Passe APRÈS ces outils, sur le modèle de `build_daf4_exterieurs.gd` ; idempotente (elle retire
## d'abord ses propres nœuds). **La logique ne change pas** (gel du J33) : couches de tuiles
## (dont `Ground`, source logique), `blocked_cells`, eau pêchable, Piste, pentes, passages,
## panneaux, PNJ et nœuds de `Entities` gardés ; les couches sont seulement masquées. L'image vient
## de `tools/coast_map_kit.gd` (une racine de kit jetable dont on adopte les nœuds), sur une copie
## **traduite** de la grille (`build/daf10b/plans/`, légendes du J22 et du J24 ramenées à celle
## du kit) :
## - forêt serrée `T` (et buissons `x`, vides ` `), herbe `.`, chemin `=` (et portes `D`),
##   hautes herbes `h` peintes ;
## - eau `w` `f` `~` : la mer de Bourg Palette (angles droits, écume) ; rivage rocheux en modules
##   sur les `R` qui touchent l'eau ; les autres `R` et la roche des Îles Écume `K` : paroi de la
##   série 12 (grands blocs) ou rochers (saillies, petits blocs), comme la Route 23 ;
## - sable `y` (et rebords `v` : `relief_rebord_01`) ; Piste Cyclable `k` `s` : béton
##   ([constant PISTE]) ; ponton `q` : planches du quai de la Route 12 ;
## - clôtures `c` (blanches, à piquets), barrières de la Piste `b` (bois), bancs `n` ;
## - façades à l'emprise exacte des bâtiments, **sans emprise propre** (les cases restent celles
##   de la grille) : postes traversants `P` (Routes 15, 18 : `bldg_poste_traversant_01`), poste
##   nord-sud de la Route 16 ouest (`bldg_poste_foret_nord_01`, comme la Route 12), maisons `m` ;
##   bouches des Îles Écume `D` (Route 20) ;
## - panneaux du J24 : image peinte accrochée au panneau (dessins provisoires retirés).
## Lumière `golden_hour` [D] là où la carte n'en avait pas (cartes du J22), comme les routes peintes.
## Nœuds posés : racine `PaintedGround`, `Daf10bForestFloor`, `Daf10bDecals` (hors des couches
## d'emprise de `GameMap`) ; enfants préfixés `Daf10b` dans `Entities`.
## Contrôle : `tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après.
##
##   godot --headless --path . -s res://tools/build_daf10b_routes.gd [-- route_13,route_19]
##   (code 2 : masques écrits ; godot --headless --path . --import, puis relancer)

const Kit := preload("res://tools/coast_map_kit.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const MAPS_DIR: String = "res://game/world/maps/"
const MASK_PATH: String = "res://assets/world/maps/%s_ground.png"
const TRANSLATED_DIR: String = "res://build/daf10b/plans/"
const NPCS_PATH: String = "res://data/npcs/%s.json"
const OWN_PREFIX: String = "Daf10b"
const OWN_ROOT: Array[String] = ["PaintedGround", "Daf10bForestFloor", "Daf10bDecals"]
## Carte → [grille, graine, légende (« j22 » | « j24 »)].
const MAPS: Dictionary = {
	&"route_12_south": ["route_12_sud", 10120, "j22"],
	&"route_13": ["route_13", 10130, "j22"],
	&"route_14": ["route_14", 10140, "j22"],
	&"route_15": ["route_15", 10150, "j22"],
	&"route_16_west": ["route_16_west", 10160, "j22"],
	&"route_17": ["route_17", 10170, "j22"],
	&"route_18": ["route_18", 10180, "j22"],
	&"route_19": ["route_19", 10190, "j24"],
	&"route_20": ["route_20", 10200, "j24"],
	&"route_21": ["route_21", 10210, "j24"],
}
## Traduction des grilles vers la légende du kit : `T` forêt, `.` herbe, `=` chemin, `h` hautes
## herbes, `p` béton (canal R du masque), `s` sable, `w` mer, `R` rivage, `#` paroi, `c` solide
## sans arbre (clôtures, bancs, bâtiments : objets posés ici).
const LEGEND: Dictionary = {
	"j22": {"T": "T", "x": "T", " ": "T", ".": ".", "=": "=", "D": "=", "h": "h", "q": ".",
		"k": "p", "s": "p", "y": "s", "w": "w", "f": "w", "~": "w", "R": "R", "c": "c", "b": "c",
		"n": "c", "P": "c", "m": "c", "g": "="},
	"j24": {"T": "T", " ": "T", ".": ".", "=": "=", "h": "h", "y": "s", "v": "s", "w": "w",
		"~": "w", "R": "R", "K": "#", "D": "=", "s": "w"},
}
const KIT_WALKABLE: String = ".=hps"
## Béton de la Piste (Codex, DAF.10b) ; repli : dalles du souterrain [D].
const PISTE: String = "res://assets/world/ground/ground_piste_01.png"
const PISTE_FALLBACK: String = "res://assets/world/ground/ground_dalles_souterrain_01.png"
const PLANKS_EW: String = "res://assets/world/ground/ground_planches_quai_01.png"
const PLANKS_NS: String = "res://assets/world/ground/ground_planches_quai_ns_01.png"
const SIGN_TEXTURE: String = "res://assets/world/props/prop_panneau_01.png"
## Façades : carte → [[caractère, objet peint, pied relevé (cases au-dessus du bas du bloc)]] ;
## l'objet est mis à la largeur du bâtiment.
const FACADES: Dictionary = {
	&"route_12_south": [["m", "bldg_maison_pecheur_01", 0.0]],
	&"route_15": [["P", "bldg_poste_traversant_01", 0.8]],
	&"route_16_west": [["P", "bldg_poste_foret_nord_01", 0.0], ["m", "bldg_maison_lavanville_01", 0.0]],
	&"route_18": [["P", "bldg_poste_traversant_01", 0.8]],
}
## Postes traversants (`tools/art/daf10b_derives.py`) : pied relevé pour que leurs passages
## latéraux tombent sur les portes ; la dernière rangée du bloc (sous la façade) est de la forêt.
const FOREST_UNDER_POST: Array[StringName] = [&"route_15", &"route_18"]
## Bouches des Îles Écume (Route 20 : portes `D` au pied de la roche `K`).
const MOUTH_IDS: Array[String] = ["relief_bouche_paroi_01", "relief_entree_grotte_01"]
## Clôtures : caractère → {« h » : [modules horizontaux, du plus long au plus court], « v » : idem}.
const FENCES: Dictionary = {
	"c": {"h": ["prop_cloture_piquets_01", "prop_cloture_piquets_01_court",
		"prop_cloture_courte_01"], "v": ["prop_cloture_piquets_v_01", "prop_cloture_courte_01"]},
	"b": {"h": ["prop_cloture_01", "prop_cloture_courte_01"],
		"v": ["prop_cloture_v_01", "prop_cloture_courte_01"]},
}
const BENCH_ID: String = "prop_banc_01"
const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
const PROTRUSION_MAX: int = 2
const BLOCK_MIN: int = 8
const MEADOW_PER_CELL: float = 0.25
const MEADOW_FLOWER_CHANCE: float = 0.25
const FLOWERS: Array[int] = [1, 3, 5]
## « Forêt plus sèche » des routes voisines (Routes 12, 16).
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _errors: int = 0
var _masks: int = 0


func _init() -> void:
	var wanted: Array = MAPS.keys()
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		wanted = Array(args[0].split(",")).map(func(s: String) -> StringName: return StringName(s))
	for map_id: StringName in wanted:
		_build(map_id)
	if _errors > 0:
		quit(1)
	elif _masks > 0:
		print("build_daf10b_routes : %d masque(s) écrit(s) ; importer (--import) puis relancer"
			% _masks)
		quit(2)
	else:
		quit(0)


func _build(map_id: StringName) -> void:
	var spec: Array = MAPS[map_id]
	var source := PlanGrid.new()
	if not source.load_file("res://tools/plans/%s.txt" % spec[0]):
		push_error("%s : %s" % [map_id, source.error])
		_errors += 1
		return
	var size := Vector2i(source.width, source.height)
	var translated := _translate(source, LEGEND[spec[2]], map_id)
	var seed_value: int = spec[1]
	var kit: Object = Kit.new(translated, size, seed_value, seed_value + 1, seed_value + 2)
	kit.set(&"errors", PackedStringArray())
	kit.call(&"set_marks", KIT_WALKABLE, "#", "")
	_reserve(kit, source)
	var kit_root: Node2D = kit.call(&"make_root", "Kit", map_id, "", "", &"golden_hour",
		NPCS_PATH % map_id)
	kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	var cliffs: Dictionary = kit.get(&"cliff_cells")
	var outcrops := _split_outcrops(cliffs, size)
	var undergrowth: Dictionary = kit.call(&"forest_undergrowth")
	if not kit.call(&"add_ground", MASK_PATH % map_id, undergrowth):
		if (kit.get(&"errors") as PackedStringArray).is_empty():
			_masks += 1
		else:
			push_error("%s :\n%s" % [map_id, "\n".join(kit.get(&"errors"))])
			_errors += 1
		kit.call(&"discard")
		return
	var painted: Node2D = kit_root.get_node(^"PaintedGround")
	if not (kit.get(&"paved_cells") as Dictionary).is_empty():
		painted.set(&"r_texture", load(PISTE if ResourceLoader.exists(PISTE) else PISTE_FALLBACK))
	var decals: Node2D = kit.get(&"decals")
	var entities: Node2D = kit.get(&"entities")
	kit.call(&"place_border_decals", seed_value)
	kit.call(&"place_meadow", int(size.x * size.y * MEADOW_PER_CELL), MEADOW_FLOWER_CHANCE,
		FLOWERS)
	var shore: int = kit.call(&"place_shore")
	var paroi: int = kit.call(&"place_paroi", seed_value + 3)
	var rocks := _place_boulders(kit, outcrops)
	var planks := _place_planks(kit, decals, source.cells_of("q"))
	var ledges := 0
	for cell: Vector2i in source.cells_of("v") if spec[2] == "j24" else []:
		kit.call(&"add_prop_at", decals, "relief_rebord_01", cell, "Ledge%02d" % ledges)
		ledges += 1
	var fences := 0
	for mark: String in FENCES:
		fences += _place_fences(kit, entities, source, mark)
	_place_benches(kit, entities, source)
	var facades := _place_facades(kit, entities, source, map_id)
	if map_id == &"route_20":
		_place_mouths(kit, entities, source)
	kit.call(&"place_tall_grass")
	var forest: Vector2i = kit.call(&"place_forest", seed_value + 5, [] as Array[Vector2], {})
	var errors: PackedStringArray = kit.get(&"errors")
	if not errors.is_empty():
		push_error("%s :\n%s" % [map_id, "\n".join(errors)])
		_errors += 1
		kit.call(&"discard")
		return

	var path := MAPS_DIR + "%s.tscn" % map_id
	var root := (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as Node2D
	_clean(root)
	for layer: Node in root.get_children():
		if layer is TileMapLayer:
			(layer as TileMapLayer).visible = false
	var index := root.get_node(^"Obstacles").get_index() + 1
	var renames := {"PaintedGround": "PaintedGround", "ForestFloor": "Daf10bForestFloor",
		"GroundDecals": "Daf10bDecals"}
	for node_name: String in renames:
		var node: Node = kit_root.get_node(NodePath(node_name))
		_adopt(node, root, root, kit_root)
		node.name = renames[node_name]
		root.move_child(node, index)
		index += 1
	var map_entities := root.get_node(^"Entities")
	for child: Node in (kit_root.get_node(^"Entities") as Node).get_children():
		child.name = OWN_PREFIX + String(child.name)
		_adopt(child, map_entities, root, kit_root)
	_paint_signs(root, map_entities)
	root.set(&"grass_front", load(Kit.GRASS_FRONT))
	if StringName(root.get(&"light_profile")) == &"":
		root.set(&"light_profile", &"golden_hour")
	kit.call(&"discard")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s (rivage %d, paroi %d, rochers %d, planches %d, rebords %d, clôtures %d, "
		% [map_id, error_string(err), shore, paroi, rocks, planks, ledges, fences]
		+ "façades %d, forêt %d → %d)" % [facades, forest.x, forest.y])
	if err != OK:
		_errors += 1
	root.free()


## Copie traduite de la grille (légende du kit, praticables du kit, positions d'origine) ; les `R`
## loin de l'eau (8-voisinage) deviennent de la paroi `#`. Renvoie son chemin.
func _translate(source: Object, legend: Dictionary, map_id: StringName) -> String:
	var lines := PackedStringArray(["PRATICABLES " + KIT_WALKABLE, "",
		"GRILLE %d %d" % [source.width, source.height]])
	var water := "wf~"
	for y: int in source.height:
		var row := ""
		for x: int in source.width:
			var mark: String = source.at(Vector2i(x, y))
			var out: String = legend.get(mark, "T")
			if mark == "R":
				var wet := false
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var other: String = source.at(Vector2i(x + dx, y + dy))
						wet = wet or (not other.is_empty() and water.contains(other))
				out = "R" if wet else "#"
			if mark == "P" and FOREST_UNDER_POST.has(map_id):
				var below: String = source.at(Vector2i(x, y + 1))
				if below != "P" and below != "D":
					out = "T"
			row += out
		lines.append("%02d %s" % [y, row])
	lines.append("FIN")
	var path := TRANSLATED_DIR + "%s.txt" % map_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TRANSLATED_DIR))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	return path


## Cases des PNJ, Pokémon et objets de la grille d'origine : la forêt s'en écarte.
func _reserve(kit: Object, source: Object) -> void:
	var cells: Array[Vector2i] = []
	var balls: Array[Vector2i] = []
	var positions: Dictionary = source.get(&"positions")
	for id: String in positions:
		var kind: String = positions[id]["kind"]
		if RESERVED_KINDS.has(kind):
			cells.append_array(positions[id]["cells"])
		if BALL_KINDS.has(kind):
			balls.append_array(positions[id]["cells"])
	kit.set(&"reserved_cells", cells)
	kit.set(&"reserved_balls", balls)


## Ponton (`q`) : planches du quai de la Route 12 en rectangles répétés (dans les décors au sol).
func _place_planks(kit: Object, decals: Node2D, cells: Array[Vector2i]) -> int:
	var left: Dictionary = {}
	for cell: Vector2i in cells:
		left[cell] = true
	var index := 0
	var keys: Array = left.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	for start: Vector2i in keys:
		if not left.has(start):
			continue
		var width := 1
		while left.has(start + Vector2i(width, 0)):
			width += 1
		var height := 1
		while true:
			var full := true
			for dx: int in width:
				full = full and left.has(start + Vector2i(dx, height))
			if not full:
				break
			height += 1
		for dy: int in height:
			for dx: int in width:
				left.erase(start + Vector2i(dx, dy))
		var sprite := Sprite2D.new()
		sprite.name = "Planks%02d" % index
		sprite.texture = load(PLANKS_EW if width >= height else PLANKS_NS)
		sprite.centered = false
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, Vector2(width, height) * Kit.TILE)
		sprite.position = Vector2(start * Kit.TILE)
		kit.call(&"attach", decals, sprite)
		index += 1
	return index


## Clôtures du caractère [param mark] : étendues horizontales (au moins deux cases) en modules du
## plus long au plus court, puis les cases restantes en étendues verticales. Renvoie leur nombre.
func _place_fences(kit: Object, entities: Node2D, source: Object, mark: String) -> int:
	var left: Dictionary = {}
	for cell: Vector2i in source.cells_of(mark):
		left[cell] = true
	var count := 0
	for horizontal: bool in [true, false]:
		var step := Vector2i.RIGHT if horizontal else Vector2i.DOWN
		var ids: Array = FENCES[mark]["h" if horizontal else "v"]
		var keys: Array = left.keys()
		keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y < b.y or (a.y == b.y and a.x < b.x))
		for start: Vector2i in keys:
			if not left.has(start) or left.has(start - step):
				continue
			var length := 1
			while left.has(start + step * length):
				length += 1
			if horizontal and length < 2:
				continue
			var at := 0
			while at < length:
				var rest := length - at
				var longest: String = ids[0]
				var full := _span(kit, longest, horizontal)
				var exact := false
				for id: String in ids:
					exact = exact or _span(kit, id, horizontal) == rest
				if rest < full and rest >= 2 and not exact:
					# Reste de 2 à 3 cases sans module à sa mesure : le module long raccourci.
					var first := start + step * at
					var rules: GDScript = kit.get(&"rules")
					var anchor := _anchor(kit, longest, first, first) if horizontal \
						else Vector2i(first.x, first.y + rest - 1)
					var foot: Vector2 = rules.call(&"foot_position", StringName(longest), anchor)
					if horizontal:
						foot.x += (rest - full) * Kit.TILE / 2.0
					var prop: Node2D = kit.call(&"add_prop", entities, longest, foot,
						"Fence%03d" % count)
					kit.call(&"clear_footprint", prop)
					var ratio := float(rest) / full
					if horizontal:
						prop.scale.x *= ratio
					else:
						prop.scale.y *= ratio
					at = length
					count += 1
					continue
				for id: String in ids:
					var span := _span(kit, id, horizontal)
					if span <= length - at or span == 1:
						var first := start + step * at
						var last := first + step * (span - 1)
						var anchor := _anchor(kit, id, first, last)
						kit.call(&"add_prop_at", entities, id, anchor, "Fence%03d" % count)
						for k: int in span:
							left.erase(first + step * k)
						at += span
						count += 1
						break
	return count


## Longueur d'un module de clôture dans son sens (cases).
func _span(kit: Object, id: String, horizontal: bool) -> int:
	var cells: Array[Vector2i] = (kit.get(&"rules") as GDScript).call(&"footprint", StringName(id))
	var lo := 1000
	var hi := -1000
	for cell: Vector2i in cells:
		var v := cell.x if horizontal else cell.y
		lo = mini(lo, v)
		hi = maxi(hi, v)
	return hi - lo + 1


## Case d'ancrage qui pose l'emprise de [param id] exactement de [param first] à [param last].
func _anchor(kit: Object, id: String, first: Vector2i, last: Vector2i) -> Vector2i:
	var cells: Array[Vector2i] = (kit.get(&"rules") as GDScript).call(&"footprint", StringName(id))
	var low := Vector2i(1000, 1000)
	for cell: Vector2i in cells:
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
	return first - low


## Bancs `n` : par paires horizontales ; une case seule reste nue (bloquée par la grille).
func _place_benches(kit: Object, entities: Node2D, source: Object) -> void:
	var cells: Array[Vector2i] = source.cells_of("n")
	var taken: Dictionary = {}
	var index := 0
	for cell: Vector2i in cells:
		if taken.has(cell) or not cells.has(cell + Vector2i.RIGHT):
			continue
		taken[cell] = true
		taken[cell + Vector2i.RIGHT] = true
		kit.call(&"add_prop_at", entities, BENCH_ID, _anchor(kit, BENCH_ID, cell,
			cell + Vector2i.RIGHT), "Bench%02d" % index)
		index += 1


## Façades : une par composante du caractère, à la largeur du bâtiment, pied au bas de sa
## dernière rangée, sans emprise propre (les cases sont déjà celles de la grille).
func _place_facades(kit: Object, entities: Node2D, source: Object, map_id: StringName) -> int:
	var count := 0
	for entry: Array in FACADES.get(map_id, []):
		var id: String = entry[1]
		if not ResourceLoader.exists("res://game/world/props/painted/%s.tscn" % id):
			push_warning("%s : façade %s absente (relancer après `daf10b.py --modules`)"
				% [map_id, id])
			continue
		var cells: Dictionary = {}
		for cell: Vector2i in source.cells_of(entry[0]):
			cells[cell] = true
		for component: Array[Vector2i] in _components(cells):
			var rect := Rect2i(component[0], Vector2i.ONE)
			for cell: Vector2i in component:
				rect = rect.merge(Rect2i(cell, Vector2i.ONE))
			# Les portes `D` sur les bords du bâtiment en font partie.
			for cell: Vector2i in source.cells_of("D"):
				if rect.grow(1).has_point(cell):
					rect = rect.merge(Rect2i(cell, Vector2i.ONE))
			var foot := Vector2((rect.position.x + rect.size.x / 2.0) * Kit.TILE,
				(float(rect.end.y) - float(entry[2])) * Kit.TILE)
			var prop: Node2D = kit.call(&"add_prop", entities, id, foot, "Facade%02d" % count)
			kit.call(&"clear_footprint", prop)
			var sprite := prop.get_node(^"Sprite") as Sprite2D
			var scale := float(rect.size.x * Kit.TILE) / sprite.texture.get_width()
			prop.scale = Vector2(scale, scale)
			count += 1
	return count


## Bouches des Îles Écume : une par paire de portes `D`, posée au pied de la roche.
func _place_mouths(kit: Object, entities: Node2D, source: Object) -> void:
	var id: String = MOUTH_IDS[1]
	for candidate: String in MOUTH_IDS:
		if ResourceLoader.exists("res://game/world/props/painted/%s.tscn" % candidate):
			id = candidate
			break
	var cells: Dictionary = {}
	for cell: Vector2i in source.cells_of("D"):
		cells[cell] = true
	var index := 0
	for component: Array[Vector2i] in _components(cells):
		var centre := 0.0
		var bottom := 0
		for cell: Vector2i in component:
			centre += cell.x + 0.5
			bottom = maxi(bottom, cell.y)
		centre /= component.size()
		var prop: Node2D = kit.call(&"add_prop", entities, id,
			Vector2(centre, bottom + 1) * Kit.TILE, "Mouth%02d" % index)
		kit.call(&"clear_footprint", prop)
		index += 1


## Panneaux du J24 (`Panneau_*` dessinés en polygones) : image peinte accrochée au panneau ;
## portes `Porte_*` : dessins retirés (bouches peintes).
func _paint_signs(root: Node, entities: Node) -> void:
	var sign: Texture2D = load(SIGN_TEXTURE)
	for child: Node in entities.get_children():
		var n := String(child.name)
		if not (n.begins_with("Panneau_") or n.begins_with("Porte_")):
			continue
		for drawing: Node in child.get_children():
			if drawing is Polygon2D:
				child.remove_child(drawing)
				drawing.free()
		if n.begins_with("Panneau_"):
			var s := Sprite2D.new()
			s.name = OWN_PREFIX + "Panneau"
			s.texture = sign
			s.centered = false
			s.offset = Vector2(-sign.get_width() / 2.0, -sign.get_height())
			child.add_child(s)
			s.owner = root


## Retire de [param cliffs] les saillies puis les petits blocs ; renvoie ces composantes (rochers)
## (comme `build_daf4_exterieurs.gd`).
func _split_outcrops(cliffs: Dictionary, size: Vector2i) -> Array[Array]:
	var loose: Dictionary = {}
	for y: int in size.y:
		var start := -1
		for x: int in size.x + 1:
			var on := x < size.x and cliffs.has(Vector2i(x, y))
			if on and start < 0:
				start = x
			elif not on and start >= 0:
				if x - start <= PROTRUSION_MAX:
					for k: int in range(start, x):
						loose[Vector2i(k, y)] = true
				start = -1
	for cell: Vector2i in loose:
		cliffs.erase(cell)
	for component: Array[Vector2i] in _components(cliffs):
		if component.size() < BLOCK_MIN:
			for cell: Vector2i in component:
				cliffs.erase(cell)
				loose[cell] = true
	return _components(loose)


func _components(cells: Dictionary) -> Array[Array]:
	var left := cells.duplicate()
	var out: Array[Array] = []
	var keys: Array = left.keys()
	keys.sort()
	for start: Vector2i in keys:
		if not left.has(start):
			continue
		left.erase(start)
		var component: Array[Vector2i] = [start]
		var stack: Array[Vector2i] = [start]
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in SIDES:
				if left.has(cell + side):
					left.erase(cell + side)
					component.append(cell + side)
					stack.append(cell + side)
		component.sort()
		out.append(component)
	return out


## Rochers sur les saillies et petits blocs (comme la Route 23) ; rocher de mer au bord de l'eau.
func _place_boulders(kit: Object, outcrops: Array[Array]) -> int:
	var rules: GDScript = kit.get(&"rules")
	var decor: RandomNumberGenerator = kit.get(&"decor_rng")
	var water: Dictionary = kit.get(&"water_cells")
	var entities: Node2D = kit.get(&"entities")
	var index := 0
	for component: Array in outcrops:
		var free: Dictionary = {}
		var wet := false
		for cell: Vector2i in component:
			free[cell] = true
			for side: Vector2i in SIDES:
				wet = wet or water.has(cell + side)
		var order: Array = component.duplicate()
		order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y > b.y or (a.y == b.y and a.x < b.x))
		var ids: Array[String] = ["prop_grande_pierre_01", "prop_rocher_01"]
		if wet:
			ids = ["prop_rocher_mer_01"]
		for cell: Vector2i in order:
			if not free.has(cell):
				continue
			var placed := false
			for id: String in ids:
				var footprint: Array[Vector2i] = rules.call(&"footprint", StringName(id))
				for align: Vector2i in footprint:
					var anchor := cell - align
					var fits := true
					for offset: Vector2i in footprint:
						fits = fits and free.has(anchor + offset)
					if not fits:
						continue
					var rock: Node2D = kit.call(&"add_prop_at", entities, id, anchor,
						"Rock%02d" % index)
					_style_rock(kit, rock, decor, 0.9 if id == "prop_grande_pierre_01" else 1.0)
					for offset: Vector2i in footprint:
						free.erase(anchor + offset)
					placed = true
					break
				if placed:
					break
			if not placed:
				var foot := Vector2(cell.x + decor.randf_range(0.4, 0.6),
					cell.y + decor.randf_range(0.88, 0.98))
				var small: Node2D = kit.call(&"add_prop", entities, ids[-1], foot * Kit.TILE,
					"Rock%02d" % index)
				kit.call(&"clear_footprint", small)
				_style_rock(kit, small, decor, 0.7)
				free.erase(cell)
			index += 1
	return index


func _style_rock(kit: Object, rock: Node2D, decor: RandomNumberGenerator, scale: float) -> void:
	var s := scale * decor.randf_range(0.92, 1.08)
	rock.scale = Vector2(s, s)
	kit.call(&"flip", rock, decor.randf() < 0.5)
	var value := decor.randf_range(0.9, 1.0)
	rock.modulate = Color(value, value, value)


## Retire ce que cette passe a posé (relance).
func _clean(root: Node) -> void:
	for node_name: String in OWN_ROOT:
		var old := root.get_node_or_null(NodePath(node_name))
		if old != null:
			root.remove_child(old)
			old.free()
	var entities := root.get_node(^"Entities")
	for child: Node in entities.get_children():
		if String(child.name).begins_with(OWN_PREFIX):
			entities.remove_child(child)
			child.free()
			continue
		for sprite: Node in child.get_children():
			if String(sprite.name).begins_with(OWN_PREFIX):
				child.remove_child(sprite)
				sprite.free()


## Déplace [param node] du kit jetable vers [param parent] de la carte (voir
## `build_daf4_exterieurs.gd`).
func _adopt(node: Node, parent: Node, root: Node, kit_root: Node) -> void:
	var owned: Array[Node] = []
	_collect(node, kit_root, owned)
	for n: Node in owned:
		n.owner = null
	node.get_parent().remove_child(node)
	parent.add_child(node)
	for n: Node in owned:
		n.owner = root


func _collect(node: Node, kit_root: Node, into: Array[Node]) -> void:
	if node.owner == kit_root:
		into.append(node)
	for child: Node in node.get_children():
		_collect(child, kit_root, into)
