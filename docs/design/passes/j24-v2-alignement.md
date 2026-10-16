# J24 — Les Îles Écume et Artikodin : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-16. Conception seulement : aucune ligne de code. V2 reproduite dans
> `j24-v2-chatgpt.md`. Relu contre `vision.md`, la roadmap, les dossiers et passes du J16 au J22
> (branches `jalon-16` à `jalon-21`, `docs/dossier-25-j22`), le brouillon de V2 du J23 (non commité,
> worktree `j23-conception`) et le code de `origin/main` (`440f9b17`, J15 terminé, sauvegarde v7).
>
> **Faits Rouge/Bleu** : désassemblage `pret/pokered` (`af51989`). Les grilles des étages sont
> **décodées** des `.blk` et de la collision réelle (script, pas à l'œil) ; les **chemins et
> solutions de poussée** viennent d'un petit solveur et **n'ont pas été vérifiés sur émulateur**.
> Origine des règles : **RB** Rouge/Bleu · **G+** génération ultérieure · **K26** invention de
> Kanto 2026.
>
> Les 7 décisions de la V2 ne sont pas rouvertes. Mes arbitrages sont numérotés **P-1 à P-22**
> (§8) : M est pris par le J22, N est laissé au J23, O est sauté (trop proche de 0). Réponds par
> numéro ; j'écris ensuite le dossier 27.

## 0. État réel du dépôt

| Point | Constat |
|---|---|
| `main` | `origin/main` = `440f9b17`, **J15 terminé**, sauvegarde **v7**. Le `main` local du Mac est en retard (J14, v6) : à mettre à jour. |
| J16 à J21 | Chacun sur sa branche (`jalon-16` … `jalon-21`), **aucun fusionné**, et ils ne se contiennent pas entre eux. Coupe (J16) et Flash (J17) vivent sur deux branches séparées. |
| J20 (Erika) | Équipe d'Erika en données (`jalon-20:data/trainers/celadon_gym.json`), grilles de Céladopole ; **ni carte, ni Arène jouable, ni remise du Badge Prisme**. |
| J22 | Recadré le 2026-10-16 : « Les deux chemins vers Parmanie » (Routes 12–18, **Parmanie**, pêche, Vélo). Passe `j22-v2-alignement.md` (M-1 à M-24) **à trancher**, pas de dossier. |
| J23 | **Rien de commité.** Brouillon de V2 (Safari, CS03 Surf, CS04 Force, Koga) dans un worktree, fichier non suivi. Son découpage prévoit **« 23D Surf et Force (monde et combat) »**. |
| Numéros | 25 = J22, 26 = J23 (prévu) → **27 = J24**, branche `docs/dossier-27-j24` (recalée sur `origin/main`). |

**Conséquence** : le J24 repose sur **sept jalons non fusionnés** (J16 à J23), dont deux (J22, J23)
n'ont même pas de dossier. Comme aux J19 à J21, le dossier 27 écrira un **contrat d'entrée** (§3).
Le code du J24 ne peut commencer qu'après la fusion du J23 ; mais les moteurs de Surf et de Force,
les grilles, les données et l'art peuvent avancer avant, sur des cartes d'essai (§9).

## 1. Les 7 décisions de la V2

| # | V2 | Avis |
|---|---|---|
| 1 | Routes 19–20, Îles Écume, accès maritime à Cramois'Île | Oui. **Mais dans RB, la Route 20 est coupée en deux mers** : par la mer, on ne va de Parmanie à Cramois'Île **qu'en traversant les Îles Écume** (§2.2) → **P-6**. |
| 2 | Donjon complet, courants et rochers | Oui. Les 5 étages, 2 entrées, 8 trous, 14 rochers. **Dans RB, les courants ne sont pas des cases** : ce sont des scripts qui coupent un passage tant que des drapeaux ne sont pas posés → **P-10**. |
| 3 | Artikodin unique et capturable | Oui. Ses règles de fuite et de défaite ne sont **pas** dans les 7 décisions (elles sont « recommandées » au §4 de la V2), et elles contredisent la règle de Ronflex retenue au J21 → **P-15**. |
| 4 | Surf : navigation libre, rencontres, transitions | Oui. **Le J23 prévoit aussi de construire Surf et Force** (lot 23D) : il faut un seul propriétaire → **P-2**. Et toute l'eau déjà peinte de Kanto deviendrait surfable → **P-3**. |
| 5 | Rochers persistants, anti-blocage | Oui. La V2 dit à la fois « positions sauvegardées » et « récupération locale » ; je propose une lecture qui tient les deux **sans changer de version de sauvegarde** → **P-9**. |
| 6 | Cramois'Île : ville et bâtiments principaux ouverts ; Manoir et Arène plus tard | Oui. À préciser : le Labo (fossiles, CT35, échanges) → **P-18**, **P-19** ; la fermeture du Manoir → **P-20**. |
| 7 | Fin libre | Oui. Aucun événement à l'arrivée, aucun objectif imposé → **P-21**. |

## 2. Ce que fait Rouge/Bleu (vérifié)

### 2.1 Routes 19, 20, 21 (`data/maps/headers`, `objects`, `constants/map_constants.asm`)

| | Route 19 | Route 20 | Route 21 |
|---|---|---|---|
| Taille (cases RB) | 20 × 54 | 100 × 18 | 20 × 90 |
| Raccords | nord : Parmanie (colonne 0 = colonne 10 de Parmanie) · ouest : Route 20 | ouest : Cramois'Île · est : Route 19 (lignes 0–17 = lignes 36–53 de la R19) | nord : Bourg Palette · sud : Cramois'Île |
| Nature | **plage** au nord (y 0–9, 2 Dresseurs à pied), puis **mer** | **mer**, une île (les Îles Écume, x 46–61) et un îlot (l'Ornithologue) | mer, **une prairie d'herbes hautes accessible seulement par l'eau** (36 cases), deux îlots de Pêcheurs |
| Entrées | — | (48,5) → 1F **ouest** ; (58,9) → 1F **est** | — |
| Panneaux | « Route marine 19 : Parmanie – Îles Écume » | « Îles Écume » ×2 | — |
| Dresseurs | 10 (8 en mer) | 10 (9 en mer, 1 sur l'îlot) | 9 (5 en mer, 4 Pêcheurs) |
| Objets | aucun | aucun | aucun |

**Rencontres** (`data/wild/maps/SeaRoutes.asm`, `Route21.asm`, versions identiques) :
- **Routes 19 et 20 : en Surf, Tentacool seulement**, taux 5 (bas), niveaux 5 à 40 selon le
  créneau. Pas d'herbe.
- **Route 21** : même table d'eau ; herbe (taux 25) : Rattata, Rattatac, Roucool, Roucoups,
  Saquedeneu, niveaux 21 à 32.
- **Pêche** : Canne → Magicarpe N5 ; Super Canne → Poissirène, Ptitard N10 ; **Méga Canne** (Routes
  19–21, Cramois'Île, Îles Écume B3F/B4F) → Stari, Hypotrempe, Kokiyas, Poissirène N15.

**Dresseurs** (`data/trainers/parties.asm`, tous les Pokémon d'une équipe au même niveau) :

| Route | Équipes (niveau) |
|---|---|
| 19 | Tentacool + Kokiyas (30) · Poissirène, Hypotrempe, Stari (29) · Ptitard, Têtarte (30) · Hypotrempe, Tentacool ×2, Poissirène (27) · Poissirène, Kokiyas, Poissoroy (29) · Hypotrempe ×2 (30) · Ptitard, Poissirène, Poissoroy, Poissirène, Ptitard (27) · Poissirène, Poissoroy (30) · Tentacool ×2, Stari, Hypotrempe, Tentacruel (27) · Stari ×3 (29) |
| 20 | Kokiyas, Crustabri (31) · Hypocéan, Hypotrempe, Hypocéan (30) · Poissoroy (35, poche fermée) · Tentacool, Hypotrempe, Otaria (30) · Stari (35) · Hypotrempe ×3, Hypocéan (28) · **Ornithologue** : Rapasdepic ×2, Roucoups (30) · Kokiyas ×2, Crustabri (30) · Poissirène, Poissoroy (31) · Ptitard, Poissoroy (31) |
| 21 | Pêcheurs (vue 0, il faut leur parler) : Poissoroy ×3 + Poissirène (28) · Magicarpe ×6 (27) · Kokiyas, Crustabri (31) · Poissoroy, Poissirène (33) — Nageurs : Hypocéan, Tentacruel (33) · Tentacool ×2, Tentacruel (31) · Staross (37) · Stari, Carabaffe (33) · Têtarte, Tentacool, Hypocéan (32) |

### 2.2 La Route 20 est coupée en deux

Décodage de la collision : **la mer est** (côté Route 19) ne touche que l'entrée **ouest** (48,5),
qui donne sur la partie du 1F d'où tout le donjon est accessible. **La mer ouest** (côté
Cramois'Île) ne touche qu'une petite poche et l'entrée **est** (58,9), qui ne mène qu'à une échelle.
Une poche fermée (le Nageur N35) n'est accessible que par la rive ouest de l'île.

**Donc, dans RB, aller de Parmanie à Cramois'Île par la mer oblige à traverser les Îles Écume**,
et ce trajet ne demande **que Surf** (pas Force) : entrée ouest → 1F → B1F → B2F → B3F → l'eau du
B3F, dont **le courant emporte le joueur jusqu'au B4F** (mer est) → escaliers → remontée par la
partie est → 1F est → Route 20 ouest → Cramois'Île. *(Déduit du solveur, à vérifier sur émulateur
en 24.0.)* L'autre chemin vers Cramois'Île est Bourg Palette → Route 21.

### 2.3 Les Îles Écume (`scripts/SeafoamIslands*.asm`, `data/maps/objects`, `toggleable_objects.asm`)

- **5 étages de 30 × 18 cases RB** : 1F, B1F, B2F, B3F, B4F. Deux niveaux de sol par étage (bas et
  haut) reliés par des escaliers ; échelles entre étages.
- **Objets cachés** : B2F Pépite, B3F Max Élixir, B4F Hyper Ball. Rien au sol.
- **Rochers** : 2 au 1F, 4 au B3F (plus 6 qui « apparaissent » quand un rocher tombe d'au-dessus).
- **Trous** : 2 par étage du 1F au B3F. Un rocher poussé dans un trou **disparaît** et un rocher
  **apparaît à un point fixe** de l'étage du dessous (drapeau `EVENT_SEAFOAMn_BOULDERm_DOWN_HOLE`).
  Le joueur peut aussi sauter dans un trou : il atterrit à côté. Au B2F et au B3F, il atterrit
  **dans l'eau, en Surf forcé**.
- **Courants** (scripts, pas de cases) :
  - **B3F** : tant que les 2 rochers du B2F ne sont pas tombés, entrer dans l'eau (ou y tomber)
    **emporte le joueur jusqu'au B4F**. Les deux rochers tombés se posent dans l'eau et coupent ce
    courant.
  - **B4F** : tant que les 2 rochers du B3F ne sont pas tombés, tomber du B3F emporte le joueur sur
    la plateforme centrale, et **l'eau de la salle d'Artikodin est interdite au Surf** (« Le courant
    est beaucoup trop fort ! »). Les deux rochers tombés coupent ce courant.
  - Panneaux du B4F : « Les rochers peuvent changer le cours de l'eau ! » ; « DANGER, courant
    rapide ! ».
- **Pour Artikodin, seuls les 2 rochers du B3F sont indispensables** : la zone des trous du B3F
  s'atteint à pied. La chaîne 1F → B1F → B2F ne sert qu'à couper le courant du B3F. *(Solveur.)*
- **Sortir et revenir** : les rochers non tombés **reprennent leur place d'origine** à chaque
  changement de carte ; les chutes sont des drapeaux permanents ; les courants restent coupés.
  Bizarrerie : en revenant sur la Route 20, RB **remet les rochers du haut à leur place** (puzzle
  visuellement remis à zéro, courants toujours coupés).
- **Bizarrerie de RB à ne pas reproduire** : au B3F, le rocher retiré dépend du **numéro du trou**,
  pas du rocher poussé ; pousser certains rochers peut laisser un rocher affiché sur un trou.
- **Blocage possible dans RB** : atteindre la salle d'Artikodin en tombant puis en surfant de force
  sans pouvoir surfer soi-même ; seules issues : Corde Sortie, Tunnel, Téléport.

Rencontres : **sur le sol de tous les étages** (taux 10 à 15), **jamais en Surf** (taux d'eau 0) ;
Méga Canne au B3F et au B4F. Rouge et Bleu diffèrent :

| Étage | Rouge | Bleu |
|---|---|---|
| 1F | Otaria, Ramoloss, Kokiyas, Hypotrempe, Nosferapti, Nosferalto, Psykokwak, **Akwakwak 38** | Otaria, Psykokwak, Stari, Krabby, Nosferapti, Nosferalto, Ramoloss, **Flagadoss 38** |
| B1F | Stari, Hypotrempe, Kokiyas, Ramoloss, Otaria, **Lamantine 38, Hypocéan 37** | Kokiyas, Krabby, Stari, Psykokwak, Otaria, **Lamantine 38, Krabboss 37** |
| B2F | Otaria, Ramoloss, Hypotrempe, Stari, Kokiyas, Nosferalto, **Flagadoss 37** | Otaria, Psykokwak, Krabby, Kokiyas, Stari, Nosferalto, **Akwakwak 37** |
| B3F | Ramoloss, Otaria, Hypotrempe, Kokiyas, **Hypocéan 39, Lamantine 37** | Psykokwak, Otaria, Krabby, Stari, **Krabboss 39, Lamantine 37** |
| B4F | Hypotrempe, Kokiyas, Ramoloss, Otaria, **Flagadoss 39**, Nosferalto | Krabby, Stari, Psykokwak, Otaria, **Akwakwak 39**, Nosferalto |

Niveaux courants : 28 à 33.

### 2.4 Artikodin (`objects/SeafoamIslandsB4F.asm`, `base_stats/articuno.asm`, `home/trainers.asm`)

| Aspect | RB |
|---|---|
| Lieu | B4F (6,1), salle au nord-ouest, accessible **en Surf** par la mer ouest, après les 2 rochers du B3F |
| Niveau, types | **50**, Glace/Vol · PV 90, Att 85, Déf 100, Vit 85, Spé 125 · croissance lente |
| Capacités au N50 | **Picpic, Laser Glace seulement** (Blizzard s'apprend au N51, Hâte au N55, Brume au N60) |
| Taux de capture | **3** (le plus bas du jeu) |
| Déclenchement | **Seulement en lui parlant** ; « Gyaoo ! », cri, combat sauvage capturable |
| Victoire, **fuite**, capture | Drapeau `EVENT_BEAT_ARTICUNO`, Artikodin **disparaît pour toujours** |
| Défaite du joueur | Aucun drapeau, **Artikodin reste** |

### 2.5 Surf et Force (`start_sub_menus.asm`, `item_effects.asm`, `push_boulder.asm`, `overworld.asm`)

**Surf.**
- Il faut le **Badge Âme**, plus la capacité, choisie dans le menu Pokémon.
- On l'utilise face à l'eau ou à une rive : le joueur avance d'une case sur l'eau.
- Il **descend automatiquement** en avançant sur une case de terre.
- Un warp ou un trou le remet à pied, sauf sur les cases de « Surf forcé ».
- L'état est sauvegardé ; au chargement, le Surf est gardé si la carte a de l'eau.
- Rencontres sur l'eau : table d'eau. Un bug utilise la table d'herbe sur certaines rives, à ne pas
  reproduire.

**Force.**
- Il faut le **Badge Prisme**.
- Elle s'active par le menu Pokémon (« X peut déplacer les rochers ») et dure **jusqu'au prochain
  changement de carte** ; un combat ne l'annule pas.
- Pour pousser un rocher, il faut **pousser deux fois** en gardant la direction.
- La case d'arrivée doit être libre, sans escalier ni différence de niveau. Un rocher ne va
  **jamais dans l'eau** ; il tombe dans un trou.

### 2.6 Cramois'Île (`objects/CinnabarIsland.asm`, `scripts/Cinnabar*.asm`, `marts.asm`, `trades.asm`)

- **20 × 18 cases RB**. Raccords : nord → Route 21, est → Route 20. Pas de maisons d'habitants.
- **Bâtiments** : Centre, Boutique, Labo (hall + 3 salles), **Manoir**, **Arène**.
  - **Arène fermée** sans la Clé Secrète (trouvée dans le Manoir) : « La porte est fermée… », recul
    d'une case.
- **Boutique** : Hyper Ball, Super Ball, Hyper Potion, Max Repousse, Corde Sortie, Total Soin,
  Rappel.
- **Labo** :
  - photo du fondateur, le Dr Fuji ;
  - salle R&D : **CT35 Métronome** donnée une fois ; un PC où l'on lit un courriel sur les trois
    oiseaux légendaires ;
  - salle d'essais : **résurrection des fossiles** (Fossile Dôme → Kabuto, Nautile → Amonita,
    Vieil Ambre → Ptéra, niveau 30, après être ressorti sur la carte de la ville) ;
  - **3 échanges** : Raichu ↔ Électrode, Mimitoss ↔ Saquedeneu, Ponyta ↔ Otaria.
- **PNJ** :
  - Centre : on peut annuler une évolution ; les Pokémon échangés grandissent vite ;
  - ville : Auguste vit ici depuis des décennies ; des scientifiques travaillent dans le bâtiment
    incendié.

## 3. Contrat d'entrée (J16 → J23)

| Le J24 suppose | Identifiant réel | État aujourd'hui | Jalon | Si c'est faux |
|---|---|---|---|---|
| Sauvegarde v7, drapeaux libres | `SaveSystem.VERSION = 7`, `StoryFlags` (ensemble de chaînes) | Implémenté | J15, `main` | — |
| Modèle hybride des CS | `FieldMoves`, `data/world/field_moves.json`, `PokemonData.can_learn_hm` | Implémenté et testé (Coupe, Flash) | J16 + J17, **non fusionnés, fichiers en conflit** | Fusion J16 + J17 avant tout code de Surf ou Force |
| Étape de scène `field_move` | `CutsceneStep.Kind.FIELD_MOVE` | Seulement sur `jalon-16` | J16 | Surf et Force s'appuient dessus |
| CS03 Surf | objet `hm03`, capacité `surf` | **Absent** (seul le numéro existe dans `tm_compatibility.json`) | J23 | Bloquant |
| CS04 Force | objet `hm04`, capacité `strength` | **Absent** | J23 | Bloquant |
| Badge Prisme | `badge_rainbow` (drapeau) | Entrée de `data/badges.json` ; équipe d'Erika en données ; **aucune remise jouable** | J20 | Bloquant pour Force |
| Badge Âme | `badge_soul` | Entrée de `badges.json` seulement ; Koga n'existe nulle part | J23 | Bloquant pour Surf |
| Parmanie, sortie sud | `fuchsia_city` (`zones.json`, sans carte) | **Absent** | J22 | Bloquant : la Route 19 part de là |
| Rencontre statique (combat sauvage lancé par une scène) | étape `wild_battle` (plan J21 §2.10) | **Non codée** | J21 | Bloquant pour Artikodin |
| Pêche, terrain `water_rod` | M-8 à M-11 | Documenté au J22 | J22 | Pas de pêche au J24 (non bloquant) |
| État « monté » du joueur | Vélo, M-6 / M-7 | Documenté au J22 | J22 | Surf réutilise le même modèle (compagnon rentré) |
| Glissade forcée | `SpinSlide`, `SpinTileRules` (`safe_cell`) | Implémenté et testé | J20, non fusionné | Base possible des courants |
| Don ou unicité d'un Pokémon | `PokemonGift` (équipe pleine → Stockage) | Implémenté et testé | J20 | Fossiles |
| Capture, équipe pleine | `BattleDirector._finish_capture` → `PokemonStorage` | Implémenté | `main` | — |
| Pas de sauvegarde en combat | `Boot.is_stable()` | Implémenté (voulu) | J15 | — |
| Eau | `GridWorld._FLAG_WATER`, `GroundMask.Kind.WATER` | **Obstacle seulement** | `main` | Tout le Surf est à faire |

**Points demandés par la V2 :**
1. **Badge Prisme** : il est prévu mais **pas obtenable** aujourd'hui. Le J24 exige que la remise
   (Arène d'Erika, étape `BADGE`) soit jouable et fusionnée.
2. **Route 21** : aucune incohérence possible tant que l'eau de Bourg Palette reste un obstacle.
   Mais dès que le Surf existe, **la côte sud de Bourg Palette, qui est déjà de l'eau peinte**
   (`tools/build_pallet_town.gd`, lignes 32–33, sans warp), devient un départ possible → **P-4**.
3. **Artikodin sans duplication** : la capture vers l'équipe ou le Stockage existe. Il n'y a **pas
   de sauvegarde pendant un combat**, donc une fermeture de l'application ramène avant l'interaction,
   avec Artikodin présent et rien de capturé. Le risque est ailleurs : la fenêtre entre la fin du
   combat et la sauvegarde suivante → règle au §6.

## 4. Coûts techniques (rien de tout cela n'existe)

| Système | Coût | Remarque |
|---|---|---|
| **Mode Surf** du joueur | Élevé | Nouvel état de déplacement ; collision inversée (eau franchissable, terre = descente) ; monture et compagnon ; transitions de carte en Surf ; reprise d'une partie |
| **Eau surfable par carte** | Moyen | Distinguer l'eau surfable de l'eau décor dans les grilles et le `GroundMask` → P-3 |
| **Rencontres sur l'eau** | Faible | Nouveau terrain `water` dans `EncounterTable.TERRAINS` |
| **Dresseurs nageurs** | Moyen | PNJ sur l'eau, ligne de vue au-dessus de l'eau, joueur en Surf pendant l'approche |
| **Rochers de Force** | Élevé | Objet poussable : collision, animation de poussée, refus (eau, escalier, niveau, PNJ), chute dans un trou |
| **Trous** | Moyen | Chute du joueur (warp vers un point fixe) et chute de rocher (drapeau) |
| **Courants** | Moyen | Glissade forcée vers une case ou un warp, désactivée par des drapeaux |
| **États dérivés des drapeaux** | Faible | Chaque étage calcule ses rochers et ses courants à partir des 8 drapeaux de chute |
| **Artikodin** | Faible | Si l'étape `wild_battle` du J21 existe |
| **Cramois'Île** | Moyen | Ville, Centre, Boutique (gabarits existants), Labo, résurrection des fossiles |
| **Route 21** | Moyen | Si retenue (P-4) : carte d'eau, prairie, 9 Dresseurs |

## 5. Art et assets

| Asset | Existe ? |
|---|---|
| Vues générales peintes + plans : Routes 19, 20 (21), Cramois'Île, 5 étages des Îles Écume | Non (série à produire en 24.0, même procédé que les jalons précédents) |
| Kit de grotte glacée (sol bas, sol haut, escaliers, échelles, trous, eau de grotte, glace décor) | Non ; Mont Sélénite et Grotte Sombre en sont la base |
| **Monture de Surf** générique peinte, 4 directions, ondulation à l'arrêt | Non |
| **Joueur en Surf** (buste, 4 directions) | Non |
| **Nageur / Nageuse** (tête et épaules dans l'eau), Topdresseur de plage, Ornithologue, Pêcheur (existe ?) | Non, sauf Pêcheur si le J21 l'a produit |
| **Rocher de Force** (poussable, distinct des rochers décor) + rocher « tombé dans l'eau » | Non |
| **Artikodin dans le monde** (posé, ailes repliées, souffle froid léger) | Non (artwork officiel 144 seulement) |
| Fonds de combat : **mer ouverte** (CB.3), **grotte glacée** | Non |
| Dos de combat (repeints à partir du rendu X/Y) | Voir §7 ; la plupart manquent |
| Intérieurs : Labo de Cramois'Île (hall + salles) | Non ; Centre et Boutique : gabarits existants |
| Scientifique, Infirmière (existe), vendeur (existe) | Scientifique : à vérifier |

## 6. Règles proposées (résumé ; le détail ira au dossier)

### 6.1 Surf (RB, sauf mention)

| Cas | Règle |
|---|---|
| Conditions | `hm03` dans le Sac + `badge_soul` + un Pokémon **de l'équipe** compatible (règle `FieldMoves` : le compagnon est préféré, un Pokémon K.O. compte) |
| Monter | Face à une eau surfable, le bouton contextuel propose **SURFER** (K26, P-8). Un toucher suffit. Courte animation : le compagnon rentre dans sa Ball, la monture apparaît, le joueur saute dessus. |
| Conditions manquantes | Le même bouton devient EXAMINER : « L'eau est profonde… », plus le manque (pas de CS, pas de badge, aucun Pokémon) avec les variantes `field` existantes. |
| Se déplacer | Contrôles de la marche, **sans course** (une seule vitesse, un peu plus rapide que la marche, K26). Pas de bouton permanent. |
| Descendre | Avancer vers une case de terre praticable ; le compagnon ressort. |
| Changer de carte | Le Surf est gardé par un bord de carte. Un warp (entrée de grotte) remet à pied, sauf sur une case **« Surf forcé »** (arrivées dans l'eau du B3F et du B4F). |
| Rencontres | Terrain `water`, au taux de la carte. Le fond de combat suit la carte : mer ouverte ou grotte. |
| Sauvegarde | Le Surf fait partie de la position. Au chargement sur l'eau, le joueur réapparaît en Surf. **Garde-fou K26** : si les conditions du Surf ne sont plus réunies, ou si la case n'est plus de l'eau surfable, il est replacé sur la **dernière case de terre** mémorisée de la carte, sinon au point d'arrivée de la carte. |
| Pokémon déposé | Impossible sur l'eau (pas de PC sur l'eau). L'équipe ne peut que s'agrandir en mer (capture, Stockage si pleine). Le garde-fou ci-dessus couvre le reste. |
| Vélo | Rangé automatiquement en montant sur la monture (règle du J22 sur le compagnon). |

### 6.2 Force (RB, sauf mention)

| Cas | Règle |
|---|---|
| Conditions | `hm04` + `badge_rainbow` + un Pokémon de l'équipe compatible |
| Activer | Toucher EXAMINER face à un rocher de Force → dialogue de type Coupe : « Un gros rocher. Il pourrait être déplacé. » → **UTILISER FORCE / LAISSER** → « {Pokémon} utilise Force ! » (cri, compagnon qui pousse). **Actif jusqu'au prochain changement de carte** (RB). |
| Pousser | Marcher contre le rocher en gardant la direction **≈ 0,25 s** (K26 : remplace la double poussée de RB ; un effleurement ne pousse pas). Le rocher avance d'une case, le joueur le suit. |
| Refus | Eau, escalier, échelle, autre niveau de sol, PNJ, autre rocher, mur : le rocher tremble, petit son sourd, aucun texte. |
| Trou | Le rocher tombe (son, poussière), son drapeau de chute est posé, la sauvegarde automatique suit. |

### 6.3 Rochers, trous, courants : tout dérive de 8 drapeaux (K26, P-9 et P-10)

- **Un drapeau par trou** : `seafoam_1f_hole_1_filled`, … `seafoam_b3f_hole_2_filled` (8). Peu
  importe quel rocher l'a rempli (la bizarrerie de RB disparaît).
- **À l'entrée d'un étage** :
  - un trou rempli est **bouché** (on peut marcher dessus) ;
  - le rocher tombé apparaît **sous lui**, à l'étage inférieur ;
  - les rochers « libres » de l'étage sont tous **à leur position d'origine** ;
  - le nombre de rochers libres est le nombre d'origine **moins les trous remplis**.
- **Récupération locale documentée** : **changer d'étage remet à leur place les rochers non tombés**
  (RB). Un panneau à l'entrée de chaque étage à rochers le dit dans le monde, sans interface.
- **Courants** : cases de glissade décrites dans les grilles, **actives tant que les 2 drapeaux de
  l'étage du dessus ne sont pas posés**. Les rochers tombés sont posés **visiblement dans le
  courant** : le joueur voit pourquoi l'eau s'est calmée.
- **Courant B3F** : il emporte le joueur jusqu'au B4F (mer est), comme RB.
- **Courant B4F** : l'eau de la salle d'Artikodin est infranchissable (« Le courant est beaucoup trop
  fort ! ») tant que les 2 trous du B3F ne sont pas remplis.
- **Anti-blocage par conception** (à prouver par un test sur chaque grille) :
  - depuis toute case atteignable, avec ou sans Force, il existe un chemin vers une sortie de
    l'étage (une échelle vers le haut ou l'entrée) ;
  - un rocher ne peut jamais murer cette sortie, sinon la case est retirée de la grille ;
  - les arrivées dans l'eau ont toujours une rive atteignable.

### 6.4 Artikodin (RB, sauf mention)

- Visible dans sa salle, posé, souffle froid léger. La salle est un peu plus lumineuse et plus
  silencieuse que le reste (vent, gouttes). **Pas de cinématique.**
- **Interaction volontaire** : « Gyaoo ! » + cri → combat sauvage, intro « légendaire » (bandeau
  plus lent, sans nouvel écran), musique de combat sauvage.
- **N50 : Picpic, Laser Glace (RB)** → aucune capacité nouvelle à créer. Taux de capture **3**.
- **Issues** → P-15.
- **Sans duplication** :
  - le drapeau `articuno_done`, le Pokémon capturé et la sauvegarde sont écrits **ensemble**, dans
    une sauvegarde **forcée** juste après la fin du combat, avant tout texte ;
  - avant cette écriture, il n'y a rien sur le disque, donc on reprend avant l'interaction ;
  - le Pokémon porte son identifiant unique (sauvegarde v6).
- Équipe pleine : Stockage, avec le message existant.

## 7. Espèces, capacités et données

**Espèces nécessaires** (données + dos repeint ; la face est l'artwork officiel, présent pour les
151) :

| Groupe | Espèces | État |
|---|---|---|
| Déjà dans `main` | Carapuce, Carabaffe, Kokiyas, Hypotrempe, Poissirène, Stari, Staross, Nosferapti, Nosferalto, Rattata, Rattatac, Roucool, Roucoups | Données + dos provisoires |
| Sur des branches | Léviator (J19), Aquali (J20), Ptitard, Tentacool, Ronflex (J21, branche de données non fusionnée), Rapasdepic (?), Saquedeneu (J20) | À fusionner |
| **Absentes** | **Tentacruel, Têtarte, Poissoroy, Crustabri, Hypocéan, Otaria, Lamantine, Ramoloss, Flagadoss, Psykokwak, Akwakwak, Krabby, Krabboss, Artikodin** | Données + dos (14) |
| Selon P-18/P-19 | Kabuto, Amonita, Ptéra ; Raichu, Électrode, Mimitoss, Ponyta | Données + dos |

**Capacités** :
- **Surf** et **Force** (données + effet en combat simple) ;
- celles des nouvelles espèces jusqu'au niveau 40 environ, à auditer en 24.0. Remplacements
  explicites si un effet manque, comme pour Major Bob. Candidats probables : Écume, Ligotage,
  Acidarmure, Repli, Entrave, Coud'Krâne, Pince-Masse, Guillotine, Cage-Éclair.

Artikodin N50 n'a besoin d'aucune capacité nouvelle.

**Compatibilités CS** : `tm_compatibility.json` est généré et se régénère après fusion. Il faut y
ajouter les nouvelles espèces (Tentacool, Lamantine, Otaria, Psykokwak : Surf ; Krabby, Ramoloss :
Force…).

**Tables (P-12)** : les jalons précédents prennent **l'union de Rouge et Bleu** (Route 4 : Abo et
Sabelette ; Route 24 : Mystherbe et Chétiflor). Je la reprends par défaut pour les Îles Écume.

## 8. Arbitrages

| # | Sujet | Options | Recommandation |
|---|---|---|---|
| **P-1** | Dossier | — | **27**, `dossier-27-iles-ecume.md`, sur `docs/dossier-27-j24`. |
| **P-2** | **Qui construit Surf et Force ?** Le J23 prévoit « 23D Surf et Force (monde et combat) », la V2 du J24 « 24A Surf » | **A** : le J23 construit les deux moteurs, le J24 s'en sert · **B** : le J23 livre les **objets, les données, les capacités en combat et les entrées `FieldMoves`** ; **le J24 construit le mode Surf et les rochers**, là où ils servent pour la première fois · **C** : B, mais Force au J23 (si son Gardien ou son Arène a un rocher) | **B**. Le Parc Safari et Koga n'ont besoin ni de nager ni de pousser ; construire ces moteurs sans terrain pour les tester, c'est les valider deux fois. **À confirmer avec la session du J23** avant son dossier : son critère de fin « obtenir Surf et Force » reste vrai (objets obtenus, apprenables en combat). |
| **P-3** | **Quelle eau devient surfable ?** | **A** : toute l'eau de Kanto dès le J24 · **B** : **seulement les cartes du J24** (Routes 19–20, (21), Îles Écume, Cramois'Île) **et la côte sud de Parmanie** ; ailleurs, l'eau reste un décor, comme aujourd'hui · **C** : B, plus les étendues où RB permet de surfer sans contenu (Azuria, Carmin, Routes 24/25, 11, 12…), sans rien à y trouver | **B**. Rendre surfable toute l'eau déjà peinte, c'est rouvrir une quinzaine de cartes validées (bords, collisions, sorties). La grille marque l'eau surfable avec un caractère distinct ; un test vérifie qu'aucune carte hors liste n'en contient. Une passe « Surf partout » viendra avec le jalon qui ouvre la Caverne Azurée ou l'arrière-pays. |
| **P-4** | **Route 21 et Bourg Palette** | **A** : **construire la Route 21 au J24** (RB : 20 × 90 cases, prairie, 9 Dresseurs) et ouvrir la côte sud de Bourg Palette · **B** : pas de Route 21 ; l'eau de Bourg Palette reste un décor ; le bord nord de Cramois'Île est un **haut-fond infranchissable** (récifs, ressac) · **C** : Route 21 ouverte, sans Dresseurs ni prairie | **A**. C'est la seule façon d'avoir un Kanto cohérent dès qu'on sait nager : Cramois'Île a deux côtes, et rentrer chez soi par la mer est un vrai moment RB. Petite carte, peu d'art nouveau (mer + îlots). **B** si tu veux un J24 plus court ; la Route 21 irait alors avec le jalon d'Auguste. |
| **P-5** | Échelle des cartes | — | Pas de question : comme aux jalons précédents, géométrie RB **agrandie** pour le S24 et la DA peinte (rapport fixé en 24.0 sur les vues générales). Les coordonnées de ce document sont celles de **RB**, jamais celles du projet. |
| **P-6** | **La Route 20 coupée en deux** | **A** : RB : par la mer, Cramois'Île passe **par les Îles Écume** (traversée en Surf, sans Force, emportée par le courant du B3F) · **B** : K26 : un chenal au sud de l'île relie les deux mers ; le donjon devient facultatif pour aller à Cramois'Île | **A**. Le donjon **est** le passage : c'est le moment fort du jalon. Il reste facultatif pour Cramois'Île si la Route 21 existe (P-4 A). Le trajet du courant doit être lisible : écume, son, panneau « DANGER, courant rapide ! » au B4F. Le solveur doit le confirmer sur émulateur en 24.0, sinon on revient vers B. |
| **P-7** | Monture | — | La V2 verrouille une **monture générique peinte** : je la garde. Précision : le **compagnon rentre dans sa Ball** en Surf et ressort à terre (même règle que le Vélo, M-7). |
| **P-8** | Monter sur l'eau | **A** : RB, par le menu Équipe → Surf · **B** : **bouton contextuel SURFER** face à l'eau surfable, un toucher · **C** : automatique en marchant vers l'eau (comme Flash) | **B**. Ni menu, ni bouton permanent. **C** fait sauter le joueur à l'eau par erreur au moindre frôlement d'une rive. Nouveau verbe `surf` dans `InteractButton` (le seul ajout d'interface). Le menu Équipe garde aussi l'entrée Surf (RB), quand le joueur est face à l'eau. |
| **P-9** | **Persistance des rochers** | **A** : **les chutes sont sauvegardées** (8 drapeaux) ; les rochers non tombés reviennent à leur place quand on change d'étage, quand on recharge une partie ou par un panneau « remettre les rochers » (RB) · **B** : A, plus la position exacte de chaque rocher libre dans la sauvegarde (**sauvegarde v8**), et une remise à zéro explicite | **A**. C'est la lecture de « positions et chutes sauvegardées » qui tient aussi « récupération locale » : la seule progression utile est la chute, au plus 4 poussées par étage. **Aucun changement de version**, car les drapeaux sont libres. Changer d'étage est la récupération documentée. Aucun état impossible : chaque étage se reconstruit depuis les drapeaux. |
| **P-10** | Courants | **A** : RB (scripts cachés) · **B** : **cases de courant dans la grille**, visibles (écume, sens), glissade réutilisant le moteur des dalles du J20 (`SpinSlide`), coupées par les drapeaux | **B**. Même règle que RB, mais lisible et testable. Sauvegarde : jamais pendant une glissade (`is_stable`) ; la reprise se fait sur la case d'arrivée. |
| **P-11** | Rencontres en Surf sur les Routes 19–21 | **A** : RB strict : Tentacool seul, N5 à 40, taux 5 · **B** : RB, mais niveaux resserrés sur la zone (≈ 25–35) · **C** : K26 : Tentacool + Tentacruel rare | **B**. Un Tentacool N5 à ce stade du jeu n'a pas de sens. On garde l'espèce RB et le taux bas, sans inventer d'espèce. |
| **P-12** | Version des tables des Îles Écume | — | Pas de question : **union Rouge + Bleu**, comme les jalons précédents (ajoute Krabby, Krabboss à la liste Rouge). Taux RB (15 au 1F, 10 ailleurs), **aucune rencontre en Surf dans le donjon** (RB). |
| **P-13** | Dresseurs | **A** : les 29 Dresseurs RB (Routes 19–21), équipes RB, niveaux recalés par l'outil de simulation · **B** : moins de Dresseurs sur l'eau (≈ 6 par route) | **A**, niveaux recalés (règle de difficulté : ≤ 80 % de victoire au premier essai ne s'applique pas à ces combats de route, faciles par nature). Les Pêcheurs de la Route 21 restent à vue 0. |
| **P-14** | Objets | **A** : RB : 3 objets cachés dans le donjon, rien sur les routes · **B** : A, plus 2 ou 3 objets visibles sur les îlots et la prairie de la Route 21 | **B** [D]. La mer sans rien à trouver est longue. Objets de niveau RB (Super Bonbon non ; Hyper Ball, Max Repousse…), fixés au dossier. |
| **P-15** | **Issues du combat d'Artikodin** (pas dans les 7 décisions) | **A** : V2 / RB : **capture, K.O. ou fuite** → il disparaît ; défaite du joueur → il reste (RB) · **B** : **capture ou K.O.** → il disparaît ; **fuite ou défaite** → il reste à sa place, nouvelle chance | **B**. C'est la règle que tu as retenue pour Ronflex au J21 (fuite → nouvelle chance). Avec un taux de capture de 3, perdre l'unique Artikodin sur une fuite, c'est la punition la plus dure du jeu. Aucune duplication possible : la capture le retire. Après un K.O. : « Artikodin s'est envolé vers le large… » [D], plus de retour. |
| **P-16** | Accès au B4F sans Surf | — | Pas de question : comme on ne peut atteindre la Route 20 qu'en Surf, le joueur qui entre dans le donjon remplit toujours les conditions du Surf. Le garde-fou du §6.1 couvre le reste. Le blocage de RB n'existe pas ici. |
| **P-17** | Objectifs du tableau de bord | — | Aucun objectif nouveau (V2, décision 7) ; rien ne montre Artikodin ni Cramois'Île. Le PNJ du Centre de Parmanie ou un Nageur parle des îles (texte). |
| **P-18** | **Résurrection des fossiles** | **A** : au J24, RB : salle d'essais, N30, « va te promener », retour par la ville · **B** : reportée au jalon d'Auguste ; le scientifique est présent mais dit « Laboratoire en cours d'installation » | **A**. Le fossile du Mont Sélénite (J12) attend depuis douze jalons ; c'est la vraie récompense de Cramois'Île. Coût : Kabuto, Amonita, Ptéra (données + dos) et `PokemonGift` (J20). Le Vieil Ambre n'est proposé que si le J10 le donne : à vérifier. |
| **P-19** | CT35 Métronome et échanges du Labo | **A** : tous au J24 · **B** : **CT35 au J24** si Métronome est faisable (capacité aléatoire, à auditer) ; **échanges reportés** (aucun système d'échange en jeu) ; leurs PNJ parlent d'autre chose, sans promesse · **C** : rien | **B**. Les échanges demandent un système nouveau et 6 espèces : à part. |
| **P-20** | **Manoir et Arène fermés** | **A** : Arène : RB, porte fermée sans la Clé Secrète ; Manoir : **entrée effondrée** (gravats, panneau « Danger : bâtiment instable ») · **B** : Manoir ouvert au rez-de-chaussée seulement · **C** : Manoir fermé par un PNJ (scientifique ou police) | **A**. La règle RB de l'Arène marche telle quelle et ne promet rien. Pour le Manoir, un éboulement est un obstacle de monde que le jalon d'Auguste retirera, sans dialogue qui annonce une suite. |
| **P-21** | Arrivée à Cramois'Île | — | Aucun événement (V2). Titre de zone + arrivée normale. Le Centre devient le point de retour. |
| **P-22** | Découpage et validations S24 | **A** : V2 (7 lots, 6 validations) · **B** : **24.0** (grilles des 7 à 9 cartes, solveur sur émulateur, vues peintes, données des espèces, art) · **24A** « Surf » (mode Surf sur **une carte d'essai** puis Routes 19–20, rencontres, Nageurs ; **validé seul**, système à risque) · **24B** « la mer » (Route 21, Cramois'Île et Labo, raccords Parmanie et Bourg Palette) · **24C** « Îles Écume » (Force, trous, courants, 5 étages ; **validé seul**) · **24D** « Artikodin » + QA finale de bout en bout | **B**. **Quatre validations S24.** Surf et rochers sont chacun validés seuls (règle 1). Artikodin est petit mais touche la sauvegarde : il passe avec la QA finale, sur une partie qui arrive par le vrai chemin. |

## 9. Lots, tests et QA

| Lot | Contenu | Tests automatisés | QA S24 |
|---|---|---|---|
| **24.0** | Grilles `tools/plans/` des Routes 19, 20, (21), Cramois'Île + intérieurs, Îles Écume 1F–B4F ; vérification du solveur sur émulateur (chemins, trajet du courant) ; vues peintes ; données des espèces et capacités ; dos ; monture, Nageurs, rochers, Artikodin | Contrôles de grille (`plan_check_*.py`) : raccords, **atteignabilité de chaque sortie depuis chaque case**, eau surfable seulement sur les cartes autorisées | Vues sur planche |
| **24A** | Mode Surf, verbe SURFER, montée et descente, Surf forcé, rencontres `water`, fond mer, Nageurs, transitions, reprise sur l'eau, garde-fou | `SurfRules` pure (conditions, montée, descente, case forcée, garde-fou de chargement) ; transitions de bord en Surf ; rencontres ; Nageur qui voit le joueur en Surf ; sauvegarde et chargement sur l'eau, Pokémon compatible déposé (simulé) | Monter et descendre, traverser les Routes 19–20, un Nageur, une rencontre, fermer l'application en mer et reprendre |
| **24B** | Route 21, Cramois'Île, Centre, Boutique, Labo, fossiles, CT35 (P-19), Manoir et Arène fermés, côte sud de Bourg Palette, raccord Parmanie | Raccords des 4 bords ; fossile unique (pas de duplication au rechargement) ; Arène refusée sans clé | Boucle Parmanie → Îles → Cramois'Île → Route 21 → Bourg Palette |
| **24C** | Rochers de Force, trous, courants, 5 étages, objets cachés, rencontres | `BoulderRules` pure (poussée, refus, chute) ; reconstruction de chaque étage depuis les 8 drapeaux (256 combinaisons) ; courants coupés par les bons drapeaux ; **aucun état bloquant** (recherche exhaustive des positions de rochers par étage) ; sauvegarde après chaque chute | Résoudre le donjon, ressortir, revenir, recharger au milieu d'un étage |
| **24D** | Artikodin, issues P-15, sauvegarde forcée ; QA finale | Capture, K.O., fuite, défaite, équipe pleine → Stockage ; fermeture simulée avant et après l'écriture | Rencontre réelle ; non-régression des jalons précédents (Bourg Palette, Parmanie) |

**Peut avancer avant la fusion du J23** : 24.0 entier ; les moteurs `SurfRules` et `BoulderRules`
(logique pure) et leurs cartes d'essai, sur une branche partie de l'intégration J16–J22.

## 10. Drapeaux et sauvegarde (proposition, sans changement de version)

| Drapeau | Posé quand | Effet |
|---|---|---|
| `seafoam_1f_hole_1_filled` … `seafoam_b3f_hole_2_filled` (8) | Un rocher tombe dans ce trou | Trou bouché, rocher sous lui à l'étage inférieur, courants dérivés |
| `articuno_done` | Capture ou K.O. (P-15 B) | Artikodin retiré du monde |
| `articuno_caught` | Capture | Textes (facultatif) |
| `got_tm35` | CT35 reçue | Remise unique |
| `fossil_reviving_<espèce>` | Fossile confié | Le Pokémon attend au Labo ; effacé quand il est donné |
| `visited_cinnabar_island` | Arrivée | Point de retour au Centre (mécanisme existant) |

**Position en Surf** : un champ `surfing` dans la position sauvegardée. C'est le seul ajout. On
l'ajoute **sans changer de version** si le format de position accepte un champ facultatif (lecture
par défaut à `false`), sinon il faut une v8 : à vérifier en 24A. Pas de position de rocher
sauvegardée (P-9 A).

## 11. Questions ouvertes (non bloquantes pour le dossier)

1. **Vieil Ambre** : le J10 le donne-t-il au Musée d'Argenta ? (Sinon, seuls Kabuto et Amonita au
   Labo.)
2. **Fossile du J12** : lequel le joueur a-t-il ? Est-il bien un objet du Sac ?
3. **Métronome** : capacité aléatoire faisable dans le moteur actuel ? (Décide P-19.)
4. **Route 19 depuis Parmanie** : le J22 doit réserver la sortie sud (plage) au bon endroit.
   À inscrire dans le contrat du J22.
5. **Musique** : thème « en mer » et thème de grotte glacée : nouveaux ou repris ?

## 12. Ce qui reste hors du J24

- Manoir Pokémon, Clé Secrète, Arène d'Auguste, Badge Volcan.
- Échanges du Labo (P-19 B), pêche (J22), Surf ailleurs que sur les cartes du J24 (P-3 B).
- Électhor, Sulfura, Mewtwo.

## 13. Suite

Tu réponds aux arbitrages **P-1 à P-22** (P-5, P-12, P-16, P-17 et P-21 sont des constats, sans
choix à faire). Puis :
1. j'écris le dossier 27, avec le plan de chaque carte, les textes complets (Nageurs, panneaux,
   PNJ de Cramois'Île, Labo, Artikodin) à valider en un seul lot, et le contrat d'entrée ;
2. j'envoie **P-2** à la session du J23, pour qu'elle en tienne compte dans son dossier 26.

## Annexe A — Plans fonctionnels (reconstruction de RB, coordonnées RB, **rien d'implémenté**)

Décodés de la collision réelle de RB (`cavern.bst`, `overworld.bst`, `Cavern_Coll`, collisions par
paires). Les grilles du projet seront redessinées et agrandies en 24.0 (P-5) ; celles-ci servent à
vérifier la topologie, pas à placer des cases.

Légende :
- `#` mur · `|` arête infranchissable · `~` eau · `S` escalier · `L` échelle ou warp · `E` entrée
- `.` sol bas · `:` sol haut (on ne passe de l'un à l'autre que par un `S`)
- `O` trou · `r` petit rocher fixe · `n` panneau
- `B` rocher de Force au départ · `b` rocher qui apparaît après une chute · `X` rocher tombé dans
  l'eau (coupe le courant) · `A` Artikodin
- `T` case qui déclenche un courant · `v > ^` trajet du courant · `!` escalier interdit au Surf tant
  que le courant B4F est actif

### Routes et ville (schéma)

```
                 PARMANIE (J22)
                      | sortie sud (colonne 10 de Parmanie)
   ROUTE 19   [plage, 2 Dresseurs]
              [mer, 8 Nageurs]
                      |
   ROUTE 20  <---- mer ouest ----|  ÎLES ÉCUME  |---- mer est ---->+
   (100 x 18)  Cramois'Île   (58,9) entrée est   (48,5) entrée ouest   (raccord Route 19, lignes 36-53)
               îlot Ornithologue (32-35, 8-9)
                      |
  CRAMOIS'ÎLE (20 x 18) --- nord ---> ROUTE 21 (20 x 90, mer, prairie, îlots) ---> BOURG PALETTE (côte sud)
   Manoir (6,3) fermé · Arène (18,3) fermée · Labo (6,9) · Centre (11,11) · Boutique (15,11)
```

**Les deux mers de la Route 20 ne communiquent pas** : on passe de l'une à l'autre par le donjon
(P-6).

### Îles Écume

```
1F                                    B1F
    000000000011111111112222222222        000000000011111111112222222222
    012345678901234567890123456789        012345678901234567890123456789
 0  ##############################     0  ###########::::::::###########
 2  ###::::::::::::::::::::#....##     2  ##..L.....#::::::::#........##
 3  ###::::::::::::::::::::#.L..##     3  ##........#::::##S##.....L..##
 4  ###::::::::::::::::::::#....##     4  ##..#::::##::::#....|.......##
 5  ###::::L:::##########S##....##     5  ##..#::L:##::::#....|.......##
 6  ###::::::::#.....O..|...O...##     6  ##..#::::##::::#.bO.|.bO....##
 7  ###::::::::#........|.....B.##     7  ##..#::####::L:#....|.......##
 8  ###::::::::#........|.......##     8  ##..#::##::::::#....|.......##
 9  ###::::::::#........|.......##     9  ##..#S###::::::#....||||||||##
10  ###::::::::#......B.|.......##    10  ##......#::::::::::#........##
11  ######SS####........||||||||##    11  ##......#::::::::::#.....L..##
12  ##..................|.......##    12  ##......#::::::::::#........##
13  ##..................|.......##    13  ##......#S#######S##........##
14  ##..................|.......##    14  ##..........|.......|.......##
15  ##..................|..L....##    15  ##..........|......L|..L....##
16  ####..####################..##
17  ####EE####################EE##
    entrée ouest (4-5,17)   entrée est (26-27,17)

B2F                                   B3F
 2  ##....................#::::###     0  #::::::::##:#:~~#:#:#::::::::#
 3  ##...L................#::L:###     1  #::::::::#####~~#####::::::::#
 4  ##........#::::#......#::::###     2  #::::::::#~~~~~~~~~~#::::::::#
 5  ##........#::::#......###S####     3  #::::::::#~~~~~~~~~~#::::L:::#
 6  ##........#::::#..bO||Ob....##     4  #::::::::##::::::#~~#::::L:::#
 7  ##........#::L:#....||......##     5  #::::#SS###::::::#~~##########
 8  ###::::::::::::::::::#......##     6  #::::#..L.#::::::#XX#::::::::#
 9  ###::::::::::::::::::#......##     7  #::::#....#::##S##TT#::::::::#
10  ###::::::::::::::::::##::::###     8  #::::::::::::#~T~~v~#::::::::#
11  ######SS#######::::::##::L:###     9  #::::::::::::#~v~~v~###S#::::#
12  ##............#::::::##::::###    10  #::::::::::::#~v~~v~~~~~#::::#
13  ##...L........###S#####::::###    11  #::::::####::#~>>>>>v~~~#::::#
14  ##....................#::L:###    12  #::::L:#..#::::::::#v~#::::::#
15  ##.............r...L..########    13  ########..#::::::::#v~#::::::#
    (Pépite cachée en (15,15))        14  .....B.rBB#::::::::#v~#::L:::#
                                      15  ...Br.....######SS##v~########
                                      16  ...Or.O..r........||v~|.......
                                      17  ....r..............|~~|.......
                                          (Max Élixir caché en (9,16) ; (20-21,17) → B4F)

B4F
 0  ##~~#::::::#~~#::::::::::::###
 1  ##~~#:A::::#~~#::::::::n:::###     A = Artikodin (6,1)
 2  ##~~#::::::#~~#::::::::::::###
 3  ##~~###S####~~#::::::::::::###
 4  ##~~~~~~~~~~~~#::::::::::L:###
 5  ##~~~~~~~~~~~~#::######S######
 6  ##~~~~#::::::::::#~~~~~~~~~~##
 7  ##~~~~#::::L:::::#~~~~~~~~~~##
 8  ##~~~~#::::::::::#~~~~~~~~~~##
 9  ##~~~~#::::::::###~~~~~~~~~~##
10  ##~~~~#::::::::#~~~~~~~~~~~~##
11  ##~~~~#!#####::#~~~~~~~~~~~~##
12  ##~~~~~^~~~~#::#~~~~~~~~~~~~##
13  ##~~^>>^~~~~#::#~~~~~~~~~~~~##
14  ##~~TT#::::::::::::#~~~~~~~~##
15  ##~~XX#::n:::::::::#~~~~~~~~##
16  ###:~~#::::::::::::#~~#:|.#:##
17  ####~~##############~~##||####
    mer ouest (salle d'Artikodin) | mer est ((23,5), (20-21,17)) : elles ne communiquent pas
    (Hyper Ball cachée en (25,17))
```

**Chaîne des chutes** (trou → point d'arrivée fixe du rocher) :
- 1F (17,6) → B1F (17,6) · 1F (24,6) → B1F (22,6)
- B1F (18,6) → B2F (18,6) · B1F (23,6) → B2F (23,6)
- B2F (19,6) → B3F (18,6) **dans l'eau** · B2F (22,6) → B3F (19,6) **dans l'eau** : coupe le
  courant du B3F
- B3F (3,16) → B4F (4,15) **dans l'eau** · B3F (6,16) → B4F (5,15) **dans l'eau** : coupe le
  courant du B4F

**Solution du B3F trouvée par le solveur** (à vérifier) :
1. (5,14) ← ;
2. (9,14) ↑↑ ;
3. (8,14) ↓ ← ← ↓ dans (6,16) ;
4. (3,15) ↓ dans (3,16).
