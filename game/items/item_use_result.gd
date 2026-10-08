class_name ItemUseResult
extends RefCounted
## Ce qu'a donné l'usage d'un objet sur un Pokémon ([method ItemUse.apply]). Donnée pure.
##
## Si [member check] n'est pas [constant ItemUse.Check.OK], rien n'a changé : les PV d'avant et
## d'après sont égaux, [member remaining] est la quantité inchangée du Sac.

var check: ItemUse.Check = ItemUse.Check.NOT_USABLE
var item_id: StringName = &""
var hp_before: int = 0
var hp_after: int = 0
var max_hp: int = 0
## Exemplaires restant dans le Sac après l'usage (UTILISER À NOUVEAU possible si > 0).
var remaining: int = 0
## Statut soigné par l'objet ([constant StatusRules.NONE] : aucun ; jalon 9, l'Antidote).
var status_cured: StringName = StatusRules.NONE
## Sexe du Pokémon (accord du résultat : « … n'est plus empoisonnée. »).
var gender: Pokemon.Gender = Pokemon.Gender.NONE


## Vrai si l'objet a servi (un exemplaire en moins, effet appliqué).
func is_ok() -> bool:
	return check == ItemUse.Check.OK


## PV rendus (0 si rien n'a changé).
func amount() -> int:
	return hp_after - hp_before
