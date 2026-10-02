extends DeviceClock
## DeviceClock des tests : date imposée, avancée à la main (jalon 5 §16.3).
##
## Utilisation : [code]const FixedClock := preload("res://tests/helpers/fixed_clock.gd")[/code].

var iso: String = "2026-10-02T14:03:05"


func _init(date: String = "2026-10-02T14:03:05") -> void:
	iso = date


func now_iso() -> String:
	return iso
