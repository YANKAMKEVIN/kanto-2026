class_name BadgeSlot
extends PanelContainer
## Un des 8 emplacements de badges de l'écran Dresseur (dossier 08 §6 ; MM.2, décision de Kevin
## du 2026-10-07 : emplacements en silhouette « ??? »). Un badge **non obtenu** montre la même
## silhouette pour les huit emplacements et « ??? » : ni son nom ni son apparence (dossier 08 §6).
## Un badge obtenu (drapeau levé, [BadgeLibrary]) : l'emblème en ACCENT et son nom ; son image
## viendra avec la DA. **Touchable seulement s'il est obtenu** (J10, T6) : un toucher émet
## [signal touched] (la bulle de détail est posée par [TrainerScreen]) ; un badge muet est inerte.

## Le badge obtenu est touché.
signal touched(slot: BadgeSlot)

const UNKNOWN_TEXT := "???"
## Le mot commun aux huit noms est omis dans l'emplacement (« Roche », comme la maquette) ; le
## nom complet reste dans la vue (bulle de détail au toucher, J10).
const NAME_PREFIX := "Badge "
const EMBLEM: Texture2D = preload("res://assets/ui/icons/trainer/badge_slot.svg")

var _view: BadgeSlotView
var _emblem: TextureRect
var _label: Label
var _down: bool = false


func _init() -> void:
	theme_type_variation = &"TrainerBadge"
	# Zone tactile d'au moins TOUCH_MIN quand le badge est obtenu.
	custom_minimum_size.y = maxf(float(UiTokens.TRAINER_BADGE_SLOT_HEIGHT),
		float(UiTokens.TOUCH_MIN))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 4)
	add_child(box)
	_emblem = TextureRect.new()
	_emblem.texture = EMBLEM
	_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_emblem.custom_minimum_size = Vector2.ONE * UiTokens.TRAINER_BADGE_ICON
	_emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_emblem)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_label)
	setup(BadgeSlotView.new())


## Pose [param view] : silhouette et « ??? » tant que le badge n'est pas obtenu.
func setup(view: BadgeSlotView) -> void:
	_view = view
	var obtained := view.obtained and not view.name.is_empty()
	theme_type_variation = &"TrainerBadgeOn" if obtained else &"TrainerBadge"
	_emblem.modulate = UiTokens.ACCENT if obtained else UiTokens.TRAINER_BADGE_UNKNOWN
	_label.theme_type_variation = &"TrainerBadgeName" if obtained else &"TrainerBadgeUnknown"
	_label.text = view.name.trim_prefix(NAME_PREFIX) if obtained else UNKNOWN_TEXT
	# Seul un badge obtenu reçoit le toucher (tout l'emplacement) ; un badge muet est inerte.
	mouse_filter = Control.MOUSE_FILTER_STOP if obtained else Control.MOUSE_FILTER_IGNORE


## Vrai si le badge n'est pas obtenu (silhouette et « ??? », aucun nom).
func is_muted() -> bool:
	return _label.text == UNKNOWN_TEXT


## Texte de l'emplacement (« ??? » ou le nom du badge).
func get_text() -> String:
	return _label.text


func get_emblem() -> TextureRect:
	return _emblem


func get_view() -> BadgeSlotView:
	return _view


## Vrai si l'emplacement répond au toucher (badge obtenu seulement).
func is_touchable() -> bool:
	return mouse_filter == Control.MOUSE_FILTER_STOP


## La zone tactile : l'emplacement entier.
func get_hit() -> Control:
	return self


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or not is_touchable():
		return
	if mouse.pressed:
		_down = true
	elif _down:
		_down = false
		if get_global_rect().has_point(get_global_mouse_position()):
			Haptics.vibrate(UiTokens.HAPTIC_TICK_MS)
			touched.emit(self)
