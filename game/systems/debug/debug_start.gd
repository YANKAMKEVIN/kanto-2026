class_name DebugStart
extends RefCounted
## Départ de débogage (jalon 5 T9) : une partie construite depuis un petit fichier de
## fixtures (carte de départ, équipe, niveaux, capacités, Sac, drapeaux), pour tester l'XP,
## l'oubli ou la Route 1 sans rejouer le prologue. Classe pure : lecture, validation stricte,
## puis [method apply] sur l'état de la partie.
##
## [b]Quand est-il lu ?[/b] Par [Boot], seulement si les trois conditions sont réunies
## ([method is_allowed] pour les deux premières) :
## - build debug ([method OS.is_debug_build]) : jamais dans un export release ;
## - [Boot] est la scène principale lancée par le moteur : jamais sous GUT ni dans un outil
##   (ils instancient Boot eux-mêmes) ;
## - le fichier [constant USER_PATH] existe. Il n'existe pas par défaut : on l'y dépose
##   (`tools/deploy_s24.sh --debug-start <nom>` sur le S24, depuis `tools/debug_start/`).
##
## Format (toutes les clés sauf « party » sont facultatives) :
## [codeblock]
## {
##   "map": "route_1", "spawn": "from_pallet_w", "facing": "up", "seed": 42,
##   "flags": ["starter_chosen"],
##   "party": [
##     { "species": "bulbasaur", "level": 19, "exp_to_next": 1,
##       "moves": ["tackle", "growl", "leech_seed", "vine_whip"] }
##   ],
##   "bag": { "poke_ball": 5, "potion": 4 },
##   "favorites": ["potion"],
##   "money": 6000,
##   "storage": [ { "species": "rattata", "level": 4 } ]
## }
## [/codeblock]
## Équipe : 1 à 6 Pokémon créés par [PokemonFactory] (capacités de Rouge/Bleu au niveau) ;
## « moves » (1 à 4, distinctes) les remplace ; « exp_to_next » fixe l'XP qui manque pour le
## niveau suivant (1 = un seul point) ; « hp » fixe les PV de départ (0 = K.O., borné aux PV
## max). Le starter est le premier de l'équipe ; chaque espèce
## de l'équipe est « capturée » au Pokédex. Sans « map », départ par défaut de [Boot].
## Jalon 7 (sauvegarde v3) : « money » (0 à GameState.MONEY_MAX ; absent : la somme d'une
## nouvelle partie) ; « storage » : Pokémon du Stockage, même format que les membres de l'équipe
## (au plus [constant MAX_STORAGE]), « capturés » au Pokédex eux aussi.
## Jalon 7 (T12, départ `shop_qa`) : « favorites » : objets du Sac marqués favoris (chacun doit
## être dans « bag »).
## Jalon 7 (T16, départ `storage_qa`) : « favorite » (booléen) sur un membre de l'équipe ou du
## stockage : Pokémon favori.
## Jalon 9 (T2, sauvegarde v4) : « status » sur un membre de l'équipe ou du stockage : statut
## durable ([constant StatusRules.KNOWN], « poison » au J9 ; absent ou "" = aucun). « autosave »
## (booléen, faux par défaut) : le départ **devient la partie sauvegardée** — l'autosave est
## actif pour la session et **remplace `user://save.json`** (QA de la sauvegarde : relire le
## statut après une fermeture forcée, départ `save_v4_qa`). Sans cette clé, un départ de
## débogage ne lit ni n'écrit jamais la sauvegarde.
## Jalon 11 (T9, QA des statuts) : « status_turns » sur un membre : tours de sommeil restants
## (0 à [constant Pokemon.MAX_STATUS_TURNS], avec « status » = « sleep » seulement ; absent : 0,
## il se réveille à sa première tentative d'agir). « wild » : table d'herbes **forcée sur la
## carte de départ** pour la session (même format qu'une table de `data/encounters/` sans
## « maps » ni « terrain » : { "rate", "slots", "ramp" }) ; exige « map » ; jamais sauvegardée.
## Jalon 15 (T2, sauvegarde v7) : « daycare » : le Pokémon gardé à la Pension, même format qu'un
## membre de l'équipe plus « pending_exp » (entier ≥ 0, XP en attente, bornée au plafond du
## niveau 100 ; absent : 0), par exemple { "species": "rattata", "level": 10,
## "pending_exp": 500 } ; « capturé » au Pokédex ; niveau au dépôt = son niveau.
## Jalon 19 (T14) : « rest_point » : carte d'un Centre enregistré comme point de repos (une défaite
## réveille là, pas à la maison), ex. "lavender_center".
## Passe systèmes 2 (S2E, départ `s2_fly`) : « discovered » : cartes déjà découvertes (villes
## ouvertes au Vol), ex. ["pallet_town", "pewter_city"] ; identifiants non vides.
## Jalon 11 (T20d, QA du compagnon) : « companion » : place dans l'équipe (0 = premier) du
## Pokémon choisi comme compagnon ; une espèce sans planche est effacée au premier rafraîchissement
## (comme en jeu, A-11).
## Jalon 12 (T20, gravats) : « wild » accepte une clé « terrain » facultative
## ([constant EncounterTable.TERRAINS], « grass » par défaut) : `"terrain": "rubble"` force la
## table des gravats de la carte (grotte) au lieu de celle des herbes.
## Jalon 17 (T9, voile d'obscurité ; clé « veil » du J18 §2.12) : « veil » = « dark » ou « lit » :
## voile d'obscurité **forcé sur la carte de départ** pour la session (« lit » : halo de Flash
## ouvert), même hors d'une grotte obscure ; exige « map » ; jamais sauvegardé.
## Combat vivant (CV.0, T8) : « fx_gallery » (avec une « party », exigée par le format) : au lieu de la partie, la **galerie d'effets**
## (`game/battle/fx/fx_gallery.tscn`) joue des attaques en boucle et écrit sa cadence dans le
## journal ; { "moves": [identifiants] (vide : une attaque par famille), "mode": "full" | "fast" |
## "reduced", "foe": false }. Les autres clés sont alors sans effet.

