class_name BagScreen
extends MenuScreen
## Écran Sac du Menu Dresseur (dossier 08 §3 ; jalon-06.md §6.8 ; maquette menu-sac-v1.jpg pour
## la DA) : les catégories à gauche (FAVORIS en tête s'il y en a), les objets en cartes au
## centre (illustration, nom, quantité), l'aperçu de l'objet touché à droite.
##
## Il reçoit un [BagView] et n'en sait rien d'autre : ni Sac, ni données, ni règles. Il émet des
## intentions ; le directeur du menu les applique et rappelle [method show_bag].
## - **Un toucher = un aperçu**, jamais un usage ([signal item_previewed]). La première carte de
##   la catégorie ouverte est déjà aperçue.
## - Appui long sur une carte : [signal favorite_toggled] (étoile et texte « FAVORI »).
## - Bouton de tri toujours là : [signal sort_changed] avec le tri suivant.
## - UTILISER (ou LANCER) : [signal use_requested], seulement pour un objet utilisable ici. Un
##   objet qui ne l'est pas : aperçu avec sa mention (« Utilisable en combat »), **aucun bouton**.
## - Depuis l'Équipe (target_index >= 0) : pas de choix du Pokémon, « Pour Salamèche ».
##   Sinon [method show_targets] ouvre le [PartyPicker] dans l'écran ; [signal target_chosen]
##   n'est émis que pour une cible utilisable ; ANNULER (ou [method go_back], retour Android) le
##   referme, sans signal.
## - [method show_result] : [UseResultBar] ; [signal repeat_requested] (UTILISER À NOUVEAU).
##   Elle reste jusqu'au prochain geste de l'utilisateur.
## Composition (MM.1, maquette) : l'écran remonte dans la rangée du × et y pose son « ‹ » rond,
## l'icône du Sac et « Sac » ; l'argent passe dans le bandeau d'état de l'hôte. Catégories avec
## icône, légende et compteur ; cartes et panneaux de verre ; l'aperçu à droite montre l'objet en
## grand, puis, après UTILISER, **« Utiliser sur… » et l'équipe dans le même panneau** (le
## contrat ne change pas : UTILISER → [signal use_requested] → [method show_targets]).
## Placement : rempli par [TrainerMenu] dans la zone sous l'en-tête, marges de SAFE_MARGIN.

## Onglet touché (le directeur s'en souvient pour la session).
signal category_opened(category: StringName)
## Carte touchée : son aperçu est affiché (informatif, rien n'est utilisé).
signal item_previewed(item_id: StringName)
## Appui long sur une carte : favori à basculer.
signal favorite_toggled(item_id: StringName)
## Bouton de tri touché : [enum BagQuery.Sort] choisi.
signal sort_changed(sort: int)
## UTILISER / LANCER touché sur un objet utilisable.
signal use_requested(item_id: StringName)
## Une cible utilisable du choix du Pokémon est touchée.
signal target_chosen(item_id: StringName, index: int)
## UTILISER À NOUVEAU touché (un seul signal par toucher).
signal repeat_requested

