extends GutTest
## CeruleanCaveAccess (jalon 31, T2 / T5 ; `docs/tech/jalon-31.md` §2.1, §5 critère 1) : accès à
## la Grotte Azurée calculé depuis le titre de Champion du J30, jamais sauvegardé. Les cinq cas
## du §2.1, le rechargement, une nouvelle tentative de Ligue après le titre, le message de refus
## et le drapeau « grotte visitée ».

const BADGES: Array[StringName] = [
	&"badge_boulder", &"badge_cascade", &"badge_thunder", &"badge_rainbow", &"badge_soul",
	&"badge_marsh", &"badge_volcano", &"badge_earth",
]
## Drapeaux de tentative du J30 (`LeagueAttempt.temporary_flags`, `origin/jalon-30`).
const ATTEMPT: StringName = &"league_attempt_active"
const ELITE_FOUR: Array[StringName] = [
	&"league_stage_0_cleared", &"league_stage_1_cleared", &"league_stage_2_cleared",
	&"league_stage_3_cleared",
]


func _flags(names: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


## Sauvegarde puis rechargement des drapeaux (comme `GameState.to_dict` / `load_dict`).
func _reloaded(flags: StoryFlags) -> StoryFlags:
	var copy := StoryFlags.new()
	copy.load_array(JSON.parse_string(JSON.stringify(flags.to_array())))
	return copy


func test_seven_badges_refused() -> void:
	assert_false(CeruleanCaveAccess.is_open(_flags(BADGES.slice(0, 7))))


func test_eight_badges_without_the_league_refused() -> void:
	assert_false(CeruleanCaveAccess.is_open(_flags(BADGES)))


func test_elite_four_beaten_without_the_champion_refused() -> void:
	var names: Array[StringName] = BADGES.duplicate()
	names.append(ATTEMPT)
	names.append_array(ELITE_FOUR)
	assert_false(CeruleanCaveAccess.is_open(_flags(names)))


func test_champion_title_opens_the_cave() -> void:
	var names: Array[StringName] = BADGES.duplicate()
	names.append(CeruleanCaveAccess.CHAMPION_FLAG)
	assert_true(CeruleanCaveAccess.is_open(_flags(names)))


func test_open_after_reload_and_forever() -> void:
	var flags := _flags([CeruleanCaveAccess.CHAMPION_FLAG] as Array[StringName])
	var reloaded := _reloaded(flags)
	assert_true(CeruleanCaveAccess.is_open(reloaded), "nouvelle session après le générique")
	# Nouvelle tentative de Ligue : les drapeaux temporaires vont et viennent, l'accès reste.
	reloaded.set_flag(ATTEMPT)
	for flag: StringName in ELITE_FOUR:
		reloaded.set_flag(flag)
	assert_true(CeruleanCaveAccess.is_open(reloaded))
	reloaded.set_flag(ATTEMPT, false)
	for flag: StringName in ELITE_FOUR:
		reloaded.set_flag(flag, false)
	assert_true(CeruleanCaveAccess.is_open(reloaded), "défaite dans une nouvelle tentative")


func test_access_is_computed_never_saved() -> void:
	var flags := _flags([CeruleanCaveAccess.CHAMPION_FLAG] as Array[StringName])
	CeruleanCaveAccess.is_open(flags)
	assert_eq(flags.to_array(), [CeruleanCaveAccess.CHAMPION_FLAG] as Array[StringName],
		"aucun drapeau « cerulean_cave_unlocked »")


func test_new_game_is_refused() -> void:
	assert_false(CeruleanCaveAccess.is_open(null))
	assert_false(CeruleanCaveAccess.is_open(StoryFlags.new()))


func test_refusal_dialogue_only_when_closed() -> void:
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	assert_true(dialogues.has_dialogue(CeruleanCaveAccess.REFUSAL_DIALOGUE))
	var page: String = dialogues.get_dialogue(CeruleanCaveAccess.REFUSAL_DIALOGUE) \
		.variants[0].pages[0].text
	assert_eq(page, "Les eaux sont trop agitées. Pas maintenant.", "texte [D] du plan §4")
	assert_eq(CeruleanCaveAccess.refusal_for(_flags(BADGES)), CeruleanCaveAccess.REFUSAL_DIALOGUE)
	assert_eq(CeruleanCaveAccess.refusal_for(
		_flags([CeruleanCaveAccess.CHAMPION_FLAG] as Array[StringName])), &"")


func test_first_entry_records_the_discovery_once() -> void:
	var flags := _flags([CeruleanCaveAccess.CHAMPION_FLAG] as Array[StringName])
	assert_false(CeruleanCaveAccess.record_entry(flags, &"cerulean_city"), "hors de la grotte")
	assert_true(CeruleanCaveAccess.record_entry(flags, &"cerulean_cave_1f"))
	assert_true(flags.has_flag(CeruleanCaveAccess.DISCOVERED_FLAG))
	assert_false(CeruleanCaveAccess.record_entry(flags, &"cerulean_cave_b1f"), "déjà posé")
	var closed := _flags(BADGES)
	assert_false(CeruleanCaveAccess.record_entry(closed, &"cerulean_cave_1f"), "grotte fermée")
	assert_false(closed.has_flag(CeruleanCaveAccess.DISCOVERED_FLAG))
	assert_false(CeruleanCaveAccess.record_entry(null, &"cerulean_cave_1f"))


## Contrat J30 → J31 : une fois le J30 fusionné, le drapeau est celui de `LeagueAttempt`.
func test_champion_flag_is_the_league_one_when_the_league_exists() -> void:
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		if entry["class"] == &"LeagueAttempt":
			var script: Script = load(entry["path"])
			assert_eq(script.get_script_constant_map().get("CHAMPION_DEFEATED"),
				CeruleanCaveAccess.CHAMPION_FLAG)
			return
	pass_test("J30 pas encore fusionné : valeur recopiée de origin/jalon-30")


func test_debug_starts_open_and_closed() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	for name: String in ["cerulean_cave", "cerulean_cave_locked"]:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % name, data, items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		var flags := StoryFlags.new()
		for flag: StringName in start.flags:
			flags.set_flag(flag)
		assert_eq(CeruleanCaveAccess.is_open(flags), name == "cerulean_cave", name)
		assert_true(flags.has_all(BADGES), "%s : huit Badges" % name)
		assert_true(start.bag.has(&"hm03"), "%s : CS03 Surf" % name)
