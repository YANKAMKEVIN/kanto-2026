# Passe « systèmes 2 » — déplacement, exploration, combat, sauvegarde en arrière-plan

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/strategie-acceleration.md`, levier 1 (périmètre validé par Kevin le 2026-10-19, deux
> vagues ; **ne pas le rouvrir**). **Questions Q-0 à Q-9 du §8 tranchées par Kevin le 2026-10-19 :
> toutes les recommandations retenues** (« okay pour tes reco »). Le reste a une valeur par défaut
> [D] (règle 4).
>
> Conséquences : départ **après le J20 complet** (Q-0) ; **pêche** dans la passe (S2C-bis, T16b) ;
> K.O. en un coup **moderne** ; Vol avec le **Badge Foudre**, lancé depuis l'**écran Carte** ;
> **Téléport et Tunnel hors combat** (T25b) ; **rencontre légendaire fixe** générique et **lot
> d'effets des grands combats** (S2G, T30, T31) ; reprise **juste avant** un combat ou une scène
> interrompus ; maison de Vol posée **par le J22**.

> Objectif : **après cette passe, un jalon de contenu (J21 à J31) ne contient plus que des données
> et des cartes.** Le joueur peut rouler à Vélo (et dévaler la Piste), surfer, pousser des rochers
> dans des trous et sur des interrupteurs, tomber d'un étage, s'envoler vers une ville, prendre un
> téléporteur, ouvrir une porte avec une carte, jouer de la Poké Flûte. En combat, Empal'Korne,
> Guillotine et Abîme mettent K.O. en un coup. Une partie interrompue par un appel, une
> notification ou le verrouillage reprend sans perte.
>
> Mécaniques nouvelles (toutes génériques, aucune carte réelle) :
> - l'**état « monté »** du joueur (à pied, Vélo, Surf), une seule source de vérité ;
> - le **Vélo**, la **Piste Cyclable** (descente refusée) et la **pente** (dérive) ;
> - l'**objet clé utilisable** (`key_use`) et la **Poké Flûte** (exploration et combat) ;
> - le **Surf** : eau surfable, montée et descente, bords de carte, reprise, rencontres `water`,
>   Nageurs, **courants** ;
> - la **Force** : rochers poussables, **trous**, `Warp` **`FALL`**, **interrupteurs** et
>   **barrières** ;
> - le **Vol** (voyage rapide vers les villes découvertes) ;
> - les **téléporteurs** et les **portes à carte** (Carte Magnétique) ;
> - l'effet de combat **`ohko`** ;
> - la **sauvegarde à la mise en arrière-plan** quand la partie n'est pas stable.
>
> **Format de sauvegarde : v7 inchangé** (champs facultatifs, §2.13). La v8 reste au J23 (Safari).

**Pré-requis (règle de la stratégie, levier 2).** Le code commence **après** la clôture du J19 et la
fusion du **J20** dans `main`. Le présent plan, l'audit et les questions se font avant.

**Code lu** (lecture seule, 2026-10-19) :

| Branche | Commit | Ce qui a été lu |
|---|---|---|
| `main` | `710a3fe9` | `GridWorld`, `GridMover`, `Player`, `Warp`, `SceneRouter`, `FlagGate`, `FieldMoves`, `FlashDirector`, `SwitchPuzzle`, `Boot`, `SaveSystem`, `SaveCoordinator`, `SessionLifecycle`, `MoveData`, `MoveEffect`, `zones.json`, `rest_points.json`, `GameState.discovered_maps` |
| `jalon-19-integ` | `9fc88208` | `GhostRule` (Scope Sylphe) ; `recoil_damage`, `force_switch` réglés |
| `jalon-20` | `c718f669` | `game/world/spin/`, `game/world/elevator/`, `game/systems/gift/`, plan `jalon-20.md` (état : **20.0a seulement**) |
| `jalon-21` | `bf708403` | `PokeFluteRules`, `FluteTarget`, plan `jalon-21.md` §2.1–§2.4 (`key_use`) |
| `jalon-22` | `e8c92d4c` | `BikeRules`, `CyclingSlope`, `FishingRules`, `FishingSpot`, plan `jalon-22.md` §2.1–§2.6 |
| `jalon-23` | `63fc5eaf` | `hm03`, `hm04`, `surf`, `strength` (données), plan `jalon-23.md` §2.10 |
| `jalon-24` | `9a69332a` (logique : `e41bd779`) | `GridWorld` étendu, `SurfRules`, `BoulderRules`, `CurrentField`, `SeafoamState`, `FossilLab`, grilles des Îles Écume, plan `jalon-24.md` §0.4, §2.1–§2.11 |
| `jalon-25` | `f0bbe0ec` | `MansionSwitch`, `GymQuiz`, `InGameTrade`, plan `jalon-25.md` (chute, porte à clé) |
| `main` (passes) | — | `docs/design/passes/j26` à `j31` (téléporteurs, portes, dalles, Force, Sulfura, Ligue, Mewtwo) |

Références : `CLAUDE.md` (règles 1 à 10), skills `godot-conventions`, `world-tiles`,
`ui-theme-2026`, `android-deploy` ; modèles de forme `jalon-17.md`, `jalon-24.md` ;
`boot-coordination.md` (sauvegarde).

---

## 0. État des lieux

### 0.1 Ordre de départ : un point à trancher

La stratégie dit « clore le J19, puis fusionner le J20 (déjà prêt) ». **Sur `origin/jalon-20`, seul
le lot 20.0a est fait** (logique pure des dalles, de l'ascenseur et du don, données, art) : les
sous-jalons **20-I** (Céladopole, ascenseur et don en jeu, Erika) et **20-II** (repaire, dalles en
jeu, Giovanni, Scope) restent à coder et à valider sur téléphone (T9 à T24 de `jalon-20.md`). Deux
lectures possibles :

- **A (recommandée)** : la passe attend la **fusion du J20 complet**. Elle hérite alors des
  directeurs `SpinTileDirector` (glissade jouée) et `ElevatorDirector`, et de la porte de Safrania,
  sans conflit dans `Boot` ni `Player`. En attendant, la passe ne fait que ce plan et peut préparer
  les grilles de QA (§2.14), qui ne touchent aucun fichier de jeu.
- **B** : la passe démarre dès le J19 clos, en parallèle du J20. Gain de quelques jours, mais deux
  sessions dans `Player`, `Boot` et `SceneRouter` en même temps (exactement ce que la stratégie veut
  éviter) ; le lecteur de glissade du J20 serait dupliqué.

C'est une question d'ordre de travail (§8, **Q-0**), pas de game design.

### 0.2 Audit par système

Légende : **écrit** = logique et tests sur une branche ; **partiel** = une partie écrite ;
**absent** = rien dans le dépôt.

| Système | État | Où | Proposition |
|---|---|---|---|
| Accès aux cases selon le mode (`MoveMode` WALK / SURF), eau surfable, courants, niveaux de sol, `can_enter_as`, `get_step_target_as`, `find_reachable(mode)` | **écrit**, testé (`test_grid_world_surf.gd`) | `jalon-24:game/world/grid_world.gd` (+178 lignes, second octet `_sea`) | **Reprendre tel quel.** Ajout pur : à pied, rien ne change (test existant). |
| Règles du Surf : `can_mount`, `step_kind`, `resume` (garde-fou), `next_cell`, `find_reachable` à pied + Surf | **écrit**, testé (`test_surf_rules.gd`) | `jalon-24:game/world/surf/surf_rules.gd` | **Reprendre.** Adapter : `resume` reçoit le mode monté générique (§2.2) au lieu de `surfing: bool`. |
| Poussée d'un rocher : `BoulderRules.push` (MOVED, FELL, REFUSED + raison) | **écrit**, testé (`test_boulder_rules.gd`) | `jalon-24:game/world/boulders/boulder_rules.gd` | **Reprendre.** Adapter : un troisième résultat `ON_SWITCH` (§2.7.4). |
| Courants : `CurrentField.ride` (trajet précalculé, BLOCKED, LOOP, TOO_LONG) | **écrit**, testé (`test_current_field.gd`) | `jalon-24:game/world/seafoam/current_field.gd` | **Reprendre**, déplacé dans `game/world/surf/` (générique : n'importe quelle eau). |
| État d'un donjon à rochers dérivé de drapeaux | **écrit**, testé (256 combinaisons) | `jalon-24:game/world/seafoam/seafoam_state.gd`, `data/world/seafoam.json` | **Laisser au J24** (contenu des Îles Écume). La passe en extrait le modèle « rochers d'origine + trous + drapeaux » vers `BoulderField` générique (§2.7.2) ; le J24 s'y branche. |
| Labo des fossiles | **écrit** | `jalon-24:game/world/fossils/fossil_lab.gd` | **Hors passe** (contenu J24). |
| `Warp` `FALL` (chute dans un trou) | **conçu** (`jalon-24.md` §2.6 bis), pas codé | — | **Coder dans la passe** (§2.7.3) ; le J25 (Manoir, 3F) le réutilise. |
| Règles du Vélo : `can_mount`, `can_dismount`, `step_duration`, `on_map_entered` | **écrit**, testé (`test_bike_rules.gd`) | `jalon-22:game/world/bike/bike_rules.gd` | **Reprendre**, fusionné dans `MountRules` (§2.2) avec une façade `BikeRules` conservée. |
| Pente de la Piste : `CyclingSlope.should_drift` | **écrit**, testé | `jalon-22:game/world/bike/cycling_slope.gd` | **Reprendre.** |
| Mode du joueur (monté), animations, durée de pas, compagnon rentré, bouton HUD Vélo | **conçu** (`jalon-22.md` §2.2, §2.4 ; `jalon-24.md` §2.3), pas codé | — | **Coder dans la passe**, une seule fois pour Vélo et Surf (§2.2). Les deux plans divergeaient (drapeau `riding_bicycle` contre champ `player.surfing`) : un seul champ `player.mount`. |
| Pêche : `FishingRules`, `FishingSpot`, terrain `water_rod` | **écrit** (logique pure), testé | `jalon-22:game/world/fishing/` | **Question Q-1** : le J22 demande qu'elle rejoigne la passe. |
| Objet clé utilisable (`key_use`), Poké Flûte en exploration et en combat | **partiel** : règles pures écrites (`PokeFluteRules`, `FluteTarget`, tests) ; `key_use`, `Kind.KEY_ITEM` et le branchement **conçus** seulement | `jalon-21:game/items/poke_flute_rules.gd`, `flute_target.gd` ; `jalon-21.md` §2.1–§2.4 | **Reprendre** les règles ; **coder** `key_use` dans la passe (le Vélo et les cannes en ont aussi besoin). Le J21 garde ses scènes (Ronflex, Fuji). |
| Scope Sylphe (combat SPECTRE sans l'objet) | **écrit** (`GhostRule`, relu à chaque rencontre dans le Sac) ; objet `silph_scope` au J20 | `jalon-19-integ:game/battle/ghost_rule.gd` ; `jalon-20:data/items/items_j20.json` | **Rien à coder.** La passe ajoute un test de contrat après la fusion du J19 et du J20 (§2.15). L'intro « révélation » du 6F reste au J21 (extension de `wild_battle`). |
| Dalles tournantes (glissade) | **partiel** : règles pures écrites ; directeur (T19) à coder par le J20 | `jalon-20:game/world/spin/` | **Réutiliser** après le J20. La passe généralise le lecteur de glissade pour les courants (§2.6). |
| Ascenseur, don de Pokémon | **partiel** (règles pures) ; directeurs par le J20 | `jalon-20:game/world/elevator/`, `game/systems/gift/` | **Hors passe** : le J26 les consomme. |
| Téléporteurs | **absent** | — | **Coder** (§2.9) : `Warp` de style `TELEPORT`, déplacement dans la même carte sans rechargement. |
| Portes à carte (Carte Magnétique) | **absent** (le J25 fait sa porte à clé par variante de scène) | — | **Coder** un composant `KeyDoor` (§2.10). |
| Interrupteurs et barrières de Force | **absent** (`SwitchPuzzle` du J16 = poubelles de Carmin, sans rapport) | — | **Coder** (§2.7.4) sur `FlagGate.blocking_cells` (barrière) et `BoulderRules` (interrupteur). |
| Vol (voyage rapide) | **absent** ; `GameState.discovered_maps`, écran Carte (`game/ui/menu/map/`), `zones.json` (services `pokemon_center`) existent ; Vol en combat = `charge` invulnérable, comme Tunnel (J14) | — | **Coder** (§2.8). |
| CS03 Surf, CS04 Force | **données** au J23 (`hm03`, `hm04`, capacités) ; entrées de `field_moves.json` prévues au T16 du J23 | `jalon-23:data/items/items_j23.json`, `moves/j23.json` | La passe **pose** `surf`, `strength`, `fly` dans `field_moves.json` ; le J23 les reprend (prévu par son §2.10). |
| K.O. en un coup | **absent** : `pending_effects: ["ohko"]` sur `horn_drill` (`main`), `guillotine` (J23, J24) ; Abîme (`fissure`) pas encore en données | `data/pokemon/moves/moves.json` l. 249 | **Coder** l'effet (§2.11) ; retirer le marqueur des trois capacités. |
| Sauvegarde à la mise en arrière-plan | **partiel** : `SessionLifecycle` + `Boot._notification` écrivent sur `APPLICATION_PAUSED` et `WM_CLOSE_REQUEST`, **seulement si la partie est stable** ; rien sur `FOCUS_OUT` ; rien pendant un dialogue, une scène, un combat | `main:game/systems/session/session_lifecycle.gd`, `game/systems/save/save_coordinator.gd`, `game/boot.gd` l. 517–523 | **Compléter** (§2.12) : point de reprise en mémoire, écrit quand la partie n'est pas stable. Validé **seul**. |

### 0.3 Corrections aux notes de coordination

- `passes/j30-v1-chatgpt.md` (notes) dit qu'aucune sauvegarde n'est déclenchée par la mise en pause :
  **inexact**. Elle existe depuis la consolidation de `Boot` (`refactor/boot-coordination`), mais
  seulement en état stable. Le trou réel est décrit au §2.12.
- `passes/j26-v2-chatgpt.md` (notes) dit le J20 « déjà écrit » pour l'ascenseur et les dalles :
  **logique pure seulement** ; les directeurs sont à faire par le J20 (§0.1).
- Le Scope Sylphe n'a **plus rien à coder** (§0.2).

### 0.4 Systèmes découverts hors périmètre (à proposer, pas à ajouter d'office)

| Système | Jalons qui l'utilisent | État | Question |
|---|---|---|---|
| Pêche (3 cannes, `water_rod`) | J22, puis toutes les eaux (J24, J29, J31) | logique pure écrite au J22 | **Q-1** |
| Rencontre légendaire fixe (`StaticEncounter` : interaction, combat, issues, sauvegarde forcée, consommation unique) | J24 Artikodin, J29 Sulfura, J31 Mewtwo (et Électhor plus tard) | conçu au J24 (§2.7), pas codé | **Q-6** |
| Effets de combat encore en attente : `heal_half` (Soin : Alakazam de Morgane, Mewtwo), `reflect` / `light_screen` (M. Mime), `haze`, `mist`, `rampage` (Mania, Danse Fleur), `two_turn` (Lance-Soleil, Coud'Krâne), `recharge` (Ultralaser : Ligue), `rage`, `mirror`, `metronome` (J24), Vague Psy (CT46, J27 : absente des données) | J24, J27, J28, J30, J31 | absents (marqueurs `pending_effects`) | **Q-7** |
| Téléport et Tunnel **hors combat** (retour au dernier Centre ; sortie de grotte) | J23 (refus dans le Parc), tout le jeu | absents (Téléport et Tunnel existent en combat) | **Q-5** |
| Garde qui contrôle un Badge ou un objet du Sac | J20 (boisson), J22 (Bicyclette), J29 (huit Badges) | variantes de scène `if_flags` / `if_items` (J20, J21) | **Aucun système** : données. Vérifié au T2. |
| Panthéon, générique, Ligue rejouable, Safari, Manoir, quiz, échanges fixes | J23, J25, J30, J31 | propres à leur jalon | **Hors passe** (un seul jalon chacun). |

### 0.5 Propriété (règle d'ancienneté)

La stratégie rend la passe **propriétaire** des systèmes de son périmètre, même écrits par une
session plus ancienne (J22, J24, J21 pour la Flûte). Concrètement :

- la passe **porte** dans sa branche le code pur des J21, J22, J24 listé au §0.2 (copie à l'identique,
  puis adaptation dans un commit séparé) ; ces jalons, à leur reprise, **retirent leur copie** en
  fusionnant `main` (même chemin de fichier : la fusion est triviale si la passe garde les chemins) ;
- **chemins conservés** autant que possible (`game/world/surf/`, `game/world/boulders/`,
  `game/world/bike/`, `game/items/poke_flute_rules.gd`) pour que la fusion des jalons soit sans
  conflit ;
- la passe **ne touche aucune carte de jeu réelle** : tout se valide sur des cartes de QA (§2.14) ;
- la passe **prévient** les sessions J21, J22, J23, J24 (message dans leur `etat-projet.md` à la
  fusion) de ce qui a changé de propriétaire.

---

## 1. Découpage

### 1.1 Sous-jalons et validations

Règle 1 de `CLAUDE.md` : une session téléphone par sous-jalon, jamais trois systèmes à la fois ; la
sauvegarde est validée **seule**.

| Sous-jalon | Contenu | Systèmes | Validation |
|---|---|---|---|
| **S2.0** | Reprise du code pur (J21, J22, J24), légende commune des grilles, cartes de QA, `field_moves.json` | aucun visible | tests + import ; **aucune session téléphone** |
| **S2A** | Sauvegarde à la mise en arrière-plan | 1 (risqué) | **téléphone, seule** |
| **S2B** | État monté + Vélo + Piste et pente ; objet clé utilisable + Poké Flûte | 2 | téléphone |
| **S2C** | Surf (montée, descente, bords, reprise, `water`, Nageurs) + courants | 2 | téléphone |
| **S2C-bis** (Q-1 retenue) | Pêche (3 cannes, `water_rod`) | 1 | téléphone (court) |
| **S2D** | Force : rochers, trous et `FALL`, interrupteurs et barrières | 1 (avec ses deux variantes) | téléphone |
| **S2E** | Vol (+ Téléport et Tunnel hors combat, même mécanique d'arrivée, Q-5) + K.O. en un coup | 2 | téléphone |
| **S2F** | Téléporteurs + portes à carte | 2 | téléphone |
| **S2G** (Q-6, Q-7 retenues) | Rencontre légendaire fixe ; lot d'effets des grands combats (Soin, Protection, Mur Lumière, deux tours, Vague Psy, Buée Noire ; Ultralaser fait au J19, T2) | 2 | téléphone (départs de combat) |
| **S2Z** | Non-régression sur la vraie partie de Kevin, suite complète, clôture, fusion | — | téléphone + fusion |

Ordre : **S2.0** d'abord ; **S2A** en parallèle de S2.0 (fichiers disjoints). Puis **S2B → S2C →
S2D** en série (tous dans `Player`) ; **S2E, S2F, S2G** en parallèle de la série (ils ne touchent ni
`Player` ni `GridMover`, voir §1.2).

### 1.2 Fichiers chauds et parallélisme

| Fichier | Sous-jalons | Règle |
|---|---|---|
| `game/player/player.gd`, `game/world/grid_mover.gd` | S2B, S2C, S2D | **en série**, une branche à la fois |
| `game/world/grid_world.gd` | S2.0 (reprise J24), S2D (interrupteurs : rien dans la grille) | S2.0 seul |
| `game/boot.gd` | S2A, S2B, S2C, S2D, S2E, S2F | chaque sous-jalon ajoute **un** directeur enfant + un bloc `_setup_*()` ; aucune autre ligne ; fusion dans l'ordre d'arrivée |
| `game/autoload/scene_router.gd` | S2C (mode à l'arrivée), S2D (`FALL`), S2E (Vol), S2F (téléporteur même carte) | une méthode chacun ; S2C avant S2D |
| `game/world/warp.gd`, `warp_point.gd` | S2D (`FALL`), S2F (`style`) | ajouts en fin d'énum |
| `game/autoload/game_state.gd` | S2B (`mount`, `last_land_cell`) | un seul ajout |
| `game/battle/*` | S2B (Flûte en combat), S2E (`ohko`), S2G | S2B avant S2E |
| `game/ui/hud/exploration_hud.gd` | S2B (bouton Vélo), S2C (verbe SURFER) | S2B avant S2C |
| `game/ui/menu/map/*` | S2E (Vol) | seul |

Une branche par tâche, fusionnée dans `systemes-2` ; worktree d'intégration dédié (mémoire
« integration-worktree »). Pendant une tâche : `tools/test.sh --changed` ; avant chaque fusion dans
`systemes-2` : CI GitHub (pousser la branche ; le déclencheur couvre `jalon-*` : **ajouter
`systemes-*`** au filtre du workflow, T1).

### 1.3 Grilles : légende commune

Chaque grille garde sa ligne `PRATICABLES` et sa section `POSITIONS`. La passe fixe les **types de
position** génériques (lus par `tools/art/plan_check.py` et par les outils de construction) :

| Type (`POSITIONS`) | Paramètres | Sens |
|---|---|---|
| `rocher` | `ordre=`, `trou=` (facultatif) | rocher de Force, position d'origine (repris du J24) |
| `trou` | `n=`, `drapeau=`, `chute=<carte>` | trou ouvert tant que le drapeau n'est pas posé (J24) |
| `chute_rocher`, `chute_joueur` | `depuis=<carte>:<n>`, `surf=` | point d'arrivée d'une chute (J24) |
| `interrupteur` | `id=`, `drapeau=` | case qui pose le drapeau quand un rocher s'y arrête (§2.7.4) |
| `barriere` | `cases=x,y;…`, `ouverte_si=<drapeau>` | `FlagGate` bloquant, ouvert par le drapeau |
| `teleporteur` | `vers=<carte>:<spawn>`, `paire=` | téléporteur (§2.9) |
| `porte_carte` | `id=`, `cle=<objet>` | porte électronique (§2.10) |
| `courant` | `id=`, `actif=`, `fin=` | courant (J24) |
| `vol_arrivee` | `ville=<zone>` | point d'arrivée du Vol (§2.8) |

Caractères de cases réservés (le J24 les a déjà) : `w` eau surfable, `^ v < >` **sur une ligne de
courant** (J24) ou **dalle** (J20) selon la légende de la grille — pas de mélange dans une même grille
(contrôle). Nouveau [D] : `/` **pente** (Piste), `T` téléporteur, `K` porte à carte, `S`
interrupteur — vérifiés au T3b contre les légendes des 55 grilles existantes (une grille peut
redéfinir un caractère dans sa ligne `PRATICABLES` ; le contrôle refuse un double sens).

**Écart retenu au T3b [D] (2026-10-20)** : `T`, `K` et `S` ont déjà d'autres sens dans une
quarantaine des 68 grilles (tables, comptoirs, panneaux…) ; on ne réserve donc **aucun caractère**.
Les caractères restent propres à chaque grille (légende en tête), et la légende commune porte sur
les **types de positions** ci-dessus : `python3 tools/art/plan_check.py --legende` contrôle, sur
toutes les grilles, les attributs obligatoires (`barriere` accepte aussi `unless=`, forme du J16),
les références (rocher → trou, chute → trou de la carte du dessus, trou → chute du joueur dessous,
téléporteur → repère de la carte visée) et l'absence de courants et de dalles dans une même grille.
68 grilles de `main` et les 5 grilles des Îles Écume du J24 : conformes.

---

## 2. Conception technique

### 2.1 Socle : `GridWorld` étendu (S2.0, T3)

Repris de `jalon-24` (`e41bd779`) sans changement de comportement : second octet `_sea` (surfable,
courant + direction, niveau de sol), `MoveMode { WALK, SURF }`, `Level { ANY, LOW, HIGH, STAIRS }`,
`move_mode_of(mover)`, `can_enter_as`, `get_step_target_as`, `find_reachable(start, mover, mode)`.

- Le Vélo **n'est pas** un mode d'accès : il suit les règles de WALK (rebords compris). Seule la
  Piste interdit la descente (règle de lieu, §2.3).
- `find_path` (PNJ) reste en WALK, sauf un PNJ `move_mode: surf` (Nageurs, §2.5.5).
- Tests repris : `test_grid_world_surf.gd`. Critère : **tous les tests existants de `GridWorld`
  passent sans modification.**

### 2.2 État « monté » du joueur (S2B, T6, T7)

**Une seule source de vérité** pour Vélo et Surf (les plans J22 et J24 en avaient deux) :

```gdscript
# game/player/mount.gd — pur
class_name Mount
enum Kind { NONE, BIKE, SURF }
const NAMES: Array[StringName] = [&"", &"bike", &"surf"]   # valeur sauvegardée
```

```gdscript
# game/world/mount/mount_rules.gd — pur, statique (reprend BikeRules et SurfRules.resume)
class_name MountRules
## Monture à l'arrivée sur une carte (warp, bord, chargement) : garder, descendre, ou monter d'office.
static func on_map_entered(current: Mount.Kind, map: MapTraits, arrival_cell: Vector2i,
		grid: GridWorld, has_bike: bool, surf_state: FieldMoves.State) -> Mount.Kind
## Durée d'un pas : Surf, Vélo, course, marche.
static func step_duration(kind: Mount.Kind, running: bool) -> float
```

- `MapTraits` (pur) : `interior`, `cycling_road`, `no_bike`, `no_fly`, `forced_surf_cells`, lus sur
  `GameMap` (exports existants + nouveaux, §2.14). Le Vélo est permis en **extérieur et en grotte**
  (dossier 25, décidé) : la grotte n'est pas `interior`.
- **`Player`** :
  - `var _mount: Mount.Kind`, `get_mount()`, `set_mount(kind, instant := false)` ;
    `get_move_mode()` rend `SURF` si `_mount == SURF` (lu par `GridWorld.move_mode_of`) ;
  - durée de pas via `MountRules.step_duration` (Vélo 0,12 s [D, J22], Surf = marche × 1/1,15 [D,
    J24]) ; `run` ignoré monté ;
  - `step_started(…, kind)` : `&"bike"` ou `&"surf"` ;
  - `CharacterLook` : jeux d'animations `bike_*`, `surf_*` (placeholders tant que l'art n'est pas
    là : règle 3 ; le code ne bloque pas sur l'art) ;
  - signal `mount_changed(kind)`.
- **`MountDirector`** (`Node`, enfant de `Boot`, comme `FlashDirector`) : monte et descend avec la
  petite mise en scène (saut ≈ 0,5 s pour le Surf, aucune pour le Vélo), rentre et ressort le
  **compagnon** (`Companion.withdraw` / `appear`), applique `MountRules.on_map_entered` à chaque
  `SceneRouter.map_entered`, met à jour `GameState.last_land_cell` à chaque pas à terre.
- **Combat** : on reste monté à la sortie ; défaite → à pied (retour au Centre, intérieur).
- **Sauvegarde** : `GameState.player_mount` (`""` / `"bike"` / `"surf"`), `last_land_cell` (§2.13).

### 2.3 Vélo, Piste Cyclable et pente (S2B, T6–T9)

Conception reprise de `jalon-22.md` §2.1–§2.4 (Kevin, dossier 25), avec les noms de la passe :

- **Monter / descendre** : objet clé `bicycle` → `key_use` `bike` (§2.4) dans le Sac, **et** bouton
  rond `BikeButton` du HUD (`RoundButtonVisual`, icône SVG, au-dessus du bouton Course [D, J22]),
  visible si la Bicyclette est dans le Sac, grisé en intérieur et sur la Piste (le toucher affiche le
  refus) ; action clavier `bike` (touche B) pour les tests desktop.
- **Refus** : intérieur (texte dossier 25 §16.1.3) ; descente sur la Piste (§16.1.4).
- **Piste** : `GameMap.cycling_road: bool` ; à l'arrivée, `on_map_entered` monte d'office si le
  joueur a la Bicyclette (le garde de l'entrée refuse sinon : donnée du J22).
- **Pente** : cases marquées `/` dans la grille → drapeau de case `slope` posé par l'outil
  (`GridWorld` : un bit libre de `_sea`, bit 6 [D]). `Player._process` : direction nulle +
  `CyclingSlope.should_drift(…)` → un pas vers le bas par le chemin normal de `GridMover` (collisions,
  rebords et vue des Dresseurs inchangés). Aucun verrou d'entrée.
- Textes : ceux du dossier 25 §16 (validés) ; la passe les place dans `data/dialogues/mount.json`
  (fichier nouveau) pour qu'ils existent avant le J22.

### 2.4 Objet clé utilisable et Poké Flûte (S2B, T10, T11)

Conception reprise de `jalon-21.md` §2.1–§2.4 (Kevin, dossier 24) :

- `ItemData.key_use: StringName` ; `KEY_USES = [&"poke_flute", &"bicycle", &"old_rod", &"good_rod",
  &"super_rod"]` (les cannes seulement si Q-1 = oui) ; un objet clé avec `key_use` a les contextes
  exploration + combat (la Flûte) ou exploration seule (Vélo, cannes).
- **Exploration** : `MenuDirector` → `field_item_requested` → `Boot` aiguille par `key_use`
  (aujourd'hui seulement la Corde Sortie, `boot.gd` `_on_field_item_requested`) : `bike` →
  `MountDirector`, `poke_flute` → `PokeFluteRules.field_target` (scène du dormeur voisin, ou « joue
  ailleurs »).
- **Combat** : `BattleAction.Kind.KEY_ITEM` (fin d'énum), `Battle._play_flute` : réveille tous les
  endormis des deux camps (`PokeFluteRules.sleepers`) ; sans dormeur, le tour n'est pas pris.
- **Données** : `poke_flute` reçoit `key_use` (le J21 l'a laissé sans, exprès) ; `bicycle` créé ici
  si le J22 ne l'a pas encore en `main` (même identifiant).
- Les **scènes** (Ronflex, Fuji, remise) restent au **J21**.

### 2.5 Surf (S2C, T12–T16)

Conception reprise de `jalon-24.md` §2.2–§2.4, sans les cartes :

1. **Montée** : face à une eau surfable, verbe **SURFER** du bouton contextuel si
   `FieldMoves.status(&"surf") == READY` ; sinon EXAMINER et dialogue `surf_water` à variantes
   `surf:<état>` (textes du dossier 27 T-1, T-2, validés). Aussi depuis la fiche du Pokémon
   compatible si Q-4 retient l'entrée dans le menu Équipe. `SurfRules.can_mount` → `MountDirector`.
2. **Nage / descente** : `SurfRules.step_kind` ; `DISMOUNT` → saut sur la rive, `Mount.NONE`,
   compagnon ressorti.
3. **Bords et warps** : un `Warp` `PUSH` de bord transmet la monture ; `MountRules.on_map_entered`
   met en Surf si la case d'arrivée est surfable ; un `Warp` `STEP_ON` arrive à pied sauf case
   « Surf forcé » de la carte.
4. **Reprise** : `SurfRules.resume` (garde-fou : `last_land_cell`, puis spawn ; `has_exit`).
5. **Nageurs** : PNJ avec `move_mode: surf` (données) ; la ligne de vue existante, le déplacement
   vers le joueur en SURF.
6. **Rencontres** : terrain `water` (déjà dans `EncounterTable.TERRAINS` sur `jalon-24`) ;
   `EncounterDirector.terrain_at` rend `water` sur une case surfable, en Surf.
7. **Courants** (§2.6) : entrée sur une case de courant actif → glissade.
8. **Entrées `field_moves.json`** : `surf` (`hm03`, `badge_soul`), `strength` (`hm04`,
   `badge_rainbow`) — les valeurs du plan du J23 §2.10 ; `fly` (`hm02`, Q-3).

### 2.6 Glissades forcées : un seul lecteur (S2C, T15)

Le J20 code `SpinTileDirector` (T19 du J20) qui joue un `SpinSlide` pas à pas, sans entrée, sans
sauvegarde (`can_save()` faux). La passe le **généralise** en `ForcedSlideDirector` qui accepte tout
trajet de forme `SpinSlide` : dalles (J20, J28), courants (`CurrentField.ride`, déjà de même forme).
`Boot.is_stable()` reste faux pendant une glissade. La fin d'un courant peut être un warp
(`Ride.warp`). Pas de nouveau directeur si celui du J20 est déjà générique : on le renomme seulement.

**Fait (T15)** : `game/world/forced_slide/` — `ForcedSlide` (forme commune ; `SpinSlide` et
`CurrentField.Ride` en héritent), `ForcedSlideDirector` (ex-`SpinTileDirector`, verrou
`forced_slide`, signaux `slide_started` / `slide_finished` / `warp_reached`, `ride_from_here()` à
l'arrivée) ; `Boot.get_forced_slide_director()` (alias `get_spin_director()`) ;
`SceneRouter.follow_warp_at(cell, direction)` pour le passage au bout d'un courant.

### 2.7 Force (S2D, T17–T22)

#### 2.7.1 Activation

- EXAMINER face à un rocher → dialogue `strength_boulder` à variantes `strength:<état>` ; READY →
  UTILISER / LAISSER → étape `field_move` (J16) → `FieldMoveState.strength_active = true`.
- Remis à zéro à **chaque changement de carte** (`SceneRouter.map_changed`), **pas** après un combat
  (J24 §2.5, comme RB).

#### 2.7.2 Rochers

- **`Boulder`** (`Node2D`, occupant de la grille, image « rocher de Force », placeholder admis).
- **`BoulderField`** (pur, nouveau) : positions d'origine des rochers d'une carte, trous ouverts
  (`trou` + `drapeau`), interrupteurs (§2.7.4), cases interdites (`no_push`). Construit par la carte
  à l'entrée depuis ses `POSITIONS` et les drapeaux. Le `SeafoamState` du J24 s'y branche pour ses
  règles propres (rochers tombés d'au-dessus, rocher désigné), sans que la passe en dépende.
- **Poussée** (`Player`) : Force active + `bumped` tenu **0,25 s** [D, J24] contre un `Boulder` →
  `BoulderRules.push` :
  - `MOVED` : glissade 0,3 s [D], le joueur avance ;
  - `REFUSED` : tremblement, son (rien si pas de son) ;
  - `FELL` : bascule, poussière, drapeau du trou posé, **sauvegarde forcée** ;
  - `ON_SWITCH` : comme `MOVED`, puis drapeau de l'interrupteur, **sauvegarde forcée** (§2.7.4).
- **Aucune position de rocher n'est sauvegardée** (J24, RB) : changer de carte ou recharger remet
  les rochers libres à leur origine ; les trous bouchés et les interrupteurs restent (drapeaux).

#### 2.7.3 `Warp` `FALL` (chute du joueur)

- `Warp.Trigger.FALL` (fin d'énum) : le joueur termine un pas sur la case → petit saut, fondu court,
  arrivée sur `target_spawn` de la carte inférieure (Surf forcé si la case le demande).
- `unless_flags` : un trou bouché ne fait plus tomber (même règle que `FlagGate`).
- Aucune règle propre aux Îles Écume : le J25 (Manoir 3F) l'utilise tel quel.

#### 2.7.4 Interrupteurs et barrières (Route Victoire)

- **Interrupteur** : case `interrupteur` de `BoulderField` avec un drapeau. `BoulderRules.push` rend
  `ON_SWITCH` quand la case visée est un interrupteur libre (le rocher s'y arrête). Le drapeau est
  posé **une fois pour toutes** [D, RB : `EVENT_VICTORY_ROAD_*_BOULDER_ON_SWITCH`].
- **Barrière** : `FlagGate` existant, `blocking_cells` + `unless_flags: [<drapeau>]` ; Boot la
  réapplique au drapeau posé (mécanisme existant du J17). Image de barrière : placeholder.
- **Persistance** [D, RB] : barrière ouverte = permanente (drapeau) ; le rocher posé sur
  l'interrupteur revient à son origine au prochain chargement de la carte, l'interrupteur reste
  enfoncé (dessin « enfoncé » si le drapeau est posé).
- **Anti-blocage** (exigence du dossier J29) : un outil **générique**
  `tools/art/plan_check_boulders.py` (extrait de `plan_check_j24_seafoam.py`) explore tous les états
  atteignables par poussée d'une carte (rochers, trous, interrupteurs, barrières) et **prouve** que
  la sortie reste atteignable depuis chaque état. Une grille qui échoue n'est pas construite. Le
  J24 et le J29 s'en servent ; la passe le teste sur ses cartes de QA.

### 2.8 Vol (S2E, T23–T25)

- **Destinations** : `data/world/fly_points.json` (fichier nouveau) : zone (`zones.json`) → carte,
  spawn d'arrivée (devant le Centre ; Bourg Palette : devant la maison [D, RB]). Une destination est
  **ouverte** si une carte de la zone est dans `GameState.discovered_maps` [D, RB : villes
  visitées]. Aucun champ de sauvegarde nouveau.
- **Conditions** : `FieldMoves.status(&"fly")` (CS02, Badge : **Q-3**) ; refusé en intérieur et sur
  une carte `no_fly` (Parc Safari J23, Ligue J30, grottes [D, RB]).
- **Lancement** : **Q-4** (recommandation : depuis l'écran **Carte** du Menu Dresseur, bouton
  « S'envoler » sur une ville ouverte ; la carte existe déjà, `game/ui/menu/map/`).
- **Mise en scène** : fermeture du menu, compagnon rentré, envol (≈ 1 s), fondu, arrivée à pied.
  `SceneRouter.change_map` normal (autosave d'arrivée habituelle).
- **En combat** : capacité `fly` = effet `charge` existant (`invulnerable`, comme Tunnel J14) + textes ;
  données seulement.
- **Logique pure** : `FlyRules` (`can_fly`, `destinations(zones, discovered, points)`).

### 2.9 Téléporteurs (S2F, T26, T27)

Rouge/Bleu : une case qui transporte vers une case fixe, de la même carte ou d'une autre ; arriver sur
un téléporteur ne le déclenche pas.

- `Warp.style: Style { DOOR, TELEPORT }` (défaut DOOR) ; un téléporteur est un `Warp` `STEP_ON`
  de style TELEPORT. **Aucune boucle** : `SceneRouter` ne déclenche rien à l'apparition (règle
  existante du `Warp`), donc pas de verrou d'arrivée à ajouter [D].
- **Même carte** : `SceneRouter.relocate(spawn, facing)` — fondu court (≈ 0,25 s) ou dissolution,
  le joueur est replacé sans recharger la carte (étages de la Sylphe : grandes cartes). Autre carte :
  `change_map` avec le même effet.
- **Données** : chaque grille liste ses `teleporteur` (`vers=`, `paire=`) ; l'outil de construction
  crée les `WarpPoint`. **Contrôle** `tools/art/plan_check_teleports.py` : chaque téléporteur mène à
  un spawn qui existe, aucune paire orpheline, et un graphe des salles (atteignabilité de la cible
  depuis l'entrée, retour toujours possible) imprimé pour la revue.
- Orientation à l'arrivée : celle du joueur [D].

### 2.10 Portes à carte (S2F, T28)

- **`KeyDoor`** (`Node2D`, sous-classe de `FlagGate`) : `door_id`, `key_item` (défaut
  `card_key`), `blocking_cells` ; ouverte si le drapeau `door_<carte>_<id>_open` est posé.
- Le joueur, face à la porte, appuie sur Action : avec la clé → animation d'ouverture, drapeau posé,
  **sauvegarde demandée** ; sans → texte « Il faut une carte. » [D, à faire valider en lot]. Le
  bouton contextuel montre OUVRIR [D].
- **Une seule clé ouvre toutes les portes** de la carte [D, RB] ; la porte reste ouverte pour
  toujours.
- Le J25 garde sa porte à clé de l'Arène (variante de scène) ; il **peut** passer sur `KeyDoor` à sa
  reprise (sans obligation).

### 2.11 K.O. en un coup (S2E, T29)

- `pending_effects: ["ohko"]` devient un vrai effet `MoveEffect.Kind.OHKO` (fin d'énum), données
  `{ "kind": "ohko" }`.
- **Règle : Q-2.** Recommandation : règle **moderne**, cohérente avec le moteur (table des types
  moderne, critiques modernes) — échoue si le niveau du lanceur est inférieur à celui de la cible ;
  précision = 30 + (niveau du lanceur − niveau de la cible), les niveaux de précision et d'esquive ne
  comptent pas ; immunités de type ordinaires (Abîme ne touche pas un Pokémon Vol, Empal'Korne ne
  touche pas un Spectre) ; rate une cible sous terre ou en l'air.
- Messages : « C'est un K.O. en un coup ! » (texte à valider) ; dégâts = PV restants de la cible.
- **IA** : ne choisit pas une capacité `ohko` qui échoue d'avance (niveau inférieur) [D].
- Données : retirer le marqueur de `horn_drill` (`main`) ; `guillotine` (J23, J24) et `fissure`
  (Abîme, CT27, J28) sont créés par leurs jalons **avec** l'effet ; la passe ajoute `fissure` si
  aucun jalon ne l'a en `main` (même identifiant).
- `tools/audit_pending_moves.py` et `docs/tech/audit-pending-moves.md` régénérés.

### 2.12 Sauvegarde à la mise en arrière-plan (S2A, T4, T5) — **validée seule**

**Existant** (`main`) : `SessionLifecycle.handle_notification` rend vrai sur
`APPLICATION_PAUSED` et `WM_CLOSE_REQUEST` ; `Boot` appelle alors
`SaveCoordinator.flush_if_stable("arrière-plan")`, qui **n'écrit rien** si la partie n'est pas
stable (dialogue, scène, rencontre, combat, transition, glissade). Écriture atomique (`.tmp` puis
`rename`), reprise après échec (5 s). `FOCUS_OUT` (rideau de notifications, appel en bandeau) ne
fait rien.

**Trous** :
1. Appel ou verrouillage **pendant** un dialogue, une scène ou un combat : aucune écriture. Si
   Android tue l'application, tout ce qui s'est passé depuis la dernière autosave est perdu (pas
   depuis le début du combat : depuis la dernière autosave, qui peut être plus ancienne).
2. `FOCUS_OUT` sans `PAUSED` (bandeau d'appel, rideau) : rien, alors que c'est souvent le prélude
   d'un arrêt.

**Conception** :
- **Point de reprise** (`SaveCheckpoint`, pur, dans `game/systems/save/`) : un instantané complet
  (`Boot._persist_snapshot` sans écriture) **capturé à chaque passage stable → instable** (début
  d'un dialogue, d'une scène, d'une rencontre, d'un combat) et à chaque autosave réussie. Il porte
  un **numéro de révision** monotone.
- **Révision du disque** : chaque écriture (autosave, écriture immédiate d'une scène, Menu)
  incrémente une révision. **On n'écrit jamais un point de reprise plus ancien que le disque** (une
  scène qui a fait une écriture immédiate, par exemple un don, l'a dépassé : alors on n'écrit rien).
- **Mise en arrière-plan** (`PAUSED`, `WM_CLOSE_REQUEST`, et **`FOCUS_OUT`** avec un délai de garde
  de 1 s [D] pour ne pas écrire à chaque bandeau) :
  - partie stable → écriture de l'état courant (comme aujourd'hui) ;
  - partie instable → écriture du **point de reprise** s'il est plus récent que le disque ;
  - jamais deux écritures en moins de 2 s [D].
- **Effet pour le joueur** (Q-8, recommandation) : tué pendant un combat ou une scène, il reprend
  **juste avant** ce combat ou cette scène (comme Rouge/Bleu), jamais au milieu. Aucune duplication
  possible : un point de reprise est un état passé cohérent, et un don ou une capture fait déjà une
  écriture immédiate qui le dépasse.
- **Ligue (J30)** : la tentative en cours relève du J30 (« progression temporaire de la tentative »).
  La passe garantit seulement qu'un arrêt reprend au dernier état stable écrit.
- **Coût** : l'instantané est construit en mémoire à quelques moments (pas à chaque image) ;
  mesurer la durée sur S24 (`OS.get_ticks_usec`), budget < 5 ms [D].
- **Tests** : `SaveCheckpoint` (révisions, refus d'un instantané plus ancien) ; `Boot` + `MemoryFs` :
  pause pendant un dialogue → point de reprise écrit ; pause après une écriture immédiate → rien ;
  `FOCUS_OUT` puis `FOCUS_IN` en moins de 1 s → rien ; écriture qui échoue → nouvelle tentative.
- **QA téléphone** (§6) : appel simulé, bouton marche, accueil + `am kill`, rideau ; à chaque fois,
  relance et comparaison.

### 2.13 Sauvegarde : aucun changement de version (v7)

| Ajout | Lecture d'une ancienne sauvegarde |
|---|---|
| `player.mount` (`""`, `"bike"`, `"surf"`) | `""` (à pied) |
| `player.last_land_cell` | = `cell` |
| Drapeaux : trous, interrupteurs, portes (`door_*_open`) | absents = non posés |

Lecture par `JsonFields.get_*` avec valeur par défaut, comme le J24 l'avait prévu. Les drapeaux
`riding_bicycle` (plan J22) et `player.surfing` (plan J24) **ne sont jamais écrits** : ils n'existent
que dans les plans. Le J23 garde la **v8** (compteur Safari) : la passe n'y touche pas ; si la v8
arrive avant la fin de la passe, les champs ci-dessus restent facultatifs dans la v8.

### 2.14 Cartes de QA et départs de débogage

Aucune carte de jeu réelle. Cartes construites depuis des grilles de `tools/plans/qa_*.txt`, avec le
kit existant et des placeholders ; **retirées à la clôture** (S2Z), comme au J16.

| Carte | Contenu |
|---|---|
| `qa_mount` | extérieur avec rebords, entrée d'un intérieur, tronçon `cycling_road` avec pente et paliers, un Dresseur sur la pente, un dormeur (Flûte) |
| `qa_sea` | côte, mer surfable, eau décor, un courant qui finit sur un warp, un Nageur, rencontres `water`, bord de carte en mer vers `qa_sea_2` |
| `qa_strength` et `qa_strength_b1` | rochers, deux trous vers l'étage inférieur, un interrupteur + barrière, une case `no_push`, preuve anti-blocage |
| `qa_teleport` | 4 salles reliées par téléporteurs (même carte et autre carte), deux portes à carte, la Carte Magnétique au sol |
| `qa_fly` | aucune : départ de débogage avec des villes découvertes |

Départs (`tools/debug_start/`) : `s2_save` (partie banale pour la QA d'interruption), `s2_bike`,
`s2_surf`, `s2_strength`, `s2_fly` (6 villes découvertes, CS02, badge), `s2_teleport`, `s2_ohko`
(combat contre un Pokémon de niveau inférieur avec Empal'Korne).

### 2.15 Scope Sylphe : contrat seulement

Après la fusion des J19 et J20 : un test d'intégration `test_scope_contract.gd` — rencontre de la
Tour sans `silph_scope` → SPECTRE ; avec → normal ; étape `ghost: always` → SPECTRE même avec. Aucun
code.

### 2.16 Budgets

- 60 fps sur S24 (et le téléphone de la session) sur `qa_sea` (eau animée), `qa_strength`
  (glissade des rochers), `qa_teleport`.
- Tests : la passe ajoute ≈ 400 à 600 tests [estimation] ; aucun test de temps réel
  (`tools/check_test_timing.sh`).

---

## 3. Tâches

Rôles : **A** architecte-godot · **C** constructeur-monde · **U** ui-mobile · **Q** qa-mobile ·
**K** Kevin.

### 3.1 S2.0 — Reprise et socle (aucun téléphone)

#### T0 — A : plan (ce document) — fait

#### T1 — A : branche d'intégration `systemes-2` depuis `main` (J20 compris) ; workflow CI : ajouter `systemes-*` au déclencheur

**Partiel (2026-10-20)** : `main` à `ad2a296f` (J19 clos) fusionné dans `systemes-2` ; le J20 sera
fusionné à son tour. CI : **ne pas** ajouter `systemes-*` (Kevin a retiré `jalon-*` du déclencheur,
quota GitHub épuisé, `bf45055b`) ; la suite locale `tools/test.sh` fait foi.
**Fait (2026-10-20)** : `main` à `537c40f0` (J20 terminé) fusionné dans `systemes-2` ; conflits
(ajouts des deux côtés) dans `battle_event.gd`, `battle_text.gd`, `plan_check.py`, `etat-projet.md`.

#### T2 — A : audit d'alignement sur `main` du moment

- Revérifier chaque ligne du §0.2 sur le code fusionné (J19, J20) ; noter les écarts ici.
- Vérifier que les gardes à Badge ou à objet (J20, J22, J29) passent par les variantes existantes
  (§0.4) ; sinon, le signaler.

**Partiel (2026-10-20, `main` à `ad2a296f`, J19 compris ; à refaire pour le J20)** :
- `GhostRule` est en `main` (J19) : le contrat du Scope (§2.15) attend seulement l'objet
  `silph_scope` du J20.
- **Ultralaser (recharge) est fait** par le J19 (`Battle._start_recharge`, `_recharge_turn`) : il
  sort du lot S2G. Marqueurs `pending_effects` restants en `main` : `ohko` (Empal'Korne, S2E),
  `heal_half`, `reflect`, `light_screen`, `haze`, `two_turn` + `charge_def_up` (Lance-Soleil,
  Coud'Krâne) pour S2G ; `rampage`, `rage`, `mirror`, `metronome` hors lot (Q-7). `mist` n'est pas
  encore en données.

**Refait (2026-10-20, `main` à `537c40f0`, J20 terminé, fusionné dans `systemes-2`)** :
- **Fichiers chauds** (§1.2) : le J20 n'a touché que `game/boot.gd` (+123 lignes : directeurs des
  dalles, de l'ascenseur, du don, sources des variantes). `player.gd`, `grid_mover.gd`,
  `scene_router.gd`, `game_state.gd`, `warp*.gd`, `exploration_hud.gd` et `game/systems/save/`
  sont inchangés : les branchements prévus restent valables. Sauvegarde toujours en **v7** (§2.13).
- **Dalles** (§2.6, T15) : `SpinTileDirector` (`game/world/spin/`) joue un `SpinSlide` (`cells`,
  `facings`, `end`, `steps_done`) ; il bloque le joueur (`LOCK_REASON`, `Boot.is_stable` faux) et
  rentre le compagnon via `slide_started`. `CurrentField.Ride` a `cells` et `warp` mais pas
  `facings` : T15 = généraliser ce directeur (direction déduite de la case suivante, fin sur un
  warp), pas en écrire un second.
- **Ascenseur, don** : `ElevatorDirector`, `PokemonGift` en `main` ; hors passe, comme prévu.
- **Scope Sylphe** (§2.15) : le contrat est **déjà couvert** par les tests du J19 et du J20
  (`test_ghost_encounter` : sans Scope → SPECTRE ; `test_tower_scope_j20` : tables de la Tour
  `ghost_unless_item: silph_scope`, rencontre identifiée avec le Scope, 6F `ghost: always` même
  avec). `test_scope_contract.gd` n'est **pas** écrit (doublon).
- **Gardes à objet** (§0.4) : le J20 a ajouté au moteur les variantes `if_items` / `unless_items`
  (Sac) et `if_zone` (T25, boisson des postes de Safrania) : les gardes du J22 (Bicyclette) et du
  J29 (Badges) n'ont besoin que de données. Aucun système à ajouter.
- **Effets en attente** en `main` après le J20 : `rampage` (×2), `rage`, `mirror`, `metronome`,
  et **`mist`, désormais en données** (Brume, `moves/celadon.json`, J20) ; tous hors lot (Q-7).
  Plus aucun `ohko`, `heal_half`, `reflect`, `light_screen`, `haze`, `two_turn` en attente.
- **Grilles** : la légende commune refusait l'affiche du Casino (`interrupteur` avec `flag=`, J20) ;
  `plan_check.py` accepte `drapeau=` ou `flag=` pour ce type. `--legende` : 97 grilles conformes.
- **Vol** : le point d'arrivée de Céladopole (`fly_points.json`, T23) visait `from_center` ; la carte
  du J20 a une porte double : **`from_center_w`** [D]. Suite complète après fusion : 6 235 / 6 236,
  le seul échec étant celui-ci, corrigé (`test_fly_rules` vert).

#### T3 — A : reprise du code pur, à l'identique puis adapté

- Commit 1 (copie exacte, auteur d'origine cité) : `grid_world.gd` (J24), `surf_rules.gd`,
  `boulder_rules.gd`, `current_field.gd` (J24), `bike_rules.gd`, `cycling_slope.gd` (J22),
  `poke_flute_rules.gd`, `flute_target.gd` (J21) [+ `fishing/` si Q-1], et leurs tests.
- Commit 2 : adaptations (§2.2 `Mount`, `MountRules`, `MapTraits` ; `ON_SWITCH` ; `CurrentField`
  dans `surf/`).
- Tests : tous repris verts ; `GridWorld` existant inchangé.

**Fait (2026-10-20, avant la fusion du J20 : décision de Kevin « avance sur tout ce qui ne
nécessite pas J20 »)** :
- commit 1 : copie exacte (J24 `9a69332a`, J22 `e8c92d4c`, J21 `bf708403`), pêche comprise
  (`data/fishing/water_rod.json` ; `data/world/fishable.json` reste au J22, ses cartes) ; seul
  écart : `test_current_field.gd` sans ses tests sur les grilles des Îles Écume (restent au J24) ;
- commit 2 : `Mount` (`game/player/mount.gd`), `MapTraits` et `MountRules`
  (`game/world/mount/`) ; `SurfRules.resume` prend la monture sauvegardée (`Mount.Kind`, le Vélo
  est gardé sur la terre) et rend `Resume.mount` ; l'énum `SurfRules.Mount` du J24 devient
  `SurfRules.MountCheck` (le nom `Mount` est la classe de la monture) ; `BoulderRules.push` reçoit
  les interrupteurs et rend `ON_SWITCH` (+ `switch_id`) ; `CurrentField` déplacé dans
  `game/world/surf/`. `BikeRules` reste tel quel (façade ; un test vérifie que `MountRules` donne
  les mêmes réponses).
- `MountRules.on_map_entered` ne prend pas l'état du Surf (`FieldMoves`) prévu au §2.2 [D] : on ne
  se tient pas sur l'eau, l'arrivée sur une eau surfable met donc toujours en Surf ; les garde-fous
  restent dans `SurfRules.resume`.
- **À reprendre par le J24 à sa fusion de `main`** : `SurfRules.Mount` → `MountCheck`,
  `resume(…, surfing: bool, …)` → `resume(…, Mount.Kind, …)`, `Resume.surfing` →
  `Resume.is_surfing()`, chemin de `CurrentField`.

#### T3b — A : `field_moves.json` (surf, strength, fly) ; légende des grilles (§1.3) dans `plan_check.py`

**Fait (2026-10-20)** : `surf` (`hm03`, `badge_soul`), `strength` (`hm04`, `badge_rainbow`), `fly`
(`hm02`, `badge_thunder`, Q-3) ; test `test_field_moves_systemes2.gd` (NO_HM tant que la CS n'est
pas en données). Légende : `plan_check.py --legende` (écart du §1.3 : types de positions, pas de
caractères réservés) ; quatrième piège dans `plan_check_systemes2.py --autotest`.

#### T3c — C : grilles et cartes de QA (§2.14), sans vie

- Peut commencer **avant** le J20 (grilles et contrôle seulement, aucun fichier de jeu).

**Fait (2026-10-19, grilles seulement)** : `tools/plans/qa_mount.txt` (+ `qa_mount_interieur`),
`qa_sea.txt`, `qa_sea_2.txt`, `qa_strength.txt`, `qa_strength_b1.txt`, `qa_teleport.txt`,
`qa_teleport_2.txt`. Contrôle générique `tools/art/plan_check_systemes2.py` (≈ 7 s) : **TOUT EST
CONFORME** ; `--autotest` vérifie qu'il refuse trois pièges (rocher qui mure la sortie, téléporteur
vers un point inexistant, courant en boucle). Il pose aussi la base de T21 (anti-blocage, une carte
à la fois ; les cinq étages des Îles Écume gardent le contrôle du J24) et de T27 (graphe des
téléporteurs, plusieurs cartes, portes à carte). Écart au §2.14 [D] : chaque rocher de `qa_strength`
est **confiné dans un couloir** (comme les puzzles de RB) ; quatre rochers libres dans un hall
donnaient plus de 500 000 états. Les cartes `.tscn` (sans vie) attendent le J20 (fichiers de jeu).

### 3.2 S2A — Sauvegarde en arrière-plan (validée seule)

#### T4 — A : `SaveCheckpoint`, révisions, `FOCUS_OUT` (§2.12) — après T1, en parallèle de T3

**Partie pure faite (2026-10-20)** : `game/systems/save/save_checkpoint.gd` : `capture`,
`note_written` (l'instantané écrit devient le point de reprise, pas plus récent que le disque),
`decide` (stable → état courant ; instable → point de reprise s'il est plus récent ; rien à moins de
2 s de la dernière écriture), délai de garde de `FOCUS_OUT` (1 s, un seul déclenchement).
`test_save_checkpoint.gd`. **Branchement fait (2026-10-20, branche `s2a-sauvegarde`)**, voir ci-dessous ; avant : : branchement dans `Boot` (capture aux passages
stable → instable, `note_written` dans l'écrivain, `FOCUS_OUT` / `FOCUS_IN` via `SessionLifecycle`),
tests `Boot` + `MemoryFs`, mesure de la capture sur S24, session S2A (validée seule).

**Branchement dans `Boot` (2026-10-20)** — bloc « Passe systèmes 2, S2A » en fin de `boot.gd`
(`_setup_save_checkpoint`) et trois points d'appel d'une ligne (`_process`, `_notification`,
`_persist_snapshot`) :
- **capture** : `Boot._process` compare `is_stable()` à l'image précédente ; au passage stable →
  instable (et si l'écriture est permise), `GameState.to_dict()` est capturé avec la **position
  de la dernière image stable** (retenue à chaque image stable, passée par
  `ElevatorDirector.stable_location` : jamais sur une dalle tournante ni dans une glisse). Écart
  [D] : le reste de l'état est celui de la **première image** de l'instabilité (ce qu'a changé
  l'image qui a ouvert le dialogue, par exemple le « vu » d'une rencontre, y est) ; aucun fichier
  d'un autre système touché (pas de signal de départ ajouté aux directeurs) ;
- **`note_written`** dans `_persist_snapshot` (toute écriture réussie : autosave, écriture
  immédiate, Menu, arrière-plan) et après l'écriture du point de reprise ;
- **`FOCUS_OUT` / `FOCUS_IN`** : `SessionLifecycle.focus_change` (`RESUMED` vaut `FOCUS_IN`) ; le
  délai de garde est relu à chaque image ;
- **écart [D] à la partie pure** : l'écart de 2 s ne porte que sur les écritures **d'arrière-plan**
  (`note_written(…, background)`) ; une autosave ordinaire juste avant n'empêche pas l'écriture à
  la mise en arrière-plan (sinon les 2 s de jeu qui suivent une autosave seraient perdues, et
  `PAUSED` juste après l'arrivée sur une carte n'écrirait rien) ;
- **échec** de l'écriture du point de reprise : nouvelle tentative après 5 s
  (`SaveCoordinator.RETRY_DELAY`) tant que la partie est instable ; redevenue stable, les
  autosaves ordinaires prennent le relais ;
- **mesure** : journal debug « [save] point de reprise : N µs (max M µs) » à chaque capture ;
- horloge injectable `Boot.background_clock` (tests) ; départ `s2_save` (Route 3, autosave actif) ;
- tests : `tests/integration/test_save_background.gd` (dialogue, scène + relance, écriture
  immédiate, combat sauvage, `FOCUS_OUT` court / long, 2 s, échec puis nouvelle tentative, départ
  `s2_save`) ; `test_save_boot.gd` (scène, défaite) et `test_spin_slide.gd` (arrêt en pleine
  glisse) adaptés : l'arrière-plan écrit désormais le point de reprise d'avant, jamais l'état du
  milieu ;
- mesure sur Mac (headless) : 80 à 320 µs par capture.

#### T5 — Q : **session S2A** → K (interruptions réelles, §6)

**QA agent sur S21 (`RFCR40827ZZ`, 2026-10-21, APK debug de `s2a-sauvegarde`, départ `s2_save`,
vraie sauvegarde de Kevin copiée puis restaurée à l'identique) : 5 scénarios sur 5 OK.**

| # | Interruption | Écrit | Relance |
|---|---|---|---|
| 1 | dialogue de Hugo, bouton marche | point de reprise, Route 3 (19, 26), 4 300 ₽, Hugo non battu | après déverrouillage : dialogue intact ; puis arrêt forcé en plein dialogue → reprise en (19, 26), Hugo à rejouer |
| 2 | combat contre Hugo, Accueil puis arrêt forcé | point de reprise d'avant le combat (PV pleins, Hugo non battu) | reprise en (19, 26), juste avant |
| 3 | rideau de notifications 0,5 s puis 3 s | rien | — (voir ci-dessous) |
| 4 | appel simulé (composeur Samsung en plein écran, `am start -a DIAL`) pendant le dialogue, puis arrêt forcé | point de reprise d'avant Hugo | reprise en (19, 26) |
| 5 | Route 3 → Argenta, arrêt forcé à l'arrivée | autosave d'arrivée, Argenta (51, 26) | reprise à Argenta (51, 26) |

- **Durée de la capture sur S21 : 0,9 à 1,4 ms** (budget 5 ms) ; Mac : 0,08 à 0,3 ms.
- **Constat : Godot 4.7 sous Android n'envoie `FOCUS_OUT` qu'avec la mise en pause.** Le rideau prend
  bien le focus de la fenêtre (`mCurrentFocus=NotificationShade`) mais le jeu ne reçoit rien ; le
  délai de garde de 1 s ne sert donc qu'au Mac et aux plateformes qui l'envoient seul. Sans
  conséquence : un appel qui prend l'écran, l'Accueil ou le bouton marche passent par `PAUSED`, qui
  écrit. Un bandeau d'appel ignoré n'écrit rien (rien n'est perdu tant que le jeu tourne).
- Journal debug ajouté pendant la QA : « [save] focus LOST / REGAINED à N s ».

### 3.3 S2B — État monté, Vélo, Flûte

#### T6 — A : `Mount`, `MountRules`, `MapTraits`, `GameState.player_mount`, `last_land_cell` — après T3

**Fait (2026-10-20, branche `s2b-monture`)** : `GameState.player_mount` (`Mount.Kind`) et
`last_land_cell` ; sauvegardés sous `mount` et `last_land_cell` (clés à plat, comme `cell`), **écrits
seulement s'ils disent quelque chose** [D] (à pied et à terre, le fichier est celui d'avant la passe :
critère 3) ; `set_player_location` tient `last_land_cell` hors du Surf. `GameMap.cycling_road`,
`GameMap.slope_cells` (→ `GridWorld.set_slope`, bit 6 du second octet), `GameMap.mount_traits()`.
Tests : `test_save_v7_mount_fields.gd`.

#### T7 — C : `Player` monté, `MountDirector`, compagnon — après T6

**Fait** : `Player.set_mount` / `get_mount` / `get_move_mode`, signal `mount_changed`, durées par
`MountRules.step_duration` (course ignorée), `step_started` en `&"bike"` / `&"surf"`, animations
`bike_*` / `surf_*` si l'apparence les a (sinon la marche : placeholders, règle 3). Dérive de la pente
dans `Player._process` (§2.3 ; « Dresseur qui voit » = joueur bloqué, la vue le bloque dans le
`moved` du pas). `MountDirector` (`game/world/mount/`) : monture d'arrivée sur
`SceneRouter.map_changed` (écran noir, sans mise en scène [D], au lieu de `map_entered`), Vélo,
`GameState` tenu à jour. **Compagnon** : `CompanionController` écoute lui-même
`Player.mount_changed` (`CompanionRules.VisibilityInput.mounted`) [D] : rentré monté, ressorti à pied.
La mise en scène du Surf (saut) reste à S2C. Tests : `test_player_mount.gd`,
`test_mount_director.gd`.

#### T8 — U : bouton Vélo du HUD, refus — après T7

**Fait** : `%BikeButton` (`game/ui/components/bike_button.tscn`, icône `assets/ui/icons/bike.svg`
provisoire), au-dessus du bouton courir (`UiTokens.BIKE_BUTTON_CENTER_FROM_CORNER` = 440, 390 [D]),
miroir gaucher, même échelle ; visible avec la Bicyclette et les contrôles ; grisé (opacité 0,45
[D]) en intérieur et sur la Piste, toucher actif (le refus joue son texte). Touche B (`bike`). Textes
(dossier 25 §16.1.3, §16.1.4) dans `data/dialogues/mount.json`. Tests : `test_bike_button.gd`.

#### T9 — C : pente, `cycling_road`, `qa_mount` vivante — après T7, T3c

**Écart [D]** : `cycling_road` est un booléen **par carte** (la Route 17 de RB) : la Piste de
`qa_mount` devient une carte à part, `qa_mount_piste` (grilles réécrites, contrôle relancé).

#### T10 — A : `key_use`, aiguillage Sac → Vélo / Flûte (exploration) — après T6

**Fait** : `ItemData.key_use` (`KEY_USES`, clé réservée aux objets clés), contextes (Flûte :
exploration + combats ; Vélo, cannes : exploration) ; `FieldItemRules` : OK et sans cible pour un
objet clé utilisable ; `MenuDirector.key_item_requested` → Boot ferme le menu →
`KeyItemDirector.use` (Vélo → `MountDirector.toggle_bike` ; Flûte → dormeur voisin
(`GameMap.flute_targets`, `InteractPoint.flute_cutscene`) ou « … Quel air entraînant ! » + bulle
« ♪ » du compagnon). `poke_flute` et `bicycle` créés dans `data/items/items_systemes2.json` (textes
validés des dossiers 24 et 25) : **le J21 et le J22 retirent leur doublon à leur fusion**.
Tests : `test_key_use.gd`, `test_mount_director.gd`.

#### T11 — A : Flûte en combat (`Kind.KEY_ITEM`) — après T10

**Fait** : `BattleAction.Kind.KEY_ITEM` (fin d'énum), `Battle.can_use_key_items`,
`flute_has_effect`, `_play_flute` (FLUTE_PLAYED, un FLUTE_WOKE muet par réveillé avec `on_field`,
ALL_WOKE, puis le tour adverse) ; directeur : sans dormeur, « Personne ne dort. » / « La Flûte
n'aurait aucun effet. », aucun tour ; jamais retirée du Sac. Tests : `test_flute_battle.gd`,
`test_battle_items_director.gd`.

#### T11b — Q : **session S2B** → K

### 3.4 S2C — Surf et courants

#### T12 — C : Surf du joueur (montée, nage, descente, saut) — après T11b

#### T13 — U : verbe SURFER, dialogue `surf_water` — après T12

#### T14 — C : bords, warps, Surf forcé, reprise — après T12

#### T15 — A : `ForcedSlideDirector` (dalles du J20 + courants) — après T12

#### T16 — C : rencontres `water`, Nageurs (`move_mode: surf`), `qa_sea` vivante — après T14

#### T16b — A *(si Q-1 = oui)* : pêche (`FishingSpot` → verbe PÊCHER, `water_rod`, scène) — après T13

#### T16c — Q : **session S2C** → K (S2C-bis pour la pêche si elle s'ajoute)

### 3.5 S2D — Force

#### T17 — A : `BoulderField`, `ON_SWITCH` — après T3

**Fait (2026-10-20)** : `game/world/boulders/boulder_field.gd` (pur) : origines, trous et
interrupteurs par drapeaux, cases interdites, `from_positions` (positions d'une grille),
`boulders_at_load` (le rocher désigné d'un trou bouché ne revient pas), `push` (trous ouverts,
interdits, interrupteurs), `flag_to_set` (drapeau à poser + sauvegarde forcée ; rien si déjà
posé). `ON_SWITCH` fait au T3. Tests `test_boulder_field.gd` : les quatre puzzles de `qa_strength`
joués poussée par poussée, rechargement compris.

#### T18 — C : `Boulder`, poussée dans `Player`, activation `field_move` — après T16c, T17

#### T19 — A : `Warp.FALL`, `SceneRouter` — après T18

#### T20 — C : interrupteurs, barrières, `qa_strength*` vivantes — après T18

#### T21 — A : `plan_check_boulders.py` générique (anti-blocage), tests sur les grilles du J24 — après T17

**Fait (2026-10-20), dans `plan_check_systemes2.py` (`verifier_force`) plutôt qu'un fichier de plus
[D]** : toutes les entrées à pied de la carte (`depart`, `spawn`, `chute_joueur`), avec chaque jeu
de drapeaux atteint lors d'une visite précédente (rochers remis à l'origine, désignés tombés
retirés) ; positions seulement, plus de caractères imposés ; `barriere` accepte `unless=`.
Cinquième piège à l'autotest (blocage visible seulement depuis une seconde entrée). **Limite** :
ni Surf, ni niveaux de sol, ni rochers tombés d'en haut : les cinq étages des Îles Écume restent
sous `plan_check_j24_seafoam.py` (essayé : ils ne passent pas ce contrôle, qui n'est pas fait pour
eux). Cible : Route Victoire (J29), Manoir (J25).

#### T22 — Q : **session S2D** → K

### 3.6 S2E — Vol et K.O. en un coup (parallèle de S2B–S2D)

#### T23 — A : `FlyRules`, `fly_points.json`, `MapTraits.no_fly` — après T3

**Fait (2026-10-20)** : `game/world/fly/fly_rules.gd` (pur) : `can_fly` (occupé, conditions de
la CS, intérieur, `no_fly`), chargement de `data/world/fly_points.json` (11 villes dans l'ordre de
RB), `destinations` ; `MapTraits.no_fly` fait au T3. Une destination est ouverte quand **sa carte**
est découverte (pas « une carte de la zone ») [D] : on n'atteint pas un Centre sans passer par la
ville. Points d'arrivée : `from_center` (Lavanville : `retour_centre` ; Bourg Palette :
`player_house_door`), vérifiés sur les six villes construites ; les cinq autres portent l'identifiant
de carte prévu par leur jalon et `from_center` [D], à confirmer par ce jalon (§7). La capacité
**Vol en combat** (données, T25) attend la fusion du J20 : un test compte toutes les capacités et
chaque jalon le modifie (conflit assuré sinon).

#### T24 — U : lancement du Vol (Q-4), liste des villes — après T23

**Fait (2026-10-21)** : bouton « S'ENVOLER » (`AccentButton`) au bas du panneau d'une zone de la
Carte quand `ZonePanelView.fly_available` (Q-4 lève le « aucun bouton de déplacement » du J6) ;
`ZonePanel` → `MapScreen` → `TrainerMenu.map_fly_requested` → `MenuDirector.request_fly`
(revérifié) → `fly_requested` → Boot ferme le menu. `FlyRules.can_fly_to` (conditions, lieu, ville
découverte ; `Check.CLOSED` nouveau) et `FlyRules.traits_of` : **Vol interdit en grotte d'après
`caves.json` [D]** (aucun champ dans `map.gd` : S2B y pose `mount_traits()`, le J23 et le J30
poseront `no_fly`). Départ `s2_fly` (Céladopole, 7 villes, CS02, Roucoups qui connaît Vol) ;
clé `discovered` ajoutée aux départs de débogage.

#### T25 — C : mise en scène de l'envol, arrivée ; Vol en combat (données) — après T24

**Mise en scène faite (2026-10-21)** : `FlyDirector` (bloc `_setup_fly` de Boot) : compagnon
rentré, « {pokemon} s'envole très haut ! » (`fly_takeoff`, variante `field: fly:ready`), joueur
effacé en 0,6 s [D], `SceneRouter.change_map` vers le point de `fly_points.json` tourné vers le bas
[D], « {pokemon} redescend. » (`fly_landing`), compagnon ressorti ; autosave d'arrivée habituel.
Tests `test_fly_integration.gd`, `test_s2ef_boot.gd` (vraie scène Boot).

**Vol en combat fait (2026-10-21)** : `fly` en données seulement (`data/pokemon/moves/moves_s2.json` :
Vol, vol, physique, 90 / 95 / PP 15, effet `charge` avec `invulnerable`, comme Tunnel) ; textes
`charge_fly_start` / `charge_fly_broken` (provisoires, §8.1) ; CS02 `hm02` (`items_systemes2.json`, enseigne
`fly`). Compatibilités déjà générées (`hm_species` : Roucool, Roucoups, Roucarnage, Piafabec,
Rapasdepic). Le moteur ne distingue pas « sous terre » et « en l'air » (`ChargeRules.dodges` : toute
capacité visant la cible est évitée) : Séisme/Abîme contre Tunnel et Fatal-Foudre/Tornade contre Vol
ne sont pas des exceptions ; à trancher plus tard. Mise en scène de l'envol hors combat : reste à faire.

#### T25b — A *(si Q-5 = oui)* : Téléport et Tunnel hors combat — après T25

**Fait (2026-10-21)** : `FieldTravelRules` (pur, `game/world/fly/field_travel_rules.gd` :
`check_teleport`, `check_dig`) et `FieldTravelDirector` (mise en scène du `FlyDirector` : compagnon
rentré, texte, joueur effacé 0,6 s, `change_map`, aucun texte d'arrivée). **Téléport** : au point
du réveil d'après une défaite (`DefeatRecovery.wakeup_point` : dans le Centre, devant le comptoir,
tourné vers le haut [D] ; RB pose le joueur devant le Centre), **sans soin** ; permis en extérieur
et **en grotte**, refusé en intérieur [D] (RB le refuse aussi en grotte, comme le Vol : à
trancher si besoin) et sur une carte `MapTraits.no_teleport` (champ réservé, Parc Safari du J23).
**Tunnel** : destination de la Corde Sortie (`FieldItemRules.escape_target`, case du joueur),
aucun objet consommé ; refusé hors grotte. `field_moves.json` : `teleport` et `dig` avec
`"hm": ""` = **sans CS ni badge, le Pokémon doit connaître la capacité** (`FieldMoves.needs_hm`) ;
Coupe, Flash, Surf, Force et Vol inchangés. Le Pokémon nommé ({pokemon}) suit la règle de
`FieldMoves` (compagnon s'il la connaît, sinon le premier de l'équipe) [D]. **Lancement [D]** :
toucher Téléport / Tunnel dans l'onglet Capacités de l'Équipe ouvre sa fiche détaillée habituelle,
avec **UTILISER** dessous (aucune quatrième action sous la fiche du Pokémon ; ce deuxième toucher
explicite tient lieu de confirmation OUI / NON) ; `MenuDirector.request_field_travel` revérifie ;
refus → « Impossible de l'utiliser ici. » (texte validé de la Corde Sortie) dans le bandeau de
l'en-tête de l'Équipe. Textes nouveaux : `data/dialogues/field_travel.json` (§8.1). Départ
`s2_field_travel`. Tests : `test_field_travel_rules.gd`, `test_field_travel_integration.gd`
(directeur, vues, menu, écran, Boot).

#### T29 — A : effet `ohko`, IA, messages, données, audit des capacités — après T1

**Fait (2026-10-20)** : `MoveEffect.Kind.OHKO` (`{ "kind": "ohko" }`), `OhkoRules` (pur : niveau,
précision = précision de la capacité + écart de niveaux, au plus 100) ; `Battle._ohko_lands`
(type sans effet → NO_EFFECT, niveau inférieur → FAILED [D], tirage raté → MOVE_MISSED, sans tirage
dans les deux premiers cas), `_ohko` (dégâts = PV restants, puis événement `OHKO`) ; une cible sous
terre l'évite (`ChargeRules.targets_foe`) ; message « ohko » (« C'est un K.O. en un coup ! », à
valider en lot) ; IA : note nulle si niveau inférieur ou type sans effet, sinon précision réelle.
Données : `horn_drill` porte l'effet (marqueur et « Sans effet… » retirés). `fissure` **pas
ajoutée** [D] : le J28 la crée (un doublon d'identifiant casserait le chargement à sa fusion) ;
**`guillotine` (J23, J24) : remplacer `pending_effects: ["ohko"]` par
`effects: [{ "kind": "ohko" }]` à leur fusion de `main`.** Tests `test_ohko.gd` ; audit des
capacités régénéré (11 en attente).

#### T29b — Q : **session S2E** → K

### 3.7 S2F — Téléporteurs et portes à carte (parallèle de S2B–S2D)

#### T26 — A : `Warp.style`, `SceneRouter.relocate` — après T1

**Fait (2026-10-21)** : `Warp.Style { DOOR, TELEPORT }` (fin d'énum, défaut DOOR), `Warp.is_teleport`,
`WarpPoint.style` ; `SceneRouter.relocate(spawn, facing)` (même carte, sans rechargement :
`transition_started` puis signal nouveau `relocated`, ni `map_changed` ni `map_entered`, donc ni
titre de zone ni autosave d'arrivée) ; un téléporteur vers une autre carte passe par `change_map`
avec le fondu court `teleport_fade_duration` = 0,25 s [D] ; aucun verrou d'arrivée (règle du
`STEP_ON`). Tests `test_teleporter.gd` (10) ; `test_scene_router.gd` inchangé et vert.

#### T27 — A : `plan_check_teleports.py` (graphe, paires) — après T3b

**Fait (2026-10-21)** : `tools/art/plan_check_teleports.py` (générique, une ou plusieurs grilles ;
sans argument : les deux `qa_teleport*`). Il réutilise `verifier_teleporteurs` de
`plan_check_systemes2.py` (importé, inchangé : spawns, « T », états, but, carte, retour) et ajoute :
paires (`paire=`, facultatif ; exactement deux téléporteurs réciproques, « sur ou à côté »),
téléporteur sur sa propre case refusé, **graphe des salles** imprimé (salle → salles atteignables,
par téléporteur ou par porte, sans ou avec la carte) et salle isolée refusée. `--autotest` : six
pièges refusés (spawn inexistant, paire orpheline, non réciproque, salle sans retour, but sans carte,
« T » sans téléporteur) et une grille correcte acceptée.

#### T28 — C : `KeyDoor`, `qa_teleport` vivante, Carte Magnétique (`card_key`, données) — après T26

**Fait (2026-10-21)** : `KeyDoor` (sous-classe de `FlagGate` : `door_id`, `key_item`, drapeau
`door_<carte>_<id>_open`, `decide`) ; verbe **OUVRIR** (`Interaction.Kind.OPEN`, fin d'énum,
icône de clé provisoire) : le contrôleur d'interactions émet `door_requested(cell)` au lieu de jouer
un dialogue ; `KeyDoorDirector` (bloc `_setup_teleporters` de Boot, qui relaie aussi `relocated` au
compagnon) : avec la clé, battant effacé en 0,3 s [D], drapeau levé (cases libérées, OUVRIR retiré),
autosave demandé, carte gardée ; sans, « Il faut une carte. » (`key_door_locked`). Objet `card_key`
(`items_systemes2.json`). Cartes `qa_teleport` et `qa_teleport_2` (`tools/build_qa_teleport.gd`, enveloppes
`tools/art/placeholders_qa_teleport.py`, déclarées dans `interiors.json`, exception dans
`test_map_catalog` à retirer en S2Z) ; sorties vers `celadon_city:from_center_w` [D] (`qa_mount` est
sur la branche S2B) ; départ `s2_teleport`. Tests `test_key_door.gd`, `test_qa_teleport_map.gd`,
`test_s2ef_boot.gd`.

#### T28b — Q : **session S2F** → K

### 3.8 S2G — si Q-6 / Q-7 = oui

#### T30 — A : `StaticEncounter` (politique d'Artikodin du J24 §2.7 : capture ou K.O. → consommé ; fuite ou défaite → rien ; sauvegarde forcée avant le premier texte)

**Partie pure faite (2026-10-20)** : `game/world/static_encounter/static_encounter.gd` (présence,
drapeaux par issue : capture → `done` + `caught`, K.O. → `done`, le reste → rien ; sauvegarde
forcée si l'issue pose des drapeaux) ; `test_static_encounter.gd`. **Reste après le J20** (il
ajoute `GIFT_POKEMON` à `CutsceneStep`) : drapeaux de capture sur l'étape `wild_battle` (aujourd'hui
`win_flags` / `lose_flags` seulement), acteur de carte caché, intro `legendary`, sauvegarde forcée.

**Branchement fait (2026-10-21)** : l'étape `wild_battle` accepte quatre clés de plus (rien ne
change pour les étapes existantes) :
```json
{ "wild_battle": "articuno", "level": 50, "intro": "legendary", "actor": "articuno",
  "static": { "done": "articuno_done", "caught": "articuno_caught" },
  "catch": ["…"], "win": ["…"] }
```
- `static` crée la `StaticEncounter` de l'étape (espèce et niveau de l'étape, identifiant =
  `actor`, sinon l'espèce) ; `CutsceneStep.outcome_flags` donne ses drapeaux (capture → `done` +
  `caught`, K.O. → `done`, fuite / fuite du sauvage / défaite → rien) **puis** ceux écrits
  (`win`, `lose`, et `catch` nouveau : drapeaux d'une capture, aussi sans `static`) ;
- issue qui consomme la rencontre → **sauvegarde forcée** par le `save_handler` du directeur
  (même chemin que l'étape `save` : `Boot._on_cutscene_save_requested`, raison « rencontre fixe :
  <id> »), à la sortie du combat, **avant** l'étape suivante (premier texte) ; une écriture en
  panne retient la scène (comme `save`) ; puis l'acteur `actor` quitte la carte (`despawn`) ;
- présence : le Pokémon de la carte est un PNJ ordinaire avec `"unless": ["<done>"]` (mécanisme
  existant) ; la scène a sa variante `unless: [<done>]`. Aucun changement dans `boot.gd`, la
  sauvegarde, le joueur ni les interactions ;
- intro `legendary` : `WildEncounter.legendary_intro` → `BattleRequest.legendary_intro` →
  `BattleStage.play_wild_intro(…, slowdown)`. Valeurs par défaut [D] : **recadrage et apparition du
  sauvage 1,5 × plus lents** (`BattleStage.LEGENDARY_INTRO_SLOWDOWN`) ; le bandeau de texte garde
  sa vitesse (aucune autre intro n'existait : seules TRAINER et WILD) ; ni cri ni effet ajouté
  (la scène les joue par ses étapes, J24 T-20) ;
- autres [D] : `static` exige `done` et `caught` distincts ; `actor` exige `static` et refuse
  `player` ; la défaite garde le réveil existant (fin de la scène, rien posé, pas de sauvegarde
  forcée) ; la sauvegarde forcée vient en plus de l'autosave « capture » déjà demandé par Boot.
- QA S2G : départs `tools/debug_start/s2_legendary.json` (Reptincel N36, Roucool N10, 20 Super
  Balls, 10 Poké Balls : K.O., capture, fuite) et `s2_legendary_weak.json` (Salamèche N5 seul :
  défaite), Route 1 devant un **Mélofée N25 de QA** (`qa_s2_legendary`, case (23, 41), une case
  au nord de `from_pallet_w`, présent seulement avec le drapeau `qa_s2_legendary` posé par le
  départ) ; scène et textes de QA `data/cutscenes/qa_s2_legendary.json`,
  `data/dialogues/qa_s2_legendary.json` ; à retirer à la clôture (S2Z, T33) avec l'entrée de
  `data/npcs/route_1.json` (et l'exception `qa_*` de `test_dialogue_data`).
  Tests : `test_cutscene_static_encounter.gd` (intégration), `test_cutscene_static_step.gd`,
  `test_s2_legendary_start.gd`.

#### T31 — A : lot d'effets de combat retenu par Kevin (un effet = une règle pure + des tests + ses textes)

**Fait (2026-10-20), règles modernes [D]** (le moteur suit déjà la table des types et les critiques
modernes) :
- **Soin** (`recover`) : `heal` (½ des PV max, au moins 1) ; échoue à PV pleins ;
- **Protection / Mur Lumière** : `screen` sur le camp du lanceur, **5 tours** (tour du lancer
  compris), dégâts physiques / spéciaux reçus ÷ 2 **sauf coup critique** ; reste quand le Pokémon
  change ; déjà levé → échec (RB : Défense doublée jusqu'au changement, écarté) ;
- **Buée Noire** : tous les niveaux des deux Pokémon à 0 (RB : soignait aussi les statuts,
  écarté) ;
- **Lance-Soleil / Coud'Krâne** : effet `charge` existant (non invulnérable) ; Coud'Krâne
  `stat_up: def` (+1 Défense au tour de charge, comme le dit sa description validée) ;
- **Vague Psy** : `fixed_damage` mode `psywave` (niveau × 50 à 150 %, au moins 1) ; la capacité
  n'est pas en données (CT46, J27 la crée **avec** cet effet) ;
- IA : Soin s'il manque des PV, Buée Noire s'il y a une baisse chez soi ou une hausse en face ;
  mur toujours jugé utile, borné par `STATUS_MAX_USES` [D].
Données : marqueurs et mentions « Sans effet » retirés (textes validés inchangés sinon) ; tests
`test_battle_lot_s2g.gd` ; anciens tests « en attente » mis à jour. Reste en attente : Mania /
Danse Fleur, Frénésie, Mimique, Métronome (J24).

#### T31b — Q : **session S2G** → K (départs de combat)

### 3.9 S2Z — Clôture

#### T32 — Q : non-régression sur la vraie partie de Kevin (S21 ou S24 selon l'attribution des téléphones) ; sauvegarde v7 d'avant la passe rechargée sans perte

#### T33 — A : suite complète, retrait des cartes et départs de QA, passation aux J21–J31 (§7), fusion dans `main` après accord de K

---

## 4. Critères d'acceptation

1. `tools/test.sh` passe ; import sans erreur ; captures relues ; CI verte sur la branche.
2. **Rien ne change pour un joueur à pied** : tous les tests existants de `GridWorld`, `Player`,
   `SceneRouter` passent sans modification.
3. Une sauvegarde v7 d'avant la passe (la vraie partie de Kevin) se recharge à l'identique.
4. Vélo : monter, descendre, refus en intérieur et sur la Piste, dérive sur la pente arrêtée par un
   palier et par un Dresseur qui voit le joueur ; compagnon rentré puis ressorti.
5. Surf : montée, nage, descente, bord de carte, warp, reprise en mer, garde-fou (Pokémon de Surf
   déposé au Stockage) ; Nageur ; rencontre `water` ; courant joué jusqu'au warp sans entrée ni
   sauvegarde.
6. Force : poussée, refus (mur, eau, niveau, occupant, `no_push`), chute dans un trou, chute du
   joueur (`FALL`), interrupteur qui ouvre la barrière pour toujours ; `plan_check_boulders.py` prouve
   l'anti-blocage des cartes de QA et des grilles du J24.
7. Vol : seules les villes découvertes sont proposées ; refus en intérieur et sur `no_fly` ;
   arrivée devant le Centre.
8. Téléporteurs : destination exacte, aucune boucle, même carte sans rechargement ; portes à carte
   ouvertes pour toujours avec la Carte, refus sans.
9. `ohko` : les trois capacités ; échec sur cible de niveau supérieur ; immunités ; IA.
10. Interruption Android : appel, verrouillage, accueil + arrêt forcé, rideau ; à chaque fois la
    reprise est cohérente, sans duplication ni perte au-delà du dernier point stable.
11. Chaque session téléphone du §1.1 est validée par Kevin.

## 5. Tests (nouveaux fichiers, en plus des tests repris)

`test_mount_rules.gd`, `test_player_mount.gd` (intégration : Vélo, Surf, compagnon, combat),
`test_cycling_slope_integration.gd`, `test_key_use.gd`, `test_flute_battle.gd`,
`test_surf_integration.gd` (montée, bords, reprise, garde-fou), `test_forced_slide.gd`,
`test_water_encounters.gd`, `test_swimmer_trainer.gd`, `test_boulder_field.gd`,
`test_boulder_push_integration.gd`, `test_warp_fall.gd`, `test_switch_barrier.gd`,
`test_fly_rules.gd`, `test_fly_integration.gd`, `test_teleporter.gd`, `test_key_door.gd`,
`test_ohko.gd`, `test_save_checkpoint.gd`, `test_background_save.gd` (Boot + `MemoryFs`),
`test_save_v7_mount_fields.gd`, `test_scope_contract.gd` ; contrôles Python
`plan_check_boulders.py`, `plan_check_teleports.py` avec leurs propres cas de test.

## 6. QA téléphone

Téléphone selon l'attribution du moment (mémoires S21 / A17) ; QA bornée à 30–45 min par session,
par départs de débogage, sans vraie partie complète (sauf S2Z).

| Session | Scénario |
|---|---|
| S2A | partie `s2_save` : (1) pendant un dialogue, `adb shell input keyevent KEYCODE_POWER`, rallumer ; (2) pendant un combat, accueil puis `adb shell am force-stop`, relancer ; (3) rideau de notifications 0,5 s puis 3 s ; (4) appel simulé (`adb emu` indisponible : appel réel ou `am start` d'une activité plein écran) ; (5) changement de carte puis arrêt forcé. Comparer position, équipe, Sac, drapeaux. Mesurer la durée d'écriture dans le journal. |
| S2B | `s2_bike` : monter / descendre (bouton et Sac), refus, pente, Dresseur sur la pente, Flûte en exploration (dormeur) et en combat |
| S2C | `s2_surf` : montée, nage, rencontres, Nageur, bord de carte, courant, sauvegarde en mer + relance |
| S2D | `s2_strength` : poussées, refus, trou, chute du joueur, interrupteur et barrière, relance (rochers remis, barrière ouverte) |
| S2E | `s2_fly` : envol, refus, arrivée ; `s2_ohko` : réussite, échec, immunité |
| S2F | `s2_teleport` : graphe parcouru, retour, portes |
| S2Z | vraie partie de Kevin : chargement, 10 min de jeu, rien de changé à pied |

## 7. Ce que consomment les jalons de contenu

Après la fusion de la passe, chaque jalon ne pose que des données et des cartes.

| Jalon | Consomme | Il fournit (données, cartes) |
|---|---|---|
| **J21** Tour 6F–7F, Fuji, Ronflex | `key_use` + Flûte (exploration, combat) ; Scope (J19) ; [`StaticEncounter` si Q-6] | scènes de Ronflex et de Fuji, `poke_flute` remise, Route 12 nord |
| **J22** deux chemins vers Parmanie | Vélo, Piste, pente, refus ; [pêche si Q-1] | Bon de Commande, Bicyclette, garde de la Piste (variante `if_items`), Routes 16–18 marquées `cycling_road` et `/`, [maison de Vol, CS02 : Q-9] |
| **J23** Safari, Koga, CS03, CS04 | entrées `surf` / `strength` de `field_moves.json` (déjà posées) ; `no_fly` sur le Parc ; Surf dans le Parc | le reste (Safari, v8) lui appartient |
| **J24** Îles Écume, Routes 19–21 | Surf, `water`, Nageurs, courants, Force, trous, `FALL`, `plan_check_boulders.py` ; [`StaticEncounter`] ; `ohko` (Guillotine) | `SeafoamState` branché sur `BoulderField`, grilles, Artikodin, `FossilLab`, Métronome (sauf Q-7) |
| **J25** Manoir, Auguste | `FALL` (3F), Surf (accès), Vol (Cramois'Île) ; [`KeyDoor` facultatif] | `MansionSwitch`, quiz, échanges : déjà les siens |
| **J26** Sylphe SARL | téléporteurs, portes à carte, `plan_check_teleports.py` ; ascenseur et don (J20) ; porte de Safrania (J20) | 11 étages, graphe, `card_key` au 5F |
| **J27** Morgane, Dojo | téléporteurs (nouveau graphe) ; [Vague Psy, Soin, Protection si Q-7] | Arène, Dojo, choix Kicklee / Tygnon (don J20) |
| **J28** Arène de Jadielle | dalles (J20, lecteur généralisé) ; `ohko` (Abîme, CT27) | grille et graphe des dalles, Giovanni |
| **J29** Route Victoire | Force, interrupteurs, barrières, anti-blocage, Surf (Route 23) ; [`StaticEncounter` : Sulfura] | trois étages, huit gardes (variantes `if_flags`), Sulfura |
| **J30** Ligue | sauvegarde en arrière-plan ; [effets de combat si Q-7] ; Vol vers le Plateau Indigo ; `no_fly` dans la Ligue | tentative de Ligue, Panthéon, générique (siens) |
| **J31** Grotte Inconnue | Surf ; [`StaticEncounter` : Mewtwo ; Soin si Q-7] | trois étages, Mewtwo |

## 8. Questions pour Kevin

Vraies décisions de game design (ou d'ordre de travail, Q-0). **Décision de Kevin (2026-10-19) :
la recommandation de chaque ligne est retenue.** Les passages « si Q-n = oui » du plan sont donc
tous actifs (pêche, Téléport et Tunnel, S2G).

| # | Question | Options | Recommandation |
|---|---|---|---|
| **Q-0** | Quand le code de la passe commence-t-il ? Le J20 n'a fait que 20.0a (§0.1). | **A** après le J20 complet · **B** dès le J19 clos, en parallèle du J20 | **A** : un seul jalon dans `Player` / `Boot` à la fois ; d'ici là, grilles de QA seulement. |
| **Q-1** | La **pêche** (3 cannes, `water_rod`) entre-t-elle dans la passe ? Demande du J22. | oui · non (reste au J22) | **Oui** : système de déplacement / exploration utilisé par toutes les eaux ; logique pure déjà écrite. |
| **Q-2** | Règle du **K.O. en un coup** | **A** moderne (niveau du lanceur ≥ cible, précision 30 + écart de niveau) · **B** Rouge/Bleu (échoue si plus lent que la cible, précision 30 % avec niveaux de précision) | **A** : le moteur suit déjà la table des types et les critiques modernes. |
| **Q-3** | **Badge** exigé pour le Vol hors combat | Badge Foudre (RB) · aucun · autre | **Badge Foudre** (RB), comme Surf (Âme) et Force (Prisme). |
| **Q-4** | D'où **lance-t-on** le Vol (et SURFER hors du bouton contextuel) ? | **A** écran Carte du Menu Dresseur (« S'envoler » sur une ville ouverte) · **B** fiche du Pokémon dans Équipe (comme RB) · A + B | **A** seul pour le Vol (la carte existe, le joueur voit où il va) ; SURFER seulement par le bouton contextuel. |
| **Q-5** | Ajouter **Téléport** (retour au dernier Centre) et **Tunnel** (sortie de grotte) **hors combat** ? | oui · non | **Oui**, petit, réutilise l'arrivée du Vol et la Corde Sortie ; sinon Abra perd son usage RB. |
| **Q-6** | Une **rencontre légendaire fixe** générique dans la passe (Artikodin, Sulfura, Mewtwo, Ronflex) ? | oui (S2G) · non (chaque jalon la sienne, le J24 d'abord) | **Oui** : une implémentation, quatre données. |
| **Q-7** | Un **lot d'effets de combat** dans la passe ? Effets en attente utilisés par les Champions, le Conseil et Mewtwo : Soin, Protection, Mur Lumière, Buée Noire, Brume, Mania / Danse Fleur, Lance-Soleil / Coud'Krâne (deux tours), Ultralaser (recharge), Frénésie, Mimique, Métronome (J24), Vague Psy (CT46, J27). | tout · seulement ceux des combats majeurs (Soin, Protection, Mur Lumière, Ultralaser, deux tours, Vague Psy, Buée Noire) · aucun | **Ceux des combats majeurs** ; Métronome reste au J24 (déjà prévu). |
| **Q-8** | Partie tuée **pendant** un combat ou une scène | **A** reprise juste avant ce combat ou cette scène (RB) · **B** reprise au milieu du combat (état du combat sauvegardé, v8, lourd) | **A**. |
| **Q-9** | Qui pose la **maison de Vol** de la Route 16 et la remise de la CS02 (réservée « au J23 », puis N-24 A : « un jalon des CS ») ? | la passe (une carte réelle) · le J22 (propriétaire de la Route 16 ouest), en données après la passe | **Le J22**, en données : la passe ne touche aucune carte réelle. |

**Valeurs par défaut [D] de la passe** (règle 4, à relire en lot) : durée d'un pas à Vélo 0,12 s ;
Surf ×1,15 la marche ; poussée tenue 0,25 s ; glissade d'un rocher 0,3 s ; saut de montée en Surf
0,5 s ; pente = bit 6 de `_sea` ; interrupteur permanent, rocher remis à l'origine ; une Carte
Magnétique ouvre toutes les portes, pour toujours ; texte « Il faut une carte. » ; verbe OUVRIR ;
téléporteur sans verrou d'arrivée, orientation conservée, fondu 0,25 s ; Vol : arrivée devant le
Centre (Bourg Palette : devant la maison), villes ouvertes = cartes découvertes, refus en grotte ;
IA qui évite un `ohko` voué à l'échec ; `FOCUS_OUT` écrit après 1 s ; pas deux écritures en moins de
2 s ; budget d'instantané < 5 ms ; Vélo permis en grotte (dossier 25) ; bouton Vélo au-dessus du
bouton Course ; touche B.

### 8.1 Lot de textes à valider (passe systèmes 2, 2026-10-20)

Textes provisoires déjà en jeu (`data/battle/messages.json`), à valider ou corriger d'un bloc :

| Modèle | Texte |
|---|---|
| `ohko` | C'est un K.O. en un coup ! |
| `heal` | {pokemon} récupère des PV ! |
| `screen_started_player` / `_foe` | {move} protège votre équipe ! / {move} protège l'équipe adverse ! |
| `screen_ended_player` / `_foe` | L'effet de {move} prend fin pour votre équipe. / … pour l'équipe adverse. |
| `haze` | Toutes les statistiques reviennent à la normale ! |
| `charge_solar_beam_start` / `_broken` | {pokemon} absorbe la lumière ! / {pokemon} perd la lumière absorbée. |
| `charge_skull_bash_start` / `_broken` | {pokemon} baisse la tête ! / {pokemon} relève la tête. |
| `charge_fly_start` / `_broken` (Vol, T25) | {pokemon} s'envole très haut ! / {pokemon} redescend. |
| `teleport_used` (T25b, `data/dialogues/field_travel.json`) | {pokemon} utilise Téléport ! |
| `dig_used` (T25b) | {pokemon} creuse un tunnel ! |
| `fly_takeoff` / `fly_landing` (Vol hors combat, T25, `data/dialogues/fly.json`) | {pokemon} s'envole très haut ! / {pokemon} redescend. |
| `key_door_locked` (T28, `data/dialogues/key_doors.json`) | Il faut une carte. |
| `card_key` (objet, T28) | Carte Magnétique — « Une carte électronique qui ouvre les portes verrouillées. » |
| `qa_teleport_*` (cartes de QA, retirés en S2Z) | — |

À venir avec leur code (après le J20) : refus du Vélo et du Surf (textes du dossier 25 et 27,
déjà validés), « Il faut une carte. » (porte à carte), Vol (« {pokemon} s'envole très haut ! »,
« {pokemon} redescend. »).

## 9. Estimation (ordre de grandeur, non mesuré)

| Sous-jalon | Tâches | Taille | Durée au rythme actuel |
|---|---|---|---|
| S2.0 | T1–T3c | moyenne (reprise + cartes de QA) | ½ jour |
| S2A | T4–T5 | petite, mais validée seule | ½ jour |
| S2B | T6–T11b | grande (fondation de l'état monté) | 1 jour |
| S2C | T12–T16c | grande | 1 jour (+ ½ avec la pêche) |
| S2D | T17–T22 | moyenne (logique déjà écrite) | ½ à 1 jour |
| S2E | T23–T29b | moyenne | ½ jour (parallèle) |
| S2F | T26–T28b | petite à moyenne | ½ jour (parallèle) |
| S2G | T30–T31b | selon Q-6 / Q-7 | ½ à 1 jour (parallèle) |
| S2Z | T32–T33 | petite | ½ jour |

Total : **≈ 30 tâches, 7 à 8 sessions téléphone, ≈ 4 à 5 jours** de calendrier avec la série S2B →
S2D et deux branches parallèles (S2E, S2F / S2G) ; ≈ 400 à 600 tests nouveaux. Pour comparaison, le
J11 (grande passe de systèmes) a pris 3 jours (2026-10-10 → 10-13). Le chemin critique est la série
S2B → S2C → S2D (tout passe par `Player`).
