class_name Haptics
extends RefCounted
## Porte unique des vibrations du jeu (bible UI/UX §12, dossier 08 règle 11 ; jalon-06.md §3.8).
##
## Tout le code passe par [method vibrate] : jamais `Input.vibrate_handheld` directement. Le
## réglage « Vibrations » des Paramètres pose [member enabled] (Boot, T29) ; coupé, plus rien
## ne vibre, où que ce soit. Les drapeaux `haptics_enabled` propres à certains composants
## (combat, toast) restent : ils coupent la vibration réelle d'un composant en test, et leurs
## signaux (`haptic_played`, `haptic_requested`) sont toujours émis.
##
## Force (bible UI/UX §12 : retours très légers, critique plus marqué) : chaque vibration part
## avec une amplitude déduite de sa durée ([method amplitude_for]) : « tic » d'un toast, toucher
## et menu faibles, coup reçu moyen, coup critique et fin de capture forts. Les appelants ne
## donnent toujours qu'une durée (les jetons HAPTIC_* de [UiTokens]).
##
## Statique : il n'y a qu'un moteur de vibration. Les tests posent [member sink] (espion) et
## appellent [method reset] à la fin.

## Faux : aucune vibration (réglage « Vibrations » coupé).
static var enabled: bool = true
## Reçoit chaque vibration permise (millisecondes) à la place du moteur ; vide en jeu.
static var sink: Callable = Callable()
## Reçoit l'amplitude (0 à 1) de chaque vibration permise, en plus de [member sink] (tests).
static var amplitude_sink: Callable = Callable()


## Vibre [param duration_ms] millisecondes, si le réglage le permet (une durée nulle ou
## négative ne fait rien).
static func vibrate(duration_ms: int) -> void:
	if not enabled or duration_ms <= 0:
		return
	var amplitude := amplitude_for(duration_ms)
	if amplitude_sink.is_valid():
		amplitude_sink.call(amplitude)
	if sink.is_valid():
		sink.call(duration_ms)
	else:
		Input.vibrate_handheld(duration_ms, amplitude)


## Amplitude (0 à 1) d'une vibration de [param duration_ms] : légère jusqu'à
## HAPTIC_LIGHT_MAX_MS (tic, toucher, menu, statut), moyenne jusqu'à HAPTIC_MEDIUM_MAX_MS (coup
## reçu, secousse de la Ball), forte au-delà (coup critique, capture réussie).
static func amplitude_for(duration_ms: int) -> float:
	if duration_ms <= UiTokens.HAPTIC_LIGHT_MAX_MS:
		return UiTokens.HAPTIC_AMPLITUDE_LIGHT
	if duration_ms <= UiTokens.HAPTIC_MEDIUM_MAX_MS:
		return UiTokens.HAPTIC_AMPLITUDE_MEDIUM
	return UiTokens.HAPTIC_AMPLITUDE_STRONG


## Valeurs de départ (tests).
static func reset() -> void:
	enabled = true
	sink = Callable()
	amplitude_sink = Callable()
