extends SceneTree
## Construit les cartes du jalon JOH6 (Chapitre Johto, « les cendres », `docs/tech/jalon-joh6.md`
## §2.1 et §2.2) d'après leurs grilles fonctionnelles (`tools/plans/burned_tower_1f.txt`,
## `burned_tower_b1f.txt`, `route_42.txt`, `mahogany_town.txt`, `mahogany_souvenir_shop.txt`,
## `route_43.txt`, `lake_of_rage.txt`, `mahogany_hideout_b1f.txt` à `b3f.txt` : **la grille fait
## foi**), en **tuiles provisoires** (`OverworldTiles` dehors, dans la Tour et le repaire ;
## `InteriorTiles` dans la boutique et le décor du souvenir) : le code ne bloque jamais sur l'art.
##
##   godot --headless --path . -s res://tools/build_joh6_maps.gd [-- --maps=route_42,lake_of_rage]
##   godot --headless --path . --import
##
## **Passe de peinture à relancer après cet outil** (il reconstruit les cartes en tuiles et en
## aplats provisoires : toute image peinte posée par-dessus est perdue). Dans l'ordre :
##   godot --headless --path . -s res://tools/build_joh_ambiance_caves.gd -- \
##     --maps=burned_tower_1f,burned_tower_b1f,mahogany_hideout_b1f,mahogany_hideout_b2f,mahogany_hideout_b3f
##   godot --headless --path . -s res://tools/build_joh6_paint_shop.gd
## (code 2 de la première : images écrites, `--import` puis relancer). Les aplats des [FlagGate], des
## dalles tournantes et des trous FALL gardent leur logique, la passe n'en remplace que le dessin.
## Routes 42 et 43, Lac Colère et Acajou ont leur propre passe de peinture (`tools/build_joh_ambiance*`).
##
## Construire d'abord les intérieurs d'Acajou (`build_painted_interiors.gd --acajou`) : leurs
## arrivées (`entrance`) sont lues dans les scènes enregistrées.
##
## Données lues ailleurs (`tools/gen_joh6_data.py`, `tools/gen_joh6_story.py`) : PNJ, Dresseurs,
## objets visibles, chiens, Léviator rouge, Raikou (`data/npcs/<carte>.json`), textes et scènes.
## Ici : sol et cases bloquées ; eau `w` surfable (tuile WATER) ; cases calmes (dallage de la Tour)
## ; passages (bord = PUSH, porte = STEP_ON ↑, sortie d'intérieur = PUSH ↓, escalier = STEP_ON
## sans direction, trou = FALL ; destination absente = « À venir ») ; arrivées (une par case) ;
## panneaux, examens, caches, interrupteurs ; déclencheurs des scènes ; portes à drapeau
## ([FlagGate] : étagère de la boutique, porte à mot de passe, grille de la cellule, barreaux de
## la cage) ; dalles tournantes ([SpinTileField] `SpinTiles`) ; décors provisoires en aplats
## (poutres, trous, statues de Persian, générateur, cage, poste de péage, antenne) ; bâtiments du
## kit peint de Kanto [D] ; lampes de nuit.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")

const TILE: int = 96
const PLANS_DIR: String = "res://tools/plans/"
const MAPS_DIR: String = "res://game/world/maps/"
const PROPS_DIR: String = "res://game/world/props/painted/"
const SIGN_PROP: String = "prop_panneau_01"
const NIGHT_LIGHTS: StringName = &"night_lights"
## Warp.Trigger (valeurs).
const STEP_ON: int = 0
const PUSH: int = 1
const FALL: int = 2

## Cartes : grille, identifiant, nom, sous-titre, style de tuiles, lumière, intérieur, graine.
## Style : « outdoor » (dehors), « tower » (Tour Cendrée), « hideout » (repaire), « shop »
## (boutique, coque intérieure).
const MAPS: Array[Dictionary] = [
	{"plan": "burned_tower_1f", "id": &"burned_tower_1f", "name": "Tour Cendrée",
		"region": "Rosalia", "style": "tower", "light": &"johto_auto", "seed": 6101},
	{"plan": "burned_tower_b1f", "id": &"burned_tower_b1f", "name": "Tour Cendrée",
		"region": "Sous-sol", "style": "tower", "light": &"cave_b1f", "seed": 6102},
	{"plan": "route_42", "id": &"route_42", "name": "Route 42", "region": "Rosalia — Acajou",
		"style": "outdoor", "light": &"johto_auto", "seed": 6201},
	{"plan": "mahogany_town", "id": &"mahogany_town", "name": "Acajou", "region": "Johto",
		"style": "outdoor", "light": &"johto_auto", "seed": 6301},
	{"plan": "mahogany_souvenir_shop", "id": &"mahogany_souvenir_shop",
		"name": "Acajou", "region": "Boutique de souvenirs", "style": "shop",
		"light": &"interior_warm", "interior": true, "seed": 6302},
	{"plan": "route_43", "id": &"route_43", "name": "Route 43", "region": "Acajou — Lac Colère",
		"style": "outdoor", "light": &"johto_auto", "seed": 6401},
	{"plan": "lake_of_rage", "id": &"lake_of_rage", "name": "Lac Colère", "region": "Johto",
		"style": "outdoor", "light": &"johto_auto", "seed": 6501},
	{"plan": "mahogany_hideout_b1f", "id": &"mahogany_hideout_b1f", "name": "Repaire Rocket",
		"region": "B1F", "style": "hideout", "light": &"hideout", "seed": 6601},
	{"plan": "mahogany_hideout_b2f", "id": &"mahogany_hideout_b2f", "name": "Repaire Rocket",
		"region": "B2F", "style": "hideout", "light": &"hideout", "seed": 6602},
	{"plan": "mahogany_hideout_b3f", "id": &"mahogany_hideout_b3f", "name": "Repaire Rocket",
		"region": "B3F", "style": "hideout", "light": &"hideout", "seed": 6603},
]

