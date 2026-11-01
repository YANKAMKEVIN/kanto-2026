"""Chantier CO (costumes du Dresseur) : écrit les prompts des planches de chara design.

Une planche par badge : à gauche le costume du joueur, à droite celui de la joueuse.
Usage : python3 tools/art/costumes/prompts_co.py  → tools/art/costumes/prompts/CO_PLANCHE_<BADGE>.txt
"""
from pathlib import Path

# badge : (joueur, description joueur, joueuse, description joueuse)
COSTUMES = {
    "ROCHE": ("Tanjiro (Demon Slayer)", "cheveux bordeaux, cicatrice rouge sur le front côté gauche, boucles d'oreilles en plaquettes rectangulaires à soleil levant, veste à damier vert et noir sur un uniforme noir à ceinture blanche, sabre au fourreau à la taille, guêtres blanches, sandales",
              "Nezuko (Demon Slayer)", "longs cheveux noirs aux pointes orangées, ruban rose dans les cheveux, petit bambou vert tenu en travers de la bouche, kimono rose à motif de feuilles de chanvre, veste courte marron à carreaux, obi noir, sandales"),
    "CASCADE": ("Luffy (One Piece)", "chapeau de paille à ruban rouge, cheveux noirs en bataille, petite cicatrice sous l'œil gauche, chemise rouge sans manches ouverte, short bleu retroussé à revers blancs, sandales, grand sourire",
                "Nami (One Piece)", "cheveux orange longs, haut bikini à rayures bleu et blanc sous un petit gilet, jupe ou pantacourt, bâton bleu repliable à la ceinture, tatouage bleu discret à l'épaule"),
    "FOUDRE": ("Iron Man", "armure rouge et or brillante, réacteur circulaire lumineux bleu-blanc au centre du torse, casque avec visière or ; visage du personnage visible, visière relevée",
               "Iron Woman", "armure rouge et or aux lignes plus fines, réacteur circulaire lumineux au torse, casque à visière relevée laissant voir le visage, cheveux qui dépassent"),
    "PRISME": ("Link (Zelda)", "tunique verte et bonnet vert pointu, cheveux blonds, oreilles pointues, ceinture de cuir, épée dans son fourreau et bouclier bleu au blason rouge dans le dos",
               "la princesse Zelda en tenue d'aventure", "cheveux blonds tressés, oreilles pointues, tunique bleue de voyageuse, pantalon sombre, bottes, serre-tête doré, petite tablette à la ceinture"),
    "AME": ("Naruto", "cheveux blonds hérissés, bandeau frontal métallique gravé d'une feuille, trois traits sur chaque joue, survêtement orange et bleu, sandales ninja",
            "Sakura (Naruto)", "cheveux roses courts, bandeau frontal métallique gravé d'une feuille porté en serre-tête, haut rouge sans manches à col, short noir, gants, sandales ninja"),
    "MARAIS": ("Deku (My Hero Academia)", "cheveux verts bouclés en bataille, taches de rousseur, combinaison de héros vert foncé à bandes noires, masque respiratoire relevé sur la nuque, gants blancs et rouges, grosses bottes rouges",
               "Ochaco (My Hero Academia)", "cheveux châtains au carré court, joues roses, combinaison de héroïne noire et rose pâle, casque-visière rose relevé, gros bracelets aux poignets, bottes"),
    "VOLCAN": ("Son Goku (Dragon Ball)", "cheveux noirs en pointes caractéristiques, kimono de combat orange avec ceinture et poignets bleus, sous-maillot bleu, bottes bleues, pose de combat confiante",
               "une combattante saiyan (Dragon Ball)", "cheveux noirs en pointes ou en grande queue hérissée, tenue de combat orange et bleue de même école que Goku, poignets bleus, bottes, pose de combat confiante"),
    "TERRE": ("Batman", "masque noir à oreilles pointues laissant voir le bas du visage, cape noire, combinaison gris foncé, chauve-souris noire sur le torse, ceinture utilitaire jaune, gants noirs",
              "Batgirl", "masque noir à oreilles pointues, cheveux roux longs qui dépassent, cape noire, combinaison sombre, chauve-souris jaune sur le torse, ceinture utilitaire jaune"),
}

