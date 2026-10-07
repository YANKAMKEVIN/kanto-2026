extends GutTest
## BattleAI « random » : une capacité au hasard parmi celles qui ont des PP, Lutte sinon.
## BattleAI « smart » (jalon-07.md §3.8, dossier 09 §14) : chaque règle seule, sur des camps
## construits à la main (capacités et types imposés).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]

var _data: PokemonData
var _side: BattleSide


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"charmander", 30, ScriptedRng.new(IV_0)))
	_side = BattleSide.new(party, false, "", BattleAI.new())
	_side.send_out(party.get_lead(), _data)


func test_known_kinds() -> void:
	assert_true(BattleAI.is_known(&"random"))
	assert_true(BattleAI.is_known(&"smart"))
	assert_false(BattleAI.is_known(&"genius"))
	assert_eq(BattleAI.new().kind, &"random")
	assert_eq(BattleAI.new(BattleAI.SMART).kind, &"smart")


func test_picks_among_usable_moves() -> void:
	var ai := BattleAI.new()
	assert_eq(ai.choose(_side, null, ScriptedRng.new([1])).move_index, 0)
	assert_eq(ai.choose(_side, null, ScriptedRng.new([4])).move_index, 3)
	_side.active.pokemon.moves[0].pp = 0
	_side.active.pokemon.moves[2].pp = 0
	assert_eq(ai.choose(_side, null, ScriptedRng.new([1])).move_index, 1)
	assert_eq(ai.choose(_side, null, ScriptedRng.new([2])).move_index, 3)


func test_struggles_without_pp_and_without_drawing() -> void:
	for slot: MoveSlot in _side.active.pokemon.moves:
		slot.pp = 0
	var rng := ScriptedRng.new([])
	var action := BattleAI.new().choose(_side, null, rng)
	assert_eq(action.kind, BattleAction.Kind.MOVE)
	assert_eq(action.move_index, BattleAction.STRUGGLE)
	assert_eq(rng.calls, 0)


func test_every_usable_move_gets_chosen() -> void:
	var rng := GameRng.new(11)
	var seen: Dictionary[int, int] = {}
	for i: int in 400:
		var index := BattleAI.new().choose(_side, null, rng).move_index
		seen[index] = seen.get(index, 0) + 1
	assert_eq(seen.keys().size(), 4)
	for index: int in seen:
		assert_between(seen[index], 60, 140, "à peu près uniforme")


## « random » ne lit pas les données : mêmes tirages avec ou sans [PokemonData].
func test_random_ignores_the_data() -> void:
	var foe := _smart_side(&"bulbasaur", [&"tackle"], [&"grass", &"poison"])
	var ai := BattleAI.new()
	assert_eq(ai.choose(_side, foe, ScriptedRng.new([3]), _data).move_index, 2)
	var rng := ScriptedRng.new([2])
	assert_eq(ai.choose(_side, foe, rng, _data).move_index, 1)
	assert_eq(rng.calls, 1, "un seul tirage")


# --- « smart » ------------------------------------------------------------------------

## Camp au Nv. 10 avec les capacités [param moves] (PP pleins) et les types [param types].
func _smart_side(species: StringName, moves: Array[StringName],
		types: Array[StringName]) -> BattleSide:
	var party := Party.new()
	var pokemon := PokemonFactory.create(_data, species, 10, ScriptedRng.new(IV_0))
	pokemon.moves.clear()
	for id: StringName in moves:
		pokemon.moves.append(MoveSlot.new(id, _data.get_move(id).pp))
	party.add(pokemon)
	var side := BattleSide.new(party, false, "", BattleAI.new(BattleAI.SMART))
	side.send_out(pokemon, _data)
	side.active.types = types.duplicate()
	return side


func _score(move_id: StringName, own: BattleSide, foe: BattleSide, used: int = 0) -> float:
	return BattleAI.score_move(_data.get_move(move_id), own.active, foe.active,
		_data.get_type_chart(), used)


## Note d'une attaque = puissance × bonus de type × efficacité × précision.
func test_score_of_an_attack() -> void:
	var own := _smart_side(&"charmander", [&"ember", &"scratch"], [&"fire"])
	var grass := _smart_side(&"bulbasaur", [&"tackle"], [&"grass"])
	var water := _smart_side(&"squirtle", [&"tackle"], [&"water"])
	assert_almost_eq(_score(&"ember", own, grass), 40.0 * 1.5 * 2.0, 0.001, "STAB, ×2")
	assert_almost_eq(_score(&"ember", own, water), 40.0 * 1.5 * 0.5, 0.001, "STAB, ×0,5")
	assert_almost_eq(_score(&"scratch", own, grass), 40.0, 0.001, "sans STAB, neutre")
	var ghost := _smart_side(&"squirtle", [&"tackle"], [&"ghost"])
	assert_eq(_score(&"scratch", own, ghost), 0.0, "×0 : inutile")
	var pidgey := _smart_side(&"pidgey", [&"sand_attack"], [&"normal", &"flying"])
	assert_almost_eq(_score(&"leech_seed", own, grass), 0.0, 0.001, "graine sur une Plante")
	assert_almost_eq(_score(&"leech_seed", own, pidgey), 40.0 * 0.9, 0.001,
		"statut : 40 × précision")


