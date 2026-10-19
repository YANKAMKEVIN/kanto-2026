#!/usr/bin/env bash
# Captures de Lavanville, de ses intérieurs et du rez-de-chaussée de la Tour (jalon 18 T14),
# 2340 × 1080, Movie Maker (Mac, pas en headless) :
#   tools/capture_lavender.sh [dossier [filtre]]   (défaut : build/captures/jalon18_t14, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt. Réutilise `tools/capture_pewter.gd` (générique :
# carte, case, orientation, caméra libre) ; override.cfg temporaire à la racine (taille de
# fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon18_t14}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

LV="--map=lavender_town"
TW="--map=pokemon_tower_1f"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"lv_arrivee|40|$LV --cell=22,2 --facing=down"
	"lv_avenue|40|$LV --cell=22,12 --facing=down"
	"lv_parvis|40|$LV --cell=33,12 --facing=up"
	"lv_rue2|40|$LV --cell=22,23 --facing=right"
	"lv_centre|40|$LV --cell=9,23 --facing=up"
	"lv_sud|40|$LV --cell=22,32 --facing=down"
	"lv_ouest|40|$LV --cell=2,11 --facing=left"
	"lv_ensemble|20|$LV --aim=22,18 --zoom=0.46 --noplayer"
	"tw_entree|40|$TW --cell=9,15 --facing=up"
	"tw_allee|40|$TW --cell=9,9 --facing=up"
	"tw_escalier|40|$TW --cell=16,4 --facing=right"
	"tw_comptoir|40|$TW --cell=4,14 --facing=up"
	"tw_ensemble|20|$TW --aim=10,9 --zoom=0.55 --noplayer"
	"in_centre|40|--map=lavender_center"
	"in_boutique|40|--map=lavender_mart"
	"in_maison_pokemon|40|--map=pokemon_house"
	"in_maison_1|40|--map=lavender_house_1"
	"in_maison_2|40|--map=lavender_house_2"
	"perf_arrivee|300|$LV --cell=22,3 --facing=down --perf"
	"perf_parvis|300|$LV --cell=33,12 --facing=up --perf"
	"perf_tour|300|$TW --cell=9,9 --facing=up --perf"
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
