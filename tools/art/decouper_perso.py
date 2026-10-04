#!/usr/bin/env python3
"""Découpe une planche de marche générée (4 × 4 poses) en planche de jeu.

Lignes : bas, gauche, droite, haut ; colonnes : les 4 images du cycle de marche.
Chaque pose est recalée sur la tête (centre horizontal) et les pieds (bas), puis réduite à la
hauteur voulue avec une échelle commune à toutes les poses.
Usage :
  tools/art/decouper_perso.py source.png sortie.png --hauteur 64 --pixel   (piste pixel art)
  tools/art/decouper_perso.py source.png sortie.png --hauteur 128          (piste peinte)
"""
import argparse

from PIL import Image

COLONNES, LIGNES = 4, 4


def _bandes(profil: list[int], nombre: int) -> list[tuple[int, int]]:
    """Les `nombre` plus grandes plages non vides d'un profil (lignes ou colonnes)."""
    plages, debut = [], None
    for i, valeur in enumerate(profil + [0]):
        if valeur and debut is None:
            debut = i
        elif not valeur and debut is not None:
            plages.append((debut, i))
            debut = None
    plages = sorted(plages, key=lambda p: p[1] - p[0], reverse=True)[:nombre]
    return sorted(plages)


def _poses(planche: Image.Image) -> list[Image.Image]:
    """Découpe en suivant les vides de la planche (les poses générées ne tombent pas
    toujours dans une grille régulière)."""
    alpha = planche.getchannel("A").point(lambda a: 255 if a > 96 else 0)
    largeur, hauteur = alpha.size
    donnees = alpha.load()
    lignes = [sum(1 for x in range(largeur) if donnees[x, y]) for y in range(hauteur)]
    poses = []
    for haut, bas in _bandes(lignes, LIGNES):
        colonnes = [sum(1 for y in range(haut, bas) if donnees[x, y]) for x in range(largeur)]
        for gauche, droite in _bandes(colonnes, COLONNES):
            cellule = planche.crop((gauche, haut, droite, bas))
            masque = cellule.getchannel("A").point(lambda a: 255 if a > 96 else 0)
            poses.append(cellule.crop(masque.getbbox()))
    if len(poses) != LIGNES * COLONNES:
        raise SystemExit(f"{len(poses)} poses trouvées au lieu de {LIGNES * COLONNES}")
    return poses


def _centre_tete(pose: Image.Image) -> float:
    haut = pose.crop((0, 0, pose.width, max(1, int(pose.height * 0.35))))
    boite = haut.getchannel("A").point(lambda a: 255 if a > 96 else 0).getbbox()
    return (boite[0] + boite[2]) / 2.0 if boite else pose.width / 2.0


def decouper(source: str, sortie: str, hauteur: int, pixel: bool = False) -> tuple[int, int]:
    """Découpe `source` en planche de jeu 4 × 4 ; renvoie la taille d'une cellule."""
    poses = _poses(Image.open(source).convert("RGBA"))
    echelle = hauteur / max(p.height for p in poses)
    marge_gauche = max(_centre_tete(p) for p in poses)
    marge_droite = max(p.width - _centre_tete(p) for p in poses)
    cellule_l = int((2 * max(marge_gauche, marge_droite)) * echelle) + 4
    cellule_h = hauteur + 2
    planche = Image.new("RGBA", (cellule_l * COLONNES, cellule_h * LIGNES), (0, 0, 0, 0))
    for index, pose in enumerate(poses):
        taille = (max(1, round(pose.width * echelle)), max(1, round(pose.height * echelle)))
        filtre = Image.BOX if pixel else Image.LANCZOS
        reduite = pose.resize(taille, filtre)
        if pixel:
            alpha = reduite.getchannel("A").point(lambda a: 255 if a > 110 else 0)
            couleurs = reduite.convert("RGB").quantize(colors=28, method=Image.MEDIANCUT)
            reduite = couleurs.convert("RGBA")
            reduite.putalpha(alpha)
        colonne, ligne = index % COLONNES, index // COLONNES
        x = colonne * cellule_l + round(cellule_l / 2 - _centre_tete(pose) * echelle)
        y = ligne * cellule_h + cellule_h - reduite.height
        planche.alpha_composite(reduite, (x, y))
    planche.save(sortie)
    return cellule_l, cellule_h


def main() -> None:
    arguments = argparse.ArgumentParser()
    arguments.add_argument("source")
    arguments.add_argument("sortie")
    arguments.add_argument("--hauteur", type=int, required=True)
    arguments.add_argument("--pixel", action="store_true")
    options = arguments.parse_args()
    cellule_l, cellule_h = decouper(options.source, options.sortie, options.hauteur, options.pixel)
    print(f"{options.sortie} : cellule {cellule_l} × {cellule_h}")


if __name__ == "__main__":
    main()
