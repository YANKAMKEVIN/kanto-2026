# Chantier OUV — l'ouverture : plan technique

Conception : `docs/design/dossier-13-ouverture.md` (**validé par Kevin le 2026-10-10** : option A, rival petit-fils de Chen, noms Red · Sacha · Kevin / Régis · Blue · Gary, prénom de 1 à 10 caractères, textes du §6 version « petit-fils »).

Découpage (dossier 13 §10) : **OUV.0** logique pure sur fichiers neufs (fait, avant la fusion du J10) → **OUV.1** démarrage et sauvegarde (validé seul sur S24 : il touche la sauvegarde) → **OUV.2** introduction de Chen → **OUV.3** transitions. OUV.1 à OUV.3 commencent **après la fusion du J10 dans `main`** (`boot.gd`, `game_state.gd`, cinématiques et écran Dresseur sont partagés).

---

## 1. OUV.0 — logique pure (fait, branche `ouv-logique`)

Uniquement des fichiers neufs ; aucun fichier existant de `game/`, `data/` ou `tests/` n'est modifié. Rien n'est encore branché : le jeu se comporte exactement comme avant.

### 1.1 Données (`data/opening/`)
| Fichier | Contenu |
|---|---|
| `names.json` | `max_length` 10 ; joueur : défaut « Kevin » (= `GameState.DEFAULT_PLAYER_NAME`, testé), pastilles Red · Sacha · Kevin ; rival : défaut « Régis », pastilles Régis · Blue · Gary |
| `title.json` | libellés Continuer / Nouvelle partie / Paramètres ; messages « corrupt », « newer » (§5.2, mot pour mot) et « unsaved » (défaut, voir §4) ; carte de confirmation du §5.4 |
| `oak_intro.json` | 31 étapes : 16 textes du §6 exacts (dont 2 questions de prénom et 2 confirmations), 15 mouvements de scène ; « speaker » « Prof. Chen », « yes » / « no » |

