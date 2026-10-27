extends GutTest
## Objets peints (docs/tech/jalon-07.md §6.6, T3) : une scène WorldProp par objet du
## catalogue, emprise sur la grille de 96 px (règles du prototype), ombres pré-floutées, relief
## dans la couche du sol.

const CATALOGUE := "res://assets/world/catalogue.json"
const MANIFEST := "res://tools/art/manifeste.json"
const SCENES := "res://game/world/props/painted/"
## Les seuls objets peints qu'on traverse (jalon-07.md §6.6).
## Série 07 : murs de soutènement et escaliers de ville (la carte bloque la rangée du mur).
const TRAVERSABLE: Array[StringName] = [&"relief_escalier_01", &"ground_hautes_herbes_01",
	&"relief_muret_01", &"relief_escalier_ville_01", &"prop_portail_01", &"prop_balustrade_01",
	# DA.0 (integration-da-bourg-route1.md) : à plat (champ, ponton, escalier en bois, rebord,
	# tapis), herbes, oyats et petites pierres, arbres de forêt (les cases de forêt bloquent).
	&"ground_champ_01", &"prop_ponton_01", &"relief_escalier_bois_01", &"relief_rebord_01",
	&"ground_hautes_herbes_jaune_01", &"prop_herbes_dune_01", &"prop_pierres_01",
	&"int_tapis_salon_01", &"int_tapis_plaid_01", &"int_tapis_pokeball_01",
	&"int_tapis_carreaux_01", &"int_tapis_rouge_01", &"int_tapis_labo_pokeball_01",
	&"tree_foret_01", &"tree_foret_02", &"tree_foret_03", &"tree_foret_04",
	&"tree_foret_05", &"tree_foret_06", &"tree_foret_07", &"tree_foret_08",
	# Série 12 (J10) : paroi de montagne (cases `K` bloquées par la carte), porte du
	# laboratoire du Musée (dans le mur du fond, déjà bloqué).
	&"relief_paroi_01", &"relief_paroi_02", &"relief_paroi_03", &"relief_paroi_04",
	&"int_porte_labo_01",
	# Série 14 (J12) : parois d'ardoise et de grotte (cases bloquées par la carte), mare et
	# puits à plat, échelles (warps), fossiles posés sur la dalle.
	&"relief_paroi_ardoise_01", &"relief_paroi_ardoise_02", &"relief_paroi_ardoise_03",
	&"relief_paroi_ardoise_04", &"relief_paroi_grotte_01", &"relief_paroi_grotte_02",
	&"relief_paroi_grotte_03", &"relief_paroi_grotte_04", &"relief_paroi_grotte_05",
	&"relief_paroi_grotte_06", &"prop_mare_grotte_01", &"decal_puits_jour_01",
	&"prop_echelle_descend_01", &"prop_echelle_monte_01", &"prop_fossile_dome_01",
	&"prop_fossile_nautile_01",
	# Série 15 (J13) : îlot, quais, berges, tabliers de pont, rebord et versant d'ardoise (cases
	# d'eau ou bloquées par la carte).
	&"relief_grotte_azuree_01", &"relief_quai_01", &"relief_quai_02", &"relief_quai_03",
	&"relief_quai_04", &"relief_quai_05", &"relief_quai_06", &"relief_berge_01",
	&"relief_berge_02", &"relief_berge_03", &"relief_berge_04", &"relief_berge_05",
	&"prop_pont_ville_01", &"prop_pont_ville_03_01", &"prop_pont_ville_ew_01",
	&"prop_pont_pepite_tablier_01", &"prop_pont_pepite_tablier_02",
	&"prop_pont_pepite_tablier_03", &"relief_rebord_ardoise_01",
	&"relief_falaise_ardoise_01", &"relief_falaise_ardoise_02",
	# Série 16 (J14) : rivage rocheux (cases `R` bloquées par la carte).
	&"relief_rivage_01", &"relief_rivage_02", &"relief_rivage_03", &"relief_rivage_04",
	&"relief_rivage_05", &"relief_rivage_06",
	# Série 17 (J15) : bords de quai, passerelle, nénuphars, murs et escaliers du souterrain,
	# escalier d'intérieur (cases d'eau, de mur ou warps) ; navire (cases `N` de la grille),
	# vue du port, cordage, applique et tableau (posés sur des cases déjà bloquées).
	&"relief_quai_bois_01", &"relief_quai_bois_02", &"relief_quai_bois_03",
	&"relief_quai_bois_04", &"relief_quai_bois_05", &"prop_passerelle_01",
	&"prop_nenuphars_01", &"prop_nenuphars_02", &"prop_nenuphars_03",
	&"relief_mur_souterrain_01", &"relief_mur_souterrain_02", &"relief_mur_souterrain_03",
	&"relief_mur_souterrain_04", &"relief_mur_souterrain_05", &"relief_mur_souterrain_06",
	&"prop_escalier_souterrain_monte_01", &"prop_escalier_souterrain_descend_01",
	&"int_escalier_descendant_01", &"bldg_ss_anne_proue_01", &"bldg_ss_anne_milieu_01",
	&"bldg_ss_anne_poupe_01", &"prop_vue_port_01", &"prop_cordage_01", &"prop_applique_01",
	&"int_tableau_port_01",
	# Série 19 (J17) : bouches de la Cave et parois de grès (cases déjà solides ou warps de la
	# carte), bords de digue (eau), barrière ouverte (passage libre), carte murale du poste.
	&"relief_bouche_cave_sud_01", &"relief_bouche_cave_nord_01",
	&"relief_paroi_sable_01", &"relief_paroi_sable_02", &"relief_paroi_sable_03",
	&"relief_paroi_sable_04", &"relief_paroi_sable_05", &"relief_paroi_sable_06",
	&"relief_digue_bord_01", &"relief_digue_bord_02", &"prop_barriere_ouverte_01",
	&"int_carte_murale_01",
	# Série 18 (J16) : bastingages, superstructure du pont extérieur, barrière de l'Arène.
	&"relief_bastingage_01", &"relief_bastingage_02", &"relief_bastingage_sud_01",
	&"relief_bastingage_est_01", &"relief_bastingage_angle_ne_01",
	&"relief_bastingage_angle_se_01", &"bldg_ss_anne_superstructure_01",
	&"int_barriere_active_01", &"int_barriere_coupee_01",
	# Série 21 (J18) : lointains, flaque, parois de la Grotte Sombre, murs et escalier de la Tour.
	&"bldg_centrale_lointaine_01", &"prop_tour_lointaine_01", &"prop_flaque_grotte_01",
	&"relief_paroi_grotte_sombre_01", &"relief_paroi_grotte_sombre_02",
	&"relief_paroi_grotte_sombre_03", &"relief_paroi_grotte_sombre_04",
	&"relief_paroi_grotte_sombre_05", &"relief_paroi_grotte_sombre_06",
	&"relief_paroi_fendue_01", &"relief_mur_tour_01", &"relief_mur_tour_02",
	&"relief_mur_tour_03", &"relief_mur_tour_04", &"relief_mur_tour_05",
	&"relief_escalier_tour_01",
	# Série 22 bis : modules du repaire et du Casino (cases déjà solides ou warps de la carte).
	&"relief_mur_repaire_01", &"relief_mur_repaire_02", &"relief_mur_repaire_03",
	&"relief_mur_repaire_04", &"relief_mur_repaire_05", &"relief_mur_casino_01",
	&"relief_mur_casino_02", &"relief_mur_casino_03", &"relief_mur_casino_04",
	&"relief_mur_casino_05", &"int_escalier_repaire_monte_01", &"int_escalier_repaire_descend_01",
	&"decal_fleche_repaire_01", &"decal_fleche_repaire_01_haut", &"decal_fleche_repaire_01_bas",
	&"decal_fleche_repaire_01_gauche", &"decal_arret_repaire_01",
	&"int_porte_ascenseur_repaire_01", &"hideout_office_door", &"game_corner_wall",
	&"int_affiche_casino_01",
	# Lot DAF.3 / DAF.4 : modules de la Sylphe, des Arènes de Safrania et de Jadielle, du Dojo.
	&"relief_mur_sylphe_01", &"relief_mur_sylphe_02", &"relief_mur_sylphe_03",
	&"relief_mur_sylphe_04", &"relief_mur_sylphe_05", &"relief_mur_morgane_01",
	&"relief_mur_morgane_02", &"relief_mur_morgane_03", &"relief_mur_morgane_04",
	&"relief_mur_morgane_05", &"relief_mur_dojo_01", &"relief_mur_dojo_02", &"relief_mur_dojo_03",
	&"relief_mur_dojo_04", &"relief_mur_dojo_05", &"relief_mur_jadielle_01",
	&"relief_mur_jadielle_02", &"relief_mur_jadielle_03", &"relief_mur_jadielle_04",
	&"relief_mur_jadielle_05", &"int_escalier_sylphe_monte_01", &"int_escalier_sylphe_descend_01",
	&"int_porte_ascenseur_sylphe_01", &"decal_teleporteur_sylphe_01", &"decal_seuil_sylphe_01",
	&"int_paillasson_sylphe_01", &"int_porte_sylphe_h_01", &"int_porte_sylphe_v_01",
	# J29 (QA A17) : porte de la Ligue dans le mur du fond du hall du Plateau (déjà bloqué).
	&"int_porte_ligue_01",
	# Lot DAF.4 : rebords, escaliers, interrupteurs et barrière (Route Victoire, Grotte Azurée).
	&"relief_rebord_victoire_01", &"relief_rebord_victoire_cote_01", &"relief_escalier_victoire_01",
	&"decal_interrupteur_victoire_01", &"decal_interrupteur_victoire_enfonce_01",
	&"relief_rebord_azuree_01", &"relief_rebord_azuree_cote_01", &"relief_escalier_azuree_01",
	&"prop_barriere_victoire_01",
	&"decal_trou_victoire_01", &"decal_trou_victoire_bouche_01"]
