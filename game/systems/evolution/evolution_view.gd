class_name EvolutionView
extends RefCounted
## Ce que l'écran d'évolution montre pour une évolution (jalon-09.md §2.3.3), préparé par
## [EvolutionDirector] **avant** l'évolution : le nom affiché est celui d'avant (sans surnom,
## « Chenipan », jamais « Chrysacier a évolué en Chrysacier »). Donnée pure, textes déjà
## remplis (lot verrouillé le 2026-10-07, bloc B) ; l'écran n'écrit aucun texte de jeu.

## Place du Pokémon dans l'équipe.
var party_index: int = -1
## Nom affiché avant l'évolution (surnom, sinon l'ancienne espèce).
var pokemon_name: String = ""
var from_species: StringName = &""
var into_species: StringName = &""
## Noms des deux espèces (« Chenipan », « Chrysacier »).
var from_name: String = ""
var into_name: String = ""
## Numéros du Pokédex national des deux espèces : artworks officiels et silhouettes
## ([method PokedexArt.portrait], [method PokedexArt.silhouette_material]).
var from_dex: int = 0
var into_dex: int = 0
## « Quoi ? Chenipan évolue ! »
var started_text: String = ""
## « Félicitations ! Chenipan a évolué en Chrysacier ! »
var finished_text: String = ""
## « Hein ? Chenipan n'évolue plus. »
var cancelled_text: String = ""
## Libellé du bouton d'annulation (« ARRÊTER »).
var stop_label: String = ""
## Consigne des moments qui attendent un toucher (« Touchez l'écran pour continuer »).
var continue_text: String = ""
