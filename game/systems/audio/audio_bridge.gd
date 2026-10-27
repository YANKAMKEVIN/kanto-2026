class_name AudioBridge
extends RefCounted
## Branchements du jeu vers l'autoload « Audio » (docs/tech/jalon-son.md §1.4–§1.8, SonA T6) :
## seul fichier « collant ». Boot relaie ses signaux ici ; le pont décide **quoi** jouer avec
## [MusicSelector] et l'autoload l'exécute. Sans fichier son, rien ne change dans le jeu.
##
## Couches ([enum MusicStack.Layer]) :
## - ZONE : musique de la carte ([method on_map_changed], Surf et Vélo par
##   [method on_mount_changed]) ; l'écran titre aussi ([method play_title]) ;
## - SCENE : thème du « ! » d'un Dresseur ([method on_trainer_spotted]), clé facultative « music »
##   d'une étape de cinématique ([method on_cutscene_step] ; « stop » l'arrête), introduction de
##   Chen ; elle se retire à la fin de la cinématique ;
## - BATTLE : musique du combat, puis de la victoire (`BATTLE_ENDED` gagné) ;
## - JINGLE : soin, objet, objet clé, Badge, capture, montée de niveau, évolution, Poké Flûte.
## Cris (SonB, §1.8) : envoi au combat (les deux camps), K.O. (plus grave), rencontre et Pokémon
## d'ambiance (`cry_requested`), bouton « Cri » du Pokédex, compagnon à qui l'on parle, écran
## d'évolution (ancienne forme au début, nouvelle à la fin).
## Bruitages (SonC, §1.7, T13) : événements de combat (`sfx.json` battle_events, statuts, stats,
## coups selon l'efficacité, famille de l'attaque), pas selon le sol à chaque case, mur, rebord,
## porte, Vélo, « ! », et interface (boutons des menus, ouverture / fermeture du menu, page de
## dialogue suivante). Une seule accroche pour tous les boutons ([method watch_ui]).

## Valeur de la clé « music » d'une étape qui arrête la musique de scène.
const STOP: StringName = &"stop"
const L := MusicStack.Layer

## Autoload « Audio » (ou un double de test) : set_music, clear_music, play_jingle,
## set_ambience, library.
var audio: Node
var selector: MusicSelector
## () -> Mount.Kind : monture actuelle du joueur.
var current_mount: Callable = Callable()
## (flag: StringName) -> bool : drapeaux d'histoire.
var has_flag: Callable = Callable()
## (trainer_id: StringName) -> String : nom du Dresseur (« Gamin Ben »), pour le thème du « ! ».
var trainer_name: Callable = Callable()
## () -> int : espèces capturées (Pokédex), pour la première capture.
var caught_count: Callable = Callable()
## Objets (catégorie objet clé / CT pour le jingle « Obtained a Key Item! »).
var items: ItemLibrary
## (species_id: StringName) -> int : numéro national (0 si inconnu), pour les cris.
var species_dex: Callable = Callable()
## (party_index: int) -> StringName : espèce d'un membre de l'équipe (évolution).
var party_species: Callable = Callable()
## () -> StringName : espèce du compagnon sorti ("" si aucun).
var companion_species: Callable = Callable()
## (move_id: StringName) -> Array [type: StringName, catégorie: StringName] (vide si inconnue).
var move_info: Callable = Callable()
## (cell: Vector2i) -> StringName : sol de la case (« grass », « hard », « indoor »…).
var ground_at: Callable = Callable()

var _library: AudioLibrary
var _zones: ZoneLibrary
var _map_id: StringName = &""
var _map_override: StringName = &""
## Vrai tant que la couche SCENE porte le thème du « ! » (retiré à la fin du combat).
var _encounter_theme: bool = false
var _trainer_id: StringName = &""
## Espèce qui vient de crier à son apparition (herbe, gravats) : son cri d'entrée en combat
## n'est pas rejoué [D] (QA T14 : deux cris de suite).
var _encounter_cry: StringName = &""
## Combat vivant (T4, §1.3, §2.5) : bruitages déjà joués au repère de la chorégraphie, que
## l'événement du journal (qui arrive après) ne rejoue pas.
var _cued_moves: int = 0
var _cued_hits: int = 0
## Nœud dont les boutons restent muets (HUD d'exploration : joystick, boutons d'action).
var _ui_excluded: Node


