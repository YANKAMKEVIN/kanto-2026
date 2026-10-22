class_name ZonePanelView
extends RefCounted
## Le panneau latéral d'une zone **découverte** de la Carte (dossier 08 §5 ; jalon-06.md §3.6).
## Construit par [method MapJournal.panel] (null pour une zone non découverte). Contrat figé au
## T18 (§6.10) : on peut seulement ajouter des champs (architecte) ; **texte vide = élément
## absent**, **liste vide = section absente** (titre compris).
##
## Ce que le joueur a découvert, rien d'autre : aucun total, aucun « ??? », aucun emplacement
## vide, aucun bouton de déplacement.

## Titres des sections (l'écran les écrit seulement au-dessus d'une liste non vide).
const POKEMON_TITLE: String = "Pokémon observés"
const ITEMS_TITLE: String = "Objets trouvés"
const SERVICES_TITLE: String = "Services"

var zone_id: StringName = &""
## « Route 1 ».
var name: String = ""
## Connexions (« Bourg Palette — Jadielle ») ; "" = absent.
var subtitle: String = ""
## Courte description du paysage ; "" = absente.
var description: String = ""
## Le joueur est dans cette zone.
var current: bool = false
## Pokémon observés dans la zone (vus sur une de ses cartes), par numéro du Pokédex ;
## **toujours vide tant que le Pokédex n'est pas visible** (règle de déblocage). Toucher →
## `MenuRoute.pokedex(MenuRoute.DEX_FILTER_ALL, id)`.
var pokemon: Array[ZoneEntryView] = []
## Objets trouvés (ramassés) dans la zone, dans l'ordre de la première trouvaille ; un objet
## trouvé plusieurs fois n'a qu'une ligne ([method ZoneEntryView.count_text]).
var items: Array[ZoneEntryView] = []
## Services découverts (Centre, Boutique, Arène), dans l'ordre de `zones.json` ; aucun au J6.
var services: Array[ZoneEntryView] = []
## Passe systèmes 2 (§2.8, Q-4 : décision de Kevin, qui lève ici le « aucun bouton de
## déplacement ») : bouton « S'ENVOLER » proposé (Vol permis d'ici vers cette ville ouverte).
var fly_available: bool = false
