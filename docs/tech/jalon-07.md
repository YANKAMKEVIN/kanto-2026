# Jalon 7 — Jadielle, le premier hub

> Objectif jouable sur le S24, sous-jalon par sous-jalon, dans l'ordre du dossier 09 (J7A puis J7B).
>
> **7A.0 — La sauvegarde v3 (validée seule).** La vraie partie de Kevin (fin du J6) passe en version 3 sans rien perdre : elle reçoit **3 000 ₽** et retrouve la **première espèce sauvage rencontrée en combat** (pour la réplique de Chen). Un APK du J6 refuse le fichier sans jamais l'écraser.
>
> **7A.1 — Jadielle.** Au nord de la Route 1, la végétation sauvage cède la place à des haies taillées, puis aux premiers toits : « JADIELLE ». **À la première arrivée seulement** (≤ 4 s, sans texte) : un enfant traverse en courant derrière son Rattata, le Roucool posé sur le toit de la Boutique s'envole, un voyageur venu du nord croise le joueur. Puis la ville vit : livreur qui entre à la Boutique, Dresseuse et son Roucool près du banc, vieil homme qui fait les cent pas, habitant devant l'Arène fermée (« La porte est verrouillée. »). Sortie nord : « ROUTE 2 — À venir ». **Art final** (séries 01 à 05 du prototype), lumière **C2** portée par Godot, 60 fps.
>
> **7A.2 — Le Centre Pokémon.** L'infirmière : « Bonjour. Je m'occupe de ton équipe ? » et deux grandes cartes **SOIGNER / PAS MAINTENANT**. Le rituel dure ~3 s, « Voilà. Tout le monde est en pleine forme. », toast « Point de repos enregistré — Jadielle », sauvegarde. Perdre un combat sauvage ramène désormais **ici**, plus chez Maman (qui soigne toujours).
>
> **7A.3 — La Boutique et l'économie.** À la première visite, le marchand reconnaît le Pokémon de Chen et confie le **colis** (« COLIS POUR CHEN — ajouté aux objets clés ») ; l'objectif du menu devient en silence « remettre le colis au Professeur Chen ». Ensuite : ACHETER / VENDRE dans le langage du Sac, total calculé au doigt, « Merci ! ». L'argent apparaît dans la Boutique, le Sac et l'écran Dresseur.
>
> **7A.4 — Le Stockage Pokémon.** Au terminal du Centre (et depuis l'Équipe quand on est dans un Centre) : ÉQUIPE · STOCKAGE, DÉPOSER, REPRENDRE au glisser **ou** par sélection, FAVORI, LIBÉRER (menu secondaire, confirmation). Le dernier Pokémon ne part jamais ; un favori ne se libère pas.
>
> **7A.5 — Le Pokédex de Chen.** De retour au labo, le joueur remet le colis ; Chen remarque ce qui est déjà enregistré (« Un Rattata… Tu n'as pas perdu de temps. »), **POKÉDEX ACTIVÉ** : la 6e carte du menu existe, et **tout ce que le joueur a déjà vu y est**. Le rival entre, reçoit le sien, repart.
>
> **7B.1 — La Route 22.** Vers l'ouest depuis Jadielle : relief, falaise et escalier, herbes hautes peintes, Piafabec, Férosinge, Nidoran ♀ et ♂ ; au bout, la vue sur le Plateau Indigo, sans passage.
>
> **7B.2 — Le rival n° 2.** Seulement après l'activation du Pokédex : on le voit finir un combat contre un jeune Dresseur, il remarque le joueur, combat (IA de **niveau 2**, SAC permis). Victoire : argent et répliques ; défaite : fondu, réveil au dernier Centre. Trois états mémorisés.
>
> Pas de marqueur, pas de « OBJECTIF MIS À JOUR », pas de PNJ guide, pas de « niveau recommandé ».

**Pré-requis** : le **jalon 6 validé par Kevin (T30, `2f7da20`) et fusionné dans `main`** (`d44077d`) — **fait**. Branche `jalon-07` créée depuis `8716088` (J6 + ce plan + art du héros peint ; aucun changement de `game/` ni de `data/` entre `2f7da20` et `8716088`). Ce plan a été écrit sur `jalon-06` à `5beb353` (2133 tests) ; **aligné au T0 sur le code réel** (§0 ci-dessous, 2244 tests au départ du J7). **Chaque tâche d'architecture commence encore par aligner ce plan sur le code du moment** (comme les §15 des jalons 5 et 6).

## 0. Écarts constatés au T0 (alignement sur `8716088`)

Le code du J6 a bougé après `5beb353` (T28, T29, T30, correctif `TapGuard`) : 44 fichiers de `game/`, `boot.gd` passe de 824 à **921 lignes**. Ce qui change pour ce plan :

1. **`ChoiceCards`** (`game/ui/components/choice_cards.gd`, livré au T28) n'a **qu'un signal**, `chosen(confirmed: bool)` (et non `confirmed` / `cancelled`), un seul par question ; `show_choice(view: ChoiceView)`, `hide_choice()`, `is_showing()`. Il pose un **voile plein cadre** (82 %) qui intercepte le toucher et **ne gère pas le retour Android** (celui qui le montre décide). Précédent d'emploi : `BattleDirector._confirm_forget` (le crée à la demande sur le calque de la HUD, attend `chosen`, le libère). Conséquences au §6.2 et au §6.5 : `chosen(bool)` → `DialogueRunner.choose(bool)` ; le voile couvre la boîte de dialogue, donc **la question passe dans `ChoiceView.title`** (comme OUBLIER / GARDER, validé au T30) et la boîte reste ouverte derrière (défaut, à confirmer au T6/T7 sur capture). `tests/helpers/fake_choice_cards.gd` existe déjà pour les tests de câblage.
2. **`ChoiceView`** (`game/systems/menu/views/choice_view.gd`) : `title`, `detail`, `confirm_label`, `confirm_detail`, `cancel_label`, `cancel_detail`, constructeur `ChoiceView.new(question, confirm, cancel)`. `DialogueChoice.to_view(question)` le construit tel quel (§3.3).
3. **`TapGuard`** (`game/ui/components/tap_guard.gd`, `TapGuard.attach(bouton)`, seuil `UiTokens.TAP_SLOP` = 24 px) : **tout bouton d'une liste qui défile** au J7 (stock de la Boutique, grille du Stockage) l'utilise, avec `scroll_deadzone = TAP_SLOP` et des filtres de souris en PASS (défaut validé au T30). Ajouté aux CA du T11 et du T15. Doigt simulé pour les tests : `tests/helpers/touch_finger.gd`.
4. **Réglages (6F)** : `GameSettings`, `SettingsStore` (fichier **séparé** `user://settings.json`, version propre ; **hors du format de sauvegarde v3**), `Haptics` (`game/systems/settings/haptics.gd`, `Haptics.vibrate(ms)` : **seule porte** des vibrations, un test interdit tout appel direct), `GraphicsProfile`, `UiPrefs`, `UiPrefsApplier` (`game/ui/theme/`, à appliquer aux écrans nouveaux du J7 : Boutique, Stockage, comme aux écrans du menu). « Réduire les animations » = `GameSettings.reduce_motion` (le ×0,5 du rituel du Centre suit `REDUCED_MENU_SPEED` = 0,5).
5. **« Économie » coupe bien plus que le §7 ne le disait** : `GraphicsProfile` Économie = **30 images/s** (`ECO_MAX_FPS`), flou du menu coupé, `reduced_effects` vrai. La lumière C2 lit `reduced_effects` (vent et liseré coupés). **Les mesures de fps du §7 se font en Auto (Élevée sur le S24)**.
6. **« Confirmer certaines actions »** (`GameSettings.confirm_actions`, désactivé par défaut) n'agit au J6 que sur l'oubli d'une capacité. Au J7 : **défaut = n'ajoute rien** (achat sans seconde confirmation, dossier 09 §9 ; vendre un favori et LIBÉRER sont **toujours** confirmés). Petite question notée, pas bloquante.
7. **`MenuDirector`** : `setup(...)` a gagné `moments`, `illustration`, `set_settings`, `change_setting`, signaux `map_*`, `trainer_shown`, `settings_*`, `save_result_shown`. Les routes SHOP / STORAGE (T10, T14) s'ajoutent sur le même modèle (signal `*_shown(view)`, branchement de `Boot` derrière `has_signal`). `MenuNavigator.open(route)` n'a toujours qu'un paramètre (le `standalone` du §2.3 reste à faire au T10).
8. **`MapJournal`** (`view(state, zones, illustration, …)`) et **`TrainerSummary.build(state, data, zones, moments, …)`** existent comme prévu ; la statistique « Captures » est de carrière (somme des `times_caught` moins le starter) : libérer au Stockage ne la fait pas baisser, **sans champ de sauvegarde**.
9. **Sauvegarde** : identique à `5beb353` (v2). **Rattrapage de la première espèce sauvage corrigé** : le §5.1 supposait que la Route 1 était la seule carte de combat sauvage ; or la table `route_1_grass` couvre aussi **`pallet_town`** (l'herbe au nord du bourg, depuis le 5B : la vraie partie v1 de Kevin a capturé son Roucool à Bourg Palette), où OBSERVER (J6, T16) marque aussi « vu ». La règle est réécrite au §5.1.
10. **Fixture v2** : aucune copie de la partie de Kevin **en fin de J6** n'existe sur le Mac (les QA du J6 après le T1 ont tourné avec des départs de débogage, qui ne lisent ni n'écrivent la sauvegarde, ou sans relevé du fichier). La fixture `tests/fixtures/save/v2_kevin_j6.json` est la **vraie partie v2 de Kevin relevée au T1 du J6** (`build/qa/jalon06_t1/save_v2_apres_t0.json`, copie telle quelle). Le T1 relève le fichier de fin de J6 (étape 1) et, s'il diffère, le **remplace** dans la fixture et relance les tests (§5.1.1).
11. Pas d'autre écart : `BattleViews.TRAINER_BATTLE_ACTIONS`, `EncounterDirector._handle_defeat` / `_WAKEUP_DIALOGUE = mom_wakeup`, `DialogueVariant.heal`, `CutsceneStep.Kind` (12 sortes, `GIVE` en dernier), `DebugStart` (ni `money` ni `storage`), `PerfCounter` (`[perf] fps= min= draw=`) sont tels que le plan les décrit.

**Hors périmètre** (dossier 09, règle de déblocage, règle « une couche à la fois ») :
- **Route 2, Forêt de Jade** (J8, J9) : la sortie nord mène à « ROUTE 2 — À venir » (build de développement), inerte en release.
- **Arène ouverte, Giovanni, badges** (J10 et plus tard) : l'Arène est fermée, sans calendrier.
- **Statuts** (poison…), **évolutions jouables**, **CT**, **changement de Pokémon en combat** (J11) : les capacités de poison des nouvelles espèces gardent leur effet en attente (`pending_effects`, comme Poudre Toxik aujourd'hui).
- **Indication « Efficace / Peu efficace »** en combat (dossier 05 §5) : rien au J7, même après l'activation (Q-12).
- **Recherche et filtres du Stockage**, boîtes multiples (dossier 09 §8 : reportés).
- **Jour/nuit, météo** (phase 10) : la lumière C2 est posée en **profils de données** pour que le jour/nuit n'ait plus qu'à les interpoler (§6.7), mais aucune horloge n'est écrite.
- **Continuité physique des PNJ entre cartes** (dossier 09 §2 : V1 = le PNJ marche jusqu'à la porte et disparaît).
- **Remplacement de Maman et de Chen par des sprites peints** : phase DA. **Le héros et le rival sont peints dès le J7** (Q-1 tranchée par Kevin, option (b)).
- **Repeindre Bourg Palette, la Route 1 et les intérieurs existants** : phase DA (Q-3).
- Rendu final des écrans (Boutique, Stockage) : provisoires aux dimensions finales (`CLAUDE.md` règle 3).

Références : `CLAUDE.md` (règles 1 à 10, décisions techniques : personnages **peints**, 128 px à 1:1, filtre `linear`), `docs/design/vision.md` (règle de déblocage), `roadmap.md` (phase 4), **`dossier-09-jadielle.md`** (source de vérité : §0 à §20, références visuelles et leurs arbitrages, décisions verrouillées), `dossier-08-menu-dresseur.md` (§1, §2, §3, §6, règle 5), `dossier-05-combat.md` (§19, §23), `dossier-06-progression.md` (§6), `dossier-07-route-1.md` (§5, §11, §12), `cahier-art-monde-v0.1.md` (§1.3 ADN, §2 contraintes, §4 personnages, méthode C), `fiches-assets/serie-01-place-jadielle.md` (journal des séries 01 à 05, calibration C2, collisions du prototype), prototype jetable `proto/da-jadielle:proto/da_jadielle/` (shaders et `emprises.gd`), [`jalon-05.md`](jalon-05.md) §16, [`jalon-06.md`](jalon-06.md) §5.1 (protocole de migration), §6.12 (`ChoiceCards`), skills `godot-conventions`, `world-tiles`, `ui-theme-2026`.

---

## 1. Découpage

| | 7A.0 Sauvegarde v3 | 7A.1 Jadielle | 7A.2 Centre | 7A.3 Boutique | 7A.4 Stockage | 7A.5 Chen | 7B.1 Route 22 | 7B.2 Rival n° 2 |
|---|---|---|---|---|---|---|---|---|
| Couche nouvelle | argent, première rencontre sauvage, migration | **art final + lumière C2** (pipeline, sol peint, props peints, PNJ peints), habitants, micro-scène | choix à deux cartes dans un dialogue, actions de dialogue, point de repos, réveil généralisé | prix, Boutique, colis, objectif | règles du Stockage, écran | jetons de dialogue, étapes caption / take, activation | 10 espèces, rencontres, herbes peintes, relief | IA niveau 2, gains, SAC contre les Dresseurs, réveil après un Dresseur |
| Visible sur le S24 | la partie de Kevin reprise | marcher dans Jadielle | se soigner, perdre et se réveiller au Centre | acheter, vendre | déposer, reprendre, libérer | le Pokédex apparaît | explorer, rencontrer, capturer | le combat et ses suites |
| Validation S24 | **T1, seule** | T5 | T9 | T13 | T17 | T20 (+ QA du J7A) | T23 | T26 (+ QA finale du J7) |

Pourquoi ce découpage :
- **Une fonctionnalité → testée sur S24 → validée → suivante** (règle 1). Le J7A compte six validations, le J7B deux ; **le J7B ne commence qu'après la validation du J7A** (dossier 09 §0).
- **La sauvegarde v3 est validée seule** (système à risque) et **une seule fois pour tout le J7** : elle porte au T0 tous les champs du J7A **et** du J7B (le J7B n'ajoute que des drapeaux d'histoire, qui ne changent pas le format).
- **7A.1 porte le changement le plus lourd du jalon : le passage de l'art du prototype à la production.** Il est validé sur une seule carte (Jadielle extérieure), sans autre système, avec des mesures de performance. Les intérieurs (7A.2, 7A.3) et la Route 22 (7B.1) réutilisent ensuite le même pipeline.
- **Le Centre avant la Boutique** : le choix à deux cartes et les actions de dialogue y naissent ; la Boutique les réutilise (vendre un favori). L'ordre de visite du joueur reste libre (dossier 09 §4).
- **Le Stockage avant Chen** : il ne dépend pas du Pokédex ; 7A.5 clôt le J7A par la scène narrative et la QA « joueur » de tout le J7A sur la vraie partie, **sans drapeau de débogage**.
- **Le rival n° 2 seul (7B.2)** : il porte le seul changement du moteur de combat du J7 (IA niveau 2, gains, SAC par dresseur), validé à part de la carte.

Chaque sous-jalon ne commence qu'une fois le précédent **validé par Kevin**. Pendant la QA d'un sous-jalon, l'architecte prépare les fondations pures du suivant (§8).

---

## 2. Ce qui existe déjà (code réel, `jalon-06` à `5beb353`, aligné au T0 sur `8716088` : §0) et ce que le J7 réutilise

### 2.1 Faits et données déjà en place

| Besoin du J7 | Où, dans le code | Ce qui manque |
|---|---|---|
| Pokédex activé (drapeau) | `StoryFlags.POKEDEX_ACTIVATED` ; lu par `MenuUnlocks.pokedex_visible()`, `BattleDirector` (carte de capture), `Boot._on_flag_changed` | **la scène qui le pose** (7A.5) |
| Données du Pokédex collectées depuis le J5 | `Pokedex`, `PokedexEntry` (vu, capturé, cartes, dates, notes), `PokedexUpdates`, `PokedexNotes` | rien : elles apparaissent à l'activation |
| Point de repos | `GameState.heal_map` / `heal_spawn` (défaut `player_house_1f` / `heal`), sauvegardés | le Centre qui les change ; le réveil qui n'est plus forcément Maman |
| Défaite sauvage → soin → réveil | `EncounterDirector._handle_defeat` (soin, `SceneRouter.change_map` vers le point de repos, `mom_wakeup` codé en dur), `Boot._on_woke_up_after_defeat` (écriture immédiate) | généraliser (§3.3) : mot de réveil du lieu, défaite contre un Dresseur |
| Soin volontaire | `DialogueVariant.heal` → `DialogueRunner.heal_requested` → `Boot._on_heal_requested` (soin + autosave) ; Maman (`data/dialogues/player_house.json`) | un **choix** avant l'action, une action qui **dure** (rituel), d'autres actions |
| Stockage (« système de recherche de Chen ») | `PokemonStorage` (`add`, `get_all`, sauvegarde), capture équipe pleine → stockage (J5D), message `sent_to_storage` | retirer, insérer ; règles ; écran |
| Favori d'un Pokémon | `Pokemon.favorite` (v2), `MenuDirector.toggle_favorite` (Équipe) | le favori dans le Stockage, la protection contre LIBÉRER |
| Objets clés | `ItemData` catégorie `key` (fin d'enum, T10), onglet OBJETS CLÉS de `BagQuery` | le colis (premier objet clé), le prix des objets |
| Argent des Dresseurs | `TrainerData.prize_money` (lu et validé par `TrainerLibrary`), `BattleConclusion.prize_money` | **l'argent du joueur** (aucun champ), la formule Rouge/Bleu, le versement |
| Objectif du tableau de bord | `ObjectiveLibrary` + `data/story/objectives.json` (« rejoindre Jadielle. » si `rival_battle_done` ; point final ajouté le 2026-10-05) | l'objectif du colis ; couper « rejoindre Jadielle » à l'arrivée |
| Zones et services | `data/world/zones.json` : `viridian_city` (Jadielle), `route_22` déjà déclarées **sans cartes** ; catalogue `services` (Centre, Boutique, Arène) au format `{ id, found_on }` (T18), **aucun service posé** ; `MapJournal` montre un service quand sa carte `found_on` est découverte | les cartes, les services posés, les descriptions (`draft`) |
| Grand moment « Arrivée à Jadielle » | `data/trainer/moments.json` (texte propre à `viridian_city`, `draft`) ; arrivée déduite de `discovered_maps` | rien |
| Grand moment « Combat contre le rival » | `Boot._on_battle_finished` : tout dresseur à `team_by_starter` est le rival, issue en détail | rien : le rival n° 2 sera daté tout seul |
| Destination « à venir » | `Warp.coming_soon`, `SceneRouter.show_coming_soon`, `ComingSoonScreen` (dev seulement) ; la Route 1 l'utilise vers « Jadielle » | la Route 1 mène pour de vrai à Jadielle ; Jadielle utilise « Route 2 » |
| PNJ, présence et répliques conditionnelles | `NpcSpec` (`if` / `unless`, `route` en boucle, `shy` fly/flee, `species` pour OBSERVER), `NpcRoster`, `Npc`, `DialogueVariant` (`if`, `unless`, `set`) | entrer dans un bâtiment, suivre un autre PNJ, petite animation périodique |
| Scènes scriptées | `CutsceneDirector` / `CutsceneStep` (wait, dialogue, face, set, spawn, move avec suiveur, change_map, hop, lean, despawn, battle avec `win_flags` / `lose_flags`, give avec `found`), conditions d'étape, alias, `EventTriggerPoint` | étapes `scare`, `caption`, `take`, `wake_up` (§3) ; lancer une scène depuis un dialogue |
| Combat de dresseur | `BattleDirector.run` / `run_request`, `BattleRules.for_trainer` (soins permis, J6 Q-10), `BattleConclusion` | SAC par dresseur (aujourd'hui `BattleViews.TRAINER_BATTLE_ACTIONS` le tait contre **tous**) ; IA niveau 2 ; argent versé |
| IA | `BattleAI` (une seule sorte, `random`), `TrainerData.make_ai()`, appelée par `Battle` (`_foe.ai.choose(_foe, _player, _rng)`) | la sorte `smart` (niveau 2) |
| Rencontres | `EncounterLibrary`, `EncounterTable` (taux, rampe 15 → 20 pas), `data/encounters/route_1.json` | `route_22.json`, 10 espèces dans `PokemonData` |
| Hautes herbes | donnée de tuile `tall_grass`, `GrassRustle`, `grass_front.png` (jambes cachées) | version peinte (dérivée de `WORLD_GROUND_HAUTES_HERBES_01`) |
| Choix à deux cartes | `ChoiceView` (T27, figé) ; `ChoiceCards` (T28, livré : signal unique `chosen(bool)`, voile plein cadre, §0) | l'afficher **dans un dialogue** |
| Départs de débogage | `DebugStart` (`map`, `party`, `bag`, `flags`…), `tools/debug_start/*.json`, `tools/deploy_s24.sh --debug-start` | clés `money`, `storage` ; départs du J7 (§5.5) |
| Réglages graphiques | `GraphicsProfile` (Auto / Élevée / Économie), `Haptics`, `UiPrefs` | ce que « Économie » coupe dans la lumière du monde (§7) |
| Mesure des fps | `PerfCounter` (ligne `[perf]` toutes les 2 s, build debug) | la mémoire des textures dans la même ligne (T3) |

### 2.2 Composants réutilisés tels quels

- **Monde** : `GameMap` (grille lue dans les tuiles `Ground` / `Detail` / `Obstacles` + empreintes des `WorldProp`), `GridWorld`, `WorldProp` (origine aux pieds, `footprint`, `fade_when_covering`), `Warp` / `WarpPoint`, `InteractPoint`, `EventTriggerPoint`, `SceneRouter` (préchargement des voisines, fondu), `CameraFraming` (intérieurs plus petits que l'écran : carte centrée, bandes de la couleur de fond, déjà admis pour la maison et le labo), `ZoneAnnouncer`.
- **Menu** : `MenuDirector` (pause, pile, `mark_changed` → autosave à la fermeture), `MenuNavigator`, `TrainerMenu` (fond flouté, en-tête, hôte d'écrans), `TeamSlotCard`, `PokemonShowcase`, `BagTile`, `BagItemCard`, `BagCategoryTab`, `UseResultBar`, `MenuFormat`, `HpBar`.
- **Interface** : `Toast`, `WorldCaption` (via `ExplorationHud`), `ComingSoonScreen`, `DialogueBox`, `ChoiceCards` (T28), `TapGuard` (listes qui défilent), `UiPrefsApplier` (texte Grande, contraste), `Haptics`.
- **Sauvegarde** : `SaveSystem` (`upgrade`, `version` pour simuler une ancienne build), `SaveFileSystem`, `JsonFields`, protocole S24 du J6 (`jalon-06.md` §5.1.1).

### 2.3 Ce qui doit être généralisé

| Aujourd'hui | Au J7 |
|---|---|
| `DialogueVariant.heal: bool` | `action: StringName` (`heal`, `center_heal`, `open_shop`, `open_storage`) ; la clé `heal: true` reste lue comme `action = heal` (rien à réécrire dans les données de Maman) |
| Un dialogue finit toujours par ses pages | une variante peut se terminer par un **choix** (`DialogueChoice`) ou **lancer une scène** (`cutscene`) |
| Texte de page fixe | **jetons** (`{first_wild_species}`) ; une page dont un jeton n'a pas de valeur est **omise** (réplique de Chen, §19) |
| Mot de réveil de Maman codé en dur dans `EncounterDirector` | `RestPointLibrary` (`data/world/rest_points.json`) : chaque point de repos a son spawn et son mot de réveil ; `DefeatRecovery` partagé par la défaite sauvage et la défaite contre un Dresseur |
| SAC muet contre **tout** dresseur (`BattleViews.TRAINER_BATTLE_ACTIONS`) | `TrainerData.allow_bag` en données (`rival_lab` : faux ; défaut vrai), décision de Kevin du 2026-10-03 |
| `prize_money` fixe | `prize_per_level` (Rouge/Bleu : base × niveau du dernier Pokémon, dossier 09 §20 Q1) ; `prize_money` reste pour une somme fixe |
| `Npc` : apparences pixel ×2 en NEAREST dans `assets/sprites/characters/placeholder/` | `CharacterLook` : une apparence **peinte** (`…/painted/`, ×1, LINEAR) est prise si elle existe, sinon la provisoire |
| `MenuNavigator.open(route)` pose toujours le tableau de bord dessous | `open(route, standalone)` : la Boutique et le terminal ouvrent un écran **seul** (retour = fermer) |
| Tuiles provisoires peintes en `TileMapLayer` visibles | cartes peintes : `Ground` reste la **source logique** (solide, herbes, rebords), **invisible** ; l'image vient du sol peint et des props peints (§6.6) |

---

## 3. Fondations logiques (architecte, classes pures et tests)

Toutes en `RefCounted` (ou statiques), sans nœud ni autoload, testées avec GUT ; données JSON validées strictement comme les bibliothèques existantes (clé inconnue, type, bornes, doublon, ligne du JSON illisible, références croisées vérifiées). Les vues (`*View`) ne contiennent que des chaînes, des nombres et des textures : les écrans ne connaissent ni `GameState`, ni `Pokemon`, ni les données.

### 3.1 Sauvegarde v3 (T0) — **fait**

Voir §5.1. `GameState` (`game/autoload/game_state.gd`) a gagné :

```gdscript
## Argent (dossier 09 §10) : 3 000 ₽ pour une nouvelle partie (provisoire) ; plafond de
## Rouge/Bleu. Jamais négatif.
const STARTING_MONEY: int = 3000
const MONEY_MAX: int = 999_999
var money: int = STARTING_MONEY
## Première espèce sauvage rencontrée **en combat** (dossier 09 §19, J6 Q-7) : la seule que
## Chen peut citer. { "species", "map", "date" } (chaînes) ; vide tant qu'aucune rencontre.
var first_wild_encounter: Dictionary = {}

## Ajoute [param amount] (≥ 0 ; négatif : rien), borné à MONEY_MAX. Renvoie la somme ajoutée.
func add_money(amount: int) -> int
## Retire [param amount] si le joueur l'a : vrai. Sinon (ou montant négatif) : faux, rien ne
## change.
func spend_money(amount: int) -> bool
## Appelée au **début** de chaque rencontre sauvage. Vrai si c'est la première (seule retenue).
func record_wild_encounter(species: StringName, map: StringName) -> bool
func first_wild_species() -> StringName   ## &"" sans rencontre
```

`EncounterDirector._run` appelle `record_wild_encounter` juste après `record_seen` (avant le froissement et le combat : une fuite compte). `new_game` remet `money` à 3 000 et vide `first_wild_encounter`. `load_dict` est tolérant : argent borné à [0, `MONEY_MAX`], absent ou mal formé → 3 000 ; première rencontre mal formée → vide, espèce inconnue → écartée (push_error, `load_dict` rend faux comme pour un Pokémon inconnu). **Aucune perte d'argent à la défaite** (dossier 09 §10) : rien ne débite l'argent hors de la Boutique.

### 3.2 Monde peint, lumière et personnages (T2)

**Lumière (méthode C, calibration C2)** — données, pas code :

```gdscript
class_name LightProfile
extends RefCounted
## Une ambiance lumineuse du monde (méthode C : assets neutres, lumière portée par Godot ;
## fiches série 01, « Comparaison de lumière »). Donnée pure, lue dans
## data/world/lighting.json par [LightingLibrary]. Le jour/nuit (phase 10) interpolera
## entre plusieurs profils ; rien ne l'anticipe ici au-delà de la forme des données.
var id: StringName
## Étalonnage d'écran par zones de luminance (gains RVB), 0..1 d'intensité.
var grade_shadows: Vector3
var grade_midtones: Vector3
var grade_highlights: Vector3
var grade_strength: float
## Liseré de soleil sur les bords des objets tournés vers la lumière.
var rim_color: Color
var rim_strength: float
var rim_width: float
var sun_direction: Vector2          ## d'où vient la lumière (haut-gauche : (-0.7, -0.7))
## Ombre portée (silhouette pré-floutée, écrasée, inclinée) et ombre de contact.
var cast_shadow_color: Color
var cast_shadow_length: float       ## écrasement vertical (0,26 au prototype)
var cast_shadow_skew_deg: float     ## −45° au prototype
var contact_color: Color
var wind_strength: float            ## 0 = arbres immobiles
```

```gdscript
class_name LightingLibrary
extends RefCounted
const DATA_PATH: String = "res://data/world/lighting.json"
func load_file(path: String = DATA_PATH) -> bool
func get_profile(id: StringName) -> LightProfile   ## null si inconnu
func get_errors() -> PackedStringArray
```

`data/world/lighting.json` (valeurs **mesurées** du prototype, fiches série 01) : `golden_hour` (gains ombres 1,16/1,07/0,97, moyens 1,06/1,01/0,91, lumières 1,01/0,97/0,85 ; liseré doré `#ffd17a` ; ombre `#1a1738`, alpha 0,34, 0,26, −45° ; contact `#1f1a33`, alpha 0,62) et `interior_warm` (étalonnage presque neutre, légèrement chaud ; pas de liseré ni d'ombre portée ; contact gardé). `GameMap` gagne `@export var light_profile: StringName = &""` : **vide = aucune lumière du monde** (Bourg Palette, Route 1 et les intérieurs existants restent tels quels jusqu'à la phase DA, Q-3).

**Apparence d'un personnage** :

```gdscript
class_name CharacterLook
extends RefCounted
## Où trouver l'apparence [param sprite] et comment l'afficher : peinte (128 px à 1:1,
## LINEAR ; CLAUDE.md) si `painted/<sprite>_frames.tres` existe, sinon provisoire (pixel ×2,
## NEAREST), sinon l'apparence générique. Une seule règle pour Npc et Player.
const PAINTED_DIR: String = "res://assets/sprites/characters/painted/"
const PLACEHOLDER_DIR: String = "res://assets/sprites/characters/placeholder/"
var frames_path: String
var scale: float                     ## 1.0 peint, 2.0 provisoire
var filter: CanvasItem.TextureFilter
static func resolve(sprite: StringName, exists: Callable = ResourceLoader.exists) -> CharacterLook
```

Les animations gardent les noms actuels (`idle_*`, `walk_*`, `run_*`) : une planche peinte 4 × 4 (lignes bas, gauche, droite, haut ; colonnes passage, pas gauche, passage, pas droit, cahier §4) devient un `SpriteFrames` par l'outil `tools/build_character_frames.gd` (§6.6).

**PNJ vivants** (dossier 09 §2), `NpcSpec` + `NpcRoster`, clés facultatives de la routine :

```gdscript
## Index de départ dans la boucle (le Rattata part un pas derrière l'enfant, même boucle).
var route_start: int = 0
## Entrer dans un bâtiment (V1, dossier 09 §2) : arrivé sur [member route_enter_cell], le PNJ
## s'efface (fondu), reste absent [member route_enter_seconds], puis réapparaît et reprend.
var route_enter_cell: Vector2i = Vector2i(-1, -1)
var route_enter_seconds: float = 0.0
## Petite animation d'ambiance (le Roucool de la Dresseuse) toutes les N secondes ; 0 = aucune.
var idle_react_every: float = 0.0
```

Données : `"route": { "cells": […], "pause": 1.2, "start": 1, "enter": { "cell": [x, y], "seconds": 8 } }`, `"idle_react": 6.0`. Validation : la case d'entrée appartient à la boucle ; `start` dans les bornes.

**Étape de scène `scare`** (7A.1, micro-scène d'arrivée) : `CutsceneStep.Kind.SCARE` (fin d'enum, clé `"scare"`) : le PNJ `actor` joue **tout de suite** sa réaction d'ambiance (`fly` / `flee`, `Npc.fly_away` / `flee` existants) et quitte la carte **pour la visite** (`GameMap.remove_npc`, comme sur la Route 1).

**Tests (T2)** : `test_light_profile` / `test_lighting_library` (valeurs, bornes, couleurs, profil inconnu), `test_character_look` (peint d'abord, provisoire ensuite, générique en dernier ; échelle et filtre), `test_npc_roster` étendu (`start`, `enter`, `idle_react`, refus d'une case d'entrée hors boucle), `test_cutscene_data` (étape `scare`), `test_debug_start` (clés `money`, `storage`).

### 3.3 Centre : choix, actions, point de repos (T6)

```gdscript
class_name DialogueChoice
extends RefCounted
## Choix à deux grandes cartes à la fin d'une variante (dossier 09 §7, §18 ; bible §4) :
## SOIGNER / PAS MAINTENANT. La question est la dernière page de la variante.
var confirm_label: String
var cancel_label: String
## Action jouée si le joueur confirme (&"" = aucune), puis [member confirm_pages].
var confirm_action: StringName
var confirm_pages: Array[DialoguePage] = []
var cancel_pages: Array[DialoguePage] = []
func to_view(question: String) -> ChoiceView
```

`DialogueVariant` gagne `action: StringName` (action de fin, après la dernière page), `choice: DialogueChoice` (null = aucun) et `cutscene: StringName` (scène lancée à la fin du dialogue, 7A.5). Une variante peut n'avoir **aucune page** si elle a une `action` ou une `cutscene` (terminal du Stockage, Chen avec le colis). `DialogueLibrary` : `const ACTIONS: Array[StringName] = [&"heal", &"center_heal", &"open_shop", &"open_storage"]`, clés `"action"`, `"choice"` (`confirm`, `cancel`, `confirm_action`, `confirm_pages`, `cancel_pages`), `"cutscene"`.

```json
"nurse": { "speaker": "Infirmière", "variants": [ {
	"pages": ["Bonjour. Je m'occupe de ton équipe ?"],
	"choice": { "confirm": "SOIGNER", "cancel": "PAS MAINTENANT", "confirm_action": "center_heal",
		"confirm_pages": ["Voilà. Tout le monde est en pleine forme."],
		"cancel_pages": ["Très bien. Reviens quand tu veux."] } } ] }
```

`DialogueRunner` (présentation, mais le contrat se fige ici) :

```gdscript
## Le choix de la variante attend le joueur (la boîte de dialogue garde la question).
signal choice_requested(view: ChoiceView)
## Réponse du joueur ; sans choix en attente : rien.
func choose(confirmed: bool) -> void
## Coroutine appelée pour une action (`func(action: StringName) -> void`), attendue avant les
## pages qui suivent. Sans gestionnaire : l'action est ignorée (push_error), les pages suivent.
var action_handler: Callable
## La variante se termine par une scène : émis après la dernière page.
signal cutscene_requested(cutscene_id: StringName)
```

`heal_requested` reste émis pour l'action `heal` (Maman, `test_mom_heal` inchangé).

**Point de repos** :

```gdscript
class_name RestPoint
extends RefCounted
var map: StringName
var spawn: StringName
var facing: Vector2i
## Dialogue joué au réveil après une défaite (« mom_wakeup », « nurse_wakeup »).
var wakeup_dialogue: StringName
## Vrai pour un Centre : s'y soigner l'enregistre. Faux pour la maison (le point de départ,
## que Maman ne « réenregistre » pas : dossier 09 §7).
var registers: bool

class_name RestPointLibrary
extends RefCounted
const DATA_PATH: String = "res://data/world/rest_points.json"
func load_file(path: String = DATA_PATH) -> bool
func get_point(map: StringName) -> RestPoint       ## null si la carte n'en a pas
## Enregistre [param point] comme point de repos de [param state] s'il `registers`.
## Vrai si le point de repos a changé (toast « Point de repos enregistré — <zone> »).
static func register(state: Node, point: RestPoint) -> bool
```

`data/world/rest_points.json` : `player_house_1f` (`heal`, haut, `mom_wakeup`, `registers: false`), `viridian_center` (`heal`, haut, `nurse_wakeup`, `registers: true`). Vérification croisée : la carte existe (`MapCatalog`), le dialogue existe.

**Tests (T6)** : `test_dialogue_library` (choix, action, scène, variante sans page, action inconnue refusée, `heal: true` → `heal`), `test_dialogue_runner` (choix demandé après la dernière page, confirmer → action attendue puis pages, annuler → pages d'annulation, `heal_requested` toujours émis), `test_rest_points` (Centre enregistré, maison jamais, deuxième soin au même Centre : pas de changement, défaut de `GameState` = maison).

#### 3.3.1 Fait au T6 (ce qui a été figé, et les écarts avec le texte ci-dessus)

Livré : `DialogueChoice` (`game/systems/dialogue/dialogue_choice.gd`), `DialogueVariant` (`action`, `choice`, `cutscene` ; **le champ `heal: bool` disparaît**, remplacé par `action == &"heal"`), `DialogueLibrary` (`ACTIONS`, clés `action` / `choice` / `cutscene`, validation), `DialogueRunner` (contrat ci-dessus + `is_awaiting_choice()`), `RestPoint` et `RestPointLibrary` (`game/world/rest/`), `data/world/rest_points.json`. **Format de sauvegarde inchangé** (v3 : `heal_map` / `heal_spawn`). Aucun câblage dans `Boot` : sans `action_handler`, une action autre que `heal` est signalée (push_error) et le dialogue continue ; aucune donnée actuelle n'en contient.

Règles figées (défauts du T6, règle 4) :
- **Une seule fin par variante** : `choice`, `action` (ou l'ancienne `heal: true`) ou `cutscene`. Une variante à `choice` a toujours au moins une page (la question) ; `confirm_pages` / `cancel_pages` peuvent être vides (le dialogue se termine).
- **Action d'un choix** (`confirm_action`, le rituel du Centre) : jouée **boîte ouverte** (elle garde la question), joueur bloqué ; toucher et `interact` n'avancent rien pendant l'action ni pendant le choix. *À revoir sur capture au T8 / T9* (cacher la boîte pendant le rituel est une décision de présentation, pas de format).
- **Action de fin de variante** (`open_shop`, `open_storage`) : jouée **boîte fermée**, drapeaux `set` déjà levés, joueur **encore bloqué** ; le lecteur l'attend, puis rend le joueur et émet `dialogue_finished`. Variante sans page : la boîte ne s'ouvre pas, la fin passe à l'image suivante (`play` rend la main avant).
- **`heal`** n'est jamais passée à `action_handler` : elle émet `heal_requested` (fin de variante : au même moment qu'au J5, après avoir rendu le joueur, juste avant `dialogue_finished` ; dans un choix : au moment de la réponse). `Boot._on_heal_requested` reste le seul à soigner pour Maman.
- **`cutscene_requested`** est émis juste **après** `dialogue_finished` (joueur rendu ; la scène pose son verrou dans la même image).
- **Point de repos** : `data/world/rest_points.json` ne contient au T6 **que la maison** (`player_house_1f`) ; le Centre de Jadielle y entre **au T8**, avec sa carte et `nurse_wakeup` (le test de données vérifie carte, point d'apparition et dialogue de chaque point ; `test_dialogue_data` compte les mots de réveil comme utilisés sur leur carte). Format : `{ "registered_title": "Point de repos enregistré", "points": { carte: { spawn, facing, wakeup_dialogue, registers } } }`.
- **Toast** : `RestPointLibrary.registered_toast(zone_name) -> PackedStringArray` = `[titre, détail]` = `["Point de repos enregistré", "Jadielle"]`, pour `ExplorationHud.show_toast(titre, détail)` (le « — » du dossier sépare le titre et le détail, comme « Poké Balls ×5 — Ajoutées au Sac »). Nom de zone : `ZoneLibrary.zone_name_of(map)`.
- **Réveil** : `RestPointLibrary.wakeup_point(state) -> RestPoint` (jamais null) : le point de la donnée si `heal_map` en a un au même `heal_spawn`, sinon un point construit sur l'état (haut, **sans** mot de réveil).

Tests : `test_dialogue_library` (+11), `test_dialogue_runner` (+10), `test_rest_points` (nouveau, 13), `test_rest_point_data` (nouveau, 4), `test_dialogue_data` adapté (`action == heal`, mots de réveil lus dans `rest_points.json`).

#### 3.3.2 Contrats du T8 (constructeur-monde), figés au T6

```gdscript
## game/systems/services/service_director.gd — actions de dialogue (jalon-07.md §6.2).
class_name ServiceDirector
extends Node
## Soin d'un Centre fini (équipe soignée, rituel joué, point de repos traité). [param registered] :
## vrai si le point de repos a changé. Boot : écriture immédiate « soin » (§5.3) et, si
## [param registered], toast RestPointLibrary.registered_toast(zone).
signal center_healed(map_id: StringName, registered: bool)
func setup(state: Node, rest_points: RestPointLibrary) -> void
func set_map(map: GameMap) -> void           ## carte courante (machine %HealMachine du Centre)
## = DialogueRunner.action_handler. center_heal : Party.heal_all, rituel UiTokens.CENTER_HEAL
## (×0,5 si reduce_motion), vibration par Haptics, RestPointLibrary.register(state,
## get_point(map)), center_healed. open_shop / open_storage : T12 / T16 (même méthode).
## Action inconnue : push_error, rien.
func run_action(action: StringName) -> void   ## coroutine

## game/world/rest/defeat_recovery.gd — remplace EncounterDirector._handle_defeat.
class_name DefeatRecovery
extends Node
## Le joueur vient de se réveiller au point de repos (équipe soignée), avant le mot du lieu :
## Boot écrit la sauvegarde (comme woke_up_after_defeat, que EncounterDirector relaie).
signal woke_up(map_id: StringName)
func setup(state: Node, rest_points: RestPointLibrary, router: Node, runner: DialogueRunner) -> void
func set_map(map: GameMap) -> void
## Soin, change_map(point.map, point.spawn, point.facing) avec point = wakeup_point(state),
## woke_up, puis runner.play(point.wakeup_dialogue) non attendu (si non vide). Coroutine.
func recover() -> void
```

`EncounterDirector` reçoit `DefeatRecovery` (paramètre de `setup` facultatif, en fin de liste) et l'attend sur une défaite ; sans lui (tests purs), comportement actuel. `_WAKEUP_DIALOGUE` disparaît. La défaite contre un Dresseur (étape `wake_up`, T25) appellera le même `recover()`.

### 3.4 Boutique et économie (T10) — **fait**

> **Fait au T10** (logique pure et tests, sans écran ni câblage ; format de sauvegarde inchangé). Écarts avec le texte ci-dessous : `ShopLibrary.check_references` rend un `bool` et **retire** du stock l'objet fautif ; `ShopRules` gagne `max_sell(item, bag)`, `buy_total`, `sell_total` ; `state` est typé `Object` (comme `TrainerSummary`) ; `ShopViews.sell_confirm_view(entry, quantity) -> ChoiceView` (confirmation d'un favori) ; `ShopView` / `ShopEntryView` dans `game/systems/shop/views/` (contrat au §6.10) ; `MenuRoute.STANDALONE_SCREENS = [SHOP]` (la Boutique n'est ni dans `SCREENS` ni dans `DASHBOARD_ORDER`, jamais la cible d'un `go`, ne s'ouvre que seule) et `MenuNavigator.is_standalone()` ; `BagQuery.view(…, money := -1)` (négatif = pas d'argent affiché) et `MenuDirector._emit_bag` lui passe `_state.money` ; `ItemData.is_key()`, et le toast d'un objet clé : titre = nom en capitales (« COLIS POUR CHEN »), détail « ajouté aux objets clés » (accordé). VENDRE ne liste **que** les objets vendables (le colis n'y apparaît pas) ; « Je ne peux pas te reprendre ça. » reste la réponse de `ShopRules.sell` à un objet clé. Un achat ne demande jamais de confirmation ; chaque vente d'un favori, si (y compris le dernier exemplaire ; le favori reste marqué). Vendre au plafond d'argent : l'excédent est perdu (Rouge/Bleu). Le stock du marchand n'a aucune condition (Poké Ball, Potion dès la première visite, dossier 09 §9) ; le format `if` / `unless` est prêt pour la suite. **Gains d'argent des combats de dresseurs : non traités ici (T24, §3.8)**.

`ItemData` : `price: int` (0 = pas en vente ; un objet clé n'a jamais de prix), `sell_price() -> int` (moitié, arrondie en dessous, Rouge/Bleu), `is_sellable() -> bool`. `data/items/items.json` : Poké Ball 200, Potion 300 (dossier 09 §10, provisoires) ; **`oak_parcel`** (« Colis pour Chen », `key`, description `draft`). Le toast d'un objet clé dit « ajouté aux objets clés » (`ItemData.added_text` selon la catégorie).

```gdscript
class_name ShopData
extends RefCounted
## Une boutique (data/shops/*.json) : son stock évolue avec la progression (if / unless par
## objet, comme les dialogues). Jamais un objet pour une mécanique absente (dossier 09 §9).
var id: StringName
var stock: Array[Dictionary] = []    ## { "item", "if", "unless" }

class_name ShopLibrary
extends RefCounted
const DATA_DIR: String = "res://data/shops/"
func load_dir(dir: String = DATA_DIR) -> bool
func get_shop(id: StringName) -> ShopData
func check_references(items: ItemLibrary) -> void   ## objet inconnu, sans prix, ou objet clé

class_name ShopRules
extends RefCounted
enum Status { OK, NOT_ENOUGH_MONEY, NOT_SOLD_HERE, NOT_SELLABLE, NOT_ENOUGH_ITEMS,
	NEEDS_CONFIRM, BAD_QUANTITY }
const MAX_QUANTITY: int = 99
static func stock(shop: ShopData, flags: StoryFlags) -> Array[StringName]
static func max_buy(item: ItemData, money: int) -> int
static func buy(state: Node, shop: ShopData, item: ItemData, quantity: int) -> Status
## Un favori demande une confirmation (NEEDS_CONFIRM tant que [param confirmed] est faux) ;
## un objet clé : NOT_SELLABLE (« Je ne peux pas te reprendre ça. »).
static func sell(state: Node, item: ItemData, quantity: int, confirmed: bool = false) -> Status
```

`ShopViews.build(state, shop, items, mode) -> ShopView` (onglets ACHETER / VENDRE ; par objet : nom, description courte, `unit_price`, `price_text`, `owned_text` « DANS LE SAC : 3 », `max_quantity`, raison si indisponible ; `money_text`), `ShopViews.total_text(unit_price, quantity)`, `ShopViews.status_text(status)` (« Tu n'as pas assez d'argent. », « Je ne peux pas te reprendre ça. », « Merci ! »). `MenuFormat.money(3000) -> "3 000 ₽"` (espace insécable, comme les XP). `MenuRoute.SHOP` (`shop(shop_id, mode)`) et `MenuNavigator.open(route, standalone := false)`. `TrainerView.money_text`, `BagView.money_text`. `data/story/objectives.json` : « remettre le colis au Professeur Chen » si `got_oak_parcel`, sauf `pokedex_activated` (en tête de liste) ; « rejoindre Jadielle » gagne `unless: ["viridian_arrived"]`.

**Tests (T10)** : `test_item_library` (prix, objet clé sans prix), `test_shop_library`, `test_shop_rules` (achat exact, argent insuffisant, quantité 0 et > 99, stock conditionnel, vente moitié prix, objet clé refusé, favori → NEEDS_CONFIRM puis OK, rien ne change sur un refus), `test_shop_views`, `test_menu_format` (argent), `test_menu_navigator` (écran seul : retour = fermer), `test_objective_library` (colis, puis rien après l'activation), `test_trainer_summary` / `test_bag_query` (argent).

### 3.5 Stockage (T14) — **fait, figé**

`game/systems/storage/` (classes pures ; règles et vues statiques) :

```gdscript
class_name StorageRules
extends RefCounted
## Règles métier du Stockage Pokémon V1 (dossier 09 §8, §19), indépendantes de l'écran.
enum Place { PARTY, STORAGE }
enum Action { NONE, DEPOSIT, WITHDRAW, RELEASE, FAVORITE }                 # 2026-10-05
enum Status { OK, LAST_POKEMON, PARTY_FULL, FAVORITE, NOT_FOUND, LAST_ABLE } # LAST_ABLE : 2026-10-05
static func get_pokemon(party, storage, place: Place, index: int) -> Pokemon
static func keeps_able(party: Party, without_index: int) -> bool          # Q-7
static func keep_status(party: Party, without_index: int) -> Status       # OK / LAST_POKEMON / LAST_ABLE
static func can_deposit(party: Party, index: int) -> Status
static func deposit(party: Party, storage: PokemonStorage, index: int) -> StorageResult
static func can_withdraw(party: Party, storage: PokemonStorage, index: int) -> Status
static func withdraw(party: Party, storage: PokemonStorage, index: int) -> StorageResult
static func can_release(party, storage, place: Place, index: int) -> Status
static func release(party, storage, place: Place, index: int) -> StorageResult
static func toggle_favorite(party, storage, place: Place, index: int) -> StorageResult

class_name StorageResult      # status, pokemon (concerné ; null si NOT_FOUND), selection, is_ok(),
                              # action (StorageRules.Action ; NONE pour un refus) — 2026-10-05
class_name StorageSelection   # place, index (−1 = aucune) ; first(party, storage), clamped(…), equals
class_name StorageViews
static func build(state, data, selection: StorageSelection, zones = null, unlocks = null,
		result: StorageResult = null) -> StorageView   # result : 2026-10-05, ligne de résultat
static func card(pokemon, place, index, data, selection = null) -> StorageCardView
static func release_choice(name: String) -> ChoiceView
static func status_text(status: StorageRules.Status, name: String) -> String
static func result_text(result: StorageResult, data: PokemonData) -> String
```

Vues figées (`game/systems/storage/views/`) : `StorageView` (`party_title`, `storage_title`, `back_label`, `party` / `storage` : `Array[StorageCardView]`, `empty_text`, `selection`, `sheet: PokemonSheetView` — la fiche de l'Équipe, même règle d'évolution —, `actions` : DÉPOSER ou REPRENDRE puis FAVORI, `more_actions` : LIBÉRER, `card_at(place, index)`, `PARTY_SLOTS` = 6 ; **ajouté le 2026-10-05** : `result_text`, la ligne de résultat d'un succès, « {Pokémon} a été libéré. » après une libération, sinon "") ; `StorageCardView` (`place`, `index`, `member: TeamMemberView`, `selected`) ; `StorageActionView` (`id` = `StorageViews.ACTION_*`, `label`, `active` pour FAVORI). Une action n'est **jamais grisée** : un refus se montre au toucher.

**Règles** (testées, `test_storage_rules`) :
- **Déposer** : le Pokémon va **à la fin** du stockage, la sélection le suit. Refus si l'équipe garderait **0 Pokémon en état de combattre** (Q-7, règle stricte validée par Kevin le 2026-10-05), avec **deux raisons distinctes** pour que le refus explique pourquoi : `LAST_POKEMON` si l'équipe serait **vide** (le seul Pokémon, même K.O.) ; `LAST_ABLE` s'il resterait des Pokémon, **tous K.O.** (le dernier valide à côté de K.O., ou un K.O. à côté d'autres K.O.). Déposer un K.O. à côté d'un valide est permis. `keep_status(party, index)` rend l'une ou l'autre.
- **Reprendre** : en **fin d'équipe**, la sélection le suit ; refus `PARTY_FULL` à 6. Un K.O. se reprend.
- **Libérer** : depuis l'équipe ou le stockage ; refus `LAST_POKEMON` / `LAST_ABLE` (équipe seulement) **avant** `FAVORITE` (retirer le favori n'y changerait rien) ; `FAVORITE` sans contournement : la règle ne touche jamais au favori. Après une libération, la sélection va à celui qui prend la place (index borné), sinon au premier de l'autre liste. **Ni le Pokédex ni la statistique « Captures »** (`TrainerSummary.capture_count`, carrière) ne bougent : vérifié sur un `GameState`.
- **Favori** : depuis l'équipe ou le stockage (dossier 09 §20) ; seul refus : `NOT_FOUND`.
- **Capacité** : **aucune limite** (un stockage unique, sans boîtes ; `PokemonStorage` depuis le J5) : pas de statut « stockage plein ».
- Déplacer garde **la même instance** (PV, PP, XP, favori, surnom, histoire : `to_dict` identique). Un refus ne change rien ; sa `selection` est la carte refusée (celle qui tremble).
- `Party.remove_at(index) -> Pokemon` (sans règle : la règle est au Stockage), `PokemonStorage.get_at`, `index_of`, `remove_at`.

**Textes** (`StorageViews`, constantes) : libellés validés ÉQUIPE · STOCKAGE · DÉPOSER · REPRENDRE · FAVORI · LIBÉRER · RETOUR · ANNULER ; confirmation « Libérer {Pokémon} ? » / « Il quittera définitivement ton équipe et ton stockage. » ; refus « Tu dois garder au moins un Pokémon avec toi. » (`LAST_POKEMON`, équipe vide), « Retire d'abord {Pokémon} de tes favoris pour pouvoir le libérer. » ; **draft** : « Ton équipe est déjà complète. », « Le stockage est vide. », **« Tu dois garder au moins un Pokémon en état de combattre. »** (`LAST_ABLE`, décision de Kevin du 2026-10-05), **« {Pokémon} a été libéré. »** (`RELEASED_TEXT`, après une libération confirmée et réussie : défaut du T14 inversé par Kevin le 2026-10-05). Les autres succès (déposer, reprendre, favori) restent **sans texte** (la carte qui bouge suffit). `result_text(result, data)` rend la raison d'un refus ou le texte d'une libération, "" sinon.

**Déblocage** : `MenuRoute.STORAGE` (`MenuRoute.storage()`, sans paramètre, **pas** une carte du tableau de bord) ; `MenuUnlocks.STORAGE_SERVICE = &"pokemon_center"`, `MenuUnlocks.set_location(zones, current_map: Callable)` (branché par `Boot` au T16), `storage_available()` (relu à chaque appel), `static is_storage_map(map, zones)` : vrai seulement sur la carte `found_on` d'un service `pokemon_center` — **pas** dans la ville du Centre ; `is_available(STORAGE)` = équipe visible **et** `storage_available()`. Sans `set_location`, le Stockage n'existe nulle part. `TeamView.storage_available` (rempli par `TeamViews.build`) : le bouton STOCKAGE de l'Équipe.

**Sauvegarde** : **inchangée** (v3) ; la sélection est de session.

**Décisions de Kevin du 2026-10-05 (appliquées)** : raison distincte « tous K.O. » (`LAST_ABLE`, ajouté en fin d'enum : les valeurs existantes ne bougent pas) ; message après une libération ; `StorageResult.action`, `StorageView.result_text` et le paramètre `result` de `build` sont des **ajouts** (rien de figé n'a changé de nom ; seul le sens de `LAST_POKEMON` se resserre : il ne couvre plus que l'équipe vide). Tests : `test_storage_rules` (+4 : raisons distinctes, `keep_status`, action portée par chaque succès, `LAST_ABLE` avant le favori), `test_storage_views` (+3 : texte « tous K.O. », seule la libération a un texte, la ligne de la vue).

**Tests (T14, faits)** : `test_storage_rules` (24), `test_storage_views` (11), `test_menu_unlocks` (+4), `test_party`, `test_pokemon_storage`, `test_menu_route`, `test_team_views` étendus.

### 3.6 Chen et le Pokédex (T18)

```gdscript
class_name DialogueTokens
extends RefCounted
## Jetons de texte des dialogues : « Un {first_wild_species}… ». Une page dont un jeton n'a
## pas de valeur est omise (dossier 09 §19 : « aucune → la réplique est omise »).
const FIRST_WILD_SPECIES: StringName = &"first_wild_species"
const KNOWN: Array[StringName] = [FIRST_WILD_SPECIES]
static func tokens_in(text: String) -> Array[StringName]
## Texte résolu, ou "" si un jeton manque (la page est alors sautée).
static func resolve(text: String, values: Dictionary[StringName, String]) -> String
```

`DialogueRunner.token_values: Callable` (renvoie le dictionnaire du moment ; `Boot` le nourrit depuis `GameState.first_wild_species()` et `PokemonData`). `DialogueLibrary` refuse un jeton inconnu. Étapes de scène (fin d'enum, après `scare`) : **`caption`** (`text` : « POKÉDEX ACTIVÉ », via `ExplorationHud`, attend la fin de la légende) et **`take`** (`item_id`, `count` : le colis quitte le Sac ; sans l'objet : étape sautée, push_error).

**Tests (T18)** : `test_dialogue_tokens`, `test_dialogue_runner` (page omise sans valeur, résolue avec), `test_cutscene_data` (`caption`, `take`) ; `record_wild_encounter` est déjà testé depuis le T0 (vide → Chen omet sa réplique : `test_parcel_scene`).

#### 3.6.1 Fait au T18 (ce qui a été figé, et les écarts avec le texte ci-dessus)

> Fait en avance (logique pure, données de la scène et tests ; **sans câblage dans `Boot`, sans écran, format de sauvegarde inchangé**).

Livré :
- **`DialogueTokens`** (`game/systems/dialogue/dialogue_tokens.gd`) : contrat ci-dessus, plus `is_well_formed(text)`, `has_tokens(pages)`, `resolve_pages(pages, values) -> Array[DialoguePage]` (copie des pages résolues, mise en scène gardée ; pages sans jeton rendues telles quelles, sans copie) et **`values_for(first_wild_species: StringName, data: PokemonData) -> Dictionary[StringName, String]`** (nom affiché de l'espèce ; vide ou espèce inconnue → aucune valeur). Jeton = `{nom}`, nom en `[a-z_]+`. Une valeur **vide** compte comme absente.
- **`DialogueRunner`** (ajout, signalé : fichier figé au T6) : `var token_values: Callable` (`func() -> Dictionary[StringName, String]`), lu seulement si une page à jouer a un jeton ; pages résolues au début du dialogue et au début des pages d'une réponse de choix. **Toutes les pages omises** = comme une variante sans page (pas de boîte, fin à l'image suivante, drapeaux et fin de variante joués). Sans `token_values` : aucune valeur, la page à jeton est omise (pas d'erreur).
- **`DialogueLibrary`** (ajout, signalé) : jeton inconnu refusé, accolade hors d'un jeton refusée (faute de frappe), **la question d'un choix (dernière page) n'a jamais de jeton** (elle ne peut pas être omise). Le texte des données garde son jeton (résolu au moment de jouer).
- **Étapes de scène** `caption` (`text`, clé `"caption": "POKÉDEX ACTIVÉ"`) et `take` (`item_id`, `count` ≥ 1, clé `"take": "oak_parcel"`), `CutsceneStep.Kind.CAPTION` / `TAKE` en fin d'enum ; `CutsceneLibrary.get_item_ids()` liste aussi les objets repris. **`CutsceneDirector`** : `set_hud(hud: ExplorationHud)` ; `caption` → `ExplorationHud.show_caption(text)` puis **attend `caption_hidden`** (fondu + `CAPTION_HOLD` 3 s + fondu) ; sans HUD : push_error, étape sautée. `take` → `Bag.remove` (Sac de `set_inventory`), **sans signal ni toast** (aucun texte validé) ; sans Sac ou sans l'objet : push_error, étape sautée, Sac inchangé.
- **Données** :
  - `data/dialogues/oak_lab.json` : `oak_lab_waiting` gagne une variante **en tête** `{ if: [got_oak_parcel], unless: [pokedex_activated], cutscene: oak_parcel }` (sans page : parler à Chen avec le colis lance la scène, défaut du §13) ; répliques du §19, **mot pour mot** : `oak_parcel_records` (« Tiens… » · « Il a déjà commencé à enregistrer tes rencontres. » · « Un {first_wild_species}… Tu n'as pas perdu de temps. » · « J'étudie… » · « Mais aucune recherche… » · « Ton voyage peut nous apprendre beaucoup. »), `oak_pokedex_activated` (« Il enregistrera… » · « Observe. Explore. Fais-toi ta propre idée du monde. »), `rival_parcel_return` (« Professeur ! Je suis revenu. »), `rival_parcel_greet` (« Tiens. T'es déjà revenu, toi aussi ? »), `oak_parcel_rival` (Chen « Et toi… apprends à regarder au-delà de la victoire. », Rival « …On verra. » après 0,8 s), `rival_parcel_leaving` (« Pas mal. » en regardant son Pokédex, « Mais ne t'imagine pas que je vais t'attendre. » vers le joueur).
  - `data/cutscenes/oak_lab.json`, scène **`oak_parcel`** (`unless: [pokedex_activated]`), dans l'ordre : Chen et le joueur se font face, Chen s'avance, **`take oak_parcel`**, `oak_parcel_records` (la page de l'espèce omise sans rencontre), **`set pokedex_activated`** (seule étape de toutes les données qui le lève), **`caption` POKÉDEX ACTIVÉ**, `oak_pokedex_activated`, puis le rival **entre** (`spawn rival` en (7, 9), sprite `rival` : peint si la planche existe, `CharacterLook`), « Professeur ! Je suis revenu. », s'approche de Chen, « Tiens. T'es déjà revenu… », Chen s'avance vers lui (il reçoit son Pokédex, sans texte), `oak_parcel_rival`, `rival_parcel_leaving`, il repart par la porte (`move` (7, 9), `despawn`) ; Chen et le joueur se refont face. **Objectif** : « remettre le colis… » s'efface avec `pokedex_activated` (`objectives.json`, T10 ; Q-10 : aucune ligne ensuite). `got_oak_parcel` reste levé (histoire).
- **Ce qui apparaît à l'activation (§4)** : rien de nouveau à coder — la 6e carte, la ligne vus · capturés, les Pokémon observés de la Carte, la chaîne d'évolution et la carte de capture lisent déjà `MenuUnlocks.pokedex_visible()` à chaque construction (`test_menu_unlock_rule`, J6) ; **aucun toast à l'activation** : `Boot._on_flag_changed` sort avant de mettre des toasts en file pour `POKEDEX_ACTIVATED` (J6) — à vérifier de bout en bout par `test_parcel_scene` (T19).

Défauts (règle 4) : le colis quitte le Sac **avant** « Tiens… » (Chen le reçoit et l'ouvre) ; pas de toast au retrait du colis ; la légende est attendue jusqu'à sa disparition (~3,4 s) avant « Il enregistrera… » ; le rival arrive **après** « Observe. Explore. » (ordre du T19 du plan ; **validé par Kevin le 2026-10-05**) et reçoit son Pokédex sans réplique (Chen s'avance vers lui ; **validé pour l'instant, à juger en QA** : silence intentionnel ou vide) ; silences et regards (0,6 s, 0,8 s, le rival baisse les yeux sur « Pas mal. ») réglables au T19 sur capture.

Tests : `test_dialogue_tokens` (nouveau, 11), `test_dialogue_library` (+4 : jetons), `test_dialogue_runner` (+5 : résolue, omise, sans source, toutes omises, pages de réponse), `test_cutscene_caption_take` (unitaire, nouveau, 5 : format), `test_cutscene_director_caption_take` (intégration, nouveau, 6 : directeur, vraie `ExplorationHud`), `test_cutscene_data` (scène `oak_parcel` simulée sur le vrai labo, ordre, `pokedex_activated` levé une seule fois), `test_dialogue_data` (textes cherchés aussi dans le dossier 09, jeton écrit `{espèce}` ; scène lancée par un dialogue ; répliques du colis), `test_objective_library` (`pokedex_activated` retiré de `_PENDING_FLAGS` ; `got_oak_parcel` y reste jusqu'au T12, comme dans `FUTURE_FLAGS` de `test_dialogue_data`).

**Fusion avec le T2 (`j7-monde`)** : le T2 ajoute l'étape `scare` au même endroit. Conflits attendus, triviaux, dans `cutscene_step.gd` (enum et `TYPE_KEYS`) et `cutscene_library.gd` (`_EXTRA_KEYS`) : résolution = **`GIVE, SCARE, CAPTION, TAKE`** (`"give", "scare", "caption", "take"` ; `_EXTRA_KEYS` : `["count", "found"], [], [], ["count"]`). Les cas du `match` du directeur et de la bibliothèque, et les tests (fichiers à part `test_cutscene_caption_take`, `test_cutscene_director_caption_take`), sont placés pour ne pas se chevaucher.

#### 3.6.2 Contrat du T19 (constructeur-monde), figé au T18

Câblage dans `Boot` (seul fichier de jeu à modifier pour faire jouer la scène) :

```gdscript
## Boot._ready, après la création des bibliothèques :
_runner.token_values = func() -> Dictionary[StringName, String]:
	return DialogueTokens.values_for(GameState.first_wild_species(), _pokemon)
_runner.cutscene_requested.connect(_on_cutscene_requested)   ## → _cutscenes_node.play(id)
_cutscenes_node.set_hud(_hud)                                ## étape « caption »
## set_inventory(GameState.bag, _items) existe déjà (étape « take »).
## Autosave : cutscene_finished (existant, §5.3) ; rien à ajouter pour l'activation.
```

- `_on_cutscene_requested(id)` : `_cutscenes_node.play(id)` (la scène n'a pas d'alias ; refus → push_warning). Le verrou du joueur passe du dialogue à la scène dans la même image (§3.3.1).
- `tools/debug_start/parcel.json` (colis en main, `got_oak_parcel`, `rival_battle_done`, `rival_left_lab`, devant le labo) ; `DebugStart` ne pose jamais `pokedex_activated`.
- `test_parcel_scene` (vrai `Boot`, départ `parcel`, puis la fixture `v2_kevin_j6_fin.json` migrée) : parler à Chen → la scène se joue jusqu'au bout ; réplique « Un Roucool… » pour la partie de Kevin, omise pour une partie sans rencontre ; colis retiré ; drapeau posé une fois et sauvegardé ; 6 cartes après, données d'avant visibles ; **aucun toast** de la scène ni de rattrapage (`_hud.get_toast().is_showing()` faux tout du long) ; objectif vide ; reparler à Chen → réplique habituelle, la scène ne se rejoue pas. Captures `oak_parcel`, `pokedex_activated`.
- Réglages permis au T19 **sans l'architecte** : positions, silences et regards de `data/cutscenes/oak_lab.json` (case d'entrée du rival, décalages autour de Chen, `wait`, `face`, `lean`) ; l'ordre des répliques et des étapes `take` / `set` / `caption` reste celui-ci (`test_cutscene_data`).

**Partage des fichiers** :

| Qui | Fichiers |
|---|---|
| **T19 (constructeur-monde)** | `game/boot.gd` (câblage ci-dessus), `tools/debug_start/parcel.json`, `tests/integration/test_parcel_scene.gd`, scénarios de capture, réglages de mise en scène de `data/cutscenes/oak_lab.json` |
| **Architecte seulement** (écart → remonter) | `game/systems/dialogue/dialogue_tokens.gd`, `dialogue_runner.gd`, `dialogue_library.gd`, `game/systems/cutscene/cutscene_step.gd`, `cutscene_library.gd`, les textes de `data/dialogues/oak_lab.json` (§19, mot pour mot) |
| **Ni l'un ni l'autre** | `game_state.gd`, `save_system.gd` (format inchangé), `menu_unlocks.gd` (le déblocage suit déjà le drapeau) |

### 3.7 Route 22 : données (T21)

- `data/pokemon/species/kanto.json` : **10 espèces** (Piafabec, Rapasdepic, Férosinge, Colossinge, Nidoran ♀, Nidorina, Nidoqueen, Nidoran ♂, Nidorino, Nidoking), statistiques, types, apprentissages et évolutions de Rouge/Bleu (les évolutions doivent exister pour la validation des chaînes, même invisibles au J7).
- `data/pokemon/moves/moves.json` : les capacités nouvelles de ces apprentissages ; une mécanique que le moteur n'a pas (poison, coups multiples, peur, taux de critique élevé) va dans `pending_effects` (précédent : Poudre Toxik) — la capacité frappe une fois, sans l'effet, jusqu'au J11.
- `data/pokedex/kanto.json` : taille et poids officiels des 10 ; **descriptions `draft` pour les 4 espèces rencontrables** (les 6 évolutions ne peuvent être ni vues ni capturées au J7).
- `data/encounters/route_22.json` : Rattata, Piafabec, Férosinge, Nidoran ♀ et ♂, niveaux et taux de **Rouge/Bleu** (les deux versions réunies pour les deux Nidoran), relevés sur une source fiable par la tâche et cités dans le commit ; même rampe que la Route 1.
- Sprites de combat (face, dos) des 4 espèces rencontrables : style selon **Q-2**.

**Tests (T21)** : `test_pokemon_data` (10 espèces valides, chaînes d'évolution), `test_encounter_library` (table de la Route 22), `test_pokedex_library` (références), simulation `tools/simulate_grass_pacing.gd` relancée sur la Route 22 (rythme comparable à la Route 1).

### 3.8 Rival n° 2 : IA de niveau 2 et gains (T24) — **fait** (écarts au §15.5)

```gdscript
## BattleAI : nouvelle sorte, par son nom (dossier 09 §14, règle durable).
const SMART: StringName = &"smart"
const KINDS: Array[StringName] = [RANDOM, SMART]
## [param data] : capacités et table des types (null : comportement « random »).
func choose(own: BattleSide, foe: BattleSide, rng: GameRng, data: PokemonData = null) -> BattleAction
## Note d'une capacité pour l'IA « smart » (pure, testée seule).
static func score_move(move: MoveData, own: Battler, foe: Battler, chart: TypeChart,
		times_used: int) -> float
```

Règles de `smart` (dossier 09 §14) : (1) une attaque **sans effet** (×0) n'est jamais choisie s'il existe une autre option ; (2) une attaque **super efficace** l'emporte sur toute attaque neutre ; (3) une capacité de statut n'est plus choisie si son effet est déjà au maximum, ni plus de **deux fois** par combat (« n'abuse pas ») ; (4) sous **⅓ de ses PV**, plus aucune capacité de statut (« plus agressif quand il est faible ») ; (5) parmi les meilleures notes à égalité, un tirage `rng.pick_index` (reproductible). Note d'une attaque = puissance × STAB × efficacité × précision. `Battle` passe `_data` à `choose` ; `random` est **inchangée** (tests et simulations du J4/J5 identiques).

`TrainerData` : `allow_bag: bool = true` (clé `"bag"`), `prize_per_level: int = 0` (clé `"prize_per_level"`, exclusive de `prize_money` > 0). `BattleConclusion.resolve(trainer, outcome, last_foe_level := 0)` : argent = `prize_money` ou `prize_per_level × niveau du dernier Pokémon de l'équipe adverse`. `BattleViews.trainer_actions(trainer) -> Dictionary[StringName, bool]` remplace la constante. `rival_lab` : `"bag": false`. `rival_route22` (`data/trainers/rival.json`) : IA `smart`, `can_lose: false`, `heal_after: false`, `gives_exp: true`, `prize_per_level: 35` (Rouge/Bleu, provisoire), `bag: true`, `start_message: true` (« Le rival veut se battre ! » est le message générique, dossier 09), `end_message: false` ; `team_by_starter` : Roucool Nv. 7 puis le starter avantagé Nv. 8 (Bulbizarre → Salamèche, Salamèche → Carapuce, Carapuce → Bulbizarre).

Étape de scène **`wake_up`** (fin d'enum) : appelle `DefeatRecovery.recover()` (§6.4). Message de combat `prize_won` (« Tu remportes {money}. », `draft`).

**Tests (T24)** : `test_battle_ai` (chaque règle seule, sur des camps construits à la main ; `random` inchangée), `test_battle_conclusion` (formule, défaite = 0, `can_lose: false` → `blackout`), `test_trainer_library` (`bag`, `prize_per_level`, exclusivité), `test_battle_views` (SAC selon le dresseur), `tools/simulate_first_battle.gd` adapté au rival n° 2 (taux de victoire d'une équipe « naturelle » Nv. 7–8, à rapporter : base de la Q-14).

---

## 4. La règle de déblocage appliquée au J7

> « Une fonctionnalité visible n'existe pas pour le joueur avant son déblocage narratif, mais les données nécessaires peuvent déjà être collectées silencieusement » (vision.md ; dossier 09 §6).

- **Pokédex** : rien avant `pokedex_activated` (déjà vérifié par `test_menu_unlock_rule` au J6). Le drapeau est posé par la scène de Chen (7A.5), **une seule fois**, jamais par un départ de débogage (`DebugUnlocks.pokedex` reste un déblocage de session). À l'activation : la 6e carte, les compteurs, les Pokémon observés de la Carte, la chaîne d'évolution découverte, la carte de capture « Nouvelle entrée Pokédex », **sans toast de rattrapage** (défaut du T14).
- **Stockage** : l'écran n'existe qu'au Centre (`MenuUnlocks.storage_available`). Avant le premier Centre, rien ne le mentionne ; le message « confié au système de recherche de Chen » reste le seul signe (J5).
- **Boutique** : un écran seul, ouvert par le marchand ; jamais une carte du tableau de bord.
- **Argent** : affiché dans la Boutique, le Sac et l'écran Dresseur ; jamais au tableau de bord, au Pokédex ni sur la Carte (dossier 09 §10, dossier 08 règle 5). Dès le début ou seulement après la première Boutique : **Q-8**.
- **Rival n° 2** : la scène ne se déclenche pas sans `pokedex_activated` ; la Route 22 reste explorable (dossier 09 §13).
- **Services sur la Carte** : un service n'apparaît qu'après la visite de sa carte `found_on` (déjà codé au T18) : Centre → `viridian_center`, Boutique → `viridian_mart`, Arène → `viridian_city` (visible dès l'arrivée, fermée).

**Comment on le teste** : `test_menu_unlock_rule` étendu (partie au Centre sans Pokédex : Stockage disponible, aucune trace du Pokédex dans le Stockage ni la Boutique) ; `test_parcel_scene` (7A.5, vrai `Boot`) : avant la scène 5 cartes, après 6, les données d'avant l'activation présentes dans la grille ; `test_rival_route22` (7B.2) : sans le drapeau, traverser le déclencheur ne lance rien.

---

## 5. Données et sauvegarde

### 5.1 Version 3 du format (T0 — **fait** ; validée seule sur le S24 au T1)

**Pourquoi une version 3** pour peu de champs : un APK du J6 qui lirait une sauvegarde du J7 ignorerait `money` et `first_wild_encounter` puis les effacerait au premier autosave (et ne connaîtrait pas le colis). Avec `VERSION = 3`, il refuse le fichier sans l'écraser (code du J6, inchangé : nouvelle partie **sans autosave**, fichier intact). **Une seule version pour tout le J7** : les autres faits du J7A et du J7B entrent dans des champs qui existent déjà (tableau ci-dessous).

| Champ | Forme v3 | Valeur pour une partie v2 (migration `_upgrade_2_to_3`) | Sert à |
|---|---|---|---|
| `money` | entier, 0 à 999 999 | **3 000** (`SaveSystem.V3_MIGRATED_MONEY`, dossier 09 §17 : même somme qu'une nouvelle partie) | 7A.3, 7B.2 |
| `first_wild_encounter` | `{ "species", "map", "date" }` (chaînes), **toujours écrit**, `{}` = aucune | **rattrapé** (règle ci-dessous), `{}` si introuvable (la réplique de Chen est omise) | 7A.5 |
| `heal_map`, `heal_spawn` | inchangés (le point de repos ; l'orientation et le mot de réveil viennent de `rest_points.json`) | inchangés (la maison) | 7A.2 |
| `bag` | inchangé (le colis est un objet `key` ; acheter passe par `Bag.add`, qui tient `acquired`) | inchangé | 7A.3 |
| `party[i].favorite`, `storage[i].favorite`, `storage` | inchangés (v2) ; libérer retire l'entrée, sans trace | inchangés | 7A.4 |
| `flags` | inchangé : `viridian_arrived`, `got_oak_parcel`, `pokedex_activated`, `rival_route22_won` / `rival_route22_lost` (**aucun des deux = pas affronté** : les trois états du dossier 09 §17), drapeaux posés par les dialogues | inchangé | partout |
| `moments` | inchangé (le rival n° 2 est daté par `Boot._on_battle_finished` comme le premier) | inchangé | 7B.2 |
| `discovered_maps`, `pokedex`, `found_items` | inchangés | inchangés | 7A.1, 7A.5 |

**Pas dans la sauvegarde** (déduits ou de session) : les services découverts (`discovered_maps`), l'Arène vue (son service `found_on = viridian_city`, au lieu du drapeau du dossier 09 §17 : une source par fait), l'objectif, le stock de la Boutique (données + drapeaux), l'onglet et la quantité de la Boutique, la sélection du Stockage, le profil de lumière, l'absence du Roucool du toit après la micro-scène (jusqu'au changement de carte), les réglages (`user://settings.json`, à part).

**Règle de rattrapage de la première espèce sauvage** (`SaveSystem.recover_first_wild_encounter(content, from_v1)`, pure, documentée dans le code). Avant la v3, « vu » au Pokédex vient de quatre sources : le début d'une rencontre sauvage (table `route_1_grass`, cartes **`route_1` et `pallet_town`**), OBSERVER (J6, T16 : Pokémon des habitants à `pallet_town`, starters à `oak_lab`), le Pokémon du rival (`oak_lab`) et le starter (« capturé » à `oak_lab`). Une capture n'a lieu qu'au bout d'un combat sauvage.
1. **Sûr et daté** : une entrée du Pokédex dont la **première observation** est sur la **Route 1** (aucune autre source n'y a jamais existé) → date = début de la rencontre. Pour un fichier **écrit par une build du J5** (v1, migré en chaîne 1 → 2 → 3), Bourg Palette compte aussi (OBSERVER n'existait pas).
2. **Sûr, date majorée** : une **capture** sur `route_1` ou `pallet_town` (Pokédex `first_caught_*`, rencontre `met` d'origine `capture` de l'équipe et du stockage, grand moment `first_capture`) → le combat a commencé avant cette date.
3. La candidate **la plus ancienne** l'emporte (dates ISO de l'appareil comparées comme chaînes ; à égalité : règle 1, puis ordre alphabétique de l'espèce). La carte retenue est celle de la candidate.
4. Sans aucune candidate datée : si **une seule** espèce a la Route 1 (ou, pour une v1, Bourg Palette) dans ses `seen_maps`, c'est elle, **date vide**. Sinon : `{}`.

**Limites** (assumées) : une espèce vue d'abord autrement (OBSERVER à Bourg Palette, Pokémon du rival) puis **combattue sans être capturée** n'a pas de date de combat ; si ce combat précède tous les autres, la règle désigne une autre espèce (ou aucune). Un combat dans l'herbe de Bourg Palette **écrit par une build du J6**, sans capture, est indiscernable d'une observation : il est ignoré. La date d'une candidate de la règle 2 est celle de la capture, pas celle du début du combat. Aucune de ces limites ne touche la partie de Kevin (Roucool vu d'abord sur la Route 1). À partir de la v3, le fait est enregistré au début de chaque rencontre (§3.1) : plus d'approximation.

**Fixture v2 réelle** : `tests/fixtures/save/v2_kevin_j6.json` = copie **telle quelle** de `build/qa/jalon06_t1/save_v2_apres_t0.json` (dépôt principal), la vraie partie de Kevin en v2 relevée au **T1 du J6** (2026-10-03) : Route 1 (24, 2) face au bas, Salamèche Nv. 6 (21 PV), Roucool Nv. 3, Rattata Nv. 3, 2 Poké Balls et 1 Potion, 4 espèces au Pokédex, 3 grands moments, 3 732 s de jeu. **Aucune copie de la fin du J6 n'existe** (§0 point 10) : l'étape 1 du T1 la relève ; si elle diffère, elle **remplace** la fixture (même nom), les attendus des tests sont ajustés (espèce, position, équipe) et `tools/test.sh` est relancé avant l'étape 2. Attendu pour la fixture actuelle : **`{ "species": "pidgey", "map": "route_1", "date": "2026-10-02T20:51:16" }`** (Roucool, règle 1).

**Fixture de fin de J6 (T1, étape 1)** : `tests/fixtures/save/v2_kevin_j6_fin.json`, copie exacte de la partie relevée sur le S24 (`integ-j7/build/qa/jalon07_t1/save_v2_kevin.json` : Route 1 (24, 8) face à droite, Rattata en tête, Roucool favori, Potion favorite à 0, notes, 50 250 s). Même espèce trouvée : **Roucool**, `2026-10-02T20:51:16`. Testée dans `test_save_system` et `test_save_boot` (tout le reste identique, notes comprises) ; la fixture du T1 du J6 reste pour les tests existants.

**Tests (T0, faits)** : `test_save_system` (v2 réelle migrée à la lecture : `money` 3 000, Roucool, **tout le reste identique** ; chargée puis réécrite en v3 : tout le reste réécrit à l'identique, aucun champ perdu, aller-retour stable ; aller-retour v3 (argent, première rencontre) ; v4 refusée, intacte ; **v3 lue par un `SaveSystem` en version 2 → refusée « 3 > 2 », intacte, aucune écriture ni renommage, pas mise de côté** ; v3 refusée par une build v1 ; v1 réelle migrée 1 → 2 → 3 (Roucool, `2026-10-02T19:10:43`) ; `upgrade` 2 → 3 sur un fichier nu, un champ déjà présent gardé, des champs mal formés ; règle de rattrapage : Route 1 la plus ancienne, observation de Bourg Palette ignorée en v2 et comptée en v1, capture comme date majorée, rencontres et moments sans Pokédex, repli sans date (une seule espèce / deux = aucune), rien sans rencontre), `test_game_state` (clés de `to_dict`, nouvelle partie à 3 000 ₽, `add_money` plafonné et sans négatif, `spend_money` refusé sans rien changer, somme exacte, `record_wild_encounter` une seule fois, chargement tolérant), `test_encounter_director` (première rencontre retenue au début, la suivante ne la remplace pas), `test_save_boot` (vrai `Boot` : la v2 réelle reprend à l'identique — carte, case, orientation, équipe, Sac, argent, espèce, temps de jeu — puis est réécrite en v3 avec **tout le reste identique**, à part les notes du Pokédex que le J6 débloque au chargement selon les drapeaux (la fixture est d'avant leurs données) ; la v3 devant le vrai `Boot` d'une build v2 → nouvelle partie, aucune écriture de la session, fichier intact ; v1 réelle réécrite en v3).

#### 5.1.1 Protocole S24 du T1 (migration validée seule)

But : la **vraie partie de Kevin** (fin du J6, sur le S24, format v2) passe en v3 sans rien perdre, avec 3 000 ₽ et sa première espèce sauvage, et l'APK du J6 ne l'écrase jamais. Tout se fait depuis le Mac, S24 branché (ou débogage sans fil), APK **debug** (sinon `run-as` est refusé). Dossier des preuves : `build/qa/jalon07_t1/`. Variables : `ADB=~/Library/Android/sdk/platform-tools/adb`, `S=$(tools/s24_serial.sh)`, `PKG=dev.kevin.kanto2026`.

**Règles de sécurité** : jamais `adb uninstall`, jamais « Effacer les données » (la partie disparaîtrait) ; toujours `install -r` (et `-r -d` pour revenir à l'APK du J6) ; les deux APK sont signés par la même clé debug du Mac, sinon `install -r` échoue **sans** toucher aux données : s'arrêter et prévenir. Jamais `pkill` / `killall` sur Godot.

0. **APK du J6, à part, sans toucher au dépôt** (une fois, avant tout) :
   ```bash
   mkdir -p ~/dev/kanto-2026-j6 && git -C ~/dev/kanto-2026 archive 2f7da20 | tar -x -C ~/dev/kanto-2026-j6
   cd ~/dev/kanto-2026-j6 && godot --headless --path . --import >/dev/null 2>&1; \
     godot --headless --path . --export-debug "Android" ~/dev/kanto-2026/build/kanto2026-j6-debug.apk
   grep "VERSION: int" ~/dev/kanto-2026-j6/game/systems/save/save_system.gd   # doit dire 2
   ```
   (`2f7da20` = T30 du J6, dans `main` ; `git archive` ne fait que lire les objets. Dossier **hors** du projet.)
1. **Sauvegarde de départ et copie de secours** (APK du J6 encore installé, application arrêtée) : `$ADB -s $S shell am force-stop $PKG`, puis `$ADB -s $S shell run-as $PKG ls files` (noter la présence de `debug_start.json` / `debug_unlocks.json` : le déploiement du T0 les retire) et `$ADB -s $S exec-out run-as $PKG cat files/save.json > build/qa/jalon07_t1/save_v2_kevin.json`. Contrôler : `"version": 2`, la carte, la case, l'équipe (Kevin la lit à voix haute : espèces, Nv., PV), le Sac, le temps de jeu, **pas de clé `money`**. **Cette copie est la sauvegarde de secours** (restauration : application arrêtée, `$ADB -s $S shell "run-as $PKG sh -c 'cat > files/save.json'" < build/qa/jalon07_t1/save_v2_kevin.json`). Copier aussi `files/settings.json` (`settings_j6.json`). Capture d'écran du jeu si possible (référence de la reprise). **Fixture** : si `save_v2_kevin.json` diffère de `tests/fixtures/save/v2_kevin_j6.json`, la remplacer (copie telle quelle), ajuster les attendus de `test_save_system` / `test_save_boot` (espèce attendue par la règle du §5.1, position, équipe), `tools/test.sh` vert, commit — **avant** l'étape 2. Calculer l'espèce attendue au Mac : `jq '.pokedex.entries | to_entries | map(select(.value.first_seen_map=="route_1")) | sort_by(.value.first_seen_date) | .[0].key' build/qa/jalon07_t1/save_v2_kevin.json` (règle 1 ; si vide, appliquer les règles 2 à 4 à la main ou par les tests).
2. **Installer le build du T0** : `tools/deploy_s24.sh` (construit, `install -r`, retire les fichiers de débogage, lance, capture, journal). Ne pas bouger avant la vérification.
3. **Reprise exacte** : même carte, même case, même orientation ; comparer à l'étape 1 : équipe (ordre, Nv., PV), Sac, temps de jeu qui reprend (pas remis à 0). Journal : « Sauvegarde chargée : … », **aucune** ligne `SaveSystem` ni `Boot : sauvegarde chargée en partie seulement`, aucun `ERROR`. (L'argent n'a pas encore d'écran : il se vérifie dans le fichier, étape 4.)
4. **Écrite en v3** : Accueil (la sauvegarde est écrite au passage en arrière-plan), puis `$ADB -s $S exec-out run-as $PKG cat files/save.json > build/qa/jalon07_t1/save_v3_apres_t0.json`. Attendu : `"version": 3` ; `"money": 3000` ; `"first_wild_encounter"` = `{ "species": <espèce de l'étape 1>, "map": "route_1", "date": <sa première observation> }` (Kevin confirme de mémoire la première espèce qu'il a affrontée dans les herbes) ; **tout le reste identique** à l'étape 1, sauf `play_time` (plus grand) et la position si Kevin a bougé. Comparaison au Mac : `diff <(jq -S 'del(.version,.money,.first_wild_encounter,.play_time)' build/qa/jalon07_t1/save_v2_kevin.json) <(jq -S 'del(.version,.money,.first_wild_encounter,.play_time)' build/qa/jalon07_t1/save_v3_apres_t0.json)` → **vide**. Aucun fichier `save.json.corrupt` (`$ADB -s $S shell run-as $PKG ls files`).
5. **Quitter et relancer** (application tuée depuis les applications récentes) : reprise identique à l'étape 3, journal propre ; le fichier relu reste en v3 avec les mêmes `money` et `first_wild_encounter`.
6. **Retour à l'APK du J6** : `$ADB -s $S shell run-as $PKG rm -f files/debug_start.json files/debug_unlocks.json` (un départ de débogage ne lirait pas la sauvegarde : le test ne prouverait rien), `$ADB -s $S install -r -d build/kanto2026-j6-debug.apk`, `logcat -c`, lancer. Attendu : **partie neuve** (chambre), journal `SaveSystem : sauvegarde d'une version plus récente (3 > 2) : mise à jour du jeu requise` puis `Boot : … Nouvelle partie SANS sauvegarde automatique`. Jouer 1 à 2 minutes (sortir de la chambre, changer de carte, ouvrir le menu, passer en arrière-plan) : rien ne doit être écrit. Puis `run-as … cat files/save.json` → **identique octet pour octet** à `save_v3_apres_t0.json` (`cmp`) ; `ls files` : ni `.corrupt`, ni `.tmp`.
7. **Retour au J7** : `tools/deploy_s24.sh --no-build` (réinstalle le build du T0 avec `install -r`). Attendu : la partie de Kevin reprend exactement comme à l'étape 5 ; `save.json` toujours en v3, 3 000 ₽, même première espèce.
8. **Rapport** : chaque étape conforme ou non, les fichiers JSON (`save_v2_kevin.json`, `save_v3_apres_t0.json`, relevés des étapes 5 à 7) et les journaux (`logcat_etape_N.txt`) dans `build/qa/jalon07_t1/`, captures, nombre de sauvegardes automatiques vues, la confirmation de Kevin sur l'espèce, et sa validation (« sa partie est là »). En cas d'écart à l'étape 3 ou 4 : **ne plus lancer le J7**, réinstaller l'APK du J6 (`-r -d`), restaurer la copie de l'étape 1, rapporter.

### 5.2 Données nouvelles ou étendues (`data/`)

```
data/world/lighting.json          profils de lumière (golden_hour, interior_warm)          T2
data/world/rest_points.json       maison, Centre de Jadielle                               T6
data/world/zones.json             Jadielle (3 cartes, 3 services), Route 22 ; descriptions draft   T4, T22
data/npcs/viridian_city.json      habitants, Pokémon d'ambiance, routines                  T4
data/npcs/viridian_center.json    infirmière, Dresseurs au repos                           T8
data/npcs/viridian_mart.json      marchand, client                                         T12
data/npcs/oak_lab.json            + rival de la scène du colis (présence conditionnelle)   T19
data/npcs/route_22.json           voyageur, jeune Dresseur, Pokémon d'ambiance             T22, T25
data/dialogues/viridian_city.json habitants, Arène (textes §19)                            T4
data/dialogues/viridian_center.json  infirmière, réveil, terminal                          T8, T16
data/dialogues/viridian_mart.json marchand                                                  T12
data/dialogues/oak_lab.json       + colis, activation, rival (§19)                          T19
data/dialogues/route_22.json      voyageur, scène et répliques du rival (§19)              T22, T25
data/cutscenes/viridian_city.json micro-scène d'arrivée                                    T4
data/cutscenes/viridian_mart.json première visite (colis)                                  T12
data/cutscenes/oak_lab.json       remise du colis et activation                            T19
data/cutscenes/route_22.json      rival n° 2                                               T25
data/items/items.json             prix, oak_parcel                                         T10
data/shops/viridian_mart.json     stock : Poké Ball, Potion                                T10
data/story/objectives.json        colis ; fin de « rejoindre Jadielle »                    T10
data/pokemon/species, moves       10 espèces, capacités                                    T21
data/pokedex/kanto.json           10 espèces, 4 descriptions draft                         T21
data/encounters/route_22.json     Rouge/Bleu                                               T21
data/trainers/rival.json          rival_lab : bag false ; rival_route22                    T24
data/battle/messages.json         prize_won (draft)                                        T24
```

Vérifier dans l'APK (`unzip -l`) : `data/world/`, `data/shops/` (nouveau dossier, règle des jalons précédents).

### 5.3 Moments d'autosave ajoutés

- **Soin au Centre** : écriture dès la fin du rituel (le joueur est au comptoir, état stable : dossier 09 §7).
- **Fermeture de la Boutique ou du Stockage** si quelque chose a changé (`mark_changed`, comme le J6).
- **Fin de la scène de Chen**, **fin de la scène du rival** : `cutscene_finished` (existant).
- **Réveil après une défaite** (sauvage ou Dresseur) : écriture immédiate au point de repos (règle de la QA S3 du J5, réutilisée par `DefeatRecovery`).

### 5.4 Textes

Les textes du dossier 09 §19 sont **la référence** (validés, raccourcissables à la QA). Tout texte **absent** du §19 entre en `draft` et part dans un seul lot à relire (§12, « Textes à relire »).

### 5.5 Départs de débogage (`tools/debug_start/`)

`viridian` (arrivée au bord sud de Jadielle, équipe Nv. 7–8 réaliste, `rival_battle_done`) · `center_qa` (équipe blessée et un K.O., devant le Centre) · `shop_qa` (6 000 ₽, des Potions favorites, devant la Boutique) · `storage_qa` (6 en équipe dont un K.O., 10 au stockage dont un favori, au Centre) · `parcel` (colis en main, devant le labo) · `route_22` (Pokédex activé, équipe Nv. 8, entrée de la Route 22) · `rival_2_weak` (équipe Nv. 4, pour perdre). `DebugStart` gagne `money` et `storage` (même format que `party`). **TODO (après le T0)** : le T2 a livré `viridian` **sans** ces deux clés (elles dépendent de `GameState.money` et de la sauvegarde v3, faites en parallèle) ; les ajouter à `DebugStart` (`_KEYS`, `apply`, `test_debug_start`) dès la fusion du T0, au plus tard avec `center_qa` (T8) / `shop_qa` (T12) qui en ont besoin (§15.2).

---

## 6. Architecture

### 6.1 Arbre des scènes

```
game/boot.tscn
Boot (Node, ALWAYS)
├─ World (Node2D, PAUSABLE)                         la carte courante
├─ WorldLighting (CanvasLayer, PAUSABLE)            NOUVEAU (T3) : étalonnage d'écran, calque
│                                                   LAYER_WORLD_GRADE (6), au-dessus du monde et de
│                                                   BattleStage (5), sous le HUD (10)
├─ BattleStage, ExplorationHud, BattleHud, StarterSheet, DialogueBox             (existants)
├─ DialogueRunner, InteractionController, CutsceneDirector, StarterChoice        (existants)
├─ BattleDirector, AmbientWatcher, EncounterDirector                             (existants)
├─ DefeatRecovery (Node, PAUSABLE)                  NOUVEAU (T8) : soin, fondu, point de repos, réveil
├─ ServiceDirector (Node, PAUSABLE)                 NOUVEAU (T8) : actions de dialogue (soins,
│                                                   Boutique, Stockage), toast du point de repos
├─ MenuDirector (ALWAYS), TrainerMenu (ALWAYS)      + routes SHOP et STORAGE (écrans seuls)
├─ ScreenFade, ComingSoonScreen
Autoloads : SceneRouter, GameState (inchangés ; aucun nouvel autoload)
```

**Aucun nouvel autoload** : `Boot` tient `LightingLibrary`, `RestPointLibrary`, `ShopLibrary` comme les autres bibliothèques. `ServiceDirector` et `DefeatRecovery` évitent d'alourdir `boot.gd` (824 lignes) : `Boot` ne fait que les relier.

```
game/world/lighting/        WorldLighting, LightProfile, LightingLibrary ; shaders/ :
                            ground_blend, world_object (vent + liseré), cast_shadow, contact_shadow,
                            screen_grade (identifiants anglais, commentaires français)
game/world/props/painted/   une scène WorldProp par asset peint (générées, §6.6)
game/world/maps/            viridian_city, viridian_center, viridian_mart, route_22 (.tscn générés)
game/world/rest/            RestPoint, RestPointLibrary, DefeatRecovery
game/systems/services/      ServiceDirector
game/systems/shop/          ShopData, ShopLibrary, ShopRules, ShopViews (+ views/)
game/systems/storage/       StorageRules, StorageViews (+ views/)
game/systems/dialogue/      + DialogueChoice, DialogueTokens
game/ui/shop/               ShopScreen (ACHETER / VENDRE, sélecteur de quantité, total)
game/ui/menu/storage/       StorageScreen
assets/world/               buildings/, props/, ground/, relief/, interiors/, backdrops/
                            (textures préparées à 1:1 + ombres pré-floutées)
assets/sprites/characters/painted/   planches et SpriteFrames des PNJ du J7
assets/sprites/pokemon/painted/      Pokémon du monde (Roucool, Rattata, Piafabec, Férosinge, Nidoran)
```

### 6.2 Signaux et flux

```
Interaction (PNJ, terminal)
  → DialogueRunner.play
      ├─ pages (jetons résolus, page omise si jeton vide)
      ├─ choice_requested(view) → ChoiceCards s'affiche (question dans view.title, boîte ouverte derrière)
      │     ChoiceCards.chosen(confirmed) → DialogueRunner.choose(confirmed)
      ├─ action → await action_handler(action) = ServiceDirector.run_action
      │     heal          → Party.heal_all (Maman) ; heal_requested (autosave « soin »)
      │     center_heal   → Party.heal_all ; rituel 3 s sur la carte ; RestPointLibrary.register
      │                     → toast « Point de repos enregistré — Jadielle » si changé ; autosave
      │     open_shop     → MenuDirector.open(MenuRoute.shop(id), standalone)
      │     open_storage  → MenuDirector.open(MenuRoute.storage(), standalone)
      └─ cutscene_requested(id) → CutsceneDirector.play(id)
Rencontre sauvage perdue ─┐
Étape « wake_up »        ─┴→ DefeatRecovery.recover() : soin, SceneRouter.change_map(point de repos),
                              woke_up(map) → Boot écrit la sauvegarde ; mot de réveil du lieu
BattleDirector (victoire contre un Dresseur) → GameState.add_money(prize) ; message prize_won
SceneRouter.map_changed → WorldLighting.apply(LightingLibrary.get_profile(map.light_profile))
```

### 6.3 Le Centre (7A.2)

- **Carte `viridian_center`** : enveloppe vide (`INT_CENTRE_COQUE`, 15 × 10 cases) dans le sol, meubles séparés (`comptoir`, `terminal`, `banquette` ×2, `plante`), murs = cases bloquées déclarées par l'outil de construction (épaisseur lue sur l'enveloppe), sortie = 2 cases PUSH vers le bas. **Pas d'escalier**, **pas de Leveinard** (arbitrages du dossier 09).
- **Rituel (~3 s)** : la machine du comptoir (`%HealMachine`, `AnimationPlayer` « heal » : six emplacements qui s'allument un à un, puis un éclat ; l'infirmière se tourne vers la machine puis revient) ; vibration légère par `Haptics` ; durée `UiTokens.CENTER_HEAL` (3,0 s ; ×0,5 avec « Réduire les animations »). Le joueur est bloqué par le dialogue tout du long.
- **Point de repos** : `RestPointLibrary.register` ; la maison reste le point de retour tant qu'aucun Centre n'a servi (déjà vrai : défaut de `GameState`).
- **Réveil** : `DefeatRecovery` remplace `EncounterDirector._handle_defeat` (le signal `woke_up_after_defeat` reste, relayé). Au Centre, le mot de réveil `nurse_wakeup` reprend la réplique validée « Voilà. Tout le monde est en pleine forme. » (aucun texte nouveau, Q-9).

### 6.4 La Boutique et le Stockage (7A.3, 7A.4)

- **Boutique** : écran seul dans `TrainerMenu` (fond flouté, monde en pause, retour Android = fermer). Gauche : onglets ACHETER / VENDRE et argent ; centre : cartes d'objets du **langage du Sac** (`BagItemCard`) ; droite : aperçu (nom, description, prix, DANS LE SAC), sélecteur QUANTITÉ (− / + et appui long qui accélère), TOTAL calculé tout de suite, CONFIRMER, RETOUR. Un achat = un toucher sur CONFIRMER, **sans seconde confirmation** ; « Merci ! » dans la barre de résultat (`UseResultBar`). Vendre un favori : `ChoiceCards` (« Vendre {objet} ? » — texte `draft`).
- **Première visite** : déclencheur sur les cases d'entrée de la Boutique (`unless: got_oak_parcel`) → scène : le marchand parle (4 pages du §19), `give oak_parcel` (toast), `set got_oak_parcel`. **La Boutique ne s'ouvre pas d'elle-même après** ; lui reparler → « Bonjour ! Qu'est-ce qu'il te faut aujourd'hui ? » → `open_shop`.
- **Stockage** : écran en trois colonnes (ÉQUIPE · Pokémon sélectionné et ses actions · STOCKAGE en grille défilante). Glisser une carte de l'équipe au stockage (et retour) après un appui long (`LONG_PRESS`, comme l'Équipe) **ou** sélectionner puis DÉPOSER / REPRENDRE ; FAVORI ; « ⋯ » ouvre le menu secondaire LIBÉRER → `ChoiceCards` (« Libérer {Pokémon} ? » / « Il quittera définitivement ton équipe et ton stockage. » / LIBÉRER / ANNULER). Refus = tremblement de la carte + raison (langage du 6B). Accès : le **terminal** (examiner → `open_storage`, écran seul) et un bouton **STOCKAGE** dans l'écran Équipe quand `storage_available` (dossier 09 §8 « par le menu Équipe »).

### 6.5 Choix à deux cartes dans un dialogue (7A.2)

`DialogueBox` reste ouverte ; `ChoiceCards` (T28) apparaît au-dessus avec son voile, **la question dans `ChoiceView.title`** (le voile couvre la boîte : défaut du T0, §0 point 1, comme OUBLIER / GARDER), cartes ≥ `TOUCH_MIN`, dans `SAFE_MARGIN`. Retour Android pendant le choix = la carte d'annulation (`ChoiceCards` ne le gère pas : la boîte s'en charge). Interface figée au T6 :

```gdscript
## DialogueBox (ui-mobile, T7)
signal choice_made(confirmed: bool)
func show_choice(view: ChoiceView) -> void
func hide_choice() -> void
```

`Boot` relie `DialogueRunner.choice_requested` → `DialogueBox.show_choice` et `DialogueBox.choice_made` → `DialogueRunner.choose`.

**Précisions figées au T6** (contrat de la boîte pour le T7, sans rien changer à `ChoiceView` ni à `ChoiceCards`) :
- `show_choice(view)` : la boîte (ouverte) montre un `ChoiceCards` **à elle** (enfant, au-dessus de son panneau, créé au premier besoin et gardé), avec `view` tel quel ; un appel boîte fermée est ignoré (push_warning).
- `choice_made(confirmed)` : **un seul par question** (relais de `ChoiceCards.chosen`). Retour pendant le choix = `choice_made(false)` : `func cancel_choice() -> bool` (vrai si un choix était affiché : il se ferme et émet `choice_made(false)` ; sinon faux, rien) ; la boîte l'appelle elle-même sur `ui_cancel` (clavier) ; le retour **Android** arrive à `Boot._on_go_back` (`NOTIFICATION_WM_GO_BACK_REQUEST`), qui appelle `_box.cancel_choice()` **en premier** (câblage du T8).
- Pendant le choix, la boîte **n'émet pas** `advance_requested` (le lecteur l'ignore de toute façon : `DialogueRunner.is_awaiting_choice()`).
- `hide_choice()` : cache sans signal ; `close()` cache aussi un choix encore affiché. `func is_choice_showing() -> bool` pour les tests.
- `UiPrefsApplier` (texte Grande, contraste) s'applique aux cartes comme au reste de la boîte.
- Le toast du point de repos n'est **pas** une tâche du T7 : `ExplorationHud.show_toast(titre, détail)` existe ; le T8 l'appelle avec `RestPointLibrary.registered_toast(zone)`.

**Partage des fichiers T7 ∥ T8** (§9 ; écran fusionné d'abord, câblage ensuite) :

| T7 — ui-mobile | T8 — constructeur-monde |
|---|---|
| `game/ui/dialogue/dialogue_box.gd` / `.tscn` ; `tests/integration/test_dialogue_box.gd` ; capture `nurse_choice` (scénario de capture du T7, vues fabriquées) | `game/boot.gd` / `.tscn` (câblage derrière `has_method(&"show_choice")`, `cancel_choice()` en tête de `_on_go_back`, `action_handler`, `cutscene_requested` non câblé avant le T19) ; `game/systems/services/` ; `game/world/rest/defeat_recovery.gd` ; `game/pokemon/encounters/encounter_director.gd` ; `game/ui/theme/ui_tokens.gd` (`CENTER_HEAL`) ; carte `viridian_center` et `tools/build_interiors.gd` ; `data/world/rest_points.json` (+ `viridian_center`), `data/dialogues/viridian_center.json` (`nurse`, `nurse_wakeup`), `data/npcs/viridian_center.json`, `data/world/zones.json` (cartes et service du Centre — **après** le T4, qui pose Jadielle) ; `tools/debug_start/center_qa.json` ; tests `test_center_heal`, `test_encounter_director`, `test_dialogue_data` (IDS), `test_rest_point_data` |
| ne touche pas `dialogue_runner.gd` (figé au T6), ni `boot.gd` | ne touche pas `dialogue_box.*` ; teste avec `tests/helpers/fake_choice_cards.gd` ou une boîte factice tant que le T7 n'est pas fusionné |

Ni l'un ni l'autre ne touche `dialogue_runner.gd`, `dialogue_library.gd` ni `rest_point_library.gd` : un écart trouvé remonte à l'architecte.

### 6.6 De l'art du prototype à la production

**Principe** : la branche `proto/da-jadielle` n'est **jamais fusionnée** ; on en reprend les **textures préparées** et les **techniques**, réécrites proprement dans `game/` avec des tests.

| Prototype (`proto/da_jadielle/`) | Production |
|---|---|
| `tex/*.png` (sorties de `preparer_proto.py`, versionnées sur la branche) | copiées dans `assets/world/…` et `assets/sprites/…/painted/` sous des noms stables (identifiant de fiche en `snake_case` : `bldg_centre_01.png`) ; le **manifeste** `tools/art/manifeste.json` (identifiant, source dans `build/art/`, sortie, taille en cases, étalonnage, ombre, emprise) remplace les tables de `preparer_proto.py` → `tools/art/preparer.py` ; on peut tout régénérer depuis `build/art/` sur le Mac, et le cloud n'en a jamais besoin |
| `sol.gdshader` : herbe + pavés mélangés par un masque de cases bruité, bande de terre | `ground_blend.gdshader` : masque **RG** (R pavés, G chemin de terre) écrit par l'outil de construction de la carte dans `assets/world/maps/<carte>_ground.png` (1 px = 1 case) ; textures herbe / pavés (× 0,7) / chemin ; même bruit, mêmes seuils. Le `TileMapLayer` `Ground` reste dans la carte, **invisible**, comme **source logique** (solide, herbes hautes, rebords) : `GameMap` et `GridWorld` ne changent pas |
| décalcomanies de bordure posées par script | posées par l'outil de construction, graine fixe par carte, dans un `Node2D` `GroundDecals` non trié |
| `ombre.gdshader` : silhouette floutée **à l'exécution** (25 lectures par pixel) | **ombre pré-floutée** par `tools/art/preparer.py` (`<id>_shadow.png`, alpha seul, demi-résolution) ; le shader `cast_shadow` ne fait **qu'une** lecture (couleur, fondu vers l'extrémité) ; écrasement et inclinaison posés une fois au chargement de la carte depuis le profil (le jour/nuit les fera varier) |
| `contact.gdshader` (60 lectures par pixel) | `<id>_contact.png` pré-calculée de la même façon, une lecture |
| `objet.gdshader` (vent + liseré, 4 lectures) | `world_object.gdshader`, mêmes calculs, paramètres en **`global uniform`** (`world_sun_dir`, `world_rim_color`, `world_rim_strength`, `world_wind`) posés par `WorldLighting` : changer d'ambiance ne touche aucun nœud |
| `etalonnage.gdshader` (copie d'écran) | `screen_grade.gdshader` dans `WorldLighting` ; gains en `global uniform` ; intensité 0 = calque caché |
| `emprises.gd` (règles par préfixe : Centre 8 × 4, Arène 10 × 4, arche nord = ses deux piliers, escalier et herbes traversables) | les mêmes règles dans la table de l'outil `tools/build_painted_props.gd`, écrites dans `WorldProp.footprint` de chaque scène générée (`game/world/props/painted/<id>.tscn` : `Sprite2D` au pied + ombre + contact) ; `GridWorld` les marque solides comme aujourd'hui. **Pas d'`AStarGrid2D`** : les routines de PNJ restent des boucles de cases voisines (`NpcSpec`), vérifiées par un test (aucune case solide, aucune case de passage obligé du joueur) |
| escalier « dans la couche du sol » (corrigé sur S24) | **falaises et escaliers** = sprites de la couche du sol (`GroundDecals`, non triés) : en vue de trois quarts, une face de falaise est toujours sous les personnages ; emprise = la rangée de la face ; l'escalier est la seule case libre de la falaise |
| intérieurs « enveloppe vide + meubles séparés » | enveloppe = sprite opaque du sol ; meubles = `WorldProp` peints ; murs = cases bloquées (`GameMap.blocked_cells`) écrites par `tools/build_interiors.gd` étendu |
| tri par les pieds (`y_sort`) | inchangé : `Entities` (y-sort), origine aux pieds, `fade_when_covering` pour les grands toits et les cimes |
| `marcheur.gd` (planche 4 × 4 lue à la main) | `SpriteFrames` générés par `tools/build_character_frames.gd` (`idle` = colonne 0, `walk` = 4 images, `run` = planche de course si elle existe, sinon `walk` accéléré) ; un cycle de 4 images couvre 2 cases (vitesse calée sur `Grid.WALK_STEP_DURATION`) ; `Npc` et `Player` passent par `CharacterLook` |
| sprite d'ombre des personnages | l'ellipse existante (`shadow.png`) pour tous les personnages, peints ou non (une ombre portée par image d'animation coûterait trop pour un gain faible) |

**Collisions et couches physiques** : le déplacement reste **sur la grille** (`GridWorld`), pas physique ; les couches physiques du `CLAUDE.md` ne servent qu'aux `Area2D` de grandes zones (aucune au J7). Une emprise = des cases de 96 px. Le test `test_painted_props` vérifie que chaque prop peint a une emprise (sauf la liste des traversables : escalier, herbes hautes, décalcomanies, fond peint) et que ses textures d'ombre existent ; les tests de carte (`test_map_links`, `test_npc_placement` étendus, `test_viridian_city`) vérifient warps, spawns, PNJ sur cases libres, routines possibles, et qu'un chemin existe entre toutes les entrées de la carte.

**Hautes herbes peintes (7B.1)** : la donnée `tall_grass` reste dans `Ground` ; l'image = deux touffes par case (`WORLD_GROUND_HAUTES_HERBES_01`, décalées, graine fixe) dans `Entities` ; le cache-jambes du joueur (`grass_front`) devient la **moitié basse de la touffe**, découpée par `tools/art/preparer.py` (pas une nouvelle génération). `GrassRustle` inchangé.

### 6.7 La lumière C2, système réutilisable

`WorldLighting.apply(profile)` à chaque changement de carte (écran noir du fondu) : `global uniform` des shaders, intensité de l'étalonnage, écrasement et inclinaison des ombres portées (groupe `cast_shadows`, une passe, aucun coût par image). Un profil vide coupe tout (`screen_grade` caché). **Jour/nuit (phase 10)** : `GameClock` choisira deux profils et un facteur ; il suffira d'ajouter `LightProfile.lerp(other, t)` et d'appeler `apply` quand l'heure change (ombres plus longues le soir par `cast_shadow_length`, liseré et gains plus chauds). Lampadaires et vitrines allumés le soir = cartes d'émission (cran B du cahier), plus tard. **Rien de cela n'est écrit au J7.**

### 6.8 Contrats des écrans (figés par l'architecte avant chaque paire ui-mobile ∥ constructeur-monde)

Comme au J6 (§6.6 à §6.12), chaque tâche d'architecture fige dans ce fichier, **avant** la paire suivante : les signaux et méthodes de l'écran, les vues, le partage des fichiers entre les deux agents, et l'ordre de fusion (écran d'abord, câblage ensuite, branchement de `Boot` derrière `has_signal`). Contrats attendus : T6 (§6.5, `DialogueBox`), T10 (`ShopScreen`), T14 (`StorageScreen`, bouton STOCKAGE de l'Équipe).

### 6.9 Contrat de l'écran Stockage (figé au T14)

Même modèle que l'Équipe : l'écran émet, `TrainerMenu` relaie (préfixe `storage_`), `Boot` relie au `MenuDirector` derrière `has_signal(&"storage_deposit_requested")`. **Toute règle passe par `StorageRules` dans le directeur** : l'écran ne décide d'aucun refus, il les montre.

```gdscript
## StorageScreen (ui-mobile, T15) — game/ui/menu/storage/storage_screen.gd, extends MenuScreen
signal back_requested
signal selected(place: int, index: int)             # informatif (toucher une carte)
signal deposit_requested(index: int)                # DÉPOSER, ou glisser une carte ÉQUIPE → STOCKAGE
signal withdraw_requested(index: int)               # REPRENDRE, ou glisser STOCKAGE → ÉQUIPE
signal favorite_toggled(place: int, index: int)     # FAVORI
signal release_requested(place: int, index: int)    # LIBÉRER du menu « ⋯ » (avant confirmation)
signal release_confirmed(place: int, index: int)    # carte LIBÉRER de la confirmation
func show_storage(view: StorageView) -> void        # vue neuve après chaque action ;
                                                    # view.result_text non vide → ligne de résultat
func show_refusal(place: int, index: int, text: String) -> void    # tremblement + raison (6B)
func ask_release(view: ChoiceView, place: int, index: int) -> void # ChoiceCards LIBÉRER / ANNULER
func go_back() -> bool   # retour : ferme d'abord la confirmation (= ANNULER) ou le menu « ⋯ »

## TrainerMenu (ui-mobile, T15)
signal storage_selected(place: int, index: int)
signal storage_deposit_requested(index: int)
signal storage_withdraw_requested(index: int)
signal storage_favorite_toggled(place: int, index: int)
signal storage_release_requested(place: int, index: int)
signal storage_release_confirmed(place: int, index: int)
func show_storage(view: StorageView) -> void
func show_storage_refusal(place: int, index: int, text: String) -> void
func ask_storage_release(view: ChoiceView, place: int, index: int) -> void
func storage_back() -> bool                         # appelé par Boot._screen_back

## MenuDirector (constructeur-monde, T16)
signal storage_shown(view: StorageView)
signal storage_refused(place: int, index: int, text: String)
signal storage_release_asked(view: ChoiceView, place: int, index: int)
func select_storage(place: int, index: int) -> void
func deposit_member(index: int) -> bool             # StorageRules.deposit
func withdraw_member(index: int) -> bool            # StorageRules.withdraw
func toggle_storage_favorite(place: int, index: int) -> bool
func request_release(place: int, index: int) -> bool   # refus → storage_refused ;
                                                       # OK → storage_release_asked(release_choice)
func confirm_release(place: int, index: int) -> bool   # StorageRules.release (règle revérifiée)
```

- **Glisser = un signal, bouton = le même** : glisser une carte de l'ÉQUIPE sur la grille émet `deposit_requested(index)` exactement comme DÉPOSER ; dans l'autre sens `withdraw_requested(index)` comme REPRENDRE. Le glisser part d'un **appui long** (`LONG_PRESS`, comme l'Équipe) ; la grille défile sans rien sélectionner (`TapGuard`, `scroll_deadzone = TAP_SLOP`). Pas de réordonnancement dans l'écran Stockage (V1 : l'Équipe le fait) ; un dépôt arrive à la fin, une reprise en fin d'équipe.
- **Directeur** : à l'entrée de la route STORAGE, sélection = `StorageSelection.first(party, storage)`, puis `storage_shown(StorageViews.build(state, data, sélection, zones, unlocks))`. Après une action : succès → sélection = `result.selection`, `mark_changed()` (autosave à la fermeture, comme le J6), vue neuve **construite avec le résultat** : `StorageViews.build(state, data, result.selection, zones, unlocks, result)` (ajout du 2026-10-05) ; refus → `storage_refused(place, index, StorageViews.result_text(result, data))` avec la place de `result.selection`, rien ne change, **pas** de vue neuve. `request_release` ne modifie rien.
- **Libérer** : `release_requested` → le directeur vérifie → refus (favori, équipe vide, tous K.O.) = tremblement + raison, **sans** confirmation ni bouton de contournement ; sinon `ask_release` montre `ChoiceCards` ; ANNULER (ou retour) ne fait rien ; LIBÉRER → `release_confirmed` → `confirm_release` → vue neuve dont `result_text` = « {Pokémon} a été libéré. ».
- **Ligne de résultat** (décision de Kevin du 2026-10-05) : l'écran montre `view.result_text` sur **une ligne de résultat, comme la barre du Sac** (`show_result` du Sac, variation de thème `ResultText`), quand il n'est pas vide ; une vue neuve dont le texte est vide l'efface (déposer, reprendre, favori, sélection : pas de texte). Seule la libération en produit un. Les refus restent sur `show_refusal` (tremblement + raison, pas de vue neuve) ; l'écran peut montrer leur raison sur la même ligne. Aucun signal nouveau : le texte voyage dans la vue.
- **Bouton STOCKAGE de l'Équipe** : présent seulement si `TeamView.storage_available` (absent ailleurs, jamais grisé) ; il émet `route_requested(MenuRoute.storage())` (signal existant de l'Équipe) ; retour = l'Équipe, rafraîchie (mécanique existante).
- **Terminal** : action `open_storage` → `MenuDirector.open(MenuRoute.storage(), standalone = true)` (le `standalone` du T10 : retour = fermer). `Boot` appelle une fois `_unlocks.set_location(_zones, <carte courante>)`.
- `UiPrefsApplier` appliqué à l'écran (comme les autres écrans du menu).

**Partage des fichiers T15 ∥ T16** (écran fusionné d'abord, câblage ensuite) :

| T15 — ui-mobile | T16 — constructeur-monde |
|---|---|
| `game/ui/menu/storage/` (`storage_screen.gd`, cartes, grille) ; `game/ui/menu/trainer_menu.gd` (hôte, relais `storage_*`, `storage_back`) ; `game/ui/menu/team/team_screen.gd` (bouton STOCKAGE si `view.storage_available`) ; `tests/integration/test_storage_screen.gd` (vues fabriquées) ; scénarios de capture `storage`, `storage_drag`, `storage_release`, `storage_refusal` | `game/systems/menu/menu_director.gd` (signaux et méthodes ci-dessus, route STORAGE) ; `game/boot.gd` (`set_location`, câblage derrière `has_signal`, `storage_back` dans `_screen_back`) ; `game/systems/services/` (`open_storage`) ; `data/dialogues/viridian_center.json` (terminal) ; `tools/debug_start/storage_qa.json` ; `tests/integration/test_menu_storage.gd`, `test_menu_director` étendu |
| ne touche ni `boot.gd` ni `menu_director.gd` | ne touche ni `storage_screen.*`, ni `trainer_menu.gd`, ni `team_screen.gd` ; teste avec un écran factice tant que le T15 n'est pas fusionné |

Ni l'un ni l'autre ne touche `game/systems/storage/**`, `menu_unlocks.gd`, `menu_route.gd`, `team_view.gd` / `team_views.gd`, `party.gd` ni `pokemon_storage.gd` (figés au T14) : un écart trouvé remonte à l'architecte.

---

### 6.10 Contrat de la Boutique (T10, figé) — pour T11 ∥ T12

**Vues** (`game/systems/shop/views/`, classes pures ; on peut seulement **ajouter** des champs ; texte vide = élément absent) :

```gdscript
class_name ShopView            ## construit par ShopViews.build(state, shop, items, mode)
var mode: StringName           ## ShopViews.MODE_BUY (&"buy") ou MODE_SELL (&"sell")
var shop_id: StringName
var modes: Array[StringName]   ## [buy, sell] ; mode_labels : ["ACHETER", "VENDRE"]
var mode_labels: PackedStringArray
var money_text: String         ## « 3 000 ₽ »
var entries: Array[ShopEntryView]
var empty_text: String         ## VENDRE sans rien de vendable : « Tu n'as rien à vendre. » (draft)
func entry(item_id: StringName) -> ShopEntryView

class_name ShopEntryView
var item_id: StringName
var name: String, plural: String, description: String, category_id: StringName
var favorite: bool             ## étoile ET texte
var owned: int                 ## owned_text « DANS LE SAC : 3 » (toujours écrit)
var owned_text: String
var unit_price: int            ## achat : prix ; vente : moitié arrondie en dessous
var price_text: String         ## « 200 ₽ »
var max_quantity: int          ## 0 = indisponible (sélecteur et CONFIRMER inactifs, reason dit pourquoi)
var reason: String             ## « Tu n'as pas assez d'argent. »
var needs_confirm: bool        ## VENDRE d'un favori
var card: BagEntryView         ## la carte BagItemCard (nom accordé à owned, ×owned, favori, icône)
func is_available() -> bool
func clamp_quantity(quantity: int) -> int   ## [1, max(max_quantity, 1)]
func get_icon() -> Texture2D
```

Textes : `ShopViews.LABEL_*` (ACHETER · VENDRE · QUANTITÉ · TOTAL · DANS LE SAC · CONFIRMER · RETOUR), `ShopViews.total_text(unit_price, quantity)` (TOTAL recalculé **par l'écran** à chaque cran, sans aller-retour au directeur), `ShopViews.status_text(status)`.

**Écran — `ShopScreen` (ui-mobile, T11)** : `game/ui/shop/shop_screen.gd` + `.tscn` (`class_name ShopScreen extends MenuScreen`, hébergé par `TrainerMenu` comme les autres écrans ; mise en page du §6.4 ; `TapGuard` sur les cartes, `scroll_deadzone = TAP_SLOP` ; `UiPrefsApplier`). La Boutique s'ouvre **seule** : ni tableau de bord, ni pastille de zone ; RETOUR et × ferment. L'écran ne fait **aucune règle** : il garde l'onglet affiché, l'objet sélectionné et la quantité (bornée par `clamp_quantity`), et relaie.

```gdscript
## TrainerMenu (ui-mobile, T11) — ajouts
signal shop_mode_changed(mode: StringName)                     ## onglet touché
signal shop_buy_requested(item_id: StringName, quantity: int)  ## CONFIRMER en ACHETER : un seul par toucher
signal shop_sell_requested(item_id: StringName, quantity: int, confirmed: bool)
	## CONFIRMER en VENDRE : confirmed = false ; puis true si la carte VENDRE de ChoiceCards est choisie
func show_shop(view: ShopView) -> void                         ## affiche / rafraîchit (garde sélection et quantité si l'objet y est encore)
func show_shop_result(text: String, ok: bool) -> void          ## UseResultBar : « Merci ! » (ok) ou le refus (tremblement)
func show_shop_confirm(view: ChoiceView, item_id: StringName, quantity: int) -> void
	## ChoiceCards ; chosen(true) → shop_sell_requested(item_id, quantity, true) ; chosen(false) → rien
func shop_back() -> bool                                       ## retour Android : ferme la confirmation si elle est ouverte (vrai), sinon faux
func get_shop() -> ShopScreen
```

**Câblage — `MenuDirector` (constructeur-monde, T12)** :

```gdscript
signal shop_shown(view: ShopView)
signal shop_result_shown(text: String, ok: bool)
signal shop_confirm_requested(view: ChoiceView, item_id: StringName, quantity: int)
func open(route: MenuRoute = null, standalone: bool = false) -> bool   ## passe standalone au navigateur ;
	## écran seul : pas de dashboard_shown
func set_shops(shops: ShopLibrary) -> void        ## comme set_settings : sans elles, SHOP = écran provisoire
func set_shop_mode(mode: StringName) -> void      ## réémet shop_shown
func buy(item_id: StringName, quantity: int) -> ShopRules.Status
func sell(item_id: StringName, quantity: int, confirmed: bool = false) -> ShopRules.Status
```

Règle du directeur : OK → `mark_changed()` (autosave à la fermeture), `shop_shown` (argent et DANS LE SAC à jour) puis `shop_result_shown(status_text, true)` ; NEEDS_CONFIRM → `shop_confirm_requested(ShopViews.sell_confirm_view(entry, quantity), …)` ; autre refus → `shop_result_shown(status_text, false)`, rien d'autre (un texte vide n'affiche rien). Route SHOP dans `_on_route_shown` : `params.shop`, `params.mode`. **`open_shop`** (action de dialogue, `ServiceDirector`) ouvre `MenuRoute.shop(<identifiant de la carte courante>)` en écran seul : **la boutique porte l'identifiant de sa carte** (`viridian_mart`). `Boot` (T12) : `ShopLibrary.load_dir()` + `check_references(_items)`, `_menu.set_shops(...)`, branchement derrière `has_signal(&"shop_buy_requested")`, `shop_back()` en tête de `_screen_back()`. `DebugStart` gagne `money` (départ `shop_qa`).

**Partage des fichiers** :

| Qui | Fichiers |
|---|---|
| **T11 (ui-mobile)** | `game/ui/shop/**` (écran, sélecteur de quantité), `game/ui/menu/trainer_menu.gd` / `.tscn` (hôte, signaux et méthodes ci-dessus), `game/ui/menu/trainer/trainer_screen.gd` (ligne « Argent », `TrainerView.money_text` / `MONEY_LABEL`), `game/ui/bag/bag_screen.gd` (`BagView.money_text`), `game/ui/theme/ui_tokens.gd` + `tools/build_ui_theme.gd` (`SHOP_*`), `tests/integration/test_shop_screen.gd` (vues fabriquées à la main), scénarios de capture `shop_*`, `trainer_money` |
| **T12 (constructeur-monde)** | `game/systems/menu/menu_director.gd`, `game/boot.gd` / `boot.tscn`, `game/systems/services/service_director.gd` (`open_shop`), `game/systems/debug/debug_start.gd` (`money`), carte `viridian_mart` et son outil, `data/npcs/viridian_mart.json`, `data/dialogues/viridian_mart.json`, `data/cutscenes/viridian_mart.json`, `tools/debug_start/shop_qa.json`, `tests/unit/test_menu_director_shop.gd` (directeur seul, signaux), `tests/integration/test_mart.gd`, `test_menu_unlock_rule.gd` |
| **Personne sans l'architecte** | `game/systems/shop/**`, `data/shops/**`, `data/items/items.json`, `game/items/**`, `menu_route.gd`, `menu_navigator.gd`, `menu_format.gd` (ajouts de champs de vue seulement, notés ici) |

**Ordre de fusion** : T11 (écran) d'abord, puis T12 (câblage, `test_mart` sur le vrai `Boot`) ; T12 développe contre ses tests du directeur sans attendre l'écran. Le retrait de `got_oak_parcel` de `_PENDING_FLAGS` (`test_objective_library`) se fait au T12, celui de `viridian_arrived` au T4 ; celui de `pokedex_activated` est fait au T18 (la scène du colis est en données, §3.6.1).

## 7. Performance sur le S24

**Mesuré au prototype** (S24, build debug) : place seule 59 fps, **18 Mo** de textures ; place + personnages en mouvement 58–59 fps, **22,6 Mo** ; visite complète (Jadielle 40 × 28, intérieurs, Route 22) validée par Kevin au doigt, sans mesure consignée ; Mac 100–145 fps. Le J6 a mesuré 58,5 fps de moyenne en exploration avec un creux d'une image toutes les ~4 s (non résolu, « à reprendre en optimisation »).

**Budgets du J7** (à tenir à chaque QA, mesurés, pas estimés) :

| Mesure | Cible | Comment |
|---|---|---|
| Images par seconde, exploration (Jadielle, Route 22, intérieurs) | moyenne ≥ 58, aucun creux < 30 hors chargement | `[perf]` de `PerfCounter` |
| Mémoire des textures par carte | ≤ **64 Mo** (bien sous le seuil de départ de 300 Mo du cahier §2) | `[perf]` étendu au T3 : `Performance.RENDER_TEXTURE_MEM_USED` |
| Changement de carte | ≤ ce qu'on mesure aujourd'hui Route 1 ↔ Bourg Palette (journal `SceneRouter : … en N ms`) | préchargement des voisines (existant) |
| Menu ouvert sur Jadielle | même tenue qu'au J6 | le flou lit l'écran déjà étalonné : rien de plus |

**Leviers posés d'emblée** : ombres pré-floutées (de ~85 lectures de texture par pixel d'objet à 2) ; textures en **compression VRAM** (ETC2/ASTC, déjà activée dans `project.godot`), sauf si la QA voit des artefacts sur les dégradés peints (alors « sans perte » pour les seuls bâtiments) — **comparaison A/B au T3**, captures à 2340 × 1080 ; pas de mipmaps pour les objets affichés à 1:1, mipmaps pour les textures répétées du sol ; un seul `ShaderMaterial` partagé par famille (lots de dessin) ; PNJ : `set_process(false)` hors routine ; pas de `PointLight2D` au J7. **« Économie »** (6F : déjà **30 images/s**, flou du menu coupé, `GraphicsProfile.reduced_effects`) coupe en plus le vent et le liseré, garde l'étalonnage (une lecture par pixel) et les ombres. Les budgets ci-dessus se mesurent en **Auto** (Élevée sur le S24).

---

## 8. Découpage des tâches (dans l'ordre)

Chaque tâche finit par `tools/test.sh` vert (nombre de tests rapporté), un import sans `ERROR` ni `SCRIPT ERROR`, et, si elle est visible, des **captures relues** (Movie Maker, 2340 × 1080 et 1920 × 1080). La capture S24 vient à la validation du sous-jalon (règle 2). `docs/tech/etat-projet.md` est mis à jour dans le même commit (règle 5). Durées, tailles et couleurs par `UiTokens` (nouvelles constantes `SHOP_*`, `STORAGE_*`, `CENTER_*`, `LAYER_WORLD_GRADE`) ; variations de thème par `tools/build_ui_theme.gd`.

### 7A.0 — Sauvegarde v3

#### T0 — architecte-godot : alignement et sauvegarde v3 — **fait**
- Plan aligné sur `8716088` (§0) ; §3.1, §5.1 ; fixture v2 réelle (celle du T1 du J6, §0 point 10).
- **CA** : tests du §5.1 verts ; `etat-projet.md` à jour ; aucune interface.

#### T1 — qa-mobile : la migration sur le S24 (validée seule)
- Protocole du §5.1.1 (APK du J6 depuis `2f7da20`). **CA à rapporter** : chaque étape conforme ; `save.json` en version 3, 3 000 ₽, première espèce retrouvée et confirmée par Kevin ; tout le reste identique (`diff` vide) ; l'APK du J6 ne l'écrase pas (identique octet pour octet) ; journal sans erreur ; validation de Kevin. Si la partie de fin de J6 diffère de la fixture : fixture remplacée et tests verts **avant** l'installation.

### 7A.1 — Jadielle

#### T2 — architecte-godot : fondations du monde peint
- §3.2 ; `data/world/lighting.json` (valeurs C2 du prototype) ; `CharacterLook` ; extensions de `NpcSpec` ; étape `scare` ; `DebugStart` (`money`, `storage`) ; départ `viridian`.
- **CA** : tests du §3.2 verts ; aucune carte, aucune image.
- **Fait (2026-10-05)** : voir §15.2 (écarts avec ce plan, contrats pour T3 / T4). `DebugStart` `money` / `storage` reportés après le T0.

#### T3 — constructeur-monde : le pipeline de l'art et la lumière C2
- `tools/art/manifeste.json` + `tools/art/preparer.py` (successeur de `preparer_proto.py` : sorties dans `assets/`, ombres et contacts pré-floutés, moitié basse des herbes hautes) ; import des textures des séries 01 à 05 (depuis `proto/da-jadielle:proto/da_jadielle/tex/`, renommées) ; `tools/build_painted_props.gd` (scènes `WorldProp` peintes, emprises du §6.6) ; `tools/build_character_frames.gd` (PNJ du J7) ; `WorldLighting` et les 5 shaders ; `CharacterLook` branché dans `Npc` et `Player` ; `PerfCounter` + mémoire des textures ; une **scène de test** (`tools/capture_lighting.gd`) qui pose la place de la série 01 avec la vraie chaîne.
- **Peut commencer pendant T0 / T1** (aucun fichier partagé avec la sauvegarde).
- **CA** : `test_painted_props`, `test_world_lighting` (profil appliqué, profil vide = calque caché, ombres orientées), `test_character_look` (un PNJ peint à l'échelle 1 en LINEAR, un provisoire ×2 en NEAREST) ; captures côte à côte **prototype C2 / production** de la place (écart visuel nul attendu, sinon expliqué) ; comparaison VRAM compressée / sans perte ; mesure Mac.

#### T4 — constructeur-monde : la carte de Jadielle
- `tools/build_viridian_city.gd` → `viridian_city.tscn` (plan du prototype 40 × 28 comme base, Q-5 ; `light_profile = golden_hour`) : place, Centre, Boutique, Arène fermée (porte : « La porte est verrouillée. »), maisons, haies, clôtures, sortie nord `coming_soon = "Route 2"`, départ de la Route 22 à l'ouest (bord bloqué jusqu'au 7B.1), arrivée progressive depuis la Route 1 au sud ; `route_1` : les destinations « Jadielle » deviennent de vrais passages (`tools/build_route_1.gd` régénéré) ; habitants et répliques du §19 (livreur qui entre à la Boutique, Dresseuse + Roucool animé, enfant + Rattata qui le suit, voyageur du nord, habitant de l'Arène, vieil homme et sa seconde réplique) ; Roucool sur le toit ; micro-scène d'arrivée (`data/cutscenes/viridian_city.json`, déclencheur 2 cases après l'entrée, `unless: viridian_arrived`, pose `viridian_arrived`) ; zones et services.
- **CA** : `test_viridian_city` (warps vers des cartes et spawns existants dans les deux sens, aucun PNJ sur une case solide, toutes les routines possibles, chemin entre les trois entrées, la porte de l'Arène répond) ; `test_arrival_scene` (vrai `Boot`, départ `viridian` : la scène se joue une seule fois, **≤ 4 s** de bout en bout, aucun dialogue, contrôles rendus, Roucool absent jusqu'au changement de carte, « rejoindre Jadielle » disparaît) ; `test_menu_map` étendu (Jadielle découverte, Arène dans ses services) ; captures `viridian_arrival`, `viridian_square`, `viridian_gym`, `viridian_north_exit`, lues avec Read.
- **Fait (2026-10-05)** : voir §15.4 (place centrale au sud, intérieurs vides provisoires, Route 22 référencée sans stub).

#### T5 — qa-mobile : validation du 7A.1
- **CA** : arrivée depuis la Route 1 sur la **vraie partie** (micro-scène une fois, titre, contrôle rendu) ; tour complet de la ville sans traverser d'objet ni rester bloqué ; habitants vivants ; Arène ; « ROUTE 2 — À venir » ; menu ouvert sur Jadielle (Carte : Jadielle et l'Arène) ; **fps et mémoire** (§7) sur 10 minutes ; journal propre. Capture S24 à côté de la capture du prototype.

### 7A.2 — Centre Pokémon

#### T6 — architecte-godot : fondations du Centre — **fait** (§3.3.1, §3.3.2, §6.5)
- §3.3 ; contrat du §6.5 ; `data/world/rest_points.json` ; contrat de `ServiceDirector` et `DefeatRecovery` (§6.2).
- **CA** : tests du §3.3 verts.

#### T7 — ui-mobile : le choix dans la boîte de dialogue
- `DialogueBox.show_choice` / `hide_choice` / `choice_made` avec `ChoiceCards` ; retour Android = annuler ; toast du point de repos (toast existant).
- **CA** : `test_dialogue_box` étendu (un `choice_made` par toucher, cartes dans `SAFE_MARGIN` à 1920 et 2340, texte grand et contraste du 6F) ; captures `nurse_choice`.

#### T8 — constructeur-monde : le Centre jouable
- Carte `viridian_center` (`tools/build_interiors.gd` étendu, `interior_warm`), infirmière, Dresseurs au repos (décor, sans espèce nouvelle), machine et rituel ; `ServiceDirector` (`heal`, `center_heal`) ; `DefeatRecovery` (remplace `_handle_defeat`, `mom_wakeup` / `nurse_wakeup` par la donnée) ; terminal posé, **inerte** jusqu'au T16 ; câblage `Boot`.
- **CA** : `test_center_heal` (vrai `Boot`, départ `center_qa` : SOIGNER → équipe pleine, ~3 s, réplique de fin, toast une fois, sauvegarde écrite avec le Centre comme point de repos ; PAS MAINTENANT → rien ne change ; Maman soigne sans changer le point de repos) ; `test_encounter_director` adapté (défaite → Centre si enregistré, sinon maison) ; `test_mom_heal` inchangé et vert.

#### T9 — qa-mobile : validation du 7A.2
- **CA** : choix au doigt, rituel lisible, toast, perte volontaire sur la Route 1 → réveil au Centre ; avant tout Centre, réveil chez Maman (départ de débogage) ; journal propre.

### 7A.3 — Boutique et économie

#### T10 — architecte-godot : fondations de la Boutique — **fait**
- §3.4 ; contrat de `ShopScreen` (§6.10) ; objectif du colis.
- **CA** : tests du §3.4 verts.

#### T11 — ui-mobile : l'écran Boutique et l'argent affiché
- `ShopScreen` (§6.4, langage du Sac) ; argent dans l'écran Dresseur et le Sac (`money_text`) ; confirmation de vente d'un favori par `ChoiceCards` ; scénarios `shop_buy`, `shop_sell`, `shop_no_money`, `trainer_money`.
- **CA** : `test_shop_screen` (onglets, quantité bornée par `max_quantity`, total à chaque cran, CONFIRMER → **un** signal, refus visibles, retour ; **glisser la liste n'achète rien** : `TapGuard`, `touch_finger.gd`) ; `UiPrefsApplier` appliqué ; captures relues.

#### T12 — constructeur-monde : la Boutique jouable
- Carte `viridian_mart` (paillasson bleu, rayons sans étiquette), marchand, scène de première visite (§6.4), `open_shop`, routes `SHOP` dans `MenuDirector`, `mark_changed` et autosave.
- **CA** : `test_mart` (vrai `Boot`, départ `shop_qa` : première visite → colis, toast, objectif ; visites suivantes → Boutique ; achat → argent et Sac ; argent insuffisant ; vente d'une Potion favorite après confirmation ; colis absent de VENDRE ; sauvegarde relue) ; `test_menu_unlock_rule` étendu.
- **Fait (2026-10-05)** : voir §15.12 (première visite : le marchand interpelle à l'entrée puis le joueur va à la caisse ; la Boutique s'ouvre à la **fin** du dialogue ; livreur dans la Boutique ; clé `favorites` de `DebugStart`).

#### T13 — qa-mobile : validation du 7A.3
- **CA** : achat de Poké Balls et de Potions au doigt, vente, refus, objectif dans le menu, argent dans l'écran Dresseur et le Sac (et nulle part ailleurs).

### 7A.4 — Stockage Pokémon

#### T14 — architecte-godot : fondations du Stockage
- §3.5 ; contrat de `StorageScreen` et du bouton STOCKAGE de l'Équipe.
- **CA** : tests du §3.5 verts.

#### T15 — ui-mobile : l'écran Stockage
- §6.4 ; scénarios `storage`, `storage_drag`, `storage_release`, `storage_refusal`.
- **CA** : `test_storage_screen` (glisser = un signal, sélection + bouton = le même, refus = tremblement + raison, `view.result_text` affiché sur la ligne de résultat et effacé par une vue sans texte, LIBÉRER seulement dans le menu secondaire, confirmation, favori sans contournement ; défiler la grille ne sélectionne rien : `TapGuard`) ; `UiPrefsApplier` appliqué ; captures relues.

#### T16 — constructeur-monde : le Stockage jouable — **fait** (§15.14)
- Terminal (`open_storage`), bouton STOCKAGE de l'Équipe (au Centre seulement), câblage, autosave.
- **CA** : `test_menu_storage` (vrai `Boot`, départ `storage_qa` : déposer, reprendre, libérer avec confirmation puis « {Pokémon} a été libéré. » dans la vue, dernier Pokémon refusé avec ses deux raisons (équipe vide, tous K.O.), favori protégé, rien hors du Centre, sauvegarde relue, le combat suivant envoie le bon premier).

#### T17 — qa-mobile : validation du 7A.4
- **CA** : glisser au pouce (une dizaine d'essais), alternative par boutons, refus lisibles, libération confirmée, sauvegarde après relance.

### 7A.5 — Le Pokédex de Chen

#### T18 — architecte-godot : fondations de la scène de Chen — **fait** (§3.6.1, contrat du T19 au §3.6.2)
- §3.6.
- **CA** : tests du §3.6 verts.

#### T19 — constructeur-monde : la remise du colis et l'activation — **fait** (§15.19)
- Contrat et partage : §3.6.2 (données de la scène, textes et étapes déjà livrés au T18 ; reste le câblage, le départ `parcel`, les tests de bout en bout et les réglages de mise en scène).
- `oak_lab` : parler à Chen avec le colis → scène (`cutscene`) : répliques du §19 dans leur ordre, page de l'espèce omise sans rencontre, `take oak_parcel`, `set pokedex_activated`, `caption` POKÉDEX ACTIVÉ, « Observe. Explore. Fais-toi ta propre idée du monde. », le rival entre (sprite peint, Q-1), répliques, il repart ; objectif effacé.
- **CA** : `test_parcel_scene` (vrai `Boot`, départ `parcel` puis la **vraie partie migrée** de Kevin : réplique avec son espèce ; partie sans rencontre : réplique omise ; 6 cartes après, données d'avant visibles, drapeau sauvegardé, colis retiré, aucun toast de rattrapage) ; captures `oak_parcel`, `pokedex_activated`.

#### T20 — qa-mobile : validation du 7A.5 et QA « joueur » du J7A
- **CA** : sur la vraie partie, **sans drapeau de débogage** : Route 1 → Jadielle → Centre → Boutique (colis) → Stockage → retour par les rebords → Chen → Pokédex plein de ce qu'il a vu ; 60 fps, journal propre, sauvegarde et reprise. **Validation du J7A.**

### 7B.1 — Route 22

#### T21 — architecte-godot : données de la Route 22
- §3.7 ; sprites de combat selon Q-2.
- **CA** : tests du §3.7 verts ; simulation de rythme rapportée.

#### T22 — constructeur-monde : la carte de la Route 22
- `tools/build_route_22.gd` (plan du prototype 46 × 20 comme base) : chemin vers l'ouest, falaise et escalier (couche du sol), trois champs d'herbes peintes avec clairières, rochers, forêt, fond peint du Plateau Indigo fondu sous la lisière, **aucun passage** vers l'ouest ; Pokémon d'ambiance peints sur les bords ; voyageur (réplique seulement si on lui parle) ; raccord avec Jadielle.
- **CA** : `test_route_22` (comme `test_viridian_city` ; escalier = seul passage ; bord ouest bloqué) ; rencontres dans les herbes (`test_encounter_director` étendu) ; capture et Pokédex des nouvelles espèces ; captures relues.

#### T23 — qa-mobile : validation du 7B.1
- **CA** : exploration, rythme des rencontres, capture d'une nouvelle espèce, Pokédex mis à jour, fps et mémoire.

### 7B.2 — Rival n° 2

#### T24 — architecte-godot : IA de niveau 2 et gains
- §3.8 (moteur : **aucune autre tâche de combat en parallèle**).
- **CA** : tests du §3.8 verts ; tests et simulations du J4/J5 inchangés ; taux de victoire simulé rapporté.

#### T25 — constructeur-monde : la scène du rival — **fait** (écarts au §15.9)
- Déclencheur à l'approche du point de vue (`if: pokedex_activated`, `unless: rival_route22_won / _lost`) : le rival et le jeune Dresseur face à face, le Pokémon du jeune Dresseur rappelé (Q-13), « Sérieusement… ? » / « Tu hésites trop. », le rival remarque le joueur, répliques du §19, combat (`win_flags` / `lose_flags`) ; victoire : répliques, argent, il part ; défaite : répliques, `wake_up` (on ne le voit pas partir). Le jeune Dresseur repart vers Jadielle.
- **CA** : `test_rival_route22` (vrai `Boot` : rien sans le drapeau ; victoire → `rival_route22_won`, argent, moment « Combat contre le rival » ; défaite (départ `rival_2_weak`) → `rival_route22_lost`, réveil au Centre ou chez Maman, aucun argent perdu ; SAC utilisable ; la scène ne se rejoue plus).

#### T26 — qa-mobile : validation du 7B.2 et QA finale du J7
- **CA** : le combat est plus exigeant que celui du labo sans être injuste (avis de Kevin, taux simulé à l'appui) ; victoire et défaite jouées une fois chacune ; puis **parcours complet** du J7 sur la vraie partie, 60 fps partout, journal propre, aucun élément du Pokédex avant Chen. **Validation du jalon 7.**

---

## 9. Parallélisme (deux agents au plus, chacun dans sa copie)

**Peut avancer en parallèle** :
- l'architecte prépare les fondations pures du sous-jalon suivant (T6, T10, T14, T18, T21, T24) pendant la QA du précédent ;
- **T3** (pipeline de l'art) pendant **T0 / T1** : ni la sauvegarde ni `Boot` n'y sont touchés ;
- **T7 ∥ T8**, **T11 ∥ T12**, **T15 ∥ T16** : écran avec des vues fabriquées d'un côté, câblage avec un écran factice de l'autre ; écran fusionné d'abord (§6.8).

**Ne peut pas avancer en parallèle** :
- deux tâches qui touchent `boot.gd` / `boot.tscn`, `game_state.gd`, le format de sauvegarde, `battle_director.gd` / `battle.gd`, `project.godot` (globaux de shaders), `ui_tokens.gd` + `build_ui_theme.gd`, `dialogue_runner.gd` ;
- **T0 et une tâche de jeu** : la sauvegarde v3 est seule jusqu'à sa validation (T1) ;
- **T3 et T4** (même pipeline, mêmes scènes de props) ;
- **T24** et toute autre tâche de combat.

---

## 10. Critères d'acceptation par sous-jalon (récapitulatif)

| | 7A.0 | 7A.1 | 7A.2 | 7A.3 | 7A.4 | 7A.5 | 7B.1 | 7B.2 |
|---|---|---|---|---|---|---|---|---|
| Tests | §5.1 | §3.2, T3–T4 | §3.3, T7–T8 | §3.4, T11–T12 | §3.5, T15–T16 | §3.6, T19 | §3.7, T22 | §3.8, T25 |
| Toujours | `tools/test.sh` vert, import propre, nombre de tests rapporté, `etat-projet.md` à jour | | | | | | | |
| Déblocage | — | Carte : services découverts seulement | — | argent : Boutique, Sac, Dresseur | Stockage au Centre seulement | rien du Pokédex avant la scène | — | rien sans le Pokédex |
| Sauvegarde | v3 validée seule | — | point de repos | argent, colis | stockage, favoris | drapeau, colis retiré | captures | drapeaux du rival, argent |
| Performance | — | **fps + mémoire** | — | — | — | — | **fps + mémoire** | — |
| S24 | T1 | T5 | T9 | T13 | T17 | T20 | T23 | T26 |
| Export | — | `data/world` | — | `data/shops` | — | — | — | — |

---

## 11. Écarts entre le dossier 09 et le code réel, risques

**Écarts et contradictions relevés** :
1. **« Arène vue = drapeau »** (dossier 09 §17) : le format des services du T18 la déduit de la carte `found_on` (Jadielle). Le plan garde la déduction (une source par fait) ; aucun drapeau.
2. **« Première espèce sauvage »** : aucun fait ne la distingue aujourd'hui d'une observation (OBSERVER, Pokémon du rival), et l'herbe de Bourg Palette est une zone de rencontres comme la Route 1 (§0 point 9). D'où `first_wild_encounter` (v3) et son rattrapage (§5.1, avec ses limites).
3. **Défaite contre un Dresseur** : jamais codée (le seul dresseur, `rival_lab`, ne fait pas perdre). `BattleConclusion.blackout` existe, rien ne l'applique : `DefeatRecovery` + étape `wake_up`.
4. **SAC contre les Dresseurs** : la grille le tait contre tous (`TRAINER_BATTLE_ACTIONS`) ; la décision du 2026-10-03 passe en donnée (`allow_bag`).
5. **Mot de réveil** codé en dur (`mom_wakeup`) dans `EncounterDirector` : passe en donnée (`rest_points.json`).
6. **Dialogues** : ni choix, ni jetons, ni action autre que `heal`, ni lancement de scène : quatre petites généralisations (§2.3), rétrocompatibles.
7. **`Npc` et `Player`** supposent des sprites pixel ×2 NEAREST (scène et `_base_scale`) : `CharacterLook`.
8. **Tuiles** : le skill `world-tiles` décrit un sol en `TileMapLayer` visibles avec terrains ; le prototype a montré que les transitions peintes par tuiles échouent (fiches, « changement de technique ») : sol par masque + décalcomanies, `Ground` gardé comme source logique invisible. **Mettre à jour le skill au T3.**
9. **Capacités des nouvelles espèces** : poison, coups multiples, peur, critiques élevés n'existent pas dans le moteur ; elles frappent une fois sans effet (`pending_effects`), comme Poudre Toxik — un Nidoran apprend Dard-Venin au niveau 14 sans empoisonner.
10. **Moments** : le dossier 08 ne prévoit pas de moment « Pokédex » (Q-11).

| Risque | Effet | Parade |
|---|---|---|
| **Sauvegarde v3** | perte de l'argent ou de la partie, ancien APK qui écrase | une migration, fixture réelle, QA S24 seule (T1) |
| **Passage de l'art en production** | écart avec ce que Kevin a validé sur le prototype | captures côte à côte prototype / production au T3, même scène |
| **Performance** (plus d'objets, ombres, étalonnage, PNJ peints) | sous 60 fps, mémoire | ombres pré-floutées, compression VRAM, mesures `[perf]` à chaque QA (§7) |
| **Sources d'art hors dépôt** (`build/art/`, Mac de Kevin seulement) | une perte du Mac = plus de régénération possible | les textures **préparées** sont versionnées (le jeu n'a besoin que d'elles) ; Kevin sauvegarde `build/art/` hors du dépôt (défaut) |
| **Rupture de style** Route 1 provisoire → Jadielle peinte ; héros provisoire parmi des PNJ peints | impression d'inachevé | décisions de Kevin (Q-1 à Q-3) ; aucune retouche avant |
| **Dialogue qui attend une action** (rituel) | verrou du joueur qui ne se lève pas, coroutine coupée | une seule coroutine d'action à la fois, tests de bout en bout (T8), même discipline que les scènes |
| **Dernier Pokémon K.O.** | équipe sans Pokémon valide après un dépôt → combat refusé | règle Q-7 dans `StorageRules`, testée |
| **Moteur de combat** (IA, gains, SAC par dresseur) | régression des combats validés | `random` inchangée, simulations du J4/J5 relancées, T24 seul |
| **10 espèces de données** | erreurs de statistiques ou d'apprentissages | source unique citée, validation stricte de `PokemonData`, revue de Kevin inutile (données factuelles) |
| **Textes hors §19** | attente de Kevin | `draft`, un seul lot (§12) |
| **Agents en parallèle** sur `boot.gd` | conflits | §9 |

---

## 12. Questions pour Kevin (valeur par défaut appliquée si tu ne dis rien)

> **Validées par Kevin (2026-10-04)** : Q-1 → (b) ; **Q-2 à Q-14 → valeurs par défaut retenues**. Seules les tenues des habitants (Q-4) restent à confirmer sur S24 au 7A.1.

Seules les vraies questions de game design et de direction artistique sont ici ; les petites ont leur valeur au §13.

**Personnages et style**
- **Q-1 — Le héros et le rival au J7.** Tu as décidé que les personnages déjà en jeu (joueur, rival, Maman, Chen) ne sont remplacés qu'à la phase DA. Mais au J7, le héros provisoire (pixel ×2) marchera parmi des habitants **peints** à 128 px dans une Jadielle peinte et éclairée, et le rival apparaît deux fois (labo, Route 22) alors que sa planche peinte existe déjà (série 02) et que le storyboard de la Route 22 le montre peint. Trois options : **(a)** garder ta décision (héros et rival provisoires partout ; la planche du rival attend) ; **(b)** avancer le héros et le rival peints dès le J7 (planches de marche et de course du héros déjà validées en test ; il manque le **dos du lancer de Ball** de la capture, le portrait du menu et les sauts ; Maman et Chen restent provisoires) ; **(c)** peints seulement dans les cartes du J7 (déconseillé : un même personnage aurait deux apparences). *Défaut : (a), sans trancher à ta place ; (b) coûte une tâche de plus au 7A.1.* **Tranché par Kevin (2026-10-04) : (b).** Héros et rival peints dès le J7, dans tout le jeu (une seule apparence par personnage) : planches de marche et de course du héros déjà validées, planche du rival (série 02) ; pose de lancer droitière et portrait du menu **déjà produits** (série 06, `build/art/VALIDE_HEROS_LANCER.png`, `HEROS_PORTRAIT_NE_r1.png` ; une seule pose de lancer, la Ball part de la main droite) ; les sauts de rebord n'ont besoin d'aucun asset (arc dessiné par `Player`) ; Maman et Chen restent provisoires jusqu'à la phase DA.
- **Q-2 — Les Pokémon peints et provisoires.** Roucool et Rattata existent en peint (Jadielle) et en provisoire (Bourg Palette, Route 1, combat). Pour les **4 nouvelles espèces** de la Route 22 en **combat** : *défaut : sprites de combat provisoires générés comme les 5 actuels (cohérence à l'intérieur du combat), peints dans le monde (assets déjà produits) ; le peint en combat pour tous à la phase DA.*
- **Q-3 — Rupture de style entre la Route 1 et Jadielle.** *Défaut : acceptée jusqu'à la phase DA ; Bourg Palette, la Route 1 et les intérieurs existants ne reçoivent ni l'art peint ni la lumière C2 au J7.*
- **Q-4 — Tenues des PNJ du J7** (infirmière, marchand, livreur, Dresseuse, vieil homme, voyageur, jeune Dresseur ; séries 02 et 05) : *défaut : celles du prototype, à valider sur le S24 au T5.*

**Jadielle**
- **Q-5 — Le plan de Jadielle.** *Défaut : le plan du prototype (40 × 28) que tu as parcouru, ajusté au jeu (entrées, routines, place des habitants) ; tu le valides au T5.*
- **Q-6 — Pokémon des habitants observables** (Roucool de la Dresseuse, Rattata de l'enfant) : OBSERVER demande une phrase de narration non écrite. *Défaut : non au J7 (comme les Pokémon des prés au 6C).*

**Centre, Stockage, argent**
- **Q-7 — « Dernier Pokémon »** : le dossier dit « le dernier Pokémon de l'équipe ». Si l'équipe compte un Pokémon valide et un K.O., déposer le valide laisserait une équipe incapable de combattre. *Défaut : on compte les Pokémon **en état de combattre** ; même message « Tu dois garder au moins un Pokémon avec toi. ».* **Précisé par Kevin (2026-10-05)** : règle stricte validée ; le refus **explique la raison** : équipe vide → « Tu dois garder au moins un Pokémon avec toi. » (validé) ; il resterait des Pokémon, tous K.O. → « Tu dois garder au moins un Pokémon en état de combattre. » (`draft`). Après une libération : « {Pokémon} a été libéré. » (`draft`).
- **Q-8 — L'argent avant la première Boutique.** *Défaut : visible dès le début dans l'écran Dresseur et le Sac (3 000 ₽ existent depuis le départ, aucun événement ne les « donne »).*
- **Q-9 — Ce que dit l'infirmière au réveil après une défaite.** *Défaut : la réplique validée « Voilà. Tout le monde est en pleine forme. » (aucun texte nouveau).*

**Chen et le Pokédex**
- **Q-10 — L'objectif après l'activation.** *Défaut : aucune ligne jusqu'au J8 (le monde s'ouvre, pas de checklist).*
- **Objectifs, ponctuation (Kevin, 2026-10-05)** : convention homogène, **tout texte d'objectif finit par un point** ; « remettre le colis au Professeur Chen. » garde le sien, « rejoindre Jadielle » devient « rejoindre Jadielle. ». Imposé par `test_objective_library` (`test_every_objective_text_ends_with_a_period`) pour toute entrée de `data/story/objectives.json`.
- **Scène de Chen (Kevin, 2026-10-05)** : le rival entre **après** « Observe. Explore. Fais-toi ta propre idée du monde. » (validé) ; Chen lui remet son Pokédex **sans réplique** (validé pour l'instant ; à juger en QA : silence intentionnel ou vide).
- **Q-11 — Un grand moment « Pokédex » dans l'écran Dresseur ?** *Défaut : non (la liste du dossier 08 reste telle quelle).*
- **Q-12 — « Efficace / Peu efficace » en combat après l'activation** (dossier 05 §5) : *défaut : pas au J7 (J11, avec la lecture des types).*

**Route 22 et rival**
- **Q-13 — La mise en scène du rival contre le jeune Dresseur.** *Défaut : le starter du rival (sprite provisoire actuel, Q-1) face au Rattata du jeune Dresseur ; le Rattata est rappelé (fondu) ; après la scène, le jeune Dresseur repart vers Jadielle, sans réplique de plus.*
- **Q-14 — Difficulté du rival n° 2.** *Défaut : l'équipe du dossier (Roucool Nv. 7, starter avantagé Nv. 8) et l'IA de niveau 2 ; on ajuste après la simulation du T24 et ton essai au T26.*

**Textes à relire** (un seul lot, tous `draft`) : message de gain « Tu remportes {money}. » ; description du colis ; descriptions de zone de Jadielle et de la Route 22 ; « Ton équipe est déjà complète. » (REPRENDRE, équipe pleine) ; « Le stockage est vide. » ; « Tu dois garder au moins un Pokémon en état de combattre. » et « {Pokémon} a été libéré. » (Stockage, 2026-10-05) ; « Vendre {objet} ? » (favori) ; les 4 descriptions du Pokédex (Piafabec, Férosinge, Nidoran ♀, Nidoran ♂) ; libellé « Argent ». Le panneau de Jadielle n'est pas examinable au J7 (aucun texte validé).

---

## 13. Valeurs par défaut (petites questions, règle 4)

| Sujet | Valeur |
|---|---|
| Rituel du Centre | 3,0 s ; ×0,5 avec « Réduire les animations » ; vibration 20 ms à l'éclat |
| Toast du point de repos | à chaque **changement** de point de repos (la première fois à Jadielle) |
| Lancement de la scène de Chen | en **parlant** à Chen avec le colis (`cutscene` d'une variante) |
| Première visite de la Boutique | déclenchée en **entrant** (le marchand salue le nouveau venu) ; la Boutique ne s'ouvre pas d'elle-même ensuite |
| Prix de vente | moitié du prix, arrondie en dessous (Rouge/Bleu) |
| Quantité à l'achat | 1 à 99, bornée par l'argent ; appui long sur + / − qui accélère |
| Plafond d'argent | 999 999 ₽ |
| Argent du rival n° 2 | 35 × niveau du dernier Pokémon (280 ₽ au Nv. 8) |
| Taille des intérieurs | Centre et Boutique 15 × 10 (enveloppes de la série 03), bandes de fond comme la maison et le labo |
| Sous-titre de zone | aucun pour Jadielle (décision du 2026-10-03) ni pour la Route 22 |
| Route 1 → Jadielle | passages réels au bord nord de la Route 1 ; Jadielle → Route 1 au bord sud |
| Ordre des cartes de la Boutique | ordre des données (Poké Ball, Potion) |
| Stockage | ordre d'arrivée ; sélection gardée pendant la visite ; un Pokémon déposé arrive à la fin |
| Micro-scène d'arrivée | déclencheur 2 cases après l'entrée sud ; ≤ 4 s mesurées par test |
| Livreur | entre à la Boutique une fois par tour de sa boucle, 8 s à l'intérieur |
| Animation du Roucool de la Dresseuse | petit bond toutes les 6 s |
| Lumière des cartes du J7 | `golden_hour` dehors, `interior_warm` au Centre et à la Boutique |
| Calque de l'étalonnage | `LAYER_WORLD_GRADE` 6 : les Pokémon du combat sont étalonnés comme le décor |
| Ombre des personnages | ellipse existante, pas d'ombre portée par image |

---

## 14. Validation S24 (résumé)

| Après | Ce que Kevin essaie sur le S24 |
|---|---|
| T1 | Sa vraie partie reprise après la migration v3 ; 3 000 ₽ ; l'APK du J6 n'écrase rien. **Validation de la sauvegarde v3.** |
| T5 | Arriver à Jadielle, la parcourir, ses habitants, l'Arène fermée, la sortie nord ; fps. **Validation du 7A.1.** |
| T9 | Se soigner au Centre, perdre et s'y réveiller. **Validation du 7A.2.** |
| T13 | Le colis, acheter, vendre, l'argent. **Validation du 7A.3.** |
| T17 | Le Stockage. **Validation du 7A.4.** |
| T20 | Chen, le Pokédex activé, puis tout le J7A d'une traite. **Validation du J7A.** |
| T23 | La Route 22 et ses Pokémon. **Validation du 7B.1.** |
| T26 | Le rival n° 2, victoire et défaite, puis tout le J7. **Validation du jalon 7.** |

---

## 15. Alignement du plan sur le code

### 15.20 T5-XL — Jadielle agrandie (constructeur-monde, 2026-10-05, base `j7-centre` à `447bf2b`, branche `j7-jadielle-xl`)

**Écart décidé par Kevin au T5 sur S24** : « Jadielle est trop petite et trop plate » → on agrandit et on suit la **composition de la référence** `jadielle-vue-generale-v1.webp`, **sans eau** (dossier 09 §1, arbitrage 1). La place revient **au centre** : le point 1 du §15.4 (« place au sud ») est abandonné. Aucun fichier de la sauvegarde, du combat, de l'UI ni des intérieurs touché.

1. **Taille : 56 × 40 cases** (cible ≈ 56 × 40 ; ancienne 40 × 28, ×2 en surface). Les bâtiments gardent leur taille ; trois niveaux reliés par des escaliers : **haut** (rangées 1–11 : arche nord et rue de la Route 2 « à venir », Arène au nord-ouest sur sa terrasse avec parvis pavé, deux maisons à jardins, chemins de terre secondaires), mur de soutènement (rangée 12, deux escaliers : Arène, rue nord), **place** (13–23 : placette nord, Centre au nord-ouest de l'arbre, Boutique au nord-est, arbre central et massif entre les deux, rue est-ouest vers la Route 22 — chemin de terre à la place du pont —, deux maisons, parc), mur (rangée 24) et **grand escalier sud**, **bas** (25–33 : arrivée entretenue bordée de haies, lampadaires, panneau, deux maisons à jardins clôturés et potagers), **falaise** (rangée 34) que le chemin de la Route 1 traverse, forêt sauvage (35–39). Bords : forêt dense ; falaise au sud. Plan en caractères : `godot --headless --path . -s res://tools/build_viridian_city.gd -- --dump`.
2. **Relief** : murs de soutènement (`relief_muret_01`) et escaliers de ville (`relief_escalier_ville_01`, marches sur 3 cases + piliers) dans `GroundDecals` comme la falaise et l'escalier de la Route 22 (jamais devant un personnage) ; **sans emprise** : la carte bloque la rangée du mur (`blocked_cells`) et les piliers (colonnes voisines des marches, sur la rangée du mur et ses deux voisines, car l'image déborde d'une demi-case de chaque côté). La falaise du sud réutilise `relief_falaise_01` (emprise = sa rangée) ; pré bloqué sans arbres à son pied pour qu'on la voie.
3. **Art produit (série 07, Codex, lumière neutre, méthode C2)** : `relief_muret_01`, `relief_escalier_ville_01`, `prop_potager_01` (3 × 1), `prop_platebande_01` (3 × 1), `prop_cloture_v_01` et `prop_haie_v_01` (1 × 4, du nord au sud). Prompts et références recadrées de la vue générale dans `build/art/` de la copie de travail (non versionné ; `REF_MURET_ESCALIER`, `REF_ESCALIER_SUD`, `REF_POTAGER`, `REF_JARDIN_EST`), manifeste et `PaintedPropRules` complétés, `tools/art/preparer.py` relancé (seuls les nouveaux fichiers changent). **Manque encore** : portail de jardin, buissons ronds isolés, balustrade de terrasse, bancs et lampadaires en variantes, toits de maisons supplémentaires (trois maisons de chaque modèle) ; la clôture verticale est fine (poteaux, peu de lisses visibles).
4. **Micro-scène d'arrivée** : le déclencheur est le **premier pas sur la place, en haut du grand escalier sud** (27..29, 23), seul passage vers le nord (mur et piliers), au lieu de « deux cases après l'entrée » : avec la composition de la référence (chemin, falaise, quartier bas, escalier), la Boutique et son Roucool ne seraient pas dans le champ deux cases après l'entrée (caméra ≈ 11 cases de haut, 5 rangées visibles au-dessus du joueur) ; en haut de l'escalier, la porte de la Boutique est à 2 rangées (testé). Rattata (24 → 30, 22) suivi de l'enfant, envol du Roucool de l'auvent, le voyageur descend de la placette (26, 21) et passe à côté du joueur vers l'escalier. Mesuré : **2,57 s** (test, temps réel), 2,73 s (capture à 30 i/s).
5. **Aucun habitant figé** (remarque de Kevin au T5) : nouvelle clé de données **`look`** des PNJ (`{ "facings": [...], "every": s }`, `NpcSpec.look_facings` / `look_every`, défaut 3,5 s, bornes 0,5–120 s, au moins deux orientations, **interdite avec `route`**) : le PNJ se tourne tour à tour vers chaque orientation, en `Tween` (pas de `_process`), jamais pendant un pas, un saut, un dialogue (`Npc._interacting`) ou dans un bâtiment. Tests : `test_npc_roster.test_look_around`, `test_npc.test_look_around_…`, `test_viridian_city.test_no_inhabitant_stands_frozen` (chaque habitant a `route` ou `look`). Valeurs par défaut : Dresseuse (3 s, vers son Roucool, la rue, le banc), son Roucool (4,5 s, + petit bond 6 s), garde de l'Arène (3 s, surtout vers la porte), Roucool de l'auvent (2,5 s), acteurs de la micro-scène en attente (enfant 1,6 s, Rattata 1,3 s + bond 2,2 s, voyageur 2,5 s), voyageur du nord après l'arrivée : petite **routine** (trois cases devant l'arche, pause 2 s). Vieil homme : boucle de 6 cases sur la placette.
6. **Positions** (noms de spawns et de warps inchangés) : `from_route_1_w/e` (28/29, 39) et warps sud (27..29, 39) ; portes du Centre (21..22, 21) et de la Boutique (35..36, 21) = `from_center` / `from_mart` ; Route 22 (0, 22..23), `from_route_22` (0, 22) ; « ROUTE 2 — À venir » (27..29, 1), retours `route_2_soon_*` (27..29, 3) ; porte de l'Arène (9..10, 9). Départs de débogage inchangés (spawns par nom). Tests adaptés : `test_viridian_city` (+ `test_terraces_are_crossed_only_by_the_stairs`), `test_arrival_scene`, `test_coming_soon`, `test_mart`, `test_painted_props` ; outils `capture_viridian.gd` (nouvelles vues : `viridian_north_stair`, `viridian_south_quarter`, `viridian_west_exit`, `viridian_gym_stair`) et `capture_map.gd` (`--map=`).
7. **Performance (Mac, 2340 × 1080)** : 145 fps (plafond), **200 appels de dessin** (225 au T4 : moins de forêt au contact des rues), textures du processus 82,2 Mo à Jadielle (UI, combat, intérieurs peints, voisines préchargées) ; textures propres à la carte **16,2 Mo** en RGBA8 (14,9 avant), sous le budget de 64 Mo du §7. Mesure S24 à faire à la validation.
8. **À valider sur S24 (Kevin)** : lisibilité des niveaux (on comprend qu'on monte), longueur de l'arrivée, la micro-scène en haut de l'escalier, les piliers bloquants, les jardins, le chemin vers la Route 22.

**Passe 2 (critique validée par Kevin sur les captures : densité, jardins, arrivée)** — remplace les points 1, 3, 6 et 7 là où ils diffèrent :

9. **Taille finale 56 × 36** (et non 40 rangées) : la lisière sous la falaise passe de 5 à 3 rangées et le niveau bas de 9 à 7 ; falaise en rangée **32**, entrée sud (27..29, **35**), `from_route_1_w/e` (28/29, 35). **Arrivée : 12 pas** de l'entrée au premier pas sur la place (16 avant). Dès l'écran d'entrée on voit les deux maisons du bas, leurs jardins, quatre lampadaires qui jalonnent le chemin, les haies et le bas du grand escalier (capture `viridian_arrival_00_entry`). La lisière près du chemin = broussailles (`SCRUB` : buissons et rochers, jamais d'arbre qui cacherait la ville).
10. **Jardins clos** (`GARDENS` de l'outil) : chaque maison a une clôture sur ses deux côtés et à l'avant, un **portail ouvert** (seul accès, testé), une **boîte aux lettres**, et dans la cour potager, arbre fruitier, pots de fleurs, tonneau, caisses ou étendoir à linge. Clôtures et garde-corps = **bandes peintes recadrées** à la longueur voulue (nœud `WorldProp` + `Sprite2D` à région, sans emprise : les cases sont dans `blocked_cells`, sans ombre portée). **Garde-corps de pierre** sur le bord haut des deux murs (sauf les escaliers), posé sur le couronnement : le joueur du niveau haut passe derrière.
11. **Bosquets** (`GROVE`) entre les quartiers et **plantation automatique** (graine 2026) : un arbre seulement si sa cime (4 rangées, colonnes voisines) ne couvre aucune case praticable ni un mur ou la falaise (la forêt du bord peut couvrir la falaise), sinon un buisson (trois modèles, 25 % sautés, décalage aléatoire : pas de rangées) ; 15 % d'arbres fruitiers dans les bosquets. **Touffes d'herbe** semées sur les pelouses (45 % des cases, graine 11). Plates-bandes et buissons au pied des murs, derrière le Centre et la Boutique.
12. **Modèles de maisons** : 4 (A, B une fois ; C et D deux fois), testé (`test_every_house_has_a_closed_garden_with_a_gate`).
13. **Art (série 07, passe 2, Codex)** : `bldg_maison_c_01` (toit vert mousse, porche), `bldg_maison_d_01` (colombages, toit brun), `prop_portail_01`, `prop_buisson_a/b/c_01`, `prop_balustrade_01`, `tree_fruitier_01`, `prop_tonneau_01`, `prop_caisses_01`, `prop_boite_lettres_01`, `prop_pots_fleurs_01`, `prop_linge_01`, et la clôture verticale refaite (r3 : poteaux massifs, deux traverses visibles). **Versionné** : `tools/art/serie07/` (prompts, références recadrées de la vue générale, `generer_serie07.sh`) ; manifeste et `PaintedPropRules` à jour. **Sources brutes** (non versionnées, comme les séries précédentes) : `build/art/` de la copie `.claude/worktrees/agent-a272d1d6549278150/` (`WORLD_*_NE_r1.png` de la série 07, `WORLD_PROP_CLOTURE_V_01_NE_r3.png`) → **à copier dans `build/art/` du Mac** avant de relancer `tools/art/preparer.py`.
14. **Perf (Mac, 2340 × 1080)** : 145 fps (plafond), **297 appels de dessin** (200 en passe 1), textures du processus 86,5 Mo, textures propres à la carte **19,5 Mo** RGBA8 (budget 64). Micro-scène : **2,59 s** (test). La mesure S24 dira si les ~300 appels de dessin tiennent 58 fps (levier si besoin : atlas des petits objets).
15. **Outil de capture** : `capture_viridian.gd` gagne `viridian_quarter_sw` / `viridian_quarter_ne` et ferme la réplique de l'Arène de façon fiable ; **à lancer sans `--write-movie`** (les images sont lues dans le viewport ; avec Movie Maker, l'outil peut bloquer et l'AVI grossir sans fin).

### 15.21 Retours de Kevin au T5 sur S24 (constructeur-monde, 2026-10-05, base `j7-centre` à `194e9d8`, branche `j7-jadielle-retours`)

Écarts avec le §15.20 (le reste tient) :

1. **Portes des maisons** (« les premières maisons qu'on voit, on ne peut pas accéder à leurs portes » ; « même fermée, la porte doit être accessible et pas bloquée ») : cause — le portail était posé à la main (`GARDENS`, 5e colonne), pas forcément sous la porte peinte (maison est : portail en 46, porte en 47) ; les deux maisons du bas avaient leur façade **sur la rangée de la clôture** (sud-ouest : la case devant la porte était une clôture, porte inaccessible ; sud-est : pots de fleurs sur la case de la boîte aux lettres). Correction dans `tools/build_viridian_city.gd` : `HOUSE_DOOR_DX` (colonne de la porte par modèle, lue sur les images : A −1, B −1, C 0, D +1), **portail = colonne de la porte**, **allée de terre** peinte de la case devant la porte jusqu'au portail (`_paint_cells`), maisons du bas remontées d'une rangée (ancres (20, 28) et (37, 28)), pots et mobilier hors des allées (NE, E, SW, SE). Points d'examen `<Maison>Door` (case de la porte, de face seulement) → dialogue **`viridian_house_door`** « C'est fermé. » (**draft**, défaut en attendant Kevin : des maisons s'ouvriront-elles ?). Test `test_every_house_door_is_reachable_from_the_south_entrance_and_closed` (six portes, chemin depuis l'entrée sud sur la grille réelle avec et sans habitants, allée libre de tout objet, portail à 3 cases au plus, interaction).
2. **Cadence des PNJ** (« comme s'ils courent et marchent en même temps ») : **causes exactes** — (a) `build_character_frames.gd` générait `run_<dir>` pour toutes les planches, **la planche de marche rejouée à 12,5 i/s** quand il n'y a pas de planche de course (tout le monde sauf le héros) ; la micro-scène faisait courir l'enfant et son Rattata (`"run": true`) : poses de marche à la vitesse de course ; (b) `Npc._play_move` relançait l'animation à l'image 0 à **chaque pas** (après chaque pause de routine, et une image de repos entre deux pas de scène) : un pas = images 0-1, toujours le même pied ; (c) le Rattata de l'enfant tournait sur la même boucle avec une pause de 0,5 s contre 0,9 s : il butait contre l'enfant et repartait à contretemps. Corrections : plus de `run_*` sans planche de course (frames régénérés) ; `Npc.can_run()` (vraie course, ou aucune animation de pas) et `step(dir, run)` **marche** sinon ; `Npc._stride` : chaque pas commence sur le demi-cycle suivant (images 0-1 puis 2-3), même après un arrêt ; pause du Rattata = 0,9 s. Règle testée sur **toutes les données** (`test_npc_gait` : routines de `data/npcs/`, acteurs des `move`, PNJ créés par une scène — cadence de marche = 2 pas par cycle, course demandée seulement à une apparence qui court vraiment) ; `test_npc` (+3), `test_character_look` (plus de fausse course), `test_viridian_city.test_the_kid_rattata_follows_at_the_kid_pace`.
3. **Micro-scène d'arrivée** (Kevin : plus lisible, plus de vie, réaction du héros). Contraintes du dossier 09 §2 tenues (première arrivée, contrôles bloqués, aucun dialogue, pas de caméra spectaculaire : **caméra inchangée**, le glissement permis n'a pas été jugé nécessaire). **Deux ajouts de données** (CutsceneLibrary / CutsceneDirector, testés) : `"background": true` sur un `move` de PNJ (sans suiveur) — le PNJ marche pendant que la scène continue, une étape suivante sur lui (move, hop, lean, despawn, scare, react) attend la fin de sa marche, la scène ne finit qu'à la fin de toutes ; étape **`react`** (joueur ou PNJ, sans attendre) — `Npc.react()` existant, **`Player.react()`** nouveau (animation `react_<dir>` si l'apparence l'a, sinon bond de 16 px en 0,28 s, l'ombre reste au sol). Chronologie (s, depuis le premier pas sur la place ; mesurée 3,4 s en test, 3,7 s à 30 i/s fixes) :
   - 0,0 l'enfant (23, 22) et son Rattata (24, 22) partent vers l'est en **marchant** (9 cases, jusqu'à (32, 22) / (33, 22), fin ≈ 2,45) ; 0,05 le héros se tourne vers eux (gauche) ;
   - 0,55 le voyageur (26, 21) baisse les yeux sur le Rattata qui passe sous lui ; 1,05 le héros les suit des yeux (haut, ils passent devant lui), 1,4 (droite), le voyageur aussi ;
   - 1,8 le Roucool, posé sur l'**auvent gauche** de la Boutique (33, 21 ; il était sur l'auvent droit, (38, 21), au bord de l'écran), sursaute ; 2,0 il s'envole (absent pour la visite) ; le héros lève la tête (haut) avec un **petit bond** ;
   - 2,1 le voyageur descend (bas, droite, bas, bas → (27, 24), sur les marches, à côté du héros) ; 2,5 l'enfant, arrivé, lève les yeux vers le Roucool ; 2,8 le héros se tourne vers le voyageur (gauche), 3,15 le suit (bas) ;
   - ≈ 3,2 le voyageur s'efface (0,2 s) ; le héros regarde de nouveau la ville (haut) ; `viridian_arrived` ; contrôles rendus.
   Test `test_arrival_scene.test_the_arrival_beats_come_one_after_the_other` (ordre enfant → Roucool → voyageur, bond du héros à l'envol, regards du héros, 9 pas de marche de l'enfant, contrôles bloqués tout du long) ; le test existant vérifie ≤ 4 s, une seule fois, Roucool absent ensuite.
4. **Hypothèse à valider** : le dossier dit « l'enfant traverse **en courant** » ; sans planche de course pour l'enfant (ni le Rattata), il marche. Produire `enfant_run` / `rattata_run` (Codex) rendrait la course (la scène raccourcirait d'environ 1 s). **Non fait** : 2 à 3 « petites réactions autour » demandées → réalisées avec le voyageur (regard), le Roucool (sursaut) et l'enfant (regard vers le ciel) ; la Dresseuse et son Roucool sont hors champ (13–14, 22), le livreur suit sa routine.
6. **Végétation sans ombre** (Kevin : « des fois les ombres donnent une impression de suspension ; pour les arbres ou les plantes on n'en a pas besoin ») : règle de données par famille, **`PaintedPropRules.VEGETATION_PREFIXES`** (`tree_`, `prop_buisson_`, `prop_haie`, `prop_platebande_`, `prop_massif_`, `prop_pots_fleurs_`, `prop_potager_`, `int_plante`, `ground_hautes_herbes_`) → `is_vegetation` / `casts_shadows` ; `tools/build_painted_props.gd` ne pose ni `CastShadow` ni `ContactShadow` pour elles (les images d'ombre restent au catalogue). Images provisoires de Bourg Palette, de la Route 1 et des intérieurs : `tools/gen_placeholder_props.gd` (`NO_SHADOW_PREFIXES` : `tree_`, `plaza_tree`, `bush_`, `brambles`, `vegetable_patch`, `plant`) ne peint plus l'ellipse d'ombre ; seules ces images changent. Touffes d'herbe : décalcomanies sans ombre (vérifié) ; aucune ombre peinte dans les images peintes de la végétation (vérifié : seuls les contours anticrénelés sont semi-transparents) ; `lighting.json` (« cast_shadow », « contact ») et `WorldLighting` ne règlent que les nœuds des groupes `cast_shadows` / `contact_shadows`, aucun shader ne dessine d'autre ombre ; les personnages gardent leur ombre (`Shadow` de `npc.tscn` / du joueur). Tests : `test_painted_props.test_vegetation_has_no_shadow_node` (scènes peintes et images provisoires), `test_world_lighting` passe sur le banc. Gardent leurs ombres : bâtiments, lampadaires, bancs, clôtures, tonneaux, caisses, boîte aux lettres, linge, panneau, rochers, arche. **À montrer à Kevin** (ombre portée qui semble aussi détachée sur les captures `shadows_*_compare.png`) : boîte aux lettres (tache sombre décalée sous la clôture), lampadaires (ombre portée inclinée, fine, loin du pied), étendoir à linge et tonneau.
7. **Captures** : `tools/capture_viridian_retours.gd` (`--fixed-fps 30`, sans Movie Maker) → `build/captures/jalon07_t5_retours/` : `house_<maison>_{avant,apres}.png` (devant chaque portail), `door_<maison>_*` (« C'est fermé. »), `walk_<habitant>_*` (une vignette par image pendant les pas), `scene_timeline_*` (scène toutes les 0,1 s), `scene_kid_*`, `scene_<tag>/f*.png`. `capture_viridian.gd` (T5-XL) n'a pas été recalé sur la nouvelle chronologie (ses images de la scène tombent à d'autres moments).

### 15.22 QA du T5 sur téléphone (S21) — toits, garde-corps, habitants (constructeur-monde, 2026-10-05, base `j7-centre` à `7646231`, branche `j7-jadielle-qa`)

Rapport : `integ-j7-centre/build/qa/jalon07_t5_s21/rapport.md` (1re et 2e passes). Défauts (règle 4) :

1. **Toit effacé à tort** : sur la rue de la place, au-dessus du mur sud, le toit vert de la maison du bas s'effaçait (son image monte jusqu'à la rue). Règle : un décor « fade » ne s'efface que si le joueur est **au même niveau** que lui. `GameMap.level_rows` (Jadielle : murs 12 et 24, falaise 32 ; posé par `build_viridian_city.gd`) est transmis à chaque `WorldProp` (`level_rows`) ; `WorldProp.same_level(rangée_a, rangée_b, murs)` : niveau = nombre de murs strictement au-dessus, la rangée d'un mur (escalier) appartient au niveau du haut. Cartes sans `level_rows` : inchangées. Tests : `test_prop_fade.test_same_level_is_split_by_walls`, `…test_tree_below_a_wall_stays_opaque_for_a_player_above`, `test_viridian_city.test_roofs_fade_only_for_a_player_at_their_level`.
2. **Garde-corps qui cachait le héros jusqu'aux épaules** (88 px d'image sur 128 de personnage, collé dessus : 78 px cachés). Défaut : **`BALUSTRADE_SCALE` = 0,62** (≈ 55 px, image entière réduite, pas étirée ; bandes de 2,48 cases) → collé au garde-corps, ≤ 46 px cachés (les jambes) ; même chose au mur nord et pour les PNJ (même tri par les pieds). La rangée collée reste praticable (la rue garde ses deux rangées). Test : `test_viridian_city.test_balustrades_hide_only_the_legs`.
3. **Habitants dans les passages** : gardien de l'Arène (12, 10) → **(7, 11)**, côté ouest du parvis, tourné vers la porte (`look` inchangé) : le parvis se traverse de l'est à la porte. Dresseuse (13, 22) → **(15, 21)** et son Roucool (14, 22) → **(16, 21)**, au bout du banc, hors de la rue ; enfant + Rattata : boucle de la rue (16..18, 22..23) → **pelouse du jardin public** derrière le banc (12..14, 19..20), même boucle et même décalage ; pots `PotsSquareW` (12, 21) → (17, 19) pour ouvrir la pelouse. Le livreur garde sa boucle sur la rangée 22 (devant la Boutique) : la rue est-ouest a **deux rangées**, la seconde paraissait absente parce que le garde-corps cachait celui qui y marchait (point 2). Test `test_viridian_city.test_inhabitants_never_block_a_passage` : (a) goulets = marches et paliers des escaliers, portails, portes du Centre et de la Boutique, passages, chemin de la sortie ouest, et **toute case dont le blocage coupe une destination** depuis l'entrée sud (devant des portes de maisons…) : aucune case de départ ni de route d'un habitant n'y est (sauf la case d'entrée du livreur dans la Boutique, porte de deux cases) ; (b) **toutes** les cases de **tous** les habitants (départs + routes, avant et après l'arrivée) occupées à la fois : les 11 destinations (3 sorties, Centre, Boutique, Arène, 6 maisons) restent atteignables (pire cas : couvre toutes les positions de route) ; (c) la porte de l'Arène s'atteint par le parvis depuis l'est. Avec les anciennes données, le test échoue (sortie ouest, Arène, maison ouest).
4. **Captures Mac** 2340 × 1080, avant/après : `build/captures/jalon07_t5_qa/` (`avant_*`, `apres_*` : toit, garde-corps sud et nord, parvis, rue ouest dont le héros qui longe le garde-corps, rue est avec le livreur) ; outil `tools/capture_viridian_qa.gd` (Movie Maker `--fixed-fps 30` obligatoire : fenêtre masquée → la boucle gèle ; attentes en images).
5. **À valider sur S24** : toit opaque depuis la terrasse ; héros visible jusqu'à la taille le long des garde-corps ; rues, parvis et portes libres ; garde-corps plus bas (rendu à juger en phase DA).

### 15.12 T12 — la Boutique jouable (constructeur-monde, 2026-10-05, base `j7-centre` à `cc3572f` + T11 `950a30e`)

Aucun fichier de `game/ui/`, de `game/systems/shop/`, `data/shops/`, `data/items/`, de la sauvegarde (format), du combat ni de la Route 22 touché. Contrat du §6.10 tenu tel quel côté directeur. Écarts et précisions :

1. **Outil** : la Boutique entre dans `tools/build_painted_interiors.gd` (`_viridian_mart`, + déclencheurs de scène) ; **`tools/build_viridian_shells.gd` supprimé**. Relancer l'outil réécrit aussi `viridian_center.tscn` avec de nouveaux `unique_id` seulement (non commité).
2. **Agencement** (prototype validé, colonnes posées sur la grille) : caisse 5 × 1 en (5..9, 4), marchand (`clerk`, peint) en (7, 3), rayons muraux 3 × 1 en (1..3, 3) et (11..13, 3), présentoirs 3 × 1 en (2..4, 7) et (10..12, 7) (le prototype avait x = 4,0 / 11,0 : symétriques autour de l'allée, une allée de 5 cases devant le paillasson), plante (13, 8). Murs : 3 rangées du fond (le T4 en mettait 2), colonnes 0 et 14, rangées 8 (sauf le paillasson bleu de l'enveloppe) et 9 ; **derrière la caisse bloqué** (5, 6, 8, 9 en rangée 3). Sortie : 3 cases PUSH (6..8, 8) → `viridian_city` / `from_mart`. Spawns `entrance` (7, 8) et `counter` (7, 5).
3. **Parler au marchand** : point fixe `ClerkCounter` (TALK, `clerk`, cases (6..8, 4), tourné vers le haut), comme l'infirmière. Le dialogue `clerk` (« Bonjour ! Qu'est-ce qu'il te faut aujourd'hui ? », §19) a **une seule variante** terminée par `open_shop` ; sans `got_oak_parcel` il ouvre aussi la Boutique (cas impossible en jeu : le déclencheur barre l'entrée).
4. **Première visite** : déclencheur `ParcelTrigger` sur **toute la rangée d'entrée** (5..9, 7), toutes directions — seul passage depuis le paillasson (testé) ; scène `mart_parcel` (`data/cutscenes/viridian_mart.json`, variante `unless: got_oak_parcel`) : le marchand se tourne, **« Bonjour ! Première fois à Jadielle ? » dit à l'entrée**, le joueur **va seul à la caisse** (7, 5) et se tourne vers lui (Rouge/Bleu), puis les trois autres répliques du §19 (dialogue `clerk_parcel`), `give oak_parcel` (toast « COLIS POUR CHEN — ajouté aux objets clés » par le chemin existant `item_given`), `set got_oak_parcel`. L'objectif change en silence (`objectives.json`, T10). **La Boutique ne s'ouvre pas** à la fin. Autosave : `cutscene_finished` (existant). Défaut (règle 4) : réplique 1 coupée du reste pour la marche ; réglable au T13.
5. **`open_shop`** : `ServiceDirector` émet `shop_requested(<carte courante>)` et rend la main (sans carte : push_error). Le menu ne peut pas s'ouvrir pendant un dialogue (garde « partie stable ») : **`Boot` garde la demande et ouvre `MenuRoute.shop(id)` en écran seul à `dialogue_finished`**. Boutique inconnue : push_error, rien.
6. **`MenuDirector`** : contrat du §6.10 + `build_shop()` (vue courante, tests) ; `open(route, standalone)` n'émet `dashboard_shown` que hors écran seul et laisse l'arbre sans pause si le navigateur refuse ; route SHOP inconnue ou sans `set_shops` → `placeholder_shown(SHOP)` ; boutique et onglet oubliés à la fermeture (`buy` / `sell` menu fermé → `NOT_SOLD_HERE`, rien ne change) ; un refus émet toujours `shop_result_shown(status_text, false)` (texte vide possible) ; succès → `mark_changed`, `shop_shown`, puis `shop_result_shown("Merci !", true)`.
7. **Boot** : `ShopLibrary.load_dir` + `check_references(_items)`, `set_shops`, câblage direct du vrai `TrainerMenu` (le T11 étant fusionné avant, plus besoin de `has_signal`), `shop_back()` en tête de `_screen_back()` (retour Android : confirmation, puis fermer). `get_shop_library()`.
8. **Livreur dans la Boutique** (`mart_courier`, apparence `courier`, (12, 5), réplique **`draft`**) : repris du prototype validé (le « client » du §5.2). **Le livreur existe aussi dehors** (sa boucle entre dans la Boutique) : même question que la Dresseuse du Centre, pour Kevin au T13.
9. **`DebugStart`** : clé **`favorites`** (objets de « bag » marqués favoris) ; départ `shop_qa` (Salamèche N8, Roucool N7, 6 000 ₽, 3 Poké Balls, 4 Potions favorites, devant la porte, tourné vers le sud).
10. **Tests** : `test_menu_director_shop` (unitaire, 12, écran factice `tests/helpers/fake_shop_screen.gd` qui reproduit le câblage de `Boot`), `test_viridian_mart` (9), `test_mart` (vrai `Boot` et vrai `ShopScreen`, 4), `test_menu_unlock_rule` (+1 : Boutique jamais carte ni lien, aucune trace du Pokédex dans ses deux onglets, argent absent du tableau de bord), `test_service_director` (+1), `test_debug_start` (+3), listes de `test_dialogue_data`, `test_cutscene_data`, `test_objective_library` (`got_oak_parcel` n'est plus « futur »). **Piège GUT** : boutique ouverte = arbre en pause = les minuteries de `wait_until` gèlent (le test ne finit jamais) ; attendre des images (`wait_process_frames`), jamais `wait_until`, menu ouvert.
11. **Captures** : `tools/capture_mart.gd` → `build/captures/jalon07_t12/mart_0*.png` (2340 × 1080). Constat hors périmètre (T11 / données T10) : l'icône du toast du colis est la Poké Ball générique.

### 15.14 T16 — le Stockage jouable (constructeur-monde, 2026-10-05, base `j7-centre` à `20db1f3`, T15 fusionné)

Contrat du §6.9 **respecté tel quel** côté directeur. Aucun fichier de `game/ui/`, de `game/systems/storage/**`, `menu_unlocks.gd`, `menu_route.gd`, `team_view(s).gd`, `party.gd`, `pokemon_storage.gd`, du format de sauvegarde, de `dialogue_runner.gd` ni du combat touché ; aucune règle du T14 changée (aucun bug trouvé). Écarts et précisions :

1. **Terminal** : dialogue `storage_terminal` (`data/dialogues/viridian_center.json`) **sans page** (`narration`, `action: open_storage`) : le lecteur ne montre aucune boîte (cas prévu au T6) ; aucune réplique inventée. Point fixe `StorageTerminalScreen` (EXAMINER, cases (1..2, 3), **de face seulement**, tourné vers le haut) ajouté par `tools/build_painted_interiors.gd` ; spawn `terminal` (1, 4). Carte régénérée (la Boutique, relancée aussi, n'avait changé que de `unique_id` : non commitée).
2. **`ServiceDirector`** : `open_storage` émet `storage_requested` et rend la main (sans carte : push_error, comme `open_shop`) ; `PENDING_ACTIONS` supprimée. **`Boot` garde la demande et ouvre `MenuRoute.storage()` en écran seul à `dialogue_finished`** (même chemin que la Boutique ; échec → push_error).
3. **`MenuDirector`** : signaux et méthodes du §6.9, + `build_storage()` et `get_storage_selection()` (tests). Les actions ne font rien hors de l'écran Stockage (menu fermé ou autre écran : faux). `select_storage` sur la carte déjà sélectionnée ou une place absente : rien émis. Un refus de `request_release` passe par `StorageViews.result_text` (même texte que la règle). Sélection oubliée à la fermeture ; entrée = `StorageSelection.first`.
4. **`Boot`** : `_unlocks.set_location(_zones, _current_map_id)` (relu à chaque appel : le bouton STOCKAGE de l'Équipe n'apparaît que dans le Centre, sans autre câblage) ; câblage **direct** du vrai `TrainerMenu` (T15 fusionné avant, comme la Boutique au T12 : plus de `has_signal`) ; `storage_back()` dans `_screen_back()` juste après `shop_back()` (retour Android : confirmation = ANNULER, puis « ⋯ », puis fermer — ou revenir à l'Équipe si le Stockage a été ouvert par elle). Autosave : `mark_changed` → `menu_closed(true)` (existant).
5. **`DebugStart`** : clé de membre **`favorite`** (booléen, équipe et stockage) ; départ **`storage_qa`** : Salamèche N9, Roucool N8, Rattata N6 **K.O.**, Piafabec N6, Nidoran♀ N5, Férosinge N5 ; 10 au stockage dont Piafabec N5 **favori** ; 3 000 ₽ ; dans le Centre devant le terminal (`terminal`, vers le haut).
6. **Tests** : `test_menu_storage` (intégration, vrai `Boot` et vrai `StorageScreen`, 7 : départ, terminal → écran seul sans réplique et retour = fermer sans autosave, déposer au bouton et en glissant, reprendre en glissant, équipe pleine et dernier Pokémon refusés, favori protégé sans confirmation, ANNULER par le retour puis LIBÉRER, sauvegarde relue, combat suivant = premier valide (Piafabec après Rattata K.O.), bouton STOCKAGE au Centre seulement, rien en ville) ; `test_menu_director_storage` (unitaire, 8) ; `test_service_director` (+1, cas sans carte adapté) ; `test_viridian_center` (le terminal s'examine de face ; remplace « terminal inerte ») ; `test_debug_start` (+3) ; `test_dialogue_data` (IDS + `storage_terminal`).
7. **Captures** : `tools/capture_storage.gd` → `build/captures/jalon07_t16/storage_0*.png` (2340 × 1080) : terminal, écran ouvert, équipe pleine, dépôt, favori refusé, confirmation, libéré, dernier Pokémon, Équipe avec STOCKAGE.
8. **Question pour Kevin (T17)** : examiner le terminal ouvre l'écran **sans texte** (aucune réplique au §19). Une ligne de narration (« Le terminal du Stockage Pokémon s'allume. ») serait un texte nouveau (`draft`) : défaut = aucune. **Tranché par Kevin (2026-10-05)** : « Un terminal de Stockage Pokémon. » à la **première** utilisation seulement (drapeau `storage_terminal_seen`, `draft`) ; vérifié en QA au T17.

### 15.19 T19 — la remise du colis et l'activation du Pokédex (constructeur-monde, 2026-10-05, base `j7-centre` à `33fb9bd`)

Contrat du §3.6.2 **respecté tel quel**. Aucun fichier de la Boutique, de `game/ui/`, de la sauvegarde (format), du combat, de `dialogue_*.gd`, `cutscene_step.gd`, `cutscene_library.gd`, `game_state.gd`, `menu_unlocks.gd` ni des textes de `data/dialogues/oak_lab.json` touché. Écarts et précisions :

1. **`Boot`** (seul fichier de jeu modifié, minimum) : `_runner.token_values = _dialogue_token_values` (méthode plutôt que lambda : `DialogueTokens.values_for(GameState.first_wild_species(), _pokemon)`), `_runner.cutscene_requested.connect(_on_cutscene_requested)` (`play(id)` ; refus → `push_warning`), `_cutscenes_node.set_hud(_hud)`. Rien d'autre : l'autosave de fin de scène et l'absence de toast à l'activation existaient déjà.
2. **Mise en scène** (`data/cutscenes/oak_lab.json`, réglage permis) : **une étape `move` ajoutée** — le rival, apparu sur la porte (7, 9), marche jusqu'à (7, 7) **avant** « Professeur ! Je suis revenu. » (sur la capture, la porte est sous la boîte de dialogue : il parlait invisible). Ordre des répliques et de `take` / `set` / `caption` inchangé (`test_cutscene_data` vert). Silences et regards du T18 gardés (lisibles sur capture).
3. **Départ `parcel`** : Salamèche N9 + Roucool N7, Poké Ball ×3, Potion ×2, colis, 2 700 ₽ (défauts), drapeaux du prologue + `got_potion_route_1`, `viridian_arrived`, `got_oak_parcel`, paire `taken_charmander` / `taken_squirtle`, `rival_lab_won` ; devant la porte du labo (`oak_lab_door`, tourné vers le nord). `DebugStart` ne sait pas poser de première rencontre : ce départ est le cas « **sans rencontre** » (réplique de l'espèce omise) ; le cas avec espèce est la vraie partie.
4. **`test_parcel_scene`** (2 tests, vrai `Boot`) : départ `parcel` et **vraie partie de Kevin** (`v2_kevin_j6_fin.json` migrée, + `viridian_arrived`, `got_oak_parcel` et le colis, comme après la Boutique du T12). Vérifie : pages exactes dans l'ordre (« Un Roucool… » seulement pour Kevin), drapeau levé **une fois** après « Ton voyage… », légende POKÉDEX ACTIVÉ juste après, rival entré puis reparti, **aucun toast** tout du long (+ 30 images après), colis retiré (`got_oak_parcel` gardé), 5 → 6 cartes, objectif vide, ligne vus · capturés, drapeau et Sac **écrits** à la fin de la scène, Pokédex de Kevin montrant Roucool, Rattata, Salamèche, reparler à Chen → « Le monde qui vous attend… », aucune scène. La légende garde ses fondus, sa tenue est raccourcie à 0,3 s dans le test.
5. **Captures** : `tools/capture_parcel.gd` (`--save=kevin` | `--save=parcel`) → `build/captures/jalon07_t19/oak_parcel_<partie>_*.png`, `pokedex_activated_<partie>.png` (légende), `pokedex_activated_<partie>_menu.png` (6 cartes, « 4 vus · 3 capturés » pour Kevin), 2340 × 1080. La sauvegarde de Kevin est chargée en mémoire (jamais le vrai `user://`).
6. Chen et Maya sont encore des sprites provisoires (pas de planche peinte `oak`) ; le rival et le héros sont peints. Rendu : à noter seulement (règle 3).


### 15.11 T11 — l'écran Boutique et l'argent affiché (ui-mobile, 2026-10-05, base `j7-centre` à `cc3572f`)

Contrat du §6.10 **respecté tel quel** (signaux, méthodes et vues de `TrainerMenu` : `shop_mode_changed`, `shop_buy_requested`, `shop_sell_requested`, `show_shop`, `show_shop_result`, `show_shop_confirm`, `shop_back`, `get_shop`). Ajouts : `get_shop_choice()` (la `ChoiceCards` de la confirmation), `ShopScreen.get_*` et `QuantityStepper` (`game/ui/shop/`). Écarts, tous sans effet sur T12 :
- **RETOUR en haut de la colonne de gauche** (comme le Sac), et non dans la colonne de droite du §6.4 : la colonne de droite (aperçu, QUANTITÉ, TOTAL, CONFIRMER 128 px) ne tient pas à 840 px de haut avec un second bouton de 128 px. Le × de l'en-tête et RETOUR ferment toujours ; aucune pastille de zone (`show_shop` vide le nom de zone).
- **`TapGuard` non posé sur les cartes** : `TapGuard` s'attache à un `BaseButton`, les cartes sont des `BagTile` dont le seuil de glissement est déjà `TAP_SLOP` (validé au J6). `scroll_deadzone = TAP_SLOP` sur la liste ; testé au doigt simulé (`touch_finger.gd`) : un glissement ne sélectionne rien. Un toucher sur une carte ne fait que la sélectionner (jamais d'achat).
- **Objet indisponible** (argent insuffisant) : CONFIRMER et sélecteur atténués, mais CONFIRMER reste touchable : il tremble, vibre 20 ms, écrit la raison dans la barre de résultat (en plus de la raison fixe sous TOTAL) et n'émet **rien**.
- `UseResultBar.show_result(text, can_repeat, success := -1)` : 1 / 0 force succès / refus (« Merci ! » n'a pas de « + »).
- `show_shop` dans le même onglet garde objet, quantité (reprise dans ses nouvelles bornes), défilement **et barre de résultat** ; autre onglet ou ouverture : première carte, quantité 1.
- Argent : colonne de gauche de la Boutique (ARGENT + pièce), ligne « Argent : 3 000 ₽ » dans l'écran Dresseur (la phrase « ni argent » de l'en-tête de `TrainerScreen` est retirée), pastille sous les catégories du Sac (`BagScreen.get_money_text()`). Nouvelles icônes `assets/ui/icons/shop/` (pièce, plus, moins), tokens `SHOP_*`, variations `Shop*` (`tools/build_ui_theme.gd`).
- Prix écrit sous chaque carte (`ShopEntryView.price_text`) ; titre central = libellé de l'onglet (aucun libellé nouveau). Appui long sur − / + : délai `LONG_PRESS`, puis un cran / 0,16 s, puis 5 crans / 0,06 s après 1,2 s (défauts, `SHOP_REPEAT_*`).
- Outil de capture : `tools/capture_menu.gd --only=shop_buy,shop_sell,shop_no_money,shop_confirm,trainer_money,bag_money` (le décor du monde derrière le menu affiche une erreur « spawn inconnu jadielle_soon_w » préexistante, sans rapport).

### 15.13 T15 — l'écran Stockage (ui-mobile, 2026-10-05, base `j7-centre` à `33fb9bd`)

Contrat du §6.9 **respecté tel quel** (signaux et méthodes de `StorageScreen` et de `TrainerMenu`, vues du T14 intactes, `boot.gd` / `menu_director.gd` / `game/systems/storage/**` non touchés). Ajouts : `TrainerMenu.get_storage()`, `StorageScreen.get_*` (cartes, boutons, zones, refus, menu), `toggle_menu()`, `StorageCard` (`game/ui/menu/storage/storage_card.gd`), `TeamScreen.get_storage_button()`. Écarts, sans effet sur T16 :
- **Mise en page** (840 px de haut sous l'en-tête) : ÉQUIPE à gauche (six cartes de 128 px, écart 4 px, titre de 40 px), au centre RETOUR, le Pokémon sélectionné (`PokemonShowcase`, sprite ×3, ni XP ni pilule « Favori » : l'étoile de la carte et le bouton FAVORI suffisent) et deux rangées d'actions (DÉPOSER / REPRENDRE en accent pleine largeur ; FAVORI + « ⋯ »), à droite la grille (2 colonnes à 1920, 3 à 2340, cartes de 420 px au moins). `PokemonShowcase._init(sprite_scale, with_xp)` : paramètres optionnels, l'Équipe est inchangée. La **fiche complète** (`StorageView.sheet` : statistiques, capacités, histoire) n'est pas affichée : la hauteur manque ; la vue la porte toujours.
- **`TapGuard` non posé** (comme à la Boutique, §15.11) : il s'attache à un `BaseButton`, les cartes sont des `Control` ; `StorageCard` (sous-classe de `TeamSlotCard`) a le même effet : filtre PASS, appui non consommé, `TapGuard.is_scroll` (TAP_SLOP) annule l'appui long, un toucher doit être immobile (≤ TAP_SLOP) ; `scroll_deadzone = TAP_SLOP`. Testé au doigt simulé (`touch_finger.gd`).
- **Sélection** : toucher une carte n'émet que `selected` ; la vue (fiche, actions DÉPOSER/REPRENDRE) change quand le directeur renvoie `show_storage` (aller-retour synchrone). Toucher la carte déjà sélectionnée n'émet rien.
- **Refus** : la carte tremble (comme CONFIRMER à la Boutique), vibre 20 ms, la raison s'écrit dans une pastille rouge sombre en haut de la fiche (4 s ou jusqu'au prochain geste ; fixe si `speed_scale` = 0). Une vue neuve l'efface.
- **Glisser** : appui long (`LONG_PRESS`) ; fantôme sous le doigt, cadre ACCENT sur la liste visée (plus vif quand le doigt est dessus) ; déposer ailleurs ou sur sa propre liste = rien. Le glisser est consommé : la grille ne défile plus.
- **Menu « ⋯ »** : volet opaque au-dessus du bouton, une seule entrée LIBÉRER (128 px) ; toucher à côté ou retour le ferme. La confirmation (`ChoiceCards`) est un enfant de l'écran ; retour Android : confirmation (= ANNULER), puis menu, puis l'hôte (`storage_back`). `TrainerMenu.close_animated` referme tout.
- **Bouton STOCKAGE de l'Équipe** : à droite de RETOUR, caché (jamais grisé) sans `storage_available`, émet `route_requested(MenuRoute.storage())`.
- Nouveaux : icônes `assets/ui/icons/storage/` (déposer, reprendre, « ⋯ », libérer ; provisoires), jetons `STORAGE_*`, variations `StorageDropZone` / `StorageRefusal` / `StorageMenu` / `StorageRefusalText` / `StorageTitle` / `StorageEmpty`. Pas de réutilisation de cartes (pool simple) : à surveiller si le stockage dépasse ~100 Pokémon.
- Captures : `tools/capture_menu.gd --only=storage,storage_drag,storage_menu,storage_release,storage_refusal,storage_empty,storage_team_button` (`build/captures/jalon07_t15/`).

### 15.7 T7 — le choix dans la boîte de dialogue (ui-mobile, 2026-10-05)

API conforme au §6.5, sans écart de contrat : `DialogueBox.show_choice(view)`, `hide_choice()` (silencieux), `cancel_choice() -> bool` (émet `choice_made(false)`), `is_choice_showing()`, signal `choice_made(confirmed)` (un par question). Précisions : (1) `ChoiceCards` est un **enfant de la boîte** (calque 30, créé au premier choix, gardé) ; la boîte reste ouverte derrière le voile, sa page à peine lisible : la question est dans `ChoiceView.title`. (2) Pendant un choix, `_input` n'avance plus et ne consomme plus le toucher (les cartes le reçoivent) ; `ui_cancel` = `cancel_choice()`. (3) `close()` cache un choix encore affiché, sans signal. (4) `get_choice_cards()` expose le composant (tests, `speed_scale`). (5) **Correctif dans `ChoiceCards` (T28)** : le contenu n'était jamais centré verticalement (collé en haut ou, en position animée, hors écran : la position d'un conteneur ancré cassait sa hauteur) ; le glissement d'apparition passe par `offset_top` / `offset_bottom` du `CenterContainer` et le contenu a une largeur minimale (deux cartes + écart). Les usages existants (confirmation d'oubli) en profitent. Rappel T8 : le retour Android appelle `_box.cancel_choice()` en premier dans `Boot._on_go_back`.

### 15.8 T8 — le Centre jouable (constructeur-monde, 2026-10-05, base `j7-centre` à `da54783` + T7 `610c32a`)

Aucun fichier de `game/ui/`, de la sauvegarde (format), du combat, de `dialogue_runner.gd`, `dialogue_library.gd`, `rest_point_library.gd` ni de la Route 22 touché. Écarts et précisions :

1. **Outil** : `tools/build_painted_interiors.gd` (nouveau) construit `viridian_center` au lieu d'étendre `tools/build_interiors.gd` (outil des intérieurs **en tuiles** du J2 : le relancer réécrirait quatre cartes ; un intérieur peint n'a ni sol ni murs en tuiles). La Boutique (T12) y entrera à son tour ; `tools/build_viridian_shells.gd` ne construit plus que la coquille de la Boutique (à retirer au T12).
2. **Agencement** (prototype validé) : comptoir 5 × 1 en (5..9, 4), infirmière en (7, 3), terminal (1..2, 3), banquettes (2..3, 7) et (11..12, 7), plantes (12, 3), (1, 8), (13, 8). Colonnes posées sur la grille (banquettes en x = 3 et 12, symétriques ; le prototype avait 3,4 / 11,6 et une emprise décalée d'une case à droite) ; hauteurs du prototype gardées (pied remonté dans sa case). Murs : 3 rangées du fond (prototype), colonnes 0 et 14, rangées 8 (sauf le paillasson) et 9 ; **derrière le comptoir bloqué** (5, 6, 8, 9 en rangée 3 : on ne passe pas derrière l'infirmière). **Sortie : 3 cases PUSH** sur le paillasson (comme la coquille du T4 ; le §6.3 disait 2 : le paillasson peint couvre 2,5 cases).
3. **Parler à l'infirmière** : point fixe `NurseCounter` (TALK, `nurse`, cases (6..8, 4), tourné vers le haut) sur le comptoir ; l'infirmière (PNJ `nurse`, apparence peinte `nurse`) n'a pas de dialogue propre. Point de repos `heal` = (7, 5), tourné vers le haut.
4. **Machine** : `HealMachine` (`game/world/props/heal_machine.gd`, `%HealMachine` dans `Entities`, 1 px devant le pied du comptoir) : halos additifs construits en code sur les six alvéoles **peintes** du comptoir + éclat, `AnimationPlayer` « heal » écrit pour 3 s, étiré à la durée demandée ; `flashed` à 2,3 s → `Haptics.vibrate(UiTokens.CENTER_HEAL_HAPTIC_MS = 20)`. **Une alvéole allumée par Pokémon de l'équipe** (Rouge/Bleu ; le §6.3 disait « six ») : défaut, à juger au T9. `attendant` / `attendant_turn` : l'infirmière se tourne vers la droite pendant le rituel puis revient.
5. **`ServiceDirector`** : contrat du §3.3.2 + `heal()` (Maman : `Boot._on_heal_requested` l'appelle), `ritual_duration()`, `reduce_motion` (posé par `Boot._apply_settings`), `is_running()`. Soin **au début** du rituel. Sans machine : attente de la durée. `open_shop` / `open_storage` : push_error « pas encore branchée » (T12 / T16).
6. **`DefeatRecovery`** : contrat du §3.3.2 + `wakeup_point()`. `EncounterDirector.setup(…, recovery)` remplace le paramètre `runner` (le mot du lieu est joué par `DefeatRecovery`) ; sans lui : soin + retour au point de repos de l'état, sans mot. `woke_up_after_defeat` reste, relayé **seulement pendant une rencontre** ; **Boot écoute `DefeatRecovery.woke_up`** (et non plus le relais) : le T25 n'aura rien à câbler pour l'écriture.
7. **Boot** : `ServiceDirector` et `DefeatRecovery` dans `boot.tscn` (PAUSABLE) ; `_rest_points` ; `action_handler` ; choix câblé directement sur l'API du T7 ; `cancel_choice()` en tête de `_on_go_back` ; `center_healed` → écriture **immédiate** « soin » ; le **toast attend la fin du dialogue** (après « Voilà… », ordre du résumé 7A.2), une fois par changement de point de repos. `cutscene_requested` non câblé (T19). Accès : `get_service_director()`, `get_defeat_recovery()`, `get_rest_points()`.
8. **Données** : `rest_points.json` + `viridian_center` ; `data/dialogues/viridian_center.json` (`nurse` et `nurse_wakeup` mot pour mot du §19 / Q-9 ; **`center_lass` en `draft`**) ; `data/npcs/viridian_center.json` (infirmière, Dresseuse au repos et son Roucool peint, `idle_react` 6 s). **La Dresseuse existe aussi sur la place** (même apparence) : question pour Kevin au T9.
9. **`DebugStart`** : clés `money` (0 à 999 999) et `storage` (format des membres) faites (TODO du §5.5) ; départ `center_qa` (Salamèche N8 à 6 PV, Roucool N7 K.O., devant la porte du Centre, tourné vers le sud).
10. **Rituel boîte ouverte** (défaut du T6) : pendant les 3 s, la boîte garde la question « Bonjour. Je m'occupe de ton équipe ? » (capture `center_04_ritual`) ; lisible, à juger au T9.
11. **Correctif hors périmètre** : `tests/integration/test_coming_soon.gd` ne se chargeait plus depuis le T4 (en-tête de `_start_at_the_north_gate` perdu : GUT l'ignorait sans échec) ; en-tête rétabli, 5 tests verts.

### 15.2 T2 — fondations du monde peint (2026-10-05, base `j7-monde` à `8716088`)

Fait en parallèle du T0 (sauvegarde v3, autre session) : **aucun** fichier de `boot.gd`, `game_state.gd`, `save_system.gd`, du combat ni de `tools/art/` touché. Écarts et précisions par rapport au §3.2 :

1. **`DebugStart` `money` / `storage` : pas faits** (ils dépendent de `GameState.money`, T0). Le départ `tools/debug_start/viridian.json` existe **sans** eux. TODO au §5.5.
2. **Départ `viridian`** : `route_1` / spawn `jadielle_soon_w` / vers le haut (au bout nord de la Route 1, un pas = l'arrivée à Jadielle), Salamèche N8 + Roucool N7, 3 Poké Balls, 2 Potions, drapeaux du prologue jusqu'à `rival_left_lab`. La carte de Jadielle n'existant qu'au T4, c'est le seul point d'arrivée vérifiable aujourd'hui ; il sert aussi `test_arrival_scene` (la scène se déclenche 2 cases après l'entrée). **Contrat T4** : si `build_route_1.gd` renomme ce spawn, mettre à jour `viridian.json` (le test `test_shipped_viridian_start` vérifie que le spawn existe sur la carte).
3. **`data/world/lighting.json`** : un objet `profiles`, chaque profil en **blocs** (`grade` { shadows, midtones, highlights, strength }, `sun_direction`, `rim` { color, strength, width }, `cast_shadow` { color, alpha, length, skew_deg }, `contact` { color, alpha }, `wind`) ; couleurs `#rrggbb`, alpha à part. `grade` et `sun_direction` obligatoires, les autres blocs facultatifs (absents = aucun effet). Valeurs `golden_hour` relevées dans les shaders et le script du prototype (`etalonnage`, `objet` : liseré `#ffd17a` force 1 largeur 5 px, `ombre` : `#1a1738` α 0,34, 0,26, −45°, `contact` : `#1f1a33` α 0,62, vent 5 px). **`interior_warm`** (défaut, règle 4 ; non mesuré, rien au prototype) : gains ombres 1,04/1,02/0,99, moyens 1,02/1,00/0,97, lumières 1,01/0,99/0,95, sans liseré, sans ombre portée, sans vent, contact gardé.
4. **Restent dans les shaders et l'outil d'art (T3), pas dans le profil** : vitesse du vent (1,1), seuils de luminance de l'étalonnage (contours 0,04–0,14, zones 0,15–0,45 / 0,50–0,85), facteur du liseré (×1,45, 0,55, seuil 0,12–0,4), rayon du flou de l'ombre portée (10 px, désormais pré-flouté), étendue de l'ombre de contact (18 px) et part de la base (0,05 objets, 0,12 bâtiments, 0,1 personnages). Ce sont des constantes de technique, pas d'ambiance ; le jour/nuit n'en a pas besoin.
5. **`LightProfile`** gagne `has_grade()`, `has_rim()`, `has_cast_shadow()`, `has_contact_shadow()`, `has_wind()` (pour `WorldLighting` : bloc absent = calque caché / paramètre à zéro). `LightingLibrary` gagne `has_profile`, `get_ids`, `size`, et `parse_profile` statique.
6. **`CharacterLook`** dans `game/world/character_look.gd` (partagé par `Npc` et `Player`, comme `grid.gd`) ; gagne `painted: bool`, `painted_frames_path` / `placeholder_frames_path` ; `resolve(sprite, exists := Callable())` (sans Callable : `ResourceLoader.exists`). Générique = `placeholder/npc_frames.tres` (même que `Npc.FALLBACK_SPRITE`). **Non branché** dans `Npc` / `Player` : c'est le T3.
7. **`NpcSpec.route_start`** : avec `"start"`, `cell` doit être `cells[start]` (sinon refus) ; **sans** `"start"`, `route_start` = première occurrence de `cell` dans la boucle (0 si absente), exactement ce que fait `Npc._start_route` aujourd'hui — le T3 peut donc remplacer `_route.find(cell)` par `route_start` sans changer le Voyageur de la Route 1 (`route_start` = 1). `route.enter` = `{ "cell", "seconds" }`, case dans la boucle, secondes dans ]0, 120] ; `idle_react` dans ]0, 120], interdit sur un « shy ». Aides `enters_building()`, `has_idle_react()`. Le **comportement** (fondu, absence, animation) est au T4 dans `Npc` (rien n'est joué au T2).
8. **Étape `scare`** : bibliothèque **et** directeur (`CutsceneDirector._scare`). L'étape **n'attend pas** la fin de la réaction (la micro-scène ≤ 4 s enchaîne ses gestes) ; même geste que `AmbientWatcher` (envol, ou fuite de 3 pas à l'opposé du joueur ; acculé : il se retourne et reste), puis `GameMap.remove_npc` à `left_scene`. Acteur pas « shy » ou introuvable : `push_error`, étape sautée. `test_cutscene_data` vérifie que l'acteur d'une étape `scare` des vraies données est « shy ».
9. **`GameMap.light_profile`** ajouté (vide partout) ; rien ne le lit encore (T3 : `WorldLighting`).


### 15.3 T3b — lumière C2, objets et personnages peints (2026-10-05, base `j7-monde` à `73c8c14`)

Aucun fichier de `boot.gd`, `game_state.gd`, `save_system.gd`, du combat ni des rencontres touché. Écarts et contrats pour T4 :

1. **`WorldLighting` n'est pas encore dans `boot.tscn`** (une autre session y travaille ; aucune carte n'a de profil avant T4). **Contrat T4** : instancier `WorldLighting.new()` dans `Boot` (après `World`), appeler `apply(lighting_library.get_profile(map.light_profile), map)` à chaque changement de carte (profil inconnu ou vide → `apply(null, map)`), et `set_reduced_effects(profile.reduced_effects)` depuis `Boot._apply_settings` (« Économie »). `LAYER_WORLD_GRADE` = 6 dans `UiTokens`.
2. **Globaux de shaders** dans `project.godot` (`[shader_globals]`, `world_*`) : valeurs par défaut neutres (aucun effet sans `WorldLighting`).
3. **Ombres pré-calculées** : l'écrasement (0,26) et l'inclinaison (45°) sont **dans l'image** (T3a) ; `WorldLighting.shadow_transform` cisaille et étire l'image préparée pour un autre profil (identité pour `golden_hour`). Le test `test_painted_props` vérifie que les constantes du jeu égalent `tools/art/manifeste.json`.
4. **Ombre de contact corrigée** (écart trouvé par la comparaison) : le prototype posait le sprite de contact `etendue` px **plus bas** que l'objet ; `preparer.py` ne le faisait pas (ombre cachée sous l'objet). Manifeste : `ombre_contact.etendue` 22 → **18** (valeur du prototype) et nouvelle clé **`chute` = 18** ; seuls les `*_contact.png` et `catalogue.json` ont changé (sources de `build/art/` relancées, le reste identique à l'octet). Les parts de base restent celles du manifeste (série 04 : banc 0,2, lampadaire 0,1… ; la place de la série 01 avait 0,05 partout) : contact un peu plus marqué sous les petits objets.
5. **Couches de dessin d'une carte peinte** : `PaintedGround` z −3, ombres z −2 (absolu, enfants des scènes d'objets : un objet garde ses ombres), `GroundDecals` z −1 (décalcomanies, falaises, escalier, massif), `Entities` 0. `GameMap` lit aussi les emprises des `WorldProp` de `GroundDecals`.
6. **Emprises** (`PaintedPropRules`, règles de `emprises.gd`) : largeur paire → pied sur un **bord** de case, impaire → au **milieu** (`foot_position`). **Défauts** (règle 4) : portes du **Centre** et de la **Boutique** = 2 cases libres au bas de l'emprise (la carte y pose deux passages) ; **Arène et maisons entièrement solides** (porte de l'Arène = point d'examen devant elle) ; arbre central et massif posés sur un bord de case (le massif 4 × 3 est centré sur le tronc) ; escalier et herbes hautes traversables ; arche nord = ses deux piliers.
7. **Correspondance des personnages** (table `LOOKS` de `tools/build_character_frames.gd`, documentée dans `CharacterLook`) : `heros` (+ `heros_run`) → `player`, `rival` → `rival`, `infirmiere` → `nurse`, `marchand` → `clerk`, `livreur` → `courier`, `dresseuse` → `lass`, `enfant` → `kid`, `vieil_homme` → `old_man`, `voyageur` → `traveler`, `jeune_dresseur` → `youngster` ; Pokémon : `roucool` → `pidgey`, `rattata`, `piafabec` → `spearow`, `ferosinge` → `mankey`, `nidoran_f`, `nidoran_m` dans `assets/sprites/pokemon/painted/`. **Un Pokémon peint se demande explicitement** : `"sprite": "pokemon/pidgey"` (sinon `"pidgey"` reste provisoire : Bourg Palette et la Route 1 inchangées, Q-2 / Q-3). Le **rival est peint partout** dès maintenant (labo, maison ; Q-1). `Route 1 / traveler` garde l'apparence générique (`"npc"`) : la passer à `"traveler"` est une décision de données (T4).
8. **SpriteFrames** : `idle_<dir>` = colonne 0 (une image), `walk_<dir>` = colonnes 1, 2, 3, 0 à 4 / (2 × 0,27) ≈ 7,4 i/s, `run_<dir>` = planche de course du héros (95 × 130) à 12,5 i/s, la marche accélérée pour les autres.
9. **`Npc`** : `route_start` utilisé (au lieu de `_route.find`) quand il entre sur sa case de départ ; `Npc.frames_path` / `has_frames` passent par `CharacterLook`.
10. **`PerfCounter`** : `[perf] … tex=<Mo>` (`RENDER_TEXTURE_MEM_USED`).
11. **Compression VRAM** : mesurée sur Mac (place, 2340 × 1080) : **40,6 Mo sans perte → 26,8 Mo compressée** ; sur Mac la compression est BPTC/S3TC (pas ETC2/ASTC) et change visiblement le rendu (contours plus durs, mean abs diff ≈ 5/255 avec la version sans perte). **Défaut : on reste sans perte** (sous le budget de 64 Mo, fidèle au prototype validé) ; A/B à refaire sur le S24 au T5 si la mémoire le demande.
12. **Restent pour T4 / 7B.1** : écrire le masque de la carte (`assets/world/maps/<carte>_ground.png`), les enveloppes d'intérieur (`int_*_coque`, images, sans scène), le fond peint du Plateau Indigo (image, sans scène), la moitié basse des herbes hautes (`ground_hautes_herbes_01_bas.png`, cache-jambes 7B.1), le portrait et la pose de lancer du héros (UI / combat, hors périmètre).


### 15.4 T4 — la carte de Jadielle (2026-10-05, base `j7-monde` à `5987722`)

Aucun fichier de `game_state.gd`, `save_system.gd`, du combat, de `data/encounters/` ni de la carte `route_22` touché ; dans `boot.gd`, seulement `WorldLighting` (contrat §15.3 point 1). Écarts et contrats :

1. **Plan** (Q-5) : le prototype (40 × 28) est gardé pour la taille, les emprises et la composition (Centre à l'ouest, Boutique à l'est, arbre central, Arène à l'ouest vers la Route 22, arche nord, forêt autour) mais **la place centrale est descendue au sud** : la caméra montre ≈ 11 cases de haut ; avec la place au milieu (prototype), ni la Boutique ni son toit ne seraient visibles deux cases après l'entrée, et la micro-scène se jouerait hors champ. La « rue sud » devient deux rangées bordées de haies (arrivée entretenue), le quartier sud = les deux maisons de part et d'autre de la place. Au nord : place nord, quartiers nord-ouest et nord-est, parc à l'est. **À valider par Kevin au T5.**
2. **Sol** : aucun `TileMapLayer` (ni herbes hautes ni rebords à Jadielle) ; forêt, arrière des toits et rangée des clôtures = `GameMap.blocked_cells`. Le masque est une image importée : l'outil s'exécute en deux passes la première fois (masque, `--import`, scène).
3. **Roucool « sur le toit »** : posé sur l'**auvent** de la Boutique (rangée avant de son emprise, `lift` 230 px) pour être dans le champ à l'arrivée ; un PNJ avec `lift` peut occuper une case solide (test).
4. **Micro-scène** : les étapes d'une scène se jouent l'une après l'autre (seule `scare` n'attend pas) ; pour tenir ≤ 4 s, les acteurs sont des PNJ **déjà présents** à l'arrivée (`arrival_kid`, `arrival_rattata`, `arrival_traveler`, `unless: viridian_arrived`), immobiles, que la scène fait courir / marcher ; l'enfant et son Rattata restent là pour la visite, le voyageur repart vers la Route 1 (`despawn`). Les habitants de toujours (`kid`, `kid_rattata`, `traveler`) ont `if: viridian_arrived`. Mesuré : 3,2 s (test, temps réel) / 3,4 s (capture à 30 i/s).
5. **Comportements de `Npc`** (prévus au T2, joués au T4) : `route.enter` (fondu 0,25 s, case libérée, absent N s, ressort quand la porte est libre, nouvel essai toutes les 0,5 s) et `idle_react` (`react()` périodique, `Tween` en boucle, pas de `_process`).
6. **Intérieurs** : `viridian_center` / `viridian_mart` sont des **coquilles vides** (enveloppe, murs, sortie de 3 cases sur le paillasson, `interior_warm`, titre « Jadielle » comme les intérieurs de Bourg Palette) construites par `tools/build_viridian_shells.gd` ; **T8 et T12 les remplacent** (et retirent l'outil). Portes : les deux cases libres du bas de l'emprise (STEP_ON haut) ; retour sur la porte, tourné vers le bas.
7. **Route 22** : warp vers `route_22` / `from_viridian` sur (0, 16) et (0, 17) ; spawn `from_route_22` en (0, 16). Sans la carte, pousser vers l'ouest ne fait rien (le routeur journalise « carte inconnue ») ; `test_map_links` et `test_viridian_city` vérifient le contrat dès que la carte existe (`PARALLEL_MAPS`, test en attente sinon).
8. **Route 1** : le bord nord mène à Jadielle (warps PUSH, spawns `from_viridian_w/e` sur les cases de passage) ; `test_coming_soon` porte désormais sur la sortie nord de Jadielle (« ROUTE 2 — À venir »).
9. **Apparences** : habitant de l'Arène = `youngster` (aucune autre tenue peinte libre ; même tenue que le jeune Dresseur de la Route 22, à trancher au T5 avec Q-4) ; Pokémon peints opt-in `pokemon/pidgey`, `pokemon/rattata`. Le Voyageur de la Route 1 garde l'apparence générique (Q-3).
10. **Lumière** : `Boot` crée `WorldLighting` dans `_ready`, `apply(profil de la carte, carte)` dans `_on_map_changed` (profil vide → `null` ; inconnu → `push_error` + `null`), `set_reduced_effects` dans `_apply_settings`. `Boot.get_world_lighting()` pour les tests et outils.
11. **Mémoire** : `[perf] tex=` compte toutes les textures résidentes du processus (UI, combat, cartes voisines préchargées, dont les deux enveloppes 1440 × 960) : 72,3 Mo à Jadielle sur le Mac ; la carte seule ajoute 18,3 Mo (Bourg Palette : 13,0). Le budget « ≤ 64 Mo par carte » est tenu pour la carte ; la mesure S24 du T5 dira si le total du processus pose problème.


### 15.5 T24 — IA de niveau 2 et gains (2026-10-05, base `jalon-07` à `da54783`)

Seule tâche de combat en cours. Aucun fichier de `boot.gd`, de la sauvegarde, des cartes ni de `game/ui/` touché. Écarts et précisions par rapport au §3.8 :

1. **Règles de `smart`** (`BattleAI`, une IA par combat via `TrainerData.make_ai`) : note d'une attaque = puissance × STAB (1,5) × efficacité × précision (« ne rate jamais » = 100 %) ; **note nulle = inutile** (×0 ; statut sous ⅓ des PV ; statut déjà choisi **2 fois par ce Pokémon** dans le combat ; statut dont aucun effet ne peut plus agir : niveau déjà à ±6 dans le sens voulu, graine déjà plantée ou cible Plante, capacité sans effet géré comme Poudre Toxik). Choix : s'il existe une attaque **super efficace** utile, seules elles sont candidates (règle 2 appliquée **avant** la note : Flammèche ×2 l'emporte sur Croc de Mort STAB neutre, dont la note est plus haute) ; sinon la meilleure note ; égalité → `pick_index` parmi les meilleures (**aucun tirage s'il n'y a qu'une meilleure**) ; toutes inutiles → tirage parmi toutes ; sans PP → Lutte sans tirage. Les capacités de statut ignorent les types (comme le moteur). Sans `PokemonData` (`data` nul), `smart` = `random`.
2. **Note d'une capacité de statut utile** (le §3.8 ne la fixait pas ; défaut, règle 4) : `STATUS_SCORE` = **40** × précision, soit une attaque neutre de puissance 40 sans STAB : à égalité avec Charge / Griffe (tirage), derrière Tornade d'un Roucool (STAB), loin derrière toute attaque super efficace. Réglable à la QA (T26).
3. **`score_move(move, own, foe, chart, times_used)`** comme prévu ; ajouts : `times_used(pokemon, move_id)`, `is_low`, `status_has_effect`, `effectiveness_of` (statiques et testés), constantes `STATUS_MAX_USES` (2), `LOW_HP_RATIO` (⅓), `STATUS_SCORE`, `STAB`.
4. **Gains** : `TrainerData.prize_for(last_level)` (somme fixe si `prize_money` > 0, sinon `prize_per_level × niveau`, jamais négatif) ; `BattleConclusion.resolve(trainer, outcome, last_foe_level := 0)` ; défaite, fuite = 0, l'argent du joueur n'est jamais retiré. `TrainerLibrary` : clés facultatives `bag` (booléen, défaut vrai) et `prize_per_level` (entier ≥ 0) ; `prize_money` reste **obligatoire** (0 pour le rival n° 2) ; les deux > 0 → erreur « exclusifs ».
5. **Versement (fait ici, flux du §6.2)** : `BattleDirector`, à la fin d'un combat de dresseur gagné, avant la sortie de la HUD : bandeau « Tu remportes 280 ₽. » (`BattleText.prize_line`, marque `{money}` = `MenuFormat.money`, modèle `prize_won` en `draft`), puis `GameState.add_money`. Niveau du dernier Pokémon = dernier de l'équipe de la requête. **Le T25 n'a rien à brancher pour l'argent** ; l'autosave de fin de scène (`cutscene_finished`) l'écrit.
6. **SAC contre un dresseur** : `BattleViews.TRAINER_BATTLE_ACTIONS` supprimée → `trainer_actions(trainer)` (ATTAQUER, SAC si `allow_bag` ; ÉQUIPE et FUITE atténués ; sans dresseur : SAC permis). **Écart corrigé** : le Sac de combat était toujours construit en contexte « sauvage » ; `BattleViews.bag_entries(bag, items, context)` reçoit maintenant `Battle.item_context()` (contre un dresseur, les Balls sont rangées mais pas utilisables) et l'onglet d'ouverture suit `BagQuery.start_category` (SOINS contre un dresseur, CAPTURE en sauvage).
7. **Données** : `rival_lab` gagne `"bag": false` ; `rival_route22` comme au §3.8 (Roucool Nv. 7 puis le starter avantagé Nv. 8, `smart`, `can_lose: false`, `heal_after: false`, `gives_exp: true`, `prize_per_level: 35`, `bag: true`, `start_message: true`, `end_message: false`).
8. **Pas fait ici (hors du périmètre donné au T24)** : l'étape de scène **`wake_up`** (§3.8, dernier paragraphe) — elle touche `CutsceneStep` / `CutsceneDirector` et `DefeatRecovery` (monde) ; à faire avec le T25 ou par l'architecte juste avant. `BattleConclusion.blackout` est vrai pour une défaite contre `rival_route22`, rien ne l'applique encore dans le directeur (comme prévu : c'est la scène qui enchaîne `wake_up`).
9. **Simulation** (`tools/simulate_first_battle.gd`, partie J4 identique à l'octet ; `simulate_route_1_exp` et `simulate_grass_pacing` identiques) : 1 000 graines par starter, équipe du joueur Nv. 8 + un Pokémon de la Route 1 Nv. 7, sans objet, XP du combat comprise. Taux de victoire du joueur (Bulbizarre · Salamèche · Carapuce — moyenne) :

| Rival | Joueur | + Roucool Nv. 7 | + Rattata Nv. 7 | starter seul |
|---|---|---|---|---|
| smart | capacité au hasard | 7,6 · 0,9 · 74,8 — **27,8 %** | 10,9 · 0,0 · 69,5 — 26,8 % | 0,5 % |
| smart | 1re capacité offensive | 9,0 · 1,1 · 98,8 — **36,3 %** | 20,5 · 1,4 · 87,2 — 36,4 % | 0,5 % |
| smart | IA smart (joueur attentif) | 3,1 · 0,1 · 99,9 — 34,4 % | 11,4 · 0,3 · 99,2 — 37,0 % | 3,9 % |
| random (témoin) | 1re capacité offensive | 65,2 · 44,3 · 94,7 — 68,1 % | 58,9 · 50,7 · 40,9 — 50,2 % | 0,5 % |

Lecture : l'IA de niveau 2 divise à peu près par deux les chances du joueur ; **avec Salamèche, le rival n° 2 est presque imbattable sans objet** (son Carapuce Nv. 8 a Écume, super efficace, choisie à chaque tour ; le Salamèche du joueur n'a que Griffe et Rugissement avant le Nv. 9) ; avec Bulbizarre, Roucool (Tornade ×2) puis Salamèche sont durs ; avec Carapuce, la victoire est presque assurée (le Bulbizarre du rival n'a ni Fouet Lianes ni attaque super efficace avant le Nv. 13). Non simulés : les Potions (2 au départ, achetables), l'ordre de l'équipe, les niveaux au-delà de 8. **Question Q-14 pour Kevin** (compte rendu du T24).
10. **Constaté, pas corrigé (hors périmètre)** : à `da54783`, `tests/integration/test_coming_soon.gd` ne compile pas (en-tête de `_start_at_the_north_gate()` perdu à une fusion, ligne ~43 : `spawn` non déclaré) ; GUT l'écarte **sans échec**, donc `tools/test.sh` reste vert sans ce test. À réparer par la session du monde (sortie nord de Jadielle).


### 15.9 T25 — la scène du rival n° 2 (constructeur-monde, 2026-10-05, base `j7-centre` à `cc3572f`)

1. **Étape `wake_up`** (§3.8, laissée par le T24, §15.5 point 8) : `CutsceneStep.Kind.WAKE_UP` en fin d'enum, clé `"wake_up": true` (seule valeur admise, aucun autre paramètre, conditions `if` / `unless` acceptées) ; `CutsceneDirector.set_recovery(DefeatRecovery)` (branché par `Boot` juste après `_recovery.setup`) ; l'étape **attend** `DefeatRecovery.recover()` (soin, fondu, point de repos, `woke_up` → écriture immédiate par `Boot`, mot du lieu non attendu) puis **arrête la scène** : la carte a changé, les étapes suivantes ne sont pas jouées. Sans `DefeatRecovery` : `push_error`, la scène s'arrête quand même. Fichiers touchés hors du monde : `cutscene_step.gd`, `cutscene_library.gd`, `cutscene_director.gd`, `boot.gd` (une ligne), doc de `defeat_recovery.gd`.
2. **Pokémon du rival dans le décor** : le déclencheur lance la scène sans alias ; le Pokémon du rival est choisi par les **drapeaux `taken_*` posés au labo** (le starter du joueur et celui du rival) : `rival_charmander` si `taken_bulbasaur` + `taken_charmander`, `rival_squirtle` si `taken_charmander` + `taken_squirtle`, `rival_bulbasaur` si `taken_squirtle` + `taken_bulbasaur` (trois entrées de `data/npcs/route_22.json` sur la même case, une seule présente ; trois étapes `despawn` conditionnelles). Aucun code. Sprite = **le provisoire du labo** (Q-13). La vraie partie de Kevin a bien les deux drapeaux (`taken_charmander`, `taken_squirtle`). Une partie sans ces drapeaux (aucune connue) : pas de Pokémon du rival, la scène se joue sans erreur.
3. **Mise en scène** (Q-13 et storyboard, défauts règle 4) : rival (6, 13) → son Pokémon (7, 13) → Rattata (8, 13) ← jeune Dresseur (9, 13), présents dès l'arrivée sur la carte (`if: pokedex_activated`, `unless: rival_route22_won / _lost`), visibles depuis l'escalier. Déclencheur `RivalVista` : cases (14, 12) et (14, 13), **pas vers l'ouest** (le premier pas sur le sentier en haut de l'escalier ; seul accès au point de vue, testé). Déroulé : 0,6 s → « Sérieusement… ? » → le Rattata rappelé (fondu) → **le rival rappelle aussi le sien** (storyboard, case 2) → « Tu hésites trop. » → le rival se tourne vers le joueur → le jeune Dresseur s'écarte d'un pas → le rival vient devant le joueur → 4 répliques → combat `rival_route22` sans Pokémon du décor (`win` / `lose`). Victoire : 0,6 s, 4 répliques, le rival descend l'escalier vers l'est (24, 18) et s'efface, puis le jeune Dresseur (regard vers le joueur, même chemin, s'efface). Défaite : 3 répliques, **« (il rappelle son Pokémon) » = silence de 0,8 s avant la dernière** (son Pokémon est déjà rentré à la fin du combat), puis `wake_up` (on ne le voit pas partir ; le jeune Dresseur non plus, il n'est plus là au retour).
4. **Argent et moment** : rien à brancher (versement par `BattleDirector` au T24 ; moment « Combat contre le rival » par `Boot._on_battle_finished` pour tout dresseur à `team_by_starter`, victoire comme défaite, map `route_22`).
5. **Carte** : `tools/build_route_22.gd` gagne `TRIGGERS` (`RivalVista`) et le spawn `stair_foot` (16, 16) ; scène régénérée : seules ces deux positions changent (le reste du diff = renumérotation des ressources par l'outil).
6. **Départs** : `route_22` (Salamèche N8 + Roucool N7, Pokédex activé, entrée de la Route 22) et `rival_2_weak` (Salamèche N4 seul, au pied de l'escalier) ; tous deux portent `taken_charmander` + `taken_squirtle` (rival à Carapuce).
7. **Correctif de test** : `test_cutscene_data.test_static_simulation_of_every_variant` ne simulait plus que les scènes jouées par le code (boucle indentée sous `if CODE_PLAYED.has(id)` depuis une fusion) ; elle simule de nouveau toutes les scènes, les deux issues pour toute scène à combat, les trois paires `taken_*` pour le rival n° 2, et s'arrête à `wake_up`.
