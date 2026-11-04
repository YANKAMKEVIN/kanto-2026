class_name CaptureGate
extends RefCounted
## Lancer refusé à 6 Pokémon pendant l'acte 1 du Chapitre Johto (JH-23, Kevin, 2026-11-02 ;
## `jalon-joh0.md` §2.2 ; dossier JOH-01 §6.3). Classe statique et pure.
##
## Le Stockage étant hors ligne ([constant TeamConfiscation.STORAGE_OFFLINE]), une capture avec
## l'équipe pleine n'irait nulle part : le jeu refuse la Ball **avant le lancer** (la Ball n'est
## pas consommée, le tour n'est pas joué) avec [constant REFUSED_KEY] (texte dans
## `data/battle/messages.json`). Hors de l'acte 1, rien ne change : à 6, la capture va au Stockage.

## Clé du texte de refus dans les messages de combat.
const REFUSED_KEY: StringName = &"ball_refused_offline"
## Texte [D] (dossier JOH-01 §6.3), repli si le gabarit manque.
const REFUSED_TEXT: String = "Ton équipe est pleine, et le PC ne répond pas."


## Vrai si une Ball peut être lancée.
static func can_throw(party_full: bool, storage_offline: bool) -> bool:
	return not (party_full and storage_offline)


## Vrai si l'état [param state] (équipe et drapeaux) interdit le lancer.
static func blocks(party: Party, flags: StoryFlags) -> bool:
	return party != null and not can_throw(party.is_full(),
		TeamConfiscation.is_storage_offline(flags))
