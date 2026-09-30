class_name BattleAction
extends RefCounted
## Le choix d'un camp pour un tour (jalon 4 §2.2). Donnée pure.
##
## MOVE au jalon 4 ; RUN (fuite) s'ajoute au jalon 5 (combat sauvage) ; SWITCH (équipe) et
## ITEM (sac, capture) viendront avec leurs jalons. RUN est en fin d'enum pour ne rien décaler.

enum Kind { MOVE, RUN }

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


## Action « prendre la fuite » (combat sauvage, légale seulement si les règles l'autorisent).
static func run() -> BattleAction:
	var action := BattleAction.new()
	action.kind = Kind.RUN
	return action
