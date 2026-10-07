extends GutTest
## DebugStart : départ de débogage (jalon 5 T9). Inactif par défaut, jamais sous GUT ni en
## release ; lecture stricte du fichier de fixtures ; partie construite dans GameState.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FIXTURES := "res://tests/fixtures/debug_start/"
const TOOL_STARTS := "res://tools/debug_start/"

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


# --- Inactif par défaut -------------------------------------------------------------------

func test_allowed_only_in_a_debug_build_with_boot_as_main_scene() -> void:
	assert_true(DebugStart.is_allowed(true, true))
	assert_false(DebugStart.is_allowed(false, true), "export release : jamais")
	assert_false(DebugStart.is_allowed(true, false),
		"GUT, outils : Boot n'est pas la scène principale")
	assert_false(DebugStart.is_allowed(false, false))


func test_never_allowed_under_gut() -> void:
	# Les tests tournent en build debug, mais la scène principale n'est jamais Boot.
	assert_true(OS.is_debug_build())
	var current := get_tree().current_scene
	assert_false(current is Boot)
	assert_false(DebugStart.is_allowed(OS.is_debug_build(), current is Boot))


func test_user_file_is_the_only_trigger() -> void:
	assert_eq(DebugStart.USER_PATH, "user://debug_start.json")
	var start := DebugStart.new()
	assert_false(start.load_file("user://absent_debug_start.json", _data, _items))
	assert_push_error("fichier introuvable")


# --- Lecture ------------------------------------------------------------------------------

func test_valid_fixture() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(FIXTURES + "valid.json", _data, _items), "\n".join(
		start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"route_1", &"from_pallet_w",
		Vector2i.UP])
	assert_eq(start.rng_seed, 7)
	assert_eq(start.flags, [&"starter_chosen", &"rival_battle_done"] as Array[StringName])
	assert_eq(start.party.size(), 2)
	assert_eq(start.bag, { &"poke_ball": 5 } as Dictionary[StringName, int])


func test_defaults() -> void:
	var start := DebugStart.new()
	assert_true(start.add_from_dict({ "party": [{ "species": "charmander", "level": 5 }] },
		_data, _items))
	assert_eq([start.map, start.spawn, start.facing, start.rng_seed], [&"", &"",
		Vector2i.DOWN, -1])
	assert_eq(start.flags.size(), 0)
	assert_eq(start.bag.size(), 0)


func test_broken_json_reports_the_line() -> void:
	var start := DebugStart.new()
	assert_false(start.load_file(FIXTURES + "broken.json", _data, _items))
	assert_string_contains("\n".join(start.get_errors()), "broken.json, ligne 3")
	assert_push_error_count(1)


func test_invalid_fields_are_rejected_and_nothing_is_kept() -> void:
	var start := DebugStart.new()
	var ok := start.add_from_dict({
		"map": "route_1", "facing": "north", "seed": -3, "flags": [""], "color": "red",
		"party": [
			{ "species": "missingno", "level": 5 },
			{ "species": "charmander", "level": 0 },
			{ "species": "charmander", "level": 5, "moves": ["scratch", "scratch"] },
			{ "species": "charmander", "level": 5, "exp_to_next": 500, "shiny": true },
		],
		"bag": { "master_ball": 1, "poke_ball": 0 },
	}, _data, _items, "t")
	assert_false(ok)
	var errors := "\n".join(start.get_errors())
	for expected: String in [
		"t : clé inconnue « color »",
		"« map » et « spawn » sont des textes non vides, ensemble",
		"« facing » vaut up, down, left ou right",
		"« seed » est un entier ≥ 0",
		"« flags » est une liste de textes",
		"t party 1 : espèce inconnue « missingno »",
		"t party 2 : « level » est un entier de 1 à 100",
		"t party 3 : capacité inconnue ou en double « scratch »",
		"t party 4 : clé inconnue « shiny »",
		"t party 4 : « exp_to_next » est un entier de 1 à 44",
		"t bag : objet inconnu « master_ball »",
		"t bag « poke_ball » : quantité entière ≥ 1 attendue",
	]:
		assert_string_contains(errors, expected)
	assert_eq(start.party.size(), 0, "tout ou rien")
	assert_eq(start.map, &"")
	assert_push_error_count(12)


