extends RefCounted
## Lettres des grilles du jalon 18 → **noms d'assets** (T11, docs/tech/jalon-18.md §5.2 ; fiche
## `docs/design/fiches-assets/serie-21-j18.md`). Utilisé par les constructeurs de cartes du J18
## (`build_route_9.gd`, `build_route_10.gd`, `build_dark_cave.gd`, `build_lavender_town.gd`,
## tour du rez-de-chaussée) à travers les boîtes à outils (`cave_map_kit.gd`,
## `pewter_map_kit.gd` / `cerulean_map_kit.gd`) :
##
## - une entrée **référence les assets par nom**, sans exiger le fichier : les assets de la
##   série 21 (« new ») ne sont générés qu'après les kits ; aucune carte J18 n'est construite
##   tant que [method status] n'a pas tranché ;
## - [method pick] renvoie les assets neufs s'ils existent **tous**, sinon le **repli** explicite
##   (asset déjà dans le dépôt, noté dans la table et dans le compte rendu du T11) ; sans repli et
##   non facultatif, la liste est vide et [method status] dit `missing` (le constructeur échoue,
##   il ne pose rien en silence) ; `optional` : élément de pur décor, omis sans erreur.
## - les assets **réutilisés** (« reused », déjà présents) n'ont pas de repli.
##
## Les entrées n'ont aucun effet sur les cartes existantes : aucune boîte ne les lit d'office.
## Les tests (`tests/unit/test_j18_asset_refs.gd`) vérifient que chaque repli et chaque asset
## réutilisé existe.

const PROPS: String = "res://game/world/props/painted/"
const GROUND: String = "res://assets/world/ground/"
## Natures d'asset : objet peint (`PROPS<id>.tscn`) ou texture de sol (`GROUND<id>.png`).
const KIND_PROP: StringName = &"prop"
const KIND_GROUND: StringName = &"ground"

## Grotte Sombre (1F et B1F). Lettres : `.` sol calme, `#` masse, `g` gravats, `j` sol éclairé,
## `o` rocher, `K` colonne, `w` flaque, `f` paroi fendue, `r` racines, `V` `U` échelles.
const DARK_CAVE: Dictionary[StringName, Dictionary] = {
	&"floor": {"letter": ".", "kind": &"ground", "new": ["ground_grotte_sombre_01"],
		"fallback": ["ground_grotte_01"], "note": "sol clair de la série 21 ; repli : sol du Mont Sélénite"},
	&"mass": {"letter": "#", "kind": &"ground", "new": ["ground_masse_grotte_sombre_01"],
		"fallback": ["ground_masse_roche_01"], "note": "dessus des masses"},
	&"rubble": {"letter": "g", "kind": &"ground", "reused": ["ground_gravats_01"]},
	&"wall_faces": {"letter": "#", "kind": &"prop",
		"new": ["relief_paroi_grotte_sombre_01", "relief_paroi_grotte_sombre_02"],
		"fallback": ["relief_paroi_grotte_01", "relief_paroi_grotte_02"], "note": "faces A / B"},
	&"wall_side": {"letter": "#", "kind": &"prop", "new": ["relief_paroi_grotte_sombre_05"],
		"fallback": ["relief_paroi_grotte_05"], "note": "bord latéral"},
	&"wall_lip": {"letter": "#", "kind": &"prop", "new": ["relief_paroi_grotte_sombre_06"],
		"fallback": ["relief_paroi_grotte_06"], "note": "lèvre nord"},
	&"rock": {"letter": "o", "kind": &"prop",
		"new": ["prop_rocher_grotte_sombre_01", "prop_rocher_grotte_sombre_02"],
		"fallback": ["prop_rocher_grotte_01", "prop_rocher_grotte_02"],
		"note": "fiche B9 : rochers du Mont Sélénite teintés brun"},
	&"column": {"letter": "K", "kind": &"prop", "new": ["prop_grande_colonne_01"],
		"fallback": ["prop_colonne_grotte_01"],
		"note": "repli : colonne 2 × 3 du Mont Sélénite, emprise plus petite que les 5 × 6 de la grille"},
	&"pool": {"letter": "w", "kind": &"prop", "new": ["prop_flaque_grotte_01"],
		"fallback": ["prop_mare_grotte_01"], "note": "flaque à plat 8 × 4 ; repli : mare 4 × 3 (étirée)"},
	&"split_wall": {"letter": "f", "kind": &"prop", "new": ["relief_paroi_fendue_01"],
		"fallback": ["relief_paroi_grotte_01"], "note": "repli : face A sans fente (le halo shaft reste)"},
	&"roots": {"letter": "r", "kind": &"prop",
		"new": ["prop_racines_plafond_01", "prop_racines_plafond_02"],
		"fallback": ["prop_racines_01"]},
	&"day_shaft": {"letter": "j", "kind": &"prop", "reused": ["decal_puits_jour_01"]},
	&"ladder_down": {"letter": "V", "kind": &"prop", "reused": ["prop_echelle_descend_01"]},
	&"ladder_up": {"letter": "U", "kind": &"prop", "reused": ["prop_echelle_monte_01"]},
	&"lamp": {"letter": "", "kind": &"prop", "reused": ["prop_lampe_chantier_01"]},
	&"clue": {"letter": "", "kind": &"prop", "reused": ["prop_indice_caillou_01"]},
	&"sign": {"letter": "", "kind": &"prop", "reused": ["prop_panneau_01"]},
}

