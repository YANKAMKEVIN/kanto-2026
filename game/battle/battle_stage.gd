class_name BattleStage
extends CanvasLayer
## Vue de combat dans le décor réel (jalon-04.md §14.4, décisions de Kevin n° 10 et 17) :
## le labo reste chargé et vivant derrière ; la caméra du joueur le **recompose** (zoom et
## cadrage sur l'arène), un voile, un vignettage et un flou léger le mettent en retrait, et
## les deux Pokémon deviennent de grands sprites de combat composés en espace écran
## (BattleLayout : le tien de dos en bas à gauche, l'adversaire de face au centre droit).
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

## Zoom de la caméra en combat (plan : ~1,35 ; 1,4 remplit mieux la largeur du S24 avec le
## labo, à régler sur le S24).
const ZOOM: float = 1.4
## Voile (opacité de UiTokens.FADE_COLOR), vignettage et flou du décor : modérés, le labo
## doit rester reconnaissable (décision n° 17).
const VEIL: float = UiTokens.BATTLE_DIM
const VIGNETTE: float = 0.45
## Flou d'arrière-plan : niveau de mipmap (0 = coupé, si le S24 perd des images).
const BLUR_ENABLED: bool = true
const BLUR_LOD: float = 1.0
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
## Ombre au sol : décalage vertical par unité d'échelle, opacité.
const SHADOW_LIFT: float = 1.5
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
## Pas « instantané » (speed_scale = 0) : avance d'un tween jusqu'à sa fin.
const INSTANT_STEP: float = 1000.0
## Hauteur affichée d'un Pokémon du monde sans AnimatedSprite2D lisible (32 px ×2).
const WORLD_HEIGHT_FALLBACK: float = 64.0
const SPRITE_DIR: String = "res://assets/sprites/pokemon/placeholder/"
const LIMIT_FREE: int = 10000000

## Multiplicateur des durées (0 = instantané, tests).
var speed_scale: float = 1.0

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
var _tweens: Array[Tween] = []

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
	material.set_shader_parameter(&"blur_lod", BLUR_LOD if BLUR_ENABLED else 0.0)
	_apply_reset()


## Chemin du sprite de combat de [param species] (de dos si [param back]) : seule
## convention de chemin des sprites de combat.
static func sprite_path(species: StringName, back: bool) -> String:
	return SPRITE_DIR + "%s_%s.png" % [species, "back" if back else "front"]


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
		_focus = BattleLayout.focus(cells)
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
	_place(side, feet + Vector2(0.0, -APPEAR_DROP), float(_anchor_scale(side)))
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
		_focus = BattleLayout.focus(cells)
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
	var scale := float(_anchor_scale(side))
	var start := Vector2(-float(BattleLayout.NATIVE.x) * scale, feet.y)
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
	tween.tween_property(_shadows[side], ^"position",
		feet + Vector2(0.0, -SHADOW_LIFT * scale), PARTNER_ENTER_DURATION) \
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
		_flash.color = Color(1, 1, 1, CRIT_FLASH)
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


## Coroutine (~0,6 s) : retour à l'exploration. Les sprites repartent vers la place de
## leur PNJ, qui réapparaît sur sa case ; caméra rendue à l'identique ; rien ne reste.
func exit() -> void:
	if not _active:
		return
	for side: BattleEvent.SideId in _sprites:
		_rest(side)
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
	var scale := float(_anchor_scale(side))
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
		_place(side, _anchor(side), float(_anchor_scale(side)))
		return
	var start := _project(_world_feet[side])
	var start_scale := _world_height[side] * _camera.zoom.y / float(BattleLayout.NATIVE.y)
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
	_place(side, feet, lerpf(start_scale, float(_anchor_scale(side)), ky))
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
	_arena = Rect2()
	_bounds = Rect2()
	_camera = null
	_active = false
	if not is_node_ready():
		return
	_set_backdrop(0.0)
	_flash.color = Color(1, 1, 1, 0)
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


func _set_texture(side: BattleEvent.SideId) -> void:
	var species: StringName = _species.get(side, &"")
	var path := sprite_path(species, side == BattleEvent.SideId.PLAYER)
	var texture: Texture2D = null
	if not species.is_empty() and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	else:
		push_warning("BattleStage : sprite de combat absent « %s »" % path)
	_sprites[side].texture = texture


## Sprite et ombre de [param side] : pieds sur [param feet] (écran), échelle [param scale].
func _place(side: BattleEvent.SideId, feet: Vector2, scale: float) -> void:
	var sprite := _sprites[side]
	sprite.position = feet
	sprite.scale = Vector2.ONE * scale
	var shadow := _shadows[side]
	shadow.position = feet + Vector2(0.0, -SHADOW_LIFT * scale)
	shadow.scale = Vector2.ONE * scale


## Remet le sprite de [param side] au repos à son ancre (après une animation).
func _rest(side: BattleEvent.SideId) -> void:
	if not _sprites[side].visible:
		return
	_place(side, _anchor(side), float(_anchor_scale(side)))
	var alpha := _sprites[side].modulate.a
	_sprites[side].modulate = Color(1, 1, 1, alpha)


func _anchor(side: BattleEvent.SideId) -> Vector2:
	var key := "player_feet" if side == BattleEvent.SideId.PLAYER else "foe_feet"
	return _anchors.get(key, Vector2.ZERO)


func _anchor_scale(side: BattleEvent.SideId) -> int:
	var key := "player_scale" if side == BattleEvent.SideId.PLAYER else "foe_scale"
	return _anchors.get(key, 1)


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
