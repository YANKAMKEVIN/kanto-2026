# Série Johto — vues générales (acte 1 : JOH1 à JOH5 ; actes 2 et 3 : JOH6 à JOH9)

> 2026-11-03, branche `claude/johto-vues-acte1` depuis `main`. Vues de **DA et de composition** ; la
> géométrie vient des grilles validées de `tools/plans/` (JOH1 à JOH9 validées par Kevin les 2026-11-02 et
> 2026-11-03), qui **font foi**. Les écarts ci-dessous ne seront pas reproduits au code.

Méthode (modèle du J22, T9) : `python3 tools/art/vues_johto_acte1.py --plans johN` (plans en aplats SANS
annotation, joints à Codex, `build/art/PLAN_*_codex.png`), puis `tools/art/generer.sh` avec un prompt versionné
par image (`tools/art/prompts/CONCEPT_<ZONE>_VUE_GENERALE_r*.txt` : ADN v1, **lumière NE** (les profils
`johto_*` du JOH0 portent l'éclairage), aucun personnage ni Pokémon, aucun texte). Plans annotés qui font foi :
`--plans-annotes johN` → `docs/design/reference/plans-johto/<carte>-plan-v1.png`. Planche de relecture :
`--planche johN` → `docs/design/reference/johN-vues-v1.png` (chaque vue à côté de son plan annoté).

Défauts pris **[D]**, à confirmer par Kevin sur la planche du JOH1 :

- **Kit de bâtiments de Kanto repris tel quel à Johto** : Centre (toit rouge) et Boutique (toit bleu)
  identiques à ceux de Kanto, maisons de même facture ; aucun dossier Johto ne demande une architecture
  propre.
- **Rues pavées** à Oliville (la grille les note `p` pavé), là où Kanto a des rues de terre battue.
- **Grottes marines** : roche sombre humide, eau turquoise au bord et bleu profond au large, rais de lumière
  tombant des fissures (dossier JOH-02 §3.2 : profil `cave_1f` éclairci de bleu) ; référence de style jointe
  = Îles Écume B4F (même roche, même eau, sans glace).
- **Ombre de Lugia** peinte dans la salle 2 (silhouette floue sous l'eau profonde), seule entorse à
  « aucun Pokémon » : la cinématique O-6 la montrera en jeu, la vue sert de repère.

## JOH1 — grotte marine et Oliville (planche `joh1-vues-v1.png`) — **validé par Kevin le 2026-11-03**

Les défauts ci-dessus sont donc confirmés et servent de règle pour les jalons suivants.

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `grotte-marine-1-vue-generale-v1.png` | r1 / 1 | `iles-ecume-b4f-vue-generale-v1.png` |
| `grotte-marine-2-vue-generale-v1.png` | r1 / 1 | salle 1 (ci-dessus) + `iles-ecume-b4f-vue-generale-v1.png` |
| `oliville-vue-generale-v1.png` | r1 / 1 | `carmin-vue-generale-v1.png` |

Codex : aucun refus, trois images en un essai chacune (≈ 2 min par image).

### Écarts avec les grilles (la grille fait foi)

- **Grotte marine, salle 1** : les groupes de rochers isolés sont rendus en une rangée de trois rochers
  (grille : blocs de 3 × 2 au nord-est et 3 × 3 au sud-ouest) ; le chenal de sortie sud paraît un peu plus
  large que ses 2 cases ; le courant est peint en deux traînées d'écume (lisible, conforme au sens).
- **Grotte marine, salle 2** : les groupes de rochers sont rendus en 2 × 2 (grille : 3 × 3) ; le chenal du
  courant est peint comme une **cascade** qui descend vers la plage, alors que la grille le veut **à plat**,
  au niveau de l'eau (le jeu y posera une glissade sur l'eau, sans dénivelé) ; la brèche de sortie, l'îlot du
  sud-est et le gouffre central sont conformes.
- **Oliville** : l'avenue s'arrête contre la forêt avant le bord est (la grille sort par le bord, x 49,
  vers la Route 39) ; le dessus de la falaise ouest et du promontoire est couvert de verdure (grille :
  rochers nus) ; la rue du quai et le quai sont un peu plus courts à l'ouest ; la petite haie du nord-est
  (y 23) est rendue à droite de l'avenue, conforme ; phare, bouche de grotte, plage de galets, deux pontons,
  caisses, récifs du sud et leur ouverture centrale : conformes.
- **Toutes** : lumière neutre respectée (Oliville blanche et diffuse ; grottes en pénombre bleue froide).

## JOH2 — Routes 39 et 38, Rosalia (planche `joh2-vues-v1.png`) — **validé par Kevin le 2026-11-03**

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `route-39-vue-generale-v1.png` | r1 / 1 | `route-25-vue-generale-v1.png` (falaise, mer, maison) |
| `route-38-vue-generale-v1.png` | r1 / 1 | `route-13-vue-generale-v1.png` (prairie, lumière neutre) |
| `rosalia-vue-generale-v1.png` | r1 / 1 | `argenta-vue-generale-v1.png` (Centre et Boutique identiques) |

Défaut pris **[D]** : à Rosalia, les **érables** repères (`G`) ont un feuillage vert profond touché de rouge
sombre (le dossier dit « érables » sans couleur ; la forêt autour reste verte) ; la **Tour Carillon** est une
pagode à toits étagés rouge-brun, la **Tour Cendrée** une tour de bois noircie au toit troué, sans flamme ni fumée ;
la Ferme Meumeu a une mangeoire et un abreuvoir dans l'enclos (accessoires, pas de collision).

### Écarts avec les grilles (la grille fait foi)

- **Route 39** : la Ferme Meumeu est peinte comme une maison ordinaire (≈ 6 × 4) plutôt qu'une grande ferme de
  7 × 6 ; la falaise au-dessus de la mer est une simple rangée de rochers (grille : 2 rangées, x 1..9, y 30..31) ;
  l'enclos et les deux panneaux sont conformes ; le chemin de l'ouest est conforme.
- **Route 38** : la barrière d'arbres (x 43..46) est rendue en une haie d'arbres d'une case au lieu de quatre, le
  passage d'une case est bien là ; l'impasse du sud (x 33..34) est rendue en couloir étroit entre deux haies, à peine
  plus long que deux cases ; les deux arbres sous le palier ouest et le gros tronc du nord (35, 6) sont là ; la falaise
  s'arrête un peu avant le bord est.
- **Rosalia** : la rue de l'est s'arrête contre la forêt avant le bord (la grille sort par x 55) ; des haies
  basses supplémentaires devant les portes des deux maisons de l'est ; la bande d'herbe à l'ouest du chemin gardé
  (x 36..40, y 9..12) est plus courte ; la Tour Carillon dépasse du bois sans l'« herbe de la tour » autour ;
  avenue, rue du sud, chemin gardé, Tour Cendrée et ses deux bandes d'herbe, maison des sages et sa haie, Centre,
  Boutique, massifs, bancs : conformes.
- **Toutes** : lumière neutre respectée.

## JOH3 — Routes 37, 36, 35, Doublonville, Souterrain (planche `joh3-vues-v1.png`) — **validé par Kevin le 2026-11-03**

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `route-37-vue-generale-v1.png` | r1 / 1 | `route-38-vue-generale-v1.png` (Johto, lumière neutre) |
| `route-36-vue-generale-v1.png` | r1 / 1 | `route-13-vue-generale-v1.png` (prairie, eau, lumière neutre) |
| `route-35-vue-generale-v1.png` | r1 / 1 | `route-39-vue-generale-v1.png` (Johto, eau, clôture blanche) |
| `doublonville-vue-generale-v1.png` | r1 / 1 | `celadopole-vue-generale-v1.png` (grande ville, grand magasin) |
| `souterrain-doublonville-vue-generale-v1.png` (plan `souterrain-doublonville-plan-v1.png`) | r1 / 1 | `souterrain-vue-generale-v1.png` (Souterrain de Kanto) |

Outil : `vues_johto_acte1.py` connaît désormais un genre `interieur` (Souterrain : murs, sol, devantures, escaliers
sur fond noir) et des **styles par grille** (la lettre `P` est le Phare à Oliville, la grille du Parc sur la Route 36,
le poste de garde sur la Route 35 ; `x` est une clôture sur la Route 35 ; `E` un escalier à Doublonville).

Défauts pris **[D]** : Tour Radio = tour moderne claire à toit plat et grande antenne rouge et blanche ; Grand Magasin
= toit jaune doré, vitrines, terrasse sur le toit ; gare = façade de pierre grise à horloge, portes closes ; Souterrain =
ancienne galerie marchande aux rideaux de fer baissés, néons froids ; portail du Parc National = grille de fer forgé
entre deux piliers de pierre, sans bâtiment ; arbres fruitiers de la Route 37 = ronds et bas, fruits rouges.

### Écarts avec les grilles (la grille fait foi)

- **Route 37** : conforme (chemin et chicane, bosquet, trois arbres fruitiers, deux poches d'herbes, trois arbres,
  panneau à gauche du chemin en haut).
- **Route 36** : le pont est peint **fini** (planches neuves) plutôt qu'inachevé, la barrière rayée est là ; les deux
  panneaux ont l'air de petits bancs ; la rivière est conforme ; le petit massif de fleurs est là.
- **Route 35** : conforme (étang, rocher, trois poches, poste à porte ouest, clôture et passage d'une case, touffe
  d'herbe) ; les arbres isolés sont un peu plus gros que la grille.
- **Doublonville** : la **place centrale** n'est pas élargie (le pavé garde la largeur de l'avenue, seuls les quatre
  massifs et les deux escaliers la marquent) ; l'escalier nord-ouest est collé à l'avenue (grille : (31, 25), trois cases à
  l'ouest) ; la haie à l'est du Grand Magasin est rendue, celle du nord-ouest aussi ; le parvis de la gare est conforme ;
  pas de panneau visible près de l'avenue au nord.
- **Souterrain** : conforme (galerie, trois renfoncements, devantures fermées des deux côtés, deux escaliers, salle du
  fond et sa caisse) ; la salle du fond est un peu moins profonde que ses 4 rangées.
- **Toutes** : lumière neutre respectée.

## JOH4 — Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss (planche `joh4-vues-v1.png`) — **validé par Kevin le 2026-11-03**

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `route-34-vue-generale-v1.png` | r1 / 1 | `route-39-vue-generale-v1.png` (Johto, mer, clôture) |
| `bois-aux-chenes-vue-generale-v1.png` | r1 / 1 | `foret-jade-vue-generale-v1.png` (forêt serrée) |
| `ecorcia-vue-generale-v1.png` | r1 / 1 | `rosalia-vue-generale-v1.png` (Johto, maisons anciennes) |
| `puits-ramoloss-b1f-vue-generale-v1.png` | r1 / 1 | `mont-selenite-vue-generale-v1.png` (roche, échelles) |
| `puits-ramoloss-b2f-vue-generale-v1.png` | r1 / 1 | B1F (ci-dessus) + `mont-selenite-vue-generale-v1.png` |

Défauts pris **[D]** : maisons d'Écorcia au **toit de chaume** (dossier JOH-05 §3) ; charbonnerie en bois noirci à cheminée
de pierre, sans porte, sacs de charbon contre le mur ; puits = margelle de pierre et trou à échelle, sans toit ;
autel du Bois = petit autel de bois moussu entre deux massifs de fleurs ; mer de la Route 34 au pied d'un simple talus
herbeux (pas de falaise) ; puits = roche sombre humide, eau claire, lumière du jour par le trou de l'échelle d'entrée.

### Écarts avec les grilles (la grille fait foi)

- **Route 34** : conforme (chemin droit, mer sur deux colonnes, étang, maison, trois poches, clôture et passage d'une
  case, six arbres) ; le passage de la clôture est peint au milieu du chemin plutôt que sur sa colonne ouest (10, 40).
- **Bois aux Chênes** : conforme (trois traversées, deux poches d'herbes sur le sentier, deux poches latérales, clairière,
  sente, autel fleuri, impasse de l'ouest, souche, bûches, panneau) ; la poche de sous-bois à droite de la clairière et
  celle de la Dresseuse sous la troisième traversée sont un peu plus petites.
- **Écorcia** : conforme (trois rues, charbonnerie, puits en cour ouverte, Centre, Boutique, deux maisons, arbres) ; la
  margelle du puits est rendue en dalles plates et le trou à échelle devant, sans les deux murets latéraux.
- **Puits B1F** : conforme (salle d'entrée, goulet sous sa niche, salle des rochers, descente de droite, grande salle
  basse, nappe d'eau, trois zones de gravats, sept rochers, deux échelles).
- **Puits B2F** : conforme (salle de l'échelle, couloir, grande salle et mare, gravats, passage et couloir de droite,
  alcôve et ses deux caisses) ; le couloir de droite est un peu plus large que ses 3 cases.
- **Toutes** : lumière neutre respectée ; les grottes en pénombre bleue froide.

## JOH5 — Tour Radio 1F à 5F (planche `joh5-vues-v1.png`) — **validé par Kevin le 2026-11-03**

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `tour-radio-1f-vue-generale-v1.png` | r1 / 1 | `poste-15-v1.png` (intérieur du J22, lumière neutre) |
| `tour-radio-2f-vue-generale-v1.png` | r1 / 1 | 1F + `poste-15-v1.png` |
| `tour-radio-3f-vue-generale-v1.png` | r1 / 1 | 2F + `poste-15-v1.png` |
| `tour-radio-4f-vue-generale-v1.png` | r1 / 1 | 3F + `poste-15-v1.png` |
| `tour-radio-5f-vue-generale-v1.png` | r1 / 1 | 4F + `poste-15-v1.png` |

Chaque étage a reçu l'étage précédent en référence : même sol dallé, mêmes murs crème à bandeau bleu, même porte
d'ascenseur, mêmes escaliers, d'un bout à l'autre de la tour.

Défauts pris **[D]** : décor « radio moderne » (murs crème, bandeau bleu sobre, logo rond à ondes sans texte au 1F,
panneaux acoustiques gris dans les studios, lampes « à l'antenne » éteintes, mur d'écrans à courbes, câbles au sol de la
régie, baie du 5F sur les toits de Doublonville de jour) ; l'ascenseur en panne porte un petit panneau sans texte ;
la réserve du 3F est une pièce de cartons derrière une porte cadenassée ; l'escalier de secours du 5F est une porte
métallique dans le mur est.

### Écarts avec les grilles (la grille fait foi)

- **1F** : conforme (niche de l'escalier et ses deux cloisons, ascenseur, comptoir, bancs, sortie) ; les deux
  « plantes » des coins hauts (M en (1, 4) et (22, 4)) sont peintes en caisses de bois.
- **2F** : conforme (deux studios vitrés et leurs portes au sud, pupitre et haut-parleur au milieu du couloir du bas,
  escaliers, ascenseur) ; les plantes des coins sont là.
- **3F** : conforme (cloison centrale à un seul passage en bas, cinq rayonnages, réserve et sa porte à l'ouest) ; la
  niche du gardien (13, 11) ne se lit pas comme une niche (la cloison y est simplement interrompue).
- **4F** : conforme (mur d'écrans, deux rangées de pupitres coupées au milieu, câbles) ; les deux cloisons de la niche
  de l'escalier qui monte (x 19 et x 21) sont rendues en piliers de part et d'autre des marches, pas en cloisons de deux cases ;
  une plante de plus dans le coin nord-ouest (grille : M en (1, 1), conforme).
- **5F** : conforme (bureau fermé et sa porte, palier, ascenseur, escalier qui descend, vitre de studio percée au centre,
  table de diffusion, baie vitrée, porte de secours) ; la vitre de studio est peinte à mi-hauteur (garde-corps vitré)
  plutôt qu'en cloison de verre du sol au plafond.
- **Tous** : lumière neutre respectée.

## JOH6 — Tour Cendrée, Route 42, Acajou, boutique, Route 43, Lac Colère, repaire (planche `joh6-vues-v1.png`) — **validé par Kevin le 2026-11-03**

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `tour-cendree-1f-vue-generale-v1.png` | r1 / 1 | `tour-pokemon-vue-generale-v1.png` (étage de tour sur fond sombre) |
| `tour-cendree-b1f-vue-generale-v1.png` | r1 / 1 | 1F + `tour-pokemon-vue-generale-v1.png` |
| `route-42-vue-generale-v1.png` | r1 / 1 | `route-36-vue-generale-v1.png` (Johto, eau, lumière neutre) |
| `acajou-vue-generale-v1.png` | r1 / 1 | `rosalia-vue-generale-v1.png` (Johto, tuiles) |
| `boutique-souvenirs-acajou-v1.png` | r1 / 1 | `boutique-jadielle-v1.webp` (intérieur de boutique) |
| `route-43-vue-generale-v1.png` | r1 / 1 | `route-35-vue-generale-v1.png` (poste, clôture) |
| `lac-colere-vue-generale-v1.png` | r1 / 1 | Route 42 (ci-dessus) + `route-13-vue-generale-v1.png` |
| `repaire-acajou-b1f-vue-generale-v1.png` | r1 / 1 | `souterrain-doublonville-vue-generale-v1.png` (béton, néons) |
| `repaire-acajou-b2f-vue-generale-v1.png` | r1 / 1 | B1F + Souterrain |
| `repaire-acajou-b3f-vue-generale-v1.png` | r1 / 1 | B2F + Souterrain |

Outil : styles par grille étendus (cendres, poutres, trous et échelles de la Tour Cendrée ; porte de grotte murée ;
boutique de souvenirs à antenne ; poste de péage ; rocher émergé ; statues, caisses, dalles fléchées, cases d'arrêt,
grilles de cellules, cage à ondes du repaire ; mur, sortie, caisse et escalier caché de la boutique).

Défauts pris **[D]** : Tour Cendrée en bois carbonisé, cendres grises, rais de lumière froide par les étages disparus,
sans flamme ni fumée ; la salle des trois chiens est peinte **vide** (les chiens sont des sprites) ; repaire en béton gris
éclairé au néon, **statues de Persian dorées aux yeux rouges** dans des niches, dalles fléchées bleu acier à lueur,
cellules à barreaux d'acier, porte à code à voyant rouge, **générateur d'ondes** à bobines de cuivre et cœur bleu-violet,
**cage à ondes vide** à barreaux clairs et champ bleu-violet ; boutique de souvenirs à figurines, boules à neige et mugs,
étagère de droite « de travers » sans trahir l'escalier ; Acajou avec sapins dans la forêt et antenne fine sur la boutique
à toit de tuiles ; Lac Colère rectangulaire aux rives droites, deux rochers émergés, sans ombre dans l'eau.

### Écarts avec les grilles (la grille fait foi)

- **Tour Cendrée 1F** : la bande de plancher effondré est peinte plus étroite que ses 2 rangées ; les poutres verticales
  (x 12, x 22) sont rendues en poteaux debout ; le reste (trous isolés, poutres au sol, dallage d'entrée, échelle) est conforme.
- **Tour Cendrée B1F** : les colonnes calcinées sont rendues en blocs de pierre bas ; l'alcôve du sud-ouest est là.
- **Route 42** : conforme (montagne, contrefort et porte murée, lac d'une paroi à l'autre, îlot, éperon à passage unique,
  trois poches d'herbes) ; le chemin ouest est un peu plus haut que ses rangées 9..11 à l'approche du lac.
- **Acajou** : conforme ; la boutique de souvenirs porte une enseigne de bois sans texte en plus ; les falaises du nord
  sont des murets de roche bas.
- **Boutique de souvenirs** : conforme ; les figurines reprennent des silhouettes de Pokémon connus (souvenirs, pas de collision).
- **Route 43** : conforme (chemin droit, trois poches, poste à porte ouest, clôture et passage d'une case) ; le poste
  est peint comme une petite maison plutôt qu'un poste de garde-route ; le passage de la clôture est peint à droite du
  chemin au lieu de sa colonne centrale (11, 24).
- **Lac Colère** : conforme (lac de forêt à forêt, rives nord et sud, chemin du sud, sentier du nord-est, quatre poches,
  deux rochers) ; le sentier du nord-est est court (3 cases visibles sur 6).
- **Repaire B1F** : conforme (hall, couloir, trois passages, statues dans leurs niches, caisses, escaliers).
- **Repaire B2F** : conforme (salle d'arrivée, dalles et sens des flèches, porte à code et escalier, couloir des cellules,
  trois cellules et levier) ; la cellule du milieu montre son sol, les deux autres sont pleines, conforme.
- **Repaire B3F** : conforme (sas, cloison à passage unique, machine, pupitre, cage ouverte au sud, caisses) ; la cage est
  reliée à la machine par des tuyaux (décor).
- **Tous** : lumière neutre respectée ; intérieurs au néon froid.

## JOH7 — Routes 40 et 41, Îles Tourbillon 1F, B1F, B2F (planche `joh7-vues-v1.png`) — **validé par Kevin le 2026-11-03**

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `route-40-vue-generale-v1.png` | r1 / 1 | `route-20-vue-generale-v1.png` (route marine de Kanto) |
| `route-41-vue-generale-v1.png` | r1 / 1 | Route 40 (ci-dessus) + `route-20-vue-generale-v1.png` |
| `iles-tourbillon-1f-vue-generale-v1.png` | r1 / 1 | `mont-selenite-vue-generale-v1.png` |
| `iles-tourbillon-b1f-vue-generale-v1.png` | r1 / 1 | `grotte-marine-2-vue-generale-v1.png` + `iles-ecume-b4f-vue-generale-v1.png` |
| `iles-tourbillon-b2f-vue-generale-v1.png` | r1 / 1 | B1F (ci-dessus) + `grotte-marine-2-vue-generale-v1.png` |

Outil : routes marines à marge de mer (`_fond: mer`), bancs de sable, tourbillons en spirale, entrée de grotte dans l'île,
cascade des grottes.

Défauts pris **[D]** : routes marines sans terre ferme hors bancs de sable et îlots, lumière neutre (sans reflets dorés de la
Route 20) ; tourbillons = spirales d'écume blanches en lignes droites, une case chacun ; île unique de roche sombre et
abrupte à sommet nu, grotte sur la face ouest ; B1F : courants en traînées d'écume, plate-forme de Suicune peinte **vide** ;
B2F : bassin bleu nuit, cascade coupée en son milieu, **halo bleu** au-dessus de l'eau, bassin vide (Lugia est un sprite).

### Écarts avec les grilles (la grille fait foi)

- **Route 40** : conforme (bordures rocheuses, entrée large au nord, chenal sud entre deux récifs, trois barres de rochers,
  rochers isolés, deux bancs de sable).
- **Route 41** : l'île est peinte un peu **plus petite** que ses 16 × 16 cases et son îlot sud-est plus près du récif ; les
  quatre lignes de tourbillons et leurs passes sont conformes ; le rocher plat au nord de la passe nord se devine à peine.
- **Îles Tourbillon 1F** : conforme (entrée ouest, trois salles, deux passages étroits, trois zones de gravats, rochers,
  échelle) ; quelques coquillages et algues à l'entrée (décor).
- **Îles Tourbillon B1F** : conforme (muraille et deux passes, lacs est et ouest, rive d'arrivée et échelle, plate-forme du
  nord, chenal de l'îlot, crique, palier du nord-ouest et courant violent, rochers) ; le courant du palier est peint en
  petite cascade.
- **Îles Tourbillon B2F** : conforme (corniche, parois, bassin, rangée d'entrée au sud, cascade coupée au milieu, rochers,
  échelle, halo).
- **Tous** : lumière neutre ; grottes en pénombre bleue.

## JOH8 — Bois de la Tour, Tour Carillon 1F, 2F, sommet (planche `joh8-vues-v1.png`) — **validé par Kevin le 2026-11-03**

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `bois-de-la-tour-vue-generale-v1.png` | r1 / 1 | `rosalia-vue-generale-v1.png` (érables, pavé, pagode) |
| `tour-carillon-1f-vue-generale-v1.png` | r1 / 1 | `tour-pokemon-vue-generale-v1.png` (étage de tour) |
| `tour-carillon-2f-vue-generale-v1.png` | r1 / 1 | 1F + `tour-pokemon-vue-generale-v1.png` |
| `tour-carillon-sommet-vue-generale-v1.png` | r1 / 1 | 2F + `rosalia-vue-generale-v1.png` (la ville en bas) |

Outil : lanternes de pierre, colonnes rouges, autel, planches qui cèdent, rambarde, grande cloche, cage de feu,
trappe, brûle-parfums.

Défauts pris **[D]** : Tour Carillon intérieure = temple de bois clair et colonnes rouges laquées, autel à nappe rouge et
offrandes, brûle-parfums fumants ; planches qui cèdent = bois vermoulu plus sombre et fendu, intact ; sommet = terrasse
dallée à rambarde rouge, cloche de bronze sous un portique rouge, **cage de flammes vide**, **ciel d'aube** rose et bleu
(JH-55), Rosalia et ses érables rouges visibles en bas ; Bois de la Tour = érables verts touchés de rouge, lanternes de
pierre allumées (seule touche chaude).

### Écarts avec les grilles (la grille fait foi)

- **Bois de la Tour** : conforme (allée, quatre lanternes, façade de la pagode et sa porte, douze érables, touffe d'herbe,
  panneau) ; la pagode montre trois étages au lieu d'une simple façade (le haut sort de l'image, conforme à l'intention).
- **Tour Carillon 1F** : conforme (autel, six colonnes en deux rangs, brûle-parfums des angles, niche étroite de l'escalier
  en haut à droite avec ses deux cloisons, sortie au sud) ; l'autel porte fleurs et bols (offrandes, décor).
- **Tour Carillon 2F** : conforme (deux escaliers et la niche, trois nappes de planches et leurs passages, quatre planches
  isolées, six colonnes).
- **Sommet** : conforme (rambarde, palier et trappe, cloche sous son portique, cage ouverte au sud, trois brûle-parfums) ;
  la cage est peinte à droite du centre (grille : x 11..13, conforme) ; l'ouverture du palier (3, 3) se lit mal.
- **Tous** : lumière neutre sauf le sommet, à l'aube (voulu, JH-55).

## JOH9 — Sentier, Mont Argenté (extérieur, 1F, 2F, 3F, sommet), Route 28, poste (planche `joh9-vues-v1.png`) — **validé par Kevin le 2026-11-03**

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `sentier-mont-argente-vue-generale-v1.png` | r1 / 1 | `route-43-vue-generale-v1.png` |
| `mont-argente-exterieur-vue-generale-v1.png` | r1 / 1 | Sentier (ci-dessus) + `route-42-vue-generale-v1.png` (roche) |
| `mont-argente-1f-vue-generale-v1.png` | r1 / 1 | `mont-selenite-vue-generale-v1.png` + `iles-tourbillon-b1f-vue-generale-v1.png` |
| `mont-argente-2f-vue-generale-v1.png` | r1 / 1 | 1F (ci-dessus) |
| `mont-argente-3f-vue-generale-v1.png` | r1 / 1 | 2F (ci-dessus) |
| `mont-argente-sommet-vue-generale-v1.png` | r1 / 1 | extérieur (ci-dessus) |
| `route-28-vue-generale-v1.png` | r1 / 1 | `route-43-vue-generale-v1.png` |
| `poste-route-28-v1.png` | r1 / 1 | `poste-15-v1.png` |

Outil : neige (grain), muraille de glace, herbes givrées sous la neige, mer de nuages, pierres des ruines, trappe dans la
neige, fond de roche ou de nuages, sortie ouest `e` des grottes, ouverture nord `N` du poste.

Défauts pris **[D]** : limite nette herbe / neige à la muraille de glace du Sentier ; Centre du Mont Argenté = Centre
standard au toit enneigé ; grotte 2F peinte en pénombre profonde lisible (le voile d'obscurité est un effet du jeu) ;
3F avec vent et neige soufflée ; sommet = plateau de neige vierge ceint de roche, pierres des ruines éparses, ciel pâle ;
Route 28 sans neige (versant ouest) ; poste de la Route 28 = une pièce traversante, neige visible par les portes.

### Écarts avec les grilles (la grille fait foi)

- **Sentier** : conforme (chemin en L, muraille de glace et son passage, limite herbe / neige, Centre, trois poches dont
  deux givrées, sapins, rochers, panneau).
- **Mont Argenté extérieur** : un **escalier de neige** est peint entre l'esplanade et l'entrée de la grotte (la grille
  n'a ni marche ni dénivelé : l'entrée est au ras de l'esplanade) ; les masses de roche de l'entonnoir sont plus arrondies ;
  le reste est conforme (chemin, trois poches givrées, sapins, rochers, paroi).
- **1F** : conforme (entrée sud, sortie ouest, lac en travers, deux barrières et leurs brèches, échelle, gravats) ; la
  rangée de gravats du nord-ouest est bien là.
- **2F** : conforme (échelles, descentes, galerie transversale, alcôve nord, salle latérale sud et son passage).
- **3F** : conforme (échelle du bas, corniche basse, montée de droite, corniche haute, raidillon, échelle du sommet, salle
  du vent et son passage, gravats) ; vent et neige soufflée très lisibles.
- **Sommet** : la **mer de nuages** est peinte autour de la falaise mais le bord sud du plateau est fermé par la
  falaise au lieu de s'ouvrir sur les nuages (grille : rangée 17 = nuages, pas de roche) ; les ruines sont rendues en
  blocs de roche enneigés plutôt qu'en pierres taillées ; palier, trappe et pierres sont à leur place.
- **Route 28** : conforme (versant rocheux, sentier d'une case, poste à l'ouest, maison au centre, deux poches, sapins) ;
  le poste est peint comme une petite maison à toit d'ardoise.
- **Poste de la Route 28** : conforme (pièce de 8 × 5, deux portes alignées, quatre plantes).
- **Tous** : lumière neutre.

## Bilan

**Acte 1** : 21 vues générales en 21 essais (JOH1 : 3, JOH2 : 3, JOH3 : 5, JOH4 : 5, JOH5 : 5), aucun refus de Codex.
**Toutes validées par Kevin le 2026-11-03** (JOH1 : « Oui, enchaîne JOH2 » ; JOH2 à JOH5 : « Oui, fusionne »). Les défauts
[D] de chaque section deviennent la règle pour les actes 2 et 3.

**Actes 2 et 3** : 27 vues en 27 essais (JOH6 : 10, JOH7 : 5, JOH8 : 4, JOH9 : 8), aucun refus. **Validées par Kevin le
2026-11-03** (« Oui, fusionne »). Total du chapitre : **48 vues générales**, 48 essais, toutes validées.

## Arc des Pierres — JOHP1 à JOHP3 (planches `johp1-vues-v1.png` à `johp3-vues-v1.png`) — **[D], à relire par Kevin**

Générées la nuit du 2026-11-05 (coordination déléguée), un essai chacune, sans refus de Codex. Prompts
`tools/art/prompts/CONCEPT_<ZONE>_VUE_GENERALE_r1.txt` ; plans annotés dans `reference/plans-johto/`.

| Vue | Référence jointe | À regarder |
|---|---|---|
| `ruins-of-alph-vue-generale-v1.png` | Écorcia | Le toit du temple se lit comme une cour dallée ; il est **bloqué** dans la grille. Feuillage un peu plus granuleux que les autres vues |
| `alph-tent-vue-generale-v1.png` | Maison de Léo | Conforme |
| `alph-gallery-vue-generale-v1.png` | Puits Ramoloss B1F | Signes des dalles abstraits, conformes ; à accorder avec les bonnes dalles au code |
| `alph-chamber-vue-generale-v1.png` | Puits Ramoloss B1F | Conforme |
| `goeland-deck-vue-generale-v1.png` | Oliville | Le bateau ressemble à une barge : proue carrée, moins « bateau de pêche » que demandé |
| `cianwood-city-vue-generale-v1.png` | Oliville | Le quai est plus court que la grille ; poches d'herbes plus grandes que la grille |
| `tide-cave-1f-vue-generale-v1.png` | Îles Tourbillon 1F | Pompes réussies, sans lettre |
| `tide-cave-b1f-vue-generale-v1.png` | Îles Tourbillon 1F | Gués bien visibles sous l'eau |
| `blackthorn-city-vue-generale-v1.png` | Acajou | Bannières rouges unies, bouche de l'Antre à piliers : réussi |
| `dragons-den-1f-vue-generale-v1.png` | Mont Argenté 1F | Petite chute d'eau ajoutée dans la salle de l'Eau, non prévue par la grille (décor seulement) |
| `dragons-den-sanctuary-vue-generale-v1.png` | Îles Tourbillon B2F | Conforme : autel à trois cuvettes, cadrage prêt pour le Réveil |

La grille fait foi pour la géométrie.
