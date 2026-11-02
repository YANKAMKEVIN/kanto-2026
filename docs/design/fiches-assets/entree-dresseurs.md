# Fiche d'art : Entrée des combats de Dresseur (v2, 2026-11-02)

Spécification : `docs/design/dossier-05-combat.md` §3 (décisions de Kevin du 2026-11-02).
**Cible de rendu validée par Kevin (« exactement ça »)** : les trois maquettes
`docs/design/reference/entree-dresseur-ordinaire-v1.png`, `entree-dresseur-lancer-v1.png`,
`entree-dresseur-vs-v1.png`. Tout l'art de ce chantier doit **atteindre ce rendu** : personnages
peints dans la même main que les maquettes (2D HD, anime peint, contours fins, ombres douces),
bustes peints au cadrage des maquettes, banderoles à l'effet pinceau. Exception : la rangée de
Poké Balls de la maquette 2 (en haut à gauche) **n'est pas retenue** : le cartouche est au-dessus
de l'adversaire (maquette 1).

Code et déroulé : livrés avec des images **provisoires** (vidéo `entree-dresseurs-v2.mp4`,
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
- **Affichage** : 0,27 × la hauteur d'écran (≈ 290 px sur 1080), pieds à (0,43 ; 0,55) en hauteurs
  d'écran depuis le centre ; ombre au sol elliptique sous les pieds ; cartouche des Balls
  au-dessus de la tête.
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
  droite**, pieds sur le bord bas centrés ; affiché à 0,55 × la hauteur d'écran, pieds à
  (−0,50 ; 0,93) : grand, au premier plan en bas à gauche.
- **Costume porté** : le jeu garde le lancer de dos du costume (pas de pose dédiée).
- **Repli actuel** : le lancer de dos existant (`heros_lancer.png` / `joueuse_lancer.png`),
  agrandi.

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
- **Affichage** : hauteur 0,5 × l'écran, haut de l'image en haut de l'écran, **rogné par le bas de
  la banderole** (seuls tête et épaules restent visibles, ≈ 55 % supérieurs de l'image).
- **Repli actuel** : portrait d'introduction du rival, sinon le sprite de face (ou son repli).
- **Joueur** : buste du menu selon l'apparence et le costume (`TrainerLooks.bust_path`), affiché en
  bas à gauche, rogné par le bas de l'écran, regard vers la droite ; un buste dédié au cadrage de
  la maquette (Kevin : tête, épaules, haut du torse) pourra le remplacer.

## 4. Banderoles « VS » (pinceau, remplaçables)

- **Chemins** : `assets/ui/battle/vs/banderole_rouge.webp` et `banderole_bleue.webp`.
- **Format** : WebP RGBA, fond transparent, **≈ 2048 × 300 px**, coup de pinceau peint (couleur
  pleine, traînées et éclaboussures), **bout intérieur déchiré à gauche** pour la rouge ; la bleue
  est dessinée de la même façon (le jeu la retourne : son bout déchiré est à droite).
- **Affichage** : épaisseur 0,22 × l'écran, inclinée de 4° (rouge en haut à droite, bleue en bas à
  gauche) ; nom en capitales Cinzel gras, or clair cerné de brun, filet et losange, titre dessous.
- **Repli actuel** : pinceau dessiné en code (bandes à bord déchiré, traînées, liseré clair).
- **Police** : Cinzel (SIL OFL 1.1) ajoutée dans `assets/fonts/cinzel/` (licence `OFL.txt` à côté).

## 5. Emblème « VS »

Dessiné en code : lettres Cinzel or cernées de brun, éclair doré en diagonale, deux traits
horizontaux qui s'effacent. Un emblème peint (`assets/ui/battle/vs/emblem.webp`, doré, éclat) peut
être produit ; il n'est pas encore branché.

## 6. Valeurs par défaut [D] (`data/battle/trainer_intro.json`, `UiTokens.VS_*`)

- Ordinaire : les dresseurs entrent 0,55 s après le début de la caméra (0,45 s), puis le cartouche
  et ses Balls (0,25 s) ; chaque lancer 0,4 s + accompagnement 0,2 s + recul en fondu 0,3 s, sous
  son message. **≈ 4,1 s** du début du combat aux commandes (mesuré sur la vidéo).
- Grand combat : la même entrée, puis le « VS » (0,3 + 0,75 + 0,35 = **1,4 s**), puis les lancers.
- Cartouche : verre sombre de l'interface, 6 emplacements (plein / éteint / vide), au-dessus de la
  tête de l'adversaire, décalé de 0,16 vers l'extérieur ; il part au lancer de l'adversaire, avant
  les jauges.

## 7. Écarts restants avec les maquettes (sans l'art définitif)

1. **Personnages** : repli sur l'apparence du monde agrandie (adversaires) et sur le lancer de dos
   (joueur, toujours dans la pose bras tendu de la maquette 1) : flous, de face et non de
   trois-quarts, pas de vraie pose de lancer (élan seulement) tant que les images du §1 et du §2
   manquent.
2. **Bustes** : Pierre utilise son apparence du monde, en pied et petite, au lieu du buste peint.
3. **Banderoles** : pinceau dessiné en code, plus net et plus plat que le pinceau peint.
4. **Emblème** : lettres et éclair plus fins et sans éclat lumineux.
5. **Cadrage du « VS »** : mêmes positions que l'entrée ordinaire ; sur la maquette 3 les deux
   dresseurs sont un peu plus hauts et plus proches du centre (cadrage d'Arène). Réglable dans
   `points` si Kevin le souhaite.
6. **Traînée de la Ball** : plus fine et plus courte que sur la maquette 2 (réglable :
   `trail_width`).
