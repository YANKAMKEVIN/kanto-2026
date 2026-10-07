class_name BadgeMoment
extends RefCounted
## Grand moment « badge » (dossier 12 §13, arbitrage 12 ; jalon-10.md §2.8) : générique pour
## les 8 badges, il porte le **souvenir de l'équipe** au moment de la victoire.
##
## Classe pure, statique. Détails enregistrés par [code]GameState.record_moment[/code] :
## [codeblock]
## { "badge": "boulder",
##   "team": [ { "species": "charmander", "level": 14, "nickname": "" }, … ] }
## [/codeblock]
## Équipe dans l'ordre de l'équipe, Pokémon K.O. compris ; ni formes ni états (arbitrage 12).
## Aucun changement de format de sauvegarde : les détails d'un moment sont déjà sauvegardés
## tels quels ; relus du JSON, les nombres reviennent en flottants ([method team_of] les remet
## en entiers). Les textes du moment viennent de [MomentLibrary] (type [constant TYPE]).

const TYPE: StringName = &"badge"

const KEY_BADGE: String = "badge"
const KEY_TEAM: String = "team"
const KEY_SPECIES: String = "species"
const KEY_LEVEL: String = "level"
const KEY_NICKNAME: String = "nickname"


## Détails du moment pour [param badge_id] avec l'équipe [param party] telle qu'elle est (à
## relever après le bilan d'expérience et l'évolution éventuelle). Un dictionnaire neuf à
## chaque appel (record_moment n'en fait qu'une copie superficielle).
static func details(badge_id: StringName, party: Party) -> Dictionary:
	var team: Array = []
	if party != null:
		for pokemon: Pokemon in party.get_all():
			team.append({
				KEY_SPECIES: String(pokemon.species_id),
				KEY_LEVEL: pokemon.level,
				KEY_NICKNAME: pokemon.nickname,
			})
	return {KEY_BADGE: String(badge_id), KEY_TEAM: team}


## Badge d'un moment enregistré (&"" si absent ou mal formé).
static func badge_of(moment_details: Dictionary) -> StringName:
	var value: Variant = moment_details.get(KEY_BADGE)
	if not value is String and not value is StringName:
		return &""
	return StringName(str(value).strip_edges())


## Équipe relue d'un moment enregistré, dans l'ordre : { "species": StringName,
## "level": int, "nickname": String }. Lecture tolérante : un niveau flottant entier redevient
## un entier ; une entrée mal formée (pas un objet, espèce vide, niveau absent, non entier ou
## < 1) est écartée ; un surnom absent ou mal formé vaut "".
static func team_of(moment_details: Dictionary) -> Array[Dictionary]:
	var team: Array[Dictionary] = []
	var raw: Variant = moment_details.get(KEY_TEAM)
	if not raw is Array:
		return team
	for entry: Variant in raw:
		if not entry is Dictionary:
			continue
		var member: Dictionary = entry
		var species: Variant = member.get(KEY_SPECIES)
		if not (species is String or species is StringName) \
				or str(species).strip_edges().is_empty():
			continue
		var level: Variant = member.get(KEY_LEVEL)
		if not (level is int or level is float) or float(level) != floorf(float(level)) \
				or int(level) < 1:
			continue
		var nickname: Variant = member.get(KEY_NICKNAME, "")
		team.append({
			KEY_SPECIES: StringName(str(species).strip_edges()),
			KEY_LEVEL: int(level),
			KEY_NICKNAME: str(nickname) if nickname is String else "",
		})
	return team


## Vrai si [param moments] (GameState.moments) contient déjà le moment de [param badge_id] :
## un seul moment par badge (étape « badge » des scènes, T9).
static func has_badge_moment(moments: Array[Dictionary], badge_id: StringName) -> bool:
	if badge_id.is_empty():
		return false
	for moment: Dictionary in moments:
		if str(moment.get("type", "")) != String(TYPE):
			continue
		var moment_details: Variant = moment.get("details")
		if moment_details is Dictionary and badge_of(moment_details) == badge_id:
			return true
	return false
