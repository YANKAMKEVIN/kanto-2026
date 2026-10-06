class_name ExpSummary
extends RefCounted
## Résumé de la progression d'un combat, pour le bilan de fin de combat (demande n° 1,
## décisions de Kevin du 2026-10-06). Classe pure : construite à partir des événements du
## journal ([method add], dans l'ordre où ils sont joués, ou [method from_events]).
##
## Seuls EXP_GAINED et LEVEL_UP comptent (camp du joueur) : un Pokémon sans XP (K.O. avant la
## fin, resté dans l'équipe) n'a pas d'entrée — il est absent du bilan (décision n° 4). Un
## Pokémon est reconnu par sa place dans l'équipe ([member BattleEvent.party_index]), jamais par
## son nom. Rien n'est écrit dans la sauvegarde.

var _entries: Array[ExpSummaryEntry] = []


## Résumé de tout un journal.
static func from_events(events: Array[BattleEvent]) -> ExpSummary:
	var summary := ExpSummary.new()
	for event: BattleEvent in events:
		summary.add(event)
	return summary


## Prend en compte [param event] (les autres sortes sont ignorées).
func add(event: BattleEvent) -> void:
	if event == null or event.side != BattleEvent.SideId.PLAYER or event.party_index < 0:
		return
	match event.kind:
		BattleEvent.Kind.EXP_GAINED:
			_add_exp(event)
		BattleEvent.Kind.LEVEL_UP:
			var entry := get_entry(event.party_index)
			if entry == null:
				return
			var step := LevelUp.new()
			step.level = event.level
			step.stat_gains = event.stat_gains.duplicate()
			entry.level_ups.append(step)
			# La tranche du nouveau niveau part d'ici ; la prochaine XP la prolonge.
			entry.segments.append(Vector2(event.exp_from, event.exp_from))
			entry.points.append(Vector3i(event.exp_points_from, event.exp_points_from,
				event.exp_points_need))


## Aucun Pokémon n'a gagné d'XP : pas de bilan.
func is_empty() -> bool:
	return _entries.is_empty()


## Les Pokémon qui ont gagné de l'XP, dans l'ordre de l'équipe.
func get_entries() -> Array[ExpSummaryEntry]:
	var sorted := _entries.duplicate()
	sorted.sort_custom(func(a: ExpSummaryEntry, b: ExpSummaryEntry) -> bool:
		return a.party_index < b.party_index)
	return sorted


## L'entrée du Pokémon à la place [param party_index], ou null.
func get_entry(party_index: int) -> ExpSummaryEntry:
	for entry: ExpSummaryEntry in _entries:
		if entry.party_index == party_index:
			return entry
	return null


## Au moins un Pokémon monte de niveau.
func has_level_up() -> bool:
	return _entries.any(func(entry: ExpSummaryEntry) -> bool: return entry.levels_gained() > 0)


func _add_exp(event: BattleEvent) -> void:
	var entry := get_entry(event.party_index)
	if entry == null:
		entry = ExpSummaryEntry.new()
		entry.party_index = event.party_index
		entry.species_id = event.species_id
		entry.pokemon_name = event.pokemon_name
		entry.start_level = event.level
		_entries.append(entry)
	entry.exp_gained += event.amount
	var segment := Vector2(event.exp_from, event.exp_to)
	var points := Vector3i(event.exp_points_from, event.exp_points_to, event.exp_points_need)
	# Toujours une tranche par niveau : une XP dans le niveau de la précédente (autre K.O.,
	# même niveau, ou juste après une montée) la prolonge.
	if entry.segments.is_empty():
		entry.segments.append(segment)
		entry.points.append(points)
	else:
		entry.segments[-1].y = segment.y
		entry.points[-1].y = points.y
