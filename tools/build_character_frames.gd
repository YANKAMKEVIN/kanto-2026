extends SceneTree
## Génère les `SpriteFrames` peints (docs/tech/jalon-07.md §6.6) à partir des planches 4 × 4 de
## `assets/world/catalogue.json` (« personnages ») :
##
##   godot --headless --path . -s res://tools/build_character_frames.gd
##
## Planche : lignes bas, gauche, droite, haut ; colonnes 0 passage, 1 pas gauche, 2 passage,
## 3 pas droit (`decouper_perso.py`, `marcheur.gd` du prototype). Animations :
## - `idle_<dir>` : la **planche d'attente** `<planche>_idle` quand elle existe (pieds joints, une
##   ligne de 4 images bas, gauche, droite, haut ; décision de Kevin du 2026-10-06), sinon la
##   colonne de la marche choisie dans [constant IDLE_FROM_WALK] (Salamèche, DA.3), sinon la
##   colonne 0 de la marche (une image ; « passage », jambes déjà écartées de profil) ;
## - `walk_<dir>` : colonnes 1, 2, 3, 0 ; un cycle de 4 images couvre **2 cases**, vitesse
##   calée sur `Grid.WALK_STEP_DURATION` (4 / (2 × 0,27) ≈ 7,4 images/s) ;
## - `run_<dir>` : **seulement avec une planche de course** (le héros ; l'enfant et le Rattata de
##   Jadielle, qui courent dans la micro-scène d'arrivée ; Chen, qui accourt dans le prologue), au rythme de
##   `Grid.RUN_STEP_DURATION` (12,5 images/s). Sans planche de course, aucune animation de
##   course : rejouer la marche à 12,5 images/s donnait des poses de marche à la vitesse de
##   course (« ils courent et marchent en même temps », Kevin au T5) ; `Npc.can_run` est faux
##   et le PNJ marche.
##
## **Correspondance des identifiants** (les planches sont nommées en français par les fiches
## d'art, les données du jeu en anglais) : [constant LOOKS]. Les personnages vont dans
## `assets/sprites/characters/painted/<id>_frames.tres` (`CharacterLook` : `"sprite": "<id>"`),
## les Pokémon du monde dans `assets/sprites/pokemon/painted/<espèce>_frames.tres`
## (`"sprite": "pokemon/<espèce>"`, choix explicite ; depuis DA.1 / DA.2, la Route 1 et Bourg
## Palette l'utilisent ; un simple `"pidgey"` reste provisoire).
##
## **Objets fixes** (jalon 8 §2.3, genre « objet fixe ») : une seule image du catalogue
## (section « images », remplie par `images_objets` du manifeste) → `idle_down/left/right/up`,
## une image chacune, sans marche ni course, dans `assets/sprites/objects/painted/<id>_frames.tres`
## (`"sprite": "object/<id>"`) : la Poké Ball posée au sol (O1, O2 de la Route 2). Une image pas
## encore préparée (absente du catalogue) est signalée et sautée, sans erreur.

const CATALOGUE := "res://assets/world/catalogue.json"
const CHARACTERS_DIR := "res://assets/sprites/characters/painted/"
const POKEMON_DIR := "res://assets/sprites/pokemon/painted/"
const OBJECTS_DIR := "res://assets/sprites/objects/painted/"
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
	"enfant": [CHARACTERS_DIR, "kid", "enfant_run"],
	"vieil_homme": [CHARACTERS_DIR, "old_man", ""],
	"voyageur": [CHARACTERS_DIR, "traveler", ""],
	"jeune_dresseur": [CHARACTERS_DIR, "youngster", ""],
	# DA.2 (Bourg Palette) : série 09 et habitants du prototype (série 06B), avec leur
	# planche d'attente (`<planche>_idle`), sans planche de course (ils marchent toujours).
	"maman": [CHARACTERS_DIR, "mom", ""],
	# DA.3 : Chen accourt dans le prologue (décision de Kevin du 2026-10-07).
	"chen": [CHARACTERS_DIR, "oak", "chen_run"],
	"leo": [CHARACTERS_DIR, "leo", ""],
	"vieille_dame": [CHARACTERS_DIR, "aoki", ""],
	"pecheur": [CHARACTERS_DIR, "haru", ""],
	"chercheuse": [CHARACTERS_DIR, "maya", ""],
	"chercheur": [CHARACTERS_DIR, "researcher", ""],
	# J8 (série 10, Route 2) : P1, avec sa planche d'attente.
	"randonneuse": [CHARACTERS_DIR, "hiker", ""],
	"roucool": [POKEMON_DIR, "pidgey", ""],
	"rattata": [POKEMON_DIR, "rattata", "rattata_run"],
	"piafabec": [POKEMON_DIR, "spearow", ""],
	"ferosinge": [POKEMON_DIR, "mankey", ""],
	"nidoran_f": [POKEMON_DIR, "nidoran_f", ""],
	"nidoran_m": [POKEMON_DIR, "nidoran_m", ""],
	# DA.3 : les trois starters (labo, rival de la Route 22). Salamèche : planche obtenue à la
	# main par Kevin (ChatGPT), sans planche d'attente → [constant IDLE_FROM_WALK].
	"bulbizarre": [POKEMON_DIR, "bulbasaur", ""],
	"salameche": [POKEMON_DIR, "charmander", ""],
	"carapuce": [POKEMON_DIR, "squirtle", ""],
}
## Objets fixes : image (catalogue, « images ») → identifiant de données (`object/<id>`).
const FIXED_OBJECTS: Dictionary = {
	"poke_ball_ground": "poke_ball_ground",
}
## Planches lues seulement comme planche de course d'une autre.
const RUN_ONLY: Array[String] = ["heros_run", "enfant_run", "rattata_run", "chen_run"]
## Suffixe des planches d'attente (`heros_idle` pour `heros`) ; colonne de chaque direction.
const IDLE_SUFFIX := "_idle"
const IDLE_COLUMNS := {"down": 0, "left": 1, "right": 2, "up": 3}
## Planches sans planche d'attente (refusée par les générateurs) : pour chaque direction, la
## colonne de la marche la plus posée (pieds rapprochés, les deux au sol), choisie à l'œil sur
## la planche de jeu (DA.3, repli du J7 « colonne 0 » adapté). Salamèche : de face, la pose
## neutre (colonne 0) ; de profil gauche, le passage (colonne 3) ; de profil droit, le passage
## (colonne 1) ; de dos, colonne 0 (les deux pieds posés).
const IDLE_FROM_WALK := {
	"salameche": {"down": 0, "left": 3, "right": 1, "up": 0},
}

