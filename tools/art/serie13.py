#!/usr/bin/env python3
"""Série 13 — planches de marche du compagnon (jalon 11, lot d'art A-10, lumière neutre).

Dossier 14 §8.2 : cinq espèces de plus deviennent éligibles comme compagnon (repos + marche en
4 directions, gabarit des starters de la série 09 et du Salamèche de Kevin) : Herbizarre,
Reptincel, Carabaffe, Pikachu, Papilusion (en vol). Fiche : docs/design/fiches-assets/
serie-13-compagnon.md. Aucune image n'entre au manifeste avant la validation de Kevin sur
planche de contact.

Le prompt est entièrement dans ce fichier (pas de modèle dans build/art/prompts), pour pouvoir
le coller tel quel dans l'app ChatGPT quand Codex refuse (cas du Salamèche, série 09).
Ancres (build/art du Mac de Kevin) : le héros validé PERSO_P2_PEINT_r1 (style) + la planche
validée de la forme précédente ou d'une forme proche (proportions, rendu).

Usage :
  tools/art/serie13.py --texte IDENTIFIANT   affiche le prompt (à coller dans ChatGPT)
  tools/art/serie13.py --manifeste           ajoute les entrées en fin de tools/art/manifeste.json
                                             (idempotent ; seulement après validation de Kevin)
  tools/art/serie13.py [IDENTIFIANT ...]     génère avec Codex (sans argument : toute la série)
"""
from __future__ import annotations

import json
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
from serie06 import ART, RACINE  # noqa: E402
from serie06b import _lancer  # noqa: E402

## (identifiant, id du manifeste, hauteur affichée en px [défaut, règle 4], ancre de forme,
##  description, mouvement, vol)
SERIE = [
	("POKE_HERBIZARRE", "herbizarre", 66, "POKE_BULBIZARRE_NE_r1.png",
		"Herbizarre, l'évolution de Bulbizarre dans Pokémon Rouge/Bleu, fidèle à son design officiel : "
		"quadrupède bleu-vert plus grand et plus robuste que Bulbizarre, taches vert foncé, yeux rouges, "
		"et sur le dos un gros bouton de fleur rose fermé entouré de quatre larges feuilles vertes. "
		"Allure calme et posée.",
		"marche à quatre pattes en 4 images, pas lourds et réguliers, feuilles du dos qui bougent à peine",
		False),
	("POKE_REPTINCEL", "reptincel", 72, "POKE_SALAMECHE_NE_r4.png",
		"Reptincel, l'évolution de Salamèche dans Pokémon Rouge/Bleu, fidèle à son design officiel : "
		"lézard bipède rouge-orangé foncé, plus grand et plus élancé que Salamèche, ventre crème, une "
		"petite corne vers l'arrière du crâne, griffes blanches, et une flamme plus vive au bout de la "
		"queue, visible dans toutes les poses. Allure fière et un peu impatiente.",
		"marche debout en 4 images, pas assurés, queue à flamme qui balance", False),
	("POKE_CARABAFFE", "carabaffe", 68, "POKE_CARAPUCE_NE_r1.png",
		"Carabaffe, l'évolution de Carapuce dans Pokémon Rouge/Bleu, fidèle à son design officiel : "
		"tortue bipède bleu soutenu, plus grande que Carapuce, carapace brune au bord crème, oreilles en "
		"forme d'ailerons duveteux bleu pâle, longue queue duveteuse blanc bleuté enroulée. Allure vive "
		"et sûre d'elle.",
		"marche debout en 4 images, petits pas dynamiques, queue duveteuse qui ondule", False),
	("POKE_PIKACHU", "pikachu", 52, "POKE_RATTATA_P2_r1.png",
		"Pikachu, de Pokémon Rouge/Bleu, fidèle à son design officiel : petit rongeur jaune vif et "
		"rond, longues oreilles pointues au bout noir, joues rouges rondes, deux bandes brunes sur le "
		"dos, queue en forme d'éclair brune à la base. Allure joyeuse et curieuse.",
		"trot à quatre pattes en 4 images, petits bonds légers, oreilles et queue qui rebondissent",
		False),
	("POKE_PAPILUSION", "papilusion", 70, "POKE_ROUCOOL_NE_r1.png",
		"Papilusion, de Pokémon Rouge/Bleu, fidèle à son design officiel : papillon au corps violet "
		"bleuté, grands yeux rouges à facettes, petites antennes, quatre grandes ailes blanches aux "
		"nervures et bords noirs, petites pattes bleu pâle. Allure douce et légère.",
		"vol sur place en 4 images, ailes qui battent (ouvertes, mi-hautes, hautes, mi-basses), le corps "
		"qui monte et descend de quelques pixels", True),
]

