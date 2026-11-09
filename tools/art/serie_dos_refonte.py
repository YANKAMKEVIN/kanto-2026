#!/usr/bin/env python3
"""Refonte des dos peu fidèles à la face (demande de Kevin, 2026-11-09, après le dos de Roucool).

Même cadrage que `serie_dos_rb.py` (coupé par le bas), mais le prompt demande de reprendre les couleurs
et les marques de l'artwork officiel joint. Pour chaque espèce : deux images AVEC l'artwork (A1, A2) ;
une image SANS (S1) seulement si les deux premières sont refusées. Rien n'est intégré ici : Kevin choisit
sur la planche, puis `--integrer IDENT ESSAI` écrit assets/sprites/pokemon/dos/dos_rb_NNN.png.

Usage :
  tools/art/serie_dos_refonte.py [IDENT ...]             génère (3 à la fois)
  tools/art/serie_dos_refonte.py --contact FICHIER.png [IDENT ...]   planche face | dos actuel | essais
  tools/art/serie_dos_refonte.py --integrer IDENT ESSAI  ex. : --integrer ONIX A2
"""
from __future__ import annotations

import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
PROMPTS = ICI / "prompts" / "dos_rb" / "refonte"
OFFICIEL = RACINE / "assets/sprites/pokemon/official"
DOS_JEU = RACINE / "assets/sprites/pokemon/dos"

