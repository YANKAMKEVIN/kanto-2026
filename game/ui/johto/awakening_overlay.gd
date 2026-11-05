class_name AwakeningOverlay
extends TmLearnOverlay
## Le Réveil à l'écran (JOHP0, `jalon-joh-pierres.md` §2.3 ; dossier JOH-11 §13.2) : le moment fort
## du chapitre. Deux coroutines, séparées par l'écriture de l'étape « stones_awaken » :
##
## [codeblock]
## await film(report, lines)       # silence, lumière, un plan par Pokémon, plan large, P-31
##   (l'étape écrit ici ; l'image reste en place)
## var learned := await review(report, prompt)   # l'écran du Réveil, puis fermeture
## [/codeblock]
##
## [b]Le film[/b] (≈ 60 à 90 s avec six Pokémon, [method film_seconds]) n'a ni question, ni
## annulation, ni accélération : rien ne le passe. Il ne lit ni n'écrit la partie : tout vient du
## bilan [AwakeningReport] (l'état est déjà à jour) et il ne compose aucun texte d'histoire (les
## lignes viennent des données). L'écran du Réveil montre une ligne par Pokémon ; toucher une ligne
## propose ses attaques par le déroulé existant ([method MoveLearnPrompt.teach]) ; CONTINUER à
## tout moment : rien n'est imposé. Le retour Android est avalé du début à la fin.
##
## Le son n'est pas ici : l'écran émet ses repères et [AudioBridge] joue. Durées multipliées par
## [member speed_scale] (0 = instantané, tests ; « Réduire les animations » : facteur du combat).
## « Réduire les flashs » : [member reduce_flashes]. Visuels provisoires (règle 3).

## La musique doit se taire net : le film commence.
signal silence_requested
## Un battement sourd, de [param strength] 0 à 1.
signal heartbeat(strength: float)
## La lumière sort : le thème commence à voix basse.
signal theme_started
## Le plan large : le thème éclate.
signal theme_burst
## Une Ball s'ouvre.
signal ball_opened
## Cri de [param species].
signal cry_requested(species: StringName)
## Le compteur vient de passer à [param level].
signal level_ticked(level: int)
## Le Pokémon vient de changer d'espèce à l'écran.
signal evolved_on_screen(species: StringName)
## L'écran du Réveil se ferme (fin de [method review]).
signal _review_closed

enum Phase { IDLE, SILENCE, LIGHT, TEAM, LINE_UP, REVIEW }

const LIGHT_SHADER: Shader = preload("res://game/ui/johto/awakening_light.gdshader")
const ART_SHADER: Shader = preload("res://game/ui/johto/awakening_art.gdshader")

## Les trois couleurs des pierres (dossier §13.2) : la terre, la mer, le ciel **[D]**.
const STONE_COLORS: Array[Color] = [
	Color(0.72, 0.66, 0.58), Color(0.25, 0.55, 1.0), Color(1.0, 1.0, 1.0),
]
const NIGHT := Color(0.03, 0.05, 0.10)

