# Jalon 13 — Route 4, Azuria, Ondine et le Pont Pépite

> Objectif jouable sur le téléphone : **la deuxième grande boucle**. Le sas du J12 devient une
> vraie **Route 4** (plateau, rebord à sens unique vers le sud, plaine d'entraînement, une Jeune
> Dresseuse, une Poké Ball) qui mène à **Azuria** : ville claire à canaux en L, trois ponts, Centre
> sur l'avenue d'arrivée, Boutique (mode VENDRE), magasin de vélos, maison ouverte, maison
> cambriolée gardée et fermée, Arène-piscine ouverte dès l'arrivée (deux Dresseurs). Au nord, la
> **Route 24** : le **rival n° 3**, au pied du Pont Pépite, inévitable et **à battre**, rejouable,
> un seul Grand moment ; **Ondine** qui l'a regardé et invite le joueur ; l'Arène, le **Badge
> Cascade** et la **CT11 Bulles d'O** ; le **Pont Pépite** (cinq Dresseurs inévitables), le
> **recruteur** (Pépite, choix sans branche, combat) et le petit espace nord (herbes, un objet
> visible, un objet caché, « ROUTE 25 — À venir »).
>
> Mécaniques nouvelles : **IA qui change de Pokémon** (une fois au plus, Ondine et le rival) ;
> **Grand moment du rival à la victoire seulement**, sans doublon ; **enchaînement de deux scènes
> avec sauvegarde entre elles** ; **choix qui pose un drapeau** dans une scène ; **eau de canal**
> (rivage existant, texture réglable). **Format de sauvegarde inchangé** (v6), preuve au §2.19.

**Pré-requis.** Dossier 16 **verrouillé** (2026-10-11 : V-1…V-9, C-1…C-8, D-1…D-16, textes §21,
défauts §22) : c'est la **source de vérité**, avec la passe `docs/design/passes/j13-v2-alignement.md`.
**D-16** : le code du J13 part **après la clôture du J12** (elle-même après celle du J11) ; la
conception, les grilles, les vues générales, l'art et, si Kevin l'accepte (**Q-1**), les **cartes
sans combat** peuvent avancer avant (§1.2).

Plan écrit sur `docs/plan-j13` (depuis `6ad5db6`). **Code lu** : `origin/main` à **`906566a`**
(J10 terminé, ouverture terminée, **J11 11.0 fusionné : sauvegarde v6 sur `main`**) ; le J11 **lu,
pas modifié**, sur `origin/claude/lancement-j11-4pkt2k` à **`ca235a1`** (11A validé ; 11B : T11 CT,
T12 Sac CT, T13 Patience, T14 CT34 de Pierre faits) ; le J12 **lu, pas modifié**, sur `jalon-12` à
**`1ea38d7`** (T1 kit série 14, T2 génération, T4 décors de combat, T7 fondations, T10 simulation ;
T3 en cours sur `j12-t3-planches` ; **T6, T8, T9 et tout le code après le J11 restent à faire**).
Les grilles du J13 sont produites **en parallèle** sur `j13-grilles` (rien n'y est encore commité
au-delà du dossier) : ce plan les cite par leur nom, jamais par leurs coordonnées, sauf le sas du J12
(`tools/plans/route_4_sas.txt`, validé). **Chaque tâche d'architecture commence par aligner ce plan
sur le code du moment** ; la première tâche après le J12 (T10) le réaligne sur le J11 et le J12
réellement fusionnés.

