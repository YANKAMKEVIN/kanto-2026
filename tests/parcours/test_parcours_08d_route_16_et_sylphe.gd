extends GutTest
## Parcours 08 — Progression à pied, tronçons f, g (découpé pour équilibrer les lots de la CI).
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
	_play = ParcoursPlay.new(self, "08d_route_16_et_sylphe")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_08f_route_16_et_piste_cyclable() -> void:
	_play.begin("Route 16 : Ronflex")
	await _play.start(DEBUG % "snorlax_16_qa", func() -> void:
		_play.make_ace()
		_play.shortcut(["got_bike_voucher", "got_bicycle"], "Bon Commande et Bicyclette (tests J22)",
			{"bicycle": 1}))
	await _play.walk_through(Vector2i(26, 22))
	var outcome := await _play.catch_with(Vector2i.LEFT, &"poke_ball")
	_play.expect(outcome in [Battle.Outcome.WIN, Battle.Outcome.CAUGHT, Battle.Outcome.FLED,
		Battle.Outcome.FOE_FLED], "Ronflex réveillé et combattu (issue %d)" % outcome)
	_play.expect(GameState.flags.has_flag(&"snorlax_route_16_done"), "Ronflex parti")

	_play.begin("Poste et Piste Cyclable jusqu'à Parmanie")
	await _play.travel_all([&"route_16_gate", &"route_16_west", &"route_17", &"route_18"])
	await _play.travel(&"route_18_gate")
	await _play.travel(&"route_18", 4, true, Vector2i(11, 5))
	await _play.travel(&"fuchsia_city")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


func test_08g_safrania_et_sylphe_1f_5f() -> void:
	_play.begin("Poste de la Route 8 : boisson au garde")
	await _play.start(DEBUG % "saffron_gate", _play.make_ace)
	await _play.talk_to(Vector2i(4, 2))
	_play.expect(GameState.flags.has_flag(&"saffron_gates_open"), "garde désaltéré")
	await _play.travel(&"saffron_city")

	_play.begin("Sylphe SARL 1F à 5F, Carte Magnétique")
	await _play.travel_all([&"silph_co_1f", &"silph_co_2f", &"silph_co_3f", &"silph_co_5f"])
	# Le couloir sud de la Carte (5F, rangée 16) ne s'atteint pas à pied depuis le nord : deux
	# Dresseurs gardent ses deux accès d'une case de large (8, 16) et (28, 4). Chemin : ascenseur
	# jusqu'au 9F, téléporteur (17, 15) du 9F → 5F (9, 15), au bout du couloir sud.
	await _play.travel(&"silph_co_elevator")
	await _play.walk_through(Vector2i(3, 1))
	await _play.interact(Vector2i.UP)
	var elevator := _play.boot.get_elevator_director()
	await wait_until(func() -> bool: return elevator.is_panel_open(), 5.0)
	_play.expect(elevator.is_panel_open(), "panneau de l'ascenseur ouvert (sans clé)")
	if elevator.is_panel_open():
		elevator.get_panel().floor_chosen.emit(&"9f")
		await _play.wait_stable()
	await _play.travel(&"silph_co_9f")
	await _play.travel(&"silph_co_5f", 4, true, Vector2i(17, 15))
	_play.expect(_play.player.get_cell() == Vector2i(9, 15), "téléporteur du 9F → 5F (9, 15)")
	await _play.step(Vector2i.DOWN)
	if not _play.boot.is_stable():
		await _play.run_scene()
	await _play.talk(Vector2i(20, 16), Vector2i.RIGHT)
	_play.expect(GameState.flags.has_flag(&"got_silph_co_5f_card_key"), "Carte Magnétique ramassée")
	_play.expect(GameState.bag.has(&"card_key"), "Carte dans le Sac")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


## Fouille la poubelle [param slot] (1 à 15, rangée par rangée) depuis la case du dessous.
