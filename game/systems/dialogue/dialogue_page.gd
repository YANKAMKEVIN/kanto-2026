class_name DialoguePage
extends RefCounted
## Une page de dialogue : le texte d'une boîte pleine et ses indications de mise en scène.
##
## Donnée pure, construite par [DialogueLibrary]. Dans les fichiers, une page est soit une
## chaîne (texte seul), soit un objet (docs/tech/jalon-03.md §2.4) :
## [codeblock]
## { "text": "Moi, je suis prêt.", "pause": 0.6 }
## { "text": "...enfin, presque.", "react": "nils_rattata", "pause": 0.5 }
## [/codeblock]
## Les didascalies du dossier 02 (« il regarde le joueur », « petit silence »,
## « Rattata réagit », « il regarde les hautes herbes ») deviennent [member face_player],
## [member pause], [member react] et [member turn] (jalon 3B) :
## [codeblock]
## { "text": "…", "turn": { "oak": "up", "player": "oak" } }
## [/codeblock]

## Voix reconnues (clé « voice »).
const VOICES: Array[StringName] = [&"spirit"]

## Texte affiché (retours à la ligne automatiques ; « \n » force une ligne).
var text: String = ""
## Locuteur de cette page ; vide = celui du dialogue (scènes à plusieurs voix, jalon 3B).
var speaker: String = ""
## Voix de la page : vide = voix normale ; « spirit » = voix d'esprit (Exorciste possédé).
var voice: StringName = &""
## Silence avant que le texte commence à s'écrire (secondes).
var pause: float = 0.0
## Le PNJ à qui l'on parle se tourne vers le joueur au début de cette page.
var face_player: bool = false
## Identifiant d'un PNJ ou Pokémon de la carte qui joue sa réaction au début de la page
## (vide = aucun).
var react: StringName = &""
## Orientations appliquées au début de la page, dans l'ordre (docs/tech/jalon-03b.md §2.7) :
## acteur → cible. Acteur = « player » ou identifiant d'un PNJ de la carte ; cible = nom de
## direction (« up »…), « player » ou identifiant de PNJ (axe dominant). Vide = aucune.
var turn: Dictionary[StringName, StringName] = {}


func _init(page_text: String = "") -> void:
	text = page_text
