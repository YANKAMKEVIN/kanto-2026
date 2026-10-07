class_name DenseForest
extends RefCounted
## Forêt serrée de production (docs/tech/integration-da-bourg-route1.md §3), réécrite d'après
## le prototype validé par Kevin le 2026-10-06 (`proto/da_jadielle/foret_serree.gd`) : arbres
## de forêt d'environ 3 cases (`tree_foret_01..08`) espacés de 1,1 case, taille, miroir et
## teinte variés ; bandes trop étroites pour un arbre garnies de buissons ; arbres repères
## dégagés. Le sol sombre sous la forêt est [ForestFloor].
##
## **Rien n'est tiré au lancement du jeu** : l'outil de construction d'une carte appelle
## [method plan] (graine fixe : la même carte donne toujours la même forêt), puis [method place]
## qui écrit les arbres dans la scène (`Entities`, tri par les pieds) avec leur taille, leur
## miroir et leur teinte. Classe pure pour [method plan] (testée sans scène).
##
## **Règle du couvert** : un arbre ne pousse que si les [constant CANOPY_ROWS] cases de sa
## colonne, de la case de son pied vers le nord, sont de la forêt (hors carte : forêt) ; son
## feuillage ne cache ni le chemin ni les clairières. Les arbres ne sont pas solides : les
## cases de forêt le sont déjà dans la carte (`Ground` ou `blocked_cells`).
##
## **Variation selon la rangée** (jalon 8 §1.2 B, lisière de la Route 2) : un [DenseForest.Shade]
## facultatif assombrit et refroidit les arbres vers le nord (teinte multipliée par
## [method row_tint] du pied) et change les poids des essences au nord d'une rangée. Sans lui
## (ou neutre), le plan est exactement celui d'avant (Route 1, Bourg Palette inchangés).
##
## Positions en **cases** (flottants, pied de l'objet) dans le plan ; en pixels dans la scène.

const TREE_IDS: Array[StringName] = [
	&"tree_foret_01", &"tree_foret_02", &"tree_foret_03", &"tree_foret_04",
	&"tree_foret_05", &"tree_foret_06", &"tree_foret_07", &"tree_foret_08",
]
## Buissons des bandes étroites (échelle du prototype de Bourg Palette).
const BUSH_IDS: Array[StringName] = [&"prop_buisson_a_01_bourg", &"prop_buisson_b_01_bourg"]
const PROPS_DIR: String = "res://game/world/props/painted/"
## Catalogue de l'art (ombres de contact préparées des arbres de forêt).
const CATALOGUE_PATH: String = "res://assets/world/catalogue.json"
const CONTACT_MATERIAL: String = "res://game/world/lighting/materials/contact_shadow.tres"
const CONTACT_NODE: StringName = &"ContactShadow"
const KIND_TREE: StringName = &"tree"
const KIND_BUSH: StringName = &"bush"

## Cases de la colonne d'un arbre, pied compris, qui doivent être de la forêt.
const CANOPY_ROWS: int = 3
## Distance minimale entre deux pieds d'arbres (cases).
const SPACING: float = 1.1
## Aucun arbre de forêt à moins de cette distance d'un arbre repère (cases).
const LANDMARK_CLEARANCE: float = 2.0
## Tirages de positions (le prototype : 9 000 pour 48 × 44 cases).
const ATTEMPTS: int = 9000
## Pieds tirés dans [MARGIN_X, largeur − MARGIN_X] × [TOP, hauteur + BELOW] : les arbres du
## bas de la carte ont leur pied sous le bord (leur cime remplit les dernières rangées).
const MARGIN_X: float = 0.3
const TOP: float = 0.6
const BELOW: float = 1.2
const SCALE_MIN: float = 0.85
const SCALE_MAX: float = 1.15
## Teinte : valeur commune puis légers écarts du rouge et du bleu.
const VALUE_MIN: float = 0.86
const VALUE_MAX: float = 1.08
const RED_MIN: float = 0.95
const RED_MAX: float = 1.03
const BLUE_MIN: float = 0.93
const BLUE_MAX: float = 1.05
## Garnissage : une case de forêt est garnie si un arbre (ou repère) est à moins de
## [constant COVER_RADIUS] de son point de référence, ou juste au sud de lui (cime au-dessus) :
## écart horizontal < [constant COVER_HALF_WIDTH], plus bas de moins de [constant COVER_DEPTH].
const CELL_REFERENCE: Vector2 = Vector2(0.5, 0.7)
const COVER_RADIUS: float = 1.0
const COVER_HALF_WIDTH: float = 0.9
const COVER_DEPTH: float = 2.4
## Buisson : sous le point de référence, légèrement décalé.
const BUSH_DROP: float = 0.25
const BUSH_JITTER: float = 0.15
## Seau du rangement des pieds (≥ SPACING : seuls les seaux voisins sont à comparer).
const _BUCKET: float = 2.0


