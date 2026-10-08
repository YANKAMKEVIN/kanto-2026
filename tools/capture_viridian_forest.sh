#!/usr/bin/env bash
# Captures de la Forêt de Jade et de ses postes (jalon 9 T19 ; cases de la forêt agrandie, §7), 2340 × 1080, Movie Maker (Mac,
# pas en headless) :
#   tools/capture_viridian_forest.sh [dossier [filtre]]   (défaut : build/captures/jalon09_t19)
# Le filtre est une expression régulière sur le nom du plan (ex. « ^int_ » : les postes).
# Une image par plan (dernière image du film) + vue d'ensemble ; journal [perf] dans perf.txt.
# override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon09_t19}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_viridian_forest.gd
SHOTS=(
	"entree|40|--cell=44,88 --facing=up"
	"c1_objet|40|--cell=35,83 --facing=left"
	"tronc_incline|40|--cell=45,80 --facing=up"
	"theo|40|--cell=34,70 --facing=left"
	"h2_cul_de_sac|40|--cell=5,76 --facing=up"
	"souche|40|--cell=29,59 --facing=up"
	"h3|40|--cell=17,48 --facing=right"
	"milo|40|--cell=35,49 --facing=left"
	"racines|40|--cell=7,49 --facing=left"
	"randonneuse|40|--cell=43,44 --facing=up"
	"clairiere_rai|40|--cell=36,30 --facing=up"
	"h5|40|--cell=27,22 --facing=right"
	"montee_o5|40|--cell=53,15 --facing=up"
	"h4|40|--cell=17,14 --facing=left"
	"poste_nord|40|--cell=28,8 --facing=up"
	"int_poste_sud|40|--map=viridian_forest_gate_south --cell=4,6 --facing=up"
	"int_poste_nord|40|--map=viridian_forest_gate_north --cell=4,3 --facing=down"
	"ensemble|20|--aim=35,45 --zoom=0.12 --noplayer"
	"perf_entree|300|--cell=44,86 --facing=up --perf"
	"perf_c2|300|--cell=29,59 --facing=up --perf"
	"perf_h3|300|--cell=23,48 --facing=right --perf"
	"perf_c3|300|--cell=37,32 --facing=up --perf"
	"perf_h5|300|--cell=32,21 --facing=right --perf"
	"perf_parvis|300|--cell=28,8 --facing=up --perf"
)
# Plans « perf_* » : sans Movie Maker (vraies images par seconde), pas d'image gardée.
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
