class_name DaycareConfig
extends RefCounted
## Réglages de la Pension Pokémon (J15, dossier 18 ; décisions de Kevin du 2026-10-11 : F-1,
## F-2, F-3), lus dans `data/daycare/daycare.json`. Donnée pure, sans règle.
##
## Format (toutes les clés sont obligatoires ; une clé inconnue est une erreur) :
## [codeblock]
## {
##   "exp_per_step": 1,           # XP mise en attente par pas du joueur (F-1)
##   "price_base": 100,           # prix du retrait, part fixe (F-2)
##   "price_per_level": 100,      # prix du retrait, par niveau gagné (F-2)
##   "money_policy": "take_all",  # argent insuffisant : « take_all » (F-2) ou « refuse » (RB)
##   "evolve_on_withdraw": true   # évolution proposée au retrait (F-3)
## }
## [/codeblock]
## Un fichier invalide laisse les valeurs par défaut ci-dessous (celles de F-1 à F-3) et signale
## l'erreur ([method get_errors], push_error).

## Argent insuffisant au retrait.
enum MoneyPolicy {
	TAKE_ALL, ## La Pension rend le Pokémon et prend tout l'argent du joueur (F-2, K26).
	REFUSE, ## La Pension refuse le retrait (Rouge/Bleu).
}

const DATA_PATH: String = "res://data/daycare/daycare.json"
const MONEY_POLICY_NAMES: Dictionary[String, MoneyPolicy] = {
	"take_all": MoneyPolicy.TAKE_ALL, "refuse": MoneyPolicy.REFUSE,
}
const _KEYS: Array[String] = [
	"exp_per_step", "price_base", "price_per_level", "money_policy", "evolve_on_withdraw",
]

var exp_per_step: int = 1
var price_base: int = 100
var price_per_level: int = 100
var money_policy: MoneyPolicy = MoneyPolicy.TAKE_ALL
var evolve_on_withdraw: bool = true

var _errors: PackedStringArray = PackedStringArray()


## Réglages lus dans [param path] (valeurs par défaut et erreurs signalées si le fichier est
## invalide).
static func load_default(path: String = DATA_PATH) -> DaycareConfig:
	var config := DaycareConfig.new()
	config.load_file(path)
	return config


## Charge [param path]. Faux si le fichier est illisible ou invalide (rien ne change alors).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet est attendu" % path)
	return set_from_dict(json.data, path)


## Applique un objet déjà lu ; tout ou rien : faux (rien ne change) à la première erreur.
func set_from_dict(data: Dictionary, source: String = "") -> bool:
	for key: Variant in data:
		if not _KEYS.has(str(key)):
			return _fail("%s : clé inconnue « %s »" % [source, key])
	for key: String in _KEYS:
		if not data.has(key):
			return _fail("%s : clé « %s » manquante" % [source, key])
	for key: String in ["exp_per_step", "price_base", "price_per_level"]:
		if not JsonFields.is_int(data[key]) or int(data[key]) < 0:
			return _fail("%s : « %s » doit être un entier ≥ 0" % [source, key])
	if not MONEY_POLICY_NAMES.has(str(data["money_policy"])):
		return _fail("%s : « money_policy » inconnue « %s »" % [source, data["money_policy"]])
	if not data["evolve_on_withdraw"] is bool:
		return _fail("%s : « evolve_on_withdraw » doit être true ou false" % source)
	exp_per_step = int(data["exp_per_step"])
	price_base = int(data["price_base"])
	price_per_level = int(data["price_per_level"])
	money_policy = MONEY_POLICY_NAMES[str(data["money_policy"])]
	evolve_on_withdraw = data["evolve_on_withdraw"]
	return true


func get_errors() -> PackedStringArray:
	return _errors


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("DaycareConfig : " + message)
	return false
