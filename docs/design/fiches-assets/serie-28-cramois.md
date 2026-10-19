# Série 28 (numéro PROVISOIRE) — Cramois'Île : Manoir Pokémon, Arène d'Auguste, réserve du Musée (jalon 25, lot 25.0, T10 à T12)

> Branche `j25-kit-art` (depuis `jalon-25`). Outil : `tools/art/serie28.py` ; prompts : `tools/art/prompts/serie28/` (décors de combat : `.../serie28/decors/`). Aucune intégration Godot : rien dans `assets/`, aucun manifeste lancé. **État : génération PARTIELLE** (voir « Bloqué »).

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

## Liste du kit

| Lot | Asset | État |
|---|---|---|
| Sols (384 px = 4 × 4 cases) | `ground_parquet_manoir_01` (étalonné 0,80 / 0,88), `ground_masse_manoir_01`, `ground_carrelage_b1_01`, `ground_masse_manoir_b1_01`, `ground_dalles_arene_01` | **retenus r1** (relus) |
| | `ground_masse_arene_01` | **à générer** |
| Relief (faces 2 × ≈ 1,1 case ×4, couronnement, flanc) | Manoir ; sous-sol | **retenus r1** |
| | Arène (`WORLD_RELIEF_MUR_ARENE_PLANCHE`) | **à générer** |
| Objets du Manoir | planche A : statue (chat de pierre), grille 2 × 2 fermée / ouverte, trou, pupitre à carnet, seuil de porte brûlée ; planche B : escalier montant, trémie descendante, tonneau, groupe 2 × 2, table de labo 1 × 2, caisse d'archives ; planche de 6 débris (planches, papiers, gravats, suie, verre, tapis) | **retenus r1** |
| Objets de l'Arène | machine de quiz, herse 2 × 2 fermée / ouverte, statue de l'Arène | **à générer** |
| Musée | vitrine d'ambre pleine / vide, caisses de fouilles ; porte arrière (façade est) | **à générer** |
| PNJ | Pillard, Auguste (marche + attente) | **à générer** |
| Combat | dos Ponyta 077, Galopa 078, Magmar 126, Ptéra 142 (provisoires IA) ; décors `manoir_salle`, `arene_cramois` | **à générer** |

Conventions de pose pour le T14 / T20 : face = 192 × ≈ 108 px, bas aligné sur le bas de la case `#` dont le sud est libre ; couronnement 192 × 25 en haut de la case dont le nord est libre ; flancs non utilisés (la vue validée n'en montre pas) ; objets : origine au milieu du bas ; mobilier lourd : `#` isolés (1 × 1 tonneau, 2 × 2 = groupe de tonneaux, B1F : deux tables de labo) ; trous peints sur la case `O` ; lumière dorée, brume et ombres : à Godot.

## Dos de combat

La chaîne validée (rendu 3D X/Y repeint sur Colab) est **inutilisable ici** : les modèles de Ponyta, Galopa, Magmar et Ptéra ne sont pas dans `~/dev/kanto-2026-modeles/` (téléchargement The Models Resource et notebook Colab = actions de Kevin, comme `dos_t13.py`). Repli décidé : **dos provisoire IA par Codex** (comme Fantominus au J19), 1 024 × 1 024, prompts r1 (nom + artwork + dos d'ancrage), r2 (sans nom), r3 (sans image) prêts.

## Bloqué

Codex a atteint sa **limite d'usage** pendant la vague 4 (« try again at 3:56 PM », message du 2026-10-19 vers 12 h 15, pas un refus). Vagues faites : 1 à 3 (Manoir) et le sol de l'Arène. Reste : `python3 tools/art/serie28.py --generer 4 5 6 7 8 9` (trois à la fois), puis `--tuiles` / `--decor` pour les deux décors, `--retenir`, `--preparer`, `--cartes`, `--controle` (planche `build/art/SERIE28_CONTROLE_v1.png`). Aucun refus de modération constaté (aucune espèce encore tentée).

## Hypothèses

Statue du Manoir = chat de pierre blanc (la vue validée), Pillard = bonnet bleu marine, écharpe rouge, veste brune, sac (vue de l'Arène) ; Auguste = chauve, moustache blanche, lunettes sombres rondes, sarrau crème à liseré orange à flammes ; Ptéra et Magmar sans aucune validation ; Intello du J20 repris tel quel.
