extends "res://tools/cerulean_map_kit.gd"
## Boîte à outils des cartes **portuaires** peintes du jalon 15 (T14, docs/tech/jalon-15.md §2.1) :
## `tools/build_route_6.gd` (étang) et `tools/build_vermilion_city.gd` (port de Carmin). Tout ce que
## fait `tools/cerulean_map_kit.gd` (praticables lus dans la grille, deux passes masque / scène,
## forêt, quais et berges en modules, graines fixes), avec les conventions des grilles du J15 :
## - **eau `W`** (majuscule : `tools/plans/route_6.txt`, `vermilion_city.txt`) au lieu de `w` ;
##   `OverworldTiles.Kind.WATER` (solide, `GridWorld.is_water`) ;
## - **coque `N`** du S.S. Anne : eau elle aussi (solide) ; la coque est un **objet séparé** posé
##   par la carte (contrat du J16 : il disparaît au départ, la mer reste) ; l'accès `E` (praticable,
##   terminal) est peint comme l'eau, sous le navire. Aucun module de quai contre la coque
##   ([member hull_cells] ne sont ni du sol ni de l'eau à border) ;
## - **mer du port** ([member sea]) : la mer de Bourg Palette (`ground_eau_01`), à angles droits,
##   écume réduite ([member sea_foam]) et **assombrie** (bleu profond de la vue générale) par un
##   aplat multiplicatif par rectangle d'eau ([method place_sea_tint], quelques nœuds) ; sinon
##   l'eau claire des canaux (étang de la Route 6) ;
## - **platelage** ([method place_planks]) : les cases de quai, de pontons et de passerelle
##   (`q g k z`) reçoivent la texture de planches en **rectangles répétés** (un `Sprite2D` par
##   rectangle, `region` + répétition : planches est-ouest sur le quai, nord-sud sur les pontons),
##   dans `GroundDecals`, avant les bords de quai ; le masque du sol reste de l'herbe dessous.
##
## Utilisé par `load("res://tools/vermilion_map_kit.gd").new(...)`.

const PORT_WATER_MARK: String = "W"
const HULL_MARK: String = "N"
const ACCESS_MARK: String = "E"
## Caractères du platelage (quai, passerelle, caisses et bittes posées sur le quai).
const PLANK_MARKS: String = "qgkz"
const PLANKS_EW: String = "res://assets/world/ground/ground_planches_quai_01.png"
const PLANKS_NS: String = "res://assets/world/ground/ground_planches_quai_ns_01.png"
## Bords de quai en bois (série 17, fiche `serie-17-carmin.md` « Alignement ») : rôle vu depuis la
## case d'eau ; `n_end` = bout de ponton (eau des deux côtés).
const WOOD_PIECES: Dictionary[StringName, Dictionary] = {
	&"n": {"ids": ["relief_quai_bois_01", "relief_quai_bois_02"], "flip_h": false,
		"flip_v": false},
	&"s": {"ids": ["relief_quai_bois_01"], "flip_h": false, "flip_v": true},
	&"w": {"ids": ["relief_quai_bois_03"], "flip_h": false, "flip_v": false},
	&"e": {"ids": ["relief_quai_bois_03"], "flip_h": true, "flip_v": false},
	&"nw": {"ids": ["relief_quai_bois_05"], "flip_h": false, "flip_v": false},
	&"ne": {"ids": ["relief_quai_bois_05"], "flip_h": true, "flip_v": false},
	&"sw": {"ids": ["relief_quai_bois_05"], "flip_h": false, "flip_v": true},
	&"se": {"ids": ["relief_quai_bois_05"], "flip_h": true, "flip_v": true},
}
const WOOD_END: String = "relief_quai_bois_04"
## Longueur maximale (cases) d'une étendue « au nord » traitée comme un bout de ponton.
const PONTOON_END_MAX: int = 2

## Mer du port (Carmin) plutôt que l'eau claire des canaux (étang de la Route 6).
var sea: bool = false
## Écume de la mer du port (0 = aucune ; défaut de Bourg Palette 0,8).
var sea_foam: float = 0.3
## Teinte multiplicative de la mer du port (bleu profond, fiche série 17 §B).
var sea_tint: Color = Color(0.58, 0.68, 0.9)
## Cases de la coque et de l'accès au navire (ni sol, ni eau à border).
var hull_cells: Dictionary = {}
## Cases du platelage.
var plank_cells: Dictionary = {}


func _kind_of(mark: String) -> int:
	if mark == PORT_WATER_MARK or mark == HULL_MARK:
		return tiles.Kind.WATER
	return super(mark)


