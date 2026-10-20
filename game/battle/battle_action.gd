class_name BattleAction
extends RefCounted
## Le choix d'un camp pour un tour (jalon 4 §2.2). Donnée pure.
##
## MOVE au jalon 4 ; RUN (fuite) au jalon 5B (combat sauvage) ; ITEM (lancer une Ball) au
## jalon 5D, et donner un soin à un Pokémon de l'équipe au jalon 6 ([member target] ≥ 0) ;
## SWITCH (changer de Pokémon, ÉQUIPE) au jalon 7 ([member target] : le Pokémon envoyé).
## SPEAK (jalon 19) : le SPECTRE parle, rien d'autre ; imposée par le moteur au camp adverse
## d'un combat SPECTRE (ni IA ni tirage), jamais légale pour le joueur.
## Jalon 20 : ITEM sans cible pour un objet COMBAT ([method use_item] : objets X, Muscle +,
## Poupée Poké), joué sur le Pokémon actif ; le Rappel est un soin ([method heal]) donné à un
## Pokémon K.O.
## Passe systèmes 2 (`systemes-2.md` §2.4) : KEY_ITEM, jouer d'un objet clé (la Poké Flûte),
## sans cible et sans rien consommer ([method key_item]).
## Chaque sorte s'ajoute en fin d'enum pour ne rien décaler.

enum Kind { MOVE, RUN, ITEM, SWITCH, SPEAK, KEY_ITEM }

## [member move_index] de Lutte (quand plus aucune capacité n'a de PP).
const STRUGGLE: int = -1

var kind: Kind = Kind.MOVE
## Emplacement de la capacité (0..3), ou [constant STRUGGLE].
var move_index: int = 0
## Objet utilisé (ITEM) : identifiant d'une Ball ou d'un soin de l'[ItemLibrary].
var item_id: StringName = &""
## ITEM : place du Pokémon soigné dans l'équipe du joueur (0 = en tête) ; −1 pour une Ball.
## SWITCH : place du Pokémon envoyé dans l'équipe du joueur.
var target: int = -1


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


## Action « utiliser l'objet de combat [param id] » (jalon 20 : objet X, Muscle +, Poupée
## Poké), comme une Ball : sans cible, joué avant les capacités. Légale seulement si
## [method Battle.is_legal] l'accepte ; le Sac n'est pas vérifié ici.
static func use_item(id: StringName) -> BattleAction:
	var action := BattleAction.new()
	action.kind = Kind.ITEM
	action.item_id = id
	return action


## Action « donner le soin [param id] au Pokémon [param party_index] de l'équipe » (jalon 6,
## Q-10 : n'importe quel membre, l'action prend le tour). Légale seulement si les règles
## permettent les soins et si [method ItemUse.check_target] l'accepte. Le Sac n'est pas vérifié
## ici (le directeur retire l'objet).
static func heal(id: StringName, party_index: int) -> BattleAction:
	var action := BattleAction.new()
	action.kind = Kind.ITEM
	action.item_id = id
	action.target = party_index
	return action


## Action « rappeler le Pokémon en jeu et envoyer le Pokémon [param party_index] de l'équipe »
## (jalon 7). Légale seulement si [method Battle.check_switch] l'accepte (ni le Pokémon actif,
## ni un K.O.).
static func switch_to(party_index: int) -> BattleAction:
	var action := BattleAction.new()
	action.kind = Kind.SWITCH
	action.target = party_index
	return action


## Action « le SPECTRE parle » (combat SPECTRE, jalon 19) : imposée par le moteur.
static func speak() -> BattleAction:
	var action := BattleAction.new()
	action.kind = Kind.SPEAK
	return action


## Action « jouer de l'objet clé [param id] » (passe systèmes 2 : la Poké Flûte). Légale
## seulement si [method Battle.is_legal] l'accepte (un Pokémon dort) ; jamais retirée du Sac.
static func key_item(id: StringName) -> BattleAction:
	var action := BattleAction.new()
	action.kind = Kind.KEY_ITEM
	action.item_id = id
	return action


## Vrai pour une action de soin (ITEM avec une cible), faux pour une Ball ou un objet de combat.
func is_heal() -> bool:
	return kind == Kind.ITEM and target >= 0
