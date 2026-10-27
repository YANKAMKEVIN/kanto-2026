#!/usr/bin/env bash
# Captures de la Centrale (jalon 32, lot 32G) et de son accès par la Route 10, à 2340 × 1080, Movie
# Maker (Mac, pas en headless), avec les vrais composants (tools/capture_viridian_forest.gd).
#
#   tools/capture_power_plant.sh [dossier [filtre]]   (défaut : build/captures/j32, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/j32}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_viridian_forest.gd
SHOTS=(
	"centrale_entree|40|--map=power_plant --cell=4,34 --facing=up"
	"centrale_electhor|40|--map=power_plant --cell=4,11 --facing=up"
	"centrale_fausses_balls|40|--map=power_plant --cell=24,19 --facing=up"
	"centrale_ct|40|--map=power_plant --cell=23,33 --facing=right"
	"route10_quai|40|--map=route_10 --cell=30,10 --facing=up"
	"route10_belvedere|40|--map=route_10 --cell=23,14 --facing=right"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_viridian_forest.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
