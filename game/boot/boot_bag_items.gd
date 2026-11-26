class_name BootBagItems
extends Node
## Domaine « objets du Sac » de [Boot] : ce qui se joue par-dessus le menu ou hors combat quand
## le Sac utilise un objet sur un Pokémon de l'équipe.
##
## CT (jalon 11, T12), PP Plus et Éther (lot 32P), pierres d'évolution (jalon 12, T23), Super
## Bonbon (jalon 14, T18b), et le voile d'apprentissage commun ([TmLearnOverlay]).
##
## Extrait de `boot.gd` sans changer le comportement : Boot crée ce nœud, appelle [method setup]
## au même moment qu'avant le découpage et relaie ses accesseurs publics.

## Lot 32P : choix de la capacité d'un PP Plus ou d'un Éther (textes validés par Kevin le 2026-10-29).
const PP_MOVE_CAPTION := "Choisis une capacité"
const PP_MOVE_CONFIRM := "CHOISIR"
const PP_MOVE_CANCEL := "RETOUR"
## Raison de blocage du joueur pendant une évolution par pierre hors combat (jalon 12, T23).
const EVOLUTION_ITEM: StringName = &"evolution_item"
## Raison de blocage du joueur pendant tout le déroulé d'un Super Bonbon (jalon 14, T18b) : voile
## au-dessus du menu, puis évolution éventuelle. La partie n'est pas stable : aucune écriture.
const RARE_CANDY: StringName = &"rare_candy"

var _boot: Boot
## Voile de l'apprentissage d'une CT depuis le Sac (jalon 11), créé au premier besoin.
var _tm_overlay: TmLearnOverlay
## Pierre en cours d'utilisation (jalon 12, T23) : retirée du Sac à
## [signal EvolutionDirector.evolution_applied], une seule fois ; &"" sinon.
var _stone_item: StringName = &""
## Place du Pokémon qui reçoit un Super Bonbon pendant son déroulé (jalon 14, T18b) ; −1 sinon.
var _candy_index: int = -1


func _init(boot: Boot = null) -> void:
	_boot = boot


## Sac → pierre, Super Bonbon, PP Plus ou Éther → Pokémon ; la pierre est retirée à
## [signal EvolutionDirector.evolution_applied]. (La CT est branchée par Boot avec l'écran du Sac :
## [method on_tm_learn_requested].)
func setup() -> void:
	var menu := _boot.get_menu_director()
	menu.evolution_item_requested.connect(_on_evolution_item_requested)
	menu.rare_candy_requested.connect(_on_rare_candy_requested)
	menu.pp_move_requested.connect(_on_pp_move_requested)
	_boot.get_evolution_director().evolution_applied.connect(_on_evolution_applied)


func get_tm_learn_overlay() -> TmLearnOverlay:
	return _tm_overlay


## Vrai pendant le déroulé d'un Super Bonbon (tests, QA).
func is_rare_candy_running() -> bool:
	return _candy_index >= 0


## Jalon 11 (T12) : le Pokémon [param index] apprend la capacité de la CT [param item_id] par le
## déroulé partagé avec le combat et l'évolution ([MoveLearnPrompt.teach]), sur un voile au-dessus
## du menu ([TmLearnOverlay]) ; la CT reste au Sac.
func on_tm_learn_requested(index: int, item_id: StringName) -> void:
	var item := _boot.get_item_library().get_item(item_id)
	var pokemon: Pokemon = GameState.party.get_at(index)
	if item == null or pokemon == null:
		return
	_learn_overlay().open()
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	var learned := await prompt.teach(pokemon, index, item.teaches,
		_tm_overlay.get_message_banner(), _tm_overlay.get_prompt_host())
	prompt.release()
	_tm_overlay.close()
	_boot.get_menu_director().finish_tm_learn(index, item_id, learned)


## Lot 32P : PP Plus ou Éther : la capacité du Pokémon [param index] se choisit dans le panneau
## d'oubli en mode choix, sur le voile d'apprentissage ; le menu applique l'objet.
func _on_pp_move_requested(index: int, item_id: StringName) -> void:
	var pokemon: Pokemon = GameState.party.get_at(index)
	if pokemon == null:
		return
	_learn_overlay().open()
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	var slot := await prompt.choose_move(pokemon, PP_MOVE_CAPTION, PP_MOVE_CONFIRM,
		PP_MOVE_CANCEL, _tm_overlay.get_message_banner(), _tm_overlay.get_prompt_host())
	prompt.release()
	_tm_overlay.close()
	_boot.get_menu_director().finish_pp_item(index, item_id, slot)


## Le voile d'apprentissage au-dessus du menu (CT, Super Bonbon, PP), créé au premier besoin
## (enfant direct de Boot, comme avant le découpage).
func _learn_overlay() -> TmLearnOverlay:
	if _tm_overlay == null:
		_tm_overlay = TmLearnOverlay.new()
		_tm_overlay.name = "TmLearnOverlay"
		_boot.add_child(_tm_overlay)
	return _tm_overlay


# --- Jalon 12 (T23) : évolution par pierre hors combat ------------------------------------------

