extends GutTest
## Légende de la toute première sortie (OUV.3, dossier 13 A12 et §8 point 8) : données réelles,
## règle « première » déduite des cartes découvertes, arrivée par la porte de la maison
## seulement, validation stricte.

const LEGEND := "Le commencement de toute aventure"
const LAVENDER := "La ville où reposent les souvenirs"

var _caption: FirstExitCaption


func before_each() -> void:
	_caption = FirstExitCaption.new()


func _discovered(maps: Array[StringName]) -> Dictionary:
	var discovered: Dictionary[StringName, String] = {}
	for map: StringName in maps:
		discovered[map] = "2026-10-11T09:00:00"
	return discovered


func test_the_real_file_loads_the_validated_text() -> void:
	assert_true(_caption.load_file())
	assert_eq(_caption.get_errors().size(), 0)
	assert_eq(_caption.get_map(), &"pallet_town")
	var fresh := _discovered([&"player_house_2f", &"player_house_1f"])
	assert_eq(_caption.subtitle_for(&"pallet_town", &"player_house_1f", fresh, "Kanto"), LEGEND)


func test_the_first_exit_of_a_new_game_shows_the_legend() -> void:
	_caption.load_file()
	assert_true(_caption.is_first_exit(&"pallet_town", &"player_house_1f",
		_discovered([&"player_house_2f", &"player_house_1f"])))


func test_once_pallet_town_is_discovered_the_region_comes_back() -> void:
	_caption.load_file()
	var known := _discovered([&"player_house_2f", &"player_house_1f", &"pallet_town"])
	assert_false(_caption.is_first_exit(&"pallet_town", &"player_house_1f", known))
	assert_eq(_caption.subtitle_for(&"pallet_town", &"player_house_1f", known, "Kanto"), "Kanto")


func test_a_start_or_a_resume_never_shows_the_legend() -> void:
	_caption.load_file()
	assert_eq(_caption.subtitle_for(&"pallet_town", &"", _discovered([]), "Kanto"), "Kanto",
		"démarrage, reprise ou départ de débogage : aucune carte quittée")


func test_arriving_from_elsewhere_or_somewhere_else_keeps_the_region() -> void:
	_caption.load_file()
	var fresh := _discovered([])
	assert_eq(_caption.subtitle_for(&"pallet_town", &"route_1", fresh, "Kanto"), "Kanto",
		"arrivée par la Route 1 (départ de débogage plus loin)")
	assert_eq(_caption.subtitle_for(&"route_1", &"player_house_1f", fresh, "Kanto"), "Kanto")
	assert_eq(_caption.subtitle_for(&"oak_lab", &"pallet_town", fresh, ""), "")


func test_an_invalid_file_is_not_applied() -> void:
	assert_false(_caption.add_from_dict({"map": "pallet_town", "from": "player_house_1f"},
		"test"))
	assert_false(_caption.add_from_dict({"map": "pallet_town", "from": "player_house_1f",
		"subtitle": "", "oops": 1}, "test"))
	assert_push_error_count(3)
	assert_false(_caption.is_loaded())
	assert_eq(_caption.subtitle_for(&"pallet_town", &"player_house_1f", _discovered([]),
		"Kanto"), "Kanto")
	assert_eq(_caption.get_errors().size(), 3, "texte manquant, texte vide, clé inconnue")


func test_a_missing_file_is_reported() -> void:
	assert_false(_caption.load_file("res://data/opening/absent.json"))
	assert_push_error_count(1)
	assert_false(_caption.is_loaded())


# --- Jalon 18 (T24) : forme liste, Lavanville ---

func test_the_real_file_holds_pallet_town_and_lavender() -> void:
	assert_true(_caption.load_file())
	var fresh := _discovered([&"route_10"])
	assert_eq(_caption.subtitle_for(&"lavender_town", &"route_10", fresh, "Kanto"), LAVENDER)
	assert_eq(_caption.subtitle_for(&"pallet_town", &"player_house_1f", _discovered([]),
		"Kanto"), LEGEND, "Bourg Palette inchangé")


func test_lavender_legend_once_and_never_at_a_start_or_a_resume() -> void:
	_caption.load_file()
	var fresh := _discovered([&"route_10"])
	assert_true(_caption.is_first_exit(&"lavender_town", &"route_10", fresh))
	assert_eq(_caption.subtitle_for(&"lavender_town", &"", fresh, "Kanto"), "Kanto",
		"démarrage, reprise, départ de débogage")
	var known := _discovered([&"route_10", &"lavender_town"])
	assert_eq(_caption.subtitle_for(&"lavender_town", &"route_10", known, "Kanto"), "Kanto",
		"seconde arrivée")
	assert_eq(_caption.subtitle_for(&"lavender_town", &"pokemon_tower_1f", fresh, "Kanto"),
		"Kanto", "arrivée par une porte : pas de légende")


func test_list_form_is_validated_entry_by_entry() -> void:
	assert_false(_caption.add_from_dict({"arrivals": []}, "test"))
	assert_false(_caption.add_from_dict({"arrivals": [
		{"map": "a", "from": "b", "subtitle": "c"}, {"map": "a", "from": "b"}]}, "test"))
	assert_false(_caption.add_from_dict({"arrivals": [3]}, "test"))
	assert_push_error_count(3)
	assert_false(_caption.is_loaded(), "tout ou rien")
	assert_true(_caption.add_from_dict({"arrivals": [
		{"map": "a", "from": "b", "subtitle": "c"}]}, "test"))
	assert_eq(_caption.subtitle_for(&"a", &"b", {}, "r"), "c")
