extends GutTest
## JOH5 (`docs/tech/jalon-joh5.md` §2.3 à §2.5, §2.7 ; dossier JOH-06 §4, §7, §11) : la Tour Radio
## jouée dans le **vrai Boot** (pilote `hideout_play.gd` : vraies entrées, combats pilotés) :
## - de la porte au départ d'Orme : faux employé (Carte d'accès, combat), Sbires inévitables,
##   réserve (clé du gardien, Raphaël), Cenere, Dante, bureau, retour de l'équipe **sans écran**
##   (6 Pokémon en tout), Multi Exp, puis l'Agente (preuves retirées du Sac) et Orme (`johto_act2`) ;
## - écran du choix des 6 (9 Pokémon) : application tuée pendant l'écran → rien d'écrit,
##   l'équipe reste confisquée, la scène rejoue ; VALIDER → T-29, une écriture, reprise sur le
##   fichier = acte 1 fini ;
## - Multi Exp déjà possédée : 3 Super Bonbons ; œuf non éclos rendu avec l'équipe ;
## - défaite contre Cenere : réveil, Cenere toujours là.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/johto_radio_tower.json"
const START_5F := "res://tools/debug_start/johto_radio_tower_5f.json"
const START_OFFICE := "res://tools/debug_start/johto_radio_tower_office.json"
const START_SMALL := "res://tools/debug_start/johto_radio_tower_small.json"
const TIMEOUT_MS := 30000

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_joh5_story_save.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


## Marche jusqu'à [param goal] ; un Dresseur qui arrête le joueur est combattu, puis on repart.
func _go(goal: Vector2i) -> void:
	for attempt: int in 6:
		if _play.player.get_cell() == goal:
			return
		await _play.walk_to(goal)
		if not _play.boot.is_stable():
			await _play.run_scene()
	assert_eq(_play.player.get_cell(), goal, "arrivé en %s" % goal)


## Un pas (passage ou déclencheur), puis la scène éventuelle jusqu'au bout.
func _step(direction: Vector2i) -> void:
	await _play.step(direction)
	if not _play.boot.is_stable():
		await _play.run_scene()


## Fait défiler les pages jusqu'à [param done] (écran du choix des 6 ouvert, par exemple).
func _advance_until(done: Callable) -> void:
	var box := _play.boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not done.call() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			var page := "page:" + box.get_text().replace("\n", " ")
			if _play.events.is_empty() or _play.events.back() != page:
				_play.events.append(page)
			box.advance_requested.emit()
		await wait_process_frames(1)


func _overlay() -> TeamReturnOverlay:
	return _play.boot._team_return_overlay


## Trois Salamèche N60 (Flammèche) : gagnent tout, même contre Prélèvem. Destin du Qulbutoké ;
## l'équipe confisquée réduite à 3 : 6 Pokémon en tout, pas d'écran (dossier §7.3).
func _strong() -> void:
	_play.make_strong()
	for i: int in 2:
		var extra := PokemonFactory.create(_play.boot.get_pokemon_data(), &"charmander", 60,
			GameState.rng)
		extra.moves.clear()
		extra.moves.append(MoveSlot.new(&"ember", 25))
		GameState.party.add(extra)
	GameState.confiscated.party.resize(3)


