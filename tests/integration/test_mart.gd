extends GutTest
## La Boutique jouable (jalon 7 T12, jalon-07.md §6.4, §6.10 ; dossier 09 §4, §9, §10, §19) avec
## la vraie scène Boot, le vrai écran Boutique (T11), la vraie carte et la partie du départ de
## débogage `shop_qa` (6 000 ₽, Potions favorites, devant la Boutique) et une sauvegarde en
## mémoire :
## - première visite : on entre, le marchand interpelle, le joueur va à la caisse, les quatre
##   répliques du §19, le colis au Sac, le toast « COLIS POUR CHEN — ajouté aux objets clés »,
##   l'objectif du tableau de bord change en silence ; la Boutique ne s'ouvre pas d'elle-même ;
##   sauvegarde écrite (fin de scène) ; une seule fois ;
## - visites suivantes : parler au marchand → « Bonjour ! Qu'est-ce qu'il te faut aujourd'hui ? »
##   → la Boutique s'ouvre seule (sans tableau de bord) ;
## - achat → argent et Sac ; argent insuffisant → refus, rien ne change ; vente d'une Potion
##   favorite après la confirmation (vraie ChoiceCards) ; colis absent de VENDRE ; fermeture →
##   sauvegarde relue (argent, Sac, favori) ; retour Android : confirmation d'abord, puis fermer.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const START := "res://tools/debug_start/shop_qa.json"
const SAVE_PATH := "user://test_mart_save.json"
const DATE := "2026-10-05T18:30:00"
const FADE := 0.05
const TIMEOUT := 12.0
const DOOR := Vector2i(30, 20)
const PARCEL_PAGES: Array[String] = [
	"Bonjour ! Première fois à Jadielle ?",
	"Hmm… Ce Pokémon vient du laboratoire du Professeur Chen, non ?",
	"Ça tombe bien. J'ai justement reçu quelque chose pour lui ce matin.",
	"Tu pourrais lui remettre quand tu retourneras à Bourg Palette ?",
]
const GREETING := "Bonjour ! Qu'est-ce qu'il te faut aujourd'hui ?"
const OBJECTIVE := "Objectif : remettre le colis au Professeur Chen."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _menu: MenuDirector
var _screen: TrainerMenu
var _saved_router: Array = []
var _pages: Array[String] = []
var _toasts: Array[PackedStringArray] = []
var _scenes: Array[StringName] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_pages.clear()
	_toasts.clear()
	_scenes.clear()
	Haptics.sink = func(_ms: int) -> void: pass


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot (sauvegarde en mémoire, autosave actif) sur [param map] / [param spawn], puis la partie
## de `shop_qa`, appliquée à la main (un départ de débogage n'écrirait rien).
func _start(map: StringName = &"viridian_city", spawn: StringName = &"from_mart",
		facing: Vector2i = Vector2i.DOWN, flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	_menu = _boot.get_menu_director()
	_screen = _boot.get_trainer_menu()
	_screen.speed_scale = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	_runner.page_started.connect(func(_i: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	_boot.get_cutscene_director().cutscene_started.connect(_scenes.append)
	await wait_process_frames(3)


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _advance_while(busy: Callable) -> void:
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while busy.call() and Time.get_ticks_msec() < deadline:
		if box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)


## Depuis le spawn devant la porte (tourné vers le sud) : un pas en bas, puis vers le haut
## jusqu'à la scène de la première visite (porte → paillasson → rangée d'entrée).
func _walk_in() -> void:
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _player.get_cell() == DOOR + Vector2i.DOWN, TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool:
		return _boot.get_cutscene_director().is_running() \
			or (_boot.get_map().map_id == &"viridian_mart" and _player.get_cell().y <= 6),
		TIMEOUT)
	Input.action_release(&"move_up")


func _talk_to_the_clerk() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _advance_while(func() -> bool: return _runner.is_running())
	# Pas de wait_until ici : la Boutique ouverte met l'arbre en pause (les minuteries de GUT
	# aussi) ; des images, si.
	await wait_process_frames(3)


func test_shop_qa_starts_in_front_of_the_mart() -> void:
	await _start()
	assert_eq(_boot.get_map().map_id, &"viridian_city")
	assert_eq(_player.get_cell(), DOOR)
	assert_eq(GameState.money, 6000)
	assert_true(GameState.bag.is_favorite(&"potion"), "Potions favorites")
	assert_false(GameState.flags.has_flag(&"got_oak_parcel"))
	assert_eq(_menu.build_dashboard().objective_text, "", "plus de ligne après l'arrivée")


func test_first_visit_gives_the_parcel_once_and_updates_the_objective_silently() -> void:
	await _start()
	var writes := _writes()
	await _walk_in()
	assert_eq(_boot.get_map().map_id, &"viridian_mart", "entré dans la Boutique")
	assert_eq(_scenes, [&"mart_parcel"] as Array[StringName], "scène de la première visite")
	await _advance_while(func() -> bool: return _boot.get_cutscene_director().is_running())
	await wait_process_frames(3)
	assert_eq(_pages, PARCEL_PAGES, "les quatre répliques du §19, mot pour mot")
	assert_eq(_player.get_cell(), Vector2i(7, 5), "à la caisse")
	assert_eq(_player.get_facing(), Vector2i.UP, "face au marchand")
	assert_eq(GameState.bag.count_of(&"oak_parcel"), 1, "le colis au Sac")
	assert_true(GameState.flags.has_flag(&"got_oak_parcel"))
	assert_eq(_toasts, [PackedStringArray(["COLIS POUR CHEN", "ajouté aux objets clés"])],
		"toast du colis")
	assert_eq(_menu.build_dashboard().objective_text, OBJECTIVE, "objectif changé en silence")
	assert_false(_menu.is_open(), "la Boutique ne s'ouvre pas d'elle-même")
	assert_true(_player.is_input_enabled(), "joueur libre")
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)
	var saved := _saved()
	assert_true((saved.get("flags", []) as Array).has("got_oak_parcel"), "drapeau écrit")
	var bag: Dictionary = (saved.get("bag", {}) as Dictionary).get("items", {})
	assert_eq(int(bag.get("oak_parcel", 0)), 1, "colis écrit")
	# En ressortant puis en revenant : plus rien.
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _player.get_cell() == Vector2i(7, 7), TIMEOUT)
	Input.action_release(&"move_down")
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return _player.get_cell() == Vector2i(7, 6), TIMEOUT)
	Input.action_release(&"move_up")
	await wait_process_frames(5)
	assert_eq(_scenes.size(), 1, "une seule fois")
	assert_eq(GameState.bag.count_of(&"oak_parcel"), 1, "un seul colis")
	assert_push_error_count(0)


