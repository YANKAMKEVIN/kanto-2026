extends GutTest
## Parcours 02 — Progression (jalon 33, T5 ; `docs/design/passes/j33-v1-chatgpt.md` §7 : villes,
## Arènes, rival, Team Rocket, CS), une seule partie sur la vraie Boot ([ParcoursPlay]), partie
## du départ `rival_cerulean` (Badge Roche) jusqu'au Badge Marais :
## rival d'Azuria → Ondine → rival du S.S. Anne → capitaine (CS01) → arbuste coupé → Major Bob →
## Erika → Giovanni au repaire (Scope Sylphe) → rival de la Tour → Ossatueur → Fuji (Poké Flûte)
## → Ronflex de la Route 12 → Koga → rival de la Sylphe → Giovanni à la Sylphe (Master Ball) →
## Morgane. Les Dresseurs d'Arène et de la Tour qui repèrent le joueur sont combattus pour de
## vrai ; les tronçons sautés (marche entre deux villes, Bill, puzzles) sont des raccourcis notés.

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const START := "res://tools/debug_start/rival_cerulean.json"

var _play: ParcoursPlay


func before_each() -> void:
	_play = ParcoursPlay.new(self, "02_progression")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_parcours_02_azuria_a_safrania() -> void:
	_play.begin("Route 24 : rival d'Azuria")
	await _play.start(START, _play.make_ace)
	await _play.walk_through(Vector2i(32, 56))
	await _play.walk_through(Vector2i(32, 55))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(GameState.flags.has_flag(&"rival_cerulean_won"), "rival d'Azuria battu")

	await _gym("Arène d'Azuria", &"cerulean_gym", &"entrance", Vector2i(7, 3), Vector2i.RIGHT,
		&"cerulean_gym_misty", ["badge_cascade", "tm11_received"],
		["cerulean_reached", "misty_invited"], "Azuria, invitation d'Ondine")

	_play.begin("S.S. Anne : rival et capitaine")
	_play.shortcut(["bill_met", "bill_restored", "got_ss_ticket",
		"ss_anne_gangway_open"], "Pont Pépite, Cap d'Azuria (Bill), Route 5 à 6, passerelle",
		{"ss_ticket": 1})
	await _play.jump(&"ss_anne_captain_corridor", &"entrance", Vector2i.UP)
	await _play.walk_through(Vector2i(7, 4))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(GameState.flags.has_flag(&"rival_ss_anne_won"), "rival du S.S. Anne battu")
	await _play.jump(&"ss_anne_captain_room", &"entrance", Vector2i.UP)
	await _play.talk(Vector2i(8, 4), Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"got_hm01"), "CS01 reçue")
	_play.expect(GameState.bag.has(&"hm01"), "CS01 dans le Sac")

	_play.begin("Carmin : arbuste de l'Arène coupé")
	_play.shortcut(["ss_anne_departed"], "descente du navire, départ du S.S. Anne")
	await _play.jump(&"vermilion_city", &"gym_tree", Vector2i.UP)
	await _play.interact(Vector2i.UP, true)
	_play.expect(GameState.flags.has_flag(&"cut_vermilion_gym_bush"), "arbuste coupé (Coupe)")

	await _gym("Arène de Carmin", &"vermilion_gym", &"entrance", Vector2i(8, 4), Vector2i.UP,
		&"vermilion_gym_surge", ["badge_thunder", "tm24_received"],
		["vermilion_gym_puzzle_solved"], "puzzle des poubelles (ses tests : J16)")

	await _gym("Arène de Céladopole", &"celadon_gym", &"entrance", Vector2i(8, 3), Vector2i.UP,
		&"celadon_gym_erika", ["badge_rainbow", "tm21_received"],
		["route_9_entered", "dark_cave_crossed", "route_10_reached", "lavender_reached",
			"route_8_reached", "celadon_reached", "tower_stairs_open", "cut_celadon_gym_bush",
			"cut_celadon_gym_inner_bush"], "Routes 9 et 10, Grotte Sombre, Lavanville, Route 8")

	_play.begin("Repaire Rocket : Giovanni, Scope Sylphe")
	_play.shortcut(["game_corner_switch", "beaten_celadon_game_corner_rocket",
		"beaten_rocket_hideout_b1f_1", "beaten_rocket_hideout_b1f_2", "beaten_rocket_hideout_b1f_3",
		"beaten_rocket_hideout_b2f_1", "beaten_rocket_hideout_b3f_1", "beaten_rocket_hideout_b3f_2",
		"beaten_rocket_hideout_b4f_guard_1", "beaten_rocket_hideout_b4f_guard_2",
		"beaten_rocket_hideout_b4f_key", "rocket_dropped_lift_key",
		"got_rocket_hideout_b4f_lift_key", "rocket_hideout_b4f_door_open"],
		"Casino, étages B1F à B4F, dalles et ascenseur (tests J20)", {"lift_key": 1})
	await _play.jump(&"rocket_hideout_b4f", &"from_elevator", Vector2i.UP)
	_play.heal()
	await _play.talk(Vector2i(24, 3), Vector2i.RIGHT)
	_play.expect_flags(["giovanni_met", "giovanni_hideout_won"], "Giovanni battu")
	await _play.talk(Vector2i(25, 3), Vector2i.UP)
	_play.expect(GameState.bag.has(&"silph_scope"), "Scope Sylphe dans le Sac")

	_play.begin("Tour Pokémon : rival, Ossatueur, Fuji")
	await _play.jump(&"pokemon_tower_2f", &"arrivee_T12", Vector2i.LEFT)
	for cell: Vector2i in [Vector2i(17, 7), Vector2i(14, 7), Vector2i(14, 6)]:
		await _play.walk_through(cell)
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(GameState.flags.has_flag(&"rival_tower_won"), "rival de la Tour battu")
	_play.shortcut(["tower_ghost_met"], "3F à 5F (Exorcistes, zone purifiée : tests J19)")
	await _play.jump(&"pokemon_tower_6f", &"devant_spectre", Vector2i.DOWN)
	_play.heal()
	await _play.walk_through(Vector2i(10, 16))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect_flags(["ghost_marowak_calmed", "tower_6f_mist_lifted"], "Ossatueur apaisé")
	await _play.jump(&"pokemon_tower_7f", &"arrivee_T67", Vector2i.RIGHT)
	await _play.talk(Vector2i(10, 4), Vector2i.UP)
	await _play.wait_stable()
	_play.expect(GameState.flags.has_flag(&"fuji_rescued"), "Fuji sauvé (Rockets du 7F battus)")
	_play.expect(_play.map_id() == &"pokemon_house", "chez Fuji")
	if not GameState.bag.has(&"poke_flute"):
		await _play.talk(Vector2i(7, 4), Vector2i.UP)
	_play.expect(GameState.bag.has(&"poke_flute"), "Poké Flûte reçue")

	_play.begin("Route 12 : Ronflex")
	_play.shortcut([], "nord de la Route 12 et son poste (arrivée au sud du poste)")
	await _play.jump(&"route_12", &"from_poste_sud", Vector2i.DOWN)
	await _play.walk_through(Vector2i(25, 92))
	var snorlax := await _play.catch_with(Vector2i.DOWN, &"poke_ball")
	_play.expect(snorlax in [Battle.Outcome.WIN, Battle.Outcome.CAUGHT],
		"Ronflex réveillé et combattu (issue %d)" % snorlax)
	_play.expect(GameState.flags.has_flag(&"snorlax_route_12_done"), "Ronflex parti")
	_play.expect(not _play.boot.get_map().get_grid().is_occupied(Vector2i(25, 93)),
		"passage libre")

	await _gym("Arène de Parmanie", &"fuchsia_gym", &"entree", Vector2i(6, 12), Vector2i.UP,
		&"fuchsia_gym_koga", ["badge_soul", "tm06_received"],
		["snorlax_route_16_done", "got_bicycle"],
		"Route 16 (Ronflex 2, ses tests), Piste Cyclable, Parmanie")

	_play.begin("Sylphe SARL : rival et Giovanni")
	_play.shortcut(["saffron_gates_open", "got_silph_co_5f_card_key"],
		"Safrania (boisson aux gardes), 1F à 6F, Carte Magnétique (tests J26)", {"card_key": 1})
	await _play.jump(&"silph_co_7f", &"tp_5", Vector2i.LEFT)
	_play.heal()
	await _play.walk_through(Vector2i(3, 3))
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(GameState.flags.has_flag(&"rival_silph_won"), "rival de la Sylphe battu")
	await _play.jump(&"silph_co_11f", &"tp_4", Vector2i.DOWN)
	_play.heal()
	# Porte électronique du bureau (6-7, 13) : ouverte avec la Carte, puis on entre.
	await _play.talk(Vector2i(6, 14), Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"door_silph_co_11f_d1_open"), "porte du bureau ouverte")
	await _play.step(Vector2i.UP)
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(GameState.flags.has_flag(&"silph_giovanni_defeated"), "Giovanni battu")
	await _play.talk(Vector2i(6, 5), Vector2i.RIGHT)
	_play.expect(GameState.bag.has(&"master_ball"), "Master Ball du président")

	await _gym("Arène de Safrania", &"saffron_gym", &"tp_19", Vector2i(9, 9), Vector2i.UP,
		&"saffron_gym_sabrina", ["badge_marsh", "tm46_received"], [], "")

	_play.begin("Bilan et relance")
	_play.expect_flags(["badge_boulder", "badge_cascade", "badge_thunder", "badge_rainbow",
		"badge_soul", "badge_marsh"], "six Badges")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)


## Arène : raccourci éventuel, entrée, Dresseurs croisés combattus, champion battu.
func _gym(label: String, map_id: StringName, spawn: StringName, talk_cell: Vector2i,
		facing: Vector2i, leader: StringName, flags: Array, skipped: Array,
		reason: String) -> void:
	_play.begin(label)
	if not skipped.is_empty():
		_play.shortcut(skipped, reason)
	await _play.jump(map_id, spawn, Vector2i.UP)
	_play.heal()
	await _play.talk(talk_cell, facing)
	_play.expect(_play.won(leader), "%s battu" % leader)
	_play.expect_flags(flags, "Badge et CT")
