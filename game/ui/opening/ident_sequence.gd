class_name IdentSequence
extends CanvasLayer
## Ident de démarrage (J34, demande de Kevin du 2026-11-03, « à la Netflix ») : le carton
## « Les studios Kevin & Co / vous présentent » après le chargement du moteur, puis les lettres du logo qui
## entrent une à une depuis la droite pour former « POKEMAKE », le filet qui se trace depuis le
## centre, le halo du vrai logo qui s'allume, une tenue, puis un fondu qui découvre l'écran titre
## déjà en place dessous. La partition vient d'[IntroTimeline] ; ici on ne fait que la jouer.
##
## Bande-annonce (« à la Netflix / Canal+ », v2 du 2026-11-04 : scènes jouées) : entre le carton
## et les lettres, la vidéo de [TrailerReel] lue par un [VideoStreamPlayer] (Theora, son sur le
## bus Musique) entre deux bandes noires de cinéma ; elle entre en fondu, s'éteint en fondu, et
## s'arrête avec l'ident (passage compris).
##
## Un toucher, `interact`, Entrée ou le retour Android ([method skip]) saute à la fin : le logo
## formé, puis le fondu. « Réduire les animations » : le carton puis le logo entier en fondu,
## sans bande-annonce.
## [member speed_scale] multiplie les durées (0 : [method play] finit aussitôt).

## L'ident est terminé (fondu fini) : à retirer de l'arbre.
signal finished

const LOGO: Texture2D = preload("res://assets/ui/opening/logo_pokemake.png")
const PARTS_DIR := "res://assets/ui/opening/logo_pokemake_parts/"
const PARTS_MANIFEST := PARTS_DIR + "parts.json"
const SERIF_FONT := UiTokens.VS_SERIF_FONT
## Durée du fondu de sortie après un passage (× speed_scale).
const SKIP_FADE := 0.3
## Entrée en fondu de la vidéo [D] et bus de son son (le curseur Musique des Paramètres).
const VIDEO_FADE_IN := 0.4
const VIDEO_BUS: StringName = &"Music"

var speed_scale: float = 1.0
## « Réduire les animations » : partition réduite.
var reduced: bool = false

var _studio_text: String = ""
var _presents_text: String = ""
var _root: Control
var _card: VBoxContainer
var _card_title: Label
var _card_sub: Label
var _reel: TrailerReel
var _reel_root: Control
var _video: VideoStreamPlayer
var _bars: Array[ColorRect] = []
var _logo_root: Control
var _letters: Array[TextureRect] = []
var _letter_targets: Array[float] = []
var _rule: TextureRect
var _full: TextureRect
var _frame: Vector2 = Vector2.ONE
var _scale: float = 1.0
var _tween: Tween
var _cues: Array[Dictionary] = []
var _playing: bool = false
var _done: bool = false


func _ready() -> void:
	layer = UiTokens.LAYER_IDENT
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = UiTokens.IDENT_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	_build_card()
	_build_reel()
	_build_logo()
	_root.resized.connect(_layout)
	_layout()


## Textes du carton (données `data/opening/title.json`, groupe `ident`) ; utilisable avant l'entrée
## dans l'arbre.
func set_texts(studio: String, presents: String) -> void:
	_studio_text = studio
	_presents_text = presents
	if _card_title != null:
		_card_title.text = studio
		_card_sub.text = presents


## Vidéo de la bande-annonce (null ou sans vidéo : aucune) ; à donner avant l'entrée dans l'arbre.
func set_reel(reel: TrailerReel) -> void:
	_reel = reel if reel != null and reel.has_video() else null
	if _reel_root != null:
		_fill_reel()


## Joue la partition. Avec [member speed_scale] à 0, finit tout de suite.
func play() -> void:
	if _playing or _done:
		return
	_playing = true
	if speed_scale <= 0.0:
		_finish.call_deferred()
		return
	var durations: Array[float] = []
	if _reel != null and not reduced:
		durations = _reel.durations()
	_cues = IntroTimeline.build(_letters.size(), reduced, durations)
	_tween = create_tween().set_parallel(true)
	_tween.set_speed_scale(1.0 / speed_scale)
	for cue: Dictionary in _cues:
		_schedule(cue)
	_tween.chain().tween_callback(_finish)


## Saute à la fin : logo formé, puis fondu court. [param reason] : pour le journal.
func skip(reason: String = "demande") -> void:
	if not _playing or _done:
		return
	print("Ident : passé (%s)" % reason)
	if _tween != null:
		_tween.kill()
		_tween = null
	_stop_video()
	_show_formed_logo()
	_tween = create_tween()
	_tween.set_speed_scale(1.0 / maxf(speed_scale, 0.001))
	_tween.tween_property(_root, "modulate:a", 0.0, SKIP_FADE)
	_tween.tween_callback(_finish)


