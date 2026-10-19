extends GutTest
## Cohérence globale des passages (jalon 2 §4.8), sur les 5 cartes :
## - chaque warp vise une carte existante et un spawn existant, case d'arrivée praticable ;
## - retour sur place : la case d'arrivée porte un warp qui ramène à la carte d'origine,
##   ou (escaliers des pièces à murs sur 4 côtés) le retour est à un pas, dans une case
##   voisine atteinte en marchant vers elle ;
## - table des warps de chaque carte construite sans erreur.

const MAP_IDS: Array[StringName] = [
	&"pallet_town", &"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab",
	&"route_1", &"viridian_city", &"viridian_center", &"viridian_mart", &"route_2",
	# Jalon 9 (T19) : la Forêt de Jade et ses deux postes.
	&"viridian_forest", &"viridian_forest_gate_south", &"viridian_forest_gate_north",
	# Jalon 10 (T13) : les intérieurs d'Argenta.
	&"pewter_center", &"pewter_mart", &"pewter_museum", &"pewter_museum_science", &"pewter_gym",
	&"pewter_house_mason", &"pewter_house_researcher",
	# Jalon 10 (T11) : la Route 2 nord et Argenta (intérieurs « à venir » jusqu'au T13).
	&"route_2_north", &"pewter_city",
	# Jalon 12 (T8) : la Route 3, le Centre du Mont Sélénite, le sas de la Route 4.
	&"route_3", &"mt_moon_center", &"route_4",
	# Jalon 12 (T9) : les trois étages du Mont Sélénite.
	&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f",
	# Jalon 13 (T7) : Azuria et ses intérieurs.
	&"cerulean_city", &"cerulean_center", &"cerulean_mart", &"cerulean_gym",
	&"cerulean_bike_shop", &"cerulean_house",
	# Jalon 14 (T20b) : la maison cambriolée.
	&"cerulean_burgled_house",
	# Jalon 13 (T8) : la Route 24 (la Route 4 est devenue la vraie Route 4, même identifiant).
	&"route_24",
	# Jalon 14 (T14) : la Route 25 et la maison de Léo (raccord ouest vers la Route 24 au T15).
	&"route_25", &"bill_house",
	# Jalon 15 (T18) : le passage souterrain.
	&"underground_path",
	# Jalon 15 (T14) : la Route 6, son bâtiment d'entrée du souterrain, Carmin et ses intérieurs.
	&"route_6", &"route_6_underground_gate", &"vermilion_city", &"vermilion_center",
	&"vermilion_mart", &"vermilion_fan_club", &"vermilion_fisher_house", &"vermilion_house_1",
	&"vermilion_house_2",
	# Jalon 15 (T13, T21) : la Route 5 (raccord réel avec Azuria) et ses trois intérieurs.
	&"route_5", &"route_5_daycare", &"route_5_gate", &"route_5_underground_gate",
	# Jalon 17 (T15, T16, T19) : la Cave Taupiqueur, la Route 11 (raccord réel avec Carmin au
	# T17), le couloir de la Route 2 est et le poste de l'assistant.
	&"digletts_cave", &"route_11", &"route_2_east", &"route_2_east_gate",
	# Jalon 16 (T11) : les 9 pièces du S.S. Anne et l'Arène de Carmin.
	&"ss_anne_main_deck", &"ss_anne_captain_corridor", &"ss_anne_captain_room",
	&"ss_anne_restaurant", &"ss_anne_lower_deck", &"ss_anne_outer_deck", &"ss_anne_cabin_a",
	&"ss_anne_cabin_b", &"ss_anne_cabin_c", &"vermilion_gym",
	# Jalon 18 (T12) : Route 9, Route 10 et son Centre (Azuria, Grotte Sombre et Lavanville :
	# « à venir » tant que leurs cartes J18 ne sont pas là).
	&"route_9", &"route_10", &"route_10_center",
	# Jalon 18 (T13) : la Grotte Sombre (sorties en repli « à venir » tant que la Route 10 manque).
	&"dark_cave_1f", &"dark_cave_b1f",
	# Jalon 18 (T14) : Lavanville, ses intérieurs et le rez-de-chaussée de la Tour.
	&"lavender_town", &"lavender_center", &"lavender_mart", &"pokemon_house",
	&"lavender_house_1", &"lavender_house_2", &"pokemon_tower_1f",
]
## Cartes dont les passages « à venir » sont comptés dans leur propre test (jalon 18).
const OWN_COMING_SOON_COUNT: Array[StringName] = [&"lavender_town", &"pokemon_tower_1f"]
## Retours pas encore branchés : [carte d'origine, carte cible]. Jalon 16 (T15) : vide (Carmin
## mène au pont principal du S.S. Anne et à l'Arène ; les retours sont vérifiés).
const PENDING_RETURNS: Array = []
## Cartes construites par une autre tâche en parallèle (jalon 7 : la Route 22, T22 ; jalon 10 :
## Argenta, T11, pendant les intérieurs du T13) : un warp qui y mène est vérifié seulement si la
## carte existe déjà (sinon le test le signale).
## Jalon 12 : Route 3, sas (T8) et étages du Mont Sélénite (T9) sont tous construits.
## Jalon 15 : les bâtiments d'entrée du souterrain (T13, T14) sont intégrés.
## Jalon 17 : la Cave Taupiqueur (T15), la Route 11 (T16) et la Route 2 est (T19) sont intégrées.
const PARALLEL_MAPS: Array[StringName] = [&"route_22"]
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _maps: Dictionary = {}