ESPECES: dict[str, tuple[int, str]] = {
	"CHRYSACIER": (11, "cocon vert trapu et anguleux, en plaques dures bien marquées, large en haut et pointu en bas, comme sur l'image"),
	"NOSFERAPTI": (41, "petite chauve-souris au corps BLEU, grandes ailes dont la membrane est VIOLETTE, deux longues pattes fines bleues pendantes"),
	"AKWAKWAK": (55, "canard bipède élancé d'un BLEU moyen comme sur l'image, crête de plumes sur la tête, longue queue, bras et jambes nets ; tête tournée de profil, bec crème visible"),
	"KADABRA": (64, "créature humanoïde mince, corps JAUNE, plastron et épaules bruns, grande queue jaune à bande brune, oreilles pointues ; silhouette fine comme sur l'image, pas massive"),
	"ALAKAZAM": (65, "créature humanoïde mince, corps JAUNE, plastron et épaules bruns, longues oreilles pointues, longues moustaches, une cuillère dans chaque main ; silhouette claire et fine"),
	"TENTACOOL": (72, "méduse au dôme BLEU bien rond avec les grosses pierres ROUGES visibles sur le dessus, deux tentacules gris clair ; même dôme que sur l'image"),
	"SPECTRUM": (93, "spectre : tête unique ronde et hérissée VIOLET foncé qui flotte, entourée de deux mains séparées violettes à griffes, comme sur l'image ; une seule masse lisible, pas de morceaux épars"),
	"ECTOPLASMA": (94, "créature ronde VIOLET foncé, le dos couvert d'une rangée de grandes PIQUES pointues, courtes pattes, grandes oreilles pointues ; même violet que sur l'image"),
	"ONIX": (95, "immense serpent fait de GROS BLOCS de roche grise arrondis, de plus en plus gros vers la tête, corne sur la tête ; des blocs épais, pas une chaîne fine"),
	"ELECTRODE": (101, "sphère parfaitement ronde : moitié HAUTE BLANCHE, moitié BASSE ROUGE, exactement dans cet ordre comme sur l'image, surface lisse et brillante, aucun visage"),
	"OSSATUEUR": (105, "petit dinosaure bipède au corps BEIGE-BRUN clair comme sur l'image, crâne blanc porté comme un casque, tenant un os blanc dans une patte, queue courte"),
	"SMOGO": (109, "grosse boule VIOLETTE ronde à cratères d'où sortent des bouffées de gaz beige, comme sur l'image ; grande et ronde, pas hérissée"),
	"MAGICARPE": (129, "poisson ROUGE à grandes écailles, couronne jaune sur le dessus, grandes nageoires blanches et jaunes, longues moustaches jaune clair ; même rouge que sur l'image, pas orange"),
	"PORYGON": (137, "créature faite de FACETTES géométriques anguleuses, rouge rosé et bleu turquoise comme sur l'image, aucune forme arrondie"),
	# --- dos optionnels (2026-11-09) ---
	"SALAMECHE": (4, "petit lézard bipède ORANGE au ventre crème, grosse tête ronde tournée de profil, queue terminée par une flamme vive, ombrage doux comme sur l'image"),
	"PIKACHU": (25, "petit rongeur JAUNE rondouillard, longues oreilles à pointe noire, deux bandes brunes sur le dos, queue en éclair, joue rouge visible de profil"),
	"PAPILUSION": (12, "papillon au corps violet-bleu, grandes ailes BLANCHES à fines nervures et bordure noire légère, gros yeux rouges visibles de profil, comme sur l'image"),
	"NOSFERALTO": (42, "grande chauve-souris au corps BLEU, ailes à membrane VIOLETTE, grandes oreilles, comme sur l'image"),
	"PARASECT": (47, "crabe orange portant un grand champignon ORANGE-ROSÉ à taches crème sur le dos, comme sur l'image, grosses pinces orange"),
	"SOPORIFIK": (96, "créature bipède trapue JAUNE en haut et BRUN foncé en bas, longue trompe visible de profil, oreilles triangulaires ; ombrage doux comme sur l'image"),
	"AMONISTAR": (139, "grosse coquille spiralée BEIGE à pointes, tentacules BLEU CLAIR comme sur l'image, pas de bleu foncé"),
	"PTERA": (142, "reptile volant GRIS-VIOLET clair aux ailes membraneuses, tête allongée tournée de profil, trait doux comme sur l'image, pas réaliste"),
	"RONFLEX": (143, "énorme créature ronde au corps BLEU-VERT sombre et ventre crème visible sur le côté, petites oreilles pointues, surface lisse sans fourrure réaliste, comme sur l'image"),
	"STEELIX": (208, "immense serpent fait de segments d'ACIER gris bien séparés, de plus en plus gros, tête massive à mâchoire carrée tournée de profil, comme sur l'image"),
	"HYPOROI": (230, "hippocampe BLEU moyen au ventre crème, grandes nageoires hérissées, museau tubulaire visible de profil, comme sur l'image, bleu pas trop saturé"),
	"ENTEI": (244, "grand fauve au pelage BRUN, crinière grise et blanche comme un nuage de fumée, masque rouge et jaune visible de profil, comme sur l'image, trait doux et non réaliste"),
}

GABARIT = """POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (projet personnel, non distribué). La créature est un animal fantastique de jeu vidéo.

{jointe}

SUJET : {sujet}.

VUE : de dos, en trois quarts, en légère plongée : la caméra est juste derrière son épaule gauche. Elle fait face à un adversaire lointain, en haut à droite de l'image. Si la créature a une tête distincte, elle est tournée de PROFIL vers la droite pour qu'on reconnaisse son visage.

{fidelite}

STYLE : {style}. Pas de pixel art, pas de 3D, pas de photo.
LUMIÈRE : neutre, diffuse, légèrement du haut à gauche.
FOND : PNG avec une vraie transparence, aucun damier, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, décor, autre créature, personnage.
CADRAGE : image CARRÉE 1024 × 1024, cadrage SERRÉ : la créature GRANDE ; le bas du corps est nettement COUPÉ par le bord BAS de l'image (environ le tiers inférieur hors champ, coupe nette, sans fondu). Rien n'est coupé en haut, à gauche ni à droite. Une seule image fixe.
"""


