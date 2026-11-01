#!/usr/bin/env python3
"""Chantier CO (docs/design/dossier-costumes.md, CO-5) : planches de jeu des costumes, depuis les
images générées par `generer_sprites_co.sh` (build/art/CO_<BADGE>_<VERSION>_<ASSET>_r1.png).

Mêmes réglages que le héros et la joueuse (`preparer_jr.py`) : hauteurs, nettoyage des halos,
attentes calées sur la marche, pêche découpée par `daf5_reliquats.pecher`, buste du menu par
`preparer_menu`. Sortie : assets/sprites/characters/painted/costumes/<badge>_<version>_*.
Le manifeste et le catalogue du jeu ne sont pas touchés (intégration après le J33 et le chantier
JR) : les entrées vont dans `tools/art/costumes/catalogue_co.json`, à verser au catalogue en code.
Révision retenue de chaque image : `r1`, sauf indication contraire dans `retenus.json`
({"CO_PRISME_JOUEUR_SURF": "r2"}, image régénérée après relecture).
Usage : tools/art/costumes/preparer_co.py BADGE [BADGE ...]
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
ART_DIR = ICI.parent
sys.path.insert(0, str(ART_DIR))
import daf5_reliquats  # noqa: E402
import preparer  # noqa: E402
import preparer_menu  # noqa: E402

RACINE = ART_DIR.parents[1]
ART = RACINE / "build" / "art"
_C = "assets/sprites/characters/painted/costumes/"
CATALOGUE = ICI / "catalogue_co.json"
VERSIONS = ("joueur", "joueuse")


RETENUS = json.loads((ICI / "retenus.json").read_text()) if (ICI / "retenus.json").exists() else {}


# Repli quand Codex refuse une pose à chaque essai (retenus.json : "tiree") : la planche d'attente
# est tirée de la planche de jeu déjà découpée, colonne « passage » (0) de chaque ligne, de la
# marche pour l'attente, du vélo pour l'arrêt à vélo. La course de profil refusée ("aucune") garde
# les profils de la planche de course.
TIREE_DE = {"ATTENTE": "", "VELO_ARRET": "_bike"}


class _Source:
	"""`source[ASSET]` → nom du fichier brut retenu (CO_<BADGE>_<VERSION>_<ASSET>_<rev>.png)."""

	def __init__(self, badge: str, version: str) -> None:
		self.prefixe = f"CO_{badge}_{version.upper()}_"

	def rev(self, asset: str) -> str:
		return RETENUS.get(self.prefixe + asset, "r1")

	def __getitem__(self, asset: str) -> str:
		return f"{self.prefixe}{asset}_{self.rev(asset)}.png"


def tirer_attente(marche: dict, sortie: str) -> dict:
	"""Planche d'attente 4 × 1 (bas, gauche, droite, haut) : colonne 0 de chaque ligne de la planche
	de jeu `marche` (entrée du catalogue). Rend l'entrée du catalogue de la nouvelle planche."""
	from PIL import Image
	planche = Image.open(RACINE / marche["fichier"][6:]).convert("RGBA")
	l, h = marche["cellule"]
	bande = Image.new("RGBA", (4 * l, h), (0, 0, 0, 0))
	for ligne in range(4):
		bande.paste(planche.crop((0, ligne * h, l, (ligne + 1) * h)), (ligne * l, 0))
	preparer._ecrire(bande, RACINE / sortie)
	return {"fichier": f"res://{sortie}", "cellule": [l, h], "hauteur": marche["hauteur"],
		"colonnes": 4, "lignes": 1, "ordre_colonnes": ["bas", "gauche", "droite", "haut"]}


def separer_profil(nom: str, poses: int = 4, vide: int = 48) -> str:
	"""Copie de la bande de course de profil où les poses ne se touchent plus : coupée à la colonne
	la moins remplie près de chaque frontière théorique (une tresse peut toucher le poing de la
	pose voisine), sans les miettes de la voisine, avec `vide` px transparents entre les morceaux. Rend le nom de la copie."""
	from PIL import Image, ImageChops
	bande = Image.open(ART / nom).convert("RGBA")
	alpha = bande.getchannel("A").point(lambda a: 255 if a > 24 else 0)
	largeur, hauteur = bande.size
	remplies = [sum(1 for y in range(hauteur) if alpha.getpixel((x, y))) for x in range(largeur)]
	marge = largeur // (poses * 6)
	coupes = [0]
	for k in range(1, poses):
		centre = largeur * k // poses
		coupes.append(min(range(centre - marge, centre + marge), key=lambda x: remplies[x]))
	coupes.append(largeur)
	separee = Image.new("RGBA", (largeur + vide * (poses - 1), hauteur), (0, 0, 0, 0))
	for k in range(poses):
		morceau = bande.crop((coupes[k], 0, coupes[k + 1], hauteur))
		# Miettes de la pose voisine laissées par la coupe : seules les grandes taches restent.
		garde = Image.new("L", morceau.size, 0)
		for _boite, masque in preparer._taches(morceau, part_min=0.1):
			garde = ImageChops.lighter(garde, masque)
		morceau.putalpha(ImageChops.multiply(morceau.getchannel("A"), garde))
		separee.paste(morceau, (coupes[k] + vide * k, 0))
	copie = nom.replace(".png", "_separe.png")
	separee.save(ART / copie)
	return copie


