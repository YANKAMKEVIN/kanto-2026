extends GutTest
## Carte de QA du jalon 12 (`qa_moves_j12`, jalon-12.md §2.22, T15 ; modèle `test_qa_switch_j13`
## du J13) et départs `moves_qa` / `moves_qa_solo` : sortie, points d'apparition, hautes herbes
## (table forcée : Nosferapti, Abo, Rondoudou, Racaillou, Voltorbe), Dresseur d'essai `smart`
## (Racaillou Destruction, Rondoudou Repos), capacités du J12 présentes, 12 espèces au Pokédex.
## Puis une partie scriptée par le vrai moteur ([Battle]) avec les Pokémon du départ : chaque
## effet du J12 se déclenche (drain, piège et ses refus, Entrave et sa fin, Repos et son
## sommeil, Destruction, double K.O., Sonicboom). Tout est retiré au T28.

const MAP_ID := &"qa_moves_j12"
const SIZE := Vector2i(24, 16)
const GRASS := Rect2i(1, 10, 6, 4)
const TRAINER_CELL := Vector2i(11, 3)
const START := "res://tools/debug_start/moves_qa.json"
const SOLO := "res://tools/debug_start/moves_qa_solo.json"
const TWELVE: Array[StringName] = [&"ekans", &"arbok", &"clefairy", &"clefable",
	&"jigglypuff", &"wigglytuff", &"zubat", &"golbat", &"paras", &"parasect", &"voltorb",
	&"koffing"]
## Table forcée : [espèce, niveau, capacité du J12 attendue].
const WILD: Array = [["zubat", 22, &"leech_life"], ["ekans", 20, &"wrap"],
	["jigglypuff", 29, &"rest"], ["geodude", 21, &"self_destruct"],
	["voltorb", 20, &"sonic_boom"]]

var _map: GameMap
var _grid: GridWorld
var _data: PokemonData
var _items: ItemLibrary


func before_each() -> void:
	_map = (load(MapCatalog.scene_path(MAP_ID)) as PackedScene).instantiate() as GameMap
	add_child_autofree(_map)
	_grid = _map.get_grid()
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _start(path: String = START) -> DebugStart:
	var start := DebugStart.new()
	assert_true(start.load_file(path, _data, _items), "\n".join(start.get_errors()))
	return start


func _moves_of(start: DebugStart, species: String) -> Array:
	for member: Dictionary in start.party:
		if member["species"] == species:
			return member.get("moves", [])
	return []


# --- Carte ---------------------------------------------------------------------------------

func test_scene_is_a_provisional_qa_map() -> void:
	assert_eq(_map.map_id, MAP_ID)
	assert_eq(_map.size, SIZE)
	assert_true(MapCatalog.is_qa_map(MAP_ID))
	assert_false(MapCatalog.is_qa_map(&"mt_moon_1f"))
	assert_true(_map.light_profile.is_empty())


func test_exit_leads_to_pewter_center_and_nothing_leads_here() -> void:
	var warps := _map.get_warps()
	assert_eq(warps.size(), 3)
	for x: int in [10, 11, 12]:
		var warp := warps.find_on_push(Vector2i(x, 14), Vector2i.DOWN)
		assert_not_null(warp)
		assert_eq([warp.target_map, warp.target_spawn], [&"pewter_city", &"from_center"])
		assert_true(_grid.is_solid(Vector2i(x, 15)))
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		if not file.ends_with(".tscn") or file.begins_with("qa_"):
			continue
		var map := (load(MapCatalog.MAPS_DIR + file) as PackedScene).instantiate() as GameMap
		for warp: Warp in map.get_warps().get_all():
			assert_ne(warp.target_map, MAP_ID, file)
		map.free()


