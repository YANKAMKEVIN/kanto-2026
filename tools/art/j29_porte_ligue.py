#!/usr/bin/env python3
"""Jalon 29 — porte de la Ligue Pokémon dans le hall du Plateau Indigo (QA téléphone, A17).

Fiche : docs/design/fiches-assets/j29-porte-ligue.md. Le hall (`indigo_plateau_lobby`) reprend la
coque du Centre Pokémon (`int_centre_coque.png`) ; le warp `ToLeague` (12, 3) donnait sur le mur
du fond nu (« Au-delà de cette porte… » dit l'hôte). Une seule image :
  INT_PORTE_LIGUE_01 → `int_porte_ligue_01` : grande porte de la Ligue posée dans le mur du fond
  au-dessus de la case (12, 3) (sans emprise : les rangées du mur sont déjà bloquées), à la
  manière de `int_porte_labo_01` dans l'arche du Musée d'Argenta (série 12).

Prompts versionnés : tools/art/prompts/j29/<NOM>_rN.txt. Sources dans $ART (défaut : build/art de
cette copie).

Usage :
  tools/art/j29_porte_ligue.py --prompts      écrit les prompts (r1 à r3)
  tools/art/j29_porte_ligue.py --refs         recadre le mur du fond de la coque (REF_J29_MUR, × 2)
  tools/art/j29_porte_ligue.py --commandes    liste les appels tools/art/generer.sh
  tools/art/j29_porte_ligue.py --integrer     prépare l'essai retenu dans assets/ + catalogue.json
                                              (fonctions de tools/art/preparer.py, entrée du
                                              manifeste) ; puis build_painted_props.gd --nouveaux
  tools/art/j29_porte_ligue.py --controle     planche de contrôle (r1..r3 posés sur la coque à
                                              l'échelle du jeu) → $ART/J29_PORTE_LIGUE_CONTROLE_v1.png
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
sys.path.insert(0, str(ICI))
from serie06 import ADN, LUMIERE_NE  # noqa: E402
import preparer  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
PROMPTS = ICI / "prompts" / "j29"
I = RACINE / "assets/world/interiors"
COQUE = I / "int_centre_coque.png"  # 1440 × 960 (15 × 10 cases)
CASE = 96
NOM = "INT_PORTE_LIGUE_01_NE"
IDENT = "int_porte_ligue_01"

## Mur du fond, colonnes 9 à 14, rangées 0 à 3 (la fenêtre est, le pilier de la case 12).
REF_MUR = (9 * CASE, 0, 15 * CASE, 3 * CASE + 48)

## Essai retenu (mis à jour après relecture ; voir la fiche).
RETENU = f"{NOM}_r3"

## Pose dans le hall (tools/build_painted_interiors.gd, `_indigo_plateau_lobby`) : pied au milieu
## de la case 12, à 2,3 cases (bas des lambris du mur du fond peint dans la coque).
POSE = {"case": (12, 2), "pied_y": 2.3}

## Entrée de tools/art/manifeste.json (« objets ») : largeur en cases, contact comme la porte du
## laboratoire (aucune ombre : `PaintedPropRules.casts_shadows` est faux).
ENTREE = {"id": IDENT, "source": f"{RETENU}.png", "sortie": f"assets/world/interiors/{IDENT}.png",
	"axe": "w", "cases": 1.6, "ombre": False, "contact": 0.2}

VALEURS = ("VALEURS DU HALL (celles du Centre Pokémon joint) : murs crème, lambris et piliers de bois brun "
	"chaud, bandeau rouge vif, verre bleu clair ; la porte de la Ligue y ajoute un rouge carmin profond, "
	"de l'or patiné (laiton) et une pierre claire crème ; lumière NEUTRE, diffuse et blanche (le jeu "
	"ajoute la lumière chaude de l'intérieur : ne peins NI halo, NI rayon, NI lueur derrière la porte).")

PORTE_TXT = """ASSET : la GRANDE PORTE DE LA LIGUE POKÉMON, au fond du hall du Plateau Indigo : la porte solennelle qui mène aux salles de la Ligue, posée DANS le mur du fond du hall (le mur crème à lambris de bois brun et bandeau rouge du Centre joint). C'est la porte la plus importante du jeu : digne, imposante, mais sobre et lisible.
Composition : un PORTAIL de pierre claire crème à montants droits et LINTEAU en léger arc surbaissé, souligné d'un filet d'or patiné ; dedans, une DOUBLE PORTE FERMÉE à deux vantaux en bois rouge carmin laqué, chaque vantail orné de deux panneaux moulurés bordés d'or, deux grandes poignées verticales en laiton au milieu, les deux vantaux jointifs (fente verticale nette au centre) ; au sommet du linteau, un petit écusson doré en forme de BLASON (bouclier stylisé avec une aile, SANS cercle partagé, SANS lettre). Un seuil de pierre bas au pied, à fleur du sol. La porte est vue de FACE, dans la vue du jeu : on voit sa face avant et à peine le dessus du linteau, jamais ses côtés.
Proportions : 1,6 case de large pour environ 2 cases de haut (la porte seule ≈ 1,2 case de large et 1,6 case de haut, le portail l'encadre) : plus haute et plus large qu'une porte simple (1 × 1,5 case).
Format : PNG CARRÉ 1024 × 1024, la porte et son portail centrés, environ 640 px de large et 800 px de haut, la base (seuil) sur une ligne horizontale droite à 60 px du bas ; vraie transparence (canal alpha) autour ; aucun mur autour, aucun sol, aucune ombre portée, aucun halo."""

INTERDITS = ("Interdits : texte, lettres, chiffres, inscription, enseigne, plaque écrite, AUCUN emblème rond de type "
	"balle (ni cercle partagé en deux, ni médaillon à bande centrale), porte ouverte ou entrouverte, lumière ou "
	"silhouette derrière la porte, personnage (même s'il figure sur une image jointe : ne le reproduis pas), "
	"Pokémon, tapis, plante, mur ou fenêtre autour, flou de profondeur, vignettage.")

ANCRES = [I / "int_porte_labo_01.png", I / "int_centre_comptoir.png"]
JOINTES_TXT = {
	"ref": "REF_J29_MUR = le mur du fond du hall où la porte sera posée (au milieu de l'extrait, à la place du pilier de bois à droite de la fenêtre) : reprends-en la lumière, les couleurs et la facture, mais NE PEINS PAS le mur, seulement la porte",
	"ancres": "int_porte_labo_01 = gabarit d'une porte posée dans un mur (même angle de vue, même main) ; int_centre_comptoir = mobilier du même Centre (rendu peint, contour coloré, finesse, lumière neutre) : respecte-les exactement",
}


def _ecrire(chemin: Path, texte: str) -> None:
	chemin.parent.mkdir(parents=True, exist_ok=True)
	chemin.write_text(texte.strip() + "\n")
	print(chemin.relative_to(RACINE))


def jointes(r: int) -> list[str]:
	"""r1 : extrait de la coque + ancres ; r2 : ancres du dépôt ; r3 : sans image (règle des refus)."""
	if r == 3:
		return []
	liste = [str(ART / "REF_J29_MUR.png")] if r == 1 else []
	return liste + [str(a) for a in ANCRES]


def _phrase_jointes(r: int) -> str:
	if r == 3:
		return "Aucune image jointe."
	parts = [JOINTES_TXT["ref"]] if r == 1 else []
	parts.append(JOINTES_TXT["ancres"])
	return "Images jointes : " + " ; ".join(parts) + "."


def prompts() -> None:
	for r in (1, 2, 3):
		texte = "\n\n".join([f"{NOM[:-3]} — NOUVELLE image : un élément de jeu isolé, pas une scène.\n"
			f"{_phrase_jointes(r)}", ADN.strip(), LUMIERE_NE + "\n" + VALEURS, PORTE_TXT, INTERDITS])
		_ecrire(PROMPTS / f"{NOM}_r{r}.txt", texte)


def refs() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	im = Image.open(COQUE).convert("RGB").crop(REF_MUR)
	im = im.resize((im.width * 2, im.height * 2), Image.LANCZOS)
	im.save(ART / "REF_J29_MUR.png")
	print(ART / "REF_J29_MUR.png", im.size)


def commandes() -> None:
	for r in (1, 2, 3):
		print("tools/art/generer.sh %s_r%d %s %s" % (NOM, r,
			(PROMPTS / f"{NOM}_r{r}.txt").relative_to(RACINE), " ".join(jointes(r))))


def _porte(source: str) -> Image.Image:
	"""Silhouette (halos clairs retirés) mise à sa largeur en cases, comme preparer.py."""
	image = preparer.nettoyer_halos(Image.open(ART / source).convert("RGBA"))
	return preparer._mettre_a_taille(preparer._silhouette(image), ENTREE["axe"], ENTREE["cases"], CASE)


def integrer() -> None:
	"""Entrée du manifeste (ajoutée ou remplacée), image et contact dans assets/, catalogue à jour."""
	chemin = ICI / "manifeste.json"
	manifeste = json.loads(chemin.read_text())
	manifeste["objets"] = [e for e in manifeste["objets"] if e["id"] != IDENT] + [ENTREE]
	chemin.write_text(json.dumps(manifeste, ensure_ascii=False, indent=1) + "\n")
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads((RACINE / "assets/world/catalogue.json").read_text())
	p._objet(IDENT, ENTREE["sortie"], _porte(ENTREE["source"]), ENTREE["ombre"], ENTREE["contact"])
	p.ecrire_catalogue()


def controle() -> None:
	"""Les essais présents posés sur le mur du fond de la coque, pied au milieu de la case 12."""
	essais = [f"{NOM}_r{r}" for r in (1, 2, 3) if (ART / f"{NOM}_r{r}.png").exists()]
	extrait = (8 * CASE, 0, 15 * CASE, 6 * CASE)
	coque = Image.open(COQUE).convert("RGBA")
	planche = Image.new("RGBA", ((extrait[2] - extrait[0]) * max(1, len(essais)), extrait[3]), "white")
	for i, nom in enumerate(essais):
		fond = coque.copy()
		porte = _porte(f"{nom}.png")
		x = round((POSE["case"][0] + 0.5) * CASE - porte.width / 2)
		y = round(POSE["pied_y"] * CASE) - porte.height
		fond.alpha_composite(porte, (x, y))
		d = ImageDraw.Draw(fond)
		d.rectangle((12 * CASE, 3 * CASE, 13 * CASE - 1, 4 * CASE - 1), outline=(0, 160, 255, 255), width=2)
		d.text((extrait[0] + 8, 5 * CASE + 60), f"{nom} : {porte.width} × {porte.height}", fill="black")
		planche.alpha_composite(fond.crop(extrait), ((extrait[2] - extrait[0]) * i, 0))
	sortie = ART / "J29_PORTE_LIGUE_CONTROLE_v1.png"
	planche.save(sortie)
	print(sortie)


if __name__ == "__main__":
	actions = {"--prompts": prompts, "--refs": refs, "--commandes": commandes, "--integrer": integrer,
		"--controle": controle}
	if len(sys.argv) != 2 or sys.argv[1] not in actions:
		print(__doc__)
		sys.exit(1)
	actions[sys.argv[1]]()
