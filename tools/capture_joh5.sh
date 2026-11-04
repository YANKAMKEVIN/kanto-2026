#!/usr/bin/env bash
# Captures du jalon JOH5 (la Tour Radio ; `docs/tech/jalon-joh5.md` §2.7, dossier JOH-06 §12) :
# 1F avec le faux employé (et T-2), 3F et la réserve, 5F (Cenere au micro, T-15), écran du choix
# des 6, bureau. 2340 × 1080, Movie Maker (Mac, pas en headless), par `tools/capture_pewter.gd` en
# mode `--boot` (vraie scène `game/boot.tscn`).
#   tools/capture_joh5.sh [dossier [filtre]]   (défaut : build/captures/joh5, tout)
# Une image par plan (dernière image du film). override.cfg temporaire à la racine, retiré à la fin.
# Le plan « choix_des_6 » part de `johto_radio_tower_office` (clé `autosave`) : il réécrit la
# sauvegarde du Mac (`user://save.json` du projet), jamais celle d'un téléphone.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh5}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

T1="--boot --start=johto_radio_tower"
T3="--boot --start=johto_radio_tower_3f"
T5="--boot --start=johto_radio_tower_5f"
TO="--boot --start=johto_radio_tower_office"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"1f_hall|50|$T1 --cell=11,8 --facing=up"
	"1f_faux_employe|50|$T1 --cell=3,4 --facing=up"
	"1f_t2_carte|140|$T1 --cell=3,3 --hold=up --mash=2"
	"3f_archives|50|$T3 --cell=16,8 --facing=down"
	"3f_reserve|50|$T3 --cell=16,11 --facing=right"
	"3f_reserve_ouverte|50|$T3 --cell=16,11 --facing=right --flags=johto_radio_staff_freed"
	"5f_studio|50|$T5 --cell=12,4 --facing=down"
	"5f_cenere_micro|140|$T5 --cell=12,5 --hold=down"
	"5f_bureau|50|$TO --cell=9,2 --facing=left"
	"5f_choix_des_6|900|$TO --cell=9,2 --hold=left --mash=24"
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
