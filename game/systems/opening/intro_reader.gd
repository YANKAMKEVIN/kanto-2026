class_name IntroReader
extends RefCounted
## Curseur pur de l'introduction du Prof. Chen ([IntroScript], dossier 13 §4, §5.5).
##
## Il ne fait qu'avancer dans les étapes et retenir les prénoms ; la future scène
## (`intro_stage.tscn`, OUV.2) affiche [method current] et relaie les entrées :
##  - STAGE et PAGE : [method advance] (toucher, ou fin d'un mouvement de scène) ;
##  - PROMPT : [method answer_prompt] avec la saisie ([NameRules] : normalisée, validée) ;
##  - CONFIRM : [method answer_confirm] ; Non ramène au prompt, champ prérempli
##    ([method prefill]) ; Oui continue ;
##  - LOOK : [method answer_look] avec une apparence de [constant IntroScript.LOOK_OPTIONS]
##    (chantier JR).
## Une action qui ne correspond pas à l'étape courante est refusée (faux). Aucun état
## persistant : l'introduction n'existe qu'en mémoire (§3.7) ; un abandon = jeter le lecteur.

var _script: IntroScript
var _max_length: int
var _index: int = 0
## Prompt → prénom retenu (normalisé).
var _answers: Dictionary[StringName, String] = {}
## Choix d'apparence → apparence retenue.
var _looks: Dictionary[StringName, StringName] = {}


## [param max_length] : [method OpeningNames.max_length].
func _init(intro: IntroScript, max_length: int) -> void:
	_script = intro
	_max_length = max_length


func index() -> int:
	return _index


func is_finished() -> bool:
	return _index >= _script.size()


## Étape courante (null une fois fini).
func current() -> IntroStep:
	return _script.step(_index)


## Texte de l'étape courante, jetons résolus ("" pour un STAGE ou à la fin).
func text() -> String:
	var entry := current()
	if entry == null or entry.type == IntroStep.Type.STAGE:
		return ""
	return IntroScript.resolve(entry.text, token_values())


## Passe une étape STAGE ou PAGE.
func advance() -> bool:
	var entry := current()
	if entry == null or entry.type == IntroStep.Type.PROMPT \
			or entry.type == IntroStep.Type.CONFIRM or entry.type == IntroStep.Type.LOOK:
		return false
	_index += 1
	return true


## Répond au PROMPT courant : faux (rien ne change) si [param raw] n'est pas un prénom valide.
func answer_prompt(raw: String) -> bool:
	var entry := current()
	if entry == null or entry.type != IntroStep.Type.PROMPT:
		return false
	if NameRules.validate(raw, _max_length) != NameRules.Result.OK:
		return false
	_answers[entry.name] = NameRules.normalize(raw)
	_index += 1
	return true


## Répond au CONFIRM courant : Oui → étape suivante ; Non → retour au prompt confirmé.
func answer_confirm(yes: bool) -> bool:
	var entry := current()
	if entry == null or entry.type != IntroStep.Type.CONFIRM:
		return false
	_index = _index + 1 if yes else _script.prompt_index(entry.name)
	return true


## Répond au LOOK courant : faux (rien ne change) si [param look] n'est pas proposé.
func answer_look(look: StringName) -> bool:
	var entry := current()
	if entry == null or entry.type != IntroStep.Type.LOOK \
			or not IntroScript.LOOK_OPTIONS[entry.name].has(look):
		return false
	_looks[entry.name] = look
	_index += 1
	return true


## Apparence retenue pour [param look_prompt] ; la première proposée tant qu'aucun choix.
func look(look_prompt: StringName) -> StringName:
	return _looks.get(look_prompt, IntroScript.LOOK_OPTIONS[look_prompt][0])


func player_look() -> StringName:
	return look(IntroScript.PROMPT_PLAYER_LOOK)


func rival_look() -> StringName:
	return look(IntroScript.PROMPT_RIVAL_LOOK)


## Valeur à placer dans le champ au PROMPT courant : le prénom déjà saisi (retour par Non),
## sinon "".
func prefill() -> String:
	var entry := current()
	if entry == null or entry.type != IntroStep.Type.PROMPT:
		return ""
	return _answers.get(entry.name, "")


## Prénom retenu pour [param prompt] ("" s'il n'a pas encore été saisi).
func answer(prompt: StringName) -> String:
	return _answers.get(prompt, "")


func player_name() -> String:
	return answer(IntroScript.PROMPT_PLAYER_NAME)


func rival_name() -> String:
	return answer(IntroScript.PROMPT_RIVAL_NAME)


## Valeurs des jetons (`{player}`, `{rival}`) connues à ce point.
func token_values() -> Dictionary[StringName, String]:
	var values: Dictionary[StringName, String] = {}
	for prompt: StringName in _answers:
		values[IntroScript.TOKEN_OF[prompt]] = _answers[prompt]
	values.merge(TrainerLooks.agreement_values(player_look(), rival_look()))
	return values


## Portraits sur la scène **avant** l'étape courante (portrait → emplacement), rejoués depuis
## le début : la scène peut se reconstruire à la même page (retour d'arrière-plan, §7).
func portraits_on_stage() -> Dictionary[StringName, StringName]:
	var on_stage: Dictionary[StringName, StringName] = {}
	for i: int in mini(_index, _script.size()):
		var entry := _script.step(i)
		if entry.type != IntroStep.Type.STAGE:
			continue
		if entry.show:
			on_stage[entry.portrait] = entry.slot
		else:
			on_stage.erase(entry.portrait)
	return on_stage
