#!/usr/bin/env python3
"""Génère le scénario d'équilibrage du rival n° 5 (jalon 19 T21) pour tools/simulate_mt_moon.gd.

Règle de Kevin (Q-T21-4, 2026-10-19) : grand combat, victoire au premier essai du joueur attentif
d'environ 40 à 60 % pour chaque starter, jamais au-dessus de 80 %, mesurée sur les vraies sorties
du J18 (équipes de tools/sim/tower_scenario_j18_exits.json, mesurées au T10).

  python3 tools/sim/gen_tower_t21.py [sortie.json]     # défaut : tools/sim/tower_t21.json

Un réglage = un groupe facultatif (Centre + rival) ; le rival seul, équipe soignée, 5 Super
Potions, 3 Antidotes, 2 Réveils, joueurs attentif et expert, au premier essai. Chaque réglage ne
change que l'équipe opposée à un starter : filtrer les équipes avec --equipe (« Reptincel »,
« Carabaffe », « Herbizarre ») et les réglages avec --variante (« s22, »).
Résultats et choix : docs/tech/jalon-19-equilibrage.md §8 (clés s.., c.., b.. du tableau).
« retenu » = l'équipe de data/trainers/pokemon_tower.json (rival_tower).
"""
import copy
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ITEMS = {"super_potion": 5, "antidote": 3, "awakening": 2}

# Capacités choisies à la main (plan §2.6, Q-T21-3 : Kadabra suit la règle du J16).
PIDGEOTTO = ["gust", "sand_attack", "quick_attack"]
GROWLITHE = ["bite", "ember", "leer"]
GYARADOS = ["bite", "dragon_rage", "leer"]
KADABRA_J16 = ["confusion", "psybeam"]
EXEGGCUTE = ["barrage", "hypnosis"]
CHARMELEON = ["scratch", "growl", "ember", "leer"]
NO_GUST = ["sand_attack", "quick_attack"]


def load(rel):
	with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
		return json.load(f)


def mon(species, level, moves=None):
	m = {"species": species, "level": level}
	if moves:
		m["moves"] = list(moves)
	return m


def team_charmander(l, kadabra=KADABRA_J16, wartortle=None):
	"""Contre Salamèche : Roucoups, Caninos, Noeunoeuf, Kadabra, Carabaffe."""
	return [mon("pidgeotto", l[0], PIDGEOTTO), mon("growlithe", l[1], GROWLITHE),
		mon("exeggcute", l[2], EXEGGCUTE), mon("kadabra", l[3], kadabra),
		mon("wartortle", l[4], wartortle)]


def team_squirtle(l, kadabra=KADABRA_J16, gyarados=GYARADOS, ivysaur=None):
	"""Contre Carapuce : Roucoups, Léviator, Caninos, Kadabra, Herbizarre."""
	return [mon("pidgeotto", l[0], PIDGEOTTO), mon("gyarados", l[1], gyarados),
		mon("growlithe", l[2], GROWLITHE), mon("kadabra", l[3], kadabra),
		mon("ivysaur", l[4], ivysaur)]


def team_bulbasaur(l, kadabra=KADABRA_J16, gyarados=GYARADOS, charmeleon=CHARMELEON,
		pidgeotto=PIDGEOTTO, exeggcute=EXEGGCUTE, third=("gyarados", None)):
	"""Contre Bulbizarre : Roucoups, Noeunoeuf, Léviator (ou remplaçant), Kadabra, Reptincel."""
	species, moves = third
	if species == "gyarados":
		moves = gyarados
	return [mon("pidgeotto", l[0], pidgeotto), mon("exeggcute", l[1], exeggcute),
		mon(species, l[2], moves), mon("kadabra", l[3], kadabra),
		mon("charmeleon", l[4], charmeleon)]


