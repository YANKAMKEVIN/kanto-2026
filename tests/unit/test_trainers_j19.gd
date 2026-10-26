extends GutTest
## Dresseurs de la Tour Pokémon (jalon 19 T4 ; `jalon-19.md` §2.5, §2.6, dossier 22 §7.3, §8) :
## les neuf Exorcistes et le rival n° 5 (`data/trainers/pokemon_tower.json`). Équipes du rival
## recalées par T21 (`docs/tech/jalon-19-equilibrage.md` §8) : règle de difficulté de Kevin
## (Q-T21-4), mesurée sur les sorties réelles du J18.

const SOURCE := "res://data/trainers/pokemon_tower.json"
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]

## Exorcistes (dossier 22 §8) : [nom, équipe [espèce, niveau]…, inévitable].
const CHANNELERS := {
	&"tower_channeler_1": ["Exorciste Hortense", [[&"gastly", 23]], false],
	&"tower_channeler_2": ["Exorciste Odile", [[&"gastly", 22]], false],
	&"tower_channeler_3": ["Exorciste Solange", [[&"gastly", 23], [&"gastly", 23]], true],
	&"tower_channeler_4": ["Exorciste Mireille", [[&"gastly", 24]], false],
	&"tower_channeler_5": ["Exorciste Bérénice", [[&"haunter", 23]], false],
	&"tower_channeler_6": ["Exorciste Marthe", [[&"gastly", 24]], false],
	&"tower_channeler_7": ["Exorciste Ysée", [[&"haunter", 22]], false],
	&"tower_channeler_8": ["Exorciste Paulette", [[&"gastly", 24]], true],
	&"tower_channeler_9": ["Exorciste Clémence", [[&"gastly", 24]], true],
}
## Rival n° 5 (dossier 22 §7.3, T21) : starter du joueur → [espèce, niveau]… Contre Bulbizarre,
## les niveaux descendent sous la fourchette 22–26 du plan [D] ; Léviator (RB) en 3e place :
## Kevin, Q26-4 (2026-10-22), retour à la lignée RB (la Sabelette du J19 est retirée) ;
## contre Carapuce, Roucoups et Caninos N21 [D].
const RIVAL := {
	&"bulbasaur": [[&"pidgeotto", 20], [&"exeggcute", 20], [&"gyarados", 20], [&"kadabra", 17],
		[&"charmeleon", 21]],
	&"charmander": [[&"pidgeotto", 22], [&"growlithe", 22], [&"exeggcute", 22],
		[&"kadabra", 20], [&"wartortle", 25]],
	&"squirtle": [[&"pidgeotto", 21], [&"gyarados", 25], [&"growlithe", 21], [&"kadabra", 18],
		[&"ivysaur", 26]],
}
## Garde-fous de plausibilité (T21, Kevin 2026-10-19) : le starter évolué du rival reste son
## Pokémon le plus haut, au plus ≈ 30 ; Kadabra ≤ 22 [D].
const RIVAL_STARTER_MAX := 30
const RIVAL_KADABRA_MAX := 22
const RIVAL_STARTERS: Array[StringName] = [&"ivysaur", &"charmeleon", &"wartortle"]

var _data: PokemonData
var _trainers: TrainerLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()


func test_ten_valid_trainers_in_the_tower_file() -> void:
	assert_eq(_trainers.get_errors().size(), 0, "\n".join(_trainers.get_errors()))
	var ids: Array[StringName] = []
	for id: StringName in _trainers.get_ids():
		if _trainers.get_trainer(id).source == SOURCE:
			ids.append(id)
	var expected: Array[StringName] = []
	expected.assign(CHANNELERS.keys())
	expected.append(&"rival_tower")
	ids.sort()
	expected.sort()
	assert_eq(ids, expected)


func test_channelers_teams_and_rules() -> void:
	for id: StringName in CHANNELERS:
		var row: Array = CHANNELERS[id]
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq([trainer.name, trainer.ai, trainer.can_lose, trainer.heal_after,
			trainer.gives_exp, trainer.can_switch, trainer.moment_on_win],
			[row[0], BattleAI.RANDOM, false, false, true, false, false], String(id))
		var team: Array = []
		for slot: TrainerSlot in trainer.team_for(&"charmander"):
			team.append([slot.species, slot.level])
			assert_true(slot.moves.is_empty(), "%s : capacités naturelles au niveau" % id)
		assert_eq(team, row[1], String(id))


func test_prize_is_30_times_the_last_level() -> void:
	for id: StringName in CHANNELERS:
		var trainer := _trainers.get_trainer(id)
		var last: int = (CHANNELERS[id][1] as Array).back()[1]
		assert_eq(trainer.prize_per_level, 30, String(id))
		assert_eq(trainer.prize_money, 0, String(id))
		assert_eq(trainer.prize_for(last), 30 * last, String(id))


