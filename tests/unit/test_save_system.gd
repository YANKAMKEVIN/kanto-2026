extends GutTest
## SaveSystem (jalon 5 §16, 5C.5) : un seul emplacement, écriture atomique, format versionné,
## fichier corrompu mis de côté, système de fichiers injectable. Puis l'aller-retour complet
## GameState → fichier → GameState neuf.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save.json"
const FIXTURE_V1 := "res://tests/fixtures/save/v1_after_capture.json"
## Vraie partie de Kevin en v2 (S24, QA T1 du J6 : `build/qa/jalon06_t1/save_v2_apres_t0.json`,
## copiée telle quelle ; jalon-07.md §5.1).
const FIXTURE_V2 := "res://tests/fixtures/save/v2_kevin_j6.json"
## Vraie partie de Kevin en **fin de J6** (S24, relevée à l'étape 1 du T1 du J7 :
## `integ-j7/build/qa/jalon07_t1/save_v2_kevin.json`, copie exacte ; 13 h 57 de jeu).
const FIXTURE_V2_END := "res://tests/fixtures/save/v2_kevin_j6_fin.json"
## Vraie partie de Kevin en **fin de J7** (v3) : QA finale du J7 sur le S21, sans départ de
## débogage (`integ-j7/build/qa/jalon07_final_s21/save_final.json`, copie exacte) ; Centre de
## Jadielle (7, 5), 4 Pokémon, Pokédex activé, 2 100 ₽, 20 h 12 de jeu (jalon-09.md §2.2).
const FIXTURE_V3 := "res://tests/fixtures/save/v3_kevin_j7_fin.json"
const FIXTURE_V3_S24 := "res://tests/fixtures/save/v3_kevin_s24.json"

var _fs: SaveFileSystem
var _save: SaveSystem
var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-02T14:03:05")
	state.new_game(7)
	return state


## Un état bien rempli : équipe, Sac, Pokédex daté, drapeaux, position, journal.
func _full_state() -> Node:
	var state := _state()
	var charmander := PokemonFactory.create(_data, &"charmander", 5, GameRng.new(3))
	state.stamp_meeting(charmander, Pokemon.Origin.STARTER, &"oak_lab")
	state.party.add(charmander)
	state.starter_species = &"charmander"
	charmander.take_damage(4)
	charmander.moves[0].use()
	var pidgey := PokemonFactory.create(_data, &"pidgey", 3, GameRng.new(4))
	state.stamp_meeting(pidgey, Pokemon.Origin.CAPTURE, &"route_1")
	state.party.add(pidgey)
	state.bag.add(&"poke_ball", 4)
	state.bag.add(&"potion", 1)
	state.record_caught(&"charmander", &"oak_lab")
	state.record_seen(&"squirtle", &"oak_lab")
	state.record_seen(&"pidgey", &"route_1")
	state.record_seen(&"pidgey", &"route_1")
	state.record_caught(&"pidgey", &"route_1")
	state.flags.set_flag(&"starter_chosen")
	state.flags.set_flag(&"got_potion_route_1")
	state.set_player_location(&"route_1", Vector2i(23, 10), Vector2i.UP)
	state.heal_map = &"player_house_1f"
	state.add_play_time(125.5)
	state.discover_map(&"player_house_2f")
	state.discover_map(&"pallet_town")
	state.discover_map(&"route_1")
	state.record_item_found(&"potion", &"route_1")
	state.record_moment(state.MOMENT_STARTER, &"oak_lab", {"species": "charmander"})
	state.record_moment(state.MOMENT_RIVAL_BATTLE, &"oak_lab", {"outcome": "win"})
	state.rng.roll(100)
	return state


## Vraie sauvegarde v1 du jalon 5 (S24 de Kevin, QA T16 passage 1, après les captures de
## Roucool et Rattata ; starter « vu 0 fois » d'avant la correction Q-8).
func _fixture_v1() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V1))
	assert_true(parsed is Dictionary, "fixture v1 lisible")
	return parsed if parsed is Dictionary else {}


## Vraie partie de Kevin en v2 (voir [constant FIXTURE_V2]).
func _fixture_v2() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V2))
	assert_true(parsed is Dictionary, "fixture v2 lisible")
	return parsed if parsed is Dictionary else {}


## Passage par le JSON (entiers en flottants), pour comparer deux dictionnaires de sauvegarde.
func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


# --- Écriture ----------------------------------------------------------------------------

func test_no_save_at_first() -> void:
	assert_false(_save.has_save())
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_FILE_NOT_FOUND)
	assert_ne(_save.last_error, "")


func test_write_then_read_round_trip_and_stamps_the_version() -> void:
	assert_eq(_save.write({"player_name": "Kevin", "cell": [3, 4]}), OK)
	assert_true(_save.has_save())
	var content := _save.read()
	assert_eq(_save.last_status, OK)
	assert_eq(_save.last_error, "")
	assert_eq(int(content["version"]), SaveSystem.VERSION, "version à la racine")
	assert_eq(content["player_name"], "Kevin")
	assert_eq(content["cell"], [3.0, 4.0])


func test_write_is_atomic_temp_file_then_rename() -> void:
	assert_eq(_save.write({"a": 1}), OK)
	var journal: Array[String] = (_fs as MemoryFs).journal
	assert_eq(journal, ["write %s.tmp" % PATH, "rename %s.tmp -> %s" % [PATH, PATH]]
		as Array[String])
	assert_false(_fs.exists(PATH + ".tmp"), "pas de temporaire laissé derrière")
	assert_true(_fs.exists(PATH))


func test_failed_write_keeps_the_previous_save_intact() -> void:
	assert_eq(_save.write({"generation": 1}), OK)
	(_fs as MemoryFs).fail_writes = true
	assert_eq(_save.write({"generation": 2}), ERR_FILE_CANT_WRITE)
	assert_eq(_save.last_status, ERR_FILE_CANT_WRITE)
	assert_true(_save.last_error.contains("temporaire"))
	(_fs as MemoryFs).fail_writes = false
	assert_eq(_save.read()["generation"], 1.0, "l'ancienne sauvegarde est intacte")
	assert_false(_fs.exists(PATH + ".tmp"))


