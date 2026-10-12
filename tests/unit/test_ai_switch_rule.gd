extends GutTest
## AiSwitchRule (jalon 13 §2.11, dossier 16 §14) : règle pure et déterministe du changement de
## Pokémon de l'IA. Bornes 25 % / 50 %, faiblesses ×2 et ×4, candidat faible écarté, premier dans
## l'ordre, K.O. et actif exclus, aucun candidat, tour forcé.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
const STAY := AiSwitchRule.STAY

var _data: PokemonData
var _chart: TypeChart


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_chart = _data.get_type_chart()


func _mon(species: StringName, level: int = 20) -> Pokemon:
	return PokemonFactory.create(_data, species, level, ScriptedRng.new(IV_0))


## Camp adverse : [param team] dans l'ordre, [param active] (place) en jeu.
func _side(team: Array[Pokemon], active: int = 0) -> BattleSide:
	var party := Party.new()
	for pokemon: Pokemon in team:
		party.add(pokemon)
	var side := BattleSide.new(party, false, "Ondine")
	side.send_out(party.get_at(active), _data)
	return side


## Pokémon du joueur en jeu.
func _player(species: StringName) -> Battler:
	var pokemon := _mon(species)
	return Battler.new(pokemon, _data.get_species(species).types)


func test_no_danger_no_switch() -> void:
	# Pidgey (Normal/Vol) ne frappe pas Salamèche à ×2 ; PV pleins.
	var side := _side([_mon(&"charmander"), _mon(&"rattata")])
	assert_false(AiSwitchRule.is_in_danger(side.active, _player(&"pidgey"), _chart))
	assert_eq(AiSwitchRule.pick(side, _player(&"pidgey"), _chart, _data), STAY)


func test_hp_quarter_bound() -> void:
	var charmander := _mon(&"charmander")
	var side := _side([charmander, _mon(&"rattata")])
	var quarter := charmander.max_hp() * AiSwitchRule.DANGER_HP_RATIO
	charmander.hp = floori(quarter)
	assert_eq(AiSwitchRule.pick(side, _player(&"pidgey"), _chart, _data), 1, "≤ 25 % : danger")
	charmander.hp = floori(quarter) + 1
	assert_eq(AiSwitchRule.pick(side, _player(&"pidgey"), _chart, _data), STAY, "> 25 % : non")
	charmander.hp = 1
	assert_true(AiSwitchRule.is_in_danger(side.active, _player(&"pidgey"), _chart))


func test_half_hp_bound_for_the_candidate() -> void:
	var rattata := _mon(&"rattata")
	var side := _side([_mon(&"charmander"), rattata])
	var foe := _player(&"squirtle")
	rattata.hp = floori(rattata.max_hp() * AiSwitchRule.SAFE_HP_RATIO)
	assert_false(AiSwitchRule.is_better_placed(rattata, foe, _chart, _data), "50 % pile : non")
	assert_eq(AiSwitchRule.pick(side, foe, _chart, _data), STAY)
	rattata.hp += 1
	assert_true(AiSwitchRule.is_better_placed(rattata, foe, _chart, _data))
	assert_eq(AiSwitchRule.pick(side, foe, _chart, _data), 1)


func test_weakness_double_and_quadruple() -> void:
	var water := _player(&"squirtle")
	assert_true(AiSwitchRule.is_weak_to(_types(&"charmander"), water, _chart), "Eau → Feu ×2")
	assert_true(AiSwitchRule.is_weak_to(_types(&"geodude"), water, _chart), "Eau → Roche/Sol ×4")
	assert_false(AiSwitchRule.is_weak_to(_types(&"pidgey"), water, _chart), "neutre")
	assert_false(AiSwitchRule.is_weak_to(_types(&"squirtle"), _player(&"charmander"), _chart),
		"résistance : pas de faiblesse")
	# Faiblesse à PV pleins : danger.
	var side := _side([_mon(&"charmander"), _mon(&"pidgey")])
	assert_true(AiSwitchRule.is_in_danger(side.active, water, _chart))
	assert_eq(AiSwitchRule.pick(side, water, _chart, _data), 1)


## Un type du Pokémon du joueur suffit (double type de l'attaquant).
func test_any_type_of_the_player_counts() -> void:
	# Bulbizarre (Plante/Poison) : Plante frappe Racaillou à ×4.
	var side := _side([_mon(&"geodude"), _mon(&"rattata")])
	assert_eq(AiSwitchRule.pick(side, _player(&"bulbasaur"), _chart, _data), 1)


func test_weak_candidate_is_skipped() -> void:
	var side := _side([_mon(&"charmander"), _mon(&"geodude"), _mon(&"sandshrew"),
		_mon(&"pidgey")])
	assert_eq(AiSwitchRule.pick(side, _player(&"squirtle"), _chart, _data), 3,
		"Racaillou et Sabelette craignent l'Eau")


func test_first_candidate_in_party_order() -> void:
	var side := _side([_mon(&"charmander"), _mon(&"pidgey"), _mon(&"rattata")])
	assert_eq(AiSwitchRule.pick(side, _player(&"squirtle"), _chart, _data), 1)


func test_fainted_and_active_are_excluded() -> void:
	var fainted := _mon(&"pidgey")
	fainted.hp = 0
	# L'actif est à la place 1, il n'est jamais son propre remplaçant.
	var side := _side([fainted, _mon(&"charmander"), _mon(&"rattata")], 1)
	assert_eq(AiSwitchRule.pick(side, _player(&"squirtle"), _chart, _data), 2)


func test_no_candidate_stays() -> void:
	var low := _mon(&"rattata")
	low.hp = 1
	var side := _side([_mon(&"charmander"), _mon(&"geodude"), low])
	assert_eq(AiSwitchRule.pick(side, _player(&"squirtle"), _chart, _data), STAY)
	var alone := _side([_mon(&"charmander")])
	assert_eq(AiSwitchRule.pick(alone, _player(&"squirtle"), _chart, _data), STAY)


func test_locked_or_fainted_active_stays() -> void:
	var side := _side([_mon(&"charmander"), _mon(&"pidgey")])
	side.active.bide_stage = 1
	assert_true(side.active.is_locked())
	assert_eq(AiSwitchRule.pick(side, _player(&"squirtle"), _chart, _data), STAY, "Patience")
	side.active.clear_bide()
	side.active.pokemon.hp = 0
	assert_eq(AiSwitchRule.pick(side, _player(&"squirtle"), _chart, _data), STAY, "K.O.")


func test_missing_inputs_stay() -> void:
	var side := _side([_mon(&"charmander"), _mon(&"pidgey")])
	assert_eq(AiSwitchRule.pick(side, null, _chart, _data), STAY)
	assert_eq(AiSwitchRule.pick(side, _player(&"squirtle"), null, _data), STAY)
	assert_eq(AiSwitchRule.pick(null, _player(&"squirtle"), _chart, _data), STAY)


func _types(species: StringName) -> Array[StringName]:
	return _data.get_species(species).types
