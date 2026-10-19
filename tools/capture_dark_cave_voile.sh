#!/usr/bin/env bash
# Captures de la Grotte Sombre SOUS LE VOILE (jalon 18 T15, répétition sur le J17) à 2340 × 1080 :
# voile sombre (sans Flash) et Flash ouvert, à quatre repères des deux étages, avec leurs vues
# jumelles sans héros (« _vide », même caméra, même trou) pour le contraste du héros :
#
#   tools/capture_dark_cave_voile.sh             # toute la série
#   tools/capture_dark_cave_voile.sh dark_galerie
#   python3 tools/art/luminance_grotte.py --halo build/captures/dark_cave_voile
#
# Seuils (J17 T25) : héros ≥ 3,0 dans le halo, sol hors du halo ≥ 0,10.
# Sortie : build/captures/dark_cave_voile/<nom>.png + <nom>.json (fiche de la caméra).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/captures/dark_cave_voile
TMP=build/cap_dark_cave_voile
mkdir -p "$OUT"
cleanup() { rm -f override.cfg; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# lieu | arguments de tools/capture_mt_moon.gd (mêmes cases que tools/capture_dark_cave.sh)
PLACES=(
	"couloir_1f|--map=dark_cave_1f --cell=27,10 --facing=down"
	"galerie_1f|--map=dark_cave_1f --cell=30,15 --facing=right"
	"flaque_b1f|--map=dark_cave_b1f --cell=22,28 --facing=down"
	"passage_b1f|--map=dark_cave_b1f --cell=37,34 --facing=right"
)
SHOTS=()
for place in "${PLACES[@]}"; do
	lieu="${place%%|*}"
	args="${place#*|}"
	for etat in dark lit; do
		SHOTS+=("${etat}_${lieu}|$args --voile=$etat")
		SHOTS+=("${etat}_${lieu}_vide|$args --voile=$etat --invisible")
	done
done

FILTER="${1:-.}"
for shot in "${SHOTS[@]}"; do
	name="${shot%%|*}"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/$name"
	mkdir -p "$TMP/$name"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/$name/f.png" --fixed-fps 60 --quit-after 60 \
		-s res://tools/capture_mt_moon.gd -- ${shot#*|} --meta="$OUT/$name.json" 2>&1 \
		| grep -E "ERROR|capture_mt_moon" || true
	cp "$TMP/$name/f00000059.png" "$OUT/$name.png"
done
echo "captures : $OUT"