## Plan de la forêt de [param forest] (cases → vrai, ordre d'insertion = ordre des buissons)
## sur une carte de [param map_size] cases. [param landmarks] : pieds des arbres repères (cases).
## Chaque entrée : { "kind": [constant KIND_TREE] | [constant KIND_BUSH], "id": StringName,
## "foot": Vector2 (cases), "position": Vector2 (pixels), "scale": float, "flip_h": bool,
## "tint": Color }. Arbres d'abord (ordre des tirages), puis buissons.
## [param shade] : variation selon la rangée (facultative, voir [DenseForest.Shade]).
static func plan(forest: Dictionary, map_size: Vector2i, landmarks: Array[Vector2],
		seed_value: int, shade: Shade = null) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var entries: Array[Dictionary] = []
	var trees: Array[Vector2] = []
	var buckets: Dictionary = {}
	for _attempt in ATTEMPTS:
		var foot := Vector2(rng.randf_range(MARGIN_X, map_size.x - MARGIN_X),
			rng.randf_range(TOP, map_size.y + BELOW))
		if not is_under_canopy(forest, map_size, foot):
			continue
		if _too_close(buckets, foot) or _near_landmark(landmarks, foot):
			continue
		trees.append(foot)
		var bucket := _bucket_of(foot)
		if not buckets.has(bucket):
			buckets[bucket] = []
		(buckets[bucket] as Array).append(foot)
		# Même ordre de tirages que le prototype : essence, taille, miroir, teinte.
		var id := _pick_tree(rng, shade, foot.y)
		var scale := rng.randf_range(SCALE_MIN, SCALE_MAX)
		var flip := rng.randf() < 0.5
		var value := rng.randf_range(VALUE_MIN, VALUE_MAX)
		var tint := Color(value * rng.randf_range(RED_MIN, RED_MAX), value,
			value * rng.randf_range(BLUE_MIN, BLUE_MAX))
		if shade != null:
			tint *= row_tint(shade, foot.y)
		entries.append(_entry(KIND_TREE, id, foot, scale, flip, tint))
	var covering: Array[Vector2] = trees.duplicate()
	covering.append_array(landmarks)
	for cell: Vector2i in forest:
		if is_covered(cell, covering):
			continue
		var reference := Vector2(cell) + CELL_REFERENCE
		var id := BUSH_IDS[rng.randi_range(0, BUSH_IDS.size() - 1)]
		var foot := Vector2(reference.x + rng.randf_range(-BUSH_JITTER, BUSH_JITTER),
			reference.y + BUSH_DROP)
		entries.append(_entry(KIND_BUSH, id, foot, 1.0, false, Color.WHITE))
	return entries


## Multiplicateur de teinte d'un arbre dont le pied est à la rangée [param row] (cases) ;
## blanc sans réglage. Sert aussi aux grands arbres de lisière (« assombris comme la forêt de
## leur rangée », jalon 8 §1.2 B).
static func row_tint(shade: Shade, row: float) -> Color:
	if shade == null or shade.from_row <= shade.full_row:
		return Color.WHITE
	var t := clampf((shade.from_row - row) / (shade.from_row - shade.full_row), 0.0, 1.0)
	var value := lerpf(1.0, shade.value, t)
	return Color(value * lerpf(1.0, shade.red, t), value, value * lerpf(1.0, shade.blue, t))


