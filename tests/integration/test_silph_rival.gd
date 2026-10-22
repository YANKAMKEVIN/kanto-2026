extends GutTest
## Rival n° 6 au 7F de la Sylphe SARL (jalon 26 T11, `jalon-26.md` §2.3, §3 T26-07 à T26-09, §5)
## avec la vraie scène Boot, la vraie carte `silph_co_7f`, la vraie scène `rival_silph`, les vrais
## départs `silph_7f_rival_<starter>` et les vraies entrées :
## - équipe selon `starter_species` (trois variantes), **jamais** selon l'équipe actuelle ;
## - obligatoire : de la dalle (5, 3) à la dalle du 11F (5, 7), tout chemin passe par (3, 2) ou
##   (3, 3) ;
## - défaite : T26-07, combat, T26-09, réveil au point de repos, aucun Grand moment ; rejouable ;
## - victoire : T26-08, il part, `rival_silph_won` (convention de `rival_ss_anne_won`), un Grand
##   moment « rival_battle » ; plus de scène ni de rival ensuite.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const STARTS := "res://tools/debug_start/silph_7f_rival_%s.json"
const MAP := &"silph_co_7f"
const TRAINER := &"rival_silph"
const WON := &"rival_silph_won"
const PAD_FROM_3F := Vector2i(5, 3)
const PAD_TO_11F := Vector2i(5, 7)
const TRIGGERS: Array[Vector2i] = [Vector2i(3, 2), Vector2i(3, 3)]
const RIVAL_CELL := Vector2i(3, 7)
## Équipes RB de Rival2Data (Sylphe 7F), [D] Q26-4 : Sablaireau au lieu de Léviator contre
## Bulbizarre (lignée du rival_tower).
const TEAMS := {
	&"bulbasaur": [[&"pidgeot", 37], [&"exeggcute", 38], [&"sandslash", 35], [&"alakazam", 35],
		[&"charizard", 40]],
	&"charmander": [[&"pidgeot", 37], [&"growlithe", 38], [&"exeggcute", 35], [&"alakazam", 35],
		[&"blastoise", 40]],
	&"squirtle": [[&"pidgeot", 37], [&"gyarados", 38], [&"growlithe", 35], [&"alakazam", 35],
		[&"venusaur", 40]],
}
const WON_LINES: Array[String] = ["Pas mal…", "Le chef est tout en haut.",
	"Fais ce que tu veux, moi j'ai mieux à faire."]
const LOST_LINES: Array[String] = ["Trop facile.", "Reviens quand tu seras prêt."]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_silph_rival.json")
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


func _intro() -> Array[String]:
	return ["Tiens, Kevin.", "Toi aussi, tu cherches le chef de la Team Rocket ?",
		"Montre-moi d'abord ce que tu vaux."]


func _rival_moments() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for moment: Dictionary in GameState.moments:
		if moment.get("type", "") == String(GameState.MOMENT_RIVAL_BATTLE) \
				and (moment.get("details", {}) as Dictionary).get("trainer") == String(TRAINER):
			found.append(moment)
	return found


## Deux pas vers l'ouest depuis la dalle (5, 3) : le second, sur (3, 3), lance la scène.
func _meet() -> bool:
	await _play.step(Vector2i.LEFT)
	await _play.step(Vector2i.LEFT)
	return await _play.run_scene()


# --- Données ----------------------------------------------------------------------------------

func test_the_team_follows_the_starter_never_the_current_party() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var trainer := library.get_trainer(TRAINER)
	assert_eq(trainer.ai, BattleAI.SMART)
	assert_true(trainer.can_switch)
	assert_true(trainer.moment_on_win, "Grand moment « rival_battle » à la victoire")
	assert_false(trainer.can_lose, "défaite → réveil")
	for starter: StringName in TEAMS:
		var team := library.build_team(TRAINER, starter, GameRng.new(1))
		assert_eq(team.get_all().map(func(p: Pokemon) -> Array: return [p.species_id, p.level]),
			TEAMS[starter], "contre %s" % starter)


func test_the_three_debug_starts_put_their_starter_first() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	for starter: StringName in TEAMS:
		var start := DebugStart.new()
		assert_true(start.load_file(STARTS % starter, data, items),
			"%s : %s" % [starter, "\n".join(start.get_errors())])
		assert_eq([start.map, start.spawn], [MAP, &"tp_5"], String(starter))
		assert_eq(StringName(start.party[0]["species"]), starter, "starter en tête")
		assert_eq(int(start.bag.get("card_key", 0)), 1, "Carte au Sac")
		assert_false(start.flags.has(WON))


