class_name Npc
extends Node2D
## PNJ ou Pokémon du décor posé sur une carte (docs/tech/jalon-03.md §2.3) : présentation
## seulement, la description vient d'un [NpcSpec] (`data/npcs/<map_id>.json`).
##
## Créé par [GameMap] au chargement : [method setup] avant l'ajout à l'arbre, puis la carte
## l'inscrit sur la [GridWorld] par [method enter_grid] (il y possède un [GridMover], comme
## le joueur). [InteractionFinder] le trouve par l'occupant de la grille et
## [method get_interaction]. Origine aux pieds ; apparence [CharacterLook] (peinte 1:1 LINEAR,
## sinon provisoire pixel art ×2 NEAREST).
## Jalon 3B : il peut marcher case par case ([method step], scènes scriptées). Sa case
## courante vit dans son [GridMover] ; [member NpcSpec.cell] reste sa case de départ.
## Au repos, [method _process] est coupé ; seule l'[AnimatedSprite2D] tourne (idle_<dir>).
## Il ne tourne que pendant un pas (walk_<dir> ou run_<dir> si l'apparence les a).
## Jalon 4 (docs/tech/jalon-04.md §3.5, §13.4) : surcharge d'interaction (« Rencontrer »),
## léger élan vers une case ([method lean_toward] / [method settle]) et saut en arc depuis
## un meuble ([method hop_to]), dans le style de [member NpcSpec.hop_style]. Tout est en
## [Tween] sur le sprite et l'ombre, sans nouvelle image.

## Réaction jouée ([method react]) : tests, futurs sons.
signal reacted
## Pas terminé sur [param cell] ([method step]).
signal step_finished(cell: Vector2i)
## Saut terminé ([method hop_to]) : posé sur [param cell], rebonds compris.
signal hopped(cell: Vector2i)
## Élan terminé ([method lean_toward]) ou retour terminé ([method settle]).
signal lean_finished
## Pokémon d'ambiance qui quitte la scène ([method fly_away] / [method flee], jalon 5 §3.5) :
## le watcher fait alors [method GameMap.remove_npc].
signal left_scene(npc_id: StringName)

