#!/usr/bin/env python3
"""Audit en lecture seule : liste les attaques référencées par un learnset (data/pokemon/species/*.json)
et absentes de data/pokemon/moves/*.json. Lancer avec : python3 -I tools/audit_moves.py
Code de sortie : 0 si rien ne manque, 1 sinon."""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read_dir(sub):
    folder = os.path.join(ROOT, "data", "pokemon", sub)
    for name in sorted(os.listdir(folder)):
        if name.endswith(".json"):
            with open(os.path.join(folder, name), encoding="utf-8") as handle:
                yield name, json.load(handle)


def main():
    moves = set()
    for _name, data in read_dir("moves"):
        moves.update(key for key in data if not key.startswith("_"))
    missing = {}
    for name, data in read_dir("species"):
        for species, entry in data.items():
            if species.startswith("_"):
                continue
            for _level, move in entry.get("learnset", []):
                if move not in moves:
                    missing.setdefault(move, set()).add(species)
    for move in sorted(missing):
        print("%s  (%s)" % (move, ", ".join(sorted(missing[move]))))
    print("%d attaque(s) manquante(s) sur %d connues." % (len(missing), len(moves)))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
