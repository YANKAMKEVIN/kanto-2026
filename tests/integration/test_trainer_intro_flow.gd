extends GutTest
## Entrée des combats de Dresseur (dossier 05 §3, décision de Kevin du 2026-11-02), jouée par le
## vrai BattleDirector, la vraie BattleStage et la vraie BattleHud (speed_scale = 0) :
## - Dresseur ordinaire : les deux dresseurs entrent (aucun Pokémon encore), le message de
##   début, l'adversaire lance, puis le joueur ; pas de séquence « VS » ;
## - grand combat (Pierre) : la séquence « VS » d'abord (nom et titre des données), puis la même
##   entrée ;
## - repli des images (aucun sprite de face peint : apparence du monde agrandie).
## Les durées et le toucher (jamais sautée) : test_trainer_intro_timing.gd.

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const STAGE_SCENE := preload("res://game/battle/battle_stage.tscn")
const HUD_SCENE := preload("res://game/ui/battle/battle_hud.tscn")
const GAME_STATE := preload("res://game/autoload/game_state.gd")
const NPCS := "res://tests/fixtures/npcs/"
const PLAYER_CELL := Vector2i(11, 7)
const ORDINARY := &"route_3_hugo"
const GRAND := &"pewter_gym_brock"

var _data: PokemonData
var _trainers: TrainerLibrary
var _texts: BattleText
var _stage: BattleStage
var _hud: BattleHud
var _player: Player
var _state: Node
var _director: BattleDirector
var _map: GameMap
## Journal mêlé : étapes de l'entrée (« step:… »), événements joués (« event:… »), VS.
var _log: Array[String] = []
## Pokémon adverse visible au début de l'étape TRAINERS_IN (doit être faux).
var _foe_shown_at_entry: bool = true
var _foe_trainer_texture: Texture2D


func before_each() -> void:
	_log.clear()
	_data = PokemonData.new()
	_data.load_dir()
	_trainers = TrainerLibrary.new(_data)
	_trainers.load_dir()
	_texts = BattleText.new()
	_texts.load_file()
	_state = GAME_STATE.new()
	add_child_autofree(_state)
	var world := Node2D.new()
	add_child_autofree(world)
	_map = GameMap.new()
	_map.name = "IntroMap"
	_map.map_id = &"intro_map"
	_map.npcs_dir = NPCS
	_map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		_map.add_child(node)
	world.add_child(_map)
	_player = PLAYER_SCENE.instantiate() as Player
	_map.get_entities().add_child(_player)
	_player.enter_map(_map.get_grid(), PLAYER_CELL, Vector2i.LEFT, _map.get_pixel_rect())
	_player.get_camera().make_current()
	_stage = STAGE_SCENE.instantiate() as BattleStage
	_stage.speed_scale = 0.0
	add_child_autofree(_stage)
	_hud = HUD_SCENE.instantiate() as BattleHud
	_hud.speed_scale = 0.0
	_hud.haptics_enabled = false
	add_child_autofree(_hud)
	_director = BattleDirector.new()
	_director.speed_scale = 0.0
	_director.haptics_enabled = false
	add_child_autofree(_director)
	_director.setup(_data, _trainers, _texts, _stage, _hud, _player, _state)
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"charmander", 5, GameRng.new(7)))
	_state.party = party
	_state.starter_species = &"charmander"
	_state.rng = GameRng.new(11)
	_director.trainer_intro_step.connect(_on_step)
	_director.vs_started.connect(func(foe_name: String, title: String) -> void:
		_log.append("vs:%s/%s" % [foe_name, title]))
	_director.event_played.connect(_on_event)
	await wait_process_frames(2)


func _on_step(step: TrainerIntro.Step) -> void:
	_log.append("step:" + str(TrainerIntro.Step.find_key(step)))
	if step == TrainerIntro.Step.TRAINERS_IN:
		_foe_shown_at_entry = _stage.get_sprite(BattleEvent.SideId.FOE).visible
	elif step == TrainerIntro.Step.FOE_SEND:
		_foe_trainer_texture = _stage.get_trainer_intro_stage().get_trainer(
			BattleEvent.SideId.FOE).texture


func _on_event(event: BattleEvent) -> void:
	match event.kind:
		BattleEvent.Kind.BATTLE_STARTED:
			_log.append("event:started")
		BattleEvent.Kind.SENT_OUT:
			if not _log.has("event:sent_player"):
				_log.append("event:sent_" + ("foe" if event.side == BattleEvent.SideId.FOE
					else "player"))


## Joue le combat contre [param trainer_id] jusqu'au bout (1re capacité à chaque tour).
func _play(trainer_id: StringName) -> void:
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _director.run(trainer_id, _map, {} as Dictionary[StringName, StringName])
		done[0] = true
	runner.call()
	var deadline := Time.get_ticks_msec() + 20000
	while not done[0] and Time.get_ticks_msec() < deadline:
		var battle := _director.get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match _hud.get_zone():
				BattleHud.Zone.ACTIONS:
					_hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_true(done[0], "le combat s'est terminé")


## Les entrées du journal qui précèdent le premier tour (l'entrée du combat).
func _opening() -> Array[String]:
	var end := _log.find("event:sent_player")
	return _log.slice(0, end + 1)


func test_ordinary_trainer_entry_order() -> void:
	await _play(ORDINARY)
	assert_eq(_opening(), ["step:TRAINERS_IN", "event:started", "step:FOE_SEND",
		"event:sent_foe", "step:PLAYER_SEND", "event:sent_player"] as Array[String],
		"dresseurs, message, l'adversaire lance, puis le joueur ; pas de « VS »")
	assert_false(_foe_shown_at_entry, "aucun Pokémon avant le lancer")
	assert_false(_stage.is_active(), "vue de combat refermée")


func test_grand_battle_plays_vs_first() -> void:
	await _play(GRAND)
	assert_eq(_opening(), ["step:TRAINERS_IN", "vs:PIERRE/Champion d'Arène d'Argenta",
		"step:VS_IN", "step:VS_HOLD", "step:VS_OUT", "event:started", "step:FOE_SEND",
		"event:sent_foe", "step:PLAYER_SEND", "event:sent_player"] as Array[String])
	assert_false(_foe_shown_at_entry)
	for child: Node in _hud.get_children():
		assert_false(child is VsBanner and not child.is_queued_for_deletion(),
			"banderoles libérées après la séquence")


func test_front_sprite_falls_back_to_the_world_look() -> void:
	await _play(ORDINARY)
	assert_not_null(_foe_trainer_texture, "un sprite de face (repli)")
	var expected := TrainerIntroStage.world_texture(&"youngster")
	assert_eq(_foe_trainer_texture.get_size(), expected.get_size(),
		"Gamin sans image peinte : apparence du monde « youngster »")


func test_rival_vs_uses_the_rival_name() -> void:
	_texts.token_values = func() -> Dictionary: return {&"rival": "Régis", &"player": "Kevin"}
	await _play(&"rival_route22")
	assert_has(_log, "vs:RÉGIS/Rival")
