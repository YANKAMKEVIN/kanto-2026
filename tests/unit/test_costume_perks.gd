extends GutTest
## Avantages des costumes (docs/design/dossier-costumes.md, CO-12 à CO-15) : actifs seulement si
## le costume est porté, écrits pour le joueur, sans effet sur la tenue d'origine.

const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")


func _state_wearing(costume: StringName) -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-11-07T20:00:00")
	state.new_game(9)
	if not costume.is_empty():
		var catalog := CostumeCatalog.shared()
		state.flags.set_flag(catalog.badges.flag(catalog.badge_of(costume)))
		assert_true(state.wear_costume(costume))
	return state


func _table() -> EncounterTable:
	var table := EncounterTable.new()
	table.rate = 100
	table.slots = [
		EncounterSlot.new(&"pidgey", 2, 2, 95),
		EncounterSlot.new(&"pikachu", 2, 2, 5),
	] as Array[EncounterSlot]
	return table


func _count_rare(rare_factor: float) -> int:
	var rng := GameRng.new(7)
	var table := _table()
	var rare := 0
	for i: int in 4000:
		if table.pick(rng, rare_factor).species == &"pikachu":
			rare += 1
	return rare


func test_every_costume_has_a_written_perk() -> void:
	var catalog := CostumeCatalog.shared()
	assert_eq(catalog.size(), 8)
	for id: StringName in catalog.ids():
		assert_true(catalog.perk_text(id).contains(" : "), "avantage écrit : %s" % id)


func test_perk_is_active_only_when_worn() -> void:
	var key := CostumeCatalog.EFFECT_PRIZE
	assert_eq(CostumeCatalog.worn_effect(_state_wearing(&"thunder"), key, 1.0), 1.2)
	assert_eq(CostumeCatalog.worn_effect(_state_wearing(&"soul"), key, 1.0), 1.0)
	assert_eq(CostumeCatalog.worn_effect(_state_wearing(&""), key, 1.0), 1.0)


func test_locked_costume_gives_nothing() -> void:
	var state := _state_wearing(&"")
	state.player_costume = &"thunder"
	assert_eq(CostumeCatalog.worn_effect(state, CostumeCatalog.EFFECT_PRIZE, 1.0), 1.0)


func test_state_without_costumes_uses_fallback() -> void:
	assert_eq(CostumeCatalog.worn_effect(null, CostumeCatalog.EFFECT_PRIZE, 1.0), 1.0)
	assert_eq(CostumeCatalog.worn_effect(RefCounted.new(), CostumeCatalog.EFFECT_PRIZE, 1.0), 1.0)


func test_unknown_effect_is_rejected() -> void:
	var catalog := CostumeCatalog.new()
	var entry := {"id": "x", "badge": "boulder", "art": "x",
		"names": {"hero": "A", "heroine": "B"},
		"perk": {"name": "N", "text": "T", "effects": {"vol": 2}}}
	assert_false(catalog.add_from_array([entry]))
	assert_push_error("effet inconnu")
	assert_eq(catalog.size(), 0)


func test_slot_views_hide_perk_of_locked_costumes() -> void:
	var views := TrainerSummary.costume_views(_state_wearing(&"marsh"), CostumeCatalog.shared())
	assert_eq(views[0].perk, TrainerView.ORIGINAL_COSTUME_PERK)
	for view: CostumeSlotView in views.slice(1):
		assert_eq(view.perk.is_empty(), not view.unlocked)


func test_rate_factor_lowers_encounters_but_never_to_zero() -> void:
	var table := _table()
	table.rate = 1
	var rng := GameRng.new(3)
	var met := 0
	for i: int in 20000:
		if table.roll(rng, 0, 0.1) != null:
			met += 1
	assert_gt(met, 0)


func test_rare_factor_boosts_rare_slots_only_when_asked() -> void:
	assert_gt(_count_rare(1.5), _count_rare(1.0))


func test_reduced_sight() -> void:
	assert_eq(TrainerRules.reduced_sight(4, 0.5), 2)
	assert_eq(TrainerRules.reduced_sight(3, 0.5), 2)
	assert_eq(TrainerRules.reduced_sight(1, 0.5), 1)
	assert_eq(TrainerRules.reduced_sight(0, 0.5), 0)
	assert_eq(TrainerRules.reduced_sight(4, 1.0), 4)


func test_prize_factor() -> void:
	var trainer := TrainerData.new()
	trainer.prize_money = 120
	var win := BattleConclusion.resolve(trainer, Battle.Outcome.WIN, 0, 0, 1.2)
	assert_eq(win.prize_money, 144)


func test_sense_text_and_radius() -> void:
	var cells: Array[Vector2i] = [Vector2i(5, 2)]
	assert_eq(Itemfinder.nearest(cells, Vector2i(2, 2), 3), Vector2i(5, 2))
	assert_eq(Itemfinder.nearest(cells, Vector2i(1, 2), 3), Vector2i(-1, -1))
	assert_eq(Itemfinder.sense_text(Vector2i(2, 2), Vector2i(5, 2)),
		Itemfinder.SENSE_FORMAT % "à l'est")


func test_hint_texts() -> void:
	assert_eq(BattleViews.hint_for(2.0), BattleViews.HINT_SUPER)
	assert_eq(BattleViews.hint_for(0.5), BattleViews.HINT_WEAK)
	assert_eq(BattleViews.hint_for(0.0), BattleViews.HINT_NONE)
	assert_eq(BattleViews.hint_for(1.0), "")


func test_move_card_shows_hint_after_power() -> void:
	var view := BattleMoveView.new("Griffe", &"normal", "Normal",
		BattleMoveView.Category.PHYSICAL, 10, 10, 40, 100, "")
	view.hint = BattleViews.HINT_SUPER
	assert_eq(MoveCard.power_text(view), "40 · Super efficace")


func test_every_costume_names_known_tracks() -> void:
	var library := AudioLibrary.new()
	assert_true(library.load_dir())
	var catalog := CostumeCatalog.shared()
	for id: StringName in catalog.ids():
		var battle := catalog.music_track(id, CostumeCatalog.MUSIC_BATTLE)
		var town := catalog.music_track(id, CostumeCatalog.MUSIC_TOWN)
		assert_true(library.has_track(battle), String(id))
		assert_true(library.is_jingle(town), String(id))
	assert_eq(catalog.music_track(CostumeCatalog.ORIGINAL, CostumeCatalog.MUSIC_BATTLE), &"")


func test_only_ordinary_battles_take_the_costume_theme() -> void:
	var library := AudioLibrary.new()
	library.load_dir()
	var zones := ZoneLibrary.new()
	zones.load_file()
	var selector := MusicSelector.new(library, zones)
	assert_true(selector.is_ordinary_battle(&"", &"pidgey"))
	assert_true(selector.is_ordinary_battle(&"", &"pidgey", &"johto"))
	assert_true(selector.is_ordinary_battle(&"bug_catcher_rick"))
	assert_false(selector.is_ordinary_battle(&"", &"mewtwo"))
	assert_false(selector.is_ordinary_battle(&"", &"mewtwo", &"johto"))
	assert_false(selector.is_ordinary_battle(&"league_lance"))
	assert_false(selector.is_ordinary_battle(&"rival_route_22"))


func test_missing_file_keeps_normal_music() -> void:
	var bridge := AudioBridge.new()
	var library := AudioLibrary.new()
	library.load_dir()
	bridge._library = library
	bridge.costume_music = func(_kind: StringName) -> StringName: return &"costume_soul_battle"
	assert_eq(bridge._costume_track(CostumeCatalog.MUSIC_BATTLE), &"", "fichier absent")
