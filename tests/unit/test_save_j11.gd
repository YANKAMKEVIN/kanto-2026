extends GutTest
## Sauvegarde du jalon 11 (T1, `jalon-11.md` §2.1, dossier 14 §9) : identifiant stable de
## chaque Pokémon, compteur du statut, compagnon désigné par identifiant. Migration additive :
## une partie d'avant le J11 se recharge avec les mêmes Pokémon, dans le même ordre.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save.json"
## Vraie partie de Kevin en fin de J7 (v3, voir test_save_system) : 4 Pokémon, Stockage.
const FIXTURE_V3 := "res://tests/fixtures/save/v3_kevin_j7_fin.json"
## Vraie partie de Kevin en v2 (fin de J6, 13 h 57) : relue jusqu'à la version courante.
const FIXTURE_V2_END := "res://tests/fixtures/save/v2_kevin_j6_fin.json"
## Vraie partie de Kevin en v4 (fin du J10, S21, relevée par OUV.1) : la partie qui sera migrée.
const FIXTURE_V4_S21 := "res://tests/fixtures/save/v4_kevin_s21.json"
## Vraie partie de Kevin en v5 (S21, relevée avant toute installation au T3 du J11, sha1 1e63980…).
const FIXTURE_V5_REAL := "res://tests/fixtures/save/v5_kevin.json"

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
	state.clock = FixedClock.new("2026-10-10T10:00:00")
	state.new_game(11)
	return state


func _fixture(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "fixture lisible : %s" % path)
	return parsed if parsed is Dictionary else {}


## La vraie partie v3 telle que la build du J9 l'écrit en v4 (le pas 3 → 4 ne transforme rien).
func _fixture_v4() -> Dictionary:
	var content := _fixture(FIXTURE_V4_S21)
	assert_eq(int(content["version"]), 4)
	return content


## La vraie partie v3 telle que la build du J9 l'écrit en v4 (Stockage non vide).
func _fixture_v4_with_storage() -> Dictionary:
	var content := _fixture(FIXTURE_V3)
	assert_eq(SaveSystem.upgrade(content, 4), OK)
	return content


## La vraie partie du S21 telle qu'OUV.1 l'écrit en v5 (prénom du rival choisi, apparence).
func _fixture_v5() -> Dictionary:
	var content := _fixture_v4()
	content["version"] = 5
	content["rival_name"] = "Blue"
	content["player_look"] = "hero"
	return content


## Écrit [param content] tel quel (sa version d'origine), le relit par SaveSystem (migration)
## puis le charge dans un GameState neuf.
func _load_through_save(content: Dictionary) -> Node:
	(_fs as MemoryFs).files[PATH] = JSON.stringify(content)
	var migrated := _save.read()
	assert_eq(_save.last_status, OK, "fichier accepté")
	assert_eq(int(migrated["version"]), SaveSystem.VERSION, "migré à la version courante")
	var state := _state()
	assert_true(state.load_dict(migrated, _data), "chargé sans entrée écartée")
	return state


## Identité d'un Pokémon sans son identifiant : espèce, surnom, niveau, XP, PV, capacités.
func _signature(entry: Variant) -> String:
	var dict: Dictionary = entry
	var moves: Array = []
	for move: Variant in dict.get("moves", []):
		moves.append("%s:%d/%d" % [move["id"], int(move["pp"]), int(move["max_pp"])])
	return "%s|%s|%d|%d|%d|%s" % [dict["species"], dict.get("nickname", ""), int(dict["level"]),
		int(dict["exp"]), int(dict["hp"]), ",".join(moves)]


func _signatures(entries: Array) -> Array[String]:
	var result: Array[String] = []
	for entry: Variant in entries:
		result.append(_signature(entry))
	return result


func _uids(state: Node) -> Array[String]:
	var result: Array[String] = []
	for pokemon: Pokemon in state.party.get_all():
		result.append(pokemon.uid)
	for pokemon: Pokemon in state.storage.get_all():
		result.append(pokemon.uid)
	return result


