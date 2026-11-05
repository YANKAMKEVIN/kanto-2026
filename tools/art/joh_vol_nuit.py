#!/usr/bin/env python3
"""JOH1, remise en scène du vol (demande de Kevin du 2026-11-04 : « voir le joueur dormir vraiment »).

Quatre assets Codex, chacun calqué sur un asset VALIDÉ du jeu (gabarit) :
  - JOH_LIT_DORMEUR_HEROS / JOH_LIT_DORMEUR_JOUEUSE : le lit de la chambre (int_lit_01) avec le héros
    ou la joueuse couché, endormi ; identité = leurs sprites peints validés ; oreiller sans Poké Ball ;
  - JOH_TABLE_STARTERS_VIDE : la table de laboratoire d'Orme, socles vides (aucune Poké Ball la nuit) ;
  - JOH_PLATEAU_POKEBALLS : le plateau des Poké Balls du comptoir, emporté par les Sbires.
Gabarits : `build/art/` du dépôt principal (images Codex validées, non versionnées) ou `assets/`.
Écrit `prompts/joh_vol_nuit/<ID>_r<N>.txt` puis lance `generer.sh` (3 en parallèle).
Usage : tools/art/joh_vol_nuit.py [--tour N] [IDENTIFIANT ...]
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from serie06 import ADN, LUMIERE_NE  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
PRINCIPAL = Path("/Users/kevinyankam/dev/kanto-2026/build/art")
PERSOS = RACINE / "assets/sprites/characters/painted"
PROMPTS = Path(__file__).parent / "prompts" / "joh_vol_nuit"

HEROS = ("le HÉROS du jeu (garçon d'environ 11 ans, cheveux châtain foncé en bataille, t-shirt blanc à "
	"manches courtes) tel qu'il est sur les sprites joints")
JOUEUSE = ("la JOUEUSE du jeu (fille d'environ 11 ans, cheveux châtain foncé ondulés jusqu'aux épaules, "
	"t-shirt blanc à manches courtes) telle qu'elle est sur les sprites joints")

FOND = ("Fond : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun halo. Même format, "
	"même cadrage et même taille d'objet que l'IMAGE 1.")


def lit(qui: str, casquette: str) -> str:
	return f"""IMAGE 1 : INT_LIT_01_NE_r1, le lit VALIDÉ de la chambre (asset du jeu). C'est le GABARIT : reproduis EXACTEMENT ce lit (bois, montants, tête de lit, couette à grands carreaux bleus et blancs, angle de vue, taille, cadrage, rendu peint, lumière neutre).
