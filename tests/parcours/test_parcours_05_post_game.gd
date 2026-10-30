extends GutTest
## Parcours 05 — Post-game (jalon 33, T5 ; `docs/design/passes/j33-v1-chatgpt.md` §7 : Grotte
## Inconnue, Mewtwo, Ligue rejouable), une seule partie sur la vraie Boot ([ParcoursPlay]),
## partie du départ `cerulean_cave_locked` (Conseil des Quatre battu, Champion à affronter) :
## - Grotte Inconnue fermée tant que le titre n'est pas acquis ;
## - Champion battu, Panthéon, Bourg Palette ;
## - la Grotte s'ouvre, Mewtwo capturé au B1F (Hyper Ball sûre) ;
## - la Ligue rejouée en entier : deuxième entrée au Panthéon, Mewtwo gardé ;
## - dons de Chen après la Ligue ; sauvegarde relue à l'identique.

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const START := "res://tools/debug_start/cerulean_cave_locked.json"
const CAVE_DOOR := Vector2i(52, 6)
const LOBBY_DOOR_FRONT := Vector2i(12, 4)
const OAK_TALK := Vector2i(8, 5)

var _play: ParcoursPlay


func before_each() -> void:
	_play = ParcoursPlay.new(self, "05_post_game")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_parcours_05_grotte_mewtwo_ligue_rejouee() -> void:
	_play.begin("Azuria : Grotte Inconnue fermée avant le titre")
	await _play.start(START, _play.make_ace)
	await _play.surf_to(CAVE_DOOR + Vector2i.DOWN)
	await _play.step(Vector2i.UP)
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(_play.map_id() == &"cerulean_city", "on reste à Azuria")

	_play.begin("Champion de la Ligue")
	await _play.jump(&"league_champion", &"from_south", Vector2i.UP)
	_play.heal()
	await _play.walk_to(ParcoursPlay.LEAGUE_CALLS[4])
	await _play.run_scene()
	_play.expect(_play.won(&"rival_champion"), "Champion battu")
	_play.expect(_play.map_id() == &"pallet_town", "Panthéon puis Bourg Palette")
	_play.expect(LeagueAttempt.is_champion(GameState.flags), "titre")
	_play.expect(GameState.hall_of_fame.size() == 1, "première entrée au Panthéon")

	_play.begin("Grotte Inconnue : Mewtwo")
	await _play.jump(&"cerulean_city", &"from_center", Vector2i.UP)
	await _play.surf_to(CAVE_DOOR + Vector2i.DOWN)
	await _play.step(Vector2i.UP)
	_play.expect(_play.map_id() == &"cerulean_cave_1f", "entrée dans la Grotte")
	_play.shortcut([], "1F, 2F et B1F de la Grotte (tests J31)")
	await _play.jump(&"cerulean_cave_b1f", &"mewtwo_front", Vector2i.UP)
	var facing := await _play.approach(Vector2i(27, 13))
	var outcome := await _play.catch_with(facing, &"ultra_ball", true)
	_play.expect(outcome == Battle.Outcome.CAUGHT, "Mewtwo capturé (issue %d)" % outcome)
	_play.expect_flags(["mewtwo_encounter_resolved", "mewtwo_caught"], "rencontre close")
	var mewtwos := _count(&"mewtwo")

	_play.begin("Ligue rejouée")
	await _play.jump(&"indigo_plateau_lobby", &"league_door", Vector2i.DOWN)
	await _play.walk_through(LOBBY_DOOR_FRONT)
	await _play.step(Vector2i.UP)
	await _play.run_scene(true)
	_play.expect(_play.map_id() == &"league_lorelei", "salle d'Olga")
	_play.expect(LeagueAttempt.is_active(GameState.flags), "nouvelle tentative")
	await _play.run_league()
	_play.begin("Deuxième cérémonie")
	_play.expect(_play.map_id() == &"pallet_town", "retour à Bourg Palette")
	_play.expect(GameState.hall_of_fame.size() == 2, "deuxième entrée au Panthéon")
	_play.expect(_count(&"mewtwo") == mewtwos, "Mewtwo gardé, jamais dédoublé")
	_play.expect(not GameState.flags.has_flag(&"mewtwo_encounter_resolved")
		or GameState.flags.has_flag(&"mewtwo_caught"), "Mewtwo capturé ne réapparaît pas")

	_play.begin("Dons de Chen après la Ligue")
	await _play.jump(&"oak_lab", &"entrance", Vector2i.UP)
	var party_size := GameState.party.size() + GameState.storage.size()
	await _play.talk(OAK_TALK, Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"oak_post_league_gifts_done"), "dons reçus")
	_play.expect(GameState.party.size() + GameState.storage.size() == party_size + 2,
		"deux starters de plus (équipe ou Stockage)")

	_play.begin("Relance")
	await _play.persist()
	_play.expect(GameState.hall_of_fame.size() == 2, "Panthéon relu")
	_play.expect(_count(&"mewtwo") == mewtwos, "Mewtwo relu")
	assert_true(_play.report())
	assert_push_error_count(0)


func _count(species: StringName) -> int:
	var found := 0
	for pokemon: Pokemon in GameState.party.get_all() + GameState.storage.get_all():
		if pokemon.species_id == species:
			found += 1
	return found
