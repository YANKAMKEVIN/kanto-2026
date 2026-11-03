#!/usr/bin/env bash
# Captures réelles 2340 × 1080 de l'entrée des combats des Dresseurs ordinaires (fiche
# docs/design/fiches-assets/entree-dresseurs.md §12) : un combat par classe, dans un lieu où la
# classe se bat vraiment ; entrée et lancer. Puis planches : tools/art/planches_ordinaires.py.
# Usage : tools/capture_ordinaires.sh [classe ...]   (défaut : toutes)
set -euo pipefail
cd "$(dirname "$0")/.."
RACINE="$(pwd)"
# classe → Dresseur, carte, point d'arrivée
combat() {
	case "$1" in
		beaute) echo "route_15_beauty_1 route_15 from_route_14" ;;
		campeur) echo "route_6_camper_gabin route_6 from_underground" ;;
		chercheur) echo "mt_moon_researcher mt_moon_b2f arrivee_d" ;;
		dompteur) echo "fuchsia_gym_tamer_1 fuchsia_gym entree" ;;
		exorciste) echo "tower_channeler_1 pokemon_tower_3f arrivee_T23" ;;
		fillette) echo "route_8_lass_iris route_8 from_lavender_n" ;;
		gamin) echo "route_11_youngster_lucas route_11 from_vermilion_n" ;;
		gentleman) echo "ss_anne_gentleman_armand ss_anne_main_deck from_ss_anne_w" ;;
		ingenieur) echo "route_11_engineer_bruno route_11 from_vermilion_n" ;;
		intello) echo "cinnabar_gym_1 cinnabar_gym depuis_ile" ;;
		jeune_dresseur) echo "route_25_jr_trainer_adam route_25 from_route_24_n" ;;
		jeune_dresseuse) echo "route_24_alice route_24 from_cerulean_w" ;;
		jongleur) echo "fuchsia_gym_juggler_1 fuchsia_gym entree" ;;
		joueur) echo "route_8_gambler_rene route_8 from_lavender_n" ;;
		karateka) echo "fighting_dojo_blackbelt_hippolyte fighting_dojo entrance" ;;
		loubard) echo "route_17_cueball_1 route_17 from_route_16" ;;
		maitre_dojo) echo "fighting_dojo_master fighting_dojo entrance" ;;
		marin) echo "ss_anne_sailor_erwan ss_anne_lower_deck entrance" ;;
		medium) echo "saffron_gym_psychic_albin saffron_gym entrance" ;;
		montagnard) echo "route_9_hiker_benoit route_9 from_cerulean" ;;
		motard) echo "route_17_biker_1 route_17 from_route_16" ;;
		nageur) echo "route_19_swimmer_yann route_19 from_fuchsia_city" ;;
		nageuse) echo "route_20_swimmer_solene route_20 from_cinnabar_island" ;;
		ornithologue) echo "route_14_bird_1 route_14 from_route_13" ;;
		pecheur) echo "route_12_fisher_1 route_12 from_lavender_w" ;;
		pillard) echo "mansion_burglar_1 pokemon_mansion_2f arrivee_a" ;;
		pokemaniac) echo "route_10_maniac_hector route_10 from_route_9_n" ;;
		rockeur) echo "vermilion_gym_rocker_axel vermilion_gym entrance" ;;
		sbire_rocket) echo "silph_co_2f_3 silph_co_2f from_1f" ;;
		sbire_rocket_f) echo "rocket_hideout_b1f_2 rocket_hideout_b1f from_casino" ;;
		scientifique) echo "silph_co_2f_1 silph_co_2f from_1f" ;;
		scout) echo "forest_scout_theo viridian_forest from_gate_south" ;;
		topdresseur) echo "victory_road_1f_cooltrainer_m victory_road_1f from_route_23" ;;
		topdresseuse) echo "celadon_gym_cooltrainer_camelia celadon_gym entrance" ;;
	esac
}
TOUTES=$(grep -E '^[[:space:]]+[a-z_]+\) echo' "$0" | sed -E 's/^[[:space:]]+([a-z_]+)\).*/\1/')
CLASSES=("$@")
[[ ${#CLASSES[@]} -eq 0 ]] && CLASSES=($TOUTES)
mkdir -p build/ordinaires
for C in "${CLASSES[@]}"; do
	read -r T M S <<< "$(combat "$C")"
	rm -rf "build/ordinaires/$C"
	godot --path . --resolution 2340x1080 --fixed-fps 60 -s res://tools/capture_trainer_intro.gd \
		-- --trainer="$T" --map="$M" --spawn="$S" --shots="$RACINE/build/ordinaires/$C" \
		> "build/ordinaires/$C.log" 2>&1 || true
	echo "$C : $(ls "build/ordinaires/$C" 2>/dev/null | tr '\n' ' ')"
done
