class_name TrainerSummary
extends RefCounted
## Traduit l'état de la partie en [TrainerView] pour l'écran Dresseur (dossier 08 §6 ;
## jalon-06.md §3.7, §6.11, Q-13, Q-14). Classe pure, statique : appelée par MenuDirector
## (T25) à chaque affichage de l'écran.
##
## Ne montre que ce que la partie enregistre déjà (aucun champ de sauvegarde nouveau) :
## - identité : nom, « Dresseur Pokémon », temps de jeu, date de départ ([code]started_at[/code]),
##   argent (J7, dossier 09 §10) ;
## - « vus » / « capturés » : seulement si le Pokédex est visible ([MenuUnlocks]) ;
## - **8 emplacements de badges** ([BadgeLibrary], MM.2 : obtenu = drapeau levé ; aucun avant le
##   J10 ; jamais « 0/8 ») et l'équipe actuelle (MM.2) ;
## - grands moments : ceux de [code]GameState.moments[/code] (premier Pokémon, combat contre le
##   rival, première capture) **et** la première arrivée dans chaque zone (date la plus
##   ancienne de [code]discovered_maps[/code] parmi les cartes de la zone), sauf la zone où
##   l'aventure commence ; « Départ de Bourg Palette » = première arrivée sur la Route 1 ;
##   un badge obtenu (J10, [BadgeMoment] : titre, ville et Champion lus dans [BadgeLibrary],
##   un badge inconnu écarte le moment ; le souvenir de l'équipe n'est pas montré au J10).
##   Ordre chronologique ; lieu = nom de la **zone**, jamais un identifiant de carte ;
## - statistiques : temps de jeu, zones découvertes, captures depuis le début (carrière : relâcher ne les
##   fait pas baisser ; le starter n'en est pas), objets trouvés (pas de combats
##   gagnés : non enregistrés) ; une statistique à 0 est absente.

## Identifiants des statistiques ([member TrainerStatView.stat_id]), dans l'ordre d'affichage.
const STAT_PLAY_TIME: StringName = &"play_time"
const STAT_ZONES: StringName = &"zones"
const STAT_CAPTURES: StringName = &"captures"
const STAT_ITEMS_FOUND: StringName = &"items_found"
## Libellés (textes d'interface validés par Kevin le 2026-10-06). Ni « vus », ni « capturés », ni
## « Pokédex » : ces mots n'existent pas avant l'activation (jalon-06.md §4).
const STAT_LABELS: Dictionary[StringName, String] = {
	STAT_PLAY_TIME: "Temps de jeu",
	STAT_ZONES: "Zones découvertes",
	STAT_CAPTURES: "Captures",
	STAT_ITEMS_FOUND: "Objets trouvés",
}

## Clés des détails d'un moment enregistré (GameState.record_moment).
const _DETAIL_SPECIES: String = "species"
const _DETAIL_OUTCOME: String = "outcome"
## Une date vide se range après toutes les autres.
const _NO_DATE: String = "~"


## Vue de l'écran Dresseur pour [param state] (l'autoload GameState, ou une instance de
## game_state.gd en test). [param zones] et [param moments] peuvent être null (pas de lieux,
## pas de moments).
## [param badges] (MM.2, facultatif) : les 8 emplacements viennent de [method BadgeLibrary.slots]
## (un badge est obtenu quand son drapeau est levé) ; null : huit emplacements muets.
static func build(state: Object, data: PokemonData, zones: ZoneLibrary, moments: MomentLibrary,
		unlocks: MenuUnlocks, badges: BadgeLibrary = null,
		items: ItemLibrary = null) -> TrainerView:
	var view := TrainerView.new()
	view.player_name = state.player_name
	view.player_title = DashboardViews.PLAYER_TITLE
	view.play_time_text = MenuFormat.play_time(state.play_time)
	view.started_text = MenuFormat.long_date(state.started_at)
	view.money_text = MenuFormat.money(state.money)
	var pokedex: Pokedex = state.pokedex
	if unlocks != null and unlocks.pokedex_visible():
		view.seen_text = DashboardViews.seen_text(pokedex.seen_count())
		view.caught_text = DashboardViews.caught_text(pokedex.caught_count())
		view.seen_route = MenuRoute.pokedex(MenuRoute.DEX_FILTER_SEEN)
		view.caught_route = MenuRoute.pokedex(MenuRoute.DEX_FILTER_CAUGHT)
	if badges != null:
		view.badges = badges.slots(state.flags)
	else:
		for i: int in TrainerView.BADGE_COUNT:
			view.badges.append(BadgeSlotView.new(i))
	if zones != null:
		view.zone_id = MapJournal.player_zone(state.current_map, zones)
	var party: Party = state.party
	for i: int in party.size():
		view.team.append(DashboardViews.member(party.get_at(i), i, data))
	if moments != null:
		view.moments = moment_views(state, data, zones, moments, unlocks, badges, items)
	view.stats = stat_views(state, zones)
	return view


