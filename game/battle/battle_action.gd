class_name BattleAction
extends RefCounted
## Le choix d'un camp pour un tour (jalon 4 §2.2). Donnée pure.
##
## MOVE au jalon 4 ; RUN (fuite) au jalon 5B (combat sauvage) ; ITEM (lancer une Ball) au
## jalon 5D ; SWITCH (équipe) viendra avec son jalon. Chaque sorte s'ajoute en fin d'enum pour
## ne rien décaler.

enum Kind { MOVE, RUN, ITEM }

## [member move_index] de Lutte (quand plus aucune capacité n'a de PP).
const STRUGGLE: int = -1

var kind: Kind = Kind.MOVE
## Emplacement de la capacité (0..3), ou [constant STRUGGLE].
var move_index: int = 0
## Objet utilisé (ITEM) : identifiant d'une Ball de l'[ItemLibrary].
var item_id: StringName = &""


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


## Action « lancer la Ball [param id] » (combat sauvage, légale seulement si les règles
## permettent les Balls et que [param id] est une Ball connue). Le Sac n'est pas vérifié ici.
static func ball(id: StringName) -> BattleAction:
	var action := BattleAction.new()
	action.kind = Kind.ITEM
	action.item_id = id
	return action
