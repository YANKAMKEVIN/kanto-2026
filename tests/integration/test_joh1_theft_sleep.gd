extends GutTest
## JOH1, remise en scène du vol (demande de Kevin du 2026-11-04 : « voir le joueur dormir
## vraiment »). Le **vrai Boot** joue l'arrivée au Centre d'Oliville ; à chaque ligne de nuit
## (O-9), on relève ce qui est à l'écran :
## - « … » : la chambre de nuit, le joueur caché, couché dans le lit ([SleeperBed], apparence du
##   héros ou de la joueuse, « z » qui montent), table d'Orme aux socles vides ;
## - « Un bruit de verre. » : plan sur le rez-de-chaussée dans la pénombre (profil
##   `interior_night_dark`), joueur caché, infirmière absente, plateau des Poké Balls sur le
##   comptoir, deux Sbires ;
## - « Une porte qui claque. » : les Sbires sont partis avec le plateau ;
## puis retour au lit, et l'écriture du vol (drapeau de la pénombre baissé, chambre, équipe vide).
## Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tests/fixtures/debug_start/johto_olivine_night_autosave.json"
const SAVE_PATH := "user://test_joh1_sleep_save.json"
const SETTINGS_PATH := "user://test_joh1_sleep_settings.json"
const ABSENT := "user://test_joh1_sleep_absent.json"
const EMPTY_TABLE := "res://assets/world/interiors/int_table_starters_vide_01.png"
const HERO_BED := "res://assets/world/interiors/int_lit_dormeur_heros_01.png"
const HEROINE_BED := "res://assets/world/interiors/int_lit_dormeur_joueuse_01.png"
const TIMEOUT := 25.0

var _fs: MemoryFs
var _boot: Boot
var _previous_scene: Node
var _seen: Dictionary = {}


func before_each() -> void:
	_fs = MemoryFs.new()
	_seen = {}
	_previous_scene = get_tree().current_scene
	GameState.clock = FixedClock.new("2026-11-04T12:00:00")


func after_each() -> void:
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null
	GameState.clock = DeviceClock.new()


func _launch(look: StringName) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.debug_start_path = START
	_boot.debug_unlocks_path = ABSENT
	_boot.force_debug_start = true
	_boot.opening_speed_scale = 0.0
	var boot := _boot
	boot.tree_entered.connect(func() -> void: get_tree().current_scene = boot,
		CONNECT_ONE_SHOT)
	get_tree().root.add_child(boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	GameState.player_look = look
	_boot.get_cutscene_director().step_played.connect(_on_step)
	await wait_process_frames(2)


func _saved() -> Dictionary:
	if not _fs.files.has(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	return parsed if parsed is Dictionary else {}


## Relevé de l'écran au début de chaque ligne de nuit.
func _on_step(step: CutsceneStep) -> void:
	if step.kind != CutsceneStep.Kind.DIALOGUE \
			or not String(step.dialogue_id).begins_with("olivine_night_"):
		return
	var map := _boot.get_map()
	var player := SceneRouter.get_player()
	var sleeper := map.get_node_or_null(^"Sleeper") as SleeperBed
	var table := map.get_node_or_null(^"Entities/StarterTable/Sprite") as Sprite2D
	var tray := map.get_node_or_null(^"Entities/NightTray") as Node2D
	_seen[step.dialogue_id] = {
		"map": map.map_id,
		"player_visible": player.visible,
		"tucked": sleeper != null and sleeper.is_tucked_in(),
		"look": sleeper.get_look() if sleeper != null else &"",
		"bed": ((map.get_node(^"Entities/Bed/Sprite") as Sprite2D).texture.resource_path
			if map.has_node(^"Entities/Bed/Sprite") else ""),
		"zzz": sleeper.get_z_count() if sleeper != null else 0,
		"zoom": player.get_camera().zoom.x,
		"table": table.texture.resource_path if table != null else "",
		"light": _boot.get_world_lighting().get_profile().id
			if _boot.get_world_lighting().get_profile() != null else &"",
		"nurse": map.get_npc(&"nurse") != null,
		"tray_on_counter": tray != null and tray.visible,
		"sbires": int(map.get_npc(&"sbire_1") != null) + int(map.get_npc(&"sbire_2") != null),
	}


func _play_theft() -> void:
	await wait_until(func() -> bool: return _boot.get_cutscene_director().is_running(), TIMEOUT)
	assert_eq(_boot.get_cutscene_director().get_cutscene_id(), &"olivine_center_arrival")
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while not (_saved().get("flags", []) as Array).has("johto_team_stolen") \
			and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)


func test_the_player_sleeps_while_the_grunts_take_the_tray() -> void:
	await _launch(&"hero")
	await _play_theft()
	var night: Dictionary = _seen.get(&"olivine_night_1", {})
	assert_eq(night.get("map"), &"olivine_center_room", "« … » : dans la chambre")
	assert_false(night.get("player_visible", true), "le joueur n'est pas debout")
	assert_true(night.get("tucked", false), "il est couché dans le lit")
	assert_eq(night.get("look"), &"hero")
	assert_eq(night.get("bed"), HERO_BED, "lit occupé par le héros")
	assert_gt(int(night.get("zzz", 0)), 0, "des « z » montent")
	assert_gt(float(night.get("zoom", 1.0)), 1.0, "léger zoom sur le lit (retour de Kevin)")
	assert_eq(night.get("table"), EMPTY_TABLE, "aucune Poké Ball sur la table")
	var glass: Dictionary = _seen.get(&"olivine_night_2", {})
	assert_eq(glass.get("map"), &"olivine_center", "plan sur le rez-de-chaussée")
	assert_false(glass.get("player_visible", true), "le joueur dort en haut")
	assert_eq(float(glass.get("zoom", 0.0)), 1.0, "plan du rez-de-chaussée sans zoom")
	assert_eq(glass.get("light"), &"interior_night_dark", "pénombre")
	assert_false(glass.get("nurse", true), "l'infirmière n'est pas au comptoir")
	assert_true(glass.get("tray_on_counter", false), "le plateau est sur le comptoir")
	assert_eq(glass.get("sbires"), 2, "deux silhouettes")
	var door: Dictionary = _seen.get(&"olivine_night_4", {})
	assert_eq(door.get("map"), &"olivine_center")
	assert_eq(door.get("sbires"), 0, "les Sbires sont partis")
	assert_false(door.get("tray_on_counter", true), "avec le plateau")
	var saved := _saved()
	var flags: Array = saved.get("flags", [])
	assert_true(flags.has("johto_team_stolen"))
	assert_false(flags.has("johto_center_dark"), "la pénombre n'est pas écrite")
	assert_eq(saved.get("map"), "olivine_center_room", "écrite dans la chambre")
	assert_eq((saved.get("party", [1]) as Array).size(), 0, "équipe vide")
	# Le matin (O-10) : le joueur se relève (changement de carte sans pose).
	await wait_until(func() -> bool: return SceneRouter.get_player().visible, TIMEOUT)
	assert_true(SceneRouter.get_player().visible, "debout au réveil")
	assert_false(SceneRouter.get_player().is_framed(), "caméra rendue au matin")
	assert_eq(SceneRouter.get_player().get_camera().zoom, Vector2.ONE)


func test_the_heroine_sleeps_in_her_own_bed() -> void:
	await _launch(&"heroine")
	await _play_theft()
	var night: Dictionary = _seen.get(&"olivine_night_1", {})
	assert_true(night.get("tucked", false))
	assert_eq(night.get("look"), &"heroine")
	assert_eq(night.get("bed"), HEROINE_BED, "lit occupé par la joueuse")
