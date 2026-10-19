extends GutTest
## Règles pures de Flash hors combat (jalon 17 T24 ; dossier 20 H-7, Q-1 « tout J17 » ; contrat
## du J18 §3.2) : automatique à chaque arrivée sur une carte obscure, avertissement sans Flash,
## aucun drapeau « allumée ».

var _caves: CaveLibrary


func before_all() -> void:
	_caves = CaveLibrary.new()
	assert_true(_caves.add_from_dict({"caves": {
		"dark": {"maps": ["dark_1f", "dark_b1f"],
			"escape": {"map": "outside", "spawn": "s", "facing": "down"}, "dark": true},
		"lit": {"maps": ["lit_1f"],
			"escape": {"map": "outside", "spawn": "s", "facing": "down"}},
	}}, "test"), "\n".join(_caves.get_errors()))


func test_entering_a_dark_map_with_flash_is_automatic() -> void:
	assert_eq(FlashRules.entry_action(&"outside", &"dark_1f", _caves, true), FlashRules.Entry.AUTO)


func test_without_flash_a_warning() -> void:
	assert_eq(FlashRules.entry_action(&"outside", &"dark_1f", _caves, false),
		FlashRules.Entry.WARN)


## Changement d'étage : Flash se rallume (dossier 21 §5.3 aligné, 2026-10-15).
func test_each_floor_is_an_entry() -> void:
	assert_eq(FlashRules.entry_action(&"dark_1f", &"dark_b1f", _caves, true),
		FlashRules.Entry.AUTO)
	assert_eq(FlashRules.entry_action(&"dark_b1f", &"dark_1f", _caves, false),
		FlashRules.Entry.WARN)


## Reprise d'une partie dans la grotte (carte de départ vide) : une arrivée comme une autre.
func test_resuming_in_the_cave_is_an_entry() -> void:
	assert_true(FlashRules.is_entry(&"", &"dark_1f"))
	assert_eq(FlashRules.entry_action(&"", &"dark_1f", _caves, true), FlashRules.Entry.AUTO)


func test_nothing_outside_dark_maps() -> void:
	for to: StringName in [&"lit_1f", &"outside", &"unknown"]:
		assert_eq(FlashRules.entry_action(&"dark_1f", to, _caves, true), FlashRules.Entry.NONE,
			String(to))
		assert_false(FlashRules.is_lit(&"dark_1f", to, _caves, true), String(to))
	assert_eq(FlashRules.entry_action(&"a", &"b", null, true), FlashRules.Entry.NONE)


## Même carte (rechargée sans changer de carte) : pas une arrivée ; halo ouvert dès l'écran noir
## si Flash est disponible.
func test_same_map_is_not_an_entry() -> void:
	assert_false(FlashRules.is_entry(&"dark_1f", &"dark_1f"))
	assert_eq(FlashRules.entry_action(&"dark_1f", &"dark_1f", _caves, true),
		FlashRules.Entry.NONE)
	assert_true(FlashRules.is_lit(&"dark_1f", &"dark_1f", _caves, true))
	assert_false(FlashRules.is_lit(&"dark_1f", &"dark_1f", _caves, false))


## À une arrivée, le voile est posé sombre : la mise en scène l'ouvre.
func test_entry_lays_the_veil_dark() -> void:
	assert_false(FlashRules.is_lit(&"outside", &"dark_1f", _caves, true))
	assert_false(FlashRules.is_lit(&"", &"dark_1f", _caves, true))
