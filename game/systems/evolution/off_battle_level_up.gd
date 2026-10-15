class_name OffBattleLevelUp
extends RefCounted
## Séquence « hors combat » après un gain de niveaux (J15, jalon-15.md §2.5.4) : **chaque
## capacité due, dans l'ordre**, avec le déroulé partagé « veut apprendre… oublier ? »
## ([MoveLearnPrompt] : refuser = non apprise, jamais d'oubli automatique), **puis l'évolution
## proposée** par l'écran d'évolution existant ([EvolutionDirector] : annulable, ARRÊTER ou retour
## Android ; une évolution annulée revient au prochain niveau gagné).
##
## Écrite une seule fois pour la Pension (J15, retrait) et le **Super Bonbon du J14** (un niveau :
## `LevelUp.moves` et `Evolution.level_up_target`). Coroutines statiques, sans écran propre :
## l'appelant fournit le bandeau et l'hôte des panneaux (voile de `TmLearnOverlay` ou de son
## héritier) et les ouvre / ferme autour de [method teach_moves] ; l'écran d'évolution a son propre
## calque, au-dessus.
##
## Sans écran (tests, outils) : [param banner] nul → une capacité est apprise s'il reste une place,
## sinon rien ne change (aucun choix à la place du joueur) ; un [EvolutionDirector] sans écran
## applique l'évolution tout de suite.


## Coroutine : les deux étapes, dans l'ordre. Renvoie vrai si le Pokémon a évolué.
static func play(pokemon: Pokemon, index: int, moves: Array[StringName], evolution: StringName,
		learn: MoveLearnPrompt, banner: BattleMessageBanner, host: Control,
		evolutions: EvolutionDirector, party: Party, data: PokemonData) -> bool:
	await teach_moves(pokemon, index, moves, learn, banner, host, data)
	return await offer_evolution(pokemon, index, evolution, evolutions, party)


## Coroutine : propose [param moves] à [param pokemon] (place [param index] de l'équipe), une par
## une, dans l'ordre. Renvoie les capacités réellement apprises. Le panneau d'oubli reste à
## libérer par l'appelant ([method MoveLearnPrompt.release]).
static func teach_moves(pokemon: Pokemon, index: int, moves: Array[StringName],
		learn: MoveLearnPrompt, banner: BattleMessageBanner, host: Control,
		data: PokemonData) -> Array[StringName]:
	var learned: Array[StringName] = []
	if pokemon == null:
		return learned
	for move_id: StringName in moves:
		var ok := false
		if learn != null and is_instance_valid(banner):
			ok = await learn.teach(pokemon, index, move_id, banner, host)
		elif data != null:
			ok = pokemon.learn_move(move_id, data) == Pokemon.LearnResult.LEARNED
		if ok:
			learned.append(move_id)
	return learned


## Coroutine : propose l'évolution de [param pokemon] vers [param into] (rien si vide). Vrai si
## elle a eu lieu (non annulée).
static func offer_evolution(pokemon: Pokemon, index: int, into: StringName,
		evolutions: EvolutionDirector, party: Party) -> bool:
	if pokemon == null or into.is_empty() or evolutions == null or party == null:
		return false
	var candidates: Array[EvolutionCandidate] = [
		EvolutionCandidate.new(index, pokemon.species_id, into),
	]
	await evolutions.play(candidates, party)
	return pokemon.species_id == into