## Cases de la colonne de [param foot] couvertes par le feuillage (pied compris).
static func canopy_cells(foot: Vector2) -> Array[Vector2i]:
	var cell := Vector2i(floori(foot.x), floori(foot.y))
	var cells: Array[Vector2i] = []
	for dy in CANOPY_ROWS:
		cells.append(cell + Vector2i(0, -dy))
	return cells


## Vrai si toutes les cases de [method canopy_cells] dans la carte sont de la forêt.
static func is_under_canopy(forest: Dictionary, map_size: Vector2i, foot: Vector2) -> bool:
	for cell: Vector2i in canopy_cells(foot):
		var inside := cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x \
			and cell.y < map_size.y
		if inside and not forest.has(cell):
			return false
	return true


## Vrai si la case de forêt [param cell] est garnie par l'un des pieds de [param feet].
static func is_covered(cell: Vector2i, feet: Array[Vector2]) -> bool:
	var reference := Vector2(cell) + CELL_REFERENCE
	for foot: Vector2 in feet:
		if foot.distance_to(reference) < COVER_RADIUS:
			return true
		if absf(foot.x - reference.x) < COVER_HALF_WIDTH and reference.y < foot.y \
				and foot.y - reference.y < COVER_DEPTH:
			return true
	return false


## Écrit les entrées de [param entries] ([method plan]) sous [param parent] : une instance
## de la scène peinte par entrée (`Forest000`, `ForestBush000`…), pied en pixels, taille,
## miroir du sprite et teinte (modulate) cuits dans le nœud. [param owner_node] : propriétaire
## pour l'enregistrement de la scène. Renvoie les nœuds créés, dans l'ordre.
## [param contact_shadows] : ombre de contact sous chaque **arbre** (comme le prototype validé ;
## désactivée par défaut, règle du J7 « pas d'ombre pour la végétation ») : l'image préparée
## `<id>_contact.png` du catalogue, nœud `ContactShadow` du groupe
## [constant WorldLighting.GROUP_CONTACT_SHADOWS] (couleur et visibilité réglées par la lumière).
static func place(entries: Array[Dictionary], parent: Node,
		owner_node: Node = null, contact_shadows: bool = false) -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	var contacts: Dictionary = _contact_entries() if contact_shadows else {}
	var trees := 0
	var bushes := 0
	for entry: Dictionary in entries:
		var packed := load(PROPS_DIR + String(entry["id"]) + ".tscn") as PackedScene
		if packed == null:
			push_error("DenseForest : scène absente pour « %s »" % entry["id"])
			continue
		var node := packed.instantiate() as Node2D
		if entry["kind"] == KIND_TREE:
			node.name = "Forest%03d" % trees
			trees += 1
		else:
			node.name = "ForestBush%03d" % bushes
			bushes += 1
		node.position = entry["position"]
		var scale: float = entry["scale"]
		node.scale = Vector2(scale, scale)
		node.modulate = entry["tint"]
		var sprite := node.get_node_or_null(^"Sprite") as Sprite2D
		if sprite != null:
			sprite.flip_h = entry["flip_h"]
		parent.add_child(node)
		if owner_node != null:
			node.owner = owner_node
		if entry["kind"] == KIND_TREE and contacts.has(String(entry["id"])):
			var shadow := contact_shadow(contacts[String(entry["id"])])
			node.add_child(shadow)
			if owner_node != null:
				shadow.owner = owner_node
		nodes.append(node)
	return nodes


