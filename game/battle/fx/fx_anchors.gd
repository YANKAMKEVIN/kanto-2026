class_name FxAnchors
extends RefCounted
## Points d'origine des effets de combat par espèce (chantier Combat vivant, CV-10 ;
## `docs/tech/combat-vivant.md` §2.2). Lit `data/battle/fx_anchors.json` (CV.A, validé par Kevin
## le 2026-10-26 ; convention dans `tools/art/fx_anchors.py`). Classe pure.
##
## Chaque espèce a une vue de face (`front`, artwork officiel entier, avant le recadrage de
## `PokedexArt.portrait`) et de dos (`back`, dos peint du cadrage B). Coordonnées **normalisées
## dans la boîte visible** de l'image (`box`, en px de l'image source) : (0, 0) = coin haut
## gauche de la boîte, (1, 1) = coin bas droit. Les paires (`yeux`, `joues`, `mains`, `canons`)
## ont deux points, gauche puis droite dans l'image.
## Repli (§2.2) : point demandé → `bouche` → `tete` → `centre` ; espèce ou vue inconnue : le
## milieu de la boîte.

const DEFAULT_PATH: String = "res://data/battle/fx_anchors.json"
const FRONT: StringName = &"front"
const BACK: StringName = &"back"
const FALLBACK_CHAIN: Array[StringName] = [&"bouche", &"tete", &"centre"]
const MIDDLE: Vector2 = Vector2(0.5, 0.5)

## species_id → { front | back → { size: Vector2i, box: Rect2i, points: {nom → PackedVector2Array} } }.
var _species: Dictionary[StringName, Dictionary] = {}


## Points lus dans [param path] (vide si le fichier manque ou est illisible).
static func load_file(path: String = DEFAULT_PATH) -> FxAnchors:
	var anchors := FxAnchors.new()
	if not FileAccess.file_exists(path):
		push_error("FxAnchors : fichier absent « %s »" % path)
		return anchors
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		anchors.read(data)
	else:
		push_error("FxAnchors : JSON illisible « %s »" % path)
	return anchors


## Remplit les points depuis [param data] (contenu de `fx_anchors.json` : `species`, indexé par
## numéro du Pokédex, chaque entrée portant son `id`).
func read(data: Dictionary) -> void:
	_species.clear()
	var species := JsonFields.get_dict(data, "species")
	for dex: String in species:
		var raw: Variant = species[dex]
		if not raw is Dictionary:
			continue
		var id := JsonFields.get_id(raw, "id")
		if id.is_empty():
			continue
		var views: Dictionary = {}
		for view: StringName in [FRONT, BACK]:
			var parsed := _read_view(JsonFields.get_dict(raw, String(view)))
			if not parsed.is_empty():
				views[view] = parsed
		_species[id] = views


func has_species(species_id: StringName) -> bool:
	return _species.has(species_id)


func has_point(species_id: StringName, view: StringName, point: StringName) -> bool:
	return _points_of(species_id, view).has(point)


## Nom du point réellement utilisé pour [param point] après le repli ("" : aucun, milieu).
func resolve(species_id: StringName, view: StringName, point: StringName) -> StringName:
	var points := _points_of(species_id, view)
	if points.has(point):
		return point
	for fallback: StringName in FALLBACK_CHAIN:
		if points.has(fallback):
			return fallback
	return &""


## Tous les points de [param point] (deux pour une paire), après le repli ; normalisés dans la
## boîte visible.
func points(species_id: StringName, view: StringName, point: StringName) -> PackedVector2Array:
	var name := resolve(species_id, view, point)
	if name.is_empty():
		return PackedVector2Array([MIDDLE])
	return _points_of(species_id, view)[name]


## Un seul point (le milieu d'une paire), après le repli ; normalisé dans la boîte visible.
func point(species_id: StringName, view: StringName, point_name: StringName) -> Vector2:
	var list := points(species_id, view, point_name)
	var sum := Vector2.ZERO
	for item: Vector2 in list:
		sum += item
	return sum / list.size()


## Boîte visible de l'image source, en px (vide si inconnue).
func box(species_id: StringName, view: StringName) -> Rect2i:
	return (_species.get(species_id, {}) as Dictionary).get(view, {}).get("box", Rect2i())


## Taille de l'image source, en px (zéro si inconnue).
func image_size(species_id: StringName, view: StringName) -> Vector2i:
	return (_species.get(species_id, {}) as Dictionary).get(view, {}).get("size", Vector2i.ZERO)


## Point normalisé [param normalized] en px de l'image source.
static func to_image_pixels(normalized: Vector2, visible_box: Rect2i) -> Vector2:
	return Vector2(visible_box.position) + normalized * Vector2(visible_box.size)


func _points_of(species_id: StringName, view: StringName) -> Dictionary:
	return (_species.get(species_id, {}) as Dictionary).get(view, {}).get("points", {})


## Vue lue : { size, box, points } ; vide si la boîte manque.
static func _read_view(raw: Dictionary) -> Dictionary:
	var box_raw := JsonFields.get_array(raw, "box")
	if box_raw.size() != 4:
		return {}
	var size_raw := JsonFields.get_array(raw, "size")
	var parsed := {
		"box": Rect2i(int(box_raw[0]), int(box_raw[1]), int(box_raw[2]), int(box_raw[3])),
		"size": Vector2i(int(size_raw[0]), int(size_raw[1])) if size_raw.size() == 2 \
			else Vector2i.ZERO,
		"points": {},
	}
	var points_raw := JsonFields.get_dict(raw, "points")
	for name: String in points_raw:
		var list := _read_points(points_raw[name])
		if not list.is_empty():
			parsed["points"][StringName(name)] = list
	return parsed


## [x, y] ou [[x, y], [x, y]] (paire) → liste de points ; vide si la forme ne va pas.
static func _read_points(raw: Variant) -> PackedVector2Array:
	var list := PackedVector2Array()
	if not raw is Array or (raw as Array).is_empty():
		return list
	var items: Array = raw if (raw as Array)[0] is Array else [raw]
	for item: Variant in items:
		if item is Array and (item as Array).size() == 2:
			list.append(Vector2(float(item[0]), float(item[1])))
	return list
