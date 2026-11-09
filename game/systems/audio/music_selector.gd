class_name MusicSelector
extends RefCounted
## Quel morceau pour une carte, un état, un combat (docs/tech/jalon-son.md §1.4, §2). Pur.
##
## Ordre pour une carte : surcharge de la carte (`GameMap.music`, [constant STATE_OVERRIDE]) →
## mode de déplacement (Surf, Vélo : `music_zones.json` « movement », puis « movement_regions »
## pour la région de la carte) → règle de drapeau
## (Tour délivrée, SON-10) → exception de carte → morceau de la zone → silence.
##
## [param state] (dictionnaire, toutes les clés facultatives) :
## - [constant STATE_OVERRIDE] : `StringName`, morceau imposé par la carte ;
## - [constant STATE_MOVEMENT] : `&"walk"`, [constant AudioLibrary.MOVEMENT_BIKE] ou
##   [constant AudioLibrary.MOVEMENT_SURF] ;
## - [constant STATE_HAS_FLAG] : `Callable(flag: StringName) -> bool` (drapeaux d'histoire) ;
## - [constant STATE_AREA] : `StringName`, partie de carte (« purified » : zone purifiée).

## Catégories où le morceau du costume porté remplace la musique (CO-18).
const ORDINARY_BATTLES: Array[StringName] = [&"wild", &"trainer", &"johto_wild", &"johto_trainer"]

const STATE_OVERRIDE: StringName = &"override"
const STATE_MOVEMENT: StringName = &"movement"
const STATE_HAS_FLAG: StringName = &"has_flag"
const STATE_AREA: StringName = &"area"

var _library: AudioLibrary
var _zones: ZoneLibrary


func _init(library: AudioLibrary, zones: ZoneLibrary) -> void:
	_library = library
	_zones = zones


## Morceau de [param map_id] ; [constant AudioLibrary.SILENCE] si rien ne s'applique.
func track_for(map_id: StringName, state: Dictionary = {}) -> StringName:
	var override: StringName = StringName(str(state.get(STATE_OVERRIDE, "")))
	if _library.has_track(override):
		return override
	var movement: StringName = _library.movement_track(StringName(str(state.get(STATE_MOVEMENT,
		""))), _zones.region_of(map_id))
	if not movement.is_empty():
		return movement
	var has_flag: Variant = state.get(STATE_HAS_FLAG)
	if has_flag is Callable and (has_flag as Callable).is_valid():
		for rule: Dictionary in _library.flag_rules():
			if (rule["maps"] as Array).has(map_id) and (has_flag as Callable).call(rule["flag"]):
				return rule["track"]
	var by_map := _library.map_track(map_id)
	if not by_map.is_empty():
		return by_map
	var by_zone := _library.zone_track(_zones.zone_of(map_id))
	return by_zone if not by_zone.is_empty() else AudioLibrary.SILENCE


## Réglage de volume (dB) de la partie de carte de [param state] (0 hors d'une partie connue).
func volume_db_for(state: Dictionary = {}) -> float:
	return _library.area_volume_db(StringName(str(state.get(STATE_AREA, ""))))


## Catégorie de combat : Dresseur (par sa fiche) ; sinon espèce à thème propre, légendaire ou
## sauvage. [param region] (celle de la carte) remplace ensuite la catégorie par la sienne
## (`region_categories`).
func battle_category(trainer_id: StringName, species_id: StringName = &"",
		region: StringName = &"") -> StringName:
	if not trainer_id.is_empty():
		return _library.regional_category(_library.trainer_category(trainer_id), region)
	var by_species := _library.species_category(species_id)
	if not by_species.is_empty():
		return by_species
	if _library.is_legendary(species_id) \
			and _library.has_battle_category(AudioLibrary.BATTLE_LEGENDARY):
		return _library.regional_category(AudioLibrary.BATTLE_LEGENDARY, region)
	return _library.regional_category(AudioLibrary.BATTLE_WILD, region)


## Vrai pour un combat ordinaire (CO-18) : sauvage ou Dresseur sans thème propre, ni légendaire
## (Johto les range avec les sauvages), ni rival, ni Rocket ni Ysolde
## (`costume_music_excluded`, décision de Kevin du 2026-11-09).
func is_ordinary_battle(trainer_id: StringName, species_id: StringName = &"",
		region: StringName = &"") -> bool:
	if _library.is_legendary(species_id) or String(trainer_id).contains("rival") \
			or _library.is_costume_music_excluded(trainer_id):
		return false
	return ORDINARY_BATTLES.has(battle_category(trainer_id, species_id, region))


## Musique du combat ([param trainer_id] vide = sauvage).
func battle_track(trainer_id: StringName, species_id: StringName = &"",
		region: StringName = &"") -> StringName:
	return _library.battle_category(battle_category(trainer_id, species_id, region)).get("battle",
		AudioLibrary.SILENCE)


## Musique de victoire (SON-14 : la victoire contre un sauvage est raccourcie par les données).
func victory_track(trainer_id: StringName, species_id: StringName = &"",
		region: StringName = &"") -> StringName:
	return _library.battle_category(battle_category(trainer_id, species_id, region)).get(
		"victory", AudioLibrary.SILENCE)


## Thème du « ! » d'un Dresseur qui repère le joueur.
func encounter_track(trainer_id: StringName, trainer_name: String = "") -> StringName:
	return _library.encounter_track(trainer_id, trainer_name)


## Morceau d'un moment du jeu (« title », « heal », « badge »…) ; silence si aucun.
func event_track(event: StringName) -> StringName:
	var track := _library.event_track(event)
	return track if not track.is_empty() else AudioLibrary.SILENCE
