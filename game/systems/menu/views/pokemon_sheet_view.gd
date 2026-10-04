class_name PokemonSheetView
extends RefCounted
## Fiche d'un Pokémon de l'équipe (écran Équipe, dossier 08 §2 ; jalon-06.md §3.3) : en-tête,
## onglets Aperçu · Capacités · Histoire, évolution. Des chaînes, des nombres et des sous-vues :
## l'écran ne connaît ni [Pokemon] ni les données. Construit par [TeamViews].
##
## Contrat figé au T6 : les champs ne changent ni de nom ni de sens (l'architecte peut en
## ajouter). Règle d'affichage : **un texte vide = un élément absent**.

## En-tête et liste : nom, sexe, Nv., PV, statut en texte, favori, place, espèce (sprite).
var member: TeamMemberView = null
## Nom de l'espèce (« Salamèche ») : égal au nom affiché tant qu'il n'y a pas de surnoms.
var species_name: String = ""
## 1 ou 2 types : identifiants (couleurs, icônes : TypeBadge) et noms affichés, même ordre.
var type_ids: Array[StringName] = []
var type_names: Array[String] = []
## Barre d'XP du niveau, 0..1 (1 au niveau 100).
var exp_fraction: float = 0.0
## « 320 / 560 XP » ; "" au niveau 100 (barre pleine, pas de texte).
var exp_text: String = ""
## « 240 XP avant le niveau suivant » ; "" au niveau 100.
var exp_remaining_text: String = ""
## Aperçu : PV, Attaque, Défense, Atq. Spé., Déf. Spé., Vitesse, dans cet ordre.
var stats: Array[StatView] = []
## Capacités : 1 à 4 cartes (MoveCard ; un toucher ouvre MoveDetailSheet).
var moves: Array[BattleMoveView] = []
## Histoire.
var history: HistoryView = null
## Évolution (Q-9) : stades révélés ou « ??? », jamais de condition ; vide = pas de section
## (lignée d'une seule espèce).
var evolution: Array[EvolutionStageView] = []
## La même chose en une ligne (« Salamèche → Reptincel → ??? » ; « ??? » avant l'activation
## du Pokédex) ; l'écran la préfixe de « Évolution : ». "" = pas de section.
var evolution_text: String = ""


## Vue affichable : un membre valide, au moins un type, six statistiques, une capacité, une
## histoire (éventuellement vide).
func is_valid() -> bool:
	return member != null and member.is_valid() and not type_ids.is_empty() \
		and type_ids.size() == type_names.size() and stats.size() == SpeciesData.STATS.size() \
		and not moves.is_empty() and history != null