## Ombre de contact pré-floutée d'une entrée « contact » du catalogue (demi-résolution à
## l'échelle 2, coin haut gauche à « decalage » du pied), comme `tools/build_painted_props.gd`.
static func contact_shadow(entry: Dictionary) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = CONTACT_NODE
	sprite.texture = load(entry["fichier"])
	sprite.centered = false
	var scale := float(entry["echelle"])
	sprite.offset = Vector2(entry["decalage"][0], entry["decalage"][1]) / scale
	sprite.scale = Vector2(scale, scale)
	sprite.z_as_relative = false
	sprite.z_index = WorldLighting.Z_SHADOWS
	sprite.material = load(CONTACT_MATERIAL)
	sprite.add_to_group(WorldLighting.GROUP_CONTACT_SHADOWS, true)
	return sprite


## Entrées « contact » du catalogue des arbres de forêt, par identifiant.
static func _contact_entries() -> Dictionary:
	var result: Dictionary = {}
	var catalogue: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE_PATH))
	if not catalogue is Dictionary:
		push_error("DenseForest : catalogue illisible")
		return result
	var objects: Dictionary = (catalogue as Dictionary).get("objets", {})
	for id: StringName in TREE_IDS:
		var entry: Dictionary = objects.get(String(id), {})
		if entry.has("contact"):
			result[String(id)] = entry["contact"]
	return result


static func _entry(kind: StringName, id: StringName, foot: Vector2, scale: float,
		flip: bool, tint: Color) -> Dictionary:
	return {
		"kind": kind,
		"id": id,
		"foot": foot,
		"position": foot * float(Grid.TILE_SIZE),
		"scale": scale,
		"flip_h": flip,
		"tint": tint,
	}


## Essence d'un arbre : tirage uniforme (celui du prototype) sans poids applicables, sinon
## tirage pondéré par [member Shade.weights] au nord de [member Shade.weights_row].
static func _pick_tree(rng: RandomNumberGenerator, shade: Shade, row: float) -> StringName:
	if shade == null or shade.weights.is_empty() or row >= shade.weights_row:
		return TREE_IDS[rng.randi_range(0, TREE_IDS.size() - 1)]
	var total := 0.0
	for id: StringName in TREE_IDS:
		total += maxf(shade.weights.get(id, 1.0), 0.0)
	var pick := rng.randf() * total
	for id: StringName in TREE_IDS:
		pick -= maxf(shade.weights.get(id, 1.0), 0.0)
		if pick < 0.0:
			return id
	return TREE_IDS[TREE_IDS.size() - 1]


static func _bucket_of(foot: Vector2) -> Vector2i:
	return Vector2i(floori(foot.x / _BUCKET), floori(foot.y / _BUCKET))


static func _too_close(buckets: Dictionary, foot: Vector2) -> bool:
	var centre := _bucket_of(foot)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for other: Vector2 in buckets.get(centre + Vector2i(dx, dy), []):
				if other.distance_to(foot) < SPACING:
					return true
	return false


static func _near_landmark(landmarks: Array[Vector2], foot: Vector2) -> bool:
	for landmark: Vector2 in landmarks:
		if landmark.distance_to(foot) < LANDMARK_CLEARANCE:
			return true
	return false


## Réglage de la forêt selon la rangée du pied ; neutre par défaut. Effet nul au sud de
## [member from_row], entier au nord de [member full_row] (et au-delà), linéaire entre les
## deux ; poids des essences ([member weights], absent = 1) au nord de [member weights_row].
class Shade:
	extends RefCounted
	## Rangée au sud de laquelle la teinte est inchangée (≤ [member full_row] : aucun effet).
	var from_row: float = 0.0
	## Rangée au nord de laquelle l'effet est entier.
	var full_row: float = 0.0
	## Multiplicateurs atteints au nord : valeur (les trois canaux), puis rouge et bleu.
	var value: float = 1.0
	var red: float = 1.0
	var blue: float = 1.0
	## Pied strictement au nord de cette rangée (y < weights_row) : poids des essences.
	var weights_row: float = 0.0
	## Essence → poids (> 0 ; absente : 1).
	var weights: Dictionary[StringName, float] = {}
