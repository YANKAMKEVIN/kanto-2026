extends Node
## Autoload « Audio » : porte unique du son (docs/tech/jalon-son.md §1). Il **exécute** ce que
## décident les classes pures de `game/systems/audio/` : bus, deux lecteurs de musique qui
## alternent (A/B) avec fondu enchaîné, une boucle d'ambiance, un petit pool de bruitages, un
## lecteur de cris.
##
## **Muet tolérant** : un fichier absent n'est jamais une erreur ; un fichier déclaré
## « expected » (attendu, Son.0 : tous) se tait sans rien dire, un autre absent est signalé une
## fois en debug. Un jingle sans fichier se termine aussitôt (la couche du dessous reprend).
##
## **Espion** (comme [Haptics]) : quand [member sink] est posé, chaque ordre lui est passé
## (`{ "type": &"music" | &"sfx" | &"cry" | &"ambience", … }`) et aucun fichier n'est chargé ni
## joué : sous GUT et dans les outils, aucun son réel.
##
## Son.0 : branché nulle part dans le jeu (SonA, T6 : `AudioBridge`).
## Sans [code]class_name[/code] (le nom est pris par l'autoload) : les tests instancient
## [code]preload("res://game/autoload/audio.gd").new()[/code], jamais l'instance globale.

## Le morceau qui joue a changé ([constant AudioLibrary.SILENCE] : plus rien).
signal music_changed(track: StringName)

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_AMBIENCE: StringName = &"Ambience"
const BUS_SFX: StringName = &"Sfx"
const BUS_CRIES: StringName = &"Cries"
## Bus de `default_bus_layout.tres`, tous envoyés vers Master.
const BUSES: Array[StringName] = [BUS_MUSIC, BUS_AMBIENCE, BUS_SFX, BUS_CRIES]
## Lecteurs de bruitages [D].
const SFX_POOL_SIZE: int = 8
## Fondu enchaîné entre deux morceaux [D] : sortie 0,4 s, entrée 0,6 s, chevauchés.
const FADE_OUT: float = 0.4
const FADE_IN: float = 0.6
## Reprise de la zone après un combat (SON-6) [D].
const RESUME_FADE_IN: float = 1.0
## Changement d'ambiance [D].
const AMBIENCE_FADE: float = 1.0

## Reçoit chaque ordre à la place des lecteurs (tests) ; vide en jeu.
var sink: Callable = Callable()
## Données ; chargées au [method _ready] si elles n'ont pas été posées avant.
var library: AudioLibrary

var _stack := MusicStack.new()
var _sfx: SfxCatalog
var _cries: CryCatalog
var _music: Array[AudioStreamPlayer] = []
## Morceau posé sur chaque lecteur de musique.
var _music_tracks: Array[StringName] = [&"", &""]
var _music_fades: Array[Tween] = [null, null]
var _active: int = 0
var _ambience: AudioStreamPlayer
var _ambience_id: StringName = &""
var _ambience_fade: Tween
var _pool: Array[AudioStreamPlayer] = []
## Bruitage joué par chaque lecteur du pool ("" : libre).
var _pool_ids: Array[StringName] = []
var _cry: AudioStreamPlayer
## Bruitages et cris déjà chargés (courts) ; la musique, lue en flux, n'est pas gardée.
var _cache: Dictionary[String, AudioStream] = {}
## Fichiers absents déjà signalés.
var _warned: Dictionary[String, bool] = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# La musique continue pendant une pause de l'arbre (menus, cinématiques).
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	if library == null:
		library = AudioLibrary.new()
		library.load_dir()
	_sfx = SfxCatalog.new(library)
	_cries = CryCatalog.new(library)
	_rng.randomize()
	for i: int in 2:
		var player := _new_player("Music%s" % ["A", "B"][i], BUS_MUSIC)
		player.finished.connect(_on_music_finished.bind(i))
		_music.append(player)
	_ambience = _new_player("Ambience", BUS_AMBIENCE)
	for i: int in SFX_POOL_SIZE:
		var player := _new_player("Sfx%d" % i, BUS_SFX)
		player.finished.connect(_on_sfx_finished.bind(i))
		_pool.append(player)
		_pool_ids.append(&"")
	_cry = _new_player("Cry", BUS_CRIES)


## Ajoute les bus manquants (si `default_bus_layout.tres` n'a pas été lu), envoyés vers Master.
static func ensure_buses() -> void:
	for bus: StringName in BUSES:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, BUS_MASTER)


# --- Musique ---------------------------------------------------------------------------

## Pose [param track] sur la couche [param layer] (« silence » : rien ne joue sur cette
## couche ; "" : retire la couche).
func set_music(layer: MusicStack.Layer, track: StringName) -> void:
	_apply(_stack.set_layer(layer, track, _music_position()))


## Retire la couche [param layer] ; celle du dessous reprend à sa position.
func clear_music(layer: MusicStack.Layer) -> void:
	_apply(_stack.clear_layer(layer, _music_position()))


