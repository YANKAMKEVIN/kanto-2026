extends GutTest
## Parcours 01 — Début (jalon 33, T5 ; `docs/design/passes/j33-v1-chatgpt.md` §7 : starter,
## premières routes, première Arène), une seule partie sur la vraie Boot ([ParcoursPlay]) :
## - nouvelle partie au labo de Chen (prologue posé : il a ses tests, OUV et J3) ;
## - choix réel du starter (fiche, bouton CHOISIR), scène et combat du rival au labo ;
## - colis à la Boutique de Jadielle, remis à Chen : Pokédex activé ;
## - rival n° 2 sur la Route 22 ;
## - Arène d'Argenta, Dresseur compris, Pierre battu : Badge Roche ;
## - sauvegarde relue à l'identique après une relance.
## La Route 1 et la Forêt de Jade ne sont pas rejouées (raccourcis notés au journal).

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const STARTER := &"bulbasaur"
const STARTER_COLUMN := 10
const OAK_TALK := Vector2i(8, 5)
const ROUTE_22_PATH: Array[Vector2i] = [Vector2i(16, 15), Vector2i(16, 13), Vector2i(15, 13),
	Vector2i(14, 13)]
const BROCK_TALK := Vector2i(7, 3)

var _play: ParcoursPlay


func before_each() -> void:
	_play = ParcoursPlay.new(self, "01_debut")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_parcours_01_starter_colis_rival_pierre() -> void:
	_play.begin("Labo de Chen, choix du starter")
	await _play.start_new(&"oak_lab", &"entrance", Vector2i.UP, func() -> void:
		_play.shortcut(["mom_greeted", "rival_met", "oak_met", "oak_lab_reunion",
			"starter_offered"], "prologue (ouverture, chambre, Route 1 avec Chen)"))
	# Le starter est sur (colonne, 5) : le joueur s'arrête dessous et se tourne vers lui.
	await _play.walk_through(Vector2i(STARTER_COLUMN, 6))
	_play.player.face(Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var sheet := _play.boot.get_starter_sheet()
	await wait_until(func() -> bool: return sheet.is_open(), 5.0)
	_play.expect(sheet.is_open(), "fiche du starter ouverte")
	await wait_process_frames(5)
	sheet.get_choose_button().pressed.emit()
	await _play.run_scene()
	_play.expect(_play.party_species().has(STARTER), "Bulbizarre dans l'équipe")
	_play.expect(GameState.starter_species == STARTER, "starter de la partie")
	_play.expect_flags(["starter_chosen", "rival_battle_done", "rival_left_lab",
		"taken_bulbasaur", "taken_charmander"], "drapeaux du choix et du rival")
	var lab := _play.last_battle(&"rival_lab")
	_play.expect(lab.get("foe", []) == [&"charmander"], "le rival prend Salamèche")
	_play.expect(GameState.bag.count_of(&"poke_ball") == 5, "5 Poké Balls de Chen")

	_play.begin("Jadielle : colis à la Boutique")
	_play.shortcut(["viridian_arrived"], "Route 1 à pied et arrivée à Jadielle")
	await _play.jump(&"viridian_city", &"from_mart", Vector2i.DOWN)
	await _play.step(Vector2i.DOWN)
	# Porte, puis vers le comptoir : la scène de la première visite part en chemin.
	for attempt: int in 6:
		if GameState.flags.has_flag(&"got_oak_parcel"):
			break
		await _play.step(Vector2i.UP)
		if not _play.boot.is_stable():
			await _play.run_scene()
	_play.expect(_play.map_id() == &"viridian_mart", "dans la Boutique")
	_play.expect(GameState.flags.has_flag(&"got_oak_parcel"), "colis reçu")
	_play.expect(GameState.bag.has(&"oak_parcel"), "colis dans le Sac")

	_play.begin("Bourg Palette : colis remis, Pokédex")
	await _play.jump(&"oak_lab", &"entrance", Vector2i.UP)
	await _play.talk(OAK_TALK, Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"pokedex_activated"), "Pokédex activé")
	_play.expect(not GameState.bag.has(&"oak_parcel"), "colis remis")

	_play.begin("Route 22 : rival n° 2")
	_play.make_ace()
	await _play.jump(&"route_22", &"stair_foot", Vector2i.UP)
	for cell: Vector2i in ROUTE_22_PATH:
		await _play.walk_through(cell)
	if not _play.boot.is_stable():
		await _play.run_scene()
	_play.expect(_play.won(&"rival_route22"), "rival battu")
	_play.expect(GameState.flags.has_flag(&"rival_route22_won"), "rival_route22_won")
	_play.expect((_play.last_battle(&"rival_route22").get("foe", []) as Array).back()
		== &"charmander", "son Salamèche en dernier")

	_play.begin("Arène d'Argenta")
	_play.shortcut(["poison_unlocked", "pewter_arrived"], "Route 2 et Forêt de Jade")
	await _play.jump(&"pewter_gym", &"entrance", Vector2i.UP)
	await _play.talk(BROCK_TALK, Vector2i.UP)
	_play.expect(_play.won(&"pewter_gym_brock"), "Pierre battu")
	_play.expect_flags(["badge_boulder", "brock_met", "tm34_received"], "Badge Roche et CT34")
	_play.expect(GameState.bag.has(&"tm34"), "CT34 dans le Sac")
	_play.expect(_play.battles.size() >= 4, "combats joués : %s" % [_play.battles.map(
		func(b: Dictionary) -> StringName: return b["trainer"])])

	_play.begin("Relance")
	await _play.persist()
	_play.expect(GameState.flags.has_flag(&"badge_boulder"), "Badge relu")
	assert_true(_play.report())
	assert_push_error_count(0)
