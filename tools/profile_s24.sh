#!/usr/bin/env bash
# Profilage Android du J33 (T3, 33C) : une session de ~30 min sur le Galaxy S24 qui relève la
# mémoire à intervalles réguliers, la cadence (lignes [perf] de PerfCounter) et la température,
# par profil : extérieur, ville, grand donjon, combat, Stockage, plus les cartes de RP-091 et le
# quai de RP-093. Rien n'est optimisé ici : on mesure.
#
# Usage : tools/profile_s24.sh [--check] [--no-build] [--scale 0.3] [--profiles liste]
#                              [--brightness 128] [--power usb|battery] [--out dossier]
#   --check       : vérifie seulement le protocole (série, DND, écran, sauvegarde lisible) ; ne
#                   lance rien, ne touche à rien.
#   --scale N     : multiplie toutes les durées (0.3 = essai rapide).
#   --profiles    : liste séparée par des virgules parmi
#                   exterieur,ville,donjon,combat,stockage,rp091,rp093 (défaut : tous, ≈ 30 min).
#   --power       : état déclaré de l'alimentation ; le script refuse de continuer s'il ne
#                   correspond pas à ce qu'il lit (usb = branché, battery = sur batterie).
#   --allow-no-dnd: autorise l'absence de Ne pas déranger (téléphone de test non personnel, ex. A17
#                   choisi par Kevin le 2026-10-29) ; le serial vient de ANDROID_SERIAL.
#   --brightness  : luminosité manuelle fixée pendant la session (0–255, défaut 128) puis rendue.
#
# PROTOCOLE (S24 = téléphone PERSONNEL de Kevin ; QA bornée à 30–45 min) :
#  1. Ne pas déranger activé (le script refuse sinon). Écran déverrouillé, sans appel en cours.
#  2. Avant chaque tap/swipe adb : le focus doit être sur l'appli (sinon arrêt net, aucun tap).
#  3. Sauvegarde de Kevin (files/save.json, save.json.bak, save.json.corrupt) copiée avant, puis
#     comparée (sha256) à la fin ; restaurée à l'identique si elle diffère. Les départs de
#     débogage n'écrivent jamais la sauvegarde (sauf la clé « autosave », absente ici).
#  4. Batterie/température : séances comparables seulement à conditions égales. Branché (USB) :
#     on relève la température et la cadence, PAS la consommation. Sur batterie (débogage sans
#     fil) : niveau et « Charge counter » (µAh) au début et à la fin. Luminosité fixée, Wi-Fi
#     inchangé, téléphone au repos 5 min avant (température de départ < 32 °C, sinon attendre).
#  5. Fin : débogage retiré (debug_start.json supprimé), luminosité rendue, appli arrêtée.
# Sortie : build/qa/profile_s24/<horodatage>/ (resume.md, mem.csv, <profil>.log, perf-*.txt).
set -uo pipefail
cd "$(dirname "$0")/.."
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
export ADB
PKG="dev.kevin.kanto2026"

CHECK=0; BUILD=1; SCALE=1; PROFILES="exterieur,ville,donjon,combat,stockage,rp091,rp093"
BRIGHT=128; POWER=""; OUT=""; NO_DND=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK=1 ;;
    --allow-no-dnd) NO_DND=1 ;;
    --no-build) BUILD=0 ;;
    --scale) SCALE="$2"; shift ;;
    --profiles) PROFILES="$2"; shift ;;
    --brightness) BRIGHT="$2"; shift ;;
    --power) POWER="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac; shift
done

die() { echo "ARRÊT : $*" >&2; exit 1; }
SERIAL=$(tools/s24_serial.sh) || exit 1
A() { "$ADB" -s "$SERIAL" "$@"; }
sh_() { A shell "$@" | tr -d '\r'; }
secs() { awk -v s="$1" -v k="$SCALE" 'BEGIN { printf "%d", s * k + 0.5 }'; }

