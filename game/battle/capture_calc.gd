class_name CaptureCalc
extends RefCounted
## Formule de capture des 3e et 4e générations (jalon 5 §2.4, Q33). Statique et pur.
##
## a = ⌊(3·PVmax − 2·PV) · taux · bonus_ball / (3·PVmax)⌋ × bonus_statut (1 au jalon 5 : pas
## de statuts) ; a ≥ 255 → capturé sans tirage. Sinon b = ⌊1 048 560 / √√(16 711 680 / a)⌋ et
## jusqu'à 4 tests « roll(65536) − 1 < b », arrêtés au premier échec : capturé si les 4
## réussissent. Secousses montrées = min(tests réussis, 3). Pas de capture critique.
## Ordre des tirages : 0 (a ≥ 255) à 4 roll(65536), un par test, dans l'ordre.

## Valeur de a à partir de laquelle la capture est assurée.
const CERTAIN: int = 255
## Tests de secousse (une capture les réussit tous).
const SHAKE_TESTS: int = 4
## Secousses montrées au plus (la 4e réussite est le « clic »).
const SHOWN_SHAKES: int = 3
## Taille du tirage de chaque test (0..65535).
const ROLL_SIZE: int = 65536


## Lance une Ball sur un Pokémon de [param hp] / [param max_hp] PV, de taux de capture
## [param catch_rate] (1..255, [member SpeciesData.catch_rate]), avec le multiplicateur de la
## Ball [param ball_bonus] ([member ItemData.catch_bonus]). L'aléatoire vient de [param rng].
static func throw_ball(max_hp: int, hp: int, catch_rate: int, ball_bonus: float,
		rng: GameRng, status_bonus: float = 1.0) -> CaptureResult:
	var a := catch_value(max_hp, hp, catch_rate, ball_bonus, status_bonus)
	if a >= CERTAIN:
		return CaptureResult.new(true, SHOWN_SHAKES)
	var b := shake_threshold(a)
	var passed := 0
	while passed < SHAKE_TESTS:
		if rng.roll(ROLL_SIZE) - 1 >= b:
			break
		passed += 1
	return CaptureResult.new(passed == SHAKE_TESTS, mini(passed, SHOWN_SHAKES))


## Valeur a de la formule (au moins 1 : un a nul rendrait b indéfini ; ≥ 255 = assurée).
static func catch_value(max_hp: int, hp: int, catch_rate: int, ball_bonus: float,
		status_bonus: float = 1.0) -> int:
	var top := maxi(max_hp, 1) * 3
	var current := clampi(hp, 0, maxi(max_hp, 1))
	var a := floori(float((top - 2 * current) * catch_rate) * ball_bonus / float(top))
	return maxi(floori(a * status_bonus), 1)


## Seuil b de chaque test de secousse pour [param a] (a ≥ 255 : 65 535 et plus, tout passe).
static func shake_threshold(a: int) -> int:
	return floori(1048560.0 / sqrt(sqrt(16711680.0 / float(maxi(a, 1)))))


## Probabilité exacte de capture (0..1) : 1 si a ≥ 255, sinon (b / 65 536)⁴. Pour les
## rapports et les réglages ; le jeu passe par [method throw_ball].
static func chance(max_hp: int, hp: int, catch_rate: int, ball_bonus: float,
		status_bonus: float = 1.0) -> float:
	var a := catch_value(max_hp, hp, catch_rate, ball_bonus, status_bonus)
	if a >= CERTAIN:
		return 1.0
	return pow(minf(float(shake_threshold(a)) / ROLL_SIZE, 1.0), SHAKE_TESTS)
