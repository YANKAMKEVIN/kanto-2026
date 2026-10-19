extends GutTest
## Sauvegarde du jalon 19 (T22, `jalon-19.md` §2.13 ; dossier 22 §16 n° 1) : **aucune nouvelle
## version** (v7 depuis le J15) ; le J19 n'ajoute que des drapeaux, qui survivent à l'écriture et à
## la relecture ; une v7 écrite par le J15 se charge sans changement ; un identifiant d'objet
## encore inconnu (`silph_scope`, J20) survit à un aller-retour du Sac.
##
## Scénario du §16 n° 1, **vraie scène Boot** : partie sauvegardée au 6F par le coordinateur de
## sauvegarde, `silph_scope` ajouté au Sac **du fichier**, partie rechargée, rencontre forcée →
## nom réel, « vu » au Pokédex, Ball acceptée ; **le SPECTRE du 6F reste un SPECTRE**
## (`ghost: always`), même Scope en poche. Points de la PR n° 1 ([SaveCoordinator]) : aucune
## écriture tant qu'un combat ou une scène tourne, la demande est écrite dès le retour au calme.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_j19.json"
const BOOT_PATH := "user://test/save_j19_boot.json"
const FIXTURE_V6_S21 := "res://tests/fixtures/save/v6_kevin_s21.json"
const BLOCK_START := "res://tools/debug_start/tower_6f_block.json"
const SCOPE := &"silph_scope"
const BALL := &"poke_ball"
const MAP_6F := &"pokemon_tower_6f"
const SPAWN_6F := &"devant_spectre"
const CELL_6F := Vector2i(10, 14)
## Case juste au nord du déclencheur du SPECTRE (10, 16) : un pas vers le sud le déclenche.
const BEFORE_TRIGGER := Vector2i(10, 15)
const FADE := 0.05
const TIMEOUT := 20.0
const GHOST_LINE := "Un SPECTRE apparaît !"

## Drapeaux du J19 (§2.13).
static var J19_FLAGS: Array[StringName] = _j19_flags()

var _data: PokemonData
var _fs: MemoryFs
var _save: SaveSystem
var _fades: Array[float] = []
var _boot: Boot
var _shown_lines: Array[String] = []


static func _j19_flags() -> Array[StringName]:
	var flags: Array[StringName] = [
		&"tower_stairs_open",
		&"rival_tower_won", &"rival_tower_lost_once", &"rival_tower_retried",
		&"got_tower_3f_objet_1", &"got_tower_4f_objet_1", &"got_tower_4f_objet_2",
		&"got_tower_5f_objet_1", &"got_tower_5f_cache_1", &"got_tower_6f_objet_1",
	]
	for i: int in range(1, 10):
		flags.append(StringName("beaten_tower_channeler_%d" % i))
	return flags


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_shown_lines.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		Input.action_release(action)


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-19T10:00:00")
	state.new_game(19)
	state.party.add(PokemonFactory.create(_data, &"charmeleon", 25, GameRng.new(1)))
	return state


func _round_trip(state: Node) -> Node:
	assert_eq(_save.write(state.to_dict()), OK, "écriture")
	var content := _save.read()
	assert_eq(_save.last_status, OK, "relecture")
	assert_eq(int(content["version"]), SaveSystem.VERSION)
	var loaded := _state()
	assert_true(loaded.load_dict(content, _data), "chargé sans entrée écartée")
	return loaded


func _fixture(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "fixture lisible : %s" % path)
	return parsed if parsed is Dictionary else {}


# --- §2.13, points 1, 2, 3 et 5 ------------------------------------------------------------

func test_the_jalon_19_adds_no_save_version() -> void:
	assert_eq(SaveSystem.VERSION, 7, "aucune version du J19 : v7 depuis le J15 (Pension)")


func test_every_flag_of_the_jalon_survives_a_save() -> void:
	assert_eq(J19_FLAGS.size(), 19, "1 + 3 + 9 + 6 drapeaux (§2.13)")
	var state := _state()
	for flag: StringName in J19_FLAGS:
		state.flags.set_flag(flag)
	var loaded := _round_trip(state)
	for flag: StringName in J19_FLAGS:
		assert_true(loaded.flags.has_flag(flag), "%s relu" % flag)


