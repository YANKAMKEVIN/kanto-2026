class_name SafariRules
extends RefCounted
## Une rencontre du Parc Safari (J23, dossier 26 §5 ; plan `jalon-23.md` §2.3) : appât, caillou,
## fuite du Pokémon sauvage, taux de capture courant. Règles de Rouge/Bleu
## (`pret/pokered` af519899, `engine/battle/core.asm`), particularités comprises (N-5). Pure : tout
## l'aléatoire vient du [GameRng] reçu.
##
## - **Appât** : taux = taux de base ÷ 2 ; colère = 0 ; repas += 1 à 5 (plafond 255).
## - **Caillou** : taux × 2 (plafond 255) ; repas = 0 ; colère += 1 à 5 (plafond 255).
## - **Fin de tour** ([method end_turn], après toute action qui ne capture pas) : repas > 0 →
##   repas − 1 (« mange »), et le taux **revient au taux de base** quand le repas finit ; sinon colère > 0 → colère − 1 (« en colère ») ; quand la colère
##   retombe à 0, le taux **revient au taux de base de l'espèce**.
## - **Fuite** ([method flees], après la fin de tour) : b = Vitesse × 2 ; repas > 0 → b ÷ 4 ;
##   colère > 0 → min(b × 2, 255) ; fuite si un tirage 0..255 est < b. Rien avant la première
##   action ([method can_flee_now]).
## **Adouci le 2026-11-12** (décision de Kevin : « c'était vraiment dur », valeurs [D]) :
## - l'appât ne se cumule plus : il met le taux à la **moitié du taux de base**, et la fin du repas
##   **rend le taux de base** (en RB la division restait et s'empilait à chaque appât : plusieurs
##   appâts rendaient la capture presque impossible) ;
## - le seuil de fuite est multiplié par [member flee_factor] ([member SafariConfig.flee_factor]).
## Particularité RB gardée : la fin de la colère remet le taux de base. **Non reprise** : RB ne lit
## que l'octet bas de la Vitesse (sans effet ici : aucune espèce du Parc n'atteint 128).

## Réponse de [method end_turn].
const NONE: StringName = &""
const EATING: StringName = &"eating"
const ANGRY: StringName = &"angry"
## Taux de capture et compteurs : plafond (un octet en RB).
const CAP: int = 255
## Tirage des compteurs d'appât et de colère (RB : 1 à 5).
const COUNTER_MIN: int = 1
const COUNTER_MAX: int = 5
## Taille du tirage de fuite (0..255).
const FLEE_ROLL: int = 256

## Taux de capture de l'espèce (1..255), celui que la fin de la colère rétablit.
var base_rate: int = 0
## Taux de capture courant, à passer à [method CaptureCalc.throw_ball].
var rate: int = 0
## Tours de repas restants (appât).
var bait: int = 0
## Tours de colère restants (caillou).
var anger: int = 0
## Vrai dès que le joueur a agi une fois (aucun test de fuite avant).
var acted: bool = false
## Multiplicateur du seuil de fuite ([member SafariConfig.flee_factor] ; 1 = règle de RB).
var flee_factor: float = 1.0


## Rencontre d'un Pokémon de taux de capture [param catch_rate].
static func begin(catch_rate: int, flee: float = 1.0) -> SafariRules:
	var rules := SafariRules.new()
	rules.flee_factor = maxf(flee, 0.0)
	rules.base_rate = clampi(catch_rate, 1, CAP)
	rules.rate = rules.base_rate
	return rules


## Le joueur lance un appât. Tirage : un range_int(1, 5).
func throw_bait(rng: GameRng) -> void:
	acted = true
	rate = maxi(base_rate / 2, 1)
	anger = 0
	bait = mini(bait + rng.range_int(COUNTER_MIN, COUNTER_MAX), CAP)


## Le joueur lance un caillou. Tirage : un range_int(1, 5).
func throw_rock(rng: GameRng) -> void:
	acted = true
	rate = mini(rate * 2, CAP)
	bait = 0
	anger = mini(anger + rng.range_int(COUNTER_MIN, COUNTER_MAX), CAP)


## Le joueur lance une Safari Ball (la capture elle-même passe par [CaptureCalc] avec [member rate]).
func throw_ball() -> void:
	acted = true


## Fin du tour sans capture : [constant EATING], [constant ANGRY] ou [constant NONE].
func end_turn() -> StringName:
	if bait > 0:
		bait -= 1
		if bait == 0:
			rate = base_rate
		return EATING
	if anger > 0:
		anger -= 1
		if anger == 0:
			rate = base_rate
		return ANGRY
	return NONE


## Vrai si un test de fuite a lieu maintenant (pas avant la première action).
func can_flee_now() -> bool:
	return acted


## Seuil de fuite pour une Vitesse [param speed], selon l'état courant (0..255, voir la doc),
## multiplié par [member flee_factor].
func flee_threshold(speed: int) -> int:
	var b := mini(maxi(speed, 0) * 2, CAP)
	if bait > 0:
		b /= 4
	if anger > 0:
		b = mini(b * 2, CAP)
	return floori(b * flee_factor)


## Le Pokémon de Vitesse [param speed] s'enfuit-il ? Un tirage roll(256) seulement si
## [method can_flee_now] ; jamais avant la première action.
func flees(speed: int, rng: GameRng) -> bool:
	if not can_flee_now():
		return false
	return rng.roll(FLEE_ROLL) - 1 < flee_threshold(speed)