const GROUND_LAYER: Array[StringName] = [
	# Lot DAF.4 : rebords, escaliers et interrupteurs (Route Victoire, Grotte Azurée).
	&"decal_trou_victoire_01", &"decal_trou_victoire_bouche_01",
	&"relief_rebord_victoire_01", &"relief_rebord_victoire_cote_01", &"relief_escalier_victoire_01",
	&"decal_interrupteur_victoire_01", &"decal_interrupteur_victoire_enfonce_01",
	&"relief_rebord_azuree_01", &"relief_rebord_azuree_cote_01", &"relief_escalier_azuree_01",
	# Lot DAF.3 / DAF.4 : modules de la Sylphe, des Arènes de Safrania et de Jadielle, du Dojo.
	&"relief_mur_sylphe_01", &"relief_mur_sylphe_02", &"relief_mur_sylphe_03",
	&"relief_mur_sylphe_04", &"relief_mur_sylphe_05", &"relief_mur_morgane_01",
	&"relief_mur_morgane_02", &"relief_mur_morgane_03", &"relief_mur_morgane_04",
	&"relief_mur_morgane_05", &"relief_mur_dojo_01", &"relief_mur_dojo_02", &"relief_mur_dojo_03",
	&"relief_mur_dojo_04", &"relief_mur_dojo_05", &"relief_mur_jadielle_01",
	&"relief_mur_jadielle_02", &"relief_mur_jadielle_03", &"relief_mur_jadielle_04",
	&"relief_mur_jadielle_05", &"int_escalier_sylphe_monte_01", &"int_escalier_sylphe_descend_01",
	&"int_porte_ascenseur_sylphe_01", &"decal_teleporteur_sylphe_01", &"decal_seuil_sylphe_01",
	&"int_paillasson_sylphe_01", &"int_porte_sylphe_h_01", &"int_porte_sylphe_v_01",
	# Série 22 bis : modules du repaire et du Casino (murs, escaliers, décalcomanies, portes).
	&"relief_mur_repaire_01", &"relief_mur_repaire_02", &"relief_mur_repaire_03",
	&"relief_mur_repaire_04", &"relief_mur_repaire_05", &"relief_mur_casino_01",
	&"relief_mur_casino_02", &"relief_mur_casino_03", &"relief_mur_casino_04",
	&"relief_mur_casino_05", &"int_escalier_repaire_monte_01", &"int_escalier_repaire_descend_01",
	&"decal_fleche_repaire_01", &"decal_fleche_repaire_01_haut", &"decal_fleche_repaire_01_bas",
	&"decal_fleche_repaire_01_gauche", &"decal_arret_repaire_01",
	&"int_porte_ascenseur_repaire_01", &"hideout_office_door", &"game_corner_wall",
	&"prop_flaque_grotte_01", &"relief_mur_tour_01", &"relief_mur_tour_02",
	&"relief_mur_tour_03", &"relief_mur_tour_04", &"relief_mur_tour_05",
	&"relief_escalier_tour_01",
	&"relief_falaise_01", &"relief_escalier_01", &"prop_massif_01", &"relief_muret_01",
	&"relief_escalier_ville_01",
	&"ground_champ_01", &"prop_ponton_01", &"relief_escalier_bois_01", &"relief_rebord_01",
	&"int_tapis_salon_01", &"int_tapis_plaid_01", &"int_tapis_pokeball_01",
	&"int_tapis_carreaux_01", &"int_tapis_rouge_01", &"int_tapis_labo_pokeball_01",
	# Série 12 (J10) : paroi ; poste vu du nord (le joueur passe toujours devant).
	&"relief_paroi_01", &"relief_paroi_02", &"relief_paroi_03", &"relief_paroi_04",
	&"bldg_poste_foret_nord_01",
	# Série 14 (J12) : paroi d'ardoise, mare, puits de jour, tranchée, échelles.
	&"relief_paroi_ardoise_01", &"relief_paroi_ardoise_02", &"relief_paroi_ardoise_03",
	&"relief_paroi_ardoise_04", &"prop_mare_grotte_01", &"decal_puits_jour_01",
	&"prop_tranchee_01", &"prop_echelle_descend_01", &"prop_echelle_monte_01",
	# Série 15 (J13) : tout le relief à plat (îlot, quais, berges, tabliers, ardoise).
	&"relief_grotte_azuree_01", &"relief_quai_01", &"relief_quai_02", &"relief_quai_03",
	&"relief_quai_04", &"relief_quai_05", &"relief_quai_06", &"relief_berge_01",
	&"relief_berge_02", &"relief_berge_03", &"relief_berge_04", &"relief_berge_05",
	&"prop_pont_ville_01", &"prop_pont_ville_03_01", &"prop_pont_ville_ew_01",
	&"prop_pont_pepite_tablier_01", &"prop_pont_pepite_tablier_02",
	&"prop_pont_pepite_tablier_03", &"relief_rebord_ardoise_01",
	&"relief_falaise_ardoise_01", &"relief_falaise_ardoise_02",
	# Série 16 (J14) : rivage rocheux à plat.
	&"relief_rivage_01", &"relief_rivage_02", &"relief_rivage_03", &"relief_rivage_04",
	&"relief_rivage_05", &"relief_rivage_06",
	# Série 17 (J15) : relief à plat (quai, nénuphars, murs, escaliers, passerelle).
	&"relief_quai_bois_01", &"relief_quai_bois_02", &"relief_quai_bois_03",
	&"relief_quai_bois_04", &"relief_quai_bois_05", &"prop_passerelle_01",
	&"prop_nenuphars_01", &"prop_nenuphars_02", &"prop_nenuphars_03",
	&"relief_mur_souterrain_01", &"relief_mur_souterrain_02", &"relief_mur_souterrain_03",
	&"relief_mur_souterrain_04", &"relief_mur_souterrain_05", &"relief_mur_souterrain_06",
	&"prop_escalier_souterrain_monte_01", &"prop_escalier_souterrain_descend_01",
	&"int_escalier_descendant_01",
	# Série 19 (J17) : bords de la digue à plat.
	&"relief_digue_bord_01", &"relief_digue_bord_02",
	# Série 18 (J16) : bastingages du pont extérieur.
	&"relief_bastingage_01", &"relief_bastingage_02", &"relief_bastingage_sud_01",
	&"relief_bastingage_est_01", &"relief_bastingage_angle_ne_01",
	&"relief_bastingage_angle_se_01",
]
## Bâtiments sans ombre : le poste de la forêt vu du nord (série 12) continue sous le bord sud
## de la Route 2 nord, couché dans la couche du sol (fiche `serie-12-argenta.md`) ; les trois
## tranches du S.S. Anne (série 17) : le jeu pose lui-même le reflet et la ligne d'eau.
const SHADOWLESS_BUILDINGS: Array[String] = ["bldg_poste_foret_nord_01",
	"bldg_ss_anne_proue_01", "bldg_ss_anne_milieu_01", "bldg_ss_anne_poupe_01",
	# Série 18 : la superstructure du pont extérieur (sur le pont, sans soleil rasant).
	"bldg_ss_anne_superstructure_01",
	# Série 21 (J18) : la centrale lointaine de la Route 10.
	"bldg_centrale_lointaine_01"]
