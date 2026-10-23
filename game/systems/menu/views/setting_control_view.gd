class_name SettingControlView
extends RefCounted
## Un contrôle de l'écran Paramètres (jalon-06.md §6.12) : interrupteur, choix, curseur ou
## action. Construit par [SettingsViews] ; l'écran ne connaît pas [GameSettings]. Contrat
## figé au T27.
##
## L'écran émet `setting_changed(key, value)` avec une valeur **du réglage** : booléen pour
## TOGGLE, [member SettingOptionView.value] pour CHOICE, flottant d'un cran pour SLIDER
## ([member min_value] + n × [member step]). ACTION (« Sauvegarder maintenant ») émet
## `save_now_requested`, jamais `setting_changed`.

enum Kind { TOGGLE, CHOICE, SLIDER, ACTION }

## Clé du réglage ([constant GameSettings.KEYS]) ou [constant SettingsViews.SAVE_NOW].
var key: StringName = &""
var kind: Kind = Kind.TOGGLE
## « Vitesse du texte ».
var label: String = ""
## Phrase d'aide sous le libellé ; "" = absente.
var detail: String = ""
## Valeur actuelle (bool, entier d'enum ou flottant ; null pour ACTION).
var value: Variant = null
## Valeur écrite en texte (« Activé », « Normale », « 70 % », « Auto (Élevée) ») : toujours
## affichée, l'état ne passe jamais par la seule position ou la seule couleur (règle 7).
var value_text: String = ""
## CHOICE : options dans l'ordre d'affichage ; l'option dont la valeur égale [member value]
## est la sélectionnée.
var options: Array[SettingOptionView] = []
## SLIDER : bornes et pas (ex. 0,3 → 1,0 par 0,1).
var min_value: float = 0.0
var max_value: float = 1.0
var step: float = 0.1
## TOGGLE : vrai si l'interrupteur affiche le **contraire** du réglage (« Lumière d'ambiance »
## activée = `economy` faux). [member value] reste la valeur du réglage, l'écran émet toujours
## son contraire ; seuls la position de l'interrupteur et [member value_text] sont inversés.
var inverted: bool = false
## Faux : le contrôle est visible mais ne se touche pas (ex. « Sauvegarder maintenant » d'une
## session de débogage) ; [member detail] dit pourquoi.
var enabled: bool = true


## Rang de l'option sélectionnée (CHOICE), ou -1.
func selected_option() -> int:
	for i: int in options.size():
		if options[i].value == value:
			return i
	return -1
