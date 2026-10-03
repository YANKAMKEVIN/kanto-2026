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
## Statique : il n'y a qu'un moteur de vibration. Les tests posent [member sink] (espion) et
## appellent [method reset] à la fin.

## Faux : aucune vibration (réglage « Vibrations » coupé).
static var enabled: bool = true
## Reçoit chaque vibration permise (millisecondes) à la place du moteur ; vide en jeu.
static var sink: Callable = Callable()


## Vibre [param duration_ms] millisecondes, si le réglage le permet (une durée nulle ou
## négative ne fait rien).
static func vibrate(duration_ms: int) -> void:
	if not enabled or duration_ms <= 0:
		return
	if sink.is_valid():
		sink.call(duration_ms)
	else:
		Input.vibrate_handheld(duration_ms)


## Valeurs de départ (tests).
static func reset() -> void:
	enabled = true
	sink = Callable()
