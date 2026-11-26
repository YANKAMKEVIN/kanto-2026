class_name BootBackgroundSave
extends RefCounted
## Domaine « sauvegarde à la mise en arrière-plan » de [Boot] (passe systèmes 2, S2A,
## `systemes-2.md` §2.12 ; stockage plein, J33 T4).
##
## Point de reprise : instantané capturé au passage stable → instable (dialogue, scène,
## rencontre, combat, transition), remplacé par chaque écriture réussie ; écrit quand le jeu passe
## en arrière-plan alors que la partie n'est pas stable, avec une nouvelle tentative après un
## échec. Message « stockage plein » une fois par série d'échecs.
##
## Extrait de `boot.gd` sans changer le comportement : Boot garde la garde d'écriture
## ([method Boot.can_write]), le [SaveCoordinator] et l'horloge injectable
## ([member Boot.background_clock], remplacée par les tests avant l'entrée dans l'arbre) ; il
## appelle ce module à chaque image ([method watch]) et à chaque notification. Ce n'est pas un
## nœud : Boot le crée avec lui, comme l'ancien état, car les notifications arrivent aussi avant
## `_ready` et pendant la libération.

var _boot: Boot
var _checkpoint := SaveCheckpoint.new()
var _was_stable: bool = false
## Position de la dernière image stable ({ map, cell, facing }) : celle du point de reprise (la
## première image instable peut avoir posé le joueur sur une dalle tournante).
var _stable_location: Dictionary = {}
## Vrai pendant une écriture déclenchée par l'arrière-plan ([method SaveCheckpoint.note_written]).
var _background_write: bool = false
## Nouvelle tentative d'écriture du point de reprise après un échec (s restantes, −1 sinon).
var _checkpoint_retry: float = -1.0
## J33 T4 : le message « stockage plein » est déjà affiché pour la série d'échecs en cours.
var _storage_full_warned: bool = false
## Plus longue capture de la session (µs), pour la mesure sur téléphone (budget < 5 ms).
var _checkpoint_max_usec: int = 0


func _init(boot: Boot) -> void:
	_boot = boot


## Horloge par défaut (secondes depuis le lancement) si les tests n'en ont pas injecté.
func setup() -> void:
	if not _boot.background_clock.is_valid():
		_boot.background_clock = func() -> float: return Time.get_ticks_msec() / 1000.0


func get_save_checkpoint() -> SaveCheckpoint:
	return _checkpoint


## Une écriture de Boot vient de réussir : le point de reprise est remplacé.
func note_written(snapshot: Dictionary) -> void:
	_checkpoint.note_written(snapshot, _now(), _background_write)


## Une fois par image, avant le coordinateur : capture au passage stable → instable, délai de
## garde d'un `FOCUS_OUT`, nouvelle tentative après un échec.
func watch(delta: float) -> void:
	var stable := _boot.is_stable()
	if stable:
		var player := _boot.get_player()
		_stable_location = {"map": _boot.current_map_id(), "cell": player.get_cell(),
			"facing": player.get_facing()}
	elif _was_stable and _boot.can_write():
		_capture_checkpoint()
	_was_stable = stable
	if _checkpoint.focus_due(_now()):
		save_in_background("arrière-plan (focus perdu)")
	if _checkpoint_retry >= 0.0:
		_checkpoint_retry = maxf(0.0, _checkpoint_retry - maxf(delta, 0.0))
		if _checkpoint_retry == 0.0:
			_checkpoint_retry = -1.0
			# Redevenue stable, la partie s'écrit par les autosaves ordinaires.
			if not stable:
				save_in_background("nouvelle tentative")


## Mise en arrière-plan (`PAUSED`, `WM_CLOSE_REQUEST`, `FOCUS_OUT` échu) : état courant si la
## partie est stable, sinon le point de reprise s'il est plus récent que le disque.
func save_in_background(reason: String) -> void:
	if not _boot.can_write():
		return
	match _checkpoint.decide(_boot.is_stable(), _now()):
		SaveCheckpoint.Decision.WRITE_CURRENT:
			_background_write = true
			_boot.get_save_coordinator().flush_if_stable(reason)
			_background_write = false
		SaveCheckpoint.Decision.WRITE_CHECKPOINT:
			_write_checkpoint(reason)


func on_focus_change(change: SessionLifecycle.Focus) -> void:
	if change != SessionLifecycle.Focus.NONE and OS.is_debug_build():
		print("[save] focus %s à %.2f s" % [SessionLifecycle.Focus.keys()[change], _now()])
	match change:
		SessionLifecycle.Focus.LOST:
			_checkpoint.focus_out(_now())
		SessionLifecycle.Focus.REGAINED:
			_checkpoint.focus_in()


## J33 T4 : stockage plein, une fois par série d'échecs (l'écriture est retentée toutes les 5 s,
## rien n'est détruit) ; une écriture réussie réarme le message.
func warn_storage_full(error: Error) -> void:
	if error != SaveSystem.STORAGE_FULL:
		if error == OK:
			_storage_full_warned = false
		return
	if not _storage_full_warned:
		_storage_full_warned = true
		_boot.get_hud().show_toast(SettingsViews.STORAGE_FULL_TITLE,
			SettingsViews.STORAGE_FULL_DETAIL)


func _now() -> float:
	return _boot.background_clock.call()


## Instantané de l'état courant, à la position de la dernière image stable.
func _capture_checkpoint() -> void:
	if _stable_location.is_empty():
		return
	var start := Time.get_ticks_usec()
	var at := _boot.get_elevator_director().stable_location(_stable_location["map"],
		_stable_location["cell"], _stable_location["facing"])
	GameState.set_player_location(at["map"], at["cell"], at["facing"])
	_checkpoint.capture(GameState.to_dict())
	var spent := Time.get_ticks_usec() - start
	_checkpoint_max_usec = maxi(_checkpoint_max_usec, spent)
	if OS.is_debug_build():
		print("[save] point de reprise : %d µs (max %d µs)" % [spent, _checkpoint_max_usec])


func _write_checkpoint(reason: String) -> void:
	var snapshot := _checkpoint.get_snapshot()
	var error := _boot.save_system.write(snapshot)
	warn_storage_full(error)
	if error == OK:
		_checkpoint.note_written(snapshot, _now(), true)
		_checkpoint_retry = -1.0
	else:
		_checkpoint_retry = SaveCoordinator.RETRY_DELAY
	if OS.is_debug_build():
		print("Sauvegarde du point de reprise (%s) : %s %s, %s" % [reason,
			snapshot.get("map", ""), snapshot.get("cell", ""), error_string(error)])
