class_name TrainerLooks
extends RefCounted
## Assets du joueur et du rival selon leur apparence (chantier JR, dossier-joueuse-rivale.md ;
## dossier 13 §3.6) : `GameState.player_look` (`hero` / `heroine`) et `GameState.rival_look`
## (`rival` / `rivale`) → apparence du monde ([CharacterLook]), lancer de dos en combat, buste
## du menu, portraits en pied de l'introduction.
##
## Classe pure : l'appelant passe l'apparence (lue dans [GameState] ou dans une sauvegarde).
## Une apparence inconnue rend les assets du héros ou du rival garçon.
## Les identifiants de la couche 2 du dossier 13 §3.5 ne changent pas : les données gardent
## `"sprite": "rival"`, remplacé à l'affichage par [method world_sprite].

const PAINTED := "res://assets/sprites/characters/painted/"

## Apparence du monde du joueur ([CharacterLook]) par `player_look`.
const PLAYER_SPRITES: Dictionary[StringName, StringName] = {
	&"hero": &"player",
	&"heroine": &"player_heroine",
}
## Apparence du monde du rival par `rival_look`.
const RIVAL_SPRITES: Dictionary[StringName, StringName] = {
	&"rival": &"rival",
	&"rivale": &"rival_heroine",
}
## Lancer de dos en combat (`BattleStage`).
const THROWERS: Dictionary[StringName, String] = {
	&"hero": PAINTED + "heros_lancer.png",
	&"heroine": PAINTED + "joueuse_lancer.png",
}
## Buste du menu (Dresseur, carte, tableau de bord, carte Continuer du titre).
const BUSTS: Dictionary[StringName, String] = {
	&"hero": "res://assets/ui/menu/hero_bust.webp",
	&"heroine": "res://assets/ui/menu/heroine_bust.webp",
}
## Portrait en pied de l'introduction, joueur puis rival.
const PLAYER_PORTRAITS: Dictionary[StringName, String] = {
	&"hero": PAINTED + "heros_portrait.png",
	&"heroine": PAINTED + "joueuse_portrait.png",
}
const RIVAL_PORTRAITS: Dictionary[StringName, String] = {
	&"rival": PAINTED + "rival_portrait.png",
	&"rivale": PAINTED + "rivale_portrait.png",
}
## Identifiant d'apparence du rival dans les données (PNJ, acteurs de cinématique).
const RIVAL_DATA_SPRITE: StringName = &"rival"


## Apparences au féminin (accords {g:…|…} et {gr:…|…}, JR-7).
const HEROINE: StringName = &"heroine"
const RIVALE: StringName = &"rivale"


## Valeurs des accords des dialogues pour ces apparences ([DialogueTokens]).
static func agreement_values(player_look: StringName,
		rival_look: StringName) -> Dictionary[StringName, String]:
	return DialogueTokens.agreement_values(player_look == HEROINE, rival_look == RIVALE)


static func player_sprite(look: StringName) -> StringName:
	return PLAYER_SPRITES.get(look, PLAYER_SPRITES[&"hero"])


static func rival_sprite(look: StringName) -> StringName:
	return RIVAL_SPRITES.get(look, RIVAL_SPRITES[&"rival"])


static func thrower_path(look: StringName) -> String:
	return THROWERS.get(look, THROWERS[&"hero"])


static func bust_path(look: StringName) -> String:
	return BUSTS.get(look, BUSTS[&"hero"])


static func player_portrait_path(look: StringName) -> String:
	return PLAYER_PORTRAITS.get(look, PLAYER_PORTRAITS[&"hero"])


static func rival_portrait_path(look: StringName) -> String:
	return RIVAL_PORTRAITS.get(look, RIVAL_PORTRAITS[&"rival"])


## Apparence affichée d'un PNJ ou d'un acteur dont les données disent [param sprite] : celle du
## rival choisi pour `"rival"`, [param sprite] inchangé sinon.
static func world_sprite(sprite: StringName, rival_look: StringName) -> StringName:
	return rival_sprite(rival_look) if sprite == RIVAL_DATA_SPRITE else sprite