func test_hp_sets_the_starting_hp_bounded_by_the_max() -> void:
	var start := DebugStart.new()
	assert_true(start.add_from_dict({ "party": [
		{ "species": "charmander", "level": 8, "hp": 6 },
		{ "species": "rattata", "level": 5, "hp": 0 },
		{ "species": "pidgey", "level": 5, "hp": 999 },
		{ "species": "pidgey", "level": 5 },
	] }, _data, _items))
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	var members: Array = []
	for i: int in state.party.size():
		var pokemon: Pokemon = state.party.get_at(i)
		members.append([pokemon.hp, pokemon.max_hp()])
	assert_eq(members[0][0], 6)
	assert_eq(members[1][0], 0, "K.O.")
	assert_eq(members[2][0], members[2][1], "borné aux PV max")
	assert_eq(members[3][0], members[3][1], "sans « hp » : PV pleins")


func test_hp_must_be_a_non_negative_integer() -> void:
	var start := DebugStart.new()
	assert_false(start.add_from_dict({ "party": [{ "species": "pidgey", "level": 5, "hp": -1 }] },
		_data, _items, "t"))
	assert_string_contains("\n".join(start.get_errors()), "t party 1 : « hp » est un entier positif ou nul")
	assert_push_error_count(1)


func test_party_size_is_bounded() -> void:
	var start := DebugStart.new()
	assert_false(start.add_from_dict({ "party": [] }, _data, _items, "vide"))
	var seven: Array = []
	for i: int in 7:
		seven.append({ "species": "pidgey", "level": 3 })
	assert_false(start.add_from_dict({ "party": seven }, _data, _items, "sept"))
	assert_push_error_count(2)


# --- Application ----------------------------------------------------------------------------

func test_apply_builds_the_game_state() -> void:
	var start := DebugStart.new()
	start.load_file(FIXTURES + "valid.json", _data, _items)
	var state: Node = autofree(GameStateScript.new())
	state.flags.set_flag(&"old_flag")
	start.apply(state, _data)
	assert_eq(state.rng.get_seed(), 7)
	assert_false(state.flags.has_flag(&"old_flag"), "nouvelle partie")
	assert_true(state.flags.has_all([&"starter_chosen", &"rival_battle_done"]
		as Array[StringName]))
	assert_eq(state.party.size(), 2)
	var lead: Pokemon = state.party.get_lead()
	assert_eq([lead.species_id, lead.level], [&"bulbasaur", 19])
	var moves: Array[StringName] = []
	for slot: MoveSlot in lead.moves:
		moves.append(slot.move_id)
	assert_eq(moves, [&"tackle", &"growl", &"leech_seed", &"vine_whip"] as Array[StringName])
	assert_eq(lead.experience, 5460 - 1, "1 XP avant le N20")
	assert_eq(lead.hp, lead.max_hp())
	var second: Pokemon = state.party.get_at(1)
	assert_eq([second.species_id, second.level, second.experience], [&"pidgey", 3, 57])
	assert_eq(state.starter_species, &"bulbasaur")
	assert_true(state.pokedex.is_caught(&"bulbasaur"))
	assert_true(state.pokedex.is_caught(&"pidgey"))
	assert_eq(state.bag.count_of(&"poke_ball"), 5)


func test_same_fixture_same_party() -> void:
	var dumps: Array = []
	for i: int in 2:
		var start := DebugStart.new()
		start.load_file(FIXTURES + "valid.json", _data, _items)
		var state: Node = autofree(GameStateScript.new())
		start.apply(state, _data)
		dumps.append(state.party.to_array())
	assert_eq(dumps[0], dumps[1], "graine fixée : mêmes IV, même sexe")


