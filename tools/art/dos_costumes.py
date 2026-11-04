#!/usr/bin/env python3
"""Dos peints du joueur en combat pour la joueuse et les costumes (2026-11-04, Kevin : les costumes
« ont encore l'ancienne pose pour le lancer de Poké Ball »). Même recette que le héros (fiche
docs/design/fiches-assets/entree-dresseurs.md §2 et §13) : une génération Codex = DEUX poses côte à
côte (à gauche prête, à droite lancer), découpées, mises en toile, exportées en WebP.

  tools/art/dos_costumes.py refs                       # références → build/art/dos_costumes/
  tools/art/dos_costumes.py prompts                    # prompts → tools/art/dos_costumes/
  tools/art/dos_costumes.py generer <cible> [rev]      # ex. heroine_terre, roche_joueur_surf
  tools/art/dos_costumes.py exporter [cible ...]       # → assets/sprites/trainers/battle/…
  tools/art/dos_costumes.py planche [cible ...]        # planche de validation (build/art/dos_costumes/)

Cibles : `heroine_terre` (dos_heroine, dos_heroine_lancer), puis pour chaque costume de
data/costumes.json et chaque version : `<art>_<joueur|joueuse>_terre` et `<…>_surf` →
`dos_costume_<art>_<version>[_surf][_lancer].webp` (à côté de `dos_hero`). Toiles : à pied 640 × 960 (pieds en bas), en
Surf 960 × 960 (bas = ligne d'eau), comme `dos_hero` et `dos_hero_surf`.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import entree_dresseurs as ed  # noqa: E402
import entree_finitions as ef  # noqa: E402
import entree_ordinaires as eo  # noqa: E402

RACINE = ed.RACINE
ART = RACINE / "build" / "art" / "dos_costumes"
PROMPTS = Path(__file__).resolve().parent / "dos_costumes"
MONDE = RACINE / "assets" / "sprites" / "characters" / "painted"
COSTUMES = MONDE / "costumes"
SPR = ed.SPR
TOILE_TERRE = (640, 960)
TOILE_SURF = ef.TOILE_SURF
VERSIONS = ("joueur", "joueuse")
LOOK_DE = {"joueur": "hero", "joueuse": "heroine"}

TERRE = """{ident} — sprites de combat de Kanto 2026 (jeu 2D HD) : {qui}, vu DE DOS, au premier plan d'un combat de Dresseur. Images jointes : IMAGE 1 = les sprites de combat VALIDÉS du HÉROS de dos (à gauche debout prêt, à droite pose de lancer) : CIBLE EXACTE du rendu, de la taille, de la vue de dos de trois-quarts et des DEUX poses, à reprendre à l'identique avec {qui_court} à la place du héros ; IMAGE 2 = {ref2} ; IMAGE 3 = {ref3}.

PERSONNAGE : {perso}

À FAIRE : UNE image PAYSAGE 1536 × 1024 avec DEUX poses côte à côte, bien séparées (au moins 120 px de vide entre elles), grandes (environ 880 px de haut chacune, du haut de la tête aux semelles), pieds posés sur une même ligne près du bas, rien de coupé par les bords. Dans les deux poses, la même vue que IMAGE 1 : {qui_court} DE DOS, de trois-quarts, tourné vers la DROITE et le haut de l'image (l'adversaire est en haut à droite), on voit surtout le dos, la nuque et un peu du profil.
- À GAUCHE : pose PRÊTE comme IMAGE 1 à gauche : jambes écartées et fléchies, en garde, les deux poings serrés devant, le buste tourné vers la droite.
- À DROITE : pose de LANCER comme IMAGE 1 à droite : le buste qui pivote, le bras droit tendu loin vers la DROITE et vers le haut, main ouverte doigts écartés, la Ball VIENT DE PARTIR (main vide, pas de Ball dessinée), l'autre bras replié vers l'arrière, une jambe en avant.
Même personnage, même tenue et mêmes proportions dans les deux poses. Mains à cinq doigts correctes. La tenue reste celle du personnage (IMAGES 2 et 3) : ne lui ajoute NI casquette rouge, NI sac à dos jaune s'il n'en porte pas.

{style}

