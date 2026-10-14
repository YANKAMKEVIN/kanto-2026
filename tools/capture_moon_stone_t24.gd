extends SceneTree
## Captures du T24 (jalon 12 : Sac AVENTURE, Pierre Lune, Corde Sortie, évolution sans ARRÊTER,
## toast et Grand moment du fossile), vrai Boot sur la Route 1, à vitesse réelle :
##   01_bag_field          Sac → AVENTURE, Pierre Lune sélectionnée (UTILISER)
##   02_bag_escape_rope    Corde Sortie sélectionnée (UTILISER)
##   03_escape_rope_refused  UTILISER hors d'une grotte : refus dans le bandeau
##   04_stone_targets      Pierre Lune → UTILISER : COMPATIBLE / INCOMPATIBLE
##   05_stone_present      « Quoi ? Mélofée évolue ! »
##   06_stone_transform    transformation, **sans ARRÊTER**
##   07_stone_rushed       après un toucher à l'emplacement d'ARRÊTER : accélérée
##   08_stone_end          « MÉLODELFE », phrase, consigne
##   09_fossil_toast       toast « Fossile Dôme » / « obtenu »
##   10_trainer_fossil     écran Dresseur, frise avec « La Team Rocket repoussée »
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_moon_stone_t24.gd -- --out=build/captures/jalon12_t24

const FPS := 30.0

var _boot: Node
var _out_dir: String = "build/captures/jalon12_t24"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _seconds(seconds: float) -> void:
	await _frames(roundi(seconds * FPS))


func _shot(name: String) -> void:
	await _frames(2)
	var path := _out_dir.path_join(name + ".png")
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path)


func _touch_at(point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.pressed = pressed
		touch.position = point
		root.push_input(touch, true)


func _start() -> void:
	var state: Node = root.get_node("GameState")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	state.call(&"new_game", 5)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.set(&"starter_species", &"charmander")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	for spec: Array in [[&"clefairy", 14], [&"charmander", 16], [&"jigglypuff", 12],
			[&"nidorino", 18], [&"pidgey", 11]]:
		party.add(PokemonFactory.create(data, spec[0], spec[1], GameRng.new(7)))
	party.get_at(2).hp = 0
	var bag: Bag = state.get(&"bag")
	bag.add(&"potion", 3)
	bag.add(&"moon_stone", 2)
	bag.add(&"escape_rope", 1)
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	menu.open(MenuRoute.bag())
	await _frames(20)
	var bag_screen := screen.get_bag()
	bag_screen.open_category(&"field")
	bag_screen.select_item(&"moon_stone")
	await _frames(20)
	await _shot("01_bag_field")
	bag_screen.select_item(&"escape_rope")
	await _frames(20)
	await _shot("02_bag_escape_rope")
	bag_screen.get_action_button().pressed.emit()
	await _frames(20)
	await _shot("03_escape_rope_refused")
	bag_screen.select_item(&"moon_stone")
	await _frames(10)
	bag_screen.get_action_button().pressed.emit()
	await _frames(20)
	await _shot("04_stone_targets")
	menu.use_item_on(&"moon_stone", 0)
	var evolutions: EvolutionDirector = _boot.call(&"get_evolution_director")
	var evo_screen := evolutions.get_screen()
	await _seconds(1.4)
	await _shot("05_stone_present")
	await _seconds(1.4)
	await _shot("06_stone_transform")
	# Toucher là où serait ARRÊTER pour une évolution de combat : la séquence accélère.
	_touch_at(evo_screen.get_stop_button().get_global_rect().get_center())
	await _frames(4)
	print("ACCÉLÉRÉE ", evo_screen.is_rushed(), " ARRÊTER visible ",
		evo_screen.get_stop_button().visible)
	await _shot("07_stone_rushed")
	var guard := 0
	while not evo_screen.is_waiting_touch() and guard < 600:
		await process_frame
		guard += 1
	await _seconds(0.6)
	await _shot("08_stone_end")
	guard = 0
	while evolutions.is_playing() and guard < 900:
		if guard % 20 == 0:
			_touch_at(root.get_visible_rect().size * Vector2(0.5, 0.3))
		await process_frame
		guard += 1
	await _seconds(1.0)
	print("PIERRES RESTANTES ", bag.count_of(&"moon_stone"), " ESPÈCE ", party.get_at(0).species_id)
	bag.add(&"dome_fossil", 1)
	_boot.call(&"_on_item_given", &"dome_fossil", 1)
	await _seconds(0.6)
	await _shot("09_fossil_toast")
	await _seconds(3.5)
	state.call(&"record_moment", MomentLibrary.FOSSIL, &"mt_moon_b2f", {"item": "dome_fossil"})
	menu.open(MenuRoute.trainer())
	await _seconds(1.0)
	await _shot("10_trainer_fossil")
	print("CAPTURE_T24 terminé")
	quit()