## Règle 1 : une attaque sans effet n'est jamais choisie s'il existe une autre option, même
## plus faible.
func test_never_picks_a_move_without_effect() -> void:
	var own := _smart_side(&"rattata", [&"tackle", &"ember"], [&"normal"])
	var water := _smart_side(&"squirtle", [&"tackle"], [&"ghost", &"water"])
	var rng := ScriptedRng.new([])
	assert_eq(own.ai.choose(own, water, rng, _data).move_index, 1, "Flammèche ×0,5 > Charge ×0")
	assert_eq(rng.calls, 0, "un seul candidat : aucun tirage")


## Règle 1 (fin) : toutes inutiles → un tirage parmi toutes.
func test_all_useless_falls_back_to_a_draw() -> void:
	var own := _smart_side(&"rattata", [&"tackle", &"scratch"], [&"normal"])
	var ghost := _smart_side(&"squirtle", [&"tackle"], [&"ghost"])
	assert_eq(own.ai.choose(own, ghost, ScriptedRng.new([2]), _data).move_index, 1)


## Règle 2 : une attaque super efficace l'emporte sur toute attaque neutre, même plus forte,
## et sur les statuts.
func test_super_effective_beats_a_stronger_neutral_move() -> void:
	var own := _smart_side(&"rattata", [&"hyper_fang", &"growl", &"ember"], [&"normal"])
	var grass := _smart_side(&"bulbasaur", [&"tackle"], [&"grass"])
	assert_gt(_score(&"hyper_fang", own, grass), _score(&"ember", own, grass),
		"Croc de Mort (80, STAB) a une meilleure note")
	var rng := ScriptedRng.new([])
	for i: int in 5:
		assert_eq(own.ai.choose(own, grass, rng, _data).move_index, 2, "Flammèche ×2")
	assert_eq(rng.calls, 0)


## Règle 3 : la meilleure note l'emporte sans tirage ; égalité → un tirage parmi les
## meilleures (reproductible).
func test_best_score_then_draw_among_ties() -> void:
	var own := _smart_side(&"pidgey", [&"tackle", &"gust", &"sand_attack"], [&"flying"])
	var foe := _smart_side(&"rattata", [&"tackle"], [&"normal"])
	var rng := ScriptedRng.new([])
	assert_eq(own.ai.choose(own, foe, rng, _data).move_index, 1, "Tornade (STAB) seule")
	assert_eq(rng.calls, 0)
	var tie := _smart_side(&"charmander", [&"scratch", &"growl"], [&"fire"])
	assert_eq(tie.ai.choose(tie, foe, ScriptedRng.new([1]), _data).move_index, 0)
	assert_eq(tie.ai.choose(tie, foe, ScriptedRng.new([2]), _data).move_index, 1,
		"Griffe 40 = Rugissement 40 : tirage")


## Règle 3 : une capacité de statut n'est plus choisie après deux usages (par Pokémon et par
## combat).
func test_status_move_at_most_twice() -> void:
	var own := _smart_side(&"charmander", [&"growl", &"scratch"], [&"fire"])
	var foe := _smart_side(&"rattata", [&"tackle"], [&"normal"])
	var ai := own.ai
	assert_eq(ai.choose(own, foe, ScriptedRng.new([1]), _data).move_index, 0)
	assert_eq(ai.choose(own, foe, ScriptedRng.new([1]), _data).move_index, 0)
	assert_eq(ai.times_used(own.active.pokemon, &"growl"), 2)
	var rng := ScriptedRng.new([])
	assert_eq(ai.choose(own, foe, rng, _data).move_index, 1, "Rugissement usé")
	assert_eq(rng.calls, 0)
	assert_eq(ai.times_used(own.active.pokemon, &"scratch"), 0, "les attaques ne comptent pas")
	assert_eq(BattleAI.new(BattleAI.SMART).times_used(own.active.pokemon, &"growl"), 0,
		"une IA neuve par combat")


## Règle 3 : un statut dont l'effet est déjà au maximum n'est plus choisi.
func test_status_move_useless_at_the_bound() -> void:
	var own := _smart_side(&"charmander", [&"growl", &"scratch"], [&"fire"])
	var foe := _smart_side(&"rattata", [&"tackle"], [&"normal"])
	foe.active.change_stage(&"atk", -6)
	assert_eq(_score(&"growl", own, foe), 0.0, "Attaque déjà à −6")
	assert_eq(own.ai.choose(own, foe, ScriptedRng.new([]), _data).move_index, 1)
	var grower := _smart_side(&"bulbasaur", [&"growth"], [&"grass"])
	assert_gt(_score(&"growth", grower, foe), 0.0, "Croissance : jamais de raté, 40")
	grower.active.change_stage(&"atk", 6)
	grower.active.change_stage(&"spa", 6)
	assert_eq(_score(&"growth", grower, foe), 0.0, "les deux au maximum")
	var seeder := _smart_side(&"bulbasaur", [&"leech_seed"], [&"grass"])
	foe.active.seed_fraction = 0.125
	assert_eq(_score(&"leech_seed", seeder, foe), 0.0, "déjà une graine")
	assert_eq(_score(&"sleep_powder", seeder, foe), 0.0,
		"effet que le moteur ne gère pas encore (sommeil : J11)")


