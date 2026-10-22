# Moteur commun — correctif partagé par les J21–J31 (2026-10-22)

Branche `moteur-commun`, partie de `systemes-2` = `main` à `58f5b7d4`, worktree
`~/dev/kanto-2026-wt-moteur`. Trois sujets : performance des grandes cartes avec eau sur l'A17,
Surf dessiné à pied (D1 de la QA du J24), boutons qui recouvrent le joueur (D5 de la QA du J24).
Aucun changement de format de sauvegarde. Les jalons la récupèrent par la fusion de `main`.

## 1. Performance des grandes routes avec eau (A17, Mali-G57 MC2, 2340 × 1080, 60 Hz)

### 1.1 Mesure

Outil : **`PerfProbe`** (`game/systems/debug/perf_probe.gd`), sonde de QA par couches, active en
build debug, Boot scène principale, si `user://perf_probe.json` existe :

```bash
adb shell "run-as dev.kevin.kanto2026 sh -c 'echo {} > files/perf_probe.json'"   # défauts
# ou { "hold": 10, "steps": ["base", "no_ground"], "always": "no_grade" }
adb logcat -s godot:V | grep probe      # [probe] <étape> fps=… min=… gpu=…ms rendu_cpu=…ms
adb shell "run-as dev.kevin.kanto2026 rm files/perf_probe.json"                  # retirer
```

Étapes : `base`, `no_ground`, `no_water`, `no_forest_floor`, `no_decals`, `no_entities`,
`no_overhead`, `no_shadows`, `no_grade`, `no_map`, `no_map_grade`, `no_map_process`, `no_layers`,
`no_layer_<Nom>` (un `CanvasLayer`). « always » : une étape appliquée pendant tout le cycle.
Le joueur reste immobile ; 8 s par étape (moitié mesurée).

**Cause** (Route 11, avant) : base 26 i/s ; sans sol peint 42 (+ 16) ; sans sous-bois 37 (+ 11) ;
sans étalonnage 30 ; carte cachée 50. Le sol (`ground_blend`, quatre bruits à sinus par pixel,
eau animée) et le sous-bois (`forest_floor`, quatre bruits) étaient redessinés à chaque image sur
tout l'écran. La cuisson du J21 ne s'y appliquait pas : rivage (l'eau ondule) et cartes plus
grandes que 2048² px (Route 11 : 7 296 × 3 456 px).

### 1.2 Correctif (générique, aucune carte nommée)

- **Reprise du moteur de cuisson du J21** (`d19a1d98`, partie moteur seule, à l'identique) :
  `PaintedGround.bake`, brume portée par le sol cuit, étalonnage à plat de la Tour.
- **Cuisson par morceaux** (`GroundChunks`, enfant `BakedChunks` du sol) pour tout sol que
  `bake()` refuse : morceaux de 512 px [D] rendus une fois dans des `SubViewport` autour de la
  vue (avance 256 px [D], oubli au-delà de 640 px [D], `SubViewport` resservis : ≈ 40 Mo au plus,
  quelle que soit la carte) ; tous les morceaux de la vue d'un coup à l'arrivée (écran noir),
  puis 2 par image [D] ; un morceau pas encore rendu est dessiné par le shader vivant (aucun
  trou).
- **Eau seule vivante** (`GroundWater`, nœud `WaterOverlay`) : `ground_blend` a deux passes de
  plus (`pass_mode` 1 = la terre, sable compris, cuite ; 2 = l'eau seule, avec un alpha tel que
  le mélange normal sur la terre refait les deux `mix()` d'avant ; au large et sur la terre,
  aucun bruit) ; dessinée seulement sur les cases d'eau (rivage à angles droits) ou les cases
  d'eau et leurs voisines (rivage naturel), en rectangles fusionnés. Le sous-bois qui touchait
  l'eau est redessiné par-dessus sur ces cases (ordre d'avant gardé).
- **Sous-bois cuit avec le sol** (`PaintedGround.forest_layers`) dans les deux cuissons.
- Contrôle visuel : `tools/capture_ground_bake.gd` (Movie Maker, vivant `--live` / cuit) ;
  Route 11 et Bourg Palette identiques hors temps (vent des arbres, ondulation).

### 1.3 Résultats (A17, i/s moyens par fenêtre de 10 s, joueur immobile)

| Lieu | Avant | Après |
|---|---|---|
| Route 11 (`route_11`, `main`) | 25–26, creux 20 | 49–54, creux 30–35 |
| Route 12 nord (J21 + moteur commun, départ `from_lavender`) | 24,7–25,4, creux 20 | 48–52, creux 31 |
| Route 12 sud (idem, `from_route_11_n`) | 24,6–24,9, creux 20 | 49–51, creux 31 |
| Route 16 (idem, `snorlax_16_qa`) | 25,6–25,9, creux 17–21 | 50–53, creux 28–36 |
| Tour 7F (J21 + moteur commun, contrôle) | — | 59–60 |

Route 12 et 16 mesurées sur une intégration jetable `moteur-commun` + `jalon-21-nuit` (hors
dépôt) ; « avant » = l'APK de `jalon-21-nuit` (`d19a1d98`) avec la sonde. Journaux et captures :
`~/dev/qa-moteur/`.

### 1.4 Ce qui reste (ouvert)

**60 i/s pas atteint dehors** : il reste deux postes de taille égale, mesurés sur la Route 12
après cuisson : la carte (≈ 8,5 ms de GPU, répartis sur toutes les couches : sol cuit, eau,
décalcomanies, arbres, `Overhead`, aucune ne pèse seule) et **l'étalonnage `golden_hour` par
copie de l'écran** (≈ 8 ms). Carte cachée : 52 ; étalonnage coupé : 53–55 ; **les deux : 60, GPU
6,5 ms**. Essai écarté : étalonnage par table 3D dans un `Environment` (fond de canevas,
« color correction ») : rendu identique (écart moyen 1,8 / 255) mais aussi coûteux sur le Mali
(48–53 i/s). Pistes, à décider par Kevin (rendu) :
1. étalonnage à plat pour les extérieurs sur les petits GPU (comme la Tour ; les gains de
   `golden_hour` vont de 1,16 à 0,85 selon la luminance : le rendu change) ;
2. un réglage « Économie » (6F) qui coupe l'étalonnage ;
3. baisser la résolution interne sur l'A17.

**Images isolées à ≈ 25–33 ms** (creux 30–38) : ce sont des rendez-vous d'affichage manqués
(écran à 60 Hz : une image de 33 ms). Cause probable : la régulation de fréquence du GPU (le temps
GPU mesuré s'étire jusqu'au budget, ≈ 15–16,5 ms quel que soit le contenu, 14,8 ms carte cachée).
Elles disparaissent quand la charge est faible (carte et étalonnage cachés : creux 60) ; arrêter
les scripts de la carte ne change rien (pas un coût de script ni de ramasse-miettes).

## 2. Monture provisoire dessinée (D1 du J24)

`MountPlaceholder` (`game/player/mount_placeholder.gd`, enfant du `Player`), tant que
l'apparence n'a pas d'animations `surf_*` / `bike_*` :
- **Surf** : dos de nageur dessiné en code (sans image), devant les jambes, sillage clair, tête de
  profil et de face ; héros assis (relevé de 18 px [D]) et immobile (animation `idle_<dir>`),
  ombre cachée. Valeurs [D] : 124 × 44 px de profil, 88 × 44 de face, bleu (0,27 ; 0,47 ; 0,66).
  Captures Mac : `~/dev/qa-moteur/surf/`.
- **Vélo** : l'image `assets/world/props/prop_velo_01.png` du J22 si elle existe (mêmes valeurs
  que `Player._bike_placeholder` du J22) ; sans elle, rien.
