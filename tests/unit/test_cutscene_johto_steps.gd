extends GutTest
## CutsceneDirector, étapes du Chapitre Johto (JOH0, `jalon-joh0.md` §2.2) : « confiscate_team »
## (le vol, d'un seul bloc) et « return_team » (le choix des 6 par le gestionnaire de Boot, ou la
## sélection par défaut sans lui, puis le retour d'un seul bloc). Lecture des étapes par la
## bibliothèque (valeur true, drapeaux levés connus), refus (équipe vide, rien de confisqué,
## choix refusé). Ni joueur ni dialogue : ces étapes n'en ont pas besoin.

const STATE_SCRIPT := preload("res://game/autoload/game_state.gd")
const TIMEOUT := 4.0
const SCENES := {
	"theft": {"steps": [{"set": ["before"]}, {"confiscate_team": true}, {"set": ["after"]}]},
	"return": {"steps": [{"return_team": true}, {"set": ["after"]}]},
}

var _director: CutsceneDirector
var _flags: StoryFlags
var _state: Node
var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func before_each() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"), str(scenes.get_errors()))
	_state = STATE_SCRIPT.new()
	autofree(_state)
	_state.new_game(5)
	_flags = _state.flags
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, null, null, null)
	_director.set_badges(null, _state)
	_director.set_inventory(_state.bag, _items)
	_director.set_pokemon_data(_data)
	watch_signals(_director)


func _await_scene_end() -> void:
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)


func _add(species: StringName, level: int, hp: int = -1) -> Pokemon:
	var mon := PokemonFactory.create(_data, species, level, GameRng.new(level))
	if hp >= 0:
		mon.hp = hp
	_state.party.add(mon)
	return mon


func _league() -> void:
	for species: StringName in [&"charizard", &"pidgeot", &"nidoking"]:
		_add(species, 60)
	_state.set_companion(_state.party.get_at(0))
	_state.bag.add(&"potion", 3)
	_state.bag.add(&"oak_parcel", 1)


# --- Lecture ---------------------------------------------------------------------------------------

func test_the_library_reads_both_steps_and_refuses_other_values() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "ok"))
	var theft := scenes.get_cutscene(&"theft")
	assert_eq(theft.variants[0].steps[1].kind, CutsceneStep.Kind.CONFISCATE_TEAM)
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.CONFISCATE_TEAM), &"confiscate_team")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.RETURN_TEAM), &"return_team")
	var raised: Array = scenes.get_set_flags()
	for flag: StringName in [TeamConfiscation.STORAGE_OFFLINE, TeamConfiscation.ACT1,
			TeamConfiscation.RETURNED]:
		assert_true(raised.has(flag), "drapeau levé connu : %s" % flag)
	var bad := CutsceneLibrary.new()
	assert_false(bad.add_from_dict({"x": {"steps": [{"confiscate_team": false}]}}, "bad"))
	assert_false(bad.add_from_dict({"y": {"steps": [{"return_team": "oui"}]}}, "bad"))
	assert_push_error_count(2)


# --- Le vol --------------------------------------------------------------------------------------

