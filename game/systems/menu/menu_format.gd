class_name MenuFormat
extends RefCounted
## Mise en forme française des nombres et des dates du Menu Dresseur (Équipe, Pokédex,
## Dresseur ; jalon-06.md §13). Classe pure, statique.

const MONTHS: Array[String] = [
	"janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre",
	"octobre", "novembre", "décembre",
]
## Séparateur des milliers (espace insécable : « 1 250 XP » ne se coupe pas).
const THOUSANDS_SEPARATOR: String = " "


## « 2 octobre 2026 », « 1er novembre 2026 » d'après une date ISO (`2026-10-02T19:07:52`, ou
## `2026-10-02`) ; "" si la date est vide ou illisible.
static func long_date(iso: String) -> String:
	var parts := iso.get_slice("T", 0).split("-")
	if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() \
			or not parts[2].is_valid_int():
		return ""
	var year := parts[0].to_int()
	var month := parts[1].to_int()
	var day := parts[2].to_int()
	if year < 1 or month < 1 or month > 12 or day < 1 or day > 31:
		return ""
	var day_text := "1er" if day == 1 else str(day)
	return "%s %s %d" % [day_text, MONTHS[month - 1], year]


## Entier avec ses milliers séparés : 117360 → « 117 360 », -1500 → « -1 500 ».
static func number(value: int) -> String:
	var digits := str(absi(value))
	var result := ""
	while digits.length() > 3:
		result = THOUSANDS_SEPARATOR + digits.right(3) + result
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + result


## Temps de jeu : « 0 h 07 », « 12 h 43 » (heures, puis minutes entamées non comptées ;
## négatif → 0). Tableau de bord et écran Dresseur (jalon-06.md §13).
static func play_time(seconds: float) -> String:
	var minutes := int(floorf(maxf(seconds, 0.0) / 60.0))
	return "%d h %02d" % [floori(minutes / 60.0), minutes % 60]
