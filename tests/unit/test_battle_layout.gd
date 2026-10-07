extends GutTest
## BattleLayout (cadrage du pilote, CB.1 : docs/tech/combat-maquettes.md) : ancres à 1920 × 1080
## et 2340 × 1080, loi de taille (taille réelle comprimée et bornée, Salamèche = référence),
## boîtes maximales dans l'écran et hors des zones de l'interface (contrat CB.1 / CB.2 : quart
## haut gauche, bas droit) ; cadrage des 3 placements réels du labo (§14.1).

const VIEWS: Array[Vector2] = [Vector2(1920, 1080), Vector2(2340, 1080)]
## Boîte visible du dos provisoire de Salamèche et de l'artwork officiel de Roucool (px).
const CHARMANDER_BACK := Vector2(48, 56)
const PIDGEY_ARTWORK := Vector2(402, 431)


func test_anchors_follow_the_pilot_framing() -> void:
	var a := BattleLayout.anchors(Vector2(1920, 1080))
	assert_eq(a["player_feet"], Vector2(960 - 0.42 * 1080, 0.90 * 1080).round())
	assert_eq(a["foe_feet"], Vector2(960 + 0.36 * 1080, 0.50 * 1080).round())
	var wide := BattleLayout.anchors(Vector2(2340, 1080))
	assert_eq(wide["player_feet"].y, a["player_feet"].y, "même hauteur")
	assert_eq(wide["foe_feet"] - wide["player_feet"], a["foe_feet"] - a["player_feet"],
		"même composition resserrée, recentrée sur la largeur")
	assert_eq(wide["foe_feet"].x - a["foe_feet"].x, 210.0)


func test_player_in_front_bottom_left_foe_further_top_right() -> void:
	for view: Vector2 in VIEWS:
		var a := BattleLayout.anchors(view)
		var mine: Vector2 = a["player_feet"]
		var foe: Vector2 = a["foe_feet"]
		assert_lt(mine.x, view.x / 2.0, "%s : joueur à gauche" % view)
		assert_gt(foe.x, view.x / 2.0, "%s : adversaire à droite" % view)
		assert_gte(mine.y, view.y * 0.85, "%s : joueur au premier plan, en bas" % view)
		assert_lte(mine.y, view.y * 0.92, "%s : pieds au-dessus du bord bas" % view)
		assert_lte(foe.y, view.y / 2.0, "%s : adversaire dans la moitié haute" % view)


func test_sprite_rect_feet_on_bottom_center() -> void:
	var r := BattleLayout.sprite_rect(Vector2(500, 700), 4.0, Vector2(64, 64))
	assert_eq(r, Rect2(372, 444, 256, 256))


func test_max_boxes_inside_screen_apart_and_off_the_hud_zones() -> void:
	for view: Vector2 in VIEWS:
		var screen := Rect2(Vector2.ZERO, view)
		var mine := BattleLayout.max_rect(true, view)
		var foe := BattleLayout.max_rect(false, view)
		assert_true(screen.encloses(mine), "%s : joueur dans l'écran" % view)
		assert_true(screen.encloses(foe), "%s : adversaire dans l'écran" % view)
		assert_false(mine.intersects(foe), "%s : jamais l'un sur l'autre" % view)
		for zone: Rect2 in BattleLayout.hud_zones(view):
			assert_false(mine.intersects(zone), "%s : joueur hors de %s" % [view, zone])
			assert_false(foe.intersects(zone), "%s : adversaire hors de %s" % [view, zone])


func test_hud_zones_are_top_left_quarter_and_bottom_right() -> void:
	var zones := BattleLayout.hud_zones(Vector2(2340, 1080))
	assert_eq(zones[0], Rect2(0, 0, 1170, 540))
	assert_eq(zones[1], Rect2(1170, 540, 1170, 540))


func test_size_ratio_reference_compressed_and_bounded() -> void:
	assert_almost_eq(BattleLayout.size_ratio(BattleLayout.REFERENCE_HEIGHT_M), 1.0, 0.0001)
	assert_lt(BattleLayout.size_ratio(0.3), 1.0, "Roucool plus petit que Salamèche")
	assert_gt(BattleLayout.size_ratio(0.3), 0.5, "mais comprimé (pas la moitié)")
	assert_gt(BattleLayout.size_ratio(2.0), BattleLayout.size_ratio(1.0), "croissant")
	assert_eq(BattleLayout.size_ratio(8.8), BattleLayout.MAX_RATIO, "Onix borné")
	assert_eq(BattleLayout.size_ratio(0.01), BattleLayout.MIN_RATIO, "minuscule borné")


