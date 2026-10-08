class_name StatusView
extends RefCounted
## Texte et couleur du statut d'un Pokémon pour les vues (jalon 9, T5) : « K.O. » s'il est
## tombé, « PSN » s'il est debout et empoisonné, rien sinon. Une seule fonction pour le combat,
## le tableau de bord, l'Équipe et le Sac (dossier 08 §2 : le statut est toujours un texte) ;
## la logique ([StatusRules]) ne connaît pas ces libellés. Classe pure, statique.

## Libellé de chaque statut durable (clés de [constant StatusRules.KNOWN]) ; le J11 ajoute les
## siens ici.
const STATUS_TEXTS: Dictionary[StringName, String] = {
	StatusRules.POISON: TeamMemberView.STATUS_POISON,
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
## poison éclairci pour « PSN ».
static func color(label: String) -> Color:
	if label == TeamMemberView.STATUS_POISON:
		return UiTokens.STATUS_POISON_TEXT
	return UiTokens.HP_LOW


## Type (identifiant de [constant UiTokens.TYPE_COLORS]) dont la pastille porte le statut
## [param status] ; « » si le statut n'a pas de pastille.
static func badge_type(status: StringName) -> StringName:
	return &"poison" if status == StatusRules.POISON else &""
