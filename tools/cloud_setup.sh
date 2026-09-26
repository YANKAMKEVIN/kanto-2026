#!/usr/bin/env bash
# Installe Godot dans une session Claude Code cloud (VM Ubuntu x86_64), pour que
# tools/test.sh et l'import fonctionnent. Lancé par le hook SessionStart de
# .claude/settings.json ; ne fait rien en local (CLAUDE_CODE_REMOTE != true).
# Le déploiement sur le S24 reste local (adb, USB).
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi

GODOT_VERSION="4.7.2"   # même version que sur le Mac de Kevin (godot --version)
GODOT_BIN="/usr/local/bin/godot"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"

if [ -x "$GODOT_BIN" ] && "$GODOT_BIN" --version 2>/dev/null | grep -q "^${GODOT_VERSION}\."; then
	echo "Godot ${GODOT_VERSION} déjà installé."
else
	TMP="$(mktemp -d)"
	echo "Téléchargement de Godot ${GODOT_VERSION}…"
	curl -fsSL "$URL" -o "$TMP/godot.zip"
	command -v unzip >/dev/null || (apt-get update -qq && apt-get install -y -qq unzip)
	unzip -q "$TMP/godot.zip" -d "$TMP"
	install -m 755 "$TMP/Godot_v${GODOT_VERSION}-stable_linux.x86_64" "$GODOT_BIN"
	rm -rf "$TMP"
	echo "Installé : $("$GODOT_BIN" --version)"
fi

# Premier import : génère .godot/ (cache des classes) pour que les scripts et les tests se chargent.
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/..}"
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1 || true
echo "Projet importé. Tests : tools/test.sh"
