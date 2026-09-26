class_name StarterOption
extends RefCounted
## Un Pokémon proposé au labo ([StarterOffer]). Donnée pure.

## Espèce proposée.
var species: StringName = &""
## PNJ Pokémon de la carte qui le représente sur la table (`data/npcs/<map>.json`).
var npc: StringName = &""
## Phrase de la fiche (« Fougueux et courageux. »).
var blurb: String = ""
