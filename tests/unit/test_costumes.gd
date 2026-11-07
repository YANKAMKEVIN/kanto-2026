extends GutTest
## Costumes du Dresseur (docs/design/dossier-costumes.md, CO-1 à CO-11) : catalogue en données,
## déblocage par badge (CO-3, CO-9), choix (CO-6, CO-7), sauvegarde par `player_costume` (CO-9),
## apparences de [TrainerLooks] (CO-5), vue de l'écran Dresseur (CO-1, CO-2), carte Continuer.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_costumes.json"
const PAINTED := "res://assets/sprites/characters/painted/"

var _data: PokemonData
var _catalog: CostumeCatalog


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_catalog = CostumeCatalog.shared()


func _new_state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-11-01T20:00:00")
	state.new_game(9)
	return state


func _round_trip(state: Node) -> Node:
	var save := SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	assert_eq(save.write(state.to_dict()), OK)
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(save.read(), _data))
	return loaded


func _flags(list: Array[StringName]) -> Callable:
	return func(flag: StringName) -> bool: return list.has(flag)


# --- Données -----------------------------------------------------------------------------------

func test_one_costume_per_badge_in_gym_order() -> void:
	assert_eq(_catalog.get_errors(), PackedStringArray())
	var badges := BadgeLibrary.new()
	badges.load_file()
	var expected: Array[StringName] = badges.ids()
	var found: Array[StringName] = []
	for id: StringName in _catalog.ids():
		found.append(_catalog.badge_of(id))
	assert_eq(found, expected, "CO-3 : un costume par badge, ordre des arènes")
	assert_eq(_catalog.costume_for_badge(&"boulder"), &"boulder")
	assert_eq(_catalog.costume_for_badge(&"inconnu"), &"")


func test_names_follow_the_player_look() -> void:
	assert_eq(_catalog.display_name(&"boulder", &"hero"), "Tanjiro")
	assert_eq(_catalog.display_name(&"boulder", &"heroine"), "Nezuko")
	assert_eq(_catalog.display_name(&"earth", &"heroine"), "Batgirl")
	assert_eq(_catalog.display_name(&"boulder", &"inconnue"), "Tanjiro", "apparence inconnue")
	assert_eq(_catalog.unlock_text(&"cascade", &"hero"), "Nouveau costume : Luffy")


func test_invalid_entries_are_rejected() -> void:
	var catalog := CostumeCatalog.new()
	assert_false(catalog.add_from_array([
		{"id": "a", "badge": "boulder", "art": "roche", "names": {"hero": "A"}},
		{"id": "b", "badge": "boulder", "art": "roche", "names": {"hero": "B", "heroine": "B"},
			"extra": 1},
		"texte",
	]))
	assert_eq(catalog.size(), 0)
	assert_eq(catalog.get_errors().size(), 3)
	assert_push_error_count(3)


# --- Déblocage et choix ------------------------------------------------------------------------

func test_a_costume_unlocks_with_its_badge_only() -> void:
	assert_false(_catalog.is_unlocked(&"boulder", _flags([])))
	assert_true(_catalog.is_unlocked(&"boulder", _flags([&"badge_boulder"])))
	assert_false(_catalog.is_unlocked(&"cascade", _flags([&"badge_boulder"])), "CO-3")
	assert_false(_catalog.is_unlocked(&"", _flags([&"badge_boulder"])))
	assert_eq(_catalog.worn(&"cascade", _flags([&"badge_boulder"])), &"")
	assert_eq(_catalog.worn(&"boulder", _flags([&"badge_boulder"])), &"boulder")


func test_wear_costume_needs_the_badge_and_the_original_is_always_allowed() -> void:
	var state := _new_state()
	assert_false(state.wear_costume(&"boulder"), "badge manquant")
	assert_eq(state.player_costume, &"")
	assert_false(state.wear_costume(&"goku"), "inconnu")
	state.flags.set_flag(&"badge_boulder")
	assert_true(state.wear_costume(&"boulder"))
	assert_eq(state.worn_costume(), &"boulder")
	assert_true(state.wear_costume(&""), "CO-6 : la tenue d'origine")
	assert_eq(state.worn_costume(), &"")


# --- Sauvegarde (CO-9) -------------------------------------------------------------------------

func test_the_worn_costume_round_trips() -> void:
	var state := _new_state()
	state.flags.set_flag(&"badge_cascade")
	assert_true(state.wear_costume(&"cascade"))
	assert_eq(state.to_dict().get("player_costume"), "cascade")
	var loaded := _round_trip(state)
	assert_eq(loaded.player_costume, &"cascade")
	assert_eq(SaveSystem.VERSION, 10, "pas de nouvelle version de sauvegarde, v10 JOH0 (lien, œuf, équipe confisquée)")


func test_a_costume_without_its_badge_loads_as_the_original_outfit() -> void:
	var state := _new_state()
	var content: Dictionary = state.to_dict()
	content["player_costume"] = "volcano"
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(content, _data))
	assert_eq(loaded.player_costume, &"", "CO-9 : badge absent → tenue d'origine")
	assert_false(loaded.to_dict().has("player_costume"))


# --- Apparences (CO-5) -------------------------------------------------------------------------

