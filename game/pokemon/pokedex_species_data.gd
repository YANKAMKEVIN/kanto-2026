class_name PokedexSpeciesData
extends RefCounted
## Ce que le Pokédex sait d'une espèce au-delà de [SpeciesData] (dossier 08 §4 ; jalon-06.md
## §3.5, Q-5) : taille, poids, description, notes d'Observations. Lue par [PokedexLibrary].
## Donnée pure. Le numéro et le nom viennent de [SpeciesData] (jamais recopiés ici).

var id: StringName = &""
## Taille en mètres et poids en kilogrammes (valeurs officielles, Q-5).
var height: float = 0.0
var weight: float = 0.0
## Description de terrain, écrite pour le projet (Q-5) ; affichée à la capture seulement.
var description: String = ""
## Description provisoire, à relire par Kevin.
var draft: bool = false
## Notes d'Observations, dans l'ordre du fichier.
var notes: Array[PokedexNoteData] = []
## Fichier d'origine (messages d'erreur).
var source: String = ""
