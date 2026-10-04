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
| Objectif du tableau de bord | `ObjectiveLibrary` + `data/story/objectives.json` (« rejoindre Jadielle » si `rival_battle_done`) | l'objectif du colis ; couper « rejoindre Jadielle » à l'arrivée |
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

### 3.4 Boutique et économie (T10)

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

### 3.5 Stockage (T14)

```gdscript
class_name StorageRules
extends RefCounted
## Règles métier du Stockage Pokémon V1 (dossier 09 §8, §19), indépendantes de l'écran.
enum Place { PARTY, STORAGE }
enum Status { OK, LAST_POKEMON, PARTY_FULL, FAVORITE, NOT_FOUND }
static func can_deposit(party: Party, index: int) -> Status
static func deposit(party: Party, storage: PokemonStorage, index: int) -> Status
static func can_withdraw(party: Party, storage: PokemonStorage, index: int) -> Status
static func withdraw(party: Party, storage: PokemonStorage, index: int) -> Status
static func can_release(party: Party, place: Place, index: int, pokemon: Pokemon) -> Status
static func release(party: Party, storage: PokemonStorage, place: Place, index: int) -> Status
```

`LAST_POKEMON` : l'équipe garderait 0 Pokémon **en état de combattre** (Q-7 ; « Tu dois garder au moins un Pokémon avec toi. »). `FAVORITE` : « Retire d'abord {Pokémon} de tes favoris pour pouvoir le libérer. », **sans contournement**. `Party.remove_at(index) -> Pokemon`, `PokemonStorage.remove_at`, `get_at`. Libérer ne touche pas au Pokédex ni à la statistique « Captures » (carrière, T25 du J6). `StorageViews.build(state, data, selection) -> StorageView` (équipe, stockage dans l'ordre d'arrivée, Pokémon sélectionné, actions avec leur raison). `MenuRoute.STORAGE` ; `MenuUnlocks.storage_available(map)` : vrai si `map` est la carte `found_on` d'un service `pokemon_center` (`zones.json`) — **aucun Stockage hors d'un Centre**.

