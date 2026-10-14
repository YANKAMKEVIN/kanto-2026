#!/usr/bin/env python3
"""Série 14 (Pokémon) — planches repos + marche en 4 directions (jalon 12, tâche T3).

C-4 du dossier 15 : Rondoudou, Mélofée, Abo, Paras, Nosferapti (en vol), Racaillou (marche) ;
lot parallèle (recommandation de la fiche série 13) : Roucoups, Nidorino, Nidorina, Rattatac,
Rapasdepic. Même gabarit que la série 13 du J11 (1024 × 1536, grille 4 × 4 de cellules
256 × 384, lignes face / gauche / droite / dos, 4 images de marche, pieds à 60 px du bas).
Aucune intégration (ni manifeste, ni companions.json) avant T21 et la validation de Kevin.

Prompts versionnés : tools/art/prompts/serie14_pokemon/<ID>_NE_r<n>.txt (écrits à la génération).
Ancres : le héros validé PERSO_P2_PEINT_r1 (style) + la planche de la forme précédente quand
elle existe, sinon Rattata (gabarit et échelle).

Usage :
  tools/art/serie14_pokemon.py --texte IDENTIFIANT   affiche le prompt
  tools/art/serie14_pokemon.py [--rN] [IDENTIFIANT ...]   génère (3 à la fois ; sans id : tout)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
from serie06 import ART, RACINE  # noqa: E402

PROMPTS = ICI / "prompts" / "serie14_pokemon"
RATTATA = "POKE_RATTATA_P2_r1.png"
PLUS_GRANDS = ("POKE_ROUCOUPS", "POKE_NIDORINO", "POKE_NIDORINA", "POKE_RATTATAC", "POKE_RAPASDEPIC")

## (identifiant, hauteur px [défaut, règle 4], ancre, description, mouvement, vol)
SERIE = [
	("POKE_RONDOUDOU", 48, RATTATA,
		"Rondoudou, de Pokémon Rouge/Bleu, fidèle à son design officiel : petite boule rose pâle "
		"toute ronde, grands yeux bleu-vert, une grosse mèche bouclée sur le front, deux grandes "
		"oreilles pointues, petits bras et petits pieds courts, minuscule queue en boucle. Allure "
		"douce et un peu endormie.",
		"marche sur ses deux petits pieds en 4 images, petits pas trottinants, corps qui rebondit "
		"légèrement", False),
	("POKE_MELOFEE", 52, "POKE_RONDOUDOU_NE_r1.png",
		"Mélofée, de Pokémon Rouge/Bleu, fidèle à son design officiel : petit Pokémon rose pâle "
		"potelé, grands yeux noirs ronds, grandes oreilles rondes aux bouts noirs, petits bras "
		"courts, petites ailes blanches dans le dos, queue courte et ronde. Allure timide et "
		"gracieuse.",
		"marche sur ses deux petits pieds en 4 images, pas menus, petites ailes qui frémissent",
		False),
	("POKE_ABO", 60, RATTATA,
		"Abo, de Pokémon Rouge/Bleu, fidèle à son design officiel : serpent violet foncé, ventre "
		"crème marqué de bandes violettes, un motif en forme de visage ou de masque sur le dessus de "
		"la tête (la capuche), yeux fins, queue fine et pointue. Corps long enroulé en S, vu de "
		"trois quarts. Allure sournoise.",
		"glisse au sol en 4 images (ondulation latérale du corps en S, la tête avance), sans pattes",
		False),
	("POKE_PARAS", 40, RATTATA,
		"Paras, de Pokémon Rouge/Bleu, fidèle à son design officiel : petit crabe-insecte orange à "
		"quatre pattes griffues, gros yeux ronds, et sur le dos deux champignons rouge orangé à "
		"taches crème. Allure placide.",
		"marche à quatre pattes en 4 images, petits pas griffus, champignons du dos qui se balancent",
		False),
	("POKE_NOSFERAPTI", 46, RATTATA,
		"Nosferapti, de Pokémon Rouge/Bleu, fidèle à son design officiel : petite chauve-souris "
		"bleu-violet sans yeux (le visage est une grande bouche), deux grandes oreilles pointues, "
		"grandes ailes membraneuses bleu foncé, deux petits crocs, deux petits pieds repliés. "
		"Allure nerveuse.",
		"vol sur place en 4 images, ailes qui battent (hautes, mi-hautes, basses, mi-hautes), le "
		"corps qui monte et descend de quelques pixels", True),
	("POKE_RACAILLOU_MARCHE", 56, "POKE_RACAILLOU_FIXE_NE_r1.png",
		"Racaillou, de Pokémon Rouge/Bleu, EXACTEMENT le même que sur la planche jointe (déjà "
		"validé : tête-rocher gris, sourcils froncés, deux bras puissants, pas de jambes). Il "
		"avance en se traînant sur ses bras, bras posés au sol.",
		"avance en se traînant sur ses bras en 4 images (un bras puis l'autre se pose devant, le "
		"corps se soulève un peu et retombe)", False),
	("POKE_ROUCOUPS", 60, "POKE_ROUCOOL_NE_r1.png",
		"Roucoups, l'évolution de Roucool dans Pokémon Rouge/Bleu, fidèle à son design officiel : "
		"oiseau brun et crème plus grand et plus robuste que Roucool, grande crête de plumes "
		"rouges et jaunes sur la tête, poitrail crème, ailes brunes bordées de crème, queue "
		"rouge et jaune. Allure fière.",
		"marche en 4 images, pas de volatile redressés, tête qui avance, ailes repliées", False),
	("POKE_NIDORINO", 58, "POKE_NIDORAN_M_NE_r3.png",
		"Nidorino, l'évolution de Nidoran mâle dans Pokémon Rouge/Bleu, fidèle à son design "
		"officiel : quadrupède violet plus grand et plus massif que Nidoran, grandes oreilles "
		"dressées, une grande corne pointue sur le front, petites taches foncées sur le dos et "
		"pointes sur l'échine, longue queue. Allure agressive.",
		"marche à quatre pattes en 4 images, pas bien campés, oreilles et queue qui bougent", False),
	("POKE_NIDORINA", 56, "POKE_NIDORAN_F_NE_r1.png",
		"Nidorina, l'évolution de Nidoran femelle dans Pokémon Rouge/Bleu, fidèle à son design "
		"officiel : quadrupède bleu-bleuté plus grande que Nidoran, grandes oreilles rondes, une "
		"petite corne sur le front, gros yeux, petites taches foncées sur le dos, ventre clair, "
		"longue queue. Allure posée et maternelle.",
		"marche à quatre pattes en 4 images, pas posés, oreilles et queue qui bougent", False),
	("POKE_RATTATAC", 66, RATTATA,
		"Rattatac, l'évolution de Rattata dans Pokémon Rouge/Bleu, fidèle à son design officiel : "
		"gros rat brun-ocre clair plus grand et plus robuste que Rattata, ventre crème, longues "
		"moustaches, grandes incisives blanches, petites oreilles pointues, queue épaisse et "
		"droite. Allure agressive.",
		"trot à quatre pattes en 4 images, pas puissants, queue droite qui balance", False),
	("POKE_RAPASDEPIC", 64, "POKE_PIAFABEC_NE_r1.png",
		"Rapasdepic, l'évolution de Piafabec dans Pokémon Rouge/Bleu, fidèle à son design "
		"officiel : grand oiseau brun plus grand et plus élancé que Piafabec, très long cou, long "
		"bec pointu rose pâle, crête de plumes rouges sur la tête, poitrail crème, grandes ailes "
		"brunes bordées de rouille, queue rouge. Allure féroce.",
		"marche en 4 images, longues enjambées d'oiseau, cou qui avance, ailes repliées", False),
]

SOL = ("les pieds posés sur la même ligne horizontale à 60 px du bas de la cellule, à la même taille "
	"dans toutes les cellules")
VOL = ("le bas du corps toujours au même endroit, environ 70 px AU-DESSUS d'une ligne horizontale "
	"invisible placée à 60 px du bas de la cellule (le Pokémon vole : rien ne touche cette ligne), à "
	"la même taille dans toutes les cellules")


## Corrections (revision r2) : description et taille de jeu remplacées après relecture.
R2_NIDORINA = ("Nidorina, l'évolution de Nidoran femelle dans Pokémon Rouge/Bleu, fidèle à son "
	"design officiel : quadrupède NETTEMENT plus grande, plus trapue et plus massive que Nidoran "
	"femelle (corps environ 1,4 fois plus gros, pattes courtes et fortes), bleu soutenu et plus "
	"foncé (bleu franc, pas bleu pâle), ventre crème, taches foncées sur le dos et les flancs, "
	"rangée de piquants dorsaux nets, une corne courte sur le front, oreilles plus petites et "
	"plus rondes que celles de Nidoran, gros yeux rouges, deux petits crocs, queue épaisse à "
	"pointe. Allure posée et maternelle.")
HAUTEURS_R2 = {"POKE_NIDORINA": 66, "POKE_RAPASDEPIC": 86}


def prompt(identifiant: str, revision: str = "r1") -> str:
	_, _, ancre, description, mouvement, vol = next(e for e in SERIE if e[0] == identifiant)
	if identifiant == "POKE_NIDORINA" and revision != "r1":
		description = R2_NIDORINA
	nom = ancre.removesuffix(".png")
	fixe = "RACAILLOU" in nom
	taille = "un peu plus grand" if identifiant in PLUS_GRANDS else "de taille comparable"
	if identifiant == "POKE_NIDORINA" and revision != "r1":
		taille = "nettement plus grand, plus trapu et d'un bleu plus soutenu"
	gabarit = "" if fixe else ", même gabarit de planche"
	note = (" Attention : cette deuxième image est une planche de poses fixes, PAS le gabarit : "
		"respecte la grille 4 × 4 décrite ci-dessus.") if fixe else ""
	return f"""{identifiant} — planche d'animation d'un Pokémon du monde (compagnon du héros).
