class_name EvolutionScreen
extends CanvasLayer
## Écran d'évolution (jalon-09.md §2.3.3, T9) : la présentation du **contrat** posé au T8 entre
## [EvolutionDirector] (la logique et l'ordre) et l'écran (le temps, l'image, le geste). Le
## directeur n'attend que ces coroutines, dans cet ordre, pour chaque évolution d'un combat :
##
## [codeblock]
## open()                         # une fois : l'environnement disparaît
## present(view)                  # l'ancienne espèce, « Quoi ? X évolue ! »
## var cancelled := transform()   # silhouettes, ARRÊTER ; vrai si annulée
##   (le directeur applique l'évolution ici, seulement si elle n'est pas annulée)
## reveal()  ou  revert()         # nouvelle espèce / retour à l'ancienne, toucher
##   (capacités : bandeau get_message_banner(), panneaux dans get_prompt_host())
## … present(view) suivant …
## close()                        # une fois : retour à la vue de combat
## [/codeblock]
##
## Mise en scène (premier vrai moment d'émotion du jeu, dossier 04 §7) : nuit bleutée opaque,
## poussières de lumière qui montent, le Pokémon (artwork officiel, [PokedexArt]) posé sur son
## ombre dans un halo froid. Transformation : couleurs → silhouette blanche auréolée, puis les
## silhouettes de l'ancienne et de la nouvelle espèce alternent en accélérant
## ([method swap_phase]) pendant que le halo enfle, que les rayons tournent de plus en plus
## vite et que les poussières se pressent. Flash, silence (la nouvelle silhouette immobile),
## puis les couleurs reviennent sur la nouvelle espèce : halo doré, onde, vibration courte,
## son nom en grand, la phrase, et la consigne qui respire. Annulée : retour doux aux couleurs
## de l'ancienne espèce.
##
## Toutes les durées vivent dans `UiTokens.EVOLUTION_*`, multipliées par [member speed_scale]
## (0 = instantané, sans attendre de toucher : tests ; « Réduire les animations » : facteur du
## combat). Chaque attente minutée est un Tween (temps simulé dans les tests) ; l'attente d'un
## toucher n'a pas de durée. Rien n'est écrit dans la partie par l'écran, aucun texte de jeu
## n'y est composé : tout vient de [EvolutionView].
## Jalon 11 (dossier 14 §7) : séquence courte (≈ 6 s, jetons EVOLUTION_*) ; toucher l'écran de la
## présentation à la consigne la joue ×2 ([method rush]) ; ARRÊTER reste un bouton à part.

## Fin d'une transformation (au terme, ou arrêtée) : reprend [method transform].
signal _transformation_ended
## Le joueur a touché l'écran pour continuer.
signal _continue_requested

const BANNER_SCENE: PackedScene = preload("res://game/ui/battle/battle_message_banner.tscn")
const STOP_ICON: Texture2D = preload("res://assets/ui/icons/menu/close.svg")
## Grossissement du halo au plus fort de la transformation ; de l'onde (début, fin) ; des rayons
## à la révélation (départ) ; du Pokémon qui « respire » à la révélation (départ).
const GLOW_GROW := 1.25
const RING_FROM := 0.3
const RING_TO := 1.5
const RAYS_BURST_FROM := 0.7
const ART_SETTLE_FROM := 1.06
## Poussières pendant le silence (presque immobiles).
const MOTES_SILENCE := 0.15
## Taille des textures de dégradé générées (le filtre linéaire les lisse).
const GRADIENT_TEXTURE := 256

## Multiplie toutes les durées (relayé par le directeur avant [method open]) ; 0 = instantané.
var speed_scale: float = 1.0
## « Réduire les flashs » (Paramètres) : flash atténué
## ([constant UiTokens.EVOLUTION_FLASH_REDUCED_ALPHA]).
var reduce_flashes: bool = false

var _open: bool = false
## Jalon 11 (dossier 14 §7) : vitesse de la séquence (1, puis EVOLUTION_RUSH après un toucher) ;
## [member _rushable] : un toucher peut encore l'accélérer (de la présentation à la consigne).
var _rush: float = 1.0
var _rushable: bool = false
var _tweens: Array[Tween] = []
var _white_tween: Tween
var _transforming: bool = false
var _cancel_requested: bool = false

var _view: EvolutionView
var _timeline: Tween
var _progress: Tween
var _stop_tween: Tween
var _hint_tween: Tween
var _waiting_touch: bool = false
var _touch_armed: bool = false
var _shows_art: bool = false
var _showing_new: bool = false
var _white: float = 0.0
var _ray_spin: float = UiTokens.EVOLUTION_RAY_SPIN
var _text_tops: Dictionary[Control, float] = {}
var _art_top: float = 0.0
## Décalage horizontal de la scène (place laissée au panneau d'oubli).
var _room: float = 0.0

var _root: Control
var _ambient: TextureRect
var _motes: CPUParticles2D
var _rays: EvolutionRays
var _glow: TextureRect
var _ring: TextureRect
var _shadow: TextureRect
var _stage: Control
var _art: Control
var _from_stack: Control
var _into_stack: Control
var _name: Label
var _line: Label
var _hint: Label
var _flash: ColorRect
var _stop: Button
var _banner: BattleMessageBanner
var _host: Control


