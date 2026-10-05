class_name PaintedPropRules
extends RefCounted
## Emprises au sol et couches des objets peints (docs/tech/jalon-07.md §6.6), reprises des
## règles du prototype (`proto/da_jadielle/emprises.gd`) sous les identifiants de
## `assets/world/catalogue.json`. Lu par `tools/build_painted_props.gd` (scènes
## `game/world/props/painted/<id>.tscn`), par les outils de construction des cartes (où poser
## un objet) et par `test_painted_props`.
##
## **Pied** d'un objet = milieu du bas de son image = origine de la scène (tri par les pieds).
## L'emprise est faite de cases de 96 px **au-dessus** du pied : rangées −(profondeur − 1) à 0
## autour de la case d'ancrage ([method WorldProp.get_anchor_cell]). Largeur paire : le pied
## est posé sur un **bord** de case (l'emprise va de −largeur/2 à largeur/2 − 1) ; impaire :
## au **milieu** d'une case ([method foot_position]).
## Couche **sol** ([constant LAYER_GROUND]) : falaises, escaliers, massif au pied de l'arbre
## central, posés dans `GroundDecals` (non trié, sous les personnages : un escalier ne passe
## jamais devant un personnage qui le monte). Les autres dans `Entities` (tri par les pieds).

const LAYER_ENTITIES: StringName = &"entities"
const LAYER_GROUND: StringName = &"ground"
## Bords du pied par rapport à la case d'ancrage.
const ALIGN_EDGE: StringName = &"edge"
const ALIGN_CENTRE: StringName = &"centre"

