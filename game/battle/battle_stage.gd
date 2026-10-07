class_name BattleStage
extends CanvasLayer
## Vue de combat dans le décor réel (jalon-04.md §14.4, décisions de Kevin n° 10 et 17) :
## le labo reste chargé et vivant derrière ; la caméra du joueur le **recompose** (zoom et
## cadrage sur l'arène), un voile, un vignettage et un flou léger le mettent en retrait, et
## les deux Pokémon deviennent de grands sprites de combat composés en espace écran
## (BattleLayout, cadrage du pilote repris au CB.1 : le tien de dos au premier plan en bas à
## gauche, l'adversaire en haut à droite au second plan, **artwork officiel** étalonné dans la
## lumière du lieu avec une ombre au sol ; tailles normalisées par la taille réelle, BattleArt).
## Présentation seulement : le BattleDirector (T8) joue les temps du journal.
##
## Transition d'entrée (~1 s, jamais d'écran noir) : **un seul paramètre** anime tout. La
## caméra glisse et se rapproche ; chaque Pokémon du monde est remplacé (fondu croisé, même
## taille à l'écran) par son sprite de combat, qui part de sa place réelle — projetée par la
## caméra **en cours de mouvement** — et rejoint son ancre en quelques petits pas. Sa taille
## à l'écran suit la même courbe que le zoom : il grandit parce que le cadre se resserre et
## qu'il vient vers l'avant-plan, jamais sur place (consigne de Kevin n° 17).
## Sortie (~0,6 s) : l'inverse ; PNJ réaffichés, caméra (zoom, position, limites, décalage)
## rendue à l'identique.
## Tout est en Tween (rien dans _process) ; [member speed_scale] = 0 rend tout instantané.

## Émis quand l'entrée est finie (vue de combat en place) et quand la sortie est finie.
signal entered
signal exited

## Zoom de la caméra en combat : lieu réel resserré (cadrage « combat » du pilote, CB.1).
const ZOOM: float = 1.9
## Voile (opacité de UiTokens.FADE_COLOR), vignettage et flou du décor du pilote (CB.1) : le
## lieu reste reconnaissable (décision n° 17), les Pokémon s'en détachent.
const VEIL: float = 0.28
const VIGNETTE: float = 0.6
## Flou d'arrière-plan : niveau de mipmap (0 = coupé, si le S24 perd des images).
const BLUR_ENABLED: bool = true
const BLUR_LOD: float = 1.6
## Durées (s) à speed_scale = 1.
const ENTER_DURATION: float = 1.0
const EXIT_DURATION: float = 0.6
## Découpage de l'entrée (fractions de ENTER_DURATION) : fondu croisé monde → combat,
## trajet des sprites (même courbe que la caméra), fin de la caméra.
const SWAP_END: float = 0.14
const TRAVEL_START: float = 0.06
const TRAVEL_END: float = 0.82
const CAMERA_END: float = 0.82
## Sortie : fondu croisé sprite → PNJ sur la dernière fraction du trajet.
const EXIT_SWAP: float = 0.2
## Petits pas du trajet : nombre de bonds et hauteur (px écran) ; le Pokémon du joueur
## vient de plus loin, il fait plus de pas.
const PLAYER_HOPS: int = 3
## Trajet : la profondeur (hauteur à l'écran, taille) se fait sur les DEPTH_LEAD premiers du
## trajet, le déplacement latéral commence après SIDE_DELAY.
const DEPTH_LEAD: float = 0.7
const SIDE_DELAY: float = 0.25
const FOE_HOPS: int = 2
const HOP_HEIGHT: float = 16.0
## Éclat du sprite de combat au moment où il remplace celui du monde (modulate).
const SWAP_GLOW := Color(1.5, 1.5, 1.5, 1.0)
## Ombre au sol (ellipse douce sous les pieds) : largeur (fraction de la boîte visible) et
## écrasement (hauteur / largeur) ; couleur : ombre de contact du lieu (battle_shadow.gdshader).
const SHADOW_WIDTH: float = 0.7
const SHADOW_FLATTEN: float = 0.2
const SHADOW_SHADER: Shader = preload("res://game/battle/battle_shadow.gdshader")
## Étalonnage des artworks officiels dans la lumière du lieu.
const ARTWORK_SHADER: Shader = preload("res://game/battle/battle_artwork.gdshader")
## Apparition d'un Pokémon sans PNJ dans le monde ([method show_pokemon]).
const APPEAR_DURATION: float = 0.3
const APPEAR_DROP: float = 24.0
## Rencontre sauvage (jalon 5 §3.7) : recadrage caméra + voile, apparition du sauvage
## (bond + fondu), puis entrée du partenaire en courant depuis le bord gauche. Aucun écran
## noir : la Route 1 reste le fond. Durées (s) à speed_scale = 1, réglables sur le S24.
const WILD_CAMERA_DURATION: float = 0.30
const WILD_APPEAR_DURATION: float = 0.30
const WILD_APPEAR_DROP: float = 40.0
const PARTNER_ENTER_DURATION: float = 0.32
## Animations des temps (dossier 05 §4, §9) : élan physique, pulsation spéciale, bond de
## statut, coup (clignotement + tremblement), K.O. (chute + fondu).
const LUNGE_DISTANCE: float = 60.0
const LUNGE_OUT: float = 0.12
const LUNGE_BACK: float = 0.18
const SPECIAL_GLOW := Color(1.8, 1.8, 1.8, 1.0)
const SPECIAL_PULSE: float = 0.14
const STATUS_HOP: float = 18.0
const STATUS_HOP_DURATION: float = 0.16
const HIT_BLINKS: int = 3
const HIT_BLINK: float = 0.06
const HIT_SHAKE: float = 10.0
const HIT_ALPHA: float = 0.25
## Coup critique : éclair blanc bref et très léger tremblement de la scène (px monde).
const CRIT_FLASH: float = 0.35
const CRIT_FLASH_DURATION: float = 0.16
const CRIT_CAMERA_SHAKE: float = 4.0
const STAT_UP := Color(1.35, 1.25, 0.85, 1.0)
const STAT_DOWN := Color(0.7, 0.8, 1.35, 1.0)
const STAT_PULSE: float = 0.16
const STAT_NUDGE: float = 8.0
const FAINT_DROP: float = 40.0
const FAINT_DURATION: float = 0.45
## Rappel dans la Poké Ball (jalon 7, changement de Pokémon) : le Pokémon rougit, rétrécit vers
## le sol et s'efface (provisoire jusqu'à la DA ; pas de Ball dessinée, le nouveau entre par
## [method show_pokemon]).
const WITHDRAW_TINT := Color(1.6, 0.45, 0.45, 0.0)
const WITHDRAW_SCALE: float = 0.2
const WITHDRAW_DURATION: float = 0.35
## Capture (jalon 5D, jalon-05.md §3.10, storyboard combat-capture-v1) : le dresseur de dos
## entre en bas à gauche, la Ball part de sa main en arc, le Pokémon sauvage est absorbé dans un
## éclat rouge, la Ball tombe dans l'herbe (ombre au sol), tremble 0 à 3 fois, puis éclat doré
## (capturé) ou éclat blanc (libéré : le Pokémon ressort). Sprites provisoires (pixel art,
## NEAREST), tout en Tween ; durées (s) à speed_scale = 1, réglables sur le S24.
const BALL_TEXTURE: Texture2D = preload("res://assets/sprites/pokemon/placeholder/poke_ball.png")
const THROWER_TEXTURE: Texture2D = preload(
	"res://assets/sprites/pokemon/placeholder/trainer_back.png")
