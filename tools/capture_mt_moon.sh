#!/usr/bin/env bash
# Captures du Mont Sélénite (jalon 12 T9) à 2340 × 1080 : vue d'ensemble de chaque étage et vues
# 1:1 aux repères, avec la fiche de la caméra de chacune (mesure de luminance :
# tools/art/luminance_grotte.py build/captures/mt_moon), vues jumelles sans joueur (« _vide »,
# contraste du héros, Forêt de Jade comprise pour comparer) et mesures de fps (« perf_* », sans
# Movie Maker, journal dans perf.txt).
#
#   tools/capture_mt_moon.sh            # toute la série
#   tools/capture_mt_moon.sh hall_1f    # une seule vue (nom de la série, expression régulière)
#
# Sortie : build/captures/mt_moon/<nom>.png + <nom>.json.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/captures/mt_moon
TMP=build/cap_mt_moon
mkdir -p "$OUT"
# override.cfg temporaire à la racine (fenêtre 2340 × 1080, sinon réduite par l'écran du Mac),
# retiré à la fin.
cleanup() { rm -f override.cfg; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | arguments de tools/capture_mt_moon.gd
SHOTS=(
	"ensemble_1f|--map=mt_moon_1f --overview --noplayer"
	"ensemble_b1f|--map=mt_moon_b1f --overview --noplayer"
	"ensemble_b2f|--map=mt_moon_b2f --overview --noplayer"
	"hall_1f|--map=mt_moon_1f --cell=29,41 --facing=up"
	"carrefour_1f|--map=mt_moon_1f --cell=27,25 --facing=right"
	"camp_1f|--map=mt_moon_1f --cell=7,16 --facing=left"
	"eclats_1f|--map=mt_moon_1f --cell=53,34 --facing=up"
	"nord_1f|--map=mt_moon_1f --cell=40,5 --facing=right"
	"guetteur_b1f|--map=mt_moon_b1f --cell=12,5 --facing=right"
	"tranchee_b1f|--map=mt_moon_b1f --cell=10,18 --facing=left"
	"poche_b1f|--map=mt_moon_b1f --cell=33,24 --facing=up"
	"echelle_c_b1f|--map=mt_moon_b1f --cell=35,25 --facing=down"
	"colonnes_b2f|--map=mt_moon_b2f --cell=26,10 --facing=down"
	"couloir_b2f|--map=mt_moon_b2f --cell=26,22 --facing=down"
	"chambre_b2f|--map=mt_moon_b2f --cell=25,33 --facing=up"
	"heros_1f|--map=mt_moon_1f --cell=29,41 --facing=down --aim=29.5,40.5"
	"heros_1f_vide|--map=mt_moon_1f --noplayer --aim=29.5,40.5"
	"heros_b1f|--map=mt_moon_b1f --cell=12,5 --facing=down --aim=12.5,4.5"
	"heros_b1f_vide|--map=mt_moon_b1f --noplayer --aim=12.5,4.5"
	"heros_b2f|--map=mt_moon_b2f --cell=26,22 --facing=down --aim=26.5,21.5"
	"heros_b2f_vide|--map=mt_moon_b2f --noplayer --aim=26.5,21.5"
	"heros_foret|--map=viridian_forest --cell=44,86 --facing=down --aim=44.5,85.5"
	"heros_foret_vide|--map=viridian_forest --noplayer --aim=44.5,85.5"
	"perf_1f_hall|--map=mt_moon_1f --cell=29,41 --facing=up"
	"perf_1f_carrefour|--map=mt_moon_1f --cell=27,25 --facing=right"
	"perf_b1f|--map=mt_moon_b1f --cell=12,5 --facing=right"
	"perf_b2f_chambre|--map=mt_moon_b2f --cell=25,33 --facing=up"
)

run_shot() {
	local name="$1" args="$2"
	if [[ "$name" == perf_* ]]; then
		echo "== $name" >> "$OUT/perf.txt"
		# shellcheck disable=SC2086
		godot --path . --quit-after 400 -s res://tools/capture_mt_moon.gd -- $args --perf 2>&1 \
			| grep -E "ERROR|\[perf\]" >> "$OUT/perf.txt" || true
		return
	fi
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
