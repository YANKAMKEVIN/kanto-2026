extends GutTest
## Compteur de pas de la Pension (J15, T4 ; jalon-15.md §2.5.1, §5 ; dossier 18 §4.2) : un pas
## libre = 1 XP en attente ; pas scripté ignoré ; Pension vide ou plafond du niveau 100 : rien.
## Le mur (pas refusé) et la course se vérifient sur le vrai joueur (test_daycare_flow).

var _data: PokemonData
var _config: DaycareConfig
var _daycare: Daycare
var _counter: DaycareStepCounter


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_config = DaycareConfig.load_default()
	_daycare = Daycare.new()
	_counter = DaycareStepCounter.new(_config)


func _keep(species: StringName, level: int) -> Pokemon:
	var mon := PokemonFactory.create(_data, species, level, GameRng.new(3))
	_daycare.put(mon, _data)
	return mon


func test_a_free_step_puts_one_exp_aside() -> void:
	_keep(&"rattata", 5)
	assert_eq(_counter.on_player_moved(_daycare, true), 1, "F-1 : 1 XP par pas")
	assert_eq(_counter.on_player_moved(_daycare, true), 1)
	assert_eq(_daycare.pending_exp, 2)
	assert_eq(_counter.counted(), 2)


func test_a_scripted_step_is_ignored() -> void:
	var mon := _keep(&"rattata", 5)
	var exp := mon.experience
	assert_eq(_counter.on_player_moved(_daycare, false), 0, "entrée bloquée : pas scripté")
	assert_eq(_daycare.pending_exp, 0)
	assert_eq(_counter.counted(), 0)
	assert_eq(mon.experience, exp, "rien ne change sur le Pokémon pendant le séjour")


func test_an_empty_daycare_counts_nothing() -> void:
	assert_eq(_counter.on_player_moved(_daycare, true), 0)
	assert_eq(_counter.on_player_moved(null, true), 0)
	assert_eq(_counter.counted(), 0)


func test_level_100_is_the_cap() -> void:
	_keep(&"rattata", 100)
	assert_eq(_counter.on_player_moved(_daycare, true), 0, "plafond du niveau 100")
	assert_eq(_daycare.pending_exp, 0)


func test_level_99_stops_at_the_cap() -> void:
	var mon := _keep(&"rattata", 99)
	var rate := _data.get_species(&"rattata").growth_rate
	var room := ExpCurve.exp_for_level(rate, 100) - mon.experience
	for i: int in room + 5:
		_counter.on_player_moved(_daycare, true)
	assert_eq(_daycare.pending_exp, room, "jamais au-delà du niveau 100")
	assert_eq(_daycare.level_after(_data), 100)
