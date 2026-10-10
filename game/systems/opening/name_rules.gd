class_name NameRules
extends RefCounted
## Règles du prénom du joueur et du rival (dossier 13, arbitrage A7, §5.5, §7).
##
## Classe pure et statique. Un prénom compte 1 à `max_length` caractères (10, lu dans
## `data/opening/names.json` par [OpeningNames]) ; il ne contient que des **lettres** (toutes
## les écritures, accentuées comprises), des espaces, des traits d'union et des apostrophes ;
## ni chiffre, ni emoji, ni autre ponctuation. Aucun filtre de mots (jeu personnel), et le
## joueur et le rival peuvent porter le même prénom.
##
## Trois usages :
##  - [method normalize] : la forme retenue (bords retirés, espaces internes réduits à un seul,
##    apostrophe droite remplacée par « ’ », première lettre en majuscule, rien d'autre) ;
##  - [method validate] : le code de [enum Result] de la forme normalisée ([b]Valider[/b] n'est
##    actif que sur [constant OK]) ;
##  - [method filter_input] : le filtre de la saisie en direct (frappe ou collage), qui retire
##    les caractères refusés sans normaliser les bords (on peut taper « Jean » puis une espace
##    puis « Luc ») ; [method has_invalid_chars] dit s'il faut afficher l'aide sous le champ.
## La longueur se compte en caractères Unicode ([method String.length]).

enum Result {
	OK,
	## Rien de nommable : vide, espaces seulement, ou aucune lettre (« - », « ’ »).
	EMPTY,
	TOO_LONG,
	## Un caractère hors de la liste permise (chiffre, emoji, ponctuation…).
	INVALID_CHAR,
}

## Apostrophe retenue (typographique) ; l'apostrophe droite est convertie en elle.
const APOSTROPHE: String = "’"
const STRAIGHT_APOSTROPHE: String = "'"
const HYPHEN: String = "-"
const SPACE: String = " "
## Aide affichée sous le champ quand un caractère est refusé (dossier 13 §5.5).
const INVALID_CHAR_HELP: String = "Lettres, espaces, - et ’ seulement"
## Blancs ramenés à une espace simple : tabulation, retours à la ligne, espaces insécables
## (fine comprise, fréquente sur un clavier français) et espaces typographiques.
const _BLANKS: Array[int] = [
	0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20, 0x85, 0xA0, 0x1680, 0x2000, 0x2001, 0x2002, 0x2003,
	0x2004, 0x2005, 0x2006, 0x2007, 0x2008, 0x2009, 0x200A, 0x2028, 0x2029, 0x202F, 0x205F,
	0x3000,
]
## Diacritiques combinants (forme décomposée « e » + « ́ ») : permis juste après une lettre.
const _COMBINING_FIRST: int = 0x0300
const _COMBINING_LAST: int = 0x036F


## Forme retenue de [param raw] : blancs ramenés à une espace, bords retirés, espaces internes
## multiples réduites à une seule, « ' » remplacée par « ’ », première lettre en majuscule (les
## autres lettres ne changent pas : « mcFly » → « McFly », « ÉLODIE » reste « ÉLODIE »). Ne
## retire aucun caractère refusé : [method validate] les signale.
static func normalize(raw: String) -> String:
	var spaced := _unify(raw)
	var words := PackedStringArray()
	for part: String in spaced.split(SPACE, false):
		words.append(part)
	return _capitalize_first_letter(SPACE.join(words))


## Code de validation de [param raw] (normalisé d'abord) pour [param max_length] caractères au
## plus. Ordre des contrôles : vide, caractère refusé (l'aide s'affiche), aucune lettre (vide
## aussi), longueur.
static func validate(raw: String, max_length: int) -> Result:
	var name := normalize(raw)
	if name.is_empty():
		return Result.EMPTY
	if has_invalid_chars(name):
		return Result.INVALID_CHAR
	if not _has_letter(name):
		return Result.EMPTY
	if name.length() > max_length:
		return Result.TOO_LONG
	return Result.OK


## Vrai si [param raw] est un prénom valide une fois normalisé.
static func is_valid(raw: String, max_length: int) -> bool:
	return validate(raw, max_length) == Result.OK


## Vrai si [param text] contient un caractère refusé (les blancs ne le sont pas : ils sont
## normalisés). Sert à afficher [constant INVALID_CHAR_HELP] pendant la saisie.
static func has_invalid_chars(text: String) -> bool:
	var previous_is_letter := false
	for i: int in text.length():
		var c := text.substr(i, 1)
		if not _is_allowed(c, previous_is_letter) and not _is_blank(c):
			return true
		previous_is_letter = _is_letter(c) or (previous_is_letter and _is_combining(c))
	return false


## Filtre de la saisie en direct (frappe ou collage) : caractères refusés retirés, blancs
## ramenés à une espace, espaces en tête retirées, espaces doubles réduites, « ' » → « ’ »,
## tronqué à [param max_length] caractères. L'espace finale est gardée (le mot suivant arrive)
## et la casse n'est pas touchée : [method normalize] fait le reste à la validation.
static func filter_input(raw: String, max_length: int) -> String:
	var kept := ""
	var previous_is_letter := false
	for i: int in raw.length():
		var c := raw.substr(i, 1)
		if _is_blank(c):
			if not kept.is_empty() and not kept.ends_with(SPACE):
				kept += SPACE
			previous_is_letter = false
			continue
		if not _is_allowed(c, previous_is_letter):
			continue
		kept += APOSTROPHE if c == STRAIGHT_APOSTROPHE else c
		previous_is_letter = _is_letter(c) or (previous_is_letter and _is_combining(c))
	return kept.left(max_length) if max_length >= 0 else kept


## Caractère seul permis : lettre, espace, trait d'union, apostrophe (droite ou « ’ ») ;
## diacritique combinant seulement après une lettre.
static func _is_allowed(c: String, previous_is_letter: bool) -> bool:
	if c == SPACE or c == HYPHEN or c == APOSTROPHE or c == STRAIGHT_APOSTROPHE:
		return true
	if _is_combining(c):
		return previous_is_letter
	return _is_letter(c)


## Lettre de n'importe quelle écriture (catégories Unicode des débuts d'identifiant : L*, Nl),
## sans le « _ » que Godot y ajoute. Chiffres, emoji et ponctuation n'en sont pas.
static func _is_letter(c: String) -> bool:
	return c.length() == 1 and c != "_" and c.is_valid_unicode_identifier()


static func _is_combining(c: String) -> bool:
	var code := c.unicode_at(0)
	return code >= _COMBINING_FIRST and code <= _COMBINING_LAST


static func _is_blank(c: String) -> bool:
	return _BLANKS.has(c.unicode_at(0))


static func _has_letter(text: String) -> bool:
	for i: int in text.length():
		if _is_letter(text.substr(i, 1)):
			return true
	return false


## Blancs → espace, « ' » → « ’ ».
static func _unify(raw: String) -> String:
	var out := ""
	for i: int in raw.length():
		var c := raw.substr(i, 1)
		if _is_blank(c):
			out += SPACE
		elif c == STRAIGHT_APOSTROPHE:
			out += APOSTROPHE
		else:
			out += c
	return out


static func _capitalize_first_letter(text: String) -> String:
	for i: int in text.length():
		var c := text.substr(i, 1)
		if _is_letter(c):
			return text.left(i) + c.to_upper() + text.substr(i + 1)
	return text
