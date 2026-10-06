extends GutTest
## Pose d'attente (QA téléphone, scène oak_parcel) : après chaque pas, marche ou course,
## après un pivot (face) ou une réaction (react), le personnage reprend son animation
## idle_<dir> (image de repos), jamais une pose de marche figée.

const NPC_SCENE := "res://game/world/npc/npc.tscn"
const PLAYER_SCENE := "res://game/player/player.tscn"
const FRAME := 1.0 / 60.0
const CELL := Vector2i(5, 5)
## Planches d'attente (décision de Kevin du 2026-10-06) : à l'arrêt, `idle_<dir>` venait de la
## colonne « passage » de la marche (jambes écartées de profil) ; chaque apparence peinte a
## maintenant une planche d'attente pieds joints `<planche>_idle` (4 × 1 : bas, gauche, droite,
## haut).
const CATALOGUE := "res://assets/world/catalogue.json"
## Planche du catalogue → SpriteFrames du jeu (tools/build_character_frames.gd, LOOKS).
const PAINTED_IDLE := {
	"heros": "res://assets/sprites/characters/painted/player_frames.tres",
	"rival": "res://assets/sprites/characters/painted/rival_frames.tres",
	"infirmiere": "res://assets/sprites/characters/painted/nurse_frames.tres",
	"marchand": "res://assets/sprites/characters/painted/clerk_frames.tres",
	"livreur": "res://assets/sprites/characters/painted/courier_frames.tres",
	"dresseuse": "res://assets/sprites/characters/painted/lass_frames.tres",
	"enfant": "res://assets/sprites/characters/painted/kid_frames.tres",
	"vieil_homme": "res://assets/sprites/characters/painted/old_man_frames.tres",
	"voyageur": "res://assets/sprites/characters/painted/traveler_frames.tres",
	"jeune_dresseur": "res://assets/sprites/characters/painted/youngster_frames.tres",
	"roucool": "res://assets/sprites/pokemon/painted/pidgey_frames.tres",
	"rattata": "res://assets/sprites/pokemon/painted/rattata_frames.tres",
}
## Pokémon : la largeur de la bande basse mesure la longueur du corps (quadrupède, oiseau), pas
## un écart de jambes ; seuls la provenance et les pieds à niveau sont testés.
const POKEMON_LOOKS: Array[String] = ["roucool", "rattata"]
const IDLE_COLUMNS := {"down": 0, "left": 1, "right": 2, "up": 3}
const ALPHA_MIN := 96.0 / 255.0
## Bande des pieds (part de la hauteur de la silhouette) : écart (comme le diagnostic), niveau.
const FEET_BAND := 0.12
const LEVEL_BAND := 0.2

var _grid: GridWorld


func before_each() -> void:
	_grid = GridWorld.new(Vector2i(16, 12))


func _npc(sprite: StringName) -> Npc:
	_grid = GridWorld.new(Vector2i(16, 12))
	var spec := NpcSpec.new()
	spec.id = &"rest_npc"
	spec.cell = CELL
	spec.facing = Vector2i.DOWN
	spec.sprite = sprite
	var npc := (load(NPC_SCENE) as PackedScene).instantiate() as Npc
	npc.setup(spec)
	add_child_autofree(npc)
	npc.enter_grid(_grid)
	npc.set_process(false)
	return npc


func _player() -> Player:
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	add_child_autofree(player)
	player.enter_map(_grid, CELL, Vector2i.DOWN, Grid.map_pixel_rect(Vector2i(16, 12)))
	player.set_process(false)
	return player


func _run_npc(npc: Npc) -> void:
	for i: int in 120:
		if not npc.is_moving():
			return
		npc._process(FRAME)


func _run_player(player: Player) -> void:
	for i: int in 120:
		player._process(FRAME)


func _assert_rest(sprite: AnimatedSprite2D, facing: Vector2i, label: String) -> void:
	var anim := StringName("idle_" + Grid.direction_name(facing))
	assert_eq(sprite.animation, anim, label + " : animation")
	assert_eq(sprite.frame, 0, label + " : image de repos")
	assert_true(sprite.is_playing() or sprite.sprite_frames.get_frame_count(anim) == 1, label)


func test_npc_rests_after_walk_and_run() -> void:
	for look: StringName in [&"rival", &"kid", &"villager"]:
		for run: bool in [false, true]:
			var npc := _npc(look)
			var sprite := npc.get_node(^"%Sprite") as AnimatedSprite2D
			for dir: Vector2i in [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]:
				assert_true(npc.step(dir, run))
				_run_npc(npc)
				_assert_rest(sprite, dir, "%s run=%s %s" % [look, run, dir])


func test_npc_rests_after_face_and_react() -> void:
	var npc := _npc(&"rival")
	var sprite := npc.get_node(^"%Sprite") as AnimatedSprite2D
	npc.step(Vector2i.RIGHT)
	_run_npc(npc)
	npc.face(Vector2i.UP)
	_assert_rest(sprite, Vector2i.UP, "face")
	npc.react()
	sprite.animation_finished.emit()
	_assert_rest(sprite, Vector2i.UP, "react")


func test_npc_background_step_chain_then_face_rests() -> void:
	var npc := _npc(&"rival")
	var sprite := npc.get_node(^"%Sprite") as AnimatedSprite2D
	for dir: Vector2i in [Vector2i.UP, Vector2i.UP, Vector2i.LEFT]:
		npc.step(dir)
		_run_npc(npc)
	npc.face(Vector2i.DOWN)
	_assert_rest(sprite, Vector2i.DOWN, "chaîne puis face")


