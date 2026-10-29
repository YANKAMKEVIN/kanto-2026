#!/usr/bin/env python3
"""Chantier JR (docs/design/dossier-joueuse-rivale.md) : planches de jeu de la joueuse et de la
rivale, depuis les images générées par `generer_jr.sh` (build/art/JR_*_r1.png).

Mêmes réglages que leurs homologues (héros, rival) au manifeste : hauteurs, nettoyage des halos,
attentes calées sur la marche, pêche découpée par `daf5_reliquats.pecher`, buste du menu par
`preparer_menu`. Entrées ajoutées au manifeste, catalogue mis à jour.
Usage : tools/art/joueuse_rivale/preparer_jr.py   (puis tools/build_character_frames.gd)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
ART_DIR = ICI.parent
sys.path.insert(0, str(ART_DIR))
import daf5_reliquats  # noqa: E402
import preparer  # noqa: E402
import preparer_menu  # noqa: E402

RACINE = ART_DIR.parents[1]
ART = RACINE / "build" / "art"
MANIFESTE = ART_DIR / "manifeste.json"
_C = "assets/sprites/characters/painted/"
NOTE = "chantier JR (dossier-joueuse-rivale.md)"

ENTREES = {
	"personnages": [
		{"id": "joueuse", "source": "JR_JOUEUSE_MARCHE_r1.png", "sortie": f"{_C}joueuse_sheet.png",
			"hauteur": 128, "note": NOTE},
		{"id": "joueuse_run", "source": "JR_JOUEUSE_COURSE_r1.png",
			"sortie": f"{_C}joueuse_run_sheet.png", "hauteur": 128,
			"profil_course": {"source": "JR_JOUEUSE_COURSE_PROFIL_r1.png", "rebond": 3},
			"note": NOTE},
		{"id": "joueuse_surf", "source": "JR_JOUEUSE_SURF_r1.png",
			"sortie": f"{_C}joueuse_surf_sheet.png", "hauteur": 134, "nettoyer": True, "note": NOTE},
		{"id": "joueuse_bike", "source": "JR_JOUEUSE_VELO_r1.png",
			"sortie": f"{_C}joueuse_bike_sheet.png", "hauteur": 128, "nettoyer": True, "note": NOTE},
		{"id": "rivale", "source": "JR_RIVALE_MARCHE_r1.png", "sortie": f"{_C}rivale_sheet.png",
			"hauteur": 130, "note": NOTE},
	],
	"attentes": [
		{"id": "joueuse_idle", "source": "JR_JOUEUSE_ATTENTE_r1.png",
			"sortie": f"{_C}joueuse_idle_sheet.png", "marche": "joueuse", "note": NOTE},
		{"id": "joueuse_bike_idle", "source": "JR_JOUEUSE_VELO_ARRET_r1.png",
			"sortie": f"{_C}joueuse_bike_idle_sheet.png", "marche": "joueuse_bike",
			"rapport_hauteur": 0.94, "note": NOTE},
		{"id": "rivale_idle", "source": "JR_RIVALE_ATTENTE_r1.png",
			"sortie": f"{_C}rivale_idle_sheet.png", "marche": "rivale", "note": NOTE},
	],
	"heros_images": [
		{"id": "joueuse_lancer", "source": "JR_JOUEUSE_LANCER_r1.png",
			"sortie": f"{_C}joueuse_lancer.png", "hauteur": 384, "note": NOTE},
		{"id": "joueuse_portrait", "source": "JR_JOUEUSE_PORTRAIT_r1.png",
			"sortie": f"{_C}joueuse_portrait.png", "hauteur": 768, "note": NOTE},
		{"id": "rivale_portrait", "source": "JR_RIVALE_PORTRAIT_r1.png",
			"sortie": f"{_C}rivale_portrait.png", "hauteur": 768, "note": NOTE},
	],
}
PECHE = [
	("joueuse_fish_cast", "JR_JOUEUSE_PECHE_LANCER_r1.png"),
	("joueuse_fish_wait", "JR_JOUEUSE_PECHE_ATTENTE_r1.png"),
]
BUSTE = ("JR_JOUEUSE_BUSTE_r1.png", "assets/ui/menu/heroine_bust.webp")


def main() -> None:
	m = json.loads(MANIFESTE.read_text())
	for section, entrees in ENTREES.items():
		connus = {e["id"] for e in m[section]}
		m[section] += [e for e in entrees if e["id"] not in connus]
	MANIFESTE.write_text(json.dumps(m, ensure_ascii=False, indent=1) + "\n")

	ids = {e["id"] for entrees in ENTREES.values() for e in entrees}
	sous = {k: ([e for e in v if e.get("id") in ids] if isinstance(v, list) else v)
		for k, v in m.items()}
	sous["pokemon"] = []
	p = preparer.Preparateur(sous, ART)
	p.catalogue = json.loads((RACINE / "assets/world/catalogue.json").read_text())
	p.personnages()
	p.attentes()
	p.heros_images()
	for ident, source in PECHE:
		largeur, hauteur = daf5_reliquats.pecher(ART / source, RACINE / f"{_C}joueuse_sheet.png",
			RACINE / f"{_C}{ident}_sheet.png")
		p.catalogue["personnages"][ident] = {
			"fichier": f"res://{_C}{ident}_sheet.png", "cellule": [largeur, hauteur],
			"hauteur": p.catalogue["personnages"]["joueuse"]["hauteur"], "colonnes": 4, "lignes": 1,
			"ordre_colonnes": ["bas", "gauche", "droite", "haut"]}
	p.ecrire_catalogue()
	preparer_menu._heros(ART / BUSTE[0], RACINE / BUSTE[1])
	print(f"buste : {BUSTE[1]}")


if __name__ == "__main__":
	main()
