#!/usr/bin/env python3
"""Contrôle des brouillons de données du jalon 22 (tâche T5), hors du jeu.

Lit `docs/tech/j22-donnees/` (Dresseurs, répliques, rencontres, classes, placement) et le
dossier 25 (§8.8, §9, §16.4) ; vérifie :
  - la syntaxe JSON de chaque brouillon ;
  - 40 Dresseurs, ids et équipes (espèces, niveaux, ordre) du dossier §9, un fichier par route ;
  - les clés et l'argent (`prize_per_level` de la classe, `classes.json`) ;
  - les répliques avant / défaite / après **mot pour mot** (§16.4 ; « / » = retour à la ligne) ;
  - le placement : portée = ceil(RB × 1,5), (I) du dossier, au plus un inévitable par route ;
  - les rencontres : format `slots`, poids RB (somme 256), espèces de §8.8 (+ écarts listés) ;
  - les espèces utilisées absentes de `data/pokemon/species/` sur la branche (avertissement).

Usage : python3 -I tools/check_j22_drafts.py   (code retour 1 si une erreur, 0 sinon)
"""

import glob
import json
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DRAFTS = os.path.join(ROOT, "docs", "tech", "j22-donnees")
DOSSIER = os.path.join(ROOT, "docs", "design", "dossier-25-deux-chemins-parmanie.md")
SPECIES_DIR = os.path.join(ROOT, "data", "pokemon", "species")

# Fichier de brouillon → section du dossier §9 / ligne du §8.8.
ROUTES = {
	"route_12_sud": ("9.1", "Route 12 sud"),
	"route_13": ("9.2", "Route 13"),
	"route_14": ("9.3", "Route 14"),
	"route_15": ("9.4", "Route 15"),
	"route_16_ouest": ("9.5", "Route 16 ouest"),
	"route_17": ("9.6", "Route 17"),
	"route_18": ("9.7", "Route 18"),
}

# Noms français des espèces pas encore présentes sur la branche (les autres viennent des
# données). Ids anglais en minuscules, convention de data/pokemon/species/.
EXTRA_NAMES = {
	"Magicarpe": "magikarp", "Électrode": "electrode", "Ptitard": "poliwag",
	"Tadmorv": "grimer", "Grotadmorv": "muk", "Canarticho": "farfetchd", "Doduo": "doduo",
	"Dodrio": "dodrio", "Saquedeneu": "tangela", "Smogogo": "weezing", "Machopeur": "machoke",
	"Aéromite": "venomoth",
}

# Corrections de traduction du dossier, appliquées après les noms des données (signalées à
# Kevin) : « Boustiflor » du §8.8 et de route_15_lass_1 désigne le GLOOM de RB version Rouge
# (Ortide) ; Boustiflor = Weepinbell, version Bleue.
NAME_FIXES = {"Boustiflor": "gloom"}

# Ligne du §16.4 → Dresseurs. « Motard (16-1, 16-2) » cite aussi le 16-2, qui a sa propre
# ligne « inévitable » : la ligne la plus précise l'emporte (écart signalé à Kevin).
ROWS = {
	"Pêcheur (12)": ["route_12_fisher_5"],
	"Jeune Dresseur (12)": ["route_12_youngster"],
	"Rockeur (12)": ["route_12_rocker"],
	"Ornithologue (13-1)": ["route_13_bird_1"],
	"Jeune Dresseuse (13-1)": ["route_13_lass_1"],
	"Jeune Dresseuse (13-2)": ["route_13_lass_2"],
	"Jeune Dresseuse (13-3)": ["route_13_lass_3"],
	"Beauté (13)": ["route_13_beauty"],
	"Motard (13)": ["route_13_biker"],
	"Ornithologue (13-2)": ["route_13_bird_2"],
	"Ornithologue (14-1)": ["route_14_bird_1"],
	"Ornithologue (14-2 à 14-4)": ["route_14_bird_2", "route_14_bird_3", "route_14_bird_4"],
	"Motard (14-1 à 14-3)": ["route_14_biker_1", "route_14_biker_2", "route_14_biker_3"],
	"Jeune Dresseuse (15-1, 15-3)": ["route_15_lass_1", "route_15_lass_3"],
	"Jeune Dresseuse (15-2)": ["route_15_lass_2"],
	"Beauté (15-1)": ["route_15_beauty_1"],
	"Beauté (15-2)": ["route_15_beauty_2"],
	"Ornithologue (15)": ["route_15_bird"],
	"Motard (15)": ["route_15_biker"],
	"Motard (16-1, 16-2)": ["route_16_biker_1"],
	"Loubard (16, 17)": [
		"route_16_cueball_1", "route_16_cueball_2", "route_16_cueball_3", "route_17_cueball_1",
		"route_17_cueball_2", "route_17_cueball_3", "route_17_cueball_4",
	],
	"Motard (16-2, inévitable)": ["route_16_biker_2"],
	"Motard (17)": ["route_17_biker_1", "route_17_biker_2", "route_17_biker_3", "route_17_biker_4"],
	"Ornithologue (18)": ["route_18_bird_1", "route_18_bird_2", "route_18_bird_3"],
}

