class_name FlashRules
extends RefCounted
## Flash hors combat dans les cartes obscures (jalon 17 T24 ; dossier 20 §8.1, H-7 ; dossier 21
## §5.3 aligné le 2026-10-15). Classe pure, contrat commun avec le J18 (`jalon-18.md` §3.2) dans
## la réponse de Kevin à Q-1 (« tout J17 », 2026-10-16) :
## - **automatique** : à chaque arrivée sur une carte obscure ([method CaveLibrary.is_dark]),
##   changement d'étage compris, Flash se rallume si elle est disponible (CS05 au Sac et un
##   Pokémon compatible, [FieldMoves]) ; sinon, l'avertissement (une fois par arrivée) ;
## - **aucun drapeau « allumée »** : rien n'est sauvegardé ; une reprise de partie dans la grotte
##   compte comme une arrivée (carte de départ vide), Flash s'y rallume de la même façon.
## Pas de proposition (OFFER du dossier 21 abandonnée) ni de règle d'extinction : quitter la carte
## suffit (le voile est reposé à chaque changement de carte).

## Ce que déclenche une arrivée : rien, la mise en scène de Flash, ou l'avertissement.
enum Entry { NONE, AUTO, WARN }


## Vrai si l'on arrive sur [param to_map] depuis une autre carte, ou au démarrage
## ([param from_map] vide : Continuer, départ de débogage).
static func is_entry(from_map: StringName, to_map: StringName) -> bool:
	return from_map != to_map


## Action d'arrivée sur [param to_map] : AUTO si elle est obscure et Flash [param available],
## WARN si elle est obscure sans Flash, NONE si elle ne l'est pas ou si ce n'est pas une arrivée.
static func entry_action(from_map: StringName, to_map: StringName, caves: CaveLibrary,
		available: bool) -> Entry:
	if caves == null or not caves.is_dark(to_map) or not is_entry(from_map, to_map):
		return Entry.NONE
	return Entry.AUTO if available else Entry.WARN


## Halo de Flash ouvert **dès l'écran noir** ([method DarknessController.set_map]) : seulement
## sur une carte obscure où l'on n'arrive pas (rechargement de la même carte) avec Flash
## disponible. À une arrivée, le voile est posé sombre et la mise en scène l'ouvre.
static func is_lit(from_map: StringName, to_map: StringName, caves: CaveLibrary,
		available: bool) -> bool:
	return available and caves != null and caves.is_dark(to_map) \
		and not is_entry(from_map, to_map)
