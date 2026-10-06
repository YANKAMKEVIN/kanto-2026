class_name PokedexQuery
extends RefCounted
## Traduit le Pokédex de la partie en vues pour l'écran Pokédex (dossier 08 §4 ; jalon-06.md
## §3.5). Classe pure, statique : appelée par MenuDirector (T16) à chaque visite et à chaque
## changement de filtre ou de fiche.
##
## « Un carnet de terrain, pas Poképédia » : rien de ce que le joueur n'a pas découvert.
## - **inconnu** : numéro et « ??? », sans silhouette, sans espèce ;
## - **vu** : sprite, nom, habitats observés, compteur, évolution vue, notes débloquées ;
## - **capturé** : en plus, types, taille, poids, description.
## Jamais de statistiques de base ni de talents ; la recherche et le filtre par type ne
## portent que sur ce qui est connu (le type d'une espèce seulement vue n'est pas connu).
##
## L'écran n'existe que si le Pokédex est visible ([method MenuUnlocks.pokedex_visible]) :
## cette classe ne le vérifie pas, [MenuNavigator] refuse déjà la route.

enum State { UNKNOWN, SEEN, CAUGHT }
## Filtres de la grille : mêmes valeurs, même ordre que `MenuRoute.DEX_FILTER_*` (T2).
enum Filter { ALL, SEEN, CAUGHT, HABITAT }

## En-tête de l'écran (dossier 08 §4 ; refonte T4 : titre sobre en casse normale, comme la
## maquette ; la région unique n'est plus répétée).
const TITLE: String = "Pokédex"
## Libellés des filtres, dans l'ordre de [enum Filter] (casse de la maquette, refonte T4).
const FILTER_LABELS: PackedStringArray = ["Tous", "Vus", "Capturés", "Habitats"]
## Textes d'interface provisoires (règle 4).
const COUNTS_SPECIES_FORMAT: String = "%s · %d espèces"
const EMPTY_TEXT: String = "Aucune espèce ne correspond."
const NO_SPECIES_TEXT: String = "Aucune espèce enregistrée."
const HABITAT_EMPTY_TEXT: String = "Aucun habitat noté pour l'instant."
const NOTES_EMPTY_TEXT: String = "Rien de noté pour l'instant."
const TIMES_FORMAT: String = "%d fois"
const HABITAT_COUNT_FORMAT: String = "Zones observées : %d"
const NUMBER_FORMAT: String = "N° %03d"
const SEEN_FORMAT: String = "Vu %d fois"
const CAUGHT_FORMAT: String = " · capturé %d fois"
## Recherche sans accents ni apostrophes ([method fold]).
const _ACCENTS: Array[Array] = [
	["à", "a"], ["â", "a"], ["ä", "a"], ["é", "e"], ["è", "e"], ["ê", "e"], ["ë", "e"],
	["î", "i"], ["ï", "i"], ["ô", "o"], ["ö", "o"], ["ù", "u"], ["û", "u"], ["ü", "u"],
	["ç", "c"], ["œ", "oe"], ["æ", "ae"], ["'", ""], ["’", ""],
]


## État de [param species] dans [param pokedex].
static func state_of(pokedex: Pokedex, species: StringName) -> State:
	if pokedex == null or not pokedex.is_seen(species):
		return State.UNKNOWN
	return State.CAUGHT if pokedex.is_caught(species) else State.SEEN


## « 3 vus · 2 capturés · 151 espèces » (« 1 vu · 0 capturé » au singulier ; jamais « / »).
static func counts_text(pokedex: Pokedex, library: PokedexLibrary) -> String:
	return COUNTS_SPECIES_FORMAT % [DashboardViews.dex_text(pokedex.seen_count(),
		pokedex.caught_count()), library.size()]


