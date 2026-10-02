class_name BattleText
extends RefCounted
## Phrases des messages de combat, à partir des modèles de `data/battle/messages.json`
## (jalon 4 §2.2, décisions de Kevin du §8 point 5). Classe pure.
##
## Format :
## [codeblock]
## {
##   "templates": {
##     "sent_out_foe": { "text": "{trainer} envoie {pokemon} !" },
##     "move_used": { "text": "{pokemon} utilise {move} !", "draft": true },
##     "recoil": { "text": "{pokemon} est blessé par le contrecoup !",
##                 "text_f": "{pokemon} est blessée par le contrecoup !" }, ...
##   },
##   "stats": { "atk": "L'Attaque", ... }
## }
## [/codeblock]
## Tous les modèles de [constant TEMPLATE_IDS] sont obligatoires, aucun autre n'est admis.
## Marques admises : {pokemon} (nom seul, jamais « ennemi » ni « du Rival »), {de_pokemon}
## (« de Salamèche », « d'Évoli »), {move}, {trainer}, {stat} (nom de « stats »), {level}
## (niveau de l'événement), {exp} (son [member BattleEvent.amount]), {old_move} (capacité
## oubliée, seulement par [method line_for]), {item} (nom de la Ball,
## [member BattleEvent.item_name]).
## Capture (jalon 5D) : BALL_THROWN → « ball_thrown » ; BROKE_FREE → « broke_free » ;
## BALL_SHAKE, CAUGHT et BATTLE_ENDED (CAUGHT) n'ont pas de phrase. La carte de capture
## (dossier 05 §17) demande à [method line_for], avec l'événement CAUGHT (accord au féminin) :
## « caught_title » (« Roucool CAPTURÉ ! » ; la carte l'affiche en capitales), « pokedex_new »
## (seulement pour une nouvelle entrée), puis « joined_party » ou « sent_to_storage ».
## XP (jalon 5C, Q25) : EXP_GAINED et LEVEL_UP n'ont pas de phrase (« +21 XP » et « Nv. 6 »
## sont sur la carte) ; MOVE_LEARNED → « move_learned » ; MOVE_FORGET_OFFERED →
## « move_forget_prompt ». La suite de l'oubli (« move_forgot », « move_not_learned ») ne
## vient pas d'un événement : la présentation la demande à [method line_for]. « level_up »
## est disponible par [method line_for] (aucune phrase par défaut, Q25).
## « draft » : texte à relire par Kevin. « text_f » (facultatif) : la phrase accordée au
## féminin, employée quand le Pokémon de l'événement est une femelle (décision de Kevin
## n° 15, jalon 4 §8) ; sans elle, « text » sert pour tous. [method lines] traduit un
## [BattleEvent] en 0, 1 ou plusieurs phrases (un coup critique super efficace en donne
## deux). Un dresseur sans message de fin ([member TrainerData.end_message] faux : premier
## combat du rival, dont les répliques en tiennent lieu) n'a pas de phrase à la fin ; de
## même, sans message de début ([member TrainerData.start_message] faux, décision n° 17 :
## « On ne va quand même pas partir… » lance le combat), pas de « … veut se battre ! ».

const DATA_PATH: String = "res://data/battle/messages.json"
const TEMPLATE_IDS: Array[StringName] = [
	&"battle_started", &"sent_out_foe", &"sent_out_player", &"move_used", &"move_missed",
	&"critical", &"super_effective", &"not_very_effective", &"no_effect",
	&"stat_rose", &"stat_rose_2", &"stat_rose_3", &"stat_fell", &"stat_fell_2",
	&"stat_fell_3", &"stat_no_higher", &"stat_no_lower", &"recoil", &"fainted",
	&"battle_won", &"battle_lost", &"wild_appeared", &"fled", &"flee_failed",
	&"level_up", &"move_learned", &"move_forget_prompt", &"move_forgot", &"move_not_learned",
	&"seeded", &"drained",
	&"ball_thrown", &"broke_free", &"caught_title", &"pokedex_new", &"joined_party",
	&"sent_to_storage",
]
const PLACEHOLDERS: Array[String] = [
	"pokemon", "de_pokemon", "move", "trainer", "stat", "level", "exp", "old_move", "item",
]

const _TEMPLATE_KEYS: Array[String] = ["text", "text_f", "draft"]
const _VOWELS: String = "AEIOUYÀÂÄÉÈÊËÎÏÔÖÙÛÜaeiouyàâäéèêëîïôöùûü"

var _texts: Dictionary[StringName, String] = {}
## Variantes au féminin (modèles qui en ont une).
var _texts_f: Dictionary[StringName, String] = {}
var _drafts: Dictionary[StringName, bool] = {}
var _stats: Dictionary[StringName, String] = {}
var _errors: PackedStringArray = PackedStringArray()
var _placeholder: RegEx = RegEx.create_from_string("\\{([^}]*)\\}")


