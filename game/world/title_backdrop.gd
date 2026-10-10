class_name TitleBackdrop
extends Node2D
## Fond de l'écran titre (OUV.1, dossier 13 A9, §3.7, §5.2) : la vraie carte (Bourg Palette) en
## **mode décor**, cadrée par sa propre caméra qui dérive lentement.
##
## Mode décor : la carte est instanciée ici, **sans [code]SceneRouter[/code]** : ni
## `map_changed` / `map_entered` (donc ni zone découverte, ni titre de zone, ni autosave
## d'entrée), aucun joueur, et rien de [code]GameState[/code] n'est lu ni écrit. Les habitants sont
## ceux d'une nouvelle partie, sur leur case de départ (une carte sans joueur retient leurs
## routines de marche, [GameMap]). Boot la crée sous `World` au lancement du titre et la libère
## ([method release]) **avant** le commit d'une nouvelle partie ou la reprise : la caméra du joueur
## redevient alors la seule.
## « Réduire les animations » : pas de dérive ([method set_reduce_motion]).

## Carte du décor et point visé par la caméra au repos (pixels de la carte). Défauts (règle 4) :
## le centre de Bourg Palette, entre les deux maisons et au-dessus du labo.
@export var map_id: StringName = &"pallet_town"
@export var focus: Vector2 = Vector2(2304, 1180)
## Dérive : amplitude (pixels, aller-retour autour de [member focus]) et durée d'un aller.
@export var drift: Vector2 = Vector2(160, 40)
@export var drift_duration: float = 24.0

var _map: GameMap
var _camera: Camera2D
var _tween: Tween
var _reduce_motion: bool = false


## Charge et montre la carte (à appeler une fois, dans l'arbre). Faux si elle n'existe pas.
func show_map() -> bool:
	var path := MapCatalog.scene_path(map_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("TitleBackdrop : carte inconnue « %s »" % map_id)
		return false
	var packed := load(path) as PackedScene
	_map = packed.instantiate() as GameMap if packed != null else null
	if _map == null:
		push_error("TitleBackdrop : « %s » n'est pas une carte" % map_id)
		return false
	add_child(_map)
	_camera = Camera2D.new()
	_camera.name = "TitleCamera"
	var limits := CameraFraming.limits_for(_map.get_pixel_rect(), get_viewport_rect().size)
	_camera.limit_left = limits.position.x
	_camera.limit_top = limits.position.y
	_camera.limit_right = limits.end.x
	_camera.limit_bottom = limits.end.y
	_camera.position = focus
	add_child(_camera)
	_camera.make_current()
	_restart_drift()
	return true


## Coupe ou rétablit la dérive (« Réduire les animations ») ; coupée, la caméra revient au repos.
func set_reduce_motion(reduce: bool) -> void:
	_reduce_motion = reduce
	_restart_drift()


## Libère tout de suite la carte et la caméra (avant que la partie ne place la sienne).
func release() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	var parent := get_parent()
	if parent != null:
		parent.remove_child(self)
	queue_free()


func get_map() -> GameMap:
	return _map


func get_camera() -> Camera2D:
	return _camera


## Vrai si la caméra dérive.
func is_drifting() -> bool:
	return _tween != null and _tween.is_valid()


func _restart_drift() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	if _camera == null:
		return
	_camera.position = focus
	if _reduce_motion or drift == Vector2.ZERO or drift_duration <= 0.0:
		return
	_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_camera, ^"position", focus + drift, drift_duration)
	_tween.tween_property(_camera, ^"position", focus - drift, drift_duration * 2.0)
	_tween.tween_property(_camera, ^"position", focus, drift_duration)
