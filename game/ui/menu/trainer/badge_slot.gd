class_name BadgeSlot
extends PanelContainer
## Un des 8 emplacements de badges de l'écran Dresseur (dossier 08 §6 ; MM.2, décision de Kevin
## du 2026-10-07 : emplacements en silhouette « ??? »). Un badge **non obtenu** montre la même
## silhouette pour les huit emplacements et « ??? » : ni son nom ni son apparence (dossier 08 §6).
## Un badge obtenu (drapeau levé, [BadgeLibrary]) : l'emblème en ACCENT et son nom ; son image
## viendra avec la DA. Jamais interactif (le détail au toucher viendra avec le J10).

const UNKNOWN_TEXT := "???"
## Le mot commun aux huit noms est omis dans l'emplacement (« Roche », comme la maquette) ; le
## nom complet reste dans la vue (détail au toucher, J10).
const NAME_PREFIX := "Badge "
const EMBLEM: Texture2D = preload("res://assets/ui/icons/trainer/badge_slot.svg")

var _view: BadgeSlotView
var _emblem: TextureRect
var _label: Label


func _init() -> void:
	theme_type_variation = &"TrainerBadge"
	custom_minimum_size.y = UiTokens.TRAINER_BADGE_SLOT_HEIGHT
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
