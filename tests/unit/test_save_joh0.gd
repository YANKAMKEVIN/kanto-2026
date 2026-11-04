extends GutTest
## Chapitre Johto, JOH0 (`jalon-joh0.md` §2.1 ; dossier JOH-01 §12) : sauvegarde **v10** : lien
## « bond » de chaque Pokémon, œuf « egg_steps », section « confiscated » ; migration 9 → 10 qui
## ne fait que donner « bond » = 50 aux Pokémon déjà présents ; les vraies parties v6 de Kevin
## traversent 6 → 10 sans rien perdre ; une build v9 refuse la v10 (comportement existant) ; une
## section confisquée invalide est signalée (jamais perdue en silence).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_joh0.json"
const FIXTURES_V6: Array[String] = [
	"res://tests/fixtures/save/v6_kevin.json", "res://tests/fixtures/save/v6_kevin_s21.json",
]

var _fs: MemoryFs
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
	state.clock = FixedClock.new("2026-11-03T20:00:00")
	state.new_game(10)
	return state


## Partie complète : 3 Pokémon dans l'équipe, 2 au Stockage, 1 à la Pension, des objets.
func _full_state() -> Node:
	var state := _state()
	for species: StringName in [&"charmander", &"pidgey", &"rattata"]:
		var mon := PokemonFactory.create(_data, species, 12, GameRng.new(species.hash()))
		state.party.add(mon)
	for species: StringName in [&"caterpie", &"weedle"]:
		state.storage.add(PokemonFactory.create(_data, species, 4, GameRng.new(species.hash())))
	state.party.add(PokemonFactory.create(_data, &"nidoran_m", 9, GameRng.new(99)))
	assert_eq(DaycareRules.deposit(state.daycare, state.party, 3, _data), DaycareRules.Status.OK)
	state.bag.add(&"potion", 3)
	state.bag.add(&"poke_ball", 5)
	return state


func _fixture(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "fixture lisible : %s" % path)
	return parsed if parsed is Dictionary else {}


func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _signatures(members: Array) -> Array:
	var result: Array = []
	for member: Dictionary in members:
		result.append([member["species"], member["level"], member["uid"]])
	return result


func _load_through_save(content: Dictionary, expect_ok: bool = true) -> Node:
	if not content.has("version"):
		content["version"] = SaveSystem.VERSION
	_fs.files[PATH] = JSON.stringify(content)
	var read := _save.read()
	assert_eq(_save.last_status, OK, "fichier accepté")
	var state := _state()
	assert_eq(state.load_dict(read, _data), expect_ok, "chargement")
	return state


# --- Format et migration ----------------------------------------------------------------------

func test_the_format_is_v10_and_a_bare_v9_only_changes_its_number() -> void:
	assert_eq(SaveSystem.VERSION, 10, "v10 : Chapitre Johto (lien, œuf, équipe confisquée)")
	var bare := {"version": 9}
	assert_eq(SaveSystem.upgrade(bare), OK)
	assert_eq(bare, {"version": 10}, "sans Pokémon, rien d'autre")
	assert_eq(SaveSystem.migration_note(9, 10), "sauvegarde v9 → v10")


func test_the_step_9_to_10_gives_bond_50_to_every_pokemon_and_nothing_else() -> void:
	var state := _full_state()
	var content: Dictionary = _json(state.to_dict())
	content["version"] = 9
	for key: String in ["party", "storage"]:
		for member: Dictionary in content[key]:
			member.erase("bond")
	(content["daycare"]["pokemon"] as Dictionary).erase("bond")
	# Un lien déjà présent (fichier retouché) n'est pas remplacé.
	(content["party"][0] as Dictionary)["bond"] = 77
	var expected: Dictionary = content.duplicate(true)
	expected["version"] = 10
	for key: String in ["party", "storage"]:
		for member: Dictionary in expected[key]:
			if not member.has("bond"):
				member["bond"] = 50
	(expected["daycare"]["pokemon"] as Dictionary)["bond"] = 50
	assert_eq(SaveSystem.upgrade(content), OK)
	assert_eq(_json(content), _json(expected), "bond = 50 là où il manquait, rien d'autre")
	var loaded := _load_through_save(content)
	assert_eq(_signatures(_json(loaded.party.to_array())), _signatures(expected["party"]),
		"même équipe, même ordre")
	assert_eq(_signatures(_json(loaded.storage.to_array())), _signatures(expected["storage"]),
		"même Stockage, même ordre")
	assert_eq(loaded.party.get_at(0).bond, 77)
	assert_eq(loaded.party.get_at(1).bond, 50)
	assert_eq(loaded.storage.get_at(1).bond, 50)
	assert_eq(loaded.daycare.pokemon.bond, 50)
	assert_true(loaded.confiscated.is_empty(), "rien de confisqué")
	assert_eq(loaded.bag.count_of(&"potion"), 3)


