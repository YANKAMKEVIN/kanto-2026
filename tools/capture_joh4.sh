#!/usr/bin/env bash
# Captures du jalon JOH4 (Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss ;
# `docs/tech/jalon-joh4.md` T11, dossier joh-05 §12) : Bois de matin et de nuit, autel, Écorcia
# avant / après, Fargas, Puits B1F et B2F, Brace, Vincent le vendredi. 2340 × 1080, Movie Maker
# (Mac, pas en headless), par `tools/capture_pewter.gd` en mode `--boot` (vraie scène).
#   tools/capture_joh4.sh [dossier [filtre]]   (défaut : build/captures/joh4, tout)
# Une image par plan (dernière image du film). override.cfg temporaire à la racine, retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh4}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

R34="--boot --start=johto_route_34"
ILM="--boot --start=johto_ilex_morning"
ILN="--boot --start=johto_ilex_night"
AZ="--boot --start=johto_azalea"
AZA="--boot --start=johto_azalea_after"
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r34_entree|50|$R34"
	"r34_etang|50|$R34 --cell=10,17 --facing=left"
	"r34_maison|50|$R34 --cell=17,11 --facing=up"
	"r34_felix|50|$R34 --cell=10,37 --facing=down"
	"bois_matin_entree|50|$ILM"
	"bois_matin_autel|50|$ILM --cell=23,12 --facing=up"
	"bois_matin_autel_examen|90|$ILM --cell=23,12 --facing=up --interact"
	"bois_nuit_autel|50|$ILN --cell=23,13 --facing=up"
	"bois_nuit_sentier|50|$ILN --cell=30,18 --facing=right"
	"bois_matin_charbonnier|50|$ILM --cell=35,43 --facing=left"
	"az_avant_entree|50|$AZ"
	"az_avant_rue|50|$AZ --cell=21,12 --facing=down"
	"az_avant_puits|50|$AZ --cell=37,10 --facing=up"
	"az_avant_barriere|120|$AZ --cell=37,9 --facing=up --hold=up"
	"az_fargas_recit|80|--boot --start=johto_kurt_house --cell=7,6 --facing=up --interact"
	"az_fargas_puits|900|--boot --start=johto_kurt_house --cell=7,6 --facing=up --interact --mash=16"
	"az_apres_rue|50|$AZA --cell=21,12 --facing=down"
	"az_apres_puits|50|$AZA --cell=36,8 --facing=up"
	"az_vendredi_vincent|50|--boot --start=johto_azalea_friday --cell=8,12 --facing=up"
	"puits_b1f_fargas|160|--boot --start=johto_slowpoke_well --hold=right"
	"puits_b1f_eau|50|--boot --start=johto_slowpoke_well --cell=8,13 --facing=down"
	"puits_b2f_brace|160|--boot --start=johto_brace --hold=up"
	"puits_b2f_combat|700|--boot --start=johto_brace --hold=up --mash=10"
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