# Le silence : voile, puis des battements de plus en plus forts et de plus en plus rapprochés.
const SHADE_ALPHA := 0.62
const SHADE_TIME := 1.2
const BEAT_GAPS: Array[float] = [1.4, 1.2, 1.0, 0.8, 0.6, 0.45]
const BEAT_SHAKE := 9.0
const BEAT_TIME := 0.22
const STONE_SPREAD := 130.0
const STONE_SIZE := 170.0
const STONE_CENTER_Y := 470.0
const STONE_TREMBLE := 3.5
# La lumière.
const JOIN_TIME := 1.0
const LIGHT_TIME := 4.2
const LIGHT_HOLD := 0.8
const LIGHT_PEAK := 1.3
const LIGHT_TEAM := 0.34
const LIGHT_LINE_UP := 0.5
# Un plan par Pokémon.
const ART_SIZE := 660.0
const ART_CENTER_Y := 430.0
const ART_RISE := 90.0
const ART_FROM := 0.55
const GLOW_SIZE := 1180.0
const RING_SIZE := 1100.0
const ENTER_TIME := 1.0
const COUNTER_TIME := 4.0
## Équipe de 3 ou moins : le plan dure un peu plus, la scène garde son poids.
const COUNTER_SMALL_TEAM := 5.0
const SMALL_TEAM := 3
const COUNT_MIN_TIME := 0.3
const STAGE_PAUSE := 0.3
const STAGE_RISE := 0.25
const STAGE_FLASH := 0.12
const STAGE_FALL := 0.55
const HOLD_TIME := 1.3
const EXIT_TIME := 0.45
const COUNTER_TOP := 846.0
const COUNTER_FONT := 104
const COUNTER_FORMAT := "Niv. %d"
const FLASH_ALPHA := 0.95
const FLASH_REDUCED_ALPHA := 0.3
const LAND_HAPTIC_MS := 30
# Le plan large.
const LINE_UP_TIME := 1.0
const LINE_UP_SLOT := 300.0
const LINE_UP_HEIGHT := 400.0
const LINE_UP_BOTTOM := 800.0
const LINE_TOP := 860.0
const LINE_FONT := 40
const LINE_READ := 3.4
const LINE_FADE := 0.4
const STORED_READ := 2.0
const MOTES_LOW := 40
const MOTES_HIGH := 90
# L'écran du Réveil **[D]** (textes de système, comme le choix des 6).
const REVIEW_TITLE := "Le Réveil"
const CONTINUE_TEXT := "CONTINUER"
const ROW_LEVELS := "Niv. %d → %d"
const ROW_EVOLVED := "%s → %s"
const ROW_MOVES_ONE := "1 attaque à voir"
const ROW_MOVES := "%d attaques à voir"
const ROW_SEPARATOR := "   ·   "
const PANEL_SIZE := Vector2(1640, 900)
const PANEL_FADE := 0.35
const ROW_HEIGHT := 150
const ROW_COLUMNS := 2

## Multiplie toutes les durées (posé par Boot) ; 0 = instantané.
var speed_scale: float = 1.0
## « Réduire les flashs » (Paramètres).
var reduce_flashes: bool = false

var _data: PokemonData
var _battle_art: BattleArt
var _phase: Phase = Phase.IDLE
var _base: ColorRect
var _shade: ColorRect
var _light: ColorRect
var _light_material: ShaderMaterial
var _stage: Control
var _stones: Array[TextureRect] = []
var _stones_active: bool = false
var _motes: CPUParticles2D
var _rays: EvolutionRays
var _glow: TextureRect
var _ring: TextureRect
var _art: TextureRect
var _art_material: ShaderMaterial
var _art_top: float = 0.0
var _line_up: Control
var _counter: Label
var _line: Label
var _flash: ColorRect
var _panel: PanelContainer
var _rows: GridContainer
var _stored_line: Label
var _continue: Button
var _row_buttons: Array[Button] = []
var _row_results: Array[AwakeningResult] = []
## Attaques encore à voir, par Pokémon (identité du bilan → liste).
var _pending: Dictionary[AwakeningResult, Array] = {}
var _prompt: MoveLearnPrompt
var _teaching: bool = false
var _learned: bool = false
var _spin: float = 0.0
var _level_shown: int = 0
var _stones_time: float = 0.0


func _ready() -> void:
	super()
	layer = UiTokens.LAYER_EVOLUTION
	_veil.visible = false
	_build_film()
	_build_review()
	set_process(false)


func _process(delta: float) -> void:
	_rays.rotation = fposmod(_rays.rotation + _spin * delta, TAU)
	_light_material.set_shader_parameter(&"aspect", _aspect())
	if _stones_active:
		_stones_time += delta
		for i: int in _stones.size():
			var wobble := Vector2(sin(_stones_time * 41.0 + i), cos(_stones_time * 37.0 + i * 2.0))
			_stones[i].get_child(0).position = wobble * STONE_TREMBLE


## Espèces (noms) et images. [param art] : celui de Boot ; null : lecture partagée.
func setup(data: PokemonData, art: BattleArt = null) -> void:
	_data = data
	_battle_art = art if art != null else BattleArt.new()


