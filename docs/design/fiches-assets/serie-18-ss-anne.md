# Série 18 — S.S. Anne et Arène de Carmin (jalon 16, lumière NE)

> Rédigée au **J16 T1** (2026-10-16, branche `j16-t1-kit` depuis `jalon-16` à `58a7bf37`). Plan : `docs/tech/jalon-16.md` §1.3, §1.4, §3 « T1 » ; conception : `docs/design/dossier-19-ss-anne-major-bob.md` (verrouillé ; §0.4 vues et grilles, §6 capitaine, §7 Coupe, §9 Arène, §12 art). Génération au **T2** (Mac, Codex), validation de Kevin sur planche de contact, intégration au **T10** (manifeste, `preparer.py`, `preparer_menu.py`, looks), cartes aux T11, T14.
>
> **Numéro provisoire : 18.** Contrat entre jalons : la série prend son numéro **au push**. Constaté le 2026-10-16 (`git fetch`, puis `git log --all` sur `docs/design/fiches-assets` et `tools/art`) : 01, 12 à 17 (17 = J15, sur `main`), **19 = J17** (`j17-t11-art`), **20 = J19** (`j19-*`) ; **18 n'existe sur aucune branche**. **À revérifier au push** : si 18 est pris entre-temps, renommer la fiche, `tools/art/serie18.py`, `tools/art/prompts/serie18/` et les mentions de `jalon-16.md` / `etat-projet.md` (les identifiants d'images ne portent pas le numéro).

