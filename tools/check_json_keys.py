#!/usr/bin/env python3
"""Refuse toute clé en double dans les fichiers de données JSON.

Godot garde la dernière occurrence d'une clé sans rien signaler : une fusion de branches qui
ajoute deux fois la même entrée (ex. une capacité créée par deux jalons) passerait inaperçue.
Usage : python3 tools/check_json_keys.py [dossier…]  (défaut : data et assets)
"""
import collections
import glob
import json
import sys

racines = sys.argv[1:] or ["data", "assets"]
erreurs = []
for chemin in sorted(c for r in racines for c in glob.glob(f"{r}/**/*.json", recursive=True)):
	def verifier(paires, chemin=chemin):
		compte = collections.Counter(k for k, _ in paires)
		erreurs.extend(f"{chemin} : clé « {k} » × {n}" for k, n in compte.items() if n > 1)
		return dict(paires)
	with open(chemin, encoding="utf-8") as f:
		json.load(f, object_pairs_hook=verifier)
if erreurs:
	print("\n".join(erreurs))
	sys.exit(1)
print("Aucune clé en double.")
