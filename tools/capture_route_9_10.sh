#!/usr/bin/env bash
# Captures de la Route 9, de la Route 10 et du Centre de la Route 10 (jalon 18 T12 ; vie : plans
# « t18_* », `tools/capture_route_9_10.sh build/captures/j18_t18 t18_`),
# 2340 × 1080, Movie Maker (Mac, pas en headless), avec `tools/capture_pewter.gd` (carte,
# joueur peint et sa caméra, WorldLighting + profil de la carte) :
#   tools/capture_route_9_10.sh [dossier [filtre]]   (défaut : build/captures/j18_t12, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt (plans « perf_* », sans Movie Maker : vraies images
# par seconde). override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/j18_t12}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

R9="--map=route_9"
R10="--map=route_10"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r9_ensemble|20|$R9 --aim=40,18 --zoom=0.27 --noplayer"
	"r9_ouest|20|$R9 --aim=20,18 --zoom=0.55 --noplayer"
	"r9_centre|20|$R9 --aim=40,14 --zoom=0.55 --noplayer"
	"r9_est|20|$R9 --aim=62,17 --zoom=0.55 --noplayer"
	"r9_sortie_azuria|40|$R9 --cell=1,23 --facing=right"
	"r9_goulet|40|$R9 --cell=11,23 --facing=right"
	"r9_rampe|40|$R9 --cell=25,19 --facing=up"
	"r9_terrasse_haute|40|$R9 --cell=30,10 --facing=right"
	"r9_couloir_bas|40|$R9 --cell=34,14 --facing=right"
	"r9_descente|40|$R9 --cell=48,20 --facing=down"
	"r9_passage_rochers|40|$R9 --cell=52,27 --facing=right"
	"r9_montee|40|$R9 --cell=59,20 --facing=up"
	"r9_flanc_est|40|$R9 --cell=66,13 --facing=right"
	"r9_terrasse_est|40|$R9 --cell=70,18 --facing=right"
	"r10_ensemble_nord|20|$R10 --aim=17,14 --zoom=0.42 --noplayer"
	"r10_ensemble|20|$R10 --aim=17,38 --zoom=0.15 --noplayer"
	"r10_ensemble_sud|20|$R10 --aim=17,62 --zoom=0.42 --noplayer"
	"r10_arrivee_r9|40|$R10 --cell=1,13 --facing=right"
	"r10_centre|40|$R10 --cell=8,12 --facing=up"
	"r10_grotte_nord|40|$R10 --cell=17,9 --facing=up"
	"r10_belvedere|40|$R10 --cell=21,17 --facing=right"
	"r10_herbes_nord|40|$R10 --cell=8,20 --facing=down"
	"r10_riviere|40|$R10 --cell=23,25 --facing=right"
	"r10_sortie_sud|40|$R10 --cell=8,49 --facing=down"
	"r10_clairiere|40|$R10 --cell=12,51 --facing=down"
	"r10_terrasse_paul|40|$R10 --cell=12,60 --facing=right"
	"r10_herbes_sud|40|$R10 --cell=6,68 --facing=down"
	"r10_raccord_lavanville|40|$R10 --cell=22,73 --facing=down"
	"centre_route_10|40|--map=route_10_center --spawn=entrance --facing=up"
	"t18_lou|40|$R9 --cell=10,23 --facing=up"
	"t18_panneau_ouest|40|$R9 --cell=3,22 --facing=up"
	"t18_adam|40|$R9 --cell=36,11 --facing=up"
	"t18_benoit|40|$R9 --cell=54,26 --facing=down"
	"t18_piafabec|40|$R9 --cell=50,25 --facing=right"
	"t18_panneau_grotte|40|$R10 --cell=14,11 --facing=up"
	"t18_randonneur|40|$R10 --cell=17,10 --facing=right"
	"t18_centre_infirmiere|40|--map=route_10_center --spawn=heal --facing=up"
	"perf_r9_ouest|300|$R9 --cell=10,23 --facing=right --perf"
	"perf_r9_terrasse|300|$R9 --cell=34,14 --facing=right --perf"
	"perf_r9_est|300|$R9 --cell=66,13 --facing=right --perf"
	"perf_r10_nord|300|$R10 --cell=8,13 --facing=right --perf"
	"perf_r10_sud|300|$R10 --cell=12,52 --facing=down --perf"
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