# --- Identifiant ---------------------------------------------------------------------------

func test_an_uid_has_sixteen_lowercase_hex_digits() -> void:
	var uid := PokemonUid.generate()
	assert_eq(uid.length(), PokemonUid.LENGTH)
	assert_true(PokemonUid.is_valid(uid))
	assert_false(PokemonUid.is_valid("ABCDEF0123456789"), "majuscules refusées")
	assert_false(PokemonUid.is_valid("0123"), "trop court")
	assert_false(PokemonUid.is_valid(12), "pas une chaîne")


func test_generating_an_uid_does_not_touch_the_game_random() -> void:
	var state := _state()
	var before: Dictionary = state.rng.to_dict()
	for i: int in 20:
		PokemonUid.generate()
	assert_eq(state.rng.to_dict(), before, "GameRng intact")


func test_joining_the_party_or_the_storage_gives_an_uid_once() -> void:
	var state := _state()
	var starter := PokemonFactory.create(_data, &"charmander", 5, GameRng.new(1))
	assert_eq(starter.uid, "", "un Pokémon sauvage n'a pas d'identifiant")
	state.party.add(starter)
	var uid := starter.uid
	assert_true(PokemonUid.is_valid(uid))
	var boxed := PokemonFactory.create(_data, &"pidgey", 3, GameRng.new(2))
	state.storage.add(boxed)
	assert_true(PokemonUid.is_valid(boxed.uid))
	assert_ne(boxed.uid, uid)
	# Déposé puis retiré : le même objet garde son identifiant.
	state.storage.add(state.party.remove_at(0))
	assert_eq(starter.uid, uid)
	state.party.add(state.storage.remove_at(state.storage.index_of(starter)))
	assert_eq(starter.uid, uid)


func test_evolving_keeps_the_uid() -> void:
	var state := _state()
	var caterpie := PokemonFactory.create(_data, &"caterpie", 7, GameRng.new(3))
	state.party.add(caterpie)
	var uid := caterpie.uid
	caterpie.evolve_into(&"metapod", _data)
	assert_eq(caterpie.species_id, &"metapod")
	assert_eq(caterpie.uid, uid)


func test_uid_and_status_turns_round_trip() -> void:
	var pokemon := PokemonFactory.create(_data, &"pikachu", 6, GameRng.new(4))
	pokemon.ensure_uid()
	pokemon.status = StatusRules.POISON
	pokemon.status_turns = 2
	var copy := Pokemon.from_dict(JSON.parse_string(JSON.stringify(pokemon.to_dict())), _data)
	assert_eq(copy.uid, pokemon.uid)
	assert_eq(copy.status_turns, 2)
	copy.cure_status()
	assert_eq(copy.status_turns, 0, "soigné : plus de compteur")
	copy.status = StatusRules.POISON
	copy.status_turns = 3
	copy.heal_full()
	assert_eq(copy.status_turns, 0, "soin complet : plus de compteur")


func test_a_malformed_uid_or_counter_is_replaced_never_refused() -> void:
	var dict := PokemonFactory.create(_data, &"rattata", 3, GameRng.new(5)).to_dict()
	dict["uid"] = "pas-un-identifiant"
	dict["status_turns"] = 99
	var pokemon := Pokemon.from_dict(dict, _data)
	assert_not_null(pokemon, "jamais un refus")
	assert_eq(pokemon.uid, "", "identifiant mal formé oublié")
	assert_eq(pokemon.status_turns, 0, "sans statut, pas de compteur")
	assert_push_warning("identifiant mal formé")
	dict["status"] = "poison"
	assert_eq(Pokemon.from_dict(dict, _data).status_turns, Pokemon.MAX_STATUS_TURNS, "borné")


# --- Migration -----------------------------------------------------------------------------

func test_a_v4_save_keeps_every_pokemon_in_order_and_gets_uids() -> void:
	for original: Dictionary in [_fixture_v4(), _fixture_v4_with_storage(), _fixture_v5(),
			_fixture(FIXTURE_V5_REAL)]:
		_check_same_pokemon(original)


