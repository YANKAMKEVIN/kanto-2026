class_name GymQuiz
extends RefCounted
## Machines de quiz de l'Arène de Cramois'Île (jalon 25, dossier 28 §8.2, X-17 ;
## `jalon-25.md` §2.3), lues dans `data/gym/cinnabar_quiz.json`. Classe pure, sans scène.
##
## Bonne réponse : la herse s'ouvre pour toujours. Mauvaise réponse : le Dresseur lié vient
## combattre s'il n'est pas encore battu (sa victoire ouvre aussi la herse) ; s'il l'est déjà,
## sa herse est déjà ouverte. Une machine dont la herse est ouverte ne repose plus la question.

enum Result {
	RIGHT, ## Bonne réponse : poser le drapeau de la herse.
	WRONG_FIGHT, ## Mauvaise réponse : le Dresseur lié vient au joueur et combat.
	WRONG_ALREADY_BEATEN, ## Mauvaise réponse, Dresseur déjà battu : rien de plus.
	ALREADY_OPEN, ## Herse déjà ouverte : la machine ne pose plus la question.
	UNKNOWN, ## Machine inconnue.
}

const DATA_PATH: String = "res://data/gym/cinnabar_quiz.json"

var intro: StringName = &""
var _questions: Dictionary[int, Dictionary] = {}
var _errors: PackedStringArray = PackedStringArray()


static func load_default(path: String = DATA_PATH) -> GymQuiz:
	var quiz := GymQuiz.new()
	quiz.load_file(path)
	return quiz


func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1, json.get_error_message()])
	if not json.data is Dictionary or not json.data.get("questions") is Array:
		return _fail("%s : « questions » manquant" % path)
	intro = StringName(str(json.data.get("intro", "")))
	for entry: Variant in json.data["questions"]:
		if not entry is Dictionary:
			return _fail("%s : question invalide" % path)
		var q: Dictionary = entry
		for key: String in ["id", "text", "answer", "gate", "trainer"]:
			if not q.has(key):
				return _fail("%s : clé « %s » manquante" % [path, key])
		if not q["answer"] in ["yes", "no"]:
			return _fail("%s : réponse « %s » (yes ou no)" % [path, q["answer"]])
		_questions[int(q["id"])] = q
	return true


func get_errors() -> PackedStringArray:
	return _errors


func ids() -> Array[int]:
	var keys: Array[int] = _questions.keys()
	keys.sort()
	return keys


func question_text(id: int) -> String:
	return str(_questions.get(id, {}).get("text", ""))


func gate_flag(id: int) -> StringName:
	return StringName(str(_questions.get(id, {}).get("gate", "")))


func trainer_id(id: int) -> StringName:
	return StringName(str(_questions.get(id, {}).get("trainer", "")))


## Vrai si la machine [param id] doit poser sa question (herse encore fermée).
func should_ask(id: int, flags: StoryFlags) -> bool:
	return _questions.has(id) and not flags.has_flag(gate_flag(id))


## Issue de la réponse [param answered_yes] à la machine [param id]. Ne modifie rien : la
## scène pose le drapeau de la herse ([method open_gate]) après RIGHT ou après la victoire.
func resolve(id: int, answered_yes: bool, flags: StoryFlags) -> Result:
	if not _questions.has(id):
		return Result.UNKNOWN
	if flags.has_flag(gate_flag(id)):
		return Result.ALREADY_OPEN
	if answered_yes == (_questions[id]["answer"] == "yes"):
		return Result.RIGHT
	if TrainerRules.is_beaten(flags, trainer_id(id)):
		return Result.WRONG_ALREADY_BEATEN
	return Result.WRONG_FIGHT


## Ouvre la herse de la machine [param id] (bonne réponse ou victoire contre son Dresseur).
func open_gate(id: int, flags: StoryFlags) -> void:
	if _questions.has(id):
		flags.set_flag(gate_flag(id))


## Machine liée au Dresseur [param trainer] (0 si aucune : le Dresseur 1 n'en a pas).
func question_for_trainer(trainer: StringName) -> int:
	for id: int in ids():
		if trainer_id(id) == trainer:
			return id
	return 0


func _fail(message: String) -> bool:
	_errors.append(message)
	push_error("GymQuiz : " + message)
	return false
