#!/usr/bin/env python3
"""Découpe une bande d'attente générée (UNE ligne de 4 poses : bas, gauche, droite, haut) en
planche d'attente de jeu (4 colonnes × 1 ligne), calée sur la planche de marche du personnage.

Décision de Kevin du 2026-10-06 : à l'arrêt, `idle_<dir>` venait de la colonne 0 (« passage »)
de la marche, jambes écartées ; la planche d'attente (pieds joints) la remplace.

- Échelle : commune aux 4 poses ; la pose de face et la pose de dos prennent en moyenne la
  hauteur des images « passage » (colonne 0) de face et de dos de la planche de marche (même
  taille de personnage que la marche). Jamais plus haute que la cellule.
- Cellule : même hauteur que la marche (même ancrage aux pieds dans le jeu : décalage du sprite
  = demi-hauteur de l'image) ; largeur = celle de la marche, élargie si une pose ne tient pas.
- Ancrage : centre de la tête au centre de la cellule, pieds sur le bas de la cellule.
- `--miroir gauche` : la pose gauche = miroir de la pose droite ; `--miroir droite` : l'inverse
  (quand Codex rate un profil, ex. le livreur de droite : sacoche cachée derrière la hanche alors
  que la marche la montre dans le dos).
Usage :
  tools/art/decouper_attente.py bande.png planche_marche.png sortie.png [--miroir gauche|droite]
Normalement appelé par preparer.py (groupe `attentes` du manifeste).
"""
from __future__ import annotations

import argparse

from PIL import Image

from decouper_perso import _bandes, _centre_tete, _separer

COLONNES = 4
LIGNE_BAS, LIGNE_HAUT = 0, 3


def _masque(image: Image.Image) -> Image.Image:
	return image.getchannel("A").point(lambda a: 255 if a > 96 else 0)


def _poses_bande(bande: Image.Image) -> list[Image.Image]:
	masque = _masque(bande)
	largeur, hauteur = masque.size
	donnees = masque.load()
	colonnes = [sum(1 for y in range(hauteur) if donnees[x, y]) for x in range(largeur)]
	plages = _separer(_bandes(colonnes, COLONNES), colonnes, COLONNES)
	poses = []
	for gauche, droite in plages:
		cellule = bande.crop((gauche, 0, droite, hauteur))
		poses.append(cellule.crop(_masque(cellule).getbbox()))
	if len(poses) != COLONNES:
		raise SystemExit(f"{len(poses)} poses trouvées au lieu de {COLONNES}")
	return poses


def _hauteur_marche(marche: Image.Image, cellule_l: int, cellule_h: int, ligne: int) -> int:
	cellule = marche.crop((0, ligne * cellule_h, cellule_l, (ligne + 1) * cellule_h))
	boite = _masque(cellule).getbbox()
	return boite[3] - boite[1]


def decouper(source: str, chemin_marche: str, sortie: str,
		miroir: str | None = None, rapport_hauteur: float | None = None) -> tuple[int, int]:
	"""Écrit la planche d'attente ; renvoie la taille d'une cellule. `rapport_hauteur` : pose
	plus basse que la marche (la Sbire ♀ qui creuse, série 14 : 0,75) ; ses poses de face et de
	dos prennent cette part de la hauteur de la marche (même échelle de personnage), dans une
	cellule de la hauteur de la marche, pieds sur le bas (même ancrage)."""
	marche = Image.open(chemin_marche).convert("RGBA")
	cellule_l, cellule_h = marche.width // COLONNES, marche.height // 4
	poses = _poses_bande(Image.open(source).convert("RGBA"))
	if miroir == "gauche":
		poses[1] = poses[2].transpose(Image.FLIP_LEFT_RIGHT)
	elif miroir == "droite":
		poses[2] = poses[1].transpose(Image.FLIP_LEFT_RIGHT)
	elif miroir is not None:
		raise SystemExit(f"miroir inconnu : {miroir}")
	rapports = [_hauteur_marche(marche, cellule_l, cellule_h, ligne) / poses[colonne].height
		for colonne, ligne in ((0, LIGNE_BAS), (3, LIGNE_HAUT))]
	echelle = sum(rapports) / len(rapports)
	if rapport_hauteur is not None:
		echelle *= rapport_hauteur
	echelle = min(echelle, (cellule_h - 1) / max(p.height for p in poses))
	reduites = []
	demi = cellule_l / 2
	for pose in poses:
		reduite = pose.resize((max(1, round(pose.width * echelle)),
			max(1, round(pose.height * echelle))), Image.LANCZOS)
		tete = _centre_tete(pose) * echelle
		demi = max(demi, tete + 1, reduite.width - tete + 1)
		reduites.append((reduite, tete))
	largeur = max(cellule_l, 2 * int(demi + 0.999) + (cellule_l % 2))
	planche = Image.new("RGBA", (largeur * COLONNES, cellule_h), (0, 0, 0, 0))
	for colonne, (reduite, tete) in enumerate(reduites):
		x = colonne * largeur + round(largeur / 2 - tete)
		planche.alpha_composite(reduite, (x, cellule_h - reduite.height))
	planche.save(sortie)
	print(f"{sortie} : cellule {largeur} × {cellule_h}, échelle {echelle:.4f}")
	return largeur, cellule_h


def main() -> None:
	arguments = argparse.ArgumentParser()
	arguments.add_argument("source")
	arguments.add_argument("marche")
	arguments.add_argument("sortie")
	arguments.add_argument("--miroir", choices=["gauche", "droite"], default=None)
	arguments.add_argument("--rapport-hauteur", type=float, default=None)
	options = arguments.parse_args()
	decouper(options.source, options.marche, options.sortie, options.miroir,
		options.rapport_hauteur)


if __name__ == "__main__":
	main()