func test_later_visits_open_the_shop_alone() -> void:
	await _start(&"viridian_mart", &"counter", Vector2i.UP, [&"got_oak_parcel"])
	await _talk_to_the_clerk()
	assert_eq(_pages, [GREETING] as Array[String])
	assert_eq(_scenes.size(), 0, "aucune scène")
	assert_true(_menu.is_open(), "la Boutique s'ouvre à la fin du dialogue")
	assert_true(_menu.get_navigator().is_standalone(), "écran seul")
	assert_eq(_menu.get_navigator().current().get_param("shop"), &"viridian_mart")
	assert_true(get_tree().paused, "monde en pause")
	var shop := _screen.get_shop()
	assert_not_null(shop, "le vrai ShopScreen")
	if shop != null:
		assert_true(shop.is_visible_in_tree(), "affiché")
		assert_eq(shop.get_money_text(), MenuFormat.money(6000))
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_false(_menu.is_open(), "retour Android = fermer")
	assert_false(get_tree().paused)
	assert_push_error_count(0)


func test_buy_refuse_sell_a_favorite_and_save_on_close() -> void:
	await _start(&"viridian_mart", &"counter", Vector2i.UP, [&"got_oak_parcel"])
	GameState.bag.add(&"oak_parcel", 1)
	await _talk_to_the_clerk()
	var shop := _screen.get_shop()
	var writes := _writes()
	# Achat : 2 Poké Balls (400 ₽).
	_screen.shop_buy_requested.emit(&"poke_ball", 2)
	await wait_process_frames(2)
	assert_eq(GameState.money, 5600)
	assert_eq(GameState.bag.count_of(&"poke_ball"), 5)
	assert_eq(shop.get_money_text(), MenuFormat.money(5600), "argent à jour à l'écran")
	assert_eq(_writes(), writes, "rien d'écrit menu ouvert")
	# Argent insuffisant : rien ne change.
	GameState.money = 250
	_screen.shop_buy_requested.emit(&"potion", 1)
	await wait_process_frames(2)
	assert_eq(GameState.money, 250)
	assert_eq(GameState.bag.count_of(&"potion"), 4)
	GameState.money = 5600
	# VENDRE : le colis n'y est pas ; une Potion favorite demande une confirmation.
	_screen.shop_mode_changed.emit(ShopViews.MODE_SELL)
	await wait_process_frames(2)
	var view := _menu.build_shop()
	assert_eq(view.mode, ShopViews.MODE_SELL)
	assert_null(view.entry(&"oak_parcel"), "colis absent de VENDRE")
	assert_not_null(view.entry(&"potion"))
	_screen.shop_sell_requested.emit(&"potion", 1, false)
	await wait_process_frames(2)
	var cards := _screen.get_shop_choice()
	assert_not_null(cards)
	if cards == null:
		return
	assert_true(cards.is_showing(), "confirmation affichée")
	assert_eq(GameState.bag.count_of(&"potion"), 4, "rien vendu avant")
	cards.get_confirm_button().pressed.emit()
	await wait_process_frames(2)
	assert_eq(GameState.bag.count_of(&"potion"), 3, "vendue après VENDRE")
	assert_eq(GameState.money, 5600 + 150, "moitié du prix")
	assert_true(GameState.bag.is_favorite(&"potion"), "toujours favorite")
	# Retour Android avec une confirmation ouverte : elle se ferme, la Boutique reste.
	_screen.shop_sell_requested.emit(&"potion", 1, false)
	await wait_process_frames(2)
	assert_true(cards.is_showing())
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_false(cards.is_showing(), "confirmation fermée")
	assert_true(_menu.is_open(), "la Boutique reste ouverte")
	assert_eq(GameState.bag.count_of(&"potion"), 3, "ANNULER : rien vendu")
	# Fermeture : autosave, relu.
	_menu.close()
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)
	var saved := _saved()
	assert_eq(int(saved.get("money", -1)), 5750, "argent écrit")
	var bag: Dictionary = saved.get("bag", {})
	var items: Dictionary = bag.get("items", {})
	assert_eq(int(items.get("poke_ball", 0)), 5)
	assert_eq(int(items.get("potion", 0)), 3)
	assert_eq(int(items.get("oak_parcel", 0)), 1, "le colis gardé")
	assert_true((bag.get("favorites", []) as Array).has("potion"))
	# Relue par le système de sauvegarde dans une partie neuve.
	var reloaded: Node = autofree(GameStateScript.new())
	assert_true(reloaded.load_dict(SaveSystem.new(_fs, SAVE_PATH).read(),
		_boot.get_pokemon_data()))
	assert_eq(reloaded.money, 5750)
	assert_eq(reloaded.bag.count_of(&"potion"), 3)
	assert_true(reloaded.bag.is_favorite(&"potion"))
	assert_true(reloaded.flags.has_flag(&"got_oak_parcel"))
	assert_push_error_count(0)
