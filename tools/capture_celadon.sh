#!/usr/bin/env bash
# Captures de Céladopole, du grand magasin (RdC, 5e, toit, cabine), de la Résidence (toit), de
# l'Arène d'Erika et du Centre (jalon 20 T16 ; modèle `capture_routes_7_8.sh`),
# 2340 × 1080, Movie Maker (Mac, pas en headless), avec `tools/capture_pewter.gd` (carte,
# joueur peint et sa caméra, WorldLighting + profil de la carte) :
#   tools/capture_celadon.sh [dossier [filtre]]   (défaut : build/captures/jalon20_t16, tout)
# Le filtre est une expression régulière sur le nom du plan. Une image par plan (dernière image
# du film) ; journal [perf] dans perf.txt (plans « perf_* », sans Movie Maker : vraies images
# par seconde). override.cfg temporaire à la racine (taille de fenêtre), retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/jalon20_t16}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

CITY="--map=celadon_city"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"ville_ensemble|20|$CITY --aim=35,23 --zoom=0.22 --noplayer"
	"ville_arrivee|40|$CITY --spawn=from_route_7_c --facing=left"
	"ville_grand_magasin|40|$CITY --cell=12,17 --facing=up"
	"ville_etang|40|$CITY --cell=44,15 --facing=up"
	"ville_fontaine_casino|40|$CITY --cell=36,34 --facing=up"
	"ville_arene_enclos|40|$CITY --cell=20,37 --facing=left"
	"ville_ouest|40|$CITY --cell=6,22 --facing=left"
	"ville_service_residence|40|$CITY --cell=30,6 --facing=up"
	"magasin_rdc|40|--map=celadon_dept_gf --spawn=entrance --facing=up"
	"magasin_2e|40|--map=celadon_dept_2f --spawn=from_down --facing=down"
	"magasin_5e|40|--map=celadon_dept_5f --spawn=from_down --facing=down"
	"magasin_toit|40|--map=celadon_dept_roof --spawn=from_down --facing=down"
	"magasin_cabine|40|--map=celadon_dept_elevator --spawn=entrance --facing=up"
	"residence_hall|40|--map=celadon_mansion_gf --spawn=entrance --facing=up"
	"residence_toit|40|--map=celadon_mansion_roof --spawn=from_service --facing=down"
	"maison_toit|40|--map=celadon_mansion_roof_house --spawn=entrance --facing=up"
	"arene_entree|40|--map=celadon_gym --spawn=entrance --facing=up"
	"arene_vestibule|40|--map=celadon_gym --cell=8,7 --facing=up"
	"arene_serre|40|--map=celadon_gym --cell=8,3 --facing=up"
	"centre|40|--map=celadon_center --spawn=entrance --facing=up"
	"restaurant|40|--map=celadon_restaurant --spawn=entrance --facing=up"
	"perf_ville_est|300|$CITY --cell=60,22 --facing=left --perf"
	"perf_ville_centre|300|$CITY --cell=30,22 --facing=left --perf"
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
