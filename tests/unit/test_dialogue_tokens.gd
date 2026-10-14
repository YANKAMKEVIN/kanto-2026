extends GutTest
## DialogueTokens (jalon-07.md §3.6, T18) : jetons « {nom} » des dialogues, page omise quand un
## jeton n'a pas de valeur (dossier 09 §19 : « aucune → la réplique est omise »).

const LINE := "Un {first_wild_species}… Tu n'as pas perdu de temps."


func _values(species: String = "") -> Dictionary[StringName, String]:
	var values: Dictionary[StringName, String] = {}
	if not species.is_empty():
		values[DialogueTokens.FIRST_WILD_SPECIES] = species
	return values


func _pages(texts: Array[String]) -> Array[DialoguePage]:
	var pages: Array[DialoguePage] = []
	for text: String in texts:
		pages.append(DialoguePage.new(text))
	return pages


func test_known_tokens() -> void:
	assert_eq(DialogueTokens.FIRST_WILD_SPECIES, &"first_wild_species")
	assert_eq(DialogueTokens.KNOWN, [&"first_wild_species", &"player", &"rival", &"pokemon"]
		as Array[StringName], "prénoms (OUV.2, dossier 13 §3.5) ; compagnon (J11, dossier 14 §13)")
	assert_eq(DialogueTokens.values_for(&"", null, "", "", "Salamèche"),
		{&"pokemon": "Salamèche"} as Dictionary[StringName, String])


func test_tokens_in() -> void:
	assert_eq(DialogueTokens.tokens_in(LINE), [&"first_wild_species"] as Array[StringName])
	assert_eq(DialogueTokens.tokens_in("Rien ici."), [] as Array[StringName])
	assert_eq(DialogueTokens.tokens_in("{a} et {b_c} puis {a}"),
		[&"a", &"b_c", &"a"] as Array[StringName], "ordre, doublons compris")
	assert_eq(DialogueTokens.tokens_in("{Bad} {} { x} {ok}"), [&"ok"] as Array[StringName],
		"seuls les noms [a-z_]+")
	assert_eq(DialogueTokens.tokens_in("{ouvert"), [] as Array[StringName])


func test_is_well_formed() -> void:
	assert_true(DialogueTokens.is_well_formed(LINE))
	assert_true(DialogueTokens.is_well_formed("Sans jeton."))
	for bad: String in ["{", "}", "a { b", "{}", "{Majuscule}", "{deux mots}", "x}{y",
			"{first_wild_species"]:
		assert_false(DialogueTokens.is_well_formed(bad), bad)


func test_resolve_with_a_value() -> void:
	assert_eq(DialogueTokens.resolve(LINE, _values("Roucool")),
		"Un Roucool… Tu n'as pas perdu de temps.")
	assert_eq(DialogueTokens.resolve("{first_wild_species}, {first_wild_species} !",
		_values("Rattata")), "Rattata, Rattata !", "chaque occurrence")


func test_resolve_without_a_value_gives_an_empty_text() -> void:
	assert_eq(DialogueTokens.resolve(LINE, _values()), "", "aucune valeur : page omise")
	var empty: Dictionary[StringName, String] = {DialogueTokens.FIRST_WILD_SPECIES: ""}
	assert_eq(DialogueTokens.resolve(LINE, empty), "", "valeur vide = pas de valeur")


func test_resolve_without_token_keeps_the_text() -> void:
	assert_eq(DialogueTokens.resolve("Tiens…", _values()), "Tiens…")
	assert_eq(DialogueTokens.resolve("Tiens…", _values("Roucool")), "Tiens…")


func test_resolve_pages_omits_the_page_whose_token_has_no_value() -> void:
	var pages := _pages(["Tiens…", LINE, "Ton voyage peut nous apprendre beaucoup."])
	var without := DialogueTokens.resolve_pages(pages, _values())
	assert_eq(without.size(), 2)
	assert_eq(without[0].text, "Tiens…")
	assert_eq(without[1].text, "Ton voyage peut nous apprendre beaucoup.")
	var with := DialogueTokens.resolve_pages(pages, _values("Roucool"))
	assert_eq(with.size(), 3)
	assert_eq(with[1].text, "Un Roucool… Tu n'as pas perdu de temps.")
	assert_same(with[0], pages[0], "une page sans jeton n'est pas copiée")
	assert_eq(pages[1].text, LINE, "la page des données n'est jamais modifiée")


