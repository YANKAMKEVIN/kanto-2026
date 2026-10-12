class_name PokemonUid
extends RefCounted
## Identifiant stable d'un Pokémon du joueur (jalon 11, `jalon-11.md` §2.1, dossier 14 §9).
##
## Classe statique et pure. Un identifiant = [constant LENGTH] chiffres hexadécimaux en
## minuscules, tirés d'un générateur **à part** : jamais [GameRng], pour que l'attribution d'un
## identifiant ne décale pas l'aléatoire du jeu (combats, rencontres, simulations). Il désigne
## un Pokémon sans dépendre de sa place (le compagnon du J11 : [member GameState.companion_uid]).
## Unicité : 64 bits tirés au hasard, plus la vérification de [method GameState.ensure_unique_uids]
## au chargement (un fichier retouché à la main peut contenir un doublon).

const LENGTH: int = 16
const _HEX: String = "0123456789abcdef"

static var _rng: RandomNumberGenerator = null


## Un identifiant neuf.
static func generate() -> String:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	var result := ""
	for i: int in LENGTH:
		result += _HEX[_rng.randi_range(0, 15)]
	return result


## Vrai si [param value] a la forme d'un identifiant ([constant LENGTH] hexadécimaux minuscules).
static func is_valid(value: Variant) -> bool:
	if not value is String or (value as String).length() != LENGTH:
		return false
	for character: String in value as String:
		if not _HEX.contains(character):
			return false
	return true
