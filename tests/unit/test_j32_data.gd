extends GutTest
## Lot 32K (jalon-32.md T3, §0.0) : les évolutions de Rouge/Bleu sont déclarées dans
## `data/pokemon/species/` dès que les deux espèces existent. Garde-fou de fusion : quand
## Mackogneur, Ectoplasma ou Noadkoko arrivent dans `main` (J29, J30), ce test rappelle
## d'ajouter Machopeur → Mackogneur, Spectrum → Ectoplasma (échange) et Noeunoeuf → Noadkoko.

## « de:vers:méthode » (méthode : level, trade ou identifiant de pierre), d'après pret/pokered.
const RB_EVOLUTIONS: Array[String] = [
	"bulbasaur:ivysaur:level", "ivysaur:venusaur:level", "charmander:charmeleon:level",
	"charmeleon:charizard:level", "squirtle:wartortle:level", "wartortle:blastoise:level",
	"caterpie:metapod:level", "metapod:butterfree:level", "weedle:kakuna:level",
	"kakuna:beedrill:level", "pidgey:pidgeotto:level", "pidgeotto:pidgeot:level",
	"rattata:raticate:level", "spearow:fearow:level", "ekans:arbok:level",
	"pikachu:raichu:thunder_stone", "sandshrew:sandslash:level", "nidoran_f:nidorina:level",
	"nidorina:nidoqueen:moon_stone", "nidoran_m:nidorino:level", "nidorino:nidoking:moon_stone",
	"clefairy:clefable:moon_stone", "vulpix:ninetales:fire_stone",
	"jigglypuff:wigglytuff:moon_stone", "zubat:golbat:level", "oddish:gloom:level",
	"gloom:vileplume:leaf_stone", "paras:parasect:level", "venonat:venomoth:level",
	"diglett:dugtrio:level", "meowth:persian:level", "psyduck:golduck:level",
	"mankey:primeape:level", "growlithe:arcanine:fire_stone", "poliwag:poliwhirl:level",
	"poliwhirl:poliwrath:water_stone", "abra:kadabra:level", "kadabra:alakazam:trade",
	"machop:machoke:level", "machoke:machamp:trade", "bellsprout:weepinbell:level",
	"weepinbell:victreebel:leaf_stone", "tentacool:tentacruel:level", "geodude:graveler:level",
	"graveler:golem:trade", "ponyta:rapidash:level", "slowpoke:slowbro:level",
	"magnemite:magneton:level", "doduo:dodrio:level", "seel:dewgong:level", "grimer:muk:level",
	"shellder:cloyster:water_stone", "gastly:haunter:level", "haunter:gengar:trade",
	"drowzee:hypno:level", "krabby:kingler:level", "voltorb:electrode:level",
	"exeggcute:exeggutor:leaf_stone", "cubone:marowak:level", "koffing:weezing:level",
	"rhyhorn:rhydon:level", "horsea:seadra:level", "goldeen:seaking:level",
	"staryu:starmie:water_stone", "magikarp:gyarados:level", "eevee:vaporeon:water_stone",
	"eevee:jolteon:thunder_stone", "eevee:flareon:fire_stone", "omanyte:omastar:level",
	"kabuto:kabutops:level", "dratini:dragonair:level", "dragonair:dragonite:level",
]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _rule(from: StringName, into: StringName) -> EvolutionRule:
	for rule: EvolutionRule in _data.get_species(from).evolutions:
		if rule.into == into:
			return rule
	return null


func test_data_loads_without_errors() -> void:
	assert_eq(_data.get_errors(), PackedStringArray())


func test_every_rb_evolution_between_known_species_is_declared() -> void:
	var checked := 0
	for entry: String in RB_EVOLUTIONS:
		var parts := entry.split(":")
		var from := StringName(parts[0])
		var into := StringName(parts[1])
		if not _data.has_species(from) or not _data.has_species(into):
			continue
		checked += 1
		var rule := _rule(from, into)
		assert_not_null(rule, "%s → %s absente des données" % [from, into])
		if rule == null:
			continue
		match parts[2]:
			"level":
				assert_eq(rule.method, EvolutionRule.Method.LEVEL, entry)
			"trade":
				assert_eq(rule.method, EvolutionRule.Method.TRADE, entry)
			_:
				assert_eq(rule.method, EvolutionRule.Method.ITEM, entry)
				assert_eq(rule.item, StringName(parts[2]), entry)
	assert_gt(checked, 50, "assez de paires vérifiées")


func test_32k_level_evolutions_follow_red_and_blue() -> void:
	for case: Array in [[&"machop", &"machoke", 28], [&"voltorb", &"electrode", 30],
			[&"koffing", &"weezing", 35]]:
		var below := PokemonFactory.create(_data, case[0], case[2] - 1, GameRng.new(1))
		assert_eq(Evolution.level_up_target(below, _data), &"", "%s sous le niveau" % case[0])
		var at := PokemonFactory.create(_data, case[0], case[2], GameRng.new(1))
		assert_eq(Evolution.level_up_target(at, _data), case[1], str(case[0]))
