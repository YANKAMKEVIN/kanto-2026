# Série 28 (numéro PROVISOIRE) — Cramois'Île : Manoir Pokémon, Arène d'Auguste, réserve du Musée (jalon 25, lot 25.0, T10 à T12)

> Branche `j25-kit-art` (depuis `jalon-25`). Outil : `tools/art/serie28.py` ; prompts : `tools/art/prompts/serie28/` (décors de combat : `.../serie28/decors/`). Aucune intégration Godot : rien dans `assets/`, aucun manifeste lancé. **État : génération COMPLÈTE (2026-10-19, après la limite d'usage de Codex)**. Planche : `build/art/SERIE28_CONTROLE_v1.png`.

## Numéro de série

Vérifié le 2026-10-19 (`git fetch`, `git ls-tree` de `tools/art/` et `docs/design/fiches-assets/` sur les 436 références locales et distantes) : fiches et scripts 20 à 24 pris (J19, J18, J20, J21, J19 bis) ; **25 réservé par le J22** (`docs/tech/jalon-22.md` : `serie-25-deux-chemins.md`, `serie25.py`) ; 26 et 27 : aucune trace, mais probablement pris par le J23 et le J24. **28 libre** : retenu, à revérifier au push (renommer la fiche, `serie28.py` et `prompts/serie28/` sinon ; les identifiants d'images ne portent pas le numéro).

## Méthode des cartes : kit modulaire, pas une image peinte d'un coup

Essai du 2026-10-19 (Codex, plan en aplats joint) : Manoir 1F en une image = 1 298 × 1 212 px pour 30 × 28 cases (≈ 43 px par case, agrandissement × 2,2) et **75 % des cases conformes** à la grille ; Arène : même défaut (murs déplacés). La grille fait foi : on suit donc le **modèle réel du J19** (`tools/build_pokemon_tower.gd`, kit de la série 21) et des grottes : sols raccordables, masses, faces / couronnements / flancs, objets, posés par la grille. `serie28.py --cartes` recompose chaque carte à 1 case = 96 px, état ARRÊT (jeu A fermé, jeu B ouvert, herses fermées) : c'est la « carte peinte » de chaque étage, fidèle à la grille à 100 %. Les essais d'image entière sont perdus (`build/art/EXP_*`, non versionnés).

## Réutilisations

| Besoin | Réutilisé |
|---|---|
| Coque de la réserve du Musée | `int_musee_coque` (série 12) : même convention 15 × 10 que `argenta_musee_reserve.txt` ; comptoir de 5 cases : `int_long_comptoir_01` (480 px) |
| Scientifique | `chercheur` (existant) |
| Guide de l'Arène | `guide_arene` (existant, série 14) ; dossier 28 §13 : « réutiliser » |
| Intello | **J20, série 22** (`PNJ_INTELLO_NE_r1` + `INTELLO_ATTENTE_r1`, retenus r1, **pas encore validés par Kevin**), lus dans `.claude/worktrees/j20-t2-t3-art/build/art` ; non regénéré |
| Carte de Champion | **aucun asset** : `ChampionCard` est une carte texte sans portrait (donnée `champion_card` seulement) |
| Héros, Poké Ball au sol, arbuste à Couper, bâtiment du Musée | existants (contrôle) |
| Arcanin, Feunard | dos du J20 (hors lot) |

## Liste du kit (tout retenu r1 sauf mention ; préparé dans `build/art/serie28/`)

| Lot | Asset |
|---|---|
| Sols (384 px = 4 × 4 cases) | `ground_parquet_manoir_01` (étalonné 0,80 / 0,88), `ground_masse_manoir_01`, `ground_carrelage_b1_01`, `ground_masse_manoir_b1_01`, `ground_dalles_arene_01`, `ground_masse_arene_01` |
| Relief (4 faces 192 × ≈ 108, couronnement, flanc) | Manoir, sous-sol, Arène (faces d'Arène 192 × ≈ 88) |
| Objets du Manoir | statue (chat de pierre), grille 2 × 2 fermée / ouverte, trou, pupitre à carnet, seuil, escalier montant, trémie, tonneau, groupe 2 × 2, table de labo 1 × 2, caisse d'archives, **fauteuil renversé, petite table, armoire basse (planche C, ajoutée le 2026-10-19 sur demande de Kevin : mobilier varié)**, 6 débris (suie floue) |
| Arène | machine de quiz, herse 2 × 2 fermée / ouverte, statue de l'Arène (colosse à cornes) |
| Musée | vitrine d'ambre pleine / vide, caisses de fouilles, porte arrière (192 × 189 px, à accoler à la façade est) |
| PNJ (marche + attente) | `pillard`, `auguste` |
| Décors CB.3 | `manoir_salle` (rai doré de la fenêtre brisée, cheminée), `arene_cramois` (herse relevée, deux braseros), 2340 × 1080 WebP (682 et 584 Ko), tuiles TL / TR recalées |
| Dos provisoires IA | Ponyta (r2), Galopa (r1), Magmar (r1), Ptéra (r3) |

Mobilier recomposé : un `#` isolé reçoit un meuble choisi par une fonction déterministe de la case (tonneau, caisse, petite table, fauteuil, armoire ; B1F sans tonneau), jamais le même que celui d'un voisin ; 2 × 2 = groupe de tonneaux (B1F : deux tables de labo).

## Essais, refus

Aucun refus pour les planches, sols, PNJ, décors. **Refus de modération en sortie** : Ponyta r1 (retenu : r2 sans nom, avec artwork), Ptéra r1 et r2 (retenu : r3 sans image, un ptérosaure plus réaliste que l'artwork, teinte grise). Magmar r1 : forme proche d'un Magmar dérivé (piques dorsales, bras massifs), à juger. Galopa r1 fidèle. Limite d'usage de Codex le 12 h 15, reprise à 15 h 58 : aucun asset perdu.

Conventions de pose pour le T14 / T20 : face = 192 × ≈ 108 px, bas aligné sur le bas de la case `#` dont le sud est libre ; couronnement 192 × 25 en haut de la case dont le nord est libre ; flancs non utilisés (la vue validée n'en montre pas) ; objets : origine au milieu du bas ; mobilier lourd : `#` isolés (1 × 1 tonneau, 2 × 2 = groupe de tonneaux, B1F : deux tables de labo) ; trous peints sur la case `O` ; lumière dorée, brume et ombres : à Godot.

## Dos de combat

La chaîne validée (rendu 3D X/Y repeint sur Colab) est **inutilisable ici** : les modèles de Ponyta, Galopa, Magmar et Ptéra ne sont pas dans `~/dev/kanto-2026-modeles/` (téléchargement The Models Resource et notebook Colab = actions de Kevin, comme `dos_t13.py`). Repli décidé : **dos provisoire IA par Codex** (comme Fantominus au J19), 1 024 × 1 024, prompts r1 (nom + artwork + dos d'ancrage), r2 (sans nom), r3 (sans image) prêts.

## Reste à faire

Intégration (manifeste, `build_painted_props`, builders `build_pokemon_mansion.gd` / `build_cinnabar_gym.gd`, `decors.json`) : plan du J25 T13 à T20. Dos : remplaçables par la chaîne Colab (mêmes noms `dos_ia_NNN`) si Kevin télécharge les modèles X/Y. Intello du J20 à valider côté J20.

## Hypothèses

Statue du Manoir = chat de pierre blanc (la vue validée), Pillard = bonnet bleu marine, écharpe rouge, veste brune, sac (vue de l'Arène) ; Auguste = chauve, moustache blanche, lunettes sombres rondes, sarrau crème à liseré orange à flammes ; Ptéra et Magmar sans aucune validation ; Intello du J20 repris tel quel.