const SHADOW_TEXTURE: Texture2D = preload(
	"res://assets/sprites/pokemon/placeholder/battle_shadow.png")
## Échelles d'affichage : dresseur (64 px natifs), Ball en vol (loin) puis au sol (près).
## La Ball au sol est aux pieds de l'adversaire, au second plan (CB.1 : ×4, avant ×6).
const THROWER_SCALE: int = 6
const BALL_FLIGHT_SCALE: float = 3.0
const BALL_REST_SCALE: float = 4.0
## Rayon de la Ball dans son image (px natifs) : sa hauteur au-dessus du sol une fois posée.
const BALL_RADIUS: float = 15.0
## Dresseur : pieds à cette distance du centre d'écran (en hauteurs d'écran, vers la gauche) et
## à cette hauteur (en hauteurs d'écran depuis le haut, > 1 : les jambes sortent du cadre) ;
## glissement d'entrée (px). CB.1 : à gauche de ton Pokémon, qui est au premier plan.
const THROWER_OFFSET_X: float = 0.74
const THROWER_FEET_Y: float = 1.04
const THROWER_SLIDE: float = 220.0
const THROWER_ENTER_DURATION: float = 0.30
## Main du dresseur dans son image (px natifs depuis le bas-centre) : départ de la Ball.
const THROWER_HAND := Vector2(28.0, -54.0)
## Vol de la Ball : durée, hauteur de l'arc (hauteurs d'écran), tours sur elle-même.
const THROW_DURATION: float = 0.42
const THROW_ARC: float = 0.16
const THROW_SPINS: float = 2.0
## Absorption du Pokémon sauvage, chute de la Ball (rebonds) et éclat rouge.
const ABSORB_DURATION: float = 0.45
const ABSORB_SHRINK: float = 0.15
const ABSORB_TINT := Color(3.0, 0.7, 0.6, 1.0)
const BALL_DROP_DURATION: float = 0.55
const BALL_DROP_HEIGHT: float = 40.0
## Secousse : durée, angle (degrés), traits de mouvement (distance au bord de la Ball, px).
const SHAKE_DURATION: float = 0.6
const SHAKE_ANGLE: float = 24.0
const SHAKE_LINE_GAP: float = 40.0
## Éclat : durée, taille finale (échelle de la lueur), étincelles, voile de l'écran.
const BURST_DURATION: float = 0.55
const BURST_SCALE: float = 6.0
const BURST_GOLD := Color(1.0, 0.82, 0.30, 1.0)
const BURST_WHITE := Color(1.0, 1.0, 1.0, 1.0)
const BURST_RED := Color(1.0, 0.25, 0.20, 1.0)
const SPARK_COUNT: int = 10
const SPARK_DISTANCE: float = 260.0
const CATCH_FLASH: float = 0.30
## Flashs réduits (Accessibilité, jalon-06.md §6.12) : le clignotement du coup devient un
## léger assombrissement ; le flash du critique, de la capture et des éclats sont adoucis.
const REDUCED_HIT_DIM := Color(0.72, 0.72, 0.72, 1.0)
const REDUCED_FLASH_GAIN: float = 0.35
const CATCH_HOP: float = 36.0
## Le Pokémon libéré ressort de la Ball.
const RELEASE_DURATION: float = 0.40
## Pas « instantané » (speed_scale = 0) : avance d'un tween jusqu'à sa fin.
const INSTANT_STEP: float = 1000.0
## Hauteur affichée d'un Pokémon du monde sans AnimatedSprite2D lisible (32 px ×2).
const WORLD_HEIGHT_FALLBACK: float = 64.0
const LIMIT_FREE: int = 10000000

## Multiplicateur des durées (0 = instantané, tests).
var speed_scale: float = 1.0
## Accessibilité : pas de clignotement ni d'éclair vif (voir [constant REDUCED_HIT_DIM]).
var reduce_flashes: bool = false
## Flou du fond du combat ; coupé en profil Économie.
var backdrop_blur: bool = true:
	set(value):
		backdrop_blur = value
		_apply_blur()

var _active: bool = false
var _camera: Camera2D
## État de la caméra avant l'entrée, rendu à la sortie.
var _cam_zoom: Vector2 = Vector2.ONE
var _cam_position: Vector2 = Vector2.ZERO
var _cam_offset: Vector2 = Vector2.ZERO
var _cam_limits: Array[int] = []
var _cam_start_center: Vector2 = Vector2.ZERO
var _focus: Vector2 = Vector2.ZERO
## Arène et limites de la carte ([method set_frame]), en pixels monde ; vides : aucune.
var _arena: Rect2 = Rect2()
var _bounds: Rect2 = Rect2()
## PNJ Pokémon du monde par côté (null : aucun), et leur position monde (pieds).
var _world: Dictionary[BattleEvent.SideId, Node2D] = {}
var _world_feet: Dictionary[BattleEvent.SideId, Vector2] = {}
var _world_height: Dictionary[BattleEvent.SideId, float] = {}
var _world_modulate: Dictionary[BattleEvent.SideId, Color] = {}
var _species: Dictionary[BattleEvent.SideId, StringName] = {}
## Côtés K.O. : leur sprite reste caché jusqu'à la sortie.
var _fainted: Dictionary[BattleEvent.SideId, bool] = {}
var _anchors: Dictionary = {}
## Image de chaque côté : boîte visible (px de la texture, pieds au bas-centre) et échelle.
var _boxes: Dictionary[BattleEvent.SideId, Rect2] = {}
var _scales: Dictionary[BattleEvent.SideId, float] = {}
var _art := BattleArt.new()
var _artwork_material: ShaderMaterial
var _shadow_texture: GradientTexture2D
var _tweens: Array[Tween] = []
## Capture (5D) : accessoires créés au premier besoin (aucun dans la scène .tscn).
var _ball: Sprite2D
var _ball_shadow: Sprite2D
var _thrower: Sprite2D
var _glow: Sprite2D
var _sparks: Array[Sprite2D] = []
var _shake_lines: Array[Line2D] = []
## Centre de la Ball au sol, et point d'où le Pokémon est absorbé / ressort (écran).
var _ball_rest: Vector2 = Vector2.ZERO
var _absorb_point: Vector2 = Vector2.ZERO

@onready var _backdrop: ColorRect = %Backdrop
@onready var _flash: ColorRect = %Flash
@onready var _sprites: Dictionary[BattleEvent.SideId, Sprite2D] = {
	BattleEvent.SideId.PLAYER: %PlayerSprite,
	BattleEvent.SideId.FOE: %FoeSprite,
}
@onready var _shadows: Dictionary[BattleEvent.SideId, Sprite2D] = {
	BattleEvent.SideId.PLAYER: %PlayerShadow,
	BattleEvent.SideId.FOE: %FoeShadow,
}


