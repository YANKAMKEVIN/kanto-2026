class_name FishingRules
extends RefCounted
## Règles pures de la pêche (jalon 22 §2.5, dossier 25 §7) : meilleure canne, chance de
## touche, table à utiliser, tirage complet. Statique, sans état ni dépendance à l'arbre.
##
## Ordre des tirages de [method roll], pour la reproductibilité : chance(touche, 100), puis
## (si ça mord) [method EncounterTable.pick] (poids, puis niveau). Aucun tirage sans canne ou
## sans table.
## [b]Provisoire (T3 → T12).[/b] Les tables viennent de [WaterRodTables] et non de
## [EncounterLibrary] (voir ce fichier) ; T12 changera le type du paramètre « tables ».

## Cannes, de la moins bonne à la meilleure (identifiants d'objets du Sac).
const RODS: Array[StringName] = [&"old_rod", &"good_rod", &"super_rod"]
## Chance de touche par canne, en % (dossier 25 §7.4 : 100 / 50 / 75 [D]).
const BITE_CHANCE: Dictionary[StringName, int] = {
	&"old_rod": 100, &"good_rod": 50, &"super_rod": 75,
}


## Meilleure canne présente dans [param bag], ou &"" (M-9 : la meilleure est utilisée).
static func best_rod(bag: Bag) -> StringName:
	if bag == null:
		return &""
	for i: int in range(RODS.size() - 1, -1, -1):
		if bag.has(RODS[i]):
			return RODS[i]
	return &""


## Chance de touche de [param rod], en % (0 pour une canne inconnue ou &"").
static func bite_chance(rod: StringName) -> int:
	return BITE_CHANCE.get(rod, 0)


## Table à utiliser : propre à [param map_id] s'il y en a une (Méga Canne à Parmanie), sinon
## la table globale ou par défaut de la canne ; null sans canne ou sans table.
static func table_for(tables: WaterRodTables, rod: StringName,
		map_id: StringName) -> EncounterTable:
	if tables == null or not RODS.has(rod):
		return null
	return tables.get_table(rod, map_id)


## Tirage complet d'une pêche : touche ou non, puis rencontre. null si rien ne mord, sans
## canne ou sans table (dans ces deux derniers cas, aucun tirage n'est fait).
static func roll(rng: GameRng, tables: WaterRodTables, rod: StringName,
		map_id: StringName) -> WildEncounter:
	var table := table_for(tables, rod, map_id)
	if table == null:
		return null
	if not rng.chance(bite_chance(rod), 100):
		return null
	return table.pick(rng)
