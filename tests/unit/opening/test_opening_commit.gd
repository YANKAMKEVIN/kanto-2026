extends GutTest
## OpeningCommit (dossier 13 §3.7) : copie atomique vers save.previous.json, construction en
## mémoire, écriture atomique ; une panne après chaque opération ne laisse sur le « disque » que
## l'ancienne partie intacte (octet pour octet) ou la nouvelle complète. Puis le parcours
## complet avec OpeningFlow : abandon = aucune écriture, relancement, seconde introduction.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const CrashingFs := preload("res://tests/helpers/crashing_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
## Vraie partie de Kevin (v3) : l'« ancienne partie » des tests, en octets réels.
const FIXTURE := "res://tests/fixtures/save/v3_kevin_j7_fin.json"
const SAVE := "user://save.json"
const PREVIOUS := "user://save.previous.json"
const A := OpeningFlow.Action
const E := OpeningFlow.Effect

var _old: String
var _new_game: Dictionary


func before_all() -> void:
	_old = FileAccess.get_file_as_string(FIXTURE)
	assert_false(_old.is_empty())
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-10T09:00:00")
	state.new_game(11)
	state.player_name = "Sacha"
	state.current_map = &"player_house_2f"
	_new_game = state.to_dict()


func _builder() -> Callable:
	return func() -> Dictionary: return _new_game.duplicate(true)


## Texte exact qu'écrit SaveSystem pour la nouvelle partie.
func _new_text() -> String:
	var content := _new_game.duplicate(true)
	content[SaveSystem.VERSION_KEY] = SaveSystem.VERSION
	return JSON.stringify(content, "\t")


func _commit(fs: SaveFileSystem) -> OpeningCommit:
	return OpeningCommit.new(fs, SAVE, PREVIOUS)


## Nombre d'opérations d'écriture d'un commit complet sur ce disque de départ.
func _op_count(files: Dictionary[String, String]) -> int:
	var fs := MemoryFs.new()
	fs.files = files.duplicate()
	assert_eq(_commit(fs).run(_builder()), OpeningCommit.Result.OK)
	return fs.journal.size()


func test_without_save_writes_new_game_and_no_copy() -> void:
	var fs := MemoryFs.new()
	var commit := _commit(fs)
	assert_eq(commit.run(_builder()), OpeningCommit.Result.OK)
	assert_eq(fs.files[SAVE], _new_text())
	assert_false(fs.files.has(PREVIOUS))
	assert_false(fs.files.has(SAVE + ".tmp"))
	var read := SaveSystem.new(fs, SAVE).read()
	assert_eq(read.get("player_name"), "Sacha")
	assert_eq(read.get("map"), "player_house_2f")


func test_with_save_copies_old_bytes_then_writes() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	assert_eq(_commit(fs).run(_builder()), OpeningCommit.Result.OK)
	assert_eq(fs.files[PREVIOUS], _old, "copie octet pour octet")
	assert_eq(fs.files[SAVE], _new_text())
	assert_false(fs.files.has(PREVIOUS + ".tmp"))
	assert_eq(fs.journal, [
		"write %s.tmp" % PREVIOUS, "rename %s.tmp -> %s" % [PREVIOUS, PREVIOUS],
		"write %s.tmp" % SAVE, "rename %s -> %s.bak" % [SAVE, SAVE],
		"rename %s.tmp -> %s" % [SAVE, SAVE],
	] as Array[String], "copie d'abord, puis écriture atomique (ancienne gardée en .bak, J33 T4)")
	assert_eq(fs.files[SAVE + ".bak"], _old, "copie de secours : l'ancienne partie")


func test_previous_copy_is_replaced() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	fs.files[PREVIOUS] = "{\"version\": 1}"
	assert_eq(_commit(fs).run(_builder()), OpeningCommit.Result.OK)
	assert_eq(fs.files[PREVIOUS], _old)


func test_builder_runs_after_the_copy() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	var seen := {}
	var builder := func() -> Dictionary:
		seen["copy"] = fs.files.get(PREVIOUS, "")
		seen["save"] = fs.files.get(SAVE, "")
		return _new_game.duplicate(true)
	_commit(fs).run(builder)
	assert_eq(seen["copy"], _old, "copie faite avant la construction")
	assert_eq(seen["save"], _old, "rien d'écrit avant la construction")


