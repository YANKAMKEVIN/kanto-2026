class_name GameVersion
extends RefCounted
## Version du jeu (J34 T1) : lue dans `application/config/version` de `project.godot`, la source
## unique que `tools/version.py` recopie dans les presets d'export. Le code Android en est dérivé
## par la même formule que l'outil : MAJEUR × 10000 + MINEUR × 100 + CORRECTIF (0.34.0 → 3400).

const SETTING := "application/config/version"
const PATTERN := "^(\\d+)\\.(\\d+)\\.(\\d+)$"


## « 0.34.0 », ou « » si le projet n'a pas de version.
static func name() -> String:
	return str(ProjectSettings.get_setting(SETTING, ""))


## Code entier croissant d'une version MAJEUR.MINEUR.CORRECTIF ; -1 si le format est invalide.
static func code_of(version: String) -> int:
	var m := RegEx.create_from_string(PATTERN).search(version)
	if m == null:
		return -1
	return int(m.get_string(1)) * 10000 + int(m.get_string(2)) * 100 + int(m.get_string(3))


static func code() -> int:
	return code_of(name())


## Texte affiché aux joueurs (écran titre) : « v0.34.0 (3400) ».
static func label() -> String:
	return "v%s (%d)" % [name(), code()]