func test_a_v7_save_written_by_the_jalon_15_loads_unchanged() -> void:
	# Aucune fixture v7 dans le dépôt : la vraie partie v6 du S21 passée en v7 par le J15
	# (« daycare » vide ajouté, rien d'autre) est la v7 du J15.
	var original := _fixture(FIXTURE_V6_S21)
	assert_eq(int(original["version"]), 6, "la fixture est bien une v6")
	var v7: Dictionary = original.duplicate(true)
	v7["version"] = 7
	v7["daycare"] = {}
	_fs.files[PATH] = JSON.stringify(v7, "\t")
	var content := _save.read()
	assert_eq(_save.last_status, OK, "acceptée")
	assert_eq(_save.read_version, 7, "lue comme une v7")
	assert_eq(SaveSystem.migration_note(_save.read_version, SaveSystem.VERSION), "",
		"aucune migration")
	var state := _state()
	assert_true(state.load_dict(content, _data), "chargée sans entrée écartée")
	assert_eq(_save.write(state.to_dict()), OK)
	var written: Variant = JSON.parse_string(_fs.files[PATH])
	assert_eq(written, JSON.parse_string(JSON.stringify(v7)),
		"réécrite à l'identique (équipe, uid, Sac, drapeaux, position, Pension…)")
	for flag: StringName in J19_FLAGS:
		assert_false(state.flags.has_flag(flag), "%s absent d'une partie du J15" % flag)


func test_an_unknown_item_id_survives_a_bag_round_trip() -> void:
	var state := _state()
	state.bag.add(BALL, 10)
	state.bag.add(SCOPE)
	var loaded := _round_trip(state)
	assert_eq(loaded.bag.count_of(SCOPE), 1, "« silph_scope » (objet du J20) relu tel quel")
	assert_eq(loaded.bag.count_of(BALL), 10)


func test_the_ghost_rule_reads_the_bag_never_a_flag() -> void:
	var state := _state()
	for flag: StringName in J19_FLAGS:
		state.flags.set_flag(flag)
	for flag: StringName in [&"ghost_marowak_calmed", &"fuji_rescued", &"silph_scope",
			&"got_silph_scope"]:
		state.flags.set_flag(flag)
	assert_true(GhostRule.is_ghost(SCOPE, state.bag), "drapeaux levés, Sac vide : SPECTRE")
	state.bag.add(SCOPE)
	assert_false(GhostRule.is_ghost(SCOPE, state.bag), "Scope dans le Sac : rencontre normale")
	assert_true(GhostRule.is_ghost_for(&"always", SCOPE, state.bag), "`always` : SPECTRE")


# --- §2.13 point 4 : vraie Boot, sauvegarde au 6F puis Scope ajouté au fichier -----------------

## Boot sur [param fs] : reprise de la sauvegarde si le fichier existe, sinon nouvelle partie au
## 6F (case `devant_spectre`).
func _start_boot(fs: MemoryFs) -> void:
	GameState.clock = FixedClock.new("2026-10-19T14:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(fs, BOOT_PATH)
	_boot.start_map = MAP_6F
	_boot.start_spawn = SPAWN_6F
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	_boot.get_battle_hud().get_message_banner().message_shown.connect(
		func(text: String, _wait: bool) -> void: _shown_lines.append(text))


func _stop_boot() -> void:
	remove_child(_boot)
	_boot.free()
	_boot = null
	await wait_process_frames(2)


## Contenu du fichier de [param fs] (dictionnaire vide s'il manque).
func _file(fs: MemoryFs) -> Dictionary:
	var parsed: Variant = JSON.parse_string(fs.files.get(BOOT_PATH, ""))
	return parsed if parsed is Dictionary else {}


## Partie J19 au 6F : drapeaux du départ `tower_6f_block` (J18 jusqu'à la Tour) et du J19 sauf la
## victoire contre le rival n° 5 ; Reptincel N25, 10 Poké Balls, aucun Scope.
func _fill_j19_game() -> void:
	var start := _fixture(BLOCK_START)
	for flag: Variant in start["flags"]:
		GameState.flags.set_flag(StringName(flag))
	for flag: StringName in J19_FLAGS:
		if flag != &"rival_tower_won":
			GameState.flags.set_flag(flag)
	GameState.starter_species = &"charmander"
	var party := Party.new()
	party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"charmeleon", 25, GameRng.new(5)))
	GameState.party = party
	GameState.bag.add(BALL, 10)


