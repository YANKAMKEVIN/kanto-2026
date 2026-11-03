#!/usr/bin/env bash
# Captures réelles 2340 × 1080 de l'entrée des autres grands combats (rival, Giovanni hors Arène,
# Conseil des 4, Maître), entrée, lancer, VS ; puis planches : tools/art/planches_grands_combats.py.
# Usage : tools/capture_grands_combats.sh [combat ...]   (défaut : tous ; « rivale_<combat> » =
# même combat avec la rivale)
set -euo pipefail
cd "$(dirname "$0")/.."
RACINE="$(pwd)"
COMBATS=("$@")
[[ ${#COMBATS[@]} -eq 0 ]] && COMBATS=(rival_labo rival_route22 rival_route24 rival_ss_anne rival_tour
	rival_sylphe rival_route22_final giovanni_repaire giovanni_sylphe olga aldo agatha peter maitre
	rivale_maitre)
mkdir -p build/grands
for C in "${COMBATS[@]}"; do
	rm -rf "build/grands/$C"
	EXTRA=()
	B="$C"
	if [[ "$C" == rivale_* ]]; then
		EXTRA=(--rival_look=rivale)
		B="rival_${C#rivale_}"
		[[ "$C" == "rivale_maitre" ]] && B="maitre"
	fi
	godot --path . --resolution 2340x1080 --fixed-fps 60 -s res://tools/capture_trainer_intro.gd \
		-- --battle="$B" --shots="$RACINE/build/grands/$C" ${EXTRA[@]+"${EXTRA[@]}"} \
		> "build/grands/$C.log" 2>&1 || true
	echo "$C : $(ls "build/grands/$C" 2>/dev/null | tr '\n' ' ')"
done
