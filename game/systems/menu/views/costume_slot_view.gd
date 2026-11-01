class_name CostumeSlotView
extends RefCounted
## Un costume de la section « Costumes » de l'écran Dresseur (dossier-costumes.md, CO-1, CO-2,
## CO-6). Construit par [TrainerSummary].
##
## Un costume **verrouillé** (badge manquant) ne porte ni nom ni badge (CO-2) : seule sa
## silhouette noire est montrée, et le toucher dit [constant TrainerView.COSTUME_LOCKED_TEXT].
## La tenue d'origine ([member costume_id] vide) est toujours débloquée, en première place (CO-6).

## Identifiant du costume ([CostumeCatalog]) ; &"" = la tenue d'origine.
var costume_id: StringName = &""
var unlocked: bool = false
## Vrai pour le costume porté (un seul de la section).
var worn: bool = false
## Nom affiché (CO-10) ; "" si verrouillé.
var name: String = ""
## Apparence du monde ([CharacterLook]) : vignette, ou silhouette si verrouillé.
var sprite: StringName = &""