const USER_PATH: String = "user://debug_start.json"
const FACINGS: Dictionary[String, Vector2i] = {
	"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT,
}
const MAX_PARTY: int = 6
const MAX_STORAGE: int = 60
## = GameState.MONEY_MAX (lu sans l'autoload : classe pure).
const MAX_MONEY: int = 999_999
## Valeurs de « veil » (jalon 17 T9).
const VEIL_DARK: StringName = &"dark"
const VEIL_LIT: StringName = &"lit"
## T25 : voile **retiré** sur la carte de départ, même en grotte obscure (mesure des fps avec et
## sans voile sur la même carte).
const VEIL_OFF: StringName = &"off"

const _KEYS: Array[String] = ["map", "spawn", "facing", "seed", "flags", "party", "bag",
	"favorites", "money", "storage", "autosave", "wild", "daycare", "companion", "veil", "rest_point",
	"discovered", "safari", "fx_gallery"]
const _MEMBER_KEYS: Array[String] = ["species", "level", "moves", "exp_to_next", "hp",
	"favorite", "status", "status_turns"]

## Carte et point d'apparition de départ (&"" = départ par défaut de Boot).
var map: StringName = &""
var spawn: StringName = &""
var facing: Vector2i = Vector2i.DOWN
## Graine de l'aléatoire de la partie (−1 = tirée au hasard).
var rng_seed: int = -1
var flags: Array[StringName] = []
## Membres de l'équipe validés : { species, level, moves (Array[StringName]), exp_to_next }.
var party: Array[Dictionary] = []
var bag: Dictionary[StringName, int] = {}
## Objets du Sac marqués favoris.
var favorites: Array[StringName] = []
## Argent de départ (−1 = celui d'une nouvelle partie).
var money: int = -1
## Pokémon du Stockage (même forme que [member party]).
var storage: Array[Dictionary] = []
## Vrai : le départ remplace la sauvegarde (autosave actif, voir l'en-tête).
var autosave: bool = false
## Table d'herbes forcée sur [member map] (vide = celle des données), déjà validée.
var wild: Dictionary = {}
## Pokémon de la Pension (même forme que [member party], plus « pending_exp ») ; vide = aucun.
var daycare: Dictionary = {}
## Place du compagnon dans l'équipe (-1 = aucun).
var companion: int = -1
## Terrain de la table forcée [member wild] (jalon 12, T20 : clé « terrain » de « wild »).
var wild_terrain: StringName = &"grass"
## Voile forcé sur [member map] ([constant VEIL_DARK], [constant VEIL_LIT], [constant VEIL_OFF] ; &"" = aucun).
var veil: StringName = &""
## Point de repos enregistré au départ (carte d'un Centre de `data/world/rest_points.json` ;
## &"" = aucun : la maison). Jalon 19 (T14) : réveil au Centre après une défaite dans la Tour.
var rest_point: StringName = &""
## Cartes découvertes au départ (passe systèmes 2, « discovered »).
var discovered: Array[StringName] = []
## J23 : visite du Parc Safari en cours ({ steps_left, balls_left } ; vide = aucune visite).
var safari: Dictionary = {}
## Combat vivant (T8) : réglages de la galerie d'effets ; vide : partie normale.
var fx_gallery: Dictionary = {}
var _errors: PackedStringArray = PackedStringArray()


