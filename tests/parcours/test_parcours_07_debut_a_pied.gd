extends GutTest
## Parcours 07 — Début à pied (jalon 33, T6 préparation) : les raccourcis du parcours 01
## (prologue, Route 1, Route 2, Forêt de Jade) rejoués sur la vraie Boot ([ParcoursPlay]), sans
## aucun saut entre deux cartes sauf le retour au labo pour le colis (rejoué par le parcours 01) :
## chambre → escalier → Maman → Bourg Palette → maison du rival → herbes de la Route 1 (scène de
## Chen, labo) → starter et rival → Route 1 à pied → arrivée à Jadielle (scène) → colis →
## Pokédex → Route 2 → poste sud → Forêt de Jade (Dresseurs) → poste nord → Argenta (scène
## d'arrivée) → relance. Les rencontres sauvages en chemin sont jouées (Mewtwo en tête après le
## choix du starter : le parcours vérifie les enchaînements, pas l'équilibrage).

const ParcoursPlay := preload("res://tests/parcours/parcours_play.gd")
const STARTER_COLUMN := 10
const OAK_TALK := Vector2i(8, 5)
const RIVAL_CELL := Vector2i(13, 4)

var _play: ParcoursPlay


func before_each() -> void:
	_play = ParcoursPlay.new(self, "07_debut_a_pied")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_parcours_07_chambre_a_argenta_a_pied() -> void:
	_play.begin("Chambre, Maman, Bourg Palette")
	await _play.start_new(&"player_house_2f", &"start", Vector2i.DOWN)
	await _play.travel(&"player_house_1f")
	_play.expect(GameState.flags.has_flag(&"mom_greeted"), "Maman salue le joueur")
	await _play.travel(&"pallet_town")
	await _play.travel(&"rival_house")
	await _play.talk_to(RIVAL_CELL)
	_play.expect(GameState.flags.has_flag(&"rival_met"), "rival rencontré chez lui")
	await _play.travel(&"pallet_town")

	_play.begin("Route 1 : Chen arrête le joueur, labo")
	# Le déclencheur des herbes est au nord de Bourg Palette : la scène emmène au labo.
	await _play.travel(&"route_1", 2, false)
	await _play.wait_stable()
	_play.expect(_play.map_id() == &"oak_lab", "Chen ramène le joueur au labo (%s)"
		% _play.map_id())
	_play.expect_flags(["oak_met", "oak_lab_reunion", "starter_offered"], "scène de Chen jouée")

	_play.begin("Labo : starter et rival")
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
	_play.expect_flags(["starter_chosen", "rival_battle_done", "rival_left_lab"],
		"starter choisi, rival du labo joué")
	_play.make_ace()

	_play.begin("Route 1 à pied jusqu'à Jadielle")
	await _play.travel_all([&"pallet_town", &"route_1", &"viridian_city"])
	# La scène d'arrivée part sur la rangée 23 (couloir de la Route 1, pas vers le nord).
	await _play.walk_through(Vector2i(28, 23))
	_play.expect(GameState.flags.has_flag(&"viridian_arrived"), "scène d'arrivée à Jadielle")

	_play.begin("Jadielle : colis, Pokédex")
	await _play.travel(&"viridian_mart")
	for attempt: int in 6:
		if GameState.flags.has_flag(&"got_oak_parcel"):
			break
		await _play.step(Vector2i.UP)
		if not _play.boot.is_stable():
			await _play.run_scene()
	_play.expect(GameState.flags.has_flag(&"got_oak_parcel"), "colis reçu")
	_play.shortcut([], "retour au labo par la Route 1 (déjà marchée ; colis remis : parcours 01)")
	await _play.jump(&"oak_lab", &"entrance", Vector2i.UP)
	await _play.talk(OAK_TALK, Vector2i.UP)
	_play.expect(GameState.flags.has_flag(&"pokedex_activated"), "Pokédex activé")
	await _play.jump(&"viridian_city", &"from_mart", Vector2i.DOWN)

	_play.begin("Route 2 et Forêt de Jade à pied")
	await _play.travel_all([&"route_2", &"viridian_forest_gate_south"])
	_play.expect(GameState.flags.has_flag(&"poison_unlocked"), "garde du poste sud (poison)")
	await _play.travel_all([&"viridian_forest", &"viridian_forest_gate_north", &"route_2_north",
		&"pewter_city"])
	# Scène d'arrivée : un pas vers le nord sur la rangée 42 (colonnes 17 à 19).
	await _play.walk_through(Vector2i(18, 42))
	_play.expect(GameState.flags.has_flag(&"pewter_arrived"), "arrivée à Argenta")
	var trainers := _play.battles.filter(func(b: Dictionary) -> bool:
		return str(b["trainer"]) != "")
	_play.expect(_play.battles.all(func(b: Dictionary) -> bool:
		return b["outcome"] != Battle.Outcome.LOSS), "aucun combat perdu (%d combats, dont %d de Dresseur)"
		% [_play.battles.size(), trainers.size()])

	_play.begin("Relance")
	await _play.persist()
	assert_true(_play.report())
	assert_push_error_count(0)
