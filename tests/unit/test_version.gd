extends GutTest
## Version du jeu (J34 T1) : source unique dans `project.godot`, recopiée dans les presets d'export
## par `tools/version.py` ; identité d'application stable (contrat du J34 §1).

const PRESETS_PATH := "res://export_presets.cfg"
const VERSION_PATTERN := "^(\\d+)\\.(\\d+)\\.(\\d+)$"


static func _version() -> String:
	return GameVersion.name()


## Même formule que `tools/version.py` : MAJEUR × 10000 + MINEUR × 100 + CORRECTIF.
static func _version_code(version: String) -> int:
	return GameVersion.code_of(version)


func _presets() -> ConfigFile:
	var presets := ConfigFile.new()
	assert_eq(presets.load(PRESETS_PATH), OK, "export_presets.cfg lisible")
	return presets


func test_version_has_three_numbers() -> void:
	var version := _version()
	assert_ne(version, "", "application/config/version défini")
	assert_true(RegEx.create_from_string(VERSION_PATTERN).search(version) != null,
		"format MAJEUR.MINEUR.CORRECTIF : " + version)


func test_version_code_formula_is_strictly_increasing_after_the_j33_reference() -> void:
	assert_eq(_version_code("0.34.0"), 3400)
	assert_eq(_version_code("1.0.0"), 10000)
	assert_gt(_version_code(_version()), 33, "au-dessus du code 33 de la version 0.33.0 du J33")
	assert_gt(_version_code("0.34.1"), _version_code("0.34.0"))
	assert_gt(_version_code("0.35.0"), _version_code("0.34.99"))
	assert_eq(_version_code("abc"), -1)
	assert_eq(GameVersion.label(), "v%s (%d)" % [_version(), _version_code(_version())])


func test_android_preset_copies_the_project_version() -> void:
	var presets := _presets()
	var android := ""
	for section: String in presets.get_sections():
		if presets.get_value(section, "platform", "") == "Android":
			android = section
	assert_ne(android, "", "un preset Android")
	var options := android + ".options"
	assert_eq(presets.get_value(options, "version/name", ""), _version())
	assert_eq(int(presets.get_value(options, "version/code", 0)), _version_code(_version()))
	assert_eq(presets.get_value(options, "package/name", ""),
		ProjectSettings.get_setting("application/config/name"), "nom affiché sur le téléphone")
	assert_eq(presets.get_value(options, "package/unique_name", ""), "dev.kevin.kanto2026",
		"identifiant jamais changé : sauvegarde et mises à jour en dépendent")
	assert_true(bool(presets.get_value(options, "package/signed", false)), "APK signé")
	for key: String in ["keystore/release", "keystore/release_user", "keystore/release_password"]:
		assert_eq(str(presets.get_value(options, key, "")), "",
			key + " vide : la clé vient de l'environnement, jamais du dépôt")


func test_ios_preset_copies_the_project_version() -> void:
	var presets := _presets()
	for section: String in presets.get_sections():
		if presets.get_value(section, "platform", "") == "iOS":
			assert_eq(presets.get_value(section + ".options", "application/short_version", ""), _version())
			assert_eq(str(presets.get_value(section + ".options", "application/version", "")),
				str(_version_code(_version())))
