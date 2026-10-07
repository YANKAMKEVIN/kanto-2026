extends GutTest
## CB.2 : cartes de PV sur la diagonale opposée aux Pokémon (adversaire en haut à gauche, joueur
## en bas à droite au-dessus des commandes), contrat avec le cadrage du pilote (rien dans la
## moitié haute droite, rien dans le quart bas gauche sauf « ‹ »), icônes de types.

const VIEWS: Array[Vector2] = [Vector2(1920, 1080), Vector2(2340, 1080)]
## Les pastilles (décor, non interactives) peuvent dépasser la mi-hauteur de cette marge.
const PIPS_TOLERANCE := 24.0


func test_foe_card_top_left_own_card_bottom_right() -> void:
	for view: Vector2 in VIEWS:
		var foe := BattleHudLayout.rect(BattleHudLayout.Slot.FOE_CARD, view)
		var own := BattleHudLayout.rect(BattleHudLayout.Slot.OWN_CARD, view)
		assert_eq(foe.position, Vector2(UiTokens.BATTLE_EDGE, UiTokens.BATTLE_FOE_CARD_TOP))
		assert_eq(own.end, view - Vector2.ONE * UiTokens.BATTLE_EDGE
			- Vector2(0, UiTokens.BATTLE_OWN_CARD_BOTTOM - UiTokens.BATTLE_EDGE))


func test_own_card_and_pips_stack_above_the_commands() -> void:
	for view: Vector2 in VIEWS:
		var own := BattleHudLayout.rect(BattleHudLayout.Slot.OWN_CARD, view)
		var pips := BattleHudLayout.rect(BattleHudLayout.Slot.PARTY_PIPS, view)
		for slot: BattleHudLayout.Slot in [BattleHudLayout.Slot.ACTIONS,
				BattleHudLayout.Slot.MOVES, BattleHudLayout.Slot.MESSAGE]:
			var zone := BattleHudLayout.rect(slot, view)
			assert_lte(own.end.y, zone.position.y + 1.0, "%s sous la carte joueur" % slot)
		assert_lt(pips.end.y, own.position.y, "pastilles au-dessus de la carte")
		assert_gte(pips.position.x, own.position.x, "alignées à gauche de la carte")
		assert_lte(pips.end.x, own.end.x)


func test_nothing_in_the_upper_right_half_nor_the_lower_left_quarter() -> void:
	for view: Vector2 in VIEWS:
		var upper_right := Rect2(view.x * 0.5, 0, view.x * 0.5, view.y * 0.5 - PIPS_TOLERANCE)
		var lower_left := Rect2(0, view.y * 0.5, view.x * 0.5, view.y * 0.5)
		for slot: BattleHudLayout.Slot in [BattleHudLayout.Slot.FOE_CARD,
				BattleHudLayout.Slot.OWN_CARD, BattleHudLayout.Slot.PARTY_PIPS,
				BattleHudLayout.Slot.ACTIONS, BattleHudLayout.Slot.MOVES,
				BattleHudLayout.Slot.MESSAGE]:
			var rect := BattleHudLayout.rect(slot, view)
			assert_false(rect.intersects(upper_right), "%s : moitié haute droite" % slot)
			if slot != BattleHudLayout.Slot.MOVES and slot != BattleHudLayout.Slot.MESSAGE:
				assert_false(rect.intersects(lower_left), "%s : bas gauche" % slot)
		# Le seul élément du quart bas gauche est « ‹ ».
		var back := BattleHudLayout.rect(BattleHudLayout.Slot.BACK, view)
		assert_true(lower_left.intersects(back))


func test_bag_is_narrower_than_the_party_panel() -> void:
	assert_lt(BattleHudLayout.bag_size().x, BattleHudLayout.party_size().x)
	assert_eq(BattleHudLayout.bag_size().x, float(UiTokens.BATTLE_BAG_WIDTH))


func test_type_icons_for_the_pilot_types() -> void:
	for type_id: StringName in [&"electric", &"flying", &"fighting", &"psychic", &"bug",
			&"ground", &"rock", &"ghost", &"ice"]:
		assert_true(TypeBadge.ICONS.has(type_id), String(type_id))
