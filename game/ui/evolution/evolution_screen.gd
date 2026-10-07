class_name EvolutionScreen
extends CanvasLayer
## Écran d'évolution (jalon-09.md §2.3.3) : **contrat** entre [EvolutionDirector] (la logique et
## l'ordre) et la présentation (T9 : le temps, l'image, le geste). Ce script pose le contrat et
## une version immédiate, sans image ; le T9 en fait la vraie scène
## (`evolution_screen.tscn`, CanvasLayer au-dessus de la HUD de combat) **sans changer les
## signatures** : le directeur n'attend que ces coroutines, dans cet ordre, pour chaque
## évolution d'un même combat :
##
## [codeblock]
## open()                         # une fois : l'environnement disparaît
## present(view)                  # l'ancienne espèce, « Quoi ? X évolue ! »
## var cancelled := transform()   # silhouettes, ARRÊTER ; vrai si annulée
##   (le directeur applique l'évolution ici, seulement si elle n'est pas annulée)
## reveal()  ou  revert()         # nouvelle espèce / retour à l'ancienne, toucher
##   (capacités : bandeau get_message_banner(), panneaux dans get_prompt_host())
## … present(view) suivant …
## close()                        # une fois : retour à la vue de combat
## [/codeblock]
##
## Le directeur ne mesure aucun temps : toutes les durées (défauts du §2.3.3 : présentation
## 1,5 s, transformation 5 s, flash 0,3 s, silence 0,4 s) vivent ici, dans
## `UiTokens.EVOLUTION_*`, multipliées par [member speed_scale] (0 = instantané, tests ;
## « Réduire les animations » les divise). Toute attente se fait avec un Tween (temps simulé
## dans les tests). Rien n'est écrit dans la partie par l'écran.

## Multiplie toutes les durées (relayé par le directeur avant [method open]) ; 0 = instantané.
var speed_scale: float = 1.0

var _open: bool = false
var _transforming: bool = false
var _cancel_requested: bool = false


## Coroutine : l'écran apparaît (fond opaque sombre, « l'environnement disparaît »). Appelée une
## fois avant la première évolution d'un combat.
func open() -> void:
	_open = true
	visible = true


## Coroutine : [param view] — l'ancienne espèce au centre, puis [member EvolutionView.started_text]
## (≈ 1,5 s, sans toucher). Appelée pour chaque évolution, après [method open].
func present(_view: EvolutionView) -> void:
	_cancel_requested = false


## Coroutine : la transformation (≈ 5 s) — silhouettes blanches de l'ancienne et de la nouvelle
## espèce qui alternent en accélérant ; le bouton [member EvolutionView.stop_label] n'est
## visible et actif que pendant cette phase. Rend [code]true[/code] si le joueur l'a arrêtée
## (bouton ou [method handle_back]) : la transformation s'interrompt aussitôt. Rend
## [code]false[/code] arrivée à son terme (le directeur applique alors l'évolution).
func transform() -> bool:
	_transforming = true
	var cancelled := _cancel_requested
	_transforming = false
	_cancel_requested = false
	return cancelled


## Coroutine : l'évolution est faite (déjà appliquée aux données) — flash, silence, la nouvelle
## espèce en couleurs, vibration courte, [member EvolutionView.finished_text], puis attente d'un
## toucher ([member EvolutionView.continue_text]).
func reveal() -> void:
	pass


## Coroutine : l'évolution est annulée — retour à l'ancienne espèce en couleurs,
## [member EvolutionView.cancelled_text], puis attente d'un toucher.
func revert() -> void:
	pass


## Bandeau des messages des capacités apprises à l'évolution ([MoveLearnPrompt]) ; null = pas
## de bandeau (les capacités sont alors apprises sans rien demander, place libre seulement).
func get_message_banner() -> BattleMessageBanner:
	return null


## Parent plein écran (Control) du panneau d'oubli et de la question à deux cartes ; null =
## aucun.
func get_prompt_host() -> Control:
	return null


## Coroutine : l'écran disparaît (retour à la vue de combat, qui sort ensuite). Appelée une fois
## après la dernière évolution.
func close() -> void:
	_open = false
	visible = false


## Retour Android pendant l'écran : pendant [method transform], arrête la transformation
## (comme ARRÊTER) ; ailleurs, sans effet. Vrai tant que l'écran est ouvert (le geste ne passe
## jamais à ce qui est dessous).
func handle_back() -> bool:
	if _transforming:
		_cancel_requested = true
	return _open


## La transformation est en cours (le bouton ARRÊTER est actif).
func is_transforming() -> bool:
	return _transforming


func is_open() -> bool:
	return _open
