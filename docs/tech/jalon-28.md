# Jalon 28 — Le dernier Badge de Kanto (Arène de Jadielle, dalles, Giovanni Champion, Badge Terre, CT27)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j28-v1-chatgpt.md` (7 arbitrages verrouillés par Kevin le 2026-10-19 ; ne pas
> les rouvrir). Plan écrit le 2026-10-21 (branche `plans-j26-j30`), en conception seulement.

> Objectif jouable sur le téléphone : **l'Arène de Jadielle s'ouvre enfin.** Après la libération de
> la Sylphe SARL, la porte longtemps verrouillée cède. Le joueur glisse sur des **dalles
> directionnelles**, évite ou combat des Dresseurs (Sol, Poison, Combat) et retrouve **Giovanni**,
> cette fois Champion : Rhinocorne, Triopikeur, Nidoqueen, Nidoking, Rhinoféros. Il gagne le **Badge
> Terre** et la **CT27 Abîme**. Giovanni quitte son rôle. Rien n'est imposé ensuite : la Route
> Victoire est au J29.
>
> **Mécanique nouvelle : aucune.** Dalles du J20 (lecteur généralisé par la passe systèmes 2),
> effet `ohko` (S2E), scène de Champion (modèle d'Erika).
>
> **Format de sauvegarde inchangé : v7.**

## 0. État et dépendances

### 0.1 Contrat d'entrée, relu sur le code (2026-10-21)

| Besoin | Où, état réel | Ce que fait le J28 |
|---|---|---|
| Jadielle, porte de l'Arène | `main` (J7) : `viridian_city`, dialogue `viridian_gym_door` (« La porte est verrouillée. »), guetteur `gym_watcher` (`viridian_gym_watcher`) ; service `gym` dans `zones.json` | Porte → warp vers `viridian_gym` **si** les 7 Badges autres que la Terre sont levés (Q28-1, 2026-10-22) ; sinon texte actuel. Guetteur à trois variantes |
| Condition d'ouverture | **Décision de Kevin Q28-1 (2026-10-22)** : comme Rouge/Bleu (`ViridianCityCheckGymOpenScript` : `wObtainedBadges` = tous les Badges sauf la Terre), la porte s'ouvre avec les **7 Badges** `badge_boulder`, `badge_cascade`, `badge_thunder`, `badge_rainbow`, `badge_soul`, `badge_marsh`, `badge_volcano`, **indépendamment de la Sylphe** (`silph_giovanni_defeated` n'est plus lu). Remplace l'arbitrage 2. Pas de `viridian_gym_unlocked` [D] |
| Dalles directionnelles | `main` (J20) : `game/world/spin/` (`SpinTileRules` : flèches `< > ^ v`, arrêt `o`, erreurs BLOCKED / LOOP / TOO_LONG ; `SpinTileField`, `SpinTileDirector`) ; `systemes-2` (S2C, T15, validé) : `ForcedSlideDirector`, un seul lecteur pour les dalles et les courants | Pose un nœud `SpinTiles` depuis la grille (passation du J20 §10.3) ; aucun code |
| K.O. en un coup | `systemes-2` (S2E, T29, validé) : `MoveEffect.Kind.OHKO`, règle moderne (Q-2 A) ; **`fissure` volontairement non créée** par la passe | Crée `fissure` (Abîme) avec `effects: [{ "kind": "ohko" }]` |
| CT27 | `main` : `tm_compatibility.json` lie la CT27 à `fissure` (pas Séisme) | Crée l'objet `tm27` si absent ; ne pas reprendre la CT26 Séisme (passe §7) |
| Badge Terre | `main` : `badges.json` (`earth`, `badge_earth`) | Rien à créer |
| Espèces | `main` : Rhinocorne, Triopikeur, Nidoqueen, Nidoking | **À créer** : Rhinoféros (`rhydon`), et les espèces des Dresseurs absentes (audit T3) |
| Sauvegarde pendant une glissade | `main` (J20) : `can_save()` faux pendant la glissade ; reprise sur une case stable (`safe_cell`) | Rien ; tests sur la vraie carte |

### 0.2 Contrat de sortie

| Donnée | Lue par |
|---|---|
| `badge_earth` | J29 : garde n° 8 de la Route 23 **et** déclenchement du rival final sur la Route 22 (RB) |
| Giovanni absent de l'Arène après la victoire | J29, J30, post-game |
| Espèce `rhydon` | J30 (rival Champion) |
| Capacité `fissure`, CT27 | Tout le jeu |

### 0.3 Ce qui peut commencer maintenant, ce qui attend

**Maintenant** : T1 à T5 (décodage RB de l'Arène et de ses dalles, grille, graphe des glissades,
données, textes, vue générale).

**Après la fusion de la passe systèmes 2 dans `main`** : T6 et suivantes. Le J28 **n'a pas besoin
que le J26 soit fusionné** : il ne lit qu'un drapeau dont le nom est fixé ici (les tests le posent).
Il peut donc être codé en parallèle du J26 ou du J27 (zone de carte disjointe : Jadielle). Il est
**fusionné après le J26**, pour que la porte ne puisse jamais s'ouvrir sur une partie où la Sylphe
n'existe pas encore (une partie réelle ne peut pas poser le drapeau avant).

### 0.4 Écarts relevés

- **Condition historique** (point Q28-1) : dans Rouge/Bleu, la porte de l'Arène de Jadielle s'ouvre
  quand le joueur a les **sept autres Badges** (pokered, script de Jadielle ; à confirmer à l'audit
  T1). La passe dit « conditions historiques » **et** « après la Sylphe, sans Badge Marais ni
  Volcan ». Le plan suit la seconde phrase, explicite et verrouillée.
- **Obstacle des dalles** : la passe veut un arrêt « avant la case bloquée ». Le moteur du J20 traite
  une glissade qui bute comme une **erreur de données** (BLOCKED). Défaut [D] : la grille pose une
  case d'arrêt `o` devant chaque obstacle atteint, et le contrôle prouve qu'aucune glissade ne finit
  en BLOCKED. Aucun code. Si le décodage RB montre une glissade qui bute contre un mur, on le signale
  (Q28-2).
- La passe propose `viridian_gym_unlocked` et `giovanni_disbanded_rocket` : remplacés par
  les 7 Badges (lus, Q28-1) et `badge_earth` (Giovanni absent si posé) [D]. Même sens.

## 1. Découpage

| Sous-jalon | Lots de la passe | Tâches | Validation |
|---|---|---|---|
| **28.0** | 28.0 | T0 à T5 | Kevin sur planches : grille, graphe des glissades, vue générale, textes |
| **28-I** | 28A à 28F | T6 à T12 | **une session téléphone**, puis clôture |

Fichiers chauds : `data/dialogues/viridian_city.json` et `data/npcs/viridian_city.json` (deux
variantes) ; la carte `viridian_city` (porte devenue warp : relancer son outil de construction ou
poser le warp en données, selon ce que l'outil du J7 permet, vu au T1).

## 2. Conception technique

### 2.1 Arène (`tools/plans/jadielle_arene.txt`, carte `viridian_gym`)

- **Plan RB à 1:1** (puzzle) : couloirs, dalles, cases d'arrêt, obstacles, Dresseurs, objets
  (pokered `ViridianGym`). Décodage `tools/art/viridian_gym_rb_decode.py`.
- **Légende** : celle du repaire du J20 (`< > ^ v` dalles, `o` arrêt) ; pas de courant dans la même
  grille (règle de `plan_check.py --legende`).
- **Graphe des glissades** (contrôle `tools/art/plan_check_j28.py`, sur `SpinTileRules.slide`
  réécrit en Python ou appelé par un script headless) : depuis chaque dalle, trajet OK (jamais
  BLOCKED, LOOP, TOO_LONG) ; Giovanni atteignable depuis l'entrée ; **l'entrée atteignable depuis
  chaque case d'arrêt** (on peut toujours ressortir) ; aucune glissade ne finit sur une case de
  warp ni ne déclenche une interaction (passe §4) ; graphe imprimé pour la revue.
- Les Dresseurs voient le joueur à l'arrêt seulement (règle du J20 : « Dresseur de la case d'arrêt »).

### 2.2 Dresseurs et Giovanni

- Dresseurs : équipes RB (Sol, Poison, Combat), places, vision, audit T3 ; certains évitables par le
  bon chemin (arbitrage 4), sans ajout.
- **Giovanni Champion** (`viridian_gym_giovanni`, distinct de `silph_co_giovanni` et du combat du
  repaire du J20) : Rhinocorne 45, Triopikeur 42, Nidoqueen 44, Nidoking 45, Rhinoféros 50
  (arbitrage verrouillé). Capacités RB (Abîme compris si RB la lui donne : audit), IA `smart`.
- Scène (modèle d'Erika) : `giovanni_gym_met`, carte de Champion (« GIOVANNI — Champion d'Arène de
  Jadielle »), combat → `badge_earth` ; Badge ; CT27 si `tm27_received` absent ; texte de départ,
  fondu, Giovanni retiré (`unless [badge_earth]` sur son PNJ). Défaite → réveil, rejouable.
- Grand moment : type existant du Champion (comme Erika).

### 2.3 Jadielle après le J28

- Guetteur : « Encore fermée… » tant que la Sylphe n'est pas libérée ; puis une réplique d'ouverture ;
  puis, après `badge_earth`, une réplique sur le départ du Champion.
- **Aucune** incitation à aller à la Route 22 (arbitrage 7).

### 2.4 Drapeaux (v7 inchangée)

| Drapeau | Rôle |
|---|---|
| 7 Badges (`badge_boulder` … `badge_volcano`) | lus : porte ouverte (Q28-1) ; `silph_giovanni_defeated` n'est plus lu |
| `giovanni_gym_met` | Introduction dite |
| `badge_earth` | Badge ; Giovanni absent |
| `tm27_received` | CT27 remise |
| `defeated` de chaque Dresseur | mécanisme existant |

### 2.5 Départs de débogage

`viridian_gym` (porte ouverte, entrée, équipe N48) · `viridian_gym_giovanni` (devant Giovanni) ·
`viridian_locked` (Sylphe non libérée : porte fermée).

### 2.6 Art

Avant le code : grille + une vue générale. Lot d'art ensuite : intérieur (modules), dalles et cases
d'arrêt (celles du repaire du J20 en placeholder), Giovanni Champion (même personnage), Triopikeur,
Nidoking, Rhinoféros, fond de combat « Arène de Jadielle ».

## 3. Textes

La passe ne propose aucun texte : tout ce qui suit est **[D]**, **validé par Kevin le 2026-10-21, validation d'avance (proposition du plan)**. Le texte de la
porte fermée reste celui du J7 (« La porte est verrouillée. »).

| N° | Locuteur | Texte |
|---|---|---|
| T28-01 [D] | Habitant (guetteur, porte ouverte) | « La porte de l'Arène est ouverte ! Le Champion serait revenu… » |
| T28-02 [D] | Habitant (après `badge_earth`) | « Le Champion est reparti. Personne ne sait où. » |
| T28-03 [D] | Guide de l'Arène | « Le dernier Champion de Kanto t'attend. Attention : le sol ici a sa propre volonté. » |
| T28-04 [D] | Giovanni (avant) | « Te voilà. C'est ici que tout a commencé pour moi. Ici, je ne suis pas le chef de la Team Rocket. Je suis le Champion de Jadielle. » |
| T28-05 [D] | Giovanni (reprise) | « Encore toi. Montre-moi que la première fois n'était pas un hasard. » |
| T28-06 [D] | Giovanni (victoire du joueur) | « … Ta force est réelle. Ce Badge Terre te revient. » |
| T28-07 [D] | Giovanni (CT) | « Prends aussi la CT27, Abîme. Une fissure dans le sol, et le combat est fini. » |
| T28-08 [D] | Giovanni (départ) | « La Team Rocket, c'est terminé. Je pars m'entraîner seul. Un jour, peut-être, nos chemins se croiseront encore. » |
| T28-09 [D] | Narration | « {player} reçoit le Badge Terre ! » (modèle des Badges existants, à vérifier) |


### 3.1 Textes complémentaires (écrits au codage, 2026-10-22) — **relus et validés par Kevin le 2026-10-22 (T28-10 à T28-36)**

Le plan ne donnait pas de répliques aux huit Dresseurs, ni la défaite du joueur contre Giovanni, ni la
remise de la CT, ni le guide après le départ du Champion. Propositions [D] ci-dessous, en place dans
`data/dialogues/viridian_gym.json` ; **elles ne sont pas couvertes par la validation d'avance**
(qui porte sur T28-01 à T28-09). « / » sépare deux bulles.

| N° | Locuteur (dialogue) | Texte |
|---|---|---|
| T28-10 [D] | Topdresseur Yannick (`viridian_gym_cooltrainer_yannick_before`) | « Le sol de cette Arène ne pardonne aucune erreur. » |
| T28-11 [D] | Topdresseur Yannick (`viridian_gym_cooltrainer_yannick_defeated`) | « J'ai glissé… au mauvais moment. » |
| T28-12 [D] | Topdresseur Yannick (`viridian_gym_cooltrainer_yannick_after`) | « Ici, on apprend à lire les flèches avant de courir. » |
| T28-13 [D] | Karatéka Bertrand (`viridian_gym_blackbelt_bertrand_before`) | « Hiyaa ! Mes poings sont prêts ! » |
| T28-14 [D] | Karatéka Bertrand (`viridian_gym_blackbelt_bertrand_defeated`) | « Ouf… Tu frappes fort. » |
| T28-15 [D] | Karatéka Bertrand (`viridian_gym_blackbelt_bertrand_after`) | « Le Champion nous apprend à tenir debout, même quand le sol bouge. » |
| T28-16 [D] | Dompteur Lionel (`viridian_gym_tamer_lionel_before`) | « Mon Rhinocorne ne s'arrête jamais. Et toi ? » |
| T28-17 [D] | Dompteur Lionel (`viridian_gym_tamer_lionel_defeated`) | « Il s'est arrêté, finalement… » |
| T28-18 [D] | Dompteur Lionel (`viridian_gym_tamer_lionel_after`) | « Un Rhinocorne, ça se dresse avec patience. » |
| T28-19 [D] | Karatéka Didier (`viridian_gym_blackbelt_didier_before`) | « Tu crois pouvoir passer sans te battre ? » |
| T28-20 [D] | Karatéka Didier (`viridian_gym_blackbelt_didier_defeated`) | « Bien joué. Vraiment. » |
| T28-21 [D] | Karatéka Didier (`viridian_gym_blackbelt_didier_after`) | « Je m'entraîne ici depuis des années. » / « Le Champion vient rarement. » |
| T28-22 [D] | Topdresseur Florian (`viridian_gym_cooltrainer_florian_before`) | « Peu de Dresseurs arrivent jusqu'ici. » |
| T28-23 [D] | Topdresseur Florian (`viridian_gym_cooltrainer_florian_defeated`) | « Tu mérites d'aller plus loin. » |
| T28-24 [D] | Topdresseur Florian (`viridian_gym_cooltrainer_florian_after`) | « Le Champion n'est plus très loin. Prépare-toi bien. » |
| T28-25 [D] | Karatéka Joël (`viridian_gym_blackbelt_joel_before`) | « Halte ! Personne ne passe sans m'affronter. » |
| T28-26 [D] | Karatéka Joël (`viridian_gym_blackbelt_joel_defeated`) | « Mes Pokémon ont tout donné… » |
| T28-27 [D] | Karatéka Joël (`viridian_gym_blackbelt_joel_after`) | « Va. Le Champion t'attend. » |
| T28-28 [D] | Dompteur Régis (`viridian_gym_tamer_regis_before`) | « Mes Pokémon ont du caractère. Attention ! » |
| T28-29 [D] | Dompteur Régis (`viridian_gym_tamer_regis_defeated`) | « Ils ne m'ont pas écouté, cette fois. » |
| T28-30 [D] | Dompteur Régis (`viridian_gym_tamer_regis_after`) | « Un Tauros, ça ne se dompte pas en un jour. » |
| T28-31 [D] | Topdresseur Damien (`viridian_gym_cooltrainer_damien_before`) | « Ce couloir est à moi. Recule ou combats ! » |
| T28-32 [D] | Topdresseur Damien (`viridian_gym_cooltrainer_damien_defeated`) | « Tu as de bons réflexes. » |
| T28-33 [D] | Topdresseur Damien (`viridian_gym_cooltrainer_damien_after`) | « Ce passage mène tout droit au Champion. » |
| T28-34 [D] | Guide (`viridian_gym_guide`) | « Le Champion est parti… L'Arène semble bien vide sans lui. » |
| T28-35 [D] | Giovanni (`viridian_gym_giovanni_lost`) | « Tu n'es pas encore à la hauteur. » / « Reviens quand tu le seras. » |
| T28-36 [D] | Giovanni (`viridian_gym_giovanni_tm_got`) | « {player} reçoit la CT27 Abîme ! » |

## 4. Tâches

### 4.1 Sous-jalon 28.0 — **maintenant**

#### T0 — A : plan (ce document) — fait
#### T1 — A : branche `jalon-28` depuis `origin/main` ; audit (porte de Jadielle dans l'outil du J7, condition RB, espèces, `fissure`, `tm27`) sur toutes les branches
#### T2 — C : décodage RB, grille, `plan_check_j28.py` (graphe des glissades) → K
#### T3 — A : données (Rhinoféros, `fissure`, `tm27`, Dresseurs, Giovanni, répliques [D])
#### T4 — A : simulation d'équilibrage de Giovanni (outil du J12)
#### T5 — C (Mac) : vue générale → K

### 4.2 Sous-jalon 28-I — **après la fusion de la passe systèmes 2**

#### T6 — C : carte `viridian_gym` (géométrie, `SpinTiles`), porte de Jadielle conditionnelle
#### T7 — C : Dresseurs, guide, objets — après T6, T3
#### T8 — C : Giovanni, Badge, CT27, départ — après T7
#### T9 — C : variantes de Jadielle (guetteur) — après T6
#### T10 — A : départs de débogage, tests de bout en bout
#### T11 — Q : **session 28** → K
#### T12 — A : clôture, passation J29, fusion **après le J26** et accord de K

## 5. Tests

- `test_viridian_gym_door.gd` : 6 Badges (sans le Volcan) → fermée, même Sylphe libérée ; 7 Badges → ouverte, sans
  `silph_giovanni_defeated` ; ouverte pour toujours.
- `test_viridian_gym.gd` : grille = plan ; chaque dalle → trajet OK ; dalles successives
  déterministes ; aucune glissade ne déclenche un warp ni un dialogue ; entrée toujours atteignable.
- `test_viridian_gym_save.gd` : sauvegarde demandée pendant une glissade → refusée ; arrêt simulé →
  reprise sur une case stable.
- `test_giovanni_gym.gd` : défaite → rejouable ; victoire → Badge et CT27 une fois ; Giovanni absent
  ensuite ; combat distinct de `silph_co_giovanni`.
- `test_fissure.gd` : K.O. en un coup sur cible de niveau inférieur ou égal ; échec sur niveau
  supérieur ; sans effet sur un Pokémon Vol.
- `test_save_j28.gd` : v7 ; aucun départ automatique vers la Route 22.

## 6. Critères d'acceptation

1. `tools/test.sh` passe ; import sans erreur ; captures relues.
2. `plan_check_j28.py` : graphe des glissades conforme, aucune erreur BLOCKED / LOOP / TOO_LONG.
3. La porte ne dépend que de la libération de la Sylphe.
4. Badge Terre et CT27 une seule fois ; Giovanni ne redevient pas Champion.
5. Session téléphone validée par K.

## 7. QA téléphone (une session, 30 à 45 min)

| Scénario | Attendu |
|---|---|
| `viridian_locked` | Porte fermée, texte du J7 |
| `viridian_gym` : parcours des dalles | Glissades fluides, arrêts nets, pas d'interaction involontaire |
| Dresseur évité | Pas de combat forcé |
| Giovanni : défaite puis victoire | Rejouable ; Badge, CT27, départ |
| Retour dans l'Arène | Giovanni absent |
| Appel pendant une glissade, relance | Reprise sur une case stable |
| Abîme utilisé en combat | Message « C'est un K.O. en un coup ! » (validé S2E) |

## 8. Valeurs par défaut [D]

- Porte ouverte par les 7 Badges (Q28-1) ; pas de drapeau d'ouverture propre.
- Case d'arrêt explicite devant chaque obstacle ; aucun changement du moteur des dalles.
- Giovanni retiré par `badge_earth` ; pas de `giovanni_disbanded_rocket`.
- Textes T28-01 à T28-09.

## 9. Points ouverts pour Kevin

- **Q28-1 — Condition d'ouverture.** RB ouvre l'Arène avec les **sept autres Badges** ; la passe dit
  « après la Sylphe, sans Badge Marais ni Volcan ». Le plan suit la passe. Confirmes-tu ?
- **Q28-2 — Obstacle des dalles.** Si le plan RB contient une glissade qui bute contre un mur sans
  case d'arrêt : ajouter une case d'arrêt (défaut, aucun code) ou étendre le moteur (« arrêt avant
  l'obstacle ») ?
- **Q28-3 — Textes** : propositions [D]. Couverts par ta validation d'avance, ou à relire ?
- **Q28-4 — Équipes des Dresseurs** : RB, mais niveaux à ajuster si la simulation montre un écart
  avec la courbe de la passe ? Défaut : RB tel quel.

## 10. Réalisé (2026-10-22, branche `jalon-28` depuis `systemes-2` @ `8c2cb6ee`, worktree `~/dev/kanto-2026-wt-j28`)

Session de nuit, sans Kevin. Textes T28-01 à T28-09 **validés par Kevin le 2026-10-21, validation
d'avance (proposition du plan)** ; textes complémentaires du §3.1 **à relire**.

### 10.1 Fait

- **T1–T2** : `tools/art/viridian_gym_rb_decode.py` (lit un pokered local, `python3 -I`) ;
  `tools/plans/jadielle_arene.txt` (RB 1:1, décalée de (+2, +2) [D] pour deux rangées / colonnes de
  mur) ; `tools/art/plan_check_j28.py` : les 12 dalles RB, la règle du moteur du J20 redonne les 12
  trajets exacts (un « o » sur chaque arrivée RB), aucune BLOCKED / LOOP / TOO_LONG, sortie
  atteignable de partout, Giovanni atteignable ; 6 Dresseurs évitables, 2 inévitables
  (`topdresseur_2` Florian, `karateka_3` Joël).
- **Écart RB** : dans RB, une dalle pousse d'un **nombre fixe de pas** (table
  `ViridianGymArrowTilePlayerMovement`), sans case d'arrêt ; la grille pose donc un `o` à chaque
  arrivée. **Q28-2 sans objet** : aucune glissade RB ne bute contre un mur.
- **T3** : Rhinoféros (`kanto_j28.json`, Rhinocorne → Rhinoféros N42, RB) ; **Machopeur et Tauros
  copiés à l'identique** des J22 / J23 (`kanto_j28_emprunts.json`, fiches de Pokédex et sprites
  provisoires repris de `origin/jalon-23`) : **à supprimer à la fusion** si J22 / J23 sont fusionnés
  avant (sinon doublon) ; fiche de Pokédex de Rhinoféros [D] ; Abîme (`moves_j28.json`, effet
  `ohko`) ; CT27 (`items_j28.json`) ; `tm_compatibility.json` régénéré (fichier généré).
- **Dresseurs** (RB, Q28-4 : niveaux RB tels quels) : Topdresseur Yannick (Sablaireau, Triopikeur
  39), Karatéka Bertrand (Machoc, Machopeur 40), Dompteur Lionel (Rhinocorne 43), Karatéka Didier
  (Machopeur 43), Topdresseur Florian (Rhinocorne 43), Karatéka Joël (Machopeur, Machoc,
  Machopeur 38), Dompteur Régis (Arbok, Tauros 39), Topdresseur Damien (Nidorino, Nidoking 39).
  Prénoms vérifiés libres sur `main` et toutes les branches `origin/jalon-2x`, `j2x-*`. Sprites
  provisoires : `camper` (Topdresseur), `hiker` et `rocker` (sprites RB des Karatékas et Dompteurs).
  Prix RB (base × niveau). IA `smart` pour les Topdresseurs.
- **Giovanni Champion** (`viridian_gym_giovanni`) : équipe verrouillée, Abîme sur Rhinoféros (RB :
  `LoneMoves`), 4 950 ₽, carte « GIOVANNI — Champion d'Arène de Jadielle ». Scène sur le modèle
  d'Erika ; rattrapage `viridian_gym_giovanni_tm_late`. **[D] Giovanni est retiré par
  `tm27_received`** (posé à la fin de la remise) plutôt que par `badge_earth` : une coupure entre le
  Badge et la CT ne fait pas perdre la CT. Le guide et le Rappel (RB) sont posés.
- **T6, T9** : carte `viridian_gym` (`tools/build_viridian_gym.gd`, enveloppe provisoire
  `tools/art/placeholders_j28.py`, nœud `SpinTiles`, aucune ligne du moteur des dalles) ; lumière
  `interior_warm` ; zone Jadielle. **Porte** : nouveau champ `Warp.if_flags` / `WarpPoint.if_flags`
  (lu par `SceneRouter._is_warp_enabled`) ; deux warps PUSH ↑ (9, 10), (10, 10) actifs avec
  les 7 Badges ; l'examen « La porte est verrouillée. » porte le nouveau champ `unless_all_flags` (`InteractPoint` / `Interaction` : cible retirée quand tous sont levés) ;
  spawn `from_gym`. Scène de Jadielle modifiée à la main (comme les sorties nord), outil du J7 mis
  à jour en conséquence. Guetteur à trois variantes.
- **T10** : départs `viridian_gym`, `viridian_gym_giovanni`, `viridian_locked` ; tests `test_viridian_gym` (9), `test_viridian_gym_door` (6), `test_giovanni_gym` (5), `test_fissure` (6). Suite complète 6 514 / 6 514, import sans erreur.
- Capture headless relue (`tools/capture_map.gd`) : Dresseurs, objet, dalles et arrêts lisibles.

### 10.2 Reste

- **T4** (simulation d'équilibrage) non faite : niveaux RB tels quels (défaut Q28-4), à juger en jeu.
- **T5** (vue générale) et lot d'art (intérieur, Giovanni Champion, Rhinoféros, fond de combat) :
  art provisoire seulement ; aucun fond de combat dédié (repli par défaut).
- **T11** session téléphone, **T12** clôture et fusion **après le J26** (accord de Kevin).
- À la fusion : retirer `kanto_j28_emprunts.json` (et les fiches de Pokédex / sprites en double) si
  J22 / J23 sont déjà dans `main` ; régénérer `tm_compatibility.json` ; recaler les listes des
  tests partagés (`test_dialogue_data`, `test_cutscene_data`, `test_pokemon_data`,
  `test_item_library`) ; `FUTURE_FLAGS` de `test_dialogue_data` porte `badge_soul`, `badge_marsh`, `badge_volcano`
  (à retirer quand leurs arènes existent).

### 10.3 Pour Kevin

- Relire les textes complémentaires du §3.1 (Dresseurs, défaite, CT, guide après le départ).
- Q28-1 (condition d'ouverture) : le code suit la passe (drapeau de la Sylphe seul).
- Q28-3 : réglée par la validation d'avance (T28-01 à T28-09).
