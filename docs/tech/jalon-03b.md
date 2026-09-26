# Jalon 3B — L'événement de la Route 1 : le Prof. Chen ramène le joueur au labo

> Objectif jouable sur le S24 : le joueur a exploré Bourg Palette. Il monte vers le nord par la prairie, où un **Roucool** et un **Rattata** vivent leur vie, jusqu'aux **hautes herbes** qui ferment le chemin de la Route 1. Sur la case juste avant les herbes, le **joystick cesse de répondre**, sans écran noir. Une voix arrive de derrière : **« ??? — Hé ! Attends ! »**. Le personnage se retourne. Le **Prof. Chen** arrive en courant depuis le village, s'arrête à côté de lui, reprend son souffle, puis parle (il regarde les herbes à sa deuxième réplique, et laisse un silence avant « ...Viens avec moi. »). Il repart vers le village, le joueur le **suit tout seul** quelques secondes, puis un fondu les amène au **laboratoire**. Le **rival est déjà là**. Il regarde Chen, puis le joueur : « Enfin. » / « Un peu de patience. » / « Ça fait une heure que tu dis ça. » / « Et pourtant, tu es toujours là. ». Le joueur récupère alors le contrôle : **le jalon 3 s'arrête là**.
>
> Ensuite, le joueur explore librement Bourg Palette. **Maya** a une nouvelle réplique (« Ah, le professeur est revenu. »…). Le rival n'est plus chez lui. Les **hautes herbes restent fermées** tant qu'il n'a pas de Pokémon : sur la case juste avant, il s'arrête, pense *« Je ne devrais pas aller là sans Pokémon. »* et recule d'un pas (Q19).
>
> Pas d'« OBJECTIF MIS À JOUR », pas de marqueur, pas de bandes noires. Du gel à la dernière réplique, les contrôles tactiles sont cachés, comme pendant un dialogue de 3A. Les répliques passent par la **boîte de dialogue 2026** de 3A.
>
> C'est le jalon 3B du dossier 02 (§5, arrivée du §6 et « Ajouts de Kevin »). Il termine la phase 3 « Interactions » : c'est le premier **événement scripté** du jeu.

**Pré-requis** : le jalon 3A ([`jalon-03.md`](jalon-03.md)) est terminé, validé sur le S24 et dans `main` (commit `dad5d5a`, 513 tests). Le plan ci-dessous est **aligné sur ce code** (§8) : noms et signatures sont ceux du dépôt.

**Hors périmètre** :
- **Jalon 4** (dossier 02 §6 suite à §10) : « Vous voulez tous les deux découvrir Kanto… », choix du starter, « Rencontrer », fiche légère, choix du rival, premier combat. Le 3B pose seulement les **points d'accroche** (§2.11), dont le drapeau `has_starter` qui rouvrira les herbes.
- **Carte de la Route 1** (phase 9) : les hautes herbes du 3B sont au bord nord de Bourg Palette, sur le chemin qui y mène. Pas de nouvelle carte.
- **Rencontres sauvages** et système Pokémon : les herbes sont une tuile de décor et une donnée (`tall_grass`), sans aucune rencontre. L'effet « jambes cachées dans l'herbe » vient avec les rencontres.
- **Sauvegarde** : comme en 3A, l'état vit dans `GameState` sans sauvegarde. Quitter l'application recommence la partie (Q14).
- Caméra qui se déplace seule, bandes cinéma, sons, musique d'événement, vibrations, portraits.
- Choix oui/non, embranchements **à l'intérieur** d'une scène, scènes qui tournent en parallèle d'autres scènes.
- Rendu « vraie DA » de Chen, des herbes et des Pokémon de la prairie : sprites et tuiles provisoires aux dimensions finales.

