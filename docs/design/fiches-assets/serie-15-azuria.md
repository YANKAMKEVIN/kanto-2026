# Série 15 — Route 4, Azuria et Route 24 (jalon 13, lumière NE)

> Rédigée au **J13 T1** (2026-10-11, branche `j13-t1` depuis `jalon-13`). Plan : `docs/tech/jalon-13.md` §0.2, §1.4, §2.3 ; conception : `docs/design/dossier-16-azuria.md` (grilles et vues générales **validées** le 2026-10-11). Fichier **nouveau**. Génération au **T2** (Mac, Codex), validation de Kevin sur planche de contact (**13.0-art**), intégration au **T5** (manifeste, `preparer.py`, `preparer_menu.py`, règles, scènes, looks).

**Consigne de Kevin (J8–J12)** : le plus petit kit modulaire qui produit la **sensation** des vues validées dans Godot, sans répétition visible.
- **DA et composition** : `reference/azuria-vue-generale-v1.png`, `route-4-vue-generale-v1.png`, `route-24-vue-generale-v1.png`. **Géométrie, qui fait foi** : `tools/plans/azuria.txt`, `route_4.txt`, `route_24.txt`, `azuria_arene.txt`, `azuria_velos.txt`, `azuria_maison.txt` (non modifiées).
- **Outil** : `tools/art/serie15.py` (`--prompts`, `--refs`, `--ancres`, `--commandes`, `--planche`, `--contact`, `--manifeste` préparé et **non lancé**, `--controle` au T5 ; génération en **deux vagues**, une image de la vague 2 joint une image de la vague 1). **Un prompt versionné par image** : `tools/art/prompts/serie15/<NOM>.txt` et, pour les attentes, `tools/art/attente/prompts/<NOM>_ATTENTE.txt`.
- **Prompts** : ADN visuel v1 (cahier §1.3) + **LUMIÈRE NE** ; l'eau a ses **valeurs d'eau** (turquoise clair, reflets dans la valeur peinte, aucune ombre portée peinte). Aucun nom de licence ni de marque ajouté ; **aucun emblème de type balle** (interdit répété dans `INTERDITS`, et dans les façades de l'Arène et du magasin de vélos : vagues sculptées, roue de vélo à rayons seulement). Interdits : texte, lettres, logo, faune non-Pokémon, Pikachu, sosie du héros.
- **Références** : recadrages `REF_AZ_*`, `REF_R4_*`, `REF_R24_*` des trois vues (boîtes versionnées dans `REFS`, × 3). Ancres validées copiées par `--ancres` depuis le checkout principal (souche, arbre A, héros `PERSO_P2_PEINT_r1`, muret, balustrade, escalier de ville, façades d'Argenta et de Jadielle, coques d'intérieur, vélo, râtelier, banc, lampadaire, rebord, falaise, `MENU_OBJETS_PLANCHE`, Pierre, paroi d'ardoise de la série 14).
- **Planche de contrôle** (sans Codex) : `python3 tools/art/serie15.py --planche` → `build/art/AZ_KIT_v1.png` (1 case = 48 px, héros à l'échelle) : réutilisés, variations, nouveaux (référence recadrée à la taille en jeu), icône, conditionnels, abandonnés. Relue au T1.

## Liste du kit

**A. Réutilisés tels quels** : herbe, chemin, pavés (`ground_paves_01`), hautes herbes jaunes, décalcomanies de fleurs ; forêt `DenseForest` et `tree_foret_*` ; haies, buissons, rochers, panneaux ; **Centre** `bldg_centre_01` (8 × 7, 1er de l'avenue) et **Boutique** `bldg_boutique_01` (seuls bâtiments à emblème rond, autorisé) ; **maisons** `bldg_maison_argenta_01`, `bldg_maison_a..d_01` (M cambriolée toit brun, m ouverte toit rouge) ; `prop_banc_01` (bancs `n`), `prop_pots_fleurs_01` (façades), `prop_massif_01`, `prop_cloture_01`, `prop_tronc_couche_01` (arbre qui barre la sortie est), `prop_balustrade_01`, `relief_muret_01`, `relief_escalier_ville_01` (perron), `relief_falaise_01` (sas, ouest du versant), `object/poke_ball_ground` (O1, O2), paroi ardoise et entrée de grotte de la série 14 (plateau du sas, vue Route 4) ; **intérieurs** : enveloppe `int_maison_argenta_coque` (15 × 10, **sans emblème**) pour les vélos **et** la maison ouverte (la grille dit « même coque que les maisons d'Argenta », le plan §1.4 disait « Boutique » : **la grille gagne**, la coque de Boutique porte un emblème au sol), `int_aquarium_01`, `int_canape_01`, `int_cuisine_01`, `int_cuisiniere_hotte_01`, `int_frigo_01`, `int_table_repas_01`, `int_chevet_lampe_01`, `int_plante`, `int_long_comptoir_01` (comptoir des vélos) ; Pokémon en combat : artworks officiels.

**Personnages réutilisés** (règle §0.2 n° 8 : aucun modèle nommé — `haru`, `aoki`, `maya`, `leo`, `oak`, `mom`, `brock` exclus) :

| Rôle (grille) | Modèle | Pourquoi |
|---|---|---|
| H1 pêcheur assis (quai ouest) | `old_man` | adulte âgé générique, déjà dans deux villes, sans identité ; la vue donne un chapeau de paille (abandonné) |
| H2 enfant | `kid` | enfant générique |
| H3 voisine | `lass` | seule adulte jeune femme générique ; **conditionnel** `PNJ_HABITANTE` si Kevin trouve `lass` trop répété (Clara, Alice, Romane, Diane, H3, H5) |
| H4 policier | `guard` | gardes de la Forêt de Jade (uniforme sans nom) |
| H5 nageuse | `lass` | défaut du plan §0.2 n° 7 ; conditionnel `PNJ_NAGEUSE` |
| H6 jeune Dresseur | `youngster` | Malo aussi (rôles distincts, cartes distinctes) |
| habitante de la maison ouverte | `old_man` | maison fermée, interlocuteur unique ; conditionnel `PNJ_HABITANTE` |
| Boutique, vélos | `clerk` | modèle des vendeurs |
| Clara, Alice, Romane, Diane | `lass` | Dresseuses (une classe) |
| Malo | `youngster` ; Timéo `scout` ; Ethan `camper` ; guide d'Arène `gym_guide` ; infirmière `nurse` ; rival n° 3 `rival` ; recruteur Sbire ♂ (série 14, J12 T6) | |

**B. Variations sans nouvel asset** : pavés plus clairs (`Shade`) pour quais et place ; fleurs plus fréquentes en ville ; forêt de la Route 4 moins sèche que celle de la Route 3 ; bancs légèrement éclaircis ; haies et buissons en miroir.

**C. Nouveaux : 19 images** (fiches ci-dessous).

| Fiche → asset(s) | Rôle | Taille en jeu | Images | Vague |
|---|---|---|---|---|
| `WORLD_GROUND_EAU_CANAL_01` → `ground_eau_canal_01` | eau des canaux et de la rivière | texture 384 | 1 | 1 |
| `WORLD_RELIEF_QUAI_PLANCHE` → `relief_quai_01..06` | bords de quai (rôles de `QUAY_PIECES`) | voir fiche | 1 | 1 |
| `WORLD_PROP_PONTS_PLANCHE` → 8 modules de pont | 3 ponts de ville, Pont Pépite | voir fiche | 1 | 2 |
| `WORLD_RELIEF_BERGE_PLANCHE` → `relief_berge_01..05`, `prop_roseaux_01` | berges naturelles de la Route 24 | voir fiche | 1 | 2 |
| `WORLD_BLDG_ARENE_AZURIA_01` | façade de l'Arène (verrière) | 12 × 7 | 1 | 1 |
| `WORLD_BLDG_VELOS_01` | façade du magasin de vélos | 8 × 7 | 1 | 1 |
| `WORLD_PROP_VILLE_EAU_PLANCHE` → 6 éléments | jardinières, arbre en bac, banc, lampadaire de quai, bitte | 1 à 2 cases | 1 | 1 |
| `WORLD_PROP_CAMBRIOLAGE_PLANCHE` → 5 indices | cambriolage (C-8) | 1 à 3 cases | 1 | 1 |
| `WORLD_PROP_FERMETURES_PLANCHE` → 3 éléments | palissade sud, barrière | 2 à 3 cases | 1 | 2 |
| `WORLD_RELIEF_GROTTE_AZUREE_01` | îlot et bouche, vue de loin | 4 × 3,5 | 1 | 1 |
| `WORLD_RELIEF_REBORD_ARDOISE_PLANCHE` → 3 modules | rebord (net, sans planche) et falaise du versant, **roche ardoise** | 1,5 / 3,4 cases | 1 | 1 |
| `INT_ARENE_AZURIA_COQUE` | salle de l'Arène, bassin peint statique | 17 × 13 | 1 | 2 |
| `INT_ARENE_AZURIA_PLANCHE` → 3 meubles | plongeoir, banc de piscine, porte-bouées | 1 à 2 cases | 1 | 2 |
| `INT_VELOS_PLANCHE` → 4 meubles | 3 vélos exposés, étagère de casques | 2 à 4 cases | 1 | 2 |
| `PNJ_ONDINE` + attente → `misty` | Ondine (pont, Arène) | 128 px | 2 | 1, 2 |
| `PNJ_NAGEUR` + attente → `swimmer` | Nageur Lucas | 128 px | 2 | 1, 2 |
| `UI_OBJETS_J13_PLANCHE` → `assets/ui/items/nugget.webp` | icône de la Pépite | 256 px | 1 | 1 |

**Écarts au plan §1.4 C** (défauts, règle 4) : `INT_MAISON_AZURIA_PLANCHE_NE` **abandonnée** (le canapé, l'aquarium, la cuisine, le frigo, la table et la lampe existent déjà : tout est réutilisé) ; `INT_ARENE_AZURIA_COQUE` + `_PLANCHE` : le bassin et les gradins sont **dans la coque**, le plongeoir, le banc et le porte-bouées en meubles ; `WORLD_RELIEF_REBORD_ARDOISE_PLANCHE` **ajoutée** (correction validée de la Route 4 : rebord et versant en ardoise) ; le sas garde `relief_falaise_01` à l'ouest (continuité) et la falaise ardoise ne couvre que la partie neuve du versant, ou tout le versant si Kevin préfère (T5, capture) ; pas de **portrait d'Ondine** (Q-2).

**D. Abandonnés** : Pokémon d'ambiance (aucun dans les vues) ; personnages des vues (remplacés par les modèles ci-dessus) ; chapeau de paille du pêcheur ; **margelle de pierre continue sur les berges de la Route 24** (la vue peint un rebord de pierre ; le plan et la consigne demandent des **berges naturelles**, la pierre ne reste qu'au pied du pont, lieu des quais ; écart à juger, §Route 24) ; **terre brune** du rebord et de la falaise de la Route 4 (→ ardoise, correction validée) ; **planche de bois** au passage du rebord (→ net) ; **ombre rectangulaire** de l'eau de la Route 24 (défaut de peinture) ; images de la V2 (hors dépôt).

**Conditionnels** (prompts prêts, jamais lancés par défaut, décision notée dans `etat-projet.md`) : `WORLD_GROUND_DALLES_CLAIRES_01` (si les pavés éclaircis ne donnent pas la pierre blanc-crème de la vue, capture du T7), `PNJ_NAGEUSE` (H5 en maillot), `PNJ_HABITANTE` (voisine H3 / habitante de la maison). **Pas de `PORTRAIT_ONDINE`** (Q-2 : décidé par Kevin, aucun portrait).

**Contrôle « chaque élément des vues a un asset »** (CA du T1) — *Azuria* : forêt, haies, fleurs, chemin de terre, pavés → A/B ; canal et baie → `ground_eau_canal_01` ; quais, escalier de quai → `relief_quai_*` ; trois ponts, piles, parapets → `prop_pont_ville_*` + balustrade ; Arène → façade neuve ; Centre, Boutique, maisons → A ; magasin de vélos → façade neuve (vélos de façade peints dedans) ; jardinières, arbre en bac, bancs, lampadaires, bitte → planche de ville d'eau ; clôture arrachée, pot, planches, ruban, trou → planche du cambriolage ; palissade sud, arbre + clôture est → fermetures + tronc couché + clôture ; Grotte Azurée → îlot ; pêcheur, enfant, voisine, policier, nageuse, dresseur → modèles réutilisés. *Route 4* : versant, rebord → `relief_*_ardoise` ; cristaux bleus → module 2 de l'ardoise (série 14) ; bouche de grotte → série 14 ; forêt, herbes, rochers, buissons, panneau, Poké Ball, Clara → A. *Route 24* : rivière → eau ; berges → `relief_berge_*` ; pont (tablier, rambardes, piles) → `prop_pont_pepite_*` ; pied de pont pavé, quais, panneau, banc → A + quais ; forêt, herbes, Poké Ball, Dresseurs → A ; Ondine, recruteur → nouveau / série 14. Rien n'est implémenté parce qu'il est sur une image (règle 10) : la grille décide de la place.

## Alignement sur `tools/cerulean_map_kit.gd` (T6 du J13)

`QUAY_PIECES` (rôle → image) : `n` = `relief_quai_01` / `02` (variantes tirées à la graine), `s` = `03`, `w` = `04`, `e` = `04` en miroir, `nw` `ne` `sw` `se` = `05` (miroirs), `06` jamais posé d'office. **La fiche suit ces rôles sans écart** ; la taille d'une image (longueur d'un module = `round(longueur / 96)` cases, profondeur = celle de l'image) est lue par l'outil, donc seules les proportions comptent. Écarts **mineurs** avec les provisoires de l'outil, à **corriger au T5** si l'on veut que les captures d'essai ne changent pas : profondeur du module `n` **43 px** (provisoire 30), `s` 16 (14), `w` / `e` 20 (18), angle 40 × 40 (30 × 30). Sens des images : `01` / `02` dessinés pour une case d'eau dont le **sol est au nord** (lèvre claire en haut, face, ligne d'eau en bas), `03` pour le sol au **sud** (seule la margelle), `04` pour le sol à l'**ouest** (sol à gauche, eau à droite), `05` pour le sol au **nord-ouest** (coin en haut à gauche, ligne d'eau à droite et en bas). Tabliers : `place_bridges({ns, ew})` ne prend **qu'un identifiant par sens** : ville `ns` = `prop_pont_ville_01` (largeur 2, étiré × 1,5 pour le pont central de 3 de large, ou `prop_pont_ville_03_01` à la bonne largeur : 2 identifiants distincts à passer par pont, **extension d'outil à prévoir au T7**), `ew` = `prop_pont_ville_ew_01` ; Pont Pépite `ns` = `prop_pont_pepite_tablier_01` ; les variantes `_02` et `_03` demandent une extension d'outil (liste de variantes alternées), **à signaler au T8** pour éviter 25 rangées identiques.

