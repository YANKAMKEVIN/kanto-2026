extends GutTest
## Giovanni et le Scope Sylphe (jalon 20 T21, `jalon-20.md` §2.7.4, §2.7.5, §2.11 ; dossier 23
## §13.5, §14, §19, §20.7 n° 52 à 55, annexe A.8 n° 154 à 156, A.10 n° 172) avec la vraie scène
## Boot, la vraie carte `rocket_hideout_b4f`, les vraies données et les vraies entrées :
## - données : G-1 (Onix 23, Rhinocorne 22, Kangourex 25), IA `smart` avec changement, 2 475 ₽,
##   carte « GIOVANNI / Chef de la Team Rocket » ;
## - victoire : n° 52 → carte → combat → n° 53, n° 54 → Giovanni part (absent ensuite) → Poké Ball
##   du Scope en (25, 2) → Grand moment « giovanni » (une fois) ; la Poké Ball : n° 55 et le toast,
##   `silph_scope` au Sac, objectif « retourner à la Tour Pokémon. » ; Super Potion cachée (25, 1)
##   lisible depuis la case du Scope ;
## - défaite : n° 155, réveil au Centre de Céladopole, Clé et Rocket battus gardés ; nouvel essai :
##   n° 156 sans introduction ni carte, puis la victoire ;
## - application coupée entre la victoire et le ramassage : au rechargement, Giovanni absent,
##   Poké Ball au sol.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/giovanni.json"
const START_WEAK := "res://tools/debug_start/giovanni_weak.json"
const MAP := &"rocket_hideout_b4f"
const GIOVANNI_CELL := Vector2i(25, 3)
const TALK_CELL := Vector2i(24, 3)
const BALL := &"rocket_hideout_b4f_silph_scope"
const BALL_CELL := Vector2i(25, 2)
const WON := &"giovanni_hideout_won"
const MET := &"giovanni_met"
const GOT := &"got_rocket_hideout_b4f_silph_scope"
const SCOPE := &"silph_scope"
const INTRO: Array[String] = [
	"Tu es donc l'enfant qui dérange mes affaires depuis le Mont Sélénite.",
	"La Tour Pokémon cache une chose qui m'intéresse.",
	"Je n'aime pas qu'on se mette en travers de mon chemin.",
]
const WON_LINES: Array[String] = ["… Je vois.", "Ce repaire ne m'est plus utile.",
	"Garde ta victoire. Nous nous reverrons."]
const LOST_LINES: Array[String] = ["Rentre chez toi.", "Et oublie ce que tu as vu ici."]
const RESUME: Array[String] = ["Encore toi.", "Soit."]
const SCOPE_LINES: Array[String] = ["Kevin obtient le Scope Sylphe !",
	"Il permet de voir ce que l'œil seul ne voit pas."]
const CARD := "card:GIOVANNI/Chef de la Team Rocket"
const KEPT: Array[StringName] = [&"beaten_rocket_hideout_b4f_guard_1",
	&"beaten_rocket_hideout_b4f_guard_2", &"rocket_hideout_b4f_door_open",
	&"got_rocket_hideout_b4f_lift_key", &"game_corner_switch", &"beaten_rocket_hideout_b1f_1"]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_giovanni_flow.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_giovanni_data_match_g1_and_the_validated_texts() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(&"giovanni_hideout")
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch, "il change de Pokémon")
	assert_eq(trainer.prize_money, 2475, "99 × 25 (G-1)")
	assert_eq([trainer.card_name, trainer.card_title], ["GIOVANNI", "Chef de la Team Rocket"])
	var team := library.build_team(&"giovanni_hideout", &"charmander", GameRng.new(1))
	assert_eq(team.get_all().map(func(p: Pokemon) -> Array: return [p.species_id, p.level]),
		[[&"onix", 23], [&"rhyhorn", 22], [&"kangaskhan", 25]], "G-1 (Kevin, 2026-10-16)")
	var roster := NpcRoster.load_for_map(MAP)
	var giovanni := roster.get_spec(&"giovanni")
	assert_eq([giovanni.cell, giovanni.facing, giovanni.sprite],
		[GIOVANNI_CELL, Vector2i.DOWN, &"giovanni"])
	assert_eq(giovanni.unless_flags, [WON] as Array[StringName], "absent après sa défaite")
	var ball := roster.get_spec(BALL)
	assert_eq([ball.cell, ball.if_flags, ball.unless_flags],
		[BALL_CELL, [WON] as Array[StringName], [GOT] as Array[StringName]],
		"Poké Ball du Scope au sol tant qu'elle n'est pas ramassée")


