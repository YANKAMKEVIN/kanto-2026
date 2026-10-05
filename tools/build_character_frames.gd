extends SceneTree
## Génère les `SpriteFrames` peints (docs/tech/jalon-07.md §6.6) à partir des planches 4 × 4 de
## `assets/world/catalogue.json` (« personnages ») :
##
##   godot --headless --path . -s res://tools/build_character_frames.gd
##
## Planche : lignes bas, gauche, droite, haut ; colonnes 0 passage, 1 pas gauche, 2 passage,
## 3 pas droit (`decouper_perso.py`, `marcheur.gd` du prototype). Animations :
## - `idle_<dir>` : colonne 0 (une image) ;
## - `walk_<dir>` : colonnes 1, 2, 3, 0 ; un cycle de 4 images couvre **2 cases**, vitesse
##   calée sur `Grid.WALK_STEP_DURATION` (4 / (2 × 0,27) ≈ 7,4 images/s) ;
## - `run_<dir>` : **seulement avec une planche de course** (le héros), au rythme de
##   `Grid.RUN_STEP_DURATION` (12,5 images/s). Sans planche de course, aucune animation de
##   course : rejouer la marche à 12,5 images/s donnait des poses de marche à la vitesse de
##   course (« ils courent et marchent en même temps », Kevin au T5) ; `Npc.can_run` est faux
##   et le PNJ marche.
##
## **Correspondance des identifiants** (les planches sont nommées en français par les fiches
## d'art, les données du jeu en anglais) : [constant LOOKS]. Les personnages vont dans
## `assets/sprites/characters/painted/<id>_frames.tres` (`CharacterLook` : `"sprite": "<id>"`),
## les Pokémon du monde dans `assets/sprites/pokemon/painted/<espèce>_frames.tres`
## (`"sprite": "pokemon/<espèce>"`, choix explicite : Bourg Palette et la Route 1 gardent leurs
## Pokémon provisoires `"pidgey"` / `"rattata"` jusqu'à la phase DA, Q-2 / Q-3).

const CATALOGUE := "res://assets/world/catalogue.json"
const CHARACTERS_DIR := "res://assets/sprites/characters/painted/"
const POKEMON_DIR := "res://assets/sprites/pokemon/painted/"
## Grid.WALK_STEP_DURATION, Grid.RUN_STEP_DURATION.
const WALK_STEP := 0.27
const RUN_STEP := 0.16
const ROWS := {"down": 0, "left": 1, "right": 2, "up": 3}
## Ordre des colonnes d'un cycle (pas gauche, passage, pas droit, passage).
const CYCLE: Array[int] = [1, 2, 3, 0]
## Planche (catalogue) → [dossier, identifiant de données, planche de course ou ""].
const LOOKS: Dictionary = {
	"heros": [CHARACTERS_DIR, "player", "heros_run"],
	"rival": [CHARACTERS_DIR, "rival", ""],
	"infirmiere": [CHARACTERS_DIR, "nurse", ""],
	"marchand": [CHARACTERS_DIR, "clerk", ""],
	"livreur": [CHARACTERS_DIR, "courier", ""],
	"dresseuse": [CHARACTERS_DIR, "lass", ""],
	"enfant": [CHARACTERS_DIR, "kid", ""],
	"vieil_homme": [CHARACTERS_DIR, "old_man", ""],
	"voyageur": [CHARACTERS_DIR, "traveler", ""],
	"jeune_dresseur": [CHARACTERS_DIR, "youngster", ""],
	"roucool": [POKEMON_DIR, "pidgey", ""],
	"rattata": [POKEMON_DIR, "rattata", ""],
	"piafabec": [POKEMON_DIR, "spearow", ""],
	"ferosinge": [POKEMON_DIR, "mankey", ""],
	"nidoran_f": [POKEMON_DIR, "nidoran_f", ""],
	"nidoran_m": [POKEMON_DIR, "nidoran_m", ""],
}
## Planches lues seulement comme planche de course d'une autre.
const RUN_ONLY: Array[String] = ["heros_run"]

var _errors: int = 0


func _init() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	var sheets: Dictionary = catalogue["personnages"]
	for sheet_id: String in sheets:
		if not LOOKS.has(sheet_id) and not RUN_ONLY.has(sheet_id):
			push_error("build_character_frames : planche « %s » sans correspondance" % sheet_id)
			_errors += 1
	for sheet_id: String in LOOKS:
		if not sheets.has(sheet_id):
			push_error("build_character_frames : planche « %s » absente du catalogue" % sheet_id)
			_errors += 1
			continue
		var look: Array = LOOKS[sheet_id]
		var run_id: String = look[2]
		var run: Dictionary = sheets.get(run_id, {}) if not run_id.is_empty() else {}
		_build(sheets[sheet_id], run, String(look[0]) + String(look[1]) + "_frames.tres")
	print("build_character_frames : %d apparences, %d erreur(s)" % [LOOKS.size(), _errors])
	quit(1 if _errors > 0 else 0)


func _build(walk_sheet: Dictionary, run_sheet: Dictionary, path: String) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var walk_texture := load(walk_sheet["fichier"]) as Texture2D
	var walk_cell := Vector2(walk_sheet["cellule"][0], walk_sheet["cellule"][1])
	var run_texture: Texture2D = null
	var run_cell := walk_cell
	if not run_sheet.is_empty():
		run_texture = load(run_sheet["fichier"]) as Texture2D
		run_cell = Vector2(run_sheet["cellule"][0], run_sheet["cellule"][1])
	for dir: String in ROWS:
		var row: int = ROWS[dir]
		var idle := StringName("idle_" + dir)
		frames.add_animation(idle)
		frames.set_animation_loop(idle, true)
		frames.set_animation_speed(idle, 1.0)
		frames.add_frame(idle, _atlas(walk_texture, walk_cell, 0, row))
		_add_cycle(frames, StringName("walk_" + dir), walk_texture, walk_cell, row,
			4.0 / (2.0 * WALK_STEP))
		if run_texture != null:
			_add_cycle(frames, StringName("run_" + dir), run_texture, run_cell, row,
				4.0 / (2.0 * RUN_STEP))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if ResourceSaver.save(frames, path) != OK:
		push_error("build_character_frames : %s non écrit" % path)
		_errors += 1
	else:
		print("%s (%d × %d%s)" % [path, walk_cell.x, walk_cell.y,
			", course" if not run_sheet.is_empty() else ""])


func _add_cycle(frames: SpriteFrames, anim: StringName, texture: Texture2D, cell: Vector2,
		row: int, speed: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, true)
	frames.set_animation_speed(anim, speed)
	for column: int in CYCLE:
		frames.add_frame(anim, _atlas(texture, cell, column, row))


func _atlas(texture: Texture2D, cell: Vector2, column: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(Vector2(column, row) * cell, cell)
	return atlas
