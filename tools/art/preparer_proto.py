#!/usr/bin/env python3
"""Prépare les assets validés de la série 01 pour la scène prototype de Jadielle.

Lit les images validées dans build/art/ (non versionné), les recadre sur leur
silhouette, les ramène à leur taille en jeu (1 case = 96 px) et les écrit dans
proto/da_jadielle/tex/. Cahier de l'art du monde §5, fiches série 01.
Usage : tools/art/preparer_proto.py
"""
from pathlib import Path

from PIL import Image, ImageEnhance

RACINE = Path(__file__).resolve().parents[2]
SOURCE = RACINE / "build" / "art"
SORTIE = RACINE / "proto" / "da_jadielle" / "tex"
CASE = 96

# (fichier validé, nom de sortie, dimension imposée en cases : ("h", n) ou ("w", n))
OBJETS = [
    ("WORLD_TREE_A_01_GH_r3_etal.png", "tree_a.png", ("h", 4)),
    ("WORLD_TREE_B_01_GH_r1_etal.png", "tree_b.png", ("h", 5)),
    ("WORLD_TREE_CENTRAL_01_GH_r1_etal.png", "tree_central.png", ("h", 6)),
    # Bâtiments sur 8 cases de large (défaut d'échelle noté dans la fiche).
    ("VALIDE_CENTRE.png", "centre.png", ("w", 8)),
    ("VALIDE_BOUTIQUE.png", "boutique.png", ("w", 8)),
]
SOLS = [
    ("VALIDE_HERBE.png", "herbe.png", 1.0),
    ("VALIDE_PAVE_CENTRE.png", "paves.png", 0.7),  # contraste réduit (fiche)
]
TEXTURE_SOL = 384  # 4 × 4 cases
PLANCHE_BORDURE = "VALIDE_DECAL_BORD.png"
PLANCHE_CASE = 256  # 1 case = 256 px dans la planche


def _silhouette(image: Image.Image) -> Image.Image:
    masque = image.getchannel("A").point(lambda a: 255 if a > 32 else 0)
    return image.crop(masque.getbbox())


def _objets() -> None:
    for source, sortie, (axe, cases) in OBJETS:
        image = _silhouette(Image.open(SOURCE / source).convert("RGBA"))
        largeur, hauteur = image.size
        echelle = cases * CASE / (hauteur if axe == "h" else largeur)
        taille = (round(largeur * echelle), round(hauteur * echelle))
        image.resize(taille, Image.LANCZOS).save(SORTIE / sortie)
        print(f"{sortie} : {taille[0]} × {taille[1]}")


def _sols() -> None:
    for source, sortie, contraste in SOLS:
        image = Image.open(SOURCE / source).convert("RGB")
        image = image.resize((TEXTURE_SOL, TEXTURE_SOL), Image.LANCZOS)
        if contraste != 1.0:
            image = ImageEnhance.Contrast(image).enhance(contraste)
        image.save(SORTIE / sortie)
        print(f"{sortie} : {TEXTURE_SOL} × {TEXTURE_SOL}")


def _bordure() -> None:
    planche = Image.open(SOURCE / PLANCHE_BORDURE).convert("RGBA")
    colonnes, lignes = 4, 3
    largeur, hauteur = planche.width // colonnes, planche.height // lignes
    echelle = CASE / PLANCHE_CASE
    noms = ["touffe", "pave", "terre"]
    for ligne in range(lignes):
        for colonne in range(colonnes):
            cellule = planche.crop((colonne * largeur, ligne * hauteur,
                                    (colonne + 1) * largeur, (ligne + 1) * hauteur))
            element = _silhouette(cellule)
            taille = (max(1, round(element.width * echelle)), max(1, round(element.height * echelle)))
            nom = f"bord_{noms[ligne]}_{colonne + 1}.png"
            element.resize(taille, Image.LANCZOS).save(SORTIE / nom)
            print(f"{nom} : {taille[0]} × {taille[1]}")


if __name__ == "__main__":
    SORTIE.mkdir(parents=True, exist_ok=True)
    _objets()
    _sols()
    _bordure()