# --- Protocole -------------------------------------------------------------------------------
ZEN=$(sh_ settings get global zen_mode)
[[ "$ZEN" =~ ^[1-3]$ || $NO_DND == 1 ]] || die "Ne pas déranger est désactivé (zen_mode=$ZEN). Activer le mode DND sur le S24."
WAKE=$(sh_ dumpsys power | grep -o "mWakefulness=[A-Za-z]*" | head -1)
[[ "$WAKE" == "mWakefulness=Awake" ]] || die "Écran éteint ($WAKE) : réveiller et déverrouiller le S24."
[[ "$(sh_ dumpsys window)" =~ (mDreamingLockscreen=true|isStatusBarKeyguard=true|mShowingLockscreen=true) ]] \
  && die "Écran verrouillé : déverrouiller le S24."
[[ $BUILD == 1 || "$(sh_ pm list packages --user 0 2>/dev/null)" == *"package:$PKG"* ]] || die "APK absent du téléphone (lancer sans --no-build)."
batt() { sh_ dumpsys battery | awk -F': *' -v k="$1" '$1 ~ "^ *" k "$" {print $2; exit}'; }
USB=$(batt "USB powered"); AC=$(batt "AC powered")
if [[ "$USB" == true || "$AC" == true ]]; then POWER_NOW=usb; else POWER_NOW=battery; fi
[[ -z "$POWER" || "$POWER" == "$POWER_NOW" ]] || die "Alimentation déclarée '$POWER' mais lue '$POWER_NOW'."
T0=$(batt temperature)
echo "S24 $SERIAL | DND=$ZEN | alim=$POWER_NOW | batterie=$(batt level)% | temp=$(awk -v t="$T0" 'BEGIN{print t/10}') °C"
# Sauvegarde lisible ? (n'écrit rien)
[[ $BUILD == 1 ]] || A shell "run-as $PKG ls files" >/dev/null 2>&1 || die "run-as impossible (APK non debug ?)."
if [[ $CHECK == 1 ]]; then echo "Protocole OK (--check : rien lancé)."; exit 0; fi

STAMP=$(date +%Y%m%d-%H%M%S)
OUT="${OUT:-build/qa/profile_s24/$STAMP}"
mkdir -p "$OUT/save_backup"

# Installation avant la copie de sauvegarde (install -r conserve les données).
if [[ $BUILD == 1 ]]; then
  tools/build_android.sh >/dev/null || die "Build impossible."
  A install -r build/kanto2026-debug.apk | tail -1
fi

# --- Sauvegarde de Kevin : copie + empreinte, restauration à la sortie ------------------------
SAVE_FILES="save.json save.json.bak save.json.corrupt"
for f in $SAVE_FILES; do
  if A shell "run-as $PKG test -f files/$f" >/dev/null 2>&1; then
    A exec-out "run-as $PKG cat files/$f" > "$OUT/save_backup/$f"
    shasum -a 256 "$OUT/save_backup/$f" | awk '{print $1}' > "$OUT/save_backup/$f.sha256"
  fi
done
echo "Sauvegarde copiée : $(ls "$OUT/save_backup" | grep -vc sha256) fichier(s) dans $OUT/save_backup"

OLD_BRIGHT=$(sh_ settings get system screen_brightness)
OLD_BRIGHT_MODE=$(sh_ settings get system screen_brightness_mode)
BG_PID=""
cleanup() {
  [[ -n "$BG_PID" ]] && kill "$BG_PID" 2>/dev/null
  A shell am force-stop "$PKG" >/dev/null 2>&1
  A shell "run-as $PKG rm -f files/debug_start.json files/debug_unlocks.json files/perf_probe.json" >/dev/null 2>&1
  A shell settings put system screen_brightness "$OLD_BRIGHT" >/dev/null 2>&1
  A shell settings put system screen_brightness_mode "$OLD_BRIGHT_MODE" >/dev/null 2>&1
  local f now bad=0
  for f in $SAVE_FILES; do
    if [[ -f "$OUT/save_backup/$f" ]]; then
      now=$(A exec-out "run-as $PKG cat files/$f" 2>/dev/null | shasum -a 256 | awk '{print $1}')
      if [[ "$now" != "$(cat "$OUT/save_backup/$f.sha256")" ]]; then
        echo "Sauvegarde $f modifiée : restauration." >&2
        A shell "run-as $PKG sh -c 'cat > files/$f'" < "$OUT/save_backup/$f"; bad=1
      fi
    elif A shell "run-as $PKG test -f files/$f" >/dev/null 2>&1; then
      echo "Fichier $f créé pendant la session (absent avant) : supprimé." >&2
      A shell "run-as $PKG rm -f files/$f"; bad=1
    fi
  done
  echo "Sauvegarde de Kevin : $([[ $bad == 0 ]] && echo identique || echo restaurée)." | tee -a "$OUT/resume.md"
}
trap cleanup EXIT

