class_name DaycarePickView
extends RefCounted
## Ce que l'écran du dépôt montre (J15, jalon-15.md §2.5.3 ; écran : `DaycareOverlay`, T5) :
## toute l'équipe, dans l'ordre ; une place refusée garde **sa raison** (règle du Stockage :
## `StorageViews.LAST_POKEMON_TEXT` / `LAST_ABLE_TEXT`) et la toucher affiche [member refused_title]
## (T-5) en titre. Donnée pure, construite par [method DaycareLines.pick_view].

## L'équipe (lecture seule pour l'écran).
var party: Party = null
## Place → raison du refus (absente : la place peut être confiée).
var refusals: Dictionary[int, String] = {}
## Titre de l'écran du dépôt (texte d'interface court, jalon-15.md T5).
const TITLE: String = "Confier un Pokémon"

## T-5, montré en titre quand une place refusée est touchée.
var refused_title: String = ""


func can_pick(index: int) -> bool:
	return party != null and party.get_at(index) != null and not refusals.has(index)


## Raison du refus de la place [param index] ("" si elle peut être confiée).
func refusal_text(index: int) -> String:
	return refusals.get(index, "")


## Le choix pour [PartyPicker] : toute l'équipe, titre [constant TITLE] ; une place refusée est une
## carte inutilisable qui montre **sa raison**, et sa phrase de refus (T-5) vient en titre au
## toucher. [param data] donne les noms et numéros du Pokédex.
func to_picker_view(data: PokemonData) -> PartyPickerView:
	var picker := PartyPickerView.new()
	picker.title = TITLE
	if party == null:
		return picker
	var members := party.get_all()
	for i: int in members.size():
		var reason := refusal_text(i)
		picker.targets.append(PartyTargetView.new(DashboardViews.member(members[i], i, data),
			reason.is_empty(), reason, refused_title))
	return picker
