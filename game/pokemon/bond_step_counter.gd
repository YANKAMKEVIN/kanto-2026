class_name BondStepCounter
extends RefCounted
## Compteur de pas du lien et des œufs (JOH0, `jalon-joh0.md` §2.7 et §2.9). Classe pure, même
## modèle que [DaycareStepCounter] : Boot l'appelle à chaque [signal Player.moved] avec
## [method Player.is_input_enabled] (un pas scripté ne compte pas).
##
## - Tous les [constant BondRules.STEPS_PER_POINT] pas comptés, chaque Pokémon de l'équipe qui
##   n'est pas un œuf gagne +1 de lien, le compagnon [constant BondRules.COMPANION_BONUS] de plus.
## - Chaque pas compté retire 1 aux pas restants de chaque œuf de l'équipe ; un œuf arrivé à 0
##   est rendu dans « hatched » : Boot joue l'éclosion ([EggRules]) au pas suivant hors combat,
##   hors scène, hors menu.
## Le compteur n'est pas sauvegardé **[D]** (moins de 256 pas perdus à la fermeture).

## Pas comptés depuis la création (journal de QA, tests).
var _counted: int = 0
## Pas comptés depuis le dernier point de lien.
var _since_bond: int = 0


## Un pas du joueur vient de finir. Rend `{ "bond": bool (un point de lien vient d'être
## donné), "hatched": Array[Pokemon] (œufs arrivés à 0 à ce pas) }`.
func on_player_moved(party: Party, companion_uid: String, input_enabled: bool) -> Dictionary:
	var result := {"bond": false, "hatched": [] as Array[Pokemon]}
	if not input_enabled or party == null or party.size() == 0:
		return result
	_counted += 1
	_since_bond += 1
	var hatched: Array[Pokemon] = result["hatched"]
	for pokemon: Pokemon in party.get_all():
		if pokemon.is_egg():
			pokemon.egg_steps -= 1
			if pokemon.egg_steps <= 0:
				# L'éclosion (EggRules.hatch) remet le compteur à 0 ; d'ici là, l'œuf reste un œuf
				# (1 pas restant) pour que l'équipe ne le voie pas combattre.
				pokemon.egg_steps = 1
				hatched.append(pokemon)
	if _since_bond >= BondRules.STEPS_PER_POINT:
		_since_bond = 0
		result["bond"] = true
		for pokemon: Pokemon in party.get_all():
			if pokemon.is_egg():
				continue
			var gain := 1
			if not companion_uid.is_empty() and pokemon.uid == companion_uid:
				gain += BondRules.COMPANION_BONUS
			pokemon.add_bond(gain)
	return result


## Pas comptés (entrée libre, équipe non vide).
func counted() -> int:
	return _counted


## Pas comptés depuis le dernier point de lien.
func since_bond() -> int:
	return _since_bond
