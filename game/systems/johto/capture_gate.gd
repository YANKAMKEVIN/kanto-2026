class_name CaptureGate
extends RefCounted
## Lancer refusé à 6 Pokémon pendant l'acte 1 du Chapitre Johto (JH-23, Kevin, 2026-11-02 ;
## `jalon-joh0.md` §2.2 ; dossier JOH-01 §6.3). Classe statique et pure.
##
## Le Stockage étant hors ligne ([constant TeamConfiscation.STORAGE_OFFLINE]), une capture avec
## l'équipe pleine n'irait nulle part : le jeu refuse la Ball **avant le lancer** (la Ball n'est
## pas consommée, le tour n'est pas joué) avec [constant REFUSED_KEY] (texte dans
## `data/battle/messages.json`). Hors de l'acte 1, rien ne change : à 6, la capture va au Stockage.
##
## Arc des Pierres (JH-71, `jalon-joh-pierres.md` §3.3) : à partir de [constant STONES_QUEST], la
## Ball n'est plus refusée. La capture en trop suit le chemin « équipe pleine » vers le Stockage,
## qui reste fermé au joueur (aucun retrait avant le retour de l'équipe), avec le texte
## [constant SENT_TO_ORME_KEY] (P-58).

## Clé du texte de refus dans les messages de combat.
const REFUSED_KEY: StringName = &"ball_refused_offline"
## Texte [D] (dossier JOH-01 §6.3), repli si le gabarit manque.
const REFUSED_TEXT: String = "Ton équipe est pleine, et le PC ne répond pas."
## Quête des pierres (posée à la Tour Radio) : la capture en trop part au Stockage fermé.
const STONES_QUEST: StringName = &"johto_stones_quest"
## Clés de la ligne de la carte de capture quand l'équipe est pleine.
const SENT_TO_STORAGE_KEY: StringName = &"sent_to_storage"
const SENT_TO_ORME_KEY: StringName = &"sent_to_orme"


## Vrai si une Ball peut être lancée.
static func can_throw(party_full: bool, storage_offline: bool) -> bool:
	return not (party_full and storage_offline)


## Vrai si l'état [param state] (équipe et drapeaux) interdit le lancer.
static func blocks(party: Party, flags: StoryFlags) -> bool:
	return party != null and not can_throw(party.is_full(),
		TeamConfiscation.is_storage_offline(flags) and not _stones_quest(flags))


## Clé du texte d'une capture rangée au Stockage : P-58 tant que le Stockage est fermé.
static func stored_key(flags: StoryFlags) -> StringName:
	return SENT_TO_ORME_KEY if TeamConfiscation.is_storage_offline(flags) else SENT_TO_STORAGE_KEY


static func _stones_quest(flags: StoryFlags) -> bool:
	return flags != null and flags.has_flag(STONES_QUEST)
