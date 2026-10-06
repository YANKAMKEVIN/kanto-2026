extends Node
## Visite du prototype sur le S24 : toucher l'écran passe d'un lieu au suivant (Bourg
## Palette et ses intérieurs, Jadielle, Route 22, place, Centre, Boutique).

const LIEUX := ["route1", "route1_avant", "bourg", "chambre", "rdc", "rival", "labo", "ville", "route22", "place", "centre", "boutique"]
const NOMS := {"bourg": "Bourg Palette (la caméra fait le tour)", "chambre": "Chambre du joueur", "rdc": "Maison du joueur — rez-de-chaussée", "rival": "Maison du rival", "labo": "Laboratoire de Chen", "route1": "Route 1 — NOUVELLE forêt (la caméra remonte la route)", "route1_avant": "Route 1 — ancienne forêt, pour comparer", "route22": "Route 22 (la caméra fait le tour)", "ville": "Jadielle entière (la caméra fait le tour)", "place": "Place de Jadielle (lumière C2)", "centre": "Centre Pokémon — intérieur",
	"boutique": "Boutique — intérieur"}

var _index := 0
var _lieu: Node
var _etiquette := Label.new()
var _chrono := 0.0


func _ready() -> void:
	var calque := CanvasLayer.new()
	calque.layer = 10
	_etiquette.position = Vector2(32, 24)
	_etiquette.add_theme_font_size_override(&"font_size", 34)
	_etiquette.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	_etiquette.add_theme_constant_override(&"outline_size", 8)
	calque.add_child(_etiquette)
	add_child(calque)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lieu="):
			_index = maxi(0, LIEUX.find(argument.trim_prefix("--lieu=")))
	_montrer()


## Relevé « [proto-perf] » toutes les 2 s, avec le lieu (adb logcat sur le S24).
func _process(delta: float) -> void:
	_chrono += delta
	if _chrono >= 2.0:
		_chrono = 0.0
		print("[proto-perf] lieu=%s fps=%d vram_textures_mo=%.1f" % [LIEUX[_index],
			Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_index = (_index + 1) % LIEUX.size()
		_montrer()


func _montrer() -> void:
	if _lieu:
		_lieu.queue_free()
	var nom: String = LIEUX[_index]
	if nom == "bourg":
		_lieu = preload("res://proto/da_jadielle/proto_bourg.gd").new()
	elif nom in ["chambre", "rdc", "rival", "labo"]:
		_lieu = preload("res://proto/da_jadielle/proto_interieur_bourg.gd").new()
		_lieu.piece = nom
	elif nom == "route1" or nom == "route1_avant":
		_lieu = preload("res://proto/da_jadielle/proto_route1.gd").new()
		_lieu.nouvelle_foret = nom == "route1"
	elif nom == "ville":
		_lieu = preload("res://proto/da_jadielle/proto_ville.gd").new()
	elif nom == "route22":
		_lieu = preload("res://proto/da_jadielle/proto_route22.gd").new()
	elif nom == "place":
		_lieu = preload("res://proto/da_jadielle/proto_da_jadielle.tscn").instantiate()
		_lieu.bascule_lumiere = false
	else:
		_lieu = preload("res://proto/da_jadielle/proto_interieur.gd").new()
		_lieu.piece = nom
	add_child(_lieu)
	_etiquette.text = "%s   ·   toucher l'écran pour changer de lieu" % NOMS[nom]
