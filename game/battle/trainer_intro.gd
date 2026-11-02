class_name TrainerIntro
extends RefCounted
## Plan de l'entrée d'un combat de Dresseur (dossier 05 §3, décision de Kevin du 2026-11-02).
## Classe pure : ni scène, ni autoload ; la présentation ([BattleStage], [VsBanner]) joue ses
## étapes dans l'ordre de [member steps], aux durées de [method duration].
##
## Deux niveaux :
## 1. **Dresseur ordinaire** : les deux dresseurs entrent en glissant dans le décor peint (le
##    joueur de dos à gauche, l'adversaire de face à droite) avec la rangée de Poké Balls de
##    l'équipe adverse ([member balls]) ; l'adversaire lance son premier Pokémon et s'efface,
##    puis le joueur (≈ 2 s d'animation, messages du moteur entre les étapes).
## 2. **Grand combat** (Dresseur dont les données ont un bloc « card » : Champions, rival,
##    Conseil 4, Giovanni) : la séquence « VS » d'abord (banderoles qui entrent, tiennent puis
##    s'écartent), puis l'entrée du niveau 1.
## **Jamais sautée** (décision de Kevin) : aucune étape n'écoute le toucher. « Réduire les
## animations » ([member slide] faux) change les glissés en fondus, aux mêmes durées.
##
## Images : sprite de face `<front_dir><sprite_id><extension>` et portrait de banderole
## `<portrait_dir><portrait_id><extension>` ([TrainerIntroCatalog]) ; l'appelant demande
## l'existence d'un fichier par un [Callable] et retombe sur l'apparence du monde
## ([member world_sprite]) si l'image manque : l'art se branche sans code.

enum Step { VS_IN, VS_HOLD, VS_OUT, TRAINERS_IN, FOE_SEND, PLAYER_SEND }
## État d'un emplacement de la rangée de Poké Balls (comme Rouge/Bleu).
enum Ball { FULL, FAINTED, EMPTY }

## Emplacements de la rangée de Poké Balls (une équipe pleine).
const SLOTS: int = Party.MAX_SIZE
## Identifiant de portrait du rival dans les données : il suit l'apparence du rival.
const RIVAL_ID: StringName = &"rival"

## Vrai pour un grand combat (séquence « VS » d'abord).
var grand: bool = false
## Étapes, dans l'ordre de jeu.
var steps: Array[Step] = []
## Faux avec « Réduire les animations » : fondus au lieu des glissés.
var slide: bool = true
## Rangée de Poké Balls de l'équipe adverse ([constant SLOTS] emplacements).
var balls: Array[Ball] = []
## Grand combat : nom (jetons non résolus, « {rival} ») et titre de la banderole.
var foe_name: String = ""
var foe_title: String = ""
## Image de face (classe du Dresseur ordinaire, ou identifiant du grand adversaire) ; &"" :
## aucune classe connue (repli générique).
var sprite_id: StringName = &""
## Portrait de banderole (grand combat seulement).
var portrait_id: StringName = &""
## Apparence du monde de l'adversaire (repli du sprite de face et du portrait).
var world_sprite: StringName = &""

var _catalog: TrainerIntroCatalog


## Plan du combat contre [param trainer] (équipe [param foe_party]). [param rival_look] :
## apparence du rival (`rival` / `rivale`), qui choisit ses images. [param reduce_motion] :
## « Réduire les animations ».
static func build(trainer: TrainerData, foe_party: Party, catalog: TrainerIntroCatalog,
		rival_look: StringName = &"rival", reduce_motion: bool = false) -> TrainerIntro:
	var intro := TrainerIntro.new()
	intro._catalog = catalog
	intro.slide = not reduce_motion
	intro.grand = trainer != null and trainer.has_card()
	if intro.grand:
		intro.steps.assign([Step.VS_IN, Step.VS_HOLD, Step.VS_OUT])
		intro.foe_name = trainer.card_name
		intro.foe_title = trainer.card_title
		intro.world_sprite = TrainerLooks.world_sprite(
			catalog.world_sprite(trainer.card_portrait), rival_look)
		var id := trainer.card_portrait
		if id == RIVAL_ID and not rival_look.is_empty():
			id = rival_look
		intro.sprite_id = id
		intro.portrait_id = id
	elif trainer != null:
		intro.sprite_id = catalog.class_for(trainer.name)
		intro.world_sprite = catalog.world_sprite(intro.sprite_id)
	intro.steps.append_array([Step.TRAINERS_IN, Step.FOE_SEND, Step.PLAYER_SEND])
	intro.balls = ball_row(foe_party)
	return intro


## Rangée de Poké Balls de [param party] : pleine pour un Pokémon valide, éteinte pour un
## Pokémon K.O., vide pour un emplacement libre.
static func ball_row(party: Party) -> Array[Ball]:
	var row: Array[Ball] = []
	for i: int in SLOTS:
		var pokemon := party.get_at(i) if party != null and i < party.size() else null
		if pokemon == null:
			row.append(Ball.EMPTY)
		elif pokemon.is_fainted():
			row.append(Ball.FAINTED)
		else:
			row.append(Ball.FULL)
	return row


## Durée (s) de [param step].
func duration(step: Step) -> float:
	match step:
		Step.VS_IN:
			return _catalog.duration("vs_in")
		Step.VS_HOLD:
			return _catalog.duration("vs_hold")
		Step.VS_OUT:
			return _catalog.duration("vs_out")
		Step.TRAINERS_IN:
			return _catalog.duration("trainers_in") + _catalog.duration("balls_in")
		Step.FOE_SEND, Step.PLAYER_SEND:
			return _catalog.duration("send_throw") + _catalog.duration("send_exit")
	return 0.0


## Durée totale (s) des étapes de [member steps] (sans les messages du moteur, ni la transition
## de caméra vers le décor de combat).
func total() -> float:
	var sum := 0.0
	for step: Step in steps:
		sum += duration(step)
	return sum


## Durée totale de l'entrée du niveau 1 seule (sans la séquence « VS »).
func entry_total() -> float:
	return duration(Step.TRAINERS_IN) + duration(Step.FOE_SEND) + duration(Step.PLAYER_SEND)


## Chemin du sprite de face s'il existe ([param exists] : `func(path: String) -> bool`), sinon
## "" (repli sur [member world_sprite]).
func front_path(exists: Callable) -> String:
	if sprite_id.is_empty():
		return ""
	var path := _catalog.front_dir + String(sprite_id) + _catalog.extension
	return path if exists.call(path) else ""


## Chemin du portrait de banderole s'il existe, sinon "" (repli : sprite de face ou apparence du
## monde, choisis par la présentation).
func portrait_path(exists: Callable) -> String:
	if portrait_id.is_empty():
		return ""
	var path := _catalog.portrait_dir + String(portrait_id) + _catalog.extension
	return path if exists.call(path) else ""


func get_catalog() -> TrainerIntroCatalog:
	return _catalog