func _ready() -> void:
	layer = UiTokens.LAYER_BATTLE_STAGE
	var material := _backdrop.material as ShaderMaterial
	material.set_shader_parameter(&"veil_color", UiTokens.FADE_COLOR)
	material.set_shader_parameter(&"veil", VEIL)
	material.set_shader_parameter(&"vignette", VIGNETTE)
	_build_shadows()
	_artwork_material = ShaderMaterial.new()
	_artwork_material.shader = ARTWORK_SHADER
	_apply_blur()
	_apply_reset()


func _apply_blur() -> void:
	if not is_node_ready():
		return
	var material := _backdrop.material as ShaderMaterial
	material.set_shader_parameter(&"blur_lod", BLUR_LOD if BLUR_ENABLED and backdrop_blur else 0.0)


## Opacité d'un éclair plein écran selon [member reduce_flashes].
func _flash_alpha(alpha: float) -> float:
	return alpha * REDUCED_FLASH_GAIN if reduce_flashes else alpha


## Chemin du sprite provisoire de [param species] (de dos si [param back]) ; l'adversaire est
## affiché en artwork officiel quand il existe (BattleArt).
static func sprite_path(species: StringName, back: bool) -> String:
	return BattleArt.placeholder_path(species, back)


## Données d'espèces (numéro du Pokédex) et du Pokédex (taille réelle) pour les images et les
## tailles de combat (Boot) ; sans appel, BattleArt les lit une fois.
func set_species_source(pokemon: PokemonData, dex: PokedexLibrary) -> void:
	_art.setup(pokemon, dex)


## Cadrage du prochain combat (à appeler avant [method enter]) : [param arena], sol dégagé à
## mettre entre les deux Pokémon (GameMap.get_battle_arena_rect) ; [param bounds], rectangle
## de la carte (GameMap.get_pixel_rect) que la vue ne quitte pas si elle est assez grande.
## Sans arène, le cadrage vise le milieu des combattants et des dresseurs.
func set_frame(arena: Rect2, bounds: Rect2) -> void:
	_arena = arena
	_bounds = bounds


## Coroutine (~1 s) : passe de la vue d'exploration à la vue de combat. [param camera] : la
## caméra du joueur ; [param player_pokemon] / [param foe_pokemon] : PNJ Pokémon du monde qui
## combattent (null : le sprite apparaît à son ancre) ; [param trainer_cells] : cases des
## dresseurs, pour le cadrage (la case du parent de la caméra — le joueur — est ajoutée si
## elle est lisible). Refusé (erreur) si un combat est déjà affiché.
func enter(camera: Camera2D, player_pokemon: Node2D, foe_pokemon: Node2D,
		player_species: StringName, foe_species: StringName,
		trainer_cells: Array[Vector2i] = []) -> void:
	if _active:
		push_error("BattleStage : un combat est déjà affiché")
		return
	if camera == null:
		push_error("BattleStage : caméra absente")
		return
	_active = true
	_camera = camera
	_save_camera()
	_anchors = BattleLayout.anchors(_view_size())
	_species = {BattleEvent.SideId.PLAYER: player_species,
		BattleEvent.SideId.FOE: foe_species}
	_world = {BattleEvent.SideId.PLAYER: player_pokemon, BattleEvent.SideId.FOE: foe_pokemon}
	var cells: Array[Vector2i] = trainer_cells.duplicate()
	var owner_node := camera.get_parent()
	if owner_node != null and owner_node.has_method(&"get_cell"):
		cells.append(owner_node.call(&"get_cell"))
	for side: BattleEvent.SideId in _world:
		var npc := _world[side]
		if npc == null:
			continue
		_world_feet[side] = npc.global_position
		_world_height[side] = _world_sprite_height(npc)
		_world_modulate[side] = npc.modulate
		cells.append(Grid.world_to_cell(npc.global_position))
	if _arena.has_area():
		_focus = BattleLayout.arena_focus(_arena, _bounds, _view_size(), ZOOM)
	elif not cells.is_empty():
		_focus = BattleLayout.clamp_focus(BattleLayout.focus(cells), _bounds, _view_size(), ZOOM)
	else:
		_focus = _cam_start_center
	for side: BattleEvent.SideId in _sprites:
		_prepare_sprite(side)
	# Limites levées : la caméra part de son centre réel (bornes comprises), sans saut.
	_free_camera()
	var tween := _new_tween()
	tween.tween_method(_set_enter_progress, 0.0, 1.0, ENTER_DURATION)
	await _play(tween)
	if _active:
		entered.emit()


## Affiche le Pokémon de [param side] ([param species]) à son ancre s'il n'y est pas déjà
## (Pokémon sans PNJ dans le monde, ou suivant après un K.O.) ; sans effet s'il est affiché.
func show_pokemon(side: BattleEvent.SideId, species: StringName) -> void:
	var sprite := _sprites[side]
	if not _active:
		return
	if sprite.visible and _species.get(side, &"") == species and sprite.modulate.a > 0.0:
		return
	_species[side] = species
	_fainted.erase(side)
	_set_texture(side)
	var feet := _anchor(side)
	sprite.visible = true
	_shadows[side].visible = true
	_place(side, feet + Vector2(0.0, -APPEAR_DROP), _anchor_scale(side))
	sprite.modulate = Color(1, 1, 1, 0)
	_shadows[side].modulate = Color(1, 1, 1, 0)
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, ^"position", feet, APPEAR_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, APPEAR_DURATION)
	tween.tween_property(_shadows[side], ^"modulate", Color.WHITE, APPEAR_DURATION)
	_play(tween)


## Coroutine (~0,6 s avec l'apparition) : entrée d'une rencontre sauvage (jalon 5 §3.7). Le
## décor de [param camera] est recadré et voilé (comme l'entrée du 4B, mais sans PNJ du monde),
## puis le sauvage [param foe_species] apparaît à sa place de combat (bond depuis le bas +
## fondu). Le cadrage vise [param origin_world] (l'herbe qui bouge) et le joueur. Le partenaire
## entre ensuite par [method play_partner_enter]. Refusé (erreur) si un combat est déjà affiché.
func play_wild_intro(camera: Camera2D, foe_species: StringName, origin_world: Vector2) -> void:
	if _active:
		push_error("BattleStage : un combat est déjà affiché")
		return
	if camera == null:
		push_error("BattleStage : caméra absente")
		return
	_active = true
	_camera = camera
	_save_camera()
	_anchors = BattleLayout.anchors(_view_size())
	_species = {BattleEvent.SideId.FOE: foe_species}
	_world = {}
	var cells: Array[Vector2i] = [Grid.world_to_cell(origin_world)]
	var owner_node := camera.get_parent()
	if owner_node != null and owner_node.has_method(&"get_cell"):
		cells.append(owner_node.call(&"get_cell"))
	if _arena.has_area():
		_focus = BattleLayout.arena_focus(_arena, _bounds, _view_size(), ZOOM)
	else:
		_focus = BattleLayout.clamp_focus(BattleLayout.focus(cells), _bounds, _view_size(), ZOOM)
	_prepare_sprite(BattleEvent.SideId.FOE)
	_free_camera()
	# Recadrage + voile (pas de PNJ à faire voyager : c'est un sauvage).
	var tween := _new_tween()
	tween.tween_method(_set_recompose, 0.0, 1.0, WILD_CAMERA_DURATION)
	await _play(tween)
	if _active:
		await _appear(BattleEvent.SideId.FOE, WILD_APPEAR_DROP, WILD_APPEAR_DURATION)


