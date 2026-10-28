#!/usr/bin/env bash
# Captures du lot DAF.4 « Fin du jeu », suite (phase DA) : Route Victoire, Grotte Azurée,
# Route 23, Plateau Indigo, Route 22 ouest, à 2340 × 1080, Movie Maker (Mac, pas en headless), avec les vrais
# composants (carte, joueur, WorldLighting + profil de la carte : tools/capture_viridian_forest.gd).
#
#   tools/capture_daf4.sh [dossier [filtre]]   (défaut : build/captures/daf4, tout)
#
# Plans « perf_* » : sans Movie Maker (vraies images par seconde au Mac), journal dans perf.txt.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/daf4}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_viridian_forest.gd
SHOTS=(
	"victoire_1f|40|--map=victory_road_1f --cell=8,15 --facing=up"
	"victoire_1f_nord|40|--map=victory_road_1f --cell=10,6 --facing=up"
	"victoire_2f|40|--map=victory_road_2f --cell=15,9 --facing=up"
	"victoire_3f|40|--map=victory_road_3f --cell=12,8 --facing=up"
	"azuree_1f|40|--map=cerulean_cave_1f --cell=24,14 --facing=up"
	"azuree_2f|40|--map=cerulean_cave_2f --cell=15,9 --facing=up"
	"azuree_b1f|40|--map=cerulean_cave_b1f --cell=15,9 --facing=up"
	"route_23_sud|40|--map=route_23 --cell=8,138 --facing=up"
	"route_23_milieu|40|--map=route_23 --cell=10,69 --facing=up"
	"route_23_nord|40|--map=route_23 --cell=10,20 --facing=up"
	"plateau_indigo|40|--map=indigo_plateau --cell=10,8 --facing=up"
	"route_22_ouest|40|--map=route_22_west --cell=10,8 --facing=up"
)
: > "$OUT/perf.txt"
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	if [[ "$name" == perf_* ]]; then
		# shellcheck disable=SC2086
		godot --path . --quit-after "$frames" -s res://tools/capture_viridian_forest.gd -- $opts \
			> "$TMP/log.txt" 2>&1 || true
	else
		# shellcheck disable=SC2086
		godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
			-s res://tools/capture_viridian_forest.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	fi
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" && echo "  ($name : erreurs ci-dessus)" || true
	if grep -q "\[perf\]" "$TMP/log.txt"; then
		{ echo "== $name"; grep "\[perf\]" "$TMP/log.txt"; } >> "$OUT/perf.txt"
	fi
	if [[ "$name" == perf_* ]]; then
		echo "$OUT/perf.txt ($name)"
		continue
	fi
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
