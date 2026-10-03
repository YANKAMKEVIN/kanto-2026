class_name TeamView
extends RefCounted
## Ce qu'affiche l'écran Équipe (dossier 08 §2, jalon-06.md §3.3) : la liste et la fiche de
## **chaque** membre, dans l'ordre de l'équipe. Construit par [TeamViews] ; l'écran change de
## Pokémon sélectionné sans rien redemander ([code]member_selected[/code] est informatif).
## Contrat figé au T6.

## Emplacements de la liste (les vides sont neutres et sans action, dossier 08 §2).
const SLOT_COUNT: int = Party.MAX_SIZE

## Membres, dans l'ordre (0 = Pokémon de tête) ; [member TeamMemberView.party_index] = place.
var members: Array[TeamMemberView] = []
## Fiches, même ordre que [member members].
var sheets: Array[PokemonSheetView] = []


func size() -> int:
	return members.size()


## Fiche de la place [param index], ou null.
func sheet_at(index: int) -> PokemonSheetView:
	return sheets[index] if index >= 0 and index < sheets.size() else null
