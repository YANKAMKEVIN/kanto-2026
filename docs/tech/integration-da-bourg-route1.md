# Intégration du monde peint : Bourg Palette, ses intérieurs et la Route 1

> Plan préparé par Claude le 2026-10-06, **validé par Kevin le même jour** : Q1 = **A** (garder la géométrie du jeu), Q2 = **oui** (personnages peints dans ce chantier), Q3 = **oui** (avant le jalon 8).
> But : que Bourg Palette, la chambre, le rez-de-chaussée, la maison du rival, le labo et la Route 1 soient **peints dans le vrai jeu** (`game/boot.tscn`), comme Jadielle depuis le jalon 7. Aujourd'hui, ils ne le sont que dans les scènes du prototype (`proto/da_jadielle/proto_bourg.gd`, `proto_interieur_bourg.gd`, `proto_route1.gd`), validées par Kevin sur S24 (60 fps).
> Références : `docs/tech/jalon-07.md` §6.6 (de l'art du prototype à la production), §7 (budget), §15 ; dossiers 01, 02, 07 ; `docs/design/fiches-assets/serie-01-place-jadielle.md` (séries 06 à 08) ; `CLAUDE.md`.

## 1. Ce qui existe

**Le pipeline du jalon 7, à réutiliser tel quel** (`jalon-07.md` §6.6) :
- `tools/art/preparer.py` + `tools/art/manifeste.json` → `assets/world/{buildings,props,ground,relief,interiors,backdrops}` à 1:1, ombres pré-floutées (`_shadow`, `_contact`), `assets/world/catalogue.json` ;
- `tools/build_painted_props.gd` → une scène `WorldProp` par objet (`game/world/props/painted/`), emprises dans `painted_prop_rules.gd` ;
- **un outil de construction par carte** (`tools/build_viridian_city.gd`, `build_route_22.gd`, `build_painted_interiors.gd`) : sol peint (`painted_ground.gd`, masque RG), décalcomanies, objets dans `Entities`, `blocked_cells`, `light_profile`, hautes herbes en deux touffes par case ;
- lumière C2 (`WorldLighting`, `data/world/lighting.json`), personnages peints (`CharacterLook`, `tools/build_character_frames.gd`) ;
- tests de l'art : `test_painted_props`, `test_world_lighting`, `test_character_look`, `test_prop_fade`, `test_npc_gait`.

**Ce qui manque** : aucun asset de Bourg Palette ni de la Route 1 n'est dans le manifeste (ils sont produits par `preparer_proto.py` pour le prototype) ; `light_profile` est vide sur ces 6 cartes ; la **forêt serrée** n'existe que dans `proto/da_jadielle/foret_serree.gd` ; pas de feuilles d'animation peintes pour Maman, Chen, la sœur du rival, les habitants de Bourg Palette (aoki, leo, haru…) ni pour la vieille dame, le pêcheur, le chercheur, la chercheuse et la jardinière du prototype (planches proto seulement).

**Géométrie, carte par carte** :

| Carte | Prototype vs jeu |
|---|---|
| `route_1` (48 × 44) | **identique case par case** (grille recopiée), arbres repères aux mêmes cases. Aucun risque. |
| 4 intérieurs | **mêmes tailles** et plans du jalon 2 ; seul écart : l'ouverture du rez-de-chaussée fait 2 cases dans le prototype, 1 dans le jeu (sortie (7, 8)). |
| `pallet_town` (48 × 34) | **différente** : dans le prototype, les herbes de la Route 1 font 9 × 3 cases (20..28, 2..4), la place est centrée en y ≈ 11 (arbre en (24, 12.6)), les maisons en x 12,5 / 35, le labo plus bas, la mer en rangées 31..33. Dans le jeu : herbes 23..24 × 0..2 entre deux clôtures, arbre de la place en (24, 16), pavés 17..31 × 12..17, portes (11, 9), (36, 9), (24, 22). Le prologue (Chen part de (24, 13), 8 pas avec le joueur), les PNJ et 7 fichiers de tests reposent sur la géométrie du jeu (`test_pallet_town`, `test_route1_event`, `test_opening_walk`, `test_npc_placement`, `test_map_links`, `test_starter_event`, `test_parcel_scene`). → **décision Q1**. |

## 2. Découpage (règle 1 : une validation S24 par sous-étape)

| | Contenu | Visible sur S24 |
|---|---|---|
| **DA.0 — Pipeline** | séries 06, 06B, 07, 08 et planches de forêt ajoutées au manifeste ; `preparer.py` ; règles d'emprise ; scènes `WorldProp` ; la **forêt serrée** devient un module de production (placement **cuit** dans la scène par l'outil, graine fixe, sous-bois en couche de sol) ; hautes herbes jaune-vert (variante d'asset, pas de teinte au lancement) ; tests de l'art étendus. | rien (fondations) |
| **DA.1 — Route 1** | `tools/build_route_1.gd` passe au peint, comme `build_route_22.gd` : sol peint, forêt serrée, arbres repères (automne, bouleau, conifères), souche, rebord peint, clôtures courtes, prairie (panneau, clôtures, banc), Voyageur et Pokémon d'ambiance peints, `light_profile` `golden_hour`. Géométrie et tests inchangés. | la Route 1 peinte, en jouant |
| **DA.2 — Bourg Palette** | `tools/build_pallet_town.gd` passe au peint selon la réponse à Q1 ; maisons, labo, arbre ancien, jardins, serre, côte, ponton, objets « avec propriétaire » ; habitants et 4 routines (vieille dame, pêcheur, enfant + Rattata, chercheur) en vrais PNJ. | Bourg Palette peint, prologue rejoué |
| **DA.3 — Intérieurs** | chambre, rez-de-chaussée, maison du rival, labo à la manière du Centre (enveloppe + meubles `WorldProp`, murs en `blocked_cells`, `interior_warm`) ; mêmes cases bloquées et mêmes cases réservées que les cartes actuelles. | les 4 intérieurs peints |
| **DA.4 — Personnages** (selon Q2) | feuilles d'animation peintes pour Maman, Chen, la sœur du rival et les habitants de Bourg Palette (Codex, ancre du héros), branchées par `build_character_frames.gd`. | plus aucun personnage provisoire à Bourg Palette |

Ordre : DA.0 → DA.1 (la plus sûre, valide le pipeline étendu) → DA.2 → DA.3 → DA.4. Branche `da-bourg-route1` depuis `main`, intégration dans un dossier de travail dédié (jamais dans le dossier principal), fusion dans `main` après la validation de chaque sous-étape.

## 3. Règles techniques

- **Rien du prototype n'est importé tel quel** : textures reprises via le manifeste, techniques réécrites dans `game/` avec des tests (`jalon-07.md` §6.6).
- **Forêt serrée en production** : les arbres sont placés **par l'outil de construction** (graine fixe) et écrits dans la scène, pas tirés au lancement ; règle du couvert (feuillage au-dessus de la forêt seulement), espacement 1,1 case, arbres repères dégagés, bandes étroites en buissons ; taille, miroir et teinte variés **cuits** dans le nœud. Ombres : aucune pour la végétation (règle du J7), contact seulement.
- **Géométrie logique inchangée** sur la Route 1 et les intérieurs : `Ground` (TileMapLayer invisible) ou `blocked_cells` restent la source des collisions, hautes herbes et rebords ; tous les tests actuels doivent passer sans modification.
- **Routines** : le format `route` des PNJ n'a qu'une pause unique ; les routines du prototype avaient une pause par coin. **Défaut (règle 4)** : pause unique par routine (3 à 8 s selon le personnage) ; une pause par case d'arrêt ne sera ajoutée que si Kevin la juge nécessaire après le test S24.
- **Budget** (`jalon-07.md` §7) : ≤ 64 Mo de textures par carte, ≥ 58 fps de moyenne sur S24. Prototype : Bourg Palette ≈ 52 Mo, Route 1 ≈ 36 Mo, 60 fps. À surveiller : le nombre d'arbres de la forêt serrée (appels de dessin) ; lots partagés (mêmes matériaux) comme au J7.
- **Sauvegarde** : aucune donnée nouvelle si Q1 = A (positions et cases inchangées). Si Q1 = B, une partie sauvegardée à Bourg Palette reprend sur la case libre la plus proche (mécanisme existant de `SceneRouter.start_at`) ; à vérifier sur la vraie partie de Kevin.
- **Tests** : `tools/test.sh` vert à chaque tâche ; nouveaux tests : objets du catalogue de Bourg Palette et de la Route 1 (règles, emprises, ombres), forêt serrée (aucun arbre dont le feuillage couvre une case praticable, repères dégagés), `light_profile` des 6 cartes.

## 4. Risques

| Risque | Parade |
|---|---|
| Q1 = B : le prologue et 7 fichiers de tests à reprendre | décision explicite de Kevin ; reprise des tests dans la même tâche que la carte ; QA du prologue complet sur S24 |
| Forêt serrée plus coûteuse dans le jeu que dans le prototype | mesure dès DA.1 (la plus dense) ; repli : moins d'arbres hors champ de la caméra, lots partagés |
| Personnages provisoires (Maman, Chen) au milieu d'un décor peint | DA.4, ou accepter le contraste jusqu'à la phase DA (Q2) |
| Une autre session travaille sur `main` ou sur le J8 en parallèle | branche et dossier de travail dédiés ; vérifier `git worktree list` avant chaque fusion |

## 5. Estimation

DA.0 : 1 tâche d'architecte (Opus) ; DA.1 : 1 tâche de constructeur du monde ; DA.2 : 2 tâches (carte + PNJ et routines, plus les tests si Q1 = B) ; DA.3 : 1 tâche ; DA.4 : 1 série Codex + 1 tâche. Chaque sous-étape visible : QA sur S24 puis validation de Kevin.

## 5 bis. Fait au DA.0 (architecte, 2026-10-06, branche `da-bourg-route1` depuis `main` à `e914a86`)

Rien de visible en jeu : aucune carte, aucun intérieur ni sprite de personnage touché.

**Art** (`tools/art/manifeste.json`, `tools/art/preparer.py`, sources `build/art/` du Mac) :
- **87 objets** ajoutés aux mêmes échelles que `preparer_proto.py` : série 06 (maisons du joueur et du rival, labo, serre, arbre ancien, clôture à piquets, vélo, camionnette, champ, ponton, ronces, tronc couché, rochers marins, escalier en bois), 06B (clôture latérale, arbres C/D/E, hortensias, mangeoire, épouvantail, barque, casiers, oyats, matériel du labo, râtelier, brouette, tas de bois, arrosoir, pierres), 08 (arbre d'automne, souche, rebord, clôture courte), série 07 (46 meubles et tapis `int_*_01`). Identifiants = fiche en `snake_case` (`bldg_maison_joueur_01`, `tree_automne_01`, `int_lit_01`…).
- **Variantes `_bourg`** : 7 objets déjà au manifeste à l'échelle de Jadielle, que le prototype de Bourg Palette affichait plus grands ou plus petits (écart > 10 %) : buissons A/B/C, pots, linge, fruitier, haie latérale (`prop_buisson_a_01_bourg`…). Boîte aux lettres (8 %) : celle du J7.
- **Forêt** : section `planches_arbres`, planches A et B coupées à la colonne et à la rangée les plus vides (30–70 %) → `tree_foret_01..08`, hauteurs du prototype (269 à 317 px, ≈ 3 cases) ; pixels identiques au prototype (05 et 07 : 1 px de large en plus).
- **Herbes jaune-vert** : `ground_hautes_herbes_jaune_01` (+ `_bas`), recolorées à la préparation (section `hautes_herbes_variantes` : teinte −0,071, gamma 0,72, saturation ×1,03, hautes lumières désaturées) ; écart moyen 2,5 / 255 avec l'image de la session ; aucune teinte au lancement.
- **Images** : enveloppes `int_chambre_joueur_coque` (14 × 10), `int_maison_joueur_rdc_coque` (14 × 10), `int_maison_rival_coque` (18 × 11), `int_labo_coque` (16 × 11) ; sols `ground_sable_01` (contraste 0,8) et `ground_eau_01` (mipmaps) ; décalcomanies `decal_fleur_1..8` (0,55 case) et `decal_cote_1..8` (0,6 case).
- **Ombres** : ombre portée pré-floutée pour les **bâtiments seulement** ; les autres objets ont une ombre de contact préparée (sauf ceux posés à plat), **non posée** dans les scènes (règle du J7, `test_painted_props`). Toutes les sorties existantes sont restées identiques à l'octet.

**Emprises** (`painted_prop_rules.gd`, valeurs de `emprises.gd` et des plans de `proto_interieur_bourg.gd`) et 96 nouvelles scènes `WorldProp` (`tools/build_painted_props.gd -- --nouveaux` : n'écrit que les scènes manquantes, les autres gardent leurs `unique_id`). Défauts (règle 4) :
- porte des maisons laissée libre sous la porte peinte : (−1, 0) chez le joueur, (0, 0) chez le rival ; labo 10 × 4 avec **double porte** (−1, 0) et (0, 0), comme le Centre : DA.2 pose un passage sur chacune (ou bloque la seconde) ;
- traversables : rebord, escalier en bois, ponton, champ, tapis (couche du sol), herbes jaune-vert, oyats et petites pierres (sans emprise au prototype), arbres de forêt (les cases de forêt de la carte bloquent) ;
- escalier montant 2 × 2 dont seule la rangée du haut est solide (la rangée du bas porte les passages vers l'étage, `player_house_1f`) ; la maison du rival l'affichait sur 3 colonnes : DA.3 bloque la troisième par `blocked_cells`.

**Forêt serrée de production** :
- `DenseForest` (`game/world/forest/dense_forest.gd`, classe pure) : `plan(cases, taille, repères, graine)` → arbres puis buissons (`foot` en cases, `position` en pixels, `scale`, `flip_h`, `tint`) ; règle du couvert du prototype (les 3 cases de la colonne, pied compris, sont de la forêt ; hors carte = forêt), espacement 1,1, repères à 2 cases, 9 000 tirages, buissons `prop_buisson_a/b_01_bourg` sur les cases non garnies. `place(plan, Entities, racine)` écrit les instances (`Forest000`, `ForestBush000`…) avec taille, miroir du sprite et teinte (`modulate`) **cuits**. Arbres sans emprise, sans fondu (aucun `_process`), sans ombre.
- `ForestFloor` (`game/world/ground/forest_floor.gd`, shader `lighting/shaders/forest_floor.gdshader` réécrit d'après `sous_bois.gdshader`, mêmes bruits, seuils et couleurs) : calque de la taille de la carte au z du sol, à poser **juste après** `PaintedGround` ; `ForestFloor.create(taille, cases)` : masque d'une case par pixel **intégré à la scène** (`ImageTexture`, pas d'image à importer ni de deuxième passe). Calque séparé du sol peint : les canaux B et A du masque du sol restent libres pour le sable et l'eau (DA.2).
- Usage prévu dans un outil de carte (DA.1) : `var trees := DenseForest.plan(foret, taille, reperes, GRAINE)` ; `DenseForest.place(trees, entities, root)` ; `root.add_child(ForestFloor.create(taille, foret))` après le sol peint, `owner = root`.

**Lumière** : `data/world/lighting.json` gagne une section `maps` (profil prévu par carte peinte : les 4 cartes du J7 et les 6 du chantier, `golden_hour` dehors, `interior_warm` dedans), lue par `LightingLibrary.get_map_profile` ; l'outil de chaque carte l'écrit dans `GameMap.light_profile` (DA.1 à DA.3), qui reste la source lue par `Boot`. `test_map_light_profiles` : toute carte prévue existe, toute carte qui a un profil a celui du plan.

**Tests** : `test_painted_props` étendu (objets de DA.0 au catalogue avec règle et scène, images et décalcomanies, herbes jaune-vert sans teinte, ombre portée réservée aux bâtiments, emprises de Bourg Palette) ; `test_dense_forest` (couvert, espacement, repères dégagés, cases garnies, bande étroite en buissons, variations, déterminisme, écriture dans la scène) ; `test_forest_floor` (masque, calque, masque relu après enregistrement) ; `test_lighting_library` (section `maps`) ; `test_map_light_profiles`.

**Écarts avec le prototype (rendu, à juger sur S24 au DA.1, règle 3)** :
- ombres : le prototype mettait ombre portée + contact sous tous les objets, et un contact à l'échelle de chaque arbre de forêt (QA v2) ; on garde la règle du J7 (ombres des bâtiments seulement). Revenir au contact sous les arbres = une clé de règle, sans régénérer l'art ;
- vent : les arbres de forêt ont le vent des autres arbres (5 px ; 3,5 au prototype) ; les buissons de forêt sont immobiles (au vent au prototype) ;
- meubles des intérieurs sans ombre de contact (0,15 au prototype) ;
- `WORLD_PROP_JARDINIERE_01` (série 06B) non ajoutée : aucune scène du prototype ne l'utilise.

## 6. Questions pour Kevin

1. **Géométrie de Bourg Palette.**
   - **A (recommandé)** : on garde la carte du jeu (cases, portes, herbes de 2 cases entre clôtures, place autour de (24, 16), prologue et tests intacts) et on l'habille avec les assets peints en respectant les règles validées (angles droits, labo contourné jusqu'à sa porte sud, herbes qui barrent la Route 1, nature dense / objets rares). Le rendu sera fidèle à la vue générale v1, la composition à quelques cases près. Risque faible.
   - **B** : on refait la carte sur le plan du prototype (herbes 9 × 3, place plus haute, mer plus basse) ; il faut reprendre le prologue, les PNJ et 7 fichiers de tests. Plus fidèle au plan peint, plus long et plus risqué.
2. **Personnages peints (DA.4) maintenant ou en phase DA ?** Le jalon 7 avait reporté Maman et Chen à la phase DA (Q-3). Recommandation : **maintenant**, dans ce chantier : Bourg Palette et ses intérieurs sont le décor de Maman et de Chen, et un personnage pixel au milieu du peint jure.
3. **Place dans la roadmap.** Recommandation : **avant le jalon 8 (Route 2)**, en chantier court, pour que tout le début du jeu (de la chambre à Jadielle) soit peint d'un bloc et que la Route 2 et la Forêt de Jade naissent directement en peint.
