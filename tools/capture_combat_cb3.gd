extends SceneTree
## Captures du CB.3 (décor peint de combat) : le VRAI combat sauvage complet (Boot, rencontre
## lancée par EncounterDirector.start_encounter, BattleDirector, BattleStage, interface CB.2),
## piloté par les signaux de la BattleHud, à vitesse réelle.
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 9000 \
##     -s res://tools/capture_combat_cb3.gd -- --out=build/captures/combat_cb3 [--place=oak_lab]
## Lancer toutes les passes avec tools/capture_combat_cb3.sh.
## Route 1 (préfixe cb3_route_1_) : transition_1..4 (monde → décor), roucool (actions),
## capacites, coup, sac, lancer, ball_au_sol, carte_capture, retour_1..2 (décor → monde),
## rattata, bilan (victoire sur Rattata), dracaufeu, fuite. Repli (--place=oak_lab, préfixe
## cb3_oak_lab_) : transition, actions.
## Mesures : lignes « [perf] » (fps, appels de dessin, mémoire des textures) sur la vue posée.
## Correctifs après la QA S24 (--place=route_22 : repli ; --pass=poses : ton Pokémon au sol
## pour --starters=rattata,charmander,charmander@2.0,venusaur (espèce@taille : taille
## imposée, boîte maximale d'un grand Pokémon ; Florizarre n'a pas de dos : rien), préfixe cb3_route_1_joueur_<espèce>) ;
## « [perf] entrée » : plus longue image (temps réel) de l'entrée en combat ; --no-preload
## vide le préchargement du décor avant la rencontre (comportement d'avant le correctif).
## Fusion du J9 (--pass=evolution, Route 1) : Chenipan N6 empoisonné, à un point d'XP du
## niveau 7, bat un Rattata : evo_combat (PSN sur le décor peint), evo_bilan, puis l'écran
## d'évolution au-dessus du combat : evo_ouverture, evo_transformation, evo_fin.

const BOOT_SCENE: String = "res://game/boot.tscn"
const STARTER: StringName = &"charmander"
const SPAWNS: Dictionary = {&"route_1": &"from_pallet_w", &"oak_lab": &"entrance",
	&"route_22": &"from_viridian"}

var _boot: Node
var _out_dir: String = "build/captures/combat_cb3"
var _place: StringName = &"route_1"
var _hud: CanvasLayer
var _director: Node
var _stage: CanvasLayer
var _encounters: Node
var _starter: StringName = STARTER
var _foes: Array[StringName] = []
var _pass: String = "full"
var _starters: Array[StringName] = [&"rattata", &"charmander", &"charmander@2.0", &"venusaur"]
var _preload: bool = true
## Aperçu d'un décor sans carte (J12 T4) : --decor=<id> le pose comme décor de la Route 1.
var _decor_id: StringName = &""


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--place="):
			_place = StringName(arg.trim_prefix("--place="))
		elif arg.begins_with("--pass="):
			_pass = arg.trim_prefix("--pass=")
		elif arg.begins_with("--starters="):
			_starters.clear()
			for id: String in arg.trim_prefix("--starters=").split(","):
				_starters.append(StringName(id))
		elif arg.begins_with("--foes="):
			for id: String in arg.trim_prefix("--foes=").split(","):
				_foes.append(StringName(id))
		elif arg.begins_with("--starter="):
			_starter = StringName(arg.trim_prefix("--starter="))
		elif arg.begins_with("--decor="):
			_decor_id = StringName(arg.trim_prefix("--decor="))
		elif arg == "--no-preload":
			_preload = false
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", _place)
	if SPAWNS.get(_place, &"") != &"":
		_boot.set(&"start_spawn", SPAWNS[_place])
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(20)
	_setup_state()
	_hud = _boot.call(&"get_battle_hud")
	_hud.set(&"haptics_enabled", false)
	_director = _boot.call(&"get_battle_director")
	_stage = _boot.call(&"get_battle_stage")
	_encounters = _boot.call(&"get_encounter_director")
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.call(&"hide_interact")
	await _frames(20)
	if _decor_id != &"":
		await _decor_preview()
	elif _pass == "poses":
		await _poses()
	elif _pass == "evolution":
		await _evolution()
	elif _pass == "foes":
		for foe: StringName in _foes:
			_encounter(foe, 5)
			await _wait_zone(1)
			await _frames(12)
			await _shot("foe_%s" % foe)
			await _flee("")
	elif _place == &"route_1":
		await _route_1()
	else:
		await _fallback()
	print("CAPTURE_CB3 terminé")
	quit()


