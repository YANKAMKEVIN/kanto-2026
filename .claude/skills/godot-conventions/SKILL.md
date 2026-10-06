---
name: godot-conventions
description: Conventions de code et d'architecture Godot 4.7 / GDScript du projet Kanto 2026 — typage, nommage, structure des scènes, signaux, autoloads, édition des fichiers .tscn/.tres à la main. À charger avant d'écrire ou de relire du GDScript ou des scènes dans ce projet.
---

# Conventions Godot — Kanto 2026

Godot **4.7** uniquement. Pas d'API Godot 3 (`KinematicBody2D`, `yield`, `export var`, `onready var`, `TileMap` monolithique…).

## GDScript

- **Typage statique partout** : variables, paramètres, retours (`func move(dir: Vector2i) -> bool:`). `:=` accepté quand le type est évident.
- Indentation : **tabulations**. Lignes ≤ 100 caractères.
- Ordre dans un script : `class_name` → `extends` → doc `##` → signaux → enums → constantes → `@export` → variables publiques → variables `_privées` → `@onready` → méthodes virtuelles (`_ready`, `_process`…) → méthodes publiques → méthodes `_privées`.
- Nommage : fichiers et dossiers `snake_case` (`player_controller.gd`) ; `class_name` en `PascalCase` ; méthodes/variables `snake_case` ; constantes `SCREAMING_SNAKE` ; privé préfixé `_`.
- **Signaux au passé** : `moved`, `dialogue_finished`, `encounter_triggered(species_id: StringName)`.
- Références de nœuds : `@onready var _sprite: AnimatedSprite2D = %Sprite` (noms uniques `%`) plutôt que des chemins longs.
- Pas de `get_node("../../..")` : on remonte par signaux, on descend par références.
- Identifiants de contenu : `StringName` (`&"pallet_town"`, `&"pikachu"`).
- Commentaires et textes de jeu en français ; identifiants de code en anglais.
- Warnings GDScript = à corriger, pas à ignorer.

## Architecture

- **Composition** : petites scènes réutilisables (`player.tscn`, `npc.tscn`, `warp.tscn`) instanciées dans les cartes.
- **Logique ≠ présentation** : les règles (grille, combat, capture, horloge) vivent dans des classes `RefCounted`/`Resource` sans dépendance à l'arbre de scènes → testables avec GUT. Les nœuds ne font qu'afficher et relayer les entrées.
- **Données** : contenu (espèces, attaques, objets, dialogues, rencontres) dans des fichiers de données sous `data/`. Jamais de `if species == "pikachu"` dans la logique.
- **Autoloads** (`game/autoload/`), à créer uniquement quand un besoin réel apparaît, un rôle chacun :
  - `SceneRouter` — changement de carte + transition + point d'apparition
  - `GameState` — état persistant de la partie (drapeaux d'histoire, équipe, sac, position)
  - `GameClock` — heure du jeu (jour/nuit, routines PNJ)
  - `SaveSystem` — sérialisation de `GameState`
  Les autoloads ne se référencent pas en cercle ; ils communiquent par signaux.
- Un dossier par fonctionnalité : `game/player/player.tscn` + `player.gd` + ses sous-scènes.

## Fichiers .tscn / .tres édités à la main

- En-tête `[gd_scene format=3]` ; ressources externes `[ext_resource type="Script" path="res://…" id="1_abc"]`, référencées par `ExtResource("1_abc")`.
- Les `uid=` sont optionnels à l'écriture : Godot les ajoute au réimport. **Commiter les fichiers `.uid`** générés à côté des scripts.
- Après toute modification de scène/script : `godot --headless --path . --import` et vérifier qu'aucune ligne `ERROR`/`SCRIPT ERROR` n'apparaît (voir skill `godot-cli`).
- Pour une scène complexe ou générée (carte remplie de tuiles), préférer un **script d'outil** (`tools/*.gd`, `extends SceneTree`) qui construit la scène et la sauve avec `ResourceSaver`, plutôt qu'écrire des milliers de lignes à la main.

## Tests (GUT 9.7)

- Fichiers `tests/unit/test_<sujet>.gd`, `extends GutTest`, méthodes `test_…`.
- Toute logique de règle a ses tests unitaires. Les scènes peuvent avoir des tests d'intégration (`tests/integration/`) avec `add_child_autofree()`.
- Lancer : `tools/test.sh` (ou `tools/test.sh res://tests/unit`).

### Tests et temps (déterministes sous charge)

Plusieurs processus Godot tournent en même temps sur le Mac : une image peut durer 0,1 s ou plus. Un test ne doit jamais dépendre de la vitesse de la machine.

- **Une durée se vérifie en temps simulé, jamais en temps réel** (une image = 1/60 s, comptée par le test) :
  - tweens : `tests/helpers/tween_clock.gd` (`TweenClock.new(get_tree())` **avant** l'appel, puis `step()` / `run_until()`, `release()` à la fin) ;
  - directeur de scènes, joueur, PNJ : `tests/helpers/frame_sim.gd` (`FrameSim`, `await sim.frame()`, `finish()`) ;
  - `AnimationPlayer` : `callback_mode_process = ANIMATION_CALLBACK_MODE_PROCESS_MANUAL` puis `advance(1.0 / 60.0)`.
  - Tolérance : « pas fini avant la durée, au plus un pas de plus » (une image par enchaînement), jamais une marge en secondes.
- **Un état intermédiaire** (« en mouvement », « il pulse », « pas encore ouvert ») se relève **au pas près** avec ces outils, pas après un `wait_seconds` partiel.
- **Un état au moment d'un événement** (« rideau opaque quand l'écran s'affiche ») se relève **dans le signal ou le rappel**, pas après `wait_for_signal` (sa reprise arrive plus tard sous charge).
- `Time.get_ticks_msec()` ne sert que de **délai de garde** (variable `deadline`), jamais de mesure ; `get_process_delta_time()` n'a pas sa place dans un test. `tools/check_test_timing.sh` (lancé par `tools/test.sh`) le refuse. Exception assumée : finir la ligne par `# temps réel : <raison>`.
- **`wait_seconds(durée + marge)` puis l'état final** reste correct (sous charge, on attend seulement plus longtemps).
- **Côté jeu, pour qu'un test puisse simuler le temps** : attendre avec un tween (`create_tween().tween_interval(t)`) plutôt que `create_timer`.
- En cas de doute, lancer la suite **sous charge** (deux `tools/test.sh` en parallèle sur deux copies, et quelques `yes > /dev/null`, arrêtés par PID).

## Performance mobile

- Viser 60 fps sur S24 : pas d'allocation dans `_process`, pas de `find_child` en boucle, `set_process(false)` quand inutile.
- Préférer `Tween` et `AnimationPlayer` aux animations manuelles image par image.
