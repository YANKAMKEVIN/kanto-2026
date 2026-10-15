class_name GhostDisguise
extends RefCounted
## Masque d'identité du SPECTRE (jalon 19, `jalon-19.md` §2.3 ; dossier 22 §6.2, K-9). Classe
## pure.
##
## Le moteur ([Battle], T11) applique [method mask] à chaque événement d'un combat SPECTRE :
## seuls ceux du camp adverse sont masqués. L'espèce réelle devient la pseudo-espèce
## [constant SPECIES] (la silhouette de [constant TEXTURE_PATH]), le niveau devient
## [constant HIDDEN_LEVEL] (la carte écrit « Nv. » + [constant HIDDEN_LEVEL_TEXT]) et le genre
## disparaît. Un événement masqué se reconnaît par [method is_masked] : c'est la garde du
## Pokédex (aucun « vu », ni rencontre sauvage, ni scène) et celle du cri.

## Pseudo-espèce de l'image (aucune donnée d'espèce : jamais créée, jamais au Pokédex).
const SPECIES: StringName = &"ghost_disguise"
## Silhouette peinte (lot 19.0) ; elle n'existe pas en dos.
const TEXTURE_PATH: String = "res://assets/sprites/battle/spectre.png"
## Niveau porté par un événement masqué (« niveau inconnu »).
const HIDDEN_LEVEL: int = 0
## Ce que la carte écrit à la place du niveau (« Nv. ?? », `jalon-19.md` §7).
const HIDDEN_LEVEL_TEXT: String = "??"


## Masque [param event] s'il concerne le camp adverse : pseudo-espèce, niveau masqué, sans
## genre ; [param display_name] (le nom « SPECTRE » des messages, s'il est donné) remplace le
## nom affiché. Faux (rien ne change) pour un événement du camp du joueur.
static func mask(event: BattleEvent, display_name: String = "") -> bool:
	if event == null or event.side != BattleEvent.SideId.FOE:
		return false
	event.species_id = SPECIES
	event.level = HIDDEN_LEVEL
	event.gender = Pokemon.Gender.NONE
	if not display_name.is_empty():
		event.pokemon_name = display_name
	return true


## Vrai si [param event] a été masqué par [method mask] : il ne doit rien enregistrer au
## Pokédex, ni jouer de cri.
static func is_masked(event: BattleEvent) -> bool:
	return event != null and event.species_id == SPECIES
