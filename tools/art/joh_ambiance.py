#!/usr/bin/env python3
"""Ambiance d'Oliville à Rosalia (cartes du JOH1 et du JOH2, décision de Kevin du 2026-11-04 :
« prendre de l'avance sur l'art et l'ambiance de Johto »). Façades propres à Johto que le kit peint
de Kanto n'a pas, peintes par Codex :
  - BLDG_PHARE_OLIVILLE (emprise 6 × 11, `tools/plans/oliville.txt` « P ») ;
  - BLDG_TOUR_CENDREE (10 × 11, `rosalia.txt` « B »), BLDG_TOUR_CARILLON (8 × 9, « K ») ;
  - BLDG_MAISON_ROSALIA (7 × 6, maisons et Maison des Sages de Rosalia : toits de tuiles) ;
  - RELIEF_BOUCHE_GROTTE_MARINE (bouche de la grotte marine dans les rochers de Bourg Palette).
Gabarit = un bâtiment VALIDÉ du kit (échelle, rendu, angle, lumière neutre, porte) ; contenu = la
vue générale peinte validée (recadrage `build/art/REF_*`). Prompts : `prompts/joh_ambiance/`.
Usage : tools/art/joh_ambiance.py [--tour N] [IDENTIFIANT ...]
        tools/art/joh_ambiance.py --preparer   (images retenues → assets/, catalogue ; puis
        `godot --headless --path . --import` et `tools/build_painted_props.gd -- --nouveaux`)
"""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from serie06 import ADN, LUMIERE_NE  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
BAT = RACINE / "assets/world/buildings"
ART = RACINE / "build/art"
PROMPTS = Path(__file__).parent / "prompts" / "joh_ambiance"

FIN = ("Fond : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun halo. "
	"Aucune ombre portée au sol, aucun sol autour : le bâtiment seul, entier, centré.\n"
	"Interdits : texte, lettres, chiffres, enseigne écrite, logo, personnage, Pokémon, arbres ou "
	"herbe autour, pixel art, 3D, contours noirs épais.")


def batiment(gabarit: str, contenu: str, largeur: int, profondeur: int, description: str) -> str:
	return f"""IMAGE 1 : {gabarit}, un bâtiment VALIDÉ du jeu. C'est le GABARIT DE STYLE : même rendu peint, même angle de vue (vue de dessus de trois quarts, façade sud visible, aucun point de fuite), même lumière neutre, même finesse, même échelle (une case = 96 px en jeu ; une porte = 1 case de large).
IMAGE 2 : {contenu}, extrait de la vue générale VALIDÉE de la ville. C'est le CONTENU : forme, couleurs, matériaux et esprit du bâtiment ; son rendu un peu pixelisé ne doit PAS être copié, ni son cadrage.

À FAIRE : {description}
Géométrie : l'emprise au sol fait {largeur} cases de large × {profondeur} cases de profondeur (la base du bâtiment occupe toute la largeur de l'image) ; la façade sud est en bas ; ce qui monte (étages, toit, lanterne) dépasse vers le haut de l'image.
Format : PNG portrait ou carré, haute définition, le bâtiment occupe presque toute la largeur.
{FIN}"""