### 1.2 Classes (`game/systems/opening/`, toutes `RefCounted`, sans scène)
| Classe | Rôle |
|---|---|
| `NameRules` | `normalize` (bords, espaces internes réduites, blancs Unicode → espace, `'` → `’`, première lettre en majuscule, rien d'autre) ; `validate(raw, max_length)` → `OK` / `EMPTY` / `TOO_LONG` / `INVALID_CHAR` ; `filter_input` (frappe et collage : refusés retirés, tronqué, espace finale gardée) ; `has_invalid_chars` (aide « Lettres, espaces, - et ’ seulement », constante `INVALID_CHAR_HELP`) |
| `OpeningNames` | charge et valide `names.json` (tout ou rien) : `max_length()`, `default_name(role)`, `suggestions(role)` |
| `OpeningFlow` | machine d'états `TITLE ⇄ SETTINGS`, `TITLE → CONFIRM_OVERWRITE → INTRO → COMMIT → DONE`, `TITLE → CONTINUE` ; entrées `SaveStatus` (NONE, VALID, CORRUPT, NEWER ; `status_from_read(SaveSystem.last_status)`) et `Action` ; sorties `screen()` et `take_effects()` (`BACKUP_PREVIOUS`, `WRITE_NEW_GAME`, `ENTER_BEDROOM`, `RESUME_SAVE`, `WARN_UNSAVED`) ; `autosave_allowed()` faux sauf en CONTINUE et en DONE après écriture réussie |
| `OpeningCommit` | protocole du §3.7 : copie atomique `save.json` → `save.previous.json` (`.tmp` → relecture → renommage), construction par un `Callable`, écriture par `SaveSystem.write` (API existante, aucun contournement nécessaire : `SaveSystem.new(fs, chemin)` suffisait) ; `SaveFileSystem` injectable |
| `SaveSummary` | résumé lu dans le dictionnaire de `SaveSystem.read()` (clés réelles de `GameState.to_dict()` : `player_name`, `map`, `play_time`, `flags`, `pokedex.entries.*.caught`) ; nom de zone par `Callable` injecté (`ZoneLibrary.zone_name_of`) ; badges = drapeaux levés parmi ceux de `BadgeLibrary` ; textes par `MenuFormat` / `DashboardViews` (mêmes formats que le Menu Dresseur) |
| `TitleTexts` + `TitleMenuModel` | entrées, entrée mise en avant, message d'état, carte de confirmation selon le statut (tableau du §5.2) |
| `IntroScript` + `IntroStep` + `IntroReader` | script typé (`stage` / `page` / `prompt` / `confirm`), validation stricte ; jetons `{player}` / `{rival}` résolus par `IntroScript.resolve` (`DialogueTokens` n'est pas touché, seulement réutilisé pour l'analyse des accolades) ; curseur pur : `advance`, `answer_prompt`, `answer_confirm` (Non → prompt prérempli), `portraits_on_stage()` pour reconstruire la scène à la même page |

`OpeningJson` : lecture commune des trois fichiers.

### 1.3 Tests (`tests/unit/opening/`, + `tests/helpers/crashing_file_system.gd`)
`test_name_rules` (26), `test_opening_names` (15), `test_opening_flow` (22), `test_title_menu_model` (15), `test_intro_script` (33), `test_opening_commit` (16) : **127 tests**. Le système de fichiers « qui meurt » (`crashing_file_system.gd`) coupe le commit après chaque opération d'écriture (la dernière écriture est déchirée) : sur le disque, toujours l'ancienne partie octet pour octet ou la nouvelle complète, et `save.json` reste lisible. Parcours complets avec `OpeningFlow` : abandon = journal d'écriture vide, relancement = nouvelle confirmation, seconde introduction réussie, sauvegarde corrompue jamais détruite, sauvegarde plus récente jamais touchée.

---

## 2. Sauvegarde v5 (à faire en OUV.1, dans `game_state.gd` et `save_system.gd`)

Rien n'est ajouté à `GameState` sur `ouv-logique` (fichier du J10). À ajouter :
- `GameState.rival_name: String` (défaut `DEFAULT_RIVAL_NAME = "Régis"`, test : égal à `OpeningNames.default_name(&"rival")`, comme le joueur) ;
- `GameState.player_look: StringName` (défaut `&"hero"` ; une valeur inconnue chargée retombe sur `&"hero"` sans erreur, testé) ;
- `to_dict` / `load_dict` : clés `"rival_name"`, `"player_look"` ; un `rival_name` vide ou invalide (`NameRules`) retombe sur le défaut ;
- `SaveSystem.VERSION = 5`, cas `4 → 5` dans `upgrade()` (rien à transformer : les défauts suffisent ; le numéro protège d'une build v4 qui effacerait les champs) ;
- **fixture v4 réelle** de la partie de Kevin (relevée sur le S24 avant la mise à jour) : `tests/fixtures/save/v4_kevin_*.json`, reprise avec « Kevin », « Régis », `hero`.

## 3. Tâches restantes (après la fusion du J10)

### OUV.1 — Démarrage et sauvegarde (architecte + ui-mobile, puis qa-mobile ; **validé seul sur S24**)
1. **Sauvegarde v5** (§2 ci-dessus) + fixture v4.
2. **`OpeningDirector`** (`game/ui/opening/opening_director.gd`, nœud créé par Boot) : tient `OpeningFlow`, `TitleMenuModel`, exécute les effets (`OpeningCommit.run` avec un constructeur qui fait `GameState.new_game()`, applique prénom et rival, place le joueur dans `player_house_2f` / `start` face au sud, puis `to_dict()`), signale `resumed` / `new_game_entered`.
3. **Boot** : dans `_start_game_state()`, départ de débogage → inchangé ; Boot hors scène courante → inchangé ; sinon l'ouverture. **Tout autosave de Boot passe par une seule garde** `_opening == null or _opening.autosave_allowed()` (entrée de carte, fin de cinématique / combat / capture, soin, arrière-plan).
4. **`title_screen.tscn`** (ui-mobile) : affiche `TitleMenuModel` ; fond Bourg Palette en **mode décor** (ni `map_entered`, ni carte découverte, ni autosave ; libéré avant le commit ou Continuer) ; carte de confirmation (choix à deux cartes existant) ; colonne à gauche en mode gaucher.
5. **`SettingsScreen` découplé** de `TrainerMenu`, hébergé par le titre sans « Sauvegarder maintenant ».
6. **Splash** (`boot_splash/*`) avec le logo Kanto 2026 (asset bloquant, Kevin / Codex).
7. Provisoirement, Nouvelle partie → commit avec les noms par défaut → chambre (l'introduction arrive en OUV.2).
8. `test_boot.gd` : tests du départ reformulés (« sans ouverture, Boot démarre dans la chambre ») ; nouveaux tests de Boot **en scène courante** avec `memory_file_system` (sans sauvegarde, valide, corrompue, plus récente) et départ de débogage qui saute le titre.

**Fait et validé par Kevin (2026-10-10, QA sur S21, branche `ouv1-demarrage`)** — tâches 1 à 8 ; fixture v4 = vraie sauvegarde du S21. Écarts : `OpeningDirector` dans `game/systems/opening/` (pas `game/ui/opening/` : le test de l'UI interdit à `game/ui` la sauvegarde et les données ; même rangement que `MenuDirector`), décor du titre `TitleBackdrop` dans `game/world/` ; fixture v4 **dérivée** de la partie S24 du J8 (aucun téléphone branché), `tests/fixtures/save/v4_kevin_depuis_s24_j8.json` (`tools/make_save_fixture_v4.gd`), à remplacer par la vraie à la validation. Splash et logo détouré : `tools/art/detourer_logo.py` → `assets/ui/opening/`. Captures : `tools/capture_title_ouv1.gd` → `build/captures/ouv1/`. Détail et défauts : `etat-projet.md` (section OUV.1).

**Validation S24 (session seule)** :
1. **Avant d'installer** l'APK : relever la vraie sauvegarde (`adb -s <série> exec-out run-as dev.kevin.kanto2026 cat files/save.json > build/qa/ouv1/save_v4_kevin.json`), la garder comme fixture v4 ; vérifier qu'aucun `files/debug_start.json` n'est présent (sinon le titre est sauté).
2. Lancer : splash (logo), puis titre ; Continuer = prénom, lieu, temps, badges (1 après le J10), captures. Journal : `Ouverture : titre (sauvegarde VALID)` et **aucune** ligne « Sauvegarde automatique » tant que le titre est là (mettre en arrière-plan et revenir : toujours rien).
3. Paramètres depuis le titre : pas de « Sauvegarder maintenant » ; Mode gaucher → colonne à gauche ; ‹ et Retour Android ramènent au titre ; Retour au titre ne quitte pas.
4. Continuer : la partie reprend au bon endroit ; journal `[qa] sauvegarde v4 → v5` puis un autosave ; `cat files/save.json` contient `"version": 5`, `"rival_name": "Régis"`, `"player_look": "hero"`.
5. Relancer, Nouvelle partie → confirmation (prénom · temps · badge) ; Annuler, puis Nouvelle partie → **tuer l'application** sur la confirmation (`adb shell am force-stop dev.kevin.kanto2026`) → relancer : Continuer présent, `save.json` identique (comparer avec le relevé), pas de `save.previous.json`.
6. Nouvelle partie confirmée → chambre, face au sud, sans titre de zone ni dialogue ; `run-as … ls files` montre `save.previous.json` = l'ancienne partie (comparer octet pour octet), `save.json` = nouvelle partie dans `player_house_2f`.
7. Remettre la vraie partie si Kevin le souhaite : `save.previous.json` → `save.json` (par adb, application arrêtée).

**Critères d'acceptation** : `tools/test.sh` vert, import propre ; captures du titre dans les quatre états ; sur S24 : la vraie partie de Kevin reprend par Continuer (prénom, lieu, temps, badges sur la carte) ; Nouvelle partie confirmée arrive dans la chambre et `save.previous.json` contient l'ancienne partie (adb) ; application tuée sur la confirmation ou avant la chambre → au relancement, l'ancienne partie est intacte ; aucun autosave tant que le titre est affiché (journal adb).

### OUV.2 — Introduction de Chen (ui-mobile + constructeur-monde pour les portraits ; validation S24)
1. `intro_stage.tscn` (CanvasLayer au-dessus du monde) : fond doré, trois emplacements, portraits peints (Chen et rival : **assets bloquants**), Nidorino (artwork 033) avec l'éclair de Poké Ball procédural ; texte par la `DialogueBox` existante ; lit `IntroReader` (`current`, `text`, `portraits_on_stage`).
2. `name_entry.tscn` : `LineEdit` natif (`max_length` de `OpeningNames`, `text_changed` → `NameRules.filter_input`, aide si `has_invalid_chars`), compteur « 4 / 10 », trois pastilles, **Valider** actif seulement si `NameRules.validate` = `OK` ; Oui / Non par le choix à deux cartes ; Retour Android : ferme le clavier, puis rien.
3. Prénom et rival appliqués au commit (constructeur de l'`OpeningDirector`).
4. Jetons `{player}` / `{rival}` dans `DialogueTokens.KNOWN`, **résolus aussi dans `speaker`** ; les 19 `"speaker": "Rival"` et les 2 « Le Rival » de `data/trainers/rival.json` → `{rival}` (liste fermée du §3.5) ; test qui interdit le littéral ; `battle_text.gd` coordonné avec CB.

**Fait (2026-10-11, branche `ouv2-introduction`, en attente de la QA S21)** — tâches 1 à 4 :
- **Portraits** : `chen_portrait.png` (364 × 768) et `rival_portrait.png` (360 × 768) par `tools/art/preparer.py --images-seulement` (entrées `heros_images` de `manifeste.json`, comme `heros_portrait`) ; les sources validées avaient **déjà un fond transparent** (aucun halo sombre à détourer, vérifié sur fond doré et sur capture).
- **Scène** `game/ui/opening/intro_stage.tscn` (`IntroStage`, vue pure, calque LAYER_MENU) : fond = **vraie carte `oak_lab` en mode décor** (`TitleBackdrop`, zoom 1,6 pour remplir l'écran, lumière de jeu `interior_warm`), **très floutée** par le shader du Menu Dresseur, plus une lumière dorée procédurale (dégradé radial) et un voile chaud au sol ; « Économie » : voile sans flou. Trois emplacements, pieds juste au-dessus de la boîte de dialogue ; entrée en fondu + montée, glissement, sortie ; éclair de Poké Ball procédural (éclair + 8 étincelles) puis Nidorino (artwork 033) qui respire. « Réduire les animations » : durées × 0,5, ni montée, ni glissement (fondu sur place), ni respiration, ni étincelles ; fondus d'entrée/sortie × 0,5.
- **Lecteur** `game/systems/opening/intro_player.gd` (`IntroPlayer`) : relie `IntroReader` à la scène, à la `DialogueBox` du jeu (texte à la vitesse des Paramètres) et à l'écran de prénom ; mouvements de scène consécutifs joués ensemble ; choix Oui / Non par le choix à deux cartes de la boîte.
- **Écran de prénom** `name_entry.tscn` (`NameEntry`) : panneau en haut à droite, **entier dans la moitié haute** (testé), `LineEdit` natif (`virtual_keyboard_enabled`, `max_length` 10, focus à l'ouverture), filtre en direct `NameRules.filter_input`, aide seulement après un caractère refusé, compteur, trois pastilles, VALIDER (libellé `validate` ajouté à `oak_intro.json`) actif seulement sur `OK` ; Entrée du clavier = VALIDER ; Retour Android : clavier fermé, puis rien.
- **Commit** : `OpeningDirector` joue l'introduction après le titre (signaux `intro_opened` / `intro_closed`), puis à la fin de la dernière réplique : commit **avec les prénoms choisis** → rideau → chambre (fondu simple, OUV.3 fera le blanc). Rien n'est écrit avant.
- **Jetons** : `{player}` / `{rival}` dans `DialogueTokens.KNOWN`, résolus aussi dans `speaker` (dialogue et page ; locuteur sans valeur = étiquette cachée), vérifiés au chargement ; liste fermée remplacée : **19** `"speaker": "{rival}"` (14 + 4 + 1, comptes vérifiés sur `main`, aucun ajout du J10) et **2** `"name": "{rival}"` ; `battle_text.gd` : **modification minimale** (`token_values` + `trainer_display_name`, signalée au chantier CB). Tests : `test_rival_name_layers` (littéraux interdits, liste fermée, couches 2 et 3 inchangées) ; tests de données → `{rival}`, tests d'affichage → nom injecté « Régis ».
- **Tests** : `test_intro_player` (textes du §6 dans l'ordre, scène de chaque plan, Non prérempli, retour, **durée simulée 41,4 s** à vitesse Normale hors saisie), `test_intro_stage`, `test_name_entry`, `test_opening_boot` (+7 : labo en mode décor, rien d'écrit, prénoms jusqu'à la chambre / au prologue / au combat, Non, retour, **abandon à chacun des 8 plans** = ancienne partie octet pour octet, seconde introduction), `test_opening_director`. Captures : `tools/capture_intro_ouv2.gd` → `build/captures/ouv2/`.
- **Après la QA S21 (2026-10-11)** : écran de prénom sur son propre calque au-dessus de la boîte de dialogue (`LAYER_NAME_ENTRY` = 31 ; le `Root` plein écran de la boîte prenait tous les touchers), test par vrais événements d'entrée ; question de Chen en titre du panneau (décision de Kevin) ; aide effacée après 3 s.
- **Écarts** : `IntroPlayer` dans `game/systems/opening/` (pas dans la scène : le test de l'UI interdit `DialogueSession` à `game/ui`) ; pas d'expression « embarrassée » de Chen (un seul portrait) ; la question reste dans la boîte **et** titre le panneau (décision de Kevin après la QA S21).

**Critères d'acceptation** : tests verts ; captures de chaque plan (Chen, Nidorino, prénom avec clavier simulé, rival) ; sur S24 : introduction complète en ≤ 90 s hors saisie (estimation actuelle : ≈ 49 s de lecture à vitesse Normale, ≈ 62 s en Lente), clavier qui ne masque pas le champ, Non qui rouvre le champ prérempli, prénoms vus ensuite dans le prologue (Maman, rival au labo, combat).

### OUV.3 — Transitions (ui-mobile ; validation S24)
1. Portrait du joueur qui rétrécit et se dissout → fondu au blanc chaud ≈ 0,8 s → chambre, contrôle rendu à la fin du fondu, aucun titre de zone.
2. Légende « BOURG PALETTE / Le commencement de toute aventure » à la toute première sortie (déduite de `discovered_maps`, aucune donnée de sauvegarde).
3. Réduction des animations : fondus raccourcis, pas de dérive du titre ni de montée des portraits.

**Critères d'acceptation** : parcours complet sur S24 du lancement à la descente vers Maman ; test du « premier passage » de la légende ; capture avec réduction des animations.

**Fait (2026-10-11, branche `ouv3-transitions`, en attente de la QA S21)** — tâches 1 à 3 :
- **Fin de l'introduction** : `OpeningDirector._on_intro_finished` garde l'ordre d'OUV.2 — **commit d'abord** (synchrone, avant toute animation), puis `_send_off()` : `IntroStage.send_off()` (le portrait du joueur rétrécit vers son centre en blanchissant et s'efface, un halo chaud grandit à sa place, 0,7 s), le **fondu au blanc chaud** part au milieu du rétrécissement (0,8 s), introduction retirée, `new_game_entered`. Boot bloque le joueur (raison `opening_arrival`) **avant** de poser la chambre, garde le HUD caché, lève le rideau depuis le blanc (0,8 s, `OpeningDirector.entry_fade_time()`) et ne rend joueur et contrôles **qu'à la fin du fondu** ; la première autosave suit (partie stable). Aucun titre de zone, aucun texte. `ScreenFade.fade_out(durée, couleur)` : la teinte est posée au départ (noir par défaut : les portes repartent du noir), `fade_in` / `set_opaque` la gardent.
- **Sécurité** : rien n'est écrit pendant l'animation ; un abandon pendant la fermeture de la boîte (avant le commit) laisse l'ancienne partie intacte, pendant le rétrécissement, le blanc ou le fondu vers la chambre la nouvelle partie complète dans la chambre (+ `save.previous.json`) — testé à chacun de ces moments.
- **Légende** : `FirstExitCaption` (`game/systems/opening/`, pure) + `data/opening/first_exit.json` (`map` pallet_town, `from` player_house_1f, `subtitle`). Boot note la carte quittée à `transition_started` et calcule le sous-titre **avant** `discover_map` : légende seulement à une arrivée **par une porte** depuis le rez-de-chaussée sur un Bourg Palette jamais découvert. Jamais au démarrage, en reprise (Continuer) ni à un départ de débogage (aucune carte quittée, ou arrivée par la Route 1).
- **Réduction des animations** : tous les fondus de l'ouverture (titre, introduction, blanc, chambre, entrée après Continuer) × 0,5 (`OpeningDirector.fade_time`), pas de rétrécissement (fondu au blanc direct) ; dérive du titre et montée des portraits : déjà coupées (OUV.1, OUV.2), maintenant testées.
- **Tests** : `test_first_exit_caption` (7), `test_opening_boot` (+10 : ordre commit → rétrécissement → blanc → chambre → contrôle au pas près, abandon à 5 moments, version réduite, dérive, fondus raccourcis, légende : nouvelle partie / seconde arrivée / seconde sortie / Continuer / partie connaissant Bourg Palette / reprise sur un Bourg Palette non découvert / départ de débogage), `test_intro_stage` (+2), `test_opening_director` (+1, durées au pas près), `test_screen_fade` (+1), `test_opening_walk` (légende à la première sortie). Captures : `tools/capture_transitions_ouv3.gd` → `build/captures/ouv3/`.

## 4. Petites valeurs par défaut (règle 4)

- **Prénom sans aucune lettre** (« - », « ’ ») : `EMPTY` (Valider inactif, sans message d'aide) ; un caractère refusé passe avant (« 🔥 » → `INVALID_CHAR`, l'aide s'affiche).
- **Lettres** = toutes les écritures Unicode (catégories des débuts d'identifiant, sans « _ ») ; diacritique combinant permis après une lettre (il compte pour un caractère : « é » décomposé fait 2).
- **Saisie en direct** : la casse n'est pas touchée (le clavier du téléphone met la majuscule) ; la normalisation se fait à la validation.
- **Échec d'écriture au commit** (disque plein) : on entre quand même dans la chambre, **sans autosave pour la session** (comme une sauvegarde plus récente), et le message « La partie n'a pas pu être enregistrée. Elle continue sans sauvegarde. » (texte par défaut, à relire par Kevin). Si la copie de sécurité échoue, rien n'est écrit.
- **Copie de sécurité** faite dès que `save.json` existe (filet le plus large), même si le flux ne la demande pas.
- **Captures sur la carte Continuer** : affichées seulement si le Pokédex est activé (comme le tableau de bord) ; « 0 badge » jamais affiché.
- **Scène** (données de `oak_intro.json`) : pendant la saisie, le portrait nommé est à gauche (§5.5) ; avant la question du rival, Chen sort ; la dernière page est dite avec le joueur seul au centre.
- **Estimation de durée** (test) : défilement à la vitesse du réglage + 1,5 s de lecture par texte + 0,5 s par mouvement de scène, prénoms de 10 caractères.

## 5. Questions ouvertes pour Kevin
- Texte « unsaved » (échec d'écriture du commit) : à valider avec le lot de textes d'OUV.1.
