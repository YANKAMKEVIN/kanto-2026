extends GutTest
## Chapitre Johto, JOH0 T3 (`jalon-joh0.md` §2.2 ; dossier JOH-01 §6 ; JH-1 à JH-3, JH-23,
## JH-24) : le vol de l'équipe et du Sac (objets clés gardés), le Stockage hors ligne, le choix
## des 6 au retour, la fusion des Sacs, le compagnon, le lancer refusé à 6 ; chaque opération est
## tout ou rien et synchrone (une sauvegarde ne voit jamais un état intermédiaire).

const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const PATH := "user://test/save_confiscation.json"

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "objets")


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-11-03T21:00:00")
	state.new_game(7)
	return state


## L'équipe de Ligue de Kevin (5 Pokémon, le 3e K.O.), son Sac (objets ordinaires, CT, clés),
## Salamèche compagnon.
func _league_state() -> Node:
	var state := _state()
	var i := 0
	for species: StringName in [&"charizard", &"pidgeot", &"raticate", &"nidoking", &"alakazam"]:
		var mon := PokemonFactory.create(_data, species, 60 + i, GameRng.new(i))
		state.stamp_meeting(mon, Pokemon.Origin.CAPTURE, &"route_1")
		state.party.add(mon)
		i += 1
	state.party.get_at(2).hp = 0
	state.set_companion(state.party.get_at(0))
	state.bag.add(&"potion", 3)
	state.bag.add(&"great_ball", 7)
	state.bag.add(&"tm28", 1)
	state.bag.add(&"oak_parcel", 1)
	state.bag.add(&"bike_voucher", 1)
	state.bag.add(&"exp_all", 1)
	state.bag.set_favorite(&"potion", true)
	state.money = 12_345
	state.flags.set_flag(&"badge_boulder")
	return state


## Après le vol : l'équipe de Johto (Germignon n'existe pas encore dans les données de cette
## branche : un Kaiminus de substitution = Carapuce), 2 Pokémon, des Balls neuves.
func _act1_state() -> Node:
	var state := _league_state()
	assert_true(TeamConfiscation.confiscate(state, _items))
	for species: StringName in [&"squirtle", &"sentret" if _data.has_species(&"sentret")
			else &"rattata"]:
		var mon := PokemonFactory.create(_data, species, 12, GameRng.new(species.hash()))
		state.stamp_meeting(mon, Pokemon.Origin.CAPTURE, &"route_39")
		state.party.add(mon)
	state.set_companion(state.party.get_at(0))
	state.bag.add(&"poke_ball", 4)
	state.bag.add(&"potion", 2)
	return state


func _uids(members: Array[Pokemon]) -> Array[String]:
	var result: Array[String] = []
	for pokemon: Pokemon in members:
		result.append(pokemon.uid)
	return result


# --- Le vol ---------------------------------------------------------------------------------------

