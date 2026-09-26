# Jalon 3A — PNJ, interactions, dialogues, vie de Bourg Palette

> Objectif jouable sur le S24 : le joueur se réveille dans sa chambre et descend. **Maman** se tourne vers lui et lui parle d'elle-même : « Bonjour ! Tu es enfin réveillé ? ». Si on lui reparle, sa réplique a changé. Sur la table, le petit-déjeuner s'**examine**. Chez le voisin, le **rival** prépare ses affaires dans sa chambre, et sa **carte de Kanto** s'examine. Au labo, **Chen n'est pas là** : **Maya** travaille devant un écran, et les trois **starters** sur la table s'**observent**. Dans le village, **Mme Aoki** nourrit deux Roucool près de la place, **Léo** joue avec son Rattata près d'une clôture, **Haru** pêche au bout du ponton, et le panneau « BOURG PALETTE » se lit.
>
> Le **bouton contextuel** n'apparaît que face à quelqu'un ou à quelque chose, avec son verbe : **Parler**, **Examiner** ou **Observer**. Les répliques s'affichent dans la **boîte de dialogue 2026** de la bible UI/UX (`docs/design/ui-ux-bible-v0.1.md` §3, décision de Kevin) : panneau inférieur sombre et translucide, nom du locuteur au-dessus du texte, sans portrait, texte rapide, indicateur « › », avance au toucher. Le joueur est immobile pendant un dialogue. Sur Mac, `E` ou `Espace` remplacent le bouton.
>
> C'est le jalon 3A du dossier 02 (§1 à §4). Il ouvre la phase 3 « Interactions ».

**Hors périmètre** :
- **Jalon 3B** (dossier 02 §5 et arrivée du §6) : hautes herbes de la Route 1, « Hé ! Attends ! », Chen qui ramène le joueur au labo, rival déjà au labo. L'architecture le prépare (§2.11) sans rien en construire. Chen n'apparaît nulle part en 3A. Sa case (8, 4) au labo reste libre.
- **Jalon 4** (dossier 02 §6 à §10) : starter, « Rencontrer », fiche légère, combat.
- **Système Pokémon** : ni espèces, ni stats, ni équipe. Les Pokémon du décor (Roucool, Rattata, starters) sont des **PNJ à sprite de Pokémon** (§2.3), avec une animation d'attente et une petite réaction.
- **Routines horaires, `GameClock`, PNJ qui se promènent** : phase 10. Les PNJ de 3A restent sur leur case (§2.3, Q12).
- **Sauvegarde** : l'état de la session (Maman a déjà parlé, le rival aussi) vit dans l'autoload `GameState` (§2.6), **sans sauvegarde**. Quitter l'application recommence la partie, comme au jalon 2.
- Portraits au-dessus de la boîte (Q10), bulles au-dessus des PNJ, sons, voix, vibration autre que l'appui sur le bouton contextuel, choix oui/non dans les dialogues.
- **Autres habitants** : la sœur du rival (dossier 01 §2) et les autres pistes du dossier 01. Le dossier 02 en fixe quatre « pour commencer ».
- Rendu « vraie DA » des personnages et des Pokémon : les sprites sont provisoires mais ont leurs dimensions finales.

