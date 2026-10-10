extends GutTest
## NameRules (dossier 13, A7, §5.5, §7) : normalisation, validation, filtre de saisie.

const MAX := 10


func test_normalize_trims_edges_and_collapses_spaces() -> void:
	assert_eq(NameRules.normalize("  sacha  "), "Sacha")
	assert_eq(NameRules.normalize("jean    luc"), "Jean luc")
	assert_eq(NameRules.normalize("\tmarie\n claire "), "Marie claire")


func test_normalize_turns_unicode_blanks_into_spaces() -> void:
	assert_eq(NameRules.normalize("ana maria"), "Ana maria", "insécable")
	assert_eq(NameRules.normalize("ana  maria"), "Ana maria", "fine + étroite")
	assert_eq(NameRules.normalize("　ren"), "Ren")


func test_normalize_capitalizes_first_letter_only() -> void:
	assert_eq(NameRules.normalize("régis"), "Régis")
	assert_eq(NameRules.normalize("élodie"), "Élodie")
	assert_eq(NameRules.normalize("mcFly"), "McFly", "le reste ne change pas")
	assert_eq(NameRules.normalize("ÉLODIE"), "ÉLODIE", "rien n'est mis en minuscules")
	assert_eq(NameRules.normalize("jean luc"), "Jean luc", "seulement la première lettre")
	assert_eq(NameRules.normalize("жанна"), "Жанна", "autres écritures")


func test_normalize_capitalizes_first_letter_after_punctuation() -> void:
	assert_eq(NameRules.normalize("’ana"), "’Ana")
	assert_eq(NameRules.normalize("-bo"), "-Bo")


func test_normalize_straight_apostrophe_becomes_typographic() -> void:
	assert_eq(NameRules.normalize("d'artagnan"), "D’artagnan")
	assert_eq(NameRules.normalize("o’neil"), "O’neil")


func test_normalize_is_idempotent() -> void:
	for raw: String in ["  jean  luc ", "d'arc", "ÉLODIE", "ana-maria", "x"]:
		var once := NameRules.normalize(raw)
		assert_eq(NameRules.normalize(once), once, raw)


func test_validate_accepts_letters_spaces_hyphens_apostrophes() -> void:
	for name: String in ["Kevin", "Régis", "Jean-Luc", "D’Arc", "D'Arc", "Ana Maria",
			"Zoë", "Çağla", "Łukasz", "Søren", "Jürgen", "ß", "Жанна", "李", "Ἀθηνᾶ"]:
		assert_eq(NameRules.validate(name, MAX), NameRules.Result.OK, name)


func test_validate_accepts_decomposed_accents() -> void:
	# « é » écrit « e » + accent aigu combinant (2 caractères).
	assert_eq(NameRules.validate("René", MAX), NameRules.Result.OK)


func test_validate_refuses_lone_combining_accent() -> void:
	assert_eq(NameRules.validate("́a", MAX), NameRules.Result.INVALID_CHAR)
	assert_eq(NameRules.validate("a-́", MAX), NameRules.Result.INVALID_CHAR)


func test_validate_empty() -> void:
	assert_eq(NameRules.validate("", MAX), NameRules.Result.EMPTY)
	assert_eq(NameRules.validate("    ", MAX), NameRules.Result.EMPTY)
	assert_eq(NameRules.validate(" \t\n", MAX), NameRules.Result.EMPTY)


func test_validate_without_letter_is_empty() -> void:
	assert_eq(NameRules.validate("-", MAX), NameRules.Result.EMPTY)
	assert_eq(NameRules.validate("’ - '", MAX), NameRules.Result.EMPTY)


func test_validate_refuses_digits() -> void:
	assert_eq(NameRules.validate("R2D2", MAX), NameRules.Result.INVALID_CHAR)
	assert_eq(NameRules.validate("Kevin7", MAX), NameRules.Result.INVALID_CHAR)
	assert_eq(NameRules.validate("Ana١", MAX), NameRules.Result.INVALID_CHAR, "chiffre arabe")


func test_validate_refuses_emoji() -> void:
	assert_eq(NameRules.validate("Kev😀", MAX), NameRules.Result.INVALID_CHAR)
	assert_eq(NameRules.validate("🔥", MAX), NameRules.Result.INVALID_CHAR)
	assert_eq(NameRules.validate("Ana❤", MAX), NameRules.Result.INVALID_CHAR)