func _ready() -> void:
	layer = UiTokens.LAYER_EVOLUTION
	_build()
	_reset_stage()
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_rays.rotation = fposmod(_rays.rotation + _ray_spin * _rush * delta, TAU)
	_make_room(delta)


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	if not _waiting_touch:
		# Toucher pendant la séquence (hors ARRÊTER) : elle se joue ×2 (jalon 11).
		if _rushable and not _stop.get_global_rect().has_point(touch.position):
			rush()
		return
	get_viewport().set_input_as_handled()
	if not _touch_armed:
		return
	_touch_armed = false
	_waiting_touch = false
	_continue_requested.emit()


## Coroutine : l'écran apparaît (fond opaque sombre, « l'environnement disparaît »). Appelée une
## fois avant la première évolution d'un combat.
func open() -> void:
	_open = true
	_reset_stage()
	visible = true
	_motes.restart()
	_motes.emitting = true
	set_process(true)
	_root.modulate.a = 0.0
	_anim(_root, ^"modulate:a", 1.0, UiTokens.EVOLUTION_OPEN, 0.0, Tween.EASE_IN_OUT)
	await _play([UiTokens.EVOLUTION_OPEN])


## Coroutine : [param view] — l'ancienne espèce monte au centre, puis
## [member EvolutionView.started_text] (EVOLUTION_PRESENT au total, sans toucher). Appelée pour
## chaque évolution, après [method open].
func present(view: EvolutionView) -> void:
	_cancel_requested = false
	_rush = 1.0
	_rushable = true
	_view = view
	_touch_armed = false
	_hide_banner()
	if _shows_art:
		# Deuxième évolution du même écran : la précédente s'efface d'abord.
		var out := UiTokens.EVOLUTION_SWITCH_OUT
		_anim(_art, ^"modulate:a", 0.0, out, 0.0, Tween.EASE_IN)
		_anim(_shadow, ^"modulate:a", 0.0, out, 0.0, Tween.EASE_IN)
		_anim(_glow, ^"modulate:a", 0.0, out, 0.0, Tween.EASE_IN)
		_anim(_rays, ^"modulate:a", 0.0, out, 0.0, Tween.EASE_IN)
		_fade_out(_name)
		_fade_out(_line)
		_hide_hint()
		await _play([out, _enter, UiTokens.EVOLUTION_PRESENT - out])
	else:
		_enter()
		await _play([UiTokens.EVOLUTION_PRESENT])


## Coroutine : la transformation (EVOLUTION_TRANSFORM) — couleurs → silhouette blanche, puis
## les silhouettes de l'ancienne et de la nouvelle espèce alternent en accélérant ; le bouton
## [member EvolutionView.stop_label] n'est visible et actif que pendant cette phase. Rend
## [code]true[/code] si le joueur l'a arrêtée (bouton ou [method handle_back]) : elle
## s'interrompt aussitôt. Rend [code]false[/code] arrivée à son terme.
func transform() -> bool:
	_transforming = true
	# Jalon 12 (T23) : une évolution non annulable (pierre) n'offre pas ARRÊTER.
	_show_stop(is_cancellable())
	var time := UiTokens.EVOLUTION_TRANSFORM * speed_scale
	if time <= 0.0:
		_apply_progress(1.0)
	else:
		_progress = _tween()
		_progress.tween_method(_apply_progress, 0.0, 1.0, time)
		_progress.tween_callback(_end_transformation)
		await _transformation_ended
	_progress = null
	_transforming = false
	_show_stop(false)
	var cancelled := _cancel_requested
	_cancel_requested = false
	return cancelled


## Coroutine : l'évolution est faite (déjà appliquée aux données) — flash, silence, la nouvelle
## espèce en couleurs, vibration courte, son nom, [member EvolutionView.finished_text], puis
## attente d'un toucher ([member EvolutionView.continue_text]).
func reveal() -> void:
	_touch_armed = false
	var peak := UiTokens.EVOLUTION_FLASH_REDUCED_ALPHA if reduce_flashes \
		else UiTokens.EVOLUTION_FLASH_ALPHA
	_flash.visible = true
	_flash.modulate.a = 0.0
	_anim(_flash, ^"modulate:a", peak, UiTokens.EVOLUTION_FLASH_RISE, 0.0, Tween.EASE_OUT,
		Tween.TRANS_QUAD)
	await _play([
		UiTokens.EVOLUTION_FLASH_RISE, _at_flash_peak,
		UiTokens.EVOLUTION_FLASH - UiTokens.EVOLUTION_FLASH_RISE + UiTokens.EVOLUTION_SILENCE,
		_at_reveal, UiTokens.EVOLUTION_REVEAL, _arm_touch,
	])
	await _wait_touch()


