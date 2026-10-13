class_name DaycareStepCounter
extends RefCounted
## Compteur de pas de la Pension (J15, jalon-15.md §2.5.1 ; dossier 18 §4.2 : « 1 XP par pas du
## joueur, sur toutes les cartes ; pas scriptés exclus ; la course compte comme la marche ; un pas
## refusé ne compte pas »). Classe pure : le [DaycareDirector] l'appelle à chaque
## [signal Player.moved] avec [method Player.is_input_enabled] (même filtre que
## `SceneRouter._on_player_moved`). Un pas refusé (mur) n'émet pas `moved` ; la course émet
## `moved` comme la marche : rien à distinguer ici. Aucune allocation, aucune écriture disque.

var _config: DaycareConfig
## Pas comptés depuis la création (journal de QA, tests).
var _counted: int = 0


func _init(config: DaycareConfig = null) -> void:
	_config = config


## Un pas du joueur vient de finir. Compté seulement si l'entrée était libre ([param input_enabled]
## faux : pas scripté d'une scène, d'un recul de garde…). Renvoie l'XP mise en attente dans
## [param daycare] (0 : pas ignoré, Pension vide ou plafond du niveau 100 atteint).
func on_player_moved(daycare: Daycare, input_enabled: bool) -> int:
	if not input_enabled or daycare == null or daycare.is_empty():
		return 0
	_counted += 1
	return daycare.add_steps(1, _config)


## Pas comptés (entrée libre, Pension occupée).
func counted() -> int:
	return _counted
