# Jalon 24 — Les Îles Écume et Artikodin (Surf, Force, Routes 19–21, Cramois'Île)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/dossier-27-iles-ecume.md`. Les 7 décisions de la V2 et les arbitrages P-1 à P-22
> sont validés par Kevin le 2026-10-16. **Les textes du §15 sont validés** par Kevin le 2026-10-16
> (« pour J24 je valide ses 90 textes », message relayé par une autre session à sa demande). Passe :
> `docs/design/passes/j24-v2-alignement.md`.

> Objectif jouable sur le téléphone : **on nage, on pousse, on traverse**. Depuis la plage de
> Parmanie, le joueur surfe sur les Routes 19 et 20 au milieu des Nageurs. Il entre dans les Îles
> Écume et pousse des rochers dans des trous pour calmer deux courants. Il atteint Artikodin et,
> de l'autre côté, Cramois'Île : Centre, Boutique, Labo, fossile ressuscité, CT35. Par la Route 21,
> il rentre à Bourg Palette.
>
> Mécaniques nouvelles :
> - le **mode Surf** du joueur : monture, eau surfable, verbe SURFER, rencontres `water`, Nageurs,
>   reprise sur l'eau avec garde-fou ;
> - les **rochers de Force**, poussables, qui tombent dans des trous ;
> - un **état de donjon dérivé de 8 drapeaux** ;
> - les **courants** : glissade forcée, coupée par drapeaux ;
> - l'**effet Métronome** ;
> - la **résurrection des fossiles**.
>
> **Format de sauvegarde inchangé : v7** (§2.9).

## 0. État et dépendances

### 0.1 Ancienneté (règle de Kevin, 2026-10-16)

Le J24 est l'avant-dernière session de lancement. Ordre d'ancienneté : J15, J17, J18, J19, J20,
J21, J22, J23, J24, J25. **Le J24 ne modifie aucun système qu'une session plus ancienne est en
train de modifier** ; il s'appuie sur la version de cette session, ou il demande à Kevin.

| Système partagé | Session propriétaire | Ce que fait le J24 |
|---|---|---|
| État « monté » (Vélo, compagnon rentré) | J22 | S'y branche (Surf = un mode de plus). Si le J22 n'a pas encore codé le Vélo quand 24A commence, **demander à Kevin** qui écrit la base commune. |
| `FieldMoves`, `field_moves.json`, étape `field_move` | J16, J17, J23 | Lit les entrées `surf` et `strength` du J23 ; n'y touche pas. |
| Étape `wild_battle` (issues `win` / `catch` / `flee` / `clear`) | J19, J21 | Réutilisée telle quelle pour Artikodin. |
| `SpinSlide`, `SpinTileRules` | J20 | Réutilisés pour les courants, sans modification ; s'il faut un ajout, demande. |
| `PokemonGift` | J20 | Réutilisé pour les fossiles. |
| Parmanie (grille, carte) | J22, J23 | Le J24 n'ajoute que sa côte sud surfable et le rocher du Gardien poussable, **après** leur clôture et avec l'accord de Kevin. |
| Moteur de combat (Métronome) | jalon qui y travaille à ce moment-là | Vérifier avant T12 ; sinon attendre. |
| `GridWorld`, `GridMover`, `Player` | aucune session connue à ce jour | Vérifier sur toutes les branches distantes avant T6. |
| Séries d'art | — | Numéro réservé au moment du push, après vérification de toutes les branches distantes (§2.12). |

### 0.2 Contrat d'entrée (dossier §3), relu sur le code