func setup(audio_node: Node, zones: ZoneLibrary) -> void:
	audio = audio_node
	_library = audio.get(&"library")
	_zones = zones
	selector = MusicSelector.new(_library, zones)


## Écran titre (après son premier rendu : Boot l'appelle à l'image suivante).
func play_title() -> void:
	audio.call(&"set_music", L.ZONE, selector.event_track(&"title"))


## Introduction de Chen (prénoms) ouverte / refermée.
func on_intro_opened() -> void:
	audio.call(&"set_music", L.SCENE, selector.event_track(&"oak_intro"))


func on_intro_closed() -> void:
	audio.call(&"clear_music", L.SCENE)


## Nouvelle carte en place (écran encore noir) : morceau de la zone, ambiance.
func on_map_changed(map: GameMap) -> void:
	_map_id = map.map_id
	_map_override = map.music
	refresh_zone()
	audio.call(&"set_ambience", _library.ambience_for(_map_id, _zones.zone_of(_map_id)))


func on_mount_changed(kind: Mount.Kind) -> void:
	refresh_zone()
	if kind == Mount.Kind.BIKE:
		_sfx(&"world", &"bike_mount")


## Recalcule la musique de la carte (même morceau : il continue sans coupure).
func refresh_zone() -> void:
	if _map_id.is_empty():
		return
	audio.call(&"set_music", L.ZONE, selector.track_for(_map_id, _state()))


func on_trainer_spotted(_npc_id: StringName, trainer_id: StringName) -> void:
	var name := str(trainer_name.call(trainer_id)) if trainer_name.is_valid() else ""
	var track := selector.encounter_track(trainer_id, name)
	if track.is_empty():
		return
	_encounter_theme = true
	_sfx(&"world", &"trainer_spotted")
	audio.call(&"set_music", L.SCENE, track)


func on_battle_started(trainer_id: StringName) -> void:
	_trainer_id = trainer_id
	_cued_moves = 0
	_cued_hits = 0
	audio.call(&"set_music", L.BATTLE, selector.battle_track(trainer_id))


## Événement de combat : victoire (`BATTLE_ENDED` gagné) → musique de victoire ; montée de
## niveau → jingle.
func on_battle_event(event: BattleEvent) -> void:
	_battle_sfx(event)
	match event.kind:
		BattleEvent.Kind.SENT_OUT:
			if event.side == BattleEvent.SideId.FOE and event.species_id == _encounter_cry:
				_encounter_cry = &""
			else:
				play_species_cry(event.species_id)
		BattleEvent.Kind.FAINTED:
			play_species_cry(event.species_id, true)
		BattleEvent.Kind.BATTLE_ENDED:
			if event.outcome == Battle.Outcome.WIN:
				audio.call(&"set_music", L.BATTLE, selector.victory_track(_trainer_id))
		BattleEvent.Kind.LEVEL_UP:
			_jingle(&"level_up")


## Fin du combat : la zone (ou la scène) reprend là où elle était (SON-6).
func on_battle_finished(_trainer_id_end: StringName, _outcome: int) -> void:
	_trainer_id = &""
	_cued_moves = 0
	_cued_hits = 0
	_encounter_cry = &""
	audio.call(&"clear_music", L.BATTLE)
	if _encounter_theme:
		_encounter_theme = false
		audio.call(&"clear_music", L.SCENE)


func on_pokemon_caught() -> void:
	var first := caught_count.is_valid() and int(caught_count.call()) <= 1
	_jingle(&"first_catch" if first else &"catch")


func on_center_healed(_map_id_healed: StringName = &"", _registered: bool = false) -> void:
	_jingle(&"heal")


## Objet reçu (étape « give ») : objet clé et CT / CS → « Obtained a Key Item! ».
func on_item_given(item_id: StringName, _count: int = 1) -> void:
	_jingle(&"key_item" if _is_key_item(item_id) else &"item")


func on_item_found(item_id: StringName, _count: int = 1) -> void:
	_jingle(&"key_item" if _is_key_item(item_id) else &"item")