# Écarts assumés avec le §8.8 (RB version Rouge), signalés à Kevin : Roucoups (créneaux 8 et 9
# de RB) gardé sur les Routes 14 et 15 ; Chétiflor 24 de ces deux lignes non repris.
ENCOUNTER_EXTRA = {"route_14": {"pidgeotto"}, "route_15": {"pidgeotto"}}
ENCOUNTER_SKIPPED = {"route_14": {"bellsprout"}, "route_15": {"bellsprout"}}

TRAINER_KEYS = {"name", "ai", "can_lose", "heal_after", "gives_exp", "prize_money",
	"prize_per_level", "team"}
DIALOGUE_KEYS = {"speaker", "pages"}

errors = []
warnings = []


def err(msg):
	errors.append(msg)


def load(path):
	try:
		with open(path, encoding="utf-8") as f:
			return json.load(f)
	except (OSError, ValueError) as e:
		err("%s : JSON illisible (%s)" % (os.path.relpath(path, ROOT), e))
		return None


def species_names():
	names, ids = {}, set()
	for path in sorted(glob.glob(os.path.join(SPECIES_DIR, "*.json"))):
		data = load(path) or {}
		for sid, entry in data.items():
			ids.add(sid)
			names[entry.get("name", "")] = sid
	for fr, sid in EXTRA_NAMES.items():
		names.setdefault(fr, sid)
	names.update(NAME_FIXES)
	return names, ids


def section(text, title):
	part = text.split(title, 1)
	if len(part) < 2:
		err("dossier : section « %s » introuvable" % title)
		return ""
	return re.split(r"\n#{2,3} ", part[1], maxsplit=1)[0]


def table_rows(text):
	for line in text.splitlines():
		line = line.strip()
		if line.startswith("|") and not re.match(r"^\|[\s\-|]+\|$", line):
			yield [c.strip() for c in line.strip("|").split("|")]


def parse_team(cell, names):
	team = []
	for part in cell.replace("(I)", "").split(","):
		m = re.match(r"^(.+?) (\d+)$", part.strip())
		if not m:
			err("dossier §9 : équipe illisible « %s »" % part)
			continue
		fr = m.group(1).strip()
		if fr not in names:
			err("dossier §9 : espèce inconnue « %s » (ajouter à EXTRA_NAMES)" % fr)
			continue
		team.append((names[fr], int(m.group(2))))
	return team


