class_name EvolutionReveal
extends RefCounted
## Ce que la fiche Équipe dit de la lignée d'une espèce, sans rien révéler (jalon-06.md §3.3,
## Q-9 verrouillée ; dossier 08 §2). Classe pure, statique ; réutilisable par le Pokédex (6C).
##
## Règles (Q-9) :
## - lignée d'une seule espèce → aucune section (liste vide) ;
## - Pokédex non visible (avant son activation au J7A) → un seul stade « ??? » ;
## - Pokédex visible → seulement ce que le joueur a découvert : l'espèce de la fiche et les
##   espèces **vues** de la lignée, à leur place. Une colonne sans espèce vue, entre deux
##   colonnes connues, est un « ??? » ; après la dernière colonne connue, **un seul** « ??? »
##   s'il reste des stades (jamais leur nombre). Dans une colonne qui a une espèce vue, les
##   branches inconnues sont tues.
## - jamais de condition (niveau, objet), ni de nom ou d'espèce d'un stade inconnu ;
## - un stade inconnu porte le numéro de son espèce pour la **silhouette** du Pokédex (Q-1 de
##   Kevin, 2026-10-06) s'il en désigne une seule ; une colonne de branches toutes inconnues
##   (un seul « ??? ») et la lignée d'avant l'activation n'en ont pas (0) : montrer une forme
##   trahirait le nombre de branches ou choisirait l'une d'elles.

## Séparateurs de [method text].
const STEP_SEPARATOR: String = " → "
const BRANCH_SEPARATOR: String = " / "
## Garde-fou contre une donnée cyclique.
const _MAX_STEPS: int = 8


## Stades à afficher pour [param species_id] (voir les règles en tête de fichier).
## [param pokedex_visible] : [method MenuUnlocks.pokedex_visible].
static func chain(species_id: StringName, data: PokemonData, pokedex: Pokedex,
		pokedex_visible: bool) -> Array[EvolutionStageView]:
	var stages: Array[EvolutionStageView] = []
	var columns := family(species_id, data)
	var count := 0
	for column: Array in columns:
		count += column.size()
	if count <= 1:
		return stages
	if not pokedex_visible:
		stages.append(EvolutionStageView.new(0))
		return stages
	var known_columns: Array[Array] = []
	var last_known := -1
	for step: int in columns.size():
		var known: Array[StringName] = []
		for id: StringName in columns[step]:
			if id == species_id or (pokedex != null and pokedex.is_seen(id)):
				known.append(id)
		known_columns.append(known)
		if not known.is_empty():
			last_known = step
	for step: int in last_known + 1:
		if known_columns[step].is_empty():
			stages.append(_unknown_stage(step, columns[step], data))
			continue
		for id: StringName in known_columns[step]:
			var species := data.get_species(id)
			stages.append(EvolutionStageView.new(step, id, species.name, id == species_id,
				species.dex))
	if last_known < columns.size() - 1:
		stages.append(_unknown_stage(last_known + 1, columns[last_known + 1], data))
	return stages


## Une ligne : colonnes séparées par « → », branches par « / » (« Salamèche → ??? »).
static func text(stages: Array[EvolutionStageView]) -> String:
	var result := ""
	var step := -1
	for stage: EvolutionStageView in stages:
		if not result.is_empty():
			result += BRANCH_SEPARATOR if stage.step == step else STEP_SEPARATOR
		result += stage.name
		step = stage.step
	return result


## Lignée complète de [param species_id] en colonnes (0 = forme de base), espèces de chaque
## colonne dans l'ordre du Pokédex. Une espèce inconnue des données → vide. Donnée brute :
## à ne jamais afficher telle quelle (Q-9), passer par [method chain].
static func family(species_id: StringName, data: PokemonData) -> Array[Array]:
	var columns: Array[Array] = []
	if not data.has_species(species_id):
		return columns
	var parents := _parents(data)
	var root := species_id
	var guard := 0
	while parents.has(root) and guard < _MAX_STEPS:
		root = parents[root]
		guard += 1
	var seen: Dictionary[StringName, bool] = {root: true}
	var column: Array[StringName] = [root]
	while not column.is_empty() and columns.size() < _MAX_STEPS:
		columns.append(column)
		var next: Array[StringName] = []
		for id: StringName in column:
			for rule: EvolutionRule in data.get_species(id).evolutions:
				if data.has_species(rule.into) and not seen.has(rule.into):
					seen[rule.into] = true
					next.append(rule.into)
		next.sort_custom(func(a: StringName, b: StringName) -> bool:
			return data.get_species(a).dex < data.get_species(b).dex)
		column = next
	return columns


## Stade inconnu de la colonne [param step] : le numéro (silhouette) seulement si la colonne
## n'a qu'une espèce.
static func _unknown_stage(step: int, column: Array, data: PokemonData) -> EvolutionStageView:
	var number := 0
	if column.size() == 1:
		number = data.get_species(column[0]).dex
	return EvolutionStageView.new(step, &"", EvolutionStageView.UNKNOWN_NAME, false, number)


## Espèce → celle dont elle évolue (la première trouvée, dans l'ordre du Pokédex).
static func _parents(data: PokemonData) -> Dictionary[StringName, StringName]:
	var parents: Dictionary[StringName, StringName] = {}
	for id: StringName in data.get_species_ids():
		for rule: EvolutionRule in data.get_species(id).evolutions:
			if not parents.has(rule.into) and rule.into != id:
				parents[rule.into] = id
	return parents