## Objets de Bourg Palette, de ses intérieurs et de la Route 1 (DA.0) : tous au catalogue,
## chacun avec sa règle et sa scène (assets des scènes du prototype validé).
const DA0_OBJECTS: Array[StringName] = [
	&"bldg_maison_joueur_01", &"bldg_maison_rival_01", &"bldg_labo_01", &"bldg_serre_01",
	&"tree_ancien_01", &"prop_cloture_piquets_01", &"prop_velo_01", &"prop_camionnette_01",
	&"ground_champ_01", &"prop_ponton_01", &"prop_ronces_01", &"prop_tronc_couche_01",
	&"prop_rocher_mer_01", &"relief_escalier_bois_01", &"prop_buisson_a_01_bourg",
	&"prop_buisson_b_01_bourg", &"prop_buisson_c_01_bourg", &"prop_pots_fleurs_01_bourg",
	&"prop_linge_01_bourg", &"tree_fruitier_01_bourg", &"prop_haie_v_01_bourg",
	&"prop_cloture_piquets_v_01", &"tree_c_01", &"tree_d_01", &"tree_e_01",
	&"prop_hortensias_01", &"prop_mangeoire_01", &"prop_epouvantail_01", &"prop_barque_01",
	&"prop_casiers_peche_01", &"prop_herbes_dune_01", &"prop_materiel_labo_01",
	&"prop_ratelier_velos_01", &"prop_brouette_01", &"prop_tas_bois_01",
	&"prop_arrosoir_seau_01", &"prop_pierres_01", &"prop_cloture_courte_01",
	&"tree_automne_01", &"prop_souche_01", &"relief_rebord_01",
	&"ground_hautes_herbes_jaune_01", &"int_lit_01", &"int_bureau_pc_01", &"int_tele_01",
	&"int_escalier_montant_01", &"int_canape_01", &"int_cuisine_01", &"int_bureau_chen_01",
	&"int_table_starters_01", &"int_lit_pokeball_01", &"int_cloison_v_01",
	&"int_tapis_pokeball_01",
]
## Images seules (sans scène) de DA.0 : sols de la côte, enveloppes des pièces, fleurs.
const DA0_IMAGES: Dictionary = {
	"ground_sable_01": Vector2i(384, 384), "ground_eau_01": Vector2i(384, 384),
	"int_chambre_joueur_coque": Vector2i(14 * 96, 10 * 96),
	"int_maison_joueur_rdc_coque": Vector2i(14 * 96, 10 * 96),
	"int_maison_rival_coque": Vector2i(18 * 96, 11 * 96),
	"int_labo_coque": Vector2i(16 * 96, 11 * 96),
}

