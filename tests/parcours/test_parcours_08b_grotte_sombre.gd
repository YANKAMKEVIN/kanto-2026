extends GutTest
## Parcours 08 — Progression à pied, tronçons c (découpé pour équilibrer les lots de la CI).
## Parcours 08 — Progression à pied (jalon 33, T6 préparation) : les raccourcis du parcours 02
## rejoués sur la vraie Boot ([ParcoursPlay]), un tronçon par test, chacun depuis son départ de
## débogage, sans saut entre deux cartes sauf quand c'est écrit (« ↷ » au journal) :
## Pont Pépite et Bill, puzzle de Carmin, Routes 9-10 et Grotte Sombre, Casino et repaire
## B1F-B4F, Tour 3F-5F, Route 16 et Piste Cyclable, Safrania et Sylphe 1F-5F.
## Mewtwo en tête ([method ParcoursPlay.make_ace]) : le parcours vérifie les enchaînements
## (déclencheurs, scènes, énigmes, passages), pas l'équilibrage.

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const DEBUG := "res://tools/debug_start/%s.json"

var _play: ParcoursPlay
var _teleport_fade := 0.0


func before_each() -> void:
	_teleport_fade = SceneRouter.teleport_fade_duration
	SceneRouter.teleport_fade_duration = 0.05
	_play = ParcoursPlay.new(self, "08b_grotte_sombre")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_08c_routes_9_10_grotte_sombre() -> void:
	_play.begin("Route 9 à pied")
	await _play.start(DEBUG % "route_9", _play.make_ace)
	await _play.travel(&"route_10")
	_play.expect(GameState.flags.has_flag(&"route_9_entered"), "Route 9 parcourue")

	_play.begin("Grotte Sombre 1F, B1F, 1F sud")
	await _play.travel(&"dark_cave_1f")
	await _play.travel(&"dark_cave_b1f")
	# Marcel barre le passage étroit (34..40, 34) : il repère le joueur, combat, puis s'en va.
	await _play.walk_through(Vector2i(33, 34))
	await _play.walk_through(Vector2i(34, 34))
	_play.expect(GameState.flags.has_flag(&"beaten_dark_cave_marcel"), "Marcel battu")
	await _play.travel(&"dark_cave_1f", 4, true, Vector2i(44, 34))
	await _play.travel(&"route_10", 4, true, Vector2i(8, 48))

	_play.begin("Route 10 sud jusqu'à Lavanville")
	# Le déclencheur « grotte traversée » couvre la rangée 49, juste sous l'arrivée (8, 48).
	await _play.travel(&"lavender_town")
	_play.expect(GameState.flags.has_flag(&"dark_cave_crossed"), "grotte traversée")
	# Arrivée en (21, 0) ; le déclencheur couvre (21..23, 1), pas vers le sud.
	await _play.walk_through(Vector2i(21, 2))
	_play.expect(GameState.flags.has_flag(&"lavender_reached"), "arrivée à Lavanville")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)
