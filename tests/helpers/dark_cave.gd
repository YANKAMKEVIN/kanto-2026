extends RefCounted
## Grotte obscure de test (J17 T28) : la carte de QA `qa_flash` est retirée, le voile
## d'obscurité et Flash s'éprouvent dans le vrai Boot sur la **Cave Taupiqueur rendue obscure en
## mémoire** (copie de `data/world/caves.json` avec `"dark": true`, écrite sous `user://` et
## passée à [member Boot.caves_path]). Rien n'est livré : le jeu garde la Cave éclairée.
##
## Départs de débogage écrits de même : devant la bouche nord de la Cave, sur la Route 2 est
## (`from_cave_w` (6, 4), tourné vers le nord) ; un pas vers le nord entre dans la Cave
## (`from_route_2_east` (16, 1), au bord nord : caméra bornée) ; on en ressort par un pas vers
## la bouche (16, 0), puis en poussant vers le nord (passage « pousser », [method leave_north]).

const CAVE: StringName = &"digletts_cave"
const OUTSIDE: StringName = &"route_2_east"
const CAVES_PATH: String = "user://test_dark_caves.json"
const START_PATH: String = "user://test_dark_cave_start.json"
## Bouche nord de la Cave (passage « pousser » vers la Route 2 est).
const NORTH_MOUTH := Vector2i(16, 0)

## Équipes des départs (anciens `flash_qa*`).
enum Team { FLASH, NO_HM, NO_POKEMON, FAINTED }

const _FLAGS: Array[String] = ["mom_greeted", "rival_met", "oak_met", "oak_lab_reunion",
	"starter_offered", "starter_chosen", "taken_charmander", "taken_squirtle", "rival_lab_won",
	"rival_challenged", "rival_battle_done", "rival_left_lab", "viridian_arrived",
	"got_oak_parcel", "pokedex_activated", "poison_unlocked", "pewter_arrived", "badge_boulder"]


## Écrit les grottes du jeu avec la Cave Taupiqueur obscure ; rend le chemin.
static func write_caves(path: String = CAVES_PATH) -> String:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		CaveLibrary.DATA_PATH))
	(data["caves"][String(CAVE)] as Dictionary)["dark"] = true
	_write(path, data)
	return path


## Départ de débogage : [param team] ; [param inside] le pose dans la Cave (reprise).
static func start(team: Team, inside: bool = false) -> Dictionary:
	var flags: Array[String] = _FLAGS.duplicate()
	var bag := {"poke_ball": 5, "potion": 3, "escape_rope": 2}
	if team != Team.NO_HM:
		flags.append("got_hm05")
		bag["hm05"] = 1
	var pikachu := {"species": "pikachu", "level": 20}
	var charmeleon := {"species": "charmeleon", "level": 22}
	var pidgeotto := {"species": "pidgeotto", "level": 19}
	var party: Array = [pikachu, charmeleon, pidgeotto]
	var result := {"map": String(OUTSIDE), "spawn": "from_cave_w", "facing": "up",
		"flags": flags, "bag": bag, "money": 3000, "companion": 0}
	match team:
		Team.NO_POKEMON:
			party = [charmeleon, pidgeotto]
		Team.FAINTED:
			pikachu["hp"] = 0
			party = [charmeleon, pikachu, pidgeotto]
			result.erase("companion")
	result["party"] = party
	if inside:
		result["map"] = String(CAVE)
		result["spawn"] = "from_route_2_east_w"
		result["facing"] = "down"
	return result


## Écrit [param data] (un départ) ; rend le chemin.
static func write_start(data: Dictionary, path: String = START_PATH) -> String:
	_write(path, data)
	return path


## Sort de la Cave par la bouche nord : un pas jusqu'à la bouche, puis pousser vers le nord
## jusqu'au début du changement de carte.
static func leave_north(test: GutTest, boot: Boot, timeout: float) -> void:
	var player := boot.get_player()
	test.assert_true(player.script_step(Vector2i.UP), "pas vers la bouche nord")
	await test.wait_until(func() -> bool: return player.get_cell() == NORTH_MOUTH \
		and not player.is_moving(), timeout)
	Input.action_press(&"move_up")
	await test.wait_until(func() -> bool: return SceneRouter.is_transitioning(), timeout)
	Input.action_release(&"move_up")


static func cleanup() -> void:
	Input.action_release(&"move_up")
	for path: String in [CAVES_PATH, START_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


static func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
