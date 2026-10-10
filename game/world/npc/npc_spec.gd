class_name NpcSpec
extends RefCounted
## Description d'un PNJ ou d'un Pokémon du décor sur une carte, lue dans
## `data/npcs/<map_id>.json` par [NpcRoster] (docs/tech/jalon-03.md §2.3).
##
## Donnée pure : la scène `Npc` s'en sert pour se placer, s'afficher et répondre au joueur.
## En lecture seule une fois construite : un PNJ qui marche (jalon 3B) garde sa case courante
## dans son GridMover, [member cell] reste sa case de départ.

## Styles de saut d'un Pokémon qui descend d'un meuble ([member hop_style], jalon 4,
## décision de Kevin n° 1) : calme (Bulbizarre), enthousiaste (Salamèche), vif et joueur
## (Carapuce). Les paramètres de chaque style (durée, hauteur, rebonds, hésitation) sont
## des constantes de la scène `Npc` (présentation), pas des données.
const HOP_STYLES: Array[StringName] = [&"calm", &"eager", &"playful"]

## Réactions d'un Pokémon d'ambiance à l'approche du joueur ([member shy_action], jalon 5
## §3.5, dossier 04 §1) : s'envoler (Roucool posé sur une clôture) ou détaler (Rattata).
## Jalon 9 (dossier 10 §7, jalon-09.md §2.7.6) : « notice » relève la tête (animation
## « react ») et reste sur la carte (Chenipan) ; « hide » se rétracte vers le feuillage (petit
## recul vers le haut et fondu) puis quitte la carte comme l'envol (Aspicot sur un tronc).
## Réservé aux Pokémon non interactifs (un Pokémon qui fuit ne se parle pas). Un Pokémon
## d'ambiance immobile et non interactif peut être posé sur une case infranchissable (tronc,
## branche basse, clôture) : il l'occupe sans la rendre praticable.
const SHY_ACTIONS: Array[StringName] = [&"fly", &"flee", &"notice", &"hide"]
## Rayon par défaut (cases) d'une réaction « shy » quand la donnée l'omet.
const SHY_RADIUS_DEFAULT: int = 2
## Pause par défaut (secondes) à chaque case d'une routine de marche quand la donnée l'omet.
const ROUTE_PAUSE_DEFAULT: float = 1.2
## Pas de case d'entrée dans un bâtiment ([member route_enter_cell]).
const NO_ENTER_CELL: Vector2i = Vector2i(-1, -1)
## Bornes des données du jalon 7 (lues par [NpcRoster]) : absence dans un bâtiment et
## période de l'animation d'ambiance, en secondes.
const ROUTE_ENTER_SECONDS_MAX: float = 120.0
const IDLE_REACT_MAX: float = 120.0
## Attente animée (jalon 7, Jadielle agrandie : « aucun habitant figé ») : période par
## défaut entre deux changements d'orientation, et ses bornes (secondes).
const LOOK_EVERY_DEFAULT: float = 3.5
const LOOK_EVERY_MIN: float = 0.5
const LOOK_EVERY_MAX: float = 120.0