## Jingle (soin, objet, Badge…) : suspend la musique, qui reprend à la même position ensuite.
func play_jingle(track: StringName) -> void:
	set_music(MusicStack.Layer.JINGLE, track)


## Morceau qui joue (selon la pile, même sans fichier).
func current_track() -> StringName:
	return _stack.current_track()


## Morceau d'une couche ("" : vide).
func track_of(layer: MusicStack.Layer) -> StringName:
	return _stack.track_of(layer)


## Arrête toute la musique et vide les couches (retour à l'écran titre).
func stop_music() -> void:
	_stack.reset()
	for i: int in _music.size():
		_fade_music(i, VolumeMath.MUTED_DB, 0.0, true)
	_music_tracks = [&"", &""]
	_emit({ "type": &"music", "track": AudioLibrary.SILENCE, "position": 0.0,
		"resumed": false, "layer": -1 })
	music_changed.emit(AudioLibrary.SILENCE)


## Lecteur de musique actif (tests).
func get_music_player() -> AudioStreamPlayer:
	return _music[_active]


func get_music_players() -> Array[AudioStreamPlayer]:
	return _music


# --- Bruitages, cris, ambiance ---------------------------------------------------------

## Joue le bruitage [param id] (variante au hasard). Faux si l'identifiant est inconnu, s'il
## joue déjà `max_polyphony` fois ou si le pool est plein ; vrai sinon, même sans fichier.
func play_sfx(id: StringName, pitch: float = 1.0) -> bool:
	if not _sfx.can_play(id):
		return false
	var file := _sfx.pick_file(id, _rng)
	if _emit({ "type": &"sfx", "id": id, "file": file, "pitch": pitch }):
		return true
	var stream := _cached_stream(file, _sfx.is_expected(id))
	if stream == null:
		return true
	var slot := _pool_ids.find(&"")
	if slot < 0:
		return false
	var player := _pool[slot]
	player.stream = stream
	player.bus = _sfx.bus(id)
	player.volume_db = _sfx.volume_db(id)
	player.pitch_scale = pitch
	_pool_ids[slot] = id
	_sfx.started(id)
	player.play()
	return true


## Cri du numéro national [param dex] ; au K.O. ([param fainted]), plus grave. Faux si le
## numéro n'a pas de cri.
func play_cry(dex: int, fainted: bool = false) -> bool:
	var file := _cries.path_for(dex)
	if file.is_empty():
		return false
	var pitch := _cries.pitch(fainted)
	if _emit({ "type": &"cry", "dex": dex, "file": file, "pitch": pitch }):
		return true
	var stream := _cached_stream(file, _cries.is_expected())
	if stream != null:
		_cry.stream = stream
		_cry.bus = _cries.bus()
		_cry.volume_db = _cries.volume_db()
		_cry.pitch_scale = pitch
		_cry.play()
	return true


## Boucle d'ambiance [param id] ("" : aucune), en fondu.
func set_ambience(id: StringName) -> void:
	if id == _ambience_id:
		return
	if not id.is_empty() and not library.has_ambience(id):
		id = &""
		if id == _ambience_id:
			return
	_ambience_id = id
	if _emit({ "type": &"ambience", "id": id }):
		return
	if _ambience_fade != null and _ambience_fade.is_valid():
		_ambience_fade.kill()
	_ambience_fade = create_tween()
	if _ambience.playing:
		_ambience_fade.tween_property(_ambience, ^"volume_db", VolumeMath.MUTED_DB,
			AMBIENCE_FADE * 0.5)
	_ambience_fade.tween_callback(_start_ambience.bind(id))


func current_ambience() -> StringName:
	return _ambience_id


# --- Volumes ---------------------------------------------------------------------------

## Volumes des curseurs des Paramètres (0 à 1) : Musique ; Effets (bruitages et ambiances) ;
## Cris. 0 coupe le bus.
func apply_volumes(music: float, sfx: float, cries: float) -> void:
	_set_bus_volume(BUS_MUSIC, music)
	_set_bus_volume(BUS_AMBIENCE, sfx)
	_set_bus_volume(BUS_SFX, sfx)
	_set_bus_volume(BUS_CRIES, cries)


func apply_settings(settings: GameSettings) -> void:
	apply_volumes(settings.music_volume, settings.sfx_volume, settings.cry_volume)


# --- Privé -----------------------------------------------------------------------------

