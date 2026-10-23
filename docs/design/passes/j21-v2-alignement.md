# J21 — Le repos des esprits : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-15. Conception seulement : aucune ligne de code. V2 reproduite dans
> `j21-v2-chatgpt.md`. Relu contre `vision.md`, la roadmap, le dossier 20 (J17, `jalon-17`), le
> dossier 21 (J18, `docs/dossier-j18`), le dossier 22 et le plan `jalon-19.md` (J19, `jalon-19`), le
> dossier 23 (J20, branche locale `docs/dossier-23-j20`) et le code de `origin/main` (`440f9b17`,
> J15 terminé) et de `jalon-17`.
>
> **Faits Rouge/Bleu** : désassemblage `pret/pokered` (`af51989`) ; « vérifié » renvoie aux fichiers
> cités. Origine des règles : **RB** Rouge/Bleu · **RFVF** Rouge Feu / Vert Feuille · **K26**
> invention de Kanto 2026.
>
> Les 7 décisions de la V2 ne sont pas rouvertes. Trois demandent une précision (n° 5, 6 et 1 pour
> la Route 16). Mes arbitrages sont numérotés **L-1 à L-16** (§6) : les lettres A à K et V sont
> prises par les passes précédentes, H deux fois. Réponds par numéro ; j'écris ensuite le dossier.

## 0. État réel du dépôt

| Point | Constat |
|---|---|
| `main` | `440f9b17`, **J15 terminé** (Route 5, Pension, sauvegarde **v7**, Carmin-sur-Mer). |
| J16 (S.S. Anne, Major Bob, Coupe) | Dossier 19 et code sur `ccr-fa255d49-wvvacc`, pas fusionné. |
| J17 (Route 11, Cave Taupiqueur, Flash) | Dossier 20, **code** sur `jalon-17` (81 fichiers), pas fusionné. **Ronflex y est posé** (§2.5). |
| J18 (Grotte Sombre, Lavanville, Tour RDC) | Dossier 21 consolidé, pas de code. |
| J19 (Tour 2F–6F, mode spectre, rival n° 5) | Dossier 22 et plan `jalon-19.md` consolidés, art série 20 validé, **pas de code**. |
| J20 (Céladopole, repaire, Scope Sylphe) | Dossier 23, grilles v1 validées, sur une branche **locale** (`docs/dossier-23-j20`), pas de code. |
| Numéros | 19 = J16, 20 = J17, 21 = J18, 22 = J19, 23 = J20 → **24 = J21** (branche `docs/dossier-24-j21`, poussée). |
| Lettres d'arbitrage | A à K et V prises → **L** pour le J21. |

**Conséquence** : le J21 repose sur cinq jalons dont un seul est en code (J17), et aucun dans `main`.
Le dossier 24 écrit donc un **contrat d'entrée** (§3), comme les J19 et J20. Le code du J21
viendra après la clôture du J20 (moteur de combat et étape de scène du J19, Scope du J20) ; les
grilles, vues peintes, données et l'art peuvent avancer dès la validation du dossier.

## 1. Les 7 décisions de la V2

