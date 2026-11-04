#!/usr/bin/env bash
# Captures de la passe d'ambiance du Chapitre Johto (`tools/build_joh_ambiance.gd`) : planche
# pilote « Oliville peinte, de jour et de nuit » (avenue et Centre, phare, plage et bouche de la
# grotte marine, port et pontons, bout est ; vue d'ensemble). 2340 × 1080, Movie Maker (Mac, pas
# en headless), par `tools/capture_pewter.gd` en mode `--boot` (vraie scène `game/boot.tscn` :
# lumière `johto_auto` résolue par le moment du départ de débogage, halos de nuit, HUD).
#   tools/capture_joh_ambiance.sh [dossier [filtre]]   (défaut : build/captures/joh_pilote, tout)
# Une image par plan (dernière image du film). override.cfg temporaire à la racine, retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh_pilote}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

DAY="--boot --start=johto_olivine_day"
NIGHT="--boot --start=johto_olivine_night"
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
