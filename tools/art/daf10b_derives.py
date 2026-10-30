#!/usr/bin/env python3
"""Lot DAF.10b, images **dérivées** du kit peint existant (sans Codex ; consigne de Kevin du
2026-10-30 : « lance tout ce que tu peux faire sans codex »). Fiche : `fiches-assets/daf-10b/fiche.md`.

- Enveloppes des postes, recomposées à partir de l'enveloppe validée de la maison d'Argenta
  (`int_maison_argenta_coque`, 15 × 10 : celle du 2F du poste de la Route 12) et des ouvertures de
  l'enveloppe des postes de la Forêt de Jade (`int_poste_foret_coque`, 1F du poste de la Route 12) :
  - `int_poste_traversant_coque` (12 × 10) : 1F des postes 15 et 18, ouvertures ouest et est
    (rangées 5 et 6), mur du bas sans porte ;
  - `int_poste_etage_coque` (12 × 10) : 2F du poste 15, fermé, deux fenêtres ;
  - `int_poste_16_coque` (14 × 10) : deux couloirs séparés par un mur, ouvertures nord et sud aux
    colonnes 2-3 et 10-11.
- Façade du poste traversant est-ouest (`bldg_poste_traversant_01`, 8 × 9) : moitié ouest du poste
  ouest de Safrania et moitié est du poste est (ouvertures latérales), toit prolongé au milieu,
  étirée à la profondeur du bâtiment de la grille.
Les images neuves de `daf10b.py` (Codex) les remplaceront si Kevin le demande.

  python3 tools/art/daf10b_derives.py      (écrit dans assets/, met le catalogue à jour)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import daf3  # noqa: E402
from daf3 import CASE, RACINE  # noqa: E402

_I = "assets/world/interiors/"
_B = "assets/world/buildings/"
ARGENTA = RACINE / _I / "int_maison_argenta_coque.png"
FORET = RACINE / _I / "int_poste_foret_coque.png"
OUEST = RACINE / _B / "bldg_poste_safrania_ouest_01.png"
EST = RACINE / _B / "bldg_poste_safrania_est_01.png"

## Enveloppe d'Argenta (1440 × 960) : bas du mur du fond / haut du sol, haut du mur du bas, pilastres
## du mur du fond, porte du mur du bas (poteaux compris), paillasson.
SOL_HAUT = 205
MUR_BAS = 765
PILASTRE_1 = (555, 600)
PILASTRE_2 = (835, 888)
PORTE_BAS = (535, 905)
PAILLASSON = (630, 830, 810, 900)
## Enveloppe de la Forêt de Jade (960 × 768) : ouverture du mur du fond (piliers compris).
OUVERTURE_HAUT = (340, 0, 620, 180)
## Agrandissement de la façade du poste traversant (largeur composée = 8 cases / échelle).
ECHELLE_FACADE = 1.4


def _sans_porte(source: Image.Image, largeur: int) -> Image.Image:
	"""Bande du mur du bas (y MUR_BAS → bas) de [largeur] px, sans porte : bouts gauche et droit
	d'Argenta, mur plein répété au milieu."""
	bande = source.crop((0, MUR_BAS, source.width, source.height))
	gauche = bande.crop((0, 0, PORTE_BAS[0], bande.height))
	droite = bande.crop((PORTE_BAS[1], 0, bande.width, bande.height))
	plein = bande.crop((120, 0, 480, bande.height))
	sortie = Image.new("RGB", (largeur, bande.height))
	reste = largeur - gauche.width - droite.width
	x = gauche.width
	while reste > 0:
		morceau = plein.crop((0, 0, min(plein.width, reste), plein.height))
		sortie.paste(morceau, (x, 0))
		x += morceau.width
		reste -= morceau.width
	if largeur < gauche.width + droite.width:
		gauche = gauche.crop((0, 0, largeur // 2, bande.height))
		droite = droite.crop((droite.width - (largeur - largeur // 2), 0, droite.width, bande.height))
	sortie.paste(gauche, (0, 0))
	sortie.paste(droite, (largeur - droite.width, 0))
	return sortie


def _piece(source: Image.Image, colonnes: int) -> Image.Image:
	"""Argenta ramenée à [colonnes] cases : on retire une tranche du mur du fond et du sol entre
	les deux pilastres (côté droit du premier), le mur du bas est refait sans porte."""
	largeur = colonnes * CASE
	coupe = source.width - largeur
	gauche = source.crop((0, 0, PILASTRE_1[1], source.height))
	droite = source.crop((PILASTRE_1[1] + coupe, 0, source.width, source.height))
	sortie = Image.new("RGB", (largeur, source.height))
	sortie.paste(gauche, (0, 0))
	sortie.paste(droite, (gauche.width, 0))
	sortie.paste(_sans_porte(source, largeur), (0, MUR_BAS))
	return sortie


def _ouverture_laterale(image: Image.Image, source: Image.Image, cote: str, rangees: tuple[int, int]) -> None:
	"""Passage ouvert dans le mur latéral [cote] sur [rangees] (incluses) : le parquet prolongé
	jusqu'au bord, un paillasson tourné posé sur la première colonne du sol."""
	y0, y1 = rangees[0] * CASE, (rangees[1] + 1) * CASE
	sol = image.crop((CASE + 40, y0, 2 * CASE + 40, y1))
	tapis = source.crop(PAILLASSON).rotate(90, expand=True).resize((60, y1 - y0 - 24))
	if cote == "ouest":
		image.paste(sol, (0, y0))
		image.paste(tapis, (CASE + 12, y0 + 12))
	else:
		image.paste(sol.transpose(Image.FLIP_LEFT_RIGHT), (image.width - CASE, y0))
		image.paste(tapis, (image.width - CASE - 72, y0 + 12))


def coque_traversant(source: Image.Image) -> Image.Image:
	image = _piece(source, 12)
	for cote in ("ouest", "est"):
		_ouverture_laterale(image, source, cote, (5, 6))
	return image


def coque_etage(source: Image.Image) -> Image.Image:
	return _piece(source, 12)


def coque_16(source: Image.Image, foret: Image.Image) -> Image.Image:
	image = _piece(source, 14)
	# Mur de séparation (rangée 4) : la bande du mur du bas, ramenée à une case.
	bande = _sans_porte(source, image.width).resize((image.width, CASE), Image.LANCZOS)
	image.paste(bande, (0, 4 * CASE))
	# Fenêtres du mur du fond recouvertes d'enduit (les ouvertures prennent leur place).
	enduit = source.crop((120, 40, 280, 200))
	for x in (300, 884):
		image.paste(enduit, (x, 40))
	ouverture = foret.crop(OUVERTURE_HAUT).resize((2 * CASE + 40, SOL_HAUT), Image.LANCZOS)
	porte = source.crop((PORTE_BAS[0], MUR_BAS, PORTE_BAS[1], source.height))
	for colonne in (2, 10):
		centre = (colonne + 1) * CASE
		image.paste(ouverture, (centre - ouverture.width // 2, 0))
		image.paste(porte, (centre - porte.width // 2, MUR_BAS))
	return image


def facade_traversant() -> Image.Image:
	"""Tiers ouest du poste est de Safrania (ouverture à gauche), milieu du poste ouest répété (toit
	et fenêtres), tiers est du poste ouest (ouverture à droite), le tout agrandi de
	[constant ECHELLE_FACADE] pour faire 8 cases de large : les ouvertures tombent alors sur les
	portes de la grille (rangées 11 et 12 des Routes 15 et 18, pied à la rangée 15,2)."""
	ouest = Image.open(OUEST).convert("RGBA")
	est = Image.open(EST).convert("RGBA")
	tiers = ouest.width // 3
	largeur = round(8 * CASE / ECHELLE_FACADE)
	ligne = Image.new("RGBA", (largeur, ouest.height), (0, 0, 0, 0))
	ligne.alpha_composite(est.crop((0, 0, tiers, est.height)), (0, 0))
	milieu = ouest.crop((tiers, 0, 2 * tiers, ouest.height))
	x = tiers
	while x < largeur - tiers:
		ligne.alpha_composite(milieu.crop((0, 0, min(milieu.width, largeur - tiers - x), ouest.height)), (x, 0))
		x += milieu.width
	ligne.alpha_composite(ouest.crop((ouest.width - tiers, 0, ouest.width, ouest.height)), (largeur - tiers, 0))
	return ligne.resize((8 * CASE, round(ouest.height * 8 * CASE / largeur)), Image.LANCZOS)


def main() -> None:
	source = Image.open(ARGENTA).convert("RGB")
	foret = Image.open(FORET).convert("RGB")
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	catalogue = json.loads(catalogue_path.read_text())
	for asset, image in (("int_poste_traversant_coque", coque_traversant(source)),
			("int_poste_etage_coque", coque_etage(source)), ("int_poste_16_coque", coque_16(source, foret))):
		image.save(RACINE / _I / f"{asset}.png", optimize=True)
		catalogue["images"][asset] = {"fichier": f"res://{_I}{asset}.png", "taille": list(image.size)}
		print(f"{asset} : {image.size}")
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	facade = facade_traversant()
	daf3._ecrire_avec_ombres(facade, "bldg_poste_traversant_01", catalogue, manifeste)
	print(f"bldg_poste_traversant_01 : {facade.size}")
	catalogue_path.write_text(json.dumps(catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	main()
