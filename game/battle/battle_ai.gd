class_name BattleAI
extends RefCounted
## Choix d'action des camps non joueurs (jalon 4 §2.2, dossier 05 §19, dossier 09 §14). Classe
## pure. Une IA par combat ([method TrainerData.make_ai]) : « smart » y compte ses statuts.
##
## [b]random[/b] (rival du labo, jalon 4) : une capacité au hasard parmi celles qui ont des PP
## (un tirage pick_index), Lutte sinon (aucun tirage). Le rival débutant « fait des erreurs ».
##
## [b]smart[/b] (IA de niveau 2, rival de la Route 22, jalon-07.md §3.8) : chaque capacité qui a
## des PP reçoit une note ([method score_move]) ; une note nulle = capacité inutile.
## 1. Une capacité inutile (attaque sans effet ×0, statut déjà au maximum, statut usé, statut
##    sous ⅓ des PV) n'est jamais choisie s'il existe une autre option.
## 2. S'il existe une attaque super efficace utile, seules les attaques super efficaces sont
##    candidates (elle l'emporte sur toute attaque neutre, et sur les statuts).
## 3. Sinon, la meilleure note l'emporte ; une capacité de statut utile vaut
##    [constant STATUS_SCORE] × précision (une attaque neutre de puissance 40 sans bonus de
##    type : à égalité avec Charge, derrière Tornade d'un Roucool).
## 4. Égalité entre les meilleures : un tirage pick_index parmi elles (aucun tirage s'il n'y en
##    a qu'une). Toutes inutiles : tirage parmi toutes. Sans PP : Lutte, aucun tirage.
## Sans [PokemonData] ([param data] nul dans [method choose]), « smart » se comporte comme
## « random ».

const RANDOM: StringName = &"random"
const SMART: StringName = &"smart"
## Noms d'IA reconnus dans les données des dresseurs.
const KINDS: Array[StringName] = [RANDOM, SMART]
## Une capacité de statut n'est plus choisie après ce nombre d'usages par le même Pokémon dans
## le combat (« n'abuse pas », dossier 09 §14).
const STATUS_MAX_USES: int = 2
## Sous cette part de ses PV, plus aucune capacité de statut (« plus agressif quand il est
## faible »).
const LOW_HP_RATIO: float = 1.0 / 3.0
## Note d'une capacité de statut utile, avant la précision (défaut, jalon-07.md §15).
const STATUS_SCORE: float = 40.0
## Bonus de type (STAB).
const STAB: float = 1.5

var kind: StringName = RANDOM
## « smart » : capacités de statut choisies, par Pokémon (identifiant d'instance) puis capacité.
var _status_uses: Dictionary[int, Dictionary] = {}


func _init(ai_kind: StringName = RANDOM) -> void:
	kind = ai_kind


static func is_known(ai_kind: StringName) -> bool:
	return KINDS.has(ai_kind)


## Action du camp [param own] contre [param foe]. [param data] : capacités et table des types
## (null : comportement « random », quel que soit [member kind]).
func choose(own: BattleSide, foe: BattleSide, rng: GameRng,
		data: PokemonData = null) -> BattleAction:
	var usable := own.active.usable_moves()
	if usable.is_empty():
		return BattleAction.move(BattleAction.STRUGGLE)
	if kind != SMART or data == null or foe == null or foe.active == null:
		return BattleAction.move(usable[rng.pick_index(usable.size())])
	var index := _choose_smart(own.active, foe.active, usable, rng, data)
	var move := data.get_move(own.active.pokemon.moves[index].move_id)
	if move != null and not move.is_damaging():
		var uses := _uses_of(own.active.pokemon)
		uses[move.id] = int(uses.get(move.id, 0)) + 1
	return BattleAction.move(index)


## Nombre de fois où « smart » a choisi la capacité [param move_id] pour [param pokemon] dans
## ce combat (seules les capacités de statut sont comptées).
func times_used(pokemon: Pokemon, move_id: StringName) -> int:
	return int(_uses_of(pokemon).get(move_id, 0))


