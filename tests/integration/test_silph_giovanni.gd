extends GutTest
## Giovanni au 11F de la Sylphe SARL et Master Ball du président (jalon 26 T12, `jalon-26.md`
## §0.2, §2.3 à §2.5, §3 T26-13 à T26-18, §5), avec la vraie scène Boot, la vraie carte
## `silph_co_11f`, le vrai départ `silph_11f` et les vraies entrées :
## - données : Nidorino 37, Kangourex 35, Rhinocorne 37, Nidoqueen 41, IA `smart`, carte ;
## - entrer dans le bureau ((6, 13) ou (7, 12)) lance la scène : Giovanni s'avance, T26-13, carte
##   (la première fois), combat ;
## - victoire : `silph_giovanni_defeated` (seule source de vérité de la libération), T26-14,
##   Giovanni part ; autosave écrit avec le drapeau ; Sbires du 11F partis au retour ;
## - défaite : T26-15, réveil, rejouable (sans carte) ;
## - président : T26-16, T26-17, Master Ball (une seule), T26-18 ; reparler : T26-18 ;
## - application coupée entre la victoire et la remise : remise à la visite suivante.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/silph_11f.json"
const MAP := &"silph_co_11f"
const TRAINER := &"silph_co_giovanni"
const DEFEATED := &"silph_giovanni_defeated"
const MET := &"silph_giovanni_met"
const GOT_BALL := &"silph_master_ball_received"
const GIOVANNI_CELL := Vector2i(6, 9)
const BELOW_DOOR := Vector2i(6, 14)
const PRESIDENT_TALK := Vector2i(6, 5)
const CARD := "card:GIOVANNI/Chef de la Team Rocket"
const T26_13: Array[String] = ["Te voilà encore.",
	"Tu t'obstines à te mettre en travers de mes affaires.",
	"Cette fois, je ne te ferai pas de cadeau."]
const T26_14: Array[String] = ["… Je me suis trompé sur toi.",
	"La Sylphe SARL n'en vaut plus la peine.", "Nous partons."]
const T26_15: Array[String] = ["Rentre chez toi.", "Ce n'est pas un jeu d'enfant."]
const T26_16: Array[String] = ["Merci !", "Sans toi, la Sylphe SARL était perdue.",
	"Accepte ceci : c'est notre plus grande invention."]
const T26_17 := "Kevin obtient la Master Ball !"
const T26_18: Array[String] = ["La Master Ball attrape n'importe quel Pokémon à coup sûr.",
	"Il n'en existe qu'une."]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_silph_giovanni.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


## Équipe réduite à un Dracaufeu N100 (Plaquage, aucune espèce adverse ne l'arrête) : gagne
## tout (le Salamèche N60 de [method HideoutPlay.make_strong] ne passe ni Rhinocorne ni Léviator).
func _make_titan() -> void:
	var titan := PokemonFactory.create(_play.boot.get_pokemon_data(), &"charizard", 100,
		GameState.rng)
	titan.moves.clear()
	titan.moves.append(MoveSlot.new(&"body_slam", 15))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(titan)


## Sous la porte du bureau, puis un pas vers le haut sur (6, 13) : la scène.
func _enter_office() -> bool:
	await _play.walk_to(BELOW_DOOR)
	assert_eq(_play.player.get_cell(), BELOW_DOOR)
	_play.events.clear()
	await _play.step(Vector2i.UP)
	return await _play.run_scene()


func _talk_to_president() -> void:
	await _play.walk_to(PRESIDENT_TALK)
	assert_eq(_play.player.get_cell(), PRESIDENT_TALK)
	_play.events.clear()
	await _play.interact(Vector2i.RIGHT)


func _saved_flags() -> Array:
	return _play.saved().get("flags", []) as Array


