#!/usr/bin/env python3
"""Tableau « équipe × variante » des rapports de seuils (jalon 16 T18).

  python3 tools/sim/table_sim.py <rapport.txt> [<rapport.txt> ...]

Une ligne par équipe ; par réglage (texte après « : » dans le nom de la variante), victoires au
premier essai attentif / expert / naïf (« sac de Carmin » et « ordre gardé » à part), tours et
K.O. de l'attentif.
"""
import re
import sys

HEAD = re.compile(r"^--- (.+?) \| (.+)$")
ARRIVAL = re.compile(r"^  arrivée au bout (\d+\.\d) %")
STEP = re.compile(r"(\d+\.\d) tours \| K\.O\. (\d+\.\d\d)")


def main():
	cells = {}
	teams = []
	settings = []
	cur = None
	for path in sys.argv[1:]:
		with open(path, encoding="utf-8") as f:
			for line in f:
				m = HEAD.match(line.rstrip("\n"))
				if m and "Équipes de départ" not in line:
					team, variant = m.group(1), m.group(2)
					player, _, setting = variant.partition(" : ")
					who = player.split(",")[0] + (" ordre" if "ordre" in player else "") \
						+ (" sac" if "sac de Carmin" in player else "")
					cur = cells.setdefault((team, setting), {}).setdefault(who, {})
					if team not in teams:
						teams.append(team)
					if setting not in settings:
						settings.append(setting)
					continue
				if cur is None:
					continue
				m = ARRIVAL.match(line)
				if m:
					cur["win"] = float(m.group(1))
					continue
				m = STEP.search(line)
				if m and "tours" not in cur:
					cur["tours"], cur["ko"] = m.group(1), m.group(2)
	for setting in settings:
		print("## " + setting)
		for team in teams:
			row = cells.get((team, setting))
			if not row:
				continue
			parts = []
			for who in ["attentif", "expert", "naïf", "attentif sac", "expert sac",
					"attentif ordre", "expert ordre"]:
				if who in row and "win" in row[who]:
					parts.append("%s %.0f" % (who, row[who]["win"]))
			a = row.get("attentif", {})
			print("  %-72s %s | att. %s tours, %s K.O." % (team[:72], " / ".join(parts),
				a.get("tours", "—"), a.get("ko", "—")))


if __name__ == "__main__":
	main()