A shell settings put system screen_brightness_mode 0
A shell settings put system screen_brightness "$BRIGHT"

# --- Outils de pilotage ---------------------------------------------------------------------
JOY_X=330; JOY_Y=800       # centre du joystick (écran 2340×1080, à confirmer par capture)
ACT_X=2150; ACT_Y=720      # bouton EXAMINER/action (capture A17 22:04)
DLG_X=1170; DLG_Y=930      # boîte de dialogue (avance)
ATK_X=1732; ATK_Y=807      # ATTAQUER en combat
MOVE_X=1404; MOVE_Y=960    # 3e capacité (menu des capacités)

online() { [[ "$(A get-state 2>/dev/null | tr -d '\r')" == device ]] || die "Téléphone hors ligne (câble ?). Arrêt, sauvegarde vérifiée à la sortie."; }
focus_ok() { [[ "$(sh_ dumpsys window | grep -m1 mCurrentFocus)" == *"$PKG"* ]]; }
need_focus() { online; focus_ok || die "Le focus n'est plus sur l'appli (appel, notification, geste de Kevin ?). Aucun tap envoyé."; }
tap() { need_focus; A shell input tap "$1" "$2"; }
hold() { need_focus; A shell input swipe "$1" "$2" "$1" "$2" "$3"; }   # appui long (ms)
walk() {  # walk haut|bas|gauche|droite durée_ms
  need_focus
  local dx=0 dy=0
  case "$1" in haut) dy=-120 ;; bas) dy=120 ;; gauche) dx=-120 ;; droite) dx=120 ;; esac
  A shell input swipe "$JOY_X" "$JOY_Y" "$((JOY_X + dx))" "$((JOY_Y + dy))" "$2"
}
shot() { A exec-out screencap -p > "$OUT/$1.png"; }

launch() {  # launch départ_de_débogage
  online
  [[ -f "tools/debug_start/$1.json" ]] || die "Départ inconnu : $1"
  A shell am force-stop "$PKG"
  A shell "run-as $PKG sh -c 'mkdir -p files && cat > files/debug_start.json'" < "tools/debug_start/$1.json"
  A logcat -c
  A shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  CUR_START="$1"; echo "$1" > "$OUT/current_label"
}

# Échantillonneur de fond : toutes les 20 s, mémoire (PSS, graphique, natif), température,
# niveau, charge. Une ligne par relevé, étiquetée par le profil en cours (current_label).
echo "t_s,epoch,label,pss_kb,graphics_kb,native_kb,temp_dC,level,charge_uAh" > "$OUT/mem.csv"
sampler() {
  local t0 now mem
  t0=$(date +%s)
  while true; do
    now=$(date +%s)
    mem=$("$ADB" -s "$SERIAL" shell dumpsys meminfo "$PKG" 2>/dev/null | tr -d '\r')
    echo "$((now - t0)),$now,$(cat "$OUT/current_label" 2>/dev/null)," \
"$(echo "$mem" | awk '/TOTAL PSS:/ {print $3; exit}')," \
"$(echo "$mem" | awk '/^ *Graphics:/ {print $2; exit}')," \
"$(echo "$mem" | awk '/Native Heap:/ {print $3; exit}')," \
"$("$ADB" -s "$SERIAL" shell dumpsys battery | tr -d '\r' | awk -F': *' '$1 ~ /^ *temperature$/ {t=$2} $1 ~ /^ *level$/ {l=$2} $1 ~ /Charge counter/ {c=$2} END {print t "," l "," c}')" \
      | tr -d ' ' >> "$OUT/mem.csv"
    sleep 20
  done
}
sampler & BG_PID=$!