## Charge [param path]. Faux si le fichier est illisible ou invalide (aucun modèle gardé).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"templates\": …, \"stats\": … } est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà décodé. Tout ou rien : en cas d'erreur, aucun modèle n'est gardé.
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not ["templates", "stats"].has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("templates") is Dictionary or not data.get("stats") is Dictionary:
		return _fail("%s : « templates » et « stats » doivent être des objets" % source)
	var texts: Dictionary[StringName, String] = {}
	var texts_f: Dictionary[StringName, String] = {}
	var drafts: Dictionary[StringName, bool] = {}
	var templates: Dictionary = data["templates"]
	for key: Variant in templates:
		var id := StringName(str(key))
		var where := "%s modèle « %s »" % [source, id]
		if not TEMPLATE_IDS.has(id):
			ok = _fail("%s : modèle inconnu" % where)
			continue
		ok = _parse_template(templates[key], id, texts, texts_f, drafts, where) and ok
	for id: StringName in TEMPLATE_IDS:
		if not templates.has(String(id)):
			ok = _fail("%s : modèle « %s » manquant" % [source, id])
	var stats: Dictionary[StringName, String] = {}
	var raw_stats: Dictionary = data["stats"]
	for key: Variant in raw_stats:
		var stat := StringName(str(key))
		if not MoveEffect.STAGE_STATS.has(stat):
			ok = _fail("%s stats : statistique inconnue « %s »" % [source, stat])
		elif not raw_stats[key] is String or (raw_stats[key] as String).strip_edges().is_empty():
			ok = _fail("%s stats « %s » : texte non vide attendu" % [source, stat])
		else:
			stats[stat] = raw_stats[key]
	for stat: StringName in MoveEffect.STAGE_STATS:
		if not raw_stats.has(String(stat)):
			ok = _fail("%s stats : « %s » manquant" % [source, stat])
	if not ok:
		return false
	_texts = texts
	_texts_f = texts_f
	_drafts = drafts
	_stats = stats
	return true


## Modèle brut [param id] (chaîne vide s'il n'existe pas). [param feminine] : sa variante
## au féminin si elle existe, sinon le modèle commun.
func get_template(id: StringName, feminine: bool = false) -> String:
	if feminine and _texts_f.has(id):
		return _texts_f[id]
	return _texts.get(id, "")


## Vrai si le modèle [param id] a une variante au féminin (« text_f »).
func has_feminine(id: StringName) -> bool:
	return _texts_f.has(id)


## Vrai si le modèle [param id] est un texte provisoire, à relire par Kevin.
func is_draft(id: StringName) -> bool:
	return _drafts.get(id, false)


## Phrases à afficher pour [param event], dans l'ordre (vide = pas de message). Les noms
## de capacités viennent de [param data]. [param trainer] : le dresseur adverse (null =
## message de fin par défaut) ; s'il n'a pas de message de fin, BATTLE_ENDED n'en a pas.
func lines(event: BattleEvent, data: PokemonData, trainer: TrainerData = null) \
		-> PackedStringArray:
	var result := PackedStringArray()
	var foe := event.side == BattleEvent.SideId.FOE
	match event.kind:
		BattleEvent.Kind.BATTLE_STARTED:
			var wanted_start := trainer == null or trainer.start_message
			if wanted_start and not event.trainer_name.is_empty():
				result.append(_fill(&"battle_started", event, data))
		BattleEvent.Kind.SENT_OUT:
			if not foe:
				result.append(_fill(&"sent_out_player", event, data))
			elif not event.trainer_name.is_empty():
				result.append(_fill(&"sent_out_foe", event, data))
			else:
				result.append(_fill(&"wild_appeared", event, data))
		BattleEvent.Kind.MOVE_USED:
			result.append(_fill(&"move_used", event, data))
		BattleEvent.Kind.MOVE_MISSED:
			result.append(_fill(&"move_missed", event, data))
		BattleEvent.Kind.DAMAGE:
			if event.critical:
				result.append(_fill(&"critical", event, data))
			if event.effectiveness > 1.0:
				result.append(_fill(&"super_effective", event, data))
			elif event.effectiveness < 1.0:
				result.append(_fill(&"not_very_effective", event, data))
		BattleEvent.Kind.NO_EFFECT:
			result.append(_fill(&"no_effect", event, data))
		BattleEvent.Kind.STAT_CHANGED:
			var size := mini(absi(event.stages), 3)
			var base := "stat_rose" if event.stages > 0 else "stat_fell"
			var id := StringName(base if size == 1 else "%s_%d" % [base, size])
			result.append(_fill(id, event, data))
		BattleEvent.Kind.STAT_UNCHANGED:
			result.append(_fill(&"stat_no_higher" if event.stages > 0 else &"stat_no_lower",
				event, data))
		BattleEvent.Kind.RECOIL:
			result.append(_fill(&"recoil", event, data))
		BattleEvent.Kind.FAINTED:
			result.append(_fill(&"fainted", event, data))
		BattleEvent.Kind.FLED:
			result.append(_fill(&"fled", event, data))
		BattleEvent.Kind.FLEE_FAILED:
			result.append(_fill(&"flee_failed", event, data))
		BattleEvent.Kind.MOVE_LEARNED:
			result.append(_fill(&"move_learned", event, data))
		BattleEvent.Kind.MOVE_FORGET_OFFERED:
			result.append(_fill(&"move_forget_prompt", event, data))
		BattleEvent.Kind.SEEDED:
			result.append(_fill(&"seeded", event, data))
		BattleEvent.Kind.DRAINED:
			result.append(_fill(&"drained", event, data))
		BattleEvent.Kind.BALL_THROWN:
			result.append(_fill(&"ball_thrown", event, data))
		BattleEvent.Kind.BROKE_FREE:
			result.append(_fill(&"broke_free", event, data))
		BattleEvent.Kind.BATTLE_ENDED:
			# FLED ne porte pas de message ici (il est sur l'événement FLED). Un sauvage n'a
			# pas de dresseur (trainer_name vide) : « Tu as battu… » ne s'affiche pas.
			var wanted := trainer == null or trainer.end_message
			if wanted and not event.trainer_name.is_empty() \
					and event.outcome in [Battle.Outcome.WIN, Battle.Outcome.LOSS]:
				result.append(_fill(&"battle_won" if event.outcome == Battle.Outcome.WIN
					else &"battle_lost", event, data))
	return result


