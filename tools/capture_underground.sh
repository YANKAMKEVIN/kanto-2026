#!/usr/bin/env bash
# Captures du passage souterrain (jalon 15 T18) à 2340 × 1080 (Movie Maker, Mac, pas en headless),
# avec les vrais composants (carte, joueur peint, caméra bornée, profil `underground`, halos) via
# tools/capture_mt_moon.gd (générique : --map, --cell, --facing, --overview, --noplayer, --aim).
#
#   tools/capture_underground.sh            # toute la série
#   tools/capture_underground.sh coude      # une vue (expression régulière sur le nom)
#
# Sortie : build/captures/underground/<nom>.png
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/captures/underground
TMP=build/cap_underground
mkdir -p "$OUT"
cleanup() { rm -f override.cfg; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | arguments de tools/capture_mt_moon.gd
SHOTS=(
	"ensemble|--map=underground_path --overview --noplayer"
	"entree_nord|--map=underground_path --cell=3,2 --facing=down"
	"coude_1|--map=underground_path --cell=4,11 --facing=down"
	"galerie_s2|--map=underground_path --cell=12,13 --facing=right"
	"coude_2|--map=underground_path --cell=19,13 --facing=right"
	"alcove_2|--map=underground_path --cell=11,12 --facing=up"
	"alcove_3|--map=underground_path --cell=20,20 --facing=right"
	"entree_sud|--map=underground_path --cell=19,27 --facing=up"
	"heros_vide|--map=underground_path --noplayer --aim=4.5,12.5"
	"heros|--map=underground_path --cell=4,12 --facing=right --aim=4.5,12.5"
)

FILTER="${1:-.}"
for shot in "${SHOTS[@]}"; do
	name="${shot%%|*}"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "${TMP:?}/$name"
	mkdir -p "$TMP/$name"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/$name/f.png" --fixed-fps 60 --quit-after 40 \
		-s res://tools/capture_mt_moon.gd -- ${shot#*|} 2>&1 | grep -E "ERROR|capture_mt_moon" || true
	cp "$TMP/$name/f00000039.png" "$OUT/$name.png"
done
echo "captures : $OUT"
