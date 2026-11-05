#!/usr/bin/env python3
"""Sprites de combat des Dresseurs de Johto (Dante, Brace, Cenere, Ysolde, Gardiens du clan, rival et
rivale d'hiver), sur le gabarit des Champions (`entree_champions.py`) : une image paysage, à gauche debout
prêt, à droite lancer, dans la main de Pierre.

  tools/art/entree_johto.py refs            # références → build/art/johto_combat/
  tools/art/entree_johto.py prompts         # prompts → tools/art/entree_dresseurs/johto/
  tools/art/entree_johto.py generer <id> [r]
  tools/art/entree_johto.py exporter [id …] # détourage, toiles, WebP, mains → johto/mains.json

Le branchement dans `trainer_intro.json` et les données de Dresseurs vient après : voir `mains.json`.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import entree_dresseurs as ed  # noqa: E402
import entree_ordinaires as eo  # noqa: E402

RACINE = ed.RACINE
JC = ed.ART / "johto_combat"
PROMPTS = Path(__file__).resolve().parent / "entree_dresseurs" / "johto"
MONDE = RACINE / "assets" / "sprites" / "characters" / "painted"

# id → (feuille du monde, description, pose debout, geste du lancer)
PERSOS: dict[str, tuple[str, str, str, str]] = {
	"dante": ("dante", "DANTE, ancien chef d'une organisation criminelle, environ 65 ans, grand, mince, très élégant, très calme : "
		"LONG MANTEAU NOIR aux chevilles, costume anthracite, chemise noire, ÉCHARPE ROUGE SOMBRE aux bords brûlés, chaussures noires "
		"cirées, GANT NOIR à la main droite, cheveux GRIS ACIER plaqués en arrière ; CICATRICE DE BRÛLURE visible et sobre sur la moitié "
		"GAUCHE de son visage et sur sa main gauche nue",
		"droit, immobile, une main gantée posée sur le revers de son manteau, regard calme et froid",
		"geste lent et maîtrisé, le manteau qui s'ouvre, sans aucune précipitation"),
	"brace": ("brace", "BRACE, admin d'une organisation criminelle, environ 30 ans, impétueux, costaud, sourire provocant : MANTEAU COURT "
		"GRIS CENDRE ouvert, manches retroussées, t-shirt noir, gants noirs sans doigts, pantalon noir, grosses bottes noires, cheveux ROUGE "
		"VIF en brosse dressée, teint hâlé. Sans lettre, sans sigle",
		"jambes écartées, poings sur les hanches, menton levé, grand sourire provocant",
		"geste violent et enthousiaste, manteau qui claque"),
	"cenere": ("cenere", "CENERE, admin d'une organisation criminelle, environ 35 ans, mince, froide, méthodique : LONG MANTEAU STRICT GRIS "
		"CENDRE boutonné jusqu'au col, gants noirs, pantalon noir, bottines noires, cheveux GRIS CENDRE lisses au carré à frange droite, "
		"fines lunettes rectangulaires, teint très pâle, yeux gris clair. Sans lettre, sans sigle",
		"droite, une main remontant ses lunettes, l'autre bras le long du corps, regard qui calcule",
		"geste sec et précis, sans émotion, coudes serrés"),
	"ysolde": ("ysolde", "YSOLDE, maîtresse d'un clan de dresseurs de dragons, environ 32 ans, grande, droite, sévère et calme : longue TUNIQUE "
		"ANTHRACITE à col haut, CEINTURE LARGE ROUGE SOMBRE nouée, COURTE CAPE ROUGE SOMBRE sur une épaule, pantalon noir, hautes bottes de "
		"cuir noir, brassards de cuir, longue TRESSE NOIRE épaisse, teint mat. Sans armure, sans arme, aucun bleu",
		"droite comme un pilier, bras croisés, regard sévère et calme",
		"geste ample et noble, cape et tresse qui suivent le mouvement"),
	"gardien": ("clan_h", "un GARDIEN d'un clan de dragons, environ 28 ans, solide, grave : TUNIQUE SANS MANCHES ANTHRACITE sur une chemise noire, "
		"CEINTURE LARGE ROUGE SOMBRE nouée, brassards de cuir, pantalon noir, bottes noires, cheveux NOIRS très courts, teint mat. Sans cape, sans arme",
		"droit, jambes légèrement écartées, une main sur la ceinture, air grave",
		"geste puissant et sobre"),
	"gardienne": ("clan_f", "une GARDIENNE d'un clan de dragons, environ 26 ans, vive, droite : TUNIQUE SANS MANCHES ANTHRACITE sur une chemise noire, "
		"CEINTURE LARGE ROUGE SOMBRE nouée, brassards de cuir, pantalon noir, bottes noires, cheveux NOIRS en queue haute, teint mat. Sans cape, sans arme",
		"droite, une main sur la hanche, regard attentif",
		"geste vif et net, queue de cheval qui suit le mouvement"),
	"rival_hiver": ("rival_hiver", "le RIVAL du joueur en tenue d'hiver : même visage, mêmes cheveux bruns en épis que sa feuille du monde (IMAGE 3) et que "
		"son sprite de combat (IMAGE 4) ; PARKA VIOLET SOMBRE fermée, capuche bordée de fourrure grise, écharpe noire, gants noirs, pantalon noir épais, "
		"bottes de neige noires et violettes, sac à dos noir",
		"reprend la pose et l'attitude de son sprite de combat (IMAGE 4)", "reprend le lancer de son sprite de combat (IMAGE 4)"),
	"rivale_hiver": ("rivale_hiver", "la RIVALE du joueur en tenue d'hiver : même visage, même queue de cheval brune que sa feuille du monde (IMAGE 3) et que "
		"son sprite de combat (IMAGE 4) ; PARKA VIOLET SOMBRE fermée, capuche bordée de fourrure grise, écharpe noire, gants noirs, pantalon noir épais, "
		"bottes de neige noires et violettes, sac à dos noir",
		"reprend la pose et l'attitude de son sprite de combat (IMAGE 4)", "reprend le lancer de son sprite de combat (IMAGE 4)"),
}
GABARIT = """{ident} — sprites de combat de Kanto 2026 (jeu 2D HD). Images jointes : IMAGE 1 = Pierre, sprites de combat VALIDÉS (à gauche debout prêt, à droite pose de lancer) : c'est la CIBLE EXACTE du rendu, de la main, de l'échelle et du cadrage ; IMAGE 2 = un autre Dresseur validé, même main ; IMAGE 3 = l'apparence du personnage dans le monde du jeu (petit sprite de face et de profil) : sa tenue et ses couleurs font foi.

