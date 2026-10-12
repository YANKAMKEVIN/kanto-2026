class_name StatusView
extends RefCounted
## Texte et couleur du statut d'un Pokémon pour les vues (jalon 9, T5) : « K.O. » s'il est
## tombé, l'abréviation de son statut (« PSN », « PAR », « SOM », « BRÛ », « GEL ») sinon. Une seule fonction pour le combat,
## le tableau de bord, l'Équipe et le Sac (dossier 08 §2 : le statut est toujours un texte) ;
## la logique ([StatusRules]) ne connaît pas ces libellés. Classe pure, statique.

## Libellé de chaque statut durable (clés de [constant StatusRules.KNOWN]).
const STATUS_TEXTS: Dictionary[StringName, String] = {
	StatusRules.POISON: TeamMemberView.STATUS_POISON,
	StatusRules.PARALYSIS: TeamMemberView.STATUS_PARALYSIS,
	StatusRules.SLEEP: TeamMemberView.STATUS_SLEEP,
	StatusRules.BURN: TeamMemberView.STATUS_BURN,
	StatusRules.FREEZE: TeamMemberView.STATUS_FREEZE,
}
## Type dont la pastille porte chaque statut (couleur de [constant UiTokens.TYPE_COLORS]) ;
## défauts du J11 (règle 4) : paralysie Électrik, sommeil Normal, brûlure Feu, gel Glace.
const BADGE_TYPES: Dictionary[StringName, StringName] = {
	StatusRules.POISON: &"poison", StatusRules.PARALYSIS: &"electric",
	StatusRules.SLEEP: &"normal", StatusRules.BURN: &"fire", StatusRules.FREEZE: &"ice",
}


## « K.O. », « PSN » ou « » pour [param pokemon]. Un K.O. n'a plus de statut (le moteur
## l'efface), mais l'ordre reste celui-ci : K.O. d'abord.
static func text(pokemon: Pokemon) -> String:
	if pokemon.is_fainted():
		return TeamMemberView.STATUS_FAINTED
	return text_of(pokemon.status)


## Libellé du statut [param status] (« PSN »), « » pour aucun statut ou un statut inconnu.
static func text_of(status: StringName) -> String:
	return STATUS_TEXTS.get(status, "")


## Couleur du texte de statut [param label] sur un panneau sombre : rouge pour « K.O. »,
## poison éclairci pour « PSN » ; couleur de la pastille éclaircie pour les statuts du J11
## (défaut, affiné au T7).
static func color(label: String) -> Color:
	if label == TeamMemberView.STATUS_POISON:
		return UiTokens.STATUS_POISON_TEXT
	var status: StringName = STATUS_TEXTS.find_key(label) if STATUS_TEXTS.values().has(label) \
		else StatusRules.NONE
	if status != StatusRules.NONE:
		return UiTokens.TYPE_COLORS[BADGE_TYPES[status]].lightened(0.35)
	return UiTokens.HP_LOW


## Type (identifiant de [constant UiTokens.TYPE_COLORS]) dont la pastille porte le statut
## [param status] ; « » si le statut n'a pas de pastille.
static func badge_type(status: StringName) -> StringName:
	return BADGE_TYPES.get(status, &"")
