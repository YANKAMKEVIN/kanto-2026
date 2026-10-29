class_name KeyItemDirector
extends Node
## Objets clés utilisables en exploration (passe systèmes 2, `docs/tech/systemes-2.md` §2.4 ;
## plan du J21 §2.2). Enfant de [Boot]. Le Sac émet [signal MenuDirector.key_item_requested] ;
## Boot ferme le menu et appelle [method use], qui aiguille par [member ItemData.key_use] :
## - **Bicyclette** : [method MountDirector.toggle_bike] (refus et textes compris) ;
## - **Poké Flûte** : un dormeur voisin ([method GameMap.flute_targets],
##   [method PokeFluteRules.field_target]) → sa scène (posée par le J21) ; sinon « {player} joue
##   de la Poké Flûte… Quel air entraînant ! » (dossier 24 §15.6.6) et la bulle « ♪ » du
##   compagnon s'il est sorti ;
## - **Cannes** (S2C-bis) : [method FishingDirector.use_rod] avec la canne choisie (sans eau
##   pêchable devant : « On ne peut pas pêcher ici. ») ;
## - **Cherch'Objet** (lot 32P) : [method Itemfinder.dialogue_for] sur les objets cachés de la carte
##   ([method GameMap.hidden_item_cells]).
## Rien n'est consommé : un objet clé reste dans le Sac.

## La Flûte a joué hors combat : [param cutscene_id] = scène du dormeur réveillé, &"" si elle a
## joué « ailleurs » (tests, QA).
signal flute_played(cutscene_id: StringName)

## Texte de la Flûte « ailleurs » (`data/dialogues/key_items.json`).
const FLUTE_ELSEWHERE_DIALOGUE: StringName = &"poke_flute_played"

var _state: Node
var _items: ItemLibrary
var _mount: MountDirector
var _runner: DialogueRunner
var _cutscenes: CutsceneDirector
var _companion: CompanionController
var _player: Player
var _fishing: FishingDirector


func _init() -> void:
	name = "KeyItemDirector"


func setup(state: Node, items: ItemLibrary, mount: MountDirector, runner: DialogueRunner,
		cutscenes: CutsceneDirector, companion: CompanionController, player: Player) -> void:
	_state = state
	_items = items
	_mount = mount
	_runner = runner
	_cutscenes = cutscenes
	_companion = companion
	_player = player


## Pêche (S2C-bis) : les cannes lui sont aiguillées (null : une canne ne fait rien).
func set_fishing(fishing: FishingDirector) -> void:
	_fishing = fishing


## Utilise l'objet clé [param item_id] (menu déjà fermé). Faux si l'objet n'a pas d'usage connu
## ou n'est pas dans le Sac.
func use(item_id: StringName) -> bool:
	var item := _items.get_item(item_id) if _items != null else null
	if item == null or not item.has_key_use() or _state == null \
			or not (_state.get(&"bag") as Bag).has(item_id):
		return false
	if FishingRules.RODS.has(item.key_use):
		return _fishing != null and _fishing.use_rod(item.key_use)
	match item.key_use:
		ItemData.KEY_USE_BICYCLE:
			_mount.toggle_bike()
			return true
		ItemData.KEY_USE_POKE_FLUTE:
			_play_flute()
			return true
		ItemData.KEY_USE_ITEMFINDER:
			_use_itemfinder()
			return true
	return false


## Cherch'Objet (lot 32P) : la direction de l'objet caché le plus proche, ou rien.
func _use_itemfinder() -> void:
	var map := SceneRouter.get_current_map()
	if not is_instance_valid(map) or not is_instance_valid(_player) or _runner == null:
		return
	var cells := map.hidden_item_cells(_state.get(&"flags") as StoryFlags)
	_runner.play(Itemfinder.dialogue_for(cells, _player.get_cell()), null, map)


func _play_flute() -> void:
	var map := SceneRouter.get_current_map()
	var cutscene := &""
	if is_instance_valid(map) and is_instance_valid(_player):
		cutscene = PokeFluteRules.field_target(map.flute_targets(), _player.get_cell(),
			_state.get(&"flags") as StoryFlags)
	if not cutscene.is_empty() and _cutscenes != null and _cutscenes.play(cutscene):
		flute_played.emit(cutscene)
		return
	if _cutscenes != null:
		_cutscenes.play_flute_notes() # Jalon 21 : les notes, sans attendre (même fonction)
	if _runner != null:
		_runner.play(FLUTE_ELSEWHERE_DIALOGUE, null, map)
	if _companion != null and _companion.is_shown():
		_companion.get_node_2d().show_emote(EmoteBubble.NOTE)
	flute_played.emit(&"")
