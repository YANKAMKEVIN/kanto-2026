extends GutTest
## Soin chez Maman (jalon 5C T11, décision de Kevin Q22, jalon-05.md §3.11) avec la vraie scène
## Boot dans la maison, au point de soin (face à Maman) :
## - avant le starter, Maman ne soigne rien (elle garde ses mots d'avant) ;
## - dès que le starter est choisi, lui parler soigne toute l'équipe (PV et PP), à chaque fois ;
## - le premier dialogue automatique (mom_greeted) et le réveil après défaite (mom_wakeup) ne
##   sont pas touchés.

const TIMEOUT := 8.0

var _boot: Boot
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.05
	SceneRouter.fade_in_duration = 0.05
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.start_map = &"player_house_1f"
	_boot.start_spawn = &"heal"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	await wait_process_frames(2)


func after_each() -> void:
	Input.action_release(&"interact")
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]


## Équipe de deux Pokémon blessés (PV à 1, un PP dépensé).
func _hurt_party() -> Party:
	var data := _boot.get_pokemon_data()
	var party := Party.new()
	for species: StringName in [&"charmander", &"squirtle"]:
		var pokemon := PokemonFactory.create(data, species, 5, GameRng.new(7))
		pokemon.hp = 1
		pokemon.moves[0].use()
		party.add(pokemon)
	return party


func _is_hurt(party: Party) -> bool:
	for pokemon: Pokemon in party.get_all():
		if pokemon.hp < pokemon.max_hp() or pokemon.moves[0].pp < pokemon.moves[0].max_pp:
			return true
	return false


## Fait défiler le dialogue en cours jusqu'à sa fin ; renvoie le texte de sa 1re page.
func _read_dialogue() -> String:
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	await wait_until(func() -> bool:
		return runner.is_running() and runner.get_session() != null and box.is_open(), TIMEOUT)
	var first_text := (box.get_node(^"%Text") as Label).text
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(runner.is_running(), "le dialogue s'est terminé")
	await wait_process_frames(2)
	return first_text


## Passe le premier dialogue automatique de Maman (arrivée dans la maison).
func _pass_the_greeting() -> void:
	var first := await _read_dialogue()
	assert_eq(first, "Bonjour ! Tu es enfin réveillé ?", "premier dialogue automatique")
	assert_true(GameState.flags.has_flag(&"mom_greeted"), "mom_greeted levé")


## Parle à Maman (le joueur est face à elle) et lit sa réplique.
func _talk() -> String:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	return await _read_dialogue()


func test_the_first_automatic_dialogue_still_plays_and_heals_nothing() -> void:
	await _pass_the_greeting()
	# Drapeau mom_greeted retiré : même avec le starter choisi, la première variante (le
	# dialogue automatique) passe avant celle du soin et ne soigne rien.
	GameState.flags.clear()
	GameState.flags.set_flag(&"starter_chosen")
	GameState.party = _hurt_party()
	assert_true(_boot.get_dialogue_runner().play(&"mom", null, _boot.get_map()))
	var first := await _read_dialogue()
	assert_eq(first, "Bonjour ! Tu es enfin réveillé ?", "premier dialogue conservé")
	assert_true(GameState.flags.has_flag(&"mom_greeted"))
	assert_true(_is_hurt(GameState.party), "le premier dialogue ne soigne pas")
	assert_push_error_count(0)


func test_talking_to_mom_before_the_starter_heals_nothing() -> void:
	await _pass_the_greeting()
	GameState.party = _hurt_party()
	assert_false(GameState.flags.has_flag(&"starter_chosen"))
	var line := await _talk()
	assert_eq(line, "Tu sors ? Profite de cette belle journée.", "ses mots d'avant le starter")
	assert_true(_is_hurt(GameState.party), "pas de soin avant le starter")
	assert_push_error_count(0)


func test_talking_to_mom_after_the_starter_heals_the_whole_team_every_time() -> void:
	await _pass_the_greeting()
	GameState.flags.set_flag(&"starter_chosen")
	GameState.party = _hurt_party()
	var first := await _talk()
	assert_eq(first, "Laisse-moi m'occuper de tes Pokémon.", "réplique de soin (provisoire)")
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, pokemon.max_hp(), "%s : PV pleins" % pokemon.species_id)
		assert_eq(pokemon.moves[0].pp, pokemon.moves[0].max_pp, "%s : PP pleins"
			% pokemon.species_id)
	assert_true(_player.is_input_enabled(), "joueur libre")
	# À chaque fois qu'on lui parle.
	GameState.party = _hurt_party()
	await _talk()
	assert_false(_is_hurt(GameState.party), "soigné une seconde fois")
	assert_push_error_count(0)


func test_the_wakeup_after_a_defeat_is_unchanged() -> void:
	await _pass_the_greeting()
	GameState.flags.set_flag(&"starter_chosen")
	GameState.party = _hurt_party()
	assert_true(_boot.get_dialogue_runner().play(&"mom_wakeup", null, _boot.get_map()))
	var first := await _read_dialogue()
	assert_eq(first, "Tu m'as fait une de ces peurs...", "réveil : première défaite")
	assert_true(GameState.flags.has_flag(&"blacked_out_before"))
	# Le réveil ne soigne pas par son texte (la défaite soigne l'équipe elle-même).
	assert_true(_is_hurt(GameState.party), "mom_wakeup n'a pas de clé « heal »")
	assert_push_error_count(0)