const BACK_TEXT := "RETOUR"
const TITLE_TEXT := "Sac"
## Titres et légendes des catégories dans l'écran Sac du menu (maquette ; casse de phrase).
## Textes d'interface **à relire par Kevin** (MM.1) ; les onglets du combat gardent
## BagEntryView.CATEGORY_LABELS.
const CATEGORY_TITLES: Dictionary[StringName, String] = {
	&"favorites": "Favoris",
	&"heal": "Soins",
	&"ball": "Capture",
	&"battle": "Combat",
	&"field": "Aventure",
	# Jalon 17 (annexe A.3, validée le 2026-10-16) : les CS rejoignent l'onglet.
	&"tm": "CT et CS",
	&"key": "Objets clés",
}
const CATEGORY_CAPTIONS: Dictionary[StringName, String] = {
	&"favorites": "Tes objets favoris.",
	&"heal": "Restaure les PV et soigne les altérations.",
	&"ball": "Pour attraper les Pokémon sauvages.",
	&"battle": "Objets pour les combats.",
	&"field": "Objets utiles en exploration.",
	# Jalon 11, défaut (règle 4) : légende de l'onglet CT.
	&"tm": "Des capacités à enseigner à tes Pokémon.",
	&"key": "Objets importants.",
}
## Icône peinte d'une catégorie (l'objet qui la représente) ; sinon CATEGORY_ICONS.
const CATEGORY_PAINTED: Dictionary[StringName, StringName] = {
	&"heal": &"potion",
	&"ball": &"poke_ball",
}
const SORT_FORMAT := "Tri : %s"
const FAVORITE_TEXT := "FAVORI"
const FAVORITE_HINT := "Appui long sur une carte : favori"
const TARGET_FORMAT := "Pour %s"
const BACK_ICON: Texture2D = preload("res://assets/ui/icons/battle/back.svg")
const SORT_ICON: Texture2D = preload("res://assets/ui/icons/menu/swap.svg")
const STAR_ICON: Texture2D = preload("res://assets/ui/icons/menu/star_filled.svg")
const BAG_ICON: Texture2D = preload("res://assets/ui/icons/battle/bag.svg")
const TAB_SCENE: PackedScene = preload("res://game/ui/bag/bag_category_tab.tscn")
const CARD_SCENE: PackedScene = preload("res://game/ui/bag/bag_item_card.tscn")
const PICKER_SCENE: PackedScene = preload("res://game/ui/bag/party_picker.tscn")
## Illustration de l'onglet d'une catégorie ; le sac pour les autres.
const CATEGORY_ICONS: Dictionary[StringName, Texture2D] = {
	&"favorites": preload("res://assets/ui/icons/menu/star_filled.svg"),
	&"heal": preload("res://assets/ui/icons/items/potion.svg"),
	&"ball": preload("res://assets/ui/icons/items/poke_ball.svg"),
	&"battle": preload("res://assets/ui/icons/bag/battle.svg"),
	&"field": preload("res://assets/ui/icons/battle/bag.svg"),
	&"tm": preload("res://assets/ui/icons/battle/bag.svg"),
	&"key": preload("res://assets/ui/icons/bag/key.svg"),
}

var _view: BagView
var _open: StringName = &""
var _selected: StringName = &""
var _tabs: Dictionary[StringName, BagCategoryTab] = {}
var _cards: Array[BagItemCard] = []
var _picker_item: StringName = &""
var _pending_result: Array = []
var _detail_tween: Tween

var _back: Button
var _header_caption: Label
var _left_panel: PanelContainer
var _tabs_box: VBoxContainer
var _center_panel: PanelContainer
var _title: Label
var _caption: Label
var _sort: Button
var _scroll: ScrollContainer
var _flow: HFlowContainer
var _empty: Label
var _detail_panel: PanelContainer
var _detail_column: VBoxContainer
var _hero: HBoxContainer
var _halo: TextureRect
var _big_icon: TextureRect
var _name: Label
var _quantity: Label
var _favorite_pill: PanelContainer
var _description: Label
var _note: Label
var _hint: Label
var _action: Button
var _browse: Control
var _lower_browse: VBoxContainer
var _picker: PartyPicker
var _result: UseResultBar


func _init() -> void:
	covers_header = true
	owns_back = true
	status_money = true
	backdrop_dim = UiTokens.MENU_GLASS_DIM
	backdrop_blur = UiTokens.MENU_GLASS_BLUR
	backdrop_lod = UiTokens.MENU_GLASS_LOD


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = -UiTokens.DEX_LAYOUT_RISE
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.GAP)
	add_child(column)
	_build_header(column)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_GAP)
	column.add_child(body)
	_build_left(body)
	var zone := VBoxContainer.new()
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_GAP)
	body.add_child(zone)
	_browse = HBoxContainer.new()
	_browse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_browse.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_browse.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_GAP)
	zone.add_child(_browse)
	_build_center(_browse)
	_build_detail(_browse)
	_result = UseResultBar.new()
	_result.speed_scale = speed_scale
	_result.repeat_requested.connect(_on_repeat)
	zone.add_child(_result)
	_refresh()


