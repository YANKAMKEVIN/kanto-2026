extends EvolutionScreen
## Faux écran d'évolution (jalon-09.md §2.3.3, T8) : note chaque appel du contrat, dans l'ordre ;
## [member cancel] : [member back] (le retour Android relayé, par exemple
## [method EvolutionDirector.handle_back]) est appelé pendant la transformation et sa réponse
## notée ; [member probe] est appelé au début de la transformation (état des données à ce
## moment-là). [member banner] / [member host] : bandeau et parent des panneaux (facultatifs).

var calls: Array[String] = []
var views: Array[EvolutionView] = []
var cancel: bool = false
var back: Callable = Callable()
var probe: Callable = Callable()
var back_answers: Array[bool] = []
var banner: BattleMessageBanner
var host: Control


func open() -> void:
	calls.append("open")
	await super.open()


func present(view: EvolutionView) -> void:
	calls.append("present")
	views.append(view)
	await super.present(view)


func transform() -> bool:
	calls.append("transform")
	_transforming = true
	if probe.is_valid():
		probe.call()
	await get_tree().process_frame
	if cancel and back.is_valid():
		back_answers.append(bool(back.call()))
	await get_tree().process_frame
	_transforming = false
	var cancelled := _cancel_requested
	_cancel_requested = false
	return cancelled


func reveal() -> void:
	calls.append("reveal")


func revert() -> void:
	calls.append("revert")


func close() -> void:
	calls.append("close")
	await super.close()


func get_message_banner() -> BattleMessageBanner:
	return banner


func get_prompt_host() -> Control:
	return host
