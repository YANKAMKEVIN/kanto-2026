#!/usr/bin/env python3
"""Combat vivant, vague 1 d'art (CV.1) : flipbooks et sprites de particules des familles du plancher.
Fiche : docs/design/fiches-assets/serie-cv-fx-1.md. Barre de qualité : docs/tech/combat-vivant.md §2.9.
Chaque image de Codex est une PLANCHE de 8 images clés (flipbook, 4 × 2) ou de 8 sprites (particules, 4 × 2).
Deux fonds, selon la matière :
  - « add » (lumière : feu, éclair, psy, lueurs) : fond NOIR PUR ; l'alpha est tiré de la luminance, la
    couleur est dépréMultipliée ; à poser en mélange ADDITIF dans le jeu ;
  - « norm » (matière : eau, feuilles, fumée, poussière, pierre, glace) : fond MAGENTA PUR #FF00FF, détouré
    par distance de couleur ; à poser en mélange normal.
Usage :
  tools/art/serie_cv_fx.py --prompts          écrit les prompts (build/art/prompts/cv_fx/), sans Codex
  tools/art/serie_cv_fx.py [NOM ...]          génère avec Codex (3 en parallèle ; sans argument : ce qui manque)
  tools/art/serie_cv_fx.py --preparer         build/art/ → assets/sprites/battle_fx/ (atlas, 16 images par flipbook)
  tools/art/serie_cv_fx.py --planche          planche + GIF en boucle → docs/design/fiches-assets/cv-fx-1/
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
PROMPTS = ART / "prompts" / "cv_fx"
SORTIE = RACINE / "assets" / "sprites" / "battle_fx"
FICHE = RACINE / "docs" / "design" / "fiches-assets" / "cv-fx-1"
FRAME = 320          ## côté d'une image de flipbook préparée
PART = 192           ## côté d'un sprite de particule
NB_FINAL = 16        ## images par flipbook après interpolation

ADN_FX = """ADN VISUEL — EFFETS DE COMBAT KANTO 2026 (à respecter strictement)
- Rendu : effet spécial PEINT numériquement, dans la même main que le monde du jeu (RPG Pokémon moderne « HD-2D peint ») : volumes lisibles, formes douces et organiques, coups de pinceau visibles, légère granularité picturale. Ni pixel art, ni 3D, ni photo, ni formes géométriques plates, ni dessin animé en aplats, ni rendu de moteur de particules.
- Couleur : dégradé de 3 à 4 teintes par élément — cœur presque blanc, teinte franche de l'élément, bord plus sombre et plus saturé. Couleurs vives mais pas fluo.
- Lumière NEUTRE : l'effet brille de lui-même ; aucun éclairage de scène, aucune ombre portée, aucun sol, aucun décor, aucun personnage, aucun Pokémon.
- Interdits : texte, lettres, chiffres, logo, signature, filigrane, cadre, grille dessinée, numéros, damier."""

FOND_NOIR = ("Fond : NOIR PUR uniforme (#000000), sur toute la planche, sans dégradé ni vignettage ; l'effet est "
	"lumineux et se détache du noir. Aucun damier, aucune transparence dessinée.")
FOND_MAGENTA = ("Fond : MAGENTA PUR uniforme (#FF00FF), sur toute la planche, sans dégradé ni ombre ; aucun magenta "
	"ni rose dans l'effet lui-même. Aucun damier, aucune transparence dessinée.")

## (identifiant, mode, titre, consigne de la suite des 8 images)
FLIPBOOKS = [
	("jet_flammes", "add", "JET DE FLAMMES (Lance-Flammes)",
		"un jet de flammes horizontal qui part du bord GAUCHE de la case et s'étire vers la droite, large "
		"d'environ la moitié de la case, pointe de langues de feu vers la droite. Les 8 images sont la boucle "
		"d'une même flamme qui ondule : langues qui se déplacent, se divisent et se rejoignent, d'une image à "
		"la suivante (la dernière enchaîne avec la première). Cœur presque blanc-jaune, corps orange, bord rouge sombre."),
	("boule_feu", "add", "BOULE DE FEU",
		"une boule de feu ronde centrée dans la case, avec une courte traîne de flammes vers la GAUCHE (elle "
		"file vers la droite). Boucle : la boule tourne et palpite, langues de flamme qui lèchent la traîne de "
		"façons différentes à chaque image. Cœur blanc-jaune, orange, rouge sombre au bord."),
	("gerbe_braises", "add", "GERBE DE BRAISES (Flammèche)",
		"une petite gerbe de braises et de trois ou quatre petites flammes qui jaillissent du bas de la case "
		"vers le haut-droite : de la naissance (image 1, quelques braises) au plein de la gerbe (images 4-5) "
		"puis à la dispersion en étincelles fines (image 8, presque vide). Braises jaune-orangé à cœur blanc."),
	("jet_eau", "norm", "JET D'EAU (Pistolet à O)",
		"un jet d'eau horizontal qui part du bord GAUCHE vers la droite, large d'environ le tiers de la case, "
		"eau bleu clair translucide avec reflets blancs, bord bleu profond, petites gouttes qui s'en échappent. "
		"Boucle : le jet ondule, les reflets glissent, d'une image à l'autre (la dernière enchaîne avec la première)."),
	("eclaboussure", "norm", "ÉCLABOUSSURE (impact d'eau)",
		"un impact d'eau qui éclabousse, centré dans la case : image 1 un point d'impact, puis une couronne "
		"d'eau qui s'ouvre (2 à 4), des gerbes et des gouttes qui s'envolent (5-6), puis qui retombent (7), "
		"quelques gouttes et un anneau d'écume à la fin (8). Eau bleu clair, reflets blancs, bord bleu profond."),
	("arc_electrique_a", "add", "ARC ÉLECTRIQUE A (Éclair)",
		"un arc électrique en zigzag horizontal qui traverse toute la case de gauche à droite, avec de petites "
		"ramifications. Chaque image a un tracé DIFFÉRENT (l'arc se régénère à chaque image, comme un vrai arc), "
		"même épaisseur générale. Cœur blanc pur, halo jaune vif, bord bleu-violet sombre."),
	("arc_electrique_b", "add", "ARC ÉLECTRIQUE B (Cage-Éclair)",
		"un arc électrique plus fin et plus sinueux que la variante A, de forme courbe en S qui va du bas-gauche "
		"au haut-droite, avec des étincelles tout autour. Tracé DIFFÉRENT à chaque image (il crépite). Cœur blanc, "
		"halo jaune, bord bleu-violet."),
	("decharge_etoile", "add", "DÉCHARGE EN ÉTOILE (Tonnerre)",
		"une décharge d'énergie en étoile centrée dans la case : image 1 un point blanc, puis des éclairs qui "
		"partent dans 6 à 8 directions et s'allongent (2 à 4), plein de l'étoile avec halo jaune (5), puis "
		"éclairs qui se brisent et s'éteignent en étincelles (6 à 8). Cœur blanc, jaune, bord bleu-violet."),
	("rafale_feuilles", "norm", "RAFALE DE FEUILLES (Tranch'Herbe)",
		"une rafale d'une quinzaine de feuilles vertes peintes qui tourbillonnent en un faisceau horizontal de "
		"gauche à droite, feuilles de tailles et d'orientations variées, qui tournent et se déplacent d'une image "
		"à l'autre (boucle). Verts du vert-jaune ensoleillé au vert sapin, nervures légères, bord plus sombre."),
	("nuage_spores", "norm", "NUAGE DE SPORES (Poudre Toxik / Para-Spore)",
		"un nuage de spores en forme de bouffée ronde et irrégulière centrée dans la case, fait de petites "
		"particules poudreuses et de volutes ; il gonfle et se déforme doucement d'une image à l'autre, des grains "
		"se détachent aux bords (boucle). Teinte jaune-vert pâle à cœur crème, bord vert olive sombre."),
	("onde_psy", "add", "ONDE PSY (Psyko / Choc Mental)",
		"une onde psychique : des anneaux concentriques ondulants et déformés, centrés dans la case, qui "
		"s'élargissent d'une image à l'autre (image 1 petit anneau serré, image 8 grands anneaux presque "
		"dissipés), avec de fins filaments lumineux en spirale. Cœur rose pâle presque blanc, rose-violet vif, "
		"bord pourpre sombre."),
	("poussiere_eboulis", "norm", "POUSSIÈRE ET ÉBOULIS (Jet-Pierres / Séisme)",
		"un nuage de poussière brun-beige qui se lève du sol avec quelques petits éclats de pierre grise qui "
		"sont projetés : image 1 petit soulèvement à la base de la case, puis le nuage gonfle (2 à 5) avec des "
		"cailloux en l'air, puis retombe et se dissipe (6 à 8). Poussière beige chaud, ombres brun-violet, "
		"pierre gris-bleu."),
]

## Sprites de particules : (identifiant de planche, mode, [(nom, description)] ×8).
PARTICULES = [
	("part_a", "add", [
		("flamme", "une petite flamme isolée, goutte de feu allongée vers le haut, cœur jaune-blanc, orange, rouge"),
		("braise", "une braise : petit éclat incandescent rond, cœur blanc-jaune, orange, léger halo"),
		("etincelle", "une étincelle : petite étoile fine à quatre branches, jaune-blanc"),
		("lueur_douce", "une lueur ronde et douce : disque flou très progressif, blanc au centre, transparent au bord (halo)"),
		("etoile_impact", "une étoile d'impact : éclat à huit pointes de tailles inégales, cœur blanc, jaune, bord orange"),
		("griffes", "des entailles de griffes : trois estafilades lumineuses parallèles et légèrement courbes, blanc-bleuté"),
		("machoires", "des mâchoires : deux rangées de crocs blancs lumineux qui se referment, en arc, bord bleu pâle"),
		("note_son", "une onde sonore : arc de trois fines lignes concentriques lumineuses, blanc-bleuté"),
	]),
	("part_b", "norm", [
		("goutte", "une goutte d'eau en poire, bleu clair translucide, reflet blanc, bord bleu profond"),
		("bulle", "une bulle de savon : cercle translucide, reflets blancs arc-en-ciel pâle, bord fin bleuté"),
		("feuille", "une feuille d'arbre verte avec nervure centrale, vert-jaune à vert sapin, légèrement courbée"),
		("petale", "un pétale rose pâle, doux, légèrement recourbé, nervures fines"),
		("plume", "une plume blanche et crème, tige fine, barbes douces, légère courbe"),
		("eclat_glace", "un éclat de glace : prisme allongé et anguleux, bleu glacé translucide, cœur blanc, arêtes claires"),
		("caillou", "un petit caillou anguleux gris-bleu avec arêtes éclairées, ombre propre brun-violet"),
		("flocon", "un flocon de neige à six branches, blanc et bleu très pâle, fin et net"),
	]),
	("part_c", "norm", [
		("fumee", "une volute de fumée grise douce et arrondie, gris-bleu clair à gris sombre, bord vaporeux"),
		("poussiere", "une petite bouffée de poussière beige, arrondie et granuleuse, bord vaporeux"),
		("spore", "une spore : petite sphère duveteuse jaune-vert pâle, poudreuse"),
		("os", "un os court de dresseur-de-Pokémon, crème, deux extrémités arrondies, ombre propre brun-violet"),
		("poing", "un poing serré vu de face, gris-blanc lumineux de stylisation d'impact, pas de personnage"),
		("_coeur_rejete", "un petit cœur rose vif, brillant, bord rose sombre, reflet blanc (REJETÉ : le rose part avec la clé magenta ; à refaire sur fond noir, vague 2)"),
		("etoile", "une étoile à cinq branches jaune d'or, arrondie, cœur blanc, bord orange"),
		("aiguille", "une aiguille fine et longue, argentée, pointe très fine, reflet blanc"),
	]),
]
PARTICULES_NOMS = [n for _i, _m, ps in PARTICULES for n, _d in ps]


def _prompt_flipbook(ident: str, mode: str, titre: str, consigne: str) -> str:
	fond = FOND_NOIR if mode == "add" else FOND_MAGENTA
	return (f"CV_FX_{ident.upper()} — NOUVELLE image : une PLANCHE de 8 images d'animation (images clés) d'un "
		f"effet d'attaque de combat : {titre}.\n\n{ADN_FX}\n\n"
		"Format : image 1536 × 1024, divisée de façon invisible en 8 cases égales (4 colonnes × 2 rangées), de "
		"384 × 512 chacune. Lecture : de gauche à droite puis rangée du bas ; case 1 en haut à gauche, case 8 en "
		"bas à droite. Même échelle, même cadrage et même position de l'effet dans chaque case ; l'effet ne touche "
		"jamais le bord de sa case et ne déborde pas sur la case voisine ; aucune ligne de séparation.\n"
		f"SUJET : {consigne}\n{fond}\n")


def _prompt_particules(ident: str, mode: str, sprites: list[tuple[str, str]]) -> str:
	fond = FOND_NOIR if mode == "add" else FOND_MAGENTA
	liste = "\n".join(f"  case {i + 1} : {d}" for i, (_n, d) in enumerate(sprites))
	return (f"CV_FX_{ident.upper()} — NOUVELLE image : une PLANCHE de 8 sprites de particules pour des effets "
		f"d'attaque de combat.\n\n{ADN_FX}\n\n"
		"Format : image 1536 × 1024, 8 cases égales (4 colonnes × 2 rangées) de 384 × 512 ; case 1 en haut à "
		"gauche, lecture de gauche à droite puis rangée du bas. UN seul sprite par case, entier, centré, occupant "
		"environ 55 % de la case, sans toucher le bord ; aucune ligne de séparation ; sprites isolés les uns des "
		f"autres.\nCONTENU :\n{liste}\n{fond}\n")


def _images() -> list[tuple[str, str, str]]:
	"""(nom sans .png, mode, texte du prompt)."""
	sortie = [(f"CV_FX_{i.upper()}_r1", m, _prompt_flipbook(i, m, t, c)) for i, m, t, c in FLIPBOOKS]
	sortie += [(f"CV_FX_{i.upper()}_r1", m, _prompt_particules(i, m, s)) for i, m, s in PARTICULES]
	return sortie


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for nom, _m, texte in _images():
		(PROMPTS / f"{nom}.txt").write_text(texte, encoding="utf-8")
	print(f"{len(_images())} prompts dans {PROMPTS}")


def _generer(image: tuple[str, str, str]) -> str:
	nom = image[0]
	commande = [str(ICI / "generer.sh"), nom, str(PROMPTS / f"{nom}.txt")]
	for _essai in range(3):
		resultat = subprocess.run(commande, capture_output=True, text=True, cwd=RACINE)
		if resultat.returncode == 0:
			return f"{nom} : ok"
	return f"{nom} : ÉCHEC {resultat.stderr.strip()[-200:]}"


def generer(noms: list[str]) -> None:
	prompts()
	images = [i for i in _images() if (any(n.upper() in i[0] for n in noms) if noms else not (ART / f"{i[0]}.png").exists())]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(_generer, images):
			print(ligne, flush=True)


def _revision(nom_r1: str) -> Path | None:
	base = nom_r1.rsplit("_r", 1)[0]
	c = sorted(ART.glob(f"{base}_r*.png"), key=lambda p: int(p.stem.rsplit("_r", 1)[1]))
	return c[-1] if c else None


def _alpha(img: Image.Image, mode: str) -> Image.Image:
	"""Fond noir → alpha = luminance (couleur dépréMultipliée) ; fond magenta → alpha par distance au magenta."""
	a = np.asarray(img.convert("RGB")).astype(np.float32) / 255.0
	if mode == "add":
		al = a.max(axis=2)
		al = np.clip((al - 0.03) / 0.9, 0, 1) ** 0.8
		col = np.where(al[..., None] > 0.01, a / np.maximum(al[..., None], 0.01), 0)
		rgb = np.clip(col, 0, 1)
	else:
		# distance au magenta pur dans l'espace RGB ; 0 = fond, 1 = matière
		d = np.sqrt(((a - np.array([1.0, 0.0, 1.0])) ** 2).sum(axis=2)) / 1.2
		al = np.clip((d - 0.12) / 0.35, 0, 1)
		# frange et halo magenta : tout ce qui tire vers le magenta (min(R,B) > G) est retiré
		mag = np.clip(np.minimum(a[..., 0], a[..., 2]) - a[..., 1], 0, 1)
		al = al * np.clip(1 - mag * 3.5, 0, 1)
		rgb = a.copy()
		rgb[..., 0] = np.clip(rgb[..., 0] - mag, 0, 1)
		rgb[..., 2] = np.clip(rgb[..., 2] - mag, 0, 1)
	out = np.dstack([rgb, al])
	return Image.fromarray((out * 255).astype(np.uint8))


def _cases(img: Image.Image) -> list[Image.Image]:
	l, h = img.size
	cw, ch = l // 4, h // 2
	return [img.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)) for r in range(2) for c in range(4)]


def _recadrer(cases: list[Image.Image], cote: int, commun: bool) -> list[Image.Image]:
	"""Carré centré sur le contenu ; en flipbook le cadrage est COMMUN (union des boîtes) pour ne pas sauter."""
	boites = [c.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox() for c in cases]
	if commun:
		vues = [b for b in boites if b]
		u = (min(b[0] for b in vues), min(b[1] for b in vues), max(b[2] for b in vues), max(b[3] for b in vues))
		boites = [u] * len(cases)
	sortie = []
	for c, b in zip(cases, boites):
		if not b:
			sortie.append(Image.new("RGBA", (cote, cote)))
			continue
		w, h = b[2] - b[0], b[3] - b[1]
		s = int(max(w, h) * 1.08)
		cx, cy = (b[0] + b[2]) // 2, (b[1] + b[3]) // 2
		carre = Image.new("RGBA", (s, s))
		carre.paste(c.crop((cx - s // 2, cy - s // 2, cx - s // 2 + s, cy - s // 2 + s)), (0, 0))
		sortie.append(carre.resize((cote, cote), Image.LANCZOS))
	return sortie


def _interpoler(images: list[Image.Image], n: int) -> list[Image.Image]:
	"""8 images clés en boucle → n images (fondu enchaîné entre voisines, la dernière revient à la première)."""
	k = len(images)
	sortie = []
	for i in range(n):
		t = i * k / n
		a, f = int(t) % k, t - int(t)
		b = (a + 1) % k
		if f < 1e-6:
			sortie.append(images[a])
		else:
			sortie.append(Image.blend(images[a].convert("RGBa"), images[b].convert("RGBa"), f).convert("RGBA"))
	return sortie


def _atlas(images: list[Image.Image], colonnes: int) -> Image.Image:
	l = images[0].width
	lignes = (len(images) + colonnes - 1) // colonnes
	atlas = Image.new("RGBA", (colonnes * l, lignes * l))
	for i, im in enumerate(images):
		atlas.paste(im, ((i % colonnes) * l, (i // colonnes) * l))
	return atlas


def preparer() -> None:
	SORTIE.mkdir(parents=True, exist_ok=True)
	manifeste = {"flipbooks": {}, "particules": {}}
	for nom, mode, _t in _images():
		src = _revision(nom)
		if not src:
			print("manquant :", nom)
			continue
		cases = [_alpha(c, mode) for c in _cases(Image.open(src))]
		if nom.startswith("CV_FX_PART"):
			ident = next(i for i, _m, _s in PARTICULES if f"CV_FX_{i.upper()}_" in nom)
			sprites = next(s for i, _m, s in PARTICULES if i == ident)
			for (n, _d), im in zip(sprites, _recadrer(cases, PART, False)):
				if n.startswith("_"):
					continue
				im.save(SORTIE / f"p_{n}.webp", lossless=True)
				manifeste["particules"][n] = {"fichier": f"p_{n}.webp", "taille": PART, "melange": mode}
		else:
			ident = next(i for i, _m, _t2, _c in FLIPBOOKS if f"CV_FX_{i.upper()}_" in nom)
			cles = _recadrer(cases, FRAME, True)
			images = _interpoler(cles, NB_FINAL)
			_atlas(images, 4).save(SORTIE / f"fb_{ident}.webp", lossless=True)
			manifeste["flipbooks"][ident] = {"fichier": f"fb_{ident}.webp", "images": NB_FINAL, "colonnes": 4,
				"taille": FRAME, "melange": mode, "boucle": True}
		print("ok", nom, "←", src.name)
	(SORTIE / "manifeste_vague1.json").write_text(json.dumps(manifeste, indent=1, ensure_ascii=False), encoding="utf-8")


def _police(t: int) -> ImageFont.FreeTypeFont:
	for p in ("/System/Library/Fonts/Helvetica.ttc", "/System/Library/Fonts/Supplemental/Arial.ttf"):
		try:
			return ImageFont.truetype(p, t)
		except OSError:
			pass
	return ImageFont.load_default()


def _sur_fond(im: Image.Image, mode: str, fond: tuple[int, int, int]) -> Image.Image:
	"""Rendu comme dans le jeu : additif (add) ou normal (norm) sur un fond de combat sombre."""
	base = Image.new("RGBA", im.size, fond + (255,))
	if mode == "add":
		a = np.asarray(im).astype(np.float32)
		b = np.asarray(base).astype(np.float32)
		rgb = np.clip(b[..., :3] + a[..., :3] * (a[..., 3:] / 255.0), 0, 255)
		return Image.fromarray(np.dstack([rgb, np.full(im.size[::-1], 255)]).astype(np.uint8))
	base.alpha_composite(im)
	return base


def planche() -> None:
	FICHE.mkdir(parents=True, exist_ok=True)
	man = json.loads((SORTIE / "manifeste_vague1.json").read_text())
	fond = (46, 66, 52)
	petite = _police(26)
	cellule = 320
	noms = list(man["flipbooks"])
	cols = 4
	lignes = (len(noms) + cols - 1) // cols
	haut = 70
	feuille = Image.new("RGBA", (cols * cellule, haut + lignes * (cellule + 36) + 60 + 4 * 220 + 40), (24, 28, 30, 255))
	d = ImageDraw.Draw(feuille)
	d.text((16, 14), "CV.1 vague 1 — flipbooks (images fixes à l'image 6 ; boucles dans les GIF) et particules", font=_police(30), fill=(235, 235, 220))
	gifs = {}
	for k, n in enumerate(noms):
		m = man["flipbooks"][n]
		atlas = Image.open(SORTIE / m["fichier"])
		fr = [atlas.crop(((i % 4) * m["taille"], (i // 4) * m["taille"], (i % 4 + 1) * m["taille"], (i // 4 + 1) * m["taille"])) for i in range(m["images"])]
		rendus = [_sur_fond(f, m["melange"], fond).convert("RGB") for f in fr]
		x, y = (k % cols) * cellule, haut + (k // cols) * (cellule + 36)
		feuille.paste(rendus[5].resize((cellule, cellule)), (x, y))
		d.text((x + 8, y + cellule + 4), f"{n} [{m['melange']}]", font=petite, fill=(235, 235, 220))
		gifs[n] = rendus
		rendus[0].save(FICHE / f"{n}.gif", save_all=True, append_images=rendus[1:], duration=62, loop=0)
	# particules
	y0 = haut + lignes * (cellule + 36) + 10
	d.text((16, y0), "Particules", font=_police(28), fill=(235, 235, 220))
	x = 10
	y = y0 + 40
	for n, m in man["particules"].items():
		im = Image.open(SORTIE / m["fichier"])
		r = _sur_fond(im, m["melange"], fond).convert("RGB")
		if x + 200 > feuille.width:
			x, y = 10, y + 220
		feuille.paste(r, (x, y))
		d.text((x + 2, y + 194), n, font=_police(18), fill=(235, 235, 220))
		x += 200
	feuille = feuille.crop((0, 0, feuille.width, y + 230)).convert("RGB")
	feuille.save(FICHE / "planche.png")
	# vidéo : tous les flipbooks en boucle, en mosaïque
	print("planche et GIF dans", FICHE)


if __name__ == "__main__":
	a = sys.argv[1:]
	if a[:1] == ["--prompts"]:
		prompts()
	elif a[:1] == ["--preparer"]:
		preparer()
	elif a[:1] == ["--planche"]:
		planche()
	else:
		generer(a)
