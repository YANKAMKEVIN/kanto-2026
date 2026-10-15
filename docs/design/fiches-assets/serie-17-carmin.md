# Série 17 — Route 5, passage souterrain, Route 6 et Carmin-sur-Mer (jalon 15, lumière NE)

> Rédigée au **J15 T8** (2026-10-14, branche `j15-t8-kit` depuis `jalon-15` à `0e1d147`). Plan : `docs/tech/jalon-15.md` §1.3, §1.4, §2.1–§2.3, §2.9 ; conception : `docs/design/dossier-18-carmin-sur-mer.md` (verrouillé ; §13.1 vues et grilles, §17 contrat du J16). Génération au **T9** (Mac, Codex), validation de Kevin sur planche de contact, intégration au **T11** (manifeste, `preparer.py`, `preparer_menu.py`, règles, looks), cartes aux T13, T14, T18.
>
> **Numéro provisoire : 17.** Contrat du J16 : la série prend son numéro **au push**. Constaté le 2026-10-14 (`git fetch`, puis toutes les `fiches-assets/serie-*` de toutes les branches) : 01, 12, 13, 14, 15 sur `origin/*` ; **16 = J14** (`serie-16-cap-azuria.md`, branches locales `j14-*`, pas encore poussée). 17 est le prochain libre. **À revérifier au push** : si 17 est pris entre-temps, renommer la fiche, `tools/art/serie17.py`, `tools/art/prompts/serie17/` et les mentions de `jalon-15.md` / `etat-projet.md` (les identifiants d'images ne portent pas le numéro).

**Consigne de Kevin (J8–J14)** : le plus petit kit modulaire qui produit la **sensation** des vues validées dans Godot, sans répétition visible.
- **DA et composition** : `reference/souterrain-vue-generale-v1.png`, `route-6-vue-generale-v1.png`, `carmin-vue-generale-v1.png` (validées le 2026-10-14). **Route 5 : `route-5-vue-generale-v1.png`, validée le 2026-10-14** (dossier 18 §13.2) : la Pension (et le poste, l'entrée du souterrain) sont **recalés sur cette vue** au T9 (`REF_R5_PENSION`, `REF_R5_POSTE`, `REF_R5_ENTREE`) ; l'indice du tronc reste à juger sur la capture de la carte. **Géométrie, qui fait foi** : `tools/plans/route_5.txt` (v2), `underground_path.txt`, `route_6.txt`, `vermilion_city.txt` (aucune case touchée au T8).
- **Écarts des vues à ne pas reproduire** (dossier §13.1) : Route 6 pauvre en air marin (la carte en ajoute à la lisière) ; navire **court, d'allure de ferry** (la grille donne **29 × 7** : paquebot long et effilé) ; aucun personnage ni Pokémon peint.
- **Contrat du J16** (dossier §17, plan §2.9) : le **S.S. Anne** est un objet de décor **séparé**, seul l'état **amarré** est produit au J15 (absent si `ss_anne_departed`) ; le **jeune arbre** de l'Arène (49..50, 10) est un objet **séparé, retirable** (drapeau `cut_vermilion_gym_bush`), jamais peint dans la façade.
- **Outil** : `tools/art/serie17.py` (`--prompts`, `--refs`, `--ancres`, `--commandes`, `--planche`, `--contact`, `--manifeste` préparé et **non lancé**, `--controle` au T11 ; génération en **deux vagues**, trois à la fois). **Un prompt versionné par image** : `tools/art/prompts/serie17/<NOM>.txt`, `tools/art/attente/prompts/<NOM>_ATTENTE.txt`, `tools/art/combat_decors/prompts/COMBAT_DECOR_ROUTE5_6_PRAIRIE_r1.txt`.
- **Prompts** : ADN visuel v1 (cahier §1.3) + **LUMIÈRE NE** (souterrain : bloc `VALEURS_PIERRE`, aucune pénombre ni flaque de lumière peinte : le profil `underground` et les `LightGlow sconce` font l'ambiance). Aucun nom de licence, **aucun nom de navire**, **aucun emblème de type balle** (l'Arène porte un éclair sculpté, le Fan Club une rosette de ruban, la stèle des vagues et des spirales). Interdits : texte, lettres, logo, faune non-Pokémon (mouettes de la vue), Pikachu, sosie du héros.
- **Références** : recadrages `REF_CA_*`, `REF_R6_*`, `REF_SO_*` des trois vues et `REF_R5_*` de la vue de la Route 5 (boîtes versionnées dans `REFS`, × 3, 1 536 px max). **Ancres** copiées par `--ancres` depuis le checkout principal, puis **toute copie de travail** qui les possède (les images des séries 14 et 15 ne sont pas toutes dans `build/art` du checkout principal).
- **Planche de contrôle** (sans Codex) : `python3 tools/art/serie17.py --planche` → `build/art/J15_KIT_v1.png` (1 case = 48 px, héros à l'échelle) : réutilisés, sols, intérieurs, personnages, variations, nouveaux (référence recadrée à la taille en jeu), conditionnels, abandonnés. **Relue au T8.**

## Liste du kit

**A. Réutilisés tels quels.**
- *Sols* : `ground_herbe_01`, `ground_chemin_01` (chemins et rue `=`), `ground_paves_01` (place `p`), `ground_hautes_herbes_01` (herbes vertes `h` des deux routes), `ground_eau_01` (mer `W`, écume du shader), `ground_eau_canal_01` (étang de la Route 6, série 15), `ground_masse_roche_01` (roche brute `#` autour de la galerie, série 14) ; décalcomanies de fleurs.
- *Végétation, relief, mobilier* : forêt `DenseForest` / `tree_foret_*` (`T`, dont la « falaise côtière » de Carmin) ; `tree_a_01` et voisins (grands arbres `G`) ; `prop_buisson_*` (`x`) ; `prop_rocher_01` / `prop_grande_pierre_01` (rochers `R` de la Route 6) ; `prop_cloture_01` + `prop_cloture_v_01` (clôture du jardin de la Pension, clôture basse de la Route 6) ; **jardin clos** `j` : `prop_platebande_01`, `prop_massif_01`, `prop_hortensias_01` + fleurs (aucun Pokémon, F-4) ; `prop_panneau_01` (tous les panneaux) ; `prop_banc_01` (bancs `n` de la place) ; `object/poke_ball_ground` (objets visibles).
- *Eau (série 15)* : `relief_berge_*` + `prop_roseaux_01` (rives de l'étang) ; `prop_bitte_01` (bittes `z` hors passerelle) ; `prop_pont_pepite_pile_01` (piles le long des pontons) ; `prop_lampadaire_quai_01` (quai, au besoin).
- *Port* : `prop_caisses_01`, `prop_tonneau_01` (accents), `prop_casiers_peche_01`, `prop_barque_01` (abords du Pêcheur, au besoin).
- *Bâtiments* : **Centre** `bldg_centre_01` et **Boutique** `bldg_boutique_01` (les deux seuls emblèmes ronds autorisés) ; **maison d'Argenta** `bldg_maison_argenta_01` pour les **maisons 1 et 2** (7 de large, porte au milieu, toit orange : exactement la vue de Carmin), la maison 2 en miroir.
- *Intérieurs* (plan §2.2) : coques `int_centre_coque`, `int_boutique_coque`, **`int_poste_foret_coque`** (poste de la Route 5, deux bâtiments d'entrée du souterrain), **`int_maison_argenta_coque`** (Pension, Fan Club, Pêcheur, maisons 1 et 2) ; meubles existants (`int_plante`, `int_petite_etagere_01` = meuble bas qui ferme (5, 2) du poste, `int_canape_01`, `int_table_repas_01`, `int_cuisine_01`, `int_lit_01`, `int_aquarium_01`…) ; `int_long_comptoir_01` = **repli** du comptoir de la Pension.
- *Combat* : artworks officiels 052, 053 ; dos provisoires ; Miaouss d'exploration = T10 (hors de cette série).

**Personnages réutilisés** (« jamais deux fois le même modèle d'**habitant** sur une carte », plan §1.4) :

| Rôle | Modèle | Carte |
|---|---|---|
| promeneuse (P1) | `hiker` | Route 5 |
| voyageur du carrefour (P2) | `traveler` | Route 5 |
| passant | `old_man` | souterrain |
| garde de Safrania ×2 | `guard` | poste Route 5 (intérieur), Route 6 |
| Chloé, Manon | `lass` | Route 6 (Dresseuses : une classe) |
| Gabin, Mathis | `camper` | Route 6 |
| Axel, Basile | `scout` | Route 6 |
| pêcheur sans canne (P2) | `haru` (planche `pecheur`) | Route 6 |
| promeneur (P3) | `traveler` | Route 6 |
| infirmière, vendeur | `nurse`, `clerk` | Centre, Boutique |
| habitante (P4) | `lass` | Carmin (seule `lass` de la carte) |
| enfant (P5) | `kid` | Carmin |
| vieil habitant (P6) | `old_man` | Carmin |
| le Pêcheur | `haru` | maison du Pêcheur |
| membres du Fan Club ×2 | `lass_young`, `traveler` [D] | Fan Club |
| habitants des maisons 1 et 2 | `old_man` / `lass` [D] (une seule personne par maison) | intérieurs |

**B. Variations sans nouvel asset** : mer du port = `ground_eau_01` **assombrie** (`Shade`, bleu profond de la vue) ; maison 2 en miroir ; roche brute du souterrain assombrie par le profil `underground` ; herbes de la Route 5 plus vertes que celles de la Route 6 (teinte) ; massifs du jardin en miroir ± 8 %.

**C. Nouveaux : 28 images** (fiches ci-dessous) — 20 en vague 1, 8 en vague 2 (le gardien de la Pension, `old_man`, est retiré le 2026-10-14).

| Fiche → asset(s) | Rôle | Taille en jeu | Images | Vague |
|---|---|---|---|---|
| `WORLD_BLDG_PENSION_01` → `bldg_pension_01` | Pension (W), recalée sur la vue Route 5 validée | 7 × 6 | 1 | 1 |
| `WORLD_BLDG_POSTE_SAFRANIA_01` → `bldg_poste_safrania_01` | postes fermés (P) des deux routes | 7 × ≈ 4,5 | 1 | 1 |
| `WORLD_BLDG_ENTREE_SOUTERRAIN_01` → `bldg_entree_souterrain_01` | entrées du souterrain (U) des deux routes | 7 × ≈ 4 | 1 | 1 |
| `WORLD_BLDG_ARENE_CARMIN_01` → `bldg_arene_carmin_01` | Arène (Z), **sans l'arbre** | 12 × 7 | 1 | 1 |
| `WORLD_BLDG_FAN_CLUB_01` → `bldg_fan_club_01` | Fan Club (F) | 8 × 6 | 1 | 1 |
| `WORLD_BLDG_MAISON_PECHEUR_01` → `bldg_maison_pecheur_01` | maison du Pêcheur (m sud-ouest) | 7 × 6 | 1 | 1 |
| `WORLD_BLDG_SS_ANNE_GUIDE` | silhouette du paquebot (guide, non intégrée) | 29 × 7,5 | 1 | 1 |
| `WORLD_BLDG_SS_ANNE_PROUE` / `_MILIEU` / `_POUPE` → `bldg_ss_anne_*_01` | **S.S. Anne** (N), trois tranches à l'échelle | 10 + 9 + 10 × 7,5 | 3 | 2 |
| `WORLD_GROUND_PLANCHES_QUAI_01` → `ground_planches_quai_01` | platelage `q`, passerelle `g` | texture 384 | 1 | 1 |
| `WORLD_RELIEF_QUAI_BOIS_PLANCHE` → 6 modules | bords du quai et des pontons | voir fiche | 1 | 1 |
| `WORLD_PROP_CARMIN_PLANCHE` → 6 éléments | **jeune arbre** (A), passerelle, grue, bitte à amarre, cordage, caisses du port | 0,8 à 2 cases | 1 | 1 |
| `WORLD_PROP_ROUTES_J15_PLANCHE` → 4 éléments | indices tronc (R5) et joncs (R6), nénuphars ×2 | 0,6 à 1 case | 1 | 1 |
| `WORLD_PROP_VUE_PORT_01` → `prop_vue_port_01` | vue lointaine du port depuis le belvédère (R6) | 4 × 4 | 1 | 2 |
| `WORLD_GROUND_DALLES_SOUTERRAIN_01` → `ground_dalles_souterrain_01` | sol de la galerie `.` | texture 384 | 1 | 1 |
| `WORLD_GROUND_TRACES_SOUTERRAIN_01` → `ground_traces_souterrain_01` | traces de passage `=` | texture 384 | 1 | 2 |
| `WORLD_RELIEF_MUR_SOUTERRAIN_PLANCHE` → 6 modules | murs maçonnés de la galerie | voir fiche | 1 | 1 |
| `WORLD_PROP_SOUTERRAIN_PLANCHE` → 6 éléments | escaliers ×2, stèle, banc, **pierre descellée**, **applique** | 0,45 à 2 cases | 1 | 1 |
| `INT_J15_PLANCHE` → 6 meubles | comptoir de la Pension, escalier descendant, panier, fauteuil, vitrine, tableau | 1 à 3 cases | 1 | 1 |
| `PNJ_MARIN` + attente → `marin` (`sailor`) | marin de la passerelle | 128 px | 2 | 1, 2 |
| `PNJ_DOCKER` + attente → `docker` (`docker`) | les deux dockers | 128 px | 2 | 1, 2 |
| `PNJ_PRESIDENT_FAN_CLUB` + attente → `president_fan_club` (`fan_club_chairman`) | président du Fan Club | 128 px | 2 | 1, 2 |
| `UI_OBJETS_J15_PLANCHE` → `super_potion.webp`, `full_restore.webp` | icônes du Sac | 256 px | 1 | 1 |
| `COMBAT_DECOR_ROUTE5_6_PRAIRIE_r1` → décor `route_5_6_prairie` | combats sauvages des Routes 5 et 6 (chaîne CB.3) | 2,17 : 1 | 1 | 1 |

**Écarts au plan §1.4** (défauts, règle 4) :
- **Postes** et **entrées du souterrain** : une façade chacun pour les **deux** routes (emprises 7 × 4 sur la Route 5, 7 × 3 sur la Route 6 : seule la profondeur de l'emprise change, l'image est la même ; la porte est au milieu dans les deux grilles). Repli si refusé : `bldg_poste_foret_01` (passage ouvert) pour les entrées.
- **Maisons côtières** : pas de planche de variantes ; maisons 1 et 2 = maison d'Argenta (identique à la vue), seule la **maison du Pêcheur** est neuve. Conditionnel `WORLD_BLDG_MAISON_COTIERE_01` si la répétition se voit (les deux maisons sont à 46 colonnes l'une de l'autre).
- **Jardin clos** de la Pension : entièrement **réutilisé** (clôtures, massifs, plates-bandes) ; rien de neuf.
- **S.S. Anne** : 29 × 7 cases (≈ 2 800 px) ne tient pas dans une image de 1 536 px à la qualité du jeu : **guide** (silhouette entière, vague 1) puis **trois tranches** à 120 px par case (vague 2, guide joint), raccordées bout à bout ; un seul nœud parent au T14 (condition `ss_anne_departed`), trois sprites (plan §2.11 : « un seul sprite ou 3 tranches »).
- **Mer du port** : variation (`ground_eau_01` assombrie) ; texture neuve en conditionnel.
- **Enveloppe du Fan Club** : coque de maison d'Argenta + meubles (plan : « ou maison d'Argenta + tableaux ») ; `INT_FAN_CLUB_COQUE` en conditionnel.
- **Ajoutés** : nénuphars (vue de la Route 6), **vue lointaine du port** (dossier §6.1 « au bout, la première vue sur le port » et texte A.2 « les grues et les mâts du port » ; la vue de la Route 6 la peint dans son coin sud-est) ; **gardien de la Pension : abandonné** (décision de Kevin du 2026-10-14, dossier 18 §13.2 : modèle existant `old_man`, pas de personnage nouveau).

**D. Abandonnés** : personnages et Pokémon (aucun dans les vues) ; mouettes (faune non-Pokémon) ; **navire court « ferry »** de la vue de Carmin (→ paquebot 29 × 7) ; caisses de la vue posées hors des cases `k` (la grille décide) ; amas de 4 rochers neufs de la Route 6 (→ rochers existants) ; **lumière peinte** de la vue du souterrain (galerie éclairée, halos) → lumière NE + `LightGlow` ; médaillon rond au fronton de l'Arène dans la vue (→ éclair sculpté) ; intérieur du navire et état « parti » (J16) ; cheminée du S.S. Anne au-dessus des toits de Carmin (plan §1.4 : relève de la peinture ; la **vue lointaine** de la Route 6 la reprend au loin).

**Conditionnels** (prompts prêts, jamais lancés par défaut, décision notée dans `etat-projet.md`) : `WORLD_GROUND_EAU_PORT_01`, `INT_FAN_CLUB_COQUE`, `WORLD_BLDG_MAISON_COTIERE_01`.

**Contrôle « chaque élément des vues a un asset »** (CA du T8) — *Carmin* : forêt et lisière côtière → A ; Centre, Boutique → A ; maisons à toit orange → A (maison d'Argenta) ; maison à toit vert → Fan Club neuf ; Arène grise → neuve ; arbre devant l'Arène → jeune arbre (planche Carmin, objet séparé) ; maison du sud-ouest → Pêcheur neuve ; maison du sud-est → A ; rue de terre → chemin ; place pavée et ses quatre bancs → pavés + bancs ; massifs, fleurs, arbres → A ; panneaux → A ; quai de planches → texture + bords en bois ; pontons → texture + bords + pieux ; bittes, cordages → bitte à amarre neuve (passerelle) + `prop_bitte_01` ; caisses, tonneaux → caisses du port + A ; passerelle → planche Carmin ; paquebot → S.S. Anne (guide + 3 tranches) ; mer bleu profond → `ground_eau_01` assombrie ; mouettes → abandonnées. *Route 6* : bâtiment de sortie (toit d'ardoise, ouverture sombre) → entrée du souterrain ; poste aux portes bleues et lanternes → poste de Safrania ; forêt, prairie, fleurs, chemin → A ; hautes herbes ×4 → A ; rochers → A ; grands arbres → A ; étang, roseaux → eau de canal + berges + roseaux (A) ; nénuphars → planche des routes ; clôture → A ; panneau, Poké Ball → A ; port au loin (grue, mâts, cheminée) → vue lointaine. *Souterrain* : roche brute → masse rocheuse (A, assombrie) ; murs de pierre taillée → planche des murs ; sol dallé → dalles ; traces → texture des traces ; deux escaliers → planche du souterrain ; stèle, pierre descellée, banc → planche du souterrain ; appliques ×6 → applique + `LightGlow sconce`. *Route 5 (grille v2, pas de vue)* : forêt, prairies, chemin, hautes herbes, Poké Ball, panneaux → A ; Pension → neuve ; jardin clos → A ; poste → poste de Safrania ; entrée du souterrain → neuve ; tronc indice → planche des routes. Rien n'est implémenté parce qu'il est sur une image (règle 10) : la grille décide de la place.

## Alignement sur les outils de carte (T13, T14, T18)

**Quai et pontons de Carmin** (`build_vermilion_city.gd`, T14 ; même logique que `QUAY_PIECES` de la série 15, posés **dans les cases d'eau `W`** de la frontière, jamais sur une case praticable) :

| Rôle (case d'eau dont le sol est…) | Image | Taille préparée visée |
|---|---|---|
| au nord (bord sud du quai, rangée 27 ; bouts de pontons) | `relief_quai_bois_01` / `02` (variantes à la graine) | 192 × ≈ 67 (2 × 0,7) |
| à l'ouest / à l'est (côtés des pontons x 9..10, 54..55) | `relief_quai_bois_03` / en miroir | ≈ 24 × 192 |
| au nord, avec de l'eau des deux côtés (extrémité d'un ponton) | `relief_quai_bois_04` | 192 × ≈ 67 |
| au nord-ouest / nord-est (départ d'un ponton depuis le quai) | `relief_quai_bois_05` / en miroir | ≈ 48 × 67 |
| pieu isolé (le long d'un ponton, à la main) | `prop_pieu_quai_01` | ≈ 38 × 96 |

Les bouts de pontons de la grille portent des bittes `z` ((9..10, 35), (54..55, 33)) : `prop_bitte_01` (série 15) posé **sur** la case `z`, le module `04` dans la case d'eau suivante. La passerelle `g` (31..32, 27) : texture de planches + `prop_passerelle_01` (2 × 1,3) par-dessus ; la case (32, 26) `z` porte `prop_bitte_amarre_01` (cordage vers le navire). Caisses `k` : `prop_caisses_port_01` (2 × 1) sur (23..24, 26) et (44..45, 26) ; **grue** `prop_grue_quai_01` sur (56..57, 24) [D, la vue n'en montre pas mais le texte A.2 et la vue de la Route 6 en parlent : **à juger sur capture du T14**, repli : caisses]. **Platelage des pontons** : la texture a ses planches **est-ouest** ; sur les pontons (nord-sud), une copie tournée de 90° au T11 (`preparer.py`) ou la même orientation (à juger).

**S.S. Anne** (T14) : un nœud `ss_anne` (condition `ss_anne_departed` absente ⇒ visible) portant trois sprites alignés sur les colonnes 21..30, 31..39, 40..49 de la rangée 34 (bas de l'emprise `N`, ligne de flottaison), sans ombre portée ni de contact ; la coupée peinte (11e et 12e cases depuis la proue, tranche du milieu) tombe sur l'accès `E` (31..32, 28). Écart de raccord éventuel : fondu de 8 px au T11, ou `_r2` de la tranche fautive.

**Jeune arbre** (T15) : `prop_jeune_arbre_arene_01` sur (49..50, 10), **objet séparé** retiré par `cut_vermilion_gym_bush` (nom à confirmer avec le J16) ; la façade de l'Arène n'a pas d'arbre.

**Souterrain** (`build_underground_path.gd`, T18) : murs posés sur les cases `#` qui touchent le sol (4-voisinage), même logique que les parois de grotte de la série 14 : sol au **sud** → `relief_mur_souterrain_01` / `02` (face visible, 2 × 1) ; sol au **nord** → `03` (couronnement seul) ; sol à l'est / à l'ouest → `04` / miroir ; angles → `05` / `06` (+ miroirs). Escaliers : `prop_escalier_souterrain_monte_01` sur (3..4, 1), `…_descend_01` sur (19..20, 28). Stèle (7, 6), pierre descellée (11, 9) **dans le mur nord de l'alcôve A2** (EXAMINER depuis (11, 10) ↑), banc (23, 20), appliques sur les six cases `applique_*` (+ `LightGlow sconce`, sol peint plus clair dessous par le masque des traces). Sol : `ground_dalles_souterrain_01` (base) + `ground_traces_souterrain_01` (canal r, cases `=`).

**Routes** (T13, T14) : postes et entrées posés sur les emprises `P` / `U` (porte au milieu de la rangée du bas) ; indice tronc (16, 31) R5, indice joncs (10, 32) R6 ; nénuphars dans l'étang (décalcomanies d'eau, 3 à 5 posées à la main) ; **vue du port** au-dessus de la forêt du coin sud-est de la Route 6 (x 36..39, y 47..50 environ, couche au-dessus des arbres, visible depuis le belvédère (37, 46)).

## Fiches

Pour chaque asset : rôle, emprise (cases de la grille), taille en pixels du jeu (1 case = 96 px), ancrage et réglages du manifeste prévus (T11). Hauteurs et réglages = **valeurs par défaut** (règle 4). Le prompt complet est dans `tools/art/prompts/serie17/<NOM>.txt`.

### Bâtiments

#### WORLD_BLDG_PENSION_01 → `bldg_pension_01` (vague 1) — recalée sur la vue Route 5 validée
- Emprise `W` 7 × 6 (24..30, 22..27), porte `D` (27, 27) = 4e colonne ; `axe w`, `cases 7`, ombre oui, contact 0,12 (≈ 672 × 580 px). Maison de campagne de la vue : **toit de tuiles rouge-orangé chaud** à deux pans, cheminée de pierre à droite du faîtage, murs crépis crème (ni colombages, ni auvent, ni lucarne, ni girouette), porte brun moyen, volets vert sapin, jardinières et pots fleuris. Sans jardin (posé par la carte), sans enseigne. **Jointes** : `REF_R5_PENSION` (vue validée), souche, arbre A, maison d'Argenta.

#### WORLD_BLDG_POSTE_SAFRANIA_01 → `bldg_poste_safrania_01` (vague 1)
- Emprises `P` 7 × 4 (Route 5, 31..37, 41..44, porte (34, 44)) et 7 × 3 (Route 6, 33..39, 5..7, porte (36, 7)) ; `cases 7`, ≈ 672 × 430 px. Pierre gris-beige, ardoises bleu-gris, **porte double fermée bleu-gris**, deux lanternes éteintes. **Jointes** : `REF_R6_POSTE`, postes de la forêt.

#### WORLD_BLDG_ENTREE_SOUTERRAIN_01 → `bldg_entree_souterrain_01` (vague 1)
- Emprises `U` 7 × 4 (Route 5, 8..14, 53..56, porte (11, 56)) et 7 × 3 (Route 6, 4..10, 2..4, porte (7, 4)) ; `cases 7`, ≈ 672 × 384 px. Même famille que le poste, **arche ouverte** où l'on devine un escalier qui descend, clé de voûte à la vague. **Jointes** : `REF_R6_SORTIE`, poste de la forêt.

#### WORLD_BLDG_ARENE_CARMIN_01 → `bldg_arene_carmin_01` (vague 1)
- Emprise `Z` 12 × 7 (44..55, 3..9), porte (49..50, 9) = 6e et 7e colonnes ; `cases 12`, ombre oui, contact 0,12 (comme les Arènes d'Argenta et d'Azuria). Pierre grise et métal riveté, ardoises anthracite, paratonnerres, **éclair sculpté** au fronton, **sans arbre**. **Jointes** : `REF_CA_ARENE`, Arènes d'Argenta et d'Azuria.

#### WORLD_BLDG_FAN_CLUB_01 → `bldg_fan_club_01` (vague 1)
- Emprise `F` 8 × 6 (12..19, 4..9), porte double (15..16, 9) ; `cases 8`. Pierre crème, **tuiles vert sapin**, marquise rayée, rosette de ruban sculptée. **Jointes** : `REF_CA_FAN_CLUB`, maison d'Argenta.

#### WORLD_BLDG_MAISON_PECHEUR_01 → `bldg_maison_pecheur_01` (vague 1)
- Emprise `m` 7 × 6 (5..11, 17..22), porte (8, 22) ; `cases 7`. Chaux, **tuiles bleu ardoise**, volets bleu délavé, filet de pêche, rames, casier. **Jointes** : `REF_CA_PECHEUR`, maison d'Argenta, barque.

### S.S. Anne

#### WORLD_BLDG_SS_ANNE_GUIDE (vague 1, non intégrée)
- Silhouette entière 29 × 7,5 (≈ 1 450 px de large) : coque bleu marine effilée, ligne de flottaison rouge sombre, hublots, trois ponts blancs, **une cheminée rouge à manchette noire**, canots, coupée au flanc nord (11e–12e cases). Sert d'ancre aux tranches, et de **repli** agrandi si les tranches ne se raccordent pas. **Jointes** : `REF_CA_NAVIRE`, Arène d'Azuria (pierre claire), ponts (bois).

#### WORLD_BLDG_SS_ANNE_PROUE / _MILIEU / _POUPE → `bldg_ss_anne_proue_01`, `_milieu_01`, `_poupe_01` (vague 2)
- Emprise `N` 29 × 7 (21..49, 28..34) en trois tranches de 10, 9 et 10 cases, **échelle fixe 1 case = 120 px** à la génération (≈ 1 200 × 900), coupées net à la verticale aux raccords ; préparées à 960 / 864 / 960 × ≈ 720 px ; `ombre` non, `contact` aucun. **Jointes** : le guide.

### Port de Carmin

#### WORLD_GROUND_PLANCHES_QUAI_01 → `ground_planches_quai_01` (vague 1)
- Platelage `q` (rangées 24..26 et pontons) et passerelle `g` : planches est-ouest, 4 par case, clous, bois miel et délavé. Texture 1 024² raccordable → 384 px (contraste 1,0, `raccord` 24). **Jointes** : `REF_CA_QUAI`, ponts (série 15).

#### WORLD_RELIEF_QUAI_BOIS_PLANCHE → `relief_quai_bois_01..05`, `prop_pieu_quai_01` (vague 1)
- Planche 3 × 2 de 512, 1 case = 200 px, largeurs `[2, 2, 0.25, 2, 0.5, 0.4]`, contact 0, couche du sol (`GroundDecals`) pour les modules. Poutre de rive brun sombre sur pieux goudronnés, algues, ligne d'eau mouillée ; **ni eau ni écume peintes**. Rôles : §« Alignement ». **Jointes** : `REF_CA_QUAI_BORD`, `REF_CA_PONTON`, `REF_CA_QUAI`, quais et ponts de la série 15.

#### WORLD_PROP_CARMIN_PLANCHE → 6 éléments (vague 1)
- Planche 3 × 2 de 512, 1 case = 150 px, largeurs `[2, 2, 2, 1, 0.8, 2]`, contact 0,15 : `prop_jeune_arbre_arene_01` (2 × ≈ 2, tronc fin : « on pourra le couper », **objet séparé retirable**), `prop_passerelle_01` (2 × 1,3, rampe de bois et mains courantes de corde), `prop_grue_quai_01` (2 × ≈ 3,2, rouge sombre riveté), `prop_bitte_amarre_01` (1, amarre de chanvre vers le bas), `prop_cordage_01` (0,8, lové à plat), `prop_caisses_port_01` (2 × ≈ 1,4, caisses cerclées + tonneau + filet). **Jointes** : `REF_CA_ARBRE`, `REF_CA_PASSERELLE`, `REF_CA_AMARRES`, `REF_CA_CAISSES`, caisses, tonneau, planche de ville d'eau (bitte).

### Routes 5 et 6

#### WORLD_PROP_ROUTES_J15_PLANCHE → `prop_indice_tronc_01`, `prop_indice_joncs_01`, `prop_nenuphars_01`, `_02` (vague 1)
- Planche 2 × 2 de 768 × 512, 1 case = 200 px, largeurs `[1, 1, 1, 0.6]`, contact 0,1. Indice **tronc** (R5 (16, 31), Antidote ) plus gris et plus clair que `prop_tronc_couche_01` ; indice **joncs** (R6 (10, 32), Super Potion) jaunis et couchés, plus clairs que `prop_roseaux_01` ; nénuphars à plat (couche d'eau). **Jointes** : `REF_R6_NENUPHARS`, `REF_R6_ETANG`, tronc couché, indices (série 14), berges (série 15).

#### WORLD_PROP_VUE_PORT_01 → `prop_vue_port_01` (vague 2)
- 4 × 4, au-dessus de la forêt du coin sud-est de la Route 6 : haut de grue, deux mâts, sommet de la cheminée du S.S. Anne, bandeau de mer ; plus petit et plus bleuté (lointain) ; bas fondu (les arbres le recouvrent). `ombre` non. **Jointes** : `REF_R6_PORT`, guide du navire, planche de Carmin (grue). **Défaut à juger** sur capture du T14 (repli : rien, comme le plan §1.4).

### Passage souterrain

#### WORLD_GROUND_DALLES_SOUTERRAIN_01 → `ground_dalles_souterrain_01` (vague 1)
- Sol `.` : grandes dalles gris-beige en assises, joints fins, un peu de mousse ; plus régulier et plus clair que le sol de grotte. Texture 384. **Jointes** : `REF_SO_SOL`, sol de grotte (série 14), pavés.

#### WORLD_GROUND_TRACES_SOUTERRAIN_01 → `ground_traces_souterrain_01` (vague 2, joint les dalles)
- Cases `=` : mêmes dalles **polies et usées** dans le sens de la marche ; différence douce (mélange par masque, canal r de `PaintedGround`). **Jointes** : `REF_SO_GALERIE`, dalles (vague 1).

#### WORLD_RELIEF_MUR_SOUTERRAIN_PLANCHE → `relief_mur_souterrain_01..06` (vague 1)
- Planche 3 × 2 de 512, 1 case = 200 px, largeurs `[2, 2, 2, 0.35, 0.35, 0.35]`, contact 0. Pierre taillée gris-beige en assises, couronnement clair ; rôles : §« Alignement ». **Jointes** : `REF_SO_MUR`, `REF_SO_ANGLE`, `REF_SO_GALERIE`, parois de grotte et masse rocheuse (série 14).

#### WORLD_PROP_SOUTERRAIN_PLANCHE → 6 éléments (vague 1)
- Planche 3 × 2 de 512, 1 case = 200 px, largeurs `[2, 2, 1, 1, 1, 0.45]`, contact 0,1 : `prop_escalier_souterrain_monte_01` (2 × 1,3, nord), `…_descend_01` (2 × 1,3, sud), `prop_stele_01` (1 × 1,4, vagues et spirales, **aucune lettre**), `prop_banc_souterrain_01` (1 × 0,6), `prop_pierre_descellee_01` (1 × 1, module de mur dont un bloc sort : indice de la **Guérison**), `prop_applique_01` (0,45 × 0,8, verre ambré **sans halo**). **Jointes** : `REF_SO_ESCALIER_N`, `REF_SO_STELE`, `REF_SO_PIERRE`, `REF_SO_BANC`, `REF_SO_APPLIQUE`, échelles et indices (série 14), masse rocheuse.

### Intérieurs

#### INT_J15_PLANCHE → 6 meubles (vague 1)
- Planche 3 × 2 de 512, 1 case = 150 px, largeurs `[3, 2, 1, 1.2, 2, 1.5]`, contact 0,2 : `int_comptoir_pension_01` (3 × 1 : registre, clochette, bocal de baies ; gardien `old_man` derrière, modèle `ClerkCounter` du plan §2.2), `int_escalier_descendant_01` (2 × ≈ 1,6 : (4..5, 2) des deux bâtiments d'entrée, warps `STEP_ON` sans direction), `int_panier_pokemon_01` (1 : Pension, vide), `int_fauteuil_president_01` (1,2 : Fan Club), `int_vitrine_rubans_01` (2 × 2 : Fan Club), `int_tableau_port_01` (1,5 × 1 : mur du Fan Club, « tableaux » du plan). **Jointes** : long comptoir, canapé, grande étagère.

### Personnages (marche puis attente)

Modèle commun des séries 10–16 : marche 4 × 4 (1024 × 1536, héros validé joint, « ne ressemble pas au héros »), attente 4 × 1 (1536 × 1024) calée sur la marche jointe. **128 px**. Préparation (T11) : sections `personnages` / `attentes` ; looks **en fin** de `build_character_frames.gd`.

| Fiche | Tenue (défaut, règle 4) | Attente | Jointes |
|---|---|---|---|
| `PNJ_MARIN` → `marin` (`sailor`) | ≈ 25 ans, vareuse blanche à **col marin bleu marine**, foulard rouge, pantalon à pont, **bachi blanc sans pompon** | mains croisées dans le dos | garde, pêcheur (à ne pas copier) |
| `PNJ_DOCKER` → `docker` (`docker`) | ≈ 35 ans, costaud, bonnet de laine gris, barbe, **pull marin vert-de-gris**, salopette ocre, gants, corde à l'épaule | poings sur les hanches | pêcheur |
| `PNJ_PRESIDENT_FAN_CLUB` → `president_fan_club` (`fan_club_chairman`) | ≈ 65 ans, rond, **moustache blanche en guidon**, costume trois pièces bordeaux, montre à gousset, nœud papillon vert, rosette | une main sur le ventre, l'autre levée | vieil homme |

### Icônes du Sac

#### UI_OBJETS_J15_PLANCHE → `assets/ui/items/super_potion.webp`, `full_restore.webp` (vague 1)
- Planche 1536 × 1024 à **4 colonnes de 384** : **Super Potion** (même vaporisateur que la Potion, violet-magenta) en 1re, **Guérison** (jaune d'or, bande verte) en 2e, colonnes 3–4 vides. Chaîne `preparer_menu.py` : T11 ajoute `("UI_OBJETS_J15_PLANCHE_r1.png", ["super_potion", "full_restore"])` **en fin** de `PLANCHES_OBJETS_SUIVANTES`. **Jointes** : `MENU_OBJETS_PLANCHE_r1`, `assets/ui/items/potion.webp`.

### Décor de combat

#### COMBAT_DECOR_ROUTE5_6_PRAIRIE_r1 → `route_5_6_prairie` (vague 1)
- Chaîne CB.3 (`tools/art/combat_decors/`, `decors.json` au T11) : prairie fleurie entre deux lisières, golden hour (les décors de combat restent peints dans l'ambiance, comme ceux des J12–J13), points A (67 %, 55 %) et B (31 %, 97 %), zones calmes. Partagé par les deux routes [D]. Carmin et le souterrain : aucun combat sauvage. **Jointes** : `combat-v1.webp`, `combat-decors-planche-v1.webp`, vue de la Route 6.

### Conditionnels (prompts prêts, non lancés)

- `WORLD_GROUND_EAU_PORT_01` : mer bleu profond si `ground_eau_01` assombrie ne suffit pas (capture du T14).
- `INT_FAN_CLUB_COQUE` (15 × 10) : salon de club à boiseries vertes, si la coque de maison d'Argenta ne suffit pas.
- `WORLD_BLDG_MAISON_COTIERE_01` (7 × 6) : autre maison d'habitants si les maisons 1 et 2 identiques se voient.

## Commandes du T9

**Sur le Mac, depuis la racine de la copie** (trois générations à la fois, vague 1 puis 2 ; une image déjà présente n'est pas refaite ; les conditionnels ne partent pas) :

```bash
python3 tools/art/serie17.py --prompts     # sans effet si les prompts versionnés sont à jour
python3 tools/art/serie17.py --refs && python3 tools/art/serie17.py --ancres
python3 tools/art/serie17.py               # 21 images (vague 1) puis 9 (vague 2), Codex, aucune API payante
python3 tools/art/serie17.py --contact     # build/captures/jalon15_assets/serie17_contact.png → Kevin
```

**Image par image** : `python3 tools/art/serie17.py --commandes`. Une correction = une entrée de `CORRECTIONS` (`(identifiant, 2)` → description corrigée), `--prompts`, relancer la commande `_r2`. **Pas** de `manifeste.json`, `preparer.py`, `preparer_menu.py` ni scène au T9 (T11 : `serie17.py --manifeste` puis `--controle`).

## Journal de la série 17

- **T8 (2026-10-14, branche `j15-t8-kit`)** : liste du kit (**30 images** nouvelles + 3 conditionnels), fiches, 33 prompts versionnés, commandes, planche de contrôle `build/art/J15_KIT_v1.png` relue (réutilisés, sols, intérieurs, personnages, variations, références des nouveaux à la taille en jeu, conditionnels, abandonnés). Numéro 17 provisoire (revérifié au push). Grilles non modifiées. Aucune image générée.