func test_interrupted_write_is_detected_and_keeps_the_previous_save() -> void:
	assert_eq(_save.write({"generation": 1}), OK)
	(_fs as MemoryFs).truncate_writes = true
	assert_eq(_save.write({"generation": 2}), ERR_FILE_CORRUPT, "relecture différente")
	(_fs as MemoryFs).truncate_writes = false
	assert_eq(_save.read()["generation"], 1.0)
	assert_false(_fs.exists(PATH + ".tmp"), "temporaire tronqué effacé")


func test_failed_rename_keeps_the_previous_save() -> void:
	assert_eq(_save.write({"generation": 1}), OK)
	(_fs as MemoryFs).fail_renames = true
	assert_eq(_save.write({"generation": 2}), ERR_CANT_OPEN)
	(_fs as MemoryFs).fail_renames = false
	assert_eq(_save.read()["generation"], 1.0)
	assert_false(_fs.exists(PATH + ".tmp"))


# --- Lecture : versions et corruption --------------------------------------------------------

func test_older_version_is_upgraded_and_accepted() -> void:
	(_fs as MemoryFs).files[PATH] = JSON.stringify({"version": 0, "player_name": "Kevin"})
	var content := _save.read()
	assert_eq(_save.last_status, OK)
	assert_eq(content["version"], SaveSystem.VERSION, "migrée à la version courante")
	assert_eq(content["player_name"], "Kevin", "le contenu est conservé")


func test_newer_version_is_refused_and_left_untouched() -> void:
	var text := JSON.stringify({"version": SaveSystem.VERSION + 1, "player_name": "Futur"})
	(_fs as MemoryFs).files[PATH] = text
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_INVALID_DATA)
	assert_true(_save.last_error.contains("plus récente"))
	assert_eq((_fs as MemoryFs).files[PATH], text, "fichier intact")
	assert_false(_fs.exists(PATH + ".corrupt"))


func test_a_v5_save_is_refused_and_left_untouched() -> void:
	# Jalon 9 : cette build écrit la v4 ; une v5 (build future) n'est jamais lue ni écrasée.
	var future: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V3))
	future["version"] = 5
	var text := JSON.stringify(future, "\t")
	(_fs as MemoryFs).files[PATH] = text
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_INVALID_DATA)
	assert_eq(_save.read_version, 0, "aucune lecture réussie")
	assert_true(_save.last_error.contains("5 > 4"), _save.last_error)
	assert_eq((_fs as MemoryFs).files[PATH], text, "fichier intact")
	assert_false(_fs.exists(PATH + ".corrupt"))


func test_the_current_save_is_refused_by_a_build_that_writes_v1() -> void:
	# Ce que fait un APK du jalon 5 (VERSION = 1) devant la sauvegarde du J9 : refus, intacte.
	assert_eq(_save.write(_full_state().to_dict()), OK)
	var written: String = (_fs as MemoryFs).files[PATH]
	assert_eq(int((JSON.parse_string(written) as Dictionary)["version"]), 4, "écrite en v4")
	var old_build := SaveSystem.new(_fs, PATH)
	old_build.version = 1
	assert_eq(old_build.read(), {})
	assert_eq(old_build.last_status, ERR_INVALID_DATA)
	assert_eq((_fs as MemoryFs).files[PATH], written, "fichier intact")
	assert_false(_fs.exists(PATH + ".corrupt"), "pas mis de côté comme corrompu")


func test_upgrade_is_idempotent_on_the_current_version() -> void:
	var content := {"version": SaveSystem.VERSION, "x": 1}
	assert_eq(SaveSystem.upgrade(content), OK)
	assert_eq(content, {"version": SaveSystem.VERSION, "x": 1})


func test_corrupt_json_is_quarantined_not_destroyed() -> void:
	var garbage := '{"version": 1, "player_name": "Kev'
	(_fs as MemoryFs).files[PATH] = garbage
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_FILE_CORRUPT)
	assert_true(_save.last_error.contains("illisible"))
	assert_false(_fs.exists(PATH), "plus de sauvegarde à l'emplacement")
	assert_eq((_fs as MemoryFs).files[PATH + ".corrupt"], garbage, "contenu gardé de côté")
	assert_false(_save.has_save())


func test_unreadable_or_non_object_file_is_corrupt() -> void:
	(_fs as MemoryFs).files[PATH] = ""
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_FILE_CORRUPT)
	(_fs as MemoryFs).files[PATH] = "[1, 2, 3]"
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_FILE_CORRUPT)
	(_fs as MemoryFs).files[PATH] = '{"player_name": "sans version"}'
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_FILE_CORRUPT, "sans version = corrompu")


func test_second_corrupt_file_replaces_the_first_quarantine() -> void:
	(_fs as MemoryFs).files[PATH] = "premier"
	_save.read()
	(_fs as MemoryFs).files[PATH] = "second"
	_save.read()
	assert_eq((_fs as MemoryFs).files[PATH + ".corrupt"], "second")


func test_erase_removes_the_save() -> void:
	assert_eq(_save.erase(), OK, "rien à effacer : OK")
	_save.write({"a": 1})
	assert_eq(_save.erase(), OK)
	assert_false(_save.has_save())


# --- Aller-retour complet de GameState -------------------------------------------------------

