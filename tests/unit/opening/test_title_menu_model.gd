extends GutTest
## Écran titre (dossier 13 §5.2, §5.4) : TitleTexts, SaveSummary (lu dans le vrai dictionnaire
## de sauvegarde) et TitleMenuModel pour les quatre états.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
## Vraie partie de Kevin en fin de J7 (v3, migrée en v4 à la lecture).
const FIXTURE_V3 := "res://tests/fixtures/save/v3_kevin_j7_fin.json"
const S := OpeningFlow.SaveStatus
const CORRUPT_TEXT := "La sauvegarde n'a pas pu être lue. Une copie a été mise de côté."
const NEWER_TEXT := \
	"Cette sauvegarde vient d'une version plus récente du jeu. Elle n'a pas été modifiée."
const CONFIRM_BODY := "Commencer une nouvelle partie remplacera cette aventure lorsque tu " \
	+ "arriveras dans ta chambre."

var _texts: TitleTexts
var _zones: ZoneLibrary
var _badge_flags: Array[StringName] = []


func before_all() -> void:
	_texts = TitleTexts.new()
	assert_true(_texts.load_file(), str(_texts.get_errors()))
	_zones = ZoneLibrary.new()
	assert_true(_zones.load_file(), "zones")
	var badges := BadgeLibrary.new()
	assert_true(badges.load_file(), "badges")
	for id: StringName in badges.ids():
		_badge_flags.append(badges.flag(id))


func _summary_of(save: Dictionary) -> SaveSummary:
	return SaveSummary.from_save(save, _zones.zone_name_of, _badge_flags, "Kevin")


## Dictionnaire écrit par un vrai GameState (mêmes clés que la sauvegarde).
func _state_dict() -> Dictionary:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new()
	state.new_game(7)
	state.player_name = "Sacha"
	state.current_map = &"pallet_town"
	state.play_time = 3 * 3600.0 + 25 * 60.0 + 59.0
	state.flags.set_flag(&"badge_boulder")
	state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	state.record_caught(&"pidgey", &"route_1")
	state.record_caught(&"rattata", &"route_1")
	state.record_seen(&"spearow", &"route_22")
	return state.to_dict()


# --- TitleTexts ---------------------------------------------------------------------------

func test_title_texts_validated() -> void:
	assert_eq(_texts.text(TitleTexts.GROUP_MESSAGES, &"corrupt"), CORRUPT_TEXT)
	assert_eq(_texts.text(TitleTexts.GROUP_MESSAGES, &"newer"), NEWER_TEXT)
	assert_eq(_texts.text(TitleTexts.GROUP_CONFIRM, &"title"), "Une aventure est déjà en cours.")
	assert_eq(_texts.text(TitleTexts.GROUP_CONFIRM, &"body"), CONFIRM_BODY)
	assert_eq(_texts.text(TitleTexts.GROUP_ENTRIES, &"new_game"), "Nouvelle partie")


func test_title_texts_strict() -> void:
	var good := {
		"entries": {"continue": "C", "new_game": "N", "settings": "P"},
		"messages": {"corrupt": "c", "newer": "n", "unsaved": "u"},
		"confirm": {"title": "t", "body": "b", "cancel": "a", "confirm": "o"},
	}
	assert_true(TitleTexts.new().add_from_dict(good.duplicate(true)))
	var unknown := good.duplicate(true)
	unknown["extra"] = {}
	assert_false(TitleTexts.new().add_from_dict(unknown), "groupe inconnu")
	var typo := good.duplicate(true)
	typo["messages"]["corupt"] = "x"
	assert_false(TitleTexts.new().add_from_dict(typo), "clé inconnue")
	var missing := good.duplicate(true)
	(missing["confirm"] as Dictionary).erase("cancel")
	var texts := TitleTexts.new()
	assert_false(texts.add_from_dict(missing), "clé manquante")
	assert_false(texts.is_loaded(), "tout ou rien")
	var empty := good.duplicate(true)
	empty["entries"]["settings"] = ""
	assert_false(TitleTexts.new().add_from_dict(empty), "texte vide")


# --- SaveSummary ------------------------------------------------------------------------

func test_summary_from_game_state_dict() -> void:
	var summary := _summary_of(_state_dict())
	assert_eq(summary.player_name, "Sacha")
	assert_eq(summary.map_id, &"pallet_town")
	assert_eq(summary.zone_name, _zones.zone_name_of(&"pallet_town"))
	assert_false(summary.zone_name.is_empty())
	assert_eq(summary.play_time_text(), "3 h 25")
	assert_eq(summary.badge_count, 1)
	assert_eq(summary.badges_text(), "1 badge")
	assert_eq(summary.caught_count, 2, "Piafabec vu seulement")
	assert_eq(summary.caught_text(), "2 capturés")


func test_summary_of_real_kevin_save() -> void:
	var fs := MemoryFs.new()
	fs.files["user://save.json"] = FileAccess.get_file_as_string(FIXTURE_V3)
	var save := SaveSystem.new(fs, "user://save.json")
	var data := save.read()
	assert_eq(save.last_status, OK)
	var summary := _summary_of(data)
	assert_eq(summary.player_name, "Kevin")
	assert_eq(summary.map_id, &"viridian_center")
	assert_eq(summary.zone_name, _zones.zone_name_of(&"viridian_center"))
	assert_eq(summary.play_time_text(), "20 h 12")
	assert_eq(summary.badge_count, 0)
	assert_eq(summary.badges_text(), "")
	assert_true(summary.pokedex_active)
	assert_eq(summary.caught_count, 4)