def prompt(ident: str, avec_image: bool) -> Path:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	sujet = ESPECES[ident][1]
	if avec_image:
		texte = GABARIT.format(
			jointe="Image jointe : l'illustration de face de cette créature. C'est LA référence absolue de ses couleurs, de ses marques et de son style : le résultat doit être reconnu au premier coup d'œil comme la même créature, simplement vue de derrière.",
			sujet=sujet,
			fidelite="Mêmes couleurs exactes, mêmes marques, mêmes proportions que l'image jointe.",
			style="exactement celui de l'image jointe : même trait fin et doux, même ombrage en aplats nuancés, même palette")
	else:
		texte = GABARIT.format(jointe="Design original de créature de jeu vidéo.", sujet=sujet.replace(", comme sur l'image", "").replace(" comme sur l'image", "").replace(" que sur l'image", ""),
			fidelite="Couleurs franches, marques nettes.", style="illustration officielle de jeu des années 2000 : trait fin et doux, ombrage en aplats nuancés")
	chemin = PROMPTS / f"{ident}_{'A' if avec_image else 'S'}.txt"
	chemin.write_text(texte, encoding="utf-8")
	return chemin


def essai(ident: str, nom: str, avec_image: bool) -> bool:
	sortie = ART / f"DOS2_{ident}_{nom}.png"
	if sortie.exists():
		return True
	cmd = [str(ICI / "generer.sh"), f"DOS2_{ident}_{nom}", str(prompt(ident, avec_image))]
	if avec_image:
		cmd.append(str(OFFICIEL / f"{ESPECES[ident][0]:03d}.png"))
	subprocess.run(cmd, cwd=RACINE, capture_output=True, text=True)
	ok = sortie.exists()
	print(ident, nom, "ok" if ok else "REFUS", flush=True)
	return ok


def espece(ident: str) -> None:
	a1 = essai(ident, "A1", True)
	a2 = essai(ident, "A2", True)
	if not a1 and not a2:
		essai(ident, "S1", False)


def actuel(num: int) -> Path:
	for motif in ("dos_rb_%03d.png", "dos_ia_%03d.png", "dos3d_%03d.png"):
		if (DOS_JEU / (motif % num)).exists():
			return DOS_JEU / (motif % num)
	raise FileNotFoundError(num)


def contact(sortie: Path, idents: list[str]) -> None:
	cote, marge = 300, 26
	choisies = {i: ESPECES[i] for i in (idents or ESPECES)}
	feuille = Image.new("RGB", (cote * 5, (cote + marge) * len(choisies)), (112, 148, 96))
	dessin = ImageDraw.Draw(feuille)
	for y, (ident, (num, _)) in enumerate(choisies.items()):
		cases = [("Face", OFFICIEL / f"{num:03d}.png"), ("Actuel", actuel(num))]
		cases += [(n, ART / f"DOS2_{ident}_{n}.png") for n in ("A1", "A2", "S1")]
		for x, (nom, chemin) in enumerate(cases):
			dessin.text((x * cote + 8, y * (cote + marge) + 6), f"{ident} {nom}" if chemin.exists() else "", fill=(255, 255, 255))
			if chemin.exists():
				im = Image.open(chemin).convert("RGBA")
				im.thumbnail((cote, cote))
				feuille.paste(im, (x * cote + (cote - im.width) // 2, y * (cote + marge) + marge), im)
	feuille.save(sortie)


def integrer(ident: str, nom: str) -> None:
	sys.path.insert(0, str(ICI))
	import serie_dos_rb as rb
	im = Image.open(ART / f"DOS2_{ident}_{nom}.png").convert("RGBA")
	rb._poser(rb._recadrer(rb._propre(im))).save(DOS_JEU / f"dos_rb_{ESPECES[ident][0]:03d}.png")


def main() -> None:
	args = sys.argv[1:]
	if args[:1] == ["--contact"]:
		contact(Path(args[1]), args[2:])
	elif args[:1] == ["--integrer"]:
		integrer(args[1], args[2])
	else:
		with ThreadPoolExecutor(3) as pool:
			list(pool.map(espece, args or list(ESPECES)))


if __name__ == "__main__":
	main()