func test_full_game_state_round_trip() -> void:
	var original := _full_state()
	var before: Dictionary = original.to_dict()
	assert_eq(_save.write(before), OK)
	var loaded := _state()
	loaded.clock = FixedClock.new("2030-01-01T00:00:00")
	assert_true(loaded.load_dict(_save.read(), _data), "rien d'écarté")
	assert_eq(loaded.to_dict(), before, "même état après rechargement")
	# Quelques faits lus directement.
	assert_eq(loaded.player_name, "Kevin")
	assert_eq(loaded.started_at, "2026-10-02T14:03:05", "date de début conservée")
	assert_eq(loaded.play_time, 125.5)
	assert_eq(loaded.current_map, &"route_1")
	assert_eq(loaded.player_cell, Vector2i(23, 10))
	assert_eq(loaded.player_facing, Vector2i.UP)
	assert_eq(loaded.starter_species, &"charmander")
	assert_eq(loaded.party.size(), 2)
	assert_eq(loaded.party.get_lead().hp, original.party.get_lead().hp)
	assert_eq(loaded.party.get_lead().moves[0].pp, original.party.get_lead().moves[0].pp)
	assert_eq(loaded.party.get_lead().origin, Pokemon.Origin.STARTER)
	assert_eq(loaded.party.get_lead().met_map, &"oak_lab")
	assert_eq(loaded.party.get_at(1).origin, Pokemon.Origin.CAPTURE)
	assert_eq(loaded.bag.count_of(&"poke_ball"), 4)
	assert_true(loaded.pokedex.is_caught(&"pidgey"))
	assert_eq(loaded.pokedex.times_seen(&"pidgey"), 2)
	assert_true(loaded.flags.has_flag(&"got_potion_route_1"))
	assert_eq(loaded.discovered_maps.size(), 3)
	assert_eq(loaded.found_items[0]["item"], "potion")
	assert_eq(loaded.moments.size(), 2)
	assert_eq(loaded.moments[1]["details"], {"outcome": "win"})
	# L'aléatoire reprend exactement où il en était.
	assert_eq(loaded.rng.get_seed(), original.rng.get_seed())
	assert_eq(loaded.rng.roll(1000), original.rng.roll(1000), "mêmes tirages après reprise")


func test_loading_a_save_without_the_newer_fields_applies_defaults() -> void:
	# Une sauvegarde d'une build antérieure : seuls les champs du dossier-07 §13.
	var minimal := {
		"version": 0, "map": "pallet_town", "cell": [5, 6], "facing": [1, 0],
		"starter": "squirtle", "flags": ["starter_chosen"],
		"party": [PokemonFactory.create(_data, &"squirtle", 5, GameRng.new(1)).to_dict()],
	}
	(_fs as MemoryFs).files[PATH] = JSON.stringify(minimal)
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data))
	assert_eq(state.player_name, "Kevin", "nom par défaut")
	assert_eq(state.started_at, "2026-10-02T14:03:05", "début = maintenant par défaut")
	assert_eq(state.play_time, 0.0)
	assert_eq(state.heal_map, &"player_house_1f")
	assert_eq(state.heal_spawn, &"heal")
	assert_eq(state.current_map, &"pallet_town")
	assert_eq(state.player_cell, Vector2i(5, 6))
	assert_eq(state.player_facing, Vector2i.RIGHT)
	assert_eq(state.starter_species, &"squirtle")
	assert_eq(state.party.size(), 1)
	assert_eq(state.party.get_lead().origin, Pokemon.Origin.UNKNOWN, "rencontre inconnue")
	assert_true(state.bag.is_empty())
	assert_eq(state.pokedex.seen_count(), 0)
	assert_true(state.flags.has_flag(&"starter_chosen"))
	assert_eq(state.discovered_maps.size(), 0)
	assert_eq(state.found_items.size(), 0)
	assert_eq(state.moments.size(), 0)
	assert_true(state.rng is GameRng, "aléatoire neuf")


func test_unknown_fields_are_ignored() -> void:
	(_fs as MemoryFs).files[PATH] = JSON.stringify({
		"version": SaveSystem.VERSION, "badges": ["boulder"],
		"observations": {"pidgey": ["note"]}, "player_name": "Kevin",
	})
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data))
	assert_false(state.to_dict().has("badges"), "les inconnus ne sont pas réécrits")


func test_malformed_fields_fall_back_to_defaults_without_crashing() -> void:
	var state := _state()
	assert_true(state.load_dict({
		"player_name": 42, "started_at": null, "play_time": "beaucoup", "map": 7,
		"cell": [1], "facing": [0, 0], "heal_map": "", "starter": [], "party": "non",
		"bag": [], "pokedex": 3, "flags": {}, "rng": {"seed": "x"}, "discovered_maps": [],
		"found_items": {"item": "potion"}, "moments": [{"date": "sans type"}, "texte"],
	}, _data))
	assert_eq(state.player_name, "Kevin")
	assert_eq(state.play_time, 0.0)
	assert_eq(state.current_map, &"")
	assert_eq(state.player_cell, Vector2i.ZERO)
	assert_eq(state.player_facing, Vector2i.DOWN, "orientation nulle → bas")
	assert_eq(state.heal_map, &"player_house_1f")
	assert_eq(state.starter_species, &"")
	assert_eq(state.party.size(), 0)
	assert_true(state.bag.is_empty())
	assert_eq(state.pokedex.seen_count(), 0)
	assert_eq(state.flags.size(), 0)
	assert_eq(state.discovered_maps.size(), 0)
	assert_eq(state.found_items.size(), 0)
	assert_eq(state.moments.size(), 0)
	assert_push_error("graine ou état invalide")


func test_invalid_entries_are_discarded_and_reported() -> void:
	var state := _state()
	var dict: Dictionary = _full_state().to_dict()
	dict["party"].append({"species": "missingno"})
	dict["bag"]["items"]["poke_ball"] = "cinq"
	assert_false(state.load_dict(dict, _data), "une entrée écartée → faux")
	assert_eq(state.party.size(), 2, "les Pokémon valides sont gardés")
	assert_eq(state.bag.count_of(&"potion"), 1)
	assert_eq(state.bag.count_of(&"poke_ball"), 0)
	# Espèce inconnue (Pokemon), entrée d'équipe écartée (Party), entrée de Sac écartée (Bag).
	assert_push_error_count(3)


func test_storage_round_trip_through_the_save_file() -> void:
	# Jalon 5D : les Pokémon confiés au système de recherche de Chen sont sauvegardés.
	var original := _full_state()
	var rattata := PokemonFactory.create(_data, &"rattata", 3, GameRng.new(5))
	rattata.take_damage(2)
	original.stamp_meeting(rattata, Pokemon.Origin.CAPTURE, &"route_1")
	original.storage.add(rattata)
	assert_eq(_save.write(original.to_dict()), OK)
	var loaded := _state()
	assert_true(loaded.load_dict(_save.read(), _data))
	assert_eq(loaded.storage.size(), 1)
	var stored: Pokemon = loaded.storage.get_all()[0]
	assert_eq([stored.species_id, stored.level, stored.hp], [&"rattata", 3, rattata.hp])
	assert_eq(stored.origin, Pokemon.Origin.CAPTURE)
	assert_eq(loaded.to_dict(), original.to_dict(), "même état après rechargement")


