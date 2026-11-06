#!/usr/bin/env python3
"""Médium masculin dans le monde (`psychic`, RP-147) : planche de marche d'après son art de combat.

Écrit `tools/art/prompts/medium/PNJ_MEDIUM_NE.txt`. Images jointes : le héros validé, puis
`medium.webp` en PNG. Usage : python3 tools/art/medium_monde.py
"""
from pathlib import Path

from serie12 import MODELE_MARCHE

ICI = Path(__file__).resolve().parent
REF = (" ; MEDIUM_COMBAT (image jointe 2) = le MÊME personnage peint pour l'écran de combat : sa tenue, sa "
	"coiffure, sa carrure et ses couleurs font foi (son rendu détaillé et sa pose sont à NE PAS copier : "
	"dans le monde il est chibi comme le héros)")
TENUE = ("un MÉDIUM, jeune homme mince et grave : cheveux noirs mi-longs en mèches, une mèche sur l'œil "
	"droit ; longue TUNIQUE PRUNE à col montant et larges manches, liserés dorés au col, au devant et au bas ; "
	"large ceinture nouée mauve dont le pan retombe devant ; pantalon bouffant brun très sombre ; bottines "
	"brun foncé. Taille d'un adulte. Aucun insigne, aucun texte.")


def main() -> None:
	sortie = ICI / "prompts" / "medium" / "PNJ_MEDIUM_NE.txt"
	sortie.write_text(MODELE_MARCHE.format(ident="PNJ_MEDIUM", ref=REF, tenue=TENUE), encoding="utf-8")


if __name__ == "__main__":
	main()
