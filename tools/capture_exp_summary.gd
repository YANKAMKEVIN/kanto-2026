extends SceneTree
## Vérification visuelle du bilan de fin de combat (demande n° 1) : la vraie ExpSummaryCard
## dans l'écran de la vraie BattleHud, sur la Route 1 sous le voile du combat, avec les sprites
## provisoires du combat. Les lignes viennent du vrai pipeline : le moteur ([Battle], son gain
## d'XP) écrit les événements, [ExpSummary] les résume, [BattleViews] et [BattleText] les
## formulent. Vitesse réelle (images à 30 par seconde).
##
## Sur le Mac :
##   godot --path . --resolution 2340x1080 --always-on-top --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_exp_summary.gd -- --out=build/captures/jalon07_bilan_xp
## Images (préfixe jalon07_bilan_xp_) :
##   un_sans_niveau_mi     un Pokémon, sans niveau : barre en route
##   un_sans_niveau_fin    barres arrivées, consigne affichée
##   trois_un_niveau_mi    trois Pokémon, Salamèche monte : passage de niveau (ligne en valeur)
##   trois_un_niveau_fin   fin : « Nv. 8 ▸ Nv. 9 », gains, consigne
##   deux_niveaux_mi       un Pokémon qui prend deux niveaux : premier passage
##   deux_niveaux_fin      fin : « Nv. 10 », gains cumulés

const BOOT_SCENE: String = "res://game/boot.tscn"
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const HUD_SCENE: String = "res://game/ui/battle/battle_hud.tscn"
const CARD_SCENE: String = "res://game/ui/battle/exp_summary_card.tscn"
const SPRITES_DIR: String = "res://assets/sprites/pokemon/placeholder/"
const PREFIX: String = "jalon07_bilan_xp_"

var _out_dir: String = "build/captures/jalon07_bilan_xp"
var _tokens: GDScript
var _data: RefCounted
var _texts: RefCounted
var _hud: CanvasLayer
var _stage: CanvasLayer


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	_tokens = load(TOKENS_PATH) as GDScript
	_data = (load("res://game/pokemon/pokemon_data.gd") as GDScript).new()
	_data.call(&"load_dir")
	_texts = (load("res://game/battle/battle_text.gd") as GDScript).new()
	_texts.call(&"load_file")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	var boot := (load(BOOT_SCENE) as PackedScene).instantiate()
	boot.set(&"start_map", &"route_1")
	boot.set(&"start_spawn", &"from_pallet_w")
	root.add_child(boot)
	await _frames(20)
	var explo: CanvasLayer = boot.call(&"get_hud")
	explo.call(&"hide_interact")
	explo.call(&"set_controls_visible", false)
	await _frames(10)
	_build_stage()
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as CanvasLayer
	root.add_child(_hud)
	_hud.set(&"haptics_enabled", false)
	await _frames(2)
	# Un Pokémon, sans niveau : Salamèche N8, +11 XP.
	await _scene("un_sans_niveau", [[&"charmander", 8, 0.3, 11]], 18)
	# Trois Pokémon, Salamèche monte d'un niveau, les deux autres non.
	await _scene("trois_un_niveau", [[&"charmander", 8, 0.85, 42], [&"pidgey", 7, 0.2, 28],
		[&"rattata", 6, 0.1, 28]], 30)
	# Un Pokémon qui prend deux niveaux d'un coup.
	await _scene("deux_niveaux", [[&"charmander", 8, 0.6, 283]], 34)
	print("CAPTURE_EXP_SUMMARY terminé")
	quit()


