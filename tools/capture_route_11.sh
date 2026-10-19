#!/usr/bin/env bash
# Captures de la Route 11 (jalon 17 T16/T17), 2340 × 1080, Movie Maker (Mac, pas en headless) :
#   tools/capture_route_11.sh [dossier [filtre]]   (défaut : build/captures/jalon17_t16)
# Réutilise `tools/capture_pewter.gd` ; override.cfg temporaire à la racine, retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon17_t16}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg
M="--map=route_11"
SHOTS=(
	"r11_arrivee|40|$M --cell=2,12 --facing=right"
	"r11_goulet_arthur|40|$M --cell=7,12 --facing=right"
	"r11_cave|40|$M --cell=16,9 --facing=up"
	"r11_prairie_nord|40|$M --cell=34,11 --facing=right"
	"r11_chemin_central|40|$M --cell=31,18 --facing=down"
	"r11_digue|40|$M --cell=40,22 --facing=right"
	# J21 T9a (M-3) : Ronflex retiré ; goulet libre et bord est « ROUTE 12 — À venir ».
	"r11_goulet_est_loin|40|$M --cell=55,14 --facing=right"
	"r11_goulet_est|40|$M --cell=64,14 --facing=right"
	"r11_bord_est|40|$M --cell=72,14 --facing=right"
	"r11_ensemble|20|$M --aim=38,18 --zoom=0.26 --noplayer"
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