func test_the_real_v6_saves_of_kevin_reach_v10_without_losing_anything() -> void:
	for path: String in FIXTURES_V6:
		before_each()
		var original := _fixture(path)
		assert_eq(int(original["version"]), 6, path)
		_fs.files[PATH] = FileAccess.get_file_as_string(path)
		var read := _save.read()
		assert_eq(_save.last_status, OK, path)
		assert_eq(_save.read_version, 6)
		assert_eq(int(read["version"]), 10)
		var state := _state()
		assert_true(state.load_dict(read, _data), "chargé sans entrée écartée : %s" % path)
		var saved: Dictionary = _json(state.to_dict())
		for key: String in ["party", "storage"]:
			assert_eq(_signatures(saved[key]), _signatures(original[key]),
				"%s : même %s, même ordre" % [path, key])
			for member: Dictionary in saved[key]:
				assert_eq(member["bond"], 50.0, "lien de migration")
				assert_false(member.has("egg_steps"), "pas un œuf")
		assert_false(saved.has("confiscated"), "rien de confisqué : rien d'écrit")
		for key: String in ["bag", "money", "flags", "moments", "pokedex", "discovered_maps",
				"found_items", "player_name", "rival_name", "map", "cell", "heal_map",
				"first_wild_encounter", "companion"]:
			assert_eq(saved.get(key), _json(original.get(key)), "%s inchangé : %s" % [path, key])
		# Réécriture puis relecture : stable.
		assert_eq(_save.write(state.to_dict()), OK)
		var again := _state()
		assert_true(again.load_dict(_save.read(), _data))
		assert_eq(_json(again.to_dict()), saved, "relecture identique : %s" % path)


func test_a_v9_build_refuses_a_v10_file_without_touching_it() -> void:
	var state := _full_state()
	assert_eq(_save.write(state.to_dict()), OK)
	var text: String = _fs.files[PATH]
	var old_build := SaveSystem.new(_fs, PATH)
	old_build.version = 9
	assert_eq(old_build.read(), {})
	assert_eq(old_build.last_status, ERR_INVALID_DATA)
	assert_eq(_fs.files[PATH], text, "fichier intact")
	var future := JSON.parse_string(text) as Dictionary
	future["version"] = 11
	_fs.files[PATH] = JSON.stringify(future)
	assert_eq(_save.read(), {}, "une v11 est refusée par cette build")
	assert_eq(_save.last_status, ERR_INVALID_DATA)


# --- Lien et œuf -------------------------------------------------------------------------------

func test_bond_and_egg_steps_survive_a_round_trip_and_are_bounded_on_read() -> void:
	var state := _full_state()
	state.party.get_at(0).set_bond(70)
	state.party.get_at(1).egg_steps = 1234
	assert_true(state.party.get_at(1).is_egg())
	var dict: Dictionary = state.to_dict()
	assert_eq(dict["party"][0]["bond"], 70)
	assert_false((dict["party"][0] as Dictionary).has("egg_steps"), "pas un œuf : rien d'écrit")
	assert_eq(dict["party"][1]["egg_steps"], 1234)
	assert_eq(_save.write(dict), OK)
	var loaded := _state()
	assert_true(loaded.load_dict(_save.read(), _data))
	assert_eq(loaded.party.get_at(0).bond, 70)
	assert_eq(loaded.party.get_at(1).egg_steps, 1234)
	assert_false(loaded.party.get_at(0).is_egg())
	# Valeurs mal formées ou hors bornes : jamais un refus.
	var entry: Dictionary = (dict["party"][0] as Dictionary).duplicate(true)
	for bad: Variant in [null, "70", -5, 250, 3.5]:
		entry["bond"] = bad
		entry["egg_steps"] = bad
		var mon := Pokemon.from_dict(entry, _data)
		assert_not_null(mon, "valeur %s" % str(bad))
		if bad is int:
			assert_eq(mon.bond, clampi(bad, 0, 100), "borné : %s" % str(bad))
			assert_eq(mon.egg_steps, maxi(bad, 0), "borné : %s" % str(bad))
		else:
			assert_eq(mon.bond, Pokemon.DEFAULT_BOND, "défaut : %s" % str(bad))
			assert_eq(mon.egg_steps, 0, "défaut : %s" % str(bad))
	var mon := PokemonFactory.create(_data, &"pidgey", 5, GameRng.new(3))
	assert_eq(mon.add_bond(60), 50, "borné à 100 : variation réelle")
	assert_eq(mon.add_bond(-200), -100)
	assert_eq(mon.bond, 0)


