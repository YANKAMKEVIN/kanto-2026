extends GutTest
## PokedexQuery : grille, filtres, recherche et fiche, sans rien révéler (dossier 08 §4 ;
## jalon-06.md §3.5). Inconnu = numéro et « ??? », sans espèce ni image ; vu = sprite, nom,
## habitats ; capturé = types, taille, poids, description. Jamais de statistiques de base.

const State := PokedexQuery.State
const Filter := PokedexQuery.Filter

var _data: PokemonData
var _lib: PokedexLibrary
var _zones: ZoneLibrary
var _dex: Pokedex


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_lib = PokedexLibrary.new()
	_lib.load_file()
	_lib.check_references(_data)
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_dex = Pokedex.new()


## La partie de Kevin à la fin du J5 : Salamèche reçu, Carapuce du rival vu, Roucool capturé
## à Bourg Palette, Rattata vu puis capturé sur la Route 1, Roucool revu sur la Route 1.
func _kevin() -> void:
	_dex.mark_caught(&"charmander", &"oak_lab", "2026-09-30T10:00:00")
	_dex.mark_seen(&"squirtle", &"oak_lab", "2026-09-30T10:05:00")
	_dex.mark_seen(&"pidgey", &"pallet_town", "2026-10-01T09:00:00")
	_dex.mark_caught(&"pidgey", &"pallet_town", "2026-10-01T09:01:00")
	_dex.mark_seen(&"rattata", &"route_1", "2026-10-02T18:00:00")
	_dex.mark_caught(&"rattata", &"route_1", "2026-10-02T18:02:00")
	_dex.mark_seen(&"pidgey", &"route_1", "2026-10-02T18:10:00")
	PokedexNotes.refresh(_dex, _lib, null)


func _grid(filter: int = Filter.ALL, zone: StringName = &"", type: StringName = &"",
		text: String = "", selected: StringName = &"") -> PokedexGridView:
	return PokedexQuery.grid(_dex, _data, _lib, _zones, filter, zone, type, text, selected)


func _ids(view: PokedexGridView) -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot: PokedexSlotView in view.slots:
		ids.append(slot.species_id)
	return ids


## Tous les textes d'une fiche (pour chercher ce qui ne doit pas y être).
func _sheet_texts(view: PokedexSheetView) -> String:
	var parts: PackedStringArray = [view.number_text, view.name, view.height_text,
		view.weight_text, view.description, view.counts_text, view.habitat_empty_text,
		view.evolution_text, view.notes_empty_text]
	parts.append_array(view.type_names)
	parts.append_array(view.notes)
	for habitat: PokedexHabitatView in view.habitats:
		parts.append(habitat.name)
	return " | ".join(parts)


func test_filters_follow_the_menu_route_values() -> void:
	assert_eq(Filter.ALL, MenuRoute.DEX_FILTER_ALL)
	assert_eq(Filter.SEEN, MenuRoute.DEX_FILTER_SEEN)
	assert_eq(Filter.CAUGHT, MenuRoute.DEX_FILTER_CAUGHT)
	assert_eq(Filter.HABITAT, MenuRoute.DEX_FILTER_HABITAT)
	assert_eq(PokedexQuery.FILTER_LABELS,
		PackedStringArray(["TOUS", "VUS", "CAPTURÉS", "HABITATS"]))


func test_three_states() -> void:
	_kevin()
	assert_eq(PokedexQuery.state_of(_dex, &"bulbasaur"), State.UNKNOWN)
	assert_eq(PokedexQuery.state_of(_dex, &"squirtle"), State.SEEN)
	assert_eq(PokedexQuery.state_of(_dex, &"charmander"), State.CAUGHT)
	assert_eq(PokedexQuery.state_of(null, &"charmander"), State.UNKNOWN)


