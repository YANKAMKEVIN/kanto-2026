extends GutTest
## Jalon 21 (T14, `jalon-21.md` §2.9, §2.13, dossier 24 §7, §15.4, §15.5) : la Maison des Pokémon
## après le sauvetage de M. Fuji (spawn `devant_fuji`, déclencheur d'entrée, Fuji, Osselait,
## dialogues §15.4) et les variantes de Lavanville (§15.5, **seulement** avec `fuji_rescued`).
## Textes mot pour mot (« / » du dossier = deux lignes d'une page).

const Plan := preload("res://tests/helpers/plan_grid.gd")
const HOUSE_PLAN: String = "res://tools/plans/lavanville_maison_pokemon.txt"
## Dossier 24 §15.4 n° 1 à 7 (une page chacun).
const FLUTE_GIVE: Array[String] = [
	"{player}. Tes Pokémon te font confiance, ça se voit.",
	"Un Pokédex se remplit avec des Pokémon. / Une aventure, avec de l'affection.",
	"Prends ceci. Elle t'aidera sur ton chemin.",
]
const AFTER_TEXT: String = "Ma Flûte t'a-t-elle été utile ?"
const SNORLAX_TEXT: String = "Ronflex ? Ha ha… / Il aura bien dormi, au moins."
## Dossier 24 §15.5 : dialogue → [texte avec fuji_rescued, texte d'avant (première page du J19)].
const LAVENDER: Dictionary = {
	&"pokemon_tower_exorcist": ["Les esprits se sont calmés. / On peut de nouveau prier en paix.",
		"Je prie pour ceux qui reposent ici… / et pour ceux qui sont montés."],
	&"pokemon_house_kid": ["Papy Fuji est rentré ! / Il dit que c'est grâce à toi.",
		"Ces Pokémon n'avaient plus de Dresseur. / Maintenant, ils nous ont nous."],
	&"pokemon_house_man": ["Ces gens en noir ont quitté la Tour. / Bon débarras.",
		"M. Fuji m'a dit avoir vu des gens / monter à la Tour, la nuit."],
	&"pokemon_house_girl": ["Osselait ne pleure plus la nuit. / Je crois qu'il sait, pour sa maman.",
		"Osselait attend sa maman."],
	&"lavender_center_gentleman": ["Le spectre de la Tour a disparu, paraît-il. / "
		+ "Quelqu'un a apaisé son âme.",
		"Des hommes en noir, j'en ai vu traîner / autour du Casino de Céladopole."],
}

var _dialogues := DialogueLibrary.new()


func before_all() -> void:
	_dialogues.load_dir()


