class_name SaveCheckpoint
extends RefCounted
## Point de reprise de la sauvegarde à la mise en arrière-plan (passe systèmes 2,
## `docs/tech/systemes-2.md` §2.12, S2A, validée seule) : pur, sans disque ni horloge (le temps
## arrive en paramètre, en secondes).
##
## - Un **instantané** de la partie est capturé à chaque passage stable → instable (début d'un
##   dialogue, d'une scène, d'une rencontre, d'un combat) : [method capture].
## - Chaque écriture réussie sur le disque (autosave, écriture immédiate d'une scène, Menu) est
##   notée : [method note_written]. L'instantané écrit devient le point de reprise.
## - Révisions monotones : **on n'écrit jamais un point de reprise plus ancien que le disque**
##   (une scène qui a fait une écriture immédiate, un don par exemple, l'a dépassé).
## - Mise en arrière-plan ([method decide]) : partie stable → écrire l'état courant ; instable →
##   écrire le point de reprise s'il est plus récent que le disque ; jamais deux écritures en
##   moins de [constant MIN_INTERVAL] s.
## - `FOCUS_OUT` (bandeau d'appel, rideau de notifications) : ne compte comme une mise en
##   arrière-plan qu'après [constant FOCUS_GRACE] s sans `FOCUS_IN` ([method focus_out],
##   [method focus_in], [method focus_due]).
##
## Effet pour le joueur (Q-8) : tué pendant un combat ou une scène, il reprend juste avant.

## Que faire à la mise en arrière-plan ([method decide]).
enum Decision {
	NOTHING, ## Rien à écrire (disque à jour, ou écriture trop récente).
	WRITE_CURRENT, ## Partie stable : écrire l'état courant (comme avant la passe).
	WRITE_CHECKPOINT, ## Partie instable : écrire [method get_snapshot].
}

## Délai de garde d'un `FOCUS_OUT` avant d'écrire [D].
const FOCUS_GRACE: float = 1.0
## Écart minimal entre deux écritures déclenchées par l'arrière-plan [D].
const MIN_INTERVAL: float = 2.0

var _counter: int = 0
var _snapshot: Dictionary = {}
var _snapshot_revision: int = -1
var _disk_revision: int = 0
var _last_write_time: float = -INF
var _focus_out_time: float = -1.0


## Capture [param snapshot] (copie profonde) comme point de reprise, plus récent que le disque.
func capture(snapshot: Dictionary) -> void:
	_counter += 1
	_snapshot = snapshot.duplicate(true)
	_snapshot_revision = _counter


## Une écriture sur le disque a réussi à [param now] avec [param snapshot] : le disque est à
## jour, et ce qui a été écrit devient le point de reprise (pas plus récent que le disque).
func note_written(snapshot: Dictionary, now: float) -> void:
	_counter += 1
	_disk_revision = _counter
	_snapshot = snapshot.duplicate(true)
	_snapshot_revision = _counter
	_last_write_time = now


## Vrai si le point de reprise est plus récent que le disque (il vaut la peine d'être écrit).
func is_newer_than_disk() -> bool:
	return not _snapshot.is_empty() and _snapshot_revision > _disk_revision


## Le point de reprise (copie ; vide s'il n'y en a pas).
func get_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


## Mise en arrière-plan à [param now] (`PAUSED`, `WM_CLOSE_REQUEST`, ou `FOCUS_OUT` échu) ;
## [param stable] : `Boot.is_stable()`.
func decide(stable: bool, now: float) -> Decision:
	if now - _last_write_time < MIN_INTERVAL:
		return Decision.NOTHING
	if stable:
		return Decision.WRITE_CURRENT
	return Decision.WRITE_CHECKPOINT if is_newer_than_disk() else Decision.NOTHING


## `FOCUS_OUT` à [param now] : arme le délai de garde (un second `FOCUS_OUT` ne le repousse pas).
func focus_out(now: float) -> void:
	if _focus_out_time < 0.0:
		_focus_out_time = now


## `FOCUS_IN` : annule le délai de garde.
func focus_in() -> void:
	_focus_out_time = -1.0


## Vrai une seule fois quand le délai de garde d'un `FOCUS_OUT` est échu à [param now] : la
## racine appelle alors [method decide].
func focus_due(now: float) -> bool:
	if _focus_out_time < 0.0 or now - _focus_out_time < FOCUS_GRACE:
		return false
	_focus_out_time = -1.0
	return true