## Vue de l'écran principal. [param filter] : [enum Filter] ; [param zone] : zone du filtre
## HABITATS (&"" ou inconnue = la première zone proposée) ; [param type] : &"" = tous ;
## [param text] : recherche ; [param selected] : fiche demandée par la route (ignorée si
## l'espèce est inconnue). [param zones] peut être null (aucun habitat).
static func grid(pokedex: Pokedex, data: PokemonData, library: PokedexLibrary,
		zones: ZoneLibrary, filter: int = Filter.ALL, zone: StringName = &"",
		type: StringName = &"", text: String = "", selected: StringName = &"") -> PokedexGridView:
	var view := PokedexGridView.new()
	view.title = TITLE
	view.counts_text = counts_text(pokedex, library)
	view.filter = filter if filter >= Filter.ALL and filter <= Filter.HABITAT else Filter.ALL
	view.filter_labels = FILTER_LABELS
	view.zone_ids = zone_choices(pokedex, zones)
	for id: StringName in view.zone_ids:
		view.zone_names.append(zones.get_zone(id).name)
	if view.filter == Filter.HABITAT and not view.zone_ids.is_empty():
		view.zone = zone if view.zone_ids.has(zone) else view.zone_ids[0]
	view.type_ids = type_choices(pokedex, data)
	var chart := data.get_type_chart()
	for id: StringName in view.type_ids:
		view.type_names.append(chart.get_type_name(id))
	view.type = type if view.type_ids.has(type) else &""
	view.text = text
	view.slots = slots(pokedex, data, library, zones, view.filter, view.zone, view.type, text)
	view.empty_text = EMPTY_TEXT if view.slots.is_empty() else ""
	view.no_species_text = NO_SPECIES_TEXT if pokedex.seen_count() == 0 else ""
	if state_of(pokedex, selected) != State.UNKNOWN and data.has_species(selected):
		view.selected = selected
	else:
		for slot: PokedexSlotView in view.slots:
			if not slot.is_unknown():
				view.selected = slot.species_id
				break
	return view


## Cases de la grille (voir [member PokedexGridView.slots]). Filtre HABITAT : [param zone]
## doit être une zone connue (sinon aucune case).
static func slots(pokedex: Pokedex, data: PokemonData, library: PokedexLibrary,
		zones: ZoneLibrary, filter: int = Filter.ALL, zone: StringName = &"",
		type: StringName = &"", text: String = "") -> Array[PokedexSlotView]:
	var result: Array[PokedexSlotView] = []
	var by_number := _species_by_number(data)
	var search := fold(text.strip_edges())
	var show_unknown := filter == Filter.ALL and type.is_empty() and search.is_empty()
	for number: int in range(1, library.size() + 1):
		var species: StringName = by_number.get(number, &"")
		var state := state_of(pokedex, species) if not species.is_empty() else State.UNKNOWN
		if state == State.UNKNOWN:
			if show_unknown:
				result.append(PokedexSlotView.new(number))
			continue
		var species_data := data.get_species(species)
		if filter == Filter.CAUGHT and state != State.CAUGHT:
			continue
		if filter == Filter.HABITAT and not habitat_zones(pokedex, species, zones).has(zone):
			continue
		if not type.is_empty() and (state != State.CAUGHT or not species_data.types.has(type)):
			continue
		if not search.is_empty() and not matches(species_data.name, number, search):
			continue
		result.append(PokedexSlotView.new(number, species, species_data.name, state))
	return result


