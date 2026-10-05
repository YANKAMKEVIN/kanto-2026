extends Node2D
## Scène QA isolée : combat face à face avec les artworks officiels (prototype, ne touche pas
## au combat du jeu). Ton Pokémon au premier plan en bas à gauche, plus grand, retourné vers
## la droite ; l'adversaire au second plan en haut à droite, plus petit, tourné vers la
## gauche. Décor réel peint (carte, lumière C2, voile et flou du combat sur le décor seul),
## vraie interface de combat par-dessus.
##
## Commandes (S24 : barre du haut ; Mac : flèches, I, D) : couple précédent / suivant,
## intégration de l'artwork (étalonnage) on / off, décor suivant. Argument de ligne de
## commande `--pair=N` (Movie Maker) : couple de départ.

const PAIRS_PATH: String = "res://proto/battle_faceoff/pairs.json"
const ARTWORK_DIR: String = "res://assets/sprites/pokemon/official/"
const HUD_SCENE: PackedScene = preload("res://game/ui/battle/battle_hud.tscn")
const BACKDROP_SHADER: Shader = preload("res://game/battle/battle_backdrop.gdshader")
const GRADE_SHADER: Shader = preload("res://proto/battle_faceoff/artwork_grade.gdshader")
## Décors : carte, point d'appui du cadrage (repère de la carte) et décalage (px monde) pour
## que les deux Pokémon se tiennent sur le sol.
const DECORS: Array[Dictionary] = [
	{"scene": "res://game/world/maps/route_22.tscn", "spawn": "vista", "name": "Route 22",
		"offset": Vector2(0, -150)},
	{"scene": "res://game/world/maps/viridian_city.tscn", "spawn": "from_center",
		"name": "Jadielle", "offset": Vector2(0, 40)},
]
## Comme le vrai combat (BattleStage) : zoom, voile, vignettage, flou du décor.
const ZOOM: float = 1.4
const VEIL: float = 0.35
const VIGNETTE: float = 0.45
const BLUR_LOD: float = 1.0
## Respiration : amplitude (fraction de la taille) et période (s) ; très légère.
const BREATH: float = 0.012
const BREATH_PERIOD: float = 2.6
## Entrée en combat : glissement (px) et durée (s).
const ENTER_SLIDE: float = 90.0
const ENTER_DURATION: float = 0.45
## Ombre au sol : largeur relative à la boîte visible, aplatissement, opacité.
const SHADOW_WIDTH: float = 0.72
const SHADOW_FLATTEN: float = 0.2
const SHADOW_ALPHA: float = 0.42
## Seuil d'alpha de la boîte visible d'un artwork.
const ALPHA_THRESHOLD: float = 0.1

var _species: Dictionary = {}
var _pairs: Array = []
var _pair_index: int = 0
var _decor_index: int = 0
var _graded: bool = true
var _map: Node2D
var _lighting: WorldLighting
var _profiles := LightingLibrary.new()
var _camera := Camera2D.new()
var _actors := CanvasLayer.new()
var _hud: BattleHud
var _label := Label.new()
var _sides: Dictionary = {}  # true (joueur) / false → { sprite, shadow, tween }
var _shadow_texture: GradientTexture2D


func _ready() -> void:
	_load_pairs()
	_profiles.load_file()
	_lighting = WorldLighting.new()
	add_child(_lighting)
	_camera.zoom = Vector2.ONE * ZOOM
	add_child(_camera)
	_build_backdrop()
	_actors.layer = 6
	add_child(_actors)
	_shadow_texture = _make_shadow_texture()
	for is_player: bool in [false, true]:
		var shadow := Sprite2D.new()
		shadow.texture = _shadow_texture
		shadow.modulate = Color(0.06, 0.08, 0.05, SHADOW_ALPHA)
		_actors.add_child(shadow)
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var material := ShaderMaterial.new()
		material.shader = GRADE_SHADER
		sprite.material = material
		_actors.add_child(sprite)
		_sides[is_player] = {"sprite": sprite, "shadow": shadow, "tween": null}
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_build_controls()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--pair="):
			_pair_index = clampi(arg.trim_prefix("--pair=").to_int(), 0, _pairs.size() - 1)
		elif arg == "--raw":
			_graded = false
		elif arg.begins_with("--decor="):
			_decor_index = clampi(arg.trim_prefix("--decor=").to_int(), 0, DECORS.size() - 1)
	_load_decor()
	_show_pair()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"move_right"):
		_step(1)
	elif event.is_action_pressed(&"move_left"):
		_step(-1)
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_I:
				_toggle_grade()
			KEY_D:
				_next_decor()