## Coroutine (~0,3 s) : le partenaire [param player_species] entre en courant depuis le bord
## gauche jusqu'à sa place de combat (jalon 5 §3.7, Q15 : pas de lancer de Ball). À appeler
## après [method play_wild_intro].
func play_partner_enter(player_species: StringName) -> void:
	if not _active:
		return
	var side := BattleEvent.SideId.PLAYER
	_species[side] = player_species
	_fainted.erase(side)
	_set_texture(side)
	var feet := _anchor(side)
	var scale := _anchor_scale(side)
	var start := Vector2(-_box(side).size.x * scale, feet.y)
	var sprite := _sprites[side]
	sprite.visible = true
	sprite.modulate = Color.WHITE
	_shadows[side].visible = true
	_shadows[side].modulate = Color.WHITE
	_place(side, start, scale)
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, ^"position", feet, PARTNER_ENTER_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_shadows[side], ^"position", feet, PARTNER_ENTER_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _play(tween)
	_rest(side)


## Coroutine : le Pokémon de [param side] utilise une capacité de [param category].
func play_move(side: BattleEvent.SideId, category: MoveData.Category) -> void:
	if not _active:
		return
	var sprite := _sprites[side]
	var base := _anchor(side)
	var tween := _new_tween()
	match category:
		MoveData.Category.PHYSICAL:
			var toward := (_anchor(_other(side)) - base).normalized() * LUNGE_DISTANCE
			tween.tween_property(sprite, ^"position", base + toward, LUNGE_OUT) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, ^"position", base, LUNGE_BACK) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		MoveData.Category.SPECIAL:
			for i: int in 2:
				tween.tween_property(sprite, ^"modulate", SPECIAL_GLOW, SPECIAL_PULSE)
				tween.tween_property(sprite, ^"modulate", Color.WHITE, SPECIAL_PULSE)
		_:
			for i: int in 2:
				tween.tween_property(sprite, ^"position", base + Vector2(0, -STATUS_HOP),
					STATUS_HOP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(sprite, ^"position", base, STATUS_HOP_DURATION) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _play(tween)
	_rest(side)


## Coroutine : le Pokémon de [param side] est touché (clignotement et tremblement ; sur un
## coup critique, éclair bref et léger tremblement de la scène, puis retour au cadrage).
func play_hit(side: BattleEvent.SideId, critical: bool) -> void:
	if not _active:
		return
	var sprite := _sprites[side]
	var base := _anchor(side)
	var tween := _new_tween()
	tween.set_parallel(true)
	if reduce_flashes:
		# Un seul assombrissement doux à la place du clignotement.
		tween.tween_property(sprite, ^"modulate", REDUCED_HIT_DIM, HIT_BLINK * 2.0)
		tween.tween_property(sprite, ^"modulate", Color.WHITE, HIT_BLINK * 2.0) \
			.set_delay(HIT_BLINK * 2.0)
	else:
		for i: int in HIT_BLINKS:
			tween.tween_property(sprite, ^"modulate:a", HIT_ALPHA, HIT_BLINK) \
				.set_delay(HIT_BLINK * 2 * i)
			tween.tween_property(sprite, ^"modulate:a", 1.0, HIT_BLINK) \
				.set_delay(HIT_BLINK * (2 * i + 1))
	var shake := HIT_SHAKE
	for i: int in HIT_BLINKS * 2:
		tween.tween_property(sprite, ^"position", base + Vector2(shake, 0), HIT_BLINK / 2.0) \
			.set_delay(HIT_BLINK * i)
		shake = -shake * 0.8
	tween.tween_property(sprite, ^"position", base, HIT_BLINK / 2.0) \
		.set_delay(HIT_BLINK * HIT_BLINKS * 2)
	if critical:
		_flash.color = Color(1, 1, 1, _flash_alpha(CRIT_FLASH))
		tween.tween_property(_flash, ^"color:a", 0.0, CRIT_FLASH_DURATION)
		for i: int in 4:
			var jolt := Vector2(CRIT_CAMERA_SHAKE * (1 if i % 2 == 0 else -1), 0)
			tween.tween_property(_camera, ^"offset", _cam_offset + jolt, HIT_BLINK / 2.0) \
				.set_delay(HIT_BLINK * i / 2.0)
		tween.tween_property(_camera, ^"offset", _cam_offset, HIT_BLINK / 2.0) \
			.set_delay(HIT_BLINK * 2.0)
	await _play(tween)
	_rest(side)
	_flash.color = Color(1, 1, 1, 0)
	if _camera != null:
		_camera.offset = _cam_offset


## Coroutine : effet de statistique sur le Pokémon de [param side] (teinte chaude et petit
## redressement si [param rising], teinte froide et tassement sinon).
func play_stat(side: BattleEvent.SideId, rising: bool) -> void:
	if not _active:
		return
	var sprite := _sprites[side]
	var base := _anchor(side)
	var tint := STAT_UP if rising else STAT_DOWN
	var nudge := Vector2(0, -STAT_NUDGE if rising else STAT_NUDGE)
	var tween := _new_tween()
	for i: int in 2:
		tween.tween_property(sprite, ^"modulate", tint, STAT_PULSE)
		tween.parallel().tween_property(sprite, ^"position", base + nudge, STAT_PULSE)
		tween.tween_property(sprite, ^"modulate", Color.WHITE, STAT_PULSE)
		tween.parallel().tween_property(sprite, ^"position", base, STAT_PULSE)
	await _play(tween)
	_rest(side)


## Coroutine : le Pokémon de [param side] tombe K.O. (chute et fondu, ombre comprise).
func play_faint(side: BattleEvent.SideId) -> void:
	if not _active:
		return
	var sprite := _sprites[side]
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, ^"position", _anchor(side) + Vector2(0, FAINT_DROP),
		FAINT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, ^"modulate:a", 0.0, FAINT_DURATION)
	tween.tween_property(_shadows[side], ^"modulate:a", 0.0, FAINT_DURATION)
	await _play(tween)
	_fainted[side] = true
	sprite.visible = false
	_shadows[side].visible = false


