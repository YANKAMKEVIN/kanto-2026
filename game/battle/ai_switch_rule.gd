class_name AiSwitchRule
extends RefCounted
## Changement de Pokémon de l'IA (dossier 16 §14, D-7 ; jalon-13.md §2.11). Classe pure,
## statique et déterministe : aucun tirage. Au plus un changement par combat : le compte est
## tenu par [BattleAI] ; ici, seulement « faut-il changer maintenant, et pour qui ? ».
##
## - [b]Faiblesse[/b] : au moins un type du Pokémon du joueur a un multiplicateur ≥ ×2 contre
##   les types du Pokémon considéré (×4 compris). L'IA lit les types, pas les capacités du joueur.
## - [b]En danger[/b] : PV ≤ 25 % des PV max (25 % pile = danger), ou faiblesse.
## - [b]Meilleure posture[/b] : ni K.O. ni en jeu, PV > 50 % (50 % pile = non), aucune faiblesse.
##   Plusieurs candidats : le premier dans l'ordre de l'équipe.
## - [b]Jamais[/b] : Pokémon actif K.O. ou en tour forcé ([method Battler.is_locked] : Patience,
##   piège quand il existera), ou aucun candidat.

const DANGER_HP_RATIO: float = 0.25
const SAFE_HP_RATIO: float = 0.5
const WEAK_MULTIPLIER: float = 2.0
## Réponse de [method pick] : rester.
const STAY: int = -1


## Place dans l'équipe de [param own] du Pokémon à envoyer contre [param foe] (le Pokémon du
## joueur en jeu), ou [constant STAY].
static func pick(own: BattleSide, foe: Battler, chart: TypeChart, data: PokemonData) -> int:
	if own == null or own.active == null or foe == null or chart == null or data == null:
		return STAY
	var active := own.active
	if active.pokemon.is_fainted() or active.is_locked():
		return STAY
	if not is_in_danger(active, foe, chart):
		return STAY
	for i: int in own.party.size():
		var pokemon := own.party.get_at(i)
		if pokemon == active.pokemon:
			continue
		if is_better_placed(pokemon, foe, chart, data):
			return i
	return STAY


## Vrai si [param active] est en danger face à [param foe] : PV ≤ 25 % ou faiblesse.
static func is_in_danger(active: Battler, foe: Battler, chart: TypeChart) -> bool:
	var max_hp := active.pokemon.max_hp()
	if max_hp > 0 and float(active.pokemon.hp) <= max_hp * DANGER_HP_RATIO:
		return true
	return is_weak_to(active.types, foe, chart)


## Vrai si un type de [param foe] frappe [param defender_types] à ×2 ou plus.
static func is_weak_to(defender_types: Array[StringName], foe: Battler, chart: TypeChart) -> bool:
	for attack_type: StringName in foe.types:
		if chart.multiplier(attack_type, defender_types) >= WEAK_MULTIPLIER:
			return true
	return false


## Vrai si [param pokemon] (hors du terrain) est en meilleure posture face à [param foe] :
## debout, PV > 50 %, aucune faiblesse.
static func is_better_placed(pokemon: Pokemon, foe: Battler, chart: TypeChart,
		data: PokemonData) -> bool:
	if pokemon == null or pokemon.is_fainted():
		return false
	if float(pokemon.hp) <= pokemon.max_hp() * SAFE_HP_RATIO:
		return false
	var species := data.get_species(pokemon.species_id)
	if species == null:
		return false
	return not is_weak_to(species.types, foe, chart)
