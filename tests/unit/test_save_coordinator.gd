extends GutTest
## Permissions et nouvelles tentatives en temps simulé, sans disque ni scène.

var _coordinator: SaveCoordinator
var _allowed: bool
var _stable: bool
var _result: Error
var _writes: Array[String]


func before_each() -> void:
	_allowed = true
	_stable = true
	_result = OK
	_writes = []
	_coordinator = SaveCoordinator.new()
	_coordinator.setup(func() -> bool: return _allowed,
		func() -> bool: return _stable, _write)


func _write(reason: String) -> Error:
	_writes.append(reason)
	return _result


func test_without_requests_nothing_is_written() -> void:
	_coordinator.process(10.0)
	assert_true(_writes.is_empty())


func test_requests_are_coalesced_until_the_world_is_stable() -> void:
	_stable = false
	_coordinator.request("carte")
	_coordinator.request("capture")
	_coordinator.process(10.0)
	assert_true(_writes.is_empty())
	_stable = true
	_coordinator.process(0.0)
	assert_eq(_writes, ["capture"])
	assert_false(_coordinator.has_pending())
	_coordinator.process(1.0)
	assert_eq(_writes.size(), 1)


func test_disabled_session_refuses_every_write_path() -> void:
	_allowed = false
	_coordinator.request("demande")
	_coordinator.process(10.0)
	assert_eq(_coordinator.write_now("direct"), ERR_UNAVAILABLE)
	assert_eq(_coordinator.flush_if_stable("pause"), ERR_UNAVAILABLE)
	assert_false(_coordinator.has_pending())
	assert_true(_writes.is_empty())


func test_permission_is_rechecked_after_a_request() -> void:
	_coordinator.request("carte")
	_allowed = false
	_coordinator.process(10.0)
	assert_true(_writes.is_empty())
	assert_true(_coordinator.has_pending())
	_allowed = true
	_coordinator.process(0.0)
	assert_eq(_writes, ["carte"])


func test_background_flush_does_not_write_an_unstable_world() -> void:
	_stable = false
	assert_eq(_coordinator.flush_if_stable("pause"), ERR_UNAVAILABLE)
	assert_true(_writes.is_empty())
	_stable = true
	assert_eq(_coordinator.flush_if_stable("pause"), OK)
	assert_eq(_writes, ["pause"])


func test_explicit_checkpoint_can_write_during_a_cutscene() -> void:
	_stable = false
	assert_eq(_coordinator.write_now("départ"), OK)
	assert_eq(_writes, ["départ"])


func test_failure_keeps_the_request_without_retrying_every_frame() -> void:
	_result = ERR_FILE_CANT_WRITE
	_coordinator.request("capture")
	_coordinator.process(0.0)
	assert_eq(_writes.size(), 1)
	assert_true(_coordinator.has_pending())
	_coordinator.process(SaveCoordinator.RETRY_DELAY - 1.0)
	assert_eq(_writes.size(), 1)
	_result = OK
	_coordinator.process(1.0)
	assert_eq(_writes, ["capture", "capture"])
	assert_false(_coordinator.has_pending())


func test_retry_still_waits_for_a_stable_world_and_current_permission() -> void:
	_result = ERR_CANT_OPEN
	_coordinator.write_now("menu")
	_result = OK
	_stable = false
	_coordinator.process(SaveCoordinator.RETRY_DELAY)
	assert_eq(_writes.size(), 1)
	_stable = true
	_allowed = false
	_coordinator.process(1.0)
	assert_eq(_writes.size(), 1)
	_allowed = true
	_coordinator.process(0.0)
	assert_eq(_writes.size(), 2)


func test_new_request_preserves_the_retry_delay_and_saves_the_latest_reason() -> void:
	_result = ERR_FILE_CANT_WRITE
	_coordinator.write_now("ancien")
	_coordinator.request("nouveau")
	_result = OK
	_coordinator.process(0.0)
	assert_eq(_writes, ["ancien"])
	_coordinator.process(SaveCoordinator.RETRY_DELAY)
	assert_eq(_writes, ["ancien", "nouveau"])


func test_successful_explicit_save_clears_a_pending_retry() -> void:
	_result = ERR_FILE_CANT_WRITE
	_coordinator.write_now("auto")
	_result = OK
	assert_eq(_coordinator.write_now("manuel"), OK)
	_coordinator.process(100.0)
	assert_eq(_writes, ["auto", "manuel"])
	assert_false(_coordinator.has_pending())


func test_unconfigured_coordinator_is_safe_before_ready() -> void:
	var coordinator := SaveCoordinator.new()
	coordinator.request("pause")
	coordinator.process(1.0)
	assert_eq(coordinator.flush_if_stable("pause"), ERR_UNAVAILABLE)
	assert_eq(coordinator.write_now("pause"), ERR_UNAVAILABLE)


func test_negative_delta_does_not_advance_the_retry() -> void:
	_result = ERR_FILE_CANT_WRITE
	_coordinator.write_now("auto")
	_coordinator.process(-1.0)
	_coordinator.process(SaveCoordinator.RETRY_DELAY - 1.0)
	assert_eq(_writes.size(), 1)