| # | V2 | Avis |
|---|---|---|
| 1 | Tour complète, Fuji, Poké Flûte, deux Ronflex | Oui. **Le Ronflex de la Route 16 oblige à rouvrir la sortie ouest de Céladopole**, que le J20 a fermée par une haie « sans promesse » (H-4) en laissant ce remplacement « au jalon de la Route 16 ». Le J21 devient ce jalon pour le premier tronçon → **L-4**. |
| 2 | Ossatueur obligatoire, non capturable | Oui, conforme à RB. Règles exactes au §2.1 → **L-5**. |
| 3 | Rocket au dernier étage, puis sauvetage | Oui, conforme à RB : 3 Sbires, pas de chef → **L-7**. |
| 4 | Poké Flûte permanente, hors combat et en combat | Oui. C'est **le premier objet clé qui s'utilise** : aujourd'hui un objet clé n'a aucun contexte d'usage (`item_data.gd`, catégorie `KEY` : « jamais utilisé ») → coût au §4. Règles au §2.3 → **L-9**, **L-10**. |
| 5 | Deux Ronflex uniques, capturables ou battus | Oui. **Mais le « Ronflex est » existe déjà** : le J17 l'a posé au bout est de la **Route 11** (H-10, drapeau `snorlax_route_11_awake`), au croisement de la Route 12. Dans RB, c'est **le même** Ronflex (un seul, au croisement) → **L-2**. Règle de fuite et de défaite → **L-11**. |
| 6 | Route 12 : début au J21, suite au J22 | Oui sur le principe, mais « début » n'a pas de contenu défini. Dans RB, le tronçon entre Lavanville et Ronflex **est** le ponton des pêcheurs, que la V2 renvoie au J22 → **L-3**. |
| 7 | Exploration libre à la fin | Oui. Aucun déplacement forcé ; objectifs du tableau de bord → **L-13**. |

## 2. Ce que fait Rouge/Bleu (vérifié)

### 2.1 Ossatueur (`scripts/PokemonTower6F.asm`, `engine/battle/core.asm`, `engine/items/item_effects.asm`)

| Aspect | RB |
|---|---|
| Déclencheur | Case (10, 16) du 6F, tant que `EVENT_BEAT_GHOST_MAROWAK` n'est pas posé. « Va-t'en… Intrus… » puis combat. |
| Avec le Scope | Le combat n'est plus un combat « fantôme » (le test est la possession de `SILPH_SCOPE`, l. 3316) : « Le SCOPE SYLPHE révèle l'identité du SPECTRE ! », puis combat sauvage **normal** contre Ossatueur N30 (Massd'Os, Rugissement, Groz'Yeux, Puissance). |
| Ball | « Il a évité la Ball ! Ce Pokémon ne peut pas être capturé ! » **La Ball est consommée** (la sortie commune retire une Ball du Sac). |
| Objets | Sac utilisable normalement. |
| Fuite | **Possible**, avec le calcul de fuite normal. Le joueur est ensuite repoussé d'une case et le déclencheur se réarme. |
| Défaite | Réveil au Centre ; le déclencheur se réarme. |
| Victoire | Drapeau posé ; « Le SPECTRE était l'âme de la mère d'Osselait ! », **cri d'Ossatueur**, pause, « L'âme de la mère s'est apaisée. Elle est partie pour l'au-delà ! ». |
| XP, Pokédex | Combat sauvage normal : XP gagnée, Ossatueur « vu ». |

### 2.2 Le 7e étage et M. Fuji (`PokemonTower7F.asm`, `MrFujisHouse.asm`, `parties.asm`)

- **3 Sbires Rocket**, chacun avec sa ligne de vue, sur le seul chemin vers Fuji :
  Nosferapti, Nosferapti, Nosferalto **N25** ; Smogo, Soporifik **N26** ; Nosferapti, Rattata,
  Rattatac, Nosferapti **N23**.
- Répliques (résumé) : « Qu'est-ce que tu veux ? » ; « Ce vieux est venu se plaindre qu'on maltraite
  des Pokémon inutiles ! On en discute entre adultes ! » / « Les Pokémon ne servent qu'à faire de
  l'argent ! » ; « Tu ne sauveras personne, gamin ! ».
- **Rencontres sauvages au 7F** (taux 15) : Fantominus, Spectrum N28–30, Osselait.
- **Fuji** : « Tu es venu me sauver ? Merci. Mais je suis venu ici de mon plein gré, pour apaiser
  l'âme de la mère d'Osselait. Je crois qu'elle est partie pour l'au-delà. » Il invite le joueur
  chez lui, puis **le joueur est téléporté** dans la maison (script `WARP_TO_MR_FUJI_HOUSE`).
