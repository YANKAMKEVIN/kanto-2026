class_name BattleHudLayout
extends RefCounted
## Emplacements des composants de l'interface de combat, d'après combat-v1 et
## combat-capacites-v1 (valeurs dans UiTokens) : chacun est ancré à un coin de l'écran, donc
## reste en place de 1920 à 2340 de large (aspect expand).
##
##   FOE_CARD    carte adversaire, en haut à droite
##   OWN_CARD    carte joueur, en bas à gauche (assez haut pour loger « ‹ » dessous)
##   PARTY_PIPS  six pastilles, juste au-dessus de la carte joueur
##   BACK        bouton « ‹ », en bas à gauche, sous la carte joueur
##   ACTIONS     grille des 4 actions, en bas à droite
##   MOVES       bandeau des capacités, en bas à droite (il déborde jusqu'aux bords)
##   MESSAGE     bandeau des messages, à la place de la grille (à droite de la carte joueur)
##   FORGET      panneau d'oubli d'une capacité (jalon 5C), bas droite, plus haut que MOVES
## Rien d'interactif à moins de SAFE_MARGIN des bords (vérifié par les tests).

enum Slot { FOE_CARD, OWN_CARD, PARTY_PIPS, BACK, ACTIONS, MOVES, MESSAGE, FORGET }


## Ancre [param control] (enfant direct d'un Control plein écran) à l'emplacement [param slot].
static func place(control: Control, slot: Slot) -> void:
	var box := frame(slot)
	var corner: Vector2 = box[0]
	var margin: Vector2 = box[1]
	var size: Vector2 = box[2]
	control.anchor_left = corner.x
	control.anchor_right = corner.x
	control.anchor_top = corner.y
	control.anchor_bottom = corner.y
	if corner.x > 0.0:
		control.offset_left = -margin.x - size.x
		control.offset_right = -margin.x
		control.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	else:
		control.offset_left = margin.x
		control.offset_right = margin.x + size.x
		control.grow_horizontal = Control.GROW_DIRECTION_END
	if corner.y > 0.0:
		control.offset_top = -margin.y - size.y
		control.offset_bottom = -margin.y
		control.grow_vertical = Control.GROW_DIRECTION_BEGIN
	else:
		control.offset_top = margin.y
		control.offset_bottom = margin.y + size.y
		control.grow_vertical = Control.GROW_DIRECTION_END


## Rectangle de [param slot] sur un écran de [param view_size].
static func rect(slot: Slot, view_size: Vector2) -> Rect2:
	var box := frame(slot)
	var corner: Vector2 = box[0]
	var margin: Vector2 = box[1]
	var size: Vector2 = box[2]
	var x := view_size.x - margin.x - size.x if corner.x > 0.0 else margin.x
	var y := view_size.y - margin.y - size.y if corner.y > 0.0 else margin.y
	return Rect2(Vector2(x, y), size)


## [coin (0 ou 1 par axe), distance des bords proches à ce coin, taille] de [param slot].
static func frame(slot: Slot) -> Array[Vector2]:
	var edge := float(UiTokens.BATTLE_EDGE)
	var card := Vector2(UiTokens.BATTLE_CARD_WIDTH, UiTokens.BATTLE_CARD_HEIGHT)
	var own_card := Vector2(UiTokens.BATTLE_CARD_WIDTH, UiTokens.BATTLE_CARD_HEIGHT_NUMBERS)
	match slot:
		Slot.FOE_CARD:
			return [Vector2(1, 0), Vector2(edge, UiTokens.BATTLE_FOE_CARD_TOP), card]
		Slot.OWN_CARD:
			return [Vector2(0, 1), Vector2(edge, UiTokens.BATTLE_OWN_CARD_BOTTOM), own_card]
		Slot.PARTY_PIPS:
			var pips := Vector2(
				UiTokens.PARTY_SIZE * UiTokens.PARTY_PIP
					+ (UiTokens.PARTY_SIZE - 1) * UiTokens.PARTY_PIP_GAP,
				UiTokens.PARTY_PIP)
			var above := UiTokens.BATTLE_OWN_CARD_BOTTOM + own_card.y + UiTokens.PARTY_PIPS_GAP
			return [Vector2(0, 1), Vector2(edge + UiTokens.PARTY_PIPS_INSET, above), pips]
		Slot.BACK:
			return [Vector2(0, 1), Vector2(edge, edge), Vector2.ONE * UiTokens.BATTLE_BACK_SIZE]
		Slot.ACTIONS:
			return [Vector2(1, 1), Vector2(edge, UiTokens.BATTLE_GRID_BOTTOM), actions_size()]
		Slot.MOVES:
			var pad := float(UiTokens.MOVE_BAND_PAD)
			return [Vector2(1, 1), Vector2(edge - pad, UiTokens.BATTLE_MOVES_BOTTOM - pad),
				moves_size()]
		Slot.FORGET:
			var pad := float(UiTokens.MOVE_BAND_PAD)
			return [Vector2(1, 1), Vector2(edge - pad, UiTokens.BATTLE_MOVES_BOTTOM - pad),
				forget_size()]
		Slot.MESSAGE:
			return [Vector2(1, 1), Vector2(edge, UiTokens.BATTLE_GRID_BOTTOM),
				Vector2(UiTokens.BATTLE_MESSAGE_WIDTH, UiTokens.BATTLE_MESSAGE_HEIGHT)]
	return [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]


## Taille de la grille d'actions (2 × 2 boutons BATTLE_ACTION_SIZE).
static func actions_size() -> Vector2:
	return UiTokens.BATTLE_ACTION_SIZE * 2.0 + Vector2.ONE * UiTokens.BATTLE_ACTION_GAP


## Taille du bandeau des capacités : 2 × 2 cartes, plus la marge du bandeau (à gauche,
## MOVE_GAP_H pour la flèche ▶ de la colonne de gauche).
static func moves_size() -> Vector2:
	var cards := UiTokens.MOVE_CARD_SIZE * 2.0 \
		+ Vector2(UiTokens.MOVE_GAP_H, UiTokens.MOVE_GAP_V)
	return cards + Vector2(UiTokens.MOVE_GAP_H + UiTokens.MOVE_BAND_PAD,
		UiTokens.MOVE_BAND_PAD * 2)


## Taille du panneau d'oubli : marge, légende, nouvelle capacité, légende, 2 × 2 cartes,
## boutons, marge (MOVE_BAND_PAD autour ; FORGET_ROW_GAP entre les cinq blocs).
static func forget_size() -> Vector2:
	var width := UiTokens.MOVE_CARD_SIZE.x * 2.0 + UiTokens.FORGET_GAP_H \
		+ UiTokens.MOVE_BAND_PAD * 2
	var height := UiTokens.MOVE_BAND_PAD * 2 + UiTokens.FORGET_CAPTION_HEIGHT * 2 \
		+ UiTokens.MOVE_CARD_SIZE.y * 3 + UiTokens.MOVE_GAP_V + UiTokens.FORGET_BUTTON_SIZE.y \
		+ UiTokens.FORGET_ROW_GAP * 4
	return Vector2(width, height)
