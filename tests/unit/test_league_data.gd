extends GutTest
## Données de la Ligue (jalon 30 T3 ; `jalon-30.md` §2.7, Q30-3) : Conseil des Quatre et rival
## Champion (`data/trainers/league.json`), vérifiés contre pokered (`parties.asm`,
## `special_moves.asm`, `read_trainer_party.asm` : capacité d'équipe du 5e Pokémon, Piqué et
## capacité du starter du Champion). Capacités au niveau calculées comme RB, **sans
## remplacement** : Q30-3, décision de Kevin du 2026-10-22, les effets manquants sont codés
## ici (Frénésie, Mania, Mimique : test_league_moves.gd) ; Toxik attend le J23, Riposte, Pied
## Sauté et Pied Voltige le J27 (effets codés là-bas, données empruntées à l'identique).

const SOURCE := "res://data/trainers/league.json"
const STARTERS: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle"]
## Capacités encore sans effet tolérées dans les équipes : codées par une autre branche.
## Toxik : J23 ; Riposte, Pied Sauté, Pied Voltige : effets livrés par le J27 (commit 865c97e7).
const PENDING_ALLOWED: Array[StringName] = [&"toxic", &"counter", &"jump_kick", &"hi_jump_kick"]

## [espèce, niveau, capacités] par membre, dans l'ordre RB.
const MEMBERS := {
	&"league_lorelei": ["Olga", [
		[&"dewgong", 54, [&"growl", &"aurora_beam", &"rest", &"take_down"]],
		[&"cloyster", 53, [&"supersonic", &"clamp", &"aurora_beam", &"spike_cannon"]],
		[&"slowbro", 54, [&"growl", &"water_gun", &"withdraw", &"amnesia"]],
		[&"jynx", 56, [&"double_slap", &"ice_punch", &"body_slam", &"thrash"]],
		[&"lapras", 56, [&"body_slam", &"confuse_ray", &"blizzard", &"hydro_pump"]],
	]],
	&"league_bruno": ["Aldo", [
		[&"onix", 53, [&"rock_throw", &"rage", &"slam", &"harden"]],
		[&"hitmonchan", 55, [&"ice_punch", &"thunder_punch", &"mega_punch", &"counter"]],
		[&"hitmonlee", 55, [&"jump_kick", &"focus_energy", &"hi_jump_kick", &"mega_kick"]],
		[&"onix", 56, [&"rock_throw", &"rage", &"slam", &"harden"]],
		[&"machamp", 58, [&"leer", &"focus_energy", &"fissure", &"submission"]],
	]],
	&"league_agatha": ["Agatha", [
		[&"gengar", 56, [&"confuse_ray", &"night_shade", &"hypnosis", &"dream_eater"]],
		[&"golbat", 56, [&"supersonic", &"confuse_ray", &"wing_attack", &"haze"]],
		[&"haunter", 55, [&"confuse_ray", &"night_shade", &"hypnosis", &"dream_eater"]],
		[&"arbok", 58, [&"bite", &"glare", &"screech", &"acid"]],
		[&"gengar", 60, [&"confuse_ray", &"night_shade", &"toxic", &"dream_eater"]],
	]],
	&"league_lance": ["Peter", [
		[&"gyarados", 58, [&"dragon_rage", &"leer", &"hydro_pump", &"hyper_beam"]],
		[&"dragonair", 56, [&"agility", &"slam", &"dragon_rage", &"hyper_beam"]],
		[&"dragonair", 56, [&"agility", &"slam", &"dragon_rage", &"hyper_beam"]],
		[&"aerodactyl", 60, [&"supersonic", &"bite", &"take_down", &"hyper_beam"]],
		[&"dragonite", 62, [&"agility", &"slam", &"barrier", &"hyper_beam"]],
	]],
}
const PIDGEOT := [&"pidgeot", 61, [&"whirlwind", &"wing_attack", &"sky_attack", &"mirror_move"]]
const ALAKAZAM := [&"alakazam", 59, [&"psybeam", &"recover", &"psychic", &"reflect"]]
const RHYDON := [&"rhydon", 61, [&"tail_whip", &"fury_attack", &"horn_drill", &"leer"]]
## Rival Champion (passe §4 = pokered Rival3Data) : starter du joueur → équipe.
const RIVAL := {
	&"bulbasaur": [PIDGEOT, ALAKAZAM, RHYDON,
		[&"exeggutor", 61, [&"barrage", &"hypnosis", &"stomp"]],
		[&"gyarados", 63, [&"dragon_rage", &"leer", &"hydro_pump", &"hyper_beam"]],
		[&"charizard", 65, [&"rage", &"slash", &"fire_blast", &"fire_spin"]]],
	&"charmander": [PIDGEOT, ALAKAZAM, RHYDON,
		[&"arcanine", 61, [&"roar", &"ember", &"leer", &"take_down"]],
		[&"exeggutor", 63, [&"barrage", &"hypnosis", &"stomp"]],
		[&"blastoise", 65, [&"bite", &"withdraw", &"blizzard", &"hydro_pump"]]],
	&"squirtle": [PIDGEOT, ALAKAZAM, RHYDON,
		[&"gyarados", 61, [&"dragon_rage", &"leer", &"hydro_pump", &"hyper_beam"]],
		[&"arcanine", 63, [&"roar", &"ember", &"leer", &"take_down"]],
		[&"venusaur", 65, [&"razor_leaf", &"growth", &"mega_drain", &"solar_beam"]]],
}

