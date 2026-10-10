class_name OpeningFlow
extends RefCounted
## Machine d'états de l'ouverture (dossier 13 §3.1, §3.2, §3.7, §5.2, §7).
##
## Classe pure : ni scène, ni disque. Le futur `OpeningDirector` (OUV.1) lui donne l'état de la
## sauvegarde au lancement et chaque action du joueur ([method handle]), affiche
## [member screen] et exécute les [enum Effect] rendus par [method take_effects] (copie de
## sécurité et écriture : [OpeningCommit] ; entrée dans la chambre ; reprise de la partie).
##
## [codeblock]
## TITLE ─ SETTINGS ─► SETTINGS ─ BACK ─► TITLE
## TITLE ─ CONTINUE (valide) ─► CONTINUE                       [RESUME_SAVE]
## TITLE ─ NEW_GAME ─┬─ valide ─► CONFIRM_OVERWRITE ─ CONFIRM ─► INTRO
##                   │            (CANCEL / BACK ─► TITLE)
##                   └─ sinon ──► INTRO
## INTRO ─ ABANDON ─► TITLE                                     (aucun effet)
## INTRO ─ INTRO_FINISHED ─┬─ écriture permise ─► COMMIT        [BACKUP_PREVIOUS?, WRITE_NEW_GAME]
##                         └─ version plus récente ─► DONE      [ENTER_BEDROOM]
## COMMIT ─ COMMIT_SUCCEEDED ─► DONE                            [ENTER_BEDROOM]
## COMMIT ─ COMMIT_FAILED ───► DONE                             [ENTER_BEDROOM, WARN_UNSAVED]
## [/codeblock]
## Garanties : aucun effet disque avant INTRO_FINISHED ; un abandon ramène au titre sans rien
## changer (une nouvelle partie redemande la confirmation) ; [method autosave_allowed] est faux
## tant qu'on n'est pas en DONE (écriture réussie) ou CONTINUE ; avec une sauvegarde d'une
## version plus récente, on peut jouer une nouvelle partie **sans jamais écrire**. Une action
## impossible dans l'écran courant est refusée (faux) sans rien changer. DONE et CONTINUE sont
## terminaux.

## État de la sauvegarde au lancement, d'après [member SaveSystem.last_status] après
## [method SaveSystem.read] ([method status_from_read]).
enum SaveStatus {
	## Pas de `save.json` (premier lancement).
	NONE,
	## Lue et migrée : Continuer est possible.
	VALID,
	## Illisible : déjà mise en quarantaine (`save.json.corrupt`) par [SaveSystem].
	CORRUPT,
	## Version plus récente que la build : laissée intacte, on ne doit jamais écrire.
	NEWER,
}

enum Screen {
	TITLE,
	SETTINGS,
	CONFIRM_OVERWRITE,
	INTRO,
	## Écritures en cours ([OpeningCommit]) ; aucune entrée du joueur.
	COMMIT,
	## Nouvelle partie lancée : la chambre.
	DONE,
	## Partie reprise.
	CONTINUE,
}

enum Action {
	CONTINUE,
	NEW_GAME,
	SETTINGS,
	## Retour (Android ou « ‹ ») : quitte les Paramètres ou la confirmation ; sans effet au
	## titre et pendant l'introduction (dossier 13 §5.2, §5.5).
	BACK,
	## Confirmation : « Nouvelle partie ».
	CONFIRM,
	## Confirmation : « Annuler ».
	CANCEL,
	## Retour au titre pendant l'introduction (ou relancement après un arrêt) : rien d'écrit.
	ABANDON,
	## Fin de la dernière réplique de Chen, avant le fondu vers la chambre.
	INTRO_FINISHED,
	COMMIT_SUCCEEDED,
	COMMIT_FAILED,
}

enum Effect {
	## Copier `save.json` existant vers `save.previous.json` ([OpeningCommit], étape 1).
	BACKUP_PREVIOUS,
	## Construire la nouvelle partie en mémoire et l'écrire tout de suite (étapes 2 et 3).
	WRITE_NEW_GAME,
	## Fondu puis `SceneRouter.start` dans la chambre (étape 4).
	ENTER_BEDROOM,
	## Lire la sauvegarde et reprendre la partie.
	RESUME_SAVE,
	## L'écriture a échoué : la partie continue sans sauvegarde (message [TitleTexts]).
	WARN_UNSAVED,
}

