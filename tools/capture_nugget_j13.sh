#!/usr/bin/env bash
# Captures du recruteur et du Pont Pépite (jalon 13 T22), 2340 × 1080, Movie Maker (Mac, pas en
# headless) : tools/capture_nugget_j13.sh [dossier] [mode : rocket | bridge | tout]
# Chaque « image : <nom> <n> » imprimée par tools/capture_nugget_j13.gd est copiée depuis le film.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/j13_t22}"
MODES="${2:-rocket bridge}"
[[ "$MODES" == tout ]] && MODES="rocket bridge"
mkdir -p "$OUT"
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg
trap 'rm -f override.cfg' EXIT
for mode in $MODES; do
	TMP="$(mktemp -d)"
	godot --path . --write-movie "$TMP/f.png" --fixed-fps 30 \
		-s res://tools/capture_nugget_j13.gd -- --mode="$mode" --out="$OUT" > "$TMP/log.txt" 2>&1 || true
	grep -E "^image : " "$TMP/log.txt" | while read -r _ _ name index; do
		src="$(printf '%s/f%08d.png' "$TMP" "$index")"; [ -f "$src" ] && cp "$src" "$OUT/$name.png"
		echo "$OUT/$name.png"
	done
done
