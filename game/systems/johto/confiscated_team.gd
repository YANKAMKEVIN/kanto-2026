class_name ConfiscatedTeam
extends RefCounted
## L'équipe et le Sac confisqués au joueur pendant l'acte 1 du Chapitre Johto (JH-1 à JH-3 ;
## `jalon-joh0.md` §2.1, §2.2 ; dossier JOH-01 §6.1). Section « confiscated » de la sauvegarde
## (v10), **vide** hors de l'acte 1 : elle n'est écrite que si elle contient quelque chose.
##
## Donnée pure : les Pokémon (format habituel, identifiants gardés), les objets non clés du Sac
## (identifiant → quantité) et l'identifiant du compagnon d'alors. Rien ici ne décide du vol ni
## du retour ([TeamConfiscation]) : cette classe ne fait que porter et sérialiser.

## Pokémon de l'équipe au moment du vol, dans leur ordre.
var party: Array[Pokemon] = []
## Objets non clés du Sac au moment du vol : identifiant → quantité (> 0).
var items: Dictionary[StringName, int] = {}
## Compagnon au moment du vol (vide = aucun).
var companion_uid: String = ""


## Vrai si rien n'est confisqué (état normal, hors acte 1).
func is_empty() -> bool:
	return party.is_empty() and items.is_empty() and companion_uid.is_empty()


## Vide la section (retour de l'équipe, nouvelle partie).
func clear() -> void:
	party.clear()
	items.clear()
	companion_uid = ""


## Pokémon confisqué d'identifiant [param uid], ou null.
func find_by_uid(uid: String) -> Pokemon:
	if uid.is_empty():
		return null
	for pokemon: Pokemon in party:
		if pokemon.uid == uid:
			return pokemon
	return null


## Section prête pour le JSON ({} si vide), clés des objets triées.
func to_dict() -> Dictionary:
	if is_empty():
		return {}
	var members: Array[Dictionary] = []
	for pokemon: Pokemon in party:
		members.append(pokemon.to_dict())
	var ids: Array[StringName] = []
	ids.assign(items.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	var bag: Dictionary = {}
	for id: StringName in ids:
		bag[String(id)] = items[id]
	return {"party": members, "items": bag, "companion": companion_uid}


## Section écrite par [method to_dict]. {} ou champs absents → section vide ; **null**
## (push_error) si un Pokémon est invalide ou si « party » / « items » n'ont pas la forme
## attendue : rien n'est perdu en silence (GameState vide alors la section et signale le refus ;
## Boot garde l'original en `save.json.rejected`, comme pour la Pension). Une quantité
## d'objet invalide est une erreur aussi ; un identifiant d'objet n'est pas vérifié ici.
static func from_dict(dict: Dictionary, data: PokemonData) -> ConfiscatedTeam:
	var result := ConfiscatedTeam.new()
	var raw_party: Variant = dict.get("party", [])
	if not raw_party is Array:
		push_error("ConfiscatedTeam.from_dict : « party » doit être une liste")
		return null
	for entry: Variant in raw_party:
		var pokemon: Pokemon = Pokemon.from_dict(entry, data) if entry is Dictionary else null
		if pokemon == null:
			push_error("ConfiscatedTeam.from_dict : Pokémon confisqué invalide")
			return null
		result.party.append(pokemon)
	var raw_items: Variant = dict.get("items", {})
	if not raw_items is Dictionary:
		push_error("ConfiscatedTeam.from_dict : « items » doit être un objet « objet → quantité »")
		return null
	for key: Variant in raw_items:
		var count: Variant = raw_items[key]
		if not key is String or (key as String).is_empty() or not JsonFields.is_int(count) \
				or int(count) < 1:
			push_error("ConfiscatedTeam.from_dict : objet confisqué invalide « %s »" % str(key))
			return null
		result.items[StringName(key)] = int(count)
	var companion: Variant = dict.get("companion", "")
	result.companion_uid = companion if PokemonUid.is_valid(companion) else ""
	return result
