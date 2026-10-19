# Jalon 18 — Route 9, Route 10, Grotte Sombre, Lavanville et la Tour (rez-de-chaussée)

> **PLAN — à valider par Kevin** (questions au §7.2). Aucun code n'est écrit par ce document.

> Objectif jouable sur le téléphone : **une traversée**. Depuis l'est d'Azuria (arbre coupé, J16),
> la **Route 9** rocheuse (7 Dresseurs, 2 inévitables), la **Route 10 nord** et son Centre, la
> **Grotte Sombre** sur deux niveaux, traversée **à la lumière d'un halo** (petit sans Flash, large
> avec), la **Route 10 sud** d'où l'on voit la Tour, puis **Lavanville** (Centre, Boutique, Maison
> des Pokémon, deux maisons) et le **rez-de-chaussée de la Tour Pokémon**, où une Médium en prière
> ferme l'escalier.
>
> Mécaniques nouvelles : **voile d'obscurité** (couche percée d'un trou radial qui suit le joueur,
> sans `Light2D`), **Flash hors combat** (état « allumée » par grotte, drapeau effacé à la sortie),
> champ `dark` dans `caves.json`, légende d'arrivée généralisée (OUV.3 → plusieurs arrivées).
> **Format de sauvegarde inchangé** (preuve au §3.6).

