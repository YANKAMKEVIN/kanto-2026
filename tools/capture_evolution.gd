extends SceneTree
## Captures de l'écran d'évolution (jalon 9, T9) avec la vraie scène Boot : son
## EvolutionDirector et son EvolutionScreen, à vitesse réelle, sur la Route 1 sous le voile du
## combat. Chenipan N7 → Chrysacier (Armure apprise), puis une évolution annulée (retour
## Android), puis une offre d'oubli (quatre capacités).
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_evolution.gd -- --out=build/captures/jalon09_evolution
##
## Images (préfixe evolution_) :
##   01_ouverture        l'environnement disparaît (fondu vers la nuit)
##   02_debut            Chenipan au centre, « Quoi ? Chenipan évolue ! »
##   03_silhouette       transformation, silhouette blanche (début), ARRÊTER visible
##   04_transformation   transformation au plus fort (halo, rayons, bascules rapides)
##   05_flash            sommet du flash
##   06_silence          la nouvelle silhouette, immobile
##   07_revelation       les couleurs reviennent (halo doré, onde)
##   08_fin              « CHRYSACIER », phrase, consigne
##   09_capacite         « Chrysacier apprend Armure ! » dans le bandeau
##   10_annulation       annulée par le retour Android : « Hein ? Chenipan n'évolue plus. »
##   11_oubli            capacités pleines : le panneau d'oubli dans l'écran

const FPS := 30.0
const PREFIX := "evolution_"

var _out_dir: String = "build/captures/jalon09_evolution"
var _boot: Node
var _data: RefCounted
var _director: Node
var _done: bool = false


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	root.add_child(_boot)
	await _frames(20)
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.call(&"hide_interact")
	explo.call(&"set_controls_visible", false)
	_build_veil()
	_data = (load("res://game/pokemon/pokemon_data.gd") as GDScript).new()
	_data.call(&"load_dir")
	_director = _boot.call(&"get_evolution_director")
	await _frames(10)
	await _evolve()
	await _cancel()
	await _forget()
	print("CAPTURE_EVOLUTION terminé")
	quit()


## Évolution complète, puis la capacité apprise.
func _evolve() -> void:
	_play(_party([]))
	await _seconds(0.25)
	await _shot("01_ouverture")
	await _seconds(1.45)
	await _shot("02_debut")
	await _seconds(1.3)
	await _shot("03_silhouette")
	await _seconds(3.2)
	await _shot("04_transformation")
	await _seconds(0.85)
	await _shot("05_flash")
	await _seconds(0.4)
	await _shot("06_silence")
	await _seconds(0.45)
	await _shot("07_revelation")
	await _seconds(1.3)
	await _shot("08_fin")
	_touch()
	await _seconds(0.8)
	await _shot("09_capacite")
	await _until_done()


## Annulée par le retour Android au milieu de la transformation.
func _cancel() -> void:
	_play(_party([]))
	await _seconds(2.0 + 2.4)
	_director.call(&"handle_back")
	await _seconds(1.2)
	await _shot("10_annulation")
	await _until_done()


## Quatre capacités : Armure passe par le panneau d'oubli, dans l'écran.
func _forget() -> void:
	_play(_party([&"growl", &"scratch"]))
	await _seconds(2.0 + 5.0 + 2.0)
	_touch()
	await _seconds(2.0)
	await _shot("11_oubli")
	var screen: Node = _director.call(&"get_screen")
	var host: Control = screen.call(&"get_prompt_host")
	for child: Node in host.get_children():
		if child.has_method(&"get_skip_button"):
			(child.call(&"get_skip_button") as Button).pressed.emit()
	await _seconds(1.0)
	await _until_done()


func _party(extra_moves: Array) -> RefCounted:
	var party: RefCounted = (load("res://game/pokemon/party.gd") as GDScript).new()
	var factory := load("res://game/pokemon/pokemon_factory.gd") as GDScript
	var rng: RefCounted = (load("res://game/systems/random/game_rng.gd") as GDScript).new(7)
	var pokemon: RefCounted = factory.call(&"create", _data, &"caterpie", 7, rng)
	for move_id: StringName in extra_moves:
		pokemon.call(&"learn_move", move_id, _data)
	party.call(&"add", pokemon)
	return party


func _play(party: RefCounted) -> void:
	_done = false
	var evolution := load("res://game/pokemon/evolution/evolution.gd") as GDScript
	var leveled: Array[int] = [0]
	var found: Array = evolution.call(&"candidates", party, leveled, _data)
	var runner := func() -> void:
		await _director.call(&"play", found, party)
		_done = true
	runner.call()


## Touche l'écran de temps en temps (le bandeau ignore les touchers trop rapprochés, en temps
## réel) jusqu'à la fin des évolutions.
func _until_done() -> void:
	var guard := 0
	while not _done and guard < 1200:
		if guard % 20 == 0:
			_touch()
		await process_frame
		guard += 1
	await _seconds(0.3)


## Voile du combat sur la Route 1 (comme pendant un combat).
func _build_veil() -> void:
	var tokens := load("res://game/ui/theme/ui_tokens.gd") as GDScript
	var layer := CanvasLayer.new()
	layer.layer = tokens.LAYER_BATTLE_STAGE
	var dim := ColorRect.new()
	dim.color = Color(tokens.FADE_COLOR, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	root.add_child(layer)


func _touch() -> void:
	for pressed: bool in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.pressed = pressed
		touch.position = root.get_visible_rect().size * Vector2(0.5, 0.3)
		root.push_input(touch, true)


func _shot(name: String) -> void:
	var path := _out_dir.path_join(PREFIX + name + ".png")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])


func _seconds(seconds: float) -> void:
	await _frames(roundi(seconds * FPS))


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