func test_spawns_are_free_and_the_lane_ends_under_the_trainer_sight() -> void:
	for spawn: StringName in [&"moves_start", &"lane_smart"]:
		assert_true(_map.has_spawn(spawn), String(spawn))
		assert_true(_grid.is_free(_map.get_spawn_cell(spawn)), String(spawn))
	var sight: Array[Vector2i] = []
	for i: int in range(1, 6):
		var next := TRAINER_CELL + Vector2i(0, i)
		if _grid.is_solid(next):
			break
		sight.append(next)
	assert_eq(sight.size(), 5, "vision libre")
	assert_eq(_map.get_spawn_cell(&"lane_smart"), TRAINER_CELL + Vector2i(0, 6))
	for y: int in range(GRASS.position.y, GRASS.end.y):
		for x: int in range(GRASS.position.x, GRASS.end.x):
			assert_false(sight.has(Vector2i(x, y)), "herbes hors de la vision")


func test_no_rubble_and_only_the_grass_patch() -> void:
	var count := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			assert_false(_grid.is_rubble(cell), "pas de gravats (validés en 12B)")
			if _grid.is_tall_grass(cell):
				assert_true(GRASS.has_point(cell), str(cell))
				count += 1
	assert_eq(count, GRASS.size.x * GRASS.size.y)


# --- Dresseur ------------------------------------------------------------------------------