## Fiche de [param species], ou null si l'espèce est inconnue (jamais vue, ou absente des
## données). [param zones] peut être null (aucun habitat).
static func sheet(species: StringName, pokedex: Pokedex, data: PokemonData,
		library: PokedexLibrary, zones: ZoneLibrary) -> PokedexSheetView:
	var state := state_of(pokedex, species)
	if state == State.UNKNOWN or not data.has_species(species):
		return null
	var species_data := data.get_species(species)
	var entry := pokedex.get_entry(species)
	var view := PokedexSheetView.new()
	view.species_id = species
	view.number = species_data.dex
	view.number_text = NUMBER_FORMAT % species_data.dex
	view.name = species_data.name
	view.state = state
	view.caught = state == State.CAUGHT
	view.counts_text = SEEN_FORMAT % entry.times_seen
	view.seen_times_text = TIMES_FORMAT % entry.times_seen
	if view.caught:
		view.caught_times_text = TIMES_FORMAT % entry.times_caught
		view.counts_text += CAUGHT_FORMAT % entry.times_caught
		var chart := data.get_type_chart()
		for type: StringName in species_data.types:
			view.type_ids.append(type)
			view.type_names.append(chart.get_type_name(type))
		var info := library.get_species(species) if library != null else null
		if info != null:
			view.height_text = height_text(info.height)
			view.weight_text = weight_text(info.weight)
			view.description = info.description
	for zone: StringName in habitat_zones(pokedex, species, zones):
		view.habitats.append(PokedexHabitatView.new(zone, zones.get_zone(zone).name))
	if not view.habitats.is_empty():
		view.habitat_count_text = HABITAT_COUNT_FORMAT % view.habitats.size()
	view.habitat_empty_text = HABITAT_EMPTY_TEXT if view.habitats.is_empty() else ""
	view.evolution = EvolutionReveal.chain(species, data, pokedex, true)
	view.evolution_text = EvolutionReveal.text(view.evolution)
	if library != null:
		for note_id: StringName in entry.notes:
			var note := library.get_note(note_id)
			if note != null and note.species == species:
				view.notes.append(note.text)
	view.notes_empty_text = NOTES_EMPTY_TEXT if view.notes.is_empty() else ""
	return view


## Zones où [param species] a été observée, dans l'ordre de découverte, chacune une fois
## (une carte hors de toute zone est ignorée ; jamais une zone non observée).
static func habitat_zones(pokedex: Pokedex, species: StringName,
		zones: ZoneLibrary) -> Array[StringName]:
	var result: Array[StringName] = []
	var entry := pokedex.get_entry(species) if pokedex != null else null
	if entry == null or zones == null:
		return result
	for map: StringName in entry.seen_maps:
		var zone := zones.zone_of(map)
		if not zone.is_empty() and not result.has(zone):
			result.append(zone)
	return result


## Zones du filtre HABITATS : celles où au moins une espèce a été observée, dans l'ordre de
## [ZoneLibrary] (l'ordre du voyage).
static func zone_choices(pokedex: Pokedex, zones: ZoneLibrary) -> Array[StringName]:
	var observed: Dictionary[StringName, bool] = {}
	var result: Array[StringName] = []
	if zones == null or pokedex == null:
		return result
	for species: StringName in pokedex.seen_ids():
		for zone: StringName in habitat_zones(pokedex, species, zones):
			observed[zone] = true
	for zone: StringName in zones.get_ids():
		if observed.has(zone):
			result.append(zone)
	return result


## Types du filtre par type : ceux des espèces **capturées**, dans l'ordre de la table des
## types.
static func type_choices(pokedex: Pokedex, data: PokemonData) -> Array[StringName]:
	var known: Dictionary[StringName, bool] = {}
	for species: StringName in pokedex.caught_ids():
		if data.has_species(species):
			for type: StringName in data.get_species(species).types:
				known[type] = true
	var result: Array[StringName] = []
	for type: StringName in data.get_type_chart().get_type_ids():
		if known.has(type):
			result.append(type)
	return result


## Vrai si l'espèce [param name] de numéro [param number] répond à la recherche
## [param folded_search] (déjà passée par [method fold]) : une partie du nom, sans casse ni
## accents ; ou le numéro (« 16 », « 016 »).
static func matches(name: String, number: int, folded_search: String) -> bool:
	if folded_search.is_empty():
		return true
	if folded_search.is_valid_int():
		return folded_search.to_int() == number
	return fold(name).contains(folded_search)


## [param text] en minuscules, sans accents (« Salamèche » → « salameche »).
static func fold(text: String) -> String:
	var result := text.to_lower()
	for pair: Array in _ACCENTS:
		result = result.replace(pair[0], pair[1])
	return result


## « 0,6 m » (une décimale, virgule française).
static func height_text(meters: float) -> String:
	return ("%.1f m" % meters).replace(".", ",")


## « 8,5 kg » (une décimale, virgule française).
static func weight_text(kilograms: float) -> String:
	return ("%.1f kg" % kilograms).replace(".", ",")


static func _species_by_number(data: PokemonData) -> Dictionary[int, StringName]:
	var result: Dictionary[int, StringName] = {}
	for id: StringName in data.get_species_ids():
		result[data.get_species(id).dex] = id
	return result
