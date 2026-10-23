class_name PropActor
extends Node2D
## Acteur de décor (jalon 21, `jalon-21.md` §2.3, T19) : un élément peint de la carte (le sprite
## de Ronflex) que les étapes de scène « react » et « emote », et la page « react » d'un
## dialogue, peuvent animer comme un PNJ, sans en être un (ni case, ni dialogue, ni routine).
##
## Présentation pure. Le nœud entre dans le groupe [constant GROUP] dès sa création (y compris
## hors de l'arbre : les tests de données le trouvent dans la scène de la carte) ; son **nom**
## est l'identifiant utilisé par les scènes ([method GameMap.get_scene_prop]).
## - [method react] : petit saut (un [Tween]) de l'enfant « Sprite » s'il existe, sinon du nœud ;
## - [method show_emote] : bulle [EmoteBubble] au-dessus, à [member emote_height] px des pieds ;
##   [signal emote_finished] à la fin.

## Fin de la bulle de [method show_emote].
signal emote_finished

## Groupe des acteurs de décor (lu par [method GameMap.get_scene_prop]).
const GROUP: StringName = &"scene_props"
## Bulles des étapes « emote » ([constant CutsceneStep.EMOTE_KINDS]) → icônes de [EmoteBubble].
const EMOTE_ICONS: Dictionary[StringName, StringName] = {
	&"exclamation": EmoteBubble.EXCLAIM,
}

## Petit saut de [method react] : hauteur (px) et durée totale (s) [D : ceux d'un PNJ].
@export var hop_height: float = 12.0
@export var hop_duration: float = 0.25
## Hauteur de la pointe de la bulle au-dessus de l'origine (px) ; par défaut celle d'un
## personnage ([constant UiTokens.EMOTE_TIP_HEIGHT]) : plus haut pour un grand sprite.
@export var emote_height: float = UiTokens.EMOTE_TIP_HEIGHT

var _hop: Tween
var _bubble: EmoteBubble


func _init() -> void:
	add_to_group(GROUP)


## Petit saut de surprise, sans attendre (la position de repos est rendue à la fin).
func react() -> void:
	if not is_inside_tree():
		return
	var target := _hop_target()
	var rest := target.position.y
	if _hop != null and _hop.is_valid():
		_hop.kill()
		rest = float(target.get_meta(&"prop_rest_y", rest))
	target.set_meta(&"prop_rest_y", rest)
	target.position.y = rest
	_hop = create_tween()
	_hop.tween_property(target, ^"position:y", rest - hop_height, hop_duration / 2.0) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop.tween_property(target, ^"position:y", rest, hop_duration / 2.0) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Vrai pendant le saut de [method react].
func is_reacting() -> bool:
	return _hop != null and _hop.is_valid() and _hop.is_running()


## Bulle [param kind] (« exclamation » d'une étape « emote », ou une icône d'[EmoteBubble])
## au-dessus du décor ; [signal emote_finished] à la fin. Hors de l'arbre : finie tout de suite.
func show_emote(kind: StringName) -> void:
	if _bubble == null or not is_instance_valid(_bubble):
		_bubble = EmoteBubble.new()
		_bubble.name = "PropEmote"
		_bubble.finished.connect(_on_bubble_finished)
		add_child(_bubble)
	_bubble.tip_height = emote_height
	_bubble.play(EMOTE_ICONS.get(kind, kind))


## Vrai pendant une bulle ([method show_emote]).
func is_emoting() -> bool:
	return _bubble != null and is_instance_valid(_bubble) and _bubble.is_playing()


func _hop_target() -> Node2D:
	var sprite := get_node_or_null(^"Sprite") as Node2D
	return sprite if sprite != null else self


func _on_bubble_finished() -> void:
	emote_finished.emit()
