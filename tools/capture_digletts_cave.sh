#!/usr/bin/env bash
# Captures de la Cave Taupiqueur (jalon 17 T15, sur tools/capture_mt_moon.gd) à 2340 × 1080 : vue d'ensemble et vues
# 1:1 aux repères, avec la fiche de la caméra de chacune (mesure de luminance :
# tools/art/luminance_grotte.py build/captures/digletts_cave), vues jumelles sans joueur (« _vide »,
# contraste du héros, Forêt de Jade comprise pour comparer) .
#
#   tools/capture_digletts_cave.sh            # toute la série
#   tools/capture_digletts_cave.sh couloir_a    # une seule vue (nom de la série, expression régulière)
#
# Sortie : build/captures/digletts_cave/<nom>.png + <nom>.json.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/captures/digletts_cave
TMP=build/cap_digletts_cave
mkdir -p "$OUT"
# override.cfg temporaire à la racine (fenêtre 2340 × 1080, sinon réduite par l'écran du Mac),
# retiré à la fin.
cleanup() { rm -f override.cfg; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | arguments de tools/capture_mt_moon.gd
SHOTS=(
	"ensemble|--map=digletts_cave --overview --noplayer"
	"bouche_sud|--map=digletts_cave --cell=15,77 --facing=up"
	"couloir_a|--map=digletts_cave --cell=15,66 --facing=up"
	"g2|--map=digletts_cave --cell=8,53 --facing=up"
	"renfoncement_r1|--map=digletts_cave --cell=6,44 --facing=left"
	"bras_est|--map=digletts_cave --cell=18,38 --facing=right"
	"couloir_c|--map=digletts_cave --cell=22,32 --facing=up"
	"couloir_d|--map=digletts_cave --cell=16,15 --facing=up"
	"bouche_nord|--map=digletts_cave --cell=16,3 --facing=up"
	"heros_a|--map=digletts_cave --cell=15,66 --facing=down --aim=15.5,65.5"
	"heros_a_vide|--map=digletts_cave --noplayer --aim=15.5,65.5"
	"heros_foret|--map=viridian_forest --cell=44,86 --facing=down --aim=44.5,85.5"
	"heros_foret_vide|--map=viridian_forest --noplayer --aim=44.5,85.5"
)

run_shot() {
	local name="$1" args="$2"
	rm -rf "$TMP/$name"
	mkdir -p "$TMP/$name"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/$name/f.png" --fixed-fps 60 --quit-after 40 \
		-s res://tools/capture_mt_moon.gd -- $args --meta="$OUT/$name.json" 2>&1 \
		| grep -E "ERROR|capture_mt_moon" || true
	cp "$TMP/$name/f00000039.png" "$OUT/$name.png"
}

FILTER="${1:-.}"
for shot in "${SHOTS[@]}"; do
	name="${shot%%|*}"
	[[ "$name" =~ $FILTER ]] || continue
	run_shot "$name" "${shot#*|}"
done
echo "captures : $OUT"
