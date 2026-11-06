#!/usr/bin/env bash
# Captures du jalon JOH6 (« les cendres » ; `docs/tech/jalon-joh6.md` T13, dossier joh-07 §14) :
# Tour Cendrée 1F et B1F (les chiens, la scène), Route 42 (lac, Louis), Acajou (antenne), Route 43
# (péage), Lac Colère (Léviator rouge), repaire B1F (statue), B2F (dalles, souvenir sépia), B3F
# (générateur, Raikou). 2340 × 1080, Movie Maker (Mac, pas en headless), par
# `tools/capture_pewter.gd` en mode `--boot` (vraie scène `game/boot.tscn`).
#   tools/capture_joh6.sh [dossier [filtre]]   (défaut : build/captures/joh6, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh6}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

S="--boot --start=johto_joh6"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"ros_doyen|50|${S}_rosalia --cell=21,13 --facing=up"
	"ros_panneau_tour|50|${S}_rosalia --cell=7,14 --facing=up"
	"t1f_entree|50|${S}_tower_1f --cell=13,20 --facing=up"
	"t1f_bande|50|${S}_tower_1f --cell=13,14 --facing=up"
	"tb1f_chiens|50|${S}_tower_b1f --cell=10,4 --facing=down"
	"tb1f_scene_brace|520|${S}_tower_b1f --hold=down --mash=6"
	"r42_ouest|50|${S}_route_42 --cell=3,10 --facing=right"
	"r42_lac|50|${S}_route_42 --cell=28,10 --facing=right"
	"r42_louis|50|${S}_route_42 --cell=50,10 --facing=right"
	"acajou_entree|50|${S}_mahogany --cell=2,15 --facing=right"
	"acajou_boutique|50|${S}_mahogany --cell=25,16 --facing=up"
	"acajou_samedi|50|${S}_saturday --cell=4,15 --facing=up"
	"r43_peage|50|${S}_route_43 --cell=11,28 --facing=up"
	"lac_rive_sud|50|${S}_lake --cell=27,39 --facing=up"
	"lac_vue|50|--map=lake_of_rage --aim=27,24 --zoom=0.55 --noplayer"
	"r42_ilot|50|--map=route_42 --aim=37,8 --zoom=0.8 --noplayer"
	"rep_b1f_statue|50|${S}_hideout --cell=5,3 --facing=right"
	"rep_b2f_dalles|50|--map=mahogany_hideout_b2f --aim=12,9 --zoom=0.6 --noplayer"
	"rep_b2f_cellules|50|${S}_hideout_b2f --cell=13,15 --facing=down"
	"rep_b2f_souvenir|600|${S}_hideout_b2f --flags=johto_cell_opened --cell=7,17 --facing=down --mash=16"
	"rep_b3f_generateur|50|${S}_hideout_b3f --cell=13,9 --facing=right"
	"ros_dimanche|50|${S}_sunday --cell=23,14 --facing=up"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" | grep -v "_on_focus_change" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
