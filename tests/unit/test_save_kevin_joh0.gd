extends GutTest
## Chapitre Johto, JOH0 T5 (`jalon-joh0.md` §2.1, §4 critère 1 ; règle 1 de `CLAUDE.md`) : une
## **sauvegarde v9 de fin de Kanto écrite par le code de `main`** (2026-11-04 : départ de débogage
## `league_champion_charmander` + Stockage, Pension et Sac, écrits par le `SaveSystem` v9 de la
## build 0.34 ; la vraie partie de Kevin est sur le S24, indisponible, l'A17 n'en a pas), relue par
## la build v10 sans rien perdre : même version lue, migration 9 → 10 qui ne pose que le lien de
## migration, mêmes Pokémon dans le même ordre (équipe, Stockage, Pension), mêmes objets, argent,
## badges, drapeaux ; réécriture puis relecture identiques ; rien de confisqué. (JOH-Q1, décision
## déléguée par Kevin le 2026-11-04 : la vraie v9 du S24 entrera en fixture quand elle sera relevée.)

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SaveV10 := preload("res://tests/helpers/save_v10.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_kevin_joh0.json"
## Écrite par `main` (v9) le 2026-11-04 ; remplacée par la vraie partie du S24 quand elle sera relevée.
const FIXTURE := "res://tests/fixtures/save/v9_fin_kanto.json"

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
	state.clock = FixedClock.new("2026-11-04T12:00:00")
	state.new_game(4)
	return state


func _text() -> String:
	return FileAccess.get_file_as_string(FIXTURE)


func _original() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_text())
	assert_true(parsed is Dictionary, "fixture lisible")
	return parsed if parsed is Dictionary else {}


func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _signatures(members: Array) -> Array:
	var result: Array = []
	for member: Dictionary in members:
		result.append([member["species"], member["level"], member["uid"]])
	return result


func test_the_fixture_is_a_v9_end_of_kanto_save() -> void:
	var original := _original()
	assert_eq(int(original["version"]), 9, "écrite par le code de main (v9)")
	assert_eq(original["player_name"], "Kevin")
	assert_gt((original["party"] as Array).size(), 0, "une équipe")
	assert_gt((original["storage"] as Array).size(), 0, "un Stockage")
	assert_true((original["daycare"] as Dictionary).has("pokemon"), "une Pension occupée")
	for member: Dictionary in original["party"]:
		assert_false(member.has("bond"), "aucun lien avant la v10")


func test_it_is_read_as_v9_and_migrated_to_v10_with_only_the_bond() -> void:
	_fs.files[PATH] = _text()
	var read := _save.read()
	assert_eq(_save.last_status, OK, _save.last_error)
	assert_eq(_save.read_version, 9, "lue comme une v9 : le journal note « sauvegarde v9 → v10 »")
	assert_eq(SaveSystem.migration_note(_save.read_version, SaveSystem.VERSION),
		"sauvegarde v9 → v10")
	var expected := SaveV10.with_migrated_bond(_original())
	expected["version"] = SaveSystem.VERSION
	assert_eq(_json(read), _json(expected), "seuls le numéro et le lien de migration changent")
	assert_eq(_fs.files[PATH], _text(), "la lecture n'écrit rien")
	assert_false(_fs.files.has(PATH + ".rejected"), "rien d'écarté")


func test_nothing_is_lost_when_loaded_rewritten_and_read_again() -> void:
	var original := _original()
	_fs.files[PATH] = _text()
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data), "chargé sans entrée écartée")
	var saved: Dictionary = _json(state.to_dict())
	for key: String in ["party", "storage"]:
		assert_eq(_signatures(saved[key]), _signatures(original[key]),
			"même %s, même ordre" % key)
		for member: Dictionary in saved[key]:
			assert_eq(member["bond"], 50.0, "lien de migration")
			assert_false(member.has("egg_steps"), "pas un œuf")
	for key: String in ["bag", "money", "flags", "pokedex", "discovered_maps", "found_items",
			"moments", "player_name", "rival_name", "player_look", "map", "cell", "heal_map",
			"heal_spawn", "starter", "first_wild_encounter", "companion"]:
		assert_eq(saved.get(key), _json(original.get(key)), "inchangé : %s" % key)
	for key: String in ["hall_of_fame", "daycare", "rival_look", "player_costume", "mount",
			"safari"]:
		if original.has(key):
			var expected: Variant = _json(original[key])
			if key == "daycare" and (expected as Dictionary).has("pokemon"):
				expected["pokemon"]["bond"] = 50.0
			assert_eq(saved.get(key), expected, "inchangé : %s" % key)
	assert_true(state.confiscated.is_empty(), "rien de confisqué")
	assert_false(saved.has("confiscated"))
	assert_false(state.flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	# Réécriture puis relecture : stable, et plus de migration.
	assert_eq(_save.write(state.to_dict()), OK)
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data))
	assert_eq(_save.read_version, SaveSystem.VERSION, "relue à la version courante")
	assert_eq(_json(again.to_dict()), saved, "relecture identique")


func test_a_v9_build_refuses_the_rewritten_v10_file() -> void:
	_fs.files[PATH] = _text()
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data))
	assert_eq(_save.write(state.to_dict()), OK)
	var text: String = _fs.files[PATH]
	var old_build := SaveSystem.new(_fs, PATH)
	old_build.version = 9
	assert_eq(old_build.read(), {}, "l'APK 0.34 (v9) refuse la v10")
	assert_eq(old_build.last_status, ERR_INVALID_DATA)
	assert_eq(_fs.files[PATH], text, "sans l'écraser")