## Identifiant unique sur la carte (cible des indications « react » des dialogues).
var id: StringName = &""
var cell: Vector2i = Vector2i.ZERO
## Orientation au repos (celle qu'il reprend après un dialogue, voir [member keep_facing]).
var facing: Vector2i = Vector2i.DOWN
## Nom de l'apparence : la scène `Npc` charge les SpriteFrames `<sprite>_frames.tres`.
var sprite: StringName = &""
## Dialogue joué quand on interagit ; vide = pas d'interaction (Roucool de Mme Aoki).
var dialogue: StringName = &""
## Verbe du bouton contextuel ([enum Interaction.Kind]) : parler (défaut), observer ou
## prendre (objet visible au sol, jalon 8 §2.3).
var verb: Interaction.Kind = Interaction.Kind.TALK
## Se tourne vers le joueur dès qu'on lui parle (faux : seulement sur une page face_player).
var turn_to_player: bool = true
## Garde l'orientation prise pendant le dialogue au lieu de reprendre [member facing].
var keep_facing: bool = false
## Élévation du sprite en pixels (Pokémon posé sur une table) ; la case et le tri en
## profondeur ne changent pas.
var lift: int = 0
## Style de saut ([constant HOP_STYLES]) quand une scène le fait sauter (étape « hop ») ;
## vide = saut par défaut.
var hop_style: StringName = &""
## Réaction d'ambiance ([constant SHY_ACTIONS]) déclenchée quand le joueur approche à
## [member shy_radius] cases ou moins ; vide = aucune (PNJ ordinaire, Pokémon immobile).
var shy_action: StringName = &""
## Rayon de déclenchement de [member shy_action], en cases (distance de Manhattan).
var shy_radius: int = SHY_RADIUS_DEFAULT
## Routine de marche (jalon 5, dossier 07 §5 : le Voyageur) : liste de cases **voisines**
## parcourues en boucle (aller-retour = inclure le retour), pause à chaque case. Vide =
## PNJ immobile. Le PNJ ne quitte jamais ces cases ; à définir hors des hautes herbes et
## du passage principal.
var route_cells: Array[Vector2i] = []
## Pause (secondes) à chaque case de la routine.
var route_pause: float = ROUTE_PAUSE_DEFAULT
## Index de départ dans la boucle (jalon 7, dossier 09 §2 : le Rattata part un pas derrière
## l'enfant, même boucle). [member cell] est toujours la case [code]route_cells[route_start]
## [/code] quand la donnée le précise ; sinon, la première occurrence de [member cell] dans
## la boucle (0 si elle n'y est pas), comme avant le jalon 7.
var route_start: int = 0
## Entrer dans un bâtiment (V1, dossier 09 §2) : arrivé sur [member route_enter_cell] (une
## case de la boucle), le PNJ s'efface (fondu), reste absent [member route_enter_seconds],
## puis réapparaît et reprend. (-1, -1) = jamais.
var route_enter_cell: Vector2i = NO_ENTER_CELL
var route_enter_seconds: float = 0.0
## Petite animation d'ambiance (le Roucool de la Dresseuse) toutes les N secondes ; 0 = aucune.
var idle_react_every: float = 0.0
## Attente animée d'un PNJ qui reste sur place (garde de l'Arène, Dresseuse sur son banc,
## acteurs qui attendent une scène) : il se tourne tour à tour vers chaque orientation de
## [member look_facings] (en boucle), une toutes les [member look_every] secondes, quand il
## ne marche pas et ne parle pas. Vide = aucune. Jamais avec une routine de marche (elle
## suffit à le faire vivre).
var look_facings: Array[Vector2i] = []
var look_every: float = LOOK_EVERY_DEFAULT
## Présence conditionnelle (docs/tech/jalon-03b.md §2.6) : présent si tous les drapeaux de
## [member if_flags] sont levés et aucun de [member unless_flags], comme une variante de
## dialogue. Sans condition, toujours présent.
var if_flags: Array[StringName] = []
var unless_flags: Array[StringName] = []
## Espèce d'un Pokémon du décor que le joueur peut OBSERVER (jalon-06.md §3.5, Q-7) : le
## geste l'enregistre « vu » au Pokédex sur la carte. &"" = rien n'est enregistré. Seulement
## sur un PNJ interactif au verbe OBSERVER ([NpcRoster] le vérifie).
var species: StringName = &""
## Dresseur (jalon 9, jalon-09.md §2.4.1) : bloc « trainer » des données. [member trainer_id]
## = combat de `data/trainers/` ; [member sight] = portée de sa vision en cases, en ligne
## droite devant lui ([TrainerRules]) ; [member before_dialogue] = réplique avant le combat.
## Sa réplique « après » est [member dialogue]. &"" = pas un Dresseur.
var trainer_id: StringName = &""
var sight: int = 0
var before_dialogue: StringName = &""
## Réplique dite **une fois**, juste après la victoire du joueur (jalon 10, jalon-10.md §2.5 :
## « D'accord… Tu es prêt. » du Campeur Liam) ; ensuite, [member dialogue]. &"" = la réplique
## « après » est dite tout de suite (comportement du jalon 9).
var defeated_dialogue: StringName = &""


## Vrai si l'on peut interagir avec lui (un dialogue est renseigné).
func is_interactive() -> bool:
	return not dialogue.is_empty()


## Vrai si c'est un Pokémon d'ambiance qui réagit à l'approche du joueur (jalon 5 §3.5).
func is_shy() -> bool:
	return not shy_action.is_empty()


## Vrai si l'observer enregistre une espèce au Pokédex (Q-7).
func is_observable_species() -> bool:
	return not species.is_empty()


## Vrai si le PNJ a une routine de marche (jalon 5, le Voyageur).
func has_route() -> bool:
	return not route_cells.is_empty()


## Vrai si la routine fait entrer le PNJ dans un bâtiment (jalon 7).
func enters_building() -> bool:
	return has_route() and route_enter_cell != NO_ENTER_CELL


## Vrai si le PNJ joue une petite animation d'ambiance périodique (jalon 7).
func has_idle_react() -> bool:
	return idle_react_every > 0.0


## Vrai si le PNJ regarde autour de lui quand il attend (jalon 7).
func has_look() -> bool:
	return not look_facings.is_empty()


## Vrai si le PNJ est sur la carte avec les drapeaux [param flags] (null = nouvelle partie,
## aucun drapeau levé).
func is_present(flags: StoryFlags) -> bool:
	if flags == null:
		return if_flags.is_empty()
	return flags.has_all(if_flags) and flags.has_none(unless_flags)


## Vrai si la présence dépend d'au moins un drapeau.
func is_conditional() -> bool:
	return not if_flags.is_empty() or not unless_flags.is_empty()


## Interaction correspondante sur [param at_cell] (source = [param source]), ou null.
func make_interaction(at_cell: Vector2i, source: Object) -> Interaction:
	if not is_interactive():
		return null
	return Interaction.new(verb, at_cell, dialogue, Vector2i.ZERO, source)


## Vrai si c'est un Dresseur qui voit le joueur et le défie (jalon 9, bloc « trainer »).
func is_trainer() -> bool:
	return not trainer_id.is_empty()
