#!/usr/bin/env bash
# Captures du jalon JOH8 (Bois de la Tour, Tour Carillon ; `docs/tech/jalon-joh8.md` T8, dossier
# joh-09 §13) : Bois, 1F, 2F (planches), sommet à l'aube (Dante, la cage d'Entei), la scène du
# sommet, la cage brûlée et Entei libre. 2340 × 1080, Movie Maker (Mac, pas en headless), par
# `tools/capture_pewter.gd` en mode `--boot` (vraie scène `game/boot.tscn`).
#   tools/capture_joh8.sh [dossier [filtre]]   (défaut : build/captures/joh8, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh8}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

WOODS="--boot --start=johto_bell_tower_woods"
F1="--boot --start=johto_bell_tower_1f"
F2="--boot --start=johto_bell_tower_2f"
ROOF="--boot --start=johto_bell_tower_roof"
ENTEI="--boot --start=johto_bell_tower_entei"
WOODSN="--boot --start=johto_bell_tower_woods_night"
ROOFN="--boot --start=johto_bell_tower_roof_night"
SHOTS=(
	"bois_entree|50|$WOODS --cell=10,17 --facing=up"
	"bois_tour|50|$WOODS --cell=11,8 --facing=up"
	"bois_sbire|50|$WOODS --cell=13,10 --facing=right"
	"bois_porte|50|$WOODS --cell=11,6 --facing=up"
	"bois_nuit|50|$WOODSN --cell=11,7 --facing=up"
	"1f_autel|50|$F1 --cell=11,4 --facing=up"
	"1f_entree|50|$F1 --cell=11,20 --facing=down"
	"2f_escalier|50|$F2 --cell=3,3 --facing=up"
	"sommet_cloche|50|$ENTEI --cell=9,6 --facing=up"
	"sommet_sud|50|$ENTEI --cell=9,15 --facing=down"
	"sommet_nuit|50|$ROOFN --cell=9,6 --facing=down"
	"1f_hall|50|$F1 --cell=11,15 --facing=up"
	"1f_sbire_v|50|$F1 --cell=17,4 --facing=right"
	"2f_planches|50|$F2 --cell=12,3 --facing=down"
	"2f_hiroshi|50|$F2 --cell=4,8 --facing=left"
	"2f_sud|50|$F2 --cell=12,15 --facing=down"
	"sommet_aube|50|$ROOF --cell=3,2 --facing=down"
	"sommet_dante_cage|50|$ROOF --cell=9,10 --facing=up --flags=johto_dante_met"
	"sommet_arrivee_scene|160|$ROOF --hold=down"
	"sommet_dante_dialogue|300|$ROOF --hold=down --mash=10"
	"sommet_entei_libre|50|$ENTEI --cell=12,10 --facing=up"
	"sommet_ho_oh_descente|330|$ROOF --cell=9,6 --facing=up --flags=johto_dante_met,johto_dante_defeated_1 --mash=12"
	"sommet_cage_brulee|520|$ROOF --cell=9,6 --facing=up --flags=johto_dante_met,johto_dante_defeated_1 --mash=20"
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
