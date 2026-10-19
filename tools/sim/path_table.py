#!/usr/bin/env python3
"""Tableau Markdown des parcours du jalon 16 (T18) : rival n° 4 et Major Bob.

  python3 tools/sim/path_table.py <rapport.txt> [<rapport.txt> ...]

Par « équipe | variante » : meneur avant le rival, victoire au premier essai, tentatives moyennes
et part des parties qui le battent (avec les reprises) ; idem pour Major Bob ; arrivée au bout
sans défaite.
"""
import re
import sys

HEAD = re.compile(r"^--- (.+?) \| (.+)$")
ARRIVAL = re.compile(r"^  arrivée au bout (\d+\.\d) %")
TRIES = re.compile(r"^  tentatives : (.+?)\s+(\d+\.\d\d) jusqu'à .*battu\s+(\d+\.\d) %")
STEP = re.compile(r"^  (.+?)\s+(\d+\.\d) % \| combats .*?vict\.\s+(\d+\.\d) %.*?"
	r"(\d+\.\d) tours \| K\.O\. (\d+\.\d\d).*?PV après\s+(\d+|—) %?.*?meneur avant N(\d+\.\d)")
RIVAL = "Rival n° 4"
BOB = "Major Bob"


def main():
	rows = []
	cur = None
	for path in sys.argv[1:]:
		with open(path, encoding="utf-8") as f:
			for line in f:
				line = line.rstrip("\n")
				m = HEAD.match(line)
				if m and "Équipes de départ" not in line:
					cur = {"team": m.group(1), "variant": m.group(2), "tries": {}, "steps": {}}
					rows.append(cur)
					continue
				if cur is None:
					continue
				m = ARRIVAL.match(line)
				if m:
					cur["arrival"] = m.group(1)
				m = TRIES.match(line)
				if m:
					cur["tries"][m.group(1).strip()] = (m.group(2), m.group(3))
				m = STEP.match(line)
				if m:
					cur["steps"][m.group(1).strip()] = m.groups()[1:]
	print("| Équipe | Variante | Rival : meneur, 1er essai, tours, K.O. (tentatives, battu) "
		"| Bob : meneur, 1er essai (tentatives, battu) | Sans défaite |")
	print("|---|---|---|---|---|")
	for r in rows:
		cells = []
		for key in (RIVAL, BOB):
			label = next((k for k in r["steps"] if k.startswith(key)), None)
			if label is None:
				cells.append("—")
				continue
			s = r["steps"][label]
			t = r["tries"].get(label)
			extra = " (%s ; %s %%)" % t if t else ""
			if key == RIVAL:
				cells.append("N%s, **%s %%**, %s t., %s K.O.%s" % (s[5], s[1], s[2], s[3], extra))
			else:
				cells.append("N%s, **%s %%**%s" % (s[5], s[1], extra))
		print("| %s | %s | %s | %s | %s %% |" % (r["team"], r["variant"], cells[0], cells[1],
			r.get("arrival", "—")))


if __name__ == "__main__":
	main()
