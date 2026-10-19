#!/usr/bin/env python3
"""T13 (J17) — dos de combat de Taupiqueur (050), Triopikeur (051), Soporifik (096), Hypno (097).

Fiche : docs/design/fiches-assets/serie-combat-dos-pilote.md §7 ; plan : docs/tech/jalon-17.md T13.
Trois Pokémon ont un modèle 3D X/Y (rendu Blender puis repeint Colab) ; Hypno (097) n'en a pas
(provenance-modeles-3d.md §1) : repli = dos provisoire peint par Codex, comme Fantominus (série 20).

Dossier de travail (hors dépôt) : $DOS_T13, défaut ~/dev/kanto-2026-modeles/dos_t13/.
Modèles extraits : ~/dev/kanto-2026-modeles/art-pokemon-pilote/modeles/ (comme les lots précédents).

Usage :
  tools/art/dos_t13.py tout [zip ...]        installer + rendre + notebook (la suite de commandes de Kevin)
  tools/art/dos_t13.py installer [zip ...]   extrait les zips X/Y (défaut : ~/Downloads, archives qui
                                             contiennent Diglett / Dugtrio / Drowzee) et renseigne
                                             modele / images dans dos_pokemon.json
  tools/art/dos_t13.py rendre [--vues]       passes couleur + profondeur (1024) dans $DOS_T13/passes ;
                                             --vues : quatre vues d'orientation, pour régler le JSON
  tools/art/dos_t13.py notebook              écrit $DOS_T13/kanto_dos_t13.ipynb (Colab)
  tools/art/dos_t13.py importer [zip]        décompresse le zip Colab (défaut ~/Downloads/kanto_dos_t13.zip),
                                             planche de choix ; --retenir 050=ipa0_g7 ... copie dans
                                             battle_proto/dos_ia_NNN.png
  tools/art/dos_t13.py hypno-prompts         écrit les prompts DOS_HYPNO_r1..r3 (Codex)
  tools/art/dos_t13.py hypno-commandes       liste les commandes tools/art/generer.sh
  tools/art/dos_t13.py hypno-detourer [r3]   détoure l'essai retenu -> $DOS_T13/dos_ia_097.png (1024)
"""
from __future__ import annotations

import glob
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
MODELES = Path.home() / "dev/kanto-2026-modeles/art-pokemon-pilote/modeles"
TRAVAIL = Path(os.environ.get("DOS_T13", Path.home() / "dev/kanto-2026-modeles/dos_t13"))
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
JSON = ICI / "blender/dos_pokemon.json"
PROMPTS = ICI / "prompts" / "dos_t13"
OFFICIEL = RACINE / "assets/sprites/pokemon/official"
PROTO = RACINE / "assets/sprites/pokemon/battle_proto"
DOWNLOADS = Path.home() / "Downloads"
ZIP_COLAB = "kanto_dos_t13.zip"

LOT = {"050": ("diglett", "Diglett"), "051": ("dugtrio", "Dugtrio"), "096": ("drowzee", "Drowzee")}
SANS_IPA = "050,051,096"  # le dos diffère de la face (visage, groin) : pas d'artwork de face


def installer(zips: list[str]) -> bool:
	if not zips:
		zips = [str(z) for z in sorted(DOWNLOADS.glob("*.zip"))]
	texte = JSON.read_text(encoding="utf-8")
	trouve = set()
	for z in zips:
		try:
			noms = zipfile.ZipFile(z).namelist()
		except (zipfile.BadZipFile, OSError):
			continue
		for num, (dossier, mot) in LOT.items():
			if not any(mot.lower() in n.lower() for n in noms):
				continue
			cible = MODELES / dossier
			cible.mkdir(parents=True, exist_ok=True)
			zipfile.ZipFile(z).extractall(cible)
			modeles = sorted(p for ext in ("SMD", "smd", "DAE", "dae")
				for p in cible.rglob(f"*.{ext}") if mot.lower() in p.name.lower())
			if not modeles:
				print(num, mot, ": aucun .SMD / .DAE trouvé dans", z)
				continue
			# Préférence : modèle sans suffixe de forme femelle (F), SMD avant DAE.
			modele = next((m for m in modeles if not m.stem.upper().endswith("F")), modeles[0])
			images = modele.parent / "images"
			if not images.is_dir():
				images = modele.parent / "Images"
			if not images.is_dir():
				images = modele.parent
			texte = _renseigner(texte, num, str(modele.relative_to(MODELES)),
				str(images.relative_to(MODELES)))
			trouve.add(num)
			print(num, mot, "->", modele.relative_to(MODELES))
	json.loads(texte)
	JSON.write_text(texte, encoding="utf-8")
	manque = [n for n in LOT if n not in trouve]
	if manque:
		print("Modèles encore absents :", ", ".join(f"{n} {LOT[n][1]}" for n in manque),
			"\n-> télécharger les zips sur The Models Resource (Pokémon X/Y) dans ~/Downloads.")
	return not manque


