extends SceneTree
## Captures du Sac avec les icônes du lot DAF.5 (`tools/art/daf5.py`), vraie scène Boot :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_bag_daf5.gd -- --out=build/captures/daf5
##
## Une image par onglet (soins, balls, objets rares, CT/CS), préfixée par la largeur, avec les
## 23 objets du lot dans le Sac (et quelques anciens pour comparer).

const SEED := 7
const ITEMS: Array[StringName] = [&"potion", &"hyper_potion", &"max_potion", &"full_heal",
	&"max_revive", &"revive", &"poke_ball", &"great_ball", &"ultra_ball", &"bicycle",
	&"bike_voucher", &"card_key", &"old_rod", &"good_rod", &"super_rod", &"old_amber",
	&"poke_flute", &"secret_key", &"lift_key", &"hm01", &"hm02", &"hm03", &"hm04", &"tm01",
	&"tm09", &"tm14", &"tm22", &"tm35", &"tm38", &"tm39"]
## (onglet, objet sélectionné, nom de l'image).
const SHOTS: Array = [[&"heal", &"hyper_potion", "bag_heal"], [&"ball", &"ultra_ball", "bag_ball"],
	[&"key", &"bicycle", "bag_key"], [&"tm", &"hm02", "bag_tm"]]

var _out_dir: String = "build/captures/daf5"
var _boot: Node
var _state: Node
var _prefix: String = ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(capture_name: String) -> void:
	await _frames(3)
	var path := "%s/%s%s.png" % [_out_dir, _prefix, capture_name]
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s" % path)


func _start() -> void:
	_prefix = "%d_" % int(root.get_visible_rect().size.x)
	_state = root.get_node("GameState")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(60)
	_state.call(&"new_game", 5)
	_state.get(&"flags").call(&"set_flag", &"starter_chosen")
	_state.set(&"starter_species", &"charmander")
	_state.set(&"player_name", "Kevin")
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = _state.get(&"party")
	party.add(PokemonFactory.create(data, &"charmander", 24, GameRng.new(SEED)))
	var bag: Bag = _state.get(&"bag")
	for item_id: StringName in ITEMS:
		bag.add(item_id, 1)
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	menu.open(MenuRoute.bag())
	await _frames(40)
	for shot: Array in SHOTS:
		screen.get_bag().open_category(shot[0])
		await _frames(10)
		screen.get_bag().select_item(shot[1])
		await _frames(20)
		await _shot(shot[2])
	print("CAPTURE_BAG_DAF5 terminé")
	quit()
