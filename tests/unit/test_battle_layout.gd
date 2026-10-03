extends GutTest
## BattleLayout (jalon-04.md §14.4, §14.11 T6) : ancres et échelles des sprites de combat à
## 1920 × 1080 et 2340 × 1080 ; sprites dans l'écran, sans chevauchement avec les
## emplacements de l'interface de combat (BattleHudLayout) ; cadrage des 3 placements réels
## du labo (§14.1).

const VIEWS: Array[Vector2] = [Vector2(1920, 1080), Vector2(2340, 1080)]
const HUD_SLOTS: Array[BattleHudLayout.Slot] = [
	BattleHudLayout.Slot.FOE_CARD, BattleHudLayout.Slot.OWN_CARD,
	BattleHudLayout.Slot.PARTY_PIPS, BattleHudLayout.Slot.BACK,
	BattleHudLayout.Slot.ACTIONS, BattleHudLayout.Slot.MOVES, BattleHudLayout.Slot.MESSAGE,
]


func _rects(view: Vector2) -> Dictionary[String, Rect2]:
	var a := BattleLayout.anchors(view)
	return {
		"joueur": BattleLayout.sprite_rect(a["player_feet"], a["player_scale"],
			BattleLayout.NATIVE),
		"adversaire": BattleLayout.sprite_rect(a["foe_feet"], a["foe_scale"],
			BattleLayout.NATIVE),
	}


func test_anchors_and_scales() -> void:
	var a := BattleLayout.anchors(Vector2(1920, 1080))
	assert_eq(a["player_scale"], 4, "de dos ×4 (256 px)")
	assert_eq(a["foe_scale"], 3, "de face ×3 (192 px)")
	assert_eq(a["player_feet"], Vector2(960 - 0.30 * 1080, 0.63 * 1080).round())
	assert_eq(a["foe_feet"], Vector2(960 + 0.24 * 1080, 0.47 * 1080).round())
	var wide := BattleLayout.anchors(Vector2(2340, 1080))
	assert_eq(wide["player_feet"].y, a["player_feet"].y, "même hauteur")
	assert_eq(wide["foe_feet"] - wide["player_feet"], a["foe_feet"] - a["player_feet"],
		"même composition resserrée, recentrée sur la largeur")
	assert_eq(wide["foe_feet"].x - a["foe_feet"].x, 210.0)


func test_player_in_front_bottom_left_foe_further_center_right() -> void:
	for view: Vector2 in VIEWS:
		var a := BattleLayout.anchors(view)
		var mine: Vector2 = a["player_feet"]
		var foe: Vector2 = a["foe_feet"]
		assert_lt(mine.x, view.x / 2.0, "%s : joueur à gauche" % view)
		assert_gt(foe.x, view.x / 2.0, "%s : adversaire à droite" % view)
		assert_gt(mine.y, foe.y, "%s : joueur plus bas (plus près)" % view)


func test_sprite_rect_feet_on_bottom_center() -> void:
	var r := BattleLayout.sprite_rect(Vector2(500, 700), 4, Vector2i(64, 64))
	assert_eq(r, Rect2(372, 444, 256, 256))


func test_sprites_inside_screen_and_apart() -> void:
	for view: Vector2 in VIEWS:
		var rects := _rects(view)
		var screen := Rect2(Vector2.ZERO, view)
		for key: String in rects:
			assert_true(screen.encloses(rects[key]), "%s : %s dans l'écran" % [view, key])
		assert_false(rects["joueur"].intersects(rects["adversaire"]),
			"%s : les deux sprites ne se chevauchent pas" % view)


func test_sprites_never_overlap_the_battle_hud() -> void:
	for view: Vector2 in VIEWS:
		var rects := _rects(view)
		for slot: BattleHudLayout.Slot in HUD_SLOTS:
			var hud := BattleHudLayout.rect(slot, view)
			for key: String in rects:
				assert_false(rects[key].intersects(hud), "%s : %s sur %s %s" % [
					view, key, BattleHudLayout.Slot.find_key(slot), hud])


## Cadrage : milieu des cases des combattants et des dresseurs, remonté d'une demi-case.
## Placements réels de la fin de la scène starter_chosen (§14.1) : rival (7, 7), son
## Pokémon (8, 7), puis le joueur et son starter.
func test_focus_for_the_three_real_placements() -> void:
	var rival: Array[Vector2i] = [Vector2i(7, 7), Vector2i(8, 7)]
	var cases: Array = [
		[[Vector2i(10, 7), Vector2i(11, 6)], Vector2(912, 624)],   # Bulbizarre
		[[Vector2i(11, 7), Vector2i(10, 7)], Vector2(912, 672)],   # Salamèche
		[[Vector2i(12, 6), Vector2i(13, 6)], Vector2(1008, 624)],  # Carapuce
	]
	for case: Array in cases:
		var cells: Array[Vector2i] = rival.duplicate()
		for cell: Vector2i in case[0]:
			cells.append(cell)
		assert_eq(BattleLayout.focus(cells), case[1], str(case[0]))


