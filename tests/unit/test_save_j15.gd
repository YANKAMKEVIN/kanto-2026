extends GutTest
## Sauvegarde v7 du jalon 15 (T2, `jalon-15.md` §2.6, dossier 18 §11) : la Pension (Pokémon
## déposé, XP en attente, niveau au dépôt) dans `GameState`, migration v6 → v7 sans
## transformation, identifiants uniques entre équipe, Stockage et Pension, Pension invalide
## signalée (jamais perdue en silence), compagnon déposé effacé au chargement.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save.json"
## Vraie partie de Kevin en v6 (S21, relevée après la QA du T16 du J11, sha1 6a4868a…) :
## 4 Pokémon, Jadielle.
const FIXTURE_V6_REAL := "res://tests/fixtures/save/v6_kevin.json"
const TOOL_START := "res://tools/debug_start/daycare_v7_qa.json"

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
	state.clock = FixedClock.new("2026-10-12T10:00:00")
	state.new_game(15)
	return state


func _fixture(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "fixture lisible : %s" % path)
	return parsed if parsed is Dictionary else {}


## Partie de deux Pokémon dont le second (Rattata N10) est déposé, avec 500 XP en attente.
func _state_with_deposit() -> Node:
	var state := _state()
	state.party.add(PokemonFactory.create(_data, &"charmander", 12, GameRng.new(1)))
	state.party.add(PokemonFactory.create(_data, &"rattata", 10, GameRng.new(2)))
	assert_eq(DaycareRules.deposit(state.daycare, state.party, 1, _data),
		DaycareRules.Status.OK)
	state.daycare.pending_exp = 500
	return state


## Écrit [param content] tel quel, le relit par SaveSystem puis le charge dans un état neuf.
## [param expect_ok] : load_dict doit-il tout accepter ?
func _load_through_save(content: Dictionary, expect_ok: bool = true) -> Node:
	(_fs as MemoryFs).files[PATH] = JSON.stringify(content)
	var migrated := _save.read()
	assert_eq(_save.last_status, OK, "fichier accepté")
	assert_eq(int(migrated["version"]), SaveSystem.VERSION, "migré à la version courante")
	var state := _state()
	assert_eq(state.load_dict(migrated, _data), expect_ok, "load_dict")
	return state


## Version courante d'une partie écrite par [param state] (passage par le JSON).
func _written(state: Node) -> Dictionary:
	assert_eq(_save.write(state.to_dict()), OK)
	return JSON.parse_string((_fs as MemoryFs).files[PATH])


# --- Format et version ---------------------------------------------------------------------

func test_the_format_is_v7_and_the_step_6_to_7_changes_nothing_but_the_version() -> void:
	assert_eq(SaveSystem.VERSION, 7, "v7 : jalon 15 (Pension)")
	var bare := {"version": 6}
	assert_eq(SaveSystem.upgrade(bare, 7), OK)
	assert_eq(bare, {"version": 7}, "aucun champ inventé : Pension vide par défaut")
	assert_eq(SaveSystem.migration_note(6, 7), "sauvegarde v6 → v7")


func test_an_empty_daycare_is_written_as_an_empty_object() -> void:
	var saved := _written(_state())
	assert_eq(saved["version"], 7.0)
	assert_eq(saved["daycare"], {}, "Pension vide : objet vide")


func test_a_new_game_empties_the_daycare() -> void:
	var state := _state_with_deposit()
	state.new_game(1)
	assert_true(state.daycare.is_empty())
	assert_eq(state.to_dict()["daycare"], {})


# --- Aller-retour --------------------------------------------------------------------------

func test_the_deposited_pokemon_its_pending_exp_and_deposit_level_round_trip() -> void:
	var state := _state_with_deposit()
	var kept: Pokemon = state.daycare.pokemon
	assert_true(PokemonUid.is_valid(kept.uid), "uid gardé au dépôt (même instance)")
	var saved := _written(state)
	assert_eq(saved["daycare"]["pending_exp"], 500.0)
	assert_eq(saved["daycare"]["deposit_level"], 10.0)
	assert_eq(saved["party"].size(), 1, "l'équipe ne le contient plus")
	var again := _state()
	assert_true(again.load_dict(_save.read(), _data), "relu sans refus")
	var back: Pokemon = again.daycare.pokemon
	assert_not_null(back, "le Pokémon déposé survit à l'aller-retour")
	assert_eq(back.species_id, &"rattata")
	assert_eq(back.level, 10, "niveau inchangé pendant le séjour")
	assert_eq(back.experience, kept.experience, "XP du Pokémon inchangée (attente à part)")
	assert_eq(back.uid, kept.uid, "même identifiant")
	assert_eq(back.moves.size(), kept.moves.size())
	assert_eq(again.daycare.pending_exp, 500)
	assert_eq(again.daycare.deposit_level, 10)
	assert_eq(again.daycare.exp_room, state.daycare.exp_room, "plafond recalculé à l'identique")
	assert_eq(again.party.size(), 1)
	assert_eq(JSON.stringify(again.to_dict()), JSON.stringify(state.to_dict()),
		"même état réécrit")


