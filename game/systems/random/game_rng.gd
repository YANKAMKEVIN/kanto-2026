class_name GameRng
extends RefCounted
## Aléatoire injectable du jeu (docs/tech/jalon-04.md §2.1).
##
## Classe pure : enveloppe un [RandomNumberGenerator] à graine. Tout l'aléatoire du jeu
## (IV, sexe, combat, IA) passe par une instance reçue en paramètre, jamais par les
## fonctions globales : même graine, mêmes appels → mêmes résultats.
## Toutes les méthodes reposent sur [method roll] (le seul tirage réel) : les tests
## remplacent cette méthode par une file de valeurs imposées (`tests/helpers/scripted_rng.gd`).

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _seed: int = 0


## [param rng_seed] : graine ; −1 (ou toute valeur négative) = graine tirée, puis gardée
## ([method get_seed]) pour pouvoir rejouer la même partie.
func _init(rng_seed: int = -1) -> void:
	if rng_seed < 0:
		var source := RandomNumberGenerator.new()
		source.randomize()
		rng_seed = source.randi()
	_seed = rng_seed
	_rng.seed = rng_seed


## Graine utilisée (toujours ≥ 0).
func get_seed() -> int:
	return _seed


## Entier uniforme de 1 à [param n] inclus ([param n] ≥ 1 ; sinon 1 et push_error).
func roll(n: int) -> int:
	if n < 1:
		push_error("GameRng : roll(%d) demande n ≥ 1" % n)
		return 1
	return _rng.randi_range(1, n)


## Entier uniforme de [param from] à [param to] inclus ([param to] ≥ [param from]).
func range_int(from: int, to: int) -> int:
	return from + roll(to - from + 1) - 1


## Vrai avec la probabilité [param num] / [param den].
func chance(num: int, den: int) -> bool:
	return roll(den) <= num


## Index uniforme dans un tableau de [param size] éléments (0 .. size − 1).
func pick_index(size: int) -> int:
	return roll(size) - 1


## Graine et position courante, prêtes pour le JSON (sauvegarde, jalon 5 §16.2). En chaînes :
## l'état est un entier 64 bits que les flottants de JSON ne gardent pas intact.
func to_dict() -> Dictionary:
	return {"seed": str(_seed), "state": str(_rng.state)}


## Aléatoire repris exactement où [method to_dict] l'a laissé, ou null (push_error) si le
## contenu est invalide : la partie rechargée ne rejoue pas les mêmes tirages qu'avant.
static func from_dict(dict: Dictionary) -> GameRng:
	var seed_text := JsonFields.get_string(dict, "seed")
	var state_text := JsonFields.get_string(dict, "state")
	if not seed_text.is_valid_int() or not state_text.is_valid_int() or seed_text.to_int() < 0:
		push_error("GameRng.from_dict : graine ou état invalide")
		return null
	var rng := GameRng.new(seed_text.to_int())
	rng._rng.state = state_text.to_int()
	return rng
