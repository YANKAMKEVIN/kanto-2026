#!/usr/bin/env python3
"""Génère les scénarios d'équilibrage du jalon 16 (T18) pour tools/simulate_mt_moon.gd.

Information pour Kevin : aucune donnée de jeu n'est changée. Les Dresseurs et les tables sont
recopiés de data/ (l'outil les relit de toute façon avec --donnees) ; les réglages « essayés »
n'existent que dans les scénarios produits ici.

  python3 tools/sim/gen_ss_anne_scenarios.py      # écrit les deux fichiers ci-dessous

- tools/sim/ss_anne_scenario.json : parcours de la fin du J13 (Ondine battue) jusqu'à Major Bob :
  Route 25 (directe ou tous les Dresseurs), Rocket d'Azuria, Route 5, Route 6, S.S. Anne,
  rival n° 4, Arène de Carmin (avec ou sans soin avant Major Bob).
- tools/sim/ss_anne_thresholds.json : un seul combat par partie (équipe soignée), échelle de
  niveaux par starter, contre le rival n° 4 et Major Bob tels que dans data/ et des réglages de
  comparaison.
"""
import copy
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def load(rel):
	with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
		return json.load(f)


def trainers(rel, ids=None):
	data = load(rel)
	out = {}
	for key, value in data.items():
		if key.startswith("_") or (ids is not None and key not in ids):
			continue
		out[key] = {k: v for k, v in value.items()
			if k in ("name", "ai", "switch", "can_lose", "heal_after", "gives_exp", "prize_money",
				"prize_per_level", "team", "team_by_starter")}
	return out


def table(rel, key):
	t = load(rel)[key]
	return {k: t[k] for k in ("maps", "terrain", "rate", "ramp", "slots") if k in t}


def mon(species, level, moves=None):
	m = {"species": species, "level": level}
	if moves:
		m["moves"] = moves
	return m


BUTTERFREE_MOVES = ["tackle", "string_shot", "harden", "confusion"]

# --- Parcours : équipes de fin du J13 (celles du scénario du J14 T21, route_25_scenario.json),
# plus leurs variantes « avec Sol » (Racaillou du Mont Sélénite ; Nidoking par la Pierre Lune pour
# l'équipe aux espèces de la partie de Kevin).
PATH_TEAMS = [
	("Reptincel 21, Férosinge 18, Roucool 17, Mystherbe 17", "charmander",
		[mon("charmeleon", 21), mon("mankey", 18), mon("pidgey", 17), mon("oddish", 17)]),
	("Sol : Reptincel 21, Férosinge 18, Roucool 17, Mystherbe 17, Racaillou 16", "charmander",
		[mon("charmeleon", 21), mon("mankey", 18), mon("pidgey", 17), mon("oddish", 17),
			mon("geodude", 16)]),
	("Kevin : Reptincel 21, Roucool 18, Nidorino 16, Rattata 16", "charmander",
		[mon("charmeleon", 21), mon("pidgey", 18), mon("nidorino", 16), mon("rattata", 16)]),
	("Sol, Kevin : Reptincel 21, Roucool 18, Nidoking 16, Rattata 16", "charmander",
		[mon("charmeleon", 21), mon("pidgey", 18), mon("nidoking", 16), mon("rattata", 16)]),
	("Herbizarre 20, Roucool 17, Papilusion 15", "bulbasaur",
		[mon("ivysaur", 20), mon("pidgey", 17), mon("butterfree", 15, BUTTERFREE_MOVES)]),
	("Sol : Herbizarre 20, Roucool 17, Papilusion 15, Racaillou 16", "bulbasaur",
		[mon("ivysaur", 20), mon("pidgey", 17), mon("butterfree", 15, BUTTERFREE_MOVES),
			mon("geodude", 16)]),
	("Carabaffe 21, Roucool 18, Papilusion 16", "squirtle",
		[mon("wartortle", 21), mon("pidgey", 18), mon("butterfree", 16, BUTTERFREE_MOVES)]),
	("Sol : Carabaffe 21, Roucool 18, Papilusion 16, Racaillou 16", "squirtle",
		[mon("wartortle", 21), mon("pidgey", 18), mon("butterfree", 16, BUTTERFREE_MOVES),
			mon("geodude", 16)]),
	("bas : Herbizarre 18, Roucool 14, Papilusion 12", "bulbasaur",
		[mon("ivysaur", 18), mon("pidgey", 14), mon("butterfree", 12, BUTTERFREE_MOVES)]),
	("bas : Carabaffe 20, Roucool 15, Papilusion 13", "squirtle",
		[mon("wartortle", 20), mon("pidgey", 15), mon("butterfree", 13, BUTTERFREE_MOVES)]),
	("bas : Reptincel 20, Férosinge 17, Roucool 16, Mystherbe 16", "charmander",
		[mon("charmeleon", 20), mon("mankey", 17), mon("pidgey", 16), mon("oddish", 16)]),
]