| Point | Code réel | Conséquence |
|---|---|---|
| Position sauvegardée | `GameState.to_dict` : `map`, `cell`, `facing` ; lecture par `JsonFields.get_*` **avec valeur par défaut** (`game_state.gd`, l. 286–325) | Ajouter `surfing` (défaut `false`) et `last_land_cell` **sans changer de version** |
| Accès aux cases | `GridWorld.can_enter` refuse `_FLAG_WATER` ; `is_free` aussi (l. 200, 252) | Surf = nouveau drapeau de case **surfable** + règle d'accès selon le mode du déplaceur (§2.1) |
| Déplacement | `GridMover` (pas, pivot, `bumped`), `Player` (marche, course, saut) | Mode Surf : une vitesse, pas de course ; poussée = `bumped` tenu (§2.4) |
| Occupation | `GridWorld.occupy`, `move_occupant` | Un rocher est un occupant ; la poussée utilise `move_occupant` |
| Glissade | `jalon-20:game/world/spin/spin_slide.gd` (trajet précalculé, `can_save()` faux pendant la glissade) | Courants = trajets précalculés de même forme (§2.6) |
| CS | `jalon-16:game/world/field/field_moves.gd` (`State` NO_HM, NO_BADGE, NO_POKEMON, READY ; variantes `move:state`) | SURFER et Force s'appuient sur `status(&"surf")` / `status(&"strength")` |
| Grilles | `tools/plans/*.txt`, `tools/art/plan_grille.py`, `plan_check.Monde` | Nouveaux caractères : eau surfable, courant, rocher, trou (§2.11) |

### 0.3 Ce qui peut commencer maintenant

**Maintenant** (branche `jalon-24`, partie de `origin/main`) :
- T1 à T5 : grilles, émulateur, données, kit d'art ;
- T6 et T9 : logique pure, avec CS et badges simulés en test.

**Après la fusion du J23** (et donc des J16 à J22) : tout ce qui touche une carte réelle, la scène
du monde ou le combat.

## 1. Découpage

### 1.1 Sous-jalons et validations (dossier §17)

| Sous-jalon | Tâches | Validation |
|---|---|---|
| **24.0** | T0 à T5 | Kevin sur planches (grilles, vues peintes, contact d'art) |
| **24A — Surf** | T6 à T8 | **Session S24 seule** |
| **24B — La mer** | T11 à T14 | Session S24 |
| **24C — Îles Écume** | T9, T10, T15 à T17 | **Session S24 seule** |
| **24D — Artikodin + QA** | T18 à T21 | Session S24, puis clôture |

### 1.2 Branches et fichiers chauds

| Fichier | Tâches | Risque |
|---|---|---|
| `game/world/grid_world.gd` | T6, T9 | Moyen : règle unique d'accès, utilisée partout ; ajout pur (nouveaux drapeaux, mode) sans changer le comportement à pied |
| `game/player/player.gd` | T7, T10 | Moyen : mode Surf, poussée |
| `game/autoload/game_state.gd` | T7 | Faible : deux champs facultatifs |
| `data/encounters/*.json`, `EncounterTable.TERRAINS` | T8 | Faible |
| `game/ui/components/interact_button.gd` | T7 | Faible : un verbe `surf` |

Une branche par tâche, fusionnée dans `jalon-24` ; worktree d'intégration dédié (mémoire
« integration-worktree »).

## 2. Conception technique

### 2.1 Eau surfable et règle d'accès (T6)

- **`GridWorld`** : nouveau drapeau de case `_FLAG_SURF`, qui désigne une eau surfable. Il est
  toujours posé **avec** `_FLAG_WATER`, si bien qu'à pied rien ne change.
- **Mode du déplaceur** : `enum MoveMode { WALK, SURF }`, lu sur le déplaceur par
  `get_move_mode()` s'il existe, `WALK` sinon. Les PNJ et le compagnon restent en `WALK`.
- **`can_enter(cell, dir, mover)`** :
  - en `WALK`, la règle actuelle ;
  - en `SURF`, une case `_FLAG_SURF` libre est accessible ; une case de terre praticable aussi
    (c'est la **descente**, signalée par `get_step_target` à l'appelant) ; tout le reste est
    refusé.
- **`find_reachable(start, mover, mode)`** : un paramètre de mode, pour les tests de grille.
- **Cases de courant** : `_FLAG_CURRENT` + direction (2 bits, comme les rebords). Lues par
  `CurrentField` (§2.6), ignorées par `can_enter`.
- **Cases « Surf forcé »** : liste par carte (données de la carte), pas un drapeau de case.

### 2.2 `SurfRules` (pure, T6)

