#!/usr/bin/env bash
# Captures du lot DAF.5, 2e partie (série 25, Chenipan, pont du S.S. Anne), 2340 × 1080, Movie Maker
# (Mac, pas en headless) :
#   tools/capture_daf5_reliquats.sh [dossier [filtre]]   (défaut : build/captures/daf5_reliquats)
# Réutilise `tools/capture_pewter.gd` ; override.cfg temporaire à la racine, retiré à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/daf5_reliquats}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f override.cfg; rm -rf "$TMP"; }
trap cleanup EXIT
printf '[display]\nwindow/size/window_width_override=2340\nwindow/size/window_height_override=1080\n' \
	> override.cfg
SHOTS=(
	"velo_profil|40|--map=route_17 --cell=11,52 --facing=left --mount=bike"
	"velo_pedale|24|--map=route_17 --cell=11,40 --facing=down --mount=bike --steps=down:3"
	"velo_dos|40|--map=fuchsia_city --cell=28,24 --facing=up --mount=bike"
	"loubard_motard|40|--map=route_17 --cell=13,52 --facing=left"
	"ornithologue_motard|40|--map=route_14 --cell=7,40 --facing=left"
	"peche_attente|40|--map=fuchsia_city --cell=43,30 --facing=right --pose=fish_wait"
	"peche_lancer|40|--map=fuchsia_city --cell=50,26 --facing=down --pose=fish_cast"
	"enclos|40|--map=fuchsia_city --cell=44,11 --facing=up"
	"frere_cadet|40|--map=fuchsia_good_rod_house --cell=10,7 --facing=up"
	"frere_aine|40|--map=route_12_rod_house --cell=10,7 --facing=up"
	"chenipan|40|--map=viridian_forest --cell=49,83 --facing=left"
	"ss_anne_pont|40|--map=ss_anne_outer_deck --facing=down"
	"ss_anne_pont_ensemble|20|--map=ss_anne_outer_deck --aim=20,10 --zoom=0.35 --noplayer"
)
for shot in "${SHOTS[@]}"; do
	IFS='|' read -r name frames opts <<< "$shot"
	[[ "$name" =~ $FILTER ]] || continue
	rm -rf "$TMP/f" && mkdir -p "$TMP/f"
	# shellcheck disable=SC2086
	godot --path . --write-movie "$TMP/f/f.png" --fixed-fps 60 --quit-after "$frames" \
		-s res://tools/capture_pewter.gd -- $opts > "$TMP/log.txt" 2>&1 || true
	grep -E "ERROR|SCRIPT ERROR" "$TMP/log.txt" && echo "  ($name : erreurs ci-dessus)" || true
	last="$(ls "$TMP"/f/f*.png | sort | tail -1)"
	cp "$last" "$OUT/$name.png"
	echo "$OUT/$name.png"
done