collect() {  # collect profil : journal Godot depuis le lancement
  A logcat -v epoch -d -s godot:V > "$OUT/$1.log"
  grep '\[perf\]' "$OUT/$1.log" > "$OUT/perf-$1.txt" || true
}

summary_perf() {  # summary_perf profil [lignes à ignorer au début]
  awk -v n="$1" -v skip="${2:-3}" '
    /\[perf\]/ { c++; if (c <= skip) next
      for (i = 1; i <= NF; i++) {
        split($i, kv, "=")
        if (kv[1] == "fps") { f = kv[2]; sf += f; k++; if (f < 55) low++ }
        if (kv[1] == "min") { if (mn == "" || kv[2] < mn) mn = kv[2] }
        if (kv[1] == "draw") { if (kv[2] > dr) dr = kv[2] }
        if (kv[1] == "tex") { if (kv[2] > tx) tx = kv[2]; last = kv[2] }
      } }
    END { if (k) printf "| %s | %.1f | %s | %d/%d | %s | %s | %s |\n", n, sf / k, mn, low + 0, k, dr, tx, last
          else printf "| %s | (aucune ligne [perf]) | | | | | |\n", n }' "$OUT/perf-$1.txt"
}

RES="$OUT/resume.md"
{
  echo "# Profilage S24 — $STAMP"
  echo
  echo "- Commit : $(git rev-parse --short HEAD), alim. $POWER_NOW, luminosité $BRIGHT (manuelle), DND=$ZEN"
  echo "- Début : batterie $(batt level) %, température $(awk -v t="$T0" 'BEGIN{print t/10}') °C, charge $(batt 'Charge counter') µAh"
  echo
  echo "| Profil | fps moyen | min (image la + lente) | fenêtres < 55 fps | draw max | tex max (Mo) | tex fin (Mo) |"
  echo "|---|---|---|---|---|---|---|"
} > "$RES"

run_walk_profile() {  # run_walk_profile nom départ durée_s
  local name="$1" start="$2" dur
  dur=$(secs "$3")
  echo ">>> $name ($start, ${dur}s)"
  launch "$start"; echo "$name" > "$OUT/current_label"
  sleep 12
  shot "$name-debut"
  local end=$(( $(date +%s) + dur ))
  local dirs=(gauche droite haut bas) i=0
  while [[ $(date +%s) -lt $end ]]; do
    walk "${dirs[$((i % 4))]}" 1500; i=$((i + 1)); sleep 1
  done
  shot "$name-fin"
  collect "$name"; summary_perf "$name" >> "$RES"
}

in_battle() {  # vrai si le bouton ATTAQUER (rouge) est à l'écran
  A exec-out screencap -p > "$OUT/.s.png"
  python3 -c "
import sys
from PIL import Image
r, g, b = Image.open('$OUT/.s.png').convert('RGB').getpixel(($ATK_X - 60, $ATK_Y))
sys.exit(0 if r > 190 and g < 100 and b < 100 else 1)"
}

