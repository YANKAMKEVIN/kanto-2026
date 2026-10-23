extends GutTest
## Moteur commun (perf A17, Routes 11, 12, 16 à 23-27 i/s) : un sol que la cuisson du J21 refuse
## (rivage, ou plus grand que 2048² px) est cuit par morceaux autour de la vue ([GroundChunks]),
## avec le sous-bois ; l'eau seule reste vivante, sur les cases d'eau ([GroundWater]).

const CHUNK := GroundChunks.CHUNK_PX


func _map(map_id: String) -> GameMap:
	var map: Node = (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
	add_child_autofree(map)
	return map as GameMap


func _chunked(map_id: String, view: Rect2) -> PaintedGround:
	var ground := _map(map_id).get_node(^"PaintedGround") as PaintedGround
	ground.bake_chunks()
	ground.get_chunks().set_view_override(view)
	return ground


# --- Règles pures ----------------------------------------------------------------------------

func test_chunk_grid_and_rects_are_clipped_to_the_ground() -> void:
	var ground := Vector2i(76, 36) * Grid.TILE_SIZE  # Route 11 : 7296 × 3456
	assert_eq(GroundChunks.chunk_grid(ground, CHUNK), Vector2i(15, 7))
	assert_eq(GroundChunks.chunk_rect(Vector2i(0, 0), ground, CHUNK), Rect2i(0, 0, CHUNK, CHUNK))
	assert_eq(GroundChunks.chunk_rect(Vector2i(14, 6), ground, CHUNK),
		Rect2i(14 * CHUNK, 6 * CHUNK, 7296 - 14 * CHUNK, 3456 - 6 * CHUNK), "bord rogné")


func test_chunks_in_a_rect_stay_inside_the_grid() -> void:
	var ground := Vector2i(2000, 1000)
	assert_eq(GroundChunks.chunks_in(Rect2(0, 0, 100, 100), ground, CHUNK), [Vector2i.ZERO])
	assert_eq(GroundChunks.chunks_in(Rect2(500, 0, 30, 30), ground, CHUNK).size(), 2,
		"à cheval sur deux morceaux")
	assert_eq(GroundChunks.chunks_in(Rect2(-900, -900, 5000, 5000), ground, CHUNK).size(), 8,
		"vue plus grande que le sol : tout le sol, rien au-delà")
	assert_true(GroundChunks.chunks_in(Rect2(3000, 3000, 10, 10), ground, CHUNK).is_empty())


func test_water_rects_square_and_natural_shores() -> void:
	var image := Image.create(6, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	for y: int in range(2, 4):
		for x: int in range(3, 6):
			image.set_pixel(x, y, Color(0, 1, 0))
	assert_eq(GroundWater.water_rects(image, true), [Rect2i(3, 2, 3, 2)] as Array[Rect2i],
		"angles droits : les cases d'eau seules, en un rectangle")
	assert_eq(GroundWater.water_rects(image, false),
		[Rect2i(2, 1, 4, 3)] as Array[Rect2i], "rivage naturel : et leurs voisines")
	image.fill(Color.BLACK)
	assert_true(GroundWater.water_rects(image, false).is_empty(), "sans eau : rien")


func test_forest_is_redrawn_only_on_water_near_the_forest() -> void:
	var covered: Array[bool] = [true, true, true, true, false, false]  # 3 × 2
	var forest := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	forest.fill(Color.BLACK)
	assert_true(GroundWater.forest_rects(covered, forest).is_empty())
	forest.set_pixel(2, 1, Color.WHITE)
	assert_eq(GroundWater.forest_rects(covered, forest),
		[Rect2i(1, 0, 2, 1)] as Array[Rect2i],
		"cases d'eau voisines du sous-bois seulement")


# --- Route 11 (76 × 36 cases, mer à angles droits, sous-bois) ---------------------------------

func test_route_11_is_too_big_for_one_bake_but_bakes_in_chunks() -> void:
	var ground := _map("route_11").get_node(^"PaintedGround") as PaintedGround
	assert_false(ground.can_bake(), "rivage et 7296 px de large : pas de cuisson d'un bloc")
	assert_true(ground.can_bake_chunks())
	assert_false(ground.is_chunked(), "sous GUT, rien n'est cuit d'office")
	assert_eq(ground.forest_layers().map(func(n: Node) -> StringName: return n.name),
		[&"ForestFloor"])


func test_chunks_cover_the_view_then_replace_the_fallback() -> void:
	var view := Rect2(3000, 1500, 2340, 1080)
	var ground := _chunked("route_11", view)
	var chunks := ground.get_chunks()
	assert_true(ground.is_chunked())
	assert_false((ground.get_parent().get_node(^"ForestFloor") as CanvasItem).visible,
		"sous-bois cuit avec le sol")
	await wait_physics_frames(1)
	await wait_process_frames(2)
	var need := GroundChunks.chunks_in(view.grow(GroundChunks.NEED_MARGIN_PX),
		Vector2i(76, 36) * Grid.TILE_SIZE, CHUNK)
	assert_eq(chunks.get_ready_chunks().size(), need.size(), "toute la vue, d'un coup")
	assert_true(chunks.get_fallback_chunks().is_empty(), "plus aucun repli vivant")
	assert_lt(need.size(), 40, "la mémoire reste celle de la vue")


func test_moving_view_bakes_new_chunks_and_recycles_old_ones() -> void:
	var view := Rect2(0, 0, 2340, 1080)
	var ground := _chunked("route_11", view)
	var chunks := ground.get_chunks()
	await wait_process_frames(3)
	var first := chunks.get_viewport_count()
	chunks.set_view_override(Rect2(4900, 2300, 2340, 1080))
	await wait_process_frames(1)
	assert_false(chunks.get_fallback_chunks().is_empty(),
		"saut de la vue : les morceaux pas encore rendus sont dessinés vivants")
	await wait_process_frames(30)
	assert_true(chunks.get_fallback_chunks().is_empty(), "rattrapé, quelques par image")
	assert_lt(chunks.get_viewport_count(), first * 2, "SubViewport resservis, pas empilés")


func test_land_is_baked_without_water_and_water_stays_live_on_water_cells() -> void:
	var ground := _chunked("route_11", Rect2(0, 0, 2340, 1080))
	assert_null(ground.get_shader_material().get_shader_parameter(&"pass_mode"),
		"matériau du sol inchangé (passe complète)")
	var water := ground.get_water()
	assert_not_null(water)
	assert_eq(water.name, GroundWater.NODE_NAME)
	assert_eq((water.material as ShaderMaterial).get_shader_parameter(&"pass_mode"),
		GroundWater.PASS_WATER)
	var cells := 0
	for rect: Rect2i in water.get_rects():
		cells += rect.get_area()
	var shore := ground.shore_mask.get_image()
	var water_cells := 0
	for y: int in shore.get_height():
		for x: int in shore.get_width():
			if shore.get_pixel(x, y).g > 0.5:
				water_cells += 1
	assert_eq(cells, water_cells, "angles droits : exactement les cases d'eau")
	assert_lt(cells, 76 * 36 / 2, "l'eau vivante ne couvre pas la carte")


func test_map_without_shore_and_small_still_uses_the_single_bake() -> void:
	var ground := _map("pokemon_tower_6f").get_node(^"PaintedGround") as PaintedGround
	assert_true(ground.can_bake(), "cuisson d'un bloc du J21 inchangée")


## Fusion de `main` (J21) : les Routes 12 et 16 du J21 prennent la cuisson par morceaux, la Tour
## 6F/7F garde la cuisson d'un bloc (avec la brume et les couches de grotte).
func test_j21_routes_12_and_16_take_the_chunked_path() -> void:
	for map_id: String in ["route_12", "route_16"]:
		var ground := _map(map_id).get_node(^"PaintedGround") as PaintedGround
		assert_false(ground.can_bake(), map_id + " : pas de cuisson d'un bloc")
		assert_true(ground.can_bake_chunks(), map_id)
		ground.bake_chunks()
		assert_true(ground.is_chunked(), map_id + " : cuit par morceaux")


func test_j21_tower_6f_and_7f_take_the_single_bake() -> void:
	for map_id: String in ["pokemon_tower_6f", "pokemon_tower_7f"]:
		var ground := _map(map_id).get_node(^"PaintedGround") as PaintedGround
		assert_true(ground.can_bake(), map_id + " : cuisson d'un bloc")
		assert_false(ground.stack_layers().is_empty(), map_id + " : couches de grotte cuites")