func test_shipped_debug_starts_are_valid() -> void:
	# Les fichiers prêts à déposer sur le S24 (tools/debug_start/).
	var names: Array[String] = ["route_1", "learn_move", "forget_move", "capture_qa", "team_full"]
	for name: String in names:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		assert_eq(start.map, &"route_1", name)
		assert_true(start.flags.has(&"starter_chosen"), name)


## Jalon 7 (T2, jalon-07.md §5.5 ; T4 : à l'entrée sud de Jadielle, la micro-scène d'arrivée
## deux cases plus haut), prologue et rival du labo faits, équipe Nv. 7–8. Sans « money » ni « storage » :
## ces clés attendent la sauvegarde v3 (T0).
func test_shipped_viridian_start() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "viridian.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"viridian_city", &"from_route_1_w",
		Vector2i.UP])
	assert_true(start.flags.has(&"rival_battle_done"))
	assert_false(start.flags.has(&"pokedex_activated"), "jamais par un départ de débogage")
	for member: Dictionary in start.party:
		assert_between(int(member["level"]), 7, 8, str(member["species"]))
	assert_true(MapCatalog.has_map(start.map))
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	assert_true(map.has_spawn(start.spawn), "le point d'apparition existe sur la carte")
	map.free()


func test_shipped_forget_move_start_reaches_the_forget_offer() -> void:
	# forget_move.json : Bulbizarre N19 à 1 XP du N20, 4 capacités → oubli au premier K.O.
	var start := DebugStart.new()
	start.load_file(TOOL_STARTS + "forget_move.json", _data, _items)
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	var bulbasaur: Pokemon = state.party.get_lead()
	assert_eq(bulbasaur.moves.size(), 4)
	var steps := bulbasaur.gain_exp(1, _data)
	assert_eq(steps.size(), 1)
	assert_eq(steps[0].moves, [&"poison_powder"] as Array[StringName])
	assert_eq(bulbasaur.learn_move(&"poison_powder", _data), Pokemon.LearnResult.NEEDS_FORGET)


# --- Jalon 7 (T8) : argent et Stockage ---------------------------------------------------------

func test_money_and_storage_are_applied() -> void:
	var start := DebugStart.new()
	assert_true(start.add_from_dict({
		"party": [{ "species": "charmander", "level": 8 }],
		"money": 6000,
		"storage": [{ "species": "rattata", "level": 4 }, { "species": "spearow", "level": 3,
			"hp": 0 }],
	}, _data, _items), "\n".join(start.get_errors()))
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	assert_eq(state.money, 6000)
	assert_eq(state.party.size(), 1, "le Stockage n'entre pas dans l'équipe")
	assert_eq(state.storage.size(), 2)
	assert_eq(state.storage.get_at(0).species_id, &"rattata")
	assert_eq(state.storage.get_at(1).hp, 0, "même format que l'équipe (PV)")
	assert_true(state.pokedex.is_caught(&"spearow"), "capturé au Pokédex")


func test_without_money_the_new_game_sum_is_kept() -> void:
	var start := DebugStart.new()
	assert_true(start.add_from_dict({ "party": [{ "species": "pidgey", "level": 3 }] }, _data,
		_items))
	var state: Node = autofree(GameStateScript.new())
	state.money = 12
	start.apply(state, _data)
	assert_eq(state.money, GameStateScript.STARTING_MONEY)
	assert_eq(state.storage.size(), 0)


func test_money_and_storage_are_validated() -> void:
	var start := DebugStart.new()
	assert_false(start.add_from_dict({ "party": [{ "species": "pidgey", "level": 3 }],
		"money": -5, "storage": [{ "species": "missingno", "level": 3 }] }, _data, _items, "t"))
	var errors := "\n".join(start.get_errors())
	assert_string_contains(errors, "t : « money » est un entier de 0 à 999999")
	assert_string_contains(errors, "t storage 1 : espèce inconnue « missingno »")
	assert_false(start.add_from_dict({ "party": [{ "species": "pidgey", "level": 3 }],
		"money": 1_000_000, "storage": "rattata" }, _data, _items, "u"))
	assert_eq(DebugStart.MAX_MONEY, GameStateScript.MONEY_MAX)
	assert_push_error_count(4)


