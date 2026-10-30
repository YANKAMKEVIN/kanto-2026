#!/usr/bin/env bash
# Génère une image avec Codex (inclus dans l'app ChatGPT de Kevin, abonnement ChatGPT,
# sans clé API ni dépense en plus) et la copie dans build/art/<identifiant>.png.
# Usage : tools/art/generer.sh IDENTIFIANT fichier_prompt.txt [image_jointe ...]
# Le prompt est lu dans un fichier (ADN + fiche) ; les images jointes sont les références.
set -euo pipefail
cd "$(dirname "$0")/../.."
CODEX="${CODEX:-/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex}"
ID="$1"; PROMPT="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift 2
JOINTES=()
for IMAGE in "$@"; do JOINTES+=(-i "$(cd "$(dirname "$IMAGE")" && pwd)/$(basename "$IMAGE")"); done
TRAVAIL="$(mktemp -d)"
ENTETE="Utilise ton outil de génération d'images pour produire UNE image. N'écris pas de code et
ne lance aucune commande. Quand l'image est produite, réponds seulement : FAIT."
{ echo "$ENTETE"; echo; cat "$PROMPT"; } > "$TRAVAIL/prompt.txt"
if ! ( cd "$TRAVAIL" && "$CODEX" exec --skip-git-repo-check -s read-only --json \
	${JOINTES[@]+"${JOINTES[@]}"} - < prompt.txt > sortie.jsonl ); then
	# Échec de Codex lui-même (quota de l'abonnement épuisé, réseau) : message d'erreur affiché.
	echo "Codex en échec : $(grep -o '"message":"[^"]*"' "$TRAVAIL/sortie.jsonl" | tail -1)" >&2
	exit 1
fi
SESSION="$(grep -o '"thread_id":"[^"]*"' "$TRAVAIL/sortie.jsonl" | head -1 | cut -d'"' -f4)"
IMAGE="$(ls -t "$HOME/.codex/generated_images/$SESSION"/*.png 2>/dev/null | head -1 || true)"
if [[ -z "$IMAGE" ]]; then
	echo "Aucune image produite (session $SESSION) ; journal : $TRAVAIL/sortie.jsonl" >&2
	exit 1
fi
mkdir -p build/art
cp "$IMAGE" "build/art/$ID.png"
echo "build/art/$ID.png"
