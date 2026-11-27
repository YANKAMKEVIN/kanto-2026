extends GutTest
## PC de Johto (demande de Kevin du 2026-11-27) : sauvegarde **v11**. Pendant l'acte 1, le
## Stockage de Kanto est mis de côté dans « confiscated.storage » et le Stockage du joueur sert de
## Boîte de Johto. Migration 10 → 11 : une partie en plein acte 1 voit son Stockage de Kanto
## passer dans la section (mêmes Pokémon, même ordre) ; toute autre partie ne change pas ; une
## build v10 refuse la v11 (elle perdrait le Stockage de Kanto au premier autosave).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_johto_box.json"

var _fs: MemoryFs
var _save: SaveSystem
var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "objets")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-11-27T10:00:00")
	state.new_game(11)
	return state


func _json(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _uids(members: Array) -> Array:
	var result: Array = []
	for member: Variant in members:
		result.append(member.uid if member is Pokemon else member["uid"])
	return result


## Partie de Kanto : 3 Pokémon dans l'équipe, 3 au Stockage.
func _kanto_state() -> Node:
	var state := _state()
	for species: StringName in [&"charizard", &"pidgeot", &"raticate"]:
		state.party.add(PokemonFactory.create(_data, species, 50, GameRng.new(species.hash())))
	for species: StringName in [&"caterpie", &"weedle", &"oddish"]:
		state.storage.add(PokemonFactory.create(_data, species, 10, GameRng.new(species.hash())))
	state.bag.add(&"potion", 2)
	return state


## Fichier v10 tel que l'écrivait la build d'avant : acte 1 en cours, Stockage de Kanto encore
## dans « storage ».
func _v10_act1_content() -> Dictionary:
	var state := _kanto_state()
	var kanto_box: Array = state.storage.to_array()
	assert_true(TeamConfiscation.confiscate(state, _items))
	state.party.add(PokemonFactory.create(_data, &"squirtle", 12, GameRng.new(3)))
	var content: Dictionary = _json(state.to_dict())
	(content["confiscated"] as Dictionary).erase("storage")
	content["storage"] = _json(kanto_box)
	content["version"] = 10
	return content


func test_the_format_is_v11() -> void:
	assert_eq(SaveSystem.VERSION, 11, "v11 : PC de Johto (Stockage de Kanto mis de côté)")
	assert_eq(SaveSystem.migration_note(10, 11), "sauvegarde v10 → v11")


func test_a_v10_save_in_act_1_moves_its_kanto_storage_aside() -> void:
	var content := _v10_act1_content()
	var kanto_box: Array = _uids(content["storage"])
	assert_eq(kanto_box.size(), 3)
	assert_eq(SaveSystem.upgrade(content), OK)
	assert_eq(int(content["version"]), 11)
	assert_eq(content["storage"], [], "la Boîte de Johto démarre vide")
	assert_eq(_uids(content["confiscated"]["storage"]), kanto_box, "mêmes Pokémon, même ordre")
	_fs.files[PATH] = JSON.stringify(_v10_act1_content())
	var state := _state()
	assert_true(state.load_dict(_save.read(), _data), "chargée sans entrée écartée")
	assert_eq(_save.read_version, 10)
	assert_eq(state.storage.size(), 0)
	assert_eq(state.confiscated.storage.size(), 3)
	assert_true(TeamConfiscation.is_storage_offline(state.flags))


func test_a_v10_save_outside_act_1_is_unchanged() -> void:
	var state := _kanto_state()
	var content: Dictionary = _json(state.to_dict())
	content["version"] = 10
	var expected: Dictionary = content.duplicate(true)
	expected["version"] = 11
	assert_eq(SaveSystem.upgrade(content), OK)
	assert_eq(_json(content), _json(expected), "seul le numéro change")


func test_a_section_that_already_has_a_storage_is_not_touched() -> void:
	var content := _v10_act1_content()
	(content["confiscated"] as Dictionary)["storage"] = []
	var before: Array = (content["storage"] as Array).duplicate(true)
	assert_eq(SaveSystem.upgrade(content), OK)
	assert_eq(content["storage"], before, "fichier retouché : rien ne bouge")


func test_a_v10_build_refuses_a_v11_save() -> void:
	var state := _kanto_state()
	assert_true(TeamConfiscation.confiscate(state, _items))
	assert_eq(_save.write(state.to_dict()), OK)
	var text: String = _fs.files[PATH]
	var old_build := SaveSystem.new(_fs, PATH)
	old_build.version = 10
	assert_eq(old_build.read(), {})
	assert_eq(old_build.last_status, ERR_INVALID_DATA)
	assert_eq(_fs.files[PATH], text, "fichier intact")


func test_an_invalid_kanto_storage_is_reported_never_lost_silently() -> void:
	var state := _kanto_state()
	assert_true(TeamConfiscation.confiscate(state, _items))
	var content: Dictionary = _json(state.to_dict())
	content["confiscated"]["storage"] = "pas une liste"
	assert_null(ConfiscatedTeam.from_dict(content["confiscated"], _data))
	content["confiscated"]["storage"] = [{"species": "espece_inconnue"}]
	assert_null(ConfiscatedTeam.from_dict(content["confiscated"], _data))
	assert_push_error_count(3, "« storage » pas une liste ; espèce inconnue puis Pokémon refusé")


func test_kanto_storage_uids_stay_unique() -> void:
	var state := _kanto_state()
	assert_true(TeamConfiscation.confiscate(state, _items))
	var twin := PokemonFactory.create(_data, &"rattata", 5, GameRng.new(8))
	state.storage.add(twin)
	twin.uid = state.confiscated.storage[0].uid
	assert_eq(state.ensure_unique_uids(), 1, "le doublon reçoit un nouvel identifiant")
	assert_ne(twin.uid, state.confiscated.storage[0].uid)
