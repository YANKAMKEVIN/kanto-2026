#!/usr/bin/env python3
"""Série 10 — Route 2 sud (jalon 8, lumière neutre). Liste exacte : docs/tech/jalon-08.md §1.2.

Consigne de Kevin (T2) : le plus petit kit modulaire qui donne la sensation de la vue validée
(`docs/design/reference/route-2-vue-generale-v1.png`, essai 3) sans effet répétitif. Presque tout
est repris (Route 1, Bourg Palette, Jadielle) ou obtenu par variation ; ne sont générés que :
  - WORLD_BLDG_POSTE_FORET_01   façade du poste sud de la Forêt de Jade (réutilisée au J9) ;
  - WORLD_PROP_GRANDE_PIERRE_01 grande pierre claire, repère unique de C2 ;
  - PNJ_RANDONNEUSE (+ RANDONNEUSE_ATTENTE) : P1, planche de marche 4 × 4 et planche d'attente.
CONDITIONNELS (jamais lancés sans leur nom, seulement si la capture du T5 le demande) :
WORLD_PROP_ARBRE_DENSE_01 (FUTUR A), WORLD_PROP_POKEBALL_SOL_01 (Ball au sol),
WORLD_GROUND_SOUS_BOIS_01 (planche de décalcomanies de lisière).

Références : recadrages REF_R2_* de la vue validée (`--refs`, reproductibles : boîtes ci-dessous,
agrandies × 3 comme REF_R1_*). Ancres de style : assets validés de la série 08 et l'arbre A.
Sources et sorties dans $ART (défaut : build/art de cette copie ; sur une autre copie que le
checkout principal, ART=/Users/kevinyankam/dev/kanto-2026/build/art, où sont les ancres).

Usage :
  tools/art/serie10.py --refs                 recadre les REF_R2_* dans $ART (sans Codex)
  tools/art/serie10.py --planche [sortie.png] planche de contrôle du kit (sans Codex ;
                                              défaut build/art/R2_KIT_v1.png)
  tools/art/serie10.py --manifeste            ajoute les entrées de la série 10 en fin de
                                              tools/art/manifeste.json (idempotent ; au T3,
                                              une fois les images validées)
  tools/art/serie10.py [IDENTIFIANT ...]      génère avec Codex (sans argument : la série,
                                              sans les conditionnels ; --refs fait d'abord)
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
from serie06 import ADN, LUMIERE_NE, OBJET_FIN, RACINE  # noqa: E402

ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
VUE = RACINE / "docs/design/reference/route-2-vue-generale-v1.png"
ATTENTE = ICI / "attente" / "prompts" / "RANDONNEUSE_ATTENTE.txt"

## Recadrages de la vue validée (1024 × 1536, ≈ 24 px par case), en pixels de la vue.
REFS = {
	"REF_R2_POSTE": (380, 90, 640, 270),
	"REF_R2_GRANDE_PIERRE": (630, 480, 770, 590),
	"REF_R2_RANDONNEUSE": (630, 660, 740, 770),
	"REF_R2_ARBRE_DENSE": (0, 340, 240, 530),
	"REF_R2_POKEBALL": (215, 800, 290, 870),
	"REF_R2_LISIERE": (120, 180, 640, 640),
	"REF_R2_BARRIERE": (770, 980, 940, 1120),
	"REF_R2_CLOTURES": (290, 1380, 730, 1470),
	"REF_R2_ENCLOS": (770, 470, 970, 660),
	# Écarts de la vue volontairement non reproduits (dossier 11, « Vue générale peinte v1 »).
	"REF_R2_SECOND_REBORD": (460, 930, 640, 1000),
}
AGRANDIR = 3

STYLE = ["WORLD_PROP_SOUCHE_01_NE_r1.png", "WORLD_TREE_A_01_NE_r1.png"]

## (identifiant, référence, largeur en cases, description, ancres supplémentaires).
SERIE = [
	("WORLD_BLDG_POSTE_FORET_01", "REF_R2_POSTE", 7,
		"poste d'entrée de la Forêt de Jade, petit bâtiment-porte de plain-pied posé en travers du "
		"chemin, plus large que profond : toit à deux pans d'ARDOISES gris-bleu en rangées régulières, "
		"débordant ; murs de PIERRE claire appareillée en blocs gris-beige ; structure de poutres de bois "
		"brun (poteaux d'angle, linteau) ; au MILIEU du bas de la façade, une large entrée ouverte d'une "
		"case de large sous un linteau de bois, l'intérieur sombre et vide (ni porte, ni personnage) ; "
		"aucune fenêtre côté façade, aucune enseigne, aucun texte. Robuste et accueillant, à la lisière "
		"d'une forêt : un peu de mousse au pied des murs. Sans arbres, sans chemin, sans panneau.",
		["WORLD_BLDG_MAISON_B_01_NE_r1.png"]),
	("WORLD_PROP_GRANDE_PIERRE_01", "REF_R2_GRANDE_PIERRE", 3,
		"une grande pierre claire isolée, repère d'une clairière : UN SEUL gros bloc arrondi et lisse "
		"(bloc erratique), gris très clair un peu chaud, plus large que haut, quelques facettes douces "
		"et fissures fines, un peu de lichen pâle ; base posée dans l'herbe mais l'herbe n'est PAS "
		"dessinée. Pas un amas de rochers anguleux.", []),
]

## Conditionnels : (identifiant, référence, largeur, description, ancres).
CONDITIONNELS = [
	("WORLD_PROP_ARBRE_DENSE_01", "REF_R2_ARBRE_DENSE", 1.2,
		"petit arbre buissonnant très dense qui bouche un sentier : tronc court presque caché, "
		"branches épaisses et serrées, feuillage vert sombre en boules compactes, plus petit et plus "
		"trapu qu'un arbre de forêt (environ 1,6 case de haut) ; clairement infranchissable.",
		["WORLD_TREE_FORET_PLANCHE_A_NE_r1.png"]),
	("WORLD_PROP_POKEBALL_SOL_01", "REF_R2_POKEBALL", 0.42,
		"une Poké Ball rouge et blanche posée au sol, vue de face et un peu de dessus comme le jeu, "
		"bande noire et bouton blanc au centre, reflet doux ; seule.", []),
]
PLANCHE_SOUS_BOIS = ("WORLD_GROUND_SOUS_BOIS_01",
	"PLANCHE de 8 petites décalcomanies de sous-bois de lisière à semer sur une herbe ombragée, vues "
	"strictement de DESSUS, à plat : grille invisible de 4 colonnes × 2 lignes dans une image 1024 × 512 "
	"(cellules de 256 × 256), un élément centré par cellule, sans cadre ni séparation. Ligne 1 : touffe de "
	"fougères vert sombre ; jeune fougère plus claire ; tapis de mousse ; feuilles mortes brunes éparses. "
	"Ligne 2 : herbe haute et sombre de lisière ; petites racines qui affleurent ; brindilles et aiguilles ; "
	"deux petits champignons bruns discrets. Chaque élément fait environ 140 px, posé sur RIEN : fond avec "
	"une vraie transparence (canal alpha), aucun sol, aucune ombre portée. Couleurs sourdes et froides.")

RANDONNEUSE = ("une randonneuse d'une vingtaine d'années, en route vers la Forêt de Jade : chapeau de "
	"paille clair à bande bleu marine, longs cheveux châtains, chemise à manches courtes vert sauge, short "
	"de randonnée bleu marine, gros sac à dos orange-brun, chaussures de marche brunes, bâton de marche en "
	"bois dans la main droite. Différente de la Dresseuse de Jadielle (veste orange, serre-tête jaune) : "
	"pas de veste orange.")

## Entrées du manifeste (ajoutées au T3 par --manifeste, en fin de chaque section).
MANIFESTE = {
	"objets": [
		{"id": "bldg_poste_foret_01", "source": "WORLD_BLDG_POSTE_FORET_01_NE_r1.png",
			"sortie": "assets/world/buildings/bldg_poste_foret_01.png", "axe": "w", "cases": 7,
			"ombre": True, "contact": 0.12},
		{"id": "prop_grande_pierre_01", "source": "WORLD_PROP_GRANDE_PIERRE_01_NE_r1.png",
			"sortie": "assets/world/props/prop_grande_pierre_01.png", "axe": "w", "cases": 3,
			"ombre": False, "contact": 0.1},
		# Variation sans Codex : 3 des 4 cases de la clôture blanche validée (coupe au milieu d'un
		# intervalle : se raccorde comme l'original).
		{"id": "prop_cloture_piquets_01_court", "source": "WORLD_PROP_CLOTURE_PIQUETS_01_NE_r1.png",
			"recadrage": [47, 430, 917, 903],
			"sortie": "assets/world/props/prop_cloture_piquets_01_court.png", "axe": "w", "cases": 3,
			"ombre": False, "contact": 0.3},
	],
	"images_objets": [
		# Variation sans Codex : la Poké Ball de la commode du joueur (série 07), détachée.
		{"id": "poke_ball_ground", "source": "INT_COMMODE_POKEBALL_01_NE_r1.png",
			"recadrage": [367, 285, 594, 512], "masque": "disque",
			"sortie": "assets/sprites/objects/painted/poke_ball_ground.png", "hauteur": 40},
	],
	"personnages": [
		{"id": "randonneuse", "source": "PNJ_RANDONNEUSE_NE_r1.png",
			"sortie": "assets/sprites/characters/painted/randonneuse_sheet.png", "hauteur": 128},
	],
	"attentes": [
		{"id": "randonneuse_idle", "source": "RANDONNEUSE_ATTENTE_r1.png",
			"sortie": "assets/sprites/characters/painted/randonneuse_idle_sheet.png",
			"marche": "randonneuse"},
	],
}


# --- Références -------------------------------------------------------------------------

def references() -> None:
	vue = Image.open(VUE).convert("RGB")
	ART.mkdir(parents=True, exist_ok=True)
	for nom, boite in REFS.items():
		ref = vue.crop(boite)
		ref = ref.resize((ref.width * AGRANDIR, ref.height * AGRANDIR), Image.LANCZOS)
		ref.save(ART / f"{nom}.png")
	print(f"{len(REFS)} références REF_R2_* dans {ART}")


# --- Génération (Codex) -----------------------------------------------------------------

def _prompt_objet(identifiant: str, ref: str, largeur, description: str, ancres: list[str]) -> str:
	noms = " et ".join(Path(a).stem for a in STYLE + ancres)
	jointes = (f"Images jointes : {ref} = référence de forme, de matériaux et de couleurs, extraite de la "
		"vue d'ensemble de la Route 2 : dessine l'objet comme s'il avait été extrait de cette image puis "
		f"agrandi, avec le même angle, mais avec la finesse des ancres. {noms} = ancres de style de la "
		"série (rendu peint, contour coloré, finesse, même angle de vue, même lumière neutre).")
	corps = (f"ASSET : {description}\nFormat : PNG carré 1024 × 1024 ; l'objet occupe environ 900 px dans sa "
		f"plus grande dimension, centré. Échelle : {largeur} cases de large.\n{OBJET_FIN}")
	return (f"{identifiant} — NOUVELLE image : un seul asset de jeu isolé, pas une scène.\n{jointes}\n\n"
		f"{ADN}\n{LUMIERE_NE}\n\n{corps}\n")


def _prompt_planche(identifiant: str, description: str) -> str:
	return (f"{identifiant} — NOUVELLE image : une planche d'éléments de jeu, pas une scène.\nImages jointes : "
		"REF_R2_LISIERE = ambiance de la lisière (couleurs) ; WORLD_PROP_SOUCHE_01_NE_r1 et "
		"WORLD_TREE_A_01_NE_r1 = ancres de style (rendu peint, contour coloré, finesse, lumière neutre)."
		f"\n\n{ADN}\n{LUMIERE_NE}\n\nEXCEPTION à la règle « Isolement » : plusieurs éléments séparés sur une "
		f"même planche.\n{description}\nInterdit : texte, chiffres, cadres, personnage, Pokémon, ombre portée.\n")


def _prompt_randonneuse() -> str:
	modele = (ART / "prompts" / "PNJ_MARCHAND_NE_r1.txt").read_text()
	debut, reste = modele.split("PERSONNAGE (identique dans toutes les images) : ", 1)
	fin = reste.split("\n", 1)[1]
	debut = debut.replace("PNJ_MARCHAND", "PNJ_RANDONNEUSE").replace(
		"(le héros validé) :", "(le héros validé) ; REF_R2_RANDONNEUSE = tenue seulement (petite, vue de "
		"dos, rendu à NE PAS copier) :")
	return debut + f"PERSONNAGE (identique dans toutes les images) : {RANDONNEUSE}\n" + fin


def _lancer(nom: str, texte: str, jointes: list[Path]) -> str:
	"""Codex (tools/art/generer.sh) ; l'image arrive dans build/art de cette copie, puis dans $ART."""
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	manquantes = [str(j) for j in jointes if not j.exists()]
	if manquantes:
		return f"{nom} : ÉCHEC, images jointes absentes : {', '.join(manquantes)}"
	(ART / "prompts").mkdir(parents=True, exist_ok=True)
	fichier = ART / "prompts" / f"{nom}.txt"
	fichier.write_text(texte)
	resultat = subprocess.run([str(ICI / "generer.sh"), nom, str(fichier), *map(str, jointes)],
		cwd=RACINE, capture_output=True, text=True)
	if resultat.returncode != 0:
		return f"{nom} : ÉCHEC {resultat.stderr.strip()[-200:]}"
	sortie = RACINE / "build" / "art" / f"{nom}.png"
	if sortie.resolve() != (ART / f"{nom}.png").resolve():
		shutil.copy2(sortie, ART / f"{nom}.png")
	return f"{nom} : ok"


