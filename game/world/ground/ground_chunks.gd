class_name GroundChunks
extends Node2D
## Sol peint cuit **par morceaux** (moteur commun, perf A17 ; généralise la cuisson du J21,
## [method PaintedGround.bake], aux grandes cartes et aux cartes avec de l'eau). Le sol est
## découpé en carrés de [constant CHUNK_PX] px ; seuls ceux qui touchent la vue (plus
## [constant NEED_MARGIN_PX] d'avance) sont rendus, **une fois** chacun, dans un `SubViewport`
## (mêmes coordonnées du monde, mêmes matériaux : mêmes pixels) puis affichés comme de simples
## textures. Les morceaux sortis de la vue de plus de [constant KEEP_MARGIN_PX] sont oubliés et
## leur `SubViewport` resservira : la mémoire reste celle de la vue (≈ 40 Mo au plus en RGBA8 sur
## un écran 2340 × 1080), quelle que soit la taille de la carte.
## Couches cuites ([method setup], « sources ») : le sol peint (sans l'eau, passe « terre » du
## shader) et le sous-bois ([ForestFloor]) ; l'eau animée reste vivante ([GroundWater]).
## **Aucun trou** : un morceau demandé mais pas encore rendu est dessiné par le shader vivant de
## chaque source ([method get_fallback_chunks]) jusqu'à l'image qui suit son rendu. Au premier
## passage (écran noir du changement de carte), tous les morceaux de la vue partent d'un coup ;
## ensuite, au plus [constant BAKES_PER_FRAME] par image (le joueur va moins vite que l'avance).
## Enfant du [PaintedGround] (mêmes coordonnées, même z) ; nœuds sans propriétaire, jamais
## enregistrés dans la scène.

const NODE_NAME: StringName = &"BakedChunks"
## Côté d'un morceau (px du monde) : 1 Mo de mémoire vidéo.
const CHUNK_PX: int = 512
## Avance autour de la vue : un morceau qui y entre est rendu avant d'être visible.
const NEED_MARGIN_PX: float = 256.0
## Au-delà de cette marge autour de la vue, un morceau est oublié (hystérésis).
const KEEP_MARGIN_PX: float = 640.0
## Morceaux rendus au plus par image, hors premier passage.
const BAKES_PER_FRAME: int = 2

enum State { BAKING, READY }

## Taille du sol (px).
var _ground_px: Vector2i
## Couches cuites : { material, transform (dans le repère du sol), rect (dans leur repère) }.
var _sources: Array[Dictionary] = []
var _sprites: Node2D
## Dessins vivants de repli, un par source.
var _fallbacks: Array[_RectDrawer] = []
## Morceau → { state, slot }.
var _chunks: Dictionary[Vector2i, Dictionary] = {}
## Emplacements libres (SubViewport + Sprite2D) à resservir.
var _pool: Array[Dictionary] = []
var _in_flight: Array[Vector2i] = []
var _fallback_chunks: Array[Vector2i] = []
var _first: bool = true
## Vue forcée (tests) ; vide = celle de la caméra.
var _view_override: Rect2 = Rect2()
var _stats_baked: int = 0


## [param ground_px] : taille du sol ; [param sources] : couches à cuire, dans leur ordre de
## dessin (voir l'en-tête).
func setup(ground_px: Vector2i, sources: Array[Dictionary]) -> void:
	name = NODE_NAME
	_ground_px = ground_px
	_sources = sources
	_sprites = Node2D.new()
	_sprites.name = "Sprites"
	add_child(_sprites)
	for source: Dictionary in sources:
		var drawer := _RectDrawer.new()
		drawer.name = "Fallback"
		drawer.material = source["material"]
		drawer.transform = source["transform"]
		add_child(drawer)
		_fallbacks.append(drawer)


func _process(_delta: float) -> void:
	update_view(_view_override if _view_override.has_area() else _camera_view())


## Vue dans le repère du sol : celle de la caméra (tests : [method set_view_override]).
func set_view_override(view: Rect2) -> void:
	_view_override = view


## Morceaux à rendre, à garder et à dessiner en repli pour [param view] (repère du sol).
func update_view(view: Rect2) -> void:
	var need := chunks_in(view.grow(NEED_MARGIN_PX), _ground_px, CHUNK_PX)
	var keep := chunks_in(view.grow(KEEP_MARGIN_PX), _ground_px, CHUNK_PX)
	for index: Vector2i in _chunks.keys():
		if not keep.has(index) and _chunks[index]["state"] == State.READY:
			_release(index)
	var todo: Array[Vector2i] = []
	for index: Vector2i in need:
		if not _chunks.has(index):
			todo.append(index)
	var center := view.get_center()
	todo.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _distance(a, center) < _distance(b, center))
	var budget := todo.size() if _first else mini(BAKES_PER_FRAME, todo.size())
	_first = false
	for i: int in budget:
		_start(todo[i])
	var fallback: Array[Vector2i] = []
	for index: Vector2i in need:
		if not _chunks.has(index) or _chunks[index]["state"] != State.READY:
			fallback.append(index)
	if fallback != _fallback_chunks:
		_set_fallback(fallback)


## Morceaux affichés comme textures.
func get_ready_chunks() -> Array[Vector2i]:
	var ready: Array[Vector2i] = []
	for index: Vector2i in _chunks:
		if _chunks[index]["state"] == State.READY:
			ready.append(index)
	return ready