func test_the_theft_step_confiscates_in_one_block() -> void:
	_league()
	assert_true(_director.play(&"theft"))
	await _await_scene_end()
	assert_true(_flags.has_flag(&"after"), "scène allée au bout")
	assert_eq(_state.party.size(), 0)
	assert_eq(_state.confiscated.party.size(), 3)
	assert_eq(_state.confiscated.items, {&"potion": 3} as Dictionary[StringName, int])
	assert_eq(_state.bag.count_of(&"oak_parcel"), 1, "objet clé gardé")
	assert_eq(_state.companion_uid, "")
	assert_true(_flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	assert_true(_flags.has_flag(TeamConfiscation.ACT1))
	assert_signal_emitted(_director, "team_confiscated")


func test_the_theft_step_on_an_empty_team_is_an_error_and_the_scene_goes_on() -> void:
	assert_true(_director.play(&"theft"))
	await _await_scene_end()
	assert_true(_flags.has_flag(&"after"))
	assert_true(_state.confiscated.is_empty())
	assert_false(_flags.has_flag(TeamConfiscation.ACT1))
	assert_signal_not_emitted(_director, "team_confiscated")
	assert_push_error("vol de l'équipe refusé")


# --- Le retour -------------------------------------------------------------------------------------

func test_the_return_step_without_handler_keeps_the_default_six() -> void:
	_league()
	assert_true(TeamConfiscation.confiscate(_state, _items))
	for species: StringName in [&"squirtle", &"rattata", &"pidgey", &"spearow"]:
		_add(species, 12)
	var johto: Array[Pokemon] = (_state.party as Party).get_all()
	var kanto: Array[Pokemon] = (_state.confiscated as ConfiscatedTeam).party.duplicate()
	assert_true(_director.play(&"return"))
	await _await_scene_end()
	assert_true(_flags.has_flag(&"after"))
	assert_eq(_state.party.size(), 6, "4 de Johto + les 2 premiers de Kanto")
	assert_eq(_state.party.get_at(0), johto[0])
	assert_eq(_state.party.get_at(4), kanto[0])
	assert_eq(_state.storage.size(), 1)
	assert_eq(_state.storage.get_at(0), kanto[2])
	assert_true(_state.confiscated.is_empty())
	assert_eq(_state.bag.count_of(&"potion"), 3)
	assert_eq(_state.companion_uid, kanto[0].uid, "le compagnon d'avant le vol est gardé")
	assert_false(_flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	assert_true(_flags.has_flag(TeamConfiscation.RETURNED))
	assert_signal_emitted_with_parameters(_director, "team_returned", [1])


func test_the_return_step_asks_the_handler_and_keeps_its_choice() -> void:
	_league()
	assert_true(TeamConfiscation.confiscate(_state, _items))
	_add(&"squirtle", 12)
	var kanto: Array[Pokemon] = (_state.confiscated as ConfiscatedTeam).party.duplicate()
	var seen: Array[TeamReturnSelection] = []
	_director.team_return_handler = func(selection: TeamReturnSelection) -> Array[String]:
		seen.append(selection)
		await get_tree().process_frame
		return [kanto[2].uid, kanto[0].uid] as Array[String]
	assert_true(_director.play(&"return"))
	await _await_scene_end()
	assert_eq(seen.size(), 1, "le gestionnaire est appelé une fois")
	assert_eq(seen[0].size(), 4, "la réserve : 1 de Johto + 3 confisqués")
	assert_eq(_state.party.size(), 2)
	assert_eq(_state.party.get_at(0), kanto[2], "dans l'ordre du choix")
	assert_eq(_state.party.get_at(1), kanto[0])
	assert_eq(_state.storage.size(), 2)
	assert_signal_emitted_with_parameters(_director, "team_returned", [2])


func test_the_return_step_with_nothing_confiscated_is_an_error() -> void:
	_add(&"squirtle", 12)
	assert_true(_director.play(&"return"))
	await _await_scene_end()
	assert_true(_flags.has_flag(&"after"))
	assert_eq(_state.party.size(), 1)
	assert_signal_not_emitted(_director, "team_returned")
	assert_push_error("rien à rendre")


func test_a_refused_choice_from_the_handler_changes_nothing() -> void:
	_league()
	assert_true(TeamConfiscation.confiscate(_state, _items))
	_add(&"squirtle", 12)
	_director.team_return_handler = func(_selection: TeamReturnSelection) -> Array[String]:
		return [] as Array[String]
	assert_true(_director.play(&"return"))
	await _await_scene_end()
	assert_eq(_state.party.size(), 1)
	assert_eq(_state.confiscated.party.size(), 3)
	assert_true(_flags.has_flag(TeamConfiscation.ACT1))
	assert_push_error("retour de l'équipe refusé")


# --- give_egg (JOH0, §2.9) -----------------------------------------------------------------------

func test_the_give_egg_step_adds_an_egg_or_fails_on_a_full_team() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict({
		"egg": {"steps": [{"give_egg": "pidgey", "steps": 300}, {"set": ["after"]}]},
		"egg_default": {"steps": [{"give_egg": "rattata"}]},
	}, "test"), str(scenes.get_errors()))
	var step: CutsceneStep = scenes.get_cutscene(&"egg").variants[0].steps[0]
	assert_eq(step.kind, CutsceneStep.Kind.GIVE_EGG)
	assert_eq(step.species, &"pidgey")
	assert_eq(step.count, 300)
	assert_eq((scenes.get_cutscene(&"egg_default").variants[0].steps[0] as CutsceneStep).count,
		EggRules.DEFAULT_STEPS, "2 000 pas par défaut")
	_director.setup(scenes, _flags, null, null, null)
	_director.set_badges(null, _state)
	_director.set_pokemon_data(_data)
	_add(&"squirtle", 10)
	assert_true(_director.play(&"egg"))
	await _await_scene_end()
	assert_eq(_state.party.size(), 2)
	assert_true(_state.party.get_at(1).is_egg())
	assert_eq(_state.party.get_at(1).egg_steps, 300)
	assert_signal_emitted(_director, "egg_given")
	for i: int in 4:
		_add(&"rattata", 5)
	assert_true(_state.party.is_full())
	assert_true(_director.play(&"egg_default"))
	await _await_scene_end()
	assert_eq(_state.party.size(), 6, "équipe pleine : rien")
	assert_push_error("équipe pleine")
	var bad := CutsceneLibrary.new()
	assert_false(bad.add_from_dict({"x": {"steps": [{"give_egg": "pidgey", "steps": 0}]}}, "b"))
	assert_push_error("steps")
