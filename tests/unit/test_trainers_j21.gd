extends GutTest
## Dresseurs du jalon 21 (T5 ; docs/tech/jalon-21.md §2.8, §2.11) : 3 Sbires Rocket du 7F de la
## Tour (RB, parties.asm « Pokémon Tower 7F ») et 4 Pêcheurs de la Route 12 nord (RB, Pêcheurs
## n° 3 à 6 de « Route 12 »). Prénoms des Pêcheurs : annexe A (brouillon, à valider).
##
## Dépend du J17 (Soporifik, Coup d'Boule, Hypnose) : ne passe qu'après la fusion de main (T9).

## Identifiant → [nom, IA, équipe [espèce, niveau]…, récompense pour le dernier niveau].
const TRAINERS := {
	&"tower_rocket_1": ["Sbire Rocket", BattleAI.RANDOM,
		[[&"zubat", 25], [&"zubat", 25], [&"golbat", 25]], 750],
	&"tower_rocket_2": ["Sbire Rocket", BattleAI.RANDOM,
		[[&"koffing", 26], [&"drowzee", 26]], 780],
	&"tower_rocket_3": ["Sbire Rocket", BattleAI.SMART,
		[[&"zubat", 23], [&"rattata", 23], [&"raticate", 23], [&"zubat", 23]], 690],
	&"route_12_fisher_1": ["Pêcheur Ned", BattleAI.RANDOM,
		[[&"goldeen", 22], [&"poliwag", 22], [&"goldeen", 22]], 35 * 22],
	&"route_12_fisher_2": ["Pêcheur Elton", BattleAI.RANDOM,
		[[&"tentacool", 24], [&"goldeen", 24]], 35 * 24],
	&"route_12_fisher_3": ["Pêcheur Bastien", BattleAI.RANDOM, [[&"goldeen", 27]], 35 * 27],
	&"route_12_fisher_4": ["Pêcheur Hervé", BattleAI.RANDOM,
		[[&"poliwag", 21], [&"shellder", 21], [&"goldeen", 21], [&"horsea", 21]], 35 * 21],
}

var _data: PokemonData
var _trainers: TrainerLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()


func test_library_loads_without_error() -> void:
	assert_eq(_trainers.get_errors(), PackedStringArray())


func test_seven_trainers_with_red_blue_teams() -> void:
	for id: StringName in TRAINERS:
		var row: Array = TRAINERS[id]
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq([trainer.name, trainer.ai], [row[0], row[1]], String(id))
		assert_eq([trainer.can_lose, trainer.heal_after, trainer.gives_exp], [false, false, true])
		var team: Array = []
		for slot: TrainerSlot in trainer.team_for(&""):
			team.append([slot.species, slot.level])
		assert_eq(team, row[2], String(id))
		var last_level: int = row[2][-1][1]
		assert_eq(trainer.prize_for(last_level), row[3], "%s : récompense" % id)


func test_sources() -> void:
	for id: StringName in TRAINERS:
		var trainer := _trainers.get_trainer(id)
		if trainer == null:
			continue
		var file := "pokemon_tower_7f" if String(id).begins_with("tower_") else "route_12"
		assert_eq(trainer.source, "res://data/trainers/%s.json" % file)


func test_moves_at_level_have_no_pending_effect() -> void:
	for id: StringName in TRAINERS:
		var team := _trainers.build_team(id, &"bulbasaur", GameRng.new(21))
		assert_eq(team.size(), (TRAINERS[id][2] as Array).size(), String(id))
		for pokemon: Pokemon in team.get_all():
			for slot: MoveSlot in pokemon.moves:
				var move := _data.get_move(slot.move_id)
				assert_not_null(move, "%s : %s" % [id, slot.move_id])
				if move != null:
					assert_eq(move.pending_effects.size(), 0,
						"%s : %s (%s) sans effet en attente" % [id, slot.move_id,
							pokemon.species_id])
