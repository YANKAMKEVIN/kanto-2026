extends Control
## Faux ChoiceCards (jalon-06.md §6.12) pour tester la confirmation d'oubli sans le composant :
## répond aux questions dans l'ordre de [member answers] après trois images.

signal chosen(confirmed: bool)

static var answers: Array[bool] = []
static var views: Array[ChoiceView] = []

var speed_scale: float = 1.0


func show_choice(view: ChoiceView) -> void:
	views.append(view)
	for i: int in 3:
		await get_tree().process_frame
	chosen.emit(answers.pop_front() if not answers.is_empty() else true)
