class_name MoveForgetPanel
extends BattleWidget
## Panneau d'oubli d'une capacité (jalon 5C T10, Q29 et Q30) : un Pokémon veut apprendre une
## cinquième capacité. Bandeau sombre opaque en bas à droite : la NOUVELLE capacité en haut
## (légende « Nouvelle capacité »), les QUATRE connues en 2 × 2 dessous, puis NE PAS APPRENDRE
## et OUBLIER. Cartes du 4B (MoveCard) ; une carte à 0 PP reste choisissable.
##
## Gestes (aucune fenêtre de confirmation) :
## - toucher une carte connue = elle est SÉLECTIONNÉE (liseré ACCENT), aucun choix n'est émis ;
##   en toucher une autre déplace la sélection ; toucher la nouvelle capacité ne fait rien ;
## - OUBLIER (inactif tant que rien n'est choisi) = un seul forget_chosen(slot) ;
## - NE PAS APPRENDRE = un seul skip_chosen ;
## - pression longue (LONG_PRESS) sur n'importe quelle carte = fiche de la capacité, sans
##   changer la sélection ; elle se ferme au relâchement du doigt.
## Après un choix le panneau se ferme et se tait jusqu'au prochain show_offer.
## Clavier (tests sur Mac) : flèches = sélection, ui_accept = OUBLIER si une carte est choisie
## (pas de touche pour NE PAS APPRENDRE : un refus ne se déclenche pas par erreur).
## Placement : BattleHudLayout.Slot.FORGET (l'hôte appelle BattleHudLayout.place). Il recouvre
## le bandeau des messages : l'hôte le fait sortir avant (le panneau, opaque, le masque sinon).

## OUBLIER touché : emplacement (0 à 3) de la capacité connue à remplacer.
signal forget_chosen(slot: int)
## NE PAS APPRENDRE touché.
signal skip_chosen
## Pression longue sur une carte : emplacement 0 à 3, ou NEW_SLOT pour la nouvelle capacité.
signal details_opened(slot: int)
signal details_closed

const SLOTS := 4
const COLUMNS := 2
## « Emplacement » de la nouvelle capacité dans details_opened.
const NEW_SLOT := -1
## Valeur de _details quand aucune fiche n'est ouverte.
const NO_DETAILS := -2
const CARD_SCENE: PackedScene = preload("res://game/ui/battle/move_card.tscn")
## Textes d'interface.
const NEW_CAPTION := "Nouvelle capacité"
const KNOWN_CAPTION := "Choisis la capacité à oublier"
const SKIP_LABEL := "NE PAS APPRENDRE"
const CONFIRM_LABEL := "OUBLIER"

var _cards: Array[MoveCard] = []
var _selected: int = -1
var _answered: bool = false
var _details: int = NO_DETAILS
var _press_tween: Tween

@onready var _content: VBoxContainer = %Content
@onready var _new_caption: Label = %NewCaption
@onready var _new_card: MoveCard = %NewCard
@onready var _known_caption: Label = %KnownCaption
@onready var _grid: GridContainer = %Cards
@onready var _buttons: HBoxContainer = %Buttons
@onready var _skip: Button = %SkipButton
@onready var _confirm: Button = %ConfirmButton
@onready var _sheet: MoveDetailSheet = %DetailSheet


func _ready() -> void:
	super._ready()
	_body.custom_minimum_size = BattleHudLayout.forget_size()
	var pad := float(UiTokens.MOVE_BAND_PAD)
	_content.offset_left = pad
	_content.offset_top = pad
	_content.offset_right = -pad
	_content.offset_bottom = -pad
	_content.add_theme_constant_override(&"separation", UiTokens.FORGET_ROW_GAP)
	for caption: Label in [_new_caption, _known_caption]:
		caption.custom_minimum_size.y = UiTokens.FORGET_CAPTION_HEIGHT
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_new_caption.text = NEW_CAPTION
	_known_caption.text = KNOWN_CAPTION
	_new_card.ignore_pp = true
	_new_card.long_pressed.connect(_on_long_pressed.bind(NEW_SLOT))
	_new_card.long_press_released.connect(_on_long_released)
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", UiTokens.FORGET_GAP_H)
	_grid.add_theme_constant_override(&"v_separation", UiTokens.MOVE_GAP_V)
	for i: int in SLOTS:
		var card := CARD_SCENE.instantiate() as MoveCard
		card.ignore_pp = true
		_grid.add_child(card)
		card.tapped.connect(_on_tapped.bind(i))
		card.long_pressed.connect(_on_long_pressed.bind(i))
		card.long_press_released.connect(_on_long_released)
		_cards.append(card)
	_buttons.add_theme_constant_override(&"separation", UiTokens.FORGET_GAP_H)
	for button: Button in [_skip, _confirm]:
		button.custom_minimum_size = UiTokens.FORGET_BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.button_down.connect(_press_feedback.bind(button, true))
		button.button_up.connect(_press_feedback.bind(button, false))
	_skip.text = SKIP_LABEL
	_confirm.text = CONFIRM_LABEL
	_skip.pressed.connect(_on_skip)
	_confirm.pressed.connect(_on_confirm)
	# La fiche d'une capacité : centrée dans le panneau, en haut.
	_sheet.anchor_left = 0.5
	_sheet.anchor_right = 0.5
	_sheet.anchor_top = 0.0
	_sheet.anchor_bottom = 0.0
	_sheet.offset_left = -UiTokens.MOVE_DETAIL_WIDTH * 0.5
	_sheet.offset_right = UiTokens.MOVE_DETAIL_WIDTH * 0.5
	_sheet.offset_top = UiTokens.FORGET_SHEET_TOP
	_sheet.offset_bottom = UiTokens.FORGET_SHEET_TOP
	_confirm.disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if not _shown or _answered:
		return
	var moves: Dictionary[StringName, Vector2i] = {
		&"ui_left": Vector2i.LEFT, &"ui_right": Vector2i.RIGHT,
		&"ui_up": Vector2i.UP, &"ui_down": Vector2i.DOWN,
	}
	for action: StringName in moves:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			_move_selection(moves[action])
			return
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		_on_confirm()