# Réglages : (clé, starter du joueur, libellé, équipe du rival).
SETTINGS = [
	("s00", "charmander", "Salamèche, T10 (r01) : 22/22/22, Kadabra 18 naturel, Carabaffe 22",
		team_charmander([22, 22, 22, 18, 22], kadabra=None)),
	("s01", "charmander", "Salamèche : 22/22/22, Kadabra 18 (J16), Carabaffe 22",
		team_charmander([22, 22, 22, 18, 22])),
	("s02", "charmander", "Salamèche : 24/24/24, Kadabra 22 (J16), Carabaffe 26",
		team_charmander([24, 24, 24, 22, 26])),
	("c00", "squirtle", "Carapuce, T10 (r01) : 22/22/22, Kadabra 18 naturel, Herbizarre 22",
		team_squirtle([22, 22, 22, 18, 22], kadabra=None)),
	("c01", "squirtle", "Carapuce : 22/22/22, Kadabra 18 (J16), Herbizarre 22",
		team_squirtle([22, 22, 22, 18, 22])),
	("c02", "squirtle", "Carapuce : 24/24/24, Kadabra 22 (J16), Herbizarre 26",
		team_squirtle([24, 24, 24, 22, 26])),
	("b00", "bulbasaur", "Bulbizarre, T10 (r01) : 22/22/22, Kadabra 18 naturel, Reptincel 22",
		team_bulbasaur([22, 22, 22, 18, 22], kadabra=None)),
	("b01", "bulbasaur", "Bulbizarre : 22/22/22, Kadabra 18 (J16), Reptincel 22",
		team_bulbasaur([22, 22, 22, 18, 22])),
	("b03", "bulbasaur", "Bulbizarre : 22/22/22, Kadabra 18 (J16), Reptincel 22, "
		"Léviator Charge + Groz'Yeux",
		team_bulbasaur([22, 22, 22, 18, 22], gyarados=["tackle", "leer"])),
	("b06", "bulbasaur", "Bulbizarre : 22/22/22, Kadabra 18 (J16), Reptincel 22, "
		"Sabelette au lieu de Léviator",
		team_bulbasaur([22, 22, 22, 18, 22], third=("sandshrew", None))),
	("s10", "charmander", "Salamèche : 23/23/23, Kadabra 20 (J16), Carabaffe 24",
		team_charmander([23, 23, 23, 20, 24])),
	("s12", "charmander", "Salamèche : 23/23/23, Kadabra 21 (J16), Carabaffe 25",
		team_charmander([23, 23, 23, 21, 25])),
	("b11", "bulbasaur", "Bulbizarre : 18/18/18, Kadabra 16 (J16), Reptincel 20, "
		"Léviator Charge + Groz'Yeux",
		team_bulbasaur([18, 18, 18, 16, 20], gyarados=["tackle", "leer"])),
	("b12", "bulbasaur", "Bulbizarre : 18/18/18, Kadabra 16 (J16), Reptincel 20, "
		"Sabelette au lieu de Léviator",
		team_bulbasaur([18, 18, 18, 16, 20], third=("sandshrew", None))),
	("b13", "bulbasaur", "Bulbizarre : 18/18/18, Kadabra 16 (J16), Reptincel 20, "
		"Roucoups sans Tornade, Léviator Charge + Groz'Yeux",
		team_bulbasaur([18, 18, 18, 16, 20], pidgeotto=NO_GUST, gyarados=["tackle", "leer"])),
	("b14", "bulbasaur", "Bulbizarre : 20/20/20, Kadabra 17 (J16), Reptincel 21, "
		"Roucoups sans Tornade, Sabelette au lieu de Léviator",
		team_bulbasaur([20, 20, 20, 17, 21], pidgeotto=NO_GUST, third=("sandshrew", None))),
	("s20", "charmander", "Salamèche : 23/23/23, Kadabra 20 (J16), Carabaffe 25",
		team_charmander([23, 23, 23, 20, 25])),
	("s22", "charmander", "Salamèche : 22/22/22, Kadabra 20 (J16), Carabaffe 25",
		team_charmander([22, 22, 22, 20, 25])),
	("c24", "squirtle", "Carapuce : 23/24/23, Kadabra 22 (J16), Herbizarre 26",
		team_squirtle([23, 24, 23, 22, 26])),
	("b23", "bulbasaur", "Bulbizarre : 20/20/20, Kadabra 17 (J16), Reptincel 22, Roucoups sans Tornade, Sabelette au lieu de Léviator",
		team_bulbasaur([20, 20, 20, 17, 22], pidgeotto=NO_GUST, third=("sandshrew", None))),
	("c31", "squirtle", "Carapuce : 22/24/22, Kadabra 20 (J16), Herbizarre 30 (Tranch'Herbe)",
		team_squirtle([22, 24, 22, 20, 30])),
	("c32", "squirtle", "Carapuce : 22/25/22, Kadabra 20 (J16), Herbizarre 26",
		team_squirtle([22, 25, 22, 20, 26])),
	("c50", "squirtle", "Carapuce : 22/25/22, Kadabra 18 (J16), Herbizarre 26",
		team_squirtle([22, 25, 22, 18, 26])),
	("c51", "squirtle", "Carapuce : 21/25/21, Kadabra 18 (J16), Herbizarre 26",
		team_squirtle([21, 25, 21, 18, 26])),
	("c52", "squirtle", "Carapuce : 20/25/20, Kadabra 18 (J16), Herbizarre 26",
		team_squirtle([20, 25, 20, 18, 26])),
]


