# Série 13 — planches de marche du compagnon (jalon 11, lot d'art A-10)

> Préparée le 2026-10-10 (T18 de `docs/tech/jalon-11.md`, en avance pendant l'attente d'OUV.1).
> Décision de Kevin (A-10, dossier 14 §8.2) : **Herbizarre, Reptincel, Carabaffe, Pikachu,
> Papilusion (en vol)**, dans la main 2D HD peinte des planches existantes. Aucune image n'entre
> dans le jeu sans la **validation de Kevin sur planche de contact** ; aucun substitut pour une
> espèce sans planche (A-11).

## Ce qui est demandé

Une planche par espèce, **même gabarit que les starters** (série 09) et le Salamèche de Kevin :
1024 × 1536, fond transparent, grille invisible 4 × 4 (cellules 256 × 384), lignes = face,
gauche, droite, dos ; colonnes = 4 images de marche ; pieds sur une ligne à 60 px du bas de la
cellule ; lumière neutre (NE) ; vue de trois quarts du jeu. Le prompt exact est dans
`tools/art/serie13.py` (source unique) :

```bash
python3 tools/art/serie13.py --texte POKE_REPTINCEL     # affiche le prompt à coller
tools/art/serie13.py                                    # Codex, les cinq (Mac de Kevin)
tools/art/serie13.py POKE_PIKACHU POKE_PAPILUSION       # Codex, une partie
```

| Identifiant | Espèce (id du jeu) | Ancre de forme (build/art) | Mouvement | Hauteur en jeu [D] |
|---|---|---|---|---|
| `POKE_HERBIZARRE` | `ivysaur` | `POKE_BULBIZARRE_NE_r1` | marche à quatre pattes, pas lourds | 66 px |
| `POKE_REPTINCEL` | `charmeleon` | `POKE_SALAMECHE_NE_r4` | marche debout, flamme qui balance | 72 px |
| `POKE_CARABAFFE` | `wartortle` | `POKE_CARAPUCE_NE_r1` | marche debout, queue qui ondule | 68 px |
| `POKE_PIKACHU` | `pikachu` | `POKE_RATTATA_P2_r1` | trot à quatre pattes, petits bonds | 60 px (52 à l'origine : la queue de la vue de face fixe l'échelle, corps trop petit ; validé par Kevin le 2026-10-13) |
| `POKE_PAPILUSION` | `butterfree` | `POKE_ROUCOOL_NE_r1` | **vol sur place**, ailes qui battent | 70 px |

Toujours joint en premier : `PERSO_P2_PEINT_r1` (le héros validé, ancre de style).
Hauteurs = valeurs par défaut (règle 4), dans l'échelle des existants (Salamèche et Bulbizarre
60 px, Rattata 56 px, héros 128 px) : une forme évoluée est un peu plus grande que la précédente.

**Papilusion en vol** : le bas du corps reste ≈ 70 px au-dessus de la ligne des pieds (rien ne
touche le sol) ; le moteur posera une ombre au sol sous lui (11D). Les 4 colonnes sont un cycle
de battement d'ailes, qui sert aussi d'attente.

## Si Codex refuse (cas du Salamèche, série 09 ; Reptincel et Pikachu, série 13)

Coller le prompt affiché par `--texte` dans l'app ChatGPT, avec les **deux images** citées
(héros + ancre de forme), et enregistrer le résultat sous `build/art/<IDENTIFIANT>_NE_r1.png`.
Ensuite, même chaîne que pour une image Codex.

**Constat du 2026-10-13** : ChatGPT a aussi refusé tant que les images d'ancre étaient jointes ; Reptincel
a été obtenu **sans image jointe** (prompt seul), rendu un peu plus doux mais validé par Kevin.

## Après la génération

1. Relire chaque planche (16 poses identiques, aucune pose qui déborde, transparence réelle,
   pieds alignés, pas de trait noir, pas de dérive de couleur) ; régénérer en `_r2` si besoin.
2. Planche de contact pour Kevin (les cinq, côte à côte avec Salamèche et Bulbizarre à la même
   échelle) → **validation de Kevin**.
3. Seulement après : `tools/art/serie13.py --manifeste` (entrées `pokemon` du manifeste),
   `python3 tools/art/preparer.py`, puis l'intégration au 11D (T20) : correspondances
   `LOOKS` de `tools/build_character_frames.gd` (`pokemon/<espèce>`) et liste des espèces
   éligibles `data/pokemon/companions.json`. Rien n'est branché avant le 11D.

## Pour le J12 (recommandation, pas une décision du J11)

Audit de l'équipe réelle de Kevin (dossier 14 §8.2) : au Mont Sélénite (Nv. 16–25), Roucoups,
Nidorina, Nidorino, Rattatac et Rapasdepic ne seront pas couverts. Même gabarit, même script
(ajouter des lignes à `SERIE`) quand Kevin le décide.