func is_playing() -> bool:
	return _playing and not _done


func is_done() -> bool:
	return _done


## Durée totale de la partition jouée (secondes, avant speed_scale).
func total_duration() -> float:
	return IntroTimeline.total(_cues)


func get_card() -> VBoxContainer:
	return _card


func get_letters() -> Array[TextureRect]:
	return _letters


func get_rule() -> TextureRect:
	return _rule


func get_full_logo() -> TextureRect:
	return _full


func get_root() -> Control:
	return _root


## Le lecteur de la bande-annonce (null sans vidéo).
func get_video_player() -> VideoStreamPlayer:
	return _video


func get_reel_root() -> Control:
	return _reel_root


## Position d'arrivée (x, dans le cadre du logo mis à l'échelle) de la lettre [param index].
func letter_target_x(index: int) -> float:
	return _letter_targets[index]


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing():
		return
	var pressed: bool = event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept")
	if event is InputEventScreenTouch:
		pressed = pressed or (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		pressed = pressed or (event as InputEventMouseButton).pressed
	if pressed:
		skip(event.get_class() + " " + event.as_text())
		get_viewport().set_input_as_handled()


func _build_card() -> void:
	_card = VBoxContainer.new()
	_card.name = "Card"
	_card.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_theme_constant_override(&"separation", UiTokens.IDENT_CARD_GAP)
	var font := load(SERIF_FONT) as Font
	_card_title = _card_label("Studio", font, UiTokens.IDENT_CARD_TITLE_FONT, UiTokens.IDENT_CARD_TITLE)
	_card_sub = _card_label("Presents", font, UiTokens.IDENT_CARD_SUB_FONT, UiTokens.IDENT_CARD_SUB)
	_card_title.text = _studio_text
	_card_sub.text = _presents_text
	_card.add_child(_card_title)
	_card.add_child(_card_sub)
	_root.add_child(_card)


func _card_label(name_: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = name_
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font != null:
		label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_shadow_color", UiTokens.TEXT_SHADOW)
	label.add_theme_constant_override(&"shadow_offset_y", UiTokens.TEXT_SHADOW_OFFSET)
	label.uppercase = false
	return label


## Conteneur de la vidéo (plein écran) et bandes noires ; rempli par [method _fill_reel].
func _build_reel() -> void:
	_reel_root = Control.new()
	_reel_root.name = "Reel"
	_reel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reel_root.clip_contents = true
	_reel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reel_root.modulate.a = 0.0
	_root.add_child(_reel_root)
	if _reel != null:
		_fill_reel()


func _fill_reel() -> void:
	for child: Node in _reel_root.get_children():
		child.queue_free()
	_video = null
	_bars.clear()
	if _reel == null:
		return
	_video = VideoStreamPlayer.new()
	_video.name = "Video"
	_video.stream = load(_reel.video) as VideoStream
	_video.expand = true
	_video.autoplay = false
	_video.loop = false
	_video.bus = VIDEO_BUS
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reel_root.add_child(_video)
	for side: int in 2:
		var bar := ColorRect.new()
		bar.name = "BarTop" if side == 0 else "BarBottom"
		bar.color = UiTokens.IDENT_BG
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_reel_root.add_child(bar)
		_bars.append(bar)
	_layout_reel()


## La vidéo couvre l'écran (même format 19,5:9 que le S24, étirée au besoin) ; les bandes noires
## par-dessus.
func _layout_reel() -> void:
	var view := _root.size
	if _video != null:
		_video.position = Vector2.ZERO
		_video.size = view
	var bar_height: float = view.y * _reel.letterbox if _reel != null else 0.0
	if _bars.size() == 2:
		_bars[0].position = Vector2.ZERO
		_bars[0].size = Vector2(view.x, bar_height)
		_bars[1].position = Vector2(0.0, view.y - bar_height)
		_bars[1].size = Vector2(view.x, bar_height)


func _build_logo() -> void:
	_logo_root = Control.new()
	_logo_root.name = "Logo"
	_logo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_logo_root)
	var manifest: Dictionary = {}
	if FileAccess.file_exists(PARTS_MANIFEST):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PARTS_MANIFEST))
		if parsed is Dictionary:
			manifest = parsed
	var frame: Array = manifest.get("frame", [LOGO.get_width(), LOGO.get_height()])
	_frame = Vector2(float(frame[0]), float(frame[1]))
	_scale = float(UiTokens.IDENT_LOGO_WIDTH) / _frame.x
	var letters: Array = manifest.get("letters", [])
	for i: int in letters.size():
		var piece: Dictionary = letters[i]
		var rect := _piece(PARTS_DIR + "letter_%d.png" % i, piece)
		if rect == null:
			continue
		rect.name = "Letter%d" % i
		_letters.append(rect)
		_letter_targets.append(rect.position.x)
	var rule: Dictionary = manifest.get("rule", {})
	if not rule.is_empty():
		_rule = _piece(PARTS_DIR + "rule.png", rule)
		if _rule != null:
			_rule.name = "Rule"
			_rule.pivot_offset = _rule.size / 2.0
			_rule.scale.x = 0.0
	_full = TextureRect.new()
	_full.name = "FullLogo"
	_full.texture = LOGO
	_full.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_full.stretch_mode = TextureRect.STRETCH_SCALE
	_full.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full.position = Vector2.ZERO
	_full.size = _frame * _scale
	_full.modulate.a = 0.0
	_logo_root.add_child(_full)
	_logo_root.size = _frame * _scale


