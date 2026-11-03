class_name TeamConfiscation
extends RefCounted
## Le vol et le retour de l'équipe du Chapitre Johto (JH-1 à JH-3, JH-24 ; `jalon-joh0.md`
## §2.2 ; dossier JOH-01 §6). Classe statique et pure : elle reçoit l'état de partie
## (l'autoload GameState en jeu, une instance de `game_state.gd` en test) et la bibliothèque
## d'objets ; aucune scène, aucun écran, aucune écriture disque.
##
## **Une seule opération synchrone** dans chaque sens : rien n'est `await`é entre la première et
## la dernière modification de l'état, donc aucun autosave ne peut tomber au milieu. La scène qui
## l'appelle fait suivre l'opération d'une étape « save » : avant l'écriture, le fichier est
## entièrement « avant » ; après, entièrement « après » (jamais une équipe vide sans section
## confisquée).
##
## - [method confiscate] (le vol, Oliville) : l'équipe (mêmes objets [Pokemon], identifiants
##   gardés) et les objets **non clés** du Sac passent dans [member GameState.confiscated] ;
##   l'équipe se vide, le Sac perd ces objets (favoris et rangs gardés : ils reviendront
##   favoris), le compagnon est effacé, [constant STORAGE_OFFLINE] et [constant ACT1] se lèvent.
##   Les objets clés (Vélo, cannes, Multi Exp, CS…), l'argent, les badges, le Pokédex et les
##   drapeaux restent. Les CT sont des objets du Sac : confisquées **[D]**.
## - [method restore] (le retour, Tour Radio) : le joueur a choisi 1 à 6 Pokémon ([param kept],
##   identifiants, [TeamReturnSelection]) parmi l'équipe de Johto et l'équipe confisquée ; ils
##   forment l'équipe dans l'ordre du choix, les autres vont au Stockage (équipe de Johto puis
##   confisquée **[D]**), les Sacs fusionnent (quantités additionnées), la section se vide,
##   [constant STORAGE_OFFLINE] et [constant ACT1] se baissent, [constant RETURNED] se lève ; le
##   compagnon redevient celui d'avant le vol s'il est gardé, sinon le premier de l'équipe **[D]**.

## Drapeaux d'histoire ordinaires (aucun format de sauvegarde).
const STORAGE_OFFLINE: StringName = &"storage_offline"
const ACT1: StringName = &"johto_act1"
const RETURNED: StringName = &"johto_team_returned"
const ARRIVED: StringName = &"johto_arrived"

## Résultat de [method check_kept].
enum Check {
	OK,
	EMPTY, ## Aucun Pokémon gardé.
	TOO_MANY, ## Plus de 6.
	UNKNOWN, ## Un identifiant qui n'est ni dans l'équipe ni dans la section confisquée.
	DUPLICATE, ## Un identifiant deux fois.
	NO_ABLE, ## Aucun Pokémon gardé en état de combattre (K.O. ou œuf).
}


## Vrai si l'acte 1 est en cours (l'équipe est confisquée).
static func is_act1(flags: StoryFlags) -> bool:
	return flags != null and flags.has_flag(ACT1)


## Vrai si le Stockage (et le terminal d'échange) refusent l'accès.
static func is_storage_offline(flags: StoryFlags) -> bool:
	return flags != null and flags.has_flag(STORAGE_OFFLINE)


## Le vol. Faux, et rien ne change, si l'équipe est vide ou si une équipe est déjà confisquée.
static func confiscate(state: Node, items: ItemLibrary) -> bool:
	var party: Party = state.party
	var confiscated: ConfiscatedTeam = state.confiscated
	if party.size() == 0 or not confiscated.is_empty():
		return false
	var bag: Bag = state.bag
	var flags: StoryFlags = state.flags
	# 1. Copier (mêmes objets Pokemon : identifiants, PV, PP, statut gardés tels quels).
	for pokemon: Pokemon in party.get_all():
		pokemon.ensure_uid()
		confiscated.party.append(pokemon)
	for item_id: StringName in bag.get_ids():
		if not is_key_item(item_id, items):
			confiscated.items[item_id] = bag.count_of(item_id)
	confiscated.companion_uid = state.companion_uid
	# 2. Retirer.
	party.clear()
	for item_id: StringName in confiscated.items:
		bag.remove(item_id, confiscated.items[item_id])
	state.companion_uid = ""
	flags.set_flag(STORAGE_OFFLINE)
	flags.set_flag(ACT1)
	return true


