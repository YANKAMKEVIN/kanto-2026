# Jalon 8 — Route 2 (sud)

> Objectif jouable sur le S24, dans l'ordre imposé par Kevin (dossier 11, arbitrage 13) : **vue générale peinte → validation → assets → vraie carte**, sans prototype séparé.
>
> **8.0 — La vue générale peinte.** Une image Codex de toute la Route 2 sud, tirée d'un plan schématique en aplats qui suit **case par case** la grille fonctionnelle de ce plan. Kevin valide composition, densité, lisibilité et transition vers la forêt **avant** toute découpe d'asset.
>
> **8.1 — La route.** Au nord de l'arche de Jadielle, plus d'écran « ROUTE 2 — À venir » : le chemin de terre continue, « ROUTE 2 ». Prairies lumineuses et deux grands arbres au départ, une petite zone d'herbes contournable, la grande prairie centrale (traversée courte ou chemin sûr), un rebord pour redescendre, la grande pierre claire, puis les arbres qui se resserrent ; dans la clairière C3, le toit du poste apparaît ; cinq à sept cases d'herbes obligatoires ; la façade du poste, sa porte → « FORÊT DE JADE — À venir ». Roucool, Rattata, Nidoran ♀ ♂, Piafabec, Férosinge (3 %). Art final de la série 10, forêt serrée, lumière `golden_hour`, 60 fps.
>
> **8.2 — La vie de la route.** Une Randonneuse qui fait trois pas en regardant le nord, un Jeune Dresseur près de la grande pierre (sans combat), deux Roucool qui s'écartent ou s'envolent, un Rattata qui fouille près de la souche puis disparaît en fondu, un Nidoran au loin. Deux Poké Balls au sol (« PRENDRE »), deux objets cachés, trois panneaux, le passage boisé et le sentier fermé (« plus tard »). Objectif du menu : « continuer vers le nord. ».
>
> Aucune cinématique, aucun Dresseur, aucun rival, aucune nouvelle mécanique de jeu, **format de sauvegarde inchangé (v3)**.

**Pré-requis** (dossier 11, en-tête) : **textes T1 à T16 validés par Kevin** et **ce plan validé**. Rien de l'art ni du code ne démarre avant. Le J7 est fusionné dans `main`. Ce plan est écrit sur `docs/dossier-11-route-2` à `cc8d515` (= `main` à `86e220f` + dossier 11) ; **chaque tâche d'architecture commence par aligner ce plan sur le code du moment**. **Aligné au T0 (2026-10-06)** sur `main` local à `4107a05` (DA.0 et DA.1 du monde peint, validés par Kevin, pas encore poussés sur `origin`) : §0.3.

Références : `CLAUDE.md` (règles 1 à 10), `docs/design/dossier-11-route-2.md` (**source de vérité** : 14 arbitrages, contrainte de raccord, §1 à §18, textes T1–T16), `dossier-10-foret-de-jade.md` (poste sud, J9), `dossier-09-jadielle.md` §11 (sortie nord), `dossier-07-route-1.md` (« Vue générale peinte v1 », Potion cachée), `cahier-art-monde-v0.1.md`, `fiches-assets/serie-01-place-jadielle.md` (journal des séries 06 à 08, forêt serrée), `roadmap.md` phase 5, `jalon-07.md` (§6.6 monde peint, T4, T22).

---

## 0. État des lieux (code réel à `cc8d515`) et écarts

### 0.1 Ce qui existe pour chaque besoin du dossier

