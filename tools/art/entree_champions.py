#!/usr/bin/env python3
"""Étape 2 de l'entrée des combats de Dresseur : les 7 autres Champions d'Arène (fiche
docs/design/fiches-assets/entree-dresseurs.md §3 et §10, pilote validé : Pierre).

  tools/art/entree_champions.py refs                  # références → build/art/champions/
  tools/art/entree_champions.py prompts               # prompts → tools/art/entree_dresseurs/champions/
  tools/art/entree_champions.py generer ondine sprites [r] [--seul]   # ou « buste »
  tools/art/entree_champions.py exporter [id ...]     # détourage, toiles, WebP aux chemins de la fiche

Une génération « sprites » = les deux poses (debout prêt, lancer) côte à côte, comme ED_PIERRE ;
une génération « buste » = le buste de banderole au cadrage de vs/pierre.webp. Références jointes :
Pierre (debout + lancer) et vs/pierre comme style, plus l'apparence du monde du Champion (s'il en a
une peinte) ou son sprite de combat debout (pour le buste).
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import entree_dresseurs as ed  # noqa: E402

RACINE = ed.RACINE
CH = ed.ART / "champions"
PROMPTS = Path(__file__).resolve().parent / "entree_dresseurs" / "champions"
MONDE = RACINE / "assets" / "sprites" / "characters" / "painted"

# id → (apparence du monde peinte ou None, description, pose debout, détail du lancer)
CHAMPIONS: dict[str, tuple] = {
	"ondine": ("ondine",
		"Ondine, Championne d'Arène d'Azuria (type Eau), jeune fille d'environ 15 ans, mince et "
		"sportive, cheveux ROUX ORANGÉ vif noués en queue de cheval haute sur le côté, grands yeux "
		"bleu-vert, sourire assuré un peu frondeur ; débardeur court JAUNE, bretelles ROUGES, short en "
		"jean bleu aux ourlets roulés, chaussettes blanches courtes, baskets rouges et blanches (comme "
		"son sprite du monde, IMAGE 3).",
		"une main sur la hanche, l'autre bras plié tenant le bas de sa bretelle, poids sur une jambe, "
		"tête tournée vers la gauche, sourire de défi",
		"queue de cheval qui suit le mouvement"),
	"major_bob": ("major_bob",
		"Major Bob, Champion d'Arène de Carmin-sur-Mer (type Électrik), GRAND homme adulte très "
		"musclé (épaules larges, nettement plus grand et plus massif que Pierre), cheveux BLONDS en "
		"brosse hérissée, mâchoire carrée, sourire carnassier ; débardeur militaire VERT OLIVE, plaque "
		"d'identité au cou, écusson éclair JAUNE sur le haut du bras, pantalon treillis CAMOUFLAGE "
		"vert et brun à poches, ceinture, rangers noires (comme son sprite du monde, IMAGE 3).",
		"poings sur les hanches, torse bombé, jambes écartées, menton levé, tête tournée vers la gauche",
		"lancer puissant, muscles tendus"),
	"erika": ("erika",
		"Erika, Championne d'Arène de Céladopole (type Plante), jeune femme d'environ 18 ans, douce et "
		"élégante, carré court NOIR avec frange droite, grand NŒUD ROUGE dans les cheveux, yeux "
		"sombres paisibles ; kimono VERT D'EAU à motifs de fleurs roses et blanches, obi JAUNE noué, "
		"hakama ROUGE, chaussettes blanches tabi et sandales (comme son sprite du monde, IMAGE 3).",
		"mains jointes devant elle, un éventail fermé entre les mains, posture droite et gracieuse, "
		"tête légèrement inclinée vers la gauche, sourire serein",
		"manches du kimono qui flottent, geste gracieux mais net"),
	"koga": (None,
		"Koga, Champion d'Arène de Parmanie (type Poison), GRAND homme adulte d'environ 40 ans, sec et "
		"nerveux, NINJA : cheveux noirs en épis attachés en arrière, BANDEAU frontal gris métal noué, "
		"courte barbe sombre, regard perçant ; tenue de ninja BLEU NUIT et VIOLET sombre, plastron et "
		"épaulière gris, longue ÉCHARPE VIOLETTE qui flotte, gants sans doigts, bandes aux mollets, "
		"tabi noirs.",
		"bras croisés, l'écharpe flottant derrière lui, jambes écartées bien ancrées, regard vers la "
		"gauche, demi-sourire",
		"geste vif et sec de ninja, écharpe qui fouette l'air"),
	"morgane": (None,
		"Morgane, Championne d'Arène de Safrania (type Psy), jeune femme d'environ 20 ans, grande et "
		"élancée, très LONGS cheveux raides NOIRS aux reflets vert sombre jusqu'à la taille, peau "
		"pâle, yeux ROUGES, expression froide et impassible ; haut ajusté NOIR à manches longues avec "
		"liserés ROUGES, ceinture-écharpe rouge, pantalon BLANC ample, bottines rouges.",
		"un bras le long du corps, l'autre main levée près de la tempe, deux doigts tendus (geste "
		"psychique), regard vers la gauche, cheveux légèrement soulevés",
		"cheveux soulevés par le mouvement, regard glacial"),
	"auguste": (None,
		"Auguste, Champion d'Arène de Cramois'Île (type Feu), homme ÂGÉ d'environ 60 ans, PETIT et "
		"vif (nettement plus petit que Pierre), CRÂNE CHAUVE, grosse MOUSTACHE BLANCHE, LUNETTES "
		"NOIRES rondes, grand sourire malicieux ; BLOUSE BLANCHE de scientifique ouverte sur une "
		"chemise ROUGE SOMBRE et une cravate noire, pantalon gris foncé, chaussures marron.",
		"une main sur la hanche, l'autre index levé comme pour poser une question de quiz, buste un "
		"peu penché vers la gauche, sourire",
		"pans de la blouse qui volent, sourire fougueux"),
	"giovanni": ("giovanni",
		"Giovanni, Champion d'Arène de Jadielle et chef de la Team Rocket (type Sol), GRAND homme "
		"adulte d'environ 45 ans, carrure imposante, cheveux BRUN SOMBRE plaqués en arrière, sourcils "
		"durs, regard froid et dominateur ; COSTUME trois pièces ORANGE ROUILLE (veste, gilet, "
		"pantalon), chemise NOIRE, petite broche rouge au revers, chaussures noires cirées (comme son "
		"sprite du monde, IMAGE 3).",
		"mains dans les poches du pantalon, épaules en arrière, menton haut, tête tournée vers la "
		"gauche, léger sourire supérieur",
		"geste ample et autoritaire, veste ouverte par le mouvement"),
}

SPRITES = """{ident} — sprites de combat de Kanto 2026 (jeu 2D HD). Images jointes : IMAGE 1 = Pierre, Champion d'Arène d'Argenta, sprites de combat VALIDÉS (à gauche debout prêt, à droite pose de lancer) : c'est la CIBLE EXACTE du rendu, de la main, de l'échelle et du cadrage ; IMAGE 2 = son buste « VS » validé (même main){monde}.