func test_victory_departure_scope_on_the_floor_moment_and_objective() -> void:
	await _play.start(START)
	_play.make_strong()
	var money := GameState.money
	assert_eq(_play.map_id(), MAP)
	assert_not_null(_play.boot.get_map().get_npc(&"giovanni"))
	await _play.walk_to(TALK_CELL)
	assert_eq(_play.player.get_cell(), TALK_CELL)
	assert_true(await _play.interact(Vector2i.RIGHT), "le combat a eu lieu")
	var events := _play.events
	var pages := _play.pages()
	assert_eq(pages.slice(0, 3), INTRO, "n° 52")
	assert_gt(events.find(CARD), events.find("page:" + INTRO[2]), "la carte après n° 52")
	assert_gt(events.find("battle"), events.find(CARD), "le combat après la carte")
	for line: String in WON_LINES:
		assert_gt(events.find("page:" + line), events.find("battle"), "« %s » après" % line)
	for line: String in LOST_LINES + RESUME:
		assert_false(pages.has(line), "« %s » PAS jouée" % line)
	assert_true(GameState.flags.has_flag(MET))
	assert_true(GameState.flags.has_flag(WON))
	assert_eq(GameState.money, money + 2475)
	assert_null(_play.boot.get_map().get_npc(&"giovanni"), "Giovanni est parti")
	var ball := _play.boot.get_map().get_npc(BALL)
	assert_not_null(ball, "le Scope est au sol")
	if ball != null:
		assert_eq(ball.get_cell(), BALL_CELL)
	assert_eq(_play.player.get_cell(), GIOVANNI_CELL, "le joueur s'avance devant la Poké Ball")
	assert_eq(_moments(), 1, "Grand moment « giovanni »")
	assert_eq(GameState.bag.count_of(SCOPE), 0, "pas encore ramassé")
	assert_eq(_objective(), "fouiller sous le Casino.")
	# La Poké Ball.
	_play.events.clear()
	await _play.interact(Vector2i.UP)
	assert_eq(_play.pages(), SCOPE_LINES, "n° 55")
	assert_has(_play.events, "toast:Scope Sylphe / obtenu", "toast « obtenu »")
	assert_eq(GameState.bag.count_of(SCOPE), 1)
	assert_true(GameState.flags.has_flag(GOT))
	assert_eq(_objective(), "retourner à la Tour Pokémon.", "texte 59")
	assert_null(_play.boot.get_map().get_npc(BALL))
	# La Super Potion cachée, lisible seulement depuis la case du Scope.
	await _play.step(Vector2i.UP)
	assert_eq(_play.player.get_cell(), BALL_CELL)
	_play.events.clear()
	var potions := GameState.bag.count_of(&"super_potion")
	await _play.interact(Vector2i.UP)
	assert_eq(GameState.bag.count_of(&"super_potion"), potions + 1)
	assert_true(GameState.flags.has_flag(&"got_rocket_hideout_b4f_hidden_1"))
	assert_eq(_moments(), 1, "un seul Grand moment")
	# Plus de Giovanni au retour.
	await SceneRouter.change_map(MAP, &"from_elevator", Vector2i.UP)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_null(_play.boot.get_map().get_npc(&"giovanni"))
	assert_null(_play.boot.get_map().get_npc(BALL))
	assert_push_error_count(0)


