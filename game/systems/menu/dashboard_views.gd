class_name DashboardViews
extends RefCounted
## Traduit l'état de la partie en [DashboardView] (dossier 08 §1, jalon-06.md §3.2). Classe
## pure, statique : appelée par MenuDirector (T4) à chaque ouverture du tableau de bord.

## Préfixe de la ligne d'objectif (dossier 08 §1 : « Objectif : rejoindre Jadielle. »).
const OBJECTIVE_PREFIX: String = "Objectif : "
## Sous-titre de la carte du Dresseur.
const PLAYER_TITLE: String = "Dresseur Pokémon"
## Titre et ligne de description de chaque carte (textes d'interface validés par Kevin le 2026-10-06).
## Pas d'AUDIO aux Paramètres (Q-17).
const CARD_TEXTS: Dictionary[StringName, Array] = {
	MenuRoute.TEAM: ["Équipe", "Tes Pokémon et leurs capacités."],
	MenuRoute.POKEDEX: ["Pokédex", "Les Pokémon que tu as observés."],
	MenuRoute.BAG: ["Sac", "Utilise et range tes objets."],
	MenuRoute.MAP: ["Carte", "Kanto et tes découvertes."],
	MenuRoute.TRAINER: ["Dresseur", "Ton profil et ton parcours."],
	MenuRoute.SETTINGS: ["Paramètres", "Jeu, commandes, graphismes et accessibilité."],
}


## Vue du tableau de bord pour [param state] (l'autoload GameState, ou une instance de
## game_state.gd en test). [param zones] et [param objectives] peuvent être null (pas de nom
## de zone, pas d'objectif) ; [param badges] null : pas de ligne des badges.
static func build(state: Object, data: PokemonData, zones: ZoneLibrary,
		objectives: ObjectiveLibrary, unlocks: MenuUnlocks,
		badges: BadgeLibrary = null) -> DashboardView:
	var view := DashboardView.new()
	var flags: StoryFlags = state.flags
	var party: Party = state.party
	var pokedex: Pokedex = state.pokedex
	view.zone_name = zones.zone_name_of(state.current_map) if zones != null else ""
	view.player_name = state.player_name
	view.player_title = PLAYER_TITLE
	view.play_time_text = play_time_text(state.play_time)
	if unlocks.pokedex_visible():
		view.dex_text = dex_text(pokedex.seen_count(), pokedex.caught_count())
	if badges != null:
		view.badges_text = badges_text(badges.obtained_count(flags))
	var lead := party.get_lead()
	if lead != null and unlocks.team_visible():
		view.lead = member(lead, 0, data)
	for screen: StringName in unlocks.dashboard_cards():
		var texts: Array = CARD_TEXTS[screen]
		view.cards.append(MenuCardView.new(screen, texts[0], texts[1]))
	var objective := objectives.current(flags) if objectives != null else ""
	view.objective_text = OBJECTIVE_PREFIX + objective if not objective.is_empty() else ""
	return view


## Membre de l'équipe [param pokemon], à la place [param index] : nom, sexe, niveau, PV,
## statut en texte, favori. Réutilisé par la liste de l'Équipe (T6).
static func member(pokemon: Pokemon, index: int, data: PokemonData) -> TeamMemberView:
	var view := TeamMemberView.new()
	view.party_index = index
	view.species_id = pokemon.species_id
	view.dex_number = data.get_species(pokemon.species_id).dex \
		if data != null and data.has_species(pokemon.species_id) else 0
	view.display_name = pokemon.display_name(data)
	view.gender = BattleViews.card_gender(pokemon.gender)
	view.level = pokemon.level
	view.max_hp = maxi(pokemon.max_hp(), 1)
	view.hp = clampi(pokemon.hp, 0, view.max_hp)
	view.status_text = TeamMemberView.STATUS_FAINTED if pokemon.is_fainted() else ""
	view.favorite = pokemon.favorite
	return view


## Temps de jeu affiché : « 0 h 07 », « 12 h 43 » ([method MenuFormat.play_time]).
static func play_time_text(seconds: float) -> String:
	return MenuFormat.play_time(seconds)


## « 27 vus · 14 capturés » (singulier : « 1 vu · 1 capturé »). Jamais de « / 151 ».
static func dex_text(seen: int, caught: int) -> String:
	return "%s · %s" % [seen_text(seen), caught_text(caught)]


## Ligne des badges : « 1 badge », « 2 badges » ; "" sans badge (Q-13 : jamais « 0 badge »).
static func badges_text(count: int) -> String:
	if count <= 0:
		return ""
	return "%s %s" % [MenuFormat.number(count), "badge" if count == 1 else "badges"]


## « 27 vus », « 1 vu », « 0 vu » (écran Dresseur : un lien chacun).
static func seen_text(seen: int) -> String:
	return "%s %s" % [MenuFormat.number(seen), "vu" if seen <= 1 else "vus"]


## « 14 capturés », « 1 capturé », « 0 capturé ».
static func caught_text(caught: int) -> String:
	return "%s %s" % [MenuFormat.number(caught), "capturé" if caught <= 1 else "capturés"]