## Coroutine : l'évolution est annulée — retour doux aux couleurs de l'ancienne espèce,
## [member EvolutionView.cancelled_text], puis attente d'un toucher.
func revert() -> void:
	_touch_armed = false
	var time := UiTokens.EVOLUTION_REVERT
	_show_form(false)
	_art.scale = Vector2.ONE
	_anim_white(0.0, time)
	_anim(_glow, ^"modulate:a", UiTokens.EVOLUTION_GLOW_CALM, time)
	_anim(_glow, ^"scale", Vector2.ONE, time)
	_anim(_rays, ^"modulate:a", 0.0, time)
	_ray_spin = UiTokens.EVOLUTION_RAY_SPIN
	_motes.speed_scale = 1.0
	_fade_out(_line)
	await _play([
		UiTokens.EVOLUTION_TEXT_OUT, _show_line.bind(_cancelled_text()),
		time - UiTokens.EVOLUTION_TEXT_OUT, _arm_touch,
	])
	await _wait_touch()


## Bandeau des messages des capacités apprises à l'évolution (en bas au centre) ; la phrase et
## la consigne de la révélation s'effacent pour lui laisser la place.
func get_message_banner() -> BattleMessageBanner:
	_fade_out(_line)
	_hide_hint()
	_banner.speed_scale = speed_scale
	return _banner


## Parent plein écran (au-dessus de tout) du panneau d'oubli et de la question à deux cartes.
func get_prompt_host() -> Control:
	return _host


## Coroutine : l'écran disparaît (retour à la vue de combat, qui sort ensuite). Appelée une fois
## après la dernière évolution.
func close() -> void:
	_touch_armed = false
	_waiting_touch = false
	_hide_banner()
	_hide_hint()
	_anim(_root, ^"modulate:a", 0.0, UiTokens.EVOLUTION_CLOSE, 0.0, Tween.EASE_IN)
	await _play([UiTokens.EVOLUTION_CLOSE])
	_open = false
	visible = false
	_motes.emitting = false
	set_process(false)
	_shows_art = false


## Retour Android pendant l'écran : pendant [method transform], arrête la transformation
## (comme ARRÊTER), sauf pour une évolution non annulable (pierre, jalon 12) ; ailleurs, sans
## effet. Vrai tant que l'écran est ouvert (le geste ne passe
## jamais à ce qui est dessous).
func handle_back() -> bool:
	if _transforming:
		_request_cancel()
	return _open


## La transformation est en cours (le bouton ARRÊTER est actif).
func is_transforming() -> bool:
	return _transforming


func is_open() -> bool:
	return _open


## Le bouton ARRÊTER est affiché et actif.
func is_stop_active() -> bool:
	return _stop.visible and not _stop.disabled


func get_stop_button() -> Button:
	return _stop


## Un toucher est attendu et sera pris (consigne affichée).
func is_waiting_touch() -> bool:
	return _waiting_touch and _touch_armed


## La silhouette (ou l'image) montrée est celle de la nouvelle espèce.
func is_showing_new_form() -> bool:
	return _showing_new


## Part de blanc posée sur l'image (0 = couleurs, 1 = silhouette).
func get_whiteness() -> float:
	return _white


func get_flash_alpha() -> float:
	return _flash.modulate.a if _flash.visible else 0.0


func get_line_text() -> String:
	return _line.text if _line.modulate.a > 0.0 else ""


func get_name_text() -> String:
	return _name.text if _name.modulate.a > 0.0 else ""


func get_hint_text() -> String:
	return _hint.text if _hint.visible else ""


## Nombre (réel) de bascules de silhouette à l'avancement [param progress] (0 → 1) de la
## transformation : l'intervalle passe de EVOLUTION_SWAP_START à EVOLUTION_SWAP_END
## (fréquence a + 3·b·t², croissante). Indépendant de la vitesse : le motif est le même,
## seulement plus court avec « Réduire les animations ».
static func swap_phase(progress: float) -> float:
	var total := UiTokens.EVOLUTION_TRANSFORM
	var t := clampf(progress, 0.0, 1.0) * total
	var start := 1.0 / UiTokens.EVOLUTION_SWAP_START
	var finish := 1.0 / UiTokens.EVOLUTION_SWAP_END
	var b := (finish - start) / (3.0 * total * total)
	return start * t + b * t * t * t


## Vrai si la nouvelle espèce est montrée à l'avancement [param progress] (bascules impaires ;
## toujours elle au terme).
static func shows_new_form(progress: float) -> bool:
	return progress >= 1.0 or int(floorf(swap_phase(progress))) % 2 == 1


# --- Déroulé ---------------------------------------------------------------------------------


## L'ancienne espèce monte au centre en fondu, dans son halo froid ; la phrase suit.
func _enter() -> void:
	_set_species()
	_show_form(false)
	_set_white(0.0)
	_art.scale = Vector2.ONE
	_art.modulate.a = 0.0
	_art.position.y = _art_top + UiTokens.EVOLUTION_ENTER_RISE
	var enter := UiTokens.EVOLUTION_ENTER
	_anim(_art, ^"modulate:a", 1.0, enter)
	_anim(_art, ^"position:y", _art_top, enter)
	_anim(_shadow, ^"modulate:a", 1.0, enter)
	_glow.self_modulate = UiTokens.EVOLUTION_GLOW_COOL
	_glow.scale = Vector2.ONE
	_anim(_glow, ^"modulate:a", UiTokens.EVOLUTION_GLOW_CALM, enter)
	_rays.self_modulate = UiTokens.EVOLUTION_RAY_COLOR
	_rays.modulate.a = 0.0
	_rays.scale = Vector2.ONE
	_ray_spin = UiTokens.EVOLUTION_RAY_SPIN
	_motes.speed_scale = 1.0
	_name.modulate.a = 0.0
	_show_text(_line, _view.started_text if _view != null else "",
		UiTokens.EVOLUTION_TEXT_DELAY)
	_shows_art = true