func test_crash_after_each_operation_with_old_save() -> void:
	var start: Dictionary[String, String] = {SAVE: _old}
	var total := _op_count(start)
	assert_eq(total, 5)
	for crash_at: int in total + 1:
		var fs := CrashingFs.new()
		fs.files = start.duplicate()
		fs.crash_after = crash_at
		_commit(fs).run(_builder())
		var on_disk: String = fs.files.get(SAVE, "")
		assert_true(on_disk == _old or on_disk == _new_text()
			or (on_disk.is_empty() and fs.files.get(SAVE + ".bak", "") == _old),
			"panne après %d opérations : ancienne ou nouvelle partie complète" % crash_at)
		if crash_at < total - 1:
			assert_eq(on_disk, _old, "panne avant la rotation : l'ancienne, intacte")
		elif crash_at == total - 1:
			assert_eq(fs.files.get(SAVE + ".bak", ""), _old,
				"panne entre les deux renommages : l'ancienne, intacte, en copie de secours")
		else:
			assert_eq(on_disk, _new_text())
		if fs.files.has(PREVIOUS):
			assert_eq(fs.files[PREVIOUS], _old, "la copie n'est jamais partielle")
		var save := SaveSystem.new(fs, SAVE)
		save.read()
		assert_eq(save.last_status, OK, "toujours lisible (panne %d)" % crash_at)


func test_crash_after_each_operation_without_save() -> void:
	var start: Dictionary[String, String] = {}
	var total := _op_count(start)
	assert_eq(total, 2)
	for crash_at: int in total + 1:
		var fs := CrashingFs.new()
		fs.crash_after = crash_at
		_commit(fs).run(_builder())
		if crash_at < total:
			assert_false(fs.files.has(SAVE), "panne %d : toujours aucune partie" % crash_at)
		else:
			assert_eq(fs.files[SAVE], _new_text())
		assert_false(fs.files.has(PREVIOUS))


func test_torn_copy_is_detected() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	fs.truncate_writes = true
	var commit := _commit(fs)
	assert_eq(commit.run(_builder()), OpeningCommit.Result.BACKUP_FAILED)
	assert_eq(fs.files[SAVE], _old)
	assert_false(fs.files.has(PREVIOUS))
	assert_false(fs.files.has(PREVIOUS + ".tmp"), "temporaire effacé")
	assert_false(commit.last_error.is_empty())


func test_backup_failure_writes_nothing_and_skips_builder() -> void:
	for mode: String in ["write", "rename"]:
		var fs := MemoryFs.new()
		fs.files[SAVE] = _old
		fs.fail_writes = mode == "write"
		fs.fail_renames = mode == "rename"
		var called := [false]
		var builder := func() -> Dictionary:
			called[0] = true
			return _new_game.duplicate(true)
		assert_eq(_commit(fs).run(builder), OpeningCommit.Result.BACKUP_FAILED, mode)
		assert_eq(fs.files[SAVE], _old, mode)
		assert_false(called[0], mode + " : la partie n'est pas construite")


func test_build_failure_keeps_old_save() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	var empty := func() -> Dictionary: return {}
	assert_eq(_commit(fs).run(empty), OpeningCommit.Result.BUILD_FAILED)
	assert_eq(fs.files[SAVE], _old)


func test_write_failure_keeps_old_save_and_copy() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	var builder := func() -> Dictionary:
		fs.fail_renames = true  # le disque lâche après la copie
		return _new_game.duplicate(true)
	var commit := _commit(fs)
	assert_eq(commit.run(builder), OpeningCommit.Result.WRITE_FAILED)
	assert_eq(fs.files[SAVE], _old)
	assert_eq(fs.files[PREVIOUS], _old)
	assert_false(commit.last_error.is_empty())


# --- Parcours complet : OpeningFlow + OpeningCommit ----------------------------------------

## Lancement : lit la sauvegarde comme le fera Boot et rend le flux.
func _launch(fs: SaveFileSystem) -> OpeningFlow:
	var save := SaveSystem.new(fs, SAVE)
	save.read()
	return OpeningFlow.new(OpeningFlow.status_from_read(save.last_status))