## Joue un bilan : [param team] = [espèce, niveau, barre de départ (0..1), XP gagnée] par
## Pokémon ; capture à [param mid] images (en route) puis à la fin.
func _scene(name: String, team: Array, mid: int) -> void:
	var events := _events(team)
	var summary: RefCounted = (load("res://game/battle/exp_summary.gd") as GDScript) \
		.call(&"from_events", events)
	var rows: Array = (load("res://game/battle/battle_views.gd") as GDScript) \
		.call(&"exp_summary", summary, _texts)
	var entries: Array = summary.call(&"get_entries")
	for i: int in rows.size():
		var path := SPRITES_DIR + "%s_front.png" % entries[i].get(&"species_id")
		if ResourceLoader.exists(path):
			rows[i].set(&"portrait", load(path) as Texture2D)
	var card := (load(CARD_SCENE) as PackedScene).instantiate() as Control
	_hud.call(&"get_screen").add_child(card)
	var layout := load("res://game/ui/battle/battle_hud_layout.gd") as GDScript
	layout.call(&"place", card, layout.get(&"Slot")["SUMMARY"])
	card.set(&"haptics_enabled", false)
	await _frames(1)
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await card.call(&"show_summary", rows, _texts.call(&"get_template", &"summary_continue"))
		done[0] = true
	runner.call()
	await _frames(mid)
	await _shot(name + "_mi")
	while not done[0]:
		await process_frame
	await _frames(12)
	await _shot(name + "_fin")
	card.call(&"close")
	await card.call(&"wait_closed")
	card.queue_free()
	await _frames(4)


## Événements du vrai moteur : chaque Pokémon reçoit son XP par le gain du [Battle].
func _events(team: Array) -> Array:
	var party_script := load("res://game/pokemon/party.gd") as GDScript
	var factory := load("res://game/pokemon/pokemon_factory.gd") as GDScript
	var rng_script := load("res://game/systems/random/game_rng.gd") as GDScript
	var party: RefCounted = party_script.new()
	var pokemons: Array = []
	for spec: Array in team:
		var pokemon: RefCounted = factory.call(&"create", _data, spec[0], spec[1],
			rng_script.new(7))
		var span: Vector2i = (load("res://game/pokemon/exp_calc.gd") as GDScript) \
			.call(&"level_span", pokemon, _data)
		pokemon.set(&"experience", int(pokemon.get(&"experience")) + int(span.y * spec[2]))
		party.call(&"add", pokemon)
		pokemons.append(pokemon)
	var foes: RefCounted = party_script.new()
	foes.call(&"add", factory.call(&"create", _data, &"rattata", 3, rng_script.new(1)))
	var side := load("res://game/battle/battle_side.gd") as GDScript
	var rules: RefCounted = (load("res://game/battle/battle_rules.gd") as GDScript).new()
	var battle: RefCounted = (load("res://game/battle/battle.gd") as GDScript).new(
		side.new(party, true), side.new(foes, false), _data, rng_script.new(1), rules)
	var events := Array([], TYPE_OBJECT, &"RefCounted",
		load("res://game/battle/battle_event.gd") as GDScript)
	for i: int in pokemons.size():
		battle.call(&"_grant_exp", pokemons[i], team[i][3], events)
	return events


## Voile du combat et sprites provisoires aux ancres du combat.
func _build_stage() -> void:
	_stage = CanvasLayer.new()
	_stage.layer = _tokens.LAYER_BATTLE_STAGE
	var dim := ColorRect.new()
	dim.color = Color(_tokens.FADE_COLOR, _tokens.BATTLE_DIM)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(dim)
	root.add_child(_stage)
	var view := root.get_visible_rect().size
	_add_battler("charmander_back.png", Vector2(0.30, 0.76) * view, 4)


func _add_battler(file: String, feet: Vector2, scale: int) -> void:
	if not ResourceLoader.exists(SPRITES_DIR + file):
		return
	var sprite := Sprite2D.new()
	sprite.texture = load(SPRITES_DIR + file) as Texture2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2.ONE * scale
	var size := sprite.texture.get_size() * scale
	sprite.position = feet - Vector2(size.x * 0.5, size.y)
	_stage.add_child(sprite)


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join(PREFIX + name + ".png")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
