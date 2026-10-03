class_name StatView
extends RefCounted
## Une statistique de l'onglet Aperçu (dossier 08 §2 : jauges et valeurs, jamais un tableau ;
## jalon-06.md §3.3). Contrat figé au T6.

## Identifiant (&"hp", &"atk"… : [constant SpeciesData.STATS]).
var stat_id: StringName = &""
## « PV », « Attaque », « Défense », « Atq. Spé. », « Déf. Spé. », « Vitesse ».
var name: String = ""
## Valeur réelle du Pokémon (PV : PV max).
var value: int = 0
## Remplissage de la jauge, 0..1 : part de la plus haute statistique du Pokémon (§13) ; la
## plus haute vaut 1.
var ratio: float = 0.0


func _init(id: StringName = &"", shown_name: String = "", stat_value: int = 0,
		fill: float = 0.0) -> void:
	stat_id = id
	name = shown_name
	value = stat_value
	ratio = clampf(fill, 0.0, 1.0)
