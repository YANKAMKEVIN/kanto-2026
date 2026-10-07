#!/bin/bash
# Captures du CB.2 en 2340 x 1080 (et 1920 x 1080 avec --1920) : interface de combat, Sac,
# ÉQUIPE (passe 1), carte de capture (passe 2). Sortie : build/captures/combat_cb2/.
set -e
cd "$(dirname "$0")/.."
OUT=build/captures/combat_cb2
SIZE=2340x1080
SUFFIX=""
if [ "$1" = "--1920" ]; then SIZE=1920x1080; SUFFIX="_1920"; fi
godot --path . --resolution "$SIZE" --fixed-fps 30 --quit-after 3000 \
	-s res://tools/capture_combat_cb2.gd -- --out="$OUT" --suffix="$SUFFIX" 2>&1 | grep -E "ERROR|CAPTURE|CAPTURE_" || true
godot --path . --resolution "$SIZE" --fixed-fps 30 --quit-after 3000 \
	-s res://tools/capture_combat_cb2.gd -- --out="$OUT" --suffix="$SUFFIX" --only-capture 2>&1 \
	| grep -E "ERROR|CAPTURE|CAPTURE_" || true
