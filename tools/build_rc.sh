#!/usr/bin/env bash
# Construit l'APK **release signé** du cercle de la maison (J34 T2) : build identifié et traçable.
#
# Usage : tools/build_rc.sh [--allow-dirty] [--skip-ci] [--install]
#   --allow-dirty  accepte un arbre Git modifié (le manifeste le note ; jamais pour un APK diffusé)
#   --skip-ci      ne vérifie pas que la CI GitHub est verte sur ce commit (le manifeste le note)
#   --install      installe l'APK par adb sur le téléphone branché (mise à jour par-dessus, -r)
#
# Clé de signature (jamais dans le dépôt) : variables d'environnement lues par Godot lui-même,
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH      chemin du keystore (tools/make_keystore.sh le crée)
#   GODOT_ANDROID_KEYSTORE_RELEASE_USER      alias de la clé
#   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD  mot de passe
# Sortie : build/rc/pokemake-<version>.apk, manifest.json, SHA256SUMS. Détail : docs/tech/release.md
set -euo pipefail
cd "$(dirname "$0")/.."

ALLOW_DIRTY=0
SKIP_CI=0
INSTALL=0
for arg in "$@"; do
	case "$arg" in
		--allow-dirty) ALLOW_DIRTY=1 ;;
		--skip-ci) SKIP_CI=1 ;;
		--install) INSTALL=1 ;;
		*) echo "Option inconnue : $arg" >&2; exit 2 ;;
	esac
done

fail() { echo "ERREUR : $*" >&2; exit 1; }

# 1. Identité : commit, arbre propre, version cohérente.
SHA="$(git rev-parse HEAD)"
DIRTY=0
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
	DIRTY=1
	[ "$ALLOW_DIRTY" = 1 ] || fail "arbre Git modifié : commite, ou --allow-dirty pour un essai local"
fi
python3 tools/version.py check
VERSION="$(python3 tools/version.py json | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])')"
CODE="$(python3 tools/version.py json | python3 -c 'import json,sys; print(json.load(sys.stdin)["code"])')"

# 2. Clé de signature.
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?keystore release absent : voir tools/make_keystore.sh et docs/tech/release.md}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?alias de la clé release absent}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?mot de passe de la clé release absent}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
[ -f "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" ] || fail "keystore introuvable : $GODOT_ANDROID_KEYSTORE_RELEASE_PATH"
case "$(cd "$(dirname "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH")" && pwd)" in
	"$(pwd)"*) fail "le keystore est dans le dépôt : garde-le ailleurs (jamais commité)" ;;
esac

# 3. Tests : CI GitHub verte sur ce commit (remplace la suite du Mac, décision du 2026-10-26).
CI="non vérifiée (--skip-ci)"
if [ "$SKIP_CI" = 0 ]; then
	[ "$DIRTY" = 0 ] || fail "arbre modifié : la CI ne peut pas couvrir ce build (--skip-ci pour un essai local)"
	# La CI ne se lance pas pour un commit qui ne touche que docs/ ou *.md (paths-ignore du workflow) :
	# dans ce cas on prend la CI du dernier ancêtre testé, à condition que tout ce qui a changé depuis
	# soit de la documentation (le code construit est alors celui qui a été testé).
	CI_SHA="$SHA"
	CI_RUN="$(gh run list --workflow godot-tests.yml --commit "$CI_SHA" --limit 1 --json databaseId --jq '.[0].databaseId // ""' 2>/dev/null || true)"
	if [ -z "$CI_RUN" ]; then
		for ANCESTOR in $(git rev-list --first-parent --max-count=30 "$SHA"); do
			RUN="$(gh run list --workflow godot-tests.yml --commit "$ANCESTOR" --limit 1 --json databaseId --jq '.[0].databaseId // ""' 2>/dev/null || true)"
			if [ -n "$RUN" ]; then CI_SHA="$ANCESTOR"; CI_RUN="$RUN"; break; fi
		done
		[ -n "$CI_RUN" ] || fail "aucune CI sur $SHA ni sur ses ancêtres récents : pousse, puis tools/ci_wait.sh"
		if git diff --name-only "$CI_SHA" "$SHA" | grep -v -E '^docs/|\.md$' | grep -q .; then
			fail "$SHA n'a pas de CI et diffère de ${CI_SHA:0:8} (testé) par autre chose que de la documentation : pousse, puis tools/ci_wait.sh"
		fi
	fi
	CONCLUSION="$(gh run view "$CI_RUN" --json conclusion --jq '.conclusion // ""' 2>/dev/null || true)"
	[ "$CONCLUSION" = "success" ] || fail "CI non verte sur ${CI_SHA:0:8} (conclusion : « ${CONCLUSION:-aucune} ») : pousse, puis tools/ci_wait.sh"
	CI="success ($CI_RUN${CI_SHA:+, commit ${CI_SHA:0:8}})"
