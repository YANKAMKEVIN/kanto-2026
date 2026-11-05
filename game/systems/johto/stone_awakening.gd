class_name StoneAwakening
extends RefCounted
## Le Réveil : le pouvoir des trois pierres de l'arc de Johto (dossier JOH-11 §13, JH-66 à JH-69 ;
## `jalon-joh-pierres.md` §2). Classe statique et pure, sur le modèle de [TeamConfiscation] : elle
## reçoit l'état de partie (l'autoload GameState en jeu, une instance de `game_state.gd` en test),
## les zones et les données ; aucune scène, aucun écran, aucune écriture disque.
##
## **Une seule opération synchrone** ([method awaken]) : niveaux, évolutions, Pokédex, objets clés
## et [constant AWAKENED] changent dans le même appel, rien n'est `await`é au milieu. L'état en
## mémoire est donc toujours entièrement « avant » ou entièrement « après » ; l'étape de scène
## écrit ensuite d'un coup (`stones_awaken`, [CutsceneDirector]) : application tuée avant
## l'écriture, le fichier est « avant » et la scène reprend à l'autel ; après, il est « après »
## et la scène reprend à Cenere (dossier §15).
##
## - Cible ([method target_level]) : moyenne arrondie des trois plus hauts niveaux de l'équipe de
##   Kanto confisquée, bornée à [constant LEVEL_MIN]–[constant LEVEL_MAX] (JH-66).
## - Qui ([method eligible]) : l'équipe, puis les captures du Stockage rencontrées à Johto (JH-67) ;
##   ni œuf, ni niveau ≥ cible : jamais de baisse.
## - Effet ([method apply]) : niveau = cible, XP au minimum du niveau, chaîne d'évolutions entière
##   sans annulation (JH-69), PV et PP pleins, statut retiré. Le lien ne bouge pas.
## - Attaques : rien n'est appris ici. [member AwakeningResult.new_moves] propose les
##   [constant OFFERED_MOVES] plus récentes **[D]** ; le Stockage reçoit d'office les
##   4 dernières de l'apprentissage **[D]** ([method apply_stored]).

## Levé par [method awaken], jamais baissé : le Réveil n'a lieu qu'une fois (JH-68).
const AWAKENED: StringName = &"johto_stones_awakened"
## Objets clés retirés du Sac au Réveil (`data/items/items_johp.json`, JOHP1). La Pierre Marée
## n'y entre jamais en jeu (JH-62) : elle est ici pour les départs de débogage.
const STONES: Array[StringName] = [&"stone_memory", &"stone_tide", &"stone_breath"]
## Bornes de la cible (JH-66) et nombre de niveaux moyennés.
const LEVEL_MIN: int = 55
const LEVEL_MAX: int = 62
const TOP_LEVELS: int = 3
## Attaques proposées par Pokémon à l'écran du Réveil **[D]**.
const OFFERED_MOVES: int = 3
## Titre de la ligne d'un Pokémon qui a évolué, à l'écran du Réveil **[D]**.
const EVOLVED_TITLE: String = "%s → %s"
## Garde-fou de la chaîne d'évolutions (les données n'en ont pas de plus longue que 2).
const MAX_CHAIN: int = 4


## Vrai si le Réveil a déjà eu lieu.
static func is_done(flags: StoryFlags) -> bool:
	return flags != null and flags.has_flag(AWAKENED)


## Niveau visé : moyenne arrondie des [constant TOP_LEVELS] plus hauts niveaux de
## [param confiscated] (moins s'il y en a moins ; un œuf ne compte pas), bornée. Équipe vide :
## [constant LEVEL_MIN].
static func target_level(confiscated: ConfiscatedTeam) -> int:
	var levels: Array[int] = []
	if confiscated != null:
		for pokemon: Pokemon in confiscated.party:
			if not pokemon.is_egg():
				levels.append(pokemon.level)
	if levels.is_empty():
		return LEVEL_MIN
	levels.sort()
	levels.reverse()
	var top := levels.slice(0, TOP_LEVELS)
	var total := 0
	for level: int in top:
		total += level
	return clampi(roundi(float(total) / float(top.size())), LEVEL_MIN, LEVEL_MAX)


## Pokémon concernés : ceux de l'équipe, puis ceux du Stockage (dans leur ordre).
static func eligible(state: Node, zones: ZoneLibrary) -> Array[Pokemon]:
	var target := target_level(state.confiscated)
	var result := _eligible_party(state, target)
	result.append_array(_eligible_stored(state, zones, target))
	return result


