class_name BattleDecor
extends RefCounted
## Un décor peint de combat (CB.3, dossier 05 §2) : la représentation peinte et resserrée d'un
## lieu, vue à hauteur d'yeux. Un décor = **zone + variante locale** (Forêt de Jade : lisière,
## sous-bois, clairière…), lu dans `data/battle/decors.json` ([BattleDecorCatalog]).
##
## **Ligne de sol** : le master est peint pour que les deux Pokémon s'y posent aux places du
## cadrage ([BattleLayout]) ; le décor déclare, en pixels de son image, les deux points du sol
## où tombent les pieds de l'adversaire ([member foe_feet]) et ceux du Pokémon du joueur
## ([member player_feet]). [method fit] en tire l'échelle (l'écart vertical entre ces deux
## points = celui des ancres) et la position (pieds adverses sur leur ancre) : les pieds et
## les ombres sont toujours sur le sol peint, la perspective du décor reste celle des tailles
## de CB.1. Calque de premier plan ([member front_path]) facultatif : même taille que le fond,
## dessiné devant ton Pokémon.
## Classe pure : aucune dépendance à l'arbre de scènes.

var id: StringName = &""
## Zone du Kanto (`data/world/zones.json`) et variante locale (« chemin », « lisière »…).
var zone: StringName = &""
var variant: StringName = &""
## Images (chemins res://) : fond opaque, premier plan transparent ("" : aucun).
var back_path: String = ""
var front_path: String = ""
## Taille du master (px), pieds de l'adversaire et du joueur et horizon, en px du master.
var size: Vector2 = Vector2.ZERO
var foe_feet: Vector2 = Vector2.ZERO
var player_feet: Vector2 = Vector2.ZERO
var horizon: float = 0.0


## Décor lu depuis une entrée de `decors.json` ([param data]) ; null si une clé manque ou si la
## ligne de sol est incohérente (le joueur doit être sous l'adversaire, dans l'image).
static func from_dict(decor_id: StringName, data: Dictionary) -> BattleDecor:
	for key: String in ["zone", "back", "size", "foe_feet", "player_feet"]:
		if not data.has(key):
			push_error("BattleDecor « %s » : clé « %s » absente" % [decor_id, key])
			return null
	var decor := BattleDecor.new()
	decor.id = decor_id
	decor.zone = StringName(str(data["zone"]))
	decor.variant = StringName(str(data.get("variant", "")))
	decor.back_path = str(data["back"])
	decor.front_path = str(data.get("front", ""))
	decor.size = _vec(data["size"])
	decor.foe_feet = _vec(data["foe_feet"])
	decor.player_feet = _vec(data["player_feet"])
	decor.horizon = float(data.get("horizon", 0.0))
	if not decor.is_valid():
		push_error("BattleDecor « %s » : ligne de sol incohérente" % decor_id)
		return null
	return decor


## Ligne de sol cohérente : image non vide, pieds dans l'image, joueur plus bas que l'adversaire.
func is_valid() -> bool:
	var image := Rect2(Vector2.ZERO, size)
	return size.x > 0.0 and size.y > 0.0 and back_path != "" \
		and image.has_point(foe_feet) and image.grow(1.0).has_point(player_feet) \
		and player_feet.y > foe_feet.y


## Rectangle écran où dessiner le master (et le premier plan) pour une vue de [param view_size] :
## l'écart vertical pieds adverses → pieds du joueur devient celui des ancres de [BattleLayout],
## les pieds adverses tombent sur leur ancre. Si l'image ne couvre alors pas tout l'écran, elle
## glisse (puis grandit autour des pieds adverses) jusqu'à le couvrir : jamais de bord vide.
func fit(view_size: Vector2) -> Rect2:
	var anchors := BattleLayout.anchors(view_size)
	var foe: Vector2 = anchors["foe_feet"]
	var mine: Vector2 = anchors["player_feet"]
	var scale := (mine.y - foe.y) / maxf(player_feet.y - foe_feet.y, 1.0)
	# Couvrir l'écran : échelle minimale d'abord, puis glissement dans les bornes.
	scale = maxf(scale, maxf(view_size.x / size.x, view_size.y / size.y))
	var position := foe - foe_feet * scale
	var shown := size * scale
	position.x = clampf(position.x, view_size.x - shown.x, 0.0)
	position.y = clampf(position.y, view_size.y - shown.y, 0.0)
	return Rect2(position, shown)


static func _vec(value: Variant) -> Vector2:
	var list := value as Array
	if list == null or list.size() < 2:
		return Vector2.ZERO
	return Vector2(float(list[0]), float(list[1]))
