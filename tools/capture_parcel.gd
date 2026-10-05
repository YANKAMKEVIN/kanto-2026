extends SceneTree
## Captures de la remise du colis et de l'activation du Pokédex (jalon 7 T19) avec la vraie scène
## Boot, au labo de Chen :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_parcel.gd -- --save=kevin --out=build/captures/jalon07_t19
##
## `--save=kevin` (défaut) : la vraie partie de Kevin (fixture de fin du J6, migrée en mémoire,
## jamais le vrai `user://`), colis ajouté : la réplique « Un Roucool… » est jouée.
## `--save=parcel` : le départ de débogage `parcel` (aucune rencontre : réplique omise).
##
## Déroulé : oak_parcel_<partie>_00_approach (devant Chen) ; une capture par réplique notable
## (01_tiens, 02_species, 03_records, 05_observe, 06_rival_enters, 07_rival_greet, 08_oak_rival,
## 09_not_bad) ; pokedex_activated_<partie> (légende POKÉDEX ACTIVÉ pleinement visible) ;
## oak_parcel_<partie>_10_end (le rival reparti) ; pokedex_activated_<partie>_menu (tableau de
## bord : 6 cartes).

const PARCEL_START := "res://tools/debug_start/parcel.json"
const KEVIN_SAVE := "res://tests/fixtures/save/v2_kevin_j6_fin.json"
const MEMORY_FS := "res://tests/helpers/memory_file_system.gd"
const SAVE_PATH := "user://capture_parcel_save.json"
const SHOTS := {
	"Tiens…": "01_tiens",
	"Un Roucool… Tu n'as pas perdu de temps.": "02_species",
	"Ton voyage peut nous apprendre beaucoup.": "03_records",
	"Observe. Explore. Fais-toi ta propre idée du monde.": "05_observe",
	"Professeur ! Je suis revenu.": "06_rival_enters",
	"Tiens. T'es déjà revenu, toi aussi ?": "07_rival_greet",
	"Et toi… apprends à regarder au-delà de la victoire.": "08_oak_rival",
	"Pas mal.": "09_not_bad",
}
const PATH_TO_OAK: Array[Vector2i] = [
	Vector2i.UP, Vector2i.UP, Vector2i.UP, Vector2i.UP, Vector2i.RIGHT,
]
## Images d'attente avant une capture de réplique (texte écrit en entier).
const PAGE_HOLD := 45

var _out_dir: String = "build/captures/jalon07_t19"
var _save: String = "kevin"
var _boot: Node
var _player: Node2D
var _box: Node
var _runner: Node
var _director: Node
var _router: Node
var _caption: Node
var _step: int = 0
var _wait: int = 0
var _path_index: int = 0
var _page: String = ""
var _page_wait: int = 0
var _caption_shot: bool = false


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--save="):
			_save = arg.trim_prefix("--save=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"pallet_town")
	_boot.set(&"start_spawn", &"oak_lab_door")
	if _save == "kevin":
		var fs: Object = load(MEMORY_FS).new()
		fs.get(&"files")[SAVE_PATH] = FileAccess.get_file_as_string(KEVIN_SAVE)
		_boot.set(&"save_system", load("res://game/systems/save/save_system.gd").new(fs, SAVE_PATH))
	root.add_child(_boot)
	var state := root.get_node(^"/root/GameState")
	var data: Object = _boot.call(&"get_pokemon_data")
	if _save == "kevin":
		state.get(&"flags").call(&"set_flag", &"viridian_arrived")
		state.get(&"flags").call(&"set_flag", &"got_oak_parcel")
		state.get(&"bag").call(&"add", &"oak_parcel", 1)
	else:
		var start: Object = load("res://game/systems/debug/debug_start.gd").new()
		if not start.call(&"load_file", PARCEL_START, data, _boot.call(&"get_item_library")):
			push_error("capture_parcel : départ illisible")
		start.call(&"apply", state, data)
	_player = _boot.call(&"get_player")
	_box = _boot.call(&"get_dialogue_box")
	_runner = _boot.call(&"get_dialogue_runner")
	_director = _boot.call(&"get_cutscene_director")
	_caption = (_boot.call(&"get_hud") as Node).call(&"get_caption")
	_caption.connect(&"caption_shown", _on_caption_shown)
	_router = root.get_node(^"/root/SceneRouter")
	_router.call(&"change_map", &"oak_lab", &"entrance", Vector2i.UP)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_wait += 1
	match _step:
		0:
			if _wait > 40 and not _router.call(&"is_transitioning"):
				_next()
		1:
			if _player.call(&"is_moving"):
				return
			if _path_index < PATH_TO_OAK.size():
				_player.call(&"script_step", PATH_TO_OAK[_path_index])
				_path_index += 1
				return
			_player.call(&"face", Vector2i.UP)
			_next()
		2:
			if _wait == 30:
				_shot("oak_parcel", "00_approach")
				Input.action_press(&"interact")
			elif _wait == 32:
				Input.action_release(&"interact")
			elif _wait > 34 and _director.call(&"is_running"):
				_next()
			elif _wait > 200:
				push_error("capture_parcel : la scène n'a pas démarré")
				quit(1)
		3:
			_drive_scene()
		4:
			if _wait == 45:
				_shot("oak_parcel", "10_end")
				(_boot.call(&"get_menu_director") as Node).call(&"open")
			elif _wait == 120:
				_shot("pokedex_activated", "menu")
				quit()


## Pendant la scène : répliques capturées puis avancées.
func _drive_scene() -> void:
	if _box.call(&"is_open"):
		var text: String = _box.call(&"get_text")
		if text != _page:
			_page = text
			_page_wait = 0
		_page_wait += 1
		if _page_wait == PAGE_HOLD and SHOTS.has(text):
			_shot("oak_parcel", SHOTS[text])
		if _page_wait % PAGE_HOLD == 0:
			_box.emit_signal(&"advance_requested")
		return
	if not _director.call(&"is_running") and not _runner.call(&"is_running"):
		_next()


## La légende vient d'être pleinement visible : capture un peu après (tenue de 3 s).
func _on_caption_shown() -> void:
	if _caption_shot:
		return
	_caption_shot = true
	await create_timer(0.3).timeout
	_shot("pokedex_activated", "")


func _next() -> void:
	_step += 1
	_wait = 0


func _shot(prefix: String, capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var file := "%s_%s" % [prefix, _save]
	if not capture_name.is_empty():
		file += "_" + capture_name
	var path := _out_dir.path_join(file + ".png")
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
