extends GutTest
## Capacités du jalon 21 (T4, jalon-21.md §2.10 ; dossier 24 §15.10) : Amnésie (Ronflex),
## data/pokemon/moves/j21.json. Psy, statut, 20 PP, Défense Spéciale +2 sur soi (RB : Spécial
## +2 ; le projet sépare les deux statistiques [D] du dossier).

const Kit := preload("res://tests/helpers/battle_kit_j12.gd")

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))


func test_amnesia_data() -> void:
	var move := _data.get_move(&"amnesia")
	assert_not_null(move)
	if move == null:
		return
	assert_eq([move.name, move.type, move.category, move.power, move.pp],
		["Amnésie", &"psychic", MoveData.Category.STATUS, 0, 20])
	assert_true(move.never_misses(), "précision 0 : jamais ratée (capacité sur soi)")
	assert_eq(move.effects.size(), 1)
	var effect := move.effects[0]
	assert_eq([effect.kind, effect.stat, effect.stages, effect.target, effect.chance],
		[MoveEffect.Kind.STAT_STAGE, &"spd", 2, MoveEffect.Target.SELF, 100])
	assert_eq(move.pending_effects.size(), 0, "rien en attente : l'effet est codé")
	assert_eq(move.description,
		"Le lanceur fait le vide dans sa tête. Augmente beaucoup sa Défense Spéciale.")
	# Texte du dossier 24 §15.10 (lot à valider) : pas de « draft », les capacités réelles n'en
	# ont jamais (test_pokemon_data) ; à corriger ici si Kevin change le texte.
	assert_eq(move.source, "res://data/pokemon/moves/j21.json")


func test_amnesia_description_is_unique() -> void:
	var text := _data.get_move(&"amnesia").description
	for id: StringName in _data.get_move_ids():
		if id != &"amnesia":
			assert_ne(_data.get_move(id).description, text, String(id))


func test_amnesia_raises_the_users_special_defense_by_two_in_battle() -> void:
	var mine := Kit.mon(_data, &"rattata", 20, [&"amnesia"])
	var foe := Kit.mon(_data, &"rattata", 20, [&"amnesia"])
	var battle := Kit.battle(_data, GameRng.new(7), [mine], [foe])
	battle.submit(BattleAction.move(0))
	var player := battle.get_player_side().active
	assert_eq(player.get_stage(&"spd"), 2, "Défense Spéciale +2")
	for stat: StringName in [&"atk", &"def", &"spa", &"spe"]:
		assert_eq(player.get_stage(stat), 0, String(stat))