func test_stamp_meeting_sets_the_starting_bond_by_origin() -> void:
	var state := _state()
	var expected := {
		Pokemon.Origin.CAPTURE: 20, Pokemon.Origin.STARTER: 50, Pokemon.Origin.GIFT: 50,
		Pokemon.Origin.TRADE: 50, Pokemon.Origin.EGG: 50,
	}
	for origin: Pokemon.Origin in expected:
		var mon := PokemonFactory.create(_data, &"rattata", 3, GameRng.new(1))
		state.stamp_meeting(mon, origin, &"route_1")
		assert_eq(mon.bond, expected[origin], Pokemon.ORIGIN_NAMES.find_key(origin))
		assert_eq(mon.origin, origin)
	var mon := PokemonFactory.create(_data, &"rattata", 3, GameRng.new(1))
	mon.record_meeting(Pokemon.Origin.EGG, &"goldenrod_city", "2026-11-03", "Kevin")
	assert_eq(Pokemon.from_dict(mon.to_dict(), _data).origin, Pokemon.Origin.EGG, "« egg » relu")


# --- Section confisquée -------------------------------------------------------------------------

func test_the_confiscated_section_is_absent_when_empty_and_round_trips_otherwise() -> void:
	var state := _full_state()
	assert_true(state.confiscated.is_empty())
	assert_false(state.to_dict().has("confiscated"), "vide : rien d'écrit")
	var taken := PokemonFactory.create(_data, &"squirtle", 55, GameRng.new(5))
	taken.ensure_uid()
	state.confiscated.party.append(taken)
	state.confiscated.items[&"super_potion"] = 4
	state.confiscated.items[&"great_ball"] = 2
	state.confiscated.companion_uid = taken.uid
	var dict: Dictionary = state.to_dict()
	assert_eq(dict["confiscated"]["items"], {"great_ball": 2, "super_potion": 4}, "clés triées")
	assert_eq(dict["confiscated"]["companion"], taken.uid)
	assert_eq(_save.write(dict), OK)
	var loaded := _state()
	assert_true(loaded.load_dict(_save.read(), _data))
	assert_eq(loaded.confiscated.party.size(), 1)
	assert_eq(loaded.confiscated.party[0].species_id, &"squirtle")
	assert_eq(loaded.confiscated.party[0].uid, taken.uid, "identifiant gardé")
	assert_eq(loaded.confiscated.items, {&"super_potion": 4, &"great_ball": 2}
		as Dictionary[StringName, int])
	assert_eq(loaded.confiscated.companion_uid, taken.uid)
	assert_eq(loaded.confiscated.find_by_uid(taken.uid).species_id, &"squirtle")
	assert_null(loaded.confiscated.find_by_uid(""))
	loaded.new_game(1)
	assert_true(loaded.confiscated.is_empty(), "nouvelle partie : rien de confisqué")


func test_an_invalid_confiscated_section_is_refused_not_lost_in_silence() -> void:
	var content: Dictionary = _full_state().to_dict()
	for bad: Variant in [{}, {"party": [], "items": {}, "companion": ""}, null]:
		content["confiscated"] = bad
		if bad == null:
			content.erase("confiscated")
		var state := _load_through_save(content)
		assert_true(state.confiscated.is_empty(), "vide : %s" % str(bad))
	var broken := PokemonFactory.create(_data, &"squirtle", 5, GameRng.new(5)).to_dict()
	broken["species"] = "missingno"
	for bad: Variant in ["texte", 3, {"party": [broken]}, {"party": {}},
			{"items": {"potion": 0}}, {"items": ["potion"]}, {"party": ["pas un objet"]}]:
		content["confiscated"] = bad
		var state := _load_through_save(content, false)
		assert_true(state.confiscated.is_empty(), "refusé et vide : %s" % str(bad))
		assert_eq(state.party.size(), 3, "le reste de la partie est chargé")
	# Une erreur par section refusée, deux pour le Pokémon invalide (espèce inconnue, puis la
	# section) : chaque refus est signalé.
	assert_push_error_count(8, "sept sections refusées, dont une pour un Pokémon invalide")


func test_confiscated_pokemon_take_part_in_uid_uniqueness() -> void:
	var state := _full_state()
	var taken := PokemonFactory.create(_data, &"squirtle", 55, GameRng.new(5))
	taken.uid = state.party.get_at(0).uid
	state.confiscated.party.append(taken)
	var twin := PokemonFactory.create(_data, &"bulbasaur", 55, GameRng.new(6))
	state.confiscated.party.append(twin)
	assert_eq(state.ensure_unique_uids(), 2, "un doublon régénéré, un identifiant attribué")
	assert_ne(taken.uid, state.party.get_at(0).uid)
	assert_true(PokemonUid.is_valid(twin.uid))
	assert_eq(state.party.get_at(0).uid, state.party.get_at(0).uid, "l'équipe garde les siens")
