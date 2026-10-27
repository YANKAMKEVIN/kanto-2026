class_name MoveFxPlan
extends RefCounted
## Chorégraphie calculée d'une attaque (chantier Combat vivant, `docs/tech/combat-vivant.md`
## §2.3, §2.6, §3.1). Pure et déterministe : le lecteur d'effets (T3) l'exécute, les tests la
## lisent sans scène.
##
## - **Phases** (§3.1) : anticipation, trajet, impact, retour, l'une après l'autre ; une attaque
##   à coups multiples ajoute trajet, impact et retour par coup en plus. Un raté remplace
##   l'impact par `miss`, un type immunisé par `no_effect` ; un échec ne garde que
##   l'anticipation et le retour ; le tour 1 d'une attaque à deux tours est une phase `charge`.
## - **Repères sonores** (§2.5) : `launch` (début du trajet, ou 0 sans trajet), `impact`,
##   `impact_2`… (début de chaque impact), `miss`, `no_effect`, `charge`.
## - **Durée** (CV-2, décision de Kevin) : Complètes selon la puissance (`durations.bands` de
##   `families.json`) ; chaque coup d'une attaque à coups multiples prend la première ligne ;
##   K.O. en un coup, Explosion / Destruction et légendaires prennent la dernière. Rapides et
##   Réduites : ≤ 0,5 s pour toute l'attaque, sans anticipation ni caméra.
## - **Réduites** (« Réduire les animations », CV-5) : comme Rapides, sans aucune secousse,
##   particules réduites de moitié. « Réduire les flashs » plafonne la lumière (0,35) ; jamais
##   plus de 3 flashs par seconde, quel que soit le mode.
## Les durées sont nominales : le lecteur les multiplie par `speed_scale` (0 = instantané).

enum Mode { FULL, FAST, REDUCED }

const ANTICIPATION: StringName = &"anticipation"
const TRAVEL: StringName = &"travel"
const IMPACT: StringName = &"impact"
const RETURN: StringName = &"return"
const MISS: StringName = &"miss"
const NO_EFFECT: StringName = &"no_effect"
const CHARGE: StringName = &"charge"
const CUE_LAUNCH: StringName = &"launch"
const CUE_IMPACT: StringName = &"impact"
const CUE_MISS: StringName = &"miss"
const CUE_NO_EFFECT: StringName = &"no_effect"
const CUE_CHARGE: StringName = &"charge"
const TARGET_SELF: StringName = &"self"
## Point d'origine par défaut ([FxAnchors]) : lanceur entier (contact, soi-même) ou bouche.
const ORIGIN_BODY: StringName = &"centre"
const ORIGIN_MOUTH: StringName = &"bouche"
## Particules d'un éclat d'impact si la famille n'en dit rien.
const DEFAULT_PARTICLES: int = 20
## Pour les comparaisons de durées (flottants).
const EPSILON: float = 0.0001


## Une phase : [member name], début et durée en secondes ; [member hit] : rang du coup (0 = le
## premier).
class Phase:
	extends RefCounted
	var name: StringName
	var start: float
	var duration: float
	var hit: int

	func _init(phase_name: StringName, phase_start: float, phase_duration: float,
			phase_hit: int) -> void:
		name = phase_name
		start = phase_start
		duration = phase_duration
		hit = phase_hit

	func end() -> float:
		return start + duration


## Un repère sonore : [member cue] à [member time] secondes du début.
class Cue:
	extends RefCounted
	var cue: StringName
	var time: float

	func _init(cue_name: StringName, cue_time: float) -> void:
		cue = cue_name
		time = cue_time


