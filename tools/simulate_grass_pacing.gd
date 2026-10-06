extends SceneTree
## Compare, sur un grand nombre de séries de pas d'herbe, l'ancien système de rencontres (taux
## fixe 25/256 à chaque pas) et le nouveau (taux qui monte avec les pas sans rencontre, clé
## « ramp » de `data/encounters/route_1.json`), plus quelques réglages voisins pour choisir.
## Utilise la vraie table de la carte (Route 1 par défaut) et le vrai
## `EncounterTable.roll(rng, quiet_steps)` : même boucle que `EncounterDirector` (compteur +1 sans rencontre, remis à zéro sur une
## rencontre). Une série = les pas d'herbe d'une rencontre à la suivante (le pas de la rencontre
## compte). Information pour Kevin, pas un seuil.
##
##   godot --headless --path . -s res://tools/simulate_grass_pacing.gd
##
## Variables d'environnement facultatives : SERIES (défaut 200000), SEED (défaut 2026),
## MAP (défaut route_1 ; route_22 au jalon 7, T21). Affiche aussi la part de chaque espèce
## et de chaque niveau tirés par la table (même tirage que le jeu).
##
##   MAP=route_22 godot --headless --path . -s res://tools/simulate_grass_pacing.gd

const DEFAULT_SERIES: int = 200000
const DEFAULT_SEED: int = 2026
const THRESHOLDS: Array[int] = [15, 20, 30]
## Réglages comparés en plus de l'ancien et du JSON : [from_step, max_steps].
const VARIANTS: Array[Vector2i] = [Vector2i(10, 20), Vector2i(12, 20), Vector2i(18, 20)]


func _init() -> void:
	var data: RefCounted = load("res://game/pokemon/pokemon_data.gd").new()
	if not data.load_dir():
		push_error("données Pokémon invalides")
		quit(1)
		return
	var library: RefCounted = load("res://game/pokemon/encounters/encounter_library.gd").new(data)
	if not library.load_dir():
		push_error("tables de rencontres invalides")
		quit(1)
		return
	var map_id := StringName(OS.get_environment("MAP")) if OS.has_environment("MAP") \
		else &"route_1"
	var table: RefCounted = library.get_table(map_id)
	if table == null:
		push_error("aucune table d'herbe pour la carte « %s »" % map_id)
		quit(1)
		return
	var series := int(OS.get_environment("SERIES")) if OS.has_environment("SERIES") \
		else DEFAULT_SERIES
	var seed_value := int(OS.get_environment("SEED")) if OS.has_environment("SEED") \
		else DEFAULT_SEED
	print("%s, taux de base %d/256, %d séries par réglage, graine %d" % [
		map_id, table.rate, series, seed_value])
	print("Écart de moyenne : par rapport à l'ancien système (taux fixe).\n")
	var json_from: int = table.ramp_from
	var json_max: int = table.ramp_max
	table.ramp_from = 0
	table.ramp_max = 0
	var old := _simulate(table, series, seed_value)
	_report("ANCIEN  taux fixe %d/256" % table.rate, old, old)
	table.ramp_from = json_from
	table.ramp_max = json_max
	_report("NOUVEAU (JSON) montée de %d à %d" % [json_from, json_max],
		_simulate(table, series, seed_value), old)
	for variant: Vector2i in VARIANTS:
		table.ramp_from = variant.x
		table.ramp_max = variant.y
		_report("variante      montée de %d à %d" % [variant.x, variant.y],
			_simulate(table, series, seed_value), old)
	table.ramp_from = json_from
	table.ramp_max = json_max
	_report_species(table, series, seed_value, data)
	quit()


## Longueurs de séries (nombre de pas d'herbe jusqu'à la rencontre) sur [param series] séries.
func _simulate(table: RefCounted, series: int, seed_value: int) -> PackedInt32Array:
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(seed_value)
	var lengths := PackedInt32Array()
	lengths.resize(series)
	for i: int in series:
		var quiet := 0
		while table.roll(rng, quiet) == null:
			quiet += 1
		lengths[i] = quiet + 1
	return lengths


## Part de chaque espèce et de chaque niveau sur [param count] rencontres tirées.
func _report_species(table: RefCounted, count: int, seed_value: int, data: RefCounted) -> void:
	var rng: RefCounted = load("res://game/systems/random/game_rng.gd").new(seed_value)
	var by_species: Dictionary[StringName, int] = {}
	var by_level: Dictionary[String, int] = {}
	for i: int in count:
		var quiet := 0
		var encounter: RefCounted = table.roll(rng, quiet)
		while encounter == null:
			quiet += 1
			encounter = table.roll(rng, quiet)
		by_species[encounter.species] = by_species.get(encounter.species, 0) + 1
		var key := "%s Nv. %d" % [encounter.species, encounter.level]
		by_level[key] = by_level.get(key, 0) + 1
	var line := "Espèces (%d rencontres) :" % count
	for species: StringName in by_species:
		line += "\n  %-10s %5.1f %%  (%s)" % [species,
			100.0 * by_species[species] / count, data.get_species(species).name]
	print(line)
	var keys: Array[String] = []
	keys.assign(by_level.keys())
	keys.sort()
	line = "Niveaux :"
	for key: String in keys:
		line += "\n  %-16s %5.1f %%" % [key, 100.0 * by_level[key] / count]
	print(line + "\n")


func _report(title: String, lengths: PackedInt32Array, baseline: PackedInt32Array) -> void:
	var sorted := lengths.duplicate()
	sorted.sort()
	var mean := _mean(lengths)
	var base_mean := _mean(baseline)
	var line := "%s\n  pas entre deux rencontres : moyenne %.2f (écart %+.1f %%), médiane %d, " \
		% [title, mean, (mean / base_mean - 1.0) * 100.0, sorted[sorted.size() / 2]]
	line += "maximum %d\n  probabilité de dépasser :" % sorted[sorted.size() - 1]
	for threshold: int in THRESHOLDS:
		var over := 0
		for length: int in lengths:
			if length > threshold:
				over += 1
		line += "  %d pas : %.2f %%" % [threshold, 100.0 * float(over) / float(lengths.size())]
	print(line + "\n")


func _mean(lengths: PackedInt32Array) -> float:
	var total := 0
	for length: int in lengths:
		total += length
	return float(total) / float(lengths.size())
