extends Node
## Galerie d'effets (chantier Combat vivant, CV.0 T3 / T8 ; §2.8, §2.9) : joue des attaques à la
## suite sur un décor peint, sans combat ni sauvegarde, pour les captures Mac (Movie Maker) et la
## relecture image par image. Scène autonome, lancée à la main :
##   godot --path . res://game/battle/fx/fx_gallery.tscn -- --moves=tackle,ember --mode=fast
## Arguments (après `--`) : `--moves=` (identifiants, à la suite, en boucle), `--mode=`
## `full` | `fast` | `reduced`, `--foe` (l'adversaire attaque, en miroir), `--miss`,
## `--reduce-flashes`, `--freeze=<s>` (fige chaque attaque à cet instant, capture fixe).
## Le départ de débogage « galerie d'effets » de `DebugStart` viendra au branchement (après le J23).
## Placement approché du cadrage B ([BattleLayout]) [D] : la vraie scène vient avec [BattleStage].

const DEFAULT_MOVES: Array[StringName] = [&"tackle", &"scratch", &"bite", &"thunder_shock",
	&"ember", &"water_gun", &"swords_dance"]
const DECOR_BACK: String = "res://assets/battle/decors/route_1_chemin_back.webp"
const DECOR_FRONT: String = "res://assets/battle/decors/route_1_chemin_front.webp"
const USER_SPECIES: StringName = &"pikachu"
const USER_DEX: String = "025"
const FOE_SPECIES: StringName = &"pidgey"
const FOE_DEX: String = "016"
## Pieds et hauteur visible, en parts de la vue [D].
const PLAYER_FEET := Vector2(0.30, 1.04)
const PLAYER_HEIGHT: float = 0.62
const FOE_FEET := Vector2(0.70, 0.56)
const FOE_HEIGHT: float = 0.30
const PAUSE: float = 0.6

var _data: PokemonData
var _catalog: MoveFxCatalog
var _anchors: FxAnchors
var _layer: CanvasLayer
var _player: MoveFxPlayer
var _back_sprite: Sprite2D
var _front_sprite: Sprite2D
var _decor_back: Sprite2D
var _decor_front: Sprite2D
var _moves: Array[StringName] = []
var _mode: MoveFxPlan.Mode = MoveFxPlan.Mode.FULL
var _foe_attacks: bool = false
var _miss: bool = false
var _reduce_flashes: bool = false
var _freeze: float = -1.0


func _ready() -> void:
	_read_args()
	_data = PokemonData.new()
	_data.load_dir()
	_catalog = MoveFxCatalog.load_dir()
	_anchors = FxAnchors.load_file()
	_layer = CanvasLayer.new()
	add_child(_layer)
	var view := get_viewport().get_visible_rect().size
	var sky := ColorRect.new()
	sky.color = Color("#2A3A2E")
	sky.size = view
	_layer.add_child(sky)
	_decor_back = _decor(DECOR_BACK, view)
	_front_sprite = _pokemon("res://assets/sprites/pokemon/official/%s.png" % FOE_DEX)
	_decor_front = _decor(DECOR_FRONT, view)
	_back_sprite = _pokemon("res://assets/sprites/pokemon/dos/dos_ia_%s.png" % USER_DEX)
	_place(_back_sprite, PLAYER_FEET, PLAYER_HEIGHT, view)
	_place(_front_sprite, FOE_FEET, FOE_HEIGHT, view)
	_player = MoveFxPlayer.new()
	_layer.add_child(_player)
	_player.setup(_layer)
	_run.call_deferred()


func _run() -> void:
	var index := 0
	while is_inside_tree():
		var move_id := _moves[index % _moves.size()]
		var stage := _stage()
		var move := _data.get_move(move_id)
		var outcome := MoveFxOutcome.new()
		outcome.result = MoveFxOutcome.Result.MISSED if _miss else MoveFxOutcome.Result.HIT
		outcome.hits = 2 if _catalog.entry(move_id).has_modifier(&"multi") else 1
		var plan := MoveFxPlan.build(_catalog, _catalog.entry(move_id), move, outcome, _mode,
			_reduce_flashes)
		print("galerie : %s (%s) %.2f s, repères %s" % [move_id, plan.family, plan.duration,
			plan.cue_names()])
		if _freeze >= 0.0:
			_player.play(plan, stage)
			_player.advance(_freeze)
			_player.set_paused(true)
			await get_tree().create_timer(1.0).timeout
			_player.stop()
		else:
			await _player.play(plan, stage)
			await get_tree().create_timer(PAUSE).timeout
		index += 1


func _stage() -> MoveFxStage:
	var stage := MoveFxStage.new()
	var user := _front_sprite if _foe_attacks else _back_sprite
	var target := _back_sprite if _foe_attacks else _front_sprite
	stage.user = user
	stage.target = target
	stage.user_rest = user.get_meta(&"rest")
	stage.target_rest = target.get_meta(&"rest")
	stage.user_rect = user.get_meta(&"rect")
	stage.target_rect = target.get_meta(&"rect")
	stage.user_is_player = not _foe_attacks
	stage.decor_back = _decor_back
	stage.decor_front = _decor_front
	stage.view_size = get_viewport().get_visible_rect().size
	var species := FOE_SPECIES if _foe_attacks else USER_SPECIES
	var view_name := FxAnchors.FRONT if _foe_attacks else FxAnchors.BACK
	var plan_origin := MoveFxPlan.ORIGIN_MOUTH
	stage.origins = MoveFxStage.to_screen(_anchors.points(species, view_name, plan_origin),
		stage.user_rect)
	return stage


func _decor(path: String, view: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if sprite.texture != null:
		var size := sprite.texture.get_size()
		var k := maxf(view.x / size.x, view.y / size.y)
		sprite.scale = Vector2.ONE * k
		sprite.position = (view - size * k) * 0.5
	_layer.add_child(sprite)
	return sprite


func _pokemon(path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_layer.add_child(sprite)
	return sprite


## Pieds en [param feet] (parts de la vue), hauteur de l'image [param height] (part de la vue).
func _place(sprite: Sprite2D, feet: Vector2, height: float, view: Vector2) -> void:
	var size := sprite.texture.get_size()
	var k := height * view.y / size.y
	sprite.scale = Vector2.ONE * k
	sprite.offset = Vector2(0.0, -size.y * 0.5)
	sprite.position = feet * view
	sprite.set_meta(&"rest", sprite.position)
	sprite.set_meta(&"rect", Rect2(sprite.position - Vector2(size.x * 0.5, size.y) * k, size * k))


func _read_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--moves="):
			for id: String in arg.trim_prefix("--moves=").split(",", false):
				_moves.append(StringName(id))
		elif arg == "--mode=fast":
			_mode = MoveFxPlan.Mode.FAST
		elif arg == "--mode=reduced":
			_mode = MoveFxPlan.Mode.REDUCED
		elif arg == "--foe":
			_foe_attacks = true
		elif arg == "--miss":
			_miss = true
		elif arg == "--reduce-flashes":
			_reduce_flashes = true
		elif arg.begins_with("--freeze="):
			_freeze = arg.trim_prefix("--freeze=").to_float()
	if _moves.is_empty():
		_moves = DEFAULT_MOVES.duplicate()