Références : `CLAUDE.md`, **`docs/design/dossier-02-prologue.md` §5, §6 et « Ajouts de Kevin » (source de vérité des textes et des intentions)**, `docs/design/dossier-01-bourg-palette.md` (§6 Prairie du Nord, « Déroulé d'ouverture » point 4), `docs/design/ui-ux-bible-v0.1.md` §3 et §11, `docs/design/vision.md`, [`jalon-01.md`](jalon-01.md) §4, [`jalon-02.md`](jalon-02.md) §2.2 et §4.7, [`jalon-03.md`](jalon-03.md) (architecture de 3A), skills `godot-conventions`, `world-tiles` et `ui-theme-2026`.

---

## 1. Fondations logiques (architecte) — **posées et testées**

Classes pures et extensions des classes pures de 3A, sans scène. **572 tests verts** (513 de 3A + 59). Rien dans les scènes, les nœuds présentés ni `data/` : c'est le travail de T1 à T4.

| Fichier | `class_name` | Ce qui existe maintenant |
|---|---|---|
| `game/world/grid.gd` (ajout) | `Grid` | `direction_from_name(name: String) -> Vector2i` (`"up"`… ; ZERO si inconnu), `is_direction_name(name) -> bool`, `direction_name(dir) -> StringName` (`&""` si non cardinale), `dominant_direction(from, to) -> Vector2i` (axe dominant, vertical à égalité, ZERO sur la même case : règle unique de « se tourner vers »). |
| `game/world/grid_world.gd` (ajout) | `GridWorld` | `is_free(cell, mover = null) -> bool` : on peut **s'y tenir** (dans la carte, ni solide, ni eau, ni rebord, libre ou occupée par `mover`). `find_path(from, to, mover = null) -> Array[Vector2i]` : plus court chemin à pied (parcours en largeur), en **liste de directions** (un saut de rebord = une direction). Mêmes règles que `get_step_target`. Ordre haut, bas, gauche, droite : chemin reproductible. Vide si `from == to`, hors carte ou inaccessible. Alloue : au début d'un déplacement seulement. |
| `game/world/grid_mover.gd` (ajout) | `GridMover` | `start_step(direction, run = false) -> bool` : pas **scripté**, **même verrouillé**. Se tourne vers `direction` et part. Case inaccessible : faux, tourné, **sans** `bumped`. Faux pendant un pas ou pour une direction non cardinale. Annule un pivot en attente. Le pas se termine dans `update()` (`step_finished`) ; verrouillé, `update()` n'en enchaîne pas d'autre. La case quittée est libérée **dès le départ** (déjà vrai en 3A, `move_occupant`) : un suiveur peut y entrer dans la même image. |
| `game/world/npc/npc_spec.gd` (ajout) | `NpcSpec` | `if_flags`, `unless_flags`, `is_present(flags: StoryFlags) -> bool` (null = nouvelle partie), `is_conditional()`. Documenté **en lecture seule** : un PNJ qui marche garde sa case courante dans son `GridMover`, `spec.cell` reste sa case de départ. |
| `game/world/npc/npc_roster.gd` (ajout) | `NpcRoster` | Clés `if` et `unless` (listes non vides de drapeaux). `static parse_entry(value: Variant, errors: PackedStringArray) -> NpcSpec` : validation d'**une** entrée ; ajoute ses messages à `errors` **sans préfixe ni `push_error`** (l'appelant les situe et les signale) ; ne lit pas l'identifiant. `static is_cell(value) -> bool`. `KEYS` (public). `PLAYER_ID = &"player"` : identifiant **réservé** (refusé dans un fichier). `get_present(flags) -> Array[NpcSpec]` (ordre du fichier). La conversion des directions passe par `Grid` (l'ancien `_FACINGS` privé est supprimé). |
| `game/systems/dialogue/dialogue_page.gd` (ajout) | `DialoguePage` | `turn: Dictionary[StringName, StringName]` : acteur → cible, **dans l'ordre du fichier** (§2.7). |
| `game/systems/dialogue/dialogue_library.gd` (ajout) | `DialogueLibrary` | Clé de page `turn` : objet non vide, acteurs et cibles = textes non vides, un nom de direction n'est pas un acteur. Qu'une cible désigne un vrai PNJ se vérifie dans les tests de données (§3.6). |
| `game/world/triggers/event_trigger.gd` | `EventTrigger` | `EventTrigger.new(cell, direction = ZERO, cutscene_id = &"")`, `is_valid()`, `matches_step(cell, direction)`. Calqué sur `Warp` en `STEP_ON`. Aucune condition : c'est la scène qui décide. |
| `game/world/triggers/trigger_table.gd` | `TriggerTable` | Calquée sur `WarpTable` : `add` refuse une entrée invalide ou ambiguë (même case, directions qui se recouvrent), `find_on_step(cell, direction) -> EventTrigger`, `get_at`, `get_all`, `size`, `is_empty`. |
| `game/systems/cutscene/cutscene_step.gd` | `CutsceneStep` | `enum Kind { WAIT, DIALOGUE, FACE, SET_FLAGS, SPAWN, MOVE, CHANGE_MAP }`, `TYPE_KEYS` (clés de type des fichiers, dans l'ordre de `Kind`), `NO_CELL = (-1, -1)`. Champs typés : `seconds`, `dialogue_id`, `actor`, `target`, `flags`, `spec: NpcSpec`, `path: Array[Vector2i]`, `cell`, `near`, `offsets`, `run`, `follower`, `map_id`, `spawn`, `facing`. `has_destination()`, `static kind_name(kind)`. |
| `game/systems/cutscene/cutscene_variant.gd` | `CutsceneVariant` | `if_flags`, `unless_flags`, `steps: Array[CutsceneStep]`, `matches(flags)`. |
| `game/systems/cutscene/cutscene.gd` | `Cutscene` | `id`, `source`, `variants: Array[CutsceneVariant]`, `pick(flags) -> CutsceneVariant` (**première** qui s'applique, comme `Dialogue.pick`), `matches(flags)`. |
| `game/systems/cutscene/cutscene_library.gd` | `CutsceneLibrary` | `DATA_DIR = "res://data/cutscenes/"`. `load_dir`, `load_file`, `add_from_dict`, `has_cutscene`, `get_cutscene`, `get_ids`, `size`, `get_errors`, `get_condition_flags`, `get_set_flags`, `get_dialogue_ids` (dialogues joués par des étapes). Validation stricte (clé inconnue, type d'étape absent ou multiple, paramètre manquant ou mal typé, direction inconnue, case ou décalage invalide, `spawn` validé par `NpcRoster.parse_entry`, identifiant en double entre fichiers, JSON illisible avec le numéro de ligne). Une scène invalide est **écartée entière**. Format complet en tête du fichier et au §2.3. |
| `game/systems/cutscene/cutscene_moves.gd` | `CutsceneMoves` | `static resolve_near(grid, anchor, offsets, mover = null) -> Vector2i` : première case `anchor + offset` où `grid.is_free(…, mover)`, `NO_CELL` sinon. `static follow_path(follower_cell, leader_cell, leader_path) -> Array[Vector2i]` : un pas vers la case du meneur, puis ses pas sauf le dernier (vide s'ils ne sont pas voisins ou si le meneur ne bouge pas). `static path_cells(from, path) -> Array[Vector2i]` (tests de données). |

Tests : `tests/unit/test_grid.gd`, `test_grid_world.gd`, `test_grid_mover.gd`, `test_dialogue_library.gd`, `test_npc_roster.gd` (étendus) ; `test_event_trigger.gd`, `test_cutscene_library.gd`, `test_cutscene_moves.gd` (nouveaux) ; données d'essai `tests/fixtures/cutscenes/prologue.json` (toutes les étapes, deux variantes) et `short.json` (destination absolue, `if`, `change_map` sans `facing`). Les cas d'erreur sont écrits dans les tests (`add_from_dict`), comme pour les dialogues.

---

## 2. Architecture

### 2.1 Arbre des scènes et câblage de `Boot`

```
game/boot.tscn
Boot (Node)  game/boot.gd                   racine de composition (câblage seulement)
├─ World (Node2D)               %World
├─ ExplorationHud (instance)    %ExplorationHud     inchangé depuis 3A
├─ DialogueBox (instance)       %DialogueBox        inchangée depuis 3A
├─ DialogueRunner (Node)        %DialogueRunner     + clé de page `turn` (§2.7)
├─ InteractionController (Node) %InteractionController  + une garde dans on_map_entered (§2.4)
├─ CutsceneDirector (Node)      %CutsceneDirector   game/systems/cutscene/cutscene_director.gd (nouveau, T2)
└─ ScreenFade (instance)        %ScreenFade

Autoloads : SceneRouter (une garde de plus, §2.4) · GameState (inchangé ; drapeaux du §2.8)
```

Structure d'une carte : le nœud **`Triggers`** (Node2D) existe déjà dans les 6 cartes, vide. Il reçoit des `EventTriggerPoint` (§2.2), écrits par les scripts de construction comme les `WarpPoint` et les `InteractPoint`.

`Boot._ready` (changements par rapport au code de 3A) :
```gdscript
@onready var _cutscenes_node: CutsceneDirector = %CutsceneDirector
var _cutscenes := CutsceneLibrary.new()

func _ready() -> void:
	GameState.new_game()
	_player = PLAYER_SCENE.instantiate() as Player
	_library.load_dir()
	_cutscenes.load_dir()                                     # data/cutscenes/
	_runner.setup(_library, GameState.flags, _dialogue_box, _player)
	_interactions.setup(_player, _runner)
	_cutscenes_node.setup(_cutscenes, GameState.flags, _runner, _player, SceneRouter)
	# … signaux de 3A (target_changed, dialogue_started, dialogue_finished) …
	_cutscenes_node.cutscene_started.connect(_on_cutscene_started)
	_cutscenes_node.cutscene_finished.connect(_on_cutscene_finished)
	SceneRouter.setup(_world, _player, _fade)
	SceneRouter.transition_started.connect(_on_transition_started)
	# 3A : SceneRouter.map_changed.connect(_interactions.set_map). 3B passe par Boot pour
	# garantir l'ordre : présence des PNJ d'abord, puis les contrôleurs.
	SceneRouter.map_changed.connect(_on_map_changed)
	SceneRouter.map_entered.connect(_on_map_entered)
	SceneRouter.map_entered.connect(_interactions.on_map_entered)
	SceneRouter.start(start_map, start_spawn, start_facing)   # tout est branché AVANT start

func _on_map_changed(map: GameMap) -> void:
	map.refresh_npcs(GameState.flags)            # §2.6 (T4)
	_interactions.set_map(map)
	_cutscenes_node.set_map(map)

func _on_cutscene_started(_id: StringName) -> void:
	_refresh_controls()

func _on_cutscene_finished(_id: StringName) -> void:
	_refresh_controls()

## Contrôles visibles seulement hors dialogue et hors scène. 3A les rétablissait à
## dialogue_finished : pendant une scène, ils doivent rester cachés entre deux dialogues.
func _refresh_controls() -> void:
	_hud.set_controls_visible(not _runner.is_running() and not _cutscenes_node.is_running())
```
- `_on_dialogue_started` / `_on_dialogue_finished` de 3A appellent `_refresh_controls()` au lieu de `set_controls_visible(false/true)`.
- `_exit_tree` débranche aussi `map_changed → _on_map_changed` (la liste `links` de 3A contient aujourd'hui `_interactions.set_map` : à remplacer).
- Accesseurs pour les tests et les outils de capture : `get_cutscene_director()`, `get_cutscene_library()`.
- `data/cutscenes/` doit exister dès T2 : `load_dir` signale un dossier absent par `push_error`.

### 2.2 Hautes herbes et déclencheur

**Tuile** : `OverworldTiles.Kind.TALL_GRASS`, ajoutée **en fin d'enum** (après `SHALLOW` : les rangées d'atlas des autres types ne bougent pas), 2 variantes dans `VARIANTS`, praticable, donnée `tall_grass = true` (la couche `DATA_TALL_GRASS` existe depuis le jalon 1, jamais utilisée). `GridWorld` ne la lit pas : les rencontres (jalon 5) le feront. Tuile provisoire : herbe plus haute et plus sombre que l'herbe rase, brins lisibles à l'écran (Q16).

**Déclencheur** : `EventTriggerPoint` (`game/world/triggers/event_trigger_point.gd`, `extends Marker2D`), enfant de `Triggers`, sur le modèle exact d'`InteractPoint` :
```gdscript
class_name EventTriggerPoint
extends Marker2D                    # position = Grid.cell_to_world(case d'ancrage)
@export var cutscene_id: StringName = &""
## Cases couvertes depuis l'ancre (bas-gauche) : x 0..size.x-1, y -(size.y-1)..0.
@export var size: Vector2i = Vector2i.ONE
## Direction du pas qui arrive sur la case (ZERO = toutes).
@export var direction: Vector2i = Vector2i.ZERO
func get_cell() -> Vector2i                      # Grid.world_to_cell(position)
func get_cells() -> Array[Vector2i]              # comme InteractPoint.get_cells
func to_triggers() -> Array[EventTrigger]        # un par case couverte
```
`GameMap` (modifié) construit `get_triggers() -> TriggerTable` dans `_build_grid`, comme `_build_warps` et `_build_interactions` (champ `_triggers`, reconstruit par `rebuild_grid`). Une entrée refusée : `push_error("GameMap <id> : déclencheur invalide en <case>")`, une seule erreur par point (même règle qu'`_build_interactions`).

Le déclencheur ne porte **aucune condition** : ce sont les **variantes** de la scène (§2.3) qui décident. Sur la Route 1, une seule scène `route1_grass` : première variante = l'interception de Chen (`unless: [oak_met]`), seconde = la pensée du joueur (`unless: [has_starter]`). Quand aucune variante ne s'applique (starter obtenu, jalon 4), le déclencheur ne fait plus rien, sans rien retirer de la carte.

**Qui écoute** : `CutsceneDirector`, sur `player.moved(cell)` (comme `SceneRouter` pour les warps). Il ignore le pas si une scène tourne, si `router.is_transitioning()`, ou si `not player.is_input_enabled()` (pas scripté, §2.5). Sinon : `trigger = map.get_triggers().find_on_step(cell, player.get_facing())`, puis `play(trigger.cutscene_id)`. Le blocage `&"cutscene"` est posé **dans l'appel même**, donc dans le `step_finished` du joueur : comme pour les portes (jalon 2 §2.2, `GridMover.set_locked`), le verrou empêche le pas qui s'enchaînerait, même doigt maintenu ou en courant. C'est « le joystick cesse brièvement de répondre ».

Une case ne porte **jamais** à la fois un warp et un déclencheur (invariant testé, §3.6) : l'ordre des deux auditeurs de `moved` n'a donc pas d'importance.

### 2.3 Scènes scriptées : format des données (`data/cutscenes/*.json`)

Une scène est une **liste d'étapes jouées dans l'ordre**, sans embranchement ni parallélisme, en une ou plusieurs **variantes** choisies comme celles des dialogues : la première qui s'applique aux drapeaux. Comme les dialogues, c'est une donnée : Kevin peut régler un délai, un chemin ou une orientation sans l'éditeur Godot, et aucun `if cutscene == "…"` n'existe dans le code. Chaque fichier est un objet `identifiant → scène`, identifiants uniques dans tout le dossier. Format de référence : en-tête de `cutscene_library.gd`.

Clés d'une scène : `variants` (liste), ou directement les clés d'une variante : `if`, `unless` (drapeaux), `steps` (liste non vide). Chaque étape a **exactement une** clé de type :

| Étape | Clés | Effet |
|---|---|---|
| `wait` | `"wait": secondes` | Temps mort (souffle, silence sans texte). |
| `dialogue` | `"dialogue": id` | `runner.play(id, null, map)`, puis attend `dialogue_finished`. `play` refusé (identifiant inconnu, aucune variante) : `push_error`, étape sautée. La mise en scène **pendant** le dialogue passe par les clés de page (`turn`, `pause`, `react`). |
| `face` | `"face": acteur`, `"to": cible` | L'acteur se tourne. Cible = nom de direction, `"player"` ou identifiant de PNJ (`Grid.dominant_direction`). |
| `set` | `"set": [drapeaux]` | Lève les drapeaux dans les `StoryFlags` reçus, **tout de suite** (avant un changement de carte, par exemple). |
| `spawn` | `"spawn": id`, puis les clés d'une entrée de `data/npcs/` **sans** `if`/`unless` : `"cell"` (obligatoire, absolue), `"sprite"` (obligatoire), `"facing"`, `"dialogue"`, `"verb"`… | Crée un PNJ **pour la durée de la carte** (`GameMap.add_npc(step.spec)`). La spécification est validée **au chargement** par `NpcRoster.parse_entry`. Ici, `"dialogue"` est la clé du PNJ (ce qu'il dit quand on lui parle), pas un second type d'étape. |
| `move` | `"move": acteur`, **soit** `"path": [directions]`, **soit** `"to"` : `[x, y]` ou `{ "near": acteur, "offsets": [[dx, dy], …] }` ; `"run"` (faux par défaut) ; `"follower"` (acteur, facultatif) | Déplace l'acteur case par case. `to` : destination résolue au début de l'étape (`CutsceneMoves.resolve_near` pour `near`), puis `GridWorld.find_path`. `follower` : un second acteur suit à un pas derrière (`CutsceneMoves.follow_path`). L'étape attend que les deux soient arrivés. |
| `change_map` | `"change_map": id`, `"at": point d'apparition`, `"facing"` (facultatif, garder l'orientation sinon) | `await router.change_map(id, at, facing)`, avec son fondu habituel. |

**Acteurs** : `"player"` (`NpcRoster.PLAYER_ID`, réservé), ou l'identifiant d'un PNJ de la carte courante (fichier `data/npcs/` ou `spawn` antérieur). Les acteurs ne sont **pas** vérifiés par la bibliothèque (elle ne connaît pas les cartes) : c'est le rôle de la simulation statique des tests de données (§3.6).

Pourquoi des données plutôt qu'un script GDScript par scène : la règle 3 du projet (contenu = données), la même validation stricte que les dialogues (faute de frappe attrapée au lancement et dans les tests), et un vocabulaire de 7 étapes qui suffit au 3B et au jalon 4. On n'ajoute **ni** condition par étape, **ni** boucle, **ni** parallélisme tant qu'aucune scène n'en a besoin.

**Export Android** : `export_presets.cfg` a `include_filter=""` ; les `.json` de `data/dialogues/` et `data/npcs/` partent pourtant dans l'APK (QA 3A). `data/cutscenes/*.json` suit le même chemin : à vérifier en T4 (`unzip -l`).

### 2.4 `CutsceneDirector`

`game/systems/cutscene/cutscene_director.gd` (`class_name CutsceneDirector`, `extends Node`, enfant de `Boot`). C'est le **seul** à jouer une scène. Il ne décide rien : il lit la variante choisie et appelle les nœuds existants (`DialogueRunner`, `Npc`, `Player`, `GameMap`, le routeur).
```gdscript
signal cutscene_started(cutscene_id: StringName)
signal step_started(index: int)                      # tests, outils de capture
signal cutscene_finished(cutscene_id: StringName)
## Raison de blocage du joueur pendant une scène (Player.set_input_enabled).
const REASON: StringName = &"cutscene"
## Un pas bloqué (case occupée) est retenté à chaque image ; au-delà, l'étape est abandonnée.
const MOVE_BLOCK_TIMEOUT: float = 2.0
## [param router] : l'autoload SceneRouter en jeu, une instance de scene_router.gd en test
## (même API : change_map, get_current_map, is_transitioning).
func setup(library: CutsceneLibrary, flags: StoryFlags, runner: DialogueRunner,
		player: Player, router: Node) -> void
func set_map(map: GameMap) -> void                   # relais de Boot sur map_changed
## Faux (et rien ne se passe) si une scène tourne, si l'identifiant est inconnu (push_error)
## ou si aucune variante ne s'applique (sans erreur : déclencheur désarmé).
func play(cutscene_id: StringName) -> bool
func is_running() -> bool
func get_step_index() -> int                         # −1 hors scène
```
Déroulé :
1. `play` : `variant = library.get_cutscene(id).pick(flags)` ; `player.set_input_enabled(false, REASON)` **de façon synchrone**, puis `cutscene_started`. `Boot` cache alors les contrôles (§2.1). `set_process(true)`.
2. Les étapes s'enchaînent dans une coroutine. Avant chaque étape : `step_started(index)`. Les acteurs sont **résolus à chaque étape** dans la carte courante (`map.get_npc(id)`, ou le joueur) : une scène traverse un changement de carte sans garder de référence périmée. Acteur introuvable : `push_error`, étape sautée (la scène continue).
3. `move` : chemins calculés au début de l'étape. `_process` pilote les pas : quand le meneur est à l'arrêt, il lance son pas suivant (`npc.step` ou `player.script_step`, §2.5) ; le suiveur lance le sien **dans la même image, juste après** (la case que le meneur quitte est libérée dès son départ). Destination `near` introuvable (`NO_CELL`) ou chemin vide alors que la case diffère : `push_error`, étape sautée. Aucune allocation par image.
4. `change_map` : si, après l'`await`, `router.get_current_map().map_id` n'est pas la carte demandée (échec du routeur), `push_error` et la scène **s'arrête** (étape 5).
5. Fin (ou arrêt) : `player.set_input_enabled(true, REASON)`, `set_process(false)`, puis `cutscene_finished`. Comme pour le routeur (`_session`), un compteur abandonne proprement une scène dont `setup` a été rappelé (tests de `Boot`).

**Blocage** (raisons de 3A, `Player.set_input_enabled(enabled, reason)`) : la scène tient `&"cutscene"` du début à la fin. Le `DialogueRunner` prend et rend `&"dialogue"` (`DialogueRunner.REASON`) à chaque dialogue, et le routeur prend et rend `&"transition"` (`Player.REASON_TRANSITION`) pendant le fondu. Le joueur n'est libre que lorsque plus aucune raison n'est active : c'est le cas prévu par 3A.

**Deux gardes ajoutées ailleurs** (une ligne chacune) :
- `SceneRouter._on_player_moved` : ignoré si `not _player.is_input_enabled()`. Un pas **scripté** ne prend donc jamais une porte. En 3A, un pas normal se fait toujours joueur libre : les tests du routeur restent verts.
- `InteractionController.on_map_entered` : pas de dialogue automatique si `not _player.is_input_enabled()`. À l'arrivée au labo pendant la scène, le routeur a rendu `&"transition"` mais la scène tient `&"cutscene"` : aucune variante `auto` ne peut partir. Au démarrage (`SceneRouter.start`), le joueur est libre : Maman parle comme en 3A. Rien d'autre à changer dans le contrôleur : `_can_target()` renvoie déjà faux quand le joueur est bloqué (pas de bouton contextuel pendant une scène), et le bouton est caché avec les contrôles.

### 2.5 Des PNJ qui marchent, un joueur qu'on déplace

**`Npc`** (3A, modifié en T3) : il possède un `GridMover`, comme le joueur. Aujourd'hui, `get_cell()` renvoie `_spec.cell` et c'est `GameMap` qui appelle `_grid.occupy(spec.cell, npc)` (dans `_spawn_npcs` et `_build_grid`).
```gdscript
signal step_finished(cell: Vector2i)
## Remplace les grid.occupy(spec.cell, npc) de GameMap : GridMover.new(grid, self) puis
## place(spec.cell, spec.facing) au premier appel, place(get_cell(), get_facing()) ensuite
## (rebuild_grid). Faux si la case est hors carte ou prise.
func enter_grid(grid: GridWorld) -> bool
func leave_grid() -> void                          # libère sa case (et la case visée)
## Un pas (marche, ou course si [param run]) : GridMover.start_step. Faux si bloqué ou déjà
## en marche.
func step(direction: Vector2i, run: bool = false) -> bool
func is_moving() -> bool
```
- `get_cell()` et `get_facing()` passent par le `GridMover` quand il existe (sinon `spec.cell` / orientation de repos, comme en 3A hors grille). `face()` appelle aussi `mover.face()`. `_process` ne tourne **que pendant un pas** (`mover.update(delta, ZERO, false)` puis `position = mover.get_world_position().round()`), et se coupe à l'arrêt : aucun coût au repos, comme en 3A.
- `get_interaction()` : l'`Interaction` de 3A est construite une fois sur `spec.cell`. `InteractionFinder` trouve un PNJ par **l'occupant de la grille**, pas par `Interaction.cell` : un PNJ qui a marché reste donc trouvable. Garder quand même `_interaction.cell` à jour à la fin d'un pas (cohérence, aucune allocation).
- Animations : `walk_<dir>` ou `run_<dir>` pendant un pas si l'apparence les a, sinon `idle_<dir>`. Les Pokémon du décor (sans marche) restent valides.
- Un Pokémon posé sur un meuble (`lift > 0`) occupe toujours une case solide : `GridMover.place` passe par `occupy`, qui ne teste pas la solidité (comportement de 3A conservé).
- `end_interaction()` remet `spec.facing` : inchangé.
- `GameMap` : `add_npc(spec: NpcSpec) -> Npc` (création, ajout à `Entities`, `enter_grid` ; `push_error` et null si la case est prise, hors carte, ou si l'identifiant existe déjà), `remove_npc(id: StringName)` (`leave_grid`, `queue_free`, retrait de `_npcs`). `_build_grid` rappelle `enter_grid` pour chaque PNJ au lieu d'`occupy`.

**`Player`** (modifié en T3) :
```gdscript
## Pas scripté : ignore le blocage des entrées (scènes). Faux si bloqué ou déjà en marche.
func script_step(direction: Vector2i, run: bool = false) -> bool   # _mover.start_step
```
Le pas se termine dans `_process` comme un pas normal (`_update_animation` joue déjà `walk_` / `run_` quand `is_moving()`). `moved` est émis : le routeur l'ignore (joueur bloqué, §2.4), le directeur aussi.

**Sprite provisoire de Chen** (`tools/gen_placeholder_npcs.gd` de 3A, étendu) : `oak`, personne 32 × 64 natif (×2), **blouse blanche, cheveux gris**, repère de direction, `idle_<dir>`, `walk_<dir>` et `run_<dir>` (4 images par direction, comme le joueur). Le générateur gagne la production de la marche pour les apparences qui en ont besoin (ici `oak` seulement). Sans `oak_frames.tres`, `Npc` prend l'apparence générique `npc` (règle de 3A) : pas d'erreur, mais test de 3A `test_every_npc_has_its_own_frames` à étendre.

### 2.6 Présence conditionnelle des PNJ

Une entrée de `data/npcs/<map_id>.json` peut porter `if` et `unless` (§1, `NpcSpec.is_present`, `NpcRoster.get_present`).

`GameMap` ne connaît toujours pas `GameState` (règle de 3A) : on lui **passe** les drapeaux.
```gdscript
## Crée les PNJ présents pour [param flags] qui manquent, retire ceux qui ne le sont plus
## (hors PNJ ajoutés par add_npc, qui restent jusqu'au départ de la carte).
func refresh_npcs(flags: StoryFlags) -> void
```
- `_spawn_npcs` (appelé par `_ready`) crée les PNJ de `roster.get_present(null)` (état « nouvelle partie ») au lieu de `get_all()` : les tests de 3A et les outils qui chargent une carte seule voient le même état qu'avant. La carte garde son `NpcRoster` pour `refresh_npcs`.
- `Boot._on_map_changed` appelle `refresh_npcs(GameState.flags)` **avant** de passer la carte aux contrôleurs. `map_changed` est émis écran noir (et de façon synchrone par `SceneRouter.start`) : un PNJ ajouté ou retiré n'est jamais vu apparaître.
- Le joueur est placé (`spawn_player`) **avant** `map_changed` : un PNJ conditionnel ne doit jamais être sur un point d'apparition (invariant de 3A déjà testé, étendu aux deux états).
- La présence n'est **réévaluée qu'au chargement de la carte**. Lever un drapeau ne fait pas apparaître un PNJ sur la carte où l'on se trouve. Ce qui doit changer sous les yeux du joueur passe par une scène (`spawn`, `move`).

### 2.7 Dialogues : clé de page `turn`

Les didascalies du dossier 02 §5 et §6 ne tiennent pas dans `face_player` : « il regarde les hautes herbes » tourne Chen vers le nord, et au labo chacun se tourne vers celui à qui il répond. La clé de page `turn` (lue et validée depuis le §1) :
```json
{ "text": "…", "turn": { "oak": "up", "player": "oak" } }
```
Dans `DialogueRunner._begin_page` (T3), **après** `_box.show_page(...)` et **avant** `face_player` et `react`, chaque paire est appliquée dans l'ordre : l'acteur (`"player"` → `_player`, sinon `_map.get_npc(id)`) se tourne vers la cible (nom de direction → `Grid.direction_from_name` ; `"player"` ou PNJ → `Grid.dominant_direction(case de l'acteur, case de la cible)`). Joueur : `Player.face(dir)` ; PNJ : `Npc.face(dir)`. Acteur ou cible introuvable (ou `_map` nul) : `push_warning` et la suite continue, comme `react` en 3A. `face_player` reste valable et inchangé.

À noter : `_finish()` appelle `_npc.end_interaction()` seulement pour le PNJ **à qui l'on parle** (`npc` de `play`) ; les scènes passent `npc = null`, donc un PNJ tourné par `turn` **garde** cette orientation après le dialogue (c'est ce qu'on veut au labo).

### 2.8 `GameState` et drapeaux

Aucun changement de `GameState`. Drapeaux du jalon :

| Drapeau | Levé par | Lu par |
|---|---|---|
| `oak_met` | `route1_grass`, variante 1, étape `set`, juste après les répliques de Chen et **avant** le retour | la scène elle-même (`unless`, un seul passage) ; présence de Chen et du rival au labo, absence du rival chez lui ; variante de Maya (§3.2, §3.3) |
| `oak_lab_reunion` | dernière étape de la variante 1, après « Et pourtant, tu es toujours là. » | le jalon 4 (§2.11) ; aucun lecteur en 3B |
| `has_starter` | **le jalon 4** (choix du starter) ; personne en 3B | `route1_grass`, variante 2 (`unless`) : la pensée et le recul cessent dès qu'il est levé |

Le test de 3A « chaque drapeau lu est levé quelque part » s'étend aux scènes et aux fichiers de PNJ (§3.6), avec une liste explicite de drapeaux **levés par un jalon futur** : `[has_starter]`. `oak_lab_reunion` est levé sans être lu : autorisé (accroche du jalon 4).

### 2.9 Signaux et flux

```
Player.moved(cell) ──► CutsceneDirector ─► map.get_triggers().find_on_step(cell, facing)
                                         ─► library.get_cutscene(id).pick(flags) ?
                                         ─► play(id) : Player.set_input_enabled(false, &"cutscene")
                                                       cutscene_started ─► Boot ─► _refresh_controls()
étapes :
  wait        ─► minuterie
  dialogue    ─► DialogueRunner.play(id, null, map) … dialogue_finished
                 (page : turn ─► Player.face / Npc.face · pause · react)
  face        ─► Player.face / Npc.face (Grid.dominant_direction pour une cible acteur)
  set         ─► flags.set_flag(…)
  spawn       ─► GameMap.add_npc(step.spec)
  move        ─► _process : Npc.step / Player.script_step (+ suiveur) ─► GridMover.start_step
  change_map  ─► router.change_map ─► map_changed ─► Boot ─► map.refresh_npcs(flags)
                                                          ─► InteractionController.set_map · CutsceneDirector.set_map
fin ─► Player.set_input_enabled(true, &"cutscene") ─► cutscene_finished ─► Boot ─► _refresh_controls()
```
`GameMap`, `Npc`, `Player`, le HUD et `DialogueRunner` ne connaissent pas `CutsceneDirector`. `CutsceneDirector` ne lit pas l'autoload `GameState` (il reçoit `GameState.flags`) et reçoit le routeur par `setup` : il est testable avec une instance de `scene_router.gd` (`map_factory`, fondus à 0) et un `StoryFlags` neuf. `Boot` reste la seule racine de composition.

### 2.10 La pensée des herbes : rien de neuf côté interface

La boîte de 3A sait déjà afficher une narration sans nom, en italique : un dialogue `"narration": true` **sans** `speaker` → `DialogueBox.show_page("", texte, true)` cache l'étiquette et applique la variation de thème `DialogNarration` (c'est le cas de « Ton petit-déjeuner est encore chaud. »). La pensée du joueur est donc un dialogue de données (§3.3) joué par la variante 2 de `route1_grass`. Aucune tâche `ui-mobile`.

### 2.11 Points d'accroche pour le jalon 4

- **Suite immédiate de la scène** : le §7 du dossier 02 suit la dernière réplique du §6. Le jalon 4 **ajoute des étapes** à la fin de la variante 1 de `route1_grass` (Chen parle aux deux, puis l'interface du choix), ou une scène séparée conditionnée par `oak_lab_reunion`. Le jalon 4 tranchera.
- **Herbes rouvertes** : le jalon 4 lève `has_starter` au choix du starter ; la variante 2 cesse de s'appliquer, le déclencheur ne fait plus rien. Aucune donnée de carte à retoucher.
- **Sortie du labo avant le choix** : un `EventTriggerPoint` devant le tapis de sortie et une scène `if: [oak_met]`, `unless: [has_starter]`, avec le texte que Kevin donnera.
- **« Rencontrer »** : une valeur de plus dans `Interaction.Kind`. Le starter qui s'approche du joueur : étape `move` d'un PNJ Pokémon.
- **Premier combat** : une étape de plus (`battle`) le moment venu, sur le même modèle.
- **Hautes herbes** : `tall_grass` est déjà dans les tuiles ; le jalon 5 le lira dans `GridWorld` pour les rencontres.

---

## 3. Données du jalon

Tolérance **±2 cases** en extérieur, **±1** en intérieur, du moment que les invariants du §3.6 tiennent (Q1, Q9, Q15).

### 3.1 Bourg Palette : herbes, déclencheur, prairie

Rappel (jalon 1 §4.1) : le chemin de la Route 1 occupe x 23–24, y 0–11, entre deux clôtures en bois x 22 et x 25 sur y 0–3. La rangée y 0 est bloquée (`blocked_cells = [(23, 0), (24, 0)]`) : le joueur s'arrête en y 1.

| Élément | Où | Détail |
|---|---|---|
| **Hautes herbes** | (23..24, 0..2) | Tuile `TALL_GRASS` à la place du chemin de terre, entre les clôtures. y 0 reste bloquée. (Q1, validée) |
| **Déclencheur** `Route1Grass` | ancre (23, 3), `size` (2, 1), `direction` ZERO, `cutscene_id` `route1_grass` | Couvre (23, 3) et (24, 3) : la case **juste avant** les herbes, sur les deux colonnes du chemin. (Q2, validée) |
| Arrivée de Chen | apparition en (24, 13) | Sur la place, **hors de l'écran** quand le joueur est en y 3 (la vue montre les rangées 0 à 11). (Q6) |
| **Roucool** `prairie_pidgey` | (18, 2), bas | `pidgey` (sprite de 3A), non interactif (Q4, validée) |
| **Rattata** `prairie_rattata` | (29, 2), gauche | `rattata` (sprite de 3A), non interactif (Q4, validée) |

`data/npcs/pallet_town.json` (ajout aux entrées de 3A ; le fichier est un **objet** identifiant → entrée) :
```json
"prairie_pidgey": { "cell": [18, 2], "facing": "down", "sprite": "pidgey" },
"prairie_rattata": { "cell": [29, 2], "facing": "left", "sprite": "rattata" }
```

### 3.2 PNJ conditionnels

| Carte | id | Case | Orient. | sprite | dialogue | Présence | Remarques |
|---|---|---|---|---|---|---|---|
| `rival_house` | `rival` | (13, 4) | droite | `rival` | `rival` | `unless: [oak_met]` | entrée de 3A, avec la condition en plus : après l'événement, il est au labo (décision 8) |
| `oak_lab` | `maya` | (5, 3) | haut | `maya` | `maya` | toujours | entrée de 3A **inchangée** : sa réplique change par une **variante** de dialogue (§3.3, décision 7) |
| `oak_lab` | `oak` | (8, 4) | bas | `oak` | — | `if: [oak_met]` | la case réservée depuis le jalon 2 ; non interactif en 3B (Q10) |
| `oak_lab` | `rival` | (9, 6) | droite | `rival` | — | `if: [oak_met]` | tourné vers les starters ; non interactif en 3B (Q9, Q10) ; `turn_to_player: false` inutile sans dialogue |

```json
"oak": { "cell": [8, 4], "facing": "down", "sprite": "oak", "if": ["oak_met"] },
"rival": { "cell": [9, 6], "facing": "right", "sprite": "rival", "if": ["oak_met"] }
```
Deux PNJ `rival` dans deux fichiers différents : autorisé (unicité **par carte**).

Pourquoi (9, 6) et pas la case (11, 6) laissée libre en 3A : (11, 6) est la **seule** case d'où l'on observe Salamèche (table en (10..12, 4..5), Pokémon en (10..12, 5)). Le rival y fermerait l'accès, et un PNJ en (10, 6), (12, 6) ou (13, 3..6) couperait un bout de la pièce. En (9, 6), sur le grand tapis, il ne ferme rien, il est à côté des starters, et les deux orientations « vers Chen » (haut) puis « vers le joueur » (gauche) se voient à l'écran.

### 3.3 Dialogues (textes du dossier 02, **définitifs**, mot pour mot)

Ajouts à `data/dialogues/pallet_town.json` (l'événement a lieu sur cette carte) :
```json
"oak_route1_call": {
	"speaker": "???",
	"pages": ["Hé ! Attends !"]
},
"oak_route1_warning": {
	"speaker": "Prof. Chen",
	"pages": [
		{ "text": "Tu allais vraiment entrer là-dedans tout seul ?", "turn": { "oak": "player" } },
		{ "text": "Les Pokémon qui vivent ici ne sont pas tous aussi tranquilles que ceux du village.",
			"turn": { "oak": "up" } },
		{ "text": "Sans Pokémon à tes côtés, tu prends un risque inutile.", "turn": { "oak": "player" } },
		{ "text": "...Viens avec moi.", "pause": 1.0 }
	]
},
"route1_grass_thought": {
	"narration": true,
	"pages": ["Je ne devrais pas aller là sans Pokémon."]
}
```
Ajouts à `data/dialogues/oak_lab.json` :
```json
"maya": {
	"speaker": "Maya",
	"variants": [
		{
			"if": ["oak_met"],
			"pages": [
				"Ah, le professeur est revenu.",
				"Et à voir son air, j'imagine qu'il a encore quelque chose en tête."
			]
		},
		{
			"pages": [
				"Bonjour ! Tu cherches le professeur Chen ?",
				"Il est sorti tôt ce matin. Encore.",
				{ "text": "Quand il commence à observer des Pokémon, il oublie complètement l'heure.",
					"pause": 0.6 }
			]
		}
	]
},
"oak_lab_reunion": {
	"pages": [
		{ "speaker": "Rival", "text": "Enfin." },
		{ "speaker": "Prof. Chen", "text": "Un peu de patience.", "turn": { "oak": "rival" } },
		{ "speaker": "Rival", "text": "Ça fait une heure que tu dis ça.", "turn": { "rival": "oak" } },
		{ "speaker": "Prof. Chen", "text": "Et pourtant, tu es toujours là." }
	]
}
```
- **Étiquette « Prof. Chen »** partout où Chen parle (décision 6). Les autres personnages disent « le professeur » ou « le professeur Chen » dans leurs répliques (Maya).
- **Maya** (décision 7) : la variante `if: [oak_met]` est écrite **d'abord** (première qui s'applique) ; la réplique de 3A devient la variante générale, texte inchangé. Pas de `set` : elle peut être relue.
- **Pensée des herbes** (décision 10) : narration sans nom, en italique (§2.10). Texte sans guillemets, comme les autres narrations (Q20).
- Découpage de 3A : une réplique « … » = une page. Didascalies : « il regarde les hautes herbes » → `turn` vers le nord ; « il réfléchit une seconde » → `pause` de **1,0 s** ; « Il regarde Chen, puis le joueur » → étapes `face` de la scène, avant le dialogue (§3.4) ; « légèrement essoufflé » → temps mort avant la première réplique (§3.4, Q6).
- « Hé ! Attends ! » est un **dialogue à part** : entre cette réplique et celles de Chen, la boîte se ferme, le joueur se retourne et Chen arrive (Q5).
- Le dossier 01 donne « Viens avec moi. J'ai quelque chose à te montrer. » ; le dossier 02, **définitif**, donne « ...Viens avec moi. » (Q17, validée).
- `oak_lab_reunion` n'a pas de `speaker` au niveau du dialogue : chaque page porte le sien (déjà lu par 3A).
- Tous ces textes sont dans le dossier 02 **avec des espaces ordinaires et des apostrophes droites** : les copier depuis le dossier (le test de 3A `test_texts_are_the_dossier_02_texts_word_for_word` les cherche tels quels). Aucun texte `draft`.

### 3.4 Scène `route1_grass` (`data/cutscenes/prologue.json`)

Valeurs par défaut des questions Q5 à Q10, Q18 et Q19, **réglables dans ce fichier seul**.
```json
{
	"route1_grass": {
		"variants": [
			{
				"unless": ["oak_met"],
				"steps": [
					{ "wait": 0.4 },
					{ "dialogue": "oak_route1_call" },
					{ "face": "player", "to": "down" },
					{ "wait": 0.3 },
					{ "spawn": "oak", "sprite": "oak", "cell": [24, 13], "facing": "up" },
					{ "move": "oak", "run": true,
						"to": { "near": "player", "offsets": [[1, 0], [-1, 0], [0, 1]] } },
					{ "face": "oak", "to": "player" },
					{ "face": "player", "to": "oak" },
					{ "wait": 0.6 },
					{ "dialogue": "oak_route1_warning" },
					{ "set": ["oak_met"] },
					{ "move": "oak", "follower": "player",
						"path": ["down", "down", "down", "down", "down", "down", "down", "down"] },
					{ "change_map": "oak_lab", "at": "entrance", "facing": "up" },
					{ "move": "player", "path": ["up", "up"] },
					{ "wait": 0.3 },
					{ "face": "rival", "to": "oak" },
					{ "wait": 0.5 },
					{ "face": "rival", "to": "player" },
					{ "wait": 0.3 },
					{ "dialogue": "oak_lab_reunion" },
					{ "set": ["oak_lab_reunion"] }
				]
			},
			{
				"unless": ["has_starter"],
				"steps": [
					{ "dialogue": "route1_grass_thought" },
					{ "move": "player", "path": ["down"] }
				]
			}
		]
	}
}
```
Variante 1, pas à pas :
1. Le joueur arrive en (23, 3) ou (24, 3) : gel immédiat, 0,4 s de silence, puis « ??? — Hé ! Attends ! ». Le joueur regarde encore les herbes.
2. Boîte fermée : il se retourne (bas). 0,3 s plus tard, Chen apparaît hors de l'écran en (24, 13) et **court** jusqu'à la case voisine du joueur sur l'autre colonne du chemin : (24, 3) si le joueur est en (23, 3), sinon (23, 3), la clôture fermant l'autre côté. Environ 1,2 s de course.
3. Chen et le joueur se font face. 0,6 s de souffle. Les quatre répliques du Prof. Chen : il regarde les herbes à la deuxième, revient au joueur à la troisième, silence d'une seconde avant « ...Viens avec moi. ».
4. `oak_met` est levé. Chen descend le chemin sur 8 cases (environ 1,8 s en marchant) ; le joueur le suit, un pas derrière (son premier pas le met sur la case que Chen vient de quitter).
5. Fondu (celui du routeur, 0,45 s). Au labo : Chen est déjà à sa place (8, 4), le rival en (9, 6) tourné vers les starters, Maya à son écran. Le joueur apparaît sur le tapis d'entrée (7, 9) et fait deux pas vers le haut, jusqu'en (7, 7).
6. Le rival se tourne vers Chen (haut), puis vers le joueur (gauche). Les quatre répliques ; Chen se tourne vers le rival pour répondre, le rival vers Chen.
7. `oak_lab_reunion` est levé, le joueur récupère le contrôle. **Fin du jalon 3.**

Variante 2 (après la scène, tant que `has_starter` n'est pas levé) : le joueur arrive sur (23, 3) ou (24, 3), de n'importe quel côté ; gel ; la pensée s'affiche ; boîte fermée, il **recule d'un pas** vers le bas (il se retrouve tourné vers le village) et reprend la main. Répétable à chaque passage. Le recul garantit qu'il n'entre jamais dans les herbes : sans lui, un second appui vers le haut le ferait passer (Q19).

### 3.5 Ce qui se passe ensuite (état de fin du 3B)

- Au labo, Chen et le rival restent en place, **non interactifs** : le dossier ne leur donne pas d'autre réplique (Q10). Maya dit sa nouvelle réplique. Les trois starters restent observables. On peut ressortir.
- Les herbes restent fermées (variante 2) jusqu'au starter (jalon 4).
- Chez le rival : il n'est plus là. Sa carte de Kanto s'examine toujours.
- Maman, Mme Aoki, Léo, Haru, le panneau : inchangés.

### 3.6 Invariants (testés)

**Bourg Palette** (`test_pallet_town.gd`, étendu) :
- les cases `TALL_GRASS` sont exactement (23..24, 0..2) ; les invariants du jalon 1 §4.4 restent vrais ((23, 1) et (24, 1) atteignables, (23, 0) et (24, 0) non) ;
- **on ne peut pas atteindre les herbes sans passer par le déclencheur** : sur une grille où (23, 3) et (24, 3) sont rendues solides, `find_reachable` depuis `start` n'atteint aucune case `TALL_GRASS` ;
- les cases du déclencheur sont praticables, atteignables, et ne sont ni un warp, ni un spawn, ni la case d'un PNJ (pour tout état de drapeaux) ; la case sous chacune, (23, 4) et (24, 4), est libre (recul de la variante 2) ;
- la case d'apparition de Chen (24, 13) est praticable et libre de tout PNJ ; pour le joueur en (23, 3) comme en (24, 3), `CutsceneMoves.resolve_near` trouve la case voisine attendue, et `find_path` depuis (24, 13) y mène ;
- depuis les deux cases de Chen possibles, les 8 pas vers le bas sont libres (ni solide, ni PNJ, ni warp, ni déclencheur : `CutsceneMoves.path_cells`), et le chemin du suiveur aussi (`follow_path`) ;
- les Pokémon de la prairie respectent les invariants de 3A (case praticable, aucune poche).

**PNJ conditionnels** (`test_npc_placement.gd` de 3A, étendu) : les invariants de 3A sont vérifiés **pour deux états** : drapeaux vides (état de 3A, inchangé : Chen et le rival absents du labo, rival chez lui) et `{ oak_met }` (Chen en (8, 4), rival en (9, 6), rival absent de sa maison). Dans les deux états : aucune poche, chaque cible interactive utilisable (**les trois starters restent observables**, Maya aussi), (11, 6) libre et atteignable, et deux entrées de même case ne sont jamais présentes ensemble. `test_chen_cells_stay_free_and_reachable_in_the_lab` ne vaut plus que pour les drapeaux vides ; avec `oak_met`, (8, 4) est occupée par Chen. Depuis `entrance` (7, 9), les deux pas vers le haut de la scène sont libres.

**Cohérence des données** (`tests/integration/test_cutscene_data.gd`, nouveau, et `test_dialogue_data.gd` de 3A, étendu) :
- `CutsceneLibrary.load_dir()` sur `data/cutscenes/` : aucune erreur ;
- chaque `cutscene_id` d'`EventTriggerPoint` (6 cartes) existe ; chaque scène est visée par au moins un déclencheur ; chaque `dialogue` d'étape existe dans `data/dialogues/` ; chaque `change_map` vise une carte (`MapCatalog`) et un point d'apparition existants ;
- **simulation statique** de chaque variante : on part de la carte de son déclencheur, avec un état de drapeaux où **cette** variante est choisie (écrit dans le test : `{}` pour la 1, `{ oak_met }` pour la 2) ; on ajoute les `set` et les `spawn` au fil des étapes ; à chaque `change_map`, on passe aux PNJ **présents** de la carte cible pour les drapeaux du moment. Chaque acteur d'étape (`face`, `move`, `follower`, `near`), chaque cible `face` qui n'est pas une direction, et chaque acteur ou cible de `turn` des dialogues joués existe à ce moment-là ;
- chaque drapeau lu (variantes de dialogue, variantes de scène, entrées de PNJ) est levé par au moins un `set` (dialogue ou scène), **sauf** la liste des drapeaux du jalon 4 : `[has_starter]` ;
- `test_every_dialogue_is_used` de 3A : un dialogue est « utilisé » s'il est porté par un PNJ, un point d'examen **ou une étape de scène** (`CutsceneLibrary.get_dialogue_ids()`) ;
- chaque page des nouveaux dialogues tient en `DIALOG_MAX_LINES` lignes (test de 3A, qui couvre déjà tous les fichiers).

---

## 4. Découpage des tâches (dans l'ordre)

Chaque tâche finit par un essai sur le S24 (capture et retour de Kevin) avant la suivante. Aucune tâche `ui-mobile` : le 3B réutilise la boîte de dialogue (narration comprise), le bouton contextuel et `set_controls_visible` de 3A sans les changer. Si l'essai de T2 montre un problème de lisibilité de l'étiquette « ??? », il deviendra une tâche `ui-mobile`.

### T1 — constructeur-monde : les hautes herbes et la prairie habitée
- `OverworldTiles.Kind.TALL_GRASS` (fin d'enum, 2 variantes, `tall_grass = true`), `tools/gen_placeholder_tiles.gd` (atlas et TileSet régénérés) ; `tools/build_pallet_town.gd` : herbes en (23..24, 0..2), carte régénérée ; `data/npcs/pallet_town.json` : Roucool et Rattata de la prairie (§3.1).
- **CA** :
  - `test_overworld_tileset.gd` : `TALL_GRASS` a ≥ 2 variantes, `tall_grass` vrai, non solide, pas d'eau ; les coordonnées d'atlas des types existants n'ont pas bougé ; tous les autres types ont `tall_grass` faux.
  - `test_pallet_town.gd` : cases `TALL_GRASS` exactes, invariants du jalon 1 inchangés, Pokémon de la prairie conformes (§3.6).
  - `test_npc_placement.gd` : `PLAN[&"pallet_town"]` complété des deux Pokémon.
  - Capture Movie Maker (`tools/capture_play.gd`, scénario `route1_grass`) à 2340 × 1080, joueur en (23, 4), lue avec Read : herbes nettement distinctes du chemin et de l'herbe rase, Roucool et Rattata visibles dans la prairie, clôtures intactes.
  - **S24** : monter jusqu'aux herbes, y entrer (rien ne se passe encore), en ressortir.
  - Import sans erreur ; `tools/test.sh` vert.

### T2 — constructeur-monde : le déclencheur, le gel et « Hé ! Attends ! »
- `EventTriggerPoint` ; `GameMap.get_triggers()` ; `CutsceneDirector` avec les étapes `wait`, `dialogue`, `face` et `set` (les autres types sont validés par la bibliothèque mais **pas encore joués** : `push_error` et étape sautée) ; les deux gardes du §2.4 (routeur, `on_map_entered`) ; câblage de `Boot` (§2.1, dont `_refresh_controls`) ; `InteractionController.dominant_direction` délègue à `Grid.dominant_direction` (même règle, un seul endroit) ; déclencheur `Route1Grass` dans `build_pallet_town.gd` ; dialogues `oak_route1_call` et `route1_grass_thought` ; `data/cutscenes/prologue.json` **réduit** : variante 1 = étapes 1 à 3 du §3.4 puis `set: [oak_met]` (le joueur se retourne, puis reprend la main) ; variante 2 = la pensée seule (le recul arrive avec `move` en T3).
- **CA** :
  - `test_game_map.gd` (mini-carte) : un `EventTriggerPoint` 2 × 1 donne 2 déclencheurs dans `get_triggers()` ; deux en conflit sur une case : `push_error` attendu ; `find_on_step` respecte `direction` ; `rebuild_grid` reconstruit la table.
  - `tests/integration/test_cutscene_director.gd` (mini-carte, vraie `DialogueBox`, `StoryFlags` neuf, fixtures, `chars_per_second = 0`, routeur de test avec fondus à 0) : `play` bloque le joueur **dans la même image** (`is_blocked_by(&"cutscene")`) et émet `cutscene_started` ; `wait` dure le temps demandé (± 1 image) ; `dialogue` attend la fin du dialogue ; `face` vers une direction, vers `"player"` et vers un PNJ ; `set` lève le drapeau avant l'étape suivante ; à la fin, joueur libre et `cutscene_finished`. Aucune variante : `false`, sans erreur. Identifiant inconnu : `false` et `push_error`. `play` pendant une scène : `false`. Un blocage `&"transition"` actif à la fin laisse le joueur bloqué. La variante choisie dépend des drapeaux (1 puis 2).
  - Même fichier : un pas terminé sur une case de déclencheur lance la scène **dans le `moved`**, et le pas suivant ne part pas avec `move_up` tenu ; aucun déclenchement si aucune variante ne s'applique, ni pendant une transition, ni sur un pas scripté.
  - `test_interaction_controller.gd` : `on_map_entered` ne lance pas de dialogue automatique si le joueur est bloqué ; les tests de 3A (dont `test_dominant_direction`) restent verts.
  - `test_scene_router.gd` : **inchangé et vert** ; un test en plus : un pas qui se termine sur une porte, joueur bloqué, ne change pas de carte.
  - `test_boot.gd` : contrôles cachés pendant toute la scène, **y compris entre deux dialogues**, rétablis à la fin.
  - `test_dialogue_data.gd` : `IDS`, locuteurs et narration étendus aux nouveaux dialogues (`"???"`, pensée : `""` et narration) ; un dialogue joué par une scène compte comme utilisé ; drapeaux du §3.6 (liste `[has_starter]`).
  - **S24** : monter vers les herbes, en marchant puis en courant, doigt maintenu : gel sur la dernière case avant les herbes, joystick et boutons cachés, « ??? — Hé ! Attends ! », le personnage se retourne, contrôle rendu. Remonter : la pensée en italique, sans nom.

### T3 — constructeur-monde : Chen arrive et parle, le recul
- `Npc` avec `GridMover` (§2.5) ; `GameMap.add_npc` / `remove_npc` ; `Player.script_step` ; étapes `spawn` et `move` (`path`, `to` absolu et `near`, `run`, sans `follower`) ; clé de page `turn` dans `DialogueRunner._begin_page` ; sprite provisoire `oak` avec marche et course ; `oak_route1_warning` ; variante 1 étendue jusqu'à `set: [oak_met]` (étapes 1 à 11 du §3.4) ; variante 2 complète (pensée puis recul).
- **CA** :
  - `tests/integration/test_npc.gd` (étendu) : `enter_grid` occupe la case ; `step` avance d'une case en `Grid.WALK_STEP_DURATION` (course : `RUN_STEP_DURATION`), libère l'ancienne case dès le départ, émet `step_finished` ; refusé contre un obstacle ou pendant un pas ; `walk_<dir>` joué s'il existe, sinon `idle_<dir>` ; `_process` coupé au repos ; `get_cell()` suit le `GridMover`. Les tests de 3A restent verts.
  - `test_game_map.gd` : `add_npc` sur une case libre, `null` et `push_error` sur une case prise ; `remove_npc` libère la case ; `rebuild_grid` garde les PNJ inscrits.
  - `test_player.gd` : `script_step` avance d'une case alors que le joueur est bloqué pour `&"cutscene"` ; refusé pendant un pas ; `moved` émis.
  - `test_dialogue_runner.gd` : `turn` tourne le PNJ, puis le joueur, au début de **cette** page seulement, avant `react` ; identifiant inconnu : `push_warning`, le dialogue continue ; sans `npc` passé à `play`, le PNJ tourné garde son orientation à la fin.
  - `test_cutscene_director.gd` : `spawn` crée le PNJ à sa case ; `move` avec `to` (absolu et `near`) suit `find_path` et attend l'arrivée ; `move` bloqué plus de `MOVE_BLOCK_TIMEOUT` : `push_error`, la scène continue ; acteur introuvable : `push_error`, étape sautée ; variante 2 : pensée puis un pas vers le bas.
  - `test_npc_placement.gd` : `oak` a ses propres SpriteFrames avec `walk_` et `run_`.
  - Capture Movie Maker (scénario `route1_oak`) : Chen qui entre dans l'écran par le bas, Chen arrêté à côté du joueur (pour chacune des deux colonnes), Chen tourné vers les herbes pendant la deuxième réplique. Lues avec Read : sprites nets, Chen à la bonne taille (≈ 1,33 case), rien de coupé.
  - **S24** : la scène complète jusqu'à « ...Viens avec moi. », puis contrôle rendu (fin provisoire). Vitesse de course de Chen, souffle et silence d'une seconde jugés par Kevin. Remonter : pensée puis recul.

### T4 — constructeur-monde : le retour au labo
- Suiveur dans l'étape `move` ; étape `change_map` ; présence conditionnelle dans `GameMap` (`_spawn_npcs` sur `get_present(null)`, `refresh_npcs`) et `Boot._on_map_changed` ; entrées du §3.2 ; variante de Maya et `oak_lab_reunion` (§3.3) ; scène complète (§3.4) ; invariants du §3.6.
- **CA** :
  - `test_game_map.gd` : `_ready` crée les PNJ présents pour des drapeaux vides ; `refresh_npcs({oak_met})` ajoute ceux en `if` et retire ceux en `unless` (cases libérées) ; appelé deux fois, il ne crée pas de doublon ; un PNJ ajouté par `add_npc` n'est pas retiré.
  - `test_cutscene_director.gd` : avec `follower`, le suiveur est toujours à un pas derrière le meneur et finit sur l'avant-dernière case du meneur ; `change_map` (routeur de test, `map_factory`) : les étapes suivantes visent les PNJ de la nouvelle carte ; échec du routeur : `push_error`, scène arrêtée, joueur libéré.
  - `tests/integration/test_npc_placement.gd` et `test_cutscene_data.gd` : tous les invariants du §3.6.
  - `tests/integration/test_route1_event.gd` (nouveau, vrai `Boot`, départ `pallet_town` / `start`, fondus raccourcis, texte instantané) : marche jusqu'à (23, 4), `move_up` **tenu** : gel en (23, 3) ; on avance chaque dialogue ; Chen arrive en (24, 3) ; `oak_met` levé ; le joueur suit ; carte `oak_lab` ; Chen en (8, 4), rival en (9, 6) ; joueur en (7, 7) ; « Enfin. » puis les trois autres répliques avec les bons noms (« Rival », « Prof. Chen ») ; `oak_lab_reunion` levé, joueur libre, contrôles visibles. Pendant toute la scène, le joueur n'a fait **que** les pas scriptés. Maya dit « Ah, le professeur est revenu. ». On ressort, on remonte en (23, 3) : la pensée, puis le joueur en (23, 4). Chez le rival : personne. Même scénario depuis (24, 3).
  - `test_opening_walk.gd` et les autres tests de 3A : inchangés et verts.
  - **Export** : `tools/build_android.sh`, puis `data/cutscenes/prologue.json` présent dans l'APK (`unzip -l`).
  - Capture Movie Maker (scénario `route1_full`) : une image par étape (gel, « ??? », Chen qui arrive, chaque réplique, le suivi, le fondu, l'arrivée au labo, le rival vers Chen puis vers le joueur, chaque réplique du labo, Maya, la pensée). Lues avec Read : étiquettes correctes, 3 lignes au plus, aucun contrôle tactile visible pendant la scène.

### T5 — qa-mobile : validation sur S24
- Checklist `android-deploy` : tests, import, `tools/deploy_s24.sh`, logcat.
- **CA à vérifier et rapporter** :
  - Déclenchement : sur chacune des deux colonnes du chemin, en marchant, en courant, doigt maintenu depuis la place : gel **sur la case avant les herbes**, sans aucun pas de plus. Aucun écran noir au moment du gel.
  - Mise en scène : « ??? » avant l'apparition de Chen ; le personnage se retourne ; Chen entre par le bas de l'écran et s'arrête à côté ; il regarde les herbes à la deuxième réplique ; silence avant « ...Viens avec moi. » ; le joueur suit Chen sans intervention ; fondu ; au labo, le rival regarde Chen puis le joueur ; les quatre répliques avec « Rival » et « Prof. Chen ».
  - Pendant toute la scène : joystick, courir et bouton contextuel cachés ; toucher l'écran n'avance que la boîte de dialogue ; le joueur ne bouge jamais de lui-même.
  - Après : contrôle rendu au labo ; Chen et le rival en place ; les trois starters toujours observables ; Maya : « Ah, le professeur est revenu. » / « Et à voir son air, j'imagine qu'il a encore quelque chose en tête. » ; on ressort ; remonter vers les herbes : arrêt, pensée en italique sans nom, recul d'un pas, jamais un pied dans les herbes (sur les deux colonnes, en marchant et en courant, dix fois) ; le rival n'est plus chez lui.
  - Parties neuves (relancer l'application) : aller au labo **avant** l'événement → Maya seule, avec sa réplique de 3A ; parler au rival **avant** → sa réplique de 3A.
  - 60 fps pendant la course de Chen et le suivi (ou « non vérifié ») ; changement de carte toujours < 100 ms ; aucune erreur dans logcat, notamment aucune de `CutsceneLibrary`, `DialogueLibrary` ni `NpcRoster`.

---

## 5. Tests GUT prévus (récapitulatif)

| Fichier | Nouveau / étendu | Tâche |
|---|---|---|
| `tests/unit/test_grid.gd` | étendu (noms de direction, `dominant_direction`) | §1 — **fait** |
| `tests/unit/test_grid_world.gd` | étendu (`is_free`, `find_path`) | §1 — **fait** |
| `tests/unit/test_grid_mover.gd` | étendu (`start_step`) | §1 — **fait** |
| `tests/unit/test_dialogue_library.gd` | étendu (`turn`) | §1 — **fait** |
| `tests/unit/test_npc_roster.gd` | étendu (`if`/`unless`, `is_present`, `get_present`, `parse_entry`, `is_cell`, `player` réservé) | §1 — **fait** |
| `tests/unit/test_event_trigger.gd` | nouveau (`EventTrigger`, `TriggerTable`) | §1 — **fait** |
| `tests/unit/test_cutscene_library.gd` | nouveau (format, variantes, validation, erreurs avec ligne) | §1 — **fait** |
| `tests/unit/test_cutscene_moves.gd` | nouveau (`resolve_near`, `follow_path`, `path_cells`) | §1 — **fait** |
| `tests/unit/test_overworld_tileset.gd` | étendu (`TALL_GRASS`) | T1 |
| `tests/integration/test_pallet_town.gd` | étendu (herbes, déclencheur, apparition et chemins de Chen, case de recul) | T1, T2, T4 |
| `tests/integration/test_game_map.gd` | étendu (déclencheurs, `add_npc`, `remove_npc`, `refresh_npcs`) | T2, T3, T4 |
| `tests/integration/test_cutscene_director.gd` | nouveau | T2, T3, T4 |
| `tests/integration/test_interaction_controller.gd` | étendu (pas d'`auto` joueur bloqué) | T2 |
| `tests/integration/test_scene_router.gd` | un test en plus (pas bloqué sur une porte) | T2 |
| `tests/integration/test_boot.gd` | étendu (contrôles pendant une scène) | T2 |
| `tests/integration/test_dialogue_data.gd` | étendu (nouveaux dialogues, dialogues des scènes, drapeaux) | T2, T3, T4 |
| `tests/integration/test_npc.gd` | étendu (marche) | T3 |
| `tests/integration/test_player.gd` | étendu (`script_step`) | T3 |
| `tests/integration/test_dialogue_runner.gd` | étendu (`turn`) | T3 |
| `tests/integration/test_npc_placement.gd` | étendu (prairie, `oak`, deux états de drapeaux) | T1, T3, T4 |
| `tests/integration/test_cutscene_data.gd` | nouveau (cohérence, simulation statique) | T4 |
| `tests/integration/test_route1_event.gd` | nouveau (scénario complet avec `Boot`) | T4 |

Données d'essai : `tests/fixtures/cutscenes/*.json` (posées), compléments dans `tests/fixtures/npcs/` et `tests/fixtures/dialogues/` si besoin. Rappel GUT 9.7 : toute `push_error` non comptée par `assert_push_error` / `assert_push_error_count` fait **échouer** le test.

---

## 6. Validation S24 (résumé)

| Après | Ce que Kevin essaie sur le S24 |
|---|---|
| T1 | Les herbes au bout du chemin, la prairie avec un Roucool et un Rattata. |
| T2 | Le gel au bord des herbes, « Hé ! Attends ! », le personnage qui se retourne ; ensuite la pensée. |
| T3 | Le Prof. Chen qui arrive en courant et ses quatre répliques ; la pensée et le recul. |
| T4 | Tout le jalon, jusqu'aux quatre répliques du labo, Maya, les herbes fermées. |
| T5 | Rapport de QA complet (§4, T5). |

---

## 7. Hypothèses et questions pour Kevin

> **Décisions de Kevin (2026-09-26)** — elles **priment** sur les propositions par défaut ci-dessous et sur le reste du plan :
> 1. Herbes : les 3 dernières rangées du chemin nord (Q1 validée).
> 2. Déclencheur : la case **juste avant** les herbes ; le joueur n'entre jamais dans les herbes sans Pokémon (Q2 validée).
> 3. Gel ≈ 0,4 s → « ??? — Hé ! Attends ! » → le joueur se retourne → Chen arrive **en courant** depuis le village (Q5, Q6 validées).
> 4. Retour : le joueur **suit Chen automatiquement** quelques cases, puis fondu vers le labo (Q8 : option A).
> 5. Réplique finale définitive : « ...Viens avec moi. » (Q17).
> 6. **Étiquette : « Prof. Chen »** (et non « Chen ») partout où il parle ; les autres personnages peuvent dire « le professeur Chen » ou « Chen » dans leurs répliques (**modifie Q13 et tous les `"speaker"` de Chen du §3.3**).
> 7. **Maya après le retour de Chen** : elle ne devient **pas** muette (modifie Q11). Nouvelle variante, conditionnée par `oak_met` : **Maya** — « Ah, le professeur est revenu. » / « Et à voir son air, j'imagine qu'il a encore quelque chose en tête. » (textes définitifs ; elle évoluera encore après le starter, jalon 4).
> 8. Le rival quitte sa chambre après l'événement et se trouve au labo ; sa chambre est vide (Q12 validée).
> 9. Scène du labo : Rival « Enfin. » / **Prof. Chen** « Un peu de patience. » / Rival « Ça fait une heure que tu dis ça. » / **Prof. Chen** « Et pourtant, tu es toujours là. », puis le joueur reprend la main.
> 10. **Après la scène (modifie Q10)** : tant que le joueur n'a **pas de starter** (jalon 4), les hautes herbes **restent bloquées**. Pas de nouvelle cinématique : sur la case juste avant les herbes, le joueur s'arrête et une courte **pensée du joueur** s'affiche : *« Je ne devrais pas aller là sans Pokémon. »* (narration, sans nom, en italique). Condition : pas de drapeau `has_starter` (levé par le jalon 4). Un simple déclencheur répétable.
> 11. Roucool et Rattata de la prairie : Pokémon d'ambiance, **aucun combat** pour l'instant (Q4 validée).
> 12. Contrôle après le 3B : le joueur explore Bourg Palette, parle aux habitants, entre dans les bâtiments ; seule la sortie par les hautes herbes reste verrouillée jusqu'au starter.
> 13. Durées, positions fines, rendu des herbes, sauvegarde et autres paramètres : **valeurs proposées**, à ajuster après l'essai sur S24.

Hypothèses techniques (pas de décision de design) :
- Scènes scriptées en **données** (`data/cutscenes/*.json`), 7 types d'étapes, variantes choisies par drapeaux comme les dialogues, sans embranchement interne ni parallélisme.
- Un déclencheur est une donnée de carte (comme un warp) ; ce qu'il fait dépend des variantes de sa scène.
- Présence des PNJ évaluée au chargement de la carte seulement ; ce qui change sous les yeux du joueur passe par une scène.
- Un pas scripté ne prend jamais une porte et ne relance aucun déclencheur.
- Pas de sauvegarde, comme en 3A.

Questions (**proposition par défaut** entre parenthèses ; c'est ce que le plan applique si tu ne dis rien). Q1, Q2, Q4, Q5, Q6, Q8, Q11, Q12, Q13 et Q17 sont tranchées par les décisions ci-dessus ; elles restent listées pour mémoire.

1. **Où sont les hautes herbes ?** *Tranchée (décision 1)* : (23..24, 0..2), entre les clôtures.
2. **Quand Chen intervient-il ?** *Tranchée (décision 2)* : sur la case juste avant les herbes.
3. **Condition de l'événement** : faut-il avoir fait quelque chose avant (parler au rival, visiter le labo) ? (*Non : seulement ne pas l'avoir déjà vécu. Le joueur passe forcément par Maman.*)
4. **Pokémon de la prairie** : *Tranchée (décision 11)* : un Roucool et un Rattata d'ambiance, non interactifs, sans combat. Pas de Papilusion pour l'instant.
5. **Mise en scène du gel** : *Tranchée (décision 3)*. Pas d'écran noir, pas de bandes cinéma, la caméra reste sur le joueur ; la boîte se ferme au toucher, **puis** il se retourne.
6. **Arrivée de Chen** : *Tranchée (décision 3)* : en courant, environ 1,2 s, puis 0,6 s de souffle. « Légèrement essoufflé » ne se voit qu'à ce temps mort : pas d'animation spéciale sur le sprite provisoire.
7. **Didascalies de Chen** : « il regarde les hautes herbes » = il se tourne vers le nord pendant cette réplique, puis revient vers le joueur à la suivante ; « il réfléchit une seconde » = silence d'1 s avant « ...Viens avec moi. ». (*Oui.*)
8. **Le retour** : *Tranchée (décision 4)* : option A, suivi automatique sur 8 cases puis fondu.
9. **Arrivée au labo** : Chen est **déjà à sa place** (devant son bureau) ; le rival est sur le grand tapis, à côté des starters, tourné vers eux ; le joueur entre et fait deux pas. Pendant l'échange, chacun se tourne vers celui à qui il répond. (*Oui.* Autre choix : Chen entre devant le joueur et marche jusqu'à son bureau, un peu plus long.)
10. **Chen et le rival après la dernière réplique** (état propre au 3B, le jalon 4 enchaînera directement) : ils restent au labo **sans dialogue** : le dossier ne leur donne pas d'autre réplique. On peut ressortir ; les herbes restent fermées (décision 10). (*Oui, non interactifs. Veux-tu leur donner une réplique d'attente ?*)
11. **Maya** : *Tranchée (décision 7)*.
12. **Le rival quitte sa maison** : *Tranchée (décision 8)*.
13. **Étiquettes de nom** : *Tranchée (décision 6)* : « ??? », puis « Prof. Chen » ; « Rival » comme en 3A.
14. **Sauvegarde** : aucune, comme en 3A. Quitter pendant l'événement ou après recommence la partie dans la chambre. (*Oui.* Quand la sauvegarde viendra, on ne pourra pas sauvegarder pendant une scène.)
15. **Positions** : déclencheur en (23..24, 3), Chen apparaît en (24, 13), Roucool (18, 2), Rattata (29, 2), Chen au labo (8, 4), rival au labo (9, 6) plutôt que (11, 6), sinon Salamèche ne s'observe plus (§3.2). (*Validées telles quelles, à ajuster après l'essai sur S24.*)
16. **Rendu des herbes** : tuile provisoire plus haute et plus sombre que l'herbe rase, sans effet « jambes cachées » (il viendra avec les rencontres). (*Oui.*)
17. **« Viens avec moi »** : *Tranchée (décision 5)* : « ...Viens avec moi. ».
18. **Durées** : 0,4 s de gel avant la voix, 0,3 s avant l'arrivée de Chen, 0,6 s de souffle, 8 cases de suivi, deux pas dans le labo, 0,5 s entre « regarde Chen » et « regarde le joueur ». (*Valeurs de départ, réglables dans `data/cutscenes/prologue.json` après l'essai sur S24.*)
19. **Nouveau — après la pensée des herbes** : ta décision dit « le joueur s'arrête et une pensée s'affiche ». Pour qu'il n'entre **jamais** dans les herbes, il faut qu'il ne puisse pas faire le pas suivant vers le haut. (*Après la pensée, il **recule d'un pas** vers le village (il se retrouve tourné vers le bas), comme dans Rouge/Bleu quand on essaie de sortir sans Pokémon. Réglable dans `prologue.json`.* Autre choix : il reste sur place et les herbes deviennent un mur invisible tant qu'il n'a pas de starter, la pensée revenant à chaque poussée contre ce mur ; cela demande des collisions conditionnées par drapeau, un mécanisme de plus.)
20. **Nouveau — forme de la pensée** : le dossier l'écrit *« Je ne devrais pas aller là sans Pokémon. »*. (*Texte affiché sans guillemets, en italique, sans nom, exactement comme les narrations « Examiner » de 3A (« Ton petit-déjeuner est encore chaud. »). Pas de style distinct « pensée » pour l'instant.*)
21. **Nouveau — la pensée à chaque passage** : (*Elle revient à **chaque** arrivée sur la case avant les herbes, de n'importe quel côté, tant qu'il n'y a pas de starter. Pas de version plus courte au deuxième passage.*)

---

## 8. Alignement sur le code 3A (fait, 2026-09-26)

Le plan précédent (commit `2e3d6a9`) avait été écrit avant l'arrivée du code de 3A. Relu contre `main` (`dad5d5a`, 513 tests), puis complété par les décisions de Kevin. Ce qui a changé :

1. **Pré-requis levé** : le code de 3A est dans `main`. L'ancien §8 (« code de 3A absent », `GameState` manquant, `Player.set_input_enabled` à un seul booléen…) est périmé et remplacé par cette section.
2. **Fondations posées** (§1) : elles existent et sont testées (572 tests). Plusieurs signatures ont changé par rapport à la version précédente, voir les points suivants.
3. **Format des PNJ** : `data/npcs/<carte>.json` est un **objet** `identifiant → entrée`, pas une liste d'objets avec `"id"`. Les extraits du §3.1 et du §3.2 sont corrigés.
4. **Noms de direction** : la conversion était une constante privée de `NpcRoster` (`_FACINGS`). Elle est **déplacée dans `Grid`** (`direction_from_name`, `is_direction_name`, `direction_name`), avec `Grid.dominant_direction` (même règle qu'`InteractionController.dominant_direction` et `Npc.face_toward` de 3A ; T2 fait déléguer le contrôleur).
5. **`NpcRoster.parse_entry`** : `static parse_entry(value: Variant, errors: PackedStringArray) -> NpcSpec` au lieu de `parse_entry(entry: Dictionary, errors)`. Il n'appelle pas `push_error` et ne préfixe pas ses messages : `NpcRoster` et `CutsceneLibrary` les situent et les signalent chacun avec leur préfixe. Il ne lit pas l'identifiant. `is_cell`, `KEYS` et `PLAYER_ID` (« player » réservé) sont publics ; `get_present(flags)` ajouté.
6. **Variantes de scène** (nouveau, pour la décision 10) : la pensée des herbes est sur **les mêmes cases** que l'interception de Chen. Plutôt qu'autoriser deux déclencheurs par case, une scène a des **variantes** choisies comme celles des dialogues (`Cutscene.pick`) : une seule scène `route1_grass` (au lieu de `oak_intercept`), un seul `EventTriggerPoint` `Route1Grass`. Nouvelle classe `CutsceneVariant` ; `Cutscene` n'a plus `if_flags` / `unless_flags` propres.
7. **Clés d'étape** : `spawn` prend la case sous **`cell`** (absolue, comme une entrée de `data/npcs/`), au lieu de `at` ; toute l'étape moins `spawn` est une entrée de PNJ, validée au chargement (`CutsceneStep.spec`). `change_map` prend le point d'apparition sous **`at`**, au lieu de `spawn` (qui est un type d'étape : l'ancien exemple `{ "change_map": …, "spawn": … }` avait deux types). Dans une étape `spawn`, `dialogue` est la clé du PNJ, pas un type (conflit trouvé par les tests).
8. **Destinations** : `CutsceneMoves.resolve_cell(spec, grid, anchors)` devient `resolve_near(grid, anchor, offsets, mover)` (une case absolue n'a rien à résoudre) ; `GridWorld.is_free` ajouté pour dire « on peut s'y tenir » ; `CutsceneMoves.path_cells` ajouté pour les tests de données.
9. **`get_turn_actors()`** supprimé de `DialogueLibrary` : les tests de données parcourent `DialoguePage.turn` directement. `CutsceneLibrary.get_dialogue_ids()` ajouté (dialogues « utilisés » par les scènes, pour `test_dialogue_data.gd`).
10. **`InteractionController.set_enabled` supprimé** : dans le code de 3A, `_can_target()` renvoie déjà faux quand le joueur est bloqué, donc aucune cible ni bouton pendant une scène. Seul risque restant : un dialogue `auto` à l'arrivée au labo. Il est réglé par une garde dans `on_map_entered` (joueur bloqué → rien), sans nouvelle API.
11. **Narration** : rien à créer. `Dialogue.narration` sans `speaker` donne déjà une boîte sans étiquette, en italique (`DialogNarration`) : la pensée est un dialogue de données (§2.10). Aucune tâche `ui-mobile`.
12. **Maya** : plus d'entrée `maya_working` non interactive ; une **variante** de son dialogue `if: [oak_met]` (décision 7). Son entrée de PNJ ne change pas.
13. **« Prof. Chen »** partout où Chen parle (décision 6) ; le drapeau `has_starter` (jalon 4) est lu par la variante 2 et **attendu non levé** en 3B (liste explicite dans les tests de données).
14. **Noms réels** utilisés dans le plan : `DialogueRunner.play(dialogue_id, npc = null, map = null, delay = 0.0)`, `DialogueRunner.REASON`, `_begin_page` ; `Player.set_input_enabled(enabled, reason = REASON_TRANSITION)`, `is_blocked_by`, `face` ; `GameMap._spawn_npcs`, `_build_grid`, `get_npc`, `get_npcs` ; `SceneRouter._on_player_moved`, `change_map(map_id, spawn, facing)`, `is_transitioning`, `get_current_map`, `map_factory` ; `InteractionController.on_map_entered`, `set_map`, `_can_target` ; `ExplorationHud.set_controls_visible` ; `OverworldTiles.DATA_TALL_GRASS`, `VARIANTS`.
15. **Constat à connaître** (préexistant, sans lien avec 3B) : `tools/test.sh` affiche 3 lignes `SCRIPT ERROR: Attempted to free a locked object (calling or emitting)` pendant des tests d'intégration de 3A (`test_game_map`, `test_interaction_controller`, `test_interiors`, `test_player`), déjà présentes sur `dad5d5a` ; tous les tests passent. À ne pas confondre avec une régression du 3B.
