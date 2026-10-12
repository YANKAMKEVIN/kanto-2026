class_name Daycare
extends RefCounted
## État de la Pension Pokémon (J15, 15.0 ; dossier 18, V-1 et F-1 validés par Kevin le
## 2026-10-11) : **un seul** Pokémon gardé, sans reproduction, son XP **en attente** et son
## niveau au dépôt. Classe pure ; les règles (dépôt, retrait, prix) sont dans [DaycareRules].
##
## - L'XP gagnée pendant le séjour reste dans [member pending_exp], **jamais** dans
##   [member Pokemon.experience] : elle n'est appliquée qu'au retrait, par
##   [method Pokemon.gain_exp] ([method DaycareRules.withdraw]). Écrire directement dans
##   `experience` désynchroniserait niveau et XP (`Pokemon.from_dict` ne recalcule pas le niveau).
## - L'XP en attente est plafonnée à celle qui mène au niveau 100 ([member exp_room]).
## - Rien ne change pendant le séjour : ni niveau, ni capacités, ni évolution, ni soin.
##
## **Compteur de pas (15A, non branché ici)** : un pas = un [signal Player.moved] émis pendant
## que [method Player.is_input_enabled] est vrai (même filtre que `SceneRouter._on_player_moved` :
## les pas scriptés ne comptent pas) ; la course compte comme la marche ; un pas refusé (mur,
## [signal Player.bumped]) n'émet pas `moved` et ne compte donc pas. Le relais appellera
## [method add_steps] avec le [DaycareConfig] chargé.
##
## **Sauvegarde (v7, J15 T2)** : [method to_dict] / [method from_dict] sont appelés par
## `GameState` (champ « daycare ») ; migration v6 → v7 sans transformation (Pension vide) ;
## Pension incluse dans `GameState.ensure_unique_uids()` ; un compagnon déposé n'est plus
## compagnon (`GameState.get_companion` ne cherche que dans l'équipe). L'uid du Pokémon déposé
## est posé au dépôt par le directeur (T4, `ensure_uid`) et au chargement s'il manque.

## Le Pokémon gardé, ou null (Pension vide).
var pokemon: Pokemon = null
## XP gagnée pendant le séjour, pas encore appliquée.
var pending_exp: int = 0
## Niveau du Pokémon au dépôt (0 si la Pension est vide).
var deposit_level: int = 0
## XP qu'il reste au Pokémon avant le niveau 100 (plafond de [member pending_exp]).
var exp_room: int = 0


func is_empty() -> bool:
	return pokemon == null


## Confie [param mon] à la Pension (sans règle : voir [method DaycareRules.deposit]). XP en
## attente remise à 0, niveau au dépôt noté, plafond calculé avec la courbe de l'espèce.
func put(mon: Pokemon, data: PokemonData) -> void:
	pokemon = mon
	pending_exp = 0
	deposit_level = mon.level if mon != null else 0
	exp_room = _room_for(mon, data)


## Rend le Pokémon gardé et vide la Pension (sans appliquer l'XP : voir
## [method DaycareRules.withdraw]), ou null si elle est vide.
func take() -> Pokemon:
	var mon := pokemon
	pokemon = null
	pending_exp = 0
	deposit_level = 0
	exp_room = 0
	return mon


## Ajoute l'XP de [param steps] pas ([member DaycareConfig.exp_per_step] chacun), plafonnée au
## niveau 100. Renvoie l'XP réellement ajoutée (0 si la Pension est vide, si [param steps] ≤ 0
## ou si le plafond est atteint).
func add_steps(steps: int, config: DaycareConfig) -> int:
	if is_empty() or steps <= 0 or config == null:
		return 0
	var added := mini(steps * config.exp_per_step, exp_room - pending_exp)
	if added <= 0:
		return 0
	pending_exp += added
	return added


## Niveau que le Pokémon atteindrait si l'XP en attente était appliquée (0 si vide).
func level_after(data: PokemonData) -> int:
	if is_empty():
		return 0
	var species := data.get_species(pokemon.species_id)
	if species == null:
		return pokemon.level
	var total := pokemon.experience + pending_exp
	return maxi(ExpCurve.level_for_exp(species.growth_rate, total), pokemon.level)


## Niveaux qui seraient gagnés au retrait (0 si vide).
func levels_gained(data: PokemonData) -> int:
	return level_after(data) - pokemon.level if not is_empty() else 0


## État prêt pour le JSON (sauvegarde v7, champ « daycare ») : objet vide si la Pension est
## vide.
func to_dict() -> Dictionary:
	if is_empty():
		return {}
	return {
		"pokemon": pokemon.to_dict(),
		"pending_exp": pending_exp,
		"deposit_level": deposit_level,
	}


## Pension écrite par [method to_dict]. Objet vide (ou sans « pokemon ») → Pension vide ; null
## (push_error) si le Pokémon est invalide : GameState vide alors la Pension et signale le
## refus (Boot garde l'original en `save.json.rejected`), rien n'est perdu en silence. XP en attente bornée à [0, plafond] ; niveau au dépôt absent ou invalide →
## niveau actuel.
static func from_dict(dict: Dictionary, data: PokemonData) -> Daycare:
	var daycare := Daycare.new()
	var entry: Variant = dict.get("pokemon")
	if entry == null:
		return daycare
	var mon: Pokemon = Pokemon.from_dict(entry, data) if entry is Dictionary else null
	if mon == null:
		push_error("Daycare.from_dict : Pokémon de la Pension invalide")
		return null
	daycare.put(mon, data)
	daycare.pending_exp = clampi(JsonFields.get_int(dict, "pending_exp"), 0, daycare.exp_room)
	var level := JsonFields.get_int(dict, "deposit_level", mon.level)
	daycare.deposit_level = level if level >= 1 and level <= mon.level else mon.level
	return daycare


static func _room_for(mon: Pokemon, data: PokemonData) -> int:
	if mon == null or data == null:
		return 0
	var species := data.get_species(mon.species_id)
	if species == null:
		return 0
	var cap := ExpCurve.exp_for_level(species.growth_rate, ExpCurve.MAX_LEVEL)
	return maxi(cap - mon.experience, 0)
