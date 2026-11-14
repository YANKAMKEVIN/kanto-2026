extends GutTest
## Parcours 09 — Donjons à pied, tronçons a, b, c (découpé pour équilibrer les lots de la CI).
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
const SAFFRON_HOPS: Array[Array] = [[Vector2i(12, 15), Vector2i(20, 17)],
	[Vector2i(16, 15), Vector2i(20, 3)], [Vector2i(16, 5), Vector2i(2, 3)],
	[Vector2i(2, 5), Vector2i(12, 11)]]
## Quiz de Cramois'Île : case devant la machine (tournée vers le haut) et bonne réponse.
const QUIZ: Array[Array] = [[Vector2i(15, 8), true], [Vector2i(10, 2), false],
	[Vector2i(9, 8), false], [Vector2i(9, 14), false], [Vector2i(1, 14), true],
	[Vector2i(1, 8), false]]


var _play: ParcoursPlay
var _teleport_fade := 0.0


func before_each() -> void:
	_teleport_fade = SceneRouter.teleport_fade_duration
	SceneRouter.teleport_fade_duration = 0.05
	_play = ParcoursPlay.new(self, "09a_safrania_manoir_quiz")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_09a_arene_de_safrania_teleporteurs() -> void:
	_play.begin("Arène de Safrania : téléporteurs jusqu'à Morgane")
	await _play.start(DEBUG % "saffron_gym", _play.make_ace)
	for hop: Array in SAFFRON_HOPS:
		# Téléporteur de la même carte : pas de changement de carte, on s'arrête à l'arrivée
		# (une nouvelle marche vers le téléporteur partirait de l'autre salle).
		for attempt: int in 4:
			await _play.walk_to(hop[0])
			await wait_process_frames(3)
			if not _play.boot.is_stable():
				await _play.run_scene()
			await _play.wait_stable()
			if _play.player.get_cell() == hop[1]:
				break
		await wait_process_frames(20)
		_play.expect(_play.player.get_cell() == hop[1], "téléporteur %s → %s (case %s)"
			% [hop[0], hop[1], _play.player.get_cell()])
	_play.heal()
	await _play.talk(Vector2i(10, 9), Vector2i.UP)
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
	# Porte fermée : la Clé Secrète l'ouvre quand le joueur la pousse (25, 5).
	await _play.walk_through(Vector2i(25, 6))
	await _play.step(Vector2i.UP)
	if not _play.boot.is_stable():
		await _play.run_scene()
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
