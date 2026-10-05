extends GutTest
## Retours de Kevin au T5 (jalon-07.md §15.21) : « des personnages courent et marchent en même
## temps ». Règle vérifiée sur **toutes les données** (habitants à routine de `data/npcs/`,
## acteurs des étapes « move » de `data/cutscenes/`, PNJ créés par une scène) : chaque apparence
## **peinte** qui se déplace marche avec une animation de marche calée sur la durée d'un pas
## (un cycle de 4 images = 2 cases, un appui de pied par case, comme le héros) ; une étape qui
## demande la course ne vise qu'une apparence qui a une vraie course (planche de course), à la
## cadence de course ; aucune planche peinte sans course n'a d'animation « run ».

const NPC_SCENE := "res://game/world/npc/npc.tscn"
const DIRECTIONS: Array[String] = ["down", "left", "right", "up"]

## Apparence de chaque PNJ (toutes cartes) : identifiant → sprite.
var _sprites: Dictionary = {}
## Apparences qui se déplacent : sprite → vrai si une étape leur demande de courir.
var _movers: Dictionary = {}
## Acteurs d'étapes « move » introuvables dans les données (aucun attendu).
var _unknown: Array[StringName] = []


func before_all() -> void:
	var dir := DirAccess.open(NpcRoster.DATA_DIR)
	for file: String in dir.get_files():
		if not file.ends_with(".json"):
			continue
		var roster := NpcRoster.new()
		roster.load_file(NpcRoster.DATA_DIR.path_join(file))
		for spec: NpcSpec in roster.get_all():
			_sprites[spec.id] = spec.sprite
			if spec.has_route():
				_note(spec.sprite, false)
	var library := CutsceneLibrary.new()
	library.load_dir()
	for id: StringName in library.get_ids():
		for variant: CutsceneVariant in library.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.SPAWN and step.spec != null:
					_sprites[step.spec.id] = step.spec.sprite
	for id: StringName in library.get_ids():
		for variant: CutsceneVariant in library.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind != CutsceneStep.Kind.MOVE:
					continue
				for actor: StringName in [step.actor, step.follower]:
					if actor.is_empty() or actor == NpcRoster.PLAYER_ID \
							or CutsceneStep.is_alias(actor):
						continue
					if not _sprites.has(actor):
						_unknown.append(actor)
						continue
					_note(_sprites[actor], step.run)


func _note(sprite: StringName, run: bool) -> void:
	_movers[sprite] = bool(_movers.get(sprite, false)) or run


func test_movers_were_found() -> void:
	assert_eq(_unknown, [] as Array[StringName], "acteurs des scènes connus")
	for sprite: StringName in [&"courier", &"old_man", &"kid", &"pokemon/rattata",
			&"traveler"]:
		assert_true(_movers.has(sprite), "%s se déplace" % sprite)


func test_every_moving_painted_look_walks_at_the_step_cadence() -> void:
	for sprite: StringName in _movers:
		var look := CharacterLook.resolve(sprite)
		if not look.painted:
			continue
		var frames := load(look.frames_path) as SpriteFrames
		for dir: String in DIRECTIONS:
			var walk := StringName("walk_" + dir)
			assert_true(frames.has_animation(walk), "%s : %s" % [sprite, walk])
			assert_eq(frames.get_frame_count(walk), 4, "%s : %s" % [sprite, walk])
			assert_almost_eq(frames.get_frame_count(walk) / frames.get_animation_speed(walk),
				2.0 * Grid.WALK_STEP_DURATION, 0.001,
				"%s : un cycle de marche = deux pas de marche" % sprite)


func test_a_scene_asks_to_run_only_a_look_that_really_runs() -> void:
	for sprite: StringName in _movers:
		if not _movers[sprite]:
			continue
		var frames := load(CharacterLook.resolve(sprite).frames_path) as SpriteFrames
		for dir: String in DIRECTIONS:
			var run := StringName("run_" + dir)
			assert_true(frames.has_animation(run), "%s court : il lui faut %s" % [sprite, run])
			if CharacterLook.resolve(sprite).painted and frames.has_animation(run):
				assert_almost_eq(frames.get_frame_count(run) / frames.get_animation_speed(run),
					2.0 * Grid.RUN_STEP_DURATION, 0.001,
					"%s : un cycle de course = deux pas de course" % sprite)


## Aucune planche peinte sans planche de course n'a d'animation « run » (sinon : poses de
## marche à la cadence de course) ; [method Npc.can_run] le reflète.
func test_painted_looks_run_only_with_a_run_sheet() -> void:
	for sprite: StringName in _movers:
		var look := CharacterLook.resolve(sprite)
		if not look.painted:
			continue
		var frames := load(look.frames_path) as SpriteFrames
		var npc := (load(NPC_SCENE) as PackedScene).instantiate() as Npc
		var spec := NpcSpec.new()
		spec.id = &"gait"
		spec.sprite = sprite
		npc.setup(spec)
		add_child_autofree(npc)
		var walk := frames.get_frame_texture(&"walk_down", 0) as AtlasTexture
		var has_run := frames.has_animation(&"run_down")
		assert_eq(npc.can_run(), has_run, "%s : can_run" % sprite)
		if has_run:
			var run := frames.get_frame_texture(&"run_down", 0) as AtlasTexture
			assert_ne(run.atlas, walk.atlas, "%s : la course vient d'une autre planche" % sprite)
