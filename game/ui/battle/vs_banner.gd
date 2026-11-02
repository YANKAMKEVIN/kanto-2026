class_name VsBanner
extends Control
## Séquence « VS » des grands combats (dossier 05 §3, décisions de Kevin du 2026-11-02 ; cible :
## maquette `reference/entree-dresseur-vs-v1.png` ; remplace la carte de Champion). Posée sur
## l'arène, les deux dresseurs déjà en place derrière : banderole **rouge en haut à droite** qui
## arrive de la droite (buste peint de l'adversaire débordant la banderole, nom en capitales à
## empattements dorées, filet et losange, titre dessous), banderole **bleue en bas à gauche** qui
## arrive de la gauche (buste et prénom du joueur) ; fines, en biais, à effet pinceau ; « VS » doré
## au centre avec un éclair diagonal et deux traits. Elles entrent (VS_IN), tiennent pendant que
## l'emblème éclate (VS_HOLD), puis repartent d'où elles viennent (VS_OUT). Durées : le plan
## [TrainerIntro].
##
## **Jamais sautée** : ni souris ni toucher ne sont écoutés ni consommés. « Réduire les
## animations » (plan sans glissé) : fondus sur place, aux mêmes durées.
## Construit en code (aucune scène) ; couleurs, tailles, police et textures : [UiTokens] (VS_*).
## Texture pinceau remplaçable par banderole (`VS_*_BANNER_TEXTURE`) ; absente : pinceau dessiné.

## Une étape commence (tests, son).
signal step_started(step: TrainerIntro.Step)
## La séquence est finie (le nœud reste, invisible ; l'appelant le libère).
signal finished

const INSTANT_STEP: float = 1000.0
## Graine des bords déchirés (dessin identique à chaque séquence).
const BRUSH_SEED: int = 2026

## Multiplicateur des durées (0 = instantané, tests).
var speed_scale: float = 1.0

var _veil: ColorRect
var _top: Control
var _bottom: Control
var _foe_stripe: VsStripe
var _own_stripe: VsStripe
var _foe_clip: Control
var _own_clip: Control
var _emblem: VsEmblem
var _foe_name: Label
var _foe_title: Label
var _player_name: Label
var _foe_rule: VsRule
var _own_rule: VsRule
var _foe_portrait: TextureRect
var _player_portrait: TextureRect
var _tweens: Array[Tween] = []
var _playing: bool = false

static var _serif: Font


func _init() -> void:
	name = &"VsBanner"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil = ColorRect.new()
	_veil.name = &"Veil"
	_veil.color = UiTokens.VS_VEIL
	_veil.modulate.a = 0.0
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_veil)
	_top = _make_holder(&"FoeBanner")
	_bottom = _make_holder(&"OwnBanner")
	_foe_stripe = VsStripe.new(UiTokens.VS_FOE_BG, UiTokens.VS_FOE_BANNER_TEXTURE, false)
	_own_stripe = VsStripe.new(UiTokens.VS_PLAYER_BG, UiTokens.VS_PLAYER_BANNER_TEXTURE, true)
	_top.add_child(_foe_stripe)
	_bottom.add_child(_own_stripe)
	_foe_clip = _make_clip(_top)
	_own_clip = _make_clip(_bottom)
	_foe_portrait = _make_portrait(_foe_clip)
	_player_portrait = _make_portrait(_own_clip)
	_foe_name = _make_label(_foe_stripe, &"VsBannerName", true)
	_foe_rule = VsRule.new()
	_foe_stripe.add_child(_foe_rule)
	_foe_title = _make_label(_foe_stripe, &"VsBannerTitle", false)
	_player_name = _make_label(_own_stripe, &"VsBannerName", true)
	_own_rule = VsRule.new()
	_own_stripe.add_child(_own_rule)
	_emblem = VsEmblem.new()
	_emblem.name = &"Emblem"
	_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_emblem)
	visible = false


## Police à empattements des noms et du « VS » (Cinzel gras), lue une fois ; null si absente.
static func serif_font() -> Font:
	if _serif == null and ResourceLoader.exists(UiTokens.VS_SERIF_FONT):
		var base := load(UiTokens.VS_SERIF_FONT) as Font
		var bold := FontVariation.new()
		bold.base_font = base
		var weight := TextServerManager.get_primary_interface().name_to_tag("wght")
		bold.variation_opentype = {weight: UiTokens.VS_SERIF_WEIGHT}
		_serif = bold
	return _serif