## Durée du film de [param report] à vitesse normale.
static func film_seconds(report: AwakeningReport) -> float:
	var total := 0.0
	for gap: float in BEAT_GAPS:
		total += gap
	total += JOIN_TIME + LIGHT_TIME + LIGHT_HOLD
	for result: AwakeningResult in report.party:
		total += _plan_seconds(result, report.party.size())
	total += LINE_UP_TIME + 2.0 * (LINE_READ + LINE_FADE)
	if not report.stored.is_empty():
		total += STORED_READ
	return total


static func _plan_seconds(result: AwakeningResult, team: int) -> float:
	return ENTER_TIME + _counter_seconds(team) + HOLD_TIME + EXIT_TIME \
		+ result.chain.size() * (STAGE_PAUSE + STAGE_RISE + STAGE_FLASH + STAGE_FALL)


static func _counter_seconds(team: int) -> float:
	return COUNTER_SMALL_TEAM if team <= SMALL_TEAM else COUNTER_TIME


## Coroutine : le film. [param lines] : les lignes de P-31, une par écran ; [param stored_line] :
## l'annonce des captures du Stockage ("" : aucune). L'image reste en place à la fin : elle couvre
## l'écriture et sert de fond à [method review].
func film(report: AwakeningReport, lines: Array[String], stored_line: String = "") -> void:
	_reset()
	open()
	set_process(true)
	await _play_silence()
	await _play_light()
	_phase = Phase.TEAM
	var count := report.party.size()
	for i: int in count:
		await _play_pokemon(report.party[i], i, count)
	await _play_line_up(report, lines, stored_line)


## Coroutine : l'écran du Réveil puis la fermeture ; vrai si une attaque a été apprise.
func review(report: AwakeningReport, prompt: MoveLearnPrompt) -> bool:
	_phase = Phase.REVIEW
	_prompt = prompt
	_learned = false
	_teaching = false
	_fill_review(report)
	_line.visible = false
	_fade(_line_up, 0.0, PANEL_FADE)
	_veil.visible = true
	_panel.visible = true
	_panel.modulate.a = 0.0
	_fade(_panel, 1.0, PANEL_FADE)
	await _review_closed
	if _prompt != null:
		_prompt.release()
	_prompt = null
	_fade(_root, 0.0, PANEL_FADE)
	await _wait(PANEL_FADE)
	set_process(false)
	_motes.emitting = false
	_phase = Phase.IDLE
	close()
	return _learned


## Retour Android : avalé tant que le Réveil est à l'écran.
func handle_back() -> bool:
	return is_open()


func get_phase() -> Phase:
	return _phase


func get_counter_text() -> String:
	return _counter.text


func get_line_text() -> String:
	return _line.text


func get_row_buttons() -> Array[Button]:
	return _row_buttons.duplicate()


func get_continue_button() -> Button:
	return _continue


func get_stored_text() -> String:
	return _stored_line.text if _stored_line.visible else ""


## Silhouettes du plan large (tests).
func get_line_up_size() -> int:
	return _line_up.get_child_count()


func get_light_power() -> float:
	return float(_light_material.get_shader_parameter(&"power"))


func get_art_texture() -> Texture2D:
	return _art.texture


# --- Le silence ------------------------------------------------------------------------------


func _play_silence() -> void:
	_phase = Phase.SILENCE
	silence_requested.emit()
	_fade(_shade, SHADE_ALPHA, SHADE_TIME)
	_stones_active = true
	for stone: TextureRect in _stones:
		stone.modulate.a = 0.0
		_fade(stone, 0.55, SHADE_TIME)
	var count := BEAT_GAPS.size()
	for i: int in count:
		await _wait(BEAT_GAPS[i])
		_beat(float(i + 1) / float(count))


## Un battement : son, vibration, les pierres grossissent, l'image tressaute.
func _beat(strength: float) -> void:
	heartbeat.emit(strength)
	Haptics.vibrate(roundi(lerpf(12.0, 40.0, strength)))
	if speed_scale <= 0.0:
		return
	for stone: TextureRect in _stones:
		stone.scale = Vector2.ONE * (1.0 + 0.35 * strength)
		stone.modulate.a = minf(1.0, 0.55 + 0.45 * strength)
		_anim(stone, ^"scale", Vector2.ONE, BEAT_TIME * 2.0, Tween.EASE_OUT)
	_stage.position.y = BEAT_SHAKE * strength
	_anim(_stage, ^"position:y", 0.0, BEAT_TIME, Tween.EASE_OUT)