## Fiches

Pour chaque asset : rôle, emprise (cases de la grille), taille en pixels du jeu (1 case = 96 px), ancrage et règle `PaintedPropRules` prévue (T5), réutilisé, images jointes. Hauteurs et réglages = **valeurs par défaut** (règle 4). Le prompt complet est dans `tools/art/prompts/serie15/<NOM>.txt`.

### Eau

#### WORLD_GROUND_EAU_CANAL_01 → `ground_eau_canal_01` (vague 1)
- **Rôle** : eau du canal en L d'Azuria (4 de large, ~230 cases) et de la rivière de la Route 24 (56 × 25) ; `PaintedGround.water_texture` (T6), écume 0, `square_shore`. Turquoise clair, ondulations régulières, **reflets peints dans la valeur**, aucun bord ni nénuphar. Texture 1 024² raccordable → 384 px (contraste 1,0, `raccord` 24). **Jointes** : `REF_AZ_EAU`, souche, arbre A, `WORLD_GROUND_EAU_01` (à ne pas copier). **Risque** : trop proche de l'eau de mer (à juger au T5) ; **ne pas** montrer l'ombre rectangulaire de la vue.

### Quais, ponts, berges

#### WORLD_RELIEF_QUAI_PLANCHE → `relief_quai_01..06` (vague 1)
- Planche 1536 × 1024, 3 × 2 cellules de 512, 1 case = 240 px, `planches_objets` (découpe par taches) largeurs `[2, 2, 2, 0.21, 0.42, 2]`, contact 0, `ombre` non. Tailles obtenues visées : `01`, `02` 192 × 43 ; `03` 192 × 16 ; `04` 20 × 192 ; `05` 40 × 40 ; `06` 192 × 96. Posés **dans les cases d'eau** de la frontière (jamais sur une case praticable : l'outil échoue sinon), dans `GroundDecals`. `06` : escalier de quai posé à la main (quai ouest du pêcheur, x 23..25 / y 12..16, au T7). **Jointes** : `REF_AZ_QUAI`, `REF_AZ_QUAI_OUEST`, `REF_AZ_PONTS`, muret, balustrade, escalier de ville.