func _check_same_pokemon(original: Dictionary) -> void:
	var state := _load_through_save(original.duplicate(true))
	var saved: Dictionary = _json(state.to_dict())
	assert_eq(_signatures(saved["party"]), _signatures(original["party"]),
		"même équipe, même ordre")
	assert_eq(_signatures(saved["storage"]), _signatures(original["storage"]),
		"même Stockage, même ordre")
	var uids := _uids(state)
	assert_eq(uids.size(), original["party"].size() + original["storage"].size())
	var unique: Dictionary = {}
	for uid: String in uids:
		assert_true(PokemonUid.is_valid(uid), "identifiant attribué : %s" % uid)
		unique[uid] = true
	assert_eq(unique.size(), uids.size(), "identifiants uniques")
	assert_eq(state.companion_uid, "", "aucun compagnon au départ")


func test_a_v4_save_keeps_bag_money_badges_flags_and_moments() -> void:
	var original := _fixture_v4()
	var state := _load_through_save(original.duplicate(true))
	var saved: Dictionary = _json(state.to_dict())
	for key: String in ["bag", "money", "flags", "moments", "pokedex", "discovered_maps",
			"found_items", "player_name", "map", "cell", "heal_map", "first_wild_encounter"]:
		assert_eq(saved.get(key), _json(original.get(key)), "inchangé : %s" % key)


func test_uids_are_stable_from_one_load_to_the_next() -> void:
	var state := _load_through_save(_fixture_v4())
	var first := _uids(state)
	assert_eq(_save.write(state.to_dict()), OK)
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data))
	assert_eq(_uids(again), first, "mêmes identifiants, même ordre")


func test_an_ouv_v5_save_keeps_the_rival_name_and_the_look() -> void:
	var state := _load_through_save(_fixture_v5())
	assert_eq(state.rival_name, "Blue", "prénom du rival (v5) gardé")
	assert_eq(state.player_look, &"hero")
	var saved: Dictionary = _json(state.to_dict())
	assert_eq(saved["rival_name"], "Blue")
	assert_eq(saved["companion"], "")


func test_the_real_v5_save_of_kevin_migrates_without_any_other_change() -> void:
	# T3 (jalon-11.md) : la vraie partie v5 du S21, relue par cette build, réécrite en v6 : hors
	# « version » et les champs du J11, rien ne change (même vérification que sur le téléphone).
	var original := _fixture(FIXTURE_V5_REAL)
	assert_eq(int(original["version"]), 5, "la fixture est bien une v5")
	var state := _load_through_save(original.duplicate(true))
	assert_eq(state.rival_name, original["rival_name"], "prénom du rival gardé")
	var saved: Dictionary = _json(state.to_dict())
	for key: String in ["party", "storage"]:
		for member: Dictionary in saved[key]:
			assert_true(PokemonUid.is_valid(member.get("uid")), "identifiant")
			assert_eq(member.get("status_turns"), 0.0, "compteur nul")
			member.erase("uid")
			member.erase("status_turns")
	assert_eq(saved["companion"], "", "aucun compagnon")
	saved.erase("companion")
	# J15 (v7) : Pension vide, seul autre champ ajouté depuis.
	assert_eq(saved["daycare"], {}, "Pension vide")
	saved.erase("daycare")
	var before: Dictionary = _json(original)
	before.erase("version")
	assert_eq(saved, before, "rien d'autre ne change")


func test_the_real_v2_save_reaches_the_current_version_with_uids() -> void:
	var original := _fixture(FIXTURE_V2_END)
	var state := _load_through_save(original.duplicate(true))
	assert_eq(_signatures(_json(state.to_dict())["party"]), _signatures(original["party"]))
	for uid: String in _uids(state):
		assert_true(PokemonUid.is_valid(uid))


