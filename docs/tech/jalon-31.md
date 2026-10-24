# Jalon 31 — La Grotte Azurée et Mewtwo

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j31-v1-chatgpt.md` (dossier V1, 7 arbitrages verrouillés). Les arbitrages et
> les textes recommandés par la passe sont **validés par Kevin le 2026-10-21 (validation d'avance
> des textes recommandés)**. Tout texte absent de la passe est une proposition marquée **[D]**.

> Objectif jouable sur le téléphone : **après la Ligue, on retourne à Azuria, on entre dans la
> Grotte Azurée, on y explore trois niveaux, on affronte Mewtwo N70 et on tente de le capturer.**
> Aucune nouvelle fin imposée ; la partie continue librement.
>
> Mécaniques nouvelles : l'**accès post-Ligue** (calculé, jamais sauvegardé), la **rencontre
> légendaire unique** (une seule règle pour Artikodin, Sulfura et Mewtwo). Rien d'autre : le Surf,
> les échelles et les donjons multi-étages existent déjà (passe systèmes 2, J24, J29).
>
> **Format de sauvegarde : pas d'incrément prévu** (§2.4). Si un incrément devient nécessaire, il
> se fait après la fusion du jalon précédent et se valide seul (règle 1 de `CLAUDE.md`).

## 0. État et dépendances (relu sur le dépôt, `origin/main`)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Espèce Mewtwo | Absente de `data/pokemon/species/` (les espèces arrivent jalon par jalon) | À créer (T4) |
| Grotte Azurée | Aucune carte ni grille dans `tools/plans/` | Les 3 grilles sont à relever (T3) |
| Entrée côté Azuria | Carte d'Azuria du J13 ; point d'entrée non vérifié | À vérifier en 31.0 (T1) |
| Victoire à la Ligue | `league_first_clear_completed` n'existe pas encore (J30, conception seule) | Contrat à poser (T2), test avec drapeau simulé |
| Surf, rochers, courants | Passe systèmes 2 (branches `s2c-surf`, `s2d-force`), pas encore dans `main` | Les cartes réelles attendent leur fusion |
| Rencontre légendaire | Règle d'Artikodin dans `docs/tech/jalon-24.md` §2.7 (capture ou K.O. : consommée ; fuite ou défaite : rien) | Une seule implémentation (T2) |
| Master Ball | J26, conception | Test de capture garantie après sa fusion |
| Sauvegarde | `SaveSystem.VERSION = 7`, écriture atomique, migrations (`game/systems/save/save_system.gd`) | Drapeaux en champs à valeur par défaut |
| Outils de carte | `tools/plans/*.txt`, `tools/build_*.gd`, `tools/art/plan_grille.py`, `cave_map_kit.gd` | Réutilisés tels quels |

### 0.1 Ce qui peut commencer tout de suite
- **T1** audit 31.0 (lecture seule) ; **T2** contrat J30 → J31 et règle légendaire (logique pure) ;
  **T3** grilles ASCII des trois niveaux (relevé Rouge/Bleu) ; **T4** données (Mewtwo, rencontres,
  objets) ; **T5** accès calculé (test avec drapeau simulé).

### 0.2 Ce qui attend
- **T6 à T9** (cartes réelles, Surf, échelles, combat) : après la fusion de la passe systèmes 2 et
  du J30. **T9** (Master Ball) : après le J26. **T10** (QA complète) : après tout le reste.
- Règle d'ancienneté : le J31 ne modifie aucun système qu'un jalon plus ancien est en train de
  modifier ; en cas de doute, demander à Kevin.

## 1. Périmètre

**Dedans** : trois cartes (1F, 2F, B1F), accès depuis Azuria, rencontres sauvages de haut niveau,
objets, Mewtwo N70 (fixe, capturable une fois), persistance, rejouabilité.
**Dehors** : nouvelle CS, nouveau Badge, minimap, flèches d'objectif, cinématique explicative,
Dresseurs dans la grotte (non prévus par la passe : à confirmer au §8).

## 2. Contrats

### 2.1 Accès (dossier §3)
`CeruleanCaveAccess.is_open(state)` est **calculé** depuis `league_first_clear_completed` (J30). Il
ne lit ni le nombre de Badges, ni le Pokédex, ni la présence de Mewtwo. Refusé : 7 Badges ; 8 Badges
sans Ligue ; Conseil des Quatre vaincu sans Champion ; accordé : Champion vaincu et victoire
enregistrée, y compris après rechargement.

### 2.2 Géographie
Entrée sur l'**îlot de la baie est** d'Azuria, déjà peint dans la grille du J13 (D-12), accès **en Surf depuis le canal** (décision de Kevin, 2026-10-22 ; aucune refonte d'Azuria). Surf selon le modèle hybride du J16 (CS possédée,
Pokémon compatible dans l'équipe, Badge Âme). **Tous les chemins sont atteignables avec les
capacités déjà obtenues** (test d'atteignabilité sur la grille, T7).

### 2.3 Rencontre légendaire (un seul comportement pour trois Pokémon)
Données par légendaire : `id`, espèce, niveau, carte, case, drapeau de résolution. Règle :
**capture ou K.O. : rencontre consommée ; fuite ou défaite : rien n'est consommé, le Pokémon reste.**
Mewtwo : N70, fixe, ne se déplace pas, absent de la carte une fois résolu. Aucun doublon après
rechargement ni après fermeture de l'appli pendant le combat (la rencontre n'est consommée qu'à la
résolution ; la capture ajoute le Pokémon et pose le drapeau dans **la même écriture**).

### 2.4 États persistants (dossier §8)
| Identifiant | Source |
|---|---|
| `cerulean_cave_unlocked` | **Calculé** (pas sauvegardé) |
| `cerulean_cave_discovered` | Drapeau d'histoire (valeur par défaut `false`) |
| `cerulean_cave_items_collected` | Liste d'objets ramassés (mécanisme existant des objets de carte) |
| `mewtwo_encounter_resolved` | Drapeau (partagé avec le contrat §2.3) |
| `mewtwo_captured` | **Non sauvegardé** : source de vérité = équipe, stockage, Pokédex |
| `postgame_unlocked` | Hérité du J30 |
Lecture par `JsonFields.get_*` avec valeur par défaut : une ancienne sauvegarde se charge sans
migration.

### 2.5 Capacités de Mewtwo
Référence du dossier (à confirmer sur les données de première génération) : Psyko, Soin, Météores,
Bouclier. T4 vérifie chaque capacité contre `data/pokemon/moves/` ; une capacité absente est
ajoutée par le jalon ou signalée à Kevin, jamais remplacée en silence.

## 3. Tâches

### T1 — Audit 31.0 (Sonnet, lecture seule)
Inventaire : carte d'Azuria et point d'entrée, `FieldMoves` et état de la passe systèmes 2, données
légendaires du J24, drapeaux du J30, espèces présentes, tables de rencontres `water` et `cave`.
Classement : implémenté et vérifié / présent incomplet / spécifié / absent.
Critère : rapport court dans `docs/tech/` (section 31.0 de ce fichier) avec chemins réels.

### T2 — Contrat J30 → J31 et règle légendaire (Opus, logique pure)
`LegendaryEncounter` (règle §2.3) en données ; `CeruleanCaveAccess` (§2.1). Aucun écran.
Tests : les 5 cas d'accès du §2.1 ; capture, K.O., fuite, défaite ; rechargement après chaque cas ;
interruption entre « capture » et « écriture » (simulée avec le faux système de fichiers de
`tests/`).

### T3 — Grilles des trois niveaux (Sonnet, validation Kevin)
`tools/plans/cerulean_cave_1f.txt`, `_2f.txt`, `_b1f.txt`, relevées sur **Rouge/Bleu** (pas Rouge
Feu/Vert Feuille). Graphe des transitions (échelles, sorties) en tête de chaque fichier. Contrôle
par `plan_check` (atteignabilité, cases d'eau surfable, échelles appariées).
Critère : Kevin valide les grilles et **une** vue générale peinte (stratégie d'accélération, levier 4).

### T4 — Données (Sonnet)
Espèce Mewtwo ; capacités vérifiées ; tables de rencontres par étage (taux et niveaux historiques) ;
objets visibles et cachés placés selon la référence ; musique et ambiance : provisoires (règle 3).
Tests : `tools/check_json_keys.py` ; test de structure des tables ; aucun objet historique remplacé.

### T5 — Accès depuis Azuria (Sonnet)
Porte ou berge d'entrée qui interroge `CeruleanCaveAccess`. Refus : message court (§4). Test
d'intégration avec drapeau simulé ; point de départ de débogage `tools/debug_start/cerulean_cave.json`.

### T6 — Cartes (après passe systèmes 2)
Trois scripts `tools/build_cerulean_cave_*.gd` sur `cave_map_kit.gd` ; palette « gris-bleu, bassins
sombres, reflets froids » du dossier §4. Capture headless relue.

### T7 — Surf, échelles, collisions (après passe systèmes 2)
Entrée et sortie de chaque étage aux bonnes coordonnées ; test d'atteignabilité de tous les objets
et de Mewtwo depuis l'entrée ; Surf refusé sans CS, sans Badge ou sans Pokémon compatible.

### T8 — Rencontres sauvages et objets (Sonnet)
Branchement des tables du T4 ; objet ramassé puis rechargement : absent ; sauvages ordinaires qui
réapparaissent selon le moteur.

### T9 — Mewtwo : combat, capture, persistance (Opus, après J26 pour la Master Ball)
Étape `wild_battle` réutilisée (issues `win` / `catch` / `flee`). Équipe pleine : stockage (jamais
de perte). Tests : Hyper Ball, Master Ball, envoi au stockage, retour après capture (absent),
nouvelle victoire à la Ligue sans reset, interruption pendant le combat.
**Sauvegarde touchée : validée seule** (règle 1).

### T10 — Rejouabilité, sauvegardes, QA S24
Suite complète, QA téléphone (§6), mise à jour de `etat-projet.md` et de la roadmap.

## 4. Textes

Validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés) : aucune cinématique
explicative ; dialogues de deux lignes maximum, environ 40 caractères par ligne.
Propositions **[D]** (la passe ne fournit aucun texte) :
- Refus d'accès : « Les eaux sont trop agitées. Pas maintenant. » — **validé par Kevin (2026-10-22)**
- Première interaction avec Mewtwo : pas de dialogue, cri puis combat. [D]
- Journaux du Manoir (J25) : inchangés ; la cohérence narrative est un contrôle, pas un texte neuf.

## 5. Critères d'acceptation
1. Huit Badges sans Ligue : accès refusé ; première victoire : accès ouvert ; rechargement : ouvert.
2. Les trois niveaux sont traversables, tous les objets atteignables, retour à l'entrée toujours possible.
3. Mewtwo N70 combattu et capturé une seule fois ; absent ensuite ; aucun doublon après fermeture forcée.
4. Pokédex et stockage enregistrent Mewtwo ; Ligue rejouable sans reset.
5. Suite complète verte ; ancienne sauvegarde v7 chargée sans migration.

## 6. QA téléphone (S24)
Une session : entrée depuis Azuria, Surf, échelles aller-retour, 3 combats sauvages, un objet
ramassé puis appli tuée et relancée, Mewtwo (fuite puis retour, puis capture), retour à Azuria.
Observer : commandes tactiles du Surf, stabilité des transitions, reprise Android.

## 7. Risques
Plan relevé sur la mauvaise version du jeu ; Mewtwo dupliqué par une écriture non atomique ;
chemin inaccessible sans nouvelle CS ; collision avec le J30 sur le drapeau de victoire.

## 8. Points ouverts pour Kevin — **tranchés par Kevin le 2026-10-22**
1. Dresseurs dans la Grotte Azurée : **aucun** (fidèle à Rouge/Bleu) — **validé, appliqué**
2. Fuite devant Mewtwo : **il reste** (règle d'Artikodin) — **validé, appliqué**
3. Refus d'accès : « Les eaux sont trop agitées. Pas maintenant. » — **validé, appliqué**
   (`cerulean_cave_closed`)
4. Mewtwo absent du Pokédex avant rencontre : voulu — **appliqué**
5. **Géographie de l'entrée** : **îlot de la baie est** déjà peint dans la grille d'Azuria (J13,
   D-12), accès en Surf depuis le canal ; **pas de déplacement au nord-ouest** (la passe J31 §3,
   « nord-ouest par les berges », est écartée sur ce point). Contradiction résolue (2026-10-22).
6. **Nom** : « **Grotte Azurée** » (nom du J13), pas « Grotte Inconnue » ; tous les textes
   visibles, noms de carte, dialogues et tests du J31 sont alignés. Les identifiants techniques
   (`cerulean_cave_*`) sont inchangés ; aucun changement de format de sauvegarde.
7. **Écarts de relevé** : 45 cases de sol sans accès dans RB changées en roche (§10) ; Guérison
   et Max Élixir du 1F ramassés depuis l'eau (comme RB). [D : conservés.]
8. **Fiches de Pokédex** de Métamorph et Mewtwo — **validées par Kevin (2026-10-22)** :
   - Métamorph (0,3 m ; 4,0 kg) : « Une masse molle qui prend la forme de ce qu'elle regarde.
     Elle a du mal à garder les yeux en place. »
   - Mewtwo (2,0 m ; 122,0 kg) : « Né d'expériences génétiques poussées trop loin. Il dort au
     fond d'une grotte où personne ne descend. »
9. **Autres défauts validés par Kevin (2026-10-22)** : Abo et Sablaireau partagent un emplacement
   de rencontre (en attendant le J32) ; Max Élixir, PP Plus et Morphing créés **sans effet** pour
   l'instant ; aucun Dresseur, et Mewtwo reste si on fuit.

## 9. Audit 31.0 (2026-10-22, branche `jalon-31` depuis `systemes-2` à `8c2cb6ee`)

Classement : **I** implémenté et vérifié · **P** présent mais incomplet · **S** seulement spécifié ·
**A** absent · **H** hors de cette base (sur une autre branche, pas encore fusionné).

| Point | État | Chemins réels |
|---|---|---|
| Surf hybride (CS03, Badge Âme, Pokémon compatible), courants, pêche | I (S2C, S2C-bis validés) | `game/world/surf/`, `data/world/field_moves.json`, `data/fishing/water_rod.json` |
| Niveaux de sol (collisions par paires de RB : sol bas / sol haut / escalier) | P : `GridWorld.Level` existe (`set_level`, `levels_compatible`), mais `GameMap` ne l'expose pas encore (les exports viennent du J24) | `game/world/grid_world.gd` ; `origin/jalon-24` |
| Rencontre légendaire unique (capture ou K.O. : consommée ; fuite ou défaite : rien ; sauvegarde forcée avant le premier texte) | I (S2 T30) : `StaticEncounter` + étape `wild_battle` clé `static` | `game/world/static_encounter/static_encounter.gd`, `game/systems/cutscene/cutscene_director.gd` (`_wild_battle`) |
| Artikodin, Sulfura (mêmes clés `static`) | H | `origin/jalon-24:data/cutscenes/seafoam.json`, `origin/jalon-29:data/cutscenes/j29.json` |
| Titre de Champion permanent | H : `league_champion_defeated` (`LeagueAttempt.CHAMPION_DEFEATED`), drapeaux de tentative temporaires | `origin/jalon-30:game/systems/league/league_attempt.gd` |
| Master Ball | H (`catch_bonus` 1000) | `origin/jalon-26:data/items/items_j26.json` |
| Journaux du Manoir (Mewtwo nommé) | H | `origin/jalon-25:data/dialogues/pokemon_mansion.json` |
| Entrée côté Azuria | **Contradiction résolue (Kevin, 2026-10-22)** : la grille validée d'Azuria (J13, D-12) pose la « Grotte Azurée » sur un îlot de la **baie EST** (51..54, 3..6) ; on la **garde**, accès en Surf depuis le canal (la passe J31 §3 voulait le nord-ouest, écarté) | `tools/plans/azuria.txt`, `docs/design/dossier-16-azuria.md` D-12 |
| Nom du lieu | **Résolu (Kevin, 2026-10-22)** : « Grotte Azurée » partout (J13) | idem |
| Terrain de rencontre « floor » (toute case praticable) | I (J19) ; utilisé par les Îles Écume (J24) | `game/pokemon/encounters/encounter_director.gd` |
| Tables de pêche | I, un seul fichier (`WaterRodTables` ne lit que `water_rod.json` + QA) | `game/world/fishing/water_rod_tables.gd` |
| Mewtwo, Métamorph | A | — |
| Espèces des rencontres | 10 présentes (Nosferalto, Hypno, Magnéton, Abo, Sablaireau, Kadabra, Parasect, Raichu, Ossatueur, Grodoudou) ; 9 sur d'autres branches (H) | voir §10 |
| Capacités de Mewtwo à N70 (Psyko, Soin, Météores, Bouclier) | Psyko, Soin, Météores I ; Bouclier H (J21) | `data/pokemon/moves/` |
| Objets de RB | Guérison, Pépite, Super Bonbon I ; Hyper Ball H (J22), Rappel Max H (J25) ; Max Élixir, PP Plus A (aucun moteur de PP : le Max Éther du J29 est « sans effet ») | `data/items/` |
| Outils de grille | I : `plan_grille.py`, `tests/helpers/plan_grid.gd` ; décodeur RB du J24 (H) servi de modèle | `tools/art/` |
| Format de sauvegarde | I : v7, drapeaux lus avec défaut ; **aucun incrément** au J31 | `game/systems/save/save_system.gd` |

## 10. Fait le 2026-10-22 (branche `jalon-31`, depuis `systemes-2` + `plans-j31-j40`)

Seules les parties démarrables (§0.1) : T1 à T5. Défauts **[D]** appliqués (validés par Kevin
le 2026-10-22) : **aucun Dresseur** dans la grotte (§8.1) ; **Mewtwo reste après une fuite**
(§8.2, règle d'Artikodin) ; **refus d'accès par le message du §4** (§8.3) ; Mewtwo sans fiche de
Pokédex avant rencontre (§8.4, comme les autres).

- **T3 — grilles** `tools/plans/cerulean_cave_1f.txt`, `_2f.txt`, `_b1f.txt` : relevé **1:1 de
  Rouge/Bleu** (30 × 18 par étage), décodé de `pokered` par `tools/art/cerulean_cave_rb_decode.py`
  (même méthode que les Îles Écume du J24 : tuile en bas à gauche, collisions par paires). Légende
  du J24 : `.` sol bas, `:` sol haut, `=` escalier, `w` eau surfable, `U`/`V` échelles, `E`
  bouche, `x` indice d'objet caché. 7 paires d'échelles (P1..P6 1F ↔ 2F, P7 1F ↔ B1F) ; arrivée
  voisine de chaque échelle, du côté qui mène quelque part (P5 en (2, 3), sol bas).
  **Écarts avec RB** : 45 cases de sol **sans accès dans RB** (poches décoratives, ni à pied ni en
  Surf) → roche, comme au J24 (27 au 1F, 18 au B1F, liste en tête des grilles) ; objets cachés de
  RB dans la roche → indice `x`, l'objet se prend depuis la case voisine.
  **Contrôle** `tools/art/plan_check_cerulean_cave.py` (+ `--autotest`, 4 pièges refusés) : 7
  paires réciproques ; toute case praticable atteinte (859, dont 156 d'eau) ; 8 objets visibles, 2
  cachés et Mewtwo touchés ; **retour à la bouche possible depuis tout état** ; **sans Surf, le B1F
  et Mewtwo sont inatteignables** (1F et 2F seulement, PP Plus seul objet) ; entrée → Mewtwo : 297
  pas, 3 échelles (1F → 2F → 1F ouest → B1F), 68 cases en Surf. Constat pour T7 : la Guérison
  (7, 13) et le Max Élixir (19, 3) du 1F ne se touchent **qu'en Surf**, face à l'objet (comme RB) :
  l'interaction depuis l'eau doit marcher.
- **T2 / T5 — accès** `game/systems/story/cerulean_cave_access.gd` (`CeruleanCaveAccess`, pur) :
  ouvert si et seulement si `league_champion_defeated` (titre du J30, valeur recopiée de
  `origin/jalon-30` ; un test vérifie l'égalité avec `LeagueAttempt.CHAMPION_DEFEATED` dès que la
  classe existe) ; jamais sauvegardé ; `refusal_for` → `cerulean_cave_closed` ; `record_entry`
  pose `cerulean_cave_discovered`. Tests `test_cerulean_cave_access` : 7 Badges, 8 sans Ligue,
  Conseil des Quatre sans Champion (refusés), Champion (ouvert), rechargement, nouvelle tentative
  et défaite après le titre (toujours ouvert), départs de débogage.
- **Règle légendaire** : **aucune nouvelle classe** ; Mewtwo est une donnée de la règle unique déjà
  codée (`StaticEncounter`, S2 T30) : scène `mewtwo` (`data/cutscenes/cerulean_cave.json`) : cri
  « Mew ! » [D] puis `wild_battle` N70, intro « legendary », `static` = `mewtwo_encounter_resolved`
  / `mewtwo_caught`. Écart avec le §2.4 : `mewtwo_caught` est posé **comme pour Artikodin et
  Sulfura** (une seule règle) ; la possession reste lue dans l'équipe et le stockage. Tests
  `test_j31_data` : capture / K.O. / fuite / fuite du sauvage / défaite, rechargement après
  chaque cas, Mewtwo absent une fois résolu, **aucun doublon** quelle que soit la sauvegarde qui
  survit (avant ou après la capture).
- **T4 — données** : Mewtwo (n° 150, apprentissage RB : à N70 Météores, Psyko, Bouclier, Soin) et
  Métamorph (`kanto_j31.json`) ; Morphing (`j31.json`) **sans effet** (`pending_effects`) ;
  rencontres RB par étage (`data/encounters/cerulean_cave.json`, terrain `floor`, taux 10 / 15 /
  25, poids des dix emplacements de RB ; **exclusivités Abo / Sablaireau partagées** comme au J24,
  en attendant la décision du J32) ; Super Canne groupe 9 (`super_rod_cerulean_cave` dans
  `water_rod.json`) ; 8 objets visibles et 2 cachés de RB (`data/npcs/cerulean_cave_*.json`,
  scènes et dialogues) ; Max Élixir et PP Plus **sans effet** (`items_j31.json`, précédent du Max
  Éther du J29) ; sprites provisoires de Métamorph et Mewtwo
  (`tools/gen_placeholder_battlers.gd`, ajoutés en fin).
- **Emprunts (copies identiques, à dédoublonner à la fusion)** :
  - `data/pokemon/species/kanto_j31_emprunts.json` : Dodrio, Aéromite, Électrode, Poissoroy (J22),
    Leveinard (J23), Flagadoss, Krabboss, Hypocéan (J24), Rhinoféros (J28) ; leurs fiches de
    Pokédex (`data/pokedex/kanto.json`) et sprites provisoires (`assets/sprites/pokemon/placeholder/`)
    copiés de la même branche ;
  - `data/pokemon/moves/j31_emprunts.json` : Amnésie, Bouclier (J21), Pince-Masse, Force Poigne
    (J22), Guillotine (J23 : version **avec** l'effet `ohko`, celle que le moteur de cette base
    applique déjà à Empal'Korne ; les J24 et J29 l'ont en `pending_effects`) ;
  - `data/items/items_j31_emprunts.json` : Hyper Ball (J22), Rappel Max (J25) ;
  - **Divergences connues** entre branches (la plus ancienne est copiée) : sprites provisoires
    d'Aéromite, Leveinard, Krabboss différents sur `jalon-29` ; Guillotine (ci-dessus).
- **Départs de débogage** `tools/debug_start/cerulean_cave.json` (Champion, 8 Badges, CS03,
  équipe N60–65, Hyper Balls, Super Canne) et `cerulean_cave_locked.json` (8 Badges, Conseil des
  Quatre vaincu dans une tentative, pas de Champion) ; tous deux à Azuria (`from_center`) en
  attendant les cartes.
- Tests d'inventaire mis à jour (`test_pokemon_data`, `test_item_library`,
  `test_encounter_library`, `test_pokedex_library` : Leveinard rencontrable avec sa note du J23,
  Métamorph et Mewtwo sans fiche).

### 10.1 Reste à faire (attend d'autres branches ou Kevin)
- **31A — entrée** (T5 en jeu) : bouche de la grotte sur la carte d'Azuria, eau surfable, warp
  vers `cerulean_cave_1f:entree` qui interroge `CeruleanCaveAccess` : géographie
  tranchée (îlot de la baie est du J13, Surf depuis le canal) ; après la fusion du J30.
- **T6–T8 — cartes** : trois `tools/build_cerulean_cave_*.gd` d'après les grilles ; **après la
  fusion du J24** (exports des niveaux de sol dans `GameMap`, kit de grotte à niveaux) ; vue
  générale peinte à valider (T3, levier 4) ; `fishable_cells` ; voile : aucun (grotte éclairée,
  RB).
- **T9** : test de capture avec la Master Ball après le J26 ; QA de la capture en équipe pleine.
- **T10** : QA S24 (§6).
- Fiches de Pokédex de Métamorph et Mewtwo : textes à écrire et valider (§4).
- Morphing, Max Élixir, PP Plus : effets à coder (moteur de PP absent).

Validation (2026-10-22) : import headless sans erreur ; suite complète **6 506 / 6 506** (593
scripts) ; `plan_check_cerulean_cave.py` conforme, `--autotest` refuse ses 4 pièges ;
`check_json_keys.py` sans doublon.

## QA A17 du 2026-10-23

Pas de grotte jouable (cartes T6–T8 et entrée 31A à venir). Contrôle minimal sur le Galaxy A17 :
le départ `cerulean_cave` se charge à Azuria (équipe N60–65, Hyper Balls au Sac). **Ouvert (art)** :
l'Hyper Ball (emprunt du J22) n'a pas d'icône (icône générique). La QA du §6 reste à faire.

## 11. Fait le 2026-10-24 (branche `jalon-31`) : fusion de `main`, cartes T6–T8, entrée 31A

- **Fusion de `origin/main`** (`38d8e446` : J22, J24, moteur commun) dans `jalon-31` (`1b5e3694`).
  Conflits : `etat-projet.md` (deux historiques gardés) et tests d'inventaire (deux côtés
  additionnés). **Emprunts dédoublonnés** (version de `main` gardée, toutes identiques) : Dodrio,
  Aéromite, Électrode, Poissoroy (J22), Flagadoss, Krabboss, Hypocéan (J24), leurs fiches de
  Pokédex ; Pince-Masse, Force Poigne (J22), **Guillotine** (J24 : même version, avec `ohko`) →
  `data/pokemon/moves/j31_emprunts.json` retiré ; Hyper Ball (J22). **Restent empruntés** (branches
  pas encore dans `main`, vérifié par `git merge-base --is-ancestor`) : Leveinard (J23) et
  Rhinoféros (J28) dans `kanto_j31_emprunts.json` (fiches et sprites provisoires), Rappel Max
  (J25) dans `items_j31_emprunts.json`. L'icône `ultra_ball.webp` n'est pas dans `main` : gardée.
  **Max Élixir** : le J24 le gardait hors des bibliothèques (`data/j24_pending/items.json`), le
  J31 l'a créé sans effet (validé par Kevin, §8.9) : retiré de `j24_pending`, une seule
  définition (`items_j31.json`) ; `test_j24_data` ajusté. Le Max Élixir caché du B3F des Îles
  Écume (« pas de point tant qu'il n'existe pas », `build_j24_seafoam.gd`) peut maintenant être
  posé : laissé au J24 (non fait ici).
- **T6–T8 — cartes** : `tools/build_cerulean_cave.gd` (**un** script pour les trois étages, comme
  `build_j24_seafoam.gd`, au lieu des trois scripts annoncés au §3) génère
  `game/world/maps/cerulean_cave_1f.tscn`, `_2f`, `_b1f` d'après les grilles (tuiles provisoires
  `OverworldTiles` : roche `# x` en falaise, sol bas en terre, sol haut `:` en pavé, escalier `=` en
  planches, eau `w`). Niveaux de sol : nouvelle `CaveLevelGate` (`game/world/caves/`, FlagGate sans
  dessin) qui reprend la seule partie « niveaux » de `SeafoamFloorGate` (pas de courants) ; le
  J24 n'est pas modifié. Eau : `surf_cells` = `fishable_cells` = toutes les cases `w` (Super Canne
  groupe 9, déjà en données). Échelles : 7 paires STEP_ON vers `arrivee_pN` (échelles dessinées
  comme aux Îles Écume). Objets visibles et Mewtwo : PNJ des `data/npcs/cerulean_cave_*.json`
  (inchangés) ; objets cachés : point d'examen sur l'indice `x` voisin de la case `objet_cache`
  (caillou clair dessiné), retiré par `got_<id>`. Lumière : `cave_1f` (1F, 2F), `cave_b1f` (B1F)
  dans `lighting.json` [D] ; aucun voile ; zone « Grotte Azurée » (`cerulean_cave`, sous-titre
  « Azuria ») dans `zones.json` et rectangle de la Carte `[1165, 138, 40, 30]` (au nord-est
  d'Azuria) [D].
- **31A — entrée** (faisable sans le J30 : le titre est une simple valeur) :
  `tools/build_cerulean_city.gd` relancé ; eau surfable d'Azuria = cases `w` du canal à l'est du
  pont de l'Arène et de la baie (x 42..55, y 0..18) [D], plus la bouche `A` (52..53, 6) de l'îlot
  (le reste du canal reste du décor) ; bouche = passage STEP_ON vers `cerulean_cave_1f:entree` ;
  retour `from_cerulean_cave` (52, 7) dans l'eau (en Surf). **Fermée** sans
  `league_champion_defeated` : une FlagGate occupe la bouche et EXAMINER face à elle donne
  `cerulean_cave_closed` (texte validé) [D : refus à l'examen, pas de recul automatique].
  `Boot._on_map_entered` appelle `CeruleanCaveAccess.record_entry` (pose
  `cerulean_cave_discovered` à la première entrée, avant l'autosave). Corde Sortie : la grotte
  n'est pas dans `caves.json` (comme les Îles Écume du J24) [D].
- **Tests** `test_j31_maps` (9) : grille → niveaux, eau, roche, pêche ; 14 échelles appariées dans
  les deux sens, arrivée praticable hors passage ; bouche du 1F ↔ îlot d'Azuria ; bouche fermée
  puis ouverte selon le titre, eau surfable limitée à la baie ; objets et Mewtwo présents puis
  absents (Mewtwo reste avec le seul `mewtwo_caught`, retiré par la résolution) ; objets cachés
  visés depuis leur case ; **Guérison (7, 13) et Max Élixir (19, 3) pris depuis l'eau** (aucun sol
  voisin) ; zone, lumière, tables de rencontres ; départs de débogage. Tests d'Azuria (J13, J14)
  recomptés (+2 warps, +2 examens, +1 FlagGate), zones 46.
- **Départs de débogage** (QA A17) : `cerulean_cave` (Azuria, devant le Centre : chemin complet
  par le canal), `cerulean_cave_locked` (bouche fermée), **`cerulean_cave_1f`** (dans la grotte,
  `entree`), **`cerulean_cave_mewtwo`** (B1F, spawn de débogage `mewtwo_front` (27, 12), tourné
  ↓) ; décrits dans `tools/debug_start/README.md`.
- **Écarts** : un seul script de construction (§3 en annonçait trois) ; capture headless non
  faite (la fenêtre de Movie Maker ne s'ouvre pas dans le bac à sable de l'agent) : vue à faire
  sur le téléphone ; vue générale peinte (T3, levier 4) toujours à faire.

Validation (2026-10-24) : import headless sans erreur ; suite complète **6 796 / 6 796** (633
scripts) ; `plan_check_cerulean_cave.py` et `plan_check_azuria.py` conformes ; `check_json_keys.py`
sans doublon.

### 11.0 QA A17 du §6 — 2026-10-24 (`84060036`, A17 en Wi-Fi, passe d'agent par adb)

Captures dans `build/qa_j31/` (non versionnées). Journal Godot : aucune erreur ni avertissement.
- **`cerulean_cave_locked`** : Surf jusqu'à l'îlot, examen → « Les eaux sont trop agitées. Pas
  maintenant. », pas d'entrée : **OK**.
- **`cerulean_cave`** : **défaut bloquant, corrigé**. La bouche `A` (52..53, 6) n'est ni praticable
  ni `w` dans la grille ; `cerulean_map_kit` la peignait en paroi (tuile solide), et `can_enter_as`
  refuse le solide même en Surf : impossible d'entrer, même Champion. Correctif : tuile d'eau
  sur la bouche dans la couche logique (`_add_cave_mouth`), carte reconstruite ;
  `test_j31_maps` vérifie maintenant `can_enter_as(SURF)` (le test ne regardait que
  `is_surfable` et `is_occupied`) ; `test_cerulean_city` : `A` n'est plus solide. **Vu sur l'A17** :
  sortie de la grotte puis pas vers le haut en Surf → `cerulean_cave_1f` (20,7 ms).
- **`cerulean_cave_1f`** : sol haut, escaliers, Surf sur le lac (montée et descente), échelle P2
  1F↔2F aller-retour (14,4 / 14,5 ms), Max Élixir et Guérison pris depuis l'eau, Super Bonbon
  caché depuis (14, 12), 3 combats sauvages (Magnéton ×2, Hypno), sortie vers Azuria (213 ms) :
  **OK**. Appli tuée et relancée : redémarre au départ (attendu pour un départ de débogage).
- **`cerulean_cave_mewtwo`** : cri « Mew ! », combat N70, fuite → il reste, nouveau combat :
  **OK**. 10 Hyper Balls sans capture (Mewtwo à PV pleins) : capture puis absence **non
  vérifiées**.
- Adversaires (Mewtwo, Magnéton, Hypno) face au joueur. Cadence : 48–52 i/s dans la grotte,
  47–53 à Azuria, 38–40 en combat.
- **Défauts ouverts** : Mewtwo dessiné sur la carte comme un PNJ humain générique (sprite de
  carte manquant) ; Poké Ball juste au-dessus du héros en Surf cachée par son sprite ;
  description de l'Hyper Ball tronquée dans le Sac de combat (comme la Guérison au J30 §10.9) ;
  dos des Pokémon du joueur en pixel art basse résolution à côté des artworks de face.
- Non couvert : échelle P7 (1F↔B1F), capture et K.O. de Mewtwo, reprise d'une vraie sauvegarde.

### 11.1 Reste à faire
- **T9** : capture avec la Master Ball après le J26 ; capture en équipe pleine (QA).
- **T10** : QA A17 du §6 faite (§11.0) ; reste capture de Mewtwo (l'affaiblir d'abord), échelle
  P7, et les défauts ouverts du §11.0. Suite complète après le correctif : **6 796 / 6 796**.
- À la fusion du J30 : `test_cerulean_cave_access` vérifie l'égalité du drapeau de Champion.
- À la fusion des J23, J25, J28 : retirer Leveinard, Rappel Max, Rhinoféros des emprunts.
- Max Élixir caché du B3F des Îles Écume (J24) : à poser maintenant que l'objet existe.
- ~~Fiches de Pokédex de Métamorph et Mewtwo~~ : **posées le 2026-10-24** (`data/pokedex/kanto.json`,
  textes et mesures du §8.8 ; `test_pokedex_library` : plus aucune espèce sans fiche) ; effets de Morphing,
  Max Élixir, PP Plus (moteur de PP absent) ; art définitif de la grotte.
- **[D] à relire par Kevin** : eau surfable d'Azuria limitée à l'est du pont de l'Arène ; refus à
  l'examen de la bouche ; lumière par étage ; description de la zone (« Une grotte sur l'îlot de
  la baie d'Azuria. Ses eaux sombres abritent des Pokémon d'une force rare. ») ; rectangle de la
  Carte ; pas de Corde Sortie.
