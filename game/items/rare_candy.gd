class_name RareCandy
extends RefCounted
## Super Bonbon (jalon 14, dossier 17 §5, jalon-14.md §2.6) : classe statique et pure.
##
## Fait gagner **un niveau** à un Pokémon hors combat : l'XP est portée au seuil exact du niveau
## suivant, puis [method Pokemon.gain_exp] fait le reste (statistiques recalculées, PV montés de
## la différence, capacités du niveau listées dans le [LevelUp] ; **rien n'est appris ici** : la
## présentation les propose par [MoveLearnPrompt], comme après un combat). L'évolution due est
## seulement **signalée** ([method evolution_after]) : la présentation la joue, annulable, comme
## une évolution par niveau. Rien ici ne touche au Sac : l'appelant retire le Super Bonbon
## seulement si [method check] vaut OK (sinon l'objet est gardé).

## État d'un Pokémon face au Super Bonbon : OK, niveau 100 (« Sans effet »), K.O. (« Ce Pokémon
## est K.O. », défaut du plan §0.2 n° 16, comme les soins).
enum Check { OK, MAX_LEVEL, FAINTED }


## Vrai si [param item] est un Super Bonbon (jalon 14, T18b : [member ItemData.field_use] =
## [constant ItemData.FIELD_USE_RARE_CANDY]) : UTILISER ouvre le choix du Pokémon.
static func is_candy(item: ItemData) -> bool:
	return item != null and item.has_field_use() \
		and item.field_use == ItemData.FIELD_USE_RARE_CANDY


## Le refus de [ItemUse] qui dit la même chose que [param check] (raisons et phrases du Sac, celles
## des soins : « Sans effet », « Ce Pokémon est K.O. ») ; OK pour OK.
static func item_use_check(check: Check) -> ItemUse.Check:
	match check:
		Check.MAX_LEVEL:
			return ItemUse.Check.NO_EFFECT
		Check.FAINTED:
			return ItemUse.Check.FAINTED
	return ItemUse.Check.OK


## État de [param pokemon] face au Super Bonbon (null : FAINTED, rien n'est possible). Le
## niveau 100 passe avant le K.O. (aucun effet possible dans les deux cas).
static func check(pokemon: Pokemon) -> Check:
	if pokemon == null:
		return Check.FAINTED
	if pokemon.level >= ExpCurve.MAX_LEVEL:
		return Check.MAX_LEVEL
	if pokemon.is_fainted():
		return Check.FAINTED
	return Check.OK


## +1 niveau pour [param pokemon] (XP au seuil du niveau suivant, puis [method Pokemon.gain_exp]).
## Renvoie le [LevelUp] du niveau gagné, ou null (et rien ne change) si [method check] ne vaut
## pas OK ou si l'espèce est inconnue.
static func apply(pokemon: Pokemon, data: PokemonData) -> LevelUp:
	if check(pokemon) != Check.OK or data == null:
		return null
	var species := data.get_species(pokemon.species_id)
	if species == null:
		return null
	var needed := ExpCurve.exp_for_level(species.growth_rate, pokemon.level + 1) \
		- pokemon.experience
	var steps := pokemon.gain_exp(maxi(needed, 1), data)
	return steps[0] if not steps.is_empty() else null


## Espèce vers laquelle [param pokemon] doit évoluer après le niveau gagné (première règle
## « level » satisfaite, [method Evolution.level_up_target]), ou &"" (aucune règle par niveau,
## comme Kadabra au jalon 14, ou niveau pas encore atteint). Une évolution annulée auparavant
## revient ici, comme au prochain niveau gagné en combat (Rouge/Bleu).
static func evolution_after(pokemon: Pokemon, data: PokemonData) -> StringName:
	if pokemon == null or data == null or pokemon.is_fainted():
		return &""
	return Evolution.level_up_target(pokemon, data)
