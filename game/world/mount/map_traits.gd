class_name MapTraits
extends RefCounted
## Ce qu'une carte permet à la monture du joueur (passe systèmes 2, `docs/tech/systemes-2.md`
## §2.2) : pur, sans nœud. Lu sur [GameMap] par l'appelant (T6) ; les tests le construisent à la
## main.
##
## Le Vélo est permis en extérieur **et en grotte** (dossier 25) : une grotte n'est pas
## [member interior].

## Intérieur (maison, bâtiment) : pas de Vélo, on descend à l'arrivée.
var interior: bool = false
## Tronçon de Piste Cyclable : on y monte d'office, on n'en descend pas.
var cycling_road: bool = false
## Vélo interdit sur cette carte sans être un intérieur (réservé, aucune carte ne s'en sert encore).
var no_bike: bool = false
## Vol interdit depuis cette carte (§2.8).
var no_fly: bool = false
## Téléport interdit depuis cette carte (T25b ; réservé : le Parc Safari du J23 le posera).
var no_teleport: bool = false
## Cases où l'on arrive en Surf même par un warp à pied (§2.5, « Surf forcé »).
var forced_surf_cells: Dictionary[Vector2i, bool] = {}


func _init(p_interior: bool = false, p_cycling_road: bool = false) -> void:
	interior = p_interior
	cycling_road = p_cycling_road


## Vrai si le Vélo est permis ici.
func allows_bike() -> bool:
	return not interior and not no_bike