SS_ANNE_IDS = ["ss_anne_gentleman_armand", "ss_anne_sailor_erwan", "ss_anne_sailor_loic",
	"ss_anne_gentleman_emile", "ss_anne_sailor_yann", "ss_anne_sailor_remi", "ss_anne_lass_lena",
	"ss_anne_scout_basile", "ss_anne_gentleman_victor", "ss_anne_sailor_paul"]
ROUTE_6_OTHERS = ["route_6_camper_gabin", "route_6_scout_axel", "route_6_camper_mathis",
	"route_6_lass_manon", "route_6_scout_basile"]
GYM_IDS = ["vermilion_gym_gentleman_louis", "vermilion_gym_rocker_axel",
	"vermilion_gym_sailor_marc"]


def path_scenario():
	all_trainers = {}
	all_trainers.update(trainers("data/trainers/route_25.json"))
	all_trainers.update(trainers("data/trainers/cerulean_rocket.json"))
	all_trainers.update(trainers("data/trainers/route_6.json"))
	all_trainers.update(trainers("data/trainers/ss_anne.json"))
	all_trainers.update(trainers("data/trainers/rival.json", ["rival_ss_anne"]))
	all_trainers.update(trainers("data/trainers/vermilion_gym.json"))
	names = {k: v["name"] for k, v in all_trainers.items()}
	steps = [
		{"label": "Centre d'Azuria (départ)", "center": True},
		{"label": "J14 D1 Gamin Jules (inévitable)", "trainer": "route_25_youngster_jules"},
		{"label": "J14 D2 Montagnard Gaston (inévitable)", "trainer": "route_25_hiker_gaston"},
		{"label": "J14 Route 25 : H3 (4 cases obligatoires)", "wild": "route_25_grass",
			"cells": 4},
	]
	for tid in ["route_25_lass_zoe", "route_25_hiker_bernard", "route_25_jr_trainer_adam",
			"route_25_youngster_yanis"]:
		steps.append({"label": "J14 " + names[tid], "trainer": tid, "optional": "tous"})
	steps += [
		{"label": "J14 Route 25 : H1, H2, H4 (30 cases)", "wild": "route_25_grass", "cells": 30,
			"optional": "tous"},
		{"label": "Centre d'Azuria (retour de chez Léo)", "center": True},
		{"label": "J14 Sbire Rocket (Azuria)", "trainer": "cerulean_rocket"},
		{"label": "Centre d'Azuria (après le Rocket)", "center": True},
		{"label": "J15 Route 5 : herbes H1, H2 (20 cases)", "wild": "route_5_grass", "cells": 20,
			"optional": "tous"},
		{"label": "J15 Route 6 : Chloé (inévitable)", "trainer": "route_6_lass_chloe"},
	]
	for tid in ROUTE_6_OTHERS:
		steps.append({"label": "J15 Route 6 : " + names[tid], "trainer": tid, "optional": "tous"})
	steps += [
		{"label": "J15 Route 6 : herbes H1–H4 (30 cases)", "wild": "route_6_grass", "cells": 30,
			"optional": "tous"},
		{"label": "Centre de Carmin (avant le navire)", "center": True},
	]
	for i, tid in enumerate(SS_ANNE_IDS):
		steps.append({"label": "S.S. Anne : " + names[tid], "trainer": tid, "optional": "tous"})
		if i == 4:
			steps.append({"label": "Centre de Carmin (retour au quai, mi-navire)",
				"center": True, "optional": "retour"})
	steps.append({"label": "Centre de Carmin (retour au quai avant le rival)", "center": True,
		"optional": "retour"})
	# Pas de soin à bord : le rival suit les Dresseurs du navire (cas « équipe usée ») ; le cas
	# « soigné » est mesuré par les seuils (ss_anne_thresholds.json).
	steps += [
		{"label": "Rival n° 4 (couloir du capitaine)", "trainer": "rival_ss_anne"},
		{"label": "Centre de Carmin (avant l'Arène)", "center": True},
	]
	for tid in GYM_IDS:
		steps.append({"label": "Arène de Carmin : " + names[tid], "trainer": tid})
	steps += [
		{"label": "Centre de Carmin (entre les Dresseurs et Major Bob)", "center": True,
			"optional": "soin_arene"},
		{"label": "Major Bob (Arène de Carmin)", "trainer": "vermilion_gym_surge"},
	]
	items = {"potion": 3, "super_potion": 2, "antidote": 1, "paralyze_heal": 1}
	variants = []
	rows = []
	for path, groups in [("directe", []), ("tous les Dresseurs", ["tous", "retour"])]:
		for soin, sg in [("soin avant Major Bob", ["soin_arene"]), ("sans soin", [])]:
			for player in ["attentif", "expert", "naif"]:
				rows.append((path, groups, soin, sg, player))
	for player in ["attentif", "expert"]:
		rows.append(("tous, sans retour au quai", ["tous"], "soin avant Major Bob",
			["soin_arene"], player))
	# L'équipe garde son ordre (le Pokémon de type Sol, en dernier, attend Raichu).
	rows.append(("directe, ordre gardé", [], "soin avant Major Bob", ["soin_arene"], "attentif"))
	rows.append(("tous les Dresseurs, ordre gardé", ["tous", "retour"], "soin avant Major Bob",
		["soin_arene"], "attentif"))
	for path, groups, soin, sg, player in rows:
		v = {"name": "%s, %s, %s" % (path, soin, "naïf" if player == "naif" else player),
			"player": player, "center": True, "retries": 5, "optional": groups + sg}
		if "ordre gardé" in path:
			v["keep_order"] = True
		if player != "naif":
			v["items"] = dict(items)
		variants.append(v)
	return {
		"version": 1,
		"title": "Équilibrage du S.S. Anne, du rival n° 4 et de Major Bob (jalon 16 T18)",
		"description": "Jalon 16 T18 (dossier 19 §5, §9 ; plan jalon-16 T18). Information pour "
			"Kevin : aucune donnée de jeu n'est changée. Départ = équipes de fin du J13 du "
			"scénario du J14 T21 (Ondine battue), plus des variantes avec un Pokémon de type Sol "
			"(Racaillou, ou Nidoking par la Pierre Lune). Parcours : Route 25 (D1, D2, H3), "
			"Rocket, Route 6 (Chloé), Centre de Carmin, rival n° 4, Centre, Arène (Louis, Axel, "
			"Marc), [Centre], Major Bob. Groupe « tous » : D3–D6 et 30 cases de la Route 25, "
			"20 cases de la Route 5, les 5 autres Dresseurs et 30 cases de la Route 6, les 10 "
			"Dresseurs du navire (aucun soin à bord) ; « retour » : retour au Centre du quai après 5 Dresseurs du navire et avant le rival. « soin_arene » : Centre entre les "
			"Dresseurs de l'Arène et Major Bob. Objets (attentif, expert) : 3 Potions, 2 Super "
			"Potions, 1 Antidote, 1 Anti-Para. Généré par tools/sim/gen_ss_anne_scenarios.py.",
		"seeds": 1000,
		"heal_at_start": True,
		"teams": [{"name": n, "starter": s, "members": m} for n, s, m in PATH_TEAMS],
		"tables": {
			"route_25_grass": table("data/encounters/route_25.json", "route_25_grass"),
			"route_5_grass": table("data/encounters/route_5.json", "route_5_grass"),
			"route_6_grass": table("data/encounters/route_6.json", "route_6_grass"),
		},
		"trainers": all_trainers,
		"steps": steps,
		"variants": variants,
	}