GABARIT = """CO_PLANCHE_{badge} — PLANCHE DE CHARA DESIGN (référence, pas un asset de jeu) de deux COSTUMES que le personnage joueur peut porter dans le jeu.
Images jointes : le héros (heros_portrait, heros_sheet) et la joueuse (joueuse_portrait, joueuse_sheet) existants. Les costumes doivent sembler faits pour CE jeu : même main peinte, mêmes proportions chibi légères (grosse tête, yeux expressifs, corps d'enfant d'environ 11 ans), même taille de silhouette que les images jointes.
Style : illustration 2D peinte numériquement, EXACTEMENT la même main que les images jointes : contour fin et doux d'une teinte sombre et colorée, aucun trait noir, trois valeurs nettes par matériau, légère granularité de pinceau, lumière douce venant du haut à gauche. Ni pixel art, ni 3D, ni photo.
À GAUCHE, version garçon : {joueur}, en version chibi aux proportions du héros joint. Tenue et signes reconnaissables : {desc_joueur}.
À DROITE, version fille : {joueuse}, en version chibi aux proportions de la joueuse jointe. Tenue et signes reconnaissables : {desc_joueuse}.
Les deux personnages doivent être immédiatement reconnaissables, mais dessinés comme des enfants du même âge que le héros et la joueuse.
PLANCHE : image paysage 1536 × 1024, fond uni gris clair neutre, aucun texte, aucune étiquette, aucun numéro, aucun cadre.
- Pour chaque personnage (moitié gauche : garçon ; moitié droite : fille) : un PORTRAIT EN PIED de trois quarts face, cadré et posé comme heros_portrait (entier, de la tête aux pieds, environ 700 px de haut) ; à côté, deux petites vues au format SPRITE DE JEU dans le style exact de heros_sheet (environ 260 px de haut, alignées sur la même ligne de pieds) : debout vue de FACE et debout vue de DOS.
Même personnage, mêmes couleurs dans ses trois figures.
"""

# Repli quand le filtre de Codex bloque un personnage de licence (2026-10-30 : Iron Man, Link, Batman ;
# Mario et Harry Potter, refusés quatre fois, remplacés par Tanjiro et Deku) : on décrit la tenue sans nommer personne.
SANS_NOM = {
    "FOUDRE": ("un garçon en armure de super-héros high-tech", "une fille en armure de super-héroïne high-tech"),
    "PRISME": ("un jeune héros d'épopée fantastique elfique", "une jeune princesse elfique aventurière"),
    "TERRE": ("un jeune justicier masqué de la nuit", "une jeune justicière masquée de la nuit"),
}


# Second repli (2026-10-30 : FOUDRE et TERRE encore bloqués, même sans images
# jointes) : tenue adoucie, sans logo ni signe distinctif déposé, en gardant l'esprit du personnage.
ADOUCI = {
    "FOUDRE": ("armure robotique rouge aux plaques dorées, petite lumière ronde bleutée sur la poitrine, casque ouvert qui laisse voir le visage",
               "armure robotique rouge aux plaques dorées plus fines, petite lumière ronde bleutée sur la poitrine, casque ouvert, cheveux qui dépassent"),
    "TERRE": ("loup de tissu noir sur les yeux, capuche noire, longue cape noire, combinaison gris anthracite, ceinture à poches jaune, gants noirs",
              "loup de tissu noir sur les yeux, longs cheveux roux, longue cape noire, combinaison violet très sombre, ceinture à poches jaune, gants noirs"),
}


if __name__ == "__main__":
    dossier = Path(__file__).parent / "prompts"
    dossier.mkdir(exist_ok=True)
    for badge, (j, dj, f, df) in COSTUMES.items():
        if badge in SANS_NOM:
            j, f = SANS_NOM[badge]
        if badge in ADOUCI:
            dj, df = ADOUCI[badge]
        texte = GABARIT.format(badge=badge, joueur=j, desc_joueur=dj, joueuse=f, desc_joueuse=df)
        (dossier / f"CO_PLANCHE_{badge}.txt").write_text(texte, encoding="utf-8")
        print(f"CO_PLANCHE_{badge}")
