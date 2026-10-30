#!/usr/bin/env bash
# Captures du lot DAF.10c : vue d'ensemble 2340 × 1080 de chaque carte touchée (tailles lues dans la scène).
#   tools/capture_daf10c.sh <dossier> [filtre regex]
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:?dossier}"; FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
trap 'rm -f override.cfg; rm -rf "$TMP"' EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' > override.cfg
for map in $(cat tools/daf10c_maps.txt); do
	[[ "$map" =~ $FILTER ]] || continue
	read -r w h <<< "$(grep -m1 -oE '^size = Vector2i\([0-9]+, [0-9]+\)' "game/world/maps/$map.tscn" | sed -E 's/.*\(([0-9]+), ([0-9]+)\).*/\1 \2/')"
	zoom="$(awk -v w="$w" -v h="$h" 'BEGIN{a=2340/(w*96);b=1080/(h*96);z=(a<b)?a:b;if(z<0.1)z=0.1;printf "%.3f",z}')"
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after 30 \
		-s res://tools/capture_viridian_forest.gd -- --map="$map" --noplayer --boulders --gates= \
		--aim="$(awk -v w="$w" -v h="$h" 'BEGIN{printf "%.1f,%.1f",w/2,h/2}')" --zoom="$zoom" > "$TMP/log.txt" 2>&1 || true
	last="$(ls "$TMP"/f/f*.png 2>/dev/null | sort | tail -1)"
	[[ -n "$last" ]] && cp "$last" "$OUT/$map.png" && echo "$OUT/$map.png ($w x $h, zoom $zoom)"
done
