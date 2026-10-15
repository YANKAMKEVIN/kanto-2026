extends RefCounted
## Destination « à venir » pour les tests du mécanisme (écran provisoire, compagnon, sauvegarde).
## Depuis le jalon 17 (T17), plus aucun raccord atteignable du jeu n'est « à venir » : le bord est
## de Carmin-sur-Mer mène à la vraie Route 11. Ce module remet les trois cases du bord est de
## Carmin « à venir » **dans la carte chargée seulement** (le `PackedScene` du jeu n'est pas
## touché ; la carte rechargée retrouve la vraie Route 11), comme le faisait le sud d'Azuria au
## jalon 15. Utilisation :
## [code]const ComingSoonGate := preload("res://tests/helpers/coming_soon_gate.gd")[/code].

const LABEL: String = "Route 11"


## Passe en « à venir » les raccords de [param map] qui mènent à la Route 11 ; le retour se fait
## sur le point d'apparition de Carmin (`from_route_11_n|c|s`), tourné vers l'ouest.
static func apply(map: GameMap) -> void:
	for node: Node in map.get_node(^"Warps").get_children():
		var warp := node as WarpPoint
		if warp == null or warp.target_map != &"route_11":
			continue
		warp.target_spawn = StringName(String(warp.target_spawn).replace("from_vermilion_",
			"from_route_11_"))
		warp.target_map = &""
		warp.arrival_facing = Vector2i.LEFT
		warp.coming_soon = LABEL
	map.rebuild_grid()