## SpriteFrames provisoires des apparences (les peintes : [CharacterLook]).
const FRAMES_DIR: String = CharacterLook.PLACEHOLDER_DIR
## Apparence générique (provisoire) quand l'apparence n'existe pas encore.
const FALLBACK_SPRITE: StringName = CharacterLook.FALLBACK_SPRITE
## Animation de réaction facultative (non bouclée) : `react_<dir>` dans l'orientation
## courante si l'apparence l'a, sinon `react` ; sans aucune des deux, petit bond.
const REACT_ANIM: StringName = &"react"
## Petit bond de [method react] : hauteur (pixels monde) et durée totale (s).
const HOP_HEIGHT: float = 12.0
const HOP_DURATION: float = 0.25
## Saut depuis un meuble ([method hop_to], décision de Kevin n° 1, jalon-04.md §13.4) : une
## entrée par valeur de [constant NpcSpec.HOP_STYLES], plus le défaut &"". Valeurs de
## départ, à régler sur le S24. Clés :
## - « hesitate » : hésitation avant le saut (s) ; il se penche de « hesitate_px » vers la
##   case d'arrivée puis revient (calme : il regarde avant de descendre) ;
## - « windup » : petit appel avant le saut (s), le sprite s'accroupit de « windup_px » ;
## - « duration » : durée du vol pour une case (s) ; « height » : hauteur de l'arc (px monde,
##   au-dessus de la ligne qui va de l'élévation de départ au sol) ; « trans » : courbe du
##   vol ([enum Tween.TransitionType], en entrée-sortie ; SINE = amorti) ;
## - « bounces » : rebonds à l'arrivée, [hauteur px, durée s] chacun ;
## - « sway » : petit décalage horizontal alterné pendant les rebonds (px monde, 0 = aucun) ;
## - « squash » : légère compression verticale à l'atterrissage (fraction de la hauteur,
##   0 = aucune), tenue [constant HOP_SQUASH_DURATION] s, pieds au sol.
## Jamais de rotation : un sprite pixel art en NEAREST tourné a des contours en escalier
## (QA du 4A, R2). Seuls des décalages et une compression verticale brève animent le saut.
const HOP_STYLE_PARAMS: Dictionary[StringName, Dictionary] = {
	&"": {
		"hesitate": 0.0, "hesitate_px": 0.0, "windup": 0.0, "windup_px": 0.0,
		"duration": 0.35, "height": 32.0, "trans": Tween.TRANS_LINEAR,
		"bounces": [], "sway": 0.0, "squash": 0.0,
	},
	# Bulbizarre, « calmement » : il regarde et se penche, descend lentement, sans rebond ;
	# atterrissage à peine marqué.
	&"calm": {
		"hesitate": 0.35, "hesitate_px": 8.0, "windup": 0.0, "windup_px": 0.0,
		"duration": 0.55, "height": 24.0, "trans": Tween.TRANS_SINE,
		"bounces": [], "sway": 0.0, "squash": 0.04,
	},
	# Salamèche, « avec enthousiasme » : petit appel, grand arc, atterrissage appuyé, un rebond.
	&"eager": {
		"hesitate": 0.0, "hesitate_px": 0.0, "windup": 0.08, "windup_px": 6.0,
		"duration": 0.38, "height": 48.0, "trans": Tween.TRANS_LINEAR,
		"bounces": [[10.0, 0.16]], "sway": 0.0, "squash": 0.1,
	},
	# Carapuce, « rapidement, vif et joueur » : saut court et vif, deux petits rebonds en
	# se dandinant (décalé d'un côté puis de l'autre, sans rotation).
	&"playful": {
		"hesitate": 0.0, "hesitate_px": 0.0, "windup": 0.0, "windup_px": 0.0,
		"duration": 0.26, "height": 28.0, "trans": Tween.TRANS_LINEAR,
		"bounces": [[8.0, 0.12], [5.0, 0.12]], "sway": 6.0, "squash": 0.06,
	},
}
## Allongement du vol par case supplémentaire (distance de Manhattan au-delà de 1).
const HOP_EXTRA_CELL_FACTOR: float = 0.25
## Durée de la compression à l'atterrissage (s), quand le style en a une (« squash »).
const HOP_SQUASH_DURATION: float = 0.08
## Pendant le vol, le Pokémon est dessiné au-dessus des personnages du y-sort (il est en
## l'air : un saut qui passe au-dessus d'un personnage ne disparaît pas derrière sa tête).
const HOP_FLIGHT_Z: int = 1
## Réduction de l'ombre au sommet de l'arc (0 = aucune).
const HOP_SHADOW_SHRINK: float = 0.3
## Léger élan vers une case ([method lean_toward]) : distance (px monde) et durée (s) de
## l'aller comme du retour ([method settle]).
const LEAN_DISTANCE: float = 20.0
const LEAN_DURATION: float = 0.18
## Sortie de scène d'un Pokémon d'ambiance (jalon 5 §3.5). Envol (Roucool) : montée en arc
## et fondu ; fuite (Rattata) : petits pas puis fondu.
const FLY_RISE: float = 96.0
const FLY_DRIFT: float = 48.0
const FLY_DURATION: float = 0.6
const FLEE_FADE_DURATION: float = 0.25
## Délai (s) avant que le PNJ à routine reprenne sa marche après un dialogue (dossier 07 §5 :
## « après le dialogue, il attend un court instant puis reprend »).
const ROUTE_RESUME_DELAY: float = 0.6
const _IDLE_ANIMS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"idle_down",
	Vector2i.UP: &"idle_up",
	Vector2i.LEFT: &"idle_left",
	Vector2i.RIGHT: &"idle_right",
}
const _WALK_ANIMS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"walk_down",
	Vector2i.UP: &"walk_up",
	Vector2i.LEFT: &"walk_left",
	Vector2i.RIGHT: &"walk_right",
}
const _RUN_ANIMS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"run_down",
	Vector2i.UP: &"run_up",
	Vector2i.LEFT: &"run_left",
	Vector2i.RIGHT: &"run_right",
}
const _REACT_ANIMS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"react_down",
	Vector2i.UP: &"react_up",
	Vector2i.LEFT: &"react_left",
	Vector2i.RIGHT: &"react_right",
}