## Pierre utilisée sur le Pokémon [param index] (`jalon-12.md` §2.9) : menu fermé, joueur et
## contrôles bloqués, [method EvolutionDirector.play_item] (non annulable) ; la pierre quitte le
## Sac **dans l'appel même** où l'évolution est appliquée ([method _on_evolution_applied]). Aucune
## image stable pendant la séquence (le joueur est bloqué) : une fermeture de l'application
## reprend à la sauvegarde d'avant, pierre comprise. Fin : retour au monde, compagnon mis à jour
## (rentre en silence si sa nouvelle espèce n'est pas éligible), autosave.
func _on_evolution_item_requested(index: int, item_id: StringName) -> void:
	var evolutions := _boot.get_evolution_director()
	var candidate := StoneUse.candidate(GameState.party, index, item_id,
		_boot.get_pokemon_data())
	if candidate == null or not GameState.bag.has(item_id) or evolutions.is_playing():
		return
	var player := _boot.get_player()
	_boot.get_menu_director().close()
	player.set_input_enabled(false, EVOLUTION_ITEM)
	_boot.refresh_controls()
	_stone_item = item_id
	evolutions.speed_scale = _boot.get_battle_director().speed_scale
	await evolutions.play_item(candidate, GameState.party, item_id)
	_stone_item = &""
	if is_instance_valid(player):
		player.set_input_enabled(true, EVOLUTION_ITEM)
	_boot.get_companion_controller().refresh()
	_boot.refresh_controls()
	_boot.request_autosave("évolution")


## L'évolution vient d'être appliquée : la pierre en cours quitte le Sac (une seule fois).
func _on_evolution_applied(_party_index: int, _into: StringName) -> void:
	if _stone_item.is_empty():
		return
	if not GameState.bag.remove(_stone_item, 1):
		push_error("Boot : la pierre « %s » n'est plus dans le Sac" % _stone_item)
	_stone_item = &""


# --- Jalon 14 (T18b) : Super Bonbon depuis le Sac -----------------------------------------------

## Super Bonbon donné au Pokémon [param index] (`jalon-14.md` §2.6, dossier 17 §5) :
## 1. dans le même appel, le bonbon quitte le Sac et le niveau est gagné ([method RareCandy.apply] :
##    stats et PV recalculés) ; le joueur est bloqué ([constant RARE_CANDY]) : la partie n'est pas
##    stable, rien n'est écrit pendant le déroulé (une fermeture de l'application reprend avant
##    l'usage, bonbon et niveau ensemble) ;
## 2. voile au-dessus du menu ([TmLearnOverlay]) : « {pokemon} monte au niveau {niveau} ! »
##    (n° 62), puis chaque capacité du niveau par [method MoveLearnPrompt.teach] (« apprend », ou
##    l'oubli ; NE PAS APPRENDRE la laisse) ;
## 3. sans évolution due : retour au Sac ([method MenuDirector.finish_rare_candy] : autosave à la
##    fermeture du menu) ; avec une évolution due ([method RareCandy.evolution_after]) : comme la
##    Pierre Lune, menu fermé puis écran d'évolution hors combat, mais **annulable** (évolution par
##    niveau : ARRÊTER, retour Android ; reproposée au prochain niveau gagné), puis retour au monde
##    et autosave.
func _on_rare_candy_requested(index: int, item_id: StringName) -> void:
	var evolutions := _boot.get_evolution_director()
	var data := _boot.get_pokemon_data()
	var menu := _boot.get_menu_director()
	var pokemon: Pokemon = GameState.party.get_at(index)
	if pokemon == null or _candy_index >= 0 or evolutions.is_playing() \
			or not GameState.bag.has(item_id) or RareCandy.check(pokemon) != RareCandy.Check.OK:
		return
	var player := _boot.get_player()
	_candy_index = index
	player.set_input_enabled(false, RARE_CANDY)
	GameState.bag.remove(item_id, 1)
	var level_up := RareCandy.apply(pokemon, data)
	if level_up == null:
		push_error("Boot : Super Bonbon sans effet sur la place %d" % index)
		GameState.bag.add(item_id, 1)
		_end_rare_candy()
		return
	var overlay := _learn_overlay()
	overlay.open()
	var banner := overlay.get_message_banner()
	await banner.show_message(_rare_candy_line(pokemon, index), true)
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	for move_id: StringName in level_up.moves:
		if not is_instance_valid(banner):
			return
		await prompt.teach(pokemon, index, move_id, banner, overlay.get_prompt_host())
	prompt.release()
	if not is_instance_valid(overlay):
		return
	overlay.close()
	menu.finish_rare_candy(index, item_id)
	var into := RareCandy.evolution_after(pokemon, data)
	if not into.is_empty() and data.has_species(into):
		menu.close()
		var candidate := EvolutionCandidate.new(index, pokemon.species_id, into)
		var list: Array[EvolutionCandidate] = [candidate]
		evolutions.speed_scale = _boot.get_battle_director().speed_scale
		await evolutions.play(list, GameState.party)
		if not is_instance_valid(player):
			return
		_end_rare_candy()
		_boot.get_companion_controller().refresh()
		_boot.request_autosave("évolution")
		return
	_end_rare_candy()


## « Abra monte au niveau 16 ! » (n° 62, accordé au sexe si la donnée a une variante).
func _rare_candy_line(pokemon: Pokemon, index: int) -> String:
	var data := _boot.get_pokemon_data()
	var event := BattleEvent.new(BattleEvent.Kind.LEVEL_UP, BattleEvent.SideId.PLAYER)
	event.pokemon_name = pokemon.display_name(data)
	event.gender = pokemon.gender
	event.party_index = index
	event.level = pokemon.level
	event.species_id = pokemon.species_id
	return _boot.get_battle_text().line_for(&"rare_candy_level", event, data)


func _end_rare_candy() -> void:
	_candy_index = -1
	var player := _boot.get_player()
	if is_instance_valid(player):
		player.set_input_enabled(true, RARE_CANDY)
	_boot.refresh_controls()
