#!/usr/bin/env bash
# Captures des lots DAF.3 « Safrania et Sylphe » et DAF.4 « Fin du jeu » (phase DA) : Safrania,
# Sylphe SARL, Arène de Morgane, Dojo, Arène de Jadielle, à 2340 × 1080, Movie Maker (Mac, pas en headless), avec les vrais
# composants (carte, joueur, WorldLighting + profil de la carte : tools/capture_viridian_forest.gd).
#
#   tools/capture_daf3.sh [dossier [filtre]]   (défaut : build/captures/daf3, tout)
#
# Plans « perf_* » : sans Movie Maker (vraies images par seconde au Mac), journal dans perf.txt.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/daf3}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_viridian_forest.gd
SHOTS=(
	"safrania_centre|40|--map=saffron_city --cell=17,41 --facing=up"
	"safrania_sylphe|40|--map=saffron_city --cell=29,31 --facing=up"
	"safrania_nord|40|--map=saffron_city --cell=44,11 --facing=up"
	"safrania_ouest|40|--map=saffron_city --cell=8,25 --facing=left"
	"safrania_est|40|--map=saffron_city --cell=52,26 --facing=right"
	"safrania_sud|40|--map=saffron_city --cell=30,44 --facing=down"
	"sylphe_1f|40|--map=silph_co_1f --cell=10,15 --facing=up"
	"sylphe_3f|40|--map=silph_co_3f --cell=14,9 --facing=up"
	"sylphe_7f|40|--map=silph_co_7f --cell=11,10 --facing=up"
	"sylphe_11f|40|--map=silph_co_11f --cell=10,10 --facing=up"
	"sylphe_cabine|40|--map=silph_co_elevator --facing=up"
	"arene_morgane|40|--map=saffron_gym --facing=up"
	"dojo|40|--map=fighting_dojo --facing=up"
	"arene_jadielle|40|--map=viridian_gym --facing=up"
	"perf_sylphe_7f|300|--map=silph_co_7f --cell=11,10 --facing=up --perf"
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