func test_validate_refuses_other_punctuation_and_symbols() -> void:
	for name: String in ["Ana_B", "Ana.", "Ana!", "Ana?", "A@b", "Ana,Bo", "A/b", "Ana–Bo",
			"<b>", "{player}", "Ana\"", "A#", "A+b", "A$"]:
		assert_eq(NameRules.validate(name, MAX), NameRules.Result.INVALID_CHAR, name)


func test_validate_length_counts_after_normalization() -> void:
	assert_eq(NameRules.validate("Abcdefghij", MAX), NameRules.Result.OK, "10 caractères")
	assert_eq(NameRules.validate("Abcdefghijk", MAX), NameRules.Result.TOO_LONG, "11")
	assert_eq(NameRules.validate("   Abcdefghij   ", MAX), NameRules.Result.OK, "bords")
	assert_eq(NameRules.validate("Abcd     efghi", MAX), NameRules.Result.OK, "espaces réduites")
	assert_eq(NameRules.validate("Élise-Anne", MAX), NameRules.Result.OK, "accents : 1 chacun")


func test_validate_invalid_char_before_length() -> void:
	assert_eq(NameRules.validate("Abcdefghijk1", MAX), NameRules.Result.INVALID_CHAR)


func test_validate_uses_given_max_length() -> void:
	assert_eq(NameRules.validate("Sacha", 4), NameRules.Result.TOO_LONG)
	assert_eq(NameRules.validate("Sacha", 5), NameRules.Result.OK)
	assert_true(NameRules.is_valid("Red", 3))
	assert_false(NameRules.is_valid("Red", 2))


func test_has_invalid_chars() -> void:
	assert_false(NameRules.has_invalid_chars("Jean Luc"))
	assert_false(NameRules.has_invalid_chars("  Jean\tLuc "), "les blancs ne sont pas refusés")
	assert_true(NameRules.has_invalid_chars("Jean2"))
	assert_true(NameRules.has_invalid_chars("😀"))


func test_filter_input_removes_refused_characters() -> void:
	assert_eq(NameRules.filter_input("Ke7vin😀!", MAX), "Kevin")
	assert_eq(NameRules.filter_input("R2-D2", MAX), "R-D")


func test_filter_input_keeps_trailing_space_while_typing() -> void:
	assert_eq(NameRules.filter_input("Jean ", MAX), "Jean ")
	assert_eq(NameRules.filter_input("Jean  ", MAX), "Jean ", "espace double réduite")


func test_filter_input_removes_leading_blanks_and_unifies_blanks() -> void:
	assert_eq(NameRules.filter_input("   Ana", MAX), "Ana")
	assert_eq(NameRules.filter_input("Ana\n\tMaria", MAX), "Ana Maria")
	assert_eq(NameRules.filter_input("Ana Maria", MAX), "Ana Maria")


func test_filter_input_converts_apostrophe_and_keeps_case() -> void:
	assert_eq(NameRules.filter_input("d'arc", MAX), "d’arc")
	assert_eq(NameRules.filter_input("ÉLODIE", MAX), "ÉLODIE")


func test_filter_input_truncates_pasted_text() -> void:
	assert_eq(NameRules.filter_input("Maximilienne", MAX), "Maximilien")
	assert_eq(NameRules.filter_input("12 34 Bob ' é", MAX), "Bob ’ é")


func test_filter_input_of_garbage_is_empty_and_invalid() -> void:
	var filtered := NameRules.filter_input("123 😀😀 !!", MAX)
	assert_eq(filtered, "")
	assert_eq(NameRules.validate(filtered, MAX), NameRules.Result.EMPTY)


func test_filtered_then_normalized_is_always_ok_or_empty() -> void:
	for raw: String in ["  ma  rie ", "x1y2z3", "--", "Ana😀Bo", "d'artagnan-le-grand",
			"  jo", "李小龍", "áb"]:
		var result := NameRules.validate(NameRules.filter_input(raw, MAX), MAX)
		assert_true(result == NameRules.Result.OK or result == NameRules.Result.EMPTY, raw)


func test_lone_combining_accent_is_filtered_out() -> void:
	assert_eq(NameRules.filter_input("́Ana", MAX), "Ana")
	assert_eq(NameRules.filter_input("René", MAX), "René")
