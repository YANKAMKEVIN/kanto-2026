#!/usr/bin/env bash
# Captures de la Route 2 nord et d'Argenta (jalon 10 T11), 2340 × 1080, Movie Maker (Mac, pas en
# headless) :
#   tools/capture_pewter.sh [dossier [filtre]]   (défaut : build/captures/jalon10_t11, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt. override.cfg temporaire à la racine (taille de
# fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon10_t11}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

R2N="--map=route_2_north"
AR="--map=pewter_city"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r2n_poste_sortie|40|$R2N --cell=15,20 --facing=up"
	"r2n_porte_poste|40|$R2N --cell=15,20 --facing=down"
	"r2n_croisement|40|$R2N --cell=15,16 --facing=right"
	"r2n_eboulis|40|$R2N --cell=23,16 --facing=right"
	"r2n_detour|40|$R2N --cell=9,10 --facing=left"
	"r2n_potion|40|$R2N --cell=5,1 --facing=left"
	"r2n_rocher_montagnard|40|$R2N --cell=16,8 --facing=up"
	"r2n_raccord_nord|40|$R2N --cell=15,1 --facing=up"
	"r2n_ensemble|20|$R2N --aim=15,12 --zoom=0.42 --noplayer"
	"ar_arrivee|40|$AR --cell=18,43 --facing=up"
	"ar_arrivee_pas|40|$AR --cell=18,41 --facing=up"
	"ar_musee|40|$AR --cell=9,40 --facing=up"
	"ar_avenue|40|$AR --cell=18,30 --facing=up"
	"ar_place|40|$AR --cell=24,21 --facing=up"
	"ar_arene|40|$AR --cell=36,13 --facing=up"
	"ar_point_de_vue|40|$AR --cell=10,4 --facing=up"
	"ar_chantier|40|$AR --cell=8,24 --facing=left"
	"ar_sortie_est|40|$AR --cell=47,26 --facing=right"
	"ar_centre_boutique|40|$AR --cell=27,36 --facing=up"
	"ar_maison_est|40|$AR --cell=46,22 --facing=up"
	"ar_ensemble|20|$AR --aim=26,22 --zoom=0.24 --noplayer"
	"boot_arrivee|90|--boot --start=pewter"
	"boot_garde|150|--boot --start=pewter --cell=47,26 --facing=right --steps=right:1"
	"boot_route_2_north|90|--boot --start=route_2_north"
	"perf_arrivee|300|$AR --cell=18,42 --facing=up --perf"
	"perf_place|300|$AR --cell=26,22 --facing=up --perf"
	"perf_r2n|300|$R2N --cell=15,14 --facing=up --perf"
)
# Plans « perf_* » : sans Movie Maker (vraies images par seconde), pas d'image gardée.
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
