class_name MansionSwitch
extends RefCounted
## Interrupteur global du Manoir Pokémon (jalon 25, dossier 28 §4.3, X-5 ; `jalon-25.md` §2.1).
##
## Un seul drapeau pour les quatre étages. Chaque étage a deux jeux de grilles : le jeu A est
## fermé quand l'interrupteur est sur ARRÊT (drapeau absent), le jeu B quand il est sur MARCHE.
## Les statues basculent le drapeau. Il revient à ARRÊT quand le joueur entre dans le Manoir
## depuis Cramois'Île (équivalent de Rouge/Bleu, qui le remet à zéro sur la carte de l'île),
## jamais aux escaliers, aux chutes ni au chargement d'une sauvegarde. Classe pure, sans scène.

## Drapeau de l'interrupteur (levé = MARCHE).
const FLAG: StringName = &"mansion_switch_on"
## Cartes d'où l'on entre dans le Manoir par une porte (remise à ARRÊT).
const ENTRY_MAPS: Array[StringName] = [&"cinnabar_island"]
## Jeux de grilles des grilles `tools/plans/manoir_*.txt` (`a`, `b`).
enum GateSet { A, B }


## Vrai si l'interrupteur est sur MARCHE.
static func is_on(flags: StoryFlags) -> bool:
	return flags != null and flags.has_flag(FLAG)


## Bascule l'interrupteur (statue, réponse OUI) ; rend le nouvel état (vrai = MARCHE).
static func toggle(flags: StoryFlags) -> bool:
	var on := not is_on(flags)
	flags.set_flag(FLAG, on)
	return on


## Arrivée sur une carte du Manoir depuis [param from_map] : remet à ARRÊT si l'on vient de
## l'île. Rend vrai si l'état a changé.
static func reset_on_entry(flags: StoryFlags, from_map: StringName) -> bool:
	if not from_map in ENTRY_MAPS or not is_on(flags):
		return false
	flags.set_flag(FLAG, false)
	return true


## Vrai si une grille du jeu [param gate_set] bloque le passage dans l'état actuel.
static func is_closed(flags: StoryFlags, gate_set: GateSet) -> bool:
	return is_on(flags) == (gate_set == GateSet.B)
