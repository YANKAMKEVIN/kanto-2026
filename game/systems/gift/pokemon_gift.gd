class_name PokemonGift
extends RefCounted
## Don d'un Pokémon par un PNJ ou un objet du monde (jalon 20, Évoli de la Résidence Céladon ;
## dossier 23 §10, §19 ; jalon-20.md §2.5.1). Classe pure et statique, réutilisable : espèce,
## niveau, carte et drapeau sont des paramètres (données de la scène, T12).
##
## [method give] travaille **en un seul bloc synchrone** (aucune attente) : aucune sauvegarde ne
## peut s'écrire entre l'arrivée du Pokémon et la pose du drapeau. Dans l'ordre :
## 1. refus si le drapeau est déjà levé (ALREADY_RECEIVED) ou l'espèce inconnue ;
## 2. [method PokemonFactory.create] avec l'aléatoire de la partie (capacités du niveau, sexe) ;
## 3. l'équipe, sinon le Stockage (identifiant attribué par l'un ou l'autre) ;
## 4. Pokédex : vu **et** capturé, daté ([code]record_caught[/code]) ;
## 5. rencontre : origine [constant ORIGIN], carte, niveau, date, dresseur = le joueur ;
## 6. le drapeau.
## Aucun écran de surnom (le jeu n'en a pas, même à la capture : jalon-20.md §0.2 n° 7).
## Sur un refus, rien ne change (pas même l'aléatoire).

enum Status {
	JOINED, ## Le Pokémon a rejoint l'équipe.
	STORED, ## Équipe pleine : le Pokémon est au Stockage.
	ALREADY_RECEIVED, ## Le drapeau est déjà levé : pas de second don.
	UNKNOWN_SPECIES, ## Espèce absente des données.
	INVALID, ## Appel mal formé : état ou données absents, drapeau vide, niveau < 1.
}

## Origine posée sur le Pokémon donné. Provisoire : `Pokemon.Origin.GIFT` n'existe pas encore
## (ajouté en fin d'enum au T12, fichier partagé) ; le T12 remplace cette valeur.
const ORIGIN: Pokemon.Origin = Pokemon.Origin.CAPTURE


## Donne un [param species] de niveau [param level] reçu sur [param map], une seule fois par
## [param flag]. [param state] : l'état de la partie (`GameState` ou une instance de test :
## `flags`, `party`, `storage`, `rng`, `record_caught`, `stamp_meeting`).
static func give(state: Object, data: PokemonData, species: StringName, level: int,
		map: StringName, flag: StringName) -> GiftResult:
	if state == null or data == null or flag.is_empty() or level < 1:
		return GiftResult.new(Status.INVALID)
	if (state.flags as StoryFlags).has_flag(flag):
		return GiftResult.new(Status.ALREADY_RECEIVED)
	if data.get_species(species) == null:
		return GiftResult.new(Status.UNKNOWN_SPECIES)
	var pokemon := PokemonFactory.create(data, species, level, state.rng as GameRng)
	if pokemon == null:
		return GiftResult.new(Status.UNKNOWN_SPECIES)
	var status := Status.JOINED
	if not (state.party as Party).add(pokemon):
		(state.storage as PokemonStorage).add(pokemon)
		status = Status.STORED
	state.record_caught(species, map)
	state.stamp_meeting(pokemon, ORIGIN, map)
	(state.flags as StoryFlags).set_flag(flag)
	return GiftResult.new(status, pokemon)