## Avancement [param p] (0 → 1) de la transformation : tout l'état visuel en découle.
func _apply_progress(p: float) -> void:
	var seconds := p * UiTokens.EVOLUTION_TRANSFORM
	var white := clampf(seconds / UiTokens.EVOLUTION_TO_SILHOUETTE, 0.0, 1.0)
	_set_white(white * white * (3.0 - 2.0 * white))
	var phase := swap_phase(p)
	_show_form(shows_new_form(p))
	var pop := 0.0
	if phase >= 1.0 and p < 1.0:
		pop = pow(1.0 - fposmod(phase, 1.0), 3.0)
	_art.scale = Vector2.ONE * (1.0 + UiTokens.EVOLUTION_SWAP_POP * pop)
	var lift := p * p
	_glow.modulate.a = lerpf(UiTokens.EVOLUTION_GLOW_CALM, UiTokens.EVOLUTION_GLOW_PEAK, lift)
	_glow.scale = Vector2.ONE * lerpf(1.0, GLOW_GROW, lift)
	_rays.modulate.a = UiTokens.EVOLUTION_RAY_ALPHA_PEAK * p
	_ray_spin = lerpf(UiTokens.EVOLUTION_RAY_SPIN, UiTokens.EVOLUTION_RAY_SPIN_PEAK, lift)
	_motes.speed_scale = lerpf(1.0, UiTokens.EVOLUTION_MOTE_RUSH, lift) * _rush


func _end_transformation() -> void:
	_transformation_ended.emit()


## ARRÊTER ou retour Android pendant la transformation : elle s'interrompt aussitôt (jamais
## pour une évolution non annulable).
func _request_cancel() -> void:
	if not _transforming or _cancel_requested or not is_cancellable():
		return
	_cancel_requested = true
	_stop.disabled = true
	var progress := _progress
	_progress = null
	if progress != null and progress.is_valid():
		progress.kill()
	_transformation_ended.emit()


func _on_stop_pressed() -> void:
	if not _transforming:
		return
	Haptics.vibrate(UiTokens.HAPTIC_TAP_MS)
	_request_cancel()


## Sommet du flash : la nouvelle silhouette, immobile ; tout se tait.
func _at_flash_peak() -> void:
	_anim(_flash, ^"modulate:a", 0.0, UiTokens.EVOLUTION_FLASH - UiTokens.EVOLUTION_FLASH_RISE,
		0.0, Tween.EASE_OUT, Tween.TRANS_QUAD)
	_show_form(true)
	_set_white(1.0)
	_art.scale = Vector2.ONE
	_rays.modulate.a = 0.0
	_ray_spin = UiTokens.EVOLUTION_RAY_SPIN
	_glow.scale = Vector2.ONE
	_glow.modulate.a = UiTokens.EVOLUTION_GLOW_CALM
	_motes.speed_scale = MOTES_SILENCE
	_line.modulate.a = 0.0


## Révélation : les couleurs reviennent, halo doré, onde, rayons, vibration ; nom puis phrase.
func _at_reveal() -> void:
	Haptics.vibrate(UiTokens.EVOLUTION_HAPTIC_MS)
	var time := UiTokens.EVOLUTION_REVEAL
	_anim_white(0.0, time)
	_art.scale = Vector2.ONE * ART_SETTLE_FROM
	_anim(_art, ^"scale", Vector2.ONE, time, 0.0, Tween.EASE_OUT, Tween.TRANS_BACK)
	_glow.self_modulate = UiTokens.EVOLUTION_GLOW_GOLD
	_glow.modulate.a = UiTokens.EVOLUTION_GLOW_PEAK
	_anim(_glow, ^"modulate:a", UiTokens.EVOLUTION_GLOW_REVEALED, time)
	_rays.self_modulate = UiTokens.EVOLUTION_GLOW_GOLD
	_rays.modulate.a = UiTokens.EVOLUTION_RAY_ALPHA_PEAK
	_rays.scale = Vector2.ONE * RAYS_BURST_FROM
	_anim(_rays, ^"scale", Vector2.ONE, time)
	_anim(_rays, ^"modulate:a", UiTokens.EVOLUTION_RAY_ALPHA_REVEALED, time)
	_ring.self_modulate = UiTokens.EVOLUTION_GLOW_GOLD
	_ring.modulate.a = 1.0
	_ring.scale = Vector2.ONE * RING_FROM
	_anim(_ring, ^"scale", Vector2.ONE * RING_TO, time)
	_anim(_ring, ^"modulate:a", 0.0, time, 0.0, Tween.EASE_OUT, Tween.TRANS_QUAD)
	_motes.speed_scale = 1.0
	_show_text(_name, _view.into_name.to_upper() if _view != null else "",
		UiTokens.EVOLUTION_NAME_DELAY)
	_show_text(_line, _view.finished_text if _view != null else "",
		UiTokens.EVOLUTION_LINE_DELAY)


