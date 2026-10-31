class_name IntroStep
extends RefCounted
## Une étape de l'introduction du Prof. Chen ([IntroScript], dossier 13 §3.2), figée après
## validation.

enum Type {
	## Montrer (ou déplacer) / cacher un portrait sur la scène.
	STAGE,
	## Une réplique : toucher = compléter / continuer.
	PAGE,
	## Écran de prénom ; [member text] est la question de Chen, affichée au-dessus.
	PROMPT,
	## « X ! C'est bien ça ? » Oui / Non ; Non ramène au prompt [member name].
	CONFIRM,
	## Choix de l'apparence (chantier JR) : deux cartes illustrées ; [member text] est la question
	## de Chen, affichée dans la boîte.
	LOOK,
}

var type: Type = Type.PAGE
## PAGE, PROMPT, CONFIRM : texte brut (jetons non résolus).
var text: String = ""
## PAGE, PROMPT, CONFIRM : étiquette du locuteur.
var speaker: String = ""
## STAGE : portrait concerné ([constant IntroScript.PORTRAITS]).
var portrait: StringName = &""
## STAGE : vrai = montrer (ou déplacer s'il est déjà visible), faux = cacher.
var show: bool = true
## STAGE (montrer) : emplacement ([constant IntroScript.SLOTS]).
var slot: StringName = &""
## STAGE (montrer) : effet d'entrée facultatif ([constant IntroScript.EFFECTS]).
var effect: StringName = &""
## PROMPT, CONFIRM : quel prénom ([constant IntroScript.PROMPT_PLAYER_NAME] ou
## [constant IntroScript.PROMPT_RIVAL_NAME]) ; LOOK : quelle apparence
## ([constant IntroScript.PROMPT_PLAYER_LOOK] ou [constant IntroScript.PROMPT_RIVAL_LOOK]).
var name: StringName = &""
