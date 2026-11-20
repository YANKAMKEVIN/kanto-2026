class_name PartyPipTracker
extends RefCounted
## État des pastilles d'équipe pendant un combat ([PartyPips]) : en forme, sous statut, K.O.
## Classe pure.
##
## La présentation n'interroge jamais le moteur pendant qu'elle joue : l'état de départ est lu
## dans les équipes avant le premier événement ([method reset]), puis chaque événement joué le
## met à jour ([method apply]). Une pastille ne change donc qu'au moment où l'écran le raconte
## (le K.O. après la chute du Pokémon, le statut avec son étiquette).

var _states: Dictionary[BattleEvent.SideId, Array] = {}


## États de [param party] tels qu'ils sont maintenant, dans l'ordre de l'équipe (vide sans
## équipe). Un œuf est une Poké Ball en forme.
static func states_of(party: Party) -> Array[PartyPips.State]:
	var states: Array[PartyPips.State] = []
	if party == null:
		return states
	for pokemon: Pokemon in party.get_all():
		states.append(state_of(pokemon))
	return states


static func state_of(pokemon: Pokemon) -> PartyPips.State:
	if pokemon.is_egg():
		return PartyPips.State.READY
	if pokemon.is_fainted():
		return PartyPips.State.FAINTED
	if pokemon.status != StatusRules.NONE:
		return PartyPips.State.STATUS
	return PartyPips.State.READY


## Début d'un combat : les deux équipes telles qu'elles entrent. [param foe] null (Pokémon
## sauvage) : aucune pastille adverse.
func reset(player: Party, foe: Party) -> void:
	_states[BattleEvent.SideId.PLAYER] = states_of(player)
	_states[BattleEvent.SideId.FOE] = states_of(foe)


## États du camp [param side], dans l'ordre de son équipe (copie).
func states(side: BattleEvent.SideId) -> Array[PartyPips.State]:
	var result: Array[PartyPips.State] = []
	result.assign(_states.get(side, []))
	return result


## Prend en compte [param event] une fois joué. Vrai si une pastille a changé.
func apply(event: BattleEvent) -> bool:
	if event == null or event.party_index < 0:
		return false
	var side: Array = _states.get(event.side, [])
	if event.party_index >= side.size():
		return false
	var before: PartyPips.State = side[event.party_index]
	var after := before
	match event.kind:
		BattleEvent.Kind.FAINTED:
			after = PartyPips.State.FAINTED
		BattleEvent.Kind.REVIVED:
			after = PartyPips.State.READY
		BattleEvent.Kind.STATUS_INFLICTED, BattleEvent.Kind.RESTED:
			if event.status != StatusRules.NONE and before != PartyPips.State.FAINTED:
				after = PartyPips.State.STATUS
		BattleEvent.Kind.STATUS_CURED, BattleEvent.Kind.STATUS_ENDED, \
				BattleEvent.Kind.FLUTE_WOKE:
			# Le statut porté par l'événement est celui qui vient de finir.
			if before == PartyPips.State.STATUS:
				after = PartyPips.State.READY
		BattleEvent.Kind.SENT_OUT:
			after = PartyPips.State.STATUS if event.status != StatusRules.NONE \
				else PartyPips.State.READY
	if after == before:
		return false
	side[event.party_index] = after
	return true
