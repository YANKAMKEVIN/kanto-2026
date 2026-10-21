#!/usr/bin/env bash
# Captures de la Grotte Sombre (jalon 18 T13) à 2340 × 1080 : vue d'ensemble de chaque étage et
# vues 1:1 aux repères, avec la fiche de la caméra de chacune (mesure de luminance :
# python3 tools/art/luminance_grotte.py build/captures/dark_cave). Lumière de référence, SANS le
# voile d'obscurité (posé par le moteur, J17/J18 T7).
#
#   tools/capture_dark_cave.sh            # toute la série
#   tools/capture_dark_cave.sh entree     # une seule vue (nom de la série, expression régulière)
#
# Sortie : build/captures/dark_cave/<nom>.png + <nom>.json.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/captures/dark_cave
TMP=build/cap_dark_cave
mkdir -p "$OUT"
cleanup() { rm -f override.cfg; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

# nom | arguments de tools/capture_dark_cave.gd
SHOTS=(
	"ensemble_1f|--map=dark_cave_1f --overview --noplayer"
	"ensemble_b1f|--map=dark_cave_b1f --overview --noplayer"
	"entree_1f|--map=dark_cave_1f --cell=27,3 --facing=down"
	"premier_couloir_1f|--map=dark_cave_1f --cell=27,10 --facing=down"
	"galerie_1f|--map=dark_cave_1f --cell=30,15 --facing=right"
	"echelle_a_1f|--map=dark_cave_1f --cell=44,4 --facing=up"
	"sud_arrivee_1f|--map=dark_cave_1f --cell=43,34 --facing=left"
	"sortie_sud_1f|--map=dark_cave_1f --cell=9,44 --facing=down"
	"alcove_b1f|--map=dark_cave_b1f --cell=32,4 --facing=up"
	"colonne_b1f|--map=dark_cave_b1f --cell=18,19 --facing=up"
	"flaque_b1f|--map=dark_cave_b1f --cell=22,28 --facing=down"
	"passage_b1f|--map=dark_cave_b1f --cell=37,34 --facing=right"
	"racines_b1f|--map=dark_cave_b1f --cell=42,34 --facing=up"
	"heros_1f|--map=dark_cave_1f --cell=27,10 --facing=down --aim=27.5,9.5"
	"heros_1f_vide|--map=dark_cave_1f --noplayer --aim=27.5,9.5"
	"perf_1f|--map=dark_cave_1f --cell=30,15 --facing=right"
	"perf_b1f|--map=dark_cave_b1f --cell=22,28 --facing=down"
)

run_shot() {
	local name="$1" args="$2"
	if [[ "$name" == perf_* ]]; then
		echo "== $name" >> "$OUT/perf.txt"
		# shellcheck disable=SC2086
		godot --path . --quit-after 400 -s res://tools/capture_dark_cave.gd -- $args --perf 2>&1 \
			| grep -E "ERROR|\[perf\]" >> "$OUT/perf.txt" || true
		return
	fi
	rm -rf "$TMP/$name"
	mkdir -p "$TMP/$name"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/$name/f.png" --fixed-fps 60 --quit-after 40 \
		-s res://tools/capture_dark_cave.gd -- $args --meta="$OUT/$name.json" 2>&1 \
		| grep -E "ERROR|capture_dark_cave" || true
	cp "$TMP/$name/f00000039.png" "$OUT/$name.png"
}

FILTER="${1:-.}"
for shot in "${SHOTS[@]}"; do
	name="${shot%%|*}"
	[[ "$name" =~ $FILTER ]] || continue
	run_shot "$name" "${shot#*|}"
done
echo "captures : $OUT"