## Vrai si [param item_id] est un objet clé (gardé au vol). Un objet inconnu de la bibliothèque
## est traité comme un objet ordinaire **[D]** (confisqué : il n'est pas une clé).
static func is_key_item(item_id: StringName, items: ItemLibrary) -> bool:
	var item := items.get_item(item_id) if items != null else null
	return item != null and item.category == ItemData.Category.KEY


## La réserve du retour : l'équipe de Johto puis l'équipe confisquée, dans l'ordre.
static func pool(state: Node) -> Array[Pokemon]:
	var result: Array[Pokemon] = []
	result.append_array((state.party as Party).get_all())
	result.append_array((state.confiscated as ConfiscatedTeam).party)
	return result


## Vrai si [param pokemon] peut combattre (ni K.O. ni œuf).
static func is_able(pokemon: Pokemon) -> bool:
	return pokemon != null and not pokemon.is_fainted() and not pokemon.is_egg()


## Contrôle du choix [param kept] (identifiants) dans la réserve [param members].
static func check_kept(members: Array[Pokemon], kept: Array[String]) -> Check:
	if kept.is_empty():
		return Check.EMPTY
	if kept.size() > Party.MAX_SIZE:
		return Check.TOO_MANY
	var seen: Dictionary[String, bool] = {}
	var able := false
	for uid: String in kept:
		if seen.has(uid):
			return Check.DUPLICATE
		seen[uid] = true
		var found: Pokemon = null
		for pokemon: Pokemon in members:
			if pokemon.uid == uid:
				found = pokemon
				break
		if found == null:
			return Check.UNKNOWN
		able = able or is_able(found)
	return Check.OK if able else Check.NO_ABLE


## Le retour. Rend `{ "ok": bool, "check": Check, "stored": Array[Pokemon], "companion": String }` ;
## `ok` faux (rien ne change) si rien n'est confisqué ou si [param kept] est refusé.
static func restore(state: Node, kept: Array[String]) -> Dictionary:
	var result := {"ok": false, "check": Check.OK, "stored": [] as Array[Pokemon], "companion": ""}
	var confiscated: ConfiscatedTeam = state.confiscated
	if confiscated.is_empty():
		result["check"] = Check.EMPTY
		return result
	var members := pool(state)
	var check := check_kept(members, kept)
	result["check"] = check
	if check != Check.OK:
		return result
	var party: Party = state.party
	var storage: PokemonStorage = state.storage
	var bag: Bag = state.bag
	var flags: StoryFlags = state.flags
	# 1. L'équipe : les gardés dans l'ordre du choix ; les autres au Stockage, dans l'ordre de la
	#    réserve.
	party.clear()
	for uid: String in kept:
		for pokemon: Pokemon in members:
			if pokemon.uid == uid:
				party.add(pokemon)
				break
	var stored: Array[Pokemon] = []
	for pokemon: Pokemon in members:
		if not kept.has(pokemon.uid):
			storage.add(pokemon)
			stored.append(pokemon)
	# 2. Les Sacs fusionnent.
	for item_id: StringName in confiscated.items:
		bag.add(item_id, confiscated.items[item_id])
	# 3. Le compagnon : celui d'avant le vol s'il est gardé, sinon le premier de l'équipe.
	var companion := confiscated.companion_uid
	if companion.is_empty() or not kept.has(companion):
		companion = party.get_at(0).uid
	state.companion_uid = companion
	# 4. Drapeaux et section.
	confiscated.clear()
	flags.set_flag(STORAGE_OFFLINE, false)
	flags.set_flag(ACT1, false)
	flags.set_flag(RETURNED)
	result["ok"] = true
	result["stored"] = stored
	result["companion"] = companion
	return result
