extends SceneTree
## Outil de vérification visuelle du HUD d'exploration (Movie Maker) : lance game/boot.tscn.
##
##   godot --path . --always-on-top --write-movie build/cap/f.png --fixed-fps 30 \
##     --quit-after 150 -s res://tools/capture_hud.gd [-- --scenario=<nom> --out=build/captures]
##
## Taille de fenêtre : utiliser un override.cfg temporaire (2340×1080), voir capture_play.gd.
## Le script affiche « CAPTURE <nom> frame=<n> » : image Movie Maker à conserver.
## Avec « -- --out=build/captures », il enregistre aussi la texture du viewport sous
## <out>/<nom>.png (utile sans Movie Maker : --fixed-fps 30 seul garde un temps déterministe ;
## --always-on-top est nécessaire : sur Mac, une fenêtre masquée par une autre n'est plus
## dessinée et Movie Maker répète alors la dernière image (titre « figé »).
##
## Scénario « hud » (défaut, Bourg Palette, 30 images/s) :
##   hud_zone_title   titre de zone pendant son maintien (~1 s)
##   hud_after_title  après sa disparition (~3,7 s)
##   hud_joystick     doigt 0 posé dans la moitié gauche puis glissé vers la droite
##   hud_run_pressed  en plus, doigt 1 tenu sur le bouton courir
## Les touchers passent par Input.parse_input_event, comme sur le téléphone (la souris
## émulée depuis le toucher est donc aussi générée, et doit être ignorée).
##
## Jalon 3A (T2) : boîte de dialogue et bouton contextuel, pilotés directement (le câblage
## vient en T3 ; la boîte de Boot est utilisée si elle existe, sinon une est ajoutée).
## Le texte s'écrit à DIALOG_CHARS_PER_SECOND comme en jeu. --quit-after 200 suffit.
##   dialog_house   rez-de-chaussée (intérieur clair) :
##                    jalon03_interact_examine   bouton EXAMINER + courir
##                    jalon03_dialog_typing      « Maman », texte en cours d'écriture
##                    jalon03_dialog_maman       page complète, « › »
##                    jalon03_dialog_narration   narration sans nom, italique
##   dialog_town    Bourg Palette (après le titre) :
##                    jalon03_interact_talk      bouton PARLER + courir
##                    jalon03_dialog_town        « Mme Aoki », page complète, « › »
##   interact_lab   labo (intérieur clair) :
##                    jalon03_interact_observe   bouton OBSERVER + courir
##                    jalon03_interact_take      bouton PRENDRE (prévu, sans données en 3A)
##
## Jalon 4A (T2) : RENCONTRER, légende et fiche du starter, sur le vrai labo. Chen et le rival
## sont présents (oak_met), le joueur est placé sous chaque starter, face à lui, avec la
## surcharge « Rencontrer » que posera StarterChoice (T3) : le bouton passe par le vrai
## câblage (InteractionController → Boot → HUD). Textes lus dans data/pokemon/ (noms,
## types, phrases, légende) ; la fiche est pilotée comme le fera StarterChoice (contrôles
## cachés, Pokémon qui s'avance, open(view)). --quit-after 700 suffit ; le script quitte seul.
##   starter_lab   labo :
##                   jalon04a_t2_caption_meet     légende pendant sa tenue + RENCONTRER
##                   jalon04a_t2_meet_button      RENCONTRER seul, légende effacée
##                   jalon04a_t2_sheet_<espèce>   fiche ouverte (×3)
##                   jalon04a_t2_sheet_slide      fiche de Salamèche en cours d'entrée
##                   jalon04a_t2_sheet_pressed    CHOISIR enfoncé (doigt posé)

const BOOT_SCENE: String = "res://game/boot.tscn"
const BOX_SCENE: String = "res://game/ui/dialogue/dialogue_box.tscn"
## Carte et point d'apparition de chaque scénario.
const SCENARIO_MAPS: Dictionary = {
	"hud": [&"pallet_town", &"start"],
	"dialog_house": [&"player_house_1f", &"stairs"],
	"dialog_town": [&"pallet_town", &"start"],
	"interact_lab": [&"oak_lab", &"entrance"],
	"starter_lab": [&"oak_lab", &"entrance"],
}
## Données lues par le scénario starter_lab (l'outil peut lire les données, pas game/ui/).
const STARTERS_PATH: String = "res://data/pokemon/starters.json"
const SPECIES_PATH: String = "res://data/pokemon/species/kanto.json"
const TYPES_PATH: String = "res://data/pokemon/types.json"
const INTERACTION_SCRIPT: String = "res://game/world/interactions/interaction.gd"
const VIEW_SCRIPT: String = "res://game/ui/starter/starter_sheet_view.gd"
## Rangée du joueur devant la table (jalon-04.md §13.2).
const TABLE_FRONT_ROW: int = 6
const THUMB_START := Vector2(430, 790)
const THUMB_SWIPE := Vector2(95, 6)
## tools/ n'est pas importé : les tokens sont chargés explicitement.
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"

