extends SceneTree
## Construit game/world/maps/route_12.tscn (Route 12 nord, 39 × 102 cases) d'après la grille
## fonctionnelle `tools/plans/route_12.txt` (jalon 21 T21, docs/tech/jalon-21.md §2.10, §2.11 ;
## dossier 24 §9, §10.1, §15.8, §19 ; décision M-3 de Kevin, 2026-10-16 : Ronflex dort au
## croisement de la Route 11).
##
##   godot --headless --path . -s res://tools/build_route_12.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import ; code 2 = masque
##   écrit, importer puis relancer)
##
## **La grille fait foi** (géométrie, positions, passages) ; la vue générale peinte validée
## (`docs/design/reference/route-12-vue-generale-v1.png`) donne la DA. Boîte à outils côtière
## (`tools/coast_map_kit.gd`, modèle `build_route_11.gd`) :
## - `Ground` (invisible) = source logique : `.` `=` `D` praticables ; `w` eau (solide,
##   `GridWorld.is_water`) ; `T` forêt, `R` rive rocheuse, `P` poste, `i` îlot : solides. **Aucune
##   herbe, aucune table de rencontres** (RB : les herbes sont au sud du croisement, J22).
## - Image : sol peint (terre de la berge nord et de la chaussée de la Route 11, mer de Bourg
##   Palette à angles droits), forêt serrée, rive rocheuse en modules, **ponton** = planches du
##   quai en rectangles répétés (un `Sprite2D` par rectangle, comme le platelage de Carmin),
##   poste (image du poste de la Forêt de Jade agrandie à 9 cases [D]), panneaux, Ronflex endormi.
## - Passages : nord (21..23, 0) PUSH ↑ → `lavender_town` / `from_route_12_w|c|e` ; ouest
##   (0, 93..94) PUSH ← → `route_11` / `from_route_12_n|s` ; sud (25..26, 101) PUSH ↓ « ROUTE 12 —
##   À venir » (`coming_soon`, le J22 le remplacera ; arrivées `from_route_12_sud`) ; portes du
##   poste (24..26, 24) et (24..26, 32) STEP_ON → `route_12_gate` / `entrance_nord|sud`.
## - Ronflex : `FlagGate` « Ronflex » (`unless snorlax_route_12_done`, bloque ses 2 × 2 cases) qui
##   porte le nœud `Snorlax` (groupe `scene_props`) ; `InteractPoint` 2 × 2 `snorlax_route_12`,
##   `flute_cutscene = snorlax_route_12_wake`.
## - Lumière `golden_hour` [D], fond de combat `route_24_pont` [D] (`data/battle/decors.json`),
##   aucun halo, aucune `Light2D`.

