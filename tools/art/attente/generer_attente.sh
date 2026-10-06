#!/bin/bash
# Planches d'ATTENTE (pieds joints) des personnages et Pokémon peints (décision de Kevin du
# 2026-10-06 : à l'arrêt, `idle_<dir>` venait de la colonne « passage » de la marche, jambes
# écartées). Codex (tools/art/generer.sh, abonnement ChatGPT), en parallèle. Une bande d'UNE
# ligne de 4 poses (bas, gauche, droite, haut), découpée par decouper_attente.py.
#   tools/art/attente/generer_attente.sh [IDENTIFIANT ...]     (ex. RIVAL_ATTENTE_r1)
# Sans argument : tous les prompts de tools/art/attente/prompts, suffixe _r1. Référence jointe =
# la planche de marche source (manifeste) dans $ART (build/art par défaut, Mac de Kevin).
# Sorties : build/art/<id>.png ; journal build/art/log_<id>.txt.
set -u
cd "$(dirname "$0")/../../.."
A="${ART:-build/art}"
P=tools/art/attente/prompts
ref() {
	case "$1" in
		HEROS_*) echo "$A/PERSO_P2_PEINT_r1.png" ;;
		ENFANT_*) echo "$A/PNJ_ENFANT_P2_r1.png" ;;
		RATTATA_*) echo "$A/POKE_RATTATA_P2_r1.png" ;;
		ROUCOOL_*) echo "$A/POKE_ROUCOOL_NE_r1.png" ;;
		*) echo "$A/PNJ_${1%_ATTENTE*}_NE_r1.png" ;;
	esac
}
IDS=("$@")
if [ ${#IDS[@]} -eq 0 ]; then
	for F in "$P"/*.txt; do IDS+=("$(basename "$F" .txt)_r1"); done
fi
mkdir -p build/art
for ID in "${IDS[@]}"; do
	PROMPT="$P/${ID%_ATTENTE*}_ATTENTE.txt"
	( tools/art/generer.sh "$ID" "$PROMPT" $(ref "$ID") > "build/art/log_$ID.txt" 2>&1
	  echo "$ID exit $?" ) &
done
wait
