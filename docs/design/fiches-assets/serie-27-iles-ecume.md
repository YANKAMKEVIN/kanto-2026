# Série 27 — Les Îles Écume et Artikodin, lot d'art 24.0 (jalon 24)

> **À VALIDER par Kevin** (planche `build/art/J24_KIT_v1.png` et vues générales dans
> `docs/design/reference/`). Rédigée le 2026-10-19 (branche `j24-art`, depuis `jalon-24`).
> Conception : `docs/design/dossier-27-iles-ecume.md` §5.4, §6.4, §7.1, §8.1, §9, §10.1, §14.4 ;
> plan `docs/tech/jalon-24.md` §2.12 (T5). Aucun code de jeu, **rien dans `assets/`, aucun
> manifeste, aucun `.tres`, aucune entrée dans `tools/art/combat_decors/decors.json`** : l'intégration
> (manifeste, `build_character_frames.gd`, planches « Surf » de `CharacterLook`, `BattleArt`, décors
> CB.3, coques du Labo) revient au plan technique après validation.

## Numéro de série

**27**, vérifié le 2026-10-19 (`git ls-tree` de `docs/design/fiches-assets/`, `tools/art/` et
`tools/art/prompts/` sur toutes les branches `origin/*`) :
- fiches et scripts pris : 01, 12 à 17 (`main`), 18 et 19 (J16, J17), 20 et 24 (`origin/jalon-19`),
  21 (J18), 22 (`origin/jalon-20`), 23 (`origin/jalon-21`) ;
- **25 et 26** : aucune trace sur les branches, mais réservées au J22 (`jalon-22.md` §2.15 : « série 25
  pour le J22 ») et au J23, plus anciens (règle d'ancienneté) ;
- **27 est libre**. Revérifié juste avant le push (voir « Essais, refus, choix »). Si un jalon plus
  ancien le prend, renommer la fiche, `tools/art/serie27.py` et `tools/art/prompts/serie27/` (les
  identifiants d'images ne portent pas le numéro).

## Outil

`tools/art/serie27.py` (reprend `ADN`, `LUMIERE_NE`, `TEXTURE_FIN` de `serie06`, `MODELE_MARCHE` de
`serie12`, `_Planche` de `serie10` ; mêmes conventions que `serie23.py` du J21) :

| Option | Rôle |
|---|---|
| `--prompts` | écrit `tools/art/prompts/serie27/<NOM>_r1.txt` (sans Codex) |
| `--ancres` | copie dans `$ART` les ancres absentes (checkout principal et copies de travail) |
| `--commandes` | liste les appels `tools/art/generer.sh` avec leurs images jointes |
| `[NOM|GROUPE …]` | génère avec Codex ; **règle de Kevin** : AVEC les ancres d'abord (2 essais), puis SANS pièce jointe (2 essais), refus consignés dans `$ART/refus_serie27.log` (pas d'essai sans pièce jointe pour les vues, les coques et les tuiles : sans leur plan ou leur portion, l'image n'a pas de sens) |
| `--tuiles` | découpe les compositions de combat en portions `_TL` / `_TR` (recette CB.3 de `combat_decors/preparer_decor.py`) |
| `--contact [sortie]` | planche de contact **à l'échelle du jeu** (1 case = 96 px, héros 128 px ; Surf et Nageurs posés sur l'eau du jeu) → `build/art/J24_KIT_v1.png` |
| `--vues` | copie les vues retenues et leurs plans dans `docs/design/reference/` |

Groupes : `surf`, `nageurs`, `top`, `force`, `artikodin`, `sols`, `combat`, `tuiles`, `dos`, `labo`,
`vues`.

Les **plans en aplats** des vues et des coques viennent de `tools/art/plan_aplats_j24.py` (trois
légendes : « mer », « grotte », « labo » ; `--annote` pour la relecture). Les grilles de
`tools/plans/` font foi.

## Inventaire : ce qui existe déjà (vérifié sur `origin/main` et les branches J15 à J23)

`git ls-tree` de `assets/sprites/characters/painted/`, `assets/sprites/pokemon/painted/`,
`assets/sprites/pokemon/battle_proto/`, `assets/battle/decors/` sur `origin/main`, `jalon-17` à
`jalon-22`, `jalon-18-integ`, `docs/dossier-26-j23`, `j24-t4-donnees`.

