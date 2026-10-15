# Jalon 15 — Route 5, passage souterrain, Route 6 et Carmin-sur-Mer

> Objectif jouable sur le téléphone : **le voyage vers la mer**. Depuis la sortie sud d'Azuria
> (relais du J14), la **Route 5** verdoyante, sans Dresseur ; la **Pension Pokémon** (un Pokémon à
> la fois, 1 XP par pas, prix au retrait, capacités puis évolution proposées au retrait, soin
> complet) ; le **poste de garde** fermé vers Safrania ; le **passage souterrain**, calme, sans
> rencontre, avec une **Guérison cachée** ; la **Route 6** (six Dresseurs, dont Chloé inévitable,
> un étang, le second poste fermé, la première vue sur le port) ; **Carmin-sur-Mer** (Centre,
> Boutique avec la **Super Potion**, Arène fermée par un **jeune arbre**, Fan Club, maison du
> Pêcheur, deux maisons, le **quai et le S.S. Anne** gardé par un marin), et « ROUTE 11 — À venir ».
>
> Mécaniques nouvelles : **Pension** (état sauvegardé, compteur de pas, retrait avec montée de
> niveau, capacités et évolution **hors combat**), **sauvegarde v7**, **Jackpot** (argent ramassé
> en fin de combat), deux objets de soin (Super Potion, Guérison), une carte « ni grotte ni
> intérieur » (le souterrain). Tout le reste est du contenu sur des systèmes existants.

**Pré-requis.** Dossier 18 **verrouillé** (2026-10-12 : V-1 à V-4, F-1 à F-16, textes §15 validés,
grilles v1 validées, Route 5 v2 à faire) : c'est la **source de vérité**. Organisation imposée par
Kevin (2026-10-11/12) : **une session par jalon** ; J11 (reste 11C et 11D), J12, J13 et J14
avancent **en parallèle** et ne sont pas fusionnés. Ce plan sépare donc les tâches **(A)**,
lançables maintenant depuis `main` + `jalon-15`, des tâches **(B)**, qui attendent un système
précis d'un autre jalon (§1.2), avec pour chacune une façon d'avancer sans conflit.

Plan écrit sur `docs/plan-j15` depuis `jalon-15` à `bbbddd4` (dossier, grilles v1, 15.0 « logique
pure » fusionnés ; base `main` à `a34e433`). **Code lu** : `origin/main` à **`ee5d5c9`** (J11 :
**11.0 sauvegarde v6, 11A statuts et remèdes, 11B CT et Patience fusionnés**) ; J12 lu, pas
modifié, sur `jalon-12` à `5b3fe9b` (T1–T4, T6–T10 faits ; **aucune tâche de code « après le
J11 »**, T11 et suivantes) et `docs/tech/jalon-12.md` ; J13 sur `jalon-13` à `2a1fe23` et
`docs/plan-j13` à `9479716` ; J14 sur `docs/dossier-17-j14` à `1b08c49` (dossier verrouillé,
**aucun plan technique**). Quand un nom n'existe que dans un plan, c'est écrit « (plan) ».
**Chaque tâche d'architecture commence par réaligner ce plan sur le code du moment.**

Références : `CLAUDE.md` (règles 1 à 10), `docs/design/dossier-18-carmin-sur-mer.md`,
`docs/design/passes/j15-v2-alignement.md` (audit §2), `dossier-14-systemes-j11.md` (compagnon,
statuts), `jalon-12.md` (objets cachés §2.8, grotte §2.3, lumière §2.4, évolution §2.9), modèle de
forme `jalon-12.md` et `jalon-10.md`.

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe pour chaque besoin du dossier

`main` = `origin/main` à `ee5d5c9`. **Attention** : la branche locale `main` du dépôt est restée à
`a34e433` (avant le J11) ; `jalon-15` aussi. Toutes les références ci-dessous sont celles
d'`origin/main`.

