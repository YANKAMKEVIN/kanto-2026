#!/usr/bin/env python3
"""Art PROVISOIRE de l'Arène de Safrania et du Dojo de Combat (jalon 27, T6) : enveloppes
dessinées d'après les grilles `tools/plans/safrania_arene.txt` et `safrania_dojo.txt`, aux
dimensions finales (cases × 96 px). Remplacer par l'art définitif = changer les images (mêmes
noms, mêmes dimensions), pas les cartes.

  python3 tools/art/placeholders_safrania_arene.py

Réutilise le dessin des enveloppes de la Sylphe (`placeholders_sylphe.enveloppe` : murs à face
visible, tapis de téléportation `T` en disque violet et cyan, sortie `E`), avec un sol propre :
dalles mauves pour l'Arène Psy, tatami pour le Dojo.

Écrit dans `assets/world/interiors/placeholder/` : `ph_saffron_gym.png` (1920 × 1728) et
`ph_fighting_dojo.png` (960 × 1152).
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import placeholders_sylphe as ph  # noqa: E402

CARTES = {
	"saffron_gym": ("safrania_arene", (176, 160, 204), (166, 150, 196), (92, 74, 128)),
	"fighting_dojo": ("safrania_dojo", (214, 196, 148), (204, 186, 138), (120, 84, 52)),
}


def main() -> None:
	ph.SORTIE.mkdir(parents=True, exist_ok=True)
	for carte, (plan, sol_a, sol_b, mur) in CARTES.items():
		ph.SOL_A, ph.SOL_B, ph.MUR = sol_a, sol_b, mur
		image = ph.enveloppe(plan)
		image.save(ph.SORTIE / ("ph_%s.png" % carte))
		print("ph_%s.png" % carte, image.size)


if __name__ == "__main__":
	main()
