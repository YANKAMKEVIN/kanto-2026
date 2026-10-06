extends GutTest
## Case de la grille du Pokédex (refonte T2) : carré de 128 px, image = région de l'atlas,
## silhouette muette pour une case inconnue, Poké Ball seulement si capturée, aucun nom dessiné.

const SEEN := PokedexQuery.State.SEEN
const CAUGHT := PokedexQuery.State.CAUGHT


func _slot(view: PokedexSlotView) -> PokedexSlot:
	var slot := PokedexSlot.new()
	add_child_autofree(slot)
	slot.set_view(view)
	return slot


func _seen(number: int = 74) -> PokedexSlotView:
	return PokedexSlotView.new(number, &"geodude", "Racaillou", SEEN)


func _caught() -> PokedexSlotView:
	return PokedexSlotView.new(4, &"charmander", "Salamèche", CAUGHT)


func test_cell_is_128_square_and_touchable() -> void:
	var slot := _slot(_caught())
	await wait_frames(2)
	assert_eq(slot.custom_minimum_size, Vector2(128, 128))
	assert_gte(slot.size.x, UiTokens.TOUCH_MIN - 0.5)
	assert_gte(slot.size.y, UiTokens.TOUCH_MIN - 0.5)


func test_unknown_cell_is_a_muted_silhouette_of_the_same_thumbnail() -> void:
	var slot := _slot(PokedexSlotView.new(95))
	assert_true(slot.has_silhouette())
	assert_true(slot.has_image())
	assert_eq(slot.get_image().material, PokedexArt.silhouette_material())
	var texture := slot.get_image().texture as AtlasTexture
	assert_eq(texture.region, PokedexArt.thumb_region(95))
	assert_eq(slot.get_texts(), PackedStringArray(["095"]), "numéro seul")
	assert_false(slot.has_ball())
	assert_eq(slot.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(slot.theme_type_variation, &"DexCellUnknown")


func test_unknown_cell_never_reveals_species_or_name() -> void:
	var view := PokedexSlotView.new(95, &"onix", "Onix", PokedexQuery.State.UNKNOWN)
	var slot := _slot(view)
	assert_eq(view.species_id, &"")
	assert_false("Onix" in slot.get_texts())
	assert_false("???" in slot.get_texts(), "pas de libellé sur la case")


func test_seen_cell_shows_plain_art_and_no_ball() -> void:
	var slot := _slot(_seen())
	assert_true(slot.has_image())
	assert_false(slot.has_silhouette())
	assert_null(slot.get_image().material)
	assert_eq((slot.get_image().texture as AtlasTexture).region, PokedexArt.thumb_region(74))
	assert_false(slot.has_ball())
	assert_eq(slot.mouse_filter, Control.MOUSE_FILTER_PASS)
	assert_eq(slot.theme_type_variation, &"DexCell")


func test_caught_cell_has_the_ball_and_no_status_text() -> void:
	var slot := _slot(_caught())
	assert_true(slot.has_ball())
	for text: String in slot.get_texts():
		assert_false(text in ["Vu", "Capturé"], "plus de libellé d'état dans la case")


func test_reusing_a_cell_swaps_silhouette_and_art() -> void:
	var slot := _slot(PokedexSlotView.new(88))
	assert_true(slot.has_silhouette())
	slot.set_view(_seen(88))
	assert_false(slot.has_silhouette())
	assert_null(slot.get_image().material)
	slot.set_view(null)
	assert_false(slot.visible)


func test_tap_on_known_cell_emits_once_and_selection_changes_variation() -> void:
	var slot := _slot(_caught())
	slot.set_selected(true)
	assert_eq(slot.theme_type_variation, &"DexCellSelected")
	slot.set_selected(false)
	assert_eq(slot.theme_type_variation, &"DexCell")


func test_unknown_cell_cannot_stay_selected() -> void:
	var slot := _slot(_caught())
	slot.set_selected(true)
	slot.set_view(PokedexSlotView.new(4))
	assert_false(slot.is_selected())


func test_theme_has_the_three_cell_variations() -> void:
	var theme := load("res://game/ui/theme/ui_theme.tres") as Theme
	for variation: StringName in [&"DexCell", &"DexCellSelected", &"DexCellUnknown"]:
		assert_true(theme.has_stylebox(&"panel", variation), String(variation))
	var selected := theme.get_stylebox(&"panel", &"DexCellSelected") as StyleBoxFlat
	assert_eq(selected.border_color, UiTokens.ACCENT)
	var normal := theme.get_stylebox(&"panel", &"DexCell") as StyleBoxFlat
	assert_eq(normal.bg_color, UiTokens.DEX_CELL_BG)
