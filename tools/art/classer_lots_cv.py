#!/usr/bin/env python3
"""Combat vivant, T10 (version courte) : classe les 165 attaques par ordre d'exposition au joueur et en tire
les lots P1 à P4 (docs/tech/combat-vivant.md §3.3, §5.1). Écrit docs/tech/combat-vivant-lots.md.
Exposition = étape de l'histoire où l'attaque est vue pour la première fois : jouée par un Pokémon sauvage
ou un Dresseur (les 4 dernières attaques de son learnset au niveau rencontré, ou `moves` si le Dresseur
les fixe), ou apprise par un starter (lignées de Bulbizarre, Salamèche, Carapuce). Les CT et la progression
en dehors de ces sources ne comptent pas : une attaque jamais vue part en P4.
Usage : tools/art/classer_lots_cv.py"""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
DATA = RACINE / "data"
TAILLES = [40, 40, 40, 10**6]

## Étapes de l'histoire (ordre du jeu) : motifs cherchés dans le nom du fichier de rencontres ou de Dresseurs.
ETAPES = [
	("Bourg Palette et Route 1", ["route_1", "rival_lab"]),
	("Route 22, Route 2 sud, Jadielle", ["route_22", "route_2", "rival_route22"]),
	("Forêt de Jade", ["viridian_forest"]),
	("Argenta (Route 2 nord, Arène de Pierre)", ["route_2_north", "pewter_gym", "rival_pewter"]),
	("Route 3 et Mont Sélénite", ["route_3", "mt_moon"]),
	("Route 4, Azuria, Routes 24 et 25", ["route_4", "cerulean", "route_24", "route_25", "rival_cerulean", "rival_route24"]),
	("Routes 5 et 6, Carmin, S.S. Anne", ["route_5", "route_6", "vermilion", "ss_anne", "rival_ss_anne", "rival_route"]),
	("Routes 9 à 11, Grotte Sombre, Taupiqueur", ["route_9", "route_10", "route_11", "dark_cave", "digletts"]),
	("Lavanville, Tour Pokémon, Céladopole", ["pokemon_tower", "route_8", "route_7", "celadon", "rocket_hideout", "rival_tower"]),
	("Routes 12 à 18, Parmanie, Safrania", ["route_12", "route_13", "route_14", "route_15", "route_16", "route_17", "route_18", "fuchsia", "safari", "saffron", "silph", "fighting_dojo", "rival_silph"]),
	("Routes 19 à 21, Îles Écume, Cramois", ["route_19", "route_20", "route_21", "seafoam", "cinnabar", "pokemon_mansion"]),
	("Fin du jeu (Jadielle, Route 22 finale)", ["viridian_gym", "rival_"]),
]
STARTER_ETAPES = [(10, 0), (16, 1), (22, 3), (32, 5), (45, 8), (100, 10)]  ## niveau de la lignée → étape


def etape_de(nom: str) -> int:
	"""Étape du motif le plus long qui correspond (route_2_north l'emporte sur route_2 ; route_1 ≠ route_10)."""
	nom = nom.lower()
	meilleur = (0, len(ETAPES) - 1)
	for i, (_t, motifs) in enumerate(ETAPES):
		for m in motifs:
			if re.search(m + r"(?![0-9])", nom) and len(m) > meilleur[0]:
				meilleur = (len(m), i)
	return meilleur[1]


def charger(chemin: Path) -> dict:
	return json.loads(chemin.read_text(encoding="utf-8"))


def especes() -> dict:
	sortie = {}
	for f in sorted((DATA / "pokemon" / "species").glob("*.json")):
		sortie.update(charger(f))
	return sortie


def attaques_connues(espece: dict, niveau: int) -> list[str]:
	apprises = [m for n, m in sorted(espece["learnset"], key=lambda x: x[0]) if n <= niveau]
	vues, sortie = set(), []
	for m in apprises:
		if m not in vues:
			vues.add(m)
			sortie.append(m)
	return sortie[-4:]


