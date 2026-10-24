extends SceneTree
## Construit game/world/maps/route_16.tscn (Route 16 est, 44 × 28 cases) d'après la grille
## fonctionnelle `tools/plans/route_16.txt` (jalon 21 T22, docs/tech/jalon-21.md §2.10, §2.12 ;
## dossier 24 §9, §10.2).
##
##   godot --headless --path . -s res://tools/build_route_16.gd
##   godot --headless --path . --import
##   (première fois, ou si le masque change : relancer l'outil après l'import)
##   puis relancer `build_celadon_city.gd` (le raccord ouest de Céladopole n'est plus « à venir »).
##
## **La grille fait foi** ; art provisoire du kit existant (la vue peinte validée
## `docs/design/reference/route-16-vue-generale-v1.png` et les façades de la série 23 viendront avec
## le lot d'art). Même méthode que `build_route_7.gd` (kit `pewter_map_kit.gd`, forêt serrée).
##
## - `Ground` (invisible) = source logique : `=` `D` chemin, `Y` voie haute (herbe rase), `W` arbre à
##   Couper (praticable dans `Ground`, occupé par sa [FlagGate]) ; **tout le reste est solide** :
##   forêt `T`, clôtures `c`, affleurements `R`, façade `P`. Aucune herbe haute, aucune rencontre,
##   aucun Dresseur, aucun objet, aucun panneau (L-4 : aucun texte sur le Vélo).
## - Passages : bord est (43, 21..23) PUSH → `celadon_city` / `from_route_16[_n|_s]` (arrivées ici
##   `from_celadon[_n|_s]`, mêmes cases, tournées ←) ; portes du poste (bloc « J22 » ci-dessous).
## - Ronflex (§2.10) : [FlagGate] « Ronflex » `unless [snorlax_route_16_done]` (bloque ses 2 × 2
##   cases) dont l'enfant `Snorlax` (groupe `scene_props`) porte le sprite endormi ;
##   [InteractPoint] 2 × 2 `unless_flags [snorlax_route_16_done]`, dialogue `snorlax_route_16`,
##   `flute_cutscene` `snorlax_route_16_wake`.
## - Titre de zone : drapeau `route_16_visited` par une scène silencieuse sur la 2e colonne du
##   raccord (comme `celadon_reached`).
## - **Bloc « J22 »** (raccords J21 ↔ J22, 2026-10-23, `jalon-22.md` §0.5) : la Route 16 ouest est
##   une carte à part (`route_16_west`), jointe par le poste `route_16_gate` (deux couloirs séparés) :
##   porte basse (15..16, 20) STEP_ON ↑ → `entrance_bas_est[_1]` (arrivées ici `from_poste[_1]`,
##   parvis (15..16, 21), tournées ↓) ; porte haute (19..20, 13) STEP_ON ↓ → `entrance_haut_est[_1]`
##   (arrivées `from_poste_haut[_1]` (19..20, 12), tournées ↑) ; voie haute ouverte sans herbes [D] ;
##   arbre à Couper 2 × 2 : [FlagGate] `CutTree` `unless cut_route_16_tree` sur ses 4 cases et un
##   [InteractPoint] 2 × 2 `route_16_tree` (COUPER → `cut_tree_route_16`, `cut_tree.json`).
##   Relancer ensuite `build_j22_maps.gd` (le poste lit les arrivées d'ici).

const Kit := preload("res://tools/pewter_map_kit.gd")
const PLAN_PATH: String = "res://tools/plans/route_16.txt"
const OUT_PATH: String = "res://game/world/maps/route_16.tscn"
const MASK_PATH: String = "res://assets/world/maps/route_16_ground.png"
const NPCS_PATH: String = "res://data/npcs/route_16.json"
const MAPS_DIR: String = "res://game/world/maps/"
const SIZE := Vector2i(44, 28)
const SEED: int = 1601
const DECOR_SEED: int = 1602
const FOREST_SEED: int = 1603

const MAP_ID: StringName = &"route_16"
const DISPLAY_NAME: String = "Route 16"
const REGION: String = "Céladopole"
## `W` (arbre à Couper) est praticable dans `Ground` : sa [FlagGate] ferme ses cases.
const WALKABLE: String = "=DYW"
## Cases solides que la forêt serrée remplit (façade hors du bâtiment) ; les clôtures `c` et les
## affleurements `R` ont leurs propres objets.
const FOREST_EXTRA: String = "P"