func _setup_state() -> void:
	var state: Node = root.get_node(^"GameState")
	state.call(&"new_game", 31)
	state.get(&"flags").call(&"set_flag", &"starter_chosen")
	state.get(&"flags").call(&"set_flag", &"pokedex_activated")
	state.set(&"starter_species", STARTER)
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var party: RefCounted = load("res://game/pokemon/party.gd").new()
	var factory: GDScript = load("res://game/pokemon/pokemon_factory.gd")
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(999)
	party.call(&"add", factory.call(&"create", data, _starter, 9, rng))
	state.set(&"party", party)
	var bag: RefCounted = state.get(&"bag")
	bag.call(&"add", &"poke_ball", 12)
	bag.call(&"add", &"potion", 3)


# --- Route 1 ---------------------------------------------------------------------------

func _route_1() -> void:
	# Roucool : transition, actions, capacités, un coup, Sac, lancer, capture, bilan, retour.
	await _entry_perf()
	_encounter(&"pidgey", 3)
	await _until(func() -> bool: return _stage.call(&"is_active"), 300)
	for i: int in 4:
		await _frames(5)
		await _shot("transition_%d" % (i + 1))
	await _wait_zone(1)
	await _frames(12)
	await _shot("roucool")
	await _perf("roucool")
	_hud.emit_signal(&"action_selected", &"attack")
	await _wait_zone(2)
	await _frames(12)
	await _shot("capacites")
	_hud.emit_signal(&"move_selected", 0)
	await _frames(14)
	await _shot("coup")
	await _wait_zone(1)
	await _catch()
	# Retour au monde : le décor s'efface dans le monde flouté (sortie du stage).
	await _until(_leaving, 900)
	print("[qa] retour : décor %.2f" % (_stage.call(&"get_decor_back") as Sprite2D).modulate.a)
	await _shot("retour_1")
	await _frames(5)
	await _shot("retour_2")
	await _until(func() -> bool: return not _director.call(&"is_running"), 900)
	await _frames(30)
	# Rattata : vue posée, puis fuite.
	_encounter(&"rattata", 3)
	await _wait_zone(1)
	await _frames(12)
	await _shot("rattata")
	await _win()
	# Un grand Pokémon : Dracaufeu.
	_encounter(&"charizard", 5)
	await _wait_zone(1)
	await _frames(12)
	await _shot("dracaufeu")
	await _perf("dracaufeu")
	await _flee("fuite")