def main():
	with open(DOSSIER, encoding="utf-8") as f:
		dossier = f.read()
	names, known = species_names()
	used = {}

	classes = load(os.path.join(DRAFTS, "classes.json")) or {}
	class_by_name = {v["name"]: k for k, v in classes.items() if not k.startswith("_")}
	for cid in ("fisherman", "biker", "bird_keeper", "cue_ball"):
		if cid not in classes:
			err("classes.json : classe « %s » absente" % cid)
	expected_ppl = {"fisherman": 35, "biker": 20, "bird_keeper": 25, "cue_ball": 25}
	for cid, ppl in expected_ppl.items():
		if cid in classes and classes[cid].get("prize_per_level") != ppl:
			err("classes.json : %s doit valoir %d par niveau (plan §2.12)" % (cid, ppl))

	# --- Dossier §9 : ids, classes, équipes, (I).
	expected = {}
	for fname, (num, _) in ROUTES.items():
		for row in table_rows(section(dossier, "### %s " % num)):
			if len(row) != 3 or not row[0].startswith("`"):
				continue
			tid = row[0].strip("`")
			expected[tid] = {"file": fname, "class": row[1], "team": parse_team(row[2], names),
				"unavoidable": "(I)" in row[2]}
	if len(expected) != 40:
		err("dossier §9 : %d Dresseurs lus au lieu de 40" % len(expected))

	# --- Brouillons des Dresseurs.
	found = {}
	for fname in ROUTES:
		data = load(os.path.join(DRAFTS, "trainers", fname + ".json"))
		if data is None:
			continue
		for tid, tr in data.items():
			if tid in found:
				err("Dresseur %s en double" % tid)
			found[tid] = fname
			exp = expected.get(tid)
			if exp is None:
				err("%s : Dresseur %s absent du dossier §9" % (fname, tid))
				continue
			if exp["file"] != fname:
				err("%s : doit être dans %s.json" % (tid, exp["file"]))
			if set(tr) != TRAINER_KEYS:
				err("%s : clés %s" % (tid, sorted(set(tr) ^ TRAINER_KEYS)))
			if tr.get("name") != exp["class"]:
				err("%s : nom « %s », classe attendue « %s »" % (tid, tr.get("name"), exp["class"]))
			cid = class_by_name.get(exp["class"])
			if cid is None:
				err("%s : classe « %s » absente de classes.json" % (tid, exp["class"]))
			elif tr.get("prize_per_level") != classes[cid]["prize_per_level"]:
				err("%s : prize_per_level %s ≠ %s" % (tid, tr.get("prize_per_level"),
					classes[cid]["prize_per_level"]))
			if tr.get("ai") != "random" or tr.get("prize_money") != 0:
				err("%s : ai « random » et prize_money 0 attendus" % tid)
			if (tr.get("can_lose"), tr.get("heal_after"), tr.get("gives_exp")) != (False, False, True):
				err("%s : can_lose/heal_after/gives_exp ≠ false/false/true" % tid)
			team = [(s.get("species"), s.get("level")) for s in tr.get("team", [])]
			if team != exp["team"]:
				err("%s : équipe %s ≠ dossier %s" % (tid, team, exp["team"]))
			for sid, _ in team:
				used.setdefault(sid, set()).add(tid)
	for tid in expected:
		if tid not in found:
			err("Dresseur %s du dossier absent des brouillons" % tid)
	if len(found) != 40:
		err("%d Dresseurs dans les brouillons au lieu de 40" % len(found))

	# --- Répliques §16.4, mot pour mot.
	lines = {}
	for row in table_rows(section(dossier, "### 16.4 Dresseurs")):
		if len(row) == 4 and row[1].startswith("«"):
			lines[row[0]] = [re.sub(r"^« | »$", "", c) for c in row[1:]]
	if set(lines) != set(ROWS):
		err("§16.4 : lignes inattendues %s" % sorted(set(lines) ^ set(ROWS)))
	owner = {}
	for label, ids in ROWS.items():
		for tid in ids:
			if tid in owner:
				err("%s : deux lignes de répliques" % tid)
			owner[tid] = label
	if set(owner) != set(expected):
		err("répliques : Dresseurs sans ligne %s" % sorted(set(expected) ^ set(owner)))
	dialogues = {}
	for fname in ROUTES:
		data = load(os.path.join(DRAFTS, "dialogues", fname + ".json"))
		if data is not None:
			dialogues.update(data)
	for tid, label in owner.items():
		for suffix, text in zip(("before", "defeated", "after"), lines.get(label, ["", "", ""])):
			key = "%s_%s" % (tid, suffix)
			d = dialogues.get(key)
			if d is None:
				err("réplique %s absente" % key)
				continue
			if set(d) != DIALOGUE_KEYS or len(d["pages"]) != 1:
				err("%s : format (speaker + une page attendus)" % key)
				continue
			if d["pages"][0].replace("\n", " / ") != text:
				err("%s : « %s » ≠ dossier « %s »" % (key, d["pages"][0], text))
			if expected.get(tid) and d["speaker"] != expected[tid]["class"]:
				err("%s : speaker « %s »" % (key, d["speaker"]))
	extra = set(dialogues) - {"%s_%s" % (t, s) for t in owner for s in ("before", "defeated", "after")}
	if extra:
		err("répliques en trop : %s" % sorted(extra))

	# --- Placement : portée RB × 1,5, inévitables.
	placement = load(os.path.join(DRAFTS, "placement.json")) or {}
	per_route = {}
	for tid, exp in expected.items():
		p = placement.get(tid)
		if p is None:
			err("placement : %s absent" % tid)
			continue
		if p.get("sight") != math.ceil(p.get("rb_sight", 0) * 1.5):
			err("placement %s : sight %s ≠ ceil(%s × 1,5)" % (tid, p.get("sight"), p.get("rb_sight")))
		if p.get("unavoidable") != exp["unavoidable"]:
			err("placement %s : (I) ≠ dossier" % tid)
		if exp["unavoidable"]:
			per_route[exp["file"]] = per_route.get(exp["file"], 0) + 1
	for route, n in per_route.items():
		if n > 1:
			err("%s : %d inévitables (au plus un, M-15)" % (route, n))

	# --- Rencontres §8.8.
	enc_rows = {}
	for row in table_rows(section(dossier, "### 8.8 Rencontres")):
		if len(row) == 3 and row[0] in {v[1] for v in ROUTES.values()}:
			enc_rows[row[0]] = row[2]
	for fname, (_, label) in ROUTES.items():
		data = load(os.path.join(DRAFTS, "encounters", fname + ".json"))
		if data is None:
			continue
		cell = re.sub(r"\(.*?\)", "", enc_rows.get(label, ""))
		listed = set()
		for part in cell.split(","):
			m = re.match(r"^(.+?) \d", part.strip())
			if m and m.group(1).strip() in names:
				listed.add(names[m.group(1).strip()])
		allowed = (listed - ENCOUNTER_SKIPPED.get(fname, set())) | ENCOUNTER_EXTRA.get(fname, set())
		if len(data) != 1:
			err("%s : une seule table d'herbes attendue" % fname)
		for tab_id, tab in data.items():
			if set(tab) != {"maps", "terrain", "rate", "ramp", "slots"} or tab.get("terrain") != "grass":
				err("%s : clés ou terrain inattendus" % tab_id)
			if not 1 <= tab.get("rate", 0) <= 255:
				err("%s : rate hors 1..255" % tab_id)
			total = sum(s.get("weight", 0) for s in tab.get("slots", []))
			if total != 256:
				err("%s : poids %d ≠ 256 (chances RB)" % (tab_id, total))
			seen = set()
			for s in tab.get("slots", []):
				lv = s.get("levels", [0, 0])
				if set(s) != {"species", "levels", "weight"} or not 1 <= lv[0] <= lv[1] <= 100:
					err("%s : emplacement mal formé %s" % (tab_id, s))
				seen.add(s.get("species"))
				used.setdefault(s.get("species"), set()).add(tab_id)
			if seen != allowed:
				err("%s : espèces %s ≠ §8.8 %s" % (tab_id, sorted(seen), sorted(allowed)))

	# --- Espèces absentes de la branche.
	missing = sorted(sid for sid in used if sid not in known)
	for sid in missing:
		warnings.append("espèce absente de data/pokemon : %s (%d usages)" % (sid, len(used[sid])))

	print("Brouillons J22 : %d Dresseurs, %d répliques, %d tables de rencontres" % (
		len(found), len(dialogues), len(ROUTES)))
	for w in warnings:
		print("AVERTISSEMENT : " + w)
	for e in errors:
		print("ERREUR : " + e)
	print("OK" if not errors else "%d erreur(s)" % len(errors))
	return 1 if errors else 0


if __name__ == "__main__":
	sys.exit(main())
