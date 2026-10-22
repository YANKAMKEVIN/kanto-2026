#!/usr/bin/env bash
# Planche « vie » du J18 : Lou (Route 9), Centre de la Route 10, grotte (Dresseur qui sort de
# l'ombre, Flash), Lavanville, Tour. 2340 × 1080, Movie Maker (Mac). Une image par plan dans
# build/captures/j18_vie/ (dernière image du film).  Usage : tools/capture_j18_vie.sh [filtre]
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="build/captures/j18_vie"
FILTER="${1:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg
# nom | images | options de capture_pewter.gd
SHOTS=(
	"1_lou_route_9|40|--map=route_9 --cell=10,23 --facing=up"
	"2_centre_route_10|40|--map=route_10_center --spawn=heal --facing=up"
	"2b_panneau_centre|40|--map=route_10 --cell=12,12 --facing=up"
	"3_grotte_dresseur|170|--boot --start=dark_cave_1f --cell=27,11 --facing=up --hold=up --mash=4"
	"4_grotte_flash|40|--map=dark_cave_1f --cell=30,15 --facing=right --voile=lit"
	"5_lavanville|40|--map=lavender_town --cell=22,12 --facing=down"
	"6_tour_exorciste|40|--map=pokemon_tower_1f --cell=17,6 --facing=up"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
