#!/usr/bin/env bash
# Captures du lot DAF.10b « Routes 13 à 21 » (RP-272, RP-273, RP-274) : vues d'ensemble et vues à
# hauteur du joueur, 2340 × 1080, Movie Maker (Mac, pas en headless), vrais composants (carte,
# joueur, WorldLighting + profil de la carte : tools/capture_viridian_forest.gd).
#
#   tools/capture_daf10b.sh [dossier [filtre]]   (défaut : build/captures/daf10b, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/daf10b}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_viridian_forest.gd
SHOTS=(
	"route_12_south_vue|30|--map=route_12_south --noplayer --aim=15,35 --zoom=0.16"
	"route_13_vue|30|--map=route_13 --noplayer --aim=45,13.5 --zoom=0.27"
	"route_14_vue|30|--map=route_14 --noplayer --aim=15,40.5 --zoom=0.14"
	"route_15_vue|30|--map=route_15 --noplayer --aim=45,13.5 --zoom=0.27"
	"route_16_west_vue|30|--map=route_16_west --noplayer --aim=20,13.5 --zoom=0.42"
	"route_17_vue|30|--map=route_17 --noplayer --aim=15,75 --zoom=0.1"
	"route_18_vue|30|--map=route_18 --noplayer --aim=37.5,13.5 --zoom=0.32"
	"route_19_vue|30|--map=route_19 --noplayer --aim=15,40.5 --zoom=0.14"
	"route_20_vue|30|--map=route_20 --noplayer --aim=75,13.5 --zoom=0.16"
	"route_21_vue|30|--map=route_21 --noplayer --aim=15,67.5 --zoom=0.1"
	"route_12_south|40|--map=route_12_south --cell=19,22 --facing=up"
	"route_13|40|--map=route_13 --cell=62,13 --facing=left"
	"route_13_ouest|40|--map=route_13 --cell=12,13 --facing=left"
	"route_14|40|--map=route_14 --cell=6,40 --facing=up"
	"route_15|40|--map=route_15 --cell=36,12 --facing=right"
	"route_16_west|40|--map=route_16_west --cell=30,7 --facing=up"
	"route_17|40|--map=route_17 --cell=10,42 --facing=down"
	"route_18|40|--map=route_18 --cell=55,12 --facing=left"
	"route_19|40|--map=route_19 --cell=12,12 --facing=down"
	"route_20|40|--map=route_20 --cell=80,11 --facing=up"
	"route_21|40|--map=route_21 --cell=15,9 --facing=down"
	"poste_15|40|--map=route_15_gate --cell=6,6 --facing=up"
	"poste_15_2f|40|--map=route_15_gate_2f --cell=6,5 --facing=up"
	"poste_16|40|--map=route_16_gate --cell=6,6 --facing=up"
	"poste_18|40|--map=route_18_gate --cell=6,6 --facing=up"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_viridian_forest.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" | head -3 && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png 2>/dev/null | sort | tail -1)"
	[[ -n "$last" ]] && cp "$last" "$OUT/$name.png" && echo "$OUT/$name.png"
done
