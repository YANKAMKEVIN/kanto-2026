# Jalon 3B — L'événement de la Route 1 : Chen ramène le joueur au labo

> Objectif jouable sur le S24 : le joueur a exploré Bourg Palette. Il monte vers le nord par la prairie, où un **Roucool** et un **Rattata** vivent leur vie, jusqu'aux **hautes herbes** qui ferment le chemin de la Route 1. Au moment d'y entrer, le **joystick cesse de répondre**, sans écran noir. Une voix arrive de derrière : **« ??? — Hé ! Attends ! »**. Le personnage se retourne. **Chen** arrive en courant depuis le village, s'arrête à côté de lui, reprend son souffle, puis parle (il regarde les herbes à sa deuxième réplique, et laisse un silence avant « ...Viens avec moi. »). Il repart vers le village, le joueur le **suit tout seul** quelques secondes, puis un fondu les amène au **laboratoire**. Le **rival est déjà là**. Il regarde Chen, puis le joueur : « Enfin. » / « Un peu de patience. » / « Ça fait une heure que tu dis ça. » / « Et pourtant, tu es toujours là. ». Le joueur récupère alors le contrôle : **le jalon 3 s'arrête là**.
>
> Pas d'« OBJECTIF MIS À JOUR », pas de marqueur, pas de bandes noires. Du gel à la dernière réplique, les contrôles tactiles sont cachés, comme pendant un dialogue de 3A. Les répliques passent par la **boîte de dialogue 2026** de 3A.
>
> C'est le jalon 3B du dossier 02 (§5 et arrivée du §6). Il termine la phase 3 « Interactions » : c'est le premier **événement scripté** du jeu.

**Pré-requis** : le jalon 3A ([`jalon-03.md`](jalon-03.md)) est **terminé et validé sur le S24** (T1 à T5). Le 3B s'appuie sur `GameState`, `StoryFlags`, le blocage par raisons, `Npc`, `NpcRoster`, `DialogueLibrary`, `DialogueRunner`, `InteractionController` et `ExplorationHud.set_controls_visible`, tels que décrits dans `jalon-03.md`. Voir le §8 : ce code n'est pas encore dans le dépôt.

**Hors périmètre** :
- **Jalon 4** (dossier 02 §6 suite à §10) : « Vous voulez tous les deux découvrir Kanto… », choix du starter, « Rencontrer », fiche légère, choix du rival, premier combat. Le 3B pose seulement les **points d'accroche** (§2.10).
- **Carte de la Route 1** (phase 9) : les hautes herbes du 3B sont au bord nord de Bourg Palette, sur le chemin qui y mène. Pas de nouvelle carte.
- **Rencontres sauvages** et système Pokémon : les herbes sont une tuile de décor et une donnée (`tall_grass`), sans aucune rencontre. L'effet « jambes cachées dans l'herbe » vient avec les rencontres.
- **Sauvegarde** : comme en 3A, l'état vit dans `GameState` sans sauvegarde. Quitter l'application recommence la partie (Q14).
- Caméra qui se déplace seule, bandes cinéma, sons, musique d'événement, vibrations, portraits.
- Choix oui/non, embranchements, scènes qui tournent en parallèle d'autres scènes.
- Rendu « vraie DA » de Chen, des herbes et des Pokémon de la prairie : sprites et tuiles provisoires aux dimensions finales.

Références : `CLAUDE.md`, **`docs/design/dossier-02-prologue.md` §5 et §6 (source de vérité des textes et des intentions)**, `docs/design/dossier-01-bourg-palette.md` (§6 Prairie du Nord, « Déroulé d'ouverture » point 4), `docs/design/ui-ux-bible-v0.1.md` §3 et §11, `docs/design/vision.md`, [`jalon-01.md`](jalon-01.md) §4, [`jalon-02.md`](jalon-02.md) §2.2 et §4.7, [`jalon-03.md`](jalon-03.md) (**toute** l'architecture de 3A, en particulier §2.5, §2.8 et §2.11), skills `godot-conventions`, `world-tiles` et `ui-theme-2026`.

---

## 1. Fondations logiques à poser (architecte, avant T1)

