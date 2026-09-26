class_name BattleAction
extends RefCounted
## Le choix d'un camp pour un tour (jalon 4 §2.2). Donnée pure.
##
## Une seule sorte au jalon 4 ; SWITCH (équipe), ITEM (sac, capture) et RUN (fuite)
## viendront avec leurs jalons.

enum Kind { MOVE }

## [member move_index] de Lutte (quand plus aucune capacité n'a de PP).
const STRUGGLE: int = -1

var kind: Kind = Kind.MOVE
## Emplacement de la capacité (0..3), ou [constant STRUGGLE].
var move_index: int = 0


## Action « utiliser la capacité [param index] ».
static func move(index: int) -> BattleAction:
	var action := BattleAction.new()
	action.kind = Kind.MOVE
	action.move_index = index
	return action