def _objet(entree) -> str:
	identifiant, ref, largeur, description, ancres = entree
	jointes = [ART / f"{ref}.png"] + [ART / a for a in STYLE + ancres]
	return _lancer(f"{identifiant}_NE_r1", _prompt_objet(identifiant, ref, largeur, description, ancres),
		jointes)


def _randonneuse() -> str:
	ligne = _lancer("PNJ_RANDONNEUSE_NE_r1", _prompt_randonneuse(),
		[ART / "PERSO_P2_PEINT_r1.png", ART / "REF_R2_RANDONNEUSE.png"])
	# L'attente se calque sur la planche de marche (méthode de tools/art/attente).
	attente = _lancer("RANDONNEUSE_ATTENTE_r1", ATTENTE.read_text(), [ART / "PNJ_RANDONNEUSE_NE_r1.png"])
	return f"{ligne}\n{attente}"


def _taches(choix: set[str]):
	for entree in SERIE:
		if not choix or entree[0] in choix:
			yield lambda e=entree: _objet(e)
	if not choix or "PNJ_RANDONNEUSE" in choix:
		yield _randonneuse
	for entree in CONDITIONNELS:
		if entree[0] in choix:
			yield lambda e=entree: _objet(e)
	if PLANCHE_SOUS_BOIS[0] in choix:
		identifiant, description = PLANCHE_SOUS_BOIS
		yield lambda: _lancer(f"{identifiant}_NE_r1", _prompt_planche(identifiant, description),
			[ART / "REF_R2_LISIERE.png"] + [ART / s for s in STYLE])