```gdscript
# game/world/surf/surf_rules.gd — pur, statique
## Le joueur peut-il monter, face à [param target] ? (READY, ou l'état FieldMoves qui manque)
static func can_mount(grid: GridWorld, target: Vector2i, field_state: FieldMoves.State) -> FieldMoves.State
## Le pas de [param from] vers [param dir] en Surf : SWIM, DISMOUNT (terre), BLOCKED.
static func step_kind(grid: GridWorld, from: Vector2i, dir: Vector2i) -> StepKind
## Reprise d'une partie : la case où réapparaître et le mode.
static func resume(grid: GridWorld, saved_cell: Vector2i, surfing: bool, last_land: Vector2i,
		spawn: Vector2i, field_state: FieldMoves.State) -> Resume
```

Les cas de `resume` :
- **surfable + READY** : on reprend en Surf ;
- **terre** : on reprend à pied ;
- **sinon** : on reprend sur `last_land` s'il est libre, sinon sur `spawn`.

### 2.3 Mode Surf du joueur (T7)

- **`Player`** :
  - nouvel état `_mode` (`WALK` / `SURF`) et `get_move_mode()` ;
  - en `SURF`, `run` est ignoré ; vitesse ×1,15 [D] ;
  - `CharacterLook` passe sur les planches « Surf » (joueur en buste + monture).
- **Montée** (`SurfDirector`, nœud de carte) :
  1. le compagnon rentre ;
  2. l'animation de saut (≈ 0,5 s) ;
  3. un pas sur l'eau ;
  4. `_mode = SURF`.
- **Descente** : `step_kind == DISMOUNT` → saut sur la rive, `_mode = WALK`, le compagnon ressort.
- **Vélo** : la règle du J22 (§0.1) range le Vélo à la montée.
- **Bouton contextuel** : verbe `surf` (« SURFER ») si la case de face est surfable et l'état READY ;
  EXAMINER sinon, avec le dialogue `surf_water` à variantes `surf:<état>` (textes T-1, T-2).
- **Menu Équipe** : entrée SURF sur le Pokémon compatible (même appel ; T-4 sinon).
- **Bords de carte** : le `Warp` `PUSH` d'un bord transmet le mode ; `SceneRouter` place le joueur
  en Surf si la case d'arrivée est surfable.
- **Warps `STEP_ON`** (grottes) : le joueur arrive à pied, sauf si la case d'arrivée est dans la
  liste « Surf forcé » de la carte.
- **Sauvegarde** : `GameState.player_surfing`, `GameState.last_land_cell`, mis à jour à chaque pas
  à terre.
- **Combat sur l'eau** : à la sortie du combat, le joueur reste en Surf. Après une défaite, il
  passe à pied au Centre.

### 2.4 Nageurs (T8)

- Dresseurs ordinaires (`data/trainers/route_19.json`, `route_20.json`, `route_21.json`), avec un
  `look` Nageur ou Nageuse **sur l'eau** : sprite tête et épaules, ondulation.
- **Ligne de vue** : la règle existante suit les cases ; le Nageur s'approche **en mode SURF** (le
  PNJ porte `move_mode: surf`).
- **Pêcheurs** : vue 0, combat en leur parlant.

### 2.5 Rochers de Force (T9, T10)

- **`BoulderRules`** (pure) :
  - `push(grid, boulder_cell, dir) → {MOVED, FELL(hole_index), REFUSED}` ;
  - refus : eau, mur, escalier ou échelle (cases marquées dans la grille), changement de niveau,
    occupant, autre rocher.
- **`Boulder`** : nœud de carte, occupant de la grille, image « rocher de Force ».
- **Poussée** (`Player`) : si Force est active sur la carte (`FieldMoveState.strength_active`, remis
  à zéro par `SceneRouter` à chaque changement de carte, pas après un combat) et que le joueur bute
  contre un `Boulder` **en tenant la direction 0,25 s** [D] → `BoulderRules.push`.
  - `MOVED` : glissade (0,3 s), puis le joueur avance ;
  - `REFUSED` : tremblement, son ;
  - `FELL` : bascule, poussière, drapeau posé, **sauvegarde forcée**.
