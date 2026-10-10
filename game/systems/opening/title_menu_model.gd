class_name TitleMenuModel
extends RefCounted
## Contenu de l'écran titre selon l'état de la sauvegarde (dossier 13 §5.2, §5.4).
##
## Classe pure, construite une fois par [method build] ; l'écran (`title_screen.tscn`, OUV.1)
## ne fait que l'afficher.
##
## | État      | Continuer     | Nouvelle partie            | Message   |
## |-----------|---------------|----------------------------|-----------|
## | aucune    | absente       | mise en avant              | —         |
## | valide    | mise en avant | secondaire, confirmation   | —         |
## | corrompue | absente       | mise en avant              | « corrupt » |
## | plus récente | absente    | mise en avant, sans écrire | « newer » |
## Paramètres est toujours là, jamais mis en avant. Les textes viennent de [TitleTexts].

const ENTRY_CONTINUE: StringName = &"continue"
const ENTRY_NEW_GAME: StringName = &"new_game"
const ENTRY_SETTINGS: StringName = &"settings"
## Séparateur du résumé de la confirmation (« Kevin · 20 h 12 · 1 badge »).
const SUMMARY_SEPARATOR: String = " · "

## Entrées affichées, de haut en bas.
var entries: Array[StringName] = []
## Entrée mise en avant (liseré doré).
var featured: StringName = &""
## Message d'état de la sauvegarde ("" s'il n'y en a pas).
var message: String = ""
## Libellé de chaque entrée.
var labels: Dictionary[StringName, String] = {}
## Nouvelle partie demande la carte de confirmation (§5.4).
var new_game_needs_confirmation: bool = false
## Nouvelle partie jouée sans jamais écrire (version plus récente).
var new_game_unsaved: bool = false
## Carte Continuer : null sans sauvegarde valide.
var summary: SaveSummary = null
## Carte de confirmation (vides sans sauvegarde valide).
var confirm_title: String = ""
var confirm_summary: String = ""
var confirm_body: String = ""
var confirm_cancel: String = ""
var confirm_accept: String = ""


## Modèle pour [param status] ([enum OpeningFlow.SaveStatus]). [param save_summary] n'est lu
## qu'avec une sauvegarde valide.
static func build(status: OpeningFlow.SaveStatus, save_summary: SaveSummary,
		texts: TitleTexts) -> TitleMenuModel:
	var model := TitleMenuModel.new()
	var valid := status == OpeningFlow.SaveStatus.VALID
	if valid:
		model.entries.append(ENTRY_CONTINUE)
		model.summary = save_summary
	model.entries.append(ENTRY_NEW_GAME)
	model.entries.append(ENTRY_SETTINGS)
	model.featured = ENTRY_CONTINUE if valid else ENTRY_NEW_GAME
	for entry: StringName in model.entries:
		model.labels[entry] = texts.text(TitleTexts.GROUP_ENTRIES, entry)
	match status:
		OpeningFlow.SaveStatus.CORRUPT:
			model.message = texts.text(TitleTexts.GROUP_MESSAGES, &"corrupt")
		OpeningFlow.SaveStatus.NEWER:
			model.message = texts.text(TitleTexts.GROUP_MESSAGES, &"newer")
			model.new_game_unsaved = true
	model.new_game_needs_confirmation = valid
	if valid:
		model.confirm_title = texts.text(TitleTexts.GROUP_CONFIRM, &"title")
		model.confirm_summary = summary_line(save_summary)
		model.confirm_body = texts.text(TitleTexts.GROUP_CONFIRM, &"body")
		model.confirm_cancel = texts.text(TitleTexts.GROUP_CONFIRM, &"cancel")
		model.confirm_accept = texts.text(TitleTexts.GROUP_CONFIRM, &"confirm")
	return model


## « {prénom} · {temps de jeu} · {badges} » ; les parties vides sont omises (pas de badge :
## « Kevin · 20 h 12 »).
static func summary_line(save_summary: SaveSummary) -> String:
	if save_summary == null:
		return ""
	var parts := PackedStringArray()
	for part: String in [save_summary.player_name, save_summary.play_time_text(),
			save_summary.badges_text()]:
		if not part.is_empty():
			parts.append(part)
	return SUMMARY_SEPARATOR.join(parts)