func test_the_deposit_level_stays_when_the_daycare_is_reloaded() -> void:
	# Niveau au dépôt différent du niveau actuel n'arrive pas (rien ne change pendant le séjour),
	# mais un fichier qui porte un niveau au dépôt plus bas le garde tel quel.
	var state := _state_with_deposit()
	var dict: Dictionary = state.to_dict()
	dict["daycare"]["deposit_level"] = 8
	dict["version"] = SaveSystem.VERSION
	var again := _load_through_save(dict)
	assert_eq(again.daycare.deposit_level, 8)


# --- Migration v6 → v7 ---------------------------------------------------------------------

func test_the_real_v6_save_of_kevin_migrates_to_v7_without_any_other_change() -> void:
	var original := _fixture(FIXTURE_V6_REAL)
	assert_eq(int(original["version"]), 6, "la fixture est bien une v6")
	assert_false(original.has("daycare"), "pas encore de Pension en v6")
	var state := _load_through_save(original.duplicate(true))
	assert_true(state.daycare.is_empty(), "Pension vide")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	assert_eq(saved["daycare"], {}, "Pension vide écrite")
	saved.erase("daycare")
	var before: Dictionary = original.duplicate(true)
	before.erase("version")
	assert_eq(saved, before, "rien d'autre ne change (uid, compagnon, équipe, Sac, drapeaux…)")


func test_the_real_v6_save_keeps_its_uids() -> void:
	var original := _fixture(FIXTURE_V6_REAL)
	var state := _load_through_save(original.duplicate(true))
	for i: int in original["party"].size():
		assert_eq(state.party.get_at(i).uid, original["party"][i]["uid"], "uid %d gardé" % i)


func test_a_v7_save_is_refused_by_the_v6_build_and_left_untouched() -> void:
	assert_eq(_save.write(_state_with_deposit().to_dict()), OK)
	var text: String = (_fs as MemoryFs).files[PATH]
	var old_build := SaveSystem.new(_fs, PATH)
	old_build.version = 6
	assert_eq(old_build.read(), {})
	assert_eq(old_build.last_status, ERR_INVALID_DATA, "la build du J11 (v6) refuse")
	assert_eq((_fs as MemoryFs).files[PATH], text, "fichier identique octet pour octet")
	assert_false((_fs as MemoryFs).files.has(PATH + SaveSystem.CORRUPT_SUFFIX),
		"pas mis de côté comme corrompu")


# --- Identifiants --------------------------------------------------------------------------

func test_an_uid_shared_by_the_party_and_the_daycare_is_regenerated_for_the_daycare() -> void:
	var state := _state_with_deposit()
	var dict: Dictionary = state.to_dict()
	var lead_uid: String = dict["party"][0]["uid"]
	dict["daycare"]["pokemon"]["uid"] = lead_uid
	dict["version"] = SaveSystem.VERSION
	var again := _load_through_save(dict)
	assert_eq(again.party.get_lead().uid, lead_uid, "l'équipe garde le sien")
	var kept_uid: String = again.daycare.pokemon.uid
	assert_true(PokemonUid.is_valid(kept_uid))
	assert_ne(kept_uid, lead_uid, "la Pension en reçoit un neuf")


func test_an_uid_shared_by_the_storage_and_the_daycare_is_regenerated_for_the_daycare() -> void:
	var state := _state_with_deposit()
	state.storage.add(PokemonFactory.create(_data, &"caterpie", 5, GameRng.new(3)))
	var dict: Dictionary = state.to_dict()
	var boxed_uid: String = dict["storage"][0]["uid"]
	dict["daycare"]["pokemon"]["uid"] = boxed_uid
	dict["version"] = SaveSystem.VERSION
	var again := _load_through_save(dict)
	assert_eq(again.storage.get_at(0).uid, boxed_uid, "le Stockage garde le sien")
	assert_ne(again.daycare.pokemon.uid, boxed_uid)


func test_a_daycare_pokemon_without_uid_gets_one_at_load() -> void:
	var state := _state_with_deposit()
	var dict: Dictionary = state.to_dict()
	(dict["daycare"]["pokemon"] as Dictionary).erase("uid")
	dict["version"] = SaveSystem.VERSION
	var again := _load_through_save(dict)
	assert_true(PokemonUid.is_valid(again.daycare.pokemon.uid), "identifiant attribué")


