# Fiche d'art : Entrée des combats de Dresseur (v5, 2026-11-02)

Spécification : `docs/design/dossier-05-combat.md` §3 (décisions de Kevin du 2026-11-02).
**Cible de rendu validée par Kevin (« exactement ça »)** : les trois maquettes
`docs/design/reference/entree-dresseur-ordinaire-v1.png`, `entree-dresseur-lancer-v1.png`,
`entree-dresseur-vs-v1.png`. Tout l'art de ce chantier doit **atteindre ce rendu** : personnages
peints dans la même main que les maquettes (2D HD, anime peint, contours fins, ombres douces),
bustes peints au cadrage des maquettes, banderoles à l'effet pinceau. Exception : la rangée de
Poké Balls de la maquette 2 (en haut à gauche) **n'est pas retenue** : le cartouche est au-dessus
de l'adversaire (maquette 1).

Code et déroulé : livrés avec des images **provisoires** (vidéo `entree-dresseurs-v5.mp4`,
comparatif maquette / jeu `entree-dresseurs-comparatif.jpg`). L'art définitif **se branche sans
code** : il suffit de déposer le fichier au bon chemin (sinon le jeu retombe sur l'image
provisoire). Données : `data/battle/trainer_intro.json` (classes, grands adversaires, chemins,
positions et durées [D]). Listes vérifiées par `tests/integration/test_trainer_intro_data.gd`.

## 1. Sprites de combat des adversaires (deux poses par classe et par grand adversaire)

- **Chemins** : `assets/sprites/trainers/battle/<id>.webp` (debout, prêt) et
  `<id>_lancer.webp` (pose de lancer, bras tendu, Ball qui part de la main **côté terrain**, à
  hauteur de poitrine, jamais devant le visage). Sans pose de lancer, le jeu fait un élan de la
  pose debout.
- **Format** : WebP RGBA, **fond transparent**, toile **512 × 768 px** (2:3), personnage en pied,
  **de trois-quarts, tourné vers la gauche** (vers le joueur), **pieds posés sur le bord bas,
  centrés** (origine aux pieds) ; pas d'ombre au sol peinte (le jeu pose l'ombre).