def exposition() -> tuple[dict, dict]:
	"""(attaque → {étape: nombre}, attaque → exemple lisible de la première source)."""
	esp = especes()
	compte: dict[str, dict[int, int]] = defaultdict(lambda: defaultdict(int))
	source: dict[str, tuple[int, str]] = {}

	def noter(attaque: str, etape: int, qui: str) -> None:
		compte[attaque][etape] += 1
		if attaque not in source or etape < source[attaque][0]:
			source[attaque] = (etape, qui)

	def equipe(membres: list, fichier: str) -> None:
		for m in membres:
			e = esp.get(m.get("species"))
			if not e:
				continue
			niveau = m.get("level", 1)
			for a in m.get("moves") or attaques_connues(e, niveau):
				noter(a, etape_de(fichier), f"{e['name']} niv. {niveau} ({fichier})")

	for f in sorted((DATA / "encounters").glob("*.json")):
		for _k, zone in charger(f).items():
			for s in zone.get("slots", []):
				niv = max(s.get("levels", [1])) if s.get("levels") else 1
				equipe([{"species": s["species"], "level": niv}], f.stem)
	for f in sorted((DATA / "trainers").glob("*.json")):
		for k, t in charger(f).items():
			cle = f"{f.stem}:{k}"
			if "team" in t:
				equipe(t["team"], cle)
			for _s, lignee in (t.get("team_by_starter") or {}).items():
				equipe(lignee, cle)
	for depart in ("bulbasaur", "charmander", "squirtle"):
		courant = depart
		while courant:
			e = esp.get(courant)
			if not e:
				break
			for niveau, a in e["learnset"]:
				etape = next(s for lim, s in STARTER_ETAPES if niveau <= lim)
				noter(a, etape, f"apprise par {e['name']} niv. {niveau} (starter)")
			evo = e.get("evolutions") or []
			courant = evo[0]["into"] if evo else None
	return compte, source


def annexe() -> list[dict]:
	lignes = []
	texte = (RACINE / "docs/tech/combat-vivant.md").read_text(encoding="utf-8").split("## Annexe A")[1]
	for l in texte.splitlines():
		m = re.match(r"\| `(\w+)` \| ([^|]+)\| ([^|]*)\| ([^|]*)\| (\w+) \|([^|]*)\|([^|]*)\|([^|]*)\|", l)
		if m:
			lignes.append({"id": m[1], "nom": m[2].strip(), "type": m[3].strip(), "famille": m[5],
				"impact": m[6].strip(), "mods": m[7].strip(), "phare": m[8].strip()})
	return lignes


def main() -> None:
	compte, source = exposition()
	toutes = annexe()
	for a in toutes:
		a["etape"] = source.get(a["id"], (len(ETAPES) + 1, "jamais vue (CT, apprentissage, jalon à venir)"))[0]
		a["source"] = source.get(a["id"], (0, "jamais vue (CT, apprentissage, jalon à venir)"))[1]
		a["n"] = sum(compte[a["id"]].values())
		a["n_premiere"] = compte[a["id"]].get(a["etape"], 0) if a["etape"] <= len(ETAPES) else 0
	toutes.sort(key=lambda a: (a["etape"], -a["phare"].startswith("oui"), -a["n_premiere"], -a["n"], a["id"]))
	lots, debut = [], 0
	for t in TAILLES:
		lots.append(toutes[debut:debut + t])
		debut += t
	sortie = ["# Combat vivant — lots d'animations P1 à P4 (classement par ordre d'exposition)", "",
		"> Généré par `tools/art/classer_lots_cv.py` (T10, version courte). **Ne pas modifier à la main : relancer le script.** "
		"Annexe A de `combat-vivant.md` pour les familles. Les lots P1 à P4 ont 40, 40, 40 attaques puis le reste.", "",
		"**Méthode.** Pour chaque attaque, la première étape de l'histoire où le joueur la voit : jouée par un Pokémon "
		"sauvage ou un Dresseur (les 4 dernières attaques de son learnset au niveau rencontré, ou la liste fixée par le "
		"Dresseur), ou apprise par un starter. Ordre des étapes ci-dessous ; à égalité : signature d'abord, puis nombre "
		"d'apparitions à cette étape. Les CT sont hors du calcul.", "", "## Étapes", ""]
	sortie += [f"{i}. {t}" for i, (t, _m) in enumerate(ETAPES)]
	for k, lot in enumerate(lots, 1):
		sortie += ["", f"## Lot P{k} ({len(lot)} attaques)", ""]
		fam = defaultdict(int)
		for a in lot:
			fam[a["famille"]] += 1
		sortie.append("Familles : " + ", ".join(f"{f} {n}" for f, n in sorted(fam.items(), key=lambda x: -x[1])) + ".")
		sortie += ["", "| # | id | Nom | Type | Famille | Impact | Modificateurs | Phare | Première exposition |", "|---|---|---|---|---|---|---|---|---|"]
		for i, a in enumerate(lot, 1):
			etape = ETAPES[a["etape"]][0] if a["etape"] < len(ETAPES) else "jamais vue"
			sortie.append(f"| {i} | `{a['id']}` | {a['nom']} | {a['type']} | {a['famille']} | {a['impact']} | {a['mods']} | {a['phare']} | {etape} — {a['source']} |")
	(RACINE / "docs/tech/combat-vivant-lots.md").write_text("\n".join(sortie) + "\n", encoding="utf-8")
	print(len(toutes), "attaques classées ;", [len(l) for l in lots])


if __name__ == "__main__":
	main()
