extends SceneTree
## RP-263 : mesure l'à-coup du premier effet d'attaque de la partie. Vrai combat sauvage
## (Boot, Route 1, Bulbizarre N5 : Charge, Rugissement) contre un Roucool, piloté par les signaux
## de la BattleHud, à vitesse réelle ; plus longue image (temps réel) de chaque attaque, de
## l'appui sur la capacité au retour des actions : 1re attaque Charge (ou --move), puis deux
## Rugissement (le Roucool N5 tient).
##
##   godot --path . --resolution 1170x540 -s res://tools/measure_first_fx.gd [-- --no-warmup]
##
## --no-warmup : sans le préchauffage des effets (comportement d'avant RP-263) ; --move=<rang>
## (défaut 0, Charge). Lignes « [perf] 1re attaque … », « [perf] 2e attaque … », « [perf]
## préchauffage … ». Pas en --headless (il faut le rendu), pas de --fixed-fps (vraies durées).

const BOOT_SCENE: String = "res://game/boot.tscn"
const ATTACKS: int = 3

var _boot: Node
var _hud: CanvasLayer
var _director: Node
var _stage: CanvasLayer
var _encounters: Node
var _warmup: bool = true
var _move: int = 0


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--no-warmup":
			_warmup = false
		elif arg.begins_with("--move="):
			_move = int(arg.trim_prefix("--move="))
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	load("res://game/battle/fx/move_fx_player.gd").set(&"warmup_enabled", _warmup)
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(20)
	_setup_state()
	_hud = _boot.call(&"get_battle_hud")
	_hud.set(&"haptics_enabled", false)
	_director = _boot.call(&"get_battle_director")
	_stage = _boot.call(&"get_battle_stage")
	_encounters = _boot.call(&"get_encounter_director")
	await _frames(30)
	var encounter: RefCounted = load("res://game/pokemon/encounters/wild_encounter.gd").new(
		&"pidgey", 5)
	_encounters.call(&"start_encounter", encounter)
	var worst_intro := 0
	var last := Time.get_ticks_usec()
	while int(_hud.call(&"get_zone")) != 1:
		await process_frame
		var now := Time.get_ticks_usec()
		worst_intro = maxi(worst_intro, now - last)
		last = now
	print("[perf] entrée en combat (préchauffage %s) : plus longue image %.1f ms"
		% ["oui" if _warmup else "non", worst_intro / 1000.0])
	await _frames(20)
	for i: int in ATTACKS:
		await _attack(i, _move if i == 0 else 1)
	print("MEASURE_FIRST_FX terminé")
	quit()


func _setup_state() -> void:
	var state: Node = root.get_node(^"GameState")
	state.call(&"new_game", 31)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.set(&"starter_species", &"bulbasaur")
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var party: RefCounted = load("res://game/pokemon/party.gd").new()
	var factory: GDScript = load("res://game/pokemon/pokemon_factory.gd")
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(999)
	party.call(&"add", factory.call(&"create", data, &"bulbasaur", 5, rng))
	state.set(&"party", party)


## ATTAQUER, capacité de rang [param move] ; plus longue image jusqu'au retour des actions.
func _attack(index: int, move: int) -> void:
	_hud.emit_signal(&"action_selected", &"attack")
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 2, 300)
	await _frames(10)
	var worst := 0
	var frames := 0
	var last := Time.get_ticks_usec()
	_hud.emit_signal(&"move_selected", move)
	while int(_hud.call(&"get_zone")) != 1 and _director.call(&"is_running") and frames < 1200:
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		last = now
		frames += 1
	print("[perf] attaque %d (préchauffage %s) : plus longue image %.1f ms (%.1f i/s), %d images"
		% [index + 1, "oui" if _warmup else "non", worst / 1000.0, 1000000.0 / maxf(worst, 1.0),
		frames])
	await _frames(20)


func _until(done: Callable, frames: int) -> bool:
	for i: int in frames:
		if done.call():
			return true
		await process_frame
	push_warning("attente dépassée")
	return false


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
