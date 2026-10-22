# Jalon 29 — La Route Victoire (Routes 22 et 23, rival n° 7, huit contrôles, Route Victoire, Sulfura, Plateau Indigo)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j29-v1-chatgpt.md` (7 arbitrages verrouillés par Kevin le 2026-10-19 ; ne pas
> les rouvrir). Plan écrit le 2026-10-21 (branche `plans-j26-j30`), en conception seulement.

> Objectif jouable sur le téléphone : **la dernière route.** À l'ouest de Jadielle, le **rival**
> attend sur la Route 22 avec six Pokémon (n° 7, obligatoire). Au nord, **huit gardes** vérifient
> chacun un Badge ; la Route 23 se traverse à pied et en **Surf**. La **Route Victoire** monte sur
> trois niveaux : rochers de **Force**, **interrupteurs**, **barrières**, Dresseurs, Pokémon
> sauvages et **Sulfura** (N50, rencontre unique). Au bout, le **Plateau Indigo** : Centre,
> Boutique, porte de la Ligue. Le joueur y arrive librement ; la Ligue est au J30.
>
> **Mécanique nouvelle : aucune.** Force, interrupteurs, barrières et contrôle d'anti-blocage
> (S2D), Surf (S2C), rencontre légendaire fixe (S2G), rival par starter, gardes par variantes
> `if_flags` (aucun système : passe systèmes 2 §0.4).
>
> **Format de sauvegarde inchangé : v7** (drapeaux seulement ; aucune position de rocher).

## 0. État et dépendances

### 0.1 Contrat d'entrée, relu sur le code (2026-10-21)

| Besoin | Où, état réel | Ce que fait le J29 |
|---|---|---|
| Route 22 | `main` (J7) : `route_22` (46 × 27), `tools/build_route_22.gd`, **aucune grille** dans `tools/plans/` ; « **aucun passage vers l'ouest** » (colonne 0 solide) ; scène du rival n° 2 (`rival_route22`, déclencheur `RivalVista`, sentier haut) | Ouvre l'ouest : grille `route_22.txt` reconstruite **depuis la carte actuelle**, prolongée jusqu'au poste de la Ligue ; scène n° 2 **intacte** |
| Rival par starter | `main` : `rival.json` (`team_by_starter`, clé = starter du joueur), `rival_route22` (n° 2) | Nouvelle entrée **`rival_route22_final`** (n° 7), jamais `rival_route22` |
| Huit Badges | `main` : `badges.json`, drapeaux `badge_*` ; `badge_marsh` (J27), `badge_volcano` (J25), `badge_earth` (J28), `badge_soul` (J23) arrivent avec leurs jalons | Gardes en variantes `if [badge_*]` ; source de vérité = drapeaux de Badge |
| Surf (CS03 + Pokémon compatible + Badge Âme) | `systemes-2` (S2C, validé) ; CS03 en données au J23 ; entrée `surf` de `field_moves.json` posée par la passe | Eau surfable `w` dans la grille de la Route 23 |
| Force, rochers, trous, interrupteurs, barrières, `plan_check_boulders.py` | `systemes-2` (S2D) : **codé, QA faite**, en attente de la validation de Kevin et de la fusion (`integration-s2d`, `s2d-force`) | Positions `rocher`, `interrupteur`, `barriere` dans les grilles ; aucune règle propre |
| Rencontre légendaire fixe | `systemes-2` (S2G, T30, validé) : étape `wild_battle` avec `static`, `intro: legendary`, sauvegarde forcée ; politique d'Artikodin (capture ou K.O. → consommée ; fuite ou défaite → rien) | Sulfura en données (`moltres_done`, `moltres_caught`) |
| Master Ball | J26 (`master_ball`) | Rien : utilisable, pas nécessaire |
| Vol | `systemes-2` : `fly_points.json` prévoit `indigo_plateau` / `from_center` | Crée le spawn, ou corrige la donnée |
| Plateau Indigo | `zones.json` : `indigo_plateau` (`kind: place`, `"maps": []`) ; fond peint `backdrop_plateau_indigo_01.png` (Route 22) | Crée les cartes et les déclare |
| Espèces | Sulfura absent ; nombreuses espèces de la Route Victoire absentes (audit T3) | À créer, après vérification des branches J21 à J28 |

