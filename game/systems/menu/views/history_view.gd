class_name HistoryView
extends RefCounted
## Onglet Histoire de la fiche Équipe (dossier 08 §2 : lieu, niveau de rencontre, dresseur
## d'origine, date ; jalon-06.md §3.3), d'après la rencontre enregistrée depuis le 5C.5
## ([member Pokemon.met_map]…). Contrat figé au T6.
##
## Règle d'affichage (comme [DashboardView]) : **un texte vide = une ligne absente** ;
## [member met_level] 0 = pas de ligne de niveau. Tout vide ([method is_empty]) : une
## sauvegarde d'avant le 5C.5 ; l'écran affiche alors [constant TeamViews.HISTORY_UNKNOWN].

## Petite phrase d'attachement : « Ton premier Pokémon » pour le starter, sinon "".
var note: String = ""
## Libellé de la ligne de lieu selon la manière : « Reçu à », « Capturé à », « Rencontré à ».
var place_label: String = ""
## Nom de la **zone** (« Bourg Palette » pour le labo du Prof. Chen) ; "" si inconnu.
var place: String = ""
## Niveau à la rencontre ; 0 = inconnu.
var met_level: int = 0
## Dresseur d'origine (« Kevin ») ; "" si inconnu.
var trainer: String = ""
## Date (« 2 octobre 2026 », « 1er novembre 2026 ») ; "" si inconnue.
var date_text: String = ""


func is_empty() -> bool:
	return place.is_empty() and met_level <= 0 and trainer.is_empty() and date_text.is_empty()