func _load_pairs() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PAIRS_PATH))
	if not data is Dictionary:
		push_error("FaceoffQa : %s illisible" % PAIRS_PATH)
		return
	_species = data["species"]
	_pairs = data["pairs"]


func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = BACKDROP_SHADER
	material.set_shader_parameter(&"amount", 1.0)
	material.set_shader_parameter(&"veil_color", UiTokens.FADE_COLOR)
	material.set_shader_parameter(&"veil", VEIL)
	material.set_shader_parameter(&"vignette", VIGNETTE)
	material.set_shader_parameter(&"blur_lod", BLUR_LOD)
	rect.material = material
	layer.add_child(rect)


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.position = Vector2(-430, 16)
	bar.custom_minimum_size = Vector2(860, 72)
	bar.add_theme_constant_override(&"separation", 12)
	layer.add_child(bar)
	for spec: Array in [["◀", _step.bind(-1)], ["▶", _step.bind(1)],
			["Intégration", _toggle_grade], ["Décor", _next_decor]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(120, 72)
		button.add_theme_font_size_override(&"font_size", 28)
		button.pressed.connect(spec[1])
		bar.add_child(button)
	_label.add_theme_font_size_override(&"font_size", 22)
	_label.add_theme_color_override(&"font_color", Color.WHITE)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 6)
	bar.add_child(_label)


func _step(delta: int) -> void:
	_pair_index = posmod(_pair_index + delta, _pairs.size())
	_show_pair()


func _toggle_grade() -> void:
	_graded = not _graded
	for is_player: bool in _sides:
		_set_grade(_sides[is_player]["sprite"])
	_update_label()


func _next_decor() -> void:
	_decor_index = (_decor_index + 1) % DECORS.size()
	_load_decor()
	_update_label()


func _load_decor() -> void:
	if _map != null:
		_map.queue_free()
	var decor: Dictionary = DECORS[_decor_index]
	_map = (load(decor["scene"]) as PackedScene).instantiate()
	add_child(_map)
	move_child(_map, 0)
	var marker := _map.get_node_or_null("Spawns/%s" % decor["spawn"]) as Node2D
	_camera.position = (marker.position if marker != null else Vector2.ZERO) \
		+ (decor.get("offset", Vector2.ZERO) as Vector2)
	var profile: LightProfile = null
	if _map.get(&"light_profile") is StringName:
		profile = _profiles.get_profile(_map.get(&"light_profile"))
	_lighting.apply(profile, _map)


func _show_pair() -> void:
	if _pairs.is_empty():
		return
	var pair: Dictionary = _pairs[_pair_index]
	_place(true, _species[pair["player"]])
	_place(false, _species[pair["foe"]])
	_hud.set_card(BattleHud.Side.PLAYER, _card(_species[pair["player"]], true))
	_hud.set_card(BattleHud.Side.FOE, _card(_species[pair["foe"]], false))
	_hud.set_party(2)
	_hud.show_actions({ActionGrid.ATTACK: true, ActionGrid.BAG: true, ActionGrid.TEAM: true,
		ActionGrid.RUN: true})
	_update_label()


func _card(entry: Dictionary, is_player: bool) -> BattleCardView:
	var gender := BattleCardView.Gender.MALE if entry["gender"] == "male" \
		else BattleCardView.Gender.FEMALE
	return BattleCardView.new(entry["name"], gender, 12 if is_player else 9, 30, 30, is_player)


