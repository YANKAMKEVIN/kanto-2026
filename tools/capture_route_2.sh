#!/usr/bin/env bash
# Captures de la Route 2 (jalon 8 T5), 2340 × 1080, Movie Maker (Mac, pas en headless) :
#   tools/capture_route_2.sh [dossier [filtre]]   (défaut : build/captures/jalon08_t5, tout)
# Le filtre est une expression régulière sur le nom du plan (ex. « ^t7_ » : la vie de la route).
# Une image par plan (dernière image du film) + vue d'ensemble ; journal [perf] dans perf.txt.
# override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon08_t5}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_route_2.gd
SHOTS=(
	"c1_depart|40|--cell=20,58 --facing=up"
	"c1_h1|40|--cell=17,53 --facing=left"
	"h2_rebord|40|--cell=17,36 --facing=left"
	"h2_herbes|40|--cell=17,31 --facing=up"
	"c2_pierre|40|--cell=27,27 --facing=up"
	"c2_nidoran|40|--cell=30,24 --facing=right"
	"montee_futur_a|40|--cell=6,19 --facing=left"
	"c3_poste|40|--cell=7,13 --facing=up"
	"h3_parvis|40|--cell=19,12 --facing=up"
	"porte|40|--cell=20,10 --facing=up"
	"futur_b|40|--cell=31,44 --facing=right"
	"ensemble|20|--aim=21,30 --zoom=0.17 --noplayer"
	"t7_ball_sol|40|--cell=11,53 --facing=left"
	"t7_ball_prise|75|--boot --cell=11,53 --facing=left --interact"
	"t7_ball_2|40|--cell=11,35 --facing=left"
	"t7_randonneuse|60|--cell=23,50 --facing=up"
	"t7_p2|40|--cell=27,26 --facing=right"
	"t7_p2_dialogue|90|--boot --cell=27,26 --facing=right --interact"
	"t7_p1_dialogue|90|--boot --cell=23,49 --facing=up --interact"
	"t7_rattata|40|--cell=12,43 --facing=right"
	"t7_objet_cache|90|--boot --cell=13,43 --facing=up --steps=up:1"
	"t7_futur_a_texte|90|--boot --cell=5,19 --facing=left --interact"
	"t7_futur_b_texte|90|--boot --cell=33,43 --facing=up --interact"
	"perf_c1|300|--cell=20,57 --facing=up --perf"
	"perf_c3|300|--cell=8,12 --facing=up --perf"
)
# Plans « perf_* » : sans Movie Maker (vraies images par seconde), pas d'image gardée.
: > "$OUT/perf.txt"
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	if [[ "$name" == perf_* ]]; then
		# shellcheck disable=SC2086
		godot --path . --quit-after "$frames" -s res://tools/capture_route_2.gd -- $opts \
			> "$TMP/log.txt" 2>&1 || true
	else
		# shellcheck disable=SC2086
		godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
			-s res://tools/capture_route_2.gd -- $opts > "$TMP/log.txt" 2>&1 || true
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
