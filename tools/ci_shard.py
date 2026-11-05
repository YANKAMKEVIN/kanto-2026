#!/usr/bin/env python3
"""Répartit les scripts de test entre les lots de la CI, d'après leur durée mesurée.

Usage : tools/ci_shard.py <lot> <nombre de lots>   (un chemin par ligne)
        tools/ci_shard.py --update <dossier>       (refait tools/ci_test_times.json depuis les junit.xml)

Durées : tools/ci_test_times.json. Un script absent du fichier compte pour la durée médiane, donc un
nouveau test ne casse rien ; relancer --update quand les lots se déséquilibrent à nouveau.
"""
import json
import pathlib
import re
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TIMES = ROOT / "tools" / "ci_test_times.json"


def load_times():
    return json.loads(TIMES.read_text(encoding="utf-8")) if TIMES.exists() else {}


def shards(paths, count, times):
    """Le plus long d'abord, toujours dans le lot le moins chargé ; résultat déterministe."""
    default = statistics.median(times.values()) if times else 1.0
    load = [0.0] * count
    groups = [[] for _ in range(count)]
    for path in sorted(paths, key=lambda p: (-times.get(p, default), p)):
        index = load.index(min(load))
        groups[index].append(path)
        load[index] += times.get(path, default)
    return [sorted(group) for group in groups], load


def update(folder):
    times = {}
    pattern = re.compile(r'<testsuite name="([^"]*)"[^>]*?time="([0-9.]+)"')
    for junit in pathlib.Path(folder).rglob("junit.xml"):
        for name, seconds in pattern.findall(junit.read_text(encoding="utf-8", errors="replace")):
            match = re.search(r"tests/.*?\.gd", name)
            if match:
                times[match.group(0)] = round(times.get(match.group(0), 0.0) + float(seconds), 1)
    if not times:
        sys.exit("Aucune durée trouvée")
    TIMES.write_text(json.dumps(times, indent=0, sort_keys=True) + "\n", encoding="utf-8")
    print(f"{len(times)} scripts, {sum(times.values()) / 60:.1f} min au total")


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--update":
        update(sys.argv[2])
        return
    shard, count = int(sys.argv[1]), int(sys.argv[2])
    paths = [p.relative_to(ROOT).as_posix() for p in (ROOT / "tests").rglob("test_*.gd")]
    print("\n".join(shards(paths, count, load_times())[0][shard]))


if __name__ == "__main__":
    main()
