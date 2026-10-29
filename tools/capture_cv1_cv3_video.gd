extends SceneTree
## Vidéo du plancher Combat vivant (CV.1 et fin de CV.3) dans un vrai combat sauvage sur la
## Route 1 (Boot, EncounterDirector, BattleStage, HUD, AudioBridge), piloté comme le fait le
## BattleDirector : gros coup (`hit_heavy`, vibration), Double Pied (la barre de chaque coup à son
## impact), Ultralaser puis halètement, quelques familles et modificateurs, puis la capture
## (Ball peinte, caméra qui s'approche, décor assombri, éclat). À enregistrer avec Movie Maker :
##
##   godot --path . --fixed-fps 30 --write-movie build/cv1_cv3.avi --quit-after 2400 \
##     -s res://tools/capture_cv1_cv3_video.gd

const BOOT_SCENE: String = "res://game/boot.tscn"
const PLAYER := BattleEvent.SideId.PLAYER
const FOE := BattleEvent.SideId.FOE
const HUD_PLAYER := BattleHud.Side.PLAYER
const HUD_FOE := BattleHud.Side.FOE

var _boot: Node
var _hud: BattleHud
var _stage: BattleStage
var _encounters: Node
var _caption: Label
var _audio_label: Label
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
	_log_audio()
	await _frames(20)
	var encounter: RefCounted = load("res://game/pokemon/encounters/wild_encounter.gd").new(
		&"pikachu", 5)
	_encounters.call(&"start_encounter", encounter)
	await _until(func() -> bool: return _stage.call(&"is_active"), 300)
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 900)
	_caption_set("Combat vivant : plancher (CV.1) et retours de PV (CV.3)")
	await _seconds(2.0)
	_caption_set("Charge, gros coup : bruitage lourd et vibration de 50 ms")
	await _attack(&"tackle", PLAYER, FOE, [8], 20, 0.6)
	await _seconds(1.2)
	_hud.get_card(HUD_FOE).set_hp(20, 20)
	_caption_set("Double Pied : la barre descend à chaque impact")
	await _attack(&"double_kick", PLAYER, FOE, [15, 10], 20)
	await _seconds(1.2)
	_caption_set("Pistolet à O, art peint (jet)")
	await _attack(&"water_gun", PLAYER, FOE, [6], 20)
	await _seconds(1.0)
	_hud.get_card(HUD_FOE).set_hp(20, 20)
	_caption_set("L'adversaire : Choc Mental (ondes, la cible ondule)")
	await _attack(&"confusion", FOE, PLAYER, [20], 27)
	await _seconds(1.0)
	_caption_set("L'adversaire : Vol-Vie (drain)")
	await _attack(&"absorb", FOE, PLAYER, [16], 27)
	await _seconds(1.0)
	_caption_set("Ligotage (piège)")
	await _attack(&"wrap", PLAYER, FOE, [17], 20)
	await _seconds(1.0)
	_caption_set("Ultralaser, puis le lanceur halète (« doit se reposer »)")
	await _attack(&"hyper_beam", PLAYER, FOE, [5], 20, 0.6)
	await _seconds(0.4)
	await _stage.play_panting(PLAYER)
	await _seconds(1.0)
	_caption_set("Capture : Ball peinte, la caméra s'approche, le décor s'assombrit")
	_hud.hide_card(HUD_FOE)
	_hud.hide_card(HUD_PLAYER)
	await _hud.hide_zone()
	await _stage.play_throw()
	for i: int in 3:
		await _seconds(0.3)
		await _stage.play_ball_shake()
	await _seconds(0.3)
	_caption_set("Capture réussie : éclat, tout revient")
	await _stage.play_catch_burst()
	await _seconds(2.0)
	print("CAPTURE_CV1_CV3_VIDEO terminé")
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


## Joue [param move_id] comme le BattleDirector : chorégraphie jusqu'au premier impact, puis un
## coup par valeur de [param hp_steps] (PV restants), chacun à son impact ; [param heavy] : part
## des PV max retirée par le plus gros coup (le bruitage lourd au-delà de HP_BIG_HIT).
func _attack(move_id: StringName, user: BattleEvent.SideId, target: BattleEvent.SideId,
		hp_steps: Array, max_hp: int, heavy: float = 0.1) -> void:
	var move := _data.get_move(move_id)
	var outcome := MoveFxOutcome.new()
	outcome.move_id = move_id
	outcome.result = MoveFxOutcome.Result.HIT
	outcome.hits = hp_steps.size()
	outcome.max_hit_fraction = heavy
	var plan := MoveFxPlan.build(_catalog, _catalog.entry(move_id), move, outcome,
		_stage.move_fx_mode(), _stage.reduce_flashes)
	await _stage.play_move_fx(user, plan)
	var hud_side := HUD_FOE if target == FOE else HUD_PLAYER
	for hp: int in hp_steps:
		if _stage.is_move_fx_hitting(target):
			await _stage.wait_move_fx_impact()
		var big := heavy > UiTokens.HP_BIG_HIT
		_stage.play_hit(target, false)
		_hud.play_hit(hud_side, false, big)
		await _hud.animate_hp(hud_side, hp, max_hp, big)
	await _stage.finish_move_fx()


## Journal du niveau des bus (« [audio] ») toutes les 0,5 s : sert à trouver un volume qui bouge.
func _log_audio() -> void:
	var audio: Node = root.get_node(^"Audio")
	var t := 0.0
	while true:
		var line := "[audio] t=%.1f" % t
		for bus: StringName in [&"Master", &"Music", &"Sfx", &"Cries", &"Ambience"]:
			var index := AudioServer.get_bus_index(bus)
			if index >= 0:
				line += " %s=%.1f" % [bus, AudioServer.get_bus_volume_db(index)]
		line += " ducked=%s" % audio.call(&"is_focus_ducked")
		line += " focus=%s" % DisplayServer.window_is_focused()
		print(line)
		if _audio_label != null:
			var music := AudioServer.get_bus_index(&"Music")
			_audio_label.text = "Musique : %.1f dB" % AudioServer.get_bus_volume_db(music)
		for i: int in 15:
			# La fenêtre d'enregistrement perd le focus : le jeu baisserait la musique (ducking de
			# focus voulu en jeu) ; on le lève ici pour que la capture reste à niveau constant.
			if audio.call(&"is_focus_ducked"):
				audio.call(&"_set_focus_ducked", false)
			await process_frame
		t += 0.5


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
	_audio_label = Label.new()
	_audio_label.position = Vector2(40, 1000)
	_audio_label.add_theme_font_size_override(&"font_size", 32)
	_audio_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_audio_label.add_theme_constant_override(&"outline_size", 8)
	layer.add_child(_audio_label)


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