func test_from_the_hall_to_the_return_of_the_team_and_orme() -> void:
	await _play.start(START, _strong)
	assert_eq(_play.map_id(), &"goldenrod_radio_tower_1f")
	assert_true(GameState.flags.has_flag(&"johto_act1"), "acte 1")
	# 1F : le faux employé (JH-40).
	await _go(Vector2i(3, 3))
	await _step(Vector2i.UP)
	assert_true(GameState.flags.has_flag(&"johto_radio_impostor_defeated"), "faux employé battu")
	assert_true(_play.pages().has("C'est la carte de Brace ! Comment tu l'as eue ?"), "T-2")
	assert_true(_play.pages().has("Le faux employé arrache son uniforme et file dans l'escalier !"))
	assert_null(_play.boot.get_map().get_npc(&"faux_employe"), "il s'est enfui")
	await _go(Vector2i(3, 1))
	await _step(Vector2i.UP)
	# 2F : Sbire I, inévitable.
	assert_eq(_play.map_id(), &"goldenrod_radio_tower_2f")
	await _go(Vector2i(20, 1))
	assert_true(GameState.flags.has_flag(&"beaten_goldenrod_radio_tower_grunt_i"), "Sbire I")
	await _step(Vector2i.UP)
	# 3F : la réserve, fermée, puis le gardien, la clé, Raphaël.
	assert_eq(_play.map_id(), &"goldenrod_radio_tower_3f")
	await _go(Vector2i(16, 11))
	await _play.interact(Vector2i.RIGHT)
	assert_false(GameState.flags.has_flag(&"johto_radio_staff_freed"), "fermée sans la clé")
	await _go(Vector2i(13, 12))
	assert_true(GameState.flags.has_flag(&"beaten_goldenrod_radio_tower_keeper"), "gardien")
	assert_true(GameState.flags.has_flag(&"johto_radio_reserve_key"), "T-8 : la clé")
	await _go(Vector2i(16, 11))
	await _play.interact(Vector2i.RIGHT)
	assert_true(GameState.flags.has_flag(&"johto_radio_staff_freed"), "T-9")
	await _go(Vector2i(20, 11))
	await _play.interact(Vector2i.RIGHT)
	assert_true(GameState.flags.has_flag(&"johto_radio_staff_talked"), "T-11")
	assert_null(_play.boot.get_map().get_npc(&"raphael"), "Raphaël rentre chez lui")
	await _go(Vector2i(3, 1))
	await _step(Vector2i.UP)
	# 4F : Sbire O, devant l'escalier.
	assert_eq(_play.map_id(), &"goldenrod_radio_tower_4f")
	await _go(Vector2i(20, 1))
	assert_true(GameState.flags.has_flag(&"beaten_goldenrod_radio_tower_grunt_o"), "Sbire O")
	await _step(Vector2i.UP)
	# 5F : Cenere, Dante, les Sbires, le départ.
	assert_eq(_play.map_id(), &"goldenrod_radio_tower_5f")
	# Le pilote n'envoie pas le Pokémon suivant après un K.O. : équipe soignée avant Cenere.
	GameState.party.heal_all()
	await _go(Vector2i(12, 5))
	await _step(Vector2i.DOWN)
	assert_true(GameState.flags.has_flag(&"johto_cenere_defeated"), "Cenere battue")
	assert_true(GameState.flags.has_flag(&"johto_dante_revealed"), "Dante a parlé")
	assert_true(_play.events.has("vs:CENERE/Admin de la Team Rocket"), "grand combat")
	var pages := _play.pages()
	assert_true(pages.has("Je m'appelle Dante. Je dirigeais la Team Rocket bien avant lui."))
	assert_true(pages.has("Un chef qui gagne, c'est un chef. Je le suis."), "T-22")
	assert_true(pages.has("Cenere s'en va par l'escalier de secours…"), "T-23")
	assert_null(_play.boot.get_map().get_npc(&"cenere"), "Cenere est partie")
	# Le bureau : 1 + 5 Pokémon, pas d'écran (dossier §7.3).
	await _go(Vector2i(9, 2))
	await _play.step(Vector2i.LEFT)
	await _step(Vector2i.LEFT)
	assert_false(_overlay().is_open(), "pas d'écran à 6 Pokémon")
	assert_true(GameState.flags.has_flag(&"johto_team_returned"), "équipe rendue")
	assert_false(GameState.flags.has_flag(&"johto_act1"), "fin de l'acte 1")
	assert_false(GameState.flags.has_flag(&"storage_offline"), "Stockage reconnecté")
	assert_true(GameState.confiscated.is_empty())
	assert_eq(GameState.party.size(), 6)
	pages = _play.pages()
	assert_true(pages.has("Dracaufeu sort de sa Poké Ball et bondit vers Kevin !"), "T-27")
	assert_false(pages.has("Connexion rétablie ! Les autres Pokémon sont au Stockage."),
		"T-29 seulement si des Pokémon vont au Stockage")
	assert_true(pages.has("Kevin reçoit une Multi Exp !"), "T-31")
	assert_eq(GameState.bag.count_of(&"exp_all"), 1)
	assert_eq(GameState.bag.count_of(&"great_ball"), 7, "sacs fusionnés (T-30)")
	assert_true(GameState.flags.has_flag(&"radio_exp_share_given"))
	var saved := _play.saved()
	assert_true((saved.get("flags", []) as Array).has("johto_team_returned"), "écrite")
	assert_false(saved.has("confiscated"))
	# 1F : l'Agente et Orme (T-33, T-34).
	await SceneRouter.change_map(&"goldenrod_radio_tower_1f", &"from_2f", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_not_null(_play.boot.get_map().get_npc(&"orme"), "Orme attend")
	await _go(Vector2i(3, 11))
	await _step(Vector2i.DOWN)
	assert_true(GameState.flags.has_flag(&"johto_act2"), "acte 2")
	assert_eq(GameState.bag.count_of(&"mission_order"), 0, "Ordre de mission remis")
	assert_eq(GameState.bag.count_of(&"radio_card"), 0, "Carte d'accès remise")
	assert_true(_play.pages().has("Je crois que c'est à propos de la Tour Cendrée."), "T-34")


func test_choice_screen_survives_a_kill_then_writes_once() -> void:
	await _play.start(START_OFFICE)
	assert_eq(GameState.party.size() + GameState.confiscated.party.size(), 9)
	var stored_before := GameState.storage.size()
	await _go(Vector2i(9, 2))
	await _play.step(Vector2i.LEFT)
	await _play.step(Vector2i.LEFT)
	await _advance_until(func() -> bool: return _overlay().is_open())
	assert_true(_overlay().is_open(), "écran du choix des 6")
	assert_true(_play.pages().has("Ces Poké Balls… ils les gardaient comme un trésor. Elles sont à toi ?"))
	assert_false((_play.saved().get("flags", []) as Array).has("johto_team_returned"),
		"rien d'écrit avant VALIDER")
	# Application tuée pendant l'écran : la partie reprend avec l'équipe confisquée.
	await _play.resume()
	assert_eq(GameState.confiscated.party.size(), 5, "jamais d'équipe perdue")
	assert_false(GameState.flags.has_flag(&"johto_team_returned"))
	assert_eq(_play.map_id(), &"goldenrod_radio_tower_5f")
	await _go(Vector2i(9, 2))
	await _play.step(Vector2i.LEFT)
	await _play.step(Vector2i.LEFT)
	await _advance_until(func() -> bool: return _overlay().is_open())
	assert_true(_overlay().is_open(), "la scène rejoue")
	_overlay().get_confirm_button().pressed.emit()
	await _play.run_scene()
	assert_eq(GameState.party.size(), 6)
	assert_eq(GameState.storage.size(), stored_before + 3, "les 3 autres au Stockage")
	assert_true(_play.pages().has("Connexion rétablie ! Les autres Pokémon sont au Stockage."),
		"T-29")
	assert_false(GameState.flags.has_flag(&"johto_return_stored"), "drapeau de travail baissé")
	var saved := _play.saved()
	assert_eq((saved.get("party", []) as Array).size(), 6)
	assert_false(saved.has("confiscated"))
	# Reprise sur le fichier écrit : l'acte 1 est fini.
	await _play.resume()
	assert_true(GameState.flags.has_flag(&"johto_team_returned"))
	assert_true(GameState.flags.has_flag(&"radio_exp_share_given"))
	assert_false(GameState.flags.has_flag(&"johto_act1"))
	assert_false(GameState.flags.has_flag(&"storage_offline"))
	assert_eq(GameState.party.size(), 6)
	assert_eq(GameState.bag.count_of(&"exp_all"), 1)


func _add_egg() -> void:
	var egg := EggRules.create(_play.boot.get_pokemon_data(), &"togepi", 800, GameState.rng)
	GameState.party.add(egg)


func test_exp_share_already_owned_gives_candies_and_the_egg_comes_back() -> void:
	await _play.start(START_SMALL, _add_egg)
	assert_eq(GameState.party.size() + GameState.confiscated.party.size(), 6, "2 + œuf + 3")
	var candies := GameState.bag.count_of(&"rare_candy")
	await _go(Vector2i(9, 2))
	await _play.step(Vector2i.LEFT)
	await _step(Vector2i.LEFT)
	assert_false(_overlay().is_open(), "pas d'écran")
	assert_true(GameState.flags.has_flag(&"johto_team_returned"))
	assert_eq(GameState.party.size(), 6)
	var eggs := 0
	for pokemon: Pokemon in GameState.party.get_all():
		if pokemon.egg_steps > 0:
			eggs += 1
	assert_eq(eggs, 1, "l'œuf non éclos revient dans l'équipe")
	assert_eq(GameState.bag.count_of(&"rare_candy"), candies + 3, "T-31 : 3 Super Bonbons")
	assert_eq(GameState.bag.count_of(&"exp_all"), 1, "pas de seconde Multi Exp")
	assert_true(_play.pages().has("Tu en as déjà une ? Alors prends ces bonbons."))


func test_defeat_against_cenere_keeps_her_at_the_microphone() -> void:
	await _play.start(START_5F, func() -> void: _play.make_weak())
	await _go(Vector2i(12, 5))
	await _step(Vector2i.DOWN)
	assert_false(GameState.flags.has_flag(&"johto_cenere_defeated"))
	assert_false(GameState.flags.has_flag(&"johto_dante_revealed"))
	assert_ne(_play.map_id(), &"goldenrod_radio_tower_5f", "réveil au point de repos")
	assert_true(GameState.flags.has_flag(&"beaten_goldenrod_radio_tower_grunt_o"),
		"étages nettoyés")
	await SceneRouter.change_map(&"goldenrod_radio_tower_5f", &"from_4f", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_not_null(_play.boot.get_map().get_npc(&"cenere"), "Cenere toujours au micro")