## Dehors : caractère → type de tuile (nom de [enum OverworldTiles.Kind]).
const OUTDOOR_KINDS: Dictionary = {
	".": "GRASS", "=": "DIRT", "h": "TALL_GRASS", "p": "COBBLE", "D": "COBBLE", "T": "FOREST",
	"x": "FOREST", "G": "FOREST", "R": "CLIFF", "w": "WATER", "Q": "CLIFF", "o": "CLIFF",
	"K": "CLIFF", "C": "CLIFF", "O": "CLIFF", "m": "CLIFF", "N": "CLIFF",
}
## Tour et repaire : mêmes tuiles provisoires, sol de pierre ou de cendres.
const TOWER_KINDS: Dictionary = {
	"#": "CLIFF", ".": "COBBLE", "c": "DIRT", "P": "CLIFF", "O": "DIRT", "V": "COBBLE",
	"U": "COBBLE", "E": "COBBLE",
}
const HIDEOUT_KINDS: Dictionary = {
	"#": "CLIFF", ".": "COBBLE", "M": "CLIFF", "X": "CLIFF", "S": "CLIFF", "<": "BOARDWALK",
	">": "BOARDWALK", "^": "BOARDWALK", "v": "BOARDWALK", "o": "COBBLE", "K": "COBBLE", "c": "CLIFF",
	"p": "CLIFF", "U": "COBBLE", "D": "COBBLE",
}
## Boutique (InteriorTiles) : murs, sol, tapis de sortie ; le reste (meubles) bloqué.
const SHOP_WALLS: String = "K"
const SHOP_MATS: String = "X"

const ARROWS: Dictionary = {
	"<": Vector2i.LEFT, ">": Vector2i.RIGHT, "^": Vector2i.UP, "v": Vector2i.DOWN,
}
const ARROW_DECALS: Dictionary = {
	"<": "decal_fleche_repaire_01_gauche", ">": "decal_fleche_repaire_01",
	"^": "decal_fleche_repaire_01_haut", "v": "decal_fleche_repaire_01_bas",
}
const STOP_DECAL: String = "decal_arret_repaire_01"

## Passages des bords et des portes : (carte, position) → carte cible, arrivée, libellé « À
## venir ». Les escaliers et les trous lisent leur cible dans la grille (« vers= »).
const WARPS: Dictionary = {
	"burned_tower_1f/sortie": {"to": &"ecruteak_city", "spawn": "retour_tour_cendree",
		"exit": true},
	"route_42/warp_ouest": {"to": &"ecruteak_city", "spawn": "from_route_42"},
	"route_42/warp_est": {"to": &"mahogany_town", "spawn": "from_route_42"},
	"mahogany_town/warp_ouest": {"to": &"route_42", "spawn": "from_mahogany"},
	"mahogany_town/warp_nord": {"to": &"route_43", "spawn": "from_mahogany"},
	"mahogany_town/porte_centre": {"to": &"mahogany_center", "spawn": "entrance"},
	"mahogany_town/porte_boutique": {"to": &"mahogany_souvenir_shop", "spawn": "entrance"},
	"mahogany_town/porte_maison_1": {"to": &"mahogany_house_1", "spawn": "entrance"},
	"mahogany_town/porte_maison_2": {"to": &"mahogany_house_2", "spawn": "entrance"},
	"route_43/warp_sud": {"to": &"mahogany_town", "spawn": "from_route_43"},
	"route_43/warp_nord": {"to": &"lake_of_rage", "spawn": "from_route_43"},
	"lake_of_rage/warp_sud": {"to": &"route_43", "spawn": "from_lake"},
	"lake_of_rage/warp_sentier": {"to": &"silver_trail", "spawn": "from_lake",
		"label": "Sentier du Mont Argenté"},
	"mahogany_souvenir_shop/sortie": {"to": &"mahogany_town", "spawn": "retour_boutique",
		"exit": true},
}
## Déclencheurs : (carte, position) → scène, sens du pas (ZERO = toutes directions). Une position
## absente de cette table n'a pas de scène (titre d'Acajou : annonce de zone ordinaire).
const TRIGGERS: Dictionary = {
	"burned_tower_1f/plancher_effondre": {"scene": &"burned_tower_floor", "dir": Vector2i.ZERO},
	"burned_tower_b1f/scene_chiens": {"scene": &"burned_tower_beasts", "dir": Vector2i.ZERO},
	"mahogany_souvenir_shop/scene_escalier": {"scene": &"souvenir_shop_stairs",
		"dir": Vector2i.ZERO},
	"mahogany_hideout_b1f/alarme_1": {"scene": &"hideout_alarm_1", "dir": Vector2i.ZERO},
	"mahogany_hideout_b1f/alarme_2": {"scene": &"hideout_alarm_2", "dir": Vector2i.ZERO},
	"mahogany_hideout_b1f/alarme_3": {"scene": &"hideout_alarm_3", "dir": Vector2i.ZERO},
	"mahogany_hideout_b3f/scene_brace": {"scene": &"hideout_brace", "dir": Vector2i.ZERO},
	"lake_of_rage/barriere_sentier": {"scene": &"lake_trail_guard", "dir": Vector2i.RIGHT},
}
const SKIPPED_TRIGGERS: Array[String] = ["mahogany_town/arrivee_titre"]
## Arrivées supplémentaires (alias) : (carte) → nom → case.
const EXTRA_SPAWNS: Dictionary = {
	# Point de Vol « Acajou » (`fly_points.json` : `from_center`) = devant le Centre.
	"mahogany_town": {"from_center": Vector2i(6, 14)},
	# Retour du souvenir de Dante (§2.7) : dans la cellule, devant le déserteur.
	"mahogany_hideout_b2f": {"devant_deserteur": Vector2i(7, 17)},
}
## Bâtiments du kit peint [D] : (carte) → [objet, case d'ancrage (porte), nœud].
const BUILDINGS: Dictionary = {
	"mahogany_town": [
		["bldg_centre_01", Vector2i(7, 13), "Centre"],
		["bldg_boutique_01", Vector2i(26, 13), "BoutiqueSouvenirs"],
		["bldg_maison_argenta_01", Vector2i(6, 24), "Maison1"],
		["bldg_maison_argenta_01", Vector2i(25, 24), "Maison2"],
	],
}
## Lampes de nuit [D] : (carte) → cases.
const NIGHT_GLOWS: Dictionary = {
	"mahogany_town": [Vector2i(5, 13), Vector2i(8, 13), Vector2i(24, 13), Vector2i(27, 13),
		Vector2i(15, 14), Vector2i(19, 26)],
	"route_43": [Vector2i(12, 23), Vector2i(18, 23)],
}
const FACINGS: Dictionary = {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}
const FACES: Dictionary = {"N": Vector2i.UP, "S": Vector2i.DOWN, "O": Vector2i.LEFT,
	"E": Vector2i.RIGHT}