## Affiche [param view]. Rappelé pendant que l'écran est affiché (après un usage, un favori, un
## tri), il met à jour **sans rejouer l'entrée** : l'onglet ouvert et l'objet aperçu sont gardés
## s'ils existent encore (sinon l'onglet d'ouverture de la vue et la première carte).
func show_bag(view: BagView) -> void:
	var keep := visible and _view != null
	var scroll := _scroll.scroll_vertical
	var wanted_category := _open
	var wanted_item := _selected
	_view = view
	if not keep:
		_close_picker_now()
		_result.clear()
		wanted_category = view.start_category
		wanted_item = &""
	_build_tabs()
	var category := wanted_category if view.categories.has(wanted_category) \
		else view.start_category
	_open_category(category, wanted_item)
	if keep:
		_scroll.scroll_vertical = scroll


## Montre le choix du Pokémon (PartyPicker) dans l'écran ; rappelé pendant qu'il est ouvert, il
## met les cartes à jour (le choix reste ouvert pour en changer).
func show_targets(view: PartyPickerView) -> void:
	_picker_item = view.item_id
	_lower_browse.visible = false
	# La place de l'équipe : la description se replie pendant le choix (nom et quantité restent).
	_description.visible = false
	_picker.speed_scale = speed_scale
	_picker.show_targets(view)


## Montre le résultat d'un usage ; UTILISER À NOUVEAU si [param can_repeat].
## Pendant que le choix du Pokémon est ouvert, le résultat attend la fin de l'animation du soin
## (barre qui remonte) : il est posé en fin d'image, une fois les cartes mises à jour.
func show_result(text: String, can_repeat: bool) -> void:
	_result.speed_scale = speed_scale
	if is_picker_open():
		_pending_result = [text, can_repeat]
		_flush_result.call_deferred()
		return
	_result.show_result(text, can_repeat)


## Retour (retour Android) : referme le choix du Pokémon s'il est ouvert. Vrai si c'est ce qui
## s'est passé (l'événement est consommé) ; faux : l'hôte revient à l'écran précédent.
func go_back() -> bool:
	if not is_picker_open():
		return false
	_close_picker()
	return true


## Le choix du Pokémon est ouvert.
func is_picker_open() -> bool:
	return _picker != null and _picker.is_shown()


## Catégorie ouverte, &"" si le Sac est vide.
func get_open_category() -> StringName:
	return _open


## Identifiant de l'objet aperçu, &"" si rien.
func get_selected_id() -> StringName:
	return _selected


## Ouvre [param category_id] (sans signal) ; sans effet si elle n'existe pas.
func open_category(category_id: StringName) -> void:
	if _view != null and _view.categories.has(category_id):
		_open_category(category_id, &"")


## Aperçoit [param item_id] de la catégorie ouverte (sans signal).
func select_item(item_id: StringName) -> void:
	for card: BagItemCard in _cards:
		if card.get_view().item_id == item_id:
			_select(item_id)
			return


func get_back_button() -> Button:
	return _back


func get_tabs() -> Dictionary[StringName, BagCategoryTab]:
	return _tabs


func get_tab(category_id: StringName) -> BagCategoryTab:
	return _tabs.get(category_id)


func get_cards() -> Array[BagItemCard]:
	return _cards


func get_card(item_id: StringName) -> BagItemCard:
	for card: BagItemCard in _cards:
		if card.get_view().item_id == item_id:
			return card
	return null


func get_sort_button() -> Button:
	return _sort


func get_action_button() -> Button:
	return _action


func get_picker() -> PartyPicker:
	return _picker


func get_result_bar() -> UseResultBar:
	return _result


