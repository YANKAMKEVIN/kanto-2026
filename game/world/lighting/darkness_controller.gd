class_name DarknessController
extends Node
## Pose le voile d'obscurité ([DarknessVeil]) sur les cartes obscures et le retire ailleurs ;
## fait suivre le trou au joueur ; ouvre le halo (Flash). Brique commune J17 T9 / J18
## (docs/tech/jalon-18.md §2.5, §2.8 ; docs/tech/jalon-17.md §2.10). Possédé par Boot (comme
## [WorldLighting]) ; le voile vit sous le nœud monde de Boot, un seul pour tout le jeu.
##
## **Aucune règle de jeu ici** : qui est obscur ([method CaveLibrary.is_dark]), quand Flash est
## allumée et si la mise en scène se joue (question Q-1 du J17, non tranchée) se décident hors
## d'ici ; ce nœud expose seulement l'état « Flash allumée / éteinte » ([method set_map],
## [method open], [method is_lit]) et un rayon animable ([method lit_amount]).
##
## Hors du noir : voile caché, `set_process(false)` (aucun coût). Dans le noir, à chaque image :
## centre du trou = centre du corps du joueur, rectangle = vue de la caméra + une case de marge ;
## rien n'est alloué, un paramètre n'est poussé au shader que s'il change.

## Fin de l'ouverture du halo ([method open]).
signal opened

## Marge autour de la vue (px) : la caméra peut avancer d'une image avant le voile.
const VIEW_MARGIN: float = Grid.TILE_SIZE
## Après le joueur et la caméra : centre et vue de la même image.
const PROCESS_PRIORITY: int = 100

var _veil: DarknessVeil
var _player: Node2D
var _profile: DarknessProfile = DarknessProfile.new()
var _params: VeilParams = VeilParams.new()
var _dark: bool = false
var _lit_amount: float = 0.0
var _reduce_motion: bool = false
var _tween: Tween


func _init() -> void:
	name = "DarknessController"
	process_priority = PROCESS_PRIORITY
	_veil = DarknessVeil.new()
	set_process(false)


func _notification(what: int) -> void:
	# Voile jamais posé dans un monde (setup non appelé) : libéré avec le contrôleur.
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_veil) and _veil.get_parent() == null:
		_veil.free()


func _process(_delta: float) -> void:
	_follow()


## Branche le voile sous [param world] (le nœud qui porte les cartes), le joueur suivi et les
## réglages ([param profile] null : ceux de `data/world/darkness.json`).
func setup(world: Node2D, player: Node2D, profile: DarknessProfile = null) -> void:
	_player = player
	if profile != null:
		_profile = profile
	else:
		_profile = DarknessProfile.new()
		_profile.load_file()
	if _veil.get_parent() != null:
		_veil.get_parent().remove_child(_veil)
	world.add_child(_veil)
	_veil.set_color(_profile.color)
	_veil.set_dither(_profile.dither)
	_veil.set_breath(_profile.breath(_reduce_motion), _profile.breath_period)
	_apply_lit_amount(_lit_amount)


## Nouvelle carte (pendant l'écran noir, carte déjà dans l'arbre) : voile posé **sans
## animation** si [param dark] (halo ouvert si [param lit]), retiré sinon. Les halos fixes de la
## carte sont relevés ici, une fois.
func set_map(map: Node, dark: bool, lit: bool) -> void:
	_stop_tween()
	_dark = dark
	_apply_lit_amount(1.0 if dark and lit else 0.0)
	if not dark:
		_veil.visible = false
		_veil.set_sources(PackedVector4Array())
		set_process(false)
		return
	_veil.set_sources(VeilMath.sources_of(_glows_of(map), LightGlow.library(),
		_profile.glow_hole_scale))
	_veil.visible = true
	set_process(true)
	_follow()


## Ouvre le halo (Flash) : rayon « sombre » → rayon « Flash » en
## [member DarknessProfile.open_duration] (instantané avec « Réduire les animations »), puis
## [signal opened]. Hors du noir ou déjà ouvert : [signal opened] tout de suite.
func open() -> void:
	_stop_tween()
	if not _dark or _reduce_motion or _lit_amount >= 1.0:
		_apply_lit_amount(1.0 if _dark else _lit_amount)
		opened.emit()
		return
	_tween = create_tween()
	_tween.tween_method(_apply_lit_amount, _lit_amount, 1.0, _profile.open_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.finished.connect(_on_opened)


## Vrai si la carte courante est couverte par le voile.
func is_dark() -> bool:
	return _dark


## Ouverture du halo : 0 = sans Flash, 1 = Flash (entre les deux pendant l'ouverture).
func lit_amount() -> float:
	return _lit_amount


## Vrai si Flash éclaire la carte (halo entièrement ouvert).
func is_lit() -> bool:
	return _dark and _lit_amount >= 1.0


## Vrai pendant l'ouverture animée.
func is_opening() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## « Réduire les animations » : battement coupé ; une ouverture en cours finit tout de suite.
func set_reduce_motion(enabled: bool) -> void:
	_reduce_motion = enabled
	_veil.set_breath(_profile.breath(enabled), _profile.breath_period)
	if enabled and is_opening():
		open()


func get_veil() -> DarknessVeil:
	return _veil


func get_profile() -> DarknessProfile:
	return _profile


func _apply_lit_amount(amount: float) -> void:
	_lit_amount = clampf(amount, 0.0, 1.0)
	_profile.fill_params(_params, _lit_amount)
	_veil.set_params(_params)


func _on_opened() -> void:
	_tween = null
	opened.emit()


func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


## Centre du trou et rectangle couvert (vue de la caméra + marge).
func _follow() -> void:
	if not _veil.is_inside_tree():
		return
	if is_instance_valid(_player) and _player.is_inside_tree():
		_veil.set_center(VeilMath.body_center(_player.global_position, _profile.center_offset))
	var viewport := _veil.get_viewport()
	var view := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	_veil.set_view_rect(VeilMath.cover_rect(view, VIEW_MARGIN))


static func _glows_of(map: Node) -> Array[LightGlow]:
	var glows: Array[LightGlow] = []
	if map == null:
		return glows
	for node: Node in map.find_children("*", "Sprite2D", true, false):
		if node is LightGlow:
			glows.append(node as LightGlow)
	return glows
