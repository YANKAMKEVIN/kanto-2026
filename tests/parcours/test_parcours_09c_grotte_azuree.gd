extends GutTest
## Parcours 09 — Donjons à pied, tronçons f (découpé pour équilibrer les lots de la CI).
## Parcours 09 — Donjons à pied (jalon 33, T6 préparation) : les raccourcis des parcours 03 et
## 05 rejoués sur la vraie Boot ([ParcoursPlay]), un tronçon par test, chacun depuis son départ
## de débogage : téléporteurs de l'Arène de Safrania (Badge Marais), Manoir 1F à B1F (statues,
## trou, Clé Secrète), portes du quiz de Cramois'Île, Arène de Jadielle à pied, Route 23
## (contrôles des Badges, Surf) jusqu'à la Route Victoire, Grotte Azurée 1F, 2F et B1F jusqu'à
## Mewtwo. Mewtwo en tête ([method ParcoursPlay.make_ace]) : enchaînements, pas équilibrage.

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const DEBUG := "res://tools/debug_start/%s.json"

var _play: ParcoursPlay
var _teleport_fade := 0.0


func before_each() -> void:
	_teleport_fade = SceneRouter.teleport_fade_duration
	SceneRouter.teleport_fade_duration = 0.05
	_play = ParcoursPlay.new(self, "09c_grotte_azuree")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_09f_grotte_azuree_1f_a_mewtwo() -> void:
	_play.begin("Grotte Azurée 1F, 2F, 1F, B1F")
	await _play.start(DEBUG % "cerulean_cave_1f", _play.make_ace)
	await _play.surf_to(Vector2i(11, 13))
	await _play.travel(&"cerulean_cave_2f", 4, true, Vector2i(3, 11))
	await _play.travel(&"cerulean_cave_1f", 4, true, Vector2i(1, 3))
	await _play.travel(&"cerulean_cave_b1f", 4, true, Vector2i(0, 6))
	_play.begin("Grotte Azurée B1F : Mewtwo")
	await _play.surf_to(Vector2i(19, 11))
	await _play.surf_to(Vector2i(26, 15))
	await _play.walk_through(Vector2i(27, 12))
	var outcome := await _play.catch_with(Vector2i.DOWN, &"ultra_ball", true)
	_play.expect(outcome == Battle.Outcome.CAUGHT, "Mewtwo capturé (issue %d)" % outcome)
	_play.expect_flags(["mewtwo_encounter_resolved", "mewtwo_caught"], "drapeaux de Mewtwo")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


## Apprend [param move] au premier [param species] de l'équipe (à la place de sa dernière capacité
## si elle en a quatre).
