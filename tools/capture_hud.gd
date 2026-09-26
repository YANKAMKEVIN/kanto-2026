extends SceneTree
## Outil de vérification visuelle du HUD d'exploration (Movie Maker) : lance game/boot.tscn.
##
##   godot --path . --always-on-top --write-movie build/cap/f.png --fixed-fps 30 \
##     --quit-after 150 -s res://tools/capture_hud.gd [-- --out=build/captures]
##
## Taille de fenêtre : utiliser un override.cfg temporaire (2340×1080), voir capture_play.gd.
## Le script affiche « CAPTURE <nom> frame=<n> » : image Movie Maker à conserver.
## Avec « -- --out=build/captures », il enregistre aussi la texture du viewport sous
## <out>/<nom>.png (utile sans Movie Maker : --fixed-fps 30 seul garde un temps déterministe ;
## --always-on-top est nécessaire : sur Mac, une fenêtre masquée par une autre n'est plus
## dessinée et Movie Maker répète alors la dernière image (titre « figé »).
##
## Déroulé (30 images/s) :
##   hud_zone_title   titre de zone pendant son maintien (~1 s)
##   hud_after_title  après sa disparition (~3,7 s)
##   hud_joystick     doigt 0 posé dans la moitié gauche puis glissé vers la droite
##   hud_run_pressed  en plus, doigt 1 tenu sur le bouton courir
## Les touchers passent par Input.parse_input_event, comme sur le téléphone (la souris
## émulée depuis le toucher est donc aussi générée, et doit être ignorée).

const BOOT_SCENE: String = "res://game/boot.tscn"
const THUMB_START := Vector2(430, 790)
const THUMB_SWIPE := Vector2(95, 6)
## tools/ n'est pas importé : les tokens sont chargés explicitement.
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"

var _boot: Node
var _frame: int = 0
var _out_dir: String = ""
## Centre du bouton courir depuis le coin bas-droit.
var _run_from_corner: Vector2


func _init() -> void:
	# La fenêtre de capture prend le focus : on coupe le clavier pour que seules les
	# entrées tactiles injectées pilotent le joueur.
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	_run_from_corner = (load(TOKENS_PATH) as GDScript).RUN_BUTTON_CENTER_FROM_CORNER
	# Les autoloads (SceneRouter, utilisé par Boot) ne sont ajoutés qu'après _init.
	process_frame.connect(_start_boot, CONNECT_ONE_SHOT)


func _start_boot() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	# Depuis le jalon 2, le jeu démarre dans la chambre (sans titre) : on part du village.
	_boot.set(&"start_map", &"pallet_town")
	root.add_child(_boot)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	match _frame:
		30:
			_mark("hud_zone_title")
		112:
			_mark("hud_after_title")
		115:
			_touch(0, THUMB_START, true)
		116, 117, 118, 119, 120:
			var t := (_frame - 115) / 5.0
			_drag(0, THUMB_START + THUMB_SWIPE * t)
		128:
			_mark("hud_joystick")
		130:
			_touch(1, root.get_visible_rect().size - _run_from_corner, true)
		136:
			_mark("hud_run_pressed")
		140:
			_touch(1, root.get_visible_rect().size - _run_from_corner, false)
			_touch(0, THUMB_START + THUMB_SWIPE, false)


func _mark(capture_name: String) -> void:
	var player: Node2D = _boot.call(&"get_player")
	print("CAPTURE %s frame=%d cell=%s right=%s run=%s viewport=%s" % [
		capture_name, _frame, player.call(&"get_cell"),
		Input.is_action_pressed(&"move_right"), Input.is_action_pressed(&"run"),
		root.get_visible_rect().size,
	])
	if not _out_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(_out_dir)
		root.get_texture().get_image().save_png(_out_dir.path_join(capture_name + ".png"))


func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	Input.parse_input_event(event)


func _drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	Input.parse_input_event(event)
