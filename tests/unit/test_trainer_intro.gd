extends GutTest
## TrainerIntro, TrainerIntroCatalog : plan de l'entrée des combats de Dresseur (dossier 05 §3,
## décision de Kevin du 2026-11-02). Ordre des étapes (ordinaire / grand combat), durées (≈ 2 s
## pour l'entrée du niveau 1), rangée de Poké Balls, classes par préfixe du nom, repli des
## images (convention de chemin absente), rival selon son apparence, « Réduire les animations ».

const Step := TrainerIntro.Step
const Ball := TrainerIntro.Ball

var _catalog: TrainerIntroCatalog
var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir("res://tests/fixtures/pokemon/valid/")


func before_each() -> void:
	_catalog = TrainerIntroCatalog.new()
	assert_true(_catalog.load_file(), str(_catalog.get_errors()))


func _trainer(trainer_name: String, card: Array = []) -> TrainerData:
	var trainer := TrainerData.new()
	trainer.id = &"t"
	trainer.name = trainer_name
	if not card.is_empty():
		trainer.card_name = card[0]
		trainer.card_title = card[1]
		trainer.card_portrait = card[2]
	return trainer


func _party(count: int, fainted: int = -1) -> Party:
	var party := Party.new()
	for i: int in count:
		var pokemon := PokemonFactory.create(_data, &"sprout", 5, GameRng.new(i))
		if i == fainted:
			pokemon.hp = 0
		party.add(pokemon)
	return party


func test_ordinary_trainer_plays_the_level_one_entry_only() -> void:
	var intro := TrainerIntro.build(_trainer("Gamin Hugo"), _party(2), _catalog)
	assert_false(intro.grand)
	assert_eq(intro.steps, [Step.TRAINERS_IN, Step.FOE_SEND, Step.PLAYER_SEND] as Array[Step])
	assert_eq(intro.sprite_id, &"gamin")
	assert_eq(intro.world_sprite, &"youngster")
	assert_eq(intro.portrait_id, &"", "pas de portrait de banderole")
	assert_true(intro.slide)


func test_grand_battle_opens_on_the_vs_sequence() -> void:
	var trainer := _trainer("Pierre", ["PIERRE", "Champion d'Arène d'Argenta", &"pierre"])
	var intro := TrainerIntro.build(trainer, _party(2), _catalog)
	assert_true(intro.grand)
	assert_eq(intro.steps, [Step.TRAINERS_IN, Step.VS_IN, Step.VS_HOLD, Step.VS_OUT,
		Step.FOE_SEND, Step.PLAYER_SEND] as Array[Step],
		"les dresseurs entrent, puis le « VS » se pose sur eux, puis les lancers")
	assert_eq([intro.foe_name, intro.foe_title], ["PIERRE", "Champion d'Arène d'Argenta"])
	assert_eq([intro.sprite_id, intro.portrait_id], [&"pierre", &"pierre"])
	assert_eq(intro.world_sprite, &"brock")


func test_level_one_entry_lasts_about_two_seconds() -> void:
	var intro := TrainerIntro.build(_trainer("Gamin Hugo"), _party(1), _catalog)
	assert_almost_eq(intro.total(), 2.8, 0.3, "[D] gestes ≈ 2,8 s, sous les messages")
	assert_eq(intro.total(), intro.entry_total())
	var grand := TrainerIntro.build(_trainer("Pierre", ["PIERRE", "T", &"pierre"]), _party(1),
		_catalog)
	var vs := grand.duration(Step.VS_IN) + grand.duration(Step.VS_HOLD) \
		+ grand.duration(Step.VS_OUT)
	assert_between(vs, 1.2, 1.6, "séquence « VS » de 1,2 à 1,6 s (maquette validée)")
	assert_almost_eq(grand.total(), vs + grand.entry_total(), 0.0001)


func test_ball_row_full_fainted_empty() -> void:
	var row := TrainerIntro.ball_row(_party(3, 1))
	assert_eq(row, [Ball.FULL, Ball.FAINTED, Ball.FULL, Ball.EMPTY, Ball.EMPTY, Ball.EMPTY]
		as Array[Ball])
	assert_eq(TrainerIntro.ball_row(null).size(), TrainerIntro.SLOTS)