# --- La lumière ------------------------------------------------------------------------------


func _play_light() -> void:
	_phase = Phase.LIGHT
	# Les trois pierres se rejoignent, le thème naît à voix basse.
	theme_started.emit()
	for stone: TextureRect in _stones:
		_anim(stone, ^"position", _stone_home(-1), JOIN_TIME, Tween.EASE_IN)
	await _wait(JOIN_TIME)
	_stones_active = false
	_motes.emitting = true
	_tween_power(LIGHT_PEAK, LIGHT_TIME, Tween.EASE_IN)
	_fade(_base, 1.0, LIGHT_TIME)
	for stone: TextureRect in _stones:
		_fade(stone, 0.0, LIGHT_TIME * 0.5)
	await _wait(LIGHT_TIME + LIGHT_HOLD)
	_shade.modulate.a = 0.0
	_tween_power(LIGHT_TEAM, ENTER_TIME, Tween.EASE_OUT)


# --- L'équipe, un par un ---------------------------------------------------------------------


func _play_pokemon(result: AwakeningResult, index: int, team: int) -> void:
	var tint: Color = STONE_COLORS[index % STONE_COLORS.size()]
	var center_top := _art_top
	_show_species(_art, result.species_before)
	_set_white(1.0)
	_art.scale = Vector2.ONE * ART_FROM
	_art.position.y = center_top + ART_RISE
	_art.modulate.a = 0.0
	_glow.self_modulate = tint
	_rays.self_modulate = tint
	_ring.self_modulate = tint
	_level_shown = result.level_before
	_counter.text = COUNTER_FORMAT % result.level_before
	_counter.modulate.a = 0.0
	# La Ball s'ouvre : l'onde part, la silhouette se relève dans la lumière.
	ball_opened.emit()
	_burst_ring()
	_fade(_glow, 0.75, ENTER_TIME)
	_fade(_rays, 0.5, ENTER_TIME)
	_spin = 0.25
	_fade(_art, 1.0, ENTER_TIME * 0.5)
	_anim(_art, ^"position:y", center_top, ENTER_TIME, Tween.EASE_OUT, Tween.TRANS_BACK)
	_anim(_art, ^"scale", Vector2.ONE, ENTER_TIME, Tween.EASE_OUT, Tween.TRANS_BACK)
	await _wait(ENTER_TIME * 0.5)
	cry_requested.emit(result.species_before)
	_tween_white(0.0, ENTER_TIME * 0.5)
	_fade(_counter, 1.0, ENTER_TIME * 0.5)
	await _wait(ENTER_TIME * 0.5)
	# Le compteur défile, palier par palier.
	var time := _counter_seconds(team)
	var span := maxi(1, result.level_after - result.level_before)
	var from := result.level_before
	for i: int in result.chain.size():
		var at: int = result.stage_levels[i]
		await _count(from, at, time * float(at - from) / float(span))
		await _play_stage(result.chain[i])
		from = at
	await _count(from, result.level_after, time * float(result.level_after - from) / float(span))
	# Arrivé : le Pokémon se pose.
	Haptics.vibrate(LAND_HAPTIC_MS)
	_burst_ring()
	_art.scale = Vector2.ONE * 1.05
	_anim(_art, ^"scale", Vector2.ONE, HOLD_TIME * 0.5, Tween.EASE_OUT, Tween.TRANS_BACK)
	_fade(_rays, 0.8, HOLD_TIME * 0.4)
	_spin = 0.6
	await _wait(HOLD_TIME)
	_fade(_art, 0.0, EXIT_TIME)
	_fade(_counter, 0.0, EXIT_TIME)
	_fade(_glow, 0.0, EXIT_TIME)
	_fade(_rays, 0.0, EXIT_TIME)
	await _wait(EXIT_TIME)