fi

# 4. Export release signé par Godot, puis fond du splash Android 12+ (re-signé avec la même clé).
OUT_DIR="build/rc"
APK="$OUT_DIR/pokemake-$VERSION.apk"
mkdir -p "$OUT_DIR"
rm -f "$APK" "$APK.idsig"
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-release Android "$APK" 2>&1 | grep -E "ERROR|WARNING|rror" || true
[ -f "$APK" ] || fail "export release échoué (voir les messages ci-dessus)"
python3 tools/android_splash_bg.py --release "$APK" 2>&1 | grep -v "^WARNING: \|^$" || true

# 5. Vérifications sur l'APK produit : signature, identifiant, version.
# Dernier build-tools stable (pas de -rcN) ; aapt2 lit le manifeste du modèle Godot sans erreur.
BUILD_TOOLS="$(ls -d "$HOME"/Library/Android/sdk/build-tools/* | grep -E '/[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)"
"$BUILD_TOOLS/apksigner" verify --print-certs "$APK" 2>/dev/null | grep -E "Signer #1 certificate SHA-256" | sed 's/^/  /'
BADGING="$("$BUILD_TOOLS/aapt2" dump badging "$APK" 2>/dev/null | grep '^package:' || true)"
echo "$BADGING" | grep -q "name='dev.kevin.kanto2026'" || fail "identifiant inattendu : $BADGING"
echo "$BADGING" | grep -q "versionCode='$CODE'" || fail "versionCode inattendu : $BADGING"
echo "$BADGING" | grep -q "versionName='$VERSION'" || fail "versionName inattendu : $BADGING"

# 6. Empreinte et manifeste.
SHA256="$(shasum -a 256 "$APK" | cut -d' ' -f1)"
(cd "$OUT_DIR" && shasum -a 256 "$(basename "$APK")" > SHA256SUMS)
python3 - "$APK" "$VERSION" "$CODE" "$SHA" "$DIRTY" "$CI" "$SHA256" <<'EOF' > "$OUT_DIR/manifest.json"
import datetime, json, os, subprocess, sys
apk, version, code, sha, dirty, ci, digest = sys.argv[1:]
godot = subprocess.run(["godot", "--version"], capture_output=True, text=True).stdout.strip()
print(json.dumps({
    "name": "Pokemake",
    "application_id": "dev.kevin.kanto2026",
    "version_name": version,
    "version_code": int(code),
    "commit": sha,
    "git_dirty": dirty == "1",
    "branch": subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True).stdout.strip(),
    "godot": godot,
    "preset": "Android (export-release, arm64-v8a, signé release)",
    "ci": ci,
    "apk": os.path.basename(apk),
    "size_bytes": os.path.getsize(apk),
    "sha256": digest,
    "built_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
}, indent=2, ensure_ascii=False))
EOF

echo "APK release : $APK ($(du -h "$APK" | cut -f1)) — $VERSION, code $CODE, commit ${SHA:0:8}"
echo "SHA-256 : $SHA256"
echo "Manifeste : $OUT_DIR/manifest.json, $OUT_DIR/SHA256SUMS"

# 7. Installation facultative (mise à jour par-dessus la version installée, même clé exigée).
if [ "$INSTALL" = 1 ]; then
	ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
	"$ADB" install -r "$APK"
fi