## SAC → Poké Ball jusqu'à la capture (le Sac pris en photo une fois, le lancer et la Ball au
## sol au premier essai), puis carte de capture et bilan.
func _catch() -> void:
	var first := true
	# Les lambdas GDScript capturent les variables locales par valeur : on passe par des tableaux.
	var got: Array = [null]
	while true:
		_hud.emit_signal(&"action_selected", &"bag")
		await _until(func() -> bool:
			got[0] = _director.call(&"get_bag_panel")
			return got[0] != null and got[0].visible and not got[0].call(&"is_sliding"), 200)
		var panel: Control = got[0]
		if panel == null:
			push_error("capture : Sac absent")
			return
		await _frames(10)
		panel.call(&"select_item", &"poke_ball")
		await _frames(6)
		if first:
			await _shot("sac")
		# LANCER comme au doigt (le panneau sort de lui-même).
		(panel.call(&"get_action_button") as Button).emit_signal(&"pressed")
		await _until(func() -> bool:
			var ball: Sprite2D = _stage.call(&"get_ball")
			return ball != null and ball.visible, 300)
		await _frames(4)
		if first:
			await _shot("lancer")
		# La Ball posée dans l'herbe : le dresseur est sorti, la chute est finie.
		await _until(func() -> bool:
			var thrower: Sprite2D = _stage.call(&"get_thrower")
			return thrower != null and not thrower.visible, 300)
		await _frames(24)
		if first:
			await _shot("ball_au_sol")
		first = false
		got[0] = null
		await _until(func() -> bool:
			var card: Control = _director.call(&"get_capture_card")
			if card != null and card.call(&"is_waiting"):
				got[0] = card
				return true
			return int(_hud.call(&"get_zone")) == 1 or not _director.call(&"is_running"), 900)
		var card: Control = got[0]
		if card != null:
			await _until(func() -> bool: return card.call(&"is_revealed"), 200)
			await _frames(10)
			await _shot("carte_capture")
			card.call(&"skip")
			break
		if not _director.call(&"is_running"):
			push_error("capture : combat fini sans carte")
			return
	got[0] = null
	if await _until(func() -> bool:
			var summary: Control = _director.call(&"get_summary_card")
			if summary != null and summary.visible and summary.call(&"is_waiting"):
				got[0] = summary
				return true
			return _leaving(), 600) and got[0] != null:
		await _frames(10)
		await _shot("bilan")
		got[0].call(&"tap")


## ATTAQUER, 1re capacité, jusqu'à la victoire ; photo du bilan d'XP.
func _win() -> void:
	var got: Array = [null]
	while _director.call(&"is_running"):
		var summary: Control = _director.call(&"get_summary_card")
		if summary != null and summary.visible and summary.call(&"is_waiting"):
			await _frames(10)
			await _shot("bilan")
			summary.call(&"tap")
			break
		match int(_hud.call(&"get_zone")):
			1:
				_hud.emit_signal(&"action_selected", &"attack")
			2:
				_hud.emit_signal(&"move_selected", 0)
		await _frames(2)
	await _until(func() -> bool: return not _director.call(&"is_running"), 900)
	await _frames(40)


## La sortie du combat a commencé : le décor peint s'efface dans le monde.
func _leaving() -> bool:
	var back: Sprite2D = _stage.call(&"get_decor_back")
	return back.visible and back.modulate.a < 0.95


func _flee(name: String) -> void:
	while _director.call(&"is_running"):
		if int(_hud.call(&"get_zone")) == 1:
			_hud.emit_signal(&"action_selected", &"run")
			if name != "":
				await _frames(16)
				await _shot(name)
				name = ""
		await _frames(2)
	await _frames(40)


## Plus longue image (temps réel) de l'entrée en combat (rencontre → actions), décor préchargé
## à l'entrée de la carte (ou pas : --no-preload). Rencontre à part, terminée par la fuite.
func _entry_perf() -> void:
	await _until(func() -> bool:
		var cache: RefCounted = _stage.call(&"get_decor_cache") \
			if _stage.has_method(&"get_decor_cache") else null
		return cache == null or not _preload or cache.call(&"get_paths").is_empty() \
			or cache.call(&"is_ready", cache.call(&"get_paths")[0]), 600)
	if not _preload and _stage.has_method(&"get_decor_cache"):
		var empty: Array[String] = []
		_stage.call(&"get_decor_cache").call(&"prepare", empty)
	await _frames(10)
	var worst := 0
	var last := Time.get_ticks_usec()
	_encounter(&"pidgey", 3)
	while int(_hud.call(&"get_zone")) != 1:
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		last = now
	print("[perf] entrée %s (préchargement %s) : plus longue image %.1f ms"
		% [_place, "oui" if _preload else "non", worst / 1000.0])
	await _flee("")
	await _frames(30)


