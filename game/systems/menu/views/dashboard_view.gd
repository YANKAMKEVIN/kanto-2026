class_name DashboardView
extends RefCounted
## Ce qu'affiche le tableau de bord du Menu Dresseur (dossier 08 §1, jalon-06.md §3.2) :
## des chaînes, des nombres et des sous-vues. Construit par [DashboardViews] ; l'écran ne
## connaît ni GameState, ni les données.
##
## Contrat figé au T2 (§6.5) : T3 fabrique ces vues à la main, T4 les construit pour de vrai.
## Règle d'affichage : **un texte vide = un élément absent** (ni ligne, ni icône, ni emplacement
## vide) ; [member lead] null = pas de carte du Pokémon de tête.

## En-tête : nom de la zone actuelle (« Route 1 », « Bourg Palette » dans un intérieur ;
## "" si la carte n'appartient à aucune zone).
var zone_name: String = ""
## Carte du Dresseur.
var player_name: String = ""
var player_title: String = ""
## Temps de jeu (« 12 h 43 »).
var play_time_text: String = ""
## « 27 vus · 14 capturés » ; "" tant que le Pokédex n'est pas visible (règle de déblocage).
var dex_text: String = ""
## Ligne des badges ; "" avant le premier badge (Q-13 : pas de « 0 badge ») — toujours "" au J6.
var badges_text: String = ""
## Pokémon de tête (null si l'équipe est vide, Q-2).
var lead: TeamMemberView = null
## Cartes, dans l'ordre d'affichage : 4 à 6 (ÉQUIPE et POKÉDEX peuvent manquer), jamais
## d'emplacement vide.
var cards: Array[MenuCardView] = []
## Ligne entière (« Objectif : rejoindre Jadielle. ») ; "" = pas de ligne.
var objective_text: String = ""


## Écrans des cartes, dans l'ordre (tests, journaux).
func card_screens() -> Array[StringName]:
	var screens: Array[StringName] = []
	for card: MenuCardView in cards:
		screens.append(card.screen)
	return screens
