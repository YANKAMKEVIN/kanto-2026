class_name BootServices
extends Node
## Domaine « services » de [Boot] : ce que les PNJ et terminaux des Centres demandent par leurs
## dialogues (jalon 7, J15, J32, JOH0).
##
## Soins (Maman, Centre) et toast du point de repos, Boutique, Stockage, Pension (dépôt, retrait),
## terminal d'échange local, refus du réseau coupé pendant l'acte 1 du Chapitre Johto. Une demande
## faite pendant un dialogue est servie à sa fin ([method on_dialogue_finished]) : le menu ne
## s'ouvre pas pendant un dialogue.
##
## Extrait de `boot.gd` sans changer le comportement : Boot crée ce nœud, appelle chaque `setup_*`
## au même moment qu'avant le découpage et relaie ses accesseurs publics.

var _boot: Boot
## Toast « Point de repos enregistré — <zone> » en attente de la fin du dialogue du soin.
var _rest_toast: PackedStringArray = PackedStringArray()
## La boutique demandée par le marchand (`open_shop`), ouverte à la fin de son dialogue.
var _pending_shop: StringName = &""
## Le terminal du Centre a demandé le Stockage (`open_storage`) : ouvert à la fin du dialogue.
var _pending_storage: bool = false
## Pension (J15, jalon-15.md §2.5) : directeur (pas, conversation) ; le gardien (`open_daycare`)
## la demande, elle commence à la fin de son dialogue.
var _daycare: DaycareDirector
var _pending_daycare: bool = false
## Écran de la Pension (J15 T5) : choix du dépôt, bandeau et hôte des capacités du retrait.
var _daycare_overlay: DaycareOverlay
## J32 (T5) : terminal d'échange local des Centres (`open_local_trade`) ; la conversation
## commence à la fin du dialogue du terminal.
var _local_trade: LocalTradeDirector
var _pending_local_trade: bool = false
## JOH0 : le terminal d'échange a été demandé pendant l'acte 1 du Chapitre Johto (réseau de
## Kanto coupé) : le refus se dit à la fin du dialogue, à la place de l'écran.
var _pending_offline_notice: bool = false
## PC de Johto (v11) : le Stockage a été demandé pendant l'acte 1 : à la fin du dialogue du
## terminal, le PC dit que Kanto ne répond pas et ouvre la Boîte de Johto (écran Stockage).
var _pending_johto_box: bool = false
## Panneau d'ascenseur demandé par le même dialogue ([method BootWorld.open_pending_elevator]) :
## vrai s'il vient d'être ouvert. Servi entre la Pension et le terminal d'échange, comme avant.
var _elevator_opener: Callable


func _init(boot: Boot = null) -> void:
	_boot = boot


func get_daycare_director() -> DaycareDirector:
	return _daycare


func get_daycare_overlay() -> DaycareOverlay:
	return _daycare_overlay


func get_local_trade_director() -> LocalTradeDirector:
	return _local_trade


## Centre Pokémon (jalon 7, 7A.2, jalon-07.md §6.2) : soin fini, Boutique et Stockage demandés.
func setup_center() -> void:
	var services := _boot.get_service_director()
	services.center_healed.connect(_on_center_healed)
	services.shop_requested.connect(_on_shop_requested)
	services.storage_requested.connect(_on_storage_requested)


## Pension (J15, jalon-15.md §2.5) : compteur de pas sur le joueur, conversation du gardien ; puis
## le terminal d'échange local (J32, T5).
func setup_daycare_and_trade() -> void:
	var pokemon := _boot.get_pokemon_data()
	var evolutions := _boot.get_evolution_director()
	var runner := _boot.get_dialogue_runner()
	var services := _boot.get_service_director()
	_daycare = DaycareDirector.new()
	_daycare.name = "DaycareDirector"
	_daycare.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_daycare)
	_daycare.setup(GameState, _boot.get_player(), runner, _boot.get_dialogue_library(), pokemon,
		DaycareConfig.load_default())
	_daycare.set_learning(_boot.get_battle_director().get_move_learn_prompt(), evolutions)
	_daycare_overlay = DaycareOverlay.new()
	_daycare_overlay.name = "DaycareOverlay"
	_daycare_overlay.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_daycare_overlay)
	_daycare_overlay.attach(_daycare,
		func(view: DaycarePickView) -> PartyPickerView: return view.to_picker_view(pokemon))
	_daycare.overlay = _daycare_overlay
	_daycare.deposited.connect(_on_daycare_deposited.unbind(1))
	_daycare.finished.connect(_on_daycare_finished)
	services.daycare_requested.connect(_on_daycare_requested)
	# Terminal d'échange local (J32, T5 ; `jalon-32.md` §1.2, N-15).
	_local_trade = LocalTradeDirector.new()
	_local_trade.name = "LocalTradeDirector"
	_local_trade.process_mode = Node.PROCESS_MODE_PAUSABLE
	_boot.add_child(_local_trade)
	_local_trade.setup(GameState, _boot.get_player(), runner, pokemon, evolutions)
	_local_trade.items = _boot.get_item_library() # JOH0 : nom de l'objet demandé (Peau Métal…)
	var trade_overlay := _boot.get_trade_overlay()
	_local_trade.pick_handler = func(view: PartyPickerView) -> int:
		return await trade_overlay.pick(view)
	_local_trade.started.connect(_boot.refresh_controls)
	_local_trade.finished.connect(_on_local_trade_finished)
	services.local_trade_requested.connect(_on_local_trade_requested)


## Le panneau d'ascenseur se sert dans la même file (voir [member _elevator_opener]).
func set_elevator_opener(opener: Callable) -> void:
	_elevator_opener = opener


