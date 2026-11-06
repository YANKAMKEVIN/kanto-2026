#!/bin/zsh
# Bande-annonce v2 (J34) : rend chaque scène du storyboard en Movie Maker (2340 × 1080, 30 i/s,
# son) dans build/trailer/raw/<scène>.avi, journal dans build/trailer/logs/<scène>.log.
# Movie Maker enregistre à la taille « window_width_override » du projet (1170 × 540, le S24
# à l'échelle ½) : un override.cfg temporaire (ignoré par git) la porte à 2340 × 1080 pendant le
# rendu, puis est retiré. Usage : tools/trailer/render.sh [scène…]  (défaut : toutes)
# TRAILER_RAW=raw_v3 : dossier de sortie (v3 : les rendus de la v2.1 restent intacts).
set -u
cd "$(dirname "$0")/../.."
scenes=("$@")
if [[ ${#scenes[@]} -eq 0 ]]; then
  scenes=(depart rival evolution velo surf selenite tour mewtwo ligue championne)
fi
raw="build/trailer/${TRAILER_RAW:-raw}"
mkdir -p "$raw" build/trailer/logs
cleanup() { rm -f override.cfg; }
trap cleanup EXIT INT TERM
printf '[display]\n\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' > override.cfg
for scene in "${scenes[@]}"; do
  echo "== $scene"
  godot --path . --resolution 2340x1080 --fixed-fps 30 \
    --write-movie "$raw/$scene.avi" \
    -s res://tools/trailer/capture_trailer_scene.gd -- "--scene=$scene" \
    > "build/trailer/logs/$scene.log" 2>&1
  echo "   exit $? ; $(grep -c '\[trailer\]' "build/trailer/logs/$scene.log") repères ; $(grep 'frames at' "build/trailer/logs/$scene.log")"
  grep "SCRIPT ERROR\|garde-fou\|aucun chemin\|bloqué" "build/trailer/logs/$scene.log" | head -5
done
