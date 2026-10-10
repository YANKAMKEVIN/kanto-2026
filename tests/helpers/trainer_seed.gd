extends RefCounted
## Graine d'une victoire contre un Dresseur, cherchée sur le moteur pur en reproduisant la
## consommation d'aléatoire du directeur de combat (équipe du Dresseur tirée d'abord, puis le
## combat ; [method BattleDirector.run]). Le joueur joue toujours la même capacité
## ([param move_index]) ; on ne garde qu'une victoire **sans K.O. du côté du joueur** (aucun
## choix de remplaçant à piloter). Modèle : test_forest_systems_together (J9).


## Première graine de [code]0..max_seed - 1[/code] qui donne cette victoire à une copie de
## [param party] (mêmes individus) contre [param trainer_id] ; −1 si aucune.
static func find(trainer_id: StringName, party: Party, starter: StringName,
		data: PokemonData, items: ItemLibrary, move_index: int, max_seed: int = 400) -> int:
	var library := TrainerLibrary.new(data)
	library.load_dir()
	var trainer := library.get_trainer(trainer_id)
	if trainer == null:
		return -1
	for seed: int in range(max_seed):
		var copy := Party.new()
		for pokemon: Pokemon in party.get_all():
			copy.add(Pokemon.from_dict(pokemon.to_dict(), data))
		var rng := GameRng.new(seed)
		var foes := library.build_team(trainer_id, starter, rng)
		var battle := Battle.new(BattleSide.new(copy, true),
			BattleSide.new(foes, false, trainer.name, trainer.make_ai()), data, rng,
			BattleRules.for_trainer(trainer, items))
		var events: Array[BattleEvent] = []
		events.append_array(battle.start())
		var turns := 0
		while battle.get_state() == Battle.State.CHOOSING and turns < 60:
			events.append_array(battle.submit(BattleAction.move(move_index)))
			turns += 1
		if battle.get_outcome() != Battle.Outcome.WIN:
			continue
		var player_fainted := events.any(func(e: BattleEvent) -> bool:
			return e.kind == BattleEvent.Kind.FAINTED and e.side == BattleEvent.SideId.PLAYER)
		if not player_fainted:
			return seed
	return -1