def _renseigner(texte: str, num: str, modele: str, images: str) -> str:
	"""Modifie l'entrée `num` du JSON en place (sans reformater le fichier)."""
	debut = texte.index(f'\t"{num}": {{')
	fin = texte.index("\n\t\t\"options\"", debut)
	bloc = texte[debut:fin]
	bloc = re.sub(r'\t\t"statut": "[^"]*",\n', "", bloc)
	bloc = re.sub(r'"modele": "[^"]*", "images": "[^"]*"',
		lambda _: f'"modele": "{modele}", "images": "{images}"', bloc)
	return texte[:debut] + bloc + texte[fin:]


def rendre(vues: bool) -> None:
	sortie = TRAVAIL / ("vues" if vues else "passes")
	rendre_lot = ICI / "blender/rendre_lot.py"
	nums = list(LOT)
	if vues:
		subprocess.run([sys.executable, rendre_lot, MODELES, sortie, *nums, "--vues", "--taille", "512"])
		return
	for passe in ("couleur", "profondeur"):
		subprocess.run([sys.executable, rendre_lot, MODELES, sortie, *nums, "--passe", passe])


def planche_passes() -> None:
	"""Planche de contrôle des passes (couleur sur fond clair + profondeur) : à relire avant Colab."""
	from PIL import Image
	passes = TRAVAIL / "passes"
	t = 320
	planche = Image.new("RGB", (t * 2, t * len(LOT)), (225, 232, 222))
	for r, n in enumerate(LOT):
		c = Image.open(passes / f"dos3d_{n}.png").convert("RGBA").resize((t, t))
		fond = Image.new("RGBA", (t, t), (225, 232, 222, 255))
		fond.alpha_composite(c)
		planche.paste(fond.convert("RGB"), (0, r * t))
		planche.paste(Image.open(passes / f"dos3d_{n}_profondeur.png").convert("RGB").resize((t, t)),
			(t, r * t))
	planche.save(TRAVAIL / "planche_passes.png")
	print("Planche de contrôle :", TRAVAIL / "planche_passes.png")


def notebook() -> None:
	passes = TRAVAIL / "passes"
	for n in LOT:
		for suffixe in ("", "_profondeur"):
			if not (passes / f"dos3d_{n}{suffixe}.png").exists():
				sys.exit(f"Passe manquante : {passes}/dos3d_{n}{suffixe}.png (lancer « rendre » d'abord)")
	sortie = TRAVAIL / "kanto_dos_t13.ipynb"
	subprocess.run([sys.executable, ICI / "ia/creer_notebook_colab_v2.py", passes, OFFICIEL, sortie,
		"--nums", ",".join(LOT), "--sans-ipa", SANS_IPA, "--zip", ZIP_COLAB], check=True)
	print("Notebook :", sortie)
	planche_passes()


def tout(zips: list[str]) -> None:
	if not installer(zips):
		sys.exit(1)
	rendre(False)
	notebook()


def importer(args: list[str]) -> None:
	retenir = {}
	if "--retenir" in args:
		i = args.index("--retenir")
		for kv in args[i + 1:]:
			num, _, var = kv.partition("=")
			retenir[num] = var
		args = args[:i]
	archive = Path(args[0]) if args else DOWNLOADS / ZIP_COLAB
	dossier = TRAVAIL / "colab"
	shutil.rmtree(dossier, ignore_errors=True)
	dossier.mkdir(parents=True)
	zipfile.ZipFile(archive).extractall(dossier)
	print("Extrait dans", dossier)
	for f in sorted(dossier.glob("*.png")):
		print(" ", f.name)
	for num, var in retenir.items():
		src = dossier / f"{num}_{var}.png"
		dst = PROTO / f"dos_ia_{num}.png"
		shutil.copyfile(src, dst)
		print("retenu :", dst.relative_to(RACINE))
	if retenir:
		print("Ensuite : godot --headless --path . --import (génère les .import à commiter).")


