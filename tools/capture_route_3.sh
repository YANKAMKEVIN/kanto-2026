#!/usr/bin/env bash
# Captures de la Route 3, du Centre du Mont Sélénite et du sas de la Route 4 (jalon 12 T8 ; vie
# de la route, plans « t18_* » : T18 — `tools/capture_route_3.sh build/captures/jalon12_t18 t18_`),
# 2340 × 1080, Movie Maker (Mac, pas en headless), avec `tools/capture_pewter.gd` (carte,
# joueur peint et sa caméra, WorldLighting + profil de la carte) :
#   tools/capture_route_3.sh [dossier [filtre]]   (défaut : build/captures/jalon12_t8, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt (plans « perf_* », sans Movie Maker : vraies images
# par seconde). override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon12_t8}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

R3="--map=route_3"
R4="--map=route_4"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r3_ensemble|20|$R3 --aim=41,19 --zoom=0.297 --noplayer"
	"r3_ouest_ensemble|20|$R3 --aim=20,19 --zoom=0.6 --noplayer"
	"r3_est_ensemble|20|$R3 --aim=62,15 --zoom=0.6 --noplayer"
	"r3_sortie_argenta|40|$R3 --cell=1,26 --facing=right"
	"r3_goulet_hugo|40|$R3 --cell=20,26 --facing=up"
	"r3_embranchement|40|$R3 --cell=26,23 --facing=up"
	"r3_rebord_l2|40|$R3 --cell=31,19 --facing=down"
	"r3_itineraire_nord|40|$R3 --cell=34,9 --facing=right"
	"r3_itineraire_sud|40|$R3 --cell=36,28 --facing=right"
	"r3_jonction|40|$R3 --cell=46,19 --facing=right"
	"r3_pied_montagne|40|$R3 --cell=58,20 --facing=right"
	"r3_rebord_l1|40|$R3 --cell=62,17 --facing=down"
	"r3_centre|40|$R3 --cell=62,13 --facing=up"
	"r3_entree_grotte|40|$R3 --cell=73,11 --facing=up"
	"r3_poche_nolan|40|$R3 --cell=76,21 --facing=down"
	"centre_mont_selenite|40|--map=mt_moon_center --spawn=entrance --facing=up"
	"sas_bouche|40|$R4 --cell=4,6 --facing=left"
	"sas_raccord_est|40|$R4 --cell=21,7 --facing=right"
	"sas_ensemble|20|$R4 --aim=12,7 --zoom=0.78 --noplayer"
	"ar_sortie_est|40|--map=pewter_city --cell=49,26 --facing=right"
	"boot_avant_sortie|60|--boot --start=pewter --flags=badge_boulder,route_3_guard_cleared --cell=50,26 --facing=right"
	"boot_argenta_route_3|200|--boot --start=pewter --flags=badge_boulder,route_3_guard_cleared --cell=50,26 --facing=right --hold=right"
	"t18_hugo|40|$R3 --cell=20,27 --facing=up"
	"t18_voyageur|40|$R3 --cell=13,17 --facing=right"
	"t18_panneau_ouest|40|$R3 --cell=3,25 --facing=up"
	"t18_sacha_piafabec|40|$R3 --cell=33,10 --facing=up"
	"t18_enzo_ines|40|$R3 --cell=36,30 --facing=down"
	"t18_cache_reveil|40|$R3 --cell=36,19 --facing=up"
	"t18_lea|40|$R3 --cell=51,21 --facing=up"
	"t18_plateau_centre|40|$R3 --cell=64,13 --facing=up"
	"t18_nolan|40|$R3 --cell=75,20 --facing=up"
	"t18_centre_infirmiere|40|--map=mt_moon_center --spawn=heal --facing=up"
	"t18_boot_cache_toast|90|--boot --start=route_3 --cell=36,19 --facing=up --interact"
	"t18_boot_panneau|90|--boot --start=route_3 --cell=3,25 --facing=up --interact"
	"t18_boot_hugo_vu|150|--boot --start=route_3 --cell=17,26 --facing=right --hold=right"
	"perf_r3_ouest|300|$R3 --cell=10,26 --facing=right --perf"
	"perf_r3_jonction|300|$R3 --cell=46,19 --facing=right --perf"
	"perf_r3_est|300|$R3 --cell=66,13 --facing=right --perf"
	"perf_sas|300|$R4 --cell=10,7 --facing=right --perf"
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