## Vrai si le départ de débogage peut être lu : build debug ([param debug_build]) et Boot
## lancé comme scène principale ([param boot_is_main_scene]).
static func is_allowed(debug_build: bool, boot_is_main_scene: bool) -> bool:
	return debug_build and boot_is_main_scene


## Lit [param path]. Faux (push_error) s'il est illisible ou invalide : rien n'est gardé.
func load_file(path: String, data: PokemonData, items: ItemLibrary) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet est attendu" % path)
	return add_from_dict(json.data, data, items, path)


## Lit un objet déjà décodé. Tout ou rien.
func add_from_dict(dict: Dictionary, data: PokemonData, items: ItemLibrary,
		source: String = "") -> bool:
	var ok := true
	for key: Variant in dict:
		if not _KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	var new_map := StringName(str(dict.get("map", "")))
	var new_spawn := StringName(str(dict.get("spawn", "")))
	if (dict.has("map") and not _is_text(dict["map"])) \
			or (dict.has("spawn") and not _is_text(dict["spawn"])) \
			or new_map.is_empty() != new_spawn.is_empty():
		ok = _fail("%s : « map » et « spawn » sont des textes non vides, ensemble" % source)
	var new_facing := Vector2i.DOWN
	if dict.has("facing"):
		if not FACINGS.has(str(dict["facing"])):
			ok = _fail("%s : « facing » vaut up, down, left ou right" % source)
		else:
			new_facing = FACINGS[str(dict["facing"])]
	var new_seed := -1
	if dict.has("seed"):
		if not _is_int(dict["seed"]) or int(dict["seed"]) < 0:
			ok = _fail("%s : « seed » est un entier ≥ 0" % source)
		else:
			new_seed = int(dict["seed"])
	var new_flags: Array[StringName] = []
	var raw_flags: Variant = dict.get("flags", [])
	if not raw_flags is Array:
		ok = _fail("%s : « flags » est une liste de textes" % source)
	else:
		for flag: Variant in raw_flags:
			if not _is_text(flag):
				ok = _fail("%s : « flags » est une liste de textes" % source)
				break
			new_flags.append(StringName(flag))
	var new_party: Array[Dictionary] = []
	var raw_party: Variant = dict.get("party")
	if not raw_party is Array or (raw_party as Array).is_empty() \
			or (raw_party as Array).size() > MAX_PARTY:
		ok = _fail("%s : « party » est une liste de 1 à %d Pokémon" % [source, MAX_PARTY])
	else:
		for i: int in (raw_party as Array).size():
			var member := _parse_member(raw_party[i], data, "%s party %d" % [source, i + 1])
			if member.is_empty():
				ok = false
			else:
				new_party.append(member)
	var new_bag: Dictionary[StringName, int] = {}
	var raw_bag: Variant = dict.get("bag", {})
	if not raw_bag is Dictionary:
		ok = _fail("%s : « bag » est un objet « objet → quantité »" % source)
	else:
		for key: Variant in raw_bag:
			var id := StringName(str(key))
			if items == null or not items.has_item(id):
				ok = _fail("%s bag : objet inconnu « %s »" % [source, id])
			elif not _is_int(raw_bag[key]) or int(raw_bag[key]) < 1:
				ok = _fail("%s bag « %s » : quantité entière ≥ 1 attendue" % [source, id])
			else:
				new_bag[id] = int(raw_bag[key])
	var new_favorites: Array[StringName] = []
	var raw_favorites: Variant = dict.get("favorites", [])
	if not raw_favorites is Array:
		ok = _fail("%s : « favorites » est une liste d'objets du Sac" % source)
	else:
		for value: Variant in raw_favorites:
			if not _is_text(value) or not new_bag.has(StringName(value)):
				ok = _fail("%s favorites : « %s » n'est pas un objet de « bag »" % [source, value])
			elif not new_favorites.has(StringName(value)):
				new_favorites.append(StringName(value))
	var new_money := -1
	if dict.has("money"):
		if not _is_int(dict["money"]) or int(dict["money"]) < 0 \
				or int(dict["money"]) > MAX_MONEY:
			ok = _fail("%s : « money » est un entier de 0 à %d" % [source, MAX_MONEY])
		else:
			new_money = int(dict["money"])
	var new_storage: Array[Dictionary] = []
	var raw_storage: Variant = dict.get("storage", [])
	if not raw_storage is Array or (raw_storage as Array).size() > MAX_STORAGE:
		ok = _fail("%s : « storage » est une liste de 0 à %d Pokémon" % [source, MAX_STORAGE])
	else:
		for i: int in (raw_storage as Array).size():
			var stored := _parse_member(raw_storage[i], data, "%s storage %d" % [source, i + 1])
			if stored.is_empty():
				ok = false
			else:
				new_storage.append(stored)
	var new_autosave := false
	if dict.has("autosave"):
		if not dict["autosave"] is bool:
			ok = _fail("%s : « autosave » est un booléen" % source)
		else:
			new_autosave = dict["autosave"]
	var new_wild: Dictionary = {}
	var new_wild_terrain: StringName = &"grass"
	if dict.has("wild"):
		if not dict["wild"] is Dictionary or new_map.is_empty():
			ok = _fail("%s : « wild » est une table d'herbes, avec « map »" % source)
		else:
			new_wild = (dict["wild"] as Dictionary).duplicate()
			if new_wild.has("terrain"):
				new_wild_terrain = StringName(str(new_wild["terrain"]))
				new_wild.erase("terrain")
			var check := EncounterLibrary.new(data)
			if not check.override_table(new_map, new_wild_terrain, new_wild,
					source + " « wild »"):
				for error: String in check.get_errors():
					_errors.append(error)
				ok = false
	var new_daycare: Dictionary = {}
	if dict.has("daycare"):
		new_daycare = _parse_daycare(dict["daycare"], data, "%s daycare" % source)
		if new_daycare.is_empty():
			ok = false
	var new_companion := -1
	if dict.has("companion"):
		if not _is_int(dict["companion"]) or int(dict["companion"]) < 0 \
				or int(dict["companion"]) >= new_party.size():
			ok = _fail("%s : « companion » est une place de l'équipe (0 à %d)" % [source,
				maxi(new_party.size() - 1, 0)])
		else:
			new_companion = int(dict["companion"])
	var new_veil: StringName = &""
	if dict.has("veil"):
		var raw_veil: Variant = dict["veil"]
		if not raw_veil is String or not [VEIL_DARK, VEIL_LIT, VEIL_OFF].has(StringName(raw_veil)) \
				or new_map.is_empty():
			ok = _fail("%s : « veil » est « dark », « lit » ou « off », avec « map »" % source)
		else:
			new_veil = StringName(raw_veil)
	var new_rest_point: StringName = &""
	if dict.has("rest_point"):
		var rest_points := RestPointLibrary.new()
		rest_points.load_file()
		var raw_rest: Variant = dict["rest_point"]
		if not raw_rest is String or not rest_points.has_point(StringName(raw_rest)) \
				or not rest_points.get_point(StringName(raw_rest)).registers:
			ok = _fail("%s : « rest_point » est la carte d'un Centre (rest_points.json)" % source)
		else:
			new_rest_point = StringName(raw_rest)
	var new_discovered: Array[StringName] = []
	if dict.has("discovered"):
		var raw_discovered: Variant = dict["discovered"]
		if not raw_discovered is Array or (raw_discovered as Array).any(
				func(id: Variant) -> bool: return not id is String or (id as String).is_empty()):
			ok = _fail("%s : « discovered » est une liste d'identifiants de cartes" % source)
		else:
			for id: String in raw_discovered:
				new_discovered.append(StringName(id))
	if not ok:
		return false
	rest_point = new_rest_point
	discovered = new_discovered
	safari = {}
	if dict.has("safari"):
		var visit: Variant = dict["safari"]
		if not visit is Dictionary or not _is_int((visit as Dictionary).get("steps_left")) \
				or not _is_int((visit as Dictionary).get("balls_left")) \
				or int(visit["steps_left"]) < 0 or int(visit["balls_left"]) < 1:
			return _fail("%s : « safari » vaut { steps_left ≥ 0, balls_left ≥ 1 }" % source)
		safari = {"active": true, "steps_left": int(visit["steps_left"]),
			"balls_left": int(visit["balls_left"])}
	fx_gallery = {}
	if dict.has("fx_gallery"):
		var gallery: Variant = dict["fx_gallery"]
		if not gallery is Dictionary \
				or not (gallery as Dictionary).get("moves", []) is Array \
				or not ["full", "fast", "reduced"].has(str((gallery as Dictionary).get("mode", "full"))):
			return _fail("%s : « fx_gallery » vaut { moves: [...], mode: full | fast | reduced, foe }"
				% source)
		fx_gallery = (gallery as Dictionary).duplicate(true)
	map = new_map
	spawn = new_spawn
	facing = new_facing
	rng_seed = new_seed
	flags = new_flags
	party = new_party
	bag = new_bag
	favorites = new_favorites
	money = new_money
	storage = new_storage
	autosave = new_autosave
	wild = new_wild
	daycare = new_daycare
	wild_terrain = new_wild_terrain
	companion = new_companion
	veil = new_veil
	return true


