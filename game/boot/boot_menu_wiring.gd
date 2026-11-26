class_name BootMenuWiring
extends RefCounted
## Câblage du Menu Dresseur de [Boot] (jalon 6, `jalon-06.md` §6.6 à §6.12) : signaux du
## directeur ([MenuDirector]) vers l'écran ([TrainerMenu]) et gestes de l'écran vers le
## directeur. Les gestionnaires propres à Boot (réglages, sauvegarde, costume, CT) restent
## branchés par Boot, juste après cet appel.
##
## Extrait de `boot.gd` sans changer le comportement : mêmes branchements, dans le même ordre.
## Les tests qui montent le vrai écran sans Boot peuvent s'en servir (voir
## `tests/helpers/fake_shop_screen.gd`).


static func wire(menu: MenuDirector, screen: TrainerMenu) -> void:
	# Ouverture et vue dans la même frame, sans await (un fondu coupé laisse une coroutine non
	# reprise).
	menu.menu_opened.connect(screen.open_animated)
	menu.menu_closed.connect(screen.close_animated.unbind(1))
	menu.dashboard_shown.connect(screen.show_dashboard)
	menu.placeholder_shown.connect(screen.show_placeholder)
	screen.route_requested.connect(menu.go)
	screen.back_requested.connect(menu.handle_back)
	screen.close_requested.connect(menu.close)
	# Costumes (dossier-costumes.md, CO-1, CO-7) : choisis sur l'écran Dresseur, le joueur du
	# monde se rhabille aussitôt.
	if screen.has_signal(&"costume_chosen"):
		screen.costume_chosen.connect(menu.choose_costume)
	# Équipe (T8) : reliée dès que l'écran porte l'interface du §6.7 (TeamScreen du T7).
	if screen.has_signal(&"team_member_moved"):
		menu.team_shown.connect(screen.show_team)
		screen.team_member_moved.connect(menu.move_member)
		screen.team_favorite_toggled.connect(menu.toggle_favorite)
		screen.team_companion_toggled.connect(menu.toggle_companion)
		screen.team_member_selected.connect(menu.select_member)
	# Sac (T12) : relié dès que l'écran porte l'interface du §6.8 (BagScreen du T11).
	if screen.has_signal(&"bag_use_requested"):
		menu.bag_shown.connect(screen.show_bag)
		menu.bag_targets_shown.connect(screen.show_bag_targets)
		menu.bag_result_shown.connect(screen.show_bag_result)
		screen.bag_category_opened.connect(menu.open_bag_category)
		screen.bag_favorite_toggled.connect(menu.toggle_item_favorite)
		screen.bag_sort_changed.connect(menu.set_bag_sort)
		screen.bag_use_requested.connect(menu.request_item_use)
		screen.bag_target_chosen.connect(menu.use_item_on)
		screen.bag_repeat_requested.connect(menu.repeat_item_use)
	# Pokédex (T16) : relié dès que l'écran porte l'interface du §6.9 (PokedexScreen du T15).
	if screen.has_signal(&"pokedex_species_opened"):
		menu.pokedex_shown.connect(screen.show_pokedex)
		menu.pokedex_sheet_shown.connect(screen.show_pokedex_sheet)
		screen.pokedex_filter_changed.connect(menu.set_pokedex_filter)
		screen.pokedex_species_opened.connect(menu.open_species)
	# Carte (T21) : reliée dès que l'écran porte l'interface du §6.10 (MapScreen du T20).
	if screen.has_signal(&"map_zone_touched"):
		menu.map_shown.connect(screen.show_map)
		menu.map_zone_shown.connect(screen.show_map_zone)
		screen.map_zone_touched.connect(menu.open_zone)
		screen.map_region_requested.connect(menu.switch_map_region)
	# Dresseur (T25) : sans show_trainer (écran pas encore fusionné), l'écran provisoire.
	if screen.has_method(&"show_trainer"):
		menu.trainer_shown.connect(screen.show_trainer)
	else:
		menu.trainer_shown.connect(
			func(_view: TrainerView) -> void: screen.show_placeholder(MenuRoute.TRAINER))
	# Paramètres (T29) : reliés dès que l'écran porte l'interface du §6.12 (SettingsScreen du
	# T28) ; sinon l'écran provisoire reste.
	if screen.has_signal(&"setting_changed"):
		menu.save_result_shown.connect(screen.show_save_result)
		menu.settings_shown.connect(screen.show_settings)
		screen.setting_changed.connect(menu.change_setting)
		screen.save_now_requested.connect(menu.request_save)
	# Boutique (jalon-07.md §6.10) : ShopScreen du T11 (TrainerMenu), directeur du T12.
	menu.shop_shown.connect(screen.show_shop)
	menu.shop_result_shown.connect(screen.show_shop_result)
	menu.shop_confirm_requested.connect(screen.show_shop_confirm)
	screen.shop_mode_changed.connect(menu.set_shop_mode)
	screen.shop_buy_requested.connect(menu.buy)
	screen.shop_sell_requested.connect(menu.sell)
	# Stockage (jalon-07.md §6.9) : StorageScreen du T15 (TrainerMenu, fusionné avant : câblage
	# direct, comme la Boutique), directeur du T16.
	menu.storage_shown.connect(screen.show_storage)
	menu.storage_refused.connect(screen.show_storage_refusal)
	menu.storage_release_asked.connect(screen.ask_storage_release)
	screen.storage_selected.connect(menu.select_storage)
	screen.storage_deposit_requested.connect(menu.deposit_member)
	screen.storage_withdraw_requested.connect(menu.withdraw_member)
	screen.storage_favorite_toggled.connect(menu.toggle_storage_favorite)
	screen.storage_release_requested.connect(menu.request_release)
	screen.storage_release_confirmed.connect(menu.confirm_release)
	screen.storage_query_changed.connect(menu.set_storage_query)
