extends Node2D
## Scène QA isolée : UN duel, Salamèche (de dos, à toi) contre Roucool (de face), avec un
## cadrage de combat dédié (prototype, ne touche pas au combat du jeu).
##
## Cadrage « combat » : la caméra se resserre sur le lieu réel (toujours reconnaissable),
## ton Pokémon domine le premier plan en bas à gauche, l'adversaire est nettement plus loin
## en haut à droite ; l'interface libère cette diagonale (carte adverse en haut à gauche, la
## tienne en bas à droite au-dessus des boutons). Cadrage « ancien » : celui du combat actuel,
## pour comparer.
## Traitements ([constant TREATMENTS]) : ton Pokémon en sprite animé Noir/Blanc aux pixels
## nets (échelle entière) à plusieurs tailles, contre l'artwork officiel HD de l'adversaire ;
## puis, pour mémoire, les essais précédents (tout en sprite net, lissé Scale2x ×3, peint).
##
## Commandes (S24 : barre du haut ; Mac : T, C, D) : traitement, cadrage, décor.
## Arguments `--treatment=N`, `--framing=combat|old`, `--decor=N` (Movie Maker).

const SHEETS_PATH: String = "res://proto/battle_faceoff/sprite_sheets.json"
const SPRITE_DIR: String = "res://assets/sprites/pokemon/battle_proto/"
const HUD_SCENE: PackedScene = preload("res://game/ui/battle/battle_hud.tscn")
const BACKDROP_SHADER: Shader = preload("res://game/battle/battle_backdrop.gdshader")
const DECORS: Array[Dictionary] = [
	{"scene": "res://game/world/maps/route_22.tscn", "spawn": "vista", "name": "Route 22",
		"offset": Vector2(0, -150)},
	{"scene": "res://game/world/maps/viridian_city.tscn", "spawn": "from_center",
		"name": "Jadielle", "offset": Vector2(0, 40)},
]
## Les deux combattants : planche sprite, image peinte, nom affiché.
const PLAYER := {"sheet": "salameche_dos_bw", "painted": "salameche_dos_peint",
	"rebuilt": "salameche_dos_reconstruit", "model": "salameche_dos_3d",
	"name": "Salamèche", "level": 12}
const FOE := {"sheet": "roucool_face_bw", "painted": "roucool_face_peint", "official": 16,
	"name": "Roucool", "level": 9}
const OFFICIAL_DIR: String = "res://assets/sprites/pokemon/official/"
## Traitements : rendu de chaque camp (net = sprite aux pixels nets, smooth = lissé, rebuilt =
## reconstruit sans IA par tools/art/reconstruire_sprite.py, model = rendu de dos du modèle 3D
## par tools/art/blender/rendre_pokemon.py, painted = repeint, official = artwork officiel HD) et taille du tien (fraction de la hauteur du
## cadrage). Le premier affiché est [constant DEFAULT_TREATMENT].
const TREATMENTS: Array[Dictionary] = [
	{"label": "sprite net 100 % · Roucool HD", "player": "net", "ratio": 1.0, "foe": "official"},
	{"label": "sprite net 70 % · Roucool HD", "player": "net", "ratio": 0.7, "foe": "official"},
	{"label": "sprite net 60 % · Roucool HD", "player": "net", "ratio": 0.6, "foe": "official"},
	{"label": "reconstruit 60 % · Roucool HD", "player": "rebuilt", "ratio": 0.6,
		"foe": "official"},
	{"label": "dos 3D 60 % · Roucool HD", "player": "model", "ratio": 0.6, "foe": "official"},
	{"label": "sprite net 50 % · Roucool HD", "player": "net", "ratio": 0.5, "foe": "official"},
	{"label": "ancien : tout sprite net", "player": "net", "ratio": 1.0, "foe": "net"},
	{"label": "ancien : sprite lissé", "player": "smooth", "ratio": 1.0, "foe": "smooth"},
	{"label": "ancien : peint", "player": "painted", "ratio": 1.0, "foe": "painted"},
]
const DEFAULT_TREATMENT: int = 4
## Cadrages : zoom de la caméra, voile, vignettage, flou du décor ; pieds (x : décalage depuis
## le centre, y : depuis le haut, en hauteurs d'écran) et hauteur visible (hauteurs d'écran)
## de chaque Pokémon.
const FRAMINGS: Dictionary = {
	"combat": {"zoom": 1.9, "veil": 0.28, "vignette": 0.6, "blur": 1.6,
		"player_feet": Vector2(-0.42, 0.97), "player_height": 0.56,
		"foe_feet": Vector2(0.36, 0.50), "foe_height": 0.21, "hud": "diagonal"},
	"old": {"zoom": 1.4, "veil": 0.35, "vignette": 0.45, "blur": 1.0,
		"player_feet": Vector2(-0.30, 0.63), "player_height": 0.30,
		"foe_feet": Vector2(0.24, 0.47), "foe_height": 0.17, "hud": "default"},
}
const BREATH: float = 0.012
const BREATH_PERIOD: float = 2.6
const ENTER_DURATION: float = 0.5
const SHADOW_ALPHA: float = 0.45
## Écart (px) entre la carte du joueur et la grille d'actions, en mode « diagonal ».
const HUD_GAP: float = 18.0