## Argent de la vue (« 3 000 ₽ »), vide si absent ; il s'affiche dans le bandeau d'état de
## l'hôte (MM.1).
func get_money_text() -> String:
	return "" if _view == null else _view.money_text


func get_title_text() -> String:
	return _title.text


## Légende sous le titre (« Pour Salamèche » depuis l'Équipe), vide sinon.
func get_caption_text() -> String:
	return _header_caption.text if _header_caption.visible else ""


func get_detail_name() -> String:
	return _name.text


func get_detail_quantity() -> String:
	return _quantity.text


func get_detail_text() -> String:
	return _description.text


## Mention de l'aperçu (« Utilisable en combat », la raison), vide si aucune.
func get_detail_note() -> String:
	return _note.text if _note.visible else ""


func get_empty_label() -> Label:
	return _empty


func is_favorite_pill_shown() -> bool:
	return _favorite_pill.visible


func is_detail_shown() -> bool:
	return _detail_panel.visible


func get_scroll() -> ScrollContainer:
	return _scroll


func get_left_panel() -> PanelContainer:
	return _left_panel


func get_detail_panel() -> PanelContainer:
	return _detail_panel


## Rangée d'en-tête : « ‹ » rond (zone TOUCH_MIN), icône du Sac, « Sac » et, depuis l'Équipe,
## « Pour Salamèche ».
func _build_header(parent: Control) -> void:
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.custom_minimum_size.y = UiTokens.TOUCH_MIN
	top.add_theme_constant_override(&"separation", UiTokens.MENU_TITLE_GAP)
	parent.add_child(top)
	_back = Button.new()
	_back.theme_type_variation = &"MenuRoundButton"
	_back.icon = BACK_ICON
	_back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back.tooltip_text = BACK_TEXT
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2.ONE * UiTokens.TOUCH_MIN
	_back.pressed.connect(_on_back)
	top.add_child(_back)
	var icon := TextureRect.new()
	icon.texture = BAG_ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * UiTokens.MENU_TITLE_ICON
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(icon)
	var title := Label.new()
	title.theme_type_variation = &"MenuScreenTitle"
	title.text = TITLE_TEXT
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	_header_caption = Label.new()
	_header_caption.theme_type_variation = &"MenuScreenCount"
	_header_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header_caption.visible = false
	top.add_child(_header_caption)


func _build_left(parent: Control) -> void:
	_left_panel = PanelContainer.new()
	_left_panel.theme_type_variation = &"MenuGlass"
	_left_panel.custom_minimum_size.x = UiTokens.BAG_SCREEN_LEFT_WIDTH
	parent.add_child(_left_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left_panel.add_child(scroll)
	_tabs_box = VBoxContainer.new()
	_tabs_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tabs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs_box.add_theme_constant_override(&"separation", UiTokens.BAG_TAB_GAP)
	scroll.add_child(_tabs_box)


func _build_center(parent: Control) -> void:
	_center_panel = PanelContainer.new()
	_center_panel.theme_type_variation = &"MenuGlass"
	_center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_center_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP)
	_center_panel.add_child(column)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override(&"separation", UiTokens.GAP)
	column.add_child(header)
	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titles.add_theme_constant_override(&"separation", 0)
	header.add_child(titles)
	_title = Label.new()
	_title.theme_type_variation = &"BagTitle"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(_title)
	_caption = Label.new()
	_caption.theme_type_variation = &"MenuSubtitle"
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.visible = false
	titles.add_child(_caption)
	_sort = Button.new()
	_sort.theme_type_variation = &"MenuAction"
	_sort.icon = SORT_ICON
	_sort.focus_mode = Control.FOCUS_NONE
	_sort.custom_minimum_size = Vector2(UiTokens.BAG_SORT_WIDTH, UiTokens.TOUCH_MIN)
	_sort.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sort.pressed.connect(_on_sort)
	header.add_child(_sort)
	var divider := Panel.new()
	divider.theme_type_variation = &"BagDivider"
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.custom_minimum_size.y = UiTokens.BORDER_WIDTH
	column.add_child(divider)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		pad.add_theme_constant_override(side, UiTokens.BAG_SCROLL_PAD)
	_scroll.add_child(pad)
	_flow = HFlowContainer.new()
	_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow.add_theme_constant_override(&"h_separation", UiTokens.BAG_CARD_GAP)
	_flow.add_theme_constant_override(&"v_separation", UiTokens.BAG_CARD_GAP)
	pad.add_child(_flow)
	_empty = Label.new()
	_empty.theme_type_variation = &"BagEmpty"
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.visible = false
	column.add_child(_empty)


