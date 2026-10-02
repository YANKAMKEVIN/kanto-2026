class_name CaptureCardView
extends RefCounted
## Ce qu'affiche la carte de capture (CaptureCard) : des chaînes et une texture.
##
## Les textes viennent de l'appelant (modèles de messages, avec l'accord au féminin) : la carte
## ne formule rien. Le titre peut arriver en minuscules, la carte le met en capitales.

## Titre (« Roucool CAPTURÉ ! »).
var title: String = ""
## Vignette du Pokémon (sprite de face, pixel art).
var portrait: Texture2D = null
## Nouvelle entrée du Pokédex : la ligne [member pokedex_line] est affichée. Faux : pas de ligne.
var new_entry: bool = false
## « Nouvelle entrée Pokédex ».
var pokedex_line: String = ""
## « Roucool rejoint ton équipe. » ou « … a été confié au système de recherche de Chen. ».
var result_line: String = ""


func _init(
	card_title: String = "", picture: Texture2D = null, is_new_entry: bool = false,
	new_entry_line: String = "", line: String = ""
) -> void:
	title = card_title
	portrait = picture
	new_entry = is_new_entry
	pokedex_line = new_entry_line
	result_line = line


## Une vue affichable : un titre et la ligne d'équipe (la ligne Pokédex est facultative).
func is_valid() -> bool:
	return not title.strip_edges().is_empty() and not result_line.strip_edges().is_empty() \
		and (not new_entry or not pokedex_line.strip_edges().is_empty())


## La ligne « Nouvelle entrée Pokédex » est à montrer.
func shows_pokedex_line() -> bool:
	return new_entry and not pokedex_line.is_empty()
