#!/usr/bin/env python3
"""Rend les dos 3D d'un lot de Pokémon d'après tools/art/blender/dos_pokemon.json.

Usage : tools/art/blender/rendre_lot.py dossier_modeles dossier_sortie [n° ...] [--vues]
        [--taille 1024] [--passe profondeur]
Chaque Pokémon : blender -b --python rendre_pokemon.py -- modele images sortie/dos3d_NNN.png
avec ses options ; --vues rend les quatre vues d'orientation (dos3d_NNN_vueA.png) à la place.
"""
import json
import os
import subprocess
import sys

ICI = os.path.dirname(os.path.abspath(__file__))


def main():
	args = [a for a in sys.argv[1:] if not a.startswith("--")]
	vues = "--vues" in sys.argv
	taille = sys.argv[sys.argv.index("--taille") + 1] if "--taille" in sys.argv else "1024"
	if "--taille" in sys.argv:
		args.remove(taille)
	passe = sys.argv[sys.argv.index("--passe") + 1] if "--passe" in sys.argv else "couleur"
	if "--passe" in sys.argv:
		args.remove(passe)
	suffixe = "" if passe == "couleur" else f"_{passe}"
	modeles, sortie, numeros = args[0], args[1], args[2:]
	lot = json.load(open(os.path.join(ICI, "dos_pokemon.json"), encoding="utf-8"))
	os.makedirs(sortie, exist_ok=True)
	for num, entree in lot.items():
		if num.startswith("_") or (numeros and num not in numeros):
			continue
		cmd = ["blender", "-b", "--python", os.path.join(ICI, "rendre_pokemon.py"), "--",
			os.path.join(modeles, entree["modele"]), os.path.join(modeles, entree["images"]),
			os.path.join(sortie, f"dos3d_{num}{suffixe}.png"), "--taille", taille, "--passe", passe]
		for cle, valeur in entree.get("options", {}).items():
			cmd += [f"--{cle}", str(valeur)]
		if vues:
			cmd += ["--vues", "1"]
		r = subprocess.run(cmd, capture_output=True, text=True)
		lignes = [l for l in r.stdout.splitlines() + r.stderr.splitlines()
			if l.startswith(("RENDU", "VUES", "OS ABSENT", "TEXTURE ABSENTE", "Traceback"))
			or "Error" in l]
		print(num, entree["nom"], "→", "; ".join(lignes[-4:]) or "?")


if __name__ == "__main__":
	main()
