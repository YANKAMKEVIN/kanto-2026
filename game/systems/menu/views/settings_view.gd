class_name SettingsView
extends RefCounted
## Ce qu'affiche l'écran Paramètres (dossier 08 §7 ; jalon-06.md §3.8, §6.12) : les catégories
## et leurs contrôles, dans l'ordre. Construit par [SettingsViews] ; l'écran ne connaît ni
## [GameSettings], ni la sauvegarde. Contrat figé au T27.
##
## Ni AUDIO (Q-17), ni « sauvegarde automatique » (permanente, dossier 08 §7), ni aucune
## option exclue par le dossier 08 (difficulté, caméra, langue…).

## Catégories, dans l'ordre (catégories à gauche, la première ouverte à l'entrée).
var categories: Array[SettingsCategoryView] = []


## Contrôle de clé [param key] (toutes catégories), ou null.
func control(key: StringName) -> SettingControlView:
	for category: SettingsCategoryView in categories:
		for item: SettingControlView in category.controls:
			if item.key == key:
				return item
	return null


## Catégorie d'identifiant [param id], ou null.
func category(id: StringName) -> SettingsCategoryView:
	for item: SettingsCategoryView in categories:
		if item.id == id:
			return item
	return null