func _show_line(text: String) -> void:
	_show_text(_line, text, 0.0)


func _cancelled_text() -> String:
	return _view.cancelled_text if _view != null else ""


## Fin de la phrase : le toucher sera pris, la consigne apparaît.
func _arm_touch() -> void:
	_rushable = false
	_rush = 1.0
	# Révélation et retour finissent en couleurs pleines quand la consigne paraît (le fondu du
	# blanc dure autant que la phrase : il peut lui manquer un dernier pas).
	if _white_tween != null and _white_tween.is_valid():
		_white_tween.kill()
	_set_white(0.0)
	_touch_armed = true
	_show_hint()


## Joue le reste de la séquence ×EVOLUTION_RUSH (toucher pendant la présentation, la
## transformation ou la révélation ; jalon 11, dossier 14 §7). ARRÊTER reste un bouton à part.
## Sans effet hors de ces phases ou déjà accéléré.
func rush() -> void:
	if not _rushable or _rush > 1.0:
		return
	_rush = UiTokens.EVOLUTION_RUSH
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.set_speed_scale(_rush)
	if _motes != null:
		_motes.speed_scale *= _rush


## Vitesse donnée à [param tween] par l'écran (×2 s'il a été accéléré) ; 1 pour un autre
## (tests : Tween n'expose pas sa vitesse).
func tween_speed(tween: Tween) -> float:
	return _rush if _tweens.has(tween) else 1.0


## Vrai si la séquence est accélérée.
func is_rushed() -> bool:
	return _rush > 1.0


## Tween de l'écran, à la vitesse courante (×2 après un toucher).
func _tween() -> Tween:
	var tween := create_tween()
	tween.set_speed_scale(_rush)
	_tweens = _tweens.filter(func(t: Tween) -> bool: return t.is_valid())
	_tweens.append(tween)
	return tween


## Coroutine : attend un toucher (rien à vitesse 0 : tests).
func _wait_touch() -> void:
	if speed_scale <= 0.0:
		_touch_armed = false
		return
	_waiting_touch = true
	await _continue_requested
	_waiting_touch = false
	_touch_armed = false
	_hide_hint()


## Un panneau est affiché dans le parent des panneaux (oubli, à droite) : le Pokémon et son
## nom glissent au milieu de la place restée libre à gauche ; sinon, ils reviennent au centre.
func _make_room(delta: float) -> void:
	var target := 0.0
	for child: Node in _host.get_children():
		var panel := child as Control
		if panel != null and panel.visible:
			var width := _root.size.x
			var free := BattleHudLayout.rect(BattleHudLayout.Slot.FORGET, _root.size).position.x
			target = minf(target, free * 0.5 - width * 0.5)
	if is_equal_approx(_room, target):
		return
	var weight := 1.0 - exp(-UiTokens.EVOLUTION_MAKE_ROOM_RATE * delta)
	_room = lerpf(_room, target, weight)
	if absf(_room - target) < 0.5:
		_room = target
	_stage.position.x = _root.size.x * 0.5 + _room
	_name.offset_left = -UiTokens.EVOLUTION_LINE_WIDTH * 0.5 + _room
	_name.offset_right = UiTokens.EVOLUTION_LINE_WIDTH * 0.5 + _room


# --- Petits outils d'animation ---------------------------------------------------------------


## Coroutine : déroule [param steps] — des durées (secondes, × [member speed_scale]) et des
## rappels, dans l'ordre, sur un seul Tween (une seule horloge par phase). À vitesse 0, les
## rappels sont appelés tout de suite.
func _play(steps: Array) -> void:
	if speed_scale <= 0.0:
		for step: Variant in steps:
			if step is Callable:
				(step as Callable).call()
		return
	_timeline = _tween()
	for step: Variant in steps:
		if step is Callable:
			_timeline.tween_callback(step as Callable)
		elif float(step) > 0.0:
			_timeline.tween_interval(float(step) * speed_scale)
	await _timeline.finished


## Anime [param property] de [param target] vers [param value] ; posé tout de suite à vitesse 0.
func _anim(target: Object, property: NodePath, value: Variant, duration: float,
		delay: float = 0.0, ease: Tween.EaseType = Tween.EASE_OUT,
		trans: Tween.TransitionType = Tween.TRANS_CUBIC) -> void:
	var time := duration * speed_scale
	if time <= 0.0:
		target.set_indexed(property, value)
		return
	var tween := _tween().set_trans(trans).set_ease(ease)
	if delay > 0.0:
		tween.tween_interval(delay * speed_scale)
	tween.tween_property(target, property, value, time)


