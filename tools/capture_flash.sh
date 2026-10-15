#!/usr/bin/env bash
# Captures de la carte de QA `qa_flash` (jalon 17 T25) à 2340 × 1080 : sans voile, voile sombre,
# Flash ouvert, au milieu et au bord de la carte, avec leurs vues jumelles sans héros (« _vide »,
# même caméra, même trou) pour le contraste du héros :
#
#   tools/capture_flash.sh              # toute la série
#   tools/capture_flash.sh dark_bord    # une seule vue (expression régulière)
#   python3 tools/art/luminance_grotte.py --halo build/captures/flash
#
# Sortie : build/captures/flash/<nom>.png + <nom>.json (fiche de la caméra).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/captures/flash
TMP=build/cap_flash
mkdir -p "$OUT"
cleanup() { rm -f override.cfg; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | arguments de tools/capture_mt_moon.gd (milieu = (15, 7), bord = coin sud-ouest (3, 13))
SHOTS=(
	"sans_voile_milieu|--map=qa_flash --cell=15,7 --facing=down"
	"sans_voile_milieu_vide|--map=qa_flash --cell=15,7 --facing=down --invisible"
	"dark_milieu|--map=qa_flash --cell=15,7 --facing=down --voile=dark"
	"dark_milieu_vide|--map=qa_flash --cell=15,7 --facing=down --voile=dark --invisible"
	"lit_milieu|--map=qa_flash --cell=15,7 --facing=down --voile=lit"
	"lit_milieu_vide|--map=qa_flash --cell=15,7 --facing=down --voile=lit --invisible"
	"dark_bord|--map=qa_flash --cell=3,13 --facing=down --voile=dark"
	"dark_bord_vide|--map=qa_flash --cell=3,13 --facing=down --voile=dark --invisible"
	"lit_bord|--map=qa_flash --cell=3,13 --facing=down --voile=lit"
	"lit_bord_vide|--map=qa_flash --cell=3,13 --facing=down --voile=lit --invisible"
	"dark_bord_est|--map=qa_flash --cell=28,5 --facing=down --voile=dark"
	"dark_bord_est_vide|--map=qa_flash --cell=28,5 --facing=down --voile=dark --invisible"
	"lit_bord_est|--map=qa_flash --cell=28,5 --facing=down --voile=lit"
	"lit_bord_est_vide|--map=qa_flash --cell=28,5 --facing=down --voile=lit --invisible"
)

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
