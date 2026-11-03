# Série Johto — vues générales de l'acte 1 (JOH1 à JOH5)

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

## JOH2 — Routes 39 et 38, Rosalia (planche `joh2-vues-v1.png`) — en attente de Kevin

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

## JOH3 — Routes 37, 36, 35, Doublonville, Souterrain (planche `joh3-vues-v1.png`) — en attente de Kevin

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `route-37-vue-generale-v1.png` | r1 / 1 | `route-38-vue-generale-v1.png` (Johto, lumière neutre) |
| `route-36-vue-generale-v1.png` | r1 / 1 | `route-13-vue-generale-v1.png` (prairie, eau, lumière neutre) |
| `route-35-vue-generale-v1.png` | r1 / 1 | `route-39-vue-generale-v1.png` (Johto, eau, clôture blanche) |
| `doublonville-vue-generale-v1.png` | r1 / 1 | `celadopole-vue-generale-v1.png` (grande ville, grand magasin) |
| `souterrain-doublonville-vue-generale-v1.png` | r1 / 1 | `souterrain-vue-generale-v1.png` (Souterrain de Kanto) |

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

## JOH4 et JOH5

À faire ensuite (Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss ; Tour Radio 1F à 5F).
