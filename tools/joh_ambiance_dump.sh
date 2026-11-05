#!/usr/bin/env bash
# Relevés de géométrie des cartes de la passe d'ambiance de Johto, lot 2 (`tools/dump_map_logic.gd`,
# `tools/dump_map_nodes.gd`) : à prendre avant et après les passes, puis `diff -r`.
#   tools/joh_ambiance_dump.sh build/relevés/avant [carte ...]
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$1"; shift
MAPS=("$@")
if [[ ${#MAPS[@]} -eq 0 ]]; then
	MAPS=(route_37 route_36 route_35 goldenrod_city goldenrod_underground goldenrod_center
		goldenrod_house_1 goldenrod_house_2 goldenrod_bond_house goldenrod_dept_store_1f
		goldenrod_dept_store_2f goldenrod_dept_store_3f goldenrod_dept_store_roof
		route_34 route_34_house ilex_forest azalea_town azalea_center azalea_mart azalea_kurt_house
		azalea_house_1 slowpoke_well_b1f slowpoke_well_b2f goldenrod_radio_tower_1f
		goldenrod_radio_tower_2f goldenrod_radio_tower_3f goldenrod_radio_tower_4f
		goldenrod_radio_tower_5f goldenrod_radio_tower_elevator route_40 route_41 whirl_islands_1f
		whirl_islands_b1f whirl_islands_b2f)
fi
mkdir -p "$OUT"
for map in "${MAPS[@]}"; do
	godot --headless --path . -s res://tools/dump_map_logic.gd -- "$map" "res://$OUT/$map.logic.txt" > /dev/null 2>&1
	godot --headless --path . -s res://tools/dump_map_nodes.gd -- "$map" "res://$OUT/$map.nodes.txt" > /dev/null 2>&1
	echo "$map"
done