var _data: PokemonData
var _library: TrainerLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon (espèces et capacités du J30 comprises)")
	_library = TrainerLibrary.new(_data)
	assert_true(_library.load_file(SOURCE), "league.json valide")


func _check_team(label: String, team: Array[TrainerSlot], expected: Array) -> void:
	assert_eq(team.size(), expected.size(), "%s : taille" % label)
	for i: int in mini(team.size(), expected.size()):
		var slot: TrainerSlot = team[i]
		var want: Array = expected[i]
		assert_eq(slot.species, want[0], "%s n° %d : espèce" % [label, i + 1])
		assert_eq(slot.level, want[1], "%s n° %d : niveau" % [label, i + 1])
		var moves: Array[StringName] = []
		moves.assign(want[2])
		assert_eq(slot.moves, moves, "%s n° %d : capacités" % [label, i + 1])


func test_the_four_members_match_red_blue() -> void:
	for id: StringName in MEMBERS:
		var trainer := _library.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.name, MEMBERS[id][0])
		assert_eq(trainer.prize_for(60), 99 * 60, "%s : 99 par niveau (pokered)" % id)
		_check_team(String(id), trainer.team_for(&"charmander"), MEMBERS[id][1])


func test_the_champion_depends_on_the_starter_only() -> void:
	var rival := _library.get_trainer(&"rival_champion")
	assert_not_null(rival)
	if rival == null:
		return
	for starter: StringName in STARTERS:
		_check_team("rival (%s)" % starter, rival.team_for(starter), RIVAL[starter])


func test_league_battles_never_heal_and_defeat_is_a_blackout() -> void:
	for id: StringName in LeagueAttempt.TRAINERS:
		var trainer := _library.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_false(trainer.heal_after, "%s : aucun soin de fin de combat" % id)
		assert_false(trainer.can_lose, "%s : défaite = réveil au Plateau" % id)
		assert_eq(trainer.ai, &"smart", "%s : IA smart" % id)


func test_no_move_without_coded_effect_except_known_dependencies() -> void:
	var teams: Array = []
	for id: StringName in MEMBERS:
		teams.append(_library.get_trainer(id).team_for(&"charmander"))
	for starter: StringName in STARTERS:
		teams.append(_library.get_trainer(&"rival_champion").team_for(starter))
	for team: Array in teams:
		for slot: TrainerSlot in team:
			for move_id: StringName in slot.moves:
				if PENDING_ALLOWED.has(move_id):
					continue
				var move := _data.get_move(move_id)
				assert_true(move != null and move.pending_effects.is_empty(),
					"%s : %s sans effet codé (Q30-3 : à coder)" % [slot.species, move_id])
