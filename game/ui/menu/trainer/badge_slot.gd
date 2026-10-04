class_name BadgeSlot
extends PanelContainer
## Un des 8 emplacements de badges de l'écran Dresseur (dossier 08 §6 ; jalon-06.md §3.7,
## Q-13). Un emplacement non obtenu est **muet** : ni nom, ni image, ni « ??? », ni toucher.
## Un badge obtenu (J10) montre son nom ; l'image viendra avec la DA. Jamais interactif au J6.

var _view: BadgeSlotView
var _name: Label


func _init() -> void:
	theme_type_variation = &"TrainerBadge"
	custom_minimum_size.y = UiTokens.TRAINER_BADGE_HEIGHT
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Pose [param view] (l'emplacement redevient muet si le badge n'est pas obtenu).
func setup(view: BadgeSlotView) -> void:
	_view = view
	if _name != null:
		remove_child(_name)
		_name.queue_free()
		_name = null
	if view.obtained and not view.name.is_empty():
		theme_type_variation = &"TrainerBadgeOn"
		_name = Label.new()
		_name.theme_type_variation = &"TrainerBadgeName"
		_name.text = view.name
		_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(_name)
	else:
		theme_type_variation = &"TrainerBadge"


## Vrai si l'emplacement n'a rien à montrer (ni texte, ni image).
func is_muted() -> bool:
	return _name == null


func get_view() -> BadgeSlotView:
	return _view
