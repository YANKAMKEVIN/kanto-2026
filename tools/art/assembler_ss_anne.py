#!/usr/bin/env python3
"""S.S. Anne (série 17, T11) : assemble les trois tranches générées en un seul navire continu, puis
le redécoupe en trois tranches EXACTES de 10, 9 et 10 cases (96 px) : tranches `_r4`.

Pourquoi : les trois images générées n'ont pas tout à fait la même échelle ni les mêmes bords (la
proue est la retouche `_r3` de Kevin, 2026-10-15, complétée à partir du milieu ; la poupe a une
coque plus haute d'environ 25 %). L'assemblage ramène la poupe à l'échelle du milieu (× 0,8), aligne
les trois lignes de flottaison, supprime le liseré sombre des bords coupés, puis redécoupe aux
cases : les trois objets se raccordent bout à bout au pixel près, et restent trois objets séparés
(contrat du J16 : l'état « parti » retire les trois nœuds).

Usage : tools/art/assembler_ss_anne.py [--controle sortie.png]
Entrées : build/art/WORLD_BLDG_SS_ANNE_{PROUE_NE_r3,MILIEU_NE_r1,POUPE_NE_r1}.png
Sorties : build/art/WORLD_BLDG_SS_ANNE_{PROUE,MILIEU,POUPE}_NE_r4.png (lues par `serie17._revision`).
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

from PIL import Image, ImageChops

RACINE = Path(__file__).resolve().parents[2]
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
CASE = 96
CASES = (10, 9, 10)
## Réglages relevés sur les images générées (2026-10-15).
COUPE_PROUE = 1264       # colonne de la proue où elle se raccorde au milieu
DEBUT_MILIEU = 251       # colonne du milieu qui lui répond (coque unie : raccord invisible)
FIN_MILIEU = 1487 - 14   # fin du milieu (liseré du bord coupé retiré)
DEBUT_POUPE = 81         # premier pixel de la poupe
ECHELLE_POUPE = 0.8
FLOTTAISON = {"PROUE_NE_r3": 846, "MILIEU_NE_r1": 846, "POUPE_NE_r1": 939}
LISERE = 18
FONDU = 16               # fondu enchaîné milieu → poupe (px de la poupe)


def _net(image: Image.Image) -> Image.Image:
	image = image.convert("RGBA")
	alpha = image.getchannel("A").point(lambda v: 0 if v <= 32 else v)
	image.putalpha(alpha)
	return image


def assembler() -> Image.Image:
	proue = _net(Image.open(ART / "WORLD_BLDG_SS_ANNE_PROUE_NE_r3.png"))
	milieu = _net(Image.open(ART / "WORLD_BLDG_SS_ANNE_MILIEU_NE_r1.png"))
	poupe = _net(Image.open(ART / "WORLD_BLDG_SS_ANNE_POUPE_NE_r1.png"))
	poupe = poupe.resize((round(poupe.width * ECHELLE_POUPE), round(poupe.height * ECHELLE_POUPE)),
		Image.LANCZOS)
	debut = round((DEBUT_POUPE + LISERE) * ECHELLE_POUPE)
	bas_poupe = round(FLOTTAISON["POUPE_NE_r1"] * ECHELLE_POUPE)
	x_milieu = COUPE_PROUE
	x_poupe = x_milieu + (FIN_MILIEU - DEBUT_MILIEU) - FONDU
	largeur = x_poupe + poupe.width - debut
	bas = 1100
	navire = Image.new("RGBA", (largeur, 1200), (0, 0, 0, 0))
	navire.alpha_composite(proue.crop((0, 0, COUPE_PROUE, 1024)), (0, bas - FLOTTAISON["PROUE_NE_r3"]))
	navire.alpha_composite(milieu.crop((DEBUT_MILIEU, 0, FIN_MILIEU, 1024)),
		(x_milieu, bas - FLOTTAISON["MILIEU_NE_r1"]))
	morceau = poupe.crop((debut, 0, poupe.width, poupe.height))
	rampe = Image.linear_gradient("L").rotate(90).resize((FONDU, morceau.height))
	alpha = morceau.getchannel("A")
	masque = Image.new("L", morceau.size, 255)
	masque.paste(rampe.transpose(Image.FLIP_LEFT_RIGHT), (0, 0))
	morceau.putalpha(ImageChops.multiply(alpha, masque))
	navire.alpha_composite(morceau, (x_poupe, bas - bas_poupe))
	return navire.crop(navire.getchannel("A").getbbox())


def tranches(navire: Image.Image) -> list[Image.Image]:
	total = sum(CASES) * CASE
	echelle = total / navire.width
	navire = navire.resize((total, round(navire.height * echelle)), Image.LANCZOS)
	bords = [0]
	for cases in CASES:
		bords.append(bords[-1] + cases * CASE)
	return [navire.crop((bords[i], 0, bords[i + 1], navire.height)) for i in range(3)]


def main() -> None:
	navire = assembler()
	morceaux = tranches(navire)
	for nom, morceau in zip(("PROUE", "MILIEU", "POUPE"), morceaux):
		morceau.save(ART / f"WORLD_BLDG_SS_ANNE_{nom}_NE_r4.png")
		print(nom, morceau.size)
	if "--controle" in sys.argv:
		sortie = Path(sys.argv[sys.argv.index("--controle") + 1])
		fond = Image.new("RGBA", (sum(CASES) * CASE + 40, morceaux[0].height + 40), (120, 120, 130, 255))
		x = 20
		for morceau in morceaux:
			fond.alpha_composite(morceau, (x, 20))
			x += morceau.width
		fond.save(sortie)


if __name__ == "__main__":
	main()
