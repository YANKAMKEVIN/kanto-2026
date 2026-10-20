class_name SpinTileDirector
extends Node
## Dalles tournantes dans le moteur (jalon 20 T19, `docs/tech/jalon-20.md` §2.4.4 ; dossier 23
## §13.3). Enfant de [Boot]. La règle est dans [SpinTileRules] (pur) ; les données de la carte
## dans son nœud `SpinTiles` ([SpinTileField], groupe [constant SpinTileField.GROUP]).
##
## - **Carte** ([method set_map], relais de `SceneRouter.map_changed`, écran noir) : trouve le
##   [SpinTileField] de la carte ; sans lui, veille (aucun coût hors du repaire). Si le joueur
##   vient d'être posé **sur une dalle** (reprise d'une sauvegarde ancienne ou abîmée, départ de
##   débogage), il est reposé sur la case stable de [method SpinTileField.safe_cell].
## - **Glisse** : [signal Player.moved] sur une dalle, **entrée libre** → le joueur est bloqué
##   (raison [constant LOCK_REASON] : [method Boot.is_stable] faux, donc ni autosave ni menu ni
##   retour Android), [signal slide_started] (Boot rentre le compagnon et cache les contrôles),
##   puis un pas de course par case du trajet, chacun lancé dans le [signal Player.moved] du
##   précédent (aucune image d'arrêt) ; le joueur pivote dans le sens de chaque dalle.
## - **Fin** (différée d'une image d'appel : les autres écouteurs du dernier pas le voient encore
##   bloqué, donc ni passage, ni déclencheur, ni rencontre) : verrou levé, [signal
##   slide_finished], puis [method TrainerWatcher.check_at] sur la case d'arrêt.
## - **Pas refusé** (case occupée, erreur de données) : la glisse s'arrête sur place,
##   `push_error`.
## Le directeur se branche sur [signal Player.moved] **avant** les autres écouteurs (Boot) : le
## pas qui pose le joueur sur une dalle n'est vu par personne d'autre comme un pas libre.

## Une glisse commence ([param slide] : trajet complet, voir [SpinSlide]).
signal slide_started(slide: SpinSlide)
## Glisse finie sur [param cell] (case d'arrêt, ou case atteinte si un pas a été refusé).
signal slide_finished(cell: Vector2i)

## Raison de blocage du joueur pendant la glisse.
const LOCK_REASON: StringName = &"spin"
## Pas de la glisse : en courant (vitesse de course, §2.4.4).
const RUN: bool = true

var _player: Player
var _trainers: TrainerWatcher
var _map: GameMap
var _field: SpinTileField
var _slide: SpinSlide
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
## case stable s'il est sur une dalle.
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
			push_error("SpinTileDirector (%s) : %s" % [map.map_id, error])
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


## Dalles de la carte courante (null hors repaire).
func get_field() -> SpinTileField:
	return _field


## La glisse en cours (null sinon).
func get_slide() -> SpinSlide:
	return _slide if is_running() else null


## Vrai pendant une glisse (partie pas stable : aucune écriture).
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
	if _field == null or not is_instance_valid(_player) or not _player.is_input_enabled():
		return
	if _field.is_arrow(cell):
		_start(cell)


func _start(cell: Vector2i) -> void:
	var slide := _field.slide_from(cell, _walkable)
	if not slide.is_ok():
		push_error("SpinTileDirector (%s) : dalle %s en erreur (%s)" % [_map_id(), cell,
			SpinSlide.Status.keys()[slide.status]])
		return
	_slide = slide
	# Synchrone, dans le `moved` du pas qui pose le joueur sur la dalle : les écouteurs suivants
	# voient un joueur bloqué, et le pas qui s'enchaînerait ne part pas.
	_player.set_input_enabled(false, LOCK_REASON)
	slide_started.emit(slide)
	_next_step()


## Un pas de la glisse vient de finir sur [param cell].
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
	if _player.script_step(direction, RUN):
		return
	push_error("SpinTileDirector (%s) : pas refusé vers %s depuis %s, glisse arrêtée"
		% [_map_id(), _slide.next_cell(), _player.get_cell()])
	_slide.abort()
	_finish.call_deferred()


## Fin de la glisse : verrou levé, signal, puis la vue des Dresseurs sur la case d'arrêt.
func _finish() -> void:
	if _slide == null:
		return
	var cell := _slide.end
	_slide = null
	if is_instance_valid(_player):
		_player.set_input_enabled(true, LOCK_REASON)
	slide_finished.emit(cell)
	if _trainers != null:
		_trainers.check_at(cell)


## Carte quittée ou rechargée en pleine glisse (ne doit pas arriver : les passages ignorent les
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
	print("SpinTileDirector : joueur sur la dalle %s de %s, reposé en %s" % [cell, _map_id(),
		target])
	_map.spawn_player_at(_player, target, _player.get_facing())


func _map_id() -> StringName:
	return _map.map_id if is_instance_valid(_map) else &""
