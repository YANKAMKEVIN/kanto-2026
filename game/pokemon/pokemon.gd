class_name Pokemon
extends RefCounted
## Un Pokémon de la partie (instance), jalon 4 §2.1 et décisions de Kevin du §8.
##
## Classe pure : elle ne connaît que des identifiants ; noms et valeurs viennent de
## [PokemonData], passé en paramètre. Création : [PokemonFactory]. Progression :
## [method gain_exp] (niveaux), [method learn_move] / [method replace_move] (4 capacités au
## maximum, le joueur choisit laquelle oublier), [method evolve_into] (évolution, voir
## [Evolution]). [method to_dict] / [method from_dict] préparent la sauvegarde.

enum Gender { NONE, MALE, FEMALE }
## Résultat de [method learn_move].
enum LearnResult {
	LEARNED, ## Appris dans un emplacement libre.
	ALREADY_KNOWN, ## Déjà connu : rien ne change.
	NEEDS_FORGET, ## Les 4 emplacements sont pris : rien ne change, au joueur de choisir.
	INVALID, ## Capacité inconnue (push_error) : rien ne change.
}

const GENDER_NAMES: Dictionary[String, Gender] = {
	"none": Gender.NONE, "male": Gender.MALE, "female": Gender.FEMALE,
}

var species_id: StringName = &""
## Surnom ; vide = nom de l'espèce.
var nickname: String = ""
var level: int = 1
var gender: Gender = Gender.NONE
var ivs: Dictionary[StringName, int] = {}
var evs: Dictionary[StringName, int] = {}
## Statistiques calculées ([method recalc]).
var stats: Dictionary[StringName, int] = {}
## PV courants.
var hp: int = 0
## XP totale (courbe de l'espèce, [ExpCurve]).
var experience: int = 0
## 1 à 4 capacités.
var moves: Array[MoveSlot] = []


## Nom affiché : le surnom, sinon le nom de l'espèce.
func display_name(data: PokemonData) -> String:
	if not nickname.is_empty():
		return nickname
	var species := data.get_species(species_id)
	return species.name if species != null else String(species_id)


func max_hp() -> int:
	return stats.get(&"hp", 0)


func is_fainted() -> bool:
	return hp <= 0


## Retire [param amount] PV (borné à 0). Renvoie les PV réellement perdus.
func take_damage(amount: int) -> int:
	var lost := clampi(amount, 0, hp)
	hp -= lost
	return lost


## PV et PP au maximum.
func heal_full() -> void:
	hp = max_hp()
	for slot: MoveSlot in moves:
		slot.restore()


## Recalcule les statistiques (niveau, espèce). Les PV perdus sont conservés : les PV
## courants suivent la variation des PV max ; un Pokémon K.O. le reste.
func recalc(data: PokemonData) -> void:
	var species := data.get_species(species_id)
	if species == null:
		push_error("Pokemon : espèce inconnue « %s »" % species_id)
		return
	var old_max := max_hp()
	stats = StatCalc.compute(species, level, ivs, evs)
	if hp > 0:
		hp = clampi(hp + max_hp() - old_max, 1, max_hp())


func knows_move(move_id: StringName) -> bool:
	return move_index(move_id) >= 0


## Emplacement de [param move_id], ou −1.
func move_index(move_id: StringName) -> int:
	for i: int in moves.size():
		if moves[i].move_id == move_id:
			return i
	return -1


## Apprend [param move_id] s'il reste un emplacement libre. Ne modifie rien sinon.
func learn_move(move_id: StringName, data: PokemonData) -> LearnResult:
	var move := data.get_move(move_id)
	if move == null:
		push_error("Pokemon : capacité inconnue « %s »" % move_id)
		return LearnResult.INVALID
	if knows_move(move_id):
		return LearnResult.ALREADY_KNOWN
	if moves.size() >= SpeciesData.MAX_MOVES:
		return LearnResult.NEEDS_FORGET
	moves.append(MoveSlot.new(move_id, move.pp))
	return LearnResult.LEARNED


## Oublie la capacité de l'emplacement [param slot_index] au profit de [param move_id]
## (PP pleins). Faux (rien ne change) si l'emplacement n'existe pas ou si la capacité est
## inconnue ou déjà connue.
func replace_move(slot_index: int, move_id: StringName, data: PokemonData) -> bool:
	var move := data.get_move(move_id)
	if move == null or slot_index < 0 or slot_index >= moves.size() or knows_move(move_id):
		push_error("Pokemon : remplacement refusé (emplacement %d, « %s »)" % [slot_index,
			move_id])
		return false
	moves[slot_index] = MoveSlot.new(move_id, move.pp)
	return true


