extends RefCounted
## Bord « à venir » de test (jalon 15 T21). Depuis que la vraie Route 5 a remplacé « ROUTE 5 — À
## venir » au sud d'Azuria, aucun bord extérieur du jeu n'est plus « à venir » (le prochain : la
## Route 11 à l'est de Carmin, T14). Les tests du mécanisme (`test_coming_soon`,
## `test_companion_coming_soon`) remettent donc, **dans la carte chargée seulement**, les trois
## passages du sud d'Azuria (31..33, 40) dans leur état du J14 : destination « Route 5 — À venir »,
## retour sur `from_route_5_w|c|e`, tourné vers le nord. Rien n'est écrit sur disque.
## Utilisation : [code]const ComingSoonGate := preload("res://tests/helpers/coming_soon_gate.gd")[/code].

const MAP := &"cerulean_city"
const LABEL := "Route 5"
const SUFFIXES: Array[String] = ["W", "C", "E"]


## Remet les passages `Route5W|C|E` de [param map] en « à venir » ; renvoie leur nombre.
static func apply(map: GameMap) -> int:
	var count := 0
	for suffix: String in SUFFIXES:
		var point := map.get_node_or_null(NodePath("Warps/Route5" + suffix)) as WarpPoint
		if point == null:
			continue
		point.target_map = &""
		point.target_spawn = StringName("from_route_5_" + suffix.to_lower())
		point.arrival_facing = Vector2i.UP
		point.coming_soon = LABEL
		count += 1
	# Seule la table des passages est refaite (la grille, le joueur et les PNJ ne bougent pas).
	map.call(&"_build_warps")
	return count