SOL = ("les pieds posés sur la même ligne horizontale à 60 px du bas de la cellule, à la même taille "
	"dans toutes les cellules")
VOL = ("le bas du corps toujours au même endroit, environ 70 px AU-DESSUS d'une ligne horizontale "
	"invisible placée à 60 px du bas de la cellule (le Pokémon vole : rien ne touche cette ligne), à "
	"la même taille dans toutes les cellules")


def prompt(identifiant: str) -> str:
	entree = next(e for e in SERIE if e[0] == identifiant)
	_, _, _, ancre, description, mouvement, vol = entree
	return f"""{identifiant} — planche d'animation d'un Pokémon du monde (compagnon du héros).
Style : exactement le rendu de la planche jointe (le héros du jeu) : Pokémon peint simplifié, même finesse, même contour fin coloré sans trait noir, même manière de peindre les volumes. Ni pixel art, ni 3D, ni anime aux contours noirs.
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

La deuxième image jointe ({ancre.removesuffix('.png')}) est un autre Pokémon du jeu, déjà validé : même rendu, même finesse, même gabarit de planche ; garde ses proportions comme repère de taille (ce Pokémon-ci est {'un peu plus grand' if identifiant in ('POKE_HERBIZARRE', 'POKE_REPTINCEL', 'POKE_CARABAFFE') else 'de taille comparable'}).
"""


def _manifeste() -> None:
	"""Ajoute les entrées en fin de la liste « pokemon », dans le texte du fichier (le reste du
	manifeste garde sa mise en forme) ; une espèce sans planche source est laissée hors du lot."""
	chemin = ICI / "manifeste.json"
	texte = chemin.read_text()
	existants = {e.get("id") for e in json.loads(texte)["pokemon"] if isinstance(e, dict)}
	bloc, ajouts = "", 0
	for identifiant, ident, hauteur, *_ in SERIE:
		if ident in existants:
			continue
		if not (ART / f"{identifiant}_NE_r1.png").exists():  # refusée ou pas encore produite
			print(f"manifeste : {ident} sans planche, laissé hors du lot (A-11)")
			continue
		bloc += (f',\n  {{\n   "id": "{ident}",\n   "source": "{identifiant}_NE_r1.png",\n'
			f'   "sortie": "assets/sprites/pokemon/painted/{ident}_sheet.png",\n'
			f'   "hauteur": {hauteur}\n  }}')
		ajouts += 1
	if bloc:
		fin = texte.index("\n ],", texte.index('\n "pokemon": ['))
		texte = texte[:fin] + bloc + texte[fin:]
		json.loads(texte)  # garde-fou : le fichier reste du JSON valide
		chemin.write_text(texte)
	print(f"manifeste : {ajouts} entrée(s) ajoutée(s)")


def _taches(choix: set[str]):
	heros = str(ART / "PERSO_P2_PEINT_r1.png")
	for identifiant, _, _, ancre, *_ in SERIE:
		if choix and identifiant not in choix:
			continue
		yield lambda i=identifiant, a=ancre: _lancer(i, prompt(i), [heros, str(ART / a)])


if __name__ == "__main__":
	arguments = sys.argv[1:]
	if arguments[:1] == ["--texte"]:
		print(prompt(arguments[1]))
	elif arguments[:1] == ["--manifeste"]:
		_manifeste()
	else:
		with ThreadPoolExecutor(max_workers=3) as pool:
			for ligne in pool.map(lambda t: t(), list(_taches(set(arguments)))):
				print(ligne, flush=True)