## Coroutine : le compteur va de [param from] à [param to] en [param time] secondes.
func _count(from: int, to: int, time: float) -> void:
	var seconds := maxf(time, COUNT_MIN_TIME) * speed_scale
	if to <= from:
		return
	if seconds <= 0.0:
		_tick(float(to))
		return
	var tween := create_tween()
	tween.tween_method(_tick, float(from), float(to), seconds)
	await tween.finished


func _tick(value: float) -> void:
	var level := floori(value + 0.001)
	if level == _level_shown:
		return
	_level_shown = level
	_counter.text = COUNTER_FORMAT % level
	level_ticked.emit(level)


## Coroutine : le palier : le compteur s'arrête, silhouette, flash, l'autre espèce.
func _play_stage(species: StringName) -> void:
	await _wait(STAGE_PAUSE)
	_tween_white(1.0, STAGE_RISE)
	await _wait(STAGE_RISE)
	_flash.visible = true
	_flash.modulate.a = FLASH_REDUCED_ALPHA if reduce_flashes else FLASH_ALPHA
	_fade(_flash, 0.0, STAGE_FLASH + STAGE_FALL)
	_show_species(_art, species)
	evolved_on_screen.emit(species)
	cry_requested.emit(species)
	await _wait(STAGE_FLASH)
	_tween_white(0.0, STAGE_FALL)
	await _wait(STAGE_FALL)


# --- Le plan large ---------------------------------------------------------------------------


func _play_line_up(report: AwakeningReport, lines: Array[String], stored_line: String) -> void:
	_phase = Phase.LINE_UP
	theme_burst.emit()
	Haptics.vibrate(LAND_HAPTIC_MS)
	_flash.visible = true
	_flash.modulate.a = FLASH_REDUCED_ALPHA if reduce_flashes else FLASH_ALPHA
	_fade(_flash, 0.0, LINE_UP_TIME)
	_tween_power(LIGHT_LINE_UP, LINE_UP_TIME, Tween.EASE_OUT)
	_motes.amount = MOTES_HIGH
	_fill_line_up(report)
	_line_up.modulate.a = 1.0
	await _wait(LINE_UP_TIME)
	for text: String in lines:
		await _say(text, LINE_READ)
	if not stored_line.is_empty():
		await _say(stored_line, STORED_READ)


## Coroutine : une ligne en bas de l'écran, lue [param read] secondes.
func _say(text: String, read: float) -> void:
	_line.text = text
	_line.visible = true
	_line.modulate.a = 0.0
	_fade(_line, 1.0, LINE_FADE)
	await _wait(read)
	_fade(_line, 0.0, LINE_FADE)
	await _wait(LINE_FADE)


func _fill_line_up(report: AwakeningReport) -> void:
	for child: Node in _line_up.get_children():
		_line_up.remove_child(child)
		child.queue_free()
	var count := report.line_up.size()
	if count == 0:
		return
	var slot := minf(LINE_UP_SLOT, (_root.size.x - 2.0 * UiTokens.SAFE_MARGIN) / float(count))
	var left := -slot * float(count) * 0.5
	for i: int in count:
		var rect := TextureRect.new()
		rect.name = "Member%d" % i
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_line_up.add_child(rect)
		_show_species(rect, report.line_up[i].species_id)
		rect.size = Vector2(slot, LINE_UP_HEIGHT)
		rect.position = Vector2(left + slot * float(i), LINE_UP_BOTTOM - LINE_UP_HEIGHT)
		rect.pivot_offset = Vector2(slot * 0.5, LINE_UP_HEIGHT)
		rect.scale = Vector2.ONE * 0.8
		_anim(rect, ^"scale", Vector2.ONE, LINE_UP_TIME, Tween.EASE_OUT, Tween.TRANS_BACK)


# --- L'écran du Réveil -----------------------------------------------------------------------


func _fill_review(report: AwakeningReport) -> void:
	for button: Button in _row_buttons:
		_rows.remove_child(button)
		button.queue_free()
	_row_buttons.clear()
	_row_results.clear()
	_pending.clear()
	for result: AwakeningResult in report.party:
		_row_results.append(result)
		_pending[result] = result.new_moves.duplicate()
		var button := Button.new()
		button.name = "Row%d" % _row_buttons.size()
		button.theme_type_variation = &"PanelButton"
		button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		TapGuard.attach(button)
		button.pressed.connect(_on_row_pressed.bind(_row_buttons.size()))
		_rows.add_child(button)
		_row_buttons.append(button)
		_refresh_row(_row_buttons.size() - 1)