## Ton Pokémon (de dos) posé au sol pour chaque espèce de --starters (un combat chacun).
func _poses() -> void:
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var factory: GDScript = load("res://game/pokemon/pokemon_factory.gd")
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(7)
	var state: Node = root.get_node(^"GameState")
	for entry: StringName in _starters:
		# « espèce@taille » : taille (m) imposée, pour voir la boîte maximale d'un grand
		# Pokémon avec un dos provisoire existant (aucun dos de Florizarre / Dracaufeu).
		var parts := String(entry).split("@")
		var species := StringName(parts[0])
		if parts.size() > 1:
			var dex: RefCounted = load("res://game/pokemon/pokedex_library.gd").new()
			dex.call(&"add_from_dict", {"size": 151, "species": {parts[0]: {
				"height": float(parts[1]), "weight": 1.0, "description": "x"}}})
			_stage.call(&"set_species_source", data, dex)
		var party: RefCounted = load("res://game/pokemon/party.gd").new()
		party.call(&"add", factory.call(&"create", data, species, 9, rng))
		state.set(&"party", party)
		_encounter(&"rattata" if species != &"rattata" else &"pidgey", 3)
		await _wait_zone(1)
		await _frames(12)
		await _shot("joueur_%s" % String(entry).replace("@", "_"))
		await _flee("")
		await _frames(30)
		if parts.size() > 1:
			_stage.call(&"set_species_source", data, _boot.get(&"_dex"))


# --- Évolution après le combat (fusion du J9) -------------------------------------------

func _evolution() -> void:
	var data: RefCounted = _boot.call(&"get_pokemon_data")
	var factory: GDScript = load("res://game/pokemon/pokemon_factory.gd")
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(7)
	var state: Node = root.get_node(^"GameState")
	var party: RefCounted = load("res://game/pokemon/party.gd").new()
	var caterpie: RefCounted = factory.call(&"create", data, &"caterpie", 6, rng)
	var curve: GDScript = load("res://game/pokemon/exp_curve.gd")
	var species: RefCounted = data.call(&"get_species", &"caterpie")
	caterpie.set(&"experience", int(curve.call(&"exp_for_level", species.get(&"growth_rate"), 7)) - 1)
	caterpie.set(&"status", &"poison")
	party.call(&"add", caterpie)
	state.set(&"party", party)
	_encounter(&"rattata", 2)
	await _wait_zone(1)
	await _frames(12)
	await _shot("evo_combat")
	var evo: Node = _boot.call(&"get_evolution_director")
	var shots := 0
	var opened_at := -1
	var frame := 0
	while _director.call(&"is_running") and frame < 9000:
		frame += 1
		var summary: Control = _director.call(&"get_summary_card")
		var screen: Node = evo.call(&"get_screen")
		if summary != null and summary.visible and summary.call(&"is_waiting"):
			await _frames(10)
			await _shot("evo_bilan")
			summary.call(&"tap")
		elif screen != null and screen.call(&"is_open"):
			if opened_at < 0:
				opened_at = frame
			var since := frame - opened_at
			if shots == 0 and since >= 8:
				await _shot("evo_ouverture")
				shots = 1
			elif shots == 1 and screen.call(&"is_transforming") and since >= 150:
				await _shot("evo_transformation")
				shots = 2
			elif screen.call(&"is_waiting_touch"):
				if shots < 3 and screen.call(&"is_showing_new_form"):
					await _frames(20)
					await _shot("evo_fin")
					shots = 3
				_tap()
				await _frames(10)
		else:
			match int(_hud.call(&"get_zone")):
				1:
					_hud.emit_signal(&"action_selected", &"attack")
				2:
					_hud.emit_signal(&"move_selected", 0)
			# Messages qui attendent un toucher (capacité apprise).
			if frame % 60 == 0:
				_tap()
		await _frames(1)
	print("[qa] évolution : %s, statut %s" % [party.call(&"get_at", 0).get(&"species_id"),
		party.call(&"get_at", 0).get(&"status")])


