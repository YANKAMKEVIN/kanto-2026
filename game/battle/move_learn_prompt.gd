class_name MoveLearnPrompt
extends Node
## Le déroulé « apprendre / oublier une capacité » (jalon-09.md §2.3.4), extrait du
## [BattleDirector] (jalon 5C, Q29 et Q30 ; confirmation : Q-18) pour servir aussi hors du
## journal de combat : aux capacités apprises à l'évolution ([EvolutionDirector]).
##
## - [method offer_forget] : le Pokémon connaît déjà quatre capacités. Le bandeau sort (le
##   panneau le recouvrirait), le [MoveForgetPanel] fait choisir la capacité à oublier ou NE PAS
##   APPRENDRE ; avec [member confirm_forget], OUBLIER passe par la question à deux cartes
##   (`ChoiceCards`, GARDER rend la main au panneau). Puis « … oublie … et apprend … ! » ou
##   « … n'apprend pas … », qui attend un toucher. Le combat l'appelle pour
##   MOVE_FORGET_OFFERED (le moteur a déjà écrit « … veut apprendre … »).
## - [method teach] (évolution) : une place libre → la capacité est apprise et « {pokemon}
##   apprend {move} ! » attend un toucher ; quatre capacités → « move_forget_prompt » puis
##   [method offer_forget]. Comme en combat.
##
## Il ne possède aucun écran : l'appelant passe le bandeau des messages ([BattleMessageBanner],
## celui du combat ou celui de l'écran d'évolution) et le parent plein écran des panneaux
## (placés à [constant BattleHudLayout.Slot.FORGET]). Le panneau est gardé d'une offre à
## l'autre tant que le parent ne change pas ; [method release] le libère.

const FORGET_PANEL_SCENE: PackedScene = preload("res://game/ui/battle/move_forget_panel.tscn")

## Durées des panneaux (0 = instantané, tests) ; lue à la création du panneau.
var speed_scale: float = 1.0
## Vibrations des panneaux ; lue à la création du panneau.
var haptics_enabled: bool = true
## « Confirmer certaines actions » (Paramètres, Q-18) : oublier passe par deux cartes.
var confirm_forget: bool = false
## Tests seulement : composant à deux cartes de remplacement (défaut : `ChoiceCards`).
var choice_cards_script: GDScript = null

var _data: PokemonData
var _texts: BattleText
var _panel: MoveForgetPanel


func setup(data: PokemonData, texts: BattleText) -> void:
	_data = data
	_texts = texts


## Coroutine (hors journal : évolution) : [param move_id] pour [param pokemon] (place
## [param party_index] dans l'équipe). Une place libre : apprise, puis « {pokemon} apprend
## {move} ! » (toucher). Quatre capacités : « {pokemon} veut apprendre {move}… » puis
## [method offer_forget]. Vrai si la capacité est apprise ; faux si refusée, déjà connue ou
## inconnue (rien ne change).
func teach(pokemon: Pokemon, party_index: int, move_id: StringName,
		banner: BattleMessageBanner, host: Control) -> bool:
	if pokemon == null or _data == null or _texts == null:
		push_error("MoveLearnPrompt : non branché (setup) ou Pokémon absent")
		return false
	var result := pokemon.learn_move(move_id, _data)
	if result == Pokemon.LearnResult.LEARNED:
		var learned := _event(BattleEvent.Kind.MOVE_LEARNED, pokemon, party_index, move_id)
		if is_instance_valid(banner):
			await banner.show_message(_texts.line_for(&"move_learned", learned, _data), true)
		return true
	if result != Pokemon.LearnResult.NEEDS_FORGET:
		return false
	var offered := _event(BattleEvent.Kind.MOVE_FORGET_OFFERED, pokemon, party_index, move_id)
	if not is_instance_valid(banner) or not is_instance_valid(host):
		# Sans écran (tests, outils) : rien ne se décide à la place du joueur.
		return false
	await banner.show_message(_texts.line_for(&"move_forget_prompt", offered, _data))
	return await offer_forget(pokemon, offered, banner, host)


