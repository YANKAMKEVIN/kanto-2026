extends GutTest
## Objets du jalon 20 dans le BattleDirector (`jalon-20.md` §2.9.3, §2.9.4 ; T11), sur la
## mini-carte de test_battle_director.gd (vraie BattleStage, vraie BattleHud, speed_scale = 0) :
## le Sac de combat joue un objet X, la Poupée Poké et le Rappel ; chaque objet quitte le Sac
## **une seule fois** ; le choix du Pokémon du Rappel n'accepte que les K.O. (« Pas K.O. » sur
## les autres). Contre un Dresseur, la Poupée n'est pas proposée : le Sac
## de combat ne montre que les objets utilisables ; rien n'est retiré, aucun tour joué.
## Passe systèmes 2 (S2B, T11) : la Poké Flûte depuis le Sac de combat (jamais retirée ; sans
## dormeur, « Personne ne dort. », aucun tour joué).

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const STAGE_SCENE := preload("res://game/battle/battle_stage.tscn")
const HUD_SCENE := preload("res://game/ui/battle/battle_hud.tscn")
const GAME_STATE := preload("res://game/autoload/game_state.gd")
const NPCS := "res://tests/fixtures/npcs/"
const MINE_ID := &"mine_poke"
const FOE_ID := &"foe_poke"

var _data: PokemonData
var _trainers: TrainerLibrary
var _texts: BattleText
var _items: ItemLibrary
var _hud: BattleHud
var _state: Node
var _director: BattleDirector
var _map: GameMap


func before_each() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()
	_texts = BattleText.new()
	_texts.load_file()
	_items = ItemLibrary.new()
	_items.load_dir()
	_state = GAME_STATE.new()
	add_child_autofree(_state)
	var world := Node2D.new()
	add_child_autofree(world)
	_map = GameMap.new()
	_map.name = "ItemsMap"
	_map.map_id = &"battle_items_map"
	_map.npcs_dir = NPCS
	_map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		_map.add_child(node)
	world.add_child(_map)
	var player := PLAYER_SCENE.instantiate() as Player
	_map.get_entities().add_child(player)
	player.enter_map(_map.get_grid(), Vector2i(11, 7), Vector2i.LEFT, _map.get_pixel_rect())
	player.get_camera().make_current()
	var stage := STAGE_SCENE.instantiate() as BattleStage
	stage.speed_scale = 0.0
	add_child_autofree(stage)
	_hud = HUD_SCENE.instantiate() as BattleHud
	_hud.speed_scale = 0.0
	_hud.haptics_enabled = false
	add_child_autofree(_hud)
	_director = BattleDirector.new()
	_director.speed_scale = 0.0
	add_child_autofree(_director)
	_director.haptics_enabled = false
	_director.setup(_data, _trainers, _texts, stage, _hud, player, _state, _items)
	_state.party = Party.new()
	(_state.party as Party).add(PokemonFactory.create(_data, &"charmander", 30, GameRng.new(9)))
	_state.starter_species = &"charmander"
	_state.rng = GameRng.new(11)
	await wait_process_frames(2)


func _wild() -> BattleRequest:
	var encounter := WildEncounter.new(&"rattata", 3, &"route_1_grass")
	return BattleRequest.wild(encounter, _data, _state.rng as GameRng, Vector2i(5, 4), _items)


func _trainer() -> BattleRequest:
	var foes := Party.new()
	foes.add(PokemonFactory.create(_data, &"rattata", 2, GameRng.new(3)))
	return BattleRequest.trainer_battle(_trainers.get_trainer(&"rival_route22"), foes, {},
		_items)


## Joue [param request] : à chaque choix, l'étape suivante de [param plan] — un tableau
## [onglet, objet, cible] (SAC, onglet, objet, UTILISER, puis la cible si ≥ 0) ou &"attack" ;
## plan épuisé : ATTAQUER (1re capacité). Un Sac sans objet utilisable : « ‹ » (noté dans
## « empty_bag »). Renvoie { outcome, events, picker, empty_bag }.
func _play(request: BattleRequest, plan: Array) -> Dictionary:
	var report := {"outcome": Battle.Outcome.NONE, "events": [], "picker": null,
		"empty_bag": false}
	_director.event_played.connect(func(e: BattleEvent) -> void: report["events"].append(e))
	var done: Array[bool] = [false]
	var runner := func() -> void:
		report["outcome"] = await _director.run_request(request, _map)
		done[0] = true
	runner.call()
	var step: Variant = null
	var picked := false
	var deadline := Time.get_ticks_msec() + 20000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var panel := _director.get_bag_panel()
		var picker := _director.get_party_picker()
		var battle := _director.get_battle()
		if picker != null and picker.is_shown() and step is Array and not picked:
			report["picker"] = picker.get_view()
			picked = true
			picker.target_chosen.emit(int(step[2]))
		elif panel != null and panel.is_shown() and not panel.is_answered() and step is Array \
				and panel.get_categories().is_empty():
			report["empty_bag"] = true
			step = null
			panel.get_back_button().back_requested.emit()
		elif panel != null and panel.is_shown() and not panel.is_answered() and step is Array:
			panel.open_category(StringName(step[0]))
			panel.select_item(StringName(step[1]))
			panel.get_action_button().pressed.emit()
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and _hud.get_zone() == BattleHud.Zone.ACTIONS:
			step = plan.pop_front() if not plan.is_empty() else &"attack"
			picked = false
			_hud.action_selected.emit(ActionGrid.BAG if step is Array else ActionGrid.ATTACK)
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and _hud.get_zone() == BattleHud.Zone.MOVES:
			_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")
	return report


