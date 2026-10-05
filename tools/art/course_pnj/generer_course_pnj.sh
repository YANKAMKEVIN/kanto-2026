#!/bin/bash
# Planches de course de l'enfant et du Rattata de Jadielle (micro-scène d'arrivée, dossier 09 §2,
# décision de Kevin du 2026-10-05) : Codex (tools/art/generer.sh, abonnement ChatGPT), en
# parallèle. Planche 4 × 4 complète + bande de profil (comme heros_run : la bande remplace les
# rangées gauche / droite, voir remplacer_profil_course.py).
#   tools/art/course_pnj/generer_course_pnj.sh [IDENTIFIANT ...]
# Sans argument : les 4 prompts de tools/art/course_pnj/prompts. Références (planches de marche,
# course du héros) dans $ART (build/art par défaut, Mac de Kevin). Sorties : build/art/<id>.png.
set -u
cd "$(dirname "$0")/../../.."
A="${ART:-build/art}"
P=tools/art/course_pnj/prompts
refs() {
	case "$1" in
		PNJ_ENFANT_COURSE_PROFIL*) echo "$A/PNJ_ENFANT_P2_r1.png $A/HEROS_COURSE_PROFIL_r1.png" ;;
		PNJ_ENFANT_COURSE*) echo "$A/PNJ_ENFANT_P2_r1.png $A/PERSO_P2_COURSE_r1.png" ;;
		POKE_RATTATA_COURSE*) echo "$A/POKE_RATTATA_P2_r1.png" ;;
	esac
}
IDS=("$@")
if [ ${#IDS[@]} -eq 0 ]; then
	for F in "$P"/*.txt; do IDS+=("$(basename "$F" .txt)"); done
fi
mkdir -p build/art
for ID in "${IDS[@]}"; do
	PROMPT="$P/${ID%_v*}.txt"
	( tools/art/generer.sh "$ID" "$PROMPT" $(refs "$ID") > "build/art/log_$ID.txt" 2>&1
	  echo "$ID exit $?" ) &
done
wait
