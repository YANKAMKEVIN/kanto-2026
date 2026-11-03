class_name SaveSummary
extends RefCounted
## Résumé d'une sauvegarde pour la carte Continuer et la confirmation (dossier 13 §5.2, §5.4).
##
## Classe pure. Lue dans le **dictionnaire de sauvegarde** rendu par [method SaveSystem.read]
## (déjà migré ; clés de `GameState.to_dict()` : « player_name », « map », « play_time »,
## « flags », « pokedex » { entries { espèce: { caught } } }), sans passer par [GameState] :
## le titre n'a pas à charger la partie pour l'afficher. Tout champ absent ou mal formé prend
## une valeur neutre, rien ne plante.
##  - lieu : le nom de zone vient d'un [Callable] injecté (`ZoneLibrary.zone_name_of`) ;
##  - badges : un badge est obtenu quand son drapeau est levé ([BadgeLibrary]) ; l'appelant
##    donne la liste des drapeaux de badge ;
##  - captures : espèces capturées du Pokédex (comme le tableau de bord), affichées seulement
##    si le Pokédex est activé (drapeau [constant StoryFlags.POKEDEX_ACTIVATED]).

var player_name: String = ""
## Apparence du joueur (buste de la carte Continuer ; chantier JR) ; le héros si absente.
var player_look: StringName = &"hero"
## Costume porté (buste de la carte Continuer ; dossier-costumes.md CO-9) : &"" (tenue d'origine)
## s'il est absent, inconnu ou si son badge manque.
var player_costume: StringName = &""
## Carte courante (identifiant) et nom de sa zone ("" si inconnu).
var map_id: StringName = &""
var zone_name: String = ""
## Temps de jeu en secondes.
var play_time: float = 0.0
var badge_count: int = 0
## Dernier badge obtenu dans l'ordre des arènes (même règle que [member DashboardView.badge_id]) ;
## &"" sans badge ou si l'appelant n'a pas donné les identifiants. Lecture seule : le format de
## sauvegarde ne change pas (déduit des drapeaux).
var badge_id: StringName = &""
## Espèces capturées.
var caught_count: int = 0
var pokedex_active: bool = false


## Résumé de [param save] ([method SaveSystem.read]). [param zone_name_of] :
## `func(map_id: StringName) -> String` (peut être invalide : pas de lieu). [param badge_flags] :
## drapeaux des badges, dans l'ordre des arènes. [param fallback_name] : prénom si la sauvegarde
## n'en a pas. [param badge_ids] : identifiants des badges, au même rang que leurs drapeaux
## (vide : pas de [member badge_id]).
static func from_save(save: Dictionary, zone_name_of: Callable = Callable(),
		badge_flags: Array[StringName] = [], fallback_name: String = "",
		badge_ids: Array[StringName] = []) -> SaveSummary:
	var summary := SaveSummary.new()
	summary.player_name = JsonFields.get_string(save, "player_name").strip_edges()
	if summary.player_name.is_empty():
		summary.player_name = fallback_name
	summary.player_look = JsonFields.get_id(save, "player_look", &"hero")
	summary.map_id = JsonFields.get_id(save, "map")
	if zone_name_of.is_valid() and not summary.map_id.is_empty():
		var zone: Variant = zone_name_of.call(summary.map_id)
		summary.zone_name = zone if zone is String else ""
	summary.play_time = maxf(JsonFields.get_float(save, "play_time"), 0.0)
	var flags := JsonFields.get_ids(save, "flags")
	for index: int in badge_flags.size():
		if flags.has(badge_flags[index]):
			summary.badge_count += 1
			if index < badge_ids.size():
				summary.badge_id = badge_ids[index]
	summary.pokedex_active = flags.has(StoryFlags.POKEDEX_ACTIVATED)
	summary.player_costume = CostumeCatalog.shared().worn(
		JsonFields.get_id(save, "player_costume"), flags.has)
	var entries := JsonFields.get_dict(JsonFields.get_dict(save, "pokedex"), "entries")
	for species: Variant in entries:
		var entry: Variant = entries[species]
		if entry is Dictionary and JsonFields.get_bool(entry, "caught"):
			summary.caught_count += 1
	return summary


## « 20 h 12 » ([method MenuFormat.play_time], comme le Menu Dresseur).
func play_time_text() -> String:
	return MenuFormat.play_time(play_time)


## « 1 badge », « 3 badges » ; "" sans badge (jamais « 0 badge », comme le tableau de bord).
func badges_text() -> String:
	return DashboardViews.badges_text(badge_count)


## « 14 capturés » ; "" tant que le Pokédex n'est pas activé.
func caught_text() -> String:
	return DashboardViews.caught_text(caught_count) if pokedex_active else ""
