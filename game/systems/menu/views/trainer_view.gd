class_name TrainerView
extends RefCounted
## Ce qu'affiche l'écran Dresseur (dossier 08 §6 ; jalon-06.md §3.7, §6.11) : identité,
## 8 emplacements de badges muets, grands moments, statistiques. Construit par
## [TrainerSummary] ; l'écran ne connaît ni GameState, ni les données. Contrat figé au T23.
##
## Règle d'affichage (comme [DashboardView]) : **un texte vide = un élément absent** (ni
## ligne, ni libellé, ni emplacement vide) ; une route null = pas de lien. Jamais de compteur
## de badges (« 0/8 », Q-13), de niveau, d'XP, de titre, de tenue ni de pourcentage.

## Nombre d'emplacements de badges (toujours tous affichés, Q-13).
const BADGE_COUNT: int = 8
## Libellés de l'écran (textes d'interface validés par Kevin le 2026-10-06).
const BADGES_TITLE: String = "Badges"
const MOMENTS_TITLE: String = "Grands moments"
const STATS_TITLE: String = "Statistiques"
const STARTED_LABEL: String = "Début de l'aventure"
## Libellé de l'argent (J7).
const MONEY_LABEL: String = "Argent"
## Phrase de la frise quand aucun moment n'existe encore (prologue).
const MOMENTS_EMPTY_TEXT: String = "Ton aventure ne fait que commencer."
## Titre de la section de l'équipe (MM.2, texte à relire par Kevin).
const TEAM_TITLE: String = "Équipe actuelle"

## Identité.
var player_name: String = ""
var player_title: String = ""
## « 12 h 43 ».
var play_time_text: String = ""
## Date de départ (« 2 octobre 2026 », à écrire après [constant STARTED_LABEL]) ; "" si
## inconnue.
var started_text: String = ""
## Argent du joueur, « 3 000 ₽ » (dossier 09 §10 ; J7, Q-8 : visible dès le début), à écrire
## après [constant MONEY_LABEL].
var money_text: String = ""
## « 3 vus », « 2 capturés » : "" tant que le Pokédex n'est pas visible (règle de déblocage).
var seen_text: String = ""
var caught_text: String = ""
## Liens de « vus » et « capturés » (Pokédex filtré) ; null quand le texte est vide.
var seen_route: MenuRoute = null
var caught_route: MenuRoute = null
## Toujours [constant BADGE_COUNT] emplacements, dans l'ordre des arènes ([method
## BadgeLibrary.slots] depuis le MM.2 : un badge non obtenu ne porte ni nom ni image, l'écran
## montre une silhouette commune et « ??? »).
var badges: Array[BadgeSlotView] = []
## Zone où se tient le joueur (décor de son portrait, MM.2) ; &"" si inconnue.
var zone_id: StringName = &""
## Équipe actuelle, dans l'ordre de l'équipe (MM.2) ; vide = section absente.
var team: Array[TeamMemberView] = []
## Grands moments, du plus ancien au plus récent ; vide → [constant MOMENTS_EMPTY_TEXT].
var moments: Array[MomentView] = []
## Statistiques, dans l'ordre d'affichage ; une statistique à 0 est absente.
var stats: Array[TrainerStatView] = []


## Nombre de badges obtenus (pour un futur affichage du détail ; jamais « n / 8 »).
func obtained_badges() -> int:
	var count := 0
	for badge: BadgeSlotView in badges:
		if badge.obtained:
			count += 1
	return count


## Statistique [param stat_id], ou null si absente.
func stat(stat_id: StringName) -> TrainerStatView:
	for line: TrainerStatView in stats:
		if line.stat_id == stat_id:
			return line
	return null