profile_combat() {
  local dur; dur=$(secs 150)
  echo ">>> combat (route_5_pay_day, rencontre forcée, <= ${dur}s)"
  launch route_5_pay_day; echo combat > "$OUT/current_label"
  sleep 12
  local i entered=0 end=$(( $(date +%s) + dur ))
  for i in 1 2 3 4 5 6; do walk bas 700; sleep 0.8; done
  for i in 1 2 3 4 5 6 7 8; do walk droite 700; sleep 0.8; done
  while [[ $(date +%s) -lt $end ]]; do
    walk gauche 700; sleep 0.9; walk droite 700; sleep 0.9
    if in_battle; then entered=1; break; fi
  done
  if [[ $entered == 1 ]]; then
    echo "Combat détecté ; 1re attaque pour RP-263"
    sleep 6; shot combat-entree
    tap "$ATK_X" "$ATK_Y"; sleep 2; shot combat-capacites
    tap "$MOVE_X" "$MOVE_Y"; sleep 10; shot combat-apres-attaque
  else
    echo "Aucun combat déclenché dans le temps imparti"; shot combat-aucun
  fi
  collect combat; summary_perf combat 3 >> "$RES"
  {
    echo "RP-261 / RP-263 : fenêtres [perf] de la fin du journal (epoch, fps, min, draw, tex) :"
    grep '\[perf\]' "$OUT/combat.log" | tail -22 | sed 's/^ *//' | awk '{print "    " $1, $7, $8, $9, $10, $11}'
  } > "$OUT/combat-rp261.txt"
}

profile_stockage() {
  local dur; dur=$(secs 40)
  echo ">>> stockage (storage_qa)"
  launch storage_qa; echo stockage > "$OUT/current_label"
  sleep 12
  tap "$ACT_X" "$ACT_Y"; sleep 2.5; tap "$DLG_X" "$DLG_Y"; sleep 3; shot stockage-1
  sleep "$dur"
  shot stockage-2
  collect stockage; summary_perf stockage 3 >> "$RES"
  grep '\[perf\]' "$OUT/stockage.log" | tail -26 | sed 's/^ *//' | awk '{print "    " $1, $7, $8, $9, $10, $11}' > "$OUT/stockage-ouverture.txt"
}

profile_maps() {  # profile_maps étiquette départ…  : mémoire des textures carte par carte
  local label="$1"; shift
  local m
  echo "" >> "$RES"; echo "### $label — textures par carte (après 12 s, 3 relevés [perf])" >> "$RES"
  echo "| Départ | fps | min | draw | tex (Mo) |" >> "$RES"; echo "|---|---|---|---|---|" >> "$RES"
  for m in "$@"; do
    launch "$m"; sleep "$(secs 14)"
    collect "map-$m"
    awk -v n="$m" '/\[perf\]/ { l = $0 } END {
        gsub(/.*\[perf\] /, "", l); split(l, a, " ")
        printf "| %s | %s | %s | %s | %s |\n", n, substr(a[1],5), substr(a[2],5), substr(a[3],6), substr(a[4],5) }' \
      "$OUT/perf-map-$m.txt" >> "$RES"
  done
}

for P in ${PROFILES//,/ }; do
  case "$P" in
    exterieur) run_walk_profile exterieur route_6 150 ;;
    ville)
      run_walk_profile ville-celadopole celadon 100
      run_walk_profile ville-safrania saffron_free 100 ;;
    donjon)
      run_walk_profile donjon-azuree cerulean_cave_1f 100
      run_walk_profile donjon-grotte-sombre dark_cave_b1f 80 ;;
    combat) profile_combat ;;
    stockage) profile_stockage ;;
    rp093) run_walk_profile rp093-quai-carmin vermilion_dock 90 ;;
    rp091) profile_maps "RP-091" pallet_town route_1 pewter route_2 celadon saffron_free route_11 \
             vermilion cerulean_city mt_moon_b1f silph_11f cerulean_cave_1f indigo_plateau j25_manoir_b1f ;;
    *) echo "Profil inconnu : $P" >&2 ;;
  esac
done

# --- Fin ------------------------------------------------------------------------------------
{
  echo
  echo "- Fin : batterie $(batt level) %, température $(awk -v t="$(batt temperature)" 'BEGIN{print t/10}') °C, charge $(batt 'Charge counter') µAh"
  echo "- Mémoire (mem.csv) : PSS max $(awk -F, 'NR>1 && $4+0>m {m=$4} END {printf "%.0f Mo", m/1024}' "$OUT/mem.csv"), natif max $(awk -F, 'NR>1 && $6+0>m {m=$6} END {printf "%.0f Mo", m/1024}' "$OUT/mem.csv")"
} >> "$RES"
echo "Résumé : $RES"