| Besoin du J24 | État | Décision |
|---|---|---|
| Nageur, Nageuse (identité) | **existent** (`nageur_sheet`, `nageuse_sheet` + attente, série 15, J13 : à terre, en tenue de bain) | **réemploi** à terre ; **neuf** : la version *dans l'eau* (tête et épaules), même personnage, planche jointe comme ancre |
| Pêcheur (Routes 21, Labo) | **existe** (`pecheur_sheet`, `haru`) | réemploi ; « Pêcheur expert » du hall = Pêcheur [D] |
| Scientifique (Labo, Boutique) | **existe** : `chercheur` (blouse blanche, lunettes ; décision du J17 pour l'assistant de la Route 2 : « le scientifique existant convient ») et `chercheuse` | réemploi [D] |
| Infirmière, vendeur | **existent** (`infirmiere`, `marchand`) | réemploi (gabarits du Centre et de la Boutique) |
| Gentleman (Centre, T-47) | **existe** sur `main` (J16) | réemploi |
| Fille (T-44), homme (T-45), papy (T-52), « Canon » (T-53) | **existent** : `fillette` ou `dresseuse`, `voyageur`, `vieil_homme`, `jeune_dresseur` | réemploi [D] |
| Employée Sylphe (Boutique, T-48) | rien de dédié | réemploi de `hotesse` (J16, `main`) ou `chercheuse` [D] ; à trancher à l'intégration |
| **Topdresseur, Topdresseuse** | **rien** sur aucune branche | **neufs** (Route 19 : Hugo, Malo ; Centre : Topdresseuse T-46) |
| **Ornithologue** | **rien**, mais **prévu par la série 25 du J22** (`jalon-22.md` §2.15 : « Motard, Ornithologue, Loubard : 3 planches PNJ »), plus ancien | **non généré ici** (règle d'ancienneté : la série 25 le livre ; le J24 le réemploie). Si le J22 tarde, le reprendre en r1 dans cette série, après accord. |
| Monture de Surf, joueur en Surf | rien | **neufs** |
| Rocher de Force, rocher dans l'eau, trou, trou bouché | rien (rochers *décor* seulement : `prop_rocher_01`, `prop_rocher_grotte_01/02`, `prop_rocher_mer_01`) | **neufs** ; même image pour le rocher du Gardien de Parmanie (dossier 26 §9.2) |
| Artikodin dans le monde | rien | **neuf** |
| Eau surfable | **existe** (`ground_eau_01`) | réemploi |
| Courant, eau de grotte | rien | **neufs** (textures) ; les 4 directions du courant = rotations d'une seule texture [D] |
| Kit de grotte glacée | Mont Sélénite et Grotte Sombre : parois `relief_paroi_grotte_*`, échelles `prop_echelle_*`, rochers de grotte, `ground_grotte_01` | **réemploi** des parois, échelles et petits rochers (teintés bleu glace par le profil de lumière) ; **neuf** : le sol de glace (texture) [D] |
| Fonds de combat | `cerulean_gym_bassin`, `route_11_coast` (J17) : aucun de haute mer ni de glace | **neufs** : mer ouverte, grotte glacée |
| Dos de combat | Tentacool `dos_ia_072`, Magicarpe `dos_ia_129`… | **neufs, provisoires IA** : Artikodin, Kabuto, Amonita seulement ; les autres espèces gardent le provisoire existant (artwork officiel retourné ou dos IA) [D] |
| Labo de Cramois'Île | rien (coque du Labo de Chen : autre géométrie) | **neuves** : 4 coques ; tables, plantes, lampe, canapé = objets **existants** (`int_paillasse_01`, `int_table_basse_01`, `int_plante`, `int_canape_01`…) [D] |
| Centre, Boutique de Cramois'Île | gabarits existants | réemploi |

## Le kit (élément par élément)

| Élément | Décision | Fichier d'image (dans `build/art/`) | Prompt (`tools/art/prompts/serie27/`) |
|---|---|---|---|
| Monture de Surf générique (4 × 4) | **neuve** | `SURF_MONTURE_NE_r1.png` | `SURF_MONTURE_NE_r1.txt` |
| Joueur en Surf (4 × 4) | **neuf** | `HEROS_SURF_NE_r1.png` | `HEROS_SURF_NE_r1.txt` |
| Nageur dans l'eau (4 × 4) | **neuf** (identité réemployée) | `PNJ_NAGEUR_EAU_NE_r1.png` | `PNJ_NAGEUR_EAU_NE_r1.txt` |
| Nageuse dans l'eau (4 × 4) | **neuve** (identité réemployée) | `PNJ_NAGEUSE_EAU_NE_r1.png` | `PNJ_NAGEUSE_EAU_NE_r1.txt` |
| Topdresseur (marche 4 × 4) | **neuf** | `PNJ_TOPDRESSEUR_NE_r1.png` | `PNJ_TOPDRESSEUR_NE_r1.txt` |
| Topdresseuse (marche 4 × 4) | **neuve** | `PNJ_TOPDRESSEUSE_NE_r1.png` | `PNJ_TOPDRESSEUSE_NE_r1.txt` |
| Rocher de Force, rocher dans l'eau, trou, trou bouché | **neufs** (une planche) | `WORLD_PROP_FORCE_PLANCHE_NE_r1.png` | `WORLD_PROP_FORCE_PLANCHE_NE_r1.txt` |
| Artikodin posé (1 × 4 : repos, inspire, souffle, repos) | **neuf** | `POKE_ARTIKODIN_MONDE_NE_r1.png` | `POKE_ARTIKODIN_MONDE_NE_r1.txt` |
| Courant (texture, vers le bas) | **neuf** | `WORLD_GROUND_COURANT_01_NE_r1.png` | `WORLD_GROUND_COURANT_01_NE_r1.txt` |
| Eau calme de grotte (texture) | **neuve** | `WORLD_GROUND_EAU_GROTTE_01_NE_r1.png` | `WORLD_GROUND_EAU_GROTTE_01_NE_r1.txt` |
| Sol de glace (texture) | **neuf** [D] | `WORLD_GROUND_GLACE_01_NE_r1.png` | `WORLD_GROUND_GLACE_01_NE_r1.txt` |
| Fond de combat « mer ouverte » | **neuf** (composition + tuiles) | `COMBAT_DECOR_MER_OUVERTE_r1.png`, `_r1_TL.png`, `_r1_TR.png` | `COMBAT_DECOR_MER_OUVERTE_r1.txt` (+ tuiles = `combat_decors/prompts/COMBAT_DECOR_TUILE_r1.txt`) |
| Fond de combat « grotte glacée » | **neuf** (composition + tuiles) | `COMBAT_DECOR_GROTTE_GLACEE_r1.png`, `_r1_TL.png`, `_r1_TR.png` | `COMBAT_DECOR_GROTTE_GLACEE_r1.txt` |
| Dos d'Artikodin, Kabuto, Amonita | **neufs, provisoires IA** | `DOS_ARTIKODIN_r1.png`, `DOS_KABUTO_r1.png`, `DOS_AMONITA_r1.png` | `DOS_*_r1.txt` |
| Coques du Labo (hall 27 × 12, R&D, fossiles, réunion 15 × 10) | **neuves** | `INT_LABO_CRAMOIS_{HALL,RD,FOSSILES,REUNION}_COQUE_NE_r1.png` | `INT_LABO_CRAMOIS_*_COQUE_NE_r1.txt` |
| Vues générales (10 vues) | **neuves** | `CONCEPT_<VUE>_VUE_GENERALE_r1.png` | `CONCEPT_<VUE>_VUE_GENERALE_r1.txt` |

### Choix [D] de la série

- **Monture générique** : une créature ronde bleu clair au ventre crème, petite tête, nageoires,
  queue en éventail, **qui n'est aucun Pokémon** (dossier P-7 : « monture générique peinte ») ; à
  moitié immergée ; ≈ 1,1 case de long de profil. Deux planches : la monture **seule** (apparition,
  saut du joueur, §5.3) et le **joueur assis dessus** (déplacement). L'eau n'est jamais dessinée :
  seulement un anneau d'écume et le sillage (colonnes 2 et 4).
- **Joueur en Surf** : assis à califourchon, à l'échelle de la planche de marche (même cellule
  256 × 384, contact à × 0,4 comme la marche).
- **Nageurs dans l'eau** : les Nageurs du J13 eux-mêmes (pas de nouvelle identité) ; brasse en 4
  images, ligne de flottaison fixe dans la cellule ; la classe « Nageuse » du §9.4 réemploie la
  Nageuse du J13.
- **Topdresseurs** : ♂ veste de survêtement vert sapin, ♀ veste sans manches violet prune, gants sans
  doigts ; aucune Poké Ball dessinée (interdit de la série).
- **Rocher de Force** : arrondi, gris clair un peu chaud, une grande fissure en éclair (dossier §6.4) ;
  **la même image** sert au rocher du Gardien de Parmanie (J23, dossier 26 §9.2). Trou et trou
  bouché : rebord de pierre givrée (Îles Écume seulement).
- **Artikodin** : une seule direction (de face, tourné vers l'entrée de la salle, dossier §8.1) ; ≈ 1,7
  case de haut (163 px) ; 4 images (repos, inspire, souffle de givre, repos).
- **Courant** : une texture « vers le bas », raccordable, que le jeu fait défiler et tourne pour les
  trois autres sens.
- **Coques du Labo** : murs, sol, portes, et ce qui est **fixé au mur du fond** (photo du fondateur,
  ordinateurs, machine de résurrection, vitrines) ; les meubles posés au sol (tables, plantes, lampe,
  canapé) restent des objets séparés, pour le tri en profondeur. Le hall (27 × 12) est peint dans un
  plan à bandes noires (rapport 2,25) : la préparation recadre sur la pièce.
- **Vues** : les cartes trop allongées sont coupées. **Route 20** : une vue centrée sur l'île
  (colonnes 40 à 119) ; les colonnes 0 à 39 et 120 à 149 ne sont que de la mer entre deux récifs.
  **Route 21** : deux vues, nord (rangées 0 à 67) et sud (67 à 134) → `route-21-nord-…` et
  `route-21-sud-…` au lieu d'un seul `route-21-…`. Golden hour dehors ; grottes de plus en plus sombres,
  salle d'Artikodin plus claire (dossier §7.1). Nageurs, Topdresseurs, Pêcheurs et Ornithologue
  suggérés en petit sur les vues des routes (positions indicatives : la grille fait foi).

## Essais, refus, choix

Génération du 2026-10-19 (Codex, aucun coût d'API ; 5 lots en parallèle). Tous les PNG des
personnages, accessoires et dos ont un vrai canal alpha ; un **halo faible** (alpha 1 à 60, jusqu'à
20 % des pixels sur la monture) entoure les sujets : à couper au seuil à la préparation, comme les
séries précédentes.

| Image | Essais | Retenu | Remarque |
|---|---|---|---|
| Monture | r1 | **r1** | créature ronde bleu clair, ventre crème, nageoires, queue en éventail ; aucun Pokémon reconnaissable ; 16 poses cohérentes, sillage aux colonnes 2 et 4. Rendu un peu « jouet lisse » : à juger par Kevin. |
| Joueur en Surf | r1 | **r1** | héros fidèle (casquette, sac), assis à califourchon, 4 directions. **Défaut de découpe** : la casquette des poses de la ligne 4 dépasse dans la cellule du dessus (découper par détection de sujet à la préparation, pas par grille). |
| Nageur dans l'eau | r1 | **r1** | le Nageur du J13 reconnaissable (lunettes, débardeur), brasse lisible. |
| Nageuse dans l'eau | r1 | **r1** | idem (chignon, lunettes, maillot turquoise) ; tête un peu plus grosse que celle du Nageur : à égaliser à la préparation. |
| Topdresseur | r1 | **r1** | veste vert sapin à bandes blanches, gants, baskets ; distinct du héros. |
| Topdresseuse | r1 | **r1** | queue de cheval auburn, veste prune, bottes blanches. |
| Planche Force | r1 | **r1** | rocher clair fendu nettement distinct des rochers décor ; rocher dans l'eau avec anneau d'écume ; trou à rebord givré ; trou bouché lisible. |
| Artikodin (monde) | r1 ; r2 (**refusé 4 fois** : filtre de sécurité, avec et sans pièce jointe) ; r3 (sans aucun nom d'espèce, r1 jointe comme anatomie) | **r3** | r1 : très fidèle mais rendu « artwork officiel », de trois quarts gauche (gardée dans `build/art/`). r3 : de face, symétrique, plus simple ; crête un peu en couronne, un cristal résiduel sur la poitrine à l'image 4, souffle peint sur le poitrail à l'image 3. Choix r1 / r3 à Kevin. |
| Courant | r1 | **r1** | traînées d'écume en chevrons vers le bas, même saturation que `ground_eau_01`. |
| Eau de grotte | r1 | **r1** | bleu profond, calme. |
| Sol de glace | r1 | **r1** | dalles de pierre bleutée et glace mate ; plus clair que `ground_grotte_01`. |
| Combat mer ouverte | r1 + tuiles TL/TR | **r1** | horizon à 31 %, île aux falaises blanches à droite, deux récifs, zone A calme turquoise ; ciel coloré de golden hour (le jeu étalonne). |
| Combat grotte glacée | r1 + tuiles TL/TR | **r1** | stalactites, bassin turquoise à gauche, blocs de glace à droite, grand sol de glace. |
| Dos d'Artikodin | r1 (2 échecs AVEC ancres, obtenu **SANS pièce jointe** au 1er essai) | **r1** | ailes à demi ouvertes, longue queue, regard vers le haut à droite. |
| Dos de Kabuto | r1 | **r1** | dôme brun lisible ; pattes brunes (au lieu de noires). |
| Dos d'Amonita | r1 | **r1** | spirale et tentacules bleus ; un peu de profil plus que de dos. |
| Coques du Labo | r1 × 4 | **r1** | hall : photo, 3 portes à hublot, plan respecté (27 × 12 entre bandes noires) ; R&D : 3 ordinateurs et machine ; fossiles : machine à capsule et 2 vitrines vides ; réunion : tableau blanc, fenêtre sur la mer. Murs latéraux sans biais. |
| Vue Route 19 | r1 | **r1** → `route-19-vue-generale-v1.png` | plage, parasols repliés, 2 Topdresseurs, 5 Nageurs, récifs à angles droits, ouverture vers l'ouest en bas. |
| Vue Route 20 | r1 | **r1** → `route-20-vue-generale-v1.png` | île aux falaises blanches et 2 entrées de grotte, poche fermée, ligne de récifs, îlot de l'Ornithologue avec Poké Ball. Colonnes 40 à 119 seulement [D]. |
| Vue Route 21 nord | r1 | **r1** → `route-21-nord-vue-generale-v1.png` | canal, prairie et hautes herbes entre récifs, bois, îlot du Pêcheur. |
| Vue Route 21 sud | r1 | **r1** → `route-21-sud-vue-generale-v1.png` | îlot avec Poké Ball, pointe de sable noir en bas ; le chenal du bas à gauche est peu lisible (la grille fait foi). |
| Vue Cramois'Île | r1 | **r1** → `cramois-ile-vue-generale-v1.png` | Manoir incendié aux gravats, Arène (toit rouge), Labo blanc, Centre et Boutique identiques aux autres villes, plage de sable noir, fumerolles. Écart : un disque d'emblème au fronton de l'Arène. |
| Vues Îles Écume 1F à B4F | r1 × 5 | **r1** → `iles-ecume-<étage>-vue-generale-v1.png` | glace bleutée, sols bas / haut et escaliers fidèles aux plans, courants du B3F et du B4F, rochers et trous ; Artikodin dans la salle claire du B4F. Écarts : la baisse de lumière d'un étage à l'autre est faible (le B3F est presque aussi clair que le 1F : l'étalonnage du jeu la portera) ; au B4F, la poche du caillou (24..25, 16..17) ressemble à une porte de métal. |

**Refus de Codex** (journal `build/art/refus_serie27.log`) : `DOS_ARTIKODIN_r1` (2 échecs avec
ancres, puis obtenu sans pièce jointe) ; `POKE_ARTIKODIN_MONDE_NE_r2` (4 refus du filtre de sécurité,
avec et sans pièce jointe), contourné par la r3 sans nom d'espèce.

**Sorties** (non versionnées, `build/art/` de la copie de travail ; copiées aussi dans `build/art/` du checkout principal) : sources
ci-dessus, `J24_KIT_v1.png` (planche de contact à l'échelle du jeu), plans `build/plans/PLAN_*_v1.png`
(et `_annote.png`), `refus_serie27.log`. Versionnés : prompts, outils, et les 20 références de
`docs/design/reference/` (10 vues + 10 plans : **à valider par Kevin**).

## Notes d'intégration (pour le plan, pas faites ici)

- `build_character_frames.gd`, table `LOOKS` : `topdresseur` → `cooltrainer_m`, `topdresseuse` →
  `cooltrainer_f` (128 px) ; `nageur_eau` → `swimmer_water`, `nageuse_eau` → `swimmer_f_water`
  (cellule à l'échelle de la marche, ligne de flottaison commune) ; `heros_surf` → `player_surf`
  et `surf_monture` → monture seule (CharacterLook « Surf », jalon-24 §2 T7).
- Rocher de Force : `prop_rocher_force_01` (1 case, origine au pied) ; rocher dans l'eau, trou, trou
  bouché : décalcomanies du sol (`GroundDecals`), jamais dans `Entities`.
- Artikodin : `pokemon/artikodin` (163 px), animation `idle` des 4 images (souffle = image 3).
- Courant : texture défilante ; eau de grotte et sol de glace : `assets/world/ground/` (384 px).
- Combat : entrées `ocean_surf` et `seafoam_glace` à ajouter à `tools/art/combat_decors/decors.json`
  puis `preparer_decor.py` → `assets/battle/decors/` et `data/battle/decors.json`.
- Dos : `battle_proto/dos_ia_144.png`, `dos_ia_140.png`, `dos_ia_138.png` (1024², sujet ≈ 88 %, comme
  `serie23.py --dos`).
- Aucune de ces entrées n'est ajoutée au manifeste tant que Kevin n'a pas validé `J24_KIT_v1.png`.
