class_name MetronomeRules
extends RefCounted
## Métronome (jalon 24, T13 ; dossier 27 §10.6, `jalon-24.md` §2.8) : pur. Tirage uniforme parmi
## les capacités du jeu dont l'effet est implémenté, sauf Métronome, Lutte et celles qui ont des
## `pending_effects`. Écartées aussi [D] : les capacités qui occupent plusieurs tours ou visent
## l'emplacement de la capacité (charge, Patience, repos forcé, piège, Entrave, Téléport) : RB les
## permet, mais le moteur les rattache à l'emplacement joué.

const EXCLUDED_IDS: Array[StringName] = [&"metronome", &"struggle"]
const EXCLUDED_KINDS: Array[MoveEffect.Kind] = [MoveEffect.Kind.CHARGE, MoveEffect.Kind.BIDE,
	MoveEffect.Kind.RECHARGE, MoveEffect.Kind.TRAP, MoveEffect.Kind.DISABLE,
	MoveEffect.Kind.TELEPORT, MoveEffect.Kind.METRONOME]


## Capacités que Métronome peut tirer, dans l'ordre des données.
static func candidates(data: PokemonData) -> Array[MoveData]:
	var result: Array[MoveData] = []
	for id: StringName in data.get_move_ids():
		var move := data.get_move(id)
		if move == null or EXCLUDED_IDS.has(id) or not move.pending_effects.is_empty():
			continue
		var excluded := false
		for effect: MoveEffect in move.effects:
			if EXCLUDED_KINDS.has(effect.kind):
				excluded = true
		if not excluded:
			result.append(move)
	return result


## Une capacité tirée par [param rng] (null : aucune candidate).
static func pick(data: PokemonData, rng: GameRng) -> MoveData:
	var pool := candidates(data)
	if pool.is_empty():
		return null
	return pool[rng.pick_index(pool.size())]
