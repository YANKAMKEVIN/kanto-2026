class_name ForcedSlideDirector
extends Node
## Glissades forcées dans le moteur : un seul lecteur pour les **dalles tournantes** (jalon 20
## T19, `docs/tech/jalon-20.md` §2.4.4 ; dossier 23 §13.3) et les **courants** du Surf (passe
## systèmes 2 T15, `docs/tech/systemes-2.md` §2.5 point 7, §2.6). Enfant de [Boot]. Les règles
## sont pures : [SpinTileRules] (dalles, données dans le nœud `SpinTiles` de la carte,
## [SpinTileField]) et [CurrentField] (courants, posés dans la grille par
## [member GameMap.current_cells]) ; les deux trajets ont la forme commune [ForcedSlide].
##
## - **Carte** ([method set_map], relais de `SceneRouter.map_changed`, écran noir) : trouve le
##   [SpinTileField] de la carte (aucun hors du repaire). Si le joueur vient d'être posé **sur une
##   dalle** (reprise d'une sauvegarde ancienne ou abîmée, départ de débogage), il est reposé sur
##   la case stable de [method SpinTileField.safe_cell].
## - **Départ** : [signal Player.moved] d'un **pas libre** (joueur non bloqué) sur une dalle, ou,
##   **en Surf**, sur une case de courant ([method GridWorld.is_current]) ; ou, à l'arrivée sur une
##   carte en Surf sur un courant, [method ride_from_here] (Boot, `SceneRouter.map_entered`, après
##   l'écran noir : reprise, [member SurfRules.Resume.ride_current]). Le joueur est bloqué (raison
##   [constant LOCK_REASON] : [method Boot.is_stable] faux, donc ni autosave ni menu ni retour
##   Android), [signal slide_started] (Boot rentre le compagnon et cache les contrôles), puis un
##   pas par case du trajet, chacun lancé dans le [signal Player.moved] du précédent (aucune image
##   d'arrêt), le joueur tourné dans le sens de chaque pas : en **course** sur les dalles
##   ([constant SPIN_RUN]), à la **vitesse du Surf** sur un courant ([constant CURRENT_RUN]).
## - **Fin** (différée d'une image d'appel : les autres écouteurs du dernier pas le voient encore
##   bloqué, donc ni passage, ni déclencheur, ni rencontre) : descente à pied si le courant finit
##   sur la terre ([member ForcedSlide.dismounts]), verrou levé, [signal slide_finished], puis
##   - courant fini sur un passage ([member ForcedSlide.warp]) : [signal warp_reached], que Boot
##     relaie à `SceneRouter.follow_warp_at` (les passages ignorent les pas scriptés) ;
##   - sinon [method TrainerWatcher.check_at] sur la case d'arrêt.
## - **Erreur de données** (trajet BLOCKED, LOOP, TOO_LONG) : `push_error`, aucune glisse. **Pas
##   refusé** en route (case occupée) : la glisse s'arrête sur place, `push_error`.
## Le directeur se branche sur [signal Player.moved] **avant** les autres écouteurs (Boot) : le
## pas qui lance une glisse n'est vu par personne d'autre comme un pas libre.

## Une glissade commence ([param slide] : trajet complet, [SpinSlide] ou [CurrentField.Ride]).
signal slide_started(slide: ForcedSlide)
## Glissade finie sur [param cell] (case d'arrêt, ou case atteinte si un pas a été refusé).
signal slide_finished(cell: Vector2i)
## Courant fini sur le passage de [param cell], atteint vers [param direction] : à suivre (verrou
## déjà levé, juste après [signal slide_finished]).
signal warp_reached(cell: Vector2i, direction: Vector2i)

## Raison de blocage du joueur pendant la glissade.
const LOCK_REASON: StringName = &"forced_slide"
## Pas des dalles : en courant (vitesse de course, jalon-20 §2.4.4).
const SPIN_RUN: bool = true
## Pas d'un courant : sans course, donc à la vitesse du Surf ([method MountRules.step_duration]).
const CURRENT_RUN: bool = false

var _player: Player
var _trainers: TrainerWatcher
var _map: GameMap
var _field: SpinTileField
var _slide: ForcedSlide
var _run: bool = false
var _walkable: Callable = Callable()


func _ready() -> void:
	set_process(false)


## Branche le directeur. [param trainers] : la vue des Dresseurs (case d'arrêt) ; null en test.
## À appeler avant tout autre branchement sur [signal Player.moved] (voir l'en-tête).
func setup(player: Player, trainers: TrainerWatcher) -> void:
	if is_instance_valid(_player) and _player.moved.is_connected(_on_player_moved):
		_player.moved.disconnect(_on_player_moved)
	_player = player
	_trainers = trainers
	if _player != null:
		_player.moved.connect(_on_player_moved)


## Nouvelle carte (écran noir, joueur déjà posé) : dalles de la carte, et joueur reposé sur une
## case stable s'il est sur une dalle. Les courants sont lus dans la grille à chaque pas.
func set_map(map: GameMap) -> void:
	_cancel()
	_map = map
	_field = find_field(map)
	_walkable = Callable()
	if _field == null:
		return
	var grid := map.get_grid()
	_walkable = func(cell: Vector2i) -> bool:
		return grid.is_in_bounds(cell) and not grid.is_solid(cell) and not grid.is_water(cell)
	if OS.is_debug_build():
		for error: String in _field.check(_walkable):
			push_error("ForcedSlideDirector (%s) : %s" % [map.map_id, error])
	_settle_player()


