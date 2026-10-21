class_name FieldMoves
extends RefCounted
## Capacités de terrain (jalon 16, dossier 19 §7, `jalon-16.md` §2.2) : classe pure.
##
## Une capacité de terrain (Coupe) se débloque par une CS dans le Sac ; elle demande un badge
## (Coupe : le Badge Cascade, G-3) et un Pokémon de l'équipe **compatible** (il peut l'apprendre
## par la CS, ou la connaît déjà) ; elle **n'occupe aucun emplacement** de capacité (G-2, dossier
## 06 §11). Un Pokémon K.O. peut s'en servir (défaut, `jalon-16.md` §6). Les règles viennent de
## `data/world/field_moves.json` :
## [codeblock]
## "cut": { "hm": "hm01", "badge": "badge_cascade" }
## [/codeblock]
## L'ordre des vérifications fixe l'état et le texte de l'arbuste (dossier 19 §0.5, n° 25 à 28) :
## pas de CS → NO_HM ; pas de badge → NO_BADGE (prime sur l'équipe) ; aucun compatible →
## NO_POKEMON ; sinon READY. Le Pokémon nommé ({pokemon}) : le compagnon s'il est compatible,
## sinon le premier compatible dans l'ordre de l'équipe ; pour NO_BADGE sans compatible, le
## premier de l'équipe (défaut du §0.5).
## Jalon 17 (T24, dossier 20 T-17) : « cue » (facultatif) : texte de la mise en scène de la
## capacité, jeton `{pokemon}` ([method cue_text]) — « {pokemon} utilise Flash ! ».
## Passe systèmes 2 (T25b, Téléport et Tunnel hors combat) : une capacité **sans CS**
## (`"hm": ""`) ne demande que d'être **connue** par un Pokémon de l'équipe (pas de compatibilité
## par CS) ; jamais NO_HM, NO_BADGE seulement si un badge est donné.

enum State { NO_HM, NO_BADGE, NO_POKEMON, READY }

## Nom de chaque état dans les variantes de dialogue (« cut:ready »), dans l'ordre de [enum State].
const STATE_NAMES: Array[String] = ["no_hm", "no_badge", "no_pokemon", "ready"]
const DATA_FILE: String = "res://data/world/field_moves.json"


## Résultat de [method check] : l'état et l'indice dans l'équipe du Pokémon nommé (−1 : aucun).
class Result:
	extends RefCounted
	var state: State = State.NO_HM
	var pokemon_index: int = -1
	## Nom affiché du Pokémon nommé (jeton `{pokemon}` des textes de l'arbuste) ; "" si aucun.
	var pokemon_name: String = ""

	func _init(p_state: State = State.NO_HM, p_index: int = -1) -> void:
		state = p_state
		pokemon_index = p_index

	## « cut:ready » : clé des variantes de dialogue.
	func key(move: StringName) -> String:
		return "%s:%s" % [move, STATE_NAMES[state]]


## Règle d'une capacité : identifiant de la CS et drapeau de badge (&"" = aucun).
var _rules: Dictionary[StringName, Dictionary] = {}
var _errors: PackedStringArray = PackedStringArray()


## Charge les règles. Faux si le fichier est illisible ou invalide (erreurs dans [method get_errors]).
func load_file(path: String = DATA_FILE) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return _fail("%s : objet { capacité: règle } attendu" % path)
	return add_from_dict(json.data, path)


## Ajoute des règles déjà lues (« _doc » ignorée).
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if str(key) == "_doc":
			continue
		var rule: Variant = data[key]
		if not rule is Dictionary or not (rule as Dictionary).get("hm") is String \
				or not (rule as Dictionary).get("badge", "") is String \
				or not _is_cue((rule as Dictionary).get("cue", "")) \
				or ((rule as Dictionary).keys().any(func(k: Variant) -> bool:
					return not ["hm", "badge", "cue"].has(str(k)))):
			ok = _fail("%s « %s » : { \"hm\": objet, \"badge\": drapeau, \"cue\": texte } attendu"
				% [source, key])
			continue
		_rules[StringName(str(key))] = {
			&"hm": StringName(rule["hm"]), &"badge": StringName(rule.get("badge", "")),
			&"cue": String(rule.get("cue", "")),
		}
	return ok


