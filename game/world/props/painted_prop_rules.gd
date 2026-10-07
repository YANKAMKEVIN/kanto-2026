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
## « material » : faux = sprite sans shader (le massif du prototype n'en avait pas) ;
## « shadow » : vrai = ombre portée et ombre de contact (**faux par défaut** : seuls les
## bâtiments, `bldg_*`, en ont ; petits objets, végétation et mobilier posés au sol non).
const RULES: Dictionary[StringName, Dictionary] = {
	&"bldg_centre_01": {"shadow": true, "width": 8, "depth": 4, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_boutique_01": {"shadow": true, "width": 8, "depth": 4, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_arene_01": {"shadow": true, "width": 10, "depth": 4, "fade": true},
	&"bldg_maison_a_01": {"shadow": true, "width": 6, "depth": 3, "fade": true},
	&"bldg_maison_b_01": {"shadow": true, "width": 5, "depth": 3, "fade": true},
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
	# Série 07, passe 2 : deux nouveaux modèles de maisons, portail ouvert (on le traverse :
	# poteaux sur les bords de la case du passage, traverses sur les clôtures voisines),
	# buissons, garde-corps posé sur le haut d'un mur (la rangée du mur est déjà bloquée),
	# arbre fruitier, petit mobilier de jardin.
	&"bldg_maison_c_01": {"shadow": true, "width": 6, "depth": 3, "fade": true},
	&"bldg_maison_d_01": {"shadow": true, "width": 5, "depth": 3, "fade": true},
	&"prop_portail_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"prop_buisson_a_01": {"width": 1, "depth": 1},
	&"prop_buisson_b_01": {"width": 1, "depth": 1},
	&"prop_buisson_c_01": {"width": 2, "depth": 1},
	&"prop_balustrade_01": {"traversable": true, "align": ALIGN_EDGE},
	&"tree_fruitier_01": {"width": 1, "depth": 1, "wind": true, "fade": true},
	&"prop_tonneau_01": {"width": 1, "depth": 1},
	&"prop_caisses_01": {"width": 1, "depth": 1},
	&"prop_boite_lettres_01": {"width": 1, "depth": 1},
	&"prop_pots_fleurs_01": {"width": 1, "depth": 1},
	&"prop_linge_01": {"width": 3, "depth": 1},
	&"int_centre_comptoir": {"width": 5, "depth": 1},
	&"int_centre_terminal": {"width": 2, "depth": 1},
	&"int_centre_banquette": {"width": 2, "depth": 1},
	&"int_plante": {"width": 1, "depth": 1},
	&"int_boutique_caisse": {"width": 5, "depth": 1},
	&"int_boutique_rayon_mural": {"width": 3, "depth": 1},
	&"int_boutique_presentoir": {"width": 3, "depth": 1},
	&"ground_hautes_herbes_01": {"traversable": true, "align": ALIGN_CENTRE},
	# --- Intégration du monde peint, DA.0 (docs/tech/integration-da-bourg-route1.md) ---
	# Emprises de `proto/da_jadielle/emprises.gd`. Série 06 : Bourg Palette. Portes des
	# maisons et du labo laissées libres (« open ») au bas de l'emprise, sous la porte peinte :
	# la carte y pose son passage (défaut DA.0 ; le labo a une double porte, comme le Centre).
	&"bldg_maison_joueur_01": {"shadow": true, "width": 6, "depth": 3, "fade": true,
		"open": [Vector2i(-1, 0)]},
	&"bldg_maison_rival_01": {"shadow": true, "width": 6, "depth": 3, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_labo_01": {"shadow": true, "width": 10, "depth": 4, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_serre_01": {"shadow": true, "width": 3, "depth": 2, "fade": true},
	&"tree_ancien_01": {"width": 4, "depth": 3, "wind": true, "fade": true},
	&"prop_cloture_piquets_01": {"width": 4, "depth": 1},
	# --- Série 10 : Route 2 (docs/tech/jalon-08.md §1.2). Poste : la case d'ancre (milieu du bas)
	# est la porte, ouverte ; la carte y pose le passage vers la forêt. ---
	&"bldg_poste_foret_01": {"shadow": true, "width": 7, "depth": 4, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"prop_grande_pierre_01": {"width": 3, "depth": 2},
	&"prop_cloture_piquets_01_court": {"width": 3, "depth": 1},
	&"prop_velo_01": {"width": 1, "depth": 1},
	&"prop_camionnette_01": {"width": 3, "depth": 2},
	# Posés à plat dans la couche du sol, on marche dessus : champ, ponton, escalier en bois.
	&"ground_champ_01": {"traversable": true, "layer": LAYER_GROUND},
	&"prop_ponton_01": {"traversable": true, "layer": LAYER_GROUND},
	&"relief_escalier_bois_01": {"traversable": true, "layer": LAYER_GROUND},
	&"prop_ronces_01": {"width": 2, "depth": 1},
	&"prop_tronc_couche_01": {"width": 3, "depth": 1},
	&"prop_rocher_mer_01": {"width": 2, "depth": 1},
	# Mêmes sources que des objets de Jadielle, à l'échelle du prototype de Bourg Palette.
	&"prop_buisson_a_01_bourg": {"width": 1, "depth": 1},
	&"prop_buisson_b_01_bourg": {"width": 1, "depth": 1},
	&"prop_buisson_c_01_bourg": {"width": 1, "depth": 1},
	&"prop_pots_fleurs_01_bourg": {"width": 1, "depth": 1},
	&"prop_linge_01_bourg": {"width": 3, "depth": 1},
	&"tree_fruitier_01_bourg": {"width": 1, "depth": 1, "wind": true, "fade": true},
	&"prop_haie_v_01_bourg": {"width": 1, "depth": 3},
	# Série 06B.
	&"prop_cloture_piquets_v_01": {"width": 1, "depth": 3},
	&"tree_c_01": {"width": 1, "depth": 1, "wind": true, "fade": true},
	&"tree_d_01": {"width": 1, "depth": 1, "wind": true, "fade": true},
	&"tree_e_01": {"width": 1, "depth": 1, "wind": true, "fade": true},
	&"prop_hortensias_01": {"width": 1, "depth": 1},
	&"prop_mangeoire_01": {"width": 1, "depth": 1},
	&"prop_epouvantail_01": {"width": 1, "depth": 1},
	&"prop_barque_01": {"width": 1, "depth": 2},
	&"prop_casiers_peche_01": {"width": 2, "depth": 1},
	# Oyats et petites pierres : sans emprise au prototype (on les frôle), restent traversables.
	&"prop_herbes_dune_01": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	&"prop_materiel_labo_01": {"width": 2, "depth": 1},
	&"prop_ratelier_velos_01": {"width": 2, "depth": 1},
	&"prop_brouette_01": {"width": 1, "depth": 1},
	&"prop_tas_bois_01": {"width": 2, "depth": 1},
	&"prop_arrosoir_seau_01": {"width": 1, "depth": 1},
	&"prop_pierres_01": {"traversable": true, "align": ALIGN_CENTRE},
	# Série 08 : Route 1. Le rebord se saute vers le sud : relief du sol sans emprise (la
	# donnée « ledge » est dans le `Ground` de la carte).
	&"prop_cloture_courte_01": {"width": 1, "depth": 1},
	&"tree_automne_01": {"width": 1, "depth": 1, "wind": true, "fade": true},
	&"prop_souche_01": {"width": 1, "depth": 1},
	&"relief_rebord_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"ground_hautes_herbes_jaune_01": {"traversable": true, "align": ALIGN_CENTRE},
	# Arbres de la forêt serrée ([DenseForest]) : posés par l'outil de la carte sur des cases de
	# forêt, déjà solides dans la carte : pas d'emprise propre, ni fondu (des centaines
	# d'arbres : aucun `_process`).
	&"tree_foret_01": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	&"tree_foret_02": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	&"tree_foret_03": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	&"tree_foret_04": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	&"tree_foret_05": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	&"tree_foret_06": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	&"tree_foret_07": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	&"tree_foret_08": {"traversable": true, "wind": true, "align": ALIGN_CENTRE},
	# Série 07 : intérieurs de Bourg Palette (cases occupées des plans du prototype,
	# `proto_interieur_bourg.gd`). Tapis : à plat, traversables. Escalier montant : seule la
	# rangée du haut est solide, la rangée du bas porte les passages vers l'étage.
	&"int_meuble_bas_01": {"width": 3, "depth": 1},
	&"int_canape_01": {"width": 3, "depth": 1},
	&"int_table_basse_01": {"width": 2, "depth": 1},
	&"int_table_repas_01": {"width": 3, "depth": 2},
	&"int_frigo_01": {"width": 1, "depth": 1},
	&"int_cuisine_01": {"width": 3, "depth": 1},
	&"int_escalier_montant_01": {"width": 2, "depth": 2,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"int_tele_01": {"width": 2, "depth": 1},
	&"int_porte_manteau_01": {"width": 1, "depth": 1},
	&"int_commode_pokeball_01": {"width": 1, "depth": 1},
	&"int_tapis_salon_01": {"traversable": true, "layer": LAYER_GROUND},
	&"int_tapis_plaid_01": {"traversable": true, "layer": LAYER_GROUND},
	&"int_lit_01": {"width": 2, "depth": 3},
	&"int_chevet_lampe_01": {"width": 1, "depth": 1},
	&"int_petite_etagere_01": {"width": 1, "depth": 1},
	&"int_bureau_pc_01": {"width": 3, "depth": 1},
	&"int_chaise_bureau_01": {"width": 1, "depth": 1},
	&"int_grande_etagere_01": {"width": 2, "depth": 2},
	&"int_sac_voyage_01": {"width": 1, "depth": 1},
	&"int_caisse_pokeballs_01": {"width": 2, "depth": 1},
	&"int_tapis_pokeball_01": {"traversable": true, "layer": LAYER_GROUND},
	&"int_tapis_carreaux_01": {"traversable": true, "layer": LAYER_GROUND},
	&"int_cuisiniere_hotte_01": {"width": 1, "depth": 1},
	&"int_bureau_angle_pc_01": {"width": 2, "depth": 1},
	&"int_chaise_gamer_01": {"width": 1, "depth": 1},
	&"int_commode_01": {"width": 2, "depth": 1},
	&"int_lit_pokeball_01": {"width": 2, "depth": 3},
	&"int_lavabo_01": {"width": 2, "depth": 1},
	&"int_douche_01": {"width": 1, "depth": 2},
	&"int_meuble_chaussures_01": {"width": 1, "depth": 1},
	&"int_cloison_v_01": {"width": 1, "depth": 3},
	&"int_cloison_h_01": {"width": 5, "depth": 1},
	&"int_aquarium_01": {"width": 1, "depth": 1},
	&"int_incubateur_01": {"width": 2, "depth": 2},
	&"int_machines_labo_01": {"width": 2, "depth": 1},
	&"int_bureau_chen_01": {"width": 3, "depth": 1},
	&"int_classeur_01": {"width": 1, "depth": 1},
	&"int_etagere_labo_01": {"width": 2, "depth": 2},
	&"int_vitrine_pokeballs_01": {"width": 1, "depth": 3},
	&"int_long_comptoir_01": {"width": 5, "depth": 1},
	&"int_table_starters_01": {"width": 3, "depth": 2},
	&"int_paillasse_01": {"width": 3, "depth": 1},
	&"int_tabouret_01": {"width": 1, "depth": 1},
	&"int_escalier_deco_01": {"width": 3, "depth": 2},
	&"int_tapis_rouge_01": {"traversable": true, "layer": LAYER_GROUND},
	&"int_tapis_labo_pokeball_01": {"traversable": true, "layer": LAYER_GROUND},
}


## Règle des ombres (retours de Kevin, 2026-10-05) : **aucun petit objet n'a d'ombre** (ni
## portée ni de contact : elle donnait une impression de suspension) ; seuls les bâtiments
## (« shadow »: true dans [constant RULES]) gardent les leurs pour l'instant. Un nouvel objet
## est donc sans ombre sans autre réglage.


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


## Vrai pour les seuls objets marqués « shadow » (bâtiments) : les autres scènes n'ont ni
## `CastShadow` ni `ContactShadow`, même si le catalogue fournit les images d'ombre.
static func casts_shadows(id: StringName) -> bool:
	return bool((RULES.get(id, {}) as Dictionary).get("shadow", false))


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