func test_class_is_the_longest_name_prefix() -> void:
	assert_eq(_catalog.class_for("Jeune Dresseuse Alice"), &"jeune_dresseuse")
	assert_eq(_catalog.class_for("Jeune Dresseur Adam"), &"jeune_dresseur")
	assert_eq(_catalog.class_for("Topdresseuse Judith"), &"topdresseuse")
	assert_eq(_catalog.class_for("Topdresseur Malo"), &"topdresseur")
	assert_eq(_catalog.class_for("Sbire Rocket"), &"sbire_rocket", "nom entier")
	assert_eq(_catalog.class_for("Maître du Dojo"), &"maitre_dojo")
	assert_eq(_catalog.class_for("Gaminette Zoé"), &"", "préfixe suivi d'une espace seulement")
	assert_eq(_catalog.class_for("Inconnu"), &"")
	var grunt := _trainer("Sbire Rocket")
	assert_eq(_catalog.class_of(grunt), &"sbire_rocket")
	grunt.battle_class = &"sbire_rocket_f"
	assert_eq(_catalog.class_of(grunt), &"sbire_rocket_f", "classe imposée par les données")
	assert_true(_catalog.has_class(&"sbire_rocket_f"))


func test_images_follow_the_path_convention_with_fallback() -> void:
	var intro := TrainerIntro.build(_trainer("Pierre", ["PIERRE", "T", &"pierre"]), _party(1),
		_catalog)
	var none := func(_path: String) -> bool: return false
	var all := func(_path: String) -> bool: return true
	assert_eq(intro.front_path(none), "", "image absente : repli")
	assert_eq(intro.portrait_path(none), "")
	assert_eq(intro.front_path(all), "res://assets/sprites/trainers/battle/pierre.webp")
	assert_eq(intro.portrait_path(all), "res://assets/ui/battle/vs/pierre.webp")
	var ordinary := TrainerIntro.build(_trainer("Scout Sacha"), _party(1), _catalog)
	assert_eq(ordinary.front_path(all), "res://assets/sprites/trainers/battle/scout.webp")
	assert_eq(ordinary.portrait_path(all), "", "aucun portrait pour un Dresseur ordinaire")
	assert_eq(ordinary.front_path(all, true),
		"res://assets/sprites/trainers/battle/scout_lancer.webp", "pose de lancer")
	assert_eq(ordinary.player_path(&"heroine", all, true),
		"res://assets/sprites/trainers/battle/dos_heroine_lancer.webp", "dos peint du joueur")
	assert_eq(ordinary.player_path(&"hero", none), "", "repli : lancer de dos existant")
	var unknown := TrainerIntro.build(_trainer("Inconnu"), _party(1), _catalog)
	assert_eq(unknown.front_path(all), "", "aucune classe : repli générique")


func test_rival_images_follow_the_rival_look() -> void:
	var card := ["{rival}", "Rival", &"rival"]
	var rival := TrainerIntro.build(_trainer("{rival}", card), _party(1), _catalog, &"rival")
	assert_eq([rival.sprite_id, rival.world_sprite], [&"rival", &"rival"])
	var rivale := TrainerIntro.build(_trainer("{rival}", card), _party(1), _catalog, &"rivale")
	assert_eq([rivale.sprite_id, rivale.portrait_id], [&"rivale", &"rivale"])
	assert_eq(rivale.world_sprite, &"rival_heroine")


func test_rivale_gets_the_feminine_title() -> void:
	var card := ["{rival}", "Champion de la Ligue", &"rival"]
	var trainer := _trainer("{rival}", card)
	trainer.card_title_rivale = "Championne de la Ligue"
	var rival := TrainerIntro.build(trainer, _party(1), _catalog, &"rival")
	assert_eq(rival.foe_title, "Champion de la Ligue")
	var rivale := TrainerIntro.build(trainer, _party(1), _catalog, &"rivale")
	assert_eq(rivale.foe_title, "Championne de la Ligue")
	var no_variant := TrainerIntro.build(_trainer("{rival}", ["{rival}", "Rival", &"rival"]),
		_party(1), _catalog, &"rivale")
	assert_eq(no_variant.foe_title, "Rival", "sans variante : titre commun")


