extends RefCounted
## Emprises au sol des objets du prototype (en cases) et grille de déplacement des
## personnages : les marcheurs contournent les obstacles au lieu de les traverser.
## Le pied d'un objet est la ligne de sol de sa base : l'emprise est juste au-dessus.

const CASE := 96

## [préfixe de texture, largeur en cases (0 = celle de la texture), profondeur en cases].
const REGLES: Array = [
	["cloture_piquets_v", 1, 3],  # avant « cloture » (préfixe commun)
	["centre", 8, 4], ["boutique", 8, 4], ["arene", 10, 4], ["maison_a", 6, 3],
	["maison_b", 5, 3], ["tree", 1, 1], ["banc", 2, 1], ["lampadaire", 1, 1],
	["panneau", 1, 1], ["rocher", 2, 1], ["haie", 4, 1], ["cloture", 4, 1],
	["falaise", 4, 1], ["int_comptoir", 5, 1], ["int_caisse", 5, 1], ["int_rayon", 3, 1],
	["int_presentoir", 3, 1], ["int_banquette", 2, 1], ["int_plante", 1, 1],
	["int_terminal", 2, 1],
	# Bourg Palette (série 06).
	["maison_joueur", 6, 3], ["maison_rival", 6, 3], ["labo", 10, 4], ["serre", 3, 2],
	["arbre_ancien", 4, 3], ["champ", 5, 3], ["camionnette", 3, 2], ["velo", 1, 1],
	["boite_lettres", 1, 1], ["potager", 3, 1], ["ronces", 2, 1], ["tronc_couche", 3, 1],
	["rocher_mer", 2, 1], ["buisson", 1, 1], ["platebande", 3, 1], ["pots_fleurs", 1, 1],
	["tonneau", 1, 1], ["linge", 3, 1], ["fruitier", 1, 1], ["caisses", 1, 1], ["haie_v", 1, 3],
	["epouvantail", 1, 1], ["barque", 1, 2], ["casiers", 2, 1], ["materiel_labo", 2, 1],
	["ratelier", 2, 1], ["brouette", 1, 1], ["tas_bois", 2, 1], ["arrosoir", 1, 1],
	["mangeoire", 1, 1], ["hortensias", 1, 1],
]


## Emprises d'un objet posé : `pied` en cases (milieu de la base). Vide si l'objet se
## traverse (escalier, herbes hautes, décor de fond).
static func de(nom: String, pied: Vector2) -> Array[Rect2i]:
	var emprises: Array[Rect2i] = []
	if nom.begins_with("porte_nord"):
		# Seulement les deux piliers : le passage entre eux reste libre.
		var bas := ceili(pied.y) - 1
		emprises.append(Rect2i(floori(pied.x - 2.5), bas, 1, 1))
		emprises.append(Rect2i(floori(pied.x + 1.5), bas, 1, 1))
		return emprises
	for regle: Array in REGLES:
		if nom.begins_with(regle[0]):
			var largeur: int = regle[1]
			var profondeur: int = regle[2]
			var gauche := floori(pied.x - largeur / 2.0 + 0.5)
			if largeur == 1:
				gauche = floori(pied.x)
			emprises.append(Rect2i(gauche, ceili(pied.y) - profondeur, largeur, profondeur))
			break
	return emprises


## Grille de déplacement (4 directions) de la taille de la carte, obstacles posés.
static func grille(taille: Vector2i, obstacles: Array[Rect2i]) -> AStarGrid2D:
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, taille)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for zone in obstacles:
		astar.fill_solid_region(zone.intersection(astar.region), true)
	return astar