func test_all_shows_151_numbered_slots_and_unknown_ones_carry_nothing() -> void:
	_kevin()
	var view := _grid()
	assert_eq(view.slots.size(), 151)
	for i: int in view.slots.size():
		var slot := view.slots[i]
		assert_eq(slot.number, i + 1)
		assert_eq(slot.number_text, "%03d" % (i + 1))
	var unknown := view.slots[0]
	assert_true(unknown.is_unknown(), "Bulbizarre jamais vu")
	assert_eq(unknown.species_id, &"", "ni espèce, ni nom (la silhouette vient du seul numéro)")
	assert_eq(unknown.name, "???")
	assert_eq(unknown.state, State.UNKNOWN)
	assert_false(unknown.caught)
	assert_true(view.slots[150].is_unknown(), "n° 151 absent des données : inconnu aussi")
	var seen := view.slots[6]
	assert_eq(seen.species_id, &"squirtle")
	assert_eq(seen.name, "Carapuce")
	assert_eq(seen.state, State.SEEN)
	assert_false(seen.caught)
	var caught := view.slots[3]
	assert_eq(caught.name, "Salamèche")
	assert_true(caught.caught)
	assert_eq(view.slot(&"pidgey").number, 16)
	assert_null(view.slot(&""), "jamais une case inconnue")
	assert_eq(view.empty_text, "")


func test_unknown_slots_keep_their_number_for_the_silhouette_but_never_a_species() -> void:
	_kevin()
	for slot: PokedexSlotView in _grid().slots:
		assert_gt(slot.number, 0)
		if slot.is_unknown():
			assert_eq(slot.species_id, &"", "n° %d" % slot.number)
			assert_eq(slot.name, PokedexSlotView.UNKNOWN_NAME)
			assert_ne(PokedexArt.thumb_region(slot.number), Rect2(), "silhouette trouvable")


func test_header_and_counter_without_slash() -> void:
	_kevin()
	var view := _grid()
	assert_eq(view.title, "POKÉDEX — KANTO")
	assert_eq(view.counts_text, "4 vus · 3 capturés · 151 espèces")
	assert_false(view.counts_text.contains("/"))
	assert_eq(PokedexQuery.counts_text(Pokedex.new(), _lib), "0 vu · 0 capturé · 151 espèces")


func test_seen_and_caught_filters() -> void:
	_kevin()
	assert_eq(_ids(_grid(Filter.SEEN)), [&"charmander", &"squirtle", &"pidgey", &"rattata"] \
		as Array[StringName], "vus = capturés compris, par numéro")
	assert_eq(_ids(_grid(Filter.CAUGHT)), [&"charmander", &"pidgey", &"rattata"] \
		as Array[StringName])
	assert_eq(_grid(Filter.CAUGHT, &"", &"", "", &"").filter, Filter.CAUGHT)
	assert_eq(_grid(42).filter, Filter.ALL, "filtre inconnu → TOUS")


func test_habitat_filter_offers_only_observed_zones() -> void:
	_kevin()
	var view := _grid(Filter.HABITAT)
	assert_eq(view.zone_ids, [&"pallet_town", &"route_1"] as Array[StringName],
		"ordre du voyage")
	assert_eq(view.zone_names, PackedStringArray(["Bourg Palette", "Route 1"]))
	assert_eq(view.zone, &"pallet_town", "sans zone : la première")
	assert_eq(_ids(view), [&"charmander", &"squirtle", &"pidgey"] as Array[StringName],
		"le labo est à Bourg Palette")
	view = _grid(Filter.HABITAT, &"route_1")
	assert_eq(_ids(view), [&"pidgey", &"rattata"] as Array[StringName])
	view = _grid(Filter.HABITAT, &"viridian_city")
	assert_eq(view.zone, &"pallet_town", "zone jamais observée : jamais proposée")
	assert_eq(_grid(Filter.ALL).zone, &"", "pas de zone hors du filtre HABITATS")


func test_habitat_filter_on_an_empty_pokedex() -> void:
	var view := _grid(Filter.HABITAT)
	assert_eq(view.zone_ids.size(), 0)
	assert_eq(view.zone, &"")
	assert_true(view.is_empty())
	assert_eq(view.empty_text, "Aucune espèce ne correspond.")
	assert_eq(view.selected, &"")