## Phrase du modèle [param id] remplie avec [param event] (chaîne vide si le modèle n'existe
## pas). [param old_move] : la capacité oubliée ({old_move}). Sert à ce qui ne vient pas d'un
## événement du moteur : « Salamèche oublie Griffe et apprend Frénésie ! »
## ([code]line_for(&"move_forgot", offered, data, &"scratch")[/code]), « … n'apprend pas … ».
func line_for(id: StringName, event: BattleEvent, data: PokemonData,
		old_move: StringName = &"") -> String:
	if not _texts.has(id):
		return ""
	return _fill(id, event, data, old_move)


## « de Salamèche », « d'Évoli » : élision devant une voyelle.
static func de_name(name: String) -> String:
	if not name.is_empty() and _VOWELS.contains(name.left(1)):
		return "d'" + name
	return "de " + name


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _fill(id: StringName, event: BattleEvent, data: PokemonData,
		old_move: StringName = &"") -> String:
	var move := data.get_move(event.move_id)
	var forgotten := data.get_move(old_move)
	return get_template(id, event.gender == Pokemon.Gender.FEMALE).format({
		"pokemon": event.pokemon_name,
		"de_pokemon": de_name(event.pokemon_name),
		"move": move.name if move != null else String(event.move_id),
		"trainer": event.trainer_name,
		"stat": _stats.get(event.stat, String(event.stat)),
		"level": event.level,
		"exp": event.amount,
		"old_move": forgotten.name if forgotten != null else String(old_move),
		"item": event.item_name,
	})


func _parse_template(value: Variant, id: StringName, texts: Dictionary[StringName, String],
		texts_f: Dictionary[StringName, String], drafts: Dictionary[StringName, bool],
		where: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : un objet { \"text\": … } est attendu" % where)
	var entry: Dictionary = value
	var ok := true
	for key: Variant in entry:
		if not _TEMPLATE_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	if not _is_text(entry.get("text")):
		return _fail("%s : « text » doit être un texte non vide" % where)
	ok = _check_placeholders(entry["text"], where) and ok
	if entry.has("text_f"):
		if not _is_text(entry["text_f"]):
			ok = _fail("%s : « text_f » doit être un texte non vide" % where)
		else:
			ok = _check_placeholders(entry["text_f"], where + " text_f") and ok
			texts_f[id] = entry["text_f"]
	if entry.has("draft") and not entry["draft"] is bool:
		ok = _fail("%s : « draft » vaut true ou false" % where)
	texts[id] = entry["text"]
	drafts[id] = entry.get("draft") is bool and entry["draft"]
	return ok


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


func _check_placeholders(text: String, where: String) -> bool:
	var ok := true
	for found: RegExMatch in _placeholder.search_all(text):
		if not PLACEHOLDERS.has(found.get_string(1)):
			ok = _fail("%s : marque inconnue « {%s} »" % [where, found.get_string(1)])
	return ok


func _fail(message: String) -> bool:
	var full := "BattleText : " + message
	_errors.append(full)
	push_error(full)
	return false