const EAST_MAP: StringName = &"celadon_city"
## Raccord est : [nœud, arrivée ici, arrivée de Céladopole] (rangées 21, 22, 23 ; [D] : rangée du
## milieu = nom de la grille, les deux autres suffixées pour garder la rangée de sortie).
const EAST_EXITS: Array = [
	["CeladonN", &"from_celadon_n", &"from_route_16_n"],
	["CeladonC", &"from_celadon", &"from_route_16"],
	["CeladonS", &"from_celadon_s", &"from_route_16_s"],
]
const EAST_COMING_SOON: String = "Céladopole"
## Poste de la Route 16 (J22) : [position de la porte, position des arrivées ici, préfixe de nœud,
## pas, arrivée dans le poste, tournée là-bas, tournée ici]. Une arrivée par case (`<nom>`,
## `<nom>_1`), même rang des deux côtés (`build_j22_maps.gd` lit celles d'ici).
const POSTE_MAP: StringName = &"route_16_gate"
const POSTE_DOORS: Array = [
	["poste_route_16", "from_poste", "DoorPoste", Vector2i.UP, "entrance_bas_est", Vector2i.UP],
	["poste_haut", "from_poste_haut", "DoorPosteHaut", Vector2i.DOWN, "entrance_haut_est",
		Vector2i.DOWN],
]
## Arbre à Couper (J22) : [FlagGate] au pied de l'objet, son décor en enfant (sans emprise).
const TREE_FLAG: StringName = &"cut_route_16_tree"
const TREE_ID: String = "prop_jeune_arbre_arene_01"
const TREE_NODE: String = "CutTree"
const TREE_DIALOGUE: StringName = &"route_16_tree"
## Échelle du jeune arbre (2 cases de large) pour qu'il couvre son bloc de 2 × 2 [D].
const TREE_SCALE: float = 1.15
## Façade du poste : `bldg_velos_01` (8 × 7, porte de 2 cases) provisoire, ancre = case de la porte
## de droite ; remplacée par la façade de la série 23 [D].
const POSTE_FACADE: String = "bldg_velos_01"
const POSTE_NODE: String = "PostFacade"
## Départ de débogage `snorlax_16_qa` : devant Ronflex, tourné ←.
## `face_arbre` : sous l'arbre à Couper, tourné ↑ (QA de la Coupe).
const DEBUG_SPAWNS: Array = [["face_ronflex", Vector2i(26, 22)], ["face_arbre", Vector2i(38, 21)]]
## Titre de zone (drapeau `route_16_visited`) : scène silencieuse sur la 2e colonne du raccord.
const VISITED_CUTSCENE: StringName = &"route_16_visited"
const VISITED_ANCHOR := Vector2i(42, 23)
const VISITED_SIZE := Vector2i(1, 3)

## Ronflex (dossier 24 §9, plan du J21 §2.10).
const SNORLAX_FLAG: StringName = &"snorlax_route_16_done"
const SNORLAX_DIALOGUE: StringName = &"snorlax_route_16"
const SNORLAX_FLUTE_CUTSCENE: StringName = &"snorlax_route_16_wake"
const SNORLAX_FRAMES: String = "res://assets/sprites/pokemon/painted/snorlax_frames.tres"
const SHADOW_TEXTURE: String = "res://assets/sprites/characters/placeholder/shadow.png"
## `PropActor` (jalon 21 T19) : script du nœud `Snorlax` (réveil : saut et « ! »).
const PROP_ACTOR: String = "res://game/world/prop_actor.gd"
const SCENE_PROPS_GROUP: StringName = &"scene_props"

const RESERVED_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible", "cache"]
const BALL_KINDS: Array[String] = ["objet_visible", "cache"]
const FENCE_ID: String = "prop_cloture_01"
## Rangée de clôtures (rangée 24) : tronçons [x début, x fin] de la grille.
const FENCE_ROW: int = 24
const FENCE_SPANS: Array = [Vector2i(11, 21), Vector2i(28, 43)]
## « Forêt plus sèche » des routes voisines.
const SHADE_VALUE: float = 0.95
const SHADE_RED: float = 1.02
const SHADE_BLUE: float = 1.0

var _kit: Object
var _outcrops: Array[Array] = []