## Jalon 7 (T8, jalon-07.md §5.5) : équipe blessée et un K.O., devant la porte du Centre de
## Jadielle, arrivée déjà faite (pas de micro-scène), aucun Centre enregistré.
func test_shipped_center_qa_start() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "center_qa.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn], [&"viridian_city", &"from_center"])
	assert_true(start.flags.has(&"viridian_arrived"), "pas de micro-scène d'arrivée")
	assert_false(start.flags.has(&"pokedex_activated"))
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	var hurt := 0
	var fainted := 0
	for pokemon: Pokemon in state.party.get_all():
		if pokemon.hp == 0:
			fainted += 1
		elif pokemon.hp < pokemon.max_hp():
			hurt += 1
	assert_eq([hurt, fainted], [1, 1], "un blessé, un K.O.")
	assert_eq(state.heal_map, &"player_house_1f", "aucun Centre enregistré")
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	assert_true(map.has_spawn(start.spawn), "le point d'apparition existe sur la carte")
	map.free()


## Jalon 7 (T25, jalon-07.md §5.5) : `route_22` (Pokédex activé, équipe Nv. 7–8, entrée de la
## Route 22) et `rival_2_weak` (équipe Nv. 4 pour perdre, au pied de l'escalier) : la scène du
## rival se joue (drapeaux de la variante et paire `taken_*` qui choisit son Pokémon).
func test_shipped_route_22_starts() -> void:
	var rows: Array = [["route_22", &"from_viridian", 7, 8], ["rival_2_weak", &"stair_foot", 4, 4]]
	for row: Array in rows:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + row[0] + ".json", _data, _items),
			"%s : %s" % [row[0], "\n".join(start.get_errors())])
		assert_eq([start.map, start.spawn], [&"route_22", row[1]], row[0])
		for flag: StringName in [&"pokedex_activated", &"taken_charmander", &"taken_squirtle"]:
			assert_true(start.flags.has(flag), "%s : %s" % [row[0], flag])
		for flag: StringName in [&"rival_route22_won", &"rival_route22_lost"]:
			assert_false(start.flags.has(flag), "%s : rival pas encore affronté" % row[0])
		assert_eq(start.party[0]["species"], &"charmander", "%s : starter" % row[0])
		for member: Dictionary in start.party:
			assert_between(int(member["level"]), int(row[2]), int(row[3]), row[0])
		assert_eq(start.money, 3000, row[0])
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
				as GameMap
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition" % row[0])
		map.free()


## Jalon 8 (T4, jalon-08.md) : partie après l'activation du Pokédex, équipe Nv. 8–10, à
## l'entrée sud de la Route 2 (case du milieu, côté Jadielle), tournée vers le nord.
func test_shipped_route_2_start() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "route_2.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"route_2", &"from_viridian_c",
		Vector2i.UP])
	assert_true(start.flags.has(&"pokedex_activated"), "après l'activation du Pokédex")
	assert_true(start.flags.has(&"viridian_arrived"), "pas de micro-scène de Jadielle")
	for member: Dictionary in start.party:
		assert_between(int(member["level"]), 8, 10, str(member["species"]))
	for flag: StringName in start.flags:
		assert_false(String(flag).begins_with("got_route_2_"), "objets de la Route 2 à prendre")
		assert_false(String(flag).begins_with("route_2_"), "PNJ de la Route 2 jamais vus")
	assert_true(MapCatalog.has_map(start.map), "carte route_2 construite (jalon 8 T5)")
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	assert_true(map.has_spawn(start.spawn), "le point d'apparition existe sur la carte")
	map.free()


# --- Jalon 7 (T12) : favoris du Sac, départ shop_qa --------------------------------------------