PERSONNAGE : {desc} Design moderne fidèle au personnage de Pokémon Rouge/Bleu.

À FAIRE : UNE image paysage 1536 × 1024 avec DEUX poses du même personnage côte à côte, chacune en pied, grande (environ 900 px de haut, des cheveux aux semelles), bien séparées (au moins 120 px de vide entre elles), rien de coupé par le bord, pieds tous à la même hauteur près du bas de l'image :
- À GAUCHE : pose DEBOUT PRÊT de Champion : de trois-quarts face, corps tourné vers la gauche de l'image, {debout}.
- À DROITE : pose de LANCER comme celle de Pierre (IMAGE 1, à droite) : de trois-quarts face tourné vers la gauche, fente avant (jambe gauche de l'image avancée et fléchie, l'autre tendue en arrière), bras tendu loin vers la gauche à hauteur de poitrine, main ouverte doigts écartés, la Ball VIENT DE PARTIR (main vide, pas de Ball dessinée), l'autre bras replié en arrière, {lancer}.
Mains à cinq doigts correctes, pieds entiers, même personnage, même tenue et mêmes proportions dans les deux poses.

STYLE (impératif) : exactement la main de Pierre (IMAGES 1 et 2) : illustration 2D HD « anime peint », contours fins et doux brun foncé (jamais de trait noir épais), aplats peints avec ombres douces et deux ou trois valeurs par matériau, légère granularité de pinceau, proportions réalistes-stylisées (PAS chibi), lumière neutre et douce venant de la gauche.

