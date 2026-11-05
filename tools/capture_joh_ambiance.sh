#!/usr/bin/env bash
# Captures de la passe d'ambiance du Chapitre Johto (`tools/build_joh_ambiance.gd`) : planche
# pilote « Oliville peinte, de jour et de nuit » (avenue et Centre, phare, plage et bouche de la
# grotte marine, port et pontons, bout est ; vue d'ensemble), puis Route 39, Route 38 et Rosalia
# (plans `r39_`, `r38_`, `ros_` : tools/capture_joh_ambiance.sh build/captures/joh_ambiance_joh2
# '^(r39|r38|ros)_'). 2340 × 1080, Movie Maker (Mac, pas
# en headless), par `tools/capture_pewter.gd` en mode `--boot` (vraie scène `game/boot.tscn` :
# lumière `johto_auto` résolue par le moment du départ de débogage, halos de nuit, HUD).
#   tools/capture_joh_ambiance.sh [dossier [filtre]]   (défaut : build/captures/joh_pilote, tout)
# Une image par plan (dernière image du film). Taille par `--resolution` (pas d'override.cfg à la
# racine : plusieurs outils de capture peuvent tourner dans la même copie).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh_pilote}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

DAY="--boot --start=johto_olivine_day"
NIGHT="--boot --start=johto_olivine_night"
R39="--boot --start=johto_route_39_day"
R39N="--boot --start=johto_route_39_night"
R38="--boot --start=johto_route_38_day"
R38N="--boot --start=johto_route_38_night"
ROS="--boot --start=johto_rosalia_day"
ROSN="--boot --start=johto_rosalia_night"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"oli_jour_avenue_centre|50|$DAY --cell=27,21 --facing=up"
	"oli_jour_phare|50|$DAY --cell=11,13 --facing=left"
	"oli_jour_plage_grotte|50|$DAY --cell=12,32 --facing=left"
	"oli_jour_port|50|$DAY --cell=33,32 --facing=down"
	"oli_jour_pontons|50|$DAY --cell=29,36 --facing=down"
	"oli_jour_est|50|$DAY --cell=44,21 --facing=right"
	"oli_nuit_avenue_centre|50|$NIGHT --cell=27,21 --facing=up"
	"oli_nuit_phare|50|$NIGHT --cell=11,13 --facing=left"
	"oli_nuit_plage_grotte|50|$NIGHT --cell=12,32 --facing=left"
	"oli_nuit_port|50|$NIGHT --cell=33,32 --facing=down"
	"oli_vue_ensemble|30|--map=olivine_city --noplayer --aim=25,20 --zoom=0.28"
	"r39_jour_chemin|50|$R39 --cell=11,12 --facing=right"
	"r39_jour_ferme|50|$R39 --cell=14,31 --facing=up"
	"r39_jour_mare|50|$R39 --cell=10,33 --facing=left"
	"r39_jour_enclos|50|$R39 --cell=21,38 --facing=left"
	"r39_nuit_ferme|50|$R39N --cell=14,31 --facing=up"
	"r39_nuit_mare|50|$R39N --cell=10,33 --facing=left"
	"r39_vue_ensemble|30|--map=route_39 --noplayer --aim=12,25 --zoom=0.22"
	"r38_jour_ouest|50|$R38 --cell=13,4 --facing=right"
	"r38_jour_muret|50|$R38 --cell=30,5 --facing=up"
	"r38_jour_impasse|50|$R38 --cell=33,12 --facing=down"
	"r38_jour_est|50|$R38 --cell=52,14 --facing=right"
	"r38_nuit_muret|50|$R38N --cell=30,5 --facing=up"
	"r38_nuit_est|50|$R38N --cell=52,14 --facing=right"
	"r38_vue_ensemble|30|--map=route_38 --noplayer --aim=30,10 --zoom=0.4"
	"ros_jour_cendree|50|$ROS --cell=9,14 --facing=up"
	"ros_jour_sages|50|$ROS --cell=21,14 --facing=up"
	"ros_jour_carillon|50|$ROS --cell=43,9 --facing=right"
	"ros_jour_centre|50|$ROS --cell=14,31 --facing=up"
	"ros_jour_maisons|50|$ROS --cell=41,31 --facing=up"
	"ros_jour_jardins|50|$ROS --cell=27,38 --facing=down"
	"ros_nuit_cendree|50|$ROSN --cell=9,14 --facing=up"
	"ros_nuit_carillon|50|$ROSN --cell=43,9 --facing=right"
	"ros_nuit_centre|50|$ROSN --cell=14,31 --facing=up"
	"ros_nuit_maisons|50|$ROSN --cell=41,31 --facing=up"
	"ros_vue_ensemble|30|--map=ecruteak_city --noplayer --aim=28,24 --zoom=0.234"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --resolution 2340x1080 --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" | grep -v "_on_focus_change" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
