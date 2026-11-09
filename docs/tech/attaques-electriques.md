# Refonte des attaques électriques (décidée le 2026-11-09)

Demande de Kevin : revoir les attaques **une famille de types à la fois**, en commençant par l'Électrik, pour que l'ensemble soit cohérent. Tonnerre ne doit plus ressembler à Éclair, ni à Fatal-Foudre.

**Direction retenue par Kevin : A, « foudre peinte »**, or et blanc, lumière naturelle, matière de peinture visible, proposée par Codex. Planche de référence : `docs/design/references/attaques/electrik_direction_A.png`. Elle donne la direction, pas un dessin à reproduire au pixel (règle 10 de `CLAUDE.md`).

## Les sept attaques

Chaque attaque se reconnaît à sa **forme et son geste**, pas seulement à sa force. Les données sont dans `data/pokemon/moves/` (attaques) et `data/battle/move_fx/` (effets).

| N° | Attaque | Puissance | Effet visuel à obtenir | Effet actuel |
|---|---|---|---|---|
| 1 | Cage-Éclair | statut | Filaments en cage autour de la cible ; pas de trait de frappe | Famille `electrique` |
| 2 | Éclair | 40 | Courte décharge fine et rapide, depuis les joues | `electrique`, signature `eclair` |
| 3 | Étincelle | 65, physique | Le lanceur couvert d'électricité charge et percute | `electrique` |
| 4 | Poing-Éclair | 75, physique | Coup unique, onde de choc concentrée au contact | `poing`, variante `eclair` |
| 5 | Tonnerre | 90 | Courant épais de foudre tressée **depuis le lanceur, jamais du ciel** ; gros impact | `electrique`, signature `tonnerre` |
| 6 | Fatal-Foudre | 110 | Ciel d'orage, colonne colossale tombant sur la cible | `foudre` |
| 7 | Élecanon | 120, précision 50 | Énorme sphère dense, instable, lente, qui explose sur la cible | `electrique` |

## Contraintes

- Barre de qualité : `docs/tech/combat-vivant.md` §2.9 (couches, flipbooks peints, validation **en vidéo**). Référence : l'idée de l'attaque dans Pokémon Rouge, rendue en 2026.
- Les Pokémon n'ont pas de pose de course ni de coup de poing : pour 3 et 4, la charge du dos existante porte le geste, les éclairs font le reste.
- La gradation de puissance doit se lire : Éclair la plus petite, Élecanon et Fatal-Foudre les plus grosses.
- Essais écartés par Kevin pour Tonnerre : arc tordu qui n'atteint pas la cible, et foudre du ciel (trop proche de Fatal-Foudre).

## Étapes

1. Lister les images animées à créer (cage, courant tressé, sphère, étincelles de charge) selon le pipeline de `tools/art/serie_cv_fx*.py` (Codex, `tools/art/generer.sh`).
2. Brancher les familles et signatures dans `data/battle/move_fx/`, avec les nouvelles briques si besoin (`game/battle/fx/`).
3. Vidéo des sept attaques avec la galerie : `game/battle/fx/fx_gallery.tscn -- --moves=thunder_wave,thunder_shock,spark,thunder_punch,thunderbolt,thunder,zap_cannon --mode=full`.
4. Validation de Kevin sur la vidéo, puis CI GitHub verte.
