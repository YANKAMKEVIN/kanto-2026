class_name DashboardScreen
extends MenuScreen
## Tableau de bord du Menu Dresseur (dossier 08 §1) : la carte du Dresseur et le Pokémon de
## tête à gauche, les grandes cartes à droite, une ligne d'objectif discrète en bas.
##
## Il reçoit un [DashboardView] et n'en sait rien d'autre. Cartes : de 4 à 6, rangées en deux
## lignes pleines (3 + 3, 3 + 2, 2 + 2) qui se partagent la largeur : jamais d'emplacement vide.
## Un texte vide dans la vue = un élément absent (objectif, vus · capturés, badges), et
## pas de Pokémon de tête = pas de carte.
## Placement : rempli par [TrainerMenu] dans la zone sous l'en-tête, marges de SAFE_MARGIN.

## Une grande carte est touchée ; porte l'écran qu'elle ouvre.
signal card_chosen(screen: StringName)
## Le Pokémon de tête est touché.
signal lead_chosen

## Cartes par ligne : la première ligne prend la moitié haute (arrondie en haut).
const MAX_PER_ROW := 3

var _trainer: TrainerCardPanel
var _rows: VBoxContainer
var _objective: Label
var _cards: Array[MenuCard] = []


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(column)
	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", UiTokens.GAP)
	column.add_child(body)
	_trainer = TrainerCardPanel.new()
	_trainer.lead_chosen.connect(lead_chosen.emit)
	body.add_child(_trainer)
	_rows = VBoxContainer.new()
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override(&"separation", UiTokens.MENU_CARD_GAP)
	body.add_child(_rows)
	_objective = Label.new()
	_objective.theme_type_variation = &"MenuObjective"
	_objective.custom_minimum_size.y = UiTokens.MENU_OBJECTIVE_HEIGHT
	_objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective.clip_text = true
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_objective)


## Affiche [param view] (les cartes sont reconstruites : l'ordre est celui de la vue).
func show_dashboard(view: DashboardView) -> void:
	_trainer.show_view(view)
	for old: Node in _rows.get_children():
		_rows.remove_child(old)
		old.queue_free()
	_cards.clear()
	var per_row := mini(MAX_PER_ROW, ceili(view.cards.size() / 2.0))
	var row: HBoxContainer = null
	for index: int in view.cards.size():
		if index == 0 or index == per_row:
			row = _new_row()
		var card := MenuCard.new()
		row.add_child(card)
		card.setup(view.cards[index])
		card.chosen.connect(card_chosen.emit)
		_cards.append(card)
	_objective.text = view.objective_text
	_objective.visible = not view.objective_text.is_empty()


## Les grandes cartes affichées, dans l'ordre.
func get_cards() -> Array[MenuCard]:
	return _cards


func get_card(screen: StringName) -> MenuCard:
	for card: MenuCard in _cards:
		if card.get_screen() == screen:
			return card
	return null


func get_trainer_card() -> TrainerCardPanel:
	return _trainer


func get_objective_label() -> Label:
	return _objective


func _new_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override(&"separation", UiTokens.MENU_CARD_GAP)
	_rows.add_child(row)
	return row