def entrees(badge: str, version: str) -> tuple[dict, list, str]:
	"""(sections du manifeste, pêche, buste) d'une version : identifiants `co_<badge>_<version>*`."""
	b, v = badge.lower(), version
	src = _Source(badge, version)
	i, f = f"co_{b}_{v}", f"{_C}{b}_{v}"
	note = f"chantier CO (dossier-costumes.md), {badge} {version}"
	sections = {
		"personnages": [
			{"id": i, "source": src["MARCHE"], "sortie": f"{f}_sheet.png", "hauteur": 128,
				"note": note},
			{"id": f"{i}_run", "source": src["COURSE"], "sortie": f"{f}_run_sheet.png",
				"hauteur": 128, "note": note},
			{"id": f"{i}_surf", "source": src["SURF"], "sortie": f"{f}_surf_sheet.png",
				"hauteur": 134, "nettoyer": True, "note": note},
			{"id": f"{i}_bike", "source": src["VELO"], "sortie": f"{f}_bike_sheet.png",
				"hauteur": 128, "nettoyer": True, "note": note},
		],
		"attentes": [
			{"id": f"{i}_idle", "source": src["ATTENTE"], "sortie": f"{f}_idle_sheet.png",
				"marche": i, "note": note},
			{"id": f"{i}_bike_idle", "source": src["VELO_ARRET"],
				"sortie": f"{f}_bike_idle_sheet.png", "marche": f"{i}_bike", "rapport_hauteur": 0.94,
				"note": note},
		],
		"heros_images": [
			{"id": f"{i}_lancer", "source": src["LANCER"], "sortie": f"{f}_lancer.png",
				"hauteur": 384, "note": note},
		],
	}
	sections["attentes"] = [e for e, asset in zip(sections["attentes"], ("ATTENTE", "VELO_ARRET"))
		if src.rev(asset) != "tiree"]
	if src.rev("COURSE_PROFIL") != "aucune":
		sections["personnages"][1]["profil_course"] = {
			"source": separer_profil(src["COURSE_PROFIL"]), "rebond": 3}
	peche = [(f"{i}_fish_cast", src["PECHE_LANCER"], f"{f}_fish_cast_sheet.png"),
		(f"{i}_fish_wait", src["PECHE_ATTENTE"], f"{f}_fish_wait_sheet.png")]
	return sections, peche, src["BUSTE"]


def preparer_version(badge: str, version: str, catalogue: dict) -> None:
	sections, peche, buste = entrees(badge, version)
	m = json.loads((ART_DIR / "manifeste.json").read_text())
	sous = {"case": m["case"], "pokemon": [], **sections}
	p = preparer.Preparateur(sous, ART)
	p.personnages()
	p.attentes()
	src = _Source(badge, version)
	for asset, planche in TIREE_DE.items():
		if src.rev(asset) == "tiree":
			base = f"co_{badge.lower()}_{version}{planche}"
			suffixe = "_idle" if asset == "ATTENTE" else "_bike_idle"
			p.catalogue["personnages"][f"co_{badge.lower()}_{version}{suffixe}"] = tirer_attente(
				p.catalogue["personnages"][base], f"{_C}{badge.lower()}_{version}{suffixe}_sheet.png")
	p.heros_images()
	marche = p.catalogue["personnages"][f"co_{badge.lower()}_{version}"]
	for ident, source, sortie in peche:
		largeur, hauteur = daf5_reliquats.pecher(ART / source, RACINE / marche["fichier"][6:],
			RACINE / sortie)
		p.catalogue["personnages"][ident] = {
			"fichier": f"res://{sortie}", "cellule": [largeur, hauteur], "hauteur": marche["hauteur"],
			"colonnes": 4, "lignes": 1, "ordre_colonnes": ["bas", "gauche", "droite", "haut"]}
	sortie_buste = f"{_C}{badge.lower()}_{version}_bust.webp"
	preparer_menu._heros(ART / buste, RACINE / sortie_buste)
	p.catalogue["images"][f"co_{badge.lower()}_{version}_bust"] = {"fichier": f"res://{sortie_buste}"}
	for section in ("personnages", "images"):
		catalogue.setdefault(section, {}).update(p.catalogue[section])
	print(f"{badge} {version} : prêt")


def main() -> None:
	catalogue = json.loads(CATALOGUE.read_text()) if CATALOGUE.exists() else {}
	for badge in sys.argv[1:]:
		for version in VERSIONS:
			preparer_version(badge.upper(), version, catalogue)
	CATALOGUE.write_text(json.dumps(catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	main()
