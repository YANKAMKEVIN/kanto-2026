class_name FossilReadyGate
extends FlagGate
## Résurrection des fossiles, côté carte de la ville (jalon 24, T13 ; dossier 27 §10.5, cas
## limite 9) : un [FlagGate] sans dessin posé sur `cinnabar_island`, réglé par
## [method GameMap.apply_flag_gates] à chaque arrivée sur la carte (sortie du Labo, arrivée par la
## mer, chargement) : pendant une résurrection, il pose le drapeau « prêt » ([method
## FossilLab.on_map_entered]).
##
## Les étapes de scène ne savent que **poser** des drapeaux : le don (`gift_pokemon`, drapeau
## `fossil_revived_<espèce>`) laisse `fossil_reviving_<espèce>` et `fossil_ready` posés ; ce nœud
## les efface à l'arrivée suivante ([method tidy]), pour qu'une autre résurrection (Vieil Ambre,
## J25) reparte de l'état IDLE de [FossilLab].

## Carte d'arrivée lue par [method FossilLab.on_map_entered].
@export var map_id: StringName = &"cinnabar_island"

static var _lab: FossilLab = null


## Données des fossiles (chargées une fois).
static func lab() -> FossilLab:
	if _lab == null:
		_lab = FossilLab.new()
		_lab.load_file()
	return _lab


func apply(flags: StoryFlags) -> void:
	visible = true
	if flags == null:
		return
	tidy(lab(), flags)
	lab().on_map_entered(map_id, flags)


## Efface les drapeaux d'une résurrection terminée (Pokémon déjà donné).
static func tidy(fossil_lab: FossilLab, flags: StoryFlags) -> void:
	var done := false
	for fossil: StringName in fossil_lab.fossil_ids():
		var flag := fossil_lab.flag_of(fossil)
		var revived := StringName("fossil_revived_" + String(fossil_lab.species_of(fossil)))
		if flags.has_flag(flag) and flags.has_flag(revived):
			flags.set_flag(flag, false)
			done = true
	if done:
		flags.set_flag(fossil_lab.ready_flag(), false)


func apply_to_grid(_grid: GridWorld) -> void:
	pass