ASSETS = {
	"BLDG_PHARE_OLIVILLE": (batiment("bldg_tour_pokemon_01", "REF_OLIVILLE_PHARE", 6, 11,
		"le PHARE d'Oliville : une haute tour ronde de phare, blanche à larges bandes rouges horizontales, "
		"posée sur un socle de pierre grise ; en haut, une galerie à garde-corps blanc et la lanterne vitrée "
		"(vitres claires, la lumière ÉTEINTE de jour) sous un toit conique rouge ; au pied, côté sud, une "
		"petite porte en bois fermée sous un auvent ; deux petites fenêtres étroites le long de la tour. "
		"Le phare est un peu plus étroit que son socle ; le socle couvre l'emprise."),
		[BAT / "bldg_tour_pokemon_01.png", ART / "REF_OLIVILLE_PHARE.png"]),
	"BLDG_TOUR_CENDREE": (batiment("bldg_tour_pokemon_01", "REF_ROSALIA_TOUR_CENDREE", 10, 11,
		"la TOUR CENDRÉE de Rosalia : une ancienne tour de temple japonais en bois, à deux étages "
		"carrés, INCENDIÉE il y a longtemps : bois noirci et charbonneux, toit de tuiles gris foncé effondré "
		"en partie (trou béant, poutres calcinées qui dépassent), quelques tuiles tombées, traces de suie ; "
		"au rez-de-chaussée, une grande double porte en bois sombre, fermée, au milieu de la façade sud, "
		"sur deux marches de pierre. Atmosphère de ruine silencieuse mais pas effrayante."),
		[BAT / "bldg_tour_pokemon_01.png", ART / "REF_ROSALIA_TOUR_CENDREE.png"]),
	"BLDG_TOUR_CARILLON": (batiment("bldg_tour_pokemon_01", "REF_ROSALIA_TOUR_CARILLON", 8, 9,
		"la TOUR CARILLON de Rosalia : une pagode japonaise élancée à cinq toits superposés de tuiles "
		"rouge brique aux bords relevés, murs crème à colombages de bois sombre, balcons de bois, une "
		"flèche dorée au sommet ; au pied, sur un socle de pierre, une porte en bois au milieu de la façade "
		"sud. Élégante, sereine, bien entretenue."),
		[BAT / "bldg_tour_pokemon_01.png", ART / "REF_ROSALIA_TOUR_CARILLON.png"]),
	"BLDG_MAISON_ROSALIA": (batiment("bldg_maison_a_01", "REF_ROSALIA_MAISON_SAGES", 7, 6,
		"une MAISON TRADITIONNELLE de Rosalia : maison japonaise basse d'un étage, murs crème à "
		"colombages de bois brun, grand toit de tuiles rouge brique aux bords légèrement relevés, "
		"une porte coulissante en bois au milieu de la façade sud (même place et même taille que la "
		"porte de l'IMAGE 1), deux fenêtres à croisillons, une petite jardinière. Même largeur, même "
		"hauteur de façade et même position de porte que l'IMAGE 1."),
		[BAT / "bldg_maison_a_01.png", ART / "REF_ROSALIA_MAISON_SAGES.png"]),
}


def generer(ident: str, tour: int) -> str:
	texte, jointes = ASSETS[ident]
	nom = f"{ident}_r{tour}"
	fichier = PROMPTS / f"{nom}.txt"
	fichier.write_text(f"{nom} — asset de jeu de Kanto 2026 (Chapitre Johto).\n\n{ADN}\n{LUMIERE_NE}\n\n{texte}\n")
	resultat = subprocess.run([str(RACINE / "tools/art/generer.sh"), nom, str(fichier),
		*[str(j) for j in jointes]], cwd=RACINE, capture_output=True, text=True)
	return f"{nom} : {'ok' if resultat.returncode == 0 else 'ÉCHEC ' + resultat.stderr.strip()[-200:]}"


# Façades retenues → `assets/world/buildings/` (silhouette recadrée, largeur = emprise, origine aux
# pieds, ombres portée et de contact, entrée du catalogue) : [identifiant du jeu, image retenue].
# L'entrée du manifeste (`manifeste.json`, mêmes réglages) permet aussi un `preparer.py` complet.
RETENUS = {
	"bldg_phare_oliville_01": "BLDG_PHARE_OLIVILLE_r1.png",
}


def preparer_retenus() -> None:
	"""Prépare les images retenues de [RETENUS] seulement (catalogue existant conservé)."""
	import json
	import preparer
	from PIL import Image
	manifeste = json.loads((Path(__file__).parent / "manifeste.json").read_text())
	entrees = {e["id"]: e for e in manifeste["objets"]}
	catalogue_path = RACINE / "assets" / "world" / "catalogue.json"
	p = preparer.Preparateur(manifeste, ART)
	p.catalogue = json.loads(catalogue_path.read_text())
	for ident, source in RETENUS.items():
		e = entrees[ident]
		image = preparer._recadrer(Image.open(ART / source).convert("RGBA"), e)
		image = preparer._mettre_a_taille(preparer._silhouette(image), e["axe"], e["cases"],
			p.case)
		p._objet(ident, e["sortie"], image, e["ombre"], e["contact"])
	p.ecrire_catalogue()


if __name__ == "__main__":
	args = sys.argv[1:]
	if args[:1] == ["--preparer"]:
		preparer_retenus()
		sys.exit(0)
	tour = 1
	if args[:1] == ["--tour"]:
		tour, args = int(args[1]), args[2:]
	PROMPTS.mkdir(parents=True, exist_ok=True)
	choix = [a for a in ASSETS if not args or a in args]
	with ThreadPoolExecutor(max_workers=4) as pool:
		for ligne in pool.map(lambda i: generer(i, tour), choix):
			print(ligne, flush=True)