var _status: SaveStatus
var _screen: Screen = Screen.TITLE
var _effects: Array[Effect] = []
var _commit_failed: bool = false


func _init(save_status: SaveStatus = SaveStatus.NONE) -> void:
	_status = save_status


## Statut d'après le résultat de [method SaveSystem.read] : OK → VALID, fichier absent → NONE,
## corrompu → CORRUPT, version plus récente (ERR_INVALID_DATA) → NEWER. Toute autre erreur
## de lecture est traitée comme une sauvegarde corrompue (jamais Continuer, jamais écrasée
## sans copie : [OpeningCommit] sauvegarde tout `save.json` présent).
static func status_from_read(read_status: Error) -> SaveStatus:
	match read_status:
		OK:
			return SaveStatus.VALID
		ERR_FILE_NOT_FOUND:
			return SaveStatus.NONE
		ERR_INVALID_DATA:
			return SaveStatus.NEWER
		_:
			return SaveStatus.CORRUPT


func save_status() -> SaveStatus:
	return _status


func screen() -> Screen:
	return _screen


## Vrai si [param action] est acceptée dans l'écran courant.
func can(action: Action) -> bool:
	match _screen:
		Screen.TITLE:
			return action == Action.NEW_GAME or action == Action.SETTINGS \
				or (action == Action.CONTINUE and can_continue())
		Screen.SETTINGS:
			return action == Action.BACK
		Screen.CONFIRM_OVERWRITE:
			return action in [Action.CONFIRM, Action.CANCEL, Action.BACK]
		Screen.INTRO:
			return action == Action.ABANDON or action == Action.INTRO_FINISHED
		Screen.COMMIT:
			return action == Action.COMMIT_SUCCEEDED or action == Action.COMMIT_FAILED
	return false


## Applique [param action]. Faux (rien ne change, aucun effet) si elle est impossible ici.
func handle(action: Action) -> bool:
	if not can(action):
		return false
	match action:
		Action.CONTINUE:
			_go(Screen.CONTINUE, [Effect.RESUME_SAVE])
		Action.NEW_GAME:
			_go(Screen.CONFIRM_OVERWRITE if needs_confirmation() else Screen.INTRO)
		Action.SETTINGS:
			_go(Screen.SETTINGS)
		Action.BACK, Action.CANCEL, Action.ABANDON:
			_go(Screen.TITLE)
		Action.CONFIRM:
			_go(Screen.INTRO)
		Action.INTRO_FINISHED:
			if writes_allowed():
				var effects: Array[Effect] = []
				if _status == SaveStatus.VALID:
					effects.append(Effect.BACKUP_PREVIOUS)
				effects.append(Effect.WRITE_NEW_GAME)
				_go(Screen.COMMIT, effects)
			else:
				_go(Screen.DONE, [Effect.ENTER_BEDROOM])
		Action.COMMIT_SUCCEEDED:
			_go(Screen.DONE, [Effect.ENTER_BEDROOM])
		Action.COMMIT_FAILED:
			_commit_failed = true
			_go(Screen.DONE, [Effect.ENTER_BEDROOM, Effect.WARN_UNSAVED])
	return true


## Effets demandés par les transitions depuis le dernier appel, dans l'ordre ; la liste est
## vidée.
func take_effects() -> Array[Effect]:
	var effects := _effects
	_effects = []
	return effects


## Continuer n'existe qu'avec une sauvegarde valide.
func can_continue() -> bool:
	return _status == SaveStatus.VALID


## Une nouvelle partie remplacerait une aventure lisible : confirmation obligatoire (A10).
func needs_confirmation() -> bool:
	return _status == SaveStatus.VALID


## Faux avec une sauvegarde d'une version plus récente (on ne la touche jamais) ou après un
## échec du commit.
func writes_allowed() -> bool:
	return _status != SaveStatus.NEWER and not _commit_failed


## Vrai seulement quand la partie est stable sur le disque : reprise (CONTINUE) ou nouvelle
## partie écrite (DONE). Faux au titre, dans les Paramètres, la confirmation, l'introduction
## et pendant le commit (y compris au passage en arrière-plan, dossier 13 §3.7).
func autosave_allowed() -> bool:
	match _screen:
		Screen.CONTINUE:
			return true
		Screen.DONE:
			return writes_allowed()
	return false


func _go(target: Screen, effects: Array[Effect] = []) -> void:
	_screen = target
	_effects.append_array(effects)