## Coroutine : le Pokémon de [param side] est rappelé (jalon 7) : il rougit, rétrécit vers ses
## pieds et s'efface, ombre comprise ; il est ensuite caché ([method show_pokemon] fera entrer le
## suivant). Sans effet hors combat ou s'il n'est pas affiché.
func play_withdraw(side: BattleEvent.SideId) -> void:
	var sprite := _sprites[side]
	if not _active or not sprite.visible:
		return
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, ^"scale", sprite.scale * WITHDRAW_SCALE, WITHDRAW_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, ^"modulate", WITHDRAW_TINT, WITHDRAW_DURATION)
	tween.tween_property(_shadows[side], ^"modulate:a", 0.0, WITHDRAW_DURATION)
	await _play(tween)
	sprite.visible = false
	_shadows[side].visible = false
	_species.erase(side)


## Coroutine (~1,5 s) : le dresseur lance la Ball sur le Pokémon sauvage (jalon 5D). Il entre
## dans le cadrage (de dos, en bas à gauche), la Ball part de sa main en arc, le Pokémon est
## absorbé dans un éclat rouge, puis la Ball tombe dans l'herbe, où elle reste (ombre au sol)
## jusqu'à [method play_catch_burst], [method play_break_free] ou [method exit]. Sans effet hors
## combat.
func play_throw() -> void:
	if not _active:
		return
	_build_capture_props()
	var view := _view_size()
	var foe := BattleEvent.SideId.FOE
	var scale := float(THROWER_SCALE)
	var feet := Vector2(view.x * 0.5 - THROWER_OFFSET_X * view.y, THROWER_FEET_Y * view.y)
	var target := _foe_center()
	_ball_rest = _anchor(foe) + Vector2(0.0, -BALL_RADIUS * BALL_REST_SCALE + 6.0)
	_absorb_point = target
	# Le dresseur entre en glissant depuis la gauche.
	_thrower.texture = THROWER_TEXTURE
	_thrower.scale = Vector2.ONE * scale
	_thrower.position = feet + Vector2(-THROWER_SLIDE, 0.0)
	_thrower.modulate = Color(1, 1, 1, 0)
	_thrower.visible = true
	var enter := _new_tween()
	enter.set_parallel(true)
	enter.tween_property(_thrower, ^"position", feet, THROWER_ENTER_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	enter.tween_property(_thrower, ^"modulate:a", 1.0, THROWER_ENTER_DURATION)
	await _play(enter)
	if not _active:
		return
	# La Ball part de sa main, en arc, et tourne sur elle-même.
	var hand := feet + THROWER_HAND * scale
	_ball.visible = true
	_ball.modulate = Color.WHITE
	_ball.rotation = 0.0
	_ball.position = hand
	_ball.scale = Vector2.ONE * BALL_FLIGHT_SCALE * 1.4
	var flight := _new_tween()
	flight.set_parallel(true)
	flight.tween_method(_set_ball_flight.bind(hand, target, view.y * THROW_ARC),
		0.0, 1.0, THROW_DURATION)
	flight.tween_property(_thrower, ^"position", feet + Vector2(24.0, 0.0), 0.12)
	flight.tween_property(_thrower, ^"modulate:a", 0.0, 0.25).set_delay(0.15)
	await _play(flight)
	if not _active:
		return
	_thrower.visible = false
	# Impact : éclat rouge, le Pokémon est absorbé dans la Ball.
	_glow.modulate = BURST_RED
	_glow.position = target
	_glow.visible = true
	var absorb := _new_tween()
	absorb.tween_method(_set_absorb_flash, 0.0, 1.0, ABSORB_DURATION)
	await _play(absorb)
	if not _active:
		return
	_glow.visible = false
	_fainted[foe] = true
	_sprites[foe].visible = false
	_shadows[foe].visible = false
	# La Ball tombe dans l'herbe : chute à rebonds, l'ombre se pose sous elle.
	_ball_shadow.position = _anchor(foe) + Vector2(0.0, -1.5 * BALL_REST_SCALE)
	_ball_shadow.scale = Vector2.ONE * BALL_REST_SCALE
	_ball_shadow.modulate = Color(1, 1, 1, 0)
	_ball_shadow.visible = true
	var drop := _new_tween()
	drop.set_parallel(true)
	drop.tween_property(_ball, ^"position", _ball_rest, BALL_DROP_DURATION) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop.tween_property(_ball, ^"scale", Vector2.ONE * BALL_REST_SCALE, BALL_DROP_DURATION)
	drop.tween_property(_ball, ^"rotation", 0.0, BALL_DROP_DURATION)
	drop.tween_property(_ball_shadow, ^"modulate:a", 1.0, BALL_DROP_DURATION * 0.5)
	await _play(drop)


## Coroutine (~0,6 s) : une secousse de la Ball posée dans l'herbe (jalon 5D) : elle penche à
## droite, à gauche, puis se redresse ; des traits de mouvement apparaissent de chaque côté.
## Sans effet hors combat ou sans Ball posée.
func play_ball_shake() -> void:
	if not _active or _ball == null or not _ball.visible:
		return
	var tilt := deg_to_rad(SHAKE_ANGLE)
	var quarter := SHAKE_DURATION / 4.0
	var reach := BALL_RADIUS * BALL_REST_SCALE + SHAKE_LINE_GAP
	for i: int in _shake_lines.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		_shake_lines[i].position = _ball_rest + Vector2(side * reach, 0.0)
		_shake_lines[i].modulate.a = 0.0
		_shake_lines[i].visible = true
	var tween := _new_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_ball, ^"rotation", tilt, quarter)
	tween.tween_property(_ball, ^"rotation", -tilt, quarter * 1.5)
	tween.tween_property(_ball, ^"rotation", tilt * 0.4, quarter * 1.0)
	tween.tween_property(_ball, ^"rotation", 0.0, quarter * 0.5)
	for line: Line2D in _shake_lines:
		var fade := _new_tween()
		fade.tween_property(line, ^"modulate:a", 0.9, quarter * 0.5)
		fade.tween_property(line, ^"modulate:a", 0.0, SHAKE_DURATION - quarter * 0.5)
		_play(fade)
	await _play(tween)
	if _ball != null:
		_ball.rotation = 0.0
	for line: Line2D in _shake_lines:
		line.visible = false


## Coroutine (~0,55 s) : la capture réussit (jalon 5D) : la Ball fait un petit bond, éclat doré
## avec étincelles et lueur dorée sur tout l'écran. La Ball reste posée jusqu'à [method exit].
func play_catch_burst() -> void:
	if not _active or _ball == null or not _ball.visible:
		return
	var origin := _ball_rest + Vector2(0.0, -BALL_RADIUS * BALL_REST_SCALE * 0.4)
	_flash.color = Color(BURST_GOLD, _flash_alpha(CATCH_FLASH))
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_property(_ball, ^"position", _ball_rest + Vector2(0.0, -CATCH_HOP), 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_ball, ^"position", _ball_rest, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.14)
	tween.tween_method(_set_burst.bind(origin, BURST_GOLD), 0.0, 1.0, BURST_DURATION)
	tween.tween_property(_flash, ^"color:a", 0.0, BURST_DURATION)
	await _play(tween)
	_glow.visible = false
	for spark: Sprite2D in _sparks:
		spark.visible = false
	_flash.color = Color(1, 1, 1, 0)


