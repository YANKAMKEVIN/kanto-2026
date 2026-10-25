class_name MansionSwitchReset
extends FlagGate
## Remise de l'interrupteur du Manoir à ARRÊT (jalon 25, `jalon-25.md` §2.1 ; dossier 28 §4.3) :
## un [FlagGate] sans dessin posé sur `cinnabar_island`, réglé par [method GameMap.apply_flag_gates]
## à chaque arrivée sur l'île (et à chaque drapeau changé pendant la visite). On n'entre dans le
## Manoir que depuis l'île : c'est l'équivalent de Rouge/Bleu (remise sur la carte de l'île), et
## rien ne change aux escaliers, aux chutes ni au chargement d'une sauvegarde **dans** le Manoir.

## Carte d'arrivée passée à [method MansionSwitch.reset_on_entry].
@export var map_id: StringName = &"cinnabar_island"


func apply(flags: StoryFlags) -> void:
	visible = true
	if flags != null:
		MansionSwitch.reset_on_entry(flags, map_id)


func apply_to_grid(_grid: GridWorld) -> void:
	pass