def build(path):
	exits = load("tools/sim/tower_scenario_j18_exits.json")
	base = load("data/trainers/pokemon_tower.json")["rival_tower"]
	trainers = {}
	steps = [{"label": "Centre de Lavanville (départ)", "center": True}]
	variants = []
	for key, starter, label, team in SETTINGS:
		rival = copy.deepcopy(base)
		rival["team_by_starter"][starter] = team
		trainers["rival_tower_" + key] = rival
		steps.append({"label": "Centre (%s)" % key, "center": True, "optional": key})
		steps.append({"label": "Rival %s : %s" % (key, label), "trainer": "rival_tower_" + key,
			"optional": key})
		for player in ("attentif", "expert"):
			variants.append({"name": "%s, %s" % (key, player), "player": player,
				"center": True, "items": dict(ITEMS), "optional": [key]})
	trainers["rival_tower"] = copy.deepcopy(base)
	steps.append({"label": "Centre (retenu)", "center": True, "optional": "retenu"})
	steps.append({"label": "Rival retenu (data/)", "trainer": "rival_tower",
		"optional": "retenu"})
	for player in ("attentif", "expert"):
		variants.append({"name": "retenu, %s" % player, "player": player, "center": True,
			"items": dict(ITEMS), "optional": ["retenu"]})
	return {
		"version": 1,
		"title": "Rival n° 5 sur les sorties réelles du J18 (jalon 19 T21)",
		"description": "Jalon 19 T21 (docs/tech/jalon-19-equilibrage.md §8). Généré par "
			"tools/sim/gen_tower_t21.py. Le rival seul, au premier essai, équipe soignée ; "
			"équipes = sorties du J18 mesurées au T10. Cible (Q-T21-4) : 40 à 60 % pour "
			"l'attentif, jamais plus de 80 %.",
		"seeds": 200,
		"heal_at_start": True,
		"teams": exits["teams"],
		"tables": {},
		"trainers": trainers,
		"steps": steps,
		"variants": variants,
	}


def compact(text):
	"""Met sur une ligne chaque objet ou liste sans imbrication (un Pokémon, ses capacités)."""
	pattern = re.compile(r"[\[{]\n\t*[^\[\]{}]*?\n\t*[\]}]")
	def one_line(match):
		inner = re.sub(r"\n\t*", " ", match.group(0))
		return inner.replace("[ ", "[").replace(" ]", "]")
	previous = None
	while previous != text:
		previous = text
		text = pattern.sub(one_line, text)
	return text


def main():
	out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "tools/sim/tower_t21.json")
	with open(out, "w", encoding="utf-8") as f:
		f.write(compact(json.dumps(build(out), ensure_ascii=False, indent="\t")) + "\n")
	print(out)


if __name__ == "__main__":
	main()