## Ajoute [param amount] XP (plafonnée à l'XP du niveau 100) et monte les niveaux
## correspondants : statistiques recalculées, PV courants augmentés du gain de PV max.
## Renvoie un [LevelUp] par niveau gagné, avec les capacités à proposer ; aucune n'est
## apprise ici (la présentation décide, voir [method learn_move]).
func gain_exp(amount: int, data: PokemonData) -> Array[LevelUp]:
	var result: Array[LevelUp] = []
	var species := data.get_species(species_id)
	if species == null or amount <= 0:
		return result
	var rate := species.growth_rate
	experience = mini(experience + amount, ExpCurve.exp_for_level(rate, ExpCurve.MAX_LEVEL))
	while level < ExpCurve.MAX_LEVEL and experience >= ExpCurve.exp_for_level(rate, level + 1):
		var before := stats.duplicate()
		level += 1
		recalc(data)
		var step := LevelUp.new()
		step.level = level
		for move_id: StringName in species.moves_learned_at(level):
			if not knows_move(move_id):
				step.moves.append(move_id)
		for stat: StringName in SpeciesData.STATS:
			step.stat_gains[stat] = stats.get(stat, 0) - before.get(stat, 0)
		result.append(step)
	return result


## Devient l'espèce [param into] (évolution) : statistiques recalculées en conservant les
## PV perdus ; capacités, IV, EV, XP, niveau, sexe et surnom gardés. Faux si l'espèce
## n'existe pas.
func evolve_into(into: StringName, data: PokemonData) -> bool:
	if not data.has_species(into):
		push_error("Pokemon : évolution vers une espèce inconnue « %s »" % into)
		return false
	species_id = into
	recalc(data)
	return true


## État complet, prêt pour le JSON (future sauvegarde).
func to_dict() -> Dictionary:
	var move_list: Array[Dictionary] = []
	for slot: MoveSlot in moves:
		move_list.append(slot.to_dict())
	return {
		"species": String(species_id), "nickname": nickname, "level": level,
		"gender": GENDER_NAMES.find_key(gender), "exp": experience, "hp": hp,
		"ivs": _stats_to_dict(ivs), "evs": _stats_to_dict(evs), "moves": move_list,
	}


## Reconstruit un Pokémon écrit par [method to_dict] ; null (push_error) si le contenu est
## invalide ou fait référence à une espèce ou une capacité inconnue.
static func from_dict(dict: Dictionary, data: PokemonData) -> Pokemon:
	var pokemon := Pokemon.new()
	pokemon.species_id = StringName(str(dict.get("species", "")))
	if not data.has_species(pokemon.species_id):
		return _invalid("espèce inconnue « %s »" % pokemon.species_id)
	var level_value: Variant = dict.get("level")
	if not _is_int(level_value) or int(level_value) < 1 or int(level_value) > ExpCurve.MAX_LEVEL:
		return _invalid("niveau invalide")
	pokemon.level = int(level_value)
	if not GENDER_NAMES.has(str(dict.get("gender", ""))):
		return _invalid("sexe invalide")
	pokemon.gender = GENDER_NAMES[str(dict["gender"])]
	pokemon.nickname = str(dict.get("nickname", ""))
	if not _is_int(dict.get("exp")) or not _is_int(dict.get("hp")):
		return _invalid("« exp » et « hp » doivent être des entiers")
	pokemon.experience = maxi(int(dict["exp"]), 0)
	if not _stats_from_dict(dict.get("ivs"), pokemon.ivs, StatCalc.IV_MAX) \
			or not _stats_from_dict(dict.get("evs"), pokemon.evs, StatCalc.EV_MAX):
		return _invalid("IV ou EV invalides")
	var move_list: Variant = dict.get("moves")
	if not move_list is Array or (move_list as Array).is_empty() \
			or (move_list as Array).size() > SpeciesData.MAX_MOVES:
		return _invalid("1 à %d capacités attendues" % SpeciesData.MAX_MOVES)
	for entry: Variant in move_list:
		if not entry is Dictionary or not data.has_move(StringName(str(entry.get("id", "")))) \
				or not _is_int(entry.get("pp")) or not _is_int(entry.get("max_pp")):
			return _invalid("capacité invalide : %s" % str(entry))
		var slot := MoveSlot.new(StringName(entry["id"]), maxi(int(entry["max_pp"]), 1))
		slot.pp = clampi(int(entry["pp"]), 0, slot.max_pp)
		pokemon.moves.append(slot)
	pokemon.recalc(data)
	pokemon.hp = clampi(int(dict["hp"]), 0, pokemon.max_hp())
	return pokemon


static func _stats_to_dict(values: Dictionary[StringName, int]) -> Dictionary:
	var result: Dictionary = {}
	for stat: StringName in SpeciesData.STATS:
		result[String(stat)] = values.get(stat, 0)
	return result


static func _stats_from_dict(value: Variant, into: Dictionary[StringName, int],
		high: int) -> bool:
	if not value is Dictionary:
		return false
	for stat: StringName in SpeciesData.STATS:
		var n: Variant = (value as Dictionary).get(String(stat), 0)
		if not _is_int(n) or int(n) < 0 or int(n) > high:
			return false
		into[stat] = int(n)
	return true


static func _is_int(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == floorf(float(value))


static func _invalid(message: String) -> Pokemon:
	push_error("Pokemon.from_dict : " + message)
	return null