## Routes 9 et 10. Les lettres communes avec la Route 3 (`T K R o v h = .`) ne changent pas.
## Route 10 : `w` eau (jamais praticable, boîte d'eau), `E` centrale lointaine, `C` `D` Centre,
## `Q` bouche de la grotte.
const ROUTES: Dictionary[StringName, Dictionary] = {
	&"water": {"letter": "w", "kind": &"ground", "reused": ["ground_eau_canal_01"]},
	&"rock_floor": {"letter": "o", "kind": &"ground", "reused": ["ground_roche_01"]},
	&"central": {"letter": "E", "kind": &"prop", "new": ["bldg_centrale_lointaine_01"],
		"fallback": [], "optional": true,
		"note": "lointain sans porte : sans l'image, les cases restent bloquées sous la forêt"},
	&"far_tower": {"letter": "", "kind": &"prop", "new": ["prop_tour_lointaine_01"],
		"fallback": [], "optional": true, "note": "repère `tour_lointaine` (8..12, 74..75)"},
	&"cave_mouth": {"letter": "Q", "kind": &"prop", "new": ["relief_bouche_paroi_01"],
		"fallback": ["bldg_entree_souterrain_01"],
		"note": "série 19 (J17) ; repli provisoire : entrée du souterrain"},
	&"center": {"letter": "C", "kind": &"prop", "reused": ["bldg_centre_01"]},
}

## Lavanville (44 × 36). `p` pavés, `x` haie, `y` fleurs, `n` banc, `G` arbre repère, `m` `N`
## maisons, `F` Maison des Pokémon, `U` Tour, `O` Boutique, `C` Centre.
const LAVENDER: Dictionary[StringName, Dictionary] = {
	&"paving": {"letter": "p", "kind": &"ground", "new": ["ground_paves_lavanville_01"],
		"fallback": ["ground_paves_01"]},
	&"hedge": {"letter": "x", "kind": &"prop",
		"new": ["prop_buis_taille_01", "prop_buis_taille_02", "prop_haie_taillee_01"],
		"fallback": ["prop_haie_01"], "note": "repli : haie sur socle (fiche B6 la juge trop « jardin »)"},
	&"flowers": {"letter": "y", "kind": &"prop",
		"new": ["prop_fleurs_pales_01", "prop_fleurs_pales_02"], "fallback": [],
		"optional": true, "note": "repli : pelouse seule (décalcomanies de fleurs blanches)"},
	&"yew": {"letter": "", "kind": &"prop", "new": ["prop_if_taille_01"], "fallback": [],
		"optional": true, "note": "ifs du parvis, à la main (T14)"},
	&"bench": {"letter": "n", "kind": &"prop", "reused": ["prop_banc_01"]},
	&"landmark_tree": {"letter": "G", "kind": &"prop", "reused": ["tree_a_01", "tree_b_01"]},
	&"house": {"letter": "m", "kind": &"prop", "new": ["bldg_maison_lavanville_01"],
		"fallback": ["bldg_maison_argenta_01"], "note": "m et N (N en miroir), 7 × 6"},
	&"pokemon_house": {"letter": "F", "kind": &"prop", "new": ["bldg_maison_pokemon_01"],
		"fallback": ["bldg_boutique_01"], "note": "8 × 7, portes 4e et 5e colonnes (comme la Boutique)"},
	&"tower": {"letter": "U", "kind": &"prop", "new": ["bldg_tour_pokemon_01"],
		"fallback": ["bldg_musee_argenta_01"],
		"note": "12 × 11 ; repli : musée d'Argenta 12 × 9, emprise et porte à revoir au T14"},
	&"center": {"letter": "C", "kind": &"prop", "reused": ["bldg_centre_01"]},
	&"mart": {"letter": "O", "kind": &"prop", "reused": ["bldg_boutique_01"]},
}

