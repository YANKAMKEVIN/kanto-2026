extends GutTest
## Défaite dans la Ligue (jalon 30 T8, `jalon-30.md` §2.2, §5), vraie partie (départ
## `league_agatha` : Olga et Aldo battus) : perdre contre Agatha → drapeaux de la tentative et
## `beaten_*` de la Ligue effacés **avant** le réveil, réveil soigné au point de repos (Plateau ;
## Centre de Jadielle tant que le hall du J29 n'est pas fusionné), sauvegarde écrite au réveil,
## rien de perdu (Badges, objets, Pokémon, argent) ; nouvelle tentative depuis Olga.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/league_agatha.json"
const WEAK_START := "res://tools/debug_start/league_weak.json"
const SAVE_PATH := "user://test_league_defeat_save.json"
const BADGES: Array[StringName] = [&"badge_boulder", &"badge_cascade", &"badge_thunder",
	&"badge_rainbow", &"badge_soul", &"badge_marsh", &"badge_volcano", &"badge_earth"]

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


## Point de réveil attendu : le Centre du Plateau s'il existe (J29), sinon celui du départ.
func _rest_map() -> StringName:
	return LeagueDirector.REST_MAP if MapCatalog.has_map(LeagueDirector.REST_MAP) \
		else &"viridian_center"


## Équipe gardée (six Pokémon) mais un seul debout, à 1 PV : la défaite est assurée.
func _one_hp_left() -> void:
	var members := GameState.party.get_all()
	for i: int in members.size():
		members[i].hp = 1 if i == 0 else 0


func test_defeat_against_agatha_resets_the_attempt() -> void:
	await _play.start(START, _one_hp_left)
	assert_eq(_play.map_id(), &"league_agatha")
	assert_eq(LeagueAttempt.current_stage(GameState.flags), 2, "Agatha à affronter")
	var money := GameState.money
	var restores: int = (GameState.bag as Bag).count_of(&"full_restore")
	var size := GameState.party.size()
	await _play.step(Vector2i.UP)
	assert_true(_play.boot.get_cutscene_director().is_running(), "appel d'Agatha")
	assert_true(await _play.run_scene(), "combat contre Agatha")
	assert_true(_play.pages().has("Je suis Agatha. Ce vieux Chen ne jure que par toi ?"))
	assert_false(_play.pages().has("Hé hé… Tu iras loin, petit. Va voir Peter."),
		"pas de réplique « vaincue »")
	for flag: StringName in LeagueAttempt.temporary_flags() + LeagueDirector.beaten_flags():
		assert_false(GameState.flags.has_flag(flag), "%s effacé" % flag)
	for badge: StringName in BADGES:
		assert_true(GameState.flags.has_flag(badge), "%s gardé" % badge)
	assert_eq(_play.map_id(), _rest_map(), "réveil au point de repos")
	assert_eq(_play.player.get_cell(), _play.boot.get_map().get_spawn_cell(&"heal"))
	assert_eq(GameState.party.size(), size, "aucun Pokémon perdu")
	for pokemon: Pokemon in GameState.party.get_all():
		assert_eq(pokemon.hp, pokemon.max_hp(), "équipe soignée")
		assert_eq(pokemon.status, &"", "statuts soignés")
	assert_eq((GameState.bag as Bag).count_of(&"full_restore"), restores, "Sac intact")
	assert_eq(GameState.money, money, "argent intact")
	var saved := _play.saved()
	assert_eq(saved.get("map", ""), String(_rest_map()), "réveil écrit")
	for flag: StringName in LeagueAttempt.temporary_flags():
		assert_false((saved.get("flags", []) as Array).has(String(flag)), "%s non écrit" % flag)
	# Nouvelle tentative : tout recommence chez Olga.
	await SceneRouter.change_map(&"league_lorelei", &"from_lobby", Vector2i.UP)
	await wait_process_frames(3)
	assert_true(LeagueAttempt.is_active(GameState.flags))
	assert_eq(LeagueAttempt.current_stage(GameState.flags), 0, "depuis Olga")
	assert_push_error_count(0)


func test_the_weak_start_loses_against_lorelei() -> void:
	await _play.start(WEAK_START)
	assert_eq(_play.map_id(), &"league_lorelei")
	assert_true(LeagueAttempt.is_active(GameState.flags))
	await _play.step(Vector2i.UP)
	assert_true(await _play.run_scene(), "combat contre Olga")
	assert_false(LeagueAttempt.is_active(GameState.flags))
	assert_eq(_play.map_id(), _rest_map())
	assert_push_error_count(0)