### 0.2 Contrat de sortie (pour le J30)

| Donnée | Règle |
|---|---|
| Cartes `indigo_plateau` (extérieur) et `indigo_plateau_lobby` (Centre, Boutique) | Point de repos `indigo_plateau_lobby` ; porte nord de la Ligue posée en « À venir », que le J30 branche |
| `rival_route22_final` | Distinct ; le J30 crée `rival_champion` |
| `no_fly` | Rien sur le Plateau ; la Ligue (J30) sera `no_fly` |

### 0.3 Ce qui peut commencer maintenant, ce qui attend

**Maintenant** : T1 à T6 (décodage RB, grilles des Routes 22 et 23, des trois niveaux et du Plateau,
**preuve d'anti-blocage** avec `plan_check_boulders.py` lu sur `integration-s2d`, données, textes, vue
générale).

**Après la fusion de la passe systèmes 2 (S2D compris) dans `main`** : la Route Victoire et la
Route 23 (T7 et suivantes). Le rival final et les gardes peuvent être codés sans les J23 à J28 :
les tests posent les drapeaux de Badge. Pour la QA en **vraie** progression, il faut le J23 (CS03,
CS04, Badge Âme) et les Badges des J25, J27, J28 dans `main`. **Fusion recommandée après le J28.**

### 0.4 Écarts et vérifications