## Décor du souvenir de Dante (§2.7) : bureau provisoire, sans grille [D].
const FLASHBACK_ID: StringName = &"dante_flashback_hq"
const FLASHBACK_SIZE := Vector2i(15, 10)

var _over: GDScript
var _inside: GDScript
var _rules: GDScript
var _rng := RandomNumberGenerator.new()
var _errors: int = 0
## Carte → arrivée → cases (relues sur toutes les grilles avant de construire).
var _spawns: Dictionary = {}


func _init() -> void:
	_over = load("res://game/world/overworld_tiles.gd")
	_inside = load("res://game/world/interior_tiles.gd")
	_rules = load("res://game/world/props/painted_prop_rules.gd")
	var wanted := _wanted()
	for spec: Dictionary in MAPS:
		_collect_spawns(spec)
	for spec: Dictionary in MAPS:
		if wanted.is_empty() or wanted.has(String(spec["id"])):
			_build(spec)
	if wanted.is_empty() or wanted.has(String(FLASHBACK_ID)):
		_build_flashback()
	print("build_joh6_maps : %s" % ("OK" if _errors == 0 else "%d erreur(s)" % _errors))
	quit(0 if _errors == 0 else 1)


func _wanted() -> Array:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--maps="):
			return Array(arg.trim_prefix("--maps=").split(","))
	return []


func _plan(spec: Dictionary) -> Object:
	var plan := PlanGrid.new()
	if not plan.load_file(PLANS_DIR + String(spec["plan"]) + ".txt"):
		_fail("%s : %s" % [spec["id"], plan.error])
	return plan


func _collect_spawns(spec: Dictionary) -> void:
	var plan := _plan(spec)
	var spawns: Dictionary = {}
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		if entry["kind"] == "spawn":
			spawns[id] = entry["cells"]
	var extra: Dictionary = EXTRA_SPAWNS.get(String(spec["id"]), {})
	for name: String in extra:
		spawns[name] = [extra[name]]
	_spawns[spec["id"]] = spawns


func _build(spec: Dictionary) -> void:
	var plan := _plan(spec)
	if _errors > 0:
		return
	_rng.seed = spec["seed"]
	var size := Vector2i(plan.width, plan.height)
	var style: String = spec["style"]
	var root := _new_map(spec, size, style == "shop")
	var blocked: Array[Vector2i] = []
	var calm: Array[Vector2i] = []
	var ground := root.get_node(^"Ground") as TileMapLayer
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			var mark: String = plan.at(cell)
			if style == "shop":
				_paint_shop(ground, cell, mark, plan.walkable, blocked)
				continue
			var kinds: Dictionary = OUTDOOR_KINDS
			if style == "tower":
				kinds = TOWER_KINDS
			elif style == "hideout":
				kinds = HIDEOUT_KINDS
			if not kinds.has(mark):
				_fail("%s : caractère inconnu « %s » en %s" % [spec["id"], mark, cell])
				continue
			var kind: int = _over.Kind[kinds[mark]]
			var variant := _rng.randi_range(0, _over.variant_count(kind) - 1)
			ground.set_cell(cell, _over.SOURCE_ID, _over.atlas_coords(kind, variant))
			var walkable: bool = plan.walkable.contains(mark)
			if not walkable and not _over.is_solid_kind(kind):
				blocked.append(cell)
			elif walkable and _over.is_solid_kind(kind):
				_fail("%s : case praticable « %s » sur une tuile pleine en %s" % [spec["id"], mark,
					cell])
			# Dallage de la Tour, échelles, sortie : sol calme (aucune rencontre des cendres).
			if style == "tower" and walkable and mark != "c" and mark != "O":
				calm.append(cell)
	if style == "tower":
		_draw_tower(root, plan)
	elif style == "hideout":
		_draw_hideout(root, plan)
	elif style == "shop":
		_draw_shop(root, plan)
	_add_positions(spec, plan, root, blocked)
	_add_buildings(spec, root)
	_add_night_glows(spec, root)
	root.set(&"blocked_cells", blocked)
	root.set(&"calm_cells", calm)
	# Eau `w` surfable (sinon simple décor) ; pêche sur le Lac Colère seulement (dossier §5).
	var water: Array[Vector2i] = []
	if style == "outdoor":
		water.assign(plan.cells_of("w"))
	root.set(&"surf_cells", water)
	if spec["id"] == &"lake_of_rage":
		root.set(&"fishable_cells", water)
	_save(root, MAPS_DIR + "%s.tscn" % spec["id"])


func _paint_shop(ground: TileMapLayer, cell: Vector2i, mark: String, walkable: String,
		blocked: Array[Vector2i]) -> void:
	var kind: int = _inside.Kind.FLOOR_WOOD
	if SHOP_WALLS.contains(mark):
		kind = _inside.Kind.WALL_HOUSE
	elif SHOP_MATS.contains(mark):
		kind = _inside.Kind.MAT
	elif not walkable.contains(mark):
		kind = _inside.Kind.RUG
		blocked.append(cell)
	var variant := _rng.randi_range(0, _inside.VARIANTS[kind] - 1)
	ground.set_cell(cell, _inside.SOURCE_ID, _inside.atlas_coords(kind, variant))


