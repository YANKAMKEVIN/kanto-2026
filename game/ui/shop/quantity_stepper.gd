class_name QuantityStepper
extends HBoxContainer
## Sélecteur de quantité de la Boutique (jalon-07.md §6.4) : un bouton −, le nombre, un bouton +,
## chacun d'au moins TOUCH_MIN. Un toucher = un cran ; **appui long** : après SHOP_REPEAT_DELAY
## le cran se répète, de plus en plus vite (intervalle lent, puis rapide, puis de
## SHOP_REPEAT_FAST_STEP en SHOP_REPEAT_FAST_STEP).
##
## Il ne connaît ni objet ni prix : il garde un nombre dans [1, maximum] et émet [signal changed]
## à chaque cran **effectif** (au plafond, rien). Le maximum vient de la vue de l'objet
## ([method ShopEntryView.clamp_quantity]) ; 0 = sélecteur inactif.

## Un cran a changé la quantité (jamais pour un changement posé par [method set_value]).
signal changed(quantity: int)

var _value: int = 1
var _maximum: int = 1
var _active: bool = true
var _direction: int = 0
var _held: float = 0.0
var _next_repeat: float = 0.0

var _minus: Button
var _plus: Button
var _label: Label


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", UiTokens.GAP)
	_minus = _make_button(preload("res://assets/ui/icons/shop/minus.svg"), -1)
	add_child(_minus)
	_label = Label.new()
	_label.theme_type_variation = &"ShopQuantity"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_label)
	_plus = _make_button(preload("res://assets/ui/icons/shop/plus.svg"), 1)
	add_child(_plus)
	set_process(false)
	_apply()


func _process(delta: float) -> void:
	advance(delta)


## Intervalle entre deux crans répétés après [param held] secondes d'appui.
static func interval_for(held: float) -> float:
	return UiTokens.SHOP_REPEAT_FAST if held >= UiTokens.SHOP_REPEAT_FAST_AFTER \
		else UiTokens.SHOP_REPEAT_SLOW


## Taille d'un cran répété après [param held] secondes d'appui.
static func step_for(held: float) -> int:
	return UiTokens.SHOP_REPEAT_FAST_STEP if held >= UiTokens.SHOP_REPEAT_FAST_AFTER else 1


## Pose le maximum ([param maximum] 0 = inactif) et la valeur, ramenée dans [1, maximum] ; sans
## signal.
func configure(maximum: int, value: int) -> void:
	_maximum = maxi(maximum, 0)
	_active = _maximum > 0
	_value = clampi(value, 1, maxi(_maximum, 1))
	stop()
	_apply()


## Pose la valeur (ramenée dans l'intervalle), sans signal.
func set_value(value: int) -> void:
	_value = clampi(value, 1, maxi(_maximum, 1))
	_apply()


func get_value() -> int:
	return _value


func get_maximum() -> int:
	return _maximum


func is_active() -> bool:
	return _active


## Un cran de [param amount] (positif : +, négatif : −) ; émet [signal changed] si la valeur a
## bougé. Sans effet si le sélecteur est inactif. Vrai si la valeur a changé.
func step(amount: int) -> bool:
	if not _active:
		return false
	var next := clampi(_value + amount, 1, _maximum)
	if next == _value:
		return false
	_value = next
	_apply()
	Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
	changed.emit(_value)
	return true


## Fait avancer l'appui long de [param delta] secondes (le jeu l'appelle par [method _process] ;
## les tests le font à la main).
func advance(delta: float) -> void:
	if _direction == 0:
		return
	_held += delta
	var guard := 0
	while _held >= _next_repeat and guard < 200:
		guard += 1
		step(_direction * step_for(_held))
		_next_repeat += interval_for(_held)


## Début d'un appui sur − (−1) ou + (+1) : un cran tout de suite, puis la répétition.
func press(direction: int) -> void:
	if not _active:
		return
	step(direction)
	_direction = direction
	_held = 0.0
	_next_repeat = UiTokens.SHOP_REPEAT_DELAY
	set_process(true)


## Fin de l'appui.
func stop() -> void:
	_direction = 0
	_held = 0.0
	set_process(false)


func get_minus_button() -> Button:
	return _minus


func get_plus_button() -> Button:
	return _plus


func get_value_label() -> Label:
	return _label


func _make_button(icon: Texture2D, direction: int) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ShopStepper"
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2.ONE * UiTokens.SHOP_STEPPER_SIZE
	button.add_theme_constant_override(&"icon_max_width", UiTokens.SHOP_STEPPER_ICON)
	button.button_down.connect(press.bind(direction))
	button.button_up.connect(stop)
	return button


func _apply() -> void:
	if _label == null:
		return
	_label.text = str(_value)
	var dim := UiTokens.SHOP_DISABLED_ALPHA
	_label.modulate.a = 1.0 if _active else dim
	_minus.modulate.a = 1.0 if _active and _value > 1 else dim
	_plus.modulate.a = 1.0 if _active and _value < _maximum else dim
