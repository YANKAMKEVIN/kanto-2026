extends GutTest
## Parcours 09 — Donjons à pied, tronçons d, e (découpé pour équilibrer les lots de la CI).
## Parcours 09 — Donjons à pied (jalon 33, T6 préparation) : les raccourcis des parcours 03 et
## 05 rejoués sur la vraie Boot ([ParcoursPlay]), un tronçon par test, chacun depuis son départ
## de débogage : téléporteurs de l'Arène de Safrania (Badge Marais), Manoir 1F à B1F (statues,
## trou, Clé Secrète), portes du quiz de Cramois'Île, Arène de Jadielle à pied, Route 23
## (contrôles des Badges, Surf) jusqu'à la Route Victoire, Grotte Azurée 1F, 2F et B1F jusqu'à
## Mewtwo. Mewtwo en tête ([method ParcoursPlay.make_ace]) : enchaînements, pas équilibrage.

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const DEBUG := "res://tools/debug_start/%s.json"
## Route Victoire 1F : poussées du rocher (5, 15) jusqu'à l'interrupteur (17, 13) (case où se
## tenir, direction), plus court chemin calculé sur le plan `route_victoire_1f.txt`.
const VR1F_PUSHES: Array[Array] = [[Vector2i(5, 14), Vector2i.DOWN],
	[Vector2i(4, 16), Vector2i.RIGHT], [Vector2i(5, 16), Vector2i.RIGHT],
	[Vector2i(6, 16), Vector2i.RIGHT], [Vector2i(8, 17), Vector2i.UP],
	[Vector2i(7, 15), Vector2i.RIGHT], [Vector2i(9, 16), Vector2i.UP],
	[Vector2i(8, 14), Vector2i.RIGHT], [Vector2i(9, 14), Vector2i.RIGHT],
	[Vector2i(10, 14), Vector2i.RIGHT], [Vector2i(11, 14), Vector2i.RIGHT],
	[Vector2i(12, 14), Vector2i.RIGHT], [Vector2i(13, 14), Vector2i.RIGHT],
	[Vector2i(14, 14), Vector2i.RIGHT], [Vector2i(16, 15), Vector2i.UP],
	[Vector2i(16, 14), Vector2i.UP], [Vector2i(15, 12), Vector2i.RIGHT],
	[Vector2i(17, 11), Vector2i.DOWN]]

var _play: ParcoursPlay
var _teleport_fade := 0.0


func before_each() -> void:
	_teleport_fade = SceneRouter.teleport_fade_duration
	SceneRouter.teleport_fade_duration = 0.05
	_play = ParcoursPlay.new(self, "09b_jadielle_route_23")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_09d_arene_de_jadielle_a_pied() -> void:
	_play.begin("Arène de Jadielle : de l'entrée à Giovanni")
	await _play.start(DEBUG % "viridian_gym", _play.make_ace)
	await _play.walk_sliding(Vector2i(4, 4))
	_play.heal()
	await _play.interact(Vector2i.UP)
	_play.expect(_play.won(&"viridian_gym_giovanni"), "Giovanni battu")
	_play.expect_flags(["badge_earth", "tm27_received"], "Badge Terre et CT27")
	assert_true(_play.report())
	assert_push_error_count(0)


func test_09e_route_23_jusqu_a_la_route_victoire() -> void:
	_play.begin("Route 23 : sept contrôles, Surf")
	await _play.start(DEBUG % "route_23_all", func() -> void:
		_play.make_ace()
		_play.shortcut([], "Léviator apprend Surf et Kangourex Force (CS03 et CS04 dans le Sac)")
		_teach(&"gyarados", &"surf", 15)
		_teach(&"kangaskhan", &"strength", 15))
	await _play.travel(&"route_23")
	# Deux étendues d'eau séparées par l'îlot (8..9, 90..91) : deux départs en Surf.
	await _play.surf_to(Vector2i(9, 90))
	await _play.surf_to(Vector2i(10, 71))
	await _play.walk_through(Vector2i(4, 32))
	_play.expect_flags(["route_23_check_7_passed", "route_23_check_6_passed",
		"route_23_check_5_passed", "route_23_check_4_passed", "route_23_check_3_passed",
		"route_23_check_2_passed", "route_23_check_1_passed"], "sept contrôles passés")
	await _play.travel(&"victory_road_1f")

	_play.begin("Route Victoire 1F : rocher sur l'interrupteur, échelle")
	for push: Array in VR1F_PUSHES:
		if not await _play.push_boulder(push[0], push[1]):
			break
	_play.expect(GameState.flags.has_flag(&"victory_road_1f_switch_1"), "interrupteur pressé")
	_play.expect(not _play.boot.get_map().get_grid().is_occupied(Vector2i(9, 12)),
		"barrière (9, 12) ouverte")
	await _play.travel(&"victory_road_2f", 4, true, Vector2i(1, 1))
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


func _teach(species: StringName, move: StringName, pp: int) -> void:
	for pokemon: Pokemon in GameState.party.get_all():
		if pokemon.species_id == species:
			if pokemon.moves.size() >= 4:
				pokemon.moves.remove_at(pokemon.moves.size() - 1)
			pokemon.moves.append(MoveSlot.new(move, pp))
			return
