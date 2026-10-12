extends RefCounted
## Capacités du J14 pour les tests du moteur (T7, T8) : Tunnel (`dig`) et Téléport (`teleport`),
## définitions du `jalon-14.md` §2.3 et §2.5. Le fichier de données réel
## (`data/pokemon/moves/moves_j14.json`) vient de T5 ; tant qu'il manque, la fixture
## `tests/fixtures/pokemon/j14_charge/moves.json` les ajoute. Une capacité déjà présente n'est
## pas rechargée (pas de doublon) : à la fusion, c'est la donnée réelle qui est testée.
## Utilisation : [code]const J14Moves := preload("res://tests/helpers/j14_moves.gd")[/code].

const FIXTURE: String = "res://tests/fixtures/pokemon/j14_charge/moves.json"


## [param data] déjà chargé : ajoute les capacités de la fixture qui lui manquent.
static func ensure(data: PokemonData) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var missing: Dictionary = {}
	for id: Variant in parsed:
		if not data.has_move(StringName(str(id))):
			missing[id] = parsed[id]
	if not missing.is_empty():
		data.add_moves_from_dict(missing, FIXTURE)
