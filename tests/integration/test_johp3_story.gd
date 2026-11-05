extends GutTest
## JOHP3 (`docs/tech/jalon-joh-pierres.md` §5.2, §5.4 ; dossier JOH-11 §6, §13 à §15) : Ébènelle,
## l'épreuve du clan et l'autel joués dans le **vrai Boot** (pilote `hideout_play.gd`) :
## - l'Antre fermé avant l'Aïeule, ouvert après ;
## - les trois Gardiens ouvrent la descente au Sanctuaire ;
## - l'Aïeule soigne une fois ; Ysolde, la Pierre Souffle, défaite au Centre d'Ébènelle ;
## - l'autel : Cenere, Farfuret, le Réveil, Cenere battue, retour de l'équipe, une écriture ;
## - défaite contre Cenere : Réveil acquis, Cenere à l'autel, mallette non rendue ;
## - le vol de retour : `johto_act2`, Rosalia.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START_ROSALIA := "res://tools/debug_start/johto_rosalia_corentin.json"
const START_CITY := "res://tools/debug_start/johto_blackthorn.json"
const START_DEN := "res://tools/debug_start/johto_den_1f.json"
const START_SANCTUARY := "res://tools/debug_start/johto_den_sanctuary.json"
const START_ALTAR := "res://tools/debug_start/johto_den_altar.json"
const START_CENERE := "res://tools/debug_start/johto_den_cenere.json"

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_johp3_story_save.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func _go(goal: Vector2i) -> void:
	for attempt: int in 6:
		if _play.player.get_cell() == goal:
			return
		await _play.walk_to(goal)
		if not _play.boot.is_stable():
			await _play.run_scene()
	assert_eq(_play.player.get_cell(), goal, "arrivé en %s" % goal)


func _step(direction: Vector2i) -> void:
	await _play.step(direction)
	if not _play.boot.is_stable():
		await _play.run_scene()


## Trois Mewtwo N100 (Météores, sans immunité dans ces équipes) : gagnent tout, même contre les
## dragons ; équipe confisquée réduite à 3 : 6 Pokémon en tout, pas d'écran des 6.
func _strong() -> void:
	GameState.party.clear()
	for i: int in 3:
		var extra := PokemonFactory.create(_play.boot.get_pokemon_data(), &"mewtwo", 100,
			GameState.rng)
		extra.moves.clear()
		extra.moves.append(MoveSlot.new(&"swift", 20))
		GameState.party.add(extra)
	GameState.confiscated.party.resize(3)


func test_the_den_is_closed_until_the_elder_speaks() -> void:
	await _play.start(START_CITY)
	assert_eq(_play.map_id(), &"blackthorn_city")
	assert_null(_play.boot.get_map().get_npc(&"aieule"), "l'Aïeule est chez elle")
	await _go(Vector2i(26, 13))
	await _step(Vector2i.RIGHT)
	assert_eq(_play.player.get_cell(), Vector2i(26, 13), "ramené en arrière")
	assert_true(_play.pages().has("Réservé au clan"), "P-41")
	await _go(Vector2i(15, 12))
	await _step(Vector2i.UP)
	assert_eq(_play.map_id(), &"blackthorn_elder_house")
	await _go(Vector2i(7, 6))
	await _play.interact(Vector2i.UP)
	assert_true(GameState.flags.has_flag(&"johto_clan_trial_open"), "P-22, P-23")
	assert_true(_play.pages().has("Mes yeux ne voient plus, mais les pierres parlent fort."), "P-22")


func test_three_guardians_open_the_way_to_the_sanctuary() -> void:
	await _play.start(START_DEN, _strong)
	assert_eq(_play.map_id(), &"dragons_den_1f")
	await _go(Vector2i(13, 8))
	await _go(Vector2i(13, 4))
	await _step(Vector2i.UP)
	assert_eq(_play.player.get_cell(), Vector2i(13, 4), "barrière : ramené en arrière")
	assert_false(GameState.flags.has_flag(&"johto_clan_guardians_done"))
	for flag: StringName in [&"beaten_den_guardian_water", &"beaten_den_guardian_stone",
			&"beaten_den_guardian_sky"]:
		GameState.flags.set_flag(flag)
	await _step(Vector2i.UP)
	assert_true(GameState.flags.has_flag(&"johto_clan_guardians_done"), "les trois sont battus")
	await _step(Vector2i.UP)
	assert_eq(_play.map_id(), &"dragons_den_sanctuary")


func test_the_elder_heals_once_then_ysolde_gives_the_stone() -> void:
	await _play.start(START_SANCTUARY, _strong)
	assert_not_null(_play.boot.get_map().get_npc(&"aieule"), "l'Aïeule attend")
	GameState.party.get_all()[0].hp = 1
	await _go(Vector2i(9, 14))
	await _play.interact(Vector2i.LEFT)
	assert_true(GameState.flags.has_flag(&"johto_clan_healed"))
	assert_eq(GameState.party.get_all()[0].hp, GameState.party.get_all()[0].max_hp(), "P-25")
	GameState.party.get_all()[0].hp = 1
	await _play.interact(Vector2i.LEFT)
	assert_eq(GameState.party.get_all()[0].hp, 1, "une fois, pas deux")
	GameState.party.heal_all()
	await _go(Vector2i(10, 12))
	await _step(Vector2i.UP)
	assert_true(_play.events.has("battle"), "combat contre Ysolde")
	assert_true(GameState.flags.has_flag(&"johto_clan_trial_done"))
	assert_true(GameState.flags.has_flag(&"johto_stone_breath"))
	assert_eq(GameState.bag.count_of(&"stone_breath"), 1)
	assert_true(_play.pages().has("{0} obtient la Pierre Souffle !".format(["Kevin"])), "P-27")