var _spec: NpcSpec = NpcSpec.new()
var _interaction: Interaction
## Interaction posée par le code (« Rencontrer » un starter), prioritaire ; null sinon.
var _override: Interaction
var _facing: Vector2i = Vector2i.DOWN
var _hop: Tween
## Déplacement sur la grille de la carte ([method enter_grid]) ; null hors grille.
var _mover: GridMover
var _grid: GridWorld
## Case hors grille (avant [method enter_grid], après [method leave_grid]).
var _cell: Vector2i = Vector2i.ZERO
## Élévation courante (px monde) : celle de la description, 0 après un saut.
var _lift: float = 0.0
## Décalage de l'élan ([method lean_toward]) appliqué au sprite et à l'ombre.
var _lean: Vector2 = Vector2.ZERO
var _lean_tween: Tween
## Saut en cours ([method hop_to]) : tween, cases, positions monde, élévation de départ.
var _hop_tween: Tween
var _hopping: bool = false
var _hop_from_cell: Vector2i = Vector2i.ZERO
var _hop_cell: Vector2i = Vector2i.ZERO
var _hop_from: Vector2 = Vector2.ZERO
var _hop_to: Vector2 = Vector2.ZERO
var _hop_start_lift: float = 0.0
var _hop_height: float = 0.0
## Échelle du sprite au repos (celle de la scène : ×2), rétablie après une compression.
var _base_scale: Vector2 = Vector2(2.0, 2.0)
## Routine de marche (jalon 5, le Voyageur) : cases voisines parcourues en boucle.
var _route: Array[Vector2i] = []
var _route_pause: float = NpcSpec.ROUTE_PAUSE_DEFAULT
var _route_index: int = 0
var _route_wait: float = 0.0
var _route_active: bool = false
## Suspendue pendant un dialogue (il s'arrête et se tourne vers le joueur, dossier 07 §5).
var _route_suspended: bool = false
## Sortie de scène en cours ([method fly_away] / [method flee]) : plus d'interaction.
var _leaving: bool = false
var _leave_tween: Tween

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _shadow: Sprite2D = %Shadow


func _ready() -> void:
	set_process(is_moving())
	_sprite.animation_finished.connect(_on_animation_finished)
	_apply_spec()


## Ne tourne que pendant un pas ou pour piloter la routine de marche (jalon 5) : le
## [GridMover] avance, le nœud suit (position arrondie).
func _process(delta: float) -> void:
	if _mover == null:
		set_process(false)
		return
	if _mover.is_moving():
		_mover.update(delta, Vector2i.ZERO, false)
		# step_finished est émis pendant update() : la fin d'une fuite fait alors quitter la
		# grille au PNJ (leave_grid remet _mover à null, position et _process déjà réglés).
		if _mover == null:
			return
		position = _mover.get_world_position().round()
		if not _mover.is_moving():
			_play_idle()
			if _route_active:
				_route_wait = _route_pause
		return
	if _route_active and not _route_suspended and not _hopping and not _leaving:
		_route_wait -= delta
		if _route_wait <= 0.0:
			_advance_route()
		return
	set_process(false)
	_play_idle()


## Décrit le PNJ (à appeler avant l'ajout à l'arbre ; rappelable ensuite). Position = pieds
## sur la case, orientation au repos, apparence [code]<sprite>_frames.tres[/code].
func setup(spec: NpcSpec) -> void:
	_spec = spec if spec != null else NpcSpec.new()
	name = String(_spec.id) if not _spec.id.is_empty() else "Npc"
	_abort_hop()
	_cell = _spec.cell
	position = Grid.cell_to_world(_spec.cell)
	_facing = _spec.facing if Grid.is_cardinal(_spec.facing) else Vector2i.DOWN
	_interaction = _spec.make_interaction(_spec.cell, self)
	_lift = float(_spec.lift)
	_lean = Vector2.ZERO
	_route = _spec.route_cells.duplicate()
	_route_pause = _spec.route_pause
	_route_index = 0
	_route_active = false
	_route_suspended = false
	if is_node_ready():
		_apply_spec()


func get_id() -> StringName:
	return _spec.id


func get_spec() -> NpcSpec:
	return _spec


## Case courante : celle du [GridMover] (case de départ pendant un pas), sinon celle de la
## description (hors grille).
func get_cell() -> Vector2i:
	return _mover.get_cell() if _mover != null else _cell


func get_facing() -> Vector2i:
	return _facing


## Inscrit le PNJ sur [param grid] : nouveau [GridMover], placé sur la case de départ au
## premier appel, sur sa case courante ensuite (grille reconstruite). Un pas en cours est
## annulé. Faux si la case est hors carte ou prise (le PNJ reste alors hors grille).
func enter_grid(grid: GridWorld) -> bool:
	_abort_hop()
	var cell := get_cell()
	if _mover != null:
		_mover.step_finished.disconnect(_on_step_finished)
		_mover = null
		_grid = null
		_cell = cell
	var mover := GridMover.new(grid, self)
	if not mover.place(cell, _facing):
		return false
	_mover = mover
	_grid = grid
	_mover.step_finished.connect(_on_step_finished)
	position = Grid.cell_to_world(cell)
	_play_idle()
	if not _route.is_empty():
		_start_route(cell)
	else:
		set_process(false)
	return true


