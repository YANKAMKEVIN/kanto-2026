extends SceneTree
## Capture d'essai du kit des canaux (jalon 13 T6, `tools/cerulean_map_kit.gd`) : la carte
## `tests/fixtures/maps/canal_essai.txt` (canal en L, quais, deux ponts) construite en mémoire
## avec les **provisoires** de la série 15 (rien n'est écrit dans `assets/` ni `game/`), rendue
## à 1:1 dans un écran de S24 (2340 × 1080), héros posé sur le pont nord-sud pour l'échelle.
##
##   godot --path . --fixed-fps 60 -s res://tools/capture_cerulean_kit.gd -- \
##     --out=build/captures/j13_t6
##
## Pas en `--headless` (il faut un rendu). Affiche le nombre de modules et les erreurs du kit.

const Kit := preload("res://tools/cerulean_map_kit.gd")
const PLAN: String = "res://tests/fixtures/maps/canal_essai.txt"
const SIZE := Vector2i(24, 11)
const VIEW := Vector2i(2340, 1080)
const HERO: String = "res://assets/sprites/characters/painted/player_frames.tres"

var _out: String = "build/captures/j13_t6"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	_run.call_deferred()


func _run() -> void:
	var kit: RefCounted = Kit.new(PLAN, SIZE, 13, 14, 15)
	kit.set(&"allow_placeholders", true)
	var map: Node2D = kit.call(&"make_root", "CanalEssai", &"canal_essai", "Essai", "", &"", "")
	kit.call(&"add_ground_in_memory", {})
	var quays: int = kit.call(&"place_quays")
	var decks: int = kit.call(&"place_bridges", {})
	print("quais : %d modules ; tabliers : %d ; erreurs : %s" % [quays, decks, kit.get(&"errors")])
	var viewport := SubViewport.new()
	viewport.size = VIEW
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	# Seulement l'affichage (sol, décalcomanies, quais, ponts) : la carte n'est pas jouée.
	for layer_name: String in ["PaintedGround", "GroundDecals"]:
		var layer := map.get_node(layer_name)
		map.remove_child(layer)
		_clear_owner(layer)
		viewport.add_child(layer)
	var hero := _hero()
	if hero != null:
		hero.position = Vector2(16.5, 6.0) * 96.0
		viewport.add_child(hero)
	var pixels := Vector2(SIZE) * 96.0
	viewport.canvas_transform = Transform2D(0.0, ((Vector2(VIEW) - pixels) / 2.0).round())
	for i: int in 6:
		await process_frame
	var image := viewport.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out))
	var path := "res://%s/canal_essai.png" % _out
	image.save_png(path)
	print("capture : %s" % ProjectSettings.globalize_path(path))
	map.free()
	quit(0 if (kit.get(&"errors") as PackedStringArray).is_empty() else 1)


## Héros peint (première image de la planche, vers le bas), origine aux pieds.
func _hero() -> Node2D:
	if not ResourceLoader.exists(HERO):
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load(HERO)
	sprite.centered = false
	var frame := sprite.sprite_frames.get_frame_texture(
		sprite.sprite_frames.get_animation_names()[0], 0)
	sprite.offset = Vector2(-frame.get_width() / 2.0, -frame.get_height())
	return sprite


func _clear_owner(node: Node) -> void:
	node.owner = null
	for child: Node in node.get_children():
		_clear_owner(child)