func _init() -> void:
	_kit = Kit.new(PLAN_PATH, SIZE, SEED, DECOR_SEED)
	if not (_kit.get(&"errors") as PackedStringArray).is_empty():
		push_error("build_route_16 : %s" % _kit.get(&"errors"))
		quit(1)
		return
	_kit.call(&"set_marks", WALKABLE, "", "")
	_reserve_positions()
	_kit.call(&"make_root", "Route16", MAP_ID, DISPLAY_NAME, REGION, &"golden_hour", NPCS_PATH)
	_kit.call(&"make_shade", SHADE_VALUE, SHADE_RED, SHADE_BLUE)
	_extend_forest()
	_classify_outcrops()
	if not _kit.call(&"add_ground", MASK_PATH, _kit.call(&"forest_undergrowth")):
		print("build_route_16 : masque écrit ; importer (--import) puis relancer l'outil")
		_kit.call(&"discard")
		quit(2)
		return
	var entities: Node2D = _kit.get(&"entities")
	var decals: Node2D = _kit.get(&"decals")
	_add_passages()
	_add_snorlax(entities)
	_add_tree_examine()
	_add_arrival_trigger()

	_kit.call(&"place_border_decals", SEED)
	var taken := _place_facade(entities)
	_place_tree(entities)
	_place_fences(entities)
	var rocks := _place_boulders(entities)
	var feet: Array[Vector2] = []
	var forest: Vector2i = _kit.call(&"place_forest", FOREST_SEED, feet, taken)

	var errors: PackedStringArray = _kit.get(&"errors")
	if not errors.is_empty():
		push_error("build_route_16 :\n" + "\n".join(errors))
		_kit.call(&"discard")
		quit(1)
		return
	var counts := Vector2i(entities.get_child_count(), decals.get_child_count())
	var result: Vector2i = _kit.call(&"save", OUT_PATH)
	print("route_16 : %s (%d entités, %d au sol, %d rochers, forêt %d → %d, %d nœuds)"
		% [error_string(result.x), counts.x, counts.y, rocks, forest.x, forest.y, result.y])
	quit(0 if result.x == OK else 1)


func _plan() -> Object:
	return _kit.get(&"plan")


func _built(map_id: StringName) -> bool:
	return ResourceLoader.exists(MAPS_DIR + "%s.tscn" % map_id)


## Cases des positions de la grille (Ronflex) : réservées à la forêt.
func _reserve_positions() -> void:
	var cells: Array[Vector2i] = []
	var balls: Array[Vector2i] = []
	var positions: Dictionary = _plan().get(&"positions")
	for id: String in positions:
		var kind: String = positions[id]["kind"]
		if RESERVED_KINDS.has(kind):
			cells.append_array(positions[id]["cells"])
		if BALL_KINDS.has(kind):
			balls.append_array(positions[id]["cells"])
	_kit.set(&"reserved_cells", cells)
	_kit.set(&"reserved_balls", balls)


## Voie haute, arbre à Couper en décor et bords de la façade : forêt serrée (décor bloquant, aucun
## examen). Les cases du bâtiment sont protégées ensuite par [method _place_facade] (`taken`).
func _extend_forest() -> void:
	var forest: Dictionary = _kit.get(&"forest_cells")
	for mark: String in FOREST_EXTRA:
		for cell: Vector2i in _plan().call(&"cells_of", mark):
			forest[cell] = true


# --- Passages et événements ---------------------------------------------------------------


func _add_passages() -> void:
	var east: Array[Vector2i] = _plan().call(&"cells_at", "warp_est")
	var city := _built(EAST_MAP)
	for i: int in east.size():
		var entry: Array = EAST_EXITS[i]
		_kit.call(&"add_spawn", entry[1], east[i])
		if city:
			_kit.call(&"add_warp", entry[0], east[i], Kit.PUSH, Vector2i.RIGHT, EAST_MAP,
				entry[2], Vector2i.RIGHT)
		else:
			_kit.call(&"add_warp", entry[0], east[i], Kit.PUSH, Vector2i.RIGHT, &"", entry[1],
				Vector2i.LEFT, EAST_COMING_SOON)
	# Bloc « J22 » : portes basse et haute du poste, case pour case (aucun texte sur le Vélo).
	for entry: Array in POSTE_DOORS:
		var doors: Array[Vector2i] = _plan().call(&"cells_at", entry[0])
		var backs: Array[Vector2i] = _plan().call(&"cells_at", entry[1])
		for i: int in doors.size():
			var suffix := "" if i == 0 else "_%d" % i
			_kit.call(&"add_spawn", entry[1] + suffix, backs[i])
			_kit.call(&"add_warp", "%s%d" % [entry[2], i], doors[i], Kit.STEP_ON, entry[3],
				POSTE_MAP, StringName(entry[4] + suffix), entry[5])
	for entry: Array in DEBUG_SPAWNS:
		_kit.call(&"add_spawn", entry[0], entry[1])