## Libère sa case (et la case visée par un pas en cours) ; le PNJ reste où il est.
func leave_grid() -> void:
	_abort_hop()
	_route_active = false
	if _mover == null:
		return
	var cell := _mover.get_cell()
	_grid.release(_mover.get_target_cell(), self)
	_grid.release(cell, self)
	_mover.step_finished.disconnect(_on_step_finished)
	_mover = null
	_grid = null
	_cell = cell
	position = Grid.cell_to_world(cell)
	set_process(false)
	_play_idle()


## Un pas vers [param direction] (marche, ou course si [param run]) : il se tourne et part,
## même si la case est prise (alors tourné, faux). Faux aussi hors grille, pendant un pas
## ou pour une direction non cardinale.
func step(direction: Vector2i, run: bool = false) -> bool:
	if _mover == null or _hopping or not Grid.is_cardinal(direction):
		return false
	var started := _mover.start_step(direction, run)
	_facing = _mover.get_facing()
	if not started:
		_play_idle()
		return false
	_play_move()
	set_process(true)
	return true


func is_moving() -> bool:
	return _mover != null and _mover.is_moving()


## Interaction du PNJ (toujours la même instance : aucune allocation) : la surcharge si
## elle existe ([method set_interaction_override]), sinon celle de sa description ; null
## s'il n'est pas interactif (Roucool de Mme Aoki).
func get_interaction() -> Interaction:
	return _override if _override != null else _interaction


## Remplace son interaction par [param interaction] (« Rencontrer » un starter, posé par le
## code du choix) jusqu'à [method clear_interaction_override] ; sa case suit celle du PNJ.
## null revient à retirer la surcharge.
func set_interaction_override(interaction: Interaction) -> void:
	_override = interaction
	if _override != null:
		_override.cell = get_cell()


## Retire la surcharge : il retrouve l'interaction de sa description.
func clear_interaction_override() -> void:
	_override = null


func has_interaction_override() -> bool:
	return _override != null


## Chemin des SpriteFrames d'une apparence ([CharacterLook] : peinte, sinon provisoire, sinon
## générique).
static func frames_path(sprite: StringName) -> String:
	return CharacterLook.resolve(sprite).frames_path


## Vrai si l'apparence a ses propres SpriteFrames, peints ou provisoires (sinon la scène prend
## le générique).
static func has_frames(sprite: StringName) -> bool:
	if sprite.is_empty():
		return false
	var path := CharacterLook.resolve(sprite).frames_path
	return sprite == FALLBACK_SPRITE \
		or path != CharacterLook.placeholder_frames_path(FALLBACK_SPRITE)


## Se tourne vers [param direction] (animation idle_<dir>). Non cardinale ou pendant un
## pas : ignorée.
func face(direction: Vector2i) -> void:
	if not Grid.is_cardinal(direction) or is_moving() or _hopping:
		return
	_facing = direction
	if _mover != null:
		_mover.face(direction)
	_play_idle()


## Se tourne vers [param cell] selon l'axe dominant (à égalité, l'axe vertical). Rien si
## c'est sa propre case.
func face_toward(cell: Vector2i) -> void:
	var delta := cell - get_cell()
	if delta == Vector2i.ZERO:
		return
	if absi(delta.x) > absi(delta.y):
		face(Vector2i(signi(delta.x), 0))
	else:
		face(Vector2i(0, signi(delta.y)))


## Début d'une interaction avec le joueur en [param player_cell] : il s'arrête (routine
## suspendue) et se tourne vers lui si [member NpcSpec.turn_to_player].
func begin_interaction(player_cell: Vector2i) -> void:
	_route_suspended = true
	if _spec.turn_to_player:
		face_toward(player_cell)


## Fin d'une interaction : il reprend son orientation au repos (« retourne à ses
## affaires »), sauf [member NpcSpec.keep_facing], puis reprend sa routine après un court
## instant (dossier 07 §5).
func end_interaction() -> void:
	if not _spec.keep_facing:
		face(_spec.facing)
	if _route_active:
		_route_suspended = false
		_route_wait = ROUTE_RESUME_DELAY
		set_process(true)


