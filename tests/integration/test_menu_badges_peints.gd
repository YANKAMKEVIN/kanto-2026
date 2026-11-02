extends GutTest
## Chantier « Menu Dresseur peint » (2026-11-01) : badges peints chargés par [MenuArt] (image
## présente) avec repli sur l'emblème SVG teinté (image absente), dans l'emplacement de l'écran
## Dresseur, la frise des grands moments et la ligne des badges du tableau de bord ; icônes
## d'objets repeintes (RP-265) au gabarit des autres.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const BADGE_IDS: Array[StringName] = [&"boulder", &"cascade", &"thunder", &"rainbow", &"soul",
	&"marsh", &"volcano", &"earth"]
const ICON_SIZE := Vector2(256, 256)
## RP-265 et les frères du même flacon repeints avec eux.
const REPAINTED_ITEMS: Array[StringName] = [&"protein", &"iron", &"calcium", &"ether", &"elixir",
	&"repel", &"super_repel", &"max_repel", &"itemfinder", &"exp_all", &"carbos", &"hp_up",
	&"pp_up", &"max_ether", &"max_elixir"]
const MISSING := &"badge_sans_image"


func _slot_view(badge_id: StringName, obtained: bool = true) -> BadgeSlotView:
	var view := BadgeSlotView.new(0)
	view.obtained = obtained
	if obtained:
		view.badge_id = badge_id
		view.name = "Badge Essai"
		view.detail = "Ville — Champion"
	return view


func _slot(view: BadgeSlotView) -> BadgeSlot:
	var slot := BadgeSlot.new()
	add_child_autofree(slot)
	slot.setup(view)
	return slot


func test_every_badge_of_the_data_has_its_painted_image() -> void:
	var badges := BadgeLibrary.new()
	assert_true(badges.load_file())
	assert_eq(badges.ids(), BADGE_IDS, "ordre des arènes")
	for id: StringName in badges.ids():
		var texture := MenuArt.badge_icon(id)
		assert_not_null(texture, "badge peint : %s" % id)
		if texture != null:
			assert_eq(texture.get_size(), ICON_SIZE, String(id))
	assert_not_null(MenuArt.badge_unknown(), "gabarit neutre du badge non obtenu")
	assert_null(MenuArt.badge_icon(&""), "pas d'identifiant : pas d'image")
	assert_null(MenuArt.badge_icon(MenuArt.BADGE_UNKNOWN_ID), "le gabarit n'est pas un badge")
	assert_null(MenuArt.badge_icon(MISSING), "image absente : null (repli de l'écran)")


func test_obtained_slot_shows_the_painted_badge_untinted() -> void:
	var slot := _slot(_slot_view(&"thunder"))
	assert_true(slot.is_painted())
	assert_eq(slot.get_emblem().texture, MenuArt.badge_icon(&"thunder"))
	assert_eq(slot.get_emblem().modulate, Color.WHITE)
	assert_true(slot.is_touchable())


func test_obtained_slot_without_image_falls_back_to_the_tinted_svg() -> void:
	var slot := _slot(_slot_view(MISSING))
	assert_false(slot.is_painted())
	assert_eq(slot.get_emblem().texture, BadgeSlot.EMBLEM)
	assert_eq(slot.get_emblem().modulate, UiTokens.ACCENT)
	assert_eq(slot.get_text(), "Essai", "le nom reste affiché")


func test_muted_slots_share_the_neutral_template() -> void:
	var first := _slot(_slot_view(&"", false))
	var second := _slot(BadgeSlotView.new(5))
	for slot: BadgeSlot in [first, second]:
		assert_true(slot.is_muted())
		assert_true(slot.is_painted())
		assert_eq(slot.get_emblem().texture, MenuArt.badge_unknown())
		assert_eq(slot.get_emblem().modulate, UiTokens.TRAINER_BADGE_UNKNOWN_PAINTED)
		assert_false(slot.is_touchable())


func test_badge_moment_uses_the_painted_badge_with_or_without_zone_preview() -> void:
	for zone: StringName in [&"pewter_city", &""]:
		var view := MomentView.new()
		view.kind = MomentLibrary.BADGE
		view.title = "Badge Roche"
		view.zone_id = zone
		view.badge_id = &"boulder"
		var row := MomentRow.new(view)
		add_child_autofree(row)
		assert_eq(row.get_icon(), MenuArt.badge_icon(&"boulder"), "zone « %s »" % zone)
	var fallback := MomentView.new()
	fallback.kind = MomentLibrary.BADGE
	fallback.title = "Badge"
	fallback.badge_id = MISSING
	var row := MomentRow.new(fallback)
	add_child_autofree(row)
	assert_eq(row.get_icon(), MomentRow.ICONS[MomentLibrary.BADGE], "repli : emblème SVG")


func test_dashboard_badge_line_shows_the_last_obtained_badge() -> void:
	var state: Node = GameStateScript.new()
	state.new_game(7)
	var data := PokemonData.new()
	data.load_dir()
	var zones := ZoneLibrary.new()
	zones.load_file()
	var badges := BadgeLibrary.new()
	badges.load_file()
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	var view := DashboardViews.build(state, data, zones, null, unlocks, badges)
	assert_eq(view.badge_id, &"", "aucun badge")
	state.flags.set_flag(badges.flag(&"thunder"))
	state.flags.set_flag(badges.flag(&"boulder"))
	view = DashboardViews.build(state, data, zones, null, unlocks, badges)
	assert_eq(view.badge_id, &"thunder", "le dernier dans l'ordre des arènes")
	var panel := TrainerCardPanel.new()
	add_child_autofree(panel)
	panel.show_view(view)
	assert_eq(panel.get_badge_icon().texture, MenuArt.badge_icon(&"thunder"))
	assert_eq(panel.get_badge_icon().modulate, Color.WHITE)
	view.badge_id = MISSING
	panel.show_view(view)
	assert_eq(panel.get_badge_icon().texture, TrainerCardPanel.ICON_BADGE, "repli SVG")
	assert_eq(panel.get_badge_icon().modulate, UiTokens.ACCENT)
	state.free()


func test_repainted_item_icons_keep_the_item_template() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	for id: StringName in REPAINTED_ITEMS:
		assert_not_null(items.get_item(id), "objet connu : %s" % id)
		var texture := MenuArt.item_icon(id)
		assert_not_null(texture, String(id))
		if texture != null:
			assert_eq(texture.get_size(), ICON_SIZE, String(id))
