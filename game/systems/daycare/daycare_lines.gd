class_name DaycareLines
extends RefCounted
## Quelle réplique de la Pension jouer (J15, jalon-15.md §2.5.2, §0.2 n° 3) : les variantes de
## dialogue ne lisent que des drapeaux, or T-2 / T-7 / T-8 / T-9 dépendent de l'état de la
## Pension. Cette classe pure choisit donc **l'identifiant** du dialogue ; les textes restent dans
## `data/dialogues/route_5_daycare.json` (dossier 18 §15.1, mot pour mot). Aucun drapeau
## « miroir » de l'état. Elle donne aussi les valeurs des jetons et la vue du dépôt.

## Le gardien (PNJ) : action `open_daycare` seule, sans page.
const KEEPER: StringName = &"daycare_keeper"
## T-2 + choix (Non → T-3).
const OFFER: StringName = &"daycare_offer"
## T-4.
const PICK: StringName = &"daycare_pick"
## T-5 (titre de l'écran du dépôt quand une place refusée est touchée).
const LAST_ABLE: StringName = &"daycare_last_able"
## T-6.
const DEPOSITED: StringName = &"daycare_deposited"
## T-7 + choix (aucun niveau gagné).
const VISIT: StringName = &"daycare_visit"
## T-8 + choix (niveaux gagnés).
const VISIT_LEVELS: StringName = &"daycare_visit_levels"
## T-9.
const PARTY_FULL: StringName = &"daycare_party_full"
## T-10.
const RETURNED: StringName = &"daycare_returned"
## T-11 (argent insuffisant, tout l'argent pris).
const RETURNED_SHORT: StringName = &"daycare_returned_short"
## T-12.
const AFTER: StringName = &"daycare_after"
## Dialogues joués par le [DaycareDirector] (tous sauf celui du gardien).
const PLAYED_BY_DIRECTOR: Array[StringName] = [
	OFFER, PICK, LAST_ABLE, DEPOSITED, VISIT, VISIT_LEVELS, PARTY_FULL, RETURNED, RETURNED_SHORT,
	AFTER,
]


## Dialogue qui ouvre la visite : Pension vide → T-2 ; équipe pleine → T-9 ; sinon T-7 (aucun
## niveau) ou T-8. &"" pour un refus sans réplique validée (NO_MONEY, politique « refuse »).
static func for_visit(preview: DaycarePreview) -> StringName:
	if preview == null:
		return &""
	match preview.status:
		DaycareRules.Status.EMPTY:
			return OFFER
		DaycareRules.Status.PARTY_FULL:
			return PARTY_FULL
		DaycareRules.Status.OK:
			return VISIT_LEVELS if preview.levels_gained > 0 else VISIT
	return &""


## Réplique du retrait : T-11 si l'argent n'a pas couvert le prix, sinon T-10.
static func for_withdrawal(plan: DaycareWithdrawal) -> StringName:
	return RETURNED_SHORT if plan != null and plan.paid < plan.price else RETURNED


## Réplique d'un refus : dépôt du dernier apte → T-5 ; équipe pleine → T-9 ; sinon &"".
static func for_refusal(status: DaycareRules.Status) -> StringName:
	match status:
		DaycareRules.Status.LAST_POKEMON, DaycareRules.Status.LAST_ABLE:
			return LAST_ABLE
		DaycareRules.Status.PARTY_FULL:
			return PARTY_FULL
	return &""


## Valeurs des jetons `{pokemon}` (nom affiché), `{levels}`, `{price}` (nombre formaté, sans
## « ₽ ») ; vide sans Pokémon.
static func token_values(pokemon: Pokemon, levels: int, price: int,
		data: PokemonData) -> Dictionary[StringName, String]:
	var values: Dictionary[StringName, String] = {}
	if pokemon == null or data == null:
		return values
	values[DialogueTokens.POKEMON] = pokemon.display_name(data)
	values[DialogueTokens.LEVELS] = str(maxi(levels, 0))
	values[DialogueTokens.PRICE] = MenuFormat.number(maxi(price, 0))
	return values


## Vue de l'écran du dépôt : chaque place de [param party] et sa raison de refus éventuelle.
static func pick_view(daycare: Daycare, party: Party, refused_title: String) -> DaycarePickView:
	var view := DaycarePickView.new()
	view.party = party
	view.refused_title = refused_title
	if party == null:
		return view
	for index: int in party.size():
		match DaycareRules.can_deposit(daycare, party, index):
			DaycareRules.Status.LAST_POKEMON:
				view.refusals[index] = StorageViews.LAST_POKEMON_TEXT
			DaycareRules.Status.LAST_ABLE:
				view.refusals[index] = StorageViews.LAST_ABLE_TEXT
	return view
