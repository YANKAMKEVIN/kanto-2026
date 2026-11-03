#!/usr/bin/env python3
"""Écrit les prompts des décors repeints à l'étape 4 (classes ordinaires, demande de Kevin du
2026-11-03 : « Mer, Route 17, Manoir ») : decor_mer.txt, decor_route_17.txt, decor_manoir.txt, à côté
de ce fichier. Gabarit des extérieurs : decor_route_22.txt (IMAGE 1 = Argenta v3, cible du rendu et
du cadrage ; IMAGE 2 = vue générale VALIDÉE du lieu, docs/design/reference/).

  python3 tools/art/entree_dresseurs/grands/ecrire_decors_ordinaires.py
"""
from pathlib import Path

D = Path(__file__).resolve().parent
PIED = (D / "decor_route_22.txt").read_text(encoding="utf-8")
PIED = PIED[PIED.index("FORMAT :"):]

REF = ("Images jointes : IMAGE 1 = un décor de combat VALIDÉ d'un autre lieu (l'Arène d'Argenta) : CIBLE "
	"du niveau de rendu, de la richesse, de la profondeur et du cadrage (sol vaste dans la moitié basse) ; "
	"ce n'est PAS le lieu à peindre. IMAGE 2 = la vue générale VALIDÉE du lieu, vue de dessus : le LIEU, "
	"les matériaux, les couleurs et la lumière à GARDER ; à repeindre comme si l'on s'y tenait, à hauteur "
	"d'homme, en vue de trois-quarts (et PAS en pixel art).")


def cadrage(gauche: str, droite: str, ligne: str, sol: str, a: str, b: str) -> str:
	return (f"PERSPECTIVE (impératif, la vue NE DOIT PAS être symétrique) : caméra à hauteur d'homme sur la "
		f"GAUCHE, regard légèrement vers la DROITE, en trois-quarts : point de fuite vers x 62 %. {gauche} ; "
		f"{droite}.\n\nCADRAGE (impératif) : {ligne} est entre 38 et 42 % de la hauteur de l'image : tout ce "
		f"qui est sous 42 % est le SOL ({sol}, vaste, la moitié basse et plus).\n"
		f"- Point A (x 67 %, y 50 %) : {a} (l'adversaire y posera les pieds), rien de haut dans un rayon de "
		f"10 % de la largeur autour.\n- Point B (x 31 %, y 97 %) : {b} au premier plan (le joueur s'y "
		f"tient).\n- Les 9 % de gauche et de droite ne contiennent rien d'important.\n\n")


