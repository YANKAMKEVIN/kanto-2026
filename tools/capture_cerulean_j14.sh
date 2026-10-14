#!/usr/bin/env bash
# Captures d'Azuria du J14 (jalon 14 T20b), 2340 × 1080, Movie Maker (Mac, pas en headless) :
#   tools/capture_cerulean_j14.sh [dossier [filtre]]   (défaut : build/captures/jalon14_t20b)
# Utilise `tools/capture_pewter.gd` (générique : `--boot` = vraie scène de jeu, départ `--start=`,
# drapeaux `--flags=`, case `--cell=`). Une image par plan (dernière du film).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon14_t20b}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

B="--boot --start=cerulean_garden"
A="--boot --start=cerulean_after"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"jardin_rue|40|$B --cell=4,3 --facing=right"
	"jardin_repere|40|$B --cell=8,2 --facing=right --flags=cerulean_rocket_spotted"
	"jardin_avant|40|$B --cell=11,3 --facing=right"
	"impasse_fond|40|$B --cell=17,3 --facing=right --flags=cerulean_rocket_spotted"
	"impasse_trou|40|$B --cell=13,3 --facing=right --flags=cerulean_rocket_spotted"
	"maison_avant|40|$B --cell=10,10 --facing=up"
	"maison_ouverte|40|$A --cell=10,10 --facing=up"
	"maison_jardin_apres|40|$A --cell=13,3 --facing=right"
	"barrage_avant|40|$B --cell=32,35 --facing=down"
	"barrage_apres|40|$A --cell=32,35 --facing=down --flags=cerulean_south_guard_left"
	"barrage_bas|40|$A --cell=32,39 --facing=down --flags=cerulean_south_guard_left"
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