{fond}
"""

SURF = """{ident} — sprites de combat de Kanto 2026 (jeu 2D HD) : {qui} sur sa monture de Surf, vu DE DOS, au premier plan d'un combat en mer. Images jointes : IMAGE 1 = les sprites de combat VALIDÉS du HÉROS sur la monture, de dos (à gauche prêt, à droite pose de lancer) : CIBLE EXACTE du rendu, de la monture, de la taille, de la vue de dos de trois-quarts et des DEUX poses, à reprendre à l'identique avec {qui_court} à la place du héros ; IMAGE 2 = {ref2} ; IMAGE 3 = {ref3}.

PERSONNAGE : {perso}
MONTURE : {monture}.

À FAIRE : UNE image PAYSAGE 1536 × 1024 avec DEUX poses côte à côte, bien séparées (au moins 100 px de vide entre elles), grandes (environ 760 px de haut chacune, du haut de la tête à la ligne d'eau), rien de coupé par les bords. Exactement la composition d'IMAGE 1 : {qui_court} DE DOS, de trois-quarts, ASSIS À CALIFOURCHON sur le dos de la monture, qui nage vers la droite et le haut de l'image ; seul le haut de la monture émerge.
- À GAUCHE : pose PRÊTE : une main posée à plat sur le dos de la monture, l'autre poing serré devant la poitrine, le buste tourné vers la droite.
- À DROITE : pose de LANCER : le buste qui pivote, le bras droit tendu loin vers la DROITE et vers le haut, main ouverte doigts écartés, la Ball VIENT DE PARTIR (main vide, pas de Ball dessinée), l'autre main agrippée au dos de la monture.
Même personnage, même tenue, même monture et mêmes proportions dans les deux poses. Mains à cinq doigts correctes. La tenue reste celle du personnage (IMAGES 2 et 3) : ne lui ajoute NI casquette rouge, NI sac à dos jaune s'il n'en porte pas.

{eau}

{style}

{fond}
"""

STYLE = ("STYLE (impératif) : exactement la main des sprites du héros joints (IMAGE 1) : illustration "
	"2D HD « anime peint », contours fins et doux brun foncé (jamais de trait noir épais), aplats "
	"peints avec ombres douces et deux ou trois valeurs par matériau, légère granularité de pinceau, "
	"proportions réalistes-stylisées d'un enfant d'environ 11 ans (PAS chibi, même gabarit que le "
	"héros), lumière neutre et douce venant de la gauche.")
FOND_TERRE = ("FOND : TRANSPARENT (vrai canal alpha), aucun damier dessiné, aucun décor, aucun sol, "
	"aucune ombre portée, aucun texte, aucune lettre, aucun cadre, aucune Poké Ball.")

JOUEUSE = ef.JOUEUSE.replace("IMAGE 3 : son apparence fait foi", "IMAGES 2 et 3 : son apparence fait foi")


def costumes() -> list[dict]:
	return json.loads((RACINE / "data" / "costumes.json").read_text(encoding="utf-8"))["costumes"]


def cibles() -> list[str]:
	sortie = ["heroine_terre"]
	for c in costumes():
		for v in VERSIONS:
			sortie += [f"{c['art']}_{v}_terre", f"{c['art']}_{v}_surf"]
	return sortie


def _decoder(cible: str) -> tuple[str, str, str]:
	"""(art, version, terrain) ; art = "" pour la joueuse sans costume."""
	if cible == "heroine_terre":
		return "", "joueuse", "terre"
	art, version, terrain = cible.rsplit("_", 2)
	return art, version, terrain


def _badge(badge_id: str) -> str:
	badges = json.loads((RACINE / "data" / "badges.json").read_text(encoding="utf-8"))["badges"]
	return next(b["name"] for b in badges if b["id"] == badge_id)


def _nom(costume: dict, version: str) -> str:
	return costume["names"][LOOK_DE[version]]


def _costume(art: str) -> dict:
	return next(c for c in costumes() if c["art"] == art)


def sorties(cible: str) -> tuple[Path, Path]:
	art, version, terrain = _decoder(cible)
	suffixe = "_surf" if terrain == "surf" else ""
	if not art:
		base = SPR / "dos_heroine"
	else:
		base = SPR / f"dos_costume_{art}_{version}"
	return Path(f"{base}{suffixe}.webp"), Path(f"{base}{suffixe}_lancer.webp")


# --- Références ----------------------------------------------------------------------------------

def refs() -> None:
	ART.mkdir(parents=True, exist_ok=True)
	ef._cote([SPR / "dos_hero.webp", SPR / "dos_hero_lancer.webp"]).save(ART / "ref_dos_hero.png")
	ef._cote([SPR / "dos_hero_surf.webp", SPR / "dos_hero_surf_lancer.webp"]).save(
		ART / "ref_dos_hero_surf.png")
	Image.open(MONDE / "joueuse_portrait.png").convert("RGBA").save(ART / "ref_joueuse_portrait.png")
	Image.open(MONDE / "joueuse_lancer.png").convert("RGBA").save(ART / "ref_joueuse_lancer.png")
	for c in costumes():
		for v in VERSIONS:
			base = f"{c['art']}_{v}"
			buste = COSTUMES / f"{base}_bust.webp"
			lancer = COSTUMES / f"{base}_lancer.png"
			Image.open(buste).convert("RGBA").save(ART / f"ref_{base}_buste.png")
			Image.open(lancer).convert("RGBA").save(ART / f"ref_{base}_lancer.png")
	print(f"références → {ART.relative_to(RACINE)}")


def jointes(cible: str) -> list[Path]:
	art, version, terrain = _decoder(cible)
	premiere = ART / ("ref_dos_hero_surf.png" if terrain == "surf" else "ref_dos_hero.png")
	if not art:
		return [premiere, ART / "ref_joueuse_portrait.png", ART / "ref_joueuse_lancer.png"]
	base = f"{art}_{version}"
	return [premiere, ART / f"ref_{base}_buste.png", ART / f"ref_{base}_lancer.png"]


# --- Prompts -------------------------------------------------------------------------------------

def _perso(art: str, version: str) -> tuple[str, str, str]:
	"""(qui, qui_court, description) du personnage."""
	if not art:
		return "la JOUEUSE (le joueur, apparence féminine)", "la joueuse", JOUEUSE
	c = _costume(art)
	nom = _nom(c, version)
	genre = "le JOUEUR" if version == "joueur" else "la JOUEUSE"
	court = "le personnage"
	desc = (f"{genre} du jeu portant son COSTUME « {nom} » (déguisement d'un personnage célèbre, "
		f"débloqué par le {_badge(c['badge'])}) : IMAGE 2 (buste de face) et IMAGE 3 (le même costume vu "
		"de dos, ancienne pose) font foi pour la coiffure, la tenue, les accessoires et les couleurs ; "
		"même âge (environ 11 ans) et même gabarit que le héros d'IMAGE 1.")
	return f"{genre} en costume « {nom} »", court, desc


def prompt(cible: str) -> str:
	art, version, terrain = _decoder(cible)
	qui, qui_court, perso = _perso(art, version)
	ident = "DC_" + cible.upper()
	if not art:
		ref2 = "la JOUEUSE en pied, de face (portrait validé) : son visage, ses cheveux et sa tenue font foi"
		ref3 = "la JOUEUSE de dos dans son ANCIENNE pose de lancer (à remplacer) : sa tenue vue de dos fait foi"
	else:
		ref2 = "le BUSTE de face du personnage en costume : coiffure, visage, tenue et couleurs font foi"
		ref3 = ("le personnage en costume vu de DOS dans son ANCIENNE pose de lancer (à remplacer) : sa "
			"tenue vue de dos fait foi, pas sa pose")
	if terrain == "surf":
		return SURF.format(ident=ident, qui=qui, qui_court=qui_court, perso=perso, ref2=ref2, ref3=ref3,
			monture=ef.MONTURE, eau=ef.EAU, style=STYLE, fond=ef.FOND)
	return TERRE.format(ident=ident, qui=qui, qui_court=qui_court, perso=perso, ref2=ref2, ref3=ref3,
		style=STYLE, fond=FOND_TERRE)


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for cible in cibles():
		(PROMPTS / f"{cible}.txt").write_text(prompt(cible), encoding="utf-8")
	print(f"{len(cibles())} prompts → {PROMPTS.relative_to(RACINE)}")


def generer(cible: str, rev: str = "1") -> int:
	if cible not in cibles():
		sys.exit(f"cible inconnue : {cible}")
	(PROMPTS / f"{cible}.txt").write_text(prompt(cible), encoding="utf-8")
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), f"dos_costumes/DC_{cible}_r{rev}",
		str(PROMPTS / f"{cible}.txt"), *[str(p) for p in jointes(cible)]]
	return subprocess.call(cmd, cwd=RACINE)


# --- Export --------------------------------------------------------------------------------------

def source(cible: str) -> Path:
	"""La dernière révision générée de la cible (DC_<cible>_r<n>.png), ou celle de RETENUES."""
	if cible in RETENUES:
		return ART / f"DC_{cible}_r{RETENUES[cible]}.png"
	revs = sorted(ART.glob(f"DC_{cible}_r*.png"), key=lambda p: int(p.stem.rsplit("_r", 1)[1]))
	if not revs:
		sys.exit(f"pas d'image générée pour {cible}")
	return revs[-1]


## Révision retenue par cible quand ce n'est pas la dernière (après relecture).
RETENUES: dict[str, int] = {}


def _poses(chemin: Path) -> tuple[Image.Image, Image.Image]:
	im = ed._nettoyer(Image.open(chemin).convert("RGBA"))
	poses = eo._poses_rangee(im)
	if len(poses) < 2:
		poses = ef._separer_eau(im)
	return poses[0], poses[-1]


def exporter(liste: list[str]) -> None:
	for cible in liste:
		_art, _version, terrain = _decoder(cible)
		debout, lancer = _poses(source(cible))
		toile = TOILE_SURF if terrain == "surf" else TOILE_TERRE
		debout, lancer = ed.poses_en_toile(debout, lancer, toile, 16)
		chemin, chemin_lancer = sorties(cible)
		ed._webp(debout, chemin)
		ed._webp(lancer, chemin_lancer)


def planche(liste: list[str]) -> Path:
	"""Rangée par cible : ancienne pose (référence), nouvelle pose prête, nouveau lancer ; même
	hauteur, fond gris neutre, comme les planches de validation de la fiche."""
	h = 360
	rangees = []
	for cible in liste:
		art, version, _terrain = _decoder(cible)
		ancienne = MONDE / "joueuse_lancer.png" if not art else COSTUMES / f"{art}_{version}_lancer.png"
		images = [Image.open(ancienne).convert("RGBA")]
		images += [Image.open(p).convert("RGBA") for p in sorties(cible)]
		cellules = []
		for im in images:
			boite = im.getbbox()
			im = im.crop(boite)
			im = im.resize((max(1, round(im.width * h / im.height)), h), Image.LANCZOS)
			cellules.append(im)
		rangees.append((cible, cellules))
	largeur = max(sum(c.width + 40 for c in cs) for _, cs in rangees) + 300
	out = Image.new("RGB", (largeur, (h + 40) * len(rangees)), (58, 58, 66))
	d = ImageDraw.Draw(out)
	try:
		f = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 24)
	except OSError:
		f = ImageFont.load_default()
	for r, (cible, cellules) in enumerate(rangees):
		y = r * (h + 40) + 20
		d.text((12, y + h // 2 - 12), cible, fill=(240, 220, 160), font=f)
		x = 300
		for i, c in enumerate(cellules):
			out.paste(c, (x, y), c)
			if i == 0:
				d.text((x, y - 18), "ancienne", fill=(200, 200, 200), font=f)
			x += c.width + 40
	chemin = ART / "planche.png"
	out.save(chemin)
	print(chemin.relative_to(RACINE))
	return chemin


def main() -> None:
	act = sys.argv[1] if len(sys.argv) > 1 else ""
	args = sys.argv[2:]
	if act == "refs":
		refs()
	elif act == "prompts":
		prompts()
	elif act == "generer":
		sys.exit(generer(args[0], args[1] if len(args) > 1 else "1"))
	elif act == "exporter":
		exporter(args or cibles())
	elif act == "planche":
		planche(args or cibles())
	elif act == "cibles":
		print("\n".join(cibles()))
	else:
		sys.exit(__doc__)


if __name__ == "__main__":
	main()
