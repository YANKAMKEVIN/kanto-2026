extends GutTest
## Départs de débogage du Chapitre Johto (JOH0, `jalon-joh0.md` §2.2) : clés « confiscated »
## (équipe et Sac confisqués, drapeaux de l'acte 1) et « cutscene » (scène jouée à l'arrivée) ;
## les trois fichiers de `tools/debug_start/` se lisent et s'appliquent.

const STATE_SCRIPT := preload("res://game/autoload/game_state.gd")
const FILES: Array[String] = [
	"res://tools/debug_start/johto_confiscated.json",
	"res://tools/debug_start/johto_confiscated_full.json",
	"res://tools/debug_start/johto_return.json",
]

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _apply(start: DebugStart) -> Node:
	var state: Node = autofree(STATE_SCRIPT.new())
	start.apply(state, _data)
	return state


func test_the_three_johto_starts_load_and_apply() -> void:
	for path: String in FILES:
		var start := DebugStart.new()
		assert_true(start.load_file(path, _data, _items), "%s : %s" % [path, start.get_errors()])
		var state := _apply(start)
		assert_false(state.confiscated.is_empty(), path)
		assert_true(state.flags.has_flag(TeamConfiscation.STORAGE_OFFLINE), path)
		assert_true(state.flags.has_flag(TeamConfiscation.ACT1), path)
		assert_true(state.flags.has_flag(&"johto_arrived"), path)
		for taken: Pokemon in state.confiscated.party:
			assert_true(PokemonUid.is_valid(taken.uid), "identifiant attribué")
			assert_true(state.pokedex.is_caught(taken.species_id), "capturé au Pokédex")
		assert_true(start.describe().contains("confisqués"), start.describe())


func test_confiscated_pokemon_items_and_the_cutscene_are_read() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(FILES[2], _data, _items), str(start.get_errors()))
	assert_eq(start.cutscene, &"johto_return_test")
	var state := _apply(start)
	assert_eq(state.party.size(), 2)
	assert_eq(state.confiscated.party.size(), 5)
	assert_eq(state.confiscated.party[2].hp, 0, "Rattatac K.O.")
	assert_eq(state.confiscated.items, {&"great_ball": 7, &"super_potion": 4, &"tm28": 1}
		as Dictionary[StringName, int])
	assert_eq(state.bag.count_of(&"poke_ball"), 6)
	assert_eq(state.money, 12000)
	assert_true(start.describe().contains("scène : johto_return_test"))
	var full := DebugStart.new()
	assert_true(full.load_file(FILES[1], _data, _items))
	var full_state := _apply(full)
	assert_true(full_state.party.is_full())
	assert_true(CaptureGate.blocks(full_state.party, full_state.flags), "Ball refusée")
	assert_eq(full.cutscene, &"")


func test_invalid_confiscated_sections_and_cutscenes_are_refused() -> void:
	var base := {"party": [{"species": "squirtle", "level": 5}]}
	var bad: Array = [
		{"confiscated": "texte"},
		{"confiscated": {}},
		{"confiscated": {"party": [], "items": {}}},
		{"confiscated": {"party": [{"species": "missingno", "level": 5}]}},
		{"confiscated": {"items": {"potion": 0}}},
		{"confiscated": {"items": {"objet_inconnu": 1}}},
		{"confiscated": {"party": [], "extra": 1}},
		{"cutscene": ""},
		{"cutscene": 3},
	]
	for extra: Dictionary in bad:
		var dict := base.duplicate(true)
		dict.merge(extra)
		var start := DebugStart.new()
		assert_false(start.add_from_dict(dict, _data, _items, "bad"), str(extra))
	assert_push_error_count(bad.size(), "une erreur par départ refusé")
	assert_true(DebugStart.new().add_from_dict(base, _data, _items, "ok"))