var _boot: Node
var _frame: int = 0
var _out_dir: String = ""
var _scenario: String = "hud"
var _tokens: GDScript
var _hud: CanvasLayer
var _box: CanvasLayer
## Écriture du texte : caractères visibles (flottant) et longueur de la page, -1 = rien.
var _typed: float = -1.0
var _page_length: int = 0
## Image → nom : la texture du viewport est lue à l'image suivante (celle de la marque).
var _pending_shots: Dictionary[int, String] = {}
## Centre du bouton courir depuis le coin bas-droit.
var _run_from_corner: Vector2


func _init() -> void:
	# La fenêtre de capture prend le focus : on coupe le clavier pour que seules les
	# entrées tactiles injectées pilotent le joueur.
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--scenario="):
			_scenario = arg.trim_prefix("--scenario=")
	if not SCENARIO_MAPS.has(_scenario):
		push_error("capture_hud : scénario inconnu « %s »" % _scenario)
		quit(1)
		return
	_tokens = load(TOKENS_PATH) as GDScript
	_run_from_corner = _tokens.RUN_BUTTON_CENTER_FROM_CORNER
	# Les autoloads (SceneRouter, utilisé par Boot) ne sont ajoutés qu'après _init.
	process_frame.connect(_start_boot, CONNECT_ONE_SHOT)


func _start_boot() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	# Depuis le jalon 2, le jeu démarre dans la chambre (sans titre) : on part du village.
	var start: Array = SCENARIO_MAPS[_scenario]
	_boot.set(&"start_map", start[0])
	_boot.set(&"start_spawn", start[1])
	root.add_child(_boot)
	_hud = _boot.call(&"get_hud")
	_box = _boot.get_node_or_null(^"%DialogueBox") as CanvasLayer
	if _box == null:
		_box = (load(BOX_SCENE) as PackedScene).instantiate() as CanvasLayer
		root.add_child(_box)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	_save_pending_shot()
	_type_text()
	match _scenario:
		"hud":
			_run_hud()
		"dialog_house":
			_run_dialog_house()
		"dialog_town":
			_run_dialog_town()
		"interact_lab":
			_run_interact_lab()
		"starter_lab":
			if _frame == 1:
				_run_starter_lab()


func _run_dialog_house() -> void:
	match _frame:
		30:
			_hud.call(&"show_interact", &"examine")
		45:
			_mark("jalon03_interact_examine")
		50:
			_open_dialog("Maman", "Bonjour ! Tu es enfin réveillé ?", false)
		64:
			_mark("jalon03_dialog_typing")
		100:
			_mark("jalon03_dialog_maman")
		110:
			_show_page("", "Ton petit-déjeuner est encore chaud.", true)
		150:
			_mark("jalon03_dialog_narration")
		160:
			_box.call(&"close")
		185:
			quit()


func _run_dialog_town() -> void:
	match _frame:
		115:
			_hud.call(&"show_interact", &"talk")
		130:
			_mark("jalon03_interact_talk")
		135:
			_open_dialog("Mme Aoki", "Ils reviennent tous les matins.", false)
		175:
			_mark("jalon03_dialog_town")
		185:
			quit()


func _run_interact_lab() -> void:
	match _frame:
		30:
			_hud.call(&"show_interact", &"observe")
		45:
			_mark("jalon03_interact_observe")
		50:
			_hud.call(&"show_interact", &"take")
		65:
			_mark("jalon03_interact_take")
		70:
			quit()


