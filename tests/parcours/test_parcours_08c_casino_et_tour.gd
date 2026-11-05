extends GutTest
## Parcours 08 — Progression à pied, tronçons d, e (découpé pour équilibrer les lots de la CI).
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
	_play = ParcoursPlay.new(self, "08c_casino_et_tour")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_08d_casino_et_repaire() -> void:
	_play.begin("Casino : sbire, affiche, escalier")
	await _play.start(DEBUG % "game_corner", _play.make_ace)
	await _play.talk(Vector2i(10, 5), Vector2i.LEFT)
	_play.expect(GameState.flags.has_flag(&"beaten_celadon_game_corner_rocket"), "sbire battu")
	await _play.talk(Vector2i(9, 5), Vector2i.UP, true)
	_play.expect(GameState.flags.has_flag(&"game_corner_switch"), "interrupteur de l'affiche")
	await _play.travel(&"rocket_hideout_b1f")

	_play.begin("Repaire B1F à B3F")
	await _play.travel(&"rocket_hideout_b2f", 4, true, Vector2i(23, 2))
	await _play.travel(&"rocket_hideout_b3f", 4, true, Vector2i(21, 8))
	# Dalles tournantes du B3F vers l'escalier du B4F (plan `repaire_b3f.txt`).
	for arrow: Vector2i in [Vector2i(12, 11), Vector2i(10, 13), Vector2i(11, 18)]:
		await _play.walk_to(arrow)
		await wait_process_frames(3)
		if not _play.boot.is_stable():
			await _play.run_scene()
	_play.expect(_play.player.get_cell() == Vector2i(15, 22),
		"dalles : arrêt en (15, 22) (case %s)" % _play.player.get_cell())
	await _play.travel(&"rocket_hideout_b4f", 4, true, Vector2i(19, 18))

	_play.begin("Repaire B4F : Clé Ascenseur")
	await _play.walk_through(Vector2i(11, 3))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(GameState.flags.has_flag(&"beaten_rocket_hideout_b4f_key"), "sbire de la clé battu")
	await _play.interact(Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"rocket_dropped_lift_key"), "il lâche la clé")
	await _play.talk(Vector2i(10, 3), Vector2i.UP)
	_play.expect(GameState.bag.has(&"lift_key"), "Clé Ascenseur dans le Sac")

	_play.begin("Ascenseur, gardes, porte du bureau, Giovanni")
	_play.shortcut([], "retour à pied du B4F ouest à l'ascenseur du B1F")
	await _play.jump(&"rocket_hideout_b1f", &"from_elevator", Vector2i.DOWN)
	await _play.travel(&"rocket_hideout_elevator")
	await _play.walk_through(Vector2i(1, 2))
	await _play.interact(Vector2i.UP)
	var elevator := _play.boot.get_elevator_director()
	await wait_until(func() -> bool: return elevator.is_panel_open(), 5.0)
	_play.expect(elevator.is_panel_open(), "panneau de l'ascenseur ouvert")
	if elevator.is_panel_open():
		elevator.get_panel().floor_chosen.emit(&"b4f")
		await _play.wait_stable()
		await _play.travel(&"rocket_hideout_b4f")
	await _play.talk(Vector2i(23, 13), Vector2i.UP)
	await _play.talk(Vector2i(26, 13), Vector2i.UP)
	_play.expect_flags(["beaten_rocket_hideout_b4f_guard_1", "beaten_rocket_hideout_b4f_guard_2",
		"rocket_hideout_b4f_door_open"], "deux gardes battus, porte ouverte")
	await _play.talk(Vector2i(24, 3), Vector2i.RIGHT)
	_play.expect(GameState.flags.has_flag(&"giovanni_hideout_won"), "Giovanni battu")
	await _play.talk(Vector2i(25, 3), Vector2i.UP)
	_play.expect(GameState.bag.has(&"silph_scope"), "Scope Sylphe")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


func test_08e_tour_3f_a_6f() -> void:
	_play.begin("Tour Pokémon 3F, 4F, 5F")
	await _play.start(DEBUG % "tower_scope", _play.make_ace)
	await _play.travel(&"pokemon_tower_4f")
	await _play.travel(&"pokemon_tower_5f")
	_play.expect(GameState.flags.has_flag(&"beaten_tower_channeler_3"),
		"Exorciste inévitable du 4F battue")
	_play.begin("Zone purifiée du 5F")
	GameState.party.get_all()[0].hp = 1
	await _play.walk_through(Vector2i(10, 9))
	if not _play.boot.is_stable():
		await _play.run_scene()
	var lead: Pokemon = GameState.party.get_all()[0]
	_play.expect(lead.hp == lead.max_hp(), "équipe soignée par la zone")
	await _play.travel(&"pokemon_tower_6f")
	_play.expect(_play.map_id() == &"pokemon_tower_6f", "arrivée au 6F")
	assert_true(_play.report())
	assert_push_error_count(0)
