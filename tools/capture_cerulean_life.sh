#!/usr/bin/env bash
# Captures de la vie de la Route 4 et d'Azuria (jalon 13 T17), 2340 × 1080, Movie Maker (Mac, pas
# en headless), avec la vraie scène Boot (HUD, titre de zone, PNJ, dialogues) :
#   tools/capture_cerulean_life.sh [dossier [filtre]]   (défaut : build/captures/j13_t17, tout)
# Une image par plan (dernière image du film). Extérieurs : `tools/capture_pewter.gd --boot` ;
# intérieurs : `tools/capture_cerulean_interiors.gd` ; Boutique : `tools/capture_cerulean_shop.gd`.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/j13_t17}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg

AZ="--boot --start=cerulean_city"
R4="--boot --start=route_4"
# nom | images | script | options
SHOTS=(
	"r4_poke_ball|60|pewter|$R4 --cell=21,19 --facing=down"
	"r4_poke_ball_prise|90|pewter|$R4 --cell=21,19 --facing=down --interact"
	"r4_rue_clara_reservee|60|pewter|$R4 --cell=44,20 --facing=up"
	"r24_panneau_pont|60|pewter|--map=route_24 --cell=34,47 --facing=up"
	"az_arrivee_titre|90|pewter|--boot --start=route_4 --cell=62,20 --facing=right --hold=right"
	"az_cambriolage|60|pewter|$AZ --cell=13,12 --facing=up"
	"az_cambriolage_ruban|90|pewter|$AZ --cell=10,10 --facing=up --interact"
	"az_voisine_dialogue|90|pewter|$AZ --cell=22,10 --facing=left --interact"
	"az_cloture_arrachee|60|pewter|$AZ --cell=5,2 --facing=right"
	"az_pecheur_quai|60|pewter|$AZ --cell=24,13 --facing=down"
	"az_pont_enfant|60|pewter|$AZ --cell=31,19 --facing=up"
	"az_nageuse_arene|60|pewter|$AZ --cell=38,12 --facing=up"
	"az_place_dresseur|60|pewter|$AZ --cell=35,23 --facing=up"
	"az_sortie_est_habitant|60|pewter|$AZ --cell=49,23 --facing=right"
	"az_panneau_ville|90|pewter|$AZ --cell=3,19 --facing=up --interact"
	"in_centre|120|interior|--room=centre"
	"in_boutique|120|interior|--room=boutique"
	"in_velos|120|interior|--room=velos --cell=12,5 --facing=up"
	"in_maison|120|interior|--room=maison"
	"in_arene|120|interior|--room=arene"
	"in_arene_lucas|220|interior|--room=arene --cell=2,9 --walk=up:1"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames kind opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	script="capture_pewter.gd"
	[[ "$kind" == interior ]] && script="capture_cerulean_interiors.gd"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s "res://tools/$script" -- $opts --out="$TMP/o" > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