#### WORLD_PROP_PONTS_PLANCHE → 8 modules (vague 2, joint la planche des quais)
- Planche 4 × 2 cellules de 384 × 512, 1 case = 120 px, `planches_objets` largeurs `[2, 3, 1, 2, 2, 2, 1, 0.5]`, contact 0. **`prop_pont_ville_01`** (tablier 2 × 1, pont de l'Arène x 40..41, y 15..18), **`prop_pont_ville_03_01`** (3 × 1, pont central x 31..33), **`prop_pont_ville_ew_01`** (1 × 2, pont ouest y 8..9, 4 longs) : pierre claire + parapets bas sur les deux côtés (dans la largeur du pont, jamais au-delà). **`prop_pont_pepite_tablier_01..03`** (2 × 1, x 32..33, y 20..44 : 25 rangées) : bois clair, longerons. **`prop_pont_pepite_garde_corps_01`** (1 case de long) et **`prop_pont_pepite_pile_01`** (0,5 × 1,2) : posés **dans les cases d'eau** le long du pont (x 31 et x 34), à la main au T8 (le tablier couvre les deux colonnes praticables). **Jointes** : `REF_AZ_PONTS`, `REF_AZ_PONT_OUEST`, `REF_R24_PONT`, `REF_R24_PONT_TETE`, quais (vague 1), balustrade, ponton. **Écart vue** : la vue de la Route 24 montre des piles de pierre sur le pont ; ici elles flanquent le tablier (la grille interdit de les poser sur une case praticable).

#### WORLD_RELIEF_BERGE_PLANCHE → `relief_berge_01..05`, `prop_roseaux_01` (vague 2, joint les quais)
- **Rôle** : berges **naturelles** de la rivière de la Route 24 (rangées 19/20 au nord, 44/45 au sud ; canal x 26..29 vers Azuria) : terre, herbe, galets, roseaux. Mêmes rôles que les quais (`01`, `02` sol au nord ; `03` sol au sud ; `04` côtés ; `05` angle ; `06` touffe de roseaux isolée dans l'eau, 1 × 1). Largeurs `[2, 2, 2, 0.21, 0.42, 1]`, contact 0. **Pose** : `place_quays` avec un autre jeu de pièces (constante à paramétrer au T8) ; **pied du pont** (x 30..41, y 45..53, place pavée) : **quais de pierre** (`relief_quai_*`). **Écart vue** : margelle de pierre continue dans la vue, **berges naturelles** ici (consigne), ceci est à **juger par Kevin** sur capture du T8. **Jointes** : `REF_R24_BERGE_N`, `REF_R24_BERGE_S`, `REF_R24_RIVIERE`, quais, rocher de mer.

### Bâtiments et repères

#### WORLD_BLDG_ARENE_AZURIA_01 → `bldg_arene_azuria_01` (vague 1)
- Emprise 12 × 7, porte (40..41, 9) = 2 cases libres au bas, `axe w`, `cases 12`, ombre oui, contact 0,12 (comme `bldg_arene_argenta_01`). Pierre blanc-crème, verrière en berceau de verre bleuté, porche en arc, **vagues sculptées, aucun emblème rond**. **Jointes** : `REF_AZ_ARENE`, façades d'Argenta (Arène, Musée), souche, arbre A.

#### WORLD_BLDG_VELOS_01 → `bldg_velos_01` (vague 1)
- Emprise 8 × 7, porte (38..39, 35) = 2 cases libres, `axe w`, `cases 8`, ombre oui, contact 0,12. Toit orange, vitrines à vélos, stores rayés, roue de vélo à rayons (jamais un cercle plein), **aucun emblème rond**. **Jointes** : `REF_AZ_VELOS`, Boutique, maison d'Argenta, vélo.

#### WORLD_RELIEF_GROTTE_AZUREE_01 → `relief_grotte_azuree_01` (vague 1)
- Repère `A` / `K` (51..54, 3..6), à plat sur l'eau (couche du sol, bloqué par la carte), 4 × ≈ 3,5, `axe w`, `cases 4`. Écume : **seule exception** de la série. Ni escalier ni ponton ni panneau (D-12). **Jointes** : `REF_AZ_GROTTE`, rocher de mer, ardoise.

### Mobilier et indices

#### WORLD_PROP_VILLE_EAU_PLANCHE → 6 éléments (vague 1)
- Planche 3 × 2, 1 case = 150 px, largeurs `[1, 1, 1, 2, 0.45, 0.5]`, contact 0,15 : `prop_jardiniere_pierre_01` / `02` (1 × 1 bloquée, place, quais, perron : fleurs bleues et blanches / roses et jaunes), `prop_arbre_bac_01` (coins de la place, 1 × 1), `prop_banc_pierre_01` (2 × 1 : variante des bancs `n`), `prop_lampadaire_quai_01` (quais, 2,6 cases), `prop_bitte_01` (quais). **Jointes** : `REF_AZ_JARDINIERE`, `REF_AZ_ARBRE_BAC`, `REF_AZ_PLACE`, pots de fleurs, banc, lampadaire, muret.

#### WORLD_PROP_CAMBRIOLAGE_PLANCHE → 5 indices (vague 1)
- Planche 3 × 2 (6e cellule vide), largeurs `[3, 1, 1, 1, 2]`, contact 0,1 : `prop_cloture_arrachee_01` (examen (6, 1), clôture du fond), `prop_porte_condamnee_01` (porte condamnée **à poser sur la façade** de la maison cambriolée (10, 9) : planches en croix + ruban jaune et noir **sans lettre**), `prop_pot_renverse_01` ((9, 2)), `prop_cloture_trou_01` (trou (14, 3), impraticable), `prop_ruban_01` (ruban entre piquets, devant la maison, au besoin). **Pas de « R », pas de nom** (D-14), aucun marqueur. **Jointes** : `REF_AZ_JARDIN`, `REF_AZ_PORTE_RUBAN`, clôture, pots de fleurs.

#### WORLD_PROP_FERMETURES_PLANCHE → 3 éléments (vague 2)
- Planche 3 × 1, largeurs `[3, 3, 2]`, contact 0,1 : `prop_palissade_chantier_01` / `02` (sud, x 30..34, y 38 : 5 cases = 3 + 3 chevauchées ou 3 + 2 barrière), `prop_barriere_croisillon_01`. Sortie est : `prop_tronc_couche_01` + `prop_cloture_01` réutilisés. Sans texte, sans promesse (D-12). **Jointes** : `REF_AZ_PALISSADE`, `REF_AZ_CLOTURE_EST`, clôture, tronc couché.

### Route 4 (correction validée)

#### WORLD_RELIEF_REBORD_ARDOISE_PLANCHE → `relief_rebord_ardoise_01`, `relief_falaise_ardoise_01..02` (vague 1)
- Planche 3 × 1 cellules de 512 × 1024, 1 case = 150 px, largeurs `[1.5, 3.4, 3.4]`, contact 0. **`relief_rebord_ardoise_01`** : rebord (28..33, 12) saut vers le sud, **net, roche ardoise, sans planche, sans terre brune** (comme le rebord de la Route 1 dans sa lisibilité, mais en roche : « on descend, on ne remonte pas »). **`relief_falaise_ardoise_01` / `02`** : versant `~` (x 3..27, y 12..13, bloqué). **Jointes** : `REF_R4_REBORD`, `REF_R4_FALAISE`, `REF_R4_PAROI`, `relief_rebord_01`, `relief_falaise_01`, ardoise (série 14).

### Intérieurs

#### INT_ARENE_AZURIA_COQUE → `int_arene_azuria_coque` (vague 2, joint la façade)
- 17 × 13 cases, 1536 × 1024 étiré à 1 632 × 1 248 (`pieces`, `cases [17, 13]`). Mur du fond sur 2 rangées (verrière), gradins légers sur les murs latéraux (2 colonnes), mur du bas sur 2 rangées, sortie de 3 cases (7..9, 11), **bassin 7 × 5 en (5..11, 4..8)**, **eau peinte statique**, chemins secs autour. Vide (plongeoir et banc à part). Paillasson bleu pâle **sans emblème**. **Jointes** : `INT_ARENE_COQUE` (Argenta), façade neuve.

#### INT_ARENE_AZURIA_PLANCHE → `int_plongeoir_01`, `int_banc_piscine_01`, `int_porte_bouees_01` (vague 2)
- Planche 3 × 1 de 512 × 1024, 1 case = 180 px, largeurs `[2, 2, 1]`, contact 0,2. Plongeoir (12..13, 2) bloqué contre le mur du fond ; banc et porte-bouées en habillage de salle (cases bloquées par la carte). Bouées **unies** (aucune bande de balle).

#### INT_VELOS_PLANCHE → `int_velo_expose_01..03`, `int_etagere_casques_01` (vague 2)
- Planche 2 × 2 de 768 × 512, 1 case = 150 px, largeurs `[2, 2, 2, 4]`, contact 0,2 : vélos exposés `b` (2 × 1 : (1..2, 3), (4..5, 3), (7..8, 3), (1..2, 6)), étagère de casques `E` (9..12, 3). Comptoir `C` : `int_long_comptoir_01` réutilisé. **Jointes** : `REF_AZ_VELOS`, vélo, râtelier, façade neuve.

### Personnages (marche puis attente)

Modèle commun : planche de marche 4 × 4 (1024 × 1536), héros validé joint, « ne ressemble pas au héros » ; planche d'attente 4 × 1 (1536 × 1024) calée sur la marche jointe. **128 px** de haut. Préparation (T5) : sections `personnages` / `attentes` ; looks en fin de `build_character_frames.gd` (`ondine` → `misty`, `nageur` → `swimmer`).

| Fiche | Tenue (défaut, règle 4) | Attente | Jointes |
|---|---|---|---|
| `PNJ_ONDINE` → `ondine` (`misty`) | jeune fille ≈ 16 ans, **cheveux orange** en courte queue de cheval sur le côté droit, débardeur jaune clair court, short en jean à **bretelles rouges**, baskets rouges, bracelet blanc ; ni cheveux roses ni bleus | pieds joints, main droite sur la hanche, menton relevé | `REF_R24_ONDINE` |
| `PNJ_NAGEUR` → `nageur` (`swimmer`) | jeune homme ≈ 22 ans, cheveux bruns humides, **lunettes de natation** relevées, **serviette blanche** au cou, maillot sans manches bleu marine, short de bain bleu clair rayé, claquettes bleues | pieds joints, mains sur la serviette | `REF_AZ_NAGEUSE` (tenue seulement) |

### Icône du Sac

#### UI_OBJETS_J13_PLANCHE → `assets/ui/items/nugget.webp` (vague 1)
- Planche 1536 × 1024 à **4 colonnes de 384**, la **Pépite** dans la première (les trois autres vides) : même découpe que `MENU_OBJETS_PLANCHE` (`preparer_menu.py`, `_bandes`, 256 px, WebP) ; T5 : ajouter la planche **en fin** (`ICONES_IDS = ["nugget"]`). Pépite d'or brut bosselée, sans pièce ni lingot. **Jointe** : `MENU_OBJETS_PLANCHE_r1`.

### Conditionnels (prompts prêts, non lancés)

- `WORLD_GROUND_DALLES_CLAIRES_01` : texture de dalles blanc-crème (quais, place) si les pavés éclaircis ne suffisent pas.
- `PNJ_NAGEUSE` (+ attente) : H5 en maillot. `PNJ_HABITANTE` (+ attente) : voisine H3 et habitante de la maison.

## T2 — commandes de génération

**Sur le Mac, depuis la racine de la copie** (trois générations à la fois, vague 1 puis 2 ; une image déjà présente n'est pas refaite ; les conditionnels ne partent pas) :

```bash
python3 tools/art/serie15.py --prompts     # sans effet si les prompts versionnés sont à jour
python3 tools/art/serie15.py --refs && python3 tools/art/serie15.py --ancres
python3 tools/art/serie15.py               # génère la série (Codex, aucune API payante)
python3 tools/art/serie15.py --contact     # planche de contact
```

**Image par image** : `python3 tools/art/serie15.py --commandes` imprime les commandes `tools/art/generer.sh ID prompt.txt refs…`. Une correction = copier le prompt en `_r2`, le corriger, relancer la commande avec le nom `_r2`. **Pas** de `manifeste.json`, `preparer.py`, `preparer_menu.py` ni scène au T2 (T5 : `serie15.py --manifeste` puis `serie15.py --controle`).

## Journal de la série 15

- **T1 (2026-10-11)** : liste du kit (19 images + 3 conditionnels), fiches, 24 prompts versionnés, commandes, planche de contrôle `build/art/AZ_KIT_v1.png` relue. Grilles non modifiées. Aucune image générée.