func test_focus_of_one_cell_is_its_center_raised() -> void:
	var cells: Array[Vector2i] = [Vector2i(2, 3)]
	assert_eq(BattleLayout.focus(cells), Vector2(2 * 96 + 48, 3 * 96 + 48 - 48))
	assert_eq(BattleLayout.focus([] as Array[Vector2i]), Vector2.ZERO)


## Avec une arène (tapis du labo, 4 × 3 cases en (6, 5)) : son centre tombe entre les deux
## ancres, près de l'adversaire ; la vue reste dans la carte si elle est assez grande, sinon elle est centrée.
func test_arena_focus_puts_the_arena_between_the_anchors() -> void:
	var arena := Rect2(576, 480, 384, 288)
	for view: Vector2 in VIEWS:
		var zoom := 1.4
		var free := BattleLayout.arena_focus(arena, Rect2(), view, zoom)
		var a := BattleLayout.anchors(view)
		var middle: Vector2 = BattleLayout.arena_screen_point(view)
		var foe: Vector2 = a["foe_feet"]
		assert_lt(middle.distance_to(foe), middle.distance_to(a["player_feet"]),
			"%s : l'adversaire se tient sur l'arène" % view)
		var on_screen := (arena.get_center() - free) * zoom + view / 2.0
		assert_almost_eq(on_screen.x, middle.x, 1.0, "%s : arène entre les ancres" % view)
		assert_almost_eq(on_screen.y, middle.y, 1.0)
	# Labo 16 × 11 : plus étroit que la vue à ×1,4 sur 2340 → entier à l'écran ; en hauteur,
	# borné.
	var lab := Rect2(0, 0, 1536, 1056)
	var wide := BattleLayout.arena_focus(arena, lab, Vector2(2340, 1080), 1.4)
	var half_w := 2340 / 2.8
	assert_between(wide.x, 1536 - half_w, half_w, "labo plus étroit que la vue : entier")
	assert_eq(wide.x, BattleLayout.arena_focus(arena, Rect2(), Vector2(2340, 1080), 1.4).x,
		"l'arène garde sa place quand c'est possible")
	var off := BattleLayout.arena_focus(Rect2(0, 480, 96, 96), lab, Vector2(2340, 1080), 1.4)
	assert_almost_eq(off.x, 1536 - half_w, 1.0, "jamais plus de vide que nécessaire")
	var half_h := 1080 / 2.8
	assert_between(wide.y, half_h, 1056 - half_h, "reste dans le labo en hauteur")
	var tall := BattleLayout.arena_focus(Rect2(0, 900, 96, 96), lab, Vector2(1920, 1080), 1.4)
	assert_almost_eq(tall.y, 1056 - half_h, 1.0, "bornée en bas")


func test_bag_slot_is_left_column_above_back_button() -> void:
	for view: Vector2 in VIEWS:
		var bag := BattleHudLayout.rect(BattleHudLayout.Slot.BAG, view)
		var back := BattleHudLayout.rect(BattleHudLayout.Slot.BACK, view)
		assert_eq(bag.position.x, float(UiTokens.SAFE_MARGIN), "%s : colonne gauche" % view)
		assert_eq(bag.end.y, view.y - UiTokens.SAFE_MARGIN, "%s : bas dans la marge" % view)
		assert_gte(bag.position.y, float(UiTokens.SAFE_MARGIN), "%s : haut dans la marge" % view)
		assert_eq(bag.end.y - back.size.y, back.position.y, "« ‹ » au pied de l'emplacement")


func test_capture_slot_is_centered_and_place_matches_rect() -> void:
	for view: Vector2 in VIEWS:
		var rect := BattleHudLayout.rect(BattleHudLayout.Slot.CAPTURE, view)
		assert_eq(rect.get_center(), view * 0.5, "%s : centrée" % view)
		var control := Control.new()
		add_child_autofree(control)
		control.size = view
		BattleHudLayout.place(control, BattleHudLayout.Slot.CAPTURE)
		assert_eq(control.anchor_left, 0.5)
		assert_eq(control.offset_left, -rect.size.x * 0.5)
		assert_eq(control.offset_right, rect.size.x * 0.5)
		assert_eq(control.grow_vertical, Control.GROW_DIRECTION_BOTH)


func test_party_picker_slot_fits_the_picker_and_stays_in_the_safe_area() -> void:
	var min_width := UiTokens.PICKER_COLUMNS * UiTokens.PICKER_COLUMN_WIDTH \
		+ (UiTokens.PICKER_COLUMNS - 1) * UiTokens.PICKER_GAP + UiTokens.MENU_PANEL_PAD * 2
	for view: Vector2 in VIEWS:
		var rect := BattleHudLayout.rect(BattleHudLayout.Slot.PARTY_PICKER, view)
		assert_gte(rect.size.x, float(min_width), "%s : la largeur minimale du choix" % view)
		assert_eq(rect.position.x, float(UiTokens.SAFE_MARGIN))
		assert_eq(rect.end.y, view.y - UiTokens.SAFE_MARGIN)
		assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN))
		assert_lt(rect.end.x, view.x * 0.7, "ne recouvre pas l'adversaire à droite")