func test_favorites_mark_bag_items() -> void:
	var start := DebugStart.new()
	assert_true(start.add_from_dict({
		"party": [{ "species": "charmander", "level": 8 }],
		"bag": { "potion": 4, "poke_ball": 2 }, "favorites": ["potion", "potion"],
	}, _data, _items), "\n".join(start.get_errors()))
	assert_eq(start.favorites, [&"potion"] as Array[StringName], "sans doublon")
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	assert_true(state.bag.is_favorite(&"potion"))
	assert_false(state.bag.is_favorite(&"poke_ball"))


func test_favorites_must_be_in_the_bag() -> void:
	var start := DebugStart.new()
	assert_false(start.add_from_dict({ "party": [{ "species": "pidgey", "level": 3 }],
		"bag": { "potion": 1 }, "favorites": ["poke_ball"] }, _data, _items, "t"))
	assert_string_contains("\n".join(start.get_errors()),
		"t favorites : « poke_ball » n'est pas un objet de « bag »")
	assert_false(start.add_from_dict({ "party": [{ "species": "pidgey", "level": 3 }],
		"favorites": "potion" }, _data, _items, "u"))
	assert_push_error_count(2)


## Jalon 7 (T12, jalon-07.md §5.5) : 6 000 ₽, des Potions favorites, devant la porte de la
## Boutique (spawn `from_mart`, tourné vers le sud), arrivée faite, colis pas encore reçu.
func test_shipped_shop_qa_start() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "shop_qa.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"viridian_city", &"from_mart",
		Vector2i.DOWN])
	assert_true(start.flags.has(&"viridian_arrived"), "pas de micro-scène d'arrivée")
	assert_false(start.flags.has(&"got_oak_parcel"), "la première visite reste à faire")
	assert_false(start.flags.has(&"pokedex_activated"))
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	assert_eq(state.money, 6000)
	assert_gt(state.bag.count_of(&"potion"), 1)
	assert_true(state.bag.is_favorite(&"potion"), "Potions favorites")
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	assert_true(map.has_spawn(start.spawn), "le point d'apparition existe sur la carte")
	map.free()


## Jalon 7 (T19, jalon-07.md §3.6.2) : `parcel` — colis en main, devant la porte du labo, rival du
## labo parti ; jamais `pokedex_activated` (seule la scène de Chen le lève).
func test_shipped_parcel_start() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "parcel.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn], [&"pallet_town", &"oak_lab_door"])
	for flag: StringName in [&"got_oak_parcel", &"rival_battle_done", &"rival_left_lab"]:
		assert_true(start.flags.has(flag), String(flag))
	assert_false(start.flags.has(&"pokedex_activated"), "jamais par un départ de débogage")
	assert_eq(start.bag.get(&"oak_parcel", 0), 1, "le colis est dans le Sac")
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	assert_true(map.has_spawn(start.spawn), "le point d'apparition existe sur la carte")
	map.free()


# --- Jalon 7 (T16) : favori d'un Pokémon, départ storage_qa -----------------------------------

func test_favorite_marks_a_member() -> void:
	var start := DebugStart.new()
	assert_true(start.add_from_dict({
		"party": [{ "species": "charmander", "level": 8, "favorite": true }],
		"storage": [{ "species": "rattata", "level": 4 },
			{ "species": "spearow", "level": 3, "favorite": true }],
	}, _data, _items), "\n".join(start.get_errors()))
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	assert_true(state.party.get_at(0).favorite)
	assert_false(state.storage.get_at(0).favorite, "faux par défaut")
	assert_true(state.storage.get_at(1).favorite)


func test_favorite_must_be_a_boolean() -> void:
	var start := DebugStart.new()
	assert_false(start.add_from_dict({
		"party": [{ "species": "charmander", "level": 8, "favorite": "oui" }] }, _data, _items,
		"f"))
	assert_string_contains("\n".join(start.get_errors()), "« favorite » est un booléen")
	assert_push_error_count(1)


