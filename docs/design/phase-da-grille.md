# Phase DA — grille d'harmonisation (J33 T2, 33A)

> Écrite d'avance le 2026-10-24 (lot DAF.0, `phase-da-cadrage.md` §3.2) pour le **T2 du J33**
> (« grille de contrôle : sols, bâtiments, personnages, Pokémon, eau, donjons, combats, menus »,
> `jalon-33.md`). Elle sert à relire l'art **après** les lots DAF.1 à DAF.7, sur S24.
> Elle ne décide rien de nouveau : références = `vision.md`, `cahier-art-monde-v0.1.md`,
> `ui-reference.md`, `ui-ux-bible-v0.1.md`, `ui-theme-2026`, états de `inventaire-art.md`.

## Mode d'emploi

1. **Par parcours** (début, milieu, fin du jeu : Bourg Palette → Argenta ; Céladopole → Safrania ;
   Route Victoire → Ligue → Grotte Azurée), sur S24 en paysage, un contrôle par ligne ci-dessous.
   Capture à l'appui pour tout écart (nom du fichier `…_NNN.png`, carte, case).
2. **Chaque écart = une ligne du registre** (`docs/tech/registre-anomalies.md`, J33) avec :
   critère de la grille (ex. `SOL-3`), priorité, carte, capture, lot d'art concerné (DAF.x).
3. **Corrections par lots d'art, pas à la main** (J33 T2). Remplacement à l'identique : mêmes
   identifiants, dimensions, emprises ; `tools/dump_map_logic.gd` avant/après doit être identique.
4. **Gel de l'art à l'entrée du J34** (DA-7) : après, seulement P0 et P1.

## Priorités (reprise du J33, tableau validé le 2026-10-21)

| P | Sens pour l'art | Traitement |
|---|---|---|
| **P0** | Illisible ou trompeur pour le joueur : on ne distingue plus un obstacle, une porte, une case d'arrêt ou une dalle ; image absente (carré rose, fond blanc) ; mauvais Pokémon ; texte coupé | corrigé avant la RC, quitte à retarder |
| **P1** | Rupture visible dans un contexte vu par tout le monde : pixel art résiduel (dos, aplat de façade), fond de combat flou, bâtiment à l'échelle fausse, raccord de carte visible, 60 i/s non tenus | corrigé avant le gel |
| **P2** | Écart de style ou de lumière perceptible mais sans gêne : intérieurs sans lumière chaude, légère différence de palette entre deux séries, ombre manquante | retouche seulement si le lot est déjà ouvert (DA-9) ; sinon accepté et documenté |
| **P3** | Détail : filet décalé de quelques pixels, variante absente d'une icône, animation sans fluidité | liste de 1.0.x |

Règle de départ (règle 3 de `CLAUDE.md` + DA-9) : un défaut de **rendu** ne devient P2 ou plus que
s'il est visible à l'échelle du jeu (1 case = 96 px) sur la planche S24.

## Grille

