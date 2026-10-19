class_name SessionLifecycle
extends RefCounted
## État de premier plan et temps de jeu, sans dépendance à Boot ou à GameState.
## Les notifications sont transmises par la racine ; aucune connexion globale.

const MAX_PLAY_TIME_STEP: float = 0.5

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


func play_time_step(delta: float, opening_active: bool) -> float:
	if not in_foreground or opening_active:
		return 0.0
	return clampf(delta, 0.0, MAX_PLAY_TIME_STEP)