## Construit la partie dans [param state] (l'autoload GameState, ou une instance neuve de
## game_state.gd en test) : nouvelle partie de graine [member rng_seed], équipe, starter,
## Pokédex, drapeaux, Sac.
func apply(state: Object, data: PokemonData) -> void:
	state.new_game(rng_seed)
	for member: Dictionary in party:
		var pokemon := _create(member, state, data)
		state.party.add(pokemon)
		state.pokedex.mark_caught(pokemon.species_id)
	for member: Dictionary in storage:
		var stored := _create(member, state, data)
		state.storage.add(stored)
		state.pokedex.mark_caught(stored.species_id)
	state.starter_species = party[0]["species"] if not party.is_empty() else &""
	for flag: StringName in flags:
		state.flags.set_flag(flag)
	for id: StringName in bag:
		state.bag.add(id, bag[id])
	for id: StringName in favorites:
		state.bag.set_favorite(id, true)
	if money >= 0:
		state.money = money
	if not daycare.is_empty():
		var kept := _create(daycare, state, data)
		kept.ensure_uid()
		state.daycare.put(kept, data)
		state.daycare.pending_exp = mini(daycare["pending_exp"], state.daycare.exp_room)
		state.pokedex.mark_caught(kept.species_id)
		state.ensure_unique_uids()
	if companion >= 0:
		state.set_companion(state.party.get_at(companion))
	if not rest_point.is_empty():
		var rest_points := RestPointLibrary.new()
		rest_points.load_file()
		state.heal_map = rest_point
		state.heal_spawn = rest_points.get_point(rest_point).spawn
	for map_id: StringName in discovered:
		state.discover_map(map_id)
	if not safari.is_empty():
		state.safari = SafariVisit.from_dict(safari)
		state.flags.set_flag(SafariDirector.FLAG_ACTIVE)