var _objects: Dictionary = {}
var _images: Dictionary = {}


func before_all() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	_objects = catalogue["objets"]
	_images = catalogue["images"]


func _scene(id: String) -> WorldProp:
	var packed := load(SCENES + id + ".tscn") as PackedScene
	if packed == null:
		return null
	var prop := packed.instantiate() as WorldProp
	autofree(prop)
	return prop


func test_every_catalogue_object_has_a_rule_and_a_scene() -> void:
	assert_gt(_objects.size(), 20)
	for id: String in _objects:
		assert_true(PaintedPropRules.has_rule(StringName(id)), "règle pour %s" % id)
		assert_true(ResourceLoader.exists(SCENES + id + ".tscn"), "scène pour %s" % id)
	for id: StringName in PaintedPropRules.get_ids():
		assert_true(_objects.has(String(id)), "%s est au catalogue" % id)


func test_every_prop_has_a_footprint_except_the_traversable_ones() -> void:
	for id: String in _objects:
		var prop := _scene(id)
		assert_not_null(prop, id)
		if prop == null:
			continue
		var expected := PaintedPropRules.footprint(StringName(id))
		assert_eq(prop.get_footprint(), expected, "%s : emprise de la règle" % id)
		if TRAVERSABLE.has(StringName(id)):
			assert_true(prop.get_footprint().is_empty(), "%s se traverse" % id)
		else:
			assert_false(prop.get_footprint().is_empty(), "%s a une emprise" % id)
	for id: StringName in TRAVERSABLE:
		assert_true(PaintedPropRules.is_traversable(id), String(id))


func test_sprite_foot_is_the_origin() -> void:
	for id: String in _objects:
		var prop := _scene(id)
		if prop == null:
			continue
		var sprite := prop.get_node(^"%Sprite") as Sprite2D
		var size := Vector2(_objects[id]["taille"][0], _objects[id]["taille"][1])
		assert_eq(sprite.texture.get_size(), size, "%s : image à 1:1" % id)
		assert_false(sprite.centered)
		assert_eq(sprite.offset, -PaintedPropRules.origin(StringName(id), size), id)
		assert_eq(prop.position, Vector2.ZERO)
	# Le massif est posé par le trou où sort le tronc de l'arbre central.
	assert_eq(PaintedPropRules.origin(&"prop_massif_01", Vector2(384, 232)), Vector2(182, 109))
	assert_eq(PaintedPropRules.origin(&"tree_a_01", Vector2(267, 384)), Vector2(133.5, 384))


