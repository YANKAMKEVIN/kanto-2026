#!/usr/bin/env python3
"""Prépare SEULEMENT les entrées d'une série (celles que `serieNN.manifeste_donnees()` fournit), sans
relire les sources des séries précédentes.

`preparer.py` relance tout le manifeste : il exige toutes les images sources de toutes les séries
(`build/art/` complet, non versionné). Ce lanceur charge le catalogue existant, ne traite que les
entrées de la série (mêmes méthodes de `Preparateur`, donc mêmes résultats) et réécrit le catalogue
(ordre conservé, nouvelles entrées à la fin).

Usage : tools/art/preparer_serie.py serie17 [--source DOSSIER]
"""
from __future__ import annotations

import importlib
import json
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import preparer  # noqa: E402


def main() -> None:
	nom = sys.argv[1]
	source = Path(sys.argv[sys.argv.index("--source") + 1]) if "--source" in sys.argv else (
		preparer.RACINE / "build" / "art")
	serie = importlib.import_module(nom)
	serie.ART = source
	complet = json.loads((ICI / "manifeste.json").read_text())
	donnees = serie.manifeste_donnees()
	partiel = {cle: valeur for cle, valeur in complet.items() if not isinstance(valeur, list)}
	partiel.update({section: [] for section in complet if isinstance(complet[section], list)})
	for section, entrees in donnees.items():
		cles = {serie._cle(e) for e in entrees}
		partiel[section] = [e for e in complet.get(section, []) if serie._cle(e) in cles]
	p = preparer.Preparateur(partiel, source)
	chemin = preparer.RACINE / "assets" / "world" / "catalogue.json"
	p.catalogue = json.loads(chemin.read_text())
	p.objets()
	p.planches_objets()
	p.effets()
	p.pieces()
	p.sols()
	p.personnages()
	p.attentes()
	p.ecrire_catalogue()
	preparer.reglages_import(partiel)


if __name__ == "__main__":
	main()