## Scène silencieuse du titre de zone : `route_16_visited`.
func _add_arrival_trigger() -> void:
	_kit.call(&"add_trigger", "Arrival", VISITED_ANCHOR, VISITED_SIZE, Vector2i.LEFT,
		VISITED_CUTSCENE)


## Examen de l'arbre à Couper (J22) : un point 2 × 2, lu depuis la route comme depuis la voie
## haute, retiré avec lui (`unless cut_route_16_tree`).
func _add_tree_examine() -> void:
	var cells: Array[Vector2i] = _plan().call(&"cells_at", "arbre_coupe")
	_kit.call(&"add_interactable", "CutTreeExamine", cells[-2], Vector2i(2, 2), Vector2i.ZERO,
		TREE_DIALOGUE)
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	var unless: Array[StringName] = [TREE_FLAG]
	point.set(&"unless_flags", unless)


# --- Ronflex ------------------------------------------------------------------------------


## [FlagGate] « Ronflex » (cases bloquées 2 × 2 tant que `snorlax_route_16_done` n'est pas levé),
## son enfant `Snorlax` (groupe `scene_props`, sprite endormi qui respire) et le point d'examen
## 2 × 2.
func _add_snorlax(entities: Node2D) -> void:
	var cells: Array[Vector2i] = _plan().call(&"cells_at", "ronflex_16")
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = "Ronflex"
	# Pieds au milieu du bas du bloc 2 × 2 (bord entre les colonnes 24 et 25, bas de la rangée 23).
	gate.position = Vector2(float(cells[-1].x * Kit.TILE), float((cells[-1].y + 1) * Kit.TILE))
	var unless: Array[StringName] = [SNORLAX_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = []
	blocking.assign(cells)
	gate.set(&"blocking_cells", blocking)
	_kit.call(&"attach", entities, gate)
	var snorlax := Node2D.new()
	snorlax.name = "Snorlax"
	snorlax.set_script(load(PROP_ACTOR))
	_kit.call(&"attach", gate, snorlax)
	snorlax.add_to_group(SCENE_PROPS_GROUP, true)
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = load(SHADOW_TEXTURE)
	shadow.position = Vector2(0.0, -8.0)
	shadow.scale = Vector2(3.4, 2.6)
	_kit.call(&"attach", snorlax, shadow)
	var frames := load(SNORLAX_FRAMES) as SpriteFrames
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	sprite.animation = &"idle_down"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.offset = Vector2(0.0, -frames.get_frame_texture(&"idle_down", 0).get_size().y / 2.0)
	_kit.call(&"attach", snorlax, sprite)
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
	_kit.call(&"attach", snorlax, player)
	# EXAMINER ou jouer la Flûte depuis les cases voisines (de tous côtés) tant que `_done` n'est
	# pas levé ; ancre = case en bas à gauche du bloc.
	_kit.call(&"add_interactable", "SnorlaxPoint", cells[-2], Vector2i(2, 2), Vector2i.ZERO,
		SNORLAX_DIALOGUE)
	var point: Node = _kit.get(&"root").get_node(^"Interactables").get_child(-1)
	point.set(&"unless_flags", unless)
	point.set(&"flute_cutscene", SNORLAX_FLUTE_CUTSCENE)


# --- Décor --------------------------------------------------------------------------------


## Façade du poste : bâtiment provisoire sur l'emprise `P`, porte aux cases (15..16, 20). Renvoie
## les cases qu'il couvre (aucun arbre dessous).
func _place_facade(entities: Node2D) -> Dictionary:
	var taken: Dictionary = {}
	var rules: GDScript = _kit.get(&"rules")
	var doors: Array[Vector2i] = _plan().call(&"cells_at", "poste_route_16")
	var anchor: Vector2i = doors[-1]
	_kit.call(&"add_prop_at", entities, POSTE_FACADE, anchor, POSTE_NODE)
	for offset: Vector2i in rules.call(&"footprint", StringName(POSTE_FACADE)):
		taken[anchor + offset] = true
	return taken


## Arbre à Couper (J22) : une [FlagGate] `unless cut_route_16_tree` dont `blocking_cells` ferment
## ses 2 × 2 cases et dont le décor est le jeune arbre peint (sans emprise), pied au milieu du bas
## du bloc (contrat du J16, comme l'arbre de la sortie est d'Azuria).
func _place_tree(entities: Node2D) -> void:
	var cells: Array[Vector2i] = _plan().call(&"cells_at", "arbre_coupe")
	var rules: GDScript = _kit.get(&"rules")
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = TREE_NODE
	gate.position = (rules.call(&"foot_position", StringName(TREE_ID), cells[-1]) as Vector2) \
		.round()
	var unless: Array[StringName] = [TREE_FLAG]
	gate.set(&"unless_flags", unless)
	var blocking: Array[Vector2i] = []
	blocking.assign(cells)
	gate.set(&"blocking_cells", blocking)
	_kit.call(&"attach", entities, gate)
	var tree: Node2D = _kit.call(&"add_prop", gate, TREE_ID, Vector2.ZERO, "Tree")
	_kit.call(&"clear_footprint", tree)
	tree.scale = Vector2(TREE_SCALE, TREE_SCALE)


## Clôtures de bois (rangée 24) : modules de 4 cases bout à bout (le dernier recouvre le précédent).
func _place_fences(entities: Node2D) -> void:
	var index := 0
	for span: Vector2i in FENCE_SPANS:
		var at := span.x
		while at <= span.y:
			var left := at if at + 3 <= span.y else span.y - 3
			_kit.call(&"add_prop_at", entities, FENCE_ID, Vector2i(left + 2, FENCE_ROW),
				"Fence%02d" % index)
			index += 1
			at += 4


## Affleurements `R` (goulet) : composantes connexes, rochers de 2 × 1 ou rocher réduit.
func _classify_outcrops() -> void:
	var left: Dictionary = {}
	for cell: Vector2i in _plan().call(&"cells_of", "R"):
		left[cell] = true
	while not left.is_empty():
		var start: Vector2i = left.keys()[0]
		left.erase(start)
		var component: Array[Vector2i] = [start]
		var stack: Array[Vector2i] = [start]
		while not stack.is_empty():
			var cell: Vector2i = stack.pop_back()
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next := cell + side
				if left.has(next):
					left.erase(next)
					component.append(next)
					stack.append(next)
		component.sort()
		_outcrops.append(component)


func _place_boulders(entities: Node2D) -> int:
	var rules: GDScript = _kit.get(&"rules")
	var decor: RandomNumberGenerator = _kit.get(&"decor_rng")
	var index := 0
	for component: Array in _outcrops:
		var free: Dictionary = {}
		for cell: Vector2i in component:
			free[cell] = true
		var order: Array = component.duplicate()
		order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y > b.y or (a.y == b.y and a.x < b.x))
		for cell: Vector2i in order:
			if not free.has(cell):
				continue
			var placed := false
			for id: String in ["prop_grande_pierre_01", "prop_rocher_01"]:
				var footprint: Array[Vector2i] = rules.call(&"footprint", StringName(id))
				for align: Vector2i in footprint:
					var anchor := cell - align
					var fits := true
					for offset: Vector2i in footprint:
						fits = fits and free.has(anchor + offset)
					if not fits:
						continue
					var rock: Node2D = _kit.call(&"add_prop_at", entities, id, anchor,
						"Rock%02d" % index)
					_style_rock(rock, decor, 0.9 if id == "prop_grande_pierre_01" else 1.0)
					for offset: Vector2i in footprint:
						free.erase(anchor + offset)
					placed = true
					break
				if placed:
					break
			if not placed:
				var foot := Vector2(cell.x + decor.randf_range(0.35, 0.65),
					cell.y + decor.randf_range(0.85, 1.0))
				var small: Node2D = _kit.call(&"add_prop", entities, "prop_rocher_01",
					foot * Kit.TILE, "Rock%02d" % index)
				_kit.call(&"clear_footprint", small)
				_style_rock(small, decor, 0.62)
				free.erase(cell)
			index += 1
	return index


func _style_rock(rock: Node2D, decor: RandomNumberGenerator, scale: float) -> void:
	var s := scale * decor.randf_range(0.92, 1.08)
	rock.scale = Vector2(s, s)
	_kit.call(&"flip", rock, decor.randf() < 0.5)
	var value := decor.randf_range(0.9, 1.0)
	rock.modulate = Color(value, value, value)
