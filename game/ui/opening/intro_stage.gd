class_name IntroStage
extends CanvasLayer
## Scène de l'introduction du Prof. Chen (OUV.2, dossier 13 §3.3, §4 plans 2 à 8, §9.0 ; composition
## de reference/ouverture-chen-v1.webp, règle 10 : Nidorino y est peint, en jeu c'est l'artwork
## officiel).
##
## Calque LAYER_MENU posé sur la **vraie carte du labo en mode décor** (côté monde, créée par
## Boot) : le monde est **très flouté** par le shader du Menu Dresseur, puis éclairé d'une lumière
## dorée procédurale (dégradé radial venu de la fenêtre) avec un voile chaud au sol. Graphismes
## « Économie » : voile seul, sans flou ([method set_backdrop_blur]).
## Trois emplacements (gauche, centre, droite) reçoivent les portraits peints en pied (Chen, le
## joueur, le rival) et l'artwork de Nidorino ; leurs pieds sont posés juste au-dessus de la boîte
## de dialogue (celle du jeu, sur son propre calque). Mouvements :
##  - [method show_portrait] : entrée en fondu avec une légère montée, ou glissement vers un autre
##    emplacement s'il est déjà là ; effet « pokeball » : éclair blanc doré et étincelles, puis le
##    Pokémon apparaît (et respire doucement) ;
##  - [method hide_portrait] : sortie en fondu.
## Chaque mouvement rend sa durée : l'appelant attend la plus longue d'un groupe de mouvements.
## « Réduire les animations » ([member reduce_motion]) : durées raccourcies, ni montée, ni
## glissement (fondu sur place), ni respiration. [member speed_scale] = 0 : tout est instantané.
## Vue pure : elle ne connaît ni le script de l'introduction ni les prénoms.
## Elle porte aussi l'écran de prénom ([NameEntry]), sur un calque au-dessus de la boîte de
## dialogue (LAYER_NAME_ENTRY).

## Portraits connus (identifiants de `data/opening/oak_intro.json`) et leur hauteur affichée.
const TEXTURES: Dictionary[StringName, Texture2D] = {
	&"chen": preload("res://assets/sprites/characters/painted/chen_portrait.png"),
	&"player": preload("res://assets/sprites/characters/painted/heros_portrait.png"),
	&"rival": preload("res://assets/sprites/characters/painted/rival_portrait.png"),
	&"nidorino": preload("res://assets/sprites/pokemon/official/033.png"),
}
const HEIGHTS: Dictionary[StringName, float] = {
	&"chen": UiTokens.INTRO_HEIGHT_ADULT,
	&"player": UiTokens.INTRO_HEIGHT_CHILD,
	&"rival": UiTokens.INTRO_HEIGHT_CHILD,
	&"nidorino": UiTokens.INTRO_HEIGHT_POKEMON,
}
const EFFECT_POKEBALL: StringName = &"pokeball"
const BACKDROP_SHADER: Shader = preload("res://game/ui/menu/menu_backdrop.gdshader")
const NAME_ENTRY_SCENE: PackedScene = preload("res://game/ui/opening/name_entry.tscn")

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0
## « Réduire les animations » (dossier 13 §7).
var reduce_motion: bool = false

var _root: Control
var _backdrop: ColorRect
var _portraits_layer: Control
## Portrait → son support (Control ancré à l'emplacement) ; le TextureRect est son enfant.
var _holders: Dictionary[StringName, Control] = {}
var _slots: Dictionary[StringName, StringName] = {}
var _tweens: Dictionary[StringName, Tween] = {}
var _breath: Tween
var _effects_layer: Control
var _name_entry: NameEntry
var _blur_enabled: bool = true