## Panneau de droite : l'objet en grand (illustration sur un halo, nom, « ×7 », description,
## FAVORI), sa mention ; dessous, soit l'astuce et UTILISER, soit « Utiliser sur… » et l'équipe
## (PartyPicker compact, dans le panneau).
func _build_detail(parent: Control) -> void:
	_detail_panel = PanelContainer.new()
	_detail_panel.theme_type_variation = &"MenuGlass"
	_detail_panel.custom_minimum_size.x = UiTokens.BAG_SCREEN_DETAIL_WIDTH
	parent.add_child(_detail_panel)
	_detail_column = VBoxContainer.new()
	_detail_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_column.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP)
	_detail_panel.add_child(_detail_column)
	_hero = HBoxContainer.new()
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.custom_minimum_size.y = UiTokens.BAG_HERO_MIN_HEIGHT
	_hero.add_theme_constant_override(&"separation", UiTokens.BAG_HERO_GAP)
	_detail_column.add_child(_hero)
	var art := Control.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2.ONE * UiTokens.BAG_HERO_ICON
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hero.add_child(art)
	_halo = TextureRect.new()
	_halo.texture = PokedexArt.halo_texture()
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_halo.stretch_mode = TextureRect.STRETCH_SCALE
	_halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.add_child(_halo)
	_big_icon = TextureRect.new()
	_big_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_big_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_big_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.add_child(_big_icon)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP / 2)
	_hero.add_child(texts)
	_favorite_pill = PanelContainer.new()
	_favorite_pill.theme_type_variation = &"TeamPill"
	_favorite_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_favorite_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	texts.add_child(_favorite_pill)
	var pill_row := HBoxContainer.new()
	pill_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_row.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP)
	_favorite_pill.add_child(pill_row)
	var star := TextureRect.new()
	star.texture = STAR_ICON
	star.modulate = UiTokens.ACCENT
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.custom_minimum_size = Vector2.ONE * UiTokens.BAG_STAR_ICON
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pill_row.add_child(star)
	var pill_text := Label.new()
	pill_text.theme_type_variation = &"TeamPillText"
	pill_text.text = FAVORITE_TEXT
	pill_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_row.add_child(pill_text)
	_name = _left_label(&"MenuName")
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_name)
	_quantity = _left_label(&"BagDetailQuantity")
	texts.add_child(_quantity)
	_description = _left_label(&"BagDetailText")
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_description)
	_note = _centered(&"BagNote")
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_column.add_child(_note)

	var lower := Control.new()
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_column.add_child(lower)
	_lower_browse = VBoxContainer.new()
	_lower_browse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lower_browse.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lower_browse.add_theme_constant_override(&"separation", UiTokens.BAG_SCREEN_HEADER_GAP)
	lower.add_child(_lower_browse)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lower_browse.add_child(spacer)
	_hint = _centered(&"BagHint")
	_hint.text = FAVORITE_HINT
	_lower_browse.add_child(_hint)
	_action = Button.new()
	_action.theme_type_variation = &"AccentButton"
	_action.focus_mode = Control.FOCUS_NONE
	_action.custom_minimum_size.y = UiTokens.TOUCH_MIN
	_action.pressed.connect(_on_action)
	_lower_browse.add_child(_action)
	_picker = PICKER_SCENE.instantiate() as PartyPicker
	_picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picker.speed_scale = speed_scale
	_picker.refusal_in_title = false
	_picker.target_chosen.connect(_on_target_chosen)
	_picker.target_refused.connect(_on_target_refused)
	_picker.back_requested.connect(_close_picker)
	lower.add_child(_picker)
	_picker.use_compact()