func test_old_save_without_storage_loads_an_empty_storage() -> void:
	var state := _state()
	state.storage.add(PokemonFactory.create(_data, &"pidgey", 3, GameRng.new(1)))
	var dict: Dictionary = _full_state().to_dict()
	dict.erase("storage")
	assert_true(state.load_dict(dict, _data), "rien d'écarté")
	assert_true(state.storage.is_empty(), "stockage vide par défaut")
	assert_eq(state.party.size(), 2)


func test_invalid_storage_entries_are_discarded() -> void:
	var state := _state()
	var dict: Dictionary = _full_state().to_dict()
	dict["storage"] = [PokemonFactory.create(_data, &"pidgey", 3, GameRng.new(1)).to_dict(),
		{"species": "missingno"}]
	assert_false(state.load_dict(dict, _data), "une entrée écartée → faux")
	assert_eq(state.storage.size(), 1, "le Pokémon valide est gardé")
	assert_push_error_count(2, "espèce inconnue (Pokemon), entrée écartée (PokemonStorage)")


# --- Version 2 (jalon 6, T0 : jalon-06.md §5.1) ---------------------------------------------

func test_the_real_v1_save_is_migrated_to_the_current_version_on_read() -> void:
	# 1 → 2 → 3 → 4 enchaînées (jalons 6, 7 et 9).
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V1)
	var content := _save.read()
	assert_eq(_save.last_status, OK)
	assert_eq(int(content["version"]), 4, "migrée en v4")
	assert_eq(_save.read_version, 1, "lue en v1")
	assert_eq(content["money"], 3000)
	assert_eq(content["first_wild_encounter"], {"species": "pidgey", "map": "route_1",
		"date": "2026-10-02T19:10:43"}, "Roucool, vu d'abord sur la Route 1")
	assert_eq(_json(content["bag"]), _json({"items": {"poke_ball": 3, "potion": 1},
		"favorites": [], "acquired": {"poke_ball": 1, "potion": 2}}), "Sac v2")
	for member: Dictionary in content["party"]:
		assert_eq(member.get("favorite"), false, "favori posé à faux")
	var entries: Dictionary = content["pokedex"]["entries"]
	for species: String in entries:
		assert_eq(entries[species].get("notes"), [], "notes vides : %s" % species)
	assert_eq(int(entries["charmander"]["times_seen"]), 0,
		"la migration ne touche pas times_seen (corrigé au chargement, une seule règle)")


func test_the_real_v1_save_loads_identically_after_migration() -> void:
	var v1 := _fixture_v1()
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V1)
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data), "rien d'écarté")
	# Lu directement : la partie de Kevin.
	assert_eq(state.current_map, &"route_1")
	assert_eq(state.player_cell, Vector2i(30, 32))
	assert_eq(state.player_facing, Vector2i.RIGHT)
	assert_eq(state.party.size(), 3)
	var summary: Array = []
	for pokemon: Pokemon in state.party.get_all():
		summary.append([pokemon.species_id, pokemon.level, pokemon.hp, pokemon.experience,
			pokemon.favorite])
	assert_eq(summary, [[&"charmander", 5, 4, 163, false], [&"pidgey", 4, 1, 96, false],
		[&"rattata", 4, 17, 64, false]], "équipe, ordre, PV, XP")
	assert_eq(state.bag.count_of(&"poke_ball"), 3)
	assert_eq(state.bag.count_of(&"potion"), 1)
	assert_eq(state.bag.favorite_ids(), [] as Array[StringName])
	assert_eq(state.pokedex.seen_count(), 4)
	assert_eq(state.pokedex.caught_count(), 3)
	assert_eq(state.pokedex.times_seen(&"charmander"), 1, "starter : vu une fois (Q-8)")
	assert_eq(state.pokedex.get_entry(&"charmander").first_seen_date, "2026-10-02T19:07:52")
	assert_eq(state.pokedex.times_seen(&"pidgey"), 2)
	assert_eq(state.pokedex.times_seen(&"rattata"), 4)
	assert_eq(state.moments.size(), 3)
	assert_eq(state.play_time, 1616.63664866551, "temps de jeu")
	# Tout ce que la v2 ne change pas est réécrit à l'identique.
	var after: Dictionary = _json(state.to_dict())
	var before: Dictionary = _json(v1)
	for key: String in before:
		if key not in ["version", "bag", "party", "pokedex"]:
			assert_eq(after.get(key), before[key], "champ « %s » identique" % key)
	var party: Array = before["party"]
	for i: int in party.size():
		var expected: Dictionary = party[i].duplicate(true)
		expected["favorite"] = false
		expected["status"] = ""
		assert_eq(after["party"][i], expected,
			"Pokémon %d identique, favori (v2) et statut vide (v4) en plus" % i)
	var dex: Dictionary = before["pokedex"]["entries"].duplicate(true)
	for species: String in dex:
		dex[species]["notes"] = []
	dex["charmander"]["times_seen"] = 1.0
	assert_eq(after["pokedex"]["entries"], dex, "Pokédex identique, notes en plus, starter vu 1")
	assert_eq(after.keys().size(), before.keys().size() + 1,
		"aucun champ perdu (sauf version), argent et première rencontre en plus")


func test_a_migrated_v1_save_is_rewritten_in_v4_and_reads_back_identically() -> void:
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V1)
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data))
	var dict: Dictionary = state.to_dict()
	assert_eq(_save.write(dict), OK)
	var written: Dictionary = JSON.parse_string((_fs as MemoryFs).files[PATH])
	assert_eq(int(written["version"]), 4)
	assert_true((written["bag"] as Dictionary).has("items"), "Sac écrit en v2")
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data))
	assert_eq(again.to_dict(), dict, "aller-retour stable")