func _ready() -> void:
	layer = UiTokens.LAYER_MENU
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_backdrop()
	_portraits_layer = _full_rect("Portraits")
	_effects_layer = _full_rect("Effects")
	# L'écran de prénom a son propre calque, **au-dessus** de la boîte de dialogue (ouverte
	# derrière, son fond plein écran prendrait tous les touchers : QA S21).
	var entry_layer := CanvasLayer.new()
	entry_layer.name = "EntryLayer"
	entry_layer.layer = UiTokens.LAYER_NAME_ENTRY
	add_child(entry_layer)
	_name_entry = NAME_ENTRY_SCENE.instantiate() as NameEntry
	entry_layer.add_child(_name_entry)


## Montre [param portrait] à l'emplacement [param slot] (`left`, `center`, `right`) : entrée en
## fondu et montée, ou glissement s'il est déjà sur la scène ; [param effect] « pokeball » :
## éclair puis apparition. Rend la durée du mouvement (secondes, déjà multipliée).
func show_portrait(portrait: StringName, slot: StringName, effect: StringName = &"") -> float:
	if not TEXTURES.has(portrait) or not UiTokens.INTRO_SLOT_X.has(slot):
		push_warning("IntroStage : portrait « %s » ou emplacement « %s » inconnu" % [portrait,
			slot])
		return 0.0
	var holder: Control = _holders.get(portrait)
	if holder != null and _slots.get(portrait) != slot:
		_slots[portrait] = slot
		return _move(portrait, holder, slot)
	if holder != null:
		return 0.0
	holder = _make_holder(portrait)
	_holders[portrait] = holder
	_slots[portrait] = slot
	_place(holder, UiTokens.INTRO_SLOT_X[slot])
	return _enter(portrait, holder, effect)


## Retire [param portrait] (fondu). Rend la durée du mouvement.
func hide_portrait(portrait: StringName) -> float:
	var holder: Control = _holders.get(portrait)
	if holder == null:
		return 0.0
	_holders.erase(portrait)
	_slots.erase(portrait)
	if portrait == &"nidorino" and _breath != null:
		_breath.kill()
		_breath = null
	var time := _time(UiTokens.INTRO_PORTRAIT_OUT)
	_kill_tween(portrait)
	if time <= 0.0:
		_free_holder(holder)
		return 0.0
	var tween := _new_tween(portrait)
	tween.tween_property(holder, ^"modulate:a", 0.0, time)
	tween.tween_callback(_free_holder.bind(holder))
	return time


## Portraits sur la scène (portrait → emplacement).
func get_on_stage() -> Dictionary[StringName, StringName]:
	return _slots.duplicate()


## Support d'un portrait (null s'il n'est pas sur la scène) : son TextureRect est l'enfant
## « Picture ».
func get_holder(portrait: StringName) -> Control:
	return _holders.get(portrait)


func get_name_entry() -> NameEntry:
	return _name_entry


func get_backdrop() -> ColorRect:
	return _backdrop


## Vrai si un mouvement de scène est en cours.
func is_animating() -> bool:
	for tween: Tween in _tweens.values():
		if tween != null and tween.is_valid() and tween.is_running():
			return true
	return false


## Flou du fond (graphismes « Économie » : voile seul, comme le Menu Dresseur).
func set_backdrop_blur(enabled: bool) -> void:
	_blur_enabled = enabled
	if _backdrop != null:
		(_backdrop.material as ShaderMaterial).set_shader_parameter(&"blur_on", enabled)


