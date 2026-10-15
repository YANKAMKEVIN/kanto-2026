#!/usr/bin/env bash
# Captures de la Route 5, de la Pension, du poste nord et de l'entrée du souterrain (jalon 15 T13,
# T21), 2340 × 1080, Movie Maker (Mac, pas en headless), avec `tools/capture_pewter.gd` (carte,
# joueur peint et sa caméra, PNJ peints, WorldLighting + profil de la carte) :
#   tools/capture_route_5.sh [dossier [filtre]]   (défaut : build/captures/j15_t13, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt (plans « perf_* », sans Movie Maker : vraies images
# par seconde). override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/j15_t13}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

R5="--map=route_5"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r5_ensemble|20|$R5 --aim=21,31 --zoom=0.17 --noplayer"
	"r5_tranche_1_arrivee|20|$R5 --aim=21,11 --zoom=0.45 --noplayer"
	"r5_tranche_2_pension|20|$R5 --aim=24,29 --zoom=0.45 --noplayer"
	"r5_tranche_3_carrefour|20|$R5 --aim=22,49 --zoom=0.45 --noplayer"
	"r5_arrivee|40|$R5 --cell=20,2 --facing=down"
	"r5_herbes_h1|40|$R5 --cell=23,10 --facing=right"
	"r5_super_potion|40|$R5 --cell=12,15 --facing=left"
	"r5_pension|40|$R5 --cell=27,28 --facing=up"
	"r5_derriere_pension|40|$R5 --cell=27,21 --facing=down"
	"r5_jardin|40|$R5 --cell=30,31 --facing=right"
	"r5_detour_tronc|40|$R5 --cell=16,32 --facing=up"
	"r5_carrefour|40|$R5 --cell=26,47 --facing=down"
	"r5_poste|40|$R5 --cell=34,45 --facing=up"
	"r5_souterrain|40|$R5 --cell=11,57 --facing=up"
	"int_pension|40|--map=route_5_daycare --cell=7,5 --facing=up"
	"int_poste|40|--map=route_5_gate --cell=4,4 --facing=up"
	"int_entree_souterrain|40|--map=route_5_underground_gate --cell=5,4 --facing=up"
	"t21_route_5_vers_azuria|150|--boot --start=route_5 --cell=20,1 --facing=up --hold=up"
	"t21_azuria_vers_route_5|150|--boot --start=cerulean_after --flags=cerulean_south_guard_left --cell=32,39 --facing=down --hold=down"
	"t21_azuria_sud|40|--boot --start=cerulean_after --flags=cerulean_south_guard_left --cell=32,38 --facing=down"
	"boot_poste_garde|330|--boot --start=route_5 --cell=34,45 --facing=up --hold=up"
	"perf_r5_pension|300|$R5 --cell=22,30 --facing=right --perf"
	"perf_r5_carrefour|300|$R5 --cell=26,48 --facing=down --perf"
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
