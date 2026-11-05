#!/usr/bin/env bash
# Captures de la remise en scène du vol (JOH1) : héros puis joueuse, 2340 × 1080 (Mac, fenêtre).
#   tools/capture_joh1_theft.sh [dossier]   (défaut : build/captures/joh1_vol)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh1_vol}"
cleanup() { rm -f override.cfg; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg
for LOOK in hero heroine; do
	godot --path . -s res://tools/capture_joh1_theft.gd -- --out="$OUT" --look="$LOOK" 2>&1 \
		| grep -E "^build/|SCRIPT ERROR|ERROR:" | grep -v "_on_focus_change" || true
done