func _refresh_row(index: int) -> void:
	var result := _row_results[index]
	var button := _row_buttons[index]
	var pending: Array = _pending[result]
	button.text = row_text(result, _data, pending.size())
	button.disabled = pending.is_empty()


## Le texte d'une ligne : nom (ou évolution), niveaux, attaques encore à voir.
static func row_text(result: AwakeningResult, data: PokemonData, moves: int) -> String:
	var title := result.pokemon.display_name(data)
	if result.evolved():
		var from := data.get_species(result.species_before)
		var into := data.get_species(result.species_after())
		title = ROW_EVOLVED % [from.name if from != null else String(result.species_before),
			into.name if into != null else String(result.species_after())]
	var detail := ROW_LEVELS % [result.level_before, result.level_after]
	if moves == 1:
		detail += ROW_SEPARATOR + ROW_MOVES_ONE
	elif moves > 1:
		detail += ROW_SEPARATOR + ROW_MOVES % moves
	return "%s\n%s" % [title, detail]


func _on_row_pressed(index: int) -> void:
	if _teaching or _prompt == null:
		return
	_teaching = true
	var result := _row_results[index]
	var pending: Array = _pending[result]
	_panel.visible = false
	var banner := get_message_banner()
	banner.speed_scale = speed_scale
	for move_id: Variant in pending.duplicate():
		var learned: bool = await _prompt.teach(result.pokemon, result.party_index,
			StringName(move_id), banner, get_prompt_host())
		_learned = _learned or learned
		pending.erase(move_id)
	banner.skip()
	banner.slide_out()
	while banner.is_sliding():
		await get_tree().process_frame
	_refresh_row(index)
	_panel.visible = true
	_teaching = false


func _on_continue_pressed() -> void:
	if _phase != Phase.REVIEW or _teaching:
		return
	_panel.visible = false
	_veil.visible = false
	_review_closed.emit()


# --- Petits outils ---------------------------------------------------------------------------


func _reset() -> void:
	_phase = Phase.IDLE
	_root.modulate.a = 1.0
	_stones_active = false
	_stones_time = 0.0
	_base.modulate.a = 0.0
	_shade.modulate.a = 0.0
	_flash.visible = false
	_veil.visible = false
	_panel.visible = false
	_line.visible = false
	_line_up.modulate.a = 0.0
	_art.modulate.a = 0.0
	_counter.modulate.a = 0.0
	_glow.modulate.a = 0.0
	_rays.modulate.a = 0.0
	_ring.modulate.a = 0.0
	_motes.amount = MOTES_LOW
	_motes.emitting = false
	_set_power(0.0)
	for i: int in _stones.size():
		_stones[i].position = _stone_home(i)
		_stones[i].modulate.a = 0.0
		_stones[i].scale = Vector2.ONE


## Place d'une pierre (coin gauche) : les trois en triangle ; −1 : réunies au centre.
func _stone_home(index: int) -> Vector2:
	var offset := Vector2.ZERO
	if index >= 0:
		offset = Vector2.from_angle(-PI * 0.5 + TAU * float(index) / 3.0) * STONE_SPREAD
	return Vector2(0.0, STONE_CENTER_Y) + offset - Vector2.ONE * STONE_SIZE * 0.5


func _aspect() -> float:
	return _root.size.x / maxf(_root.size.y, 1.0)


func _show_species(rect: TextureRect, species: StringName) -> void:
	var image := _battle_art.image(species, false) if _battle_art != null else {}
	rect.texture = image.get("texture")
	rect.flip_h = image.get("flip", false)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if image.get("official", true) \
		else CanvasItem.TEXTURE_FILTER_NEAREST


func _set_white(value: float) -> void:
	_art_material.set_shader_parameter(&"white", value)


func _set_power(value: float) -> void:
	_light_material.set_shader_parameter(&"power", value)


