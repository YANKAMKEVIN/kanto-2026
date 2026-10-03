class_name PartyPickerView
extends RefCounted
## Le choix du Pokémon après UTILISER (dossier 08 §3, jalon-06.md §3.4) : toute l'équipe avec
## ses PV, dans l'ordre, chaque membre utilisable ou avec sa raison. Le même dans le Sac du
## menu et en combat. Construit par [method BagQuery.targets]. Contrat figé au T10 (§6.8).

var item_id: StringName = &""
## Nom de l'objet au singulier (« Potion ») et quantité restante (l'écran écrit « ×3 »).
var item_name: String = ""
var quantity: int = 0
## Un par membre de l'équipe, dans l'ordre (0 = Pokémon de tête).
var targets: Array[PartyTargetView] = []
## Membre mis en avant (UTILISER À NOUVEAU : le même Pokémon) ; −1 = aucun.
var selected: int = -1


func size() -> int:
	return targets.size()


## Cible de la place [param index], ou null.
func target_at(index: int) -> PartyTargetView:
	return targets[index] if index >= 0 and index < targets.size() else null


## Vrai si au moins un membre peut recevoir l'objet.
func has_usable() -> bool:
	for target: PartyTargetView in targets:
		if target.usable:
			return true
	return false
