#!/usr/bin/env python3
"""Série 24 — complément de la série 21 du J18 pour les étages 2F à 6F de la Tour Pokémon (J19).

Fiche : docs/design/fiches-assets/serie-24-tour-etages.md. Le kit de l'intérieur de la Tour
(sol `ground_dalles_tour_01`, murs `relief_mur_tour_01..05`, escalier montant
`relief_escalier_tour_01`, tombes `int_tombe_tour_01..03`, bougeoir `int_bougeoir_tour_01`)
est produit par la série 21 du J18 (`origin/jalon-18`, `tools/art/serie21.py`) et réutilisé par
le J19. Cette série ne produit que ce que le J18 n'a pas :
  1. WORLD_PROP_ESCALIER_TOUR_DESCEND_01 → `prop_escalier_tour_descend_01` : escalier
     descendant tenu dans une case (cases `V` des grilles 3F à 6F) ;
  2. WORLD_GROUND_DALLE_PURIFIEE_01 → `ground_dalle_purifiee_01` : dalle 2 × 2 cases de la
     zone purifiée du 5F (cases `Z`), à la place du `Polygon2D` provisoire.
Valeurs et interdits : ceux de la série 21 (`VALEURS_TOUR`, `INTERDITS`, profil `tower_cold`).

Prompts versionnés : tools/art/prompts/serie24/<NOM>_rN.txt. Sources et sorties dans $ART
(défaut : build/art de cette copie) ; rien n'est écrit dans assets/.

Usage :
  tools/art/serie24.py --prompts            écrit les prompts (r1 à r3 par image)
  tools/art/serie24.py --refs               recadre la vue validée (REF_TE_*, × 3) dans $ART
  tools/art/serie24.py --commandes          liste les appels tools/art/generer.sh
  tools/art/serie24.py --preparer           prépare les essais retenus → $ART/serie24/
  tools/art/serie24.py --controle [sortie]  recompose le 5F à l'échelle du jeu
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
sys.path.insert(0, str(ICI))
from serie06 import ADN, LUMIERE_NE  # noqa: E402
import preparer  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
SORTIE = ART / "serie24"
PROMPTS = ICI / "prompts" / "serie24"
VUE = RACINE / "docs/design/reference/tour-pokemon-vue-generale-v1.png"  # 1024 × 1536
PLANS = RACINE / "tools/plans"
W = RACINE / "assets/world"
## Copie de travail du J18 : si sa planche de murs (avec `relief_escalier_tour_01`) est déjà
## générée, elle est jointe comme ancre de cohérence (essai r1).
J18_ART = Path(os.environ.get("J18_ART",
	"/Users/kevinyankam/dev/kanto-2026/.claude/worktrees/j18-t1-kit/build/art"))
J18_MURS = "WORLD_RELIEF_MUR_TOUR_PLANCHE_NE_r1.png"
CASE = 96

## Recadrages de la vue validée (px de la vue 1024 × 1536 ; une case ≈ 23 px).
REFS = {
	"REF_TE_ESCALIER": (55, 230, 130, 320),  # 2F : escalier ouest dans sa niche
	"REF_TE_ZONE": (660, 640, 880, 800),     # 5F : dalle purifiée (sans son halo)
}

## Essais retenus (mis à jour après relecture ; voir la fiche).
RETENUS = {
	"ESCALIER": "WORLD_PROP_ESCALIER_TOUR_DESCEND_01_NE_r1",
	"DALLE": "WORLD_GROUND_DALLE_PURIFIEE_01_NE_r1",
}

## Entrées proposées pour tools/art/manifeste.json (au plan d'intégration, pas ici).
ESCALIER = {"id": "prop_escalier_tour_descend_01", "axe": "w", "cases": 1, "ombre": False,
	"contact": None}
DALLE = {"id": "ground_dalle_purifiee_01", "taille": 2 * CASE}

## Repris mot pour mot de la série 21 du J18 (origin/jalon-18:tools/art/serie21.py).
VALEURS_TOUR = ("VALEURS DE LA TOUR POKÉMON (exception de palette à l'ADN : un lieu de mémoire calme et "
	"digne) : pierre de taille gris perle, gris violacé doux, lavande désaturée, bois sombre, touches "
	"de crème et de vert tendre (fleurs) ; lumière NEUTRE, diffuse et blanche (le jeu ajoute la lumière "
	"froide du lieu et la lueur des bougies : ne peins NI pénombre, NI flaque de lumière, NI halo, NI "
	"brume) ; contraste doux, aucune ombre portée. Rien d'inquiétant : ni spectre, ni crâne, ni "
	"toile d'araignée, ni fissure menaçante.")
INTERDITS = ("Interdits de la série : texte, lettres, chiffres, logo, inscription sur les tombes, AUCUN "
	"emblème rond de type balle (ni cercle partagé en deux, ni médaillon à bande centrale) sauf sur le "
	"Centre et la Boutique existants, animaux réels ou faune non-Pokémon (oiseaux, chauves-souris, "
	"insectes, araignées), Pikachu et tout Pokémon non demandé, personnage qui ressemble au héros "
	"(casquette rouge, t-shirt blanc, sac à dos jaune), squelette, crâne, fantôme, toile d'araignée, "
	"élément effrayant ou macabre, croix religieuse.")

ESCALIER_TXT = """ASSET : ESCALIER DESCENDANT de l'intérieur d'une tour de mémoire en pierre (on descend à l'étage du dessous), le pendant de l'escalier MONTANT pris dans le mur de la même tour : même pierre de taille gris perle légèrement violacée, mêmes marches, même facture. Il est posé AU SOL et TIENT DANS UNE SEULE CASE (vu de dessus en trois quarts, le carré de la case est entièrement occupé, rien ne dépasse) : une TRÉMIE CARRÉE ouverte dans le sol dallé, bordée sur trois côtés (gauche, droite, bas) d'un rebord de pierre de taille gris perle un peu plus clair, et dont l'ouverture est au HAUT de l'image ; à l'intérieur, cinq marches de pierre gris perle qui DESCENDENT vers le haut de l'image et s'enfoncent dans une ombre douce gris-violet (jamais noire, jamais de lumière au fond) ; les nez de marche s'assombrissent à mesure qu'ils descendent ; une rampe basse de pierre de chaque côté. Sobre, ancien, propre ; aucune inscription, aucune décoration.
Format : PNG CARRÉ 1024 × 1024, l'escalier vu strictement dans la vue du jeu (projection oblique frontale), le carré de la trémie et de son rebord occupe environ 90 % de l'image, centré ; bords gauche et droit verticaux, bord bas horizontal ; vraie transparence (canal alpha) autour, aucun sol dallé autour, aucune ombre portée, aucun halo."""

DALLE_TXT = """ASSET : la DALLE BÉNIE de la zone purifiée d'une tour de mémoire : un CARRÉ de 2 × 2 cases posé dans le sol de dalles gris perle de la tour, fait de QUATRE grandes dalles carrées de pierre CLAIRE NACRÉE (blanc cassé tirant sur la lavande et le bleu très pâle, reflets nacrés doux, comme de la pierre de lune polie), séparées par des joints fins gris perle en croix, et entourées d'un mince LISERÉ de pierre gris perle plus soutenu, à fleur du sol, sur tout le pourtour. Un seul ouvrage, propre, lisse et très bien entretenu, nettement plus clair que le sol gris perle de la tour. Pierre peinte dans sa propre couleur, SANS AUCUN effet lumineux : ni halo, ni rayons, ni étincelles, ni lueur, ni brume, ni particules (le jeu ajoute lui-même la lumière blanche de la zone). Aucun symbole gravé, aucune inscription.
Format : PNG carré 1024 × 1024, OPAQUE, l'ouvrage COUVRE TOUTE L'IMAGE (le liseré touche les quatre bords), vu strictement de dessus, à plat ; une dalle = 512 px ; aucune perspective, aucun objet posé dessus, aucun sol autour.
Interdit : personnage, Pokémon, objet, texte, ombre portée, vignettage, effet lumineux."""

TEXTES = {
	"WORLD_PROP_ESCALIER_TOUR_DESCEND_01_NE": ("un élément de jeu isolé, pas une scène", ESCALIER_TXT),
	"WORLD_GROUND_DALLE_PURIFIEE_01_NE": ("une dalle de sol de jeu, pas une scène", DALLE_TXT),
}
## Images jointes par essai : r1 avec les références (et la planche du J18 si elle existe),
## r2 ancres du dépôt seulement, r3 sans image (règle des refus).
ANCRES = {
	"WORLD_PROP_ESCALIER_TOUR_DESCEND_01_NE": (["REF_TE_ESCALIER"],
		[W / "props/prop_escalier_souterrain_descend_01.png",
		W / "relief/relief_mur_souterrain_01.png"]),
	"WORLD_GROUND_DALLE_PURIFIEE_01_NE": (["REF_TE_ZONE"],
		[W / "ground/ground_dalles_souterrain_01.png"]),
}
JOINTES_TXT = {
	"ref": "{ref} = forme, matériaux et couleurs, extrait de la vue d'ensemble validée de la tour (minuscule, ambiance de bougies : n'en copie ni le rendu ni la lumière)",
	"j18": "WORLD_RELIEF_MUR_TOUR_PLANCHE = les murs de CETTE tour, dont l'escalier MONTANT (dernier module) : même pierre, même main, même gris perle ; l'escalier demandé en est le pendant DESCENDANT",
	"ancres": "{ancres} = ancres de style et gabarit (rendu peint, contour coloré, finesse, angle de vue, lumière neutre) ; ne reprends pas leur couleur gris-beige",
}


def _ecrire(chemin: Path, texte: str) -> None:
	chemin.parent.mkdir(parents=True, exist_ok=True)
	chemin.write_text(texte.strip() + "\n")
	print(chemin.relative_to(RACINE))


def jointes(nom: str, r: int) -> list[str]:
	refs, ancres = ANCRES[nom]
	if r == 3:
		return []
	liste = [] if r == 2 else [str(ART / f"{n}.png") for n in refs]
	if r == 1 and nom.startswith("WORLD_PROP_ESCALIER") and (J18_ART / J18_MURS).exists():
		liste.append(str(J18_ART / J18_MURS))
	return liste + [str(a) for a in ancres]


def _phrase_jointes(nom: str, r: int) -> str:
	if r == 3:
		return "Aucune image jointe."
	refs, ancres = ANCRES[nom]
	parts = []
	if r == 1:
		parts.append(JOINTES_TXT["ref"].format(ref=" et ".join(refs)))
		if any(Path(j).name == J18_MURS for j in jointes(nom, r)):
			parts.append(JOINTES_TXT["j18"])
	parts.append(JOINTES_TXT["ancres"].format(ancres=" et ".join(Path(a).stem for a in ancres)))
	return "Images jointes : " + " ; ".join(parts) + "."


def prompts() -> None:
	for nom, (genre, corps) in TEXTES.items():
		for r in (1, 2, 3):
			texte = "\n\n".join([f"{nom[:-3]} — NOUVELLE image : {genre}.\n{_phrase_jointes(nom, r)}",
				ADN.strip(), LUMIERE_NE + "\n" + VALEURS_TOUR, corps, INTERDITS])
			_ecrire(PROMPTS / f"{nom}_r{r}.txt", texte)


def refs() -> None:
	vue = Image.open(VUE).convert("RGB")
	for nom, boite in REFS.items():
		im = vue.crop(boite)
		im = im.resize((im.width * 3, im.height * 3), Image.LANCZOS)
		im.save(ART / f"{nom}.png")
		print(ART / f"{nom}.png", im.size)


def commandes() -> None:
	for nom in TEXTES:
		for r in (1, 2, 3):
			print("tools/art/generer.sh %s_r%d %s %s" % (nom, r,
				(PROMPTS / f"{nom}_r{r}.txt").relative_to(RACINE), " ".join(jointes(nom, r))))


# --- Préparation (fonctions de tools/art/preparer.py) ----------------------------------------


def _ecrire_png(image: Image.Image, nom: str) -> None:
	SORTIE.mkdir(parents=True, exist_ok=True)
	image.save(SORTIE / f"{nom}.png")
	print(f"{nom} : {image.width} × {image.height}")


def preparer_tout() -> None:
	# 1. Escalier : silhouette, halos retirés, 1 case de large ; hauteur bornée à 1 case.
	esc = preparer.nettoyer_halos(Image.open(ART / f"{RETENUS['ESCALIER']}.png").convert("RGBA"))
	esc = preparer._silhouette(esc)
	k = min(CASE / esc.width, CASE / esc.height)
	_ecrire_png(esc.resize((round(esc.width * k), round(esc.height * k)), Image.LANCZOS),
		ESCALIER["id"])
	# 2. Dalle purifiée : 2 × 2 cases, opaque.
	dalle = Image.open(ART / f"{RETENUS['DALLE']}.png").convert("RGB")
	_ecrire_png(dalle.resize((DALLE["taille"],) * 2, Image.LANCZOS), DALLE["id"])


# --- Planche de contrôle : 5F recomposé à l'échelle du jeu -----------------------------------
## Les assets du J18 sont pris dans J18_ASSETS s'ils existent (après son T6), sinon l'art
## provisoire actuel du dépôt (celui de build_pokemon_tower_floors.gd) tient leur place.
J18_ASSETS = Path(os.environ.get("J18_ASSETS",
	"/Users/kevinyankam/dev/kanto-2026/.claude/worktrees/j18-t1-kit/assets/world"))
ROLES = {
	"sol": ("ground/ground_dalles_tour_01.png", "ground/ground_dalles_souterrain_01.png"),
	"face": ("relief/relief_mur_tour_01.png", "relief/relief_mur_souterrain_01.png"),
	"face_b": ("relief/relief_mur_tour_02.png", "relief/relief_mur_souterrain_02.png"),
	"cap": ("relief/relief_mur_tour_03.png", "relief/relief_mur_souterrain_03.png"),
	"side": ("relief/relief_mur_tour_04.png", "relief/relief_mur_souterrain_04.png"),
	"tombe": ("interiors/int_tombe_tour_02.png", "props/prop_stele_01.png"),
	"bougeoir": ("interiors/int_bougeoir_tour_01.png", "props/prop_stele_01.png"),
	"monte": ("relief/relief_escalier_tour_01.png", "props/prop_escalier_souterrain_monte_01.png"),
}


def _role(nom: str) -> tuple[Image.Image, bool]:
	neuf, ancien = ROLES[nom]
	if (J18_ASSETS / neuf).exists():
		return Image.open(J18_ASSETS / neuf).convert("RGBA"), True
	return Image.open(W / ancien).convert("RGBA"), False


def _plan(etage: str) -> tuple[list[str], list[list[str]]]:
	lignes = (PLANS / f"pokemon_tower_{etage}.txt").read_text().splitlines()
	i = next(n for n, l in enumerate(lignes) if l.startswith("GRILLE"))
	grille = []
	for l in lignes[i + 1:]:
		if l.startswith("FIN"):
			break
		grille.append(l[3:23])
	j = lignes.index("POSITIONS")
	pos = []
	for l in lignes[j + 1:]:
		if l.startswith("FIN"):
			break
		pos.append(l.split("#")[0].split())
	return grille, pos


def _pied(fond: Image.Image, im: Image.Image, cx: float, bas: float) -> None:
	fond.alpha_composite(im, (round(cx - im.width / 2), round(bas - im.height)))


def _bornee(im: Image.Image, largeur: float) -> Image.Image:
	if im.width <= largeur:
		return im
	k = largeur / im.width
	return im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)


def recomposer(etage: str) -> tuple[Image.Image, list[str]]:
	"""Étage recomposé selon les règles de build_pokemon_tower_floors.gd (faces au sud des `#` ouverts,
	couronnements au nord, côtés, tombes, stèles, escaliers, dalle purifiée), héros 128 px."""
	g, pos = _plan(etage)
	h, w = len(g), len(g[0])
	at = lambda x, y: g[y][x] if 0 <= x < w and 0 <= y < h else "#"
	mur = lambda x, y: at(x, y) == "#"
	face = lambda x, y: mur(x, y) and not mur(x, y + 1)
	cap = lambda x, y: mur(x, y) and not face(x, y) and not mur(x, y - 1)
	side = lambda x, y: mur(x, y) and not face(x, y) and (not mur(x - 1, y) or not mur(x + 1, y))
	r = {k: _role(k) for k in ROLES}
	sources = [f"{k} : {'J18' if neuf else 'provisoire'}" for k, (_, neuf) in r.items()]
	fond = Image.new("RGBA", (w * CASE, h * CASE), (38, 34, 50, 255))
	sol = r["sol"][0]
	for y in range(0, h * CASE, sol.height):
		for x in range(0, w * CASE, sol.width):
			fond.alpha_composite(sol, (x, y))
	d = ImageDraw.Draw(fond)
	for y in range(h):
		for x in range(w):
			if mur(x, y):
				d.rectangle((x * CASE, y * CASE, (x + 1) * CASE - 1, (y + 1) * CASE - 1),
					fill=(38, 34, 50, 255))
	zs = [(x, y) for y in range(h) for x in range(w) if g[y][x] == "Z"]
	if zs:
		fond.alpha_composite(Image.open(SORTIE / f"{DALLE['id']}.png").convert("RGBA"),
			(min(z[0] for z in zs) * CASE, min(z[1] for z in zs) * CASE))
	capim = r["cap"][0]
	for y in range(h):
		for x in range(w):
			if cap(x, y):
				c = capim.crop(((capim.width - CASE) // 2, 0, (capim.width + CASE) // 2, capim.height))
				fond.alpha_composite(c, (x * CASE, y * CASE))
	sim = r["side"][0]
	part = sim.crop((0, (sim.height - CASE) // 2, sim.width, (sim.height - CASE) // 2 + CASE))
	for x in range(w):
		for y in range(h):
			if side(x, y):
				if not mur(x + 1, y):
					fond.alpha_composite(part, ((x + 1) * CASE - part.width, y * CASE))
				else:
					fond.alpha_composite(part.transpose(Image.FLIP_LEFT_RIGHT), (x * CASE, y * CASE))
	n = 0
	for y in range(h):
		x = 0
		while x < w:
			if face(x, y):
				k = 2 if x + 1 < w and face(x + 1, y) else 1
				im = r["face" if n % 2 == 0 else "face_b"][0]
				if k == 1:
					im = im.crop(((im.width - CASE) // 2, 0, (im.width + CASE) // 2, im.height))
				_pied(fond, im, (x + k / 2) * CASE, (y + 1) * CASE)
				x += k
				n += 1
			else:
				x += 1
	desc = Image.open(SORTIE / f"{ESCALIER['id']}.png").convert("RGBA")
	monte = _bornee(r["monte"][0], CASE)
	for p in pos:
		if len(p) > 2 and p[1] == "escalier":
			cx, cy = map(int, p[2].split(","))
			_pied(fond, monte if "sens=monte" in p else desc, (cx + 0.5) * CASE, (cy + 1) * CASE)
	objets = [(y, x, "tombe" if g[y][x] == "T" else "bougeoir")
		for y in range(h) for x in range(w) if g[y][x] in "TS"]
	feuille = Image.open(RACINE / "assets/sprites/characters/painted/heros_idle_sheet.png")
	heros = preparer._silhouette(feuille.convert("RGBA").crop((0, 0, feuille.width // 4,
		feuille.height)))
	spawn = next(p for p in pos if len(p) > 2 and p[1] == "spawn")
	hx, hy = map(int, spawn[2].split(","))
	objets.append((hy, hx, "heros"))
	for y, x, nom in sorted(objets):
		if nom == "heros":
			_pied(fond, heros, (x + 0.5) * CASE, (y + 1) * CASE - 4)
		else:
			im = _bornee(r[nom][0], CASE)
			if nom == "tombe" and not r[nom][1]:
				im = im.resize((round(im.width * 0.62), round(im.height * 0.62)), Image.LANCZOS)
			_pied(fond, im, (x + 0.5) * CASE, (y + 1) * CASE - 6)
	return fond, sources


def _police(taille: int) -> ImageFont.ImageFont:
	for c in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(c).exists():
			return ImageFont.truetype(c, taille)
	return ImageFont.load_default()


def controle(sortie: Path) -> None:
	etage, sources = recomposer("5f")
	# Détail à 2 × : zone purifiée et escalier descendant de l'ouest (cases 2..12, 6..12).
	zoom = etage.crop((2 * CASE, 6 * CASE, 13 * CASE, 12 * CASE))
	marge, f, fp = 40, _police(34), _police(24)
	pl = Image.new("RGBA", (etage.width, etage.height + zoom.height + 4 * marge + 120),
		(24, 22, 30, 255))
	d = ImageDraw.Draw(pl)
	d.text((marge, 14), "Série 24 — Tour 5F à l'échelle du jeu (case 96 px, héros 128 px, "
		"sans voile ni halo)", fill="white", font=f)
	j18 = [x.split(" : ")[0] for x in sources if x.endswith("J18")]
	d.text((marge, 56), "Neufs : dalle purifiée (Z), escalier descendant (V). Kit du J18 : "
		+ (", ".join(j18) if j18 else "pas encore préparé, art provisoire du dépôt à sa place"),
		fill=(200, 196, 214), font=fp)
	pl.alpha_composite(etage, (0, 100))
	y = 100 + etage.height + marge
	d.text((marge, y), "Détail 1:1 : escalier descendant (3, 9), arrivée (4, 9), zone purifiée "
		"(10..11, 8..9)", fill="white", font=f)
	pl.alpha_composite(zoom, ((pl.width - zoom.width) // 2, y + 50))
	sortie.parent.mkdir(parents=True, exist_ok=True)
	pl.convert("RGB").save(sortie)
	print(sortie, pl.size)


def main() -> None:
	args = sys.argv[1:]
	ART.mkdir(parents=True, exist_ok=True)
	if not args or args[0] == "--prompts":
		prompts()
	elif args[0] == "--refs":
		refs()
	elif args[0] == "--commandes":
		commandes()
	elif args[0] == "--preparer":
		preparer_tout()
	elif args[0] == "--controle":
		controle(Path(args[1]) if len(args) > 1 else ART / "SERIE24_CONTROLE_v1.png")
	else:
		sys.exit(__doc__)


if __name__ == "__main__":
	main()
