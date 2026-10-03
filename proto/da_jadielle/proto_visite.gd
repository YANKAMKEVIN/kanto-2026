extends Node
## Visite du prototype sur le S24 : toucher l'écran passe de la place (lumière C2) à
## l'intérieur du Centre, puis de la Boutique.

const LIEUX := ["ville", "route22", "place", "centre", "boutique"]
const NOMS := {"route22": "Route 22 (la caméra fait le tour)", "ville": "Jadielle entière (la caméra fait le tour)", "place": "Place de Jadielle (lumière C2)", "centre": "Centre Pokémon — intérieur",
	"boutique": "Boutique — intérieur"}

var _index := 0
var _lieu: Node
var _etiquette := Label.new()


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


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_index = (_index + 1) % LIEUX.size()
		_montrer()


func _montrer() -> void:
	if _lieu:
		_lieu.queue_free()
	var nom: String = LIEUX[_index]
	if nom == "ville":
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
