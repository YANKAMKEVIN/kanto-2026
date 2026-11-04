extends GutTest
## Bande-annonce de l'ident (J34 v2.1, décision de Kevin du 2026-11-04) : jouée au premier
## lancement seulement (aucune sauvegarde) ; jamais avec une partie en cours, une sauvegarde
## corrompue ou plus récente.


func test_trailer_only_without_a_save() -> void:
	assert_true(OpeningDirector.trailer_plays_for(OpeningFlow.SaveStatus.NONE), "premier lancement")
	for status: OpeningFlow.SaveStatus in [OpeningFlow.SaveStatus.VALID, OpeningFlow.SaveStatus.CORRUPT,
			OpeningFlow.SaveStatus.NEWER]:
		assert_false(OpeningDirector.trailer_plays_for(status),
			"pas de bande-annonce : %s" % OpeningFlow.SaveStatus.find_key(status))