const Kit := preload("res://tools/coast_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_12.txt"
const OUT_PATH: String = "res://game/world/maps/route_12.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_12_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_12.json"
const SIZE := Vector2i(39, 102)
const SEED: int = 1201
const DECOR_SEED: int = 1202
const FOREST_SEED: int = 12
const SHORE_SEED: int = 1204

const MAP_ID: StringName = &"route_12"
const DISPLAY_NAME: String = "Route 12"
const REGION: String = "Lavanville — Route 11"
const WALKABLE: String = ".=D"

## Raccord nord : une arrivée de Lavanville par colonne (`from_lavender_w|c|e`, plus `from_lavender`
## au centre), retour Lavanville `from_route_12_w|c|e` (case (21..23, 34)).
const NORTH_MAP: StringName = &"lavender_town"
const SUFFIXES_H: Array[String] = ["w", "c", "e"]
## Raccord ouest : [nœud, case, spawn de la Route 11 (retour), spawn d'ici].
const WEST_EXITS: Array = [
	["Route11N", Vector2i(0, 93), &"from_route_12_n", "from_route_11_n"],
	["Route11S", Vector2i(0, 94), &"from_route_12_s", "from_route_11_s"],
]
const WEST_MAP: StringName = &"route_11"
const SOUTH_COMING_SOON: String = "Route 12"
## Portes du poste : [préfixe de nœud, rangée, direction du pas, spawn intérieur, rangée de sortie,
## préfixe des spawns de sortie].
const POST_DOORS: Array = [
	["PostNorth", 24, Vector2i.DOWN, &"entrance_nord", 23, "from_poste_nord"],
	["PostSouth", 32, Vector2i.UP, &"entrance_sud", 33, "from_poste_sud"],
]
const POST_MAP: StringName = &"route_12_gate"

const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
## Panneaux : [position, nœud du décor, dialogue]. Lus depuis la case au nord, tournés vers le sud.
const SIGNS: Array = [
	["panneau_route_12", "SignRoad", &"route_12_sign"],
	["panneau_ponton", "SignPier", &"route_12_pier_sign"],
]

## Poste : l'image du poste de la Forêt de Jade (vue du nord : toit, lucarne, passage en bas)
## agrandie à la largeur de l'emprise (9 cases) [D] ; pied posé pour que le bas de l'image soit
## sur le bord sud de la rangée 32.
const POST_ID: String = "bldg_poste_foret_nord_01"
const POST_SCALE: float = 9.0 / 7.0
const POST_CENTRE_X: float = 25.5
const POST_FOOT_Y: float = 33.0 - 138.0 * POST_SCALE / 96.0

## Ponton : planches du quai (est-ouest sur les bras, nord-sud sur les troncs).
const PLANKS_EW: String = "res://assets/world/ground/ground_planches_quai_01.png"
const PLANKS_NS: String = "res://assets/world/ground/ground_planches_quai_ns_01.png"
## Rangées de la berge de terre : (nord) 0..5 ; chaussée de la Route 11 et croisement : 93..95.
const EARTH_ROWS: Array[Vector2i] = [Vector2i(0, 5), Vector2i(93, 95)]
## Entre ces rangées, les `.` de la grille sont des placettes de ponton (planches).
const DECK_ROWS := Vector2i(6, 92)

## Ronflex endormi : apparence peinte du J17 (série 19), drapeaux du M-3.
const SNORLAX_DONE: StringName = &"snorlax_route_12_done"
const SNORLAX_FRAMES: String = "res://assets/sprites/pokemon/painted/snorlax_frames.tres"
const SHADOW_TEXTURE: String = "res://assets/sprites/characters/placeholder/shadow.png"
const SNORLAX_DIALOGUE: StringName = &"snorlax_route_12"
const SNORLAX_WAKE: StringName = &"snorlax_route_12_wake"
const REACHED_CUTSCENE: StringName = &"route_12_visited"

## Forêt « plus sèche » (même valeurs que les routes voisines).
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0

var _kit: Object


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED, SHORE_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_12 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "K", "")
	_reserve_positions()
	_kit.call(&"make_root", "Route12", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	var planks := _prepare_cells()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_route_12 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_examine_points()

	_kit.call(&"place_border_decals", SEED)
	var shore: int = _kit.call(&"place_shore")
	var decks := _place_planks(decals, planks)
	_add_post(entities)
	for entry: Array in SIGNS:
		_kit.call(&"add_prop_at", entities, "prop_panneau_01", _cell(entry[0]), entry[1])
	_add_snorlax(entities)
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, {})

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_12 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_12 : %s (%d entités, %d au sol dont %d modules de rivage et %d rectangles de "
		% [error_string(result.x), counts.x, counts.y, shore, decks]
		+ "ponton, forêt %d → %d, %d nœuds)" % [forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _cell(id: String) -> Vector2i:
	return _plan().call(&"cell_of", id)


## Cases des PNJ, Pokémon et objets de la grille : réservées (la forêt s'en écarte).
func _reserve_positions() -> void:
	var cells: Array[Vector2i] = []
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		if RESERVED_KINDS.has(positions[id]["kind"]):
			cells.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", cells)
	_kit.set(&"reserved_balls", [] as Array[Vector2i])


## Chemin de terre (masque) : les `.` de la berge nord et de la chaussée de la Route 11 ; le
## ponton (`=`, placettes, portes, poste, îlot) est peint en planches (renvoie ses cases) et ne
## garde pas de chemin de terre sous lui.
func _prepare_cells() -> Dictionary:
	var path: Dictionary = _kit.get(&"path_cells")
	path.clear()
	var planks: Dictionary = {}
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var mark: String = _plan().call(&"at", cell)
			var earth := false
			for rows: Vector2i in EARTH_ROWS:
				earth = earth or (y >= rows.x and y <= rows.y)
			match mark:
				".":
					if earth:
						path[cell] = true
					else:
						planks[cell] = true
				"=", "D", "P", "i":
					planks[cell] = true
	return planks


# --- Passages et points d'examen --------------------------------------------------------------


func _add_passages() -> void:
	# Nord : Lavanville. Arrivées `from_lavender_w|c|e` (+ `from_lavender` au centre), tournées ↓.
	var north: Array[Vector2i] = _plan().call(&"cells_at", "warp_nord")
	for i: int in north.size():
		var suffix: String = SUFFIXES_H[i]
		_kit.call(&"add_spawn", "from_lavender_" + suffix, north[i])
		_kit.call(&"add_warp", "Lavender" + suffix.to_upper(), north[i], Kit.PUSH, Vector2i.UP,
			NORTH_MAP, StringName("from_route_12_" + suffix), Vector2i.UP)
	_kit.call(&"add_spawn", "from_lavender", north[1])
	# Ouest : la Route 11, rangée par rangée ; arrivée tournée vers l'est (la chaussée).
	for entry: Array in WEST_EXITS:
		_kit.call(&"add_spawn", entry[3], entry[1])
		_kit.call(&"add_warp", entry[0], entry[1], Kit.PUSH, Vector2i.LEFT, WEST_MAP, entry[2],
			Vector2i.RIGHT)
	_kit.call(&"add_spawn", "from_route_11", WEST_EXITS[0][1])
	# Sud : « ROUTE 12 — À venir » ; retour une case au nord, tourné ↑ (J22 : warp réel).
	var south: Array[Vector2i] = _plan().call(&"cells_at", "warp_sud")
	var south_back: Array[Vector2i] = _plan().call(&"cells_at", "from_route_12_sud")
	for i: int in south.size():
		var name := "from_route_12_sud" + ("" if i == 0 else "_e")
		_kit.call(&"add_spawn", name, south_back[i])
		_kit.call(&"add_warp", "South%d" % i, south[i], Kit.PUSH, Vector2i.DOWN, &"",
			StringName(name), Vector2i.UP, SOUTH_COMING_SOON)
	# Poste : trois cases de porte par côté (STEP_ON) ; sorties `from_poste_*` (centre sans suffixe).
	for door: Array in POST_DOORS:
		var row: int = door[1]
		var out_row: int = door[4]
		for i: int in 3:
			_kit.call(&"add_warp", "%s%s" % [door[0], SUFFIXES_H[i].to_upper()],
				Vector2i(24 + i, row), Kit.STEP_ON, door[2], POST_MAP, door[3], door[2])
			_kit.call(&"add_spawn", "%s_%s" % [door[5], SUFFIXES_H[i]], Vector2i(24 + i, out_row))
		_kit.call(&"add_spawn", door[5], Vector2i(25, out_row))
	# Déclencheurs silencieux de `route_12_visited` (titre d'arrivée déjà annoncé par la zone).
	_kit.call(&"add_trigger", "VisitedNorth", Vector2i(21, 1), Vector2i(3, 1), Vector2i.ZERO,
		REACHED_CUTSCENE)
	_kit.call(&"add_trigger", "VisitedWest", Vector2i(1, 94), Vector2i(1, 2), Vector2i.ZERO,
		REACHED_CUTSCENE)


## Panneaux : lus depuis la case au nord, tournés vers le sud (grille : `panneau_*`).
func _add_examine_points() -> void:
	for entry: Array in SIGNS:
		_kit.call(&"add_interactable", String(entry[1]) + "Point", _cell(entry[0]), Vector2i.ONE,
			Vector2i.DOWN, entry[2])


# --- Décor ------------------------------------------------------------------------------------


## Ponton : un `Sprite2D` répété par rectangle de planches (est-ouest si plus large que haut,
## sinon nord-sud), dans `GroundDecals` après les modules de rivage. Renvoie le nombre de rectangles.
func _place_planks(decals: Node2D, planks: Dictionary) -> int:
	var index := 0
	for rect: Rect2i in _rectangles(planks):
		var sprite := Sprite2D.new()
		sprite.name = "Planks%02d" % index
		index += 1
		sprite.texture = load(PLANKS_EW if rect.size.x >= rect.size.y else PLANKS_NS)
		sprite.centered = false
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, Vector2(rect.size * Kit.TILE))
		sprite.position = Vector2(rect.position * Kit.TILE)
		_kit.call(&"attach", decals, sprite)
	return index


## Découpe gloutonne de [param cells] en rectangles (rangée par rangée, de haut en bas).
func _rectangles(cells: Dictionary) -> Array[Rect2i]:
	var left: Dictionary = cells.duplicate()
	var result: Array[Rect2i] = []
	for y: int in SIZE.y:
		for x: int in SIZE.x:
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


## Poste (9 × 9, `facade_poste`) : image agrandie, sans emprise propre (les cases sont bloquées par
## la grille ; les cases de porte restent praticables).
func _add_post(entities: Node2D) -> void:
	var foot := Vector2(POST_CENTRE_X * Kit.TILE, POST_FOOT_Y * Kit.TILE)
	var post: Node2D = _kit.call(&"add_prop", entities, POST_ID, foot, "Post")
	_kit.call(&"clear_footprint", post)
	post.scale = Vector2.ONE * POST_SCALE


## Ronflex du croisement (M-3) : `FlagGate` « Ronflex » (bloque ses 2 × 2 cases tant que
## `snorlax_route_12_done` est absent), nœud `Snorlax` (groupe `scene_props`) = image endormie +
## ombre + respiration, et `InteractPoint` 2 × 2 (on lui parle, ou on lui joue la Flûte, depuis les
## cases `face_ronflex`). Les cases sont celles de la position `ronflex_12`.
func _add_snorlax(entities: Node2D) -> void:
	var cells: Array[Vector2i] = _plan().call(&"cells_at", "ronflex_12")
	var anchor := Vector2i(cells[0].x, cells[0].y)
	var bottom := 0
	for cell: Vector2i in cells:
		anchor.x = mini(anchor.x, cell.x)
		bottom = maxi(bottom, cell.y)
	anchor.y = bottom
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "Ronflex"
	# Pieds au milieu du bas du bloc 2 × 2 (bord entre les deux colonnes, bas de la rangée basse).
	gate.position = Vector2(float((anchor.x + 1) * Kit.TILE), float((bottom + 1) * Kit.TILE))
	var unless: Array[StringName] = [SNORLAX_DONE]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = []
	blocking.assign(cells)
	gate.set(&"blocking_cells", blocking)
	_kit.call(&"attach", entities, gate)
	# Jalon 21 (T20) : `PropActor` (`react()` / `show_emote()` pour la scène du réveil).
	var body := Node2D.new()
	body.set_script(load("res://game/world/prop_actor.gd"))
	body.name = "Snorlax"
	body.add_to_group(&"scene_props", true)
	_kit.call(&"attach", gate, body)
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = load(SHADOW_TEXTURE)
	shadow.position = Vector2(0.0, -8.0)
	shadow.scale = Vector2(3.4, 2.6)
	_kit.call(&"attach", body, shadow)
	var frames := load(SNORLAX_FRAMES) as SpriteFrames
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	sprite.animation = &"idle_down"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.offset = Vector2(0.0, -frames.get_frame_texture(&"idle_down", 0).get_size().y / 2.0)
	_kit.call(&"attach", body, sprite)
	# Respiration lente : une pose, le sprite gonfle de 3 % de sa hauteur toutes les 4 s.
	var breath := Animation.new()
	breath.length = 4.0
	breath.loop_mode = Animation.LOOP_LINEAR
	var track := breath.add_track(Animation.TYPE_VALUE)
	breath.track_set_path(track, NodePath("Sprite:scale"))
	breath.track_insert_key(track, 0.0, Vector2.ONE)
	breath.track_insert_key(track, 2.0, Vector2(1.012, 1.03))
	breath.track_insert_key(track, 4.0, Vector2.ONE)
	var library := AnimationLibrary.new()
	library.add_animation(&"breathe", breath)
	var player := AnimationPlayer.new()
	player.name = "Breath"
	player.add_animation_library(&"", library)
	player.autoplay = &"breathe"
	_kit.call(&"attach", body, player)
	# EXAMINER / Flûte depuis les trois côtés : texte T-6 puis T-7, ou le choix de la Flûte.
	_kit.call(&"add_interactable", "SnorlaxPoint", anchor, Vector2i(2, 2), Vector2i.ZERO,
		SNORLAX_DIALOGUE)
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	point.set(&"unless_flags", unless)
	point.set(&"flute_cutscene", SNORLAX_WAKE)