func test_a_duplicated_uid_is_regenerated_for_the_second_only() -> void:
	var content := _fixture_v4()
	content["version"] = SaveSystem.VERSION
	var party: Array = content["party"]
	assert_gt(party.size(), 1, "au moins deux Pokémon")
	party[0]["uid"] = "0123456789abcdef"
	party[1]["uid"] = "0123456789abcdef"
	var state := _load_through_save(content)
	assert_eq(state.party.get_at(0).uid, "0123456789abcdef", "le premier garde le sien")
	assert_ne(state.party.get_at(1).uid, "0123456789abcdef", "le second en reçoit un neuf")


func test_a_newer_version_is_still_refused_untouched() -> void:
	var text := JSON.stringify({"version": SaveSystem.VERSION + 1, "player_name": "Futur"})
	(_fs as MemoryFs).files[PATH] = text
	assert_eq(_save.read(), {})
	assert_eq(_save.last_status, ERR_INVALID_DATA)
	assert_eq((_fs as MemoryFs).files[PATH], text, "fichier intact")


func test_the_previous_build_refuses_a_j11_save_without_writing_it() -> void:
	var state := _load_through_save(_fixture_v4())
	assert_eq(_save.write(state.to_dict()), OK)
	var text: String = (_fs as MemoryFs).files[PATH]
	var old_build := SaveSystem.new(_fs, PATH)
	old_build.version = 5
	assert_eq(old_build.read(), {})
	assert_eq(old_build.last_status, ERR_INVALID_DATA, "la build d'OUV (v5) refuse")
	assert_eq((_fs as MemoryFs).files[PATH], text, "fichier identique octet pour octet")


# --- Compagnon -----------------------------------------------------------------------------

func test_the_companion_is_kept_by_uid_when_the_party_is_reordered() -> void:
	var state := _load_through_save(_fixture_v4())
	var second: Pokemon = state.party.get_at(1)
	assert_true(state.set_companion(second))
	assert_true(state.party.swap(0, 1))
	assert_eq(state.get_companion(), second, "toujours le même Pokémon")
	assert_eq(_save.write(state.to_dict()), OK)
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data))
	assert_eq(again.get_companion().uid, second.uid, "relu par identifiant")
	assert_eq(again.party.index_of(again.get_companion()), 0, "à sa nouvelle place")


func test_the_companion_stays_chosen_when_fainted() -> void:
	var state := _load_through_save(_fixture_v4())
	var lead: Pokemon = state.party.get_lead()
	state.set_companion(lead)
	lead.take_damage(lead.hp)
	assert_eq(state.get_companion(), lead, "K.O. : toujours choisi (seule la visibilité change)")
	assert_eq(state.companion_uid, lead.uid)


func test_a_companion_not_in_the_party_is_refused_and_one_deposited_is_gone() -> void:
	var state := _load_through_save(_fixture_v4())
	var outsider := PokemonFactory.create(_data, &"pidgey", 3, GameRng.new(6))
	assert_false(state.set_companion(outsider), "hors de l'équipe : refusé")
	assert_eq(state.companion_uid, "")
	var lead: Pokemon = state.party.get_lead()
	state.set_companion(lead)
	state.storage.add(state.party.remove_at(0))
	assert_null(state.get_companion(), "déposé au Stockage : plus de compagnon")
	assert_true(state.set_companion(null))
	assert_eq(state.companion_uid, "")


func test_an_unknown_companion_in_the_file_means_no_companion() -> void:
	var content := _fixture_v4()
	content["version"] = SaveSystem.VERSION
	content["companion"] = "ffffffffffffffff"
	var state := _load_through_save(content)
	assert_eq(state.companion_uid, "", "identifiant inconnu : aucun compagnon, sans refus")


func test_a_new_game_has_no_companion() -> void:
	var state := _state()
	state.companion_uid = "0123456789abcdef"
	state.new_game(1)
	assert_eq(state.companion_uid, "")


## Passage par le JSON (entiers en flottants), pour comparer deux dictionnaires.
func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))
