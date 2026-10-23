# Jalon 25 — paquet de données : appliqué le 2026-10-22

Les fichiers du paquet ont été branchés dans `data/` (T6 à T9) et supprimés d'ici.

| Contenu | Destination |
|---|---|
| Ponyta, Galopa, Magmar, Ptéra | `data/pokemon/species/kanto_j25.json` |
| Tadmorv, Grotadmorv, Smogogo, Électrode (reprises à l'identique de `origin/jalon-22` ; **retirées** à la fusion de `main` du 2026-10-23, ce sont celles de `kanto_j22.json`) | `data/pokemon/species/kanto_j25_reprises.json` + sprites et fiches de Pokédex du J22 |
| Déflagration, Poing de Feu | `data/pokemon/moves/j25.json` |
| Clé Secrète, Vieil Ambre, CT38, Potion Max (+ Rappel Max, CT14, CT22) | `data/items/items_j25.json` |
| Entrées du Pokédex | `data/pokedex/kanto.json` |
| Dialogues (Manoir, Arène, échanges, réserve du Musée) | `data/dialogues/` |

`moves/j25_reprises.json` (Écrasement, Ultralaser) était sans objet (`stomp` est dans `celadon.json`,
`hyper_beam` dans `tower.json`) : supprimé sans être branché. Ce dossier peut être supprimé.