## Petite réaction (indication « react » d'une page de dialogue) : animation
## `react_<dir>` (ou `react`) si l'apparence en a une, puis retour à l'attente ; sinon
## petit bond du sprite (la case ne change pas).
func react() -> void:
	reacted.emit()
	if _sprite == null:
		return
	var frames := _sprite.sprite_frames
	if frames != null:
		var directed: StringName = _REACT_ANIMS.get(_facing, REACT_ANIM)
		for anim: StringName in [directed, REACT_ANIM]:
			if frames.has_animation(anim):
				_sprite.play(anim)
				return
	if not is_inside_tree() or _hopping:
		return
	if _hop != null and _hop.is_valid():
		_hop.kill()
	var rest := _rest_y()
	_sprite.position.y = rest
	_hop = create_tween()
	_hop.tween_property(_sprite, ^"position:y", rest - HOP_HEIGHT, HOP_DURATION / 2.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop.tween_property(_sprite, ^"position:y", rest, HOP_DURATION / 2.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## S'avance légèrement vers [param cell] ([constant LEAN_DISTANCE] px selon l'axe dominant,
## en [constant LEAN_DURATION] s) : « il s'approche légèrement ». La case ne change pas ;
## il reste penché jusqu'à [method settle]. Rien si c'est sa propre case.
func lean_toward(cell: Vector2i) -> void:
	var direction := Grid.dominant_direction(get_cell(), cell)
	if direction == Vector2i.ZERO:
		return
	_tween_lean(Vector2(direction) * LEAN_DISTANCE)


## Revient à sa place après [method lean_toward] (sans effet s'il n'est pas penché).
func settle() -> void:
	_tween_lean(Vector2.ZERO)


## Décalage courant de l'élan (px monde), ZERO au repos.
func get_lean_offset() -> Vector2:
	return _lean


## Vrai pendant l'aller ou le retour d'un élan.
func is_leaning() -> bool:
	return _lean_tween != null and _lean_tween.is_valid() and _lean_tween.is_running()


## Vrai pour un grand personnage (humain) : sprite affiché plus haut qu'une case. Un
## Pokémon (64 px affichés) ne l'est pas ; une case juste au-dessus d'un grand personnage
## est derrière sa tête (scènes : [method CutsceneMoves.resolve_landing]).
func is_tall() -> bool:
	if _sprite == null or _sprite.sprite_frames == null:
		return true
	var frame := _sprite.sprite_frames.get_frame_texture(_IDLE_ANIMS[Vector2i.DOWN], 0)
	if frame == null:
		return true
	return frame.get_size().y * _base_scale.y > float(Grid.TILE_SIZE)


## Élévation courante (px monde) : celle de sa description, 0 après un saut.
func get_lift() -> float:
	return _lift


## Saute en arc vers [param cell] (descendre de la table, jalon 4 §13.4), dans le style de
## [member NpcSpec.hop_style] ([constant HOP_STYLE_PARAMS]) : hésitation ou appel, vol de
## l'élévation courante jusqu'au sol, rebonds. Il se tourne vers la case d'arrivée. Sur la
## grille, la case quittée est libérée et la case d'arrivée réservée dès le départ ; sa case
## ([method get_cell]) devient [param cell] à l'atterrissage. [signal hopped] à la toute fin.
## [param grid] : sa grille par défaut (celle de [method enter_grid]) ; une autre grille le
## fait passer dessus. Faux (rien ne bouge) si aucune grille, pendant un pas ou un saut, si
## [param cell] est sa case, hors carte, solide, de l'eau, un rebord ou prise.
func hop_to(cell: Vector2i, grid: GridWorld = null) -> bool:
	var target_grid := grid if grid != null else _grid
	if target_grid == null or is_moving() or _hopping:
		return false
	var from := get_cell()
	if cell == from or not target_grid.is_free(cell, self):
		return false
	if _mover != null and target_grid != _grid:
		leave_grid()
	if _mover == null:
		var mover := GridMover.new(target_grid, self)
		if not mover.place(from, _facing):
			# Sa case de départ est prise sur la nouvelle grille : il ne réserve que l'arrivée.
			mover = null
		if mover != null:
			_mover = mover
			_grid = target_grid
			_mover.step_finished.connect(_on_step_finished)
	_grid = target_grid
	_grid.occupy(cell, self)
	_grid.release(from, self)
	var direction := Grid.dominant_direction(from, cell)
	if direction != Vector2i.ZERO:
		_facing = direction
		if _mover != null:
			_mover.face(direction)
		_play_idle()
	_hopping = true
	_hop_from_cell = from
	_hop_cell = cell
	_hop_from = Grid.cell_to_world(from)
	_hop_to = Grid.cell_to_world(cell)
	_hop_start_lift = _lift
	if _lean_tween != null and _lean_tween.is_valid():
		_lean_tween.kill()
	_lean = Vector2.ZERO
	if _hop != null and _hop.is_valid():
		_hop.kill()
	if not is_inside_tree() or _sprite == null:
		_land_hop()
		return true
	_apply_offsets()
	_start_hop_tween(hop_params(_spec.hop_style), hop_distance(from, cell), direction)
	return true


## Vrai pendant un saut ([method hop_to]), rebonds compris.
func is_hopping() -> bool:
	return _hopping


## Paramètres du style [param style] ([constant HOP_STYLE_PARAMS]) ; ceux du défaut pour un
## style inconnu.
static func hop_params(style: StringName) -> Dictionary:
	return HOP_STYLE_PARAMS.get(style, HOP_STYLE_PARAMS[&""])


## Distance d'un saut en cases (Manhattan, au moins 1).
static func hop_distance(from: Vector2i, to: Vector2i) -> int:
	return maxi(1, absi(to.x - from.x) + absi(to.y - from.y))


## Durée du vol seul (s) pour [param style] sur [param distance] cases.
static func hop_flight_duration(style: StringName, distance: int = 1) -> float:
	var params := hop_params(style)
	return float(params["duration"]) * (1.0 + HOP_EXTRA_CELL_FACTOR * float(maxi(distance, 1) - 1))


## Durée totale du saut (s) : hésitation, appel, vol, compression et rebonds.
static func hop_total_duration(style: StringName, distance: int = 1) -> float:
	var params := hop_params(style)
	var total := float(params["hesitate"]) + float(params["windup"])
	total += hop_flight_duration(style, distance)
	if float(params["squash"]) > 0.0:
		total += HOP_SQUASH_DURATION
	for bounce: Array in params["bounces"]:
		total += float(bounce[1])
	return total


func _start_hop_tween(params: Dictionary, distance: int, direction: Vector2i) -> void:
	_hop_tween = create_tween()
	var rest := Vector2(0.0, -_hop_start_lift)
	var hesitate := float(params["hesitate"])
	if hesitate > 0.0:
		# Il se penche vers la case d'arrivée, regarde, puis se redresse.
		var peek := rest + Vector2(direction) * float(params["hesitate_px"])
		_hop_tween.tween_property(_sprite, ^"position", peek, hesitate * 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_hop_tween.tween_property(_sprite, ^"position", rest, hesitate * 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var windup := float(params["windup"])
	if windup > 0.0:
		# Petit appel : il s'accroupit (le vol repart de sa hauteur de départ).
		_hop_tween.tween_property(_sprite, ^"position:y", rest.y + float(params["windup_px"]),
				windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_height = float(params["height"])
	var trans: Tween.TransitionType = params["trans"]
	_hop_tween.tween_callback(set_z_index.bind(HOP_FLIGHT_Z))
	_hop_tween.tween_method(_set_hop_progress, 0.0, 1.0,
			hop_flight_duration(_spec.hop_style, distance)) \
			.set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	_hop_tween.tween_callback(_on_hop_landed)
	var squash := float(params["squash"])
	if squash > 0.0:
		# Compression brève, par paliers (pas d'interpolation d'échelle image par image) :
		# pieds au sol (origine aux pieds), largeur inchangée.
		var squashed := Vector2(_base_scale.x, _base_scale.y * (1.0 - squash))
		_hop_tween.tween_callback(_sprite.set_scale.bind(squashed))
		_hop_tween.tween_interval(HOP_SQUASH_DURATION)
		_hop_tween.tween_callback(_sprite.set_scale.bind(_base_scale))
	var sway := float(params["sway"])
	var side := 1.0
	for bounce: Array in params["bounces"]:
		var half := float(bounce[1]) * 0.5
		_hop_tween.tween_property(_sprite, ^"position:y", -float(bounce[0]), half) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if sway != 0.0:
			# Dandinement : un pas de côté en l'air, retour au centre à l'atterrissage.
			_hop_tween.parallel().tween_property(_sprite, ^"position:x", sway * side, half)
		_hop_tween.tween_property(_sprite, ^"position:y", 0.0, half) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if sway != 0.0:
			_hop_tween.parallel().tween_property(_sprite, ^"position:x", 0.0, half)
		side = -side
	_hop_tween.tween_callback(_finish_hop)


## Vol : [param t] de 0 à 1 (courbe du style). Position au sol interpolée, élévation de
## départ → 0, arc par-dessus ; l'ombre suit l'élévation et rétrécit au sommet.
func _set_hop_progress(t: float) -> void:
	position = _hop_from.lerp(_hop_to, t).round()
	var ground := lerpf(_hop_start_lift, 0.0, t)
	var arc := 4.0 * _hop_height * t * (1.0 - t)
	_sprite.position = Vector2(0.0, -(ground + arc))
	_shadow.position = Vector2(0.0, _shadow_rest_y() - ground)
	var shrink := 1.0 - HOP_SHADOW_SHRINK * (arc / _hop_height if _hop_height > 0.0 else 0.0)
	_shadow.scale = Vector2(shrink, shrink)


## Atterrissage (avant la compression et les rebonds) : élévation nulle, case changée, de
## nouveau trié avec les autres personnages.
func _on_hop_landed() -> void:
	z_index = 0
	_lift = 0.0
	position = _hop_to
	if _mover != null:
		_mover.place(_hop_cell, _facing)
	else:
		_cell = _hop_cell
	_sync_interaction_cells(_hop_cell)
	_sprite.position = Vector2(0.0, _rest_y())
	_shadow.position = Vector2(0.0, _shadow_rest_y())
	_shadow.scale = Vector2.ONE


func _finish_hop() -> void:
	_hopping = false
	_apply_offsets()
	_play_idle()
	hopped.emit(_hop_cell)


## Saut sans animation (hors arbre) : posé tout de suite.
func _land_hop() -> void:
	_lift = 0.0
	position = _hop_to
	if _mover != null:
		_mover.place(_hop_cell, _facing)
	else:
		_cell = _hop_cell
	_sync_interaction_cells(_hop_cell)
	_hopping = false
	_apply_offsets()
	hopped.emit(_hop_cell)


## Saut interrompu (nouvelle grille, départ de la grille, nouvelle description) : il reste
## sur sa case de départ, la réservation de l'arrivée est rendue ; pas de [signal hopped].
func _abort_hop() -> void:
	if not _hopping:
		return
	_hopping = false
	z_index = 0
	if _hop_tween != null and _hop_tween.is_valid():
		_hop_tween.kill()
	if _grid != null:
		_grid.release(_hop_cell, self)
		_grid.occupy(_hop_from_cell, self)
	position = _hop_from
	_lift = _hop_start_lift
	_apply_offsets()


func _tween_lean(offset: Vector2) -> void:
	if _lean_tween != null and _lean_tween.is_valid():
		_lean_tween.kill()
	if _hopping:
		return
	if not is_inside_tree() or _sprite == null:
		_set_lean(offset)
		lean_finished.emit()
		return
	_lean_tween = create_tween()
	_lean_tween.tween_method(_set_lean, _lean, offset, LEAN_DURATION) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_lean_tween.tween_callback(lean_finished.emit)


func _set_lean(offset: Vector2) -> void:
	_lean = offset
	_apply_offsets()


func _apply_spec() -> void:
	# Apparence peinte (1:1, LINEAR) ou provisoire (×2, NEAREST) : [CharacterLook].
	var look := CharacterLook.resolve(_spec.sprite)
	var frames := load(look.frames_path) as SpriteFrames
	if frames != null:
		_sprite.sprite_frames = frames
	_base_scale = Vector2(look.scale, look.scale)
	_sprite.texture_filter = look.filter
	# Pieds sur l'origine quelle que soit la hauteur de l'image (64 px, 48 px, 130 px).
	var frame := _sprite.sprite_frames.get_frame_texture(_IDLE_ANIMS[Vector2i.DOWN], 0)
	if frame != null:
		_sprite.offset = Vector2(0.0, -frame.get_size().y / 2.0)
	# Élévation (Pokémon sur une table) en pixels monde : sprite et ombre montent ensemble.
	if _hop != null and _hop.is_valid():
		_hop.kill()
	_apply_offsets()
	_play_idle()


## Hauteur du sprite au repos : élévation et élan.
func _rest_y() -> float:
	return -_lift + _lean.y


## Sprite et ombre à leur place de repos (élévation, élan), sans rotation ni compression.
func _apply_offsets() -> void:
	if _sprite == null:
		return
	_sprite.position = Vector2(_lean.x, _rest_y())
	_sprite.rotation = 0.0
	_sprite.scale = _base_scale
	_shadow.position = Vector2(_lean.x, _shadow_rest_y() - _lift + _lean.y)
	_shadow.scale = Vector2.ONE


## Position de l'ombre sans élévation (celle de la scène, comme le joueur).
func _shadow_rest_y() -> float:
	return -6.0


func _play_idle() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var anim: StringName = _IDLE_ANIMS.get(_facing, &"idle_down")
	if _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)


## Pendant un pas : run_<dir> ou walk_<dir> si l'apparence les a, sinon idle_<dir>
## (Pokémon du décor).
func _play_move() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var table := _RUN_ANIMS if _mover.is_running() else _WALK_ANIMS
	var anim: StringName = table.get(_facing, &"")
	if not _sprite.sprite_frames.has_animation(anim):
		anim = _WALK_ANIMS.get(_facing, &"")
	if not _sprite.sprite_frames.has_animation(anim):
		_play_idle()
		return
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)


## Fin d'un pas (dans [method GridMover.update]) : l'interaction suit la case (aucune
## allocation), puis le signal. Un gestionnaire peut lancer le pas suivant.
func _on_step_finished(cell: Vector2i) -> void:
	_sync_interaction_cells(cell)
	step_finished.emit(cell)


func _sync_interaction_cells(cell: Vector2i) -> void:
	if _interaction != null:
		_interaction.cell = cell
	if _override != null:
		_override.cell = cell


## Démarre la routine de marche depuis [param cell] (une case de [member _route]) : il attend
## une pause avant le premier pas.
func _start_route(cell: Vector2i) -> void:
	_route_active = true
	_route_suspended = false
	# Case de départ : l'index de la donnée (« start », jalon 7) ; ailleurs (grille
	# reconstruite en chemin), la première occurrence de la case.
	_route_index = _spec.route_start if cell == _spec.cell else maxi(_route.find(cell), 0)
	_route_wait = _route_pause
	set_process(true)


## Un pas vers la case suivante de la routine (boucle). Si elle est prise (le joueur y est),
## il patiente et réessaiera : il ne bloque jamais le passage, ne force jamais un pas.
func _advance_route() -> void:
	if _route.size() < 2:
		_route_active = false
		return
	var target_index := (_route_index + 1) % _route.size()
	var next := _route[target_index]
	var direction := Grid.dominant_direction(get_cell(), next)
	if direction == Vector2i.ZERO:
		_route_index = target_index
		_route_wait = _route_pause
		return
	if step(direction):
		_route_index = target_index
	else:
		# Case prise (joueur) : il se tourne vers elle et attend, sans avancer.
		_route_wait = _route_pause


## Envol d'un Pokémon d'ambiance (Roucool, jalon 5 §3.5) : montée en arc vers le haut et le
## bord, fondu, puis [signal left_scene]. Libère sa case tout de suite.
func fly_away() -> void:
	if _leaving:
		return
	_leaving = true
	_route_active = false
	_abort_hop()
	if _mover != null:
		leave_grid()
	if not is_inside_tree() or _sprite == null:
		left_scene.emit(get_id())
		return
	if _leave_tween != null and _leave_tween.is_valid():
		_leave_tween.kill()
	_leave_tween = create_tween()
	_leave_tween.set_parallel(true)
	var drift := FLY_DRIFT if _facing != Vector2i.LEFT else -FLY_DRIFT
	_leave_tween.tween_property(_sprite, ^"position",
		Vector2(_sprite.position.x + drift, _sprite.position.y - FLY_RISE), FLY_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_leave_tween.tween_property(_sprite, ^"modulate:a", 0.0, FLY_DURATION)
	_leave_tween.tween_property(_shadow, ^"modulate:a", 0.0, FLY_DURATION)
	_leave_tween.chain().tween_callback(func() -> void: left_scene.emit(get_id()))


## Fuite d'un Pokémon d'ambiance (Rattata, jalon 5 §3.5) : il détale en courant le long de
## [param path] (directions), puis fondu et [signal left_scene]. Chemin vide : il se retourne
## et [method react] (il reste ; le watcher ne le retire pas).
func flee(path: Array[Vector2i]) -> void:
	if _leaving:
		return
	_route_active = false
	if path.is_empty():
		react()
		return
	_leaving = true
	_abort_hop()
	_flee_steps(path.duplicate())


func _flee_steps(remaining: Array[Vector2i]) -> void:
	if remaining.is_empty():
		_flee_fade()
		return
	var direction: Vector2i = remaining.pop_front()
	if not step(direction, true):
		_flee_fade()
		return
	await step_finished
	_flee_steps(remaining)


func _flee_fade() -> void:
	if _mover != null:
		leave_grid()
	if not is_inside_tree() or _sprite == null:
		left_scene.emit(get_id())
		return
	if _leave_tween != null and _leave_tween.is_valid():
		_leave_tween.kill()
	_leave_tween = create_tween()
	_leave_tween.tween_property(_sprite, ^"modulate:a", 0.0, FLEE_FADE_DURATION)
	_leave_tween.parallel().tween_property(_shadow, ^"modulate:a", 0.0, FLEE_FADE_DURATION)
	_leave_tween.tween_callback(func() -> void: left_scene.emit(get_id()))


func _on_animation_finished() -> void:
	if _sprite.animation == REACT_ANIM or _REACT_ANIMS.values().has(_sprite.animation):
		_play_idle()