func _build_backdrop() -> void:
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	var material := ShaderMaterial.new()
	material.shader = BACKDROP_SHADER
	material.set_shader_parameter(&"amount", 1.0)
	material.set_shader_parameter(&"blur_radius", UiTokens.INTRO_BLUR_RADIUS)
	material.set_shader_parameter(&"blur_lod", UiTokens.INTRO_BLUR_LOD)
	material.set_shader_parameter(&"blur_on", _blur_enabled)
	material.set_shader_parameter(&"dim", UiTokens.INTRO_DIM)
	material.set_shader_parameter(&"dim_color", UiTokens.INTRO_DIM_COLOR)
	_backdrop.material = material
	_root.add_child(_backdrop)
	# Lumière dorée : dégradé radial venu de la fenêtre (haut), sur tout l'écran.
	var glow := TextureRect.new()
	glow.name = "Glow"
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.texture = _radial(UiTokens.INTRO_GLOW, UiTokens.INTRO_GLOW_EDGE,
		UiTokens.INTRO_GLOW_CENTER, UiTokens.INTRO_GLOW_RADIUS)
	_root.add_child(glow)
	# Voile chaud du sol : transparent au milieu, teinté en bas.
	var floor_shade := TextureRect.new()
	floor_shade.name = "FloorShade"
	floor_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	floor_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor_shade.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.set_color(0, UiTokens.INTRO_FLOOR_CLEAR)
	gradient.set_color(1, UiTokens.INTRO_FLOOR_SHADE)
	gradient.set_offset(0, 0.55)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 4
	texture.height = 128
	floor_shade.texture = texture
	_root.add_child(floor_shade)


func _full_rect(node_name: String) -> Control:
	var layer_control := Control.new()
	layer_control.name = node_name
	layer_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(layer_control)
	return layer_control


## Support ancré au bas-centre du portrait (x : part de la largeur, y : ligne des pieds) ; le
## TextureRect « Picture » est posé au-dessus, centré.
func _make_holder(portrait: StringName) -> Control:
	var texture := TEXTURES[portrait]
	var height: float = HEIGHTS[portrait]
	var width := height * texture.get_width() / float(texture.get_height())
	var holder := Control.new()
	holder.name = String(portrait).capitalize()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.size = Vector2(width, height)
	picture.position = Vector2(-width * 0.5, -height)
	picture.pivot_offset = Vector2(width * 0.5, height)
	holder.add_child(picture)
	_portraits_layer.add_child(holder)
	return holder


func _place(holder: Control, x_ratio: float) -> void:
	holder.anchor_left = x_ratio
	holder.anchor_right = x_ratio
	holder.anchor_top = 0.0
	holder.anchor_bottom = 0.0
	holder.offset_left = 0.0
	holder.offset_right = 0.0
	holder.offset_top = UiTokens.INTRO_FEET_Y
	holder.offset_bottom = UiTokens.INTRO_FEET_Y


func _enter(portrait: StringName, holder: Control, effect: StringName) -> float:
	var picture := holder.get_node(^"Picture") as TextureRect
	var fade := _time(UiTokens.INTRO_PORTRAIT_IN)
	var delay := 0.0
	if effect == EFFECT_POKEBALL:
		delay = _flash(holder)
	_kill_tween(portrait)
	if fade <= 0.0 and delay <= 0.0:
		holder.modulate.a = 1.0
		_after_enter(portrait, picture)
		return 0.0
	var tween := _new_tween(portrait)
	holder.modulate.a = 0.0
	var rise := 0.0 if reduce_motion else UiTokens.INTRO_PORTRAIT_RISE
	var base_y := picture.position.y
	picture.position.y = base_y + rise
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(holder, ^"modulate:a", 1.0, fade).set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	if rise > 0.0:
		tween.parallel().tween_property(picture, ^"position:y", base_y, fade) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_after_enter.bind(portrait, picture))
	return delay + fade


## Glissement vers [param slot] ; réduit : fondu sur place (sortie, saut, entrée).
func _move(portrait: StringName, holder: Control, slot: StringName) -> float:
	var target: float = UiTokens.INTRO_SLOT_X[slot]
	var time := _time(UiTokens.INTRO_PORTRAIT_MOVE)
	_kill_tween(portrait)
	if time <= 0.0:
		_place(holder, target)
		holder.modulate.a = 1.0
		return 0.0
	var tween := _new_tween(portrait)
	if reduce_motion:
		tween.tween_property(holder, ^"modulate:a", 0.0, time * 0.5)
		tween.tween_callback(_place.bind(holder, target))
		tween.tween_property(holder, ^"modulate:a", 1.0, time * 0.5)
		return time
	tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(holder, ^"anchor_left", target, time)
	tween.tween_property(holder, ^"anchor_right", target, time)
	tween.tween_property(holder, ^"modulate:a", 1.0, time)
	return time