func test_type_filter_only_knows_caught_species() -> void:
	_kevin()
	var view := _grid()
	assert_eq(view.type_ids, [&"normal", &"fire", &"flying"] as Array[StringName],
		"types des capturés, ordre de la table (pas l'Eau de Carapuce, seulement vu)")
	assert_eq(view.type_names.size(), 3)
	assert_eq(_ids(_grid(Filter.ALL, &"", &"normal")), [&"pidgey", &"rattata"] \
		as Array[StringName], "plus de cases inconnues")
	assert_eq(_grid(Filter.ALL, &"", &"water").type, &"", "type non proposé : ignoré")
	assert_eq(_grid(Filter.ALL, &"", &"water").slots.size(), 151)


func test_search_only_finds_known_species_without_case_or_accents() -> void:
	_kevin()
	assert_eq(_ids(_grid(Filter.ALL, &"", &"", "salameche")), [&"charmander"] \
		as Array[StringName])
	assert_eq(_ids(_grid(Filter.ALL, &"", &"", "  ROU ")), [&"pidgey"] as Array[StringName])
	assert_eq(_ids(_grid(Filter.ALL, &"", &"", "016")), [&"pidgey"] as Array[StringName])
	assert_true(_grid(Filter.ALL, &"", &"", "bulbi").is_empty(), "Bulbizarre jamais vu")
	assert_true(_grid(Filter.ALL, &"", &"", "1").is_empty(), "le n° 1 est inconnu")
	assert_eq(_grid(Filter.ALL, &"", &"", "bulbi").empty_text, "Aucune espèce ne correspond.")
	assert_eq(_ids(_grid(Filter.CAUGHT, &"", &"", "a")), [&"charmander", &"rattata"] \
		as Array[StringName], "les filtres se combinent")
	assert_eq(PokedexQuery.fold("Cramois'Île Œuf"), "cramoisile oeuf")


func test_selected_species() -> void:
	_kevin()
	assert_eq(_grid().selected, &"charmander", "sans route : la première connue")
	assert_eq(_grid(Filter.ALL, &"", &"", "", &"rattata").selected, &"rattata")
	assert_eq(_grid(Filter.ALL, &"", &"", "", &"bulbasaur").selected, &"charmander",
		"une espèce inconnue n'est jamais ouverte")
	assert_eq(_grid(Filter.HABITAT, &"route_1").selected, &"pidgey")


func test_sheet_of_an_unknown_species_does_not_exist() -> void:
	_kevin()
	assert_null(PokedexQuery.sheet(&"bulbasaur", _dex, _data, _lib, _zones))
	assert_null(PokedexQuery.sheet(&"missingno", _dex, _data, _lib, _zones))


func test_sheet_of_a_seen_species_hides_what_is_learnt_at_capture() -> void:
	_kevin()
	var view := PokedexQuery.sheet(&"squirtle", _dex, _data, _lib, _zones)
	assert_eq(view.number_text, "N° 007")
	assert_eq(view.name, "Carapuce")
	assert_eq(view.state, State.SEEN)
	assert_false(view.caught)
	assert_eq(view.type_ids.size(), 0, "types à la capture seulement")
	assert_eq(view.height_text, "")
	assert_eq(view.weight_text, "")
	assert_eq(view.description, "")
	assert_eq(view.counts_text, "Vu 1 fois")
	assert_eq(view.habitats.size(), 1)
	assert_eq(view.habitats[0].zone_id, &"pallet_town")
	assert_eq(view.habitats[0].name, "Bourg Palette")
	assert_eq(view.notes, PackedStringArray([_lib.get_notes(&"squirtle")[0].text]),
		"la note de la première observation")
	assert_eq(view.notes_empty_text, "")