func test_v2_round_trip_keeps_favorites_and_notes() -> void:
	var original := _full_state()
	original.bag.set_favorite(&"potion", true)
	original.party.get_at(1).favorite = true
	original.pokedex.get_entry(&"pidgey").notes.append(&"pidgey_paths")
	var rattata := PokemonFactory.create(_data, &"rattata", 3, GameRng.new(5))
	rattata.favorite = true
	original.storage.add(rattata)
	var before: Dictionary = original.to_dict()
	assert_eq(_save.write(before), OK)
	var loaded := _state()
	assert_true(loaded.load_dict(_save.read(), _data), "rien d'écarté")
	assert_eq(loaded.to_dict(), before, "même état après rechargement")
	assert_true(loaded.bag.is_favorite(&"potion"))
	assert_gt(loaded.bag.acquired_rank(&"potion"), loaded.bag.acquired_rank(&"poke_ball"),
		"ordre d'obtention gardé")
	assert_false(loaded.party.get_lead().favorite)
	assert_true(loaded.party.get_at(1).favorite)
	assert_true(loaded.storage.get_all()[0].favorite, "favori du stockage")
	assert_eq(loaded.pokedex.get_entry(&"pidgey").notes, [&"pidgey_paths"] as Array[StringName])


func test_upgrade_1_to_2_leaves_v2_shapes_and_malformed_fields_alone() -> void:
	var content := {"version": 1, "bag": {"items": {"potion": 2}, "favorites": ["potion"],
		"acquired": {"potion": 4}}, "party": [{"species": "pidgey", "favorite": true}, 7]}
	assert_eq(SaveSystem.upgrade(content, 2), OK)
	assert_eq(content["bag"], {"items": {"potion": 2}, "favorites": ["potion"],
		"acquired": {"potion": 4}}, "Sac déjà en v2 : intact")
	assert_eq(content["party"], [{"species": "pidgey", "favorite": true}, 7])
	var odd := {"version": 1, "bag": 3, "party": "x", "storage": null,
		"pokedex": {"entries": []}}
	assert_eq(SaveSystem.upgrade(odd, 2), OK, "rien ne plante")
	assert_eq(odd["bag"], 3, "mal formé : laissé aux chargeurs tolérants")
	assert_eq(odd["version"], 2)
	var bare := {"version": 1}
	assert_eq(SaveSystem.upgrade(bare, 2), OK)
	assert_eq(bare, {"version": 2}, "aucun champ inventé")


# --- Version 3 (jalon 7, T0 : jalon-07.md §5.1) ---------------------------------------------

## Le contenu d'une sauvegarde sans ce que la v3 et la v4 ajoutent (pour comparer à la v2).
func _without_v3(content: Dictionary) -> Dictionary:
	var copy := _without_v4(content)
	for key: String in ["money", "first_wild_encounter"]:
		copy.erase(key)
	return copy


## Le contenu d'une sauvegarde sans ce que la v4 ajoute (pour comparer à la v3) : la version et
## le statut (« status ») de chaque Pokémon de l'équipe et du stockage.
func _without_v4(content: Dictionary) -> Dictionary:
	var copy: Dictionary = _json(content)
	copy.erase("version")
	for key: String in ["party", "storage"]:
		for member: Variant in JsonFields.get_array(copy, key):
			if member is Dictionary:
				(member as Dictionary).erase("status")
	return copy


func test_the_real_v2_save_is_migrated_to_the_current_version_on_read() -> void:
	var v2 := _fixture_v2()
	assert_eq(int(v2["version"]), 2, "la fixture est bien une v2")
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V2)
	var content := _save.read()
	assert_eq(_save.last_status, OK, _save.last_error)
	assert_eq(int(content["version"]), 4, "migrée en v4")
	assert_eq(content["money"], 3000, "3 000 ₽ (dossier 09 §17)")
	assert_eq(content["first_wild_encounter"], {"species": "pidgey", "map": "route_1",
		"date": "2026-10-02T20:51:16"}, "Roucool : première espèce vue sur la Route 1")
	assert_eq(_without_v3(content), _without_v3(v2), "rien d'autre ne change")


func test_the_real_v2_save_loads_and_is_rewritten_identically_in_v4() -> void:
	var v2 := _fixture_v2()
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V2)
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data), "rien d'écarté")
	# La partie de Kevin, lue directement.
	assert_eq(state.current_map, &"route_1")
	assert_eq(state.player_cell, Vector2i(24, 2))
	assert_eq(state.player_facing, Vector2i.DOWN)
	var summary: Array = []
	for pokemon: Pokemon in state.party.get_all():
		summary.append([pokemon.species_id, pokemon.level, pokemon.hp, pokemon.experience])
	assert_eq(summary, [[&"charmander", 6, 21, 219], [&"pidgey", 3, 16, 92],
		[&"rattata", 3, 15, 27]], "équipe, ordre, Nv., PV, XP")
	assert_eq(state.bag.count_of(&"poke_ball"), 2)
	assert_eq(state.bag.count_of(&"potion"), 1)
	assert_eq(state.money, 3000)
	assert_eq(state.first_wild_species(), &"pidgey")
	assert_eq(state.play_time, 3732.01731968654)
	# Réécrite : tout ce que la v2 avait, à l'identique, plus les deux champs de la v3 et le
	# statut (vide) de la v4.
	assert_eq(_save.write(state.to_dict()), OK)
	var written: Dictionary = JSON.parse_string((_fs as MemoryFs).files[PATH])
	assert_eq(int(written["version"]), 4)
	assert_eq(written["money"], 3000.0)
	assert_eq(written["first_wild_encounter"]["species"], "pidgey")
	assert_eq(_without_v3(written), _without_v3(v2), "tout le reste réécrit à l'identique")
	assert_eq(written.keys().size(), v2.keys().size() + 2, "aucun champ perdu")
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data))
	assert_eq(again.to_dict(), state.to_dict(), "aller-retour v4 stable")


