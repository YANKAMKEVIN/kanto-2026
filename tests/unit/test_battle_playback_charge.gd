extends GutTest
## Temps de mise en scène de « charge puis frappe » et de Téléport (jalon 14 T9) : événement du
## journal → BattleBeat (cacher / rendre le sprite, pas de Ball, messages seuls).

const J14Moves := preload("res://tests/helpers/j14_moves.gd")
const K := BattleEvent.Kind
const B := BattleBeat.Kind

var _data: PokemonData
var _texts: BattleText


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	J14Moves.ensure(_data)
	_texts = BattleText.new()
	_texts.load_file()


func _event(kind: BattleEvent.Kind, side: BattleEvent.SideId, move: StringName = &"",
		species: StringName = &"charmander") -> BattleEvent:
	var event := BattleEvent.new(kind, side)
	event.pokemon_name = "Salamèche"
	event.species_id = species
	event.move_id = move
	return event


func _kinds(event: BattleEvent) -> Array:
	var result: Array = []
	for beat: BattleBeat in BattlePlayback.beats(event, _texts, _data):
		result.append(beat.kind)
	return result


func test_dig_start_says_then_burrows() -> void:
	var event := _event(K.CHARGE_STARTED, BattleEvent.SideId.PLAYER, &"dig")
	assert_eq(_kinds(event), [B.MESSAGE, B.BURROW], "message puis le sol l'avale")
	var beats := BattlePlayback.beats(event, _texts, _data)
	assert_eq(beats[0].text, "Salamèche creuse un trou !")
	assert_eq(beats[1].side, BattleEvent.SideId.PLAYER)


func test_visible_charge_only_says_the_message() -> void:
	# Une charge qui n'est pas invulnérable : le message, aucun sprite caché.
	var move := _data.get_move(&"dig")
	var effect := move.charge_effect()
	var was := effect.invulnerable
	effect.invulnerable = false
	assert_eq(_kinds(_event(K.CHARGE_STARTED, BattleEvent.SideId.FOE, &"dig")), [B.MESSAGE])
	effect.invulnerable = was


func test_release_surfaces_without_a_phrase() -> void:
	assert_eq(_kinds(_event(K.CHARGE_RELEASED, BattleEvent.SideId.PLAYER, &"dig")),
		[B.SURFACE])


func test_broken_surfaces_then_says() -> void:
	var event := _event(K.CHARGE_BROKEN, BattleEvent.SideId.FOE, &"dig")
	assert_eq(_kinds(event), [B.SURFACE, B.MESSAGE])
	assert_eq(BattlePlayback.beats(event, _texts, _data)[1].text,
		"Salamèche remonte à la surface.")


func test_dodged_blocked_and_nothing_happened_are_messages_only() -> void:
	assert_eq(_kinds(_event(K.DODGED, BattleEvent.SideId.PLAYER, &"tackle")), [B.MESSAGE])
	var blocked := _event(K.BALL_BLOCKED, BattleEvent.SideId.FOE)
	blocked.item_id = &"poke_ball"
	assert_eq(_kinds(blocked), [B.MESSAGE], "ni lancer ni Ball : THROW absent")
	assert_eq(_kinds(_event(K.NOTHING_HAPPENED, BattleEvent.SideId.PLAYER)), [B.MESSAGE])


func test_teleport_vanishes_then_says() -> void:
	var event := _event(K.TELEPORTED, BattleEvent.SideId.FOE, &"teleport", &"abra")
	event.pokemon_name = "Abra"
	assert_eq(_kinds(event), [B.VANISH, B.MESSAGE])
	assert_eq(BattlePlayback.beats(event, _texts, _data)[0].side, BattleEvent.SideId.FOE)
