extends GutTest
## Intro « révélation » et Ball refusée (jalon 21, `jalon-21.md` §2.5, §2.6, T10, T11 ; dossier 24
## §5) avec la vraie scène Boot sur la carte réelle `pokemon_tower_3f`, texte et animations de
## combat instantanés, combat lancé par une étape de scène « wild_battle » :
## - avec le Scope : la silhouette du SPECTRE d'abord, « Le Scope Sylphe révèle l'identité du
##   SPECTRE ! », le fondu vers Ossatueur, puis « C'est un Ossatueur ! » au lieu du texte
##   d'apparition ; événements non masqués ; Ossatueur « vu » au Pokédex ;
## - « uncatchable » : une Ball choisie est refusée par « Ce Pokémon ne peut pas être capturé. »,
##   sans être retirée ni jouer de tour ;
## - sans le Scope : SPECTRE du J19, « reveal » ignorée, refus de Ball du SPECTRE.

const STARTER := &"charmander"
const LEVEL := 20
const PARTY_SEED := 777
const MAP_ID := &"pokemon_tower_3f"
const SPAWN := &"arrivee_T23"
const START := Vector2i(4, 9)
const SCOPE := &"silph_scope"
const BALL := &"poke_ball"
const FOE := &"marowak"
const FADE := 0.05
const TIMEOUT := 12.0
const REVEALED := "Le Scope Sylphe révèle l'identité du SPECTRE !"
const UNCATCHABLE := "Ce Pokémon ne peut pas être capturé."
const GHOST_REFUSED := "Pas question de lancer une Ball sur… ça. Elle passerait au travers."
const SCENES := {
	"j21_reveal": {"steps": [
		{"wild_battle": "marowak", "level": 30, "ghost_unless_item": "silph_scope",
			"reveal": true, "uncatchable": true, "flee": ["j21_reveal_fled"]},
	]},
}

var _boot: Boot
var _player: Player
var _fades: Array[float] = []
var _shown_lines: Array[String] = []
## Image adverse affichée au moment de chaque ligne.
var _images_at_line: Array[String] = []
var _events: Array[BattleEvent] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_shown_lines.clear()
	_images_at_line.clear()
	_events.clear()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.start_map = MAP_ID
	_boot.start_spawn = SPAWN
	_boot.start_facing = Vector2i.RIGHT
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	await wait_process_frames(2)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	_boot.get_battle_hud().get_message_banner().message_shown.connect(_on_line)
	_boot.get_battle_director().event_played.connect(
		func(event: BattleEvent) -> void: _events.append(event))
	var library := _boot.get_cutscene_library()
	assert_true(library.add_from_dict(SCENES, "test"), str(library.get_errors()))
	assert_true(library.check_species(_boot.get_pokemon_data()))


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]


func _on_line(text: String, _wait: bool) -> void:
	_shown_lines.append(text)
	var sprite := _boot.get_battle_stage().get_sprite(BattleEvent.SideId.FOE)
	var path := ""
	if sprite != null and sprite.visible and sprite.texture != null:
		var texture := sprite.texture
		path = (texture as AtlasTexture).atlas.resource_path if texture is AtlasTexture \
			else texture.resource_path
	_images_at_line.append(path)


func _new_tower_game(scope: bool) -> void:
	GameState.new_game(21)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = STARTER
	var party := Party.new()
	party.add(PokemonFactory.create(_boot.get_pokemon_data(), STARTER, LEVEL,
		GameRng.new(PARTY_SEED)))
	GameState.party = party
	GameState.party.get_lead().stats[&"spe"] = 999
	GameState.bag.add(BALL, 5)
	if scope:
		GameState.bag.add(SCOPE)
	var map := _boot.get_map()
	_player.enter_map(map.get_grid(), START, Vector2i.RIGHT, map.get_pixel_rect())


