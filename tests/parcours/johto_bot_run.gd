extends GutTest
## Bot de parcours de Johto ([JohtoBot], `tests/parcours/johto_bot.gd`) : une seule partie, de la
## lettre d'Orme (`johto_letter`) au retour à Bourg Palette (`johto_chapter_done`), jouée seule sur
## la vraie scène Boot. Le journal (actions, puis diagnostic du blocage) est imprimé dans la sortie
## de GUT ; le test échoue si le chapitre n'est pas terminé ou si le bot a dû sortir d'un cul-de-sac.
## Hors de la suite (nom sans « test_ », 1 à 2 h) : `tools/johto_bot.sh`, ou le workflow
## « Johto bot » de GitHub (lancement à la main).

const JohtoBot := preload("res://tests/parcours/johto_bot.gd")

var _bot: JohtoBot


func before_each() -> void:
	_bot = JohtoBot.new(self)
	_bot.setup()


func after_each() -> void:
	_bot.teardown()


func test_johto_from_letter_to_chapter_end() -> void:
	# Pour reprendre ailleurs pendant une mise au point : JOHTO_BOT_START=<départ de débogage>.
	var start := OS.get_environment("JOHTO_BOT_START")
	await _bot.start(JohtoBot.START if start.is_empty()
		else "res://tools/debug_start/%s.json" % start)
	var done: bool = await _bot.run()
	gut.p("Bot de Johto : %s, %d action(s)" % ["chapitre terminé" if done else "BLOQUÉ",
		_bot.actions.size()])
	for line: String in _bot.journal():
		gut.p(line)
	assert_true(done, "\n".join(_bot.stall))
	assert_eq(_bot.dead_ends, [] as Array[String],
		"culs-de-sac (le bot en sort à la Corde Sortie, un joueur sans Corde y reste)")