# --- Manifeste --------------------------------------------------------------------------

def _fin_de_liste(texte: str, section: str) -> int:
	"""Position du « ] » qui ferme la liste « section » du manifeste (crochets hors chaînes)."""
	debut = texte.index(f'"{section}": [') + len(f'"{section}": ')
	profondeur, dans_chaine, echappe = 0, False, False
	for i in range(debut, len(texte)):
		c = texte[i]
		if dans_chaine:
			echappe = c == "\\" and not echappe
			if c == '"' and not echappe:
				dans_chaine = False
			continue
		if c == '"':
			dans_chaine = True
		elif c == "[":
			profondeur += 1
		elif c == "]":
			profondeur -= 1
			if profondeur == 0:
				return i
	raise ValueError(section)


def manifeste() -> None:
	"""Ajoute les entrées absentes en fin de section, **par insertion de texte** : la mise en
	forme manuelle du manifeste (tableaux sur une ligne) reste intacte."""
	chemin = ICI / "manifeste.json"
	texte = chemin.read_text()
	m = json.loads(texte)
	ajouts = 0
	for section, entrees in MANIFESTE.items():
		presents = {e["id"] for e in m.get(section, [])}
		nouvelles = [e for e in entrees if e["id"] not in presents]
		if not nouvelles:
			continue
		blocs = ",\n".join("  " + json.dumps(e, ensure_ascii=False, indent=1).replace("\n", "\n  ")
			for e in nouvelles)
		if section in m:
			fin = _fin_de_liste(texte, section)
			avant = texte[:fin].rstrip()
			separateur = "," if not avant.endswith("[") else ""
			texte = f"{avant}{separateur}\n{blocs}\n {texte[fin:]}"
		else:
			fin = texte.rstrip().rindex("}")
			texte = f'{texte[:fin].rstrip()},\n "{section}": [\n{blocs}\n ]\n{texte[fin:]}'
		ajouts += len(nouvelles)
	json.loads(texte)  # toujours du JSON valide
	chemin.write_text(texte)
	print(f"manifeste : {ajouts} entrée(s) de la série 10 ajoutée(s)")