## Référence du pilote : Salamèche de dos ≈ 60 % du premier essai (0,56 → ≈ 0,336 de haut),
## Roucool de face ≈ 0,21 de haut.
func test_pilot_reference_sizes() -> void:
	var h := 1080.0
	var mine := BattleLayout.sprite_scale(CHARMANDER_BACK, 0.6, true, h, true)
	assert_eq(mine, 6.0, "pixel art net : échelle entière")
	assert_almost_eq(CHARMANDER_BACK.y * mine / h, 0.336, 0.03)
	var foe := BattleLayout.sprite_scale(PIDGEY_ARTWORK, 0.3, false, h)
	assert_almost_eq(PIDGEY_ARTWORK.y * foe / h, 0.21, 0.01)


func test_scale_follows_real_size_and_respects_max_boxes() -> void:
	var h := 1080.0
	var small := BattleLayout.sprite_scale(PIDGEY_ARTWORK, 0.3, false, h)
	var big := BattleLayout.sprite_scale(PIDGEY_ARTWORK, 1.7, false, h)
	assert_gt(big, small, "même image, plus grand Pokémon : plus grand")
	var onix := BattleLayout.sprite_scale(Vector2(411, 431), 8.8, false, h)
	assert_lte(431 * onix, BattleLayout.FOE_MAX_BOX.y * h + 0.01, "Onix tient dans sa boîte")
	var wide := BattleLayout.sprite_scale(Vector2(800, 100), 0.6, true, h)
	assert_lte(800 * wide, BattleLayout.PLAYER_MAX_BOX.x * h + 0.01, "largeur bornée")
	var whole := BattleLayout.sprite_scale(Vector2(60, 64), 8.8, true, h, true)
	assert_eq(whole, floorf(whole), "entière")
	assert_lte(64 * whole, BattleLayout.PLAYER_MAX_BOX.y * h, "entière sans dépasser la boîte")
	assert_eq(BattleLayout.sprite_scale(Vector2.ZERO, 0.6, true, h), 1.0, "boîte vide")


func test_scale_follows_the_view_height() -> void:
	var a := BattleLayout.sprite_scale(PIDGEY_ARTWORK, 0.3, false, 1080.0)
	var b := BattleLayout.sprite_scale(PIDGEY_ARTWORK, 0.3, false, 540.0)
	assert_almost_eq(b, a / 2.0, 0.0001)


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
	assert_between(wide.x, 1536 - half_w - 0.5, half_w + 0.5,
		"labo plus étroit que la vue : entier (à l'arrondi près)")
	# Arène d'une case plus à l'est : sa place libre tient dans la fenêtre, elle la garde.
	var east := Rect2(672, 480, 384, 288)
	assert_eq(BattleLayout.arena_focus(east, lab, Vector2(2340, 1080), 1.4).x,
		BattleLayout.arena_focus(east, Rect2(), Vector2(2340, 1080), 1.4).x,
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


## Sans arène (dresseur sur une route, sauvage) : la vue reste aussi dans la carte (CB.1, zoom
## plus fort : sans borne, un combat près du bord montrait le vide).
func test_clamp_focus_keeps_the_view_inside_the_map() -> void:
	var view := Vector2(2340, 1080)
	var map := Rect2(0, 0, 4800, 2400)
	var near_edge := BattleLayout.clamp_focus(Vector2(4750, 100), map, view, 1.9)
	assert_almost_eq(near_edge.x, 4800 - 2340 / 3.8, 1.0, "bord droit")
	assert_almost_eq(near_edge.y, 1080 / 3.8, 1.0, "bord haut")
	assert_eq(BattleLayout.clamp_focus(Vector2(2000.4, 1200), map, view, 1.9), Vector2(2000, 1200))
	assert_eq(BattleLayout.clamp_focus(Vector2(-50.4, 9.6), Rect2(), view, 1.9), Vector2(-50, 10),
		"sans carte : arrondi seulement")
