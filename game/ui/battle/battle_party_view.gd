class_name BattlePartyView
extends RefCounted
## Un Pokémon de l'équipe dans le panneau ÉQUIPE du combat (BattlePartyPanel, jalon 7,
## jalon-07.md §15.23) : des chaînes et des entiers, rien d'autre. Le panneau ne connaît ni le
## moteur ni les données ; le directeur du combat la fait remplir.

## Place dans l'équipe (0 = en tête) : celle qu'émet le panneau quand on l'envoie.
var party_index: int = 0
var species_id: StringName = &""
## Surnom, sinon nom de l'espèce.
var display_name: String = ""
var level: int = 1
var hp: int = 1
var max_hp: int = 1
## Types (identifiants, pour la couleur et l'icône) et leurs noms affichés, dans l'ordre.
var type_ids: Array[StringName] = []
var type_names: PackedStringArray = PackedStringArray()
## Statut écrit en toutes lettres (« K.O. »), vide sinon.
var status_text: String = ""
## Le Pokémon en jeu (« ACTIF »).
var active: bool = false
## Il peut être envoyé maintenant.
var can_send: bool = false
## Sinon, la raison, courte (« Déjà au combat », « Ne peut plus combattre »).
var reason: String = ""


## Vue affichable : un nom, un niveau ≥ 1, 0 ≤ PV ≤ PV max, PV max ≥ 1.
func is_valid() -> bool:
	return not display_name.is_empty() and level >= 1 and max_hp >= 1 \
		and hp >= 0 and hp <= max_hp