- **Maison** : Fuji donne la Poké Flûte en lui parlant (« Ta quête du Pokédex échouera sans amour
  pour tes Pokémon. Ceci t'aidera. »), avec la règle « Fais de la place ! » si le Sac est plein ;
  ensuite « Ma Flûte t'a-t-elle aidé ? ». Remise unique (`EVENT_GOT_POKE_FLUTE`).
- **Après** : la fille de la maison d'Osselait dit que le spectre de la Tour est parti ; un client
  de la Boutique change de réplique ; RB permute aussi deux PNJ **de Safrania** (hors J21).

### 2.3 Poké Flûte (`ItemUsePokeFlute`)

| Contexte | RB |
|---|---|
| Combat sauvage | Réveille **toute l'équipe du joueur** et le Pokémon sauvage. |
| Combat de Dresseur | Réveille **toute l'équipe du joueur et toute l'équipe adverse**. |
| Effet | « Tous les Pokémon endormis se réveillent. » ; si personne ne dormait : « Vous jouez de la Poké Flûte. Quel air entraînant ! ». L'usage prend le tour, comme tout objet en combat. |
| Hors combat, devant Ronflex | Sur une case voisine de Ronflex (Route 12 ou 16), tant qu'il n'est pas « battu » : « {joueur} joue de la Poké Flûte. » → Ronflex se réveille. |
| Hors combat, ailleurs | « Quel air entraînant ! » |

### 2.4 Ronflex (`scripts/Route12.asm`, `Route16.asm`)

- **N30**, capacités au N30 : **Coup d'Boule, Amnésie, Repos** (Plaquage au N35). Taux de capture 25.
- « Ronflex se réveille ! Il attaque, de très mauvaise humeur ! » → combat sauvage.
- **Ronflex est retiré du monde avant le combat**, quelle que soit l'issue :
  - victoire ou **fuite** : « Ronflex se calme ! Avec un grand bâillement, il retourne dans les
    montagnes ! » ;
  - capture : aucun texte de plus ;
  - **défaite** : réveil au Centre, et Ronflex a quand même disparu.
- **RB = une seule chance**, quelle que soit l'issue.

### 2.5 Géographie des deux Ronflex

- **Route 12** : route nord-sud de 20 × 108 cases sous Lavanville. De haut en bas : poste (traversé
  par la route, 2F : CT39 Météores), **ponton des pêcheurs** (4 Pêcheurs entre les lignes 31 et 52),
  puis **Ronflex en (10, 62), exactement au croisement où arrive la Route 11** (raccord ouest,
  décalage 27 blocs). Ronflex bloque à la fois Lavanville → sud, Route 11 → Lavanville et Route 11
  → sud. Plus au sud : maison de la Super Canne, Dresseurs, Route 13.
- **Projet** : le J17 a posé ce Ronflex **dans la carte de la Route 11**, goulet de 2 cases en
  (66..67, 14..15), bord est (75, 14..15) noté « Route 12 : jalon de la Poké Flûte »
  (`tools/plans/route_11.txt`, `FlagGate` + `InteractPoint` 2 × 2, `unless snorlax_route_11_awake`,
  textes T-6 et T-7). **Le « Ronflex est » de la V2 et celui du J17 sont donc le même.**
- **Route 16** : Ronflex en (26, 10), à une quinzaine de cases du bord de Céladopole, sur la voie
  basse, avant le poste de la Piste Cyclable (x 17..24). Voie haute derrière un arbre à Couper → maison
  qui donne **CS02 Vol**. Derrière le poste : Piste Cyclable, **réservée au Vélo** (aucun système de
  Vélo dans le projet).

## 3. Contrat d'entrée (hypothèses sur les J17 à J20)

| Le J21 suppose | Jalon | Si c'est faux |
|---|---|---|
| Ronflex de la Route 11 : `FlagGate` 2 × 2 et `InteractPoint`, `unless snorlax_route_11_awake`, bord est (75, 14..15) praticable mais inatteignable | J17 (codé) | Le J21 change seulement la donnée et le dialogue. |
| Lavanville : bord sud « ROUTE 12 — À venir » ; Maison des Pokémon (enfant, Rondoudou, Nidoran ♀) | J18 | — |
| Maison de Fuji au J19 : homme, fille, **Osselait** (Q-2 = A) ; textes §15.6 | J19 | Le J21 remplace leurs variantes. |
| 6F : scène `tower_6f_ghost`, déclencheur (10, 16), étape `wild_battle` `marowak` 30 `ghost: always`, recul (10, 15), variante `unless ghost_marowak_calmed` ; warp du 7F posé mais inatteignable | J19 (plan) | Le J21 change la **donnée** de la scène (le plan J19 le prévoit). |
| Mode spectre = possession de `silph_scope` ; règles `ball_refused`, `flee_always`, masque d'identité | J19 (plan) | `ball_refused` sert aussi à Ossatueur (§4). |
| Drapeaux réservés et jamais posés avant : `ghost_marowak_calmed`, `fuji_rescued`, `got_poke_flute`, `beaten_tower_rocket_1..3` | J19, J20 (tests) | — |
| `silph_scope` objet clé, obtenu après Giovanni ; objectif « retourner à la Tour Pokémon. » | J20 | — |
| Céladopole, sortie ouest = **haie dense et talus** (H-4) | J20 | **Le J21 la remplace** (L-4). |
| Espèces : Osselait, Ossatueur (données de combat), Fantominus, Spectrum (J19) ; Soporifik (J17) ; Smogo, Nosferapti, Nosferalto, Rattata, Rattatac (`main`) | J15–J19 | — |
| Capacités : Repos (`main`), Coup d'Boule (J17), Massd'Os (J19), Rugissement, Groz'Yeux, Puissance (`main`) | — | **Amnésie** manque (Ronflex) → créée au J21. |
| Équipe du joueur vers les niveaux 28 à 35 (Erika, Giovanni) | J20 | Rocket et Ronflex aux niveaux RB restent faciles : c'est voulu (L-7, L-12). |

## 4. Coûts techniques (code réel et plans)

| Besoin | Existe ? | Où / coût |
|---|---|---|
| Changer de carte dans une scène (téléportation vers Fuji) | **oui** | Étape `change_map` (`cutscene_director.gd`). Coût nul. |
| Combat sauvage lancé par une scène (Ossatueur, Ronflex) | prévu J19 | Étape `wild_battle`, drapeaux `win` / `lose` « prévus pour le J21 » (`jalon-19.md` §2.4). Le J21 ajoute l'issue **fuite** (`flee`) et **capture**. Faible. |
| Capture refusée avant le lancer | prévu J19 | Règle `ball_refused` du SPECTRE, à rendre indépendante du mode spectre (`uncatchable`) avec son propre message. Faible. |
| Objet clé utilisable | **non** | `ItemData.contexts()` rend `[]` pour `KEY`. Il faut un usage d'objet clé (`key_use`) en exploration **et** en combat, l'onglet Objets clés dans le Sac de combat, et un bouton UTILISER. **Moyen** : premier du genre, touche le Sac et le combat. |
| Réveiller toute une équipe | partiel | `StatusRules` gère le sommeil (J11) ; il manque une fonction « réveiller tout le monde » et son événement de combat. Faible. |
| Case libérée par un drapeau | **oui (J17)** | `FlagGate`. Le réveil pose le drapeau ; le combat suit. |
| Rencontre unique persistante | oui | Drapeaux de sauvegarde. Aucune migration. |
| Remise unique d'un objet | oui | Modèle CT34 / Scope (`give` + drapeau). Idempotence à soigner (L-8). |
| Amnésie | non | Effet `stat_stage` existant (Défense Spé. +2). Faible. |
| Objectifs du tableau de bord | oui | `data/story/objectives.json`. |
| Sauvegarde | — | **Aucun changement de version** : seulement des drapeaux. |

## 5. Art et assets

| Élément | État | Besoin J21 |
|---|---|---|
| 7F de la Tour | rien | Grille 20 × 18 (RB) + vue peinte sur l'enveloppe J19 ; autel, bougies, Fuji agenouillé |
| M. Fuji | rien (absent jusqu'ici) | **Planche PNJ** peinte (vieil homme, marche + pose de prière) ; portrait si les scènes en ont (non à ce jour) |
| Sbires Rocket | oui (J12) | — |
| Ossatueur | rien | Face : artwork officiel ; **aucun dos** (jamais dans l'équipe) |
| Ronflex | sprite endormi du monde (J17, série 19) | Face : artwork officiel ; **dos** (capturable) ; planche de marche **non** (compagnon reporté, sauf avis contraire) |
| Poké Flûte | rien | Icône du Sac |
| Fonds CB.3 | `tour_pokemon` (J19) | Route 11 (Ronflex est) : celui du J17 s'il existe, sinon décor de route existant ; **Route 16** : nouveau ou celui de Céladopole [D] |
| Route 12 nord, Route 16 est | rien | Grilles + vues peintes (L-3, L-4) |
| Son, musique | hors jalon | Intentions notées pour le jalon audio (comme K-18) |

## 6. Arbitrages

| # | Sujet | Options | Recommandation |
|---|---|---|---|
| **L-1** | Numéro et nom du dossier | — | **24**, `dossier-24-repos-des-esprits.md`, sur `docs/dossier-24-j21`. |
| **L-2** | Le « Ronflex est » | **A** : c'est le Ronflex du **J17** (bout est de la Route 11, `snorlax_route_11_awake`), réveillé là où il est · **B** : le déplacer sur la carte de la Route 12, au croisement exact (RB), ce qui modifie une carte du J17 · **C** : un troisième Ronflex (non RB) | **A**. Même Pokémon que RB, déjà codé et validé ; on le réveille depuis la Route 11 **ou** depuis la Route 12 (il est au bord du croisement). Identifiants : `snorlax_route_11_*` et `snorlax_route_16_*`. **Dépendance J22 signalée** : dans RB, ce Ronflex bloque aussi la Route 12 vers le sud ; ici, c'est au J22 de décider ce qui ferme la Route 12 sud tant que la Flûte n'est pas obtenue. |
| **L-3** | Contenu de « Route 12 : début » | **A** : **Route 12 nord complète**, de Lavanville au croisement de la Route 11 : poste (CT39 au 2F si Météores existe, sinon reportée [D]), ponton, **ses 4 Pêcheurs RB**, rencontres ; bord sud « ROUTE 12 — À venir » · **B** : même tronçon, **sans Dresseurs** (pêcheurs et passerelles au J22, lecture littérale de la V2) · **C** : seulement le raccord sous Ronflex, Route 12 entière au J22 | **A**. Le tronçon nord **est** le ponton : un ponton vide sonne creux, et le réveil de Ronflex ouvre alors une vraie boucle **Carmin ↔ Route 11 ↔ Lavanville**. Le J22 garde la Route 12 sud, les Routes 13 à 15 et Parmanie. **B** si tu tiens au découpage de la V2. |
| **L-4** | Ronflex de la Route 16 | **A** : **Route 16 est** construite (sortie ouest de Céladopole → Ronflex sur la voie basse → **façade du poste**, porte « À venir ») ; la haie du J20 est remplacée ; voie haute et arbre à Couper en décor dense (CS Vol hors jalon) · **B** : Ronflex directement au bout de la rue de Céladopole, à la place de la haie ; derrière lui, bord « ROUTE 16 — À venir » · **C** : reporter ce Ronflex au jalon de la Piste Cyclable (contredit la décision 5) | **A**. Géométrie RB, et le futur jalon n'aura qu'à ouvrir la porte du poste. **Aucun texte sur le Vélo** (pas de promesse, H-4). La seule récompense est la rencontre avec Ronflex : c'est assumé. |
| **L-5** | Règles du combat d'Ossatueur | **A** : RB strict (Ball consommée) · **B** : RB, sauf **Ball refusée avant le lancer, non consommée**, avec un message propre (comme K-8) | **B**. Concrètement : Sac autorisé ; **fuite possible** (calcul normal), puis recul d'une case et déclencheur réarmé ; **défaite** : réveil au Centre de Lavanville, déclencheur réarmé ; **victoire** : `ghost_marowak_calmed` ; **XP gagnée** et Ossatueur **vu** au Pokédex (RB). Message : « Ce Pokémon ne peut pas être capturé. » |
| **L-6** | Mise en scène de la révélation | **A** : RB (une ligne de texte) · **B** : A, plus, dans l'intro du combat, la **silhouette SPECTRE du J19 qui se dissout** en Ossatueur (fondu entre deux images existantes, sans image nouvelle) ; après la victoire, dans le monde : la brume du 6F se lève, une petite lumière monte, cri d'Ossatueur, puis les deux phrases RB | **B**. Émouvant et sobre, sans transformation horrifique, et sans art supplémentaire. « Réduire les animations » garde les textes et coupe la lumière qui monte. |
| **L-7** | Le 7F | **A** : 3 Sbires RB (équipes et niveaux **RB**, sans simulation), tous inévitables, rencontres sauvages RB au 7F (taux 15) · **B** : niveaux relevés par simulation | **A**. Ce sont des combats de récit, pas un défi : le joueur a battu Giovanni. Aucun chef. Une réplique au plus rappelle la défaite du boss, sans le nommer [D]. |
| **L-8** | Fuji : transition et remise de la Flûte | **A** : RB : texte de Fuji au 7F → **fondu et téléportation** dans sa maison (`change_map`) → remise de la Flûte · **B** : on redescend à pied, Fuji attend chez lui | **A**, avec une remise **idempotente** : `fuji_rescued` est posé **avant** la téléportation ; à l'arrivée dans la maison, une scène se lance si `fuji_rescued` et **pas de `poke_flute` dans le Sac** ; parler à Fuji la relance. Une sauvegarde interrompue n'importe où donne toujours exactement une Flûte. |
| **L-9** | Flûte en combat | **A** : RB strict (réveille l'équipe du joueur, et le sauvage ou **toute l'équipe adverse** ; prend le tour même sans effet) · **B** : A, mais **sans effet, elle ne prend pas le tour** (message, retour au menu) | **B**. L'effet reste RB, y compris le réveil des adversaires, ce qui en fait un vrai choix tactique. Elle ne soigne rien d'autre que le sommeil. |
| **L-10** | Flûte hors combat | **A** : RB : Sac → UTILISER sur une case voisine de Ronflex ; ailleurs « Quel air entraînant ! » · **B** : A, plus **parler à Ronflex** propose « Jouer de la Poké Flûte ? OUI / NON » ; ailleurs, **le compagnon réagit** par la bulle « ♪ » existante | **B**. Le raccourci évite d'aller fouiller le Sac au doigt. La bulle ne coûte aucune image. Message ailleurs : « Vous jouez de la Poké Flûte… Quel air entraînant ! » (RB ; la V2 propose « aucun Pokémon ne réagit », que la bulle du compagnon contredirait). |
| **L-11** | Ronflex : fuite et défaite | **A** : RB : retiré du monde quelle que soit l'issue · **B** : capture ou K.O. → retiré (V2) ; **fuite ou défaite → il se rendort sur place**, nouvelle chance | **B**. On ne perd pas pour toujours le seul Ronflex d'un côté de Kanto sur une erreur de doigt. Aucune duplication possible : la capture le retire. Après un K.O. : texte RB du retour aux montagnes. |
| **L-12** | Ronflex en combat | **A** : RB, N30, Coup d'Boule, Amnésie, Repos · **B** : niveau relevé | **A**. Amnésie est créée (Défense Spé. +2). Repos l'endort : la Flûte le réveille aussi, clin d'œil assumé. Pas d'écran de boss : intro sauvage ordinaire, précédée des textes de réveil. |
| **L-13** | Objectifs du tableau de bord | — | Après « retourner à la Tour Pokémon. » (J20) : « trouver M. Fuji, au sommet de la Tour. » (`ghost_marowak_calmed`, sauf `fuji_rescued`) ; « rendre visite à M. Fuji. » (`fuji_rescued`, pas de Flûte) ; **aucun objectif ensuite** (exploration libre ; rien ne montre Ronflex). |
| **L-14** | Lavanville et la Tour après le jalon | **A** : variantes de texte seulement · **B** : A, plus le 6F un peu moins brumeux et Osselait près de Fuji | **B** [D]. Textes : gardienne, enfant, homme et fille de la Maison de Fuji, gentleman du Centre. Osselait reste chez Fuji, sans don au joueur. Tour revisitable : rencontres normales, zone purifiée maintenue, Rocket battus le restent. |
| **L-15** | Portrait de Fuji | — | Les répliques RB, réécrites au ton du projet : il est venu de lui-même, il remercie, il parle de l'amour pour les Pokémon et du Pokédex. **Aucune allusion** à son passé, au Manoir Pokémon ni à Mewtwo. Planche PNJ à produire. |
| **L-16** | Découpage | **A** : V2 (21.0 + 6 lots) · **B** : **21.0** (grilles du 7F, de la Route 12 nord et de la Route 16 est, vues peintes, données, art) · **21A** « la Tour résolue » (Ossatueur, 7F, Fuji, remise de la Flûte) · **21B** « la Flûte » (usages, deux Ronflex, Routes 12 nord et 16 est, QA de bout en bout) | **B**, avec **deux validations S24** (21A, 21B), comme le J19 (K-20). La Flûte en combat et l'objet clé utilisable sont dans le même sous-jalon que leurs seuls usages. |

## 7. Drapeaux et sauvegarde (proposition, sans changement de version)

| Drapeau | Posé par |
|---|---|
| `ghost_marowak_calmed` | Victoire contre Ossatueur (issue `win` de l'étape) |
| `beaten_tower_rocket_1..3` | Sbires du 7F (mécanisme existant) |
| `fuji_rescued` | Scène du 7F, **avant** la téléportation |
| `got_poke_flute` | Même étape que la remise ; la scène teste aussi la **possession** de `poke_flute` (L-8) |
| `snorlax_route_11_awake` | Réveil du Ronflex est (nom du J17, gardé) |
| `snorlax_route_16_awake` | Réveil du Ronflex ouest |
| `snorlax_route_11_done`, `snorlax_route_16_done` | Capture ou K.O. (L-11) ; `*_awake` sans `*_done` = il se rendort |

**Tests d'interruption à prévoir** (plan technique) : sauvegarde relue après Ossatueur et avant le
7F ; entre le dernier Rocket et Fuji ; après `fuji_rescued` et avant la Flûte ; pendant et après
chaque Ronflex. Une build J20 rechargée en J21 : rien ne change avant l'arrivée au 6F.

## 8. Ce qui reste hors du J21

Route 12 sud et Routes 13 à 15 (J22) ; Piste Cyclable, Vélo, CS02 Vol, maison de la Route 16 ;
Safrania (accès, Thé, PNJ que RB permute au sauvetage) ; Osselait offert ; Ronflex compagnon ;
musique et sons.

## 9. Suite

1. Tu réponds par numéro (ex. : « L-3 B, le reste ok »).
2. J'écris `dossier-24-repos-des-esprits.md`, avec une section **Textes à valider** en un seul lot.
3. **En parallèle, sans attendre** : grilles `tools/plans/pokemon_tower_7f.txt`, `route_12.txt`
   (selon L-3) et `route_16.txt` (selon L-4) avec leur contrôle, puis prompts des vues peintes et
   fiche du lot d'art (Fuji, Ossatueur, Ronflex, icône de la Flûte).
4. Plan technique `docs/tech/jalon-21.md` ensuite ; le code après la clôture du J20.
