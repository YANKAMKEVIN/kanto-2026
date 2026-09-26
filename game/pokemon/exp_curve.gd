class_name ExpCurve
extends RefCounted
## Courbes d'expérience modernes : XP totale nécessaire pour atteindre un niveau.
##
## Classe pure, statique (décision de Kevin, jalon 4 §8 point 4). Les six courbes des
## jeux ; le niveau 1 vaut toujours 0 XP. Toutes les divisions sont entières (arrondi
## vers le bas), comme dans les jeux.

enum Rate { ERRATIC, FAST, MEDIUM_FAST, MEDIUM_SLOW, SLOW, FLUCTUATING }

const RATE_NAMES: Dictionary[String, Rate] = {
	"erratic": Rate.ERRATIC, "fast": Rate.FAST, "medium_fast": Rate.MEDIUM_FAST,
	"medium_slow": Rate.MEDIUM_SLOW, "slow": Rate.SLOW, "fluctuating": Rate.FLUCTUATING,
}
const MAX_LEVEL: int = 100

@warning_ignore_start("integer_division")


## XP totale pour être au niveau [param level] (borné à 1..100).
static func exp_for_level(rate: Rate, level: int) -> int:
	var n := clampi(level, 1, MAX_LEVEL)
	if n == 1:
		return 0
	var cube := n * n * n
	var total := 0
	match rate:
		Rate.FAST:
			total = 4 * cube / 5
		Rate.MEDIUM_FAST:
			total = cube
		Rate.MEDIUM_SLOW:
			total = 6 * cube / 5 - 15 * n * n + 100 * n - 140
		Rate.SLOW:
			total = 5 * cube / 4
		Rate.ERRATIC:
			if n < 50:
				total = cube * (100 - n) / 50
			elif n < 68:
				total = cube * (150 - n) / 100
			elif n < 98:
				total = cube * ((1911 - 10 * n) / 3) / 500
			else:
				total = cube * (160 - n) / 100
		Rate.FLUCTUATING:
			if n < 15:
				total = cube * ((n + 1) / 3 + 24) / 50
			elif n < 36:
				total = cube * (n + 14) / 50
			else:
				total = cube * (n / 2 + 32) / 50
	return maxi(total, 0)


## Niveau atteint avec [param total_exp] XP totale (1..100).
static func level_for_exp(rate: Rate, total_exp: int) -> int:
	var level := 1
	while level < MAX_LEVEL and total_exp >= exp_for_level(rate, level + 1):
		level += 1
	return level