## Un Pokémon d'après un membre validé (capacités, XP, PV).
static func _create(member: Dictionary, state: Object, data: PokemonData) -> Pokemon:
	var pokemon := PokemonFactory.create(data, member["species"], member["level"], state.rng)
	var moves: Array[StringName] = member["moves"]
	if not moves.is_empty():
		pokemon.moves.clear()
		for move_id: StringName in moves:
			pokemon.learn_move(move_id, data)
	var to_next: int = member["exp_to_next"]
	if to_next > 0:
		var rate := data.get_species(pokemon.species_id).growth_rate
		pokemon.experience = ExpCurve.exp_for_level(rate, pokemon.level + 1) - to_next
	var hp: int = member.get("hp", -1)
	if hp >= 0:
		pokemon.hp = mini(hp, pokemon.max_hp())
	pokemon.favorite = bool(member.get("favorite", false))
	pokemon.status = member.get("status", StatusRules.NONE)
	pokemon.status_turns = member.get("status_turns", 0)
	return pokemon


## Résumé d'une ligne (journal du jeu).
func describe() -> String:
	var members: PackedStringArray = []
	for member: Dictionary in party:
		var status: StringName = member.get("status", StatusRules.NONE)
		members.append("%s N%d%s" % [member["species"], member["level"],
			"" if status.is_empty() else " (%s)" % status])
	var kept := "" if daycare.is_empty() else ", Pension : %s N%d + %d XP" % [
		daycare["species"], daycare["level"], daycare["pending_exp"]]
	return "%s/%s, %s%s%s" % [map if not map.is_empty() else &"(défaut)", spawn,
		", ".join(members), kept, " (remplace la sauvegarde)" if autosave else ""]


func get_errors() -> PackedStringArray:
	return _errors


