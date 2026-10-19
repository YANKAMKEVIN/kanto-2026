class_name PokeFluteRules
extends RefCounted
## Règles de la Poké Flûte (jalon 21 §2.2, §2.4 ; dossier 24 §8) : classe statique et pure.
##
## - Exploration : la Flûte réveille un dormeur ([FluteTarget]) si le joueur se tient sur l'une
##   des 4 cases voisines de l'une de ses cases ; sinon, elle joue « ailleurs », sans effet.
## - Combat : elle réveille **tous** les Pokémon endormis non K.O. des deux camps (RB : toute
##   l'équipe adverse d'un Dresseur). Le réveil est [method Pokemon.cure_status] (statut et
##   compteur à 0, y compris le sommeil de Repos) ; rien d'autre ne change (PV, autres statuts,
##   confusion et stades, qui vivent dans [Battler]). Aucun tirage.


## Scène de réveil si [param cell] touche (4 voisins) un dormeur encore présent ; &"" sinon.
## Plusieurs dormeurs voisins : le premier de [param targets] (les cartes n'en posent qu'un).
static func field_target(targets: Array[FluteTarget], cell: Vector2i,
		flags: StoryFlags) -> StringName:
	for target: FluteTarget in targets:
		if target == null or target.cutscene_id.is_empty():
			continue
		if target.is_present(flags) and target.touches(cell):
			return target.cutscene_id
	return &""


## Pokémon endormis (non K.O.) des deux équipes, dans l'ordre : joueur, puis adversaire.
## Une équipe nulle est ignorée.
static func sleepers(player: Party, foe: Party) -> Array[Pokemon]:
	var result: Array[Pokemon] = []
	for party: Party in [player, foe]:
		if party == null:
			continue
		for pokemon: Pokemon in party.get_all():
			if is_sleeper(pokemon):
				result.append(pokemon)
	return result


## Vrai si [param pokemon] dort et n'est pas K.O.
static func is_sleeper(pokemon: Pokemon) -> bool:
	return pokemon != null and not pokemon.is_fainted() \
			and pokemon.has_status(StatusRules.SLEEP)


## Réveille chaque Pokémon endormi de [param pokemons] ([method Pokemon.cure_status]) ; rend ceux
## qui dormaient, dans l'ordre. Les autres (éveillés, autre statut, K.O.) ne changent pas.
static func wake_all(pokemons: Array[Pokemon]) -> Array[Pokemon]:
	var woken: Array[Pokemon] = []
	for pokemon: Pokemon in pokemons:
		if is_sleeper(pokemon):
			pokemon.cure_status()
			woken.append(pokemon)
	return woken
