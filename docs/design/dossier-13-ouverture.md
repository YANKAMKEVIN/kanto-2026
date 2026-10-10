# Dossier 13 — L'ouverture : démarrage, écran titre, introduction du Prof. Chen (chantier « OUV »)

> Commande de Kevin du 2026-10-10 (« Chantier J0 — Ouverture de Kanto 2026 »). **V0.1 de Claude** (V0 du 2026-10-10, revue intégrée le même jour) : audit de l'existant, architecture proposée, storyboard, écrans, cas limites, assets manquants et **arbitrages à trancher** (section A). **Validé par Kevin le 2026-10-10** (voir ci-dessous). **Aucune implémentation avant la validation de ce dossier et des références visuelles (§9), ni avant la fusion du J10 dans `main`** (le J10 modifie `boot.gd` et `game_state.gd`, qu'il faudra aussi modifier ici).

**Décision créative de Kevin** : on garde l'introduction emblématique du Professeur Chen de Rouge/Bleu, réalisée dans la DA 2D HD peinte de Kanto 2026. Fidèle au déroulé, sans interface rétro pixelisée et sans réécrire le prologue existant.

**Parcours cible** : splash → écran titre (Continuer · Nouvelle partie · Paramètres) → introduction de Chen → présentation du monde → apparence et prénom du joueur → présentation et prénom du rival → transition vers la chambre → prologue existant, inchangé.

## ✅ VALIDÉ PAR KEVIN le 2026-10-10
Kevin a validé **l'ensemble du dossier V0.1** : les 14 arbitrages selon les recommandations (A2 = **option A**, héros actuel, modèle prêt pour une héroïne), les textes de Chen du §6 (sans petit-fils refusé : version « petit-fils »), le storyboard et les références à produire. **Implémentation du câblage après la fusion du J10** ; le travail sur des fichiers neufs peut commencer avant (voir `etat-projet.md`).

## Revue du 2026-10-10 (ChatGPT, transmise par Kevin)
Positions **recommandées** sur les six premiers arbitrages ; rien n'est verrouillé tant que Kevin ne l'a pas confirmé :

| # | Sujet | Position recommandée |
|---|---|---|
| A1 | Nom du chantier | **OUV.1 à OUV.3** ; « J0 » reste le nom des fondations |
| A2 | Apparence | **Option A** en V1 (le héros actuel), **modèle de données prêt pour une héroïne** sans nouvelle migration (§3.4, §3.6) |
| A3 | Rival | **Petit-fils de Chen**, comme dans Rouge/Bleu |
| A4 | « ??? » sur la Route 1 | **Conservé** |
| A10 | Nouvelle partie | **Confirmation obligatoire** si une sauvegarde existe ; l'ancienne partie reste intacte jusqu'à la fin de l'introduction |
| A12 | Première sortie | **Incluse en OUV.3** (« Le commencement de toute aventure ») |

Améliorations demandées, **intégrées dans cette V0.1** :
- **Abandon pendant l'introduction** : garanties explicites et protocole d'écriture détaillé (§3.7).
- **Prénom du rival ≠ rôle du rival** : trois couches séparées, aucun identifiant technique renommé (§3.5).
- **Durée** : 60–90 s confirmées comme plafond (§4).
- **Priorité artistique** : le titre, la scène de Chen et l'écran de prénom appartiennent au même univers visuel que Bourg Palette et le laboratoire (§9.0).

Restent à examiner par Kevin : A5–A9, A11, A13, A14, les textes du §6, le storyboard du §4 et les références du §9.1.

---

## A. Arbitrages demandés à Kevin

Une recommandation est donnée pour chaque point. Les petites valeurs (durées, tailles) sont des défauts (règle 4) et ne figurent pas ici.

1. **Nom du chantier.** « J0 » est déjà pris : la roadmap appelle « Phase 1 — Fondations (J0 → J4) » le démarrage du projet, et `jalon-04.md` parle du « jalon 0 ». Les anciens plans réservent les éléments de l'ouverture à un « jalon « ouverture » » (`jalon-01.md` Q3, `jalon-02.md` §0 et §7.3, `jalon-03.md` Q13).
   *Recommandation* : appeler le chantier **OUV** (sur le modèle de CB pour le combat), découpé en OUV.1 à OUV.3, et l'inscrire dans la roadmap comme chantier transversal.
2. **Apparence du joueur.** Rouge/Bleu n'avait qu'un héros, Rouge Feu/Vert Feuille proposait garçon ou fille. Trois options :
   - **A — Fidèle à Rouge/Bleu** : un seul héros, on ne choisit que le prénom. Aucun nouvel asset de personnage.
   - **B — Héros ou héroïne** (Rouge Feu). Il faut un jeu complet de l'héroïne (marche, course, attente, lancer, portrait, buste du menu, portrait de la carte), produit sur l'ancre de style `PERSO_P2_PEINT_r1`, **et** l'accord grammatical de certaines répliques déjà écrites (§8.3).
   - **C — Héros unique, variantes de tenue** (couleurs). Coût faible, mais le dossier 08 §6 exclut « tenues et apparence » jusqu'à un jalon dédié.

   *Recommandation* : **B** si l'héroïne compte pour Kevin. Le champ et le mécanisme d'accord arrivent dès OUV.2 (« données avant interface »), mais l'écran de choix n'apparaît que lorsque l'art de l'héroïne est validé. Sinon, **A**, et l'écran d'apparence est retiré du parcours.