**Consigne de Kevin (J8–J15)** : le plus petit kit modulaire qui produit la **sensation** des vues validées dans Godot, sans répétition visible.
- **DA et composition** : `reference/ss-anne-pont-principal-v1.png`, `ss-anne-pont-exterieur-v1.png`, `arene-carmin-v1.png` (validées le 2026-10-16). Les autres salles du navire (couloir et cabine du capitaine, restaurant, pont inférieur, cabines A/B/C) **suivent le rendu du pont principal** : leurs coques partent en vague 2, la coque du pont principal jointe. **Géométrie, qui fait foi** : `tools/plans/ss_anne_*.txt`, `carmin_arene.txt` (aucune case touchée au T1) ; planche `reference/ss-anne-plans-v1.png`.
- **Écarts des vues à ne pas reproduire** (dossier §0.4) : zone du Champion de l'Arène peinte sur 2 rangées (la grille en a **3**, rangées 2..4) ; faisceaux et flaques de lumière dorée du pont principal ; lueur bleue peinte de l'Arène (tubes, voyants, barrière) ; mouettes du pont extérieur ; passerelle un peu large (grille : 2 cases). Les **15 objets fouillables sont des poubelles identiques** (défaut retenu le 2026-10-16).
- **Outil** : `tools/art/serie18.py` (`--prompts`, `--refs`, `--ancres`, `--commandes`, `--planche`, `--contact`, `--manifeste` préparé et **non lancé** ; génération en **deux vagues**, trois à la fois). **Un prompt versionné par image** : `tools/art/prompts/serie18/<NOM>.txt`, `tools/art/attente/prompts/<NOM>_ATTENTE.txt` (+ `CAPITAINE_MALADE.txt`), `tools/art/combat_decors/prompts/COMBAT_DECOR_{SS_ANNE_SALON,SS_ANNE_PONT,GYM_CARMIN}_r1.txt`.
- **Géométrie des coques tirée des grilles** : `serie18.geometrie()` lit la grille et écrit dans le prompt la taille, l'épaisseur des murs, chaque porte `D`, chaque sortie `X` (en cases et en pixels de l'image) : une retouche de grille → `--prompts` → diff à relire.
- **Prompts** : ADN visuel v1 (cahier §1.3) + **LUMIÈRE NE** ; intérieurs : appliques, hublots, tubes et voyants peints **éteints-neutres, sans halo** (bloc `LUMIERE_INT`) : la lumière vient des profils et des `LightGlow`. Aucun nom de licence, **aucun nom de navire**, aucune plaque lisible, **aucun emblème de type balle**. Interdits : texte, lettres, logo, faune non-Pokémon (mouettes), Pikachu, sosie du héros.
- **Références** : recadrages `REF_PP_*`, `REF_PE_*`, `REF_AC_*` des trois vues (boîtes versionnées dans `REFS`, × 3, 1 536 px max). **Ancres** copiées par `--ancres` depuis le checkout principal, puis **toute copie de travail** qui les possède, et sinon (**nouveau**) depuis l'**asset préparé** (dans la copie, ou `origin/main` par `git show` : marin, navire, Arène de Carmin, planches du quai de la série 17 tant que `jalon-16` n'a pas fusionné le J15).
- **Planche de contrôle** (sans Codex) : `python3 tools/art/serie18.py --planche` → `build/art/J16_KIT_v1.png` (1 case = 48 px, héros à l'échelle) : réutilisés (dont la série 17 lue sur `main`), variations, coques (vue validée étirée à la grille, et plan en aplats à côté), pont extérieur, mobilier (référence ou aplat à la taille en jeu), Arène, personnages, effet, Sac, combat, conditionnels, abandonnés. **Relue au T1.**

## Liste du kit

**A. Réutilisés tels quels.**
- *Navire et Carmin (série 17, `main`)* : S.S. Anne amarré `bldg_ss_anne_proue_01` / `_milieu_01` / `_poupe_01` (nœud `Entities/SsAnne`, cible de l'étape `animate` du départ ; **aucun état « parti » à peindre** : le nœud est caché) ; passerelle `prop_passerelle_01` ; **arbuste** `prop_jeune_arbre_arene_01` (`Entities/GymTree`, retiré par `cut_vermilion_gym_bush`) ; `prop_caisses_port_01` = caisses `k` 2 × 1 du pont inférieur (19..20, 2) ; quai et Arène de Carmin (façade) inchangés.
- *Intérieurs* : `int_plante` (plantes `x` du pont principal (23, 2), (2, 10)) ; `object/poke_ball_ground` (objets visibles) ; objets cachés sans indice peint (armoire de la cabine B, caisse (5, 6), comptoir de la cuisine).
- *Sols* : `ground_eau_01` (mer `w` du pont extérieur, shader, assombrie comme le port de Carmin) ; `ground_planches_quai_01` (série 17) pour le pont de teck, voir B.
- *Combat* : artworks officiels et dos existants (Kadabra, Machoc, Voltorbe, Raichu… : **zéro espèce nouvelle**, R-4) ; aucune image de Pokémon dans cette série.

**Personnages réutilisés** (« jamais deux fois le même modèle d'**habitant** sur une carte » ; les Dresseurs d'une même classe partagent leur modèle) :

| Rôle | Modèle (look) | Carte |
|---|---|---|
| rival n° 4 | `rival` | couloir du capitaine |
| marin de la passerelle, matelot | `sailor` (`marin`, série 17) | pont principal, pont inférieur |
| Marins Erwan, Loïc, Yann, Rémi, Paul, Marc | `sailor` | pont inférieur, pont extérieur, pont principal, Arène |
| Fillette Léna | `lass` | cabine A |
| Scout Basile | `scout` | cabine B |
| passager_1 | `traveler` | pont principal |
| serveur | `clerk` (`marchand` : moustache, tablier) | restaurant |
| guide | `gym_guide` | Arène |

**B. Variations sans nouvel asset** : pont de teck = `ground_planches_quai_01` **éclairci** (modulate, planches est-ouest comme la vue) ; mer = `ground_eau_01` assombrie ; **cabines A, B, C = une seule coque** et les mêmes meubles (grilles identiques ; comme Rouge/Bleu) ; marin = `sailor` de la série 17 (le « `swimmer` habillé » du plan §1.4 B n'a plus lieu d'être) ; serveur = `clerk` tel quel (le « `clerk` en veste » du plan demanderait une image) ; couchette du capitaine = lit de cabine ; barrière « absente » = aucune image (les 3 PNJ objets et le visuel disparaissent avec `vermilion_gym_puzzle_solved`).

**C. Nouveaux : 30 images** (fiches ci-dessous) — 17 en vague 1, 13 en vague 2.

| Fiche → asset(s) | Rôle | Taille en jeu | Images | Vague |
|---|---|---|---|---|
| `INT_SS_ANNE_PONT_PRINCIPAL_COQUE` → `int_ss_anne_pont_principal_coque` | hall d'accueil, **recalé sur la vue validée** | 26 × 13 (2 496 × 1 248) | 1 | 1 |
| `INT_ARENE_CARMIN_COQUE` → `int_arene_carmin_coque` | Arène, **recalée** (Champion : 3 rangées) | 17 × 15 (1 632 × 1 440) | 1 | 1 |
| `INT_SS_ANNE_COULOIR_COQUE` → `int_ss_anne_couloir_coque` | couloir du capitaine (bande recadrée) | 18 × 7 (1 728 × 672) | 1 | 2 |
| `INT_SS_ANNE_CABINE_CAPITAINE_COQUE` → `int_ss_anne_cabine_capitaine_coque` | cabine du capitaine | 14 × 10 (1 344 × 960) | 1 | 2 |
| `INT_SS_ANNE_RESTAURANT_COQUE` → `int_ss_anne_restaurant_coque` | restaurant (passe-plat peint) | 18 × 11 (1 728 × 1 056) | 1 | 2 |
| `INT_SS_ANNE_PONT_INFERIEUR_COQUE` → `int_ss_anne_pont_inferieur_coque` | pont inférieur (escalier montant peint) | 22 × 11 (2 112 × 1 056) | 1 | 2 |
| `INT_SS_ANNE_CABINE_COQUE` → `int_ss_anne_cabine_coque` | cabines A, B, C | 12 × 9 (1 152 × 864) | 1 | 2 |
| `INT_SS_ANNE_PLANCHE_A` → 6 meubles | banquette, comptoir d'accueil, table de restaurant, comptoir de cuisine, lit de cabine, armoire | 1 à 4 cases | 1 | 1 |
| `INT_SS_ANNE_PLANCHE_B` → 6 meubles | table sous hublot, bureau du capitaine, lavabo 1 case, table à cartes, caisses de cale 2 × 2 et 3 × 2 | 1 à 3 cases | 1 | 2 |
| `INT_ARENE_CARMIN_PLANCHE` → 5 éléments | **poubelle unique** (×15), armoires électriques A, B, barrière active, barrière coupée | 0,75 à 3 cases | 1 | 1 |
| `WORLD_RELIEF_PONT_EXTERIEUR_PLANCHE` → 8 éléments | bastingages N ×2, S + flanc, E, angles NE et SE, chaises longues, bouée | 0,35 à 2 cases | 1 | 1 |
| `WORLD_BLDG_SS_ANNE_SUPERSTRUCTURE_OUEST` → `bldg_ss_anne_superstructure_01` | bout de superstructure et porte `D` du pont extérieur | 1,3 × 7,5 | 1 | 1 |
| `PNJ_CAPITAINE` + attente + `CAPITAINE_MALADE` → `capitaine` (`captain`), `capitaine_malade` | capitaine (penché sur son lavabo, puis soulagé) | 128 px | 3 | 1, 2, 2 |
| `PNJ_MAJOR_BOB` + attente → `major_bob` (`surge`) | Champion | 128 px | 2 | 1, 2 |
| `PNJ_GENTLEMAN` + attente → `gentleman` (`gentleman`) | Armand, Émile, Victor, Louis | 128 px | 2 | 1, 2 |
| `PNJ_ROCKEUR` + attente → `rockeur` (`rocker`) | Axel (Arène) | 128 px | 2 | 1, 2 |
| `PNJ_HOTESSE` + attente → `hotesse` (`hostess`) | hôtesse d'accueil | 128 px | 2 | 1, 2 |
| `PNJ_PASSAGERE` + attente → `passagere` (`passenger_f`) | passagère du pont extérieur, convive du restaurant | 128 px | 2 | 1, 2 |
| `FX_COUPE_PLANCHE` → `fx_coupe_01..04` | effet générique de Coupe (trait de lame, feuilles) | ≈ 2 × 2 cases | 1 | 1 |
| `UI_OBJETS_J16_PLANCHE` → `paralyze_heal.webp`, `awakening.webp` | icônes du Sac (Anti-Para, Réveil, trouvés à bord) | 256 px | 1 | 1 |
| `COMBAT_DECOR_SS_ANNE_SALON_r1` → `ss_anne_salon` | combats à l'intérieur du navire (5 cartes) | 2,17 : 1 | 1 | 1 |
| `COMBAT_DECOR_SS_ANNE_PONT_r1` → `ss_anne_pont` | combats du pont extérieur | 2,17 : 1 | 1 | 1 |
| `COMBAT_DECOR_GYM_CARMIN_r1` → `vermilion_gym_salle` | combats de l'Arène | 2,17 : 1 | 1 | 1 |

**Écarts au plan §1.4** (défauts, règle 4, **à faire valider par Kevin**) :
- **Hôtesse** : nouvelle (`PNJ_HOTESSE`) au lieu de `clerk` (le marchand est un homme moustachu en tablier : il devient le **serveur**, rôle qui lui va).
- **Passagère** : nouvelle (`PNJ_PASSAGERE`, croisiériste), pour le pont extérieur et le convive du restaurant (deux cartes différentes) ; `swimmer` et `naturalist` du plan ne sont pas utilisés (maillot de bain et filet à papillons à bord d'un paquebot). Le plan disait « réutilisés ».
- **Cuisinier** : demandé dans la commande du T1 mais **aucune grille ne lui donne de case** (restaurant : serveur (12, 5) et convive (4, 4) seulement ; derrière le comptoir de la cuisine (11..14, 2), c'est le mur). Prompt prêt en **conditionnel** (`PNJ_CUISINIER`) : l'ajouter demande une case dans `ss_anne_restaurant.txt` (décision de Kevin).
- **Capitaine** : une planche de **poses « malade »** en plus (dossier §6 : « penché, animation courte ») : 2 poses de dos penché (respiration) + 1 de face soulagé.
- **Marin** : celui de la série 17 (le plan prévoyait un `swimmer` habillé, écrit avant la livraison du J15).
- **Lavabo** : nouveau (1 case) ; `int_lavabo_01` fait 2 cases et la grille donne (8, 2) seul.
- **Pont de teck** : variation des planches du quai (série 17) ; texture neuve en conditionnel.
- **Icônes du Sac** : Anti-Para et Réveil (objets trouvés à bord, sans icône peinte à ce jour) ; CS01 et CT24 gardent l'icône générique des CT (comme CT11 et CT34).
- **Navire « parti »** : aucun asset ; le départ anime le nœud amarré (`animate`), puis le cache.

**D. Abandonnés** : cuisine jouable, oiseaux marins et mouettes (faune non-Pokémon, dossier §12 « souhaitable seulement ») ; faisceaux de lumière dorée peints (pont principal) et lueur bleue peinte (Arène) → lumière NE + profils + `LightGlow` ; zone du Champion à 2 rangées (→ 3, grille) ; armoires électriques comme objets fouillables (→ poubelles identiques) ; passerelle large de la vue (→ 2 cases) ; balancement du décor, ondulation (souhaitables, hors kit) ; portrait / carte de Champion peints (le modèle des J10–J13 n'en a pas).

**Conditionnels** (prompts prêts, jamais lancés par défaut, décision notée dans `etat-projet.md`) : `WORLD_GROUND_PONT_TECK_01`, `PNJ_CUISINIER` (+ attente).

**Contrôle « chaque élément des vues a un asset »** — *Pont principal* : mur crème, lambris, hublots, appliques, portes, parquet, tapis → coque ; portes latérales → coque (épaisseur des murs) ; banquettes ×3 → planche A ; comptoir et clochette → planche A ; plantes ×2 → A ; trémie d'escalier et rambarde de laiton → coque ; passerelle (sortie) → coque (seuil). *Pont extérieur* : mer → shader ; pont de teck → variation ; bastingages N, S (+ flanc et hublots), E → planche du pont ; chaises longues ×4 (2 paires) → planche ; bouées ×2 → planche ; superstructure, hublots et porte → superstructure ouest ; mouettes → abandonnées. *Arène* : mur de tableaux électriques, tubes, tuyaux → coque ; murs latéraux à grilles, bandes de danger, sol de plaques → coque ; armoires ×10 → planche (A, B alternées) ; barrière et pylônes → planche (active / coupée) ; poubelles ×15 → planche (une image) ; sortie → coque. Rien n'est implémenté parce qu'il est sur une image (règle 10) : la grille décide de la place.

## Alignement sur les outils de carte (T11, T14)

Coques : `tools/build_painted_interiors.gd` (pièces en dictionnaires) ; la coque couvre **toute la grille, murs compris** (comme `int_arene_azuria_coque` 17 × 13). Meubles : objets bloquants posés sur leurs cases, **origine au pied** (bas de la dernière rangée), ombre de contact du manifeste. Cases au format (x, y) des grilles.

| Carte | Élément | Cases | Asset |
|---|---|---|---|
| pont principal | banquettes `b` | (3..4, 3), (8..9, 3), (16..17, 3) | `int_banquette_ss_anne_01` |
| | comptoir `c` | (15..18, 9) | `int_comptoir_accueil_ss_anne_01` |
| | plantes `x` | (23, 2), (2, 10) | `int_plante` |
| | escalier `S` | (22..23, 10) | peint dans la coque |
| restaurant | tables `t` | (3..4, 3), (8..9, 3), (3..4, 6), (8..9, 6) | `int_table_restaurant_01` |
| | comptoir de cuisine `c` | (11..14, 2) | `int_comptoir_cuisine_01` (+ objet caché) |
| cabine du capitaine | bureau `N` | (2..4, 2) | `int_bureau_capitaine_01` |
| | lavabo `v` | (8, 2) | `int_lavabo_cabine_01` (capitaine en `capitaine_malade` (8, 3) ↑) |
| | carte marine `g` | (10..11, 2) | `int_table_cartes_01` |
| | couchette `L` | (11..12, 5..6) | `int_lit_cabine_01` |
| pont inférieur | caisses `k` | (19..20, 2) / (14..16, 3..4) / (5..6, 6..7) | `prop_caisses_port_01` / `int_caisses_cale_02` / `int_caisses_cale_01` (+ objet caché) |
| | escalier `S` | (2..3, 2) | peint dans la coque |
| cabines A, B, C | table `n`, lit `L`, armoire `a` | (2..3, 2), (8..9, 2..3), (10, 6) | `int_table_hublot_01`, `int_lit_cabine_01`, `int_armoire_cabine_01` |
| Arène | armoires `m` | (2..6, 5), (10..14, 5) | `int_armoire_electrique_01` / `_02` alternées (5 + 5) |
| | barrière `B` | (7..9, 5) | `int_barriere_active_01` → `int_barriere_coupee_01` (étape `animate` / `FlagGate`, T9) → rien |
| | poubelles `i` | x ∈ {2, 5, 8, 11, 14}, y ∈ {7, 9, 11} | `int_poubelle_arene_01` ×15, **sans aucune variation** |
| pont extérieur | bastingage `r` | rangée 2 (x 0..25), rangée 9, colonne 25 (y 3..8) | `relief_bastingage_01` / `_02` (graine), `_sud_01`, `_est_01`, angles `_ne_01` (25, 2), `_se_01` (25, 9) |
| | superstructure `K` + porte `D` | colonne 0 (y 3..8), porte (0, 6) | `bldg_ss_anne_superstructure_01` (porte peinte à 2,5 cases du bas) |
| | chaises longues `l` | (5..6, 4), (5..6, 7) | `prop_chaises_longues_01` |
| | bouées `u` | (14, 3), (22, 8) | `prop_bouee_01` |
| | mer `w` | rangées 0..1, 10 | `ground_eau_01` assombrie ; le flanc du bastingage sud déborde sur la rangée 10 |

**Effet de Coupe** (T7 / T10) : 4 images à ≈ 2 cases, centrées sur l'arbuste (49..50, 10), jouées en ≤ 2 s avec le Pokémon visible ; « Réduire les animations » : fondu 0,3 s (plan §6), sans effet. **Préparation** : découpe par **cellules fixes** (`boites` du manifeste), pas par taches (les feuilles détachées).

**Couloir** : image générée en bande (1 530 × 595 dans 1 536 × 1 024) ; le manifeste porte `"boite"` (T10 : `[0, 250, 1536, 770]`, la bande réellement peinte, l'ancienne boîte gardait du noir), lue par `preparer.pieces` avant l'étirement.

## Fiches

Pour chaque asset : rôle, emprise (cases de la grille), taille en pixels du jeu (1 case = 96 px), ancrage et réglages du manifeste prévus (T10). Hauteurs et réglages = **valeurs par défaut** (règle 4). Le prompt complet est dans `tools/art/prompts/serie18/<NOM>.txt`.

### Coques (opaques, 1 case = 96 px après préparation)

Toutes : murs du fond sur 2 rangées (face visible), sortie en bas, géométrie écrite par `geometrie()` depuis la grille. Image générée **plein cadre** 1 536 × 1 024 (l'étirement non uniforme reste ≤ 1,35, comme l'Arène d'Azuria), sauf le couloir (bande).

#### INT_SS_ANNE_PONT_PRINCIPAL_COQUE (vague 1) — recalée sur la vue validée
- 26 × 13 (2 496 × 1 248) ; murs latéraux de 2 colonnes ; portes `D` (5, 1), (11, 1), (20, 1), (1, 6), (24, 6) ; sortie de la passerelle (12..13, 11) ; trémie d'escalier descendant (22..23, 10) peinte avec sa rambarde de laiton ; grand tapis bordeaux peint au sol (colonnes 7..18, rangées 4..8, comme la vue). **Jointes** : `REF_PP_SALLE`, `REF_PP_MUR`, coques du Centre et de la maison de Léo, tranche du navire (palette).

#### INT_ARENE_CARMIN_COQUE (vague 1) — recalée sur la vue validée
- 17 × 15 (1 632 × 1 440) ; murs latéraux de 2 colonnes ; sortie (7..9, 13) ; mur du fond de tableaux électriques ; sol de plaques de métal ; **zone du Champion de 3 rangées** (2..4) ; rangée 5 laissée en sol (armoires et barrière posées à part). **Jointes** : `REF_AC_SALLE`, `REF_AC_MUR`, `REF_AC_SOL`, coque de l'Arène d'Azuria, façade de l'Arène de Carmin.

#### INT_SS_ANNE_COULOIR_COQUE (vague 2)
- 18 × 7 (1 728 × 672) ; bande 1 530 × 595 px (1 case = 85 px) ; porte du capitaine (15, 1) plus imposante ; sortie d'une case (2, 5) ; moquette bleu marine à liseré doré. Le déclencheur `T` (7, 2..4) n'a pas de visuel. **Jointes** : coque du pont principal, `REF_PP_MUR`, `REF_PP_PORTE`.

#### INT_SS_ANNE_CABINE_CAPITAINE_COQUE (vague 2)
- 14 × 10 (1 344 × 960) ; sortie (6..7, 8) ; lambris pleine hauteur, grand hublot double, horloge sans chiffres, baromètre ; moquette bleu marine. **Jointes** : coque du pont principal, `REF_PP_MUR`, coque de Léo.

#### INT_SS_ANNE_RESTAURANT_COQUE (vague 2)
- 18 × 11 (1 728 × 1 056) ; porte dans le mur de droite à la rangée 6 (warp (16, 6)) ; **passe-plat** peint dans le mur du fond au-dessus de (11..14, 2) (cuisine entrevue, non jouable) ; moquette bordeaux à motifs. **Jointes** : coque du pont principal, `REF_PP_MUR`, `REF_PP_TAPIS`.

#### INT_SS_ANNE_PONT_INFERIEUR_COQUE (vague 2)
- 22 × 11 (2 112 × 1 056) ; porte de tôle (10, 1) vers la cabine B ; **escalier montant** peint contre le mur du fond (2..3, 2) ; tôle vert d'eau rivetée, tuyaux, planches brutes. **Jointes** : coque du pont principal, coque du labo.

#### INT_SS_ANNE_CABINE_COQUE (vague 2) — cabines A, B, C
- 12 × 9 (1 152 × 864) ; sortie (5..6, 7) ; papier peint crème rayé bleu ciel, deux hublots (au-dessus de la table et du lit), moquette bleu marine. **Jointes** : coque du pont principal, `REF_PP_MUR`, coque de Léo.

### Mobilier et objets

#### INT_SS_ANNE_PLANCHE_A → 6 meubles (vague 1)
- Planche 3 × 2 de 512, **1 case = 120 px** (le comptoir de 4 cases tient dans 512), largeurs `[2, 4, 2, 4, 2, 1]`, contact 0,2 : `int_banquette_ss_anne_01` (2 × 1, velours bordeaux), `int_comptoir_accueil_ss_anne_01` (4 × 1, acajou et laiton, clochette, registre), `int_table_restaurant_01` (2 × 1, nappe blanche, 2 chaises), `int_comptoir_cuisine_01` (4 × 1, inox et acajou), `int_lit_cabine_01` (2 × 2, couvre-lit bleu marine, oreillers unis), `int_armoire_cabine_01` (1 × ≈ 1,8). **Jointes** : `REF_PP_BANQUETTE`, `REF_PP_COMPTOIR`, long comptoir, canapé, lit.

#### INT_SS_ANNE_PLANCHE_B → 6 meubles (vague 2, joint la planche A)
- Même gabarit, largeurs `[2, 3, 1, 2, 2, 3]` : `int_table_hublot_01`, `int_bureau_capitaine_01` (longue-vue, compas, livre de bord, lampe verte), `int_lavabo_cabine_01` (1 case, miroir rond), `int_table_cartes_01` (carte marine **sans lettres**), `int_caisses_cale_01` (2 × 2), `int_caisses_cale_02` (3 × 2). **Jointes** : planche A, lavabo, caisses.

#### INT_ARENE_CARMIN_PLANCHE → 5 éléments (vague 1)
- Planche 3 × 2 de 512, 1 case = 150 px, largeurs `[0,75, 1, 1, 3, 3]`, contact 0,15 : `int_poubelle_arene_01` (**une seule image pour les 15**, aucun détail distinctif, G-8 / dossier §9 « aucun indice »), `int_armoire_electrique_01`, `_02` (1 × ≈ 1,5, bords droits pour la rangée), `int_barriere_active_01` (3 × ≈ 1,5 : pylônes + champ translucide), `int_barriere_coupee_01` (mêmes pylônes éteints, sans champ). Le champ peut **pulser** en jeu (modulate) ; repli si l'alpha partiel sort mal : champ dessiné par un shader au T14, pylônes seuls. **Jointes** : `REF_AC_POUBELLE`, `REF_AC_ARMOIRES`, `REF_AC_BARRIERE`, machines du labo, façade de l'Arène de Carmin.

#### WORLD_RELIEF_PONT_EXTERIEUR_PLANCHE → 8 éléments (vague 1)
- Planche **4 × 2** de 384 × 512, 1 case = 180 px, largeurs `[2, 2, 2, 0,35, 0,35, 0,35, 2, 1]`, contact 0 (bastingages, couche du sol) : `relief_bastingage_01`, `_02` (N, 2 × ≈ 0,9), `relief_bastingage_sud_01` (2 × ≈ 1,6, avec le flanc blanc, un hublot et le liseré bleu marine), `relief_bastingage_est_01` (0,35 × 2), `relief_bastingage_angle_ne_01`, `_se_01`, `prop_chaises_longues_01` (2 × ≈ 1,2), `prop_bouee_01` (1). Aucune mer, aucune écume peintes. **Jointes** : 5 recadrages `REF_PE_*`, tranche du navire, planches du quai, caisses.

#### WORLD_BLDG_SS_ANNE_SUPERSTRUCTURE_OUEST → `bldg_ss_anne_superstructure_01` (vague 1)
- Colonne 0, rangées 3..8 du pont extérieur (+ débord jusqu'au bastingage) ; 1,3 × ≈ 7,5 cases (≈ 125 × 720 px) ; image **portrait** 1 024 × 1 536 ; toit gris clair, paroi blanche montrée de biais côté pont (exception assumée de la vue : la porte `D` (0, 6) regarde l'est), 2 hublots, porte de bois à hublot ; `ombre` non, `contact` aucun. **Jointes** : `REF_PE_SUPERSTRUCTURE`, tranche du navire.

### Personnages (marche puis attente)

Modèle commun des séries 10–17 : marche 4 × 4 (1024 × 1536, héros validé joint, « ne ressemble pas au héros »), attente 4 × 1 (1536 × 1024) calée sur la marche jointe. **128 px**. Préparation (T10) : sections `personnages` / `attentes` ; looks **en fin** de `build_character_frames.gd`.

| Fiche | Tenue (défaut, règle 4) | Attente | Jointes |
|---|---|---|---|
| `PNJ_CAPITAINE` → `capitaine` (`captain`) | ≈ 60 ans, barbe blanche courte, teint un peu pâle, vareuse bleu marine à double boutonnage doré, galons, casquette blanche à **ancre dorée** | mains dans le dos | marin, vieil homme |
| `CAPITAINE_MALADE` → `capitaine_malade` | mêmes : de dos **penché** (2 poses, respiration), de face soulagé (main sur le ventre) | — | marche du capitaine |
| `PNJ_MAJOR_BOB` → `major_bob` (`surge`) | ≈ 35 ans, grand et carré, cheveux blonds en brosse, débardeur vert olive, treillis kaki, rangers, plaque sans inscription, **éclair** cousu à l'épaule | bras croisés | Pierre, guide |
| `PNJ_GENTLEMAN` → `gentleman` (`gentleman`) | ≈ 55 ans, moustache grise, chapeau melon, trois-pièces anthracite, lavallière bleu nuit, canne à pommeau d'argent | mains sur la canne | président du Fan Club, vieil homme |
| `PNJ_ROCKEUR` → `rockeur` (`rocker`) | ≈ 25 ans, banane noire, petites lunettes noires, cuir noir à petits éclairs, t-shirt rouge, guitare rouge **sans logo** | main sur la guitare | guide |
| `PNJ_HOTESSE` → `hotesse` (`hostess`) | ≈ 30 ans, chignon brun, tailleur bleu marine, foulard rouge et blanc, calot (uniforme de la compagnie du marin) | mains jointes | marin |
| `PNJ_PASSAGERE` → `passagere` (`passenger_f`) | ≈ 40 ans, grand chapeau de paille à ruban bleu ciel, robe d'été jaune pâle, sac de paille | main au chapeau | — |
| `PNJ_CUISINIER` [conditionnel] | toque, veste de chef blanche, foulard rouge, pantalon pied-de-poule, louche | louche levée | marchand |

### Effet

#### FX_COUPE_PLANCHE → `fx_coupe_01..04` (vague 1)
- Une ligne de 4 cellules 384 × 512 (moitié haute de l'image), effet ≈ 300 px (≈ 2 cases en jeu) : demi-trait, arc complet blanc bordé de bleu ciel, second trait en X + feuilles, dissipation. Rendu peint, net, **sans halo ni étincelle électrique**. Préparation en `assets/world/fx/` par cellules fixes.

### Icônes du Sac

#### UI_OBJETS_J16_PLANCHE → `assets/ui/items/paralyze_heal.webp`, `awakening.webp` (vague 1)
- Planche 1536 × 1024 à **4 colonnes de 384** : Anti-Para (vaporisateur de l'Antidote, corps jaune citron), Réveil (corps bleu ciel), colonnes 3–4 vides. Chaîne `preparer_menu.py` : T10 ajoute `("UI_OBJETS_J16_PLANCHE_r1.png", ["paralyze_heal", "awakening"])` **en fin** de `PLANCHES_OBJETS_SUIVANTES`. **Jointes** : `MENU_OBJETS_PLANCHE_r1`, `assets/ui/items/antidote.webp`.

### Décors de combat (chaîne CB.3, `decors.json` au T10)

Points A (67 %, 58 %) et B (31 %, 97 %), zones calmes, 2,17 : 1 ; les décors gardent l'**ambiance** (comme ceux des J12–J15). Jointes : `combat-v1.webp`, `combat-decors-planche-v1.webp`, vue validée de la salle.
- `COMBAT_DECOR_SS_ANNE_SALON_r1` → `ss_anne_salon` : mur crème et lambris, hublots, appliques allumées, parquet et tapis bordeaux ; **toutes les cartes intérieures** du navire (pont principal, restaurant, pont inférieur, cabines, couloir : rival n° 4) [D].
- `COMBAT_DECOR_SS_ANNE_PONT_r1` → `ss_anne_pont` : pont de teck, bastingage, mer scintillante, golden hour ; pont extérieur.
- `COMBAT_DECOR_GYM_CARMIN_r1` → `vermilion_gym_salle` : mur technique, tubes bleu froid, plaques de métal ; Arène (Dresseurs et Major Bob).

### Conditionnels (prompts prêts, non lancés)

- `WORLD_GROUND_PONT_TECK_01` : pont de teck neuf si les planches du quai éclaircies ne suffisent pas (capture du T11).
- `PNJ_CUISINIER` (+ attente) : seulement si Kevin lui donne une case dans la grille du restaurant.

## Commandes du T2

**Sur le Mac, depuis la racine de la copie** (trois générations à la fois, vague 1 puis 2 ; une image déjà présente n'est pas refaite ; les conditionnels ne partent pas) :

```bash
python3 tools/art/serie18.py --prompts     # sans effet si les prompts versionnés sont à jour
python3 tools/art/serie18.py --refs && python3 tools/art/serie18.py --ancres
python3 tools/art/serie18.py               # 17 images (vague 1) puis 13 (vague 2), Codex, aucune API payante
python3 tools/art/serie18.py --contact     # build/captures/jalon16_assets/serie18_contact.png → Kevin
```

**Image par image** : `python3 tools/art/serie18.py --commandes`. Une correction = une entrée de `CORRECTIONS` (`(identifiant, 2)` → description corrigée ; planches et coques), `--prompts`, relancer la commande `_r2`. **Pas** de `manifeste.json`, `preparer.py`, `preparer_menu.py` ni scène au T2 (T10 : `serie18.py --manifeste`, puis la découpe du couloir dans `preparer.pieces`).

## Journal de la série 18

- **T1 (2026-10-16, branche `j16-t1-kit`)** : liste du kit (**30 images** nouvelles + 3 conditionnels), fiches, 33 prompts versionnés (géométrie des coques tirée des grilles), commandes, planche de contrôle `build/art/J16_KIT_v1.png` relue (réutilisés de la série 17 lus sur `main`, variations, coques à l'échelle avec leur plan, pont extérieur, mobilier, Arène, personnages, effet, Sac, combat, conditionnels, abandonnés). Numéro 18 provisoire (revérifié au push). Grilles non modifiées. Aucune image générée.
- **T10 (2026-10-16, branche `j16-t10-integration`)** : planche validée par Kevin (tapis du pont principal = coque `_r2`, superstructure gardée). Préparées : 7 coques (retouches : sorties des cabines et de la cabine du capitaine élargies à 2 cases, escalier du pont inférieur ramené à 2 cases, portes de la cabine B et du capitaine recentrées, bande du couloir recadrée), 12 meubles, 5 éléments de l'Arène (barrières à 3,5 cases), 8 éléments du pont extérieur (paire de chaises longues découpée par boîte), superstructure étirée à 1,3 × 6,8 cases, pont de teck (`ground_pont_teck_01`, planches du quai × 1,15), 4 images de Coupe (cellules fixes, une échelle), 6 personnages + attentes, capitaine malade (planche d'attente à 5 colonnes), icônes Anti-Para et Réveil, 3 décors de combat (chaîne CB.3, 6 tuiles repeintes par Codex). Halos retirés par `nettoyer` sur toutes les planches.
