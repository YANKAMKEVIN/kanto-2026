class_name VsBanner
extends Control
## Séquence « VS » des grands combats (dossier 05 §3, décision de Kevin du 2026-11-02 ; remplace
## la carte de Champion) : banderole **rouge en haut** (portrait peint de l'adversaire, son nom et
## son titre), banderole **bleue en bas** (portrait du joueur et son prénom). Elles entrent
## (VS_IN), tiennent pendant que l'emblème « VS » éclate au centre (VS_HOLD), puis s'écartent,
## celle du haut vers la gauche, celle du bas vers la droite (VS_OUT) ; vient ensuite l'entrée du
## combat. Durées : le plan [TrainerIntro].
##
## **Jamais sautée** : ni souris ni toucher ne sont écoutés ni consommés. « Réduire les
## animations » (plan sans glissé) : fondus sur place, aux mêmes durées.
## Construit en code (aucune scène) ; couleurs et tailles : [UiTokens] (VS_*). Plein écran,
## aspect expand (1920 à 2340 de large) : les banderoles couvrent toute la largeur.

## Une étape commence (tests, son).
signal step_started(step: TrainerIntro.Step)
## La séquence est finie (le nœud reste, invisible ; l'appelant le libère).
signal finished

const INSTANT_STEP: float = 1000.0

## Multiplicateur des durées (0 = instantané, tests).
var speed_scale: float = 1.0

var _veil: ColorRect
var _top: Control
var _bottom: Control
var _emblem: Control
var _foe_name: Label
var _foe_title: Label
var _player_name: Label
var _foe_portrait: TextureRect
var _player_portrait: TextureRect
var _tweens: Array[Tween] = []
var _playing: bool = false


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
	_top = _make_banner(&"FoeBanner", UiTokens.VS_FOE_BG, false)
	_bottom = _make_banner(&"OwnBanner", UiTokens.VS_PLAYER_BG, true)
	_foe_portrait = _make_portrait(_top)
	_player_portrait = _make_portrait(_bottom)
	_foe_name = _make_label(_top, &"VsBannerName")
	_foe_title = _make_label(_top, &"VsBannerTitle")
	_player_name = _make_label(_bottom, &"VsBannerName")
	_emblem = VsEmblem.new()
	_emblem.name = &"Emblem"
	_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_emblem)
	visible = false


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
	# VS_IN : la banderole du haut arrive de la droite, celle du bas de la gauche.
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
	# VS_OUT : elles s'écartent (haut vers la gauche, bas vers la droite), l'emblème s'efface.
	step_started.emit(TrainerIntro.Step.VS_OUT)
	var out := intro.duration(TrainerIntro.Step.VS_OUT)
	var leave := _new_tween()
	leave.set_parallel(true)
	leave.tween_property(_veil, ^"modulate:a", 0.0, out)
	leave.tween_property(_emblem, ^"modulate:a", 0.0, out)
	leave.tween_property(_emblem, ^"scale", Vector2.ONE * UiTokens.VS_EMBLEM_POP, out)
	for pair: Array in [[_top, -width], [_bottom, width]]:
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


## Banderole du haut (adversaire) et du bas (joueur), tests et captures.
func get_foe_banner() -> Control:
	return _top


func get_player_banner() -> Control:
	return _bottom


## Place banderoles, portraits, textes et emblème pour la taille de vue courante.
func _layout() -> void:
	var view := _view()
	var height := UiTokens.VS_BANNER_HEIGHT * view.y
	var margin := UiTokens.VS_BANNER_MARGIN * view.y
	_top.position = Vector2(0.0, margin)
	_top.size = Vector2(view.x, height)
	_bottom.position = Vector2(0.0, view.y - margin - height)
	_bottom.size = Vector2(view.x, height)
	var portrait_height := UiTokens.VS_PORTRAIT_HEIGHT * view.y
	var raise := UiTokens.VS_PORTRAIT_RAISE * view.y
	var inset := UiTokens.SAFE_MARGIN + UiTokens.VS_TEXT_INSET
	for entry: Array in [[_foe_portrait, true], [_player_portrait, false]]:
		var rect: TextureRect = entry[0]
		var width := portrait_height * 0.75
		if rect.texture != null:
			width = portrait_height * rect.texture.get_width() / maxf(rect.texture.get_height(), 1.0)
		rect.size = Vector2(width, portrait_height)
		rect.position = Vector2(view.x - inset - width if entry[1] else float(inset), -raise)
	var name_size := _foe_name.get_combined_minimum_size()
	var title_size := _foe_title.get_combined_minimum_size()
	var block := name_size.y + title_size.y
	_foe_name.position = Vector2(inset, (height - block) / 2.0)
	_foe_title.position = Vector2(inset, _foe_name.position.y + name_size.y)
	var player_size := _player_name.get_combined_minimum_size()
	_player_name.position = Vector2(view.x - inset - player_size.x, (height - player_size.y) / 2.0)
	_emblem.size = UiTokens.VS_BOLT_SIZE
	_emblem.pivot_offset = UiTokens.VS_BOLT_SIZE / 2.0
	_emblem.position = view / 2.0 - UiTokens.VS_BOLT_SIZE / 2.0


func _view() -> Vector2:
	var rect := get_viewport_rect() if is_inside_tree() else Rect2()
	return rect.size if rect.size != Vector2.ZERO else Vector2(1920, 1080)


func _make_banner(banner_name: StringName, color: Color, edge_top: bool) -> Control:
	var banner := Control.new()
	banner.name = banner_name
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.clip_contents = true
	var fill := ColorRect.new()
	fill.name = &"Fill"
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.add_child(fill)
	var edge := ColorRect.new()
	edge.name = &"Edge"
	edge.color = UiTokens.VS_EDGE
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if edge_top
		else Control.PRESET_BOTTOM_WIDE)
	if edge_top:
		edge.offset_bottom = UiTokens.VS_EDGE_WIDTH
	else:
		edge.offset_top = -UiTokens.VS_EDGE_WIDTH
	banner.add_child(edge)
	add_child(banner)
	return banner


func _make_portrait(banner: Control) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = &"Portrait"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	banner.add_child(rect)
	return rect


func _make_label(banner: Control, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(label)
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


## Emblème « VS » : éclair ACCENT et lettres grasses cernées de sombre, dessinés en code.
class VsEmblem:
	extends Control

	func _draw() -> void:
		var s := size
		# Éclair en zigzag (huit points), du haut à droite vers le bas à gauche.
		var bolt := PackedVector2Array([
			Vector2(0.62, 0.0), Vector2(0.30, 0.52), Vector2(0.48, 0.52), Vector2(0.22, 1.0),
			Vector2(0.78, 0.40), Vector2(0.56, 0.40), Vector2(0.80, 0.0), Vector2(0.62, 0.0),
		])
		for i: int in bolt.size():
			bolt[i] = bolt[i] * s
		draw_colored_polygon(bolt, UiTokens.VS_EDGE)
		var font := get_theme_default_font()
		var text := "VS"
		var font_size := UiTokens.VS_EMBLEM_FONT
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var origin := Vector2((s.x - text_size.x) / 2.0,
			(s.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
		draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			UiTokens.VS_EMBLEM_OUTLINE, UiTokens.VS_EMBLEM_OUTLINE_COLOR)
		draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiTokens.TEXT)
