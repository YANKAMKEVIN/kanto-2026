class_name FluteNotes
extends Node2D
## Notes de la Poké Flûte au-dessus du joueur (jalon 21, `jalon-21.md` §2.3, T19) : trois notes
## peintes (série 23, `poke_flute_note_1..4`) montent l'une après l'autre en ondulant, puis
## s'effacent (≈ 1,5 s). Présentation pure, modèle de [RubbleBurst] : un seul [Tween], le nœud
## se libère à la fin ([method play]). « Réduire les animations » : aucune note (l'appelant ne
## crée pas le nœud, [method CutsceneDirector.play_flute_notes]).

## Fin des notes (juste avant la libération du nœud).
signal finished

## Nombre de notes et durée totale (s) [D].
const NOTE_COUNT: int = 3
const DURATION: float = 1.5
## Images des notes (série 23) ; la n-ième note prend la n-ième image.
const TEXTURE_PATHS: Array[String] = [
	"res://assets/sprites/effects/poke_flute_note_1.png",
	"res://assets/sprites/effects/poke_flute_note_2.png",
	"res://assets/sprites/effects/poke_flute_note_3.png",
	"res://assets/sprites/effects/poke_flute_note_4.png",
]
## Hauteur affichée d'une note (px monde ; les images font 120 px) [D].
const NOTE_HEIGHT: float = 56.0
## Départ au-dessus des pieds du joueur (sa tête, personnages de 128 px) et montée (px) [D].
const START_HEIGHT: float = 150.0
const RISE: float = 90.0
## Écart latéral entre les notes et amplitude de l'ondulation (px) [D].
const SPREAD: float = 36.0
const SWAY: float = 10.0
## Part de [constant DURATION] que dure chaque note (elles se chevauchent) [D].
const NOTE_SHARE: float = 0.6

var _notes: Array[Sprite2D] = []


## Crée les notes au-dessus de [param player] (frère du joueur : elles ne bougent pas avec lui).
## Null si le joueur n'a pas de parent.
static func spawn_over(player: Node2D) -> FluteNotes:
	var parent := player.get_parent() if player != null else null
	if parent == null:
		return null
	var notes := FluteNotes.new()
	notes.name = "FluteNotes"
	parent.add_child(notes)
	notes.global_position = player.global_position
	return notes


func _init() -> void:
	# Au-dessus du voile d'obscurité et des cimes, comme les bulles « ♪ » (WorldLighting).
	z_as_relative = false
	z_index = WorldLighting.Z_ABOVE_VEIL
	for i: int in NOTE_COUNT:
		var note := Sprite2D.new()
		note.name = "Note%d" % (i + 1)
		var texture := load(TEXTURE_PATHS[i % TEXTURE_PATHS.size()]) as Texture2D
		note.texture = texture
		if texture != null:
			note.scale = Vector2.ONE * (NOTE_HEIGHT / float(texture.get_height()))
		note.modulate.a = 0.0
		add_child(note)
		_notes.append(note)
	_apply(0.0)


## Notes dessinées (tests).
func get_notes() -> Array[Sprite2D]:
	return _notes


## Coroutine : joue les notes ([constant DURATION]) puis se libère. [param speed_scale] = 0 :
## instantané (tests).
func play(speed_scale: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_method(_apply, 0.0, 1.0, DURATION)
	if speed_scale <= 0.0:
		tween.custom_step(1000.0)
	else:
		tween.set_speed_scale(speed_scale)
	if tween.is_valid() and tween.is_running():
		await tween.finished
	finished.emit()
	queue_free()


## Progression [param t] de 0 à 1 : la note n part à n / (NOTE_COUNT) de la part libre, monte en
## ondulant, apparaît vite et s'efface sur sa fin.
func _apply(t: float) -> void:
	var gap := (1.0 - NOTE_SHARE) / maxf(1.0, float(NOTE_COUNT - 1))
	for i: int in _notes.size():
		var local := clampf((t - gap * i) / NOTE_SHARE, 0.0, 1.0)
		var x := (float(i) - float(NOTE_COUNT - 1) / 2.0) * SPREAD
		var note := _notes[i]
		note.position = Vector2(x + sin(local * TAU) * SWAY, -START_HEIGHT - RISE * local)
		var alpha := 0.0
		if local > 0.0 and local < 1.0:
			alpha = minf(1.0, local / 0.2) * minf(1.0, (1.0 - local) / 0.4)
		note.modulate.a = alpha