Références : `CLAUDE.md`, **`docs/design/dossier-02-prologue.md` (source de vérité des textes et des intentions)**, `docs/design/dossier-01-bourg-palette.md`, `docs/design/ui-reference.md` + `reference/da-2026-planche-v1.webp` (case « Écran de dialogue »), `reference/ouverture-storyboard-v1.webp` (case 3), `reference/maison-rival-v1.webp` (**sans l'Évoli**), `reference/labo-chen-v1.png`, [`jalon-01.md`](jalon-01.md), [`jalon-02.md`](jalon-02.md) (§4 cases réservées, §7, §8), skills `godot-conventions`, `world-tiles` et `ui-theme-2026`.

---

## 1. Fondations déjà posées (architecte, testées)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/systems/story/story_flags.gd` | `StoryFlags` | **Drapeaux d'histoire** de la session : `set_flag(flag, value = true)`, `has_flag`, `has_all(list)`, `has_none(list)`, `clear()`, `to_array()` trié et `load_array()` (pour la future sauvegarde). Signal `flag_changed(flag, value)`, émis seulement quand la valeur change. |
| `game/systems/dialogue/dialogue_page.gd` | `DialoguePage` | Une page : `text`, `speaker` (vide = celui du dialogue), `pause` (silence avant le texte, s), `face_player` (le PNJ se tourne vers le joueur au début de la page), `react` (identifiant d'un PNJ ou Pokémon de la carte qui joue sa réaction). Les didascalies du dossier 02 deviennent ces trois champs. |
| `game/systems/dialogue/dialogue_variant.gd` | `DialogueVariant` | Pages et conditions : `if_flags` (tous levés), `unless_flags` (aucun levé), `set_flags` (levés à la fin), `auto` (se joue à l'arrivée sur la carte du PNJ). `matches(flags)`. |
| `game/systems/dialogue/dialogue.gd` | `Dialogue` | `id`, `speaker`, `narration` (examiner, observer : style distinct), `draft` (texte provisoire), `source`, `variants`. `pick(flags)` renvoie la **première** variante qui s'applique. |
| `game/systems/dialogue/dialogue_library.gd` | `DialogueLibrary` | Lit **tous les `.json`** de `data/dialogues/` (`load_dir`), `load_file`, `add_from_dict`. Il valide : clé inconnue (faute de frappe), pages vides, types, identifiant en double d'un fichier à l'autre, JSON illisible (avec le numéro de ligne). Une entrée invalide est écartée et signalée par `push_error` et `get_errors()`. Donne `get_dialogue(id)`, `get_ids()`, et `get_condition_flags()` / `get_set_flags()` pour les tests de cohérence. |
| `game/systems/dialogue/dialogue_session.gd` | `DialogueSession` | **Déroulé pur** d'un dialogue : `update(delta)` fait passer le silence de la page, puis écrit le texte à `chars_per_second` (0 = d'un coup). `advance()` renvoie `REVEALED` (on complète la page, pendant l'écriture ou le silence), `NEXT_PAGE`, `FINISHED` ou `NONE`. `get_page()`, `get_speaker()` (celui de la page, sinon celui du dialogue), `get_visible_characters()`, `is_page_complete()`, `is_last_page()`, `is_pausing()`. |
| `game/world/interactions/interaction.gd` | `Interaction` | Donnée d'une cible : `kind` (enum `Kind { TALK, EXAMINE, OBSERVE }` = Parler / Examiner / Observer), `cell`, `dialogue_id`, `facing` (orientation exigée du joueur, ZERO = de tous côtés), `source` (le PNJ, ou null pour un point fixe). `accepts(player_facing)`, `is_valid()`, `kind_name()` / `kind_from_name()`. |
| `game/world/interactions/interaction_table.gd` | `InteractionTable` | Points fixes d'une carte, indexés par case, calquée sur `WarpTable`. `add` refuse une entrée invalide ou **ambiguë** (même case, orientations qui se recouvrent). `find(cell, player_facing)`, `get_at`, `get_all`, `size`. |
| `game/world/interactions/interaction_finder.gd` | `InteractionFinder` | **Règle unique de la cible** : `find(grid, table, cell, facing)` regarde **la case devant le joueur**. D'abord l'occupant de la grille s'il expose `get_interaction()` (PNJ, Pokémon du décor), sinon le point fixe de la table qui accepte l'orientation. Rien derrière ni sur les côtés. Aucune allocation : appelable à chaque image. |
| `game/world/npc/npc_spec.gd` | `NpcSpec` | Description d'un PNJ ou Pokémon du décor : `id`, `cell`, `facing`, `sprite`, `dialogue` (vide = non interactif), `verb` (TALK ou OBSERVE), `turn_to_player`, `keep_facing`, `lift` (sprite surélevé en pixels, pour un Pokémon posé sur une table). `make_interaction(cell, source)`. |
| `game/world/npc/npc_roster.gd` | `NpcRoster` | Lit `data/npcs/<map_id>.json` (`load_for_map`). S'il n'y a pas de fichier, la carte n'a aucun PNJ, sans erreur. Il valide les clés, les types, la case (entiers ≥ 0), l'orientation, le verbe et l'unicité des identifiants. |

Tests : `tests/unit/test_story_flags.gd`, `test_dialogue_library.gd`, `test_dialogue_session.gd`, `test_interaction.gd`, `test_npc_roster.gd`, avec les données d'essai `tests/fixtures/dialogues/*.json` et `tests/fixtures/npcs/sample_map.json`. **356 tests verts** (295 + 61), import sans erreur.

---

## 2. Architecture

### 2.1 Arbre des scènes

```
game/boot.tscn
Boot (Node)  game/boot.gd                   racine de composition (câblage seulement)
├─ World (Node2D)               %World
├─ ExplorationHud (instance)    %ExplorationHud     CanvasLayer 10 : + bouton contextuel (T2)
├─ DialogueBox (instance)       %DialogueBox        CanvasLayer 30 (T2)
├─ DialogueRunner (Node)        %DialogueRunner     game/systems/dialogue/dialogue_runner.gd (T3)
├─ InteractionController (Node) %InteractionController  game/world/interactions/… (T3)
└─ ScreenFade (instance)        %ScreenFade         CanvasLayer 100

Autoloads : SceneRouter (inchangé) · GameState (nouveau, game/autoload/game_state.gd, T1)
```

Structure d'une carte : un nœud **`Interactables`** (Node2D) s'ajoute, entre `Warps` et `Spawns`, dans les **6 cartes** (scripts `tools/build_*.gd`). Il contient les `InteractPoint`. Les PNJ **ne sont pas** dans la scène de la carte : `GameMap` les crée au chargement à partir de `data/npcs/<map_id>.json` (§2.3).

`Boot._ready` (ajouts) :
```gdscript
var library := DialogueLibrary.new()
library.load_dir()                                # data/dialogues/, erreurs → push_error
%DialogueRunner.setup(library, GameState.flags, %DialogueBox, _player)
%InteractionController.setup(_player, %DialogueRunner)
SceneRouter.map_changed.connect(%InteractionController.set_map)
SceneRouter.map_entered.connect(%InteractionController.on_map_entered)   # dialogue automatique
%InteractionController.target_changed.connect(_on_target_changed)        # → HUD
%DialogueRunner.dialogue_started.connect(_on_dialogue_started)           # HUD : contrôles masqués
%DialogueRunner.dialogue_finished.connect(_on_dialogue_finished)         # HUD : contrôles rétablis
# … puis SceneRouter.start(...) comme avant (map_changed/map_entered branchés AVANT start)
```

### 2.2 Interactions : cible, points fixes, bouton contextuel

**Cible = la case devant le joueur** (`InteractionFinder`, §1). Pas de détection de proximité ni de zone `Area2D` : tout passe par la grille, comme les warps. Si l'on pousse un PNJ, on se retrouve face à lui, et le bouton apparaît. Voir Q9 pour l'autre choix possible (cible adjacente, le joueur se tourne tout seul).

**Points fixes** : `InteractPoint` (`game/world/interactions/interact_point.gd`, `extends Marker2D`), dans `Interactables`, écrits par les scripts de construction à partir de tables, comme les `WarpPoint` :
```gdscript
class_name InteractPoint
extends Marker2D                    # position = Grid.cell_to_world(case d'ancrage)
@export var dialogue_id: StringName = &""
@export var kind: Interaction.Kind = Interaction.Kind.EXAMINE
## Cases couvertes depuis l'ancre (bas-gauche, comme les empreintes de props) :
## x 0..size.x-1, y -(size.y-1)..0. Une table 3 × 2 = un seul point.
@export var size: Vector2i = Vector2i.ONE
## Orientation exigée du joueur (ZERO = de tous côtés).
@export var facing: Vector2i = Vector2i.ZERO
func get_cell() -> Vector2i
func to_interactions() -> Array[Interaction]      # une par case couverte
```
`GameMap` (modifié) construit `get_interactions() -> InteractionTable` avec la grille, comme `get_warps()`. Une entrée invalide ou ambiguë donne `push_error("GameMap <id> : interaction invalide en <case>")`.

**Contrôleur** : `InteractionController` (`game/world/interactions/interaction_controller.gd`, Node, enfant de `Boot`) :
```gdscript
## Cible devant le joueur : kind = Interaction.Kind, ou -1 s'il n'y a plus de cible.
signal target_changed(kind: int)
func setup(player: Player, runner: DialogueRunner) -> void
func set_map(map: GameMap) -> void           # SceneRouter.map_changed
func on_map_entered(map: GameMap) -> void    # dialogue automatique (§2.7)
func get_target() -> Interaction
```
- À chaque image, **pas de cible** si le joueur est bloqué (`not is_input_enabled()` : transition, dialogue), s'il marche (`is_moving()`) ou si un dialogue tourne. Sinon, `InteractionFinder.find(map.get_grid(), map.get_interactions(), player.get_cell(), player.get_facing())`. `target_changed` n'est émis **qu'au changement** (autre cible ou autre verbe). Aucune allocation par image.
- **Appui** : `Input.is_action_just_pressed(&"interact")` (clavier `E`/`Espace`, ou le `TouchScreenButton` du HUD qui presse la même action) avec une cible. Si la source est un `Npc`, elle appelle `npc.begin_interaction(player.get_cell())` (il se tourne si `turn_to_player`), puis `runner.play(target.dialogue_id, npc, map)`.
- **Anti-rebond** : après `dialogue_finished`, le contrôleur ignore `interact` **jusqu'à son relâchement** (`Input.is_action_pressed` faux). Sinon, l'appui sur `E` qui ferme le dialogue le rouvrirait dans la même image.

**Bouton contextuel (HUD, T2)** : `InteractButton` = `TouchScreenButton` `action = "interact"` + `RoundButtonVisual`, et un **libellé** « PARLER » / « EXAMINER » / « OBSERVER » (Q9). Il reste invisible sans cible. Il apparaît et disparaît en fondu `ANIM_MICRO`. Un `TouchScreenButton` invisible ne reçoit pas le toucher. Place : le coin bas-droit, laissé libre au jalon 1 (`RUN_BUTTON_CENTER_FROM_CORNER`). `Boot._on_target_changed(kind)` appelle `hud.show_interact(Interaction.kind_name(kind))`, ou `hud.hide_interact()` si `kind == -1`. Le HUD ne connaît ni `Interaction` ni le joueur : il reçoit un nom de verbe (`&"talk"`, `&"examine"`, `&"observe"`).

### 2.3 PNJ et Pokémon du décor

**Données** : `data/npcs/<map_id>.json`, lu par `NpcRoster` (§1). Une entrée par personnage **ou Pokémon du décor**, dans l'ordre d'apparition (format en tête de `npc_roster.gd`). Mettre les PNJ dans `data/` plutôt que dans la scène (comme les warps) a deux raisons : Kevin peut les déplacer ou changer leur dialogue sans outil Godot, et leur **présence conditionnelle** (Chen au labo seulement après 3B, rival au labo) s'ajoutera au même endroit (§2.11).

**Scène** : `game/world/npc/npc.tscn` + `npc.gd` (`class_name Npc`, Node2D), calquée sur le joueur :
```
Npc (Node2D)  origine aux pieds, position = Grid.cell_to_world(spec.cell)
├─ Shadow (Sprite2D)
└─ Sprite (AnimatedSprite2D) %Sprite   NEAREST, scale 2, offset.y -= spec.lift
```
```gdscript
const FRAMES_DIR: String = "res://assets/sprites/characters/placeholder/"
func setup(spec: NpcSpec) -> void                 # avant add_child ; frames = FRAMES_DIR + sprite + "_frames.tres"
func get_id() -> StringName
func get_spec() -> NpcSpec
func get_cell() -> Vector2i
func get_interaction() -> Interaction             # instance gardée (pas d'allocation), null si non interactif
func face(direction: Vector2i) -> void            # anim idle_<dir>
func face_toward(cell: Vector2i) -> void          # axe dominant ; rien si même case
func begin_interaction(player_cell: Vector2i) -> void   # face_toward si turn_to_player
func end_interaction() -> void                    # reprend spec.facing, sauf keep_facing
func react() -> void                              # anim « react » si elle existe, sinon petit bond (Tween, ~12 px, 0,25 s)
```
- **Grille** : `GameMap._ready`, après `_build_grid`, crée un `Npc` par entrée, l'ajoute à `Entities` (y-sort) et fait `grid.occupy(cell, npc)`. `rebuild_grid()` réinscrit les PNJ. Un échec (case hors carte ou déjà occupée) donne `push_error` et le PNJ n'est pas créé. `GameMap` gagne `@export var npcs_dir: String = NpcRoster.DATA_DIR` (les tests pointent sur `tests/fixtures/npcs/`), `get_npcs() -> Array[Npc]` et `get_npc(id) -> Npc`. Les PNJ n'ont pas d'`owner` : les scripts de construction ne les sauvent jamais dans les `.tscn`.
- **Occupation d'une case solide** : un Pokémon posé sur un meuble (les starters) occupe une case de la table, qui est solide. `occupy` le permet, et `InteractionFinder` le trouve quand même (occupant avant solidité).
- **Orientation** : au repos, `spec.facing`. Quand on lui parle, il se tourne vers le joueur (`turn_to_player`, vrai par défaut), ou seulement sur une page `face_player` (le rival, dossier 02 §2). À la fin, il **reprend son orientation** : « il retourne à ses affaires » (Q4).
- **Animations** : `idle_<dir>` (2 images, respiration ou picorage pour Roucool, lentes), et `react` en option. `_process` est coupé au repos ; seule l'`AnimatedSprite2D` tourne. Aucun déplacement en 3A.
- **Sprites provisoires** (T4, `tools/gen_placeholder_npcs.gd`, sur le modèle de `gen_placeholder_player.gd`) : **personnes** en 32 × 64 natif (×2), silhouettes et couleurs distinctes, repère de direction (Maman : tablier ; rival : cheveux en pointes, veste sombre ; Maya : blouse blanche ; Mme Aoki : cheveux gris, châle ; Léo : plus petit, 32 × 48 ; Haru : chapeau, canne à pêche). **Pokémon** en 32 × 32 natif (×2 = 64 px), 4 directions : `bulbasaur`, `charmander` (flamme de queue qui vacille dans `idle`), `squirtle`, `rattata`, `pidgey`. Chaque sprite a un `<id>_frames.tres`.

### 2.4 Format des dialogues (`data/dialogues/*.json`)

Un fichier par lieu (`player_house.json`, `rival_house.json`, `oak_lab.json`, `pallet_town.json`). Chaque fichier est un objet `identifiant → dialogue`, et les identifiants sont uniques dans tout le dossier. Format complet en tête de `dialogue_library.gd` :

| Clé | Où | Rôle |
|---|---|---|
| `speaker` | dialogue, page | nom de l'étiquette (« Maman »). Vide ou absent = pas d'étiquette. Sur une page, il remplace celui du dialogue (scènes à plusieurs voix, 3B). |
| `narration` | dialogue | texte de narration (examiner, observer) : italique (Q7) |
| `draft` | dialogue | texte **provisoire** à remplacer par Kevin. Sans effet en jeu ; `get_ids()` + `draft` permettent de les lister. |
| `variants` | dialogue | liste ordonnée : la **première** qui s'applique gagne. Sans `variants`, les clés d'une variante s'écrivent directement dans le dialogue. |
| `pages` | variante | liste de pages : texte seul, ou objet `{ "text", "speaker", "pause", "face_player", "react" }` |
| `if` / `unless` | variante | drapeaux tous levés / aucun levé |
| `set` | variante | drapeaux levés **à la fin** du dialogue |
| `auto` | variante | se joue d'elle-même quand le joueur arrive sur la carte du PNJ (§2.7) |

**Convention de découpage** (Q2) : **une réplique « … » du dossier = une page**. Les didascalies ne s'affichent pas, elles deviennent de la mise en scène : « il regarde le joueur » → `face_player`, « petit silence » et « petit temps » → `pause` d'environ 0,6 à 0,8 s, « Rattata réagit » → `react`. Une page tient en **3 lignes** dans la boîte (test T4). Le texte est brut, sans BBCode.

Pourquoi du JSON : Kevin écrit ses textes (souvent avec ChatGPT) et peut les modifier sans l'éditeur Godot. Le format est lisible dans un diff, et la validation stricte attrape les fautes de frappe au lancement comme dans les tests. **Export Android** : les `.json` ne sont pas importés par Godot. On vérifie qu'ils partent dans l'APK (T4). Sinon, on ajoute `include_filter="data/*"` au préréglage d'export.

### 2.5 `DialogueRunner` et `DialogueBox`

`DialogueRunner` (`game/systems/dialogue/dialogue_runner.gd`, Node, enfant de `Boot`) est le **seul** à jouer un dialogue : interaction, dialogue automatique, et plus tard les scènes de 3B.
```gdscript
signal dialogue_started(dialogue_id: StringName)
signal page_started(index: int)                    # tests, futurs sons
signal dialogue_finished(dialogue_id: StringName)
var chars_per_second: float = UiTokens.DIALOG_CHARS_PER_SECOND
func setup(library: DialogueLibrary, flags: StoryFlags, box: DialogueBox, player: Player) -> void
## Faux (et rien ne se passe) si un dialogue tourne déjà, si l'identifiant est inconnu
## (push_error) ou si aucune variante ne s'applique (push_error). [param delay] : le joueur est
## bloqué tout de suite, la boîte s'ouvre après ce délai (dialogue automatique).
func play(dialogue_id: StringName, npc: Npc = null, map: GameMap = null, delay: float = 0.0) -> bool
func is_running() -> bool
func has_auto_variant(dialogue_id: StringName) -> bool   # pick(flags).auto
func get_session() -> DialogueSession
```
Déroulé :
1. `variant = dialogue.pick(flags)`. `player.set_input_enabled(false, &"dialogue")` **de façon synchrone**, puis `dialogue_started`.
2. Après `delay` : `box.open()`, puis `DialogueSession.new(variant.pages, dialogue.speaker, chars_per_second)`.
3. **Début de chaque page** (première comprise) : `box.show_page(session.get_speaker(), page.text, dialogue.narration)`. Si `page.face_player` : `npc.face_toward(player.get_cell())`. Si `page.react` : `map.get_npc(page.react).react()` (id inconnu : `push_warning`, on continue). Puis `page_started`.
4. `_process` : `session.update(delta)`, puis `box.set_visible_characters(session.get_visible_characters())` (−1 dès que la page est complète). Ensuite `box.set_continue_visible(session.is_page_complete() and not session.is_last_page())`.
5. **Avance** sur `box.advance_requested` (toucher n'importe où) ou sur `interact` juste pressé. Un appui dans l'image même de `play` est ignoré. `advance()` : `REVEALED` complète la page, `NEXT_PAGE` passe à l'étape 3, `FINISHED` passe à l'étape 6.
6. Fin : `await box.close()`, puis les `set_flags` sont levés, `npc.end_interaction()`, `player.set_input_enabled(true, &"dialogue")`, et enfin `dialogue_finished`. Les drapeaux sont levés **avant** le signal : un auditeur voit l'état à jour.

`DialogueBox` (`game/ui/dialogue/dialogue_box.tscn` + `.gd`, `class_name DialogueBox`, T2) **ne fait qu'afficher**. Il ne connaît ni la session, ni les données, ni le joueur :
```
DialogueBox (CanvasLayer, layer = UiTokens.LAYER_DIALOG = 30)
└─ Root (Control plein écran)  mouse_filter STOP ouvert, IGNORE fermé  → toucher = advance_requested
   └─ Panel (PanelContainer, variation DialogBox)   bas de l'écran, centré, largeur DIALOG_BOX_WIDTH
      └─ VBox
         ├─ Speaker (Label, variation DialogSpeaker) %Speaker   nom du locuteur, dans le panneau, au-dessus du texte ; caché si vide
         ├─ Text (Label) %Text        autowrap, texte clair, FONT_BODY, visible_characters
         └─ Continue (Control) %Continue   « › » en bas à droite, clignote (DIALOG_CONTINUE_BLINK)
signal advance_requested
signal closed
func open() -> void                                    # monte depuis le bas en 150–200 ms (DIALOG_OPEN) + fondu ; pas de « pop »
func show_page(speaker: String, text: String, narration: bool) -> void   # étiquette cachée si speaker vide
func set_visible_characters(count: int) -> void        # −1 = tout
func set_continue_visible(visible: bool) -> void
func close() -> void                                   # coroutine ; émet closed
func is_open() -> bool
```
Un toucher = **un seul** `advance_requested`. Sur Mac, un clic souris fait de même : `emulate_touch_from_mouse` est actif, sans double comptage. La narration (`narration = true`) passe en italique avec la variation de thème `DialogNarration` (Q7).

### 2.6 `GameState` (autoload)

`game/autoload/game_state.gd`, sans `class_name`, **un seul rôle en 3A** : tenir l'état de la session qui doit survivre aux changements de carte.
```gdscript
extends Node
var flags := StoryFlags.new()
func new_game() -> void        # flags.clear() ; appelé par Boot._ready
```
Pourquoi maintenant : les cartes sont libérées à chaque porte, mais « Maman a déjà parlé » doit survivre au va-et-vient, et 3B, 4 puis la sauvegarde liront ces drapeaux. `CLAUDE.md` et `godot-conventions` prévoient `GameState` pour ce rôle, et le jalon 2 l'annonçait pour le « premier drapeau d'histoire ». Il ne connaît aucun autre autoload. `DialogueRunner` reçoit `GameState.flags` par `setup` et ne lit pas l'autoload : il reste testable avec un `StoryFlags` neuf.

Drapeaux de 3A : `mom_greeted` et `rival_met`.

### 2.7 Premier dialogue automatique de Maman

La variante `auto` du dialogue `mom` (`unless: [mom_greeted]`, `set: [mom_greeted]`) se joue à la **première arrivée** au rez-de-chaussée. Le jeu démarre dans la chambre, donc c'est forcément la première descente.
- `InteractionController.on_map_entered(map)` parcourt `map.get_npcs()` dans l'ordre du fichier. Le **premier** PNJ interactif dont `runner.has_auto_variant(dialogue)` est vrai joue son dialogue. Le joueur se tourne vers lui (`player.face(...)`, axe dominant) et le PNJ vers le joueur (`begin_interaction`). Ensuite `runner.play(dialogue, npc, map, AUTO_DIALOGUE_DELAY)` avec `AUTO_DIALOGUE_DELAY = 0.35` s (Q1).
- Le joueur est bloqué **dans l'appel même** de `map_entered`, donc avant sa prochaine image. Avec le **doigt maintenu** (jalon 2 §2.3), il ne fait donc aucun pas au pied de l'escalier.
- Maman ne se déplace pas (Q1). À la fin, elle reprend son orientation. Le joueur « récupère immédiatement le contrôle » (dossier 02 §1).
- C'est une règle de données, pas un cas particulier du code : aucun `if npc == "mom"`.

### 2.8 Blocage des entrées : plusieurs raisons

Le routeur et les dialogues bloquent maintenant tous deux le joueur, et 3B ajoutera les scènes scriptées. Un seul booléen partagé serait fragile : un dialogue qui se termine pendant un fondu débloquerait le joueur. `Player` (modifié, T1) :
```gdscript
## Bloque ou débloque pour [param reason]. Le joueur est libre quand plus aucune raison n'est active.
func set_input_enabled(enabled: bool, reason: StringName = &"transition") -> void
func is_input_enabled() -> bool                    # aucune raison active
## Pivote sur place (à l'arrêt ; ignoré pendant un pas). Sert au dialogue automatique et aux scènes.
func face(direction: Vector2i) -> void
```
`SceneRouter` ne change pas : il utilise la raison par défaut `&"transition"`. `GridMover` gagne `face(direction)` public (pivot sans pas, émet `facing_changed`, ignoré en `MOVING`). La même raison ne s'empile pas : deux appels à `false` puis un seul à `true` suffisent à libérer.

HUD pendant un dialogue : `Boot` appelle `hud.set_controls_visible(false)`, qui cache joystick, courir et bouton contextuel et **relâche** leurs actions. `true` les rétablit à `dialogue_finished`. L'écran reste épuré (vision : presque aucune UI), et un toucher sur la boîte ne fait pas apparaître le joystick.

### 2.9 Tokens UI à ajouter (T2, `UiTokens`)

`DIALOG_BOX_WIDTH = 1400`, `DIALOG_BOX_MIN_HEIGHT = 200`, `DIALOG_MAX_LINES = 3`, `DIALOG_CHARS_PER_SECOND = 45.0` (Q11), `DIALOG_CONTINUE_BLINK = 0.5`, `DIALOG_BOTTOM_MARGIN = SAFE_MARGIN`, `INTERACT_BUTTON_CENTER_FROM_CORNER = Vector2(190, 360)` (d'après la planche : au-dessus et à droite du bouton courir ; à ajuster sur capture). `DIALOG_OPEN = 0.18` (montée depuis le bas, bible §3). Panneau **sombre translucide** (fond `SURFACE_DARK` à ~85 % d'opacité, coins doux), texte clair. Variations de thème `DialogBox`, `DialogSpeaker` et `DialogNarration` dans `tools/build_ui_theme.gd`. Icônes SVG vectorielles `assets/ui/icons/talk.svg` (bulle, comme la planche), `examine.svg` (loupe) et `observe.svg` (œil). Les libellés « PARLER / EXAMINER / OBSERVER » sont des constantes du composant de bouton (texte d'interface, pas de contenu de jeu).

### 2.10 Signaux et flux

```
Player (idle) ──cell, facing──► InteractionController ─► InteractionFinder.find(grid, table, cell, facing)
                                      │ target_changed(kind | -1)
                                      ▼
                                   Boot ─► ExplorationHud.show_interact(&"talk") / hide_interact()
[E] / InteractButton (action interact) ─► InteractionController ─► npc.begin_interaction(cell)
                                                                 ─► DialogueRunner.play(id, npc, map)
SceneRouter.map_entered ─► InteractionController.on_map_entered ─► (variante auto ?) play(…, delay)

DialogueRunner ─► Player.set_input_enabled(false, &"dialogue")
               ─► dialogue_started ─► Boot ─► hud.set_controls_visible(false)
               ─► DialogueBox.open / show_page / set_visible_characters / set_continue_visible
DialogueBox.advance_requested ──┐
[E] (interact juste pressé) ────┴► DialogueRunner ─► DialogueSession.advance()
               page : face_player ─► Npc.face_toward · react ─► GameMap.get_npc(id).react()
               fin : box.close ─► GameState.flags.set_flag(set…) ─► npc.end_interaction()
                     ─► Player.set_input_enabled(true, &"dialogue") ─► dialogue_finished ─► Boot ─► HUD
```
`GameMap`, `Npc`, `Player` et le HUD ne connaissent ni `DialogueRunner` ni `GameState`. `Boot` reste la seule racine de composition. `GameState` et `SceneRouter` ne se référencent pas.

### 2.11 Ce que 3B et 4 ajouteront sans rien casser

- **Plusieurs locuteurs** (§6 du dossier 02, « ??? ») : `speaker` par page, déjà lu et testé.
- **Scènes scriptées** (Chen qui arrête le joueur puis le ramène) : une future classe de séquence enchaîne `await runner.play(...)`, des déplacements de `Npc` (un `GridMover` par PNJ, déjà conçu pour occuper la grille) et `SceneRouter.change_map`. Le blocage passe par la raison `&"cutscene"`, ce qui donne « le joystick cesse brièvement de répondre ».
- **Déclencheur des hautes herbes** : le nœud `Triggers` des cartes existe déjà, sur le modèle des warps `STEP_ON`.
- **Présence conditionnelle** : clés `if` / `unless` ajoutées aux entrées de `data/npcs/*.json` (Chen au labo après 3B, rival au labo). C'est une extension de `NpcRoster`, sans rien casser.
- **« Rencontrer »** (jalon 4) : une valeur de plus dans `Interaction.Kind` et une icône de plus.

---

## 3. Données du jalon

### 3.1 PNJ et Pokémon du décor (`data/npcs/<map_id>.json`)

Tolérance **±2 cases** (±1 en intérieur), du moment que les invariants du §3.4 tiennent (Q5).

| Carte | id | Case | Orient. | sprite | dialogue | Remarques |
|---|---|---|---|---|---|---|
| `player_house_1f` | `mom` | (7, 4) | bas | `mom` | `mom` | case réservée du jalon 2, « près de la cuisine », variante `auto` |
| `rival_house` | `rival` | (13, 4) | droite | `rival` | `rival` | case réservée ; tourné vers son lit (sac, carte, affaires) ; `turn_to_player: false` |
| `oak_lab` | `maya` | (5, 3) | haut | `maya` | `maya` | devant les écrans (`lab_computers`, 4..5, 2) ; (8, 4) et (11, 6) restent **libres** |
| `oak_lab` | `bulbasaur` | (10, 5) | bas | `bulbasaur` | `observe_bulbasaur` | `verb: observe`, sur la table (case solide), `lift` ≈ 56 |
| `oak_lab` | `charmander` | (11, 5) | bas | `charmander` | `observe_charmander` | idem, ordre de la référence (gauche → droite) |
| `oak_lab` | `squirtle` | (12, 5) | bas | `squirtle` | `observe_squirtle` | idem |
| `pallet_town` | `aoki` | (29, 13) | gauche | `aoki` | `aoki` | bord est de la place, vers ses Roucool |
| `pallet_town` | `aoki_pidgey_1` | (27, 13) | droite | `pidgey` | — | non interactif (Q6) |
| `pallet_town` | `aoki_pidgey_2` | (28, 14) | haut | `pidgey` | — | non interactif ; (28, 13) reste libre (graines) |
| `pallet_town` | `leo` | (18, 9) | gauche | `leo` | `leo` | quartier résidentiel, le long de la clôture est du jardin du rival (x 16) |
| `pallet_town` | `leo_rattata` | (17, 9) | droite | `rattata` | — | non interactif, cible du `react` de Léo |
| `pallet_town` | `haru` | (9, 33) | bas | `haru` | `haru` | bout du ponton, face à la mer ; on lui parle depuis (9, 32) |

`player_house_2f` n'a aucun PNJ.

### 3.2 Points d'examen (`InteractPoint`, dans les tables des scripts de construction)

| Carte | Nœud | Ancre | `size` | `facing` | dialogue | Remarques |
|---|---|---|---|---|---|---|
| `player_house_1f` | `BreakfastTable` | (3, 5) | (3, 2) | tous | `breakfast_table` | la table à manger (3..5, 4..5) ; petit-déjeuner dessiné dessus (prop provisoire) |
| `rival_house` | `KantoMap` | (15, 4) | (2, 3) | tous | `rival_kanto_map` | carte dépliée **sur le lit**, avec le sac ouvert et des affaires : nouveau prop `bed_items` posé sur `bed_pokeball` (Q3) |
| `pallet_town` | `SignPallet` | (21, 13) | (1, 1) | tous | `sign_pallet_town` | le panneau existant |

Rien d'autre n'est examinable en 3A : aucun texte du dossier 02 pour la télé, le PC, les étagères, les boîtes aux lettres. On n'en invente pas.

### 3.3 Fichiers de dialogues (textes du dossier 02, **définitifs**)

`data/dialogues/player_house.json`
```json
{
	"mom": {
		"speaker": "Maman",
		"variants": [
			{
				"unless": ["mom_greeted"], "set": ["mom_greeted"], "auto": true,
				"pages": ["Bonjour ! Tu es enfin réveillé ?",
					"J'ai laissé quelque chose à manger sur la table."]
			},
			{ "pages": ["Tu sors ? Profite de cette belle journée.",
				"Et évite les hautes herbes, d'accord ?"] }
		]
	},
	"breakfast_table": { "narration": true, "pages": ["Ton petit-déjeuner est encore chaud."] }
}
```
`data/dialogues/rival_house.json`
```json
{
	"rival": {
		"speaker": "Rival",
		"variants": [
			{
				"unless": ["rival_met"], "set": ["rival_met"],
				"pages": [
					"Ah. Enfin réveillé.",
					{ "text": "T'as choisi ton jour pour faire la grasse matinée.", "face_player": true },
					{ "text": "Moi, je suis prêt.", "pause": 0.8 }
				]
			},
			{ "pages": ["Quoi ?", "Va faire un tour. Tu comprendras."] }
		]
	},
	"rival_kanto_map": {
		"narration": true,
		"pages": ["Une carte de Kanto.", "Plusieurs villes ont été entourées au crayon."]
	}
}
```
`data/dialogues/oak_lab.json`
```json
{
	"maya": {
		"speaker": "Maya",
		"pages": [
			"Bonjour ! Tu cherches le professeur Chen ?",
			"Il est sorti tôt ce matin. Encore.",
			{ "text": "Quand il commence à observer des Pokémon, il oublie complètement l'heure.",
				"pause": 0.6 }
		]
	},
	"observe_bulbasaur": { "speaker": "Bulbizarre", "narration": true,
		"pages": [{ "text": "Il t'observe calmement.", "react": "bulbasaur" }] },
	"observe_charmander": { "speaker": "Salamèche", "narration": true,
		"pages": [{ "text": "Sa flamme s'agite lorsqu'il te voit.", "react": "charmander" }] },
	"observe_squirtle": { "speaker": "Carapuce", "narration": true,
		"pages": [{ "text": "Il te regarde avec curiosité.", "react": "squirtle" }] }
}
```
`data/dialogues/pallet_town.json`
```json
{
	"aoki": { "speaker": "Mme Aoki", "pages": ["Ils reviennent tous les matins.",
		"Je crois qu'ils savent exactement à quelle heure je sors."] },
	"leo": { "speaker": "Léo", "pages": [
		"Regarde ! Il commence à comprendre quand je l'appelle !",
		{ "text": "...enfin, presque.", "react": "leo_rattata", "pause": 0.6 }] },
	"haru": { "speaker": "Haru", "pages": ["La mer est calme aujourd'hui.",
		"Les Pokémon le sentent avant nous."] },
	"sign_pallet_town": { "draft": true, "pages": ["BOURG PALETTE"] }
}
```
- Nom affiché du rival : « Rival », comme dans le dossier 02, en attendant son prénom (Q13).
- Le **seul texte provisoire** est celui du panneau (`draft: true`, Q8).
- Réactions (`react`) : bond de Rattata ; flamme qui s'agite (Salamèche) ; petit mouvement de tête pour Bulbizarre et Carapuce (Q6).
- Maya et les habitants répètent la même réplique : le dossier n'en donne pas d'autre (Q14).

### 3.4 Invariants (testés, T4)

Pour **chaque carte** qui a des PNJ :
- chaque entrée de `data/npcs/<map_id>.json` se charge sans erreur. Sa case est dans la carte, n'est **ni** un warp **ni** un spawn, et est praticable, **sauf** pour un Pokémon posé sur un meuble (`lift > 0`) ;
- **aucune poche** : avec les PNJ en place, `find_reachable` depuis le spawn de référence (`entrance`, `stairs` ou `start`) couvre toutes les cases praticables **non occupées**. Les invariants des jalons 1 et 2 restent vrais. Les « cases réservées » du jalon 2 deviennent « occupées par le bon PNJ », sauf (8, 4) et (11, 6) au labo, qui restent **libres et atteignables** ;
- **chaque cible est utilisable** : pour chaque PNJ interactif et chaque `InteractPoint`, il existe une case atteignable voisine d'où `InteractionFinder.find` (le vrai) renvoie ce dialogue avec le bon verbe.

**Données globales** (`tests/integration/test_dialogue_data.gd`) :
- `DialogueLibrary.load_dir()` sur `data/dialogues/` : aucune erreur ;
- chaque `dialogue` de PNJ et chaque `dialogue_id` d'`InteractPoint` existe ; chaque `react` vise un PNJ **de la carte** où le dialogue est utilisé ;
- chaque drapeau lu par une condition est levé par au moins un `set` ;
- chaque page de chaque variante tient en `DIALOG_MAX_LINES` lignes dans la vraie `DialogueBox` à 1920 × 1080 (police du thème) ;
- les dialogues `draft` sont exactement ceux attendus (aujourd'hui : `sign_pallet_town`).

---

## 4. Découpage des tâches (dans l'ordre)

### T1 — constructeur-monde : `GameState`, blocage par raisons, scène `Npc`, PNJ et points d'examen dans `GameMap`
- `game/autoload/game_state.gd` + entrée `[autoload]` ; `Player.set_input_enabled(enabled, reason)`, `Player.face()`, `GridMover.face()` (§2.8) ; `InteractPoint` ; `Npc` (§2.3, avec un sprite provisoire générique pour T1) ; `GameMap` : `npcs_dir`, création des PNJ, `get_npcs`, `get_npc`, `get_interactions` ; nœud `Interactables` (vide) ajouté aux 6 cartes par les scripts de construction (régénérées).
- **CA** :
  - `test_player.gd` : bloqué pour `&"transition"` puis `&"dialogue"` ; libérer `&"dialogue"` laisse le joueur bloqué, libérer les deux le rend libre. `set_input_enabled(false)` deux fois pour la même raison, puis `true` une fois : libre. `face(LEFT)` à l'arrêt pivote sans pas et émet `facing_changed` ; pendant un pas, rien. Les tests du routeur (`test_scene_router.gd`) restent verts **sans modification**.
  - `test_grid_mover.gd` : `face()` à l'arrêt, ignoré en `MOVING`, sans `bumped`.
  - `test_game_map.gd` (mini-carte, `npcs_dir = "res://tests/fixtures/npcs/"`, `map_id = &"sample_map"`) : 4 `Npc` dans `Entities`, chacun sur sa case et **occupant** la grille (`get_occupant`), `get_npc(&"rival")`. Le Pokémon `lift` 56 a un sprite remonté de 56 px, sans changement de case. `get_interaction()` du Roucool est null. Un `InteractPoint` 3 × 2 donne 6 interactions dans `get_interactions()`. Deux points en conflit : `push_error` attendu. Carte sans fichier : aucun PNJ, aucune erreur.
  - `tests/integration/test_npc.gd` : `face_toward` (axe dominant, 4 cas), `begin_interaction` / `end_interaction` avec `turn_to_player` et `keep_facing`, `react()` sans erreur même sans animation `react`. `get_interaction()` rend **la même instance** à chaque appel.
  - `GameState.new_game()` vide les drapeaux ; aucune référence à `SceneRouter`.
  - Import sans erreur ; `tools/test.sh` vert.

### T2 — ui-mobile : boîte de dialogue 2026, bouton contextuel
- `DialogueBox` (§2.5), `InteractButton` dans `ExplorationHud` : `show_interact(verb: StringName)`, `hide_interact()`, `set_controls_visible(visible)`. Tokens, variations de thème, 3 icônes SVG (§2.9). **Aucune** référence au joueur, à la carte, aux données ou aux classes de dialogue dans `game/ui/`.
- **CA** :
  - `tests/integration/test_dialogue_box.gd` : layer 30. Fermée, elle est invisible et en `mouse_filter` IGNORE. `open()` puis `show_page("Maman", …, false)` : nom du locuteur visible avec « Maman ». Avec `speaker` vide, pas de nom. `set_visible_characters(5)` affiche 5 caractères, −1 tout. « › » visible seulement après `set_continue_visible(true)`. **Un** `InputEventScreenTouch` pressé donne **un** `advance_requested` ; fermée, zéro. `await close()` émet `closed`. Largeur `DIALOG_BOX_WIDTH` et marges `SAFE_MARGIN` respectées à 1920 et à 2340 de large. Narration : variation `DialogNarration`.
  - `test_exploration_hud.gd` : bouton contextuel invisible au départ, puis visible après `show_interact(&"talk")` avec le libellé PARLER (EXAMINER, OBSERVER pour les autres verbes). `hide_interact()` le cache en ≤ `ANIM_MICRO` + 1 image. `action == "interact"`, centre à `INTERACT_BUTTON_CENTER_FROM_CORNER` du coin bas-droit, dans `SAFE_MARGIN`, zone touchable ≥ `TOUCH_MIN`, sans chevaucher le bouton courir. `set_controls_visible(false)` cache joystick, courir et contextuel et relâche `run`, `interact` et `move_*`.
  - Capture Movie Maker (outil `tools/capture_hud.gd` étendu) de la boîte ouverte avec « Maman » et sa première réplique, à 2340 × 1080, lue avec Read : conforme à la bible UI/UX §3 (panneau sombre translucide, nom au-dessus du texte dans le panneau, « › », pas de portrait, texte très lisible).
  - Couleurs, tailles et durées uniquement via `UiTokens`.

### T3 — constructeur-monde : `DialogueRunner`, `InteractionController`, câblage de `Boot`
- `dialogue_runner.gd` (§2.5), `interaction_controller.gd` (§2.2, §2.7), `Boot` (§2.1).
- **CA** :
  - `tests/integration/test_dialogue_runner.gd` (vraie `DialogueBox`, `StoryFlags` neuf, fixtures `tests/fixtures/dialogues/`, `chars_per_second` réglable) : `play(&"mom")` bloque le joueur **dans la même image**, émet `dialogue_started`, puis la boîte affiche « Maman » et la page 1. Deux avances (compléter, suivante), puis deux de plus : `dialogue_finished`, `mom_greeted` levé **avant** le signal, joueur libéré. Un second `play(&"mom")` joue la variante 2. Id inconnu : `false` et `push_error`. `play` pendant un dialogue : `false`. `react` sur la page de Léo appelle `react()` sur le bon `Npc`. `face_player` tourne le PNJ au début de **cette** page seulement. `pause` : aucun caractère avant la fin du silence. Un blocage `&"transition"` actif à la fin du dialogue laisse le joueur bloqué.
  - `tests/integration/test_interaction_controller.gd` (mini-carte avec PNJ et point fixe) : face au PNJ, `target_changed(TALK)` une seule fois. En se détournant, `target_changed(-1)`. Pendant un pas ou un dialogue : pas de cible. `Input.action_press(&"interact")` joue le bon dialogue et le PNJ se tourne vers le joueur. **Anti-rebond** : `interact` tenu à la fin du dialogue ne le relance pas ; il faut relâcher puis réappuyer. Variante `auto` : `on_map_entered` bloque le joueur dans l'appel, les deux se font face, et la boîte s'ouvre après `AUTO_DIALOGUE_DELAY`. Pas de relance à l'arrivée suivante.
  - `test_boot.gd` : `GameState` vide au démarrage, bibliothèque chargée sans erreur, pas de dialogue dans la chambre.
  - `test_opening_walk.gd` étendu : chambre, escalier, puis **Maman parle d'elle-même** (le joueur ne bouge pas pendant le dialogue, même `move_down` tenu). On avance le dialogue jusqu'au bout, on marche vers la sortie, on ressort. On revient, on parle à Maman : réplique « Tu sors ? … ».

### T4 — constructeur-monde : contenu 3A (PNJ, Pokémon, textes, points d'examen)
- `tools/gen_placeholder_npcs.gd` (§2.3) ; `data/npcs/*.json` (§3.1) ; `data/dialogues/*.json` (§3.3, **textes exacts du dossier 02**) ; `InteractPoint` et props `bed_items` / `breakfast` dans `build_interiors.gd` et `build_pallet_town.gd` (§3.2), cartes régénérées ; `test_interiors.gd` : les cases réservées deviennent occupées (§3.4).
- **CA** :
  - `tests/integration/test_npc_placement.gd` et `test_dialogue_data.gd` : tous les invariants du §3.4.
  - Les invariants des jalons 1 et 2 restent verts (`test_pallet_town.gd`, `test_interiors.gd`, `test_map_links.gd`).
  - **Export** : `tools/build_android.sh`, puis `data/dialogues/*.json` et `data/npcs/*.json` présents dans l'APK (`unzip -l`). Sinon, `include_filter` à ajouter (§2.4).
  - Scénario `npcs` de `tools/capture_play.gd` : Maman qui parle d'elle-même, table examinée, rival (page 1, puis page 2 tourné vers le joueur), carte de Kanto, Maya, les trois starters observés (Salamèche en réaction), Mme Aoki et ses Roucool, Léo (Rattata en réaction), Haru, panneau. Une capture par étape à 2340 × 1080, lue avec Read : sprites nets (NEAREST), bouton contextuel avec le bon libellé, étiquette de nom correcte, texte en 3 lignes au plus, aucun sprite coupé par le bord de la carte (Haru).

### T5 — qa-mobile : validation sur S24
- Checklist `android-deploy` : tests, import, `tools/deploy_s24.sh`, logcat.
- **CA à vérifier et rapporter** :
  - Première descente : Maman parle d'elle-même, sans qu'on puisse bouger, même en gardant le doigt sur le joystick depuis la chambre. Ensuite, contrôle rendu. Lui reparler donne la seconde réplique, **y compris** après être sorti et rentré.
  - Chaque PNJ et chaque point du §3 : le bouton apparaît **seulement** face à la cible, avec le bon libellé. Un toucher lance le dialogue. Le texte s'écrit, un toucher complète la page, un autre passe à la suivante, puis la boîte se ferme. Aucun dialogue ne se relance tout seul.
  - Mise en scène : le rival ne se tourne qu'à sa deuxième réplique, puis retourne à ses affaires. Silence avant « Moi, je suis prêt. ». Rattata réagit avant « ...enfin, presque. ». La flamme de Salamèche s'agite. Les starters ne se prennent pas.
  - Pendant un dialogue : joystick, courir et bouton contextuel cachés ; le joueur ne bouge pas. Pas de dialogue possible pendant un fondu.
  - Lisibilité sur le S24 : taille du texte, contraste du panneau translucide sur les décors clairs, nom du locuteur, « › ». Rien sous l'encoche ni hors de `SAFE_MARGIN`. Le bouton contextuel ne gêne pas le pouce sur le bouton courir.
  - 60 fps en dialogue et dans le village avec tous les PNJ (ou « non vérifié »). Changement de carte toujours < 100 ms (création des PNJ comprise). Aucune erreur dans logcat, notamment aucune de `DialogueLibrary` ni de `NpcRoster`.

---

## 5. Hypothèses et questions pour Kevin

Hypothèses techniques (pas de décision de design) :
- PNJ dans `data/npcs/` (données, présence conditionnelle future), points d'examen dans les scènes de carte comme les warps (ils suivent le mobilier des scripts de construction).
- JSON pour les données de 3A ; validation stricte au chargement et dans les tests.
- `GameState` minimal : les drapeaux de la session seulement, sans sauvegarde (confirmé par Kevin pour 3A).
- Blocage des entrées par raisons (`transition`, `dialogue`, plus tard `cutscene`).
- Les Pokémon du décor sont des PNJ à sprite de Pokémon, sans aucun lien avec le futur système Pokémon.

**Décisions de Kevin (2026-09-26)** : les propositions par défaut ci-dessous sont **toutes acceptées**, avec deux précisions venues de la bible UI/UX (`docs/design/ui-ux-bible-v0.1.md`) :
- **Q10** : boîte de dialogue **sombre et translucide, sans portrait**, nom du locuteur dans le panneau au-dessus du texte, « › », montée depuis le bas en 150–200 ms (la bible remplace la planche sur ce point ; l'étiquette bleue et le ▼ sont abandonnés).
- **Q9** : bouton contextuel **face à la cible seulement**, un seul bouton en bas à droite ; l'état **Prendre** est prévu dans le composant (icône, libellé) mais n'est utilisé par aucune donnée en 3A.
- Q8 : panneau « BOURG PALETTE » seul, provisoire (`draft`) ; Q13 : « Rival ».
- Bible §11 : aucun marqueur au-dessus des PNJ, aucun journal de quête à l'écran. Le bouton Courir reste.

Rappel des questions (proposition retenue entre parenthèses) :

1. **Premier dialogue de Maman** : il se déclenche dès l'arrivée au rez-de-chaussée, environ 0,35 s après le fondu. Maman reste à sa place (elle ne s'approche pas), elle et le joueur se tournent l'un vers l'autre. (*Oui*.)
2. **Découpage en pages** : une réplique « … » du dossier = une boîte. Les didascalies ne s'affichent pas, elles deviennent de la mise en scène (se tourner, silence d'environ 0,6 à 0,8 s, réaction). (*Oui*.)
3. **Carte de Kanto du rival** : dépliée **sur son lit**, avec le sac ouvert et quelques affaires, et examinable depuis le bord du lit. Autre choix : au mur au-dessus de son bureau. (*Sur le lit*, qui rejoint « affaires posées sur le lit ».)
4. **Après un dialogue**, chacun reprend son orientation, c'est-à-dire « retourne à ses affaires ». Pour le rival, on ne se retourne vers le joueur qu'à « T'as choisi ton jour… ». Pour la reprise « Quoi ? », il reste tourné vers ses affaires. (*Oui aux deux*.)
5. **Positions et orientations** (§3.1) : Maman à droite de la table (case réservée), rival sur le tapis de sa chambre tourné vers son lit, Maya devant les écrans du labo (de dos), starters de gauche à droite comme sur la référence, Mme Aoki au bord est de la place, Léo le long de la clôture du jardin du rival, Haru au bout du ponton. (*Validées telles quelles, à ajuster après l'essai sur S24*.)
6. **Pokémon du décor** : **2 Roucool** près de Mme Aoki. Roucool et Rattata sont immobiles avec une petite animation (picorer, respirer), bloquent leur case et ne sont pas interactifs (le dossier ne leur donne pas de texte). Les starters jouent une petite réaction quand on les observe (flamme pour Salamèche, mouvement de tête pour les deux autres). Rien ne s'envole encore. (*Oui*.)
7. **Style de la narration** (Examiner, Observer) : texte en italique. Pas d'étiquette pour un objet ; étiquette avec le nom du Pokémon pour Observer (« Bulbizarre »). (*Oui*.)
8. **Texte du panneau** « BOURG PALETTE » : le dossier 02 n'en donne pas. Provisoire : « BOURG PALETTE » seul (marqué `draft`). Quel texte veux-tu ? Aucun autre panneau n'est lisible en 3A (maisons, labo). (*Provisoire en attendant ton texte*.)
9. **Bouton contextuel** : il apparaît seulement quand le joueur est **face** à la cible (la case devant lui). Rond comme sur la planche (bulle, loupe, œil), avec le verbe en toutes lettres dans une petite étiquette à sa gauche : PARLER, EXAMINER, OBSERVER. Autre choix : il apparaît dès qu'une cible est **à côté** et le joueur se tourne tout seul, plus tolérant au pouce, mais le bouton clignoterait en longeant les PNJ. (*Face seulement, avec l'étiquette*.)
10. **Boîte de dialogue** : en bas de l'écran comme sur la référence UI, avec l'étiquette de nom bleue (« Maman ») comme sur le storyboard, plutôt qu'une bulle au-dessus du PNJ. Pas de portrait en 3A (ils viendront avec la DA des personnages). (*Oui*.)
11. **Vitesse du texte** : environ 45 caractères par seconde. Un toucher complète la page, le suivant passe à la page d'après, et le toucher marche n'importe où sur l'écran. (*Oui* ; un réglage de vitesse pourra venir avec les Options.)
12. **Routines** : aucune en 3A. Les PNJ restent sur leur case avec une animation d'attente ; les routines selon l'heure viendront avec `GameClock` (phase 10). (*Oui*.)
13. **Nom du rival** dans l'étiquette : « Rival » en attendant son prénom (et celui du joueur), à décider pour le jalon « ouverture » ? (*« Rival » pour 3A*.)
14. **Répliques répétées** : Maya, Mme Aoki, Léo et Haru redisent la même chose à chaque fois (le dossier ne donne qu'une version). (*Oui*.)