func test_smart_trainer_has_destruction_then_rest() -> void:
	var library := TrainerLibrary.new(_data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var npc := _map.get_npc(&"smart")
	assert_not_null(npc)
	assert_eq(npc.get_cell(), TRAINER_CELL)
	assert_eq(npc.get_spec().facing, Vector2i.DOWN)
	assert_eq(npc.get_spec().sight, 5)
	assert_eq(npc.get_spec().trainer_id, &"qa_moves_smart")
	var trainer := library.get_trainer(&"qa_moves_smart")
	assert_eq(trainer.ai, &"smart")
	assert_eq(trainer.team.size(), 2)
	assert_eq([trainer.team[0].species, trainer.team[0].level], [&"geodude", 21])
	assert_true(trainer.team[0].moves.has(&"self_destruct"))
	assert_eq([trainer.team[1].species, trainer.team[1].level], [&"jigglypuff", 29])
	assert_true(trainer.team[1].moves.has(&"rest"))
	assert_true(trainer.team[1].moves.has(&"disable"))


# --- Départs -------------------------------------------------------------------------------

func test_moves_qa_start_party_bag_and_pokedex() -> void:
	var start := _start()
	assert_eq(start.map, MAP_ID)
	assert_eq(start.spawn, &"moves_start")
	var species: Array = []
	for member: Dictionary in start.party:
		species.append([String(member["species"]), int(member["level"])])
	assert_eq(species, [["geodude", 21], ["ekans", 20], ["jigglypuff", 29], ["zubat", 22]])
	assert_true(_moves_of(start, "geodude").has("self_destruct"), "Destruction")
	assert_true(_moves_of(start, "ekans").has("wrap"), "Ligotage")
	assert_true(_moves_of(start, "jigglypuff").has("disable"), "Entrave")
	assert_true(_moves_of(start, "jigglypuff").has("rest"), "Repos")
	assert_true(_moves_of(start, "zubat").has("leech_life"), "Vampirisme")
	assert_true(_moves_of(start, "zubat").has("confuse_ray"), "Onde Folie")
	var seen: Array[StringName] = []
	for member: Dictionary in start.party + start.storage:
		seen.append(StringName(member["species"]))
	for id: StringName in TWELVE:
		assert_true(seen.has(id), "%s au Pokédex (équipe ou Stockage)" % id)
	assert_true(start.flags.has(&"pokedex_activated"))
	assert_true(start.flags.has(&"badge_boulder"))
	for item: StringName in [&"potion", &"poke_ball", &"antidote", &"paralyze_heal",
			&"awakening", &"burn_heal", &"ice_heal"]:
		assert_gt(int(start.bag.get(item, 0)), 0, String(item))


func test_moves_qa_party_moves_are_the_natural_ones() -> void:
	# Toutes les capacités du départ sont apprises au niveau indiqué (Rouge/Bleu) : la clé
	# « moves » ne fait que fixer l'ordre.
	var start := _start()
	for member: Dictionary in start.party:
		var natural := _data.get_species(StringName(member["species"])).moves_at(
			int(member["level"]))
		var wanted: Array[StringName] = []
		for id: Variant in member["moves"]:
			wanted.append(StringName(str(id)))
		wanted.sort()
		natural.sort()
		assert_eq(wanted, natural, member["species"])


func test_forced_table_gives_the_five_qa_species_with_their_j12_move() -> void:
	var start := _start()
	assert_eq(start.wild_terrain, &"grass")
	var slots: Array = start.wild["slots"]
	assert_eq(slots.size(), WILD.size())
	for i: int in WILD.size():
		assert_eq(slots[i]["species"], WILD[i][0])
		assert_eq(int(slots[i]["levels"][0]), WILD[i][1])
		assert_eq(int(slots[i]["levels"][1]), WILD[i][1])
		var pokemon := PokemonFactory.create(_data, StringName(WILD[i][0]), WILD[i][1],
			GameRng.new(i))
		var ids: Array[StringName] = []
		for move: MoveSlot in pokemon.moves:
			ids.append(move.move_id)
		assert_true(ids.has(WILD[i][2]), "%s : %s" % [WILD[i][0], WILD[i][2]])
	# Nosferapti sauvage a aussi Onde Folie, Rondoudou Entrave.
	var zubat := PokemonFactory.create(_data, &"zubat", 22, GameRng.new(1))
	var jiggly := PokemonFactory.create(_data, &"jigglypuff", 29, GameRng.new(1))
	assert_true(_species_moves(jiggly).has(&"disable"))
	assert_true(_species_moves(zubat).has(&"confuse_ray"))


func test_solo_start_is_a_lone_geodude_with_destruction() -> void:
	var start := _start(SOLO)
	assert_eq(start.map, MAP_ID)
	assert_eq(start.party.size(), 1)
	assert_eq(start.party[0]["species"], "geodude")
	assert_eq(_moves_of(start, "geodude")[0], "self_destruct")
	assert_false(start.wild.is_empty())


func _species_moves(pokemon: Pokemon) -> Array[StringName]:
	var ids: Array[StringName] = []
	for move: MoveSlot in pokemon.moves:
		ids.append(move.move_id)
	return ids


# --- Partie scriptée : chaque effet du J12 avec les Pokémon du départ ----------------------
# Vrai moteur ([Battle]), vraie IA, aléatoire réel à graine fixe : pour une scène qui dépend du
# hasard (l'adversaire sauvage choisit au hasard), on essaie les graines 1..SEEDS et on garde la
# première où la condition est vue (reproductible).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const K := BattleEvent.Kind
const P := BattleEvent.SideId.PLAYER
const F := BattleEvent.SideId.FOE
const SEEDS: int = 30
const TURNS: int = 30


## Équipe du départ [param path] construite par [method DebugStart.apply] (graine [param seed]).
func _party_of(path: String, seed: int) -> Party:
	var start := _start(path)
	start.rng_seed = seed
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	return state.party


func _member(party: Party, species: StringName) -> Pokemon:
	for i: int in party.size():
		if party.get_at(i).species_id == species:
			return party.get_at(i)
	return null


## Combat : [param mine] (dans l'ordre) contre un sauvage [param wild] ([espèce, niveau]) ou,
## si [param wild] est vide, contre le Dresseur d'essai (son IA « smart », ses règles).
func _fight(mine: Array, wild: Array, seed: int) -> Battle:
	var party := Party.new()
	for pokemon: Pokemon in mine:
		party.add(pokemon)
	var foes := Party.new()
	var ai: BattleAI = null
	var rules := BattleRules.for_wild(_items)
	var foe_name := ""
	if wild.is_empty():
		var library := TrainerLibrary.new(_data)
		library.load_dir()
		var trainer := library.get_trainer(&"qa_moves_smart")
		for slot: TrainerSlot in trainer.team_for(&""):
			var foe := PokemonFactory.create(_data, slot.species, slot.level, GameRng.new(seed))
			if not slot.moves.is_empty():
				foe.moves.clear()
				for move_id: StringName in slot.moves:
					foe.learn_move(move_id, _data)
			foes.add(foe)
		ai = trainer.make_ai()
		rules = BattleRules.for_trainer(trainer, _items)
		foe_name = trainer.name
	else:
		foes.add(PokemonFactory.create(_data, StringName(wild[0]), int(wild[1]),
			GameRng.new(seed)))
	var battle := Battle.new(BattleSide.new(party, true),
		BattleSide.new(foes, false, foe_name, ai), _data, GameRng.new(seed), rules)
	battle.start()
	return battle


func _slot(battle: Battle, move_id: StringName) -> int:
	var moves := battle.get_player_side().active.pokemon.moves
	for i: int in moves.size():
		if moves[i].move_id == move_id:
			return i
	return -1


## Remplace un K.O. du joueur par le premier Pokémon valide (état REPLACING).
func _replace_if_needed(battle: Battle) -> Array[BattleEvent]:
	if battle.get_state() == Battle.State.REPLACING:
		var party := battle.get_player_side().party
		for index: int in party.size():
			if not party.get_at(index).is_fainted():
				return battle.replace(index)
	return [] as Array[BattleEvent]


## Joue des tours : [param policy] (combat → action ; une action illégale devient la première
## capacité utilisable), jusqu'à [param stop] (événements → booléen) ou la fin du combat.
func _play(battle: Battle, policy: Callable, stop: Callable) -> Array[BattleEvent]:
	var all: Array[BattleEvent] = []
	for i: int in TURNS:
		all.append_array(_replace_if_needed(battle))
		if battle.get_state() != Battle.State.CHOOSING:
			break
		var action: BattleAction = policy.call(battle)
		if not battle.is_legal(action):
			var usable := battle.get_usable_moves()
			action = BattleAction.move(usable[0] if not usable.is_empty()
				else BattleAction.STRUGGLE)
		all.append_array(battle.submit(action))
		if stop.call(all):
			break
	return all


func _use(move_id: StringName) -> Callable:
	return func(battle: Battle) -> BattleAction: return BattleAction.move(_slot(battle, move_id))


func _has(kind: BattleEvent.Kind, side: int) -> Callable:
	return func(events: Array[BattleEvent]) -> bool: return _find(events, kind, side) != null


static func _find(events: Array[BattleEvent], kind: BattleEvent.Kind,
		side: int = -1) -> BattleEvent:
	for event: BattleEvent in events:
		if event.kind == kind and (side < 0 or event.side == side):
			return event
	return null


func test_script_drain_leech_life_heals_zubat() -> void:
	var seen := false
	for seed: int in range(1, SEEDS + 1):
		var party := _party_of(START, seed)
		var zubat := _member(party, &"zubat")
		zubat.hp = zubat.max_hp() / 2
		var battle := _fight([zubat], ["ekans", 20], seed)
		var events := _play(battle, _use(&"leech_life"), _has(K.DRAINED_HP, P))
		var drained := _find(events, K.DRAINED_HP, P)
		if drained != null:
			assert_gt(drained.amount, 0, "PV rendus")
			assert_lte(zubat.hp, zubat.max_hp(), "plafonné")
			seen = true
			break
	assert_true(seen, "Vampirisme rend des PV à Nosferapti")


func test_script_confuse_ray_confuses() -> void:
	var seen := false
	for seed: int in range(1, SEEDS + 1):
		var party := _party_of(START, seed)
		var battle := _fight([_member(party, &"zubat")], ["geodude", 21], seed)
		var events := _play(battle, _use(&"confuse_ray"), _has(K.CONFUSED, F))
		if _find(events, K.CONFUSED, F) != null:
			seen = true
			break
	assert_true(seen, "Onde Folie rend confus")


func test_script_wrap_traps_damages_and_releases_the_foe() -> void:
	var seen := false
	for seed: int in range(1, SEEDS + 1):
		var party := _party_of(START, seed)
		var battle := _fight([_member(party, &"ekans")], ["voltorb", 20], seed)
		var policy := func(b: Battle) -> BattleAction:
			var foe := b.get_foe_side().active
			return BattleAction.move(_slot(b, &"leer" if foe.is_trapped() else &"wrap"))
		var events := _play(battle, policy, _has(K.TRAP_ENDED, F))
		if _find(events, K.TRAP_ENDED, F) != null:
			assert_not_null(_find(events, K.TRAPPED, F))
			assert_not_null(_find(events, K.TRAP_DAMAGED, F), "perte de fin de tour")
			seen = true
			break
	assert_true(seen, "Ligotage : piège, pertes de fin de tour, libération")


func test_script_wild_wrap_refuses_flee_and_switch() -> void:
	var seen := false
	for seed: int in range(1, SEEDS + 1):
		var party := _party_of(START, seed)
		var battle := _fight([_member(party, &"jigglypuff"), _member(party, &"zubat")],
			["ekans", 20], seed)
		var stop := func(_events: Array[BattleEvent]) -> bool: return battle.is_player_trapped()
		_play(battle, _use(&"defense_curl"), stop)
		if battle.is_player_trapped() and battle.get_state() == Battle.State.CHOOSING:
			assert_true(battle.can_flee(), "le bouton FUITE reste")
			assert_false(battle.is_legal(BattleAction.run()), "fuite refusée")
			assert_false(battle.is_legal(BattleAction.switch_to(1)), "changement refusé")
			var events := _play(battle, _use(&"defense_curl"), _has(K.TRAP_ENDED, P))
			if _find(events, K.TRAP_ENDED, P) == null:
				continue
			assert_true(battle.is_legal(BattleAction.run()), "fuite permise ensuite")
			seen = true
			break
	assert_true(seen, "Abo sauvage ligote le joueur, refus, puis libération")


func test_script_sonic_boom_deals_twenty() -> void:
	var seen := false
	for seed: int in range(1, SEEDS + 1):
		var party := _party_of(START, seed)
		var battle := _fight([_member(party, &"jigglypuff")], ["voltorb", 20], seed)
		var stop := func(events: Array[BattleEvent]) -> bool:
			return _sonic_boom_damage(events) >= 0
		var events := _play(battle, _use(&"defense_curl"), stop)
		var amount := _sonic_boom_damage(events)
		if amount >= 0:
			assert_eq(amount, 20, "Sonicboom : 20 PV fixes")
			seen = true
			break
	assert_true(seen, "Voltorbe sauvage lance Sonicboom")


func _sonic_boom_damage(events: Array[BattleEvent]) -> int:
	for i: int in events.size():
		if events[i].kind == K.MOVE_USED and events[i].side == F \
				and events[i].move_id == &"sonic_boom":
			for j: int in range(i + 1, events.size()):
				if events[j].kind == K.DAMAGE and events[j].side == P:
					return events[j].amount
				if events[j].kind == K.MOVE_USED:
					break
	return -1


func test_script_disable_blocks_a_foe_move_then_ends() -> void:
	var seen := false
	for seed: int in range(1, SEEDS + 1):
		var party := _party_of(START, seed)
		var battle := _fight([_member(party, &"jigglypuff")], ["voltorb", 20], seed)
		var turn: Array[int] = [0]
		var policy := func(b: Battle) -> BattleAction:
			turn[0] += 1
			var foe := b.get_foe_side().active
			var id := &"disable" if turn[0] > 1 and not foe.has_disabled_move() \
				else &"defense_curl"
			return BattleAction.move(_slot(b, id))
		var events := _play(battle, policy, _has(K.DISABLE_ENDED, F))
		var start := events.find(_find(events, K.MOVE_DISABLED, F))
		var end := events.find(_find(events, K.DISABLE_ENDED, F))
		if start >= 0 and end > start:
			var blocked := events[start].move_id
			for i: int in range(start + 1, end):
				if events[i].kind == K.MOVE_USED and events[i].side == F:
					assert_ne(events[i].move_id, blocked, "l'adversaire ne la lance pas")
			seen = true
			break
	assert_true(seen, "Entrave bloque une capacité de Voltorbe, puis la fin est annoncée")


func test_script_rest_fails_at_full_hp_then_heals_and_sleeps_two_turns() -> void:
	# Voltorbe est plus rapide : une graine où il ne blesse pas d'abord (Grincement).
	var battle: Battle = null
	var jiggly: Pokemon = null
	for seed: int in range(1, SEEDS + 1):
		var party := _party_of(START, seed)
		jiggly = _member(party, &"jigglypuff")
		battle = _fight([jiggly], ["voltorb", 20], seed)
		var first := battle.submit(BattleAction.move(_slot(battle, &"rest")))
		var failed := _find(first, K.FAILED, P)
		if failed != null:
			assert_eq(failed.move_id, &"rest", "échec de Repos à PV pleins")
			break
		battle = null
	assert_not_null(battle, "Repos échoue à PV pleins")
	if battle == null:
		return
	jiggly.hp = jiggly.max_hp() / 2
	var events := _play(battle, _use(&"rest"), _has(K.RESTED, P))
	assert_not_null(_find(events, K.RESTED, P))
	assert_eq(jiggly.hp, jiggly.max_hp(), "PV pleins")
	assert_eq(jiggly.status, StatusRules.SLEEP)
	assert_eq(jiggly.status_turns, 2)
	var lost := 0
	for i: int in 4:
		var turn := battle.submit(BattleAction.move(_slot(battle, &"defense_curl")))
		if _find(turn, K.MOVE_USED, P) != null:
			break
		lost += 1
	assert_eq(lost, 2, "manque exactement 2 tours")
	assert_eq(jiggly.status, StatusRules.NONE, "réveillé")


func test_script_destruction_against_the_smart_trainer() -> void:
	var party := _party_of(START, 1)
	var battle := _fight([_member(party, &"geodude"), _member(party, &"ekans")], [], 1)
	var events := battle.submit(BattleAction.move(_slot(battle, &"self_destruct")))
	assert_not_null(_find(events, K.SELF_KO, P), "Racaillou se détruit")
	assert_not_null(_find(events, K.FAINTED, P))
	assert_ne(battle.get_outcome(), Battle.Outcome.LOSS, "Abo reste")


func test_script_solo_double_ko_is_lost() -> void:
	var seen := false
	for seed: int in range(1, SEEDS + 1):
		var party := _party_of(SOLO, seed)
		var battle := _fight([party.get_at(0)], ["voltorb", 20], seed)
		var events := battle.submit(BattleAction.move(_slot(battle, &"self_destruct")))
		if _find(events, K.FAINTED, F) != null and _find(events, K.SELF_KO, P) != null:
			assert_eq(battle.get_outcome(), Battle.Outcome.LOSS, "double K.O. perdu")
			seen = true
			break
	assert_true(seen, "double K.O. contre Voltorbe")


func test_script_smart_ai_self_destructs_low_and_rests_hurt() -> void:
	var party := _party_of(START, 1)
	var battle := _fight([_member(party, &"ekans"), _member(party, &"jigglypuff")], [], 1)
	var geodude := battle.get_foe_side().active.pokemon
	var first := battle.submit(BattleAction.move(_slot(battle, &"leer")))
	for event: BattleEvent in first:
		if event.kind == K.MOVE_USED and event.side == F:
			assert_ne(event.move_id, &"self_destruct", "pas de Destruction à PV pleins")
	_replace_if_needed(battle)
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	geodude.hp = maxi(1, geodude.max_hp() / 4)
	var events := _play(battle, _use(&"leer"), _has(K.SELF_KO, F))
	assert_not_null(_find(events, K.SELF_KO, F), "Destruction sous ¼ des PV")
	_replace_if_needed(battle)
	# Rondoudou entre ; à PV pleins, jamais Repos.
	var jiggly := battle.get_foe_side().active.pokemon
	assert_eq(jiggly.species_id, &"jigglypuff")
	assert_eq(battle.get_state(), Battle.State.CHOOSING)
	var turn := battle.submit(BattleAction.move(_slot(battle, &"defense_curl")))
	for event: BattleEvent in turn:
		if event.kind == K.MOVE_USED and event.side == F:
			assert_ne(event.move_id, &"rest", "pas de Repos à PV pleins")
	jiggly.hp = jiggly.max_hp() / 2
	events = _play(battle, _use(&"defense_curl"), _has(K.RESTED, F))
	assert_not_null(_find(events, K.RESTED, F), "Repos quand il est blessé")