## Coroutine (~0,4 s) : le Pokémon sauvage se libère (jalon 5D) : la Ball s'ouvre dans un éclat
## blanc et le Pokémon ressort à sa place. Sans effet hors combat ou sans Ball posée.
func play_break_free() -> void:
	if not _active or _ball == null or not _ball.visible:
		return
	var foe := BattleEvent.SideId.FOE
	_absorb_point = _ball_rest
	_fainted.erase(foe)
	_set_texture(foe)
	_sprites[foe].visible = true
	_shadows[foe].visible = true
	_set_absorbed(1.0)
	_ball.visible = false
	_ball_shadow.visible = false
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_release, 0.0, 1.0, RELEASE_DURATION)
	tween.tween_method(_set_burst.bind(_ball_rest, BURST_WHITE), 0.0, 1.0, BURST_DURATION * 0.7)
	await _play(tween)
	_glow.visible = false
	for spark: Sprite2D in _sparks:
		spark.visible = false
	_rest(foe)
	_sprites[foe].modulate = Color.WHITE
	_shadows[foe].modulate = Color.WHITE


## Les accessoires de la capture (Ball, ombre, dresseur) sont affichés.
func is_capture_shown() -> bool:
	return _ball != null and (_ball.visible or _thrower.visible)


## Ball posée dans l'herbe, visible (tests, captures) ; null avant le premier lancer.
func get_ball() -> Sprite2D:
	return _ball


## Dresseur de dos du lancer (tests, captures) ; null avant le premier lancer.
func get_thrower() -> Sprite2D:
	return _thrower


## Coroutine (~0,6 s) : retour à l'exploration. Les sprites repartent vers la place de
## leur PNJ, qui réapparaît sur sa case ; caméra rendue à l'identique ; rien ne reste.
func exit() -> void:
	if not _active:
		return
	for side: BattleEvent.SideId in _sprites:
		_rest(side)
	_fade_capture_props(EXIT_DURATION * 0.5)
	var tween := _new_tween()
	tween.tween_method(_set_exit_progress, 0.0, 1.0, EXIT_DURATION)
	await _play(tween)
	if not _active:
		return
	_apply_reset()
	exited.emit()


## Remise à l'état initial immédiate (tests, abandon) : PNJ réaffichés, caméra rendue.
func reset() -> void:
	_apply_reset()


func is_active() -> bool:
	return _active


## Sprite de combat de [param side] (tests, captures).
func get_sprite(side: BattleEvent.SideId) -> Sprite2D:
	return _sprites[side]


## Rectangle écran de la boîte visible du Pokémon de [param side] à sa place courante (tests,
## captures).
func get_sprite_rect(side: BattleEvent.SideId) -> Rect2:
	return BattleLayout.sprite_rect(_sprites[side].position, _anchor_scale(side),
		_box(side).size)


## Centre monde du cadrage de combat (tests, captures).
func get_focus() -> Vector2:
	return _focus


# --- Transition ----------------------------------------------------------------------

## Entrée à [param t] (0 → 1, linéaire dans le temps).
func _set_enter_progress(t: float) -> void:
	var cam := _ease(clampf(t / CAMERA_END, 0.0, 1.0))
	_set_camera(cam)
	_set_backdrop(_ease(clampf(t / CAMERA_END, 0.0, 1.0)))
	var swap := clampf(t / SWAP_END, 0.0, 1.0)
	var travel := _ease(clampf((t - TRAVEL_START) / (TRAVEL_END - TRAVEL_START), 0.0, 1.0))
	for side: BattleEvent.SideId in _sprites:
		_set_travel(side, travel, swap)


## Sortie à [param t] (0 → 1) : l'entrée à l'envers, sprites et caméra ensemble.
func _set_exit_progress(t: float) -> void:
	var back := _ease(1.0 - t)
	_set_camera(back)
	_set_backdrop(back)
	var swap := clampf((1.0 - t) / EXIT_SWAP, 0.0, 1.0)
	for side: BattleEvent.SideId in _sprites:
		_set_travel(side, back, swap)


## Caméra à [param k] (0 : cadrage d'exploration, 1 : cadrage de combat).
func _set_camera(k: float) -> void:
	if _camera == null:
		return
	_camera.zoom = _cam_zoom.lerp(Vector2.ONE * ZOOM, k)
	_camera.global_position = _cam_start_center.lerp(_focus, k).round()


func _set_backdrop(k: float) -> void:
	(_backdrop.material as ShaderMaterial).set_shader_parameter(&"amount", k)
	_backdrop.visible = k > 0.0


## Recadrage + voile de l'entrée sauvage à [param k] (0 : exploration, 1 : combat), sans faire
## voyager de sprite (les combattants n'ont pas de PNJ dans le monde).
func _set_recompose(k: float) -> void:
	_set_camera(k)
	_set_backdrop(k)


## Coroutine : le Pokémon de [param side] apparaît à son ancre (bond depuis [param drop] px
## au-dessus + fondu, ombre comprise). Sert au sauvage de l'entrée (§3.7).
func _appear(side: BattleEvent.SideId, drop: float, duration: float) -> void:
	var sprite := _sprites[side]
	_fainted.erase(side)
	_set_texture(side)
	var feet := _anchor(side)
	var scale := _anchor_scale(side)
	sprite.visible = true
	_shadows[side].visible = true
	_place(side, feet + Vector2(0.0, -drop), scale)
	sprite.modulate = Color(1, 1, 1, 0)
	_shadows[side].modulate = Color(1, 1, 1, 0)
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, ^"position", feet, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, ^"modulate", Color.WHITE, duration)
	tween.tween_property(_shadows[side], ^"modulate", Color.WHITE, duration)
	await _play(tween)


## Sprite de [param side] sur son trajet : [param k] (0 : place du PNJ projetée par la
## caméra courante, taille du monde ; 1 : ancre, taille de combat) ; [param swap] : fondu
## croisé du PNJ vers le sprite (0 : PNJ seul, 1 : sprite seul).
func _set_travel(side: BattleEvent.SideId, k: float, swap: float) -> void:
	var sprite := _sprites[side]
	var npc: Node2D = _world.get(side)
	var shown := 0.0 if _fainted.get(side, false) else 1.0
	if npc == null:
		# Sans PNJ : il apparaît à son ancre, en fondu, au rythme du décor.
		sprite.visible = k * shown > 0.0
		_shadows[side].visible = sprite.visible
		sprite.modulate = Color(1, 1, 1, k * shown)
		_shadows[side].modulate = Color(1, 1, 1, k * shown)
		_place(side, _anchor(side), _anchor_scale(side))
		return
	var start := _project(_world_feet[side])
	var start_scale := _world_height[side] * _camera.zoom.y / maxf(_box(side).size.y, 1.0)
	var hops := PLAYER_HOPS if side == BattleEvent.SideId.PLAYER else FOE_HOPS
	# Profondeur d'abord, côté ensuite : le tien vient vers l'avant-plan puis se décale, le
	# sien recule puis se décale ; leurs trajets se croisent à des hauteurs différentes (le
	# tien devant), jamais l'un sur l'autre au même plan.
	var target := _anchor(side)
	var ky := _ease(clampf(k / DEPTH_LEAD, 0.0, 1.0))
	var kx := _ease(clampf((k - SIDE_DELAY) / (1.0 - SIDE_DELAY), 0.0, 1.0))
	var feet := Vector2(lerpf(start.x, target.x, kx), lerpf(start.y, target.y, ky))
	feet.y -= absf(sin(k * PI * hops)) * HOP_HEIGHT * (1.0 - k * 0.5) * float(k < 1.0)
	# Taille : même courbe que la profondeur (il grandit en venant vers la caméra).
	_place(side, feet, lerpf(start_scale, _anchor_scale(side), ky))
	sprite.visible = swap * shown > 0.0
	_shadows[side].visible = sprite.visible
	var glow := SWAP_GLOW.lerp(Color.WHITE, swap)
	sprite.modulate = Color(glow.r, glow.g, glow.b, swap * shown)
	_shadows[side].modulate = Color(1, 1, 1, swap * shown)
	npc.visible = swap < 1.0
	var base := _world_modulate[side]
	npc.modulate = Color(base.r, base.g, base.b, base.a * (1.0 - swap))