func test_defeat_wakes_at_the_center_then_retry_without_introduction_nor_card() -> void:
	await _play.start(START_WEAK)
	assert_eq(GameState.party.size(), 1)
	assert_eq(GameState.heal_map, &"celadon_center", "Centre de Céladopole enregistré")
	await _play.walk_to(TALK_CELL)
	assert_true(await _play.interact(Vector2i.RIGHT), "le combat a eu lieu")
	var pages := _play.pages()
	for line: String in INTRO + LOST_LINES:
		assert_true(pages.has(line), "« %s » jouée" % line)
	assert_gt(_play.events.find("page:" + LOST_LINES[0]), _play.events.find("battle"))
	assert_has(_play.events, CARD)
	assert_true(GameState.flags.has_flag(MET), "première rencontre mémorisée")
	assert_false(GameState.flags.has_flag(WON))
	assert_eq(_play.map_id(), &"celadon_center", "réveil au Centre de Céladopole")
	assert_eq(GameState.bag.count_of(&"lift_key"), 1, "Clé gardée")
	for flag: StringName in KEPT:
		assert_true(GameState.flags.has_flag(flag), "%s gardé" % flag)
	assert_eq(_moments(), 0)
	# Retour par l'ascenseur (départ à sa porte), mieux préparé.
	await SceneRouter.change_map(MAP, &"from_elevator", Vector2i.UP)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	_play.make_strong()
	_play.events.clear()
	await _play.walk_to(TALK_CELL)
	assert_true(await _play.interact(Vector2i.RIGHT), "second combat")
	pages = _play.pages()
	assert_eq(pages.slice(0, 2), RESUME, "n° 156")
	for line: String in INTRO:
		assert_false(pages.has(line), "« %s » PAS rejouée" % line)
	assert_false(_play.events.has(CARD), "pas de carte aux reprises")
	assert_true(GameState.flags.has_flag(WON))
	assert_not_null(_play.boot.get_map().get_npc(BALL))
	assert_eq(_moments(), 1)
	assert_push_error_count(0)


func test_an_app_killed_before_the_scope_is_picked_up_leaves_the_ball_on_the_floor() -> void:
	await _play.start(START)
	_play.make_strong()
	await _play.walk_to(TALK_CELL)
	assert_true(await _play.interact(Vector2i.RIGHT))
	assert_true(GameState.flags.has_flag(WON))
	_play.boot.request_autosave("test : avant le Scope")
	await wait_until(func() -> bool:
		return (_play.saved().get("flags", []) as Array).has(String(WON)), 10.0)
	var saved := _play.saved()
	assert_true((saved.get("flags", []) as Array).has(String(WON)), "victoire sauvée")
	assert_false((saved.get("flags", []) as Array).has(String(GOT)), "Scope pas ramassé")
	assert_eq(saved.get("map"), String(MAP))
	# Application relancée.
	await _play.resume()
	assert_true(_play.boot.has_resumed())
	assert_eq(_play.map_id(), MAP)
	assert_null(_play.boot.get_map().get_npc(&"giovanni"), "Giovanni absent")
	var ball := _play.boot.get_map().get_npc(BALL)
	assert_not_null(ball, "la Poké Ball du Scope est au sol")
	if ball != null:
		assert_eq(ball.get_cell(), BALL_CELL)
	assert_eq(GameState.bag.count_of(SCOPE), 0)
	assert_eq(_moments(), 1, "le Grand moment n'est pas rejoué")
	# On la ramasse.
	await _play.walk_to(BALL_CELL + Vector2i.DOWN)
	await _play.interact(Vector2i.UP)
	assert_eq(GameState.bag.count_of(SCOPE), 1)
	assert_push_error_count(0)


func _moments() -> int:
	var count := 0
	for moment: Dictionary in GameState.moments:
		if str(moment.get("type", "")) == String(MomentLibrary.GIOVANNI):
			count += 1
			assert_eq(str(moment.get("map", "")), String(MAP), "moment au B4F")
	return count


func _objective() -> String:
	var objectives := ObjectiveLibrary.new()
	objectives.load_file()
	return objectives.current(GameState.flags)