func test_reduce_motion_fades_without_shortening() -> void:
	var trainer := _trainer("Pierre", ["PIERRE", "T", &"pierre"])
	var normal := TrainerIntro.build(trainer, _party(1), _catalog)
	var reduced := TrainerIntro.build(trainer, _party(1), _catalog, &"rival", true)
	assert_false(reduced.slide, "fondus au lieu des glissés")
	assert_eq(reduced.steps, normal.steps, "la séquence reste entière")
	assert_eq(reduced.total(), normal.total())


func test_invalid_catalog_is_reported() -> void:
	var catalog := TrainerIntroCatalog.new()
	assert_false(catalog.add_from_dict({"durations": {"vs_in": -1}, "classes": {"x": 3}}))
	assert_gt(catalog.get_errors().size(), 3)
	assert_push_error_count(catalog.get_errors().size())


## Itération 3 (maquettes, fractions de l'écran) : poses d'entrée, de lancer et du « VS ».
func test_poses_follow_the_mockups() -> void:
	assert_eq(_catalog.pose("entry", "player"), Vector3(0.285, 0.95, 0.55))
	assert_eq(_catalog.pose("entry", "foe"), Vector3(0.70, 0.56, 0.26))
	assert_eq(_catalog.pose("throw", "player"), Vector3(0.215, 0.97, 0.57))
	assert_eq(_catalog.pose("throw", "foe"), Vector3(0.72, 0.56, 0.32))
	assert_eq(_catalog.pose("vs", "player"), Vector3(0.29, 0.74, 0.38))
	assert_eq(_catalog.pose("vs", "foe"), Vector3(0.71, 0.67, 0.238), "Pierre réduit de 15 %")
	assert_eq(_catalog.point("cartouche_min"), Vector2(0.69, 0.19))
	assert_eq(_catalog.point("cartouche_max"), Vector2(0.86, 0.26))
	assert_eq(_catalog.point("foe_via"), Vector2(0.56, 0.28), "arc de la Ball")
	assert_almost_eq(_catalog.layout["ball_diameter"], 0.024, 0.0001)


## Taille réelle relative (données) : un adulte (Pierre) paraît plus grand qu'un enfant (Gamin).
func test_adults_are_taller_than_children() -> void:
	assert_gt(_catalog.scale_of(&"pierre"), _catalog.scale_of(&"gamin"))
	assert_eq(_catalog.scale_of(&"rivale"), _catalog.scale_of(&"rival"), "rivale = rival")
	assert_eq(_catalog.scale_of(&"inconnu"), _catalog.default_scale)


## Itération 4 : image par moment, recadrage du lancer, bustes du « VS » par les données.
func test_phase_images_framing_and_busts_come_from_data() -> void:
	assert_true(_catalog.uses_throw_image("player", "entry"), "entrée : bras tendu")
	assert_false(_catalog.uses_throw_image("player", "guard"), "garde : poings serrés")
	assert_true(_catalog.uses_throw_image("player", "release"))
	assert_false(_catalog.uses_throw_image("foe", "entry"))
	assert_true(_catalog.uses_throw_image("foe", "release"))
	assert_gt(_catalog.framing_zoom, 1.0, "le décor se recadre vraiment")
	assert_eq(_catalog.framing_to, Vector2(0.72, 0.56), "Hugo pieds (72 %, 56 %)")
	assert_eq(_catalog.foe_bust.x, 1.0, "buste au bout droit de la banderole")
	assert_eq(_catalog.bust_adjust(&"inconnu"), Vector3(0, 0, 1), "sans réglage")
	assert_ne(_catalog.hand_of(&"gamin"), _catalog.point("foe_hand"), "main de sa pose")
	assert_eq(_catalog.hand_of(&"inconnu"), _catalog.point("foe_hand"), "repli")


func test_bad_images_or_framing_are_reported() -> void:
	var catalog := TrainerIntroCatalog.new()
	var root: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		TrainerIntroCatalog.PATH))
	root["images"]["player"]["entry"] = "assis"
	root["framing"]["zoom"] = 0.5
	assert_false(catalog.add_from_dict(root))
	assert_eq(catalog.get_errors().size(), 2)
	assert_push_error_count(2)