func test_the_theft_moves_the_team_and_the_ordinary_items_into_the_section() -> void:
	var state := _league_state()
	var before := _uids(state.party.get_all())
	var companion: String = state.companion_uid
	assert_true(TeamConfiscation.confiscate(state, _items))
	assert_eq(state.party.size(), 0, "équipe vide")
	assert_eq(_uids(state.confiscated.party), before, "mêmes Pokémon, même ordre, mêmes identifiants")
	assert_eq(state.confiscated.party[2].hp, 0, "le K.O. reste K.O. : rien n'est soigné")
	assert_eq(state.confiscated.items, {&"potion": 3, &"great_ball": 7, &"tm28": 1}
		as Dictionary[StringName, int], "objets ordinaires et CT confisqués")
	assert_eq(state.confiscated.companion_uid, companion)
	assert_eq(state.companion_uid, "", "plus de compagnon")
	for key: StringName in [&"oak_parcel", &"bike_voucher", &"exp_all"]:
		assert_eq(state.bag.count_of(key), 1, "objet clé gardé : %s" % key)
	assert_eq(state.bag.count_of(&"potion"), 0)
	assert_true(state.bag.is_favorite(&"potion"), "favori gardé : la Potion reviendra favorite")
	assert_eq(state.money, 12_345, "argent gardé")
	assert_true(state.flags.has_flag(&"badge_boulder"), "badges gardés")
	assert_true(state.flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	assert_true(state.flags.has_flag(TeamConfiscation.ACT1))
	assert_true(TeamConfiscation.is_act1(state.flags))
	assert_true(TeamConfiscation.is_storage_offline(state.flags))


func test_the_theft_is_refused_on_an_empty_team_or_twice() -> void:
	var state := _state()
	assert_false(TeamConfiscation.confiscate(state, _items), "équipe vide")
	assert_false(state.flags.has_flag(TeamConfiscation.ACT1))
	state = _league_state()
	assert_true(TeamConfiscation.confiscate(state, _items))
	state.party.add(PokemonFactory.create(_data, &"squirtle", 5, GameRng.new(1)))
	assert_false(TeamConfiscation.confiscate(state, _items), "déjà une équipe confisquée")
	assert_eq(state.party.size(), 1, "rien ne change")
	assert_eq(state.confiscated.party.size(), 5)


func test_an_unknown_item_is_ordinary_and_a_key_item_stays() -> void:
	assert_true(TeamConfiscation.is_key_item(&"oak_parcel", _items))
	assert_false(TeamConfiscation.is_key_item(&"potion", _items))
	assert_false(TeamConfiscation.is_key_item(&"tm28", _items), "une CT est un objet du Sac")
	assert_false(TeamConfiscation.is_key_item(&"objet_inconnu", _items), "[D] confisqué")
	assert_false(TeamConfiscation.is_key_item(&"oak_parcel", null))


func test_the_theft_survives_a_save_and_the_section_never_shows_a_half_state() -> void:
	var state := _league_state()
	var fs := MemoryFs.new()
	var save := SaveSystem.new(fs, PATH)
	assert_eq(save.write(state.to_dict()), OK, "avant : la partie de Ligue")
	assert_true(TeamConfiscation.confiscate(state, _items))
	assert_eq(save.write(state.to_dict()), OK, "après : une seule écriture")
	var loaded := _state()
	assert_true(loaded.load_dict(save.read(), _data))
	assert_eq(loaded.party.size(), 0)
	assert_eq(loaded.confiscated.party.size(), 5)
	assert_eq(loaded.confiscated.items[&"great_ball"], 7)
	assert_true(loaded.flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	assert_eq(loaded.bag.count_of(&"exp_all"), 1, "Multi Exp gardé (objet clé)")


# --- Le retour ------------------------------------------------------------------------------------

func test_the_return_keeps_the_chosen_six_stores_the_rest_and_merges_the_bags() -> void:
	var state := _act1_state()
	var johto := _uids(state.party.get_all())
	var kanto := _uids(state.confiscated.party)
	# Gardés : les deux de Johto, puis Dracaufeu, Roucarnage, Nidoking et Alakazam (6) ; Rattatac
	# (K.O.) va au Stockage.
	var kept: Array[String] = [johto[0], johto[1], kanto[0], kanto[1], kanto[3], kanto[4]]
	var result := TeamConfiscation.restore(state, kept)
	assert_true(result["ok"])
	assert_eq(result["check"], TeamConfiscation.Check.OK)
	assert_eq(_uids(state.party.get_all()), kept, "l'équipe dans l'ordre du choix")
	assert_eq(_uids(result["stored"]), [kanto[2]], "le reste au Stockage")
	assert_eq(_uids(state.storage.get_all()), [kanto[2]])
	assert_true(state.confiscated.is_empty(), "section vidée")
	assert_eq(state.bag.count_of(&"potion"), 5, "2 + 3 : Sacs fusionnés")
	assert_eq(state.bag.count_of(&"great_ball"), 7)
	assert_eq(state.bag.count_of(&"poke_ball"), 4)
	assert_eq(state.bag.count_of(&"tm28"), 1)
	assert_true(state.bag.is_favorite(&"potion"), "la Potion est revenue favorite")
	assert_false(state.flags.has_flag(TeamConfiscation.STORAGE_OFFLINE))
	assert_false(state.flags.has_flag(TeamConfiscation.ACT1))
	assert_true(state.flags.has_flag(TeamConfiscation.RETURNED))
	assert_eq(state.companion_uid, kanto[0], "le compagnon d'avant le vol, gardé, revient")
	assert_eq(result["companion"], kanto[0])
	assert_eq(state.get_companion().species_id, &"charizard")


func test_the_return_falls_back_to_the_first_kept_as_companion() -> void:
	var state := _act1_state()
	var johto := _uids(state.party.get_all())
	var kanto := _uids(state.confiscated.party)
	var kept: Array[String] = [kanto[4], johto[0]]
	var result := TeamConfiscation.restore(state, kept)
	assert_true(result["ok"])
	assert_eq(state.companion_uid, kanto[4], "Dracaufeu non gardé : le premier de l'équipe")
	assert_eq(state.party.size(), 2)
	assert_eq(state.storage.size(), 5, "4 de Kanto et 1 de Johto au Stockage")
	assert_eq(_uids(state.storage.get_all()), [johto[1], kanto[0], kanto[1], kanto[2], kanto[3]],
		"ordre : équipe de Johto puis confisquée")


func test_the_return_is_refused_for_bad_choices_and_changes_nothing() -> void:
	var state := _act1_state()
	var johto := _uids(state.party.get_all())
	var kanto := _uids(state.confiscated.party)
	var cases := {
		TeamConfiscation.Check.EMPTY: [] as Array[String],
		TeamConfiscation.Check.TOO_MANY: [johto[0], johto[1], kanto[0], kanto[1], kanto[2],
			kanto[3], kanto[4]] as Array[String],
		TeamConfiscation.Check.UNKNOWN: ["0123456789abcdef"] as Array[String],
		TeamConfiscation.Check.DUPLICATE: [johto[0], johto[0]] as Array[String],
		TeamConfiscation.Check.NO_ABLE: [kanto[2]] as Array[String],
	}
	for check: TeamConfiscation.Check in cases:
		var result := TeamConfiscation.restore(state, cases[check])
		assert_false(result["ok"], TeamConfiscation.Check.find_key(check))
		assert_eq(result["check"], check)
		assert_eq(state.party.size(), 2, "rien ne change")
		assert_eq(state.confiscated.party.size(), 5)
		assert_true(state.flags.has_flag(TeamConfiscation.ACT1))
	var fresh := _state()
	assert_false(TeamConfiscation.restore(fresh, [] as Array[String])["ok"], "rien de confisqué")


func test_a_fainted_egg_free_choice_with_one_able_is_enough() -> void:
	var state := _act1_state()
	var kanto := _uids(state.confiscated.party)
	state.party.get_at(0).egg_steps = 500
	var johto := _uids(state.party.get_all())
	assert_eq(TeamConfiscation.check_kept(TeamConfiscation.pool(state), [johto[0], kanto[2]]),
		TeamConfiscation.Check.NO_ABLE, "un œuf et un K.O. : personne pour combattre")
	assert_eq(TeamConfiscation.check_kept(TeamConfiscation.pool(state),
		[johto[0], kanto[2], kanto[0]]), TeamConfiscation.Check.OK)


func test_the_return_survives_a_save_in_one_write() -> void:
	var state := _act1_state()
	var fs := MemoryFs.new()
	var save := SaveSystem.new(fs, PATH)
	assert_eq(save.write(state.to_dict()), OK)
	var kanto := _uids(state.confiscated.party)
	assert_true(TeamConfiscation.restore(state, [kanto[0]] as Array[String])["ok"])
	assert_eq(save.write(state.to_dict()), OK)
	var loaded := _state()
	assert_true(loaded.load_dict(save.read(), _data))
	assert_eq(loaded.party.size(), 1)
	assert_eq(loaded.storage.size(), 6)
	assert_true(loaded.confiscated.is_empty())
	assert_false(loaded.to_dict().has("confiscated"), "section absente du fichier")
	assert_true(loaded.flags.has_flag(TeamConfiscation.RETURNED))


# --- Le choix (TeamReturnSelection) --------------------------------------------------------------

func test_the_selection_counts_toggles_in_touch_order_and_caps_at_six() -> void:
	var state := _act1_state()
	var selection := TeamReturnSelection.new(state.party.get_all(), state.confiscated.party)
	assert_eq(selection.size(), 7)
	assert_eq(selection.source_of(0), TeamReturnSelection.Source.JOHTO)
	assert_eq(selection.source_of(2), TeamReturnSelection.Source.KANTO)
	assert_eq(selection.count(), 0)
	assert_false(selection.can_confirm(), "rien de choisi")
	var pool := selection.get_pool()
	assert_true(selection.toggle(pool[3].uid))
	assert_true(selection.toggle(pool[0].uid))
	assert_eq(selection.kept(), [pool[3].uid, pool[0].uid] as Array[String], "ordre de touche")
	assert_true(selection.can_confirm())
	assert_true(selection.toggle(pool[3].uid), "retiré")
	assert_eq(selection.count(), 1)
	assert_false(selection.toggle("inconnu"))
	for i: int in [1, 2, 3, 4, 5]:
		assert_true(selection.toggle(pool[i].uid))
	assert_eq(selection.count(), 6)
	assert_false(selection.toggle(pool[6].uid), "plus de place")
	assert_false(selection.is_selected(pool[6].uid))
	assert_true(selection.can_confirm())


func test_the_default_selection_is_johto_then_kanto_up_to_six() -> void:
	var state := _act1_state()
	var selection := TeamReturnSelection.new(state.party.get_all(), state.confiscated.party)
	var pool := selection.get_pool()
	var expected: Array[String] = []
	for i: int in 6:
		expected.append(pool[i].uid)
	assert_eq(selection.default_selection(), expected)
	selection.select(selection.default_selection())
	assert_true(selection.can_confirm())
	assert_eq(selection.check(), TeamConfiscation.Check.OK)
	# Seul le K.O. choisi : refusé.
	selection.select([pool[4].uid] as Array[String])
	assert_eq(selection.check(), TeamConfiscation.Check.NO_ABLE)
	assert_false(selection.can_confirm())
	var empty := TeamReturnSelection.new()
	assert_eq(empty.default_selection(), [] as Array[String])
	assert_false(empty.can_confirm())


# --- Lancer refusé à 6 (JH-23) ----------------------------------------------------------------

func test_a_ball_is_refused_only_with_a_full_team_and_the_storage_offline() -> void:
	assert_true(CaptureGate.can_throw(false, false))
	assert_true(CaptureGate.can_throw(true, false), "hors acte 1 : la capture va au Stockage")
	assert_true(CaptureGate.can_throw(false, true))
	assert_false(CaptureGate.can_throw(true, true))
	var state := _act1_state()
	assert_false(CaptureGate.blocks(state.party, state.flags), "2 Pokémon : place")
	for i: int in 4:
		state.party.add(PokemonFactory.create(_data, &"rattata", 5, GameRng.new(i)))
	assert_true(state.party.is_full())
	assert_true(CaptureGate.blocks(state.party, state.flags))
	state.flags.set_flag(TeamConfiscation.STORAGE_OFFLINE, false)
	assert_false(CaptureGate.blocks(state.party, state.flags))
	assert_false(CaptureGate.blocks(null, state.flags))


func test_the_refusal_text_is_in_the_battle_messages() -> void:
	var texts := BattleText.new()
	texts.load_file()
	assert_eq(texts.get_errors().size(), 0)
	assert_eq(texts.get_template(CaptureGate.REFUSED_KEY), CaptureGate.REFUSED_TEXT)
