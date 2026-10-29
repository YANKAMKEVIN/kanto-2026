#!/usr/bin/env bash
# Captures 2340 × 1080 (Mac, Movie Maker) des quatre salles du Conseil des 4 avec leurs sprites peints
# (DAF.4 reliquat, RP-136) : tools/capture_daf4_ligue.sh [dossier]  (défaut : build/captures/daf4_ligue)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/daf4_ligue}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' > override.cfg
SHOTS=(
	"olga|40|--map=league_lorelei --cell=5,6 --facing=up"
	"aldo|40|--map=league_bruno --cell=5,6 --facing=up"
	"agatha|40|--map=league_agatha --cell=5,6 --facing=up"
	"peter|40|--map=league_lance --cell=6,5 --facing=up"
	"champion|40|--map=league_champion --cell=4,6 --facing=up"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" && echo "  ($name : erreurs ci-dessus)" || true
	cp "$(ls "$TMP"/f/f*.png | sort | tail -1)" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
