#!/usr/bin/env bash
# Chantier CO : génère les sprites de jeu des costumes (Codex, 4 en parallèle).
# Gabarits attendus dans build/art/ancres_co/ : assets bruts du héros (comme `generer_jr.sh`) et
# de la joueuse (JR_JOUEUSE_*_r1, branche du chantier JR). Identité : moitié gauche (joueur) ou
# droite (joueuse) de docs/design/reference/costumes/costume-<badge>-v1.webp, découpée ici.
# Usage : tools/art/costumes/generer_sprites_co.sh BADGE [FILTRE ...]
#   FILTRE : fin d'identifiant à garder (ex. JOUEUR_MARCHE) ; sans filtre, les 22 assets du badge.
# Sortie : build/art/CO_<BADGE>_<VERSION>_<ASSET>_${REV:-r1}.png
set -uo pipefail
export REV="${REV:-r1}"
cd "$(dirname "$0")/../../.."
A=build/art/ancres_co
BADGE="$1"; shift
python3 - "$BADGE" "$A" <<'EOF'
import sys
from PIL import Image
badge, ancres = sys.argv[1], sys.argv[2]
planche = Image.open(f"docs/design/reference/costumes/costume-{badge.lower()}-v1.webp").convert("RGB")
moitie = planche.width // 2
planche.crop((0, 0, moitie, planche.height)).save(f"{ancres}/CO_{badge}_JOUEUR_ID.png")
planche.crop((moitie, 0, planche.width, planche.height)).save(f"{ancres}/CO_{badge}_JOUEUSE_ID.png")
EOF
python3 tools/art/costumes/prompts_sprites_co.py "$BADGE" | while read -r ID GABARIT IDENTITE; do
	if [[ $# -gt 0 ]]; then
		garde=0
		for F in "$@"; do [[ "$ID" == *"_$F" ]] && garde=1; done
		[[ $garde == 0 ]] && continue
	fi
	echo "$ID $GABARIT $IDENTITE"
done | xargs -P 4 -L 1 bash -c \
	'tools/art/generer.sh "$0_$REV" "tools/art/costumes/prompts/$0.txt" "'$A'/$1.png" "'$A'/$2.png" || echo "ÉCHEC $0"'
