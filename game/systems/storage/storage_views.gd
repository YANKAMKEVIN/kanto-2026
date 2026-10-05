class_name StorageViews
extends RefCounted
## Traduit l'équipe et le stockage en [StorageView] pour l'écran Stockage, et les résultats de
## [StorageRules] en textes (dossier 09 §8, §19 ; jalon-07.md §3.5). Classe pure, statique :
## appelée par MenuDirector (T16) à l'entrée de l'écran et après chaque action.
##
## Libellés et textes **validés** (dossier 09 §19) sauf ceux marqués « draft » (lot de textes
## du jalon-07.md §12, à relire par Kevin).

const ACTION_DEPOSIT: StringName = &"deposit"
const ACTION_WITHDRAW: StringName = &"withdraw"
const ACTION_FAVORITE: StringName = &"favorite"
const ACTION_RELEASE: StringName = &"release"

const PARTY_TITLE: String = "ÉQUIPE"
const STORAGE_TITLE: String = "STOCKAGE"
const DEPOSIT_LABEL: String = "DÉPOSER"
const WITHDRAW_LABEL: String = "REPRENDRE"
const FAVORITE_LABEL: String = "FAVORI"
const RELEASE_LABEL: String = "LIBÉRER"
const BACK_LABEL: String = "RETOUR"
const CANCEL_LABEL: String = "ANNULER"
## Confirmation de LIBÉRER ({Pokémon} = nom affiché).
const RELEASE_TITLE: String = "Libérer %s ?"
const RELEASE_DETAIL: String = "Il quittera définitivement ton équipe et ton stockage."
## Raisons des refus.
const LAST_POKEMON_TEXT: String = "Tu dois garder au moins un Pokémon avec toi."
const FAVORITE_TEXT: String = "Retire d'abord %s de tes favoris pour pouvoir le libérer."
## draft (jalon-07.md §12, « Textes à relire »).
const PARTY_FULL_TEXT: String = "Ton équipe est déjà complète."
## draft (jalon-07.md §12).
const EMPTY_TEXT: String = "Le stockage est vide."


## Vue de l'écran pour l'équipe et le stockage de [param state] (GameState : [code]party[/code],
## [code]storage[/code], [code]pokedex[/code]), avec [param selection] ramenée dans les listes.
## [param zones] peut être null (lieux de l'Histoire vides) ; [param unlocks] décide de la
## révélation de l'évolution dans la fiche (rien du Pokédex avant son activation).
static func build(state: Object, data: PokemonData, selection: StorageSelection,
		zones: ZoneLibrary = null, unlocks: MenuUnlocks = null) -> StorageView:
	var party: Party = state.party
	var storage: PokemonStorage = state.storage
	var view := StorageView.new()
	view.party_title = PARTY_TITLE
	view.storage_title = STORAGE_TITLE
	view.back_label = BACK_LABEL
	view.selection = selection.clamped(party, storage) if selection != null \
		else StorageSelection.first(party, storage)
	var members := party.get_all()
	for i: int in members.size():
		view.party.append(card(members[i], StorageRules.Place.PARTY, i, data, view.selection))
	var stored := storage.get_all()
	for i: int in stored.size():
		view.storage.append(card(stored[i], StorageRules.Place.STORAGE, i, data, view.selection))
	view.empty_text = EMPTY_TEXT if stored.is_empty() else ""
	if view.selection.is_empty():
		return view
	var pokemon := StorageRules.get_pokemon(party, storage, view.selection.place,
		view.selection.index)
	var visible := unlocks != null and unlocks.pokedex_visible()
	view.sheet = TeamViews.sheet(pokemon, view.selection.index, data, zones, state.pokedex,
		visible)
	if view.selection.place == StorageRules.Place.PARTY:
		view.actions.append(StorageActionView.new(ACTION_DEPOSIT, DEPOSIT_LABEL))
	else:
		view.actions.append(StorageActionView.new(ACTION_WITHDRAW, WITHDRAW_LABEL))
	view.actions.append(StorageActionView.new(ACTION_FAVORITE, FAVORITE_LABEL, pokemon.favorite))
	view.more_actions.append(StorageActionView.new(ACTION_RELEASE, RELEASE_LABEL))
	return view


## Carte de [param pokemon], à [param index] de la liste [param place].
static func card(pokemon: Pokemon, place: StorageRules.Place, index: int, data: PokemonData,
		selection: StorageSelection = null) -> StorageCardView:
	var view := StorageCardView.new()
	view.place = place
	view.index = index
	view.member = DashboardViews.member(pokemon, index, data)
	view.selected = selection != null and selection.equals(StorageSelection.new(place, index))
	return view


## Confirmation de LIBÉRER (deux cartes, jamais « Oui / Non ») pour [param name].
static func release_choice(name: String) -> ChoiceView:
	var view := ChoiceView.new(RELEASE_TITLE % name, RELEASE_LABEL, CANCEL_LABEL)
	view.detail = RELEASE_DETAIL
	return view


## Raison d'un refus ([param name] = nom affiché du Pokémon) ; "" pour OK et NOT_FOUND (rien à
## dire : l'écran ne montre que ce qui existe).
static func status_text(status: StorageRules.Status, name: String) -> String:
	match status:
		StorageRules.Status.LAST_POKEMON:
			return LAST_POKEMON_TEXT
		StorageRules.Status.PARTY_FULL:
			return PARTY_FULL_TEXT
		StorageRules.Status.FAVORITE:
			return FAVORITE_TEXT % name
	return ""


## Texte de [param result] ([method status_text] avec le nom du Pokémon concerné). Un succès
## n'a pas de texte (la carte qui bouge suffit ; défaut du T14).
static func result_text(result: StorageResult, data: PokemonData) -> String:
	if result == null:
		return ""
	var name := result.pokemon.display_name(data) if result.pokemon != null else ""
	return status_text(result.status, name)