## Coroutine : [param pokemon] veut apprendre [member BattleEvent.move_id] de [param event]
## mais connaît déjà quatre capacités. Le bandeau [param banner] sort, le panneau (dans
## [param host]) fait choisir ; seul OUBLIER (après sélection d'une carte) ou NE PAS
## APPRENDRE ferme l'offre. Oubli : [method Pokemon.replace_move] (PP pleins) et « oublie… et
## apprend… » ; refus : rien ne change et « n'apprend pas… ». Rend la main une fois la phrase
## lue (toucher). Vrai si la capacité est apprise.
func offer_forget(pokemon: Pokemon, event: BattleEvent, banner: BattleMessageBanner,
		host: Control) -> bool:
	var offered := BattleViews.offered_move(event.move_id, _data) if _data != null else null
	if pokemon == null or offered == null or not is_instance_valid(banner) \
			or not is_instance_valid(host):
		push_error("MoveLearnPrompt : offre d'oubli impossible (« %s » pour « %s »)"
			% [event.move_id, event.pokemon_name])
		return false
	var known := BattleViews.moves(pokemon, _data)
	# Le panneau recouvre le bandeau : le bandeau sort d'abord, jamais les deux ensemble.
	banner.skip()
	banner.slide_out()
	while banner.is_sliding():
		await get_tree().process_frame
	var panel := _ensure_panel(host)
	var answer: Array = []
	while true:
		panel.show_offer(offered, known)
		answer = await _first_of(panel.forget_chosen, panel.skip_chosen)
		while panel.is_sliding():
			await get_tree().process_frame
		if answer[0] != 0 or not confirm_forget:
			break
		var slot := int(answer[1])
		var old_id: StringName = pokemon.moves[slot].move_id \
			if slot >= 0 and slot < pokemon.moves.size() else &""
		if await _confirm_forget(event, old_id, host):
			break
	var line := ""
	var learned := false
	if answer[0] == 0:
		var slot := int(answer[1])
		var old_move: StringName = pokemon.moves[slot].move_id \
			if slot >= 0 and slot < pokemon.moves.size() else &""
		if pokemon.replace_move(slot, event.move_id, _data):
			learned = true
			line = _texts.line_for(&"move_forgot", event, _data, old_move)
	if line.is_empty():
		line = _texts.line_for(&"move_not_learned", event, _data)
	await banner.show_message(line, true)
	return learned


## Le panneau d'oubli, tant qu'il existe (ouvert pendant une offre, tests) ; null sinon.
func get_forget_panel() -> MoveForgetPanel:
	return _panel if is_instance_valid(_panel) else null


## Libère le panneau (fin du combat, fin de l'écran d'évolution).
func release() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null


## Coroutine : la question « Oublier {capacité} ? » en deux cartes (composant `ChoiceCards`).
## Vrai si le joueur confirme (OUBLIER) ; GARDER rend la main au panneau d'oubli.
func _confirm_forget(event: BattleEvent, old_move: StringName, host: Control) -> bool:
	var script: GDScript = choice_cards_script if choice_cards_script != null else ChoiceCards
	var view := ChoiceView.new(
		_texts.line_for(&"forget_confirm_title", event, _data, old_move),
		_texts.line_for(&"forget_confirm_yes", event, _data, old_move),
		_texts.line_for(&"forget_confirm_no", event, _data, old_move))
	view.detail = _texts.line_for(&"forget_confirm_detail", event, _data, old_move)
	var cards: Control = script.new()
	cards.set(&"speed_scale", speed_scale)
	host.add_child(cards)
	cards.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cards.call(&"show_choice", view)
	var box: Array[bool] = []
	cards.connect(&"chosen", func(confirmed: bool) -> void: box.append(confirmed))
	while box.is_empty():
		await get_tree().process_frame
	cards.queue_free()
	return box[0]


## Le panneau d'oubli dans [param host] (créé au premier besoin, à son emplacement) ; un
## panneau resté dans un autre parent (combat, puis écran d'évolution) est remplacé.
func _ensure_panel(host: Control) -> MoveForgetPanel:
	if is_instance_valid(_panel) and _panel.get_parent() == host:
		return _panel
	release()
	_panel = FORGET_PANEL_SCENE.instantiate() as MoveForgetPanel
	host.add_child(_panel)
	BattleHudLayout.place(_panel, BattleHudLayout.Slot.FORGET)
	_panel.speed_scale = speed_scale
	_panel.haptics_enabled = haptics_enabled
	return _panel


## Événement « hors journal » qui porte ce que les phrases demandent : nom affiché (surnom ou
## espèce actuelle), sexe (accord), espèce, place, niveau, capacité.
func _event(kind: BattleEvent.Kind, pokemon: Pokemon, party_index: int,
		move_id: StringName) -> BattleEvent:
	var event := BattleEvent.new(kind, BattleEvent.SideId.PLAYER)
	event.pokemon_name = pokemon.display_name(_data)
	event.species_id = pokemon.species_id
	event.party_index = party_index
	event.level = pokemon.level
	event.gender = pokemon.gender
	event.hp = pokemon.hp
	event.max_hp = pokemon.max_hp()
	event.move_id = move_id
	return event


## Coroutine : attend le premier des deux signaux. Renvoie [index (0/1), valeur].
func _first_of(a: Signal, b: Signal) -> Array:
	var box: Array = []
	var on_a := func(value: Variant = null) -> void:
		if box.is_empty():
			box.append([0, value])
	var on_b := func(value: Variant = null) -> void:
		if box.is_empty():
			box.append([1, value])
	a.connect(on_a)
	b.connect(on_b)
	while box.is_empty():
		await get_tree().process_frame
	a.disconnect(on_a)
	b.disconnect(on_b)
	return box[0]
