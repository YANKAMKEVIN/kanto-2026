class_name DebugUnlocks
extends RefCounted
## Drapeau de débogage du Menu Dresseur (dossier 08 §4, dossier 09 §6, jalon-06.md §4) :
## débloque l'écran Pokédex pour développer et tester le J6, **sans** poser
## [constant StoryFlags.POKEDEX_ACTIVATED]. Rien n'est sauvegardé : il agit seulement sur
## [member MenuUnlocks.debug_pokedex] ([method apply]).
##
## [b]Quand est-il lu ?[/b] Par [Boot] (T4), avec la même garde que [DebugStart] :
## build debug, [Boot] scène principale lancée par le moteur (jamais sous GUT ni dans un outil,
## [method is_allowed]), et le fichier [constant USER_PATH] existe. On l'y dépose avec
## `tools/deploy_s24.sh --debug-unlock pokedex` ; sans l'option, il est retiré. Il marche avec
## la vraie sauvegarde comme avec un départ de débogage.
##
## Format (validation stricte : clé inconnue ou valeur non booléenne = erreur, rien n'est
## gardé) : [code]{ "pokedex": true }[/code].

const USER_PATH: String = "user://debug_unlocks.json"
## Clés connues (une par écran débloquable) ; `tools/deploy_s24.sh` accepte les mêmes noms.
const KEYS: Array[String] = ["pokedex"]

var pokedex: bool = false
var _errors: PackedStringArray = PackedStringArray()


## Vrai si le fichier peut être lu : build debug et Boot scène principale (même règle que
## [method DebugStart.is_allowed]).
static func is_allowed(debug_build: bool, boot_is_main_scene: bool) -> bool:
	return DebugStart.is_allowed(debug_build, boot_is_main_scene)


## Lit [param path]. Faux (push_error) s'il est illisible ou invalide : rien n'est gardé.
func load_file(path: String = USER_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà décodé. Tout ou rien.
func add_from_dict(dict: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in dict:
		if not key is String or not KEYS.has(key):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
		elif not dict[key] is bool:
			ok = _fail("%s : « %s » vaut true ou false" % [source, key])
	if not ok:
		return false
	pokedex = dict.get("pokedex", false)
	return true


## Reporte les déblocages sur [param unlocks] (jamais sur les drapeaux d'histoire).
func apply(unlocks: MenuUnlocks) -> void:
	if unlocks != null:
		unlocks.debug_pokedex = pokedex


## Résumé d'une ligne (journal du jeu).
func describe() -> String:
	return "pokedex" if pokedex else "aucun"


func get_errors() -> PackedStringArray:
	return _errors


func _fail(message: String) -> bool:
	var full := "DebugUnlocks : " + message
	_errors.append(full)
	push_error(full)
	return false