func on_evolution_started(party_index: int = 0, _into: StringName = &"") -> void:
	audio.call(&"set_music", L.JINGLE, selector.event_track(&"evolution"))
	if party_species.is_valid():
		play_species_cry(StringName(str(party_species.call(party_index))))


## Évolution finie : « Congratulations! » puis retour ; annulée : retour direct.
func on_evolution_finished(_party_index: int = 0, into: StringName = &"",
		cancelled: bool = false) -> void:
	if cancelled:
		audio.call(&"clear_music", L.JINGLE)
	else:
		audio.call(&"set_music", L.JINGLE, selector.event_track(&"evolved"))
		play_species_cry(into)


## Cri d'une espèce (rencontre, Pokémon d'ambiance : `EncounterDirector.cry_requested`).
func play_species_cry(species_id: StringName, fainted: bool = false) -> void:
	var dex := int(species_dex.call(species_id)) if species_dex.is_valid() else 0
	if dex > 0:
		audio.call(&"play_cry", dex, fainted)


## Cri d'un sauvage à son apparition (`EncounterDirector.cry_requested` : herbe qui bouge,
## gravats) ; retenu pour ne pas le rejouer à son entrée en combat.
func on_encounter_cry(species_id: StringName) -> void:
	_encounter_cry = species_id
	play_species_cry(species_id)


## Bouton « Cri » du Pokédex (espèce capturée, SON-12).
func on_pokedex_cry(number: int) -> void:
	audio.call(&"play_cry", number, false)


## Le joueur parle à son compagnon : son cri (jamais en boucle automatique).
func on_companion_line(_dialogue_id: StringName = &"") -> void:
	if companion_species.is_valid():
		play_species_cry(StringName(str(companion_species.call())))


## Étape de cinématique jouée : clé « music », Badge, Poké Flûte.
func on_cutscene_step(step: CutsceneStep) -> void:
	if step.music == STOP:
		audio.call(&"clear_music", L.SCENE)
	elif not step.music.is_empty():
		# Un identifiant de morceau (« blue_theme ») ou un moment (« rival », « oak »).
		var track := step.music if _library.has_track(step.music) \
			else selector.event_track(step.music)
		audio.call(&"set_music", L.SCENE, track)
	match step.kind:
		CutsceneStep.Kind.BADGE:
			_jingle(&"badge")
		CutsceneStep.Kind.FLUTE:
			_jingle(&"poke_flute")


## Fin de la cinématique : sa musique de scène s'arrête (pas le thème du « ! » d'un combat en
## cours).
func on_cutscene_finished(_cutscene_id: StringName = &"") -> void:
	if not _encounter_theme:
		audio.call(&"clear_music", L.SCENE)


## Un pas commence : le sol de la case d'arrivée (à pied ou en courant), le rebord (saut) ;
## rien à Vélo ni en Surf.
func on_player_step(_from_cell: Vector2i, to_cell: Vector2i, kind: StringName) -> void:
	if kind == &"jump":
		_sfx(&"world", &"ledge")
	elif (kind == &"walk" or kind == &"run") and ground_at.is_valid():
		_sfx(&"grounds", StringName(str(ground_at.call(to_cell))))


func on_bumped(_direction: Vector2i = Vector2i.ZERO) -> void:
	_sfx(&"world", &"bump")


## Changement de carte (porte, tapis, escalier) : un seul bruit de porte [D].
func on_transition_started(_target_map: StringName = &"") -> void:
	_sfx(&"world", &"door")


func on_menu_opened() -> void:
	_sfx(&"world", &"menu_open")


func on_menu_closed(_arg: Variant = null) -> void:
	_sfx(&"world", &"menu_close")


## Page de dialogue suivante (pas la première).
func on_dialogue_page(index: int) -> void:
	if index > 0:
		_sfx(&"world", &"dialog_next")


## Accroche unique de l'interface : tout bouton (existant sous [param root] ou ajouté ensuite à
## l'arbre) joue le clic quand on l'appuie, sauf sous [param excluded].
func watch_ui(root: Node, excluded: Node = null) -> void:
	_ui_excluded = excluded
	var tree := root.get_tree()
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	_hook_buttons(root)


