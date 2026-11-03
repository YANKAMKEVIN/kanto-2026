#!/usr/bin/env bash
# Génère les images des finitions (tools/art/entree_finitions.py) absentes, une par une, dans l'ordre
# (la joueuse en dernier : elle reprend le héros obtenu). Usage : tools/art/entree_finitions_lot.sh [image ...]
set -uo pipefail
cd "$(dirname "$0")/../.."
IMAGES=("$@")
[[ ${#IMAGES[@]} -eq 0 ]] && IMAGES=(heros_surf nageurs_eau karateka_monde maitre_dojo_monde joueuse_surf)
for P in "${IMAGES[@]}"; do
	[[ -f "build/art/ES_${P}_r1.png" ]] && continue
	if python3 tools/art/entree_finitions.py generer "$P"; then
		echo "$P : faite ($(date +%H:%M))"
	else
		echo "$P : échec ($(date +%H:%M))"
	fi
done