## Montre l'offre : la nouvelle capacité [param new_move] et les capacités connues
## [param known] (4 au plus, une carte par emplacement dans l'ordre). Rien n'est choisi ;
## réarme le panneau après un choix. Une vue invalide est refusée (erreur, rien ne change).
func show_offer(new_move: BattleMoveView, known: Array[BattleMoveView]) -> void:
	if new_move == null or not new_move.is_valid() or known.is_empty() or known.size() > SLOTS:
		push_error("MoveForgetPanel : offre invalide")
		return
	for view: BattleMoveView in known:
		if view == null or not view.is_valid():
			push_error("MoveForgetPanel : capacité connue invalide")
			return
	_new_card.set_view(new_move)
	for i: int in SLOTS:
		_cards[i].set_view(known[i] if i < known.size() else null)
	_answered = false
	_details = NO_DETAILS
	_sheet.speed_scale = speed_scale
	_sheet.slide_out()
	select(-1)
	slide_in()


## Sélectionne la carte connue [param slot] (liseré ACCENT) et active OUBLIER ; -1 ou une
## carte vide : plus rien de choisi. N'émet aucun signal de choix.
func select(slot: int) -> void:
	if slot < 0 or slot >= SLOTS or _cards[slot].is_empty():
		slot = -1
	_selected = slot
	for i: int in SLOTS:
		_cards[i].set_selected(i == slot)
	_confirm.disabled = slot < 0


## Emplacement sélectionné (0 à 3), -1 si rien.
func get_selected() -> int:
	return _selected


## Carte connue de l'emplacement [param slot] (0 à 3).
func get_card(slot: int) -> MoveCard:
	return _cards[slot]


func get_new_card() -> MoveCard:
	return _new_card


func get_confirm_button() -> Button:
	return _confirm


func get_skip_button() -> Button:
	return _skip


func get_detail_sheet() -> MoveDetailSheet:
	return _sheet


## La fiche est ouverte (doigt encore posé après une pression longue).
func is_details_open() -> bool:
	return _details != NO_DETAILS


## Un choix a été fait : le panneau se tait jusqu'au prochain show_offer.
func is_answered() -> bool:
	return _answered


func _on_tapped(slot: int) -> void:
	if _answered or not _shown or is_details_open():
		return
	select(slot)
	_haptic(UiTokens.HAPTIC_TICK_MS)


func _on_confirm() -> void:
	if _answered or not _shown or _selected < 0:
		return
	_answered = true
	_haptic(UiTokens.HAPTIC_TAP_MS)
	forget_chosen.emit(_selected)
	slide_out()


func _on_skip() -> void:
	if _answered or not _shown:
		return
	_answered = true
	_haptic(UiTokens.HAPTIC_TAP_MS)
	skip_chosen.emit()
	slide_out()


func _on_long_pressed(slot: int) -> void:
	if _answered or not _shown:
		return
	var card := _new_card if slot == NEW_SLOT else _cards[slot]
	_details = slot
	_sheet.speed_scale = speed_scale
	_sheet.open(card.get_view())
	_haptic(UiTokens.HAPTIC_TAP_MS)
	details_opened.emit(slot)


## Relâchement après une pression longue : la fiche se ferme, la sélection ne change pas.
func _on_long_released() -> void:
	if not is_details_open():
		return
	_details = NO_DETAILS
	_sheet.close()
	details_closed.emit()


func _move_selection(step: Vector2i) -> void:
	if _selected < 0:
		select(0)
		return
	var cell := Vector2i(_selected % COLUMNS, _selected / COLUMNS) + step
	var index := cell.y * COLUMNS + cell.x
	if cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and index < SLOTS \
			and not _cards[index].is_empty():
		select(index)


## Légère mise à l'échelle à l'appui (PRESSED_SCALE), retour au relâchement.
func _press_feedback(button: Button, down: bool) -> void:
	button.pivot_offset = button.size * 0.5
	if _press_tween != null:
		_press_tween.kill()
	_press_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target := Vector2.ONE * (UiTokens.PRESSED_SCALE if down else 1.0)
	_press_tween.tween_property(button, ^"scale", target, UiTokens.ANIM_MICRO)