func test_trainer_looks_dress_every_appearance() -> void:
	assert_eq(TrainerLooks.player_sprite(&"hero", &"boulder"), &"costumes/roche_joueur")
	assert_eq(TrainerLooks.player_sprite(&"heroine", &"boulder"), &"costumes/roche_joueuse")
	assert_eq(TrainerLooks.player_sprite(&"heroine"), &"player_heroine", "tenue d'origine")
	assert_eq(TrainerLooks.player_sprite(&"hero", &"goku"), &"player", "inconnu")
	assert_eq(TrainerLooks.thrower_path(&"hero", &"thunder"),
		PAINTED + "costumes/foudre_joueur_lancer.png")
	assert_eq(TrainerLooks.thrower_path(&"hero"), PAINTED + "heros_lancer.png")
	assert_eq(TrainerLooks.bust_path(&"heroine", &"earth"),
		PAINTED + "costumes/terre_joueuse_bust.webp")
	assert_eq(TrainerLooks.bust_path(&"heroine"), "res://assets/ui/menu/heroine_bust.webp")


func test_every_costume_has_the_animations_and_images_of_its_counterpart() -> void:
	var counterparts := {&"hero": [&"player", &"player_surf"],
		&"heroine": [&"player_heroine", &"player_heroine_surf"]}
	for id: StringName in _catalog.ids():
		for look: StringName in counterparts:
			var sprite := _catalog.world_sprite(id, look)
			var resolved := CharacterLook.resolve(sprite)
			assert_true(resolved.painted, "%s : peint" % sprite)
			assert_eq(_animations(resolved.frames_path),
				_animations(PAINTED + String(counterparts[look][0]) + "_frames.tres"),
				"%s : animations" % sprite)
			assert_eq(_animations(PAINTED + String(sprite) + "_surf_frames.tres"),
				_animations(PAINTED + String(counterparts[look][1]) + "_frames.tres"),
				"%s : surf" % sprite)
			var thrower := load(_catalog.thrower_path(id, look)) as Texture2D
			assert_not_null(thrower, "%s : lancer" % sprite)
			if thrower != null:
				assert_eq(thrower.get_height(),
					(load(TrainerLooks.thrower_path(look)) as Texture2D).get_height())
			var bust := load(_catalog.bust_path(id, look)) as Texture2D
			assert_not_null(bust, "%s : buste" % sprite)
			if bust != null:
				assert_eq(bust.get_height(),
					(load(TrainerLooks.bust_path(look)) as Texture2D).get_height())


func _animations(path: String) -> Array:
	var frames := load(path) as SpriteFrames
	assert_not_null(frames, path)
	if frames == null:
		return []
	var names: Array = []
	for animation: StringName in frames.get_animation_names():
		names.append([String(animation), frames.get_frame_count(animation)])
	names.sort()
	return names


# --- Écran Dresseur (CO-1, CO-2, CO-6) et carte Continuer ---------------------------------------

func test_trainer_view_lists_the_original_first_then_silhouettes() -> void:
	var state := _new_state()
	state.player_look = &"heroine"
	state.flags.set_flag(&"badge_boulder")
	assert_true(state.wear_costume(&"boulder"))
	var views := TrainerSummary.costume_views(state, _catalog)
	assert_eq(views.size(), 9)
	assert_eq(views[0].costume_id, &"")
	assert_true(views[0].unlocked)
	assert_false(views[0].worn)
	assert_eq(views[0].sprite, &"player_heroine")
	assert_true(views[1].unlocked and views[1].worn)
	assert_eq(views[1].name, "Nezuko")
	for i: int in range(2, 9):
		assert_false(views[i].unlocked)
		assert_eq(views[i].name, "", "CO-2 : ni nom")
		assert_false(views[i].sprite.is_empty(), "silhouette")


func test_save_summary_keeps_only_an_unlocked_costume() -> void:
	var save := {"player_look": "hero", "player_costume": "boulder",
		"flags": ["badge_boulder"]}
	assert_eq(SaveSummary.from_save(save).player_costume, &"boulder")
	save["flags"] = []
	assert_eq(SaveSummary.from_save(save).player_costume, &"", "badge absent")


func test_trainer_screen_locked_touch_explains_and_unlocked_touch_chooses() -> void:
	var screen: TrainerScreen = add_child_autofree(TrainerScreen.new())
	var state := _new_state()
	state.flags.set_flag(&"badge_boulder")
	var view := TrainerView.new()
	view.costumes = TrainerSummary.costume_views(state, _catalog)
	screen.show_trainer(view)
	var slots := screen.get_costume_slots()
	assert_eq(slots.size(), 9)
	assert_eq(screen.get_costume_caption().text, "%s\n%s" % [
		TrainerView.ORIGINAL_COSTUME_NAME, TrainerView.ORIGINAL_COSTUME_PERK])
	assert_true(slots[2].is_silhouette())
	assert_false(slots[1].is_silhouette())
	watch_signals(screen)
	slots[2].get_hit().pressed.emit()
	assert_signal_not_emitted(screen, "costume_chosen")
	assert_eq(screen.get_costume_caption().text, TrainerView.COSTUME_LOCKED_TEXT)
	slots[1].get_hit().pressed.emit()
	assert_signal_emitted_with_parameters(screen, "costume_chosen", [&"boulder"])
	slots[0].get_hit().pressed.emit()
	assert_signal_emit_count(screen, "costume_chosen", 1, "déjà portée : rien")