## Le [SpinTileField] de [param map] (nœud `SpinTiles`, ou tout nœud du groupe sous la carte) ;
## null s'il n'y en a pas.
static func find_field(map: GameMap) -> SpinTileField:
	if not is_instance_valid(map):
		return null
	var named := map.get_node_or_null(^"SpinTiles") as SpinTileField
	if named != null:
		return named
	if not map.is_inside_tree():
		return null
	for node: Node in map.get_tree().get_nodes_in_group(SpinTileField.GROUP):
		if map.is_ancestor_of(node):
			return node as SpinTileField
	return null


## Arrivée sur la carte (écran visible, `SceneRouter.map_entered`) : si le joueur, libre et **en
## Surf**, est sur une case de courant, la glissade part d'ici. Vrai si elle est partie.
func ride_from_here() -> bool:
	if _slide != null or not is_instance_valid(_player) or not is_instance_valid(_map):
		return false
	if not _player.is_input_enabled() or _player.is_moving():
		return false
	return _try_current(_player.get_cell())


## Dalles de la carte courante (null hors repaire).
func get_field() -> SpinTileField:
	return _field


## La glissade en cours (null sinon).
func get_slide() -> ForcedSlide:
	return _slide if is_running() else null


## Vrai pendant une glissade (partie pas stable : aucune écriture).
func is_running() -> bool:
	return _slide != null


## Case stable pour [param cell] sur la carte courante : la case elle-même hors dalle, sinon la
## fin de sa glisse.
func stable_cell(cell: Vector2i) -> Vector2i:
	if _field == null or not _walkable.is_valid():
		return cell
	return _field.safe_cell(cell, _walkable)


func _on_player_moved(cell: Vector2i) -> void:
	if _slide != null:
		_advance(cell)
		return
	if not is_instance_valid(_player) or not _player.is_input_enabled() \
			or not is_instance_valid(_map):
		return
	if _field != null and _field.is_arrow(cell):
		_start_spin(cell)
	else:
		_try_current(cell)


func _start_spin(cell: Vector2i) -> void:
	var slide := _field.slide_from(cell, _walkable)
	if not slide.is_ok():
		push_error("ForcedSlideDirector (%s) : dalle %s en erreur (%s)" % [_map_id(), cell,
			slide.status_name()])
		return
	_play(slide, SPIN_RUN)


## Courant sous [param cell], joueur en Surf : trajet jusqu'à l'eau calme, la terre ou un passage
## de la carte. Vrai si la glissade est partie.
func _try_current(cell: Vector2i) -> bool:
	if _player.get_mount() != Mount.Kind.SURF:
		return false
	var grid := _map.get_grid()
	if not grid.is_current(cell):
		return false
	var ride := CurrentField.ride(grid, cell, _terminals(), _player)
	if not ride.is_ok():
		push_error("ForcedSlideDirector (%s) : courant %s en erreur (%s, case %s)" % [_map_id(),
			cell, ride.status_name(), ride.end])
		return false
	if ride.size() == 0:
		return false  # départ sur un passage : le routeur le suit comme un pas libre
	_play(ride, CURRENT_RUN)
	return true


## Cases des passages de la carte : un courant qui y arrive s'y arrête par un transfert.
func _terminals() -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	for warp: Warp in _map.get_warps().get_all():
		cells[warp.cell] = true
	return cells


func _play(slide: ForcedSlide, run: bool) -> void:
	_slide = slide
	_run = run
	# Synchrone, dans le `moved` du pas qui lance la glissade : les écouteurs suivants voient un
	# joueur bloqué, et le pas qui s'enchaînerait ne part pas.
	_player.set_input_enabled(false, LOCK_REASON)
	slide_started.emit(slide)
	_next_step()


## Un pas de la glissade vient de finir sur [param cell].
func _advance(cell: Vector2i) -> void:
	if cell != _slide.next_cell():
		return
	_slide.step_done()
	if _slide.is_sliding():
		_next_step()
	else:
		_finish.call_deferred()


func _next_step() -> void:
	var direction := _slide.next_direction()
	_player.face(direction)
	if _player.script_step(direction, _run):
		return
	push_error("ForcedSlideDirector (%s) : pas refusé vers %s depuis %s, glisse arrêtée"
		% [_map_id(), _slide.next_cell(), _player.get_cell()])
	_slide.abort()
	_finish.call_deferred()


## Fin de la glissade : descente éventuelle, verrou levé, signal, puis le passage ou la vue des
## Dresseurs sur la case d'arrêt.
func _finish() -> void:
	if _slide == null:
		return
	var slide := _slide
	_slide = null
	if not is_instance_valid(_player):
		return
	if slide.dismounts:
		_player.set_mount(Mount.Kind.NONE)
	_player.set_input_enabled(true, LOCK_REASON)
	slide_finished.emit(slide.end)
	if slide.warp:
		warp_reached.emit(slide.end, _player.get_facing())
	elif _trainers != null:
		_trainers.check_at(slide.end)


## Carte quittée ou rechargée en pleine glissade (ne doit pas arriver : les passages ignorent les
## pas scriptés) : verrou levé sans rien d'autre.
func _cancel() -> void:
	if _slide == null:
		return
	_slide = null
	if is_instance_valid(_player):
		_player.set_input_enabled(true, LOCK_REASON)


## Joueur posé sur une dalle : reposé sur la case stable (ou la case libre la plus proche).
func _settle_player() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_map):
		return
	var cell := _player.get_cell()
	if not _field.is_arrow(cell):
		return
	var target := _map.find_standing_cell(stable_cell(cell), _player)
	if target == Vector2i(-1, -1) or target == cell:
		return
	print("ForcedSlideDirector : joueur sur la dalle %s de %s, reposé en %s" % [cell, _map_id(),
		target])
	_map.spawn_player_at(_player, target, _player.get_facing())


func _map_id() -> StringName:
	return _map.map_id if is_instance_valid(_map) else &""