# --- Seuils : échelle de niveaux (meneur N) par starter.
def ladder_teams():
	teams = []
	for n in [20, 22, 24, 26]:
		teams += [
			("Reptincel %d, Férosinge %d, Roucoups %d, Mystherbe %d" % (n, n - 3, n - 4, n - 4),
				"charmander",
				[mon("charmeleon", n), mon("mankey", n - 3), mon("pidgeotto", n - 4),
					mon("oddish", n - 4)]),
			("Kevin : Reptincel %d, Roucoups %d, Nidorino %d, Rattata %d" % (n, n - 3, n - 5,
				n - 5), "charmander",
				[mon("charmeleon", n), mon("pidgeotto", n - 3), mon("nidorino", n - 5),
					mon("rattata", n - 5)]),
			("Herbizarre %d, Roucoups %d, Papilusion %d" % (n, n - 3, n - 5), "bulbasaur",
				[mon("ivysaur", n), mon("pidgeotto", n - 3),
					mon("butterfree", n - 5, BUTTERFREE_MOVES)]),
			("Carabaffe %d, Roucoups %d, Papilusion %d" % (n, n - 3, n - 5), "squirtle",
				[mon("wartortle", n), mon("pidgeotto", n - 3),
					mon("butterfree", n - 5, BUTTERFREE_MOVES)]),
		]
	for n in [20, 22, 24]:
		teams += [
			("Sol : Reptincel %d, Férosinge %d, Roucoups %d, Racaillou %d" % (n, n - 3, n - 4,
				n - 4), "charmander",
				[mon("charmeleon", n), mon("mankey", n - 3), mon("pidgeotto", n - 4),
					mon("geodude", n - 4)]),
			("Sol, Kevin : Reptincel %d, Roucoups %d, Nidoking %d, Rattata %d" % (n, n - 3,
				n - 5, n - 5), "charmander",
				[mon("charmeleon", n), mon("pidgeotto", n - 3), mon("nidoking", n - 5),
					mon("rattata", n - 5)]),
			("Sol : Carabaffe %d, Roucoups %d, Papilusion %d, Racaillou %d" % (n, n - 3, n - 5,
				n - 4), "squirtle",
				[mon("wartortle", n), mon("pidgeotto", n - 3),
					mon("butterfree", n - 5, BUTTERFREE_MOVES), mon("geodude", n - 4)]),
			("Tunnel : Reptincel %d (CT28), Férosinge %d, Roucoups %d, Mystherbe %d" % (n, n - 3,
				n - 4, n - 4), "charmander",
				[mon("charmeleon", n, ["ember", "scratch", "leer", "dig"]), mon("mankey", n - 3),
					mon("pidgeotto", n - 4), mon("oddish", n - 4)]),
			("Sol : Herbizarre %d, Roucoups %d, Papilusion %d, Racaillou %d" % (n, n - 3, n - 5,
				n - 4), "bulbasaur",
				[mon("ivysaur", n), mon("pidgeotto", n - 3),
					mon("butterfree", n - 5, BUTTERFREE_MOVES), mon("geodude", n - 4)]),
			("Tunnel : Carabaffe %d (CT28), Roucoups %d, Papilusion %d" % (n, n - 3, n - 5),
				"squirtle",
				[mon("wartortle", n, ["water_gun", "bubble", "tail_whip", "dig"]),
					mon("pidgeotto", n - 3), mon("butterfree", n - 5, BUTTERFREE_MOVES)]),
			("Plante : Carabaffe %d, Roucoups %d, Papilusion %d, Mystherbe %d" % (n, n - 3,
				n - 5, n - 4), "squirtle",
				[mon("wartortle", n), mon("pidgeotto", n - 3),
					mon("butterfree", n - 5, BUTTERFREE_MOVES), mon("oddish", n - 4)]),
		]
	return teams


