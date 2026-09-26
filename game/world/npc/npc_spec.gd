class_name NpcSpec
extends RefCounted
## Description d'un PNJ ou d'un Pokémon du décor sur une carte, lue dans
## `data/npcs/<map_id>.json` par [NpcRoster] (docs/tech/jalon-03.md §2.3).
##
## Donnée pure : la scène `Npc` s'en sert pour se placer, s'afficher et répondre au joueur.
## En lecture seule une fois construite : un PNJ qui marche (jalon 3B) garde sa case courante
## dans son GridMover, [member cell] reste sa case de départ.

## Identifiant unique sur la carte (cible des indications « react » des dialogues).
var id: StringName = &""
var cell: Vector2i = Vector2i.ZERO
## Orientation au repos (celle qu'il reprend après un dialogue, voir [member keep_facing]).
var facing: Vector2i = Vector2i.DOWN
## Nom de l'apparence : la scène `Npc` charge les SpriteFrames `<sprite>_frames.tres`.
var sprite: StringName = &""
## Dialogue joué quand on interagit ; vide = pas d'interaction (Roucool de Mme Aoki).
var dialogue: StringName = &""
## Verbe du bouton contextuel ([enum Interaction.Kind]) : parler (défaut) ou observer.
var verb: Interaction.Kind = Interaction.Kind.TALK
## Se tourne vers le joueur dès qu'on lui parle (faux : seulement sur une page face_player).
var turn_to_player: bool = true
## Garde l'orientation prise pendant le dialogue au lieu de reprendre [member facing].
var keep_facing: bool = false
## Élévation du sprite en pixels (Pokémon posé sur une table) ; la case et le tri en
## profondeur ne changent pas.
var lift: int = 0
## Présence conditionnelle (docs/tech/jalon-03b.md §2.6) : présent si tous les drapeaux de
## [member if_flags] sont levés et aucun de [member unless_flags], comme une variante de
## dialogue. Sans condition, toujours présent.
var if_flags: Array[StringName] = []
var unless_flags: Array[StringName] = []


## Vrai si l'on peut interagir avec lui (un dialogue est renseigné).
func is_interactive() -> bool:
	return not dialogue.is_empty()


## Vrai si le PNJ est sur la carte avec les drapeaux [param flags] (null = nouvelle partie,
## aucun drapeau levé).
func is_present(flags: StoryFlags) -> bool:
	if flags == null:
		return if_flags.is_empty()
	return flags.has_all(if_flags) and flags.has_none(unless_flags)


## Vrai si la présence dépend d'au moins un drapeau.
func is_conditional() -> bool:
	return not if_flags.is_empty() or not unless_flags.is_empty()


## Interaction correspondante sur [param at_cell] (source = [param source]), ou null.
func make_interaction(at_cell: Vector2i, source: Object) -> Interaction:
	if not is_interactive():
		return null
	return Interaction.new(verb, at_cell, dialogue, Vector2i.ZERO, source)
