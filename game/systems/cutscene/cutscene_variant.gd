class_name CutsceneVariant
extends RefCounted
## Une version d'une scène : ses étapes et les drapeaux qui la conditionnent, comme une
## [DialogueVariant] (docs/tech/jalon-03b.md §2.3).
##
## Elle s'applique si tous les drapeaux de [member if_flags] sont levés et aucun de
## [member unless_flags]. Une même case de déclencheur joue ainsi l'interception de Chen la
## première fois, puis la pensée du joueur tant qu'il n'a pas de Pokémon.

var if_flags: Array[StringName] = []
var unless_flags: Array[StringName] = []
## Jalon 21 (`jalon-21.md` §2.3) : objets qui doivent tous être dans le Sac (« if_items ») ou
## dont aucun ne doit y être (« unless_items »), comme les variantes de dialogue du J20.
var if_items: Array[StringName] = []
var unless_items: Array[StringName] = []
var steps: Array[CutsceneStep] = []


## Vrai si la variante s'applique avec les drapeaux [param flags] (null = aucun drapeau) et le
## Sac [param bag] (jalon 21 ; null = aucun Sac : une variante qui demande un objet ne
## s'applique pas, « unless_items » seul est vrai).
func matches(flags: StoryFlags, bag: Bag = null) -> bool:
	if flags == null:
		if not if_flags.is_empty():
			return false
	elif not (flags.has_all(if_flags) and flags.has_none(unless_flags)):
		return false
	return items_match(bag)


## Jalon 21 : « if_items » / « unless_items » lus dans [param bag] (sémantique de
## [method Dialogue._items_match]).
func items_match(bag: Bag) -> bool:
	if if_items.is_empty() and unless_items.is_empty():
		return true
	if bag == null:
		return if_items.is_empty()
	for id: StringName in if_items:
		if not bag.has(id):
			return false
	for id: StringName in unless_items:
		if bag.has(id):
			return false
	return true