## Place l'artwork de [param entry] sur son ancre : échelle selon la taille réelle
## (FaceoffScale), pieds (bas de la boîte visible) sur l'ancre, retourné côté joueur.
func _place(is_player: bool, entry: Dictionary) -> void:
	var side: Dictionary = _sides[is_player]
	var sprite: Sprite2D = side["sprite"]
	var shadow: Sprite2D = side["shadow"]
	var texture: Texture2D = load(ARTWORK_DIR + "%03d.png" % int(entry["number"]))
	sprite.texture = texture
	sprite.flip_h = is_player
	_set_grade(sprite)
	var box := _visible_box(texture)
	var view := get_viewport().get_visible_rect().size
	var scale := FaceoffScale.sprite_scale(box.size, float(entry["height"]), is_player, view.y)
	# Origine du sprite = pieds : bas-centre de la boîte visible (miroir côté joueur).
	var center_x := box.get_center().x
	if is_player:
		center_x = texture.get_width() - center_x
	sprite.offset = -Vector2(center_x, box.end.y)
	var feet := BattleLayout.feet(BattleLayout.PLAYER_FEET if is_player
		else BattleLayout.FOE_FEET, view)
	shadow.position = feet
	var shadow_width := box.size.x * scale * SHADOW_WIDTH
	shadow.scale = Vector2(shadow_width, shadow_width * SHADOW_FLATTEN) \
		/ Vector2(_shadow_texture.get_size())
	_animate(side, feet, scale, is_player)


func _animate(side: Dictionary, feet: Vector2, scale: float, is_player: bool) -> void:
	var sprite: Sprite2D = side["sprite"]
	if side["tween"] != null:
		(side["tween"] as Tween).kill()
	var start := feet + (Vector2(-ENTER_SLIDE, 0.0) if is_player else Vector2(0.0, -24.0))
	sprite.position = start
	sprite.scale = Vector2.ONE * scale
	sprite.modulate.a = 0.0
	var enter := create_tween().set_parallel()
	enter.tween_property(sprite, ^"position", feet, ENTER_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	enter.tween_property(sprite, ^"modulate:a", 1.0, ENTER_DURATION * 0.6)
	# Respiration : la hauteur gonfle à peine, la largeur suit à l'inverse ; pieds fixes.
	var breath := create_tween().set_loops()
	var high := Vector2(scale * (1.0 - BREATH * 0.4), scale * (1.0 + BREATH))
	var low := Vector2.ONE * scale
	if not is_player:
		breath.tween_interval(BREATH_PERIOD * 0.35)
	breath.tween_property(sprite, ^"scale", high, BREATH_PERIOD / 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breath.tween_property(sprite, ^"scale", low, BREATH_PERIOD / 2.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	side["tween"] = breath


func _set_grade(sprite: Sprite2D) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter(&"strength", 1.0 if _graded else 0.0)


func _update_label() -> void:
	var pair: Dictionary = _pairs[_pair_index]
	_label.text = "%d/%d  %s ↔ %s · %s · %s · intégration %s" % [_pair_index + 1, _pairs.size(),
		_species[pair["player"]]["name"], _species[pair["foe"]]["name"], pair["note"],
		DECORS[_decor_index]["name"], "on" if _graded else "off"]


## Boîte des pixels visibles de [param texture] (coordonnées de l'image).
static func _visible_box(texture: Texture2D) -> Rect2:
	var image := texture.get_image()
	if image == null:
		return Rect2(Vector2.ZERO, texture.get_size())
	if image.is_compressed():
		image.decompress()
	var rect := image.get_used_rect()
	# get_used_rect compte tout alpha > 0 : on resserre au seuil sur les bords bas et côtés.
	var bottom := rect.end.y - 1
	while bottom > rect.position.y and not _row_visible(image, bottom, rect):
		bottom -= 1
	return Rect2(rect.position, Vector2(rect.size.x, bottom - rect.position.y + 1))


static func _row_visible(image: Image, y: int, rect: Rect2i) -> bool:
	for x: int in range(rect.position.x, rect.end.x, 2):
		if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
			return true
	return false


static func _make_shadow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.55, Color(1, 1, 1, 0.75))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture
