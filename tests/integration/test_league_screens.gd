extends GutTest
## Écran du Panthéon et générique (jalon 30, T15, T16) : instantanés (speed_scale = 0), ils
## montrent la vue reçue, rendent la main et se cachent ; le bouton « passer » n'existe que si
## le générique est passable ; un vrai défilement finit par la dernière ligne au centre.

var _hall: HallOfFameScreen
var _credits: CreditsScreen


func before_each() -> void:
	_hall = HallOfFameScreen.new()
	_hall.speed_scale = 0.0
	add_child_autofree(_hall)
	_credits = CreditsScreen.new()
	_credits.speed_scale = 0.0
	_credits.skip_label = "Passer"
	add_child_autofree(_credits)


func _view() -> Dictionary:
	return {"header": "Kevin · 26/10/2026", "members": [
		{"texture": PokedexArt.portrait(6), "line": "Dracaufeu — N62", "subtitle": ""},
		{"texture": PokedexArt.portrait(18), "line": "Plume — N58", "subtitle": "Roucarnage"}]}


func _rows() -> Array[Dictionary]:
	return [{"kind": CreditsData.RowKind.LOGO, "text": "KANTO 2026"},
		{"kind": CreditsData.RowKind.GAP, "text": ""},
		{"kind": CreditsData.RowKind.LINE, "text": "Merci d'avoir joué"}]


func test_hall_of_fame_shows_each_member_then_the_team_and_leaves() -> void:
	await _hall.present(_view())
	assert_false(_hall.is_showing(), "parti")
	assert_eq(_hall.get_line_text(), "Plume — N58", "dernier Pokémon montré")
	assert_eq(_hall.get_team_size(), 2, "toute l'équipe à la fin")


func test_credits_list_their_rows_and_skip_only_when_allowed() -> void:
	await _credits.present(_rows(), false)
	assert_false(_credits.is_showing())
	assert_eq(_credits.get_row_texts(), PackedStringArray(["KANTO 2026", "Merci d'avoir joué"]))
	assert_false(_credits.is_skip_visible(), "premier générique : pas de bouton")
	var shown: Array[bool] = []
	_credits.visibility_changed.connect(func() -> void:
		if _credits.visible:
			shown.append(_credits.is_skip_visible()))
	await _credits.present(_rows(), true)
	assert_eq(shown, [true], "déjà vu : passable")


func test_real_credits_scroll_and_can_be_skipped() -> void:
	_credits.speed_scale = 0.05
	var done: Array[bool] = [false]
	_credits.finished.connect(func() -> void: done[0] = true)
	_credits.present(_rows(), true)
	await wait_process_frames(3)
	assert_true(_credits.is_showing())
	_credits.skip()
	await wait_until(func() -> bool: return done[0], 3.0)
	assert_true(done[0], "passé")


## Q30-4 : consultation (lecture seule) de plusieurs entrées, puis l'écran se ferme.
func test_browse_shows_each_entry_and_leaves() -> void:
	var views := [_view(), {"header": "Kevin · 27/10/2026", "members": [
		{"texture": PokedexArt.portrait(6), "line": "Dracaufeu — N63", "subtitle": ""}]}]
	await _hall.browse(views)
	assert_false(_hall.is_showing())
	assert_eq(_hall.get_team_size(), 1, "dernière entrée montrée")


## Q30-4 : le lien « Panthéon » de l'écran Dresseur émet sa demande.
func test_trainer_screen_hall_link_emits_its_request() -> void:
	var screen := TrainerScreen.new()
	add_child_autofree(screen)
	await wait_process_frames(1)
	var view := TrainerView.new()
	view.player_name = "Kevin"
	view.hall_of_fame_text = TrainerView.HALL_OF_FAME_LABEL
	screen.show_trainer(view)
	await wait_process_frames(1)
	var button := screen.get_hall_of_fame_button()
	assert_true(button.visible)
	assert_eq(button.text, "Panthéon")
	var asked: Array[bool] = []
	screen.hall_of_fame_requested.connect(func() -> void: asked.append(true))
	button.pressed.emit()
	assert_eq(asked, [true])
	view.hall_of_fame_text = ""
	screen.show_trainer(view)
	assert_false(button.visible, "pas de Panthéon : pas de lien")
