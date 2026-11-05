#!/usr/bin/env bash
# Captures de la passe d'ambiance des grottes du Chapitre Johto (`tools/build_joh_ambiance_caves.gd`) :
# salles 1 et 2 de la grotte marine, bouche de Bourg Palette ouverte et fermée. 2340 × 1080, Movie
# Maker (Mac, pas en headless), par `tools/capture_pewter.gd` en mode `--boot` (vraie scène
# `game/boot.tscn`), sauf les vues d'ensemble `*_vue` (caméra libre, comparaison avec les vues
# générales). Les départs des salles sont ceux de `johto_sea_cave`, copiés le temps des captures
# (carte et arrivée changées ; arrivée en Surf forcé : le héros garde le Surf sur `--cell`).
#   tools/capture_joh_ambiance_caves.sh [dossier [filtre]]
#   (défaut : build/captures/joh_ambiance_caves, tout)
# Une image par plan (dernière image du film). override.cfg temporaire à la racine, reposé avant
# chaque plan et retiré à la fin : une autre session peut capturer dans le même dossier ; un plan
# sorti en 1170 × 540 (fichier retiré entre-temps) est refait.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh_ambiance_caves}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
STARTS=(tools/debug_start/_cap_cave1.json tools/debug_start/_cap_cave2.json
	tools/debug_start/_cap_cave2_pied.json tools/debug_start/_cap_palette_fermee.json)
cleanup() { rm -f "${STARTS[@]}" override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
SRC=tools/debug_start/johto_sea_cave.json
sed -e 's/"map": "pallet_town"/"map": "sea_cave_1"/' \
	-e 's/"spawn": "from_sea_cave"/"spawn": "from_pallet_town"/' "$SRC" > "${STARTS[0]}"
sed -e 's/"map": "pallet_town"/"map": "sea_cave_2"/' \
	-e 's/"spawn": "from_sea_cave"/"spawn": "from_sea_cave_1"/' "$SRC" > "${STARTS[1]}"
sed -e 's/"map": "pallet_town"/"map": "sea_cave_2"/' \
	-e 's/"spawn": "from_sea_cave"/"spawn": "from_olivine_city"/' "$SRC" > "${STARTS[2]}"
python3 - "$SRC" "${STARTS[3]}" <<'PY'
import json, sys
start = json.load(open(sys.argv[1]))
start["flags"].remove("johto_letter_read")
json.dump(start, open(sys.argv[2], "w"), ensure_ascii=False, indent=1)
PY

S1="--boot --start=_cap_cave1"
S2="--boot --start=_cap_cave2"
S2P="--boot --start=_cap_cave2_pied"
PAL="--boot --start=johto_sea_cave"
PALF="--boot --start=_cap_palette_fermee"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"s1_vue|30|--map=sea_cave_1 --noplayer --aim=15,20 --zoom=0.27"
	"s1_entree|50|$S1 --cell=13,6 --facing=down"
	"s1_bassin_nord|50|$S1 --cell=11,12 --facing=right"
	"s1_courant|50|$S1 --cell=20,15 --facing=left"
	"s1_chenal_est|50|$S1 --cell=21,24 --facing=right"
	"s1_bassin_sud|50|$S1 --cell=15,33 --facing=up"
	"s2_vue|30|--map=sea_cave_2 --noplayer --aim=15,20 --zoom=0.27"
	"s2_entree|50|$S2 --cell=20,8 --facing=down"
	"s2_bassin|50|$S2 --cell=14,18 --facing=down"
	"s2_ombre|50|$S2 --flags=johto_lugia_passing --cell=13,12 --facing=down"
	"s2_ilot|50|$S2 --cell=21,25 --facing=right"
	"s2_chenal|50|$S2 --cell=7,29 --facing=down"
	"s2_plage|50|$S2P --cell=6,37 --facing=down"
	"pal_ouverte|50|$PAL --cell=23,32 --facing=down"
	"pal_ouverte_bord|50|$PAL --cell=23,33 --facing=down"
	"pal_ouverte_large|50|$PAL --cell=28,32 --facing=left"
	"pal_fermee|50|$PALF --cell=23,32 --facing=down"
	"pal_fermee_large|50|$PALF --cell=28,32 --facing=left"
)
shoot() {
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
		> override.cfg
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$1" \
		-s res://tools/capture_pewter.gd -- $2 > "$TMP/log.txt" 2>&1 || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
}
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	shoot "$frames" "$opts"
	[[ "$(sips -g pixelWidth "$last" | tail -1 | awk '{print $2}')" == 2340 ]] || shoot "$frames" "$opts"
	grep -E "SCRIPT ERROR|^ERROR" "$TMP/log.txt" | grep -v -E "_on_focus_change|resources still in use" \
		&& echo "  ($name : erreurs ci-dessus)" || true
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
