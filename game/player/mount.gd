class_name Mount
extends RefCounted
## Monture du joueur (passe systèmes 2, `docs/tech/systemes-2.md` §2.2) : une seule source de
## vérité pour le Vélo et le Surf. Pur, statique.
##
## Valeur sauvegardée : [constant NAMES] (`player.mount` de la sauvegarde v7, champ facultatif :
## absent ou inconnu = à pied, §2.13).

enum Kind { NONE, BIKE, SURF }

## Nom sauvegardé de chaque [enum Kind], dans l'ordre de l'énum.
const NAMES: Array[StringName] = [&"", &"bike", &"surf"]


## Nom sauvegardé de [param kind].
static func to_name(kind: Kind) -> StringName:
	return NAMES[kind]


## [enum Kind] d'un nom sauvegardé ; un nom inconnu donne [constant Kind.NONE] (à pied).
static func from_name(saved: StringName) -> Kind:
	var index := NAMES.find(saved)
	return Kind.NONE if index < 0 else index as Kind