- **Affichage** (fractions de l'écran, x depuis la gauche, y depuis le haut) : à l'entrée, centre
  70 % x, pieds 56 % y, hauteur 26 % ; au lancer, 72 % / 56 % / 32 % (le décor est recadré avec
  lui, zoom 1,22) ; pendant le « VS », 71 % / 67 % / 23,8 % (réduit de 15 % à l'itération 5) ; ombre au sol elliptique sous les
  pieds ; cartouche des Balls à 69–86 % x, 19–26 % y, au-dessus de la tête. Une pose de lancer peut
  être peinte sur une toile **élargie** (même hauteur et même échelle que la pose debout, milieu
  des pieds au centre de la toile) ; sa main se règle par `hand` dans les données de la classe.
- **Rendu** : celui de Gamin Hugo et de Pierre sur les maquettes ; lumière neutre (le décor donne
  l'ambiance), tenue fidèle à l'apparence du monde de la classe.
- **Repli actuel** : première image de l'apparence du monde agrandie (floue), sinon une silhouette.

### Classes de Dresseurs ordinaires (34 classes, 260 combats)

| id | Préfixe du nom | Combats | Apparence du monde (repli) |
|---|---|---|---|
| `beaute` | Beauté | 4 | `beauty` |
| `campeur` | Campeur | 6 | `camper` |
| `chercheur` | Chercheur | 1 | `researcher` |
| `dompteur` | Dompteur | 5 | `docker` |
| `exorciste` | Exorciste | 12 | `channeler` |
| `fillette` | Fillette | 9 | `lass` |
| `gamin` | Gamin | 10 | `youngster` |
| `gentleman` | Gentleman | 4 | `gentleman` |
| `ingenieur` | Ingénieur | 2 | `engineer` |
| `intello` | Intello | 6 | `nerd` |
| `jeune_dresseur` | Jeune Dresseur | 2 | `youngster` |
| `jeune_dresseuse` | Jeune Dresseuse | 16 | `lass` |
| `jongleur` | Jongleur | 7 | `gambler` |
| `joueur` | Joueur | 4 | `gambler` |
| `karateka` | Karatéka | 8 | `hiker` |
| `loubard` | Loubard | 7 | `cue_ball` |
| `maitre_dojo` | Maître du Dojo | 1 | `hiker` |
| `marin` | Marin | 6 | `sailor` |
| `medium` | Médium | 4 | `channeler` |
| `montagnard` | Montagnard | 7 | `hiker` |
| `motard` | Motard | 11 | `biker` |
| `nageur` | Nageur | 14 | `swimmer` |
| `nageuse` | Nageuse | 9 | `swimmer_f` |
| `ornithologue` | Ornithologue | 11 | `bird_keeper` |
| `pecheur` | Pêcheur | 9 | `haru` |
| `pillard` | Pillard | 6 | `gambler` |
| `pokemaniac` | Pokémaniac | 4 | `pokemaniac` |
| `rockeur` | Rockeur | 2 | `rocker` |
| `sbire_rocket` | Sbire Rocket (homme) | 26 | `rocket_grunt_m` |
| `sbire_rocket_f` | Sbire Rocket (femme, `"class"` dans les données) | 11 | `rocket_grunt_f` |
| `scientifique` | Scientifique | 13 | `researcher` |
| `scout` | Scout | 11 | `scout` |
| `topdresseur` | Topdresseur | 8 | `cooltrainer_m` |
| `topdresseuse` | Topdresseuse | 4 | `cooltrainer_f` |

Ordre conseillé (combats les plus vus d'abord) : `sbire_rocket`, `jeune_dresseuse`, `nageur`,
`scientifique`, `exorciste`, `sbire_rocket_f`, `motard`, `ornithologue`, `scout`, `gamin`, puis
le reste. Les Sbires femmes ont un sprite à part (décision de Kevin du 2026-11-02).

## 2. Dos du joueur (premier plan)

- **Chemins** : `assets/sprites/trainers/battle/dos_hero.webp` et `dos_heroine.webp` (debout,
  prêt, maquette 1), plus `dos_hero_lancer.webp` / `dos_heroine_lancer.webp` (pose de lancer).
- **Format** : WebP RGBA, fond transparent, toile **640 × 960 px**, **de dos, trois-quarts vers la
  droite**, pieds sur le bord bas centrés. Images par moment (données « images ») : à l'entrée la
  **pose de lancer** (debout, bras droit tendu main ouverte, maquette 1), silhouette entre 20 et
  37 % x, pieds 95 % y, sommet 40 % y ; pendant le lancer de l'adversaire la **pose debout** (garde,
  poings serrés, maquette 2), centre 21,5 % x, pieds 97 % y, hauteur 57 % ; à son propre lâcher la
  pose de lancer ; pendant le « VS » la pose debout, centre 29 % x, pieds 74 % y.
- **Costume porté** (2026-11-04, Kevin : les costumes « ont encore l'ancienne pose pour le lancer ») :
  chaque costume a ses dos peints, même recette et mêmes toiles que le héros :
  `dos_costume_<art>_<joueur|joueuse>[_surf][_lancer].webp` (apparence de combat
  `costume_<art>_<version>`, `CostumeCatalog.battle_look`) ; outil `tools/art/dos_costumes.py`
  (Codex, deux poses par image, 33 générations ; Link et Zelda à pied bloqués une fois par la
  sécurité de Codex, passés au second essai). `dos_heroine(_lancer)` est peint aussi.
- **Repli** : sans dos peint, le lancer de dos existant (`heros_lancer.png` / `joueuse_lancer.png`,
  ou `<art>_<version>_lancer.png` du costume), agrandi.

## 3. Grands adversaires (13 portraits, 22 combats)

Chaque grand adversaire demande le sprite de face du §1 (mêmes deux poses, même id) **et** un
**buste de banderole** pour la séquence « VS ».

| id (portrait) | Combats | Titre affiché | Apparence du monde (repli) |
|---|---|---|---|
| `pierre` | `pewter_gym_brock` | Champion d'Arène d'Argenta | `brock` |
| `ondine` | `cerulean_gym_misty` | Championne d'Arène d'Azuria | `misty` |
| `major_bob` | `vermilion_gym_surge` | Champion d'Arène de Carmin | `surge` |
| `erika` | `celadon_gym_erika` | Championne d'Arène de Céladopole | `erika` |
| `koga` | `fuchsia_gym_koga` | Champion d'Arène de Parmanie | `gentleman` |
| `morgane` | `saffron_gym_sabrina` | Championne d'Arène de Safrania | `beauty` |
| `auguste` | `cinnabar_gym_blaine` | Champion d'Arène de Cramois'Île | `gentleman` |
| `giovanni` | `silph_co_giovanni`, `giovanni_hideout`, `viridian_gym_giovanni` | Chef de la Team Rocket / Champion d'Arène de Jadielle | `giovanni` |
| `olga` | `league_lorelei` | Conseil des Quatre | `olga` |
| `aldo` | `league_bruno` | Conseil des Quatre | `aldo` |
| `agatha` | `league_agatha` | Conseil des Quatre | `agatha` |
| `peter` | `league_lance` | Conseil des Quatre | `peter` |
| `rival` (+ `rivale`) | 8 combats : `rival_lab`, `rival_route22`, `rival_cerulean`, `rival_ss_anne`, `rival_tower`, `rival_silph`, `rival_route22_final`, `rival_champion` | Rival / Champion de la Ligue (dernier combat) | `rival` / `rival_heroine` |

Le rival suit l'apparence choisie à l'ouverture : prévoir `rival` **et** `rivale` (14 bustes,
14 × 2 sprites de face).

### Buste de banderole

- **Chemin** : `assets/ui/battle/vs/<id>.webp`.
- **Format** : WebP RGBA, fond transparent, **≈ 540 × 720 px** (3:4), cadrage **tête et épaules**
  comme Pierre et Kevin sur la maquette 3, **regard vers la gauche** (vers le centre : le buste est
  au bout droit de la banderole rouge), expression de défi ; le haut de la tête près du bord haut.
- **Affichage** (cadrage par les données, bloc « vs » de `trainer_intro.json`) : bord droit au
  bord de l'écran, haut à −12 % y, hauteur 53 % de l'écran, **rogné au bas de la banderole**
  (28,5 % y) ; réglage par buste `busts.<id>` = [dx, dy, échelle] (Pierre : [−0,005 ; 0,023 ;
  1,2], visage au cadrage de la maquette, col et haut de poitrine dans la banderole).
- **Repli actuel** : portrait d'introduction du rival, sinon le sprite de face (ou son repli).
- **Joueur** : buste peint `vs/<apparence>.webp` (sinon buste du menu selon l'apparence et le
  costume, `TrainerLooks.bust_path`), en bas à gauche : bord gauche à −2 % x, haut à 58,9 % y,
  hauteur 66,7 %, rogné par le bas de l'écran, regard vers la droite.

## 4. Banderoles « VS » (pinceau, remplaçables)

- **Chemins** : `assets/ui/battle/vs/banderole_rouge.webp` et `banderole_bleue.webp`.
- **Format** : WebP RGBA, fond transparent, **≈ 2048 × 300 px**, coup de pinceau peint (couleur
  pleine, traînées et éclaboussures), **bout intérieur déchiré à gauche** pour la rouge ; la bleue
  est dessinée de la même façon (le jeu la retourne : son bout déchiré est à droite).
- **Affichage** : rouge 50–100 % x, 5–30 % y (épaisseur 22 %, 1,5° montant vers la droite),
  bleue 0–60 % x (épaisseur 18 %, 4°) ; textes presque horizontaux (70 % de l'inclinaison
  annulée) ; nom Cinzel gras (initiale en capitale, le reste en petites capitales : « Pierre »,
  « Kevin »), **blanc ivoire** cerné de brun adouci (filet et losange ivoire), centré à 69,5 % x (rouge) ou 30,5 % x (bleue), filet et
  losange, titre en bas-de-casse **Cormorant Garamond** demi-gras dessous.
- **Repli actuel** : pinceau dessiné en code (bandes à bord déchiré, traînées, liseré clair).
- **Polices** : Cinzel (SIL OFL 1.1, `assets/fonts/cinzel/`) pour les noms ; Cormorant Garamond
  (SIL OFL 1.1, `assets/fonts/cormorant_garamond/`, licence `OFL.txt` à côté) pour le titre.

## 5. Emblème « VS »

Remplacement peint **branché** : `assets/ui/battle/vs/emblem_vs.webp` (WebP RGBA, fond
transparent, « VS » doré lumineux avec entaille diagonale et éclair, ≈ 600 × 500 px) ; affiché à
≈ 12 % de la largeur de l'écran, centré à (50 %, 49 %). Repli actuel dessiné en code : lettres
Cinzel en dégradé d'or, éclat additif, entaille diagonale, éclair et deux traits.

## 6. Valeurs par défaut [D] (`data/battle/trainer_intro.json`, `UiTokens.VS_*`)

- Ordinaire : les dresseurs entrent 0,55 s après le début de la caméra (0,45 s), puis le cartouche
  et ses Balls (0,25 s ; actives à opacité pleine, emplacements vides en Ball grise claire) ;
  chaque lancer : garde 0,25 s (rapprochement ; au lancer de l'adversaire, le joueur passe en garde
  au premier plan et **le décor se recadre**, zoom 1,22 autour des pieds de l'adversaire), vol
  0,4 s (Ball de 2,4 % de la largeur, arc par (56 % ; 28 %) depuis la main de la pose de lancer,
  traînée dessinée de la main à la Ball, qui s'amincit et s'efface progressivement, sur un
  halo fin (la traînée peinte `fx/ball_trail.webp` reste branchable par `fx_trail`) ; le décor
  revient au cadrage du combat pendant la seconde moitié du vol), accompagnement 0,2 s, recul en
  fondu 0,3 s, sous son message. **≈ 4,5 s** du début du combat aux commandes (vidéo v4).
- Grand combat : la même entrée, puis le « VS » (0,3 + 0,75 + 0,35 = **1,4 s**) pendant lequel les
  dresseurs prennent leur place du « VS » puis reviennent ; puis les lancers.
- Banderoles : voir §4.
- Bandeau des messages : 49–98 % x, 77–94 % y (compromis entre les maquettes 1 et 2), texte
  40 px, contour plus clair, **petit triangle de suite** en bas à droite tant qu'un message attend
  (tokens `BATTLE_MESSAGE_*`, tout le combat).

## 7. Lot d'art pilote branché (2026-11-02) et écarts restants

Branché sans code : `gamin(_lancer)`, `pierre(_lancer)`, `dos_hero(_lancer)`, bustes `vs/pierre`
et `vs/hero` (buste peint du joueur : `assets/ui/battle/vs/<apparence>.webp`, sauf costume porté),
banderoles `banderole_rouge` / `banderole_bleue` (inclinées par le jeu), emblème `vs/emblem.webp`
(les deux traits horizontaux restent dessinés en code). Décors v2 `route_3_roche_v2_back` et
`pewter_gym_roche_v2_back` branchés dans `data/battle/decors.json` (Arène : `foe_feet`
[1559, 640]) ; **les anciens fichiers `route_3_roche_back.webp` et `pewter_gym_roche_back.webp`
restent dans le dépôt, à supprimer si Kevin valide les v2**.
Taille des personnages : hauteur **visible** (boîte alpha) × taille réelle relative des données
(`scale` par classe ou grand adversaire, `default_scale` 1,18 pour un adulte, 1 pour un enfant et
le joueur) : Pierre paraît plus grand que Gamin Hugo.

Écarts restants (art seulement) :
1. **Toutes les autres classes et grands adversaires** (32 classes, 12 grands adversaires, la
   joueuse) : encore sur leur repli (apparence du monde agrandie).
2. **Titre de la banderole** : Cinzel n'a que des capitales (petites capitales pour les
   minuscules) ; la maquette montre un titre en bas-de-casse à empattements. Une seconde police
   OFL à empattements avec minuscules (par exemple Cormorant) réglerait l'écart.
3. **Décor de l'Arène v2** : recadré par le jeu (sol à 600 px) ; les colonnes du haut sont plus
   coupées que sur la maquette.
4. **Traînée de la Ball** : fine et sans éclat ; un sprite de traînée peint ferait mieux.

## 8. Itération 4 (2026-11-02, revue de Codex) et écarts restants

Fait : pose par moment (données « images »), recadrage réel du décor au lancer, main de la pose de
lancer par classe (`hand`), Ball et traînée peintes de l'agent d'art (`fx/`), cartouche aux Balls
vides grises claires, bandeau des messages et triangle de suite, banderoles du « VS » refaites
(rouge plus longue et moins haute, textes presque horizontaux, titre Cormorant), bustes poitrine
cadrés par les données, décor d'Arène v3 (`foe_feet` [1559, 560], horizon 515). Comparatif :
`entree-dresseurs-comparatif.jpg` (maquette | capture réelle 2340 × 1080, mêmes moments).

Écarts restants :
1. **Art** : toutes les autres classes et grands adversaires, la joueuse (repli).
2. **Lancer** : le décor de la maquette 2 est plus serré que le zoom 1,22 (gardé pour que la taille
   de l'adversaire reste cohérente avec le sol) ; la traînée part de la main, plus basse sur la
   pose peinte de Gamin Hugo (≈ 65 % ; 35 %) que sur la maquette (≈ 67 % ; 30 %).
3. **« VS »** : la banderole rouge est une bande droite inclinée (la maquette est un coin qui
   s'élargit vers la droite) ; le buste de Pierre au cadrage du visage de la maquette ne montre que
   le col et le haut de la poitrine (comme la maquette).
4. Fichiers d'Arène v1 et v2 et de la Route 3 v1 toujours dans le dépôt, à supprimer si Kevin
   valide.

## 9. Itération 5 (2026-11-02, arrêtée par Kevin : rendu v4 jugé très bien)

Gardé, sûr et non contradictoire : noms, filet et losange du « VS » en blanc ivoire ; Pierre réduit
de 15 % pendant le « VS » (pieds à 67 %) ; traînée dessinée de la main à la Ball, effilée et
effacée progressivement. Tout le reste de la v4 est inchangé (cadrage, cartouche, bandeau,
« VS » à 50 % x). Aucun nouvel art fusionné (`dos_hero_vs.webp` de la branche d'art non branché).
Comparatif et vidéo `entree-dresseurs-v5.mp4` refaits (v4 retirée). Suite : contrôle dans toutes
les Arènes et lieux de combat.

## 10. Étape 2 : les 8 Champions dans leur Arène (2026-11-02)

Pilote validé par Kevin (Pierre, « c'est bon pour moi ») étendu aux 7 autres Champions. Planches en
captures réelles 2340 × 1080 (entrée, lancer, « VS ») : `entree-champions/<arene>.jpg`
(`argenta`, `azuria`, `carmin`, `celadopole`, `parmanie`, `safrania`, `cramois`, `jadielle`) et
`entree-champions-ensemble.jpg` (le « VS » des 8). Refaire : `tools/capture_champions.sh` puis
`tools/art/planches_champions.py`.

- **Art** (`tools/art/entree_champions.py`, prompts `tools/art/entree_dresseurs/champions/`) : par
  Champion une génération « sprites » (debout prêt + lancer, références : Pierre debout et lancer,
  buste de Pierre, apparence du monde quand elle est peinte) et une génération « buste » (références :
  buste de Pierre, sprite debout du Champion). Apparence Rouge/Bleu modernisée : Koga en ninja,
  Morgane cheveux longs noirs, haut noir et pantalon blanc, Auguste chauve, moustache blanche,
  lunettes noires et blouse blanche (leurs apparences du monde sont encore provisoires :
  `gentleman`, `beauty`). Exports aux chemins du §1 et du §3 (toiles 512 × 768, lancer élargi,
  buste 540 × 720).
- **Données** (`trainer_intro.json`, `grand`) : `scale` [D] Ondine 1,10, Erika 1,12, Auguste 1,08,
  Morgane 1,16, Koga 1,26, Giovanni 1,28, Major Bob 1,30 (Pierre : 1,18 par défaut) ; `hand` mesurée
  sur chaque pose de lancer (bout des doigts, ramené vers la paume comme Pierre) ; `busts.<id>` au
  réglage de Pierre.
- **Code** : le cartouche des Balls remonte pour rester au-dessus de la tête de l'adversaire à
  l'entrée et au lancer (pose agrandie) ; nom et titre de la banderole rouge réduits s'ils dépassent
  20 % de la largeur (`UiTokens.VS_FOE_TEXT_MAX_WIDTH`).
- **Décors** : repeints en v2 (trois-quarts, sol vers 41–43 % de la hauteur, `foe_feet`
  [1559, 560]) car nettement en dessous d'Argenta v3 (vue frontale vide) : Jadielle
  (`viridian_gym_sol_v2`, dalles à flèches, statues de Rhinocorne ; l'ancien `viridian_gym_sol`
  reste au combat du Maître de la Ligue), Safrania (`saffron_gym_psy_v2`, téléporteurs), Carmin
  (`vermilion_gym_salle_v2`, barrière électrique, poubelles). Gardés : Azuria (bassin), Céladopole
  (serre), Parmanie (dojo), Cramois'Île (volcan) : lisibles, sol qui porte les personnages.

Écarts restants : apparences du monde de Koga, Morgane et Auguste toujours provisoires (le combat
est peint, le monde non) ; Cramois'Île : les pieds d'Auguste sont près du muret du fond (sol à
≈ 52 %) ; bustes non réglés un par un (cadrage de Pierre, à affiner sur téléphone) ; anciens décors
de Safrania et Carmin gardés dans le dépôt, à supprimer si Kevin valide les v2.

## 11. Étape 3 : les autres grands combats (2026-11-02)

Même séquence que les Champions pour tous les autres combats à `card.portrait` : le rival à ses 8
combats (titre « Rival », « Champion de la Ligue » au dernier), Giovanni au repaire et à Sylphe SARL,
le Conseil des 4. Planches en captures réelles 2340 × 1080 (entrée, lancer, « VS ») :
`entree-grands-combats/<lieu>.jpg` (`labo-chen`, `route-22`, `route-24`, `ss-anne`, `tour-pokemon`,
`sylphe`, `repaire-rocket`, `ligue`, `ligue-maitre`) et `entree-grands-combats-ensemble.jpg` (les
15 « VS », rivale comprise). Refaire : `tools/capture_grands_combats.sh` puis
`tools/art/planches_grands_combats.py`.

- **Art** (`tools/art/entree_grands_combats.py`, prompts `tools/art/entree_dresseurs/grands/`, mêmes
  gabarits que les Champions, IMAGE 3 = apparence du monde : portrait peint du rival, feuilles du
  Conseil) : sprites debout et lancer + buste « VS » du **rival** (épis châtains, gilet violet sans
  manches, t-shirt noir, pendentif, sac à dos, baskets violettes, comme son portrait et la planche de
  la Route 22), de la **rivale** (même tenue, queue de cheval), d'**Olga** (carré bleu nuit, lunettes,
  manteau bleu glacier à fourrure, bottes blanches), d'**Aldo** (karatégi blanc aux manches arrachées,
  ceinture noire, pantalon orange), d'**Agatha** (âgée, voûtée, chignon gris, robe violette, châle
  noir, canne), de **Peter** (roux, cape noire doublée d'orange, veste marine à passepoils dorés).
  Giovanni reprend son jeu de l'étape 2. Peter : poses séparées par composante connexe (capes qui
  se touchent).
- **Données** (`trainer_intro.json`) : `scale` [D] rival et rivale 1,05, Olga 1,14, Aldo 1,32,
  Agatha 0,95, Peter 1,24 ; `hand` = bout des doigts du lancer + (0,061 ; 0,114), la règle des
  Champions ; bustes au réglage de Pierre (`rival` et `rivale`).
- **Décors** (recette `preparer_decor.py` : composition + 2 tuiles repeintes, jamais
  d'agrandissement ; `foe_feet` [1559, 560], sol vers 41–46 %) :
  - **peints, nouveaux** : les 5 salles de la Ligue, fidèles aux salles du monde (DAF.10d) et non
    plus empruntées à d'autres lieux : `league_olga_glace`, `league_aldo_roche`,
    `league_agatha_spectre`, `league_peter_dragon` (`foe_feet` [1559, 585]),
    `league_champion_salle` ; le **labo de Chen** (`oak_lab_labo`, le labo n'avait aucun fond :
    repli sur la carte floutée) ; le **couloir du capitaine du S.S. Anne** (`ss_anne_couloir`, pour
    `ss_anne_captain_corridor` et `_room` ; `foe_feet` [1559, 575]).
  - **repeints en v2, même identifiant** (vue frontale vide, sous Argenta v3) : `silph_co_bureaux`
    (tous les étages de bureaux de Sylphe), `tour_pokemon` (tous les étages de la Tour),
    `rocket_hideout_repaire` (tous les sous-sols du repaire).
  - **Route 22, fond propre** (demande de Kevin, « oui fond propre à la route 22 ») :
    `route_22_chemin` (chemin de terre entre falaises ocre en terrasses, sapins, barrière de bois,
    marches de pierre, Plateau Indigo au loin, d'après `reference/route-22-rival-02-v1.webp`),
    branché sur `route_22` et `route_22_west` (les deux combats du rival et toute la route) ;
    remplace la prairie des Routes 5-6 empruntée.
  - **gardé** : Route 24 (`route_24_pont`) : riche, au niveau, sol qui porte les personnages.
- **Tests** : `test_battle_decor` (le labo a son fond), `test_serie18_assets` (couloir du capitaine).

Écarts restants : le bureau du président (Giovanni, 11e étage) réutilise le plateau de bureaux ;
bustes non réglés un par un ; fichiers devenus inutiles, à supprimer si Kevin valide :
`viridian_gym_sol_back.webp` (plus aucun combat), `silph_co_bureaux_back.webp`,
`rocket_hideout_repaire_back.webp` (anciennes versions) ; `tour_pokemon_back.webp` reste (fond
`manoir_salle` du Manoir Pokémon).

## 12. Étape 4 : les classes de Dresseurs ordinaires (2026-11-03)

Demande de Kevin (« Vas y continue ») : les **34 classes** ordinaires du §1 (toutes utilisées, 260
combats) ont leur art peint ; le Gamin était le pilote, les **33 autres** sont peintes ici, Sbire
femme comprise (`sbire_rocket_f`, sprite à part, décision de Kevin). Entrée de niveau 1 inchangée
(les deux dresseurs, la rangée de Balls, le lancer ; pas de « VS »).

- **Art** (`tools/art/entree_ordinaires.py`, prompts `tools/art/entree_dresseurs/ordinaires/`,
  lot `tools/art/entree_ordinaires_lot.sh`) : **deux classes par image Codex** (portrait
  1024 × 1536, une rangée par classe : debout prêt à gauche, lancer à droite), références : Pierre
  (debout + lancer), Gamin (debout + lancer), puis l'apparence du monde de chaque classe quand elle
  lui est fidèle (face et profil de sa feuille peinte). Figures de 610 à 800 px de haut dans la
  source : jamais agrandies à l'export. Classes dont l'apparence du monde est un emprunt (et non la
  classe) : dessinées d'après Rouge/Bleu, sans IMAGE du monde : `medium` (Psy de Safrania, le monde
  prend `channeler`), `karateka` et `maitre_dojo` (le monde prend `hiker`), `jongleur` et `pillard`
  (le monde prend `gambler`), `jeune_dresseur` (le monde prend `youngster`). Révisions retenues :
  `elite` r2 (le Topdresseur tendait déjà le bras à l'entrée), `jeunes` r2 (le Jeune Dresseur en
  rouge et blanc ressemblait au héros : casquette verte, t-shirt jaune [D]). 19 images Codex.
- **Export** : rangées séparées par les lignes vides, poses par colonnes vides, sinon par
  composantes connexes (motard, loubard : la main du lancer passe au-dessus du coude de la pose
  debout) ; toiles du §1 (debout 512 × 768, lancer élargi, milieu des pieds au centre).
- **Données** (`trainer_intro.json`, `classes`) : `hand` = bout des doigts du lancer (cherché dans
  la moitié haute de la pose, pour ne pas prendre le pied avant) + (0,061 ; 0,114), la règle des
  grands combats ; `scale` [D] : enfants 1,0 (gamin, fillette, scout, campeur), adolescents 1,05
  (jeune dresseur, jeune dresseuse), adultes 1,06 à 1,26 :

| Classe | scale | Apparence peinte |
|---|---|---|
| `beaute` | 1,10 | longs cheveux châtains, robe d'été rose pâle, sac blanc |
| `campeur` | 1,00 | chemise kaki de scout, foulard rouge, short olive, sac à dos |
| `chercheur` | 1,12 | jeune, cheveux noirs, lunettes, blouse ouverte, pull vert, carnet |
| `dompteur` | 1,24 | bonnet gris, barbe, salopette ocre, fouet enroulé |
| `exorciste` | 1,06 | voile crème, robe brun-violet, chapelet de bois |
| `fillette` | 1,00 | robe bleu clair, barrette-fleur, sac rose |
| `gamin` | 1,00 | (pilote, inchangé) |
| `gentleman` | 1,14 | chapeau melon, moustache blanche, costume noir, canne |
| `ingenieur` | 1,20 | casque jaune, t-shirt orange, salopette bleue, clé à molette |
| `intello` | 1,12 | lunettes rondes, chemise blanche, nœud papillon vert, livre |
| `jeune_dresseur` | 1,05 | casquette verte et blanche, t-shirt jaune, short vert |
| `jeune_dresseuse` | 1,05 | queue de cheval, bandeau jaune, veste orange, short en jean |
| `jongleur` | 1,16 | gilet à losanges rouges et jaunes, pantalon violet, balles de jonglage |
| `joueur` | 1,18 | fedora, moustache, veste marron, gilet moutarde, dé |
| `karateka` | 1,22 | karatégi blanc, ceinture noire, bandeau, pieds nus |
| `loubard` | 1,24 | chauve, barbe, gilet de cuir sans manches, cargo noir |
| `maitre_dojo` | 1,24 | crâne rasé, moustache et barbiche grises, karatégi à revers noirs |
| `marin` | 1,20 | bachi, col marin, foulard rouge, pantalon marine |
| `medium` | 1,14 | cheveux noirs sur un œil, tunique violet sombre à liserés dorés |
| `montagnard` | 1,26 | bob kaki, barbe, chemise à carreaux rouges, gros sac à dos |
| `motard` | 1,20 | banane noire, lunettes noires, blouson de cuir, t-shirt rouge |
| `nageur` | 1,16 | lunettes de natation, serviette au cou, short de bain bleu |
| `nageuse` | 1,10 | chignon, maillot turquoise, paréo blanc |
| `ornithologue` | 1,16 | chapeau vert à plume bleue, jumelles, gilet bleu-vert |
| `pecheur` | 1,18 | bob beige, barbe grise, gilet de pêche, canne |
| `pillard` | 1,18 | bonnet, loup noir, pull rayé, sac de toile |
| `pokemaniac` | 1,12 | lunettes, chemise à carreaux, sac à dos olive |
| `rockeur` | 1,18 | banane, lunettes noires, blouson à étoiles, guitare rouge |
| `sbire_rocket` | 1,16 | casquette et uniforme noirs au R rouge, gants et bottes gris |
| `sbire_rocket_f` | 1,12 | même uniforme, cheveux courts sous la casquette |
| `scientifique` | 1,16 | adulte grisonnant, lunettes, longue blouse, pull vert, cravate |
| `scout` | 1,00 | chapeau de paille, gilet vert, filet à papillons, boîte verte |
| `topdresseur` | 1,14 | cheveux noirs en épis, veste de survêtement verte, bras croisés |
| `topdresseuse` | 1,10 | queue de cheval rousse, veste courte marine, mini-short |

- **Captures** (`tools/capture_ordinaires.sh` : un combat par classe, là où elle se bat vraiment ;
  `tools/capture_trainer_intro.gd` accepte `--trainer`, `--map`, `--spawn` ; planches
  `tools/art/planches_ordinaires.py`) : `entree-ordinaires/<lot>.jpg` (entrée et lancer en
  2340 × 1080, un fichier par planche d'art, plus `gamin.jpg`) et `entree-ordinaires-ensemble.jpg`
  (un lancer par classe). Montagnard capturé sur la Route 9 (dans la Grotte Sombre, le message
  d'entrée de la carte se superpose au combat lancé dès l'arrivée : artefact de l'outil).
- **Tests** : `test_every_ordinary_class_has_complete_art` (debout, lancer, main pour chaque
  classe), `test_ordinary_class_scales` (enfants < adolescents < adultes).

**Décors signalés, puis repeints** (réponse de Kevin du 2026-11-03 : « Mer, Route 17, Manoir », dans
cet ordre ; outils de l'étape 3 : prompts `tools/art/entree_dresseurs/grands/ecrire_decors_ordinaires.py`,
`tools/art/entree_grands_combats.py decor|tuile`, recette `preparer_decor.py`, IMAGE 1 = Argenta v3,
IMAGE 2 = vue générale validée du lieu ; 10 images Codex : 4 compositions et 6 tuiles, dont une
composition du Manoir refaite parce que la tuile gauche, avec une grande statue de Mew au premier
plan, était refusée par Codex) ; planche `entree-ordinaires/decors-repeints.jpg` :
- **Mer des Routes 19 à 21** (`sea_open`, même identifiant, nouveau fichier `sea_open_v2_back.webp`,
  aussi la mer de Cramois'Île) : [D] **grand banc de sable émergé** dans des hauts-fonds turquoise,
  digue d'enrochement au premier plan à gauche et au fond (comme la vue générale de la Route 19) :
  le joueur et le nageur se tiennent sur du sable mouillé. Alternative possible : le joueur sur son
  Pokémon de Surf (question à Kevin). `foe_feet` [1559, 560].
- **Route 17, Route cyclable** (identifiant neuf `route_17_cyclable`, branché sur `route_17` seule) :
  chaussée de béton à dalles en bord de mer, glissière à bornes orange, enrochements, séparateur
  central, traces de dérapage, forêt dense de l'autre côté (vue générale de la Route 17). Les pilotis
  ne se voient presque pas (la chaussée longe les enrochements). Les Routes 16 ouest et 18 gardent
  le parc urbain des Routes 7-8. `foe_feet` [1559, 560].
- **Manoir Pokémon** (`manoir_salle`, propre fichier `manoir_salle_back.webp` au lieu du fond de la
  Tour) : grande salle délabrée, parquet usé et brûlé, tapis rouge déchiré, papier peint décollé,
  poutres calcinées, deux statues de Mew au fond, grille entrouverte, bibliothèque renversée,
  lumière dorée des fenêtres brisées (r2 retenue). `foe_feet` [1559, 575].
- Emprunts lisibles mais pas propres au lieu, non repeints : Routes 14 et 15 (prairie des Routes
  5-6), Route 12 (pont de pierre de la Route 24), Route 25 (côte de la Route 11). Arène de Parmanie
  (dompteurs, jongleurs) : grande salle frontale vide, gardée à l'étape 2.

**Jeune Dresseur** en vert et jaune : validé par Kevin (« pas de soucis », 2026-11-03).

**Apparences du monde et replis par genre** (Kevin, 2026-11-03 : « il faut fixer ») : `hiker` (feuille
`randonneuse`, féminine) servait aux Montagnards, Karatékas et au Maître du Dojo. Désormais :
Montagnard → `mountaineer` (feuille masculine `montagnard`, la tenue de son art de combat), dans le
monde (6 Dresseurs) et en repli ; Karatéka et Maître du Dojo → `cue_ball` [D] (feuille `loubard` :
crâne rasé, carrure musclée, sans manches), dans le monde (9 Dresseurs) et en repli, **faute de
feuille de karatéka peinte** ; Médium → `youngster` en repli (comme ses Dresseurs du monde ; il
retombait sur la feuille féminine `exorciste`). Les passants non Dresseurs en `hiker` (Routes 2, 3
et 5, Forêt de Jade, maisons de repos du Parc Safari) ne changent pas. Garde :
`test_world_looks_match_the_gender_of_the_class` (repli de chaque classe et chaque Dresseur
ordinaire du monde : feuille féminine si et seulement si la classe est féminine).

Défauts restants : le fouet enroulé du Dompteur se lit comme un tuyau ; uniforme des Sbires plutôt
gris-brun très sombre que noir pur ; la Topdresseuse porte deux Poké Balls à la ceinture (r2) ;
Karatékas et Maître du Dojo n'avaient pas de feuille du monde propre (peinte au §13).

## 13. Finitions (2026-11-03)

Quatre finitions tranchées par Kevin, branche `claude/entree-finitions`. Planches en captures
réelles 2340 × 1080 : `entree-mer-comparatif.jpg` (banc de sable / Surf, même combat) et
`entree-finitions.jpg`. Refaire : `tools/capture_finitions.sh` puis `tools/art/planches_finitions.py`.
Art : `tools/art/entree_finitions.py` (prompts `tools/art/entree_dresseurs/finitions/`, lot
`tools/art/entree_finitions_lot.sh`) ; **5 images Codex**, toutes retenues en r1.

**1. Mer : le joueur sur son Pokémon de Surf, à choisir.** Kevin trouve le banc de sable « très
bien » et veut voir le Surf avant de choisir : la mise en scène « Surf » est un **réglage**
(`surf.enabled` de `data/battle/decors.json`, **faux par défaut** : le banc de sable `sea_open_v2`
reste intact et utilisé).
- **Monture** : celle du monde, générique (dossier 27, P-7 : « monture générique peinte »,
  `surf_monture` / `player_surf`), pas le Pokémon de l'équipe. Même monture en combat.
- **Art** : héros et joueuse montés, vus de dos (pose prête et lancer, main de `dos_hero`) :
  `dos_hero_surf(_lancer).webp`, `dos_heroine_surf(_lancer).webp`, toile 960 × 960, **bas de la
  toile = ligne d'eau**. Depuis le 2026-11-04, la joueuse a aussi son dos peint à pied
  (`dos_heroine`), et chaque costume ses dos en Surf (`dos_costume_<…>_surf(_lancer)`, §2).
- **Adversaire** [D] : le Nageur et la Nageuse **dans l'eau**, coupés au nombril, prête et lancer
  (`nageur_surf`, `nageuse_surf` + `_lancer`), comme leurs PNJ du monde (`swimmer_water`).
  `scale` [D] = celui de la classe × 0,45 (partie visible) ; joueur monté × 0,9 ; mains mesurées
  sur la hauteur visible (bloc `surf` de `trainer_intro.json`).
- **Fond** : `sea_surf` = l'ancienne mer ouverte sans sol (`sea_open_back.webp`, renommée
  `sea_surf_back.webp`), lumière dorée ; aucune image neuve.
- **Code** : `SurfStaging` (pur) : Surf si le réglage est vrai, que le joueur surfe
  (`player_mount`), que le décor a un remplaçant (`surf.decors` : `sea_open` → `sea_surf`) et que
  le combat est sauvage ou contre une classe peinte dans l'eau. [D] **Dresseurs de la terre ferme**
  (Pêcheurs sur leur îlot, Topdresseurs, Ornithologue) : banc de sable et joueur à pied, même en
  Surf (ils ne peuvent pas se tenir sur la mer ouverte). Cramois'Île garde le banc de sable.
  `BattleStage.set_place(…, surfing, wild, foe_class)`, `TrainerIntro.surf` et `art_id()`.
- Tests : `test_surf_staging`.

**2. Feuille du monde du Karatéka.** Planches de marche 4 × 4 peintes (modèle des PNJ, série 25,
128 px [D], sans planche d'attente : colonne 0) : `karateka_sheet` → apparence `blackbelt`
(bandeau, karatégi, ceinture noire, pieds nus) et `maitre_dojo_sheet` → `karate_master` (crâne
rasé, moustache et barbiche grises, revers noirs). Branchées sur les 9 PNJ (Dojo : 4 Karatékas +
le Maître ; Arène de Jadielle : 3 ; Route Victoire 2F : 1) et en repli (`trainer_intro.json`) à la
place de `cue_ball`, qui reste aux Loubards. `test_world_looks_match_the_gender_of_the_class` vert.

**3. Routes 16 ouest et 18 sur `route_17_cyclable`.** Constat : **aucune des deux n'est en bord de
mer** dans le monde (Piste cyclable en pleine forêt ; falaise au nord de la 16 ouest, étang à l'est
de la 18) ; le fond montre la mer à gauche. [D] Les hautes herbes, hors Piste (voie haute de la 16
ouest, est de la 18), prennent la prairie `route_5_6_prairie` (variantes par cases).
**Puis fond propre** (Kevin, 2026-11-03 : « peindre leur propre fond ») : `route_cyclable_foret`,
**un seul fond commun** aux deux routes (même lieu des deux côtés de la Route cyclable) : chaussée de
béton à dalles, barrière basse de lisses de bois sur poteaux de béton, haute falaise de roche
beige-ocre coiffée d'herbe à gauche (nord de la 16 ouest), forêt dense de feuillus à droite et éclat
d'un petit étang entre les arbres au loin (est de la 18), aucune mer. Recette de l'étape 3
(`ecrire_decors_ordinaires.py`, `entree_grands_combats.py decor|tuile route_cyclable_foret`,
`preparer_decor.py`) : IMAGE 1 = Argenta v3, IMAGES 2 et 3 = vues générales validées des Routes 16
ouest et 18 ; tuiles avec leur propre prompt (`tuile_route_cyclable_foret.txt`) ; **3 images Codex**
(composition + 2 tuiles, r1, recalage 0,934 et 0,877, couture invisible). Même ligne de sol que
`route_17_cyclable` (`foe_feet` [1559, 560], horizon 430). La Route 17 garde `route_17_cyclable`.
Captures : `entree-finitions.jpg`, rangées 3 (Loubard Brutus, Route 16 ouest ; Ornithologue
Albert, Route 18). Test : `test_cycling_road_routes_have_their_own_decor`.

**4. Nettoyage.** Pour chaque fichier, `git grep` du nom et du `.import` hors `docs/` : aucune
donnée, scène, script, test ni outil ne le chargeait. **Supprimés** (avec leur `.import`) :
`pewter_gym_roche_back` et `_v2_back` (Argenta v1, v2), `route_3_roche_back` (Route 3 v1),
`vermilion_gym_salle_back` (ancien Carmin), `saffron_gym_psy_back` (ancien Safrania),
`viridian_gym_sol_back` (plus aucun combat), `silph_co_bureaux_back`, `rocket_hideout_repaire_back`,
`tour_pokemon_back` (ancienne Tour ; le Manoir a son fond) ; entrées sans lieu `saffron_gym_psy`,
`vermilion_gym_salle`, `viridian_gym_sol` retirées de `decors.json`. `entree_dresseurs.py` (planche
pilote) saute désormais les fonds absents ; `serie20.py` n'écrit `tour_pokemon_back` que dans
`build/`. **Gardés** : `sea_open_back` (réutilisé, renommé `sea_surf_back`), `sea_open_v2_back`
(banc de sable), `pewter_gym_roche_v3_back`, `route_3_roche_v2_back` et les autres v2 (en service).
`dos_hero_vs.webp` n'est pas dans `main` (seulement dans l'ancien commit d5942146) : rien à
supprimer. Sprites de combat et bustes « VS » : tous branchés par convention.