## Fin d'un dialogue (contrôles déjà rafraîchis par Boot) : toast du point de repos, puis la
## demande en attente, une seule : Boutique, Stockage, Pension, ascenseur, terminal d'échange,
## refus du réseau coupé.
func on_dialogue_finished() -> void:
	if not _rest_toast.is_empty():
		_boot.get_hud().show_toast(_rest_toast[0], _rest_toast[1])
		_rest_toast = PackedStringArray()
	var menu := _boot.get_menu_director()
	if not _pending_shop.is_empty():
		var shop_id := _pending_shop
		_pending_shop = &""
		if not menu.open(MenuRoute.shop(shop_id), true):
			push_error("Boot : la Boutique « %s » ne s'ouvre pas" % shop_id)
	elif _pending_johto_box:
		# PC de Johto : l'explication (complète la première fois, une ligne ensuite), puis, à
		# sa fin, la Boîte de Johto (branche du Stockage ci-dessous).
		_pending_johto_box = false
		_pending_storage = true
		var flags := GameState.flags
		var dialogue := TeamConfiscation.JOHTO_BOX_SHORT_DIALOGUE \
			if flags.has_flag(TeamConfiscation.JOHTO_BOX_EXPLAINED) \
			else TeamConfiscation.JOHTO_BOX_DIALOGUE
		flags.set_flag(TeamConfiscation.JOHTO_BOX_EXPLAINED)
		_boot.get_dialogue_runner().play(dialogue, null, SceneRouter.get_current_map())
	elif _pending_storage:
		_pending_storage = false
		if not menu.open(MenuRoute.storage(), true):
			push_error("Boot : le Stockage ne s'ouvre pas sur « %s »" % _boot.current_map_id())
	elif _pending_daycare:
		_pending_daycare = false
		_daycare.run()
	elif _elevator_opener.is_valid() and _elevator_opener.call():
		pass
	elif _pending_local_trade:
		_pending_local_trade = false
		_local_trade.run()
	elif _pending_offline_notice:
		# JOH0 : acte 1 du Chapitre Johto, le réseau de Kanto est coupé.
		_pending_offline_notice = false
		_boot.get_dialogue_runner().play(TeamConfiscation.STORAGE_OFFLINE_DIALOGUE, null,
			SceneRouter.get_current_map())


## Soin demandé par un dialogue « heal » (jalon 5 §3.11, Maman) : l'équipe est soignée (PV et
## PP) ; le point de repos ne change pas (dossier 09 §7).
func on_heal_requested() -> void:
	_boot.get_service_director().heal()
	_boot.request_autosave("soin")


## « open_shop » (le marchand, jalon-07.md §6.10) : la Boutique s'ouvre en écran seul dès la fin
## du dialogue (partie stable). Boutique inconnue : refusée tout de suite.
func _on_shop_requested(shop_id: StringName) -> void:
	if not _boot.get_shop_library().has_shop(shop_id):
		push_error("Boot : boutique inconnue « %s »" % shop_id)
		return
	_pending_shop = shop_id


## « open_storage » (le terminal du Centre, jalon-07.md §6.9) : le Stockage s'ouvre en écran
## seul dès la fin du dialogue ; retour = fermer, autosave à la fermeture s'il a changé.
## Acte 1 du Chapitre Johto (réseau de Kanto coupé) : le PC le dit, puis ouvre la Boîte de Johto.
func _on_storage_requested() -> void:
	if TeamConfiscation.is_storage_offline(GameState.flags):
		_pending_johto_box = true
		return
	_pending_storage = true


## Soin d'un Centre fini (jalon-07.md §5.3) : écriture tout de suite (joueur au comptoir, la
## partie ne peut plus rien perdre), comme au réveil ; le toast du point de repos attend la fin
## du dialogue (après « Voilà. Tout le monde est en pleine forme. »), une fois par changement.
func _on_center_healed(map_id: StringName, registered: bool) -> void:
	_boot.get_companion_controller().note_joy()
	if registered:
		_rest_toast = _boot.get_rest_points().registered_toast(
			_boot.get_zone_library().zone_name_of(map_id))
	_boot.save_now_or_soon("soin")


# --- Pension (J15, jalon-15.md §2.5.3) ----------------------------------------------------------

## « open_daycare » (le gardien) : la conversation de la Pension commence à la fin du dialogue.
func _on_daycare_requested() -> void:
	_pending_daycare = true


## Dépôt fait : écriture tout de suite (quitter avant l'autosave ne perd rien), comme au soin.
## Le compagnon déposé (choix effacé par le directeur) rentre tout de suite (J11, 11D).
func _on_daycare_deposited() -> void:
	_boot.get_companion_controller().refresh()
	_boot.save_now_or_soon("pension, dépôt")


## Conversation finie (joueur rendu) : contrôles ; après un retrait, **une seule** écriture.
func _on_daycare_finished(withdrew: bool) -> void:
	_boot.get_companion_controller().refresh()
	_boot.refresh_controls()
	if not withdrew:
		return
	_boot.save_now_or_soon("pension, retrait")


# --- Terminal d'échange local (J32, T5) ---------------------------------------------------------

## « open_local_trade » (le terminal) : la conversation commence à la fin du dialogue.
func _on_local_trade_requested() -> void:
	# JOH0 : le terminal d'échange est fermé tant que le Stockage est hors ligne [D].
	if TeamConfiscation.is_storage_offline(GameState.flags):
		_pending_offline_notice = true
		return
	_pending_local_trade = true


## Fin de la conversation : compagnon à jour (même identifiant, nouvelle espèce) ; échange fait :
## écriture tout de suite, comme un retrait de la Pension.
func _on_local_trade_finished(traded: bool) -> void:
	_boot.get_companion_controller().refresh()
	_boot.refresh_controls()
	if not traded:
		return
	_boot.save_now_or_soon("échange local")