func test_giovanni_data_and_map() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(TRAINER)
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_eq([trainer.card_name, trainer.card_title], ["GIOVANNI", "Chef de la Team Rocket"])
	var team := library.build_team(TRAINER, &"charmander", GameRng.new(1))
	assert_eq(team.get_all().map(func(p: Pokemon) -> Array: return [p.species_id, p.level]),
		[[&"nidorino", 37], [&"kangaskhan", 35], [&"rhyhorn", 37], [&"nidoqueen", 41]],
		"arbitrage verrouillé de la passe")
	var roster := NpcRoster.load_for_map(MAP)
	var giovanni := roster.get_spec(&"giovanni")
	assert_eq([giovanni.cell, giovanni.sprite], [GIOVANNI_CELL, &"giovanni"])
	assert_eq(giovanni.unless_flags, [DEFEATED] as Array[StringName])
	for id: StringName in [&"silph_co_11f_1", &"silph_co_11f_2"]:
		assert_eq(roster.get_spec(id).unless_flags, [DEFEATED] as Array[StringName],
			"%s : parti à la libération" % id)
	var map := (load(MapCatalog.scene_path(MAP)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	var cells: Array[Vector2i] = []
	for trigger: EventTrigger in map.get_triggers().get_all():
		if trigger.cutscene_id == TRAINER:
			cells.append(trigger.cell)
	cells.sort()
	assert_eq(cells, [Vector2i(6, 13), Vector2i(7, 12)] as Array[Vector2i], "cases RB")


func test_victory_frees_the_silph_then_the_president_gives_the_master_ball_once() -> void:
	await _play.start(START)
	_make_titan()
	assert_eq(_play.map_id(), MAP)
	assert_true(await _enter_office(), "le combat a eu lieu")
	var events := _play.events
	assert_eq(_play.pages().slice(0, 3), T26_13, "T26-13")
	assert_gt(events.find(CARD), events.find("page:" + T26_13[2]), "la carte après T26-13")
	assert_gt(events.find("battle"), events.find(CARD))
	for line: String in T26_14:
		assert_gt(events.find("page:" + line), events.find("battle"), "T26-14")
	for line: String in T26_15:
		assert_false(_play.pages().has(line))
	assert_true(GameState.flags.has_flag(DEFEATED))
	assert_null(_play.boot.get_map().get_npc(&"giovanni"), "Giovanni est parti")
	# Sauvegarde forcée après le combat (fin de combat, fin de scène).
	await wait_until(func() -> bool: return _saved_flags().has(String(DEFEATED)), 10.0)
	assert_true(_saved_flags().has(String(DEFEATED)), "victoire sauvée")
	# Le président.
	await _talk_to_president()
	assert_eq(_play.pages(), T26_16 + [T26_17] + T26_18, "T26-16, T26-17, T26-18")
	assert_eq(GameState.bag.count_of(&"master_ball"), 1)
	assert_true(GameState.flags.has_flag(GOT_BALL))
	await _talk_to_president()
	assert_eq(_play.pages(), T26_18, "après : T26-18")
	assert_eq(GameState.bag.count_of(&"master_ball"), 1, "une seule Master Ball")
	# Retour sur l'étage : ni Giovanni ni Sbires, plus de scène.
	await SceneRouter.change_map(MAP, &"tp_4", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	for id: StringName in [&"giovanni", &"silph_co_11f_1", &"silph_co_11f_2"]:
		assert_null(_play.boot.get_map().get_npc(id), "%s absent" % id)
	assert_eq(await _enter_office(), false, "plus de combat")
	assert_push_error_count(0)


func test_defeat_wakes_up_then_retry_without_the_card() -> void:
	await _play.start(START)
	_play.make_weak()
	assert_true(await _enter_office(), "le combat a eu lieu")
	var pages := _play.pages()
	assert_eq(pages.slice(0, 3), T26_13)
	assert_has(_play.events, CARD)
	for line: String in T26_15:
		assert_gt(_play.events.find("page:" + line), _play.events.find("battle"), "T26-15")
	assert_false(GameState.flags.has_flag(DEFEATED))
	assert_true(GameState.flags.has_flag(MET))
	assert_eq(_play.map_id(), &"celadon_center", "réveil au point de repos")
	assert_eq(GameState.bag.count_of(&"master_ball"), 0)
	await SceneRouter.change_map(MAP, &"tp_4", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_not_null(_play.boot.get_map().get_npc(&"giovanni"), "Giovanni attend toujours")
	_make_titan()
	assert_true(await _enter_office(), "second combat")
	assert_eq(_play.pages().slice(0, 3), T26_13)
	assert_false(_play.events.has(CARD), "pas de carte aux reprises")
	assert_true(GameState.flags.has_flag(DEFEATED))
	assert_push_error_count(0)


func test_an_app_killed_before_the_president_gives_the_ball_at_the_next_visit() -> void:
	await _play.start(START)
	_make_titan()
	assert_true(await _enter_office())
	assert_true(GameState.flags.has_flag(DEFEATED))
	await wait_until(func() -> bool: return _saved_flags().has(String(DEFEATED)), 10.0)
	assert_true(_saved_flags().has(String(DEFEATED)))
	assert_false(_saved_flags().has(String(GOT_BALL)), "Master Ball pas encore remise")
	# Application relancée.
	await _play.resume()
	assert_true(_play.boot.has_resumed())
	assert_eq(_play.map_id(), MAP)
	assert_null(_play.boot.get_map().get_npc(&"giovanni"))
	assert_eq(GameState.bag.count_of(&"master_ball"), 0)
	await _talk_to_president()
	assert_eq(_play.pages(), T26_16 + [T26_17] + T26_18, "remise à la visite suivante")
	assert_eq(GameState.bag.count_of(&"master_ball"), 1)
	assert_push_error_count(0)
