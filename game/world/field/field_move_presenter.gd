class_name FieldMovePresenter
extends Node
## Mise en scène d'une capacité de terrain (jalon 16, Coupe ; `jalon-16.md` §2.3, dossier 19
## §7) : le gestionnaire [member CutsceneDirector.field_move_handler] posé par Boot. Affichage
## seul : les règles (case, ordre des étapes) viennent de [FieldMoveStage], le Pokémon qui coupe
## de [FieldMoves] (par [member user_source]).
##
## 1. le Pokémon apparaît à côté du joueur avec l'éclat de Ball ; si c'est le compagnon resté
##    dehors ([method CompanionController.on_cutscene_started]), il y marche ;
## 2. effet de coupe ([CutSlash], 4 images peintes de la série 18) et vibration légère ;
## 3. l'obstacle disparaît en fondu (le directeur retire ensuite un PNJ ; un décor part avec le
##    drapeau de l'étape « set » suivante) ;
## 4. le Pokémon rentre dans sa Ball, sauf le compagnon, qui reste dehors.
## Espèce sans planche d'exploration peinte : pas de Pokémon montré (aucun substitut), l'effet
## seul. « Réduire les animations » : l'obstacle disparaît en fondu, rien d'autre.

## Début de chaque étape ([constant FieldMoveStage.APPEAR], SLASH, CLEAR, WITHDRAW).
signal stage_started(stage: StringName)

## Hauteur de l'effet au-dessus du pied de l'obstacle (px) : valeur par défaut (règle 4).
const SLASH_LIFT: float = 64.0

## « Réduire les animations ».
var reduce_motion: bool = false
## `func(move: StringName) -> Pokemon` : le Pokémon qui utilise la capacité (null : aucun).
var user_source: Callable

var _companion: CompanionController
var _player: Player
var _map: GameMap
## Pokémon montré pendant la capacité en cours (tests, captures) ; null sinon.
var _shown: Companion
var _slash: CutSlash


func _init() -> void:
	name = "FieldMovePresenter"


func setup(companion: CompanionController, player: Player) -> void:
	_companion = companion
	_player = player


## Carte courante (Boot, à chaque changement de carte).
func set_map(map: GameMap) -> void:
	_map = map


## Le Pokémon montré pendant la capacité en cours (null sinon).
func get_shown() -> Companion:
	return _shown if is_instance_valid(_shown) else null


## L'effet de coupe en cours (null sinon).
func get_slash() -> CutSlash:
	return _slash if is_instance_valid(_slash) else null


## Coroutine : capacité [param move] sur [param target] (voir l'en-tête).
## Passe systèmes 2 (Force) : [param clears] faux = rien à retirer ; le Pokémon apparaît, prend
## appui ([constant FieldMoveStage.HOLD_DURATION], vibration légère) et rentre ; ni effet ni
## fondu ([method FieldMoveStage.stages]).
func perform(move: StringName, target: Node2D, clears: bool = true) -> void:
	if reduce_motion or not is_instance_valid(_map) or _player == null:
		if clears:
			stage_started.emit(FieldMoveStage.CLEAR)
			await _fade(target, FieldMoveStage.REDUCED_FADE)
		return
	var pokemon: Pokemon = user_source.call(move) if user_source.is_valid() else null
	var facing := _player.get_facing()
	var cell := FieldMoveStage.NONE
	if pokemon != null:
		cell = FieldMoveStage.pick_cell(_player.get_cell(), facing, _is_free)
	var is_companion := cell != FieldMoveStage.NONE and _companion != null \
		and _companion.is_kept_in_cutscene() and _companion.get_chosen() == pokemon
	var temporary: Companion = null
	if cell != FieldMoveStage.NONE and not is_companion:
		temporary = _make_pokemon(pokemon)
	var plan := FieldMoveStage.stages(false, is_companion or temporary != null, is_companion,
		clears)
	if plan.has(FieldMoveStage.APPEAR):
		stage_started.emit(FieldMoveStage.APPEAR)
		if is_companion:
			_shown = _companion.get_node_2d()
			await _companion.step_to(cell, facing)
		else:
			_shown = temporary
			_map.get_entities().add_child(temporary)
			temporary.set_grid(_map.get_grid())
			temporary.place(cell, facing)
			await temporary.appear()
	if plan.has(FieldMoveStage.SLASH):
		stage_started.emit(FieldMoveStage.SLASH)
		Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
		_slash = CutSlash.new()
		_map.add_child(_slash)
		_slash.position = _map.to_local(_effect_position(target))
		await _slash.play(FieldMoveStage.SLASH_DURATION)
		_slash.queue_free()
		_slash = null
	if plan.has(FieldMoveStage.CLEAR):
		stage_started.emit(FieldMoveStage.CLEAR)
		await _fade(target, FieldMoveStage.CLEAR_FADE)
	if not clears and not plan.is_empty():
		Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
		var hold := create_tween()
		hold.tween_interval(FieldMoveStage.HOLD_DURATION)
		await hold.finished
	if plan.has(FieldMoveStage.WITHDRAW):
		stage_started.emit(FieldMoveStage.WITHDRAW)
		await temporary.withdraw()
		temporary.queue_free()
	_shown = null


## Pokémon de passage (même nœud que le compagnon, hors de la grille) ; null si son espèce n'a
## pas de planche d'exploration peinte.
func _make_pokemon(pokemon: Pokemon) -> Companion:
	var sprite := StringName(CharacterLook.POKEMON_PREFIX + String(pokemon.species_id))
	if not CharacterLook.resolve(sprite).painted:
		return null
	var node := Companion.new()
	node.name = "FieldMovePokemon"
	if not node.set_species(pokemon.species_id, sprite):
		node.free()
		return null
	return node


func _is_free(cell: Vector2i) -> bool:
	if not _map.get_grid().is_free(cell):
		return false
	var warps := _map.get_warps()
	if warps != null:
		for warp: Warp in warps.get_at(cell):
			if warp.trigger == Warp.Trigger.STEP_ON:
				return false
	return true


## Position monde de l'effet : milieu des cases bloquées d'une [FlagGate] (l'arbuste du J15),
## sinon le pied du nœud ; relevée de [constant SLASH_LIFT].
func _effect_position(target: Node2D) -> Vector2:
	var gate := target as FlagGate
	if gate != null and not gate.blocking_cells.is_empty():
		var sum := Vector2.ZERO
		for cell: Vector2i in gate.blocking_cells:
			sum += Grid.cell_to_world(cell)
		return _map.to_global(sum / gate.blocking_cells.size()) - Vector2(0.0, SLASH_LIFT)
	return target.global_position - Vector2(0.0, SLASH_LIFT)


func _fade(target: Node2D, seconds: float) -> void:
	if not is_instance_valid(target) or not target.visible:
		return
	var tween := target.create_tween()
	tween.tween_property(target, ^"modulate:a", 0.0, seconds)
	await tween.finished
