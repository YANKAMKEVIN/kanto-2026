extends GutTest
## MomentLibrary : textes des grands moments de l'écran Dresseur (jalon-06.md §3.7, Q-14).


func _valid() -> Dictionary:
	return {
		"moments": {
			"starter": {"title": "Premier Pokémon", "detail": "{species} arrive."},
			"rival_battle": {"title": "Rival", "detail": "{outcome}"},
			"first_capture": {"title": "Première capture", "detail": "{species} à {zone}."},
			"zone_arrival": {"title": "{zone}"},
		},
		"outcomes": {"win": {"text": "Gagné."}},
		"zone_arrivals": {"route_1": {"title": "Départ", "detail": "Vers la {zone}."}},
	}


func _zones() -> ZoneLibrary:
	var zones := ZoneLibrary.new()
	zones.load_file()
	return zones


# --- Données réelles -----------------------------------------------------------------------

func test_real_data_loads_without_error() -> void:
	var library := MomentLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	assert_true(library.check_references(_zones()), "\n".join(library.get_errors()))
	assert_eq(library.get_errors().size(), 0)
	for type: StringName in MomentLibrary.TYPES:
		assert_not_null(library.get_text(type), "texte de %s" % type)
	assert_true(library.has_drafts(), "textes provisoires, à relire par Kevin")


func test_real_data_q14_route_1_is_the_departure_from_pallet_town() -> void:
	var library := MomentLibrary.new()
	library.load_file()
	assert_eq(library.get_zone_text(&"route_1").title, "Départ de Bourg Palette")
	assert_eq(library.get_zone_text(&"pewter_city"), library.get_text(&"zone_arrival"),
		"sans texte propre : le texte général")
	assert_eq(library.outcome_text(&"win").is_empty(), false)
	assert_eq(library.outcome_text(&"loss").is_empty(), false)
	assert_eq(library.outcome_text(&"fled"), "", "issue inconnue : pas de texte")


func test_real_texts_never_speak_of_the_pokedex() -> void:
	var library := MomentLibrary.new()
	library.load_file()
	var texts: Array[MomentTextData] = []
	for type: StringName in MomentLibrary.TYPES:
		texts.append(library.get_text(type))
	for zone: StringName in library.get_zone_ids():
		texts.append(library.get_zone_text(zone))
	var all := PackedStringArray()
	for text: MomentTextData in texts:
		all.append(text.title)
		all.append(text.detail)
	for outcome: StringName in library.get_outcomes():
		all.append(library.outcome_text(outcome))
	var joined := " ".join(all).to_lower()
	for word: String in ["pokédex", "vus", "capturés", "habitat", "badge"]:
		assert_false(joined.contains(word), "règle de déblocage : « %s »" % word)


# --- Format --------------------------------------------------------------------------------

func test_valid_dictionary() -> void:
	var library := MomentLibrary.new()
	assert_true(library.add_from_dict(_valid(), "t"), "\n".join(library.get_errors()))
	assert_eq(library.get_text(&"starter").title, "Premier Pokémon")
	assert_eq(library.get_text(&"starter").detail, "{species} arrive.")
	assert_false(library.get_text(&"starter").draft)
	assert_eq(library.get_text(&"zone_arrival").detail, "", "détail facultatif")
	assert_eq(library.get_zone_ids(), [&"route_1"] as Array[StringName])
	assert_eq(library.outcome_text(&"win"), "Gagné.")
	assert_false(library.has_drafts())


func test_every_type_is_required() -> void:
	var data := _valid()
	(data["moments"] as Dictionary).erase("rival_battle")
	var library := MomentLibrary.new()
	assert_false(library.add_from_dict(data, "t"))
	assert_string_contains("\n".join(library.get_errors()), "« rival_battle » manquant")
	assert_push_error("manquant")


func test_unknown_keys_and_types_are_errors() -> void:
	var data := _valid()
	data["extra"] = 1
	(data["moments"] as Dictionary)["first_badge"] = {"title": "Badge"}
	(data["moments"]["starter"] as Dictionary)["subtitle"] = "x"
	(data["outcomes"]["win"] as Dictionary)["tone"] = "x"
	var library := MomentLibrary.new()
	assert_false(library.add_from_dict(data, "t"))
	var errors := "\n".join(library.get_errors())
	assert_string_contains(errors, "clé inconnue « extra »")
	assert_string_contains(errors, "type inconnu")
	assert_string_contains(errors, "clé inconnue « subtitle »")
	assert_string_contains(errors, "clé inconnue « tone »")
	assert_null(library.get_text(&"first_badge"))
	assert_null(library.get_text(&"starter"), "entrée invalide écartée")
	assert_eq(library.outcome_text(&"win"), "")
	assert_push_error_count(5, "une erreur par faute, plus le starter manquant")


func test_marks_are_checked_per_type() -> void:
	var data := _valid()
	data["moments"]["rival_battle"]["detail"] = "{species} perd."
	data["moments"]["starter"]["title"] = "{outcome}"
	data["zone_arrivals"]["route_1"]["title"] = "{species}"
	data["outcomes"]["win"]["text"] = "{zone}"
	var library := MomentLibrary.new()
	assert_false(library.add_from_dict(data, "t"))
	var errors := "\n".join(library.get_errors())
	assert_string_contains(errors, "moment « rival_battle » : marque « {species} »")
	assert_string_contains(errors, "moment « starter » : marque « {outcome} »")
	assert_string_contains(errors, "arrivée « route_1 » : marque « {species} »")
	assert_string_contains(errors, "n'accepte aucune marque")
	assert_push_error_count(6, "quatre fautes et deux types manquants")


func test_bad_values() -> void:
	var data := _valid()
	data["moments"]["starter"]["title"] = "  "
	data["moments"]["first_capture"]["detail"] = 3
	data["moments"]["zone_arrival"]["draft"] = "oui"
	var library := MomentLibrary.new()
	assert_false(library.add_from_dict(data, "t"))
	var errors := "\n".join(library.get_errors())
	assert_string_contains(errors, "« title » est un texte non vide")
	assert_string_contains(errors, "« detail » est un texte")
	assert_string_contains(errors, "« draft » vaut true ou false")
	assert_push_error_count(6, "trois fautes et trois types manquants")


func test_zone_arrivals_must_name_known_zones() -> void:
	var data := _valid()
	data["zone_arrivals"]["atlantis"] = {"title": "Atlantide"}
	var library := MomentLibrary.new()
	assert_true(library.add_from_dict(data, "t"))
	assert_false(library.check_references(_zones()))
	assert_string_contains("\n".join(library.get_errors()), "« atlantis » : zone inconnue")
	assert_eq(library.get_zone_ids(), [&"route_1"] as Array[StringName], "écartée")
	assert_push_error("zone inconnue")


func test_missing_or_broken_file() -> void:
	var library := MomentLibrary.new()
	assert_false(library.load_file("res://data/trainer/absent.json"))
	assert_push_error("fichier introuvable")
	var list := MomentLibrary.new()
	assert_false(list.add_from_dict({"moments": []}, "t"))
	assert_push_error("« moments » doit être un objet")
