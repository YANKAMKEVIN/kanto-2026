class_name IntroTimeline
extends RefCounted
## Partition de l'ident de démarrage (J34, demande de Kevin du 2026-11-03, « à la Netflix ») :
## un carton « Les studios Kevin & Co vous présentent », puis les lettres du logo qui entrent une à
## une depuis la droite pour former « POKEMAKE », le filet qui se trace, le halo qui s'allume, puis
## le fondu vers l'écran titre. Logique pure : la scène ([IdentSequence]) ne fait que jouer les
## repères rendus ici. Toutes les durées sont en secondes, avant [member speed_scale] de la scène.
##
## Un repère : `{"id": StringName, "start": float, "duration": float, "index": int}` (index : la
## lettre, -1 sinon). Les ids : `card_in`, `card_out`, `letter` (× lettres), `rule`, `glow`,
## `logo_in` (version réduite seulement), `fade_out`.

const CARD_IN: StringName = &"card_in"
const CARD_OUT: StringName = &"card_out"
const LETTER: StringName = &"letter"
const RULE: StringName = &"rule"
const GLOW: StringName = &"glow"
const LOGO_IN: StringName = &"logo_in"
const FADE_OUT: StringName = &"fade_out"

## Version complète [D] : carton 0,6 s d'entrée, 1,6 s de tenue, 0,5 s de sortie ; 0,3 s de noir ;
## lettres toutes les 0,14 s, 0,55 s de trajet chacune ; filet 0,4 s ; halo 0,5 s ; tenue 0,9 s ;
## fondu de sortie 0,6 s (≈ 7 s pour 8 lettres).
const FULL := {
	"card_in": 0.6, "card_hold": 1.6, "card_out": 0.5, "gap": 0.3,
	"letter_stagger": 0.14, "letter_travel": 0.55,
	"rule": 0.4, "glow": 0.5, "hold": 0.9, "fade_out": 0.6,
}
## « Réduire les animations » [D] : carton plus court, le logo entier apparaît en fondu, pas de
## lettres en mouvement (≈ 3,2 s).
const REDUCED := {
	"card_in": 0.4, "card_hold": 1.0, "card_out": 0.3, "gap": 0.2,
	"logo_in": 0.5, "hold": 0.6, "fade_out": 0.4,
}


## Les repères, dans l'ordre, pour [param letter_count] lettres.
static func build(letter_count: int, reduced: bool = false) -> Array[Dictionary]:
	var cues: Array[Dictionary] = []
	var d: Dictionary = REDUCED if reduced else FULL
	var t: float = 0.0
	cues.append(_cue(CARD_IN, t, d["card_in"]))
	t += d["card_in"] + d["card_hold"]
	cues.append(_cue(CARD_OUT, t, d["card_out"]))
	t += d["card_out"] + d["gap"]
	if reduced:
		cues.append(_cue(LOGO_IN, t, d["logo_in"]))
		t += d["logo_in"]
	else:
		for i: int in letter_count:
			cues.append(_cue(LETTER, t + i * d["letter_stagger"], d["letter_travel"], i))
		t += maxf(letter_count - 1, 0) * d["letter_stagger"] + d["letter_travel"]
		cues.append(_cue(RULE, t, d["rule"]))
		t += d["rule"]
		cues.append(_cue(GLOW, t, d["glow"]))
		t += d["glow"]
	t += d["hold"]
	cues.append(_cue(FADE_OUT, t, d["fade_out"]))
	return cues


## Fin du dernier repère : durée totale de l'ident.
static func total(cues: Array[Dictionary]) -> float:
	var end: float = 0.0
	for cue: Dictionary in cues:
		end = maxf(end, cue["start"] + cue["duration"])
	return end


## Le repère [param id] (et [param index] pour une lettre) ; vide s'il n'existe pas.
static func find(cues: Array[Dictionary], id: StringName, index: int = -1) -> Dictionary:
	for cue: Dictionary in cues:
		if cue["id"] == id and cue["index"] == index:
			return cue
	return {}


## Instant où le logo est entièrement formé (fin du halo, ou du fondu du logo réduit) : point
## d'arrivée d'un passage (« passer » saute ici).
static func logo_formed_at(cues: Array[Dictionary]) -> float:
	var glow := find(cues, GLOW)
	if glow.is_empty():
		glow = find(cues, LOGO_IN)
	return glow["start"] + glow["duration"] if not glow.is_empty() else 0.0


static func _cue(id: StringName, start: float, duration: float, index: int = -1) -> Dictionary:
	return {"id": id, "start": start, "duration": duration, "index": index}
