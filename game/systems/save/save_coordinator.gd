class_name SaveCoordinator
extends RefCounted
## Coordonne les demandes d'écriture sans connaître Boot, GameState ni le disque.
## La racine injecte la permission, la stabilité et l'écriture de l'instantané courant.
## Une écriture immédiate peut se faire pendant une scène (départ du navire, réveil) ;
## seules les demandes différées attendent un état stable.
## Un échec garde la demande, avec une nouvelle tentative après 5 s de temps simulé.

const RETRY_DELAY: float = 5.0

var _allowed: Callable
var _stable: Callable
var _writer: Callable
var _pending: bool = false
var _reason: String = ""
var _retry_remaining: float = 0.0


func setup(allowed: Callable, stable: Callable, writer: Callable) -> void:
	_allowed = allowed
	_stable = stable
	_writer = writer


func request(reason: String) -> void:
	if not _can_write():
		return
	_pending = true
	_reason = reason


## Appelé une fois par image. Aucun accès disque tant que la partie n'est pas stable.
func process(delta: float) -> void:
	if not _pending:
		return
	_retry_remaining = maxf(0.0, _retry_remaining - maxf(delta, 0.0))
	if _retry_remaining == 0.0 and _can_write() and _stable.call():
		write_now(_reason)


## Retour / arrière-plan : même garde de stabilité que les demandes différées.
func flush_if_stable(reason: String) -> Error:
	if not _can_write() or not _stable.call():
		return ERR_UNAVAILABLE
	return write_now(reason)


## La permission est toujours relue : un écran titre ou une sauvegarde future protège
## aussi les demandes déjà en attente. Un appel explicite ignore le délai de nouvelle tentative.
func write_now(reason: String) -> Error:
	if not _can_write():
		return ERR_UNAVAILABLE
	var error: Error = _writer.call(reason)
	if error == OK:
		_pending = false
		_reason = ""
		_retry_remaining = 0.0
	else:
		_pending = true
		_reason = reason
		_retry_remaining = RETRY_DELAY
	return error


func has_pending() -> bool:
	return _pending


func _can_write() -> bool:
	return _allowed.is_valid() and _stable.is_valid() and _writer.is_valid() \
		and _allowed.call()