## Morceaux dessinés par le shader vivant (demandés, pas encore rendus).
func get_fallback_chunks() -> Array[Vector2i]:
	return _fallback_chunks.duplicate()


## Nombre de `SubViewport` créés (en service ou libres).
func get_viewport_count() -> int:
	return _chunks.size() + _pool.size()


## Morceaux rendus depuis le début (journal, tests).
func get_baked_count() -> int:
	return _stats_baked


## Nombre de morceaux (colonnes, rangées) d'un sol de [param ground_px].
static func chunk_grid(ground_px: Vector2i, chunk: int) -> Vector2i:
	return Vector2i(ceili(ground_px.x / float(chunk)), ceili(ground_px.y / float(chunk)))


## Rectangle (px, repère du sol) du morceau [param index], rogné au bord du sol.
static func chunk_rect(index: Vector2i, ground_px: Vector2i, chunk: int) -> Rect2i:
	var origin := index * chunk
	return Rect2i(origin, Vector2i(mini(chunk, ground_px.x - origin.x),
		mini(chunk, ground_px.y - origin.y)))


## Morceaux qui touchent [param rect] (repère du sol), dans les limites du sol.
static func chunks_in(rect: Rect2, ground_px: Vector2i, chunk: int) -> Array[Vector2i]:
	var grid := chunk_grid(ground_px, chunk)
	var first := Vector2i(clampi(floori(rect.position.x / chunk), 0, grid.x),
		clampi(floori(rect.position.y / chunk), 0, grid.y))
	var last := Vector2i(clampi(ceili(rect.end.x / chunk), 0, grid.x),
		clampi(ceili(rect.end.y / chunk), 0, grid.y))
	var result: Array[Vector2i] = []
	for y: int in range(first.y, last.y):
		for x: int in range(first.x, last.x):
			result.append(Vector2i(x, y))
	return result


func _distance(index: Vector2i, center: Vector2) -> float:
	return Rect2(chunk_rect(index, _ground_px, CHUNK_PX)).get_center().distance_squared_to(center)


func _camera_view() -> Rect2:
	var viewport := get_viewport()
	var screen := Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
	var world := viewport.get_canvas_transform().affine_inverse() * screen
	return get_global_transform().affine_inverse() * world


func _start(index: Vector2i) -> void:
	var slot: Dictionary = _pool.pop_back() if not _pool.is_empty() else _new_slot()
	var rect := chunk_rect(index, _ground_px, CHUNK_PX)
	var viewport: SubViewport = slot["viewport"]
	viewport.size = rect.size
	# Le sol cuit est ramené en (0, 0) de la vue, décalé de l'origine du morceau.
	viewport.canvas_transform = Transform2D(0.0, -Vector2(rect.position)) \
		* get_global_transform().affine_inverse()
	(slot["stage"] as Node2D).transform = get_global_transform()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var sprite: Sprite2D = slot["sprite"]
	sprite.position = rect.position
	sprite.visible = false
	_chunks[index] = {"state": State.BAKING, "slot": slot}
	_in_flight.append(index)
	if _in_flight.size() == 1:
		# Après le rendu de la vue (sans rendu, sous GUT : l'image suivante).
		var rendered: Signal = RenderingServer.frame_post_draw \
			if DisplayServer.get_name() != "headless" else get_tree().process_frame
		rendered.connect(_on_rendered, CONNECT_ONE_SHOT)


func _on_rendered() -> void:
	if not is_inside_tree():
		return
	for index: Vector2i in _in_flight:
		if _chunks.has(index):
			_chunks[index]["state"] = State.READY
			(_chunks[index]["slot"]["sprite"] as Sprite2D).visible = true
			_stats_baked += 1
	_in_flight.clear()
	var fallback: Array[Vector2i] = []
	for index: Vector2i in _fallback_chunks:
		if not _chunks.has(index) or _chunks[index]["state"] != State.READY:
			fallback.append(index)
	_set_fallback(fallback)


func _release(index: Vector2i) -> void:
	var slot: Dictionary = _chunks[index]["slot"]
	(slot["sprite"] as Sprite2D).visible = false
	_chunks.erase(index)
	_pool.append(slot)


func _new_slot() -> Dictionary:
	var viewport := SubViewport.new()
	viewport.name = "ChunkBake"
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var stage := Node2D.new()
	for source: Dictionary in _sources:
		var piece := PaintedGround.BakeSource.new()
		piece.rect = source["rect"]
		piece.material = source["material"]
		piece.transform = source["transform"]
		stage.add_child(piece)
	viewport.add_child(stage)
	add_child(viewport)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.visible = false
	sprite.texture = viewport.get_texture()
	_sprites.add_child(sprite)
	return {"viewport": viewport, "stage": stage, "sprite": sprite}


func _set_fallback(chunks: Array[Vector2i]) -> void:
	_fallback_chunks = chunks
	for i: int in _fallbacks.size():
		var drawer := _fallbacks[i]
		var to_source: Transform2D = (_sources[i]["transform"] as Transform2D).affine_inverse()
		var rects: Array[Rect2] = []
		for index: Vector2i in chunks:
			rects.append(to_source * Rect2(chunk_rect(index, _ground_px, CHUNK_PX)))
		drawer.rects = rects
		drawer.queue_redraw()


## Rectangles dessinés par le shader vivant d'une source (repli).
class _RectDrawer:
	extends Node2D
	var rects: Array[Rect2] = []

	func _draw() -> void:
		for rect: Rect2 in rects:
			draw_rect(rect, Color.WHITE)