func test_player_rests_after_scripted_step_face_and_react() -> void:
	var player := _player()
	var sprite := player.get_node(^"%Sprite") as AnimatedSprite2D
	for run: bool in [false, true]:
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]:
			assert_true(player.script_step(dir, run))
			_run_player(player)
			_assert_rest(sprite, dir, "joueur run=%s %s" % [run, dir])
	player.face(Vector2i.LEFT)
	_assert_rest(sprite, Vector2i.LEFT, "joueur face")
	player.react()
	sprite.animation_finished.emit()
	_run_player(player)
	_assert_rest(sprite, Vector2i.LEFT, "joueur react")


func test_player_keep_facing_step_rests_in_facing() -> void:
	var player := _player()
	var sprite := player.get_node(^"%Sprite") as AnimatedSprite2D
	player.face(Vector2i.UP)
	assert_true(player.script_step(Vector2i.DOWN, false, true))
	_run_player(player)
	_assert_rest(sprite, Vector2i.UP, "recul")


func test_painted_idle_comes_from_idle_sheet() -> void:
	var sheets := _catalogue()
	for sheet_id: String in PAINTED_IDLE:
		var idle_sheet: Dictionary = sheets.get(sheet_id + "_idle", {})
		assert_false(idle_sheet.is_empty(), sheet_id + " : planche d'attente au catalogue")
		if idle_sheet.is_empty():
			continue
		var walk_cell: Array = (sheets[sheet_id] as Dictionary)["cellule"]
		var cell: Array = idle_sheet["cellule"]
		assert_eq(int(cell[1]), int(walk_cell[1]), sheet_id + " : même hauteur (ancrage pieds)")
		var frames := load(PAINTED_IDLE[sheet_id]) as SpriteFrames
		for dir: String in IDLE_COLUMNS:
			var anim := StringName("idle_" + dir)
			assert_eq(frames.get_frame_count(anim), 1, "%s %s" % [sheet_id, anim])
			var atlas := frames.get_frame_texture(anim, 0) as AtlasTexture
			assert_eq(atlas.atlas.resource_path, String(idle_sheet["fichier"]),
				"%s %s : planche d'attente" % [sheet_id, anim])
			var column: int = IDLE_COLUMNS[dir]
			assert_eq(atlas.region, Rect2(int(cell[0]) * column, 0, int(cell[0]), int(cell[1])),
				"%s %s : colonne" % [sheet_id, anim])


func test_painted_idle_feet_together() -> void:
	for sheet_id: String in PAINTED_IDLE:
		var frames := load(PAINTED_IDLE[sheet_id]) as SpriteFrames
		for dir: String in IDLE_COLUMNS:
			var idle := frames.get_frame_texture(StringName("idle_" + dir), 0).get_image()
			var label := "%s %s" % [sheet_id, dir]
			# Pieds à niveau (aucun pied devant l'autre) dans toutes les vues.
			assert_lte(_feet_stagger(idle), 1, label + " : pieds à niveau")
			if POKEMON_LOOKS.has(sheet_id) or dir == "down" or dir == "up":
				continue
			# De profil : pieds plus serrés que dans TOUTE image de marche de la même direction.
			# (De face et de dos, les pieds côte à côte sont plus larges que des pieds qui se
			# masquent en marchant : la largeur n'y mesure pas l'écart, le niveau si.)
			var spread := _feet_spread(idle)
			var walk := StringName("walk_" + dir)
			for i: int in frames.get_frame_count(walk):
				var walk_spread := _feet_spread(frames.get_frame_texture(walk, i).get_image())
				assert_lt(spread, walk_spread, "%s : attente %d < marche[%d] %d" % [
					label, spread, i, walk_spread])


func _catalogue() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	return (parsed as Dictionary)["personnages"]


## Boîte de la silhouette (alpha > 96) à partir de la ligne `from_y` ; Rect2i vide sinon.
func _bbox(image: Image, from_y: int = 0) -> Rect2i:
	var left := image.get_width()
	var right := -1
	var top := image.get_height()
	var bottom := -1
	for y: int in range(from_y, image.get_height()):
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > ALPHA_MIN:
				left = mini(left, x)
				right = maxi(right, x)
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if right < 0:
		return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


## Écart des pieds : largeur de la silhouette dans sa bande basse (12 % de sa hauteur).
func _feet_spread(image: Image) -> int:
	var box := _bbox(image)
	var band := maxi(2, roundi(box.size.y * FEET_BAND))
	return _bbox(image, box.end.y - band).size.x


## Décalage vertical entre le bas de la moitié gauche et de la moitié droite des pieds.
func _feet_stagger(image: Image) -> int:
	var box := _bbox(image)
	var band_top := box.end.y - maxi(2, roundi(box.size.y * LEVEL_BAND))
	var feet := _bbox(image, band_top)
	var middle := feet.position.x + feet.size.x / 2
	var left := _bbox(image.get_region(Rect2i(0, 0, middle, image.get_height())), band_top)
	var right := _bbox(image.get_region(Rect2i(middle, 0, image.get_width() - middle,
		image.get_height())), band_top)
	return absi(left.end.y - right.end.y)