func unwatch_ui(tree: SceneTree) -> void:
	if tree != null and tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node as BaseButton)


func _hook_buttons(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node as BaseButton)
	for child: Node in node.get_children():
		_hook_buttons(child)


func _hook_button(button: BaseButton) -> void:
	if not button.pressed.is_connected(_on_ui_pressed):
		button.pressed.connect(_on_ui_pressed.bind(button))


func _on_ui_pressed(button: BaseButton) -> void:
	if _ui_excluded != null and is_instance_valid(_ui_excluded) \
			and _ui_excluded.is_ancestor_of(button):
		return
	_sfx(&"world", &"ui_click")


## Repère d'une chorégraphie de combat (Combat vivant, §2.5) : `launch` (ou `charge`, tour 1)
## → bruitage de l'attaque ; `impact`, `impact_2`… → bruitage du coup, selon l'issue du plan.
## Le MOVE_USED et les DAMAGE qui suivent dans le journal restent alors muets.
func on_move_fx_cue(cue: StringName, plan: MoveFxPlan) -> void:
	if plan == null:
		return
	var id: StringName = &""
	if cue == MoveFxPlan.CUE_LAUNCH or cue == MoveFxPlan.CUE_CHARGE:
		id = _move_sfx(plan.move_id)
		_cued_moves += 1
	elif String(cue).begins_with(MoveFxPlan.CUE_IMPACT):
		var outcome := plan.outcome
		if outcome != null and outcome.result != MoveFxOutcome.Result.HIT:
			return
		var first := cue == MoveFxPlan.CUE_IMPACT
		id = _hit_sfx(outcome != null and outcome.critical and first,
			outcome.effectiveness if outcome != null else 1.0)
		_cued_hits += 1
	if not id.is_empty():
		audio.call(&"play_sfx", id)


func _battle_sfx(event: BattleEvent) -> void:
	var id: StringName = &""
	match event.kind:
		BattleEvent.Kind.DAMAGE:
			if _cued_hits > 0:
				_cued_hits -= 1
				return
			id = _hit_sfx(event.critical, event.effectiveness)
		BattleEvent.Kind.MOVE_USED:
			if _cued_moves > 0:
				_cued_moves -= 1
				return
			id = _move_sfx(event.move_id)
		BattleEvent.Kind.STAT_CHANGED:
			id = _library.sfx_for(&"stat_changes", &"up" if event.stages > 0 else &"down")
		BattleEvent.Kind.STATUS_INFLICTED:
			id = _library.sfx_for(&"statuses", event.status)
		_:
			id = _library.sfx_for(&"battle_events", BattleEvent.Kind.find_key(event.kind))
	if not id.is_empty():
		audio.call(&"play_sfx", id)


func _move_sfx(move_id: StringName) -> StringName:
	var info: Array = move_info.call(move_id) if move_info.is_valid() else []
	if info.size() == 2:
		return _library.move_sfx(move_id, info[0], info[1])
	return &""


static func _hit_sfx(critical: bool, effectiveness: float) -> StringName:
	if critical:
		return &"critical"
	if effectiveness > 1.0:
		return &"hit_super"
	if effectiveness < 1.0:
		return &"hit_weak"
	return &"hit_normal"


func _sfx(table: StringName, key: StringName) -> void:
	var id := _library.sfx_for(table, key)
	if not id.is_empty():
		audio.call(&"play_sfx", id)


func _jingle(event: StringName) -> void:
	var track := selector.event_track(event)
	if track != AudioLibrary.SILENCE:
		audio.call(&"play_jingle", track)


func _is_key_item(item_id: StringName) -> bool:
	if items == null or not items.has_item(item_id):
		return false
	var category := items.get_item(item_id).category
	return category == ItemData.Category.KEY or category == ItemData.Category.TM


func _state() -> Dictionary:
	var state := { MusicSelector.STATE_OVERRIDE: _map_override }
	if current_mount.is_valid():
		state[MusicSelector.STATE_MOVEMENT] = Mount.to_name(current_mount.call() as Mount.Kind)
	if has_flag.is_valid():
		state[MusicSelector.STATE_HAS_FLAG] = has_flag
	return state
