#!/usr/bin/env python3
"""Compatibilités des CT de Rouge/Bleu pour les espèces du jeu (jalon 11, lot 11B préparé).

Dossier 14 §6.1 : compatibilité **par espèce**, reprise de Rouge/Bleu (valeur par défaut, règle 4).
Source : les CSV publics de PokeAPI (dépôt PokeAPI/pokeapi, `data/v2/csv/`) : `pokemon_moves.csv`,
`moves.csv`, `pokemon.csv`, `machines.csv`, `version_groups.csv`, `pokemon_move_methods.csv`.
Écrit `data/pokemon/tm_compatibility.json` (CT 01–50 → capacité, espèce → numéros de CT), pour
**toutes** les espèces des fichiers `data/pokemon/species/*.json` (jalon 12 : `kanto.json` et
`kanto_mt_moon.json` ; J15 : `kanto_vermilion.json` ; les fichiers à part des jalons suivants aussi), par numéro de Pokédex.
Fichier **généré** : en cas de conflit de fusion, le régénérer, ne jamais le fusionner à la main. Lu par `PokemonData`
(`can_learn_tm`, lot CT 11B, `jalon-11.md` §2.6).

Usage : python3 -I tools/gen_tm_compatibility.py DOSSIER_DES_CSV
  (télécharger les six CSV dans un dossier neuf, par ex. avec curl depuis
   https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/<nom>.csv)
"""
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[1]
ESPECES = RACINE / "data/pokemon/species"
SORTIE = RACINE / "data/pokemon/tm_compatibility.json"
GROUPE = "red-blue"
METHODE = "machine"


def _lire(dossier: Path, nom: str) -> list[dict[str, str]]:
	with open(dossier / f"{nom}.csv", newline="", encoding="utf-8") as fichier:
		return list(csv.DictReader(fichier))


def _ident(identifiant_pokeapi: str) -> str:
	return identifiant_pokeapi.replace("-", "_")


def main() -> None:
	dossier = Path(sys.argv[1])
	groupe = next(l["id"] for l in _lire(dossier, "version_groups") if l["identifier"] == GROUPE)
	methode = next(l["id"] for l in _lire(dossier, "pokemon_move_methods") if l["identifier"] == METHODE)
	capacites = {l["id"]: _ident(l["identifier"]) for l in _lire(dossier, "moves")}
	pokemon = {l["id"]: _ident(l["identifier"]) for l in _lire(dossier, "pokemon")}
	# CT de Rouge/Bleu : numéros 1 à 50 (les CS ont des numéros ≥ 101 dans PokeAPI).
	ct_par_capacite: dict[str, int] = {}
	tms: dict[str, str] = {}
	for ligne in _lire(dossier, "machines"):
		numero = int(ligne["machine_number"])
		if ligne["version_group_id"] == groupe and 1 <= numero <= 50:
			ct_par_capacite[ligne["move_id"]] = numero
			tms[f"{numero:02d}"] = capacites[ligne["move_id"]]
	assert len(tms) == 50, f"50 CT attendues, {len(tms)} trouvées"
	toutes: dict[str, dict] = {}
	for fichier in sorted(ESPECES.glob("*.json")):
		contenu = json.loads(fichier.read_text(encoding="utf-8"))
		toutes.update(contenu.get("species", contenu))
	especes = sorted(toutes, key=lambda espece: toutes[espece]["dex"])
	compat: dict[str, set[int]] = {espece: set() for espece in especes}
	for ligne in _lire(dossier, "pokemon_moves"):
		if ligne["version_group_id"] != groupe or ligne["pokemon_move_method_id"] != methode:
			continue
		espece = pokemon.get(ligne["pokemon_id"], "")
		numero = ct_par_capacite.get(ligne["move_id"])
		if espece in compat and numero is not None:
			compat[espece].add(numero)
	resultat = {
		"_doc": ("Compatibilités des CT (Rouge/Bleu, dossier 14 §6.1), générées par "
			"tools/gen_tm_compatibility.py depuis les CSV de PokeAPI ; lues par PokemonData "
			"(jalon 11, lot 11B). « tms » : numéro de CT → capacité (identifiants du jeu). « species » : "
			"espèce → numéros de CT compatibles (vide = aucune CT, comme Chenipan ou Aspicot). "
			"Objets CT existants : CT34 (Patience, « bide », J11) et CT01 (Ultimapoing, « mega_punch », "
			"J12) ; les autres CT arrivent avec leur capacité et leur lieu. Fichier généré : le "
			"régénérer après une fusion, jamais le fusionner à la main."),
		"tms": dict(sorted(tms.items())),
		"species": {espece: sorted(compat[espece]) for espece in especes},
	}
	SORTIE.write_text(json.dumps(resultat, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
	vides = [e for e, n in resultat["species"].items() if not n]
	print(f"{SORTIE.relative_to(RACINE)} : {len(especes)} espèces, CT34 = {tms['34']}, "
		f"compatibles CT34 : {sum(34 in n for n in resultat['species'].values())}, sans CT : {vides}")


if __name__ == "__main__":
	main()