## Monte [param pokemon] à [param target] : voir la classe. Sans effet ni bilan (null) si
## [param pokemon] est un œuf, déjà à la cible ou d'une espèce inconnue.
static func apply(pokemon: Pokemon, target: int, data: PokemonData) -> AwakeningResult:
	if pokemon == null or data == null or pokemon.is_egg() or pokemon.level >= target:
		return null
	var species := data.get_species(pokemon.species_id)
	if species == null:
		push_error("StoneAwakening : espèce inconnue « %s »" % pokemon.species_id)
		return null
	var result := AwakeningResult.new()
	result.pokemon = pokemon
	result.level_before = pokemon.level
	result.level_after = target
	result.species_before = pokemon.species_id
	pokemon.level = target
	pokemon.experience = ExpCurve.exp_for_level(species.growth_rate, target)
	# Attaques rencontrées en route : [niveau, attaque], pour chaque tronçon de la chaîne.
	var offers: Array[Array] = []
	var reached := result.level_before
	var first := reached + 1
	for _i: int in MAX_CHAIN:
		var into := Evolution.level_up_target(pokemon, data)
		if into.is_empty() or not data.has_species(into):
			break
		var at := _stage_level(data.get_species(pokemon.species_id), into, reached, target)
		_collect(data.get_species(pokemon.species_id), first, at, offers)
		Evolution.evolve(pokemon, into, data)
		result.chain.append(into)
		result.stage_levels.append(at)
		reached = at
		first = at # L'espèce nouvelle apprend aussi au niveau de son évolution.
	_collect(data.get_species(pokemon.species_id), first, target, offers)
	result.new_moves = _latest(offers, pokemon)
	result.title = pokemon.display_name(data) if result.chain.is_empty() else EVOLVED_TITLE % [
		species.name, data.get_species(pokemon.species_id).name]
	pokemon.recalc(data)
	pokemon.heal_full()
	return result


## Comme [method apply], pour une capture du Stockage : pas de choix à l'écran, ses 4 capacités
## deviennent les dernières de l'apprentissage **[D]** (PP pleins).
static func apply_stored(pokemon: Pokemon, target: int, data: PokemonData) -> AwakeningResult:
	var result := apply(pokemon, target, data)
	if result == null:
		return null
	result.stored = true
	result.new_moves.clear()
	var moves := data.get_species(pokemon.species_id).moves_at(target)
	if not moves.is_empty():
		pokemon.moves.clear()
		for move_id: StringName in moves:
			pokemon.learn_move(move_id, data)
	return result


## Le Réveil, d'un seul bloc. Null, et rien ne change, s'il a déjà eu lieu. Sinon le bilan ; un
## bilan vide ([method AwakeningReport.has_scene] faux) lève quand même le drapeau et retire les
## pierres (dossier §15 : « le réveil se joue sans écran »).
static func awaken(state: Node, zones: ZoneLibrary, data: PokemonData) -> AwakeningReport:
	var flags: StoryFlags = state.flags
	if is_done(flags):
		return null
	var report := AwakeningReport.new()
	report.target = target_level(state.confiscated)
	var party := _eligible_party(state, report.target)
	var stored := _eligible_stored(state, zones, report.target)
	for pokemon: Pokemon in party:
		var result := apply(pokemon, report.target, data)
		if result != null:
			result.party_index = (state.party as Party).index_of(pokemon)
			report.party.append(result)
	for pokemon: Pokemon in stored:
		var result := apply_stored(pokemon, report.target, data)
		if result != null:
			report.stored.append(result)
	for result: AwakeningResult in report.party + report.stored:
		for species: StringName in result.chain:
			state.record_evolved(species)
	for pokemon: Pokemon in (state.party as Party).get_all():
		if not pokemon.is_egg():
			report.line_up.append(pokemon)
	var bag: Bag = state.bag
	for stone: StringName in STONES:
		if bag.has(stone):
			bag.remove(stone, bag.count_of(stone))
	flags.set_flag(AWAKENED)
	return report


static func _eligible_party(state: Node, target: int) -> Array[Pokemon]:
	var result: Array[Pokemon] = []
	for pokemon: Pokemon in (state.party as Party).get_all():
		if not pokemon.is_egg() and pokemon.level < target:
			result.append(pokemon)
	return result


static func _eligible_stored(state: Node, zones: ZoneLibrary, target: int) -> Array[Pokemon]:
	var result: Array[Pokemon] = []
	if zones == null:
		return result
	for pokemon: Pokemon in (state.storage as PokemonStorage).get_all():
		if not pokemon.is_egg() and pokemon.level < target and not pokemon.met_map.is_empty() \
				and zones.is_johto(pokemon.met_map):
			result.append(pokemon)
	return result


## Niveau du palier de l'évolution de [param species] vers [param into] : celui de la règle
## « level » ; une évolution en retard ou sans niveau (lien) tombe au niveau suivant
## [param reached] : le compteur monte toujours. Jamais au-delà de [param target].
static func _stage_level(species: SpeciesData, into: StringName, reached: int,
		target: int) -> int:
	var at := reached + 1
	for rule: EvolutionRule in species.evolutions:
		if rule.into == into and rule.method == EvolutionRule.Method.LEVEL:
			at = maxi(rule.level, at)
			break
	return mini(at, target)


## Ajoute à [param offers] les attaques de [param species] apprises de [param from] à [param to].
static func _collect(species: SpeciesData, from: int, to: int, offers: Array[Array]) -> void:
	for entry: Array in species.learnset:
		var level := int(entry[0])
		if level >= from and level <= to:
			offers.append([level, entry[1]])


## Les [constant OFFERED_MOVES] attaques les plus récentes de [param offers] que [param pokemon]
## ne connaît pas, sans doublon (une attaque retrouvée plus haut garde son niveau le plus haut),
## de la plus ancienne à la plus récente.
static func _latest(offers: Array[Array], pokemon: Pokemon) -> Array[StringName]:
	var result: Array[StringName] = []
	for i: int in range(offers.size() - 1, -1, -1):
		var move_id: StringName = offers[i][1]
		if result.size() < OFFERED_MOVES and not result.has(move_id) \
				and not pokemon.knows_move(move_id):
			result.push_front(move_id)
	return result