## Lance la scène, attend le premier choix, choisit une Ball dans le Sac, attend le retour de la
## grille, puis fuit jusqu'à la fin de la scène. Renvoie le combat (après le refus).
func _play_ball_then_flee() -> Array:
	var cutscenes := _boot.get_cutscene_director()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	assert_true(cutscenes.play(&"j21_reveal"), "scène lancée")
	await wait_until(func() -> bool:
		var b := battles.get_battle()
		return b != null and b.get_state() == Battle.State.CHOOSING \
			and hud.get_zone() == BattleHud.Zone.ACTIONS, 5.0)
	var battle := battles.get_battle()
	hud.action_selected.emit(ActionGrid.BAG)
	await wait_until(func() -> bool:
		var panel := battles.get_bag_panel()
		return panel != null and not panel.item_chosen.get_connections().is_empty(), 5.0)
	battles.get_bag_panel().item_chosen.emit(BALL)
	await wait_until(func() -> bool: return hud.get_zone() == BattleHud.Zone.ACTIONS, 5.0)
	var turn := battle.get_turn()
	var state := battle.get_state()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while cutscenes.is_running() and Time.get_ticks_msec() < deadline:
		var current := battles.get_battle() if battles.is_running() else null
		if current != null and current.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.ACTIONS:
			hud.action_selected.emit(ActionGrid.RUN)
		await wait_process_frames(1)
	assert_false(cutscenes.is_running(), "la scène s'est terminée")
	return [battle, turn, state]


func test_with_the_scope_the_ghost_is_revealed_and_the_ball_refused() -> void:
	_new_tower_game(true)
	watch_signals(GameState.pokedex)
	var result: Array = await _play_ball_then_flee()
	var battle: Battle = result[0]
	var name := _boot.get_pokemon_data().get_species(FOE).name
	# Intro révélation.
	var revealed_at := _shown_lines.find(REVEALED)
	var species_at := _shown_lines.find("C'est un %s !" % name)
	assert_gt(revealed_at, -1, "« Le Scope Sylphe révèle… »")
	assert_gt(species_at, revealed_at, "« C'est un Ossatueur ! » ensuite")
	assert_eq(_images_at_line[revealed_at], GhostDisguise.TEXTURE_PATH,
		"la silhouette pendant « révèle »")
	assert_ne(_images_at_line[species_at], GhostDisguise.TEXTURE_PATH, "Ossatueur ensuite")
	assert_ne(_images_at_line[species_at], "")
	assert_does_not_have(_shown_lines, "Un %s sauvage apparaît !" % name)
	assert_does_not_have(_shown_lines, "Un SPECTRE apparaît !")
	assert_null(_boot.get_battle_stage().get_reveal_overlay(), "silhouette libérée")
	# Événements non masqués, Pokédex.
	assert_gt(_events.size(), 0)
	for event: BattleEvent in _events:
		assert_false(event.disguised, "événement non masqué : %s" % event.to_dict())
	assert_true(GameState.pokedex.is_seen(FOE), "Ossatueur « vu »")
	# Ball refusée.
	assert_has(_shown_lines, UNCATCHABLE)
	assert_does_not_have(_shown_lines, GHOST_REFUSED)
	assert_eq(result[1], 0, "aucun tour joué au refus")
	assert_eq(result[2], Battle.State.CHOOSING, "le combat attend un nouveau choix")
	assert_eq(GameState.bag.count_of(BALL), 5, "Ball non consommée")
	assert_eq(battle.get_outcome(), Battle.Outcome.FLED)
	assert_true(GameState.flags.has_flag(&"j21_reveal_fled"), "« flee » levé")
	assert_push_error_count(0)


func test_without_the_scope_it_stays_a_ghost() -> void:
	_new_tower_game(false)
	watch_signals(GameState.pokedex)
	await _play_ball_then_flee()
	assert_does_not_have(_shown_lines, REVEALED, "« reveal » ignorée")
	assert_has(_shown_lines, "Un SPECTRE apparaît !")
	assert_has(_shown_lines, GHOST_REFUSED, "refus du SPECTRE gardé")
	assert_does_not_have(_shown_lines, UNCATCHABLE)
	assert_eq(GameState.bag.count_of(BALL), 5)
	assert_signal_not_emitted(GameState.pokedex, "recorded", "aucun « vu »")
	assert_push_error_count(0)