**Pré-requis.** Dossier 21 **verrouillé** (2026-10-14 : I-1 à I-26, textes T-1 à T-56, grilles §13.1
validés) : c'est la **source de vérité** du J18. Passe d'alignement : `docs/design/passes/
j18-v2-alignement.md`. Plan écrit sur `docs/dossier-j18` = `main` à `4f0ee90` (**J13 terminé**,
sauvegarde **v6**) + documents du J18. Lus sans modification : `jalon-14` (`808f45ed`, 14C validé,
pas encore dans `main`), `docs/plan-j15` (`jalon-15.md`, sauvegarde v7), `docs/dossier-20-j17`
(**dossier 20 du J17, verrouillé le 2026-10-14 à 23 h 40**), `origin/ccr-fa255d49-wvvacc`
(passe d'alignement du J16, `passes/j16-v2-alignement.md`, G-1 à G-10 répondus ; **aucun dossier 19
consolidé**), `docs/dossier-j19` (dossier 22, contrat d'entrée du J19).

> **Alerte de conception (§0.2 n° 1, §7.2 Q-1).** Le dossier 20 (J17) et le dossier 21 (J18),
> verrouillés le même jour par deux sessions parallèles, **ne disent pas la même chose de Flash** :
> J17 H-6 (Flash aussi apprise en combat, comme une CT réutilisable) et H-7 (Flash **automatique**
> à l'entrée, « pas de menu, pas de bouton ») contre J18 I-3 (« n'existe pas en combat ») et I-5
> (**proposition OUI / NON**, puis « par le menu des capacités de terrain du J16 », menu que
> personne ne conçoit). Rien de l'arbre des tâches 18.0 n'attend cette réponse ; seule la branche
> « entrée dans la grotte » du T17 l'attend.

Références : `CLAUDE.md` (règles 1 à 10), `dossier-21-grotte-sombre-lavanville.md`,
`dossier-15-route-3-mont-selenite.md` (grotte, gravats, Corde), `dossier-06-progression.md` §11
(ex-CS sans emplacement), `dossier-13-ouverture.md` (légende OUV.3), `jalon-12.md` (§2.1–2.6, 2.21,
2.22 : modèle), `jalon-13.md` (eau, villes, intérieurs), `jalon-14.md` et `jalon-15.md` (branches).

> Téléphone de validation : le **S21** depuis le 2026-10-10 (OUV.1), le **S24** aussi. « Session
> S24 » désigne la session téléphone du sous-jalon. **18B se valide à luminosité moyenne** (curseur
> à mi-course, luminosité automatique coupée), avec et sans Flash.

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe et que le J18 utilise (`main` à `4f0ee90`)

| Besoin (dossier 21) | Existant (fichiers:lignes) | Manque |
|---|---|---|
| Grilles et contrôles | `tools/plans/route_9.txt`, `route_10.txt`, `grotte_sombre_1f.txt`, `grotte_sombre_b1f.txt`, `lavanville.txt`, `tour_pokemon_rdc.txt`, `azuria.txt` (arbre `k` (53, 23), `warp_est` l. 109) ; `tools/art/plan_check_*.py` verts ; lecteur `tests/helpers/plan_grid.gd` | rien (validées) ; commentaires périmés de `lavanville.txt` (§0.2 n° 9) |
| Cartes de grotte | `tools/cave_map_kit.gd` : `WALKABLE ".gjUVE"` (l. 35), `PLANS` (l. 74–79, sert à `ladder_links` l. 301), `add_glow` (l. 390), voile **précalculé** `add_shade` (l. 434, `CaveShade` + `CaveFloorLight` sous `Entities`) ; `tools/build_mt_moon.gd -- --etage=` | lettres `e K w f r o` ; `PLANS` des deux étages ; `tools/build_dark_cave.gd` |
| Cartes extérieures, villes, eau | `tools/pewter_map_kit.gd`, `tools/build_route_3.gd`, `build_route_24.gd` (eau du J13), `build_cerulean_city.gd` ; `tools/build_painted_interiors.gd` (`_pokemon_center`) | `build_route_9.gd`, `build_route_10.gd`, `build_lavender_town.gd`, pièces des intérieurs |
| Catégorie grotte, Corde | `CaveLibrary` (`game/world/caves/cave_library.gd`) : clés strictes `_CAVE_KEYS = ["maps", "escape"]` (l. 27), `is_cave`, `cave_of`, `escape_target` ; `data/world/caves.json` (Mont Sélénite) ; `FieldItemRules.check` / `escape_target` (`game/items/field_item_rules.gd` l. 17–38) ; `Boot._on_field_item_requested` (`boot.gd` l. 1525) | clé `dark`, `is_dark()` ; entrée `dark_cave` |
| Halos fixes | `LightGlow` (`game/world/lighting/light_glow.gd`) : sprite additif, `Z_GLOW = 5` (l. 19, au-dessus d'`Entities`, sous `Overhead` 10), `set_reduce_motion` (l. 54, branché `boot.gd` l. 1470) ; types `data/world/light_glows.json` (`lamp`, `shaft`, `beam`…) ; ≤ 16 par carte (`test_mt_moon_maps.gd` l. 106–118) | rien ; type `candle` [D] pour la Tour |
| **Interdiction de `Light2D`** | `tests/unit/test_light_glow.gd` l. 240–254 (**cherche le texte** `PointLight2D`, `DirectionalLight2D`, `LightOccluder2D` dans tout `.gd` / `.tscn` de `game/`) ; `tests/integration/test_mt_moon_maps.gd` l. 117 (aucun nœud `Light2D`) | **rien à assouplir** ; ne jamais écrire ces trois mots, même en commentaire, dans `game/` |
| Couches de dessin | `WorldLighting` : `Z_GROUND -3`, `Z_SHADOWS -2`, `Z_GROUND_DECALS -1` (`world_lighting.gd` l. 31–33), `Entities` 0 (tri par les pieds), `Overhead` 10 ; étalonnage d'écran = `CanvasLayer` `UiTokens.LAYER_WORLD_GRADE` (l. 57), au-dessus du monde ; HUD et menus : `CanvasLayer` | `Z_VEIL`, `Z_ABOVE_VEIL` |
| Bulle « ! » | `Npc.show_emote` (`game/world/npc/npc.gd` l. 1112–1121) : `Sprite2D` enfant du PNJ, **`z_index = 10` relatif** ; `EmoteBubble` (compagnon, `emote_bubble.gd` l. 41) : idem | z absolu au-dessus du voile |
| Rencontres | terrain `rubble` (J12 : `EncounterTable.TERRAINS`, `GridWorld.is_rubble`, `RubbleBurst`, `rate` 25, rampe 15 → 20) ; tables `data/encounters/*.json` (`maps`, `terrain`, `slots`) | 4 tables |
| Dresseurs, PNJ | `data/trainers/*.json` (`name`, `ai`, `prize_money`, `team`) ; bloc `trainer` des PNJ, `rematch`, `leave` (J12 T17) ; `TrainerEncounter` | 14 Dresseurs ; classes Pokémaniac (planche) |
| Objets visibles et cachés | J8 (`object/poke_ball_ground`, `got_<id>`) ; objets cachés « face à un indice » (J12 T17 : `InteractPoint.unless_flags`) | données |
| Dialogues, choix | `DialogueChoice` : `confirm_action` ∈ `DialogueLibrary.ACTIONS = [heal, center_heal, open_shop, open_storage]` (`dialogue_library.gd` l. 37), `confirm_set`, `confirm_pages`, `confirm_cutscene` ; ordre dans `DialogueRunner.choose` (l. 175–195 : drapeaux, **action attendue**, puis pages) ; actions servies par `ServiceDirector.run_action` (`service_director.gd` l. 83, branché `boot.gd` l. 210) | action `use_flash` |
| Jeton `{pokemon}` | `Boot._dialogue_token_values` (`boot.gd` l. 1210) : **nom du compagnon seulement** | valeur imposée pendant la scène de Flash |
| Légende d'arrivée | `FirstExitCaption` (`game/systems/opening/first_exit_caption.gd`, `subtitle_for` l. 73) : **un seul** couple `map` / `from` (`data/opening/first_exit.json`) ; appelée dans `Boot._on_map_entered` (l. 1128) | une liste d'arrivées (Lavanville) |
| Arrivée sur une carte | `Boot._on_map_changed` (l. 1070 : écran noir, `_apply_lighting`, contrôleurs) puis `_on_map_entered` (l. 1128 : zone découverte, **autosave**, titre) ; `SceneRouter` : `transition_started`, `map_changed`, `map_entered` | branchement du voile et de Flash |
| Réglages | `Boot._apply_settings` (l. 1457–1479) : `reduce_motion`, `reduce_flashes` | `DarknessController.set_reduce_motion` |
| Objectifs | `data/story/objectives.json` (première entrée valide l'emporte ; textes **en minuscule initiale**, « traverser le Mont Sélénite. ») | 5 entrées |
| Zones, points de repos, décors | `zones.json` (`name`, `kind`, `maps`, `subtitle`, `description`, `services`), `rest_points.json`, `data/battle/decors.json` (par carte, variantes par cases), `companions.json` (`contexts` carte → `cave`) | entrées ; 2 décors CB.3 |
| Pokédex, compteur | `Pokedex.caught_count()` (`pokedex.gd` l. 128) | rien au J18 (J17 l'utilise) |
| Compatibilités | `tools/gen_tm_compatibility.py` : CT 1–50 seulement, « les CS ont des numéros ≥ 101 dans PokeAPI » (l. 46) ; `PokemonData.can_learn_tm` (`pokemon_data.gd` l. 137) | section CS (J16, sinon J18) |
| Sauvegarde | `SaveSystem.VERSION = 6` (`save_system.gd` l. 35) ; v7 au J15 (Pension) | rien (§3.6) |
| Départs de débogage | `DebugStart._KEYS` (`debug_start.gd` l. 70 : …, `wild`, `companion`), `wild_terrain` | clé `veil` (prototype) ; 11 départs |
| Mesures | `PerfCounter` (« `[perf] fps=… min=… draw=… tex=…` », `perf_counter.gd` l. 22) ; `tools/measure_map_cache.gd` ; `tools/art/luminance_grotte.py` (sol près du joueur ≥ 0,22, ≥ 2,0 × paroi, héros ≥ 3,0 ; `PLANS` du Mont Sélénite) ; `tools/capture_mt_moon.gd` | seuil **hors du halo** ; plans du J18 ; option voile |
| Simulation | `tools/simulate_mt_moon.gd` + scénarios `tools/sim/*_scenario.json` (générique depuis le J13 : `cerulean_scenario.json`) | scénario du J18 |

### 0.2 Écarts constatés (et décision)

1. **Flash : deux dossiers verrouillés se contredisent** (dossier 20 H-6, H-7, H-8 ; dossier 21 I-3,
   I-5 ; passe J16 G-2 « modèle hybride » pour toutes les CS). → **Q-1** (game design). Ce qui ne
   dépend pas de la réponse : l'état « allumée » par grotte (I-6), le voile, le drapeau, la
   condition « CS05 + Pokémon compatible », T-2 et T-3.
2. **Source de Flash (I-4) : la condition est levée.** Le dossier 20 pose l'assistant de Chen et la
   CS05 (poste de la Route 2 est, 10 espèces, H-2, H-9, sous-jalon 17B). **Le §8 du dossier 21 ne
   s'applique pas** : le J18 ne construit ni poste, ni assistant, ni FUTUR A ; ses textes T-11 à
   T-16 restent inutilisés ; la description de la CS05 est celle du J17 (dossier 20 T-15). [D]
3. **Condition de badge.** Dossier 21 §5.3 : « + Badge Roche » ; dossier 20 H-6 : aucune. Le Badge
   Roche est toujours obtenu avant (J10) : **aucune condition de badge dans le code** (une
   condition toujours vraie ne sert à rien). [D]
4. **Le « menu des capacités de terrain du J16 » n'est conçu nulle part.** La passe du J16 coupe
   les arbustes par un `InteractPoint` dédié qui interroge `FieldMoves.can_cut(party, bag, flags)`
   (G-2, G-3 retranché : Badge Cascade exigé) ; le J17 rend Flash automatique « sans menu ». Le
   J18 ne dépend donc d'aucun menu **sauf** si Q-1 garde la proposition avec rattrapage (option B).
5. **Le voile : qui le code ?** Dossier 20 H-8 : « fondation de l'éclairage au J17, sur une carte de
   QA `qa_flash` ; réglage au J18 ». Dossier 21 §13 : « voile en prototype mesuré au 18.0 ». Deux
   codes pour une brique = un de trop → **Q-3** (recommandation : une seule brique, celle du §2,
   codée maintenant au 18.0 et reprise par le J17).
6. **Nom de la grotte** : le dossier 20 dit « Tunnel Roche » dans ses notes ; I-1 garde « Grotte
   Sombre ». Aucun texte validé du J17 ne nomme la grotte. Identifiants J18 : `dark_cave`,
   `dark_cave_1f`, `dark_cave_b1f`. [D]
7. **Corde Sortie et entrées multiples** : le dossier 20 (§12) veut, pour la Cave Taupiqueur, « la
   bouche par laquelle on est entré » (une seconde forme de sortie dans `caves.json`) ; le J18 garde
   **une seule sortie** (I-11 : entrée nord). Les deux formes cohabitent : le J18 n'écrit que
   `escape`. Si le J17 change le schéma, le J18 s'aligne au T15.
8. **Roadmap** : celle de cette branche dit « J17 Major Bob + Badge Foudre (dossier 20) » ; le
   dossier 20 réel est « Les chemins retrouvés » (Route 11, Cave Taupiqueur, CS05) et la passe du
   J16 met Major Bob au J16. Sans effet sur le code du J18 ; à corriger dans `roadmap.md` par la
   session qui la tient (signalé, non modifié ici).
9. **`lavanville.txt` : commentaires périmés.** L'en-tête et `warp_nord` citent encore la Route 10
   en (15..17, 75) ; `route_10.txt` (`warp_sud` 21..23, 75) et le dossier §13.1 (« raccord aligné en
   colonnes 21..23 ») font foi. Les positions sont justes, seuls les commentaires sont faux :
   corrigés par le constructeur au T14 (fichier de `tools/plans/`, pas de `tools/art/`). [D]
10. **Légende d'arrivée** : `lavanville.txt` pose un `declencheur` `legende_arrivee` (21..23, 1). Le
    dossier exige le **mécanisme d'OUV.3** (titre de zone dont la région est remplacée) : la légende
    passe par `FirstExitCaption` étendu (§4.11) ; la case du déclencheur sert à poser
    `lavender_reached` (objectif), en silence. [D]
11. **Objectifs** : T-56 commence par une majuscule ; les données existantes sont en minuscule
    initiale (`objectives.json`). Mêmes mots, convention des données. [D]
12. **Escalier de la Tour** : `pokemon_tower_2f` n'existe pas au J18. Le warp (17, 2) porte
    `coming_soon = "Tour Pokémon"` (mécanisme existant, inerte en release ; de toute façon
    inatteignable tant que la Médium occupe (17, 3)). Le J19 le remplace. [D]
13. **Médium / Exorciste** : le J19 (K-2) renomme la gardienne « Exorciste » qui ne combat pas et
    pose `tower_stairs_open` (K-3). Le J18 utilise **déjà** ce nom de drapeau pour sa présence
    (`unless: [tower_stairs_open]`) et l'apparence `channeler` (planche mutualisée, J19 §12.4). [D]
14. **Le J19 attend du J18** (dossier 22 §3) : la maison d'Osselait (exclue par le dossier 21 §6.2 :
    le J19 la placera) et « un emplacement de panneau pour le Scope Sylphe » (le J18 ne pose rien ;
    passation au T26).
15. **Machoc devient sauvage** (grotte) : son évolution vers Machopeur (Nv. 28) a été **omise au J14**
    (espèce absente, Machoc « de Dresseur seulement ») ; même cas pour Voltorbe (Électrode). Règle
    existante : une évolution vers une espèce absente n'existe pas. « Aucune espèce nouvelle au
    J18 » (§10.1) : gardé, signalé dans la passation (§7.1). [D]
16. **Identifiants des Dresseurs** : les grilles écrivent `route_9_<classe>_<prénom>` pour les
    routes et `dark_cave_<prénom>` pour la grotte. Les grilles font foi. [D]
17. **Halos de la grotte** : 2 à 4 par étage (lampes, filet de jour, lumière de l'entrée), contre ≥ 4
    au Mont Sélénite (`assert_between(…, 4, 16)`) : le test du J18 prend 1 à 16. [D]
18. **Texte T-9 (racines) et objet caché sous les racines** : la case où l'on se tient (42, 32) est
    entre deux cases de racines. T-9 en (41, 32) (regard ←), l'indice de l'objet caché en (43, 32)
    (regard →, règle du J12 : disparaît une fois trouvé). [D]

### 0.3 Ce que le J18 attend des J14 à J17 (et repli)

| Livraison | Jalon (état au 2026-10-14) | Pour | Si elle manque ou diffère |
|---|---|---|---|
| `machop` (Machoc), `low_kick` (Balayage), `dig` (Tunnel en combat) | J14 (`jalon-14`, 14C validé, **pas dans `main`**) | rencontres de la grotte, R9-5/R9-6, G-1 | données du J18 préparées hors de `data/` (scénario de simulation) jusqu'à la fusion ; aucun repli dans le jeu |
| `super_potion`, `meowth` (Miaouss), sauvegarde **v7** | J15 (`jalon-15`, en cours) | objets, Boutique, R9-4 | idem ; le J18 écrit la version de `main` au moment de sa fusion |
| Coupe dans le monde, `FieldMoves`, arbustes « cases libérées par un drapeau », section CS de `tm_compatibility.json` | J16 (passe répondue, **dossier 19 absent, aucun code**) | arbre d'Azuria → Route 9 | Route 9 jouée par départs de débogage ; son bord ouest reste `coming_soon = "Azuria"` (§1.4) |
| `hm05`, `got_hm05`, compatibilités CS05, Flash en combat (H-6), fondation d'éclairage (H-8) | J17 (dossier 20 verrouillé, **aucun plan ni code**) | Flash | voir §1.3 et §1.4 |

---

## 1. Dépendances et contrats

### 1.1 J14 et J15

Le J18 **lit** leurs données, sans rien y ajouter : `machop` (`data/pokemon/species/kanto_j14.json`),
`low_kick` (`moves_j14.json`), `meowth` (J15), `super_potion` (`data/items/vermilion.json`). Les
fichiers du J18 qui les citent (Dresseurs, rencontres, Boutique, objets) n'entrent dans `data/`
qu'**après** la fusion de ces jalons dans `main` : les chargeurs refusent un identifiant inconnu
(`test_trainer_library`, `test_encounter_library`, `test_shop_library`). Avant : le scénario de
simulation (T10) porte les mêmes valeurs, au format de `data/`.

### 1.2 J16 — Coupe, arbre, capacités de terrain : interface minimale attendue

Le J18 n'a besoin que de **trois choses** du J16. Si le J16 les livre sous une autre forme, le T15
(alignement) adapte le J18, jamais l'inverse.

1. **L'arbre à couper d'Azuria** se comporte comme les arbustes du J16 : un `InteractPoint`
   « arbuste » en (53, 23), un drapeau par arbre (G-4 ; nom [D] `cut_cerulean_east_tree`), la case
   devient praticable quand le drapeau est levé (« cases libérées par un drapeau »), Badge Cascade
   exigé (G-3 retranché). Le J18 **ne code rien de Coupe** : il régénère Azuria (`azuria.txt` déjà
   à jour) avec l'arbre et le warp est `warp_est` (55, 22..24) → `route_9` / `from_cerulean`.
2. **Un registre des capacités de terrain**, pur, lu dans les données (règle 7 : jamais
   `if move == &"flash"`). Contrat **minimal** proposé au J16 (s'il n'a rien fixé, c'est cette
   forme) :
   ```json
   // data/pokemon/field_moves.json
   { "_doc": "…", "moves": {
     "cut":   { "item": "hm01", "hm": 1, "badge": "badge_cascade" },
     "flash": { "item": "hm05", "hm": 5 } } }
   ```
   ```gdscript
   # game/pokemon/field_moves.gd — pur, testable sans scène
   class_name FieldMoves
   extends RefCounted
   ## Capacités de terrain (dossier 06 §11 : sans emplacement de combat). Disponible = l'objet CS
   ## est dans le Sac, le badge éventuel est obtenu, un membre de l'équipe est compatible
   ## (K.O. compris, dossier 21 §14).
   func load_file(path: String = DATA_PATH) -> bool
   func can_use(move: StringName, party: Party, bag: Bag, flags: StoryFlags,
   		data: PokemonData) -> bool
   ## Qui l'utilise : le compagnon s'il est compatible, sinon le premier compatible de l'équipe.
   func user_for(move: StringName, party: Party, data: PokemonData,
   		companion: Pokemon) -> Pokemon
   ```
   Si le J16 a écrit `can_cut(party, bag, flags)` en fonction dédiée, le J18 ajoute
   `can_flash` / `flash_user` **à côté, en fin de fichier**, sans réécrire le J16.
3. **La section CS des compatibilités** : `tools/gen_tm_compatibility.py` étendu aux numéros
   PokeAPI 101–105 de `red-blue` (CS01–CS05) ; forme proposée : `"hms": { "01": "cut", …,
   "05": "flash" }` + `"hm_species": { "<espèce>": [1, 5] }` ; lecture `PokemonData.can_use_hm
   (species, number) -> bool` (à côté de `can_learn_tm`, l. 137). Fichier **généré** : régénéré
   après chaque fusion, jamais fusionné à la main (règle du J11).

**Tunnel hors combat** (dossier 17 §7.4) et **Flash par un menu** n'existent que si un menu de
terrain existe : le J18 ne le suppose pas (§0.2 n° 4).

### 1.3 J17 — CS05 et Flash

- **Reçu** (dossier 20 §8.1) : objet `hm05` « CS05 — Flash » (catégorie CS du J16, jamais
  consommé), drapeau `got_hm05`, compatibilités CS05 (PokeAPI `red-blue`), capacité de combat
  `flash` (H-6), mise en scène « {pokemon} utilise Flash ! » (T-17 du J17 = T-2 du J18, mot pour
  mot), carte de QA `qa_flash` retirée à sa clôture.
- **Contrat que le J18 propose au J17** (pour qu'il n'y ait qu'un code) : une carte est obscure
  **si et seulement si** sa grotte porte `"dark": true` dans `caves.json` (`CaveLibrary.is_dark`) ;
  l'éclairage est le voile du §2 (`DarknessVeil`, `DarknessController`) ; l'état allumé est le
  drapeau `<grotte>_lit` (§3.4) ; la disponibilité est `FieldMoves.can_use(&"flash", …)`. Le J17
  peut éprouver sa mise en scène sur `mt_moon_1f` avec la clé de débogage `veil` (§2.12) au lieu
  d'une carte `qa_flash`.
- **Ce qui dépend de Q-1** : la décision d'entrée (automatique ou proposition) et l'existence d'un
  rattrapage après NON. Le reste du §3 est commun.

### 1.4 Plan B si le J16 ou le J17 tardent

| Manque | Ce que fait le J18 | Ce qui reste bloqué |
|---|---|---|
| J16 (Coupe) | Route 9 construite et vivante ; bord ouest `coming_soon = "Azuria"` (retour sur la case) ; départ `route_9` posé sur la Route 9 ; Azuria **non régénérée** | 18A ne valide pas le raccord Azuria ↔ Route 9 (validé à la fusion du J16, critère reporté) |
| J16 (registre, section CS) | le T17 crée `field_moves.json` **avec la seule entrée `flash`**, `FieldMoves` et la section CS ; le J16 ajoute `cut` à sa fusion (« le premier fusionné crée, l'autre aligne ») | rien |
| J17 (`hm05`) | le T16 crée `hm05` **d'après le dossier 20** (§8.1, nom, catégorie, description T-15 du J17), dans `data/items/j18.json`, signalé aux deux sessions ; Flash éprouvée par départs de débogage (CS05 au Sac) | dans la vraie partie, Flash n'est obtenue qu'avec le J17 (le J18 n'a pas de source, §0.2 n° 2) |
| J17 (fondation H-8) | le §2 est la fondation | rien |
| aucun menu de terrain | Flash ne s'allume qu'à l'entrée (automatique, ou proposition selon Q-1) | option B de Q-1 seulement (bouton FLASH), §7.2 |

### 1.5 Calendrier, branches, fichiers partagés

**Règle (analogue de C-7 du J12)** : le code du J18 dans les fichiers **chauds** (`boot.gd`, combat,
sauvegarde, dialogues, Sac, `debug_start.gd`) part **après la clôture du J17** (un seul jalon à la
fois dans ces fichiers). Avant, sur `jalon-18` depuis `main` (**Q-4**) : l'art, les cartes **sans
vie**, le voile (fichiers neufs + trois raccords courts), les outils de mesure et la simulation.

Branche d'intégration `jalon-18` depuis `main`, une branche par tâche `j18-t<n>-<sujet>` ; jamais
de `pkill` ; `etat-projet.md` mis à jour dans chaque commit de tâche ; textes **mot pour mot** du
dossier 21 §15 et de l'annexe A validée.

Fichiers partagés avec d'autres jalons (ajouts **en fin**, « garder les deux côtés » à la fusion) :

| Fichier | Autres jalons | Ajout du J18 |
|---|---|---|
| `game/boot.gd` | J14–J17 | 3 raccords (voile, Flash, légende) + réglage `reduce_motion` |
| `game/world/caves/cave_library.gd`, `data/world/caves.json` | J17 (Cave Taupiqueur, sortie par bouche) | clé `dark` en fin de `_CAVE_KEYS`, `is_dark` ; entrée `dark_cave` |
| `game/world/npc/npc.gd` (l. 1121), `emote_bubble.gd` (l. 41) | J16 (Coupe visible ?) | z absolu de la bulle |
| `game/systems/debug/debug_start.gd` | tous | clé `veil` en fin de `_KEYS` |
| `game/systems/dialogue/dialogue_library.gd`, `service_director.gd` | J16 (choix → scène, G-10) | action `use_flash` en fin d'`ACTIONS` |
| `game/systems/opening/first_exit_caption.gd`, `data/opening/first_exit.json` | — | forme liste (§4.11) |
| `tools/gen_tm_compatibility.py`, `tm_compatibility.json` | J16 (section CS), J17 | section CS si absente (régénéré) |
| `tools/build_cerulean_city.gd`, `tools/plans/azuria.txt` | J14 (jardin, barrage), J16 (arbre ?) | arbre + warp est (régénération **après** J14 et J16) |
| `tools/build_painted_interiors.gd` | J14–J17 | 7 pièces en fin |
| `data/story/objectives.json`, `zones.json`, `rest_points.json`, `decors.json`, `companions.json`, `lighting.json`, `light_glows.json` | tous | entrées nouvelles (objectifs **en tête**, §4.13) |

---

## 2. Le voile d'obscurité (cœur technique)

### 2.1 Principe

- **Un seul nœud** pour tout le jeu, **dans le monde** (pas un `CanvasLayer`), qui dessine un
  rectangle couvrant exactement la vue avec un `ShaderMaterial` : noir bleuté d'opacité
  `outside`, **percé** d'un trou radial doux centré sur le joueur et de trous plus petits aux
  `LightGlow` de la carte. Aucune `Light2D`, aucune occlusion, **aucun effet sur la grille** : les
  collisions et les cartes sont les mêmes avec ou sans Flash (risque n° 1 de la V2, garanti par
  construction).
- **Pourquoi dans le monde** : la bulle « ! » doit passer **au-dessus** du voile et rester sous
  l'interface ; un `CanvasLayer` obligerait à sortir la bulle du monde. Dans le monde, un `z_index`
  absolu suffit (§2.2).
- **Pourquoi pas le voile précalculé du J12** (`CaveShade`) : il est fixe, sous `Entities`. Il reste
  peint dans les étages de la Grotte Sombre (même kit que le Mont Sélénite), pour que la grotte
  éclairée par Flash ait le rendu validé du J12 ; le voile s'ajoute par-dessus.
- **Le Mont Sélénite n'a pas de voile** (dossier 21 §5.2) : pas de `dark` dans son entrée.

### 2.2 Couches (`z_index` absolu, `z_as_relative = false`)

| Élément | z | Sous / sur le voile |
|---|---|---|
| sol peint, ombres, décalcomanies (`WorldLighting.Z_GROUND`…) | −3 à −1 | sous |
| `Entities` (joueur, PNJ, compagnon, objets) | 0 (tri par les pieds) | sous ; **le joueur est dans le trou** (rayon net ≥ 2,5 cases autour du centre de son corps, sprite de 128 px) |
| `LightGlow` | 5 | sous, mais **percés** : un trou du voile à chaque halo (§2.6) |
| `Overhead` (surplombs, cimes) | 10 | sous (sinon les surplombs resteraient clairs dans le noir) |
| **`DarknessVeil`** | **20** (`WorldLighting.Z_VEIL`, nouveau) | — |
| bulle « ! » des PNJ, bulle du compagnon | **21** (`WorldLighting.Z_ABOVE_VEIL`, nouveau) | sur |
| étalonnage d'écran, HUD, dialogues, menus, combat | `CanvasLayer` | sur |

**Bulle** : `Npc.show_emote` et `EmoteBubble.play` passent de `z_index = 10` relatif à
`z_as_relative = false`, `z_index = WorldLighting.Z_ABOVE_VEIL`, **partout** (pas seulement dans
le noir) : la bulle est un signe d'interface, elle passe aussi au-dessus des cimes (aujourd'hui à
égalité avec `Overhead`). Capture de contrôle sur la Route 3 (Dresseur sous un arbre). [D]

### 2.3 Shader (`game/world/lighting/shaders/darkness_veil.gdshader`)

```glsl
shader_type canvas_item;
render_mode unshaded, blend_mix;
const int MAX_SOURCES = 16;
uniform vec3 veil_color : source_color = vec3(0.016, 0.024, 0.047);
uniform vec2 center;            // monde (px), centre du corps du joueur
uniform float clear_radius;     // px : trou net
uniform float fade_radius;      // px : fin du fondu
uniform float outside;          // opacité hors du halo (< 1 : jamais de noir total)
uniform float breath = 0.0;     // amplitude relative du battement (0 : « Réduire les animations »)
uniform float breath_period = 3.5;
uniform vec4 sources[MAX_SOURCES]; // x, y (monde, px), rayon (px), force (0..1)
uniform int source_count = 0;
varying vec2 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	float k = 1.0 + breath * sin(TIME * 6.2831853 / breath_period);
	float lit = 1.0 - smoothstep(clear_radius * k, fade_radius * k, distance(world, center));
	for (int i = 0; i < source_count; i++) {
		vec4 s = sources[i];
		lit = max(lit, s.w * (1.0 - smoothstep(s.z * 0.4, s.z, distance(world, s.xy))));
	}
	COLOR = vec4(veil_color, outside * (1.0 - lit));
}
```

- Calcul en **coordonnées du monde** (`MODEL_MATRIX`) : indépendant de la caméra, de l'étirement
  `canvas_items` et du format `expand` du S24.
- Coût : une passe plein écran, un mélange alpha, ≤ 17 distances par pixel ; aucune texture.
- Le **même calcul** existe en GDScript pur (`VeilMath.alpha_at`, §2.4) pour les tests (le rendu
  ne se relit pas en headless) ; une capture Mac contrôle l'accord (§2.11).

### 2.4 Logique pure (testable sans scène)

```gdscript
# game/world/lighting/darkness_profile.gd — pur
class_name DarknessProfile
extends RefCounted
## Réglages du voile (`data/world/darkness.json`) : états « dark » (sans Flash) et « lit »
## (Flash), en cases ; couleur ; battement ; durée d'ouverture ; échelle des trous des halos.
## Garde-fou « jamais de noir total » : outside ≤ MAX_OUTSIDE ; clear < fade.
const DATA_PATH: String = "res://data/world/darkness.json"
const MAX_OUTSIDE: float = 0.85
const MAX_SOURCES: int = 16
func load_file(path: String = DATA_PATH) -> bool
func params_at(lit_amount: float) -> VeilParams     # interpolation dark → lit, en px
func open_duration() -> float
func breath(reduce_motion: bool) -> float           # 0 si réduit
func get_errors() -> PackedStringArray

# game/world/lighting/veil_params.gd — donnée pure
class_name VeilParams
extends RefCounted
var clear_px: float
var fade_px: float
var outside: float

# game/world/lighting/veil_math.gd — pur (miroir du shader)
class_name VeilMath
extends RefCounted
static func alpha_at(point: Vector2, center: Vector2, params: VeilParams,
		sources: PackedVector4Array) -> float
## Sources des halos d'une carte : position monde, rayon (cases du type × échelle → px), force ;
## au plus MAX_SOURCES (au-delà : push_error, les premières gardées).
static func sources_of(glows: Array[LightGlow], library: LightGlowLibrary,
		hole_scale: float) -> PackedVector4Array
static func body_center(player_position: Vector2, offset_px: float) -> Vector2
```

### 2.5 Présentation et branchement

```gdscript
# game/world/lighting/darkness_veil.gd
class_name DarknessVeil
extends Node2D
## Le voile : un rectangle à la taille de la vue (marge d'une case), z absolu Z_VEIL, matériau
## du shader. Ne calcule rien : reçoit centre, réglages et sources.
func set_view_rect(rect: Rect2) -> void        # appelé par le contrôleur quand la vue bouge
func set_center(world: Vector2) -> void
func set_params(params: VeilParams) -> void
func set_sources(sources: PackedVector4Array) -> void
func set_breath(amplitude: float) -> void

# game/world/lighting/darkness_controller.gd
class_name DarknessController
extends Node
## Possédé par Boot (comme WorldLighting). Pose le voile sur les cartes obscures, le retire
## ailleurs ; suit le joueur ; ouvre le halo (Flash). `set_process(false)` hors du noir.
signal opened                                    # fin de l'ouverture (Flash)
func setup(world: Node2D, player: Player, profile: DarknessProfile) -> void
func set_map(map: GameMap, dark: bool, lit: bool) -> void   # écran noir : sans animation
func open() -> void                              # Flash : lit_amount 0 → 1 en open_duration
func is_dark() -> bool
func lit_amount() -> float
func set_reduce_motion(enabled: bool) -> void
```

- **`Boot._on_map_changed`** (l. 1070, écran noir), juste après `_apply_lighting(map)` :
  `_darkness.set_map(map, _caves.is_dark(map.map_id), FlashRules.is_lit(map.map_id, _caves,
  GameState.flags))`. Le voile est donc en place **avant** que l'écran s'éclaire : aucun éclair de
  grotte non voilée, aux échelles comme à la reprise (« le halo se recrée pendant le fondu »).
- **Sources** : `set_map` cherche les `LightGlow` de la carte **une fois** (`find_children`, jamais
  dans `_process`), `VeilMath.sources_of` → `set_sources`.
- **`_process`** (seulement dans le noir) : centre = `VeilMath.body_center(player.global_position,
  offset)` ; rectangle de vue = rectangle visible de la fenêtre passé par l'inverse de
  `get_viewport().get_canvas_transform()` ; `set_shader_parameter` avec des `StringName`
  constants ; aucune allocation.
- Le voile vit sous le nœud monde de Boot (un seul, jamais libéré) ; `visible = false` hors du
  noir.
- **Ouverture (Flash)** : un `Tween` sur `lit_amount` (0 → 1, `open_duration` 0,6 s [D], sortie
  douce), dont le setter pousse `profile.params_at(lit_amount)` ; testable avec `TweenClock`.
- **Combat, menus, dialogues** : au-dessus (`CanvasLayer`) ; le voile reste dessous, inchangé.

### 2.6 Halos fixes qui percent le voile

Les `LightGlow` restent sous le voile (z 5) et **percent** celui-ci par les `sources` du shader :
rayon du trou = `radius` du type (`light_glows.json`) × `glow_hole_scale` [D 1,0], force [D 1,0]
(une lampe éclaire « comme dehors »), ≤ 16 (budget du J12). Colonne `beam` : trou au pied.
Lampes de randonneur, filet de jour de la paroi fendue (`shaft` + `beam`), lumière de l'entrée nord
(`j`) : repères visibles **de loin** dans le noir, ce que veut la V2.

### 2.7 Exceptions (I-8) et compagnon

- **Joueur** : centre du trou au centre de son corps (`center_offset` −48 px [D]) ; rayon net 2,5
  cases = 240 px ≥ la tête (−128 px) : jamais voilé, y compris en course.
- **Bulle « ! »** : z 21 (§2.2). Un Dresseur qui voit le joueur à 4–5 cases est dans l'ombre, sa
  bulle non ; il **sort de l'ombre** en marchant.
- **Compagnon** : adjacent, donc dans le trou ; masqué dans le passage étroit (règle du J11).
- **Pokémon sauvage** : le combat s'ouvre dans son propre `CanvasLayer` ; l'intro « éboulis »
  (`RubbleBurst`) est aux pieds du joueur, dans le trou.

### 2.8 « Réduire les animations », ouverture, transitions

- `Boot._apply_settings` (l. 1457), à côté de `LightGlow.set_reduce_motion` (l. 1470) :
  `_darkness.set_reduce_motion(s.reduce_motion)` → battement `breath` = 0 ; ouverture de Flash
  **instantanée** (lit_amount = 1 dans le même appel).
- Changement d'étage : rien de propre (fondu existant ; `lit_amount` gardé dans la même grotte).
- Sortie de la grotte : `set_map(…, dark = false, …)` à l'écran noir → voile caché.

### 2.9 Données

```json
// data/world/darkness.json [toutes les valeurs D, réglées en 18.0 sur S24]
{ "_doc": "Voile d'obscurité (docs/tech/jalon-18.md §2) …",
  "color": "#04060c",
  "dark": { "clear": 2.5, "fade": 4.0, "outside": 0.6 },
  "lit":  { "clear": 7.0, "fade": 9.0, "outside": 0.3 },
  "center_offset": -48, "breath": 0.03, "breath_period": 3.5,
  "open_duration": 0.6, "glow_hole_scale": 1.0 }
```
```json
// data/world/caves.json (entrée ajoutée ; "dark" facultatif, faux par défaut)
"dark_cave": { "maps": ["dark_cave_1f", "dark_cave_b1f"],
  "escape": { "map": "route_10", "spawn": "from_dark_cave_n", "facing": "down" },
  "dark": true }
```
`CaveLibrary` : `"dark"` **en fin** de `_CAVE_KEYS` (booléen, sinon erreur), `is_dark(map_id)`.
`outside` « dark » de départ 0,6 : estimé pour tenir « sol hors du halo ≥ 0,10 » sur un sol de
grotte à ≈ 0,22–0,30 (luminance relative) ; c'est la mesure du 18.0 qui fixe la valeur.

### 2.10 Budget de performances et protocole S24

- **Budget** (J12) : moyenne ≥ 58 fps, creux ≥ 50 ; **écart dû au voile ≤ 2 fps de moyenne**
  contre la même vue sans voile, même session, même téléphone.
- **Protocole** (qa-mobile, ≈ 30 min) : APK debug ; départ `veil_proto_mt_moon` (18.0) puis
  `dark_cave_1f` / `dark_cave_1f_flash` (18B) ; luminosité **automatique coupée, curseur à
  mi-course** (photo du réglage dans le rapport) ; parcours fixe de 60 s (aller-retour entre deux
  repères, course comprise) **sans voile** (`mt_moon_1f`, référence), **voile sombre**, **voile
  Flash**, puis un combat sauvage ; relever les lignes `[perf]` (`adb logcat -s godot`) : fps
  moyen, min, `draw`, `tex` ; captures `tools/deploy_s24.sh` aux repères ; verdict de lisibilité
  par Kevin (relief encore lisible hors du halo, gravats visibles dans le halo, personnages qui
  sortent de l'ombre, bulle « ! » lisible).

### 2.11 Mesure Mac : extension de `tools/art/luminance_grotte.py`

- `PLANS` += `dark_cave_1f`, `dark_cave_b1f` (`tools/plans/grotte_sombre_*.txt`) ; `SOL` +=
  `e` ; `PAROI` += `K f r` ; `w` ni sol ni paroi.
- La fiche de capture (`<nom>.json`) porte `veil: { "lit": bool, "clear": …, "fade": … }`.
- **Seuils nouveaux** [D] : **sol hors du halo** (cases praticables à distance > `fade` du centre et
  hors de tout trou de halo) : moyenne ≥ **0,10** et ≥ **1,5** × la paroi voisine (« jamais de noir
  total », I-7) ; **dans le halo** : critères existants (sol ≥ 0,22, ≥ 2,0 × paroi, héros ≥ 3,0) ;
  **gravats dans le halo** distinguables du sol calme (écart de luminance ≥ 0,02, information) ;
  **avec Flash** : critères « près du joueur » jusqu'à 7 cases.
- Captures : `tools/capture_dark_cave.gd` (+ `.sh`, modèle `capture_mt_moon.gd`, 2340 × 1080, zoom 1)
  aux repères (panneau, premier couloir, colonne, paroi fendue, flaque, passage étroit, racines,
  sortie sud), chaque vue **sans et avec Flash**, + vues `_vide` pour le contraste du héros. Pour le
  prototype : option `--voile=dark|lit` de `tools/capture_mt_moon.gd`. Les outils posent un
  `DarknessVeil` sans Boot.

### 2.12 Prototype 18.0 (mesuré avant toute carte du J18)

- Clé de débogage **`veil`** (`"dark"` ou `"lit"`, en fin de `DebugStart._KEYS`) : force le voile
  sur la carte de départ **pour la session** (comme `wild`), build debug seulement, jamais
  sauvegardée. Départ `veil_proto_mt_moon` : `mt_moon_1f`, `"veil": "dark"`.
- Ainsi le prototype tourne sur le **vrai décor peint** du Mont Sélénite (halos, parois), sans
  carte de QA et sans toucher au Mont Sélénite du jeu (aucun `dark` dans son entrée).
- Livrables : mesures Mac (§2.11), session S24 (§2.10), réglages de `darkness.json` arrêtés.

### 2.13 Tests du voile

- `tests/unit/test_darkness_profile.gd` : lecture, erreurs (clé inconnue, clear ≥ fade, outside >
  0,85, durée ≤ 0), cases → px (96), `params_at(0)` = dark, `params_at(1)` = lit, milieu
  interpolé, `breath(true) == 0`.
- `tests/unit/test_veil_math.gd` : alpha 0 au centre du corps et à la tête du joueur ; `outside`
  au-delà de `fade` ; trou d'un halo ; 17 sources → 16 gardées + erreur ; Flash : alpha < 0,1 à
  6 cases.
- `tests/unit/test_cave_library.gd` (étendu) : `dark` vrai / absent / non booléen ; `is_dark`.
- `tests/integration/test_darkness_veil.gd` : sur une carte réelle (`mt_moon_1f`) et le joueur :
  z 20 absolu, rectangle ⊇ vue, centre qui suit le joueur **image par image** (`FrameSim`) pendant
  un pas et une course, sources = halos de la carte, voile caché hors du noir ; ouverture : pas
  finie avant 0,6 s, au plus un pas de plus (`TweenClock`) ; `reduce_motion` : ouverture dans le
  même appel, `breath` 0 ; bulle « ! » d'un PNJ : `z_as_relative == false`, z 21 > 20.
- Garde-fous existants **inchangés et verts** : `test_light_glow.test_no_light2d_in_the_game`,
  `test_mt_moon_maps.test_glows_within_budget_and_no_light2d`, `test_cave_shade_layers`.

---

## 3. Flash

### 3.1 Données

- `hm05` (J17 ; repli §1.4), `got_hm05` (J17).
- Compatibilités CS05 : générées (§1.2 n° 3) depuis les CSV PokeAPI `red-blue`, numéro 105.
- Registre `data/pokemon/field_moves.json`, entrée `flash` (§1.2 n° 2) : **sans badge** (§0.2 n° 3).
- Textes : `data/dialogues/dark_cave.json` : `dark_cave_flash_offer` (T-1, choix OUI / NON),
  `dark_cave_flash_used` (T-2, jeton `{pokemon}`), `dark_cave_too_dark` (T-3) ;
  `data/dialogues/field_moves.json` : `flash_not_here` (T-4, seulement si un menu existe, Q-1 B).

### 3.2 Règles pures

```gdscript
# game/world/caves/flash_rules.gd — pur
class_name FlashRules
extends RefCounted
## Flash hors combat dans les grottes obscures (dossier 21 §5.3, I-5, I-6).
enum Entry { NONE, OFFER, AUTO, WARN }
## Drapeau « allumée » d'une grotte : « <grotte>_lit » (dark_cave → dark_cave_lit).
static func lit_flag(cave: StringName) -> StringName
static func is_lit(map_id: StringName, caves: CaveLibrary, flags: StoryFlags) -> bool
## Vrai si l'on entre dans une grotte obscure depuis une carte d'une autre grotte, de dehors,
## ou au démarrage (from_map vide : Continuer, départ de débogage).
static func is_cave_entry(from_map: StringName, to_map: StringName, caves: CaveLibrary) -> bool
## Ce que l'arrivée déclenche : rien (pas obscure, déjà allumée, pas une entrée), la
## proposition ou l'allumage automatique (Flash disponible, selon Q-1), l'avertissement (T-3).
static func entry_action(from_map: StringName, to_map: StringName, caves: CaveLibrary,
		flags: StoryFlags, available: bool) -> Entry
## Drapeaux « allumée » à effacer en arrivant sur to_map : ceux de toute grotte dont to_map
## ne fait pas partie (sortie à pied, Corde, Tunnel, défaite → Centre).
static func flags_to_clear(to_map: StringName, caves: CaveLibrary,
		flags: StoryFlags) -> Array[StringName]
```

- **Une seule règle d'extinction**, appliquée à **chaque** changement de carte : couvre la sortie à
  pied (nord ou sud), la Corde Sortie, Tunnel, la défaite (réveil au Centre), par construction.
- `entry_action` ne retourne que **OFFER** ou **AUTO** selon Q-1 (une constante, pas un réglage) :
  le code n'implémente que la réponse de Kevin.
- « Une fois par entrée » : mémoire **non sauvegardée** dans `FlashDirector` (§3.3), remise à zéro
  à chaque `is_cave_entry`. Une reprise de partie dans la grotte compte comme une entrée [D].

### 3.3 Entrée dans la grotte

```gdscript
# game/world/caves/flash_director.gd
class_name FlashDirector
extends Node
## Possédé par Boot. À chaque arrivée : extinction (écran noir), puis action d'entrée (écran
## visible, partie stable). Lance la proposition / l'allumage / l'avertissement, une fois par
## entrée ; sert l'action de dialogue « use_flash ».
signal flash_used(map_id: StringName)
func setup(runner: DialogueRunner, darkness: DarknessController, caves: CaveLibrary,
		field_moves: FieldMoves, data: PokemonData) -> void
func on_map_changed(map: GameMap, from_map: StringName) -> void  # efface les drapeaux
func on_map_entered(map: GameMap, from_map: StringName) -> void  # action d'entrée
func use_here() -> void                                         # action « use_flash »
func pokemon_name() -> String                                   # jeton {pokemon} du lanceur
```

- **Ordre dans Boot** : `_on_map_changed` (l. 1070) appelle `FlashDirector.on_map_changed`
  **avant** `_darkness.set_map` ; `_on_map_entered` (l. 1128) mémorise `from` (`_arrival_from`,
  déjà là) et appelle `on_map_entered` **après** `request_autosave` et le titre de zone. Ainsi
  l'autosave d'arrivée n'écrit jamais un drapeau « allumée » hors de la grotte.
- **Proposition (Q-1 = I-5)** : dialogue `dark_cave_flash_offer` (T-1) avec choix ; OUI →
  `confirm_set: [dark_cave_lit]`, `confirm_action: use_flash` (**en fin** de
  `DialogueLibrary.ACTIONS`, servi par `ServiceDirector.run_action` → signal relayé à
  `FlashDirector.use_here`, qui **lance** l'ouverture sans l'attendre), `confirm_pages: [T-2]` (le
  halo s'ouvre pendant que T-2 s'affiche) ; NON → rien, aucune proposition jusqu'à la prochaine
  entrée. Délai d'ouverture de la boîte 0,6 s (paramètre `delay` de `DialogueRunner.play`), pour
  laisser le titre « GROTTE SOMBRE » s'afficher. [D]
- **Automatique (Q-1 = H-7)** : `use_here()` directement (drapeau, ouverture, T-2) ; mise en scène
  du J17 (Pokémon qui apparaît, éclair `ScreenFlash` du J14) si elle existe, sinon ouverture seule.
- **Sans Flash disponible** : `dark_cave_too_dark` (T-3), une fois par entrée.
- **Jeton `{pokemon}`** : `Boot._dialogue_token_values` (l. 1210) prend `FlashDirector.
  pokemon_name()` quand il n'est pas vide (pendant la proposition et T-2), sinon le compagnon.
  Lanceur : `FieldMoves.user_for(&"flash", …)` — le compagnon s'il est compatible (petit éclat :
  bulle « ♪ » [D]), sinon le premier compatible, K.O. compris (§14).
- Jamais pendant une scène ou un combat (`Boot.is_stable()`, l. 654) : si l'arrivée n'est pas
  stable, l'action attend la fin (même mécanique que les dialogues automatiques existants).

### 3.4 Drapeau `dark_cave_lit`

- Posé par OUI (ou par l'allumage automatique). Lu par `DarknessController.set_map` (§2.5).
- **Gardé dans la grotte**, changements d'étage compris (I-6) ; **effacé** par `flags_to_clear` à
  la première carte hors de la grotte.
- Une fois allumée, Flash **reste** allumée même si le lanceur tombe K.O. (I-6 : « jusqu'à la
  sortie »). [D]

### 3.5 « Ce n'est pas utile ici » (T-4)

Seulement si un point d'entrée « utiliser Flash » existe hors de l'arrivée (Q-1 option B) : dans
une carte non obscure, ou déjà allumée → T-4, rien ne change.

### 3.6 Sauvegarde : **aucune version nouvelle** (preuve)

| Ce que le J18 mémorise | Champ (existant) | Forme |
|---|---|---|
| `dark_cave_lit`, `route_9_entered`, `route_10_reached`, `dark_cave_crossed`, `lavender_reached`, `tower_medium_talked`, `beaten_<14 Dresseurs>`, `got_<objets>`, `cut_cerulean_east_tree` (J16) | `flags` | inchangée |
| Objets (Super Potion, Antidote, Poké Ball, Corde Sortie) | `bag.items` | inchangée |
| Objet caché | `found_items` | inchangée |
| Position dans la grotte, points de repos | `map`, `cell`, `facing`, `heal_map`, `heal_spawn` | inchangée |
| Proposition faite pendant l'entrée, `lit_amount` | **rien** (état de session) | — |

Aucun champ ajouté ni transformé : le J18 écrit la version de `main` au moment de sa fusion (v7 si
le J15 est fusionné). **Garde** : toute tâche qui voudrait un champ nouveau s'arrête et revient à
l'architecte. Test `tests/integration/test_save_j18.gd` : partie au B1F, `dark_cave_lit` posé →
`to_dict` → JSON → `load_dict` → drapeau, position, Sac identiques ; reprise : voile allumé **sans**
animation ni proposition ; `SaveSystem.VERSION` inchangée par le J18.

### 3.7 Tests de Flash

- `tests/unit/test_flash_rules.gd` : table de `entry_action` (pas obscure, déjà allumée, étage →
  étage de la même grotte, dehors → grotte, reprise, disponible / non) ; `flags_to_clear`
  (Route 10, Centre de Lavanville, autre étage, autre grotte) ; `lit_flag`.
- `tests/unit/test_field_moves.gd` (étendu ou créé) : `flash` disponible avec `hm05` + compatible ;
  compatible K.O. → disponible ; aucun compatible → non ; sans `hm05` → non ; aucun badge exigé ;
  `user_for` : compagnon compatible prioritaire, sinon premier compatible.
- `tests/integration/test_dark_cave_flash.gd` (Boot réel, vraies cartes) : §6.

---

## 4. Monde

### 4.1 Cartes

| Carte | Taille | Catégorie | Lumière [D] | `display_name` / `region` [D] |
|---|---|---|---|---|
| `route_9` | 80 × 36 | extérieur | `golden_hour` | « Route 9 » / « Azuria — Route 10 » |
| `route_10` | 34 × 76 | extérieur | `golden_hour` | « Route 10 » / « Route 9 — Lavanville » |
| `route_10_center` | 15 × 10 | bâtiment | `interior_warm` | « Route 10 » |
| `dark_cave_1f` | 56 × 49 | **grotte obscure** | `cave_1f` | « Grotte Sombre » / "" |
| `dark_cave_b1f` | 48 × 38 | grotte obscure | `cave_b1f` | « Grotte Sombre » / "" |
| `lavender_town` | 44 × 36 | extérieur | `lavender` (nouveau : étalonnage froid désaturé, violet léger) | « Lavanville » / « Kanto » (légende à la 1re arrivée) |
| `lavender_center`, `lavender_mart` | modèles existants | bâtiment | `interior_warm` | « Lavanville » |
| `pokemon_house`, `lavender_house_1`, `lavender_house_2` | 10 × 8 (maisons d'Argenta / Azuria) | bâtiment | `interior_warm` | « Lavanville » |
| `pokemon_tower_1f` | 20 × 18 | bâtiment | `tower_cold` (nouveau : lumière froide, calme) | « Tour Pokémon » |

### 4.2 Outils de construction (scripts `extends SceneTree`, graines fixes, deux passes masque / scène)

- `tools/build_route_9.gd` (modèle `build_route_3.gd`, kit `pewter_map_kit.gd` : `o` sol rocheux,
  `K` falaise, `R` rochers, `v` rebords, `h` herbes, `T` forêt serrée) ; raccord ouest `coming_soon
  = "Azuria"` tant qu'Azuria n'est pas régénérée (§1.4).
- `tools/build_route_10.gd` (modèle `build_route_24.gd` pour l'eau du J13) : une carte, deux
  secteurs, bande centrale inaccessible ; `w` eau (jamais praticable), `E` centrale (décor bloqué,
  sans porte ni texte), `C`/`D` Centre, `Q` bouches de la grotte (STEP_ON ↑).
- `tools/build_dark_cave.gd -- --etage=1f|b1f|tous` sur `tools/cave_map_kit.gd` étendu :
  `WALKABLE += "e"`, solides `K` (module « grande colonne »), `w` (flaque bloquante, décalcomanie
  d'eau), `f` (paroi fendue + halo `shaft` / `beam`), `r` (racines), `o` (rocher) ; `PLANS` +=
  `dark_cave_1f`, `dark_cave_b1f` (pour `ladder_links`). Voile précalculé et sol éclairé **comme le
  Mont Sélénite** (profils `cave_*`).
- `tools/build_lavender_town.gd` (modèle `build_cerulean_city.gd`) : pavés `p`, haies `x`, fleurs
  `y`, bancs `n`, arbres repères `G`, emprises de bâtiments (Centre et Boutique 8 × 7 réutilisés,
  Maison des Pokémon 8 × 7 neuve, maisons 7 × 6, Tour 12 × 11).
- `tools/build_painted_interiors.gd -- --rooms=route_10_center,lavender_center,lavender_mart,
  pokemon_house,lavender_house_1,lavender_house_2,pokemon_tower_1f` (pièces **en fin** ; la Tour
  suit `tour_pokemon_rdc.txt` : tombes `g`, comptoir `W`, bancs `n`, chandeliers `b` + halo
  `candle`, escalier `S`).
- `tools/build_cerulean_city.gd` : régénération d'Azuria **après** la fusion du J14 et du J16
  (arbre `k` (53, 23), `warp_est` (55, 22..24) PUSH → → `route_9` / `from_cerulean`, `from_route_9`
  tourné ←) ; test : diff limité à l'arbre, à la clôture et aux warps.

### 4.3 Raccords

Azuria (55, 22..24) PUSH → ↔ Route 9 (0, 22..24) ; Route 9 (79, 12..14) ↔ Route 10 (0, 12..14) ;
Centre de la Route 10 : porte (7..8, 11) ↔ `route_10_center` ; entrée nord (16..17, 7) STEP_ON ↑ →
`dark_cave_1f` / `from_route_10_n` (27..28, 1) ↓ ; 1F (27..28, 0) → `route_10` /
`from_dark_cave_n` (16..17, 8) ↓ ; échelle A 1F (44, 2) ↔ B1F (44, 2), arrivées (44, 3) ; échelle
B B1F (44, 34) ↔ 1F (44, 34), arrivées (43, 34) ; sortie sud 1F (8..9, 48) STEP_ON ↓ → `route_10` /
`from_dark_cave_s` (8..9, 48) ↓ ; entrée sud (8..9, 47) STEP_ON ↑ → `dark_cave_1f` /
`from_route_10_s` (8..9, 47) ↑ ; Route 10 (21..23, 75) PUSH ↓ ↔ Lavanville (21..23, 0) ;
Lavanville : ouest (0, 10..12) `coming_soon = "Route 8"`, sud (21..23, 35) `coming_soon =
"Route 12"` (T-29 : « ROUTE 8 — À venir » / « ROUTE 12 — À venir », mécanisme existant) ; portes
des six bâtiments (spawns `retour_*`) ; Tour : sortie (9..10, 16) PUSH ↓, escalier (17, 2) §0.2
n° 12. Tous les noms de spawn sont ceux des grilles.

### 4.4 Azuria et l'arbre (J16)

Rien de Coupe dans le J18 (§1.2 n° 1). Le texte 17 « On ne passe pas par là pour l'instant. »
reste celui de l'arbre debout **sans** CS01 ; avec la CS01, les textes génériques du J16 (G-2,
G-3). Test (après J16) : `cut_cerulean_east_tree` levé → (53, 23) praticable, warp est atteignable,
Route 9 chargée ; retour de la Route 9 → l'arbre reste coupé (§14).

### 4.5 `caves.json`, Corde Sortie, Tunnel

Entrée `dark_cave` (§2.9) : la Corde Sortie (J12) ramène depuis **les deux étages et les deux
moitiés du 1F** devant l'entrée nord (`route_10` / `from_dark_cave_n`, tourné ↓). Aucun code :
`FieldItemRules.escape_target`. Tunnel hors combat suit la même règle **si** un menu de terrain
existe (dossier 17 §7.4) : rien au J18.

### 4.6 Rencontres (`data/encounters/`, J12 : `rate` 25, rampe 15 → 20)

| Fichier | Table | Terrain | Cartes | Contenu |
|---|---|---|---|---|
| `route_9.json` | `route_9_grass` | `grass` | `route_9` | dossier §3.2 |
| `route_10.json` | `route_10_grass` | `grass` | `route_10` (nord et sud, §4.4 [D]) | dossier §4.4 |
| `dark_cave.json` | `dark_cave_1f_rubble`, `dark_cave_b1f_rubble` | `rubble` | un étage chacune | dossier §5.4 |

Tests : `test_encounter_library` (tables valides), `test_dark_cave_maps` (gravats `g` = tuiles
`RUBBLE` ; **10 cases de gravats** sur le plus court chemin principal entrée nord → sortie sud ;
aucune rencontre sur le sol calme). Information : `tools/simulate_grass_pacing.gd` sur le chemin
principal (combats attendus par traversée).

### 4.7 Dresseurs (14) — données

`data/trainers/route_9.json` (7), `route_10.json` (2), `dark_cave.json` (5) : identifiants des
grilles (§0.2 n° 16), noms « <Classe> <Prénom> » (« Jeune Dresseuse Lou », « Pokémaniac Simon »…),
`ai: random`, `prize_money` du dossier, équipes du dossier (substitutions * comprises), capacités
apprises au niveau (aucune `moves`). PNJ : blocs `trainer` aux cases, orientations et vues des
grilles ; répliques T-42 à T-55 (`before`, `defeated`, `after`) dans `data/dialogues/route_9.json`,
`route_10.json`, `dark_cave.json`. Apparences : classes existantes (`lass`, `camper`, `hiker` /
`mountaineer`, `scout`) + **`pokemaniac`** (nouvelle). Test `tests/unit/test_trainers_j18.gd` :
14 Dresseurs valides ; **aucune capacité en attente** (`pending_effects`) au niveau donné (garde
« Frénésie », §3.3 du dossier) ; aucun Osselait ; récompenses du dossier. Intégration
`test_route_9_trainers` (Lou, Bernard inévitables, autres évitables : recherche de chemin hors des
lignes de vue sur la **vraie scène avec ses PNJ**), `test_dark_cave_trainers` (Roger, Marcel
inévitables), `test_route_10_trainers` (Hector, Paul évitables).

### 4.8 PNJ, examens, textes → données (aucun texte en dur)

| Textes | Fichier | Porté par |
|---|---|---|
| T-1 à T-3 | `data/dialogues/dark_cave.json` | `FlashDirector` (§3.3) |
| T-4 | `data/dialogues/field_moves.json` | Q-1 option B seulement |
| T-5, T-7 | `data/dialogues/route_10.json` | panneau (14, 10) ; randonneur (19, 9) |
| T-6, T-8 à T-10 | `data/dialogues/dark_cave.json` | panneau (26, 2) ; examens colonne, racines (41, 32), paroi fendue (32, 1) |
| T-11 à T-16 | — | **non utilisés** (§0.2 n° 2) |
| T-17 | `data/opening/first_exit.json` (forme liste, §4.11) | légende |
| T-18 à T-29 | `data/dialogues/lavender_town.json`, `lavender_houses.json` | panneaux, habitants, maisons ; T-29 = libellés `coming_soon` |
| T-30 à T-41 | `data/dialogues/pokemon_tower.json` | gardien, visiteurs, Médium, tombes |
| T-42 à T-55 | `route_9.json`, `route_10.json`, `dark_cave.json` (dialogues) | Dresseurs |
| T-56 | `data/story/objectives.json` | objectifs |
| Panneau « ROUTE 9 / Azuria — Route 10 » (§3.1) | `data/dialogues/route_9.json` | panneau (3, 21) |
| Annexe A (descriptions de zones, panneau du Centre) | `zones.json`, `route_10.json` | à valider (Q-5) |

PNJ : `data/npcs/route_9.json`, `route_10.json`, `route_10_center.json`, `dark_cave_1f.json`,
`dark_cave_b1f.json`, `lavender_town.json`, `lavender_center.json`, `lavender_mart.json`,
`pokemon_house.json` (enfant T-25 puis T-26 [D : variante `if` d'un drapeau de session `talked`
existant, sinon les deux pages à la suite], Rondoudou et Nidoran ♀ d'ambiance), `lavender_house_1`
(T-27), `lavender_house_2` (T-28, couple = deux PNJ, même texte), `pokemon_tower_1f.json`.
Pokémon d'ambiance de la Route 9 (`piafabec_1` fuit rayon 2, `racaillou_1` endormi) : mécanisme
existant (`AmbientDirector`). Test `tests/unit/test_dialogue_data` (existant) couvre les nouveaux
fichiers ; test « mot pour mot » : chaque T-x présent une fois, identique au dossier.

### 4.9 Objets

Route 9 : `route_9_item_1` Super Potion (32, 9), `_2` Antidote (29, 25), `_3` Poké Ball ×2 (65, 20) ;
Route 10 : `route_10_item_1` Super Potion (3, 66) ; 1F : `dark_cave_1f_item_1` Corde Sortie
(39, 20), `_2` Antidote (17, 46) ; B1F : `dark_cave_b1f_item_1` Super Potion (21, 18) ;
**caché** `dark_cave_b1f_hidden_1` Super Potion (on se tient en (42, 32), indice (43, 32), §0.2
n° 18 ; système d'objets cachés du J12 présent : la condition du §5.7 est remplie). Drapeaux
`got_<id>`.

### 4.10 Boutique, Centres, points de repos

- `data/shops/lavender_mart.json` : Poké Ball, Potion, Super Potion, Antidote, Anti-Para, Réveil,
  Anti-Brûle, Corde Sortie (I-20 ; aucun objet absent).
- `rest_points.json` : `route_10_center`, `lavender_center` (toast « Point de repos enregistré —
  Route 10 » / « — Lavanville »). Infirmière, terminal de Stockage (modèle de Jadielle).

### 4.11 Légende d'arrivée (OUV.3 généralisé)

`FirstExitCaption` accepte **une liste** (`{ "arrivals": [ {map, from, subtitle}, … ] }`) en plus
de l'objet unique d'OUV.3 (lu à l'identique : aucune régression de Bourg Palette). Entrée :
`{ "map": "lavender_town", "from": "route_10", "subtitle": "La ville où reposent les souvenirs" }`.
Règle inchangée : seulement si la carte n'a **jamais** été découverte et qu'on arrive **depuis**
`from` (jamais à la reprise ni au départ de débogage, sauf départ posé sur la Route 10 sud). Titre :
« LAVANVILLE / La ville où reposent les souvenirs » (T-17). Pas de Grand moment (aucune entrée
`zone_arrivals`). Tests : `test_first_exit_caption` (liste, objet seul, doublons refusés),
intégration dans `test_lavender_town`.

### 4.12 Tour Pokémon (rez-de-chaussée)

- Médium (`channeler`, pose de prière) en (17, 3) ↑, entrée de PNJ `unless: [tower_stairs_open]`
  (drapeau du J19, jamais posé au J18) ; dialogue : 1re fois T-34 + `set: [tower_medium_talked]`,
  ensuite T-35 (`if tower_medium_talked`).
- Gardien (`old_man`, réutilisé) T-30 ; visiteuse T-31 ; visiteur T-32 (deux pages) ; jeune fille
  T-33. Tombes : 5 `InteractPoint` EXAMINER (T-36 à T-40, cases de lecture de la grille), les 31
  autres T-41 (un seul dialogue partagé).
- Bougies : 6 `LightGlow` de type `candle` (nouveau [D] : `lamp` plus pâle, vacillement 0,06).
- **Rien du J19** : aucun Dresseur, combat, spectre, Osselait, drapeau du J19 posé ; test
  `test_pokemon_tower_1f` : escalier inatteignable depuis l'entrée avec la Médium (chemin sur la vraie
  scène), Médium deux fois, objectif, aucun drapeau hors de la liste du §3.6.

### 4.13 Objectifs (`objectives.json`, **en tête**, minuscule initiale §0.2 n° 11)

| id | Texte (T-56) | `if` | `unless` |
|---|---|---|---|
| `tower_later` | « revenir plus tard à la Tour Pokémon. » | `tower_medium_talked` | — |
| `visit_tower` | « visiter la Tour Pokémon. » | `lavender_reached` | `tower_medium_talked` |
| `reach_lavender` | « rejoindre Lavanville, au sud. » | `dark_cave_crossed` | `lavender_reached` |
| `cross_dark_cave` | « traverser la Grotte Sombre. » | `route_10_reached` | `dark_cave_crossed` |
| `cross_route_9` | « traverser la Route 9 vers l'est. » | `route_9_entered` | `route_10_reached` |

Déclencheurs silencieux [D] : `route_9_entered` (Route 9, colonne 1, rangées 22..24) ;
`route_10_reached` (Route 10, colonne 1, rangées 12..14 : le Centre est à 4 cases, « au Centre »
du dossier) ; `dark_cave_crossed` (Route 10, sortie sud, rangée 49) ; `lavender_reached`
(Lavanville (21..23, 1), case `legende_arrivee`). Les objectifs des J16 / J17 arrivent aussi en
tête : ordre réglé à la fusion (le plus avancé dans la progression d'abord). Test
`test_objective_library` : les cinq états.

### 4.14 Zones, Carte, décors de combat, lumière

- `zones.json` : `route_9`, `route_10` (+ `route_10_center`, service `pokemon_center`),
  `dark_cave` (« Grotte Sombre », `kind: place`), `lavender_town` (`town`, + Centre, Boutique,
  maisons, Tour), sous-titres et descriptions de l'**annexe A** (à valider). Aperçus de la Carte :
  `tools/build_zone_previews.gd`.
- `decors.json` : `route_9_roche` (défaut de `route_9` et `route_10`), `dark_cave_galerie` (défaut
  des deux étages) ; Lavanville et Tour : aucun combat. Test `test_battle_stage_decor`.
- `lighting.json` : profils `lavender`, `tower_cold` (en fin) ; `light_glows.json` : `candle`.

### 4.15 Compagnon

Rien de nouveau (J11, J12) : `companions.json` `contexts` += `dark_cave_1f`, `dark_cave_b1f` →
`cave` ; rentre dans les bâtiments ; jamais posé sur une échelle ; masqué dans le passage étroit
(6 cases de 1, B1F) puis de retour. Espèces sans planche (Onix, Voltorbe, Sabelette, Machoc,
Nosferalto) non éligibles (§10.1). Test : `test_dark_cave_maps` liste les goulets d'une case.

### 4.16 Départs de débogage (`tools/debug_start/`, README complété)

Équipe de référence [D, recalée au T22 : sortie du J16 mesurée, starter évolué N24, seconds
N17–19 ; départs de débogage non modifiés] : starter évolué N24, Roucoups N21, Papilusion N20,
Machoc ou Sabelette N19 (compatible Coupe), + un compatible Flash (Pikachu N20 ou Mélofée N20, vérifié
contre les compatibilités générées), Badges Roche, Cascade (et Foudre selon le départ),
`hm01` + `cut_cerulean_east_tree` quand le J16 existe.

| Départ | Contenu |
|---|---|
| `veil_proto_mt_moon` | 18.0 : `mt_moon_1f`, `"veil": "dark"` ; Reptincel compagnon (contraste du héros, bulle) |
| `route_9` | Route 9 ouest (`from_cerulean`), aucun Dresseur battu |
| `route_10_center` | dans le Centre, un Pokémon K.O. (soin, point de repos) |
| `dark_cave_1f` | entrée nord, **sans CS05** : T-3, voile sombre ; `wild` + `terrain: rubble`, taux 60 |
| `dark_cave_1f_flash` | entrée nord, `hm05` + `got_hm05`, compatible Flash **compagnon** : proposition (ou automatique) |
| `dark_cave_1f_no_compat` | `hm05` sans aucun compatible : T-3 |
| `dark_cave_b1f_lit` | B1F, `dark_cave_lit` posé : reprise allumée, sans proposition |
| `dark_cave_weak` | 1F nord, Salamèche N4 seul : perdre contre Roger → Centre, Flash éteinte |
| `dark_cave_rope_qa` | 1F **moitié sud**, 3 Cordes, Flash allumée : Corde → entrée nord, Flash éteinte |
| `route_10_south` | Route 10, sortie sud de la grotte, `lavender_town` non découverte : légende |
| `lavender` / `pokemon_tower_1f` | Lavanville (place) ; devant la porte de la Tour |

### 4.17 Budgets

- ≤ 3 000 nœuds par carte (`NODE_BUDGET`), mesuré **à la première construction** (Route 9 : 80 ×
  36 = 2 880 cases, falaises et forêt : même risque que la Route 3 ; parades du J12 §2.21).
- Mémoire « carte + voisines » ≤ 64 Mo (`tools/measure_map_cache.gd`) : `route_10` précharge
  `route_9`, `dark_cave_1f` et `lavender_town` → mesuré au T12 ; au-delà : préchargement réduit
  à la voisine du point d'arrivée (règle du J12) [D].
- fps (§2.10) ; changement d'étage ≤ 1,5 × Jadielle ; référence Route 1 dans chaque session.

### 4.18 Kit d'assets (série « prochain numéro libre », vérifié sur toutes les branches au T1)

Après validation des vues générales peintes (en cours, autre agent). Réutiliser d'abord (grotte du
J12, centres et boutique, maisons d'Argenta / Azuria, eau du J13). **Nouveaux** : falaises en
terrasses et rampes (Route 9), centrale lointaine, bouches de grotte, grande colonne, paroi fendue,
racines, flaque, sol et parois « Grotte Sombre » (variante plus sombre et plus froide), façades et
pavés de Lavanville, Maison des Pokémon, **Tour (extérieur 12 × 11)**, intérieur de la Tour (tombes,
comptoir, chandeliers, escalier, dalles) ; personnages **Pokémaniac**, **Médium** (`channeler`,
mutualisée avec le J19) ; décors CB.3 `route_9_roche`, `dark_cave_galerie` (« sombre mais lisible »).

---

## 5. Tâches

Chaque tâche : tests verts, import propre, captures relues si c'est visible, `etat-projet.md` dans
le même commit. **Agents** : A = architecte-godot, C = constructeur-monde, U = ui-mobile,
Q = qa-mobile, K = Kevin.

### 5.1 Sous-jalon 18.0 — art, données, voile (« maintenant » sauf mention)

#### T0 — A : plan (ce document)

#### T1 — A : kit d'assets — après les vues générales validées par Kevin
- Fiche `docs/design/fiches-assets/serie-<n>-j18.md`, `tools/art/serie<n>.py` (prompts, références
  recadrées, commandes, planche, manifeste préparé), planche du kit.
- **CA** : chaque élément visible des vues validées a un asset (réutilisé, varié, nouveau) ou est
  abandonné par écrit ; aucun fichier de `game/` touché.

#### T2 — C (Mac, Codex) : génération → planche de contact → K
- **CA** : images validées par Kevin ; journal dans la fiche.

#### T3 — C (Mac) : personnages Pokémaniac, Médium (marche + prière) → K
- **CA** : planches validées ; gardien = `old_man` réutilisé.

#### T4 — C (Mac) : décors CB.3 `route_9_roche`, `dark_cave_galerie`
- **CA** : validés par Kevin sur capture de combat Mac (`tools/capture_combat_cb3.sh`).

#### T5 — K : réponses Q-1 à Q-4, annexe A (Q-5)
- Bloque : la branche « entrée » du T17 (Q-1), le T7 (Q-3), les données de zones (Q-5).

#### T6 — C : intégration de la série — après T2, T3
- Manifeste, `preparer.py` deux fois, `build_painted_props.gd -- --nouveaux`,
  `build_character_frames.gd` (`pokemaniac`, `channeler`, ajouts en fin).
- **CA** : second passage sans changement ; `test_painted_props` vert.

#### T7 — A : le voile d'obscurité (fondation) — **maintenant** (après Q-3)
- §2.2–2.9, §2.12 : `darkness_profile.gd`, `veil_params.gd`, `veil_math.gd`, `darkness_veil.gd`,
  `darkness_controller.gd`, `darkness_veil.gdshader`, `data/world/darkness.json` ;
  `WorldLighting.Z_VEIL` / `Z_ABOVE_VEIL` ; bulle des PNJ et du compagnon en z absolu ;
  `CaveLibrary` : clé `dark`, `is_dark` ; `DebugStart` : clé `veil` ; Boot : création du contrôleur,
  `set_map` dans `_on_map_changed`, `set_reduce_motion` dans `_apply_settings` ; départ
  `veil_proto_mt_moon`.
- Tests : §2.13. **CA** : tests verts ; Mont Sélénite inchangé (diff nul sur ses scènes, captures
  identiques sans clé `veil`) ; aucun des trois noms interdits dans `game/`.

#### T8 — A : mesures du voile — après T7
- §2.11 : `luminance_grotte.py` étendu (seuil hors du halo, plans du J18, fiche `veil`), option
  `--voile` de `tools/capture_mt_moon.gd`, `tools/capture_dark_cave.gd` préparé.
- **CA** : rapport Mac du prototype (sombre, Flash) : seuils tenus ou réglages de `darkness.json`
  proposés ; aucun seuil du J12 modifié.

#### T9 — Q : **session 18.0 (voile)** → K — après T8
- §2.10 sur `veil_proto_mt_moon` (sombre, puis `"veil": "lit"`), référence sans voile.
- **CA** : rapport `build/qa/jalon18_t9/` (fps, captures, réglage de luminosité) ; validation de
  Kevin des valeurs de `darkness.json` (rayons, opacité, battement).

#### T10 — A : scénario de simulation — **maintenant**
- `tools/sim/j18_scenario.json` (format `mt_moon_scenario.json`) : tables §3.2, §4.4, §5.4,
  14 Dresseurs, parcours des grilles (Route 9 107 pas, grotte 179 pas, 10 gravats), variantes
  avec / sans Centre de la Route 10 ; `--valider` signale aujourd'hui Machoc, Miaouss, Super Potion
  (code 3, attendu jusqu'aux fusions J14 / J15).
- **CA** : `--valider` ne signale que ces identifiants ; test `test_simulate_mt_moon` inchangé.

### 5.2 Cartes sans vie (peuvent partir avant la clôture du J17, Q-4)

#### T11 — C : kits — après T6
- `cave_map_kit.gd` (lettres `e K w f r o`, `PLANS`), `pewter_map_kit.gd` (lettres manquantes de la
  Route 9 / 10 s'il y en a). **CA** : Mont Sélénite, Route 3, Route 4 régénérés **identiques**.

#### T12 — C : Route 9, Route 10, Centre de la Route 10 — après T11
- §4.1–4.3 ; cases des PNJ, objets, déclencheurs **réservées** (aucune donnée de PNJ) ; bord ouest
  de la Route 9 `coming_soon = "Azuria"` ; `zones.json` (cartes, services), `interiors.json`,
  `rest_points.json`.
- Tests : `test_route_9` (grille de la scène = grille du plan ; rebords ; raccords), `test_route_10`
  (deux secteurs **non reliés** à pied sur la vraie scène ; eau jamais praticable ; centrale sans
  porte), `test_route_10_center`, `test_map_links`, `test_map_catalog`, `test_coming_soon` ;
  nœuds ≤ 3 000 ; captures relues contre les vues ; `[perf]` Mac ; mémoire.

#### T13 — C : Grotte Sombre 1F et B1F — après T11 (∥ T12)
- §4.2, échelles, halos, profils `cave_*`, `caves.json` (`dark: true`) ; décor `dark_cave_galerie`.
- Tests `tests/integration/test_dark_cave_maps.gd` : grilles = scènes ; échelles A et B **aux
  mêmes coordonnées** sur les deux étages, aller-retour ; graphe : entrée nord → A → B1F → B →
  moitié sud → sortie sud ; **moitiés du 1F non reliées** ; **jamais visibles ensemble** (aucune
  case praticable de l'une dans un rectangle de vue 2340 × 1080 centré sur une case de l'autre,
  ni dans un disque de 9 cases) ; retour à l'entrée nord possible de toute case (à pied ou par les
  échelles) ; `g` = `RUBBLE` ; 10 gravats sur le plus court chemin ; halos 1 à 16 ; aucune
  `Light2D` ; nœuds ≤ 3 000 ; goulets d'une case listés ; passage étroit = 6 cases de 1.
- Captures `tools/capture_dark_cave.gd` + `luminance_grotte.py` sombre et Flash (§2.11).

#### T14 — C : Lavanville, intérieurs, Tour — après T11 (∥ T12, T13)
- §4.1–4.3, §4.12 (carte seule) ; correction des commentaires de `lavanville.txt` (§0.2 n° 9) ;
  `coming_soon` ouest et sud ; escalier de la Tour (§0.2 n° 12).
- Tests `test_lavender_town`, `test_pokemon_tower_1f` (géométrie : escalier atteignable seulement
  par (17, 3)), `test_map_links` ; captures.

### 5.3 Après la clôture du J17 (fichiers chauds)

#### T15 — A : alignement — après la fusion de J14, J15, J16, J17 dans `main`
- Fusion de `main` dans `jalon-18` ; §0.1, §0.3, §1 réalignés sur le code réel (`FieldMoves`,
  `hm05`, section CS, arbre, schéma de `caves.json`, mise en scène de Flash du J17, éclairage du
  J17 s'il existe) ; noms et signatures du §2–§4 corrigés. **CA** : liste des écarts et décisions
  techniques ; aucune décision de game design changée.

#### T15 — répétition sur jalon-17 (2026-10-16)

Branche jetable `j18-essai-sur-j17` = `jalon-18` (4db38f17) + fusion de `origin/jalon-17`
(27e96f21). But : que la vraie T15 soit courte. Le J16 n'y est pas (rien de fusionnable sur
`origin/ccr-fa255d49-wvvacc`).

**Conflits (23 fichiers) et résolution** — règle « garder les deux côtés, le J17 d'abord » :

| Fichier | Résolution |
|---|---|
| `zones.json`, `lighting.json`, `interiors.json`, `companions.json`, `kanto_placeholder_areas.json` | entrées du J17 puis du J18 ; `route_5` en double dans les aires de la carte gardé une fois |
| `caves.json` | `digletts_cave` (« escapes »), `qa_flash` puis `dark_cave` **avec `"dark": true`** |
| `data/battle/decors.json`, `tools/art/combat_decors/decors.json` | les 4 décors (`route_11_coast`, `digletts_cave_rock`, `route_9_roche`, `dark_cave_galerie`) et leurs lieux |
| `assets/world/catalogue.json` | fusion à 3 voies par clé (fichier généré, format identique) |
| `tools/art/manifeste.json` | fusion à 3 voies par élément de liste, blocs recopiés tels quels (format mixte gardé) |
| `painted_prop_rules.gd`, `build_character_frames.gd`, `build_painted_interiors.gd`, `luminance_grotte.py` | ajouts en fin, J17 puis J18 |
| `test_cave_library` | `[mt_moon, digletts_cave, qa_flash, dark_cave]` |
| `test_lighting_library` | `… cave_sand, lavender, tower_cold` |
| `test_zone_library` | 33 zones |
| `test_encounter_library` | 20 tables, identifiants triés |
| `test_painted_props` | listes des séries 19 et 21 |
| `test_map_links` | cartes J17 + J18 ; « à venir » = **10** (7 du J17 + Azuria 3) |
| `test_cutscene_data` | objets J17 + J18 (liste triée), `… + J18_IDS` |
| `test_dialogue_data` | `UNUSED_YET` du J18 + `J17_TOKENS` / `DRAFT_VARIANTS` ; `IDS_J17 + IDS_J18` ; objets lancés **57** (41 + 8 J17 + 8 J18) ; dossiers 20 et 21 tous deux lus pour le « mot pour mot » |
| `etat-projet.md` | en-tête « Mis à jour » réuni |
| `tools/cave_map_kit.gd` (**fusion automatique fautive**, sans marqueur) | `wall_faces` / `wall_side` / `wall_lip` ajoutés par les deux jalons (J18 T11, J17 T15) → déclarés deux fois, erreur d'analyse (`tools/` n'est pas importé : vue seulement par la suite, `test_serie14_assets` en échec, `test_cave_map_kit` et `test_j18_map_kits` ignorés) ; un seul bloc gardé |
| `test_dialogue_data` (2e passe) | virgule restée après la condition J17 du « mot pour mot » (`annex_a_17…),`) : fichier ignoré par GUT, corrigé |

**Suite complète** (copie jetable, b988203c) : 5 250 / 5 250, `test_dialogue_data` ignoré
(erreur d'analyse ci-dessus), puis seul après correction : 23 / 23. Import propre.

**Hors conflit, aligné** : `dark_cave_too_dark` (T-3) était défini **deux fois** (J17
`dark_caves.json`, J18 `dark_cave.json`, même texte, le J18 avec un retour à la ligne) → gardé
celui du J17, retiré du J18 (et de `UNUSED_YET` / `IDS_J18` : il est dans `PLAYED_BY_BOOT`).

**Écarts de noms entre le §3 et le code du J17** (le code du J17 fait foi) :

| Plan J18 | Code J17 |
|---|---|
| `Entry { NONE, OFFER, AUTO, WARN }` | `{ NONE, AUTO, WARN }` (Q-1 : « tout J17 », automatique) |
| `entry_action(from, to, caves, flags, available)`, `is_cave_entry`, `lit_flag`, `flags_to_clear` | `entry_action(from, to, caves, available)`, `is_entry(from, to)` (toute arrivée, étage compris), `is_lit(from, to, caves, available)` ; **aucun drapeau `dark_cave_lit`** ni règle d'extinction (§3.4 et la ligne `dark_cave_lit` du §3.6 tombent) |
| `FlashDirector.setup(runner, darkness, caves, field_moves, data)`, `use_here`, `pokemon_name`, action `use_flash` | `setup(state, darkness, caves, field_moves, hud, runner, library, player, …)`, rappels `check_flash` / `can_start`, signaux `cue_started`, `flash_used` ; pas d'action de dialogue |
| `game/pokemon/field_moves.gd`, `data/pokemon/field_moves.json`, `can_use` / `user_for` | `game/world/field/field_moves.gd`, `data/world/field_moves.json`, `check(...) -> FieldMoves.Result`, `cue_text` (T-2 = « cue » de `flash`) |
| `dark_cave_flash_offer` (T-1), `dark_cave_flash_used` (T-2) | sans objet (pas de proposition ; T-2 = bandeau du HUD) |
| `DarknessController`, `DarknessVeil`, `VeilMath`, `VeilParams`, `darkness.json` | mêmes noms ; `DarknessProfile` (et non `DarknessConfig`) ; `HaloFloorLight` en plus |

**Vérifié** : `test_dark_cave_maps` (Grotte obscure, Mont Sélénite jamais) et
`test_dark_cave_flash` (vrai Boot) : sans Flash → voile sombre + T-3 une fois ; CS05 + Pikachu
→ AUTO, « Pikachu utilise Flash ! », halo ouvert ; échelle 1F → B1F → rallumée ; Corde Sortie
depuis le B1F → `route_10` sur `from_dark_cave_n_w`, tourné ↓, voile retiré ; Mont Sélénite avec
CS05 : ni voile, ni Flash, ni avertissement.

**Luminance sous le voile** (`tools/capture_dark_cave_voile.sh` + `luminance_grotte.py --halo`,
étendu aux deux étages ; réglages communs du J17 **inchangés**) :

| Vue | héros | sol hors halo (sombre) | sol hors halo (Flash) |
|---|---|---|---|
| couloir 1F (27, 10) | **2,96** | **0,063** | **0,087** |
| galerie 1F (30, 15) | 3,87 | **0,049** | **0,060** |
| flaque B1F (22, 28) | 3,58 | **0,098** | **0,096** |
| passage B1F (37, 34) | 3,07 | **0,090** | 0,100 |

Seuils : héros ≥ 3,0, hors halo ≥ 0,10 (`qa_flash` : 0,106–0,145). Le sol de la série 21 est
plus sombre : 7 vues sur 8 en échec. Propositions [D], sans toucher à `darkness.json` commun :
(a) éclaircir le sol de la série 21 (`ground_grotte_sombre_01` : gamma / contraste du manifeste)
et les profils `cave_1f` / `cave_b1f` de la Grotte Sombre seule (profils propres
`dark_cave_1f` / `_b1f` dans `lighting.json`) ; (b) à défaut, une surcharge d'opacité par grotte
(`caves.json` → `"veil": { "outside": … }`, lue par `DarknessProfile`), ≈ 0,30 sans Flash. Le héros
à 2,96 (couloir, sol clair sous la lueur `floor_lift`) passe avec (a). À trancher à la T20.

**À refaire à la vraie fusion** : rejouer cette fusion sur `main` (J16 + J17) ; J16 : arbre
d'Azuria (53, 23), `cut_cerulean_east_tree`, régénération d'Azuria (variante J18, warp est →
`route_9`), « à venir » 10 → 7 dans `test_map_links`, section CS / `field_moves.json` (`cut`) ;
retrait de `qa_flash` (T28 du J17) → `test_cave_library` et `luminance_grotte.py` (`PLAN_QA`) ;
§1.3, §3 et §3.6 du plan à réécrire selon le tableau ci-dessus ; réglage de luminance (a) ou (b).

#### T15 — FAIT (2026-10-19, branche `jalon-18-integ` depuis `j18-essai-sur-j17` à 5e966549)

Fusion de `origin/main` (aebbd857 : J16, PR n° 1 « Boot découpé », J17 terminé). Règle
d'ancienneté : le J16 et le J17 font foi (brique voile / Flash, découpage de Boot, `darkness.json`).

**Conflits (25 fichiers)**, « les deux côtés, le plus ancien d'abord » : `zones.json` (34 zones),
`lighting.json`, `interiors.json`, `decors.json` (jeu et outil), aires de la carte,
`painted_prop_rules.gd`, `build_character_frames.gd`, `build_painted_interiors.gd`, README des
départs ; `objectives.json` : les cinq objectifs du J18 **en tête**, puis ceux du J16 ; `caves.json` :
`qa_flash` retirée (J17 T28), `dark_cave` gardée (`dark`, `escape` → `route_10` /
`from_dark_cave_n_w`) ; `catalogue.json` et `manifeste.json` : fusion à trois voies par clé, format de
`main` (aucun conflit réel) ; `luminance_grotte.py` : `PLANS` de `main` (la Grotte Sombre y est) ;
`etat-projet.md` : version dédoublonnée de `main` + sections du J18, une seule ligne « Mis à jour » ;
tests : objectifs, zones, grottes, objets peints, cartes (« à venir » = 3), scènes, dialogues (objets
lancés 71, `FUTURE_FLAGS` = `tower_stairs_open`). Aucune déclaration en double après la fusion
automatique (vérifié sur les 93 scripts touchés), aucune clé JSON en double. Boot : le J18 n'y
touchait pas (aucun conflit avec `SaveCoordinator` / `SettingsApplier` / `SessionLifecycle`).

**Raccord Azuria ↔ Route 9 (I-2, §4.4)** : Azuria construite sur la variante `J18` de la grille ;
arbre à couper (53, 23) = [FlagGate] `unless cut_cerulean_east_tree` (objet
`prop_jeune_arbre_arene_01`, comme les arbustes du J16 / J17), la grande clôture verticale remplacée
par deux pans courts (53, 22) et (53, 24) ; warps (55, 22..24) → `route_9` /
`from_cerulean_n|from_cerulean|from_cerulean_s`, spawns `from_route_9_n|from_route_9|from_route_9_s`
(rangée pour rangée, comme la Route 10) ; Route 9 régénérée (bord ouest réel). Examen
`cerulean_closed_exit` à variantes « field » : texte 17 sans CS01, textes du J16 sinon ; scène
`cut_tree_cerulean_east`. Départ `cerulean_east_cut`, test `test_cerulean_east_tree`.

**Luminance sous le voile** (réglages définitifs du J17, `darkness.json` inchangé ; aucun réglage
propre au J18 nécessaire) :

| Vue | héros | hors halo (sombre) | hors halo (Flash) |
|---|---|---|---|
| couloir 1F (27, 10) | 4,44 | 0,124 | 0,160 |
| galerie 1F (30, 15) | 5,26 | 0,118 | 0,148 |
| flaque B1F (22, 28) | 4,55 | 0,154 | 0,173 |
| passage B1F (37, 34) | 4,69 | 0,144 | 0,166 |

Les propositions (a) / (b) de la répétition tombent.

#### T16 — A : données — après T15 (et Q-5)
- §4.6–4.10, §4.13, §4.14 (descriptions), §3.1 (dialogues) : Dresseurs, rencontres, Boutique,
  dialogues (T-x **mot pour mot**), objectifs, zones, décors, compagnon ; `hm05` si absent (§1.4).
- Tests : `test_trainers_j18`, `test_encounter_library`, `test_shop_library`, `test_dialogue_data`,
  « mot pour mot », `test_objective_library`. **CA** : `simulate_mt_moon.gd -- --valider` sur le
  scénario du J18 : code 0.

#### T17 — A : moteur de Flash — après T15 (∥ T16) ; branche « entrée » après Q-1
- §3.2–3.5 : `FlashRules`, `FlashDirector`, `FieldMoves` (`flash`, ou création minimale §1.4),
  section CS de `gen_tm_compatibility.py` si absente, action `use_flash`, jeton `{pokemon}`,
  branchements Boot ; `FirstExitCaption` en liste (§4.11).
- Tests : `test_flash_rules`, `test_field_moves`, `test_first_exit_caption`, `test_dialogue_library`
  (action), `test_save_j18`. **CA** : tests verts ; Bourg Palette (OUV.3) inchangé ; Mont Sélénite
  sans voile ni proposition.

**État au T15 (2026-10-19)** : le moteur est **celui du J17** (`FlashRules`, `FlashDirector`,
`FieldMoves` dans `data/world/field_moves.json` avec `flash` / `cue`, section CS de
`tm_compatibility.json`, AUTO / WARN, T-3 joué par Boot) ; le J18 n'en avait **aucun doublon** dans
`game/` (la répétition avait déjà retiré `dark_cave_too_dark`). `FirstExitCaption` en liste : fait au
T24. Grottes branchées : `dark_cave` (`dark: true`, Corde Sortie → `route_10` /
`from_dark_cave_n_w`) ; `test_dark_cave_flash` (vrai Boot) repart de `dark_cave_1f_flash.json`.
Tombent avec Q-1 « tout J17 » : action `use_flash`, `dark_cave_lit` et ses règles d'extinction
(§3.4), `test_save_j18` (aucun état nouveau, §3.6). **Reste** : rien de code ; §1.3 et §3 sont à lire
avec le tableau « Écarts de noms » de la répétition du T15.

#### T18 — C : la vie de la Route 9, de la Route 10 nord et du Centre (18A) — après T12, T16
- PNJ, Dresseurs, Pokémon d'ambiance, objets, panneaux, rencontres, déclencheurs, objectifs ;
  régénération d'Azuria (arbre, warp) **si le J16 est fusionné**, sinon §1.4 ; départs `route_9`,
  `route_10_center`.
- Tests `test_route_9_life`, `test_route_9_trainers`, `test_azuria_cut_tree` (si J16).
  **CA** : tests verts, captures relues.

#### T19 — Q : **session 18A** → K — après T18 et la validation de 18.0
- Azuria → Route 9 (arbre coupé, retour), Lou et Bernard inévitables, autres évitables, rencontres,
  objets, Centre (soin, toast, défaite → Centre), objectif ; fps, mémoire, durée de traversée
  (≈ 6 min). **CA** : rapport `build/qa/jalon18_t19/` ; validation de Kevin.

#### T20 — C : la vie de la grotte (18B) — après T13, T16, T17
- Dresseurs, gravats, objets visibles et caché, panneau, examens T-8 à T-10, Corde au sol, voile
  et Flash sur les vraies cartes, départs `dark_cave_*`.
- Tests `test_dark_cave_flash` (§6), `test_dark_cave_trainers`, `test_escape_rope` (étendu à la
  Grotte Sombre), `test_hidden_items` (B1F). **CA** : tests verts ; luminance Mac tenue (§2.11).

#### T21 — U : relecture d'interface de la grotte — après T20 (∥ T22)
- Captures relues : proposition OUI / NON (ou bandeau automatique), T-2 / T-3, bulle « ! » au-dessus
  du voile, titre « GROTTE SOMBRE » puis dialogue (délai). Si Q-1 = B : bouton **FLASH** sur la
  carte d'un Pokémon compatible dans l'Équipe (dossier 08), refus T-4. **CA** : captures 2340 ×
  1080 relues ; fichiers d'interface seuls touchés.

#### T22 — A : équilibrage — après T20
- `simulate_mt_moon.gd -- --donnees` avec le scénario du J18, équipes de sortie du J16 **et** du J17
  (I-12) ; cible du J12 (joueur attentif sans défaite ≥ 85 %, aucun combat > 40 % de défaites) ;
  ajustements limités aux valeurs [D] du dossier (niveaux ±1–2, récompenses suivent). **CA** :
  chiffres dans le plan ; aucune valeur [V] changée sans Kevin.

**Fait (2026-10-16, branche `j18-t22-equilibrage`)** — règle de Kevin du 2026-10-16, prioritaire
sur la cible du J12 : **victoire au premier essai de 60 à 80 % par combat** (60 = plancher, 80 =
plafond) pour un joueur prudent qui va droit au but avec son Sac et le Centre de la Route 10 ;
exception : un taux élevé qui vient d'un **avantage de type choisi par le joueur** reste tel quel ;
jamais adoucir au-delà de 80 % sans Kevin.

*Mesure.* `tools/sim/j18_scenario.json` refait (`--donnees --seeds 500`, ≈ 4 min en 11 processus ;
rapports bruts non versionnés `build/sim/j18_t22/`). Joueur attentif, Sac [D] 3 Potions,
2 Super Potions, 2 Antidotes, départ soigné à Azuria, Centre de la Route 10. Chaque variante a des
reprises (réveil au dernier Centre) : le **premier essai** d'un Dresseur est son premier combat dans
la partie, même après une défaite ailleurs (plus de biais du survivant). Chemin direct pour Lou,
Benoît, Roger, Marcel ; chaque évitable est mesuré seul (« détour <nom> » = chemin direct + lui, à
sa place, sans soin de plus). Outil : `simulate_mt_moon.gd` soumet désormais la capacité imposée
(tour 2 de Tunnel, Patience) — avant, l'équipe « type Kevin » finissait ses combats « non
terminés » (8 % de « victoires » contre Marcel) ; ligne « premier essai » par Dresseur (reprises).

*Équipes.* **Sortie du J16** (référence de la règle : on va droit au but, le J17 est facultatif) =
équipes de référence du J17 (Carmin avant le S.S. Anne) + le gain d'un chapitre, mesuré en jouant
la Route 11 et la Cave (le J16 n'a pas encore de données) : seul le meneur progresse (+2,4) →
Reptincel 24 + Roucoups 19, Férosinge 19, Mystherbe 18 (R) ; **type Kevin** Reptincel 24 (Tunnel),
Roucoups 19, Nidorino 18, Rattata 17 (K) ; Herbizarre 23, Roucoups 18, Papilusion 18 (H) ;
Carabaffe 24, Roucoups 19, Papilusion 17 (C). **Sortie du J17** (J16 puis J17) : meneur 25–27,
mêmes seconds. Les équipes du T10 (seconds à 21–22) surestimaient les seconds de 2–3 niveaux ;
leurs « bas » restent en information.

*Cibles et exceptions [D].* Montagnards (Benoît, Gilles, Roger, Marcel, Paul) : équipe K seule
(R a Férosinge et Mystherbe, H une Plante, C de l'Eau : avantage de type choisi). Lou (Plante /
Poison) et Noa (Insecte / Poison) : exception pour toutes les équipes (Roucoups, Feu, Psy
contre eux dans chaque équipe de référence) → inchangés. Autres : moyenne de R, K, H, C.

| Dresseur | Avant → après (niveaux, ₽) | Cible | Avant | Après | R · K · H · C après |
|---|---|---|---|---|---|
| Lou (inévitable) | 18 ×4, 360 — inchangé | exception | 100 | 100 | 100 · 100 · 100 · 100 |
| Adam | 20 / 21, 420 — inchangé | moyenne | 100 | 100 | 100 · 100 · 100 · 100 |
| Jules | 19 ×3 → **26** ×3, 380 → 520 | moyenne | 100 | **79** | 92 · 84 · 67 · 72 |
| Noa | 19 ×2, 228 — inchangé | exception | 100 | 100 | 100 · 100 · 100 · 100 |
| Benoît (inévitable) | 20 / 20 → **25 / 23**, 700 → 805 | K | 99 | **81** | 100 · 81 · 97 · 95 |
| Zoé | 23 → **26**, 460 → 520 | moyenne | 99 | **90** | 98 · 62 · 99 · 100 |
| Gilles | 20 ×3 → **16** ×3, 700 → 560 | K | 67 | **40** | 100 · 40 · 99 · 100 |
| Roger (inévitable) | 19 ×4 → **20 / 21 / 20 / 20**, 665 → 700 | K | 98 | **79** | 100 · 79 · 100 · 100 |
| Simon | 23 / 23 → **26 / 26**, 1 150 → 1 300 | moyenne | 98 | **85** | 64 · 76 · 100 · 100 |
| Elsa | 19 ×4 → **22** ×4, 380 → 440 | moyenne | 97 | **80** | 62 · 67 · 92 · 98 |
| Marcel (inévitable) | 20 ×3 → **17** ×3, 700 → 595 | K | 73 | **62** | 90 · 62 · 100 · 100 |
| Yanis | 21 / 21 → **21 / 26**, 1 050 → 1 300 | moyenne | 94 | **79** | 53 · 73 · 91 · 100 |
| Hector | 20 / 20 → **26 / 26**, 1 000 → 1 300 | moyenne | 97 | **82** | 60 · 74 · 94 · 98 |
| Paul | 21 / 21 → **19 / 19**, 735 → 665 | K | 55 | **65** | 80 · 65 · 100 · 100 |

(% de victoire au premier essai, équipes de sortie du J16 ; « Avant » = données du T16 mesurées
de la même façon ; écart-type ≈ 2 points.) Sortie du J17 : Benoît 95, Roger 96, Marcel 92, Gilles
80 pour K ; Simon 78–100, Yanis 63–100, Jules 77–98 (le J17 fait = un chapitre d'entraînement).

*Traversée* (Lavanville sans aucune défaite, chemin direct, attentif) — avant → après : R 86 → 88,
**K 69 → 36**, H 99 → 97, C 100 → 95 ; sortie du J17 : K 96 → 85 ; expert : K 59 → 35 ; naïf :
R 57 → 44, les autres 0–9 → ≤ 1 % ; « bas » Reptincel 22 : 1 % (inchangé). Tous les Dresseurs sans
défaite : 0 % partout pour la sortie du J16 (avant 1–22 %) ; avec reprises, toutes les parties
arrivent. Niveaux à Lavanville (chemin direct, sans défaite) inchangés : meneur 24–26, seconds 17–19.

*Constats.*
- Un combat isolé, équipe soignée, reste à ≥ 94 % même 4 à 8 niveaux plus haut (Gilles soigné
  après le Centre : 94–99 % au Nv. 24 ; Hector soigné : ≥ 92 % au Nv. 28) : la difficulté vient de
  l'**usure en chaîne** (pas de Centre entre Lou et Benoît, ni entre Roger et Marcel). Durcir un
  Dresseur fait baisser les suivants : Roger plus fort → Marcel adouci (20 → 17) pour rester ≥ 60 ;
  Benoît plus fort → Gilles à 40 % pour K **même au Nv. 16** (son niveau pèse ≈ 4 points par niveau).
- Racaillou Nv. ≥ 21 apprend Destruction : aléatoire (l'IA `random` se sacrifie), courbe non
  monotone ; tous les Racaillou restent ≤ Nv. 20 ; seul le Machoc de Roger passe au Nv. 21.
- Plafond de niveau [D] : **Nv. 26** (référence du J16 + 2 ; Major Bob : Raichu 24) ; Salamèche
  ≤ 21, Onix et Dardargnan ≤ 24 (Frénésie au-delà, capacité en attente).
- Écart entre équipes : H et C restent ≥ 90 % sur Zoé, Simon, Hector, Yanis (sans avantage de
  type net) pendant que R descend à 53–64 % ; viser 80 pour H / C mettrait R et K sous 40.

*Hors règle, à arbitrer par Kevin* (§ « Questions » de `etat-projet.md`) : Adam 100 % (deux
Pokémon, Salamèche plafonné au Nv. 21 ; Férosinge 28 : encore 89–95 %) ; Zoé 90 % (un seul
Miaouss, au plafond 26) ; Simon 85 % (plafond 26) ; Gilles 40 % pour K (sous le plancher, usure de
Benoît) ; Yanis 53 % et Hector 60 % pour R ; Lou et Noa laissés à 100 % au titre de l'exception
de type ; traversée de K à 36 %. Leviers possibles, non appliqués : dépasser le plafond (Nv. 28–30),
changer un Pokémon (Salamèche → Reptincel pour Adam, second Pokémon pour Zoé), ou un soin de plus
(Centre d'Azuria après Lou, retour au Centre après Roger) dans la définition du « joueur prudent ».
Tests : `test_trainers_j18`, `test_route_9_trainers`, `test_dark_cave_trainers`, `test_route_10_life` aux nouvelles
valeurs ; `test_simulate_mt_moon` inchangé.

#### T23 — Q : **session 18B** → K — après T21, T22 et la validation de 18A
- Luminosité moyenne, **sans puis avec Flash** : repères reconnus, gravats vus avant d'y marcher,
  Dresseurs qui sortent de l'ombre, bulle « ! », échelles, Corde (moitié sud → entrée nord),
  défaite (Centre, Flash éteinte), reprise allumée / éteinte, « Réduire les animations », fps
  (§2.10), durée (≈ 6 min 50 sans Flash). **CA** : rapport ; validation de Kevin.

#### T24 — C : Route 10 sud, Lavanville, Tour (18C) — après T14, T16, T17
- PNJ, Dresseurs Hector et Paul, objets, légende, objectifs, Boutique, Centre, maisons, Tour (§4.12),
  sorties « À venir » ; départs `route_10_south`, `lavender`, `pokemon_tower_1f`.
- Tests `test_route_10_life`, `test_lavender_town` (légende une fois, jamais à la reprise),
  `test_pokemon_tower_1f`. **CA** : tests verts, captures.

#### T25 — Q : **QA finale 18C** → K, fusion — après T24 et la validation de 18B
- Vraie partie (ou départs enchaînés si Kevin le décide, comme au J13) Azuria → Route 9 → Route 10 →
  grotte → Lavanville → Tour, **avec et sans Flash** ; sauvegardes à chaque étape, dont dans la
  grotte Flash allumée ; retours en arrière ; rien du J19 déclenché. **CA** : rapport ; validation ;
  fusion dans `main` (`project.godot` et filtre d'export vérifiés) ; prévenir la session du J19.

#### T26 — A : clôture et passation au J19
- Critères du §5.5 un par un ; passation : gardienne (`tower_stairs_open`, `channeler`), escalier
  `coming_soon`, emplacement du panneau du Scope (case de pelouse du parvis au choix du J19), maison
  d'Osselait absente, Route 8 « À venir », Machopeur / Électrode absents (§0.2 n° 15), dos
  provisoires.

### 5.4 Ordre et parallélisme

```
Art      : T1 ─→ T2 ─→ T6 ; T3 ─→ T6 ; T4                    (après les vues peintes)
Voile    : T7 ─→ T8 ─→ T9 (téléphone 18.0)                    (maintenant, après Q-3)
Simul.   : T10                                                (maintenant)
Cartes   : T11 (après T6) ─→ T12 ∥ T13 ∥ T14                  (avant la clôture du J17, Q-4)
Moteur   : [clôture J17] ─→ T15 ─→ T16 ∥ T17
18A      : T18 (T12, T16) ─→ T19
18B      : T20 (T13, T16, T17) ─→ T21 ∥ T22 ─→ T23 (après T19)
18C      : T24 (T14, T16, T17) ─→ T25 (après T23) ─→ T26
```

**Démarrables tout de suite, malgré l'absence du J16 (et du J17)** : T7 (voile, dès Q-3), T8, T9,
T10 ; T1–T4 dès les vues peintes validées ; T5 (Kevin) ; puis T11–T14 (cartes sans vie, Route 9
fermée à l'ouest par `coming_soon`). **Seul le raccord Azuria ↔ Route 9 attend le J16** ; **seule
la source de Flash dans la vraie partie attend le J17**.

### 5.5 Critères d'acceptation par sous-jalon

**18.0** — planches, décors CB.3 et kit validés par Kevin ; voile mesuré sur Mac (seuils §2.11) et
sur téléphone à luminosité moyenne (écart ≤ 2 fps, moyenne ≥ 58, creux ≥ 50) ; valeurs de
`darkness.json` arrêtées par Kevin ; Mont Sélénite inchangé ; tests verts, import propre.

**18A** — raccord Azuria ↔ Route 9 sur trois rangées (si J16) et arbre définitif ; Lou et Bernard
impossibles à contourner, autres évitables ; rencontres §3.2 ; 3 objets ; Pokémon d'ambiance ;
Centre (soin, toast, point de repos, défaite → Centre) ; objectifs « traverser la Route 9 vers
l'est. » puis « traverser la Grotte Sombre. » ; rivière et centrale visibles, inaccessibles, sans
texte ; traversée ≈ 6 min ; budgets.

**18B** — à luminosité moyenne : relief lisible hors du halo, jamais de noir total ; halo ≈ 2,5
cases sans Flash, ≈ 7 avec ; repères reconnus ; gravats toujours vus avant d'y marcher, rencontres
seulement sur gravats ; Dresseurs voilés, bulle « ! » au-dessus, sortie de l'ombre ; Roger et Marcel
inévitables ; Flash selon Q-1, une fois par entrée, durable entre étages, éteinte à la sortie
(pied, Corde, défaite) ; T-3 une fois sans Flash ; Corde depuis partout → entrée nord ; reprise
dans la grotte allumée / éteinte ; « Réduire les animations » ; compagnon (passage étroit, échelles) ;
collisions identiques avec et sans Flash (test) ; budgets.

**18C** — légende « LAVANVILLE / La ville où reposent les souvenirs » une seule fois ; habitants,
maisons, Maison des Pokémon (Fuji absent, sans alarme) ; Boutique (8 objets) ; Centre ; Tour :
tombes, visiteurs, gardien, Médium deux fois, escalier fermé, objectif « revenir plus tard à la
Tour Pokémon. » ; Routes 8 et 12 « À venir » (développement) ; QA de bout en bout avec et sans
Flash ; aucun drapeau ni contenu du J19 ; sauvegarde à la version de `main` ; `tools/test.sh` vert.

---

## 6. Cas limites du dossier §14 → tests

| Cas (dossier 21 §14) | Test |
|---|---|
| Entrer sans Pokémon compatible, avec la CS05 | `test_flash_rules` (indisponible → WARN) ; `test_dark_cave_flash` : départ `no_compat`, T-3 une fois, aucun choix |
| Compatible K.O. : Flash utilisable | `test_field_moves` (K.O. compatible) ; `test_dark_cave_flash` |
| Déposer le compatible après Flash | impossible dans la grotte (aucun terminal) ; `test_flash_rules.flags_to_clear` : toute carte hors grotte (Centre compris) éteint ; noté, pas de test de dépôt |
| Défaite dans la grotte → dernier Centre, Flash éteinte | `test_dark_cave_flash` (départ `weak`, réveil au Centre, drapeau absent, voile caché) |
| Corde Sortie depuis la moitié sud → entrée nord | `test_escape_rope` (1F nord, 1F sud, B1F → `from_dark_cave_n` ↓, drapeau effacé) |
| Reprise d'une sauvegarde dans la grotte, allumée / éteinte | `test_save_j18` + `test_dark_cave_flash` (reprise : voile selon le drapeau, sans animation ; éteinte et disponible → proposition une fois) |
| Dresseur qui voit le joueur depuis l'ombre | `test_darkness_veil` (bulle z 21) ; `test_dark_cave_trainers` (Roger : `VeilMath.alpha_at` > 0,3 sur sa case au moment du « ! », < 0,05 sur sa case d'arrivée) ; capture |
| Compagnon dans le passage étroit | `test_dark_cave_maps` (goulet listé) ; `test_companion_controller` (masqué puis de retour, règle du J11) |
| « Réduire les animations » | `test_darkness_veil` (battement 0, ouverture dans le même appel) |
| Route 9 avant le Badge Foudre | `test_trainers_j18` / `test_dialogue_data` : aucune condition sur un badge de Major Bob dans les données du J18 ; départ `route_9` sans ce badge joué en 18A |
| Revenir à Azuria depuis la Route 9 : l'arbre reste coupé | `test_azuria_cut_tree` (après J16) |
| Médium deux fois ; passer à côté | `test_pokemon_tower_1f` (T-34 puis T-35 ; aucun chemin vers (17, 2)) |
| Les deux moitiés du 1F ne se voient jamais | `test_dark_cave_maps` (rectangle de vue et disque de 9 cases) |
| Collisions identiques avec ou sans Flash (V2, risque n° 1) | `test_dark_cave_flash` : `GridWorld` de la carte identique avant / après OUI ; le voile n'a aucun nœud de collision |

---

## 7. Risques et points à trancher

### 7.1 Risques

| Risque | Effet | Parade |
|---|---|---|
| **Flash contradictoire entre J17 et J18** (§0.2 n° 1) | deux codes, ou un code qui trahit un dossier | Q-1 avant le T17 ; tout le reste en est indépendant |
| **Deux fondations d'éclairage** (J17 H-8, J18 18.0) | travail perdu, conflit à la fusion | Q-3 ; contrat du §1.3 transmis à la session du J17 |
| **J16 non conçu** (pas de dossier 19) | arbre d'Azuria, registre, section CS absents | contrat minimal §1.2 ; plan B §1.4 ; seul le raccord Azuria attend |
| **Quatre jalons pas encore dans `main`** (J14–J17) | données citées refusées, fichiers chauds en conflit | données hors de `data/` jusqu'aux fusions ; code chaud après la clôture du J17 ; ajouts en fin (§1.5) |
| **Lisibilité dans le noir sur téléphone** | grotte injouable sans Flash, ou pas assez sombre | prototype mesuré au 18.0 sur le vrai décor ; seuils Mac ; valeurs en données ; validation à luminosité moyenne |
| **Coût du voile** (passe plein écran) | fps | 1 rectangle, aucune texture, ≤ 17 distances ; mesuré contre une référence sans voile |
| **Bulle « ! » au-dessus des cimes partout** | rendu légèrement différent hors grotte | capture Route 3 ; règle 3 (rendu provisoire) |
| **Budget de nœuds de la Route 9** (80 × 36, relief) | fps, budget dépassé | mesure au premier passage du T12 ; parades du J12 |
| **Mémoire de la Route 10** (trois voisines lourdes) | creux, chargements lents | mesure ; préchargement réduit (règle du J12) |
| **Régénération d'Azuria après J14 et J16** | diff inattendu, conflit | régénérer en dernier (T18), diff limité à l'arbre et aux warps |
| **Machoc sauvage sans évolution** (§0.2 n° 15) | un Machoc N28 n'évolue pas | Q-2 ; passation |
| **Fermeture pendant l'ouverture de Flash** | drapeau posé, animation perdue | le drapeau est posé au OUI (`confirm_set`) ; la reprise allume sans animation |

### 7.2 Questions pour Kevin

> **Tranchées par Kevin le 2026-10-15** (« 1 ok, 2 ok, vues ok avec grotte r3, art ok ») : **Q-1 option A**
> (Flash comme le dossier 20 : automatique à l'entrée, aussi en combat ; T-1, T-4 et le §8 du dossier 21
> abandonnés ; le §3 ci-dessous se lit avec `entry_action` = allumage automatique ou avertissement T-3,
> sans proposition — le code de Flash est fait par le J17, T24, sur ce contrat) ; **Q-2** oui ; **Q-3**
> une seule brique, codée par le J17 (`origin/jalon-17`, relue conforme) ; **Q-4** oui ; **Q-5** textes
> A-1 à A-9 validés.

- **Q-1 — Flash à l'entrée de la grotte, et en combat (vraie contradiction entre deux dossiers
  verrouillés).** Dossier 20 (J17) : H-6 Flash s'apprend **aussi** pour le combat (CS réutilisable,
  comme Coupe G-2), H-7 Flash **automatique** à l'entrée, « pas de menu, pas de bouton ». Dossier 21
  (J18) : I-3 « n'existe pas en combat », I-5 « Utiliser Flash ? » **OUI / NON** à l'entrée puis
  « par le menu des capacités de terrain du J16 » — menu qu'aucun jalon ne conçoit.
  *Recommandation* : **combat : garder H-6** (cohérent avec Coupe ; le J18 n'y touche pas, et
  I-3 se lit « le Flash de terrain n'occupe aucun emplacement ») ; **entrée : option A**.
  - **A — automatique (H-7)** : avec Flash disponible, « {pokemon} utilise Flash ! » et le halo
    s'ouvre à chaque entrée ; sans Flash, T-3. Aucun menu. T-1 et T-4 inutilisés. Le plus simple,
    et le J17 l'a déjà mis en scène ; mais un joueur qui a Flash ne traverse jamais le noir.
  - **B — proposition + rattrapage** : T-1 à l'entrée ; après NON, un bouton **FLASH** sur la
    carte d'un Pokémon compatible dans l'Équipe (dossier 08 à compléter), T-4 ailleurs. Fidèle à
    I-5 ; coûte une entrée d'interface nouvelle (U, T21) qui servira ensuite à Tunnel.
  - **C — proposition sans rattrapage** : T-1 à l'entrée ; NON = sans Flash jusqu'à la prochaine
    entrée. Pas de menu ; un NON par erreur oblige à ressortir.
- **Q-2 — Machoc sauvage sans évolution.** Le J14 a omis Machoc → Machopeur (Nv. 28 ; espèce
  absente, Machoc « de Dresseur seulement ») ; au J18 il devient capturable (grotte). « Aucune espèce
  nouvelle au J18 » (§10.1). *Recommandation* : ne rien ajouter au J18 (règle existante : une
  évolution vers une espèce absente n'existe pas ; un Machoc capturé vers le Nv. 17 n'atteint le
  Nv. 28 qu'au J20) ; créer Machopeur (données, Pokédex, artwork existant) au plus tard au J20.
  Même cas pour Voltorbe → Électrode (Nv. 30).
- **Q-3 — Qui code l'éclairage ?** Dossier 20 H-8 : la fondation au J17 sur une carte `qa_flash`,
  le réglage au J18. *Recommandation* : **une seule brique, celle du §2, codée maintenant** (T7,
  18.0) et mesurée sur le vrai Mont Sélénite par une clé de débogage ; le J17 s'en sert pour sa mise
  en scène au lieu de créer `qa_flash`. Alternative : attendre le code du J17 et l'adapter.
- **Q-4 — Lancement avant la clôture des J14 à J17.** Comme Q-1 du J12 : art, voile, simulation et
  **cartes sans vie** sur `jalon-18` dès maintenant ; données et moteur (fichiers chauds) après la
  clôture du J17. *Recommandation : oui.*
- **Q-5 — Lot de textes de l'annexe A** (non couverts par le §15 : sous-titres et descriptions de
  zones, panneau du Centre de la Route 10). *Recommandation : relecture en une passe.*

**À signaler (pas une question)** : le §8 du dossier 21 (poste de l'assistant, T-11 à T-16) tombe,
le J17 posant la CS05 (I-4) ; la roadmap de cette branche nomme mal le J17 (§0.2 n° 8).

---

## 8. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Voile | nœud monde unique, z 20 ; bulle z 21 absolu partout ; noir bleuté #04060c ; sans Flash : net 2,5 / fondu 4 cases, opacité 0,6 ; Flash : 7 / 9, 0,3 ; centre −48 px ; battement 3 %, 3,5 s ; ouverture 0,6 s ; trous des halos = rayon du type ; ≤ 16 sources ; opacité max 0,85 |
| Mesures | sol hors du halo ≥ 0,10 et ≥ 1,5 × paroi ; seuils du J12 dans le halo ; écart de fps dû au voile ≤ 2 ; validation à luminosité automatique coupée, curseur à mi-course |
| Flash | sans badge ; compagnon compatible lanceur, sinon premier compatible, K.O. compris ; drapeau `<grotte>_lit` posé au OUI, effacé à toute carte hors de la grotte ; reprise = entrée ; reste allumée jusqu'à la sortie ; dialogue d'entrée 0,6 s après l'arrivée |
| Prototype | clé de débogage `veil` sur `mt_moon_1f` ; aucune carte de QA |
| Identifiants | cartes du dossier §16 + `route_10_center`, `lavender_center`, `lavender_mart`, `pokemon_house`, `lavender_house_1/2` ; Dresseurs et objets : identifiants des grilles ; grotte `dark_cave` |
| Drapeaux | `route_9_entered`, `route_10_reached`, `dark_cave_crossed`, `lavender_reached`, `tower_medium_talked`, `dark_cave_lit`, `cut_cerulean_east_tree` (J16), `tower_stairs_open` (J19, lu seulement) |
| Rencontres | une table Route 10 pour les deux secteurs ; taux et rampe du J12 |
| Lumière | `golden_hour` routes ; `cave_1f` / `cave_b1f` ; `lavender`, `tower_cold`, halo `candle` nouveaux |
| Tour | escalier `coming_soon = "Tour Pokémon"` ; Médium `channeler`, présence `unless tower_stairs_open` ; gardien `old_man` |
| T-9 / objet caché | T-9 en (41, 32), indice en (43, 32) |
| Objectifs | minuscule initiale ; « au Centre » = arrivée sur la Route 10 |
| Halos de la grotte | test 1 à 16 par étage |
| Équilibrage | cible du J12 ; équipes de sortie du J16 et du J17 |

---

## Annexe A — Textes à valider par Kevin (Q-5), brouillons

| # | Élément | Texte proposé |
|---|---|---|
| A-1 | Zone Route 9, sous-titre | « Azuria — Route 10 » |
| A-2 | Zone Route 9, description | « Une route de roche et de terrasses à l'est d'Azuria. Le sentier grimpe, tourne, redescend : il faut garder le pas sûr. » |
| A-3 | Zone Route 10, sous-titre | « Route 9 — Lavanville » |
| A-4 | Zone Route 10, description | « Une route coupée en deux par la falaise et la rivière. On ne passe d'un côté à l'autre que par la Grotte Sombre. » |
| A-5 | Zone Grotte Sombre, sous-titre | « Route 10 » |
| A-6 | Zone Grotte Sombre, description | « Un tunnel sans lumière sous la montagne. On y avance de repère en repère, une colonne, une fente, une flaque. » |
| A-7 | Zone Lavanville, sous-titre | « Route 10 — Route 8 — Route 12 » |
| A-8 | Zone Lavanville, description | « Une petite ville silencieuse au pied de la Tour Pokémon. On y vient de loin pour se souvenir. » |
| A-9 | Panneau du Centre de la Route 10 | « CENTRE POKÉMON / Route 10 » |