## Position écran d'un point monde avec la caméra courante (centre et zoom posés par
## [method _set_camera]).
func _project(world: Vector2) -> Vector2:
	return (world - _camera.global_position) * _camera.zoom + _view_size() / 2.0


func _ease(k: float) -> float:
	return (1.0 - cos(PI * k)) / 2.0


# --- Outils --------------------------------------------------------------------------

func _save_camera() -> void:
	_cam_zoom = _camera.zoom
	_cam_position = _camera.position
	_cam_offset = _camera.offset
	_cam_limits = [_camera.limit_left, _camera.limit_top, _camera.limit_right,
		_camera.limit_bottom]
	_cam_start_center = _camera.get_screen_center_position()


func _free_camera() -> void:
	_camera.limit_left = -LIMIT_FREE
	_camera.limit_top = -LIMIT_FREE
	_camera.limit_right = LIMIT_FREE
	_camera.limit_bottom = LIMIT_FREE
	_camera.global_position = _cam_start_center


func _restore_camera() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	_camera.zoom = _cam_zoom
	_camera.position = _cam_position
	_camera.offset = _cam_offset
	if _cam_limits.size() == 4:
		_camera.limit_left = _cam_limits[0]
		_camera.limit_top = _cam_limits[1]
		_camera.limit_right = _cam_limits[2]
		_camera.limit_bottom = _cam_limits[3]
	_camera.reset_smoothing()


func _apply_reset() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	if _active:
		_restore_camera()
	for side: BattleEvent.SideId in _world:
		var npc := _world[side]
		if npc != null and is_instance_valid(npc):
			npc.visible = true
			npc.modulate = _world_modulate.get(side, Color.WHITE)
	_world.clear()
	_world_feet.clear()
	_world_height.clear()
	_world_modulate.clear()
	_species.clear()
	_fainted.clear()
	_boxes.clear()
	_scales.clear()
	_arena = Rect2()
	_bounds = Rect2()
	_camera = null
	_active = false
	if not is_node_ready():
		return
	_set_backdrop(0.0)
	_flash.color = Color(1, 1, 1, 0)
	_hide_capture_props()
	for side: BattleEvent.SideId in _sprites:
		_sprites[side].visible = false
		_sprites[side].texture = null
		_sprites[side].modulate = Color.WHITE
		_shadows[side].visible = false
		_shadows[side].modulate = Color.WHITE


func _prepare_sprite(side: BattleEvent.SideId) -> void:
	_set_texture(side)
	_sprites[side].visible = false
	_shadows[side].visible = false


## Image de [param side] (BattleArt) : artwork officiel de l'adversaire (linéaire, étalonné)
## ou sprite provisoire (NEAREST, échelle entière) ; pieds (bas-centre de la boîte visible) à
## l'origine du sprite ; échelle normalisée par la taille réelle (BattleLayout).
func _set_texture(side: BattleEvent.SideId) -> void:
	var species: StringName = _species.get(side, &"")
	var back := side == BattleEvent.SideId.PLAYER
	var image := _art.image(species, back)
	var texture: Texture2D = image["texture"]
	var official: bool = image["official"]
	var box: Rect2 = image["box"]
	if texture == null:
		push_warning("BattleStage : sprite de combat absent « %s »" % sprite_path(species, back))
	var sprite := _sprites[side]
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = -Vector2(box.get_center().x, box.end.y).round()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if official \
		else CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material = _artwork_material if official else null
	var scale := BattleLayout.sprite_scale(box.size, _art.height_m(species), back,
		_view_size().y, not official)
	_boxes[side] = box
	_scales[side] = scale
	if official:
		_artwork_material.set_shader_parameter(&"texels_per_pixel", 1.0 / scale)


## Boîte visible de l'image de [param side] (px de la texture).
func _box(side: BattleEvent.SideId) -> Rect2:
	return _boxes.get(side, Rect2(Vector2.ZERO, BattleLayout.NATIVE))


## Sprite et ombre de [param side] : pieds sur [param feet] (écran), échelle [param scale].
func _place(side: BattleEvent.SideId, feet: Vector2, scale: float) -> void:
	var sprite := _sprites[side]
	sprite.position = feet
	sprite.scale = Vector2.ONE * scale
	var shadow := _shadows[side]
	shadow.position = feet
	var width := _box(side).size.x * scale * SHADOW_WIDTH
	shadow.scale = Vector2(width, width * SHADOW_FLATTEN) / _shadow_texture.get_size()


## Remet le sprite de [param side] au repos à son ancre (après une animation).
func _rest(side: BattleEvent.SideId) -> void:
	if not _sprites[side].visible:
		return
	_place(side, _anchor(side), _anchor_scale(side))
	var alpha := _sprites[side].modulate.a
	_sprites[side].modulate = Color(1, 1, 1, alpha)


func _anchor(side: BattleEvent.SideId) -> Vector2:
	var key := "player_feet" if side == BattleEvent.SideId.PLAYER else "foe_feet"
	return _anchors.get(key, Vector2.ZERO)


func _anchor_scale(side: BattleEvent.SideId) -> float:
	return _scales.get(side, 1.0)


func _other(side: BattleEvent.SideId) -> BattleEvent.SideId:
	return BattleEvent.SideId.FOE if side == BattleEvent.SideId.PLAYER \
		else BattleEvent.SideId.PLAYER


func _view_size() -> Vector2:
	return get_viewport().get_visible_rect().size


