class_name TeamViews
extends RefCounted
## Traduit l'équipe en [TeamView] pour l'écran Équipe (dossier 08 §2, jalon-06.md §3.3) et
## dit où va la sélection après un échange. Classe pure, statique : appelée par MenuDirector
## (T8) à chaque visite de l'Équipe et après chaque action (échange, favori).
##
## Textes d'interface validés par Kevin le 2026-10-06 : noms des statistiques, libellés de l'Histoire.

## Noms des statistiques de l'Aperçu, dans l'ordre de [constant SpeciesData.STATS].
const STAT_NAMES: Dictionary[StringName, String] = {
	&"hp": "PV", &"atk": "Attaque", &"def": "Défense", &"spa": "Atq. Spé.",
	&"spd": "Déf. Spé.", &"spe": "Vitesse",
}
## Libellé de la ligne de lieu de l'Histoire, selon la manière dont le Pokémon est arrivé.
const PLACE_LABELS: Dictionary[Pokemon.Origin, String] = {
	Pokemon.Origin.STARTER: "Reçu à",
	Pokemon.Origin.CAPTURE: "Capturé à",
	Pokemon.Origin.UNKNOWN: "Rencontré à",
}
## Phrase d'attachement du starter (onglet Histoire).
const STARTER_NOTE: String = "Ton premier Pokémon"
## Onglet Histoire d'un Pokémon sans rencontre enregistrée (sauvegarde d'avant le 5C.5).
const HISTORY_UNKNOWN: String = "Son histoire reste à écrire."
## « 320 / 560 XP » et « 240 XP avant le niveau suivant ».
const EXP_FORMAT: String = "%s / %s XP"
const EXP_REMAINING_FORMAT: String = "%s XP avant le niveau suivant"


## Vue de l'équipe [param party] : membres et fiches, dans l'ordre. [param zones] peut être
## null (lieux de l'Histoire vides) ; [param unlocks] décide de la révélation de l'évolution.
## Jalon 11 : [param companions] (espèces éligibles, null = aucune) et [param companion_uid]
## (le compagnon actuel) donnent le bouton FAIRE SORTIR / RAPPELER de chaque fiche.
static func build(party: Party, data: PokemonData, zones: ZoneLibrary, pokedex: Pokedex,
		unlocks: MenuUnlocks, companions: CompanionCatalog = null,
		companion_uid: String = "") -> TeamView:
	var view := TeamView.new()
	var visible := unlocks != null and unlocks.pokedex_visible()
	view.storage_available = unlocks != null and unlocks.storage_available()
	var members := party.get_all()
	for i: int in members.size():
		var pokemon_sheet := sheet(members[i], i, data, zones, pokedex, visible)
		pokemon_sheet.companion_action = companion_action(members[i], companions, companion_uid)
		view.members.append(pokemon_sheet.member)
		view.sheets.append(pokemon_sheet)
	return view


## Fiche de [param pokemon], à la place [param index] de l'équipe.
static func sheet(pokemon: Pokemon, index: int, data: PokemonData, zones: ZoneLibrary,
		pokedex: Pokedex, pokedex_visible: bool) -> PokemonSheetView:
	var view := PokemonSheetView.new()
	view.member = DashboardViews.member(pokemon, index, data)
	var species := data.get_species(pokemon.species_id)
	view.species_name = species.name if species != null else String(pokemon.species_id)
	if species != null:
		var chart := data.get_type_chart()
		for type_id: StringName in species.types:
			view.type_ids.append(type_id)
			view.type_names.append(chart.get_type_name(type_id))
	view.exp_fraction = ExpCalc.progress(pokemon, data)
	var span := ExpCalc.level_span(pokemon, data)
	if span.y > 0:
		view.exp_text = EXP_FORMAT % [MenuFormat.number(span.x), MenuFormat.number(span.y)]
		view.exp_remaining_text = EXP_REMAINING_FORMAT % MenuFormat.number(span.y - span.x)
	view.stats = stats(pokemon)
	view.moves = BattleViews.moves(pokemon, data)
	view.history = history(pokemon, zones)
	view.evolution = EvolutionReveal.chain(pokemon.species_id, data, pokedex, pokedex_visible)
	view.evolution_text = EvolutionReveal.text(view.evolution)
	return view


## Bouton du compagnon pour [param pokemon] : RAPPELER s'il est le compagnon actuel, FAIRE SORTIR
## si son espèce est éligible, rien sinon (pas de bouton grisé, A-11). Un Pokémon K.O. peut être
## choisi : il reste invisible jusqu'à sa guérison (§8.3).
static func companion_action(pokemon: Pokemon, companions: CompanionCatalog,
		companion_uid: String) -> PokemonSheetView.CompanionAction:
	if not companion_uid.is_empty() and pokemon.uid == companion_uid:
		return PokemonSheetView.CompanionAction.RECALL
	if companions != null and CompanionRules.is_eligible(pokemon, companions):
		return PokemonSheetView.CompanionAction.SEND_OUT
	return PokemonSheetView.CompanionAction.NONE


## Les six statistiques de [param pokemon] (PV = PV max), jauges relatives à la plus haute.
static func stats(pokemon: Pokemon) -> Array[StatView]:
	var views: Array[StatView] = []
	var highest := 1
	for stat: StringName in SpeciesData.STATS:
		highest = maxi(highest, pokemon.stats.get(stat, 0))
	for stat: StringName in SpeciesData.STATS:
		var value: int = pokemon.stats.get(stat, 0)
		views.append(StatView.new(stat, STAT_NAMES[stat], value, float(value) / highest))
	return views


## Onglet Histoire de [param pokemon] : lieu = nom de la **zone** de la carte de rencontre
## (un intérieur → sa ville), niveau, dresseur d'origine, date en toutes lettres.
static func history(pokemon: Pokemon, zones: ZoneLibrary) -> HistoryView:
	var view := HistoryView.new()
	view.note = STARTER_NOTE if pokemon.origin == Pokemon.Origin.STARTER else ""
	view.place_label = PLACE_LABELS[pokemon.origin]
	if zones != null and not pokemon.met_map.is_empty():
		view.place = zones.zone_name_of(pokemon.met_map)
	view.met_level = maxi(pokemon.met_level, 0)
	view.trainer = pokemon.original_trainer
	view.date_text = MenuFormat.long_date(pokemon.met_date)
	return view


## Sélection après l'échange des places [param a] et [param b] : elle suit le Pokémon
## sélectionné (sélectionné en [param a] → [param b], et inversement), sinon elle ne bouge pas.
static func selection_after_swap(selected: int, a: int, b: int) -> int:
	if selected == a:
		return b
	if selected == b:
		return a
	return selected


## [param selected] ramené dans l'équipe de [param size] membres (0 si elle est vide).
static func clamp_selection(selected: int, size: int) -> int:
	return clampi(selected, 0, maxi(size - 1, 0))
