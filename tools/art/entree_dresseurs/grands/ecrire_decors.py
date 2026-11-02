#!/usr/bin/env python3
"""Écrit les prompts des décors des grands combats (decor_<id>.txt, à côté de ce fichier).
Gabarit : celui des décors v2 des Champions (Safrania, Carmin, Jadielle). IMAGE 1 = Argenta v3
(cible du rendu et du cadrage) ; IMAGE 2 = ancien fond du lieu quand il est fidèle au lieu.

  python3 tools/art/entree_dresseurs/grands/ecrire_decors.py
"""
from pathlib import Path

D = Path(__file__).resolve().parent

COMMUN = """
PERSPECTIVE (impératif, la vue NE DOIT PAS être symétrique) : caméra sur la GAUCHE de la salle, regard légèrement vers la DROITE, en trois-quarts, comme sur IMAGE 1 : point de fuite vers x 62 %. Éléments de GAUCHE proches, grands, coupés par le bord gauche et par le haut ; ceux de droite plus petits et plus lointains.

CADRAGE (impératif) : le PIED DU MUR DU FOND est entre 38 et 42 % de la hauteur de l'image : tout ce qui est sous 42 % est le SOL (vaste, la moitié basse et plus).
- Point A (x 67 %, y 50 %) : sol plat et nu (l'adversaire y posera les pieds), rien de haut dans un rayon de 10 % de la largeur autour.
- Point B (x 31 %, y 97 %) : sol plat et nu au premier plan.
- Les 9 % de gauche et de droite ne contiennent rien d'important.

FORMAT : paysage très large, rapport 2,17 : 1 (comme 2340 × 1080), la plus grande résolution possible, OPAQUE, cadrage plein, sans bord.

RENDU : illustration 2D HD peinte, riche et détaillée, au niveau de l'IMAGE 1 (même main, même richesse, même profondeur), aucun trait noir épais, netteté partout (pas de flou, pas de vignettage).

INTERDITS : personnage, silhouette humaine, Pokémon, Poké Ball, banderole avec texte, interface, texte, lettres, chiffres, logo, signature, cadre, pixel art.
"""

REF_LIGUE = ("Images jointes : IMAGE 1 = un décor de combat VALIDÉ d'un autre lieu (l'Arène d'Argenta) : "
	"c'est la CIBLE du rendu, de la richesse, de la lumière, de la vue de trois-quarts et du cadrage (sol "
	"vaste, mur du fond vers 40 % de la hauteur) ; ce n'est PAS le lieu à peindre : ne reprends ni ses "
	"piliers de roche, ni son médaillon, ni ses bannières rouges.")
REF_ANCIEN = ("Images jointes : IMAGE 1 = un décor de combat VALIDÉ d'un autre lieu (l'Arène d'Argenta) : "
	"CIBLE du rendu, de la richesse, de la vue de trois-quarts et du cadrage ; ce n'est PAS le lieu à "
	"peindre. IMAGE 2 = l'ancien décor de ce lieu (lieu, matériaux et couleurs à GARDER), mais trop vide, "
	"trop plat et trop frontal : à rendre bien plus riche, profond et vivant, en vue de trois-quarts.")

