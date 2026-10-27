class_name VolumeMath
extends RefCounted
## Volume d'un curseur des Paramètres (0 à 1) → décibels d'un bus (docs/tech/jalon-son.md
## §1.9). Pur.
##
## 0 → bus **coupé** ([method is_muted], `AudioServer.set_bus_mute`) ; sinon une courbe douce
## `x²` [D] avant `linear_to_db`, pour que 50 % s'entende « à moitié » : 100 % = 0 dB,
## 50 % ≈ −12 dB, 10 % = −40 dB.

## Décibels d'un bus coupé (plancher de Godot).
const MUTED_DB: float = -80.0
## En dessous : coupé.
const EPSILON: float = 0.001


## Décibels du volume [param volume] (borné à 0–1).
static func to_db(volume: float) -> float:
	var v := clampf(volume, 0.0, 1.0)
	if v < EPSILON:
		return MUTED_DB
	return maxf(linear_to_db(v * v), MUTED_DB)


static func is_muted(volume: float) -> bool:
	return volume < EPSILON
