extends SceneTree
## Captures de l'art des Pokémon de Johto (fiche docs/design/fiches-assets/serie-johto-pokemon.md) :
## vrai Boot à Oliville, équipe de Johto, toutes les espèces de Johto capturées, puis le Pokédex
## (grille filtrée sur Johto, fiches de quelques espèces), l'écran Équipe (vignettes) et le Sac
## (objets d'évolution).
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 4000 \
##     -s res://tools/capture_johto_art.gd -- --out=build/captures/johto_art
## Images : dex_grille_johto, dex_fiche_<espèce> (une par espèce de SHEETS), equipe, sac.

const SHEETS: Array[StringName] = [&"chikorita", &"cyndaquil", &"totodile", &"suicune", &"tyranitar",
	&"ho_oh"]
const PARTY: Array[StringName] = [&"chikorita", &"quilava", &"feraligatr", &"ampharos", &"scizor",
	&"lugia"]
const ITEMS: Array[StringName] = [&"kings_rock", &"metal_coat", &"dragon_scale", &"up_grade"]

var _out_dir: String = "build/captures/johto_art"
var _boot: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE %s/%s.png" % [_out_dir, name])


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"force_debug_start", false)
	_boot.set(&"force_debug_unlocks", true)
	_boot.set(&"debug_unlocks_path", "res://tests/fixtures/debug_unlocks/pokedex.json")
	_boot.set(&"start_map", &"olivine_city")
	_boot.set(&"start_spawn", &"from_route_39")
	root.add_child(_boot)
	await _frames(90)
	var state: Node = root.get_node("GameState")
	state.call(&"new_game", 5)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = state.get(&"party")
	for i: int in PARTY.size():
		party.add(PokemonFactory.create(data, PARTY[i], 30 + i * 4, GameRng.new(11 + i)))
	for id: StringName in data.get_species_ids():
		if data.get_species(id).dex >= 152:
			state.call(&"record_caught", id, &"olivine_city")
	var bag: Bag = state.get(&"bag")
	for item: StringName in ITEMS:
		bag.add(item, 1)
	await _frames(30)
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	for species: StringName in SHEETS:
		menu.open(MenuRoute.pokedex(MenuRoute.DEX_FILTER_ALL, species))
		await _frames(40)
		await _shot("dex_fiche_%s" % species)
		menu.close()
		await _frames(20)
	menu.open(MenuRoute.pokedex())
	await _frames(40)
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	screen.pokedex_back()
	await _frames(30)
	await _shot("dex_grille")
	menu.close()
	await _frames(20)
	menu.open(MenuRoute.team())
	await _frames(40)
	await _shot("equipe")
	menu.close()
	await _frames(20)
	menu.open(MenuRoute.bag())
	await _frames(40)
	await _shot("sac")
	print("CAPTURE_JOHTO_ART terminé")
	quit()
