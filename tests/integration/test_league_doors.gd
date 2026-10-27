extends GutTest
## Portes de la Ligue (jalon 30 T8–T9, `jalon-30.md` §2.2, §5) :
## - sur les six scènes construites (`tools/build_j30_league.gd`) : intérieur, `no_fly`,
##   `no_teleport` ; porte sud = warp `unless league_attempt_active` + battant bloquant pendant la
##   tentative ; porte nord = battant bloquant tant que le membre n'est pas battu ; chaque porte
##   mène à un point d'arrivée existant ; le Panthéon n'a pas de porte ;
## - battants réglés par les drapeaux, comparés à [method LeagueAttempt.north_door_open] et
##   [method LeagueAttempt.south_door_open] à chaque étape ;
## - vraie partie (départ `league_lorelei`) : la porte du hall se referme derrière le joueur, Vol
##   et Téléport refusés ; victoire contre Olga → porte nord ouverte, salle d'Aldo, porte sud
##   fermée derrière.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/league_lorelei.json"
const SAVE_PATH := "user://test_league_doors_save.json"
const ROOMS: Array[StringName] = [&"league_lorelei", &"league_bruno", &"league_agatha",
	&"league_lance", &"league_champion"]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


func _scene(map_id: StringName) -> GameMap:
	return (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap


func _warps(map: GameMap, prefix: String) -> Array[WarpPoint]:
	var found: Array[WarpPoint] = []
	for node: Node in map.get_node(^"Warps").get_children():
		if String(node.name).begins_with(prefix):
			found.append(node as WarpPoint)
	return found


func _gate(map: GameMap, gate_name: String) -> FlagGate:
	return map.get_node(^"Entities").get_node_or_null(NodePath(gate_name)) as FlagGate


# --- Scènes -------------------------------------------------------------------------------------

func test_every_room_is_an_interior_without_fly_or_teleport() -> void:
	for map_id: StringName in ROOMS + [&"hall_of_fame"]:
		var map := _scene(map_id)
		assert_eq(map.map_id, map_id)
		assert_true(map.interior, "%s : intérieur" % map_id)
		assert_true(map.no_fly, "%s : no_fly" % map_id)
		assert_true(map.no_teleport, "%s : no_teleport" % map_id)
		map.free()
	# Les règles lisent ces marques même hors intérieur (traits construits comme les directeurs).
	var traits := FlyRules.traits_of(false, false)
	traits.no_fly = true
	assert_eq(FlyRules.can_fly(FieldMoves.State.READY, traits), FlyRules.Check.NO_FLY)
	var travel := MapTraits.new(false)
	travel.no_teleport = true
	assert_eq(FieldTravelRules.check_teleport(FieldMoves.State.READY, travel, &"viridian_center"),
		FieldTravelRules.Check.NOT_HERE)


func test_doors_lead_on_in_order_and_close_by_flags() -> void:
	for stage: int in ROOMS.size():
		var map := _scene(ROOMS[stage])
		var south := _warps(map, "PorteSud")
		var north := _warps(map, "PorteNord")
		assert_gt(south.size(), 0, "%s : porte sud" % ROOMS[stage])
		assert_gt(north.size(), 0, "%s : porte nord" % ROOMS[stage])
		var back := &"indigo_plateau_lobby" if stage == 0 else ROOMS[stage - 1]
		for warp: WarpPoint in south:
			assert_eq(warp.target_map, back)
			assert_eq(warp.unless_flags, [LeagueAttempt.ACTIVE] as Array[StringName],
				"%s : porte sud inactive pendant la tentative" % ROOMS[stage])
		var next := &"hall_of_fame" if stage == 4 else ROOMS[stage + 1]
		for warp: WarpPoint in north:
			assert_eq(warp.target_map, next)
			var target := _scene(next)
			assert_not_null(target.get_node(^"Spawns").get_node_or_null(NodePath(warp.target_spawn)),
				"%s:%s existe" % [next, warp.target_spawn])
			target.free()
		var south_gate := _gate(map, "PorteSudFermee")
		var north_gate := _gate(map, "PorteNordFermee")
		assert_eq(south_gate.if_flags, [LeagueAttempt.ACTIVE] as Array[StringName])
		assert_eq(north_gate.unless_flags, [LeagueAttempt.stage_flag(stage)] as Array[StringName])
		assert_eq(north_gate.blocking_cells.size(), north.size())
		assert_eq(south_gate.blocking_cells.size(), south.size())
		# Battants comparés à la machine à états, étape par étape.
		var flags := StoryFlags.new()
		for progress: int in range(-1, LeagueAttempt.STAGE_COUNT + 1):
			flags.clear()
			if progress >= 0:
				LeagueAttempt.start(flags)
				for won: int in progress:
					LeagueAttempt.record_victory(flags, won)
			assert_eq(not north_gate.is_open(flags), LeagueAttempt.north_door_open(flags, stage),
				"%s, progression %d : porte nord" % [ROOMS[stage], progress])
			assert_eq(not south_gate.is_open(flags), LeagueAttempt.south_door_open(flags, stage),
				"%s, progression %d : porte sud" % [ROOMS[stage], progress])
		map.free()
	var hall := _scene(&"hall_of_fame")
	assert_eq(hall.get_node(^"Warps").get_child_count(), 0, "le Panthéon n'a pas de porte")
	hall.free()


func test_lorelei_has_the_lobby_arrival_point() -> void:
	var map := _scene(&"league_lorelei")
	var spawns := map.get_node(^"Spawns")
	assert_not_null(spawns.get_node_or_null(^"from_lobby"), "arrivée par le hall (J29 : ToLeague)")
	assert_eq((spawns.get_node(^"from_lobby") as Node2D).position,
		(spawns.get_node(^"from_south") as Node2D).position)
	for warp: WarpPoint in _warps(map, "PorteSud"):
		assert_eq(warp.target_spawn, &"league_door", "point du hall du J29")
	map.free()


# --- Vraie partie ------------------------------------------------------------------------------

func test_the_door_closes_behind_and_opens_after_lorelei() -> void:
	await _play.start(START, func() -> void:
		var ace := PokemonFactory.create(_play.boot.get_pokemon_data(), &"alakazam", 100,
			GameState.rng)
		ace.moves.clear()
		ace.moves.append(MoveSlot.new(&"thunderbolt", 15))
		GameState.party.remove_at(0)
		GameState.party.add(ace)
		GameState.party.move(GameState.party.size() - 1, 0))
	assert_eq(_play.map_id(), &"league_lorelei")
	assert_true(LeagueAttempt.is_active(GameState.flags), "tentative commencée à l'entrée")
	var expected_rest := LeagueDirector.REST_MAP \
		if MapCatalog.has_map(LeagueDirector.REST_MAP) else &"viridian_center"
	assert_eq(GameState.heal_map, expected_rest, "Plateau (ou Jadielle tant que le J29 manque)")
	assert_ne(_play.boot.get_fly_director().check(&"viridian_city"), FlyRules.Check.OK,
		"Vol refusé")
	# La porte du hall s'est refermée.
	var entry := _play.player.get_cell()
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.map_id(), &"league_lorelei")
	assert_eq(_play.player.get_cell(), entry, "porte sud fermée")
	# Premier pas vers Olga : l'appel, le combat, la victoire.
	await _play.step(Vector2i.UP)
	assert_true(await _play.run_scene(), "combat contre Olga")
	assert_true(GameState.flags.has_flag(&"league_stage_0_cleared"))
	assert_true(GameState.flags.has_flag(&"beaten_league_lorelei"))
	assert_true(_play.events.has("card:OLGA/Conseil des Quatre"), "carte de présentation")
	assert_true(_play.pages().has("Tu as du talent… Va. Les autres t'attendent."))
	var map := _play.boot.get_map()
	assert_false(map.get_grid().is_occupied(Vector2i(4, 0)), "porte nord ouverte")
	await _play.walk_to(Vector2i(4, 1))
	await _play.step(Vector2i.UP)
	assert_eq(_play.map_id(), &"league_bruno", "salle d'Aldo")
	assert_eq(_play.player.get_cell(), _play.boot.get_map().get_spawn_cell(&"from_south"))
	entry = _play.player.get_cell()
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.player.get_cell(), entry, "pas de retour chez Olga")
	assert_eq(LeagueAttempt.current_stage(GameState.flags), 1)
	assert_push_error_count(0)
