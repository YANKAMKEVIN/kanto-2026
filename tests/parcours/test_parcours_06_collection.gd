extends GutTest
## Parcours 06 — Collection (jalon 33, T5 ; `docs/design/passes/j33-v1-chatgpt.md` §7 : Pokédex,
## évolutions, stockage, secrets), une seule partie sur la vraie Boot ([ParcoursPlay]), partie
## du départ `evolution_qa` (Forêt de Jade, Chenipan à 1 XP du N7) :
## - Chenipan en tête bat Théo et évolue en Chrysacier après le combat (Pokédex : capturé) ;
## - captures dans les herbes jusqu'à l'équipe pleine, la suivante part au Stockage ;
## - dépôt et retrait par les règles du Stockage ;
## - 150 espèces (raccourci : toute l'aventure) → Diplôme du Concepteur → Mew sous le camion
##   de Carmin, capturé : 151 ;
## - sauvegarde relue à l'identique (Pokédex, Stockage, équipe).

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const START := "res://tools/debug_start/evolution_qa.json"

var _play: ParcoursPlay


func before_each() -> void:
	_play = ParcoursPlay.new(self, "06_collection")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_parcours_06_evolution_stockage_pokedex_mew() -> void:
	_play.begin("Forêt de Jade : Chenipan contre Théo, évolution")
	await _play.start(START, func() -> void:
		var index := _play.party_species().find(&"caterpie")
		GameState.party.move(index, 0)
		_play.shortcut([], "Chenipan mis en tête (écran Équipe)", {"poke_ball": 10}))
	_play.expect(_play.party_species()[0] == &"caterpie", "Chenipan en tête")
	await _play.jump(&"viridian_forest", &"before_theo", Vector2i.LEFT)
	await _play.walk_through(Vector2i(30, 70))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(_play.won(&"forest_scout_theo"), "Théo battu")
	_play.expect(_play.party_species()[0] == &"metapod", "Chenipan évolue en Chrysacier")
	_play.expect(GameState.pokedex.is_caught(&"metapod"), "Chrysacier capturé au Pokédex")
	_play.expect(not _play.party_species().has(&"caterpie"), "plus de Chenipan dans l'équipe")

	_play.begin("Captures : équipe pleine, puis Stockage")
	_play.make_ace()
	var stored_before := GameState.storage.size()
	while GameState.party.size() < 6:
		var size := GameState.party.size()
		var outcome := await _play.catch_in_grass(&"poke_ball")
		if not _play.expect(outcome == Battle.Outcome.CAUGHT and GameState.party.size() == size + 1,
				"capture dans l'équipe (issue %d)" % outcome):
			break
	var outcome := await _play.catch_in_grass(&"poke_ball")
	_play.expect(outcome == Battle.Outcome.CAUGHT, "capture avec l'équipe pleine")
	_play.expect(GameState.party.size() == 6, "équipe toujours à 6")
	_play.expect(GameState.storage.size() == stored_before + 1, "la capture part au Stockage")

	_play.begin("Stockage : dépôt et retrait")
	var last := GameState.party.get_at(GameState.party.size() - 1)
	_play.expect(StorageRules.deposit(GameState.party, GameState.storage,
		GameState.party.size() - 1).is_ok(), "dépôt")
	_play.expect(GameState.storage.index_of(last) >= 0, "déposé au Stockage")
	_play.expect(StorageRules.withdraw(GameState.party, GameState.storage,
		GameState.storage.index_of(last)).is_ok(), "retrait")
	_play.expect(GameState.party.get_all().has(last), "repris dans l'équipe")
	await _play.persist("équipe et Stockage relus à l'identique")

	_play.begin("Pokédex à 150 : Diplôme")
	_play.shortcut(["league_champion_defeated"], "Ligue (parcours 04)")
	for species: StringName in _play.boot.get_pokemon_data().get_species_ids():
		if species != &"mew":
			GameState.pokedex.mark_caught(species)
	_play.shortcut([], "les 150 captures de toute l'aventure (Pokédex)")
	_play.expect(GameState.pokedex.caught_count() == 150, "150 espèces capturées")
	await _play.jump(&"celadon_mansion_3f", &"from_down", Vector2i.UP)
	await _play.talk(Vector2i(9, 4), Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"diploma_received"), "Diplôme reçu")

	_play.begin("Carmin : Mew sous le camion")
	await _play.jump(&"vermilion_city", &"from_fisher_house", Vector2i.DOWN)
	var facing := await _play.approach(Vector2i(5, 25))
	var mew := await _play.catch_with(facing, &"poke_ball", true)
	_play.expect(GameState.flags.has_flag(&"mew_appeared"), "Mew apparaît")
	_play.expect(mew == Battle.Outcome.CAUGHT, "Mew capturé (issue %d)" % mew)
	_play.expect(GameState.pokedex.caught_count() == 151, "151 espèces")

	_play.begin("Relance")
	await _play.persist()
	_play.expect(GameState.pokedex.caught_count() == 151, "Pokédex relu")
	assert_true(_play.report())
	assert_push_error_count(0)
