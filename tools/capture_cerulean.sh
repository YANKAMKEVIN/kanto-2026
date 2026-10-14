#!/usr/bin/env bash
# Captures d'Azuria et de ses intérieurs (jalon 13 T7), 2340 × 1080, Movie Maker (Mac, pas en
# headless) :
#   tools/capture_cerulean.sh [dossier [filtre]]   (défaut : build/captures/jalon13_t7, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt. Réutilise `tools/capture_pewter.gd` (générique :
# carte, case, orientation, caméra libre) ; override.cfg temporaire à la racine (taille de
# fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon13_t7}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

AZ="--map=cerulean_city"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"az_arrivee|40|$AZ --cell=1,20 --facing=right"
	"az_avenue|40|$AZ --cell=12,20 --facing=right"
	"az_place|40|$AZ --cell=30,22 --facing=up"
	"az_canal|40|$AZ --cell=32,17 --facing=up"
	"az_pont_ouest|40|$AZ --cell=23,9 --facing=right"
	"az_arene|40|$AZ --cell=41,11 --facing=up"
	"az_quartier_nord_ouest|40|$AZ --cell=15,11 --facing=left"
	"az_sortie_nord|40|$AZ --cell=32,2 --facing=up"
	"az_boutique_velos|40|$AZ --cell=32,36 --facing=up"
	"az_sortie_est|40|$AZ --cell=48,23 --facing=right"
	"az_baie|40|$AZ --cell=47,13 --facing=right"
	"az_ensemble|20|$AZ --aim=28,20 --zoom=0.4 --noplayer"
	"perf_arrivee|300|$AZ --cell=2,20 --facing=right --perf"
	"perf_canal|300|$AZ --cell=32,20 --facing=up --perf"
	"perf_arene|300|$AZ --cell=41,12 --facing=up --perf"
)
: > "$OUT/perf.txt"
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	if [[ "$name" == perf_* ]]; then
		# shellcheck disable=SC2086
		godot --path . --quit-after "$frames" -s res://tools/capture_pewter.gd -- $opts \
			> "$TMP/log.txt" 2>&1 || true
	else
		# shellcheck disable=SC2086
		godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
			-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
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
