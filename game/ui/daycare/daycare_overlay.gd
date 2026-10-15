class_name DaycareOverlay
extends TmLearnOverlay
## L'écran de la Pension (J15, T5 ; jalon-15.md §2.5.1, dossier 18 §4) : un voile au-dessus du
## monde avec, pour le dépôt, le [PartyPicker] du Sac (équipe entière, une carte par Pokémon) et,
## pour le retrait, le bandeau et l'hôte des panneaux « apprendre / oublier » hérités de
## [TmLearnOverlay] (le directeur l'utilise comme son `overlay`).
## - Une place refusée reste visible, atténuée, avec **sa raison** sur la carte ; la toucher la
##   fait trembler et met T-5 en titre. Le choix reste ouvert.
## - Une place valide : [method DaycareDirector.choose_deposit] ; sur OK l'écran se ferme.
## - ANNULER et le retour Android : [method DaycareDirector.cancel_pick].
## Aucune règle ici : l'écran affiche la [DaycarePickView] et relaie les touchers.

const PICKER_SCENE: PackedScene = preload("res://game/ui/bag/party_picker.tscn")

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0

var _director: DaycareDirector
## DaycarePickView -> PartyPickerView (fourni par Boot : l'UI ne lit pas les données Pokémon).
var _to_picker: Callable
var _picker: PartyPicker


func _ready() -> void:
	super()
	_picker = PICKER_SCENE.instantiate() as PartyPicker
	_picker.name = "Picker"
	_picker.speed_scale = speed_scale
	var size := BattleHudLayout.picker_size()
	_picker.anchor_left = 0.5
	_picker.anchor_right = 0.5
	_picker.anchor_top = 0.5
	_picker.anchor_bottom = 0.5
	_picker.offset_left = -size.x * 0.5
	_picker.offset_right = size.x * 0.5
	_picker.offset_top = -size.y * 0.5
	_picker.offset_bottom = size.y * 0.5
	_picker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_picker.grow_vertical = Control.GROW_DIRECTION_BOTH
	_picker.target_chosen.connect(_on_target_chosen)
	_picker.back_requested.connect(_on_back_requested)
	_root.add_child(_picker)


## Branche l'écran sur le directeur : [signal DaycareDirector.pick_requested] l'ouvre,
## [signal DaycareDirector.pick_closed] le ferme.
func attach(director: DaycareDirector, to_picker: Callable) -> void:
	_director = director
	_to_picker = to_picker
	director.pick_requested.connect(show_pick)
	director.pick_closed.connect(hide_pick)


## Ouvre le choix du Pokémon à confier.
func show_pick(view: DaycarePickView) -> void:
	open()
	_picker.speed_scale = speed_scale
	_picker.show_targets(_to_picker.call(view) as PartyPickerView)


## Referme le choix (le voile aussi).
func hide_pick() -> void:
	if _picker.is_shown():
		_picker.speed_scale = speed_scale
		_picker.slide_out()
	close()


func is_picking() -> bool:
	return _picker != null and _picker.is_shown()


func get_picker() -> PartyPicker:
	return _picker


func _on_target_chosen(index: int) -> void:
	if _director == null:
		return
	var status := _director.choose_deposit(index)
	if status != DaycareRules.Status.OK:
		# Ne devrait pas arriver (les refus sont des cartes inutilisables) : le choix reste ouvert.
		_picker.get_card(index).shake()


func _on_back_requested() -> void:
	if _director != null:
		_director.cancel_pick()
