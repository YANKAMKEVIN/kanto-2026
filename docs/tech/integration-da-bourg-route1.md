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

## 6. Questions pour Kevin

1. **Géométrie de Bourg Palette.**
   - **A (recommandé)** : on garde la carte du jeu (cases, portes, herbes de 2 cases entre clôtures, place autour de (24, 16), prologue et tests intacts) et on l'habille avec les assets peints en respectant les règles validées (angles droits, labo contourné jusqu'à sa porte sud, herbes qui barrent la Route 1, nature dense / objets rares). Le rendu sera fidèle à la vue générale v1, la composition à quelques cases près. Risque faible.
   - **B** : on refait la carte sur le plan du prototype (herbes 9 × 3, place plus haute, mer plus basse) ; il faut reprendre le prologue, les PNJ et 7 fichiers de tests. Plus fidèle au plan peint, plus long et plus risqué.
2. **Personnages peints (DA.4) maintenant ou en phase DA ?** Le jalon 7 avait reporté Maman et Chen à la phase DA (Q-3). Recommandation : **maintenant**, dans ce chantier : Bourg Palette et ses intérieurs sont le décor de Maman et de Chen, et un personnage pixel au milieu du peint jure.
3. **Place dans la roadmap.** Recommandation : **avant le jalon 8 (Route 2)**, en chantier court, pour que tout le début du jeu (de la chambre à Jadielle) soit peint d'un bloc et que la Route 2 et la Forêt de Jade naissent directement en peint.