## Jalon 7 (T16, jalon-07.md §5.5) : 6 en équipe dont un K.O., 10 au stockage dont un favori,
## dans le Centre, devant le terminal.
func test_shipped_storage_qa_start() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "storage_qa.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing], [&"viridian_center", &"terminal",
		Vector2i.UP])
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	assert_eq(state.party.size(), 6, "équipe pleine")
	assert_eq(state.storage.size(), 10)
	var fainted := 0
	for pokemon: Pokemon in state.party.get_all():
		if pokemon.is_fainted():
			fainted += 1
	assert_eq(fainted, 1, "un K.O. dans l'équipe")
	var favorites := 0
	for pokemon: Pokemon in state.storage.get_all():
		if pokemon.favorite:
			favorites += 1
	assert_eq(favorites, 1, "un favori au stockage")
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	assert_true(map.has_spawn(start.spawn), "le point d'apparition existe sur la carte")
	assert_true(MenuUnlocks.is_storage_map(start.map, _zones()), "dans un Centre")
	map.free()


func _zones() -> ZoneLibrary:
	var zones := ZoneLibrary.new()
	zones.load_file()
	return zones


# --- Jalon 9 (T2, sauvegarde v4) : statut d'un membre, autosave, départ save_v4_qa ------------

func test_status_marks_a_member() -> void:
	var start := DebugStart.new()
	assert_true(start.add_from_dict({
		"party": [{ "species": "charmander", "level": 9, "status": "poison" },
			{ "species": "pidgey", "level": 7, "status": "" }],
		"storage": [{ "species": "rattata", "level": 4, "status": "poison" },
			{ "species": "spearow", "level": 3 }],
	}, _data, _items), "\n".join(start.get_errors()))
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	assert_eq(state.party.get_at(0).status, StatusRules.POISON)
	assert_eq(state.party.get_at(1).status, StatusRules.NONE, "vide : aucun")
	assert_eq(state.storage.get_at(0).status, StatusRules.POISON, "stockage")
	assert_eq(state.storage.get_at(1).status, StatusRules.NONE, "absent : aucun")
	assert_string_contains(start.describe(), "charmander N9 (poison)")


func test_status_must_be_a_known_status() -> void:
	var start := DebugStart.new()
	assert_false(start.add_from_dict({ "party": [
		{ "species": "charmander", "level": 9, "status": "paralysis" },
		{ "species": "pidgey", "level": 7, "status": 3 },
	] }, _data, _items, "s"))
	var errors := "\n".join(start.get_errors())
	assert_string_contains(errors, "s party 1 : « status » est vide ou l'un de : poison")
	assert_string_contains(errors, "s party 2 : « status » est vide ou l'un de : poison")
	assert_eq(start.party.size(), 0, "tout ou rien")
	assert_push_error_count(2)


func test_autosave_is_off_by_default_and_must_be_a_boolean() -> void:
	var start := DebugStart.new()
	assert_true(start.add_from_dict({ "party": [{ "species": "pidgey", "level": 3 }] },
		_data, _items))
	assert_false(start.autosave, "un départ de débogage n'écrit jamais la sauvegarde")
	assert_true(start.add_from_dict({ "autosave": true,
		"party": [{ "species": "pidgey", "level": 3 }] }, _data, _items))
	assert_true(start.autosave)
	assert_string_contains(start.describe(), "remplace la sauvegarde")
	var bad := DebugStart.new()
	assert_false(bad.add_from_dict({ "autosave": "oui",
		"party": [{ "species": "pidgey", "level": 3 }] }, _data, _items, "a"))
	assert_string_contains("\n".join(bad.get_errors()), "a : « autosave » est un booléen")
	assert_push_error_count(1)