## Grands moments, du plus ancien au plus récent (à date égale : arrivées d'abord, puis dans
## l'ordre d'enregistrement). Un moment d'un type sans texte est ignoré ; un moment « badge »
## sans [param badges] ou d'un badge inconnu aussi ; un moment « fossil » (J12) sans
## [param items] ou d'un objet inconnu aussi.
static func moment_views(state: Object, data: PokemonData, zones: ZoneLibrary,
		moments: MomentLibrary, unlocks: MenuUnlocks, badges: BadgeLibrary = null,
		items: ItemLibrary = null) -> Array[MomentView]:
	var keyed: Array[Array] = []
	var arrivals := first_arrivals(state.discovered_maps, zones)
	var start_zone := start_zone_of(arrivals)
	for zone: StringName in arrivals:
		if zone == start_zone:
			continue
		var arrival := _arrival_view(zone, arrivals[zone], zones, moments)
		if arrival != null:
			keyed.append([_sort_date(arrival.date), 0, keyed.size(), arrival])
	var records: Array[Dictionary] = state.moments
	for record: Dictionary in records:
		var moment := _record_view(record, state, data, zones, moments, unlocks, badges, items)
		if moment != null:
			keyed.append([_sort_date(moment.date), 1, keyed.size(), moment])
	keyed.sort_custom(func(a: Array, b: Array) -> bool:
		if a[0] != b[0]:
			return a[0] < b[0]
		if a[1] != b[1]:
			return a[1] < b[1]
		return a[2] < b[2])
	var views: Array[MomentView] = []
	for entry: Array in keyed:
		views.append(entry[3])
	return views


## Statistiques déjà enregistrées, dans l'ordre d'affichage ; celles à 0 sont absentes (le
## temps de jeu est toujours là).
static func stat_views(state: Object, zones: ZoneLibrary) -> Array[TrainerStatView]:
	var stats: Array[TrainerStatView] = []
	stats.append(_stat(STAT_PLAY_TIME, MenuFormat.play_time(state.play_time)))
	var zone_count := first_arrivals(state.discovered_maps, zones).size()
	if zone_count > 0:
		stats.append(_stat(STAT_ZONES, MenuFormat.number(zone_count)))
	var captures := capture_count(state.pokedex, state.starter_species)
	if captures > 0:
		stats.append(_stat(STAT_CAPTURES, MenuFormat.number(captures)))
	var found: Array[Dictionary] = state.found_items
	if found.size() > 0:
		stats.append(_stat(STAT_ITEMS_FOUND, MenuFormat.number(found.size())))
	return stats


## Première arrivée dans chaque zone : zone → date ISO la plus ancienne parmi ses cartes
## découvertes. Une seule règle, celle de [method MapJournal.discovered_zones] ; ici seul
## l'ordre change : celui des dates (à date égale, l'identifiant ; une date vide à la fin).
static func first_arrivals(discovered_maps: Dictionary, zones: ZoneLibrary) \
		-> Dictionary[StringName, String]:
	var dates := MapJournal.discovered_zones(discovered_maps, zones)
	var ids: Array[StringName] = []
	ids.assign(dates.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		if dates[a] != dates[b]:
			return _sort_date(dates[a]) < _sort_date(dates[b])
		return String(a) < String(b))
	var ordered: Dictionary[StringName, String] = {}
	for id: StringName in ids:
		ordered[id] = dates[id]
	return ordered


## Zone où l'aventure commence : celle de la première arrivée (&"" si aucune). Son arrivée
## n'est pas un grand moment (la date de départ le dit déjà).
static func start_zone_of(arrivals: Dictionary[StringName, String]) -> StringName:
	for zone: StringName in arrivals:
		return zone
	return &""


## Captures depuis le début de la partie (statistique de carrière, décision de Kevin du
## 2026-10-03) : somme des compteurs de capture du Pokédex, qui ne baissent jamais (relâcher ou
## déposer au stockage n'y change rien). Le starter, reçu et non capturé, est enregistré une
## fois au Pokédex : on le retire.
static func capture_count(pokedex: Pokedex, starter: StringName) -> int:
	var count := 0
	for species: StringName in pokedex.caught_ids():
		count += pokedex.times_caught(species)
	if not starter.is_empty() and pokedex.times_caught(starter) > 0:
		count -= 1
	return maxi(count, 0)


static func _arrival_view(zone: StringName, date: String, zones: ZoneLibrary,
		moments: MomentLibrary) -> MomentView:
	var text := moments.get_zone_text(zone)
	var zone_data := zones.get_zone(zone)
	if text == null or zone_data == null:
		return null
	var marks := {MomentLibrary.MARK_ZONE: zone_data.name}
	var view := _view(MomentLibrary.ZONE_ARRIVAL, text, marks)
	if view == null:
		return null
	view.place = zone_data.name
	view.zone_id = zone
	view.date = date
	view.date_text = MenuFormat.long_date(date)
	return view


