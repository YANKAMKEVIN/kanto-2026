#!/usr/bin/env bash
# Captures de combat de l'audit J33 T2 : un vrai combat sauvage par carte (fond de combat de la
# carte, tools/capture_t2_combat.gd, repli `_fallback` : transition + actions), 2340 × 1080.
#   tools/capture_t2_combats.sh [dossier]   (défaut : build/captures/t2_combats)
set -uo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/t2_combats}"
mkdir -p "$OUT"
for PLACE in route_2 viridian_forest mt_moon_1f route_4 route_9 route_22 route_25 \
	cerulean_cave_1f dark_cave_1f seafoam_b1f route_19 power_plant safari_zone_center \
	victory_road_1f pokemon_tower_3f silph_co_1f pewter_gym fuchsia_gym cinnabar_gym; do
	godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 3000 \
		-s res://tools/capture_t2_combat.gd -- --out="$OUT" --place="$PLACE" 2>&1 \
		| grep -E "ERROR|CAPTURE_CB3" | head -3
done
