extends GutTest
## Monture provisoire (moteur commun, défaut D1 de la QA du J24 : « en Surf, le joueur est
## dessiné à pied sur l'eau ») : tant que l'apparence n'a pas d'animations `surf_*`, un dos de
## nageur dessiné couvre les jambes, le héros est assis (relevé, immobile, sans ombre) ; tout
## revient à pied. Le Vélo provisoire n'apparaît qu'avec l'image du J22.
## Depuis le 2026-11-04, le héros a son Surf peint : la monture provisoire est testée sur une copie
## de ses animations sans `surf_*` ; le vrai héros joue `surf_walk_*` / `surf_idle_*`, sans
## provisoire ni ombre.

const PLAYER_SCENE := "res://game/player/player.tscn"
const FRAME := 1.0 / 60.0
const START := Vector2i(2, 2)
const SIZE := Vector2i(8, 10)

var _grid: GridWorld
var _player: Player


func before_each() -> void:
	_grid = GridWorld.new(SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			_grid.set_surfable(Vector2i(x, y))
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	add_child_autofree(_player)
	_strip_painted_surf()
	_player.set_mount(Mount.Kind.SURF)
	_player.enter_map(_grid, START, Vector2i.DOWN, Grid.map_pixel_rect(SIZE))
	_player.set_process(false)


func after_each() -> void:
	Input.action_release(&"move_right")


func _sprite() -> AnimatedSprite2D:
	return _player.get_node(^"%Sprite") as AnimatedSprite2D


## Une apparence sans Surf peint : les animations du héros, moins `surf_*`.
func _strip_painted_surf() -> void:
	var frames := _sprite().sprite_frames.duplicate() as SpriteFrames
	for anim: StringName in frames.get_animation_names():
		if String(anim).begins_with("surf_"):
			frames.remove_animation(anim)
	_sprite().sprite_frames = frames


## Le vrai héros, avec son Surf peint, sur l'eau.
func _painted_surfer() -> void:
	_player.set_mount(Mount.Kind.NONE)
	_player.refresh_look()
	_player.set_mount(Mount.Kind.SURF)


func test_surf_draws_the_swimmer_in_front_of_the_legs() -> void:
	var placeholder := _player.get_mount_placeholder()
	assert_true(_player.is_mount_drawn(), "le Surf se voit")
	assert_true(placeholder.is_drawn())
	assert_gt(placeholder.get_index(), _sprite().get_index(), "devant les jambes")
	assert_eq(_sprite().position.y, -MountPlaceholder.SURF_SEAT_LIFT, "héros assis, relevé")
	assert_false((_player.get_node(^"%Shadow") as CanvasItem).visible, "pas d'ombre sur l'eau")


func test_swimming_keeps_the_hero_seated_whatever_the_direction() -> void:
	Input.action_press(&"move_right")
	for i: int in 10:
		_player._process(FRAME)
	assert_true(_player.is_moving())
	assert_eq(_sprite().animation, &"idle_right", "assis : pas de jambes qui marchent")
	assert_true(_player.is_mount_drawn())
	for direction: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]:
		Input.action_release(&"move_right")
		_player._process(1.0)
		_player.face(direction)
		assert_true(_player.is_mount_drawn(), "nageur visible vers %s" % direction)


func test_back_on_foot_restores_the_walker() -> void:
	_player.set_mount(Mount.Kind.NONE)
	assert_false(_player.is_mount_drawn())
	assert_false(_player.get_mount_placeholder().is_drawn())
	assert_eq(_sprite().position.y, 0.0)
	assert_true((_player.get_node(^"%Shadow") as CanvasItem).visible)


func test_bike_placeholder_needs_the_bike_image() -> void:
	_player.set_mount(Mount.Kind.BIKE)
	var has_image := ResourceLoader.exists(MountPlaceholder.BIKE_TEXTURE_PATH)
	assert_eq(_player.is_mount_drawn(), has_image,
		"vélo provisoire seulement avec l'image du J22")
	assert_eq(_sprite().position.y, 0.0, "à Vélo, le héros n'est pas relevé")


func test_an_appearance_with_surf_animations_needs_no_placeholder() -> void:
	var placeholder := _player.get_mount_placeholder()
	placeholder.refresh(Mount.Kind.SURF, &"surf_idle_down", Vector2i.DOWN)
	assert_false(placeholder.is_drawn(), "l'art des montures remplace le provisoire")
	placeholder.refresh(Mount.Kind.SURF, &"idle_left", Vector2i.LEFT)
	assert_true(placeholder.is_drawn())


func test_painted_surf_replaces_the_placeholder() -> void:
	_painted_surfer()
	assert_true(_sprite().sprite_frames.has_animation(&"surf_idle_down"), "Surf peint du héros")
	assert_eq(_sprite().animation, &"surf_idle_down", "assis sur le nageur peint, à l'arrêt")
	assert_true(_player.is_mount_drawn(), "le Surf se voit")
	assert_false(_player.get_mount_placeholder().is_drawn(), "plus de nageur dessiné en code")
	assert_eq(_sprite().position.y, 0.0, "la peinture est déjà assise : pas de relevé")
	assert_false((_player.get_node(^"%Shadow") as CanvasItem).visible, "pas d'ombre sur l'eau")


func test_painted_surf_swims_with_its_own_cycle() -> void:
	_painted_surfer()
	Input.action_press(&"move_right")
	for i: int in 10:
		_player._process(FRAME)
	assert_true(_player.is_moving())
	assert_eq(_sprite().animation, &"surf_walk_right", "le nageur peint avance")
	assert_false(_player.get_mount_placeholder().is_drawn())
