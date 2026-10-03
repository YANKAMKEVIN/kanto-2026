extends Control
## Choix du Pokémon factice pour les tests du combat (jalon-06.md §6.8) : mêmes signaux et
## méthodes que le `PartyPicker` du T11, sans rendu. Sert tant que le vrai composant n'est pas
## livré, et garde les tests du BattleDirector indépendants de l'interface.

signal target_chosen(index: int)
signal back_requested

var speed_scale: float = 1.0
var haptics_enabled: bool = true
var last_view: PartyPickerView
var shown: bool = false


## Scène à glisser dans [code]BattleDirector.party_picker_scene[/code].
static func make_scene() -> PackedScene:
	var node := Control.new()
	node.set_script(load("res://tests/helpers/fake_party_picker.gd"))
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	return scene


func show_targets(view: PartyPickerView) -> void:
	last_view = view


func slide_in() -> void:
	shown = true


func slide_out() -> void:
	shown = false


func is_sliding() -> bool:
	return false
