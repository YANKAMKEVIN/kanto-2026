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
## Jalon 12 (`jalon-12.md` §2.10) : Repos jamais à PV pleins (ni endormi), Entrave jamais si elle
## échouerait, Ligotage (piège) jamais sur une cible déjà piégée, Destruction et Explosion
## seulement à ¼ de ses PV ou moins ([constant SELF_KO_HP_RATIO]) : note nulle sinon.
## Sans [PokemonData] ([param data] nul dans [method choose]), « smart » se comporte comme
## « random ».
##
## [b]Changement de Pokémon[/b] (jalon 13, dossier 16 §14) : si [member can_switch] (donnée
## « switch » du Dresseur), [method choose] demande d'abord à [AiSwitchRule] s'il faut changer ;
## oui → [code]BattleAction.switch_to(place)[/code], au plus une fois par combat (une IA par
## combat). Aucun tirage : sans « switch », mêmes choix et mêmes tirages qu'avant.

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
## Jalon 12 : Destruction et Explosion seulement à ce quart de ses PV ou moins [D].
const SELF_KO_HP_RATIO: float = 0.25
## « Charge puis frappe » (jalon 14, Tunnel) : deux tours pour un coup, note × 0,5 [D].
const CHARGE_FACTOR: float = 0.5

var kind: StringName = RANDOM
## L'IA peut rappeler son Pokémon (donnée « switch » du Dresseur, [TrainerData]) ; jamais en
## combat sauvage (IA par défaut).
var can_switch: bool = false
## « smart » : capacités de statut choisies, par Pokémon (identifiant d'instance) puis capacité.
var _status_uses: Dictionary[int, Dictionary] = {}
## Le changement de ce combat a déjà eu lieu.
var _switched: bool = false


func _init(ai_kind: StringName = RANDOM, ai_can_switch: bool = false) -> void:
	kind = ai_kind
	can_switch = ai_can_switch


static func is_known(ai_kind: StringName) -> bool:
	return KINDS.has(ai_kind)


## Action du camp [param own] contre [param foe]. [param data] : capacités et table des types
## (null : comportement « random », quel que soit [member kind]).
func choose(own: BattleSide, foe: BattleSide, rng: GameRng,
		data: PokemonData = null) -> BattleAction:
	if can_switch and not _switched and data != null and foe != null and foe.active != null:
		var index := AiSwitchRule.pick(own, foe.active, data.get_type_chart(), data)
		if index != AiSwitchRule.STAY:
			_switched = true
			return BattleAction.switch_to(index)
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


## Vrai si l'IA a déjà changé de Pokémon dans ce combat.
func has_switched() -> bool:
	return _switched


## Nombre de fois où « smart » a choisi la capacité [param move_id] pour [param pokemon] dans
## ce combat (seules les capacités de statut sont comptées).
func times_used(pokemon: Pokemon, move_id: StringName) -> int:
	return int(_uses_of(pokemon).get(move_id, 0))


## Note d'une capacité pour l'IA « smart » (0 = inutile). Attaque : puissance × bonus de type ×
## efficacité × précision (une capacité qui ne rate jamais compte 100 %). Statut :
## [constant STATUS_SCORE] × précision, ou 0 si [param own] est sous ⅓ de ses PV, si
## [param times_used] ≥ [constant STATUS_MAX_USES], ou si aucun de ses effets ne peut plus rien
## changer (niveau déjà au bout, graine déjà plantée ou cible immunisée, statut déjà présent ou
## cible immunisée, effet que le moteur ne gère pas encore). Les capacités de statut ignorent les types (comme le moteur).
## Une capacité « charge puis frappe » (jalon 14) vaut × [constant CHARGE_FACTOR] ; Téléport
## n'a aucun effet utile ici : 0 (jamais choisi en combat de Dresseur).
static func score_move(move: MoveData, own: Battler, foe: Battler, chart: TypeChart,
		times_used: int) -> float:
	if move == null:
		return 0.0
	var accuracy := 1.0 if move.never_misses() else move.accuracy / 100.0
	if move.is_damaging():
		if not damaging_is_sensible(move, own, foe):
			return 0.0
		var effectiveness := effectiveness_of(move, foe, chart)
		var stab := STAB if not move.typeless and own.types.has(move.type) else 1.0
		var charge := CHARGE_FACTOR if move.charge_effect() != null else 1.0
		return move.power * stab * effectiveness * accuracy * charge
	if is_low(own) or times_used >= STATUS_MAX_USES or not status_has_effect(move, own, foe):
		return 0.0
	if move.effect_of(MoveEffect.Kind.OHKO) != null:
		# K.O. en un coup : immunité de type, précision selon les niveaux ([OhkoRules]).
		if effectiveness_of(move, foe, chart) == 0.0:
			return 0.0
		accuracy = OhkoRules.accuracy(move.accuracy, own.pokemon.level, foe.pokemon.level) / 100.0
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
## chose (un niveau pas au bout dans le bon sens, une graine qui prendrait, un statut durable
## qui prendrait : [method StatusRules.can_inflict]).
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
			MoveEffect.Kind.STATUS:
				if StatusRules.can_inflict(effect.status, foe.pokemon, foe.types) \
						== StatusRules.Inflict.OK:
					return true
			MoveEffect.Kind.CONFUSION:
				if not foe.is_confused():
					return true
			MoveEffect.Kind.CRIT_UP:
				if not own.focused:
					return true
			MoveEffect.Kind.FIXED_DAMAGE:
				return true
			MoveEffect.Kind.OHKO:
				# Passe systèmes 2 : jamais si elle échoue d'avance (niveau inférieur) [D].
				return OhkoRules.level_allows(own.pokemon.level, foe.pokemon.level)
			MoveEffect.Kind.FORCE_SWITCH:
				# Hurlement (jalon 19) : la réserve de la cible n'est pas connue ici [D].
				return true
			MoveEffect.Kind.DISABLE:
				if foe.last_move_slot >= 0 and not foe.has_disabled_move() \
						and not foe.is_biding():
					return true
			MoveEffect.Kind.REST:
				if own.pokemon.hp < own.pokemon.max_hp() \
						and own.pokemon.status != StatusRules.SLEEP:
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


## Jalon 12 : faux si l'attaque [param move] serait un mauvais choix malgré ses dégâts — piège
## sur une cible déjà piégée, Destruction / Explosion au-dessus d'¼ des PV de [param own] ;
## Dévorêve sur une cible qui ne dort pas (jalon 19).
static func damaging_is_sensible(move: MoveData, own: Battler, foe: Battler) -> bool:
	if move.effect_of(MoveEffect.Kind.TRAP) != null and foe.is_trapped():
		return false
	# Jalon 19 : Dévorêve rate sur une cible qui ne dort pas.
	if move.effect_of(MoveEffect.Kind.REQUIRES_SLEEP) != null \
			and foe.pokemon.status != StatusRules.SLEEP:
		return false
	if move.effect_of(MoveEffect.Kind.SELF_KO) != null:
		var max_hp := own.pokemon.max_hp()
		return max_hp > 0 and float(own.pokemon.hp) <= max_hp * SELF_KO_HP_RATIO
	return true