## T1 du J7 : la vraie partie de fin de J6 (Potion favorite à 0, notes, OBSERVER faits).
func test_the_real_end_of_j6_save_migrates_to_v4_and_rewrites_identically() -> void:
	var text := FileAccess.get_file_as_string(FIXTURE_V2_END)
	var v2: Dictionary = JSON.parse_string(text)
	assert_eq(int(v2["version"]), 2, "la fixture est bien une v2")
	(_fs as MemoryFs).files[PATH] = text
	var content := _save.read()
	assert_eq(_save.last_status, OK, _save.last_error)
	assert_eq(int(content["version"]), 4)
	assert_eq(content["money"], 3000)
	assert_eq(content["first_wild_encounter"], {"species": "pidgey", "map": "route_1",
		"date": "2026-10-02T20:51:16"}, "Roucool : première espèce vue sur la Route 1")
	assert_eq(_without_v3(content), _without_v3(v2), "rien d'autre ne change")
	var state := _state()
	assert_true(state.load_dict(content, _data), "rien d'écarté")
	assert_eq(state.current_map, &"route_1")
	assert_eq(state.player_cell, Vector2i(24, 8))
	assert_eq(state.player_facing, Vector2i.RIGHT)
	assert_eq(state.party.get_lead().species_id, &"rattata")
	assert_true(state.party.get_at(2).favorite, "Roucool favori")
	assert_eq(state.bag.count_of(&"potion"), 0)
	assert_true(state.bag.is_favorite(&"potion"), "favori gardé à 0")
	assert_eq(state.money, 3000)
	assert_eq(_save.write(state.to_dict()), OK)
	var written: Dictionary = JSON.parse_string((_fs as MemoryFs).files[PATH])
	assert_eq(int(written["version"]), 4)
	assert_eq(_without_v3(written), _without_v3(v2), "tout le reste réécrit à l'identique")
	assert_eq(written.keys().size(), v2.keys().size() + 2, "aucun champ perdu")


func test_v3_round_trip_keeps_money_and_the_first_wild_encounter() -> void:
	var original := _full_state()
	assert_true(original.spend_money(2900))
	original.add_money(12_345)
	assert_true(original.record_wild_encounter(&"rattata", &"route_22"))
	var before: Dictionary = original.to_dict()
	assert_eq(_save.write(before), OK)
	var loaded := _state()
	assert_true(loaded.load_dict(_save.read(), _data), "rien d'écarté")
	assert_eq(loaded.to_dict(), before, "même état après rechargement")
	assert_eq(loaded.money, 12_445)
	assert_eq(loaded.first_wild_encounter, {"species": "rattata", "map": "route_22",
		"date": "2026-10-02T14:03:05"})


func test_the_current_save_is_refused_by_a_j6_build_and_left_untouched() -> void:
	# Ce que fait l'APK du jalon 6 (VERSION = 2) devant la sauvegarde du J9 : refus, intacte,
	# pas mise de côté comme corrompue (le J6 ne la lit jamais, donc ne l'écrase jamais).
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V2)
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data))
	assert_eq(_save.write(state.to_dict()), OK)
	var written: String = (_fs as MemoryFs).files[PATH]
	(_fs as MemoryFs).journal.clear()
	var j6_build := SaveSystem.new(_fs, PATH)
	j6_build.version = 2
	assert_eq(j6_build.read(), {})
	assert_eq(j6_build.last_status, ERR_INVALID_DATA)
	assert_true(j6_build.last_error.contains("4 > 2"), j6_build.last_error)
	assert_eq((_fs as MemoryFs).files[PATH], written, "fichier intact")
	assert_eq((_fs as MemoryFs).journal.size(), 0, "aucune écriture, aucun renommage")
	assert_false(_fs.exists(PATH + ".corrupt"))


func test_upgrade_2_to_3_adds_only_money_and_the_first_wild_encounter() -> void:
	var bare := {"version": 2}
	assert_eq(SaveSystem.upgrade(bare, 3), OK)
	assert_eq(bare, {"version": 3, "money": 3000, "first_wild_encounter": {}},
		"aucune rencontre connue : vide (Chen omet sa réplique)")
	var kept := {"version": 2, "money": 42, "first_wild_encounter": {"species": "rattata"}}
	assert_eq(SaveSystem.upgrade(kept), OK)
	assert_eq(kept["money"], 42, "un champ déjà là n'est pas remplacé")
	assert_eq(kept["first_wild_encounter"], {"species": "rattata"})
	var odd := {"version": 2, "pokedex": "x", "party": [3, {"met": 4}], "moments": {"a": 1},
		"storage": null}
	assert_eq(SaveSystem.upgrade(odd), OK, "rien ne plante")
	assert_eq(odd["first_wild_encounter"], {})
	assert_eq(odd["pokedex"], "x", "mal formé : laissé aux chargeurs tolérants")


# --- Version 4 (jalon 9, T2 : jalon-09.md §2.2) : statut des Pokémon -------------------------

func _fixture_v3() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V3))
	assert_true(parsed is Dictionary, "fixture v3 lisible")
	return parsed if parsed is Dictionary else {}


func test_upgrade_3_to_4_changes_nothing_but_the_version() -> void:
	var bare := {"version": 3}
	assert_eq(SaveSystem.upgrade(bare), OK)
	assert_eq(bare, {"version": 4}, "aucun champ inventé")
	var content := {"version": 3, "party": [{"species": "pidgey"}, 7], "storage": "x"}
	assert_eq(SaveSystem.upgrade(content), OK)
	assert_eq(content, {"version": 4, "party": [{"species": "pidgey"}, 7], "storage": "x"},
		"aucun « status » ajouté : absent = aucun statut (Pokemon.from_dict)")


func test_migration_note() -> void:
	assert_eq(SaveSystem.migration_note(3, 4), "sauvegarde v3 → v4")
	assert_eq(SaveSystem.migration_note(1, 4), "sauvegarde v1 → v4")
	assert_eq(SaveSystem.migration_note(4, 4), "", "déjà à jour : rien")


func test_the_real_v3_save_is_migrated_to_v4_on_read_without_any_change() -> void:
	var v3 := _fixture_v3()
	assert_eq(int(v3["version"]), 3, "la fixture est bien une v3")
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V3)
	var content := _save.read()
	assert_eq(_save.last_status, OK, _save.last_error)
	assert_eq(int(content["version"]), 4, "migrée en v4")
	assert_eq(_save.read_version, 3, "lue en v3 : le journal note la migration")
	assert_eq(_without_v4(content), _without_v4(v3), "rien d'autre ne change")
	assert_false((_fs as MemoryFs).files.has(PATH + SaveSystem.CORRUPT_SUFFIX))