func _new_player(player_name: String, bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus
	add_child(player)
	return player


## Passe [param order] à l'espion ; vrai s'il y en a un (rien ne doit alors être joué).
func _emit(order: Dictionary) -> bool:
	if not sink.is_valid():
		return false
	sink.call(order)
	return true


func _apply(change: MusicStack.Change) -> void:
	if not change.changed:
		return
	var spied := _emit({ "type": &"music", "track": change.track,
		"position": change.position, "resumed": change.resumed, "layer": change.layer })
	var jingle := library.is_jingle(change.track)
	# Un jingle coupe net (RB) ; une reprise après un combat revient en 1 s (SON-6).
	var fade_out := 0.0 if jingle and not change.resumed else FADE_OUT
	var fade_in := FADE_IN
	if change.resumed and change.previous_layer == MusicStack.Layer.BATTLE:
		fade_in = RESUME_FADE_IN
	elif jingle:
		fade_in = 0.0
	var playing := _crossfade(change.track, change.position, fade_out, fade_in, spied)
	music_changed.emit(change.track)
	if jingle and not playing and _stack.track_of(MusicStack.Layer.JINGLE) == change.track:
		# Muet tolérant : un jingle sans fichier se termine tout de suite.
		clear_music(MusicStack.Layer.JINGLE)


## Fondu enchaîné vers [param track] ; vrai si un fichier joue vraiment.
func _crossfade(track: StringName, position: float, fade_out: float, fade_in: float,
		spied: bool) -> bool:
	_fade_music(_active, VolumeMath.MUTED_DB, fade_out, true)
	_active = 1 - _active
	var player := _music[_active]
	_kill_fade(_active)
	player.stop()
	player.stream = null
	_music_tracks[_active] = track
	if track == AudioLibrary.SILENCE or spied:
		return false
	var info := library.track(track)
	var stream := _load_stream(info.get("file", ""), info.get("expected", false))
	if stream == null:
		return false
	if &"loop" in stream:
		stream.set(&"loop", info.get("loop", true))
	if &"loop_offset" in stream:
		stream.set(&"loop_offset", info.get("loop_offset", 0.0))
	var target: float = info.get("volume_db", 0.0)
	player.stream = stream
	player.volume_db = VolumeMath.MUTED_DB if fade_in > 0.0 else target
	player.play(position)
	_fade_music(_active, target, fade_in)
	var cut: float = info.get("fade_out_after", 0.0)
	if cut > 0.0:
		# Victoire contre un sauvage (SON-14 A) : la piste se tait d'elle-même après ~4 s.
		_music_fades[_active].tween_interval(cut)
		_music_fades[_active].tween_property(player, ^"volume_db", VolumeMath.MUTED_DB, FADE_OUT)
	return true


## Amène le lecteur [param index] à [param volume_db] en [param duration] s (0 : tout de suite) ;
## [param stop_after] : l'arrête à la fin.
func _fade_music(index: int, volume_db: float, duration: float, stop_after: bool = false) -> void:
	_kill_fade(index)
	var player := _music[index]
	var tween := create_tween()
	if duration > 0.0 and player.playing:
		tween.tween_property(player, ^"volume_db", volume_db, duration)
	else:
		player.volume_db = volume_db
		tween.tween_interval(0.0)
	if stop_after:
		tween.tween_callback(player.stop)
	_music_fades[index] = tween


func _kill_fade(index: int) -> void:
	var tween := _music_fades[index]
	if tween != null and tween.is_valid():
		tween.kill()
	_music_fades[index] = null


func _music_position() -> float:
	var player := _music[_active]
	return player.get_playback_position() if player.playing else 0.0


func _on_music_finished(index: int) -> void:
	if index == _active and library.is_jingle(_music_tracks[index]) \
			and _stack.track_of(MusicStack.Layer.JINGLE) == _music_tracks[index]:
		clear_music(MusicStack.Layer.JINGLE)


func _on_sfx_finished(slot: int) -> void:
	if _pool_ids[slot].is_empty():
		return
	_sfx.finished(_pool_ids[slot])
	_pool_ids[slot] = &""


func _start_ambience(id: StringName) -> void:
	_ambience.stop()
	_ambience.stream = null
	if id.is_empty():
		return
	var info := library.ambience(id)
	var stream := _load_stream(info.get("file", ""), info.get("expected", false))
	if stream == null:
		return
	if &"loop" in stream:
		stream.set(&"loop", true)
	_ambience.stream = stream
	_ambience.volume_db = VolumeMath.MUTED_DB
	_ambience.play()
	_ambience_fade = create_tween()
	_ambience_fade.tween_property(_ambience, ^"volume_db", info.get("volume_db", 0.0),
		AMBIENCE_FADE)


func _cached_stream(path: String, expected: bool) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var stream := _load_stream(path, expected)
	if stream != null:
		_cache[path] = stream
	return stream


## Flux de [param path], ou null s'il manque (signalé une fois s'il n'est pas « attendu »).
func _load_stream(path: String, expected: bool) -> AudioStream:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		if not expected and not _warned.has(path):
			_warned[path] = true
			if OS.is_debug_build():
				print("Audio : fichier absent, silence : %s" % path)
		return null
	return load(path) as AudioStream


func _set_bus_volume(bus: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, VolumeMath.is_muted(volume))
	AudioServer.set_bus_volume_db(index, VolumeMath.to_db(volume))
