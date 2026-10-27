extends SceneTree
## Vidéo du CV.3 (statuts et PV) : vrai combat sauvage sur la Route 1 (Boot, EncounterDirector,
## BattleDirector, BattleStage, HUD), puis scénario piloté directement sur la scène et la HUD :
## chaque statut, un petit coup, un gros coup, des PV critiques, une attaque en Complètes puis
## en Rapides. À enregistrer avec Movie Maker :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --write-movie build/cv3.avi \
##     --quit-after 4500 -s res://tools/capture_cv3_video.gd

const BOOT_SCENE: String = "res://game/boot.tscn"
const PLAYER := BattleEvent.SideId.PLAYER
const FOE := BattleEvent.SideId.FOE
const HUD_PLAYER := BattleHud.Side.PLAYER
const HUD_FOE := BattleHud.Side.FOE
const STATUS_SECONDS: float = 5.0

var _boot: Node
var _hud: BattleHud
var _stage: BattleStage
var _encounters: Node
var _caption: Label
var _data: PokemonData
var _catalog: MoveFxCatalog


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(20)
	_setup_state()
	_hud = _boot.call(&"get_battle_hud")
	_hud.haptics_enabled = false
	_stage = _boot.call(&"get_battle_stage")
	_encounters = _boot.call(&"get_encounter_director")
	_data = PokemonData.new()
	_data.load_dir()
	_catalog = MoveFxCatalog.load_dir()
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.call(&"hide_interact")
	_build_caption()
	await _frames(20)
	var encounter: RefCounted = load("res://game/pokemon/encounters/wild_encounter.gd").new(
		&"pikachu", 5)
	_encounters.call(&"start_encounter", encounter)
	await _until(func() -> bool: return _stage.call(&"is_active"), 300)
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 900)
	_caption_set("Combat : respiration au repos (tous les Pokémon, camps décalés)")
	await _seconds(5.0)
	for status: StringName in [StatusRules.PARALYSIS, StatusRules.POISON, StatusRules.TOXIC,
			StatusRules.BURN, StatusRules.SLEEP, StatusRules.FREEZE]:
		_caption_set("Statut : %s" % String(status))
		_set_both(status)
		await _seconds(STATUS_SECONDS)
	_set_both(StatusRules.NONE)
	_caption_set("Statut : confusion (au moment du test)")
	await _seconds(0.5)
	await _stage.play_confusion(FOE)
	await _stage.play_confusion(PLAYER)
	await _seconds(0.8)
	_caption_set("Statut : poison, « Réduire les animations » (teintes et respiration seules)")
	_stage.reduce_motion = true
	_set_both(StatusRules.POISON)
	await _seconds(2.5)
	_set_both(StatusRules.FREEZE)
	await _seconds(2.0)
	_set_both(StatusRules.NONE)
	_stage.reduce_motion = false
	await _seconds(0.5)
	_caption_set("Petit coup : la trace claire reste, puis rattrape la barre")
	await _hit(FOE, 18, 20, false)
	await _seconds(1.5)
	_caption_set("Gros coup")
	await _hit(FOE, 6, 20, true)
	await _seconds(1.5)
	_caption_set("PV critiques (carte qui pulse sous 20 %)")
	await _hit(PLAYER, 14, 27, false)
	await _seconds(0.6)
	await _hit(PLAYER, 4, 27, true)
	await _seconds(3.0)
	_hud.get_card(HUD_PLAYER).set_hp(27, 27)
	_hud.get_card(HUD_FOE).set_hp(20, 20)
	_caption_set("Animations de combat : Complètes (Flammèche)")
	_stage.battle_animations = GameSettings.BattleAnimations.FULL
	await _attack(&"ember", PLAYER, FOE, 14)
	await _seconds(1.5)
	_caption_set("Animations de combat : Rapides (Flammèche)")
	_stage.battle_animations = GameSettings.BattleAnimations.FAST
	await _attack(&"ember", PLAYER, FOE, 9)
	await _seconds(1.5)
	print("CAPTURE_CV3_VIDEO terminé")
	quit()


func _setup_state() -> void:
	var state: Node = root.get_node(^"GameState")
	state.call(&"new_game", 31)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.get(&"flags").call(&"set_flag", &"pokedex_activated")
	state.set(&"starter_species", &"charmander")
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var party: RefCounted = load("res://game/pokemon/party.gd").new()
	var factory: GDScript = load("res://game/pokemon/pokemon_factory.gd")
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(999)
	party.call(&"add", factory.call(&"create", data, &"charmander", 9, rng))
	state.set(&"party", party)


func _set_both(status: StringName) -> void:
	_stage.set_status(PLAYER, status)
	_stage.set_status(FOE, status)
	_hud.set_status(HUD_PLAYER, status)
	_hud.set_status(HUD_FOE, status)


func _hit(side: BattleEvent.SideId, hp: int, max_hp: int, big: bool) -> void:
	var hud_side := HUD_PLAYER if side == PLAYER else HUD_FOE
	_stage.play_hit(side, false)
	_hud.play_hit(hud_side, false)
	await _hud.animate_hp(hud_side, hp, max_hp, big)


func _attack(move_id: StringName, user: BattleEvent.SideId, target: BattleEvent.SideId,
		hp_left: int) -> void:
	var move := _data.get_move(move_id)
	var outcome := MoveFxOutcome.new()
	outcome.result = MoveFxOutcome.Result.HIT
	outcome.hits = 1
	var plan := MoveFxPlan.build(_catalog, _catalog.entry(move_id, move.type, &"special"),
		move, outcome, _stage.move_fx_mode(), _stage.reduce_flashes)
	await _stage.play_move_fx(user, plan)
	var hud_side := HUD_FOE if target == FOE else HUD_PLAYER
	_stage.play_hit(target, false)
	_hud.play_hit(hud_side, false)
	await _hud.animate_hp(hud_side, hp_left, 20, false)
	await _stage.finish_move_fx()


func _build_caption() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	_caption = Label.new()
	_caption.position = Vector2(40, 24)
	_caption.add_theme_font_size_override(&"font_size", 40)
	_caption.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_caption.add_theme_constant_override(&"outline_size", 10)
	layer.add_child(_caption)


func _caption_set(text: String) -> void:
	_caption.text = text


func _seconds(seconds: float) -> void:
	await _frames(int(seconds * 30.0))


func _until(done: Callable, frames: int) -> bool:
	for i: int in frames:
		if done.call():
			return true
		await process_frame
	return false


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
