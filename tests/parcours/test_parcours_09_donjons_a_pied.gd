extends GutTest
## Parcours 09 — Donjons à pied (jalon 33, T6 préparation) : les raccourcis des parcours 03 et
## 05 rejoués sur la vraie Boot ([ParcoursPlay]), un tronçon par test, chacun depuis son départ
## de débogage : téléporteurs de l'Arène de Safrania (Badge Marais), Manoir 1F à B1F (statues,
## trou, Clé Secrète), portes du quiz de Cramois'Île, Arène de Jadielle à pied, Route 23
## (contrôles des Badges, Surf) jusqu'à la Route Victoire, Grotte Azurée 1F, 2F et B1F jusqu'à
## Mewtwo. Mewtwo en tête ([method ParcoursPlay.make_ace]) : enchaînements, pas équilibrage.

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const DEBUG := "res://tools/debug_start/%s.json"
## Arène de Safrania : téléporteur posé → case d'arrivée (plus court chemin du plan
## `safrania_arene.txt` : S, SE, NE, NO, salle centrale).
const SAFFRON_HOPS: Array[Array] = [[Vector2i(11, 15), Vector2i(19, 17)],
	[Vector2i(15, 15), Vector2i(19, 3)], [Vector2i(15, 5), Vector2i(1, 3)],
	[Vector2i(1, 5), Vector2i(11, 11)]]
## Quiz de Cramois'Île : case devant la machine (tournée vers le haut) et bonne réponse.
const QUIZ: Array[Array] = [[Vector2i(15, 8), true], [Vector2i(10, 2), false],
	[Vector2i(9, 8), false], [Vector2i(9, 14), false], [Vector2i(1, 14), true],
	[Vector2i(1, 8), false]]

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
	_play = ParcoursPlay.new(self, "09_donjons_a_pied")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_09a_arene_de_safrania_teleporteurs() -> void:
	_play.begin("Arène de Safrania : téléporteurs jusqu'à Morgane")
	await _play.start(DEBUG % "saffron_gym", _play.make_ace)
	for hop: Array in SAFFRON_HOPS:
		await _play.walk_through(hop[0])
		await _play.wait_stable()
		await wait_process_frames(20)
		_play.expect(_play.player.get_cell() == hop[1], "téléporteur %s → %s (case %s)"
			% [hop[0], hop[1], _play.player.get_cell()])
	_play.heal()
	await _play.talk(Vector2i(9, 9), Vector2i.UP)
	_play.expect(_play.won(&"saffron_gym_sabrina"), "Morgane battue")
	_play.expect_flags(["badge_marsh", "tm46_received"], "Badge Marais et CT46")
	assert_true(_play.report())
	assert_push_error_count(0)


func test_09b_manoir_1f_a_b1f() -> void:
	_play.begin("Manoir 1F, 2F, 3F : statue, trou")
	await _play.start(DEBUG % "j25_manoir", _play.make_ace)
	await _play.travel(&"pokemon_mansion_1f")
	_play.expect(not GameState.flags.has_flag(&"mansion_switch_on"), "interrupteur sur ARRÊT à l'entrée")
	await _play.travel(&"pokemon_mansion_2f", 4, true, Vector2i(5, 10))
	await _play.travel(&"pokemon_mansion_3f", 4, true, Vector2i(6, 1))
	await _play.talk_to(Vector2i(6, 12))
	await _play.talk(Vector2i(10, 6), Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"mansion_switch_on"), "statue du 3F : MARCHE")
	await _play.travel(&"pokemon_mansion_1f", 4, true, Vector2i(16, 14))
	_play.expect(GameState.flags.has_flag(&"mansion_switch_on"), "chute : interrupteur gardé")

	_play.begin("Manoir B1F : deux statues, Clé Secrète")
	await _play.travel(&"pokemon_mansion_b1f", 4, true, Vector2i(21, 23))
	await _play.talk(Vector2i(18, 26), Vector2i.UP)
	_play.expect(not GameState.flags.has_flag(&"mansion_switch_on"), "statue sud : ARRÊT")
	await _play.talk(Vector2i(20, 4), Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"mansion_switch_on"), "statue nord : MARCHE")
	await _play.talk_to(Vector2i(5, 13))
	_play.expect(GameState.bag.has(&"secret_key"), "Clé Secrète dans le Sac")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


func test_09c_quiz_de_cramois_ile() -> void:
	_play.begin("Arène de Cramois'Île : porte, six machines, Auguste")
	await _play.start(DEBUG % "j25_arene", _play.make_ace)
	await _play.travel(&"cinnabar_gym")
	_play.expect(GameState.flags.has_flag(&"cinnabar_gym_unlocked"), "Clé Secrète : porte ouverte")
	for index: int in QUIZ.size():
		await _play.talk(QUIZ[index][0], Vector2i.UP, QUIZ[index][1])
		_play.expect(GameState.flags.has_flag(StringName("cinnabar_gym_gate_%d" % (index + 1))),
			"machine %d : bonne réponse, porte ouverte" % (index + 1))
	_play.heal()
	await _play.talk_to(Vector2i(3, 3))
	_play.expect(_play.won(&"cinnabar_gym_blaine"), "Auguste battu")
	_play.expect_flags(["badge_volcano", "tm38_received"], "Badge Volcan et CT38")
	assert_true(_play.report())
	assert_push_error_count(0)


func test_09d_arene_de_jadielle_a_pied() -> void:
	_play.begin("Arène de Jadielle : de l'entrée à Giovanni")
	await _play.start(DEBUG % "viridian_gym", _play.make_ace)
	await _play.walk_through(Vector2i(4, 4))
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
func _teach(species: StringName, move: StringName, pp: int) -> void:
	for pokemon: Pokemon in GameState.party.get_all():
		if pokemon.species_id == species:
			if pokemon.moves.size() >= 4:
				pokemon.moves.remove_at(pokemon.moves.size() - 1)
			pokemon.moves.append(MoveSlot.new(move, pp))
			return
