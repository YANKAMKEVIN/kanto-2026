#!/usr/bin/env bash
# Captures de la passe d'ambiance du Chapitre Johto, lot 2 (`tools/build_joh_ambiance.gd`,
# `tools/build_joh_ambiance_caves.gd`, `tools/build_joh_ambiance_radio.gd`) : JOH3, JOH4, JOH5 et
# JOH7, de jour et de nuit, plus les vues d'ensemble `*_vue` (caméra libre, comparaison avec les
# vues générales). 2340 × 1080, Movie Maker (Mac, pas en headless), par `tools/capture_pewter.gd`
# en mode `--boot` (vraie scène `game/boot.tscn` : lumière, halos de nuit, HUD).
#   tools/capture_joh_ambiance2.sh [dossier [filtre]]   (défaut : build/captures/joh_lot2, tout)
# Une image par plan (dernière image du film). Départs `_cap2_*` écrits dans `tools/debug_start/`
# le temps des captures (copies de `johto_goldenrod` et `johto_whirl_route_40`, carte, arrivée et
# moment changés), retirés à la fin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-build/captures/joh_lot2}"
FILTER="${2:-.}"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
cleanup() { rm -f tools/debug_start/_cap2_*.json; rm -rf "$TMP"; }
trap cleanup EXIT

python3 - <<'PY'
import json
# départ → (base, carte, arrivée)
STARTS = {
	"r37": ("johto_goldenrod", "route_37", "from_ecruteak"),
	"r36": ("johto_goldenrod", "route_36", "from_route_37"),
	"r35": ("johto_goldenrod", "route_35", "from_route_36"),
	"doub": ("johto_goldenrod", "goldenrod_city", "from_route_35"),
	"r34": ("johto_goldenrod", "route_34", "from_goldenrod"),
	"bois": ("johto_goldenrod", "ilex_forest", "from_route_34"),
	"eco": ("johto_goldenrod", "azalea_town", "from_ilex"),
	"r40": ("johto_whirl_route_40", "route_40", "from_olivine"),
	"r41": ("johto_whirl_route_40", "route_41", "from_route_40"),
	"sout": ("johto_goldenrod", "goldenrod_underground", "from_goldenrod_west"),
	"p1": ("johto_goldenrod", "slowpoke_well_b1f", "from_azalea"),
	"p2": ("johto_goldenrod", "slowpoke_well_b2f", "from_b1f"),
	"t1": ("johto_goldenrod", "goldenrod_radio_tower_1f", "from_city"),
	"t2": ("johto_goldenrod", "goldenrod_radio_tower_2f", "from_1f"),
	"t3": ("johto_goldenrod", "goldenrod_radio_tower_3f", "from_2f"),
	"t4": ("johto_goldenrod", "goldenrod_radio_tower_4f", "from_3f"),
	"t5": ("johto_goldenrod", "goldenrod_radio_tower_5f", "from_4f"),
	"w1": ("johto_whirl_route_40", "whirl_islands_1f", "from_route_41"),
	"w2": ("johto_whirl_route_40", "whirl_islands_b1f", "from_1f"),
	"w3": ("johto_whirl_route_40", "whirl_islands_b2f", "from_b1f"),
}
for name, (base, map_id, spawn) in STARTS.items():
	for period in ("day", "night"):
		start = json.load(open(f"tools/debug_start/{base}.json"))
		start.update({"map": map_id, "spawn": spawn, "period": period})
		json.dump(start, open(f"tools/debug_start/_cap2_{name}_{period}.json", "w"),
			ensure_ascii=False, indent=1)
PY