# --- Planche de contrôle (sans Codex) ---------------------------------------------------

CASE_PLANCHE = 48  # 1 case du jeu (96 px) = 48 px sur la planche : tailles relatives justes.
FOND = (74, 118, 66)


def _police(taille: int):
	for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Helvetica.ttc",
			"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
		if Path(chemin).exists():
			return ImageFont.truetype(chemin, taille)
	return ImageFont.load_default()


def _asset(relatif: str) -> Image.Image:
	"""Asset du jeu à l'échelle de la planche (les images du jeu sont à 1:1, 96 px par case)."""
	image = Image.open(RACINE / relatif).convert("RGBA")
	return image.resize((max(1, image.width // 2), max(1, image.height // 2)), Image.LANCZOS)


def _teinter(image: Image.Image, rvb: tuple[float, float, float]) -> Image.Image:
	r, v, b, a = image.split()
	r = r.point(lambda x: min(255, round(x * rvb[0])))
	v = v.point(lambda x: min(255, round(x * rvb[1])))
	b = b.point(lambda x: min(255, round(x * rvb[2])))
	return Image.merge("RGBA", (r, v, b, a))


def _echelle(image: Image.Image, facteur: float) -> Image.Image:
	return image.resize((max(1, round(image.width * facteur)), max(1, round(image.height * facteur))),
		Image.LANCZOS)


def _miroir(image: Image.Image) -> Image.Image:
	return image.transpose(Image.FLIP_LEFT_RIGHT)


def _cellule_perso(relatif: str) -> Image.Image:
	"""Première pose (de face) d'une planche 4 × 4, à l'échelle de la planche."""
	image = Image.open(RACINE / relatif).convert("RGBA")
	pose = image.crop((0, 0, image.width // 4, image.height // 4))
	return pose.resize((pose.width // 2, pose.height // 2), Image.LANCZOS)


def _ref(nom: str, hauteur: int) -> Image.Image:
	image = Image.open(VUE).convert("RGBA").crop(REFS[nom])
	return _echelle(image, hauteur / image.height)


class _Planche:
	TITRE = ("Route 2 — kit de la série 10 (T2, jalon 8) : 1 case = 48 px sur cette planche ; "
		"héros à l'échelle")

	def __init__(self, largeur: int, titre: str = "") -> None:
		self.largeur = largeur
		self.titre = titre or self.TITRE
		self.blocs: list[tuple[str, list[tuple[Image.Image, str]], tuple[int, int, int]]] = []

	def section(self, titre: str, elements: list[tuple[Image.Image, str]], couleur) -> None:
		self.blocs.append((titre, elements, couleur))

	def rendre(self) -> Image.Image:
		titre_p, etiquette_p = _police(30), _police(15)
		marge, ecart, haut_etiq = 24, 22, 40
		mises: list = []
		y = 90
		for titre, elements, couleur in self.blocs:
			mises.append(("titre", titre, couleur, y))
			y += 50
			x, ligne_h = marge, 0
			for image, texte in elements:
				large = max(image.width, *(round(etiquette_p.getlength(m)) for m in texte.split("\n")))
				if x + large > self.largeur - marge and x > marge:
					y += ligne_h + haut_etiq + ecart
					x, ligne_h = marge, 0
				mises.append(("image", image, texte, (x, y)))
				x += large + ecart
				ligne_h = max(ligne_h, image.height)
			y += ligne_h + haut_etiq + 40
		planche = Image.new("RGBA", (self.largeur, y), FOND + (255,))
		d = ImageDraw.Draw(planche)
		d.text((marge, 24), self.titre, font=_police(34), fill=(255, 255, 255))
		# Hauteurs alignées par rangée : le bas des images sur une même ligne.
		rangs: dict[int, int] = {}
		for m in mises:
			if m[0] == "image":
				rangs[m[3][1]] = max(rangs.get(m[3][1], 0), m[1].height)
		for m in mises:
			if m[0] == "titre":
				_, titre, couleur, ty = m
				d.rectangle((0, ty - 6, self.largeur, ty + 40), fill=couleur)
				d.text((marge, ty), titre, font=titre_p, fill=(255, 255, 255))
			else:
				_, image, texte, (ix, iy) = m
				base = iy + rangs[iy]
				planche.alpha_composite(image, (ix, base - image.height))
				for i, morceau in enumerate(texte.split("\n")[:2]):
					d.text((ix, base + 4 + i * 17), morceau, font=etiquette_p, fill=(255, 255, 240))
		return planche


def planche(sortie: Path) -> Path:
	heros = (_cellule_perso("assets/sprites/characters/painted/heros_sheet.png"), "héros (échelle)")
	w = "assets/world/"
	p = _Planche(2600)

	p.section("1. RÉUTILISÉS TELS QUELS (déjà dans le jeu)", [
		heros,
		*[(_asset(f"{w}props/tree_foret_0{i}.png"), f"tree_foret_0{i}\nforêt serrée") for i in range(1, 9)],
		(_asset(f"{w}props/tree_a_01.png"), "tree_a_01\nrepère C1 ouest"),
		(_asset(f"{w}props/tree_c_01.png"), "tree_c_01\nrepère C1 est"),
		(_asset(f"{w}props/tree_b_01.png"), "tree_b_01\nlisière nord"),
		(_asset(f"{w}props/tree_e_01.png"), "tree_e_01\nlisière nord"),
		(_asset(f"{w}props/prop_buisson_a_01_bourg.png"), "buisson_a _bourg"),
		(_asset(f"{w}props/prop_buisson_b_01_bourg.png"), "buisson_b _bourg"),
		(_asset(f"{w}props/prop_buisson_c_01_bourg.png"), "buisson_c _bourg"),
		(_asset(f"{w}ground/ground_hautes_herbes_jaune_01.png"), "hautes herbes\njaune-vert H1-H3"),
		(_asset(f"{w}relief/relief_rebord_01.png"), "rebord ×3"),
		(_asset(f"{w}props/prop_souche_01.png"), "souche (O3)"),
		(_asset(f"{w}props/prop_panneau_01.png"), "panneau ×3"),
		(_asset(f"{w}props/prop_cloture_piquets_v_01.png"), "piquets_v\nbarrière FUTUR B"),
		(_asset(f"{w}props/prop_ronces_01.png"), "ronces\nlisière"),
		(_asset(f"{w}props/prop_tronc_couche_01.png"), "tronc couché\nlisière"),
		(_asset(f"{w}props/prop_pierres_01.png"), "pierres"),
		*[(_echelle(_asset(f"{w}ground/decals/decal_fleur_{i}.png"), 1.6), f"fleur_{i}") for i in range(1, 9)],
		*[(_echelle(_asset(f"{w}ground/decals/decal_touffe_{i}.png"), 1.0), f"touffe_{i}") for i in (1, 2)],
		*[(_echelle(_asset(f"{w}ground/decals/decal_pave_{i}.png"), 1.0), f"pave_{i}") for i in (1, 2)],
		(_cellule_perso("assets/sprites/characters/painted/jeune_dresseur_sheet.png"), "Jeune Dresseur\n(P2)"),
		(_cellule_perso("assets/sprites/pokemon/painted/roucool_sheet.png"), "Roucool ×2"),
		(_cellule_perso("assets/sprites/pokemon/painted/rattata_sheet.png"), "Rattata"),
		(_cellule_perso("assets/sprites/pokemon/painted/nidoran_f_sheet.png"), "Nidoran ♀"),
		(_cellule_perso("assets/sprites/pokemon/painted/nidoran_m_sheet.png"), "Nidoran ♂ (P2)"),
	], (40, 90, 50))

	# 2. Variations.
	arbre = _asset(f"{w}props/tree_foret_03.png")
	rangees = [(y, 1.0 if y >= 30 else 0.72 + 0.28 * max(0.0, y - 8) / 22) for y in (40, 30, 20, 12, 4)]
	variations = [(_teinter(arbre, (v * 0.97 if y < 30 else v, v, min(1.0, v * 1.04) if y < 30 else v)),
		f"forêt rangée {y}\nvaleur ×{v:.2f}") for y, v in rangees]
	variations.append((_teinter(_echelle(_asset(f"{w}props/tree_foret_08.png"), 0.55), (0.66, 0.74, 0.74)),
		"FUTUR A = foret_08\n× 0,55, assombri"))
	buisson = _asset(f"{w}props/prop_buisson_a_01_bourg.png")
	variations += [(_teinter(_miroir(buisson), (0.9, 0.92, 0.95)), "buisson miroir\n+ teinte"),
		(_teinter(_echelle(buisson, 1.12), (0.8, 0.84, 0.9)), "buisson ×1,12\nlisière sombre")]
	herbe = _asset(f"{w}ground/ground_hautes_herbes_jaune_01.png")
	variations.append((_teinter(herbe, (0.84, 0.88, 0.9)), "H3 un peu\nplus sombre"))
	ombre = _asset(f"{w}props/tree_a_01_shadow.png")
	tache = Image.new("RGBA", ombre.size, (16, 26, 40, 0))
	tache.putalpha(ombre.getchannel("A").point(lambda a: round(a * 0.5)))
	variations.append((_echelle(tache, 2.0), "ombre de canopée\n(ombre de tree_a)"))
	sys.path.insert(0, str(ICI))
	from preparer import _recadrer, _silhouette  # noqa: E402
	sources = Path(os.environ.get("ART", RACINE / "build" / "art"))
	for entree in MANIFESTE["objets"] + MANIFESTE["images_objets"]:
		if "recadrage" not in entree:
			continue
		source = sources / entree["source"]
		if not source.exists():
			source = Path("/Users/kevinyankam/dev/kanto-2026/build/art") / entree["source"]
		if not source.exists():
			continue
		image = _silhouette(_recadrer(Image.open(source).convert("RGBA"), entree))
		if "hauteur" in entree:
			image = _echelle(image, entree["hauteur"] / 2 / image.height)
		else:
			image = _echelle(image, entree["cases"] * CASE_PLANCHE / image.width)
		variations.append((image, f"{entree['id']}\n(préparation, sans Codex)"))
	p.section("2. VARIATIONS SANS NOUVEL ASSET (teinte par rangée, échelle, miroir, recadrage)",
		variations, (60, 80, 110))

	# 3. Nouveaux : références recadrées de la vue, à leur taille en jeu.
	p.section("3. NOUVEAUX (Codex, lumière NE) — référence recadrée de la vue, à la taille en jeu", [
		heros,
		(_ref("REF_R2_POSTE", round(4.6 * CASE_PLANCHE)), "WORLD_BLDG_POSTE_FORET_01\n7 × 4 cases, ombre"),
		(_ref("REF_R2_GRANDE_PIERRE", round(2.4 * CASE_PLANCHE)), "WORLD_PROP_GRANDE_PIERRE_01\n3 × 2 cases"),
		(_ref("REF_R2_RANDONNEUSE", 150), "PNJ_RANDONNEUSE (+ attente)\n128 px, marche 4 × 4"),
	], (130, 70, 40))
	p.section("3 bis. CONDITIONNELS (prompts prêts, lancés seulement si la capture du T5 le demande)", [
		(_ref("REF_R2_ARBRE_DENSE", 150), "WORLD_PROP_ARBRE_DENSE_01\nsi FUTUR A ne se lit pas"),
		(_ref("REF_R2_POKEBALL", 70), "WORLD_PROP_POKEBALL_SOL_01\nsi la Ball recadrée déçoit"),
		(_ref("REF_R2_LISIERE", 240), "WORLD_GROUND_SOUS_BOIS_01\nsi la lisière manque de sous-bois"),
	], (110, 90, 40))
	p.section("4. ABANDONNÉS (écarts de la vue, non reproduits)", [
		(_ref("REF_R2_SECOND_REBORD", 120), "second rebord sous H2\n(arbitrage 14 : un seul)"),
		(_ref("REF_R2_RANDONNEUSE", 120), "Randonneuse près de la pierre\n(reste au 1er embranchement)"),
		(_ref("REF_R2_ENCLOS", 180), "conifères isolés dans C2,\nbuissons à fleurs orange"),
		(_ref("REF_R2_BARRIERE", 140), "barrière blanche de face\n(piquets_v à la place)"),
		(_ref("REF_R2_CLOTURES", 90), "clôtures à lisses\n(piquets courts à la place)"),
	], (120, 40, 40))

	sortie.parent.mkdir(parents=True, exist_ok=True)
	p.rendre().convert("RGB").save(sortie, optimize=True)
	return sortie


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--refs" in arguments:
		references()
	elif "--planche" in arguments:
		autres = [a for a in arguments if a != "--planche"]
		print(planche(Path(autres[0]) if autres else RACINE / "build" / "art" / "R2_KIT_v1.png"))
	elif "--manifeste" in arguments:
		manifeste()
	else:
		references()
		taches = list(_taches(set(arguments)))
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(lambda t: t(), taches):
				print(ligne, flush=True)
