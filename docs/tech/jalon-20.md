# Jalon 20 — Route 8, souterrain, Route 7, Céladopole, Erika et le repaire Rocket

> Objectif jouable sur le téléphone : **les lumières et les ombres**. Depuis le bord ouest de
> Lavanville (J18), la **Route 8** (7 Dresseurs, deux chemins, poste fermé vers Safrania), le
> **souterrain ouest-est** silencieux (2 objets cachés), la **Route 7** en pente douce, puis
> **Céladopole** : Centre, **grand magasin** à 5 étages, toit et **ascenseur**, **Résidence** et la
> maison du toit où attend **Évoli** (don), restaurant, hôtel, maison du chef, **Arène d'Erika**
> derrière son arbuste (Badge Prisme, CT21 Méga-Sangsue). Sous le **Casino** aux machines éteintes,
> l'affiche, l'interrupteur, et le **repaire Rocket** : B1F à B4F en géométrie Rouge/Bleu, **dalles
> tournantes**, **Clé Ascenseur**, **Giovanni**, et le **Scope Sylphe**, qui rend identifiables les
> spectres de la Tour (règle du J19). Fin du jalon au Scope.
>
> Mécaniques nouvelles : **ascenseur** (grand magasin et repaire, une seule mécanique),
> **dalles tournantes** (déterministes, réutilisables à Jadielle), **don de Pokémon** (Évoli).
> Petits ajouts au moteur : **objets de combat** (Poupée Poké, objets X), **Rappel**, **une boutique
> par vendeur**, **CT achetable une fois**, **condition d'objet** dans un dialogue (échange de la
> fillette du toit). Tout le reste est du contenu sur des systèmes existants.

**Pré-requis.** Dossier 23 **verrouillé** (2026-10-14 : H-1 à H-14, textes §20, valeurs §21) et
**grilles v1 validées** (2026-10-15, 29 grilles) : c'est la **source de vérité**. Règle **C-7** : le
**code** du J20 commence **après la clôture du J19** (un seul jalon à la fois dans le moteur de
combat et dans la sauvegarde). Avant, seulement : documents, **données dans des fichiers
nouveaux** (sur une branche non fusionnée), **logique pure en fichiers nouveaux**, art, outils de
simulation en lecture seule.

Plan écrit sur `docs/plan-j20` (base `origin/main` = `440f9b17` + dossier et grilles du J20 ;
fusion `39e69e43`). **Code lu** : `main` à `440f9b17` (**J15 terminé, sauvegarde v7**). **Lus sans
les modifier**, pour le contrat d'entrée : J16 sur `origin/ccr-fa255d49-wvvacc` (`776ec16d`,
`docs/tech/jalon-16.md` + code partiel : `FieldMoves`, `SwitchPuzzle`, `moves_j16.json`,
`items_j16.json`) ; J17 sur `origin/docs/dossier-20-j17` (`c63bb47f`, plan seulement) ; J18 sur
`origin/docs/dossier-j18` (`91a598f9`, plan + grille `lavanville.txt`) ; J19 sur
`origin/docs/dossier-j19` (`ed49ea83`, plan seulement). Quand un nom n'existe que dans un plan,
c'est écrit « (plan J1x) ». **La tâche d'ouverture (T9) réaligne ce plan sur le code du moment.**

Références : `CLAUDE.md` (règles 1 à 10), `docs/design/dossier-23-celadopole.md`,
`docs/design/passes/j20-v2-alignement.md`, grilles `tools/plans/` du J20 et leurs profils
(`tools/art/plan_check_routes_j20.py`, `plan_check_celadopole.py`, `plan_check_repaire.py`),
modèles de forme `jalon-15.md` et `jalon-13.md`.

Notation : « T-n » = texte n° n du lot **validé** (dossier 23 §20) ; les numéros 61 et suivants sont
ceux de l'**annexe A** (à valider). « [D] » = valeur par défaut (règle 4, §8).

---

## 0. État des lieux et écarts

### 0.0 Fusions de `main` (`aebbd857`, puis `d397b2df`) dans `jalon-20` (2026-10-19)

`main` contient désormais le **J15, le J16 et le J17 terminés**, le découpage du Boot (PR #1 :
`SaveCoordinator`, `SettingsApplier`, `SessionLifecycle`) et une CI GitHub ; puis le **J18**
(`d397b2df`, fusionné le même jour, voir plus bas). Le J19 n'est **pas** fusionné : le T9 reste
à faire après lui. Les §0.1 à §0.3 ci-dessous datent de
`440f9b17` et restent à relire au T9.

- **Apporté par J16 / J17 et utile au J20** : CS01 Coupe hors combat (`FieldMoves`,
  `data/world/field_moves.json`, deux arbustes au J17), CS05 Flash et voile d'obscurité
  (`FlashDirector`, `FlashRules`, `"dark": true` dans `caves.json`), compatibilités CS
  (`hms`, `hm_species` dans `tm_compatibility.json`), Major Bob (carte de Champion), sauvegarde
  **toujours v7**.
