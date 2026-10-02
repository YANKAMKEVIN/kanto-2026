#!/usr/bin/env bash
# Affiche la série adb du Galaxy S24, branché en USB ou en débogage sans fil.
# Ordre : câble USB → déjà connecté en Wi-Fi → découverte mDNS (S24 déjà appairé) → S24_ADDR (ip:port).
# Usage : S24=$(tools/s24_serial.sh) || exit 1 ; puis $ADB -s "$S24" ...
# Appairage sans fil (une seule fois) : S24 > Options de développement > Débogage sans fil >
# « Associer l'appareil avec un code », puis : $ADB pair <ip>:<port d'association> <code>
set -euo pipefail
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
USB_SERIAL="${ANDROID_SERIAL:-RFCX80Y0FVX}"

"$ADB" start-server >/dev/null 2>&1

# Un appareil connecté en Wi-Fi s'appelle ip:port ou adb-<série>-… : on le reconnaît à sa série matérielle.
find_s24() {
  local dev
  for dev in $("$ADB" devices | awk 'NR > 1 && $2 == "device" {print $1}'); do
    if [[ "$("$ADB" -s "$dev" shell getprop ro.serialno 2>/dev/null | tr -d '\r')" == "$USB_SERIAL" ]]; then
      echo "$dev"; return 0
    fi
  done
  return 1
}

# Juste après le (re)démarrage du serveur adb, la découverte Wi-Fi (mDNS) prend quelques
# secondes : on réessaie avant de conclure que le S24 est absent.
for _attempt in 1 2 3 4 5 6; do
  if "$ADB" devices | awk -v s="$USB_SERIAL" '$1 == s && $2 == "device" {found = 1} END {exit !found}'; then
    echo "$USB_SERIAL"; exit 0
  fi
  find_s24 && exit 0

  addr=$("$ADB" mdns services 2>/dev/null \
    | awk -v s="adb-$USB_SERIAL" 'index($1, s) == 1 && $2 ~ /_adb-tls-connect/ {print $3; exit}')
  addr="${addr:-${S24_ADDR:-}}"
  if [[ -n "$addr" ]]; then
    "$ADB" connect "$addr" >/dev/null 2>&1 || true
    find_s24 && exit 0
  fi
  sleep 1
done

echo "S24 introuvable : ni câble USB, ni débogage sans fil." >&2
echo "Sans fil : activer « Débogage sans fil » sur le S24 (même Wi-Fi que le Mac) ; s'il n'a jamais été appairé, voir l'en-tête de tools/s24_serial.sh." >&2
exit 1
