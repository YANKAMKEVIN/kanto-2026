#!/usr/bin/env bash
# Lot DAF.10d : écrit la grille logique et les nœuds de chaque carte touchée (gel du J33).
#   tools/dump_daf10a.sh avant|apres
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="build/dumps/${1:?avant|apres}"
mkdir -p "$OUT"
for m in $(cat tools/daf10d_maps.txt); do
	godot --headless --path . -s res://tools/dump_map_logic.gd -- "$m" "res://$OUT/$m.logic" > /dev/null 2>&1
	godot --headless --path . -s res://tools/dump_map_nodes.gd -- "$m" "res://$OUT/$m.nodes" > /dev/null 2>&1
done
echo "$OUT : $(ls "$OUT" | wc -l) fichiers"