func test_shadow_textures_exist_and_are_drawn_under_everything() -> void:
	for id: String in _objects:
		var prop := _scene(id)
		if prop == null:
			continue
		var entry: Dictionary = _objects[id]
		for pair: Array in [["ombre", "CastShadow", WorldLighting.GROUP_CAST_SHADOWS],
				["contact", "ContactShadow", WorldLighting.GROUP_CONTACT_SHADOWS]]:
			var node := prop.get_node_or_null(NodePath(pair[1])) as Sprite2D
			if not entry.has(pair[0]) or not PaintedPropRules.casts_shadows(StringName(id)):
				assert_null(node, "%s : pas de %s" % [id, pair[1]])
				continue
			var shadow: Dictionary = entry[pair[0]]
			assert_true(ResourceLoader.exists(shadow["fichier"]), shadow["fichier"])
			assert_not_null(node, "%s : %s" % [id, pair[1]])
			if node == null:
				continue
			assert_eq(node.texture.resource_path, shadow["fichier"])
			assert_true(node.is_in_group(pair[2]), "%s : groupe %s" % [id, pair[2]])
			assert_false(node.z_as_relative, "%s : z absolu" % id)
			assert_eq(node.z_index, WorldLighting.Z_SHADOWS)
			assert_eq(node.scale, Vector2(2, 2), "demi-résolution affichée à l'échelle 2")
			# Coin haut gauche à « decalage » (pixels de jeu) du milieu du bas de l'image.
			var size := Vector2(entry["taille"][0], entry["taille"][1])
			var image_foot := Vector2(size.x / 2.0, size.y) \
				- PaintedPropRules.origin(StringName(id), size)
			assert_eq(node.offset * 2.0,
				Vector2(shadow["decalage"][0], shadow["decalage"][1]) + image_foot, id)
	# Les bâtiments ont les deux ombres.
	for id: String in ["bldg_centre_01", "bldg_maison_a_01", "bldg_arene_01"]:
		assert_true(_objects[id].has("ombre") and _objects[id].has("contact"), id)
		assert_not_null(_scene(id).get_node_or_null(^"CastShadow"), id)
		assert_not_null(_scene(id).get_node_or_null(^"ContactShadow"), id)


## Retours de Kevin (2026-10-05) : **aucun petit objet n'a d'ombre** (ni portée, ni de contact),
## seuls les bâtiments (`bldg_*`, règle « shadow ») gardent les leurs ; scènes peintes, puis
## ombres peintes dans les images provisoires (Bourg Palette, Route 1, intérieurs).
func test_only_buildings_have_shadow_nodes() -> void:
	for id: String in _objects:
		var building := id.begins_with("bldg_") and not SHADOWLESS_BUILDINGS.has(id)
		assert_eq(PaintedPropRules.casts_shadows(StringName(id)), building,
			"%s : règle « shadow »" % id)
		var prop := _scene(id)
		if prop == null:
			continue
		var has_shadow := false
		for child: Node in prop.get_children():
			if child.is_in_group(WorldLighting.GROUP_CAST_SHADOWS) \
					or child.is_in_group(WorldLighting.GROUP_CONTACT_SHADOWS) \
					or String(child.name).contains("Shadow"):
				has_shadow = true
		assert_eq(has_shadow, building, "%s : nœud d'ombre seulement pour un bâtiment" % id)
	for id: String in ["tree_a_01", "prop_buisson_a_01", "prop_banc_01", "prop_tonneau_01",
			"prop_cloture_01", "prop_rocher_01", "prop_lampadaire_01", "prop_boite_lettres_01",
			"prop_linge_01", "prop_portail_01", "prop_balustrade_01", "prop_potager_01",
			"int_centre_comptoir", "int_plante"]:
		assert_false(PaintedPropRules.casts_shadows(StringName(id)), "%s : sans ombre" % id)
	# Images provisoires : plus d'ellipse d'ombre (couleur de tools/gen_placeholder_props.gd,
	# alpha 0,28) sous tous les petits objets.
	for path: String in ["tree_oak_a", "tree_oak_b", "tree_pine", "tree_birch", "tree_maple",
			"plaza_tree", "bush_a", "bush_b", "interior/plant", "lamp_post", "bench",
			"sign_pallet", "mailbox", "bicycle", "van", "rock_small", "rock_large",
			"interior/desk_chair", "interior/travel_bag", "interior/coat_rack"]:
		var image := (load("res://assets/tiles/placeholder/props/%s.png" % path)
			as Texture2D).get_image()
		var shadow_pixels := 0
		for x: int in range(0, image.get_width(), 2):
			var c := image.get_pixel(x, image.get_height() - 10)
			if absf(c.a - 0.28) < 0.02 and c.r < 0.2 and c.g < 0.2:
				shadow_pixels += 1
		assert_eq(shadow_pixels, 0, "%s : pas d'ombre peinte" % path)


func test_materials_shared_by_family() -> void:
	var still := load("res://game/world/lighting/materials/world_object.tres")
	var wind := load("res://game/world/lighting/materials/world_object_wind.tres")
	for id: String in _objects:
		var prop := _scene(id)
		if prop == null:
			continue
		var sprite := prop.get_node(^"%Sprite") as Sprite2D
		if not PaintedPropRules.uses_material(StringName(id)):
			assert_null(sprite.material, id)
		elif PaintedPropRules.has_wind(StringName(id)):
			assert_eq(sprite.material, wind, "%s : feuillage au vent" % id)
		else:
			assert_eq(sprite.material, still, id)
	for id: StringName in [&"tree_a_01", &"tree_b_01", &"tree_central_01"]:
		assert_true(PaintedPropRules.has_wind(id), String(id))
		assert_true(PaintedPropRules.fades(id), "%s : la cime devient transparente" % id)
	for id: StringName in [&"bldg_centre_01", &"bldg_arene_01", &"bldg_maison_a_01"]:
		assert_true(_scene(String(id)).fade_when_covering, "%s : le toit" % id)