# --- Carte ------------------------------------------------------------------------------------

func test_the_rival_stands_on_the_only_way_to_the_11f_pad() -> void:
	var map := (load(MapCatalog.scene_path(MAP)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	var cells: Array[Vector2i] = []
	for trigger: EventTrigger in map.get_triggers().get_all():
		if trigger.cutscene_id == TRAINER:
			cells.append(trigger.cell)
	cells.sort()
	assert_eq(cells, TRIGGERS, "deux cases de déclenchement (RB)")
	var roster := NpcRoster.load_for_map(MAP)
	var rival := roster.get_spec(TRAINER)
	assert_eq([rival.cell, rival.facing, rival.sprite], [RIVAL_CELL, Vector2i.UP, &"rival"])
	assert_eq(rival.unless_flags, [WON] as Array[StringName], "absent après la victoire")
	# Sans les cases de déclenchement, la dalle du 11F est hors d'atteinte depuis celle du 3F.
	var grid := map.get_grid()
	var blocker := RefCounted.new()
	for cell: Vector2i in TRIGGERS:
		assert_true(grid.occupy(cell, blocker))
	var reached := GridPaths.distances(grid, [PAD_FROM_3F])
	assert_false(reached.has(PAD_TO_11F), "le rival est sur le chemin obligatoire du 11F")
	for cell: Vector2i in TRIGGERS:
		grid.release(cell, blocker)
	assert_true(GridPaths.distances(grid, [PAD_FROM_3F]).has(PAD_TO_11F))


# --- Défaite puis victoire -------------------------------------------------------------------

func test_defeat_wakes_up_then_retry_and_victory_with_a_single_moment() -> void:
	await _play.start(STARTS % "charmander")
	_play.make_weak()
	assert_eq(_play.map_id(), MAP)
	assert_eq(_play.player.get_cell(), PAD_FROM_3F)
	assert_true(await _meet(), "le combat a eu lieu")
	var pages := _play.pages()
	assert_eq(pages.slice(0, 3), _intro(), "T26-07")
	for line: String in LOST_LINES:
		assert_gt(_play.events.find("page:" + line), _play.events.find("battle"), "T26-09")
	for line: String in WON_LINES:
		assert_false(pages.has(line))
	assert_false(GameState.flags.has_flag(WON))
	assert_true(GameState.flags.has_flag(&"rival_silph_lost_once"))
	assert_eq(_play.map_id(), &"celadon_center", "réveil au point de repos")
	assert_true(_rival_moments().is_empty(), "aucun Grand moment pour une défaite")
	# Retour par la dalle du 3F, mieux préparé : rejouable.
	await SceneRouter.change_map(MAP, &"tp_5", Vector2i.LEFT)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_not_null(_play.boot.get_map().get_npc(TRAINER), "le rival attend toujours")
	_make_titan()
	_play.events.clear()
	assert_true(await _meet(), "second combat")
	assert_eq(_play.pages().slice(0, 3), _intro())
	for line: String in WON_LINES:
		assert_gt(_play.events.find("page:" + line), _play.events.find("battle"), "T26-08")
	assert_true(GameState.flags.has_flag(WON))
	assert_null(_play.boot.get_map().get_npc(TRAINER), "il est parti")
	var moments := _rival_moments()
	assert_eq(moments.size(), 1, "un Grand moment")
	if moments.size() == 1:
		assert_eq((moments[0].get("details", {}) as Dictionary).get("outcome"), "win")
	assert_push_error_count(0)


func test_after_the_victory_the_way_to_the_11f_is_free_and_nothing_replays() -> void:
	await _play.start(STARTS % "squirtle")
	# Équipe remplacée (Dracaufeu N100) : le combat suit toujours le starter de la partie.
	_make_titan()
	assert_eq(GameState.starter_species, &"squirtle")
	assert_true(await _meet(), "combat")
	assert_true(GameState.flags.has_flag(WON))
	_play.events.clear()
	# Repasser sur les deux cases : aucune scène.
	await _play.step(Vector2i.UP)
	await _play.step(Vector2i.DOWN)
	assert_false(_play.boot.get_cutscene_director().is_running())
	assert_eq(_play.events.count("battle"), 0, "pas de second combat")
	# Rechargement de la carte : toujours absent.
	await SceneRouter.change_map(MAP, &"tp_5", Vector2i.LEFT)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_null(_play.boot.get_map().get_npc(TRAINER))
	await _play.walk_to(PAD_TO_11F)
	assert_eq(_play.map_id(), &"silph_co_11f", "dalle du 11F atteinte")
	assert_eq(_rival_moments().size(), 1)
	assert_push_error_count(0)
