# Jalon 25 — paquet de données à appliquer à l'intégration

Ces fichiers sont **prêts** mais **hors de `data/`** : ils touchent des inventaires partagés
(nombre d'espèces, sprites provisoires, notes du Pokédex, listes d'objets, dialogues « utilisés »)
que les jalons plus anciens (J20, J22, J24) modifient en ce moment. Règle d'ancienneté : le J25 les
ajoute **après** leurs fusions, avec la mise à jour des tests d'inventaire et les cartes qui
utilisent les dialogues (T14, T17, T18, T20, T21).

| Fichier | Destination | Attend |
|---|---|---|
| `species/kanto_j25.json` (Ponyta, Galopa, Magmar, Ptéra) | `data/pokemon/species/` | sprites provisoires front/back, `tm_compatibility.json` régénéré, taux de capture officiels et compte d'espèces des tests |
| `pokedex/kanto_j25_entrees.json` | entrées dans `data/pokedex/kanto.json` | notes : seulement pour les espèces rencontrables (tables du Manoir, J22) ; **textes à valider par Kevin** |
| `moves/j25.json` (Déflagration, Poing de Feu) | `data/pokemon/moves/` | — |
| `moves/j25_reprises.json` (Écrasement du J20, Ultralaser du J24) | supprimé si ces jalons sont fusionnés | J20, J24 |
| `items/items_j25.json` (Clé Secrète, Vieil Ambre, CT38, Potion Max) | `data/items/` | listes d'objets des tests ; Rappel Max après J20, CT14 après J24 |
| `dialogues/*.json` | `data/dialogues/` | cartes et scènes qui les utilisent ; `{player}` à déclarer dans les dialogues qui l'autorisent ; répliques `draft` à faire valider |