## Exécute les effets demandés comme le fera l'OpeningDirector ; rend vrai si la chambre est
## atteinte.
func _run_effects(flow: OpeningFlow, fs: SaveFileSystem) -> bool:
	var entered := false
	var guard := 0
	while guard < 10:
		guard += 1
		var effects := flow.take_effects()
		if effects.is_empty():
			break
		for effect: OpeningFlow.Effect in effects:
			match effect:
				E.WRITE_NEW_GAME:
					var ok := _commit(fs).run(_builder()) == OpeningCommit.Result.OK
					flow.handle(A.COMMIT_SUCCEEDED if ok else A.COMMIT_FAILED)
				E.ENTER_BEDROOM:
					entered = true
	return entered


func test_abandon_writes_nothing_and_relaunch_finds_old_save() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	var flow := _launch(fs)
	assert_eq(flow.save_status(), OpeningFlow.SaveStatus.VALID)
	flow.handle(A.NEW_GAME)
	flow.handle(A.CONFIRM)
	flow.handle(A.ABANDON)
	assert_false(_run_effects(flow, fs))
	assert_eq(fs.journal.size(), 0, "aucune écriture")
	assert_eq(fs.files[SAVE], _old, "octet pour octet")
	assert_false(fs.files.has(PREVIOUS))
	var relaunched := _launch(fs)
	assert_true(relaunched.can_continue())
	assert_true(relaunched.handle(A.NEW_GAME))
	assert_eq(relaunched.screen(), OpeningFlow.Screen.CONFIRM_OVERWRITE, "nouvelle confirmation")


func test_second_intro_after_abandon_commits() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	var flow := _launch(fs)
	flow.handle(A.NEW_GAME)
	flow.handle(A.CONFIRM)
	flow.handle(A.ABANDON)
	flow.handle(A.NEW_GAME)
	flow.handle(A.CONFIRM)
	flow.handle(A.INTRO_FINISHED)
	assert_true(_run_effects(flow, fs))
	assert_eq(flow.screen(), OpeningFlow.Screen.DONE)
	assert_true(flow.autosave_allowed())
	assert_eq(fs.files[SAVE], _new_text())
	assert_eq(fs.files[PREVIOUS], _old)


func test_first_launch_new_game() -> void:
	var fs := MemoryFs.new()
	var flow := _launch(fs)
	assert_eq(flow.save_status(), OpeningFlow.SaveStatus.NONE)
	flow.handle(A.NEW_GAME)
	flow.handle(A.INTRO_FINISHED)
	assert_true(_run_effects(flow, fs))
	assert_eq(fs.files[SAVE], _new_text())
	assert_false(fs.files.has(PREVIOUS))


func test_corrupt_save_stays_quarantined() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = "{ pas du json"
	var flow := _launch(fs)
	assert_eq(flow.save_status(), OpeningFlow.SaveStatus.CORRUPT)
	assert_eq(fs.files[SAVE + ".corrupt"], "{ pas du json", "mise de côté par SaveSystem")
	flow.handle(A.NEW_GAME)
	flow.handle(A.INTRO_FINISHED)
	assert_true(_run_effects(flow, fs))
	assert_eq(fs.files[SAVE], _new_text())
	assert_eq(fs.files[SAVE + ".corrupt"], "{ pas du json", "jamais détruite")


func test_newer_save_is_never_touched() -> void:
	var fs := MemoryFs.new()
	var newer := "{\"version\": %d, \"player_name\": \"Futur\"}" % (SaveSystem.VERSION + 1)
	fs.files[SAVE] = newer
	var flow := _launch(fs)
	assert_eq(flow.save_status(), OpeningFlow.SaveStatus.NEWER)
	flow.handle(A.NEW_GAME)
	flow.handle(A.INTRO_FINISHED)
	assert_true(_run_effects(flow, fs), "on joue quand même")
	assert_eq(fs.journal.size(), 0, "aucune écriture")
	assert_eq(fs.files[SAVE], newer)
	assert_false(flow.autosave_allowed())


func test_commit_failure_enters_bedroom_without_autosave() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE] = _old
	var flow := _launch(fs)
	flow.handle(A.NEW_GAME)
	flow.handle(A.CONFIRM)
	flow.handle(A.INTRO_FINISHED)
	fs.fail_writes = true
	assert_true(_run_effects(flow, fs))
	assert_eq(fs.files[SAVE], _old)
	assert_false(flow.autosave_allowed(), "l'ancienne partie ne sera pas écrasée")