var _sheets: Dictionary = {}
var _treatment: int = DEFAULT_TREATMENT
var _framing: String = "combat"
var _decor_index: int = 0
var _map: Node2D
var _lighting: WorldLighting
var _profiles := LightingLibrary.new()
var _camera := Camera2D.new()
var _backdrop: ShaderMaterial
var _actors := CanvasLayer.new()
var _hud: BattleHud
var _label := Label.new()
var _sides: Dictionary = {}  # true (joueur) / false → { node, shadow, tween }
var _shadow_texture: GradientTexture2D


func _ready() -> void:
	_sheets = JSON.parse_string(FileAccess.get_file_as_string(SHEETS_PATH))
	_profiles.load_file()
	_lighting = WorldLighting.new()
	add_child(_lighting)
	add_child(_camera)
	_build_backdrop()
	_actors.layer = 6
	add_child(_actors)
	_shadow_texture = _make_shadow_texture()
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_build_controls()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--treatment="):
			_treatment = clampi(arg.trim_prefix("--treatment=").to_int(), 0, TREATMENTS.size() - 1)
		elif arg.begins_with("--framing="):
			_framing = arg.trim_prefix("--framing=")
		elif arg.begins_with("--decor="):
			_decor_index = clampi(arg.trim_prefix("--decor=").to_int(), 0, DECORS.size() - 1)
	_load_decor()
	_show()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_T:
				_toggle_treatment()
			KEY_C:
				_toggle_framing()
			KEY_D:
				_next_decor()


func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop = ShaderMaterial.new()
	_backdrop.shader = BACKDROP_SHADER
	_backdrop.set_shader_parameter(&"amount", 1.0)
	_backdrop.set_shader_parameter(&"veil_color", UiTokens.FADE_COLOR)
	rect.material = _backdrop
	layer.add_child(rect)


func _build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.position = Vector2(-380, 16)
	bar.add_theme_constant_override(&"separation", 12)
	layer.add_child(bar)
	for spec: Array in [["Traitement", _toggle_treatment], ["Cadrage", _toggle_framing],
			["Décor", _next_decor]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(150, 72)
		button.add_theme_font_size_override(&"font_size", 28)
		button.pressed.connect(spec[1])
		bar.add_child(button)
	_label.add_theme_font_size_override(&"font_size", 22)
	_label.add_theme_color_override(&"font_color", Color.WHITE)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 6)
	bar.add_child(_label)


func _toggle_treatment() -> void:
	_treatment = (_treatment + 1) % TREATMENTS.size()
	_show()


func _toggle_framing() -> void:
	_framing = "old" if _framing == "combat" else "combat"
	_show()


func _next_decor() -> void:
	_decor_index = (_decor_index + 1) % DECORS.size()
	_load_decor()
	_show()


func _load_decor() -> void:
	if _map != null:
		_map.queue_free()
	var decor: Dictionary = DECORS[_decor_index]
	_map = (load(decor["scene"]) as PackedScene).instantiate()
	add_child(_map)
	move_child(_map, 0)
	var profile: LightProfile = null
	if _map.get(&"light_profile") is StringName:
		profile = _profiles.get_profile(_map.get(&"light_profile"))
	_lighting.apply(profile, _map)