var _errors: int = 0


func _init() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	var sheets: Dictionary = catalogue["personnages"]
	for sheet_id: String in sheets:
		var idle_of := sheet_id.trim_suffix(IDLE_SUFFIX)
		if idle_of != sheet_id and LOOKS.has(idle_of):
			continue
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
		var idle: Dictionary = sheets.get(sheet_id + IDLE_SUFFIX, {})
		_build(sheets[sheet_id], run, idle, String(look[0]) + String(look[1]) + "_frames.tres",
			IDLE_FROM_WALK.get(sheet_id, {}))
	var images: Dictionary = catalogue.get("images", {})
	var objects := 0
	for image_id: String in FIXED_OBJECTS:
		if not images.has(image_id):
			print("build_character_frames : objet « %s » pas encore préparé (sauté)" % image_id)
			continue
		_build_fixed_object(images[image_id], OBJECTS_DIR + String(FIXED_OBJECTS[image_id])
			+ "_frames.tres")
		objects += 1
	print("build_character_frames : %d apparences, %d objet(s) fixe(s), %d erreur(s)"
		% [LOOKS.size(), objects, _errors])
	quit(1 if _errors > 0 else 0)


func _build(walk_sheet: Dictionary, run_sheet: Dictionary, idle_sheet: Dictionary,
		path: String, idle_from_walk: Dictionary = {}) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var walk_texture := load(walk_sheet["fichier"]) as Texture2D
	var walk_cell := Vector2(walk_sheet["cellule"][0], walk_sheet["cellule"][1])
	var run_texture: Texture2D = null
	var run_cell := walk_cell
	if not run_sheet.is_empty():
		run_texture = load(run_sheet["fichier"]) as Texture2D
		run_cell = Vector2(run_sheet["cellule"][0], run_sheet["cellule"][1])
	var idle_texture: Texture2D = null
	var idle_cell := walk_cell
	if not idle_sheet.is_empty():
		idle_texture = load(idle_sheet["fichier"]) as Texture2D
		idle_cell = Vector2(idle_sheet["cellule"][0], idle_sheet["cellule"][1])
		if idle_cell.y != walk_cell.y:
			push_error("build_character_frames : %s : hauteur d'attente ≠ marche (ancrage)"
				% path)
			_errors += 1
	for dir: String in ROWS:
		var row: int = ROWS[dir]
		var idle := StringName("idle_" + dir)
		frames.add_animation(idle)
		frames.set_animation_loop(idle, true)
		frames.set_animation_speed(idle, 1.0)
		if idle_texture != null:
			frames.add_frame(idle, _atlas(idle_texture, idle_cell, IDLE_COLUMNS[dir], 0))
		else:
			frames.add_frame(idle, _atlas(walk_texture, walk_cell, idle_from_walk.get(dir, 0),
				row))
		_add_cycle(frames, StringName("walk_" + dir), walk_texture, walk_cell, row,
			4.0 / (2.0 * WALK_STEP))
		if run_texture != null:
			_add_cycle(frames, StringName("run_" + dir), run_texture, run_cell, row,
				4.0 / (2.0 * RUN_STEP))
	_save(frames, path, "%s (%d × %d%s%s)" % [path, walk_cell.x, walk_cell.y,
		", course" if not run_sheet.is_empty() else "",
		", attente" if not idle_sheet.is_empty() else ""])


## Objet fixe : la même image entière pour les quatre orientations d'attente.
func _build_fixed_object(image: Dictionary, path: String) -> void:
	var texture := load(image["fichier"]) as Texture2D
	if texture == null:
		push_error("build_character_frames : image « %s » introuvable" % image["fichier"])
		_errors += 1
		return
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for dir: String in ROWS:
		var idle := StringName("idle_" + dir)
		frames.add_animation(idle)
		frames.set_animation_loop(idle, true)
		frames.set_animation_speed(idle, 1.0)
		frames.add_frame(idle, texture)
	_save(frames, path, "%s (objet fixe, %d × %d)" % [path, texture.get_width(),
		texture.get_height()])


func _save(frames: SpriteFrames, path: String, report: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if ResourceSaver.save(frames, path) != OK:
		push_error("build_character_frames : %s non écrit" % path)
		_errors += 1
	else:
		print(report)


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