## Sortie de Poké Ball : un éclair blanc doré qui grandit et s'éteint au pied du Pokémon, des
## étincelles qui s'écartent. Rend le délai avant l'apparition du Pokémon.
func _flash(holder: Control) -> float:
	var time := _time(UiTokens.INTRO_FLASH)
	if time <= 0.0:
		return 0.0
	var height: float = HEIGHTS[&"nidorino"]
	var center := Vector2(0.0, -height * 0.45)
	# Sur le calque des effets (le portrait, lui, est encore transparent), au même endroit.
	var spot := Control.new()
	spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effects_layer.add_child(spot)
	_place(spot, holder.anchor_left)
	create_tween().tween_callback(spot.queue_free).set_delay(time * 3.0)
	var flash := _effect_sprite(UiTokens.INTRO_FLASH_SIZE)
	spot.add_child(flash)
	flash.position = center - flash.size * 0.5
	flash.pivot_offset = flash.size * 0.5
	flash.scale = Vector2.ONE * 0.2
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, ^"scale", Vector2.ONE, time).set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, ^"modulate:a", 0.0, time * 2.0).set_delay(time * 0.5)
	tween.chain().tween_callback(flash.queue_free)
	if reduce_motion:
		return time
	for i: int in UiTokens.INTRO_SPARKLES:
		var sparkle := _effect_sprite(UiTokens.INTRO_SPARKLE_SIZE)
		spot.add_child(sparkle)
		sparkle.position = center - sparkle.size * 0.5
		var angle := TAU * i / float(UiTokens.INTRO_SPARKLES)
		var target := sparkle.position + Vector2.from_angle(angle) \
			* UiTokens.INTRO_SPARKLE_DISTANCE
		var spark := create_tween().set_parallel(true)
		spark.tween_property(sparkle, ^"position", target, time * 2.0) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		spark.tween_property(sparkle, ^"modulate:a", 0.0, time * 2.0)
		spark.chain().tween_callback(sparkle.queue_free)
	return time


func _effect_sprite(side: float) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = _radial(UiTokens.INTRO_FLASH_COLOR, UiTokens.INTRO_FLASH_EDGE,
		Vector2(0.5, 0.5), 0.5)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.size = Vector2.ONE * side
	return sprite


## Pokémon : petite respiration (sauf animations réduites).
func _after_enter(portrait: StringName, picture: TextureRect) -> void:
	if portrait != &"nidorino" or reduce_motion or speed_scale <= 0.0:
		return
	if _breath != null:
		_breath.kill()
	_breath = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath.tween_property(picture, ^"scale", Vector2(1.0, 1.0 + UiTokens.INTRO_BREATH),
		UiTokens.INTRO_BREATH_TIME * 0.5)
	_breath.tween_property(picture, ^"scale", Vector2.ONE, UiTokens.INTRO_BREATH_TIME * 0.5)


func _free_holder(holder: Control) -> void:
	if is_instance_valid(holder):
		holder.get_parent().remove_child(holder)
		holder.queue_free()


func _kill_tween(portrait: StringName) -> void:
	var old: Tween = _tweens.get(portrait)
	if old != null and old.is_valid():
		old.kill()
	_tweens.erase(portrait)


func _new_tween(portrait: StringName) -> Tween:
	var tween := create_tween()
	_tweens[portrait] = tween
	return tween


## [param base] secondes, multipliées par [member speed_scale] et la réduction des animations.
func _time(base: float) -> float:
	return base * speed_scale * (UiTokens.INTRO_REDUCED if reduce_motion else 1.0)


static func _radial(inner: Color, outer: Color, center: Vector2, radius: float) \
		-> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, inner)
	gradient.set_color(1, outer)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = center
	texture.fill_to = center + Vector2(radius, 0.0)
	texture.width = 256
	texture.height = 256
	return texture