Colonnes : **ID** · **Critère** (ce qu'on regarde) · **Seuil d'alerte** · **P par défaut** · **Lot**.

### SOL — sols et décors de terrain

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| SOL-1 | Sol peint sur toute la carte (pas de tuile de placeholder, pas de trou noir) | une case de repli visible | P1 | DAF.3/4/5 |
| SOL-2 | Raccord entre deux cartes ou deux séries (route ↔ ville, J21 ↔ J22 Route 16) | ligne de couleur, changement net de lumière ou d'échelle de brins | P1 si franc, P2 sinon | DAF.5 |
| SOL-3 | Lisibilité des cases spéciales : herbes hautes, dalles fléchées, cases d'arrêt, pentes, Piste | indiscernables à 1 m du téléphone | P0 | DAF.4 |
| SOL-4 | Forêt de Jade : zones sombres hors clairières, `DenseForest` | forêt aussi claire qu'une route | P2 | DAF.6 |
| SOL-5 | Variété : pas de répétition visible de la même texture sur 3 écrans | motif répété repérable | P3 | — |
| SOL-6 | Ombre au sol des props posés (contact, ombre portée) | objet « flottant » | P2 | DAF.5 |

### BAT — bâtiments (façades, intérieurs)

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| BAT-1 | **Aucune façade en aplat** (dessinée par `placeholders_*.py`) | 1 façade de `placeholders_safrania.py` en jeu | P1 | DAF.3 |
| BAT-2 | **Aucun intérieur en aplat** (`ph_*`) hors références de taille | 1 `ph_*` utilisé par une carte | P1 | DAF.3/4 |
| BAT-3 | Échelle et emprise : porte à la bonne case, toit/mur dans la grille, personnage 128 px plausible dans l'embrasure | porte décalée, escalier hors emprise | P1 | DAF.3 |
| BAT-4 | Lumière : façade en **lumière neutre** (méthode C) cohérente avec l'heure (jour/nuit) | façade « dorée » en pleine nuit | P2 | DAF.6 |
| BAT-5 | Intérieurs : lumière chaude et décor riche des références (`chambre-joueur-v1`, `labo-chen-v1`) | pièce vide ou grise | P2 | DAF.6 |
| BAT-6 | Coques partagées de la série 22 bis (4F recoloré, Résidence) | deux étages identiques côte à côte | P2 (DA-9) | DAF.5 si signalé |
| BAT-7 | Cohérence de série à l'intérieur d'une même ville (Safrania : poste, Dojo, Arène, Sylphe) | styles de toiture mélangés | P2 | DAF.3 |
| BAT-8 | Mont Sélénite : masse d'ardoise, bouche du sas | entrée illisible | P2 | DAF.6 |

### PER — personnages

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| PER-1 | Aucun sprite pixel visible (héros, rival, PNJ, Dresseurs, compagnons) ; **sprites provisoires** des J28 à J31 (Olga, Aldo, Agatha, Peter, Giovanni Champion) repeints | un sprite `placeholder/` à l'écran | P1 | DAF.4 |
| PER-2 | Série 25 intégrée : héros à vélo, héros qui pêche, Motard, Ornithologue, Loubard, frères pêcheurs | feuille absente ou carré | P1 | DAF.5 |
| PER-3 | Hauteur 128 px (enfant ≈ 108), origine aux pieds, ombre au sol | pieds qui flottent ou s'enfoncent | P2 | — |
| PER-4 | Animations : marche 4 directions, attente, prière/pêche/vélo | image qui saute ou sens inversé | P2 | DAF.8 |
| PER-5 | Orientations dans les cinématiques ; sauts et recul du starter | personnage de dos qui parle | P3 | DAF.8 |

### POK — Pokémon (dehors, combat, menus)

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| POK-1 | **Dos de combat peints** pour les 151 espèces ; aucun dos 64 px pixel | 1 dos pixel en combat | **P1** | DAF.1 |
| POK-2 | Identité : dos reconnaissable de l'espèce (couleur, silhouette, accessoire : cuillère de Kadabra…) | dos d'une autre espèce | **P0** | DAF.1 |
| POK-3 | Cadrage et taille des dos (sujet ≤ 870 px de 1024, bas à 120 px), pieds sur la ligne de sol du fond | Pokémon qui flotte ou coupé | P1 | DAF.1 |
| POK-4 | Faces : artwork officiel pour les 151 ; plus de face pixel (Saquedeneu, Rhinocorne, Kangourex) | face pixel en combat | P1 | DAF.1/5 |
| POK-5 | Cohérence face ↔ dos (couleur, forme) pour une même espèce à l'écran de combat | teinte nettement différente | P2 | DAF.1 |
| POK-6 | Pokémon fixes du monde et compagnons (27 + série 25) peints, même main | pixel ou carré | P1 | DAF.5 |
| POK-7 | Pokémon qui coupent, nagent, volent sans planche d'exploration | image fixe glissante | P3 | DAF.8 |
| POK-8 | Pokédex, Équipe, Sac : visuels pris des mêmes fichiers que le combat | image absente | P1 | DAF.1 |

### EAU — eau, côtes, glace

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| EAU-1 | Eau lisible comme surfable/non surfable ; bord, écume, reflets | on ne sait pas où l'on peut aller | P0 | DAF.5 |
| EAU-2 | Routes 19 à 21, Îles Écume : décor de combat marin (`sea_open`, `seafoam_ice`) branché | repli flou en combat | P1 | DAF.2 |
| EAU-3 | Pêche : canne, ligne, bouchon, éclaboussure ; icônes des 3 cannes | icône absente | P2 | DAF.5 |
| EAU-4 | Courants et glaçons des Îles Écume (J24) lisibles | courant invisible | P1 | DAF.4/6 |
| EAU-5 | Raccord côte ↔ sable (Route 25, Cap d'Azuria, Cramois) | rive découpée au cutter | P2 | DAF.5 |

### DON — donjons et grottes

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| DON-1 | Kits en placeholder remplacés : Arène de Jadielle (dalles, cases d'arrêt), Route Victoire (interrupteur, barrière, gardes), cinq salles de la Ligue + Panthéon, Grotte Azurée (3 niveaux) | tuile `InteriorTiles` ou kit repaire visible | P1 | DAF.4 |
| DON-2 | Voile d'obscurité et lampes (Flash) : lisibilité sans Flash, avec Flash | tout noir ou tout clair | P1 | DAF.6 |
| DON-3 | Murs, plafonds, escaliers : sens de lecture du niveau (haut/bas) | étage indiscernable | P1 | DAF.4 |
| DON-4 | Puzzles : trous, rochers, interrupteurs (Manoir), dalles de téléportation (Sylphe) visibles | élément interactif camouflé | P0 | DAF.3/4 |
| DON-5 | Variété d'ambiance entre grottes (Mont Sélénite, Grotte Sombre, Écume, Azurée) | deux grottes identiques | P3 | DAF.6 |
| DON-6 | Tour Pokémon et Repos des esprits : ambiance, lumière spectrale | scène trop claire | P2 | DAF.6 |

### CMB — combats

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| CMB-1 | **Fond de combat dédié** pour chaque carte à combats (50 / 66 sur `main` ; ≈ 30 de plus après fusion) | repli « carte floutée » dans le parcours principal | **P1** (Forêt de Jade, Routes 2/22/25, Arène d'Argenta) ; P2 ailleurs | DAF.2 |
| CMB-2 | Alignement des pieds adversaire et joueur sur la ligne de sol du fond | décalage > 1/2 case | P1 | DAF.2 |
| CMB-3 | Lisibilité jour/nuit et contraste des barres de PV sur le fond | barre illisible sur fond clair | P0 | DAF.2/6 |
| CMB-4 | Détails du J9 : voile du poison, bouton ARRÊTER, icône de l'Antidote | élément absent | P3 | DAF.8 |
| CMB-5 | Animations d'attaque, entrée en scène, K.O. : fluidité sur S24 | < 50 i/s | P2 | DAF.8 |
| CMB-6 | Boss et cinématiques (Ligue, Mewtwo) : image de combat et fond dédiés | fond générique pour le Champion | P2 | DAF.2/4 |

### MEN — menus, UI, identité

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| MEN-1 | Thème 2026 respecté (tokens, formes, tailles tactiles ≥ 48 dp) sur chaque écran du menu Dresseur | bouton < 48 dp ou style ancien | P1 | — |
| MEN-2 | **Icône pour chaque objet du Sac** (≈ 23 manquantes sur `main`) | objet sans icône | P1 | DAF.5 |
| MEN-3 | Textes entièrement visibles (accents, longueurs) en paysage 2340 × 1080 | texte coupé | **P0** | — |
| MEN-4 | Icône de l'appli et écran de démarrage (remplace « GODOT ») ; écran titre | splash Godot ou icône par défaut | P1 | DAF.7 |
| MEN-5 | Carte du monde / Carte de la ville : vues peintes des zones J26 à J31 | zone absente ou grise | P2 | DAF.5 |
| MEN-6 | Cohérence menus ↔ monde ↔ combat (ton, couleur dominante, ombres) | écart de palette flagrant | P2 | — |
| MEN-7 | Performance : 60 i/s et mémoire des textures sur S24 et A17 | < 50 i/s, > budget de mémoire du J33 | P1 | DAF.6 |

### GLO — global

| ID | Critère | Seuil d'alerte | P | Lot |
|---|---|---|---|---|
| GLO-1 | Plus aucune image `placeholder/` à l'écran (tout sprite, façade, intérieur ou fond) | 1 occurrence | P1 | tous |
| GLO-2 | Style unique « 2D HD peinte, même main » : lumière dorée du monde, personnages peints simplifiés | série qui détonne (couleurs saturées, contours durs) | P2 | tous |
| GLO-3 | `tools/dump_map_logic.gd` avant/après chaque lot : zéro différence | différence | P0 | tous |
| GLO-4 | Suite complète verte après chaque lot (`tools/test.sh`) | test rouge | P0 | tous |

## Lignes de départ (état au 2026-10-24, `main` @ `91770ba0`)

Ce qu'on sait déjà échouer avant le moindre lot : POK-1 (125 / 125 pixel), POK-4 (3 faces pixel),
CMB-1 (16 cartes sans fond, dont 6 à produire), BAT-1/BAT-2 et PER-1/DON-1 (sur les branches J26 à
J31), PER-2 (série 25 non intégrée), MEN-2 (≈ 23 icônes), MEN-4. Détail : `inventaire-art.md`.
