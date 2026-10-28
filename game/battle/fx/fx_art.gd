class_name FxArt
extends RefCounted
## Art peint des effets de combat (chantier Combat vivant, CV.1 vagues 1 et 2,
## `docs/tech/combat-vivant.md` §2.9, §3.4) : lit les manifestes de `assets/sprites/battle_fx/` une
## fois et rend les textures par identifiant (un identifiant dans deux manifestes est une erreur de
## test). Flipbooks : atlas de `colonnes` × `colonnes` images de `taille` px, en boucle ; particules :
## une image. `melange` : `add` (lumière, mélange additif), `norm` ou `vert` (matière, mélange
## normal ; `vert` dit seulement le fond de détourage).
## Orientation des flipbooks : l'effet part du bord gauche vers la droite (le code tourne).

const MANIFESTS: Array[String] = [
	"res://assets/sprites/battle_fx/manifeste_vague1.json",
	"res://assets/sprites/battle_fx/manifeste_vague2.json",
]
const DIR: String = "res://assets/sprites/battle_fx/"

static var _flipbooks: Dictionary = {}
static var _particles: Dictionary = {}
static var _loaded: bool = false


## Flipbook [param id] : { texture, frames, columns, size, additive } ; vide s'il est inconnu.
static func flipbook(id: StringName) -> Dictionary:
	_load()
	return _flipbooks.get(id, {})


## Particule [param id] : { texture, additive } ; vide si elle est inconnue.
static func particle(id: StringName) -> Dictionary:
	_load()
	return _particles.get(id, {})


## Charge tout l'art d'avance (à la construction de la scène de combat) : aucun chargement au
## premier coup, qui ferait un à-coup (vu dans la galerie : une image de 150 ms). Coût : ≈ 6,5 Mo
## de mémoire graphique par flipbook (atlas 1 280 px sans compression) [D], mesuré en T8.
static func preload_all() -> void:
	_load()


## Un identifiant connu du manifeste (flipbook ou particule).
static func has(id: StringName) -> bool:
	_load()
	return _flipbooks.has(id) or _particles.has(id)


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	for manifest: String in MANIFESTS:
		_read(manifest)


## Identifiants de [param manifest] (flipbooks puis particules ; tests).
static func ids_of(manifest: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest)) \
		if FileAccess.file_exists(manifest) else null
	if data is Dictionary:
		for table: String in ["flipbooks", "particules"]:
			for key: String in JsonFields.get_dict(data, table):
				ids.append(StringName(key))
	return ids


static func _read(manifest: String) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest)) \
		if FileAccess.file_exists(manifest) else null
	if not data is Dictionary:
		push_error("FxArt : manifeste illisible « %s »" % manifest)
		return
	var books := JsonFields.get_dict(data, "flipbooks")
	for key: String in books:
		var raw: Dictionary = books[key]
		var texture := load(DIR + JsonFields.get_string(raw, "fichier")) as Texture2D
		if texture == null:
			continue
		_flipbooks[StringName(key)] = {
			"texture": texture,
			"frames": JsonFields.get_int(raw, "images", 1),
			"columns": JsonFields.get_int(raw, "colonnes", 1),
			"size": JsonFields.get_int(raw, "taille", texture.get_width()),
			"additive": JsonFields.get_string(raw, "melange") == "add",
		}
	var parts := JsonFields.get_dict(data, "particules")
	for key: String in parts:
		var raw: Dictionary = parts[key]
		var texture := load(DIR + JsonFields.get_string(raw, "fichier")) as Texture2D
		if texture == null:
			continue
		_particles[StringName(key)] = {
			"texture": texture,
			"additive": JsonFields.get_string(raw, "melange") == "add",
		}