**Tests (T14)** : `test_storage_rules` (déposer le dernier, le dernier valide, reprendre équipe pleine, libérer un favori, libérer le dernier, libérer depuis le stockage, l'instance déplacée garde PV, PP, favori et histoire), `test_storage_views`, `test_menu_unlocks` (Stockage seulement au Centre), `test_party` / `test_pokemon_storage` étendus.

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

### 3.7 Route 22 : données (T21)

- `data/pokemon/species/kanto.json` : **10 espèces** (Piafabec, Rapasdepic, Férosinge, Colossinge, Nidoran ♀, Nidorina, Nidoqueen, Nidoran ♂, Nidorino, Nidoking), statistiques, types, apprentissages et évolutions de Rouge/Bleu (les évolutions doivent exister pour la validation des chaînes, même invisibles au J7).
- `data/pokemon/moves/moves.json` : les capacités nouvelles de ces apprentissages ; une mécanique que le moteur n'a pas (poison, coups multiples, peur, taux de critique élevé) va dans `pending_effects` (précédent : Poudre Toxik) — la capacité frappe une fois, sans l'effet, jusqu'au J11.
- `data/pokedex/kanto.json` : taille et poids officiels des 10 ; **descriptions `draft` pour les 4 espèces rencontrables** (les 6 évolutions ne peuvent être ni vues ni capturées au J7).
- `data/encounters/route_22.json` : Rattata, Piafabec, Férosinge, Nidoran ♀ et ♂, niveaux et taux de **Rouge/Bleu** (les deux versions réunies pour les deux Nidoran), relevés sur une source fiable par la tâche et cités dans le commit ; même rampe que la Route 1.
- Sprites de combat (face, dos) des 4 espèces rencontrables : style selon **Q-2**.

**Tests (T21)** : `test_pokemon_data` (10 espèces valides, chaînes d'évolution), `test_encounter_library` (table de la Route 22), `test_pokedex_library` (références), simulation `tools/simulate_grass_pacing.gd` relancée sur la Route 22 (rythme comparable à la Route 1).

### 3.8 Rival n° 2 : IA de niveau 2 et gains (T24)

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

`viridian` (arrivée au bord sud de Jadielle, équipe Nv. 7–8 réaliste, `rival_battle_done`) · `center_qa` (équipe blessée et un K.O., devant le Centre) · `shop_qa` (6 000 ₽, des Potions favorites, devant la Boutique) · `storage_qa` (6 en équipe dont un K.O., 10 au stockage dont un favori, au Centre) · `parcel` (colis en main, devant le labo) · `route_22` (Pokédex activé, équipe Nv. 8, entrée de la Route 22) · `rival_2_weak` (équipe Nv. 4, pour perdre). `DebugStart` gagne `money` et `storage` (même format que `party`).

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

---

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

#### T3 — constructeur-monde : le pipeline de l'art et la lumière C2
- `tools/art/manifeste.json` + `tools/art/preparer.py` (successeur de `preparer_proto.py` : sorties dans `assets/`, ombres et contacts pré-floutés, moitié basse des herbes hautes) ; import des textures des séries 01 à 05 (depuis `proto/da-jadielle:proto/da_jadielle/tex/`, renommées) ; `tools/build_painted_props.gd` (scènes `WorldProp` peintes, emprises du §6.6) ; `tools/build_character_frames.gd` (PNJ du J7) ; `WorldLighting` et les 5 shaders ; `CharacterLook` branché dans `Npc` et `Player` ; `PerfCounter` + mémoire des textures ; une **scène de test** (`tools/capture_lighting.gd`) qui pose la place de la série 01 avec la vraie chaîne.
- **Peut commencer pendant T0 / T1** (aucun fichier partagé avec la sauvegarde).
- **CA** : `test_painted_props`, `test_world_lighting` (profil appliqué, profil vide = calque caché, ombres orientées), `test_character_look` (un PNJ peint à l'échelle 1 en LINEAR, un provisoire ×2 en NEAREST) ; captures côte à côte **prototype C2 / production** de la place (écart visuel nul attendu, sinon expliqué) ; comparaison VRAM compressée / sans perte ; mesure Mac.

#### T4 — constructeur-monde : la carte de Jadielle
- `tools/build_viridian_city.gd` → `viridian_city.tscn` (plan du prototype 40 × 28 comme base, Q-5 ; `light_profile = golden_hour`) : place, Centre, Boutique, Arène fermée (porte : « La porte est verrouillée. »), maisons, haies, clôtures, sortie nord `coming_soon = "Route 2"`, départ de la Route 22 à l'ouest (bord bloqué jusqu'au 7B.1), arrivée progressive depuis la Route 1 au sud ; `route_1` : les destinations « Jadielle » deviennent de vrais passages (`tools/build_route_1.gd` régénéré) ; habitants et répliques du §19 (livreur qui entre à la Boutique, Dresseuse + Roucool animé, enfant + Rattata qui le suit, voyageur du nord, habitant de l'Arène, vieil homme et sa seconde réplique) ; Roucool sur le toit ; micro-scène d'arrivée (`data/cutscenes/viridian_city.json`, déclencheur 2 cases après l'entrée, `unless: viridian_arrived`, pose `viridian_arrived`) ; zones et services.
- **CA** : `test_viridian_city` (warps vers des cartes et spawns existants dans les deux sens, aucun PNJ sur une case solide, toutes les routines possibles, chemin entre les trois entrées, la porte de l'Arène répond) ; `test_arrival_scene` (vrai `Boot`, départ `viridian` : la scène se joue une seule fois, **≤ 4 s** de bout en bout, aucun dialogue, contrôles rendus, Roucool absent jusqu'au changement de carte, « rejoindre Jadielle » disparaît) ; `test_menu_map` étendu (Jadielle découverte, Arène dans ses services) ; captures `viridian_arrival`, `viridian_square`, `viridian_gym`, `viridian_north_exit`, lues avec Read.

#### T5 — qa-mobile : validation du 7A.1
- **CA** : arrivée depuis la Route 1 sur la **vraie partie** (micro-scène une fois, titre, contrôle rendu) ; tour complet de la ville sans traverser d'objet ni rester bloqué ; habitants vivants ; Arène ; « ROUTE 2 — À venir » ; menu ouvert sur Jadielle (Carte : Jadielle et l'Arène) ; **fps et mémoire** (§7) sur 10 minutes ; journal propre. Capture S24 à côté de la capture du prototype.

### 7A.2 — Centre Pokémon

#### T6 — architecte-godot : fondations du Centre
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

#### T10 — architecte-godot : fondations de la Boutique
- §3.4 ; contrat de `ShopScreen` ; objectif du colis.
- **CA** : tests du §3.4 verts.

#### T11 — ui-mobile : l'écran Boutique et l'argent affiché
- `ShopScreen` (§6.4, langage du Sac) ; argent dans l'écran Dresseur et le Sac (`money_text`) ; confirmation de vente d'un favori par `ChoiceCards` ; scénarios `shop_buy`, `shop_sell`, `shop_no_money`, `trainer_money`.
- **CA** : `test_shop_screen` (onglets, quantité bornée par `max_quantity`, total à chaque cran, CONFIRMER → **un** signal, refus visibles, retour ; **glisser la liste n'achète rien** : `TapGuard`, `touch_finger.gd`) ; `UiPrefsApplier` appliqué ; captures relues.

#### T12 — constructeur-monde : la Boutique jouable
- Carte `viridian_mart` (paillasson bleu, rayons sans étiquette), marchand, scène de première visite (§6.4), `open_shop`, routes `SHOP` dans `MenuDirector`, `mark_changed` et autosave.
- **CA** : `test_mart` (vrai `Boot`, départ `shop_qa` : première visite → colis, toast, objectif ; visites suivantes → Boutique ; achat → argent et Sac ; argent insuffisant ; vente d'une Potion favorite après confirmation ; colis absent de VENDRE ; sauvegarde relue) ; `test_menu_unlock_rule` étendu.

#### T13 — qa-mobile : validation du 7A.3
- **CA** : achat de Poké Balls et de Potions au doigt, vente, refus, objectif dans le menu, argent dans l'écran Dresseur et le Sac (et nulle part ailleurs).

### 7A.4 — Stockage Pokémon

#### T14 — architecte-godot : fondations du Stockage
- §3.5 ; contrat de `StorageScreen` et du bouton STOCKAGE de l'Équipe.
- **CA** : tests du §3.5 verts.

#### T15 — ui-mobile : l'écran Stockage
- §6.4 ; scénarios `storage`, `storage_drag`, `storage_release`, `storage_refusal`.
- **CA** : `test_storage_screen` (glisser = un signal, sélection + bouton = le même, refus = tremblement + raison, LIBÉRER seulement dans le menu secondaire, confirmation, favori sans contournement ; défiler la grille ne sélectionne rien : `TapGuard`) ; `UiPrefsApplier` appliqué ; captures relues.

#### T16 — constructeur-monde : le Stockage jouable
- Terminal (`open_storage`), bouton STOCKAGE de l'Équipe (au Centre seulement), câblage, autosave.
- **CA** : `test_menu_storage` (vrai `Boot`, départ `storage_qa` : déposer, reprendre, libérer avec confirmation, dernier Pokémon refusé, favori protégé, rien hors du Centre, sauvegarde relue, le combat suivant envoie le bon premier).

#### T17 — qa-mobile : validation du 7A.4
- **CA** : glisser au pouce (une dizaine d'essais), alternative par boutons, refus lisibles, libération confirmée, sauvegarde après relance.

### 7A.5 — Le Pokédex de Chen

#### T18 — architecte-godot : fondations de la scène de Chen
- §3.6.
- **CA** : tests du §3.6 verts.

#### T19 — constructeur-monde : la remise du colis et l'activation
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

#### T25 — constructeur-monde : la scène du rival
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
- **Q-7 — « Dernier Pokémon »** : le dossier dit « le dernier Pokémon de l'équipe ». Si l'équipe compte un Pokémon valide et un K.O., déposer le valide laisserait une équipe incapable de combattre. *Défaut : on compte les Pokémon **en état de combattre** ; même message « Tu dois garder au moins un Pokémon avec toi. ».*
- **Q-8 — L'argent avant la première Boutique.** *Défaut : visible dès le début dans l'écran Dresseur et le Sac (3 000 ₽ existent depuis le départ, aucun événement ne les « donne »).*
- **Q-9 — Ce que dit l'infirmière au réveil après une défaite.** *Défaut : la réplique validée « Voilà. Tout le monde est en pleine forme. » (aucun texte nouveau).*

**Chen et le Pokédex**
- **Q-10 — L'objectif après l'activation.** *Défaut : aucune ligne jusqu'au J8 (le monde s'ouvre, pas de checklist).*
- **Q-11 — Un grand moment « Pokédex » dans l'écran Dresseur ?** *Défaut : non (la liste du dossier 08 reste telle quelle).*
- **Q-12 — « Efficace / Peu efficace » en combat après l'activation** (dossier 05 §5) : *défaut : pas au J7 (J11, avec la lecture des types).*

**Route 22 et rival**
- **Q-13 — La mise en scène du rival contre le jeune Dresseur.** *Défaut : le starter du rival (sprite provisoire actuel, Q-1) face au Rattata du jeune Dresseur ; le Rattata est rappelé (fondu) ; après la scène, le jeune Dresseur repart vers Jadielle, sans réplique de plus.*
- **Q-14 — Difficulté du rival n° 2.** *Défaut : l'équipe du dossier (Roucool Nv. 7, starter avantagé Nv. 8) et l'IA de niveau 2 ; on ajuste après la simulation du T24 et ton essai au T26.*

**Textes à relire** (un seul lot, tous `draft`) : message de gain « Tu remportes {money}. » ; description du colis ; descriptions de zone de Jadielle et de la Route 22 ; « Ton équipe est déjà complète. » (REPRENDRE, équipe pleine) ; « Le stockage est vide. » ; « Vendre {objet} ? » (favori) ; les 4 descriptions du Pokédex (Piafabec, Férosinge, Nidoran ♀, Nidoran ♂) ; libellé « Argent ». Le panneau de Jadielle n'est pas examinable au J7 (aucun texte validé).

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