func test_footprints_of_the_prototype() -> void:
	# Centre 8 × 4, porte (2 cases du bas) libre pour le passage de la carte.
	var centre := PaintedPropRules.footprint(&"bldg_centre_01")
	assert_eq(centre.size(), 8 * 4 - 2)
	for cell: Vector2i in [Vector2i(-4, -3), Vector2i(3, -3), Vector2i(-4, 0), Vector2i(3, 0)]:
		assert_true(centre.has(cell), "coin %s" % cell)
	for door: Vector2i in PaintedPropRules.open_cells(&"bldg_centre_01"):
		assert_false(centre.has(door), "porte %s libre" % door)
	assert_eq(PaintedPropRules.open_cells(&"bldg_centre_01"), [Vector2i(-1, 0), Vector2i(0, 0)])
	# Arène 10 × 4 fermée (« La porte est verrouillée. ») : rien de libre.
	assert_eq(PaintedPropRules.footprint(&"bldg_arene_01").size(), 40)
	# Maisons, largeur impaire centrée.
	var house_b := PaintedPropRules.footprint(&"bldg_maison_b_01")
	assert_eq(house_b.size(), 15)
	assert_true(house_b.has(Vector2i(-2, -2)) and house_b.has(Vector2i(2, 0)))
	# Arche nord : seulement les deux piliers.
	assert_eq(PaintedPropRules.footprint(&"prop_porte_nord_01"),
		[Vector2i(-2, 0), Vector2i(2, 0)])
	# Banc 2 × 1 posé sur un bord de case.
	assert_eq(PaintedPropRules.footprint(&"prop_banc_01"), [Vector2i(-1, 0), Vector2i(0, 0)])
	assert_eq(PaintedPropRules.footprint(&"tree_a_01"), [Vector2i.ZERO])
	assert_eq(PaintedPropRules.footprint(&"relief_falaise_01").size(), 4)
	assert_eq(PaintedPropRules.footprint(&"prop_massif_01").size(), 12)


func test_relief_lies_in_the_ground_layer() -> void:
	for id: StringName in PaintedPropRules.get_ids():
		var expected := PaintedPropRules.LAYER_GROUND if GROUND_LAYER.has(id) \
			else PaintedPropRules.LAYER_ENTITIES
		assert_eq(PaintedPropRules.layer(id), expected, String(id))


func test_foot_position_gives_back_the_anchor_cell() -> void:
	var anchor := Vector2i(13, 9)
	for id: StringName in PaintedPropRules.get_ids():
		var foot := PaintedPropRules.foot_position(id, anchor)
		var prop := WorldProp.new()
		autofree(prop)
		prop.position = foot
		assert_eq(prop.get_anchor_cell(), anchor, String(id))
	# Largeur paire : pied sur le bord gauche de la case ; impaire : au milieu.
	assert_eq(PaintedPropRules.foot_position(&"bldg_centre_01", anchor), Vector2(1248, 960))
	assert_eq(PaintedPropRules.foot_position(&"bldg_maison_b_01", anchor), Vector2(1296, 960))
	assert_eq(PaintedPropRules.foot_position(&"tree_central_01", anchor), Vector2(1248, 960))


func test_game_map_marks_props_of_both_layers_solid() -> void:
	var map := GameMap.new()
	map.size = Vector2i(30, 20)
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	map.add_child(entities)
	var decals := Node2D.new()
	decals.name = "GroundDecals"
	decals.z_index = WorldLighting.Z_GROUND_DECALS
	map.add_child(decals)
	entities.add_child(_placed(&"bldg_centre_01", Vector2i(10, 8)))
	decals.add_child(_placed(&"relief_falaise_01", Vector2i(20, 4)))
	decals.add_child(_placed(&"relief_escalier_01", Vector2i(23, 4)))
	add_child_autofree(map)
	var grid := map.get_grid()
	assert_true(grid.is_solid(Vector2i(6, 5)), "coin du Centre")
	assert_true(grid.is_solid(Vector2i(13, 8)))
	assert_false(grid.is_solid(Vector2i(9, 8)), "porte du Centre")
	assert_false(grid.is_solid(Vector2i(10, 8)), "porte du Centre")
	assert_false(grid.is_solid(Vector2i(10, 9)), "devant le Centre")
	for x in range(18, 22):
		assert_true(grid.is_solid(Vector2i(x, 4)), "face de la falaise %d" % x)
	assert_false(grid.is_solid(Vector2i(23, 4)), "l'escalier se monte")


## Instance libérée avec la carte (pas d'autofree).
func _placed(id: StringName, anchor: Vector2i) -> WorldProp:
	var prop := (load(SCENES + String(id) + ".tscn") as PackedScene).instantiate() as WorldProp
	prop.position = PaintedPropRules.foot_position(id, anchor)
	return prop


func test_baked_shadow_matches_the_art_manifest() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var cast: Dictionary = manifest["ombre_portee"]
	assert_almost_eq(float(cast["ecrasement"]), WorldLighting.BAKED_SHADOW_LENGTH, 0.0001)
	assert_almost_eq(float(cast["inclinaison_deg"]), WorldLighting.BAKED_SHADOW_ANGLE_DEG,
		0.0001)
	assert_eq(float(cast["reduction"]), WorldLighting.SHADOW_TEXTURE_SCALE)
	assert_eq(float(manifest["ombre_contact"]["reduction"]), WorldLighting.SHADOW_TEXTURE_SCALE)


