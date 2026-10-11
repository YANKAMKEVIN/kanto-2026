extends GutTest
## OpeningDirector (OUV.1, OUV.2) seul, sans Boot : système de fichiers en mémoire, constructeur de
## partie factice. Ordre des effets (titre fermé, introduction, commit **avec les prénoms
## choisis** avant le rideau, introduction retirée), une seule construction de la partie, garde
## d'autosave, chemin de la copie de sécurité.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const SAVE_PATH := "user://test_director_save.json"

var _fs: MemoryFs
var _director: OpeningDirector
var _events: Array[String] = []
var _builds: int = 0


func before_each() -> void:
	_fs = MemoryFs.new()
	_events.clear()
	_builds = 0


func _build(player_name: String, rival_name: String) -> Dictionary:
	_builds += 1
	_events.append("build %s %s (écritures : %d)" % [player_name, rival_name,
		_writes()])
	return {"player_name": player_name, "rival_name": rival_name, "map": "player_house_2f"}


func _writes() -> int:
	return _fs.journal.filter(func(e: String) -> bool: return e.begins_with("write ")).size()


func _start() -> void:
	_director = OpeningDirector.new()
	_director.speed_scale = 0.0
	add_child_autofree(_director)
	_director.setup(SaveSystem.new(_fs, SAVE_PATH), _build, null, GameSettings.new(),
		GameSettings.Graphics.HIGH, Callable(), [] as Array[StringName])
	_director.title_closed.connect(func() -> void:
		_events.append("title_closed (écritures : %d)" % _writes()))
	_director.resumed.connect(func(save: Dictionary) -> void:
		_events.append("resumed %s" % save.get("player_name", "")))
	_director.new_game_entered.connect(func(warning: String) -> void:
		_events.append("new_game_entered [%s]" % warning))
	_director.intro_opened.connect(func() -> void:
		_events.append("intro_opened (écritures : %d)" % _writes()))
	_director.intro_closed.connect(func() -> void:
		_events.append("intro_closed (écritures : %d)" % _writes()))
	_director.run()


## Attend la fin ; une introduction en cours est jouée avec [param player] et [param rival].
func _finish(player: String = "Kevin", rival: String = "Régis") -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while not _director.is_finished() and Time.get_ticks_msec() < deadline:
		var intro := _director.get_intro()
		if intro != null and intro.is_running():
			if intro.is_waiting_for_name():
				var prompt := intro.get_reader().current().name
				intro.submit_name(player if prompt == IntroScript.PROMPT_PLAYER_NAME else rival)
			elif intro.is_waiting_for_choice():
				intro.answer(true)
			else:
				intro.advance()
		await wait_process_frames(1)


func test_previous_path_sits_next_to_the_save() -> void:
	assert_eq(OpeningDirector.previous_path_for("user://save.json"), OpeningCommit.PREVIOUS_PATH)
	assert_eq(OpeningDirector.previous_path_for("user://a/b.json"), "user://a/b.previous.json")


func test_the_title_closes_before_the_commit_and_the_game_is_built_once() -> void:
	_start()
	assert_false(_director.autosave_allowed())
	_director.choose(TitleMenuModel.ENTRY_NEW_GAME)
	await _finish("Sacha", "Gary")
	assert_eq(_events, ["title_closed (écritures : 0)", "intro_opened (écritures : 0)",
		"build Sacha Gary (écritures : 0)", "intro_closed (écritures : 1)",
		"new_game_entered []"] as Array[String])
	assert_null(_director.get_intro(), "introduction retirée")
	assert_null(_director.get_intro_stage())
	assert_eq(_builds, 1)
	assert_true(_director.autosave_allowed())
	assert_true(_fs.files.has(SAVE_PATH))


func test_a_newer_save_builds_the_game_without_writing() -> void:
	_fs.files[SAVE_PATH] = JSON.stringify({"version": SaveSystem.VERSION + 1})
	_start()
	_director.choose(TitleMenuModel.ENTRY_NEW_GAME)
	await _finish()
	assert_eq(_builds, 1, "partie construite en mémoire")
	assert_eq(_writes(), 0)
	assert_false(_director.autosave_allowed())
	assert_eq(_director.get_last_commit(), -1)


func test_continue_resumes_with_what_was_read() -> void:
	SaveSystem.new(_fs, SAVE_PATH).write({"player_name": "Sacha", "map": "route_1"})
	_fs.journal.clear()
	_start()
	assert_false(_director.autosave_allowed(), "pas avant la reprise")
	_director.choose(TitleMenuModel.ENTRY_CONTINUE)
	await _finish()
	assert_eq(_events, ["title_closed (écritures : 0)", "resumed Sacha"] as Array[String])
	assert_eq(_builds, 0)
	assert_true(_director.autosave_allowed())
	assert_eq(_writes(), 0)


func test_touches_during_the_exit_are_ignored() -> void:
	SaveSystem.new(_fs, SAVE_PATH).write({"player_name": "Sacha"})
	_start()
	_director.choose(TitleMenuModel.ENTRY_CONTINUE)
	_director.choose(TitleMenuModel.ENTRY_NEW_GAME)
	_director.choose(TitleMenuModel.ENTRY_CONTINUE)
	await _finish()
	assert_eq(_events.size(), 2, "une seule sortie : %s" % [_events])
	assert_false(_director.handle_back(), "fini : le retour n'est plus pris")


func test_a_build_failure_is_a_failed_commit() -> void:
	_director = OpeningDirector.new()
	_director.speed_scale = 0.0
	add_child_autofree(_director)
	_director.setup(SaveSystem.new(_fs, SAVE_PATH), func(_p: String, _r: String) -> Variant:
		return null, null, GameSettings.new(), GameSettings.Graphics.HIGH, Callable(),
		[] as Array[StringName])
	var warnings: Array[String] = []
	_director.new_game_entered.connect(func(warning: String) -> void: warnings.append(warning))
	_director.run()
	_director.choose(TitleMenuModel.ENTRY_NEW_GAME)
	await _finish()
	assert_eq(_director.get_last_commit(), OpeningCommit.Result.BUILD_FAILED)
	assert_eq(warnings, ["La partie n'a pas pu être enregistrée. Elle continue sans sauvegarde."]
		as Array[String])
	assert_false(_director.autosave_allowed())
	assert_false(_fs.files.has(SAVE_PATH))


func test_the_introduction_writes_nothing_until_its_last_line() -> void:
	_start()
	_director.choose(TitleMenuModel.ENTRY_NEW_GAME)
	await wait_until(func() -> bool: return _director.get_intro() != null, 5.0)
	var intro := _director.get_intro()
	assert_false(_director.autosave_allowed())
	assert_true(_director.handle_back(), "le retour appartient à l'introduction")
	assert_eq(_director.get_flow().screen(), OpeningFlow.Screen.INTRO)
	assert_eq(_writes(), 0)
	assert_eq(_builds, 0, "rien de construit pendant l'introduction")
	assert_true(intro.is_running())