func _show() -> void:
	var framing: Dictionary = FRAMINGS[_framing]
	var decor: Dictionary = DECORS[_decor_index]
	var marker := _map.get_node_or_null("Spawns/%s" % decor["spawn"]) as Node2D
	_camera.position = (marker.position if marker != null else Vector2.ZERO) \
		+ (decor["offset"] as Vector2)
	_camera.zoom = Vector2.ONE * float(framing["zoom"])
	_backdrop.set_shader_parameter(&"veil", framing["veil"])
	_backdrop.set_shader_parameter(&"vignette", framing["vignette"])
	_backdrop.set_shader_parameter(&"blur_lod", framing["blur"])
	var view := get_viewport().get_visible_rect().size
	var treatment: Dictionary = TREATMENTS[_treatment]
	_place(true, PLAYER, _anchor(framing["player_feet"], view),
		float(framing["player_height"]) * float(treatment["ratio"]) * view.y, treatment["player"])
	_place(false, FOE, _anchor(framing["foe_feet"], view), float(framing["foe_height"]) * view.y,
		treatment["foe"])
	_hud.set_card(BattleHud.Side.PLAYER, BattleCardView.new(PLAYER["name"],
		BattleCardView.Gender.MALE, PLAYER["level"], 30, 30, true))
	_hud.set_card(BattleHud.Side.FOE, BattleCardView.new(FOE["name"],
		BattleCardView.Gender.MALE, FOE["level"], 22, 22, false))
	_hud.set_party(2)
	_hud.show_actions({ActionGrid.ATTACK: true, ActionGrid.BAG: true, ActionGrid.TEAM: true,
		ActionGrid.RUN: true})
	_arrange_hud(framing["hud"] == "diagonal")
	_label.text = "%d/%d %s · cadrage %s · %s" % [_treatment + 1, TREATMENTS.size(),
		treatment["label"], _framing, decor["name"]]


static func _anchor(feet: Vector2, view: Vector2) -> Vector2:
	return Vector2(view.x / 2.0 + feet.x * view.y, feet.y * view.y).round()