func _add_positions(spec: Dictionary, plan: Object, root: Node2D,
		blocked: Array[Vector2i]) -> void:
	var map_id: StringName = spec["id"]
	var size := size_of(root)
	for id: String in plan.positions:
		var entry: Dictionary = plan.positions[id]
		var cells: Array[Vector2i] = []
		cells.assign(entry["cells"])
		var attrs: Dictionary = entry["attrs"]
		var key := "%s/%s" % [map_id, id]
		var unless := _flags(attrs.get("actif_sans", ""))
		var if_flags := _flags(attrs.get("actif_avec", ""))
		# Position « bloque » hors PNJ (cellules fermées, repères, décors) : cases occupées.
		if entry["blocks"] and not ["dresseur", "pnj", "objet_visible", "pokemon"].has(entry["kind"]):
			for cell: Vector2i in cells:
				if not blocked.has(cell):
					blocked.append(cell)
		match entry["kind"]:
			"spawn":
				for i: int in cells.size():
					_spawn(root, id if i == 0 else "%s_%d" % [id, i], cells[i])
			"warp":
				if not WARPS.has(key):
					_fail("%s : passage sans destination" % key)
					continue
				_add_warp(root, id, cells, WARPS[key], size, if_flags, unless)
			"escalier":
				_add_stairs(root, id, cells[0], attrs)
			"trou":
				_add_holes(root, id, cells, attrs)
			"panneau":
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.UP,
					StringName("%s_%s" % [map_id, id]), [], [])
				if spec["style"] == "outdoor":
					_add_sign(root, cells[0], _node_name(id))
			"examen":
				var span := Vector2i(cells.size(), 1)
				_interact(root, _node_name(id), cells[0], span, Vector2i.ZERO,
					StringName("%s_%s" % [map_id, id]), if_flags, unless)
			"cache":
				var dialogue := StringName("%s_%s" % [map_id, id])
				var got: Array[StringName] = [StringName("got_%s_%s" % [map_id, id])]
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.ZERO, dialogue,
					[], got)
			"interrupteur":
				var flag := StringName(attrs.get("flag", ""))
				var face: Vector2i = FACES.get(attrs.get("face", ""), Vector2i.ZERO)
				var not_after: Array[StringName] = unless.duplicate()
				if not flag.is_empty():
					not_after.append(flag)
				_interact(root, _node_name(id), cells[0], Vector2i.ONE, face,
					StringName("%s_%s" % [map_id, id]), if_flags, not_after)
				_draw_switch(root, cells[0], id)
			"porte_cle":
				_add_key_gate(root, map_id, id, cells, attrs)
			"declencheur":
				if SKIPPED_TRIGGERS.has(key):
					continue
				if not TRIGGERS.has(key):
					_fail("%s : déclencheur sans scène" % key)
					continue
				var trigger: Dictionary = TRIGGERS[key]
				_trigger(root, _node_name(id), cells, trigger["dir"], trigger["scene"])
			"statue":
				_draw_statue(root, cells[0], attrs, id)
			"repere":
				_draw_landmark(root, map_id, id, cells, attrs)
			"decor":
				if id == "passage_secret":
					_poly_cell(root, root.get_node(^"Decor"), "PassageSecret", cells[0],
						Rect2(8, 8, 80, 88), Color(0.12, 0.12, 0.14))
			"dresseur", "pnj", "objet_visible", "pokemon", "herbes", "rencontre", "dalle":
				pass # données (`data/npcs/<carte>.json`) ou simples repères
			_:
				_fail("%s : type de position inconnu « %s »" % [key, entry["kind"]])
	var extra: Dictionary = EXTRA_SPAWNS.get(String(map_id), {})
	for name: String in extra:
		_spawn(root, name, extra[name])


func size_of(root: Node2D) -> Vector2i:
	return root.get(&"size")


