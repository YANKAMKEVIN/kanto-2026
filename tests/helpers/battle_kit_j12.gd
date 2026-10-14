extends RefCounted
## Outils communs des tests du moteur de combat du jalon 12 (T13) : Pokémon aux capacités
## choisies (IV 0), combats à aléatoire imposé, recherche d'événements.
## Utilisation : [code]const Kit := preload("res://tests/helpers/battle_kit_j12.gd")[/code].

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const IV_0: Array[int] = [1, 1, 1, 1, 1, 1, 1]
## Un coup qui touche, sans critique, aléatoire à 100 % (précision, critique, aléatoire).
const HIT: Array[int] = [50, 2, 16]


## Pokémon [param species] au niveau [param level] (IV 0) qui connaît [param moves] seulement.
static func mon(data: PokemonData, species: StringName, level: int, moves: Array) -> Pokemon:
	var pokemon := PokemonFactory.create(data, species, level, ScriptedRng.new(IV_0))
	pokemon.moves.clear()
	for move_id: Variant in moves:
		pokemon.moves.append(MoveSlot.new(StringName(move_id),
			data.get_move(StringName(move_id)).pp))
	return pokemon


## Combat lancé ([method Battle.start]) : [param mine] contre [param foes] ; [param trainer] vide =
## sauvage. [param rules] null = règles sauvages.
static func battle(data: PokemonData, rng: GameRng, mine: Array, foes: Array,
		trainer: String = "", rules: BattleRules = null) -> Battle:
	var party := Party.new()
	for pokemon: Pokemon in mine:
		party.add(pokemon)
	var foe_party := Party.new()
	for pokemon: Pokemon in foes:
		foe_party.add(pokemon)
	var result := Battle.new(BattleSide.new(party, true), BattleSide.new(foe_party, false,
		trainer), data, rng, rules if rules != null else BattleRules.for_wild())
	result.start()
	return result


## Tirages mis à plat (des nombres et des listes de nombres).
static func draws(parts: Array) -> Array[int]:
	var result: Array[int] = []
	for part: Variant in parts:
		if part is Array:
			for value: int in part:
				result.append(value)
		else:
			result.append(int(part))
	return result


## Premier événement [param kind] (du camp [param side] si ≥ 0), ou null.
static func find(events: Array[BattleEvent], kind: BattleEvent.Kind,
		side: int = -1) -> BattleEvent:
	for event: BattleEvent in events:
		if event.kind == kind and (side < 0 or event.side == side):
			return event
	return null


## Nombre d'événements [param kind].
static func count(events: Array[BattleEvent], kind: BattleEvent.Kind) -> int:
	var total := 0
	for event: BattleEvent in events:
		if event.kind == kind:
			total += 1
	return total


## Sortes et camps (« MOVE_USED », « PLAYER »), sans TURN_STARTED.
static func kinds(events: Array[BattleEvent]) -> Array:
	var result: Array = []
	for event: BattleEvent in events:
		if event.kind != BattleEvent.Kind.TURN_STARTED:
			result.append([BattleEvent.Kind.find_key(event.kind),
				BattleEvent.SideId.find_key(event.side)])
	return result


## Rang du premier événement [param kind] (−1 s'il n'y en a pas).
static func index_of(events: Array[BattleEvent], kind: BattleEvent.Kind,
		side: int = -1) -> int:
	for i: int in events.size():
		if events[i].kind == kind and (side < 0 or events[i].side == side):
			return i
	return -1