func test_bourg_palette_and_route_1_objects_are_in_the_catalogue() -> void:
	for id: StringName in DA0_OBJECTS:
		assert_true(_objects.has(String(id)), "%s au catalogue" % id)
		assert_true(PaintedPropRules.has_rule(id), "%s a sa règle" % id)
		assert_true(ResourceLoader.exists(SCENES + String(id) + ".tscn"), "%s a sa scène" % id)
	# La forêt serrée n'utilise que des objets du catalogue.
	for id: StringName in DenseForest.TREE_IDS + DenseForest.BUSH_IDS:
		assert_true(_objects.has(String(id)) and PaintedPropRules.has_rule(id), String(id))
		assert_false(PaintedPropRules.fades(id), "%s : pas de fondu (aucun _process)" % id)
	for id: StringName in DenseForest.TREE_IDS:
		assert_true(PaintedPropRules.has_wind(id), "%s au vent" % id)
		assert_true(PaintedPropRules.is_traversable(id), "%s : la case de forêt bloque" % id)
		# Arbres de forêt ≈ 3 cases (échelle du prototype validée par Kevin).
		var height: int = _objects[String(id)]["taille"][1]
		assert_between(height, 260, 320, "%s : environ 3 cases" % id)


func test_bourg_palette_images_and_decals() -> void:
	for id: String in DA0_IMAGES:
		assert_true(_images.has(id), "%s au catalogue" % id)
		if not _images.has(id):
			continue
		assert_eq(Vector2i(_images[id]["taille"][0], _images[id]["taille"][1]), DA0_IMAGES[id],
			"%s à sa taille" % id)
		assert_true(ResourceLoader.exists(_images[id]["fichier"]), id)
	for family: String in ["fleur", "cote"]:
		for i in range(1, 9):
			var id := "decal_%s_%d" % [family, i]
			assert_true(_images.has(id) and ResourceLoader.exists(_images[id]["fichier"]), id)
	# Herbes jaune-vert de la Route 1 : une image recolorée (et son cache-jambes), même taille
	# que les herbes vertes ; aucune teinte au lancement.
	var green: Dictionary = _objects["ground_hautes_herbes_01"]
	var yellow: Dictionary = _objects["ground_hautes_herbes_jaune_01"]
	assert_eq(yellow["taille"], green["taille"])
	assert_true(ResourceLoader.exists(yellow["bas"]["fichier"]), "cache-jambes jaune-vert")
	var tuft := _scene("ground_hautes_herbes_jaune_01")
	assert_eq(tuft.modulate, Color.WHITE)
	assert_eq((tuft.get_node(^"%Sprite") as Sprite2D).self_modulate, Color.WHITE)


func test_cast_shadows_are_prepared_for_buildings_only() -> void:
	# Manifeste (DA.0) : ombre portée pré-floutée pour les bâtiments seulement ; la végétation
	# et les petits objets n'ont au plus qu'une ombre de contact (non posée dans les scènes).
	for id: StringName in DA0_OBJECTS + DenseForest.TREE_IDS:
		var entry: Dictionary = _objects.get(String(id), {})
		assert_eq(entry.has("ombre"), String(id).begins_with("bldg_"),
			"%s : ombre portée seulement pour un bâtiment" % id)


func test_footprints_of_bourg_palette() -> void:
	# Maisons 6 × 3, porte libre sous la porte peinte (le joueur à gauche, le rival à droite).
	var player := PaintedPropRules.footprint(&"bldg_maison_joueur_01")
	assert_eq(player.size(), 6 * 3 - 1)
	assert_false(player.has(Vector2i(-1, 0)), "porte de la maison du joueur")
	assert_true(player.has(Vector2i(-3, -2)) and player.has(Vector2i(2, 0)))
	assert_false(PaintedPropRules.footprint(&"bldg_maison_rival_01").has(Vector2i(0, 0)))
	# Labo 10 × 4, double porte au milieu du bas.
	var lab := PaintedPropRules.footprint(&"bldg_labo_01")
	assert_eq(lab.size(), 10 * 4 - 2)
	assert_eq(PaintedPropRules.open_cells(&"bldg_labo_01"), [Vector2i(-1, 0), Vector2i(0, 0)])
	assert_eq(PaintedPropRules.footprint(&"tree_ancien_01").size(), 12)
	assert_eq(PaintedPropRules.footprint(&"prop_haie_v_01_bourg"),
		[Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0)])
	# Escalier montant : la rangée du bas porte les passages vers l'étage.
	assert_eq(PaintedPropRules.footprint(&"int_escalier_montant_01"),
		[Vector2i(-1, -1), Vector2i(0, -1)])
	assert_eq(PaintedPropRules.footprint(&"int_lit_01").size(), 6)


