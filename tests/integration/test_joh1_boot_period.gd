extends GutTest
## Boot et le moment imposé par l'histoire (JOH1, `jalon-joh1.md` §2.4) sur les vrais départs de
## débogage : nuit à l'arrivée à Oliville (lampes allumées sur la carte `johto_auto`), matin dans
## la chambre après le vol, heure réelle dès `johto_orme_left`, et un départ qui impose `period`
## garde la main sur la règle.

const BOOT_SCENE := preload("res://game/boot.tscn")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const TIMEOUT := 8.0

var _boot: Boot


func _start(start_path: String) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_joh1_boot_period.json")
	_boot.force_debug_start = true
	_boot.debug_start_path = start_path
	add_child_autofree(_boot)
	await wait_process_frames(3)
	await wait_until(func() -> bool:
		return _boot.is_stable() or _boot.get_dialogue_runner().is_running(), TIMEOUT)
	await wait_process_frames(2)


func _lit_lamps() -> int:
	var map := _boot.get_map()
	var lit := 0
	for node: Node in get_tree().get_nodes_in_group(WorldLighting.GROUP_NIGHT_LIGHTS):
		if map.is_ancestor_of(node) and (node as CanvasItem).visible:
			lit += 1
	return lit


func test_night_is_forced_from_the_letter_to_the_theft() -> void:
	await _start("res://tools/debug_start/johto_olivine_night.json")
	assert_eq(_boot.get_map().map_id, &"olivine_city")
	var clock := _boot.get_world_clock()
	assert_true(clock.is_period_forced(), "moment imposé par la règle")
	assert_eq(clock.period(), WorldClock.Period.NIGHT)
	assert_gt(_lit_lamps(), 0, "lampes de nuit allumées")
	assert_eq(_boot.period_for_map(&"olivine_city"), &"night")


func test_morning_after_the_theft_then_real_time_once_orme_left() -> void:
	await _start("res://tools/debug_start/johto_orme.json")
	assert_eq(_boot.get_map().map_id, &"olivine_center_room")
	var clock := _boot.get_world_clock()
	assert_eq(clock.period(), WorldClock.Period.MORNING)
	assert_true(clock.is_period_forced())
	GameState.flags.set_flag(&"johto_orme_left")
	await wait_process_frames(2)
	assert_false(clock.is_period_forced(), "heure réelle dès le départ d'Orme")


func test_a_debug_period_wins_over_the_story_rule() -> void:
	await _start("res://tools/debug_start/johto_olivine_day.json")
	var clock := _boot.get_world_clock()
	assert_eq(clock.period(), WorldClock.Period.DAY, "jour imposé par le départ")
	assert_eq(_lit_lamps(), 0, "lampes éteintes de jour")
	# La règle dirait « matin » si Orme n'était pas reparti : le débogage garde la main.
	GameState.flags.set_flag(&"johto_orme_left", false)
	await wait_process_frames(2)
	assert_eq(clock.period(), WorldClock.Period.DAY)
	GameState.flags.set_flag(&"johto_orme_left")