var move_id: StringName = &""
var family: StringName = &""
var impact: StringName = &""
var modifiers: Array[StringName] = []
var signature: StringName = &""
var mode: Mode = Mode.FULL
## Ligne du tableau de CV-2 (0 à 3) ; -1 pour un tour de charge.
var band: int = 0
## Durée totale, et durée d'un coup (= totale sauf coups multiples).
var duration: float = 0.0
var hit_duration: float = 0.0
var hits: int = 1
var phases: Array[Phase] = []
var cues: Array[Cue] = []
## L'effet se joue sur le lanceur (statut positif, soin).
var on_self: bool = false
## Point d'origine demandé ([FxAnchors] fait le repli).
var origin: StringName = ORIGIN_BODY
## Caméra (CV-3) : zoom (1 = aucun) et tremblement en px, déjà plafonnés.
var camera_zoom: float = 1.0
var camera_shake: float = 0.0
## La cible tremble à l'impact (faux en Réduites).
var target_shake: bool = true
## Lumière simulée du décor (CV-6) : couleur, intensité (0..1), nombre d'éclats.
var light_color: Color = Color.WHITE
var light_peak: float = 0.0
var flashes: int = 0
## « Réduire les flashs » : le lecteur n'éclaircit pas la cible au coup (assombrit à la place).
var reduce_flashes: bool = false
## Facteur du nombre de particules (0,5 en Réduites).
var particle_scale: float = 1.0
## Dégradé des effets (`fx.palette` de la famille, §2.9 : cœur, couleur de l'élément, bord) ;
## repli : la couleur de la lumière.
var palette: PackedColorArray = PackedColorArray()
## Particules d'un éclat d'impact, facteur des Réduites compris (`fx.particles`).
var particles: int = 0
## Briques de la famille (`bricks` : `launch`, `travel`, `impact`), pour le lecteur d'effets.
var bricks: Dictionary = {}
## Réactions du monde autres que la lumière (Complètes seulement) : `dust`, `droplets`,
## `foliage`, `darken`.
var world: Array[StringName] = []
## Art peint (CV.1, [FxArt]) par rôle : `charge`, `travel`, `bolt`, `impact`, `particle`, `rise`,
## `fallout`, `dust`, `stamp` (marque d'impact du Contact), `cheeks`, `feathers` (Éclair) ; la
## famille, puis la variante d'impact, puis la signature. Rôle absent : forme dessinée en code.
var art: Dictionary[StringName, StringName] = {}
## Types de la cible (Éclair : plumes sur un Pokémon Vol) ; rempli par la scène, vide sinon.
var target_types: Array[StringName] = []
## Issue lue dans le journal (null : un coup qui porte) ; le son du coup en dépend (T4).
var outcome: MoveFxOutcome


## Mode d'animation d'après les réglages : « Réduire les animations » l'emporte (CV-5).
static func mode_for(animations: GameSettings.BattleAnimations, reduce_motion: bool) -> Mode:
	if reduce_motion:
		return Mode.REDUCED
	return Mode.FAST if animations == GameSettings.BattleAnimations.FAST else Mode.FULL


## Chorégraphie de [param move] (effet [param entry]) selon son issue [param outcome] (null :
## un coup qui porte). [param legendary] : le lanceur est un légendaire (dernière ligne de CV-2).
static func build(catalog: MoveFxCatalog, entry: MoveFxEntry, move: MoveData,
		outcome: MoveFxOutcome, plan_mode: Mode, reduce_flashes: bool = false,
		legendary: bool = false) -> MoveFxPlan:
	var plan := MoveFxPlan.new()
	plan.outcome = outcome
	plan._setup(catalog, entry, plan_mode)
	var result := MoveFxOutcome.Result.HIT if outcome == null else outcome.result
	var family_data := catalog.family(plan.family)
	if result == MoveFxOutcome.Result.CHARGING:
		plan._layout_charge(catalog)
	else:
		var multi := entry.has_modifier(&"multi")
		plan.hits = maxi(1, outcome.hits) if multi and outcome != null else 1
		plan.band = band_for(catalog, entry, move, legendary)
		var full_hit := full_hit_duration(catalog, entry, move, legendary)
		plan._layout(catalog, family_data, full_hit, result)
	plan._camera(catalog, family_data, outcome, result)
	plan._light(catalog, family_data, result, reduce_flashes)
	return plan


## Ligne du tableau de CV-2 de l'attaque (0 à 3).
static func band_for(catalog: MoveFxCatalog, entry: MoveFxEntry, move: MoveData,
		legendary: bool = false) -> int:
	var bands := _bands(catalog)
	if bands.is_empty():
		return 0
	if legendary or _band_max(catalog, entry):
		return bands.size() - 1
	if entry.has_modifier(&"multi") or not move.is_damaging():
		return 0
	for i: int in bands.size():
		if move.power <= JsonFields.get_int(bands[i], "power_max"):
			return i
	return bands.size() - 1


## Durée d'un coup en Complètes (CV-2) : la puissance placée dans sa ligne.
static func full_hit_duration(catalog: MoveFxCatalog, entry: MoveFxEntry, move: MoveData,
		legendary: bool = false) -> float:
	var bands := _bands(catalog)
	if bands.is_empty():
		return 0.0
	var line: Dictionary = bands[band_for(catalog, entry, move, legendary)]
	var low := JsonFields.get_float(line, "min")
	var high := JsonFields.get_float(line, "max")
	var position := JsonFields.get_float(catalog.durations(), "status_position", 0.5)
	if move.is_damaging():
		var power_min := JsonFields.get_float(line, "power_min")
		var power_max := JsonFields.get_float(line, "power_max")
		position = 0.0 if power_max <= power_min \
			else clampf((move.power - power_min) / (power_max - power_min), 0.0, 1.0)
	return lerpf(low, high, position)