func test_the_s24_v3_save_of_kevin_is_migrated_to_v4_and_loads_with_no_status() -> void:
	# Partie relevée sur le S24 par le T3 (route_2, J8) : mêmes garanties que la fixture du J7.
	var text := FileAccess.get_file_as_string(FIXTURE_V3_S24)
	var v3: Variant = JSON.parse_string(text)
	assert_true(v3 is Dictionary, "fixture S24 lisible")
	assert_eq(int((v3 as Dictionary)["version"]), 3)
	(_fs as MemoryFs).files[PATH] = text
	var content := _save.read()
	assert_eq(_save.last_status, OK, _save.last_error)
	assert_eq(int(content["version"]), 4)
	assert_eq(_save.read_version, 3)
	assert_eq(_without_v4(content), _without_v4(v3 as Dictionary), "rien d'autre ne change")
	var state := _state()
	assert_true(state.load_dict(content, _data), "rien d'écarté")
	assert_eq(state.party.get_all().size(), (v3 as Dictionary)["party"].size())
	for pokemon: Pokemon in state.party.get_all():
		assert_eq(pokemon.status, &"", "aucun statut")


func test_the_real_v3_save_loads_with_no_status_and_is_rewritten_identically_in_v4() -> void:
	var v3 := _fixture_v3()
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V3)
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data), "rien d'écarté")
	# La partie de Kevin (fin du J7), lue directement.
	assert_eq(state.current_map, &"viridian_center")
	assert_eq(state.player_cell, Vector2i(7, 5))
	assert_eq(state.player_facing, Vector2i.UP)
	var summary: Array = []
	for pokemon: Pokemon in state.party.get_all():
		summary.append([pokemon.species_id, pokemon.level, pokemon.hp, pokemon.experience,
			pokemon.status])
	assert_eq(summary, [[&"charmander", 8, 25, 336, &""], [&"pidgey", 3, 16, 92, &""],
		[&"rattata", 3, 15, 62, &""], [&"nidoran_m", 3, 16, 57, &""]],
		"équipe, ordre, Nv., PV, XP ; aucun statut")
	assert_eq(state.money, 2100)
	assert_true(state.flags.has_flag(&"pokedex_activated"))
	assert_eq(state.pokedex.seen_count(), 5)
	assert_eq(state.heal_map, &"viridian_center", "point de repos : le Centre")
	assert_eq(state.first_wild_species(), &"pidgey")
	assert_eq(state.play_time, float(v3["play_time"]), "temps de jeu")
	# Réécrite : tout ce que la v3 avait, à l'identique, plus « status » vide sur chaque Pokémon.
	assert_eq(_save.write(state.to_dict()), OK)
	var written: Dictionary = JSON.parse_string((_fs as MemoryFs).files[PATH])
	assert_eq(int(written["version"]), 4)
	for member: Dictionary in written["party"]:
		assert_eq(member.get("status"), "", "statut écrit vide")
	assert_eq(_without_v4(written), _without_v4(v3), "tout le reste réécrit à l'identique")
	assert_eq(written.keys().size(), v3.keys().size(), "aucun champ perdu ni ajouté")
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data))
	assert_eq(_save.read_version, 4, "relue en v4 : plus de migration")
	assert_eq(again.to_dict(), state.to_dict(), "aller-retour v4 stable")


func test_v4_round_trip_keeps_poisoned_party_and_storage_members() -> void:
	var original := _full_state()
	original.party.get_lead().status = StatusRules.POISON
	var rattata := PokemonFactory.create(_data, &"rattata", 3, GameRng.new(5))
	rattata.status = StatusRules.POISON
	original.storage.add(rattata)
	var before: Dictionary = original.to_dict()
	assert_eq(_save.write(before), OK)
	var text: String = (_fs as MemoryFs).files[PATH]
	assert_string_contains(text, '"status": "poison"')
	var loaded := _state()
	assert_true(loaded.load_dict(_save.read(), _data), "rien d'écarté")
	assert_eq(loaded.to_dict(), before, "même état après rechargement")
	assert_eq(loaded.party.get_lead().status, StatusRules.POISON, "équipe")
	assert_eq(loaded.party.get_at(1).status, StatusRules.NONE)
	assert_eq(loaded.storage.get_at(0).status, StatusRules.POISON, "stockage")
	# Relue puis réécrite : identique octet pour octet.
	assert_eq(_save.write(loaded.to_dict()), OK)
	assert_eq((_fs as MemoryFs).files[PATH], text, "réécriture identique")


func test_a_v4_save_is_refused_by_a_j7_build_and_left_untouched() -> void:
	# Ce que fait l'APK du jalon 7 / 8 (VERSION = 3) devant la sauvegarde du J9 : refus, intacte,
	# pas mise de côté comme corrompue ; il ne la lit jamais, donc n'efface jamais un statut.
	(_fs as MemoryFs).files[PATH] = FileAccess.get_file_as_string(FIXTURE_V3)
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data))
	state.party.get_lead().status = StatusRules.POISON
	assert_eq(_save.write(state.to_dict()), OK)
	var written: String = (_fs as MemoryFs).files[PATH]
	(_fs as MemoryFs).journal.clear()
	var j7_build := SaveSystem.new(_fs, PATH)
	j7_build.version = 3
	assert_eq(j7_build.read(), {})
	assert_eq(j7_build.last_status, ERR_INVALID_DATA)
	assert_true(j7_build.last_error.contains("4 > 3"), j7_build.last_error)
	assert_eq((_fs as MemoryFs).files[PATH], written, "fichier intact")
	assert_eq((_fs as MemoryFs).journal.size(), 0, "aucune écriture, aucun renommage")
	assert_false(_fs.exists(PATH + SaveSystem.CORRUPT_SUFFIX))


func test_a_v4_save_with_an_unknown_status_loads_without_it() -> void:
	# Fichier retouché ou statut d'une build future en v4 : le Pokémon est gardé, sans statut.
	var dict: Dictionary = _full_state().to_dict()
	dict["party"][0]["status"] = "paralysis"
	assert_eq(_save.write(dict), OK)
	var loaded := _state()
	assert_true(loaded.load_dict(_save.read(), _data), "rien d'écarté")
	assert_eq(loaded.party.size(), 2)
	assert_eq(loaded.party.get_lead().status, StatusRules.NONE)
	assert_push_warning_count(1)
	assert_push_error_count(0)


# --- Rattrapage de la première espèce sauvage (§5.1) -----------------------------------------