day() { echo "--boot --start=_cap2_$1_day"; }
night() { echo "--boot --start=_cap2_$1_night"; }
# nom | images | options de capture_pewter.gd
SHOTS=(
	"r37_vue|30|--map=route_37 --noplayer --aim=10,20 --zoom=0.25"
	"r37_jour_sud|50|$(day r37) --cell=9,28 --facing=down"
	"r37_jour_verger|50|$(day r37) --cell=7,10 --facing=left"
	"r37_nuit_sud|50|$(night r37) --cell=9,28 --facing=down"
	"r36_vue|30|--map=route_36 --noplayer --aim=28,10 --zoom=0.4"
	"r36_jour_grille|50|$(day r36) --cell=34,8 --facing=up"
	"r36_jour_pont|50|$(day r36) --cell=40,10 --facing=right"
	"r36_nuit_grille|50|$(night r36) --cell=34,8 --facing=up"
	"r36_nuit_pont|50|$(night r36) --cell=40,10 --facing=right"
	"r35_vue|30|--map=route_35 --noplayer --aim=12,22 --zoom=0.23"
	"r35_jour_etang|50|$(day r35) --cell=9,20 --facing=left"
	"r35_jour_poste|50|$(day r35) --cell=11,37 --facing=right"
	"r35_nuit_poste|50|$(night r35) --cell=11,37 --facing=right"
	"doub_vue|30|--map=goldenrod_city --noplayer --aim=36,30 --zoom=0.17"
	"doub_jour_tour|50|$(day doub) --cell=11,17 --facing=up"
	"doub_jour_magasin|50|$(day doub) --cell=50,29 --facing=up"
	"doub_jour_place|50|$(day doub) --cell=35,29 --facing=down"
	"doub_jour_gare|50|$(day doub) --cell=59,47 --facing=up"
	"doub_jour_centre|50|$(day doub) --cell=16,29 --facing=up"
	"doub_nuit_tour|50|$(night doub) --cell=11,17 --facing=up"
	"doub_nuit_magasin|50|$(night doub) --cell=50,29 --facing=up"
	"doub_nuit_place|50|$(night doub) --cell=35,29 --facing=down"
	"doub_nuit_gare|50|$(night doub) --cell=59,47 --facing=up"
	"r34_vue|30|--map=route_34 --noplayer --aim=12,24 --zoom=0.21"
	"r34_jour_maison|50|$(day r34) --cell=12,11 --facing=up"
	"r34_jour_etang|50|$(day r34) --cell=9,21 --facing=left"
	"r34_jour_cloture|50|$(day r34) --cell=11,42 --facing=up"
	"r34_nuit_maison|50|$(night r34) --cell=12,11 --facing=up"
	"bois_vue|30|--map=ilex_forest --noplayer --aim=24,24 --zoom=0.21"
	"bois_jour_autel|50|$(day bois) --cell=23,13 --facing=up"
	"bois_jour_sentier|50|$(day bois) --cell=12,18 --facing=right"
	"bois_jour_charbonnier|50|$(day bois) --cell=37,43 --facing=left"
	"bois_nuit_autel|50|$(night bois) --cell=23,13 --facing=up"
	"eco_vue|30|--map=azalea_town --noplayer --aim=22,18 --zoom=0.27"
	"eco_jour_charbonnerie|50|$(day eco) --cell=9,12 --facing=up"
	"eco_jour_puits|50|$(day eco) --cell=36,9 --facing=up"
	"eco_jour_centre|50|$(day eco) --cell=21,21 --facing=left"
	"eco_jour_fargas|50|$(day eco) --cell=10,31 --facing=up"
	"eco_nuit_charbonnerie|50|$(night eco) --cell=9,12 --facing=up"
	"eco_nuit_centre|50|$(night eco) --cell=21,21 --facing=left"
	"eco_nuit_puits|50|$(night eco) --cell=36,9 --facing=up"
	"r40_vue|30|--map=route_40 --noplayer --aim=12,20 --zoom=0.24"
	"r40_jour_banc|50|$(day r40) --cell=14,9 --facing=right"
	"r40_nuit_banc|50|$(night r40) --cell=14,9 --facing=right"
	"r41_vue|30|--map=route_41 --noplayer --aim=30,24 --zoom=0.21"
	"r41_jour_entree|50|$(day r41) --cell=17,24 --facing=right"
	"r41_jour_tourbillons|50|$(day r41) --cell=30,12 --facing=up"
	"r41_nuit_entree|50|$(night r41) --cell=17,24 --facing=right"
	"sout_vue|30|--map=goldenrod_underground --noplayer --aim=20,7 --zoom=0.5"
	"sout_ouest|50|$(day sout) --cell=6,6 --facing=right"
	"sout_chef|50|$(day sout) --cell=32,10 --facing=up"
	"p1_vue|30|--map=slowpoke_well_b1f --noplayer --aim=15,12 --zoom=0.36"
	"p1_entree|50|$(day p1) --cell=6,3 --facing=right"
	"p1_mare|50|$(day p1) --cell=14,13 --facing=down"
	"p2_vue|30|--map=slowpoke_well_b2f --noplayer --aim=15,12 --zoom=0.36"
	"p2_caisses|50|$(day p2) --cell=25,6 --facing=up"
	"p2_mare|50|$(day p2) --cell=14,19 --facing=up"
	"t1_vue|30|--map=goldenrod_radio_tower_1f --noplayer --aim=12,8 --zoom=0.7"
	"t2_vue|30|--map=goldenrod_radio_tower_2f --noplayer --aim=12,8 --zoom=0.7"
	"t3_vue|30|--map=goldenrod_radio_tower_3f --noplayer --aim=12,8 --zoom=0.7"
	"t4_vue|30|--map=goldenrod_radio_tower_4f --noplayer --aim=12,8 --zoom=0.7"
	"t5_vue|30|--map=goldenrod_radio_tower_5f --noplayer --aim=12,8 --zoom=0.7"
	"t1_hall|50|$(day t1) --cell=11,8 --facing=up"
	"t2_studio|50|$(day t2) --cell=9,8 --facing=up"
	"t3_archives|50|$(day t3) --cell=11,6 --facing=left"
	"t4_regie|50|$(day t4) --cell=12,7 --facing=up"
	"t5_studio|50|$(day t5) --cell=12,12 --facing=up"
	"w1_vue|30|--map=whirl_islands_1f --noplayer --aim=15,12 --zoom=0.36"
	"w2_vue|30|--map=whirl_islands_b1f --noplayer --aim=18,14 --zoom=0.31"
	"w3_vue|30|--map=whirl_islands_b2f --noplayer --aim=12,12 --zoom=0.42"
	"w1_entree|50|$(day w1) --cell=4,12 --facing=right"
	"w1_salle|50|$(day w1) --cell=24,16 --facing=down"
	"w2_rive|50|$(day w2) --cell=26,18 --facing=left"
	"w2_lac|50|$(day w2) --cell=11,8 --facing=down"
	"w3_corniche|50|$(day w3) --cell=12,18 --facing=up"
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