## Jalon 9 (T2, jalon-09.md §3 T2) : Salamèche N9 empoisonné, Roucool N7, à Jadielle devant le
## Centre ; il remplace la sauvegarde (QA T3 : statut relu après une fermeture forcée).
func test_shipped_save_v4_qa_start() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "save_v4_qa.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn], [&"viridian_city", &"from_center"])
	assert_true(start.autosave, "remplace la sauvegarde")
	assert_true(start.flags.has(&"viridian_arrived"), "pas de micro-scène d'arrivée")
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	var summary: Array = []
	for pokemon: Pokemon in state.party.get_all():
		summary.append([pokemon.species_id, pokemon.level, pokemon.status,
			pokemon.hp == pokemon.max_hp()])
	assert_eq(summary, [[&"charmander", 9, &"poison", true], [&"pidgey", 7, &"", true]])
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	assert_true(map.has_spawn(start.spawn), "le point d'apparition existe sur la carte")
	map.free()


# --- Jalon 9 (T6) : départs de la carte de QA ----------------------------------------------

func _load_qa_start(file_name: String) -> DebugStart:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + file_name + ".json", _data, _items),
		"%s : %s" % [file_name, "\n".join(start.get_errors())])
	assert_eq(start.map, &"qa_forest_systems", file_name)
	var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
	assert_true(map.has_spawn(start.spawn), "%s : le point d'apparition existe" % file_name)
	map.free()
	assert_false(start.autosave, "%s : ne touche jamais la sauvegarde" % file_name)
	assert_true(start.flags.has(&"viridian_arrived"), file_name)
	return start


func _party_summary(start: DebugStart) -> Array:
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	var summary: Array = []
	for pokemon: Pokemon in state.party.get_all():
		summary.append([pokemon.species_id, pokemon.level, pokemon.status])
	return summary


func test_shipped_poison_qa_start() -> void:
	var start := _load_qa_start("poison_qa")
	assert_eq([start.spawn, start.facing], [&"poison_start", Vector2i.UP])
	assert_true(start.flags.has(&"pokedex_activated"))
	assert_false(start.flags.has(&"poison_unlocked"), "c'est le garde qui le pose")
	assert_eq(start.money, 3000)
	assert_eq(_party_summary(start), [[&"charmander", 9, &"poison"], [&"pidgey", 7, &""]])
	assert_eq(start.bag.get(&"potion"), 2)
	assert_eq(start.bag.get(&"antidote"), 2, "2 Antidotes (objet du T4, ajouté à l'intégration)")


func test_shipped_evolution_qa_start() -> void:
	var start := _load_qa_start("evolution_qa")
	assert_eq([start.spawn, start.facing], [&"evolution_start", Vector2i.LEFT])
	assert_true(start.flags.has(&"poison_unlocked"), "le garde ne parle pas")
	assert_eq(_party_summary(start), [[&"charmander", 9, &""], [&"caterpie", 6, &""],
		[&"weedle", 6, &""], [&"metapod", 9, &""]])
	assert_eq(start.bag.get(&"potion"), 5)
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	for index: int in [1, 2, 3]:
		var pokemon: Pokemon = state.party.get_at(index)
		var rate := _data.get_species(pokemon.species_id).growth_rate
		assert_eq(ExpCurve.exp_for_level(rate, pokemon.level + 1) - pokemon.experience, 1,
			"%s à 1 XP du niveau suivant" % pokemon.species_id)


func test_shipped_trainers_qa_starts() -> void:
	var strong := _load_qa_start("trainers_qa")
	var weak := _load_qa_start("trainers_weak_qa")
	for start: DebugStart in [strong, weak]:
		assert_eq([start.spawn, start.facing], [&"theo_corridor", Vector2i.LEFT])
		assert_true(start.flags.has(&"poison_unlocked"))
		assert_eq(start.money, 3000)
	assert_eq(_party_summary(strong), [[&"charmander", 9, &""], [&"pidgey", 8, &""]])
	assert_eq(_party_summary(weak), [[&"charmander", 4, &""]], "Salamèche N4 seul : pour perdre")
	assert_eq(strong.bag.get(&"potion"), 5)
	assert_eq(strong.bag.get(&"antidote"), 1, "1 Antidote (objet du T4, ajouté à l'intégration)")
	assert_true(weak.bag.is_empty(), "sans Sac")