# --- Repli Hypno (pas de modèle 3D) : dos provisoire peint par Codex, comme Fantominus (série 20) ---

FIN = ("FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond "
	"coloré, aucun sol, aucune ombre portée.")
HYPNO = """POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). {nom}

{ancres}

SUJET : un Pokémon bipède de type psy à tête de tapir, animal à pelage ras entièrement jaune vif (une seule teinte, pas de robe ni de manteau), torse ventru et large, bras musclés pliés (poings fermés, coudes écartés), jambes courtes fléchies, pieds à trois orteils ; une GRANDE COLLERETTE DE POILS BLANCS ébouriffés autour du cou (vue de derrière, elle encadre la nuque) ; deux grandes oreilles pointues dressées, au creux brun clair, et un long nez recourbé dont on ne voit que la courbe du profil au-delà de la collerette. Posture de combat, un peu voûtée.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; le Pokémon regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant lui). AUCUN œil, aucune bouche, aucun visage dessiné sur le dos ou la nuque : le visage est tourné vers l'avant, hors de vue (au plus, la pointe du museau en profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, le Pokémon ENTIER, centré, qui occupe environ 85 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe.
{fin}
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage."""
NOM = {1: "Le Pokémon est HYPNO (n° 097), de la première génération.",
	2: "La créature est un Pokémon psy de jeu vidéo à tête de tapir, original.",
	3: "La créature est un Pokémon psy de jeu vidéo à tête de tapir, original."}
ANCRES = {
	1: ("IMAGE 1 : l'artwork officiel de face de ce Pokémon : anatomie, couleurs, proportions et style de "
		"rendu (pas la pose : on le veut de dos).\nIMAGE 2 : un autre Pokémon de dos déjà produit pour ce "
		"jeu : reprends son ANGLE de vue (trois quarts dos, regard vers le haut à droite), son cadrage et sa "
		"famille de rendu ; ne reprends ni sa forme ni ses couleurs."),
	2: ("IMAGE 1 : une illustration de face de la créature : couleurs, proportions et style (pas la pose).\n"
		"IMAGE 2 : une autre créature vue de dos dans ce jeu : reprends son ANGLE de vue et son cadrage, pas "
		"sa forme."),
	3: "Aucune image jointe."}
JOINTES = {1: [OFFICIEL / "097.png", PROTO / "dos_ia_093.png"],
	2: [OFFICIEL / "097.png", PROTO / "dos_ia_093.png"], 3: []}


def hypno_prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for r in (1, 2, 3):
		p = PROMPTS / f"DOS_HYPNO_r{r}.txt"
		p.write_text(HYPNO.format(nom=NOM[r], ancres=ANCRES[r], fin=FIN).strip() + "\n")
		print(p.relative_to(RACINE))


def hypno_commandes() -> None:
	for r in (1, 2, 3):
		print("tools/art/generer.sh DOS_HYPNO_r%d %s %s" % (r,
			(PROMPTS / f"DOS_HYPNO_r{r}.txt").relative_to(RACINE),
			" ".join(str(j) for j in JOINTES[r])))


def hypno_detourer(essai: str) -> None:
	from PIL import Image
	im = Image.open(ART / f"DOS_HYPNO_{essai}.png").convert("RGBA")
	boite = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
	im = im.crop(boite) if boite else im
	k = min(870 / im.width, 870 / im.height)
	s = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
	out = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
	out.alpha_composite(s, ((1024 - s.width) // 2, 1024 - 120 - s.height))
	TRAVAIL.mkdir(parents=True, exist_ok=True)
	out.save(TRAVAIL / "dos_ia_097.png")
	print(TRAVAIL / "dos_ia_097.png", "(à copier dans battle_proto/ après relecture)")


def main() -> None:
	a = sys.argv[1:]
	if not a:
		print(__doc__)
	elif a[0] == "tout":
		tout(a[1:])
	elif a[0] == "installer":
		installer(a[1:])
	elif a[0] == "rendre":
		rendre("--vues" in a)
	elif a[0] == "notebook":
		notebook()
	elif a[0] == "importer":
		importer(a[1:])
	elif a[0] == "hypno-prompts":
		hypno_prompts()
	elif a[0] == "hypno-commandes":
		hypno_commandes()
	elif a[0] == "hypno-detourer":
		hypno_detourer(a[1] if len(a) > 1 else "r3")
	else:
		print(__doc__)


if __name__ == "__main__":
	main()
