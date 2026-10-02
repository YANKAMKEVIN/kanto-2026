class_name MenuCardView
extends RefCounted
## Une grande carte du tableau de bord (dossier 08 §1) : l'écran qu'elle ouvre, son titre et
## une ligne de description. Contrat figé au T2 (jalon-06.md §6.5).

## Écran ouvert ([constant MenuRoute.TEAM]…) ; c'est ce que [code]card_chosen[/code] émet.
var screen: StringName = &""
## Titre (« Équipe » ; la carte choisit sa casse).
var title: String = ""
## Ligne de description (« Gérez vos Pokémon et leurs capacités. »).
var caption: String = ""


func _init(screen_id: StringName = &"", card_title: String = "", card_caption: String = "") \
		-> void:
	screen = screen_id
	title = card_title
	caption = card_caption
