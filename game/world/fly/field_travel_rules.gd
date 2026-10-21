class_name FieldTravelRules
extends RefCounted
## Téléport et Tunnel hors combat (passe systèmes 2, `docs/tech/systemes-2.md` §3.6 T25b, Q-5) :
## pur, sans nœud. Lancés depuis la fiche d'un Pokémon de l'Équipe qui connaît la capacité
## (`FieldMoves`, `"hm": ""` : ni CS, ni badge).
##
## - **Téléport** (`teleport`) : retour au dernier point de soin (`heal_map` / `heal_spawn`, le
##   point du réveil après une défaite), **sans soin**. Permis en extérieur et en grotte, refusé
##   en intérieur [D] et sur une carte [member MapTraits.no_teleport] (Parc Safari, J23).
## - **Tunnel** (`dig`) : sortie de grotte, exactement la destination de la Corde Sortie
##   ([method FieldItemRules.escape_target]), sans objet consommé ; refusé hors grotte.

enum Check {
	OK,
	BUSY, ## Le joueur n'est pas libre (dialogue, scène, voyage en cours…).
	NO_POKEMON, ## Aucun Pokémon de l'équipe ne connaît la capacité.
	NOT_HERE, ## Pas ici : intérieur ou carte interdite (Téléport), hors grotte (Tunnel).
	UNKNOWN_MOVE, ## Ni Téléport ni Tunnel.
}

const TELEPORT: StringName = &"teleport"
const DIG: StringName = &"dig"
## Les capacités de voyage hors combat, dans l'ordre.
const MOVES: Array[StringName] = [TELEPORT, DIG]


## Vrai si [param move] est une capacité de voyage hors combat.
static func is_travel_move(move: StringName) -> bool:
	return MOVES.has(move)


## Téléport d'ici ? [param heal_map] : la carte du dernier point de soin (vide : aucun, refus).
static func check_teleport(field_state: FieldMoves.State, map: MapTraits, heal_map: StringName,
		busy: bool = false) -> Check:
	if busy:
		return Check.BUSY
	if field_state != FieldMoves.State.READY:
		return Check.NO_POKEMON
	if map == null or map.interior or map.no_teleport or heal_map.is_empty():
		return Check.NOT_HERE
	return Check.OK


## Tunnel d'ici ? [param exit] : la sortie de la grotte ([method FieldItemRules.escape_target],
## null hors grotte).
static func check_dig(field_state: FieldMoves.State, exit: CaveExit, busy: bool = false) -> Check:
	if busy:
		return Check.BUSY
	if field_state != FieldMoves.State.READY:
		return Check.NO_POKEMON
	if exit == null:
		return Check.NOT_HERE
	return Check.OK
