#!/usr/bin/env bash
# Captures du jalon JOH2 (Routes 39 et 38, Rosalia ; `docs/tech/jalon-joh2.md` T11, dossier joh-03
# §11) : Route 39 de jour et de nuit, Route 38, Rosalia de jour et de nuit, la scène des Sbires,
# Margot un mardi. 2340 × 1080, Movie Maker (Mac, pas en headless), par `tools/capture_pewter.gd`
# en mode `--boot` (vraie scène `game/boot.tscn` : lumière `johto_auto` résolue par le moment du
# départ de débogage, lampes de nuit, HUD, titre de zone, scènes).
#   tools/capture_joh2.sh [dossier [filtre]]   (défaut : build/captures/joh2, tout)
# Une image par plan (dernière image du film). override.cfg temporaire à la racine, retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh2}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

R39="--boot --start=johto_route_39"
R39N="--boot --start=johto_route_39_night"
R38="--boot --start=johto_route_38"
ROS="--boot --start=johto_rosalia"
ROSN="--boot --start=johto_rosalia_night"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r39_jour_entree|50|$R39 --cell=2,21 --facing=right"
	"r39_jour_chemin_nord|50|$R39 --cell=9,10 --facing=up"
	"r39_jour_ferme|50|$R39 --cell=16,31 --facing=up"
	"r39_jour_enclos|50|$R39 --cell=11,37 --facing=right"
	"r39_nuit_entree|50|$R39N --cell=2,21 --facing=right"
	"r39_nuit_ferme|50|$R39N --cell=16,31 --facing=up"
	"r38_jour_entree|50|$R38 --cell=2,4 --facing=right"
	"r38_jour_ines|50|$R38 --cell=40,15 --facing=right"
	"r38_jour_impasse|50|$R38 --cell=33,16 --facing=down"
	"ros_jour_entree|50|$ROS --cell=0,15 --facing=right"
	"ros_sbires_dialogue|140|$ROS --hold=right"
	"ros_sbires_fuite|420|$ROS --hold=right --mash=5"
	"ros_jour_tour_cendree|50|$ROS --cell=8,14 --facing=up"
	"ros_jour_centre|50|$ROS --cell=9,31 --facing=up"
	"ros_jour_carillon|50|$ROS --cell=42,14 --facing=up"
	"ros_jour_sud|50|$ROS --cell=27,42 --facing=down"
	"ros_nuit_entree|50|$ROSN --cell=0,15 --facing=right"
	"ros_nuit_tour_cendree|50|$ROSN --cell=8,14 --facing=up"
	"ros_nuit_centre|50|$ROSN --cell=9,31 --facing=up"
	"ros_mardi_margot|50|--boot --start=johto_rosalia_tuesday --cell=13,30 --facing=up"
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