FOND : TRANSPARENT (vrai canal alpha), aucun damier dessiné, aucun décor, aucun sol, aucune ombre portée, aucun halo, aucun texte, aucune lettre, aucun cadre, aucune Poké Ball.
"""

BUSTE = """{ident} — buste de banderole « VS » de Kanto 2026. Images jointes : IMAGE 1 = le buste VALIDÉ de Pierre (CIBLE EXACTE du cadrage, du rendu et de la main) ; IMAGE 2 = le personnage à peindre, sprite de combat du jeu (même personnage, même tenue, à GARDER).

PERSONNAGE : {desc}

À FAIRE : le personnage de l'IMAGE 2, même visage, même coiffure, même tenue, en BUSTE POITRINE exactement cadré comme Pierre (IMAGE 1) : tête, cou, les DEUX ÉPAULES entières et le haut de la poitrine avec le col de sa tenue.

MISE EN PAGE (impératif) dans une image portrait 1024 × 1536 :
- le haut des cheveux à environ 40 px du bord haut ;
- la TÊTE entière (cheveux compris) occupe seulement les 38 % supérieurs de la hauteur (le menton vers 36 %) ;
- le cou, le col et la ligne des épaules entre 36 % et 50 % de la hauteur, les épaules bien larges (presque toute la largeur) ;
- le haut de la poitrine jusqu'au bord bas (coupé net par le bas, c'est voulu).
Visage de trois-quarts tourné vers la GAUCHE, menton un peu baissé, regard vers le BAS À GAUCHE, expression de défi propre au personnage.

STYLE : celui de l'IMAGE 1 : illustration anime peinte, réaliste-stylisée (PAS chibi), contours fins brun foncé, ombres douces peintes, lumière chaude venant de la droite.