## Jalon 10 T10 (série 12, fiche `serie-12-argenta.md`) : emprises = cases de la grille
## d'Argenta et de la Route 2 nord, portes libres là où la carte pose ses passages.
func test_footprints_of_pewter_city() -> void:
	# Musée 12 × 9 (3..14, 31..39), porte (8..9, 39) : ancre (9, 39), pied sur un bord.
	var museum := PaintedPropRules.footprint(&"bldg_musee_argenta_01")
	assert_eq(museum.size(), 12 * 9 - 2)
	assert_eq(PaintedPropRules.open_cells(&"bldg_musee_argenta_01"),
		[Vector2i(-1, 0), Vector2i(0, 0)])
	assert_true(museum.has(Vector2i(-6, -8)) and museum.has(Vector2i(5, 0)), "coins du Musée")
	# Arène 12 × 7 (30..41, 5..11), porte (35..36, 11) : ancre (36, 11).
	var gym := PaintedPropRules.footprint(&"bldg_arene_argenta_01")
	assert_eq(gym.size(), 12 * 7 - 2)
	assert_true(gym.has(Vector2i(-6, -6)) and gym.has(Vector2i(5, 0)), "coins de l'Arène")
	# Maison 7 × 6, porte au milieu du bas (largeur impaire, pied au milieu de la case).
	var house := PaintedPropRules.footprint(&"bldg_maison_argenta_01")
	assert_eq(house.size(), 7 * 6 - 1)
	assert_false(house.has(Vector2i.ZERO), "porte de la maison")
	assert_true(house.has(Vector2i(-3, -5)) and house.has(Vector2i(3, 0)))
	assert_eq(PaintedPropRules.align(&"bldg_maison_argenta_01"), PaintedPropRules.ALIGN_CENTRE)
	# Poste vu du nord 7 × 3 (12..18, 21..23), ancre (15, 23), porte au bord haut (15, 21).
	var gate := PaintedPropRules.footprint(&"bldg_poste_foret_nord_01")
	assert_eq(gate.size(), 7 * 3 - 1)
	assert_false(gate.has(Vector2i(0, -2)), "porte du poste au bord haut")
	assert_true(gate.has(Vector2i(0, 0)) and gate.has(Vector2i(-3, -2)))
	assert_eq(PaintedPropRules.layer(&"bldg_poste_foret_nord_01"),
		PaintedPropRules.LAYER_GROUND)
	# Rocher de la place 3 × 3, blocs du tailleur 3 × 2.
	assert_eq(PaintedPropRules.footprint(&"prop_rocher_place_01").size(), 9)
	assert_eq(PaintedPropRules.footprint(&"prop_blocs_tailles_01").size(), 6)
	# Intérieurs : vitrines, panneau et pilier 2 × 1, Pierre Lune 1 × 1, rochers de l'Arène.
	for id: StringName in [&"int_vitrine_dome_01", &"int_vitrine_nautile_01",
			&"int_vitrine_journal_01", &"int_panneau_expo_01", &"int_pilier_roche_01"]:
		assert_eq(PaintedPropRules.footprint(id), [Vector2i(-1, 0), Vector2i(0, 0)], String(id))
	assert_eq(PaintedPropRules.footprint(&"int_vitrine_pierre_lune_01"), [Vector2i.ZERO])
	assert_eq(PaintedPropRules.footprint(&"int_rochers_bas_01").size(), 4)
	assert_eq(PaintedPropRules.footprint(&"int_rochers_bas_02"), [Vector2i.ZERO])


## Le seuil peint du poste vu du nord tombe au bas de la case de la porte (règle « origin »).
func test_north_gate_threshold_lands_on_the_door_cell() -> void:
	const THRESHOLD_Y := 249.0  # bas du seuil de pierre sous le paillasson, dans l'image
	var entry: Dictionary = _objects["bldg_poste_foret_nord_01"]
	var size := Vector2(entry["taille"][0], entry["taille"][1])
	assert_eq(size, Vector2(672, 579))
	var foot := PaintedPropRules.foot_position(&"bldg_poste_foret_nord_01", Vector2i(15, 23))
	var origin := PaintedPropRules.origin(&"bldg_poste_foret_nord_01", size)
	assert_eq(foot.y - origin.y + THRESHOLD_Y, float(22 * Grid.TILE_SIZE),
		"seuil au bas de la case (15, 21)")
	assert_eq(origin.x, size.x / 2.0, "pied centré")


## Série 12 : images préparées à la largeur de leur emprise (1 case = 96 px), paroi de
## 3 cases de haut, enveloppes des pièces aux tailles des grilles.
func test_pewter_assets_are_prepared_at_scale() -> void:
	var widths := {"bldg_musee_argenta_01": 12, "bldg_arene_argenta_01": 12,
		"bldg_maison_argenta_01": 7, "bldg_poste_foret_nord_01": 7, "prop_rocher_place_01": 3,
		"prop_blocs_tailles_01": 3, "int_vitrine_dome_01": 2, "int_vitrine_nautile_01": 2,
		"int_vitrine_pierre_lune_01": 1, "int_vitrine_journal_01": 2, "int_porte_labo_01": 3,
		"int_panneau_expo_01": 2, "int_pilier_roche_01": 2, "int_rochers_bas_01": 2,
		"int_rochers_bas_02": 1}
	for id: String in widths:
		assert_true(_objects.has(id), id)
		assert_eq(int(_objects[id]["taille"][0]), int(widths[id]) * Grid.TILE_SIZE, id)
		var cast := id.begins_with("bldg_") and id != "bldg_poste_foret_nord_01"
		assert_eq(_objects[id].has("ombre"), cast, id + " : ombre portée des bâtiments posés")
		assert_eq(PaintedPropRules.casts_shadows(StringName(id)), cast, id)
	for i in range(1, 5):
		assert_eq(int(_objects["relief_paroi_0%d" % i]["taille"][1]), 288, "paroi de 3 cases")
	for id: String in ["int_musee_coque", "int_maison_argenta_coque"]:
		assert_eq(Vector2i(_images[id]["taille"][0], _images[id]["taille"][1]),
			Vector2i(15 * 96, 10 * 96), id)
	assert_eq(Vector2i(_images["int_arene_coque"]["taille"][0],
		_images["int_arene_coque"]["taille"][1]), Vector2i(15 * 96, 11 * 96))