IMAGE 2 et IMAGE 3 : les sprites peints VALIDÉS du personnage (planche d'attente et portrait). C'est l'IDENTITÉ : visage, coiffure, couleurs, même main de peintre.

À FAIRE : le même lit que l'IMAGE 1, avec {qui} COUCHÉ DEDANS ET ENDORMI, vu exactement de la même vue de dessus de trois quarts que le lit :
- couché sur le dos, la tête posée au milieu de l'oreiller (en haut du lit), le visage tourné vers le haut de l'image et légèrement vers nous, yeux fermés (deux petits arcs), bouche paisible, joues roses ; on lit tout de suite « il dort » ;
- la couette à carreaux est remontée jusqu'à la poitrine et dessine le relief du corps jusqu'au pied du lit ; les deux bras, en t-shirt blanc, reposent sur la couette ;
- l'oreiller est blanc et UNI : le coussin à motif de Poké Ball de l'IMAGE 1 est retiré (aucune Poké Ball dans l'image) ;
- {casquette} ; pas de sac à dos, pas de chaussures ;
- même échelle que les sprites : la tête a la même taille que celle des sprites joints posés à côté du lit.
{FOND}
Interdits : texte, lettres, chiffres, « Zzz », bulle, Poké Ball, Pokémon, autre personnage, décor, sol, ombre portée, pixel art, 3D, contours noirs épais."""


ASSETS = {
	"JOH_LIT_DORMEUR_HEROS": (
		lit(HEROS, "sans casquette (cheveux visibles) : sa casquette rouge à visière blanche est accrochée au "
			"montant gauche de la tête de lit"),
		[PRINCIPAL / "INT_LIT_01_NE_r1.png", PERSOS / "heros_idle_sheet.png", PERSOS / "heros_portrait.png"]),
	"JOH_LIT_DORMEUR_JOUEUSE": (
		lit(JOUEUSE, "sans chapeau (cheveux étalés sur l'oreiller) : son chapeau rouge à bord blanc est accroché "
			"au montant gauche de la tête de lit"),
		[PRINCIPAL / "INT_LIT_01_NE_r1.png", PERSOS / "joueuse_idle_sheet.png",
			PERSOS / "joueuse_portrait.png"]),
	"JOH_TABLE_STARTERS_VIDE": (
		"""IMAGE 1 : INT_TABLE_STARTERS_01_NE_r1, la table de laboratoire VALIDÉE (asset du jeu). C'est le GABARIT : reproduis EXACTEMENT cette table (plateau métallique, tiroirs, trois socles, bloc-notes, angle, taille, cadrage, rendu, lumière).
À FAIRE : la même table, mais les trois socles sont VIDES : aucune Poké Ball dessus (on voit le creux arrondi de chaque socle). Le bloc-notes reste. Rien d'autre ne change.
""" + FOND + "\nInterdits : texte, lettres, chiffres, Poké Ball, personnage, Pokémon, décor, sol, ombre portée, pixel art, 3D.",
		[PRINCIPAL / "INT_TABLE_STARTERS_01_NE_r1.png"]),
	"JOH_PLATEAU_POKEBALLS": (
		"""IMAGE 1 : INT_CENTRE_COMPTOIR_NE_r1, le comptoir VALIDÉ du Centre Pokémon (asset du jeu) : ANCRE DE STYLE (rendu peint, contour coloré, couleurs rouge, blanc et gris du Centre, angle de vue, lumière neutre). Ne reproduis PAS le comptoir.
À FAIRE : un seul petit objet isolé : le PLATEAU DE TRANSPORT des Poké Balls d'un Centre Pokémon, posé à plat, vu de dessus en trois quarts comme le comptoir : un plateau rectangulaire aux coins arrondis, blanc et rose pâle, à bord gris clair, avec deux petites poignées sur les côtés ; six alvéoles rondes en deux rangées de trois, chacune contenant une Poké Ball rouge et blanche (bouton blanc au centre), toutes identiques.
Échelle : le plateau fait 0,9 case de large (un adulte mesure 1,33 case) ; il tient dans les mains d'un adulte.
Format : PNG carré 1024 × 1024, l'objet occupe environ 800 px de large, centré. Fond : PNG avec une vraie transparence (canal alpha), aucun damier dessiné.
Interdits : texte, lettres, chiffres, personnage, Pokémon, comptoir, machine, décor, sol, ombre portée, pixel art, 3D.""",
		[PRINCIPAL / "INT_CENTRE_COMPTOIR_NE_r1.png"]),
}


def generer(ident: str, tour: int) -> str:
	texte, jointes = ASSETS[ident]
	nom = f"{ident}_r{tour}"
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(f"{nom} — asset de jeu de Kanto 2026.\n\n{ADN}\n{LUMIERE_NE}\n\n{texte}\n")
	resultat = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier),
		*[str(j) for j in jointes]], cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()[-200:]}"


## Découpe (--preparer) : (image retenue, sortie, boîte de l'asset d'origine dans l'image Codex,
## largeur en jeu). Codex a gardé le cadrage du gabarit au pixel près : on reprend la boîte de
## recadrage de l'asset d'origine (même échelle, même pied), élargie vers le haut si le nouvel objet
## dépasse (casquette accrochée à la tête de lit).
DECOUPES = [
	("JOH_LIT_DORMEUR_HEROS_r1", "int_lit_dormeur_heros_01", (175, 56, 1079, 1201), 192),
	("JOH_LIT_DORMEUR_JOUEUSE_r1", "int_lit_dormeur_joueuse_01", (175, 56, 1079, 1201), 192),
	("JOH_TABLE_STARTERS_VIDE_r1", "int_table_starters_vide_01", (43, 318, 1214, 992), 288),
	("JOH_PLATEAU_POKEBALLS_r1", "int_plateau_pokeballs_01", None, 84),
]


def preparer() -> None:
	import numpy as np
	from PIL import Image
	sortie = RACINE / "assets/world/interiors"
	art = RACINE / "build/art"
	for source, nom, boite, largeur in DECOUPES:
		chemin = art / f"{source}.png"
		if not chemin.exists():
			print(f"{source} : absente")
			continue
		image = Image.open(chemin).convert("RGBA")
		alpha = np.array(image)[:, :, 3] > 40
		ys, xs = np.where(alpha)
		if boite is None:
			boite = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
		else:
			boite = (boite[0], min(boite[1], int(ys.min())), boite[2], boite[3])
		echelle = largeur / (boite[2] - boite[0])
		image = image.crop(boite)
		taille = (largeur, round(image.height * echelle))
		image.resize(taille, Image.LANCZOS).save(sortie / f"{nom}.png")
		print(f"{nom}.png {taille}")


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--preparer"]:
		preparer()
		sys.exit(0)
	tour = 1
	if args[:1] == ["--tour"]:
		tour, args = int(args[1]), args[2:]
	PROMPTS.mkdir(parents=True, exist_ok=True)
	choix = [a for a in ASSETS if not args or a in args]
	with ThreadPoolExecutor(max_workers=3) as pool:
		for ligne in pool.map(lambda i: generer(i, tour), choix):
			print(ligne, flush=True)