## Entrée du Pokédex (forme v2) : première observation, capture éventuelle, cartes vues.
func _entry(seen_map: String, seen_date: String, caught_map: String = "",
		caught_date: String = "", seen_maps: Array = []) -> Dictionary:
	return {
		"caught": not caught_map.is_empty(), "first_seen_map": seen_map,
		"first_seen_date": seen_date, "first_caught_map": caught_map,
		"first_caught_date": caught_date,
		"seen_maps": seen_maps if not seen_maps.is_empty() else [seen_map],
	}


func _recover(entries: Dictionary, extra: Dictionary = {}, from_v1: bool = false) -> Dictionary:
	var content := {"pokedex": {"entries": entries}}
	content.merge(extra)
	return SaveSystem.recover_first_wild_encounter(content, from_v1)


func test_recovery_takes_the_earliest_first_sighting_on_route_1() -> void:
	var found := _recover({
		"charmander": _entry("oak_lab", "2026-10-02T10:00:00", "oak_lab", "2026-10-02T10:00:00"),
		"squirtle": _entry("oak_lab", "2026-10-02T10:01:00"),
		"rattata": _entry("route_1", "2026-10-02T10:20:00"),
		"pidgey": _entry("route_1", "2026-10-02T10:10:00", "route_1", "2026-10-02T10:30:00"),
	})
	assert_eq(found, {"species": "pidgey", "map": "route_1", "date": "2026-10-02T10:10:00"},
		"le starter et le Pokémon du rival (labo) ne comptent jamais")


func test_recovery_ignores_an_observation_in_pallet_town_for_a_v2_save() -> void:
	# J6 : OBSERVER marque « vu » le Roucool d'un habitant à Bourg Palette. Ce n'est pas un
	# combat ; Rattata, vu plus tard sur la Route 1, l'emporte.
	var found := _recover({
		"pidgey": _entry("pallet_town", "2026-10-02T10:05:00"),
		"rattata": _entry("route_1", "2026-10-02T10:20:00"),
	})
	assert_eq(found["species"], "rattata")


func test_recovery_counts_pallet_town_sightings_for_a_save_written_before_observe() -> void:
	# Une v1 (J5, sans OBSERVER) : « vu » à Bourg Palette = un combat dans son herbe.
	var entries := {
		"pidgey": _entry("pallet_town", "2026-10-02T10:05:00"),
		"rattata": _entry("route_1", "2026-10-02T10:20:00"),
	}
	assert_eq(_recover(entries, {}, true)["species"], "pidgey")
	var content := {"version": 1, "pokedex": {"entries": entries}}
	assert_eq(SaveSystem.upgrade(content), OK)
	assert_eq(content["first_wild_encounter"]["species"], "pidgey", "upgrade le sait seul")


func test_recovery_uses_a_wild_capture_date_as_an_upper_bound() -> void:
	# Roucool observé à Bourg Palette, puis combattu et capturé sur la Route 1 avant toute
	# autre rencontre : seule sa capture est datée sur une carte sauvage.
	var found := _recover({
		"pidgey": _entry("pallet_town", "2026-10-02T10:05:00", "route_1", "2026-10-02T10:12:00",
			["pallet_town", "route_1"]),
		"rattata": _entry("route_1", "2026-10-02T10:20:00"),
	})
	assert_eq(found, {"species": "pidgey", "map": "route_1", "date": "2026-10-02T10:12:00"})


func test_recovery_falls_back_on_meetings_and_moments_without_a_pokedex() -> void:
	var content := {
		"party": [{"species": "charmander", "met": {"origin": "starter", "map": "oak_lab",
			"date": "2026-10-02T09:00:00"}},
			{"species": "rattata", "met": {"origin": "capture", "map": "route_1",
			"date": "2026-10-02T10:40:00"}}],
		"storage": [{"species": "pidgey", "met": {"origin": "capture", "map": "pallet_town",
			"date": "2026-10-02T10:30:00"}}],
		"moments": [{"type": "first_capture", "map": "route_1", "date": "2026-10-02T10:35:00",
			"details": {"species": "rattata"}}],
	}
	assert_eq(SaveSystem.recover_first_wild_encounter(content), {"species": "pidgey",
		"map": "pallet_town", "date": "2026-10-02T10:30:00"})


func test_recovery_without_dates_needs_a_single_species_fought_on_route_1() -> void:
	var one := _recover({
		"pidgey": _entry("pallet_town", "", "", "", ["pallet_town", "route_1"]),
		"rattata": _entry("pallet_town", "2026-10-02T10:05:00"),
	})
	assert_eq(one, {"species": "pidgey", "map": "route_1", "date": ""},
		"seul Roucool a été vu sur la Route 1")
	var two := _recover({
		"pidgey": _entry("pallet_town", "2026-10-02T10:01:00", "", "", ["pallet_town", "route_1"]),
		"rattata": _entry("pallet_town", "2026-10-02T10:02:00", "", "", ["pallet_town", "route_1"]),
	})
	assert_eq(two, {}, "deux candidates sans date : aucune n'est sûre")


func test_recovery_finds_nothing_without_a_wild_encounter() -> void:
	assert_eq(_recover({
		"charmander": _entry("oak_lab", "2026-10-02T10:00:00", "oak_lab", "2026-10-02T10:00:00"),
		"squirtle": _entry("oak_lab", "2026-10-02T10:01:00"),
		"pidgey": _entry("pallet_town", "2026-10-02T10:05:00"),
	}), {}, "le starter, le rival et un Roucool observé ne sont pas des rencontres")
	assert_eq(SaveSystem.recover_first_wild_encounter({}), {})


# --- Système de fichiers réel ---------------------------------------------------------------

func test_real_file_system_in_user_dir() -> void:
	var real_path := "user://tests/save_system_test.json"
	var save := SaveSystem.new(SaveFileSystem.new(), real_path)
	save.erase()
	assert_false(save.has_save())
	assert_eq(save.write({"player_name": "Kevin", "cell": [1, 2]}), OK, save.last_error)
	assert_true(save.has_save())
	assert_false(FileAccess.file_exists(real_path + ".tmp"), "temporaire renommé")
	assert_eq(save.read()["player_name"], "Kevin")
	assert_eq(save.write({"player_name": "Kevin 2"}), OK, "remplacement d'une sauvegarde")
	assert_eq(save.read()["player_name"], "Kevin 2")
	assert_eq(save.erase(), OK)
	assert_false(save.has_save())
	DirAccess.remove_absolute("user://tests")