func _anim_white(value: float, duration: float) -> void:
	var time := duration * speed_scale
	if time <= 0.0:
		_set_white(value)
		return
	if _white_tween != null and _white_tween.is_valid():
		_white_tween.kill()
	_white_tween = _tween()
	_white_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) \
		.tween_method(_set_white, _white, value, time)


## Texte qui monte en fondu après [param delay].
func _show_text(label: Label, text: String, delay: float) -> void:
	label.text = text
	var top: float = _text_tops[label]
	label.modulate.a = 0.0
	label.position.y = top + UiTokens.EVOLUTION_TEXT_RISE
	_anim(label, ^"modulate:a", 1.0, UiTokens.EVOLUTION_TEXT_IN, delay)
	_anim(label, ^"position:y", top, UiTokens.EVOLUTION_TEXT_IN, delay)


func _fade_out(label: Label) -> void:
	_anim(label, ^"modulate:a", 0.0, UiTokens.EVOLUTION_TEXT_OUT, 0.0, Tween.EASE_IN)


func _show_hint() -> void:
	_kill_hint()
	_hint.text = _view.continue_text if _view != null else ""
	_hint.visible = true
	if speed_scale <= 0.0:
		_hint.modulate.a = 1.0
		return
	_hint.modulate.a = 0.0
	_hint_tween = _tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hint_tween.tween_property(_hint, ^"modulate:a", 1.0, UiTokens.EVOLUTION_HINT_IN * speed_scale)
	_hint_tween.tween_callback(_pulse_hint)


## La consigne respire tant qu'elle est là (sans fin, sans rien attendre).
func _pulse_hint() -> void:
	var half := UiTokens.EVOLUTION_HINT_PERIOD * 0.5 * maxf(speed_scale, 0.5)
	_hint_tween = _tween().set_loops().set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	_hint_tween.tween_property(_hint, ^"modulate:a", UiTokens.EVOLUTION_HINT_DIM, half)
	_hint_tween.tween_property(_hint, ^"modulate:a", 1.0, half)


func _hide_hint() -> void:
	_kill_hint()
	_hint.visible = false
	_hint.modulate.a = 0.0


func _kill_hint() -> void:
	if _hint_tween != null and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = null


func _show_stop(on: bool) -> void:
	if _stop_tween != null and _stop_tween.is_valid():
		_stop_tween.kill()
	_stop_tween = null
	_stop.text = _view.stop_label if _view != null else ""
	if on:
		_stop.visible = true
		_stop.disabled = false
		if speed_scale <= 0.0:
			_stop.modulate.a = 1.0
			return
		_stop.modulate.a = 0.0
		_stop_tween = _tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_stop_tween.tween_property(_stop, ^"modulate:a", 1.0,
			UiTokens.EVOLUTION_STOP_IN * speed_scale)
		return
	_stop.disabled = true
	if speed_scale <= 0.0 or not _stop.visible:
		_stop.visible = false
		return
	_stop_tween = _tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_stop_tween.tween_property(_stop, ^"modulate:a", 0.0, UiTokens.EVOLUTION_STOP_OUT * speed_scale)
	_stop_tween.tween_callback(_stop.hide)


func _hide_banner() -> void:
	if _banner.is_shown():
		_banner.skip()
		_banner.speed_scale = speed_scale
		_banner.slide_out()


func _set_white(value: float) -> void:
	_white = value
	var auras := UiTokens.EVOLUTION_AURA_ALPHAS.size()
	for stack: Control in [_from_stack, _into_stack]:
		for i: int in auras:
			(stack.get_child(i) as CanvasItem).modulate.a = \
				value * UiTokens.EVOLUTION_AURA_ALPHAS[i]
		(stack.get_child(auras + 1) as CanvasItem).modulate.a = value


func _show_form(new_form: bool) -> void:
	_showing_new = new_form
	_from_stack.visible = not new_form
	_into_stack.visible = new_form


## Les deux espèces de la vue courante (artworks officiels), posées sur le bas du cadre.
func _set_species() -> void:
	var from_dex := _view.from_dex if _view != null else 0
	var into_dex := _view.into_dex if _view != null else 0
	_fill_stack(_from_stack, PokedexArt.portrait(from_dex))
	_fill_stack(_into_stack, PokedexArt.portrait(into_dex))


func _fill_stack(stack: Control, texture: Texture2D) -> void:
	var box := float(UiTokens.EVOLUTION_ART_SIZE)
	var drawn := Vector2.ONE * box
	if texture != null:
		var source := texture.get_size()
		if source.x > 0.0 and source.y > 0.0:
			drawn = source * minf(box / source.x, box / source.y)
	for child: Node in stack.get_children():
		var rect := child as TextureRect
		rect.texture = texture
		rect.size = drawn
		rect.position = Vector2((box - drawn.x) * 0.5, box - drawn.y)
		# Les auras grandissent autour du centre de l'image.
		rect.pivot_offset = drawn * 0.5


# --- Construction ----------------------------------------------------------------------------


