extends GutTest
## StatusView (jalon 9, T5) : le texte et la couleur du statut dans les vues, sans toucher à la
## logique ([StatusRules]) ; « K.O. » prime, « PSN » seulement debout.

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _pokemon() -> Pokemon:
	return PokemonFactory.create(_data, &"pidgey", 5, GameRng.new(1))


func test_a_healthy_pokemon_has_no_status_text() -> void:
	assert_eq(StatusView.text(_pokemon()), "")


func test_a_poisoned_standing_pokemon_reads_psn() -> void:
	var pokemon := _pokemon()
	pokemon.status = StatusRules.POISON
	assert_eq(StatusView.text(pokemon), "PSN")
	assert_eq(StatusView.text(pokemon), TeamMemberView.STATUS_POISON)


func test_a_fainted_pokemon_reads_ko_even_with_a_stale_status() -> void:
	var pokemon := _pokemon()
	pokemon.status = StatusRules.POISON
	pokemon.hp = 0
	assert_eq(StatusView.text(pokemon), "K.O.")


func test_every_known_status_has_a_label() -> void:
	for status: StringName in StatusRules.KNOWN:
		assert_false(StatusView.text_of(status).is_empty(), "libellé de %s" % status)
		assert_ne(StatusView.badge_type(status), &"", "pastille de %s" % status)
	assert_eq(StatusView.text_of(StatusRules.NONE), "")
	assert_eq(StatusView.text_of(&"inconnu"), "")


func test_colors_follow_the_status() -> void:
	assert_eq(StatusView.color("K.O."), UiTokens.HP_LOW)
	assert_eq(StatusView.color("PSN"), UiTokens.STATUS_POISON_TEXT)
	assert_eq(UiTokens.STATUS_POISON, UiTokens.TYPE_COLORS[&"poison"],
		"la pastille a la couleur du type Poison")


func test_the_poison_text_is_readable_on_the_panels() -> void:
	# Texte courant sur fond de panneau opaque : contraste WCAG ≥ 4,5 : 1.
	var bg := Color(UiTokens.PANEL_BG_STRONG.r, UiTokens.PANEL_BG_STRONG.g,
		UiTokens.PANEL_BG_STRONG.b)
	assert_gte(_contrast(UiTokens.STATUS_POISON_TEXT, bg), 4.5)


func _luminance(color: Color) -> float:
	var channels: Array[float] = []
	for c: float in [color.r, color.g, color.b]:
		channels.append(c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)