## Phase nommée [param phase_name] du coup [param hit], ou null.
func phase(phase_name: StringName, hit: int = 0) -> Phase:
	for item: Phase in phases:
		if item.name == phase_name and item.hit == hit:
			return item
	return null


## Instant du repère [param cue_name] (-1 s'il n'y en a pas).
func cue_time(cue_name: StringName) -> float:
	for item: Cue in cues:
		if item.cue == cue_name:
			return item.time
	return -1.0


func cue_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for item: Cue in cues:
		names.append(item.cue)
	return names


## Nom du repère d'impact du coup [param hit] : `impact`, `impact_2`, `impact_3`…
static func impact_cue(hit: int) -> StringName:
	return CUE_IMPACT if hit == 0 else StringName("%s_%d" % [CUE_IMPACT, hit + 1])


func _setup(catalog: MoveFxCatalog, entry: MoveFxEntry, plan_mode: Mode) -> void:
	move_id = entry.move_id
	family = entry.family
	impact = entry.impact
	modifiers = entry.modifiers.duplicate()
	signature = entry.signature
	mode = plan_mode
	var family_data := catalog.family(family)
	on_self = JsonFields.get_id(family_data, "target") == TARGET_SELF
	var signature_origin := JsonFields.get_id(catalog.signature(signature), "origin")
	if not signature_origin.is_empty():
		origin = signature_origin
	elif on_self or family == MoveFxCatalog.CONTACT_FAMILY:
		origin = ORIGIN_BODY
	else:
		origin = ORIGIN_MOUTH
	particle_scale = JsonFields.get_float(catalog.limits(), "reduced_particles", 0.5) \
		if mode == Mode.REDUCED else 1.0
	target_shake = mode != Mode.REDUCED
	bricks = JsonFields.get_dict(family_data, "bricks")
	var fx := JsonFields.get_dict(family_data, "fx")
	particles = roundi(JsonFields.get_int(fx, "particles", DEFAULT_PARTICLES) * particle_scale)
	for color: Variant in JsonFields.get_array(fx, "palette"):
		if color is String:
			palette.append(Color.from_string(color, Color.WHITE))
	_read_art(JsonFields.get_dict(fx, "art"))
	var stamp := JsonFields.get_id(catalog.impact(impact), "art")
	if not stamp.is_empty():
		art[&"stamp"] = stamp
	_read_art(JsonFields.get_dict(catalog.signature(signature), "art"))


func _read_art(raw: Dictionary) -> void:
	for role: String in raw:
		if raw[role] is String:
			art[StringName(role)] = StringName(raw[role])


func _layout_charge(catalog: MoveFxCatalog) -> void:
	band = -1
	var charge := JsonFields.get_dict(catalog.durations(), "charge_turn")
	duration = JsonFields.get_float(charge, "full" if mode == Mode.FULL else "fast")
	hit_duration = duration
	phases.append(Phase.new(CHARGE, 0.0, duration, 0))
	cues.append(Cue.new(CUE_CHARGE, 0.0))


func _layout(catalog: MoveFxCatalog, family_data: Dictionary, full_hit: float,
		result: MoveFxOutcome.Result) -> void:
	var parts := JsonFields.get_dict(family_data, "phases")
	var anticipation := JsonFields.get_float(parts, "anticipation")
	var travel := JsonFields.get_float(parts, "travel")
	var strike := JsonFields.get_float(parts, "impact")
	var back := JsonFields.get_float(parts, "return")
	if result == MoveFxOutcome.Result.FAILED:
		# Rien ne part : le lanceur se prépare, puis revient (première ligne de CV-2).
		var shortest := JsonFields.get_float(_bands(catalog)[0], "min") if not _bands(catalog).is_empty() \
			else full_hit
		duration = _mode_duration(catalog, shortest)
		hit_duration = duration
		var total := anticipation + back
		var first := anticipation / total if total > EPSILON else 0.5
		phases.append(Phase.new(ANTICIPATION, 0.0, duration * first, 0))
		phases.append(Phase.new(RETURN, duration * first, duration * (1.0 - first), 0))
		return
	if mode != Mode.FULL:
		anticipation = 0.0
	if hits == 1:
		duration = _mode_duration(catalog, full_hit)
		hit_duration = duration
	else:
		duration = _mode_duration(catalog, full_hit * hits)
		hit_duration = duration / hits
	var strike_name := IMPACT
	match result:
		MoveFxOutcome.Result.MISSED, MoveFxOutcome.Result.DODGED:
			strike_name = MISS
		MoveFxOutcome.Result.NO_EFFECT:
			strike_name = NO_EFFECT
	var time := 0.0
	for hit: int in hits:
		var weights := [anticipation if hit == 0 else 0.0, travel, strike, back]
		var names: Array[StringName] = [ANTICIPATION, TRAVEL, strike_name, RETURN]
		var sum := 0.0
		for weight: float in weights:
			sum += weight
		for i: int in names.size():
			var length: float = hit_duration * weights[i] / sum if sum > EPSILON else 0.0
			if length <= EPSILON:
				continue
			if names[i] == TRAVEL and hit == 0:
				cues.append(Cue.new(CUE_LAUNCH, time))
			elif names[i] == strike_name:
				if hit == 0 and cue_time(CUE_LAUNCH) < 0.0:
					cues.append(Cue.new(CUE_LAUNCH, 0.0))
				cues.append(Cue.new(_strike_cue(strike_name, hit), time))
			phases.append(Phase.new(names[i], time, length, hit))
			time += length
	duration = time