func before_all() -> void:
	for map_id: StringName in MAP_IDS:
		var scene := load(MapCatalog.scene_path(map_id)) as PackedScene
		if scene != null:
			var map := scene.instantiate() as GameMap
			add_child(map)
			_maps[map_id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


func _warp_count_in_scene(map: GameMap) -> int:
	var count := 0
	for child: Node in map.get_node(^"Warps").get_children():
		if child is WarpPoint:
			count += 1
	return count


func test_all_maps_load_and_warp_tables_build_without_error() -> void:
	for map_id: StringName in MAP_IDS:
		assert_true(MapCatalog.has_map(map_id), String(map_id))
		assert_true(_maps.has(map_id), "%s se charge" % map_id)
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		map.rebuild_grid()
		# Un warp invalide ou ambigu serait écarté de la table (avec push_error).
		assert_eq(map.get_warps().size(), _warp_count_in_scene(map), String(map_id))
		assert_gt(map.get_warps().size(), 0, "%s a au moins un passage" % map_id)
	assert_push_error_count(0)


func test_every_warp_targets_existing_map_and_walkable_spawn() -> void:
	for map_id: StringName in _maps:
		for warp: Warp in (_maps[map_id] as GameMap).get_warps().get_all():
			if warp.is_coming_soon():
				continue  # destination « à venir » : voir le test dédié
			var label := "%s %s → %s/%s" % [map_id, warp.cell, warp.target_map, warp.target_spawn]
			if PARALLEL_MAPS.has(warp.target_map) and not MapCatalog.has_map(warp.target_map):
				gut.p("%s : carte « %s » pas encore construite (tâche parallèle)" % [label,
					warp.target_map])
				continue
			if PARALLEL_MAPS.has(warp.target_map):
				var other := (load(MapCatalog.scene_path(warp.target_map)) as PackedScene) \
						.instantiate() as GameMap
				assert_true(other.has_spawn(warp.target_spawn), label)
				other.free()
				continue
			assert_true(MapCatalog.has_map(warp.target_map), label)
			var target := _maps.get(warp.target_map) as GameMap
			if target == null:
				continue
			assert_true(target.has_spawn(warp.target_spawn), label)
			var arrival := target.get_spawn_cell(warp.target_spawn)
			var grid := target.get_grid()
			assert_true(grid.is_in_bounds(arrival), label)
			assert_false(grid.is_solid(arrival) or grid.is_water(arrival),
				"%s : arrivée praticable" % label)


func test_every_coming_soon_warp_returns_to_a_walkable_spawn_of_its_own_map() -> void:
	# Destination « à venir » (dossier-07 §12) : pas de carte cible, le retour se fait sur un
	# point d'apparition de la carte courante, praticable, avec un libellé et une orientation.
	var found := 0
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		for warp: Warp in map.get_warps().get_all():
			if not warp.is_coming_soon() or OWN_COMING_SOON_COUNT.has(map_id):
				continue
			found += 1
			var label := "%s %s « %s »" % [map_id, warp.cell, warp.coming_soon]
			assert_true(map.has_spawn(warp.target_spawn), "%s : spawn de retour" % label)
			var back := map.get_spawn_cell(warp.target_spawn)
			assert_false(map.get_grid().is_solid(back), "%s : retour praticable" % label)
			assert_ne(warp.facing, Vector2i.ZERO, "%s : orientation au retour" % label)
	# Jalon 15 (T13, T21) : le sud d'Azuria mène à la vraie Route 5 ; reste l'ouverture
	# nord du poste vers Safrania (2 cases, jamais atteinte). Jalon 15 (T14) : Route 11
	# (trois cases), Safrania (porte nord de la Route 6, une). Jalon 16 (T15) : l'Arène de
	# Carmin et l'embarquement du S.S. Anne sont branchés. Jalon 17 (T17) : le bord est de Carmin
	# mène à la vraie Route 11. Jalon 18 (T15) : Azuria et la Route 9 sont reliées (arbre coupé du
	# J16) ; la Grotte Sombre et Lavanville sont reliées à la Route 10, et les passages de
	# Lavanville et de la Tour sont comptés dans leurs propres tests.
	assert_eq(found, 3, "« SAFRANIA » (2), Safrania (1)")


## Warp de [param map] qui ramène à [param origin] depuis [param arrival] : sur la case
## même, dans une case voisine atteinte en un pas vers elle (STEP_ON), ou au bout d'un pas vers
## une case de bord qu'on pousse dans la même direction (PUSH : bouches de la Cave Taupiqueur,
## J17, arrivée une case en retrait de la bouche).
func _return_warp(map: GameMap, arrival: Vector2i, origin: StringName) -> Warp:
	for warp: Warp in map.get_warps().get_at(arrival):
		if warp.target_map == origin:
			return warp
	for direction: Vector2i in DIRECTIONS:
		var next := arrival + direction
		var reachable := map.get_grid().get_step_target(arrival, direction) == next
		var warp := map.get_warps().find_on_step(next, direction)
		if warp != null and warp.target_map == origin \
				and (reachable or _blocked_only_by_a_character(map, next)):
			return warp
		warp = map.get_warps().find_on_push(next, direction)
		if warp != null and warp.target_map == origin and reachable:
			return warp
		# Jalon 16 (T11) : sortie PUSH à un pas (les pièces du S.S. Anne : arrivée de la grille
		# une case au-dessus de la sortie, dans l'encadrement du mur).
		var push := map.get_warps().find_on_push(next, direction)
		if push != null and push.target_map == origin \
				and map.get_grid().get_step_target(arrival, direction) == next:
			return push
	return null


## Porte condamnée par un personnage (le ruban d'Azuria, J14) : la case est praticable, un PNJ
## l'occupe tant que le Rocket n'est pas battu.
func _blocked_only_by_a_character(map: GameMap, cell: Vector2i) -> bool:
	return map.get_grid().is_occupied(cell) and not map.get_grid().is_solid(cell)


func test_every_warp_is_reversible_on_the_spot() -> void:
	for map_id: StringName in _maps:
		for warp: Warp in (_maps[map_id] as GameMap).get_warps().get_all():
			var target := _maps.get(warp.target_map) as GameMap
			if target == null or warp.is_coming_soon():
				continue
			if PENDING_RETURNS.has([map_id, warp.target_map]):
				continue
			var arrival := target.get_spawn_cell(warp.target_spawn)
			var back := _return_warp(target, arrival, map_id)
			assert_not_null(back, "retour de %s/%s vers %s" % [warp.target_map, arrival, map_id])
			if back == null:
				continue
			# Le retour ramène au passage d'origine : sur sa case, ou à un pas d'un passage
			# vers la même carte (escalier de 2 cases, un seul spawn).
			var origin: GameMap = _maps[map_id]
			var home := origin.get_spawn_cell(back.target_spawn)
			assert_true(_is_at_or_next_to_warp_to(origin, home, warp.target_map),
				"%s : retour en %s pour un départ en %s" % [map_id, home, warp.cell])


func _is_at_or_next_to_warp_to(map: GameMap, cell: Vector2i, target: StringName) -> bool:
	for warp: Warp in map.get_warps().get_all():
		if warp.target_map != target:
			continue
		if warp.cell == cell or Grid.is_cardinal(warp.cell - cell):
			return true
	return false


func test_player_house_stairs_link_both_floors() -> void:
	var bedroom: GameMap = _maps[&"player_house_2f"]
	var ground: GameMap = _maps[&"player_house_1f"]
	assert_eq(bedroom.get_spawn_cell(&"stairs"), Vector2i(6, 8))
	assert_eq(ground.get_spawn_cell(&"stairs"), Vector2i(2, 4))
	for cell: Vector2i in [Vector2i(1, 3), Vector2i(2, 3)]:
		var up := ground.get_warps().find_on_step(cell, Vector2i.UP)
		assert_not_null(up, "escalier ↑ en %s" % cell)
		if up != null:
			assert_eq(up.target_map, &"player_house_2f")
			assert_eq(up.target_spawn, &"stairs")
	for cell: Vector2i in [Vector2i(6, 9), Vector2i(7, 9)]:
		var down := bedroom.get_warps().find_on_step(cell, Vector2i.DOWN)
		assert_not_null(down, "escalier ↓ en %s" % cell)
		if down != null:
			assert_eq(down.target_map, &"player_house_1f")
			assert_eq(down.target_spawn, &"stairs")
		assert_null(bedroom.get_warps().find_on_step(cell, Vector2i.LEFT), "pas de côté")


func test_single_level_rival_house_and_lab_link_to_the_village() -> void:
	# Maison du rival (un seul niveau, §4.5) et labo (§4.7) : la porte mène au tapis,
	# le tapis ramène sur la case de porte.
	var village: GameMap = _maps[&"pallet_town"]
	for spec: Array in [[Vector2i(11, 9), &"rival_house", &"rival_house_door"],
			[Vector2i(24, 22), &"oak_lab", &"oak_lab_door"]]:
		var door := village.get_warps().find_on_step(spec[0], Vector2i.UP)
		assert_not_null(door, "porte en %s" % spec[0])
		if door == null:
			continue
		assert_eq(door.target_map, spec[1])
		assert_eq(door.target_spawn, &"entrance")
		var inside: GameMap = _maps[spec[1]]
		var mat := inside.get_spawn_cell(&"entrance")
		var exit := inside.get_warps().find_on_push(mat, Vector2i.DOWN)
		assert_not_null(exit, "%s : sortie sur le tapis" % spec[1])
		if exit != null:
			assert_eq(exit.target_map, &"pallet_town")
			assert_eq(exit.target_spawn, spec[2])
			assert_eq(village.get_spawn_cell(spec[2]), spec[0])
	for gone: StringName in [&"rival_house_1f", &"rival_house_2f"]:
		assert_false(MapCatalog.has_map(gone), "%s supprimée" % gone)


## Invariant du 3B adapté au jalon 4 (jalon-04.md §13.6) : jamais un déclencheur de scène sur
## un warp STEP_ON (le changement de carte partirait avec la scène). Un déclencheur peut
## partager la case d'un warp PUSH : l'arrivée sur la case (scène, blocage) précède la
## poussée. Tables des déclencheurs construites sans erreur.
func test_no_trigger_on_a_step_on_warp() -> void:
	var shared := 0
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		map.rebuild_grid()
		for trigger: EventTrigger in map.get_triggers().get_all():
			for warp: Warp in map.get_warps().get_at(trigger.cell):
				assert_ne(warp.trigger, Warp.Trigger.STEP_ON,
					"%s : déclencheur « %s » sur un warp STEP_ON en %s" % [map_id,
					trigger.cutscene_id, trigger.cell])
				shared += 1
	# Jalon 16 (T15) : la passerelle du pont principal du S.S. Anne (2 cases PUSH, départ).
	assert_eq(shared, 3, "partages : le tapis de sortie du labo, la passerelle du S.S. Anne "
		+ "(warps PUSH)")
	assert_push_error_count(0)