func _tap() -> void:
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.pressed = pressed
		touch.position = root.get_visible_rect().size * Vector2(0.5, 0.3)
		root.push_input(touch, true)


# --- Repli -----------------------------------------------------------------------------

func _fallback() -> void:
	await _entry_perf()
	_encounter(&"pidgey", 3)
	await _until(func() -> bool: return _stage.call(&"is_active"), 300)
	await _frames(6)
	await _shot("transition")
	await _wait_zone(1)
	await _frames(12)
	await _shot("actions")
	await _perf("repli")
	await _flee("")


# --- Aperçu d'un décor (J12 T4) ---------------------------------------------------------

## Le décor [member _decor_id] (lu dans decors.json) tient lieu de décor de la carte de départ :
## aucune carte n'est branchée. Petit, moyen et grand Pokémon sur la ligne de sol.
func _decor_preview() -> void:
	var data: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/battle/decors.json"))
	data["places"] = {String(_place): [{"decor": String(_decor_id)}]}
	var catalog := BattleDecorCatalog.new()
	catalog.read(data)
	_stage.call(&"set_decor_catalog", catalog)
	await _frames(10)
	_encounter(&"pidgey", 3)
	await _until(func() -> bool: return _stage.call(&"is_active"), 300)
	await _frames(6)
	await _shot("transition")
	await _wait_zone(1)
	await _frames(12)
	await _shot("roucool")
	_hud.emit_signal(&"action_selected", &"attack")
	await _wait_zone(2)
	await _frames(12)
	await _shot("capacites")
	await _flee("")
	_encounter(&"rattata", 3)
	await _wait_zone(1)
	await _frames(12)
	await _shot("rattata")
	await _flee("")
	_encounter(&"charizard", 5)
	await _wait_zone(1)
	await _frames(12)
	await _shot("dracaufeu")
	await _flee("")


# --- Outils ----------------------------------------------------------------------------

func _encounter(species: StringName, level: int) -> void:
	var encounter: RefCounted = load("res://game/pokemon/encounters/wild_encounter.gd").new(
		species, level)
	if not _encounters.call(&"start_encounter", encounter):
		push_error("rencontre refusée : %s" % species)


func _wait_zone(zone: int) -> void:
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == zone, 900)


## Attend que [param done] rende vrai (au plus [param frames] images) ; vrai si atteint.
func _until(done: Callable, frames: int) -> bool:
	for i: int in frames:
		if done.call():
			return true
		await process_frame
	push_warning("attente dépassée")
	return false


## Mesure sur la vue posée : appels de dessin et mémoire des textures ; fps réels (temps
## mesuré sur 120 images) seulement utiles sans --fixed-fps et sans vsync (passe de mesure).
func _perf(label: String) -> void:
	await _frames(30)
	var start := Time.get_ticks_usec()
	await _frames(120)
	var fps := 120.0 / maxf((Time.get_ticks_usec() - start) / 1000000.0, 0.001)
	var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var tex := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
	print("[perf] %s %s : %d appels de dessin, %.1f Mo de textures, %.0f fps"
		% [_place, label, draws, tex, fps])


func _shot(name: String) -> void:
	paused = true
	for i: int in 6:
		await process_frame
	var path := _out_dir.path_join("cb3_%s_%s.png" % [
		_decor_id if _decor_id != &"" else _place, name])
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var ball: Sprite2D = _stage.call(&"get_ball") if _stage != null else null
	if ball != null:
		print("[qa] %s : Ball %s %s a=%.2f" % [name, ball.visible, ball.position, ball.modulate.a])
	# Fenêtre cachée ou occultée : macOS peut sauter des rendus ; on force celui de l'image.
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])
	paused = false


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
