#!/usr/bin/env bash
# Génère les planches des classes ordinaires manquantes (tools/art/entree_ordinaires.py), une par
# une ; si Codex échoue (quota de l'abonnement épuisé), attend 20 min et reprend la même planche.
# Usage : tools/art/entree_ordinaires_lot.sh [planche ...]   (défaut : toutes les absentes)
set -uo pipefail
cd "$(dirname "$0")/../.."
PLANCHES=("$@")
[[ ${#PLANCHES[@]} -eq 0 ]] && PLANCHES=(sbires dresseuses nageurs labo esprit route_cyclable nature
	dojo randonnee elite jeux pillard_dompteur ss_anne metiers beaute_rockeur jeunes intello)
for P in "${PLANCHES[@]}"; do
	[[ -f "build/art/EO_${P}_r1.png" ]] && continue
	ESSAIS=0
	until python3 tools/art/entree_ordinaires.py generer "$P"; do
		ESSAIS=$((ESSAIS + 1))
		[[ $ESSAIS -ge 24 ]] && { echo "$P : abandon après $ESSAIS essais"; exit 1; }
		echo "$P : échec ($(date +%H:%M)), nouvel essai dans 20 min"
		sleep 1200
	done
	echo "$P : faite ($(date +%H:%M))"
done