## Tour Pokémon, rez-de-chaussée (20 × 18, sur `cave_map_kit.gd`, murs `K`). Noms alignés sur le
## plan du J19.
const TOWER: Dictionary[StringName, Dictionary] = {
	&"floor": {"letter": ".", "kind": &"ground", "new": ["ground_dalles_tour_01"],
		"fallback": ["ground_dalles_souterrain_01"]},
	&"wall_faces": {"letter": "K", "kind": &"prop",
		"new": ["relief_mur_tour_01", "relief_mur_tour_02"],
		"fallback": ["relief_mur_souterrain_01", "relief_mur_souterrain_02"]},
	&"wall_cap": {"letter": "K", "kind": &"prop", "new": ["relief_mur_tour_03"],
		"fallback": ["relief_mur_souterrain_03"]},
	&"wall_side": {"letter": "K", "kind": &"prop", "new": ["relief_mur_tour_04"],
		"fallback": ["relief_mur_souterrain_04"]},
	&"wall_corner": {"letter": "K", "kind": &"prop", "new": ["relief_mur_tour_05"],
		"fallback": ["relief_mur_souterrain_05"]},
	&"stairs": {"letter": "S", "kind": &"prop", "new": ["relief_escalier_tour_01"],
		"fallback": ["prop_escalier_souterrain_monte_01"]},
	&"grave": {"letter": "g", "kind": &"prop",
		"new": ["int_tombe_tour_01", "int_tombe_tour_02", "int_tombe_tour_03"],
		"fallback": ["prop_rocher_grotte_01"], "note": "repli : pierre arrondie en guise de stèle"},
	&"candle": {"letter": "b", "kind": &"prop", "new": ["int_bougeoir_tour_01"],
		"fallback": ["prop_lampe_chantier_01"]},
	&"counter": {"letter": "W", "kind": &"prop", "new": ["int_comptoir_tour_01"],
		"fallback": ["int_comptoir_pension_01"]},
	&"bench": {"letter": "n", "kind": &"prop", "new": ["int_banc_tour_01"],
		"fallback": ["prop_banc_pierre_01"]},
}

## Toutes les tables, par nom.
static func tables() -> Dictionary:
	return {&"dark_cave": DARK_CAVE, &"routes": ROUTES, &"lavender": LAVENDER, &"tower": TOWER}


## Vrai si l'asset [param id] de nature [param kind] existe dans le dépôt.
static func exists(id: String, kind: StringName) -> bool:
	return ResourceLoader.exists(path_of(id, kind))


static func path_of(id: String, kind: StringName) -> String:
	return GROUND + id + ".png" if kind == KIND_GROUND else PROPS + id + ".tscn"


## `new` (assets de la série 21 tous présents), `reused` (déjà dans le dépôt), `fallback`
## (repli utilisé), `skipped` (facultatif, rien posé) ou `missing` (ni asset ni repli : erreur).
static func status(entry: Dictionary) -> StringName:
	var kind: StringName = entry["kind"]
	if entry.has("reused"):
		return &"reused" if _all_exist(entry["reused"], kind) else &"missing"
	if _all_exist(entry["new"], kind):
		return &"new"
	if not (entry["fallback"] as Array).is_empty():
		return &"fallback" if _all_exist(entry["fallback"], kind) else &"missing"
	return &"skipped" if entry.get("optional", false) else &"missing"


## Identifiants à utiliser (liste vide si `skipped` ou `missing`).
static func pick(entry: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var source: Array = []
	match status(entry):
		&"reused":
			source = entry["reused"]
		&"new":
			source = entry["new"]
		&"fallback":
			source = entry["fallback"]
	for id: Variant in source:
		ids.append(String(id))
	return ids


static func _all_exist(ids: Array, kind: StringName) -> bool:
	for id: Variant in ids:
		if not exists(String(id), kind):
			return false
	return true