func _parse_member(value: Variant, data: PokemonData, where: String) -> Dictionary:
	if not value is Dictionary:
		_fail("%s : un objet est attendu" % where)
		return {}
	var entry: Dictionary = value
	var ok := true
	for key: Variant in entry:
		if not _MEMBER_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	var species_id := StringName(str(entry.get("species", "")))
	var species := data.get_species(species_id)
	if species == null:
		return _empty_fail("%s : espèce inconnue « %s »" % [where, species_id])
	var level_value: Variant = entry.get("level")
	if not _is_int(level_value) or int(level_value) < 1 \
			or int(level_value) > ExpCurve.MAX_LEVEL:
		return _empty_fail("%s : « level » est un entier de 1 à %d" % [where,
			ExpCurve.MAX_LEVEL])
	var level := int(level_value)
	var moves: Array[StringName] = []
	if entry.has("moves"):
		var raw: Variant = entry["moves"]
		if not raw is Array or (raw as Array).is_empty() \
				or (raw as Array).size() > SpeciesData.MAX_MOVES:
			ok = _fail("%s : « moves » est une liste de 1 à %d capacités" % [where,
				SpeciesData.MAX_MOVES])
		else:
			for move: Variant in raw:
				var move_id := StringName(str(move))
				if not data.has_move(move_id) or moves.has(move_id):
					ok = _fail("%s : capacité inconnue ou en double « %s »" % [where, move_id])
				moves.append(move_id)
	var to_next := 0
	if entry.has("exp_to_next"):
		var span := ExpCurve.exp_for_level(species.growth_rate, level + 1) \
			- ExpCurve.exp_for_level(species.growth_rate, level)
		var raw_next: Variant = entry["exp_to_next"]
		if level >= ExpCurve.MAX_LEVEL or not _is_int(raw_next) or int(raw_next) < 1 \
				or int(raw_next) > span:
			ok = _fail("%s : « exp_to_next » est un entier de 1 à %d" % [where, span])
		else:
			to_next = int(raw_next)
	var hp := -1
	if entry.has("hp"):
		var raw_hp: Variant = entry["hp"]
		if not _is_int(raw_hp) or int(raw_hp) < 0:
			ok = _fail("%s : « hp » est un entier positif ou nul" % where)
		else:
			hp = int(raw_hp)
	var favorite := false
	if entry.has("favorite"):
		if not entry["favorite"] is bool:
			ok = _fail("%s : « favorite » est un booléen" % where)
		else:
			favorite = entry["favorite"]
	var status := StatusRules.NONE
	if entry.has("status"):
		var raw_status: Variant = entry["status"]
		if not raw_status is String or (not (raw_status as String).is_empty()
				and not StatusRules.is_known(StringName(raw_status))):
			ok = _fail("%s : « status » est vide ou l'un de : %s" % [where,
				", ".join(PackedStringArray(StatusRules.KNOWN))])
		else:
			status = StringName(raw_status)
	var status_turns := 0
	if entry.has("status_turns"):
		if not _is_int(entry["status_turns"]) or int(entry["status_turns"]) < 0 \
				or int(entry["status_turns"]) > Pokemon.MAX_STATUS_TURNS \
				or status != StatusRules.SLEEP:
			ok = _fail("%s : « status_turns » est un entier de 0 à %d, avec « status » = sleep"
				% [where, Pokemon.MAX_STATUS_TURNS])
		else:
			status_turns = int(entry["status_turns"])
	if not ok:
		return {}
	return { "species": species_id, "level": level, "moves": moves, "exp_to_next": to_next,
		"hp": hp, "favorite": favorite, "status": status, "status_turns": status_turns }


## « daycare » : un membre ([method _parse_member]) plus « pending_exp » ; {} si invalide.
func _parse_daycare(value: Variant, data: PokemonData, where: String) -> Dictionary:
	if not value is Dictionary:
		return _empty_fail("%s : un objet est attendu" % where)
	var entry := (value as Dictionary).duplicate()
	var pending := 0
	if entry.has("pending_exp"):
		if not _is_int(entry["pending_exp"]) or int(entry["pending_exp"]) < 0:
			return _empty_fail("%s : « pending_exp » est un entier positif ou nul" % where)
		pending = int(entry["pending_exp"])
		entry.erase("pending_exp")
	var member := _parse_member(entry, data, where)
	if not member.is_empty():
		member["pending_exp"] = pending
	return member


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


static func _is_int(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == floorf(float(value))


func _empty_fail(message: String) -> Dictionary:
	_fail(message)
	return {}


func _fail(message: String) -> bool:
	var full := "DebugStart : " + message
	_errors.append(full)
	push_error(full)
	return false