PERSONNAGE : {desc}.

À FAIRE : UNE image paysage 1536 × 1024 avec DEUX poses du même personnage côte à côte, chacune en pied, grande (environ 900 px de haut, des cheveux aux semelles), bien séparées (au moins 120 px de vide entre elles), rien de coupé par le bord, pieds tous à la même hauteur près du bas de l'image :
- À GAUCHE : pose DEBOUT PRÊT : de trois-quarts face, corps tourné vers la gauche de l'image, {debout}.
- À DROITE : pose de LANCER comme celle de Pierre (IMAGE 1, à droite) : de trois-quarts face tourné vers la gauche, fente avant (jambe gauche de l'image avancée et fléchie, l'autre tendue en arrière), bras tendu loin vers la gauche à hauteur de poitrine, main ouverte doigts écartés, la Ball VIENT DE PARTIR (main vide, pas de Ball dessinée), l'autre bras replié en arrière, {lancer}.
Mains à cinq doigts correctes, pieds entiers, même personnage, même tenue et mêmes proportions dans les deux poses.

STYLE (impératif) : exactement la main de Pierre (IMAGE 1) : illustration 2D HD « anime peint », contours fins et doux brun foncé (jamais de trait noir épais), aplats peints avec ombres douces et deux ou trois valeurs par matériau, légère granularité de pinceau, proportions réalistes-stylisées (PAS chibi), lumière neutre et douce venant de la gauche.