func test_resolve_pages_keeps_the_staging_of_a_resolved_page() -> void:
	var page := DialoguePage.new(LINE)
	page.speaker = "Prof. Chen"
	page.pause = 0.5
	page.face_player = true
	page.react = &"pidgey"
	page.turn = {&"oak": &"player"}
	var pages: Array[DialoguePage] = [page]
	var resolved := DialogueTokens.resolve_pages(pages, _values("Roucool"))
	assert_eq(resolved.size(), 1)
	assert_ne(resolved[0], page, "copie")
	assert_eq(resolved[0].speaker, "Prof. Chen")
	assert_eq(resolved[0].pause, 0.5)
	assert_true(resolved[0].face_player)
	assert_eq(resolved[0].react, &"pidgey")
	assert_eq(resolved[0].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])
	resolved[0].turn[&"rival"] = &"down"
	assert_eq(page.turn.size(), 1, "turn copié, pas partagé")


func test_resolve_pages_without_any_token_returns_the_same_array() -> void:
	var pages := _pages(["Tiens…", "Bonjour."])
	assert_same(DialogueTokens.resolve_pages(pages, _values()), pages, "aucune copie")
	assert_false(DialogueTokens.has_tokens(pages))
	assert_true(DialogueTokens.has_tokens(_pages(["a", LINE])))


func test_values_for_the_first_wild_species() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir(), "données Pokémon")
	assert_eq(DialogueTokens.values_for(&"pidgey", data),
		{&"first_wild_species": "Roucool"} as Dictionary[StringName, String])
	assert_eq(DialogueTokens.values_for(&"rattata", data)[DialogueTokens.FIRST_WILD_SPECIES],
		"Rattata")
	assert_true(DialogueTokens.values_for(&"", data).is_empty(), "aucune rencontre")
	assert_true(DialogueTokens.values_for(&"missingno", data).is_empty(), "espèce inconnue")
	assert_true(DialogueTokens.values_for(&"pidgey", null).is_empty(), "sans données")


## La vraie réplique de Chen (data/dialogues/oak_lab.json), avec la première espèce de la
## partie de Kevin (Roucool, T1) puis sans rencontre sauvage.
func test_chen_line_from_the_real_data() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := DialogueLibrary.new()
	assert_true(library.load_dir(), str(library.get_errors()))
	var pages := library.get_dialogue(&"oak_parcel_records").variants[0].pages
	var kevin := DialogueTokens.resolve_pages(pages, DialogueTokens.values_for(&"pidgey", data))
	assert_eq(kevin.size(), pages.size())
	assert_eq(kevin[2].text, "Un Roucool… Tu n'as pas perdu de temps.")
	var none := DialogueTokens.resolve_pages(pages, DialogueTokens.values_for(&"", data))
	assert_eq(none.size(), pages.size() - 1, "réplique omise")
	for page: DialoguePage in none:
		assert_false(page.text.contains("{"), page.text)


# --- Prénoms du joueur et du rival (OUV.2, dossier 13 §3.5) ----------------------------------

func _names() -> Dictionary[StringName, String]:
	return DialogueTokens.values_for(&"", null, "Sacha", "Régis")


func test_values_for_carry_the_two_names() -> void:
	assert_eq(_names(), {&"player": "Sacha", &"rival": "Régis"} as Dictionary[StringName, String])
	assert_true(DialogueTokens.values_for(&"", null, "", "").is_empty(), "prénom vide : rien")
	var data := PokemonData.new()
	data.load_dir()
	var all := DialogueTokens.values_for(&"pidgey", data, "Red", "Blue")
	assert_eq(all.size(), 3)
	assert_eq(all[DialogueTokens.RIVAL], "Blue")


func test_resolve_speaker() -> void:
	assert_eq(DialogueTokens.resolve_speaker("{rival}", _names()), "Régis")
	assert_eq(DialogueTokens.resolve_speaker("Prof. Chen", _names()), "Prof. Chen")
	assert_eq(DialogueTokens.resolve_speaker("{rival}", _values()), "",
		"sans valeur : étiquette cachée")


func test_resolve_pages_resolves_the_speaker_and_keeps_the_page() -> void:
	var page := DialoguePage.new("Hé ! Attends-moi !")
	page.speaker = "{rival}"
	var pages: Array[DialoguePage] = [page]
	assert_true(DialogueTokens.has_tokens(pages), "un locuteur à jeton compte")
	var resolved := DialogueTokens.resolve_pages(pages, _names())
	assert_eq(resolved.size(), 1)
	assert_eq(resolved[0].speaker, "Régis")
	assert_eq(resolved[0].text, "Hé ! Attends-moi !")
	assert_eq(page.speaker, "{rival}", "la page des données n'est jamais modifiée")
	var unnamed := DialogueTokens.resolve_pages(pages, _values())
	assert_eq(unnamed.size(), 1, "un locuteur sans valeur n'omet pas la page")
	assert_eq(unnamed[0].speaker, "")
