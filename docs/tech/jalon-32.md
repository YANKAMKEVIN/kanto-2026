# Jalon 32 — Un Kanto complet et vivant

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j32-v1-chatgpt.md` (7 arbitrages verrouillés). Arbitrages et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.
> **Arbitrages de collection N-1 à N-16 et textes associés validés par Kevin le 2026-10-24**
> (`docs/design/passes/j32-arbitrages-kevin.md`, sur `main`) : reportés au §7, en T3 et au §3
> le 2026-10-25 (session J32, branche `jalon-32`).

> Objectif jouable : **on peut finir le Pokédex dans une seule sauvegarde solo, échanger
> localement pour faire évoluer Kadabra, Machopeur, Gravalanch et Spectrum, rejouer la Ligue, le
> Safari et la pêche, et gérer ses Pokémon sans rien perdre.** Pas de nouvelle région, pas de
> campagne, pas de marqueur d'objectif.
>
> Mécaniques nouvelles : la **matrice d'obtention** des 151 espèces, le **terminal d'échange
> local**, le **suivi de collection** (Pokédex et stockage). Format de sauvegarde : champs
> ajoutés avec valeur par défaut (§2.4) ; un incrément de version se valide seul.

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Évolution par échange | `game/pokemon/evolution/evolution_rule.gd` connaît `Method.TRADE` ; Gravalanch → Grolem déclaré dans `data/pokemon/species/kanto.json` ; **aucune logique ne le déclenche** | Le terminal appelle ce chemin (T4) |
| Échanges PNJ | `InGameTrade` (logique pure) sur la branche `jalon-25` | S'en inspirer après la fusion du J25 |
| Espèces | Environ la moitié des 151 en données sur `main` ; le reste arrive jalon par jalon | La matrice se refait sur le `main` du moment (T1) |
| Pokédex et stockage | Écrans existants (`docs/tech/pokedex-refonte.md`) ; départs de débogage `storage_qa.json`, `team_full.json` | UX en retouche, pas en refonte |
| Fossiles, Dojo | Remise unique (J25), choix unique (J27) : **non annulés** | Solutions post-game compatibles seulement |
| Safari, pêche | J22–J23 | Contrôle de rejouabilité |
| Sauvegarde | `SaveSystem.VERSION = 7`, atomique | Nouveaux champs par `JsonFields.get_*` avec défaut |

### 0.0 Audit 32.0 (2026-10-25, branche `jalon-32` depuis `main` à `b3f12c6b`)

Relu sur `origin/main` et les branches non fusionnées `jalon-23`, `jalon-26` à `jalon-31`
(J24 et J25 sont déjà dans `main`). Matrice complète : `docs/tech/jalon-32-matrice.md`
(générée par `tools/audit_pokedex.py`).

| Point du tableau | Constat au 2026-10-25 |
|---|---|
| Évolution par échange | Toujours **aucun déclencheur** : `Method.TRADE` n'est lu que par `pokemon_data.gd` (validation). Déclarées : Kadabra → Alakazam (J26, J27 seulement), Gravalanch → Grolem. **Absentes des données** : Machopeur → Mackogneur, Spectrum → Ectoplasma (à ajouter avant T4) |
| Échanges PNJ | `InGameTrade` est dans `main` (J25 fusionné) : trois échanges de Cramois'Île. Les six de RB (N-14) sont à ajouter |
| Espèces | 126 espèces en données sur `main`, **147** en réunissant les branches ; sans données nulle part : Élektek, Porygon, Électhor, Minidraco, Mew |
| Fossiles | Le choix se fait **au J12** (Mont Sélénite, dossier 15 V-6), la résurrection au J24/J25 (`FossilLab`, `data/world/fossils.json`) ; Vieil Ambre indépendant |
| Dons | `PokemonGift` dans `main` (Évoli) ; Lokhlass (J26/J27), Kicklee **ou** Tygnon (J27) sur leurs branches |
| Rencontres fixes | `StaticEncounter` : Artikodin (`main`), Sulfura (J29), Mewtwo (J31), Ronflex ×2 (`main`) ; Ossatueur spectre exclu (`uncatchable`) |
| Sauvegarde | `SaveSystem.VERSION = 7` sur `main` et sur toutes les branches J26–J31 |
| Données d'évolution | Évolutions RB absentes de `species/` en plus des deux ci-dessus : Machoc → Machopeur, Voltorbe → Électrode, Noeunoeuf → Noadkoko, Smogo → Smogogo (valeurs par défaut RB, à corriger avec T2) |

**Bilan de la matrice** (toutes branches réunies) : **116 / 151** obtenables sans choix ni échange
local ; **18** seulement par un choix unique (starters, fossile, Dojo, Évoli) ; **2** seulement par
échange local (Alakazam, Grolem) ; **15** sans voie. Sur `main` seul : 102 / 16 / 1 / 32. Chaque
manque a sa règle N-x (§7) sauf trois trous de **données** (Mackogneur, Ectoplasma, Noadkoko).

### 0.1 Ce qui peut commencer tout de suite
- **T1** matrice des 151 (outil de lecture des données) et audit 32.0 ;
- **T2** règles d'obtention et d'échange en **logique pure** ;
- **T4** terminal d'échange en logique pure (sans écran) ;
- **T6** inventaire des objets et secrets (lecture des cartes et des données déjà fusionnées).

### 0.2 Ce qui attend
- Espèces des jalons non fusionnés (J21 à J31) : la matrice reste « à compléter ».
- Écran du terminal et UX Pokédex/stockage (T5, T7) : après la clôture de la passe systèmes 2.
- Solutions starters, fossiles, Dojo, Évoli, Mew, Centrale, voies RB manquantes : **décidées**
  (N-1 à N-16, §7) ; leur code touche des cartes des J20 à J31 et attend la fusion des J23 et
  J26 à J31 dans `main`.

## 1. Contrats

### 1.1 Une voie d'obtention testée par espèce
Chaque espèce a **au moins une** voie, **testée de bout en bout** (capture, évolution, cadeau,
fossile, échange PNJ, légendaire unique, exclusivité répartie, événement). Le Pokédex n'est pas
déclaré complétable tant qu'une espèce n'a pas sa voie testée. Distinction nette : « 151 dans le
Pokédex » et « 151 capturables en solo » ; le J32 vise la seconde.

### 1.2 Échange local atomique
Choix d'un Pokémon compatible, confirmation, puis **le même individu** évolué (surnom,
identifiant, statistiques individuelles, historique conservés). Tout réussit ou rien ne change.
Ni réseau, ni second appareil.

### 1.3 Rejouabilité par activité
Ligue : retour au Plateau, soins, cinq combats, une entrée de Panthéon par victoire, aucun reset du
post-game ni des légendaires. Safari et pêche rejouables. Dresseurs ordinaires **non rejouables**
(nouvelle mécanique, hors périmètre). Les objets uniques ne reviennent jamais.

### 1.4 Pas de guidage
Ni flèche vers une espèce manquante, ni minimap, ni localisation d'un Pokémon jamais rencontré. La
provenance se révèle selon ce que le joueur a découvert.

## 2. Tâches

### T1 — Audit 32.0 et matrice des 151 (Sonnet) — **fait le 2026-10-25**
`tools/audit_pokedex.py` (lecture seule, Python) lit, sur plusieurs révisions git (`--refs`, par
défaut `origin/main` et les branches J23, J26–J31) ou un dossier (`--dir`) :
`data/pokemon/species/`, `data/encounters/`, `data/fishing/`, `data/pokemon/starters.json`,
`data/cutscenes/` (étapes `gift_pokemon`, `wild_battle`, `give`), `data/world/fossils.json`,
`data/trades/`, `data/shops/`, et vérifie que chaque table sauvage a sa carte
(`game/world/maps/`). Choix uniques détectés : starters, fossile du Mont Sélénite, Dojo, espèce
à évolutions multiples reçue en un exemplaire (Évoli). Sorties : CSV en `build/audit_pokedex.csv`
(non suivi) et `docs/tech/jalon-32-matrice.md` (`--md`, suivi). Tests :
`python3 -m unittest tools/test_audit_pokedex.py` (11 tests, fixture en dossier temporaire).
À relancer sur le `main` du moment après chaque fusion (§0.2).

### T2 — Règles d'obtention (Opus, logique pure)
`CollectionRules` : pour chaque espèce, voies et conditions ; vérification « au moins une voie ».
Tests : le test lit la matrice et échoue si une espèce **déclarée comme obtenable** n'a pas de voie.

### T3 — Obstacles de collection (Opus) — **décisions de Kevin reçues (N-1 à N-16, 2026-10-24)**
Une solution par cas, sans annuler la première récompense ; tous les dons passent par
`PokemonGift` (équipe pleine → stockage), un drapeau d'événement par don ou rencontre, pas
d'incrément de version de sauvegarde attendu (à confirmer par l'architecte). Code **après la
fusion** des jalons qui portent les cartes touchées.

| Lot | Règle | Contenu | Cartes touchées |
|---|---|---|---|
| 32A | N-6 | Chen, après la Ligue : la Poké Ball restée sur la table, puis le second starter (N5 [D]) | Labo de Chen |
| 32B | N-7 | Le chercheur du Mont Sélénite, au Labo de Cramois'Île, après la Ligue : **son** fossile, une fois ; `FossilLab` fait le reste | Labo de Cramois'Île |
| 32C | N-8 | Le Maître du Dojo offre l'autre Poké Ball après la Ligue (pas de revanche) | Dojo (J27) |
| 32D | N-9 | Deux Évoli de plus dans la pièce du toit après la Ligue [D] | Résidence de Céladopole |
| 32E | N-10 | Union Rouge + Bleu des tables sauvages **ratifiée** : rien à refaire | — |
| 32F | N-12 | Groupe Super Canne RB du Parc Safari : Minidraco, Krabby, Psykokwak, Ramoloss N15 (données ; Draco et Dracolosse par niveau) **Fait le 2026-10-27** : Minidraco (`kanto_j32.json`, sans évolution : Draco et Dracolosse arrivent avec le J30) et table `super_rod_safari` (`data/fishing/water_rod.json`). Reste : Minidraco → Draco à la fusion du J30 (garde-fou `test_j32_data`) ; pêche dans le Parc non vue en jeu. | Parc Safari (J23) |
| 32G | N-11 | **Centrale** (Route 10, accès par Surf) : grille RB à valider, union Rouge + Bleu (Élektek, Raichu, Magnéti, Voltorbe…), **Électhor N50** (`StaticEncounter`), objets **Fait en données le 2026-10-27** : Élektek et Électhor (`kanto_j32.json`), table `power_plant_floor` (union R + B : Élektek et Raichu), scène fixe `zapdos` N50 (`j32_power_plant.json`, textes [D] à valider). **Reste** : la carte `power_plant` (grille RB à proposer et à faire valider par Kevin, accès par Surf depuis la Route 10, fond de combat, objets) ; tant qu'elle manque, la matrice ne compte ni Élektek ni Électhor. | Route 10, carte nouvelle |
| 32H | N-13 | Porygon confié par un employé de Sylphe SARL **après Giovanni** [D], une fois **Fait le 2026-10-27** : Porygon (`kanto_j32.json`, Affûtage et Conversion dans `moves/j32.json`, Conversion sans effet dans le moteur), employé `silph_co_porygon_giver` au 1F (24, 11) [D], présent après `silph_giovanni_defeated`, réplique 16 validée, don N26 [D] (niveau du lot du Casino RB) ; textes de réception et d'après-don [D] à valider. | Sylphe SARL (J26) |
| 32I | N-14 | Les six échanges PNJ de RB sur le modèle `InGameTrade` : Abra → M. Mime (Route 2), Têtarte → Lippoutou (Azuria), Piafabec → Canarticho (Carmin), Flagadoss → Excelangue (Route 18), Nidoran ♂ → Nidoran ♀ (souterrain Route 5), Nidorino → Nidorina (Route 11) ; surnoms VF RB à relever ; présence des maisons à vérifier (T6) **Fait le 2026-10-27 (5 sur 6)** : `data/trades/rb_trades.json` (`InGameTrade` charge maintenant tout `data/trades/`), scènes `j32_trade_*`, PNJ : Abra → M. Mime au poste de la Route 2 est (12, 4) [D, la maison d'échange de RB n'existe pas], Piafabec → Canarticho maison 2 de Carmin (12, 4), Flagadoss → Excelangue poste de la Route 18 (8, 4), Nidoran ♂ → ♀ entrée du souterrain de la Route 5 (7, 4), Nidorino → Nidorina au 2F du poste de la Route 12 (6, 5) [D, le poste de la Route 11 de RB n'existe pas] ; prénoms, surnoms (d'après l'anglais de RB : Marcel, Dux, Marc, Spot, Terry) et répliques [D] à valider. **Reste** : Têtarte → Lippoutou (Azuria) à la fusion du J30 (Lippoutou est une espèce du J30). | Routes 2, 5, 11, 18, Azuria, Carmin |
| 32J | N-1 à N-5 | Mew : rumeur d'un PNJ du port (présent dès le J15), camion du quai de Carmin, condition **150 autres espèces capturées**, rencontre unique **N30** [D], politique de Mewtwo (J31) pour fuite et K.O., « vu » à la rencontre ; Diplôme : porte « Bureau privé » ouverte après la Ligue, Diplôme à 150 (ne dit rien de Mew) ; drapeaux `mew_appeared`, `mew_resolved`, `diploma_received` [D] | Carmin, Résidence de Céladopole |
| 32K | données | Évolutions RB absentes de `species/` (§0.0). **Fait le 2026-10-25** : Machoc → Machopeur (N28), Voltorbe → Électrode (N30), Smogo → Smogogo (N35). **Reste**, impossible avant la fusion des J29/J30 (espèces cibles absentes de `main`, une évolution vers une espèce inconnue est une erreur de données) : Machopeur → Mackogneur et Spectrum → Ectoplasma (échange), Noeunoeuf → Noadkoko (Pierre Plante). Garde-fou : `tests/unit/test_j32_data.gd` échoue dès que les deux espèces d'une paire RB existent sans l'évolution | `data/pokemon/species/` |
| 32L | N-17 | Réapparition après la Ligue : `StaticRespawn.on_league_won` baisse le drapeau `done` des rencontres fixes (clé « static ») mises K.O. sans capture ; `CutsceneLibrary.get_static_encounters`. **Fait le 2026-10-25** (logique, tests). Aucun champ de sauvegarde. **Reste** : l'appel à la victoire contre le Maître (J30, `LeagueAttempt`) à l'intégration. Les Ronflex des routes ne reviennent pas (N-18) | — |
| 32M | N-18 | Ronflex d'après la Ligue : `StaticRespawn.apply_snorlax_rule` (appelée par `on_league_won`) lève `snorlax_post_league_present` si `snorlax_route_12_done` et `snorlax_route_16_done` sont posés sans `_caught` ; rebaisse `snorlax_post_league_done` s'il a été mis K.O. sans capture. Données : `data/cutscenes/j32_snorlax.json` (scène du J21, drapeaux `snorlax_post_league_*`), `data/dialogues/j32_snorlax.json` (répliques validées du J21, sans la page de première rencontre « au milieu du chemin », fausse ici ; le joueur a toujours la Flûte après la Ligue). Carte : Route 10, `FlagGate` « Ronflex » + `InteractPoint` 2 × 2 avec Flûte, ajoutés à la main dans `route_10.tscn` et dans `tools/build_route_10.gd` (position `ronflex_ligue` de `tools/plans/route_10.txt`) ; `InteractPoint`, `Interaction` et `FluteTarget` reçoivent `if_flags`. **Lieu [D], justification** : carte déjà dans `main` ; le belvédère (x 19..23, y 12..22) est une impasse du secteur nord, hors de tout chemin (ni Route 12 ni Route 16) ; « il retourne dans les montagnes » (réplique du J21) : la Route 10 est la route de montagne, au pied du Mont et de la Grotte Sombre, vue sur la Centrale. Accessible sans CS dès le J18. **Fait le 2026-10-25** (logique, données, carte, tests `test_j32_snorlax.gd`). **Reste** : l'appel à la victoire du J30 (comme 32L) | Route 10 |

Le test de complétion (T2, T9) relit `tools/audit_pokedex.py` : après les lots 32A à 32K, aucune
espèce ne doit rester « manque » ni « choix unique ».

### T4 — Échange local, logique (Opus) — **fait le 2026-10-25** (`game/systems/trade/local_trade.gd`, `tests/unit/test_local_trade.gd`)
Remplace le « Cordon d'échange » [D] du J14 (dossier 17 E-3, jamais codé, sans source) : le plan
J32 et N-15 priment. Sur `main`, seul Gravalanch → Grolem est déclaré ; Kadabra → Alakazam arrive
avec J26/J27, Machopeur → Mackogneur et Spectrum → Ectoplasma avec le reste du lot 32K.
`LocalTrade` : liste des Pokémon compatibles (Kadabra, Machopeur, Gravalanch, Spectrum), évolution
via `EvolutionRule` méthode `TRADE`, opération atomique (copie de travail validée, puis remplacement).
Tests : individu identique (surnom, IV, EV, PP, statut) ; équipe pleine sans perte ; interruption
simulée au milieu : état d'origine intact ; Pokémon incompatible refusé.

### T5 — Échange local, écran (après passe systèmes 2)
Terminal dans un Centre Pokémon (4 cases tactiles minimum, lisible au S24).

### T6 — Audit des secrets et objets (Sonnet)
Tableau par carte : objets visibles et cachés, CT/CS, pierres, cadeaux, échanges, pêche, Safari.
Source : données et cartes déjà fusionnées ; référence Rouge/Bleu. Les écarts vont dans un registre
`P0–P3`, sans correction de masse.

### T7 — UX Pokédex et stockage
Vus / capturés distincts, recherche par numéro et par nom, tableau de bord (espèces, vues,
capturées). Stockage : recherche, tri, déplacement sans risque. Grandes zones de contact.

### T8 — Rejouabilité (Sonnet)
Contrôle de la Ligue (J30), du Safari et de la pêche : aucun drapeau consommé à tort.

### T9 — Tests de complétion, migrations, performances, QA S24
Test « complétion » en suite complète ; ancienne sauvegarde chargée ; stockage très rempli
(mesure de la durée d'ouverture sur S24).

## 3. Textes
Validés par Kevin le 2026-10-21 : mise en scène du terminal sans texte long, deux lignes de
40 caractères au plus. Propositions **[D]** :
- Terminal : « Choisis un Pokémon à échanger. » ; confirmation : « Échanger [nom] ? » ;
  résultat : « [nom] a évolué ! » [D]
- Aucun texte pour les cartes de Pokédex : la fiche existante suffit. [D]

**Textes de collection validés par Kevin le 2026-10-24 (N-16)** : les 16 répliques du §5 de
`docs/design/passes/j32-arbitrages-kevin.md` (rumeur de Carmin 1–2, Mew 3, concepteur 4–7, Chen
8–10, chercheur 11–12, Maître du Dojo 13–14, Évoli 15, Porygon 16) font foi ; ne pas les recopier
ailleurs qu'en données de dialogue.

## 4. Critères d'acceptation
1. `audit_pokedex.py` liste 151 lignes ; aucune espèce « obtenable » sans voie testée.
2. Les 4 évolutions par échange se font localement, individu conservé, sans perte.
3. Ligue gagnée plusieurs fois, Panthéon sans écrasement ; Safari et pêche rejouables.
4. Ancienne sauvegarde v7 chargée ; collection non dépendante d'un second appareil.
5. Suite complète verte.

## 5. QA téléphone (S24)
Échange complet d'un Kadabra ; équipe pleine ; recherche dans un Pokédex bien rempli ; stockage
rempli ; une Ligue rejouée ; appli tuée au milieu d'un échange (état d'origine ou fini, jamais
entre les deux).

## 6. Risques
Duplication ou perte au transfert ; espèce déclarée mais inobtenable ; sauvegarde ancienne
écrasée ; confusion entre les voies « sauvages » et les exclusivités.

## 7. Décisions de Kevin (N-1 à N-16, validées le 2026-10-24)

Source : `docs/design/passes/j32-arbitrages-kevin.md` (toutes les recommandations retenues).

| N° | Sujet | Décision |
|---|---|---|
| N-1 | Mew en solo | **Rencontre secrète** unique en post-game, sans annonce |
| N-2 | Condition | Les **150 autres espèces capturées** (le moment du Diplôme RB) |
| N-3 | Lieu | Le **vieux camion du quai de Carmin** + une rumeur de PNJ du port |
| N-4 | Rencontre | N30 [D], unique, politique de Mewtwo, « vu » à la rencontre |
| N-5 | Diplôme | « Bureau privé » ouvert après la Ligue, concepteur RB, Diplôme à 150 |
| N-6 | Starters non choisis | Chen, après la Ligue, au labo (deux dons) |
| N-7 | Second fossile | Le chercheur du Mont Sélénite, au Labo de Cramois'Île, une fois |
| N-8 | Kicklee / Tygnon | Le Maître offre l'autre après la Ligue |
| N-9 | Évoli | Deux Évoli de plus après la Ligue |
| N-10 | Exclusivités | Union Rouge + Bleu ratifiée |
| N-11 | Centrale et Électhor | Lot **32G** dans le J32 |
| N-12 | Minidraco | Super Canne RB au Parc Safari (données) |
| N-13 | Porygon | Sylphe SARL après Giovanni |
| N-14 | Échanges PNJ RB | Les six |
| N-15 | Terminal d'échange local | Dans **tous** les Centres Pokémon |
| N-16 | Textes | Lot de 16 répliques validé (§3) |
| **N-17** | Pokémon unique mis K.O. (validé par Kevin le **2026-10-25**) | **Réapparaît après la Ligue** : Artikodin, Sulfura, Électhor, Mewtwo, Mew reviennent à leur place à chaque victoire à la Ligue s'ils ont été mis K.O. sans être capturés ; le Pokédex reste toujours complétable. Logique : `StaticRespawn` (fait, §T3 lot 32L) |
| **N-18** | Ronflex (validé par Kevin le **2026-10-25**) | **Un Ronflex après la Ligue** : les deux Ronflex des routes ne reviennent pas ; si tous les deux ont été mis K.O. sans capture, un troisième Ronflex endormi apparaît après la Ligue, hors du chemin, et se capture avec la Poké Flûte (mêmes scène et répliques que le J21) ; mis K.O., il revient à la victoire suivante (N-17). Lieu [D] : **bout du belvédère de la Route 10**, cases (21..22, 19..20) (lot 32M) |

Anciens points ouverts : 1 → N-1 à N-5 ; 2 → N-6 (le [D] « échange PNJ » est écarté) ; 3 → N-7 (la
« machine » est écartée) ; 4 → N-8 ; 5 → N-10 et N-11 ; 6 → N-15.