| Besoin (dossier 18) | Existant sur `main` (fichier:ligne) | Apporté par un autre jalon (non fusionné) | Manque |
|---|---|---|---|
| Règles de la Pension | `jalon-15` : `game/systems/daycare/` — `Daycare` (état, XP en attente plafonnée au niveau 100, `to_dict`/`from_dict`), `DaycareRules` (dépôt, prix, paiement, retrait, refus `EMPTY OCCUPIED PARTY_FULL LAST_POKEMON LAST_ABLE NOT_FOUND NO_MONEY`), `DaycarePreview`, `DaycareWithdrawal` (capacités dues dans l'ordre, évolution proposée), `DaycareConfig` ← `data/daycare/daycare.json` ; `tests/unit/test_daycare.gd` (34 tests) | — | branchement : état dans `GameState`, sauvegarde, pas, écrans |
| Compteur de pas | `Player.moved(cell)` (`player.gd:13`), `bumped` (l. 15), `is_input_enabled()` (l. 161) ; filtre des pas scriptés dans `SceneRouter._on_player_moved` (`scene_router.gd:379-382`) et `EncounterDirector` (`encounter_director.gd:100, 119`) | — | un écouteur de plus (§2.5) |
| Sauvegarde | **v6** (`save_system.gd:35`, règle d'incrément l. 21-26, `upgrade` l. 160) ; `GameState.to_dict` (l. 264), `load_dict` (l. 303) ; `ensure_unique_uids()` (l. 384 : **équipe + Stockage seulement**) ; `companion_uid` (l. 105), `get_companion` / `set_companion` (l. 402, 413) | J12, J13, J14 : **aucune version nouvelle** (preuves : `jalon-12.md` §2.20, `jalon-13.md` §2.19, dossier 17 §1 n° 17) | **v7** : champ `daycare`, migration v6 → v7, Pension dans `ensure_unique_uids` (§2.6) |
| Argent | `GameState.add_money` / `spend_money` (l. 236, 246 ; refus sans effet), `MONEY_MAX` (l. 43) ; garde `test_shop_rules.test_only_the_shop_spends_money` (`test_shop_rules.gd:201` : seuls `game_state.gd` et `shop_rules.gd` peuvent écrire `spend_money`) | — | la Pension dans la liste blanche (§2.5) |
| Dialogues de service | `DialogueLibrary.ACTIONS = [heal, center_heal, open_shop, open_storage]` (`dialogue_library.gd:35`) ; `DialogueRunner.action_handler` (`dialogue_runner.gd:53`, attendu dans `_finish`, l. 342) ; `play` refuse si un dialogue tourne (l. 123) ; Boutique et Stockage ouverts **à la fin** du dialogue (`boot.gd:1107-1121`, `_pending_shop`, `_pending_storage`) ; `DialogueChoice` (Oui / Non, `confirm_action`) | J12 T23 (plan) : `confirm_cutscene` ; J13 T17 (plan) : `confirm_set` / `cancel_set` — mêmes fichiers | action `open_daycare`, dialogue « action seule » (§2.5) |
| Jetons de texte | `DialogueTokens.KNOWN = [first_wild_species, player, rival]` (`dialogue_tokens.gd:19-26`) ; une page dont un jeton n'a pas de valeur est **omise** ; valeurs lues par `Boot._dialogue_token_values` (`boot.gd:1148`) | — | `{pokemon}`, `{levels}`, `{price}` (§2.5) |
| Apprendre hors combat | `MoveLearnPrompt.teach(pokemon, party_index, move_id, banner, host)` (`move_learn_prompt.gd:48`) ; **hôte hors combat déjà créé par le J11** : `TmLearnOverlay` (`game/ui/bag/tm_learn_overlay.gd`, voile + `BattleMessageBanner` + hôte des panneaux), utilisé par `Boot._on_tm_learn_requested` (`boot.gd:1249-1266`) | — | rien de neuf : l'audit (passe §2 n° 5) est dépassé |
| Évolution hors combat | `EvolutionDirector.play(candidates, party)` (`evolution_director.gd:66`) appartient à **Boot** (`boot.gd:231-243`), sans dépendance au combat ; ARRÊTER et retour Android (`handle_back`, l. 89, relayé par `BattleDirector.handle_back`) ; `Evolution.level_up_target` (`evolution.gd:14`), `evolve` (l. 70) | J11 11C : séquence courte ; J12 T23 (plan) : `play_item`, `cancellable`, `evolution_applied` (pierres, **non annulables**) | rien : la Pension propose une évolution **annulable** (F-3), comme en fin de combat |
| Choix d'un Pokémon | `PartyPicker` (`game/ui/bag/party_picker.gd` : cibles, raison du refus, `target_chosen`, `target_refused`, `back_requested`) ; texte de refus du Stockage `StorageViews.LAST_ABLE_TEXT` (`storage_views.gd:29`) | — | un hôte « Pension » (§2.5) |
| Cartes extérieures | `tools/pewter_map_kit.gd` (sol logique, forêt `DenseForest`, hautes herbes, panneaux, décalcomanies) ; `PaintedGround` à **trois textures fixes** | J12 T7 : `PaintedGround` réglable, `LightGlow`, `CaveLibrary` (`jalon-12`) ; J13 : eau de canal à texture réglable (plan) | `build_route_5.gd`, `build_route_6.gd`, `build_vermilion_city.gd`, `build_underground_path.gd` |
| Intérieurs | `tools/build_painted_interiors.gd` : `_pokemon_center` (l. 132), `_poke_mart` (l. 189), `_forest_gate(side)` (l. 222, 10 × 8, propre à la forêt), `_pewter_house` (l. 593) | J12 : `mt_moon_center` ; J13 : pièces d'Azuria (plan) | 12 pièces (§2.2) |
| Raccords « À venir » | `WarpPoint.coming_soon` (`warp_point.gd:20`) | J14 (dossier §3.3) : bord sud d'Azuria → « ROUTE 5 — À venir », `route_5` / `from_cerulean` réservés | — |
| Objets cachés | ancien modèle : `EventTriggerPoint` **sur la case** ; `InteractPoint` sans drapeau (`interact_point.gd:11-17`) | **J12 T17 (plan, non codé)** : `InteractPoint.unless_flags` (§2.8 de `jalon-12.md`) | — |
| Catégorie du souterrain | `GameMap.interior` (booléen) ; `interiors.json` ; préchargement des voisines | J12 T7 (`jalon-12`) : `data/world/caves.json` + `CaveLibrary` (Corde Sortie) | rien : `interior = false`, hors `caves.json` (§2.3) |
| Lumière | `lighting.json` : `golden_hour`, `interior_warm` (sans `cast_shadow` ni `rim` : clés facultatives), `forest` | J12 : profils `cave_*`, `LightGlow` + `light_glows.json` (`jalon-12`) | profil `underground` ; appliques (§2.3) |
| Espèces, capacités | 38 espèces (`kanto.json`) ; 67 capacités ; `PokemonData` lit **tous** les `.json` de `species/` et `moves/` (`pokemon_data.gd:7-8`) ; Bite, Grincement, Combo-Griffe, Tranche, Griffe, Rugissement existent | J12 : 12 espèces, 21 capacités ; **J13 T11 (plan §2.15) : Mystherbe, Ortide, Chétiflor, Boustiflor** (D-8 retenu), évolutions au niveau 21 | Miaouss, Persan, Jackpot |
| Effet de capacité | `MoveEffect.Kind` (`move_effect.gd:37-48` : `STAT_STAGE … BIDE`) | J12 T13 (plan) : `DRAIN TRAP DISABLE REST SELF_KO` **en fin d'enum** | `COINS` (Jackpot), après ceux du J12 |
| Argent de fin de combat | `BattleConclusion.resolve(trainer, outcome, last_foe_level)` (`battle_conclusion.gd:25-37`, **sauvage : rien**) ; `BattleDirector` verse `prize_money` (`battle_director.gd:262-273`) ; `BattleText.prize_line` | — | pièces du Jackpot (§2.7.3) |
| Objets | 9 objets (`items.json`) ; `ItemLibrary` lit **tous** les `.json` de `data/items/` (`item_library.gd:44`) ; soin = `heal_amount` et / ou `cures` | J12 : Corde Sortie, Pierre Lune… ; J14 : `ss_ticket`, `rare_candy` (dossier §5) | Super Potion, Guérison |
| Boutiques | `ShopLibrary` lit un dossier (`shop_library.gd:33`) ; stock `if` / `unless` | J13 (plan §2.5) : `cerulean_mart` = Poké Ball, Potion, Antidote, **Corde Sortie (J12)**, Anti-Para, Réveil, Antigel, Anti-Brûle | `vermilion_mart` |
| Dresseurs | `TrainerLibrary` lit un dossier (`trainer_library.gd:55`) ; `prize_money` fixe ; bloc `trainer` des PNJ ; IA `random` | J12 T17 (plan) : `rematch`, `leave` (inutiles ici) | 6 Dresseurs |
| Gardes qui bloquent | `route_3_guard` (scène de recul, `data/cutscenes/pewter_city.json:12`) ; modèle `guard` | — | deux gardes (§2.4) |
| Zones, Carte | `zones.json` : `vermilion_city` et `saffron_city` sans carte (l. 60, 63) ; **ni `route_5`, ni `route_6`, ni souterrain** ; `kanto_placeholder_areas.json` : `vermilion_city` seule (l. 20) | J13/J14 : Azuria, Routes 24/25 (fins de fichier) | 3 zones, 2 aires |
| Personnages | `old_man`, `guard`, `scout`, `camper`, `lass`, `nurse`, `clerk`, `haru` (planche `pecheur`), `traveler`, `hiker`, `kid`, `mountaineer`… ; Pokémon d'ambiance peints : 13 espèces (Roucool, Rattata…) | J12 : `lass_young`, Sbires ; J13 : vendeur, Nageurs (plan) | marin, docker, président du Fan Club |
| Compagnon | `companion_uid` en sauvegarde seulement | **J11 11D** : `CompanionRules`, `CompanionTrail`, `companions.json` (branche du J11, plan `jalon-11-compagnon.md`) | règle « déposé = effacé » (§2.5) ; planche de Miaouss |
| Départs de QA | `tools/debug_start/*.json` (`DebugStart`) | — | champ `daycare`, départs du J15 |

### 0.2 Écarts et trous constatés

1. **L'audit de la passe (§2) est en partie dépassé** : v6, `Pokemon.uid`, `ensure_unique_uids`,
   `companion_uid`, paralysie, sommeil, remèdes **et un hôte hors combat de `MoveLearnPrompt`**
   (`TmLearnOverlay`) sont sur `main`. Du J11, il ne reste comme dépendance que **11D** (compagnon
   visible) — et la Pension n'en a pas besoin pour effacer le compagnon (`set_companion(null)`).
2. **Le dialogue ne peut pas en jouer un autre pendant son action** : l'action d'une variante est
   attendue **avant** que `_running` retombe (`dialogue_runner.gd:342-360`) et `play` refuse
   pendant ce temps (l. 123). La Pension enchaîne donc ses répliques **après** la fin du dialogue
   du gardien, comme la Boutique et le Stockage (`_pending_shop`) : §2.5.
3. **Choix du texte selon l'état** : les variantes de dialogue ne lisent que des drapeaux. Les
   répliques T-2 / T-7 / T-8 / T-9 dépendent de l'état de la Pension (vide, niveaux, équipe
   pleine) : c'est le directeur de la Pension qui choisit **l'identifiant** du dialogue à jouer,
   les textes restent dans `data/dialogues/` (§2.5). Aucun drapeau « miroir » de l'état.
4. **Le gardien n'a pas de réplique d'accueil à lui** (T-2 et T-8 ouvrent la conversation) : le
   dialogue du PNJ doit être **une action sans page** (`open_daycare`). Petit ajout à
   `DialogueLibrary` (variante sans page permise si elle a une action) et `DialogueRunner` (sans
   page : pas de boîte, l'action puis la fin).
5. **Jackpot hors moteur pour le sauvage** : `BattleConclusion.resolve` rend tout de suite pour un
   combat sauvage (l. 30-32). Les pièces se ramassent aussi contre un sauvage : le paramètre des
   pièces s'ajoute avant ce retour.
6. **Textes non couverts par le §15** (règle : aucun texte inventé dans le jeu) — brouillons à
   l'**annexe A**, à valider en une passe (**Q-1**) : messages de combat du Jackpot ; descriptions
   et sous-titres des zones ; panneaux présents dans les grilles mais absents du §15 (carrefour,
   quai, poste de la Route 6, panneau de la Route 6 côté Carmin) ; PNJ des grilles sans texte
   (promeneur de la Route 6, enfant de Carmin, membres du Fan Club, habitants des deux maisons :
   « le navire ») ; sous-titre du panneau de l'Arène (T-30 « à proposer ») ; note de Pokédex de
   la forme de base (Miaouss), comme aux J10 et J12.
7. **Panneaux : le §15 prime sur les commentaires des grilles** (T-13 « ROUTE 5 — Azuria ↔
   Safrania » ; la grille écrit « Azuria ← → Carmin-sur-Mer »). T-20 « ROUTE 6 — Safrania ↔
   Carmin-sur-Mer » va sur le panneau `panneau_route` (24, 52) de la Route 6 ; T-25 sur
   `panneau_ville` de Carmin.
8. **Postes vers Safrania — deux formes** (la grille fait foi pour la géométrie) : Route 5, un
   **intérieur** 10 × 8 (porte (34, 44)) dont le garde bloque la porte nord ; Route 6, **un garde
   devant la porte extérieure** (36, 8) et un déclencheur (`verrou_safrania`), sans intérieur. Le
   dossier §7 disait « modèle `_forest_gate` » pour les deux ; seule la Route 5 l'utilise.
9. **Prénoms en double** (défauts [D] du dossier §6.2, aucun texte validé ne les nomme) :
   « Campeur Lucas » (J15) et « Nageur Lucas » (J13) ; « Scout Timéo » (J15) et « Scout Timéo »
   (J13, Route 24). Défaut : **Campeur Gabin** (`route_6_camper_gabin`) et **Scout Basile**
   (`route_6_scout_basile`) ; attributs `trainer=` de `route_6.txt` mis à jour par la tâche de la
   carte (aucune géométrie touchée).
10. **Objectifs** : le format de `objectives.json` est en minuscule, préfixé par l'interface
    (« continuer vers la Route 3. ») : T-42 s'écrit « rejoindre Carmin-sur-Mer, au sud. » et
    « explorer Carmin-sur-Mer. » (adaptation typographique, comme au J12).
11. **Le souterrain n'a « pas de ciel »** mais n'est pas une grotte : `CaveLibrary.has_sky` (J12)
    le dirait « à ciel ouvert ». Aucun usage avant le jour/nuit (phase 10) : **rien à coder au
    J15**, passation notée pour la phase 10.
12. **Route 5 v2** (grille à faire serpenter, dossier §13.1) et **vues générales peintes** sont en
    cours sur `j15-grille-route5-v2` et `j15-vues-generales` : la carte de la Route 5 attend leur
    validation ; Route 6, souterrain et Carmin attendent leur vue générale.

### 0.3 Dépendances envers les autres jalons (vrais noms)

| Jalon | Système attendu | Nom réel / état | Utilisé par |
|---|---|---|---|
| J11 | sauvegarde v6, `Pokemon.uid`, `ensure_unique_uids`, `companion_uid` | **sur `main`** | rien à attendre |
| J11 | paralysie, sommeil (Papilusion de Basile), remèdes | **sur `main`** (11A) | rien à attendre |
| J11 | compagnon visible (11D) | branche du J11 : `CompanionRules`, `CompanionTrail`, `data/pokemon/companions.json` (`species`, `contexts`) | planche de Miaouss branchée, compagnon dans le souterrain (T20) |
| J12 | objets cachés « face à un indice » | **plan seulement** : `InteractPoint.unless_flags` (`jalon-12.md` §2.8, T17) | Guérison, Antidote, Super Potion cachés (T19) |
| J12 | sol peint réglable, halos | **code sur `jalon-12`** (T7) : `PaintedGround` (`base_texture`, `r_texture`, `g_texture`), `LightGlow` + `data/world/light_glows.json` | carte du souterrain (T18) |
| J12 | catégorie grotte | **code sur `jalon-12`** : `CaveLibrary`, `data/world/caves.json` | rien (le souterrain n'y est **pas**) ; test « hors `caves.json` » (T18) |
| J12 | genres d'effet du moteur | **plan** : `MoveEffect.Kind += DRAIN TRAP DISABLE REST SELF_KO` (T13) | numéro de `COINS` (T17) |
| J12 | Corde Sortie | **plan** : `escape_rope` (T12) | stock de Carmin (T16) |
| J12 | évolution hors combat | **plan** : `EvolutionDirector.play_item`, `EvolutionCandidate.cancellable`, `evolution_applied` (T23) | **rien** : la Pension utilise `play` (annulable), déjà sur `main` |
| J13 | Mystherbe, Chétiflor, Ortide, Boustiflor | **plan** (`jalon-13.md` §2.15, T11) : `oddish`, `gloom`, `bellsprout`, `weepinbell`, évolutions niveau 21 | rencontres des Routes 5 et 6 (T16) |
| J13 | stock d'Azuria | **plan** (`jalon-13.md` §2.5) : `data/shops/cerulean_mart.json` | stock de Carmin (déjà recopié ici, §2.7.6) |
| J13 | carte d'Azuria | **code sur `jalon-13`** (`cerulean_city`) | raccord nord (T21) |
| J14 | raccord sud d'Azuria, barrage levé | **sur `main`** (2026-10-15, `jalon-14.md` §9.4) : trois cases PUSH ↓ (31..33, 40) de `cerulean_city` → `route_5` / `from_cerulean_w|c|e` (réservés), `coming_soon` « Route 5 » (« ROUTE 5 — À venir ») ; arrivées `from_route_5_w|c|e` (31..33, 40) tournées ↑ ; barrage du policier (scène `cerulean_south_guard`) levé si `cerulean_rocket_beaten`, puis `cerulean_south_guard_left` | raccord nord (T21) |
| J14 | Passe Bateau | **sur `main`** : `ss_ticket` (objet clé, `items_j14.json`, jamais consommé, sans UTILISER), donné par Léo (`got_ss_ticket`) ; objectif `ss_anne` | test « avec Passe Bateau » (T21) |
| J14 | Super Bonbon | **sur `main`** : `RareCandy` (`game/items/rare_candy.gd`) + déroulé dans `boot.gd` (blocage `RARE_CANDY`), **sans** `OffBattleLevelUp` ; seul le voile `_learn_overlay()` (`TmLearnOverlay`) est partagé avec la Pension (fusion `j15-sync-j14`) | rien ; réunir les deux séquences n'est pas demandé (à noter au T23) |

---

## 1. Découpage

### 1.1 Sous-jalons et validations (F-15)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **15.0** | logique pure de la Pension (**fait**) ; **sauvegarde v7**, migration v6 → v7, `GameState.daycare`, Pension dans `ensure_unique_uids` | **seule** (système risqué) : Mac puis téléphone (vraie partie v6 migrée, refus par une build v6, départ avec un Pokémon déposé) |
| **15A** | Route 5 (décor, raccord, PNJ, objets, rencontres), **Pension sur la carte** (dialogues, dépôt, retrait, compteur de pas, capacités, évolution), poste nord, bâtiments d'entrée, **souterrain** et **Guérison cachée** | téléphone |
| **15B** | Route 6 (6 Dresseurs, étang, poste est), Carmin (Centre, Boutique, Arène et arbre, Fan Club, Pêcheur, maisons, quai et S.S. Anne), Route 11 « À venir », **Jackpot**, objectifs ; **QA finale** et clôture | téléphone + fusion |

- **Jamais trois systèmes à la fois** : 15.0 = la sauvegarde seule ; 15A = un système (Pension à
  l'écran) + des cartes sur des systèmes existants (l'objet caché est celui du J12) ; 15B = un
  petit système (Jackpot) + du contenu.
- **Ce qui bloque les sessions téléphone** : 15.0 rien ; **15A** attend J12 (objets cachés, sol et
  halos du souterrain) et J13 (espèces des rencontres de la Route 5) ; **15B** attend J12 (Jackpot
  après les genres d'effet, Corde Sortie au stock) et J13 (rencontres). Le raccord réel avec
  Azuria (J13, J14) se vérifie à la QA finale si les deux sont fusionnés, sinon par un départ de
  débogage (le bord nord reste « AZURIA — À venir »).

### 1.2 « Maintenant » (A) ou « après un autre jalon » (B)

> **Mise à jour du 2026-10-15 — J14 dans `main`, fusionné dans le J15** (branche `j15-sync-j14`
> depuis `jalon-15` à `d7361eb`, `origin/main` à `2bd6bbf` : J14 `1d3bb84` + décisions de Kevin
> `1e1c9a5`, `2bd6bbf`). Le J14 est resté en sauvegarde **v6** : le J15 garde la **v7** (§2.6).
> **Il n'y a plus de tâche (B)** : **T21 passe en (A)**. Vrais noms (`jalon-14.md` §9.4) :
>
> | Tâche | Devient | Ce qui existe maintenant (vrais noms) | Ce qui reste à attendre |
> |---|---|---|---|
> | **T21** raccord nord réel + Passe Bateau | **(A)** | `cerulean_city` : trois warps PUSH ↓ `Route5W|C|E` en (31..33, 40) → `route_5` / `from_cerulean_w|c|e`, avec `coming_soon` « Route 5 » (« ROUTE 5 — À venir », `SOUTH_COMING_SOON` de `tools/build_cerulean_city.gd`) à retirer ; arrivées `from_route_5_w|c|e` (31..33, 40) tournées ↑, posées ; barrage : scène `cerulean_south_guard` (déclencheur (31..33, 37)), jouée si `cerulean_rocket_beaten`, pose `cerulean_south_guard_left` ; Passe Bateau `ss_ticket` (objet clé), drapeau `got_ss_ticket` ; tests rattachés au « À venir » : `test_coming_soon`, `test_companion_coming_soon` (à déplacer), `test_cerulean_city` | la carte `route_5` (T13) ; **écart de la grille** `tools/plans/route_5.txt` (§2.1) |
>
> **Ordre libre des deux histoires du J14** : le barrage dépend **seulement** du Rocket
> (`cerulean_rocket_beaten`), pas de Léo. On peut donc arriver sur la Route 5 (et à Carmin)
> **avec ou sans** `ss_ticket`, avant ou après la visite à Léo : rien du J15 ne doit supposer
> `got_ss_ticket`, `bill_restored` ni le Badge Cascade sur la Route 5 (tests T21 dans les deux cas).
> Bug du moteur « combat gagné avec toute l'équipe K.O. » (`jalon-14.md` §9.2) : **confié au J15**
> par Kevin le 2026-10-15 → tâche **T24** (A, ci-dessous et §3), sans dépendance.
>
> | Tâche | Devient | Ce qui existe maintenant (vrais noms) | Ce qui reste à attendre |
> |---|---|---|---|
> | **T24** défaite quand toute l'équipe du joueur est K.O. | **(A)** | `Battle._check_end` (`game/battle/battle.gd`), `BattleConclusion.resolve`, `PayDayPurse.is_collected`, `DefeatRecovery.recover`, `TrainerWatcher`, garde de `BattleDirector.run` / `run_request` | rien |

> **Mise à jour du 2026-10-14 — J12 et J13 dans `main`, fusionnés dans le J15** (branche
> `j15-sync-j12` depuis `jalon-15` à `2b224be`, `origin/main` à `4f0ee90` : J12 `2b2745f` + J13).
> La sauvegarde reste en **v7** (J12 et J13 n'ont pas de version). Bilan des tâches (B), avec les
> **vrais noms** du code fusionné (le tableau ci-dessous est corrigé en conséquence) :
>
> | Tâche | Devient | Ce qui existe maintenant (vrais noms) | Ce qui reste à attendre |
> |---|---|---|---|
> | **T16** rencontres + Corde Sortie au stock | **(A)** | espèces `oddish`, `gloom`, `bellsprout`, `weepinbell` dans `data/pokemon/species/kanto.json` (J13) ; objet `escape_rope` dans `data/items/mt_moon.json` (J12), déjà au stock de `pewter_mart.json` et `cerulean_mart.json` ; tables prêtes dans `tools/pending_data/j15/encounters/route_5.json`, `route_6.json` → `data/encounters/` (modèle `route_3.json`, `route_4.json`) ; ajouter `{ "item": "escape_rope" }` à `data/shops/vermilion_mart.json` (et à `test_vermilion_data`) | rien d'un autre jalon ; les tables ne servent qu'une fois les cartes `route_5` / `route_6` posées (T13, T14) |
> | **T17** Jackpot dans le moteur | **(A)** pour le moteur | `MoveEffect.Kind` finit par `DRAIN, TRAP, DISABLE, REST, SELF_KO` (`game/pokemon/moves/move_effect.gd:52`) → `COINS` **après `SELF_KO`** + entrée `"coins"` dans `MoveEffect.KIND_NAMES` ; `BattleEvent.Kind` finit par `… RESTED, SELF_KO` (`battle_event.gd:121`) → `COINS_SCATTERED` en fin ; `BattleConclusion.resolve(trainer, outcome, last_foe_level := 0)` (`battle_conclusion.gd:24`) → paramètre `coins` en fin ; `PayDayPurse` (`game/battle/pay_day_purse.gd`, déjà là) ; `pay_day` de `data/pokemon/moves/vermilion.json` perd `pending_effects` (lu par `PokemonData`, `pokemon_data.gd:492`) ; messages dans `data/battle/messages.json` | **Q-1** (annexe A) pour les deux messages du Jackpot : moteur et tests faisables avant, textes branchés après validation |
> | **T18** carte du souterrain | **(A)** côté moteur | `PaintedGround.base_texture` / `r_texture` / `g_texture` (`game/world/ground/painted_ground.gd`) ; `LightGlow.glow_type` (`game/world/lighting/light_glow.gd`) + types `lamp shaft shard projector beam` de `data/world/light_glows.json` → `sconce` **en fin** ; `LightGlowLibrary.MAX_PER_MAP` ; boîte à outils `tools/cave_map_kit.gd` (sol `Ground` logique, escaliers `WarpPoint` STEP_ON, halos) et voile `tools/cave_shade.gd` (facultatif) ; `CaveLibrary.is_cave` + `data/world/caves.json` (le souterrain n'y est **pas**) ; `FieldItemRules.check(item, map_id, caves)` → `Check.NOT_HERE` pour la Corde Sortie (tests modèles `test_field_item_rules`, `test_escape_rope`) ; profils de `lighting.json` (`cave_1f` etc. comme modèles de `underground`) | art de la série 17 (T9/T11) et vue générale du souterrain validée |
> | **T19** objets cachés | **(A)** | `InteractPoint.unless_flags: Array[StringName]` (`game/world/interactions/interact_point.gd:21`, recopié dans l'`Interaction`) ; modèle d'outil `_add_hidden_item` de `tools/build_route_24.gd` (J13 : indice teinté + `add_interactable` + `unless_flags = [got_<id>]`) et `HIDDEN_ITEMS` de `tools/build_mt_moon.gd` ; tests modèles `tests/integration/test_hidden_items.gd`, `test_hidden_item_point.gd` | les cartes `route_5`, `underground_path`, `route_6` (T13, T14, T18) |
> | **T20** compagnon | **(A)** (déjà vrai depuis T1 : 11D était dans `main`) | `CompanionRules`, `CompanionTrail` (`game/world/companion/`), `data/pokemon/companions.json` (25 espèces, pas encore `meowth`) ; phrase `companion_cave` du J12 réservée aux cartes de `caves.json` (le souterrain garde le repli « route », §2.10) | planche de Miaouss validée (T10) |
> | **T21** raccord nord réel + Passe Bateau | ~~reste (B)~~ **(A) depuis le 2026-10-15** (ci-dessus) | J13 : `cerulean_city` existe, mais son bord sud est fermé **sans warp** (`SouthBarrier` → dialogue `cerulean_closed_exit`, `tools/build_cerulean_city.gd:99`) | **J14** : ouverture du sud d'Azuria, `from_cerulean`, `ss_ticket` |
>
> Hors (B) mais utile : l'évolution par objet du J12 est **`EvolutionDirector.play_item(candidate,
> party, item_id)`** avec **`EvolutionCandidate.cancellable`** (faux pour une pierre) et le signal
> **`evolution_applied(party_index, into)`** (`game/systems/evolution/evolution_director.gd`) ; la
> Pension continue d'utiliser `play` (annulable, F-3). Session **15A** : ne dépend plus que des
> cartes (T13, T18) et de l'art ; **15B** : du moteur du Jackpot (T17) et de Q-1 pour ses textes.

**Règles des tâches (A)** : branche d'intégration **`jalon-15`**, dans une copie dédiée
(mémoire « worktree d'intégration ») ; **T1 y fusionne d'abord `origin/main`** (J11 11A/11B, v6) ;
une branche par tâche (`j15-t<n>-<sujet>`), **jamais fusionnée dans `main` avant la fin du J15** ;
fichiers **nouveaux** de préférence ; les données qui se chargent par dossier vont dans des
**fichiers nouveaux** (`species/`, `moves/`, `items/`, `trainers/`, `shops/`, `encounters/`,
`dialogues/`, `npcs/`, `cutscenes/`) ; ajouts aux fichiers uniques **en fin de fichier**
(`zones.json`, `interiors.json`, `rest_points.json`, `lighting.json`, `objectives.json`,
`data/pokedex/kanto.json`, `kanto_placeholder_areas.json`, `tools/art/manifeste.json`,
`build_character_frames.gd`) — conflits attendus avec J12/J13/J14 : « garder les deux côtés ».

**Fichiers chauds** (le J12 ou le J13 les modifient aussi d'après leurs plans) : `game/boot.gd`,
`game/systems/dialogue/dialogue_library.gd` et `dialogue_choice.gd`, `game/autoload/game_state.gd`,
`game/systems/save/save_system.gd`, `tools/build_painted_interiors.gd`, `tools/debug_start/README.md`.
Le J15 y fait des **ajouts courts et groupés** (un bloc commenté « Pension (J15) »), jamais de
réécriture ; le conflit se résout à la fusion. Aucune tâche (A) ne touche `game/battle/battle*.gd`,
`move_effect.gd`, `interact_point.gd`, `interaction_controller.gd` (J12 T13, T17).

| Tâche | Agent | Quand | Dépendance | Comment avancer sans conflit |
|---|---|---|---|---|
| T0 Plan (ce document) | architecte | fait | — | docs |
| T1 Alignement : `origin/main` dans `jalon-15` | architecte | **(A)** | — | fusion seule ; 15.0 vert |
| T2 Sauvegarde v7 + `GameState.daycare` | architecte | **(A)**, après T1 | — | `save_system.gd`, `game_state.gd` : blocs courts (§2.6) |
| T3 Session 15.0 (téléphone) | qa-mobile | **(A)**, après T2 | — | — |
| T4 Pension sur la carte (moteur) | architecte | **(A)**, après T2 | — | fichiers nouveaux + `boot.gd` (bloc) + dialogue (2 ajouts) |
| T5 Hôte de la Pension (écran) | ui-mobile | **(A)**, après T4 | — | `game/ui/daycare/` (nouveau) |
| T6 Carte de QA `qa_daycare` + départs | constructeur-monde | **(A)**, après T4 | — | carte provisoire retirée au T23 |
| T7 Lot de textes (annexe A) → Kevin | architecte | **fait dans ce plan** ; validation de Kevin | — | docs |
| T8 Kit d'assets série 17 | architecte | **(A)**, après les vues générales | vues générales (en cours) | fichiers nouveaux |
| T9 Génération Codex | constructeur-monde (Mac) | **(A)**, après T8 | — | `build/art/` |
| T10 Planche de Miaouss (+ Persan) | constructeur-monde (Mac) | **(A)** | — | images seules ; branchement au T20 (11D) |
| T11 Intégration de la série 17 | constructeur-monde (Mac) | **(A)**, après T9 | — | entrées en fin de fichier |
| T12 Données sans dépendance | architecte | **(A)**, après T1 et T7 | — | fichiers nouveaux (§2.7) |
| T13 Cartes Route 5, intérieurs, postes | constructeur-monde | **(A)**, après T11, Route 5 v2 | J13/J14 pour le raccord nord → **bouchon `coming_soon`** | outils et scènes nouveaux |
| T14 Cartes Route 6 et Carmin + intérieurs | constructeur-monde | **(A)**, après T11 | — | idem |
| T15 Vie des cartes (PNJ, Dresseurs, objets visibles, panneaux, gardes, marin, arbre) | constructeur-monde | **(A)**, après T12–T14 | — | données nouvelles |
| T16 Rencontres + stock final de Carmin | architecte | **(A)** depuis le 2026-10-14 | ~~J13, J12~~ dans `main` ; cartes T13/T14 pour jouer | tables de `tools/pending_data/j15/encounters/` → `data/encounters/` ; `escape_rope` au stock (§2.7.5, §2.7.6) |
| T17 Jackpot (moteur) | architecte | **(A)** depuis le 2026-10-14 | ~~J12~~ dans `main` ; **Q-1** pour les messages | `MoveEffect.Kind.COINS` après `SELF_KO`, `BattleEvent.Kind.COINS_SCATTERED` en fin, `BattleConclusion.resolve(…, coins)` ; `PayDayPurse` déjà là |
| T18 Carte du souterrain | constructeur-monde | **(A)** depuis le 2026-10-14 | ~~J12~~ dans `main` ; art T11 et vue générale | `PaintedGround` réglable, `LightGlow` (`sconce` en fin de `light_glows.json`), `tools/cave_map_kit.gd` ; hors `caves.json` |
| T19 Objets cachés (3) | constructeur-monde | **(A)** depuis le 2026-10-14 | ~~J12~~ dans `main` ; cartes T13, T14, T18 | `InteractPoint.unless_flags`, modèle `_add_hidden_item` (`build_route_24.gd`) |
| T20 Compagnon (Miaouss, souterrain) | constructeur-monde | **(A)** (11D dans `main` dès T1) | planche T10 | entrée `meowth` dans `companions.json` |
| T21 Raccord nord réel + Passe Bateau | constructeur-monde | **(A)** depuis le 2026-10-15 | ~~J13, J14~~ dans `main` ; carte `route_5` (T13) | retirer `coming_soon` des deux côtés ; `from_cerulean_w|c|e` (écart de grille, §2.1) |
| T22 Sessions 15A puis 15B | qa-mobile | après T16–T19 | — | — |
| T23 Clôture | architecte | fin | — | — |

**Parallélisme maintenant** : T1 → T2 → (T3 ∥ T4) → T5 ∥ T6 ; en même temps, T10, T12, et dès
les vues générales validées T8 → T9 → T11 → T13 ∥ T14 → T15. Chaque (B) part dès que son jalon est
fusionné dans `main` (puis `main` fusionné dans `jalon-15`).

### 1.3 Grilles : lecture et normalisations (aucune géométrie modifiée)

Les grilles font foi (règle 10) ; leurs `POSITIONS` sont des défauts « ajustables au plan ».

1. **Identifiants** (anglais, règle du projet) — cartes : `route_5`, `route_5_daycare`,
   `route_5_gate` (poste nord), `route_5_underground_gate`, `underground_path`,
   `route_6_underground_gate`, `route_6`, `vermilion_city`, `vermilion_center`, `vermilion_mart`,
   `vermilion_fan_club`, `vermilion_fisher_house`, `vermilion_house_1`, `vermilion_house_2`.
   Points d'arrivée des grilles traduits : `from_pension` → `from_daycare`, `from_poste` →
   `from_gate`, `from_souterrain` → `from_underground` ; `from_cerulean`, `from_route_5`,
   `from_route_6`, `from_vermilion`, `from_route_11` gardés. Un spawn par case quand il en couvre
   plusieurs (`_w / _c / _e` pour trois colonnes, `_w / _e` pour deux).
2. **Portes** : `STEP_ON ↑` vers l'intérieur ; sortie des intérieurs vers le spawn de la grille,
   tourné ↓. **Escaliers** du souterrain : `STEP_ON` avec `direction = ZERO` (comme les échelles
   du J12), orientation à l'arrivée = celle de la grille.
3. **Objets cachés** (règle du J12 §1.3) : point d'examen **sur la case-indice** (bloquée) ;
   drapeau `got_<identifiant>` (`got_route_5_hidden_1`, `got_underground_hidden_1`,
   `got_route_6_hidden_1`).
4. **Accès inatteignables au J15** : porte de l'Arène (49..50, 9) derrière l'arbre, embarquement
   (31..32, 28) derrière le marin, porte du poste de la Route 6 (36, 7) derrière le garde :
   warps posés avec `coming_soon` (« Arène de Carmin-sur-Mer », « S.S. Anne », « Safrania ») pour
   que le relais existe ; un test vérifie qu'aucun chemin n'y mène (§5).
5. **Déclencheurs** [D] : `route_5_entered` sur la rangée 1 de la Route 5 (19..21, 1), toute
   direction ; `vermilion_reached` sur (30..32, 1) de Carmin.

### 1.4 Kit d'assets : série « 17 » provisoire (numéro définitif pris au push, contrat du J16 ; méthode des J8–J12)

Numéro **17** [D] (14 = J12, 15 = J13, 16 réservé au J14 ; « le second fusionné renumérote »).
Consigne de Kevin : le plus petit kit modulaire qui donne la **sensation** des vues générales
validées, sans répétition visible ; lumière neutre (NE) pour objets et personnages ; la grille
fait foi. Liste finale, fiches et prompts : **T8** (`docs/design/fiches-assets/serie-17-carmin.md`,
`tools/art/serie17.py`).

**Liste finale (T8, 2026-10-14)** : fiche `docs/design/fiches-assets/serie-17-carmin.md`, outil
`tools/art/serie17.py`, 33 prompts dans `tools/art/prompts/serie17/` (+ attentes, décor de combat) ;
**30 images nouvelles** (21 en vague 1, 9 en vague 2) + 3 conditionnels. Numéro 17 constaté libre
le 2026-10-14 (16 = J14, branches locales) : **revérifié au push**. Route 5 : vue générale pas encore
validée, ses assets (Pension, indice du tronc) sont **à recaler sur la vue Route 5**.

| Groupe | Réutilisé | Nouveau (série 17) |
|---|---|---|
| Routes 5 et 6 | herbe, chemin, forêt `DenseForest`, hautes herbes, rochers, buissons, grands arbres, panneaux, `object/poke_ball_ground` ; **jardin clos** = clôtures + massifs + plates-bandes ; étang = eau de canal + berges + roseaux (série 15) | façade de la **Pension** (7 × 6, toit rouge-brique) ; **poste de garde** (une façade pour les deux routes, 7 × 4 / 7 × 3) ; **entrée du souterrain** (idem) ; planche : indices **tronc** et **joncs**, nénuphars ×2 ; **vue lointaine du port** (belvédère R6, défaut à juger) |
| Souterrain | roche brute = `ground_masse_roche_01` (série 14) assombrie | textures **dalles** et **traces** ; planche de 6 **murs maçonnés** ; planche : escaliers montant et descendant, stèle, banc, **pierre descellée**, **applique** |
| Intérieurs | coques Centre, Boutique, `int_poste_foret_coque` (poste R5, entrées ×2), `int_maison_argenta_coque` (Pension, Fan Club, Pêcheur, maisons) ; meubles existants | planche de 6 meubles : **comptoir de la Pension**, **escalier descendant**, panier, fauteuil du président, vitrine de rubans, tableau (Fan Club) |
| Carmin | Centre, Boutique ; **maisons 1 et 2 = maison d'Argenta** (identique à la vue) ; mer = `ground_eau_01` assombrie ; bittes, piles, caisses, tonneaux, bancs, pavés | façades **Arène** (12 × 7, sans arbre), **Fan Club** (8 × 6), **maison du Pêcheur** (7 × 6) ; texture de **planches** ; planche des **bords de quai en bois** (6 modules) ; planche : **jeune arbre** (objet séparé retirable), passerelle, grue, bitte à amarre, cordage, caisses du port ; **S.S. Anne** 29 × 7 : guide + **3 tranches** à l'échelle (objet séparé, état amarré) |
| Personnages | `old_man`, `guard` ×2, `lass`, `lass_young`, `camper`, `scout`, `nurse`, `clerk`, `haru`, `traveler`, `hiker`, `kid` ; jamais deux fois le même modèle d'**habitant** sur une carte | **marin**, **docker** (×2), **président du Fan Club** — marche + attente (gardien de la Pension = `old_man`, décision de Kevin du 2026-10-14) |
| Pokémon | artworks officiels 052, 053 (combat) ; dos provisoires | planche de Miaouss : T10 (hors série) |
| Combat | — | décor **`route_5_6_prairie`** partagé (chaîne CB.3) ; Carmin et le souterrain : aucun combat sauvage |
| Sac | — | icônes `super_potion`, `full_restore` (`preparer_menu.py`) |

**Conditionnels** : mer du port (texture), coque du Fan Club, autre maison d'habitants.
**Abandonné** : Pokémon visibles au jardin (F-4), intérieur du navire et état « parti » (J16),
cheminée du S.S. Anne au-dessus des toits de Carmin (reprise au loin par la vue du port de la
Route 6), navire court « ferry » de la vue, lumière peinte de la vue du souterrain, mouettes.

---

## 2. Conception technique

### 2.1 Cartes et raccords (T13, T14, T18)

| Carte | Taille | Catégorie | Lumière | `display_name` / région |
|---|---|---|---|---|
| `route_5` | 42 × 62 (v2 à venir) | extérieur | `golden_hour` | « Route 5 » / « Azuria — Safrania » |
| `route_5_daycare` | 15 × 10 | intérieur | `interior_warm` | « Pension Pokémon » |
| `route_5_gate` | 10 × 8 | intérieur | `interior_warm` | « Route 5 » |
| `route_5_underground_gate`, `route_6_underground_gate` | 10 × 8 | intérieur | `interior_warm` | « Passage souterrain » |
| `underground_path` | 26 × 30 | **ni grotte ni intérieur** (`interior = false`, hors `caves.json`) | `underground` (nouveau) | « Passage souterrain » |
| `route_6` | 42 × 56 | extérieur | `golden_hour` | « Route 6 » / « Safrania — Carmin-sur-Mer » |
| `vermilion_city` | 64 × 43 | extérieur | `golden_hour` | « Carmin-sur-Mer » |
| `vermilion_center`, `vermilion_mart`, `vermilion_fan_club`, `vermilion_fisher_house`, `vermilion_house_1`, `vermilion_house_2` | 15 × 10 | intérieur | `interior_warm` | « Carmin-sur-Mer » |

- **Outils** : `tools/build_route_5.gd`, `tools/build_route_6.gd`, `tools/build_vermilion_city.gd`
  (kit `pewter_map_kit.gd`, praticables de la grille, eau et rivage existants, quai `q`/`g` =
  sol praticable texturé planches, coque `N` et mer `W` bloquées) ; `tools/build_underground_path.gd`
  (B, kit du J12 : `PaintedGround` à textures réglables, `LightGlow` type `sconce` aux six cases
  `applique_*`). Graines fixes, deux passes masque / scène (méthode du J10).
- **Raccords** :
  - Route 5 (19..21, 0) PUSH ↑ → `cerulean_city` / `from_route_5_w|c|e` (posées par le J14 en
    (31..33, 40), tournées ↑ ; décalage de 12 colonnes entre les deux cartes) ; **jusqu'au T21 :
    `coming_soon = "Azuria"`** (build de développement ; en release le bord est bloqué) ;
    arrivées `from_cerulean_w|c|e` en (19, 0), (20, 0), (21, 0) tournées ↓ (noms réservés par le
    J14 : ce sont les cibles des warps `Route5W|C|E` d'Azuria). Côté Azuria (T21) : retirer
    `SOUTH_COMING_SOON` (« ROUTE 5 — À venir ») de `tools/build_cerulean_city.gd`. Le barrage
    (`cerulean_rocket_beaten` → `cerulean_south_guard_left`) reste celui du J14, indépendant de
    Léo et de `ss_ticket` (§1.2).
  - **Écart de la grille v2 (signalé le 2026-10-15, non corrigé)** : `tools/plans/route_5.txt`
    déclare **une seule** arrivée `from_cerulean  spawn  19..21,0` (et son en-tête dit « spawn
    from_cerulean côté Azuria », alors que côté Azuria ce sont `from_route_5_w|c|e`) ; le J14
    attend **trois** arrivées `from_cerulean_w|c|e`. Correction minimale proposée (la géométrie ne
    bouge pas) : remplacer la ligne 116 par trois lignes
    `from_cerulean_w  spawn  19,0`, `from_cerulean_c  spawn  20,0`, `from_cerulean_e  spawn  21,0`
    (`libre`, « tournée ↓ »), et corriger l'en-tête (ligne 8 : « spawns `from_route_5_w|c|e` côté
    Azuria, `from_cerulean_w|c|e` ici »). Variante sans toucher la grille : garder la ligne à trois
    cases et suffixer `w|c|e` dans l'outil, comme `tools/build_cerulean_city.gd` le fait déjà pour
    `warp_sud` / `from_route_5` (`SOUTH_SUFFIXES`) — à trancher au T13 (constructeur-monde) ;
    `plan_check_j15.py` (profil `verifier_route_5`) est à relancer si la grille change.
  - Pension (27, 27), poste (34, 44), entrée du souterrain (11, 56) : STEP_ON ↑ ;
  - souterrain : escalier nord (3..4, 1) → `route_5_underground_gate` ; escalier sud (19..20, 28)
    → `route_6_underground_gate` ; arrivées `from_route_5_w|e` (3..4, 2) ↓, `from_route_6_w|e`
    (19..20, 27) ↑ ;
  - Route 6 : porte du bâtiment (7, 4) → `route_6_underground_gate` ; bord sud (25..27, 55) PUSH ↓
    → `vermilion_city` / `from_route_6_w|c|e` (30..32, 0) ; retour (30..32, 0) PUSH ↑ → `route_6`
    / `from_vermilion_w|c|e` (25..27, 55) (décalage de 5 colonnes) ;
  - Carmin : est (63, 11..13) PUSH → `coming_soon = "Route 11"`, retour sur la case tourné ← ;
    portes des bâtiments (§1.3) ; Arène, embarquement : §1.3 n° 4.
- **Préchargement** : `route_5` ↔ (Azuria au T21) ; le souterrain n'a que des voisins intérieurs
  (aucun préchargement) ; `route_6` ↔ `vermilion_city`.

### 2.2 Intérieurs (`build_painted_interiors.gd`, T13, T14)

- Nouveau groupe `const CARMIN := [...]` et `const ROUTE_5 := [...]` + options `--carmin`,
  `--route5` ; définitions **en fin de fichier** ; `_init` appelle `_vermilion_rooms()` et
  `_route_5_rooms()` (deux lignes).
- **Postes** : `_forest_gate(side)` est propre à la forêt. Nouvelle définition générique
  `_gate_room(id, node, title, warps, spawns, guard_cell)` (même enveloppe `int_poste_foret_coque`,
  mêmes meubles) ; `_forest_gate` **inchangée** (aucun diff sur les scènes de la forêt).
  - `route_5_gate` : sud (4..5, 7) → `route_5` / `from_gate` ; nord (4..5, 1) = `coming_soon
    "Safrania"` (jamais atteint) ; garde `guard` en (4, 2) tourné ↓ devant l'ouverture, la case
    (5, 2) fermée par un meuble bas [D] ; déclencheur `route_5_gate_rule` sur (4..5, 3), pas ↑
    (scène §2.4).
  - `route_5_underground_gate` / `route_6_underground_gate` : porte sud → la route ; **escalier**
    au nord (prop « escalier descendant » sur (4..5, 2), warps `STEP_ON` sans direction) →
    `underground_path` / `from_route_5_*` ou `from_route_6_*` ; panneau T-14 au mur (EXAMINER).
- **Pension** `route_5_daycare` : enveloppe de maison d'Argenta (`_pewter_house`) + comptoir ;
  gardien `old_man` derrière le comptoir, parlé par-dessus (modèle `ClerkCounter` de `_poke_mart`) ;
  dialogue `daycare_keeper` (§2.5).
- **Carmin** : `vermilion_center` = `_pokemon_center` (point de repos), `vermilion_mart` =
  `_poke_mart`, `vermilion_fan_club`, `vermilion_fisher_house`, `vermilion_house_1|2` =
  `_pewter_house` (meubles variés) ; Fan Club : 15 × 10 [D], président + 2 membres + Miaouss.
- `interiors.json` : les 12 pièces ; `rest_points.json` : `vermilion_center`.

### 2.3 Le souterrain : catégorie, lumière (T18, B)

- **Catégorie** : `interior = false` (compagnon visible, titre de zone « PASSAGE SOUTERRAIN » à
  l'entrée), **absent** de `caves.json` (pas de Corde Sortie : `FieldItemRules.check` du J12 rend
  `NOT_HERE`) et de `interiors.json`. Aucun champ de scène nouveau.
- **Lumière** : profil `underground` dans `lighting.json` (fin de fichier ; aucune ombre portée,
  `rim` faible, étalonnage chaud et sombre, vent 0) ; six **appliques** `LightGlow` (type
  `sconce` ajouté **en fin** de `light_glows.json` : orangé, rayon ≈ 2,5 cases, vacillement lent
  coupé par « Réduire les animations ») ; la lumière est d'abord **peinte** (sol plus clair sous
  les appliques). Seuils Mac du J12 (`luminance_grotte.py`) : informatifs.
- **(A) maintenant** : art (T9), PNJ et dialogue du passant (T-18), décor-indice, test de
  grille `test_underground_path` écrit sur `PlanGrid` (40 pas, 2 coudes, 3 alcôves, aucune
  herbe), marqué `pending` jusqu'à la scène.

### 2.4 Gardes vers Safrania (T15)

- **Route 5** (intérieur) : scène `route_5_gate_rule` (modèle `route_3_guard`) : `face` →
  `dialogue route_5_guard` → recul d'une case ; dialogue à deux variantes : `unless
  route_5_gate_warned` (T-15, `set route_5_gate_warned`) puis T-16.
- **Route 6** (extérieur) : scène `route_6_gate_rule` sur les cases `verrou_safrania` (35, 8),
  (37, 8), (35..37, 9) : T-17 puis recul ; parlé de face : T-17.
- Aucun drapeau de déblocage (hors J15).

### 2.5 La Pension sur la carte (T4, T5)

#### 2.5.1 Classes

| Fichier | Classe | Rôle |
|---|---|---|
| `game/systems/daycare/daycare.gd` … (fait) | `Daycare`, `DaycareRules`, `DaycareConfig`, `DaycarePreview`, `DaycareWithdrawal` | règles pures (15.0) |
| `game/systems/daycare/daycare_step_counter.gd` | `DaycareStepCounter` (`RefCounted`) | `on_player_moved(input_enabled: bool) -> int` : un pas compte si l'entrée est libre ; appelle `Daycare.add_steps(1, config)` ; pur, testable |
| `game/systems/daycare/daycare_lines.gd` | `DaycareLines` (`RefCounted`, statique) | **quel dialogue jouer** : `for_visit(preview) -> StringName` (`daycare_offer`, `daycare_visit`, `daycare_visit_levels`, `daycare_party_full`), `for_withdrawal(plan)` (`daycare_returned` / `daycare_returned_short`), `for_refusal(status)` ; `token_values(pokemon, levels, price, data) -> Dictionary` (`{price}` = nombre formaté **sans** « ₽ », le texte le porte) |
| `game/systems/daycare/daycare_director.gd` | `DaycareDirector` (`Node`) | relaie : pas → compteur ; `run(npc)` coroutine (dépôt / retrait, dialogues, choix, sélecteur, débit, capacités, évolution, écriture) ; aucune règle |
| `game/ui/daycare/daycare_overlay.gd` | `DaycareOverlay` (`CanvasLayer`, T5) | voile + `PartyPicker` (dépôt) + bandeau et hôte pour `MoveLearnPrompt` (même placement que `TmLearnOverlay`) |

- **Compteur de pas** : `DaycareDirector.setup(state, player, config, …)` connecte
  `Player.moved` ; filtre `player.is_input_enabled()` (même règle que `scene_router.gd:382`) ;
  la course compte comme la marche ; un pas refusé n'émet pas `moved` ; aucune allocation.
  Rien n'est écrit sur disque à chaque pas (passe §2 n° 7 : quelques pas perdus si l'application
  est tuée, jamais de doublon).
- **Autoload** : aucun. Le directeur est un enfant de Boot, comme `EvolutionDirector`.

#### 2.5.2 Dialogues, action et jetons

- `DialogueLibrary.ACTIONS += &"open_daycare"` ; une variante **sans page** est permise si elle a
  une action (seul cas : le gardien) ; `DialogueRunner` sans page : pas de boîte, action puis
  fin. Tests : `test_dialogue_library`, `test_dialogue_runner`.
- `DialogueTokens.KNOWN += pokemon, levels, price` ; `Boot._dialogue_token_values` fusionne
  `_daycare.token_values()` (vide hors d'une conversation de Pension → les pages à jeton seraient
  omises, jamais affichées avec « {pokemon} »). `{pokemon}` = nom affiché du Pokémon concerné
  (gardé, ou qui vient d'être rendu) ; `{levels}` = niveaux gagnés ; `{price}` = prix annoncé.
- Données `data/dialogues/route_5_daycare.json` (textes §15.1 mot pour mot) :
  `daycare_keeper` (`action: open_daycare`, sans page), `daycare_offer` (T-2 + choix Oui / Non,
  `confirm_action: daycare_yes` [D], `cancel_pages` T-3 ; ou, plus simple, le directeur lit la
  réponse par un signal `choice_made(confirmed)` ajouté au runner — **décision au T4**, la plus
  petite des deux), `daycare_pick` (T-4), `daycare_last_able` (T-5), `daycare_deposited` (T-6),
  `daycare_visit` (T-7 + choix), `daycare_visit_levels` (T-8 + choix), `daycare_party_full`
  (T-9), `daycare_returned` (T-10), `daycare_returned_short` (T-11), `daycare_after` (T-12).
- Panneau T-1 devant la Pension (`panneau_pension`).

#### 2.5.3 Déroulé (après la fin du dialogue `daycare_keeper`, comme `_pending_shop`)

```
Pension vide   : daycare_offer ─ Non → T-3 (fin)
                               └ Oui → T-4 → sélecteur (PartyPicker, équipe entière ;
                                        refus LAST_POKEMON / LAST_ABLE : carte avec la raison
                                        StorageViews.LAST_ABLE_TEXT, toucher → T-5 en titre)
                                        ANNULER → fin, rien ne change
                                        choix → DaycareRules.deposit ; compagnon effacé si c'était
                                        lui ; ÉCRITURE immédiate ; T-6
Pension occupée: équipe pleine → T-9 (fin)
                 sinon T-7 / T-8 (preview : niveaux, prix) ─ Non → fin
                                                          └ Oui → DaycareRules.withdraw
                    → spend_money(plan.paid) → T-10 ou T-11 (plan.paid < plan.price)
                    → chaque capacité de plan.moves : MoveLearnPrompt.teach (overlay)
                    → si plan.evolution : EvolutionDirector.play([candidat], party) (ARRÊTER possible)
                    → T-12 → ÉCRITURE de la sauvegarde
```

- **Ordre du dossier** respecté (XP → capacités dans l'ordre → évolution → soin) : le soin est
  appliqué dans `withdraw` (PV pleins, statut et PP) ; une évolution garde les PV perdus
  (`Pokemon.evolve_into`) : un Pokémon soigné reste donc plein après l'évolution (test).
- **Verrou** : le joueur reste bloqué (raison `daycare`) de la fin du dialogue du gardien à la fin
  du déroulé ; `Boot.is_stable()` est donc faux et aucune autosave n'écrit au milieu.
- **Écritures** [D] : **dépôt** → écriture immédiate (cas limite « quitter avant l'autosave ») ;
  **retrait** → une seule écriture à la fin du déroulé. Une application tuée pendant les capacités
  ou l'évolution reprend **avant le retrait** (Pokémon encore à la Pension, argent intact) : rien
  n'est perdu ni dupliqué.
- **Argent** : seul `DaycareDirector` appelle `GameState.spend_money(plan.paid)` (toujours ≤
  argent du joueur, donc jamais refusé) ; `test_only_the_shop_spends_money` : le fichier
  `res://game/systems/daycare/daycare_director.gd` **ajouté à la liste blanche**.
- **Retour Android** : pendant le sélecteur = ANNULER (à router depuis `Boot._on_go_back` vers
  le directeur de la Pension) ; pendant `teach` = règle existante du panneau ; pendant
  l'évolution = ARRÊTER **sans rien ajouter** : `Boot._on_go_back` appelle d'abord
  `BattleDirector.handle_back` (`battle_director.gd:343-346`), qui relaie l'`EvolutionDirector`
  partagé avec Boot (`boot.gd:236`) dès qu'il joue, combat ou non.
- **Compagnon** : `DaycareRules.deposit` ne connaît pas le compagnon ; le directeur appelle
  `GameState.set_companion(null)` si l'uid déposé est `companion_uid`. Le choix d'un autre
  compagnon est la règle du J11 (11D).

#### 2.5.4 Séquence hors combat partagée avec le Super Bonbon (J14)

Les deux étapes « capacités dues puis évolution proposée » sont écrites une seule fois, hors du
dossier de la Pension, dans **`game/systems/evolution/off_battle_level_up.gd`** (`OffBattleLevelUp`,
coroutine statique) : `play(pokemon, index, moves, evolution, learn: MoveLearnPrompt, banner, host,
evolutions: EvolutionDirector, party)`. La Pension l'appelle avec
le plan de retrait ; le **Super Bonbon du J14** l'appellera avec le `LevelUp` d'un niveau
(capacités) et `Evolution.level_up_target` — **passation écrite pour le plan du J14**. Le premier
des deux jalons fusionné la crée (passe §2 n° 4).

### 2.6 Sauvegarde v7 (T2) — seul changement de format du J15

- `SaveSystem.VERSION = 7` ; en-tête : « 7 = jalon 15, Pension (« daycare » : Pokémon déposé, XP en
  attente, niveau au dépôt ; dossier 18 §11) ». `upgrade` : **6 → 7 : rien à transformer** (une
  partie sans « daycare » a une Pension vide) ; le numéro protège d'une build v6 qui **perdrait
  le Pokémon déposé** au premier autosave.
- `GameState` : `var daycare: Daycare = Daycare.new()` ; `new_game` la vide ; `to_dict` ajoute
  `"daycare": daycare.to_dict()` ; `load_dict` : `Daycare.from_dict(dict, data)` ; **null**
  (Pokémon invalide) → Pension vide **et** `ok = false` (Boot garde l'original en
  `save.json.rejected`, `_keep_rejected_save` : rien n'est perdu en silence).
- `ensure_unique_uids()` parcourt équipe, Stockage **et** Pension (`daycare.pokemon` reçoit un uid
  au dépôt par `ensure_uid`, et au chargement s'il en manque).
- `load_dict` : un `companion_uid` qui désigne le Pokémon de la Pension est effacé (même règle que
  « absent de l'équipe », déjà là).
- `DebugStart` : champ facultatif `daycare` `{ species, level, pending_exp }` (README).
- **Version** : si un autre jalon fusionné avant le J15 change le format, « le second fusionné
  renumérote » (le J15 passe alors en v8 ; seul le numéro et le test changent).
- **Tests** `test_save_j15` : aller-retour (Pokémon, uid, XP en attente, niveau au dépôt) ;
  v6 réelle (`tests/fixtures` : la partie v6 du J11) → v7 sans autre changement, Pension vide ;
  v7 lue avec `version = 6` → `ERR_INVALID_DATA`, fichier intact ; Pension invalide → vide + refus
  signalé ; uid en double entre l'équipe et la Pension → réattribué ; compagnon déposé → aucun.

### 2.7 Données (T12 en A ; T16, T17 en B)

#### 2.7.1 Espèces et Pokédex (A)

- `data/pokemon/species/kanto_vermilion.json` [D, fichier nouveau : `PokemonData` lit tout le
  dossier] : `meowth` (n° 52, Normal, 40/45/35/40/40/90, `medium_fast`, XP de base 58, capture 255,
  ½ mâles) et `persian` (n° 53, 65/70/60/65/65/115, XP 154, capture 90) ; apprentissages RB :
  Miaouss `[1 scratch] [1 growl] [12 bite] [17 pay_day] [24 screech] [33 fury_swipes] [44 slash]`,
  Persan `[1 scratch] [1 growl] [1 bite] [1 screech] [12 bite] [17 pay_day] [24 screech]
  [37 fury_swipes] [51 slash]` ; Miaouss → Persan niveau 28.
- `data/pokedex/kanto.json` (fin de fichier) : Miaouss 0,4 m / 4,2 kg, T-40 ; Persan 1,0 m /
  32,0 kg, T-41 ; note de la forme de base (annexe A).
- Compatibilités CT : `tools/gen_tm_compatibility.py` relancé sur les espèces connues ; **conflit
  attendu** avec J12/J13 (fichier généré) : **on régénère à chaque fusion**, jamais à la main.
- Sprites provisoires de dos : `gen_placeholder_battlers.gd` étendu (exigé par `test_battle_stage`).
- Mystherbe, Chétiflor, Ortide, Boustiflor : **viennent du J13** (D-8 retenu, plan §2.15) ; le
  J15 ne les crée pas.

#### 2.7.2 Capacité Jackpot (A : donnée ; B : effet)

`data/pokemon/moves/vermilion.json` [D] : `pay_day` « Jackpot », Normal, physique, 40, 100,
20 PP, description T-39. **En (A)** : `"pending_effects": ["pay_day"]` (le moteur ignore l'effet ;
aucun texte « Sans effet » : la description validée reste). **En (B, T17)** : l'effet remplace
`pending_effects` (§2.7.3).

#### 2.7.3 Effet du Jackpot (T17, B : après la fusion du J12)

- Donnée : `{ "kind": "coins", "per_level": 2 }` ; `MoveEffect.Kind.COINS` **en fin d'enum, après
  ceux du J12**.
- Règle pure `PayDayPurse` (`game/battle/pay_day_purse.gd`, **écrite en (A)** avec ses tests,
  aucun fichier du combat touché) : `add(user_level, per_level)`, `total()` ; seules les
  utilisations **du camp du joueur** comptent (le Jackpot d'un Miaouss sauvage ne rapporte rien).
- Moteur : chaque utilisation réussie par le joueur émet `BattleEvent.COINS_SCATTERED(amount)`
  (message de l'annexe A) ; `BattleConclusion.resolve(…, coins)` : `coins` versés si l'issue est
  **victoire ou capture** [D] (dossier : « combat gagné » ; la capture termine le combat sans
  défaite), jamais à la fuite ni à la défaite ; contre un sauvage aussi (§0.2 n° 5) ;
  `BattleDirector` : « Tu ramasses {money}. » (annexe A) **après** l'argent du Dresseur, puis
  `add_money` (plafond existant).
- Tests : `test_pay_day_purse` (A), `test_battle_pay_day` (B : 2 × niveau par utilisation, total
  cumulé, sauvage et Dresseur, capture, fuite = rien, défaite = rien, Jackpot adverse = rien).

#### 2.7.4 Objets (A)

`data/items/vermilion.json` [D] : `super_potion` « Super Potion » / « Super Potions », féminin,
`heal`, `heal_amount` 50, 700 ₽, T-37 ; `full_restore` « Guérison » / « Guérisons », féminin,
`heal`, `heal_amount` **999** [D : au-delà de tout PV max, soin total sans champ nouveau] +
`cures` des cinq statuts, prix 3 000 ₽ (non vendue), T-38. Icônes : T9/T11.

#### 2.7.5 Rencontres (T16, B : après J13)

`data/encounters/route_5.json` et `route_6.json` : table §3.2 (Roucool 13–16 ×30, Mystherbe 13–16
×15, Chétiflor 13–16 ×15, Férosinge 10–16 ×20, Miaouss 10–16 ×20), `rate` 25, rampe 15 → 20
(Route 3). **En (A)** : les deux fichiers sont écrits dans la branche de T12 **sans les lignes
Mystherbe et Chétiflor** et **non fusionnés** dans `jalon-15` (un chargement avec une espèce
inconnue échouerait) ; T16 les complète et les fusionne dès le J13 dans `main`.

#### 2.7.6 Boutique de Carmin (A, puis une ligne en B)

`data/shops/vermilion_mart.json` : Poké Ball, Potion, **Super Potion**, Antidote, Anti-Para,
Réveil, Antigel, Anti-Brûle (stock d'Azuria du plan J13 §2.5 + Super Potion, F-14) ; **Corde
Sortie** ajoutée par T16 après le J12. Marchand : dialogue existant `clerk`.

#### 2.7.7 Dresseurs (A)

`data/trainers/route_6.json`, IA `random`, capacités apprises au niveau, `prize_money` fixe :
`route_6_lass_chloe` « Jeune Dresseuse Chloé » (Roucool 16 ×3, 320), `route_6_camper_gabin`
« Campeur Gabin » (Piafabec 16, Rattatac 16, 320), `route_6_scout_axel` « Scout Axel » (Aspicot,
Chenipan, Aspicot 16, 192), `route_6_camper_mathis` « Campeur Mathis » (Carapuce 20, 400),
`route_6_lass_manon` « Jeune Dresseuse Manon » (Rattata 16, Pikachu 16, 320),
`route_6_scout_basile` « Scout Basile » (Papilusion 20 : Choc Mental, Poudre Toxik, Para-Spore,
Poudre Dodo, 240). Répliques §15.5 (avant / défaite / après) ; vision et orientation de la grille.

#### 2.7.8 PNJ et répliques (A)

| Carte | PNJ (modèle [D]) | Texte |
|---|---|---|
| Route 5 | promeneuse (habitante non encore utilisée) | T-21 |
| Route 5 | voyageur `traveler` | T-22 |
| `route_5_gate` | garde `guard` | T-15, T-16 |
| souterrain | passant `hiker` | T-18 |
| Route 6 | pêcheur sans canne (habitant non utilisé sur la carte, choisi au T15) | T-23 |
| Route 6 | garde `guard` | T-17 |
| Route 6 | promeneur (P3 de la grille) | **annexe A** |
| Carmin | marin (nouveau) | T-26 |
| Carmin | docker 1, docker 2 (nouveau, même modèle) | T-27, T-28 |
| Carmin | vieil habitant devant l'Arène | T-31 |
| Carmin | habitante de la place | T-32 |
| Carmin | enfant | **annexe A** |
| Fan Club | président (nouveau) | T-33 |
| Fan Club | membres ×2 [D] | T-34 + **annexe A** |
| Pêcheur | `haru` (planche `pecheur`) | T-35 |
| maison 1 | habitant | T-36 |
| maison 2 | habitante | **annexe A** (« le navire ») |
| Carmin | jeune arbre (EXAMINER, `examen_arbre`) | T-29 |
| panneaux | Route 5, souterrain (×2 bâtiments), Route 6, Carmin, Arène, Pension | T-13, T-14, T-20, T-25, T-30, T-1 ; autres : annexe A |

Le « vrai » pêcheur de Carmin garde le modèle du pêcheur (`haru`) ; l'homme de l'étang, qui
annonce l'autre (T-23), prend un modèle différent pour qu'on ne les confonde pas [D]. Règle des
habitants : jamais deux fois le même modèle sur une carte. Pokémon d'ambiance des grilles :
Roucool et Rattata (planches existantes).

#### 2.7.9 Drapeaux, objectifs, zones (A)

- Drapeaux : `beaten_<id>` ×6, `got_route_5_item_1`, `got_route_6_item_1`, `got_route_5_hidden_1`,
  `got_route_6_hidden_1`, `got_underground_hidden_1`, `route_5_entered`, `route_5_gate_warned`,
  `vermilion_reached` — tous dans `flags` (format inchangé).
- `objectives.json`, **en tête** : `{ "id": "explore_vermilion", "text": "explorer
  Carmin-sur-Mer.", "if": ["vermilion_reached"] }`, puis `{ "id": "go_vermilion", "text":
  "rejoindre Carmin-sur-Mer, au sud.", "if": ["route_5_entered"], "unless": ["vermilion_reached"] }`.
  **Conflit de tête attendu** avec J13/J14 (même fichier, première entrée valide) : l'ordre
  final = ordre du voyage, réglé à la fusion.
- `zones.json` : `route_5` (`maps` : route, Pension, poste, bâtiment d'entrée ; service nouveau
  `daycare` « Pension » `found_on: route_5_daycare` [D]), `underground_path` (`kind: place`),
  `route_6` (+ son bâtiment d'entrée), `vermilion_city` (`maps` remplies ; services Centre,
  Boutique, Arène `found_on: vermilion_city`) ; sous-titres et descriptions : annexe A.
- `kanto_placeholder_areas.json` : aires `route_5`, `route_6` (`underground_path` : aucune, comme
  les intérieurs) ; `pokedex/scenes.json` : `route_5`, `route_6` → décor « prairie » [D].

### 2.8 Objets visibles et cachés (T15 en A, T19 en B)

- **Visibles** (modèle du J8, `object/poke_ball_ground`, PRENDRE, `got_<id>`) : Super Potion
  Route 5 (13, 12) ; Poké Ball Route 6 (38, 41).
- **Cachés** (J12 §2.8) : Antidote Route 5 (indice tronc (16, 31), depuis (16, 32)) ; **Guérison**
  souterrain (pierre descellée (11, 9), depuis (11, 10) tourné ↑, **T-19 en page avant le toast**,
  seul objet caché avec une phrase, dossier §5) ; Super Potion Route 6 (joncs (10, 32)).
  **En (A)** : décor-indice posé par l'outil sur la case, dialogues `<id>` → scène `give … found:
  true` → `set got_<id>` écrits et testés par `test_cutscene_library`. **En (B, T19)** :
  `InteractPoint` + `unless_flags = [got_<id>]`.

### 2.9 S.S. Anne, Arène, Route 11 (T15)

- **Marin** (31, 26) tourné ↓ : T-26, **sans condition** (identique avec ou sans `ss_ticket` ; la
  variante du J16 remplacera la réplique). Cordage (32, 26) bloqué. Embarquement inatteignable.
- **Arbuste** (49..50, 10) : objet bloquant **retiré par le drapeau `cut_vermilion_gym_bush`** (contrat
  du J16, dossier 18 §17 ; nom à confirmer avec le J16) + `InteractPoint` EXAMINER T-29 ; aucune
  mécanique de coupe au J15 : le J16 le coupera.
- **S.S. Anne** : objet de décor **séparé**, absent si `ss_anne_departed` (contrat du J16), pour que le
  J16 le fasse disparaître après le départ.
- **Route 11** : `coming_soon`, retour sur la case.

### 2.10 Compagnon (T20, B : après 11D)

Miaouss entre dans `companions.json` (planche validée, A-11) ; le souterrain n'est pas un
intérieur : le compagnon y suit (galerie de 2 cases, renflement au passant) ; contexte de phrase
« souterrain » : **aucun** au J15 [D] (pas de texte validé ; repli « route » du J11). Pension :
« déposé = effacé » (§2.5.3), codé en (A).

### 2.11 Budgets et mesures

- ≤ 3 000 nœuds par carte (`NODE_BUDGET`), mesuré **dès la première construction** : Route 5
  (42 × 62 ≈ 2 600 cases, forêt sur les bords : risque comme la Route 2), Carmin (64 × 43, mer et
  coque = grands aplats, peu de nœuds ; le S.S. Anne en **un seul** sprite ou 3 tranches).
  Si Carmin dépasse : quai en carte séparée `vermilion_dock` (F-12), décision notée.
- Mémoire « carte + voisines » (`tools/measure_map_cache.gd`) : Route 6 + Carmin (la plus lourde,
  grand asset du navire) ; seuil 64 Mo (J12).
- fps : moyenne ≥ 58, creux ≥ 50 (Route 5, Carmin, souterrain avec halos) ; écran de la Pension :
  aucune allocation par image.
- Pension : `add_steps` par pas, sans allocation ; aucune écriture disque par pas.

### 2.12 Départs de débogage et carte de QA

- **Carte `qa_daycare`** (T6, tuiles provisoires, un gardien, de l'herbe sans rencontre, une
  boucle de 40 cases) : la Pension testable avant la Route 5. **Retirée au T23.**
- Départs (`tools/debug_start/`, README) : `daycare_v7_qa` (Pokémon déposé, XP en attente, pour
  15.0) ; `daycare_qa` (sur `qa_daycare` : équipe de 3, 5 000 ₽) ; `daycare_ready` (Pokémon déposé
  Nv. 15 + XP pour 3 niveaux, capacité due à chaque niveau, équipe de 4 capacités, évolution
  atteinte) ; `daycare_poor` (0 ₽) ; `daycare_full` (équipe de 6) ; `daycare_lv99` ; `route_5`,
  `underground`, `route_6`, `vermilion` (équipe Nv. 18–22 [D]).

---

## 3. Tâches

Branche **`jalon-15`** (copie dédiée), une branche par tâche (`j15-t<n>-<sujet>`) ; jamais de
`pkill` ; chaque tâche met à jour `etat-projet.md` dans son commit ; textes **mot pour mot** (§15
et annexe A validée).

#### T0 — architecte : plan (fait)

#### T1 — architecte : alignement — **(A)**
- Fusionner `origin/main` (`ee5d5c9` ou plus récent) dans `jalon-15` ; relancer `test_daycare`
  (`Pokemon.gain_exp` est à la l. 182 sur `main` : docs de `daycare.gd` à mettre à jour) ;
  réaligner §0 si le J11 a bougé. **CA** : `tools/test.sh` vert, import propre.

#### T2 — architecte : sauvegarde v7 — **(A)**, après T1 → **15.0**
- §2.6 (`save_system.gd`, `game_state.gd`, `DebugStart`, `test_save_j15`, fixture v6).
- **CA** : tests verts ; une partie v6 réelle se charge en v7 sans autre changement ; une build
  v6 refuse la v7 sans l'écraser ; le Pokémon de la Pension survit à un aller-retour JSON.

#### T3 — qa-mobile : **session 15.0** → Kevin — **(A)**, après T2
- Téléphone : vraie partie v6 de Kevin → APK v7 → rien perdu ; départ `daycare_v7_qa` → sauvegarde
  → relance → Pension intacte (`adb` : `daycare` dans `save.json`) ; APK v6 sur une sauvegarde v7 →
  refus, fichier intact ; partie restaurée. **CA** : rapport `build/qa/jalon15_t3/` ; validation.

#### T4 — architecte : Pension sur la carte (moteur) — **(A)**, après T2
- §2.5 : `DaycareStepCounter`, `DaycareLines`, `DaycareDirector`, `OffBattleLevelUp`, action
  `open_daycare`, dialogue sans page, jetons, liste blanche, routage du retour, données
  `route_5_daycare.json` (dialogues).
- Tests : `test_daycare_step_counter` (pas libre / scripté / refusé, course), `test_daycare_lines`,
  `test_dialogue_library` / `_runner` (sans page, jetons), `test_shop_rules` (liste blanche),
  intégration `test_daycare_flow` (Boot réel sur `qa_daycare` : dépôt, refus, retrait,
  capacités refusées, évolution annulée, argent, écritures — §5).
- **CA** : tests verts ; aucun fichier de `game/battle/` touché.

#### T5 — ui-mobile : écran de la Pension — **(A)**, après T4
- `DaycareOverlay` (sélecteur, raisons de refus, bandeau, hôte des panneaux), titres du sélecteur
  (« Confier un Pokémon » [D, texte d'interface court]), captures 2340 × 1080 relues (sélecteur avec
  un refus, « veut apprendre », évolution depuis la Pension). Jetons d'interface (`ui_tokens.gd`,
  fin de fichier). **CA** : captures relues ; aucune couleur en dur.

#### T6 — constructeur-monde : `qa_daycare` + départs — **(A)**, après T4
- §2.12. **CA** : départs chargés sans erreur ; README à jour.

#### T7 — Kevin : lot de textes (annexe A) — **(A)**
- **CA** : validé en une passe ; bloque les données de T12/T15 qui en dépendent, pas le code.

#### T8 — architecte : kit d'assets série 17 — **(A)**, après les vues générales validées
- §1.4 ; fiche `serie-17-carmin.md`, `tools/art/serie17.py` (`--prompts`, `--refs`,
  `--commandes`, `--planche`, `--manifeste` préparé, `--controle`), planche `build/art/J15_KIT_v1.png`.
- **CA** : chaque élément visible des vues validées a un asset (réutilisé, varié, nouveau) ou est
  abandonné explicitement.
- **Fait (2026-10-14, branche `j15-t8-kit`)** : 30 images nouvelles + 3 conditionnels, 33 prompts,
  planche `J15_KIT_v1.png` relue ; contrôle « chaque élément » dans la fiche.

#### T9 — constructeur-monde (Mac, Codex) : génération → planche de contact pour Kevin — **(A)**
#### T10 — constructeur-monde (Mac) : planche de Miaouss (+ Persan si budget) — **(A)**
- Gabarit de la série 13 (repos + marche 4 directions) ; validation de Kevin ; **aucune**
  intégration avant 11D.
#### T11 — constructeur-monde (Mac) : intégration de la série 17 — **(A)**, après T9
- Manifeste (fin), `preparer.py` ×2, règles de décor, `build_painted_props.gd -- --nouveaux`,
  `build_character_frames.gd` (fin), icônes. **CA** : second passage sans changement ;
  `test_painted_props` vert.

#### T12 — architecte : données — **(A)**, après T1 (et T7 pour les textes de l'annexe)
- §2.7.1, §2.7.2 (donnée), §2.7.4, §2.7.6 (sans Corde), §2.7.7, `PayDayPurse` + tests ;
  rencontres préparées (§2.7.5, non fusionnées).
- Tests : `test_pokemon_data` (40 espèces sur `main`, compte recalé à chaque fusion),
  `test_pokedex_library`, `test_item_library`, `test_shop_library`, `test_trainer_library`
  (Dresseurs valides, récompenses du §6.2), `test_battle_stage` (sprites provisoires).
- **CA** : tests verts ; aucune carte touchée.

#### T13 — constructeur-monde : Route 5, Pension, poste, bâtiment d'entrée — **(A)**, après T11 et la grille v2
- §2.1, §2.2 ; `build_route_5.gd` ; bord nord en `coming_soon = "Azuria"` ; cases des PNJ et
  objets réservées. Tests `test_route_5` (grille de la scène = grille du plan, nœuds ≤ 3 000,
  raccords), `test_map_catalog`, `test_map_links`, `test_coming_soon` ; captures relues contre la
  vue. **CA** : tests verts, captures, budget.

#### T14 — constructeur-monde : Route 6, Carmin et intérieurs — **(A)**, après T11
- §2.1, §2.2, `build_route_6.gd`, `build_vermilion_city.gd` (quai, pontons, mer, coque) ;
  `test_route_6` (Chloé inévitable par géométrie, les cinq autres évitables — critères de
  `plan_check_carmin.py` sur la vraie scène), `test_vermilion_city` (Arène et embarquement
  inatteignables, Route 11 « À venir », nœuds) ; captures ; mémoire « Route 6 + Carmin ».

#### T15 — constructeur-monde : la vie des cartes — **(A)**, après T12–T14
- §2.4, §2.7.7–§2.7.9, §2.8 (visibles + préparation des cachés), §2.9 ; déclencheurs ; Centre et
  Boutique ; Pension sur la vraie carte (gardien, `daycare_keeper`). Tests `test_route_5_life`,
  `test_route_6_trainers` (Chloé, réplique « après », récompenses), `test_vermilion_life`
  (marin, arbre, Fan Club, Boutique : Super Potion 700 ₽), `test_objective_library`.

#### T16 — architecte : rencontres + Corde Sortie au stock — **(A depuis le 2026-10-14 : J12 et J13 dans `main`, §1.2)**
- §2.7.5, §2.7.6 ; `test_encounter_library` (tables par carte), Miaouss vu sur la Route 5 en vraie
  scène. **CA** : tests verts.

#### T17 — architecte : Jackpot dans le moteur — **(A depuis le 2026-10-14 ; messages après Q-1, §1.2)**
- §2.7.3 ; messages de l'annexe A dans `messages.json` ; `test_battle_pay_day`.

#### T18 — constructeur-monde : carte du souterrain — **(A depuis le 2026-10-14, après l'art T11, §1.2)**
- §2.3 ; `build_underground_path.gd`, profil `underground`, `sconce`, PNJ ; `test_underground_path`
  (grille, 41 pas, escaliers aller-retour, hors `caves.json`, `interior == false`, Corde Sortie
  refusée), captures (luminosité par défaut).

#### T19 — constructeur-monde : objets cachés — **(A depuis le 2026-10-14, après T13, T14, T18, §1.2)**
- §2.8 ; `test_hidden_items` étendu aux trois caches (bouton face à l'indice seulement, toast,
  T-19 pour la Guérison, absent ensuite même après rechargement).

#### T20 — constructeur-monde : compagnon — **(A : J11 11D dans `main`, §1.2)**
- §2.10. **CA** : Miaouss compagnon dans la galerie et le souterrain ; dépôt du compagnon → aucun.

#### T21 — constructeur-monde : raccord nord réel et Passe Bateau — **(A depuis le 2026-10-15 : J13 et J14 dans `main`, §1.2)**
- Route 5 : bord nord (19..21, 0) → `cerulean_city` / `from_route_5_w|c|e` (sans `coming_soon`) ;
  arrivées `from_cerulean_w|c|e` (19..21, 0) tournées ↓ (écart de grille à régler d'abord, §2.1).
- Azuria : les trois warps `Route5W|C|E` (31..33, 40) perdent `coming_soon` « Route 5 »
  (`SOUTH_COMING_SOON` de `tools/build_cerulean_city.gd`) et mènent à `route_5` /
  `from_cerulean_w|c|e` ; carte régénérée ; `test_coming_soon` et `test_companion_coming_soon`
  déplacés vers un autre bord « À venir » (Carmin est → Route 11), `test_cerulean_city` recalé.
- Barrage inchangé (J14) : levé par `cerulean_rocket_beaten` puis `cerulean_south_guard_left`.
- **Aucune hypothèse sur Léo** : les deux histoires du J14 se font dans n'importe quel ordre.
- **Tests / CA** : reprise d'une partie sauvegardée sur le raccord « ROUTE 5 — À venir » du J14
  (retombe sur la case d'Azuria, le bord mène à `route_5`) ; aller-retour Azuria ↔ Route 5 sur les
  trois colonnes (w, c, e) ; barrage présent tant que `cerulean_rocket_beaten` est faux ; Route 5,
  Pension et Carmin jouables **sans** `got_ss_ticket` comme **avec** ; marin identique avec et
  sans `ss_ticket` (T-26).

#### T24 — architecte : défaite quand toute l'équipe du joueur est K.O. — **(A, 2026-10-15)**
- Bug (`jalon-14.md` §9.2, antérieur au J14) : le dernier Pokémon apte du joueur met l'adversaire
  K.O. et tombe du même coup (contrecoup de Lutte ; ou Destruction / Explosion **de
  l'adversaire**, règle J12 « le camp du lanceur perd ») → `Battle._check_end` déclarait la
  victoire ; le joueur repartait avec toute son équipe K.O. (plus de rencontres, un Dresseur qui
  le voit → `push_error` du `BattleDirector`, étape de combat sautée).
- **Règle retenue (Rouge/Bleu, `pret/pokered` : `HandleEnemyMonFainted` teste d'abord
  `AnyPartyAlive` → `HandlePlayerBlackOut`)** : **le joueur sans Pokémon valide perd toujours**,
  quel que soit le lanceur et même si le dernier adversaire tombe dans le même coup ; une victoire
  implique donc toujours un Pokémon valide. Correction **centrale, dans le moteur pur** :
  `_check_end(events)` (paramètre `acting` retiré) rend LOSS dès que le joueur n'a plus de Pokémon
  valide, sinon WIN si l'adversaire n'en a plus. Tout le reste suit le chemin d'une défaite
  ordinaire, sans code nouveau : ni prix ni `beaten_<id>` (`BattleConclusion`, `outcome_flags`),
  pas de pièces du Jackpot (`PayDayPurse.is_collected`), aucune XP (aucun participant debout),
  réveil au dernier Centre (`DefeatRecovery` : `EncounterDirector` en sauvage, étape `wake_up` des
  scènes de Dresseur), argent inchangé (règle existante : rien gagné, rien perdu), combats
  rejouables (rival, Pierre, Rocket) et Grands moments selon leurs règles de défaite. Le
  contournement de `tools/simulate_mt_moon.gd` (J14 T21) devient une garde de sûreté.
- **Écart avec une valeur par défaut du J12** (`jalon-12.md` §2.10, [D, G+]) : Destruction /
  Explosion **de l'adversaire** qui met K.O. les deux derniers Pokémon donnait la victoire au
  joueur (avec une équipe entière K.O. : même bug) ; c'est désormais une **défaite** (RB).
  Destruction du joueur : défaite, inchangé. Question Q-T24 (§8) pour confirmation.
- **Garde-fou** : `TrainerWatcher.setup(…, state)` (Boot passe `GameState`) ; sans Pokémon valide,
  aucun Dresseur ne lance sa séquence, ni à la vue ni à la parole (comme les rencontres
  sauvages) ; `BattleDirector.run` / `run_request` refusent déjà un tel combat avant de tirer
  l'équipe du Dresseur (testé).
- **Tests** : `tests/unit/test_battle_party_wipe.gd` (8 : Lutte en Dresseur et en sauvage, dernier
  Pokémon qui tombe face à un Dresseur qui en a encore, deuxième Pokémon → le combat continue,
  victoire si le contrecoup est encaissé, poison / brûlure de fin de tour des deux côtés,
  poison de l'adversaire seul, Jackpot puis double K.O. → ni pièces ni prix) ;
  `test_battle.gd` et `test_battle_self_ko.gd` (double K.O. → LOSS dans les deux sens) ;
  `tests/integration/test_battle_director.gd` (équipe K.O. refusée sans tirage, Lutte contre
  Théo → LOSS, argent intact) ; `test_trainer_watcher.gd` (aucun défi sans Pokémon valide) ;
  `tests/integration/test_double_ko_defeat.gd` (vraie Boot : double K.O. contre Théo → réveil
  au Centre de Jadielle, équipe soignée, argent intact, Théo toujours à battre).
- **Laissé de côté** : une sauvegarde déjà écrite **après** le bug (équipe entière K.O. dans le
  monde) n'est pas réparée au chargement : le joueur peut marcher jusqu'à un Centre (aucun
  Dresseur ni rencontre ne l'arrête) ; les scènes scriptées à combat imposé (rival, Pierre)
  gardent le refus du `BattleDirector` (inatteignable désormais).

#### T22 — qa-mobile : **sessions 15A puis 15B** → Kevin — après T13–T21
- **15A** (départs `route_5`, `daycare_*`, vraie partie si possible) : Route 5, Pension complète
  (§4), poste nord (T-15 puis T-16, recul), souterrain (lisible sans monter la luminosité), Guérison.
- **15B** : Route 6 (Chloé inévitable, cinq autres, Papilusion : paralysie / sommeil), poste est,
  Carmin (Centre et point de repos, Boutique, Arène, arbre, Fan Club, Pêcheur, maisons, quai, marin,
  dockers), Route 11, Jackpot, objectifs ; **QA finale** sur la vraie partie de Kevin.

#### T23 — architecte : clôture
- Retrait de `qa_daycare` et de ses départs ; `etat-projet.md`, roadmap ; passation : J16 (marin et
  embarquement, navire, `vermilion_dock` non créé), J17 (arbre, porte de l'Arène), J14 (séquence
  `OffBattleLevelUp` pour le Super Bonbon), phase 10 (souterrain sans ciel). Fusion dans `main`
  (copie d'intégration ; `project.godot` et filtre d'export vérifiés).

---

## 4. Critères d'acceptation par sous-jalon

**15.0** — partie v6 migrée en v7 sans perte (équipe, Stockage, Sac, drapeaux, compagnon) ; build
v6 refuse la v7, fichier intact ; Pokémon déposé + XP en attente + niveau au dépôt relus à
l'identique ; uid uniques ; tests verts, import propre.

**15A** — Route 5 parcourable (bord nord « AZURIA — À venir » ou Azuria réelle) ; T-13, T-21, T-22 ;
Super Potion visible, Antidote caché ; rencontres H1/H2 (Miaouss vu) ; **Pension** : T-1 ; dépôt
(T-2 → T-4 → sélecteur → T-6), refus du dernier apte (T-5), K.O. déposable, compagnon effacé ;
pas comptés en marchant et en courant, pas scriptés et murs non comptés ; visite sans niveau (T-7,
100 ₽) et avec niveaux (T-8, 100 + 100 × n) ; équipe pleine (T-9) ; argent insuffisant (T-11, tout
l'argent pris, Pokémon rendu) ; capacités proposées dans l'ordre, refus possible, jamais d'oubli
automatique ; évolution proposée et annulable ; soin complet ; aucun Pokémon au jardin ; poste nord
(T-15, T-16, recul) ; souterrain : escaliers dans les deux sens, aucune rencontre, passant (T-18),
Guérison (T-19 + toast, puis plus rien) ; ≥ 58 fps, nœuds ≤ 3 000.

**15B** — Route 6 : Chloé inévitable, cinq évitables, récompenses du §6.2, répliques §15.5,
pêcheur (T-23), poste est (T-17, recul), Poké Ball, Super Potion cachée ; Carmin : T-25, Centre et
point de repos, Boutique (Super Potion 700 ₽), Arène (T-30, arbre T-29, porte inatteignable), Fan
Club (T-33, T-34), Pêcheur (T-35, aucune Canne), habitants (T-31, T-32, T-36), quai (T-26 identique
avec et sans Passe Bateau, T-27, T-28), Route 11 « À venir » ; Jackpot : pièces ramassées après
une victoire ; objectifs T-42 ; **vraie partie de Kevin** sans régression ; tests verts, import
propre, budgets tenus.

---

## 5. Cas limites (dossier §14) → tests

| Cas | Test | Attendu |
|---|---|---|
| Déposer le compagnon | `test_daycare_flow` | `companion_uid` vide après le dépôt ; aucun compagnon après rechargement ; le Pokémon rendu n'est pas compagnon |
| Déposer, puis quitter avant l'autosave | `test_daycare_flow` (sauvegarde relue juste après le dépôt) | le disque contient la Pension pleine et l'équipe sans lui |
| Quitter pendant le retrait (capacités, évolution) | `test_daycare_flow` | le disque contient l'état **d'avant** le retrait (Pokémon gardé, argent intact) |
| Retirer avec l'équipe pleine | `test_daycare` (fait) + `test_daycare_flow` | T-9, rien ne change |
| Retirer sans assez d'argent, avec 0 ₽ | `test_daycare` (fait) + flow | T-11, argent à 0, Pokémon rendu ; avec 0 ₽ : rendu gratuitement |
| Pokémon déposé au niveau 99 ou 100 | `test_daycare` (fait : plafond) + flow `daycare_lv99` | 99 → au plus 100 ; 100 → T-7, 100 ₽ |
| Plusieurs capacités dues, toutes refusées | flow | aucune apprise, les 4 anciennes gardées, pas d'oubli |
| Évolution annulée au retrait | flow + `test_daycare` (fait) | espèce inchangée ; reproposée au prochain niveau gagné en combat (règle existante) |
| Pokémon empoisonné ou K.O. déposé | `test_daycare` (fait) | déposable ; rendu soigné (PV, statut, PP) |
| Partie sauvegardée sur « ROUTE 5 — À venir » du J14 | `test_route_5` (T21, A) | la reprise retombe sur la case d'Azuria ; le bord mène à `route_5` |
| v6 chargée par v7 ; v7 lue par v6 | `test_save_j15` | migration sans changement ; refus `ERR_INVALID_DATA`, fichier intact |
| Arrivée à Carmin sans puis avec Passe Bateau | `test_vermilion_life` (A, sans) + T21 (avec) | même réplique T-26, embarquement inatteignable |
| (en plus) pas scriptés, mur, course | `test_daycare_step_counter` | seul le pas libre compte, course = marche |
| (en plus) Jackpot adverse, fuite | `test_battle_pay_day` (B) | rien n'est versé |

---

## 6. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Fichiers chauds** (`boot.gd`, dialogue, `game_state.gd`, `save_system.gd`, interiors) modifiés par J12/J13 en parallèle | conflits à la fusion | ajouts courts et groupés (§1.2) ; fusion de `main` dans `jalon-15` après chaque jalon fusionné |
| **Numéro de sauvegarde** si un autre jalon change le format avant le J15 | deux v7 | « le second fusionné renumérote » ; test de version mis à jour |
| **15A et 15B bloqués** par le J12 (souterrain, objets cachés, Jackpot) et le J13 (rencontres) | sessions téléphone tardives | tout le reste prêt en (A) ; la Pension vérifiée sur `qa_daycare` (captures, tests) bien avant |
| **Route 5 v2 et vues générales** pas encore validées | cartes en attente | T12, T4–T6, T10 avancent sans elles |
| **Budget de Carmin** (navire, quai, mer) | nœuds, mémoire | mesure au premier passage ; navire en un ou trois sprites ; repli `vermilion_dock` (F-12) |
| **Séquence de retrait longue** (dialogues, plusieurs capacités, évolution) | lenteur, retour Android ambigu | un seul verrou, routage explicite du retour, test du déroulé complet |
| **Échec intermittent connu** de `tools/test.sh` sous charge (« Parameter "t" is null » au chargement d'une carte) | faux rouge | non traité ici ; relancer le fichier seul avant de conclure ; noter l'occurrence |
| **Doublons de prénoms entre jalons** | confusion | défauts §0.2 n° 9 ; hors J15 : « Clara » existe au J13 et au J14 (signalé) |

---

## 7. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Branches | `jalon-15` (copie dédiée), `origin/main` fusionné au T1 ; tâches `j15-t<n>-*` |
| Identifiants | cartes et spawns du §1.3 ; Dresseurs `route_6_*` (Gabin, Basile au lieu de Lucas, Timéo) |
| Données | fichiers nouveaux `kanto_vermilion.json`, `moves/vermilion.json`, `items/vermilion.json`, `trainers/route_6.json`, `shops/vermilion_mart.json` |
| Pension | gardien `old_man` au comptoir ; dialogue « action seule » ; directeur qui choisit l'identifiant ; écriture immédiate au dépôt, une seule à la fin du retrait ; T-10/T-11 avant capacités et évolution, T-12 à la fin |
| Jetons | `{price}` sans symbole ; `{pokemon}` = nom affiché |
| Jackpot | 2 × niveau par utilisation, camp du joueur seulement, versé à la victoire ou à la capture, sauvage compris |
| Guérison | `heal_amount` 999 + cinq statuts ; non vendue |
| Souterrain | `interior = false`, hors `caves.json`, profil `underground`, 6 appliques `sconce` ; ciel : rien avant la phase 10 |
| Postes | Route 5 intérieur (garde, drapeau `route_5_gate_warned`) ; Route 6 garde extérieur |
| Inatteignables | warps `coming_soon` (Arène, S.S. Anne, Safrania, Route 11) |
| Art | série 17 ; décor de combat `route_5_6_prairie` partagé ; Persan au lot parallèle si budget |
| Compagnon | aucun contexte « souterrain » (repli « route ») |
| Zones | service `daycare` « Pension » ; aires de Carte pour les deux routes |
| Budgets | ≤ 3 000 nœuds ; ≥ 58 fps moyens, creux ≥ 50 ; mémoire ≤ 64 Mo « carte + voisines » |
| Sauvegarde | v7 (ou suivante si renumérotée) |

---

## 8. Questions pour Kevin

Aucune décision de game design ne manque : tout le reste a une valeur par défaut (§7).

- **Q-1 — Lot de textes de l'annexe A** (non couverts par le §15 : messages du Jackpot, zones,
  panneaux des grilles, PNJ des grilles sans réplique, sous-titre de l'Arène, note de Pokédex).
  *Recommandation : relecture en une passe, comme aux J9–J12 ; bloque quelques données (T12,
  T15, T17), pas le code.* Alternative pour les PNJ sans texte : les retirer des grilles.

- **Q-T24 — Explosion / Destruction de l'adversaire qui met K.O. les deux derniers Pokémon**
  (T24, 2026-10-15). Le J12 avait retenu par défaut « le camp du lanceur perd » [D] : le joueur
  « gagnait » alors avec toute son équipe K.O. (le bug de T24). T24 applique la règle de
  Rouge/Bleu : **défaite du joueur dans tous les cas**. *Recommandation : garder RB.* Revenir à
  l'ancien sens imposerait de réveiller le joueur au Centre après une « victoire ».

**À fournir par Kevin** (pas une question) : la sauvegarde v6 de sa vraie partie pour T3 et la QA
finale.

---

## Annexe A — Textes VALIDÉS par Kevin le 2026-10-14 (Q-1)

Conventions des lots précédents : bulles de 2 lignes de ~40 caractères, ton léger.

### A.1 Combat (Jackpot)

- Utilisation : « Des pièces s'éparpillent partout ! »
- Fin de combat : « Tu ramasses {money}. » (comme « Tu remportes 280 ₽. »)

### A.2 Zones (Carte, Pokédex)

- Route 5 — sous-titre « Azuria — Safrania » ; « Une route verdoyante entre les jardins, au sud
  d'Azuria. On y croise la Pension, puis l'entrée d'un vieux passage. »
- Passage souterrain — sous-titre « Route 5 — Route 6 » ; « Un long couloir de pierre qui passe
  sous Safrania. Le silence n'y est troublé que par l'écho des pas. »
- Route 6 — sous-titre « Safrania — Carmin-sur-Mer » ; « Une route ouverte où l'air sent déjà le
  sel. Au bout, les grues et les mâts du port de Carmin. »
- Carmin-sur-Mer — « Une ville tournée vers le large, où les grands navires font escale. La
  lumière dorée y danse sur l'eau des quais. »

### A.3 Panneaux

- Route 5, carrefour : « SAFRANIA → · PASSAGE SOUTERRAIN ← »
- Route 6, poste : « SAFRANIA — Poste de garde »
- Carmin, quai : « QUAIS — S.S. ANNE »
- Arène (sous-titre de T-30) : « Le Soldat de la Foudre »

### A.4 Personnages sans réplique au §15

- Route 6, promeneur : « Tu sens ce vent ? La mer n'est plus très loin. »
- Carmin, enfant : « Un jour, je monterai sur ce grand bateau. Tout là-haut, sur le pont ! »
- Fan Club, membre 2 : « Mon Miaouss adore qu'on parle de lui. Regarde comme il se tient droit ! »
- Maison 2, habitante (« le navire ») : « Le S.S. Anne ne reste jamais longtemps. Quand il
  repart, toute la ville vient le saluer. »

### A.5 Pokédex

- Note de la forme de base (Miaouss) : « On l'entend miauler la nuit près des quais, là où
  traînent des pièces tombées des poches. »