- **Doublons retirés (ancienneté : le J17 gagne)** : Caninos et Goupix sortent de
  `kanto_celadon.json` (ceux de `kanto_j17.json`, identiques, restent ; le J20 leur ajoute
  seulement la Pierre Feu, comme prévu au §2.10.1) ; Bélier et Hurlement sortent de
  `moves/celadon.json` (ceux de `moves/j17.json`, identiques) ; fiches de Pokédex de Caninos et
  Goupix : **textes du J17 gardés** (les n° 191 et 193 de l'annexe A ne sont plus utilisés) ;
  sprites provisoires identiques des deux côtés. Aucun objet, Dresseur, boutique ni table de
  rencontres en double. `tm_compatibility.json` régénéré (`tools/gen_tm_compatibility.py`) :
  83 espèces, CT34 79 / 83, entrées de `main` inchangées.
- **Logique J20 non branchée** (`spin/`, `elevator/`, `gift/`) : APIs appelées inchangées
  (`GameState.flags/party/storage/rng`, `record_caught`, `stamp_meeting`, `Party.add`,
  `PokemonStorage.add`, `PokemonFactory.create`, `Pokemon.Origin`), aucune adaptation.
- **Seconde fusion, `main` à `d397b2df` (J18 terminé, même jour)** : Route 9, Route 10 et son
  Centre, Grotte Sombre, Lavanville, Tour RDC. Aucun identifiant en double avec le J20 (le J18
  n'ajoute ni espèce, ni capacité, ni objet, ni fiche de Pokédex ; ses Dresseurs, tables et
  boutique `lavender_mart` ont des noms distincts). `tools/art/plan_aplats.py` garde les deux
  côtés ; `celadopole-plan-v1.png` se régénère au pixel près, `plan_check.py` conforme.
- **Prénoms des Dresseurs de la Route 8 renommés (le J18 les avait pris ; valeur par défaut,
  règle 4, validés par Kevin le 2026-10-19)** : Intello Hector → **Intello Anatole**
  (`route_8_nerd_anatole`), Intello Simon → **Intello Firmin** (`route_8_nerd_firmin`),
  Fillette Lou → **Fillette Margot** (`route_8_lass_margot`), Joueur Gilles → **Joueur Fernand**
  (`route_8_gambler_fernand`). Seuls les noms changent : équipes, récompenses et répliques de
  l'annexe A (n° 101, 103, 107, 108) restent celles validées.
- **Raccord Lavanville ↔ Route 8, relu sur la carte réelle du J18** (fichiers du J18 non
  modifiés) : carte `lavender_town` ; warps `Route8N|C|S` en (0, 10..12), `PUSH ←`,
  `target_map` vide, `coming_soon = "Route 8"`, `target_spawn = from_route_8_n|c|s` (provisoire) ;
  arrivées `from_route_8_n|c|s` en (1, 10..12), tournées →. Le §2.1 tient : la Route 8
  (79, 10..12) cible `lavender_town` / `from_route_8_n|c|s`. **Au T15**, dans
  `tools/build_lavender_town.gd` (boucle « Ouest », ≈ l. 194–201) : retirer le `coming_soon`,
  cibler `route_8` / `from_lavender_n|c|s`, régénérer la carte. `lavender_town` existe déjà :
  le repli « bord est en `coming_soon = "Lavanville"` » du §0.3 devient inutile. À vérifier au
  T15 : `route_8.txt` pose `from_lavender` **sur** la colonne du warp (79), alors que le J18
  place ses arrivées une case à l'intérieur (1) ; aligner (78) si le kit l'exige. Dans
  `route_8.txt`, `spawn=from_route_8` devient `from_route_8_n|c|s` (une par rangée).
- **Reste au T9** : fusion du J19 (Caninos du J19, effets de Bélier et Hurlement codés au J19,
  Spectres et Scope Sylphe), relecture des §0.1–0.3 sur le code du moment, branchement dans le
  Boot découpé (blocs « J20 » dans `boot.gd` ou ses nouveaux coordinateurs), `data/j20_pending/`
  au T11.

### 0.1 Ce qui existe pour chaque besoin du dossier (`main` à `440f9b17`)

| Besoin (dossier 23) | Existant sur `main` (vrais noms) | Apporté par J16–J19 (non fusionné) | Manque |
|---|---|---|---|
| Cartes, passages | `GameMap`, `WarpPoint` (`trigger`, `direction`, `target_map`, `target_spawn`, `arrival_facing`, `coming_soon`), `Warp` (champs simples, modifiables), `WarpTable` (`find_on_step`, `find_on_push`) ; `SceneRouter.change_map`, `show_coming_soon`, `_follow` (`scene_router.gd:399`) ; `MapCatalog` (id = nom de scène) ; `PlanGrid` (`tests/helpers/plan_grid.gd`) | J18 : `lavender_town`, bord ouest (0, 10..12) `coming_soon = "Route 8"`, arrivée réservée `from_route_8` (1, 10..12) | 32 cartes (§2.1) |
| Raccord est (Lavanville) | — | J18 (plan + grille) : `tools/build_lavender_town.gd` (plan) | retrait du `coming_soon` (T15) |
| Arbustes à Couper | rien | **J16 (code)** : `FieldMoves` (`game/world/field/field_moves.gd`, `data/world/field_moves.json` : `cut` → `hm01` + `badge_cascade`) ; arbuste = PNJ objet `object/cut_tree`, `verb: examine`, `unless: [cut_<id>]`, dialogue `cut_tree` (variantes ARB-00 à 03), `confirm_cutscene: "cut_tree_<id>"`, étape de scène `field_move` | 2 arbustes (`celadon_gym_bush`, `celadon_gym_inner_bush`), données seulement |
| Objets visibles | modèle J8 : PNJ `object/poke_ball_ground`, `verb: take`, `unless: [got_<id>]`, scène `give … found: true` | — | — |
| Objets cachés | `InteractPoint.unless_flags` (`interact_point.gd:21`), `_add_hidden_item` (`tools/build_route_24.gd`), `HIDDEN_ITEMS` (`build_mt_moon.gd`), tests `test_hidden_items`, `test_hidden_item_point` | — | rien : 6 caches |
| Décor conditionnel | `FlagGate` (`if_flags`, `unless_flags`, `blocking_cells` J15) ; réappliquée à chaque drapeau changé pendant la visite | — | mur coulissant du Casino, porte du bureau (§2.6, §2.7) |
| Dresseurs | `TrainerLibrary` (dossier lu en entier) ; bloc `trainer` des PNJ (`id`, `sight` 1..8, `before`, `defeated`, `rematch`, `leave`) ; `TrainerWatcher` (`_on_player_moved` ignore les pas sans entrée, l. 61-63) ; IA `random` / `smart` ; changement de Pokémon (`switch`, J13) ; `card`, `start_message`, `end_message` | J16 : `vermilion_gym`, `ss_anne` ; J17 : `route_11` ; J19 : `pokemon_tower` | 22 Dresseurs + Erika + Giovanni (§2.10.6) ; relance de la vue après une glisse (§2.4) |
| Scènes | `CutsceneLibrary` : `wait dialogue face set spawn move change_map hop lean despawn battle give scare caption take wake_up react emote champion_card badge moment flash` ; `next` ; conditions `if` / `unless` sur chaque étape | J16 : `field_move` ; J19 : `wild_battle` | étape **`gift_pokemon`** (§2.5) |
| Dialogues | `DialogueLibrary` : variantes (`if`, `unless`, `set`, `auto`, `one_in`), `choice` (`confirm_action`, `confirm_cutscene`, `confirm_set`…), `ACTIONS = heal, center_heal, open_shop, open_storage, open_daycare` ; jetons `DialogueTokens` | J16 : variantes `field` (selon l'équipe et le Sac, plan J16 T6) | action **`open_elevator`** ; clé **`shop`** ; condition d'objet (§2.9.6) |
| Boutiques | `ShopLibrary` (dossier), `ShopRules` (`max_buy`, `buy`, `sell`) ; **boutique = identifiant de la carte** (`ServiceDirector`, `service_director.gd:147`) | — | une boutique par vendeur ; CT achetable une seule fois (§2.9) |
| Objets | 22 objets (`items.json`, `items_j14.json`, `mt_moon.json`, `vermilion.json`) ; catégories `BALL HEAL BATTLE FIELD KEY TM` ; `field_use` : `escape_rope`, `evolution_stone`, `rare_candy` ; **aucun objet BATTLE** ; `ItemUse` refuse un Pokémon K.O. (Q-11 du J6) | J16 : `hm01`, `tm24`, `super_potion` (doublon de `vermilion.json`, à régler par le J16) ; J17 : `hm05` | §2.10.4 |
| Pierres d'évolution | `StoneUse` (`game/pokemon/evolution/stone_use.gd`), `Evolution.item_target`, `EvolutionDirector.play_item` (non annulable), règles `"method": "item"` ; `pikachu → raichu (thunder_stone)` **déjà dans les données** | — | 4 pierres, 7 règles nouvelles (§2.10.2) |
| CT | `TmTeach` (CT permanente, jamais vendue ni consommée) ; `tm01` Ultimapoing (Mont Sélénite), `tm11`, `tm19`, `tm28`, `tm34` ; `tools/gen_tm_compatibility.py` (fichier généré) | J16 : `tm24` Tonnerre | `tm13`, `tm21` (§2.10.3) |
| Capacités | 103 (dont `horn_drill`, `reflect`, `light_screen`, `submission`, `double_edge` **« Sans effet dans le moteur actuel »** : `pending_effects`) ; effet `drain` joué (`absorb`, `leech_life`) | J17 : `hypnosis`, `headbutt`, `poison_gas`, `meditate`, `roar` (en attente), `flash` ; J19 : `lick`, `night_shade`, `bone_club`, `dragon_rage` | `mega_drain` + 7 capacités d'apprentissage (§2.10.2) |
| Espèces | **64** (`kanto.json`, `kanto_j14.json`, `kanto_mt_moon.json`, `kanto_vermilion.json`) ; `PokemonData` lit tout `species/` | J17 (plan) : `diglett`, `dugtrio`, `drowzee`, `hypno`, `magnemite`, `magneton`, **`growlithe`, `vulpix`** (adversaires seulement) ; J19 (plan) : `gastly`, `haunter`, `cubone`, `marowak`, **`growlithe`**, `gyarados`, `exeggcute` | §2.10.1 |
| Don de Pokémon | capture : `BattleDirector._finish_capture` (`party.add` sinon `storage.add`, `record_caught`, `stamp_meeting(CAPTURE)`) ; starter : `Boot` (l. 1351) ; `Pokemon.Origin = UNKNOWN, STARTER, CAPTURE` (sauvé en texte, `ORIGIN_NAMES`) | — | `PokemonGift` + `Origin.GIFT` (§2.5) |
| Surnom | `Pokemon.nickname` existe, **aucun écran de surnom** (ni à la capture) | — | rien (§2.5, défaut) |
| Grands moments | `MomentLibrary.TYPES = starter, rival_battle, first_capture, zone_arrival, badge, fossil, bill_restored` ; `data/trainer/moments.json` ; étape `moment` | J16–J19 : peut-être d'autres types (fin de liste) | type `giovanni`, arrivée `celadon_city` (§2.11) |
| Badge | `data/badges.json` : `rainbow` « Badge Prisme », Erika, Céladopole, `badge_rainbow` ; étape `badge` | — | rien |
| Grottes, Corde Sortie | `CaveLibrary` + `data/world/caves.json` (`maps`, `escape`) ; `FieldItemRules` | J18 : clé `dark` | entrée `rocket_hideout` (§2.7) |
| Lumière | profils `golden_hour`, `interior_warm`, `forest`, `cave_*`, `underground` (J15) ; `LightGlow` + `light_glows.json` | J18 : `lavender` ; J19 : profils de la Tour (plan) | `hideout`, `greenhouse`, halo `neon` (§2.1) |
| Points de repos | `data/world/rest_points.json` (Centre = `registers: true`) ; `DefeatRecovery` (dernier point enregistré) | — | `celadon_center` |
| Zones, Carte | `zones.json` : **`route_8`, `route_7`, `celadon_city` déjà présentes, `maps: []`** ; `saffron_city` sans carte | — | `maps`, services, descriptions (§2.11) |
| Objectifs | `data/story/objectives.json` : première entrée valide, en tête = plus avancée | J16–J19 : leurs objectifs en tête | 4 objectifs (§2.11) |
| Compagnon | `CompanionController.on_cutscene_started / finished` (se rétracte, ressort), `companions.json` (`species`, `contexts`) | — | contextes et rétraction (§2.12) |
| Sauvegarde | **v7** (`save_system.gd:36`) ; `Boot.is_stable()` (entrée libre, ni dialogue, ni scène, ni combat, ni transition) garde **tout** autosave ; `GameState.set_player_location` | J16–J19 : **aucune version nouvelle** (preuves : `jalon-16.md` §2.12, `jalon-17.md` §2.15, `jalon-18.md` §3.6, `jalon-19.md` §2.13) | **rien** (§2.13) |
| Tour Pokémon (Scope) | — | **J19 (plan)** : tables `"ghost_unless_item": "silph_scope"` ; 6F `ghost: always` ; Scope = identifiant brut dans le Sac (testé sans donnée d'objet) | objet `silph_scope` (§2.7.5) |
| Audio | `game/systems/audio/` **vide** : aucun son dans le jeu | — | rien (sons des dalles et de l'ascenseur : signaux posés, son à la phase audio) |

### 0.2 Écarts et trous constatés

1. **13 espèces, pas 12.** Le tableau du dossier §15.1 en énumère 13 (Caninos, Goupix, Évoli,
   Empiflor, Saquedeneu, Rafflesia, Rhinocorne, Kangourex, Arcanin, Feunard, Aquali, Voltali,
   Pyroli). Le texte dit « 12 au minimum ». Le plan suit le tableau : **13**, moins celles créées
   par un jalon fusionné avant (J17 et J19 créent Caninos ; J17 crée Goupix, en adversaire seulement).
2. **« Capacité existante » (H-7)** : sur `main`, Empal'Korne, Protection, Sacrifice et Damoclès
   **existent dans les données mais ne font rien** (`pending_effects`, « Sans effet dans le moteur
   actuel »). La passe H-7 cite justement Empal'Korne comme « mécanique absente », et le dossier 09
   §9 dit « jamais un objet pour une mécanique absente ». Règle retenue [D] : une CT est retenue si
   sa capacité **existe et est jouée** (aucun `pending_effects`). Conséquence : **3 CT** (§2.10.3),
   et le vendeur de CT du 2e ne propose que la CT01, déjà trouvable au Mont Sélénite → **Q-2**.
3. **Une boutique par carte** : `ServiceDirector` ouvre la boutique qui porte **l'identifiant de
   la carte**. Le 2e et le 4e ont **deux** vendeurs, le toit **trois** distributeurs. Petit ajout :
   clé `shop` d'une variante de dialogue (§2.9.1).
4. **Une CT ne se vend pas** aujourd'hui (`is_sellable` faux, prix absent) et le Sac n'en garde
   qu'une. L'acheter demande : un prix, un achat limité à 1, refusé si elle est déjà dans le Sac
   (§2.9.2).
5. **Aucun objet de combat** (catégorie BATTLE vide) : la Poupée Poké et les objets X demandent une
   action de combat « objet sur soi » (§2.9.3). H-8 : objets X **vendus**, puisque le moteur gère les
   niveaux de statistiques (`MoveEffect.STAGE_STATS`).
6. **Aucun objet ne ranime** (Q-11 du J6, « pour l'instant ») : le Rappel, vendu au 2e et valeur
   de remplacement de plusieurs objets RB (H-8, §21), l'introduit (§2.9.4).
7. **Aucun écran de surnom** dans le jeu, ni à la capture. Le dossier §10 dit « proposition de
   surnom comme pour une capture » : la capture n'en propose pas, donc **le don non plus** [D]. Le
   jour où un écran de surnom existera, il servira aux deux.
8. **Dialogues selon le Sac** : la fillette du toit réagit à la boisson que le joueur porte ; les
   variantes de dialogue ne lisent que des drapeaux (le J16 ajoute des variantes `field` selon
   l'équipe et la CS : T9 regarde s'il suffit de les généraliser). Ajout : `if_items` /
   `unless_items` (§2.9.6).
9. **Le Rocket du Casino** : la grille le range en (11, 6) après sa défaite, mais un Dresseur ne
   peut pas avoir d'autre place (`moved` refusé avec `trainer`). Défaut : bloc `trainer.leave`
   existant (J12), **il quitte la salle** par l'allée ouest (le dossier : « il s'éloigne »).
10. **Porte du bureau** (deux gardes battus) : `FlagGate` ne sait pas dire « tous deux battus »
    sauf avec `if_flags`, et ici il faut **cacher** la porte quand les deux drapeaux sont levés.
    Défaut : un drapeau dérivé `rocket_hideout_b4f_door_open`, posé par la réplique « défaite » de
    chaque garde (variante `if` les deux `beaten_*`), données seulement (§2.7.3).
11. **Identifiants des grilles** : plusieurs sont en français ou varient d'une grille à l'autre
    (`safrania_gate_r8`, `underground_entrance_r7`, `game_corner` / `celadon_game_corner`,
    `tm_horn_drill`, `from_poste`…). Normalisation au §1.3 (géométrie inchangée, comme au J15).
12. **Défaite dans le repaire** : le dossier dit « réveil au Centre de Céladopole ». Le moteur
    réveille au **dernier point de repos enregistré** (soin au Centre). Défaut : règle existante ;
    en pratique Céladopole (le Centre est à 13 pas de l'entrée est). Pas de point forcé.
13. **Tartard du pêcheur** : Tartard n'est pas dans les données. Défaut : Pokémon de décor **sans**
    OBSERVER ni Pokédex (pas de clé `species`), planche minimale au lot d'art, ou retiré si le lot
    ne suit pas.
14. **Ascenseur et sauvegarde** : la destination de la cabine n'est pas sauvée. Défaut : **la cabine
    n'est jamais une position de sauvegarde** ; une écriture faite dans la cabine enregistre la case
    d'arrivée de l'étage courant (§2.3.5). Dossier §17 et §19 respectés.
15. **Le repaire est une « grotte » pour la Corde Sortie** : `caves.json` est la seule façon de
    l'autoriser et d'y donner la destination (`from_casino`). Il garde `interior = false`
    (compagnon visible, dossier §19 : il se rétracte sur les dalles et dans l'ascenseur).
16. **Sons** : aucun système audio. Les directeurs émettent des signaux (`slide_started`,
    `slide_finished`, `ride_started`) ; le son viendra avec la phase audio.
17. **Budget de nœuds de Céladopole** : 70 × 46 = 3 220 cases, au-dessus des 2 288 d'Argenta et
    proche de la limite de 3 000 nœuds (Azuria 56 × 41 la tient). Mesure dès la première
    construction (§2.15).

### 0.3 Contrat d'entrée (J16 à J19) et protections

| Le J20 suppose | Jalon | État lu (2026-10-15) | Protection du plan |
|---|---|---|---|
| **Coupe** hors combat (CS01 + Badge Cascade), arbuste = PNJ `object/cut_tree` + dialogue `cut_tree` + scène `cut_tree_<id>` + drapeau `cut_<id>` | J16 | code partiel sur `ccr-fa255d49-wvvacc` (`FieldMoves`, `field_moves.json`, étape `field_move`) | T9 relit les vrais noms ; les deux arbustes du J20 ne sont que des **données** ; départ `celadon_gym` (dans l'Arène) pour éprouver Erika sans Coupe |
| Lavanville raccordée par son bord ouest (0, 10..12), arrivée `from_route_8` | J18 | grille et plan ; `coming_soon = "Route 8"` posé par `build_lavender_town.gd` (plan) | Route 8 construite avec son bord est en `coming_soon = "Lavanville"` **tant que** `MapCatalog.has_map(&"lavender_town")` est faux (outil et test) ; raccord réel au T15 |
| Spectres conditionnés à `silph_scope` **dans le Sac** ; 6F `ghost: always` | J19 | plan : `ghost_unless_item`, tests avec l'identifiant brut | le J20 crée seulement l'objet ; test « Tour avec Scope » **sauté** si `pokemon_tower_3f` n'existe pas |
| Rival n° 5 battu ; aucun rival au J20 | J19 | plan | rien |
| Équipe ≈ N25–28 à l'arrivée | J19 | plan (rival n° 5 RB : 20–25) | simulation d'Erika et de Giovanni (T8) sur plusieurs profils |
| Espèces : Soporifik, Magnéti, Caninos, Goupix (J17) ; Fantominus, Spectrum, Osselait, Caninos (J19) | J17, J19 | plans | §2.10.1 : chaque espèce a **son créateur** et **un remplacement** si elle manque à T9 |
| Sauvegarde v7 | J15–J19 | v7 partout | test `test_save_j20` : `VERSION == 7` |
| Objectifs, moments, zones en tête ou en fin de fichiers uniques | J16–J19 | — | ordre du voyage réglé à T9 (« garder les deux côtés ») |

**Règles des branches** : branche d'intégration **`jalon-20`**, dans une copie dédiée (mémoire
« worktree d'intégration »), créée au **T9** depuis `main` (J19 fusionné). Avant T9, les tâches (A)
vivent sur des branches `j20-t<n>-<sujet>` **non fusionnées**, en **fichiers nouveaux** ; elles
sont fusionnées dans `jalon-20` au T9 ou juste après. Ajouts aux fichiers uniques **en fin de
fichier** (`zones.json`, `interiors.json`, `rest_points.json`, `lighting.json`, `light_glows.json`,
`caves.json`, `data/pokedex/kanto.json`, `moments.json`, `companions.json`,
`tools/art/manifeste.json`, `build_character_frames.gd`) ; `objectives.json` **en tête**.

**Fichiers chauds** (touchés aussi par J16–J19) : `game/boot.gd`, `dialogue_library.gd`,
`dialogue_runner.gd`, `dialogue_variant.gd`, `cutscene_library.gd`, `cutscene_step.gd`,
`cutscene_director.gd`, `item_data.gd`, `item_library.gd`, `item_use.gd`, `game/battle/battle*.gd`,
`shop_rules.gd`, `service_director.gd`, `trainer_watcher.gd`, `pokemon.gd`,
`tools/build_painted_interiors.gd`. Le J20 y fait des **ajouts courts et groupés** (un bloc commenté
« J20 »), jamais de réécriture, et **seulement en (B)**.

---

## 1. Découpage

### 1.1 Sous-jalons et validations (dossier §22, H-2)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **20.0a** (avant la clôture du J19) | ce plan ; lot de textes complémentaire (annexe A) ; kit d'assets et art (espèces, PNJ, fonds de combat) ; **logique pure** des dalles, de l'ascenseur et du don ; **données** en fichiers nouveaux (non fusionnées) ; **simulations** d'Erika et de Giovanni | Kevin : textes, planche d'art, niveaux (Q-1, Q-3) ; tests GUT sur les branches |
| **20.0b** (ouverture, après le J19) | alignement (T9) ; intégration de l'art et des données ; **objets nouveaux dans le moteur** (Rappel, Poupée Poké, objets X, boutiques) | **combats de test** (dossier §22) : tests GUT + captures Mac, aucune session téléphone |
| **20-I** (lots V 20A–20C) | Route 8, souterrain, Route 7, postes ; Céladopole et ses intérieurs ; **ascenseur** (grand magasin) ; **don d'Évoli** ; pierres ; Arène, Erika, Badge Prisme, CT21 | **S24** |
| **20-II** (lots V 20D–20F) | Casino, interrupteur ; repaire B1F–B4F ; **dalles tournantes** ; Clé et ascenseur du repaire ; Giovanni ; Scope ; contrôle de la Tour ; **QA finale** de Lavanville au Scope en vraie partie | **S24** + fusion |

- **Jamais trois systèmes à la fois** : 20.0b = objets de combat (petits, sans risque de
  sauvegarde) ; 20-I = ascenseur + don ; 20-II = dalles (l'ascenseur du repaire réutilise celui du
  20-I). Les deux mécaniques à risque (dalles, ascenseur) ont chacune leur test automatique de
  reprise en plus de la session.

### 1.2 Tâches : (A) avant la clôture du J19, (B) après

| Tâche | Agent | Quand | Dépend de | Comment avancer sans conflit |
|---|---|---|---|---|
| T0 Plan (ce document) | architecte | fait | — | docs |
| T1 Lot de textes complémentaire → Kevin | architecte + Kevin | **(A)** | — | annexe A de ce plan |
| T2 Kit d'assets (série « prochain numéro libre ») | architecte | **(A)** | vues générales validées | fiche et outil nouveaux |
| T3 Génération Codex, planches PNJ et Pokémon, dos | constructeur-monde (Mac) | **(A)** | T2 | `build/art/` |
| T4 Logique pure : dalles | architecte | **(A)** | — | `game/world/spin/` (nouveau) |
| T5 Logique pure : ascenseur | architecte | **(A)** | — | `game/world/elevator/` + `data/world/elevators.json` (nouveaux) |
| T6 Logique pure : don | architecte | **(A)** | — | `game/systems/gift/` (nouveau) |
| T7 Données (espèces, capacités, objets, Pokédex, Dresseurs, rencontres, boutiques, dialogues) | architecte | **(A)**, branche non fusionnée | T1 pour les dialogues | fichiers nouveaux |
| T8 Simulations d'Erika et de Giovanni → Kevin | architecte | **(A)**, après T7 | T7 | outil nouveau, lecture seule du moteur |
| T9 **Ouverture** : fusion de `main` (J16–J19), réalignement | architecte | **(B), premier** | clôture du J19 | — |
| T10 Intégration de l'art | constructeur-monde (Mac) | (B) | T3, T9 | fins de fichiers |
| T11 Moteur : objets nouveaux et boutiques | architecte | (B) → **20.0b** | T9 | fichiers chauds, blocs « J20 » |
| T12 Moteur : don de Pokémon | architecte | (B) | T6, T9 | idem |
| T13 Moteur : ascenseur | architecte | (B) | T5, T9 | idem |
| T14 UI : panneau d'étages, boutique (CT, objets de combat, Rappel) | ui-mobile | (B) | T11, T13 | `game/ui/elevator/` (nouveau) |
| T15 Cartes : Route 8, souterrain, Route 7, bâtiments, postes, raccord Lavanville | constructeur-monde | (B) | T10 | outils nouveaux |
| T16 Cartes : Céladopole, Centre, grand magasin, Résidence, petits intérieurs, Arène | constructeur-monde | (B) | T10 | outils nouveaux + `build_painted_interiors.gd` (bloc) |
| T17 Vie du 20-I (PNJ, Dresseurs, objets, Évoli, Erika, objectifs, zones, départs) | constructeur-monde | (B) | T7, T11–T16 | données |
| T18 Session **20-I** | qa-mobile | (B) | T17 | — |
| T19 Moteur : dalles tournantes | architecte | (B) | T4, T9 | `game/world/spin/` + Boot (bloc) |
| T20 Cartes : Casino, repaire B1F–B4F, cabine | constructeur-monde | (B), en parallèle de T17 | T10 | outils nouveaux |
| T21 Vie du 20-II (Casino, Dresseurs, Clé, porte, Giovanni, Scope, Tour, départs) | constructeur-monde | (B) | T19, T20 | données |
| T22 Compagnon | constructeur-monde | (B) | T12, T13, T19 | `companions.json` (fin) |
| T23 Session **20-II** + QA finale (vraie partie) | qa-mobile | (B) | T21, T22 | — |
| T24 Clôture | architecte | fin | T23 | — |

**Parallélisme** : maintenant T1 ∥ T2 → T3 ∥ T4 ∥ T5 ∥ T6 ∥ T7 → T8. Après le J19 : T9 → (T10 ∥ T11
∥ T12 ∥ T13) → T14 ∥ T15 ∥ T16 → T17 → T18 ; en même temps T19 ∥ T20 → T21 → T22 → T23 → T24.

### 1.3 Grilles : lecture et normalisations (aucune géométrie modifiée)

Les grilles font foi pour la géométrie (règle 10). Leurs identifiants sont normalisés en anglais,
comme au J15 ; leurs `POSITIONS` sont des défauts « ajustables au plan ».

| Grille | Carte (`map_id`) | Normalisations |
|---|---|---|
| `route_8.txt` | `route_8` | `porte_poste` → `route_8_gate` ; `porte_souterrain` → `route_8_underground_gate` ; `from_poste` → `from_gate`, `from_souterrain` → `from_underground` ; `from_lavender` → `from_lavender_n|c|s` ; Dresseurs : §2.10.6 |
| `route_7.txt` | `route_7` | idem (`route_7_gate`, `route_7_underground_gate`) ; `from_celadon_n|c|s` |
| `souterrain_entree.txt` (×2) | `route_7_underground_gate`, `route_8_underground_gate` | `entree` → `entrance` ; `from_underground` gardé |
| `poste_safrania.txt` (×2) | `route_7_gate`, `route_8_gate` | `entree` → `entrance` ; porte de Safrania **sans warp** (grille) |
| `souterrain_7_8.txt` | `underground_path_7_8` | arrivées `from_route_7_n|s` (3, 5..6), `from_route_8_n|s` (44, 7..8) |
| `celadopole.txt` | `celadon_city` | `from_route_7_n|c|s` ; arrivées des portes à deux cases `_w|e` ; `celadon_game_corner` (pas `game_corner`) |
| `celadopole_magasin_*`, `_residence_*`, `_restaurant`, `_maison_chef`, `_hotel`, `_arene` | `celadon_dept_gf…5f`, `_roof`, `_elevator` ; `celadon_mansion_gf…3f`, `_roof`, `_roof_house` ; `celadon_restaurant`, `celadon_chief_house`, `celadon_hotel`, `celadon_gym` | `entree` → `entrance` ; `floor=` lu par l'ascenseur (§2.3) |
| `casino.txt` | `celadon_game_corner` | `entree_ville` → `entrance` ; `arrivee_b1f` → `from_hideout` |
| `repaire_b1f…b4f.txt`, `repaire_ascenseur.txt` | `rocket_hideout_b1f…b4f`, `rocket_hideout_elevator` | cibles « carte:x,y » → le spawn de la paire (`from_<paire>`, ex. `from_b2f_north`) ; `entree_gauche|droite` → `entrance_w|e` |
| objets | — | `tm_horn_drill`, `tm_double_edge`, `tm_razor_wind` → **`super_potion`** (règle §0.2 n° 2) ; `hyper_potion`, `iron` → `super_potion` ; `pp_up`, `hp_up` → `revive` (attribut `fallback=` des grilles) |

- **Portes** : `STEP_ON ↑` vers l'intérieur ; sortie des intérieurs `PUSH ↓` vers le spawn de la
  grille, tourné ↓. **Escaliers** : `STEP_ON`, `direction = ZERO` (J12), orientation à l'arrivée =
  celle de la grille. **Portes d'ascenseur** : `STEP_ON` ↑ (magasin) ou sans direction (repaire),
  comme une porte (fondu).
- **Objets cachés** (règle du J12 §1.3) : point d'examen **sur la case-indice** (bloquée) ; drapeau
  `got_<identifiant>`.
- **Accès sans issue** : la sortie ouest de Céladopole n'a aucun warp (examen T-21). La porte de
  Safrania des deux postes **s'ouvre par une boisson** (décision de Kevin du 2026-10-19, §2.16) ;
  son warp vise `saffron_city`, carte du J26.

### 1.4 Kit d'assets (T2) : série « prochain numéro libre »

Numéro vérifié sur toutes les branches au T2 (J16 = 18, J17 = 19 ; J18 et J19 : « prochain libre ») ;
« le second fusionné renumérote ». Méthode des J8–J15 : le plus petit kit modulaire qui donne la
**sensation** des vues générales validées, lumière neutre pour les objets et personnages, la grille
fait foi. Fiche `docs/design/fiches-assets/serie-<n>-celadopole.md`, outil `tools/art/serie<n>.py`.

| Groupe | Réutilisé | Nouveau |
|---|---|---|
| Routes 7 et 8 | herbe, chemins, `DenseForest`, hautes herbes, rochers, clôtures, rebords, panneaux ; enveloppe des postes (`int_poste_foret_coque`, J15) | façade du poste de Safrania et du bâtiment d'entrée (une pour les deux routes) ; vue lointaine des toits (Route 7) |
| Souterrain | sol et murs du souterrain du J15, appliques `sconce` | carrelage fissuré, néon qui grésille (halo `neon_cold` [D]), bancs |
| Céladopole | pavés, massifs, haies, Centre (façade réutilisée) | façades : grand magasin, Résidence + escalier de service, Casino (néons), façade de l'ancien Coin à lots, Arène + enclos, restaurant, hôtel, maison du chef ; fontaine, étang et quai, talus et haie de l'ouest |
| Intérieurs | coques Centre, Boutique, maison d'Argenta | coque du grand magasin (1 pour 5 étages, un accent de couleur par étage), toit-terrasse, distributeurs, comptoirs, tableau des étages, cabine d'ascenseur + panneau ; Résidence (hall, palier, toit, maison du toit) ; restaurant, hôtel ; serre (haies, bassin, verrière) ; Casino (machines, affiche, mur coulissant) |
| Repaire | — | sol béton, murs, caisses, conduites, consoles ; **flèche peinte** ×4 directions + **disque d'arrêt** ; escaliers, porte d'ascenseur, porte du bureau ; cabine du repaire |
| Personnages | `clerk`, `lass`, `lass_young`, `old_man`, `guard`, `nurse`, Sbires Rocket… (jamais deux fois le même modèle d'**habitant** sur une carte) | **Erika**, **Giovanni**, **Intello**, **Joueur**, **Beauté**, **Topdresseuse**, **Rocket en civil**, employé de bureau, jardinière, vieille dame, hôtesse, cuisinier, serveur, réceptionniste, touriste ; Tartard (décor, facultatif) |
| Pokémon | artworks officiels (faces) | **dos** des espèces capturables : Caninos, Arcanin, Goupix, Feunard, Évoli, Aquali, Voltali, Pyroli, Empiflor, Rafflesia, **Fantominus, Spectrum, Osselait** ; planche de compagnon d'**Évoli** (si budget) ; Pokémon d'ambiance de la vieille dame (Miaouss, Mélofée : planches existantes ?) |
| Combat | — | fonds CB.3 **`urban_route`**, **`greenhouse`**, **`hideout`** |
| Sac | — | icônes : Super Ball, Rappel, Poupée Poké, 4 pierres, 3 boissons, 6 objets X, Clé Ascenseur, Scope Sylphe |

**T2 + T3 (lot 20.0a, 2026-10-15)** : série **22**, fiche `docs/design/fiches-assets/serie-22-celadopole.md`,
outil `tools/art/serie22.py` ; périmètre espèces, personnages, fonds de combat (le reste du kit : série 22 bis).
Produits, à valider par Kevin : 9 dos peints provisoires (Évoli, Caninos, Goupix, Empiflor, Rafflesia, Osselait,
Arcanin, Feunard, Aquali ; Voltali et Pyroli refusés par Codex), Erika, Giovanni, Rocket en civil, Intello, Beauté,
Topdresseuse (marche + attente), décors `route_7_8_urbaine`, `celadon_gym_serre`, `rocket_hideout_repaire`.

---

## 2. Conception technique

### 2.1 Cartes, raccords, lumière (T15, T16, T20)

| Carte | Taille | Catégorie | Lumière | Outil |
|---|---|---|---|---|
| `route_8` | 80 × 26 | extérieur | `golden_hour` | `tools/build_route_8.gd` (nouveau, kit `pewter_map_kit.gd`) |
| `route_8_gate`, `route_7_gate` | 12 × 10 | intérieur | `interior_warm` | `build_painted_interiors.gd` : `_gate_room` (J15) |
| `route_8_underground_gate`, `route_7_underground_gate` | 12 × 10 | intérieur | `interior_warm` | idem |
| `underground_path_7_8` | 48 × 10 | ni grotte ni intérieur (J15) | `underground` (J15) | `tools/build_underground_path_7_8.gd` (nouveau, modèle `build_underground_path.gd`) |
| `route_7` | 28 × 24 | extérieur | `golden_hour` | `tools/build_route_7.gd` (nouveau) |
| `celadon_city` | 70 × 46 | extérieur | `golden_hour` | `tools/build_celadon_city.gd` (nouveau, modèle `build_cerulean_city.gd`) |
| `celadon_center` | Centre existant | intérieur | `interior_warm` | `_pokemon_center` ; point de repos |
| `celadon_dept_gf…5f` | 20 × 13 | intérieur | `interior_warm` | `build_painted_interiors.gd` : `_dept_floor(id, …)` (nouveau) |
| `celadon_dept_roof` | 20 × 11 | **intérieur** (toit sans compagnon [D]) | `golden_hour` | idem |
| `celadon_dept_elevator` | 6 × 6 | intérieur | `interior_warm` | idem |
| `celadon_mansion_gf…3f` | 16 × 11 | intérieur | `interior_warm` | `_mansion_floor(…)` |
| `celadon_mansion_roof` | 16 × 10 | intérieur [D] | `golden_hour` | idem |
| `celadon_mansion_roof_house` | 10 × 8 | intérieur | `interior_warm` | idem |
| `celadon_restaurant`, `celadon_chief_house`, `celadon_hotel` | 15 × 10 | intérieur | `interior_warm` | `_pewter_house` varié |
| `celadon_gym` | 17 × 16 | intérieur | **`greenhouse`** (nouveau [D] : vert filtré, sans ombre portée) | `tools/build_celadon_gym.gd` (nouveau) |
| `celadon_game_corner` | 20 × 18 | intérieur | `interior_warm` + halos **`neon`** (nouveau type en fin de `light_glows.json` [D], magenta et or, coupés par « Réduire les animations ») | `tools/build_game_corner.gd` (nouveau) |
| `rocket_hideout_b1f…b3f` | 30 × 28 | **grotte** (`caves.json`, `interior = false`) | **`hideout`** (nouveau [D] : blanc dur, aucune obscurité punitive) | `tools/build_rocket_hideout.gd` (nouveau, kit `cave_map_kit.gd`) |
| `rocket_hideout_b4f` | 30 × 24 | idem | idem | idem |
| `rocket_hideout_elevator` | 6 × 8 | grotte (même entrée `caves.json`) | `hideout` | idem |

**32 cartes** (dossier §2). Raccords :

- **Lavanville ↔ Route 8** : Route 8 (79, 10..12) `PUSH →` → `lavender_town` / `from_route_8_n|c|s`
  (noms à confirmer sur le code du J18 au T9) ; arrivées `from_lavender_n|c|s` (79, 10..12)
  tournées ←. Côté Lavanville (T15) : retirer le `coming_soon = "Route 8"` de
  `tools/build_lavender_town.gd` et cibler `route_8` / `from_lavender_n|c|s`, carte régénérée.
  **Tant que `lavender_town` n'existe pas**, le bord est de la Route 8 est un `coming_soon =
  "Lavanville"` (retour sur la case).
- **Route 7 ↔ Céladopole** : Route 7 (0, 10..12) `PUSH ←` → `celadon_city` / `from_route_7_n|c|s`
  (69, 21..23) ; Céladopole (69, 21..23) `PUSH →` → `route_7` / `from_celadon_n|c|s` (0, 10..12).
- **Souterrain** : bâtiment de la Route 7, escalier (5..6, 2) → `underground_path_7_8` /
  `from_route_7_n|s` ; escalier ouest du souterrain (2, 5..6) → `route_7_underground_gate` /
  `from_underground` ; idem à l'est avec la Route 8.
- **Casino ↔ ville** : (15..16, 17) `PUSH ↓` → `celadon_city` / `from_casino_w|e` (39..40, 33).
- **Casino ↔ B1F** : escalier (17, 4) ↔ B1F (21, 2), sous un **mur coulissant** (§2.6).
- **Repaire** : tous les escaliers et portes d'ascenseur sont déclarés des deux côtés (grilles).
- **Préchargement** : `route_8` ↔ `lavender_town` ; `route_7` ↔ `celadon_city` ; les intérieurs ne
  sont pas préchargés depuis l'extérieur (J10). Mémoire « carte + voisines » mesurée (§2.15).

### 2.2 Intérieurs (T16, T20)

- `build_painted_interiors.gd` : groupe `const CELADON := [...]`, option `--celadon`, définitions
  **en fin de fichier** ; `_init` appelle `_celadon_rooms()` (une ligne). Postes et bâtiments
  d'entrée : `_gate_room` du J15, **inchangée**.
- **Grand magasin** : une coque pour les cinq étages (accent de couleur par étage), escaliers à
  l'ouest (`S` montant (2..3, 2), `Z` descendant (4..5, 2)), porte d'ascenseur à l'est (16..17, 2),
  arrivées `from_up`, `from_down`, `from_elevator`. Tableau des étages au RdC (T-22, EXAMINER).
- **Résidence** : hall, paliers ; le 3e a la porte « BUREAU PRIVÉ » (examen T-27, aucun warp) ; le
  toit n'est relié qu'à l'**escalier de service** de la ville (grille) ; maison du toit avec la
  Poké Ball d'Évoli.
- **Casino** : 56 machines en décor, examinables depuis les allées (un `InteractPoint` par case
  d'allée face à une machine, dialogue `game_corner_machine`, T-39) ; affiche (9, 4) ; escalier
  (17, 4) caché par le mur coulissant.

### 2.3 Ascenseur (T5 logique, T13 moteur, T14 écran)

#### 2.3.1 Données — `data/world/elevators.json` (nouveau)

```json
{
	"_doc": "Ascenseurs (jalon 20, dossier 23 §9, §13.4). « car » : carte de la cabine. « key » : objet exigé (\"\" = aucun). « floors » : étages proposés au panneau, dans l'ordre affiché ; « map » / « spawn » : où mène la sortie de la cabine.",
	"elevators": {
		"celadon_dept": {
			"car": "celadon_dept_elevator", "key": "",
			"floors": [
				{ "id": "gf", "label": "RdC", "map": "celadon_dept_gf", "spawn": "from_elevator" },
				{ "id": "2f", "label": "2e", "map": "celadon_dept_2f", "spawn": "from_elevator" },
				{ "id": "3f", "label": "3e", "map": "celadon_dept_3f", "spawn": "from_elevator" },
				{ "id": "4f", "label": "4e", "map": "celadon_dept_4f", "spawn": "from_elevator" },
				{ "id": "5f", "label": "5e", "map": "celadon_dept_5f", "spawn": "from_elevator" }
			]
		},
		"rocket_hideout": {
			"car": "rocket_hideout_elevator", "key": "lift_key",
			"floors": [
				{ "id": "b1f", "label": "B1F", "map": "rocket_hideout_b1f", "spawn": "from_elevator" },
				{ "id": "b2f", "label": "B2F", "map": "rocket_hideout_b2f", "spawn": "from_elevator" },
				{ "id": "b4f", "label": "B4F", "map": "rocket_hideout_b4f", "spawn": "from_elevator" }
			]
		}
	}
}
```

#### 2.3.2 Classes pures (`game/world/elevator/`, T5)

| Fichier | Classe | Rôle |
|---|---|---|
| `elevator_data.gd` | `ElevatorData` (`RefCounted`) | `id`, `car`, `key`, `floors: Array[Dictionary]` ; `floor(id)`, `floor_for_map(map_id)`, `default_floor()` (le premier) |
| `elevator_library.gd` | `ElevatorLibrary` (`RefCounted`) | lit le fichier ; clés strictes ; refuse : cabine en double, étage en double, liste vide ; `for_car(map_id) -> ElevatorData` (null hors cabine) |
| `elevator_rules.gd` | `ElevatorRules` (`RefCounted`, statique) | `can_operate(elevator, bag) -> bool` (pas de clé, ou clé dans le Sac) ; `choose(elevator, current_id, wanted_id, bag) -> Status { OK, NO_KEY, UNKNOWN_FLOOR, SAME_FLOOR }` ; `exit_target(elevator, floor_id) -> Dictionary {map, spawn}` ; `entry_floor(elevator, arrived_from: StringName) -> StringName` (étage dont la carte est celle d'où l'on vient, sinon `default_floor`) |

Tests `test_elevator_library`, `test_elevator_rules` : étages du magasin RdC → 5e **sans le toit** ;
repaire **B1F, B2F, B4F seulement** ; refus `NO_KEY` sans `lift_key`, `OK` avec ; `SAME_FLOOR` ;
entrée depuis une carte inconnue → premier étage ; fichier réel : chaque `map` et chaque `spawn`
existent (sauté pour les cartes pas encore construites, comme `test_map_links`), la clé est un
objet `key` connu.

#### 2.3.3 Directeur (`ElevatorDirector`, `Node`, enfant de Boot, T13)

- **Entrée dans la cabine** (`SceneRouter.map_entered`) : `ElevatorLibrary.for_car(map.map_id)` ;
  l'étage courant = `ElevatorRules.entry_floor(elevator, arrival_from)` (Boot connaît déjà la carte
  quittée, `_arrival_from`) ; la sortie de la cabine est **réorientée** : chaque `Warp` de sortie
  de la cabine (`WarpTable` de la carte) reçoit `target_map` / `target_spawn` de l'étage courant.
  Dans la scène, ces warps visent par défaut le **premier étage** (cohérence de `test_map_links`).
- **Panneau** : `InteractPoint` EXAMINER → dialogue `<car>_panel` (variante sans page, `action:
  open_elevator`, nouvelle action de `DialogueLibrary.ACTIONS`) ; à la fin du dialogue (modèle
  `_pending_shop`), Boot appelle `ElevatorDirector.open_panel()` :
  - sans la Clé : dialogue `rocket_hideout_elevator_locked` (T-50), fin ;
  - sinon : `ElevatorPanel` (T14) liste les étages ; l'étage courant est grisé ; FERMER ou retour
    Android = rien ne change ;
  - choix : verrou (raison `elevator`), compagnon rétracté (`on_cutscene_started`), **fondu 0,4 s**
    + **légère secousse** (décalage de la caméra du joueur, 0,25 s, ±6 px [D], coupée par
    « Réduire les animations » ; vibration légère si permise) ; étage courant changé ; sortie
    réorientée ; verrou levé ; signal `ride_finished(floor_id)`.
- Le joueur **sort à pied** (RB) : le passage normal (fondu, `map_entered`) mène à l'arrivée
  `from_elevator` de l'étage.
- **Retour Android** pendant le trajet : avalé (Boot route vers `ElevatorDirector.handle_back()`).

#### 2.3.4 Écran (`ElevatorPanel`, T14, ui-mobile)

`game/ui/elevator/elevator_panel.gd` (`CanvasLayer`) : voile, titre (texte d'interface, annexe A),
une carte par étage (libellé de la donnée), étage courant grisé, bouton FERMER ; jetons
`ui_tokens.gd` (fin de fichier), cibles ≥ 96 px ; signaux `floor_chosen(id)`, `closed`. Captures
2340 × 1080 relues (magasin, repaire avec la Clé).

#### 2.3.5 Sauvegarde

Aucune donnée persistée. **La cabine n'est jamais une position sauvée** : Boot demande la position
à `ElevatorDirector.stable_location(map_id, cell, facing)` dans `_write_save` et `_on_menu_opened` ;
dans une cabine, elle rend la carte, la case d'arrivée `from_elevator` et l'orientation de l'étage
courant ; ailleurs, la position donnée. Test : sauvegarde écrite dans la cabine au 4e → rechargée
au 4e devant la porte ; partie tuée pendant le fondu → dernière sauvegarde stable (aucune écriture
pendant le verrou, `is_stable()` faux).

### 2.4 Dalles tournantes (T4 logique, T19 moteur, T20 cartes)

#### 2.4.1 Règle (dossier §13.3, grilles, vérifiée contre RB par `plan_check_repaire.py`)

Posé sur une flèche, le joueur glisse **case par case dans sa direction** ; chaque flèche rencontrée
change la direction ; la glisse s'arrête sur la **première case d'arrêt** (`o`). Déterministe : même
dalle, même trajet. 43 dalles au B2F, 16 au B3F (59 trajets RB).

#### 2.4.2 Données dans la carte

L'outil `build_rocket_hideout.gd` lit les caractères `< > ^ v` et `o` de la grille et pose un nœud
**`SpinTiles`** (`SpinTileField`, `Node2D`, `game/world/spin/spin_tile_field.gd`, groupe
`spin_tile_field`) : `@export var arrows: Dictionary[Vector2i, Vector2i]`, `@export var stops:
Array[Vector2i]`. Les flèches et les disques sont **peints** (décalcomanies du kit), pas des nœuds
par case. Les cases de flèche et d'arrêt sont du sol praticable dans `Ground`.

**Interface fixée au T19 pour T20 / T21** (modèle : `_build_spin_room()` de
`tools/build_qa_j20.gd`, carte `qa_spin_j20`) :
- nœud `Node2D` nommé **`SpinTiles`**, **enfant direct de la racine** de la carte, script
  `res://game/world/spin/spin_tile_field.gd` (le directeur le cherche par ce nom, puis par le
  groupe) ; `arrows` = case → vecteur unitaire (`Vector2i.RIGHT` pour `>`, etc. :
  `SpinTileRules.direction_of_char`), `stops` = cases `o`. Dans l'outil, construire des variables
  **typées** (`var arrows: Dictionary[Vector2i, Vector2i]`, `var stops: Array[Vector2i]`) puis
  `field.set(&"arrows", arrows)` : la scène les écrit typés.
- « Praticable » pour la glisse = dans la carte, ni `solid` ni `water` (grille de la carte ; les
  occupants ne comptent pas). En build debug, chaque entrée sur la carte lance
  `SpinTileField.check()` et fait un `push_error` par dalle fautive : un test qui charge la carte
  échoue si les données sont fausses. Test T20 conseillé : `field.check(walkable).is_empty()` avec
  la même règle.
- **Rien sur une dalle ni sur un trajet** : ni PNJ (Dresseurs compris : un pas refusé arrête la
  glisse sur place, `push_error`), ni objet au sol, ni `WarpPoint`, `EventTriggerPoint` ou point
  d'apparition (un joueur posé sur une dalle est reposé sur sa case d'arrêt). Une case d'arrêt peut
  porter un point d'apparition, pas une dalle.
- Les pas de la glisse ne sont vus par personne (ni passage, ni déclencheur, ni rencontre, ni
  compteur de la Pension) ; à l'arrêt, seuls les **Dresseurs** regardent la case d'arrêt
  (`TrainerWatcher.check_at`). Un Dresseur placé pour voir une case d'arrêt (T21) réagit comme
  après un pas normal ; un Dresseur dont la ligne coupe le **milieu** d'un trajet ne réagit pas.

#### 2.4.3 Logique pure (`game/world/spin/spin_tile_rules.gd`, T4)

| Élément | Rôle |
|---|---|
| `SpinTileRules.slide(start, arrows, stops, walkable: Callable, max_steps := 256) -> SpinSlide` | le trajet depuis la flèche `start` : `cells` (cases traversées, sans `start`), `facings` (direction de chaque pas), `end`, `status` |
| `SpinSlide.Status` | `OK`, `NOT_AN_ARROW`, `BLOCKED` (case suivante non praticable : erreur de données), `LOOP` (cycle), `TOO_LONG` |
| `SpinTileRules.check_field(arrows, stops, walkable) -> PackedStringArray` | une erreur par flèche qui ne finit pas sur un arrêt praticable |
| `SpinTileRules.safe_cell(cell, arrows, stops, walkable) -> Vector2i` | une case **stable** pour la reprise : la case elle-même si ce n'est pas une flèche, sinon la fin de sa glisse |

Tests `test_spin_tile_rules` : cas synthétiques (ligne droite, virage, chaîne de flèches, boucle,
mur, `max_steps`) ; **les grilles réelles** (`PlanGrid` sur `repaire_b2f.txt`, `repaire_b3f.txt`) :
chaque flèche → un arrêt praticable, sans boucle ni mur, et **trajet identique** à l'attribut
`trajet=` / `arret=` de la grille (RB) ; aucune flèche au B1F et au B4F.

#### 2.4.4 Directeur (`SpinTileDirector`, `Node`, enfant de Boot, T19)

- `map_entered` : trouve le `SpinTileField` de la carte (groupe), sinon se met en veille
  (`set_process(false)`, aucun coût hors repaire).
- `Player.moved(cell)` **avec l'entrée libre** et `cell` dans `arrows` → `slide` :
  1. verrou (raison `spin`) : `is_stable()` faux, donc **aucune autosave**, menu et retour Android
     ignorés (règles existantes de Boot) ;
  2. compagnon rétracté (`on_cutscene_started`) ; signal `slide_started` ;
  3. pour chaque pas : `player.face(dir)` puis `player.script_step(dir, run = true)` (vitesse de
     course), attendre la fin du pas ; un pas refusé (case occupée) arrête la glisse sur place et
     `push_error` (données garanties par les tests) ;
  4. fin : verrou levé, compagnon de retour, signal `slide_finished(cell)` ;
     **`TrainerWatcher.check_at(cell)`** (nouveau, public, même règle que `_on_player_moved`) pour
     qu'un Dresseur dont la ligne couvre la case d'arrêt réagisse comme après un pas normal.
- Les pas de la glisse sont « scriptés » : ni warp (`SceneRouter` les ignore), ni rencontre.
- Rotation : le joueur **pivote** dans le sens de chaque flèche (changement d'orientation), sans
  animation de toupie [D].
- **Reprise** : une sauvegarde est toujours écrite sur une case stable (verrou). Par sécurité, au
  chargement, si la case sauvée est une flèche, Boot place le joueur sur `safe_cell` (test).

### 2.5 Don de Pokémon (T6 logique, T12 moteur)

#### 2.5.1 Logique pure (`game/systems/gift/pokemon_gift.gd`, T6)

`PokemonGift` (`RefCounted`, statique) :
`give(state, data: PokemonData, species: StringName, level: int, map: StringName, flag: StringName)
-> GiftResult` ; `GiftResult.status = JOINED | STORED | ALREADY_RECEIVED | UNKNOWN_SPECIES`,
`pokemon`.

En **un seul bloc synchrone** (aucune attente au milieu, donc aucune sauvegarde ne peut couper
entre deux) :
1. refus si `flag` est déjà levé (`ALREADY_RECEIVED`) ou si l'espèce est inconnue ;
2. `PokemonFactory.create(data, species, level, rng)` (capacités du niveau, sexe tiré) ;
3. `party.add`, sinon `storage.add` (le Stockage du joueur attribue l'uid) ;
4. `record_caught(species, map)` (vu **et** capturé, daté) ;
5. `stamp_meeting(pokemon, Origin.GIFT, map)` ;
6. `flags.set_flag(flag)`.

`Pokemon.Origin.GIFT` est ajouté **en fin d'enum** (T12, fichier chaud), texte `"gift"` dans
`ORIGIN_NAMES`, libellé de la fiche « Reçu à » (`team_views.gd`, texte existant du starter).

Tests `test_pokemon_gift` (état de test, sans scène) : équipe de 5 → JOINED ; équipe de 6 →
STORED (uid attribué) ; second appel → ALREADY_RECEIVED, rien ne change ; Pokédex vu + capturé ;
niveau 25, capacités d'Évoli au N25 (Charge, Jet de Sable) ; origine `gift`, carte, dresseur.

#### 2.5.2 Étape de scène `gift_pokemon` (T12)

`CutsceneStep.Kind.GIFT_POKEMON` **en fin d'enum** :
`{ "gift_pokemon": "eevee", "level": 25, "flag": "eevee_received", "say": "<dialogue>",
"say_stored": "<dialogue>" }` (`level`, `flag`, `say` obligatoires ; `say_stored` facultatif).
Le `CutsceneDirector` appelle `PokemonGift.give` (avec `GameState`), joue `say` (T-29), puis
`say_stored` si STORED (T-30) ; ALREADY_RECEIVED : rien, l'étape passe. Signal
`pokemon_gifted(pokemon, stored)` → Boot : `request_autosave("don")`, `_companion.refresh()`, toasts
du Pokédex existants.

#### 2.5.3 Évoli (T17, données)

- PNJ `eevee_ball` (4, 3) de `celadon_mansion_roof_house` : `sprite: object/poke_ball_table`
  [D], `verb: examine`, `turn_to_player: false`, `unless: [eevee_received]`, dialogue
  `celadon_eevee_ball` : T-28 + choix (OUI / NON), `confirm_cutscene: celadon_eevee_gift`.
- Scène `celadon_eevee_gift` : `gift_pokemon` (eevee, 25, `eevee_received`, T-29, T-30) puis
  `despawn: eevee_ball`.
- **Pas de surnom** (§0.2 n° 7). **Pas de marqueur** (H-10).

### 2.6 Casino, affiche et interrupteur (T20, T21)

- **Machines** : décor, examen T-39. **Aucun jeton, aucune mise.**
- **Rocket de l'affiche** `celadon_game_corner_rocket` (9, 5), tourné ↑ vers l'affiche, `sight: 1`
  [D, la grille dit 0, minimum 1], bloc `trainer` : avant T-40, défaite T-41, **`leave`** vers
  l'allée ouest puis la porte (§0.2 n° 9).
- **Affiche** (9, 4), lue depuis (9, 5) (case libérée par le départ du Rocket) : dialogue
  `game_corner_poster` à variantes : `if [game_corner_switch]` → annexe A ; sinon T-42 + choix
  `confirm_cutscene: game_corner_switch`.
- **Scène `game_corner_switch`** : dialogue T-43, `set: [game_corner_switch]` → le **mur
  coulissant** (`FlagGate` `unless [game_corner_switch]`, `blocking_cells` (17, 4)) disparaît : Boot
  réapplique les portes de drapeaux à chaque drapeau changé (J14/J15) ; l'escalier (17, 4) devient
  praticable. Secousse légère [D] (même effet que l'ascenseur). Le passage reste ouvert.
- **Restaurant** : client n° 44 (T-44) ; aucune Boîte Jetons.

### 2.7 Repaire Rocket (T20, T21)

#### 2.7.1 Cartes

Grilles RB 1:1 (marges vides de RB conservées). Sol de béton sans rencontre. `caves.json` (fin) :

```json
"rocket_hideout": {
	"maps": ["rocket_hideout_b1f", "rocket_hideout_b2f", "rocket_hideout_b3f",
		"rocket_hideout_b4f", "rocket_hideout_elevator"],
	"escape": { "map": "celadon_city", "spawn": "from_casino_w", "facing": "down" }
}
```

(`_doc` du fichier complété : « grotte » = lieu souterrain où la Corde Sortie ramène dehors.)

#### 2.7.2 Clé Ascenseur

Sbire `rocket_hideout_b4f_key` (11, 2), `sight: 1`. Après sa défaite : réplique « défaite » T-47 ;
quand on lui **reparle** (dialogue « après » à variantes) : `unless [rocket_dropped_lift_key]` →
T-48 + `set [rocket_dropped_lift_key]` + **scène** `rocket_hideout_key_drop` qui fait apparaître
(`spawn`) la Poké Ball en (10, 2) ; ensuite : réplique de l'annexe A. La Poké Ball est aussi dans le
roster (`if [rocket_dropped_lift_key]`, `unless [got_rocket_hideout_b4f_lift_key]`, `verb: take`)
pour les visites suivantes. Prise : T-49 en page puis toast « obtenue » (objet clé `lift_key`).

#### 2.7.3 Porte du bureau

`FlagGate` sur (24..25, 11), `unless [rocket_hideout_b4f_door_open]`, `blocking_cells` (24..25,
11). Les deux gardes (`sight: 1` [D]) ont chacun une réplique « défaite » à deux variantes :
`if [beaten_rocket_hideout_b4f_guard_1, beaten_rocket_hideout_b4f_guard_2]` → page +
`set [rocket_hideout_b4f_door_open]` ; sinon la page seule. Examen de la porte fermée : annexe A.

#### 2.7.4 Giovanni

- Bloc `trainer` `giovanni_hideout` (25, 3) tourné ↓, `sight: 1`, dialogue de scène (modèle
  `cerulean_gym_misty`) : `face` → T-52 (`unless giovanni_met`) / reprise annexe A (`if
  giovanni_met`) → `champion_card` (`unless giovanni_met`, carte : annexe A) → `set giovanni_met` →
  `battle` (`win: [giovanni_hideout_won]`) → victoire : T-54 → `wait` 0,4 → **`despawn: giovanni`**
  (fondu) → `spawn` de la Poké Ball du Scope en (25, 2) → `moment: giovanni` ; défaite : réplique
  (annexe A) → `wake_up`.
- `end_message` : T-53. IA `smart`, `switch: true`, `can_lose: false`.
- Roster : Giovanni `unless [giovanni_hideout_won]` ; Poké Ball du Scope `if [giovanni_hideout_won]`
  `unless [got_rocket_hideout_b4f_silph_scope]`, `verb: take`, dialogue T-55 puis toast.
- **Défaite du joueur** : dernier point de repos (§0.2 n° 12) ; Rocket battus gardés ; Clé gardée ;
  retour direct possible par l'ascenseur.
- **Cas limite** (dossier §19) : application coupée entre la victoire et le ramassage → au
  rechargement, Giovanni absent, Poké Ball au sol (roster).

#### 2.7.5 Scope Sylphe et la Tour

- `silph_scope` : catégorie `key`, `obtained: true` [D, toast « obtenu »], sans `field_use`,
  jamais consommé. Description : T-55 (2e ligne) [D].
- **Rien d'autre** : la Tour lit le Sac (J19). Aucune donnée du J20 ne pose `fuji_*`, `marowak_*`,
  `poke_flute*` (test `test_j20_no_j21_flags` sur `data/cutscenes`, `data/dialogues`, `data/npcs`).
- Build J20 sans J21 : rencontres de la Tour identifiées avec le Scope ; 6F reste un SPECTRE
  (`ghost: always`, donnée du J19) ; test `test_tower_scope_j20` **sauté** sans les cartes du J19.

### 2.8 Arène d'Erika (T16, T17)

- **Arbuste de l'enclos** (19, 37) de `celadon_city` et **arbuste intérieur** (8, 10) de
  `celadon_gym` : mécanisme du J16 (PNJ `object/cut_tree`, `unless [cut_<id>]`, dialogue
  `cut_tree`, scène `cut_tree_<id>`), identifiants `celadon_gym_bush`, `celadon_gym_inner_bush`
  [D]. Sans Coupe : message de l'arbuste (J16) ; la ville reste entièrement ouverte (test).
- **Dresseuses** E1–E5 (§2.10.6) ; E5 **inévitable** (sa ligne couvre l'accès à la porte-haie
  (8, 4)) ; Erika atteignable par le tour sans couper l'arbuste intérieur (test sur la vraie scène).
- **Erika** (8, 2), tournée ↓ : scène `celadon_gym_erika` (modèle `cerulean_gym_misty`) :
  T-34 (`unless erika_met`) / reprise (annexe A) → carte (annexe A) → `battle` (`win:
  [badge_rainbow]`) → T-35 en `end_message` → `badge: rainbow` (T-36, vibration, Grand moment
  « badge » existant) → T-37 + `give: tm21` + `set [tm21_received]` ; défaite : annexe A →
  `wake_up` (Dresseuses battues gardées). Après : T-38. Variante de rattrapage de la CT comme
  `cerulean_gym_misty_tm_late`.
- « Elle somnole » : seulement le texte T-34 [D] (aucune émotion « zzz » : `EMOTE_KINDS` n'a que
  l'exclamation).
- **Badge sans effet** (dossier 23 §11.4).

### 2.9 Boutiques et objets nouveaux dans le moteur (T11, T14)

#### 2.9.1 Une boutique par vendeur

`DialogueVariant` : clé facultative **`shop`** (identifiant de `data/shops/`), permise seulement
avec `action: open_shop`. `ServiceDirector` émet `shop_requested(variant.shop)` si elle est
renseignée, sinon l'identifiant de la carte (comportement actuel). Tests `test_dialogue_library`
(clé refusée sans `open_shop`), `test_service_director`.

| Vendeur | Boutique | Stock (ordre d'affichage) |
|---|---|---|
| 2e, vendeur 1 | `celadon_dept_2f` | Super Ball, Super Potion, Rappel, Antidote, Anti-Brûle, Antigel, Réveil, Anti-Para (RB ; Super Repousse quand la Repousse existera) |
| 2e, vendeur 2 | `celadon_dept_2f_tm` | **CT01** Ultimapoing (selon Q-2) |
| 4e, vendeur 1 | `celadon_dept_4f` | Poupée Poké |
| 4e, vendeur 2 | `celadon_dept_4f_stones` | Pierre Feu, Pierre Eau, Pierre Foudre, Pierre Plante |
| 5e | `celadon_dept_5f` | Attaque +, Défense +, Vitesse +, Spécial +, Précision +, Muscle + |
| Toit | `celadon_dept_roof_water`, `_soda`, `_lemonade` | une boisson chacun (distributeur EXAMINER, T annexe A, action `open_shop` + `shop`) |

Le 5e a donc son vendeur (la condition `stat_stages` de la grille est remplie, H-8). **Aucune
vitamine.**

#### 2.9.2 CT achetable une fois

`ItemLibrary` accepte un `price` sur une CT. `ShopRules.max_buy` : objet **permanent** → 1 s'il n'est
pas dans le Sac, 0 sinon ; `buy` refuse une quantité > 1. `ShopViews` : ligne « déjà dans le Sac »
(texte d'interface, annexe A) au lieu du prix. `is_sellable` reste faux (une CT ne se revend pas).
Tests `test_shop_rules`, `test_shop_views`.

#### 2.9.3 Objets de combat : Poupée Poké, objets X

- `ItemData` : clé **`battle_use`** (catégorie `battle` seulement) :
  `{ "kind": "stat_stage", "stat": "atk", "stages": 1 }`, `{ "kind": "crit_up" }`,
  `{ "kind": "escape" }`. Contextes : `escape` → combat **sauvage** seulement (« Impossible contre
  un Dresseur », refus existant `WRONG_CONTEXT`) ; les autres → les deux combats.
- `BattleAction.use_item(id)` (nouveau, comme `ball`) : joué avant les capacités ; le
  `BattleDirector` retire l'objet une fois, avant de soumettre l'action (règle de la Ball).
  `Battle` : `stat_stage` → logique d'étage existante sur le Pokémon actif du joueur (messages
  « augmente » existants, « ne peut plus monter » si +6) ; `crit_up` → l'état de Puissance
  (`focus_energy`) ; `escape` → fuite **garantie** (issue `FLED`), message propre (annexe A).
  `BattleEvent.Kind` : `ITEM_ESCAPE` **en fin d'enum**.
- Valeurs [D] : **+1 étage** (RB ; les jeux récents donnent +2) ; « Spécial + » → Attaque Spéciale
  +1 ; Défense Spéc. (Brume) non vendue (effet absent).
- L'IA adverse n'utilise aucun objet. Tests `test_battle_items` (étages, plafond, Muscle +, Poupée
  sauvage = fuite sans tour adverse, refus contre un Dresseur, objet retiré une seule fois).

#### 2.9.4 Rappel

`ItemData` : clé **`revive`** (fraction de PV, `0.5`) sur un objet `heal` ; `ItemUse` : un objet
`revive` ne se donne **qu'à un Pokémon K.O.** (sinon `NO_EFFECT`) ; il rend
`max(1, floori(max_hp × 0,5))` PV et retire le statut K.O. En combat (RB) : sur un Pokémon K.O. de
l'équipe, **pas l'actif** (qui n'est jamais K.O. au moment de choisir) ; l'écran d'équipe du combat
autorise les K.O. pour cet objet ; `BattleEvent.Kind.REVIVED` en fin d'enum (message, annexe A).
Tests `test_item_use` (revive), `test_battle_revive`.

#### 2.9.5 Pierres, boissons

Données seulement : pierres `field_use: evolution_stone` (`StoneUse` existant) ; boissons `heal`
50 / 60 / 80 PV. Évolution par pierre **non annulable** (règle du J12).

#### 2.9.6 Condition d'objet dans un dialogue (la fillette du toit)

`DialogueVariant` : clés **`if_items`** / **`unless_items`** (identifiants d'objets ; vraies si tous
/ aucun sont dans le Sac). `Dialogue.pick` reçoit le Sac (Boot le passe au runner). Si les variantes
`field` du J16 savent déjà lire le Sac, T9 les **généralise** au lieu d'ajouter une clé (le plus
petit des deux).

Fillette (17, 5), dialogue `celadon_roof_girl` :
1. `if [rooftop_tm13]` → annexe A (après) ;
2. `if_items [fresh_water]` → T-24 + choix (annexe A : « Lui donner une Eau Fraîche ? »),
   `confirm_cutscene: celadon_roof_trade`, refus : annexe A ;
3. `if_items` Soda Cool ou Limonade seulement → annexe A (« trop sucré ») ;
4. sinon → T-24.

Scène `celadon_roof_trade` : `take: fresh_water` → T-25 → `give: tm13` → `set [rooftop_tm13]`. CT48
et CT49 : capacités absentes → la fillette ne les donne pas (H-7).

### 2.10 Données (T7, fichiers nouveaux)

#### 2.10.1 Espèces (`data/pokemon/species/kanto_celadon.json` [D])

Types et statistiques **actuels**, apprentissages **RB**, valeurs revérifiées sur PokeAPI à
l'écriture (méthode J12/J15) ; évolutions par pierre (`"method": "item"`).

| Espèce | N° | Types | Rôle | Créée par | Si absente au T9 |
|---|---|---|---|---|---|
| `growlithe` Caninos | 58 | Feu | sauvage, D6 | **J17 ou J19** (adversaire) | J20 la crée ; sinon **ajoute** l'évolution et le dos |
| `arcanine` Arcanin | 59 | Feu | Pierre Feu | J20 | — |
| `vulpix` Goupix | 37 | Feu | sauvage, D6 | **J17** (adversaire) | idem Caninos |
| `ninetales` Feunard | 38 | Feu | Pierre Feu | J20 | — |
| `eevee` Évoli | 133 | Normal | don | J20 | — |
| `vaporeon` Aquali | 134 | Eau | Pierre Eau | J20 | — |
| `jolteon` Voltali | 135 | Électrik | Pierre Foudre | J20 | — |
| `flareon` Pyroli | 136 | Feu | Pierre Feu | J20 | — |
| `victreebel` Empiflor | 71 | Plante / Poison | Erika ; Pierre Plante | J20 | — |
| `tangela` Saquedeneu | 114 | Plante | Erika | J20 | — |
| `vileplume` Rafflesia | 45 | Plante / Poison | Erika ; Pierre Plante | J20 | — |
| `rhyhorn` Rhinocorne | 111 | Sol / Roche | Giovanni | J20 | — |
| `kangaskhan` Kangourex | 115 | Normal | Giovanni | J20 | — |
| `gastly`, `haunter`, `cubone` | 92, 93, 104 | — | Tour (capturables dès le Scope) | **J19** | **dos** et art définitif par le J20 ; Pokédex d'Osselait par le J20 (J19 §2.12) |
| `drowzee` Soporifik, `magnemite` Magnéti | 96, 81 | — | Dresseurs | **J17** | remplacés (§2.10.6) |

Règles d'évolution ajoutées : `growlithe → arcanine` (`fire_stone`), `vulpix → ninetales`
(`fire_stone`), `eevee → vaporeon / jolteon / flareon` (`water_stone` / `thunder_stone` /
`fire_stone`), `gloom → vileplume` (`leaf_stone`), `weepinbell → victreebel` (`leaf_stone`) et
**`staryu → starmie` (`water_stone`)**, oubliée jusqu'ici (Staross existe, la règle manque).
Recensement des autres lignées : `pikachu → raichu` (`thunder_stone`, déjà là) ; Kokiyas, Noeunoeuf,
Têtarte : évolution vers une espèce absente → aucune règle (règle existante). Modifier les fichiers
d'un autre jalon (Caninos, Goupix, Staross) se fait au T9, une ligne par règle.

Apprentissages RB (pour mémoire, revérifiés au T7) : Caninos `[1 bite][1 roar][18 ember][23 leer]
[30 take_down][39 agility][50 flamethrower]` ; Arcanin `[1 roar][1 ember][1 leer][1 take_down]` ;
Goupix `[1 ember][1 tail_whip][16 quick_attack][21 roar][28 confuse_ray][35 flamethrower]
[42 fire_spin]` ; Feunard `[1 ember][1 tail_whip][1 quick_attack][1 roar]` ; Évoli `[1 tackle]
[1 sand_attack][27 quick_attack][31 tail_whip][37 bite][45 take_down]` ; Aquali, Voltali, Pyroli :
RB (dont `acid_armor`, `mist`) ; Rafflesia `[1 stun_spore][1 sleep_powder][1 acid][1 petal_dance]
[15 poison_powder][17 stun_spore][19 sleep_powder]` ; Empiflor `[1 sleep_powder][1 stun_spore]
[1 acid][1 razor_leaf][13 wrap][15 poison_powder][18 sleep_powder]` ; Saquedeneu `[1 constrict]
[1 bind][29 absorb][32 poison_powder][36 stun_spore][39 sleep_powder][45 slam][49 growth]` ;
Rhinocorne `[1 horn_attack][30 stomp][35 tail_whip][40 fury_attack][45 horn_drill][50 leer]
[55 take_down]` ; Kangourex `[1 comet_punch][1 rage][26 bite][31 tail_whip][36 mega_punch]
[41 leer][46 dizzy_punch]`.

Pokédex (`data/pokedex/kanto.json`, fin) : taille, poids (valeurs officielles), description
(annexe A, A.12), pour les 13 espèces et Osselait, **sauf** celles déjà décrites par un jalon
fusionné (T9 retire les doublons).

#### 2.10.2 Capacités (`data/pokemon/moves/celadon.json` [D])

| Capacité | Nom | Valeurs (actuelles) | Effet | Qui |
|---|---|---|---|---|
| `mega_drain` | Méga-Sangsue | Plante, spéciale, 40, 100 %, 15 PP | `drain` 0,5 (joué) | CT21, Rafflesia d'Erika |
| `constrict` | Constriction | Normal, physique, 10, 100 %, 35 PP | Vitesse −1, 10 % (joué) | Saquedeneu |
| `comet_punch` | Poing Comète | Normal, physique, 18, 85 %, 15 PP | 2 à 5 coups (joué) | Kangourex |
| `stomp` | Écrasement | Normal, physique, 65, 100 %, 20 PP | peur 30 % (joué) | Rhinocorne N30 |
| `dizzy_punch` | Uppercut | Normal, physique, 70, 100 %, 10 PP | confusion 20 % (joué) | Kangourex N46 |
| `acid_armor` | Acidarmure | Poison, statut, 20 PP | Défense +2 (joué) | Aquali N42 |
| `take_down` | Bélier | Normal, physique, 90, 85 %, 20 PP | `pending_effects: ["recoil_damage"]` | Caninos, Arcanin, Évoli, Rhinocorne |
| `mist` | Brume | Glace, statut, 30 PP | `pending_effects: ["mist"]` | Aquali N48 |
| `roar` | Hurlement | Normal, statut, 20 PP | `pending_effects: ["force_switch"]` | **J17** ; créée ici si absente |

Descriptions : annexe A (A.13). Une capacité « Sans effet dans le moteur actuel » le dit dans sa
description (règle J12). **Dresseurs** : jamais de capacité en attente dans une équipe imposée
(Bélier, Hurlement → la plus proche jouée, choix manuel dans la fiche, règle J12).

#### 2.10.3 CT retenues (règle H-7, §0.2 n° 2)

Vérification capacité par capacité sur `main` (+ J16–J19 d'après leurs plans) :

| CT RB du J20 | Capacité | Sur `main` | Retenue |
|---|---|---|---|
| CT01 (2e) | Ultimapoing `mega_punch` | jouée | **oui** (objet `tm01` existant, prix 3 000 ₽ RB) |
| CT02 (2e ; B4F) | Coupe-Vent `razor_wind` | absente | non → B4F : Super Potion |
| CT05 (2e) | Ultimawashi `mega_kick` | absente | non |
| CT07 (2e ; B2F) | Empal'Korne `horn_drill` | **sans effet** (`ohko`) | non → B2F : Super Potion |
| CT09 (2e) | Bélier `take_down` | créée en attente (§2.10.2) | non |
| CT10 (B3F) | Damoclès `double_edge` | **sans effet** (`recoil_damage`) | non → B3F : Super Potion |
| CT13 (toit) | Laser Glace `ice_beam` | jouée | **oui** (`tm13`, échange de l'Eau Fraîche) |
| CT17 (2e) | Sacrifice `submission` | **sans effet** | non |
| CT18 (3e) | Riposte `counter` | absente | non (l'homme ne donne rien, T-23) |
| CT21 (Erika) | Méga-Sangsue `mega_drain` | **créée** (jouée) | **oui** (`tm21`) |
| CT32 (2e) | Reflet `double_team` | absente | non |
| CT33 (2e) | Protection `reflect` | **sans effet** | non |
| CT37 (2e) | Bombe-Œuf `egg_bomb` | absente | non |
| CT48 / CT49 (toit) | Éboulement / Triplattaque | absentes | non |

**CT retenues : CT01 Ultimapoing, CT13 Laser Glace, CT21 Méga-Sangsue.** T9 refait le tableau sur
le code fusionné (un jalon a pu jouer `recoil_damage` ou les écrans). Compatibilités :
`tools/gen_tm_compatibility.py` relancé (fichier généré, jamais fusionné à la main) ; il couvre
déjà toutes les CT RB par numéro.

#### 2.10.4 Objets (`data/items/celadon.json` [D] ; `items_j20.json` au T7, §2.10.7)

| Id | Nom / pluriel | Catégorie | Valeurs | Prix |
|---|---|---|---|---|
| `great_ball` | Super Ball / Super Balls | ball | `catch_bonus` 1,5 | 600 |
| `revive` | Rappel / Rappels | heal | `revive` 0,5 | 1 500 |
| `poke_doll` | Poupée Poké / Poupées Poké | battle | `battle_use` escape | 1 000 |
| `fire_stone`, `water_stone`, `thunder_stone`, `leaf_stone` | Pierre Feu / Eau / Foudre / Plante | field | `evolution_stone` | 2 100 |
| `fresh_water`, `soda_pop`, `lemonade` | Eau Fraîche, Soda Cool, Limonade | heal | 50 / 60 / 80 PV | 200 / 300 / 350 |
| `x_attack`, `x_defend`, `x_speed`, `x_special`, `x_accuracy`, `dire_hit` | Attaque +, Défense +, Vitesse +, Spécial +, Précision +, Muscle + | battle | `battle_use` (§2.9.3) | 500, 550, 350, 350, 950, 650 |
| `tm13` | CT13 — Laser Glace | tm | `teaches: ice_beam` | — |
| `tm21` | CT21 — Méga-Sangsue | tm | `teaches: mega_drain` | — |
| `lift_key` | Clé Ascenseur | key | `obtained` faux | — |
| `silph_scope` | Scope Sylphe | key | `obtained: true` | — |
| `tm01` (existant) | — | — | **prix 3 000** ajouté | 3 000 |

Remplacements §21 (objets RB absents) : Hyper Potion, Huile, Fer → **Super Potion** ; PP Plus, PV
Plus → **Rappel** ; CT au sol non retenues → **Super Potion**. Descriptions : annexe A (A.11).
`super_potion` existe (J15) ; le doublon du J16 est réglé par le J16.

#### 2.10.5 Rencontres (`data/encounters/route_7.json`, `route_8.json`)

Union Rouge + Bleu, niveaux RB, rééquilibrée comme la Route 3 ; `terrain: grass`, `rate` 25, rampe
`{ from_step: 15, max_steps: 20 }` [D].

| Route 8 | Niveaux | Poids |
|---|---|---|
| Roucool | 18–20 | 30 |
| Férosinge | 18–20 | 15 |
| Miaouss | 18–20 | 15 |
| Abo | 17–19 | 10 |
| Sabelette | 17–19 | 10 |
| Caninos | 15–18 | 10 |
| Goupix | 15–18 | 10 |

| Route 7 | Niveaux | Poids |
|---|---|---|
| Roucool | 19–22 | 30 |
| Mystherbe | 19–22 | 15 |
| Chétiflor | 19–22 | 15 |
| Férosinge | 17–20 | 10 |
| Miaouss | 17–20 | 10 |
| Caninos | 18–20 | 10 |
| Goupix | 18–20 | 10 |

Souterrain, ville, repaire : aucune rencontre. Pokémon d'ambiance des grilles : Roucool,
Sabelette, Mystherbe (planches existantes, à vérifier au T2).

#### 2.10.6 Dresseurs (`data/trainers/route_8.json`, `celadon_gym.json`, `rocket_hideout.json`)

Prix = base RB × niveau du dernier Pokémon (règle vérifiée sur les Dresseurs existants : Fillette
Léa 15 × 9 = 135). IA `random` sauf Erika, Giovanni et la Topdresseuse (`smart`, §21). Prénoms
[D], choisis pour ne pas répéter ceux des J3–J19 (revérifiés au T9). Les identifiants remplacent
l'attribut `trainer=` des grilles (géométrie inchangée).

| Grille | Identifiant | Nom | Équipe (remplacements en gras) | Prix |
|---|---|---|---|---|
| D1 | `route_8_nerd_anatole` | Intello Anatole | Voltorbe, Smogo, Voltorbe 20, Magnéti 20 (**Voltorbe** sans J17) | 500 |
| D2 | `route_8_gambler_rene` | Joueur René | **Hypotrempe, Hypotrempe, Poissirène** 22 (Ptitard, Têtarte absents) | 1 540 |
| D3 | `route_8_nerd_firmin` | Intello Firmin | **Smogo, Arbok, Smogo** 22 (Tadmorv, Grotadmorv absents) | 550 |
| D4 | `route_8_lass_iris` | Fillette Iris | Nidoran♀, Nidorina 23 | 345 |
| D5 | `route_8_lass_margot` | Fillette Margot | Miaouss ×3 24 | 360 |
| D6 | `route_8_gambler_fernand` | Joueur Fernand | Caninos, Goupix 24 | 1 680 |
| D7 | `route_8_lass_nina` | Fillette Nina | Mélofée ×2 22 | 330 |
| E1 | `celadon_gym_lass_lila` | Fillette Lila | Chétiflor, Boustiflor 23 | 345 |
| E2 | `celadon_gym_lass_capucine` | Fillette Capucine | Mystherbe, Ortide 23 | 345 |
| E3 | `celadon_gym_beauty_violette` | Beauté Violette | Chétiflor ×2 24 | 1 680 |
| E4 | `celadon_gym_jr_trainer_apolline` | Jeune Dresseuse Apolline | Bulbizarre, Herbizarre 24 | 480 |
| E5 | `celadon_gym_cooltrainer_camelia` | Topdresseuse Camélia | Boustiflor, Ortide, Herbizarre 24 (`smart`) | 840 |
| Erika | `celadon_gym_erika` | Erika | Empiflor 29, Saquedeneu 24, Rafflesia 29 + Méga-Sangsue (**niveaux et capacités : T8**) | 99 × niveau final (RB 2 871) |
| Casino | `celadon_game_corner_rocket` | Sbire Rocket | Rattatac, Nosferapti 20 | 600 |
| B1F | `rocket_hideout_b1f_1` | Sbire Rocket | Soporifik, Machoc 21 (**Kadabra** sans J17) | 630 |
| B1F | `rocket_hideout_b1f_2` | Sbire Rocket | Rattatac ×2 21 | 630 |
| B1F | `rocket_hideout_b1f_3` | Sbire Rocket | **Abo**, Smogo, Smogo 20 (Tadmorv absent) | 600 |
| B2F | `rocket_hideout_b2f_1` | Sbire Rocket | Nosferapti, Smogo, **Abo**, Nosferapti, Rattatac 17 | 510 |
| B3F | `rocket_hideout_b3f_1` | Sbire Rocket | Rattata, Rattatac, Soporifik 20 (**Kadabra** sans J17) | 600 |
| B3F | `rocket_hideout_b3f_2` | Sbire Rocket | Machoc ×2 21 | 630 |
| B4F | `rocket_hideout_b4f_key` | Sbire Rocket | Smogo, Nosferapti 21 | 630 |
| B4F | `rocket_hideout_b4f_guard_1` | Sbire Rocket | Sabelette, Abo, Sablaireau 23 | 690 |
| B4F | `rocket_hideout_b4f_guard_2` | Sbire Rocket | Abo, Sabelette, Arbok 23 | 690 |
| B4F | `giovanni_hideout` | Giovanni | Onix 25, Rhinocorne 24, Kangourex 29 (**T8**) | 99 × niveau final (RB 2 871) |

7 + 5 + 10 (Casino compris) + Erika + Giovanni. Capacités : apprises au niveau, sauf capacité en
attente (règle J12) ; Rafflesia d'Erika : Méga-Sangsue (RB). Répliques : §20 et annexe A.
`can_lose: false`, `heal_after: false`, `gives_exp: true` (modèle existant).

#### 2.10.7 Réalisé au T7 (branche `j20-t7-data`, non fusionnée)

- **Fichiers nouveaux** : `species/kanto_celadon.json` (13 espèces, valeurs actuelles PokeAPI,
  apprentissages RB ; Caninos et Goupix **identiques** à ceux du J17 : T9 garde une copie),
  `moves/celadon.json` (9 : `mega_drain`, `constrict`, `comet_punch`, `stomp`, `dizzy_punch`,
  `acid_armor`, `mist`, et `take_down`, `roar` **copiés mot pour mot du J17**), `items/items_j20.json`
  (Super Ball, 4 pierres, 3 boissons, CT13, CT21, Clé Ascenseur, Scope Sylphe ; nommé comme
  `items_j14.json` pour être lu après `items.json` : ordre « pertinence » du Sac, Poké Ball en
  tête), `shops/celadon_dept.json`
  (pierres du 4e, trois distributeurs du toit), `encounters/route_7.json`, `route_8.json`,
  `trainers/route_8.json`, `celadon_gym.json`, `rocket_hideout.json` (Casino compris), sprites
  provisoires des 13 espèces (`gen_placeholder_battlers.gd`, bloc « Jalon 20 » ; Caninos et Goupix
  pixel pour pixel ceux du J17).
- **Fichiers existants touchés** (une ligne chacun, comme prévu au T9) : `kanto.json` (évolutions
  d'Ortide, de Boustiflor et de **Stari → Staross** par pierre), `pokedex/kanto.json` (13 entrées
  en fin), `tm_compatibility.json` (régénéré, ajouts seulement).
- **En attente du moteur (T11)** : `data/j20_pending/items_t11.json` (Rappel `revive`, Poupée Poké et
  objets X `battle_use`, prix de la CT01) et `shops_t11.json` (2e, 2e CT, 4e, 5e). Aucune
  bibliothèque ne lit ce dossier ; le T11 ajoute les clés puis déplace les entrées.
- **Textes de l'annexe A** (brouillon, Q-1) : copiés mot pour mot, **sans** clé `draft` (les
  tests partagés n'en admettent aucune : `test_no_draft_in_data`, Pokédex, capacités) ; la
  correspondance numéro → donnée est `ANNEX_TEXTS` de `tests/unit/test_celadon_data.gd`, qui
  compare chaque donnée à l'annexe (corriger l'annexe fait échouer le test sur la donnée à
  remplacer ; n° 126, 154 : titres des cartes d'Erika et de Giovanni). Osselait (n° 204) : avec
  l'espèce, au T9. Dialogues (§20 et annexe A) : au T17 / T21, avec les PNJ.
- **Capacités sans effet retirées des équipes imposées** (règle J12) : Hurlement (Caninos, Goupix
  de Fernand), Frénésie (Onix, Kangourex de Giovanni) ; Danse Fleur → Méga-Sangsue (Rafflesia).
- **Tests partagés recalés** (comptes et listes : espèces, capacités, objets, boutiques, tables,
  cartes de Champion, changement de Pokémon de l'IA, CT11, CT34, évolutions d'Ortide, Boustiflor,
  Stari ; la lignée d'Évoli de `test_evolution_reveal` vient désormais des données).

### 2.11 Drapeaux, objectifs, zones, Grands moments (T17, T21)

- **Drapeaux** (tous dans `flags`) : `route_8_reached` (déclencheur sur la 2e colonne de l'arrivée
  est, tout pas vers l'ouest [D]), `celadon_reached` (déclencheur `arrivee_est` de la grille),
  `erika_met`, `tm21_received`, `eevee_received`, `rooftop_tm13`, `game_corner_switch`,
  `rocket_dropped_lift_key`, `rocket_hideout_b4f_door_open`, `giovanni_met`,
  `giovanni_hideout_won`, `cut_celadon_gym_bush`, `cut_celadon_gym_inner_bush` (J16),
  `beaten_<22 + 2>`, `got_<objets>` (visibles et cachés), `badge_rainbow` (existant).
- **Objectifs** (`objectives.json`, **en tête**, ordre « plus avancé d'abord ») :
  1. `back_to_tower` « retourner à la Tour Pokémon. » — `if [got_rocket_hideout_b4f_silph_scope]`
     (le J21 ajoutera son `unless`) ;
  2. `search_game_corner` « fouiller sous le Casino. » — `if [game_corner_switch]`, `unless
     [got_rocket_hideout_b4f_silph_scope]` ;
  3. `explore_celadon` « explorer Céladopole. » — `if [celadon_reached]`, `unless
     [game_corner_switch]` ;
  4. `go_celadon` « rejoindre Céladopole. » — `if [route_8_reached]`, `unless [celadon_reached]`.
  Conflit de tête attendu avec J16–J19 : ordre du voyage réglé au T9.
- **Zones** (`zones.json`, entrées existantes complétées) : `route_8` (`maps` : route, poste,
  bâtiment d'entrée), `underground_path_7_8` (nouvelle, `kind: place`), `route_7` (+ poste,
  bâtiment), `celadon_city` (`maps` : ville + 19 intérieurs + **cartes du repaire** [D, le repaire
  n'est pas une zone de la Carte] ; services Centre, grand magasin `found_on: celadon_dept_gf`, Arène
  `found_on: celadon_city`) ; sous-titres et descriptions : annexe A. Légende d'arrivée de
  Céladopole : T-13 (mécanisme des villes).
- `kanto_placeholder_areas.json` : aires `route_7`, `route_8` ; `pokedex/scenes.json` : décors
  « prairie » [D].
- **Grands moments** : `MomentLibrary.TYPES += giovanni` (en fin) ; `moments.json` : texte du type
  `giovanni` et `zone_arrivals.celadon_city` (annexe A) ; badge : type existant.
- **Points de repos** : `celadon_center` (`registers: true`).

### 2.12 Compagnon (T22)

- Suit dehors, sur les routes, dans le souterrain **et dans le repaire** (grotte) ; rentre dans les
  intérieurs (dont le toit du grand magasin et celui de la Résidence [D]) ; **se rétracte** pendant
  une glisse et un trajet d'ascenseur (`on_cutscene_started / finished`), ressort derrière le
  joueur.
- `companions.json` : contexte `celadon_city: city` ; `rocket_hideout_*` : aucun contexte [D]
  (phrase générique) ; **Évoli** éligible si sa planche (repos + marche 4 directions) est validée
  au T3, sinon non (règle J11 : aucun substitut).

### 2.13 Sauvegarde : **aucune version nouvelle** (v7)

| Ce que le J20 écrit | Champ | Forme | Version |
|---|---|---|---|
| drapeaux (Dresseurs, objets, histoire, porte, Clé, Coupe) | `flags` | inchangée | 7 |
| Clé, Scope, pierres, boissons, objets X, Rappel, CT13, CT21 | `bag` | identifiants seulement (catégories en fin d'enum, aucun index sauvé) | 7 |
| objets trouvés | `found_items` | inchangée | 7 |
| Grand moment `giovanni` | `moments` | `{type, map, date, details}` inchangée | 7 |
| Évoli (équipe ou Stockage) | `party` / `storage` | inchangée ; **`met.origin` = `"gift"`**, valeur nouvelle d'un champ texte | 7 |
| espèces nouvelles | `pokedex` | identifiants | 7 |
| position | `map`, `cell`, `facing` | toujours une case stable (verrous des dalles et de l'ascenseur ; cabine réécrite, §2.3.5) | 7 |
| ascenseur, glisse | — | **rien** n'est sauvé | — |

**Pourquoi pas de v8** : aucun champ n'est ajouté ni ne change de forme. Seul risque : une build
J19 qui lirait une partie J20 verrait l'origine `gift` en « inconnue » (« Rencontré à ») et la
réécrirait ainsi ; aucun Pokémon ni objet perdu, les builds ne reculent pas. Accepté [D].

Tests `test_save_j20` : `VERSION == 7` ; aller-retour d'Évoli (origine `gift`, uid, Stockage) ; Clé
et Scope dans le Sac ; partie v7 du J15 (fixture) chargée sans changement ; sauvegarde écrite dans
la cabine → étage ; aucune écriture pendant une glisse (Boot réel, `FrameSim`) ; position sur une
flèche → `safe_cell` ; Giovanni battu sans Scope ramassé → Poké Ball au sol après rechargement.

### 2.14 Départs de débogage (T17, T21)

`tools/debug_start/` (README) : équipe de référence « arrivée J19 » [D] (starter évolué N28,
Roucoups N24, Papilusion N22, un Pokémon apte à Couper, CS01, Badges Roche, Cascade, Foudre) :
`route_8` (bord est), `route_8_west`, `underground_7_8`, `route_7`, `celadon` (entrée est),
`celadon_dept` (5 000 ₽, Eau Fraîche, Soda Cool), `celadon_dept_tm01` (CT01 déjà au Sac),
`celadon_eevee_full` (équipe de 6), `celadon_gym_outside` (devant l'arbuste), `celadon_gym`
(dans l'Arène, arbustes coupés), `erika_weak` (pour perdre), `game_corner`, `rocket_hideout_b1f`,
`rocket_hideout_b2f` (dalles), `rocket_hideout_b3f`, `rocket_hideout_key` (B4F ouest, sbire battu),
`rocket_hideout_lift` (Clé au Sac, cabine), `giovanni` (B4F est, gardes battus), `giovanni_weak`,
`tower_scope` (si le J19 est là). Test `test_j20_qa_starts` (chaque départ se charge).

### 2.15 Budgets et mesures

- ≤ **3 000 nœuds** par carte, mesuré **dès la première construction** : Céladopole (3 220 cases :
  bâtiments en grands aplats, massifs regroupés ; repli : décor du jardin nord fusionné en une
  image), Route 8 (2 080 cases, forêt sur les bords).
- Mémoire « carte + voisines » (`tools/measure_map_cache.gd`) : Route 7 + Céladopole ; seuil
  informatif 64 Mo (J12 ; J15 a relevé 94 Mo de textures sur S21 sans ralentissement).
- fps : moyenne ≥ 58, creux ≥ 50 (ville, repaire pendant une glisse, Casino avec néons).
- Dalles et ascenseur : aucune allocation par pas ; `SpinTileDirector` en veille hors repaire.

### 2.16 Postes de Safrania : une boisson ouvre la ville (T25 ; décision de Kevin, 2026-10-19)

Décision relayée par la session de coordination (`docs/design/strategie-acceleration.md`, levier 1 ;
`passes/j26-v2-chatgpt.md`) : **l'entrée dans Safrania se fait au J20**, comme dans Rouge/Bleu. Elle
**remplace H-5 (C)** du dossier 23 §6 (« le garde ne parle pas de soif, aucun drapeau »). Le J26
consomme la règle sans la coder.

**Règle (RB)** : le garde a soif. Le joueur lui donne **une** boisson (Eau Fraîche, Soda Cool ou
Limonade, achetées au toit du grand magasin) → drapeau **`saffron_gates_open`** → **les quatre
postes** s'ouvrent (Route 7 et Route 8 du J20, Route 5 et Route 6 du J15). Aucun objet nouveau, aucun
Thé (RFVF non retenu).

**Données seulement**, avec les mécanismes déjà écrits (§2.9.6 : `if_items`, `confirm_cutscene`,
`take`) :
- dialogue `saffron_gate_guard` (les deux postes du J20) : `if [saffron_gates_open]` → merci (215) ;
  `if_items` une boisson → soif (216) + choix « Lui donner une boisson ? » (217) →
  `confirm_cutscene: saffron_gate_drink` ; refus (218) ; sinon → soif (216).
- boisson donnée [D] : la **première présente** dans l'ordre Eau Fraîche → Soda Cool → Limonade (la
  moins chère d'abord, et l'Eau reste la seule utile à la fillette du toit si le joueur en a deux).
  Trois variantes `if_items` dans l'ordre suffisent ; pas de menu de choix.
- scène `saffron_gate_drink` : `take: <boisson>` → `set [saffron_gates_open]` dans **un seul bloc
  synchrone** (aucune sauvegarde entre les deux) → 219 → le garde fait **un pas de côté** (vers la
  case libre (4, 3) de `poste_safrania.txt`) et garde cette place (`if [saffron_gates_open]` dans le
  placement du PNJ).
- porte S (5, 2)–(6, 2) : devient un **warp** `STEP_ON ↑` vers `saffron_city` / `from_gate_r7` ou
  `from_gate_r8`, actif seulement `if [saffron_gates_open]`. La grille change d'un seul caractère de
  légende (S « porte fermée, bloquée » → « porte, praticable si ouverte ») : **aucune géométrie
  modifiée**, `plan_check_routes_j20.py` suit.
- J15 (Route 5, Route 6, données dans `main`, J15 terminé) : `unless [saffron_gates_open]` ajouté
  aux règles qui repoussent le joueur (`route_5_gate_*`, `route_6_gate_rule_*`) et à la réplique
  « fermée » ; mêmes warps vers `saffron_city`. Données seulement.

**Tant que la carte `saffron_city` n'existe pas (avant le J26)** [Q-4 : A, décidé par Kevin] : la mécanique entière est
codée et testée, mais le garde **ne demande rien** : sa réplique reste « fermée » (texte 12) et la
porte reste bloquée. La bascule est **une donnée** : `saffron_city` reçoit ses `maps` dans
`data/world/zones.json` (aujourd'hui `[]`), et `ZoneLibrary` dit si la zone est jouable. Le J26
remplit la zone, et les postes s'ouvrent sans une ligne de code. Ainsi aucune partie du J20 ne
donne une boisson pour une porte qui ne mène nulle part, et aucune réplique ne promet Safrania
(règle de l'annexe A).

**Sauvegarde** : v7 inchangée (`saffron_gates_open` dans `flags`, boisson retirée du `bag`).

**Tests** (`test_saffron_gates`, sur une carte de test où `saffron_city` est déclarée jouable) :
sans boisson ; avec chacune des trois ; avec deux boissons (l'Eau part en premier) ; refus ;
drapeau posé → les quatre postes laissent passer, le garde du J20 s'est écarté ; zone non jouable →
texte 12, porte bloquée, aucune variante « soif » ; partie v7 du J15 chargée sans changement.

---

## 3. Tâches

Branches `j20-t<n>-<sujet>` ; jamais de `pkill` ; chaque tâche met à jour `etat-projet.md` dans son
commit ; textes **mot pour mot** (§20 et annexe A validée).

#### T0 — architecte : plan (ce document)

#### T1 — architecte + Kevin : lot de textes complémentaire — **(A)**
- Annexe A (n° 61 et suivants) → validation groupée (Q-1). **CA** : validé ; bloque les données de
  dialogue (T7, T17, T21), pas le code.

#### T2 — architecte : kit d'assets — **(A)**, après les vues générales validées
- §1.4 ; fiche, `tools/art/serie<n>.py`, planche `build/art/J20_KIT_v1.png`. **CA** : chaque élément
  visible des vues validées a un asset (réutilisé, varié, nouveau) ou est abandonné explicitement.

#### T3 — constructeur-monde (Mac) : génération, planches, dos — **(A)**, après T2
- Codex (personnages peints, lumière neutre) ; artworks officiels (faces) ; dos Colab des espèces
  capturables (§1.4) ; planche d'Évoli compagnon si budget. **CA** : planche de contact validée par
  Kevin ; espèces sans art définitif listées dans `etat-projet.md` (art provisoire, §9 du dossier).

#### T4 — architecte : logique pure des dalles — **(A)**
- §2.4.3 : `SpinTileRules`, `SpinSlide`, `SpinTileField` (nœud de données seul) ; tests
  `test_spin_tile_rules` (synthétiques + grilles B2F et B3F réelles contre les trajets RB).
- **CA** : 59 trajets identiques à RB ; aucune boucle ; aucun fichier existant modifié.

#### T5 — architecte : logique pure de l'ascenseur — **(A)**
- §2.3.1, §2.3.2 ; `data/world/elevators.json` ; tests `test_elevator_library`,
  `test_elevator_rules`. **CA** : étages autorisés, refus sans Clé ; aucun fichier existant modifié.

#### T6 — architecte : logique pure du don — **(A)**
- §2.5.1 : `PokemonGift`, `GiftResult` (origine provisoire `CAPTURE` dans la branche, remplacée par
  `GIFT` au T12) ; `test_pokemon_gift`. **CA** : bloc synchrone, unicité, équipe pleine → Stockage.

#### T7 — architecte : données — **(A)**, branche `j20-t7-data` **non fusionnée**
- §2.10 (espèces, évolutions, capacités, objets, Pokédex, Dresseurs, rencontres, boutiques),
  dialogues du §20 et de l'annexe A une fois validée ; `gen_tm_compatibility.py` relancé ; dos
  provisoires (`gen_placeholder_battlers.gd`). Les fichiers qui citent une espèce du J17 / J19
  restent sur la branche jusqu'au T9.
- Tests : `test_pokemon_data` (compte d'espèces recalé, évolutions par pierre, `mega_drain` drain),
  `test_stone_use` (Évoli × 3 pierres, Rafflesia, Empiflor, Staross ; Pierre Plante sur Évoli =
  INCOMPATIBLE), `test_item_library`, `test_shop_library`, `test_trainer_library`,
  `test_encounter_library`, `test_pokedex_library`. **CA** : tests verts sur la branche.

#### T8 — architecte : simulations d'Erika et de Giovanni — **(A)**, après T7
- `tools/simulate_celadon.gd` (modèle `simulate_mt_moon.gd` ; vrai moteur, vraie IA, 1 000 graines)
  ; profils « arrivée J19 » : chaque starter évolué N26–28 + deux équipiers naturels (Roucoups,
  Papilusion, Férosinge, Nidorino…), avec 0 / 3 / 5 Super Potions ; Erika RB 29 / 24 / 29 et
  variantes ; Giovanni RB 25 / 24 / 29 et variantes ; Salamèche face à Erika et Bulbizarre face à
  Giovanni comme cas faciles, Carapuce face à Erika comme cas difficile.
- Tableau des taux de victoire pour Kevin, **sans seuil** (méthode du J10 T16). **CA** : Kevin fixe
  les niveaux et capacités (Q-3) ; données mises à jour.
- **Fait (2026-10-16, branche `j20-t7-data`)** : `docs/tech/jalon-20-equilibrage.md`, scénario
  `tools/sim/celadon_thresholds.json` (simulateur du J12–J13 tel quel). Constat : Erika RB =
  Salamèche facile, Carapuce difficile (attendu) ; **Giovanni RB = mur pour les trois starters**
  (Kangourex N29), Bulbizarre compris. Propositions : Erika E-1 (Saquedeneu 24 en tête, Empiflor
  27, Rafflesia 29), Giovanni G-1 (Onix 23, Rhinocorne 22, Kangourex 25) ; données inchangées en
  attendant Q-3.

#### T9 — architecte : ouverture du J20 — **(B), premier**
- Fusion de `main` (J16–J19) dans `jalon-20` ; fusion des branches T4–T8 ; réalignement : §0.1 et
  §0.3 (noms réels : `FieldMoves`, `cut_tree`, `lavender_town` et ses spawns, variantes `field`,
  espèces et capacités des J17 / J19, objectifs et moments) ; tableau des CT (§2.10.3) refait ;
  remplacements d'espèces (§2.10.6) confirmés ; `plan_check.py` relancé (38 plans).
- **CA** : `tools/test.sh` vert, import propre ; ce plan corrigé dans le même commit.

#### T10 — constructeur-monde (Mac) : intégration de l'art — (B), après T3 et T9 — **FAIT le 2026-10-20** (série 22 : personnages, dos, décors ; icônes et reste du kit : série 22 bis, détail `etat-projet.md`)
- Manifeste (fin), `preparer.py`, `build_painted_props.gd -- --nouveaux`,
  `build_character_frames.gd` (fin), icônes du Sac, fonds de combat (`decors.json`). **CA** : second
  passage sans changement ; `test_painted_props`, `test_battle_stage` verts.

#### T11 — architecte : objets nouveaux et boutiques — (B) → **20.0b** — **FAIT le 2026-10-20**
- Fait : §2.9.1 à §2.9.4 (détail et écarts : `etat-projet.md`, entrée « J20 T11 ») ; §2.9.6
  (`if_items`) reporté au T25, qui en a besoin le premier.
- §2.9.1 à §2.9.4 : clé `shop`, CT achetable une fois, `battle_use` (Poupée Poké, objets X),
  `revive` (Rappel) dans `ItemUse` et le combat, `BattleAction.use_item`, `ITEM_ESCAPE`, `REVIVED` ;
  messages (annexe A) dans `data/battle/messages.json`.
- Tests : `test_dialogue_library`, `test_service_director`, `test_shop_rules`, `test_shop_views`,
  `test_item_use`, `test_battle_items`, `test_battle_revive`, `test_bag_query`.
- **CA** : tests verts ; **combats de test** (départs `celadon_dept` + un combat sauvage et un de
  Dresseur) : captures Mac de la Poupée, d'un objet X, du Rappel en combat et hors combat.

#### T12 — architecte : don de Pokémon — (B), après T6 et T9 — **FAIT le 2026-10-20**
- Fait (branche `j20-t12-t13`) : `Pokemon.Origin.GIFT` (« gift », « Reçu à ») ; étape
  `gift_pokemon` (clés `level`, `flag`, `say` obligatoires, `say_stored` facultative ; espèce
  vérifiée par `check_species`) ; `CutsceneDirector.set_pokemon_data`, signal
  `pokemon_gifted(pokemon, stored)` émis après le don, avant les dialogues ; Boot : compagnon
  rafraîchi, `request_autosave("don")` (toasts du Pokédex par `pokedex.recorded`, inchangés).
- **Données d'Évoli posées dès T12** (§2.5.3) : dialogues `celadon_eevee_ball` (T-28 + OUI/NON),
  `celadon_eevee_received` (T-29), `celadon_eevee_stored` (T-30) dans
  `data/dialogues/celadon_eevee.json` ; scène `celadon_eevee_gift` (`unless: [eevee_received]`,
  don puis `despawn: eevee_ball` si reçu) dans `data/cutscenes/celadon_eevee.json`. **Au T17** :
  poser seulement le PNJ `eevee_ball` dans `data/npcs/celadon_mansion_roof_house.json`, retirer
  les trois dialogues de `UNUSED_YET` (`test_dialogue_data`) et passer `celadon_eevee_gift` de
  `qa_gift_j20` à `celadon_mansion_roof_house` dans `CODE_PLAYED` (`test_cutscene_data`).
- Carte de QA `qa_gift_j20` (`tools/build_qa_j20.gd`, `data/npcs/qa_gift_j20.json`, tuiles
  provisoires, Poké Ball au sol `object/poke_ball_ground` [D]) : **retirée au T24**.
- §2.5.2 : `Origin.GIFT`, étape `gift_pokemon`, signal `pokemon_gifted`, Boot (autosave, compagnon,
  Pokédex) ; tests `test_cutscene_library` (étape et clés), intégration `test_eevee_gift` (vraie
  Boot : équipe de 5 → équipe ; de 6 → Stockage + T-30 ; Poké Ball absente après ; **rechargement :
  pas de second Évoli** ; Pokédex) ; `test_save_j20` (origine).

#### T13 — architecte : ascenseur — (B), après T5 et T9 — **FAIT le 2026-10-20**
- Fait (branche `j20-t12-t13`) : `ElevatorDirector` (`game/world/elevator/elevator_director.gd`,
  enfant de Boot, bloc J20), action `open_elevator` (`DialogueLibrary.ACTIONS`,
  `ServiceDirector.elevator_requested`, ouverture à la fin du dialogue comme la Boutique), sortie
  réorientée à chaque entrée dans la cabine et après chaque trajet, position sauvée
  (`stable_location` dans `_persist_snapshot` et à l'ouverture du menu), retour Android
  (FERMER ; avalé pendant le trajet), `is_stable()` faux panneau ouvert et pendant le trajet.
- **Écarts [D]** : un seul dialogue de panneau pour toutes les cabines, `elevator_panel`
  (variante sans page, `action: open_elevator`), et un seul refus, `elevator_locked` (T-50), au
  lieu de `<car>_panel` / `rocket_hideout_elevator_locked` : le directeur connaît l'ascenseur
  par la carte. Les cabines (T16, T20) posent un `InteractPoint` EXAMINER `elevator_panel`.
  Sont réorientés les warps de la cabine qui mènent à un **étage** de l'ascenseur. Trajet :
  secousse 0,25 s ±6 px (verticale, coupée par « Réduire les animations ») + vibration
  `HAPTIC_TAP_MS`, puis fondu 0,2 s au noir et 0,2 s retour. Orientation sauvée = celle de la
  sortie de la cabine (ZERO : celle du joueur).
- **Interface pour T14** (`ElevatorPanel`, `game/ui/elevator/elevator_panel.gd`, **écran
  provisoire** à remplacer en gardant l'interface) : `open(view: ElevatorPanelView)`, `close()`,
  `is_open() -> bool`, signaux `floor_chosen(floor_id: StringName)` et `closed` (FERMER). Vue pure
  `ElevatorPanelView` (`game/world/elevator/elevator_panel_view.gd`) : `title` (« Quel étage ? »,
  n° 158), `close_label` (« FERMER », n° 159), `floors` = `[{id, label, current}]` dans l'ordre
  des données, `current_floor()`, `choosable_ids()`. L'écran ne décide rien : l'étage courant est
  à griser (le directeur refuse de toute façon `SAME_FLOOR`) ; le retour Android ne passe pas par
  l'écran (Boot → `ElevatorDirector.handle_back()` → `close()`). Boot crée l'écran dans
  `_setup_elevators()` (`ElevatorPanel.new()`) : si T14 en fait une scène `.tscn`, n'y changer que
  l'instanciation.
- Tests : `test_elevator_flow` (vraie Boot, cartes de QA), `test_elevator_director` (vue,
  position sauvée), `test_service_director` ; recalés : `test_dialogue_library` (ACTIONS),
  `test_dialogue_data` (`elevator_panel` en attente des cabines, `elevator_locked` joué par le
  code), `test_map_catalog`. **Tests sur le vrai magasin avec T16** (RdC → 5e, toit absent).
- Carte de QA (`tools/build_qa_j20.gd`) : cabine `qa_elevator_j20` (5 × 3, panneau en (2, 0),
  arrivée `entrance` (2, 1), sortie (2, 2) ↓) et étages `qa_elevator_j20_1f` / `_2f` (porte
  (3, 0), arrivée `from_elevator` (3, 1)) ; ascenseurs de test dans `tests/fixtures/elevators/`
  (`Boot.elevators_path`, tests seulement) ; **retirés au T24**.
- §2.3.3, §2.3.5 : `ElevatorDirector`, action `open_elevator`, réorientation de la sortie, position
  sauvée, retour Android. Tests : intégration `test_elevator_flow` sur une **carte de QA**
  `qa_elevator_j20` (cabine + deux étages, tuiles provisoires, retirée au T24) puis sur le vrai
  magasin (T16) : RdC → 5e → sortie au 5e ; toit absent ; FERMER = rien ; sauvegarde dans la cabine
  → étage ; repaire sans Clé → T-50.

#### T14 — ui-mobile : panneau d'étages et boutique — (B), après T11 et T13 — **FAIT le 2026-10-20**
- Fait (détail et valeurs par défaut : `etat-projet.md`, entrée « J20 T14 »).
- `ElevatorPanel` (§2.3.4) ; ligne « déjà dans le Sac » ; liste d'équipe du combat qui accepte un K.O.
  pour le Rappel. **CA** : captures 2340 × 1080 relues ; aucune couleur en dur.

#### T15 — constructeur-monde : Route 8, souterrain, Route 7, postes, raccord Lavanville — (B) — **FAIT le 2026-10-20**
- Fait (détail et valeurs par défaut : `etat-projet.md`, entrée « J20 T15 ») ; objets cachés,
  PNJ et Dresseurs laissés au T17.
- §2.1, §2.2 ; `build_route_8.gd`, `build_route_7.gd`, `build_underground_path_7_8.gd`, `_gate_room`
  ×4 ; raccord Lavanville (§2.1, retrait du `coming_soon` dans `build_lavender_town.gd`) ; cases des
  PNJ et objets réservées.
- Tests `test_route_8` (grille de la scène = grille du plan ; D1, D2, D4, D5 inévitables, D3, D6,
  D7 évitables, critères de `plan_check_routes_j20.py` sur la vraie scène ; corniche à sens unique ;
  nœuds), `test_route_7`, `test_underground_7_8` (aucune rencontre, hors `caves.json`),
  `test_map_links`, `test_map_catalog`, `test_lavender_route_8` (partie sauvegardée sur chaque case
  du bord ouest de Lavanville → reprise sur la case, le bord mène à la Route 8, retour sur la même
  rangée). **CA** : tests verts, captures relues contre les vues, budget.

#### T16 — constructeur-monde : Céladopole et intérieurs, Arène — (B) — **FAIT le 2026-10-20**
- Fait (détail et valeurs par défaut : `etat-projet.md`, entrée « J20 T16 ») : géométrie seulement ;
  PNJ, Dresseuses, Erika, Évoli, vendeurs et scènes au T17 ; trajet d'ascenseur au T13 (test en attente).
- §2.1, §2.2, `build_celadon_city.gd`, intérieurs (`--celadon`), `build_celadon_gym.gd` ; profil
  `greenhouse` ; `interiors.json`, `rest_points.json`, `zones.json`.
- Tests `test_celadon_city` (Arène fermée sans Coupe, ville entière ouverte sans Coupe ; 14 PNJ hors
  des cases de coupure ; toit de la Résidence seulement par l'escalier de service ; nœuds ≤ 3 000),
  `test_celadon_dept` (escaliers, ascenseur RdC–5e, toit par l'escalier seulement),
  `test_celadon_mansion`, `test_celadon_gym` (E5 inévitable, Erika atteignable par le tour).

#### T17 — constructeur-monde : vie du 20-I — (B), après T7 et T11–T16 — **FAIT le 2026-10-20**
- Fait (branche `j20-t17-vie`, détail et valeurs par défaut : `etat-projet.md`, entrée « J20 T17 »). Casino, repaire et dalles : T19 à T21.
- PNJ et répliques (§20, annexe A), Dresseurs Route 8 et Arène, gardes, habitants, vendeurs,
  distributeurs, fillette (§2.9.6), vieille dame, Évoli (§2.5.3), Erika (§2.8), arbustes, objets
  visibles et cachés (Route 8 : Super Potion, Rappel caché ; souterrain : Pépite, Super Potion ;
  ville : Rappel caché), objectifs, zones, moments, départs (§2.14).
- Tests `test_route_8_trainers` (duo D4 / D5 : deux combats successifs, jamais en duo ; prix),
  `test_celadon_life` (vendeurs → bonnes boutiques, pierres 2 100 ₽, Poupée 1 000 ₽, boissons, CT01
  une fois, fillette : Eau Fraîche → CT13 une seule fois, Soda seul → refus), `test_erika_flow`
  (badge, CT21, défaite → réveil, Dresseuses gardées, nouvel essai), `test_hidden_items` (+ 3
  caches), `test_objective_library`, `test_zone_library`, `test_moment_library`.

#### T18 — qa-mobile : **session 20-I** → Kevin — **FAIT, 20-I validé par Kevin le 2026-10-20** (S24)
- Protocole §6.2. **CA** : rapport `build/qa/jalon20_20i/`, validation de Kevin.

#### T19 — architecte : dalles tournantes — (B), après T4 et T9 — **FAIT le 2026-10-20**
- Fait (branche `j20-t19-dalles` depuis `jalon-20` à `fb1d6fbe`) : `SpinTileDirector`
  (`game/world/spin/spin_tile_director.gd`, enfant PAUSABLE de Boot, bloc J20
  `_setup_spin_tiles()`), branché sur `Player.moved` **avant** tous les autres écouteurs (appelé
  juste après `_runner.setup`) : le pas libre qui pose le joueur sur une dalle le bloque (raison
  `spin`) dans le `moved` même, donc aucun autre écouteur ne le traite. Chaque pas de course est
  lancé dans le `moved` du précédent (aucune image d'arrêt) ; la fin est **différée d'un appel**
  (`call_deferred`) pour que le dernier pas reste « bloqué » pour les autres écouteurs, puis verrou
  levé, `slide_finished(cell)`, `TrainerWatcher.check_at(cell)` (nouveau, public : le corps de
  l'ancien `_on_player_moved`). `is_stable()` et `_refresh_controls()` tiennent compte de
  `is_running()` ; compagnon rentré (`on_cutscene_started`) puis revenu ; `set_map` dans
  `_on_map_changed` (avant le compagnon) : sans `SpinTiles`, veille ; joueur posé sur une dalle →
  reposé sur `safe_cell` (reprise). Interface des cartes : §2.4.2.
- **Valeurs par défaut [D]** : contrôles cachés pendant la glisse (comme l'ascenseur : le
  joystick est relâché, il faut reposer le doigt à l'arrêt) ; aucune rencontre, aucun passage ni
  déclencheur sur la case d'arrêt (seuls les Dresseurs la regardent) ; `check()` des dalles à
  chaque entrée sur la carte en build debug seulement ; pas refusé = glisse arrêtée sur la case
  atteinte, joueur libre.
- Tests : `test_spin_slide` (vraie Boot, carte de QA `qa_spin_j20`, 9 tests : glisse au pas près,
  pivots, entrées / menu / retour refusés, aucune autosave ni à l'arrière-plan, compagnon,
  Dresseur de la case d'arrêt et pas celui du milieu, coupure en pleine glisse, sauvegarde sur une
  dalle, pas refusé, veille hors repaire) ; recalé : `test_map_catalog` (liste blanche). Carte
  `qa_spin_j20` (10 × 8) et `data/npcs/qa_spin_j20.json` (deux Dresseurs du Mont Sélénite
  réutilisés) **à retirer au T24**. Sur `rocket_hideout_b2f` : à faire avec T20 / T21.
- §2.4.4 : `SpinTileDirector`, verrou `spin`, `TrainerWatcher.check_at`, reprise `safe_cell` ;
  tests d'intégration `test_spin_slide` (vraie Boot sur `rocket_hideout_b2f` dès T20 ; avant, carte
  de QA `qa_spin_j20` de 10 × 8, retirée au T24) : glisse au pas près (`FrameSim`), entrées
  ignorées, menu et retour refusés, **aucune autosave** pendant la glisse, compagnon rétracté puis
  revenu, Dresseur qui voit la case d'arrêt.

#### T20 — constructeur-monde : Casino, repaire, cabine — (B), en parallèle de T17 — **FAIT le 2026-10-20**
- §2.1, §2.6, §2.7.1 ; `build_game_corner.gd`, `build_rocket_hideout.gd` (sol, murs, caisses,
  dalles peintes, `SpinTiles`, portes d'ascenseur), profil `hideout`, `caves.json`.
- Tests `test_rocket_hideout` (grilles = scènes ; `SpinTiles` = grille ; **chaque dalle mène à une
  case d'arrêt praticable de la scène** ; moitiés du B4F disjointes à pied ; escaliers aller-retour ;
  Corde Sortie → `from_casino_w` ; nœuds), `test_game_corner` (escalier inatteignable sans
  l'interrupteur).

#### T21 — constructeur-monde : vie du 20-II — (B), après T19 et T20 — **FAIT le 2026-10-20**
- Fait (branche `j20-t21-repaire` depuis `jalon-20` à `9d00b3fb` ; détail, valeurs par défaut et
  points à valider : `etat-projet.md`, entrée « J20 T21 »).
- Casino (Rocket, affiche, interrupteur, mur), repaire (10 Dresseurs, objets et caches, Clé, porte,
  Giovanni, Scope), contrôle de la Tour, départs.
- Tests `test_game_corner_switch`, `test_hideout_key` (Clé seulement après avoir reparlé ; unique ;
  gardée après une défaite), `test_hideout_elevator` (B1F, B2F, B4F seulement ; refus sans Clé ;
  B4F est atteint seulement par l'ascenseur), `test_giovanni_flow` (victoire → départ, Scope au sol,
  Grand moment ; défaite → réveil, Clé gardée ; application coupée avant le ramassage),
  `test_celadon_order` (Erika puis repaire, repaire puis Erika : mêmes résultats),
  `test_j20_no_j21_flags`, `test_tower_scope_j20` (si J19), `test_save_j20` (complet).

#### T22 — constructeur-monde : compagnon — (B) — **FAIT le 2026-10-20** (détail : `etat-projet.md`, entrée « J20 T22 »)
- §2.12 ; `test_companion_j20` (suit sur les routes, le souterrain, la ville et le repaire ; rentre
  dans les intérieurs ; se rétracte pendant une glisse et un trajet d'ascenseur ; Évoli s'il est
  éligible).

#### T23 — qa-mobile : **session 20-II** + QA finale → Kevin — **FAIT, 20-II validé par Kevin le 2026-10-20** (S24 ; détail : `etat-projet.md`, entrée « J20 T23 »)
- Protocole §6.2 ; **QA finale** : vraie partie de Kevin, de Lavanville au Scope (lot V 20F).

#### T25 — constructeur-monde : postes de Safrania et boisson — (B), après T11 et T15 — **FAIT le 2026-10-20**
- Fait (détail : `etat-projet.md`, entrée « J20 T25 ») ; remise de la boisson aux gardes du J15
  laissée au J26 (raison et marche à suivre dans la même entrée).
- §2.16 : dialogue, scène, warps conditionnels des deux postes du J20, `unless` des règles du J15 ;
  `test_saffron_gates`. Textes 215 à 219 (annexe A.14, validés). Vérifié dans la session 20-I.

#### T24 — architecte : clôture
- Retrait des cartes de QA (`qa_elevator_j20`, `qa_spin_j20`) et de leurs départs ; `etat-projet.md`,
  roadmap ; passation : J21 (Tour, 6F, `unless` de `back_to_tower`, Ossatueur), J26 (Safrania :
  carte `saffron_city` et ses quatre entrées, à brancher sur les warps du §2.16 ; Porygon), Route 16 (obstacle ouest), Jadielle (moteur des dalles) ;
  fusion dans `main` (copie d'intégration ; `project.godot` et filtre d'export vérifiés).

---

## 4. Critères d'acceptation par sous-jalon

**20.0** — textes validés ; planche d'art validée ; niveaux d'Erika et de Giovanni décidés ; logique
pure des dalles (59 trajets RB), de l'ascenseur et du don testée ; données complètes et vertes sur
leur branche ; puis (20.0b) objets nouveaux joués en combat de test, captures relues ; tests verts,
import propre.

**20-I** — Route 8 parcourable depuis Lavanville (ou son `coming_soon`) ; 7 Dresseurs, duo D4 / D5
successifs, D3 / D6 / D7 évitables ; poste fermé (T-12) ; souterrain silencieux, Pépite et Super
Potion cachées ; Route 7, rencontres (Caninos, Goupix) ; Céladopole lisible, 12 habitants + 2 Rocket
en civil, sortie ouest fermée (T-21) ; Centre et point de repos ; grand magasin : escaliers,
**ascenseur RdC–5e**, vendeurs (Super Ball, Rappel, CT01, Poupée, pierres, objets X), distributeurs,
fillette (CT13) ; Résidence, toit par l'escalier de service, **Évoli** (équipe ou Stockage, une
seule fois) ; pierre utilisée sur Évoli ; Arène : arbuste, 5 Dresseuses, E5 inévitable, Erika,
Badge Prisme (vibration, Grand moment), CT21 ; objectifs ; ≥ 58 fps ; nœuds ≤ 3 000.

**20-II** — Casino : machines en décor, Rocket, affiche, interrupteur, passage ouvert ; repaire :
10 Dresseurs, dalles (prise en main, reprise sur une case stable), Clé, ascenseur B1F / B2F / B4F,
porte des gardes, **Giovanni**, **Scope** ; Corde Sortie → devant le Casino ; Tour : rencontres
identifiées, 6F « à venir » ; aucun drapeau J21 ; **vraie partie de Kevin** sans régression ; tests
verts, import propre, budgets tenus.

---

## 5. Cas limites (dossier §19) → tests

| Cas | Test | Attendu |
|---|---|---|
| Arrivée devant l'Arène sans Coupe | `test_celadon_city` | message de l'arbuste (J16) ; reste de la ville ouvert |
| Équipe pleine au don d'Évoli | `test_eevee_gift` | Stockage + T-30 |
| Second Évoli après rechargement | `test_eevee_gift` | impossible (drapeau posé avec le don) |
| Partie quittée pendant une glisse | `test_spin_slide`, `test_save_j20` | aucune écriture pendant la glisse ; reprise sur la dernière case stable |
| Partie quittée dans l'ascenseur | `test_elevator_flow`, `test_save_j20` | reprise devant la porte de l'étage courant |
| Clé ramassée, puis défaite | `test_hideout_key` | Clé gardée ; descente par l'ascenseur |
| Giovanni battu, application coupée avant le Scope | `test_giovanni_flow` | Poké Ball du Scope au sol |
| Corde Sortie dans le repaire | `test_rocket_hideout` | devant le Casino, tourné ↓ |
| Joueur à la Tour avec le Scope (build J20) | `test_tower_scope_j20` | rencontres identifiées ; 6F SPECTRE |
| Retour au poste de Safrania | `test_saffron_gates` | sans boisson : réplique « soif », porte fermée ; boisson donnée : les 4 postes ouverts, une seule boisson retirée |
| Boisson donnée, application coupée pendant la scène | `test_saffron_gates` | drapeau et retrait de la boisson dans le même bloc synchrone (§2.16) |
| Pierre sur une espèce sans art définitif | `test_stone_use` + capture | évolution jouée, art provisoire |
| Compagnon | `test_companion_j20` | §2.12 |
| Défaite dans le repaire | `test_giovanni_flow` | réveil au dernier Centre ; Rocket battus gardés ; interrupteur gardé |
| Erika et repaire dans les deux ordres | `test_celadon_order` | aucun lien |
| CT01 déjà au Sac | `test_celadon_life` | « déjà dans le Sac », aucun achat |
| Poupée Poké contre un Dresseur | `test_battle_items` | refusée, objet gardé |
| Rappel sur un Pokémon debout | `test_item_use` | refusé (`NO_EFFECT`) |
| Fillette sans Eau Fraîche | `test_celadon_life` | T-24 ou « trop sucré », rien donné |

---

## 6. Tests et QA

### 6.1 Tests automatiques (GUT) — récapitulatif

Unitaires : `test_spin_tile_rules`, `test_elevator_library`, `test_elevator_rules`,
`test_pokemon_gift`, `test_pokemon_data`, `test_stone_use`, `test_item_library`, `test_item_use`,
`test_battle_items`, `test_battle_revive`, `test_shop_rules`, `test_shop_views`, `test_shop_library`,
`test_dialogue_library`, `test_cutscene_library`, `test_trainer_library`, `test_encounter_library`,
`test_pokedex_library`, `test_objective_library`, `test_zone_library`, `test_moment_library`,
`test_save_j20`, `test_j20_no_j21_flags`.

Intégration : `test_map_links` (32 cartes, aller-retour sur chaque porte), `test_map_catalog`,
`test_route_8`, `test_route_7`, `test_underground_7_8`, `test_lavender_route_8`,
`test_celadon_city`, `test_celadon_dept`, `test_celadon_mansion`, `test_celadon_gym`,
`test_route_8_trainers`, `test_celadon_life`, `test_erika_flow`, `test_eevee_gift`,
`test_elevator_flow`, `test_game_corner`, `test_game_corner_switch`, `test_rocket_hideout`,
`test_spin_slide`, `test_hideout_key`, `test_hideout_elevator`, `test_giovanni_flow`,
`test_celadon_order`, `test_tower_scope_j20`, `test_companion_j20`, `test_hidden_items`,
`test_j20_qa_starts`.

Règles de temps (skill `godot-conventions`) : glisse et fondu mesurés en temps simulé (`FrameSim`,
`TweenClock`), jamais en secondes réelles.

### 6.2 QA S24 (ou S21) bornée (dossier §24)

APK debug, départ déposé par `tools/deploy_s24.sh --debug-start <départ>` ; **30–45 min par
session** ; une étape qui bloque est notée (capture + journal) et la session continue. Preuve =
capture renommée `20i_<n>.png` / `20ii_<n>.png` ou ligne du journal citée.

*Session 20-I* (≈ 45 min)

| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `route_8` | traverser vers l'ouest par le chemin bas | D7, D6 évités ; duo D4 / D5 : deux combats successifs ; objectif « rejoindre Céladopole. » |
| 2 | (suite) | chemin haut, sauter la corniche ; Super Potion ; Rappel caché | toasts ; corniche à sens unique |
| 3 | `route_8_west` | poste de Safrania ; D1 ; bâtiment d'entrée | T-12 ; D1 inévitable ; T-10 |
| 4 | `underground_7_8` | parcourir, niche et coude | lisible sans monter la luminosité ; Pépite, Super Potion ; aucune rencontre |
| 5 | `route_7` | herbes, vers l'ouest | rencontres N17–22 ; arrivée : légende T-13 |
| 6 | `celadon` | parcourir la ville | 74 pas jusqu'à l'Arène jugés (dossier : point 3) ; habitants ; sortie ouest T-21 |
| 7 | `celadon_dept` | RdC → ascenseur → 5e → escalier → toit | panneau lisible, fondu et secousse, toit absent du panneau |
| 8 | (suite) | acheter Super Ball, Rappel, Poupée, une pierre, un objet X ; boissons ; fillette | prix ; CT13 une fois |
| 9 | `celadon_dept_tm01` | vendeur de CT | « déjà dans le Sac » |
| 10 | `celadon` | Résidence, escalier de service, maison du toit | Évoli N25 ; Pokédex |
| 11 | `celadon_eevee_full` | idem | Évoli au Stockage (T-30) |
| 12 | (suite) | Pierre Foudre sur Évoli | Voltali (art provisoire possible) |
| 13 | `celadon_gym_outside` | Couper l'arbuste ; Dresseuses ; Erika | E5 inévitable ; badge, vibration, CT21 ; Arène plus haute que l'écran jugée |
| 14 | `erika_weak` | perdre | réveil au Centre ; Dresseuses gardées |
| 15 | (fps) | pendant 1 à 13 | ≥ 58 fps moyens, creux ≥ 50 |

*Session 20-II* (≈ 45 min)

| n° | Départ | Geste | Attendu |
|---|---|---|---|
| 1 | `game_corner` | machines, Rocket, affiche, interrupteur | T-39, T-40/41, T-42/43 ; escalier ouvert |
| 2 | `rocket_hideout_b1f` | B1F, 3 sbires, Corde Sortie au sol | répliques ; objets |
| 3 | `rocket_hideout_b2f` | dalles : 10 glisses variées | **prise en main** : lisible, rien ne bloque, aucune case ambiguë |
| 4 | (suite) | quitter l'application pendant une glisse, relancer | reprise sur une case stable |
| 5 | `rocket_hideout_b3f` | dalles, Super Bonbon, caches | — |
| 6 | `rocket_hideout_key` | reparler au sbire, prendre la Clé | T-48, T-49 |
| 7 | `rocket_hideout_lift` | ascenseur sans Clé (autre départ), avec Clé → B4F | T-50 ; B1F, B2F, B4F seulement |
| 8 | (suite) | quitter l'application dans la cabine | reprise devant la porte de l'étage |
| 9 | `giovanni` | gardes, porte, Giovanni | T-51/52/53/54, départ, Scope, Grand moment |
| 10 | `giovanni_weak` | perdre | réveil ; Clé gardée |
| 11 | (suite) | Corde Sortie au B3F | devant le Casino |
| 12 | `tower_scope` (si J19) | rencontre à la Tour | espèce identifiée ; 6F bloqué |
| 13 | (fps) | ville, repaire, Casino | ≥ 58 fps moyens |
| 14 | **vraie partie de Kevin** (QA finale) | de Lavanville au Scope | aucune régression, rien perdu |

---

## 7. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Le plus gros jalon du projet** (32 cartes, 24 Dresseurs, 3 mécaniques) | durée, fatigue de QA | deux sous-jalons S24 ; cartes du repaire préparées avant ses événements ; QA bornée |
| **Dépendances J16–J19** (Coupe, Lavanville, espèces, Tour) | blocage du code | C-7 respectée : code après J19 ; protections §0.3 ; T9 réaligne |
| **Espèces créées deux fois** (Caninos au J17 **et** au J19) | conflit de données | « le premier fusionné crée » ; T9 vérifie, le J20 n'ajoute que règles et dos |
| **Budget de nœuds de Céladopole** | dépassement | mesure au premier passage ; aplats ; décor regroupé |
| **Repaire RB 1:1** (salles serrées, marges vides) | lisibilité sur téléphone | caméra qui suit (existante) ; vues générales ; session 20-II point 3 |
| **Dalles** : un trajet qui traverse un PNJ ou un objet | glisse arrêtée | test « aucun PNJ ni objet sur un trajet » ; `push_error` |
| **Fichiers chauds** (Boot, dialogue, scènes, objets, combat) | conflits | blocs courts « J20 », seulement en (B), après les fusions |
| **Vendeur de CT presque vide** | 2e étage décevant | Q-2 |
| **Objets X et Poupée** = petit système de plus | dérive | regroupés au 20.0b, validés seuls par combats de test |
| **Art** (13 espèces + 3 de la Tour, 7 PNJ nommés, 12 habitants tous différents) | retard | art provisoire signalé (règle 3) ; Tartard facultatif |
| **Échec intermittent connu** de `tools/test.sh` sous charge | faux rouge | relancer le fichier seul avant de conclure |

---

## 8. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Espèces | 13 (tableau du dossier), moins celles des J17 / J19 |
| CT | capacité **jouée** ; CT01, CT13, CT21 |
| Identifiants | §1.3 ; Dresseurs §2.10.6 ; arbustes `celadon_gym_bush`, `celadon_gym_inner_bush` |
| Fichiers de données | `kanto_celadon.json`, `moves/celadon.json`, `items/celadon.json`, `trainers/route_8.json`, `celadon_gym.json`, `rocket_hideout.json`, `encounters/route_7.json`, `route_8.json`, `shops/celadon_*.json`, `data/world/elevators.json` |
| Ascenseur | fondu 0,4 s, secousse 0,25 s ±6 px ; cabine jamais sauvée ; sortie réorientée |
| Dalles | vitesse de course ; pivot sans toupie ; reprise `safe_cell` ; `TrainerWatcher.check_at` |
| Don | aucun écran de surnom ; origine `gift`, « Reçu à » |
| Objets | Super Ball ×1,5 ; Rappel ½ PV, combat et hors combat ; objets X +1 ; Spécial + = Attaque Spéciale ; prix RB |
| Rocket du Casino | quitte la salle (`leave`) |
| Porte du bureau | drapeau dérivé `rocket_hideout_b4f_door_open` |
| Défaite | dernier point de repos (Céladopole en pratique) |
| Repaire | « grotte » de `caves.json` (Corde, compagnon visible) ; lumière `hideout` |
| Toits | intérieurs (sans compagnon) |
| Tartard | décor sans OBSERVER, facultatif |
| Rencontres | taux 25, rampe 15 → 20 |
| Sauvegarde | v7 |
| Budgets | ≤ 3 000 nœuds ; ≥ 58 fps moyens, creux ≥ 50 |

---

## 9. Questions pour Kevin

- **Q-1 — Lot de textes complémentaire** — **validé par Kevin le 2026-10-16.** (annexe A, n° 61 à 214) : habitants, intérieurs, magasin,
  Dresseurs sans texte, Casino, repaire, interface (panneau d'étages, boutique), combat (objets
  nouveaux), zones, Grands moments, descriptions d'objets et de capacités, Pokédex.
  *Recommandation : relecture en une passe, comme aux J13–J15 ; bloque les données, pas le code.*

- **Q-2 — Le vendeur de CT du 2e étage.** **Décidé par Kevin le 2026-10-16 : A (CT01 seule).** La règle H-7 (« capacité existante ») ne laisse passer
  que la **CT01 Ultimapoing**, déjà ramassable au Mont Sélénite. Empal'Korne, Protection, Sacrifice
  et Damoclès existent dans les données mais **ne font rien** en combat.
  - **A** — le vendeur vend la CT01 seule (achetable si elle n'est pas dans le Sac) ;
  - **B** — le vendeur est en « réassort » (réplique neutre, comme l'homme du 3e), aucune CT ;
  - **C** — on code au J20 le recul (`recoil_damage` : Sacrifice, Damoclès, Bélier) et les écrans
    (Protection, Mur Lumière), et le vendeur propose aussi CT09, CT10, CT17, CT33 (plus de travail
    dans le moteur de combat, juste après le J19).
  *Recommandation : **A**.* Elle respecte H-7, et le vendeur sert déjà à qui a manqué la CT01. C
  serait une passe de systèmes (H-7 la renvoyait à plus tard).

- **Q-3 — Niveaux et capacités d'Erika et de Giovanni** — **décidé le 2026-10-16 : E-1 et G-1** (`jalon-20-equilibrage.md` §5). : décidés par toi au vu de la simulation
  (T8), comme pour Pierre. *Pas une question aujourd'hui : une décision attendue au T8.*

- **Q-4 — Postes de Safrania avant le J26** (§2.16, décision du 2026-10-19). **Décidé par Kevin le 2026-10-19 : A.** La carte de Safrania
  n'arrive qu'au J26. Entre-temps :
  - **A** — la mécanique est codée et testée, mais le garde ne demande rien tant que la zone
    `saffron_city` n'est pas jouable (une donnée que le J26 remplit) ;
  - **B** — le garde prend la boisson dès le J20 ; la porte s'ouvre sur un écran « à suivre » ;
  - **C** — le garde prend la boisson dès le J20, s'écarte, mais la porte reste close jusqu'au J26.
  *Recommandation : **A**.* Aucune boisson donnée pour rien, aucune promesse, et le J26 n'a qu'à
  déclarer sa carte. 

**Notes (pas des questions)** : le dossier §15.1 compte 12 espèces mais en liste 13 (le plan suit
la liste) ; la capture n'ayant pas d'écran de surnom, le don d'Évoli n'en propose pas non plus.

**À fournir par Kevin** : la sauvegarde de sa vraie partie (après le J19) pour la QA finale.

---

## Annexe A — Lot de textes complémentaire (VALIDÉ par Kevin le 2026-10-16, Q-1)

> **Validé tel quel le 2026-10-16** (« Valide les textes de J20 »). Bélier (211) et Hurlement (213) :
> la mention « Sans effet dans le moteur actuel. » est la règle du projet depuis le J11 ; elle
> disparaîtra quand la branche `j19-effets-capacites` (effets de Bélier, Hurlement, Dévorêve,
> Ultralaser) sera fusionnée. **T9 s'aligne sur `data/pokemon/moves/tower.json` du J19** pour
> `take_down` et `roar` (et sur le J17 pour Caninos et Goupix) : les copies de
> `data/pokemon/moves/celadon.json` sont retirées à l'ouverture, sans créer de doublon.
>
> Numérotés à partir de 61, pour une réponse groupée (« 74 : … »). Ton du §20 : court, sobre, sans
> caricature ; Rocket = employés d'une organisation. Bulles de 2 lignes de ~40 caractères ; `/`
> sépare deux pages. Aucune réplique ne promet la Route 16, Safrania ou la suite de la Tour.

### A.1 Céladopole, habitants sans texte

61. Pêcheur sans canne (étang) : « Pas de pêche ici, c'est interdit. » / « Alors je regarde l'eau,
    avec mon Tartard. On aime ça, tous les deux. »
62. Enfant (fontaine) : « On dit que si on jette une pièce dans la fontaine, le vœu se réalise. » /
    « J'en ai jeté trois. J'attends encore. »
63. Promeneur du parc ouest : « Au bout de l'avenue, il n'y a que des arbres. » / « C'est pour ça
    que je viens lire ici. Personne ne passe. »
64. Cliente devant les vitrines : « Cinq étages de magasin. » / « Je n'arrive jamais à tout voir
    en une seule journée. »
65. Touriste devant l'hôtel : « Je suis venu pour les jardins. » / « J'ai prolongé mon séjour d'une
    semaine. »
66. Jardinier de la place : « On replante ces massifs à chaque saison. » / « Erika passe parfois
    nous donner des conseils. »
67. Jeune de la pelouse est : « De Lavanville, je prends toujours le souterrain. » / « C'est long,
    mais au moins il ne pleut pas. »
68. Cuisinier en pause : « Depuis que le Casino est fermé, le restaurant ne désemplit pas. » / « Je
    ne m'en plains pas. »

### A.2 Résidence et maison du chef

69. Résidence, 1er, habitant : « Cette résidence est la plus chic de la ville. » / « Les loyers
    aussi, d'ailleurs. »
70. Résidence, 1er, habitante : « La dame du rez-de-chaussée connaît tout le monde ici. » / « Et
    tous les Pokémon du quartier. »
71. Résidence, 2e, habitant : « Les murs sont épais. On n'entend jamais les voisins. » / « C'est
    reposant. »
72. Résidence, 2e, habitante : « Mes plantes poussent mieux depuis que j'ai suivi les conseils
    d'Erika. »
73. Maison du chef, habitant : « Mon fils veut devenir Dresseur. » / « Moi, j'aurais préféré qu'il
    reprenne la boutique. »
74. Maison du chef, habitante : « Le soir, on entendait la musique du Casino jusqu'ici. » / « Depuis
    qu'il est fermé, on dort mieux. »

### A.3 Hôtel et restaurant

75. Réceptionniste : « Bienvenue. » / « Nous sommes complets toute la semaine, désolée. »
76. Hôtel, client 1 : « Je suis venu pour le Casino. » / « “Fermé pour inventaire”… Drôle de façon
    de commencer des vacances. »
77. Hôtel, client 2 : « Ma chambre donne sur les jardins. » / « Le matin, tout sent la fleur. »
78. Serveur : « Une table ? Il faudra patienter un peu. » / « Nous sommes pleins depuis ce matin. »
79. Restaurant, convive : « Ici, tout est bon. » / « Surtout les desserts. »

### A.4 Grand magasin

80. Hôtesse d'accueil (RdC) : « Bienvenue au grand magasin de Céladopole ! » / « Le tableau des
    étages est juste derrière moi. »
81. RdC, client 1 : « Je cherche un cadeau. » / « Il paraît que le 4e est fait pour ça. »
82. RdC, client 2 : « L'ascenseur va plus vite. » / « Mais moi, je préfère les escaliers. »
83. 2e, client 1 : « Une Super Ball attrape mieux qu'une Poké Ball. » / « Elle vaut bien la
    différence de prix. »
84. 2e, client 2 : « Je fais toujours le plein de Rappels. » / « On ne sait jamais ce qui nous
    attend. »
85. 3e, joueur 1 : « Encore une partie, et j'arrête. »
86. 3e, joueur 2 : « Ce jeu est trop difficile. » / « … Ou alors c'est moi. »
87. 4e, client : « Une pierre d'évolution, c'est un beau cadeau. » / « Mais une fois utilisée, on ne
    revient pas en arrière. »
88. 5e, salon 1 : « On se repose ici entre deux étages. » / « Mes pieds me remercient. »
89. 5e, salon 2 : « Les objets du 5e servent en plein combat. » / « Un seul combat, puis leur effet
    s'en va. »
90. Distributeur (examiner, avant la boutique) : « Un distributeur de boissons fraîches. »
91. Fillette du toit, question : « Lui donner une Eau Fraîche ? »
92. Fillette, si NON : « Tant pis… Je vais attendre encore un peu. »
93. Fillette, Soda Cool ou Limonade seulement : « C'est trop sucré pour moi. » / « Je préfère l'eau. »
94. Fillette, après la CT : « Ça va mieux, merci. » / « Le toit, c'est joli, mais il y fait chaud. »

### A.5 Casino et restaurant (compléments)

95. Employé du guichet : « Désolé, toutes les machines sont arrêtées. » / « Fermé pour inventaire. »
96. Client 1 : « Je venais tous les jours. » / « Maintenant, je ne sais plus quoi faire de mes
    après-midi. »
97. Cliente 2 : « Ces machines ne m'ont jamais fait gagner. » / « Au moins, éteintes, elles ne me
    coûtent rien. »
98. Client 3 : « Le type devant l'affiche ne bouge pas d'un pouce. » / « Bizarre, non ? »
99. Client 4 : « Le patron vient rarement en salle. » / « Il a des bureaux ailleurs, paraît-il. »
100. Affiche, passage déjà ouvert : « Derrière l'affiche, l'interrupteur. » / « Le passage est
     ouvert. »

### A.6 Route 8, Dresseurs

101. Intello Anatole (D1), après : « La probabilité de te revoir est faible. » / « Mais pas nulle. »
102. Joueur René (D2), après : « Au Casino, on ne gagne jamais contre la maison. » / « Contre toi
     non plus, apparemment. »
103. Intello Firmin (D3), avant : « Mes Pokémon sont le résultat de longues expériences. »
104. D3, battu : « L'expérience a échoué. »
105. D3, après : « Je note tout dans mon carnet. Même mes défaites. »
106. Fillette Iris (D4), après : « On va s'entraîner encore. » / « Toutes les deux. »
107. Fillette Margot (D5), après : « Mes Miaouss ont trouvé une pièce dans l'herbe. » / « C'est
     toujours ça. »
108. Joueur Fernand (D6), avant : « Tu as l'air d'avoir de la chance. » / « Voyons si elle tient. »
109. D6, battu : « La chance a tourné. »
110. Fillette Nina (D7), avant : « Mes Mélofée dansent mieux qu'elles ne se battent. » / « Mais
     elles se battent quand même ! »
111. D7, battue : « Elles ont perdu en dansant… »
112. D7, après : « Lavanville est juste derrière. » / « Moi, je n'aime pas trop y aller. »

### A.7 Arène d'Erika

113. Fillette Lila (E1), battue : « Au moins, tu as été silencieux. »
114. E1, après : « Erika n'aime pas qu'on coure dans la serre. »
115. Fillette Capucine (E2), avant : « Tu as coupé l'arbuste ? » / « Erika va le remarquer. »
116. E2, battue : « Mes fleurs sont fanées… »
117. E2, après : « Ici, chaque plante a un nom. » / « Je les connais toutes. »
118. Beauté Violette (E3), avant : « L'élégance, c'est aussi savoir se défendre. »
119. E3, battue : « Perdre avec élégance, c'est déjà ça. »
120. E3, après : « Je viens ici pour le calme. » / « Et pour Erika, bien sûr. »
121. Jeune Dresseuse Apolline (E4), avant : « Mes Pokémon poussent aussi vite que les plantes de la
     serre ! »
122. E4, battue : « Il leur faut encore un peu de soleil. »
123. E4, après : « Le bassin, au fond, c'est l'endroit préféré d'Erika. »
124. Topdresseuse Camélia (E5), avant : « Personne ne réveille Erika sans passer par moi. »
125. E5, battue : « Bien. Tu as le droit de la déranger. »
126. Carte d'Erika : « ERIKA » / « Championne d'Arène de Céladopole »
127. Erika, quand le joueur perd : « Les plantes repoussent toujours. » / « Reviens quand tu seras
     prêt. »
128. Erika, nouvel essai : « Te revoilà. » / « Reprenons, sans nous presser. »
129. Erika, CT21 donnée plus tard (rattrapage) : « Attends. J'ai oublié de te donner ceci. »

### A.8 Repaire Rocket

130. Sbire B1F n° 1 (après T-45), battu : « Ton badge d'accès, tu l'as eu où ? »
131. B1F n° 1, après : « Je vais devoir faire un rapport. »
132. Sbire B1F n° 2, avant : « Cette zone est réservée au personnel. »
133. B1F n° 2, battu : « Mon chef ne va pas être content. »
134. B1F n° 2, après : « Je ne t'ai pas vu. » / « Toi non plus, d'ailleurs. »
135. Sbire B1F n° 3, avant : « Un livreur ? » / « Non… Tu n'as pas de colis. »
136. B1F n° 3, battu : « La logistique, ce n'est pas le combat. »
137. B1F n° 3, après : « Les caisses ne vont pas se ranger toutes seules. »
138. Sbire B2F, avant : « Tu t'es perdu ? » / « Moi aussi, ma première semaine. »
139. B2F, battu : « Au moins, les dalles, elles obéissent. »
140. Sbire B3F n° 1, avant : « Encore un étage, encore un intrus. » / « Les journées sont longues. »
141. B3F n° 1, battu : « Je vais demander une mutation. »
142. B3F n° 1, après : « Le patron est plus bas. » / « Il ne reçoit personne. »
143. Sbire B3F n° 2, avant : « Technicien de maintenance. » / « Je m'occupe aussi des intrus. »
144. B3F n° 2, battu : « Panne générale. »
145. B3F n° 2, après : « Ces machines coûtent une fortune. » / « Ne touche à rien. »
146. Sbire à la Clé, avant : « La Clé Ascenseur ne quitte jamais ma poche. » / « Jamais. »
147. Sbire à la Clé, après l'avoir laissée tomber : « Si on te demande, tu l'as trouvée par terre. »
148. Garde n° 2, avant : « Personne ne passe cette porte sans rendez-vous. »
149. Garde n° 1, battu : « … Je ne suis plus vraiment de garde. »
150. Garde n° 1, après : « Le patron n'aime pas être dérangé. » / « Tu vas l'apprendre. »
151. Garde n° 2, battu : « La porte… Tant pis. »
152. Garde n° 2, après : « Je n'ai rien vu. » / « C'est mieux pour tout le monde. »
153. Porte du bureau, fermée (examiner) : « La porte est verrouillée. »
154. Carte de Giovanni : « GIOVANNI » / « Chef de la Team Rocket »
155. Giovanni, quand le joueur perd : « Rentre chez toi. » / « Et oublie ce que tu as vu ici. »
156. Giovanni, nouvel essai : « Encore toi. » / « Soit. »
157. Panneau d'étages, carte de l'étage courant (grisée) : « Vous êtes ici »

### A.9 Interface et combat

158. Panneau d'étages, titre : « Quel étage ? »
159. Panneau d'étages, bouton : « FERMER »
160. Boutique, CT déjà au Sac : « Déjà dans le Sac »
161. Combat, Poupée Poké : « {player} lance la Poupée Poké. » / « Le Pokémon sauvage s'en
     désintéresse : tu t'éclipses ! »
162. Combat, Poupée Poké contre un Dresseur : texte de refus existant (« Impossible contre un
     Dresseur. ») — rien de nouveau si le texte existe déjà au T11.
163. Combat, objet X : « {player} utilise {item} ! » puis le message d'étage existant.
164. Combat et Sac, Rappel : « {pokemon} reprend connaissance ! »
165. Sac, Rappel sur un Pokémon debout : texte « aucun effet » existant.
166. Rappel, liste d'équipe (combat et Sac), Pokémon debout : « Pas K.O. »

### A.10 Zones (Carte, Pokédex) et Grands moments

167. Route 8 — sous-titre « Lavanville — Safrania » ; « Une route de Dresseurs entre deux chemins.
     À l'ouest, le poste de Safrania et l'entrée du souterrain. »
168. Passage souterrain (Routes 7 et 8) — sous-titre « Route 7 — Route 8 » ; « Un long couloir
     carrelé sous Safrania. Des néons froids, et presque personne. »
169. Route 7 — sous-titre « Céladopole — Safrania » ; « Une courte route en pente douce. Les toits
     de Céladopole apparaissent entre les arbres. »
170. Céladopole — « Une ville prospère, verte et commerçante. Sous les néons du Casino, l'ambiance
     n'est plus la même. »
171. Grand moment, arrivée : « Arrivée à Céladopole » / « La ville des fleurs et du commerce. »
172. Grand moment, Giovanni : « Le repaire sous le Casino » / « Giovanni est parti. Le Scope Sylphe
     est à toi. »

### A.11 Objets (descriptions du Sac)

173. Super Ball : « Une Ball plus efficace que la Poké Ball. »
174. Rappel : « Ranime un Pokémon K.O. et lui rend la moitié de ses PV. »
175. Poupée Poké : « Distrait un Pokémon sauvage pour fuir à coup sûr. »
176. Pierre Feu : « Une pierre chaude au toucher. Fait évoluer certains Pokémon. »
177. Pierre Eau : « Une pierre bleue et limpide. Fait évoluer certains Pokémon. »
178. Pierre Foudre : « Une pierre qui crépite. Fait évoluer certains Pokémon. »
179. Pierre Plante : « Une pierre veinée de vert. Fait évoluer certains Pokémon. »
180. Eau Fraîche : « Une eau minérale bien fraîche. Rend 50 PV. »
181. Soda Cool : « Une boisson pétillante. Rend 60 PV. »
182. Limonade : « Une limonade très sucrée. Rend 80 PV. »
183. Attaque + : « Augmente l'Attaque d'un Pokémon pendant un combat. »
184. Défense + : « Augmente la Défense d'un Pokémon pendant un combat. »
185. Vitesse + : « Augmente la Vitesse d'un Pokémon pendant un combat. »
186. Spécial + : « Augmente l'Attaque Spéciale d'un Pokémon pendant un combat. »
187. Précision + : « Augmente la précision d'un Pokémon pendant un combat. »
188. Muscle + : « Augmente les chances de coup critique pendant un combat. »
189. Clé Ascenseur : « La clé de l'ascenseur du repaire de la Team Rocket. »
190. Scope Sylphe : « Il permet de voir ce que l'œil seul ne voit pas. » (2e ligne de T-55)

### A.12 Pokédex (une phrase d'observation, sans chiffre)

191. Caninos : « Fidèle et vif, il aboie dès qu'un inconnu approche de son territoire, puis se
     calme si son Dresseur le rassure. »
192. Arcanin : « Il court si vite qu'on ne voit passer qu'une traînée de feu. Les anciens le
     croyaient sorti d'une légende. »
193. Goupix : « Ses queues bouclées s'étoffent à mesure qu'il grandit. On l'aperçoit au crépuscule,
     près des clairières sèches. »
194. Feunard : « Ses longues queues brillent d'une lueur dorée. On raconte qu'il n'oublie jamais
     qui lui a manqué de respect. »
195. Évoli : « Son corps change au contact de certaines pierres. On ne le croise presque jamais
     dans la nature. »
196. Aquali : « Dans l'eau, il se fond au point de devenir invisible. Les jours de pluie, on
     l'entend chanter au bord des étangs. »
197. Voltali : « Son poil se hérisse en aiguilles quand l'air se charge d'électricité. Il crépite
     dès qu'on le surprend. »
198. Pyroli : « Il garde dans son corps une chaleur intense, qu'il rejette en soufflant. Son poil
     gonfle quand il se réchauffe. »
199. Empiflor : « Il attend, immobile dans le feuillage, qu'une proie s'approche de sa grande
     bouche. Un parfum sucré flotte autour de lui. »
200. Saquedeneu : « Ses lianes bleues s'agitent sans cesse et cachent tout son corps. Personne ne
     sait vraiment ce qu'il y a dessous. »
201. Rafflesia : « Ses larges pétales libèrent un pollen lourd qui pique les yeux. Il secoue sa
     fleur pour le répandre alentour. »
202. Rhinocorne : « Il fonce droit devant lui sans réfléchir et ne s'arrête qu'une fois l'obstacle
     renversé. »
203. Kangourex : « Elle ne quitte jamais le petit qu'elle porte dans sa poche, et le défend avec une
     force redoutable. »
204. Osselait : « Il porte le crâne de sa mère comme un casque. Les nuits de lune, on l'entend
     pleurer doucement. »

### A.13 Capacités et CT (descriptions)

205. Méga-Sangsue (et CT21) : « Aspire l'énergie de la cible. Rend au lanceur la moitié des dégâts
     infligés. »
206. Constriction : « Serre la cible avec des lianes. Peut baisser sa Vitesse. »
207. Poing Comète : « Une volée de coups de poing, de deux à cinq fois. »
208. Écrasement : « Écrase la cible d'un pied lourd. Peut l'apeurer. »
209. Uppercut : « Un coup de poing qui monte. Peut rendre la cible confuse. »
210. Acidarmure : « Le corps se liquéfie et devient plus dur à frapper. Augmente beaucoup la
     Défense. »
211. Bélier : « Une charge brutale qui blesse aussi le lanceur. Sans effet dans le moteur actuel. »
212. Brume : « Un voile blanc qui protège des baisses de statistiques. Sans effet dans le moteur
     actuel. »
213. Hurlement (si le J17 ne l'a pas créée) : « Un cri qui fait fuir la cible. Sans effet dans le
     moteur actuel. »
214. CT13 — Laser Glace : description de la capacité `ice_beam` existante (aucun texte nouveau).

### A.14 Postes de Safrania (ajout du 2026-10-19, **VALIDÉ par Kevin le 2026-10-19**, §2.16)

> Répliques des gardes des Routes 7 et 8 quand la zone de Safrania est jouable (J26). Avant, le
> texte 12 (validé) ne change pas. Les gardes du J15 (Routes 5 et 6) reprennent 216 à 219.

215. Garde, après la boisson : « Merci encore pour la boisson. » / « Allez-y, Safrania vous attend. »
216. Garde, soif : « Je monte la garde depuis ce matin, sous ce soleil… » / « J'ai une de ces soifs. »
217. Choix : « Lui donner une boisson ? » (Oui / Non)
218. Refus : « Tant pis… Je tiendrai bien encore un peu. »
219. Boisson donnée : « [Joueur] donne un(e) [boisson] au garde. » / « Ah, ça fait du bien ! » /
     « Pour la peine, je vous laisse passer. Bonne visite de Safrania ! »
