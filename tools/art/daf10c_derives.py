#!/usr/bin/env python3
"""Lot DAF.10c, images **dérivées** du kit peint existant, sous les identifiants des images Codex de
`daf10c.py` (l'outil d'image de Codex était à sa limite quotidienne le 2026-10-30) : les cartes se
construisent tout de suite et `daf10c.py --modules` remplace ensuite chaque image à l'identique (mêmes
identifiants, mêmes gabarits ; relancer les deux passes de carte). Fiche : `fiches-assets/daf-10c/fiche.md`.

Îles Écume (grotte glacée) : sol bas = roche ardoise de la Grotte Azurée, givrée ; masse = masse rocheuse
bleuie ; parois, rebords, escalier, trous, petit rocher = ceux du Mont Sélénite, de la Grotte Azurée et de la
Route Victoire, bleuis et givrés (le clair tiré vers le blanc de givre).
Centrale : sol = béton du repaire tiré vers le gris-vert ; masse = masse des bâtiments ; murs = modules
du repaire, faces vert d'eau ; machines = armoires électriques et console du repaire.

  python3 tools/art/daf10c_derives.py      (écrit dans assets/, met le catalogue à jour)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageEnhance

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
from daf3 import RACINE  # noqa: E402

_W = "assets/world/"
_G, _R, _P, _I = f"{_W}ground/", f"{_W}relief/", f"{_W}props/", f"{_W}interiors/"

GIVRE = (226, 238, 248)
ARDOISE = (70, 92, 122)
VERT_EAU = (112, 150, 140)


def _ouvrir(chemin: str) -> Image.Image:
	return Image.open(RACINE / chemin).convert("RGBA")


def _teinter(image: Image.Image, couleur: tuple[int, int, int], part: float, givre: float = 0.0,
		seuil: float = 0.55, valeur: float = 1.0) -> Image.Image:
	"""Mêle la couleur [couleur] (multipliée par la luminance) à [part] ; tire les pixels plus clairs que
	[seuil] vers le givre (jusqu'à [givre]) ; alpha gardé."""
	r, g, b, a = image.split()
	px_r, px_g, px_b = r.load(), g.load(), b.load()
	w, h = image.size
	for y in range(h):
		for x in range(w):
			vr, vg, vb = px_r[x, y], px_g[x, y], px_b[x, y]
			lum = (0.299 * vr + 0.587 * vg + 0.114 * vb) / 255.0
			tr, tg, tb = (c * lum * 1.6 for c in couleur)
			nr = vr * (1 - part) + tr * part
			ng = vg * (1 - part) + tg * part
			nb = vb * (1 - part) + tb * part
			if givre > 0.0 and lum > seuil:
				k = min(1.0, (lum - seuil) / (1.0 - seuil)) * givre
				nr, ng, nb = (n * (1 - k) + c * k for n, c in zip((nr, ng, nb), GIVRE))
			px_r[x, y] = max(0, min(255, round(nr * valeur)))
			px_g[x, y] = max(0, min(255, round(ng * valeur)))
			px_b[x, y] = max(0, min(255, round(nb * valeur)))
	return Image.merge("RGBA", (r, g, b, a))


def sols() -> None:
	glace = _ouvrir(f"{_G}ground_glace_01.png")
	bas = _teinter(_ouvrir(f"{_G}ground_azuree_bas_01.png"), ARDOISE, 0.25, 0.35, 0.62)
	bas = Image.blend(bas, glace, 0.12)
	bas.convert("RGB").save(RACINE / f"{_G}ground_ecume_bas_01.png", optimize=True)
	masse = _teinter(_ouvrir(f"{_G}ground_masse_roche_01.png"), ARDOISE, 0.55, 0.25, 0.30, 1.05)
	masse.convert("RGB").save(RACINE / f"{_G}ground_masse_glace_01.png", optimize=True)
	beton = _teinter(_ouvrir(f"{_G}ground_beton_repaire_01.png"), (150, 138, 118), 0.35, valeur=0.86)
	beton.convert("RGB").save(RACINE / f"{_G}ground_centrale_01.png", optimize=True)
	masse_c = _teinter(_ouvrir(f"{_G}ground_masse_batiment_01.png"), (90, 110, 120), 0.3)
	masse_c.convert("RGB").save(RACINE / f"{_G}ground_masse_centrale_01.png", optimize=True)
	print("sols : ground_ecume_bas_01, ground_masse_glace_01, ground_centrale_01, ground_masse_centrale_01")


## (asset, source, dossier, teinte, part, givre, seuil, contact).
OBJETS = [
	("relief_paroi_glace_01", f"{_R}relief_paroi_grotte_01.png", _R, ARDOISE, 0.45, 0.55, 0.40, 0.0),
	("relief_paroi_glace_02", f"{_R}relief_paroi_grotte_02.png", _R, ARDOISE, 0.45, 0.55, 0.40, 0.0),
	("relief_paroi_glace_05", f"{_R}relief_paroi_grotte_05.png", _R, ARDOISE, 0.45, 0.55, 0.40, 0.0),
	("relief_paroi_glace_06", f"{_R}relief_paroi_grotte_06.png", _R, ARDOISE, 0.45, 0.55, 0.40, 0.0),
	("relief_rebord_ecume_01", f"{_R}relief_rebord_azuree_01.png", _R, ARDOISE, 0.3, 0.6, 0.45, 0.0),
	("relief_rebord_ecume_cote_01", f"{_R}relief_rebord_azuree_cote_01.png", _R, ARDOISE, 0.3, 0.6, 0.45, 0.0),
	("relief_escalier_ecume_01", f"{_R}relief_escalier_azuree_01.png", _R, ARDOISE, 0.3, 0.6, 0.45, 0.0),
	("decal_trou_ecume_01", f"{_I}decal_trou_victoire_01.png", _I, ARDOISE, 0.85, 0.5, 0.45, 0.12),
	("decal_trou_ecume_bouche_01", f"{_I}decal_trou_victoire_bouche_01.png", _I, ARDOISE, 0.6, 0.5, 0.5, 0.12),
	("prop_rocher_glace_01", f"{_P}prop_rocher_grotte_01.png", _P, ARDOISE, 0.4, 0.7, 0.42, 0.12),
	*[(f"relief_mur_centrale_0{i}", f"{_R}relief_mur_repaire_0{i}.png", _R, VERT_EAU, 0.55, 0.0, 0.55, 0.0)
		for i in range(1, 6)],
	("int_transformateur_centrale_01", f"{_I}int_armoire_electrique_02.png", _I, VERT_EAU, 0.35, 0.0, 0.5, 0.12),
	("int_bobine_centrale_01", f"{_I}int_armoire_electrique_01.png", _I, VERT_EAU, 0.35, 0.0, 0.5, 0.12),
	("int_pupitre_centrale_01", f"{_I}int_console_repaire_01.png", _I, VERT_EAU, 0.35, 0.0, 0.5, 0.12),
]


def objets() -> None:
	import preparer
	manifeste = json.loads((ICI / "manifeste.json").read_text())
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ICI)
	p.catalogue = json.loads(catalogue_path.read_text())
	for asset, source, dossier, teinte, part, givre, seuil, contact in OBJETS:
		image = _teinter(_ouvrir(source), teinte, part, givre, seuil)
		if asset.startswith("relief_mur_centrale"):
			image = ImageEnhance.Contrast(image).enhance(1.08)
		p._objet(asset, f"{dossier}{asset}.png", image, False, contact)
	catalogue_path.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	sols()
	objets()
