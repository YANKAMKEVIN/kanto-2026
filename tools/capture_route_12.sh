#!/usr/bin/env bash
# Captures de la Route 12 nord et de son poste (jalon 21 T21), 2340 × 1080, Movie Maker (Mac, pas
# en headless) :
#   tools/capture_route_12.sh [dossier [filtre]]   (défaut : build/captures/jalon21_t21)
# Réutilise `tools/capture_pewter.gd` ; override.cfg temporaire à la racine, retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon21_t21}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg
M="--map=route_12"
SHOTS=(
	"r12_arrivee_lavanville|40|$M --cell=22,3 --facing=down"
	"r12_ponton_palier|40|$M --cell=22,14 --facing=down"
	"r12_poste_nord|40|$M --cell=25,22 --facing=down"
	"r12_poste_sud|40|$M --cell=25,34 --facing=down"
	"r12_pecheur_1|40|$M --cell=24,47 --facing=right"
	"r12_croisement|40|$M --cell=25,90 --facing=down"
	"r12_chaussee_route_11|40|$M --cell=6,93 --facing=right"
	"r12_ensemble|20|$M --aim=19,51 --zoom=0.1 --noplayer"
	"r12_poste_1f|40|--map=route_12_gate --spawn=entrance_nord --facing=down"
	"r12_poste_2f|40|--map=route_12_gate_2f --spawn=from_1f --facing=down"
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