func _paint_logic(layer: TileMapLayer) -> void:
	super(layer)
	for cell: Vector2i in plan.call(&"cells_of", PORT_WATER_MARK + HULL_MARK + ACCESS_MARK):
		water_cells[cell] = true
	for cell: Vector2i in plan.call(&"cells_of", HULL_MARK + ACCESS_MARK):
		hull_cells[cell] = true
	for cell: Vector2i in plan.call(&"cells_of", PLANK_MARKS):
		plank_cells[cell] = true
		# Les planches sont un décor posé : le masque reste neutre dessous (pas de pavés).
		paved_cells.erase(cell)


func is_land(cell: Vector2i) -> bool:
	if hull_cells.has(cell):
		return false
	return super(cell)


func _skips_border_decal(cell: Vector2i) -> bool:
	return super(cell) or plank_cells.has(cell) or hull_cells.has(cell)


func _add_water(painted: Node2D) -> void:
	if not sea:
		super(painted)
		return
	if water_cells.is_empty():
		return
	var script := load("res://game/world/ground/ground_mask.gd") as GDScript
	painted.set(&"shore_mask", ImageTexture.create_from_image(
		script.call(&"build_water", size, water_cells) as Image))
	painted.set(&"foam_strength", sea_foam)
	painted.set(&"square_shore", true)


## Quais et berges sans la coque : les cases du navire ne reçoivent aucun module, et aucun
## module ne les borde. Bouts de pontons (étendue « au nord » d'au plus [constant
## PONTOON_END_MAX] cases, eau des deux côtés) : [constant WOOD_END].
func place_quays() -> int:
	for cell: Vector2i in hull_cells:
		water_cells.erase(cell)
	var count := super()
	for cell: Vector2i in hull_cells:
		water_cells[cell] = true
	return count


func _fill_run(side: StringName, run: Dictionary) -> void:
	var table: Dictionary = run.get("table", QUAY_PIECES)
	if side == &"n" and table == WOOD_PIECES and int(run["to"]) - int(run["from"]) + 1 \
			<= PONTOON_END_MAX:
		var line: int = run["line"]
		var left := Vector2i(int(run["from"]) - 1, line - 1)
		var right := Vector2i(int(run["to"]) + 1, line - 1)
		if not is_land(left) and not is_land(right):
			var end := table.duplicate(true)
			end[&"n"] = {"ids": [WOOD_END], "flip_h": false, "flip_v": false}
			run = run.duplicate()
			run["table"] = end
	super(side, run)


## Aplats multiplicatifs (bleu profond) sur les rectangles d'eau de la mer du port, dans
## `GroundDecals`, **avant** les planches et les bords de quai. Renvoie le nombre d'aplats.
func place_sea_tint() -> int:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	var index := 0
	for rect: Rect2i in rectangles(water_cells):
		var polygon := Polygon2D.new()
		polygon.name = "SeaTint%02d" % index
		index += 1
		var r := Rect2(rect.position * TILE, rect.size * TILE)
		polygon.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
			Vector2(r.position.x, r.end.y)])
		polygon.color = sea_tint
		polygon.material = material
		attach(decals, polygon)
	return index


## Platelage : un `Sprite2D` répété par rectangle de [member plank_cells] (planches est-ouest si
## le rectangle est plus large que haut, sinon nord-sud). Renvoie le nombre de rectangles.
func place_planks() -> int:
	var index := 0
	for rect: Rect2i in rectangles(plank_cells):
		var sprite := Sprite2D.new()
		sprite.name = "Planks%02d" % index
		index += 1
		sprite.texture = load(PLANKS_EW if rect.size.x >= rect.size.y else PLANKS_NS)
		sprite.centered = false
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, Vector2(rect.size * TILE))
		sprite.position = Vector2(rect.position * TILE)
		attach(decals, sprite)
	return index


## Découpe gloutonne de [param cells] en rectangles (rangée par rangée, de haut en bas) :
## chaque rectangle s'étend d'abord vers l'est, puis vers le sud tant que la rangée est pleine.
func rectangles(cells: Dictionary) -> Array[Rect2i]:
	var left: Dictionary = cells.duplicate()
	var result: Array[Rect2i] = []
	for y: int in size.y:
		for x: int in size.x:
			var start := Vector2i(x, y)
			if not left.has(start):
				continue
			var width := 1
			while left.has(start + Vector2i(width, 0)):
				width += 1
			var height := 1
			while true:
				var full := true
				for dx: int in width:
					if not left.has(start + Vector2i(dx, height)):
						full = false
						break
				if not full:
					break
				height += 1
			for dy: int in height:
				for dx: int in width:
					left.erase(start + Vector2i(dx, dy))
			result.append(Rect2i(start, Vector2i(width, height)))
	return result
