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
## T-5, montré en titre quand une place refusée est touchée.
var refused_title: String = ""


func can_pick(index: int) -> bool:
	return party != null and party.get_at(index) != null and not refusals.has(index)


## Raison du refus de la place [param index] ("" si elle peut être confiée).
func refusal_text(index: int) -> String:
	return refusals.get(index, "")