## Règle 4 : sous ⅓ de ses PV, plus aucune capacité de statut.
func test_no_status_when_low() -> void:
	var own := _smart_side(&"charmander", [&"growl", &"scratch"], [&"fire"])
	var foe := _smart_side(&"rattata", [&"tackle"], [&"normal"])
	var pokemon := own.active.pokemon
	pokemon.hp = ceili(pokemon.max_hp() / 3.0)
	assert_gt(_score(&"growl", own, foe), 0.0, "à ⅓ tout juste : encore permis")
	pokemon.hp = ceili(pokemon.max_hp() / 3.0) - 1
	assert_true(BattleAI.is_low(own.active))
	assert_eq(_score(&"growl", own, foe), 0.0)
	var rng := ScriptedRng.new([])
	assert_eq(own.ai.choose(own, foe, rng, _data).move_index, 1, "Griffe, sans tirage")
	assert_eq(rng.calls, 0)


## Sans PP : Lutte, sans tirage ; sans données : comme « random ».
func test_smart_struggles_and_falls_back_without_data() -> void:
	var own := _smart_side(&"charmander", [&"growl", &"scratch"], [&"fire"])
	var foe := _smart_side(&"rattata", [&"tackle"], [&"normal"])
	var rng := ScriptedRng.new([2])
	assert_eq(own.ai.choose(own, foe, rng, null).move_index, 1, "tirage parmi toutes")
	for slot: MoveSlot in own.active.pokemon.moves:
		slot.pp = 0
	var empty := ScriptedRng.new([])
	assert_eq(own.ai.choose(own, foe, empty, _data).move_index, BattleAction.STRUGGLE)
	assert_eq(empty.calls, 0)


## Un vrai combat avec l'IA « smart » passe les données (Battle → choose) : le rival du
## labo et ses tirages ne changent pas, un dresseur « smart » ne choisit jamais un ×0.
func test_battle_passes_the_data_to_the_ai() -> void:
	var own := _smart_side(&"rattata", [&"tackle", &"ember"], [&"normal"])
	var party := Party.new()
	var mine := PokemonFactory.create(_data, &"squirtle", 30, ScriptedRng.new(IV_0))
	mine.moves.clear()
	mine.moves.append(MoveSlot.new(&"tail_whip", 30))
	party.add(mine)
	var player := BattleSide.new(party, true)
	var battle := Battle.new(player, own, _data, GameRng.new(4), BattleRules.for_trainer())
	battle.start()
	player.active.types = [&"ghost", &"water"] as Array[StringName]
	var used: Array[StringName] = []
	for turn: int in 3:
		for event: BattleEvent in battle.submit(BattleAction.move(0)):
			if event.kind == BattleEvent.Kind.MOVE_USED \
					and event.side == BattleEvent.SideId.FOE:
				used.append(event.move_id)
	assert_eq(used, [&"ember", &"ember", &"ember"] as Array[StringName],
		"jamais Charge sur un Spectre")


## Jalon 9 : Poudre Toxik est utile sur une cible saine, inutile sur une cible déjà empoisonnée
## ou immunisée (types Poison et Acier) ; l'IA « smart » ne la choisit alors plus.
func test_poison_powder_is_useless_on_a_poisoned_or_immune_target() -> void:
	var own := _smart_side(&"bulbasaur", [&"poison_powder", &"tackle"], [&"grass", &"poison"])
	var foe := _smart_side(&"rattata", [&"tackle"], [&"normal"])
	var move := _data.get_move(&"poison_powder")
	assert_true(BattleAI.status_has_effect(move, own.active, foe.active))
	assert_almost_eq(_score(&"poison_powder", own, foe), BattleAI.STATUS_SCORE * 0.75, 0.001,
		"statut utile × précision 75 %")
	foe.active.pokemon.status = StatusRules.POISON
	assert_false(BattleAI.status_has_effect(move, own.active, foe.active), "déjà empoisonné")
	assert_eq(_score(&"poison_powder", own, foe), 0.0)
	assert_eq(own.ai.choose(own, foe, ScriptedRng.new([]), _data).move_index, 1,
		"Charge, la seule utile")
	var bug_poison: Array[StringName] = [&"bug", &"poison"]
	var steel: Array[StringName] = [&"steel"]
	for types: Array[StringName] in [bug_poison, steel]:
		var immune := _smart_side(&"weedle", [&"tackle"], types)
		assert_false(BattleAI.status_has_effect(move, own.active, immune.active), str(types))
