#!/usr/bin/env bash
# Captures du lot DAF.9 « Cramois'Île » (phase DA, RP-024) : Manoir 1F à B1F, Arène, île, à
# 2340 × 1080, Movie Maker (Mac, pas en headless), avec les vrais composants (carte, joueur,
# WorldLighting + profil de la carte : tools/capture_viridian_forest.gd), décors à drapeaux réglés
# (`--gates` : nouvelle partie, ou interrupteur du Manoir sur MARCHE, herses ouvertes).
#
#   tools/capture_daf9.sh [dossier [filtre]]   (défaut : build/captures/daf9, tout)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/daf9}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg
OUVERT="mansion_switch_on"
HERSES="cinnabar_gym_gate_1,cinnabar_gym_gate_2,cinnabar_gym_gate_3,cinnabar_gym_gate_4,cinnabar_gym_gate_5,cinnabar_gym_gate_6"

# nom | images | options de capture_viridian_forest.gd
SHOTS=(
	"manoir_1f_vue|30|--map=pokemon_mansion_1f --cell=5,26 --aim=15,14 --zoom=0.4 --gates="
	"manoir_2f_vue|30|--map=pokemon_mansion_2f --cell=7,11 --aim=15,14 --zoom=0.4 --gates="
	"manoir_3f_vue|30|--map=pokemon_mansion_3f --cell=6,2 --aim=15,9 --zoom=0.55 --gates="
	"manoir_b1f_vue|30|--map=pokemon_mansion_b1f --cell=23,23 --aim=15,14 --zoom=0.4 --gates="
	"manoir_1f_marche_vue|30|--map=pokemon_mansion_1f --cell=5,26 --aim=15,14 --zoom=0.4 --gates=$OUVERT"
	"arene_vue|30|--map=cinnabar_gym --cell=16,16 --aim=10,9 --zoom=0.55 --gates="
	"arene_ouverte_vue|30|--map=cinnabar_gym --cell=16,16 --aim=10,9 --zoom=0.55 --gates=$HERSES"
	"ile_vue|30|--map=cinnabar_island --cell=15,7 --aim=17,13.5 --zoom=0.4 --gates="
	"manoir_1f|40|--map=pokemon_mansion_1f --cell=5,25 --facing=up --gates="
	"manoir_1f_statue|40|--map=pokemon_mansion_1f --cell=3,6 --facing=up --gates="
	"manoir_2f|40|--map=pokemon_mansion_2f --cell=4,11 --facing=up --gates="
	"manoir_3f|40|--map=pokemon_mansion_3f --cell=17,15 --facing=up --gates="
	"manoir_b1f|40|--map=pokemon_mansion_b1f --cell=10,7 --facing=up --gates="
	"arene|40|--map=cinnabar_gym --cell=16,16 --facing=up --gates="
	"arene_auguste|40|--map=cinnabar_gym --cell=3,4 --facing=up --gates=$HERSES"
	"ile|40|--map=cinnabar_island --cell=15,7 --facing=up --gates="
	"ile_plage|40|--map=cinnabar_island --cell=22,19 --facing=up --gates="
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_viridian_forest.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
