extends GutTest
## Extérieurs plus petits qu'un écran 20:9 (25 × 12 cases) : aucun ne laisse voir le fond noir du
## projet. Soit `tools/decor_hors_limites.py` y a posé du décor, soit la carte est déjà garnie hors
## de ses limites (liste relevée le 2026-11-10 avec `tools/audit_bords_noirs.gd`). Une nouvelle
## carte extérieure étroite fait échouer ce test tant qu'elle n'a pas son décor.

const MAPS_DIR := "res://game/world/maps/"
const CLOSED_PROFILES: Array[String] = ["interior_warm", "office", "tower", "tower_cold", "cave_1f",
	"cave_b1f", "hideout", "greenhouse", "sea_cave", "underground", "whirl_islands_b2f"]
## Sans profil de lumière, mais fermés.
const CLOSED_MAPS: Array[String] = ["fighting_dojo", "safari_zone_gate", "safari_zone_secret_house",
	"safari_zone_rest_house_center", "safari_zone_rest_house_east", "safari_zone_rest_house_north",
	"safari_zone_rest_house_west", "saffron_gym", "wardens_house", "olivine_center_room"]
## Déjà garnis autrement (peinture, falaises, mer ou paysage posés hors des limites).
const ALREADY_FILLED: Array[String] = ["route_23", "indigo_plateau", "mt_silver_summit",
	"bell_tower_roof", "goeland_deck"]
const MIN_CELLS := Vector2i(25, 12)


func test_narrow_exteriors_have_side_decor() -> void:
	var size_pattern := RegEx.create_from_string("size = Vector2i\\((\\d+), (\\d+)\\)")
	var profile_pattern := RegEx.create_from_string("light_profile = &\"(\\w+)\"")
	var checked := 0
	for file: String in DirAccess.get_files_at(MAPS_DIR):
		if not file.ends_with(".tscn"):
			continue
		var map_id := file.trim_suffix(".tscn")
		if map_id in CLOSED_MAPS or map_id in ALREADY_FILLED:
			continue
		var text := FileAccess.get_file_as_string(MAPS_DIR + file)
		var head := text.substr(0, text.find("\n[node", text.find("[node ")))
		var size_match := size_pattern.search(head)
		if size_match == null:
			continue
		if int(size_match.get_string(1)) >= MIN_CELLS.x and int(size_match.get_string(2)) >= MIN_CELLS.y:
			continue
		var profile := profile_pattern.search(head)
		if profile == null or profile.get_string(1) in CLOSED_PROFILES:
			continue
		checked += 1
		assert_true("name=\"SideForest" in text, "%s : fond noir visible sur les côtés" % map_id)
	assert_gt(checked, 10)
