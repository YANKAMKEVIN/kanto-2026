extends RefCounted
## Aides des tests de sauvegarde pour la v10 (Chapitre Johto, JOH0, `jalon-joh0.md` §2.1).
##
## Utilisation : [code]const SaveV10 := preload("res://tests/helpers/save_v10.gd")[/code].
## La migration 9 → 10 donne « bond » = [constant SaveSystem.V10_MIGRATED_BOND] à chaque Pokémon
## de l'équipe, du Stockage et de la Pension qui n'en a pas : c'est le **seul** champ qu'une
## sauvegarde d'avant la v10 gagne à la lecture (en plus des défauts des versions précédentes).
## Les tests « réécrite à l'identique » des jalons passés comparent donc à
## [method with_migrated_bond] de leur fixture.


## Copie profonde de [param content] où chaque Pokémon de « party », « storage » et
## « daycare.pokemon » sans « bond » reçoit le lien de migration.
static func with_migrated_bond(content: Dictionary) -> Dictionary:
	var result := content.duplicate(true)
	for key: String in ["party", "storage"]:
		var members: Variant = result.get(key)
		if members is Array:
			for member: Variant in members:
				_give(member)
	var daycare: Variant = result.get("daycare")
	if daycare is Dictionary:
		_give((daycare as Dictionary).get("pokemon"))
	return result


static func _give(member: Variant) -> void:
	if member is Dictionary and not (member as Dictionary).has("bond"):
		(member as Dictionary)["bond"] = SaveSystem.V10_MIGRATED_BOND
