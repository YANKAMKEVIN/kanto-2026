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
    # Habillage de Bourg Palette, repris des sessions du J7 (lumière neutre).
    ("WORLD_PROP_BUISSON_A_01_NE_r1.png", "buisson_a.png", ("w", 1.4)),
    ("WORLD_PROP_BUISSON_B_01_NE_r1.png", "buisson_b.png", ("w", 1.5)),
    ("WORLD_PROP_BUISSON_C_01_NE_r1.png", "buisson_c.png", ("w", 1.3)),
    ("WORLD_PROP_PLATEBANDE_01_NE_r1.png", "platebande.png", ("w", 3)),
    ("WORLD_PROP_POTS_FLEURS_01_NE_r1.png", "pots_fleurs.png", ("w", 1)),
    ("WORLD_PROP_TONNEAU_01_NE_r1.png", "tonneau.png", ("h", 1)),
    ("WORLD_PROP_LINGE_01_NE_r1.png", "linge.png", ("w", 2.6)),
    ("WORLD_TREE_FRUITIER_01_NE_r1.png", "fruitier.png", ("h", 3.6)),
    ("WORLD_PROP_CAISSES_01_NE_r1.png", "caisses.png", ("w", 1.3)),
    ("WORLD_PROP_HAIE_V_01_NE_r1.png", "haie_v.png", ("h", 3.6)),
    # Habillage de Bourg Palette (série 06B, lumière neutre).
    ("WORLD_PROP_CLOTURE_PIQUETS_V_01_NE_r1.png", "cloture_piquets_v.png", ("h", 3.4)),
    ("WORLD_TREE_C_01_NE_r1.png", "tree_c_ne.png", ("h", 4)),
    ("WORLD_TREE_D_01_NE_r1.png", "tree_d_ne.png", ("h", 4.4)),
    ("WORLD_TREE_E_01_NE_r1.png", "tree_e_ne.png", ("h", 5)),
    ("WORLD_PROP_HORTENSIAS_01_NE_r1.png", "hortensias.png", ("w", 1.5)),
    ("WORLD_PROP_JARDINIERE_01_NE_r1.png", "jardiniere_fleurs.png", ("w", 2.6)),
    ("WORLD_PROP_MANGEOIRE_01_NE_r1.png", "mangeoire.png", ("h", 1.8)),
    ("WORLD_PROP_EPOUVANTAIL_01_NE_r1.png", "epouvantail.png", ("h", 2)),
    ("WORLD_PROP_BARQUE_01_NE_r1.png", "barque.png", ("h", 2.6)),
    ("WORLD_PROP_CASIERS_PECHE_01_NE_r1.png", "casiers.png", ("w", 1.6)),
    ("WORLD_PROP_HERBES_DUNE_01_NE_r1.png", "oyats.png", ("w", 1)),
    ("WORLD_PROP_MATERIEL_LABO_01_NE_r1.png", "materiel_labo.png", ("w", 2.2)),
    ("WORLD_PROP_RATELIER_VELOS_01_NE_r1.png", "ratelier.png", ("w", 2.2)),
    ("WORLD_PROP_BROUETTE_01_NE_r1.png", "brouette.png", ("w", 1.4)),
    ("WORLD_PROP_TAS_BOIS_01_NE_r1.png", "tas_bois.png", ("w", 1.8)),
    ("WORLD_PROP_ARROSOIR_SEAU_01_NE_r1.png", "arrosoir.png", ("w", 0.9)),
    ("WORLD_PROP_PIERRES_01_NE_r1.png", "pierres.png", ("w", 0.9)),
    # Intérieurs de Bourg Palette (série 07, lumière neutre).
    ("INT_MEUBLE_BAS_01_NE_r1.png", "int_meuble_bas.png", ("w", 3)),
    ("INT_CANAPE_01_NE_r1.png", "int_canape.png", ("w", 3)),
    ("INT_TABLE_BASSE_01_NE_r1.png", "int_table_basse.png", ("w", 2)),
    ("INT_TABLE_REPAS_01_NE_r1.png", "int_table_repas.png", ("w", 3)),
    ("INT_FRIGO_01_NE_r1.png", "int_frigo.png", ("w", 1)),
    ("INT_CUISINE_01_NE_r1.png", "int_cuisine.png", ("w", 3)),
    ("INT_ESCALIER_MONTANT_01_NE_r1.png", "int_escalier_montant.png", ("w", 2.2)),
    ("INT_TELE_01_NE_r1.png", "int_tele.png", ("w", 2)),
    ("INT_PORTE_MANTEAU_01_NE_r1.png", "int_porte_manteau.png", ("w", 1)),
    ("INT_COMMODE_POKEBALL_01_NE_r1.png", "int_commode_pokeball.png", ("w", 1)),
    ("INT_TAPIS_SALON_01_NE_r1.png", "int_tapis_salon.png", ("w", 3)),
    ("INT_TAPIS_PLAID_01_NE_r1.png", "int_tapis_plaid.png", ("w", 5)),
    ("INT_LIT_01_NE_r1.png", "int_lit.png", ("w", 2)),
    ("INT_CHEVET_LAMPE_01_NE_r1.png", "int_chevet.png", ("w", 1)),
    ("INT_PETITE_ETAGERE_01_NE_r1.png", "int_petite_etagere.png", ("w", 1)),
    ("INT_BUREAU_PC_01_NE_r1.png", "int_bureau_pc.png", ("w", 3)),
    ("INT_CHAISE_BUREAU_01_NE_r1.png", "int_chaise_bureau.png", ("w", 0.8)),
    ("INT_GRANDE_ETAGERE_01_NE_r1.png", "int_grande_etagere.png", ("w", 2)),
    ("INT_SAC_VOYAGE_01_NE_r1.png", "int_sac.png", ("w", 0.9)),
    ("INT_CAISSE_POKEBALLS_01_NE_r1.png", "int_caisse_pokeballs.png", ("w", 2)),
    ("INT_TAPIS_POKEBALL_01_NE_r1.png", "int_tapis_pokeball.png", ("w", 4)),
    ("INT_TAPIS_CARREAUX_01_NE_r1.png", "int_tapis_carreaux.png", ("w", 2)),
    ("INT_CUISINIERE_HOTTE_01_NE_r1.png", "int_cuisiniere.png", ("w", 1)),
    ("INT_BUREAU_ANGLE_PC_01_NE_r1.png", "int_bureau_angle.png", ("w", 2)),
    ("INT_CHAISE_GAMER_01_NE_r1.png", "int_chaise_gamer.png", ("w", 0.9)),
    ("INT_COMMODE_01_NE_r1.png", "int_commode.png", ("w", 2)),
    ("INT_LIT_POKEBALL_01_NE_r1.png", "int_lit_pokeball.png", ("w", 2)),
    ("INT_LAVABO_01_NE_r1.png", "int_lavabo.png", ("w", 2)),
    ("INT_DOUCHE_01_NE_r1.png", "int_douche.png", ("w", 1)),
    ("INT_MEUBLE_CHAUSSURES_01_NE_r1.png", "int_meuble_chaussures.png", ("w", 1)),
    ("INT_CLOISON_V_01_NE_r1.png", "int_cloison_v.png", ("h", 3.6)),
    ("INT_CLOISON_H_01_NE_r1.png", "int_cloison_h.png", ("w", 5)),
    ("INT_AQUARIUM_01_NE_r1.png", "int_aquarium.png", ("w", 1)),
    ("INT_INCUBATEUR_01_NE_r1.png", "int_incubateur.png", ("w", 2)),
    ("INT_MACHINES_LABO_01_NE_r1.png", "int_machines.png", ("w", 2)),
    ("INT_BUREAU_CHEN_01_NE_r1.png", "int_bureau_chen.png", ("w", 3)),
    ("INT_CLASSEUR_01_NE_r1.png", "int_classeur.png", ("w", 1)),
    ("INT_ETAGERE_LABO_01_NE_r1.png", "int_etagere_labo.png", ("w", 2)),
    ("INT_VITRINE_POKEBALLS_01_NE_r1.png", "int_vitrine.png", ("w", 1)),
    ("INT_LONG_COMPTOIR_01_NE_r1.png", "int_long_comptoir.png", ("w", 5)),
    ("INT_TABLE_STARTERS_01_NE_r1.png", "int_table_starters.png", ("w", 3)),
    ("INT_PAILLASSE_01_NE_r1.png", "int_paillasse.png", ("w", 3)),
    ("INT_TABOURET_01_NE_r1.png", "int_tabouret.png", ("w", 0.7)),
    ("INT_ESCALIER_DECO_01_NE_r1.png", "int_escalier_deco.png", ("w", 3)),
    ("INT_TAPIS_ROUGE_01_NE_r1.png", "int_tapis_rouge.png", ("w", 4)),
    ("INT_TAPIS_LABO_POKEBALL_01_NE_r1.png", "int_tapis_labo.png", ("w", 4)),
]
# Enveloppes des pièces (15 × 10 cases), opaques.
PIECES = [
    ("INT_CENTRE_COQUE_NE_r1.png", "int_centre_coque.png"),
    ("INT_BOUTIQUE_COQUE_NE_r2.png", "int_boutique_coque.png"),
]
# Enveloppes des pièces de Bourg Palette (série 07) : (source, sortie, largeur, profondeur en cases).
PIECES_BOURG = [
    ("INT_CHAMBRE_JOUEUR_COQUE_NE_r1.png", "int_chambre_coque.png", 14, 10),
    ("INT_MAISON_JOUEUR_RDC_COQUE_NE_r1.png", "int_rdc_coque.png", 14, 10),
    ("INT_MAISON_RIVAL_COQUE_NE_r1.png", "int_rival_coque.png", 18, 11),
    ("INT_LABO_COQUE_NE_r1.png", "int_labo_coque.png", 16, 11),
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
        if not (SOURCE / source).exists():
            print(f"{sortie} : source absente ({source}), ignoré")
            continue
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
    for source, sortie, largeur, profondeur in PIECES_BOURG:
        image = Image.open(SOURCE / source).convert("RGB").resize((largeur * CASE, profondeur * CASE),
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


# Planches de décalcomanies 4 × 2 (série 06B) : (source, préfixe, largeur d'un élément en cases).
PLANCHES_DECAL = [
    ("WORLD_GROUND_FLEURS_SAUVAGES_01_NE_r1.png", "fleur", 0.55),
    ("WORLD_GROUND_FLEURS_COTIERES_01_NE_r1.png", "cote", 0.6),
]


def _decalcomanies() -> None:
    for source, prefixe, cases in PLANCHES_DECAL:
        planche = Image.open(SOURCE / source).convert("RGBA")
        largeur, hauteur = planche.width // 4, planche.height // 2
        for i in range(8):
            cellule = planche.crop(((i % 4) * largeur, (i // 4) * hauteur,
                                    (i % 4 + 1) * largeur, (i // 4 + 1) * hauteur))
            element = _silhouette(cellule)
            echelle = cases * CASE / element.width
            taille = (round(element.width * echelle), round(element.height * echelle))
            element.resize(taille, Image.LANCZOS).save(SORTIE / f"{prefixe}_{i + 1}.png")
        print(f"{prefixe}_1..8.png : {cases} case")


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
    _decalcomanies()