## Vrai si [param move] est une capacité de terrain connue.
func has_move(move: StringName) -> bool:
	return _rules.has(move)


## Identifiant de la CS qui débloque [param move] (&"" si inconnue).
func hm_of(move: StringName) -> StringName:
	return _rules.get(move, {}).get(&"hm", &"")


## Vrai si [param move] se débloque par une CS ; faux pour une capacité connue seulement
## (`"hm": ""`, T25b : Téléport, Tunnel) ou inconnue.
func needs_hm(move: StringName) -> bool:
	return hm_of(move) != &""


## Texte de la mise en scène de [param move] (« cue »), `{pokemon}` remplacé par
## [param pokemon_name] ; "" sans texte ou sans nom.
func cue_text(move: StringName, pokemon_name: String) -> String:
	var cue: String = _rules.get(move, {}).get(&"cue", "")
	return DialogueTokens.resolve(cue, {&"pokemon": pokemon_name})


## État de [param move] pour l'équipe [param party], le Sac [param bag] et les drapeaux
## [param flags] ; [param companion] : le Pokémon sorti (ou null), préféré s'il est compatible.
func check(move: StringName, party: Party, bag: Bag, flags: StoryFlags, items: ItemLibrary,
		data: PokemonData, companion: Pokemon = null) -> Result:
	if not _rules.has(move):
		return Result.new(State.NO_HM)
	var hm: ItemData = null
	if needs_hm(move):
		hm = items.get_item(hm_of(move)) if items != null else null
		if hm == null or not hm.is_hm() or bag == null or not bag.has(hm.id):
			return Result.new(State.NO_HM)
	var compatible := _compatible_index(move, hm, party, data, companion)
	var badge: StringName = _rules[move][&"badge"]
	if badge != &"" and (flags == null or not flags.has_flag(badge)):
		var named := compatible if compatible >= 0 else (0 if party != null and party.size() > 0 \
			else -1)
		return _named(Result.new(State.NO_BADGE, named), party, data)
	if compatible < 0:
		return Result.new(State.NO_POKEMON)
	return _named(Result.new(State.READY, compatible), party, data)


func get_errors() -> PackedStringArray:
	return _errors


## Indice du Pokémon qui utilise [param move] : le compagnon s'il est compatible, sinon le premier
## compatible de l'équipe ; −1 si aucun.
func _compatible_index(move: StringName, hm: ItemData, party: Party, data: PokemonData,
		companion: Pokemon) -> int:
	if party == null:
		return -1
	if companion != null and _can_use(move, hm, companion, data):
		var index := party.index_of(companion)
		if index >= 0:
			return index
	var members := party.get_all()
	for i: int in members.size():
		if _can_use(move, hm, members[i], data):
			return i
	return -1


func _named(result: Result, party: Party, data: PokemonData) -> Result:
	var pokemon := party.get_at(result.pokemon_index) if party != null else null
	if pokemon != null:
		result.pokemon_name = pokemon.display_name(data)
	return result


## [param hm] null : capacité sans CS, il faut la connaître.
func _can_use(move: StringName, hm: ItemData, pokemon: Pokemon, data: PokemonData) -> bool:
	if pokemon.knows_move(move):
		return true
	return hm != null and data != null and data.can_learn_hm(pokemon.species_id, hm.hm_number)


## « cue » : absent, ou un texte dont les seuls jetons sont `{pokemon}`.
static func _is_cue(value: Variant) -> bool:
	if not value is String:
		return false
	for token: StringName in DialogueTokens.tokens_in(value):
		if token != &"pokemon":
			return false
	return true


func _fail(message: String) -> bool:
	var full := "FieldMoves : " + message
	_errors.append(full)
	push_error(full)
	return false