func test_summary_hides_captures_before_pokedex() -> void:
	var save := _state_dict()
	save["flags"] = []
	var summary := _summary_of(save)
	assert_eq(summary.caught_count, 2)
	assert_eq(summary.caught_text(), "", "Pokédex pas encore activé")
	assert_eq(summary.badges_text(), "")


func test_summary_tolerates_broken_fields() -> void:
	var summary := SaveSummary.from_save({"player_name": 3, "map": [], "play_time": "x",
		"flags": "badge_boulder", "pokedex": {"entries": {"pidgey": "oui"}}},
		_zones.zone_name_of, _badge_flags, "Kevin")
	assert_eq(summary.player_name, "Kevin", "repli")
	assert_eq(summary.zone_name, "")
	assert_eq(summary.play_time, 0.0)
	assert_eq(summary.badge_count, 0)
	assert_eq(summary.caught_count, 0)


func test_summary_without_zone_callable() -> void:
	var summary := SaveSummary.from_save(_state_dict())
	assert_eq(summary.zone_name, "")
	assert_eq(summary.badge_count, 0, "aucun drapeau de badge donné")


# --- TitleMenuModel ---------------------------------------------------------------------

func test_no_save() -> void:
	var model := TitleMenuModel.build(S.NONE, null, _texts)
	assert_eq(model.entries, [TitleMenuModel.ENTRY_NEW_GAME, TitleMenuModel.ENTRY_SETTINGS]
		as Array[StringName])
	assert_eq(model.featured, TitleMenuModel.ENTRY_NEW_GAME)
	assert_eq(model.message, "")
	assert_false(model.new_game_needs_confirmation)
	assert_false(model.new_game_unsaved)
	assert_null(model.summary)


func test_valid_save() -> void:
	var summary := _summary_of(_state_dict())
	var model := TitleMenuModel.build(S.VALID, summary, _texts)
	assert_eq(model.entries, [TitleMenuModel.ENTRY_CONTINUE, TitleMenuModel.ENTRY_NEW_GAME,
		TitleMenuModel.ENTRY_SETTINGS] as Array[StringName])
	assert_eq(model.featured, TitleMenuModel.ENTRY_CONTINUE)
	assert_eq(model.message, "")
	assert_true(model.new_game_needs_confirmation)
	assert_eq(model.summary, summary)
	assert_eq(model.labels[TitleMenuModel.ENTRY_CONTINUE], "Continuer")
	assert_eq(model.labels[TitleMenuModel.ENTRY_SETTINGS], "Paramètres")


func test_valid_save_confirmation_card() -> void:
	var model := TitleMenuModel.build(S.VALID, _summary_of(_state_dict()), _texts)
	assert_eq(model.confirm_title, "Une aventure est déjà en cours.")
	assert_eq(model.confirm_summary, "Sacha · 3 h 25 · 1 badge")
	assert_eq(model.confirm_body, CONFIRM_BODY)
	assert_eq(model.confirm_cancel, "Annuler")
	assert_eq(model.confirm_accept, "Nouvelle partie")


func test_confirmation_summary_omits_missing_badges() -> void:
	var save := _state_dict()
	save["flags"] = []
	assert_eq(TitleMenuModel.summary_line(_summary_of(save)), "Sacha · 3 h 25")
	assert_eq(TitleMenuModel.summary_line(null), "")


func test_corrupt_save() -> void:
	var model := TitleMenuModel.build(S.CORRUPT, null, _texts)
	assert_false(model.entries.has(TitleMenuModel.ENTRY_CONTINUE))
	assert_eq(model.featured, TitleMenuModel.ENTRY_NEW_GAME)
	assert_eq(model.message, CORRUPT_TEXT)
	assert_false(model.new_game_needs_confirmation)
	assert_false(model.new_game_unsaved)
	assert_eq(model.confirm_title, "")


func test_newer_save() -> void:
	var model := TitleMenuModel.build(S.NEWER, null, _texts)
	assert_false(model.entries.has(TitleMenuModel.ENTRY_CONTINUE))
	assert_eq(model.featured, TitleMenuModel.ENTRY_NEW_GAME)
	assert_eq(model.message, NEWER_TEXT)
	assert_true(model.new_game_unsaved)
	assert_false(model.new_game_needs_confirmation)


func test_summary_ignored_unless_valid() -> void:
	var summary := _summary_of(_state_dict())
	for status: OpeningFlow.SaveStatus in [S.NONE, S.CORRUPT, S.NEWER]:
		assert_null(TitleMenuModel.build(status, summary, _texts).summary)


func test_model_agrees_with_flow() -> void:
	for status: OpeningFlow.SaveStatus in [S.NONE, S.VALID, S.CORRUPT, S.NEWER]:
		var model := TitleMenuModel.build(status, null, _texts)
		var flow := OpeningFlow.new(status)
		assert_eq(model.entries.has(TitleMenuModel.ENTRY_CONTINUE), flow.can_continue())
		assert_eq(model.new_game_needs_confirmation, flow.needs_confirmation())
		assert_eq(model.new_game_unsaved, not flow.writes_allowed())
