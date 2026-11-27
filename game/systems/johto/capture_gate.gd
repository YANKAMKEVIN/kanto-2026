class_name CaptureGate
extends RefCounted
## Où va une capture avec l'équipe pleine, et le texte qui le dit. Classe statique et pure.
##
## Historique : JH-23 (Kevin, 2026-11-02) refusait la Ball à 6 Pokémon pendant l'acte 1 du
## Chapitre Johto (Stockage hors ligne), puis l'arc des Pierres (JH-71, P-58) envoyait la capture
## en trop « chez Orme ». **PC de Johto** (demande de Kevin du 2026-11-27) : le réseau de Kanto
## reste coupé, mais les PC de Johto ont leur propre stockage local, la **Boîte de Johto** (le
## Stockage du joueur pendant l'acte 1, [TeamConfiscation]). La Ball n'est donc plus jamais
## refusée pour une équipe pleine : la capture va dans la Boîte de Johto, avec
## [constant SENT_TO_JOHTO_BOX_KEY].

## Clés de la ligne de la carte de capture quand l'équipe est pleine.
const SENT_TO_STORAGE_KEY: StringName = &"sent_to_storage"
const SENT_TO_JOHTO_BOX_KEY: StringName = &"sent_to_johto_box"


## Clé du texte d'une capture rangée au Stockage : la Boîte de Johto tant que le réseau de
## Kanto est coupé.
static func stored_key(flags: StoryFlags) -> StringName:
	return SENT_TO_JOHTO_BOX_KEY if TeamConfiscation.is_storage_offline(flags) \
		else SENT_TO_STORAGE_KEY