func test_sheet_of_a_caught_species_is_complete() -> void:
	_kevin()
	var view := PokedexQuery.sheet(&"charmander", _dex, _data, _lib, _zones)
	assert_true(view.caught)
	assert_eq(view.type_ids, [&"fire"] as Array[StringName])
	assert_eq(view.type_names, PackedStringArray(["Feu"]))
	assert_eq(view.height_text, "0,6 m")
	assert_eq(view.weight_text, "8,5 kg")
	assert_eq(view.description, _lib.get_species(&"charmander").description)
	assert_eq(view.counts_text, "Vu 1 fois · capturé 1 fois", "Q-8 : reçu = observé")
	assert_eq(view.evolution_text, "Salamèche → ???", "Q-9, jamais de condition")
	assert_eq(PokedexSheetView.TAB_LABELS,
		PackedStringArray(["Aperçu", "Habitat", "Évolution", "Observations"]))
	var pidgey := PokedexQuery.sheet(&"pidgey", _dex, _data, _lib, _zones)
	assert_eq(pidgey.counts_text, "Vu 2 fois · capturé 1 fois")
	assert_eq(pidgey.habitats.size(), 2, "Bourg Palette puis Route 1")
	assert_eq(pidgey.habitats[1].name, "Route 1")


func test_sheet_never_shows_stats_conditions_or_question_marks_in_habitats() -> void:
	_kevin()
	_dex.mark_seen(&"charizard", &"route_1")
	for species: StringName in _dex.seen_ids():
		var view := PokedexQuery.sheet(species, _dex, _data, _lib, _zones)
		var texts := _sheet_texts(view)
		for word: String in ["Attaque", "Vitesse", "Talent", "N. ", "Nv.", "niveau"]:
			assert_false(texts.contains(word), "%s : « %s »" % [species, word])
		for habitat: PokedexHabitatView in view.habitats:
			assert_false(habitat.name.contains("???"), "aucun « ??? » dans un habitat")
			assert_false(habitat.zone_id.is_empty())
	assert_eq(PokedexQuery.sheet(&"charmander", _dex, _data, _lib, _zones).evolution_text,
		"Salamèche → ??? → Dracaufeu", "seulement les stades vus")


func test_empty_habitats_and_notes_have_their_sentence() -> void:
	_dex.mark_seen(&"raticate")
	var view := PokedexQuery.sheet(&"raticate", _dex, _data, _lib, _zones)
	assert_eq(view.habitats.size(), 0)
	assert_eq(view.habitat_empty_text, "Aucun habitat noté pour l'instant.")
	assert_eq(view.notes.size(), 0)
	assert_eq(view.notes_empty_text, "Rien de noté pour l'instant.")
	assert_eq(view.evolution_text, "??? → Rattatac", "Rattata jamais vu")
	assert_eq(PokedexQuery.sheet(&"raticate", _dex, _data, _lib, null).habitats.size(), 0)


func test_notes_follow_unlock_order_and_ignore_unknown_ids() -> void:
	_dex.mark_seen(&"pidgey")
	_dex.unlock_note(&"pidgey", &"old_note_removed_from_data")
	_dex.unlock_note(&"pidgey", &"rattata_hops")
	PokedexNotes.refresh(_dex, _lib, null)
	var view := PokedexQuery.sheet(&"pidgey", _dex, _data, _lib, _zones)
	assert_eq(view.notes, PackedStringArray([_lib.get_note(&"pidgey_paths").text]),
		"une note d'une autre espèce ou disparue des données n'est pas montrée")


func test_formats() -> void:
	assert_eq(PokedexQuery.height_text(2.0), "2,0 m")
	assert_eq(PokedexQuery.weight_text(100.0), "100,0 kg")
	assert_eq(PokedexQuery.weight_text(1.8), "1,8 kg")
	assert_true(PokedexQuery.matches("Roucool", 16, ""))
	assert_true(PokedexQuery.matches("Roucool", 16, "16"))
	assert_false(PokedexQuery.matches("Roucool", 16, "17"))