DECORS = {
	"ligue_olga": ("SALLE D'OLGA, LIGUE POKÉMON",
		"Olga, membre du Conseil des Quatre (type Glace), premier des quatre combats de la Ligue au "
		"Plateau Indigo", REF_LIGUE,
		"la première salle du Conseil des Quatre, au cœur du Plateau Indigo : une salle d'honneur "
		"construite (PAS une grotte naturelle) envahie par la GLACE : murs de grands blocs de pierre "
		"bleu-gris couverts de givre, hauts piliers de pierre gainés de glace avec des stalactites, "
		"grappes de CRISTAUX DE GLACE bleu clair translucides aux pieds des murs et dans les angles, au "
		"fond une grande porte double sombre à ferrures dorées (la sortie vers la salle suivante) au "
		"sommet de deux ou trois marches givrées. Le SOL est un dallage de pierre recouvert d'une GLACE "
		"polie et lisse, bleu pâle, avec des reflets, des veines blanches et une fine neige poudreuse "
		"dans les joints. Lumière FROIDE bleutée et blanche qui tombe de hautes fenêtres givrées en haut "
		"à gauche, rayons doux, éclats lumineux dans les cristaux, petits flocons en suspension ; "
		"ambiance solennelle et glaciale."),
	"ligue_aldo": ("SALLE D'ALDO, LIGUE POKÉMON",
		"Aldo, membre du Conseil des Quatre (type Combat), deuxième combat de la Ligue au Plateau Indigo",
		REF_LIGUE,
		"la deuxième salle du Conseil des Quatre, au Plateau Indigo : une salle d'entraînement taillée "
		"dans la ROCHE brute : murs de roche brune et ocre aux strates marquées, gros ROCHERS gris sombre "
		"posés le long des murs et dans les angles, un grand pilier de roche brut à gauche, quelques "
		"blocs de pierre fendus comme frappés par des coups, une corde de paille tressée (shimenawa) "
		"tendue entre deux piliers de bois au fond, au fond une grande porte double sombre à ferrures "
		"dorées au sommet de quelques marches de pierre. Le SOL est de la roche sablée claire, damée et "
		"un peu craquelée, beige doré, avec des traces de pas et un peu de poussière. Lumière CHAUDE et "
		"dorée de grandes torches et braseros de fer aux murs, lueurs orangées, ombres franches, "
		"poussière dorée en suspension ; ambiance rude et puissante."),
	"ligue_agatha": ("SALLE D'AGATHA, LIGUE POKÉMON",
		"Agatha, membre du Conseil des Quatre (type Spectre), troisième combat de la Ligue au Plateau "
		"Indigo", REF_LIGUE,
		"la troisième salle du Conseil des Quatre, au Plateau Indigo : une salle funèbre et hantée, PAS "
		"la Tour Pokémon : murs de briques de pierre gris-violet sombre, hautes arches gothiques, "
		"petites TOMBES de pierre arrondies ornées de fleurs pâles et de bougies alignées le long des "
		"murs, grands CHANDELIERS de fer forgé aux bougies allumées, toiles d'araignée dans les angles "
		"hauts, au fond une grande porte double sombre à ferrures dorées au sommet de quelques marches. "
		"Le SOL est un dallage de grandes pierres lilas et violet pâle usées, fissurées, avec une BRUME "
		"violette basse qui rampe au ras du sol sur les côtés. Lumière froide VIOLETTE et mauve, lueurs "
		"spectrales flottantes (petites flammes bleu-violet sans forme vivante), flammes de bougies "
		"chaudes en contraste ; ambiance inquiétante et mystérieuse."),
	"ligue_peter": ("SALLE DE PETER, LIGUE POKÉMON",
		"Peter, membre du Conseil des Quatre (type Dragon), quatrième et dernier combat du Conseil au "
		"Plateau Indigo", REF_LIGUE,
		"la quatrième salle du Conseil des Quatre, au Plateau Indigo : une salle majestueuse et ardente : "
		"murs de briques rouge sombre et brun, veinées de fissures où rougeoient des BRAISES, grandes "
		"STATUES de pierre sombre de DRAGONS (têtes et ailes déployées, gargouilles) sur des socles de "
		"part et d'autre, grands CANDÉLABRES de bronze aux flammes vives, bannières rouge sombre sans "
		"aucun signe, un LONG TAPIS ROUGE bordé d'or qui traverse la salle vers une grande porte double "
		"sombre à ferrures dorées au fond (la sortie vers la salle du Maître). Le SOL est un dallage de "
		"pierre brun-rouge sombre, poli, avec des reflets chauds. Lumière CHAUDE orange et rouge de "
		"braise, étincelles qui montent, contre-jour doré au fond ; ambiance épique."),
	"ligue_maitre": ("SALLE DU MAÎTRE DE LA LIGUE",
		"le rival, devenu Maître de la Ligue (Champion de la Ligue), au combat FINAL du jeu au Plateau "
		"Indigo", REF_LIGUE,
		"la salle du Maître de la Ligue, sommet du Plateau Indigo, la plus solennelle du jeu : sol de "
		"grandes dalles de MARBRE blanc et crème veiné d'or, poli comme un miroir, un LONG TAPIS ROUGE "
		"bordé d'or qui mène au fond à une grande porte double ornée (vers le Panthéon) au sommet d'un "
		"large escalier de marbre de cinq marches ; murs de hauts PANNEAUX BORDEAUX encadrés de moulures "
		"dorées, APPLIQUES DORÉES aux flammes chaudes, quatre grandes STATUES de pierre blanche de "
		"Pokémon légendaires stylisés (silhouettes nobles, ailes, sans visage précis) sur de hauts "
		"piliers de marbre, de part et d'autre de l'escalier ; un grand vitrail circulaire doré au-dessus "
		"de la porte, sans aucun signe. Lumière DORÉE majestueuse qui tombe du vitrail et de hautes "
		"fenêtres en haut à gauche, rayons de poussière dorée, reflets sur le marbre ; ambiance de grande "
		"finale."),
	"sylphe": ("SYLPHE SARL, ÉTAGES DE BUREAUX (version 2)",
		"le rival (7e étage) ou Giovanni, chef de la Team Rocket (bureau du président, 11e étage), dans "
		"Sylphe SARL occupée par la Team Rocket", REF_ANCIEN,
		"un grand plateau de bureaux de Sylphe SARL, siège moderne d'une société de Safrania, occupé par "
		"la Team Rocket : grandes baies vitrées sur la ville de Safrania (gratte-ciel au loin, ciel clair "
		"de fin de journée), postes de travail blancs et bleus avec écrans, fauteuils de bureau, plantes "
		"en pots, cloisons vitrées, un TÉLÉPORTEUR rond de métal argenté à disque bleu lumineux contre "
		"une cloison du fond, quelques cartons et papiers renversés, une chaise tombée (désordre de "
		"l'occupation), au fond une porte coulissante métallique. Le SOL est une moquette gris-bleu en "
		"dalles, avec un chemin plus clair. Lumière de bureau blanche et chaude des baies, plafonniers ; "
		"ambiance tendue."),
	"repaire": ("REPAIRE DE LA TEAM ROCKET (version 2)",
		"Giovanni, chef de la Team Rocket, au fond du repaire secret sous le Casino de Céladopole",
		REF_ANCIEN,
		"le dernier sous-sol du repaire secret de la Team Rocket, sous le Casino : grande salle "
		"souterraine de béton et de métal, murs de plaques d'acier gris-bleu rivetées, poutres et tuyaux "
		"au plafond, néons blancs froids et une lampe rouge d'alarme, caisses de bois et caisses "
		"métalliques empilées, un poste de commande avec écrans verts, une porte blindée à bandes jaunes "
		"et noires au fond, quelques DALLES À FLÈCHES métalliques au sol sur le côté (le puzzle du "
		"repaire), une grande tache de peinture rouge abstraite au mur (AUCUNE lettre). Le SOL est du "
		"béton gris poli, taché, avec des marquages jaunes et noirs. Lumière froide et dure des néons, "
		"reflets sur le béton, coins sombres ; ambiance de repaire criminel."),
	"tour": ("TOUR POKÉMON DE LAVANVILLE (version 2)",
		"le rival, venu se recueillir, au 2e étage de la Tour Pokémon", REF_ANCIEN,
		"un étage de la Tour Pokémon de Lavanville, cimetière des Pokémon : murs de grands blocs de "
		"pierre gris-violet, petites niches à bougies, nombreuses petites TOMBES de pierre arrondies "
		"alignées en rangées, ornées de fleurs blanches et d'offrandes, quelques lanternes de pierre, un "
		"escalier de pierre qui monte au fond à droite, fines volutes d'encens. Le SOL est un dallage de "
		"grandes pierres gris-lilas usées, une BRUME pâle basse au ras du sol sur les côtés. Lumière "
		"froide et feutrée, mauve et bleutée, quelques flammes chaudes de bougies ; ambiance recueillie "
		"et un peu inquiétante."),
	"labo": ("LABORATOIRE DU PROFESSEUR CHEN",
		"le rival, au tout premier combat du jeu, juste après le choix des Pokémon de départ",
		"Images jointes : IMAGE 1 = un décor de combat VALIDÉ d'un autre lieu (l'Arène d'Argenta) : "
		"CIBLE du rendu, de la richesse, de la vue de trois-quarts et du cadrage ; ce n'est PAS le lieu à "
		"peindre. IMAGE 2 = la référence VALIDÉE du laboratoire vue de dessus (lieu, mobilier, matériaux, "
		"couleurs et lumière à GARDER) : à repeindre comme si l'on se tenait DANS la pièce, à hauteur "
		"d'homme, en vue de trois-quarts.",
		"le laboratoire du Professeur Chen à Bourg Palette, chaleureux et encombré : murs crème, grande "
		"fenêtre à petits carreaux sur des arbres ensoleillés au fond, bureau de bois avec ordinateur, "
		"étagères pleines de livres et de classeurs colorés, plantes vertes en pots, la grande machine "
		"cylindrique de métal à écran bleu lumineux à gauche, vitrines et terrariums, une grande carte "
		"de la région punaisée au mur (dessin de contours seulement, AUCUN mot), et sur la droite la "
		"longue table blanche du présentoir des trois Pokémon de départ, avec ses trois socles et des "
		"Poké Balls ROUGES ET BLANCHES posées dessus (pas de Pokémon). Le SOL est un carrelage crème "
		"clair, avec un grand tapis gris-bleu orné d'un cercle de Poké Ball rouge et blanc. Lumière "
		"CHAUDE et dorée de fin d'après-midi qui entre par la fenêtre en haut à gauche, rayons doux, "
		"lampes suspendues allumées ; ambiance de départ d'une aventure."),
	"ss_anne": ("S.S. ANNE, COULOIR DU CAPITAINE (version 2)",
		"le rival, dans le couloir qui mène à la cabine du capitaine du paquebot S.S. Anne", REF_ANCIEN,
		"un large couloir luxueux du paquebot de croisière S.S. Anne, près de la cabine du capitaine : "
		"boiseries d'acajou vernis, panneaux crème, HUBLOTS ronds à cerclage de laiton qui montrent la "
		"mer bleue et le ciel, appliques de laiton aux globes chauds, une bouée de sauvetage rouge et "
		"blanche accrochée au mur (sans texte), une maquette de voilier sous vitrine, une porte "
		"d'acajou à hublot au fond (la cabine du capitaine), des rampes de laiton. Le SOL est un parquet "
		"de bois clair verni, avec un LONG TAPIS rouge bordé d'or. Lumière chaude dorée des appliques et "
		"lumière de mer bleutée des hublots ; ambiance de croisière élégante."),
}

GABARIT = """DÉCOR DE COMBAT — {titre} (Kanto 2026). Image de PRODUCTION : le fond peint d'un écran de combat sur smartphone en paysage, où le joueur affronte {adv}. AUCUN personnage, AUCUN Pokémon, AUCUNE interface, AUCUN texte.

{jointes}

LIEU : {lieu}
"""

if __name__ == "__main__":
	for ident, (titre, adv, jointes, lieu) in DECORS.items():
		(D / f"decor_{ident}.txt").write_text(GABARIT.format(titre=titre, adv=adv, jointes=jointes,
			lieu=lieu) + COMMUN, encoding="utf-8")
		print(f"decor_{ident}.txt")