func test_ensure_unique_uids_covers_the_daycare() -> void:
	var state := _state_with_deposit()
	state.daycare.pokemon.uid = state.party.get_lead().uid
	assert_eq(state.ensure_unique_uids(), 1, "un seul réattribué")
	assert_ne(state.daycare.pokemon.uid, state.party.get_lead().uid)


# --- Pension invalide ----------------------------------------------------------------------

func test_an_invalid_daycare_pokemon_empties_the_daycare_and_is_reported() -> void:
	var state := _state_with_deposit()
	var dict: Dictionary = state.to_dict()
	dict["daycare"]["pokemon"]["species"] = "missingno"
	dict["version"] = SaveSystem.VERSION
	var again := _load_through_save(dict, false)
	assert_true(again.daycare.is_empty(), "Pension vide")
	assert_eq(again.party.size(), 1, "le reste de la partie est chargé")
	assert_eq(again.party.get_lead().species_id, &"charmander")
	assert_push_error_count(2, "Pokémon invalide puis Pension invalide")


func test_a_daycare_that_is_not_an_object_is_reported() -> void:
	var dict: Dictionary = _state().to_dict()
	dict["daycare"] = "Rattata"
	dict["version"] = SaveSystem.VERSION
	var again := _load_through_save(dict, false)
	assert_true(again.daycare.is_empty())
	assert_push_error("Pension mal formée")


func test_a_daycare_without_pokemon_is_simply_empty() -> void:
	var dict: Dictionary = _state().to_dict()
	dict["daycare"] = {"pending_exp": 300}
	dict["version"] = SaveSystem.VERSION
	var again := _load_through_save(dict)
	assert_true(again.daycare.is_empty(), "rien à perdre : Pension vide, sans refus")


# --- Compagnon -----------------------------------------------------------------------------

func test_a_deposited_companion_is_no_companion_after_reload() -> void:
	var state := _state()
	state.party.add(PokemonFactory.create(_data, &"charmander", 12, GameRng.new(1)))
	state.party.add(PokemonFactory.create(_data, &"pikachu", 10, GameRng.new(2)))
	assert_true(state.set_companion(state.party.get_at(1)))
	var uid: String = state.companion_uid
	assert_eq(DaycareRules.deposit(state.daycare, state.party, 1, _data),
		DaycareRules.Status.OK)
	assert_null(state.get_companion(), "déposé : plus de compagnon visible")
	# Même si l'identifiant est encore écrit (le directeur du T4 l'effacera au dépôt), la
	# relecture n'en fait pas un compagnon.
	var dict: Dictionary = state.to_dict()
	assert_eq(dict["companion"], uid)
	dict["version"] = SaveSystem.VERSION
	var again := _load_through_save(dict)
	assert_eq(again.companion_uid, "", "aucun compagnon après rechargement")
	assert_eq(again.daycare.pokemon.uid, uid, "le Pokémon déposé est bien là")


# --- Départ de débogage --------------------------------------------------------------------

func test_the_daycare_v7_qa_start_fills_the_daycare() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_START, _data, items), "\n".join(start.get_errors()))
	assert_true(start.autosave, "remplace la sauvegarde (QA 15.0)")
	var state := _state()
	start.apply(state, _data)
	assert_false(state.daycare.is_empty())
	assert_eq(state.daycare.pokemon.species_id, &"rattata")
	assert_eq(state.daycare.pokemon.level, 10)
	assert_eq(state.daycare.deposit_level, 10)
	assert_eq(state.daycare.pending_exp, 500)
	assert_true(PokemonUid.is_valid(state.daycare.pokemon.uid))
	assert_true(state.pokedex.is_caught(&"rattata"), "capturé au Pokédex")
	assert_eq(state.party.size(), 2)
	var again := _load_through_save(_written(state))
	assert_eq(again.daycare.pending_exp, 500, "relu après écriture")


func test_a_debug_daycare_is_validated_and_its_pending_exp_capped() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	var base := {"party": [{"species": "charmander", "level": 5}]}
	var bad := base.duplicate(true)
	bad["daycare"] = {"species": "rattata", "level": 10, "pending_exp": -1}
	assert_false(DebugStart.new().add_from_dict(bad, _data, items), "XP négative refusée")
	bad["daycare"] = {"species": "missingno", "level": 10}
	assert_false(DebugStart.new().add_from_dict(bad, _data, items), "espèce inconnue refusée")
	assert_push_error_count(2)
	var capped := base.duplicate(true)
	capped["daycare"] = {"species": "rattata", "level": 99, "pending_exp": 99_999_999}
	var start := DebugStart.new()
	assert_true(start.add_from_dict(capped, _data, items), "\n".join(start.get_errors()))
	var state := _state()
	start.apply(state, _data)
	assert_eq(state.daycare.pending_exp, state.daycare.exp_room, "bornée au niveau 100")
