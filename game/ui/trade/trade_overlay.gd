class_name TradeOverlay
extends TmLearnOverlay
## Choix du Pokémon à échanger (jalon 25, `jalon-25.md` §2.5 : « sélecteur de cible existant,
## filtré sur l'espèce ») : le [PartyPicker] du Sac sur un voile, toute l'équipe, seules les
## places de l'espèce demandée utilisables (les autres gardent leur raison). Le choix d'une place
## ou ANNULER (retour Android) referme l'écran. Aucune règle ici : [method pick] rend la place.

const PICKER_SCENE: PackedScene = preload("res://game/ui/bag/party_picker.tscn")
## Titre de l'écran [D] ; raison d'une place refusée [D].
const TITLE: String = "Échanger un Pokémon"
const REFUSED_REASON: String = "Pas l'espèce demandée"

signal _picked(index: int)

## Durées multipliées (0 = instantané, pour les tests).
var speed_scale: float = 1.0

var _picker: PartyPicker


func _ready() -> void:
	super()
	_picker = PICKER_SCENE.instantiate() as PartyPicker
	_picker.name = "Picker"
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
	_picker.target_chosen.connect(func(index: int) -> void: _picked.emit(index))
	_picker.back_requested.connect(func() -> void: _picked.emit(-1))
	_root.add_child(_picker)


## Vue du choix : [param party] entière, [param accepted] utilisables.
static func view_for(party: Party, accepted: Array[int], data: PokemonData) -> PartyPickerView:
	var picker := PartyPickerView.new()
	picker.title = TITLE
	var members := party.get_all()
	for i: int in members.size():
		var ok := i in accepted
		picker.targets.append(PartyTargetView.new(DashboardViews.member(members[i], i, data),
			ok, "" if ok else REFUSED_REASON, REFUSED_REASON))
	return picker


## Ouvre le choix et attend : la place choisie, ou −1 (ANNULER).
func pick(view: PartyPickerView) -> int:
	open()
	_picker.speed_scale = speed_scale
	_picker.show_targets(view)
	var index: int = await _picked
	if _picker.is_shown():
		_picker.slide_out()
	close()
	return index


func is_picking() -> bool:
	return _picker != null and _picker.is_shown()


## Retour Android pendant le choix : renonce.
func handle_back() -> bool:
	if not is_picking():
		return false
	_picked.emit(-1)
	return true


func get_picker() -> PartyPicker:
	return _picker
