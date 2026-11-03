#!/usr/bin/env python3
"""Étape 3 de l'entrée des combats de Dresseur : les autres grands combats (fiche
docs/design/fiches-assets/entree-dresseurs.md §11) : le rival (et la rivale), le Conseil des 4,
les décors de leurs lieux. Giovanni est déjà peint (étape 2, tools/art/entree_champions.py).

  tools/art/entree_grands_combats.py refs                  # références → build/art/grands/
  tools/art/entree_grands_combats.py prompts               # prompts → tools/art/entree_dresseurs/grands/
  tools/art/entree_grands_combats.py generer rival sprites [r] [--seul]   # ou « buste »
  tools/art/entree_grands_combats.py decor ligue_olga [r]  # composition d'un décor (Codex)
  tools/art/entree_grands_combats.py tuile ligue_olga TL   # tuile repeinte en plus grand (Codex)
  tools/art/entree_grands_combats.py exporter [id ...]     # détourage, toiles, WebP (fiche §1, §3)

Mêmes gabarits de prompts que les Champions (entree_champions.SPRITES / BUSTE) : la cible du rendu
est Pierre (debout, lancer, buste « VS ») ; IMAGE 3 = apparence du monde du personnage (portrait
peint du rival, sinon les deux premières images de sa feuille du monde agrandies).
Décors : recette de tools/art/combat_decors/preparer_decor.py (composition ≈ 1846 × 852, deux tuiles
repeintes en plus grand, couture, réduction ; jamais d'agrandissement), manifeste
tools/art/combat_decors/decors.json.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import entree_champions as ec  # noqa: E402
import entree_dresseurs as ed  # noqa: E402

RACINE = ed.RACINE
GR = ed.ART / "grands"
PROMPTS = Path(__file__).resolve().parent / "entree_dresseurs" / "grands"
MONDE = ec.MONDE

# id → (référence du monde : fichier peint ou feuille, description, pose debout, détail du lancer)
GRANDS: dict[str, tuple] = {
	"rival": ("rival_portrait.png",
		"le RIVAL du joueur, garçon d'environ 15 ans (même âge que le joueur), mince et sûr de lui, "
		"cheveux CHÂTAINS en épis hérissés, yeux gris sombre, sourire en coin arrogant ; t-shirt NOIR, "
		"GILET VIOLET sans manches à capuche (liserés blancs), pendentif argenté ovale sur une chaîne, "
		"petit sac à dos noir aux bretelles violettes, pantalon NOIR ample, baskets VIOLETTES et "
		"blanches (exactement comme son portrait du monde, IMAGE 3).",
		"bras croisés sur la poitrine comme sur IMAGE 3, poids sur une jambe, tête tournée vers la "
		"gauche, sourire narquois",
		"geste désinvolte et sûr de lui, mèches qui bougent"),
	"rivale": ("rivale_portrait.png",
		"la RIVALE du joueur, fille d'environ 15 ans (même âge que le joueur), mince et sûre d'elle, "
		"longs cheveux CHÂTAINS en épis noués en haute QUEUE DE CHEVAL (chouchou violet), mèches "
		"hérissées sur le front, yeux gris sombre, sourire en coin arrogant ; t-shirt NOIR, GILET "
		"VIOLET sans manches à capuche (liserés blancs), pendentif argenté ovale sur une chaîne, petit "
		"sac à dos noir aux bretelles violettes, pantalon NOIR ample, baskets VIOLETTES et blanches "
		"(exactement comme son portrait du monde, IMAGE 3).",
		"bras croisés sur la poitrine comme sur IMAGE 3, poids sur une jambe, tête tournée vers la "
		"gauche, sourire narquois",
		"queue de cheval qui suit le mouvement, geste désinvolte et sûr d'elle"),
	"olga": ("olga_sheet.png",
		"Olga, membre du Conseil des Quatre de la Ligue Pokémon (type Glace), femme d'environ 25 ans, "
		"grande, élancée et élégante, cheveux BLEU NUIT coupés en carré court avec frange, fines "
		"LUNETTES rondes, regard calme et glacial ; long MANTEAU BLEU GLACIER clair jusqu'aux genoux, "
		"col et poignets de FOURRURE BLANCHE, ceinture argentée à boucle ronde, bottes BLANCHES (comme "
		"son sprite du monde, IMAGE 3).",
		"une main remontant ses lunettes du bout des doigts, l'autre bras le long du corps, posture "
		"droite, tête tournée vers la gauche, demi-sourire froid",
		"pans du manteau qui s'ouvrent, geste précis et froid"),
	"aldo": ("aldo_sheet.png",
		"Aldo, membre du Conseil des Quatre de la Ligue Pokémon (type Combat), homme d'environ 35 ans, "
		"TRÈS GRAND et colossal (plus massif encore que Major Bob), cheveux NOIRS courts en brosse, "
		"sourcils épais, mâchoire carrée, air sévère ; haut de KARATÉGI BLANC aux manches arrachées, "
		"ouvert sur des pectoraux musclés, CEINTURE NOIRE nouée, pantalon de karatégi ORANGE, bandes "
		"BLANCHES aux avant-bras et aux poignets, sandales de paille (comme son sprite du monde, "
		"IMAGE 3).",
		"poings serrés en garde de karaté, jambes fléchies bien ancrées, épaules massives, tête tournée "
		"vers la gauche, regard dur",
		"lancer puissant, muscles tendus, kimono qui claque"),
	"agatha": ("agatha_sheet.png",
		"Agatha, membre du Conseil des Quatre de la Ligue Pokémon (type Spectre), femme TRÈS ÂGÉE "
		"(environ 80 ans), PETITE et un peu voûtée, cheveux GRIS-BLANC relevés en chignon, rides "
		"marquées, sourire malicieux et inquiétant ; longue ROBE VIOLET SOMBRE, CHÂLE NOIR sur les "
		"épaules, CANNE en bois sombre (comme son sprite du monde, IMAGE 3).",
		"les deux mains posées sur le pommeau de sa canne devant elle, dos un peu voûté, tête tournée "
		"vers la gauche, sourire rusé",
		"elle lance du bras droit, la canne gardée dans l'autre main, châle qui flotte, geste vif "
		"malgré l'âge"),
	"peter": ("peter_sheet.png",
		"Peter, membre du Conseil des Quatre de la Ligue Pokémon (type Dragon), homme d'environ 30 ans, "
		"grand et charismatique, cheveux ROUX VIF en épis, regard perçant ; longue CAPE NOIRE doublée "
		"d'ORANGE à col haut, veste BLEU MARINE à boutons et passepoils DORÉS, ceinture brune, pantalon "
		"BLANC CASSÉ, bottes brunes (comme son sprite du monde, IMAGE 3).",
		"un bras tendu sur le côté qui écarte la cape, l'autre main sur la ceinture, jambes écartées, "
		"tête tournée vers la gauche, regard assuré",
		"cape qui claque derrière lui"),
}

# Révision retenue par (id, pose) ; absente = r1.
RETENUS: dict[tuple[str, str], str] = {}


def refs() -> None:
	GR.mkdir(parents=True, exist_ok=True)
	ec.refs()  # ref_pierre_poses.png et ref_pierre_buste.png dans build/art/champions/
	for ident, (monde, *_r) in GRANDS.items():
		f = Image.open(MONDE / monde).convert("RGBA")
		if monde.endswith("_sheet.png"):
			cw, chh = f.width // 4, f.height // 4
			r = Image.new("RGBA", (cw * 2 + 10, chh), (0, 0, 0, 0))
			r.alpha_composite(f.crop((0, 0, cw, chh)), (0, 0))
			r.alpha_composite(f.crop((0, chh, cw, 2 * chh)), (cw + 10, 0))
			f = r.resize((r.width * 4, r.height * 4), Image.LANCZOS)
		f.save(GR / f"ref_monde_{ident}.png")


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for ident, (_monde, desc, debout, lancer) in GRANDS.items():
		m = (" ; IMAGE 3 = son apparence dans le monde du jeu : sa coiffure, sa tenue et ses couleurs "
			"font foi")
		(PROMPTS / f"{ident}_sprites.txt").write_text(ec.SPRITES.format(ident=f"EG_{ident.upper()}",
			monde=m, desc=desc, debout=debout, lancer=lancer)
			.replace("pose DEBOUT PRÊT de Champion", "pose DEBOUT PRÊT"), encoding="utf-8")
		desc_b = desc.replace(" (comme son sprite du monde, IMAGE 3)", "") \
			.replace(" (exactement comme son portrait du monde, IMAGE 3)", "")
		(PROMPTS / f"{ident}_buste.txt").write_text(ec.BUSTE.format(ident=f"EG_BUSTE_{ident.upper()}",
			desc=desc_b), encoding="utf-8")


def jointes(ident: str, pose: str) -> list[Path]:
	if pose == "sprites":
		return [ec.CH / "ref_pierre_poses.png", ec.CH / "ref_pierre_buste.png",
			GR / f"ref_monde_{ident}.png"]
	png = GR / f"ref_debout_{ident}.png"
	Image.open(ed.SPR / f"{ident}.webp").convert("RGBA").save(png)
	return [ec.CH / "ref_pierre_buste.png", png]


def generer(ident: str, pose: str, rev: str = "1", seul: bool = False) -> int:
	j = [] if seul else [str(p) for p in jointes(ident, pose)]
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), f"EG_{ident}_{pose}_r{rev}",
		str(PROMPTS / f"{ident}_{pose}.txt"), *j]
	return subprocess.call(cmd, cwd=RACINE)


def _source(ident: str, pose: str) -> Image.Image | None:
	p = ed.ART / f"EG_{ident}_{pose}_r{RETENUS.get((ident, pose), '1')}.png"
	return Image.open(p).convert("RGBA") if p.exists() else None


def _composante(a: np.ndarray, y: int, x: int) -> np.ndarray:
	"""Composante connexe (8-connexité) du masque [param a] qui contient (y, x)."""
	c = np.zeros_like(a)
	c[y, x] = True
	while True:
		g = c.copy()
		g[1:] |= c[:-1]
		g[:-1] |= c[1:]
		g[:, 1:] |= g[:, :-1]
		g[:, :-1] |= g[:, 1:]
		g &= a
		if (g == c).all():
			return c
		c = g


def _separer(im: Image.Image) -> list[Image.Image]:
	"""Deux poses qui se chevauchent en x (cape de Peter) : chaque pose = composante connexe de son
	pixel opaque le plus à gauche (pose debout) ou le plus à droite (lancer) ; les bribes détachées
	sont jetées."""
	im = ed._nettoyer(im)
	a = np.asarray(im)[..., 3] > 8
	ys, xs = np.where(np.asarray(im)[..., 3] > 96)
	sorties = []
	for k in (int(np.argmin(xs)), int(np.argmax(xs))):
		arr = np.asarray(im).copy()
		arr[..., 3] = np.where(_composante(a, ys[k], xs[k]), arr[..., 3], 0)
		p = Image.fromarray(arr)
		sorties.append(p.crop(p.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()))
	return sorties


def exporter(idents: list[str]) -> None:
	for ident in idents or list(GRANDS):
		s = _source(ident, "sprites")
		if s is not None:
			p = ec._poses(s)
			if len(p) == 1:
				p = _separer(s)
			print(ident, "poses", [i.size for i in p])
			if len(p) >= 2:
				debout, lancer = ed.poses_en_toile(p[0], p[-1], (512, 768), 16)
				ed._webp(debout, ed.SPR / f"{ident}.webp")
				ed._webp(lancer, ed.SPR / f"{ident}_lancer.webp")
		b = _source(ident, "buste")
		if b is not None:
			ed._webp(ec._buste(b), ed.VS / f"{ident}.webp")


def decor(ident: str, rev: str = "1") -> int:
	"""Composition d'un décor (prompt entree_dresseurs/grands/decor_<id>.txt) : IMAGE 1 = Argenta v3,
	IMAGE 2 = ancien fond du lieu s'il est fidèle au lieu (DECOR_ANCIENS)."""
	GR.mkdir(parents=True, exist_ok=True)
	j = []
	for nom in ["pewter_gym_roche_v3"] + ([DECOR_ANCIENS[ident]] if ident in DECOR_ANCIENS else []):
		png = GR / f"ref_decor_{Path(nom).stem}.png"
		src = RACINE / nom if "/" in nom else DECOR_DIR / f"{nom}_back.webp"
		Image.open(src).convert("RGB").save(png)
		j.append(str(png))
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), f"EG_DECOR_{ident.upper()}_r{rev}",
		str(PROMPTS / f"decor_{ident}.txt"), *j]
	return subprocess.call(cmd, cwd=RACINE)


