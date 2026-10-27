#!/usr/bin/env bash
# Captures du lot DAF.6 « Lumière et ambiance » (phase DA) : Forêt de Jade, intérieurs, Mont
# Sélénite et son abord, à 2340 × 1080, Movie Maker (Mac, pas en headless), avec les vrais
# composants (carte, joueur, WorldLighting + profil de la carte : tools/capture_viridian_forest.gd).
#
#   tools/capture_daf6.sh [dossier [filtre]]   (défaut : build/captures/daf6, tout)
#
# Plans « perf_* » : sans Movie Maker (vraies images par seconde au Mac), journal dans perf.txt.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/daf6}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | images | options de capture_viridian_forest.gd
SHOTS=(
	"foret_entree|40|--cell=44,88 --facing=up"
	"foret_theo|40|--cell=34,70 --facing=left"
	"foret_h3|40|--cell=17,48 --facing=right"
	"foret_clairiere_rai|40|--cell=36,30 --facing=up"
	"foret_parvis_nord|40|--cell=28,8 --facing=up"
	"int_chambre|40|--map=player_house_2f --facing=down"
	"int_maison_1f|40|--map=player_house_1f --facing=up"
	"int_maison_rival|40|--map=rival_house --facing=up"
	"int_labo_chen|40|--map=oak_lab --facing=up"
	"int_centre_jadielle|40|--map=viridian_center --facing=up"
	"int_boutique_jadielle|40|--map=viridian_mart --facing=up"
	"int_musee_argenta|40|--map=pewter_museum --facing=up"
	"int_poste_foret_sud|40|--map=viridian_forest_gate_south --cell=4,6 --facing=up"
	"selenite_abord|40|--map=route_3 --cell=73,12 --facing=up"
	"selenite_hall_1f|40|--map=mt_moon_1f --cell=29,41 --facing=up"
	"selenite_carrefour_1f|40|--map=mt_moon_1f --cell=27,25 --facing=right"
	"selenite_tranchee_b1f|40|--map=mt_moon_b1f --cell=10,18 --facing=left"
	"selenite_chambre_b2f|40|--map=mt_moon_b2f --cell=25,33 --facing=up"
	"perf_foret_entree|300|--cell=44,86 --facing=up --perf"
	"perf_foret_h3|300|--cell=23,48 --facing=right --perf"
	"perf_foret_c3|300|--cell=37,32 --facing=up --perf"
	"perf_labo|300|--map=oak_lab --facing=up --perf"
	"perf_centre|300|--map=viridian_center --facing=up --perf"
	"perf_selenite_1f|300|--map=mt_moon_1f --cell=29,41 --facing=up --perf"
	"perf_selenite_b2f|300|--map=mt_moon_b2f --cell=25,33 --facing=up --perf"
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
