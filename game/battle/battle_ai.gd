class_name BattleAI
extends RefCounted
## Choix d'action des camps non joueurs (jalon 4 §2.2, dossier 05 §19). Classe pure.
##
## Une seule IA au jalon 4, [code]random[/code] : une capacité au hasard parmi celles qui
## ont des PP (un tirage pick_index), Lutte sinon (aucun tirage). Le rival débutant « fait
## des erreurs » ; l'IA qui « te connaît » s'ajoutera à côté, par son nom.

const RANDOM: StringName = &"random"
## Noms d'IA reconnus dans les données des dresseurs.
const KINDS: Array[StringName] = [RANDOM]

var kind: StringName = RANDOM


func _init(ai_kind: StringName = RANDOM) -> void:
	kind = ai_kind


static func is_known(ai_kind: StringName) -> bool:
	return KINDS.has(ai_kind)


## Action du camp [param own] contre [param _foe].
func choose(own: BattleSide, _foe: BattleSide, rng: GameRng) -> BattleAction:
	var usable := own.active.usable_moves()
	if usable.is_empty():
		return BattleAction.move(BattleAction.STRUGGLE)
	return BattleAction.move(usable[rng.pick_index(usable.size())])
