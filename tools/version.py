#!/usr/bin/env python3
"""Source unique de la version du jeu (J34 T1).

La version vit dans `project.godot` (`application/config/version`, forme `MAJEUR.MINEUR.CORRECTIF`).
Le code Android (`versionCode`, entier strictement croissant exigé par Android pour une mise à jour
par-dessus) en est dérivé : `MAJEUR × 10000 + MINEUR × 100 + CORRECTIF` (0.34.0 → 3400 ; il dépasse
le code 33 de la version de référence 0.33.0 du J33). Les presets d'export (`export_presets.cfg`)
recopient ces deux valeurs : ce script les écrit et vérifie qu'ils ne divergent pas.

Usage :
  tools/version.py show            affiche la version et le code
  tools/version.py check           vérifie project.godot et export_presets.cfg (sortie 1 si écart)
  tools/version.py set 0.34.1      écrit la nouvelle version partout
  tools/version.py json            {"version": …, "code": …, "name": …} pour le manifeste de build
"""
from __future__ import annotations

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = os.path.join(ROOT, "project.godot")
PRESETS = os.path.join(ROOT, "export_presets.cfg")
VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def version_code(version: str) -> int:
    m = VERSION_RE.match(version)
    if not m:
        sys.exit(f"Version invalide « {version} » (attendu MAJEUR.MINEUR.CORRECTIF)")
    major, minor, patch = (int(x) for x in m.groups())
    if minor > 99 or patch > 99:
        sys.exit("MINEUR et CORRECTIF doivent rester inférieurs à 100 (le code Android en dépend)")
    return major * 10000 + minor * 100 + patch


def read(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path: str, text: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def project_values() -> tuple[str, str]:
    text = read(PROJECT)
    version = re.search(r'^config/version="([^"]*)"', text, re.M)
    name = re.search(r'^config/name="([^"]*)"', text, re.M)
    if not version or not name:
        sys.exit("config/version ou config/name introuvable dans project.godot")
    return version.group(1), name.group(1)


# Clés des presets qui recopient la version : (expression, formateur).
PRESET_KEYS = [
    (r"^version/name=.*$", lambda v, c: f'version/name="{v}"'),  # Android
    (r"^version/code=.*$", lambda v, c: f"version/code={c}"),  # Android
    (r"^application/short_version=.*$", lambda v, c: f'application/short_version="{v}"'),  # iOS
    (r"^application/version=.*$", lambda v, c: f'application/version="{c}"'),  # iOS
]


def check() -> int:
    version, name = project_values()
    code = version_code(version)
    presets = read(PRESETS)
    errors: list[str] = []
    for pattern, fmt in PRESET_KEYS:
        expected = fmt(version, code)
        found = re.findall(pattern, presets, re.M)
        if not found:
            errors.append(f"clé absente de export_presets.cfg : {expected}")
        for line in found:
            if line != expected:
                errors.append(f"export_presets.cfg : « {line} » ≠ « {expected} »")
    package_names = re.findall(r'^package/name="([^"]*)"$', presets, re.M)
    for package_name in package_names:
        if package_name != name:
            errors.append(f"package/name « {package_name} » ≠ config/name « {name} »")
    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        print("Corrige avec : tools/version.py set " + version, file=sys.stderr)
        return 1
    print(f"Version {version}, code {code}, nom « {name} » : cohérents")
    return 0


def set_version(version: str) -> None:
    code = version_code(version)
    project = read(PROJECT)
    project, n = re.subn(r'^config/version="[^"]*"', f'config/version="{version}"', project, flags=re.M)
    if n != 1:
        sys.exit("config/version doit apparaître une fois dans project.godot")
    write(PROJECT, project)
    presets = read(PRESETS)
    for pattern, fmt in PRESET_KEYS:
        presets = re.sub(pattern, fmt(version, code), presets, flags=re.M)
    write(PRESETS, presets)
    print(f"Version {version}, code {code} écrits dans project.godot et export_presets.cfg")


def main(argv: list[str]) -> int:
    command = argv[1] if len(argv) > 1 else "show"
    if command == "show":
        version, name = project_values()
        print(f"{version} (code {version_code(version)}) — {name}")
        return 0
    if command == "json":
        version, name = project_values()
        print(json.dumps({"version": version, "code": version_code(version), "name": name}))
        return 0
    if command == "check":
        return check()
    if command == "set" and len(argv) == 3:
        set_version(argv[2])
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
