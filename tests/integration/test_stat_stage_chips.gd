extends GutTest
## Puces des crans de statistiques sur les cartes de combat (« ATT ▲2 », « DÉF ▼1 ») : posées au
## changement, retirées au retour à zéro et au rappel, hors du cadre de la carte (sa taille ne
## change pas), flèche vers le haut ou vers le bas.

const CARD_SCENE := "res://game/ui/battle/battle_info_card.tscn"
const HUD_SCENE := "res://game/ui/battle/battle_hud.tscn"


func _card() -> BattleInfoCard:
	var card := (load(CARD_SCENE) as PackedScene).instantiate() as BattleInfoCard
	card.haptics_enabled = false
	card.speed_scale = 0.0
	add_child_autofree(card)
	card.set_view(BattleCardView.new("Salamèche", BattleCardView.Gender.MALE, 5, 19, 19, true))
	card.slide_in()
	return card


func test_a_raise_and_a_drop_show_their_chip() -> void:
	var card := _card()
	assert_eq(card.get_stat_chip_count(), 0, "aucune puce au départ")
	card.set_stat_stage(&"atk", "ATT", 2)
	card.set_stat_stage(&"def", "DÉF", -1)
	assert_eq(card.get_stat_chip_count(), 2)
	assert_eq(card.get_stat_chip(&"atk").get_text(), "ATT +2")
	assert_true(card.get_stat_chip(&"atk").is_up(), "hausse : flèche vers le haut")
	assert_eq(card.get_stat_chip(&"def").get_text(), "DÉF -1")
	assert_false(card.get_stat_chip(&"def").is_up(), "baisse : flèche vers le bas")
	assert_eq(card.get_stat_stage(&"spe"), 0)


func test_a_chip_follows_its_stage_and_leaves_at_zero() -> void:
	var card := _card()
	card.set_stat_stage(&"atk", "ATT", 1)
	card.set_stat_stage(&"atk", "ATT", 3)
	assert_eq(card.get_stat_chip_count(), 1, "une seule puce par statistique")
	assert_eq(card.get_stat_stage(&"atk"), 3)
	card.set_stat_stage(&"atk", "ATT", 0)
	assert_eq(card.get_stat_chip_count(), 0, "retour à zéro : la puce part")
	assert_null(card.get_stat_chip(&"atk"))
	card.set_stat_stage(&"spe", "VIT", 0)
	assert_eq(card.get_stat_chip_count(), 0, "zéro sans puce : rien")


func test_clear_removes_every_chip() -> void:
	var card := _card()
	card.set_stat_stage(&"atk", "ATT", 2)
	card.set_stat_stage(&"acc", "PRÉC", -2)
	card.clear_stat_stages()
	assert_eq(card.get_stat_chip_count(), 0)
	assert_eq(card.get_stat_chips().get_child_count(), 0)


func test_chips_never_resize_the_card_and_sit_outside_its_frame() -> void:
	var card := _card()
	var before := card.get_combined_minimum_size()
	for stat: StringName in [&"atk", &"def", &"spa", &"spd", &"spe", &"acc", &"eva"]:
		card.set_stat_stage(stat, "DÉF. SPÉ", -6)
	await wait_process_frames(3)
	assert_eq(card.get_combined_minimum_size(), before, "la carte garde sa taille")
	var frame := card.get_body().get_global_rect()
	var chips := card.get_stat_chips().get_global_rect()
	assert_gt(chips.size.y, 0.0)
	assert_gte(chips.position.y, frame.end.y, "sous le cadre (carte adverse, par défaut)")
	assert_almost_eq(chips.end.x, frame.end.x, 0.5, "alignées au bord droit de la carte")
	assert_almost_eq(chips.size.x, BattleInfoCard.stat_chips_width(), 0.5)
	card.chips_above = true
	await wait_process_frames(3)
	chips = card.get_stat_chips().get_global_rect()
	assert_lte(chips.end.y, frame.position.y, "au-dessus du cadre (carte du joueur)")


func test_hud_puts_the_player_chips_above_and_the_foe_chips_below() -> void:
	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as BattleHud
	add_child_autofree(hud)
	hud.haptics_enabled = false
	hud.speed_scale = 0.0
	assert_true(hud.get_card(BattleHud.Side.PLAYER).chips_above)
	assert_false(hud.get_card(BattleHud.Side.FOE).chips_above)
	hud.set_stat_stage(BattleHud.Side.FOE, &"atk", "ATT", -1)
	assert_eq(hud.get_card(BattleHud.Side.FOE).get_stat_stage(&"atk"), -1)
	assert_eq(hud.get_card(BattleHud.Side.PLAYER).get_stat_chip_count(), 0)
	hud.clear_stat_stages(BattleHud.Side.FOE)
	assert_eq(hud.get_card(BattleHud.Side.FOE).get_stat_chip_count(), 0)


func test_the_chips_leave_the_pips_their_room() -> void:
	# Bande des pastilles : retrait, six pastilles, une marge, puis les puces jusqu'au bord droit.
	var pips := BattleHudLayout.pips_size().x
	assert_almost_eq(UiTokens.PARTY_PIPS_INSET + pips + UiTokens.STAT_CHIPS_MARGIN
		+ BattleInfoCard.stat_chips_width(), float(UiTokens.BATTLE_CARD_WIDTH), 0.01)
	assert_gt(BattleInfoCard.stat_chips_width(), 200.0, "deux puces courtes par ligne")
