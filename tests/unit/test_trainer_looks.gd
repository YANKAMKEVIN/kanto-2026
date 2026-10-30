extends GutTest
## Chantier JR (dossier-joueuse-rivale.md, JR-1, JR-2 ; dossier 13 §3.6) : les assets du joueur
## et du rival suivent `GameState.player_look` et `GameState.rival_look` ; une apparence inconnue
## rend le héros ou le rival garçon ; les données gardent `"sprite": "rival"`.

var _player_look: StringName
var _rival_look: StringName


func before_each() -> void:
	_player_look = GameState.player_look
	_rival_look = GameState.rival_look


func after_each() -> void:
	GameState.player_look = _player_look
	GameState.rival_look = _rival_look


func test_every_known_look_has_all_its_assets() -> void:
	for look: StringName in GameState.PLAYER_LOOKS:
		for path: String in [TrainerLooks.thrower_path(look), TrainerLooks.bust_path(look),
				TrainerLooks.player_portrait_path(look),
				CharacterLook.painted_frames_path(TrainerLooks.player_sprite(look))]:
			assert_true(ResourceLoader.exists(path), "%s : %s" % [look, path])
	for look: StringName in GameState.RIVAL_LOOKS:
		for path: String in [TrainerLooks.rival_portrait_path(look),
				CharacterLook.painted_frames_path(TrainerLooks.rival_sprite(look))]:
			assert_true(ResourceLoader.exists(path), "%s : %s" % [look, path])


func test_the_heroine_and_the_girl_rival_use_their_own_assets() -> void:
	assert_eq(TrainerLooks.player_sprite(&"heroine"), &"player_heroine")
	assert_eq(TrainerLooks.rival_sprite(&"rivale"), &"rival_heroine")
	assert_ne(TrainerLooks.thrower_path(&"heroine"), TrainerLooks.thrower_path(&"hero"))
	assert_ne(TrainerLooks.bust_path(&"heroine"), TrainerLooks.bust_path(&"hero"))
	assert_ne(TrainerLooks.rival_portrait_path(&"rivale"), TrainerLooks.rival_portrait_path(&"rival"))


func test_an_unknown_look_gives_the_boy_assets() -> void:
	assert_eq(TrainerLooks.player_sprite(&"villain"), Player.LOOK_SPRITE)
	assert_eq(TrainerLooks.rival_sprite(&""), &"rival")
	assert_eq(TrainerLooks.thrower_path(&"x"), BattleStage.THROWER_TEXTURE.resource_path)
	assert_eq(TrainerLooks.bust_path(&"x"), MenuArt.HERO_BUST_PATH)


func test_only_the_rival_data_sprite_is_replaced() -> void:
	assert_eq(TrainerLooks.world_sprite(&"rival", &"rivale"), &"rival_heroine")
	assert_eq(TrainerLooks.world_sprite(&"rival", &"rival"), &"rival")
	assert_eq(TrainerLooks.world_sprite(&"oak", &"rivale"), &"oak")


func test_game_code_reads_the_looks_from_game_state() -> void:
	GameState.player_look = &"heroine"
	assert_eq(Player.look_sprite(), &"player_heroine")
	assert_eq(MenuArt.hero_bust().resource_path, TrainerLooks.bust_path(&"heroine"))
	assert_eq(BattleStage.thrower_texture().resource_path,
		TrainerLooks.thrower_path(&"heroine"))
	GameState.player_look = &"hero"
	assert_eq(Player.look_sprite(), Player.LOOK_SPRITE)
	assert_eq(BattleStage.thrower_texture(), BattleStage.THROWER_TEXTURE)


func test_the_save_summary_reads_the_look() -> void:
	assert_eq(SaveSummary.from_save({"player_look": "heroine"}).player_look, &"heroine")
	assert_eq(SaveSummary.from_save({}).player_look, &"hero")


func test_a_rival_npc_wears_the_chosen_look() -> void:
	GameState.rival_look = &"rivale"
	var spec := NpcSpec.new()
	spec.id = &"rival"
	spec.cell = Vector2i(5, 5)
	spec.sprite = &"rival"
	var npc := (load("res://game/world/npc/npc.tscn") as PackedScene).instantiate() as Npc
	npc.setup(spec)
	add_child_autofree(npc)
	var sprite := npc.get_node("%Sprite") as AnimatedSprite2D
	assert_eq(sprite.sprite_frames.resource_path,
		CharacterLook.painted_frames_path(&"rival_heroine"))
	assert_eq(spec.sprite, &"rival", "les données gardent « rival »")
