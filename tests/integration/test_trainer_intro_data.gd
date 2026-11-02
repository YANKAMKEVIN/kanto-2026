extends GutTest
## Entrée des combats de Dresseur (dossier 05 §3, décision de Kevin du 2026-11-02) sur les vraies
## données : la liste des grands combats vient des données (bloc « card »), chaque Dresseur
## ordinaire a une classe connue (sprite de face), chaque apparence de repli existe, et la fiche
## d'art `docs/design/fiches-assets/entree-dresseurs.md` peut s'appuyer sur ces listes.

## Grands combats attendus (Kevin : Champions d'Arène, rival, Conseil 4, Maître, Giovanni).
const GRAND: Array[StringName] = [
	&"celadon_gym_erika", &"cerulean_gym_misty", &"cinnabar_gym_blaine", &"fuchsia_gym_koga",
	&"giovanni_hideout", &"league_agatha", &"league_bruno", &"league_lance", &"league_lorelei",
	&"pewter_gym_brock", &"rival_cerulean", &"rival_champion", &"rival_lab", &"rival_route22",
	&"rival_route22_final", &"rival_silph", &"rival_ss_anne", &"rival_tower",
	&"saffron_gym_sabrina", &"silph_co_giovanni", &"vermilion_gym_surge",
	&"viridian_gym_giovanni",
]

var _trainers: TrainerLibrary
var _catalog: TrainerIntroCatalog


func before_all() -> void:
	var data := PokemonData.new()
	data.load_dir()
	_trainers = TrainerLibrary.new(data)
	assert_true(_trainers.load_dir(), str(_trainers.get_errors()))
	_catalog = TrainerIntroCatalog.new()
	assert_true(_catalog.load_file(), str(_catalog.get_errors()))


func _grand_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for id: StringName in _trainers.get_ids():
		if _trainers.get_trainer(id).has_card():
			found.append(id)
	found.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return found


func test_grand_battles_come_from_the_data() -> void:
	assert_eq(_grand_ids(), GRAND)


func test_every_rival_battle_is_grand() -> void:
	for id: StringName in _trainers.get_ids():
		var trainer := _trainers.get_trainer(id)
		if trainer.name == "{rival}":
			assert_true(trainer.has_card(), "%s : grand combat" % id)
			assert_eq(trainer.card_portrait, TrainerIntro.RIVAL_ID, String(id))


func test_every_grand_portrait_is_in_the_catalog() -> void:
	for id: StringName in _grand_ids():
		var portrait := _trainers.get_trainer(id).card_portrait
		assert_true(_catalog.has_grand(portrait), "%s : portrait « %s »" % [id, portrait])


func test_every_ordinary_trainer_has_a_class() -> void:
	var used: Dictionary[StringName, bool] = {}
	for id: StringName in _trainers.get_ids():
		var trainer := _trainers.get_trainer(id)
		if trainer.has_card():
			continue
		var class_id := _catalog.class_for(trainer.name)
		assert_ne(class_id, &"", "%s (« %s ») : classe connue" % [id, trainer.name])
		used[class_id] = true
	for class_id: StringName in _catalog.class_ids():
		assert_true(used.has(class_id), "classe « %s » utilisée par un Dresseur" % class_id)


func test_every_fallback_look_exists() -> void:
	var ids: Array[StringName] = _catalog.class_ids()
	ids.append_array(_catalog.grand_ids())
	for id: StringName in ids:
		var sprite := _catalog.world_sprite(id)
		var look := CharacterLook.resolve(sprite)
		assert_true(look.painted, "%s : apparence peinte « %s »" % [id, sprite])
		assert_not_null(TrainerIntroStage.world_texture(sprite), "%s : image de repli" % id)
