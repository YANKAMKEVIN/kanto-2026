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
##   BAG         Sac de combat (jalon 5D), colonne gauche : cadre au-dessus du bouton « ‹ »
##   CAPTURE     carte de capture (jalon 5D), centrée sur l'écran
##   PARTY_PICKER choix du Pokémon à soigner (jalon 6), coin bas gauche, à la place du Sac
##   PARTY       panneau ÉQUIPE (jalon 7), colonne gauche comme le Sac : cadre au-dessus de « ‹ »
##   SUMMARY     bilan de fin de combat (demande n° 1), centré sur l'écran
## Rien d'interactif à moins de SAFE_MARGIN des bords (vérifié par les tests).

enum Slot {
	FOE_CARD, OWN_CARD, PARTY_PIPS, BACK, ACTIONS, MOVES, MESSAGE, FORGET, BAG, CAPTURE,
	PARTY_PICKER, PARTY, SUMMARY,
}

## Valeur de « coin » d'un axe pour un emplacement centré (la distance au bord est ignorée).
const CENTERED := 0.5


## Ancre [param control] (enfant direct d'un Control plein écran) à l'emplacement [param slot].
static func place(control: Control, slot: Slot) -> void:
	var box := frame(slot)
	var corner: Vector2 = box[0]
	var margin: Vector2 = box[1]
	var size: Vector2 = box[2]
	var horizontal := _place_axis(corner.x, margin.x, size.x)
	control.anchor_left = horizontal[0]
	control.anchor_right = horizontal[0]
	control.offset_left = horizontal[1]
	control.offset_right = horizontal[2]
	control.grow_horizontal = int(horizontal[3]) as Control.GrowDirection
	var vertical := _place_axis(corner.y, margin.y, size.y)
	control.anchor_top = vertical[0]
	control.anchor_bottom = vertical[0]
	control.offset_top = vertical[1]
	control.offset_bottom = vertical[2]
	control.grow_vertical = int(vertical[3]) as Control.GrowDirection


## Rectangle de [param slot] sur un écran de [param view_size].
static func rect(slot: Slot, view_size: Vector2) -> Rect2:
	var box := frame(slot)
	var corner: Vector2 = box[0]
	var margin: Vector2 = box[1]
	var size: Vector2 = box[2]
	return Rect2(Vector2(_axis_start(corner.x, margin.x, size.x, view_size.x),
		_axis_start(corner.y, margin.y, size.y, view_size.y)), size)


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
		Slot.BAG:
			return [Vector2(0, 1), Vector2(edge, edge), bag_size()]
		Slot.CAPTURE:
			return [Vector2(CENTERED, CENTERED), Vector2.ZERO, capture_size()]
		Slot.PARTY_PICKER:
			return [Vector2(0, 1), Vector2(edge, edge), picker_size()]
		Slot.PARTY:
			return [Vector2(0, 1), Vector2(edge, edge), party_size()]
		Slot.SUMMARY:
			return [Vector2(CENTERED, CENTERED), Vector2.ZERO,
				Vector2(UiTokens.SUMMARY_CARD_WIDTH, UiTokens.SUMMARY_CARD_MAX_HEIGHT)]
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


## Taille de l'emplacement du Sac : cadre (au plus BAG_FRAME_MAX_HEIGHT), écart, puis « ‹ ».
static func bag_size() -> Vector2:
	return Vector2(UiTokens.BAG_PANEL_WIDTH, UiTokens.BAG_FRAME_MAX_HEIGHT + UiTokens.GAP
		+ UiTokens.BATTLE_BACK_SIZE)


## Taille du choix du Pokémon (PartyPicker) : PICKER_COLUMNS colonnes de cartes, trois rangées
## (six Pokémon), l'en-tête et les marges ; jamais plus étroit que le Sac.
static func picker_size() -> Vector2:
	var width := UiTokens.PICKER_COLUMNS * UiTokens.PICKER_COLUMN_WIDTH \
		+ (UiTokens.PICKER_COLUMNS - 1) * UiTokens.PICKER_GAP + UiTokens.MENU_PANEL_PAD * 2
	var rows := ceili(UiTokens.PARTY_SIZE / float(UiTokens.PICKER_COLUMNS))
	var height := UiTokens.MENU_PANEL_PAD * 2 + UiTokens.TOUCH_MIN + UiTokens.PICKER_GAP \
		+ rows * UiTokens.PICKER_ROW_HEIGHT + (rows - 1) * UiTokens.PICKER_GAP \
		+ UiTokens.BAG_SCROLL_PAD * 2
	return Vector2(maxf(width, UiTokens.BAG_PANEL_WIDTH), height)


## Taille du panneau ÉQUIPE (jalon 7) : cadre du Sac (largeur), en-tête, filet, trois rangées
## de deux cartes (six Pokémon), pied ENVOYER, marges ; puis l'écart et « ‹ ».
static func party_size() -> Vector2:
	var rows := ceili(UiTokens.PARTY_SIZE / float(UiTokens.BATTLE_PARTY_COLUMNS))
	var frame_height := UiTokens.BAG_PANEL_PAD * 2 + UiTokens.BAG_TITLE_ICON \
		+ UiTokens.BORDER_WIDTH + rows * UiTokens.BATTLE_PARTY_CARD_HEIGHT \
		+ (rows - 1) * UiTokens.PICKER_GAP + UiTokens.BATTLE_PARTY_FOOTER_HEIGHT \
		+ UiTokens.BAG_ROW_GAP * 3
	return Vector2(UiTokens.BAG_PANEL_WIDTH, frame_height + UiTokens.GAP
		+ UiTokens.BATTLE_BACK_SIZE)


## Taille de l'emplacement de la carte de capture (elle épouse son contenu, au centre).
static func capture_size() -> Vector2:
	return Vector2(UiTokens.CAPTURE_CARD_WIDTH, UiTokens.CAPTURE_CARD_MAX_HEIGHT)


## [ancre, décalage du bord proche, décalage du bord lointain, sens de croissance] d'un axe.
## [param corner] : 0 (bords haut ou gauche), 1 (bas ou droite) ou CENTERED.
static func _place_axis(corner: float, margin: float, length: float) -> Array[float]:
	if corner == CENTERED:
		return [CENTERED, -length * 0.5, length * 0.5, float(Control.GROW_DIRECTION_BOTH)]
	if corner > 0.0:
		return [corner, -margin - length, -margin, float(Control.GROW_DIRECTION_BEGIN)]
	return [corner, margin, margin + length, float(Control.GROW_DIRECTION_END)]


## Début (bord haut ou gauche) d'un emplacement sur un axe de longueur [param extent].
static func _axis_start(corner: float, margin: float, length: float, extent: float) -> float:
	if corner == CENTERED:
		return (extent - length) * 0.5
	if corner > 0.0:
		return extent - margin - length
	return margin