## Par identifiant du catalogue. Clés : « width » / « depth » (cases, rectangle au-dessus du
## pied), ou « cells » (liste explicite) ; « open » : cases laissées libres (portes
## franchissables du Centre et de la Boutique, où la carte pose ses passages) ; « wind » :
## feuillage au vent ; « fade » : devient transparent quand le joueur passe derrière ;
## « layer » ; « align » (défaut : selon la parité de la largeur) ; « origin » : pied ailleurs
## qu'au milieu du bas de l'image (pixels de l'image) ; « traversable » : aucune emprise ;
## « material » : faux = sprite sans shader (le massif du prototype n'en avait pas).
const RULES: Dictionary[StringName, Dictionary] = {
	&"bldg_centre_01": {"width": 8, "depth": 4, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_boutique_01": {"width": 8, "depth": 4, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_arene_01": {"width": 10, "depth": 4, "fade": true},
	&"bldg_maison_a_01": {"width": 6, "depth": 3, "fade": true},
	&"bldg_maison_b_01": {"width": 5, "depth": 3, "fade": true},
	&"tree_a_01": {"width": 1, "depth": 1, "wind": true, "fade": true},
	&"tree_b_01": {"width": 1, "depth": 1, "wind": true, "fade": true},
	# Pied sur un bord de case : le massif qui l'entoure est centré sur ce bord.
	&"tree_central_01": {"width": 1, "depth": 1, "wind": true, "fade": true,
		"align": ALIGN_EDGE},
	# Origine = le trou de terre où sort le tronc, posé sur le pied de l'arbre central.
	&"prop_massif_01": {"cells": [
		Vector2i(-2, -1), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	], "layer": LAYER_GROUND, "align": ALIGN_EDGE, "origin": Vector2(182, 109),
		"material": false},
	&"prop_banc_01": {"width": 2, "depth": 1},
	&"prop_lampadaire_01": {"width": 1, "depth": 1},
	&"prop_panneau_01": {"width": 1, "depth": 1},
	&"prop_rocher_01": {"width": 2, "depth": 1},
	&"prop_haie_01": {"width": 4, "depth": 1},
	&"prop_cloture_01": {"width": 4, "depth": 1},
	# Arche de la sortie nord : seulement les deux piliers, le passage reste libre.
	&"prop_porte_nord_01": {"cells": [Vector2i(-2, 0), Vector2i(2, 0)], "fade": true,
		"align": ALIGN_CENTRE},
	&"relief_falaise_01": {"width": 4, "depth": 1, "layer": LAYER_GROUND},
	&"relief_escalier_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	# Série 07 (Jadielle agrandie). Murs de soutènement des terrasses et escaliers de ville :
	# relief de la couche du sol, sans emprise (la carte bloque la rangée du mur dans
	# `blocked_cells`, piliers compris ; les tronçons se chevauchent librement).
	&"relief_muret_01": {"traversable": true, "layer": LAYER_GROUND},
	&"relief_escalier_ville_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	# Jardins : potager et plate-bande (3 cases, rangée du pied), clôture et haie qui courent
	# du nord au sud (4 cases au-dessus du pied, sur la colonne d'ancrage).
	&"prop_potager_01": {"width": 3, "depth": 1},
	&"prop_platebande_01": {"width": 3, "depth": 1},
	&"prop_cloture_v_01": {"width": 1, "depth": 4},
	&"prop_haie_v_01": {"width": 1, "depth": 4},
	&"int_centre_comptoir": {"width": 5, "depth": 1},
	&"int_centre_terminal": {"width": 2, "depth": 1},
	&"int_centre_banquette": {"width": 2, "depth": 1},
	&"int_plante": {"width": 1, "depth": 1},
	&"int_boutique_caisse": {"width": 5, "depth": 1},
	&"int_boutique_rayon_mural": {"width": 3, "depth": 1},
	&"int_boutique_presentoir": {"width": 3, "depth": 1},
	&"ground_hautes_herbes_01": {"traversable": true, "align": ALIGN_CENTRE},
}


static func has_rule(id: StringName) -> bool:
	return RULES.has(id)


static func get_ids() -> Array[StringName]:
	return RULES.keys()


## Cases solides relatives à la case d'ancrage (vide pour un objet traversable).
static func footprint(id: StringName) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var rule: Dictionary = RULES.get(id, {})
	if rule.is_empty() or rule.get("traversable", false):
		return cells
	if rule.has("cells"):
		cells.assign(rule["cells"])
		return cells
	var width: int = rule["width"]
	var depth: int = rule["depth"]
	var left := -floori(width / 2.0) if align(id) == ALIGN_EDGE else -floori((width - 1) / 2.0)
	var open: Array = rule.get("open", [])
	for y in range(-(depth - 1), 1):
		for x in range(left, left + width):
			var cell := Vector2i(x, y)
			if not open.has(cell):
				cells.append(cell)
	return cells


static func is_traversable(id: StringName) -> bool:
	return bool((RULES.get(id, {}) as Dictionary).get("traversable", false))


## Cases laissées libres dans le rectangle (portes), relatives à la case d'ancrage.
static func open_cells(id: StringName) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign((RULES.get(id, {}) as Dictionary).get("open", []))
	return cells


static func layer(id: StringName) -> StringName:
	return (RULES.get(id, {}) as Dictionary).get("layer", LAYER_ENTITIES)


static func has_wind(id: StringName) -> bool:
	return bool((RULES.get(id, {}) as Dictionary).get("wind", false))


static func fades(id: StringName) -> bool:
	return bool((RULES.get(id, {}) as Dictionary).get("fade", false))


static func uses_material(id: StringName) -> bool:
	return bool((RULES.get(id, {}) as Dictionary).get("material", true))


## Pied de l'objet dans son image (pixels) : [param image_size] (milieu du bas) sauf
## « origin ».
static func origin(id: StringName, image_size: Vector2) -> Vector2:
	var rule: Dictionary = RULES.get(id, {})
	if rule.has("origin"):
		return rule["origin"]
	return Vector2(image_size.x / 2.0, image_size.y)


## Bord (pied sur le bord gauche de la case d'ancrage) ou milieu de case.
static func align(id: StringName) -> StringName:
	var rule: Dictionary = RULES.get(id, {})
	if rule.has("align"):
		return rule["align"]
	return ALIGN_EDGE if int(rule.get("width", 1)) % 2 == 0 else ALIGN_CENTRE


## Position monde du pied pour que la case d'ancrage soit [param anchor] (bas de la case ;
## bord gauche ou milieu selon [method align]).
static func foot_position(id: StringName, anchor: Vector2i) -> Vector2:
	var x := float(anchor.x * Grid.TILE_SIZE)
	if align(id) == ALIGN_CENTRE:
		x += Grid.HALF_TILE
	return Vector2(x, float((anchor.y + 1) * Grid.TILE_SIZE))