func _piece(path: String, piece: Dictionary) -> TextureRect:
	if not ResourceLoader.exists(path):
		return null
	var rect := TextureRect.new()
	rect.texture = load(path) as Texture2D
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2(float(piece["x"]), float(piece["y"])) * _scale
	rect.size = Vector2(float(piece["w"]), float(piece["h"])) * _scale
	_logo_root.add_child(rect)
	return rect


func _layout() -> void:
	var view := _root.size
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not _playing:
		_layout_reel()
	var logo_size := _frame * _scale
	_logo_root.position = Vector2((view.x - logo_size.x) / 2.0,
		view.y * UiTokens.IDENT_LOGO_CENTER_Y - logo_size.y / 2.0)
	# Lettres pas encore posées : hors de l'écran, à droite.
	if not _playing:
		for i: int in _letters.size():
			_letters[i].position.x = _offscreen_x(i)


## Départ d'une lettre : juste au-delà du bord droit de l'écran, dans le repère du logo.
func _offscreen_x(index: int) -> float:
	var view_right := _root.size.x - _logo_root.position.x
	return view_right + UiTokens.IDENT_LETTER_OFFSCREEN + index * 0.0


func _schedule(cue: Dictionary) -> void:
	var start: float = cue["start"]
	var duration: float = cue["duration"]
	match cue["id"]:
		IntroTimeline.CARD_IN:
			_tween.tween_property(_card, "modulate:a", 1.0, duration).set_delay(start)
		IntroTimeline.CARD_OUT:
			_tween.tween_property(_card, "modulate:a", 0.0, duration).set_delay(start)
		IntroTimeline.SHOT:
			# La vidéo (un seul plan) : lecture au repère, entrée en fondu court.
			if _video != null:
				var fade: float = minf(VIDEO_FADE_IN, duration)
				_tween.tween_callback(_start_video).set_delay(start)
				_tween.tween_property(_reel_root, "modulate:a", 1.0, fade).set_delay(start)
		IntroTimeline.REEL_OUT:
			_tween.tween_property(_reel_root, "modulate:a", 0.0, duration).set_delay(start)
			_tween.tween_callback(_stop_video).set_delay(start + duration)
		IntroTimeline.LETTER:
			var letter := _letters[cue["index"]]
			_tween.tween_property(letter, "position:x", _letter_targets[cue["index"]], duration) \
				.from(_offscreen_x(cue["index"])).set_delay(start) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		IntroTimeline.RULE:
			if _rule != null:
				_tween.tween_property(_rule, "scale:x", 1.0, duration).set_delay(start) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		IntroTimeline.GLOW:
			_tween.tween_property(_full, "modulate:a", 1.0, duration).set_delay(start)
			for letter: TextureRect in _letters:
				_tween.tween_property(letter, "modulate:a", 0.0, duration).set_delay(start)
			if _rule != null:
				_tween.tween_property(_rule, "modulate:a", 0.0, duration).set_delay(start)
		IntroTimeline.LOGO_IN:
			_tween.tween_property(_full, "modulate:a", 1.0, duration).set_delay(start)
		IntroTimeline.FADE_OUT:
			_tween.tween_property(_root, "modulate:a", 0.0, duration).set_delay(start)


func _start_video() -> void:
	if _video != null and is_instance_valid(_video):
		_video.play()


func _stop_video() -> void:
	if _video != null and is_instance_valid(_video) and _video.is_playing():
		_video.stop()


## État « logo formé » : lettres posées et éteintes, filet tracé et éteint, vrai logo allumé.
func _show_formed_logo() -> void:
	_card.modulate.a = 0.0
	if _reel_root != null:
		_reel_root.modulate.a = 0.0
	for i: int in _letters.size():
		_letters[i].position.x = _letter_targets[i]
		_letters[i].modulate.a = 0.0
	if _rule != null:
		_rule.scale.x = 1.0
		_rule.modulate.a = 0.0
	_full.modulate.a = 1.0
	_root.modulate.a = 1.0


func _finish() -> void:
	if _done:
		return
	_done = true
	_playing = false
	_stop_video()
	print("Ident : fini")
	finished.emit()
