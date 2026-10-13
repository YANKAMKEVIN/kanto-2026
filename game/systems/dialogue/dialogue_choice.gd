class_name DialogueChoice
extends RefCounted
## Choix à deux grandes cartes à la fin d'une variante de dialogue (dossier 09 §7, §18 ;
## bible UI/UX §4 ; jalon-07.md §3.3) : SOIGNER / PAS MAINTENANT. La question est la
## **dernière page** de la variante ; elle passe aussi dans le titre des cartes
## ([method to_view]), car le voile de `ChoiceCards` couvre la boîte (jalon-07.md §0, point 1).
##
## Donnée pure, construite par [DialogueLibrary] (clé « choice » d'une variante) :
## [codeblock]
## "choice": { "confirm": "SOIGNER", "cancel": "PAS MAINTENANT",
##   "confirm_action": "center_heal",
##   "confirm_pages": ["Voilà. Tout le monde est en pleine forme."],
##   "cancel_pages": ["Très bien. Reviens quand tu veux."] }
## [/codeblock]
## Le lecteur ([DialogueRunner]) joue, si le joueur confirme, [member confirm_action] (attendue)
## puis [member confirm_pages] ; sinon [member cancel_pages]. Une liste vide = le dialogue se
## termine tout de suite.

## Libellé de la carte de l'action (« SOIGNER »).
var confirm_label: String = ""
## Libellé de la carte du renoncement (« PAS MAINTENANT »).
var cancel_label: String = ""
## Action jouée si le joueur confirme (&"" = aucune), avant [member confirm_pages] :
## une de [constant DialogueLibrary.ACTIONS].
var confirm_action: StringName = &""
var confirm_pages: Array[DialoguePage] = []
var cancel_pages: Array[DialoguePage] = []


## Scène lancée si le joueur confirme (jalon 12, T23 ; &"" = aucune) : à la fermeture du
## dialogue, après [member confirm_pages], par [signal DialogueRunner.cutscene_requested]
## (« Prendre le Fossile Dôme ? » OUI → la scène du fossile). Exclusive de [member confirm_action].
var confirm_cutscene: StringName = &""


## Vue des deux cartes, [param question] en titre (texte de la dernière page de la variante).
func to_view(question: String) -> ChoiceView:
	return ChoiceView.new(question, confirm_label, cancel_label)
