extends GutTest
## Parcours, variantes des trois starters (jalon 33, T5 ; `docs/design/passes/j33-v1-chatgpt.md`
## §7 et §8 « Équipes du rival ») : pour chaque starter, les trois derniers combats du rival sur
## la vraie partie ([ParcoursPlay]), avec ses vrais départs :
## - Route 22 (dernier rival avant la Route Victoire, `route_22_final_<starter>`) ;
## - 7F de la Sylphe SARL (`silph_7f_rival_<starter>`) ;
## - Champion de la Ligue (`league_champion_<starter>`), jusqu'au Panthéon.
## L'équipe affrontée est celle que les données donnent contre ce starter, et son dernier
## Pokémon est le starter évolué qui bat le nôtre.

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const STARTS := "res://tools/debug_start/%s_%s.json"
## Starter du joueur → dernier Pokémon du rival (RB : le type qui l'emporte).
const ACES: Dictionary[StringName, StringName] = {
	&"bulbasaur": &"charizard", &"charmander": &"blastoise", &"squirtle": &"venusaur",
}
## Route 22 ouest : cases de l'appel (7 à 9, 7) ; Sylphe 7F : cases (3, 2) et (3, 3) ; salle du
## Champion : rangée 5 (voir les scènes et `test_silph_rival.gd`).
const ROUTE_22_CALL := Vector2i(9, 7)
const SILPH_CALL := Vector2i(3, 3)
const CHAMPION_CALL := Vector2i(4, 5)

var _play: ParcoursPlay


func before_each() -> void:
	_play = null


func after_each() -> void:
	if _play != null:
		_play.teardown()


func test_parcours_bulbizarre() -> void:
	await _run(&"bulbasaur")


func test_parcours_salameche() -> void:
	await _run(&"charmander")


func test_parcours_carapuce() -> void:
	await _run(&"squirtle")


func _run(starter: StringName) -> void:
	_play = ParcoursPlay.new(self, "starter_%s" % starter)
	_play.setup()
	await _segment(starter, "route_22_final", &"rival_route22_final", ROUTE_22_CALL)
	_play.expect_flags(["rival_route22_final_won"], "rival de la Route 22 battu")
	await _segment(starter, "silph_7f_rival", &"rival_silph", SILPH_CALL)
	_play.expect_flags(["rival_silph_won"], "rival de la Sylphe battu")
	await _segment(starter, "league_champion", &"rival_champion", CHAMPION_CALL)
	_play.expect(_play.map_id() == &"pallet_town", "Panthéon puis Bourg Palette")
	_play.expect(LeagueAttempt.is_champion(GameState.flags), "titre de Champion")
	assert_true(_play.report())
	assert_push_error_count(0)


func _segment(starter: StringName, start: String, trainer: StringName, call: Vector2i,
		settle: bool = true) -> void:
	_play.begin("%s (%s)" % [trainer, starter])
	await _play.restart(STARTS % [start, starter], _play.make_ace, settle)
	_play.expect(GameState.starter_species == starter, "starter de la partie")
	_play.heal()
	await _play.walk_to(call)
	await _play.run_scene()
	var battle := _play.last_battle(trainer)
	var foe: Array = battle.get("foe", [])
	_play.expect(_play.won(trainer), "combat gagné")
	_play.expect(foe == _play.trainer_species(trainer, starter), "équipe des données (%s)" % [foe])
	_play.expect(not foe.is_empty() and foe.back() == ACES[starter],
		"%s en dernier" % ACES[starter])
