class_name MapJournal
extends RefCounted
## Traduit la partie en vues pour l'écran Carte (dossier 08 §5 ; jalon-06.md §3.6). Classe
## pure, statique : appelée par MenuDirector (T21) à chaque visite et à chaque zone touchée.
##
## « La Carte ne montre pas ce qu'il reste à découvrir. Elle raconte ce que tu as déjà
## découvert. » Une zone est **découverte** dès qu'une de ses cartes l'est
## (`GameState.discovered_maps`, datées à la première arrivée) ; un intérieur compte pour sa
## ville. La zone où se tient le joueur est toujours découverte. Une zone non découverte n'a
## ni nom, ni toucher, ni panneau (Q-15). Aucun total, aucun « ??? ».
##
## [code]state[/code] : l'autoload GameState (ou une instance de game_state.gd en test) ; on
## y lit `discovered_maps`, `found_items`, `pokedex`, `current_map`.

## En-tête de l'écran.
const TITLE: String = "CARTE — KANTO"


## Zones découvertes d'après [param discovered_maps] (carte → date ISO de première arrivée),
## dans l'ordre de [param zones] (celui du voyage) : zone → date de la première visite (la
## plus ancienne de ses cartes ; "" si aucune n'est datée). Une carte rangée dans aucune zone
## est ignorée.
static func discovered_zones(discovered_maps: Dictionary,
		zones: ZoneLibrary) -> Dictionary[StringName, String]:
	var first: Dictionary[StringName, String] = {}
	var result: Dictionary[StringName, String] = {}
	if zones == null:
		return result
	for map: Variant in discovered_maps:
		var zone := zones.zone_of(StringName(str(map)))
		if zone.is_empty():
			continue
		var date := str(discovered_maps[map])
		if not first.has(zone) or _earlier(date, first[zone]):
			first[zone] = date
	for zone: StringName in zones.get_ids():
		if first.has(zone):
			result[zone] = first[zone]
	return result


## Zone du joueur : celle de sa carte (dans un intérieur, sa ville) ; &"" si la carte n'est
## rangée nulle part.
static func player_zone(current_map: StringName, zones: ZoneLibrary) -> StringName:
	return zones.zone_of(current_map) if zones != null else &""


## Vrai si [param zone] est découverte (ou si le joueur s'y trouve).
static func is_discovered(zone: StringName, state: Object, zones: ZoneLibrary) -> bool:
	return _known_zones(state, zones).has(zone)


## Vue de l'écran : illustration, zones découvertes (avec leur rectangle), portrait. Le
## panneau à ouvrir à l'arrivée est [param zone] (paramètre « zone » de la route) s'il est
## découvert, sinon la zone du joueur.
static func view(state: Object, zones: ZoneLibrary, illustration: MapIllustration,
		zone: StringName = &"") -> MapView:
	var result := MapView.new()
	result.title = TITLE
	if illustration != null:
		result.image_path = illustration.get_image_path()
		result.image_size = illustration.get_image_size()
	if state == null or zones == null:
		return result
	var here := player_zone(state.current_map, zones)
	var known := _known_zones(state, zones)
	for id: StringName in known:
		var data := zones.get_zone(id)
		var entry := MapZoneView.new()
		entry.zone_id = id
		entry.name = data.name
		entry.kind = data.kind
		if illustration != null and illustration.has_area(id):
			entry.area = Rect2(illustration.area_of(id))
		entry.current = id == here
		result.zones.append(entry)
	result.player_zone = here if known.has(here) else &""
	if known.has(zone):
		result.selected = zone
	else:
		result.selected = result.player_zone
	return result


## Panneau de [param zone] ; null si elle n'est pas découverte (ou inconnue).
## [param pokedex_visible] : [method MenuUnlocks.pokedex_visible] ; faux → aucun Pokémon
## observé (les données restent, l'écran ne les montre pas). [param items] donne le nom des
## objets (null → aucun objet listé).
static func panel(zone: StringName, state: Object, data: PokemonData, zones: ZoneLibrary,
		items: ItemLibrary, pokedex_visible: bool) -> ZonePanelView:
	if state == null or zones == null or not zones.has_zone(zone) \
			or not is_discovered(zone, state, zones):
		return null
	var info := zones.get_zone(zone)
	var result := ZonePanelView.new()
	result.zone_id = zone
	result.name = info.name
	result.subtitle = info.subtitle
	result.description = info.description
	result.current = player_zone(state.current_map, zones) == zone
	if pokedex_visible:
		result.pokemon = observed_pokemon(zone, state.pokedex, data, zones)
	result.items = found_items(zone, state.found_items, items, zones)
	for service: ZoneService in info.services:
		if state.discovered_maps.has(service.found_on):
			result.services.append(ZoneEntryView.new(service.id,
				zones.service_name(service.id)))
	return result


## Espèces vues sur une carte de [param zone], par numéro du Pokédex. N'applique **pas** la
## règle de déblocage ([method panel] le fait).
static func observed_pokemon(zone: StringName, pokedex: Pokedex, data: PokemonData,
		zones: ZoneLibrary) -> Array[ZoneEntryView]:
	var found: Array[SpeciesData] = []
	if pokedex == null or data == null:
		return [] as Array[ZoneEntryView]
	for species: StringName in pokedex.seen_ids():
		if data.has_species(species) \
				and PokedexQuery.habitat_zones(pokedex, species, zones).has(zone):
			found.append(data.get_species(species))
	found.sort_custom(func(a: SpeciesData, b: SpeciesData) -> bool: return a.dex < b.dex)
	var result: Array[ZoneEntryView] = []
	for species: SpeciesData in found:
		var entry := ZoneEntryView.new(species.id, species.name)
		entry.dex_number = species.dex
		result.append(entry)
	return result


## Objets ramassés sur une carte de [param zone] ([param found] : `GameState.found_items`,
## entrées { item, map, date }), une ligne par objet dans l'ordre de la première trouvaille,
## avec le nombre de trouvailles. Un objet absent de [param items] n'est pas listé (jamais un
## identifiant brut).
static func found_items(zone: StringName, found: Array, items: ItemLibrary,
		zones: ZoneLibrary) -> Array[ZoneEntryView]:
	var result: Array[ZoneEntryView] = []
	if items == null or zones == null:
		return result
	var by_id: Dictionary[StringName, ZoneEntryView] = {}
	for raw: Variant in found:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if zones.zone_of(StringName(str(entry.get("map", "")))) != zone:
			continue
		var id := StringName(str(entry.get("item", "")))
		if by_id.has(id):
			by_id[id].count += 1
			continue
		var item := items.get_item(id)
		if item == null:
			continue
		var line := ZoneEntryView.new(id, item.name)
		by_id[id] = line
		result.append(line)
	return result


## Zones découvertes, plus celle du joueur, dans l'ordre de [param zones].
static func _known_zones(state: Object, zones: ZoneLibrary) -> Array[StringName]:
	var result: Array[StringName] = []
	if state == null or zones == null:
		return result
	var discovered := discovered_zones(state.discovered_maps, zones)
	var here := player_zone(state.current_map, zones)
	for id: StringName in zones.get_ids():
		if discovered.has(id) or id == here:
			result.append(id)
	return result


## Vrai si [param date] précède [param other] (dates ISO ; une date vide ne précède rien et
## est remplacée par toute date connue).
static func _earlier(date: String, other: String) -> bool:
	if date.is_empty():
		return false
	return other.is_empty() or date < other