func _tween_white(value: float, time: float) -> void:
	var seconds := time * speed_scale
	if seconds <= 0.0:
		_set_white(value)
		return
	var from := float(_art_material.get_shader_parameter(&"white"))
	create_tween().tween_method(_set_white, from, value, seconds)


func _tween_power(value: float, time: float, ease_type: Tween.EaseType) -> void:
	var seconds := time * speed_scale
	if seconds <= 0.0:
		_set_power(value)
		return
	create_tween().tween_method(_set_power, get_light_power(), value, seconds) \
		.set_ease(ease_type).set_trans(Tween.TRANS_QUAD)


## L'onde d'une Ball qui s'ouvre, ou d'un Pokémon qui se pose.
func _burst_ring() -> void:
	_ring.scale = Vector2.ONE * 0.25
	_ring.modulate.a = 1.0
	_anim(_ring, ^"scale", Vector2.ONE * 1.4, ENTER_TIME, Tween.EASE_OUT)
	_fade(_ring, 0.0, ENTER_TIME)


func _fade(node: CanvasItem, alpha: float, time: float) -> void:
	_anim(node, ^"modulate:a", alpha, time, Tween.EASE_OUT)


func _anim(node: Node, property: NodePath, value: Variant, time: float,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT,
		trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	var seconds := time * speed_scale
	if seconds <= 0.0:
		node.set_indexed(property, value)
		return
	create_tween().tween_property(node, property, value, seconds) \
		.set_ease(ease_type).set_trans(trans)


## Attente en temps de jeu (Tween : temps simulé dans les tests) ; sans attente à la vitesse 0.
func _wait(time: float) -> void:
	var seconds := time * speed_scale
	if seconds <= 0.0:
		return
	var tween := create_tween()
	tween.tween_interval(seconds)
	await tween.finished


# --- Construction ----------------------------------------------------------------------------


func _build_film() -> void:
	var film_root := Control.new()
	film_root.name = "Film"
	film_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(film_root)
	_root.move_child(film_root, 0)
	film_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade = _cover(film_root, "Shade", NIGHT)
	_base = _cover(film_root, "Base", NIGHT)
	_light = _cover(film_root, "Light", Color.WHITE)
	_light_material = ShaderMaterial.new()
	_light_material.shader = LIGHT_SHADER
	_light_material.set_shader_parameter(&"earth", STONE_COLORS[0])
	_light_material.set_shader_parameter(&"sea", STONE_COLORS[1])
	_light_material.set_shader_parameter(&"sky", STONE_COLORS[2])
	_light.material = _light_material
	_build_motes(film_root)
	# Scène centrée : x = 0 au milieu de l'écran, y depuis le haut.
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film_root.add_child(_stage)
	_stage.anchor_left = 0.5
	_stage.anchor_right = 0.5
	var center := Vector2(0.0, ART_CENTER_Y)
	_rays = EvolutionRays.new()
	_rays.name = "Rays"
	_stage.add_child(_rays)
	_centered(_rays, center, Vector2.ONE * UiTokens.EVOLUTION_RAY_RADIUS * 2.0)
	var white := Color.WHITE
	_glow = _sprite(_stage, "Glow", _radial([0.0, 0.35, 1.0],
		[white, _alpha(white, 0.45), _alpha(white, 0.0)]))
	_centered(_glow, center, Vector2.ONE * GLOW_SIZE)
	_ring = _sprite(_stage, "Ring", _radial([0.0, 0.7, 0.86, 1.0],
		[_alpha(white, 0.0), _alpha(white, 0.0), white, _alpha(white, 0.0)]))
	_centered(_ring, center, Vector2.ONE * RING_SIZE)
	for i: int in STONE_COLORS.size():
		var color: Color = STONE_COLORS[i]
		var holder := TextureRect.new()
		holder.name = "Stone%d" % i
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(holder)
		holder.size = Vector2.ONE * STONE_SIZE
		holder.pivot_offset = holder.size * 0.5
		var orb := _sprite(holder, "Orb", _radial([0.0, 0.25, 1.0],
			[white, _alpha(color, 0.8), _alpha(color, 0.0)]))
		orb.size = holder.size
		_stones.append(holder)
	_art = TextureRect.new()
	_art.name = "Art"
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_material = ShaderMaterial.new()
	_art_material.shader = ART_SHADER
	_art.material = _art_material
	_stage.add_child(_art)
	_centered(_art, center, Vector2.ONE * ART_SIZE)
	_art.pivot_offset = Vector2(ART_SIZE * 0.5, ART_SIZE)
	_art_top = _art.position.y
	_line_up = Control.new()
	_line_up.name = "LineUp"
	_line_up.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_line_up)
	_counter = _text(film_root, "Counter", COUNTER_TOP, COUNTER_FONT)
	_counter.add_theme_color_override(&"font_color", UiTokens.ACCENT)
	_line = _text(film_root, "Line", LINE_TOP, LINE_FONT)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flash = _cover(film_root, "Flash", Color.WHITE)
	_flash.visible = false