func _strike_cue(strike_name: StringName, hit: int) -> StringName:
	match strike_name:
		MISS:
			return CUE_MISS if hit == 0 else StringName("%s_%d" % [CUE_MISS, hit + 1])
		NO_EFFECT:
			return CUE_NO_EFFECT
	return impact_cue(hit)


## Durée de l'attaque selon le mode : Complètes telle quelle ; Rapides et Réduites compressées
## et bornées (`durations.fast` : ≤ 0,5 s).
func _mode_duration(catalog: MoveFxCatalog, full: float) -> float:
	if mode == Mode.FULL:
		return full
	var fast := JsonFields.get_dict(catalog.durations(), "fast")
	return clampf(full * JsonFields.get_float(fast, "ratio", 0.4),
		JsonFields.get_float(fast, "min", 0.3), JsonFields.get_float(fast, "max", 0.5))


func _camera(catalog: MoveFxCatalog, family_data: Dictionary, outcome: MoveFxOutcome,
		result: MoveFxOutcome.Result) -> void:
	if mode != Mode.FULL:
		return
	var limits := catalog.limits()
	var camera := JsonFields.get_dict(family_data, "camera")
	camera_zoom = JsonFields.get_float(camera, "zoom", 1.0)
	var lands := result == MoveFxOutcome.Result.HIT or result == MoveFxOutcome.Result.AFFECTED
	camera_shake = JsonFields.get_float(camera, "shake") if lands else 0.0
	if outcome != null and outcome.critical:
		camera_zoom += JsonFields.get_float(limits, "critical_zoom")
		camera_shake *= JsonFields.get_float(limits, "critical_shake", 1.0)
	camera_zoom = clampf(camera_zoom, 1.0, JsonFields.get_float(limits, "zoom_max", 1.0))
	camera_shake = clampf(camera_shake, 0.0, JsonFields.get_float(limits, "shake_max", 0.0))


func _light(catalog: MoveFxCatalog, family_data: Dictionary, result: MoveFxOutcome.Result,
		reduce_flashes: bool) -> void:
	var limits := catalog.limits()
	self.reduce_flashes = reduce_flashes
	var data := JsonFields.get_dict(family_data, "world")
	light_color = Color.from_string(JsonFields.get_string(data, "light", "#FFFFFF"), Color.WHITE)
	light_peak = JsonFields.get_float(data, "light_peak")
	var own := catalog.signature(signature)
	light_peak = JsonFields.get_float(own, "light_peak", light_peak)
	if palette.is_empty():
		palette = PackedColorArray([Color.WHITE, light_color, light_color.darkened(0.5)])
	if reduce_flashes:
		light_peak = minf(light_peak, JsonFields.get_float(limits, "reduced_flash_peak", 0.35))
	var lands := result == MoveFxOutcome.Result.HIT or result == MoveFxOutcome.Result.AFFECTED
	flashes = JsonFields.get_int(own, "flashes", JsonFields.get_int(data, "flashes")) * hits \
		if lands and light_peak > 0.0 else 0
	var per_second := JsonFields.get_float(limits, "flashes_per_second", 3.0)
	flashes = mini(flashes, floori(per_second * duration + EPSILON))
	if mode == Mode.FULL and lands:
		for flag: StringName in [&"dust", &"droplets", &"foliage", &"darken"]:
			if JsonFields.get_bool(data, String(flag)):
				world.append(flag)


static func _bands(catalog: MoveFxCatalog) -> Array:
	return JsonFields.get_array(catalog.durations(), "bands")


static func _band_max(catalog: MoveFxCatalog, entry: MoveFxEntry) -> bool:
	for modifier: StringName in entry.modifiers:
		if JsonFields.get_bool(catalog.modifier(modifier), "band_max"):
			return true
	return false