- `Player.is_mount_drawn()`. Non vu sur téléphone : aucune carte de `main` n'a d'eau surfable
  (à voir à la QA du J24 après fusion).

## 3. Boutons sous le joueur (D5 du J24) — choix [D]

**[D] Transparence** : le groupe de boutons que le joueur touche à l'écran (coin bas : courir,
contextuel, Vélo ; ou le bouton Menu) passe à 0,3 d'opacité (`UiTokens.BUTTONS_UNDER_PLAYER_ALPHA`)
en un fondu court, marge 12 px, et **reste actif**. Boot donne à chaque image le rectangle du
joueur à l'écran (`Player.get_screen_body_rect()` → `ExplorationHud.set_player_screen_rect`).
Écartés : décaler la caméra ou élargir ses limites (montrerait le vide au-delà de la carte),
rétrécir ou déplacer les boutons (planche validée). Couvert par `test_hud_under_player` ; pas vu
sur téléphone (aucun départ ne pose le joueur au bord bas-droit).

## 4. Pour les jalons à leur fusion de `main`

- **J21** (`jalon-21-nuit`) : conflit attendu dans `game/world/ground/painted_ground.gd` (prendre
  la version de `main`, qui contient celle du J21) ; `test_world_lighting.gd` /
  `test_lighting_library.gd` : mêmes ajouts des deux côtés, prendre `main` en cas de conflit.
  `test_tower_ground_bake` (J21, 2F–7F) et `test_ground_bake_tower` (moteur, 2F–6F) coexistent.
- **J22** : garder `MountPlaceholder` et retirer `_bike_placeholder` / `_make_bike_placeholder` /
  `_update_bike_placeholder` de `player.gd` (même rendu) ; `is_bike_drawn()` peut devenir
  `return get_mount() == Mount.Kind.BIKE and is_mount_drawn()`.
- **J24** : D1 et D5 sont traités ici ; les retirer de la liste des défauts après la QA.
- Tous : une carte peinte n'a rien à faire ; sous GUT (headless), rien n'est cuit d'office.

## 5. Tests

`test_ground_chunks` (règles des morceaux et des rectangles d'eau, Route 11 cuite par morceaux,
vue qui saute, eau exactement sur les cases d'eau), `test_ground_bake_tower` (cuisson du J21 sur
les étages de `main`), `test_mount_placeholder`, `test_hud_under_player`, `test_perf_probe`,
ajouts de `test_world_lighting` / `test_lighting_library` (J21).

Suite complète : **6 485 / 6 485** sur `59f07817` (2026-10-22).