func _left_label(variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _centered(variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_FILL
	return label


func _build_tabs() -> void:
	for tab: BagCategoryTab in _tabs.values():
		_tabs_box.remove_child(tab)
		tab.queue_free()  # différé : rappelé depuis le toucher de cet onglet
	_tabs.clear()
	for category_id: StringName in _view.categories:
		var tab := TAB_SCENE.instantiate() as BagCategoryTab
		_tabs_box.add_child(tab)
		tab.use_list_layout()
		tab.use_menu_layout()
		tab.set_category(category_id, CATEGORY_TITLES.get(category_id,
			_view.category_label(category_id)), _category_icon(category_id))
		tab.set_caption(CATEGORY_CAPTIONS.get(category_id, ""))
		tab.set_count(_view.entries_in(category_id).size())
		tab.tapped.connect(_on_tab_tapped.bind(category_id))
		_tabs[category_id] = tab


## Ouvre [param category_id] : ses cartes, l'objet [param wanted] aperçu s'il y est (sinon le
## premier).
func _open_category(category_id: StringName, wanted: StringName) -> void:
	_open = category_id
	for id: StringName in _tabs:
		_tabs[id].set_selected(id == category_id)
	_rebuild_cards()
	var first := &""
	var found := false
	for card: BagItemCard in _cards:
		var id := card.get_view().item_id
		first = id if first.is_empty() else first
		found = found or id == wanted
	_select(wanted if found else first)


func _rebuild_cards() -> void:
	for card: BagItemCard in _cards:
		_flow.remove_child(card)
		card.queue_free()  # différé : rappelé depuis le toucher de cette carte
	_cards.clear()
	if _open.is_empty():
		return
	for entry: BagEntryView in _view.entries_in(_open):
		var card := CARD_SCENE.instantiate() as BagItemCard
		_flow.add_child(card)
		card.use_menu_style()
		card.set_view(entry)
		card.long_press_enabled = true
		card.tapped.connect(_on_card_tapped.bind(entry.item_id))
		card.long_pressed.connect(_on_card_long_pressed.bind(entry.item_id))
		_cards.append(card)
	_scroll.scroll_vertical = 0


func _select(item_id: StringName) -> void:
	_selected = item_id
	for card: BagItemCard in _cards:
		card.set_selected(card.get_view().item_id == item_id)
	_refresh()


## Remet les textes, l'aperçu et les boutons à jour pour la vue et l'objet aperçu.
func _refresh() -> void:
	var empty := _view == null or _view.is_empty()
	_left_panel.visible = not empty
	_detail_panel.visible = not empty
	_center_panel.visible = true
	_scroll.visible = not empty
	_sort.visible = not empty
	_empty.visible = empty
	_empty.text = "" if _view == null else _view.empty_text
	_title.text = TITLE_TEXT if empty else CATEGORY_TITLES.get(_open,
		BagEntryView.category_label(_open))
	var target_name := "" if _view == null else _view.target_name
	# « Pour Salamèche » : dans la rangée d'en-tête seulement (MM.1), pas deux fois.
	_caption.text = TARGET_FORMAT % target_name
	_caption.visible = false
	_header_caption.text = _caption.text
	_header_caption.visible = not target_name.is_empty()
	if empty:
		return
	if not _view.sort_labels.is_empty():
		var index := clampi(_view.sort, 0, _view.sort_labels.size() - 1)
		_sort.text = SORT_FORMAT % _view.sort_labels[index]
	var entry := _selected_entry()
	_detail_column.visible = entry != null
	if entry == null:
		return
	_big_icon.texture = entry.get_icon()
	_name.text = entry.display_name
	_quantity.text = entry.quantity_text()
	_description.text = entry.description
	_description.visible = not entry.description.is_empty() and not is_picker_open()
	_note.text = entry.note
	_note.visible = not entry.note.is_empty()
	_favorite_pill.visible = entry.favorite
	_action.visible = entry.usable
	_action.text = entry.action_label
	_flash_detail()


func _selected_entry() -> BagEntryView:
	if _view == null:
		return null
	for entry: BagEntryView in _view.entries:
		if entry.item_id == _selected:
			return entry
	return null


func _flash_detail() -> void:
	if _detail_tween != null:
		_detail_tween.kill()
		_detail_tween = null
	_hero.modulate.a = 1.0
	var time := UiTokens.ANIM_MICRO * speed_scale
	if time <= 0.0 or not is_inside_tree():
		return
	_hero.modulate.a = UiTokens.BAG_DETAIL_FADE_FROM
	_detail_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_detail_tween.tween_property(_hero, ^"modulate:a", 1.0, time)


func _close_picker() -> void:
	if not is_picker_open():
		return
	_lower_browse.visible = true
	_description.visible = not _description.text.is_empty()
	_picker.slide_out()


func _close_picker_now() -> void:
	_lower_browse.visible = true
	_description.visible = not _description.text.is_empty()
	if _picker != null and _picker.is_shown():
		_picker.speed_scale = 0.0
		_picker.slide_out()
		_picker.speed_scale = speed_scale


func _category_icon(category_id: StringName) -> Texture2D:
	var painted := MenuArt.item_icon(CATEGORY_PAINTED.get(category_id, &""))
	if painted != null:
		return painted
	return CATEGORY_ICONS.get(category_id, BagEntryView.GENERIC_ICON)


func _haptic(duration_ms: int) -> void:
	Haptics.vibrate(duration_ms)


func _on_tab_tapped(category_id: StringName) -> void:
	_result.clear()
	if category_id == _open:
		return
	_open_category(category_id, &"")
	_haptic(UiTokens.HAPTIC_TICK_MS)
	category_opened.emit(category_id)


func _on_card_tapped(item_id: StringName) -> void:
	_result.clear()
	if item_id != _selected:
		_select(item_id)
	_haptic(UiTokens.HAPTIC_TICK_MS)
	item_previewed.emit(item_id)


func _on_card_long_pressed(item_id: StringName) -> void:
	_result.clear()
	_haptic(UiTokens.HAPTIC_BAG_FAVORITE_MS)
	favorite_toggled.emit(item_id)


func _on_sort() -> void:
	if _view == null or _view.sort_labels.is_empty():
		return
	_result.clear()
	_haptic(UiTokens.HAPTIC_TICK_MS)
	sort_changed.emit((_view.sort + 1) % _view.sort_labels.size())


func _on_action() -> void:
	var entry := _selected_entry()
	if entry == null or not entry.usable:
		return
	_result.clear()
	_haptic(UiTokens.HAPTIC_TAP_MS)
	use_requested.emit(entry.item_id)


func _flush_result() -> void:
	if _pending_result.is_empty():
		return
	if _picker != null and _picker.is_healing():
		if not _picker.heal_finished.is_connected(_flush_result):
			_picker.heal_finished.connect(_flush_result, CONNECT_ONE_SHOT)
		return
	var pending := _pending_result
	_pending_result = []
	_result.show_result(pending[0] as String, pending[1] as bool)


## Cible refusée : la carte a tremblé ; la raison s'affiche en style refus dans la barre de
## résultat (rien n'est consommé, aucun target_chosen).
func _on_target_refused(_index: int, text: String) -> void:
	_pending_result = []
	if text.is_empty():
		return
	_result.speed_scale = speed_scale
	_result.show_result(text, false)


func _on_target_chosen(index: int) -> void:
	_pending_result = []
	_result.clear()
	target_chosen.emit(_picker_item, index)


func _on_repeat() -> void:
	repeat_requested.emit()


func _on_back() -> void:
	if go_back():
		return
	back_requested.emit()
