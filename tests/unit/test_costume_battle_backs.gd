extends GutTest
## Dos peints de combat de la joueuse et des costumes (2026-11-04, Kevin : les costumes « ont
## encore l'ancienne pose pour le lancer de Poké Ball ») : l'apparence de combat d'un costume porté
## est `costume_<art>_<version>`, ses dos sont `dos_costume_<…>[_surf][_lancer].webp` à côté de
## `dos_hero` ; sans costume, l'apparence du joueur ; chaque apparence a ses quatre dos (debout et
## lancer, à pied et en Surf).

const BATTLE_DIR := "res://assets/sprites/trainers/battle/"


func _catalog() -> CostumeCatalog:
	var catalog := CostumeCatalog.new()
	assert_true(catalog.add_from_array([
		{"id": "boulder", "badge": "boulder", "art": "roche",
			"names": {"hero": "Tanjiro", "heroine": "Nezuko"}},
	], "test"))
	return catalog


func test_a_worn_costume_has_its_own_battle_look() -> void:
	var catalog := _catalog()
	assert_eq(catalog.battle_look(&"boulder", &"hero"), &"costume_roche_joueur")
	assert_eq(catalog.battle_look(&"boulder", &"heroine"), &"costume_roche_joueuse")
	assert_eq(catalog.battle_look(&"", &"hero"), &"", "tenue d'origine : rien")
	assert_eq(catalog.battle_look(&"nope", &"hero"), &"", "costume inconnu : rien")


func test_trainer_looks_falls_back_to_the_player_look() -> void:
	assert_eq(TrainerLooks.battle_look(&"heroine"), &"heroine", "sans costume")
	assert_eq(TrainerLooks.battle_look(&"hero", &"boulder"), &"costume_roche_joueur")


func test_costume_backs_follow_the_player_path_convention() -> void:
	var trainer := TrainerData.new()
	trainer.id = &"t"
	trainer.name = "Nageur Yann"
	var intro := TrainerIntro.build(trainer, Party.new(), TrainerIntroCatalog.shared())
	var all := func(_path: String) -> bool: return true
	assert_eq(intro.player_path(&"costume_roche_joueur", all, true),
		BATTLE_DIR + "dos_costume_roche_joueur_lancer.webp")
	intro.surf = true
	assert_eq(intro.player_path(&"costume_roche_joueuse", all),
		BATTLE_DIR + "dos_costume_roche_joueuse_surf.webp")


func test_every_player_look_has_its_four_painted_backs() -> void:
	var looks: Array[StringName] = [&"hero", &"heroine"]
	var catalog := CostumeCatalog.shared()
	for id: StringName in catalog.ids():
		for look: StringName in [&"hero", &"heroine"]:
			looks.append(catalog.battle_look(id, look))
	assert_eq(looks.size(), 2 + 2 * catalog.size())
	for look: StringName in looks:
		for suffix: String in ["", "_lancer", "_surf", "_surf_lancer"]:
			var path := BATTLE_DIR + "dos_" + String(look) + suffix + ".webp"
			assert_true(ResourceLoader.exists(path), path)