func _run_starter_lab() -> void:
	await _frames(5)
	var state: Node = root.get_node(^"GameState")
	var flags: RefCounted = state.get(&"flags")
	flags.call(&"set_flag", &"oak_met")
	var lab: Node = _boot.call(&"get_map")
	lab.call(&"refresh_npcs", flags)
	var starters: Dictionary = _read_json(STARTERS_PATH)
	var species: Dictionary = _read_json(SPECIES_PATH)
	var types: Dictionary = _read_json(TYPES_PATH)["types"]
	var interaction_script: GDScript = load(INTERACTION_SCRIPT)
	var meet: int = interaction_script.get(&"Kind")["MEET"]
	var npcs: Array[Node] = []
	for choice: Dictionary in starters["choices"]:
		var npc: Node = lab.call(&"get_npc", StringName(choice["npc"]))
		npc.call(&"set_interaction_override", interaction_script.new(
			meet, npc.call(&"get_cell"), &"", Vector2i.ZERO, npc))
		npcs.append(npc)
	var sheet: CanvasLayer = _boot.get_node(^"%StarterSheet")
	var choices: Array = starters["choices"]
	# Légende + RENCONTRER devant Salamèche.
	await _stand_below(lab, npcs[1])
	_hud.call(&"show_caption", starters["prompt"])
	await _frames(30)
	_mark("jalon04a_t2_caption_meet")
	await _frames(2)
	await _wait_until(func() -> bool: return not _hud.get_caption().visible, 200)
	await _frames(5)
	_mark("jalon04a_t2_meet_button")
	await _frames(2)
	for i: int in choices.size():
		var choice: Dictionary = choices[i]
		var npc: Node = npcs[i]
		await _stand_below(lab, npc)
		var entry: Dictionary = species[choice["species"]]
		var ids: Array[StringName] = []
		var names: Array[String] = []
		for type_id: String in entry["types"]:
			ids.append(StringName(type_id))
			names.append(types[type_id]["name"])
		var view: RefCounted = (load(VIEW_SCRIPT) as GDScript).new(
			entry["name"], ids, names, choice["blurb"])
		_hud.call(&"set_controls_visible", false)
		npc.call(&"lean_toward", _player_cell())
		await _frames(6)
		sheet.call(&"open", view)
		if i == 1:
			await _frames(4)
			_mark("jalon04a_t2_sheet_slide")
			await _frames(2)
		await _frames(20)
		_mark("jalon04a_t2_sheet_" + String(choice["species"]))
		await _frames(2)
		if i == 1:
			var choose: Button = sheet.call(&"get_choose_button")
			var center := choose.get_global_rect().get_center()
			_touch(0, center, true)
			await _frames(8)
			_mark("jalon04a_t2_sheet_pressed")
			await _frames(2)
			_touch(0, center, false)
			await _frames(2)
		sheet.call(&"close")
		npc.call(&"settle")
		await _frames(12)
		_hud.call(&"set_controls_visible", true)
	await _frames(3)
	print("STARTER_LAB terminé (frame %d)" % _frame)
	quit()


## Place le joueur sous [param npc] (rangée devant la table), tourné vers lui.
func _stand_below(lab: Node, npc: Node) -> void:
	var cell: Vector2i = npc.call(&"get_cell")
	var player: Node = _boot.call(&"get_player")
	player.call(&"enter_map", lab.call(&"get_grid"), Vector2i(cell.x, TABLE_FRONT_ROW),
		Vector2i.UP, lab.call(&"get_pixel_rect"))
	await _frames(15)


func _player_cell() -> Vector2i:
	return (_boot.call(&"get_player") as Node).call(&"get_cell")


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _wait_until(done: Callable, limit: int) -> void:
	for i: int in limit:
		if done.call():
			return
		await process_frame


func _read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


## Comme en jeu (T3) : contrôles cachés, boîte ouverte, première page qui s'écrit.
func _open_dialog(speaker: String, text: String, narration: bool) -> void:
	_hud.call(&"hide_interact")
	_hud.call(&"set_controls_visible", false)
	_box.call(&"open")
	_show_page(speaker, text, narration)


func _show_page(speaker: String, text: String, narration: bool) -> void:
	_box.call(&"show_page", speaker, text, narration)
	_typed = 0.0
	_page_length = text.length()


## Écrit la page à DIALOG_CHARS_PER_SECOND, puis montre « › » (sauf narration finale).
func _type_text() -> void:
	if _typed < 0.0:
		return
	_typed += _tokens.DIALOG_CHARS_PER_SECOND / 30.0
	if _typed < _page_length:
		_box.call(&"set_visible_characters", int(_typed))
		return
	_typed = -1.0
	_box.call(&"set_visible_characters", -1)
	_box.call(&"set_continue_visible", not bool(_box.call(&"is_narration")))


func _run_hud() -> void:
	match _frame:
		30:
			_mark("hud_zone_title")
		112:
			_mark("hud_after_title")
		115:
			_touch(0, THUMB_START, true)
		116, 117, 118, 119, 120:
			var t := (_frame - 115) / 5.0
			_drag(0, THUMB_START + THUMB_SWIPE * t)
		128:
			_mark("hud_joystick")
		130:
			_touch(1, root.get_visible_rect().size - _run_from_corner, true)
		136:
			_mark("hud_run_pressed")
		140:
			_touch(1, root.get_visible_rect().size - _run_from_corner, false)
			_touch(0, THUMB_START + THUMB_SWIPE, false)


func _mark(capture_name: String) -> void:
	var player: Node2D = _boot.call(&"get_player")
	print("CAPTURE %s frame=%d cell=%s right=%s run=%s viewport=%s" % [
		capture_name, _frame, player.call(&"get_cell"),
		Input.is_action_pressed(&"move_right"), Input.is_action_pressed(&"run"),
		root.get_visible_rect().size,
	])
	if not _out_dir.is_empty():
		_pending_shots[_frame + 1] = capture_name


func _save_pending_shot() -> void:
	if not _pending_shots.has(_frame):
		return
	var capture_name: String = _pending_shots[_frame]
	_pending_shots.erase(_frame)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(_out_dir.path_join(capture_name + ".png"))


func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	Input.parse_input_event(event)


func _drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	Input.parse_input_event(event)
