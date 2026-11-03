#!/usr/bin/env bash
# Exporte le projet Xcode iOS et compile l'app. Usage :
#   tools/build_ios.sh                 # export + compilation pour le simulateur (sans signature)
#   tools/build_ios.sh --run           # idem, puis installation et lancement dans le simulateur
#   tools/build_ios.sh --device        # export + compilation signée pour un iPhone (KANTO_IOS_TEAM requis)
#   tools/build_ios.sh --export-only   # export du projet Xcode seulement (build/ios/kanto2026.xcodeproj)
#   tools/build_ios.sh --no-export ... # réutilise l'export précédent (pas de ré-export Godot)
#
# Variables : KANTO_IOS_TEAM (identifiant d'équipe Apple à 10 caractères, obligatoire pour
# --device ; le preset d'export garde un identifiant factice remplacé ici) ; KANTO_IOS_SIM (nom ou
# UDID du simulateur, défaut « iPhone 16 Pro »).
#
# Simulateur : les modèles d'export officiels de Godot 4.7 ne contiennent qu'une tranche x86_64
# pour le simulateur, donc l'app est compilée en x86_64 et tourne sous Rosetta ; il faut un
# simulateur avec un runtime iOS 18 (les runtimes iOS 26 n'acceptent plus Rosetta).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="build/ios"
XCODEPROJ="$OUT/kanto2026.xcodeproj"
DERIVED="$OUT/derived"
LOG="$OUT/xcodebuild.log"
SIM="${KANTO_IOS_SIM:-iPhone 16 Pro}"
BUNDLE_ID="dev.kevin.kanto2026"
EXPORT=1; BUILD=1; TARGET="sim"; RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run) RUN=1 ;;
    --device) TARGET="device" ;;
    --export-only) BUILD=0 ;;
    --no-export) EXPORT=0 ;;
    *) echo "option inconnue : $1" >&2; exit 2 ;;
  esac
  shift
done

mkdir -p "$OUT"
if [[ $EXPORT -eq 1 ]]; then
  godot --headless --path . --import >/dev/null 2>&1 || true
  godot --headless --path . --export-debug "iOS" "$XCODEPROJ" 2>&1 \
    | grep -E "ERROR|WARNING|rror" | grep -v "tcp:5037" || true
  test -d "$XCODEPROJ" || { echo "export iOS échoué : $XCODEPROJ absent" >&2; exit 1; }
  echo "Projet Xcode : $XCODEPROJ ($(du -sh "$OUT/kanto2026.pck" | cut -f1) de données)"
fi
[[ $BUILD -eq 1 ]] || exit 0

if [[ "$TARGET" == "sim" ]]; then
  xcodebuild -project "$XCODEPROJ" -scheme kanto2026 -configuration Debug \
    -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= build > "$LOG" 2>&1 \
    || { grep -E "error:|BUILD FAILED" "$LOG" | head -20 >&2; exit 1; }
  APP="$DERIVED/Build/Products/Debug-iphonesimulator/kanto2026.app"
  echo "App simulateur : $APP ($(du -sh "$APP" | cut -f1))"
  [[ $RUN -eq 1 ]] || exit 0
  xcrun simctl boot "$SIM" 2>/dev/null || true
  open -a Simulator
  xcrun simctl bootstatus "$SIM" -b >/dev/null
  xcrun simctl install "$SIM" "$APP"
  xcrun simctl launch "$SIM" "$BUNDLE_ID"
  echo "Journal Godot : xcrun simctl spawn \"$SIM\" log stream --predicate 'process == \"kanto2026\"'"
else
  TEAM="${KANTO_IOS_TEAM:-}"
  [[ -n "$TEAM" ]] || { echo "KANTO_IOS_TEAM (identifiant d'équipe Apple) est requis pour --device" >&2; exit 2; }
  xcodebuild -project "$XCODEPROJ" -scheme kanto2026 -configuration Debug \
    -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath "$DERIVED" \
    -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic build > "$LOG" 2>&1 \
    || { grep -E "error:|BUILD FAILED" "$LOG" | head -20 >&2; exit 1; }
  APP="$DERIVED/Build/Products/Debug-iphoneos/kanto2026.app"
  echo "App iPhone : $APP ($(du -sh "$APP" | cut -f1))"
  echo "Installation : xcrun devicectl list devices ; xcrun devicectl device install app --device <id> \"$APP\""
fi
