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
    # J7.1 (générés par Codex). Le massif n'est pas étalonné : ses fleurs jaunes verdiraient.
    ("WORLD_PROP_MASSIF_01_GH_r1.png", "massif.png", ("w", 4)),
    ("WORLD_PROP_BANC_01_GH_r1.png", "banc.png", ("w", 2)),
    ("WORLD_PROP_LAMPADAIRE_01_GH_r1.png", "lampadaire.png", ("h", 2.6)),
    # Variantes de lumière neutre (comparaison GH / NE du cahier §5.3).
    ("WORLD_TREE_A_01_NE_r1.png", "tree_a_ne.png", ("h", 4)),
    ("WORLD_TREE_B_01_NE_r1.png", "tree_b_ne.png", ("h", 5)),
    ("WORLD_TREE_CENTRAL_01_NE_r1.png", "tree_central_ne.png", ("h", 6)),
    ("WORLD_BLDG_CENTRE_01_NE_r1.png", "centre_ne.png", ("w", 8)),
    ("WORLD_BLDG_BOUTIQUE_01_NE_r1.png", "boutique_ne.png", ("w", 8)),
    # Intérieurs du Centre et de la Boutique (série 03, lumière neutre).
    ("INT_CENTRE_COMPTOIR_NE_r1.png", "int_comptoir.png", ("w", 5)),
    ("INT_CENTRE_TERMINAL_NE_r1.png", "int_terminal.png", ("h", 2.2)),
    ("INT_CENTRE_BANQUETTE_NE_r1.png", "int_banquette.png", ("w", 2.3)),
    ("INT_PLANTE_NE_r1.png", "int_plante.png", ("h", 2.4)),
    ("INT_BOUTIQUE_CAISSE_NE_r1.png", "int_caisse.png", ("w", 5)),
    ("INT_BOUTIQUE_RAYON_MURAL_NE_r1.png", "int_rayon.png", ("w", 2.7)),
    ("INT_BOUTIQUE_PRESENTOIR_NE_r1.png", "int_presentoir.png", ("w", 3)),
    # Reste de Jadielle (série 04, lumière neutre).
    ("WORLD_BLDG_MAISON_A_01_NE_r1.png", "maison_a.png", ("w", 6)),
    ("WORLD_BLDG_MAISON_B_01_NE_r1.png", "maison_b.png", ("w", 5.5)),
    ("WORLD_BLDG_ARENE_01_NE_r1.png", "arene.png", ("w", 10)),
    ("WORLD_PROP_HAIE_01_NE_r1.png", "haie.png", ("w", 4)),
    ("WORLD_PROP_CLOTURE_01_NE_r1.png", "cloture.png", ("w", 4)),
    ("WORLD_PROP_PANNEAU_01_NE_r1.png", "panneau.png", ("h", 2)),
    ("WORLD_PROP_PORTE_NORD_01_NE_r1.png", "porte_nord.png", ("w", 5)),
    # Route 22 (série 05, lumière neutre).
    ("WORLD_RELIEF_FALAISE_01_NE_r1.png", "falaise.png", ("w", 4)),
    ("WORLD_RELIEF_ESCALIER_01_NE_r1.png", "escalier.png", ("w", 2.2)),
    ("WORLD_PROP_ROCHER_01_NE_r1.png", "rocher.png", ("w", 2)),
    ("WORLD_GROUND_HAUTES_HERBES_01_NE_r1.png", "hautes_herbes.png", ("w", 1.15)),
    # Bourg Palette (série 06, lumière neutre) ; boîte aux lettres et potager repris du J7.
    ("WORLD_BLDG_MAISON_JOUEUR_01_NE_r1.png", "maison_joueur.png", ("w", 6.5)),
    ("WORLD_BLDG_MAISON_RIVAL_01_NE_r1.png", "maison_rival.png", ("w", 6.5)),
    ("WORLD_BLDG_LABO_01_NE_r1.png", "labo.png", ("w", 10)),
    ("WORLD_BLDG_SERRE_01_NE_r1.png", "serre.png", ("w", 3)),
    ("WORLD_TREE_ANCIEN_01_NE_r1.png", "arbre_ancien.png", ("w", 6)),
    ("WORLD_PROP_CLOTURE_PIQUETS_01_NE_r1.png", "cloture_piquets.png", ("w", 4)),
    ("WORLD_PROP_VELO_01_NE_r1.png", "velo.png", ("w", 1.6)),
    ("WORLD_PROP_CAMIONNETTE_01_NE_r1.png", "camionnette.png", ("w", 2.4)),
    ("WORLD_GROUND_CHAMP_01_NE_r1.png", "champ.png", ("w", 6)),
    ("WORLD_PROP_PONTON_01_NE_r1.png", "ponton.png", ("w", 5)),
    ("WORLD_PROP_RONCES_01_NE_r1.png", "ronces.png", ("w", 2)),
    ("WORLD_PROP_TRONC_COUCHE_01_NE_r1.png", "tronc_couche.png", ("w", 3)),
    ("WORLD_PROP_ROCHER_MER_01_NE_r1.png", "rocher_mer.png", ("w", 2)),
    ("WORLD_RELIEF_ESCALIER_BOIS_01_NE_r1.png", "escalier_bois.png", ("w", 2)),
    ("WORLD_PROP_BOITE_LETTRES_01_NE_r1.png", "boite_lettres.png", ("h", 1.3)),
    ("WORLD_PROP_POTAGER_01_NE_r1.png", "potager.png", ("w", 3)),
]
# Enveloppes des pièces (15 × 10 cases), opaques.
PIECES = [
    ("INT_CENTRE_COQUE_NE_r1.png", "int_centre_coque.png"),
    ("INT_BOUTIQUE_COQUE_NE_r2.png", "int_boutique_coque.png"),
]
SOLS = [
    ("VALIDE_HERBE.png", "herbe.png", 1.0),
    ("VALIDE_PAVE_CENTRE.png", "paves.png", 0.7),  # contraste réduit (fiche)
    ("WORLD_GROUND_CHEMIN_01_NE_r1.png", "chemin.png", 0.55),
    ("WORLD_GROUND_SABLE_01_NE_r1.png", "sable.png", 0.8),
    ("WORLD_GROUND_EAU_01_NE_r1.png", "eau.png", 1.0),
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


def _pieces() -> None:
    for source, sortie in PIECES:
        image = Image.open(SOURCE / source).convert("RGB").resize((15 * CASE, 10 * CASE),
                                                                   Image.LANCZOS)
        image.save(SORTIE / sortie)
        print(f"{sortie} : {image.width} × {image.height}")


def _decor() -> None:
    image = Image.open(SOURCE / "WORLD_DECOR_PLATEAU_INDIGO_01_NE_r1.png").convert("RGB")
    image.save(SORTIE / "plateau_indigo.png")
    print("plateau_indigo.png : 1536 × 1024")


def _sols() -> None:
    for source, sortie, contraste in SOLS:
        image = Image.open(SOURCE / source).convert("RGB")
        image = image.resize((TEXTURE_SOL, TEXTURE_SOL), Image.LANCZOS)
        if contraste != 1.0:
            image = ImageEnhance.Contrast(image).enhance(contraste)
        if sortie == "chemin.png":
            # Terre trop orangée à la génération : ramenée vers l'ocre clair.
            image = ImageEnhance.Color(image).enhance(0.55)
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
    _pieces()
    _decor()
    _sols()
    _bordure()
