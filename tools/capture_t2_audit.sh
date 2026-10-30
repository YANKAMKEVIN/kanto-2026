#!/usr/bin/env bash
# Captures de l'audit J33 T2 (33A) : vue d'ensemble de chaque carte échantillonnée, à 2340 × 1080,
# Movie Maker (Mac, pas en headless), sans joueur, avec les vrais composants
# (tools/capture_viridian_forest.gd : `--aim` + `--zoom` + `--noplayer`).
#
#   tools/capture_t2_audit.sh [dossier [filtre]]   (défaut : build/captures/t2 ; filtre = regex sur le nom)
# Lecture seule : aucun fichier du jeu n'est modifié.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/t2}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# carte largeur hauteur (cases) ; le zoom ajuste la carte entière dans 2340 × 1080 (plancher 0,1)
MAPS=(
	"pallet_town 48 34" "viridian_city 56 36" "pewter_city 52 44" "cerulean_city 56 41"
	"vermilion_city 64 43" "lavender_town 44 36" "celadon_city 70 46" "fuchsia_city 60 54"
	"saffron_city 60 50" "cinnabar_island 34 27" "indigo_plateau 20 18"
	"route_1 48 44" "route_2 42 60" "route_2_north 30 24" "route_2_east 16 48" "route_3 82 38"
	"route_4 64 24" "route_5 42 62" "route_6 42 56" "route_7 28 24" "route_8 80 26" "route_9 80 36"
	"route_10 34 76" "route_11 76 36" "route_12 39 102" "route_15 90 27" "route_16 44 28"
	"route_18 75 27" "route_19 30 81" "route_21 30 135" "route_22 46 27" "route_23 20 144"
	"route_24 56 62" "route_25 80 28"
	"viridian_forest 70 90" "mt_moon_1f 60 46" "mt_moon_b1f 40 30" "dark_cave_1f 56 49"
	"digletts_cave 34 80" "seafoam_1f 30 18" "seafoam_b3f 30 18" "cerulean_cave_1f 30 18"
	"cerulean_cave_b1f 30 18" "victory_road_1f 20 18" "victory_road_3f 30 18"
	"rocket_hideout_b1f 30 28" "rocket_hideout_b4f 30 24" "power_plant 40 36"
	"pokemon_tower_3f 20 18" "pokemon_tower_6f 20 18" "pokemon_mansion_1f 30 28"
	"pokemon_mansion_b1f 30 28" "silph_co_1f 30 18" "silph_co_7f 26 18" "silph_co_11f 18 18"
	"safari_zone_center 30 26" "safari_zone_north 40 36" "underground_path 26 30"
	"player_house_1f 14 10" "player_house_2f 14 10" "oak_lab 16 11" "rival_house 18 11"
	"viridian_center 15 10" "viridian_mart 15 10" "pewter_museum 15 10" "pewter_house_mason 15 10"
	"viridian_gym 24 22" "pewter_gym 15 11" "cerulean_gym 17 13" "vermilion_gym 17 15"
	"celadon_gym 17 16" "saffron_gym 20 18" "fuchsia_gym 14 20" "cinnabar_gym 20 18"
	"celadon_dept_gf 20 13" "celadon_dept_3f 20 13" "celadon_game_corner 20 18"
	"ss_anne_main_deck 26 13" "ss_anne_lower_deck 22 11" "ss_anne_captain_room 14 10"
	"cinnabar_lab 27 12" "fighting_dojo 10 12" "route_16_gate 14 10"
	"indigo_plateau_lobby 15 10" "league_lorelei 10 12" "league_lance 26 26" "league_champion 8 8"
	"hall_of_fame 10 8"
	"route_13 90 27" "route_14 30 81" "route_17 30 150" "route_20 150 27" "fuchsia_center 15 10"
	"route_15_gate 12 10" "safari_zone_rest_house_center 15 10" "seafoam_b4f 30 18" "route_12_gate 10 8"
)
for entry in "${MAPS[@]}"; do
	read -r map w h <<< "$entry"
	[[ "$map" =~ $FILTER ]] || continue
	zoom="$(awk -v w="$w" -v h="$h" 'BEGIN{a=2340/(w*96);b=1080/(h*96);z=(a<b)?a:b;if(z<0.1)z=0.1;printf "%.3f",z}')"
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after 30 \
		-s res://tools/capture_viridian_forest.gd -- --map="$map" --noplayer \
		--aim="$(awk -v w="$w" -v h="$h" 'BEGIN{printf "%.1f,%.1f",w/2,h/2}')" --zoom="$zoom" \
		> "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" | head -3 && echo "  ($map : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png 2>/dev/null | sort | tail -1)"
	[[ -n "$last" ]] && cp "$last" "$OUT/$map.png" && echo "$OUT/$map.png (zoom $zoom)"
done
