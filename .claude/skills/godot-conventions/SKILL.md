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

## Performance mobile

- Viser 60 fps sur S24 : pas d'allocation dans `_process`, pas de `find_child` en boucle, `set_process(false)` quand inutile.
- Préférer `Tween` et `AnimationPlayer` aux animations manuelles image par image.
