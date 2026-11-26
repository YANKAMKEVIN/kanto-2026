class_name BootPokedexToasts
extends RefCounted
## Domaine « nouvelles du Pokédex » de [Boot] (jalon 6, `jalon-06.md` §6.9) : espèces vues par
## OBSERVER, notes débloquées, file des toasts du Pokédex (au plus un par espèce, montrés un à la
## fois quand la partie est stable).
##
## Extrait de `boot.gd` sans changer le comportement : Boot le crée au début de son `_ready`, lui
## relaie l'image ([method process]), l'arrivée sur une carte et les drapeaux d'histoire.

var _boot: Boot
## Toasts en attente (au plus un par espèce) : des paires [espèce, [titre, détail]].
var _toasts: Array[Array] = []
## Individus observés pendant la visite de la carte (OBSERVER, une fois par individu).
var _observed: Dictionary[StringName, bool] = {}


func _init(boot: Boot) -> void:
	_boot = boot


## Une seule écoute de tout ce qui s'enregistre au Pokédex (jalon-06.md §6.9), puis OBSERVER.
func setup() -> void:
	GameState.pokedex.recorded.connect(_on_pokedex_recorded)


## Mise en place de la partie : notes débloquées sans bruit (parties existantes, jalon-06.md §6.9,
## point 4), file vidée.
func reset() -> void:
	PokedexNotes.refresh(GameState.pokedex, _boot.get_pokedex_library(), GameState.flags)
	_toasts.clear()


## Écran noir d'un changement de carte : nouvelle visite, chaque individu peut être réobservé.
func clear_observed() -> void:
	_observed.clear()


## Une fois par image : le toast suivant, s'il y en a un et que le moment s'y prête.
func process() -> void:
	if not _toasts.is_empty():
		_show_next()


## OBSERVER (Q-7, jalon-06.md §6.9) : l'espèce est « vue » ici, une fois par individu et par
## visite de la carte. Le toast éventuel vient plus tard (file différée).
func on_observed(npc: Npc, species: StringName) -> void:
	if _observed.has(npc.get_id()):
		return
	_observed[npc.get_id()] = true
	GameState.record_seen(species, _boot.current_map_id())


## Un drapeau d'histoire a changé : notes de toutes les espèces ; un toast par espèce concernée,
## sauf à l'activation du Pokédex (tout apparaît d'un coup, sans rafale).
func on_flag_changed(flag: StringName) -> void:
	var fresh := PokedexNotes.refresh(GameState.pokedex, _boot.get_pokedex_library(),
		GameState.flags)
	if flag == StoryFlags.POKEDEX_ACTIVATED:
		return
	for species: StringName in PokedexNotes.species_of(fresh):
		_queue(species, PokedexUpdates.Kind.NEW_NOTE)


## Une espèce vient d'être vue ou capturée : notes rafraîchies, puis toast en attente.
func _on_pokedex_recorded(species: StringName, map: StringName, first_seen: bool,
		new_map: bool, caught: bool) -> void:
	var fresh := PokedexNotes.refresh(GameState.pokedex, _boot.get_pokedex_library(),
		GameState.flags, species)
	var kind := PokedexUpdates.classify(GameState.pokedex, _boot.get_pokemon_data(),
		_boot.get_zone_library(), species, map, first_seen, new_map, caught, not fresh.is_empty())
	_queue(species, kind)


func _queue(species: StringName, kind: PokedexUpdates.Kind) -> void:
	for pending: Array in _toasts:
		if pending[0] == species:
			return
	var data := _boot.get_pokemon_data().get_species(species)
	var message := PokedexUpdates.message(kind, data.name if data != null else "",
		_boot.get_menu_unlocks().pokedex_visible())
	if not message.is_empty():
		_toasts.append([species, message])


## Un toast à la fois, seulement partie stable, menu fermé, aucun toast à l'écran. Il porte la
## vignette peinte de l'espèce (une espèce nommée par un toast est déjà vue : rien n'est révélé).
func _show_next() -> void:
	var hud := _boot.get_hud()
	if _boot.get_menu_director().is_open() or not _boot.is_stable() \
			or hud.get_toast().is_showing():
		return
	var entry: Array = _toasts.pop_front()
	var message: PackedStringArray = entry[1]
	var species := _boot.get_pokemon_data().get_species(entry[0])
	hud.show_toast(message[0], message[1],
		MenuArt.pokemon_thumbnail(species.dex) if species != null else null)
