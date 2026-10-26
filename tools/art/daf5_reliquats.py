#!/usr/bin/env python3
"""DAF.5, 2e partie (phase DA, `docs/design/phase-da-cadrage.md`) — séries en attente et reliquats :
intégration de la série 25 (héros à vélo et qui pêche, Motard, Ornithologue, Loubard, deux frères
pêcheurs, Kangourex et Ramoloss de l'enclos de Parmanie) et du Chenipan d'ambiance de la Forêt de Jade
(série 11, entrée `chenipan` déjà au manifeste, image jamais générée avant DAF.5).
Inventaire : `docs/design/inventaire-art.md` §5 et §7 ; fiche `fiches-assets/serie-25-deux-chemins.md`.

Sources (images brutes hors dépôt, dans $ART, défaut build/art de cette copie) : les originaux de la
série 25 sont ceux de la copie `j22-t7b` (Kangourex r2 validé, Ramoloss r3) ; les icônes de la série 25
(planches A et B) ne sont **pas** reprises : DAF.5 1re partie a déjà peint Bicyclette, Bon, cannes,
Hyper Potion et Hyper Ball. Le bouton « Vélo » du HUD est déjà là (`assets/ui/icons/bike.svg`).

Usage :
  tools/art/daf5_reliquats.py --manifeste   ajoute les entrées en fin de tools/art/manifeste.json
                                            (idempotent)
  tools/art/daf5_reliquats.py --preparer    images de $ART → assets/ (ces entrées seulement, catalogue
                                            existant conservé) ; puis build_character_frames.gd
  tools/art/daf5_reliquats.py --planche     planche docs/design/fiches-assets/daf-5-reliquats/planche.png
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import preparer  # noqa: E402

RACINE = ICI.parents[1]
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
MANIFESTE = ICI / "manifeste.json"
_C = "assets/sprites/characters/painted/"
_P = "assets/sprites/pokemon/painted/"


def _perso(ident: str, source: str, hauteur: int, note: str) -> dict:
	# Halo alpha des planches de marche de Codex (comme la série 27) : coupé avant la découpe.
	return {"id": ident, "source": source, "sortie": f"{_C}{ident}_sheet.png", "hauteur": hauteur,
		"nettoyer": True, "note": note}


def _attente(ident: str, source: str, marche: str) -> dict:
	return {"id": ident, "source": source, "sortie": f"{_C}{ident}_sheet.png", "marche": marche,
		"note": "série 25 (DAF.5)"}


ENTREES = {
	"personnages": [
		_perso("motard", "PNJ_MOTARD_NE_r1.png", 128, "série 25 (DAF.5) ; Motards des Routes 16 à 18 ; biker"),
		_perso("ornithologue", "PNJ_ORNITHOLOGUE_NE_r1.png", 128, "série 25 (DAF.5) ; bird_keeper"),
		_perso("loubard", "PNJ_LOUBARD_NE_r1.png", 128, "série 25 (DAF.5) ; cue_ball"),
		_perso("pecheur_parmanie", "PNJ_PECHEUR_PARMANIE_NE_r1.png", 130,
			"série 25 (DAF.5) ; frère cadet, Super Canne ; fisher_fuchsia"),
		_perso("pecheur_route_12", "PNJ_PECHEUR_ROUTE12_NE_r1.png", 130,
			"série 25 (DAF.5) ; frère aîné, Méga Canne ; fisher_route_12"),
		_perso("heros_bike", "HEROS_VELO_NE_r1.png", 128,
			"série 25 (DAF.5) ; hauteur = héros à pied, le vélo dépasse en largeur ; animations bike_* de player"),
	],
	"attentes": [
		_attente("motard_idle", "MOTARD_ATTENTE_r1.png", "motard"),
		_attente("ornithologue_idle", "ORNITHOLOGUE_ATTENTE_r1.png", "ornithologue"),
		_attente("loubard_idle", "LOUBARD_ATTENTE_r1.png", "loubard"),
		_attente("pecheur_parmanie_idle", "PECHEUR_PARMANIE_ATTENTE_r1.png", "pecheur_parmanie"),
		_attente("pecheur_route_12_idle", "PECHEUR_ROUTE12_ATTENTE_r1.png", "pecheur_route_12"),
		# Arrêt en selle peint ≈ 6 % plus grand que le pédalage (profil 86 px contre 81) : ramené.
		dict(_attente("heros_bike_idle", "HEROS_VELO_ARRET_r1.png", "heros_bike"), rapport_hauteur=0.94),
	],
	"pokemon_fixes": [
		{"id": "kangourex", "source": "POKE_KANGOUREX_FIXE_NE_r2.png", "sortie": f"{_P}kangourex_sheet.png",
			"hauteur": 150, "note": "série 25 (DAF.5) ; r2 (tête brune sans casque, planche v2)"},
		{"id": "ramoloss", "source": "POKE_RAMOLOSS_FIXE_NE_r3.png", "sortie": f"{_P}ramoloss_sheet.png",
			"hauteur": 64, "note": "série 25 (DAF.5) ; r3, obtenu sans pièce jointe"},
	],
}
## Pêche (pas au manifeste : `decouper_attente` met à l'échelle sur la hauteur totale, canne levée
## comprise, et la borne à la cellule de la marche : héros trop petit). Découpe propre : [method pecher].
PECHE = [
	("heros_fish_cast", "HEROS_PECHE_LANCER_r1.png"),
	("heros_fish_wait", "HEROS_PECHE_ATTENTE_r1.png"),
]
## Déjà au manifeste (série 11), préparé ici une fois l'image générée.
CHENIPAN = "chenipan"


def manifeste() -> None:
	m = json.loads(MANIFESTE.read_text())
	for section, entrees in ENTREES.items():
		connus = {e["id"] for e in m[section]}
		m[section] += [e for e in entrees if e["id"] not in connus]
	MANIFESTE.write_text(json.dumps(m, ensure_ascii=False, indent=1) + "\n")


def preparer_images() -> None:
	m = json.loads(MANIFESTE.read_text())
	sous = dict(m)
	ids = {e["id"] for entrees in ENTREES.values() for e in entrees} | {CHENIPAN}
	for section in ("personnages", "attentes", "pokemon_fixes"):
		sous[section] = [e for e in m[section] if e["id"] in ids - {CHENIPAN}]
	sous["pokemon"] = []
	sous["pokemon_boucles"] = []
	p = preparer.Preparateur(sous, ART)
	p.catalogue = json.loads((RACINE / "assets/world/catalogue.json").read_text())
	p.personnages()
	p.attentes()
	p.pokemon_fixes()
	# Chenipan : halo alpha coupé d'abord (`pokemon_fixes` n'a pas l'option `nettoyer`).
	chenipan = next(e for e in m["pokemon_fixes"] if e["id"] == CHENIPAN)
	if (ART / chenipan["source"]).exists():
		net = ART / "net"
		net.mkdir(exist_ok=True)
		preparer.nettoyer_halos(Image.open(ART / chenipan["source"]).convert("RGBA")).save(net / chenipan["source"])
		p.source = net
		p.m = dict(sous, pokemon_fixes=[chenipan])
		p.pokemon_fixes()
		p.source = ART
	for ident, source in PECHE:
		largeur, hauteur = pecher(ART / source, RACINE / f"{_C}heros_sheet.png", RACINE / f"{_C}{ident}_sheet.png")
		p.catalogue["personnages"][ident] = {
			"fichier": f"res://{_C}{ident}_sheet.png", "cellule": [largeur, hauteur],
			"hauteur": p.catalogue["personnages"]["heros"]["hauteur"], "colonnes": 4, "lignes": 1,
			"ordre_colonnes": ["bas", "gauche", "droite", "haut"]}
	p.ecrire_catalogue()


def _hauteur_corps(pose: Image.Image, epaisseur: int = 24) -> tuple[int, int]:
	"""Haut et bas du corps : rangées d'au moins `epaisseur` pixels opaques (canne et fil, fins,
	ignorés ; même mesure que la planche de contact de `serie25.py`)."""
	alpha = np.asarray(pose.getchannel("A")) > 40
	rangs = np.nonzero(alpha.sum(axis=1) >= epaisseur)[0]
	return int(rangs[0]), int(rangs[-1]) + 1


def pecher(source: Path, chemin_marche: Path, sortie: Path) -> tuple[int, int]:
	"""Planche de pêche 4 × 1 (bas, gauche, droite, haut) à l'échelle du héros à pied : le **corps**
	des poses de face et de dos prend la hauteur des mêmes poses de la marche. La canne dépasse :
	cellule plus haute que la marche, pieds à la même distance sous le centre (le sprite du joueur est
	centré : `offset` = demi-hauteur de `idle_down`), tête au centre en largeur."""
	import decouper_attente as da
	from decouper_perso import _centre_tete
	marche = Image.open(chemin_marche).convert("RGBA")
	cellule_l, cellule_h = marche.width // 4, marche.height // 4
	poses = da._poses_bande(Image.open(source).convert("RGBA"))
	rapports = []
	for colonne, ligne in ((0, 0), (3, 3)):
		haut, bas = _hauteur_corps(poses[colonne])
		rapports.append(da._hauteur_marche(marche, cellule_l, cellule_h, ligne) / (bas - haut))
	echelle = sum(rapports) / len(rapports)
	reduites = []
	demi_l, au_dessus = cellule_l / 2, cellule_h / 2
	for pose in poses:
		_haut, bas = _hauteur_corps(pose)
		reduite = pose.resize((max(1, round(pose.width * echelle)), max(1, round(pose.height * echelle))),
			Image.LANCZOS)
		pieds = bas * echelle  # bas du corps (le fil peut descendre plus bas, devant les pieds)
		tete = _centre_tete(pose) * echelle
		demi_l = max(demi_l, tete + 1, reduite.width - tete + 1)
		reduites.append((reduite, tete, pieds))
	# Pieds à cellule_h / 2 sous le centre (comme la marche) ; place au-dessus pour la canne, et
	# autant en dessous (centrage), au moins le fil qui pend sous les pieds.
	haut_max = max(pieds for _r, _t, pieds in reduites)
	bas_max = max(r.height - pieds for r, _t, pieds in reduites)
	moitie = max(cellule_h / 2, haut_max - cellule_h / 2, cellule_h / 2 + bas_max)
	hauteur = 2 * int(moitie + 0.999)
	largeur = 2 * int(demi_l + 0.999)
	sol = hauteur // 2 + cellule_h // 2
	planche = Image.new("RGBA", (largeur * 4, hauteur), (0, 0, 0, 0))
	for colonne, (reduite, tete, pieds) in enumerate(reduites):
		planche.alpha_composite(reduite, (colonne * largeur + round(largeur / 2 - tete), round(sol - pieds)))
	planche.save(sortie, optimize=True)
	print(f"{sortie} : cellule {largeur} × {hauteur}, échelle {echelle:.4f}")
	return largeur, hauteur


# --- Planche de validation -----------------------------------------------------------------------

CAPTURES = RACINE / "build/captures/daf5_reliquats"


def _police(taille: int) -> ImageFont.FreeTypeFont:
	for chemin in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(chemin).exists():
			return ImageFont.truetype(chemin, taille)
	return ImageFont.load_default()


def _cellules(relatif: str, colonnes: int, lignes: int, ligne: int = 0) -> list[Image.Image]:
	image = Image.open(RACINE / relatif).convert("RGBA")
	l, h = image.width // colonnes, image.height // lignes
	return [image.crop((c * l, ligne * h, (c + 1) * l, (ligne + 1) * h)) for c in range(colonnes)]


def _rangee(cellules: list[Image.Image], fond=(118, 150, 96, 255), haut: int = 270, zoom: float = 2,
		bas: bool = False) -> Image.Image:
	"""Cellules à l'échelle du jeu × zoom, côte à côte, centrées comme le sprite du jeu : pieds de la
	marche à 65 px sous le centre, sur la ligne rouge ; [param bas] : bas de cellule sur la ligne
	(Pokémon fixes)."""
	visibles = [c.crop(c.getbbox() or (0, 0, 1, 1)) for c in cellules]
	largeur = 20 + sum(round(v.width * zoom) + 24 for v in visibles)
	bande = Image.new("RGBA", (largeur, haut), fond)
	d = ImageDraw.Draw(bande)
	sol = haut - 20
	x = 10
	for c, v in zip(cellules, visibles):
		g = c.resize((round(c.width * zoom), round(c.height * zoom)), Image.LANCZOS)
		gauche = round((c.getbbox() or (0, 0, 1, 1))[0] * zoom)
		haut_g = sol - g.height if bas else round(sol - 65 * zoom) - g.height // 2
		bande.alpha_composite(g, (x - gauche, haut_g))
		x += round(v.width * zoom) + 24
	d.line((0, sol, bande.width, sol), fill=(200, 60, 60, 255), width=2)
	return bande


def planche() -> Path:
	texte = _police(20)
	largeur = 2400
	blocs: list[tuple[str, Image.Image]] = []
	heros = _cellules(f"{_C}heros_sheet.png", 4, 4)[0]
	blocs.append(("Héros à pied (repère, 128 px) — à vélo : pédalage bas, gauche, droite, haut — arrêt en selle",
		_rangee([heros] + [_cellules(f"{_C}heros_bike_sheet.png", 4, 4, r)[1] for r in range(4)]
			+ _cellules(f"{_C}heros_bike_idle_sheet.png", 4, 1))))
	blocs.append(("Pêche : lancer (bas, gauche, droite, haut) puis attente fil tendu — corps à l'échelle de la marche, "
		"cellule plus haute pour la canne", _rangee([heros] + _cellules(f"{_C}heros_fish_cast_sheet.png", 4, 1)
			+ _cellules(f"{_C}heros_fish_wait_sheet.png", 4, 1), haut=560)))
	pnj = []
	for ident in ("motard", "ornithologue", "loubard", "pecheur_parmanie", "pecheur_route_12"):
		pnj += [_cellules(f"{_C}{ident}_sheet.png", 4, 4)[0], _cellules(f"{_C}{ident}_idle_sheet.png", 4, 1)[1]]
	blocs.append(("Motard, Ornithologue, Loubard, frère cadet (Parmanie, Super Canne), frère aîné (Route 12, "
		"Méga Canne) : marche de face + attente de profil", _rangee([heros] + pnj)))
	fixes = []
	for ident, colonnes in (("kangourex", 6), ("ramoloss", 6), ("chenipan", 6)):
		c = _cellules(f"{_P}{ident}_sheet.png", colonnes, 1)
		fixes += [c[0], c[1], c[2], c[3]]
	blocs.append(("Pokémon fixes : Kangourex 150 px, Ramoloss 64 px (enclos de Parmanie), Chenipan 44 px "
		"(Forêt de Jade, généré par Codex au DAF.5) — repos / réaction, face puis profil",
		_rangee([_cellules(f"{_C}heros_sheet.png", 4, 4)[0]] + fixes, haut=360, zoom=1.6, bas=True)))

	def captures(noms: list[str], par_ligne: int = 3) -> Image.Image:
		l = (largeur - 40 - 20 * (par_ligne - 1)) // par_ligne
		h = l * 1080 // 2340
		lignes = (len(noms) + par_ligne - 1) // par_ligne
		bande = Image.new("RGBA", (largeur - 40, lignes * (h + 34)), (34, 40, 52, 255))
		d = ImageDraw.Draw(bande)
		for i, nom in enumerate(noms):
			x, y = (i % par_ligne) * (l + 20), (i // par_ligne) * (h + 34)
			bande.paste(Image.open(CAPTURES / f"{nom}.png").convert("RGBA").resize((l, h), Image.LANCZOS), (x, y))
			d.text((x, y + h + 4), nom, font=texte, fill=(230, 230, 230))
		return bande

	ecrans: list[tuple[str, Image.Image]] = []
	ecrans.append(("En jeu, 2340 × 1080 (Movie Maker, `tools/capture_daf5_reliquats.sh`) ; Routes 13 à 17 encore "
		"en tuiles provisoires (hors lot)", captures(["velo_profil", "velo_dos", "peche_attente", "peche_lancer",
			"enclos", "chenipan", "frere_cadet", "frere_aine", "ornithologue_motard"])))
	ecrans.append(("Pont extérieur du S.S. Anne (`ss_anne_outer_deck`) : sol peint par sa coque, rien à refaire",
		captures(["ss_anne_pont"], 2)))
	etages = [Image.open(RACINE / f"assets/world/interiors/int_celadon_dept_{e}_coque.png").convert("RGBA")
		for e in ("2f", "3f", "4f")]
	l = (largeur - 80) // 3
	bande = Image.new("RGBA", (largeur - 40, l * etages[0].height // etages[0].width + 34), (34, 40, 52, 255))
	d = ImageDraw.Draw(bande)
	for i, (e, im) in enumerate(zip(("2F", "3F", "4F"), etages)):
		bande.paste(im.resize((l, l * im.height // im.width), Image.LANCZOS), (i * (l + 20), 0))
		d.text((i * (l + 20), bande.height - 28), f"celadon_dept_{e.lower()}", font=texte, fill=(230, 230, 230))
	blocs.append(("DA-9, grille du J33 : BAT-6 (coques partagées 22 bis) non atteint — 2F et 4F = même coque "
		"recolorée, jamais côte à côte (le 3F les sépare) → pas refait ; porte arrière du Musée (série 28) "
		"jamais intégrée, rien en jeu → pas refaite", bande))

	sortie = RACINE / "docs/design/fiches-assets/daf-5-reliquats/planche.png"
	sortie.parent.mkdir(parents=True, exist_ok=True)
	_page("DAF.5, 2e partie — série 25, Chenipan, DA-9 (à valider par Kevin) ; captures : captures-2340.jpg",
		blocs).convert("RGB").save(sortie, optimize=True)
	_page("DAF.5, 2e partie — captures en jeu", ecrans).convert("RGB").save(
		sortie.with_name("captures-2340.jpg"), quality=85)
	return sortie


def _page(titre: str, blocs: list[tuple[str, Image.Image]], largeur: int = 2400) -> Image.Image:
	police, texte = _police(34), _police(20)
	page = Image.new("RGBA", (largeur, 80 + sum(b.height + 60 for _t, b in blocs)), (34, 40, 52, 255))
	d = ImageDraw.Draw(page)
	d.text((20, 20), titre, font=police, fill=(240, 240, 240))
	y = 80
	for legende, bloc in blocs:
		d.text((20, y), legende, font=texte, fill=(250, 210, 120))
		page.alpha_composite(bloc, (20, y + 30))
		y += bloc.height + 60
	return page

if __name__ == "__main__":
	arguments = sys.argv[1:]
	if "--manifeste" in arguments:
		manifeste()
	elif "--preparer" in arguments:
		preparer_images()
	elif "--planche" in arguments:
		print(planche())