## Note d'une capacité pour l'IA « smart » (0 = inutile). Attaque : puissance × bonus de type ×
## efficacité × précision (une capacité qui ne rate jamais compte 100 %). Statut :
## [constant STATUS_SCORE] × précision, ou 0 si [param own] est sous ⅓ de ses PV, si
## [param times_used] ≥ [constant STATUS_MAX_USES], ou si aucun de ses effets ne peut plus rien
## changer (niveau déjà au bout, graine déjà plantée ou cible immunisée, effet que le moteur ne
## gère pas encore). Les capacités de statut ignorent les types (comme le moteur).
static func score_move(move: MoveData, own: Battler, foe: Battler, chart: TypeChart,
		times_used: int) -> float:
	if move == null:
		return 0.0
	var accuracy := 1.0 if move.never_misses() else move.accuracy / 100.0
	if move.is_damaging():
		var effectiveness := effectiveness_of(move, foe, chart)
		var stab := STAB if not move.typeless and own.types.has(move.type) else 1.0
		return move.power * stab * effectiveness * accuracy
	if is_low(own) or times_used >= STATUS_MAX_USES or not status_has_effect(move, own, foe):
		return 0.0
	return STATUS_SCORE * accuracy


## Efficacité de [param move] sur [param foe] (1 pour une capacité sans type).
static func effectiveness_of(move: MoveData, foe: Battler, chart: TypeChart) -> float:
	if move.typeless:
		return 1.0
	return chart.multiplier(move.type, foe.types)


## Vrai si [param battler] est sous ⅓ de ses PV.
static func is_low(battler: Battler) -> bool:
	var max_hp := battler.pokemon.max_hp()
	return max_hp > 0 and float(battler.pokemon.hp) < max_hp * LOW_HP_RATIO


## Vrai si au moins un effet de la capacité de statut [param move] peut encore changer quelque
## chose (un niveau pas au bout dans le bon sens, une graine qui prendrait).
static func status_has_effect(move: MoveData, own: Battler, foe: Battler) -> bool:
	for effect: MoveEffect in move.effects:
		match effect.kind:
			MoveEffect.Kind.STAT_STAGE:
				var target := own if effect.target == MoveEffect.Target.SELF else foe
				var stage := target.get_stage(effect.stat)
				if (effect.stages > 0 and stage < Battler.STAGE_MAX) \
						or (effect.stages < 0 and stage > Battler.STAGE_MIN):
					return true
			MoveEffect.Kind.SEED:
				if not foe.is_seeded() and not foe.has_any_type(effect.immune_types):
					return true
	return false


func _choose_smart(own: Battler, foe: Battler, usable: Array[int], rng: GameRng,
		data: PokemonData) -> int:
	var chart := data.get_type_chart()
	var scores: Array[float] = []
	var super_effective := false
	for index: int in usable:
		var move := data.get_move(own.pokemon.moves[index].move_id)
		var score := score_move(move, own, foe, chart,
			times_used(own.pokemon, move.id) if move != null else 0)
		scores.append(score)
		if score > 0.0 and move.is_damaging() and effectiveness_of(move, foe, chart) > 1.0:
			super_effective = true
	var best := 0.0
	var candidates: Array[int] = []
	for i: int in usable.size():
		var move := data.get_move(own.pokemon.moves[usable[i]].move_id)
		if super_effective and (scores[i] <= 0.0 or not move.is_damaging()
				or effectiveness_of(move, foe, chart) <= 1.0):
			continue
		if scores[i] > best:
			best = scores[i]
			candidates.clear()
		if scores[i] == best:
			candidates.append(usable[i])
	if candidates.size() == 1:
		return candidates[0]
	return candidates[rng.pick_index(candidates.size())]


func _uses_of(pokemon: Pokemon) -> Dictionary:
	var key := pokemon.get_instance_id()
	if not _status_uses.has(key):
		_status_uses[key] = {}
	return _status_uses[key]
