extends GutTest
## Entrée des combats de Dresseur (dossier 05 §3, décision de Kevin du 2026-11-02) sur les vraies
## données : la liste des grands combats vient des données (bloc « card »), chaque Dresseur
## ordinaire a une classe connue (sprite de face), chaque apparence de repli existe, et la fiche
## d'art `docs/design/fiches-assets/entree-dresseurs.md` peut s'appuyer sur ces listes.

## Grands combats attendus (Kevin : Champions d'Arène, rival, Conseil 4, Maître, Giovanni).
const GRAND: Array[StringName] = [
	&"bell_tower_dante_1", &"celadon_gym_erika", &"cerulean_gym_misty", &"cinnabar_gym_blaine",
	&"fuchsia_gym_koga", &"giovanni_hideout", &"goldenrod_radio_tower_admin_cenere", &"league_agatha",
	&"league_bruno", &"league_lance", &"league_lorelei", &"mahogany_hideout_b3f_brace",
	&"mt_silver_dante_2", &"mt_silver_rival_final", &"pewter_gym_brock", &"rival_cerulean",
	&"rival_champion", &"rival_lab", &"rival_route22", &"rival_route22_final", &"rival_silph",
	&"rival_ss_anne", &"rival_tower", &"saffron_gym_sabrina", &"silph_co_giovanni",
	&"slowpoke_well_admin_brace", &"vermilion_gym_surge", &"viridian_gym_giovanni",
	&"whirl_islands_cenere",
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
			assert_true(trainer.card_portrait in [TrainerIntro.RIVAL_ID, TrainerIntro.RIVAL_WINTER_ID], String(id))


## Rival d'hiver (Mont Argenté) : la rivale a sa propre tenue, partout (monde, combat, VS).
func test_winter_rival_follows_the_rival_look() -> void:
	assert_eq(TrainerLooks.world_sprite(&"rival_hiver", &"rival"), &"rival_hiver")
	assert_eq(TrainerLooks.world_sprite(&"rival_hiver", &"rivale"), &"rivale_hiver")
	var trainer := _trainers.get_trainer(&"mt_silver_rival_final")
	var party := Party.new()
	var boy := TrainerIntro.build(trainer, party, _catalog, &"rival")
	assert_eq([boy.sprite_id, boy.portrait_id, boy.foe_title], [&"rival_hiver", &"rival_hiver", "Rival"])
	var girl := TrainerIntro.build(trainer, party, _catalog, &"rivale")
	assert_eq([girl.sprite_id, girl.portrait_id, girl.foe_title], [&"rivale_hiver", &"rivale_hiver", "Rivale"])
	assert_eq(girl.world_sprite, &"rivale_hiver")


func test_rival_titles() -> void:
	assert_eq(_trainers.get_trainer(&"rival_champion").card_title, "Champion de la Ligue")
	assert_eq(_trainers.get_trainer(&"rival_champion").card_title_rivale, "Championne de la Ligue")
	for id: StringName in [&"rival_lab", &"rival_route22", &"rival_tower", &"rival_silph"]:
		assert_eq(_trainers.get_trainer(id).card_title, "Rival", String(id))


func test_female_grunts_have_their_own_class() -> void:
	var female := 0
	for id: StringName in _trainers.get_ids():
		if _trainers.get_trainer(id).battle_class == &"sbire_rocket_f":
			female += 1
	# 11 à Kanto, 3 au JOH6 (péage Q, alarme 2 du B1F, Sbire S du B2F d'Acajou), 2 au JOH3 (Route 37 de nuit, Souterrain de Doublonville). JOH4 : + le Sbire F du
	# Puits Ramoloss (B1F). JOH7 : le Sbire U des Îles Tourbillon et Cenere (classe de Sbire femme
	# [D] tant que le JOH5 n'a pas de classe d'admin). JOH5 : + 3 Sbires F de la Tour Radio (J, L, N)
	# et Cenere (apparence rocket_grunt_f [D]). JOH6 : + 3 (péage Q, alarme 2, Sbire S).
	# JOH8 : + le Sbire W de la Tour Carillon. JOH9 : + le Sbire Y du 1F du Mont Argenté.
	# Cenere a sa propre carte depuis le 2026-11-05 (buste VS et sprites peints) : 2 de moins.
	assert_eq(female, 25, "25 Sbires Rocket femmes (apparence du monde rocket_grunt_f)")


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
		var class_id := _catalog.class_of(trainer)
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


## Les 8 Champions d'Arène (étape 2 de l'entrée, 2026-11-02) : art complet (debout, lancer,
## buste), main du lancer et réglage du buste dans les données, taille réelle relative cohérente.
const CHAMPIONS: Array[StringName] = [&"pierre", &"ondine", &"major_bob", &"erika", &"koga",
	&"morgane", &"auguste", &"giovanni"]


func test_every_champion_has_complete_art() -> void:
	for id: StringName in CHAMPIONS:
		var front := _catalog.front_dir + String(id) + _catalog.extension
		var throw := _catalog.front_dir + String(id) + _catalog.throw_suffix + _catalog.extension
		var bust := _catalog.portrait_dir + String(id) + _catalog.extension
		for path: String in [front, throw, bust]:
			assert_true(ResourceLoader.exists(path), "%s : %s" % [id, path])
		assert_ne(_catalog.hand_of(id), _catalog.point("foe_hand"), "%s : main du lancer" % id)
		assert_ne(_catalog.bust_adjust(id), Vector3(0.0, 0.0, 1.0), "%s : réglage du buste" % id)


## Étape 4 (fiche §12) : chaque classe ordinaire a sa pose debout, sa pose de lancer et sa main.
func test_every_ordinary_class_has_complete_art() -> void:
	for id: StringName in _catalog.class_ids():
		var front := _catalog.front_dir + String(id) + _catalog.extension
		var throw := _catalog.front_dir + String(id) + _catalog.throw_suffix + _catalog.extension
		for path: String in [front, throw]:
			assert_true(ResourceLoader.exists(path), "%s : %s" % [id, path])
		assert_ne(_catalog.hand_of(id), _catalog.point("foe_hand"), "%s : main du lancer" % id)


## Taille réelle [D] : enfants < adolescents < adultes.
func test_ordinary_class_scales() -> void:
	var children: Array[StringName] = [&"gamin", &"fillette", &"scout", &"campeur"]
	var teens: Array[StringName] = [&"jeune_dresseur", &"jeune_dresseuse"]
	for id: StringName in _catalog.class_ids():
		var scale := _catalog.scale_of(id)
		assert_between(scale, 1.0, 1.4, "%s : taille réelle relative" % id)
		if id in children or id in teens:
			continue
		for young: StringName in children + teens:
			assert_gt(scale, _catalog.scale_of(young), "%s plus grand que %s" % [id, young])
	for child: StringName in children:
		for teen: StringName in teens:
			assert_lt(_catalog.scale_of(child), _catalog.scale_of(teen), "%s < %s" % [child, teen])


func test_champion_scales() -> void:
	for id: StringName in CHAMPIONS:
		var scale := _catalog.scale_of(id)
		assert_between(scale, 1.0, 1.4, "%s : taille réelle relative" % id)
	# Grands adultes plus grands que Pierre ; Ondine, Erika et Auguste un peu moins.
	for tall: StringName in [&"major_bob", &"koga", &"giovanni"]:
		assert_gt(_catalog.scale_of(tall), _catalog.scale_of(&"pierre"), String(tall))
	for small: StringName in [&"ondine", &"erika", &"auguste"]:
		assert_lt(_catalog.scale_of(small), _catalog.scale_of(&"pierre"), String(small))


## Demande de Kevin (2026-11-03, « il faut fixer ») : une classe masculine ne retombe jamais sur
## une feuille peinte féminine (Montagnard, Karatéka et Maître du Dojo prenaient `hiker`, feuille
## `randonneuse`), ni l'inverse ; ni pour le repli de la classe, ni pour ses Dresseurs du monde.
const FEMALE_CLASSES: Array[StringName] = [&"beaute", &"exorciste", &"fillette", &"jeune_dresseuse",
	&"nageuse", &"sbire_rocket_f", &"topdresseuse"]
const FEMALE_SHEETS: Array[String] = ["agatha", "beaute", "chercheuse", "dresseuse", "erika",
	"exorciste", "fillette", "hotesse", "infirmiere", "joueuse", "maman", "nageuse", "nageuse_eau",
	"olga", "ondine", "passagere", "randonneuse", "rivale", "sbire_f", "topdresseuse",
	"vieille_dame"]


## Feuille peinte (nom de base, sans « _idle_sheet » ni « _sheet ») d'une apparence du monde.
func _sheet_of(sprite: String) -> String:
	var path := "res://assets/sprites/characters/painted/%s_frames.tres" % sprite
	if not FileAccess.file_exists(path):
		return ""
	var found := RegEx.create_from_string("painted/([a-z_]+?)(_idle)?_sheet\\.png") \
		.search(FileAccess.get_file_as_string(path))
	return found.get_string(1) if found != null else ""


func _assert_same_gender(id: StringName, sprite: String, where: String) -> void:
	var sheet := _sheet_of(sprite)
	if sheet.is_empty():
		return
	assert_eq(sheet in FEMALE_SHEETS, id in FEMALE_CLASSES,
		"%s : %s → feuille %s (%s)" % [id, sprite, sheet, where])


func test_world_looks_match_the_gender_of_the_class() -> void:
	for id: StringName in _catalog.class_ids():
		_assert_same_gender(id, String(_catalog.world_sprite(id)), "repli")
	for file: String in DirAccess.get_files_at("res://data/npcs"):
		if not file.ends_with(".json"):
			continue
		var npcs: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs/" + file))
		if not npcs is Dictionary:
			continue
		for key: String in npcs:
			var npc: Variant = npcs[key]
			if not npc is Dictionary or not npc.get("trainer") is Dictionary:
				continue
			var trainer := _trainers.get_trainer(StringName(npc["trainer"].get("id", "")))
			if trainer == null or trainer.has_card():
				continue
			_assert_same_gender(_catalog.class_of(trainer), String(npc.get("sprite", "")),
				"%s/%s" % [file, key])
