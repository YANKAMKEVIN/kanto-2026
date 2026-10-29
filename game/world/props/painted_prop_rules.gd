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
	# Tour Pokémon (J19 T8) : panneau du Scope, même emprise que le panneau de bois.
	&"prop_panneau_scope_01": {"width": 1, "depth": 1},
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
	# Série 11 : Forêt de Jade (docs/tech/jalon-09.md §2.8.4). Le tronc incliné s'appuie sur les
	# deux cases `I` du repère sud (pied sur le bord entre elles, mesuré sur l'image : pied du
	# tronc à droite, 288 px de la gauche) ; il monte vers le haut-gauche au-dessus de cases de
	# forêt : ni fondu ni vent. Petits objets : aucune ombre.
	&"prop_tronc_incline_01": {"cells": [Vector2i(-1, 0), Vector2i(0, 0)], "align": ALIGN_EDGE,
		"origin": Vector2(288, 304)},
	&"prop_grande_souche_01": {"width": 3, "depth": 2},
	&"prop_racines_01": {"width": 1, "depth": 2},
	&"prop_sac_rando_01": {"width": 1, "depth": 1},
	# Série 12 : Argenta et Route 2 nord (docs/design/fiches-assets/serie-12-argenta.md, emprises
	# = cases de la grille `tools/plans/argenta.txt`, toit compris, toutes bloquées sauf la porte).
	&"bldg_musee_argenta_01": {"shadow": true, "width": 12, "depth": 9, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_arene_argenta_01": {"shadow": true, "width": 12, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_maison_argenta_01": {"shadow": true, "width": 7, "depth": 6, "fade": true,
		"open": [Vector2i(0, 0)]},
	# Poste vu du nord (Route 2 nord, ancre (15, 23) au bord sud de la carte) : porte au bord
	# HAUT de l'emprise (0, −2). Couche du sol : le joueur est toujours au nord du bâtiment et
	# passe devant l'avant-corps de la porte (dans `Entities`, le toit le cacherait). Pied
	# déplacé (« origin ») pour que le seuil peint (y 249 de l'image 672 × 579) tombe au bas de
	# la case de la porte : le bas de l'image (1,4 case) sort de la carte, coupé net.
	&"bldg_poste_foret_nord_01": {"width": 7, "depth": 3, "open": [Vector2i(0, -2)],
		"layer": LAYER_GROUND, "origin": Vector2(336, 441)},
	&"prop_rocher_place_01": {"width": 3, "depth": 3},
	&"prop_blocs_tailles_01": {"width": 3, "depth": 2},
	# Paroi de montagne (4 modules d'≈ 5 × 3 cases) : relief du sol sans emprise, les cases `K`
	# sont bloquées par la carte (comme les murets de Jadielle) ; les modules se chevauchent.
	&"relief_paroi_01": {"traversable": true, "layer": LAYER_GROUND},
	&"relief_paroi_02": {"traversable": true, "layer": LAYER_GROUND},
	&"relief_paroi_03": {"traversable": true, "layer": LAYER_GROUND},
	&"relief_paroi_04": {"traversable": true, "layer": LAYER_GROUND},
	# Musée : vitrines et panneau 2 × 1, Pierre Lune 1 × 1 ; la porte du laboratoire ferme
	# l'arche du mur du fond (cases du mur déjà bloquées par la pièce) : sans emprise.
	&"int_vitrine_dome_01": {"width": 2, "depth": 1},
	&"int_vitrine_nautile_01": {"width": 2, "depth": 1},
	&"int_vitrine_pierre_lune_01": {"width": 1, "depth": 1},
	&"int_vitrine_journal_01": {"width": 2, "depth": 1},
	&"int_porte_labo_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"int_panneau_expo_01": {"width": 2, "depth": 1},
	# Arène : pilier 2 × 1, bloc bas 2 × 2 (il arrête la vision du Campeur), rocher 1 × 1.
	&"int_pilier_roche_01": {"width": 2, "depth": 1},
	&"int_rochers_bas_01": {"width": 2, "depth": 2},
	&"int_rochers_bas_02": {"width": 1, "depth": 1},
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
	# --- Série 14 : Route 3 et Mont Sélénite (J12 T6, fiche `serie-14-mont-selenite.md`). ---
	# Entrée de la grotte `Q` (module 4 × 3, ancre (74, 9)) : les deux cases de l'ouverture au
	# bas de l'emprise restent libres (la carte y pose le passage), le reste est bloqué.
	&"relief_entree_grotte_01": {"width": 4, "depth": 3,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	# Paroi d'ardoise (4 modules ≈ 5 × 3, comme la série 12) : relief du sol sans emprise, les
	# cases `K` / `#` sont bloquées par la carte ; les modules se chevauchent.
	&"relief_paroi_ardoise_01": {"traversable": true, "layer": LAYER_GROUND},
	&"relief_paroi_ardoise_02": {"traversable": true, "layer": LAYER_GROUND},
	&"relief_paroi_ardoise_03": {"traversable": true, "layer": LAYER_GROUND},
	&"relief_paroi_ardoise_04": {"traversable": true, "layer": LAYER_GROUND},
	# Parois de la grotte (faces, angles, bords, lèvre) : posées sur des cases `#` déjà solides
	# par `cave_map_kit` (T9), triées au pied dans `Entities` (une face passe devant un
	# personnage au nord de la masse), sans emprise propre. Pied au milieu d'une case (largeur
	# impaire : faces 3, bord 1, lèvre 3) ou sur un bord (angles de 2 cases).
	&"relief_paroi_grotte_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_grotte_02": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_grotte_03": {"traversable": true, "align": ALIGN_EDGE},
	&"relief_paroi_grotte_04": {"traversable": true, "align": ALIGN_EDGE},
	&"relief_paroi_grotte_05": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_grotte_06": {"traversable": true, "align": ALIGN_CENTRE},
	# Repères minéraux : colonne du carrefour 2 × 3, colonnes fines, rochers et éclats 1 × 1.
	&"prop_colonne_grotte_01": {"width": 2, "depth": 3},
	&"prop_colonne_grotte_02": {"width": 1, "depth": 1},
	&"prop_rocher_grotte_01": {"width": 1, "depth": 1},
	&"prop_rocher_grotte_02": {"width": 1, "depth": 1},
	&"prop_eclats_lune_01": {"width": 1, "depth": 1},
	&"prop_eclats_lune_02": {"width": 1, "depth": 1},
	# Mare `w` et puits de jour `j` : à plat dans la couche du sol (la mare est bloquée par la
	# grille, on marche dans la lumière du puits).
	&"prop_mare_grotte_01": {"traversable": true, "layer": LAYER_GROUND},
	&"decal_puits_jour_01": {"traversable": true, "layer": LAYER_GROUND, "material": false},
	# Camp et indices Rocket : lampe, caisses (1 × 1, empilées 2 × 1), projecteur, outils ;
	# tranchée de fouille 3 × 3 à plat (couche du sol, cases `F` bloquées).
	&"prop_lampe_chantier_01": {"width": 1, "depth": 1},
	&"prop_caisse_r_01": {"width": 1, "depth": 1},
	&"prop_caisse_r_02": {"width": 2, "depth": 1},
	&"prop_tranchee_01": {"width": 3, "depth": 3, "layer": LAYER_GROUND},
	&"prop_projecteur_01": {"width": 1, "depth": 1},
	&"prop_outils_fouille_01": {"width": 1, "depth": 1},
	# Échelles : warps « en marchant dessus », le décor ne bloque pas leur case ; couche du sol
	# (une échelle ne passe jamais devant le personnage qui la prend).
	&"prop_echelle_descend_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"prop_echelle_monte_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	# Dalle des fossiles 3 × 1 ; fossiles posés dessus (cases de la dalle, déjà bloquées) : sans
	# emprise (en jeu, les fossiles choisis sont des objets fixes `object/fossil_*`).
	&"prop_dalle_01": {"width": 3, "depth": 1},
	&"prop_fossile_dome_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"prop_fossile_nautile_01": {"traversable": true, "align": ALIGN_CENTRE},
	# Indices des objets cachés : la case de l'indice est bloquée (point d'examen).
	&"prop_indice_caillou_01": {"width": 1, "depth": 1},
	&"prop_indice_eclat_01": {"width": 1, "depth": 1},
	# --- Série 15 : Route 4, Azuria, Route 24 (J13 T5, fiche `serie-15-azuria.md`). ---
	# Arène (12 × 7, porte (40..41, 9)) et magasin de vélos (8 × 7, porte (38..39, 35)) :
	# emprise = toute l'image, les deux cases de la porte restent libres au bas.
	&"bldg_arene_azuria_01": {"shadow": true, "width": 12, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_velos_01": {"shadow": true, "width": 8, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	# Îlot de la Grotte Azurée : à plat sur l'eau (couche du sol), les cases `K` et `A` sont
	# bloquées par la carte.
	&"relief_grotte_azuree_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	# Quais et berges : modules posés **dans les cases d'eau** (déjà solides) par
	# `cerulean_map_kit`, dans la couche du sol ; 06 = escalier de quai posé à la main.
	&"relief_quai_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_quai_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_quai_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_quai_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_quai_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_quai_06": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_berge_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_berge_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_berge_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_berge_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_berge_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	# Touffe de roseaux isolée dans l'eau (1 × 1, case d'eau).
	&"prop_roseaux_01": {"width": 1, "depth": 1},
	# Tabliers de pont (cases `B`, praticables) : à plat, sous les personnages. Ville : 2, 3 de
	# large (nord-sud) et est-ouest ; Pont Pépite : 3 variantes de 2 de large.
	&"prop_pont_ville_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"prop_pont_ville_03_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"prop_pont_ville_ew_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"prop_pont_pepite_tablier_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"prop_pont_pepite_tablier_02": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"prop_pont_pepite_tablier_03": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	# Garde-corps et piles du Pont Pépite : posés dans les cases d'eau qui flanquent le tablier
	# (jamais sur une case praticable), triés au pied.
	&"prop_pont_pepite_garde_corps_01": {"width": 1, "depth": 1},
	&"prop_pont_pepite_pile_01": {"width": 1, "depth": 1},
	# Mobilier de ville d'eau.
	&"prop_jardiniere_pierre_01": {"width": 1, "depth": 1},
	&"prop_jardiniere_pierre_02": {"width": 1, "depth": 1},
	&"prop_arbre_bac_01": {"width": 1, "depth": 1, "fade": true},
	&"prop_banc_pierre_01": {"width": 2, "depth": 1},
	&"prop_lampadaire_quai_01": {"width": 1, "depth": 1},
	&"prop_bitte_01": {"width": 1, "depth": 1},
	# Cambriolage : clôture arrachée 3 × 1, porte condamnée posée sur la façade (case `f` déjà
	# bloquée), pot renversé, trou dans la clôture, ruban 2 × 1.
	&"prop_cloture_arrachee_01": {"width": 3, "depth": 1},
	&"prop_porte_condamnee_01": {"width": 1, "depth": 1},
	&"prop_pot_renverse_01": {"width": 1, "depth": 1},
	&"prop_cloture_trou_01": {"width": 1, "depth": 1},
	&"prop_ruban_01": {"width": 2, "depth": 1},
	# Fermetures : palissade de chantier 3 × 1 (×2), barrière à croisillon 2 × 1.
	&"prop_palissade_chantier_01": {"width": 3, "depth": 1},
	&"prop_palissade_chantier_02": {"width": 3, "depth": 1},
	&"prop_barriere_croisillon_01": {"width": 2, "depth": 1},
	# Route 4 : rebord et versant en roche ardoise (cases du rebord / `~` bloquées par la carte).
	&"relief_rebord_ardoise_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_falaise_ardoise_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_falaise_ardoise_02": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	# Intérieurs : plongeoir 2 × 1 contre le mur du fond, banc de piscine 2 × 1, porte-bouées,
	# vélos exposés 2 × 1, étagère de casques 4 × 1.
	&"int_plongeoir_01": {"width": 2, "depth": 1},
	&"int_banc_piscine_01": {"width": 2, "depth": 1},
	&"int_porte_bouees_01": {"width": 1, "depth": 1},
	&"int_velo_expose_01": {"width": 2, "depth": 1},
	&"int_velo_expose_02": {"width": 2, "depth": 1},
	&"int_velo_expose_03": {"width": 2, "depth": 1},
	&"int_etagere_casques_01": {"width": 4, "depth": 1},
	# --- Série 16 : Route 25, Cap d'Azuria, maison de Léo (J14 T13, fiche `serie-16-*.md`). ---
	# Maison du Cap (8 × 6, porte aux 4e et 5e colonnes de la rangée du bas, ancre (72, 11)).
	&"bldg_maison_leo_01": {"shadow": true, "width": 8, "depth": 6, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	# Rivage rocheux : modules posés **sur les cases `R` au contact de la mer** par
	# `coast_map_kit` (rect explicite, couche du sol), jamais sur une case praticable.
	&"relief_rivage_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_rivage_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_rivage_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_rivage_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_rivage_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_rivage_06": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	# Indice du coquillage (objet caché O4, case `R` bloquée par la grille) ; clôture réparée
	# d'Azuria (décor seul, T20b).
	&"prop_indice_coquillage_01": {"width": 1, "depth": 1},
	&"prop_cloture_reparee_01": {"width": 1, "depth": 1},
	# Maison de Léo : cabines (machine + armoire, 3 × 2), console 2 × 1, module 1 × 1, écran
	# 1 × 1, bureau 3 × 1, bibliothèque vue de côté 1 × 2.
	&"int_cabine_teleport_01": {"width": 3, "depth": 2},
	&"int_console_leo_01": {"width": 2, "depth": 1},
	&"int_module_leo_01": {"width": 1, "depth": 1},
	&"int_ecran_diagnostic_01": {"width": 1, "depth": 1},
	&"int_bureau_leo_01": {"width": 3, "depth": 1},
	&"int_bibliotheque_cote_01": {"width": 1, "depth": 2},
	# --- Série 17 : Routes 5 et 6, souterrain, Carmin-sur-Mer (J15 T11, fiche
	# `serie-17-carmin.md`). Bâtiments : emprise = toute l'image, porte(s) libre(s) au bas.
	# Postes et entrées du souterrain : 7 × 4 (Route 5) ; sur la Route 6 la carte n'en bloque que
	# 7 × 3 (même image, seule la profondeur change : la carte T14 pose ses propres cases).
	&"bldg_pension_01": {"shadow": true, "width": 7, "depth": 6, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_poste_safrania_01": {"shadow": true, "width": 7, "depth": 4, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_entree_souterrain_01": {"shadow": true, "width": 7, "depth": 4, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_arene_carmin_01": {"shadow": true, "width": 12, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_fan_club_01": {"shadow": true, "width": 8, "depth": 6, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_maison_pecheur_01": {"shadow": true, "width": 7, "depth": 6, "fade": true,
		"open": [Vector2i(0, 0)]},
	# S.S. Anne : trois tranches de 10, 9 et 10 cases, objets séparés (contrat du J16 : l'état
	# « parti » retire les trois). Sans ombre ni emprise : les cases `N` de la grille sont déjà
	# bloquées et l'accès `E` (coupée) reste libre ; la carte T14 règle le z.
	&"bldg_ss_anne_proue_01": {"traversable": true, "align": ALIGN_EDGE},
	&"bldg_ss_anne_milieu_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"bldg_ss_anne_poupe_01": {"traversable": true, "align": ALIGN_EDGE},
	# Vue lointaine du port (belvédère de la Route 6) : décor posé au-dessus des arbres.
	&"prop_vue_port_01": {"traversable": true, "align": ALIGN_EDGE},
	# Bords de quai en bois : modules posés **dans les cases d'eau** de la frontière (couche du
	# sol, jamais sur une case praticable) ; 03 = côté d'un ponton (0,25 case), 05 = départ.
	&"relief_quai_bois_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_quai_bois_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_quai_bois_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_quai_bois_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_quai_bois_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"prop_pieu_quai_01": {"width": 1, "depth": 1},
	# Port : jeune arbre de l'Arène (objet séparé, retirable par `cut_vermilion_gym_bush`),
	# passerelle (on marche dessus), grue, bitte à amarre, cordage à plat, caisses.
	&"prop_jeune_arbre_arene_01": {"width": 2, "depth": 1, "wind": true, "fade": true},
	&"prop_passerelle_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"prop_grue_quai_01": {"width": 2, "depth": 1},
	&"prop_bitte_amarre_01": {"width": 1, "depth": 1},
	&"prop_cordage_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"prop_caisses_port_01": {"width": 2, "depth": 1},
	# Routes : indices des objets cachés (case bloquée = point d'examen) ; nénuphars à plat
	# sur l'eau (01 = trio avec fleur, 02 et 03 = feuilles seules).
	&"prop_indice_tronc_01": {"width": 1, "depth": 1},
	&"prop_indice_joncs_01": {"width": 1, "depth": 1},
	&"prop_nenuphars_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"prop_nenuphars_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"prop_nenuphars_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	# Souterrain : murs maçonnés posés sur les cases `#` (cases bloquées par la carte) ; 01/02 =
	# face au sud, 03 = couronnement, 04 à 06 = côtés et angle. Escaliers = warps `STEP_ON`.
	&"relief_mur_souterrain_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_souterrain_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_souterrain_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_souterrain_04": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_mur_souterrain_05": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_mur_souterrain_06": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"prop_escalier_souterrain_monte_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"prop_escalier_souterrain_descend_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"prop_stele_01": {"width": 1, "depth": 1},
	&"prop_banc_souterrain_01": {"width": 1, "depth": 1},
	&"prop_pierre_descellee_01": {"width": 1, "depth": 1},
	&"prop_applique_01": {"traversable": true, "align": ALIGN_CENTRE},
	# Intérieurs : comptoir de la Pension 3 × 1, escalier descendant (warp `STEP_ON`, couche du
	# sol), panier 1 × 1, fauteuil 1 × 1, vitrine 2 × 2, tableau mural (le mur est déjà bloqué).
	&"int_comptoir_pension_01": {"width": 3, "depth": 1},
	&"int_escalier_descendant_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"int_panier_pokemon_01": {"width": 1, "depth": 1},
	&"int_fauteuil_president_01": {"width": 1, "depth": 1},
	&"int_vitrine_rubans_01": {"width": 2, "depth": 2},
	&"int_tableau_port_01": {"traversable": true, "align": ALIGN_CENTRE},
	# --- Série 19 : Route 11, Cave Taupiqueur, Route 2 est et son poste (J17 T14, fiche
	# `serie-19-chemins.md`). Bouches vues de dehors (talus, paroi) : module 4 × 3, les deux cases
	# de l'ouverture au bas restent libres (la carte y pose les warps), comme l'entrée de la
	# grotte de la série 14.
	&"relief_bouche_talus_01": {"width": 4, "depth": 3,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"relief_bouche_paroi_01": {"width": 4, "depth": 3,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	# Bouches vues de l'intérieur de la Cave (rangées 79 et 0, 4 cases de large) : posées sur des
	# cases déjà solides ou des warps de la carte, sans emprise propre.
	&"relief_bouche_cave_sud_01": {"traversable": true, "align": ALIGN_EDGE},
	&"relief_bouche_cave_nord_01": {"traversable": true, "align": ALIGN_EDGE},
	# Parois de grès de la Cave (mêmes rôles que les parois de la grotte : faces 3, 3, angles 2, 2,
	# bord 1, lèvre 3) : posées sur des cases `#` déjà solides, triées au pied.
	&"relief_paroi_sable_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_sable_02": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_sable_03": {"traversable": true, "align": ALIGN_EDGE},
	&"relief_paroi_sable_04": {"traversable": true, "align": ALIGN_EDGE},
	&"relief_paroi_sable_05": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_sable_06": {"traversable": true, "align": ALIGN_CENTRE},
	# Bord sud de la digue (rangée 24, 2 cases de large) : relief à plat sur des cases d'eau.
	&"relief_digue_bord_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_digue_bord_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	# Barrière ouverte (FUTUR B) : le passage de 2 cases est libre entre les poteaux, pied au
	# poteau sud ; aucune emprise (l'état fermé est la `ClosedGate` de la carte).
	&"prop_barriere_ouverte_01": {"traversable": true, "align": ALIGN_CENTRE},
	# Poste de recherche (pièce du poste) : étagère 2 × 1, table de lecture 3 × 1, caisse 1 × 1 ;
	# la carte murale est accrochée à un mur déjà bloqué.
	&"int_etagere_lampes_01": {"width": 2, "depth": 1},
	&"int_carte_murale_01": {"traversable": true, "align": ALIGN_EDGE},
	&"int_table_lecture_01": {"width": 3, "depth": 1},
	&"int_caisse_lampes_01": {"width": 1, "depth": 1},
	# --- Série 18 : S.S. Anne et Arène de Carmin (J16 T10, fiche `serie-18-ss-anne.md`). Les
	# meubles sont posés par `build_painted_interiors.gd` en rectangles de la grille (« furniture »,
	# emprise écrite dans l'instance) ; ces règles donnent la même emprise.
	&"int_banquette_ss_anne_01": {"width": 2, "depth": 1},
	&"int_comptoir_accueil_ss_anne_01": {"width": 4, "depth": 1},
	&"int_table_restaurant_01": {"width": 2, "depth": 1},
	&"int_comptoir_cuisine_01": {"width": 4, "depth": 1},
	&"int_lit_cabine_01": {"width": 2, "depth": 2},
	&"int_armoire_cabine_01": {"width": 1, "depth": 1},
	&"int_table_hublot_01": {"width": 2, "depth": 1},
	&"int_bureau_capitaine_01": {"width": 3, "depth": 1},
	&"int_lavabo_cabine_01": {"width": 1, "depth": 1},
	&"int_table_cartes_01": {"width": 2, "depth": 1},
	&"int_caisses_cale_01": {"width": 2, "depth": 2},
	&"int_caisses_cale_02": {"width": 3, "depth": 2},
	&"int_poubelle_arene_01": {"width": 1, "depth": 1},
	&"int_armoire_electrique_01": {"width": 1, "depth": 1},
	&"int_armoire_electrique_02": {"width": 1, "depth": 1},
	# Barrière : cases `B` praticables une fois ouverte (les PNJ objets `electric_barrier` les
	# bloquent avant) ; pylônes éteints toujours là, barrière active = objet fixe du segment du
	# milieu. `int_barriere_active_01` sert d'image à cet objet (aucune carte ne la pose).
	&"int_barriere_active_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"int_barriere_coupee_01": {"traversable": true, "align": ALIGN_CENTRE},
	# Pont extérieur : bastingages dans la couche du sol (cases `r` bloquées par la grille), la
	# superstructure ouest dans `Entities` (cases `K` bloquées) ; chaises longues et bouées
	# bloquent leurs cases.
	&"relief_bastingage_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_bastingage_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_bastingage_sud_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"relief_bastingage_est_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_bastingage_angle_ne_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_bastingage_angle_se_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"bldg_ss_anne_superstructure_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"prop_chaises_longues_01": {"width": 2, "depth": 1},
	&"prop_bouee_01": {"width": 1, "depth": 1},
	# --- Série 21 : Routes 9 et 10, Grotte Sombre, Lavanville, Tour Pokémon (J18 T6, fiche
	# `serie-21-j18.md`). ---
	# Tour Pokémon 12 × 11 (porte double aux 6e et 7e colonnes), Maison des Pokémon 8 (porte aux
	# 4e et 5e colonnes), maison d'habitants 7 (porte à la 4e colonne, comme la maison d'Argenta,
	# J18 T14) : emprise = largeur de l'image.
	&"bldg_tour_pokemon_01": {"shadow": true, "width": 12, "depth": 11, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_maison_pokemon_01": {"shadow": true, "width": 8, "depth": 5, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_maison_lavanville_01": {"shadow": true, "width": 7, "depth": 5, "fade": true,
		"open": [Vector2i(0, 0)]},
	# Lointains (centrale de la Route 10, silhouette de la Tour) : la carte bloque ses cases.
	&"bldg_centrale_lointaine_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"prop_tour_lointaine_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"prop_grande_colonne_01": {"width": 5, "depth": 6},
	&"prop_flaque_grotte_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	# Parois de la Grotte Sombre : mêmes rôles et ancrages que `relief_paroi_grotte_01..06`.
	&"relief_paroi_grotte_sombre_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_grotte_sombre_02": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_grotte_sombre_03": {"traversable": true, "align": ALIGN_EDGE},
	&"relief_paroi_grotte_sombre_04": {"traversable": true, "align": ALIGN_EDGE},
	&"relief_paroi_grotte_sombre_05": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_grotte_sombre_06": {"traversable": true, "align": ALIGN_CENTRE},
	&"relief_paroi_fendue_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"prop_racines_plafond_01": {"width": 1, "depth": 2},
	&"prop_racines_plafond_02": {"width": 2, "depth": 2},
	&"prop_rocher_grotte_sombre_01": {"width": 1, "depth": 1},
	&"prop_rocher_grotte_sombre_02": {"width": 1, "depth": 1},
	# Lavanville : buis, haie (2 cases), fleurs pâles, if du parvis.
	&"prop_buis_taille_01": {"width": 1, "depth": 1},
	&"prop_buis_taille_02": {"width": 1, "depth": 1},
	&"prop_haie_taillee_01": {"width": 2, "depth": 1},
	&"prop_fleurs_pales_01": {"width": 1, "depth": 1},
	&"prop_fleurs_pales_02": {"width": 2, "depth": 1},
	&"prop_if_taille_01": {"width": 1, "depth": 1},
	# Céladopole (série 22 bis, intégrée : façades peintes aux identifiants, tailles et emprises des
	# provisoires du J20 T16) : emprise = toute l'image, porte(s) libre(s) au bas (la carte pose
	# ses passages). Maison du toit : 5 × 4 sur la terrasse.
	&"bldg_grand_magasin_01": {"shadow": true, "width": 14, "depth": 9, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_residence_01": {"shadow": true, "width": 12, "depth": 8, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_escalier_service_01": {"shadow": true, "width": 4, "depth": 4, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_casino_01": {"shadow": true, "width": 12, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_coin_lots_01": {"shadow": true, "width": 8, "depth": 7, "fade": true},
	&"bldg_arene_celadopole_01": {"shadow": true, "width": 12, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_restaurant_01": {"shadow": true, "width": 8, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_hotel_01": {"shadow": true, "width": 10, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_maison_chef_01": {"shadow": true, "width": 7, "depth": 6, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_maison_toit_01": {"shadow": true, "width": 5, "depth": 4, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"prop_fontaine_01": {"width": 2, "depth": 2},
	# Safrania (J26 T6 ; façades peintes du lot DAF.3, `tools/art/daf3.py`, aux tailles des provisoires de
	# `placeholders_safrania.py`) : emprise = l'image
	# entière (rectangles de `tools/plans/safrania.txt`), porte(s) libre(s). Arène : porte d'une
	# case (7e colonne) ; postes : porte tournée vers la ville (nord : en bas ; sud : en haut ;
	# ouest : à droite ; est : à gauche).
	&"bldg_sylphe_safrania_01": {"shadow": true, "width": 14, "depth": 17, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_arene_safrania_01": {"shadow": true, "width": 12, "depth": 7, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_dojo_safrania_01": {"shadow": true, "width": 10, "depth": 7, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_maison_safrania_01": {"shadow": true, "width": 7, "depth": 6, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_maison_safrania_02": {"shadow": true, "width": 7, "depth": 6, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_maison_safrania_03": {"shadow": true, "width": 7, "depth": 6, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_immeuble_safrania_01": {"shadow": true, "width": 7, "depth": 6, "fade": true},
	&"bldg_immeuble_safrania_02": {"shadow": true, "width": 7, "depth": 6, "fade": true},
	&"bldg_immeuble_safrania_03": {"shadow": true, "width": 7, "depth": 6, "fade": true},
	&"bldg_immeuble_bas_safrania_01": {"shadow": true, "width": 8, "depth": 4, "fade": true},
	&"bldg_immeuble_bas_safrania_02": {"shadow": true, "width": 6, "depth": 4, "fade": true},
	&"bldg_poste_safrania_nord_01": {"shadow": true, "width": 4, "depth": 3, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_poste_safrania_sud_01": {"shadow": true, "width": 4, "depth": 3, "fade": true,
		"open": [Vector2i(-1, -2), Vector2i(0, -2)]},
	&"bldg_poste_safrania_ouest_01": {"shadow": true, "width": 3, "depth": 5, "fade": true,
		"open": [Vector2i(1, -2), Vector2i(1, -1)]},
	&"bldg_poste_safrania_est_01": {"shadow": true, "width": 3, "depth": 5, "fade": true,
		"open": [Vector2i(-1, -2), Vector2i(-1, -1)]},
	# Tour (intérieur, mutualisé avec le J19) : murs sur le modèle de `relief_mur_souterrain_*`,
	# escalier montant dans le mur (warp `STEP_ON`), tombes, bougeoir, comptoir 4 × 1, banc.
	&"relief_mur_tour_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_tour_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_tour_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_tour_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_tour_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_escalier_tour_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"int_tombe_tour_01": {"width": 1, "depth": 1},
	&"int_tombe_tour_02": {"width": 1, "depth": 1},
	&"int_tombe_tour_03": {"width": 1, "depth": 1},
	&"int_bougeoir_tour_01": {"width": 1, "depth": 1},
	&"int_comptoir_tour_01": {"width": 4, "depth": 1},
	&"int_banc_tour_01": {"width": 1, "depth": 1},
	# Repaire Rocket (série 22 bis, modules sur le modèle de la Tour) : murs, caisses, conduite,
	# consoles, bureau de Giovanni 4 × 2, escaliers dans le mur (warp `STEP_ON`), flèches et disque
	# d'arrêt peints au sol (décalcomanies 1 case), porte d'ascenseur (face de mur 2 cases) et
	# porte du bureau (192 × 96, lue en direct par `build_rocket_hideout.gd`).
	&"relief_mur_repaire_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_repaire_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_repaire_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_repaire_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_repaire_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"int_caisse_repaire_01": {"width": 1, "depth": 1},
	&"int_conduite_repaire_01": {"width": 1, "depth": 1},
	&"int_console_repaire_01": {"width": 1, "depth": 1},
	&"int_bureau_giovanni_01": {"width": 4, "depth": 2},
	&"int_escalier_repaire_monte_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"int_escalier_repaire_descend_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"decal_fleche_repaire_01": {"traversable": true, "layer": LAYER_GROUND, "material": false},
	&"decal_fleche_repaire_01_haut": {"traversable": true, "layer": LAYER_GROUND,
		"material": false},
	&"decal_fleche_repaire_01_bas": {"traversable": true, "layer": LAYER_GROUND, "material": false},
	&"decal_fleche_repaire_01_gauche": {"traversable": true, "layer": LAYER_GROUND,
		"material": false},
	&"decal_arret_repaire_01": {"traversable": true, "layer": LAYER_GROUND, "material": false},
	&"int_porte_ascenseur_repaire_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"hideout_office_door": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	# Casino de Céladopole (série 22 bis) : murs, machines et tabourets 1 × 1, comptoir à
	# juxtaposer bout à bout, affiche au mur, pan de mur coulissant (96 × 96, lu en direct par
	# `build_game_corner.gd`).
	&"relief_mur_casino_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_casino_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_casino_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_casino_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_casino_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"int_machine_casino_01": {"width": 1, "depth": 1},
	&"int_machine_casino_02": {"width": 1, "depth": 1},
	&"int_tabouret_casino_01": {"width": 1, "depth": 1},
	&"int_comptoir_casino_01": {"width": 1, "depth": 1},
	&"int_affiche_casino_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"game_corner_wall": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	# Lot DAF.3 / DAF.4 (`tools/art/daf3.py`, modules sur le modèle du repaire) : murs de la Sylphe,
	# de l'Arène de Morgane, du Dojo et de l'Arène de Jadielle ; mobilier de la Sylphe d'une case
	# (bureau, armoire de serveurs, plante) ; escaliers et porte d'ascenseur dans le mur du fond ;
	# tapis de téléporteur et seuil de porte électronique peints au sol (1 case) ; paillasson de
	# 2 cases ; battants des portes électroniques (lus en direct par `build_silph_co.gd`).
	&"relief_mur_sylphe_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_sylphe_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_sylphe_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_sylphe_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_sylphe_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_morgane_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_morgane_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_morgane_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_morgane_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_morgane_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_dojo_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_dojo_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_dojo_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_dojo_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_dojo_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_jadielle_01": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_jadielle_02": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_jadielle_03": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_EDGE},
	&"relief_mur_jadielle_04": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"relief_mur_jadielle_05": {"traversable": true, "layer": LAYER_GROUND, "align": ALIGN_CENTRE},
	&"int_bureau_sylphe_01": {"width": 1, "depth": 1},
	&"int_serveur_sylphe_01": {"width": 1, "depth": 1},
	&"int_plante_sylphe_01": {"width": 1, "depth": 1},
	&"int_escalier_sylphe_monte_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"int_escalier_sylphe_descend_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"int_porte_ascenseur_sylphe_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"decal_teleporteur_sylphe_01": {"traversable": true, "layer": LAYER_GROUND,
		"material": false},
	&"decal_seuil_sylphe_01": {"traversable": true, "layer": LAYER_GROUND,
		"material": false},
	&"int_paillasson_sylphe_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"int_porte_sylphe_h_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	&"int_porte_sylphe_v_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_EDGE},
	# J29 (QA A17) : porte de la Ligue posée dans le mur du fond du hall du Plateau Indigo,
	# comme la porte du laboratoire du Musée (rangées du mur déjà bloquées) : sans emprise.
	&"int_porte_ligue_01": {"traversable": true, "align": ALIGN_CENTRE},
	# Lot DAF.4 (`tools/art/daf4.py`, `tools/build_daf4_caves.gd`) : rebords et escaliers du sol haut
	# de la Route Victoire et de la Grotte Azurée, interrupteurs (dalles au sol) ; la barrière est
	# une image posée dans le [FlagGate] (cases déjà bloquées par la logique) : sans emprise.
	&"relief_rebord_victoire_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_rebord_victoire_cote_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_escalier_victoire_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"decal_interrupteur_victoire_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"decal_interrupteur_victoire_enfonce_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_rebord_azuree_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_rebord_azuree_cote_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"relief_escalier_azuree_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"prop_barriere_victoire_01": {"traversable": true, "align": ALIGN_CENTRE},
	&"decal_trou_victoire_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	&"decal_trou_victoire_bouche_01": {"traversable": true, "layer": LAYER_GROUND,
		"align": ALIGN_CENTRE},
	# Façades du J29 (lot DAF.4, `tools/build_daf4_facades.gd`) : poste de la Ligue (Route 22 ouest,
	# 5 × 4, porte au milieu) et bâtiment de la Ligue (Plateau Indigo, 8 × 6, porte double).
	&"bldg_poste_route_22_01": {"shadow": true, "width": 5, "depth": 4, "fade": true,
		"open": [Vector2i(0, 0)]},
	&"bldg_ligue_01": {"shadow": true, "width": 8, "depth": 6, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	# Façades de Cramois'Île (lot DAF.9, `tools/build_daf9_ile.gd`) : 9 × 6, emprise = cases du
	# bâtiment de la grille (`cinnabar_island.txt`), portes doubles libres.
	&"bldg_manoir_ruine_01": {"shadow": true, "width": 9, "depth": 6, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
	&"bldg_arene_cramois_01": {"shadow": true, "width": 9, "depth": 6, "fade": true,
		"open": [Vector2i(0, 0), Vector2i(1, 0)]},
	&"bldg_labo_cramois_01": {"shadow": true, "width": 9, "depth": 6, "fade": true,
		"open": [Vector2i(-1, 0), Vector2i(0, 0)]},
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
