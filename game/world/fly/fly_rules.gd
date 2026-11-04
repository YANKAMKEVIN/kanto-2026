class_name FlyRules
extends RefCounted
## Vol hors combat (passe systèmes 2, `docs/tech/systemes-2.md` §2.8) : pur, sans nœud.
## Conditions (CS02, Badge Foudre, Pokémon compatible : `FieldMoves.status(&"fly")`, déjà évalué)
## et lieu ; destinations ouvertes, lues dans `data/world/fly_points.json`.
##
## Une destination est **ouverte** quand sa carte est dans les cartes découvertes
## (`GameState.discovered_maps`) [D, RB : villes visitées] ; aucun champ de sauvegarde nouveau.

## Réponse de [method can_fly].
enum Check {
	OK,
	BUSY, ## Le joueur n'est pas libre (dialogue, scène, glissade…).
	NO_HM, ## Pas de CS02.
	NO_BADGE, ## CS02 sans Badge Foudre.
	NO_POKEMON, ## Aucun Pokémon de l'équipe ne peut voler.
	INDOORS, ## Intérieur.
	NO_FLY, ## Carte où le Vol est interdit (Parc Safari, Ligue, grottes [D, RB]).
	CLOSED, ## Destination inconnue ou pas encore découverte (T24).
	OTHER_REGION, ## JOH0 (JH-18) : destination dans l'autre région pendant l'acte 1.
}

const DATA_PATH: String = "res://data/world/fly_points.json"

const _KEYS: Array[String] = ["zone", "map", "spawn"]


## Une destination : zone de `zones.json`, carte et point d'arrivée.
class Point:
	extends RefCounted
	var zone: StringName = &""
	var map: StringName = &""
	var spawn: StringName = &""
	## Région de la zone (JOH0, [method FlyRules.stamp_regions]) ; Kanto par défaut.
	var region: StringName = ZoneData.REGION_KANTO

	func _init(p_zone: StringName = &"", p_map: StringName = &"", p_spawn: StringName = &"") -> void:
		zone = p_zone
		map = p_map
		spawn = p_spawn


var _points: Array[Point] = []
var _errors: PackedStringArray = PackedStringArray()


## Peut-on s'envoler d'ici ? Ordre : occupé, conditions de la capacité, intérieur, carte interdite.
static func can_fly(field_state: FieldMoves.State, map: MapTraits, busy: bool = false) -> Check:
	if busy:
		return Check.BUSY
	match field_state:
		FieldMoves.State.NO_HM:
			return Check.NO_HM
		FieldMoves.State.NO_BADGE:
			return Check.NO_BADGE
		FieldMoves.State.NO_POKEMON:
			return Check.NO_POKEMON
	if map.interior:
		return Check.INDOORS
	if map.no_fly:
		return Check.NO_FLY
	return Check.OK


## Peut-on s'envoler d'ici vers la zone [param zone] ? [method can_fly], puis destination ouverte
## ([param discovered] : `GameState.discovered_maps`) (T24 : bouton « S'ENVOLER » de la Carte).
## JOH0 : [param from_region] (région de la carte courante, &"" = sans contrôle) et
## [param cross_allowed] (faux pendant l'acte 1, JH-18) : une destination de l'autre région est
## OTHER_REGION.
func can_fly_to(zone: StringName, field_state: FieldMoves.State, map: MapTraits,
		discovered: Dictionary, busy: bool = false, from_region: StringName = &"",
		cross_allowed: bool = true) -> Check:
	var check := can_fly(field_state, map, busy)
	if check != Check.OK:
		return check
	var point := get_point(zone)
	if point == null or not discovered.has(point.map):
		return Check.CLOSED
	if not cross_allowed and not from_region.is_empty() and point.region != from_region:
		return Check.OTHER_REGION
	return Check.OK


## JOH0 : pose la région de chaque destination d'après sa zone ([method ZoneLibrary.get_zone]) ;
## une zone inconnue reste à Kanto.
func stamp_regions(zones: ZoneLibrary) -> void:
	if zones == null:
		return
	for point: Point in _points:
		var zone := zones.get_zone(point.zone)
		if zone != null:
			point.region = zone.region


## Traits de Vol d'une carte (T24) : intérieur, et Vol interdit dans une grotte [D, RB]
## (`caves.json`). Le Parc Safari (J23) et la Ligue (J30) poseront leur propre interdiction.
static func traits_of(interior: bool, cave: bool) -> MapTraits:
	var traits := MapTraits.new(interior)
	traits.no_fly = cave
	return traits


## Charge [param path]. Faux s'il est illisible ou contient une erreur.
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not (parsed as Dictionary).get("points") is Array:
		return _fail("%s : un objet { \"points\": […] } est attendu" % path)
	return add_points(parsed["points"], path)


## Ajoute des destinations (liste d'objets { zone, map, spawn }), dans l'ordre.
func add_points(entries: Array, source: String = "") -> bool:
	var ok := true
	for i: int in entries.size():
		var where := "%s point %d" % [source, i]
		var entry: Variant = entries[i]
		if not entry is Dictionary or (entry as Dictionary).size() != _KEYS.size() \
				or _KEYS.any(func(k: String) -> bool:
					return not (entry as Dictionary).get(k) is String \
						or String((entry as Dictionary)[k]).is_empty()):
			ok = _fail("%s : { \"zone\", \"map\", \"spawn\" } (textes non vides) attendu" % where)
			continue
		var point := Point.new(StringName(entry["zone"]), StringName(entry["map"]),
			StringName(entry["spawn"]))
		if get_point(point.zone) != null:
			ok = _fail("%s : zone « %s » en double" % [where, point.zone])
			continue
		_points.append(point)
	return ok


## Toutes les destinations, dans l'ordre des données.
func get_points() -> Array[Point]:
	return _points.duplicate()


## Destination de la zone [param zone], ou null.
func get_point(zone: StringName) -> Point:
	for point: Point in _points:
		if point.zone == zone:
			return point
	return null


## Destinations ouvertes (carte découverte), dans l'ordre des données ; JOH0 : celles de
## [param region] d'abord (si donnée), puis les autres si [param cross_allowed].
func destinations(discovered: Dictionary, region: StringName = &"",
		cross_allowed: bool = true) -> Array[Point]:
	var open: Array[Point] = []
	var others: Array[Point] = []
	for point: Point in _points:
		if not discovered.has(point.map):
			continue
		if region.is_empty() or point.region == region:
			open.append(point)
		elif cross_allowed:
			others.append(point)
	open.append_array(others)
	return open


func get_errors() -> PackedStringArray:
	return _errors


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("FlyRules : " + message)
	return false
