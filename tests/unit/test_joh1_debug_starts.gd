extends GutTest
## Départs de débogage du jalon JOH1 (`jalon-joh1.md` §2.9) : les six fichiers se lisent et
## s'appliquent ; `johto_orme` a une équipe **vide** (permise avec « confiscated ») ;
## `johto_olivine_day` a Kaiminus, les dons d'Orme et le point de repos d'Oliville.

const STATE_SCRIPT := preload("res://game/autoload/game_state.gd")
const DIR := "res://tools/debug_start/"
const FILES: Array[String] = ["johto_letter", "johto_sea_cave", "johto_olivine_arrival",
	"johto_olivine_night", "johto_orme", "johto_olivine_day"]

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _load(name: String) -> DebugStart:
	var start := DebugStart.new()
	assert_true(start.load_file(DIR + name + ".json", _data, _items),
		"%s : %s" % [name, start.get_errors()])
	return start


func _apply(start: DebugStart) -> Node:
	var state: Node = autofree(STATE_SCRIPT.new())
	start.apply(state, _data)
	return state


func test_the_six_starts_load_apply_and_point_at_existing_spawns() -> void:
	for name: String in FILES:
		var start := _load(name)
		var state := _apply(start)
		assert_true(state.flags.has_flag(&"league_champion_defeated"), name)
		assert_true(MapCatalog.has_map(start.map), "%s : carte %s" % [name, start.map])
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
		assert_true(map.has_spawn(start.spawn), "%s : arrivée %s sur %s" % [name, start.spawn,
			start.map])
		map.free()


func test_the_morning_start_has_an_empty_team_and_the_confiscated_one() -> void:
	var start := _load("johto_orme")
	var state := _apply(start)
	assert_eq(state.party.size(), 0, "aucun Pokémon avant Orme")
	assert_eq(state.confiscated.party.size(), 6)
	assert_true(state.flags.has_flag(&"johto_team_stolen"))
	assert_true(state.flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	assert_true(state.flags.has_flag(TeamConfiscation.ACT1))
	assert_eq(JohtoPeriodRule.forced_period(state.flags), &"morning")
	assert_eq(state.heal_map, &"olivine_center", "point de repos d'Oliville")


func test_an_empty_team_without_confiscation_is_still_refused() -> void:
	var start := DebugStart.new()
	assert_false(start.add_from_dict({"party": []}, _data, _items, "t"))
	assert_push_error_count(1)


func test_the_day_start_is_after_the_choice() -> void:
	var start := _load("johto_olivine_day")
	var state := _apply(start)
	assert_eq(state.party.size(), 1)
	assert_eq(state.party.get_at(0).species_id, &"totodile")
	assert_eq(state.bag.count_of(&"poke_ball"), 5)
	assert_eq(state.bag.count_of(&"potion"), 1)
	assert_true(state.flags.has_flag(&"johto_orme_left"))
	assert_eq(JohtoPeriodRule.forced_period(state.flags), &"", "heure réelle après Orme")
	assert_eq(start.period, &"day", "moment imposé par le départ")
	assert_eq(StarterChoice.taken_flag(&"totodile"), &"taken_totodile")
	assert_true(state.flags.has_flag(&"taken_totodile"))


func test_the_night_start_is_before_the_theft() -> void:
	var start := _load("johto_olivine_night")
	var state := _apply(start)
	assert_eq(state.party.size(), 6)
	assert_true(state.confiscated.is_empty())
	assert_eq(JohtoPeriodRule.forced_period(state.flags), &"night")