| Besoin (dossier 11) | Existant | Manque |
|---|---|---|
| Carte peinte | `build_viridian_city.gd`, `build_route_22.gd` (`GameMap`, `light_profile`, `PaintedGround` + `GroundMask` RG, `Ground` invisible = source logique, `BorderDecals`, props peints `game/world/props/painted/<id>.tscn`, `PaintedPropRules`) | `tools/build_route_2.gd`, `route_2.tscn`, masque `route_2_ground.png` |
| Forêt serrée (validée par Kevin sur la Route 1 et Bourg Palette) | **seulement dans le prototype** : `proto/da_jadielle/foret_serree.gd`, `sous_bois.gdshader`, textures `proto/da_jadielle/tex/foret_1..8.png` | portage dans `game/` (sous-bois, arbres de forêt en props), §2.12 |
| Raccord sud | Jadielle 56 × 36 : `Route2SoonW/C/E` en (27..29, 1), **PUSH ↑**, `coming_soon = "Route 2"`, rangée 0 bloquée (`BLOCKED_EDGE`) ; spawns de retour `route_2_soon_*` en (27..29, 3) | cible des trois warps, trois spawns `from_route_2_*` (§2.1) |
| Porte du poste « À venir » | `WarpPoint.coming_soon` (PUSH ou STEP_ON, `SceneRouter._follow`), `ComingSoonScreen` (« <LIBELLÉ> — À venir », majuscules), actif en build debug seulement, testé (`test_coming_soon`) | le warp de la porte (§2.2) |
| Rencontres | `EncounterLibrary` (`data/encounters/*.json`, `levels` [min, max], `rate`, `ramp`) ; Route 1 et 22 : `rate` 25, `ramp` 15 → 20 | `data/encounters/route_2.json` |
| Hautes herbes peintes | `ground_hautes_herbes_01` (+ `_bas`), deux touffes par case, matériau de vent (Route 22) | variante **jaune-vert** de la forêt serrée : prototype seulement (`hautes_herbes_jaune.png`, recoloration hors pipeline) |
| Objets cachés | Potion de la Route 1 : `EventTriggerPoint` (pas sur la case) → scène `route_1_potion` : dialogue, `give … found: true` (journal `found_items` + toast), `set` | données seulement (§2.4) |
| Objets **visibles** au sol | rien de dédié. Briques : PNJ de données (`NpcRoster`, présence `unless`), dialogue sans page qui lance une scène, étapes `despawn` / `give found` / `set`, bouton contextuel avec un verbe **`take` / « PRENDRE » déjà prévu** (`InteractButton.VERBS`, « pour les objets ramassables ») | `Interaction.Kind.TAKE`, verbe `take` accepté par `NpcRoster`, apparence d'objet (§2.3), **un asset** (Poké Ball au sol ; T2 : recadrée d'un asset validé, §1.2 B) |
| Rebord | `OverworldTiles.Kind.LEDGE_DOWN` (donnée `ledge` de `Ground`), saut du joueur (arc, aucun asset) | asset `relief_rebord_01` : **prototype seulement** (`rebord.png`, série 08) |
| PNJ, routines | `route` (cases voisines, pause), `look` (attente animée), `idle_react`, variantes « première fois / ensuite » par drapeau (vieil homme de Jadielle) | apparence peinte de la **Randonneuse** |
| Pokémon d'ambiance | `shy` `fly` (envol + fondu) et `flee` (fuite de 3 pas, course si planche de course, **puis fondu**), `AmbientWatcher` ; peints : `pokemon/pidgey`, `rattata` (+ course), `nidoran_f`, `nidoran_m`, `spearow`, `mankey` | rien (§2.6) |
| FUTUR A / B, panneaux | `InteractPoint` (EXAMINE, orientation exigée), dialogues `narration`, `prop_panneau_01` (sans texte), `prop_cloture_01` / `_v_01` | asset de l'arbre dense ; barrière à confirmer sur la vue générale (T2 : variations d'existants, §1.2 B) |
| Objectif | `ObjectiveLibrary` (`data/story/objectives.json`, première entrée valide l'emporte, point final imposé par test) | une entrée |
| Zone | `zones.json` : `route_2` **existe sans carte** (`"maps": []`) ; `GameState.discovered_maps` ; Carte, Pokédex (habitats) | `maps`, `subtitle`, `description` |
| Lumière | `golden_hour` (`data/world/lighting.json`), `WorldLighting` | rien |
| Départ de débogage | `tools/debug_start/*.json` (`route_22.json`…) | `route_2.json` |
| Pipeline d'art | `tools/art/generer.sh` (Codex), `serie06*.py` / `serie07.py` / `serie08.py`, `preparer.py` + `manifeste.json` (sources dans `build/art/` du Mac), `build_painted_props.gd`, `build_character_frames.gd` | série 10, plan en aplats reproductible (§1.1) |

### 0.2 Écarts constatés (à `cc8d515` ; n° 1, 2, 3 et 7 levés depuis, §0.3)

1. **Bourg Palette et la Route 1 peints n'existent que dans le prototype** (`proto/da_jadielle/proto_bourg.gd`, `proto_route1.gd`) ; les cartes du jeu restent en tuiles provisoires. La Route 2 sera donc **la première vraie carte avec la forêt serrée** : son portage (sous-bois, arbres de forêt ≈ 3 cases teintés, hautes herbes jaune-vert) est un travail de ce jalon (§2.12), mutualisé ensuite avec la Forêt de Jade (J9) et le repeint de Bourg Palette et de la Route 1.
2. **Plusieurs textures validées ont été préparées hors pipeline** : découpe des planches `WORLD_TREE_FORET_PLANCHE_A/B` en `foret_1..8`, recoloration jaune-vert des hautes herbes ; aucun script versionné. Les autres (souche, rebord, pierres, ronces, tronc couché, bouleau, conifère, grand chêne) ont leur source dans `build/art/` mais ne sont pas dans le manifeste. → T3 les fait entrer dans `manifeste.json` (§1.2).
3. **Les plans en aplats** de Bourg Palette et de la Route 1 ont été dessinés par des scripts non versionnés. → `tools/art/plan_aplats.py` (T0), lu depuis la grille du §1.1.
4. **Jadielle est générée** (`build_viridian_city.gd`) et ses nœuds portent des `unique_id` : relancer l'outil réécrit tout le `.tscn` (diff énorme, conflits). → modification minimale (§2.1).
5. `NpcRoster` refuse tout verbe autre que `talk` / `observe` ; `Interaction.Kind` n'a pas `TAKE` alors que le bouton contextuel l'a déjà (§2.3).
6. `NpcRoster` interdit `idle_react` sur un Pokémon `shy` : le « fouille brièvement le sol » du Rattata passe par `look` (§2.6).
7. Chaque `WorldProp` avec `fade` tourne un `_process` par image : à proscrire sur les centaines d'arbres de forêt (§2.12, §4).
8. Le dossier 11 §17 dit « dialogues lus de P1 / P2 : pas à mémoriser », mais le seul mécanisme « première fois / ensuite » existant est un drapeau d'histoire sauvegardé (Q-2, §5).

### 0.3 Alignement du T0 (2026-10-06) : le monde peint est arrivé dans `main`

`main` (local, `4107a05`, « Fusion : DA.0 et DA.1 ») contient l'intégration du monde peint (`docs/tech/integration-da-bourg-route1.md`). La branche du J8 (`docs/dossier-11-route-2`, fusionnée avec `origin/main`) ne l'a pas encore : **la fusionner avant le T4**. Conséquences sur ce plan :

1. **Forêt serrée de production déjà dans `game/`** : `DenseForest` (`game/world/forest/dense_forest.gd`, classe pure, plan à graine fixe, arbres cuits dans la scène par l'outil, règle du couvert de 3 cases, buissons des bandes étroites, arbres repères dégagés) et `ForestFloor` (`game/world/ground/forest_floor.gd` + `forest_floor.gdshader`, sous-bois, masque L8 1 pixel = 1 case **intégré à la scène**). Écarts §0.2 n° 1, 2 et 7 **résolus** ; la Route 2 n'est plus la première carte à forêt serrée (la Route 1 peinte l'est, `tools/build_route_1.gd`, `test_route_1_painted`).
2. **Assets promus au DA.0** (manifeste, `preparer.py`, scènes `WorldProp`, règles `PaintedPropRules`) : `tree_foret_01` … `tree_foret_08` (et non `tree_foret_1_01`…), `ground_hautes_herbes_jaune_01` (recoloration faite par `preparer.py`), `prop_souche_01`, `relief_rebord_01`, `prop_pierres_01`, `prop_ronces_01`, `prop_tronc_couche_01`, `tree_c_01` / `tree_d_01` / `tree_e_01`, décalcomanies de fleurs ; le tableau « à promouvoir » du §1.2 est donc **fait**. Le T3 ne génère que les nouveaux (série 10).
3. **Sous-bois** : plus de canal B dans `GroundMask` ni de `ground_blend.gdshader` modifié (§2.12 corrigé) : `ForestFloor.create(size, cases_de_forêt)`. Le masque est binaire : l'assombrissement vers le nord passe par la **teinte des arbres en fonction de la rangée** (paramètre à ajouter à `DenseForest`, T4) et, si la capture du T5 le demande, des couleurs du sous-bois réglées par carte (uniformes `dark_color` / `light_color`).
4. **Modèle de l'outil** : `tools/build_route_1.gd` (carte peinte avec forêt serrée, arbres repères, rebord, touffes jaune-vert, `grass_front`) plutôt que `build_route_22.gd`.
5. **Numéro de série** : `tools/art/serie09.py` existe sur `main` (personnages peints de Bourg Palette, DA.4) → la Route 2 est la **série 10** (`serie10.py`, fiche « Série 10 — Route 2 »).
6. **Grille v1 (T0)** par rapport à la v0 : rangée 59 = forêt sauf l'entrée (19..21) — le joueur ne longe plus un bord invisible ; pieds des grands arbres (`G`) et deux clôtures basses (`c`, (13..15, 58) et (25..27, 58)) inscrits dans la grille ; panneaux T1 (22, 56) et T2 (23, 9) en `x` comme T8 ; trajet le plus court **88 pas** (89 en v0 : la case de départ n'est plus comptée), 98 par le chemin sûr. Rien d'autre ne bouge.
7. Sans effet sur le plan : `origin/main` a avancé de `abc12b9` (`tools/test.sh` échoue si un test ne se charge pas) et `58060a0` (capacités au K.O.). `Interaction.Kind` n'a toujours pas `TAKE` ; à ne pas confondre avec `CutsceneStep.Kind.TAKE` (objets retirés du Sac), qui existe.

**Hors périmètre** (dossier 11) : intérieur du poste, garde, `poison_unlocked`, Antidote (J9) ; Route 2 nord (après la forêt) ; son et musique (intentions seulement, `GameMap.music` reste vide) ; mécaniques de FUTUR A / B ; jour / nuit.

---

## 1. Ordre imposé et découpage

| | 8.0 Vue générale | 8.1 La route | 8.2 La vie de la route |
|---|---|---|---|
| Couche nouvelle | plan en aplats reproductible, image Codex | forêt serrée (déjà dans le jeu, §0.3), série 10, carte, raccord, rencontres, porte « À venir » | objets au sol (verbe PRENDRE), objets cachés, PNJ, ambiance, panneaux, FUTUR, objectif |
| Validation | **Kevin, sur l'image** (T1) | **S24** (T6) | **S24** + QA finale du J8 (T8) |

- **(a) Vue générale** (T0 → T1) : la grille fonctionnelle (§1.1) → plan en aplats → Codex (méthode de Bourg Palette et de la Route 1 : plan + vue d'un **autre** lieu comme ancre de style ; joindre un rendu précédent du même lieu le fait recopier). **Validation de Kevin** ; si elle demande un changement de composition, la **grille** est corrigée d'abord, puis le plan, puis l'image (la vue respecte toujours le plan fonctionnel).
- **(b) Assets** (T2 → T3) : liste exacte tirée de la vue validée, série 10 Codex en **lumière neutre (NE)** (les textures du prototype sont déjà promues, §0.3), manifeste, `preparer.py`.
- **(c) Vraie carte** (T5) : `tools/build_route_2.gd` lit la **même grille** et construit `route_2.tscn` directement. Pas de prototype.
- **Deux validations S24** (règle 1) : 8.1 porte le changement lourd (première carte à forêt serrée, performances, raccord) ; 8.2 ajoute la seule brique nouvelle (objet au sol) et le contenu. Aucune validation de sauvegarde isolée : le format ne change pas.
- Pendant l'attente de la validation de l'image (T1) et la génération (T3), l'architecte pose les fondations de code (T4), qui ne dépendent pas de l'art.

### 1.1 Grille fonctionnelle v1 (42 × 60) — `tools/plans/route_2.txt` fait foi

Source unique de la géométrie : plan en aplats, vue générale, outil de construction et critères des tests. Vérifiée par `python3 tools/art/plan_check.py` (règles de `GridWorld` : 4 directions, rebord sauté vers le sud = un pas ; PNJ, Pokémon, Poké Balls, panneaux et clôtures = obstacles) : **trajet le plus court 88 pas** de l'entrée sud à la porte (par H2 ; 98 par le chemin sûr), **6 cases d'herbes obligatoires, toutes dans H3**, H1 et H2 évitables (ensemble), **H2 traversée en 19 pas contre 29 par le chemin sûr** (repères (17, 37) → (8, 27)), **retour porte → entrée 78 pas par le rebord contre 89 sans** ((13, 28) → (10, 38) : 12 contre 21). Fichier sous `tools/` (non importé : rien ne part dans l'APK). Ci-dessous, la v1 recopiée pour lecture ; **en cas d'écart, le fichier gagne**.

Légende : `T` forêt (bloquée) · `.` herbe rase · `=` chemin de terre · `h` hautes herbes · `v` rebord (sauté vers le sud) · `P` emprise du poste · `D` porte du poste · `A` arbre dense (FUTUR A) · `a` sentier peint derrière l'arbre (bloqué) · `B` barrière (FUTUR B) · `b` sentier peint derrière la barrière (bloqué) · `R` grande pierre claire · `S` souche · `G` pied d'un grand arbre repère · `c` clôture basse · `x` buissons, ronces ou panneau (bloqués, végétation basse). Nord en haut ; x = colonne 0..41, y = rangée 0..59.

```text
             x : 0         1         2         3         4
                 012345678901234567890123456789012345678901
 0               TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 1               TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 2               TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 3               TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 4               TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 5               TTTTTTTTTTTTTTTTTPPPPPPPTTTTTTTTTTTTTTTTTT
 6               TTTTTTTTTTTTTTTTTPPPPPPPTTTTTTTTTTTTTTTTTT
 7               TTT..........TTTTPPPPPPPTTTTTTTTTTTTTTTTTT
 8               TTT..........TTTTPPPDPPPTTTTTTTTTTTTTTTTTT
 9               TTT..........TTT.TT===.x.TTTTTTTTTTTTTTTTT
10               TTT..........hhhhhh===...TTTTTTTTTTTTTTTTT
11               TTT....======hhhhhh===...TTTTTTTTTTTTTTTTT
12               TTT....======hhhhhh===...TTTTTTTTTTTTTTTTT
13               TTT..........TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
14               TTT..........TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
15               TTT..........TTTTTTTTTTTTTTTTTTTTTTTTTTTTT
16               TTTTTTT==TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
17               TTTTTTT==TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
18               TTTTTTT==TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
19               aaaaA====TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
20               TTTTTTT==TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
21               TTTTTTT==TTTTTTTTTT.............TTTTTTTTTT
22               TTTTTTT==TTTTTTTTTT.............xxxxxTTTTT
23               TTTTTTT==TTTTTTTTTT.......RRR...x...xTTTTT
24               TTTTTTT==TTTTTTTTTT.......RRR...x...xTTTTT
25               TTTTTTT==TTTTTTTTTT.............x...xTTTTT
26               TTTTTTT==================.......xxxxxTTTTT
27               TTTTTTT==================.......TTTTTTTTTT
28               TTTTTTTTTTT............==.......TTTTTTTTTT
29               TTTTTTTTTTThhhhhhhhhhh.==.......TTTTTTTTTT
30               TTTTTTTTTTThhhhhhhhhhh.==.......TTTTTTTTTT
31               TTTTTTTTTTThhhhhhhhhhh.==TTTTTTTTTTTTTTTTT
32               TTTTTTTTTTThhhhhhhhhhh.==TTTTTTTTTTTTTTTTT
33               TTTTTTTTTTThhhhhhhhhhh.==TTTTTTTTTTTTTTTTT
34               TTTTTTTTTTThhhhhhhhhhh.==TTTTTTTTTTTTTTTTT
35               TTTTTTTTTT.hhhhhhhhhhh.==TTTTTTTTTTTTTTTTT
36               TTTTTTTTTTTTvvvTT......==TTTTTTTTTTTTTTTTT
37               TTTTTTTTT================TTTTTTTTTTTTTTTTT
38               TTTTTTTTT================TTTTTTTTTTTTTTTTT
39               TTTTTTTTT==TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
40               TTTTTTTTT==......TTTTTTTTTTTTTTTTTTTTTTTTT
41               TTTTTTTTT==......TTTTTTTTTTTTTTTTTTTTTTTTT
42               TTTTTTTTT==...S..TTTTTTTTTTTTTTTTxTTTTTTTT
43               TTTTTTTTT==......TT===============Bbbbbbbb
44               TTTTTTTTT==......TT===============Bbbbbbbb
45               TTTTTTTTT==TTTTTT..===....TTTTTTTTTTTTTTTT
46               TTTTTTTTT==TTTTTT..===....TTTTTTTTTTTTTTTT
47               TTTTTTTTT=============....TTTTTTTTTTTTTTTT
48               TTTTTTTTT=============....TTTTTTTTTTTTTTTT
49               TTTTTTTTTTTTTTTTT..===....TTTTTTTTTTTTTTTT
50               TTTTTTTTTTT........===.........TTTTTTTTTTT
51               TTTTTTTTTTT........===.........TTTTTTTTTTT
52               TTTTTTTTTTThhhhh...===.........TTTTTTTTTTT
53               TTTTTTTTTT.hhhhh...===.........TTTTTTTTTTT
54               TTTTTTTTTTThhhhh...===.........TTTTTTTTTTT
55               TTTTTTTTTTThhhhh...===.........TTTTTTTTTTT
56               TTTTTTTTTTT........===x........TTTTTTTTTTT
57               TTTTTTTTTTT........===.........TTTTTTTTTTT
58               TTTTTTTTTTT..ccc.G.===.G.ccc...TTTTTTTTTTT
59               TTTTTTTTTTTTTTTTTTT===TTTTTTTTTTTTTTTTTTTT
                                    ↓ Jadielle (19..21, 59) ↔ (27..29, 1)
```

Lecture du tracé (sud → nord, dossier 11 §5) : **C1** (rangées 50–59) départ dans une large prairie, deux grands arbres de part et d'autre du chemin, **H1** à l'ouest (x 11–15, y 52–55), contournable, la Poké Ball O1 dans une niche au bout (10, 53) ; **carrefour de P1** (y 45–49) : le chemin principal part à l'ouest (y 47–48) puis monte (x 9–10), une branche monte au nord puis file à l'est vers **FUTUR B** (y 43–44, barrière en x 34) ; la clairière de la **souche** (x 11–16, y 40–44 : O3, Rattata) ; couloir bas (y 37–38) ; **H2** (x 11–21, y 29–35) : on y entre par l'est (y 36, x 17–22), **chemin sûr** à l'est (x 23–24) puis retour à l'ouest (y 26–27), ou traversée nord-ouest plus courte ; **rebord** (x 12–14, y 36) : retour direct vers le couloir bas ; Potion O2 dans la niche (10, 35) ; **C2** à l'est : grande pierre claire (x 26–28, y 23–24), P2, Nidoran dans son enclos de buissons (x 33–35, y 23–25) ; montée (x 7–8) avec le **FUTUR A** à l'ouest (arbre dense en (4, 19)) ; **C3** (x 3–12, y 7–15) : première vue sur le poste et la canopée ; **H3** obligatoire (x 13–18, y 10–12, 6 cases à traverser d'ouest en est), Potion O4 dans la niche (16, 9) ; parvis (x 19–24, y 9–12) ; **poste** (x 17–23, y 5–8), porte (20, 8) ; au-dessus, la canopée de la forêt (rangées 0–4).

**C3 près du poste** (défaut, règle 4) : la caméra montre ≈ 5,6 rangées au-dessus du joueur ; pour que le toit du poste apparaisse « au loin » depuis C3 sans contrôle retiré (§14), C3 doit être à ≈ 6 rangées de la façade. « Aux deux tiers » s'entend donc en **temps de parcours** (H2, C2 et la montée viennent avant), pas en rangées.

**Positions de départ** (défauts, ajustables au T7 ; source : section `POSITIONS` de `tools/plans/route_2.txt`, qui ajoute les deux clôtures basses (13..15, 58) et (25..27, 58) et les repères de mesure de `plan_check.py`) :

| Élément | Case(s) | Détail |
|---|---|---|
| Entrée sud (warps, spawns `from_viridian_w/c/e`) | (19, 59), (20, 59), (21, 59) | PUSH ↓ vers Jadielle ; arrivée tournée ↑ |
| Deux grands arbres (C1) | pieds en (17, 58) et (23, 58) | repères « arbres → pierre → forêt » |
| Panneau T1 | (22, 56) | lu depuis (22, 57), tourné ↑ |
| Roucool (s'écarte / s'envole) | (24, 55) `flee`, (25, 53) `fly` | rayon 2 |
| O1 Poké Ball (visible) | (10, 53) | niche au bout de H1 |
| P1 Randonneuse | boucle (23, 48) → (23, 47) → (23, 46) → (23, 47) | pause 1,6 s ; regarde ↑ en haut |
| Souche ; O3 (caché) | souche (14, 42) ; déclencheur (13, 42) | herbe rase |
| Rattata | (16, 41) | `shy flee` rayon 2 + `look` |
| FUTUR B : panneau T8, barrière T9 | panneau (33, 42), lu depuis (33, 43) ↑ ; barrière (34, 43..44), examinée depuis (33, 43..44) → | sentier peint (35..41, 43..44) |
| Rebord | (12..14, 36) | `LEDGE_DOWN` |
| O2 Potion (visible) | (10, 35) | niche au fond de H2 |
| Grande pierre | (26..28, 23..24) | 3 × 2 cases |
| P2 Jeune Dresseur + son Pokémon | (29, 26) + (30, 26) | `look` ; Pokémon `idle_react` |
| Nidoran | (34, 24) | immobile (`look`), enclos de buissons |
| FUTUR A : arbre dense T7 | (4, 19), examiné depuis (5, 19) ← | sentier peint (0..3, 19) |
| O4 Potion (cachée) | (16, 9) | niche au bord nord de H3 (« près des racines ») |
| Panneau T2 « FORÊT DE JADE » | (23, 9) | lu depuis (23, 10) ↑ |
| Porte du poste, spawn `from_forest_gate` | porte (20, 8) ; spawn (20, 9) | STEP_ON ↑ ; retour tourné ↓ |

### 1.2 Assets : liste exacte (T2, 2026-10-07, d'après la vue validée)

**Consigne de Kevin** : le plus petit kit modulaire qui produit la **sensation** de la vue validée dans Godot, sans effet répétitif ; la vue fixe une sensation, pas un inventaire. **Bilan : 2 assets de décor nouveaux + 1 personnage** (4 images Codex en tout : poste, grande pierre, planche de marche et planche d'attente de la Randonneuse), au lieu de 5 à 7 prévus. Planche de contrôle (sans Codex) : `build/art/R2_KIT_v1.png` (`python3 tools/art/serie10.py --planche`), réutilisés, variations rendues, références recadrées des nouveaux, abandons ; 1 case = 48 px, héros à l'échelle.

**A. Réutilisés tels quels** (`assets/`, aucun travail d'art)

| Rôle (vue validée, grille) | Asset(s) |
|---|---|
| Sol : prairie, chemin, amorce de Jadielle | `ground_herbe_01`, `ground_chemin_01` (masque G, sentiers `a` / `b` compris), `ground_paves_01` (masque R, 2 rangées du bas) ; décalcomanies `decal_touffe_*`, `decal_terre_*`, `decal_pave_*` (`BorderDecals`) |
| Forêt serrée (toutes les cases `T`) | `tree_foret_01` … `08` posés par `DenseForest` + sous-bois `ForestFloor` ; buissons des bandes étroites `prop_buisson_a/b_01_bourg` |
| Repères C1 (pieds `G`) | `tree_a_01` (17, 58) et `tree_c_01` (23, 58) : deux essences différentes, pas de symétrie |
| Lisière nord (repères à fondu, couronne au-dessus du chemin) | `tree_b_01` (conifère), `tree_e_01` (grand feuillu sombre) : 3 à 5 en tout, sur des cases de forêt au bord de C3, de la montée et du parvis |
| Bords de chemin, enclos du Nidoran (`x`) | `prop_buisson_a/b/c_01_bourg` (une case chacun, les trois mélangés) |
| Hautes herbes H1, H2, H3 | `ground_hautes_herbes_jaune_01` (+ `_bas` = `grass_front`), deux touffes par case |
| Rebord (12..14, 36) | `relief_rebord_01` ×3 |
| Souche (O3, Rattata) | `prop_souche_01` |
| Panneaux T1, T2, T8 | `prop_panneau_01` ×3 |
| Barrière de FUTUR B | `prop_cloture_piquets_v_01` (blanche, « entretenue »), pied en (34, 44) : emprise (34, 42..44), la case du haut est déjà de la forêt, la clôture sort du bois et ferme le sentier |
| Lisière dense (sur des cases de forêt au bord des clairières du dernier tiers) | `prop_ronces_01`, `prop_tronc_couche_01` (deux ou trois chacun, jamais côte à côte) ; `prop_pierres_01` (traversable) dans C3 |
| Prairies | `decal_fleur_1..8`, de plus en plus rares vers le nord ; au-delà de la rangée 20, seulement `decal_fleur_5` (trèfle) et `_6` (herbe sombre) |
| Personnages, Pokémon | `jeune_dresseur` (P2), `roucool` ×2, `rattata` (+ course), `nidoran_f` (enclos), `nidoran_m` (Pokémon de P2) |

**B. Variations sans nouvel asset** (ce qui évite la répétition)

| Variation | Où, comment | Qui |
|---|---|---|
| **Teinte de la forêt selon la rangée** | valeur × 1,00 jusqu'à la rangée 30, puis décroissance jusqu'à × 0,72 à la rangée 8 et au-dessus ; au nord de la rangée 30, rouge × 0,97, bleu × 1,04 (plus froid) ; s'ajoute aux écarts aléatoires existants | T4 (`DenseForest`, testé), réglages en tête de `build_route_2.gd` |
| **Essences plus froides au nord** | au nord de la rangée 20, poids × 2 pour `tree_foret_04`, `05`, `06` (bleu-vert, conifères), comme la vue | T4 (`DenseForest`, paramètre optionnel, neutre par défaut) |
| **Sous-bois qui gagne la prairie** (dernier tiers) | herbe rase `.` à plus d'une case d'une case ouverte (`= h D v R`, comme `plan_aplats.py --lisiere`) au nord de la rangée 20 : masque `ForestFloor` à 0,45 (taches bruitées), 0,55 au nord de la rangée 12 ; jamais sur le chemin ni à côté | T4 (`ForestFloor.build_mask` accepte une valeur par case), T5 |
| **Ombres de canopée au sol** | images d'ombre existantes (`tree_a_01_shadow`, `tree_b_01_shadow`, `tree_central_01_shadow`) posées à plat sur l'herbe de C3, du parvis et de la montée, matériau d'ombre portée, densité croissante vers le nord, graine fixe | T5 |
| **FUTUR A, l'arbre dense** | `tree_foret_08` à l'échelle 0,55 (≈ 1,6 case de haut), valeur × 0,7, pied sur (4, 19) (case `A`, déjà bloquée par `Ground`) ; examiné depuis (5, 19) | T5 |
| **Buissons** | miroir aléatoire, échelle 0,9–1,12, teinte ± 8 %, plus sombres au nord ; jamais deux fois la même image côte à côte dans l'enclos | T5 |
| **H3 plus sombre** | touffes de H3 `modulate` × 0,86 environ (sous la canopée) | T5 |
| **Grands arbres de lisière** | `tree_b_01` / `tree_e_01` en miroir, assombris comme la forêt de leur rangée | T5 |
| **Clôtures basses de C1** (`c`, 3 cases) | `prop_cloture_piquets_01_court` : 3 des 4 cases de la clôture blanche validée, recadrées à la préparation (coupe au milieu d'un intervalle) ; règle `width 3, depth 1` | T3 (`preparer.py` : option `recadrage`, faite au T2) |
| **Poké Ball au sol** (O1, O2) | `poke_ball_ground` : la Poké Ball de la commode du joueur (`INT_COMMODE_POKEBALL_01`, série 07, lumière NE), détachée par un disque, 40 px de haut ; section `images_objets` du manifeste → `assets/sprites/objects/painted/poke_ball_ground.png` | T3 (`preparer.py` : options `recadrage` + `masque: disque`, faites au T2) |

**C. Nouveaux (série 10, Codex, lumière NE)** : fiches complètes dans `fiches-assets/serie-01-place-jadielle.md` (« Série 10 »)

| Fiche | Rôle que rien d'existant ne tient | Taille / emprise | Couche, ombre | Référence |
|---|---|---|---|---|
| `WORLD_BLDG_POSTE_FORET_01` → `bldg_poste_foret_01` | objectif visuel de toute la route, porte vers la forêt ; **réutilisé au J9** (poste nord) | image 7 cases de large (≈ 4,5 de haut) ; emprise 7 × 4, ancre (20, 8), `open` [(0, 0)] = la porte | entités, `shadow` vrai (bâtiment), `fade` vrai | `REF_R2_POSTE` |
| `WORLD_PROP_GRANDE_PIERRE_01` → `prop_grande_pierre_01` | repère unique de C2 (« arbres → pierre → forêt ») : `prop_rocher_01`, déjà vu trois fois sur la Route 1 et la Route 22 et anguleux, ne serait pas un repère | 3 cases de large (≈ 2,2 de haut) ; emprise 3 × 2, ancre (27, 24) | entités, sans ombre (règle des petits objets), pas de fondu | `REF_R2_GRANDE_PIERRE` |
| `PNJ_RANDONNEUSE` (+ `RANDONNEUSE_ATTENTE`) → `randonneuse` | P1 nommée (« Randonneuse ») : le Voyageur est déjà sur la Route 1, la Dresseuse à Jadielle ; les reprendre ferait le même personnage à deux endroits | 128 px, marche 4 × 4 + attente 4 × 1 | personnage (ellipse du jeu) | `REF_R2_RANDONNEUSE` (tenue seulement) |

**Conditionnels** (prompts prêts dans `serie10.py`, **jamais lancés par défaut** ; seulement si la capture du T5, relue contre la vue, le demande — décision de l'architecte, notée dans `etat-projet.md`) : `WORLD_PROP_ARBRE_DENSE_01` (si FUTUR A en `tree_foret_08` réduit ne se lit pas comme un obstacle), `WORLD_PROP_POKEBALL_SOL_01` (si la Ball recadrée déçoit au sol), `WORLD_GROUND_SOUS_BOIS_01` (planche de 8 décalcomanies de lisière, si le dernier tiers manque de sous-bois ; mutualisable au J9).

**D. Abandonnés** (éléments de la vue volontairement non reproduits)

| Élément de la vue | Pourquoi |
|---|---|
| Randonneuse près de la grande pierre | écart de la vue : P1 reste au premier embranchement (dossier 11) |
| Second rebord sous H2, à droite | arbitrage 14 : un seul rebord |
| Conifères isolés au milieu de C2 et de la prairie est | ils seraient sur des cases praticables : la grille fait foi ; les conifères restent dans la forêt |
| Buissons à fleurs orange (C3, FUTUR B) | détail décoratif ; `prop_buisson_b_01_bourg` (fleurs roses) suffit, pas d'asset pour une couleur |
| Barrière blanche dessinée de face (FUTUR B) | triche de la vue (le sentier est est-ouest, la barrière est nord-sud) : `prop_cloture_piquets_v_01` |
| Clôtures blanches à lisses de C1 | les piquets blancs recadrés donnent la même lecture (« Jadielle encore perceptible ») |
| Planche d'arbres de lisière sombres (`WORLD_TREE_FORET_PLANCHE_C`, conditionnel du T0) | teinte par rangée + poids des essences froides font la lisière |
| Barrière dédiée (`WORLD_PROP_BARRIERE_SENTIER_01`, conditionnel du T0) | `prop_cloture_piquets_v_01` |
| `tree_automne_01` | identité de la Route 1 : pas réutilisé ici |

**Règles `PaintedPropRules` prévues** (T3, avec `build_painted_props.gd --nouveaux`) : `bldg_poste_foret_01` `{shadow: true, width: 7, depth: 4, fade: true, open: [Vector2i(0, 0)]}` ; `prop_grande_pierre_01` `{width: 3, depth: 2}` ; `prop_cloture_piquets_01_court` `{width: 3, depth: 1}`. La Ball n'est pas un objet du catalogue (`test_painted_props` exige une scène par objet) : c'est une image (`images_objets`) lue par `build_character_frames.gd` (genre « objet fixe », T4).

Poids attendu : < 2 Mo de PNG ajoutés (poste ≈ 670 × 430, pierre ≈ 290 × 210, deux planches de personnage, une Ball, une clôture).

### 1.3 Fiche et prompt de la vue générale (écrits au T0, lancés au T1)

Prompt : `tools/art/prompts/CONCEPT_ROUTE2_VUE_GENERALE_r1.txt` (le brouillon de ce plan, complété : légende des fleurs, des clôtures, des sentiers fermés et des trois panneaux ; placement de la vie d'après la grille ; « sous-bois sombre » retiré de l'ancre de style, invisible sur la vue de la Route 1). Images jointes : le plan en aplats `build/art/PLAN_ROUTE2_v1.png` (`python3 tools/art/plan_aplats.py`) et **la vue de la Route 1** comme ancre de style (un autre lieu ; jamais un rendu précédent de la Route 2). Lancement, depuis la copie qui contient le plan :

```bash
python3 tools/art/plan_check.py && python3 tools/art/plan_aplats.py
tools/art/generer.sh CONCEPT_ROUTE2_VUE_GENERALE_r1 tools/art/prompts/CONCEPT_ROUTE2_VUE_GENERALE_r1.txt build/art/PLAN_ROUTE2_v1.png docs/design/reference/route-1-vue-generale-v1.png
```

Trois essais au plus avant de revenir à Kevin (r2, r3 : nouveau fichier de prompt, même grille).

Couleurs du plan en aplats (`tools/art/plan_aplats.py`, T0) : celles du plan de la Route 1 (`reference/route-1-plan-v1.png`) pour `T . = h v`, plus gris-bleu (poste), gris clair (grande pierre), brun (souche, rebord), vert sombre (arbre dense, buissons), blanc (barrière), ocre (panneaux), points rouge et blanc (Poké Balls), disques verts (grands arbres) ; sentiers `a` / `b` en beige atténué. 1 case = 24 px (1008 × 1440), centré sur un fond de forêt 1024 × 1536 ; chemins et sentiers qui sortent de la carte prolongés jusqu'au bord ; fleurs roses semées dans les prairies, de plus en plus rares vers le nord (graine fixe : même grille → même image) ; personnages et objets cachés non dessinés (comme au plan de la Route 1).

---

## 2. Conception technique par besoin

### 2.1 Raccord exact avec Jadielle (Jadielle inchangée)

- **Route 2** : chemin de 3 cases en (19..21, 59), dernière rangée. Trois `WarpPoint` **PUSH ↓** sur ces cases → `viridian_city`, spawns `from_route_2_w/c/e`, arrivée tournée ↓. Spawns `from_viridian_w/c/e` = les mêmes cases, arrivée tournée ↑ (comme le bord nord de la Route 1 et le bord sud de Jadielle : le joueur arrive sur la case du passage ; pousser vers le bas le renvoie). Les deux rangées du bas : pavés déchaussés qui cèdent à la terre (masque R puis G) et une ou deux clôtures courtes : la continuité de la rue nord de Jadielle (dossier 11 §4).
- **Jadielle** : seuls changent les trois warps nord et leurs spawns de retour :
  - `Route2SoonW/C/E` deviennent `Route2W/C/E` : `coming_soon` vide, `target_map = route_2`, `target_spawn = from_viridian_w/c/e`, `arrival_facing = ↑` (PUSH ↑ inchangé, rangée 0 toujours bloquée) ;
  - spawns `route_2_soon_*` (rangée 3) remplacés par `from_route_2_w/c/e` en (27..29, 1).
  - Mise en œuvre : `build_viridian_city.gd` reçoit ces valeurs (la source reste juste) **et** `viridian_city.tscn` est modifié **à la main sur ces six nœuds seulement** (pas de reconstruction : les `unique_id` et la graine réécriraient 9 000 lignes). CA : `git diff --stat` de la scène ≤ 40 lignes ; un test compare les warps et spawns nord de la scène aux constantes de l'outil (lues dans le fichier, pas importées).
- `test_map_links` (cibles et spawns de tous les warps) couvre l'aller-retour ; `test_coming_soon` est **réécrit** sur la porte du poste (§2.2) ; `tools/capture_coming_soon.gd` aussi.

### 2.2 Façade du poste et porte → « FORÊT DE JADE — À venir »

- Prop peint `bldg_poste_foret_01` (règle d'emprise : `width` 7, `depth` 4, `shadow` vrai, `fade` vrai, `open` : `[Vector2i(0, 0)]` = la porte), ancre (20, 8).
- `WarpPoint` « ForestGateSoon » en (20, 8) : **STEP_ON ↑**, `coming_soon = "Forêt de Jade"`, `target_spawn = from_forest_gate` (20, 9), `arrival_facing = ↓`. Le routeur montre « FORÊT DE JADE — À venir » (le libellé passe en majuscules : test explicite du « Ê »), ramène le joueur devant la porte, rien n'est sauvegardé, aucune carte `viridian_forest` découverte. En release, le passage est inerte (comportement existant).
- **J9** : seul ce warp change (`coming_soon` vide, carte du poste, spawn) ; `from_forest_gate` reste le point de retour depuis le poste. Constante `FOREST_GATE_*` en tête de l'outil pour que ce soit une ligne.

### 2.3 Objets visibles au sol (arbitrage 2) : briques existantes + un asset

Un objet visible est **une entrée du fichier de PNJ** de la carte, avec l'apparence de la Poké Ball au sol, le verbe **PRENDRE**, et une présence conditionnée par son drapeau. Aucun nœud ni système nouveau dans la carte.

```json
"route_2_ball_1": {
	"cell": [10, 53], "facing": "down", "sprite": "object/poke_ball_ground",
	"dialogue": "route_2_ball_1", "verb": "take", "turn_to_player": false,
	"unless": ["got_route_2_item_1"]
}
```
- `data/dialogues/route_2.json` : `"route_2_ball_1": { "cutscene": "route_2_item_1" }` (variante sans page : pas de boîte, la scène part aussitôt — comportement existant de `DialogueRunner`).
- `data/cutscenes/route_2.json` : `"route_2_item_1": { "variants": [ { "unless": ["got_route_2_item_1"], "steps": [ { "despawn": "route_2_ball_1" }, { "give": "poke_ball", "count": 1, "found": true }, { "set": ["got_route_2_item_1"] } ] } ] }` : fondu de 0,2 s (`DESPAWN_FADE`), objet au Sac, journal des objets trouvés, toast standard « Poké Ball ×1 — Ajoutée au Sac », drapeau. Au prochain chargement, `unless` le retire.
- **Code (petit, T4)** :
  - `Interaction.Kind.TAKE` ajouté **en fin d'enum** ; `kind_name` → `&"take"`, `kind_from_name("take")` ; le bouton contextuel l'affiche déjà (« PRENDRE », `take.svg`) ;
  - `NpcRoster` accepte `"verb": "take"` (toujours pas `meet`) ;
  - `CharacterLook` : préfixe `object/` → `assets/sprites/objects/painted/<id>_frames.tres` (comme `pokemon/`), sans apparence provisoire (absent → apparence générique, comme aujourd'hui) ;
  - `build_character_frames.gd` : genre « objet fixe » (une image → `idle_down/left/right/up`, une image chacune).
- L'objet occupe sa case (on le prend de face, comme dans Rouge/Bleu). Son ombre est l'ellipse des PNJ ; si elle est trop grande pour la Ball (capture du T7), valeur par défaut : la garder (petite remarque de rendu → « Reportés »).
- O2 (Potion) utilise la **même apparence** (Q-1) ; seuls l'identifiant, l'objet donné et le drapeau changent.

### 2.4 Objets cachés (O3, O4) : exactement la Potion de la Route 1

`EventTriggerPoint` d'une case (direction ZERO) sur une case d'**herbe rase** → scène `route_2_item_3` / `_4` : `dialogue` (`route_2_item_3_found` : narration T10 ; `_4` : T11), `give … found: true`, `set`. Le toast suit la narration ; pas de deuxième bulle (dossier 11 §11). Rejouer la case après : variante vide, rien.

### 2.5 Rebord (arbitrage 14)

Trois cases `LEDGE_DOWN` en (12..14, 36) dans `Ground` (logique) + `relief_rebord_01` posé trois fois dans `GroundDecals` (règle : `layer` sol, `traversable` vrai, pas d'ombre). Saut existant. Critères vérifiés par recherche de chemin dans `test_route_2` (§3, T5) : la porte reste atteignable depuis l'entrée sud ; le rebord ne se monte pas ; il raccourcit le retour (19 pas contre 29 dans la grille v0).

### 2.6 PNJ, routines, Pokémon d'ambiance (dossier 11 §9, §10) — `data/npcs/route_2.json`

| Id | Sprite | Comportement |
|---|---|---|
| `hiker` (P1) | `hiker` (nouveau, peint) | `route` verticale de 3 cases (§1.1), pause 1,6 s ; dialogue `route_2_hiker` (T3 puis T4) |
| `youngster` (P2) | `youngster` (existant) | `look` (vers son Pokémon et vers le sud) ; dialogue `route_2_youngster` (T5 puis T6) ; **aucune** scène de combat, aucun champ de vision |
| `youngster_pokemon` | `pokemon/nidoran_m` (défaut) | `idle_react` 5 s, sans dialogue |
| `pidgey_1`, `pidgey_2` | `pokemon/pidgey` | `shy` `flee` (s'écarte de 3 pas puis s'efface : comportement existant) et `shy` `fly` |
| `rattata` | `pokemon/rattata` | `shy` `flee` rayon 2 (course, puis **fondu**) + `look` (gauche / bas / droite, 1,2 s) pour « fouiller » |
| `nidoran` | `pokemon/nidoran_f` (défaut) | `look` lent (6 s), aucune réaction ; inaccessible (enclos) |
| `route_2_ball_1`, `route_2_ball_2` | `object/poke_ball_ground` | §2.3 |

- **Rattata (arbitrage 5)** : la fuite existante (`AmbientRules.flee_path`, glouton haut / bas / gauche / droite) le fait courir 3 pas puis s'effacer. Le T7 place sa case pour que la fuite finisse **derrière la végétation** (niche d'une case, buissons posés sur les cases de forêt au sud de la niche, qui passent devant lui par le tri des pieds). **Repli** si le chemin ne s'y prête pas sans nouveau code : petite animation sur place (`idle_react`, sans `shy`). Pas de nouveau système dans les deux cas.
- Noms affichés : `speaker` « Randonneuse », « Jeune Dresseur » (T16).
- « Première fois / ensuite » : variantes à drapeau `route_2_hiker_talked`, `route_2_youngster_talked` (modèle du vieil homme de Jadielle) — **Q-2**.
- Les cases des PNJ et de leurs routines sont lues par l'outil de construction (pas d'arbre dessus ni à côté, comme `build_route_22.gd`).

### 2.7 FUTUR A et FUTUR B (arbitrage 11, §6)

- **A** : `tree_foret_08` réduit (× 0,55, assombri, §1.2 B) au pied de (4, 19), case `A` déjà bloquée par `Ground` (repli : asset conditionnel `WORLD_PROP_ARBRE_DENSE_01`) ; `InteractPoint` sur sa case, `facing` ←, dialogue `route_2_dense_tree` (narration T7) ; sentier peint (masque G) en (0..3, 19), cases bloquées (`Ground` forêt), aucun warp.
- **B** : barrière `prop_cloture_piquets_v_01` au pied de (34, 44) (emprise (34, 42..44), la case du haut est de la forêt), solide ; panneau `prop_panneau_01` en (33, 42) ; `InteractPoint` panneau (`facing` ↑, `route_2_closed_sign`, T8 « ACCÈS FERMÉ / Travaux sur le sentier. ») et barrière (2 cases, `facing` →, `route_2_closed_gate`, T9) ; sentier peint (35..41, 43..44) bloqué.
- Aucun état, aucun drapeau.

### 2.8 Panneaux (arbitrage 7)

`prop_panneau_01` + `InteractPoint` (`facing` ↑) : `route_2_sign` → une page « ROUTE 2\nJadielle — Forêt de Jade » (T1 ; la boîte n'a pas de gras : le nom en majuscules suffit, comme « BOURG PALETTE ») ; `route_2_forest_sign` → « FORÊT DE JADE » (T2). Format de `sign_pallet_town`, sans `speaker`.

### 2.9 Rencontres (§8) — `data/encounters/route_2.json`

```json
{ "route_2_grass": { "maps": ["route_2"], "terrain": "grass", "rate": 25,
  "ramp": { "from_step": 15, "max_steps": 20 },
  "slots": [
    { "species": "pidgey", "levels": [4, 6], "weight": 35 },
    { "species": "rattata", "levels": [4, 6], "weight": 30 },
    { "species": "nidoran_f", "levels": [4, 6], "weight": 12 },
    { "species": "nidoran_m", "levels": [4, 6], "weight": 12 },
    { "species": "spearow", "levels": [5, 6], "weight": 8 },
    { "species": "mankey", "levels": [5, 6], "weight": 3 } ] } }
```
Une table pour H1, H2, H3. **Rythme de la Route 1 gardé** (`rate` 25, rampe 15 → 20) : avec 6 cases obligatoires, ≈ 82 % de chances d'une rencontre dans H3 (1 − 0,75⁶) ; le T6 le mesure avec `tools/simulate_grass_pacing.gd` (étendu à `route_2`) et sur S24. Tests : poids = 100, aucune espèce Insecte ni Pikachu, niveaux, espèces connues de `PokemonData`.

### 2.10 Objectif « continuer vers le nord. » (arbitrage 6)

En **tête** de `data/story/objectives.json` (la première entrée valide l'emporte) : `{ "id": "go_north", "text": "continuer vers le nord.", "if": ["pokedex_activated"] }`. Pas de `unless` au J8 ; le J9 l'ajoute à l'entrée de la forêt. `test_objective_library` : « après l'activation, plus rien » devient « après l'activation : continuer vers le nord. ».

### 2.11 Zone `route_2` et carte

- `zones.json` : `"route_2": { "name": "Route 2", "kind": "route", "maps": ["route_2"], "subtitle": "Jadielle — Forêt de Jade", "description": "Un chemin bordé de prairies qui s'enfonce peu à peu sous les arbres." }` (T14 ; sous-titre = T1, comme la Route 1).
- `GameMap` : `map_id = route_2`, `display_name = "Route 2"`, `region = "Jadielle — Forêt de Jade"`, `size = (42, 60)`, `light_profile = golden_hour`, `music` vide, `level_rows` vide.
- Découverte : `GameState.discovered_maps` à l'arrivée (existant) ; Carte, Pokédex (habitats), écran Dresseur suivent sans code.
- Défaite : réveil au dernier point de repos (existant, aucun texte).

### 2.12 Lumière unique et ambiance par le décor (arbitrage 3) ; forêt serrée dans le jeu

- Un seul profil, `golden_hour`, aucune variation dynamique. Le nord est plus sombre **par le décor construit une fois par l'outil** :
  - **sous-bois** : `ForestFloor` existant (§0.3), masque des cases de forêt ; couleurs réglables par carte si la capture du T5 le demande ;
  - **arbres de forêt** `tree_foret_01..08` par `DenseForest` (graine fixe), **plus froids et plus sombres vers le nord** : teinte fonction de la rangée (petit ajout à `DenseForest`, T4, testé), grands arbres `tree_c/d/e` en lisière ; le nombre de cases de prairie visibles diminue vers le nord (grille).
- Règle du prototype gardée : un arbre de forêt ne pousse que si les cases couvertes par son feuillage (3 au-dessus du pied) sont aussi de la forêt (rien ne cache un chemin) ; bandes trop étroites garnies de buissons.
- **Performance** : les arbres de forêt ont `fade` faux (ils ne couvrent jamais une case praticable) et pas d'ombre portée (ombre de contact seulement, comme au prototype) ; aucun `_process` par arbre. Budget de la scène (défaut) : ≤ 3 000 nœuds, changement de carte Jadielle → Route 2 au plus 1,5 × celui de Jadielle (`SceneRouter : <carte> en N ms`) ; si dépassé, les arbres de forêt passent en `Sprite2D` simples (sans scène `WorldProp`), voir §4.

### 2.13 Drapeaux et sauvegarde

| Drapeau | Posé par |
|---|---|
| `got_route_2_item_1` … `_4` | ramassage de O1 à O4 (un par objet) |
| `route_2_hiker_talked`, `route_2_youngster_talked` | première réplique de P1 / P2 (Q-2) |

« Route 2 découverte » = `discovered_maps` (existant) ; espèces vues / capturées = Pokédex (existant) ; objets trouvés = `found_items` (existant). **Format de sauvegarde inchangé** (`SaveSystem.VERSION` = 3) : seuls des noms de drapeaux nouveaux dans un tableau existant. Rien pour l'ambiance, FUTUR A / B, C3, les herbes visitées.

### 2.14 Textes et données (règle 7)

Tous les textes T1–T16 dans `data/` (dialogues, zones, objectifs) **après validation de Kevin** (`test_no_draft_in_data` interdit les brouillons) ; ajoutés au lot validé `docs/design/textes/` ; `test_dialogue_data` (« mot pour mot ») les couvre. Libellé « Forêt de Jade » de la porte : constante de l'outil de construction (texte de développement, comme « Route 2 » aujourd'hui).

---

## 3. Tâches

Branche d'intégration `jalon-08` depuis `main`, dans une copie dédiée ; une branche par tâche ; jamais de `pkill`.

#### T0 — architecte : alignement, grille, plan en aplats, prompt (8.0)
- Aligner ce plan sur le code du moment (§0) ; `tools/plans/route_2.txt` (grille §1.1, positions §1.1 en fin de fichier) ; `tools/art/plan_aplats.py` → `build/art/PLAN_ROUTE2_v1.png` ; `tools/art/plan_check.py` (recherche de chemin : mêmes critères que `test_route_2`) ; `tools/art/prompts/CONCEPT_ROUTE2_VUE_GENERALE_r1.txt` (§1.3) ; en-tête « Série 10 — Route 2 » (fait ; « 09 » est pris, §0.3) dans `fiches-assets/serie-01-place-jadielle.md`.
- **CA** : `plan_check.py` : porte atteignable, 5 ≤ cases d'herbes obligatoires ≤ 7 et toutes dans H3, H1 et H2 évitables, H2 plus courte que le chemin sûr, rebord = raccourci de retour, entrée sud = 3 cases en x 19–21 ; plan relu (image) ; aucun fichier de `game/` touché.

#### T1 — constructeur-monde (Mac, Codex) : la vue générale → **validation de Kevin (8.0)**
- Lancer `generer.sh` (§1.3), 3 essais au plus ; relire contre la grille (chemins à angles droits, zones, poste, repères). Présenter à Kevin.
- Après validation : `docs/design/reference/route-2-vue-generale-v1.png` + `route-2-plan-v1.png`, section « Vue générale peinte v1 » du dossier 11 (fichiers, prompt, écarts retenus), `etat-projet.md`.
- **CA** : Kevin a validé l'image ; tout changement de composition demandé est d'abord reporté dans la grille (T0 rejoué).

#### T2 — architecte : liste exacte des assets (après T1)
- Fiche « Série 10 » complète (une fiche par asset nouveau : taille en cases, emprise, couche, ombre, références recadrées `REF_R2_*` de la vue validée) ; `tools/art/serie10.py` ; entrées du manifeste prévues (nouveaux + promus, §1.2) ; règles `PaintedPropRules` prévues.
- **CA** : chaque élément visible de la vue validée a un asset (existant, promu ou nouveau) ou est explicitement abandonné ; liste relue par Kevin en même temps que la vue s'il le souhaite (non bloquant).
- **Fait (2026-10-07)** : §1.2 (réutilisés, variations, 2 décors + 1 personnage nouveaux, 3 conditionnels, abandons) ; fiche « Série 10 » ; `tools/art/serie10.py` (références `--refs`, génération, `--manifeste`, planche `--planche`) ; prompt d'attente `tools/art/attente/prompts/RANDONNEUSE_ATTENTE.txt` ; `preparer.py` : options `recadrage` / `masque: disque` des objets et section `images_objets` (relancé : aucune image changée) ; planche `build/art/R2_KIT_v1.png` relue.

#### T3 — constructeur-monde (Mac, Codex) : série 10 (8.1)
- Génération : **4 images**, §1.2 C (lumière NE ; ancres `WORLD_PROP_SOUCHE_01` + `WORLD_TREE_A_01`, plus `WORLD_BLDG_MAISON_B_01` pour le poste) ; les conditionnels **ne sont pas lancés**. Depuis la copie du J8, les sources étant dans le checkout principal :
  ```bash
  ART=/Users/kevinyankam/dev/kanto-2026/build/art python3 tools/art/serie10.py
  ```
  (recadre d'abord les `REF_R2_*` ; trois générations à la fois ; la planche d'attente part quand la marche existe ; une image déjà là n'est pas refaite ; correction = la supprimer ou passer en `_r2`).
- Relecture contre la vue et la planche `R2_KIT_v1.png`, puis : `python3 tools/art/serie10.py --manifeste` (entrées du §1.2 en fin de sections : 3 objets, 1 image d'objet, 1 personnage, 1 attente), `python3 tools/art/preparer.py --source /Users/kevinyankam/dev/kanto-2026/build/art` (deux fois), `--import`, règles `PaintedPropRules` du §1.2, `build_painted_props.gd --nouveaux`, `build_character_frames.gd` (Randonneuse : marche + attente ; Ball : objet fixe, genre du T4).
- **CA** : `preparer.py` relancé deux fois ne change aucun fichier ; `test_painted_props` passe (une règle par nouvel identifiant) ; planche contact `build/captures/jalon08_assets/` relue ; journal de la série 10 dans la fiche.

#### T4 — architecte : fondations (en parallèle de T1–T3, après validation du plan et des textes)
- Code : `Interaction.Kind.TAKE` ; `NpcRoster` verbe `take` ; `CharacterLook` préfixe `object/` ; teinte des arbres de `DenseForest` fonction de la rangée (assombrissement et refroidissement vers le nord, §1.2 B) et poids optionnels des essences au nord ; `ForestFloor.build_mask` avec une valeur par case (sous-bois partiel sur l'herbe éloignée du chemin, §1.2 B) ; `build_character_frames.gd` objet fixe. **Avant** : fusionner `main` (DA.0, DA.1).
- Données : `data/encounters/route_2.json`, `zones.json`, `objectives.json`, `data/dialogues/route_2.json`, `data/cutscenes/route_2.json`, `data/npcs/route_2.json` (cases de la grille), `tools/debug_start/route_2.json` (partie après l'activation du Pokédex, équipe Nv. 8–10, spawn `from_viridian_c`).
- Tests : `test_interaction` (TAKE, nom, ordre de l'enum), `test_npc_roster` (take accepté, meet refusé), `test_character_look` (`object/`), `test_dense_forest` (teinte selon la rangée et poids des essences, sans effet quand les réglages sont neutres), `test_forest_floor` (valeurs du masque), `test_encounter_library` (table de la Route 2 : poids 100, aucun Insecte ni Pikachu), `test_zone_library`, `test_objective_library`, `test_dialogue_data`, `test_cutscene_library` (scènes des objets : `despawn` d'un PNJ du fichier, `give found`, `set`).
- **CA** : `tools/test.sh` vert, import propre ; aucune carte touchée.
- **Fait (2026-10-07, branche `j8-t4-fondations`)** : code, données et tests ci-dessus ; 2928 tests (2925 verts, 3 en attente : carte du T5, image du T3), import propre, aucune carte ni asset touchés. API : `DenseForest.plan(forest, size, landmarks, seed, shade)` avec `DenseForest.Shade` (`from_row`, `full_row`, `value`, `red`, `blue`, `weights_row`, `weights`) et `DenseForest.row_tint(shade, row)` ; `ForestFloor.build_mask` : valeur nombre par case dans un dictionnaire. Données réelles des scènes testées dans `tests/integration/test_cutscene_data.gd` (pas `test_cutscene_library`) ; `test_parcel_scene` et `test_debug_start` mis à jour aussi. Défauts et gardes à retirer au T5 : `etat-projet.md` (« T4 fait »).

#### T5 — constructeur-monde : la carte (8.1)
- `tools/build_route_2.gd` (modèle `build_route_1.gd`, carte peinte à forêt serrée, §0.3) lit `tools/plans/route_2.txt` (même lecteur que `tools/art/plan_grille.py`) : `Ground` logique (forêt, herbe, chemin, hautes herbes, rebord), `PaintedGround` + masque, sous-bois (`ForestFloor`), décalcomanies, forêt serrée (graine fixe), grands arbres repères, hautes herbes jaune-vert (deux touffes par case), relief du rebord, poste et warp « À venir », panneaux et FUTUR A / B (props et points d'examen), spawns, warps sud ; cases des PNJ réservées (lues dans `data/npcs/route_2.json`).
- Jadielle : §2.1 (outil + six nœuds à la main).
- Tests : **`test_route_2`** (taille, `light_profile`, warps et spawns, recherche de chemin : critères du T0 sur la **vraie grille** de la scène, rebord, porte « À venir », cellules des objets cachés sur herbe rase, aucune case praticable sous une cime d'arbre de forêt, nombre de nœuds ≤ 3 000), `test_viridian_city` (warps nord vers `route_2`, spawns `from_route_2_*`, diff limité), `test_map_links`, `test_coming_soon` réécrit (porte du poste ; « FORÊT DE JADE — À venir » ; retour devant la porte tourné ↓ ; rien de sauvegardé ; aucune carte `viridian_forest`), `test_encounter_director` (rencontre dans H1, H2, H3) ; `tools/capture_route_2.gd` (C1, H2 et rebord, C2, C3 avec le poste, porte).
- **CA** : tests verts, import propre, captures 2340 × 1080 relues contre la vue générale ; `[perf]` sur Mac relevé.

#### T6 — qa-mobile : validation 8.1 sur S24 → Kevin
- Partie réelle de Kevin (sortie nord de Jadielle) **et** départ `route_2` ; traversée directe et attentive chronométrées (dossier 11 §3) ; rythme des rencontres (`simulate_grass_pacing` + terrain) ; rebord ; porte ; retour à Jadielle par les trois cases ; fps (moyenne ≥ 58, creux), mémoire des textures, temps de changement de carte, taille de l'APK.
- **CA** : rapport `build/qa/jalon08_t6/`, aucune erreur dans les logs ; validation de Kevin. Remarques de rendu → « Reportés ».

#### T7 — constructeur-monde (+ ui-mobile pour la relecture des écrans) : la vie de la route (8.2)
- PNJ, ambiance, objets visibles et cachés, panneaux, textes des FUTUR, objectif, description de zone (données du T4 finalisées sur la carte reconstruite) ; Randonneuse peinte ; placement du Rattata (fuite derrière la végétation ou repli §2.6).
- ui-mobile : relecture du bouton PRENDRE, des toasts, de la Carte (zone Route 2, sous-titre, description) et du Pokédex (habitat « Route 2 ») ; aucune vue nouvelle.
- Tests : `test_route_2_items` (prendre O1 : Sac +1, `found_items`, drapeau, PNJ retiré tout de suite **et** au rechargement ; O3 : narration puis toast, une seule fois), `test_route_2` étendu (aucune scène de combat ni déclencheur près de P2, routines hors hautes herbes et hors du chemin principal, Nidoran inaccessible, cases d'objets atteignables), `test_ambient_rules` étendu (fuite du Rattata finie sur sa niche, grille de la vraie carte), `test_rest_pose` si besoin.
- **CA** : tests verts, captures relues (Ball au sol lisible, Randonneuse, Rattata derrière la végétation).

#### T8 — qa-mobile : validation 8.2 et QA finale du J8 sur S24 → Kevin
- Vraie partie, sans drapeau de débogage : les quatre objets, P1 / P2 (première fois, ensuite, après rechargement), les trois tableaux d'ambiance, FUTUR A / B, objectif dans le menu, Carte, sauvegarde et reprise sur la Route 2 (objets ramassés absents, format v3).
- **CA** : rapport `build/qa/jalon08_t8/` ; validation de Kevin ; fusion de `jalon-08` dans `main`.

#### T9 — architecte : clôture
- `etat-projet.md`, lot de textes, passation au J9 (warp du poste, `unless` de l'objectif, façade réutilisée, forêt serrée disponible dans `game/`).

**Parallélisme** : T4 ∥ T1–T3 ; préparation des données du T7 ∥ T6 (sans fusion avant la validation de 8.1). **Une seule** session S24 par sous-jalon (T6, T8).

---

## 4. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Conflits avec d'autres branches** : préparation du J9 (dossier 10, étude de DA de la forêt : `tools/art/`, `manifeste.json`, fiche des séries), Pokédex (T5), `etat-projet.md` toujours | conflits de fusion, art écrasé | regarder les branches ouvertes avant chaque fusion (copie d'intégration dédiée) ; série 10 **ajoutée en fin** de manifeste et de fiche ; Jadielle modifiée sur six nœuds seulement ; `zones.json` / `objectives.json` : une entrée chacun |
| **Poids et nombre de nœuds** (forêt serrée sur 1 700 cases bloquées, ≈ 1 000 arbres) | chargement lent, fps | `fade` faux et pas d'ombre portée sur la forêt ; budget ≤ 3 000 nœuds testé ; repli `Sprite2D` simples ; mesures au T5 (Mac) puis T6 (S24) ; textures déjà mesurées au prototype (≈ 36,5 Mo, 60 fps) |
| ~~**Recoloration et découpe hors pipeline** non reproductibles~~ | — | **levé** : faites par `preparer.py` au DA.0 (§0.3) |
| **Rythme des rencontres** (rampe calée sur la Route 1, H3 obligatoire) | trop ou pas assez de combats avant la forêt | simulation (T6) + S24 ; ajuster la **grille** (taille de H3, H2) avant de toucher au taux |
| **Raccord** (Jadielle générée, `unique_id`) | diff massif, régressions dans Jadielle | modification à la main de six nœuds, test de cohérence outil ↔ scène, `test_viridian_city` complet |
| **Vue générale qui s'écarte du plan** (Codex ajoute des courbes, de l'eau, des bâtiments) | composition invalide | interdits explicites, 3 essais, la grille fait foi (règle 10) |
| **C3 et caméra** : la vue « au loin » n'existe qu'à ≈ 5,6 rangées | moment C3 raté | C3 placé près du poste (§1.1), vérifié par capture |
| **Fuite du Rattata** qui ne finit pas derrière la végétation | effet raté | placement + test ; repli de l'arbitrage 5 |
| **Objet au sol en PNJ** : ellipse d'ombre trop grande, objet « Parler » par erreur | lisibilité | verbe TAKE testé ; ombre : remarque de rendu reportée |

---

## 5. Questions pour Kevin

> **Validé par Kevin (2026-10-06)** : textes T1–T16 du dossier 11 tels quels ; **Q-1 et Q-2 = défauts** (Potion au sol avec l'aspect d'une Poké Ball ; deux drapeaux pour « première fois / ensuite » de P1 et P2) ; **plan validé, lancement du sous-jalon 8.0** (vue générale peinte) ; le reste attend la validation de la vue.

Vraies questions (une valeur par défaut permet de continuer) :

- **Q-1 — Aspect des objets visibles.** La Potion O2 posée au sol a-t-elle le **même aspect que la Poké Ball O1** (une Poké Ball, comme dans Rouge/Bleu ; « un asset peint ») ? *Défaut : oui, une seule image ; le toast dit « Potion ×1 ».* L'alternative est une Potion peinte au sol (deuxième asset).
- **Q-2 — « Première fois / ensuite » de P1 et P2.** Le dossier 11 §17 dit de ne pas mémoriser les dialogues lus, mais la seule manière existante est un drapeau sauvegardé (comme le vieil homme de Jadielle). *Défaut : deux drapeaux (`route_2_hiker_talked`, `route_2_youngster_talked`), format inchangé.* L'alternative (première réplique rejouée à chaque chargement de la carte) demanderait un petit mécanisme nouveau de variantes non sauvegardées.

Valeurs par défaut notées (règle 4), à corriger d'un mot si besoin :

| Sujet | Défaut |
|---|---|
| Validations | 8.0 sur l'image, puis **deux** sessions S24 (8.1 la route, 8.2 la vie) |
| H3 | 6 cases obligatoires (traversée ouest → est, toutes dans H3) |
| C3 | ≈ 6 rangées sous la façade du poste (contrainte de caméra) ; « deux tiers » en temps |
| Verbe des objets visibles | PRENDRE (déjà prévu par le bouton contextuel) |
| Roucool qui « s'écarte » | fuite existante : 3 pas puis fondu |
| Rattata qui « fouille » | `look` (gauche / bas / droite) ; repli `idle_react` sur place |
| Nidoran d'ambiance | ♀ (à confirmer sur la vue générale) |
| P2 | modèle peint `youngster` existant (déjà vu sur la Route 22 et devant l'Arène), avec un Nidoran ♂ |
| Randonneuse | nouvelle planche peinte ; tenue = celle de la vue générale validée |
| Barrière de FUTUR B | `prop_cloture_piquets_v_01` (T2) ; aucun asset dédié |
| Kit de la série 10 (T2) | 2 décors (poste, grande pierre) + Randonneuse ; FUTUR A = `tree_foret_08` × 0,55 assombri ; Ball = Poké Ball de la commode recadrée (40 px) ; clôtures de C1 = piquets blancs recadrés à 3 cases ; 3 conditionnels décidés sur la capture du T5 |
| Lisière (T2) | forêt × 1,00 → × 0,72 de la rangée 30 à la rangée 8, plus froide ; essences bleu-vert × 2 au nord de la rangée 20 ; sous-bois du masque à 0,45 / 0,55 sur l'herbe éloignée du chemin au nord des rangées 20 / 12 ; H3 × 0,86 |
| Panneau T1 | une page « ROUTE 2 » + « Jadielle — Forêt de Jade » (pas de gras dans la boîte) |
| Sous-titre de zone | « Jadielle — Forêt de Jade » (comme la Route 1) |
| Raccord | pavés déchaussés sur 2 rangées puis terre ; une ou deux clôtures courtes |
| Budget | ≤ 3 000 nœuds ; changement de carte ≤ 1,5 × Jadielle ; moyenne ≥ 58 fps |
| Façade du poste | réutilisée pour le poste nord au J9 |
