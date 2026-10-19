#!/usr/bin/env python3
"""Résume les rapports bruts de tools/simulate_mt_moon.gd (jalon 16 T18).

  python3 tools/sim/summarize_sim.py <rapport.txt> [étape ...]

Pour chaque ligne « équipe | variante » : arrivée au bout (victoire au premier essai pour un
scénario de seuils), puis, pour chaque étape dont le libellé contient un des textes donnés :
victoires, tours, K.O., PV après, niveau du meneur avant, tentatives jusqu'à la victoire.
"""
import re
import sys

HEAD = re.compile(r"^--- (.+?) \| (.+)$")
STEP = re.compile(r"^  (.+?)\s+(\d+\.\d) % \| combats .*?vict\.\s+(\d+\.\d) %.*?"
	r"(\d+\.\d) tours \| K\.O\. (\d+\.\d\d).*?PV après\s+(\d+|—) %?.*?meneur avant N(\d+\.\d)")
TRIES = re.compile(r"^  tentatives : (.+?)\s+(\d+\.\d\d) jusqu'à .*battu\s+(\d+\.\d) %")
ARRIVAL = re.compile(r"^  arrivée au bout (\d+\.\d) %")
RETRY = re.compile(r"^  avec reprises au Centre : (.+)$")


def main():
	path = sys.argv[1]
	wanted = sys.argv[2:]
	rows = []
	cur = None
	with open(path, encoding="utf-8") as f:
		for line in f:
			line = line.rstrip("\n")
			m = HEAD.match(line)
			if m and "Équipes de départ" not in line:
				cur = {"team": m.group(1), "variant": m.group(2), "arrival": None, "steps": {},
					"tries": {}, "retry": ""}
				rows.append(cur)
				continue
			if cur is None:
				continue
			m = ARRIVAL.match(line)
			if m:
				cur["arrival"] = float(m.group(1))
				continue
			m = RETRY.match(line)
			if m:
				cur["retry"] = m.group(1)
				continue
			m = TRIES.match(line)
			if m:
				cur["tries"][m.group(1).strip()] = (float(m.group(2)), float(m.group(3)))
				continue
			m = STEP.match(line)
			if m:
				cur["steps"][m.group(1).strip()] = m.groups()[1:]
	for r in rows:
		print("%s | %s | arrivée %.1f %%" % (r["team"], r["variant"], r["arrival"] or 0.0))
		for label, s in r["steps"].items():
			if wanted and not any(w in label for w in wanted):
				continue
			tries = ""
			for tl, t in r["tries"].items():
				if tl == label:
					tries = " | tentatives %.2f (battu %.1f %%)" % t
			print("    %-45s atteint %5s %% vict. %5s %% | %4s tours | K.O. %s | PV %s %% | "
				"meneur N%s%s" % (label[:45], s[0], s[1], s[2], s[3], s[4], s[5], tries))
		if r["retry"]:
			print("    reprises : " + r["retry"])


if __name__ == "__main__":
	main()
