extends GutTest
## SaveSystem (jalon 5 §16, 5C.5) : un seul emplacement, écriture atomique, format versionné,
## fichier corrompu mis de côté, système de fichiers injectable. Puis l'aller-retour complet
## GameState → fichier → GameState neuf.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save.json"

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
		"version": SaveSystem.VERSION, "money": 3000, "badges": ["boulder"],
		"observations": {"pidgey": ["note"]}, "player_name": "Kevin",
	})
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data))
	assert_false(state.to_dict().has("money"), "les inconnus ne sont pas réécrits")


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
	dict["bag"]["poke_ball"] = "cinq"
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
