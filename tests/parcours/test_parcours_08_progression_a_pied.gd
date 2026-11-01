extends GutTest
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
	_play = ParcoursPlay.new(self, "08_progression_a_pied")
	_play.setup()


func after_each() -> void:
	SceneRouter.teleport_fade_duration = _teleport_fade
	_play.teardown()


func test_08a_pont_pepite_route_25_et_bill() -> void:
	_play.begin("Pont Pépite : cinq Dresseurs et le recruteur")
	await _play.start(DEBUG % "nugget_bridge", _play.make_ace)
	await _play.walk_through(Vector2i(33, 24))
	_play.expect_flags(["beaten_route_24_timeo", "beaten_route_24_alice", "beaten_route_24_malo",
		"beaten_route_24_romane", "beaten_route_24_ethan"], "cinq Dresseurs du pont battus")
	await _play.walk_through(Vector2i(33, 23))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect_flags(["got_nugget", "beaten_nugget_rocket"], "Pépite et recruteur battu")

	_play.begin("Route 25 à pied jusqu'à la maison de Léo")
	await _play.travel_all([&"route_25", &"bill_house"])

	_play.begin("Maison de Léo : Mélofée, écran, module, console")
	await _play.walk_through(Vector2i(7, 9))
	if not _play.boot.is_stable():
		await _play.run_scene()
	await _play.talk(Vector2i(6, 4), Vector2i.DOWN)
	_play.expect(GameState.flags.has_flag(&"bill_met"), "Mélofée parle (bill_met)")
	await _play.talk(Vector2i(5, 4), Vector2i.UP)
	await _play.talk(Vector2i(10, 4), Vector2i.UP)
	_play.expect_flags(["bill_screen_checked", "bill_module_checked", "bill_in_cabin"],
		"écran et module")
	await _play.talk(Vector2i(8, 4), Vector2i.UP)
	_play.expect_flags(["bill_restored", "got_ss_ticket"], "Léo rétabli, Passe Bateau")
	_play.expect(GameState.bag.has(&"ss_ticket"), "Passe Bateau dans le Sac")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


func test_08b_puzzle_de_carmin() -> void:
	_play.begin("Arène de Carmin : poubelles, barrière, Major Bob")
	await _play.start(DEBUG % "vermilion_gym_map", _play.make_ace)
	await _search_bin(13)
	var puzzle: Variant = _play.boot.get_active_puzzle(&"vermilion_gym")
	if not _play.expect(puzzle != null, "puzzle tiré à la première fouille"):
		assert_true(_play.report())
		return
	if not puzzle.is_first_found():
		await _search_bin(puzzle.first())
	_play.expect(puzzle.is_first_found(), "premier interrupteur trouvé")
	await _search_bin(puzzle.second())
	_play.expect(GameState.flags.has_flag(&"vermilion_gym_puzzle_solved"), "barrière ouverte")
	await _play.talk(Vector2i(8, 4), Vector2i.UP)
	_play.expect(_play.won(&"vermilion_gym_surge"), "Major Bob battu")
	_play.expect_flags(["badge_thunder", "tm24_received"], "Badge Foudre et CT24")
	assert_true(_play.report())
	assert_push_error_count(0)


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
	# RP-284 (P3) : la case de Giovanni (25, 3) redevient occupée au rechargement ; la relance
	# se fait à côté pour vérifier le reste de la partie.
	await _play.walk_through(Vector2i(24, 3))
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
func _search_bin(slot: int) -> void:
	var xs: Array[int] = [2, 5, 8, 11, 14]
	var ys: Array[int] = [7, 9, 11]
	var bin := Vector2i(xs[(slot - 1) % 5], ys[(slot - 1) / 5])
	await _play.talk(bin + Vector2i.DOWN, Vector2i.UP)