func _flags(list: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in list:
		flags.set_flag(flag)
	return flags


func _text(page: DialoguePage) -> String:
	return page.text.replace("\n", " / ")


func _lines(variant: DialogueVariant) -> Array[String]:
	var out: Array[String] = []
	for page: DialoguePage in variant.pages:
		out.append(_text(page))
	return out


func _has(items: Array[StringName]) -> Callable:
	return func(id: StringName) -> bool: return items.has(id)


# --- Carte -----------------------------------------------------------------------------------


func test_house_has_the_devant_fuji_spawn_and_the_entry_trigger() -> void:
	var map := (load(MapCatalog.scene_path(&"pokemon_house")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	assert_true(map.has_spawn(&"devant_fuji"))
	assert_eq(map.get_spawn_cell(&"devant_fuji"), Vector2i(7, 4), "devant Fuji (7, 3)")
	assert_false(map.get_grid().is_solid(Vector2i(7, 4)))
	# Premier pas depuis le paillasson : les trois cases (6..8, 7), sans direction.
	for x: int in range(6, 9):
		var list := map.get_triggers().get_at(Vector2i(x, 7))
		assert_eq(list.size(), 1, "case (%d, 7)" % x)
		if list.is_empty():
			continue
		assert_eq(list[0].cutscene_id, &"pokemon_house_flute")
		assert_eq(list[0].direction, Vector2i.ZERO, "sans direction")
	assert_eq(map.get_triggers().size(), 3, "aucun autre déclencheur")
	# L'arrivée de la porte (7, 8) n'est pas un déclencheur : on entre, puis on fait un pas.
	assert_true(map.get_triggers().get_at(Vector2i(7, 8)).is_empty())
	var plan := Plan.new()
	assert_true(plan.load_file(HOUSE_PLAN), plan.error)
	assert_eq(plan.cell_of("devant_fuji"), Vector2i(7, 4))
	assert_eq(plan.cell_of("mr_fuji"), Vector2i(7, 3))


func test_fuji_and_osselait_in_the_house() -> void:
	var roster := NpcRoster.load_for_map(&"pokemon_house")
	var before: Dictionary = {}
	for spec: NpcSpec in roster.get_present(null):
		before[spec.id] = spec
	assert_false(before.has(&"mr_fuji"), "Fuji absent avant le sauvetage")
	var after: Dictionary = {}
	for spec: NpcSpec in roster.get_present(_flags([&"fuji_rescued"])):
		after[spec.id] = spec
	var fuji: NpcSpec = after[&"mr_fuji"]
	assert_eq(fuji.cell, Vector2i(7, 3), "près de la fenêtre [D]")
	assert_eq(fuji.facing, Vector2i.DOWN)
	assert_eq(fuji.sprite, &"mr_fuji")
	assert_eq(fuji.dialogue, &"pokemon_house_fuji")
	assert_eq(fuji.if_flags, [&"fuji_rescued"] as Array[StringName])
	var bone: NpcSpec = before[&"osselait"]
	assert_eq(bone.sprite, &"pokemon/cubone", "Osselait du monde (série 23)")
	assert_eq(bone.dialogue, &"", "sans dialogue de don")
	var girl: NpcSpec = before[&"fille"]
	assert_lte(absi(bone.cell.x - girl.cell.x) + absi(bone.cell.y - girl.cell.y), 2,
		"près de la fille")
	assert_true(before.has(&"rondoudou") and before.has(&"nidoran_f"), "cris inchangés")
	assert_eq(after.size(), before.size() + 1, "Fuji seul s'ajoute")


# --- Dialogues §15.4 -------------------------------------------------------------------------


func test_flute_dialogues_word_for_word() -> void:
	assert_eq(_lines(_dialogues.get_dialogue(&"fuji_flute_give").variants[0]), FLUTE_GIVE)
	var received := _dialogues.get_dialogue(&"fuji_flute_received")
	assert_true(received.narration, "§15.4 n° 4 : système")
	assert_eq(_lines(received.variants[0]), ["{player} reçoit la Poké Flûte !"] as Array[String])
	assert_eq(_lines(_dialogues.get_dialogue(&"fuji_flute_explain").variants[0]),
		["Sa mélodie réveille les Pokémon endormis. / Même les plus gros dormeurs."] as Array[String])


func test_fuji_dialogue_picks_by_state() -> void:
	var dialogue := _dialogues.get_dialogue(&"pokemon_house_fuji")
	var none := _has([])
	var flute := _has([&"poke_flute"])
	# Sauvé, sans Flûte : la remise (scène), quoi qu'il arrive ensuite.
	var give := dialogue.pick(_flags([&"fuji_rescued"]), null, 0, Callable(), none)
	assert_eq(give.cutscene, &"pokemon_house_flute", "remise par le dialogue")
	var give_woken := dialogue.pick(_flags([&"fuji_rescued", &"snorlax_route_12_woken"]), null,
		0, Callable(), none)
	assert_eq(give_woken.cutscene, &"pokemon_house_flute", "la Flûte d'abord")
	# Avec la Flûte : §15.4.6 ; avec un Ronflex réveillé : §15.4.7.
	var talk := dialogue.pick(_flags([&"fuji_rescued", &"got_poke_flute"]), null, 0,
		Callable(), flute)
	assert_eq(_lines(talk), [AFTER_TEXT] as Array[String], "§15.4 n° 6")
	assert_eq(talk.cutscene, &"")
	for woken: StringName in [&"snorlax_route_12_woken", &"snorlax_route_16_woken"]:
		var variant := dialogue.pick(_flags([&"fuji_rescued", &"got_poke_flute", woken]), null,
			0, Callable(), flute)
		assert_eq(_lines(variant), [SNORLAX_TEXT] as Array[String], "%s : §15.4 n° 7" % woken)
	var both := dialogue.pick(_flags([&"fuji_rescued", &"got_poke_flute",
		&"snorlax_route_12_woken", &"snorlax_route_16_woken"]), null, 0, Callable(), flute)
	assert_eq(_lines(both), [SNORLAX_TEXT] as Array[String])


func test_flute_scene_exists_and_is_gated() -> void:
	var library := CutsceneLibrary.new()
	library.load_dir()
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var scene := library.get_cutscene(&"pokemon_house_flute")
	assert_not_null(scene)
	assert_eq(scene.variants.size(), 1)
	assert_eq(scene.variants[0].if_flags, [&"fuji_rescued"] as Array[StringName])
	# Jalon 21 (plan §2.9, T12-T14) : la POSSESSION fait foi (« unless_items »), pas le drapeau ;
	# `got_poke_flute` est levé par l'étape `give … set` elle-même.
	assert_eq(scene.variants[0].unless_flags, [] as Array[StringName])
	assert_eq(scene.variants[0].unless_items, [&"poke_flute"] as Array[StringName])
	var give_step: CutsceneStep = null
	for step: CutsceneStep in scene.variants[0].steps:
		if step.kind == CutsceneStep.Kind.GIVE:
			give_step = step
	assert_not_null(give_step, "étape give")
	if give_step != null:
		assert_eq(give_step.flags, [&"got_poke_flute"] as Array[StringName], "give + set")
	var empty := Bag.new()
	var with_flute := Bag.new()
	with_flute.add(&"poke_flute")
	assert_null(scene.pick(_flags([]), empty), "sans sauvetage : rien")
	assert_null(scene.pick(_flags([&"fuji_rescued", &"got_poke_flute"]), with_flute),
		"déjà reçue : rien")
	assert_null(scene.pick(_flags([&"fuji_rescued"]), with_flute),
		"Flûte déjà dans le Sac sans drapeau : rien")
	assert_not_null(scene.pick(_flags([&"fuji_rescued", &"got_poke_flute"]), empty),
		"drapeau sans Flûte : remise")
	assert_not_null(scene.pick(_flags([&"fuji_rescued"]), empty))


# --- Lavanville après le sauvetage (§15.5) ---------------------------------------------------


func test_lavender_variants_only_with_fuji_rescued() -> void:
	for id: StringName in LAVENDER:
		var texts: Array = LAVENDER[id]
		var dialogue := _dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		var rescued := dialogue.pick(_flags([&"fuji_rescued", &"tower_stairs_open"]))
		assert_eq(_lines(rescued), [texts[0]] as Array[String], "%s : §15.5 mot pour mot" % id)
		# Sans le drapeau : jamais le texte du sauvetage, premier texte du J18 / J19 intact.
		var plain := dialogue.pick(_flags([&"tower_stairs_open", &"pokemon_house_kid_talked"]))
		assert_ne(_lines(plain), [texts[0]] as Array[String], "%s : avant le sauvetage" % id)
		assert_eq(_text(plain.pages[0]), texts[1], "%s : texte d'avant inchangé" % id)
		assert_eq(dialogue.variants[0].if_flags, [&"fuji_rescued"] as Array[StringName],
			"%s : la variante du sauvetage est en tête" % id)
