class_name SessionLifecycle
extends RefCounted
## État de premier plan et temps de jeu, sans dépendance à Boot ou à GameState.
## Les notifications sont transmises par la racine ; aucune connexion globale.

const MAX_PLAY_TIME_STEP: float = 0.5

## Changement de focus pour le délai de garde de la sauvegarde (passe systèmes 2, S2A,
## [SaveCheckpoint]) : `FOCUS_OUT` sans `PAUSED` (bandeau d'appel, rideau de notifications).
enum Focus { NONE, LOST, REGAINED }
## Jalon Son (T7, `docs/tech/jalon-son.md` §1.10) : ce que fait le son à une notification.
## MUTE : mise en arrière-plan (tout coupé) ; DUCK : focus perdu sans pause (bandeau d'appel,
## rideau de notifications : musique et ambiance atténuées) ; RESTORE : retour au premier plan.
enum AudioChange { NONE, MUTE, DUCK, RESTORE }

var in_foreground: bool = true


## Vrai si la notification demande une sauvegarde stable avant la suspension / fermeture.
func handle_notification(what: int) -> bool:
	match what:
		Node.NOTIFICATION_APPLICATION_PAUSED:
			in_foreground = false
			return true
		Node.NOTIFICATION_WM_CLOSE_REQUEST:
			return true
		Node.NOTIFICATION_APPLICATION_RESUMED, Node.NOTIFICATION_APPLICATION_FOCUS_IN:
			in_foreground = true
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT:
			in_foreground = false
	return false


## `FOCUS_OUT` → [constant Focus.LOST] ; `FOCUS_IN` ou `RESUMED` → [constant Focus.REGAINED].
static func focus_change(what: int) -> Focus:
	match what:
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT:
			return Focus.LOST
		Node.NOTIFICATION_APPLICATION_FOCUS_IN, Node.NOTIFICATION_APPLICATION_RESUMED:
			return Focus.REGAINED
	return Focus.NONE


## `PAUSED` → MUTE ; `FOCUS_OUT` → DUCK ; `RESUMED` ou `FOCUS_IN` → RESTORE (même source que la
## sauvegarde : aucune autre notification à écouter).
static func audio_change(what: int) -> AudioChange:
	match what:
		Node.NOTIFICATION_APPLICATION_PAUSED:
			return AudioChange.MUTE
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT:
			return AudioChange.DUCK
		Node.NOTIFICATION_APPLICATION_RESUMED, Node.NOTIFICATION_APPLICATION_FOCUS_IN:
			return AudioChange.RESTORE
	return AudioChange.NONE


func play_time_step(delta: float, opening_active: bool) -> float:
	if not in_foreground or opening_active:
		return 0.0
	return clampf(delta, 0.0, MAX_PLAY_TIME_STEP)
