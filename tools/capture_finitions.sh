#!/usr/bin/env bash
# Captures réelles 2340 × 1080 des finitions de l'entrée des combats de Dresseur (fiche
# docs/design/fiches-assets/entree-dresseurs.md §13) : la mer à pied (banc de sable) et en Surf
# (même combat, Route 19), la joueuse en Surf, les Routes 16 ouest et 18 sur la Piste, le
# Karatéka et le Maître du Dojo (combat et monde). Puis planches : tools/art/planches_finitions.py.
# Usage : tools/capture_finitions.sh [capture ...]   (défaut : toutes)
set -euo pipefail
cd "$(dirname "$0")/.."
RACINE="$(pwd)"
# capture → Dresseur, carte, point d'arrivée, options
combat() {
	case "$1" in
		mer_sable) echo "route_19_swimmer_yann route_19 from_fuchsia_city" ;;
		mer_surf) echo "route_19_swimmer_yann route_19 from_fuchsia_city --surf" ;;
		mer_surf_joueuse) echo "route_20_swimmer_solene route_20 from_cinnabar_island --surf --look=heroine" ;;
		route_16_ouest) echo "route_16_cueball_1 route_16_west from_route_17" ;;
		route_18) echo "route_18_bird_1 route_18 from_route_17" ;;
		karateka) echo "fighting_dojo_blackbelt_hippolyte fighting_dojo entrance" ;;
		karateka_jadielle) echo "viridian_gym_blackbelt_bertrand viridian_gym entrance" ;;
	esac
}
TOUTES=$(grep -E '^[[:space:]]+[a-z_0-9]+\) echo' "$0" | sed -E 's/^[[:space:]]+([a-z_0-9]+)\).*/\1/')
CAPTURES=("$@")
[[ ${#CAPTURES[@]} -eq 0 ]] && CAPTURES=($TOUTES)
mkdir -p build/finitions
for C in "${CAPTURES[@]}"; do
	read -r T M S O1 O2 <<< "$(combat "$C")"
	rm -rf "build/finitions/$C"
	godot --path . --resolution 2340x1080 --fixed-fps 60 -s res://tools/capture_trainer_intro.gd \
		-- --trainer="$T" --map="$M" --spawn="$S" ${O1:-} ${O2:-} \
		--entree=dresseurs --shots="$RACINE/build/finitions/$C" > "build/finitions/$C.log" 2>&1 || true
	echo "$C : $(ls "build/finitions/$C" 2>/dev/null | tr '\n' ' ')"
done
