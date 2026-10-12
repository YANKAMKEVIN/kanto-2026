#!/usr/bin/env bash
# Captures de la Route 4 et de la Route 24 (jalon 13 T8),
# 2340 × 1080, Movie Maker (Mac, pas en headless), avec `tools/capture_pewter.gd` (carte,
# joueur peint et sa caméra, WorldLighting + profil de la carte) :
#   tools/capture_route_4_24.sh [dossier [filtre]]   (défaut : build/captures/j13_t8, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt (plans « perf_* », sans Movie Maker : vraies images
# par seconde). override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/j13_t8}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

R4="--map=route_4"
R24="--map=route_24"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r4_ensemble|20|$R4 --aim=32,12 --zoom=0.37 --noplayer"
	"r4_ensemble_ouest|20|$R4 --aim=18,12 --zoom=0.6 --noplayer"
	"r4_ensemble_est|20|$R4 --aim=46,17 --zoom=0.6 --noplayer"
	"r4_sortie_grotte|40|$R4 --cell=4,6 --facing=left"
	"r4_plateau|40|$R4 --cell=16,7 --facing=right"
	"r4_rebord|40|$R4 --cell=31,11 --facing=down"
	"r4_rebord_bas|40|$R4 --cell=31,14 --facing=down"
	"r4_plaine_ouest|40|$R4 --cell=18,18 --facing=right"
	"r4_herbes|40|$R4 --cell=40,19 --facing=right"
	"r4_h2_rue|40|$R4 --cell=45,20 --facing=right"
	"r4_raccord_azuria|40|$R4 --cell=61,20 --facing=right"
	"r24_ensemble|20|$R24 --aim=28,31 --zoom=0.18 --noplayer"
	"r24_couloir|40|$R24 --cell=32,59 --facing=up"
	"r24_goulet_rival|40|$R24 --cell=32,56 --facing=up"
	"r24_pied_pont|40|$R24 --cell=32,46 --facing=up"
	"r24_pied_pont_place|40|$R24 --cell=36,49 --facing=up"
	"r24_entree_pont|40|$R24 --cell=32,43 --facing=up"
	"r24_milieu_pont|40|$R24 --cell=32,32 --facing=up"
	"r24_bout_pont|40|$R24 --cell=33,22 --facing=up"
	"r24_prairie_nord|40|$R24 --cell=33,14 --facing=up"
	"r24_prairie_est|40|$R24 --cell=45,7 --facing=right"
	"r24_prairie_ouest|40|$R24 --cell=22,9 --facing=left"
	"perf_r4_plateau|300|$R4 --cell=10,7 --facing=right --perf"
	"perf_r4_plaine|300|$R4 --cell=46,20 --facing=right --perf"
	"perf_r24_pied|300|$R24 --cell=34,48 --facing=up --perf"
	"perf_r24_pont|300|$R24 --cell=32,32 --facing=up --perf"
	"perf_r24_nord|300|$R24 --cell=33,12 --facing=up --perf"
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
