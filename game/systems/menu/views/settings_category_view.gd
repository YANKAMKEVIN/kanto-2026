class_name SettingsCategoryView
extends RefCounted
## Une catégorie de l'écran Paramètres (JEU, COMMANDES, ACCESSIBILITÉ, GRAPHISMES ; dossier
## 08 §7, jalon-06.md §6.12). Contrat figé au T27.

## [constant SettingsViews.CATEGORY_GAME]…
var id: StringName = &""
## « JEU ».
var title: String = ""
## Sous-titre de la section (MM.3, repris de la maquette : « Personnalise tes contrôles. ») ;
## "" = absent.
var subtitle: String = ""
## Contrôles, dans l'ordre d'affichage (jamais vide).
var controls: Array[SettingControlView] = []


func _init(category_id: StringName = &"", category_title: String = "",
		category_subtitle: String = "") -> void:
	id = category_id
	title = category_title
	subtitle = category_subtitle
