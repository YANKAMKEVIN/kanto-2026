extends GutTest
## Costumes avec le vrai Boot (dossier-costumes.md) : choix depuis l'écran Dresseur (CO-1, CO-7),
## le joueur du monde et le buste se rhabillent aussitôt, autosave à la fermeture ; annonce
## « Nouveau costume : … » à la fin de la scène qui remet le badge (CO-4).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_costumes_boot_save.json"
const FIXTURE_V1 := "res://tests/fixtures/save/v1_after_capture.json"

var _boot: Boot
var _menu: MenuDirector
var _screen: Node


func before_each() -> void:
	GameState.clock = FixedClock.new("2026-11-01T10:00:00")


func after_each() -> void:
	get_tree().paused = false
	GameState.clock = DeviceClock.new()
	GameState.player_costume = GameState.NO_COSTUME
	MenuArt.player_costume = &""


func _start() -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE_PATH] = FileAccess.get_file_as_string(FIXTURE_V1)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(fs, SAVE_PATH)
	add_child_autofree(_boot)
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	_boot.get_trainer_menu().speed_scale = 0.0
	await wait_until(func() -> bool: return _boot.is_stable(), 12.0)


func test_choosing_a_costume_dresses_the_player_at_once() -> void:
	await _start()
	GameState.flags.set_flag(&"badge_boulder")
	assert_true(_menu.open(MenuRoute.trainer()))
	var view: TrainerView = _screen.trainers.back()
	assert_eq(view.costumes.size(), 9)
	assert_true(view.costumes[1].unlocked)
	assert_false(_menu.choose_costume(&"cascade"), "verrouillé : rien")
	assert_true(_menu.choose_costume(&"boulder"))
	assert_eq(GameState.player_costume, &"boulder")
	assert_eq(MenuArt.player_costume, &"boulder", "le buste suit")
	assert_eq(_screen.trainers.size(), 2, "vue neuve")
	assert_true((_screen.trainers.back() as TrainerView).costumes[1].worn)
	var player := _boot.get_player()
	var sprite := player.get_node("%Sprite") as AnimatedSprite2D
	assert_eq(sprite.sprite_frames.resource_path,
		CharacterLook.painted_frames_path(&"costumes/roche_joueur"))
	var changed := [false]
	_menu.menu_closed.connect(func(c: bool) -> void: changed[0] = c)
	_menu.close()
	assert_true(changed[0], "autosave à la fermeture")


func test_the_badge_scene_announces_its_costume_at_its_end() -> void:
	await _start()
	var step := CutsceneStep.new()
	step.kind = CutsceneStep.Kind.BADGE
	step.badge_id = &"cascade"
	GameState.flags.set_flag(&"badge_cascade")
	var toast := _boot.get_hud().get_toast()
	watch_signals(toast)
	_boot._on_costume_badge_step(step)
	assert_signal_not_emitted(toast, "toast_shown", "pas pendant la scène")
	_boot._announce_costume()
	assert_signal_emitted_with_parameters(toast, "toast_shown", ["Nouveau costume : Luffy", ""])
	assert_not_null(toast.get_icon(), "vignette du costume")
	_boot._announce_costume()
	assert_signal_emit_count(toast, "toast_shown", 1, "une seule fois")


func test_the_costume_waits_for_the_tm_toast() -> void:
	await _start()
	var step := CutsceneStep.new()
	step.kind = CutsceneStep.Kind.BADGE
	step.badge_id = &"cascade"
	GameState.flags.set_flag(&"badge_cascade")
	var toast := _boot.get_hud().get_toast()
	toast.show_toast("CT11", "Ajoutée au Sac")
	watch_signals(toast)
	_boot._on_costume_badge_step(step)
	_boot._announce_costume()
	assert_eq(toast.get_title_text(), "CT11", "le toast de la CT reste")
	toast.hide_now()
	# La disparition dure ANIM_MICRO : attendre l'état, pas un nombre d'images (CI chargée).
	await wait_until(func() -> bool: return toast.get_title_text() != "CT11", 2.0)
	assert_eq(toast.get_title_text(), "Nouveau costume : Luffy", "puis le costume")
