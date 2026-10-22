extends GutTest
## Logique pure du mode SPECTRE (jalon 19, T6 ; `jalon-19.md` §2.3) : [GhostRule] (décision
## relue à chaque appel, clé « ghost » des étapes de scène, peur selon le statut) et
## [GhostDisguise] (masque d'identité des événements du camp adverse).

const SCOPE: StringName = &"silph_scope"


# --- GhostRule.is_ghost --------------------------------------------------------------------

func test_ghost_without_the_item() -> void:
	var bag := Bag.new()
	bag.add(&"poke_ball", 5)
	assert_true(GhostRule.is_ghost(SCOPE, bag), "sans l'objet : SPECTRE")


func test_no_ghost_with_the_item() -> void:
	var bag := Bag.new()
	bag.add(SCOPE)
	assert_false(GhostRule.is_ghost(SCOPE, bag), "avec l'objet : combat normal")


func test_empty_item_is_never_a_ghost() -> void:
	assert_false(GhostRule.is_ghost(&"", Bag.new()), "table sans clé")
	assert_false(GhostRule.is_ghost(&"", null), "même sans Sac")


func test_missing_bag_holds_nothing() -> void:
	assert_true(GhostRule.is_ghost(SCOPE, null))


func test_decision_is_read_again_at_each_call() -> void:
	var bag := Bag.new()
	assert_true(GhostRule.is_ghost(SCOPE, bag), "1re rencontre : pas d'objet")
	bag.add(SCOPE)
	assert_false(GhostRule.is_ghost(SCOPE, bag), "2e rencontre : l'objet vient d'arriver")
	bag.remove(SCOPE)
	assert_true(GhostRule.is_ghost(SCOPE, bag), "3e rencontre : l'objet est reparti")


# --- GhostRule.is_ghost_for (étape de scène) -----------------------------------------------

func test_always_is_a_ghost_even_with_the_item() -> void:
	var bag := Bag.new()
	bag.add(SCOPE)
	assert_true(GhostRule.is_ghost_for(GhostRule.ALWAYS, &"", bag), "6F : ghost always")
	assert_true(GhostRule.is_ghost_for(GhostRule.ALWAYS, SCOPE, bag), "always passe avant")
	assert_true(GhostRule.is_ghost_for(GhostRule.ALWAYS, &"", null))


func test_step_without_mode_reads_the_item() -> void:
	var bag := Bag.new()
	assert_true(GhostRule.is_ghost_for(&"", SCOPE, bag))
	bag.add(SCOPE)
	assert_false(GhostRule.is_ghost_for(&"", SCOPE, bag))
	assert_false(GhostRule.is_ghost_for(&"", &"", bag), "ni mode ni objet : combat normal")


func test_known_modes() -> void:
	assert_true(GhostRule.is_known_mode(&"always"))
	assert_true(GhostRule.is_known_mode(&""), "clé absente")
	assert_false(GhostRule.is_known_mode(&"never"))
	assert_false(GhostRule.is_known_mode(&"Always"))


# --- GhostRule.fear_applies ----------------------------------------------------------------

func test_sleep_and_freeze_keep_their_message() -> void:
	assert_false(GhostRule.fear_applies(StatusRules.SLEEP))
	assert_false(GhostRule.fear_applies(StatusRules.FREEZE))


func test_fear_applies_otherwise() -> void:
	assert_true(GhostRule.fear_applies(StatusRules.NONE), "aucun statut")
	assert_true(GhostRule.fear_applies(StatusRules.POISON))
	assert_true(GhostRule.fear_applies(StatusRules.BURN))
	assert_true(GhostRule.fear_applies(StatusRules.PARALYSIS), "la peur passe avant")


func test_every_known_status_is_decided() -> void:
	# Un statut ajouté plus tard doit être classé ici (peur ou message propre).
	var keep_message: Array[StringName] = [StatusRules.SLEEP, StatusRules.FREEZE]
	for status: StringName in StatusRules.KNOWN:
		assert_eq(GhostRule.fear_applies(status), not keep_message.has(status), str(status))


# --- GhostDisguise -------------------------------------------------------------------------

func _foe_event(kind: BattleEvent.Kind) -> BattleEvent:
	var event := BattleEvent.new(kind, BattleEvent.SideId.FOE)
	event.species_id = &"pikachu"
	event.pokemon_name = "Pikachu"
	event.level = 25
	event.gender = Pokemon.Gender.MALE
	event.hp = 40
	event.max_hp = 52
	event.party_index = 0
	return event


func test_mask_hides_species_level_and_gender() -> void:
	var event := _foe_event(BattleEvent.Kind.SENT_OUT)
	assert_true(GhostDisguise.mask(event))
	assert_eq(event.species_id, GhostDisguise.SPECIES)
	assert_eq(event.level, 0, "niveau masqué")
	assert_eq(event.level, GhostDisguise.HIDDEN_LEVEL)
	assert_eq(event.gender, Pokemon.Gender.NONE)
	assert_true(GhostDisguise.is_masked(event), "marqué")
	assert_eq(event.hp, 40, "les PV restent (la jauge)")
	assert_eq(event.max_hp, 52)
	assert_eq(event.party_index, 0)


func test_mask_replaces_the_name_when_given() -> void:
	var event := _foe_event(BattleEvent.Kind.SENT_OUT)
	GhostDisguise.mask(event, "SPECTRE")
	assert_eq(event.pokemon_name, "SPECTRE")
	var unnamed := _foe_event(BattleEvent.Kind.SENT_OUT)
	GhostDisguise.mask(unnamed)
	assert_eq(unnamed.pokemon_name, "Pikachu", "le nom vient du surnom posé par le directeur")


func test_masked_event_never_holds_the_real_species() -> void:
	var event := _foe_event(BattleEvent.Kind.SENT_OUT)
	GhostDisguise.mask(event, "SPECTRE")
	var dump := str(event.to_dict()).to_lower()
	assert_false(dump.contains("pikachu"), dump)
	assert_false(dump.contains("\"level\": 25"), dump)


func test_player_events_are_never_masked() -> void:
	var event := _foe_event(BattleEvent.Kind.SENT_OUT)
	event.side = BattleEvent.SideId.PLAYER
	assert_false(GhostDisguise.mask(event, "SPECTRE"))
	assert_eq(event.species_id, &"pikachu")
	assert_eq(event.level, 25)
	assert_eq(event.pokemon_name, "Pikachu")
	assert_false(GhostDisguise.is_masked(event))


func test_unmasked_and_null_events() -> void:
	assert_false(GhostDisguise.is_masked(_foe_event(BattleEvent.Kind.DAMAGE)))
	assert_false(GhostDisguise.is_masked(null))
	assert_false(GhostDisguise.mask(null))


func test_pseudo_species_is_not_a_real_species() -> void:
	var data := PokemonData.new()
	data.load_dir()
	assert_false(data.has_species(GhostDisguise.SPECIES), "jamais une donnée d'espèce")