# Portions des tuiles : celles des Champions (composition ≈ 1846 × 852, chevauchement 154 px).
def portions(ident: str, rev: str = "1") -> dict[str, tuple[int, int, int, int]]:
	w, h = Image.open(ed.ART / f"EG_DECOR_{ident.upper()}_r{rev}.png").size
	return {"TL": (0, 0, 1000, h), "TR": (w - 1000, 0, w, h)}


def tuile(ident: str, cote: str, rev: str = "1") -> int:
	nom = f"EG_DECOR_{ident.upper()}_r{rev}"
	src = ed.ART / f"{nom}_{cote}_src.png"
	Image.open(ed.ART / f"{nom}.png").convert("RGB").crop(portions(ident, rev)[cote]).save(src)
	# Prompt propre au fond s'il existe (grands/tuile_<id>.txt), sinon celui des Champions.
	propre = PROMPTS / f"tuile_{ident}.txt"
	prompt = propre if propre.exists() else \
		Path(__file__).resolve().parent / "entree_dresseurs" / "champions" / "tuile_decor.txt"
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), f"{nom}_{cote}", str(prompt), str(src)]
	return subprocess.call(cmd, cwd=RACINE)


DECOR_DIR = RACINE / "assets" / "battle" / "decors"
# Décor repeint → ancien fond du même lieu joint en IMAGE 2 (les salles de la Ligue n'en ont pas :
# leurs anciens fonds étaient empruntés à d'autres lieux, DAF.10d).
DECOR_ANCIENS: dict[str, str] = {"sylphe": "silph_co_bureaux", "repaire": "rocket_hideout_repaire",
	"tour": "tour_pokemon", "ss_anne": "ss_anne_salon",
	# Le labo n'avait aucun fond (repli : carte floutée) : référence validée du lieu.
	"labo": "docs/design/reference/labo-chen-v1.png",
	# Route 22 (demande de Kevin, 2026-11-02) : fond propre, d'après la planche validée ; prompt
	# écrit à la main (extérieur), entree_dresseurs/grands/decor_route_22.txt.
	"route_22": "docs/design/reference/route-22-rival-02-v1.webp",
	# Étape 4 (classes ordinaires, « Mer, Route 17, Manoir », 2026-11-03) : vues générales validées ;
	# prompts tools/art/entree_dresseurs/grands/ecrire_decors_ordinaires.py.
	"mer": "docs/design/reference/route-19-vue-generale-v1.png",
	"route_17": "docs/design/reference/route-17-vue-generale-v1-t2.png",
	"manoir": "docs/design/reference/manoir-vue-generale-v1.png"}


if __name__ == "__main__":
	act = sys.argv[1]
	if act == "refs":
		refs()
	elif act == "prompts":
		prompts()
	elif act == "generer":
		args = [a for a in sys.argv[2:] if a != "--seul"]
		sys.exit(generer(args[0], args[1], args[2] if len(args) > 2 else "1", "--seul" in sys.argv))
	elif act == "decor":
		sys.exit(decor(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "1"))
	elif act == "tuile":
		sys.exit(tuile(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else "1"))
	elif act == "exporter":
		exporter(sys.argv[2:])