3. **Le rival est-il le petit-fils de Chen ?** C'est le ressort comique de l'introduction de Rouge/Bleu (« Euh… comment s'appelle-t-il déjà ? »). Les textes existants ne le contredisent pas : « Ça fait une heure que tu dis ça. » / « Et pourtant, tu es toujours là. » fonctionnent, et la sœur présente dans la maison du rival devient la petite-fille de Chen.
   *Recommandation* : **oui**, fidèle à l'original.
4. **« ??? — Hé ! Attends ! » sur la Route 1** (dossier 02 §5). Le joueur aura déjà vu Chen dans l'introduction. Dans Rouge/Bleu, la voix restait anonyme jusqu'à l'arrivée de Chen.
   *Recommandation* : **ne rien changer**. Une voix qui vient de derrière reste « ??? », et la reconnaissance devient un clin d'œil. Les répliques de Maya (« Il est sorti tôt ce matin ») restent cohérentes.
5. **Noms proposés.** Comme dans Rouge/Bleu, l'écran de prénom propose trois noms et une saisie libre.
   *Recommandation* : joueur **Red · Sacha · Kevin**, rival **Régis · Blue · Gary**. Kevin choisit les listes définitives.
6. **Saisie du prénom** : clavier du téléphone (champ texte natif) ou clavier dessiné dans le jeu ?
   *Recommandation* : **clavier du téléphone**, avec un champ et des propositions en pastilles. On est en 2026, et l'accentuation et la correction viennent gratuitement.
7. **Règles du prénom.**
   *Recommandation* :
   - 1 à **10** caractères (7 dans Rouge/Bleu ; 10 tient dans l'étiquette du dialogue et la carte Dresseur, à vérifier au rendu) ;
   - lettres accentuées, espace, trait d'union et apostrophe ; ni chiffres ni emoji ;
   - espaces retirés aux bords et première lettre mise en majuscule ;
   - champ vide impossible : « Valider » reste désactivé ;
   - aucun filtre de mots (jeu personnel) ;
   - le joueur et le rival peuvent porter le même prénom (Rouge/Bleu l'autorisait), sans avertissement.
8. **« Présentation du monde ».** Dans Rouge/Bleu, c'est le Pokémon qui sort de sa Ball à côté de Chen (Nidorino) pendant « ce monde est peuplé de créatures appelées Pokémon ».
   *Recommandation* : **Nidorino**, en artwork officiel (déjà présent : `assets/sprites/pokemon/official/033.png`, cohérent avec la décision du 2026-10-06 sur la source des Pokémon). **Pas** de diaporama du monde en plus : le dossier 02 demande « très peu de texte, pas un visual novel ».
9. **Arrière-plan de l'écran titre.**
   *Recommandation* : **le vrai Bourg Palette en direct**, sur un cadrage composé fixe avec une dérive lente de la caméra, la lumière dynamique, les PNJ et les Roucool de Mme Aoki qui vivent leur vie. « Le monde est la star », et cela ne coûte aucun asset. L'autre option serait une illustration peinte dédiée, qui demande un asset.
10. **Une nouvelle partie quand une sauvegarde existe.** Il n'y a qu'un emplacement et les sauvegardes multiples sont exclues (dossier 08 §7).
    *Recommandation* :
    - une carte de confirmation à deux choix (§5.4) ;
    - l'ancienne sauvegarde n'est **écrasée qu'à l'arrivée dans la chambre** : quitter pendant l'introduction ne perd rien ;
    - elle est copiée une fois dans `user://save.previous.json`. Ce filet est invisible dans le jeu et se récupère par adb.
11. **Pouvoir passer l'introduction.**
    *Recommandation* : **non** en V1, comme dans Rouge/Bleu. Toucher complète la ligne, la vitesse du texte des Paramètres s'applique, et l'introduction dure environ 60 à 90 s. On pourra la rendre passable plus tard, à partir de la deuxième partie.
12. **Révélation de Bourg Palette à la première sortie** (« Le commencement de toute aventure »), reportée au « jalon « ouverture » » depuis le J2.
    *Recommandation* : **l'inclure en OUV.3, mais réduite à la légende** : à la toute première sortie, le titre affiche « BOURG PALETTE / Le commencement de toute aventure » au lieu de « Kanto ». La cinématique en perspective du storyboard (case 5) n'est pas faite ici : elle demande de l'art dédié et relève de la phase DA.
13. **Nom du rival en combat.** Aujourd'hui, `data/trainers/rival.json` porte « Le Rival ».
    *Recommandation* : le prénom seul (« Régis veut se battre ! »). L'étiquette de dialogue « Rival » devient le prénom partout (§8.2).
14. **Musique.** Le projet n'a aucun son : `assets/audio/` et `game/systems/audio/` sont vides.
    *Recommandation* : **hors périmètre**. L'ouverture est conçue muette, avec des points d'accroche sonores notés au storyboard (§4) pour le futur chantier audio.

---

## 1. Audit de l'existant (2026-10-10, `main` à `402f7c8`)

### 1.1 Démarrage
- **Scène principale** : `game/boot.tscn` (`project.godot` l. 9). Elle contient tout le jeu : monde, combat, HUD, menus, `ScreenFade`, `CutsceneDirector`, `DialogueBox`. Il y a deux autoloads, `SceneRouter` et `GameState`.
- `Boot._ready()` appelle `GameState.new_game()`, charge les réglages et les bibliothèques, puis `_start_game_state()` (`boot.gd` l. 685–698) dans cet ordre :
  1. départ de débogage ;
  2. sinon, lecture de `user://save.json` puis reprise à la position sauvegardée ;
  3. sinon, la chambre (`player_house_2f`, spawn `start`, face au sud).
- **Il n'y a pas de choix Continuer / Nouvelle partie** : une sauvegarde valide est reprise d'office.
- **Splash** : celui de Godot par défaut (aucune clé `boot_splash/*`), déjà noté dans les « Reportés ».
- **Garde-fou utile** : la sauvegarde et les réglages ne sont ouverts que si `get_tree().current_scene == self`. Les tests GUT et les outils de capture instancient `Boot` sans jamais toucher les vrais fichiers.
- **Départs de débogage** : `game/systems/debug/debug_start.gd` lit `user://debug_start.json` (23 préréglages dans `tools/debug_start/`, `deploy_s24.sh --debug-start`), uniquement dans un build de débogage, avec Boot comme scène principale. `debug_unlocks.gd` suit la même règle. **La QA en dépend.**

### 1.2 État et sauvegarde
- **`GameState`** (`game/autoload/game_state.gd`) : `DEFAULT_PLAYER_NAME = "Kevin"` (l. 25) et `player_name` (l. 64, commentaire « pas encore d'écran de nom »). Si le nom chargé est vide, on retombe sur « Kevin » (l. 268–270).
- **Le rival n'a pas de nom, et il n'existe ni apparence ni genre.**
- **`SaveSystem`** (`game/systems/save/save_system.gd`) :
  - un emplacement, `user://save.json`, en JSON, **version 4** (le J10 la garde) ;
  - migrations `upgrade()` de 1 à 4 ;
  - écriture atomique (`.tmp`, relecture, renommage) ;
  - fichier corrompu mis en quarantaine dans `save.json.corrupt` ;
  - version plus récente : on joue sans écrire ;
  - entrées rejetées copiées dans `save.json.rejected` ;
  - `has_save()` existe, ainsi que `erase()`, qui n'est jamais appelé.
- **Autosave permanent** (dossier 08 §7, non désactivable) : à l'entrée dans une carte, en fin de cinématique, de combat ou de capture, au soin de Maman et au passage en arrière-plan.
- **Réglages** : `user://settings.json`, séparé de la sauvegarde (`game_settings.gd`, `SettingsScreen` intégré au Menu Dresseur). Il n'y a **aucun réglage de volume** (pas de son).

### 1.3 Textes et noms
- Les dialogues sont des données (`data/dialogues/*.json`, `dialogue_library.gd`).
- **Jetons** (`dialogue_tokens.gd`) :
  - la liste blanche ne contient que `{first_wild_species}` ;
  - un jeton inconnu provoque une erreur de chargement ;
  - un jeton sans valeur fait **omettre** la page ;
  - les jetons ne sont **pas résolus dans `speaker`**.
- **Étiquette « Rival » écrite en dur** : 19 fois (14 dans `oak_lab.json`, 4 dans `route_22.json`, 1 dans `rival_house.json`), plus « Le Rival » dans `data/trainers/rival.json`, qui s'affiche via `{trainer}` dans les messages de combat.
- **Le nom du joueur est lu depuis l'état** : tableau de bord, écran Dresseur, et dresseur d'origine des Pokémon (`stamp_meeting`).
- **Aucun champ de saisie de nom** : le seul `LineEdit` du jeu est la recherche du Pokédex.

### 1.4 Prologue (à préserver tel quel)
- Cartes : `player_house_2f` (chambre, sans déclencheur), `player_house_1f`, `pallet_town`, `rival_house`, `oak_lab`, `route_1`.
- **Première image d'une nouvelle partie** : le joueur dans la chambre, face au sud, contrôle immédiat, sans fondu, sans titre de zone ni dialogue. C'est une décision du J2 : « départ dans la chambre sans titre ». Quatre tests de `tests/integration/test_boot.gd` la vérifient, dont `test_no_title_screen` (l. 90).
- **Premier temps scénarisé** : Maman, automatiquement, au rez-de-chaussée (`player_house.json`, drapeau `mom_greeted`).
- Cinématiques : `data/cutscenes/prologue.json` (`route1_grass`), `starter.json`, `oak_lab.json`.

### 1.5 Outils réutilisables
- `ScreenFade` : `fade_out` / `fade_in` / `set_opaque`, couche de transition.
- `SceneRouter.start` / `start_at` / `change_map`.
- `DialogueRunner` + `DialogueBox.show_page(speaker, text, narration)`.
- **Choix à deux cartes** (`show_choice`, bible §4).
- `WorldCaption` (titre de zone), `Toast`, thème `ui_theme.tres` / `UiTokens`.
- `CutsceneDirector` (18 types d'étape) est **lié au monde** (carte et joueur). Il convient au passage dans la chambre, pas à un monologue sur une scène vide.

### 1.6 Personnages peints présents
- **Héros** : `player_frames.tres` (planches marche, attente et course), `heros_portrait.png` (**pied, 379 × 768**, réutilisable dans l'introduction), `heros_lancer.png` (dos, en combat), `assets/ui/menu/hero_bust.webp`, `assets/ui/map/player_portrait.png`.
- **Rival** : planches marche et attente, icône `rival.svg`. **Pas de portrait en pied.**
- **Chen** : planches marche, attente et course. **Pas de portrait en pied.**

---

## 2. Décisions validées à préserver

| Décision | Source | Conséquence pour l'ouverture |
|---|---|---|
| Les textes du prologue sont **définitifs** | dossier 02 l. 3 | aucune réplique du prologue n'est réécrite ; seuls l'étiquette « Rival » et d'éventuels accords (arbitrage 2) changent |
| Départ **dans la chambre**, sans titre de zone ni dialogue ; Maman parle à la première descente | J2, dossier 02 §1, `test_boot.gd` | l'introduction se termine **dans** cette situation exacte |
| Pas de tutoriel, pas d'« OBJECTIF MIS À JOUR », très peu de texte | dossier 02 | l'introduction tient en une quinzaine de pages ; aucune explication des commandes |
| Étiquette « **Prof. Chen** » | dossier 02 l. 176 | la même dans l'introduction |
| Boîte de dialogue **sombre translucide, sans portrait systématique** ; nom distinct du texte ; toucher = compléter / continuer ; deux choix au plus | bible UI/UX §3–4, décision 3A | l'introduction utilise **la même boîte** ; les grands portraits sont **sur la scène**, pas dans la boîte |
| UI moderne non pixel art ; personnages **peints simplifiés** | `CLAUDE.md` règle 9, vision | portraits peints ; ni police ni cadre rétro |
| **Un seul emplacement**, **autosave permanent** ; sauvegardes multiples exclues | `jalon-05.md` §16.1, dossier 08 §7 | Nouvelle partie = remplacement après confirmation, sans gestionnaire d'emplacements |
| Paramètres : cinq catégories ; « Sauvegarder maintenant » dans JEU | dossier 08 §7 | réutilisés depuis le titre, sans « Sauvegarder maintenant » |
| Nom du joueur « Kevin » par défaut | dossier 08 Q3, `jalon-05.md` §16.3 | **reste** la valeur des sauvegardes existantes et des départs de débogage |
| Données ≠ logique ≠ présentation | `CLAUDE.md` règles 7–8 | script de l'introduction et listes de noms en données ; flux testable sans scène |
| Rival : un ami d'enfance, compétitif, « il est préparé » | dossier 02 §2 | sa présentation par Chen reste brève et taquine |
| Départs de débogage et QA bornée | `tools/debug_start/`, mémoire QA | un départ de débogage **saute** tout l'écran titre |
| Les maquettes ne font jamais foi sur le fonctionnel | `CLAUDE.md` règle 10 | le storyboard d'ouverture v1 (chambre → révélation) reste la référence des intérieurs, pas de ce chantier |

---

## 3. Architecture technique proposée

### 3.1 Principe
**Boot reste la scène principale.** Les départs de débogage, les tests et le garde-fou `current_scene == self` en dépendent. On ajoute un **mode d'ouverture** devant `_start_game_state()` :

```text
Boot._ready()
  └─ (inchangé) bibliothèques, réglages, câblage
  └─ _start_game_state()
       ├─ départ de débogage ? ─────────────► comme aujourd'hui (aucun écran titre)
       ├─ Boot n'est pas la scène courante ? ► comme aujourd'hui (tests, outils de capture)
       └─ sinon ► OpeningDirector.run()
            ├─ TITRE ── Continuer ──────────► lecture de la sauvegarde → _resume()
            │        ├─ Paramètres ─────────► SettingsScreen (hôte titre) → TITRE
            │        └─ Nouvelle partie ─┬─ sauvegarde valide ? → CONFIRMATION → INTRO
            │                            └─ sinon ───────────────────────────→ INTRO
            └─ INTRO (données) → VALIDATION (commit) → CHAMBRE (SceneRouter.start)
```

Grâce au garde-fou, **l'immense majorité des tests existants restent inchangés** : ils instancient Boot hors de la scène courante. Seuls les tests qui décrivent explicitement le démarrage réel changent (§10).

### 3.2 Logique (sans scène, testable avec GUT)
- **`game/systems/opening/opening_flow.gd`** : machine d'états `TITLE → CONFIRM_OVERWRITE → INTRO → COMMIT → DONE` (et `TITLE → CONTINUE`). Entrées : l'état de la sauvegarde (`none`, `valid`, `corrupt`, `newer`) et les actions du joueur. Sorties : l'écran à afficher et les commandes « écrire » / « sauvegarder l'ancienne ».
- **`title_menu_model.gd`** : à partir du statut et du résumé de la sauvegarde, il donne les entrées disponibles, l'entrée mise en avant et le contenu de la carte Continuer.
- **`name_rules.gd`** : normalisation et validation (arbitrage 7). C'est une fonction pure, testée exhaustivement.
- **`intro_script.gd`** : charge et valide `data/opening/oak_intro.json`, une suite d'étapes :
  - `stage` (montrer ou cacher un portrait, faire entrer Nidorino, régler la lumière) ;
  - `page` (texte, avec les jetons `{player}` et `{rival}`) ;
  - `prompt` (`look`, `player_name` ou `rival_name`) ;
  - `confirm` (« X, c'est bien ça ? »).
- **`data/opening/names.json`** : noms proposés et limites, qui sont des données (règle 7).

### 3.3 Présentation (`game/ui/opening/`)
- **`title_screen.tscn`** : logo, trois boutons, carte Continuer, message d'état de la sauvegarde.
- **`intro_stage.tscn`** : un `CanvasLayer` au-dessus du monde. Il contient le fond (lumière dorée de Bourg Palette, procédurale, ou labo flouté selon la référence, §9.0) et trois emplacements de portrait (gauche, centre, droite) avec des entrées en fondu et une légère montée. Le texte passe par **la `DialogueBox` existante**.
- **`name_entry.tscn`** : portrait du personnage nommé, champ texte natif (le clavier Android s'ouvre), pastilles des noms proposés et bouton **Valider**.
- **`look_choice`** (option B) : réutilise le **choix à deux cartes**, illustré des deux portraits en pied.
- **Paramètres** : `SettingsScreen` est aujourd'hui intégré à `TrainerMenu`. Il faut l'en **découpler** pour pouvoir l'héberger depuis le titre, sans l'entrée « Sauvegarder maintenant ». C'est un petit refactor à faire en OUV.1, testé.

### 3.4 Données de partie (`GameState`, sauvegarde v5)
Nouveaux champs :
- `rival_name: String`, par défaut le premier nom proposé (« Régis », selon l'arbitrage 5) ;
- `player_look: StringName`, `&"hero"` par défaut ; `&"heroine"` seulement avec l'option B ;
- en option B, l'accord grammatical se **déduit** de `player_look` par une table dans les données, pas par un second champ.

**Préparer l'héroïne sans la faire (A2, option A)** : `player_look` est créé et sauvegardé **dès la v5**, même s'il vaut toujours `&"hero"`. Ajouter l'héroïne plus tard ne demandera donc **aucune migration** :
- une nouvelle valeur `&"heroine"` ;
- ses assets, rangés par apparence (§3.6) ;
- l'écran de choix (§5.6) ;
- la syntaxe d'accord des textes (§3.5), qui ne touche pas la sauvegarde.

En V1, `player_look` est lu partout où l'apparence compte, mais n'a qu'une seule valeur possible. Un test vérifie qu'une valeur inconnue chargée depuis une sauvegarde retombe sur `&"hero"` sans erreur.

**Sauvegarde v5** (règle du projet : un nouveau champ fait incrémenter la version) :
- `upgrade()` de 4 à 5 remplit les valeurs par défaut ;
- la partie de Kevin reprend donc avec « Kevin », « Régis » et le héros ;
- il faut une **fixture v4** réelle, qui n'existe pas encore (les fixtures s'arrêtent à v3).

### 3.5 Jetons et étiquettes
- On ajoute `{player}` et `{rival}` à la liste blanche des jetons.
- **On les résout aussi dans `speaker`**.

**Prénom du rival ≠ rôle du rival.** Le mot « rival » existe à trois niveaux, et **seul le premier change** :

| Couche | Exemples | Traitement |
|---|---|---|
| **1. Nom affiché** (ce que le joueur lit comme nom propre) | les 19 `"speaker": "Rival"` (14 `oak_lab.json`, 4 `route_22.json`, 1 `rival_house.json`) ; `"name": "Le Rival"` ×2 dans `data/trainers/rival.json` (« Le Rival envoie Carapuce ! ») | remplacés par le jeton `{rival}`, **résolu à l'affichage, jamais stocké** |
| **2. Identifiants techniques** (le rôle dans les systèmes) | id de dresseur `rival`, PNJ et acteur de cinématique `rival`, apparence `rival` (`rival_frames.tres`), drapeaux `rival_battle_done`…, moment `rival_battle`, IA, noms de fichiers, de fonctions et de tests | **inchangés**, aucun renommage |
| **3. Le mot commun « rival »** dans un texte (le rôle, pas le nom) | titre du grand moment « Combat contre le rival » ; commentaires ; § des dossiers | **inchangé** par défaut ; c'est un rôle, comme « Champion » |

Règles :
- **Pas de rechercher-remplacer** sur « Rival » : la liste fermée de la couche 1 ci-dessus est la seule modifiée, champ par champ (`speaker`, `name` d'un dresseur).
- Un **test** interdit le littéral `"Rival"` / `"Le Rival"` comme `speaker` ou nom de dresseur dans `data/`. Un autre vérifie que les identifiants de la couche 2 existent toujours.
- **Les tests existants** : 65 occurrences de « Le Rival » / « Rival » dans 17 fichiers de `tests/`. Ceux qui lisent les données attendent désormais `{rival}`. Ceux qui vérifient un affichage injectent un nom fixe (« Régis »), sans dépendre d'une sauvegarde.
- Les commentaires de code qui citent « Le Rival » en exemple (`trainer_data.gd`, `battle_side.gd`, `battle_playback.gd`) et le texte d'aperçu de l'éditeur dans `battle_message_banner.tscn` sont mis à jour ou laissés tels quels, au choix (aucun effet en jeu).
- Les **Pokémon du rival** n'ont pas de dresseur d'origine affiché : rien à faire.
- **À coordonner avec le chantier combat** (CB) : la résolution de `{rival}` dans le nom du dresseur passe par `battle_text.gd`, qui est de son ressort.
- **Option B uniquement** : une syntaxe d'accord `{g:réveillé|réveillée}`, résolue d'après `player_look`, validée au chargement (deux formes exactement). Un test vérifie que la liste des répliques adressées au joueur et accordées (§8.3) est entièrement couverte.

### 3.6 Apparence
- `Player.LOOK_SPRITE` (aujourd'hui la constante `&"player"`) devient une valeur lue depuis `GameState.player_look`, résolue par `CharacterLook`.
- Les autres usages suivent la même clé : `heros_lancer` (combat), `hero_bust` (menu), `player_portrait` (carte).
- Option A (V1) : un seul jeu d'assets, mais déjà **rangé et résolu par apparence** (`hero` → les fichiers actuels). L'héroïne n'aura qu'à ajouter les siens sous `heroine`.

### 3.7 Point de validation (« commit ») : la sécurité des données

**Garanties** (A10 + revue) :
1. **Tant que l'introduction n'est pas finie, le disque n'est pas touché.** Aucune écriture de `save.json`, aucun fichier « introduction en cours », aucun drapeau intermédiaire. L'introduction n'a **pas d'état persistant** : elle n'existe qu'en mémoire.
2. **Quitter à n'importe quel moment avant le commit** (fermer, tuer l'application, panne de batterie, retour au titre) laisse exactement **l'ancienne sauvegarde, intacte**, ou aucune sauvegarde s'il n'y en avait pas. Au relancement : titre, Continuer sur l'ancienne partie, et une Nouvelle partie qui recommence l'introduction **depuis le début**, après une nouvelle confirmation.
3. **Pas d'état à moitié écrit** : le commit est une suite d'écritures atomiques, chacune sûre si elle est interrompue (ci-dessous).

**Pendant le titre et l'introduction** :
- L'autosave est **désactivé** (l'`OpeningDirector` déclare l'état « non stable »), y compris au passage en arrière-plan.
- Le **fond du titre** (Bourg Palette en direct) est chargé en **mode décor** : il ne passe pas par la tenue de compte de `SceneRouter` (`map_entered`, cartes découvertes, autosave d'entrée de carte) et ne modifie pas `GameState`. Le Bourg Palette du titre ne compte donc pas comme visité, et il est libéré avant le commit ou avant Continuer.
- Les **réglages** modifiés depuis le titre sont écrits dans `settings.json` comme aujourd'hui. Ce fichier est indépendant de la partie et ne crée pas d'état intermédiaire.

**Protocole du commit**, à la fin de la dernière réplique de Chen, **avant** le fondu vers la chambre :
1. Si `save.json` existe : copie atomique vers `save.previous.json` (`.tmp` → relecture → renommage), qui remplace l'éventuelle copie précédente. *Interruption ici* : `save.json` est encore l'ancienne partie ; tout va bien.
2. `GameState.new_game()`, puis application du prénom, du rival et de l'apparence. Tout cela se passe en mémoire.
3. **Écriture atomique immédiate** de la nouvelle partie (`SaveSystem.write`, avec la position dans la chambre, face au sud). On n'attend pas l'autosave d'arrivée. *Interruption avant le renommage* : `save.json` reste l'ancienne partie. *Après* : la nouvelle partie existe et reprendra dans la chambre.
4. Fondu au blanc, puis `SceneRouter.start(chambre)`. L'autosave normal reprend.

Il n'existe donc que deux états possibles sur le disque, « ancienne partie » ou « nouvelle partie dans la chambre », et jamais d'entre-deux.

**Tests** (système de fichiers en mémoire, `memory_file_system.gd`) :
- une interruption simulée après chaque étape du commit ;
- un abandon à chaque plan de l'introduction ;
- un relancement après abandon, qui vérifie que l'ancienne sauvegarde est identique octet pour octet ;
- une deuxième introduction complète après un abandon.

**Cas « version plus récente »** : comportement actuel conservé (on joue sans écrire), avec un avertissement sur le titre.

### 3.8 Ce que l'ouverture ne touche pas
- Les cartes, le prologue, les cinématiques existantes et le moteur de combat (sauf l'affichage du nom du rival, en coordination avec CB).
- Les départs de débogage, sauf un nouveau préréglage éventuel pour la QA de l'ouverture.

---

## 4. Storyboard

Durées indicatives à la vitesse de texte « Normale ». **♪** marque un point d'accroche pour le futur chantier audio.

| # | Plan | Contenu | Interaction | Transition |
|---|---|---|---|---|
| 0 | **Splash** | logo **Kanto 2026** centré sur fond sombre chaud, image de démarrage native (affichée pendant le chargement réel, sans délai artificiel) | aucune | fondu vers le titre ≈ 0,4 s |
| 1 | **Titre** | Bourg Palette en direct, à l'heure dorée, caméra qui dérive lentement ; logo en haut à gauche ; à droite, la carte **Continuer** (si sauvegarde), **Nouvelle partie** et **Paramètres** ♪ thème titre | toucher un bouton | fondu au noir ≈ 0,45 s (valeur des portes) |
| 1b | Confirmation | carte sombre sur le titre flouté (§5.4) | Annuler / Commencer | retour au titre ou fondu |
| 2 | **Scène de Chen** | le noir s'ouvre sur la **lumière d'heure dorée de Bourg Palette** (ou le labo très flouté, §9.0) ; **portrait en pied de Chen** au centre, qui entre en fondu et en légère montée ♪ thème de Chen | toucher = continuer | — |
| 3 | Présentation du monde | Chen se décale à gauche ; un **éclair de Poké Ball** à droite, puis **Nidorino** apparaît (artwork, petite respiration) | toucher | Nidorino sort en fondu |
| 4 | Le joueur | Chen sort ; le **portrait en pied du joueur** entre au centre | option B : choix de l'apparence à deux cartes | fondu enchaîné sur l'autre portrait si on change |
| 5 | Prénom du joueur | écran de prénom (§5.5) sur la scène ; le portrait reste visible à gauche | saisie ou pastille → Valider → « {player}, c'est bien ça ? » Oui / Non | — |
| 6 | Le rival | le portrait du joueur sort ; **portrait du rival** au centre, les bras croisés ; Chen revient, l'air embarrassé (« comment s'appelle-t-il déjà ? ») | toucher | — |
| 7 | Prénom du rival | même écran que le 5, avec les noms du rival | idem | — |
| 8 | Envoi | Chen seul, puis le **portrait du joueur** revient au centre pour la dernière réplique | toucher | le portrait **rétrécit vers le centre et se dissout dans la lumière** (clin d'œil au rétrécissement de Rouge/Bleu) → **fondu au blanc chaud** ≈ 0,8 s |
| 9 | **Chambre** | fondu du blanc vers la chambre, rayon de soleil par la fenêtre ; joueur face au sud ; **aucun titre de zone, aucun texte** ; contrôle rendu à la fin du fondu ; première autosave | prologue existant | — |

Durée totale visée : **≈ 60–90 s, plafond retenu** (revue du 2026-10-10 : « mémorable, mais rapide » ; les 2–3 min envisagées au départ sont écartées). C'est environ 15 pages de Chen, sans compter la saisie. Si une mesure sur S24 dépasse 90 s, on coupe des pages, pas des plans.

---

## 5. Écrans et interactions

### 5.1 Splash
- Godot `application/boot_splash/image` : logo Kanto 2026 sur un fond uni sombre et chaud (teinte par défaut, ajustée avec l'asset), avec `fullsize=false` et le filtre activé.
- Android 12+ affiche d'abord l'icône système. On ne la combat pas : elle s'enchaîne avec notre image.
- Pas de second splash animé : la durée du splash est celle du chargement réel.

### 5.2 Écran titre
- **Disposition paysage** :
  - logo en haut à gauche, sans cadre, posé sur le monde avec une ombre douce ;
  - colonne d'actions à droite : grandes cartes tactiles d'au moins 96 px de haut, panneaux sombres translucides du thème 2026.
- **Continuer** est la carte la plus grande, mise en avant par un liseré doré. Elle affiche :
  - le prénom ;
  - le lieu (nom de zone) ;
  - le temps de jeu ;
  - les badges et les captures du Pokédex ;
  - le buste du joueur.

  Toutes ces données existent déjà dans la sauvegarde.
- **Nouvelle partie** et **Paramètres** sont des cartes secondaires.
- Il n'y a pas d'écran intermédiaire « Toucher pour commencer » : ce serait un toucher inutile.
- **Selon l'état de la sauvegarde** :

  | État | Continuer | Nouvelle partie | Message |
  |---|---|---|---|
  | aucune | absente | mise en avant | — |
  | valide | mise en avant | secondaire, avec confirmation | — |
  | corrompue (mise en quarantaine) | absente | mise en avant | « La sauvegarde n'a pas pu être lue. Une copie a été mise de côté. » |
  | version plus récente | absente | possible, **sans sauvegarde** | « Cette sauvegarde vient d'une version plus récente du jeu. Elle n'a pas été modifiée. » |
- **Retour Android** : sans effet sur le titre (`quit_on_go_back=false` est déjà réglé). On quitte par le système.

### 5.3 Paramètres depuis le titre
- Le même écran que dans le Menu Dresseur, avec ses cinq catégories, **sans** « Sauvegarder maintenant ».
- On revient au titre par « ‹ » ou par Retour.
- Les réglages s'appliquent tout de suite : vitesse du texte et accessibilité valent aussi pour l'introduction.

### 5.4 Confirmation de nouvelle partie
- Une carte sombre centrée et deux choix (bible §4) :

  > **Une aventure est déjà en cours.**
  > {player} · {temps de jeu} · {badges}
  > Commencer une nouvelle partie remplacera cette aventure lorsque tu arriveras dans ta chambre.

- Boutons : **Annuler** (par défaut, à gauche) et **Nouvelle partie** (à droite, couleur d'alerte du thème, jamais la couleur seule : l'icône et le texte portent aussi le sens).
- Pas de seconde confirmation : le filet de sécurité est `save.previous.json`, plus le fait que l'écrasement n'arrive qu'à la chambre.

### 5.5 Écran de prénom
- **Haut** : « Comment t'appelles-tu ? » (ou « Comment s'appelle-t-il ? ») sous forme de page de Chen dans la `DialogueBox`, qui reste visible.
- **Centre-droit** :
  - champ texte (thème 2026), qui s'ouvre avec le clavier du téléphone ;
  - compteur discret « 4 / 10 » ;
  - en dessous, trois **pastilles** avec les noms proposés. En toucher une remplit le champ.
- **Bas** :
  - **Valider**, inactif tant que le champ est vide ou invalide ;
  - un message d'aide sous le champ seulement en cas de caractère refusé (« Lettres, espaces, - et ’ seulement ») ;
  - jamais de pop-up.
- **Après validation**, une page de Chen et un choix **Oui / Non** :

  > **Prof. Chen** — « {player} ! C'est bien ça ? »

  « Non » rouvre l'écran avec le champ déjà rempli.
- **Retour Android** : il ferme d'abord le clavier, puis ne fait rien. On ne revient pas en arrière dans l'introduction, comme dans Rouge/Bleu ; « Non » suffit à corriger.

### 5.6 Choix de l'apparence (option B seulement)
- Deux cartes avec les portraits en pied ; toucher une carte fait entrer le portrait sur la scène.
- Aucun mot « garçon » ou « fille » n'est imposé à l'écran. Les étiquettes sont à décider avec Kevin si l'option B est retenue (par défaut, aucune : les portraits suffisent).

---

## 6. Textes de l'introduction — **proposition, à valider par Kevin**

On garde **les temps forts de Rouge/Bleu**, réécrits dans la voix de Chen du dossier 02 (bienveillant, observateur, un peu distrait). **Aucune phrase n'est copiée de la version française d'origine.** Chaque page tient en une ou deux lignes.

> **Prof. Chen** — « Bonjour ! Bienvenue dans le monde des Pokémon ! »
> « Je m'appelle Chen. Ici, on m'appelle le Professeur Pokémon. »
> *(Poké Ball, Nidorino apparaît)*
> « Ce monde est peuplé de créatures que l'on appelle Pokémon. »
> « Certains vivent à nos côtés. D'autres préfèrent les hautes herbes, les forêts ou la mer. »
> « Certains Dresseurs s'entraînent avec eux pour combattre. Moi… je passe mes journées à les observer. »
> *(Nidorino sort ; le joueur entre)*
> « Mais parlons un peu de toi. »
> *[option B : choix de l'apparence]*
> « Comment t'appelles-tu ? »
> *[prénom]* « {player} ! C'est bien ça ? » *[Oui / Non]*
> *(le rival entre)*
> « Et lui, tu le connais depuis toujours. C'est mon petit-fils. »
> « Vous vous lancez des défis depuis que vous savez marcher. »
> « Il s'appelle… euh… »
> « Comment s'appelle-t-il, déjà ? »
> *[prénom du rival]* « {rival} ! C'est ça, bien sûr. » *[Oui / Non]*
> *(le rival sort ; le joueur revient)*
> « {player} ! Ta propre aventure est sur le point de commencer. »
> « Un monde de rêves et de rencontres t'attend. »
> « Allez… en route ! »

- **Variante sans petit-fils** (si l'arbitrage 3 est refusé) : « Et lui, tu le connais depuis toujours. Ton voisin… et ton plus grand rival. »
- **Option B** : « Il s'appelle… » reste au masculin (le rival est toujours un garçon). L'introduction ne contient **aucun accord adressé au joueur** : c'est voulu.

---

## 7. Cas limites

| Situation | Comportement |
|---|---|
| L'application passe en arrière-plan pendant l'introduction | rien n'est écrit ; au retour, on reprend à la même page |
| L'application est tuée pendant l'introduction | au prochain lancement : titre, avec l'ancienne sauvegarde intacte (ou aucune) ; l'introduction recommence au début |
| Tuée exactement pendant le commit | l'écriture atomique existante protège `save.json` ; `save.previous.json` est écrit **avant** |
| Prénom vide, en espaces seulement, trop long ou avec des emoji | Valider inactif ou caractère refusé, avec l'aide sous le champ ; la troncature à 10 caractères se fait à la saisie (`max_length`) |
| Collage d'un texte | normalisé par `name_rules` comme une saisie ; si le résultat est vide, Valider reste inactif |
| Prénom identique pour le joueur et le rival | accepté (comme dans Rouge/Bleu) |
| Clavier du téléphone qui couvre le champ | le champ est placé dans la moitié haute de l'écran en paysage (à vérifier sur S24) |
| Sauvegarde v4 existante (partie de Kevin) | migrée en v5 : « Kevin », rival au nom par défaut, héros ; elle reprend sans rien demander |
| Corrompue ou version plus récente | §5.2 |
| Départ de débogage présent | pas de titre ni d'introduction, comme aujourd'hui ; les noms par défaut s'appliquent |
| Tests GUT et outils de capture | Boot n'est pas la scène courante : pas d'ouverture, comportement actuel |
| « Réduction des animations » active | fondus raccourcis, pas de dérive de la caméra du titre, pas d'animation de montée des portraits |
| « Taille du texte » grande | l'écran de prénom et les cartes du titre restent lisibles (à vérifier par capture) |
| Mode gaucher | colonne d'actions du titre à **gauche** |
| Retour Android | §5.2 et §5.5 ; jamais de sortie involontaire |
| Premier lancement après mise à jour | identique à « sauvegarde valide » |

---

## 8. Incompatibilités avec l'existant, et leur traitement

1. **`test_boot.gd`** vérifie l'absence d'écran titre et le départ direct dans la chambre. Grâce au garde-fou, ces tests décrivent toujours Boot hors scène courante. Il faut **les renommer et les reformuler** (« sans ouverture, Boot démarre dans la chambre ») et ajouter des tests qui couvrent l'ouverture.
2. **« Rival » écrit en dur** : 19 étiquettes et « Le Rival ». On passe par le jeton `{rival}` dans `speaker` (§3.5). C'est un changement mécanique, sans réécrire de texte.
3. **Accords au masculin** (option B seulement). Répliques adressées au joueur relevées automatiquement, liste **à compléter par une relecture humaine** avant OUV.2 :
   - `player_house.json` l. 10 : « Tu es enfin réveillé ? » ;
   - `rival_house.json` l. 9 : « Ah. Enfin réveillé. » ;
   - `pallet_town.json` l. 44 : « …tout seul ? » ;
   - `oak_lab.json` l. 167 : « T'es déjà revenu, toi aussi ? » ;
   - `route_22.json` l. 25 : « …tu es venu voir… » ;
   - ainsi que les répliques de Dresseurs et de PNJ des J7–J10 qui s'adressent au joueur (non relevées par la recherche par mots-clés).

   Le texte du dossier 02 n'est **pas réécrit** : on ajoute seulement la forme féminine, validée par Kevin dans le lot de textes.
4. **`SettingsScreen` intégré au `TrainerMenu`** : il doit être découplé pour être hébergé par le titre (§3.3).
5. **QA et captures** (`deploy_s24.sh`) : sans départ de débogage, la capture tombe désormais sur le titre. Il faut un préréglage « continuer » ou un toucher scripté. La QA de l'ouverture se fait sans départ de débogage.
6. **Fichiers partagés avec le J10** (`boot.gd`, `game_state.gd`, cinématiques, écran Dresseur) : **implémentation après la fusion du J10 dans `main`**. Ce dossier ne modifie que `docs/`.
7. **Combat (CB)** : seul `battle_text.gd` est concerné (nom du rival). La modification est petite, à faire après CB.3 et à signaler.
8. **Dossier 01, « Déroulé d'ouverture »**, et les reportés : la légende « Le commencement de toute aventure » (arbitrage 12) remplace « Kanto » **seulement à la toute première sortie**. Il faut un drapeau, mais pas de nouvelle donnée de sauvegarde, puisque `discovered_maps` le dit déjà.

---

## 9. Assets et références visuelles

### 9.0 Priorité artistique (revue du 2026-10-10)
Le titre, la scène de Chen et l'écran de prénom appartiennent au **même univers visuel que Bourg Palette et le laboratoire existant**. Ils ne doivent pas ressembler à un autre jeu Pokémon : ni le fond blanc de Rouge/Bleu, ni la scène de Rouge Feu, ni l'interface d'un jeu récent.

Concrètement :
- **Fond de la scène de Chen** : la lumière d'heure dorée de `bourg-palette-vue-generale-v1.png`, pas un studio abstrait. Option à étudier dans la référence : un **intérieur du laboratoire très flouté** en fond (`labo-chen-v1.png`), Chen au premier plan.
- **Portraits** : peints simplifiés, de la même main que les personnages du monde, sur l'ancre de style (`cahier-art-monde-v0.1.md` §4), lumière neutre éclairée par Godot.
- **Interface** : le thème 2026 du jeu (skill `ui-theme-2026`, panneaux sombres translucides, la même boîte de dialogue que le prologue), aucune police ni cadre rétro.
- **Chaque prompt de référence** joint `bourg-palette-vue-generale-v1.png`, `labo-chen-v1.png` et `heros_portrait.png` comme ancres.

### 9.1 Références visuelles à produire avant l'implémentation (Kevin, avec ChatGPT ; prompts rédigés par Claude sur demande)

| Référence | Contenu attendu |
|---|---|
| `ouverture-titre-v1` | écran titre paysage : Bourg Palette à l'heure dorée en fond, logo, colonne de cartes (Continuer détaillée, Nouvelle partie, Paramètres) |
| `ouverture-chen-v1` | scène d'introduction : lumière dorée de Bourg Palette (ou labo flouté, §9.0), Chen en pied, Nidorino, boîte de dialogue sombre en bas |
| `ouverture-prenom-v1` | écran de prénom : portrait, champ, pastilles, Valider, clavier Android ouvert |
| *(option B)* `ouverture-apparence-v1` | les deux cartes, héros et héroïne |

### 9.2 Assets de jeu manquants

| Asset | Format (défauts) | Production | Bloque |
|---|---|---|---|
| **Logo « Kanto 2026 »** (logotype propre, **pas** le logo officiel Pokémon) | vectoriel ou PNG 2048 px transparent, version claire | Kevin / Codex | OUV.1 |
| **Image de démarrage** | logo sur fond uni, 1920 × 1080 | dérivée du logo | OUV.1 |
| **Portrait en pied de Chen** | ≈ 380 × 770, comme `heros_portrait.png`, peint simplifié, lumière neutre, sur l'ancre de style | Codex (`tools/art`) | OUV.2 |
| **Portrait en pied du rival** | idem, bras croisés | Codex | OUV.2 |
| Portrait en pied du héros | **existe** (`heros_portrait.png`) ; à vérifier sur la scène lumineuse | — | — |
| Nidorino | **existe** (artwork officiel 033) | — | — |
| Éclair de Poké Ball | effet procédural (particules), aucun asset | code | — |
| Fond de la scène de Chen | lumière dorée procédurale (aucun asset) ou flou d'un intérieur du labo existant, selon la référence §9.1 | code | — |
| *(option B)* **Héroïne complète** | planches marche, attente et course 4 × 4, lancer de dos, portrait en pied, buste du menu, portrait de la carte, toutes calibrées sur `PERSO_P2_PEINT_r1` (128 px, filtre linear) | Codex, **le plus gros lot** | OUV.2 (écran d'apparence) |
| Musique et sons | — | hors périmètre (arbitrage 14) | — |

**Nouveau type d'asset** : les portraits en pied de PNJ (Chen, rival) n'ont pas de précédent. Celui du héros sert d'étalon pour l'échelle, le cadrage et la lumière.

---

## 10. Découpage proposé (après la fusion du J10)

Validation S24 par sous-jalon (`CLAUDE.md`, règle 1). **OUV.1 touche la sauvegarde : il est validé seul.**

| Sous-jalon | Contenu | Validation S24 |
|---|---|---|
| **OUV.1 — Démarrage et sauvegarde** | splash ; écran titre (fond Bourg Palette en direct) ; Continuer / Nouvelle partie / Paramètres ; états de la sauvegarde ; confirmation ; commit différé + `save.previous.json` ; sauvegarde v5 (champs par défaut) + migration + fixture v4 ; découplage de `SettingsScreen` ; contournement par les départs de débogage. Provisoirement, Nouvelle partie mène directement à la chambre | reprendre la vraie partie de Kevin ; nouvelle partie confirmée ; tuer l'application avant la chambre (l'ancienne partie est intacte) |
| **OUV.2 — Introduction de Chen** | `oak_intro.json` + scène + portraits ; écran de prénom (clavier natif, règles, propositions) ; jetons `{player}` / `{rival}` et étiquette du rival ; *(option B)* choix de l'apparence et accords | introduction complète au S24, clavier, lisibilité |
| **OUV.3 — Transitions** | rétrécissement → blanc → chambre ; légende de la première sortie (arbitrage 12) ; réduction des animations ; passe de finition | parcours complet, du lancement à la descente vers Maman |

**Tests à prévoir** : `opening_flow` (toutes les transitions et les quatre états de la sauvegarde), `name_rules`, `intro_script` (validation des données), migration 4 → 5, jetons dans `speaker`, Boot en scène courante avec et sans sauvegarde (système de fichiers en mémoire), départ de débogage qui saute l'ouverture.

---

## 11. Prochaines étapes
1. Kevin tranche les **arbitrages A1–A14** (au minimum A1, A2, A3, A5, A10 et A12 ; les autres ont des défauts raisonnables).
2. Kevin valide ou corrige les **textes du §6** (et, avec l'option B, la forme féminine des répliques du §8.3, en un seul lot).
3. Références visuelles du §9.1, puis assets bloquants (logo, portraits de Chen et du rival).
4. Après la fusion du J10 : plan technique `docs/tech/ouverture.md` (tâches et critères d'acceptation), puis OUV.1.
