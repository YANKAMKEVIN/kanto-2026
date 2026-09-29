class_name Toast
extends Control
## Toast (bible UI/UX §6) : « Poké Balls ×5 — Ajoutées au Sac » en haut au centre de l'écran,
## jamais d'interruption : on continue de jouer pendant qu'il est affiché.
##
## Capsule sombre translucide (variation « Toast ») : icône à gauche (Poké Ball par défaut),
## titre gras au-dessus, détail discret en dessous. Il descend de TOAST_SLIDE en fondu
## (TOAST_FADE_IN), reste TOAST_HOLD, puis remonte en fondu (TOAST_FADE_OUT) et se cache.
## Vibration « tic » (HAPTIC_TICK_MS, bible §12) à chaque toast.
## Purement visuel : ni lui ni ses enfants n'interceptent souris ou toucher.
## Placement (aspect expand, 1920 à 2340 de large) : ancré au milieu du bord haut, à
## TOAST_TOP, il grandit des deux côtés avec son texte.

## Un toast commence (texte posé, apparition lancée).
signal toast_shown(title: String, detail: String)
## Le toast vient de disparaître (fin de sa tenue ou hide_now).
signal toast_hidden
## Vibration demandée (millisecondes), émise même quand haptics_enabled est faux (tests).
signal haptic_played(duration_ms: int)

const DEFAULT_ICON: Texture2D = preload("res://assets/ui/icons/poke_ball.svg")

## Durées multipliées (0 = instantané ; la tenue aussi).
var speed_scale: float = 1.0
## Faux en test : pas de vibration réelle (haptic_played est quand même émis).
var haptics_enabled: bool = true

var _tween: Tween
var _showing: bool = false

@onready var _body: PanelContainer = %Body
@onready var _row: HBoxContainer = %Row
@onready var _lines: VBoxContainer = %Lines
@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _detail: Label = %Detail


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_END
	offset_left = 0.0
	offset_right = 0.0
	offset_top = UiTokens.TOAST_TOP
	offset_bottom = UiTokens.TOAST_TOP
	_row.add_theme_constant_override(&"separation", UiTokens.TOAST_GAP)
	_lines.add_theme_constant_override(&"separation", UiTokens.TOAST_LINE_GAP)
	_icon.custom_minimum_size = Vector2.ONE * UiTokens.TOAST_ICON
	_icon.texture = DEFAULT_ICON
	_body.minimum_size_changed.connect(update_minimum_size)
	resized.connect(_fit_body)
	update_minimum_size()
	_fit_body()
	visible = false
	modulate.a = 0.0


func _get_minimum_size() -> Vector2:
	if _body == null:
		return Vector2.ZERO
	return _body.get_combined_minimum_size()


## Affiche [param title] (« Poké Balls ×5 ») et [param detail] (« Ajoutées au Sac ») avec
## [param icon] (Poké Ball si null) : apparition, tenue TOAST_HOLD, disparition. Un toast
## déjà affiché change de texte et sa tenue repart de zéro, sans nouvelle apparition.
func show_toast(title: String, detail: String, icon: Texture2D = null) -> void:
	_title.text = title
	_detail.text = detail
	_detail.visible = not detail.is_empty()
	_icon.texture = icon if icon != null else DEFAULT_ICON
	_kill()
	if not _showing:
		_body.position = Vector2.UP * UiTokens.TOAST_SLIDE
		modulate.a = 0.0
	_showing = true
	visible = true
	_haptic(UiTokens.HAPTIC_TICK_MS)
	toast_shown.emit(title, detail)
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_body, ^"position", Vector2.ZERO, _time(UiTokens.TOAST_FADE_IN))
	_tween.parallel().tween_property(self, ^"modulate:a", 1.0, _time(UiTokens.TOAST_FADE_IN))
	_tween.tween_interval(_time(UiTokens.TOAST_HOLD))
	_tween.tween_property(_body, ^"position", Vector2.UP * UiTokens.TOAST_SLIDE,
		_time(UiTokens.TOAST_FADE_OUT)).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, ^"modulate:a", 0.0, _time(UiTokens.TOAST_FADE_OUT)) \
		.set_ease(Tween.EASE_IN)
	_tween.tween_callback(_on_hidden)


## Efface le toast en fondu court (ANIM_MICRO) ; émet toast_hidden à la fin. Sans effet
## s'il n'est pas affiché.
func hide_now() -> void:
	if not _showing:
		return
	_kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, ^"modulate:a", 0.0, _time(UiTokens.ANIM_MICRO))
	_tween.tween_callback(_on_hidden)


## Un toast est affiché (apparition, tenue ou disparition en cours).
func is_showing() -> bool:
	return _showing


func get_title_text() -> String:
	return _title.text


func get_detail_text() -> String:
	return _detail.text


func get_icon() -> Texture2D:
	return _icon.texture


func get_body() -> PanelContainer:
	return _body


func _time(duration: float) -> float:
	return maxf(duration * speed_scale, 0.0)


## Le visuel prend la taille du toast ; sa position reste libre pour le glissement.
func _fit_body() -> void:
	_body.size = size


func _haptic(duration_ms: int) -> void:
	haptic_played.emit(duration_ms)
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms)


func _kill() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _on_hidden() -> void:
	_tween = null
	_showing = false
	visible = false
	_body.position = Vector2.ZERO
	toast_hidden.emit()