func _reset_stage() -> void:
	_kill_hint()
	_root.modulate.a = 1.0
	_art.modulate.a = 0.0
	_art.scale = Vector2.ONE
	_art.position.y = _art_top
	_shadow.modulate.a = 0.0
	_glow.modulate.a = 0.0
	_glow.scale = Vector2.ONE
	_rays.modulate.a = 0.0
	_ring.modulate.a = 0.0
	_flash.visible = false
	_flash.modulate.a = 0.0
	_name.modulate.a = 0.0
	_line.modulate.a = 0.0
	_hint.visible = false
	_hint.modulate.a = 0.0
	_stop.visible = false
	_stop.disabled = true
	_set_white(0.0)
	_show_form(false)
	_shows_art = false
	_touch_armed = false
	_waiting_touch = false


func _build() -> void:
	_root = _full_rect(Control.new(), self)
	_root.name = "Root"
	# Le fond prend tous les touchers : rien n'atteint la vue de combat dessous.
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var base := _full_rect(ColorRect.new(), _root) as ColorRect
	base.color = UiTokens.EVOLUTION_BG
	_ambient = _full_rect(TextureRect.new(), _root) as TextureRect
	_ambient.texture = _radial([0.0, 1.0], [UiTokens.EVOLUTION_AMBIENT, _clear(
		UiTokens.EVOLUTION_AMBIENT)])
	_ambient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ambient.stretch_mode = TextureRect.STRETCH_SCALE
	_build_motes()
	# Scène centrée : x = 0 au milieu de l'écran, y depuis le haut.
	var stage := Control.new()
	_stage = stage
	stage.name = "Stage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(stage)
	stage.anchor_left = 0.5
	stage.anchor_right = 0.5
	var center := Vector2(0.0, UiTokens.EVOLUTION_ART_CENTER_Y)
	_rays = EvolutionRays.new()
	_rays.name = "Rays"
	stage.add_child(_rays)
	_centered(_rays, center, Vector2.ONE * UiTokens.EVOLUTION_RAY_RADIUS * 2.0)
	var white := UiTokens.EVOLUTION_SILHOUETTE
	_glow = _sprite(stage, "Glow", _radial([0.0, 0.35, 1.0],
		[white, _faded(white, 0.45), _clear(white)]))
	_centered(_glow, center, Vector2.ONE * UiTokens.EVOLUTION_GLOW_SIZE)
	_ring = _sprite(stage, "Ring", _radial([0.0, 0.7, 0.86, 1.0],
		[_clear(white), _clear(white), white, _clear(white)]))
	_centered(_ring, center, Vector2.ONE * UiTokens.EVOLUTION_RING_SIZE)
	var shadow_color := UiTokens.EVOLUTION_SHADOW
	_shadow = _sprite(stage, "Shadow", _radial([0.0, 1.0], [shadow_color, _clear(shadow_color)]))
	_centered(_shadow, center + Vector2(0.0, UiTokens.EVOLUTION_ART_SIZE * 0.5),
		UiTokens.EVOLUTION_SHADOW_SIZE)
	_art = Control.new()
	_art.name = "Art"
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_art)
	_centered(_art, center, Vector2.ONE * UiTokens.EVOLUTION_ART_SIZE)
	_art.pivot_offset = Vector2(UiTokens.EVOLUTION_ART_SIZE * 0.5, UiTokens.EVOLUTION_ART_SIZE)
	_art_top = _art.position.y
	var silhouette := PokedexArt.silhouette_material().duplicate() as ShaderMaterial
	silhouette.set_shader_parameter(&"tint", UiTokens.EVOLUTION_SILHOUETTE)
	_from_stack = _stack("From", silhouette)
	_into_stack = _stack("Into", silhouette)
	_name = _label("Name", &"WorldCaption", UiTokens.EVOLUTION_NAME_TOP)
	_name.add_theme_font_size_override(&"font_size", UiTokens.EVOLUTION_NAME_FONT)
	_name.add_theme_color_override(&"font_color", UiTokens.ACCENT)
	_line = _label("Line", &"WorldCaption", UiTokens.EVOLUTION_LINE_TOP)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _label("Hint", &"ZoneTitleRegion", UiTokens.EVOLUTION_HINT_TOP)
	_flash = _full_rect(ColorRect.new(), _root) as ColorRect
	_flash.name = "Flash"
	_flash.color = UiTokens.EVOLUTION_FLASH_COLOR
	_build_stop()
	_banner = BANNER_SCENE.instantiate() as BattleMessageBanner
	_banner.name = "Banner"
	_root.add_child(_banner)
	# Ici, le bandeau est centré sous le Pokémon : sa phrase aussi.
	_banner.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.anchor_top = 1.0
	_banner.anchor_bottom = 1.0
	_banner.offset_left = -UiTokens.BATTLE_MESSAGE_WIDTH * 0.5
	_banner.offset_right = UiTokens.BATTLE_MESSAGE_WIDTH * 0.5
	_banner.offset_bottom = -UiTokens.EVOLUTION_BANNER_BOTTOM
	_banner.offset_top = -UiTokens.EVOLUTION_BANNER_BOTTOM - UiTokens.BATTLE_MESSAGE_HEIGHT
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_host = _full_rect(Control.new(), _root)
	_host.name = "PromptHost"


