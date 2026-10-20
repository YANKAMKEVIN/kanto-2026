class_name ElevatorPanel
extends CanvasLayer
## Panneau d'étages de l'ascenseur — **écran provisoire** (jalon 20 T13). L'écran définitif
## (voile, cartes d'étage, jetons `ui_tokens.gd`, captures) est la tâche **T14** (ui-mobile,
## `docs/tech/jalon-20.md` §2.3.4) : il remplace ce fichier en gardant son **interface** :
## - [method open] (vue [ElevatorPanelView] : titre, FERMER, étages, l'étage courant grisé) ;
## - [method close] ; [method is_open] ;
## - [signal floor_chosen] (un étage touché) et [signal closed] (FERMER).
## Le retour Android ne passe pas par l'écran : [ElevatorDirector] le reçoit de Boot et appelle
## [method close]. L'écran ne décide rien (pas de règle, pas de clé) : il affiche et relaie.

## Un étage a été touché (jamais l'étage courant, désactivé).
signal floor_chosen(floor_id: StringName)
## FERMER a été touché.
signal closed

var _root: Control
var _list: VBoxContainer
var _title: Label
var _view: ElevatorPanelView


func _ready() -> void:
	layer = UiTokens.LAYER_MENU
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_list = VBoxContainer.new()
	_list.name = "List"
	center.add_child(_list)
	_title = Label.new()
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(_title)
	visible = false


## Montre [param view] : un bouton par étage (l'étage courant désactivé), puis FERMER.
func open(view: ElevatorPanelView) -> void:
	_view = view
	for child: Node in _list.get_children():
		if child != _title:
			_list.remove_child(child)
			child.queue_free()
	_title.text = view.title
	for entry: Dictionary in view.floors:
		var button := _button(String(entry["label"]))
		button.name = "Floor_%s" % entry["id"]
		button.disabled = entry["current"]
		var floor_id: StringName = entry["id"]
		button.pressed.connect(func() -> void: floor_chosen.emit(floor_id))
	var close_button := _button(view.close_label)
	close_button.name = "Close"
	close_button.pressed.connect(func() -> void: closed.emit())
	visible = true


func close() -> void:
	visible = false
	_view = null


func is_open() -> bool:
	return visible


## Vue affichée (null panneau fermé).
func get_view() -> ElevatorPanelView:
	return _view


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN * 3, UiTokens.TOUCH_MIN)
	_list.add_child(button)
	return button