Classes pures et extensions de classes pures de 3A, avec leurs tests. Rien n'est encore écrit : c'est la première étape du 3B, sur le modèle du §1 de `jalon-03.md`.

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/world/grid_world.gd` (ajout) | `GridWorld` | `find_path(from, to, mover = null) -> Array[Vector2i]` : **plus court chemin** à pied (BFS), sous forme de **liste de directions**. Il respecte `get_step_target` (solides, eau, rebords, occupants autres que `mover`). Ordre d'exploration fixe (haut, bas, gauche, droite) : le chemin est reproductible. Vide si `from == to` ou si `to` est inaccessible. Sert au déplacement de Chen et remplacera le BFS de `tools/capture_play.gd`. |
| `game/world/grid_mover.gd` (ajout) | `GridMover` | `start_step(direction, run = false) -> bool` : lance **un pas scripté** depuis l'arrêt ou un pivot, **même verrouillé**. L'entité se tourne vers `direction`. Si la case est inaccessible, renvoie faux **sans** `bumped`. Pendant un pas, renvoie faux. Le pas se termine ensuite par `update()` comme un pas normal (`step_finished` émis). Le verrou continue d'ignorer les directions de `update()`. |
| `game/world/grid.gd` (ajout, **si 3A ne l'a pas déjà**) | `Grid` | `direction_from_name(name) -> Vector2i` (`"up"`, `"down"`, `"left"`, `"right"`, sinon ZERO) et `direction_name(dir) -> StringName`. Si 3A a mis cette conversion dans `NpcRoster`, on la **déplace** ici : les PNJ, les dialogues et les scènes l'utilisent tous les trois. |
| `game/systems/dialogue/dialogue_page.gd` (ajout) | `DialoguePage` | Champ **`turn`** : `Dictionary[StringName, StringName]`, acteur → cible, appliqué **au début de la page** (§2.7). Acteur = `"player"` ou identifiant de PNJ de la carte. Cible = nom de direction, `"player"` ou identifiant de PNJ. |
| `game/systems/dialogue/dialogue_library.gd` (ajout) | `DialogueLibrary` | Accepte et valide la clé de page `turn` : objet non vide, clés et valeurs = chaînes non vides. Une cible qui n'est ni une direction ni `"player"` est un identifiant, vérifié par les tests de cohérence (§3.6), pas par la bibliothèque. `get_turn_actors()` sert à ces tests. |
| `game/world/npc/npc_spec.gd` (ajout) | `NpcSpec` | **Présence conditionnelle** : `if_flags`, `unless_flags` (même sens que les variantes de dialogue), `is_present(flags: StoryFlags) -> bool`. |
| `game/world/npc/npc_roster.gd` (ajout) | `NpcRoster` | Clés d'entrée `if` et `unless` (listes de chaînes), validées. `static func parse_entry(entry: Dictionary, errors: PackedStringArray) -> NpcSpec` : validation d'une seule entrée, extraite du chargement de 3A et réutilisée par l'étape `spawn` des scènes (§2.3). L'unicité des identifiants reste vérifiée par fichier. |
| `game/world/triggers/event_trigger.gd` | `EventTrigger` | Donnée d'un déclencheur : `cell`, `direction` (direction du pas qui arrive sur la case, ZERO = toutes), `cutscene_id`. `is_valid()`, `matches_step(cell, direction)`. Calqué sur `Warp` en `STEP_ON`. |
| `game/world/triggers/trigger_table.gd` | `TriggerTable` | Déclencheurs d'une carte, indexés par case, calquée sur `WarpTable` : `add` refuse une entrée invalide ou ambiguë (même case, directions qui se recouvrent), `find_on_step(cell, direction)`, `get_all`, `size`. |
| `game/systems/cutscene/cutscene_step.gd` | `CutsceneStep` | Une étape de scène : `kind` (enum `Kind { WAIT, DIALOGUE, FACE, SET_FLAGS, SPAWN, MOVE, CHANGE_MAP }`) et ses paramètres typés (§2.3). |
| `game/systems/cutscene/cutscene.gd` | `Cutscene` | `id`, `if_flags`, `unless_flags`, `steps: Array[CutsceneStep]`, `source`. `matches(flags) -> bool`. |
| `game/systems/cutscene/cutscene_library.gd` | `CutsceneLibrary` | Lit **tous les `.json`** de `data/cutscenes/` (`load_dir`, `load_file`, `add_from_dict`), sur le modèle exact de `DialogueLibrary` : clé inconnue, type d'étape inconnu ou multiple, paramètre manquant, direction inconnue, forme de case invalide, identifiant en double d'un fichier à l'autre, JSON illisible (avec le numéro de ligne). Une scène invalide est **écartée entière**, signalée par `push_error` et `get_errors()`. `get_cutscene(id)`, `get_ids()`, `get_condition_flags()`, `get_set_flags()`. |
| `game/systems/cutscene/cutscene_moves.gd` | `CutsceneMoves` | Deux fonctions statiques pures. `resolve_cell(spec, grid, anchors: Dictionary[StringName, Vector2i]) -> Vector2i` : une case absolue `[x, y]`, ou `{ "near": acteur, "offsets": [[dx, dy], …] }` = la **première** case voisine praticable et libre, (-1, -1) si aucune. `follow_path(follower_cell, leader_cell, leader_path) -> Array[Vector2i]` : chemin du suiveur = un pas vers la case du meneur, puis les pas du meneur sauf le dernier (vide si les deux ne sont pas voisins). |

Tests à écrire avec ces classes : `tests/unit/test_grid_world.gd` (+ `find_path` : ligne droite, contournement, occupant évité, `mover` ignoré sur sa case, rebord, inaccessible → vide, même case → vide, reproductibilité), `test_grid_mover.gd` (+ `start_step` : verrouillé, bloqué sans `bumped`, refus pendant un pas, `step_finished` émis), `test_dialogue_library.gd` (+ `turn` valide et invalide), `test_npc_roster.gd` (+ `if`/`unless`, `is_present`, `parse_entry`), `tests/unit/test_event_trigger.gd`, `tests/unit/test_cutscene_library.gd`, `tests/unit/test_cutscene_moves.gd`, avec les données d'essai `tests/fixtures/cutscenes/*.json` (une valide, une par cas d'erreur).

---

## 2. Architecture

### 2.1 Arbre des scènes

```
game/boot.tscn
Boot (Node)  game/boot.gd                   racine de composition (câblage seulement)
├─ World (Node2D)               %World
├─ ExplorationHud (instance)    %ExplorationHud     inchangé depuis 3A
├─ DialogueBox (instance)       %DialogueBox        inchangé depuis 3A
├─ DialogueRunner (Node)        %DialogueRunner     + clé de page `turn` (§2.7)
├─ InteractionController (Node) %InteractionController  + set_enabled() (§2.4)
├─ CutsceneDirector (Node)      %CutsceneDirector   game/systems/cutscene/cutscene_director.gd (nouveau, T2)
└─ ScreenFade (instance)        %ScreenFade

Autoloads : SceneRouter (une règle en plus, §2.4) · GameState (inchangé, deux drapeaux de plus)
```

Structure d'une carte : le nœud **`Triggers`** existe déjà dans les 6 cartes (jalons 1 et 2, vide). Il reçoit des `EventTriggerPoint` (§2.2), écrits par les scripts de construction à partir de tables, comme les `WarpPoint` et les `InteractPoint`.

`Boot._ready` (changements par rapport à 3A) :
```gdscript
var cutscenes := CutsceneLibrary.new()
cutscenes.load_dir()                                         # data/cutscenes/
%CutsceneDirector.setup(cutscenes, GameState.flags, %DialogueRunner, _player, SceneRouter)
# 3A branchait SceneRouter.map_changed directement sur InteractionController.set_map.
# 3B passe par Boot, pour garantir l'ordre : présence des PNJ d'abord, puis contrôleurs.
SceneRouter.map_changed.connect(_on_map_changed)
%CutsceneDirector.cutscene_started.connect(_on_cutscene_started)
%CutsceneDirector.cutscene_finished.connect(_on_cutscene_finished)
# … le reste de 3A, puis SceneRouter.start(...) (tous les signaux branchés AVANT start)

func _on_map_changed(map: GameMap) -> void:
	map.refresh_npcs(GameState.flags)            # §2.6
	%InteractionController.set_map(map)
	%CutsceneDirector.set_map(map)

func _on_cutscene_started(_id: StringName) -> void:
	%InteractionController.set_enabled(false)
	_refresh_controls()

func _on_cutscene_finished(_id: StringName) -> void:
	%InteractionController.set_enabled(true)
	_refresh_controls()

## Contrôles visibles seulement hors dialogue et hors scène (3A les rétablissait à
## dialogue_finished : pendant une scène, ils doivent rester cachés entre deux dialogues).
func _refresh_controls() -> void:
	_hud.set_controls_visible(not %DialogueRunner.is_running() and not %CutsceneDirector.is_running())
```
Les gestionnaires `_on_dialogue_started` / `_on_dialogue_finished` de 3A appellent aussi `_refresh_controls()` au lieu de `set_controls_visible(true/false)`.

### 2.2 Hautes herbes et déclencheur

**Tuile** : `OverworldTiles.Kind.TALL_GRASS`, ajoutée **en fin d'enum** (les coordonnées d'atlas des autres types ne bougent pas), 2 variantes, praticable, donnée `tall_grass = true` (la couche de données existe depuis le jalon 1, jamais utilisée). `GridWorld` ne la lit pas encore : les rencontres (jalon 5) le feront. Tuile provisoire : herbe plus haute et plus sombre que l'herbe rase, brins lisibles à l'écran (Q16).

**Déclencheur** : `EventTriggerPoint` (`game/world/triggers/event_trigger_point.gd`, `extends Marker2D`), enfant de `Triggers`, sur le modèle d'`InteractPoint` :
```gdscript
class_name EventTriggerPoint
extends Marker2D                    # position = Grid.cell_to_world(case d'ancrage)
@export var cutscene_id: StringName = &""
## Cases couvertes depuis l'ancre (bas-gauche) : x 0..size.x-1, y -(size.y-1)..0.
@export var size: Vector2i = Vector2i.ONE
## Direction du pas qui arrive sur la case (ZERO = toutes).
@export var direction: Vector2i = Vector2i.ZERO
func get_cell() -> Vector2i
func to_triggers() -> Array[EventTrigger]      # un par case couverte
```
`GameMap` (modifié) construit `get_triggers() -> TriggerTable` avec la grille, comme `get_warps()` et `get_interactions()`. Une entrée invalide ou ambiguë donne `push_error("GameMap <id> : déclencheur invalide en <case>")`.

Le déclencheur ne porte **aucune condition** : les conditions (`if` / `unless`) sont dans la scène (§2.3). Un déclencheur dont la scène ne s'applique plus ne fait rien. C'est ce qui le désarme après son passage (drapeau `oak_met`), sans rien retirer de la carte.

**Qui écoute** : `CutsceneDirector`, sur `player.moved(cell)` (comme `SceneRouter` pour les warps). Il ignore le pas si une scène tourne, si le routeur est en transition, ou si le joueur est bloqué (pas scripté, §2.5). Sinon : `trigger = map.get_triggers().find_on_step(cell, player.get_facing())`, puis `play(trigger.cutscene_id)`. Le blocage `&"cutscene"` est posé **dans l'appel même**, donc dans le `step_finished` du joueur : comme pour les portes (jalon 2 §2.2), le verrou empêche le pas qui s'enchaînerait, même doigt maintenu ou en courant. C'est « le joystick cesse brièvement de répondre ».

Une case ne porte **jamais** à la fois un warp et un déclencheur (invariant testé, §3.6) : l'ordre des deux auditeurs de `moved` n'a donc pas d'importance.

### 2.3 Scènes scriptées : format des données (`data/cutscenes/*.json`)

Une scène est une **liste d'étapes jouées dans l'ordre**, sans embranchement ni parallélisme. Comme les dialogues, c'est une donnée : Kevin peut régler un délai, un chemin ou une orientation sans l'éditeur Godot, et aucun `if cutscene == "oak_intercept"` n'existe dans le code. Chaque fichier est un objet `identifiant → scène`, et les identifiants sont uniques dans tout le dossier. Format complet en tête de `cutscene_library.gd`.

Clés d'une scène : `if`, `unless` (drapeaux, comme les variantes de dialogue), `steps` (liste). Chaque étape a **exactement une** clé de type :

| Étape | Clés | Effet |
|---|---|---|
| `wait` | `"wait": secondes` | Temps mort (souffle, silence sans texte). |
| `dialogue` | `"dialogue": id` | `runner.play(id, null, map)`, puis attend `dialogue_finished`. La mise en scène **pendant** le dialogue passe par les clés de page (`turn`, `pause`, `react`). |
| `face` | `"face": acteur`, `"to": cible` | L'acteur se tourne. Cible = direction (`"up"`…), `"player"` ou identifiant de PNJ (axe dominant, comme `Npc.face_toward` de 3A). |
| `set` | `"set": [drapeaux]` | Lève des drapeaux dans `GameState.flags`, **tout de suite** (avant un changement de carte, par exemple). |
| `spawn` | `"spawn": id`, `"sprite"`, `"at": case`, `"facing"`, et les clés facultatives d'une entrée de `NpcRoster` | Crée un PNJ **pour la durée de la carte** (`GameMap.add_npc`). La spécification passe par `NpcRoster.parse_entry` : mêmes règles que les PNJ des fichiers `data/npcs/`. |
| `move` | `"move": acteur`, **soit** `"path": [directions]`, **soit** `"to": case` ; `"run"` (faux par défaut) ; `"follower"` (acteur, facultatif) | Déplace l'acteur case par case. `to` : chemin calculé au début de l'étape (`GridWorld.find_path`). `follower` : un second acteur suit le meneur à un pas derrière (`CutsceneMoves.follow_path`). L'étape attend que les deux soient arrivés. |
| `change_map` | `"change_map": id`, `"spawn"`, `"facing"` | `await router.change_map(id, spawn, facing)`, avec son fondu habituel. |

**Acteurs** : `"player"`, ou l'identifiant d'un PNJ de la carte courante (fichier `data/npcs/` ou `spawn` antérieur). **Cases** : `[x, y]` absolue, ou `{ "near": acteur, "offsets": [[dx, dy], …] }` = la première case libre et praticable autour de l'acteur, dans l'ordre donné (`CutsceneMoves.resolve_cell`).

Pourquoi des données plutôt qu'un script GDScript par scène : la règle 3 du projet (contenu = données), la même validation stricte que les dialogues (faute de frappe attrapée au lancement et dans les tests), et un vocabulaire de 7 étapes qui suffit au 3B et au jalon 4 (Chen qui parle, le starter qui s'approche, le rival qui choisit, le rival qui se retourne avant le combat). On n'ajoute **ni** condition par étape, **ni** boucle, **ni** parallélisme tant qu'aucune scène n'en a besoin.

**Export Android** : `data/cutscenes/*.json` doit partir dans l'APK comme `data/dialogues/` et `data/npcs/` (même `include_filter` que 3A si besoin ; vérifié en T4).

### 2.4 `CutsceneDirector`

`game/systems/cutscene/cutscene_director.gd` (Node, enfant de `Boot`). C'est le **seul** à jouer une scène. Il ne décide rien : il lit la scène et appelle les nœuds déjà existants (`DialogueRunner`, `Npc`, `Player`, `GameMap`, `SceneRouter`).
```gdscript
signal cutscene_started(cutscene_id: StringName)
signal step_started(index: int)                      # tests, outils de capture
signal cutscene_finished(cutscene_id: StringName)
## Un pas bloqué (case occupée) est retenté à chaque image ; au-delà, l'étape est abandonnée.
const MOVE_BLOCK_TIMEOUT: float = 2.0
## [param router] : l'autoload SceneRouter en jeu, une instance de scene_router.gd en test.
func setup(library: CutsceneLibrary, flags: StoryFlags, runner: DialogueRunner,
		player: Player, router: Node) -> void
func set_map(map: GameMap) -> void                   # relais de Boot sur map_changed
## Faux (et rien ne se passe) si une scène tourne, si l'identifiant est inconnu (push_error)
## ou si ses conditions ne s'appliquent pas (sans erreur : c'est un déclencheur désarmé).
func play(cutscene_id: StringName) -> bool
func is_running() -> bool
func get_step_index() -> int                         # −1 hors scène
```
Déroulé :
1. `play` : `player.set_input_enabled(false, &"cutscene")` **de façon synchrone**, puis `cutscene_started`. `Boot` coupe alors l'`InteractionController` et cache les contrôles (§2.1). `set_process(true)`.
2. Les étapes s'enchaînent dans une coroutine. Avant chaque étape : `step_started(index)`. Les acteurs sont **résolus à chaque étape** dans la carte courante (`map.get_npc(id)`, ou le joueur) : une scène traverse un changement de carte sans garder de référence périmée. Un acteur introuvable donne `push_error` et l'étape est sautée (la scène continue).
3. `move` : `_process` pilote les pas. Quand le meneur est à l'arrêt, il lance le pas suivant (`npc.step` ou `player.script_step`, §2.5). Le suiveur lance le sien **dans la même image, juste après** : la case que le meneur quitte est libérée dès le départ de son pas (`GridWorld.move_occupant`). Aucune allocation par image : les chemins sont calculés au début de l'étape.
4. `change_map` : si, après l'`await`, la carte courante n'est pas la carte demandée (erreur du routeur), `push_error` et la scène **s'arrête** (étape 5).
5. Fin (ou arrêt) : `player.set_input_enabled(true, &"cutscene")`, `set_process(false)`, puis `cutscene_finished`. Comme pour le routeur, un compteur de session abandonne proprement une scène dont le `setup` a été rappelé (tests de `Boot`).

**Blocage** (raisons de 3A, `jalon-03.md` §2.8) : la scène tient `&"cutscene"` du début à la fin. Le `DialogueRunner` prend et rend `&"dialogue"` à chaque dialogue, et le routeur prend et rend `&"transition"` pendant le fondu. Le joueur n'est libre que lorsque plus aucune raison n'est active : c'est exactement le cas prévu par 3A.

**Deux petites règles ajoutées ailleurs** :
- `SceneRouter._on_player_moved` ignore le pas si `not player.is_input_enabled()`. Un pas **scripté** ne prend donc jamais une porte. Les tests du routeur restent verts sans modification (en 3A, un pas normal se fait toujours joueur libre).
- `InteractionController.set_enabled(enabled: bool)` : désactivé, il n'a plus de cible (`target_changed(-1)`), ignore `interact` et **ne lance pas** de dialogue automatique sur `on_map_entered`. Sans cela, l'arrivée au labo pendant la scène pourrait jouer une variante `auto`. Réactivé, il recalcule sa cible à l'image suivante.

### 2.5 Des PNJ qui marchent, un joueur qu'on déplace

**`Npc`** (3A, modifié) : il possède désormais un `GridMover`, comme le joueur (3A l'avait prévu, `jalon-03.md` §2.11).
```gdscript
signal step_finished(cell: Vector2i)
## Remplace le grid.occupy(cell, npc) de 3A : GridMover.place(spec.cell, spec.facing).
func enter_grid(grid: GridWorld) -> bool
func leave_grid() -> void                          # libère sa case
## Un pas (marche, ou course si [param run]). Faux si bloqué ou déjà en marche.
func step(direction: Vector2i, run: bool = false) -> bool
func is_moving() -> bool
```
- `get_cell()` et `face()` passent par le `GridMover`. `_process` ne tourne **que pendant un pas** (`position = mover.get_world_position().round()`), puis se coupe : aucun coût au repos, comme en 3A.
- Animations : `walk_<dir>` ou `run_<dir>` pendant un pas si elles existent, sinon `idle_<dir>`. Les Pokémon du décor, qui n'ont pas d'animation de marche, restent valides.
- Un Pokémon posé sur un meuble (`lift > 0`) occupe toujours une case solide : `GridMover.place` passe par `occupy`, qui ne teste pas la solidité (comportement de 3A conservé).
- `GameMap` : `add_npc(spec) -> Npc` (création, ajout à `Entities`, `enter_grid` ; `push_error` et null si la case est prise ou hors carte), `remove_npc(id)`. `rebuild_grid()` rappelle `enter_grid` pour chaque PNJ.

**`Player`** (modifié) :
```gdscript
## Pas scripté : ignore le blocage des entrées (scènes). Faux si bloqué ou déjà en marche.
func script_step(direction: Vector2i, run: bool = false) -> bool   # GridMover.start_step
```
Le pas se termine dans `_process` comme un pas normal, avec les animations de marche. `moved` est émis : le routeur l'ignore (joueur bloqué, §2.4), le directeur aussi.

**Sprite provisoire de Chen** (`tools/gen_placeholder_npcs.gd` de 3A, étendu) : `oak`, personne 32 × 64 natif (×2), **blouse blanche, cheveux gris**, repère de direction, avec `idle_<dir>`, `walk_<dir>` et `run_<dir>` (4 images par direction pour la marche, comme le joueur). Le générateur gagne la possibilité de produire la marche pour les sprites qui en ont besoin (ici `oak` seulement).

### 2.6 Présence conditionnelle des PNJ

Prévue par 3A (§2.11). Une entrée de `data/npcs/<map_id>.json` peut porter `if` et `unless` (§1, `NpcSpec.is_present`).

`GameMap` ne connaît toujours pas `GameState` (règle de 3A) : on lui **passe** les drapeaux.
```gdscript
## Crée les PNJ présents pour [param flags] qui manquent, retire ceux qui ne le sont plus.
func refresh_npcs(flags: StoryFlags) -> void
```
- `_ready` crée les PNJ présents **pour des drapeaux vides** (état « nouvelle partie ») : les tests de 3A et les outils qui chargent une carte seule voient le même état qu'avant.
- `Boot._on_map_changed` appelle `refresh_npcs(GameState.flags)` **avant** de passer la carte aux contrôleurs. `map_changed` est émis écran noir (et de façon synchrone par `SceneRouter.start`) : un PNJ ajouté ou retiré n'est jamais vu apparaître.
- La présence n'est **réévaluée qu'au chargement de la carte**. Lever un drapeau ne fait pas apparaître un PNJ sur la carte où l'on se trouve. Ce qui doit changer sous les yeux du joueur passe par une scène (`spawn`, `move`).

### 2.7 Dialogues : clé de page `turn`

Les didascalies du dossier 02 §5 et §6 ne tiennent pas dans `face_player` : « il regarde les hautes herbes » tourne Chen vers le nord, et dans la scène du labo chacun se tourne vers celui à qui il répond. 3B ajoute une clé de page, dans l'esprit de la convention de 3A (didascalie → mise en scène, jamais du texte affiché) :
```json
{ "text": "…", "speaker": "Chen", "turn": { "oak": "up", "player": "oak" } }
```
Au **début de la page**, après `show_page` et avant `face_player` et `react`, le `DialogueRunner` applique chaque paire dans l'ordre : l'acteur (`"player"` → `player.face()`, sinon `map.get_npc(id)`) se tourne vers la cible (direction, `"player"` ou PNJ, axe dominant). Un identifiant inconnu donne `push_warning` et la suite continue, comme `react` en 3A. `face_player` reste valable et inchangé.

### 2.8 `GameState` et drapeaux

Aucun changement de `GameState`. Deux drapeaux de plus :

| Drapeau | Levé par | Lu par |
|---|---|---|
| `oak_met` | la scène `oak_intercept`, étape `set`, juste après les répliques de Chen et **avant** le retour | la scène elle-même (`unless`, un seul passage), la présence de Chen et du rival au labo, l'absence du rival chez lui, l'état de Maya (§3.2) |
| `oak_lab_reunion` | dernière étape de la scène, après « Et pourtant, tu es toujours là. » | le jalon 4 (§2.10) ; aucun lecteur en 3B |

Le test de 3A « chaque drapeau lu est levé quelque part » s'étend aux scènes et aux fichiers de PNJ (§3.6). `oak_lab_reunion` est levé sans être lu : c'est autorisé (accroche du jalon 4).

### 2.9 Signaux et flux

```
Player.moved(cell) ──► CutsceneDirector ─► map.get_triggers().find_on_step(cell, facing)
                                         ─► library.get_cutscene(id).matches(flags) ?
                                         ─► play(id) : Player.set_input_enabled(false, &"cutscene")
                                                       cutscene_started ─► Boot ─► InteractionController.set_enabled(false)
                                                                                 ─► hud.set_controls_visible(false)
étapes :
  wait        ─► minuterie
  dialogue    ─► DialogueRunner.play(id, null, map) … dialogue_finished
                 (page : turn ─► Player.face / Npc.face_toward · pause · react)
  face        ─► Player.face / Npc.face / Npc.face_toward
  set         ─► GameState.flags.set_flag(…)
  spawn       ─► NpcRoster.parse_entry ─► GameMap.add_npc(spec)
  move        ─► _process : Npc.step / Player.script_step (+ suiveur) ─► GridMover
  change_map  ─► SceneRouter.change_map ─► map_changed ─► Boot ─► map.refresh_npcs(flags)
                                                              ─► InteractionController.set_map · CutsceneDirector.set_map
fin ─► Player.set_input_enabled(true, &"cutscene") ─► cutscene_finished ─► Boot ─► contrôleur réactivé, HUD rétabli
```
`GameMap`, `Npc`, `Player`, le HUD et `DialogueRunner` ne connaissent pas `CutsceneDirector`. `CutsceneDirector` ne lit pas l'autoload `GameState` (il reçoit `GameState.flags`), et reçoit le routeur par `setup` : il est testable avec une instance de `scene_router.gd` et un `StoryFlags` neuf. `Boot` reste la seule racine de composition.

### 2.10 Points d'accroche pour le jalon 4

- **Suite immédiate de la scène** : le §7 du dossier 02 suit la dernière réplique du §6. Le jalon 4 **ajoute des étapes** à la fin de `oak_intercept` (Chen parle aux deux, puis l'interface du choix). Autre possibilité : une scène séparée, conditionnée par `oak_lab_reunion`. Le jalon 4 tranchera.
- **Sortie du labo avant le choix** : si le jalon 4 veut empêcher de ressortir, un `EventTriggerPoint` sur le tapis de sortie (PUSH n'existe que pour les warps : il faudra une case de déclencheur devant le tapis) et une scène conditionnée par `if: [oak_met]`, `unless: [starter_chosen]`, avec le texte que Kevin donnera.
- **« Rencontrer »** : une valeur de plus dans `Interaction.Kind` (prévu en 3A). Le starter qui s'approche du joueur : étape `move` d'un PNJ Pokémon.
- **Premier combat** : une étape de plus (`battle`) le moment venu, sur le même modèle.
- **Hautes herbes** : `tall_grass` est déjà dans les tuiles ; le jalon 5 le lira dans `GridWorld` pour les rencontres.

---

## 3. Données du jalon

Tolérance **±2 cases** en extérieur, **±1** en intérieur, du moment que les invariants du §3.6 tiennent (Q1, Q9).

### 3.1 Bourg Palette : herbes, déclencheur, prairie

Rappel (jalon 1 §4.1) : le chemin de la Route 1 occupe x 23–24, y 0–11, entre deux clôtures en bois x 22 et x 25 sur y 0–3. La rangée y 0 est bloquée (`blocked_cells`) : le joueur s'arrête en y 1.

| Élément | Où | Détail |
|---|---|---|
| **Hautes herbes** | (23..24, 0..2) | Tuile `TALL_GRASS` à la place du chemin de terre, entre les clôtures. y 0 reste bloquée. (Q1) |
| **Déclencheur** `Route1Intercept` | ancre (23, 3), `size` (2, 1), `direction` ZERO | Couvre (23, 3) et (24, 3) : la case **juste avant** les herbes, sur les deux colonnes du chemin. Scène `oak_intercept`. (Q2) |
| Arrivée de Chen | apparition en (24, 13) | Sur la place, **hors de l'écran** quand le joueur est en y 3 (la vue montre les rangées 0 à 11). (Q6) |
| **Roucool** `prairie_pidgey` | (18, 2), bas | `pidgey` (sprite de 3A), non interactif (Q4) |
| **Rattata** `prairie_rattata` | (29, 2), gauche | `rattata` (sprite de 3A), non interactif (Q4) |

`data/npcs/pallet_town.json` (ajout aux entrées de 3A) :
```json
{ "id": "prairie_pidgey", "cell": [18, 2], "facing": "down", "sprite": "pidgey" },
{ "id": "prairie_rattata", "cell": [29, 2], "facing": "left", "sprite": "rattata" }
```
(Les noms exacts des clés sont ceux du format de `npc_roster.gd` de 3A.)

### 3.2 PNJ conditionnels

| Carte | id | Case | Orient. | sprite | dialogue | Présence | Remarques |
|---|---|---|---|---|---|---|---|
| `rival_house` | `rival` | (13, 4) | droite | `rival` | `rival` | `unless: [oak_met]` | entrée de 3A, avec la condition en plus : après l'événement, il est au labo (Q12) |
| `oak_lab` | `maya` | (5, 3) | haut | `maya` | `maya` | `unless: [oak_met]` | entrée de 3A, avec la condition en plus |
| `oak_lab` | `maya_working` | (5, 3) | haut | `maya` | — | `if: [oak_met]` | même personne, **non interactive** : sa réplique « Il est sorti tôt ce matin. » serait fausse avec Chen présent (Q11) |
| `oak_lab` | `oak` | (8, 4) | bas | `oak` | — | `if: [oak_met]` | la case réservée depuis le jalon 2 ; non interactif en 3B (Q10) |
| `oak_lab` | `rival` | (9, 6) | droite | `rival` | — | `if: [oak_met]` | tourné vers les starters ; non interactif en 3B (Q9, Q10) |

Pourquoi (9, 6) et pas la case (11, 6) laissée libre en 3A : (11, 6) est la **seule** case d'où l'on observe Salamèche (table en (10..12, 4..5), Pokémon en (10..12, 5)). Le rival y fermerait l'accès, et un PNJ en (10, 6), (12, 6) ou (13, 3..6) couperait un bout de la pièce. En (9, 6), sur le grand tapis, il ne ferme rien, il est à côté des starters, et les deux orientations « vers Chen » (haut) puis « vers le joueur » (gauche) se voient à l'écran. (8, 4) et (11, 6) : voir §3.6.

### 3.3 Dialogues (textes du dossier 02, **définitifs**)

Ajouts à `data/dialogues/pallet_town.json` (l'événement a lieu sur cette carte) :
```json
{
	"oak_route1_call": {
		"speaker": "???",
		"pages": ["Hé ! Attends !"]
	},
	"oak_route1_warning": {
		"speaker": "Chen",
		"pages": [
			{ "text": "Tu allais vraiment entrer là-dedans tout seul ?",
				"turn": { "oak": "player" } },
			{ "text": "Les Pokémon qui vivent ici ne sont pas tous aussi tranquilles que ceux du village.",
				"turn": { "oak": "up" } },
			{ "text": "Sans Pokémon à tes côtés, tu prends un risque inutile.",
				"turn": { "oak": "player" } },
			{ "text": "...Viens avec moi.", "pause": 1.0 }
		]
	}
}
```
Ajout à `data/dialogues/oak_lab.json` :
```json
{
	"oak_lab_reunion": {
		"pages": [
			{ "speaker": "Rival", "text": "Enfin." },
			{ "speaker": "Chen", "text": "Un peu de patience.", "turn": { "oak": "rival" } },
			{ "speaker": "Rival", "text": "Ça fait une heure que tu dis ça.", "turn": { "rival": "oak" } },
			{ "speaker": "Chen", "text": "Et pourtant, tu es toujours là." }
		]
	}
}
```
- Découpage de 3A (Q2 de `jalon-03.md`) : une réplique « … » = une page. Didascalies : « il regarde les hautes herbes » → `turn` vers le nord ; « il réfléchit une seconde » → `pause` de **1,0 s** (le dossier dit « une seconde », plus long que les silences de 0,6 à 0,8 s de 3A) ; « Il regarde Chen, puis le joueur » → étapes `face` de la scène, avant le dialogue (§3.4) ; « légèrement essoufflé » → temps mort avant la première réplique (§3.4, Q6).
- « Hé ! Attends ! » est un **dialogue à part** : entre cette réplique et celles de Chen, la boîte se ferme, le joueur se retourne et Chen arrive (Q5).
- Étiquettes : « ??? », « Chen », « Rival », comme dans le dossier 02 (Q13).
- Le dossier 01 (« Déroulé d'ouverture », point 4) donne « Viens avec moi. J'ai quelque chose à te montrer. ». Le dossier 02, **définitif**, donne « ...Viens avec moi. » : on prend le dossier 02 (Q17).
- `oak_lab_reunion` n'a pas de `speaker` au niveau du dialogue : chaque page porte le sien (clé déjà prévue par 3A, §2.4).
- Aucun texte `draft` dans le 3B.

### 3.4 Scène `oak_intercept` (`data/cutscenes/prologue.json`)

Valeurs par défaut des questions Q5 à Q10, **réglables dans ce fichier seul**.
```json
{
	"oak_intercept": {
		"unless": ["oak_met"],
		"steps": [
			{ "wait": 0.4 },
			{ "dialogue": "oak_route1_call" },
			{ "face": "player", "to": "down" },
			{ "wait": 0.3 },
			{ "spawn": "oak", "sprite": "oak", "at": [24, 13], "facing": "up" },
			{ "move": "oak", "run": true,
				"to": { "near": "player", "offsets": [[1, 0], [-1, 0], [0, 1]] } },
			{ "face": "oak", "to": "player" },
			{ "face": "player", "to": "oak" },
			{ "wait": 0.6 },
			{ "dialogue": "oak_route1_warning" },
			{ "set": ["oak_met"] },
			{ "move": "oak", "follower": "player",
				"path": ["down", "down", "down", "down", "down", "down", "down", "down"] },
			{ "change_map": "oak_lab", "spawn": "entrance", "facing": "up" },
			{ "move": "player", "path": ["up", "up"] },
			{ "wait": 0.3 },
			{ "face": "rival", "to": "oak" },
			{ "wait": 0.5 },
			{ "face": "rival", "to": "player" },
			{ "wait": 0.3 },
			{ "dialogue": "oak_lab_reunion" },
			{ "set": ["oak_lab_reunion"] }
		]
	}
}
```
Ce que cela donne, pas à pas :
1. Le joueur arrive en (23, 3) ou (24, 3) : gel immédiat, 0,4 s de silence, puis « ??? — Hé ! Attends ! ». Le joueur regarde encore les herbes.
2. Boîte fermée : il se retourne (bas). 0,3 s plus tard, Chen apparaît hors de l'écran en (24, 13) et **court** jusqu'à la case voisine du joueur sur l'autre colonne du chemin : (24, 3) si le joueur est en (23, 3), sinon (23, 3), la clôture fermant l'autre côté. Environ 1,2 s de course.
3. Chen et le joueur se font face. 0,6 s de souffle. Les quatre répliques de Chen : il regarde les herbes à la deuxième, revient au joueur à la troisième, silence d'une seconde avant « ...Viens avec moi. ».
4. `oak_met` est levé. Chen descend le chemin sur 8 cases (environ 1,8 s en marchant) ; le joueur le suit, un pas derrière (son premier pas le met sur la case que Chen vient de quitter).
5. Fondu (celui du routeur, 0,45 s). Au labo : Chen est déjà à sa place (8, 4), le rival en (9, 6) tourné vers les starters, Maya à son écran (non interactive). Le joueur apparaît sur le tapis d'entrée (7, 9) et fait deux pas vers le haut, jusqu'en (7, 7).
6. Le rival se tourne vers Chen (haut), puis vers le joueur (gauche). Les quatre répliques ; Chen se tourne vers le rival pour répondre, le rival vers Chen.
7. `oak_lab_reunion` est levé, le joueur récupère le contrôle. **Fin du jalon 3.**

### 3.5 Ce qui se passe ensuite (défauts, Q10)

- Au labo, Chen et le rival restent en place, **non interactifs** : le dossier ne leur donne pas d'autre réplique. On peut ressortir.
- Le déclencheur ne se relance plus (`unless: [oak_met]`). Les herbes sont praticables, sans rencontre (il n'y en a pas avant le jalon 5).
- Chez le rival : il n'est plus là. Sa carte de Kanto s'examine toujours.
- Maman, Mme Aoki, Léo, Haru, le panneau : inchangés.

Cet état n'existe que dans le 3B : le jalon 4 enchaîne directement sur le §7 du dossier 02 (§2.10).

### 3.6 Invariants (testés)

**Bourg Palette** (`test_pallet_town.gd`, étendu) :
- les cases `TALL_GRASS` sont exactement (23..24, 0..2) ; les invariants du jalon 1 §4.4 restent vrais ((23, 1) et (24, 1) atteignables, (23, 0) et (24, 0) non) ;
- **on ne peut pas atteindre les herbes sans passer par le déclencheur** : sur une grille où (23, 3) et (24, 3) sont rendues solides, `find_reachable` depuis `start` n'atteint aucune case `TALL_GRASS` ;
- les cases du déclencheur sont praticables, atteignables, et ne sont ni un warp, ni un spawn, ni la case d'un PNJ (pour tout état de drapeaux) ;
- la case d'apparition de Chen (24, 13) est praticable et libre de tout PNJ ; pour le joueur en (23, 3) comme en (24, 3), `resolve_cell` trouve la case voisine attendue, et `find_path` depuis (24, 13) y mène ;
- depuis les deux cases de Chen possibles, les 8 pas vers le bas sont libres (ni solide, ni PNJ, ni warp, ni déclencheur), et le chemin du suiveur aussi ;
- les Pokémon de la prairie respectent les invariants de 3A (§3.4 de `jalon-03.md` : case praticable, aucune poche).

**PNJ conditionnels** (`test_npc_placement.gd` de 3A, étendu) : les invariants de 3A sont vérifiés **pour deux états** : drapeaux vides (état de 3A, inchangé : Chen et le rival absents du labo, Maya interactive) et `{ oak_met }` (Chen en (8, 4), rival en (9, 6), `maya_working`, rival absent de sa maison). Dans les deux états : aucune poche, chaque cible interactive utilisable (**les trois starters restent observables**), (11, 6) libre et atteignable, et deux entrées de même case ne sont jamais présentes ensemble. Depuis `entrance` (7, 9), les deux pas vers le haut de la scène sont libres.

**Cohérence des données** (`tests/integration/test_cutscene_data.gd`, nouveau, et `test_dialogue_data.gd` de 3A, étendu) :
- `CutsceneLibrary.load_dir()` sur `data/cutscenes/` : aucune erreur ;
- chaque `cutscene_id` d'`EventTriggerPoint` (6 cartes) existe ; chaque `dialogue` d'étape existe dans `data/dialogues/` ; chaque `change_map` vise une carte et un spawn existants ;
- **simulation statique** de chaque scène : on part de la carte de son déclencheur, avec les drapeaux qui satisfont ses conditions ; on ajoute les `set` et les `spawn` au fil des étapes ; à chaque `change_map`, on passe aux PNJ **présents** de la carte cible pour les drapeaux du moment. Chaque acteur d'étape et chaque acteur ou cible de `turn` des dialogues joués existe à ce moment-là ;
- chaque drapeau lu (variantes de dialogue, scènes, entrées de PNJ) est levé par au moins un `set` (dialogue ou scène) ;
- chaque page des nouveaux dialogues tient en `DIALOG_MAX_LINES` lignes (test de 3A, qui couvre déjà tous les fichiers).

---

## 4. Découpage des tâches (dans l'ordre)

Chaque tâche finit par un essai sur le S24 (capture et retour de Kevin) avant la suivante. Aucune tâche `ui-mobile` : le 3B réutilise la boîte de dialogue, le bouton contextuel et `set_controls_visible` de 3A sans les changer. Si l'essai de T2 montre un problème de lisibilité de l'étiquette « ??? », il deviendra une tâche `ui-mobile`.

### T1 — constructeur-monde : les hautes herbes et la prairie habitée
- `OverworldTiles.Kind.TALL_GRASS` (fin d'enum, 2 variantes, `tall_grass = true`), `tools/gen_placeholder_tiles.gd` (atlas et TileSet régénérés) ; `tools/build_pallet_town.gd` : herbes en (23..24, 0..2), carte régénérée ; `data/npcs/pallet_town.json` : Roucool et Rattata de la prairie (§3.1).
- **CA** :
  - `test_overworld_tileset.gd` : `TALL_GRASS` a ≥ 2 variantes, `tall_grass` vrai, non solide, pas d'eau ; les coordonnées d'atlas des types existants n'ont pas bougé ; tous les autres types ont `tall_grass` faux.
  - `test_pallet_town.gd` : cases `TALL_GRASS` exactes, invariants du jalon 1 inchangés, Pokémon de la prairie conformes (§3.6).
  - Capture Movie Maker (`tools/capture_play.gd`, scénario `route1_grass`) à 2340 × 1080, joueur en (23, 4), lue avec Read : herbes nettement distinctes du chemin et de l'herbe rase, Roucool et Rattata visibles dans la prairie, clôtures intactes.
  - **S24** : monter jusqu'aux herbes, y entrer (rien ne se passe encore), en ressortir.
  - Import sans erreur ; `tools/test.sh` vert.

### T2 — constructeur-monde : le déclencheur, le gel et « Hé ! Attends ! »
- `EventTriggerPoint` ; `GameMap.get_triggers()` ; `CutsceneDirector` avec les étapes `wait`, `dialogue`, `face` et `set` (les autres types sont validés par la bibliothèque mais **pas encore joués** : `push_error` et étape sautée) ; `InteractionController.set_enabled` ; règle du routeur (§2.4) ; câblage de `Boot` (§2.1) ; déclencheur `Route1Intercept` dans `build_pallet_town.gd` ; `oak_route1_call` ; `data/cutscenes/prologue.json` **réduit aux étapes 1 à 4 et à `set`** (le joueur se retourne, puis reprend la main).
- **CA** :
  - `test_game_map.gd` (mini-carte) : un `EventTriggerPoint` 2 × 1 donne 2 déclencheurs dans `get_triggers()` ; deux en conflit sur une case : `push_error` attendu ; `find_on_step` respecte `direction`.
  - `tests/integration/test_cutscene_director.gd` (mini-carte, vraie `DialogueBox`, `StoryFlags` neuf, fixtures, `chars_per_second = 0`, fondus à 0) : `play` bloque le joueur **dans la même image** et émet `cutscene_started` ; `wait` dure le temps demandé (± 1 image) ; `dialogue` attend la fin du dialogue ; `face` vers une direction, vers `"player"` et vers un PNJ ; `set` lève le drapeau avant l'étape suivante ; à la fin, joueur libre et `cutscene_finished`. Conditions fausses : `false`, sans erreur. Identifiant inconnu : `false` et `push_error`. `play` pendant une scène : `false`. Un blocage `&"transition"` actif à la fin laisse le joueur bloqué.
  - Même fichier : un pas terminé sur une case de déclencheur lance la scène **dans le `moved`**, et le pas suivant ne part pas avec `move_up` tenu ; aucun déclenchement si la scène ne s'applique plus, ni pendant une transition.
  - `test_interaction_controller.gd` : désactivé, `target_changed(-1)`, `interact` ignoré, pas de dialogue automatique à `on_map_entered` ; réactivé, la cible revient.
  - `test_scene_router.gd` : **inchangé et vert** ; un test en plus : un pas qui se termine sur une porte, joueur bloqué, ne change pas de carte.
  - `test_boot.gd` : contrôles cachés pendant toute la scène, **y compris entre deux dialogues**, rétablis à la fin.
  - **S24** : monter vers les herbes, en marchant puis en courant, doigt maintenu : gel sur la dernière case avant les herbes, joystick et boutons cachés, « ??? — Hé ! Attends ! », le personnage se retourne, contrôle rendu. Remonter : plus rien.

### T3 — constructeur-monde : Chen arrive et parle
- `Npc` avec `GridMover` (§2.5) ; `GameMap.add_npc` / `remove_npc` ; `Player.script_step` ; étapes `spawn` et `move` (`path`, `to`, `run`, sans `follower`) ; clé de page `turn` dans le `DialogueRunner` ; sprite provisoire `oak` avec marche et course ; `oak_route1_warning` ; scène étendue jusqu'à `set: [oak_met]` (étapes 1 à 11 du §3.4).
- **CA** :
  - `tests/integration/test_npc.gd` (étendu) : `enter_grid` occupe la case ; `step` avance d'une case en `WALK_STEP_DURATION` (course : `RUN_STEP_DURATION`), libère l'ancienne case dès le départ, émet `step_finished` ; refusé contre un obstacle ou pendant un pas ; `walk_<dir>` joué s'il existe, sinon `idle_<dir>` ; `_process` coupé au repos. Les tests de 3A restent verts.
  - `test_game_map.gd` : `add_npc` sur une case libre, `null` et `push_error` sur une case prise ; `remove_npc` libère la case ; `rebuild_grid` garde les PNJ inscrits.
  - `test_player.gd` : `script_step` avance d'une case alors que le joueur est bloqué pour `&"cutscene"` ; refusé pendant un pas.
  - `test_dialogue_runner.gd` : `turn` tourne le PNJ, puis le joueur, au début de **cette** page seulement ; identifiant inconnu : `push_warning`, le dialogue continue.
  - `test_cutscene_director.gd` : `spawn` crée le PNJ à la case résolue ; `move` avec `to` suit `find_path` et attend l'arrivée ; `move` bloqué plus de `MOVE_BLOCK_TIMEOUT` : `push_error`, la scène continue ; acteur introuvable : `push_error`, étape sautée.
  - Capture Movie Maker (scénario `route1_oak`) : Chen qui entre dans l'écran par le bas, Chen arrêté à côté du joueur (pour chacune des deux colonnes), Chen tourné vers les herbes pendant la deuxième réplique. Lues avec Read : sprites nets, Chen à la bonne taille (≈ 1,33 case), rien de coupé.
  - **S24** : la scène complète jusqu'à « ...Viens avec moi. », puis contrôle rendu (fin provisoire). Vitesse de course de Chen, souffle et silence d'une seconde jugés par Kevin.

### T4 — constructeur-monde : le retour au labo
- Suiveur dans l'étape `move` ; étape `change_map` ; `NpcSpec` conditionnel dans `GameMap.refresh_npcs` et `Boot._on_map_changed` ; entrées du §3.2 ; `oak_lab_reunion` ; scène complète (§3.4) ; invariants du §3.6.
- **CA** :
  - `test_game_map.gd` : `_ready` crée les PNJ présents pour des drapeaux vides ; `refresh_npcs({oak_met})` ajoute ceux en `if` et retire ceux en `unless` (cases libérées) ; appelé deux fois, il ne crée pas de doublon.
  - `test_cutscene_director.gd` : avec `follower`, le suiveur est toujours à un pas derrière le meneur et finit sur l'avant-dernière case du meneur ; `change_map` (routeur de test, `map_factory`) : les étapes suivantes visent les PNJ de la nouvelle carte ; échec du routeur : `push_error`, scène arrêtée, joueur libéré.
  - `tests/integration/test_npc_placement.gd` et `test_cutscene_data.gd` : tous les invariants du §3.6.
  - `tests/integration/test_route1_event.gd` (nouveau, vrai `Boot`, départ `pallet_town` / `start`, fondus raccourcis, texte instantané) : marche jusqu'à (23, 4), `move_up` **tenu** : gel en (23, 3) ; on avance chaque dialogue ; Chen arrive en (24, 3) ; `oak_met` levé ; le joueur suit ; carte `oak_lab` ; Chen en (8, 4), rival en (9, 6), Maya non interactive ; joueur en (7, 7) ; « Enfin. » puis les trois autres répliques avec les bons noms ; `oak_lab_reunion` levé, joueur libre, contrôles visibles. Pendant toute la scène, le joueur n'a fait **que** les pas scriptés. On ressort, on remonte en (23, 3) : rien. Chez le rival : personne. Même scénario depuis (24, 3).
  - `test_opening_walk.gd` et les autres tests de 3A : inchangés et verts.
  - **Export** : `tools/build_android.sh`, puis `data/cutscenes/prologue.json` présent dans l'APK (`unzip -l`).
  - Capture Movie Maker (scénario `route1_full`) : une image par étape (gel, « ??? », Chen qui arrive, chaque réplique, le suivi, le fondu, l'arrivée au labo, le rival vers Chen puis vers le joueur, chaque réplique du labo). Lues avec Read : étiquettes correctes, 3 lignes au plus, aucun contrôle tactile visible pendant la scène.

### T5 — qa-mobile : validation sur S24
- Checklist `android-deploy` : tests, import, `tools/deploy_s24.sh`, logcat.
- **CA à vérifier et rapporter** :
  - Déclenchement : sur chacune des deux colonnes du chemin, en marchant, en courant, doigt maintenu depuis la place : gel **sur la case avant les herbes**, sans aucun pas de plus. Aucun écran noir au moment du gel.
  - Mise en scène : « ??? » avant l'apparition de Chen ; le personnage se retourne ; Chen entre par le bas de l'écran et s'arrête à côté ; Chen regarde les herbes à la deuxième réplique ; silence avant « ...Viens avec moi. » ; le joueur suit Chen sans intervention ; fondu ; au labo, le rival regarde Chen puis le joueur ; les quatre répliques avec les bons noms.
  - Pendant toute la scène : joystick, courir et bouton contextuel cachés ; toucher l'écran n'avance que la boîte de dialogue ; le joueur ne bouge jamais de lui-même.
  - Après : contrôle rendu au labo ; Chen et le rival en place ; les trois starters toujours observables ; on ressort ; remonter vers les herbes ne relance rien ; le rival n'est plus chez lui ; Maya ne donne plus sa réplique sur l'absence de Chen.
  - Parties neuves (relancer l'application) : aller au labo **avant** l'événement → Maya seule, comme en 3A ; parler au rival **avant** → sa réplique de 3A.
  - 60 fps pendant la course de Chen et le suivi (ou « non vérifié ») ; changement de carte toujours < 100 ms ; aucune erreur dans logcat, notamment aucune de `CutsceneLibrary`, `DialogueLibrary` ni `NpcRoster`.

---

## 5. Tests GUT prévus (récapitulatif)

| Fichier | Nouveau / étendu | Tâche |
|---|---|---|
| `tests/unit/test_grid_world.gd` | étendu (`find_path`) | §1 |
| `tests/unit/test_grid_mover.gd` | étendu (`start_step`) | §1 |
| `tests/unit/test_dialogue_library.gd` | étendu (`turn`) | §1 |
| `tests/unit/test_npc_roster.gd` | étendu (`if`/`unless`, `parse_entry`, `is_present`) | §1 |
| `tests/unit/test_event_trigger.gd` | nouveau (`EventTrigger`, `TriggerTable`) | §1 |
| `tests/unit/test_cutscene_library.gd` | nouveau (format, validation, erreurs avec ligne) | §1 |
| `tests/unit/test_cutscene_moves.gd` | nouveau (`resolve_cell`, `follow_path`) | §1 |
| `tests/unit/test_overworld_tileset.gd` | étendu (`TALL_GRASS`) | T1 |
| `tests/integration/test_pallet_town.gd` | étendu (herbes, déclencheur, apparition et chemins de Chen) | T1, T2, T4 |
| `tests/integration/test_game_map.gd` | étendu (déclencheurs, `add_npc`, `remove_npc`, `refresh_npcs`) | T2, T3, T4 |
| `tests/integration/test_cutscene_director.gd` | nouveau | T2, T3, T4 |
| `tests/integration/test_interaction_controller.gd` | étendu (`set_enabled`) | T2 |
| `tests/integration/test_scene_router.gd` | un test en plus (pas bloqué sur une porte) | T2 |
| `tests/integration/test_boot.gd` | étendu (contrôles pendant une scène) | T2 |
| `tests/integration/test_npc.gd` | étendu (marche) | T3 |
| `tests/integration/test_player.gd` | étendu (`script_step`) | T3 |
| `tests/integration/test_dialogue_runner.gd` | étendu (`turn`) | T3 |
| `tests/integration/test_npc_placement.gd` | étendu (deux états de drapeaux) | T4 |
| `tests/integration/test_cutscene_data.gd` | nouveau (cohérence, simulation statique) | T4 |
| `tests/integration/test_dialogue_data.gd` | étendu (drapeaux des scènes et des PNJ) | T4 |
| `tests/integration/test_route1_event.gd` | nouveau (scénario complet avec `Boot`) | T4 |

Données d'essai : `tests/fixtures/cutscenes/*.json`, compléments dans `tests/fixtures/npcs/` et `tests/fixtures/dialogues/`.

---

## 6. Validation S24 (résumé)

| Après | Ce que Kevin essaie sur le S24 |
|---|---|
| T1 | Les herbes au bout du chemin, la prairie avec un Roucool et un Rattata. |
| T2 | Le gel au bord des herbes, « Hé ! Attends ! », le personnage qui se retourne. |
| T3 | Chen qui arrive en courant et ses quatre répliques. |
| T4 | Tout le jalon, jusqu'aux quatre répliques du labo. |
| T5 | Rapport de QA complet (§4, T5). |

---

## 7. Hypothèses et questions pour Kevin

> **Décisions de Kevin (2026-09-26)** — elles **priment** sur les propositions par défaut ci-dessous et sur le reste du plan :
> 1. Herbes : les 3 dernières rangées du chemin nord (Q1 validée).
> 2. Déclencheur : la case **juste avant** les herbes ; le joueur n'entre jamais dans les herbes sans Pokémon (Q2 validée).
> 3. Gel ≈ 0,4 s → « ??? — Hé ! Attends ! » → le joueur se retourne → Chen arrive **en courant** depuis le village (Q5, Q6 validées).
> 4. Retour : le joueur **suit Chen automatiquement** quelques cases, puis fondu vers le labo (Q8 : option A).
> 5. Réplique finale définitive : « ...Viens avec moi. » (Q17).
> 6. **Étiquette : « Prof. Chen »** (et non « Chen ») partout où il parle ; les autres personnages peuvent dire « le professeur Chen » ou « Chen » dans leurs répliques (**modifie Q13 et tous les `"speaker": "Chen"` du §3.3**).
> 7. **Maya après le retour de Chen** : elle ne devient **pas** muette (modifie Q11 et le PNJ `maya_working` du §3.2, qui devient interactif). Nouvelle variante, conditionnée par `oak_met` : **Maya** — « Ah, le professeur est revenu. » / « Et à voir son air, j'imagine qu'il a encore quelque chose en tête. » (textes définitifs ; elle évoluera encore après le starter, jalon 4).
> 8. Le rival quitte sa chambre après l'événement et se trouve au labo ; sa chambre est vide (Q12 validée).
> 9. Scène du labo : Rival « Enfin. » / **Prof. Chen** « Un peu de patience. » / Rival « Ça fait une heure que tu dis ça. » / **Prof. Chen** « Et pourtant, tu es toujours là. », puis le joueur reprend la main.
> 10. **Après la scène (modifie Q10)** : tant que le joueur n'a **pas de starter** (jalon 4), les hautes herbes **restent bloquées**. Pas de nouvelle cinématique : sur la case juste avant les herbes, le joueur s'arrête et une courte **pensée du joueur** s'affiche : *« Je ne devrais pas aller là sans Pokémon. »* (narration, sans nom, en italique). Cette restriction disparaîtra quand le starter sera obtenu (drapeau du jalon 4, par ex. `has_starter`).
> 11. Roucool et Rattata de la prairie : Pokémon d'ambiance, **aucun combat** pour l'instant (Q4 validée).
> 12. Contrôle après le 3B : le joueur explore Bourg Palette, parle aux habitants, entre dans les bâtiments ; seule la sortie par les hautes herbes reste verrouillée jusqu'au starter.
> 13. Durées, positions fines, rendu des herbes, sauvegarde et autres paramètres : **valeurs proposées**, à ajuster après l'essai sur S24.


Hypothèses techniques (pas de décision de design) :
- Scènes scriptées en **données** (`data/cutscenes/*.json`), 7 types d'étapes, sans embranchement ni parallélisme.
- Un déclencheur est une donnée de carte (comme un warp) ; ses conditions sont dans la scène.
- Présence des PNJ évaluée au chargement de la carte seulement ; ce qui change sous les yeux du joueur passe par une scène.
- Un pas scripté ne prend jamais une porte et ne relance aucun déclencheur.
- Pas de sauvegarde, comme en 3A.

Questions (**proposition par défaut** entre parenthèses ; c'est ce que le plan ci-dessus applique si tu ne dis rien) :

1. **Où sont les hautes herbes ?** Le dossier dit « les véritables hautes herbes de la Route 1 », mais la Route 1 n'est pas encore une carte : aujourd'hui, le chemin de terre file au bord nord de Bourg Palette, entre deux clôtures (x 23–24). (*Les 3 dernières rangées du chemin, (23..24, 0..2), deviennent des hautes herbes, entre les clôtures. Rien d'autre sur la carte. Les vrais champs d'herbes viendront avec la carte de la Route 1.* Autre choix : une bande d'herbes plus large au bord nord, au-delà des clôtures, ce qui retouche la lisière de forêt et demande de clore la prairie.)
2. **Quand Chen intervient-il ?** Le dossier 02 dit « quand on approche », le dossier 01 « en entrant dans les hautes herbes ». (*Sur la case juste avant les herbes : le joueur n'y met jamais le pied, ce qui colle à « Tu allais vraiment entrer là-dedans ».*)
3. **Condition de l'événement** : faut-il avoir fait quelque chose avant (parler au rival, visiter le labo) ? (*Non : seulement ne pas l'avoir déjà vécu. Le joueur passe forcément par Maman.*)
4. **« Quelques Pokémon visibles » dans la prairie** (dossier 01 §6 : Roucool, Rattata, Papilusion très rare). (*Un Roucool et un Rattata, immobiles avec leur animation d'attente, non interactifs (pas de texte), comme ceux de 3A. Pas de Papilusion pour l'instant.*)
5. **Mise en scène du gel** : pas d'écran noir, pas de bandes cinéma, la caméra reste sur le joueur. Environ 0,4 s de silence, puis « ??? — Hé ! Attends ! », alors que le joueur regarde encore les herbes. La boîte se ferme au toucher, **puis** il se retourne. Joystick et boutons cachés du gel jusqu'à la dernière réplique au labo. (*Oui.*)
6. **Arrivée de Chen** : il apparaît hors de l'écran, sur la place, et **court** jusqu'à la case voisine du joueur (environ 1,2 s), puis reprend son souffle 0,6 s avant de parler. « Légèrement essoufflé » ne se voit qu'à ce temps mort : pas d'animation spéciale sur le sprite provisoire. (*Oui.* Autre choix : il arrive en marchant, environ 2,2 s.)
7. **Didascalies de Chen** : « il regarde les hautes herbes » = il se tourne vers le nord pendant cette réplique, puis revient vers le joueur à la suivante ; « il réfléchit une seconde » = silence d'1 s avant « ...Viens avec moi. ». (*Oui.*)
8. **Le retour** : le dossier propose deux façons. (*A : Chen descend le chemin et le joueur le suit tout seul sur 8 cases (environ 2 s), puis fondu jusqu'au labo.* B : le joueur reprend la main et Chen marche devant lui jusqu'au labo. B demande de décider ce qui se passe si le joueur ne le suit pas ou rebrousse chemin, et un trajet de Chen à travers la place. Avec A, la question « rebrousser chemin » ne se pose pas : tout est automatique du gel jusqu'au labo.)
9. **Arrivée au labo** : Chen est **déjà à sa place** (devant son bureau, il est entré le premier) ; le rival est sur le grand tapis, à côté des starters, tourné vers eux ; le joueur entre et fait deux pas. Le rival se tourne vers Chen, puis vers le joueur, puis « Enfin. ». Pendant l'échange, chacun se tourne vers celui à qui il répond. (*Oui.* Autre choix : Chen entre devant le joueur et marche jusqu'à son bureau, un peu plus long.)
10. **Après la dernière réplique** (état propre au 3B, le jalon 4 enchaînera directement) : le joueur reprend la main dans le labo ; Chen et le rival restent là, sans dialogue ; on peut ressortir ; les herbes ne relancent rien et sont praticables (aucune rencontre avant le jalon 5). (*Oui.* Autre choix : la sortie du labo est bloquée sans explication jusqu'au jalon 4, mais un tapis qui ne marche pas ressemble à un bug.)
11. **Maya après le retour de Chen** : sa réplique « Il est sorti tôt ce matin. Encore. » devient fausse. (*Elle reste à son écran, mais n'est plus interactive, en attendant une réplique de toi. Veux-tu lui en donner une ?*)
12. **Le rival quitte sa maison** : une fois l'événement passé, il est au labo, et sa chambre est vide. (*Oui.*)
13. **Étiquettes de nom** : « ??? » pour la voix, puis « Chen » (dossier 02), pas « Prof. Chen » (planche). « Rival » comme en 3A. (*Oui.*)
14. **Sauvegarde** : aucune, comme en 3A. Quitter pendant l'événement ou après recommence la partie dans la chambre. (*Oui.* Quand la sauvegarde viendra, on ne pourra pas sauvegarder pendant une scène.)
15. **Positions** : déclencheur en (23..24, 3), Chen apparaît en (24, 13), Roucool (18, 2), Rattata (29, 2), Chen au labo (8, 4), rival au labo (9, 6) plutôt que (11, 6), sinon Salamèche ne s'observe plus (§3.2). (*Validées telles quelles, à ajuster après l'essai sur S24.*)
16. **Rendu des herbes** : tuile provisoire plus haute et plus sombre que l'herbe rase, sans effet « jambes cachées » (il viendra avec les rencontres). (*Oui.*)
17. **« Viens avec moi »** : le dossier 01 donnait « Viens avec moi. J'ai quelque chose à te montrer. », le dossier 02 « ...Viens avec moi. ». (*Le dossier 02, puisque ses textes sont définitifs.*)
18. **Durées** : 0,4 s de gel avant la voix, 0,3 s avant l'arrivée de Chen, 0,6 s de souffle, 8 cases de suivi, deux pas dans le labo, 0,5 s entre « regarde Chen » et « regarde le joueur ». (*Valeurs de départ, réglables dans `data/cutscenes/prologue.json` après l'essai sur S24.*)

---

## 8. Écarts constatés entre le dépôt et `jalon-03.md` (2026-09-26)

Constat fait sur `main` (`a924cff`), base de ce plan :

1. **Documents** : ce plan a été établi à partir des versions de `jalon-03.md`, `dossier-02-prologue.md`, `dossier-04-systeme-pokemon.md` et `ui-ux-bible-v0.1.md` présentes sur `main`.
2. **Code de 3A absent** : le dernier commit de `main` n'ajoute que des documents. Aucun des fichiers du §1 de `jalon-03.md` n'existe (`game/systems/story/`, `game/systems/dialogue/`, `game/world/interactions/*.gd`, `game/world/npc/*.gd`), pas plus que `data/`, `tests/fixtures/` et leurs tests. `etat-projet.md` annonce pourtant ces fondations « posées » avec **356 tests verts**. Le dépôt en compte **295**, tous verts (état du jalon 2).
3. **Pas d'autoload `GameState`** dans `project.godot` (seulement `SceneRouter`).
4. **`Player.set_input_enabled(enabled: bool)`** n'a qu'un seul booléen, sans raison ; `Player.face()` et `GridMover.face()` n'existent pas (prévus en 3A T1).
5. **`Boot`** ne contient ni `DialogueBox`, ni `DialogueRunner`, ni `InteractionController` ; `game/ui/dialogue/` est vide ; `ExplorationHud` n'a ni `show_interact` ni `set_controls_visible`.
6. **Cohérent avec `jalon-03.md`** : cases réservées du labo (8, 4) et (11, 6) dans `test_interiors.gd` ; table des starters en (10..12, 4..5) dans `build_interiors.gd`, comme dans `jalon-03.md` §3.1. Le plan ASCII de `jalon-02.md` §4.7 indique encore (11..13) : écart de documentation du jalon 2, expliqué dans un commentaire de `build_interiors.gd`.
7. Le nœud `Triggers` existe bien dans les 6 cartes (vide), comme le suppose le §2.2 ci-dessus.

Conséquence : le 3B ne peut commencer qu'une fois le code de 3A poussé. Si les noms réels de 3A diffèrent de `jalon-03.md` (par exemple l'emplacement de la conversion des noms de direction), on aligne ce plan sur le code réel **avant** l'étape d'architecture du 3B.