Références : `CLAUDE.md` (règles 1 à 10), `dossier-16-azuria.md`, `dossier-05-combat.md` (§14
changement, §19 IA progressive), `dossier-06-progression.md` (§3 leçon d'Ondine, §6 Rattata du
rival), `dossier-09-jadielle.md` (§13–15 rival : IA de niveau 2, états en mémoire, exception du J13),
`dossier-12-argenta.md` (Arène, badge, CT « J'allais oublier. »), `dossier-15-route-3-mont-selenite.md`
(§14 sas, Sbire, choix), `dossier-14-systemes-j11.md` et `jalon-11.md` (branche du J11 : CT,
statuts, compagnon), `jalon-12.md` (méthode, briques du monde, simulation), `roadmap.md` (rival n° 3,
Grands moments précisés le 2026-10-11).

> Téléphone de validation : le **S21** depuis le 2026-10-10 (décision de Kevin) ; « session S24 »
> désigne la session téléphone du sous-jalon, quel que soit l'appareil.

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe pour chaque besoin du dossier, et ce que le J11 et le J12 apportent

Chemins:lignes sur `origin/main` à `906566a` sauf mention. « J11 » = branche du J11 (fait ou
planifié dans `jalon-11.md`) ; « J12 » = planifié dans `jalon-12.md` (fait seulement si dit).

| Besoin (dossier 16) | Existe sur `main` | Prévu J11 | Prévu J12 | À créer au J13 |
|---|---|---|---|---|
| Combats de Dresseur, équipe du rival | `TrainerData` (`team_by_starter` `trainer_data.gd:40`, `team_for`, `prize_per_level`, `card_name` l. 43, `make_ai` l. 74) ; `data/trainers/rival.json` (`rival_lab` l. 2, `rival_route22` l. 12, `team_by_starter` l. 6 et 17 ; IA `smart`, 35 ₽ × niveau) ; clés reconnues `trainer_library.gd:33` | — | — | `rival_cerulean` (Roucoups 18, Rattata 15, starter évolué 17) ; clés `switch` et `moment` (§2.7, §2.11) |
| Combat rejouable jusqu'à la victoire | modèle de Pierre : `data/cutscenes/pewter_gym.json` (variante `unless badge_boulder`, `brock_met` évite l'introduction, défaite → `_lost` puis `wake_up`) ; rival n° 2 : scène sur déclencheur `data/cutscenes/route_22.json` (`rival_route22_won` / `_lost`, approche `move near`, départ `move` + `despawn`) ; `EventTriggerPoint` (`event_trigger_point.gd:12-17` : `cutscene_id`, `size`, `direction`) | — | `lost_<id>`, `rematch`, `leave` dans le bloc `trainer` des PNJ (T17) | rien de neuf pour la reprise ; **sauvegarde entre la victoire et la scène d'Ondine** (§2.9) |
| Grand moment `rival_battle` | `Boot._on_battle_finished` (`boot.gd:1195`) : tout Dresseur à `team_by_starter` enregistre un moment **à chaque combat**, victoire comme défaite (l. 1201) ; `GameState.record_moment` (`game_state.gd:185`) **sans contrôle de doublon** ; `has_moment(type)` (l. 194) ; textes `data/trainer/moments.json:7` (`{outcome}`) | `boot.gd` modifié (statuts, CT) | `boot.gd` modifié ; étape `moment` + type `fossil` (T23) | **victoire seule** pour le rival n° 3 et **jamais deux fois par Dresseur** (§2.8) |
| Vue des Dresseurs, `beaten_<id>` | `TrainerEncounter.build` (`trainer_encounter.gd:38` ; `win_flags = [beaten_<id>]` l. 68 ; réplique « vaincu »/« après » ; `wake_up` sinon) ; `TrainerRules.beaten_flag` (`trainer_rules.gd:22`), `sight_distance` (l. 35) ; `TrainerWatcher` | — | `rematch`, `leave` (T17) | rien : P1–P5, Clara, Lucas, Diane = blocs `trainer` ordinaires |
| Défaite → dernier Centre | `DefeatRecovery.recover` (`defeat_recovery.gd:46`) ; aucun argent perdu ; étape `wake_up` | — | — | rien (D-2 : règle inchangée) |
| IA | `BattleAI` (`battle_ai.gd:26` `KINDS = [random, smart]`, `choose` l. 53, `score_move` l. 80) ; **aucune IA ne change de Pokémon** ; l'adversaire choisit dans `Battle.submit` (`battle.gd:271`) et `_foe_turn_alone` (l. 371) ; changement **du joueur** : `BattleAction.switch_to` (`battle_action.gd:64`), `Battle._switch` (l. 353 : WITHDRAWN, SENT_OUT, puis l'adversaire joue) ; `_send_out` (l. 613) | `_foe_action()` (Patience imposée sans tirage), `can_act`, statuts au changement (confusion perdue, sommeil gardé) ; **IA qui change reportée (A-4)** | IA `smart` : Repos, Entrave, Ligotage, Destruction (T13) ; piège = changement interdit | **`AiSwitchRule`** (pur) + `BattleAI.can_switch` + exécution du changement adverse (§2.11) |
| Rappel adverse à l'écran | `WITHDRAWN` (`battle_event.gd:87`) seulement pour le joueur ; texte `withdrawn` « Reviens, {pokemon} ! » (`messages.json:60`, `battle_text.gd:276`) ; `BattleStage.play_withdraw(side)` **générique** (`battle/battle_stage.gd:652`) | — | — | texte `withdrawn_foe` (§21 n° 60), WITHDRAW côté adverse (§2.11) |
| Badge | `data/badges.json:5` (`cascade`, `badge_cascade`, Ondine, Azuria) ; étape `badge` (`cutscene_director.gd:569` : drapeau, légende, vibration, Grand moment une fois par badge l. 575) ; carte de Champion `ChampionCard` (**sans portrait**, `champion_card.gd:6`) | — | — | données seules |
| CT | rien sur `main` (`item_data.gd:20` : 5 catégories) | **fait sur la branche** : catégorie `tm`, `teaches`, `TmTeach`, onglet CT, toast « CT34 — Patience / obtenue », remise de Pierre + rattrapage `pewter_gym_brock_tm_late` (T11–T14) ; `tm_compatibility.json` (`"11": "bubble_beam"`) | CT01, compatibilités régénérées pour 50 espèces (T12) | `tm11`, compatibilités pour 59 espèces (§2.15) |
| Vente, Pépite | `ShopRules.sell` (`shop_rules.gd:97`) ; `ItemData.is_sellable` / `sell_price` = ⌊prix / 2⌋ (`item_data.gd:126`, `:132`) | `is_sellable` faux pour les CT | catégorie AVENTURE utilisée (Corde, Pierre Lune), `field_use` (T20) | `nugget` (AVENTURE, 10 000 ₽, **sans** `field_use`) |
| Objets au sol, `got_<id>` | PNJ `object/poke_ball_ground` + `give … found` + `set got_<id>` ; `found_items` = journal (`game_state.gd:180`) | — | objets cachés « face à un indice » (`unless_flags`, T17) | données seules |
| Objectifs | `ObjectiveLibrary.current` (`objective_library.gd:58`, première entrée valide) ; `data/story/objectives.json` (`go_route_3` en tête) | — | `go_cerulean` (`if route_4_reached`), `cross_mt_moon` (T18, T28) | 3 entrées en tête (§2.16) |
| « À venir » | `Warp.coming_soon` (`warp.gd:31`), `WarpPoint.coming_soon` ; `SceneRouter.show_coming_soon` (`scene_router.gd:180`, développement seulement) | — | raccord est du sas « AZURIA — À venir » ; `test_coming_soon` déplacé sur le sas (T8) | raccord est de la Route 24 « ROUTE 25 — À venir » ; `test_coming_soon` déplacé |
| Sauvegarde | **v6** (`save_system.gd:35` ; règle d'incrément l. 22) | v6 (statuts, `uid`, compagnon) | **aucune version nouvelle** (§2.20 du J12) | **aucune version nouvelle** (§2.19) |
| Rencontres | `data/encounters/*.json` (format `maps`, `terrain: grass`, `rate`, `ramp`, `slots`) | — | terrain `rubble` | `route_4.json`, `route_24.json` (herbes) |
| Zones, carte | `data/world/zones.json` : `route_4` (l. 58) et `cerulean_city` (l. 59) **déclarées sans carte** ; **`route_24` absente** ; `assets/ui/map/kanto_placeholder_areas.json:15` (Azuria) ; `assets/ui/pokedex/scenes.json` (Azuria « village », Route 4 « prairie ») | — | `route_4` = sas (T8), sous-titre et description (annexe A du J12) | zone `route_24` (zones, aire de la carte, scène de Pokédex), cartes d'Azuria |
| Eau | `PaintedGround.shore_mask` (`painted_ground.gd:31`) + `ground_blend.gdshader:22-26` (sable, **eau qui ondule par `TIME`**, écume ; aucune lecture d'écran) ; `OverworldTiles.Kind.WATER`, `BOARDWALK` (ponton) ; `GridWorld.is_water` (`grid_world.gd:73`) ; Bourg Palette (mer) | compagnon : phrase « eau à ≤ 2 cases » | `PaintedGround` : textures du sol réglables (`base/r/g_texture`, T7 **fait**) | **texture d'eau réglable**, écume réglable (§2.3) |
| Décors de combat | `data/battle/decors.json` (un décor, `route_1_chemin`) ; `BattleDecorCatalog.pick(map, cell)` ; repli = carte floutée | — | 3 décors (T4 **fait**) | `route_4_plaine`, `route_24_pont`, `cerulean_gym_bassin` |
| Intérieurs | `tools/build_painted_interiors.gd` : `_pokemon_center` (l. 132), `_poke_mart` (l. 189), maison `_pewter_house` (l. 593), Arène de Pierre `_pewter_gym` (l. 565) ; `data/world/interiors.json` | — | `mt_moon_center` (T8) | Centre, Boutique (enveloppes), **Arène-piscine**, **magasin de vélos**, maison (§2.5) |
| Personnages peints | 26 modèles (`tools/build_character_frames.gd:47-90`) : `lass` (Jeune Dresseuse), `youngster`, `scout`, `camper`, `guard`, `gym_guide`, `nurse`, `clerk`, `kid`, `old_man`, `traveler`, `hiker`… | 5 planches du compagnon (série 13) | Fillette, Sbire ♂ / ♀, chercheur (série 14, générés, **non intégrés**, T6) | **Ondine**, **Nageur** (série 15) |
| Espèces, capacités | **38 espèces** (`kanto.json`), **66 capacités** (`moves.json`) ; artworks 001–151 ; dos provisoires (`gen_placeholder_battlers.gd`) | `bide` (67) ; effets `status`, `confusion`, `hits`, `flinch`, `fixed_damage` | 12 espèces (50), 21 capacités dont **`acid`** et `wrap` ; effets `drain`, `trap`… (T12, T13) | **9 espèces** (59) ; **8 capacités** dont `bubble_beam`, `absorb` (§2.15) |
| Choix dans un dialogue | `DialogueChoice.confirm_action` (`dialogue_choice.gd:25` : soins, Boutique, Stockage) | — | `confirm_cutscene` (T23) | **`confirm_set` / `cancel_set`** (drapeau posé par le choix, §2.13) |
| Prénom du joueur | jeton `{player}` (OUV.2, `boot.gd:245`) | — | — | rien (§21 n° 49) |
| Compagnon | rien sur `main` | `CompanionRules`, `companions.json` (`contexts` carte → phrase), masqué sans case libre, rentre en intérieur | contexte `cave` | contexte `city` pour Azuria (données) |
| Simulation | `tools/simulate_brock.gd` | — | `tools/simulate_mt_moon.gd` piloté par un **scénario JSON** (`--scenario`, T10 **fait**) | `tools/sim/cerulean_scenario.json` (§2.22) |

### 0.2 Écarts et trous constatés

1. **Grand moment sans doublon** (dossier §7.4, D-5) : `boot.gd:1195` écrit un moment à chaque fin de combat contre un Dresseur à `team_by_starter`. Un combat rejouable en écrirait un par défaite. Correction §2.8 (règle pure + donnée `moment: "win"`).
2. **Partie quittée entre la victoire et la scène d'Ondine** (§8 reprise, §19) : l'autosave n'écrit jamais pendant une scène (`Boot.is_stable`, `boot.gd:629`) ; une scène unique « combat + départ + Ondine » perdrait la victoire à la fermeture et rejouerait le combat, contrairement au §19 (« `rival_cerulean_won` est déjà levé »). Il faut **deux scènes** et une **sauvegarde entre les deux** (§2.9).
3. **Recruteur : « Oui » comme « Non » mènent au même combat** avec deux répliques. Le `confirm_cutscene` du J12 lance une **autre** scène depuis un dialogue d'exploration ; ici le choix est **au milieu** d'une scène qui continue. Défaut : le choix **pose un drapeau** (`confirm_set` / `cancel_set`), les étapes suivantes s'en servent (§2.13).
4. **Capacités** : le dossier §15.2 compte 3 capacités nouvelles. Avec la convention du J12 (« apprentissages de Rouge/Bleu, **tous niveaux** » ; un learnset ne cite qu'une capacité connue, `PokemonData`), il en faut **8** : Bulles d'O, Vol-Vie, **Soin** (Stari 27), **Claquoir** (Kokiyas 23), **Onde Boréale** (Kokiyas 30), **Laser Glace** (Kokiyas 50), **Cascade** (Poissirène 37), **Danse Fleur** (Mystherbe 33, Ortide 38). Aucune des 6 dernières n'est atteignable au J13 (Dresseurs à Nv. ≤ 21, sauvages ≤ 14). Défaut §2.15 ; textes à l'annexe A.
5. **Acide** : le dossier 16 écrit « Défense −1 » ; le J12 l'ajoute (T12) en **Déf. Spé. −1** (G+), texte validé « Peut baisser sa Défense Spéciale. » (annexe A du J12). Défaut : **la donnée du J12 fait foi** (validée la première) ; aucun changement au J13.
6. **Portrait d'Ondine** (dossier §15.3 « planche + portrait de carte ») : la carte de Champion n'a **aucun portrait** (J10, `champion_card.gd:6`) et aucun écran n'en affiche hors de l'ouverture. → **Q-2**.
7. **H5 « nageuse »** : le seul modèle de nageur prévu est masculin (Nageur Lucas). Défaut : H5 garde un modèle existant (Jeune Dresseuse `lass`, sans maillot) ; une Nageuse peinte est un **conditionnel** du kit (§1.4).
8. **Habitants et personnages nommés** : `haru` (pêcheur), `aoki`, `maya`, `leo` sont des habitants **nommés** d'autres villes ; les reprendre pour H1/H3 ferait croire au même personnage. Règle du kit : aucun modèle de personnage nommé pour un habitant d'Azuria.
9. **Sas → Route 4** (passation du J12, `jalon-12.md` §0.2 n° 15) : la Route 4 doit **contenir le sas à l'origine** (colonnes 0–23, rangées 0–13) pour que toute position sauvegardée dans le sas reste praticable ; `route_4_reached` (4, 5..9) et `from_mt_moon` (3, 6) restent ; le raccord est (23, 6..7) devient du chemin ; la rangée « vue sur la plaine » (12–13) peut devenir le rebord (grille).
10. **Mémoire de la Route 4** : le sas précharge B2F (une grotte n'est pas un intérieur, règle du J12) ; la Route 4 précharge en plus Azuria (≈ 56 × 46). À mesurer (§2.20).
11. **Pont de 2 cases et vue des Dresseurs** : une vue est une ligne ; sur un pont de 2 cases, un Dresseur qui regarde le long du pont laisse la seconde colonne libre. « Inévitable » se règle à la grille (Dresseur qui occupe une colonne et **regarde l'autre**, ou vue qui couvre les deux) et se vérifie par `plan_check` puis sur la vraie scène. Le compagnon y est masqué au passage (goulet d'une case, règle du J11).
12. **Rafflesia / Empiflor** : pas de données (dossier §15.1) ; Ortide et Boustiflor **n'ont pas** d'évolution déclarée (`evolutions: []`).
13. **Sorties fermées** (est, sud) : **matérielles, sans warp ni « À venir »** (dossier §4.2). La passe du J14 attend plus tard un raccord « ROUTE 5 — À venir » au sud : **hors J13**, noté pour la passation.

### 0.3 Ce que le J13 attend du J11 et du J12 (et repli)

| Livraison | Pour | Si elle manque ou diffère |
|---|---|---|
| J11 11A : statuts, confusion, Antigel / Anti-Brûle / Anti-Para / Réveil | Ultrason (Poissirène, Kokiyas), poudres ; stock de la Boutique | bloquant (le J12 l'est aussi) |
| J11 11B : CT (`tm`, `TmTeach`, onglet, toast « obtenue », modèle `pewter_gym_brock_tm_late`) | CT11, rattrapage | **fait sur la branche** ; si 11B change, T10 réaligne |
| J11 : statuts au changement (confusion perdue, sommeil gardé), Patience imposée | IA qui change | règles reprises telles quelles |
| J11 11D : compagnon, `contexts` | phrase « ville » à Azuria, suivi sur quais et ponts | le J13 se passe du compagnon (critères retirés) |
| J12 T8 : carte `route_4` (sas), `build_route_4.gd` | remplacement par la Route 4 | T8 du J13 attend la T8 du J12 dans `jalon-12` |
| J12 T12 : Abo, Nosferapti, Paras, Rondoudou, Sabelette… (50 espèces), `acid`, `wrap` | Clara, recruteur, rencontres, Chétiflor | bloquant pour les données (T11) |
| J12 T13 : `drain`, `trap` (messages par capacité) | Vol-Vie, Claquoir | Vol-Vie sans drain = `pending_effects` (repli) |
| J12 T17 : objets cachés (`unless_flags`), `rematch`, `leave` | Antidote caché de la Route 24 | objet caché « sur la case » (J5) en repli |
| J12 T20 / T24 : AVENTURE, `field_use`, UTILISER seulement si `field_use` | Pépite sans UTILISER | ajouter la condition au T16 |
| J12 T23 : `confirm_cutscene`, étape `moment` | modèle du choix (clé sœur `confirm_set`) | — |
| J12 T6 : intégration de la série 14 (Sbire ♂ peint, indices) | recruteur, objet caché | Sbire provisoire (aucune validation de rendu au J13) |
| J12 T10 : `simulate_mt_moon.gd` | équilibrage du rival et d'Ondine | estimation du §2.22 seulement |

---

## 1. Découpage

### 1.1 Sous-jalons et validations (D-16)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **13.0-art** | grilles et vues générales (préalables, hors de ce plan) ; kit série 15 (Azuria, Route 24, Arène, vélos, Ondine, Nageur), décors de combat, icône Pépite | **Kevin, sur planches de contact** |
| **13.0** | données : 9 espèces, 8 capacités, Pokédex, Pépite, CT11, compatibilités ; **IA qui change de Pokémon** ; carte de QA `qa_switch_j13` | **S24** (combats de test) |
| **13A** | Route 4 (remplace le sas : rebord, herbes, Clara, Poké Ball), Azuria (extérieur, eau, Centre, Boutique et vente, vélos, maison, maison cambriolée et indices), Dresseurs de l'Arène (Lucas, Diane), guide « avant l'invitation » | **S24** (+ reprise d'une partie sauvegardée dans le sas) |
| **13B** | rival n° 3 (rejouable, Grand moment unique), scène d'Ondine au pont (et sa reprise), Ondine à l'Arène, Badge Cascade, CT11 et rattrapage | **S24** |
| **13C** | Pont Pépite, recruteur, Pépite, Route 24 nord (herbes, objet visible, objet caché, « ROUTE 25 — À venir »), objectifs, retrait de la carte de QA ; **QA finale** sas → Azuria → badge et pont en vraie partie | **S24** + fusion |

- **Jamais trois systèmes à la fois** : 13.0 = un système (IA qui change) + des données ; 13A = du contenu sur des systèmes existants (eau = rivage existant) ; 13B = deux briques (moment unique, scènes enchaînées) ; 13C = une brique (choix qui pose un drapeau) + contenu.
- **Aucune validation de sauvegarde isolée** : format inchangé (§2.19) ; la reprise depuis le sas est un critère de 13A, celle de la scène d'Ondine un critère de 13B.

### 1.2 « Maintenant » ou « après la clôture du J12 »

**Fichiers que le J11 ou le J12 modifient ou vont modifier** — à ne pas toucher avant la clôture du
J12 : toute la liste du §1.2 de `jalon-12.md` (moteur de combat, `game/pokemon/*`, `game/items/*`,
menus, Sac, `game_state.gd`, `scene_router.gd`, `boot.gd`, `save_system.gd`, `grid_world.gd`,
`player.gd`, `npc.gd`, `interaction_*`, `cutscene_*`, `evolution/*`, `moves.json`, `messages.json`,
`items.json`, `shops/*`, `tm_compatibility.json`, `companions.json`…) **plus** ce que le J12 y
ajoute : `kanto.json`, `pokedex/kanto.json`, `trainers/*`, `npcs/*`, `dialogues/*`, `cutscenes/*`,
`encounters/*`, `objectives.json`, `moments.json`, `moment_library.gd`, `dialogue_choice.gd`,
`dialogue_library.gd`, `dialogue_runner.gd`, `npc_spec.gd`, `npc_roster.gd`, `trainer_encounter.gd`,
`interact_point.gd`, `gen_placeholder_battlers.gd`, `tools/debug_start/*` ; et, côté cartes, ce que
la T8/T9 du J12 touche : `build_route_4.gd`, `build_pewter_city.gd`, `build_painted_interiors.gd`,
`zones.json`, `interiors.json`, `rest_points.json`, `lighting.json`, `decors.json`, `test_map_links`,
`test_coming_soon`, `test_route_4`.

**Règles pour les tâches « maintenant »** (si **Q-1** est accepté) : branche d'intégration
**`jalon-13` créée depuis `jalon-12`** (pas depuis `main` : la Route 4 remplace la carte du sas que
le J12 construit, et le J13 réutilise ses outils et son art) dans une copie dédiée (mémoire
« worktree d'intégration ») ; une branche par tâche (`j13-t<n>-<sujet>`) ; **jamais fusionnée dans
`main` avant la fin du J13** ; `jalon-12` fusionnée **dans** `jalon-13` aussi souvent que possible
(jamais l'inverse) ; fichiers **nouveaux** de préférence ; ajouts aux fichiers partagés **en fin de
fichier** (manifeste, catalogue, looks, règles de décor, catalogues de cartes : « garder les deux
côtés ») ; **aucune donnée qui nomme une espèce, une capacité ou un objet absents** (les tests de
données les refuseraient) ; aucune tâche « carte » avant que la tâche correspondante du J12 soit
dans `jalon-12`. À la clôture du J12 : fusion de `main` dans `jalon-13` (T10).

| Tâche | Agent | Quand | Dépendances J11 / J12 | Pourquoi / comment éviter les conflits |
|---|---|---|---|---|
| T0 Plan (ce document) | architecte | **fait** | — | docs |
| T1 Kit d'assets série 15 | architecte | **maintenant**, après grilles et vues générales validées | J12 T1 (méthode) | fichiers nouveaux (`serie15.py`, fiche, prompts) |
| T2 Génération Codex → 13.0-art | constructeur-monde (Mac) | **maintenant**, après T1 | — | images dans `build/art/` |
| T3 Décors de combat (3) → 13.0-art | constructeur-monde (Mac) | **maintenant** | J12 T4 (chaîne CB.3) | prompts nouveaux sous `tools/art/combat_decors/` |
| T4 Textes de l'annexe A → Kevin | Kevin | **maintenant** | — | docs |
| T5 Intégration de la série 15 | constructeur-monde (Mac) | **maintenant**, après T2 **et J12 T6** | J12 T6 | entrées en fin de fichier |
| T6 Fondations : eau réglable, kit de canaux | architecte | **maintenant** | J12 T7 (fait) | `painted_ground.gd`, `ground_blend.gdshader` : touchés par la seule T7 du J12, déjà fusionnée |
| T7 Cartes Azuria + intérieurs (sans PNJ) | constructeur-monde | **maintenant**, après T5, T6 et **J12 T8** | J12 T8 | outils et scènes nouveaux ; catalogues en fin |
| T8 Cartes Route 4 et Route 24 (sans PNJ) | constructeur-monde | **maintenant**, après T5, T6 et **J12 T8** | J12 T8 (`build_route_4.gd`, sas) | Route 4 = réécriture de l'outil du sas, après lui |
| T9 Scénario de simulation | architecte | **maintenant** | J12 T10 (fait) | `tools/sim/cerulean_scenario.json` (nouveau) |
| T10 et suivantes | — | **après la clôture du J12** | J11 + J12 dans `main` | moteur, données, vie des cartes |

**Parallélisme maintenant** : T1 → T2 → T5 ; T3 ∥ T6 ∥ T9 ; T7 ∥ T8 après T5, T6 et la T8 du J12.
Après le J12 : T10 → T11 → T12 → T13 → T14 → **T15 (13.0)** → … (§3).

### 1.3 Cartes, grilles et raccords

Les grilles font foi (règle 10) ; ce plan **ne fixe aucune coordonnée** (sauf le sas). Elles
viennent de `j13-grilles` : `tools/plans/route_4.txt`, `azuria.txt`, `route_24.txt`,
`azuria_arene.txt`, `azuria_velos.txt`, `azuria_maison.txt` (avec leurs `plan_check`). Le Centre et la
Boutique reprennent les enveloppes du J10 (pas de grille).

| Carte | Taille | Catégorie | Lumière | `display_name` / `region` (titre) |
|---|---|---|---|---|
| `route_4` | ≈ 64 × 24 (grille ; **contient le sas en (0,0)–(23,13)**) | extérieur | `golden_hour` | « Route 4 » / « Mont Sélénite — Azuria » (J12, inchangé) |
| `cerulean_city` | ≈ 56 × 46 (grille) | extérieur | `golden_hour` | « Azuria » / « La ville aux eaux claires » (§21 n° 5) |
| `cerulean_center` | enveloppe `_pokemon_center` | intérieur | `interior_warm` | « Azuria » |
| `cerulean_mart` | enveloppe `_poke_mart` | intérieur | `interior_warm` | « Azuria » |
| `cerulean_gym` | ≈ 17 × 13 (grille `azuria_arene.txt`) | intérieur | `interior_warm` [D] | « Azuria » |
| `cerulean_bike_shop` | grille `azuria_velos.txt` (enveloppe de boutique) | intérieur | `interior_warm` | « Azuria » |
| `cerulean_house` | grille `azuria_maison.txt` (enveloppe de maison) | intérieur | `interior_warm` | « Azuria » |
| `route_24` | grille `route_24.txt` | extérieur | `golden_hour` | « Route 24 » / « Le Pont Pépite » (§21 n° 56) |

**Raccords** (cases « selon la grille validée ») :
- **Sas → plateau** : inchangé (bouche (2, 6) STEP_ON ← → `mt_moon_b2f` / `arrivee_s` ; `from_mt_moon` (3, 6) →).
- **Route 4 ↔ Azuria** : bord est de la Route 4 (PUSH →, un spawn par rangée `_n/_c/_s`) → `cerulean_city` / `from_route_4_*` ; bord ouest d'Azuria (PUSH ←) → `route_4` / `from_cerulean_*`.
- **Azuria ↔ Route 24** : sortie nord (pont sur le canal, PUSH ↑) → `route_24` / `from_cerulean_*` ; bord sud de la Route 24 (PUSH ↓) → `cerulean_city` / `from_route_24_*`.
- **Portes d'Azuria** (STEP_ON ↑) : Centre, Boutique, Arène, magasin de vélos, maison ouverte ; sorties des intérieurs → `cerulean_city` / `from_<intérieur>`. **Maison cambriolée** : aucune porte praticable, un `InteractPoint` (§21 n° 12).
- **Route 24 est** : `coming_soon = "Route 25"` (« ROUTE 25 — À venir », développement ; bord bloqué en release) — passation J14 : `route_25` / `from_route_24`.
- **Azuria est et sud** : fermées, sans warp (arbre et clôture ; palissade de chantier).
- **Eau** : jamais praticable (`WATER`) ; ponts de ville et Pont Pépite = cases praticables posées sur l'eau (`BOARDWALK` ou `COBBLE` sous un décor de pont).

**Lecture des grilles par les outils** (règles du J12 reprises) : un spawn par case (`_n/_c/_s`,
`_w/_e`) ; objet caché = point d'examen **sur la case de l'indice** (`jalon-12.md` §1.3 n° 1) ;
déclencheurs de scène = **rectangles** de la grille (vue du rival, pied du pont, devant le
recruteur, entrée d'Azuria) ; vues des Dresseurs = `vue=` de la grille ; `plan_check` vérifie
« inévitable / évitable » avant la carte, les tests le revérifient sur la vraie scène avec ses PNJ.

### 1.4 Kit d'assets : série 15 (méthode des J8–J12)

**Numéro** : 12 = Argenta, 13 = compagnon (J11, sur `main`), 14 = Route 3 / Mont Sélénite
(`jalon-12`), **15 = libre** sur toutes les branches (vérifié le 2026-10-11 : aucun `serie15`, aucune
fiche `serie-15-*`). Fiche `docs/design/fiches-assets/serie-15-azuria.md`, outil
`tools/art/serie15.py` (T1). Vues : les vues générales peintes du J13 (à valider, filière
`j12-vues-generales`) ; **la grille fait foi**. Lumière **neutre (NE)** pour objets et personnages ;
reflets de l'eau **dans la valeur peinte** de la texture, jamais d'ombre portée peinte.

**A. Réutilisés tels quels** : herbe, chemin, pavés, hautes herbes, `relief_rebord_01` (rebord de la
Route 4), forêt `DenseForest` et `tree_foret_*`, buissons, rochers, panneaux, `bldg_centre_01`, la
façade de Boutique de Jadielle / Argenta, maisons d'Argenta (façades et enveloppe intérieure),
paroi ardoise et entrée de grotte de la série 14 (plateau du sas), `object/poke_ball_ground`,
`prop_indice_caillou_01` (série 14, objet caché) ; personnages `lass` (Clara, Alice, Romane, Diane,
H5 par défaut), `youngster` (Malo, H6), `scout` (Timéo), `camper` (Ethan), `guard` (H4 policier),
`gym_guide`, `nurse`, `clerk` (Boutique, vélos), `kid` (H2), habitants génériques pour H1, H3 et la
maison (choix au T1, **aucun modèle de personnage nommé** : `haru`, `aoki`, `maya`, `leo`, `oak`,
`mom`, `brock` exclus), `rival`, Sbire ♂ (série 14) pour le recruteur ; Pokémon en combat :
artworks officiels 043, 044, 069, 070, 090, 116, 118, 120, 121 (présents).

**B. Variations sans nouvel asset** : pavés existants plus clairs (`Shade`) pour les quais ; fleurs
plus fréquentes en ville ; arbres de la Route 4 moins secs que ceux de la Route 3.

**C. Nouveaux (série 15, Codex, lumière NE)** — **≈ 22 images** [D] (T1 peut fusionner des planches)

| Fiche → asset | Rôle que rien d'existant ne tient | Images |
|---|---|---|
| `WORLD_GROUND_EAU_CANAL_01` → `ground_eau_canal_01` | eau claire des canaux et de la rivière (texture répétable, reflets peints) | 1 |
| `WORLD_GROUND_DALLES_CLAIRES_01` | pierre claire des quais et de la place (si les pavés éclaircis ne suffisent pas : **conditionnel**) | (1) |
| `WORLD_RELIEF_QUAI_PLANCHE` → `relief_quai_01..06` | bords de quai droits, angles rentrants et sortants, escalier de quai | 1 |
| `WORLD_PROP_PONTS_PLANCHE` → `prop_pont_ville_01` (2 × 3), `prop_pont_pepite_tablier_01..03`, `_garde_corps_01`, `_pile_01` | trois ponts de ville ; Pont Pépite en modules répétables (2 cases de large) | 1 |
| `BLDG_ARENE_AZURIA_01` | façade de l'Arène (verrière, bleu et blanc) | 1 |
| `BLDG_VELOS_01` | façade du magasin de vélos (vitrine) | 1 |
| `WORLD_PROP_CAMBRIOLAGE_PLANCHE` → clôture arrachée, planche clouée, pot renversé, trou dans la clôture, ruban | indices matériels (C-8) sur une façade de maison réutilisée | 1 |
| `WORLD_PROP_FERMETURES_PLANCHE` → palissade de chantier, clôture + arbre | sorties sud et est | 1 |
| `WORLD_PROP_VILLE_EAU_PLANCHE` → jardinières, bancs, lampadaires de quai, bittes d'amarrage | végétation et mobilier de ville d'eau (V-2) | 1 |
| `WORLD_RELIEF_GROTTE_AZUREE_01` | entrée de la Grotte Azurée vue de loin, au-delà de l'eau (D-12) | 1 |
| `WORLD_RELIEF_BERGE_PLANCHE` | berges de la rivière de la Route 24 (terre et roseaux) | 1 |
| `INT_ARENE_AZURIA_COQUE_NE` + `INT_ARENE_AZURIA_PLANCHE_NE` | piscine : bassin, chemins secs, plongeoir, gradins, verrière (eau peinte, statique) | 2 |
| `INT_VELOS_PLANCHE_NE` | 2–3 vélos exposés, présentoirs (enveloppe de Boutique reprise) | 1 |
| `INT_MAISON_AZURIA_PLANCHE_NE` | mobilier de la maison ouverte (enveloppe de maison reprise) | 1 |
| `PNJ_ONDINE` (+ attente) → `misty` | Ondine (pont, Arène) | 2 |
| `PNJ_NAGEUR` (+ attente) → `swimmer` | Nageur Lucas (Arène) | 2 |
| `UI_ITEM_PEPITE` → `assets/ui/items/nugget.webp` | illustration du Sac (chaîne `preparer_menu.py`) | 1 |

**Conditionnels** (prompts prêts, jamais lancés par défaut) : `PNJ_NAGEUSE` (H5, §0.2 n° 7),
`WORLD_GROUND_DALLES_CLAIRES_01`, `PORTRAIT_ONDINE` (seulement si **Q-2** le demande).

**Décors de combat (T3, CB.3)** : `route_4_plaine`, `route_24_pont` (pied du pont et tablier),
`cerulean_gym_bassin` (bord du bassin) ; master 2340 × 1080, ligne de sol mesurée par
`preparer_decor.py` ; prompts `tools/art/combat_decors/prompts/COMBAT_DECOR_{ROUTE4,ROUTE24,
ARENE_AZURIA}_r1.txt`.

**Dos des 4 espèces capturables** (Mystherbe, Ortide, Chétiflor, Boustiflor) : **sprites
provisoires** (`gen_placeholder_battlers.gd`, comme les 50 espèces d'avant), étendus aux 9 espèces
(exigés par `test_battle_stage` pour toute espèce de Dresseur). Les dos peints suivent la filière
décidée (rendu 3D X/Y repeint par IA, `fiches-assets/serie-combat-dos-pilote.md`,
`provenance-modeles-3d.md`) : **chantier des dos peints suivi à part**, dette du J12 héritée, sans
blocage.

**Abandonnés** : Pokémon d'ambiance (aucun n'est placé par le dossier), personnages placés par les
vues, images de la V2 (droits, hors dépôt).

**Poids attendu** : ≈ 5 à 7 Mo (deux textures 1 024², planches, 3 décors de combat ≈ 0,4 Mo chacun).

---

## 2. Conception technique

### 2.1 Cartes : outils et catalogues (T6, T7, T8)

- **Outils** : `tools/build_cerulean_city.gd`, `tools/build_route_24.gd` (nouveaux),
  `tools/build_route_4.gd` (**réécrit** sur la grille `route_4.txt`, après celui du sas) — tous sur
  `pewter_map_kit.gd` (+ `cerulean_map_kit.gd`, §2.3) ; intérieurs :
  `build_painted_interiors.gd -- --rooms=cerulean_center,cerulean_mart,cerulean_gym,cerulean_bike_shop,cerulean_house`
  (`_pokemon_center`, `_poke_mart` ; l'enveloppe de maison `_pewter_house` devient générique
  `_painted_house` si son nom gêne, sans changer Argenta : diff nul vérifié).
- **Catalogues** : `zones.json` (zone `cerulean_city` : 6 cartes, services `pokemon_center`,
  `poke_mart`, `gym` ; zone **`route_24`** nouvelle, `kind: route`, sous-titre et description
  annexe A ; `route_4` inchangée) ; `assets/ui/map/kanto_placeholder_areas.json` (aire de `route_24`
  au nord d'Azuria, même identifiant : `test_zone_library`) ; `assets/ui/pokedex/scenes.json`
  (`route_24` → « prairie ») ; `interiors.json` (5 intérieurs) ; `rest_points.json`
  (`cerulean_center`, `nurse_wakeup`, `registers: true` → toast « Point de repos enregistré —
  Azuria ») ; `lighting.json` (aucun profil nouveau [D]) ; `decors.json` (§2.18).
- **Tests de carte** (sur les vraies scènes) : grille de la scène = grille du plan ; raccords aller
  et retour (`test_map_links`) ; intérieurs déclarés (`test_map_catalog`) ; nœuds ≤ 3 000 ;
  `test_coming_soon` déplacé sur le raccord est de la Route 24.

### 2.2 La Route 4 remplace le sas (T8 carte, T17 vie)

- **Même identifiant** `route_4`, **même repère** : la grille `route_4.txt` garde les colonnes 0–23 et
  les rangées 0–13 du sas aux mêmes coordonnées (praticable reste praticable, sauf la rangée du rebord
  qui peut devenir `LEDGE_DOWN`) ; même bouche de grotte, même `from_mt_moon` (3, 6), même
  déclencheur `route_4_reached` (4, 5..9), même panneau (6, 5). Le raccord est « AZURIA — À venir »
  disparaît.
- **Rebord à sens unique vers le sud** : tuiles `LEDGE_DOWN` existantes + `relief_rebord_01` (Route 1) ;
  on ne remonte pas par la route ; retour vers la grotte par le plateau seulement.
- **Test de reprise obligatoire** (`test_route_4_resume`, intégration, Boot réel) : pour **chaque
  case praticable de `route_4_sas.txt`**, une sauvegarde v6 construite sur `route_4` à cette case se
  charge et place le joueur sur une case **praticable** de la nouvelle scène (même case) ; plus, sur la
  vraie scène : `from_mt_moon` existe, le déclencheur `route_4_reached` couvre (4, 5..9), l'échelle
  mène toujours à B2F, le bord est mène à Azuria. Le test lit la grille du sas (`PlanGrid`), pas une
  liste recopiée.
- **Contenu** (§3.2 du dossier) : table `route_4_grass` (§2.14), Jeune Dresseuse Clara (évitable,
  bloc `trainer` ; vérifié sur la vraie scène), Poké Ball au sol (`got_route_4_poke_ball`).
- Test `test_route_4` du J12 **réécrit** (même nom) ; `test_route_4_life` (Clara évitable, objet,
  herbes, saut du rebord dans un seul sens).

### 2.3 L'eau sans shader coûteux (T6 fondations, T7, T8)

- **Mécanisme existant** : `PaintedGround.shore_mask` (`GroundMask.build_shore(size, sand, water)`)
  → le **même** `ground_blend.gdshader` dessine l'eau dans la passe du sol (une seule surface, aucun
  nœud par case, aucune lecture d'écran, aucune `Light2D`) ; l'ondulation `TIME` est celle de la mer de
  Bourg Palette (déjà validée sur S24).
- **Ajouts (T6)**, sans rien changer aux cartes existantes : `PaintedGround.water_texture`
  (`@export`, nul = eau de mer actuelle) et `PaintedGround.foam_strength` (`@export`, défaut 0,8 =
  valeur actuelle codée en dur dans le shader l. 76 → uniform ; **0 pour les canaux** : les quais sont
  des murs, pas des plages) ; masque de rivage **sans sable** pour Azuria et la Route 24.
- **`tools/cerulean_map_kit.gd`** (nouveau, appelle `pewter_map_kit.gd`) : canaux à **angles
  droits** depuis les cases d'eau de la grille, bords de quai posés en modules `relief_quai_*` sur
  toute frontière eau / sol (sans jamais toucher une case praticable), ponts (décor au-dessus,
  cases praticables `BOARDWALK`), graines fixes.
- **Reflets** : peints dans `ground_eau_canal_01` ; **aucun** shader de réflexion, aucune particule.
  L'Arène : eau **peinte dans la coque** (statique).
- **Tests** : `test_painted_ground` (défauts identiques : Bourg Palette inchangée, `foam_strength`
  par défaut = rendu actuel) ; `test_ground_mask` (rivage sans sable) ; sur les cartes : toute case
  d'eau est solide pour le joueur, les ponts sont praticables, le compagnon voit l'eau
  (`GridWorld.is_water`).
- **Budget** : moyenne ≥ 58 fps, creux ≥ 50 sur Azuria avec l'eau à l'écran (mesure dès la première
  construction de T7, capture `[perf]`).

### 2.4 Azuria : habitants, cambriolage (T17)

- **PNJ** `data/npcs/cerulean_city.json` : H1–H6 (§4.4, textes n° 7–11, 14–17), H5 seule réagit au
  badge (`if badge_cascade`) ; habitant près d'une sortie fermée (n° 17).
- **Maison cambriolée** : façade réutilisée + décalcomanies de la série 15 ; porte = `InteractPoint`
  EXAMINER → « Un ruban interdit l'entrée. » (n° 12) ; clôture arrière arrachée = `InteractPoint`
  (n° 13) ; planche, pot, trou dans la clôture du fond = **décor seul** [D] (aucun texte au §21) ;
  le trou donne visuellement vers l'est, case **bloquée**. H3 : n° 9, puis n° 10 en lui reparlant
  (drapeau de mémoire `cerulean_neighbor_talked` [D] ou variante « déjà dit » existante). H4 : n° 11.
  **Rien ne change au J13** (ni badge ni pont). Passation J14 : jardin et trou gardés par la grille.
- **Arrivée** : déclencheur silencieux à l'entrée ouest (rectangle de la grille) → scène
  `cerulean_arrival` (`unless cerulean_reached` : `set cerulean_reached`), modèle `pewter_arrived` ;
  titre de zone « AZURIA » (ZoneAnnouncer) ; Grand moment d'arrivée `zone_arrivals.cerulean_city`
  (annexe A) ; objectif changé en silence.
- **Panneaux** : entrée (n° 6), Arène (n° 20), Centre « CENTRE POKÉMON » / « Azuria » (modèle des
  Centres précédents).

### 2.5 Centre, Boutique, magasin de vélos, maison (T7 cartes, T17 vie)

- **Centre** : soin, Stockage, point de repos (§2.1) ; PNJ modèle de Jadielle.
- **Boutique** `data/shops/cerulean_mart.json` : Poké Ball, Potion, Antidote, Corde Sortie (J12),
  Anti-Para, Réveil, Antigel, Anti-Brûle (J11) — sans Repousse (D-13). **VENDRE** existe : la Pépite
  se vend 5 000 ₽ (`sell_price` = ⌊10 000 / 2⌋), confirmation existante si favori.
- **Magasin de vélos** : vendeur (`clerk` [D]) qui dit les trois pages du n° 19 ; vélos = décor
  (EXAMINER facultatif : non [D]) ; aucun achat, aucun objet remis, **aucun mode Boutique**.
- **Maison ouverte** : habitante (n° 18).

### 2.6 Arène : lieu, Dresseurs, guide (T7 carte, T17 Dresseurs, T19 Ondine)

- Carte `cerulean_gym` (grille `azuria_arene.txt`) : bassin peint (cases solides), chemins secs,
  plongeoir, gradins ; ni puzzle, ni nage, ni courant.
- **Dresseurs** (`data/trainers/cerulean_gym.json`) : `cerulean_gym_lucas` « Nageur Lucas »
  (Hypotrempe 16, Kokiyas 16, `random`, 80 ₽), `cerulean_gym_diane` « Jeune Dresseuse Diane »
  (Poissirène 19, `random`, 285 ₽) ; capacités apprises au niveau ; blocs `trainer` (vues de la
  grille), **évitables** (vérifiés sur la vraie scène) ; combattables **dès l'arrivée** (aucune
  condition) ; répliques n° 24–27 (« après » = « battu » [D]).
- **Guide** : n° 21 (`unless misty_invited`), n° 22 (`if misty_invited`, `unless badge_cascade`), n° 23
  (`if badge_cascade`).
- **Ondine** : PNJ `misty` au fond, présent `if misty_invited` ; avant, sa place est vide (§2.10).

### 2.7 Le rival n° 3 (T16 briques, T19 données)

- **Donnée** `rival.json` += `rival_cerulean` : `name: "{rival}"`, `ai: "smart"`, **`switch: true`**,
  `can_lose: false`, `heal_after: false`, `gives_exp: true`, `prize_per_level: 35` (→ 35 × 17 =
  **595 ₽**), `start_message: true`, `end_message: false`, `bag: true` (le **joueur** garde son Sac ;
  « pas de Sac au combat » vise le rival, qui n'a jamais d'objet) [D], **`moment: "win"`** (§2.8),
  `team_by_starter` : Bulbizarre → Roucoups 18, Rattata 15, Reptincel 17 ; Salamèche → Roucoups 18,
  Rattata 15, Carabaffe 17 ; Carapuce → Roucoups 18, Rattata 15, Herbizarre 17 (capacités apprises au
  niveau).
- **PNJ** `rival_cerulean` (Route 24, au pied du pont, tourné vers la ville), présent
  `unless rival_cerulean_won`.
- **Déclencheur** : `EventTriggerPoint` couvrant **toute la vue** du rival (rectangle de la grille,
  toute la largeur de l'accès, `direction = ZERO`) → scène `route_24_rival`.
- **Scène `route_24_rival`** (une variante, `unless rival_cerulean_won`) :
  `emote !` (rival) → `move` rival `near` joueur → `face` × 2 →
  `dialogue rival_cerulean_intro` (n° 28) `unless rival_cerulean_lost_once` →
  `dialogue rival_cerulean_resume` (n° 30) `if rival_cerulean_lost_once` `unless rival_cerulean_retried` →
  `dialogue rival_cerulean_resume_again` (n° 31) `if rival_cerulean_retried` →
  `set rival_cerulean_retried` `if rival_cerulean_lost_once` →
  `battle rival_cerulean` (`win: [rival_cerulean_won]`, `lose: [rival_cerulean_lost_once]`) →
  victoire : `wait 0.6` → `dialogue` n° 32 → `move` rival vers la ville (chemin de la grille) →
  `despawn` ; défaite : `dialogue` n° 29 → `wake_up`.
  Lecture du §7.3 : première défaite → au retour n° 30 ; deuxième défaite et suivantes → n° 31
  (« à partir du deuxième retour ») ; `rival_cerulean_retried` [D] est la mémoire « a déjà eu sa
  reprise ». **Jamais une branche** : le combat et l'équipe sont les mêmes.
- **Clé de scène `next: "route_24_misty"`** (§2.9).
- **Tests** : `test_rival_cerulean` (Boot réel, vraie scène) : vue inévitable (aucun chemin de la
  ville au pont hors du rectangle) ; première rencontre → n° 28 ; défaite → Centre, aucun argent
  perdu, rival toujours là ; retour → n° 30 sans introduction ; deuxième défaite → n° 31 ; victoire →
  n° 32, départ, absent au rechargement ; 595 ₽ ; trois starters → trois équipes.

### 2.8 Grand moment du rival : unique, à la victoire (T16)

```gdscript
# game/systems/menu/rival_moment.gd — pur (modèle BadgeMoment)
class_name RivalMoment
extends RefCounted
## Grand moment « combat contre le rival » (roadmap, précisée le 2026-10-11 ; dossier 16 D-5).
## Rival = Dresseur à `team_by_starter`. Un moment par Dresseur, jamais deux ; si la donnée du
## Dresseur dit `moment: "win"` (combat obligatoire et rejouable), seulement à la victoire.
static func should_record(trainer: TrainerData, outcome: int, moments: Array) -> bool
static func has_rival_moment(moments: Array, trainer_id: StringName) -> bool
```
- `TrainerData.moment_on_win: bool` (JSON `"moment": "win"`, seule valeur admise ; absent = toute
  issue, comportement des rivaux n° 1 et n° 2 **inchangé**) ; `TrainerLibrary` refuse une autre valeur.
- `Boot._on_battle_finished` (`boot.gd:1195`) appelle `RivalMoment.should_record` avant
  `record_moment` ; le contrôle de doublon (`details.trainer`) s'applique à **tous** les rivaux
  (inoffensif : n° 1 et n° 2 ne se rejouent pas).
- **Tests** : `test_rival_moment` (pur : n° 1 et n° 2 victoire comme défaite ; n° 3 défaite → rien,
  victoire → un ; deux victoires impossibles → un seul) ; intégration dans `test_rival_cerulean`
  (deux défaites puis une victoire → **exactement un** moment `rival_battle`, issue « win ») ;
  non-régression `test_rival_route22`.

### 2.9 Scène d'Ondine au pont, et sa reprise (T16 brique, T19 données)

- **Brique : enchaînement de scènes** — clé de scène `"next": "<id>"` (`CutsceneLibrary`, lecture
  tolérante, référence vérifiée) : à la fin d'une scène qui a `next`, **Boot écrit la sauvegarde
  tout de suite** (partie stable : joueur libre, aucune scène) puis joue `next` **si une de ses
  variantes s'applique** ; sinon rien. Une seule fois par fin de scène (pas de boucle : la scène
  suivante n'enchaîne que si elle a elle-même `next`). Aucune écriture pendant une scène (régime
  existant inchangé).
- **Scène `route_24_misty`** (une variante, `if rival_cerulean_won`, `unless misty_invited`) :
  `move misty near joueur` → `face` × 2 → `dialogue misty_bridge_invite` (n° 33, 4 pages) →
  `move misty` vers la ville (chemin de la grille) → `despawn misty` → `set misty_invited`.
- **PNJ** `misty_bridge` sur la berge au pied du pont, tourné vers le pont, présent
  `unless misty_invited` (visible au-delà du rival, inatteignable avant lui par la géométrie) ;
  dialogue → scène `route_24_misty` (on peut aussi lui parler pendant la reprise).
- **Reprise** (§8, §19) : un second déclencheur **au pied du pont** (rectangle de la grille, toute la
  largeur, entre la vue du rival et le tablier) joue `route_24_misty`. Partie quittée après la
  sauvegarde d'entre-scènes → au rechargement, rival absent, Ondine présente, le premier pas vers le
  pont ou un retour depuis la ville joue la scène ; partie quittée pendant `route_24_misty` → rien
  n'est écrit, même résultat.
- **Tests** : `test_cutscene_chain` (Boot réel : la sauvegarde écrite entre les deux scènes contient
  `rival_cerulean_won` et pas `misty_invited` ; la scène suivante ne joue pas si sa variante ne
  s'applique pas ; pas de second enchaînement) ; `test_route_24_misty` (enchaînement direct ;
  rechargement de la sauvegarde d'entre-scènes → scène par le déclencheur ; puis Ondine absente,
  `misty_invited`).

### 2.10 Ondine, Badge Cascade, CT11 (T19)

- **Donnée** `cerulean_gym_misty` « Ondine » : `smart`, **`switch: true`**, 2 100 ₽, `card` « ONDINE »
  / « Championne d'Arène d'Azuria », `start_message: false`, `end_message: true`, équipe Stari 18
  (`tackle`, `water_gun`), Staross 21 (`tackle`, `water_gun`, `harden`, `bubble_beam`).
- **Scène `cerulean_gym_misty`** (modèle `pewter_gym.json` du J11), variante `unless badge_cascade` :
  `face` → n° 34 `unless misty_met` / n° 36 `if misty_met` → `champion_card` `unless misty_met` →
  `set misty_met` → `battle` (`win: [badge_cascade]`) → victoire : `wait 0.6`, n° 37, **`badge
  cascade`** (légende « BADGE CASCADE », vibration, Grand moment « badge », drapeau), n° 38, puis
  `unless tm11_received` : « Prends aussi ceci. » → `give tm11` (toast « CT11 — Bulles d'O / obtenue »,
  forme du J11) → « C'est la CT11, Bulles d'O… » → `set tm11_received` ; défaite : n° 35 → `wake_up`.
- **Rattrapage** : scène `cerulean_gym_misty_tm_late` (modèle `pewter_gym_brock_tm_late`) : n° 40
  puis n° 39 (deux pages, `give tm11` entre elles), `set tm11_received`.
- **Dialogue d'Ondine** (variantes, ordre) : `if badge_cascade unless tm11_received` → rattrapage ;
  `if badge_cascade if beaten_nugget_rocket` → n° 41 b ; `if badge_cascade` → n° 41 a ; sinon → scène
  `cerulean_gym_misty`.
- **Effet du badge** : aucun ; objectif en silence ; autosave à la fin de la scène.
- **Tests** : `test_misty_sequence` (victoire → légende, badge, moment, CT11 une fois ; défaite →
  Centre → n° 36 sans carte ; partie badgée sans CT → rattrapage une fois ; réplique n° 41 selon le
  recruteur ; Dresseurs battus gardés) ; textes mot pour mot contre le §21.

### 2.11 IA qui change de Pokémon (T12 moteur, T13 interface)

Règle du dossier §14, rendue **déterministe** (aucun tirage : les graines des tests existants ne
bougent pas).

```gdscript
# game/battle/ai_switch_rule.gd — pur
class_name AiSwitchRule
extends RefCounted
## Changement de Pokémon de l'IA (dossier 16 §14, D-7) : au plus un par combat (compté par
## BattleAI), au moment de choisir l'action. Données lues : PV, types, table des types.
const DANGER_HP_RATIO: float = 0.25   # en danger : PV ≤ 25 % des PV max
const SAFE_HP_RATIO: float = 0.5      # meilleure posture : PV > 50 %
const WEAK_MULTIPLIER: float = 2.0    # faiblesse : multiplicateur ≥ ×2
## Place dans own.party du Pokémon à envoyer, ou -1 (rester).
static func pick(own: BattleSide, foe: Battler, chart: TypeChart, data: PokemonData) -> int
static func is_in_danger(active: Battler, foe: Battler, chart: TypeChart) -> bool
static func is_weak_to(defender_types: Array[StringName], foe: Battler, chart: TypeChart) -> bool
static func is_better_placed(pokemon: Pokemon, foe: Battler, chart: TypeChart, data: PokemonData) -> bool
```

- **Faiblesse** [D] : au moins **un type du Pokémon du joueur** (attaquant) a un multiplicateur
  ≥ ×2 contre les types du Pokémon considéré (×4 compris). L'IA lit les **types**, pas les capacités
  du joueur (l'information qu'un joueur a à l'écran).
- **En danger** : PV ≤ 25 % (bornes : 25 % pile = danger) **ou** faiblesse.
- **Meilleure posture** : non K.O., pas en jeu, PV **> 50 %** (50 % pile = non), **aucune**
  faiblesse. Plusieurs candidats → **le premier dans l'ordre de l'équipe** [D].
- **Jamais** : `can_switch` faux (donnée `switch` absente ou fausse : tous les Dresseurs sauf Ondine
  et le rival n° 3) ; déjà changé une fois dans ce combat ; Pokémon actif en Patience (J11) ou
  **piégé** (J12 `trap`) ou verrouillé de quelque façon que `Battle` connaisse au T10 ; combat
  sauvage (aucun `TrainerData`) ; un seul Pokémon debout.
- **`BattleAI`** : `var can_switch: bool` (posé par `TrainerData.make_ai`, `switch` lu par
  `TrainerLibrary`), `var _switched: bool` ; dans `choose`, **avant** le choix de capacité :
  `AiSwitchRule.pick` ≥ 0 → `_switched = true` → `BattleAction.switch_to(index)` (action SWITCH
  existante, jalon 7).
- **`Battle`** : l'action adverse SWITCH est jouée **avant** les capacités du tour (comme le
  changement du joueur) : `_foe_switch(index, events)` = WITHDRAWN (camp adverse, `trainer_name`) puis
  `_send_out(_foe, events, pokemon)` ; le Dresseur **ne joue pas** de capacité ce tour (le tour est
  consommé) ; le joueur agit ensuite contre le nouveau Pokémon ; puis la fin de tour. Dans
  `_foe_turn_alone` (après un changement, un objet, une fuite ratée du joueur) : même chose, l'IA
  juge contre le Pokémon du joueur **alors en jeu**. Le Pokémon rappelé **garde PV et statut**
  (objet `Pokemon`), perd niveaux de statistiques, confusion, graine, piège (nouveau `Battler`, règles
  du J11/J12) ; il revient plus tard par `first_able` quand le suivant tombe ; XP : règle existante
  (participants remis à zéro à chaque entrée adverse).
- **Texte** : `messages.json` += `withdrawn_foe` « {trainer} rappelle {pokemon} ! » (§21 n° 60) ;
  `BattleText` choisit la clé par camp ; puis « {trainer} envoie {pokemon} ! » (existant).
- **Présentation** (T13, ui-mobile en relecture) : beat WITHDRAW côté adverse = carte adverse
  masquée + `BattleStage.play_withdraw(FOE)` (générique, existant) sur l'artwork officiel ; puis
  l'entrée habituelle. Aucune image nouvelle. Captures relues.
- **Tests** : `test_ai_switch_rule` (pur : bornes 25 % / 50 %, ×2 et ×4, candidat faible écarté,
  premier dans l'ordre, K.O. et actif exclus, aucun candidat) ; `test_battle_ai` (`can_switch` faux →
  jamais ; vrai → **une fois au plus** même si les conditions durent ; jamais en Patience ni piégé ;
  `random` et `smart` sans `switch` : mêmes choix et mêmes tirages qu'avant) ; `test_battle_foe_switch`
  (ordre WITHDRAWN puis SENT_OUT, tour consommé, coup du joueur sur le nouveau, PV et statut gardés,
  niveaux remis à zéro, confusion perdue, retour par `first_able`, XP) ; `test_battle_text`,
  `test_battle_playback` ; `test_trainer_library` (`switch` booléen) ; **non-régression** :
  `tools/simulate_brock.gd` relancé → résultats identiques ; `test_brock_sequence`, `test_rival_route22`.

### 2.12 Le Pont Pépite (T22)

- **Données** `data/trainers/route_24.json` : `route_24_timeo` « Scout Timéo » (Chenipan, Aspicot,
  Chrysacier, Coconfort Nv. 10, 120 ₽), `route_24_alice` « Jeune Dresseuse Alice » (Roucool,
  Mystherbe, Chétiflor Nv. 12, 180 ₽), `route_24_malo` « Gamin Malo » (Sabelette, Abo Nv. 14, 210 ₽),
  `route_24_romane` « Jeune Dresseuse Romane » (Nidoran ♀ 16, Nidoran ♂ 16, 240 ₽),
  `route_24_ethan` « Campeur Ethan » (Férosinge 18, 360 ₽) ; `random` ; montants fixes ; capacités
  apprises au niveau.
- **PNJ** : blocs `trainer` aux cases et vues de la grille, chacun **inévitable** (§0.2 n° 11) ;
  répliques n° 43–47 (« avant » / « battu » ; « après » = « battu » [D]) ; panneau n° 42 au pied du
  pont.
- **Persistance** : `beaten_<id>` (C-3, rien à coder) ; défaite → Centre d'Azuria, battus gardés.
- **Tests** : `test_nugget_bridge` (vraie scène avec PNJ : aucun chemin du pied du pont au recruteur
  hors des cinq vues ; ordre P1 → P5 ; défaite au milieu → battus gardés, les autres attendent).

### 2.13 Le recruteur, le choix, la Pépite (T16 brique, T22 données)

- **Brique : choix qui pose un drapeau** — `DialogueChoice.confirm_set` / `cancel_set` (clés JSON
  `"confirm_set"`, `"cancel_set"`, tableaux de drapeaux, compatibles avec `confirm_action` /
  `confirm_cutscene`) : le `DialogueRunner` lève les drapeaux du bouton choisi **avant** de fermer le
  dialogue ; dans une scène, les étapes suivantes les lisent (conditions évaluées à l'exécution,
  comme `badge_boulder` après le combat de Pierre). Tests : `test_dialogue_library` (clés, refus d'un
  drapeau vide), `test_dialogue_runner` (OUI → `confirm_set`, NON → `cancel_set`, rien d'autre).
- **Donnée** `nugget_rocket` « Sbire Rocket » (Abo 15, Nosferapti 15, `smart`, 450 ₽) ; objet `nugget`
  (« Pépite » / « Pépites », féminin, `field` = AVENTURE, `price: 10000`, **aucun** `field_use` → pas
  de bouton UTILISER, description n° 58).
- **PNJ** `nugget_rocket` (Sbire ♂, série 14) au bout nord du pont, présent `unless
  beaten_nugget_rocket` ; **déclencheur** devant lui (rectangle de toute la largeur) → scène
  `route_24_rocket`.
- **Scène `route_24_rocket`** :
  - variante `unless got_nugget` : `face` × 2 → n° 48 → n° 49 (« {player} reçoit une PÉPITE ! ») →
    `give nugget` (toast « Pépite ×1 — Ajoutée au Sac ») → `set got_nugget` → n° 50 avec choix OUI /
    NON (`confirm_set: [nugget_rocket_yes]`) → n° 51 `if nugget_rocket_yes` / n° 52 `unless
    nugget_rocket_yes` → `battle nugget_rocket` (`win: [beaten_nugget_rocket]`) → victoire : n° 53,
    `move` vers l'espace nord puis `despawn` ; défaite : n° 54, `wake_up` ;
  - variante `if got_nugget`, `unless beaten_nugget_rocket` : n° 55 → même combat et mêmes issues,
    **sans proposition ni choix**.
- **Une seule Pépite** : `give` et `set got_nugget` dans la même scène (une fermeture en pleine
  scène rejoue tout, Sac compris : jamais deux) ; vendue → rien ne la redonne. Le drapeau
  `nugget_rocket_yes` [D] n'a **aucune** conséquence (C-4).
- **Tests** : `test_nugget_rocket` (Boot réel : OUI et NON → réplique propre puis le même combat ;
  Pépite au Sac une fois ; défaite → Centre, Pépite gardée, retour → n° 55 sans choix ; victoire →
  départ, espace nord ouvert, absent au rechargement) ; `test_shop_sell` étendu (Pépite → +5 000 ₽).

### 2.14 Route 24 nord et rencontres (T8 carte, T17, T22)

- **Espace nord** : 2 zones d'herbes ; Potion visible (`got_route_24_potion`) ; **Antidote caché**
  face à un indice (mécanique J12 : `InteractPoint` `unless_flags = [got_route_24_antidote]`, toast
  standard) ; aucun Dresseur ; raccord est « ROUTE 25 — À venir ».
- **Tables** [D, niveaux du dossier] :
  - `data/encounters/route_4.json` — `route_4_grass` (`rate` 25, rampe 15 → 20) : Rattata 8–12 (30),
    Piafabec 8–12 (30), Abo 10–12 (15), Sabelette 10–12 (15), Férosinge 10–13 (10).
  - `data/encounters/route_24.json` — `route_24_grass` (mêmes taux) : Mystherbe 12–14 (25),
    Chétiflor 12–14 (25), Roucool 12–13 (15), Chenipan 7–8 (10), Aspicot 7–8 (10), Chrysacier 8–9 (7),
    Coconfort 8–9 (8).
  Habitats du Pokédex : automatiques (vu par carte, zone `route_24`).
- **Tests** : `test_encounter_library` (deux tables, couples uniques), `test_route_24_life`.

### 2.15 Espèces, capacités, Pokédex, CT, objets (T11)

- **`kanto.json`** : `staryu`, `starmie`, `horsea`, `shellder`, `goldeen`, `oddish`, `gloom`,
  `bellsprout`, `weepinbell` — conventions existantes (statistiques, taux de capture et XP de base
  actuels, types modernes, croissance, apprentissages de **Rouge/Bleu, tous niveaux**) ;
  évolutions : Mystherbe → Ortide (21), Chétiflor → Boustiflor (21) ; **non déclarées**, faute de
  données pour la forme suivante [D] : Hypotrempe → Hypocéan (32), Poissirène → Poissoroy (33), et
  toutes les évolutions par pierre (Stari, Kokiyas, Ortide, Boustiflor). **59 espèces**.
- **Capacités** (`moves.json`, valeurs modernes comme l'existant) :

  | Id | Nom | Effet | Qui (atteignable au J13 ?) |
  |---|---|---|---|
  | `bubble_beam` | Bulles d'O | Eau, spéciale, 65, 100, 20 PP ; `stat_stage spe −1, 10 %` (existant) | Staross (Ondine), CT11 — **oui** |
  | `absorb` | Vol-Vie | Plante, spéciale, 20, 100, 25 PP ; `drain ½` (J12) | Mystherbe 1 — **oui** |
  | `recover` | Soin | Normal, statut, 5 PP ; `pending_effects: ["heal_half"]` | Stari 27 — non |
  | `clamp` | Claquoir | Eau, physique, 35, 85, 15 PP ; `trap` (J12, messages par capacité) | Kokiyas 23 — non |
  | `aurora_beam` | Onde Boréale | Glace, spéciale, 65, 100, 20 PP ; `stat_stage atk −1, 10 %` | Kokiyas 30 — non |
  | `ice_beam` | Laser Glace | Glace, spéciale, 90, 100, 10 PP ; gel 10 % (J11) | Kokiyas 50 — non |
  | `waterfall` | Cascade | Eau, physique, 80, 100, 15 PP ; apeurement 20 % (J11, G+) [D] | Poissirène 37 — non |
  | `petal_dance` | Danse Fleur | Plante, spéciale, 120, 100, 10 PP ; `pending_effects: ["rampage"]` | Mystherbe 33, Ortide 38 — non |

  Déjà présentes (J12 ou avant) : `acid` (J12, §0.2 n° 5), `wrap`, `tackle`, `water_gun`, `harden`,
  `swift`, `minimize`, `light_screen`, `hydro_pump`, `bubble`, `smokescreen`, `leer`, `agility`,
  `withdraw`, `supersonic`, `peck`, `tail_whip`, `horn_attack`, `fury_attack`, `horn_drill`,
  `poison_powder`, `stun_spore`, `sleep_powder`, `solar_beam`, `vine_whip`, `growth`, `razor_leaf`,
  `slam`. Descriptions : annexe A (Bulles d'O = §21 n° 59). Compte attendu : 66 (`main`) + 1 (J11,
  `bide`) + 21 (J12) = 88, puis **96** au J13 (recompté au T10).
- **Pokédex** `data/pokedex/kanto.json` : 9 fiches (taille, poids officiels, description) + notes
  des **6 formes de base** (annexe A).
- **CT** : `tools/gen_tm_compatibility.py` relancé sur 59 espèces (CSV de PokeAPI, comme au J11) ;
  objet `tm11` (« CT11 — Bulles d'O », catégorie `tm`, `tm: 11`, `teaches: bubble_beam`, féminin,
  description n° 59).
- **Sprites provisoires** : `gen_placeholder_battlers.gd` étendu aux 9 (§1.4).
- **Tests** : `test_pokemon_data` (59 espèces, learnsets résolus, aucune évolution vers une espèce
  absente), `test_pokedex_library`, `test_tm_compatibility` (CT11 compatible avec Staross, Kokiyas,
  Carapuce… d'après la table générée), `test_item_library` (Pépite vendable, sans usage ; CT11
  invendable), `test_battle_drain` étendu (Vol-Vie), `test_battle_trap` (Claquoir : textes).

### 2.16 Objectifs (T17, T22)

`objectives.json`, **en tête**, dans cet ordre (première entrée valide l'emporte) :
`{ "id": "explore_cerulean", "text": "explorer les environs d'Azuria.", "if": ["badge_cascade",
"beaten_nugget_rocket"] }`, `{ "id": "cross_nugget_bridge", "text": "traverser le Pont Pépite.",
"if": ["badge_cascade"], "unless": ["beaten_nugget_rocket"] }`, `{ "id": "get_cascade_badge", "text":
"obtenir le Badge Cascade.", "if": ["cerulean_reached"], "unless": ["badge_cascade"] }` ; puis les
entrées du J12 (`go_cerulean`…). Le pont fait avant le badge : l'objectif reste « obtenir le Badge
Cascade. » (§19). `test_objective_library` : les quatre états du §18 + ce cas.

### 2.17 Compagnon (J11)

Données seules : `companions.json` `contexts` += `cerulean_city: city` (phrase « ville » du J11) ;
la phrase « eau à ≤ 2 cases » joue d'elle-même au bord des canaux. Il suit sur les quais (≥ 2 cases)
et les ponts, est masqué dans les goulets d'une case (Dresseurs du pont), rentre dans les cinq
intérieurs (`interior = true`). Aucune espèce nouvelle éligible (aucune planche, §1.4). Critères
retirés si le 11D manque (§0.3).

### 2.18 Décors de combat (T3 art, T7 / T8 intégration)

`decors.json` : `route_4_plaine` (défaut de `route_4`, sas compris [D]), `route_24_pont` (défaut de
`route_24` : pont, recruteur, espace nord), `cerulean_gym_bassin` (défaut de `cerulean_gym`). Azuria
et ses autres intérieurs : aucun combat. Tests `test_battle_stage_decor` (choix par carte), captures
CB.3 (`tools/capture_combat_cb3.sh`).

### 2.19 Drapeaux et sauvegarde : **aucune version nouvelle** (preuve)

Règle d'en-tête de `save_system.gd` (l. 22) : incrémenter `VERSION` quand un champ change de forme
ou quand on ajoute des champs qu'une build plus ancienne effacerait. Inventaire de ce que le J13
écrit, champ par champ de `GameState.to_dict()` :

| Ce que le J13 mémorise | Champ (existant) | Forme |
|---|---|---|
| `rival_cerulean_won`, `rival_cerulean_lost_once`, `rival_cerulean_retried`, `misty_invited`, `misty_met`, `badge_cascade`, `tm11_received`, `got_nugget`, `nugget_rocket_yes`, `cerulean_reached`, `beaten_*` (Clara, Lucas, Diane, P1–P5, recruteur), `got_<objet>` (visibles et caché), `cerulean_neighbor_talked` | `flags` (tableau de chaînes) | inchangée |
| Pépite, CT11, objets ramassés | `bag.items`, `acquired` | inchangée |
| Objets trouvés | `found_items` | inchangée |
| Grands moments `rival_battle` (n° 3, `{trainer, outcome}`), `badge` (cascade), `zone_arrival` (Azuria) | `moments` | inchangée |
| Espèces, capacités, évolutions nouvelles | `party`, `storage` | inchangée |
| Position sur les cartes nouvelles, `route_4` (même identifiant) | `map`, `cell`, `facing` | inchangée |
| Point de repos d'Azuria | `heal_map`, `heal_spawn` | inchangée |
| Compagnon | `companion` (J11) | inchangée |
| Changement de l'IA (`_switched`) | **rien** : volatil de combat, jamais écrit pendant un combat | — |

Aucun champ ajouté ni transformé → **pas de version nouvelle** : le J13 écrit la version de `main`
après le J12 (v6). Une build plus ancienne écarterait seulement les **valeurs** inconnues (carte,
espèce, objet) en copiant l'original dans `save.json.rejected` (régime des J8, J10, J12). **Garde** :
toute tâche qui voudrait un champ nouveau s'arrête et revient à l'architecte (version + validation
seule, règle 1).
Tests : `test_save_j13` (partie construite après le rival et avant le badge : `to_dict` → JSON →
`load_dict` → mêmes drapeaux, Sac, moments ; `SaveSystem.VERSION` inchangée par le J13) ;
`test_route_4_resume` (§2.2).

### 2.20 Budgets et mesures (T7, T8, QA)

- ≤ 3 000 nœuds par carte (`NODE_BUDGET`), mesuré **dès** la première construction d'Azuria
  (≈ 2 576 cases, contre 2 288 pour Argenta : moins d'arbres, plus de modules de quai) et de la
  Route 24 (tablier en grands modules, pas un nœud par case).
- Mémoire « carte + voisines » (`tools/measure_map_cache.gd`) : Route 4 (Azuria + B2F), Azuria
  (Route 4 + Route 24 ; intérieurs non préchargés), Route 24 (Azuria). Si la Route 4 dépasse
  **64 Mo** avec ses voisines : elle ne précharge que Azuria [D, défaut du J12 reconduit] ;
  changement de carte ≤ 1,5 × Jadielle.
- fps : moyenne ≥ 58, creux ≥ 50 (Azuria avec eau, Pont Pépite, Arène) ; ≥ 55 en combat ; taille de
  l'APK notée.

### 2.21 Départs de débogage et carte de QA (T14, T17, T19, T22)

- **Carte `qa_switch_j13`** (modèle `qa_status` / `qa_moves_j12`, tuiles provisoires) : herbes à
  table forcée (Mystherbe Nv. 24 Vol-Vie / Acide, Chétiflor Nv. 21 Ligotage / poudres) ; trois
  Dresseurs d'essai `switch: true` : « Ondine d'essai » (Stari, Staross), « rival d'essai » (équipe
  de Salamèche), un Dresseur `smart` **sans** `switch` (témoin) ; départ **`switch_qa`** (Pikachu,
  Bulbizarre, Carapuce, Salamèche Nv. 20, Potions). **Retirée au T22.**
- Départs (`tools/debug_start/`, README complété) : `route_4` (sortie du sas, équipe Nv. 18–20 [D]) ;
  `cerulean_city` (arrivée, `cerulean_reached`) ; `rival_cerulean` (devant la vue du rival) ;
  `rival_cerulean_weak` (pour perdre : reprise) ; `misty_pending` (sauvegarde d'entre-scènes :
  `rival_cerulean_won` sans `misty_invited`) ; `cerulean_gym` (`misty_invited`) ; `cascade_no_tm`
  (badge sans CT11 : rattrapage) ; `nugget_bridge` (pied du pont) ; `nugget_rocket` (P1–P5 battus) ;
  `route_24_north` (recruteur battu) ; `nugget_sell` (Pépite au Sac, Boutique).

### 2.22 Niveaux : vérification contre la progression attendue

L'outil du J12 (`simulate_mt_moon.gd`) ne peut pas encore tourner : les espèces du J12 et du J13
manquent aux données (il saute alors les étapes, `EXIT_SKIPPED`). **Estimation documentée** (formule
du jeu `exp_calc.gd` : ⌊b × N × 1,5 / 7⌋ contre un Dresseur, b = XP de base moderne ; croissance
« moyenne lente » des starters) depuis l'entrée de la Route 3 du scénario du J12 (meneur Nv. 15) :

| Parcours avant le rival | XP gagnée (meneur seul) | Niveau du meneur (seul / ≈ moitié de l'XP) |
|---|---|---|
| J12 minimal (Hugo, Léa, R1, R3, chercheur, ≈ 15 sauvages) | ≈ 2 900 | **19** / 17 |
| J12 complet (+ 6 Dresseurs facultatifs) | ≈ 4 200 | **20** / 18 |
| + Route 4 (Clara, ≈ 7 sauvages) + Lucas et Diane | ≈ 5 800 | **22** / 19 |

- **Rival 18 / 15 / 17** : un meneur à 19–22 et un second Pokémon à 15–17 arrivent à égalité ou un
  peu au-dessus. Le Roucoups (18, le plus haut) ouvre le combat ; le starter évolué de type avantagé
  vient en dernier. Combat **tendu sans être un mur**, d'autant que la Route 4 et l'Arène (Lucas,
  Diane) offrent de l'entraînement avant lui (rôle voulu par D-1, C-1). **Garder 18 / 15 / 17** (RB).
- **Ondine 18 / 21** : Staross 21 (Bulles d'O, Vitesse de base 115) reste le mur historique,
  surtout pour Salamèche (comme Pierre au J10) ; la Route 24 nord (Mystherbe, Chétiflor, Plante) est
  accessible **avant** Ondine dès le rival battu : préparation possible, jamais une impasse. **Garder
  18 / 21** (RB).
- **Pont 10–18** : en dessous du joueur, croissant ; l'XP du pont (≈ 1 500 au total) prépare Ondine.
  **Garder.**
- **Vérification réelle** (T20, information pour Kevin, aucune donnée changée sans lui) : scénario
  `tools/sim/cerulean_scenario.json` (T9) joué par `simulate_mt_moon.gd -- --scenario …` avec les
  équipes de sortie du scénario du J12, la **vraie partie de Kevin** (`--save`), l'IA qui change, les
  trois starters (rival = trois Dresseurs du scénario, un par starter, si l'outil ne lit pas
  `team_by_starter`) : taux de victoire et durées du rival, d'Ondine, du recruteur.

---

## 3. Tâches

Branche d'intégration **`jalon-13`** (§1.2), une branche par tâche (`j13-t<n>-<sujet>`) ; jamais de
`pkill` ; chaque tâche met à jour `etat-projet.md` dans son commit ; textes **mot pour mot** du §21
et de l'annexe A validée.

#### T0 — architecte : plan (fait)

#### T1 — architecte : kit d'assets série 15 — **maintenant**, après les grilles et vues générales validées
- Fiche `docs/design/fiches-assets/serie-15-azuria.md` (une fiche par asset du §1.4 C : taille,
  emprise, couche, références recadrées des vues validées) ; `tools/art/serie15.py` (`--prompts`,
  `--refs`, `--commandes`, `--planche`, `--manifeste` préparé non lancé, `--controle`) ; prompts des
  personnages (marche + attente) ; choix des modèles d'habitants (règle §0.2 n° 8) ; planche
  `build/art/AZ_KIT_v1.png` (1 case = 48 px, héros à l'échelle).
- Dépend : grilles `j13-grilles` et vues générales validées par Kevin. **CA** : chaque élément visible
  des vues a un asset (réutilisé, varié, nouveau) ou est abandonné explicitement ; aucun fichier de la
  liste §1.2 touché.

#### T2 — constructeur-monde (Mac, Codex) : série 15 → **13.0-art** — **maintenant**, après T1
- Trois générations à la fois, corrections en `_r2` ; repli app ChatGPT si Codex refuse ; planche
  de contact `build/captures/jalon13_assets/` → Kevin. **CA** : images validées ; journal dans la
  fiche ; ni manifeste ni scène.

#### T3 — constructeur-monde (Mac) : décors de combat → **13.0-art** — **Fait, à valider par Kevin**
- `route_4_plaine`, `route_24_pont`, `cerulean_gym_bassin` (§2.18) par la chaîne CB.3. **CA** :
  validés par Kevin sur capture de combat Mac.
- **Fait** : 3 masters 2340 × 1080 (`assets/battle/decors/<id>_back.webp`, ≈ 0,8–1,0 Mo), recette
  CB.3 (composition Codex 1846 × 852, 2 tuiles repeintes, couture, réduction ; scores de recalage
  0,86–0,94, aucune couture visible). Un seul essai (`_r1`) par décor, tous retenus. Prompts :
  `tools/art/combat_decors/prompts/COMBAT_DECOR_{ROUTE4_PLAINE,ROUTE24_PONT,GYM_AZURIA_BASSIN}_r1.txt`
  (sans nom de licence ; refs : `combat-v1`, planche des décors, vue générale Route 3 ou Argenta) ;
  manifeste `tools/art/combat_decors/decors.json`. `data/battle/decors.json` : 3 décors + `places`
  par défaut `route_4` (sas compris), `route_24`, `cerulean_gym` (les cartes viennent aux T7/T8 ;
  tests inchangés). Ligne de sol commune (pieds 1559, 540 / 716, 972), pas de calque de premier plan
  (sol nu dans les coins : choix, comme la Route 3). Captures :
  `build/captures/jalon13_decors/cb3_<id>_{transition,roucool,capacites}.png`.
- **À regarder** : Route 24, l'adversaire pose les pieds au bord de la rivière, au pied du pont
  (le corps recouvre le garde-corps) ; Arène, les bannières portent un emblème rond (motif de
  ligue générique, repeignable) ; arbre en haut à gauche de la Route 24 sous la carte de PV.

#### T4 — Kevin : lot de textes (annexe A) — **maintenant**
- **CA** : validé en une passe ; bloque les données (T11, T17), pas le code.

#### T5 — constructeur-monde (Mac) : intégration de la série 15 — **maintenant**, après T2 et la T6 du J12
- `serie15.py --manifeste` (entrées en fin), `preparer.py` deux fois, règles de décor, scènes d'objets,
  `build_character_frames.gd` (Ondine, Nageur ; en fin), icône Pépite (`preparer_menu.py`). **CA** :
  second passage sans changement ; `test_painted_props` vert ; planche de contrôle relue.

#### T6 — architecte : fondations de l'eau — **maintenant**
- §2.3 : `PaintedGround.water_texture`, `foam_strength` (uniform), rivage sans sable ;
  `tools/cerulean_map_kit.gd`. Tests `test_painted_ground`, `test_ground_mask`. **CA** : tests verts,
  import propre ; diff nul sur les `.tscn` existants (Bourg Palette comprise) ; capture d'essai
  (canal en L sur une carte de test) relue.

#### T7 — constructeur-monde : Azuria et ses intérieurs (sans PNJ) — **maintenant**, après T5, T6 et la T8 du J12
- §2.1, §2.3, §2.5 (cartes), §2.6 (carte) ; cases des PNJ, objets, déclencheurs **réservées** d'après
  la grille ; catalogues (§2.1).
- Tests : `test_cerulean_city` (grille = plan, raccords, eau solide, ponts praticables, Centre premier
  bâtiment de l'avenue, sorties est et sud fermées sans warp, nœuds ≤ 3 000), `test_cerulean_interiors`,
  `test_map_links`, `test_map_catalog`, `test_zone_library` ; captures 2340 × 1080 (arrivée, place,
  canal, Arène, sortie nord) relues contre la vue ; `[perf]` et mémoire.
- **CA** : tests verts ; captures relues ; budgets tenus.

#### T8 — constructeur-monde : Route 4 et Route 24 (sans PNJ) — **maintenant**, après T5, T6 et la T8 du J12
- §2.2 (carte, **test de reprise du sas**), §2.14 (carte), §2.18 ; `build_route_4.gd` réécrit,
  `build_route_24.gd` ; `test_coming_soon` déplacé (Route 25).
- Tests : `test_route_4` (réécrit), `test_route_4_resume`, `test_route_24` (vues du rival et des
  cinq Dresseurs lues sur la grille, pont 2 cases, raccords, nœuds) ; captures.
- **CA** : tests verts ; reprise du sas verte sur **toutes** ses cases praticables.

#### T9 — architecte : scénario de simulation — **maintenant**
- `tools/sim/cerulean_scenario.json` (Route 4, Clara, Lucas, Diane, rival × 3 starters, Ondine, P1–P5,
  recruteur ; variantes « directe », « avec Route 24 nord ») ; `--valider` passe (étapes manquantes
  signalées). Lancé au T20.

#### T10 — architecte : alignement — **après la clôture du J12**
- Fusionner `main` (J11 + J12) dans `jalon-13` ; réaligner §0, §2.9, §2.11, §2.13, §2.15, §2.19 sur le
  code réel (`_foe_action`, verrous de combat, `confirm_cutscene`, `unless_flags`, `field_use`, `trap`
  et ses messages, toast CT, compte des capacités, version) ; écarts notés ici (§0.4 à créer).

#### T11 — architecte : données — après T10, T4
- §2.15 (9 espèces, 8 capacités, Pokédex, CT, `tm11`, `nugget`, sprites provisoires). **CA** : tests
  verts ; aucune carte touchée.

#### T12 — architecte : IA qui change de Pokémon — après T11
- §2.11 (règle, IA, `Battle`, texte, `TrainerData.switch`). **CA** : tests verts ; `simulate_brock.gd`
  identique ; Pierre et le rival n° 2 inchangés.

#### T13 — ui-mobile : rappel adverse à l'écran — après T12
- §2.11 (présentation) ; captures relues (rappel, envoi, carte). **CA** : `game/ui/battle/` et
  `battle_director.gd` seuls touchés.

#### T14 — constructeur-monde : carte `qa_switch_j13` + départ `switch_qa` — après T12
#### T15 — qa-mobile : **session 13.0** → Kevin
- Départ `switch_qa` : changement adverse vu (message n° 60, animation, une fois au plus, jamais
  piégé ni en Patience, jamais pour le témoin), 9 espèces au Pokédex, Vol-Vie, Bulles d'O, Acide.
  **CA** : rapport `build/qa/jalon13_t15/` ; validation de Kevin.

#### T16 — architecte : briques du monde — après T10
- §2.8 (`RivalMoment`, `moment: "win"`), §2.9 (`next`), §2.13 (`confirm_set` / `cancel_set`).
  **CA** : tests verts ; rivaux n° 1 et n° 2, Pierre, Sbires et fossiles du J12 inchangés.

#### T17 — constructeur-monde : la vie de la Route 4 et d'Azuria (13A) — après T11, T7, T8
- §2.2 (vie), §2.4, §2.5, §2.6 (Dresseurs et guide), §2.14 (Route 4), §2.16 (`get_cascade_badge`),
  zone et Grand moment d'arrivée, départs `route_4`, `cerulean_city`. Tests `test_route_4_life`,
  `test_cerulean_life`, `test_cerulean_gym_trainers`, `test_shop_sell`. **CA** : tests verts, captures.

#### T18 — qa-mobile : **session 13A** → Kevin
- Partie sauvegardée **dans le sas** (vraie partie du J12 ou départ) rechargée → même case ; rebord
  (une fois en bas, pas de retour) ; Clara évitable ; Azuria : titre, Centre premier bâtiment, point de
  repos, Boutique (achat, **vente**), vélos, maison, cambriolage (porte, clôture, aucun marqueur),
  Lucas et Diane évitables et combattables, guide ; eau lisible ; fps, mémoire.

#### T19 — constructeur-monde : rival, Ondine, badge, CT11 (13B) — après T16, T17, T12
- §2.7, §2.9, §2.10 ; départs `rival_cerulean`, `rival_cerulean_weak`, `misty_pending`,
  `cerulean_gym`, `cascade_no_tm`. Tests `test_rival_cerulean`, `test_route_24_misty`,
  `test_cutscene_chain`, `test_misty_sequence`, `test_save_j13`. **CA** : tests verts, captures.

#### T20 — architecte : équilibrage — après T19
- §2.22 : simulation ; **information pour Kevin**, aucune donnée changée sans lui.

#### T21 — qa-mobile : **session 13B** → Kevin
- Rival inévitable, défaite → Centre (sans argent perdu) → n° 30 puis n° 31, victoire → départ,
  **un seul** Grand moment ; Ondine au pont, invitation, départ ; **fermeture forcée** entre les deux
  scènes → reprise ; Arène : guide, Ondine (carte, changement de Pokémon), défaite → reprise n° 36,
  victoire → « BADGE CASCADE », écran Dresseur, CT11 (Sac CT, apprentissage) ; rattrapage.

#### T22 — constructeur-monde : Pont Pépite, recruteur, Route 24 nord, fin (13C) — après T19
- §2.12, §2.13, §2.14 (nord), §2.16 (deux entrées) ; **retrait de `qa_switch_j13`** et de son départ ;
  README des départs. Tests `test_nugget_bridge`, `test_nugget_rocket`, `test_route_24_life`,
  `test_hidden_items` (Route 24), `test_objective_library`.

#### T23 — qa-mobile : **QA finale 13C** → Kevin, fusion
- Pont (cinq inévitables, défaite au milieu), recruteur (OUI puis, sur une autre partie, NON ; Pépite ;
  défaite → reprise sans choix), espace nord, Antidote caché, « ROUTE 25 — À venir » ; **vraie partie
  de Kevin**, sans drapeau de débogage : sas → Route 4 → Azuria → rival → Ondine → pont → vente de la
  Pépite ; sauvegarde relue par l'APK final. **CA** : rapport `build/qa/jalon13_t23/` ; validation de
  Kevin ; fusion de `jalon-13` dans `main` (copie d'intégration ; `project.godot` et filtre d'export
  vérifiés).

#### T24 — architecte : clôture
- `etat-projet.md`, roadmap (rival n° 3 fait) ; passation au J14 : `route_25` / `from_route_24`
  (raccord est de la Route 24, repère de coordonnées), jardin et trou de la maison cambriolée
  (poursuite du J14), sortie sud d'Azuria (raccord « ROUTE 5 — À venir » du J14), dos peints des 9
  espèces, IA qui change disponible pour les Dresseurs suivants (`switch: true`).

---

## 4. Critères d'acceptation par sous-jalon

**13.0-art** — Kevin valide les planches de contact (décors, Ondine, Nageur, icône, décors de combat) ;
chaque asset a sa fiche ; grilles et vues générales validées avant toute carte.

**13.0** — Ondine d'essai et rival d'essai **changent au plus une fois** quand la règle le dit
(« {Dresseur} rappelle {Pokémon} ! », rappel visible, puis envoi) et jamais sinon ; le tour du
changement, le Dresseur n'attaque pas ; le Pokémon rappelé revient avec ses PV ; le Dresseur témoin ne
change jamais ; Vol-Vie rend des PV ; Bulles d'O et Acide baissent leur statistique (parfois) ; les 9
espèces au Pokédex ; ≥ 55 fps en combat ; Pierre, rival n° 2 et Sbires inchangés ; tests verts, import
propre.

**13A** — une partie sauvegardée dans le sas se recharge sur la même case ; rebord à sens unique ;
Clara évitable, Poké Ball ; herbes de la Route 4 (5 espèces) ; titre « AZURIA », Grand moment
d'arrivée, objectif « obtenir le Badge Cascade. » ; Centre = premier bâtiment de l'avenue, toast
« Point de repos enregistré — Azuria » ; Boutique : stock du §2.5, **VENDRE** ; vélos : 1 000 000 ₽,
rien à acheter ; maison ; cambriolage : ruban, clôture, H3, H4, aucun marqueur ; sorties est et sud
fermées ; eau jamais praticable ; Lucas et Diane évitables et combattables avant le rival ; guide
n° 21 ; ≥ 58 fps moyens, creux ≥ 50 ; nœuds ≤ 3 000 ; mémoire « carte + voisines ».

**13B** — rival **impossible à contourner** ; défaite → Centre, aucun argent perdu, rival en place ;
n° 30 au premier retour, n° 31 ensuite, jamais l'introduction ; victoire → n° 32, départ, **un seul**
Grand moment `rival_battle` (aucun pour les défaites) ; Ondine s'approche, n° 33, part ; fermeture
forcée entre les scènes → rival absent, scène d'Ondine rejouée au pied du pont ; Arène : guide n° 22,
Ondine présente, carte « ONDINE », changement de Pokémon possible, défaite → n° 35 → Centre → n° 36 ;
victoire → « BADGE CASCADE », vibration, badge dans l'écran Dresseur, Grand moment « badge », CT11
(toast « obtenue », Sac CT, apprentissage) ; partie badgée sans CT → « J'allais oublier. » ; H5 et
guide réagissent au badge, personne d'autre.

**13C** — P1–P5 inévitables dans l'ordre, chacun annonce son rang ; défaite au milieu → battus gardés ;
recruteur : félicitations, **Pépite** (une seule), proposition, OUI → n° 51, NON → n° 52, même combat ;
défaite → Centre, Pépite gardée, reprise n° 55 sans choix ; victoire → n° 53, départ, espace nord
ouvert ; Antidote caché (bouton face à l'indice seulement) ; Potion ; « ROUTE 25 — À venir »
(développement) ; objectifs « traverser le Pont Pépite. » puis « explorer les environs d'Azuria. » ;
Pépite vendue 5 000 ₽ ; carte de QA retirée ; **vraie partie de Kevin** sas → pont sans régression
(J1–J12 sur les points de contrôle) ; sauvegarde relue par l'APK final (version inchangée) ;
`tools/test.sh` vert, import propre ; budgets tenus.

---

## 5. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Le J12 (et le J11) tardent** | tout le code du J13 attend | « maintenant » = art, fondations de l'eau, cartes sans combat, scénario (§1.2) ; `jalon-13` prête le jour de la clôture |
| **Le J12 livre autre chose que son plan** (`confirm_cutscene`, objets cachés, `trap`, AVENTURE) | briques du §2.13, Antidote caché, Claquoir, Pépite désalignés | T10 réaligne ; replis du §0.3 |
| **Conflits `jalon-12` ↔ `jalon-13`** (manifeste, catalogues, `build_route_4.gd`) | fusions pénibles | `jalon-13` depuis `jalon-12`, fusions fréquentes dans un seul sens, tâches « carte » après la T8 du J12 |
| **Partie sauvegardée dans le sas sur une case devenue solide** | joueur coincé | grille qui contient le sas ; `test_route_4_resume` sur **toutes** les cases |
| **Eau trop chère ou plate** | fps, rendu | eau dans la passe du sol (aucun nœud, aucune lecture d'écran), reflets peints ; mesure dès T7 |
| **Mémoire de la Route 4** (B2F + Azuria) | creux, changements lents | mesure (§2.20) ; préchargement réduit |
| **Pont de 2 cases contournable** | Dresseur évitable par erreur | grille + `plan_check` + test sur la vraie scène avec PNJ |
| **IA qui change trop ou mal** | combats frustrants ou injustes | une fois au plus, règle déterministe testée aux bornes ; témoin sans `switch` ; simulation (T20) |
| **Rival trop dur pour un joueur sans Centre d'Azuria** | retraversée du Mont Sélénite | accepté (D-2) ; Centre premier bâtiment ; Route 4 et Arène pour s'entraîner |
| **Salamèche face à Carabaffe puis Ondine** | double mur | Route 24 nord (Plante) accessible avant Ondine ; mesuré au T20, information pour Kevin |
| **Fermeture pendant une scène** (recruteur, rival) | combat rejoué | régime existant (rien n'est perdu ni doublé) ; la seule sauvegarde intermédiaire voulue (entre rival et Ondine) passe par `next` |
| **Codex refuse Ondine, le Sbire ou une piscine** | délai d'art | repli app ChatGPT (série 09) ; prompts sans marque |

---

## 6. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Validations | 13.0-art sur planches ; 4 sessions téléphone (13.0, 13A, 13B, 13C) |
| Branches | `jalon-13` depuis `jalon-12` (Q-1) ; fusion de `main` au T10 |
| Identifiants | `route_4`, `cerulean_city`, `cerulean_center`, `cerulean_mart`, `cerulean_gym`, `cerulean_bike_shop`, `cerulean_house`, `route_24` ; Dresseurs `route_4_clara`, `cerulean_gym_lucas/diane/misty`, `rival_cerulean`, `route_24_timeo/alice/malo/romane/ethan`, `nugget_rocket` |
| Drapeaux ajoutés | `rival_cerulean_retried` (reprise n° 31), `nugget_rocket_yes` (choix sans conséquence), `cerulean_neighbor_talked` (H3) |
| Eau | rivage existant, texture de canal réglable, écume 0 sur les quais, ondulation de la mer de Bourg Palette |
| Rival | 595 ₽ ; le joueur garde son Sac ; départ vers la ville au fondu ; moment à la victoire seulement |
| Ondine | `interior_warm` dans l'Arène ; carte sans portrait (Q-2) ; scène de reprise par déclencheur au pied du pont et en lui parlant |
| IA qui change | faiblesse = types du Pokémon du joueur ≥ ×2 ; PV ≤ 25 % ; candidat > 50 % sans faiblesse ; premier dans l'ordre ; une fois par combat ; jamais en Patience ni piégé |
| Dresseurs | réplique « après » = « battu » quand le §21 n'en donne pas ; montants fixes |
| Capacités | 8 nouvelles (learnsets RB complets) ; Acide du J12 (Déf. Spé.) ; Cascade : apeurement 20 % ; Soin et Danse Fleur en attente |
| Espèces | évolutions vers des espèces absentes non déclarées (Hypocéan, Poissoroy, Rafflesia, Empiflor) ; dos provisoires |
| Rencontres | tables du §2.14 (taux 25, rampe 15 → 20) |
| Cambriolage | planche, pot, trou : décor seul ; porte et clôture examinables |
| Vélos | vendeur `clerk`, vélos en décor non examinables |
| Habitants | modèles génériques, aucun personnage nommé d'une autre ville ; H5 en `lass` |
| Budgets | ≤ 3 000 nœuds ; ≥ 58 fps moyens, creux ≥ 50 ; « carte + voisines » ≤ 64 Mo |
| Sauvegarde | v6, aucune nouvelle |

---

## 7. Questions pour Kevin

> **Réponses de Kevin (2026-10-11) : les trois recommandations retenues** — Q-1 oui (tâches « maintenant » lancées sur `jalon-13`, créée depuis `jalon-12`) ; Q-2 pas de portrait d'Ondine au J13 ; Q-3 annexe A validée.

Le dossier 16 tranche tout le reste ; seules ces trois décisions bloquent.

- **Q-1 — Lancement avant la clôture du J12.** D-16 met le **code** après le J12 et laisse l'art
  avancer. Ce plan fait partir aussi, sur une branche `jalon-13` **créée depuis `jalon-12`** et
  jamais fusionnée dans `main` avant la fin du J13 : le kit et l'art (T1–T3, T5), les fondations de
  l'eau (T6), les **cartes sans combat** d'Azuria, de ses intérieurs, de la Route 4 et de la Route 24
  (T7, T8 : décor, eau, raccords, test de reprise du sas, sans PNJ ni données) et le scénario de
  simulation (T9). *Recommandation : oui (comme Q-1 du J12) — c'est ce qui permet de juger l'eau et
  le budget d'Azuria sur captures bien avant 13A ; rien n'entre dans `main` avant la fin du J13.*
- **Q-2 — Portrait d'Ondine.** Le dossier 16 (§15.3) prévoit « planche + portrait de carte », mais
  la carte de Champion n'affiche **aucun portrait** (décision du J10 : nom et titre seuls, Pierre
  compris), et aucun écran n'en montre hors de l'ouverture. *Recommandation : pas de portrait au J13
  (carte identique à celle de Pierre) ; le prompt reste prêt en conditionnel. Alternative : un
  portrait sur la carte pour **tous** les Champions (changement d'interface, portrait de Pierre à
  produire aussi).*
- **Q-3 — Lot de textes de l'annexe A** (non couverts par le §21) : 9 descriptions et 6 notes de
  Pokédex, descriptions de 7 capacités, textes du Claquoir, zones (Azuria, Route 24), Grand moment
  d'arrivée à Azuria. *Recommandation : relecture en une passe ; bloque les données (T11, T17), pas le
  code.*

**À fournir par Kevin** (pas une question) : la sauvegarde de sa vraie partie à la fin du J12 (équipe,
niveaux) pour la simulation (T20) et la QA de reprise du sas (T18).

---

## 8. Premières tâches à lancer maintenant (si Q-1 est accepté)

1. Attendre la validation des **grilles** (`j13-grilles`) et des **vues générales** par Kevin.
2. Créer **`jalon-13` depuis `jalon-12`** dans une copie dédiée.
3. **T1** (kit série 15) → **T2** (Codex, Mac) → planche de contact pour Kevin.
4. En parallèle : **T3** (décors de combat), **T6** (fondations de l'eau), **T9** (scénario) ; Kevin
   relit l'annexe A (**T4**).
5. Après T2 et la T6 du J12 : **T5** ; après T5, T6 et la T8 du J12 : **T7** ∥ **T8**, captures
   relues sur Mac.
6. **À la clôture du J12** : T10 (alignement), puis la chaîne 13.0 → 13A → 13B → 13C.

---

## Annexe A — Textes à valider par Kevin (Q-3)

Conventions des lots précédents : bulles de 2 lignes de ~40 caractères, `[e]` = forme au féminin du
Pokémon (`text_f`). Ton du Pokédex : carnet de terrain, ce qui s'observe, aucun secret dévoilé ;
une note seulement pour les formes de base.

### A.1 Pokédex (taille, poids officiels ; description ; note des formes de base)

| Espèce | Taille / poids | Description | Note |
|---|---|---|---|
| Stari | 0,8 m / 34,5 kg | « Le cœur rouge de son corps brille faiblement dans le noir. Les nuits calmes, on le voit scintiller au bord de l'eau comme une étoile tombée. » | « Il se colle aux pierres des quais quand l'eau est tranquille, et disparaît au premier remous. » |
| Staross | 1,1 m / 80,0 kg | « Son joyau central change de couleur selon la lumière. Il nage en tournant sur lui-même, si vite qu'on le perd des yeux. » | — |
| Hypotrempe | 0,4 m / 8,0 kg | « Il nage bien droit et s'accroche aux algues avec sa queue quand le courant forcit. Menacé, il crache un nuage d'encre noire. » | « On le voit parfois flotter immobile juste sous la surface, comme s'il guettait quelque chose. » |
| Kokiyas | 0,3 m / 4,0 kg | « Sa coquille épaisse se referme d'un coup sec au moindre danger. Quand il se croit seul, il laisse dépasser sa longue langue. » | « Au fond des canaux, il reste à moitié enfoui dans le sable, la coquille entrouverte. » |
| Poissirène | 0,6 m / 15,0 kg | « Ses nageoires ondulent comme un voile dans le courant. Sa corne fend l'eau quand il remonte la rivière. » | « Au printemps, ils remontent le courant en bancs et sautent par-dessus les petites chutes. » |
| Mystherbe | 0,5 m / 5,4 kg | « Le jour, il s'enfouit dans la terre et ne laisse dépasser que ses feuilles. La nuit, il se met à marcher. » | « Une touffe de feuilles au milieu du chemin, qui n'y était pas la veille : c'est souvent lui. » |
| Ortide | 0,8 m / 8,6 kg | « Une odeur âcre flotte autour de lui. Le nectar collant qui coule de sa bouche fait fuir presque tout le monde. » | — |
| Chétiflor | 0,7 m / 4,0 kg | « Son corps fin comme une tige plie au vent sans jamais se rompre. Il attrape ce qui passe avec ses longues lianes. » | « Il se balance doucement au bord des herbes, puis se fige net dès qu'on approche. » |
| Boustiflor | 1,0 m / 6,4 kg | « Il se suspend aux branches par le crochet de sa tige. Le liquide qu'il garde dans sa bouche ronge presque tout. » | — |

### A.2 Capacités ajoutées (description)

Bulles d'O : §21 n° 59 (« Projette des bulles avec force. Peut baisser la Vitesse. ») ; Acide : J12
(validé). Nouvelles :
Vol-Vie « Aspire l'énergie de la cible. Le lanceur récupère la moitié des dégâts infligés. » ·
Soin « Le lanceur récupère la moitié de ses PV. Sans effet dans le moteur actuel. » ·
Claquoir « La cible est prise entre deux coquilles pendant quelques tours. » ·
Onde Boréale « Un rayon aux couleurs de l'aurore frappe la cible. Peut baisser son Attaque. » ·
Laser Glace « Un rayon glacé frappe la cible. Peut la geler. » ·
Cascade « Le lanceur fonce sur la cible dans une gerbe d'eau. Peut l'apeurer. » ·
Danse Fleur « Le lanceur attaque dans une pluie de pétales. Sans effet dans le moteur actuel. »

### A.3 Combat

- Claquoir (piège du J12, messages par capacité) : « {pokemon} est pris[e] dans le Claquoir ! » ·
  « {pokemon} souffre du Claquoir ! » (libération : « {pokemon} est libéré[e] ! », J12).
- Rappel par l'IA : §21 n° 60 (validé).

### A.4 Zones (Carte, Pokédex) et Grand moment

- Azuria — description « Une ville claire traversée de canaux, entre la montagne et le cap. Partout,
  on entend l'eau couler. » (le titre et le sous-titre de zone sont au §21 n° 5).
- Route 24 — sous-titre « Le Pont Pépite » (§21 n° 56) ; description « Au nord d'Azuria, un long pont
  franchit la rivière. Au-delà, une prairie tranquille où l'herbe pousse haut. »
- Route 4 — inchangée (annexe A du J12 : « Le versant est du Mont Sélénite. La route descend vers la
  plaine, en direction d'Azuria. »).
- Grand moment d'arrivée (`zone_arrivals.cerulean_city`) : titre « Arrivée à Azuria » · détail « Une
  ville d'eau et de lumière. »
