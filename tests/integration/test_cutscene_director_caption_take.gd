extends GutTest
## CutsceneDirector : étapes « caption » (légende de la vraie ExplorationHud, attendue jusqu'à sa
## disparition) et « take » (objet retiré du Sac, sans signal) — jalon-07.md §3.6, T18.
## Ni carte ni joueur : ces étapes n'en ont pas besoin. (Fichier à part de
## test_cutscene_director.gd : l'étape « scare » du T2 y est ajoutée en parallèle.)

const HUD_SCENE := preload("res://game/ui/hud/exploration_hud.tscn")
const TIMEOUT := 6.0
const SCENES := {
	"caption_scene": {"steps": [
		{"set": ["before"]}, {"caption": "POKÉDEX ACTIVÉ"}, {"set": ["after"]},
	]},
	"take_parcel": {"steps": [{"take": "oak_parcel"}, {"set": ["after"]}]},
	"take_two": {"steps": [{"take": "potion", "count": 2}, {"set": ["after"]}]},
}

var _director: CutsceneDirector
var _flags: StoryFlags
var _bag: Bag
var _items: ItemLibrary


func before_each() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"), str(scenes.get_errors()))
	_flags = StoryFlags.new()
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, null, null, null)
	_bag = Bag.new()
	_items = ItemLibrary.new()
	_items.load_dir()


func _await_scene_end() -> void:
	await wait_until(func() -> bool: return not _director.is_running(), TIMEOUT)


func test_caption_is_shown_and_the_scene_waits_until_it_is_hidden() -> void:
	var hud := HUD_SCENE.instantiate() as ExplorationHud
	add_child_autofree(hud)
	_director.set_hud(hud)
	assert_true(_director.play(&"caption_scene"))
	await wait_process_frames(2)
	assert_true(_flags.has_flag(&"before"))
	assert_eq(hud.get_caption().get_text(), "POKÉDEX ACTIVÉ")
	assert_true(hud.get_caption().is_showing(), "légende affichée")
	assert_true(_director.is_running(), "la scène attend la légende")
	assert_false(_flags.has_flag(&"after"))
	hud.hide_caption()
	await _await_scene_end()
	assert_true(_flags.has_flag(&"after"), "reprise après la disparition de la légende")
	assert_push_error_count(0)


func test_caption_without_hud_is_skipped_with_error() -> void:
	_director.play(&"caption_scene")
	await _await_scene_end()
	assert_push_error("pas de HUD pour la légende")
	assert_true(_flags.has_flag(&"after"))


func test_take_removes_the_parcel_from_the_bag() -> void:
	_bag.add(&"poke_ball", 3)
	_bag.add(&"oak_parcel")
	_director.set_inventory(_bag, _items)
	watch_signals(_director)
	_director.play(&"take_parcel")
	await _await_scene_end()
	assert_false(_bag.has(&"oak_parcel"), "le colis a quitté le Sac")
	assert_eq(_bag.count_of(&"poke_ball"), 3, "le reste ne bouge pas")
	assert_signal_not_emitted(_director, "item_given", "aucun toast")
	assert_true(_flags.has_flag(&"after"))
	assert_push_error_count(0)


func test_take_a_count() -> void:
	_bag.add(&"potion", 3)
	_director.set_inventory(_bag, _items)
	_director.play(&"take_two")
	await _await_scene_end()
	assert_eq(_bag.count_of(&"potion"), 1)


func test_take_without_the_item_is_skipped_with_error() -> void:
	_bag.add(&"potion", 1)
	_director.set_inventory(_bag, _items)
	_director.play(&"take_parcel")
	await _await_scene_end()
	assert_push_error("le Sac n'a pas 1 « oak_parcel »")
	_director.play(&"take_two")
	await _await_scene_end()
	assert_push_error("le Sac n'a pas 2 « potion »")
	assert_eq(_bag.count_of(&"potion"), 1, "Sac inchangé")
	assert_true(_flags.has_flag(&"after"))


func test_take_without_a_bag_is_skipped_with_error() -> void:
	_director.play(&"take_parcel")
	await _await_scene_end()
	assert_push_error("pas de Sac pour reprendre")
	assert_true(_flags.has_flag(&"after"))