def with_levels(team, levels):
	out = copy.deepcopy(team)
	for i, lvl in enumerate(levels):
		if lvl is not None:
			out[i]["level"] = lvl
	return out


def thresholds_scenario():
	rival = trainers("data/trainers/rival.json", ["rival_ss_anne"])["rival_ss_anne"]
	surge = trainers("data/trainers/vermilion_gym.json",
		["vermilion_gym_surge"])["vermilion_gym_surge"]
	settings = {"rival_ss_anne": rival, "vermilion_gym_surge": surge}
	labels = {"rival_ss_anne": "Rival n° 4 (données : smart, switch)",
		"vermilion_gym_surge": "Major Bob (données : smart, switch)"}

	def rival_variant(key, label, levels=None, kadabra_moves=None, only=None):
		r = copy.deepcopy(rival)
		for st, team in r["team_by_starter"].items():
			if only and st not in only:
				continue
			if levels:
				r["team_by_starter"][st] = with_levels(team, levels)
			if kadabra_moves:
				r["team_by_starter"][st][2]["moves"] = kadabra_moves
		settings[key] = r
		labels[key] = label

	rival_variant("rival_a_18_15_17_19", "Rival n° 4 (a) : 18 / 15 / 17 / 19 (− 1 partout)",
		[18, 15, 17, 19])
	rival_variant("rival_b_17_15_16_18", "Rival n° 4 (b) : 17 / 15 / 16 / 18",
		[17, 15, 16, 18])
	rival_variant("rival_f_16_14_15_17", "Rival n° 4 (f) : 16 / 14 / 15 / 17 (− 3 partout)",
		[16, 14, 15, 17])
	rival_variant("rival_c_kadabra_16", "Rival n° 4 (c) : Kadabra N16, le reste inchangé",
		[None, None, 16, None])
	rival_variant("rival_d_sans_rafale", "Rival n° 4 (d) : Kadabra sans Rafale Psy "
		"(Choc Mental, Téléport)", kadabra_moves=["confusion", "teleport"])
	rival_variant("rival_h_bulbi_16_14_15_16", "Rival n° 4 (h), contre Bulbizarre seul : "
		"Roucoups 16, Rattatac 14, Kadabra 15, Reptincel 16", [16, 14, 15, 16],
		only=["bulbasaur"])
	rival_variant("rival_i_bulbi_14_12_13_15", "Rival n° 4 (i), contre Bulbizarre seul : "
		"Roucoups 14, Rattatac 12, Kadabra 13, Reptincel 15", [14, 12, 13, 15],
		only=["bulbasaur"])
	rival_variant("rival_e_starter_18", "Rival n° 4 (e) : starter évolué N18",
		[None, None, None, 18])
	r = copy.deepcopy(rival)
	r["switch"] = False
	settings["rival_sans_switch"] = r
	labels["rival_sans_switch"] = "Rival n° 4 sans changement"

	def surge_variant(key, label, levels=None, raichu_moves=None, ai=None, switch=None):
		s = copy.deepcopy(surge)
		if levels:
			s["team"] = with_levels(s["team"], levels)
		if raichu_moves:
			s["team"][2]["moves"] = raichu_moves
		if ai:
			s["ai"] = ai
		if switch is not None:
			s["switch"] = switch
		settings[key] = s
		labels[key] = label

	surge_variant("surge_sans_switch", "Major Bob sans changement", switch=False)
	surge_variant("surge_a_raichu_22", "Major Bob (a) : Raichu N22", [None, None, 22])
	surge_variant("surge_b_raichu_21", "Major Bob (b) : Voltorbe 20, Pikachu 18, Raichu 21",
		[20, None, 21])
	surge_variant("surge_c_sans_tonnerre", "Major Bob (c) : Raichu N24 sans Tonnerre "
		"(Éclair, Cage-Éclair, Vive-Attaque)",
		raichu_moves=["thunder_shock", "thunder_wave", "quick_attack"])
	surge_variant("surge_d_vive_attaque", "Major Bob (d) : Raichu N24 avec Vive-Attaque "
		"(Éclair, Cage-Éclair, Tonnerre, Vive-Attaque)",
		raichu_moves=["thunder_shock", "thunder_wave", "thunderbolt", "quick_attack"])
	surge_variant("surge_f_19_18_20", "Major Bob (f) : Voltorbe 19, Pikachu 18, Raichu 20",
		[19, None, 20])
	surge_variant("surge_g_21_sans_tonnerre", "Major Bob (g) : Voltorbe 20, Pikachu 18, "
		"Raichu 21 sans Tonnerre (Éclair, Cage-Éclair, Vive-Attaque)", [20, None, 21],
		raichu_moves=["thunder_shock", "thunder_wave", "quick_attack"])
	surge_variant("surge_e_raichu_26", "Major Bob (e) : Raichu N26", [None, None, 26])
	steps = [{"label": labels[k], "trainer": k, "optional": k} for k in settings]
	variants = []
	for k in settings:
		for player in ["attentif", "expert", "naif"]:
			pname = "naïf" if player == "naif" else player
			v = {"name": "%s, %s : %s" % (pname, "sans objet" if player == "naif"
				else "3 Potions", k), "player": player, "center": True, "optional": [k]}
			if player != "naif":
				v["items"] = {"potion": 3}
			variants.append(v)
		# Sac du parcours (Super Potions de la Boutique de Carmin et du navire, Anti-Para).
		if k in ("rival_ss_anne", "vermilion_gym_surge", "rival_b_17_15_16_18",
				"rival_f_16_14_15_17", "rival_h_bulbi_16_14_15_16", "rival_i_bulbi_14_12_13_15",
				"surge_g_21_sans_tonnerre", "surge_b_raichu_21", "surge_c_sans_tonnerre"):
			for player in ["attentif", "expert"]:
				variants.append({"name": "%s, sac de Carmin : %s" % (player, k),
					"player": player, "center": True, "optional": [k],
					"items": {"potion": 3, "super_potion": 2, "paralyze_heal": 1}})
		# Joueur qui garde l'ordre de son équipe (le Pokémon de type Sol, en dernier, attend
		# Raichu) : le « meilleur en tête » de l'attentif l'envoie sinon contre Voltorbe.
		if k.startswith("surge") or k == "vermilion_gym_surge":
			for player in ["attentif", "expert"]:
				variants.append({"name": "%s, 3 Potions, ordre gardé : %s" % (player, k),
					"player": player, "center": True, "optional": [k], "keep_order": True,
					"items": {"potion": 3}})
	return {
		"version": 1,
		"title": "Seuils du rival n° 4 et de Major Bob (jalon 16 T18)",
		"description": "Jalon 16 T18 : un combat par partie (équipe soignée ; attentif et "
			"expert avec 3 Potions, naïf sans objet), sans reprise : taux de victoire au premier "
			"essai p (tentatives ≈ 1/p). Échelle de niveaux par starter (meneur N20 à N26) contre "
			"le rival n° 4 et Major Bob tels que dans data/ et contre des réglages de comparaison. "
			"Équipes « Sol » : Racaillou ou Nidoking ; « Tunnel » : Reptincel avec la CT28 ; « Plante » : Carabaffe avec un "
			"Mystherbe. Variantes « ordre gardé » : l'équipe part dans son ordre (Sol en dernier). "
			"Information pour Kevin : aucune donnée de jeu n'est changée. Généré par "
			"tools/sim/gen_ss_anne_scenarios.py.",
		"seeds": 1000,
		"heal_at_start": True,
		"teams": [{"name": n, "starter": s, "members": m} for n, s, m in ladder_teams()],
		"tables": {},
		"trainers": settings,
		"steps": steps,
		"variants": variants,
	}


def write(rel, data):
	path = os.path.join(ROOT, rel)
	with open(path, "w", encoding="utf-8") as f:
		json.dump(data, f, ensure_ascii=False, indent="\t")
		f.write("\n")
	print("écrit :", rel)


if __name__ == "__main__":
	write("tools/sim/ss_anne_scenario.json", path_scenario())
	write("tools/sim/ss_anne_thresholds.json", thresholds_scenario())
