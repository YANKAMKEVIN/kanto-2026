extends GutTest
## Clôture du J12 (T29, `jalon-12.md` §2.20 et §4 « 12D ») : la **vraie partie de Kevin** relevée
## sur le S21 le 2026-10-14 (v6, Jadielle, sans badge ; SHA-1 `e51ccdaa…`), relue par le code du
## J12 sans rien perdre. Point « non vu » de la QA finale : un départ de débogage n'écrit pas la
## sauvegarde, l'APK n'a donc jamais relu la vraie partie. Ici : lecture par [SaveSystem]
## (aucune migration, version inchangée), chargement dans un [GameState] neuf, réécriture et
## relecture identiques champ par champ ; le compagnon se choisit et se relit.
## (La reprise par le vrai Boot et les raccords vers Argenta : `test_save_kevin_j12_boot`.)

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_kevin_j12.json"
## Copie octet pour octet de `build/qa/sauvegarde_kevin_s21_2026-10-14/save.json` du Mac.
const FIXTURE := "res://tests/fixtures/save/v6_kevin_s21.json"
## Tous les champs que `GameState.to_dict()` écrit, vérifiés un par un.
const KEYS: Array[String] = [
	"version", "bag", "cell", "companion", "discovered_maps", "facing", "first_wild_encounter",
	"flags", "found_items", "heal_map", "heal_spawn", "map", "moments", "money", "party",
	"play_time", "player_look", "player_name", "pokedex", "rival_name", "rng", "started_at",
	"starter", "storage",
]

var _fs: MemoryFs
var _save: SaveSystem
var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon du J12")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-14T12:00:00")
	state.new_game(29)
	return state


func _text() -> String:
	return FileAccess.get_file_as_string(FIXTURE)


func _original() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_text())
	assert_true(parsed is Dictionary, "fixture lisible")
	return parsed if parsed is Dictionary else {}


## Dépose le fichier tel quel, le relit par [SaveSystem] et le charge dans un état neuf.
func _load() -> Node:
	_fs.files[PATH] = _text()
	var read := _save.read()
	assert_eq(_save.last_status, OK, "fichier accepté")
	var state := _state()
	assert_true(state.load_dict(read, _data), "chargé sans entrée écartée")
	return state


## Passage par le JSON (entiers en flottants), pour comparer deux dictionnaires.
func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func test_the_fixture_is_the_real_save_of_kevin() -> void:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA1)
	hashing.update(FileAccess.get_file_as_bytes(FIXTURE))
	assert_eq(hashing.finish().hex_encode(), "e51ccdaa90bb7ddbd111e65ea2feab636058ebc0",
		"copie exacte du fichier du téléphone")
	var original := _original()
	assert_eq(int(original["version"]), 6)
	assert_eq(original["player_name"], "Kevin")
	assert_eq(original["map"], "viridian_city")
	assert_false((original["flags"] as Array).has("badge_boulder"), "aucun badge")
	var keys: Array = original.keys()
	keys.sort()
	var expected := KEYS.duplicate()
	expected.sort()
	assert_eq(keys, expected, "mêmes champs que ceux qu'écrit le J12")


func test_the_j12_reads_it_without_migration() -> void:
	assert_eq(SaveSystem.VERSION, 6, "le J12 n'a pas de version nouvelle (§2.20)")
	_fs.files[PATH] = _text()
	var read := _save.read()
	assert_eq(_save.last_status, OK)
	assert_eq(int(read["version"]), 6, "version inchangée")
	assert_eq(_json(read), _json(_original()), "lu tel quel : aucune migration")
	assert_eq(_fs.files[PATH], _text(), "la lecture n'écrit rien")
	assert_false(_fs.files.has(PATH + ".rejected"), "rien d'écarté")


func test_nothing_is_lost_when_loaded_by_the_j12() -> void:
	var original := _original()
	var state := _load()
	# Équipe : espèces, niveaux, XP, PV, capacités, identifiants, dans l'ordre.
	var party: Array = original["party"]
	assert_eq(state.party.size(), party.size(), "équipe complète")
	for i: int in party.size():
		var pokemon: Pokemon = state.party.get_at(i)
		var entry: Dictionary = party[i]
		assert_eq(String(pokemon.species_id), entry["species"], "espèce %d" % i)
		assert_eq(pokemon.level, int(entry["level"]), "niveau %d" % i)
		assert_eq(pokemon.uid, entry["uid"], "identifiant %d" % i)
	assert_eq(state.storage.size(), (original["storage"] as Array).size(), "Stockage")
	# Sac, argent, drapeaux, Pokédex, compagnon, position, point de repos.
	assert_eq(state.money, int(original["money"]), "argent")
	assert_eq(state.flags.size(), (original["flags"] as Array).size(), "drapeaux")
	for flag: String in original["flags"]:
		assert_true(state.flags.has_flag(StringName(flag)), flag)
	assert_eq(state.bag.count_of(&"potion"), 0, "Sac vide (Potions utilisées)")
	assert_eq(state.companion_uid, "", "aucun compagnon choisi")
	assert_eq(state.current_map, &"viridian_city")
	assert_eq(state.player_cell, Vector2i(42, 22))
	assert_eq(state.player_facing, Vector2i.UP)
	assert_eq(state.heal_map, &"viridian_center")
	assert_eq(state.player_name, "Kevin")
	assert_eq(state.rival_name, "Régis")
	# `to_dict()` n'a pas « version » : SaveSystem l'ajoute à l'écriture (test suivant).
	var saved: Dictionary = _json(state.to_dict())
	for key: String in KEYS:
		if key != "version":
			assert_eq(saved.get(key), _json(original.get(key)), "inchangé : %s" % key)


func test_written_then_read_again_it_is_identical() -> void:
	var state := _load()
	assert_eq(_save.write(state.to_dict()), OK, "écrite par le J12")
	var once: String = _fs.files[PATH]
	assert_eq(JSON.parse_string(once), _json(_original()), "fichier écrit = l'original (v6)")
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data), "relue")
	assert_eq(_save.write(again.to_dict()), OK)
	assert_eq(_fs.files[PATH], once, "deuxième écriture identique octet pour octet")


func test_his_starter_can_become_the_companion_and_it_is_kept() -> void:
	var state := _load()
	var starter: Pokemon = state.party.get_at(0)
	assert_eq(starter.species_id, &"charmander")
	assert_true(state.set_companion(starter), "Salamèche choisi comme compagnon")
	assert_eq(_save.write(state.to_dict()), OK)
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data))
	assert_eq(again.companion_uid, "5966d34cfc4a453a", "compagnon relu par identifiant")
	assert_eq(again.get_companion(), again.party.get_at(0))
