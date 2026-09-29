class_name MoveGrid
extends BattleWidget
## Grille des capacités (combat-capacites-v1) : remplace la grille d'actions après ATTAQUER.
## Quatre emplacements en 2 × 2 sur un bandeau sombre translucide, en bas à droite ; un
## emplacement vide si moins de 4 capacités ; une carte sans PP est atténuée et inerte.
##
## Gestes (dossier 05 §7, jalon 4 Q16) :
## - toucher une carte = move_selected(index), une seule fois : la grille se tait ensuite
##   jusqu'au prochain show_moves (pas de double choix) ;
## - dès l'appui, la carte est sélectionnée : liseré ACCENT + flèche ▶ à sa gauche ;
## - pression longue (LONG_PRESS) = fiche détaillée (MoveDetailSheet) au-dessus des cartes,
##   SANS move_selected ; la fiche se ferme au relâchement du doigt, qui ne lance jamais la
##   capacité (details_opened / details_closed) ;
## - doigt relâché hors de la carte : rien (sélection effacée).
## Clavier (tests sur Mac) : flèches (ui_left/right/up/down) = select, ui_accept = confirm.
## Le bouton « ‹ » est un composant à part (BattleBackButton), sous la carte joueur.

signal move_selected(index: int)
signal details_opened(index: int)
signal details_closed

const SLOTS := 4
const COLUMNS := 2
const CARD_SCENE: PackedScene = preload("res://game/ui/battle/move_card.tscn")
const ARROW: Texture2D = preload("res://assets/ui/icons/battle/select_arrow.svg")

var _cards: Array[MoveCard] = []
var _selected: int = -1
var _answered: bool = false
var _details: int = -1

@onready var _grid: GridContainer = %Cards
@onready var _arrow: TextureRect = %Arrow
@onready var _sheet: MoveDetailSheet = %DetailSheet


func _ready() -> void:
	super._ready()
	_body.custom_minimum_size = BattleHudLayout.moves_size()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", UiTokens.MOVE_GAP_H)
	_grid.add_theme_constant_override(&"v_separation", UiTokens.MOVE_GAP_V)
	_grid.position = Vector2(UiTokens.MOVE_GAP_H, UiTokens.MOVE_BAND_PAD)
	_arrow.texture = ARROW
	_arrow.size = UiTokens.MOVE_SELECT_ARROW
	_arrow.modulate = UiTokens.ACCENT
	_arrow.visible = false
	_sheet.anchor_left = 1.0
	_sheet.anchor_right = 1.0
	_sheet.offset_right = -UiTokens.MOVE_BAND_PAD
	_sheet.offset_left = -UiTokens.MOVE_BAND_PAD - UiTokens.MOVE_DETAIL_WIDTH
	_sheet.offset_bottom = -UiTokens.GAP
	_sheet.offset_top = -UiTokens.GAP
	_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	for i: int in SLOTS:
		var card := CARD_SCENE.instantiate() as MoveCard
		_grid.add_child(card)
		card.pressed_down.connect(_on_pressed_down.bind(i))
		card.tapped.connect(_on_tapped.bind(i))
		card.press_cancelled.connect(_on_cancelled.bind(i))
		card.long_pressed.connect(_on_long_pressed.bind(i))
		card.long_press_released.connect(_on_long_released.bind(i))
		_cards.append(card)


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
		confirm()


## Montre les capacités [param views] (4 au plus ; les emplacements restants sont vides) et
## fait apparaître la grille ; réarme la grille après un choix. Aucune carte sélectionnée.
func show_moves(views: Array[BattleMoveView]) -> void:
	if views.size() > SLOTS:
		push_error("MoveGrid : %d capacités, 4 au plus" % views.size())
	for i: int in SLOTS:
		var view: BattleMoveView = views[i] if i < views.size() else null
		if view != null and not view.is_valid():
			push_error("MoveGrid : vue invalide (emplacement %d)" % i)
			view = null
		_cards[i].set_view(view)
	_answered = false
	_details = -1
	_sheet.speed_scale = speed_scale
	_sheet.slide_out()
	select(-1)
	slide_in()


## Sélectionne la carte [param index] (liseré ACCENT + ▶) ; -1, une carte vide ou sans PP :
## aucune sélection.
func select(index: int) -> void:
	if index < 0 or index >= SLOTS or not _cards[index].is_usable():
		index = -1
	_selected = index
	for i: int in SLOTS:
		_cards[i].set_selected(i == index)
	_arrow.visible = index >= 0
	if index >= 0:
		_place_arrow.call_deferred()


func get_selected() -> int:
	return _selected


## Lance la capacité sélectionnée (clavier) : comme un toucher sur sa carte.
func confirm() -> void:
	if _selected >= 0:
		_choose(_selected)


func get_card(index: int) -> MoveCard:
	return _cards[index]


func get_detail_sheet() -> MoveDetailSheet:
	return _sheet


func get_arrow() -> TextureRect:
	return _arrow


## La fiche détaillée est ouverte (doigt encore posé après une pression longue).
func is_details_open() -> bool:
	return _details >= 0


func _choose(index: int) -> void:
	if _answered or not _shown or not _cards[index].is_usable():
		return
	_answered = true
	select(index)
	_haptic(UiTokens.HAPTIC_TAP_MS)
	move_selected.emit(index)


func _on_pressed_down(index: int) -> void:
	if _answered or not _shown:
		return
	select(index)


func _on_tapped(index: int) -> void:
	_choose(index)


func _on_cancelled(_index: int) -> void:
	if not _answered:
		select(-1)


func _on_long_pressed(index: int) -> void:
	if _answered or not _shown:
		return
	_details = index
	_sheet.speed_scale = speed_scale
	_sheet.open(_cards[index].get_view())
	_haptic(UiTokens.HAPTIC_TAP_MS)
	details_opened.emit(index)


## Relâchement après une pression longue : la fiche se ferme, rien n'est lancé.
func _on_long_released(_index: int) -> void:
	if _details < 0:
		return
	_details = -1
	_sheet.close()
	if not _answered:
		select(-1)
	details_closed.emit()


func _move_selection(step: Vector2i) -> void:
	var usable: Array[int] = []
	for i: int in SLOTS:
		if _cards[i].is_usable():
			usable.append(i)
	if usable.is_empty():
		return
	if _selected < 0:
		select(usable[0])
		return
	var cell := Vector2i(_selected % COLUMNS, _selected / COLUMNS) + step
	var index := cell.y * COLUMNS + cell.x
	if cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and index < SLOTS \
			and _cards[index].is_usable():
		select(index)


## ▶ à gauche de la carte sélectionnée, centrée dans l'écart (MOVE_GAP_H) qui la précède.
func _place_arrow() -> void:
	if _selected < 0:
		return
	var card := _cards[_selected]
	var left := _grid.position.x + card.position.x
	_arrow.position = Vector2(
		left - (UiTokens.MOVE_GAP_H + UiTokens.MOVE_SELECT_ARROW.x) * 0.5,
		_grid.position.y + card.position.y + (card.size.y - UiTokens.MOVE_SELECT_ARROW.y) * 0.5)