- **Activation** : EXAMINER face à un rocher → dialogue `strength_boulder`, à variantes
  `strength:<état>` ; avec READY, choix UTILISER / LAISSER → étape `field_move` (J16/J23).

### 2.6 `SeafoamState` et `CurrentField` (T9)

- **`SeafoamState`** (pure) : à partir des 8 drapeaux, rend pour un étage :
  - les trous bouchés ;
  - les rochers tombés d'au-dessus (cellules fixes) ;
  - les rochers libres (positions d'origine, moins les trous remplis de l'étage, en retirant les
    **derniers** de la liste) ;
  - l'état des courants.

  Les données par étage sont dans `data/world/seafoam.json` : trous, points de chute, rochers
  d'origine, courants avec leurs drapeaux, cases « Surf forcé ».
- **`CurrentField`** :
  - quand le joueur entre sur une case de courant active, il reçoit un trajet précalculé
    (`SpinSlide`, même classe) jusqu'à la case d'arrivée ou jusqu'à un warp ;
  - aucune entrée n'est prise pendant la glissade ; `can_save()` est faux ;
  - le courant 1 se termine par le warp B3F → B4F.

### 2.7 Artikodin (T18)

- Acteur `StaticEncounter`, posé sur la carte et caché si `articuno_done`.
- **OBSERVER** → scène `articuno` : T-20, cri, givre, puis étape `wild_battle articuno 50` avec
  `intro: legendary` (bandeau ≈ 1,5 × plus lent [D]).
- **Issues** :
  - `catch` : `articuno_done`, `articuno_caught` ;
  - `win` : `articuno_done`, puis T-21 ;
  - `flee` et défaite : rien.
- **Sauvegarde** : forcée à la sortie de l'étape, **avant** le premier texte (dossier §8.4).

### 2.8 Fossiles, CT35, Métronome (T12, T13)

- **`FossilLab`** (pure) : états `IDLE` → `REVIVING` → `READY` → `IDLE`.
  - `REVIVING` est posé au dépôt du fossile (objet retiré, drapeau `fossil_reviving_<espèce>`) ;
  - `READY` quand `SceneRouter` charge la carte `cinnabar_island` ;
  - le Pokémon est donné par `PokemonGift` (N30), puis les drapeaux sont effacés dans la même
    sauvegarde.
- **CT35** : remise unique (`got_tm35`), « Sac plein » géré (règle existante).
- **Effet `metronome`** : tirage uniforme parmi les capacités dont l'effet est implémenté, sauf
  Métronome, Lutte et celles qui ont `pending_effects`. La capacité est exécutée comme si le
  Pokémon la connaissait (PP de Métronome consommés). Le tirage passe par le générateur aléatoire
  injecté du combat (tests déterministes).

### 2.9 Sauvegarde : aucun changement de version (v7)

| Ajout | Lecture d'une ancienne sauvegarde |
|---|---|
| `player.surfing` (bool) | `false` |
| `player.last_land_cell` | = `cell` |
| Drapeaux du §13.2 du dossier | absents = non posés |

Les sauvegardes forcées : chute d'un rocher, fin du combat d'Artikodin, don du fossile, CT35.
**Pas de position de rocher.**

### 2.10 Départs de débogage (`tools/debug_start/`)

| Départ | Contenu |
|---|---|
| `surf_qa` | Parmanie (côte sud), CS03, Badge Âme, Tentacool |
| `seafoam_qa` | 1F des Îles Écume, CS03 + CS04, deux badges, équipe N40 |
| `seafoam_b3f_qa` | B3F, 6 drapeaux posés (il ne reste que le B3F) |
| `articuno_qa` | B4F, salle d'Artikodin, équipe N50, 10 Hyper Balls |
| `cinnabar_qa` | Cramois'Île, Fossile Dôme, équipe pleine |

### 2.11 Grilles (`tools/plans/`) — nouveaux caractères

