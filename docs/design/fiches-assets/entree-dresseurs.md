# Fiche d'art — Entrée des combats de Dresseur (v1, 2026-11-02)

Spécification : `docs/design/dossier-05-combat.md` §3 (décision de Kevin du 2026-11-02).
Code et déroulé livrés avec des images **provisoires** (vidéo : `entree-dresseurs-v1.mp4`) ; cette
fiche liste l'art définitif à produire par lots (Codex), qui **se branche sans code** : il suffit de
déposer le fichier au bon chemin (sinon le jeu retombe sur l'image provisoire).

Données : `data/battle/trainer_intro.json` (classes, grands adversaires, chemins, durées [D]) ;
grands combats = Dresseurs dont le bloc `card` de `data/trainers/*.json` a un `portrait`.
Listes vérifiées par `tests/integration/test_trainer_intro_data.gd`.

## 1. Sprites de combat de face (un par classe et par grand adversaire)

- **Chemin** : `assets/sprites/trainers/battle/<id>.webp` (id = classe ci-dessous, ou identifiant
  de portrait d'un grand adversaire, §2).
- **Format** : WebP RGBA, **fond transparent**, toile **512 × 768 px** (portrait 2:3), personnage
  **en pied, de face** (léger trois-quarts permis), **pieds posés sur le bord bas, centrés**
  (origine aux pieds, bas-centre de l'image), tête à ~40 px du haut ; aucune ombre portée au sol
  (le jeu n'en dessine pas pour l'instant).
- **Affichage** : hauteur de l'image ramenée à 0,42 × la hauteur d'écran (≈ 454 px sur 1080),
  filtre linéaire ; posé à l'ancre de l'adversaire (en haut à droite du décor).
- **Rendu** : même main que les personnages peints du jeu (« peints simplifiés », 2D HD),
  **lumière neutre** (le décor de combat donne l'ambiance), pas de contour noir épais, palette et
  tenue fidèles au sprite d'exploration de la classe (colonne « apparence du monde »).
- **Pose** : debout, prêt à lancer (Poké Ball en main conseillée, main droite à l'écran ≈ 22 %
  de la largeur à gauche du centre, à mi-hauteur : la Ball lancée part de là).
- **Repli actuel** : première image de l'apparence du monde, agrandie (flou assumé), sinon une
  silhouette.

### Classes de Dresseurs ordinaires (33 classes, 260 combats)

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
| `sbire_rocket` | Sbire Rocket | 37 | `rocket_grunt_m` |
| `scientifique` | Scientifique | 13 | `researcher` |
| `scout` | Scout | 11 | `scout` |
| `topdresseur` | Topdresseur | 8 | `cooltrainer_m` |
| `topdresseuse` | Topdresseuse | 4 | `cooltrainer_f` |

Ordre de production conseillé (combats les plus vus d'abord) : `sbire_rocket`, `jeune_dresseuse`,
`nageur`, `scientifique`, `exorciste`, `motard`, `ornithologue`, `scout`, `gamin`, puis le reste.

À noter : 11 des 37 Sbires Rocket sont des femmes dans le monde (`rocket_grunt_f`) ; une seule
classe pour l'instant (question pour Kevin, §5).

## 2. Grands adversaires (13 portraits, 22 combats)

Chaque grand adversaire demande **deux** images : le sprite de face du §1 (même id) et un
**portrait de banderole** pour la séquence « VS ».

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
| `rival` (+ `rivale`) | 8 combats : `rival_lab`, `rival_route22`, `rival_cerulean`, `rival_ss_anne`, `rival_tower`, `rival_silph`, `rival_route22_final`, `rival_champion` | Rival / Maître de la Ligue | `rival` / `rival_heroine` |

Le rival suit l'apparence choisie à l'ouverture : prévoir `rival.webp` **et** `rivale.webp`
(soit 14 portraits et 14 sprites de face pour couvrir les deux apparences).

### Format du portrait de banderole

- **Chemin** : `assets/ui/battle/vs/<id>.webp`.
- **Format** : WebP RGBA, fond transparent, **≈ 540 × 720 px** (3:4), **buste** (tête et épaules,
  haut du torse), regard tourné vers le centre de l'écran (l'adversaire est à droite de sa
  banderole rouge : il regarde vers la **gauche**). Haut de la tête à ~40 px du bord haut.
- **Affichage** : hauteur ramenée à 0,5 × l'écran, débordant de 0,03 au-dessus de la banderole
  (hauteur 0,30) et rogné par elle : seuls le visage et les épaules restent visibles ; garder
  l'essentiel dans les **60 % supérieurs** de l'image.
- **Rendu** : peint, même main que les bustes du menu (`assets/ui/menu/hero_bust.webp`), lumière
  neutre, expression de défi.
- **Repli actuel** : portrait d'introduction du rival (`rival_portrait.png` / `rivale_portrait.png`)
  pour le rival ; sinon le sprite de face (ou son repli).

### Joueur

Le portrait bleu du joueur reprend le **buste du menu** selon l'apparence et le costume porté
(`TrainerLooks.bust_path`) : rien à produire pour ce chantier ; un buste dédié pourra le remplacer
plus tard. Le dos du joueur (entrée) est le lancer de dos existant (`TrainerLooks.thrower_path`).

## 3. Emblème « VS »

Provisoire dessiné en code (éclair `ACCENT` et lettres « VS » cernées). Facultatif :
`assets/ui/battle/vs/emblem.webp` (non branché à ce jour, à brancher si un emblème peint est
produit).

## 4. Valeurs par défaut [D] (réglables dans `data/battle/trainer_intro.json` et `UiTokens.VS_*`)

- Séquence « VS » : entrée 0,35 s, tenue 0,9 s, sortie 0,4 s (≈ 1,65 s) ; banderole rouge
  `#C8323C` en haut, bleue `#2F64C8` en bas, liseré `ACCENT`, voile du monde à 50 %.
- Entrée du niveau 1 : dresseurs 0,45 s + rangée de Balls 0,25 s, lancer 0,35 s + effacement
  0,3 s par camp (≈ 2,0 s sans les messages).
- Rangée de Poké Balls : 6 emplacements dans la zone de la carte adverse (pleine / éteinte /
  vide), taille 0,065 × l'écran.

## 5. Questions ouvertes (pour Kevin)

1. Sbires Rocket femmes : un sprite de face distinct (`sbire_rocket_f`) ?
2. Combat du labo (`rival_lab`) : la séquence « VS » est jouée (le rival est un grand adversaire),
   mais les dresseurs n'entrent pas (les Pokémon viennent du monde) : à confirmer.
3. Revanches (après une défaite contre un Champion) : la séquence « VS » est rejouée (« jamais
   sautée ») ; l'ancienne carte n'apparaissait qu'à la première rencontre.
4. Titres [D] du rival : « Rival », et « Maître de la Ligue » pour le dernier combat.