FOND : TRANSPARENT (vrai canal alpha), aucun damier dessiné, aucun décor, aucun sol, aucune ombre portée, aucun halo, aucun texte, aucune lettre, aucun cadre, aucune Poké Ball.
"""


def _duo(a: Path, b: Path, sortie: Path) -> None:
	i, j = Image.open(a).convert("RGBA"), Image.open(b).convert("RGBA")
	t = Image.new("RGBA", (i.width + j.width + 40, max(i.height, j.height)), (0, 0, 0, 0))
	t.alpha_composite(i, (0, 0))
	t.alpha_composite(j, (i.width + 40, 0))
	t.save(sortie)


def _monde(feuille: str, sortie: Path) -> None:
	s = Image.open(MONDE / f"{feuille}_sheet.png").convert("RGBA")
	w, h = s.width // 4, s.height // 4
	t = Image.new("RGBA", (w * 2 + 10, h), (0, 0, 0, 0))
	t.alpha_composite(s.crop((0, 0, w, h)), (0, 0))
	t.alpha_composite(s.crop((0, h, w, 2 * h)), (w + 10, 0))
	t.resize((t.width * 3, t.height * 3), Image.LANCZOS).save(sortie)


def refs() -> None:
	JC.mkdir(parents=True, exist_ok=True)
	_duo(ed.SPR / "pierre.webp", ed.SPR / "pierre_lancer.webp", JC / "ref_pierre.png")
	_duo(ed.SPR / "giovanni.webp", ed.SPR / "giovanni_lancer.webp", JC / "ref_giovanni.png")
	_duo(ed.SPR / "rival.webp", ed.SPR / "rival_lancer.webp", JC / "ref_rival.png")
	_duo(ed.SPR / "rivale.webp", ed.SPR / "rivale_lancer.webp", JC / "ref_rivale.png")
	for ident, p in PERSOS.items():
		_monde(p[0], JC / f"ref_monde_{ident}.png")


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for ident, (_, desc, debout, lancer) in PERSOS.items():
		(PROMPTS / f"{ident}_sprites.txt").write_text(GABARIT.format(ident="EJ_" + ident.upper(), desc=desc, debout=debout, lancer=lancer))


def generer(ident: str, rev: str = "1") -> int:
	j = [JC / "ref_pierre.png", JC / "ref_giovanni.png", JC / f"ref_monde_{ident}.png"]
	if ident.endswith("_hiver"):
		j.append(JC / ("ref_rival.png" if ident == "rival_hiver" else "ref_rivale.png"))
	return subprocess.call([str(RACINE / "tools" / "art" / "generer.sh"), f"EJ_{ident}_r{rev}",
		str(PROMPTS / f"{ident}_sprites.txt"), *[str(p) for p in j]], cwd=RACINE)


RETENUS: dict[str, str] = {}


def exporter(idents: list[str]) -> None:
	f = PROMPTS / "mains.json"
	mains = json.loads(f.read_text()) if f.exists() else {}
	for ident in idents or list(PERSOS):
		p = ed.ART / f"EJ_{ident}_r{RETENUS.get(ident, '1')}.png"
		if not p.exists():
			print("absent", ident)
			continue
		poses = eo._poses_rangee(ed._nettoyer(Image.open(p).convert("RGBA")))
		print(ident, [i.size for i in poses])
		if len(poses) < 2:
			continue
		debout, lancer = ed.poses_en_toile(poses[0], poses[-1], (512, 768), 16)
		ed._webp(debout, ed.SPR / f"{ident}.webp")
		ed._webp(lancer, ed.SPR / f"{ident}_lancer.webp")
		mains[ident] = list(eo.main_du_lancer(lancer))
	f.write_text(json.dumps(mains, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	act = sys.argv[1]
	if act == "refs":
		refs()
	elif act == "prompts":
		prompts()
	elif act == "generer":
		sys.exit(generer(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "1"))
	elif act == "exporter":
		exporter(sys.argv[2:])