FOND : TRANSPARENT (vrai canal alpha), aucun damier dessiné, aucun décor, aucune banderole, aucun texte, aucun cadre, aucun halo.
"""


def refs() -> None:
	CH.mkdir(parents=True, exist_ok=True)
	a = Image.open(ed.SPR / "pierre.webp").convert("RGBA")
	b = Image.open(ed.SPR / "pierre_lancer.webp").convert("RGBA")
	t = Image.new("RGBA", (a.width + b.width + 60, a.height), (0, 0, 0, 0))
	t.alpha_composite(a, (0, 0))
	t.alpha_composite(b, (a.width + 60, 0))
	t.save(CH / "ref_pierre_poses.png")
	Image.open(ed.VS / "pierre.webp").convert("RGBA").save(CH / "ref_pierre_buste.png")
	for ident, (monde, *_r) in CHAMPIONS.items():
		if monde is None:
			continue
		f = Image.open(MONDE / f"{monde}_sheet.png").convert("RGBA")
		cw, chh = f.width // 4, f.height // 4
		# Rangées : bas, gauche, droite, haut ; première image de face et de profil gauche.
		r = Image.new("RGBA", (cw * 2 + 10, chh), (0, 0, 0, 0))
		r.alpha_composite(f.crop((0, 0, cw, chh)), (0, 0))
		r.alpha_composite(f.crop((0, chh, cw, 2 * chh)), (cw + 10, 0))
		r.resize((r.width * 4, r.height * 4), Image.LANCZOS).save(CH / f"ref_monde_{ident}.png")


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for ident, (monde, desc, debout, lancer) in CHAMPIONS.items():
		m = (" ; IMAGE 3 = son apparence dans le monde du jeu (petit sprite de face et de profil) : "
			"sa tenue et ses couleurs font foi") if monde else ""
		(PROMPTS / f"{ident}_sprites.txt").write_text(SPRITES.format(ident=f"EC_{ident.upper()}",
			monde=m, desc=desc, debout=debout, lancer=lancer), encoding="utf-8")
		(PROMPTS / f"{ident}_buste.txt").write_text(BUSTE.format(ident=f"EC_BUSTE_{ident.upper()}",
			desc=desc.replace(" (comme son sprite du monde, IMAGE 3)", "")), encoding="utf-8")


def jointes(ident: str, pose: str) -> list[Path]:
	if pose == "sprites":
		j = [CH / "ref_pierre_poses.png", CH / "ref_pierre_buste.png"]
		if CHAMPIONS[ident][0]:
			j.append(CH / f"ref_monde_{ident}.png")
		return j
	png = CH / f"ref_debout_{ident}.png"
	Image.open(ed.SPR / f"{ident}.webp").convert("RGBA").save(png)
	return [CH / "ref_pierre_buste.png", png]


def generer(ident: str, pose: str, rev: str = "1", seul: bool = False) -> int:
	j = [] if seul else [str(p) for p in jointes(ident, pose)]
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), f"EC_{ident}_{pose}_r{rev}",
		str(PROMPTS / f"{ident}_{pose}.txt"), *j]
	return subprocess.call(cmd, cwd=RACINE)


# Révision retenue par (id, pose) ; absente = r1.
RETENUS: dict[tuple[str, str], str] = {}


def _source(ident: str, pose: str) -> Image.Image | None:
	p = ed.ART / f"EC_{ident}_{pose}_r{RETENUS.get((ident, pose), '1')}.png"
	return Image.open(p).convert("RGBA") if p.exists() else None


def _poses(im: Image.Image) -> list[Image.Image]:
	im = ed._nettoyer(im)
	masque = np.asarray(im)[..., 3] > 96
	sorties = []
	for x0, x1 in ed._plages(masque):
		sous = im.crop((x0, 0, x1, im.height))
		sorties.append(sous.crop(sous.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()))
	return sorties


def _buste(im: Image.Image, toile=(540, 720), marge_haut: int = 18) -> Image.Image:
	im = ed._nettoyer(im)
	boite = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
	im = im.crop((0, boite[1], im.width, im.height))
	r = im.resize((toile[0], round(im.height * toile[0] / im.width)), Image.LANCZOS)
	t = Image.new("RGBA", toile, (0, 0, 0, 0))
	t.alpha_composite(r.crop((0, 0, toile[0], toile[1] - marge_haut)), (0, marge_haut))
	return t


def exporter(idents: list[str]) -> None:
	for ident in idents or list(CHAMPIONS):
		s = _source(ident, "sprites")
		if s is not None:
			p = _poses(s)
			print(ident, "poses", [i.size for i in p])
			if len(p) >= 2:
				debout, lancer = ed.poses_en_toile(p[0], p[-1], (512, 768), 16)
				ed._webp(debout, ed.SPR / f"{ident}.webp")
				ed._webp(lancer, ed.SPR / f"{ident}_lancer.webp")
		b = _source(ident, "buste")
		if b is not None:
			ed._webp(_buste(b), ed.VS / f"{ident}.webp")


if __name__ == "__main__":
	act = sys.argv[1]
	if act == "refs":
		refs()
	elif act == "prompts":
		prompts()
	elif act == "generer":
		args = [a for a in sys.argv[2:] if a != "--seul"]
		sys.exit(generer(args[0], args[1], args[2] if len(args) > 2 else "1", "--seul" in sys.argv))
	elif act == "exporter":
		exporter(sys.argv[2:])