| Caractère | Sens |
|---|---|
| `~` | eau décor (non surfable), comme aujourd'hui |
| `w` | **eau surfable** |
| `^ v < >` sur `w` | **courant** et sa direction |
| `B` | rocher de Force (position d'origine) |
| `O` | trou |
| `F` | point de chute d'un rocher (étage inférieur) |
| `s` | case « Surf forcé » |
| `=` | escalier entre niveaux de sol |

Les grilles des Îles Écume partent du **décodage RB** fait pendant la passe (scripts du scratchpad,
recopiés dans `tools/art/seafoam_rb_decode.py` en T2). Elles sont ensuite élargies hors des zones
de puzzle (dossier §4 : puzzles à 1:1).

### 2.12 Art (lot 24.0)

Le numéro de série est réservé **au moment du push**, après vérification de toutes les branches
distantes : les séries 20 à 25 sont prises ou visées au 2026-10-16 ; on vise la **26**, ou la
première libre.

## 3. Tâches

Rôles : **A** architecte-godot · **C** constructeur-monde · **U** ui-mobile · **Q** qa-mobile ·
**K** Kevin.

### 3.1 Sous-jalon 24.0

#### T0 — A : plan (ce document)

#### T1 — A : branche `jalon-24` depuis `origin/main` — **maintenant**

#### T2 — C : grilles v1 — **maintenant**

- **Cartes** : `route_19.txt`, `route_20.txt`, `route_21.txt`, `cinnabar_island.txt`, les 4 pièces
  du Labo, `seafoam_1f.txt` … `seafoam_b4f.txt`.
- **Contrôle** : `tools/art/plan_check_j24.py`.
  - Raccords des bords (colonnes RB ×1,5) ; eau surfable seulement sur les cartes autorisées ;
    atteignabilité de chaque sortie, à pied et en Surf.
  - **Îles Écume, graphe des 5 étages** :
    - échelles appariées ;
    - recherche exhaustive des positions de rochers (états atteignables par poussée) ;
    - preuve de l'**anti-blocage** (dossier §7.6) ;
    - solution complète ; trajet du courant 1 jusqu'au B4F ;
    - traversée entrée ouest → entrée est **en Surf seul**.
- **Fin** : contrôle « TOUT EST CONFORME », puis K valide les grilles.

#### T3 — A : vérification sur émulateur — **maintenant**

- **Sur pokered compilé**, partie de test avec Surf et Force :
  - le trajet du courant B3F ;
  - la traversée ouest → est sans Force ;
  - la solution du B3F.
- **Résultat** consigné ici.
- **Si la traversée échoue** : on applique le recours de P-6 (chenal au sud de l'île) et on prévient
  K.

#### T4 — A : données — **maintenant**

- Espèces du dossier §14.1 (données ; dos en T5), tables de rencontres (union R+B), équipes des 29
  Dresseurs, objets, `seafoam.json`.
- Capacités des nouvelles espèces jusqu'au N40 : audit et remplacements explicites.
- **Avant d'ajouter une espèce ou une capacité, vérifier qu'aucune session plus ancienne ne l'a
  déjà créée** sur sa branche (doublons du J17, J19 et J20) ; si elle existe, reprendre sa version.

#### T5 — C (Mac, Codex) : kit d'art et vues peintes — **maintenant**

- Série d'art (§2.12) : monture, joueur en Surf, Nageurs, Topdresseur, Ornithologue,
  Scientifique, rocher de Force, rocher dans l'eau, trou bouché, Artikodin dans le monde, fonds
  de combat (mer, grotte glacée), dos des espèces.
- Vues générales : Routes 19, 20, 21, Cramois'Île, 5 étages.
- Planche de contact → K.

### 3.2 Sous-jalon 24A (Surf)

#### T6 — A : eau surfable, `SurfRules`, `GridWorld` (modes, drapeaux) — **maintenant** (logique pure)

- Tests : `test_surf_rules.gd` (montée, descente, blocage, reprise, garde-fou) ;
  `test_grid_world_surf.gd` (rien ne change à pied).

#### T7 — C + U : mode Surf du joueur, verbe SURFER, transitions, sauvegarde — après la fusion du J23 (et le Vélo du J22)

- Tests :
  - intégration : montée et descente sur une carte d'essai ;
  - passage de bord en Surf ;
  - sauvegarde et chargement en mer ;
  - garde-fou (Pokémon de Surf retiré, simulé).

#### T8 — C : rencontres `water`, fond « mer », Nageurs, Routes 19 et 20 — après T7, T2, T4, T5

- Tests : `EncounterTable` sur l'eau ; un Nageur voit et rejoint le joueur en Surf.

#### T8b — Q : **session 24A** → K

### 3.3 Sous-jalon 24B (la mer)

#### T11 — C : Route 21, côte sud de Bourg Palette, côte sud de Parmanie — après T8

- La côte de Parmanie ne se fait qu'après la clôture du J22 et du J23, avec l'accord de K
  (ancienneté).

#### T12 — C : Cramois'Île, Centre, Boutique, Labo, Manoir et Arène fermés — après T2, T5

#### T13 — A : `FossilLab`, CT35, effet Métronome — logique **maintenant**, intégration après T12

#### T14 — Q : **session 24B** → K

### 3.4 Sous-jalon 24C (Îles Écume)

#### T9 — A : `BoulderRules`, `SeafoamState`, `CurrentField` — **maintenant** (logique pure)

- Tests :
  - `test_boulder_rules.gd` ;
  - `test_seafoam_state.gd` (les **256 combinaisons** de drapeaux donnent des étages valides,
    solution toujours possible) ;
  - `test_current_field.gd`.

#### T10 — C : poussée dans `Player`, `Boulder`, activation de Force — après la fusion du J23

#### T15 — C : les 5 étages, chutes du joueur, courants en jeu, objets cachés, rencontres — après T9, T10, T2, T5

#### T16 — C : rocher du Gardien poussable (Parmanie) — après la clôture du J23, accord de K

#### T17 — Q : **session 24C** → K

### 3.5 Sous-jalon 24D (Artikodin et clôture)

#### T18 — C : Artikodin — après T15 et l'étape `wild_battle` du J21

#### T19 — A : simulation d'équilibrage des Dresseurs (outil du J12)

#### T20 — Q : QA finale de bout en bout → K

#### T21 — A : clôture (suite complète, nettoyage des départs de QA, passation au J25)

#### Après la fusion des jalons plus anciens (à faire par le J24)

- **J21** (accord de la session du J21, 2026-10-16) : compléter l'évolution de `poliwag` (→ `poliwhirl`
  N25) et de `tentacool` (→ `tentacruel` N30) dans `data/pokemon/species/kanto_j21.json`, puis
  supprimer les reprises correspondantes. Le J21 ne peut pas le faire lui-même : ses tests refusent
  une évolution vers une espèce absente.
- **J22** (session du J22, 2026-10-16, `docs/dossier-25-j22` à `b75e75a9`) : Magicarpe passe dans `kanto_j22.json`, à l'identique de celui du J24 ; **retirer `magikarp` de `kanto_j24.json`** à la fusion du J22. Ne plus changer ses valeurs sans prévenir le J22. Raccord sud de Parmanie réservé (rangée 53, colonnes 24..32 et 34..35, `warp_sud` `coming_soon=route_19`).
- **Tous** : supprimer chaque fichier `*_reprises.json` dès que sa branche d'origine est fusionnée ;
  régénérer `tm_compatibility.json` ; résoudre `data/pokedex/kanto.json` (fiches ajoutées à la fin).

## 4. Critères d'acceptation

1. `tools/test.sh` passe ; import sans erreur ; captures relues.
2. Les grilles passent `plan_check_j24.py`, y compris l'anti-blocage exhaustif.
3. Rien ne change pour un joueur à pied : les tests existants de `GridWorld` passent sans
   modification.
4. Aucune eau surfable hors des cartes autorisées : test sur toutes les cartes.
5. Une sauvegarde ne dédouble jamais Artikodin, un fossile ni la CT35 (tests de fermeture
   simulée).
6. Les quatre validations S24 du §1.1 sont faites.