func _build_review() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme_type_variation = &"MenuPanel"
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_top = -PANEL_SIZE.y * 0.5
	_panel.offset_bottom = PANEL_SIZE.y * 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.visible = false
	_root.add_child(_panel)
	_root.move_child(_panel, _root.get_child_count() - 3)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override(&"separation", UiTokens.PICKER_GAP)
	_panel.add_child(column)
	var title := Label.new()
	title.name = "Title"
	title.theme_type_variation = &"PickerTitle"
	title.text = REVIEW_TITLE
	column.add_child(title)
	_rows = GridContainer.new()
	_rows.name = "Rows"
	_rows.columns = ROW_COLUMNS
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override(&"h_separation", UiTokens.PICKER_GAP)
	_rows.add_theme_constant_override(&"v_separation", UiTokens.PICKER_GAP)
	column.add_child(_rows)
	_stored_line = Label.new()
	_stored_line.name = "Stored"
	_stored_line.visible = false
	column.add_child(_stored_line)
	_continue = Button.new()
	_continue.name = "Continue"
	_continue.theme_type_variation = &"AccentButton"
	_continue.text = CONTINUE_TEXT
	_continue.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	_continue.pressed.connect(_on_continue_pressed)
	column.add_child(_continue)


func _build_motes(parent: Control) -> void:
	var anchor := Control.new()
	anchor.name = "Motes"
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(anchor)
	anchor.anchor_left = 0.5
	anchor.anchor_right = 0.5
	anchor.anchor_top = 1.0
	anchor.anchor_bottom = 1.0
	_motes = CPUParticles2D.new()
	anchor.add_child(_motes)
	var white := Color.WHITE
	var dot := _radial([0.0, 0.4, 1.0], [white, _alpha(white, 0.35), _alpha(white, 0.0)])
	(dot as GradientTexture2D).width = 32
	(dot as GradientTexture2D).height = 32
	_motes.texture = dot
	_motes.amount = MOTES_LOW
	_motes.lifetime = 5.0
	_motes.preprocess = 2.0
	_motes.position = Vector2(0.0, 60.0)
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.emission_rect_extents = Vector2(1200.0, 40.0)
	_motes.direction = Vector2.UP
	_motes.spread = 16.0
	_motes.gravity = Vector2.ZERO
	_motes.initial_velocity_min = 130.0
	_motes.initial_velocity_max = 300.0
	_motes.scale_amount_min = 0.5
	_motes.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
	ramp.colors = PackedColorArray([_alpha(white, 0.0), white, white, _alpha(white, 0.0)])
	_motes.color_ramp = ramp
	_motes.emitting = false


func _cover(parent: Control, cover_name: String, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = cover_name
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


func _text(parent: Control, label_name: String, top: float, font: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.theme_type_variation = &"WorldCaption"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font)
	parent.add_child(label)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -UiTokens.EVOLUTION_LINE_WIDTH * 0.5
	label.offset_right = UiTokens.EVOLUTION_LINE_WIDTH * 0.5
	label.offset_top = top
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	return label


func _sprite(parent: Control, sprite_name: String, texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = sprite_name
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(rect)
	return rect


static func _centered(control: Control, center: Vector2, size: Vector2) -> void:
	control.position = center - size * 0.5
	control.size = size
	control.pivot_offset = size * 0.5


static func _radial(offsets: Array[float], colors: Array[Color]) -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture


static func _alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = alpha
	return result
