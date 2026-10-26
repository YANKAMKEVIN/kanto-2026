#!/usr/bin/env python3
"""Fond sombre de l'écran de démarrage système d'Android 12+ (DAF.7c).

Pourquoi : sans build Gradle, Godot 4.7 exporte depuis l'APK précompilé du modèle et ne régénère
pas `res/values/themes.xml` ; l'option `splash_screen/background_color` est donc ignorée. Dans ce
modèle, le thème `GodotAppSplashTheme` (v31) pointe `android:windowSplashScreenBackground` (un
attribut de type couleur) sur `@mipmap/icon_background`, une image : Android ne sait pas en tirer
une couleur et retombe sur le fond du thème DayNight, blanc en mode clair.

Ce script remplace, dans `resources.arsc` de l'APK exporté, cette référence par la couleur
littérale `boot_splash/bg_color` de `project.godot` (le fond de l'image de démarrage du jeu), puis
réaligne et re-signe l'APK avec la clé de débogage de Godot. Le motif doit apparaître une seule
fois : si un futur modèle Godot le change, le script échoue au lieu de produire un APK faux.

Usage : tools/android_splash_bg.py build/kanto2026-debug.apk
"""
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SDK = os.path.expanduser("~/Library/Android/sdk")
EDITOR_SETTINGS = os.path.expanduser("~/Library/Application Support/Godot/editor_settings-4.7.tres")

ATTR_SPLASH_BG = 0x0101062C  # android:windowSplashScreenBackground
REF_ICON_BG = 0x7F0A0001  # @mipmap/icon_background du modèle 4.7.2
TYPE_REFERENCE = 0x01
TYPE_INT_COLOR_ARGB8 = 0x1C


def build_tools() -> str:
    root = os.path.join(SDK, "build-tools")
    versions = sorted(v for v in os.listdir(root) if re.fullmatch(r"\d+\.\d+\.\d+", v))
    return os.path.join(root, versions[-1])


def splash_color() -> int:
    text = open(os.path.join(ROOT, "project.godot"), encoding="utf-8").read()
    m = re.search(r"^boot_splash/bg_color=Color\(([^)]*)\)", text, re.M)
    if not m:
        sys.exit("boot_splash/bg_color introuvable dans project.godot")
    r, g, b, a = (float(x) for x in m.group(1).split(","))
    return (round(a * 255) << 24) | (round(r * 255) << 16) | (round(g * 255) << 8) | round(b * 255)


def entry(value_type: int, data: int) -> bytes:
    # ResTable_map : name (uint32) + Res_value (size=8, res0=0, dataType, data)
    return struct.pack("<IHBBI", ATTR_SPLASH_BG, 8, 0, value_type, data)


def keystore() -> tuple[str, str, str]:
    text = open(EDITOR_SETTINGS, encoding="utf-8").read()

    def get(key: str, default: str) -> str:
        m = re.search(rf'^export/android/{key} = "([^"]*)"', text, re.M)
        return m.group(1) if m and m.group(1) else default

    return get("debug_keystore", ""), get("debug_keystore_user", "androiddebugkey"), get("debug_keystore_pass", "android")


def main() -> None:
    apk = sys.argv[1]
    color = splash_color()
    old, new = entry(TYPE_REFERENCE, REF_ICON_BG), entry(TYPE_INT_COLOR_ARGB8, color)
    tmp = tempfile.mkdtemp()
    try:
        with zipfile.ZipFile(apk) as z:
            arsc = z.read("resources.arsc")
        if arsc.count(new) == 1 and arsc.count(old) == 0:
            print(f"Fond de démarrage déjà à #{color:08X}")
            return
        if arsc.count(old) != 1:
            sys.exit(f"Motif windowSplashScreenBackground=@mipmap/icon_background trouvé {arsc.count(old)} fois (attendu : 1)")
        arsc_path = os.path.join(tmp, "resources.arsc")
        with open(arsc_path, "wb") as f:
            f.write(arsc.replace(old, new))
        unaligned = os.path.join(tmp, "unaligned.apk")
        shutil.copyfile(apk, unaligned)
        subprocess.run(["zip", "-q", "-0", unaligned, "resources.arsc"], cwd=tmp, check=True)
        tools = build_tools()
        subprocess.run([os.path.join(tools, "zipalign"), "-P", "16", "-f", "4", unaligned, apk], check=True)
        ks, alias, password = keystore()
        subprocess.run([os.path.join(tools, "apksigner"), "sign", "--ks", ks, "--ks-key-alias", alias,
                        "--ks-pass", "pass:" + password, apk], check=True)
        subprocess.run([os.path.join(tools, "apksigner"), "verify", apk], check=True)
        if os.path.exists(apk + ".idsig"):
            os.remove(apk + ".idsig")
        print(f"Fond de démarrage Android 12+ : #{color:08X}")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