## Hauteur affichée (px monde) de l'image courante du PNJ Pokémon.
func _world_sprite_height(npc: Node2D) -> float:
	var sprite := npc.get_node_or_null(^"%Sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return WORLD_HEIGHT_FALLBACK
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if frame == null:
		return WORLD_HEIGHT_FALLBACK
	return frame.get_size().y * absf(sprite.global_scale.y)


func _new_tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	return tween


## Joue [param tween] à [member speed_scale] (0 : jusqu'à la fin, tout de suite) et attend.
func _play(tween: Tween) -> void:
	if speed_scale <= 0.0:
		tween.custom_step(INSTANT_STEP)
	else:
		tween.set_speed_scale(speed_scale)
	if tween.is_valid() and tween.is_running():
		await tween.finished
	_tweens.erase(tween)


# --- Capture (jalon 5D) --------------------------------------------------------------

## Centre écran du sprite de combat adverse à son ancre.
func _foe_center() -> Vector2:
	var foe := BattleEvent.SideId.FOE
	return _anchor(foe) + Vector2(0.0, -_box(foe).size.y * 0.5 * _anchor_scale(foe))


## Crée les accessoires de la capture au premier lancer (Ball, ombre, dresseur, lueur,
## étincelles, traits de secousse), sous le voile [member _flash].
func _build_capture_props() -> void:
	if _ball != null:
		return
	_ball_shadow = _make_prop(SHADOW_TEXTURE)
	_ball = _make_prop(BALL_TEXTURE)
	_thrower = _make_prop(THROWER_TEXTURE)
	_thrower.offset = Vector2(0.0, -32.0)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var halo := GradientTexture2D.new()
	halo.gradient = gradient
	halo.fill = GradientTexture2D.FILL_RADIAL
	halo.fill_from = Vector2(0.5, 0.5)
	halo.fill_to = Vector2(1.0, 0.5)
	halo.width = 128
	halo.height = 128
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow = _make_prop(halo)
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_glow.material = additive
	for i: int in SPARK_COUNT:
		var spark := _make_prop(halo)
		spark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		spark.material = additive
		_sparks.append(spark)
	# Traits de mouvement : deux arcs de chaque côté de la Ball (pair : gauche, impair : droite).
	for i: int in 4:
		var side := -1.0 if i % 2 == 0 else 1.0
		var line := Line2D.new()
		line.width = 7.0
		line.default_color = Color(1, 1, 1, 1)
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.visible = false
		for step: int in 7:
			var u := float(step) / 3.0 - 1.0
			line.add_point(Vector2(side * (float(i / 2) * 28.0 + 22.0 * (1.0 - u * u)), u * 70.0))
		add_child(line)
		_shake_lines.append(line)
	move_child(_flash, -1)


## Ombres au sol des deux Pokémon : ellipse douce partagée, teintée par le lieu.
func _build_shadows() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.55, Color(1, 1, 1, 0.75))
	_shadow_texture = GradientTexture2D.new()
	_shadow_texture.gradient = gradient
	_shadow_texture.fill = GradientTexture2D.FILL_RADIAL
	_shadow_texture.fill_from = Vector2(0.5, 0.5)
	_shadow_texture.fill_to = Vector2(1.0, 0.5)
	_shadow_texture.width = 128
	_shadow_texture.height = 128
	var material := ShaderMaterial.new()
	material.shader = SHADOW_SHADER
	for side: BattleEvent.SideId in _shadows:
		_shadows[side].texture = _shadow_texture
		_shadows[side].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_shadows[side].material = material


func _make_prop(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.visible = false
	add_child(sprite)
	return sprite


## Cache et remet à zéro les accessoires de la capture (fin du combat, abandon).
func _hide_capture_props() -> void:
	if _ball == null:
		return
	for sprite: Sprite2D in [_ball, _ball_shadow, _thrower, _glow] + _sparks:
		sprite.visible = false
		sprite.modulate = Color.WHITE
	_ball.rotation = 0.0
	for line: Line2D in _shake_lines:
		line.visible = false


## Fait disparaître en fondu la Ball et son ombre pendant [param duration] (sortie du combat).
func _fade_capture_props(duration: float) -> void:
	if _ball == null or not _ball.visible:
		return
	var tween := _new_tween()
	tween.set_parallel(true)
	tween.tween_property(_ball, ^"modulate:a", 0.0, duration)
	tween.tween_property(_ball_shadow, ^"modulate:a", 0.0, duration)
	_play(tween)


## Vol de la Ball à [param t] (0 : main, 1 : cible) : arc de hauteur [param arc] px, tours sur
## elle-même, elle rapetisse en s'éloignant.
func _set_ball_flight(t: float, from: Vector2, to: Vector2, arc: float) -> void:
	_ball.position = from.lerp(to, t) + Vector2(0.0, -arc * 4.0 * t * (1.0 - t))
	_ball.rotation = t * TAU * THROW_SPINS
	_ball.scale = Vector2.ONE * lerpf(BALL_FLIGHT_SCALE * 1.4, BALL_FLIGHT_SCALE, t)


## Impact à [param t] (0 → 1) : le Pokémon sauvage est absorbé dans l'éclat rouge, la Ball tourne.
func _set_absorb_flash(t: float) -> void:
	_set_absorbed(_ease(t))
	_ball.rotation = t * TAU
	_glow.scale = Vector2.ONE * lerpf(1.0, 4.0, t)
	_glow.modulate = Color(BURST_RED, _flash_alpha(sin(PI * t)))


## Le Pokémon sauvage à [param k] de l'absorption (0 : à son ancre, taille normale ; 1 :
## rapetissé au point [member _absorb_point], teinté puis effacé). Sert à l'absorption et, à
## l'envers, à la libération.
func _set_absorbed(k: float) -> void:
	var foe := BattleEvent.SideId.FOE
	var full := _anchor_scale(foe)
	var scale := lerpf(full, ABSORB_SHRINK, k)
	var center := _foe_center().lerp(_absorb_point, k)
	_place(foe, center + Vector2(0.0, _box(foe).size.y * 0.5 * scale), scale)
	var tint := Color.WHITE.lerp(ABSORB_TINT, minf(k * 2.0, 1.0))
	_sprites[foe].modulate = Color(tint.r, tint.g, tint.b, 1.0 - maxf(k - 0.7, 0.0) / 0.3)
	_shadows[foe].modulate = Color(1, 1, 1, 1.0 - k)


## Libération à [param t] (0 → 1) : le Pokémon ressort de la Ball.
func _set_release(t: float) -> void:
	_set_absorbed(1.0 - _ease(t))


## Éclat de [param color] à [param t] (0 → 1) centré sur [param origin] : lueur qui grandit en
## s'éteignant, étincelles qui partent en étoile.
func _set_burst(t: float, origin: Vector2, color: Color) -> void:
	var out := 1.0 - pow(1.0 - t, 3.0)
	_glow.visible = true
	_glow.position = origin
	_glow.scale = Vector2.ONE * lerpf(0.5, BURST_SCALE, out)
	_glow.modulate = Color(color, _flash_alpha((1.0 - t) * 0.9))
	for i: int in _sparks.size():
		var angle := TAU * float(i) / float(_sparks.size()) + 0.3
		var spark := _sparks[i]
		spark.visible = true
		spark.position = origin + Vector2.from_angle(angle) * SPARK_DISTANCE * out
		spark.scale = Vector2.ONE * lerpf(0.18, 0.05, t)
		spark.modulate = Color(color, 1.0 - t)
