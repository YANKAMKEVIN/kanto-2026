extends GutTest
## Cartes d'information de combat (QA 23E) : le nom français de chaque espèce des données tient
## en entier dans la carte adverse et dans celle du joueur, au pire cas (♀, « PSN+ », Nv. 100,
## PV chiffrés), sans élargir la carte au-delà de BATTLE_CARD_WIDTH. Le nom affiché est bien le
## nom français complet (« HYPNOMADE », pas « HYPNO »).

const CARD_SCENE := "res://game/ui/battle/battle_info_card.tscn"

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon chargées")


func _card() -> BattleInfoCard:
	var card := (load(CARD_SCENE) as PackedScene).instantiate() as BattleInfoCard
	card.haptics_enabled = false
	add_child_autofree(card)
	return card


## Vue la plus large possible pour [param name] : ♀, poison grave, Nv. 100, 999 / 999.
func _worst_view(name: String, own: bool) -> BattleCardView:
	var view := BattleCardView.new(name, BattleCardView.Gender.FEMALE, 100, 999, 999, own)
	view.status = StatusRules.TOXIC
	return view


func _name_label(card: BattleInfoCard) -> Label:
	return card.find_child("NameLabel", true, false) as Label


func test_hypno_shows_its_full_french_name() -> void:
	assert_eq(_data.get_species(&"hypno").name, "Hypnomade")
	var card := _card()
	card.set_view(_worst_view(_data.get_species(&"hypno").name, false))
	assert_eq(_name_label(card).text, "HYPNOMADE")


func test_short_name_keeps_theme_size_and_long_name_shrinks_without_trimming() -> void:
	var card := _card()
	card.set_view(BattleCardView.new("Abo", BattleCardView.Gender.MALE, 20, 30, 30, false))
	assert_eq(card.get_name_font_size(), UiTokens.BATTLE_CARD_NAME_FONT,
		"nom court : taille normale")
	card.set_view(_worst_view("Grotadmorv", false))
	assert_lt(card.get_name_font_size(), UiTokens.BATTLE_CARD_NAME_FONT, "nom long : plus petit")
	assert_true(card.get_name_font_size() >= UiTokens.BATTLE_CARD_NAME_FONT_MIN, "plancher")
	assert_eq(card.get_name_text(), "GROTADMORV")
	# Le statut retiré, le nom reprend de la place.
	card.set_status(StatusRules.NONE)
	var without := card.get_name_font_size()
	card.set_status(StatusRules.TOXIC)
	assert_true(without >= card.get_name_font_size(), "sans statut, au moins aussi grand")
	assert_true(card.get_combined_minimum_size().x <= float(UiTokens.BATTLE_CARD_WIDTH))


func test_every_species_name_fits_both_cards() -> void:
	var smallest := UiTokens.BATTLE_CARD_NAME_FONT
	var smallest_name := ""
	for own: bool in [false, true]:
		var card := _card()
		var label := _name_label(card)
		for id: StringName in _data.get_species_ids():
			var name := _data.get_species(id).name
			card.set_view(_worst_view(name, own))
			var needed := card.get_combined_minimum_size().x
			if card.get_name_font_size() < smallest:
				smallest = card.get_name_font_size()
				smallest_name = name
			assert_true(needed <= float(UiTokens.BATTLE_CARD_WIDTH),
				"%s (%s) : %.0f px pour une carte de %d px" % [name,
					"joueur" if own else "adversaire", needed, UiTokens.BATTLE_CARD_WIDTH])
			assert_eq(label.text, name.to_upper(), "%s : nom entier" % name)
			assert_eq(label.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING,
				"%s : jamais rogné" % name)
	gut.p("Pire cas : %s en %d px (thème %d)" % [smallest_name, smallest,
		UiTokens.BATTLE_CARD_NAME_FONT])