## Pilote le combat en cours : relève les règles au premier choix, puis FUITE à chaque choix,
## jusqu'à la fin du combat, de la rencontre, de la scène et des dialogues. Renvoie
## [issue, règles du combat (ou null)].
func _flee_everything() -> Array:
	var enc := _boot.get_encounter_director()
	var battles := _boot.get_battle_director()
	var cutscenes := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var hud := _boot.get_battle_hud()
	var box := _boot.get_dialogue_box()
	var result: Array = [Battle.Outcome.NONE, null]
	var on_finished := func(_id: StringName, o: int) -> void: result[0] = o
	battles.battle_finished.connect(on_finished)
	await wait_until(func() -> bool: return battles.is_running(), TIMEOUT)
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (battles.is_running() or enc.is_running() or cutscenes.is_running()
			or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		var battle := battles.get_battle() if battles.is_running() else null
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			if result[1] == null:
				result[1] = battle.get_rules()
			if hud.get_zone() == BattleHud.Zone.ACTIONS:
				hud.action_selected.emit(ActionGrid.RUN)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	battles.battle_finished.disconnect(on_finished)
	assert_false(battles.is_running(), "combat fini")
	assert_false(cutscenes.is_running(), "scène finie")
	return result


func test_a_j19_save_with_the_scope_added_meets_named_wild_pokemon_but_the_6f_ghost_stays() \
		-> void:
	var fs := MemoryFs.new()
	# 1. Sauvegarder au 6F (vraie Boot, coordinateur de sauvegarde).
	await _start_boot(fs)
	assert_false(_boot.has_resumed(), "nouvelle partie : aucune sauvegarde à lire")
	assert_true(_boot.is_autosave_enabled())
	assert_eq(_boot.get_map().map_id, MAP_6F)
	assert_eq(_boot.get_player().get_cell(), CELL_6F, "devant le SPECTRE")
	_fill_j19_game()
	_boot.request_autosave("T22 : sauvegarde au 6F")
	await wait_until(func() -> bool:
		return (_file(fs).get("flags", []) as Array).has("tower_stairs_open"), TIMEOUT)
	var saved := _file(fs)
	assert_eq(int(saved.get("version", 0)), 7, "toujours v7")
	assert_eq(saved.get("map"), String(MAP_6F), "sauvegardée au 6F")
	for flag: StringName in J19_FLAGS:
		if flag != &"rival_tower_won":
			assert_has(saved["flags"] as Array, String(flag), "%s écrit" % flag)
	assert_false(((saved["bag"] as Dictionary)["items"] as Dictionary).has(String(SCOPE)),
		"pas de Scope au J19")
	await _stop_boot()

	# 2. Ajouter `silph_scope` au Sac du fichier (comme le fera le J20).
	var edited: Dictionary = saved.duplicate(true)
	((edited["bag"] as Dictionary)["items"] as Dictionary)[String(SCOPE)] = 1
	fs.files[BOOT_PATH] = JSON.stringify(edited, "\t")

	# 3. Recharger.
	_shown_lines.clear()
	await _start_boot(fs)
	assert_true(_boot.has_resumed(), "sauvegarde reprise")
	assert_true(_boot.is_autosave_enabled(), "rien d'écarté, l'autosave continue")
	assert_false(fs.files.has(BOOT_PATH + ".rejected"), "aucune entrée écartée")
	assert_eq(_boot.get_map().map_id, MAP_6F, "reprise au 6F")
	assert_eq(GameState.bag.count_of(SCOPE), 1, "Scope relu dans le Sac")
	assert_true(GameState.flags.has_flag(&"tower_stairs_open"))
	assert_false(GameState.pokedex.is_seen(&"gastly"))
	GameState.party.get_lead().stats[&"spe"] = 999

	# 4. Forcer une rencontre (6F, avec le Scope) : rencontre normale.
	var enc := _boot.get_encounter_director()
	var battles := _boot.get_battle_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"gastly", 22)), "rencontre forcée")
	await wait_until(func() -> bool:
		return battles.get_battle() != null \
			and battles.get_battle().get_state() == Battle.State.CHOOSING, TIMEOUT)
	var battle := battles.get_battle()
	assert_not_null(battle)
	if battle == null:
		return
	assert_false(battle.get_rules().ghost, "Scope en poche : pas de SPECTRE")
	assert_false(battle.refuses_balls(), "les Balls ne sont pas refusées")
	assert_true(battle.is_legal(BattleAction.ball(BALL)), "Ball acceptée")
	# PR n° 1 : une demande d'écriture pendant le combat attend le retour au calme.
	var before_battle_save: String = fs.files[BOOT_PATH]
	assert_false(_boot.is_stable(), "combat : partie instable")
	_boot.request_autosave("T22 : pendant le combat")
	await wait_process_frames(3)
	assert_eq(fs.files[BOOT_PATH], before_battle_save, "rien d'écrit pendant le combat")
	var fled: Array = await _flee_everything()
	assert_eq(fled[0], Battle.Outcome.FLED, "fuite")
	var name := _boot.get_pokemon_data().get_species(&"gastly").name
	assert_true(_shown_lines.any(func(l: String) -> bool: return l.contains(name)),
		"nom réel affiché (%s)" % name)
	assert_false(_shown_lines.has(GHOST_LINE), "aucun SPECTRE")
	assert_true(GameState.pokedex.is_seen(&"gastly"), "« vu » au Pokédex")
	await wait_until(func() -> bool:
		return (_file(fs).get("pokedex", {}) as Dictionary) != (JSON.parse_string(
			before_battle_save) as Dictionary).get("pokedex", {}), TIMEOUT)
	assert_ne(fs.files[BOOT_PATH], before_battle_save, "la demande est écrite au retour au calme")
	assert_eq(int(_file(fs).get("version", 0)), 7)
	var items: Dictionary = (_file(fs)["bag"] as Dictionary)["items"]
	assert_eq(int(items.get(String(SCOPE), 0)), 1, "le Scope reste dans le fichier")

	# Le SPECTRE du 6F reste un SPECTRE (`ghost: always`), même Scope en poche.
	_shown_lines.clear()
	watch_signals(GameState.pokedex)
	var player := _boot.get_player()
	_boot.get_map().spawn_player_at(player, BEFORE_TRIGGER, Vector2i.DOWN)
	await wait_process_frames(3)
	var file_before_scene: String = fs.files[BOOT_PATH]
	var cutscenes := _boot.get_cutscene_director()
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return cutscenes.is_running(), TIMEOUT)
	Input.action_release(&"move_down")
	assert_eq(cutscenes.get_cutscene_id(), &"tower_6f_ghost", "la scène du SPECTRE")
	_boot.request_autosave("T22 : pendant la scène")
	var ghost: Array = await _flee_everything()
	assert_eq(ghost[0], Battle.Outcome.FLED, "la fuite réussit")
	var rules := ghost[1] as BattleRules
	assert_not_null(rules)
	if rules != null:
		assert_true(rules.ghost, "SPECTRE malgré le Scope")
	assert_has(_shown_lines, GHOST_LINE)
	assert_false(GameState.pokedex.is_seen(&"marowak"), "Ossatueur jamais vu")
	assert_signal_not_emitted(GameState.pokedex, "recorded", "rien au Pokédex")
	assert_eq(player.get_cell(), BEFORE_TRIGGER, "repoussé en (10, 15)")
	assert_eq(GameState.bag.count_of(SCOPE), 1, "Scope toujours là")
	assert_false(GameState.flags.has_flag(&"ghost_marowak_calmed"), "drapeau du J21 jamais posé")
	await wait_until(func() -> bool: return fs.files[BOOT_PATH] != file_before_scene, TIMEOUT)
	assert_eq(_file(fs).get("map"), String(MAP_6F), "écrite après la scène, au 6F")
	var cell: Array = _file(fs).get("cell", [])
	assert_eq(Vector2i(int(cell[0]), int(cell[1])), BEFORE_TRIGGER, "case stable")
	assert_push_error_count(0)
