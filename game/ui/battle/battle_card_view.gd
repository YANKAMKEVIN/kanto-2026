class_name BattleCardView
extends RefCounted
## Ce qu'affiche une carte d'information de combat (BattleInfoCard) : des chaînes et des
## entiers, rien d'autre.
##
## Celui qui pilote l'interface la remplit à partir du combat ; la carte ne connaît ni les
## Pokémon ni les données. Nom seul, sans « ennemi » ni « du Rival » (jalon 4, décision 5).

## Sexe affiché à droite du nom (♂ bleu, ♀ rose, rien si sans sexe).
enum Gender { NONE, MALE, FEMALE }

## Nom affiché (« Carapuce » ; la carte le met en MAJUSCULES).
var display_name: String = ""
var gender: Gender = Gender.NONE
var level: int = 1
var hp: int = 1
var max_hp: int = 1
## PV chiffrés sous la barre (« 19 / 19 ») : côté joueur seulement (dossier 05 §5).
var show_hp_numbers: bool = false
## Statut durable du Pokémon (&"" = aucun) : la carte pose l'étiquette « PSN » ([StatusView]).
var status: StringName = StatusRules.NONE
## Niveau masqué (SPECTRE, jalon 19) : la carte écrit « Nv. ?? » et [member level] est ignoré.
var level_hidden: bool = false


func _init(
	name: String = "", sex: Gender = Gender.NONE, lvl: int = 1, current_hp: int = 1,
	maximum_hp: int = 1, numbers: bool = false
) -> void:
	display_name = name
	gender = sex
	level = lvl
	hp = current_hp
	max_hp = maximum_hp
	show_hp_numbers = numbers


## Vue affichable : un nom, un niveau ≥ 1 (ou masqué), 0 ≤ PV ≤ PV max, PV max ≥ 1.
func is_valid() -> bool:
	return not display_name.is_empty() and (level >= 1 or level_hidden) and max_hp >= 1 \
		and hp >= 0 and hp <= max_hp