func test_ghosts_know_lick_confuse_ray_and_night_shade() -> void:
	# Dossier 22 §8 : Hypnose arrive après ces niveaux (N27, N29).
	for id: StringName in CHANNELERS:
		var team := _trainers.build_team(id, &"bulbasaur", GameRng.new(1))
		for pokemon: Pokemon in team.get_all():
			var moves: Array = pokemon.moves.map(func(m: MoveSlot) -> StringName:
				return m.move_id)
			assert_eq(moves, [&"lick", &"confuse_ray", &"night_shade"], String(id))


func test_no_pending_effect_at_the_given_level() -> void:
	for id: StringName in [&"rival_tower"] + CHANNELERS.keys():
		for starter: StringName in STARTERS:
			var team := _trainers.build_team(id, starter, GameRng.new(1))
			for pokemon: Pokemon in team.get_all():
				for slot: MoveSlot in pokemon.moves:
					var move := _data.get_move(slot.move_id)
					assert_eq(move.pending_effects.size(), 0, "%s %s : %s" % [id,
						pokemon.species_id, slot.move_id])


func test_rival_follows_the_player_starter() -> void:
	var rival := _trainers.get_trainer(&"rival_tower")
	assert_not_null(rival)
	if rival == null:
		return
	for starter: StringName in STARTERS:
		var team: Array = []
		for slot: TrainerSlot in rival.team_for(starter):
			team.append([slot.species, slot.level])
			assert_ne(slot.species, &"raticate", "pas de Rattatac (dossier 06 §6)")
		assert_eq(team.size(), 5, String(starter))
		assert_eq(team, RIVAL[starter], String(starter))


func test_rival_starter_is_the_highest_and_plausible() -> void:
	var rival := _trainers.get_trainer(&"rival_tower")
	assert_not_null(rival)
	if rival == null:
		return
	for starter: StringName in STARTERS:
		var slots: Array = rival.team_for(starter)
		var last: TrainerSlot = slots.back()
		assert_true(RIVAL_STARTERS.has(last.species), "%s : starter évolué en dernier" % starter)
		assert_lte(last.level, RIVAL_STARTER_MAX, String(starter))
		for slot: TrainerSlot in slots:
			if slot == last:
				continue
			assert_lt(slot.level, last.level, "%s %s N%d" % [starter, slot.species, slot.level])
			if slot.species == &"kadabra":
				assert_lte(slot.level, RIVAL_KADABRA_MAX, String(starter))


func test_rival_rules_copy_the_third_rival() -> void:
	var rival := _trainers.get_trainer(&"rival_tower")
	var model := _trainers.get_trainer(&"rival_cerulean")
	assert_eq([rival.name, rival.ai, rival.can_lose, rival.heal_after, rival.gives_exp,
		rival.end_message, rival.start_message, rival.allow_bag, rival.can_switch,
		rival.moment_on_win],
		[model.name, model.ai, model.can_lose, model.heal_after, model.gives_exp,
		model.end_message, model.start_message, model.allow_bag, model.can_switch,
		model.moment_on_win])
	assert_true(rival.moment_on_win, "Grand moment à la victoire seulement")
	assert_eq(rival.prize_per_level, 35, "défaut : celui du n° 3 (plan §2.6)")


func test_rival_hand_picked_moves() -> void:
	# Plan §2.6 : Léviator sans Hydrocanon ; Hurlement de Caninos remplacé par Groz'Yeux ;
	# Tourbillon de Roucoups et Frénésie de Reptincel écartés. Kadabra : règle du J16 (Q-T21-3).
	# Contre Bulbizarre (Q-T21-1) : Roucoups sans Tornade.
	var common := {
		&"gyarados": [&"bite", &"dragon_rage", &"leer"],
		&"growlithe": [&"bite", &"ember", &"leer"],
		&"pidgeotto": [&"gust", &"sand_attack", &"quick_attack"],
		&"kadabra": [&"confusion", &"psybeam"],
		&"exeggcute": [&"barrage", &"hypnosis"],
		&"charmeleon": [&"scratch", &"growl", &"ember", &"leer"],
	}
	for starter: StringName in STARTERS:
		var expected := common.duplicate()
		if starter == &"bulbasaur":
			expected[&"pidgeotto"] = [&"sand_attack", &"quick_attack"]
		var team := _trainers.build_team(&"rival_tower", starter, GameRng.new(1))
		for pokemon: Pokemon in team.get_all():
			if not expected.has(pokemon.species_id):
				continue
			var moves: Array = pokemon.moves.map(func(m: MoveSlot) -> StringName:
				return m.move_id)
			assert_eq(moves, expected[pokemon.species_id], "%s %s" % [starter,
				pokemon.species_id])