DECORS = {
	"mer": ("MER DES ROUTES 19 À 21 (version 2)",
		"un Nageur ou une Nageuse en pleine mer au sud de Parmanie (Routes 19, 20 et 21 ; aussi la mer "
		"autour de Cramois'Île)",
		"la mer chaude du sud de Kanto, eau TURQUOISE claire et transparente sur des HAUTS-FONDS, qui fonce "
		"en bleu profond au loin. Le sol est un grand BANC DE SABLE émergé, plat et mouillé, sable clair "
		"doré, avec de fines nappes d'eau de quelques centimètres, de petites rides de sable, des "
		"coquillages, quelques galets et touffes d'algues ; de petites vagues mousseuses viennent lécher "
		"ses bords. Au premier plan à gauche, de gros ROCHERS ronds gris-beige d'une DIGUE D'ENROCHEMENT "
		"(comme sur IMAGE 2), coupés par le bord, éclaboussés d'écume. Au loin à droite, la longue digue "
		"d'enrochement qui ferme un bassin, une petite plage avec deux parasols rayés minuscules et la côte "
		"boisée très loin ; un îlot rocheux. Ciel d'été bleu à gros nuages blancs, soleil haut à gauche, "
		"mille reflets scintillants sur l'eau ; ambiance de vacances au bord de la mer.",
		cadrage("rochers de la digue de GAUCHE proches, grands, coupés par le bord gauche",
			"la côte et la digue du fond plus petites et lointaines à droite",
			"la LIGNE où le banc de sable rejoint l'eau du fond", "le banc de sable mouillé",
			"sable plat, mouillé et nu, bien émergé", "sable plat, mouillé et nu")),
	"route_17": ("ROUTE 17, ROUTE CYCLABLE",
		"un Motard ou un Loubard sur la Route cyclable, la longue route qui descend de Céladopole à "
		"Parmanie le long de la mer",
		"la ROUTE CYCLABLE : une large route de BÉTON gris clair à grandes dalles, SURÉLEVÉE sur des "
		"PILOTIS de béton au-dessus des enrochements, au bord de la mer. Sur la gauche (proche) : la mer "
		"bleu profond avec écume, une rangée de gros ROCHERS ronds gris-beige en enrochement contre le pied "
		"des pilotis, une glissière basse de béton et de métal le long du bord. Au milieu de la chaussée, un "
		"séparateur bas de béton avec de petites BORNES de bois orange (comme IMAGE 2), marquages blancs "
		"effacés au sol, quelques traces de pneus et de dérapages, une petite plate-bande d'herbe et un banc "
		"de bois. Sur la droite et au fond : la route qui file en pente douce vers le sud jusqu'à "
		"l'horizon, bordée d'une FORÊT DENSE de feuillus vert vif. Ciel de fin d'après-midi lumineux, "
		"lumière chaude venant de la gauche, embruns dans l'air ; ambiance de vitesse et de bande de motards.",
		cadrage("mer, enrochements et glissière de GAUCHE proches, grands, coupés par le bord gauche",
			"la forêt et la route qui file au loin plus petites à droite",
			"la LIGNE où la chaussée plate rejoint le pied de la forêt du fond et l'horizon",
			"la chaussée de béton", "béton plat et nu, sur la chaussée", "béton plat et nu")),
	# Finitions (Kevin, 2026-11-03 : « peindre leur propre fond ») : un fond commun aux Routes 16
	# ouest et 18 (Piste cyclable en forêt, sans mer). IMAGE 2 = vue générale de la 16 ouest, IMAGE 3 =
	# celle de la 18.
	"route_cyclable_foret": ("PISTE CYCLABLE EN FORÊT (ROUTES 16 OUEST ET 18)",
		"un Loubard, un Motard ou un Ornithologue sur la Piste cyclable, aux deux bouts de la Route "
		"cyclable (Route 16 ouest au pied de Céladopole, Route 18 à l'entrée de Parmanie)",
		"(IMAGE 2 = vue générale VALIDÉE de la Route 16 ouest, IMAGE 3 = celle de la Route 18 : même "
		"usage, le même lieu des deux côtés de la Route cyclable) la PISTE CYCLABLE en pleine FORÊT, loin "
		"de la mer (AUCUNE mer, AUCUNE plage) : une large "
		"chaussée de BÉTON gris clair à grandes dalles bordée d'une bordure de pavés clairs, deux voies "
		"séparées par une BARRIÈRE BASSE de lisses de bois brun sur des poteaux de béton (comme IMAGES 2 "
		"et 3), marquages blancs effacés, quelques traces de pneus. Sur la GAUCHE (proche) : une haute "
		"FALAISE de roche beige-ocre à colonnes verticales, coiffée d'herbe et de buissons, qui longe la "
		"piste (comme le nord de la Route 16 ouest, IMAGE 2), avec de petites touffes de fleurs à son "
		"pied. Sur la DROITE et au fond : une FORÊT DENSE de grands feuillus vert vif aux troncs bruns qui "
		"enserre la piste, et, entre les arbres à droite au loin, l'éclat bleu d'un petit ÉTANG calme "
		"bordé d'herbe (comme à l'est de la Route 18, IMAGE 3). La piste file droit vers le fond entre "
		"falaise et forêt. Ciel d'après-midi bleu à nuages blancs vu au-dessus des arbres, lumière chaude "
		"venant de la gauche, ombres douces des feuillages sur le béton ; ambiance de vitesse en forêt.",
		cadrage("la falaise et la barrière de GAUCHE proches, grandes, coupées par le bord gauche et par "
			"le haut", "la forêt et l'étang plus petits et lointains à droite",
			"la LIGNE où la chaussée plate rejoint le pied de la forêt du fond",
			"la chaussée de béton", "béton plat et nu, sur la chaussée", "béton plat et nu")),
	"manoir": ("MANOIR POKÉMON DE CRAMOIS'ÎLE",
		"un Pillard ou un Scientifique dans le Manoir Pokémon abandonné de Cramois'Île",
		"une grande salle du MANOIR POKÉMON, vieux manoir abandonné et à moitié brûlé où l'on étudiait Mew : "
		"PARQUET de bois chaud usé, lames disjointes, brûlées par endroits, quelques trous ; un long TAPIS "
		"rouge sombre élimé et déchiré ; murs de lambris et papier peint décollé, fissurés, plâtre tombé "
		"laissant voir des briques et des poutres calcinées ; deux STATUES blanches de MEW (petit félin assis "
		"sur un socle), de taille MOYENNE, contre le mur du FOND (vers x 45 % et x 80 %), aucune au premier "
		"plan ; tonneaux, caisses, une étagère de "
		"livres renversée, journaux et papiers épars au sol, un bureau avec une lampe ; une grille de fer "
		"entrouverte au fond ; poussière et toiles d'araignée. Lumière dorée chaude de lampes à huile et de "
		"rayons qui tombent de hautes fenêtres aux vitres cassées en haut à gauche, coins sombres ; ambiance "
		"de lieu interdit, mystérieux mais pas funèbre (PAS de tombes, PAS de bougies funéraires).",
		cadrage("étagère renversée, poutres et lambris de GAUCHE proches, grandes, coupées par le bord gauche et par "
			"le haut", "la grille et le fond plus petits et lointains à droite", "le PIED DU MUR DU FOND",
			"le parquet", "parquet plat et nu", "parquet plat et nu")),
}

if __name__ == "__main__":
	for ident, (titre, adv, lieu, cad) in DECORS.items():
		texte = (f"DÉCOR DE COMBAT — {titre} (Kanto 2026). Image de PRODUCTION : le fond peint d'un écran "
			f"de combat sur smartphone en paysage, où le joueur affronte {adv}. AUCUN personnage, AUCUN "
			f"Pokémon, AUCUNE interface, AUCUN texte.\n\n{REF}\n\nLIEU : {lieu}\n\n{cad}{PIED}")
		(D / f"decor_{ident}.txt").write_text(texte, encoding="utf-8")
		print(f"decor_{ident}.txt")