func _kinds(report: Dictionary) -> Array[BattleEvent.Kind]:
	var kinds: Array[BattleEvent.Kind] = []
	for event: BattleEvent in report["events"]:
		kinds.append(event.kind)
	return kinds


func test_the_poke_doll_leaves_the_bag_once_and_ends_a_wild_battle() -> void:
	_state.bag.add(&"poke_doll", 2)
	var report := await _play(_wild(), [[&"battle", &"poke_doll", -1]])
	assert_eq(report["outcome"], Battle.Outcome.FLED)
	assert_eq(_state.bag.count_of(&"poke_doll"), 1, "une seule Poupée retirée")
	assert_true(_kinds(report).has(BattleEvent.Kind.ITEM_ESCAPE))
	assert_false(_kinds(report).has(BattleEvent.Kind.MOVE_USED), "personne n'attaque")
	assert_push_error_count(0)


func test_an_x_item_leaves_the_bag_once_and_raises_the_stage() -> void:
	_state.bag.add(&"x_attack", 3)
	var report := await _play(_wild(), [[&"battle", &"x_attack", -1]])
	assert_eq(_state.bag.count_of(&"x_attack"), 2, "un seul objet X retiré")
	var kinds := _kinds(report)
	var used := kinds.find(BattleEvent.Kind.BATTLE_ITEM_USED)
	assert_gt(used, -1)
	assert_eq(kinds[used + 1], BattleEvent.Kind.STAT_CHANGED)
	assert_push_error_count(0)


func test_the_poke_doll_is_not_offered_against_a_trainer() -> void:
	_state.bag.add(&"poke_doll", 1)
	var entries := BattleViews.bag_entries(_state.bag, _items, ItemData.CONTEXT_TRAINER_BATTLE)
	assert_eq(entries.size(), 1)
	assert_false(entries[0].usable, "combat sauvage seulement")
	var report := await _play(_trainer(), [[&"battle", &"poke_doll", -1]])
	assert_true(report["empty_bag"], "aucun objet utilisable dans le Sac")
	assert_eq(_state.bag.count_of(&"poke_doll"), 1, "rien n'est retiré")
	assert_false(_kinds(report).has(BattleEvent.Kind.ITEM_ESCAPE))
	assert_eq(report["outcome"], Battle.Outcome.WIN, "le combat continue jusqu'au bout")
	assert_push_error_count(0)


func test_a_revive_picks_only_a_fainted_member_and_leaves_the_bag_once() -> void:
	var down := PokemonFactory.create(_data, &"pidgey", 12, GameRng.new(4))
	down.hp = 0
	(_state.party as Party).add(down)
	_state.bag.add(&"revive", 2)
	var report := await _play(_wild(), [[&"heal", &"revive", 1]])
	var picker: PartyPickerView = report["picker"]
	assert_not_null(picker, "le choix du Pokémon s'est ouvert")
	if picker != null:
		assert_eq([picker.targets[0].usable, picker.targets[1].usable], [false, true])
		assert_eq(picker.targets[0].reason, "Pas K.O.")
	assert_eq(_state.bag.count_of(&"revive"), 1, "un seul Rappel retiré")
	assert_eq(down.hp, maxi(1, floori(down.max_hp() / 2.0)))
	assert_true(_kinds(report).has(BattleEvent.Kind.REVIVED))
	var revived: BattleEvent = null
	for event: BattleEvent in report["events"]:
		if event.kind == BattleEvent.Kind.REVIVED:
			revived = event
	assert_eq(Array(_texts.lines(revived, _data)), ["Roucool reprend connaissance !"])
	assert_push_error_count(0)


func test_an_x_item_against_a_trainer_then_the_battle_goes_on() -> void:
	_state.bag.add(&"x_defend", 1)
	var report := await _play(_trainer(), [[&"battle", &"x_defend", -1]])
	assert_eq(_state.bag.count_of(&"x_defend"), 0)
	assert_true(_kinds(report).has(BattleEvent.Kind.BATTLE_ITEM_USED))
	assert_eq(report["outcome"], Battle.Outcome.WIN)
	assert_push_error_count(0)


func test_the_flute_wakes_the_sleeper_and_stays_in_the_bag() -> void:
	var mine: Pokemon = (_state.party as Party).get_at(0)
	mine.status = StatusRules.SLEEP
	mine.status_turns = 5
	_state.bag.add(&"poke_flute", 1)
	var report := await _play(_wild(), [[&"key", &"poke_flute", -1]])
	var kinds := _kinds(report)
	assert_true(kinds.has(BattleEvent.Kind.FLUTE_PLAYED))
	assert_lt(kinds.find(BattleEvent.Kind.FLUTE_WOKE), kinds.find(BattleEvent.Kind.ALL_WOKE))
	assert_true(_state.bag.has(&"poke_flute"), "un objet clé n'est jamais retiré")
	assert_eq(report["outcome"], Battle.Outcome.WIN)
	assert_push_error_count(0)


func test_without_a_sleeper_the_flute_takes_no_turn() -> void:
	_state.bag.add(&"poke_flute", 1)
	var report := await _play(_wild(), [[&"key", &"poke_flute", -1]])
	var kinds := _kinds(report)
	assert_false(kinds.has(BattleEvent.Kind.FLUTE_PLAYED), "rien n'est soumis")
	var first_turn := kinds.find(BattleEvent.Kind.TURN_STARTED)
	assert_gt(first_turn, -1)
	var first: BattleEvent = report["events"][first_turn]
	assert_eq(first.turn, 1, "le tour suivant est le premier : aucun tour pris")
	assert_true(_state.bag.has(&"poke_flute"))
	assert_eq(report["outcome"], Battle.Outcome.WIN)
	assert_push_error_count(0)
