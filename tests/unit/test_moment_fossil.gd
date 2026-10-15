extends GutTest
## Grand moment « fossil » (jalon 12, T23 ; `jalon-12.md` §2.13, annexe A.5, dossier 15 §20
## n° 30) : type de [MomentLibrary] (en fin de liste), marque {fossil} réservée à ce type, texte
## validé (« La Team Rocket repoussée » / « {fossil} obtenu. ») ; l'écran Dresseur
## ([TrainerSummary]) lit le nom du fossile dans les objets et le lieu dans les zones : « Mont
## Sélénite : la Team Rocket repoussée, Fossile Dôme obtenu. ».

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

var _data: PokemonData
var _zones: ZoneLibrary
var _moments: MomentLibrary
var _items: ItemLibrary
var _state: Node


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()
	_moments = MomentLibrary.new()
	assert_true(_moments.load_file(), "\n".join(_moments.get_errors()))
	_items = ItemLibrary.new()
	_items.load_dir()


func before_each() -> void:
	_state = GameStateScript.new()
	_state.clock = FixedClock.new("2026-10-13T10:00:00")
	_state.new_game(7)


func after_each() -> void:
	_state.free()


func test_type_is_appended_last() -> void:
	# Jalon 14 : `bill_restored` vient après lui (ajouts en fin).
	assert_eq(MomentLibrary.TYPES.back(), MomentLibrary.BILL_RESTORED, "ajout en fin")
	assert_eq(MomentLibrary.TYPES.find(MomentLibrary.FOSSIL),
		MomentLibrary.TYPES.find(MomentLibrary.BADGE) + 1)
	assert_eq(MomentLibrary.MARK_FOSSIL, "{fossil}")


func test_real_text_is_the_validated_one() -> void:
	var text := _moments.get_text(MomentLibrary.FOSSIL)
	assert_not_null(text)
	assert_eq(text.title, "La Team Rocket repoussée")
	assert_eq(text.detail, "{fossil} obtenu.")
	assert_false(text.draft, "texte validé (annexe A.5)")


func test_fossil_mark_is_only_for_the_fossil_moment() -> void:
	var data := {
		"moments": {
			"starter": {"title": "P", "detail": "{fossil}"},
			"rival_battle": {"title": "R"},
			"first_capture": {"title": "C"},
			"zone_arrival": {"title": "{zone}"},
			"badge": {"title": "{badge}"},
			"fossil": {"title": "{fossil} à {zone}"},
			"bill_restored": {"title": "L"},
		},
	}
	var library := MomentLibrary.new()
	assert_false(library.add_from_dict(data, "t"))
	assert_string_contains("\n".join(library.get_errors()), "moment « starter » : marque « {fossil} »")
	assert_eq(library.get_text(MomentLibrary.FOSSIL).title, "{fossil} à {zone}", "permise ici")
	assert_push_error_count(2, "la marque, puis le texte écarté")


func _view(items: ItemLibrary) -> Array[MomentView]:
	return TrainerSummary.moment_views(_state, _data, _zones, _moments,
		MenuUnlocks.new(_state.flags, _state.party), null, items)


func test_trainer_screen_line() -> void:
	_state.record_moment(MomentLibrary.FOSSIL, &"mt_moon_b2f", {"item": "dome_fossil"})
	var views := _view(_items)
	assert_eq(views.size(), 1)
	var moment := views[0]
	assert_eq(moment.kind, MomentLibrary.FOSSIL)
	assert_eq(moment.title, "La Team Rocket repoussée")
	assert_eq(moment.detail, "Fossile Dôme obtenu.")
	assert_eq(moment.place, "Mont Sélénite", "nom de la zone, comme le badge")
	assert_eq(moment.zone_id, &"mt_moon")
	assert_eq(moment.date_text, "13 octobre 2026")
	assert_eq("%s : la Team Rocket repoussée, %s" % [moment.place, moment.detail],
		"Mont Sélénite : la Team Rocket repoussée, Fossile Dôme obtenu.", "texte n° 30")
	_state.record_moment(MomentLibrary.FOSSIL, &"mt_moon_b2f", {"item": "helix_fossil"})
	assert_eq(_view(_items)[1].detail, "Fossile Nautile obtenu.")


func test_without_items_or_unknown_item_the_moment_is_skipped() -> void:
	_state.record_moment(MomentLibrary.FOSSIL, &"mt_moon_b2f", {"item": "dome_fossil"})
	assert_eq(_view(null).size(), 0, "sans objets : ignoré")
	_state.moments.clear()
	_state.record_moment(MomentLibrary.FOSSIL, &"mt_moon_b2f", {"item": "old_amber"})
	assert_eq(_view(_items).size(), 0, "objet inconnu : ignoré")
	_state.moments.clear()
	_state.record_moment(MomentLibrary.FOSSIL, &"mt_moon_b2f", {})
	assert_eq(_view(_items).size(), 0, "sans objet : ignoré")


func test_build_passes_the_items() -> void:
	_state.record_moment(MomentLibrary.FOSSIL, &"mt_moon_b2f", {"item": "dome_fossil"})
	var view := TrainerSummary.build(_state, _data, _zones, _moments,
		MenuUnlocks.new(_state.flags, _state.party), null, _items)
	assert_eq(view.moments.size(), 1)
	assert_eq(view.moments[0].detail, "Fossile Dôme obtenu.")