## Coroutine : joue la séquence de [param intro] (étapes VS_IN, VS_HOLD, VS_OUT) avec
## l'adversaire [param foe_name] (mis en MAJUSCULES) / [param foe_title] / [param foe_portrait]
## et le joueur [param player_name] / [param player_portrait] (portraits null : aucun).
func play(intro: TrainerIntro, foe_name: String, foe_title: String, foe_portrait: Texture2D,
		player_name: String, player_portrait: Texture2D) -> void:
	_kill()
	_playing = true
	_foe_name.text = foe_name.to_upper()
	_foe_title.text = foe_title
	_player_name.text = player_name.to_upper()
	_foe_portrait.texture = foe_portrait
	_player_portrait.texture = player_portrait
	visible = true
	_layout()
	var width := _view().x
	var slide := intro.slide
	# VS_IN : la rouge arrive de la droite, la bleue de la gauche.
	step_started.emit(TrainerIntro.Step.VS_IN)
	var duration := intro.duration(TrainerIntro.Step.VS_IN)
	_emblem.scale = Vector2.ZERO
	_emblem.modulate.a = 1.0
	var enter := _new_tween()
	enter.set_parallel(true)
	enter.tween_property(_veil, ^"modulate:a", 1.0, duration)
	for pair: Array in [[_top, width], [_bottom, -width]]:
		var banner: Control = pair[0]
		banner.modulate.a = 0.0 if not slide else 1.0
		banner.position.x = pair[1] if slide else 0.0
		enter.tween_property(banner, ^"position:x", 0.0, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		enter.tween_property(banner, ^"modulate:a", 1.0, duration)
	await _play(enter)
	# VS_HOLD : l'emblème éclate puis se pose ; les banderoles tiennent.
	step_started.emit(TrainerIntro.Step.VS_HOLD)
	var hold := intro.duration(TrainerIntro.Step.VS_HOLD)
	var pop := hold * UiTokens.VS_EMBLEM_POP_SHARE
	var hold_tween := _new_tween()
	hold_tween.tween_property(_emblem, ^"scale", Vector2.ONE * UiTokens.VS_EMBLEM_POP, pop * 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hold_tween.tween_property(_emblem, ^"scale", Vector2.ONE, pop * 0.4)
	hold_tween.tween_interval(maxf(hold - pop, 0.0))
	await _play(hold_tween)
	# VS_OUT : elles repartent d'où elles viennent, l'emblème s'efface.
	step_started.emit(TrainerIntro.Step.VS_OUT)
	var out := intro.duration(TrainerIntro.Step.VS_OUT)
	var leave := _new_tween()
	leave.set_parallel(true)
	leave.tween_property(_veil, ^"modulate:a", 0.0, out)
	leave.tween_property(_emblem, ^"modulate:a", 0.0, out)
	leave.tween_property(_emblem, ^"scale", Vector2.ONE * UiTokens.VS_EMBLEM_POP, out)
	for pair: Array in [[_top, width], [_bottom, -width]]:
		var banner: Control = pair[0]
		if slide:
			leave.tween_property(banner, ^"position:x", pair[1], out) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		leave.tween_property(banner, ^"modulate:a", 0.0, out)
	await _play(leave)
	visible = false
	_playing = false
	finished.emit()


func is_playing() -> bool:
	return _playing


func get_foe_name_text() -> String:
	return _foe_name.text


func get_foe_title_text() -> String:
	return _foe_title.text


func get_player_name_text() -> String:
	return _player_name.text


func get_foe_portrait() -> Texture2D:
	return _foe_portrait.texture


func get_player_portrait() -> Texture2D:
	return _player_portrait.texture


## Banderole du haut (adversaire) et du bas (joueur), tests et captures : leur décalage
## horizontal (0 au repos) est leur position x.
func get_foe_banner() -> Control:
	return _top


func get_player_banner() -> Control:
	return _bottom


## Place banderoles, bustes, textes et emblème pour la taille de vue courante.
func _layout() -> void:
	var view := _view()
	var thick := UiTokens.VS_FOE_BANNER_THICK * view.y
	var own_thick := UiTokens.VS_PLAYER_BANNER_THICK * view.y
	var overhang := 0.1 * view.x
	# Rouge en haut à droite, montant vers la droite : son bout extérieur dépasse le bord droit.
	_foe_stripe.size = Vector2(UiTokens.VS_FOE_BANNER_WIDTH * view.x + overhang, thick)
	_foe_stripe.position = Vector2(view.x * (1.0 - UiTokens.VS_FOE_BANNER_WIDTH),
		UiTokens.VS_FOE_BANNER_Y * view.y - thick / 2.0)
	_foe_stripe.pivot_offset = Vector2(0.0, thick / 2.0)
	_foe_stripe.rotation = -deg_to_rad(UiTokens.VS_FOE_BANNER_TILT)
	# Bleue en bas à gauche : son bout extérieur dépasse le bord gauche.
	_own_stripe.size = Vector2(UiTokens.VS_PLAYER_BANNER_WIDTH * view.x + overhang, own_thick)
	_own_stripe.position = Vector2(-overhang,
		UiTokens.VS_PLAYER_BANNER_Y * view.y - own_thick / 2.0)
	_own_stripe.pivot_offset = Vector2(_own_stripe.size.x, own_thick / 2.0)
	_own_stripe.rotation = deg_to_rad(UiTokens.VS_PLAYER_BANNER_TILT)
	_foe_stripe.queue_redraw()
	_own_stripe.queue_redraw()
	# Bustes débordant la banderole : l'adversaire rogné par le bas de sa banderole, le joueur
	# par le bas de l'écran.
	var portrait_height := UiTokens.VS_PORTRAIT_HEIGHT * view.y
	var foe_top := UiTokens.VS_FOE_PORTRAIT_TOP * view.y
	_foe_clip.position = Vector2(view.x * 0.62, foe_top)
	_foe_clip.size = Vector2(view.x * 0.38, UiTokens.VS_FOE_PORTRAIT_BOTTOM * view.y - foe_top)
	_place_portrait(_foe_portrait, portrait_height, _foe_clip.size, false)
	_own_clip.position = Vector2(0.0, UiTokens.VS_PLAYER_PORTRAIT_TOP * view.y)
	_own_clip.size = Vector2(view.x * 0.38, view.y - _own_clip.position.y)
	_place_portrait(_player_portrait, portrait_height, _own_clip.size, true)
	# Textes : nom, filet, titre, centrés dans la partie libre de la banderole.
	var inset := float(UiTokens.VS_TEXT_INSET)
	_center_text(_foe_stripe, [_foe_name, _foe_rule, _foe_title],
		inset + UiTokens.VS_FOE_BANNER_WIDTH * view.x * 0.36)
	_center_text(_own_stripe, [_player_name, _own_rule],
		_own_stripe.size.x - inset - UiTokens.VS_PLAYER_BANNER_WIDTH * view.x * 0.35)
	_emblem.width = UiTokens.VS_EMBLEM_WIDTH * view.x
	_emblem.size = Vector2(_emblem.width * 1.3, _emblem.width * 1.1)
	_emblem.pivot_offset = _emblem.size / 2.0
	_emblem.position = UiTokens.VS_EMBLEM_CENTER * view - _emblem.size / 2.0
	_emblem.queue_redraw()


## Empile [param parts] (labels et filet) centrés verticalement dans [param stripe], centrés
## horizontalement sur [param center_x].
func _center_text(stripe: Control, parts: Array, center_x: float) -> void:
	var total := 0.0
	for part: Control in parts:
		total += part.get_combined_minimum_size().y if part is Label else part.size.y
	var y := (stripe.size.y - total) / 2.0
	for part: Control in parts:
		var size := part.get_combined_minimum_size() if part is Label else part.size
		part.position = Vector2(center_x - size.x / 2.0, y)
		y += size.y


func _place_portrait(rect: TextureRect, height: float, area: Vector2, left: bool) -> void:
	var width := height * 0.65
	if rect.texture != null:
		width = height * rect.texture.get_width() / maxf(rect.texture.get_height(), 1.0)
	rect.size = Vector2(width, height)
	rect.position = Vector2(0.0 if left else area.x - width, 0.0)


func _view() -> Vector2:
	var rect := get_viewport_rect() if is_inside_tree() else Rect2()
	return rect.size if rect.size != Vector2.ZERO else Vector2(1920, 1080)


func _make_holder(holder_name: StringName) -> Control:
	var holder := Control.new()
	holder.name = holder_name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	return holder


func _make_clip(holder: Control) -> Control:
	var clip := Control.new()
	clip.name = &"PortraitClip"
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.clip_contents = true
	holder.add_child(clip)
	return clip


func _make_portrait(parent: Control) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = &"Portrait"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(rect)
	return rect


func _make_label(parent: Control, variation: StringName, serif: bool) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := serif_font()
	if font != null:
		label.add_theme_font_override(&"font", font)
	if serif:
		label.add_theme_color_override(&"font_color", UiTokens.VS_GOLD)
		label.add_theme_color_override(&"font_outline_color", UiTokens.VS_GOLD_OUTLINE)
		label.add_theme_constant_override(&"outline_size", UiTokens.VS_NAME_OUTLINE)
	parent.add_child(label)
	return label


func _new_tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _play(tween: Tween) -> void:
	if speed_scale <= 0.0:
		tween.custom_step(INSTANT_STEP)
	else:
		tween.set_speed_scale(speed_scale)
	if tween.is_valid() and tween.is_running():
		await tween.finished
	_tweens.erase(tween)


func _kill() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()


## Banderole : la texture pinceau si elle existe (bout déchiré à gauche ; la bleue est retournée),
## sinon un coup de pinceau dessiné : bord intérieur déchiré, traînées claires et sombres, liseré.
class VsStripe:
	extends Control

	var _color: Color
	var _texture: Texture2D
	var _mirrored: bool

	func _init(color: Color, texture_path: String, mirrored: bool) -> void:
		_color = color
		_mirrored = mirrored
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(texture_path):
			_texture = load(texture_path) as Texture2D

	func _draw() -> void:
		var s := size
		if _mirrored:
			draw_set_transform(Vector2(s.x, 0.0), 0.0, Vector2(-1.0, 1.0))
		if _texture != null:
			draw_texture_rect(_texture, Rect2(Vector2.ZERO, s), false)
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = VsBanner.BRUSH_SEED
		var depth := s.y * UiTokens.VS_BRUSH_DEPTH
		# Bandes horizontales (trapèzes convexes, jamais de triangulation ratée) : le bout intérieur
		# de chaque bande commence à un x tiré, d'où le bord déchiré.
		var teeth := UiTokens.VS_BRUSH_TEETH
		var lefts: Array[float] = []
		for i: int in teeth + 1:
			lefts.append(rng.randf_range(0.0, depth * 4.0))
		for i: int in teeth:
			var y0 := s.y * float(i) / float(teeth)
			var y1 := s.y * float(i + 1) / float(teeth)
			draw_colored_polygon(PackedVector2Array([Vector2(lefts[i], y0), Vector2(s.x, y0),
				Vector2(s.x, y1), Vector2(lefts[i + 1], y1)]), _color)
		# Traînées du pinceau.
		for i: int in UiTokens.VS_BRUSH_STREAKS:
			var y := rng.randf_range(0.1, 0.9) * s.y
			var start := rng.randf_range(0.0, 0.35) * s.x
			var length := rng.randf_range(0.3, 0.7) * s.x
			var shade := _color.lightened(0.25) if i % 2 == 0 else _color.darkened(0.3)
			shade.a = 0.35
			draw_rect(Rect2(start, y, length, rng.randf_range(2.0, depth * 0.6)), shade)
		var edge := _color.lightened(0.45)
		edge.a = 0.8
		draw_line(Vector2(depth * 2.0, 2.0), Vector2(s.x, 2.0), edge, 3.0)
		draw_line(Vector2(depth * 2.0, s.y - 2.0), Vector2(s.x, s.y - 2.0), edge, 3.0)


## Filet doré sous un nom, losange au centre.
class VsRule:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(UiTokens.VS_RULE_LENGTH, UiTokens.VS_RULE_DIAMOND * 2 + 6)

	func _draw() -> void:
		var y := size.y / 2.0
		var fade := UiTokens.VS_GOLD
		fade.a = 0.0
		var line := PackedVector2Array([Vector2(0, y), Vector2(size.x / 2.0, y),
			Vector2(size.x, y)])
		draw_polyline_colors(line, PackedColorArray([fade, UiTokens.VS_GOLD, fade]),
			UiTokens.VS_RULE_WIDTH, true)
		var d := float(UiTokens.VS_RULE_DIAMOND)
		var c := Vector2(size.x / 2.0, y)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0),
			c + Vector2(0, d), c + Vector2(-d, 0)]), UiTokens.VS_GOLD)