func _build_motes() -> void:
	var anchor := Control.new()
	anchor.name = "Motes"
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(anchor)
	anchor.anchor_left = 0.5
	anchor.anchor_right = 0.5
	anchor.anchor_top = 1.0
	anchor.anchor_bottom = 1.0
	_motes = CPUParticles2D.new()
	anchor.add_child(_motes)
	var white := UiTokens.EVOLUTION_SILHOUETTE
	var dot := _radial([0.0, 0.4, 1.0], [white, _faded(white, 0.35), _clear(white)])
	(dot as GradientTexture2D).width = UiTokens.EVOLUTION_MOTE_TEXTURE
	(dot as GradientTexture2D).height = UiTokens.EVOLUTION_MOTE_TEXTURE
	_motes.texture = dot
	_motes.amount = UiTokens.EVOLUTION_MOTES
	_motes.lifetime = UiTokens.EVOLUTION_MOTE_LIFE
	_motes.preprocess = UiTokens.EVOLUTION_MOTE_LIFE
	_motes.position = Vector2(0.0, -UiTokens.EVOLUTION_MOTE_AREA.y)
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.emission_rect_extents = UiTokens.EVOLUTION_MOTE_AREA
	_motes.direction = Vector2.UP
	_motes.spread = 18.0
	_motes.gravity = Vector2.ZERO
	_motes.initial_velocity_min = UiTokens.EVOLUTION_MOTE_SPEED.x
	_motes.initial_velocity_max = UiTokens.EVOLUTION_MOTE_SPEED.y
	_motes.scale_amount_min = UiTokens.EVOLUTION_MOTE_SCALE.x
	_motes.scale_amount_max = UiTokens.EVOLUTION_MOTE_SCALE.y
	_motes.color = UiTokens.EVOLUTION_MOTE
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.7, 1.0])
	ramp.colors = PackedColorArray([_clear(white), white, white, _clear(white)])
	_motes.color_ramp = ramp
	_motes.emitting = false


func _build_stop() -> void:
	_stop = Button.new()
	_stop.name = "Stop"
	_stop.theme_type_variation = &"PanelButton"
	_stop.icon = STOP_ICON
	_stop.add_theme_constant_override(&"icon_max_width", UiTokens.EVOLUTION_STOP_ICON)
	_stop.add_theme_constant_override(&"h_separation", UiTokens.GAP)
	_stop.focus_mode = Control.FOCUS_NONE
	_root.add_child(_stop)
	var size := UiTokens.EVOLUTION_STOP_SIZE
	_stop.anchor_left = 1.0
	_stop.anchor_right = 1.0
	_stop.anchor_top = 1.0
	_stop.anchor_bottom = 1.0
	_stop.offset_right = -UiTokens.EVOLUTION_STOP_RIGHT
	_stop.offset_left = -UiTokens.EVOLUTION_STOP_RIGHT - size.x
	_stop.offset_bottom = -UiTokens.EVOLUTION_STOP_BOTTOM
	_stop.offset_top = -UiTokens.EVOLUTION_STOP_BOTTOM - size.y
	_stop.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_stop.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_stop.custom_minimum_size = size
	_stop.pressed.connect(_on_stop_pressed)


## Une espèce : auras (silhouettes agrandies, translucides, de la plus serrée à la plus
## large), image en couleurs, silhouette blanche — dans cet ordre d'enfants.
func _stack(stack_name: String, silhouette: ShaderMaterial) -> Control:
	var stack := Control.new()
	stack.name = stack_name
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.add_child(stack)
	stack.size = Vector2.ONE * UiTokens.EVOLUTION_ART_SIZE
	var parts: Array[String] = []
	for i: int in UiTokens.EVOLUTION_AURA_SCALES.size():
		parts.append("Aura%d" % i)
	parts.append_array(["Color", "White"])
	for part: String in parts:
		var rect := TextureRect.new()
		rect.name = part
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		if part != "Color":
			rect.material = silhouette
		stack.add_child(rect)
	for i: int in UiTokens.EVOLUTION_AURA_SCALES.size():
		(stack.get_child(i) as Control).scale = Vector2.ONE * UiTokens.EVOLUTION_AURA_SCALES[i]
	return stack


func _label(label_name: String, variation: StringName, top: float) -> Label:
	var label := Label.new()
	label.name = label_name
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(label)
	var half := UiTokens.EVOLUTION_LINE_WIDTH * 0.5
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -half
	label.offset_right = half
	label.offset_top = top
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_text_tops[label] = top
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


static func _full_rect(control: Control, parent: Node) -> Control:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return control


## Place [param control] (enfant de la scène centrée) centré sur [param center].
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
	texture.width = GRADIENT_TEXTURE
	texture.height = GRADIENT_TEXTURE
	return texture


static func _clear(color: Color) -> Color:
	return _faded(color, 0.0)


static func _faded(color: Color, alpha: float) -> Color:
	var faded := color
	faded.a = alpha
	return faded


## L'évolution présentée peut être arrêtée (jalon 12, T23 : faux pour une pierre,
## [member EvolutionView.cancellable]) ; vrai sans vue.
func is_cancellable() -> bool:
	return _view == null or _view.cancellable
