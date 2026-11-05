extends GutTest
## JOH5 (`docs/tech/jalon-joh5.md` §2.3 à §2.5, §2.7 ; dossier JOH-06 §4, §7, §11) : la Tour Radio
## jouée dans le **vrai Boot** (pilote `hideout_play.gd` : vraies entrées, combats pilotés) :
## - de la porte au départ d'Orme : faux employé (Carte d'accès, combat), Sbires inévitables,
##   réserve (clé du gardien, Raphaël), Cenere, Dante (« Prends tout »), bureau **vide** (le retour de
##   l'équipe est à la fin de l'arc des Pierres : `test_johp3_story`, `test_johp3_resume`), papier,
##   Multi Exp, puis l'Agente (preuves retirées du Sac), Orme et la légende (`johto_stones_quest`) ;
## - Multi Exp déjà possédée : 3 Super Bonbons ;
## - défaite contre Cenere : réveil, Cenere toujours là.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/johto_radio_tower.json"
const START_5F := "res://tools/debug_start/johto_radio_tower_5f.json"
const START_SMALL := "res://tools/debug_start/johto_radio_tower_small.json"

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


## Trois Salamèche N60 (Flammèche) : gagnent tout, même contre Prélèvem. Destin du Qulbutoké.
func _strong() -> void:
	_play.make_strong()
	for i: int in 2:
		var extra := PokemonFactory.create(_play.boot.get_pokemon_data(), &"charmander", 60,
			GameState.rng)
		extra.moves.clear()
		extra.moves.append(MoveSlot.new(&"ember", 25))
		GameState.party.add(extra)


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
	assert_true(_play.events.has("battle"), "combat contre Cenere")
	var pages := _play.pages()
	assert_true(pages.has("Je m'appelle Dante. Je dirigeais la Team Rocket bien avant lui."))
	assert_true(pages.has("Un chef qui gagne, c'est un chef. Je le suis."), "T-22")
	assert_true(pages.has("Cenere s'en va par l'escalier de secours, une mallette à la main…"), "T-23")
	assert_null(_play.boot.get_map().get_npc(&"cenere"), "Cenere est partie")
	# Le bureau, vide : l'équipe reste confisquée.
	await _go(Vector2i(9, 2))
	await _play.step(Vector2i.LEFT)
	await _step(Vector2i.LEFT)
	assert_true(GameState.flags.has_flag(&"johto_radio_office_done"), "bureau joué")
	assert_false(GameState.flags.has_flag(&"johto_team_returned"), "l'équipe n'est pas là")
	assert_true(GameState.flags.has_flag(&"johto_act1"), "l'acte 1 continue (Exp ×1,5)")
	assert_true(GameState.flags.has_flag(&"storage_offline"), "Stockage toujours coupé")
	assert_false(GameState.confiscated.is_empty())
	pages = _play.pages()
	assert_true(pages.has("Sur la table, rien."), "T-24")
	assert_true(pages.has("Tes Poké Balls ? Elle les a mises dans une mallette, avec ton sac."), "T-26")
	assert_true(pages.has("« Ruines d'Alpha. Irisia. Ébènelle. Réunir les trois pierres. »"), "T-26")
	assert_true(pages.has("Kevin reçoit une Multi Exp !"), "T-31")
	assert_eq(GameState.bag.count_of(&"exp_all"), 1)
	assert_true(GameState.flags.has_flag(&"radio_exp_share_given"))
	# 1F : l'Agente et Orme (T-33, T-34, P-1).
	await SceneRouter.change_map(&"goldenrod_radio_tower_1f", &"from_2f", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_not_null(_play.boot.get_map().get_npc(&"orme"), "Orme attend")
	await _go(Vector2i(3, 11))
	await _step(Vector2i.DOWN)
	assert_true(GameState.flags.has_flag(&"johto_stones_quest"), "l'arc s'ouvre")
	assert_false(GameState.flags.has_flag(&"johto_act2"), "l'acte 2 attend la fin de l'arc")
	assert_eq(GameState.bag.count_of(&"mission_order"), 0, "Ordre de mission remis")
	assert_eq(GameState.bag.count_of(&"radio_card"), 0, "Carte d'accès remise")
	assert_true(_play.pages().has("… Trois pierres. Je connais cette histoire."), "T-34")
	assert_true(_play.pages().has("Réunies, elles réveillent ce qui est né sur cette terre."), "P-1")


func test_exp_share_already_owned_gives_candies() -> void:
	await _play.start(START_SMALL)
	var candies := GameState.bag.count_of(&"rare_candy")
	await _go(Vector2i(9, 2))
	await _play.step(Vector2i.LEFT)
	await _step(Vector2i.LEFT)
	assert_true(GameState.flags.has_flag(&"johto_radio_office_done"))
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