## Emblème « VS » : l'image peinte [constant UiTokens.VS_EMBLEM_TEXTURE] si elle existe ; sinon,
## dessiné : éclat additif, lettres dorées à empattements en dégradé (or profond dessous, or clair
## dessus), entaille diagonale, éclair et deux traits horizontaux.
class VsEmblem:
	extends Control

	## Largeur voulue des lettres « VS » (px).
	var width: float = 280.0
	var _texture: Texture2D
	## Éclat additif au-dessus des lettres (calque à part, mélange additif).
	var _halo: Control
	var _font: Font
	var _font_size: int = 0
	var _origin: Vector2 = Vector2.ZERO

	func _init() -> void:
		if ResourceLoader.exists(UiTokens.VS_EMBLEM_TEXTURE):
			_texture = load(UiTokens.VS_EMBLEM_TEXTURE) as Texture2D
		_halo = Control.new()
		_halo.name = &"Glow"
		_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_halo.material = additive
		_halo.draw.connect(_draw_glow)
		add_child(_halo)

	func _draw_glow() -> void:
		if _font == null or _texture != null:
			return
		_halo.draw_string_outline(_font, _origin, "VS", HORIZONTAL_ALIGNMENT_LEFT, -1,
			_font_size, UiTokens.VS_EMBLEM_GLOW_SIZE, UiTokens.VS_EMBLEM_GLOW)

	func _draw() -> void:
		var s := size
		var center := s / 2.0
		var gold := UiTokens.VS_GOLD
		var deep := UiTokens.VS_GOLD_DEEP
		var fade := gold
		fade.a = 0.0
		# Deux traits horizontaux qui s'effacent vers l'extérieur (maquette 3).
		var line := float(UiTokens.VS_EMBLEM_LINE)
		var half := width * 0.55
		draw_polyline_colors(PackedVector2Array([Vector2(center.x - half - line, center.y),
			Vector2(center.x - half, center.y)]), PackedColorArray([fade, gold]), 5.0, true)
		draw_polyline_colors(PackedVector2Array([Vector2(center.x + half, center.y),
			Vector2(center.x + half + line, center.y)]), PackedColorArray([gold, fade]), 5.0, true)
		if _texture != null:
			var tex_size := _texture.get_size() * width / maxf(_texture.get_width(), 1.0)
			draw_texture_rect(_texture, Rect2(center - tex_size / 2.0, tex_size), false)
			return
		# Éclair diagonal derrière les lettres.
		var bolt := PackedVector2Array([Vector2(0.78, 0.0), Vector2(0.48, 0.52),
			Vector2(0.58, 0.50), Vector2(0.2, 1.0)])
		for i: int in bolt.size():
			bolt[i] = bolt[i] * s
		draw_polyline(bolt, deep, 14.0, true)
		draw_polyline(bolt, gold, 5.0, true)
		var font := VsBanner.serif_font()
		if font == null:
			font = get_theme_default_font()
		var text := "VS"
		var probe := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 100)
		var font_size := int(100.0 * width / maxf(probe.x, 1.0))
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var origin := Vector2(center.x - text_size.x / 2.0,
			center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
		# Contour sombre, or profond, puis or clair décalé (dégradé du bas vers le haut) ; l'éclat
		# additif est dessiné par le calque « Glow ».
		_font = font
		_font_size = font_size
		_origin = origin
		_halo.size = s
		_halo.queue_redraw()
		draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			UiTokens.VS_EMBLEM_OUTLINE, UiTokens.VS_GOLD_OUTLINE)
		draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, deep)
		draw_string(font, origin + Vector2(0.0, -font_size * 0.04), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, gold)
		# Entaille diagonale à travers les lettres.
		var top := origin + Vector2(text_size.x * 0.62, -font.get_ascent(font_size) * 0.95)
		var bottom := origin + Vector2(text_size.x * 0.38, font.get_descent(font_size))
		draw_line(top, bottom, UiTokens.VS_GOLD_OUTLINE, maxf(font_size * 0.05, 3.0), true)
		var light := gold.lightened(0.5)
		draw_line(top + Vector2(3, 0), bottom + Vector2(3, 0), light, 1.5, true)