func test_defeat_against_ysolde_wakes_at_blackthorn_guardians_stay_beaten() -> void:
	await _play.start(START_SANCTUARY, _weak)
	await _go(Vector2i(10, 12))
	await _step(Vector2i.UP)
	assert_eq(_play.map_id(), &"blackthorn_center", "réveil au Centre d'Ébènelle")
	assert_false(GameState.flags.has_flag(&"johto_clan_trial_done"))
	assert_true(GameState.flags.has_flag(&"johto_clan_guardians_done"), "Gardiens toujours battus")


func _weak() -> void:
	_play.make_weak()


func test_the_altar_awakens_then_cenere_falls_and_the_team_comes_back() -> void:
	await _play.start(START_ALTAR, _strong)
	assert_eq(_play.map_id(), &"dragons_den_sanctuary")
	assert_null(_play.boot.get_map().get_npc(&"cenere"), "Cenere n'est pas encore là")
	await _step(Vector2i.UP)
	assert_true(GameState.flags.has_flag(&"johto_stones_awakened"), "le Réveil")
	assert_true(GameState.flags.has_flag(&"johto_cenere_defeated_arc"), "Cenere battue")
	assert_true(GameState.flags.has_flag(&"johto_team_returned"), "équipe rendue")
	assert_false(GameState.flags.has_flag(&"johto_act1"), "×1,5 retiré")
	assert_false(GameState.flags.has_flag(&"storage_offline"), "Stockage rétabli")
	assert_false(GameState.flags.has_flag(&"johto_act2"), "l'acte 2 attend le vol de retour")
	assert_true(GameState.confiscated.is_empty())
	assert_eq(GameState.bag.count_of(&"stone_breath"), 0, "les pierres s'éteignent")
	var pages := _play.pages()
	assert_true(pages.has("Tes six Pokémon contre tes pierres. Le calcul est simple."), "P-28")
	assert_true(pages.has("… Ce n'était pas dans les données."), "P-30")
	assert_true(pages.has("… Ils changent tout. Deuxième erreur."), "P-32")
	assert_true(pages.has("Kevin retrouve son équipe et son sac !"), "P-34")
	var saved := _play.saved()
	assert_true((saved.get("flags", []) as Array).has("johto_team_returned"), "écrite")
	assert_false(saved.has("confiscated"))
	assert_null(_play.boot.get_map().get_npc(&"cenere"), "Cenere est partie")


func test_defeat_against_cenere_keeps_the_awakening_and_the_case() -> void:
	await _play.start(START_CENERE, _weak)
	assert_not_null(_play.boot.get_map().get_npc(&"cenere"), "Cenere à l'autel")
	await _step(Vector2i.UP)
	assert_eq(_play.map_id(), &"blackthorn_center", "réveil au Centre d'Ébènelle")
	assert_true(GameState.flags.has_flag(&"johto_stones_awakened"), "Réveil acquis")
	assert_false(GameState.flags.has_flag(&"johto_cenere_defeated_arc"))
	assert_false(GameState.flags.has_flag(&"johto_team_returned"), "mallette non rendue")
	assert_false(GameState.confiscated.is_empty())


## De Rosalia à Ébènelle et retour (JH-79) : Corentin appelle, puis reste à son poste.
func test_corentin_calls_at_rosalia_then_the_flight_stays_open() -> void:
	await _play.start(START_ROSALIA)
	assert_eq(_play.map_id(), &"ecruteak_city")
	assert_not_null(_play.boot.get_map().get_npc(&"corentin"), "Corentin attend à Rosalia")
	await _go(Vector2i(34, 18))
	await _play.interact(Vector2i.RIGHT)
	assert_eq(_play.map_id(), &"blackthorn_city", "le vol (P-21)")
	assert_true(GameState.flags.has_flag(&"johto_clan_called"))
	assert_true(_play.pages().has("Kevin s'accroche !"), "P-21")
	assert_eq(GameState.heal_map, &"blackthorn_center", "défaite à Ébènelle : Centre d'Ébènelle")
	await _go(Vector2i(16, 22))
	await _play.interact(Vector2i.RIGHT)
	assert_eq(_play.map_id(), &"ecruteak_city", "retour libre pendant l'arc [D]")
	assert_false(GameState.flags.has_flag(&"johto_act2"))
	await _go(Vector2i(34, 18))
	await _play.interact(Vector2i.RIGHT)
	assert_eq(_play.map_id(), &"blackthorn_city", "P-56")
	assert_true(_play.pages().has("Ébènelle ? Monte !"), "P-56")


func test_corentin_flies_back_to_rosalia_and_opens_act_2() -> void:
	await _play.start(START_CITY, func() -> void:
		GameState.flags.set_flag(&"johto_team_returned"))
	await _go(Vector2i(16, 22))
	await _play.interact(Vector2i.RIGHT)
	assert_eq(_play.map_id(), &"ecruteak_city", "déposé à Rosalia")
	assert_true(GameState.flags.has_flag(&"johto_act2"), "acte 2")
	assert_true(_play.pages().has("Allez, je te dépose devant leur porte !"), "P-38")
