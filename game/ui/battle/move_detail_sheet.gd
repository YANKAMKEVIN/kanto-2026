class_name MoveDetailSheet
extends BattleWidget
## Fiche détaillée d'une capacité, ouverte par une pression longue sur sa carte (dossier 05
## §7) : NOM, pastille du type, catégorie (Physique / Spéciale / Statut), Puissance
## (« — » si aucune), Précision (« — » si elle touche toujours), PP, description.
##
## Petite carte sombre translucide, posée par MoveGrid au-dessus des capacités ; elle entre en
## glissant de MOVE_DETAIL_SLIDE depuis le bas en fondu (MOVE_DETAIL_OPEN). Elle ne reçoit
## aucune entrée : MoveGrid la ferme au relâchement du doigt.

## Textes d'interface.
const CATEGORY_NAMES: Dictionary[BattleMoveView.Category, String] = {
	BattleMoveView.Category.PHYSICAL: "Physique",
	BattleMoveView.Category.SPECIAL: "Spéciale",
	BattleMoveView.Category.STATUS: "Statut",
}
const POWER_CAPTION := "Puissance"
const ACCURACY_CAPTION := "Précision"
const PP_CAPTION := "PP"
const NO_VALUE := "—"
const PP_FORMAT := "%d/%d"

var _view: BattleMoveView

@onready var _content: VBoxContainer = %Content
@onready var _stats: HBoxContainer = %Stats
@onready var _name_label: Label = %NameLabel
@onready var _badge: TypeBadge = %Badge
@onready var _category: Label = %Category
@onready var _power: Label = %PowerValue
@onready var _accuracy: Label = %AccuracyValue
@onready var _pp: Label = %PpValue
@onready var _description: Label = %Description


func _ready() -> void:
	slide_direction = Vector2.DOWN
	_open_time = UiTokens.MOVE_DETAIL_OPEN
	_close_time = UiTokens.MOVE_DETAIL_CLOSE
	_slide_distance = UiTokens.MOVE_DETAIL_SLIDE
	super._ready()
	_body.custom_minimum_size.x = UiTokens.MOVE_DETAIL_WIDTH
	_content.add_theme_constant_override(&"separation", UiTokens.MOVE_DETAIL_GAP)
	_stats.add_theme_constant_override(&"separation", UiTokens.MOVE_DETAIL_STAT_GAP)
	(%PowerCaption as Label).text = POWER_CAPTION
	(%AccuracyCaption as Label).text = ACCURACY_CAPTION
	(%PpCaption as Label).text = PP_CAPTION


## Remplit la fiche avec [param view] et la fait apparaître. Une vue invalide est refusée.
func open(view: BattleMoveView) -> void:
	if view == null or not view.is_valid():
		push_error("MoveDetailSheet : vue invalide")
		return
	_view = view
	_name_label.text = view.display_name.to_upper()
	_badge.set_type(view.type_id, view.type_name)
	_category.text = CATEGORY_NAMES.get(view.category, "")
	_power.text = str(view.power) if view.power > 0 else NO_VALUE
	_accuracy.text = str(view.accuracy) if view.accuracy > 0 else NO_VALUE
	_pp.text = PP_FORMAT % [view.pp, view.max_pp]
	_description.text = view.description
	_description.visible = not view.description.is_empty()
	slide_in()


## Coroutine : fait disparaître la fiche.
func close() -> void:
	await slide_out()


func get_view() -> BattleMoveView:
	return _view


func get_name_text() -> String:
	return _name_label.text


func get_category_text() -> String:
	return _category.text


func get_power_text() -> String:
	return _power.text


func get_accuracy_text() -> String:
	return _accuracy.text


func get_pp_text() -> String:
	return _pp.text


func get_description_text() -> String:
	return _description.text


func get_badge() -> TypeBadge:
	return _badge