- **Poste du Badge Roche.** Dans Rouge/Bleu, le Badge Roche est contrôlé au **poste de la Ligue**
  (bâtiment entre la Route 22 et la Route 23), les sept autres sur la Route 23 (à confirmer à
  l'audit, pokered `Route22Gate`, `Route23`). La passe dit « huit postes sur la Route 23 » **et**
  « fidèles à Rouge/Bleu ». Défaut [D] : poste n° 1 = le poste de la Ligue, seuil de la Route 23
  (RB) ; postes 2 à 8 sur la Route 23. Q29-1.
- **Déclenchement du rival.** RB : le rival apparaît sur la Route 22 **après le Badge Terre**. La
  passe le rend obligatoire (adaptation assumée). Défaut [D] : il se tient devant le poste de la Ligue
  `if [badge_earth] unless [<victoire rival_route22_final>]` et bloque le passage tant qu'il n'est
  pas battu. Un joueur sans Badge Terre ne le voit pas, mais il est arrêté au poste n° 8 de toute
  façon. Q29-2.
- **Route 22 actuelle** : la scène n° 2 vit sur le sentier haut ; le combat n° 7 est sur le chemin
  bas, à l'ouest. Les deux identifiants et leurs drapeaux sont indépendants (vigilance n° 3).
- **Persistance des rochers** : règle de la passe systèmes 2 (§2.7.4) : interrupteur enfoncé et
  barrière ouverte pour toujours (drapeaux) ; rochers libres remis à leur origine au rechargement de
  la carte. C'est le comportement RB (`EVENT_VICTORY_ROAD_*_BOULDER_ON_SWITCH`).

## 1. Découpage

| Sous-jalon | Lots de la passe | Tâches | Validation |
|---|---|---|---|
| **29.0** | 29.0 | T0 à T6 | Kevin sur planches : grilles, preuve d'anti-blocage, vue générale, textes |
| **29-I** | 29A, 29B | T7 à T10 | — (tests, captures) |
| **29-II** | 29C à 29F | T11 à T17 | **une session téléphone** (Force et Surf déjà validés en S2C / S2D), puis clôture |

Fichiers chauds : `tools/build_route_22.gd` et `route_22.tscn` (carte du J7 : ne rien changer à
l'est ni au sentier haut) ; `rival.json` ; `zones.json`.

## 2. Conception technique

### 2.1 Cartes et grilles

| Grille | Carte | Contenu |
|---|---|---|
| `route_22.txt` (nouvelle) | `route_22` | Relevé de la carte actuelle (T2), prolongé vers l'ouest et le nord jusqu'au poste ; place du rival n° 7 |
| `poste_ligue.txt` | `route_22_gate` | Garde du Badge Roche (poste n° 1) ; sortie nord vers la Route 23 |
| `route_23.txt` | `route_23` | Postes 2 à 8 (gardes debout sur le chemin, comme RB), eau surfable `w`, entrée de la Route Victoire |
| `route_victoire_1f.txt`, `_2f.txt`, `_3f.txt` | `victory_road_1f` … `_3f` | **Puzzles à 1:1** (RB) : `rocher`, `interrupteur`, `barriere`, escaliers, échelles, Dresseurs, objets, Sulfura (2F, RB) |
| `plateau_indigo.txt`, `plateau_indigo_hall.txt` | `indigo_plateau`, `indigo_plateau_lobby` | Extérieur ; hall : infirmière, vendeur, PC, porte nord de la Ligue |

- Décodage `tools/art/victory_road_rb_decode.py` (cartes, rochers, interrupteurs, barrières).
- **Contrôles** : `plan_check.py --legende` ; **`plan_check_boulders.py`** sur les trois niveaux
  (tous les états atteignables par poussée ; depuis chacun, la sortie et l'entrée restent
  atteignables ; une grille qui échoue n'est pas construite) ; `plan_check_j29.py` : raccords
  Route 22 ↔ poste ↔ Route 23 ↔ Route Victoire ↔ Plateau, eau seulement où RB en a, chaque poste
  infranchissable sans son Badge (chemin unique, pas de contournement par l'eau).

### 2.2 Les huit contrôles

- Chaque garde : PNJ bloquant sur le chemin, dialogue à variantes `if [badge_<x>]` (laisse passer,
  s'écarte d'une case comme le garde du J20) / sinon (« Il te faut le Badge … », le joueur recule
  d'une case, mécanisme des déclencheurs de recul du J15).
- **Possession seulement** (vigilance n° 1) : aucune lecture de l'ordre ni des jalons.
- Un joueur arrêté au poste k peut toujours revenir en arrière.
- Pas de `route23_checkpoint_progress` [D] : les drapeaux de Badge suffisent.

### 2.3 Rival n° 7 (`rival_route22_final`)

Référence Rouge/Bleu, **à confirmer par l'audit** (pokered `parties.asm`) ; cohérente avec le
tableau du rival Champion de la passe J30 :

| Starter du joueur | Équipe (RB) |
|---|---|
| Bulbizarre | Roucarnage 47, Rhinocorne 45, Noeunoeuf 45, Léviator 47, Alakazam 50, Dracaufeu 53 |
| Salamèche | Roucarnage 47, Rhinocorne 45, Caninos 45, Noeunoeuf 47, Alakazam 50, Tortank 53 |
| Carapuce | Roucarnage 47, Rhinocorne 45, Léviator 45, Caninos 47, Alakazam 50, Florizarre 53 |

Obligatoire, rejouable après défaite ; Grand moment `rival_battle` (victoire et défaite) ; aucune
modification de l'équipe du joueur après.

### 2.4 Route Victoire

- Force : statut `strength` (CS04 + Pokémon compatible + Badge Prisme, J16) ; activation, poussée,
  `ON_SWITCH`, barrières : S2D, données seulement.
- Rencontres : table RB par niveau (`data/encounters/victory_road_*.json`), union Rouge + Bleu
  (règle des jalons précédents).
- Dresseurs et objets : RB (audit T3).
- **Sulfura** (2F) : PNJ `moltres` `unless [moltres_done]` ; scène `moltres` : texte, puis étape
  `wild_battle moltres 50` avec `intro: legendary`, `actor: moltres`,
  `static: { done: moltres_done, caught: moltres_caught }`. Capture ou K.O. → consommée et
  sauvegarde forcée ; fuite ou défaite → rien, il reste. Master Ball permise.

### 2.5 Plateau Indigo

- Centre (soin, point de repos `indigo_plateau_lobby`), Boutique (inventaire RB), PC (stockage).
- Porte nord : « La Ligue — À venir » jusqu'au J30 [D]. **Aucun dialogue ni soin ne lance la Ligue.**
- Drapeau `indigo_plateau_discovered` : inutile, `discovered_maps` le donne déjà (Vol) [D].

### 2.6 Drapeaux (v7 inchangée)

| Drapeau | Rôle |
|---|---|
| victoire de `rival_route22_final` | convention des combats du rival (T12 la recopie) |
| `badge_*` | lus |
| drapeaux des interrupteurs (`victory_road_<n>f_switch_<id>`) | S2D, posés une fois |
| `moltres_done`, `moltres_caught` | Sulfura |
| `defeated` des Dresseurs, objets | mécanismes existants |

### 2.7 Départs de débogage

`route_22_final` (Badge Terre, devant le rival, 3 variantes) · `route_23_seven` (sept Badges, sans
Terre) · `route_23_all` (huit Badges, CS03, CS04, Pokémon de Surf et de Force) · `victory_road_1f`,
`_2f`, `_3f` (interrupteurs déjà posés ou non) · `moltres` (devant Sulfura, Master Ball, Hyper
Balls) · `indigo_plateau`.

### 2.8 Art

Avant le code : grilles + une vue générale de la Route Victoire (le Plateau a déjà un fond peint).
Lot d'art ensuite : grotte (kit grotte existant en placeholder), interrupteur et barrière, gardes,
poste, Plateau et hall, Sulfura (monde et combat), espèces nouvelles, fonds de combat « Route
Victoire » et « Route 23 ».

## 3. Textes

La passe ne propose aucun texte : tout ce qui suit est **[D] (défaut, à relire)**.

| N° | Locuteur | Texte |
|---|---|---|
| T29-01 [D] | Rival (avant) | « {player} ! J'ai les huit Badges, moi aussi. La Ligue n'aura qu'un seul vainqueur, et ce sera moi. Prouve-moi le contraire ! » |
| T29-02 [D] | Rival (victoire du joueur) | « Encore toi… D'accord. On se reverra là-haut. » |
| T29-03 [D] | Rival (défaite du joueur) | « Tu vois ? Tu n'es pas prêt pour la Ligue. » |
| T29-04 [D] | Garde (sans le Badge) | « Seuls les Dresseurs qui ont le {badge} peuvent passer. » |
| T29-05 [D] | Garde (avec le Badge) | « Le {badge} ! Tu peux passer. » |
| T29-06 [D] | Panneau (Route 23) | « ROUTE VICTOIRE — Seuls les meilleurs Dresseurs arrivent au bout. » |
| T29-07 [D] | Narration (Sulfura) | « Une chaleur intense emplit la grotte… » |
| T29-08 [D] | Narration (Sulfura vaincu) | « Sulfura s'est envolé en laissant une traînée de braises. » (K.O. seulement) |
| T29-09 [D] | Narration (interrupteur) | « Clac ! Un mécanisme s'est enclenché quelque part. » |
| T29-10 [D] | Hôte du Plateau | « Bienvenue au Plateau Indigo. Au-delà de cette porte, le Conseil des Quatre attend. Prépare-toi bien. » |
| T29-11 [D] | Porte de la Ligue (avant le J30) | « La Ligue Pokémon — À venir » (format des portes « À venir ») |

`{badge}` = nom du Badge (`badges.json`). Les répliques des Dresseurs de la Route 23 et de la Route
Victoire sont écrites au T4, en lot, marquées [D].

## 4. Tâches

### 4.1 Sous-jalon 29.0 — **maintenant**

#### T0 — A : plan (ce document) — fait
#### T1 — A : branche `jalon-29` depuis `origin/main` ; audit (pokered : postes, rival, Route Victoire, Sulfura ; branches J21 à J28 : espèces, CS)
#### T2 — C : relevé de la Route 22 actuelle en grille ; prolongement ; poste ; Route 23 ; trois niveaux ; Plateau
#### T3 — A : `plan_check_boulders.py` (lu sur `integration-s2d`) et `plan_check_j29.py` : TOUT EST CONFORME → K
#### T4 — A : données (espèces, rencontres, Dresseurs, rival, Sulfura, objets, répliques [D])
#### T5 — A : simulation d'équilibrage du rival et des Dresseurs (outil du J12)
#### T6 — C (Mac) : vue générale de la Route Victoire → K

### 4.2 Sous-jalon 29-I — **après la fusion de la passe systèmes 2 (S2D compris)**

#### T7 — C : Route 22 ouest et poste de la Ligue (la scène n° 2 inchangée, testée)
#### T8 — C : rival n° 7 — après T7, T4
#### T9 — C : Route 23, eau, sept gardes — après T7
#### T10 — A : tests des contrôles (huit Badges, sept Badges, un seul manquant, aucun)

### 4.3 Sous-jalon 29-II

#### T11 — C : Route Victoire 1F à 3F (géométrie, rochers, interrupteurs, barrières, escaliers) — après T3
#### T12 — C : Dresseurs, rencontres, objets — après T11
#### T13 — C : Sulfura — après T11
#### T14 — C : Plateau Indigo, hall, Centre, Boutique, porte « À venir » — après T9
#### T15 — A : départs de débogage ; test d'intégration Jadielle → Plateau
#### T16 — Q : **session 29** → K
#### T17 — A : clôture, passation J30, fusion **après le J28** et accord de K

## 5. Tests

- `test_route_22_final.gd` : rival n° 7 seulement avec `badge_earth` ; trois variantes par
  `starter_species` ; défaite → rejouable ; scène n° 2 inchangée (déclencheur, drapeaux) ; le
  combat n° 7 ne pose ni n'efface les drapeaux de `rival_route22`.
- `test_route_23_guards.gd` : pour chaque Badge manquant, seul son poste arrête ; huit Badges →
  passage ; retour toujours possible ; Badges obtenus dans le désordre.
- `test_route_23_surf.gd` : eau seulement avec CS03 + Pokémon + Badge Âme (modèle hybride J16).
- `test_victory_road.gd` : grilles = plans ; interrupteur → barrière ouverte, et ouverte après
  rechargement ; rochers remis à l'origine ; sortie toujours atteignable (preuve du contrôle +
  parcours joué) ; Force exige CS04 + Pokémon + Badge Prisme.
- `test_moltres.gd` : capture → `done` + `caught`, sauvegarde forcée ; K.O. → `done` ; fuite et
  défaite → rien ; jamais deux Sulfura.
- `test_indigo_plateau.gd` : point de repos, Vol vers le Plateau, porte « À venir », rien
  d'automatique.
- `test_save_j29.gd` : v7 ; aucune position de rocher écrite.

## 6. Critères d'acceptation

1. `tools/test.sh` passe ; import sans erreur ; captures relues.
2. `plan_check_boulders.py` prouve l'anti-blocage des trois niveaux ; `plan_check_j29.py` conforme.
3. Chaque garde lit son Badge ; un Badge manquant ne bloque que son poste.
4. Rival n° 7 obligatoire, distinct du n° 2.
5. Sulfura unique, capturable, jamais dupliqué.
6. Arrivée libre au Plateau ; la Ligue ne démarre jamais.
7. Session téléphone validée par K.

## 7. QA téléphone (une session, 45 min au plus)

| Scénario | Attendu |
|---|---|
| `route_22_final` ×3 starters | Bonne équipe ; défaite puis victoire |
| `route_23_seven` | Arrêté au poste 8, retour libre |
| `route_23_all` : Surf sur la Route 23 | Montée, nage, descente |
| Route Victoire : poussées, interrupteurs, barrières | Lisible au doigt ; barrière ouverte après relance |
| Rocher mal poussé, sortie de la carte, retour | Rocher remis, puzzle résoluble |
| `moltres` : fuite, puis capture à la Master Ball | Reste, puis consommé |
| Appel pendant le combat de Sulfura, relance | Reprise juste avant ; un seul Sulfura |
| Plateau | Soin, Boutique, porte « À venir » |

## 8. Valeurs par défaut [D]

- Poste n° 1 (Roche) au poste de la Ligue ; postes 2 à 8 sur la Route 23 (RB).
- Rival n° 7 présent avec `badge_earth`, devant le poste, bloquant.
- Pas de `route23_checkpoint_progress`, `victory_road_puzzle_states`, `indigo_plateau_discovered` :
  les drapeaux de Badge, d'interrupteur et `discovered_maps` suffisent.
- Porte de la Ligue « À venir » jusqu'au J30.
- Textes T29-01 à T29-11.

## 9. Points ouverts pour Kevin

- **Q29-1 — Où est le poste du Badge Roche ?** RB : au poste de la Ligue (Route 22), les sept autres
  sur la Route 23. La passe : « huit postes sur la Route 23 ». Défaut : RB. Confirmes-tu ?
- **Q29-2 — Quand le rival apparaît-il ?** Défaut : avec le Badge Terre (RB). Autre option : avec
  les huit Badges.
- **Q29-3 — Textes** : propositions [D]. Couverts par ta validation d'avance, ou à relire ?
- **Q29-4 — Route 22 du J7** : elle n'a pas de grille ; le T2 en fait un relevé avant de l'étendre.
  Le rendu peint de l'est et du sentier haut ne bouge pas. Si l'extension demande de repeindre le
  sol de toute la carte, faut-il le faire au J29 ou dans un lot d'art ?

## 10. État du code (2026-10-22, branche `jalon-29`, nuit de travail autonome)

Branche `jalon-29` depuis `origin/systemes-2` (S2D compris) + `plans-j26-j30`. Textes T29-01 à
T29-11 et répliques [D] : **validés par Kevin le 2026-10-21, validation d'avance (proposition du
plan)** ; Q29-1 (poste du Badge Roche au poste de la Ligue, RB) et Q29-2 (rival avec le Badge Terre,
RB) : défauts du plan appliqués ; Q29-4 : tuiles provisoires, sol peint plus tard.

### 10.1 Fait

- **T1 / T2** : `tools/art/j29_rb_decode.py` (décodeur pokered local, jamais copié) écrit les grilles
  RB 1:1 (`--ecrire`) : `route_victoire_1f/2f/3f.txt`, `route_23.txt` (20 × 144), `plateau_indigo.txt` ;
  `--ecarts` compare grilles et RB. `route_22.txt` = **relevé** de la carte du J7 (`dump_map_logic`),
  `test_route_22_plan` (scène = grille case par case) ; `route_22_ouest.txt`, `poste_ligue.txt` à la main.
- **Route 22 étendue sans toucher la scène n° 2** : trois warps PUSH ← en (1, 16..18) vers la nouvelle
  carte `route_22_west` (partie ouest : rival n° 7 devant la porte du poste, panneau). Aucune autre
  case de `route_22` ne change (diff de la scène : warps et spawn seulement).
- **Niveaux de sol (moteur)** : la Route Victoire de RB a un sol bas et un sol haut reliés par des
  escaliers (collisions par paires) : `GameMap.low_cells / high_cells / stairs_cells` → `GridWorld.set_level`
  (le moteur des niveaux existait déjà, S2C) ; un rocher ne change pas de niveau (`BoulderRules`).
- **Rocher conditionnel** (`BoulderField.add_boulder(…, requires)`, `BoulderSetup.boulder_requires`,
  grille `si=`) : le rocher n° 4 du 3F tombé par le trou (23, 15) réapparaît au 2F en (23, 16), comme RB.
- **T3** : `tools/art/plan_check_j29.py` (huit cartes ensemble) : raccords ; exploration exhaustive
  des états (carte, région, rochers, drapeaux) avec niveaux, trous, interrupteurs, barrières, rochers
  conditionnels ; anti-blocage = depuis chaque jeu d'états atteint, le Plateau reste atteignable ;
  retour vers Jadielle de partout ; chaque drapeau de Force peut être posé ; sans un Badge, le Plateau
  n'est plus atteignable ; le nord de la Route 23 n'est atteignable que par la Route Victoire ;
  `--autotest` (trois pièges). **Long** (plusieurs dizaines de minutes : le 3F a des millions
  d'états) — résultat ci-dessous (§10.3).
- **T4** : données (agent, branche `j29-donnees` fusionnée) : espèces (Sulfura N50, reprises identiques
  des J22–J26 : à dédoublonner à la fusion des jalons), objets, Boutique du Plateau, 11 Dresseurs RB
  (prénoms vérifiés libres sur toutes les branches), rival n° 7 (`rival_route22_final`, équipes RB par
  starter), rencontres (Route 23, trois étages en gravats), textes (`docs/tech/jalon-29-textes.md`).
- **T7, T9, T11, T14** : `tools/build_j29.gd` (route_22_west, route_23, victory_road_1f/2f/3f,
  indigo_plateau) ; `build_painted_interiors.gd --j29` (route_22_gate sur l'enveloppe des postes,
  indigo_plateau_lobby = Centre + marchand + hôte + porte « Ligue Pokémon — À venir », warp sans cible
  que le J30 branche). Zones (Route Victoire dans la zone de la Route 23, titre propre comme la Tour),
  grotte (Corde Sortie → Route 23), lumière, point de repos, intérieurs.
- **T8, T10, T12, T13** : scènes `data/cutscenes/j29.json` : huit contrôles (déclencheur « pas vers le
  nord » sur chaque case de la rangée RB ; sans le Badge : T29-04 et recul d'une case ; avec : T29-05
  une fois, drapeau `<scène>_passed`) ; rival n° 7 (victoire `rival_route22_final_won`, défaite :
  réveil, il reste) ; Sulfura (`wild_battle` S2G, `moltres_done` / `moltres_caught`) ; objets et caches.
  T29-09 joué par `StrengthDirector` au premier enfoncement d'un interrupteur.
- **T15** : départs `route_22_final_{bulbasaur,charmander,squirtle,weak}`, `route_23_seven`,
  `route_23_all`, `victory_road_1f/2f/3f`, `moltres`, `indigo_plateau` (README).
- Tests : `test_route_22_plan`, `test_j29_maps`, `test_j29_story`, `test_boulder_field_j29`, tests de
  données et de zones mis à jour.

### 10.2 Écarts [D] (règle 4)

- Défense Spéc. et Huile Max (aucun effet dans le moteur) → Super Bonbon et Potion Max ; Métamorph
  absent (pas d'effet « transform ») : retiré de la table de la Route 23 ; Max Repousse absent de la
  Boutique (pas de Repousse).
- Sulfura dessiné avec la planche de Rapasdepic en attendant son art ; Topdresseur et Dompteur :
  planche `scout` ; Jongleur : `nerd` ; Karatéka : `hiker` (RB).
- Interrupteurs permanents (aucune remise à zéro en changeant d'étage, contrairement à RB) ; un trou
  bouché se franchit (RB : le trou reste).
- Rival n° 7 battu : il disparaît (pas de marche) ; rival à six Pokémon sans liste de capacités
  (apprentissage par niveau) ; tableau du §2.3 corrigé par l'audit RB (équipes ci-dessus = RB).
- Gardes des rangées 85 et 96 sur l'eau (Nageurs de RB) : contrôle en Surf, recul en Surf.

### 10.3 Reste à faire

- **T5** simulation d'équilibrage (non faite) ; **T6** vue générale de la Route Victoire (art) ;
  **lot d'art** (Q29-4) ; `tm_compatibility.json` des 14 nouvelles espèces (fichier généré).
- **T16** session téléphone (§7) ; **T17** clôture, fusion après le J28 et accord de Kevin.
