extends RefCounted
## Temps simulé pour les tests : les tweens nés après la création de l'horloge ne suivent plus
## le temps réel ; ils avancent seulement quand le test appelle [method step], par pas fixes.
## Une durée se compte alors en pas, quelle que soit la charge de la machine.
##
## Utilisation : [code]const TweenClock := preload("res://tests/helpers/tween_clock.gd")[/code],
## [code]var clock := TweenClock.new(get_tree())[/code] juste avant l'appel mesuré, puis
## [method step] ou [method run_until], et [method release] à la fin.
##
## Les tweens sont figés par une vitesse nulle, pas par une pause : ils restent « en cours »
## ([method Tween.is_running]), que du code de jeu consulte (cartes de combat, élan des PNJ).
## Pendant que l'horloge les tient, un [method Tween.custom_step] du jeu sur l'un d'eux
## (« terminer tout de suite ») est sans effet. Les tweens sont avancés à la vitesse 1
## (Tween n'expose pas sa vitesse) : BattleStage et GrassRustle ne s'utilisent qu'avec leur
## speed_scale à 1.

const STEP := 1.0 / 60.0

var _tree: SceneTree
## Tweens existants à la création : laissés au moteur (temps réel).
var _ignored: Array[Tween] = []
## Tweens tenus par l'horloge.
var _driven: Array[Tween] = []


func _init(tree: SceneTree) -> void:
	_tree = tree
	_ignored = tree.get_processed_tweens()


## Avance d'un pas de [param seconds] tous les tweens nés depuis la création de l'horloge.
## Ceux créés pendant ce pas (enchaînements) sont figés aussitôt et avancent au pas suivant.
func step(seconds: float = STEP) -> void:
	_adopt()
	for tween: Tween in _driven.duplicate():
		if not tween.is_valid():
			continue
		tween.set_speed_scale(1.0)
		tween.custom_step(seconds)
		if tween.is_valid():
			tween.set_speed_scale(0.0)
	_adopt()


## Pas de [constant STEP] jusqu'à ce que [param done] rende vrai (au plus
## [param max_seconds]). Rend le nombre de pas faits.
func run_until(done: Callable, max_seconds: float = 10.0) -> int:
	var steps := 0
	while not done.call() and steps * STEP < max_seconds:
		step()
		steps += 1
	return steps


## Rend au moteur (temps réel) les tweens encore vivants.
func release() -> void:
	for tween: Tween in _driven:
		if tween.is_valid():
			tween.set_speed_scale(1.0)
	_driven.clear()


func _adopt() -> void:
	for tween: Tween in _tree.get_processed_tweens():
		if not tween.is_valid() or _ignored.has(tween) or _driven.has(tween):
			continue
		_driven.append(tween)
		tween.set_speed_scale(0.0)