static func _record_view(record: Dictionary, state: Object, data: PokemonData,
		zones: ZoneLibrary, moments: MomentLibrary, unlocks: MenuUnlocks,
		badges: BadgeLibrary, items: ItemLibrary = null) -> MomentView:
	var type := StringName(str(record.get("type", "")))
	if type == MomentLibrary.ZONE_ARRIVAL:
		return null
	var text := moments.get_text(type)
	if text == null:
		return null
	var details: Dictionary = record.get("details", {}) if record.get("details") is Dictionary \
		else {}
	var map := StringName(str(record.get("map", "")))
	var zone := zones.zone_of(map) if zones != null else &""
	var place := zones.zone_name_of(map) if zones != null else ""
	var species := StringName(str(details.get(_DETAIL_SPECIES, "")))
	var species_data := data.get_species(species) if data != null and not species.is_empty() \
		else null
	var marks := {
		MomentLibrary.MARK_ZONE: place,
		MomentLibrary.MARK_SPECIES: species_data.name if species_data != null else "",
		MomentLibrary.MARK_OUTCOME: moments.outcome_text(
			StringName(str(details.get(_DETAIL_OUTCOME, "")))),
	}
	if type == MomentLibrary.BADGE:
		var badge := BadgeMoment.badge_of(details)
		if badges == null or not badges.has_badge(badge):
			return null
		marks[MomentLibrary.MARK_BADGE] = badges.badge_name(badge)
		marks[MomentLibrary.MARK_CITY] = badges.city(badge)
		marks[MomentLibrary.MARK_LEADER] = badges.leader(badge)
	if type == MomentLibrary.FOSSIL:
		# J12 : le fossile obtenu (« Fossile Dôme »), nom lu dans les objets.
		var item_id := StringName(str(details.get(MomentLibrary.DETAIL_ITEM, "")))
		var item := items.get_item(item_id) if items != null else null
		if item == null:
			return null
		marks[MomentLibrary.MARK_FOSSIL] = item.name
	var view := _view(type, text, marks)
	if view == null:
		return null
	if type == MomentLibrary.FOSSIL:
		view.item_id = StringName(str(details.get(MomentLibrary.DETAIL_ITEM, "")))
	view.place = place
	view.zone_id = zone
	view.date = str(record.get("date", ""))
	view.date_text = MenuFormat.long_date(view.date)
	if species_data != null:
		view.species_id = species
		view.dex_number = species_data.dex
	if type == MomentLibrary.STARTER and species_data != null:
		view.route = _starter_route(species, state.party, unlocks)
	return view


## Moment [param kind] aux textes remplis par [param marks] : un titre qui ne se remplit pas
## écarte le moment (null) ; un détail qui ne se remplit pas devient "" (ligne absente).
static func _view(kind: StringName, text: MomentTextData, marks: Dictionary) -> MomentView:
	var title := _fill(text.title, marks)
	if title.is_empty():
		return null
	var view := MomentView.new()
	view.kind = kind
	view.title = title
	view.detail = _fill(text.detail, marks)
	return view


## [param template] avec ses marques remplacées ; "" si une marque utilisée n'a pas de valeur.
static func _fill(template: String, marks: Dictionary) -> String:
	var result := template
	for mark: String in marks:
		if not result.contains(mark):
			continue
		var value: String = marks[mark]
		if value.is_empty():
			return ""
		result = result.replace(mark, value)
	return result


## Lien du « premier Pokémon » (§6.3) : sa fiche Équipe s'il est dans l'équipe, sinon sa
## fiche Pokédex si le Pokédex est visible, sinon aucun.
static func _starter_route(species: StringName, party: Party, unlocks: MenuUnlocks) -> MenuRoute:
	var fallback := -1
	for i: int in party.size():
		var pokemon := party.get_at(i)
		if pokemon.species_id != species:
			continue
		if pokemon.origin == Pokemon.Origin.STARTER:
			return MenuRoute.team(i)
		if pokemon.origin == Pokemon.Origin.UNKNOWN and fallback < 0:
			fallback = i
	if fallback >= 0:
		return MenuRoute.team(fallback)
	if unlocks != null and unlocks.pokedex_visible():
		return MenuRoute.pokedex(MenuRoute.DEX_FILTER_ALL, species)
	return null


static func _stat(id: StringName, value: String) -> TrainerStatView:
	return TrainerStatView.new(id, STAT_LABELS[id], value)


static func _sort_date(date: String) -> String:
	return date if not date.is_empty() else _NO_DATE