func _flags(text: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for flag: String in text.split(",", false):
		out.append(StringName(flag))
	return out


## Passage d'un bord ou d'une porte : un warp par case, chacun vers l'arrivée de même rang de la
## carte cible si elle en a autant, sinon vers la première. Bord = PUSH vers l'extérieur ; porte
## = STEP_ON ↑ ; sortie d'intérieur (« exit ») = PUSH ↓. Cible absente : « À venir ».
func _add_warp(root: Node2D, id: String, cells: Array[Vector2i], dest: Dictionary,
		size: Vector2i, if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var on_edge := _on_edge(cells[0], size)
	var trigger := PUSH if on_edge or dest.get("exit", false) else STEP_ON
	var direction := Vector2i.UP
	if dest.get("exit", false):
		direction = Vector2i.DOWN
	elif on_edge:
		direction = _edge_direction(cells[0], size)
	var target: StringName = dest["to"]
	var spawn: String = dest["spawn"]
	var exists := _spawns.has(target) or ResourceLoader.exists(MAPS_DIR + "%s.tscn" % target)
	var target_cells: Array = _target_spawn_cells(target, spawn)
	for i: int in cells.size():
		var name := "%s_%d" % [_node_name(id), i]
		if not exists:
			_warp(root, name, cells[i], trigger, direction, &"",
				StringName(_back_spawn(root, cells[i])), -direction,
				dest.get("label", String(target)), if_flags, unless)
			continue
		var arrival := spawn
		if target_cells.size() == cells.size() and i > 0:
			arrival = "%s_%d" % [spawn, i]
		_warp(root, name, cells[i], trigger, direction, target, StringName(arrival),
			_arrival_facing(target, spawn, direction), "", if_flags, unless)


## Cases de l'arrivée [param spawn] de [param target] : grilles du jalon, sinon grille de
## Rosalia (JOH2) pour les retours vers la ville.
func _target_spawn_cells(target: StringName, spawn: String) -> Array:
	if _spawns.has(target):
		return (_spawns[target] as Dictionary).get(spawn, [])
	if target == &"ecruteak_city" or target == &"silver_trail":
		var plan := PlanGrid.new()
		var file := "rosalia.txt" if target == &"ecruteak_city" else "silver_trail.txt"
		if plan.load_file(PLANS_DIR + file):
			var entry: Dictionary = plan.positions.get(spawn, {})
			return entry.get("cells", [])
	return []


## Escalier (« vers=<carte>:<arrivée> », « cond=<drapeau> ») : STEP_ON sans direction.
func _add_stairs(root: Node2D, id: String, cell: Vector2i, attrs: Dictionary) -> void:
	var dest: String = attrs.get("vers", "")
	var target := StringName(dest.get_slice(":", 0))
	var spawn := StringName(dest.get_slice(":", 1))
	var if_flags := _flags(attrs.get("cond", ""))
	var exists := _spawns.has(target) or ResourceLoader.exists(MAPS_DIR + "%s.tscn" % target)
	if not exists:
		_fail("escalier %s : carte cible « %s » inconnue" % [id, target])
		return
	var facing := Vector2i.DOWN
	var entry: Array = (_spawns.get(target, {}) as Dictionary).get(String(spawn), [])
	if entry.is_empty():
		_fail("escalier %s : arrivée « %s » absente de « %s »" % [id, spawn, target])
	_warp(root, _node_name(id), cell, STEP_ON, Vector2i.ZERO, target, spawn,
		_arrival_facing(target, String(spawn), facing), "", if_flags, [])
	var up: bool = attrs.get("sens", "") == "monte"
	var gate := _gate(root, root.get_node(^"Decor"), "Escalier" + _node_name(id), cell, if_flags,
		[], [])
	_rect(root, gate, Rect2(-40, -88, 80, 80), Color(0.30, 0.29, 0.28))
	for step: int in 4:
		var y := -84 + step * 20
		var shade := 0.45 + (0.1 * step if up else 0.1 * (3 - step))
		_rect(root, gate, Rect2(-36, y, 72, 12), Color(shade, shade, shade * 0.95))


## Trous du plancher (FALL) : un warp par case vers « vers= » / « arrivee= », dessin noir.
func _add_holes(root: Node2D, id: String, cells: Array[Vector2i], attrs: Dictionary) -> void:
	var target := StringName(attrs.get("vers", ""))
	var spawn := StringName(attrs.get("arrivee", ""))
	for i: int in cells.size():
		var cell := cells[i]
		_warp(root, "%s_%d" % [_node_name(id), i], cell, FALL, Vector2i.ZERO, target, spawn,
			Vector2i.DOWN, "", [], [])
		var hole := Node2D.new()
		hole.name = "Trou_%d_%d" % [cell.x, cell.y]
		hole.position = _world(cell)
		_attach(root, root.get_node(^"Decor"), hole)
		_rect(root, hole, Rect2(-46, -92, 92, 88), Color(0.10, 0.07, 0.05))
		_rect(root, hole, Rect2(-36, -80, 72, 64), Color(0.0, 0.0, 0.0))


## Porte à drapeau (« porte_cle ») : [FlagGate] qui occupe la case tant que le drapeau
## d'ouverture manque. Porte à mot de passe : ouverte par `johto_password_said` (C-38), avec un
## point d'examen devant ; grille de la cellule : par le levier.
func _add_key_gate(root: Node2D, map_id: StringName, id: String, cells: Array[Vector2i],
		attrs: Dictionary) -> void:
	var open_flag := StringName(attrs.get("cle", ""))
	if id == "porte_mdp":
		open_flag = &"johto_password_said"
		_interact(root, _node_name(id), cells[0], Vector2i.ONE, Vector2i.UP,
			StringName("%s_%s" % [map_id, id]), [], [open_flag])
	var blocking: Array[Vector2i] = []
	blocking.assign(cells)
	var gate := _gate(root, root.get_node(^"Entities"), "Porte" + _node_name(id), cells[0], [],
		[open_flag], blocking)
	var color := Color(0.36, 0.38, 0.44) if id == "porte_mdp" else Color(0.55, 0.56, 0.6)
	_rect(root, gate, Rect2(-48, -120, 96, 116), color.darkened(0.3))
	if id == "porte_mdp":
		_rect(root, gate, Rect2(-36, -108, 72, 92), color)
		_rect(root, gate, Rect2(18, -70, 10, 10), Color(0.9, 0.2, 0.2))
	else:
		for bar: int in 5:
			_rect(root, gate, Rect2(-40 + bar * 18, -116, 8, 112), color)


func _draw_switch(root: Node2D, cell: Vector2i, id: String) -> void:
	var node := Node2D.new()
	node.name = "Dessin" + _node_name(id)
	node.position = _world(cell)
	_attach(root, root.get_node(^"Entities"), node)
	_rect(root, node, Rect2(-30, -70, 60, 64), Color(0.25, 0.27, 0.3))
	_rect(root, node, Rect2(-8, -96, 16, 40), Color(0.75, 0.2, 0.18))


## Statue de Persian (aplat provisoire [D]) : socle, corps, yeux qui regardent dans le sens de
## la caméra.
func _draw_statue(root: Node2D, cell: Vector2i, attrs: Dictionary, id: String) -> void:
	var node := Node2D.new()
	node.name = "Statue" + _node_name(id)
	node.position = _world(cell)
	_attach(root, root.get_node(^"Entities"), node)
	_rect(root, node, Rect2(-40, -30, 80, 26), Color(0.32, 0.30, 0.28))
	_rect(root, node, Rect2(-28, -110, 56, 82), Color(0.62, 0.56, 0.42))
	_rect(root, node, Rect2(-22, -132, 44, 30), Color(0.66, 0.60, 0.46))
	var facing: Vector2i = FACINGS.get(attrs.get("facing", "down"), Vector2i.DOWN)
	var eye_y := -122 if facing == Vector2i.DOWN else -128
	_rect(root, node, Rect2(-14, eye_y, 8, 6), Color(0.95, 0.15, 0.12))
	_rect(root, node, Rect2(6, eye_y, 8, 6), Color(0.95, 0.15, 0.12))


## Repères dessinés : antenne de la boutique, poste de péage, cage à ondes, cellules vides.
func _draw_landmark(root: Node2D, map_id: StringName, id: String, cells: Array[Vector2i],
		attrs: Dictionary) -> void:
	var rect := _bounds(cells)
	match "%s/%s" % [map_id, id]:
		"mahogany_town/antenne":
			# Sur le toit de la boutique : nœud trié avec la façade (pied sur la rangée des portes).
			var node := Node2D.new()
			node.name = "Antenne"
			node.position = Vector2(rect.position.x * TILE + TILE, 13 * TILE + TILE - 2)
			_attach(root, root.get_node(^"Entities"), node)
			var top := -(13 - rect.position.y) * TILE - 260
			_rect(root, node, Rect2(-6, top, 12, 220), Color(0.35, 0.36, 0.4))
			_rect(root, node, Rect2(-50, top + 20, 100, 8), Color(0.35, 0.36, 0.4))
			_rect(root, node, Rect2(-34, top + 56, 68, 8), Color(0.35, 0.36, 0.4))
			_rect(root, node, Rect2(-6, top - 10, 12, 12), Color(0.95, 0.2, 0.15))
		"route_43/poste_peage":
			var body := Polygon2D.new()
			body.name = "PostePeage"
			var top_left := Vector2(rect.position) * TILE
			var span := Vector2(rect.size) * TILE
			body.polygon = PackedVector2Array([top_left + Vector2(8, span.y * 0.2),
				top_left + Vector2(span.x - 8, span.y * 0.2), top_left + span - Vector2(8, 0),
				top_left + Vector2(8, span.y)])
			body.color = Color(0.45, 0.38, 0.32)
			_attach(root, root.get_node(^"Decor"), body)
			var roof := Polygon2D.new()
			roof.name = "PostePeageToit"
			roof.polygon = PackedVector2Array([top_left + Vector2(0, span.y * 0.24),
				top_left + Vector2(span.x * 0.5, 0), top_left + Vector2(span.x, span.y * 0.24)])
			roof.color = Color(0.22, 0.22, 0.26)
			_attach(root, root.get_node(^"Decor"), roof)
		"mahogany_hideout_b3f/cage":
			# Barreaux de la cage (visibles tant que le générateur tourne) et case d'accès (17, 10)
			# occupée jusqu'à `johto_generator_off`.
			var door: Array[Vector2i] = [Vector2i(17, 10)]
			var gate := _gate(root, root.get_node(^"Entities"), "CageAOndes", Vector2i(17, 10), [],
				[&"johto_generator_off"], door)
			for bar: int in 5:
				_rect(root, gate, Rect2(-44 + bar * 20, -110, 8, 106), Color(0.55, 0.75, 1.0))
			_rect(root, gate, Rect2(-48, -116, 96, 10), Color(0.4, 0.6, 0.95))
			var glow := _gate(root, root.get_node(^"Decor"), "CageHalo", Vector2i(16, 10), [],
				[&"johto_generator_off"], [])
			_rect(root, glow, Rect2(-48, -3 * TILE + 4, 3 * TILE, 3 * TILE - 8),
				Color(0.45, 0.7, 1.0, 0.25))
		"mahogany_hideout_b2f/cellules_fermees", "mahogany_hideout_b2f/cellule_vide_2":
			pass # barreaux = cases K de la grille, bloquées par leur tuile
		_:
			pass


## Tour : poutres calcinées (`P`) en aplats bruns.
func _draw_tower(root: Node2D, plan: Object) -> void:
	for cell: Vector2i in plan.cells_of("P"):
		_poly_cell(root, root.get_node(^"Decor"), "Poutre_%d_%d" % [cell.x, cell.y], cell,
			Rect2(6, 30, 84, 40), Color(0.16, 0.10, 0.07))


## Repaire : dalles (flèches et arrêts peints), consoles, caisses, générateur, pupitre.
func _draw_hideout(root: Node2D, plan: Object) -> void:
	var decor := root.get_node(^"Decor")
	var arrows: Dictionary[Vector2i, Vector2i] = {}
	for character: String in ARROWS:
		for cell: Vector2i in plan.cells_of(character):
			arrows[cell] = ARROWS[character]
			_add_decal(root, ARROW_DECALS[character], cell)
	var stops: Array[Vector2i] = []
	stops.assign(plan.cells_of("o"))
	for cell: Vector2i in stops:
		_add_decal(root, STOP_DECAL, cell)
	if not arrows.is_empty():
		var field := Node2D.new()
		field.set_script(load("res://game/world/spin/spin_tile_field.gd"))
		field.name = "SpinTiles"
		field.set(&"arrows", arrows)
		field.set(&"stops", stops)
		_attach(root, root, field)
	for cell: Vector2i in plan.cells_of("M"):
		_poly_cell(root, decor, "Console_%d_%d" % [cell.x, cell.y], cell, Rect2(4, 8, 88, 84),
			Color(0.24, 0.30, 0.36))
	for cell: Vector2i in plan.cells_of("X"):
		_poly_cell(root, decor, "Caisse_%d_%d" % [cell.x, cell.y], cell, Rect2(8, 12, 80, 80),
			Color(0.50, 0.38, 0.24))
	for cell: Vector2i in plan.cells_of("p"):
		_poly_cell(root, decor, "Pupitre_%d_%d" % [cell.x, cell.y], cell, Rect2(6, 20, 84, 70),
			Color(0.20, 0.22, 0.26))
	for cell: Vector2i in plan.cells_of("c"):
		_poly_cell(root, decor, "Barreau_%d_%d" % [cell.x, cell.y], cell, Rect2(30, 0, 36, 96),
			Color(0.40, 0.55, 0.85))


## Boutique : comptoir, rayons, présentoirs ; étagère qui cache l'escalier (porte à drapeau).
func _draw_shop(root: Node2D, plan: Object) -> void:
	var decor := root.get_node(^"Decor")
	for cell: Vector2i in plan.cells_of("rb"):
		_poly_cell(root, decor, "Rayon_%d_%d" % [cell.x, cell.y], cell, Rect2(4, 4, 88, 88),
			Color(0.46, 0.32, 0.22))
	for cell: Vector2i in plan.cells_of("c"):
		_poly_cell(root, decor, "Caisse_%d_%d" % [cell.x, cell.y], cell, Rect2(0, 24, 96, 66),
			Color(0.62, 0.44, 0.28))
	for cell: Vector2i in plan.cells_of("q"):
		_poly_cell(root, decor, "Presentoir_%d_%d" % [cell.x, cell.y], cell, Rect2(10, 10, 76, 80),
			Color(0.70, 0.52, 0.30))
	for cell: Vector2i in plan.cells_of("x"):
		_poly_cell(root, decor, "Plante_%d_%d" % [cell.x, cell.y], cell, Rect2(20, 10, 56, 80),
			Color(0.26, 0.46, 0.24))
	for cell: Vector2i in plan.cells_of("S"):
		var cells: Array[Vector2i] = [cell]
		var shelf := _gate(root, root.get_node(^"Entities"), "EtagereCachee", cell, [],
			[&"johto_hideout_found"], cells)
		_rect(root, shelf, Rect2(-46, -120, 92, 116), Color(0.46, 0.32, 0.22))
		for row: int in 3:
			_rect(root, shelf, Rect2(-40, -110 + row * 34, 80, 6), Color(0.30, 0.20, 0.14))


## Décor du souvenir de Dante (§2.7) : bureau de l'ancien QG, sans grille [D]. Murs sur les trois
## premières rangées, porte en feu au nord (Dante derrière), bureau de Giovanni (objet peint du
## repaire de Céladopole), sortie de secours au sud vers le B2F (application tuée pendant le
## souvenir).
func _build_flashback() -> void:
	_rng.seed = 6699
	var spec := {"id": FLASHBACK_ID, "name": "Repaire Rocket", "region": "Kanto, il y a vingt ans",
		"light": &"interior_warm", "interior": true}
	var root := _new_map(spec, FLASHBACK_SIZE, true)
	var ground := root.get_node(^"Ground") as TileMapLayer
	var blocked: Array[Vector2i] = []
	for y: int in FLASHBACK_SIZE.y:
		for x: int in FLASHBACK_SIZE.x:
			var cell := Vector2i(x, y)
			var kind: int = _inside.Kind.FLOOR_WOOD
			if y < 3 or x == 0 or x == FLASHBACK_SIZE.x - 1 or y == FLASHBACK_SIZE.y - 1:
				kind = _inside.Kind.WALL_HOUSE
				if not (y == FLASHBACK_SIZE.y - 1 and x >= 6 and x <= 8):
					blocked.append(cell)
				else:
					kind = _inside.Kind.MAT
			var variant := _rng.randi_range(0, _inside.VARIANTS[kind] - 1)
			ground.set_cell(cell, _inside.SOURCE_ID, _inside.atlas_coords(kind, variant))
	# Bureau (9..12, 5..6) : objet peint du bureau de Giovanni (ancré sur la 3e case de la rangée
	# du bas, comme au repaire de Céladopole), cases bloquées.
	for y: int in [5, 6]:
		for x: int in range(9, 13):
			blocked.append(Vector2i(x, y))
	_add_prop(root, "int_bureau_giovanni_01", Vector2i(11, 6), "Bureau")
	# Porte bloquée (7, 4) entre Dante (7, 3) et Giovanni (7, 5), flammes le long du mur nord [D].
	var decor := root.get_node(^"Decor")
	blocked.append(Vector2i(7, 4))
	var door := Node2D.new()
	door.name = "PorteBloquee"
	door.position = _world(Vector2i(7, 4))
	_attach(root, root.get_node(^"Entities"), door)
	_rect(root, door, Rect2(-48, -150, 96, 146), Color(0.30, 0.18, 0.10))
	_rect(root, door, Rect2(-40, -140, 80, 40), Color(1.0, 0.55, 0.15, 0.9))
	for x: int in [2, 4, 6, 8, 10, 12]:
		_poly_cell(root, decor, "Flamme_%d" % x, Vector2i(x, 2), Rect2(14, 30, 68, 66),
			Color(1.0, 0.45, 0.10, 0.85))
	for x: int in [1, 13]:
		_poly_cell(root, decor, "FlammeMur_%d" % x, Vector2i(x, 5), Rect2(10, 0, 76, 96),
			Color(1.0, 0.40, 0.08, 0.7))
	_spawn(root, "vue", Vector2i(7, 7))
	for i: int in 3:
		_warp(root, "SortieSecours_%d" % i, Vector2i(6 + i, FLASHBACK_SIZE.y - 1), PUSH,
			Vector2i.DOWN, &"mahogany_hideout_b2f", &"devant_deserteur", Vector2i.UP, "", [], [])
	root.set(&"blocked_cells", blocked)
	_save(root, MAPS_DIR + "%s.tscn" % FLASHBACK_ID)


## Arrivée « tournée » de la carte cible (attribut facing de sa grille, sinon le sens du passage).
func _arrival_facing(target: StringName, spawn: String, direction: Vector2i) -> Vector2i:
	for spec: Dictionary in MAPS:
		if spec["id"] != target:
			continue
		var plan := _plan(spec)
		var entry: Dictionary = plan.positions.get(spawn, {})
		var facing: String = (entry.get("attrs", {}) as Dictionary).get("facing", "")
		if FACINGS.has(facing):
			return FACINGS[facing]
	return direction


## Arrivée de la carte qui se trouve sur la case [param cell] (retour d'un « À venir »).
func _back_spawn(root: Node2D, cell: Vector2i) -> String:
	var spawns: Dictionary = _spawns.get(root.get(&"map_id"), {})
	for name: String in spawns:
		var cells: Array = spawns[name]
		for i: int in cells.size():
			if cells[i] == cell:
				return name if i == 0 else "%s_%d" % [name, i]
	for name: String in spawns:
		return name
	return ""


func _on_edge(cell: Vector2i, size: Vector2i) -> bool:
	return cell.x == 0 or cell.y == 0 or cell.x == size.x - 1 or cell.y == size.y - 1


func _edge_direction(cell: Vector2i, size: Vector2i) -> Vector2i:
	if cell.x == 0:
		return Vector2i.LEFT
	if cell.x == size.x - 1:
		return Vector2i.RIGHT
	if cell.y == 0:
		return Vector2i.UP
	return Vector2i.DOWN


func _node_name(id: String) -> String:
	return id.to_pascal_case()


func _bounds(cells: Array[Vector2i]) -> Rect2i:
	var top_left := cells[0]
	var bottom_right := cells[0]
	for cell: Vector2i in cells:
		top_left = Vector2i(mini(top_left.x, cell.x), mini(top_left.y, cell.y))
		bottom_right = Vector2i(maxi(bottom_right.x, cell.x), maxi(bottom_right.y, cell.y))
	return Rect2i(top_left, bottom_right - top_left + Vector2i.ONE)


# --- Nœuds ------------------------------------------------------------------------------------

func _new_map(spec: Dictionary, size: Vector2i, inside_tiles: bool) -> Node2D:
	var root := Node2D.new()
	root.name = String(spec["id"]).to_pascal_case()
	root.set_script(load("res://game/world/map.gd"))
	root.set(&"map_id", spec["id"])
	root.set(&"display_name", spec["name"])
	root.set(&"region", spec["region"])
	root.set(&"size", size)
	root.set(&"interior", spec.get("interior", false))
	root.set(&"light_profile", spec["light"])
	# Tableaux typés posés explicitement : sans les autoloads, map.gd ne compile pas dans l'outil
	# et un tableau laissé par défaut serait enregistré « Array[int] ».
	for property: StringName in [&"calm_cells", &"slope_cells", &"surf_cells", &"forced_surf_cells",
			&"fishable_cells", &"low_cells", &"high_cells", &"stairs_cells", &"cycling_road_cells",
			&"blocked_cells"]:
		var empty: Array[Vector2i] = []
		root.set(property, empty)
	var rows: Array[int] = []
	root.set(&"level_rows", rows)
	var currents: Dictionary[Vector2i, Vector2i] = {}
	root.set(&"current_cells", currents)
	var tileset: TileSet = load(_inside.TILESET_PATH if inside_tiles else _over.TILESET_PATH)
	_add_layer(root, "Ground", tileset)
	_add_layer(root, "Detail", tileset)
	_add_layer(root, "Obstacles", tileset)
	var decor := Node2D.new()
	decor.name = "Decor"
	_attach(root, root, decor)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_attach(root, root, entities)
	entities.unique_name_in_owner = true
	var overhead := _add_layer(root, "Overhead", tileset)
	overhead.z_index = 10
	for group: String in ["Warps", "Interactables", "Spawns", "Triggers", "NightLights"]:
		var node := Node2D.new()
		node.name = group
		_attach(root, root, node)
	return root


func _spawn(root: Node, spawn_name: String, cell: Vector2i) -> void:
	var marker := Marker2D.new()
	marker.name = spawn_name
	marker.position = _world(cell)
	_attach(root, root.get_node(^"Spawns"), marker)


func _warp(root: Node, warp_name: String, cell: Vector2i, trigger: int, direction: Vector2i,
		target: StringName, spawn: StringName, facing: Vector2i, coming_soon: String,
		if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/warp_point.gd"))
	point.name = warp_name
	point.position = _world(cell)
	point.set(&"trigger", trigger)
	point.set(&"direction", direction)
	point.set(&"target_map", target)
	point.set(&"target_spawn", spawn)
	point.set(&"arrival_facing", facing)
	point.set(&"coming_soon", coming_soon)
	point.set(&"if_flags", if_flags)
	point.set(&"unless_flags", unless)
	_attach(root, root.get_node(^"Warps"), point)


func _interact(root: Node, node_name: String, cell: Vector2i, span: Vector2i, facing: Vector2i,
		dialogue: StringName, if_flags: Array[StringName], unless: Array[StringName]) -> void:
	var point := Marker2D.new()
	point.set_script(load("res://game/world/interactions/interact_point.gd"))
	point.name = node_name
	point.position = _world(cell)
	point.set(&"size", span)
	point.set(&"facing", facing)
	point.set(&"dialogue_id", dialogue)
	point.set(&"if_flags", if_flags)
	point.set(&"unless_flags", unless)
	_attach(root, root.get_node(^"Interactables"), point)


func _trigger(root: Node, node_name: String, cells: Array[Vector2i], direction: Vector2i,
		cutscene: StringName) -> void:
	var rect := _bounds(cells)
	var point := Marker2D.new()
	point.set_script(load("res://game/world/triggers/event_trigger_point.gd"))
	point.name = node_name
	# Ancre en bas à gauche (EventTriggerPoint : y -(size.y-1)..0).
	point.position = _world(Vector2i(rect.position.x, rect.end.y - 1))
	point.set(&"size", rect.size)
	point.set(&"direction", direction)
	point.set(&"cutscene_id", cutscene)
	_attach(root, root.get_node(^"Triggers"), point)


## [FlagGate] ancré au pied de [param cell] ; [param blocking] : cases occupées tant qu'il est
## affiché.
func _gate(root: Node, parent: Node, gate_name: String, cell: Vector2i, if_flags: Array,
		unless: Array, blocking: Array) -> Node2D:
	var gate := Node2D.new()
	gate.set_script(load("res://game/world/flag_gate.gd"))
	gate.name = gate_name
	gate.position = _world(cell)
	var typed_if: Array[StringName] = []
	typed_if.assign(if_flags)
	var typed_unless: Array[StringName] = []
	typed_unless.assign(unless)
	var typed_cells: Array[Vector2i] = []
	typed_cells.assign(blocking)
	gate.set(&"if_flags", typed_if)
	gate.set(&"unless_flags", typed_unless)
	gate.set(&"blocking_cells", typed_cells)
	_attach(root, parent, gate)
	return gate


## Aplat dans une case : [param rect] en pixels depuis le coin haut-gauche de la case.
func _poly_cell(root: Node, parent: Node, node_name: String, cell: Vector2i, rect: Rect2,
		color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = node_name
	poly.color = color
	var origin := Vector2(cell) * TILE + rect.position
	poly.polygon = PackedVector2Array([origin, origin + Vector2(rect.size.x, 0),
		origin + rect.size, origin + Vector2(0, rect.size.y)])
	_attach(root, parent, poly)


## Rectangle relatif au parent (pied de case).
func _rect(root: Node, parent: Node, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = "Dessin"
	poly.color = color
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])
	_attach(root, parent, poly)


## Panneau peint (son emprise bloque sa case).
func _add_sign(root: Node, cell: Vector2i, node_name: String) -> void:
	_add_prop(root, SIGN_PROP, cell, node_name + "Sign")


func _add_buildings(spec: Dictionary, root: Node) -> void:
	for entry: Array in BUILDINGS.get(String(spec["id"]), []):
		_add_prop(root, entry[0], entry[1], "Bat_" + String(entry[2]))


func _add_prop(root: Node, id: String, anchor: Vector2i, node_name: String) -> void:
	var scene := load(PROPS_DIR + id + ".tscn") as PackedScene
	if scene == null:
		_fail("objet peint introuvable : %s" % id)
		return
	var prop := scene.instantiate() as Node2D
	prop.name = node_name
	prop.position = _rules.call(&"foot_position", StringName(id), anchor)
	_attach(root, root.get_node(^"Entities"), prop)


## Décalcomanie au sol (flèche ou disque d'arrêt des dalles), sous les personnages.
func _add_decal(root: Node, id: String, cell: Vector2i) -> void:
	var scene := load(PROPS_DIR + id + ".tscn") as PackedScene
	if scene == null:
		_fail("décalcomanie introuvable : %s" % id)
		return
	var prop := scene.instantiate() as Node2D
	prop.name = "Dalle_%d_%d" % [cell.x, cell.y]
	prop.position = _rules.call(&"foot_position", StringName(id), cell)
	_attach(root, root.get_node(^"Decor"), prop)


## Lampes de nuit : halos `LightGlow` (type `lamp`) du groupe `night_lights`, cachés par défaut.
func _add_night_glows(spec: Dictionary, root: Node) -> void:
	var glow_script: GDScript = load("res://game/world/lighting/light_glow.gd")
	var index := 0
	for cell: Vector2i in NIGHT_GLOWS.get(String(spec["id"]), []):
		var glow := Sprite2D.new()
		glow.set_script(glow_script)
		glow.name = "Lampe%d" % index
		glow.position = Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
		glow.set(&"glow_type", &"lamp")
		glow.visible = false
		_attach(root, root.get_node(^"NightLights"), glow)
		glow.add_to_group(NIGHT_LIGHTS, true)
		index += 1


func _save(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s : %s" % [path, "OK" if err == OK else "ERREUR %d" % err])
	if err != OK:
		_errors += 1
	root.free()


func _world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


func _attach(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _add_layer(root: Node, layer_name: String, tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tileset
	_attach(root, root, layer)
	return layer


func _fail(message: String) -> void:
	push_error("build_joh6_maps : " + message)
	_errors += 1
