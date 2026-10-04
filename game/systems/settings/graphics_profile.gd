class_name GraphicsProfile
extends RefCounted
## Profil graphique résolu (Q-17, dossier 08 §7 : « le joueur choisit une intention, le moteur
## choisit les détails »). Classe pure.
##
## Le joueur choisit Auto (défaut), Élevée ou Économie ([enum GameSettings.Graphics]) ; ce
## profil dit ce que cela veut dire pour le moteur. **Auto** se résout selon l'appareil
## ([method auto_quality]) : un appareil puissant (le S24 : 8 cœurs, 8 Go) → Élevée.
## **Économie** : 30 images par seconde ([member max_fps]), flou du fond du menu coupé
## ([member menu_blur]), autres effets coûteux réduits ([member reduced_effects], la liste est
## celle de `Boot._apply_settings`, T29). Aucune autre option technique.

## Images par seconde en Économie (`Engine.max_fps`).
const ECO_MAX_FPS: int = 30
## Auto : sous ces seuils (connus), l'appareil passe en Économie. Une valeur inconnue (0) ne
## compte pas.
const AUTO_MIN_PROCESSORS: int = 6
const AUTO_MIN_MEMORY_MB: int = 4096
## Clés de la description d'appareil ([method current_device]).
const DEVICE_PROCESSORS: String = "processors"
const DEVICE_MEMORY_MB: String = "memory_mb"

## HIGH ou ECO, jamais AUTO.
var quality: GameSettings.Graphics = GameSettings.Graphics.HIGH
## Vrai si le joueur a laissé Auto (l'écran peut écrire « Auto (Élevée) »).
var auto: bool = false
## `Engine.max_fps` : 0 = pas de limite (le comportement d'avant le J6).
var max_fps: int = 0
## Flou du fond du Menu Dresseur.
var menu_blur: bool = true
## Effets coûteux réduits.
var reduced_effects: bool = false


## Profil de [param choice] sur l'appareil [param device] (voir [method current_device]).
static func resolve(choice: GameSettings.Graphics, device: Dictionary) -> GraphicsProfile:
	var profile := GraphicsProfile.new()
	profile.auto = choice == GameSettings.Graphics.AUTO
	profile.quality = auto_quality(device) if profile.auto else choice
	var eco := profile.quality == GameSettings.Graphics.ECO
	profile.max_fps = ECO_MAX_FPS if eco else 0
	profile.menu_blur = not eco
	profile.reduced_effects = eco
	return profile


## Qualité choisie par Auto pour [param device] : Économie si l'appareil a moins de
## [constant AUTO_MIN_PROCESSORS] cœurs ou moins de [constant AUTO_MIN_MEMORY_MB] Mo de
## mémoire (valeurs connues seulement), sinon Élevée.
static func auto_quality(device: Dictionary) -> GameSettings.Graphics:
	var processors := JsonFields.get_int(device, DEVICE_PROCESSORS, 0)
	var memory := JsonFields.get_int(device, DEVICE_MEMORY_MB, 0)
	if processors > 0 and processors < AUTO_MIN_PROCESSORS:
		return GameSettings.Graphics.ECO
	if memory > 0 and memory < AUTO_MIN_MEMORY_MB:
		return GameSettings.Graphics.ECO
	return GameSettings.Graphics.HIGH


## Description de l'appareil courant : { "processors": int, "memory_mb": int } (0 = inconnu).
## Seule fonction qui interroge le système (Boot, T29).
static func current_device() -> Dictionary:
	var memory: Variant = OS.get_memory_info().get("physical", -1)
	var memory_mb := 0
	if (memory is int or memory is float) and float(memory) > 0.0:
		memory_mb = int(float(memory) / (1024.0 * 1024.0))
	return {
		DEVICE_PROCESSORS: OS.get_processor_count(),
		DEVICE_MEMORY_MB: memory_mb,
	}