## Place un combattant : pieds (bas de la boîte visible) sur [param feet], hauteur visible
## [param height], rendu [param kind] (voir [constant TREATMENTS]) ; « net » = échelle entière
## (pixels nets), les images HD = échelle libre.
func _place(is_player: bool, who: Dictionary, feet: Vector2, height: float, kind: String) -> void:
	if _sides.has(is_player):
		var old: Dictionary = _sides[is_player]
		if old["tween"] != null:
			(old["tween"] as Tween).kill()
		(old["node"] as Node).queue_free()
		(old["shadow"] as Node).queue_free()
	var shadow := Sprite2D.new()
	shadow.texture = _shadow_texture
	shadow.modulate = Color(0.06, 0.08, 0.05, SHADOW_ALPHA)
	_actors.add_child(shadow)
	var node: Node2D
	var box: Rect2
	var still_path := SPRITE_DIR + "%s.png" % who["painted"]
	if kind == "official":
		still_path = OFFICIAL_DIR + "%03d.png" % int(who["official"])
	elif kind == "model":
		still_path = SPRITE_DIR + "%s.png" % who["model"]
	var scale: float
	if kind in ["painted", "official", "model"] and ResourceLoader.exists(still_path):
		var texture: Texture2D = load(still_path)
		box = _visible_box(texture.get_image())
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.offset = -Vector2(box.get_center().x, box.end.y)
		scale = height / box.size.y
		node = sprite
	else:
		var sheet: String = who["sheet"] + {"smooth": "_lisse"}.get(kind, "")
		if kind == "rebuilt":
			sheet = who["rebuilt"]
		var built := _animated(sheet, kind == "net")
		node = built[0]
		box = built[1]
		# Pixels nets : échelle entière (planche brute) ; la planche lissée est libre.
		scale = height / box.size.y
		if kind == "net":
			scale = maxf(1.0, roundf(scale))
	_actors.add_child(node)
	shadow.position = feet
	var shadow_width := box.size.x * scale * 0.7
	shadow.scale = Vector2(shadow_width, shadow_width * 0.2) / Vector2(_shadow_texture.get_size())
	node.position = feet + (Vector2(-140.0, 40.0) if is_player else Vector2(0.0, -30.0))
	node.scale = Vector2.ONE * scale
	node.modulate.a = 0.0
	var enter := create_tween().set_parallel()
	enter.tween_property(node, ^"position", feet, ENTER_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	enter.tween_property(node, ^"modulate:a", 1.0, ENTER_DURATION * 0.6)
	var tween: Tween = null
	if node is Sprite2D:
		# Le peint n'a pas d'animation : respiration très légère, pieds fixes.
		tween = create_tween().set_loops()
		if not is_player:
			tween.tween_interval(BREATH_PERIOD * 0.35)
		tween.tween_property(node, ^"scale",
			Vector2(scale * (1.0 - BREATH * 0.4), scale * (1.0 + BREATH)), BREATH_PERIOD / 2.0) \
			.set_trans(Tween.TRANS_SINE)
		tween.tween_property(node, ^"scale", Vector2.ONE * scale, BREATH_PERIOD / 2.0) \
			.set_trans(Tween.TRANS_SINE)
	_sides[is_player] = {"node": node, "shadow": shadow, "tween": tween}


## [AnimatedSprite2D (pieds à l'origine), boîte visible] depuis une planche Noir/Blanc.
func _animated(sheet_id: String, nearest: bool) -> Array:
	var meta: Dictionary = _sheets[sheet_id]
	var texture: Texture2D = load(SPRITE_DIR + "%s.png" % sheet_id)
	var image := texture.get_image()
	var size := Vector2i(int(meta["frame"][0]), int(meta["frame"][1]))
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", 100.0)
	var box := Rect2()
	var durations: Array = meta["durations_ms"]
	for i: int in int(meta["count"]):
		var columns := int(meta.get("columns", meta["count"]))
		var region := Rect2i(Vector2i(i % columns * size.x, i / columns * size.y), size)
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(region)
		# Vitesse 100 images/s : la durée relative d'une image = ses millisecondes / 10.
		frames.add_frame(&"default", atlas, float(durations[i]) / 10.0)
		var used := image.get_region(region).get_used_rect()
		if used.has_area():
			box = Rect2(used) if not box.has_area() else box.merge(Rect2(used))
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if nearest \
		else CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.offset = -Vector2(roundf(box.get_center().x), box.end.y)
	sprite.play(&"default")
	return [sprite, box]


## Mode « diagonal » : carte adverse en haut à gauche, la tienne en bas à droite au-dessus de
## la grille d'actions (pastilles d'équipe au-dessus d'elle) ; « default » : le combat actuel.
func _arrange_hud(diagonal: bool) -> void:
	var foe_card := _hud.get_card(BattleHud.Side.FOE)
	var own_card := _hud.get_card(BattleHud.Side.PLAYER)
	var pips := _hud.get_party_pips()
	BattleHudLayout.place(foe_card, BattleHudLayout.Slot.FOE_CARD)
	BattleHudLayout.place(own_card, BattleHudLayout.Slot.OWN_CARD)
	BattleHudLayout.place(pips, BattleHudLayout.Slot.PARTY_PIPS)
	if not diagonal:
		return
	var edge := float(UiTokens.BATTLE_EDGE)
	_pin(foe_card, Vector2(0, 0), Vector2(edge, UiTokens.BATTLE_FOE_CARD_TOP))
	var own_bottom := UiTokens.BATTLE_GRID_BOTTOM + BattleHudLayout.actions_size().y + HUD_GAP
	_pin(own_card, Vector2(1, 1), Vector2(edge, own_bottom))
	var pips_bottom := own_bottom + UiTokens.BATTLE_CARD_HEIGHT_NUMBERS + UiTokens.PARTY_PIPS_GAP
	_pin(pips, Vector2(1, 1), Vector2(edge + UiTokens.PARTY_PIPS_INSET, pips_bottom))


## Ancre [param control] au coin [param corner] (0 ou 1 par axe), à [param margin] des bords.
static func _pin(control: Control, corner: Vector2, margin: Vector2) -> void:
	var size := control.get_combined_minimum_size().max(control.size)
	control.anchor_left = corner.x
	control.anchor_right = corner.x
	control.anchor_top = corner.y
	control.anchor_bottom = corner.y
	control.offset_left = margin.x if corner.x == 0 else -margin.x - size.x
	control.offset_right = control.offset_left + size.x
	control.offset_top = margin.y if corner.y == 0 else -margin.y - size.y
	control.offset_bottom = control.offset_top + size.y


static func _visible_box(image: Image) -> Rect2:
	if image.is_compressed():
		image.decompress()
	return Rect2(image.get_used_rect())


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