Style : exactement le rendu de la première planche jointe (le héros du jeu) : Pokémon peint simplifié, même finesse, même contour fin coloré sans trait noir, même manière de peindre les volumes. Ni pixel art, ni 3D, ni anime aux contours noirs.
LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.

POKÉMON (identique dans toutes les images) : {description}

PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 256 × 384 px et contient UNE pose du Pokémon, entier, centré horizontalement, {VOL if vol else SOL} (environ 170 px de haut). Aucune pose ne déborde de sa cellule.
- Ligne 1 : de face (vers le bas de l'écran).
- Ligne 2 : de profil, vers la gauche.
- Ligne 3 : de profil, vers la droite.
- Ligne 4 : de dos (vers le haut de l'écran).
- Colonnes : {mouvement}.
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit un peu le dessus du Pokémon). Pas de perspective, pas d'ombre au sol, pas de sol, pas de texte, pas de numéros, pas de cadres autour des cellules.
Les couleurs, les proportions et la tête doivent être EXACTEMENT les mêmes dans les 16 poses.

La deuxième image jointe ({nom}) est un autre Pokémon du jeu, déjà validé : même rendu, même finesse{gabarit} ; garde ses proportions comme repère de taille et de style (ce Pokémon-ci est {taille}).{note}
"""


def _lancer(identifiant: str, revision: str) -> str:
	nom = f"{identifiant}_NE_{revision}"
	if (ART / f"{nom}.png").exists():
		return f"{nom} : déjà là"
	PROMPTS.mkdir(parents=True, exist_ok=True)
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(prompt(identifiant, revision))
	ancre = next(e[2] for e in SERIE if e[0] == identifiant)
	jointes = [str(ART / "PERSO_P2_PEINT_r1.png"), str(ART / ancre)]
	for _ in range(3):  # le filtre de Codex refuse parfois au hasard : on réessaie
		r = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier), *jointes],
			cwd=RACINE, capture_output=True, text=True)
		if r.returncode == 0:
			break
	return f"{nom} : {'ok' if r.returncode == 0 else 'ÉCHEC ' + r.stderr.strip()[-200:]}"


if __name__ == "__main__":
	args = sys.argv[1:]
	rev = "r1"
	for a in list(args):
		if a.startswith("--r") and a[3:].isdigit():
			rev = a[2:]
			args.remove(a)
	if args[:1] == ["--texte"]:
		print(prompt(args[1]))
	else:
		ids = [e[0] for e in SERIE if not args or e[0] in args]
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(lambda i: _lancer(i, rev), ids):
				print(ligne, flush=True)
