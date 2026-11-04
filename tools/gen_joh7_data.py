#!/usr/bin/env python3
"""Données de jeu du jalon JOH7 (Routes 40 et 41, Îles Tourbillon), générées depuis les grilles.

Lit les positions de `tools/plans/route_40.txt`, `route_41.txt`, `whirl_islands_1f.txt`,
`whirl_islands_b1f.txt`, `whirl_islands_b2f.txt` (grilles validées le 2026-11-03, elles font foi)
et écrit, d'après `docs/design/dossier-joh-08-iles-tourbillon.md` (textes M-1 à M-34 validés le
2026-11-02, Dresseurs §6, objets §7, rencontres §5) et le plan `docs/tech/jalon-joh7.md` §2 :
  - `data/npcs/<carte>.json` (Dresseurs, objets visibles, Suicune, Lugia, Lokhlass) ;
  - `data/trainers/joh7.json` ;
  - `data/encounters/<carte>.json` (tables par moment), tables de pêche en fin de
    `data/fishing/water_rod.json` ;
  - `data/dialogues/joh7_whirl.json`, `data/cutscenes/joh7_whirl.json` (préfixe `joh7_` : écartés des grands
    registres, vérifiés par `tests/unit/test_joh7_data.gd`).
Oliville (marin de la plage, enfant, Orme au Centre) : entrées ajoutées aux fichiers du JOH1
(`olivine_city.json`, `olivine_house_2.json`, `olivine_center.json`) s'ils existent.

Usage : python3 -I tools/gen_joh7_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

MAPS = [("route_40", "route_40"), ("route_41", "route_41"),
	("whirl_islands_1f", "whirl_islands_1f"), ("whirl_islands_b1f", "whirl_islands_b1f"),
	("whirl_islands_b2f", "whirl_islands_b2f")]

NARRATION = None

# Dresseurs (dossier §6) : position de la grille → (identifiant, nom, prix par niveau, équipe,
# sprite, classe imposée ou None). Prix par niveau [D] : Nageur 5, Pêcheur 35, Sbire 30.
TRAINERS = {
	("route_40", "yanis"): ("route_40_swimmer_yanis", "Nageur Yanis", 5,
		[("tentacruel", 50), ("staryu", 49)], "swimmer_water", None),
	("route_40", "elodie"): ("route_40_swimmer_elodie", "Nageuse Élodie", 5,
		[("azumarill", 51)], "swimmer_f_water", None),
	("route_40", "marius"): ("route_40_swimmer_marius", "Nageur Marius", 5,
		[("kingler", 50), ("seadra", 50)], "swimmer_water", None),
	("route_41", "lea"): ("route_41_swimmer_lea", "Nageuse Léa", 5,
		[("dewgong", 52), ("starmie", 52)], "swimmer_f_water", None),
	("route_41", "gabin"): ("route_41_swimmer_gabin", "Nageur Gabin", 5,
		[("tentacruel", 51), ("gyarados", 53)], "swimmer_water", None),
	("route_41", "noe"): ("route_41_fisher_noe", "Pêcheur Noé", 35,
		[("seadra", 52), ("seaking", 52)], "fisher_fuchsia", None),
	("whirl_islands_1f", "sbire_t"): ("whirl_islands_grunt_t", "Sbire Rocket", 30,
		[("muk", 58), ("arbok", 58)], "rocket_grunt_m", None),
	("whirl_islands_1f", "sbire_u"): ("whirl_islands_grunt_u", "Sbire Rocket", 30,
		[("houndoom", 59), ("golbat", 58)], "rocket_grunt_f", "sbire_rocket_f"),
}
SURF_TRAINERS = {"swimmer_water", "swimmer_f_water"}
# Répliques (M-5, M-6, M-10) : avant · défaite · après.
TRAINER_LINES = {
	"route_40_swimmer_yanis": ("La mer est mon terrain !", "J'ai bu la tasse.",
		"Les îles sont plus au sud."),
	"route_40_swimmer_elodie": ("Tu nages jusqu'aux îles ? Moi aussi !",
		"Bon, vas-y la première. Enfin, le premier.", "Fais attention aux courants."),
	"route_40_swimmer_marius": ("Mes Pokémon pincent fort !", "Ils ont lâché prise.",
		"Suis les chenaux, pas les tourbillons."),
	"route_41_swimmer_lea": ("Si tu veux passer, il faut nager plus vite que moi !",
		"Tu nages vraiment vite.", "J'ai vu un Pokémon bleu courir sur l'eau, ce matin."),
	"route_41_swimmer_gabin": ("Mon Léviator n'a peur de rien !", "Si, de toi.",
		"Les îles grondent la nuit."),
	"route_41_fisher_noe": ("Ce chenal est à moi. Un combat pour le droit de passage !",
		"Passe, passe.", "Au fond des îles, il y a quelque chose d'immense. Mon grand-père le disait."),
	"whirl_islands_grunt_t": ("Cenere a dit : personne ne descend !",
		"Elle avait tout calculé, sauf toi.", "Elle est déjà en bas."),
	"whirl_islands_grunt_u": ("Pour Dante ! Tu ne passes pas !", "… Pour Dante…",
		"Le bleu court plus vite que nous. Mais Cenere a un plan."),
}

# Cenere (§6, §11 ; M-14 à M-17) : grand combat, IA « smart », un changement [D].
CENERE_ID = "whirl_islands_cenere"
CENERE_TEAM = [("weezing", 62), ("wobbuffet", 62), ("noctowl", 63), ("dewgong", 63),
	("sneasel", 64)]
CENERE_SPRITE = "rocket_grunt_f"  # [D] : sprite de Cenere (JOH5) repris à sa fusion

# Textes des panneaux et examens (carte, position) → (orateur, pages).
TEXTS = {
	("route_40", "panneau"): (NARRATION, ["ROUTE 40", "Oliville — Îles Tourbillon"]),
	("route_41", "panneau_route"): (NARRATION, ["ROUTE 41",
		"Attention : tourbillons. Suivez les chenaux."]),
	("route_41", "panneau_iles"): (NARRATION, ["ÎLES TOURBILLON",
		"Lieu sacré. On dit qu'un gardien dort sous la mer."]),
	("route_41", "tourbillon"): (NARRATION, ["L'eau tourne violemment.",
		"Impossible de passer par là."]),
	("whirl_islands_b2f", "cascade"): (NARRATION, ["L'eau tombe de très haut.",
		"Derrière, on devine une petite grotte."]),
}
# Identifiants de dialogue des panneaux et examens.
TEXT_IDS = {
	("route_40", "panneau"): "route_40_sign",
	("route_41", "panneau_route"): "route_41_sign",
	("route_41", "panneau_iles"): "whirl_islands_sign",
	("route_41", "tourbillon"): "whirlpool_examine",
	("whirl_islands_b2f", "cascade"): "whirl_islands_waterfall",
}

# Objets visibles (dossier §7) : position → identifiant de scène (drapeau `got_<id>`).
ITEM_IDS = {
	("route_40", "ultra_balls"): "route_40_item_1",
	("route_41", "max_potion"): "route_41_item_1",
	("whirl_islands_1f", "rappel_max"): "whirl_islands_1f_item_1",
	("whirl_islands_b1f", "ecaille_draco"): "whirl_islands_b1f_dragon_scale",
	("whirl_islands_b1f", "pp_max"): "whirl_islands_b1f_item_1",
	("whirl_islands_b2f", "super_bonbons"): "whirl_islands_b2f_item_1",
}

# Rencontres (dossier §5, plan §2.3) : carte → [(table, terrain, moments ou None, taux,
# niveaux, créneaux)].
ROUTE_WATER = [("tentacool", 40), ("tentacruel", 25), ("staryu", 15), ("shellder", 10),
	("krabby", 10)]
ENCOUNTERS = {
	"route_40": [("route_40_water", "water", None, 5, (42, 48), ROUTE_WATER)],
	"route_41": [("route_41_water", "water", None, 5, (42, 48), ROUTE_WATER)],
	"whirl_islands_1f": [
		("whirl_islands_1f_rubble_day", "rubble", ["morning", "day"], 20, (46, 50),
			[("golbat", 30), ("graveler", 20), ("geodude", 10), ("kingler", 20), ("dewgong", 20)]),
		("whirl_islands_1f_rubble_night", "rubble", ["night"], 20, (46, 50),
			[("golbat", 40), ("graveler", 20), ("dewgong", 20), ("wobbuffet", 5), ("kingler", 15)]),
	],
	"whirl_islands_b1f": [
		("whirl_islands_b1f_rubble", "rubble", None, 20, (48, 52),
			[("golbat", 35), ("dewgong", 25), ("cloyster", 20), ("kingler", 15), ("wobbuffet", 5)]),
		("whirl_islands_b1f_water", "water", None, 8, (48, 52),
			[("tentacruel", 30), ("dewgong", 30), ("seadra", 25), ("seel", 15)]),
	],
}
# Pêche (dossier §5) : Canne et Super Canne sur les Routes 40 et 41 ; Méga Canne : table par
# défaut [D].
FISHING = {
	"joh7_old_rod": ("old_rod", 100, [("magikarp", 5, 1), ("tentacool", 5, 1)]),
	"joh7_good_rod": ("good_rod", 50, [("krabby", 10, 1), ("horsea", 10, 1), ("staryu", 10, 1)]),
}

# Textes du B1F, du B2F et d'Oliville (M-11 à M-34).
DIALOGUES = {
	"whirl_current": (NARRATION, ["Le courant emporte {player} !"]),
	"whirl_suicune_seen": (NARRATION, ["Un Pokémon bleu se tient sur le rocher.",
		"Il regarde {player}, sans bouger."]),
	"whirl_cenere_arrival": ("Cenere", ["Tu es là avant moi. Encore.",
		"Deux erreurs de calcul. Ça commence à faire beaucoup."]),
	"whirl_cenere_before": ("Cenere", ["Cette fois, j'ai étudié ton équipe. Chaque Pokémon. Chaque attaque.",
		"Recule, ou je te range dans mes statistiques."]),
	"whirl_cenere_defeated": ("Cenere", ["… Je ne comprends pas.", "Mes calculs étaient justes."]),
	"whirl_cenere_after": ("Cenere", ["Garde ton Suicune. Il ne compte plus.",
		"Le maître a déjà le troisième. Le rouge.", "Il monte à la Tour Carillon.",
		"Quand Ho-Oh descendra, tu comprendras que tu as perdu depuis le début."]),
	"whirl_cenere_leaves": (NARRATION, ["Cenere s'en va…"]),
	"whirl_suicune_leap_1": (NARRATION, ["Suicune saute de son rocher."]),
	"whirl_suicune_leap_2": (NARRATION, ["Il s'approche de {player}…",
		"Il veut se mesurer à {player} !"]),
	"whirl_suicune_after": (NARRATION, ["L'eau de la grotte devient plus claire."]),
	"whirl_lugia_rise_1": (NARRATION, ["Le bassin est immobile.", "…"]),
	"whirl_lugia_rise_2": (NARRATION, ["Une ombre immense passe sous l'eau.",
		"La même que dans la grotte de Bourg Palette !"]),
	"whirl_lugia_rise_3": (NARRATION, ["L'eau se soulève.", "Lugia surgit des profondeurs !"]),
	"whirl_lugia_gone": (NARRATION, ["Lugia replonge dans le bassin et disparaît."]),
	"whirl_b2f_heart": (NARRATION, ["Le cœur des îles, où la mer tombe en cascade."]),
	"whirl_dragon_scale_found": (NARRATION, ["{player} trouve une Écaille Draco !",
		"Une écaille dure et brillante."]),
}
M13 = ["Suicune observe {player}.", "On dirait qu'il attend quelque chose."]
M20 = ["Un courant violent remonte de l'escalier.", "Impossible de descendre."]
M21 = ["Le courant s'est apaisé.", "On entend une cascade, tout en bas."]
M26 = ["Un Lokhlass nage dans la crique.", "Il chante doucement."]
M27 = ["La crique est calme.", "Il paraît qu'un Lokhlass y vient, certains jours."]
M33 = ["Une petite crique, à l'abri des courants."]
M1 = ["Au large, il y a des îles entourées de tourbillons.", "Personne n'y va jamais.",
	"Mais hier, un bateau noir s'est approché."]
M29 = ["Les tourbillons se sont calmés d'un coup, cette nuit.",
	"Comme si quelque chose, au fond, s'était enfin reposé."]
M30 = ["Mon papa dit que tu as vu le Pokémon le plus fort de la mer.", "C'est vrai ?"]
M31 = ["{player} ! Les sages de Rosalia m'ont appelé.",
	"Un homme a forcé la porte de la Tour Carillon cette nuit.",
	"Il avait un Pokémon rouge, enfermé dans une cage de feu.",
	"Les sages t'attendent. Ils t'ouvriront la tour."]
M32 = ["Raikou, Suicune… Et maintenant Entei.", "Dante veut les trois pour faire descendre Ho-Oh.",
	"Il ne lui en manque plus qu'un. Fais vite."]
OTHER_DAYS = ["monday", "tuesday", "wednesday", "thursday", "saturday", "sunday"]

# Oliville : PNJ ajoutés aux fichiers du JOH1. Orme au rez-de-chaussée du Centre [D].
OLIVINE_SAILOR_CELL = None  # lu dans tools/plans/oliville.txt (« marin_plage »)
ORME_CENTER_CELL = [3, 5]   # [D] : case libre du Centre d'Oliville, au sud-ouest du comptoir

# Début du bloc du JOH7 dans `water_rod.json` (sa première table) : relance idempotente.
FISHING_MARK = '\t"joh7_old_rod": {'

# Ombre de Lugia (B2F, `build_joh7_maps.gd`) : de (7, 11) à (17, 11).
SHADOW_OFFSET = [10, 0]

CELL_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?,(\d+)(?:\.\.(\d+))?$")


def read_plan(name):
	"""Positions de la grille : id → (type, cases, attributs, commentaire)."""
	positions = {}
	section = None
	with open(os.path.join(PLANS, name + ".txt"), encoding="utf-8") as handle:
		for raw in handle:
			line = raw.rstrip("\n")
			if line.startswith("POSITIONS"):
				section = "pos"
				continue
			if line.startswith("FIN"):
				section = None
				continue
			if section != "pos" or not line.strip() or line.startswith("#"):
				continue
			body, _, comment = line.partition("#")
			words = body.split()
			ident, kind, cells_text = words[0], words[1], words[2]
			attrs = {}
			for word in words[4:]:
				if "=" in word:
					key, _, value = word.partition("=")
					attrs[key] = value
			positions[ident] = (kind, parse_cells(cells_text), attrs, comment.strip())
	return positions


def parse_cells(text):
	cells = []
	for group in text.split(";"):
		match = CELL_RE.match(group)
		if not match:
			raise ValueError("cases illisibles : " + text)
		x0, x1, y0, y1 = match.groups()
		for y in range(int(y0), int(y1 or y0) + 1):
			for x in range(int(x0), int(x1 or x0) + 1):
				cells.append((x, y))
	return cells


def write_json(path, data):
	text = json.dumps(data, ensure_ascii=False, indent="\t") + "\n"
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(text)
	print("écrit :", os.path.relpath(path, ROOT))


def dialogue(speaker, pages):
	entry = {}
	if speaker:
		entry["speaker"] = speaker
	else:
		entry["narration"] = True
	entry["pages"] = pages
	return entry


def item_scene(ident, item, count, flag, extra=None):
	steps = [{"despawn": ident}, {"give": item, "count": count, "found": True}, {"set": [flag]}]
	if extra:
		steps.append({"dialogue": extra})
	return {"variants": [{"unless": [flag], "steps": steps}]}


def cenere_scene():
	"""M-14 à M-17 : Cenere sort de la galerie (14, 1), vient au joueur, combat obligatoire ;
	battue, elle repart par la galerie ; la suite (Suicune) est enchaînée par « next ». Défaite
	du joueur : réveil au Centre, la scène se rejoue."""
	won = ["johto_cenere_defeated_2"]
	return {"next": "whirl_suicune_battle", "variants": [{"unless": won, "steps": [
		{"spawn": "cenere", "sprite": CENERE_SPRITE, "cell": [14, 1], "facing": "down"},
		{"emote": "cenere", "kind": "exclamation"},
		{"move": "cenere", "to": {"near": "player", "offsets": [[1, 0], [-1, 0], [0, -1]]}},
		{"face": "cenere", "to": "player"},
		{"face": "player", "to": "cenere"},
		{"dialogue": "whirl_cenere_arrival"},
		{"dialogue": "whirl_cenere_before"},
		{"battle": CENERE_ID, "win": won},
		{"dialogue": "whirl_cenere_defeated", "if": won},
		{"dialogue": "whirl_cenere_after", "if": won},
		{"dialogue": "whirl_cenere_leaves", "if": won},
		{"move": "cenere", "to": [14, 1], "if": won},
		{"despawn": "cenere", "if": won},
		{"despawn": "cenere", "unless": won},
		{"wake_up": True, "unless": won},
	]}]}


def legendary_battle(species, level, actor, resolved, caught):
	return {"wild_battle": species, "level": level, "intro": "legendary", "actor": actor,
		"static": {"done": resolved, "caught": caught}, "flee": [resolved, FLED]}


# Fuite (QA A17) : la rencontre fixe ne retire son acteur qu'après une capture ou un K.O. ; une
# fuite lève ce drapeau passager, l'acteur est retiré à la main, puis le drapeau est baissé.
FLED = "johto_whirl_fled"


def flee_cleanup(actor):
	return [{"despawn": actor, "if": [FLED]}, {"unset": [FLED], "if": [FLED]}]


def suicune_scene():
	"""M-18, combat (niv. 60, capturable), M-19 ; `johto_suicune_done` (progression) posé quand la
	rencontre est consommée (capture, K.O. ou fuite)."""
	resolved = "johto_suicune_resolved"
	return {"variants": [{"if": ["johto_cenere_defeated_2"], "unless": ["johto_suicune_done"],
		"steps": [
			{"dialogue": "whirl_suicune_leap_1"},
			{"lean": "suicune", "to": "player"},
			{"dialogue": "whirl_suicune_leap_2"},
			legendary_battle("suicune", 60, "suicune", resolved, "johto_suicune_caught"),
			*flee_cleanup("suicune"),
			{"dialogue": "whirl_suicune_after", "if": [resolved]},
			{"set": ["johto_suicune_done"], "if": [resolved]},
		]}]}


def lugia_rise_scene():
	"""M-23 (l'ombre de la grotte marine passe sous l'eau), M-24 : Lugia émerge au centre du
	bassin ; on le combat en l'abordant depuis l'eau (grille [D])."""
	return {"variants": [{"unless": ["johto_lugia_emerged"], "steps": [
		{"wait": 0.3},
		{"react": "player"},
		{"dialogue": "whirl_lugia_rise_1"},
		# [D] Le joueur glisse de 4 cases vers le centre du bassin : l'ombre (rangée 11) et Lugia
		# (12, 9) restent dans le cadre (≈ 5 rangées visibles au-dessus du joueur).
		{"move": "player", "path": ["up", "up", "up", "up"]},
		{"set": ["johto_whirl_lugia_passing"]},
		{"animate": "LugiaShadow", "offset": SHADOW_OFFSET, "duration": 4.0, "fade": True},
		{"unset": ["johto_whirl_lugia_passing"]},
		{"dialogue": "whirl_lugia_rise_2"},
		{"flash": 1},
		{"spawn": "lugia", "sprite": "pokemon/lugia", "cell": [12, 9], "facing": "down",
			"dialogue": "whirl_lugia", "verb": "observe", "turn_to_player": False},
		{"set": ["johto_lugia_emerged"]},
		{"dialogue": "whirl_lugia_rise_3"},
	]}]}


def lugia_scene():
	resolved = "johto_lugia_resolved"
	return {"variants": [{"unless": [resolved], "steps": [
		legendary_battle("lugia", 65, "lugia", resolved, "johto_lugia_caught"),
		*flee_cleanup("lugia"),
		{"dialogue": "whirl_lugia_gone", "if": [resolved], "unless": ["johto_lugia_caught"]},
		{"set": ["johto_lugia_done"], "if": [resolved]},
	]}]}


def lapras_scene():
	"""JH-50 : le Lokhlass du vendredi (niv. 50) ; K.O. ou fuite : absent jusqu'à la remise à
	zéro hebdomadaire de `week_friday_lapras` (`data/story/weekly_flags.json`)."""
	return {"variants": [{"unless": ["week_friday_lapras", "johto_lapras_caught"], "steps": [
		{"wild_battle": "lapras", "level": 50, "actor": "lokhlass",
			"static": {"done": "week_friday_lapras", "caught": "johto_lapras_caught"},
			"flee": ["week_friday_lapras", FLED]},
		*flee_cleanup("lokhlass"),
	]}]}


def main():
	trainers = {}
	dialogues = {}
	cutscenes = {}
	for plan, map_id in MAPS:
		positions = read_plan(plan)
		npcs = {}
		for ident, (kind, cells, attrs, comment) in positions.items():
			key = (map_id, ident)
			cell = list(cells[0])
			if kind == "dresseur":
				tid, name, prize, team, sprite, battle_class = TRAINERS[key]
				before, defeated, after = TRAINER_LINES[tid]
				speaker = name
				dialogues[tid + "_before"] = dialogue(speaker, [before])
				dialogues[tid + "_defeated"] = dialogue(speaker, [defeated])
				dialogues[tid + "_after"] = dialogue(speaker, [after])
				entry = {"name": name}
				if battle_class:
					entry["class"] = battle_class
				entry.update({"ai": "random", "can_lose": False, "heal_after": False,
					"gives_exp": True, "prize_money": 0, "prize_per_level": prize,
					"team": [{"species": s, "level": lv} for s, lv in team]})
				trainers[tid] = entry
				npc = {"cell": cell, "facing": attrs["facing"], "sprite": sprite,
					"dialogue": tid + "_after",
					"trainer": {"id": tid, "sight": int(attrs["sight"]), "before": tid + "_before",
						"defeated": tid + "_defeated"}}
				if sprite in SURF_TRAINERS:
					npc["move_mode"] = "surf"
				npcs[ident] = npc
			elif kind in ("panneau", "examen") and key in TEXTS:
				dialogues[TEXT_IDS[key]] = dialogue(*TEXTS[key])
			elif kind == "objet_visible":
				scene_id = ITEM_IDS[key]
				flag = "got_" + scene_id
				npcs[scene_id] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": scene_id, "verb": "take", "turn_to_player": False, "unless": [flag]}
				dialogues[scene_id] = {"cutscene": scene_id}
				extra = "whirl_dragon_scale_found" if attrs["item"] == "dragon_scale" else None
				cutscenes[scene_id] = item_scene(scene_id, attrs["item"],
					int(attrs.get("quantite", 1)), flag, extra)
			elif kind == "pokemon":
				species = attrs["espece"]
				if species == "suicune":
					npcs["suicune"] = {"cell": cell, "facing": "down", "sprite": "pokemon/suicune",
						"dialogue": "whirl_suicune", "verb": "observe", "turn_to_player": False,
						"unless": ["johto_suicune_done", "johto_suicune_resolved"]}
				elif species == "lugia":
					npcs["lugia"] = {"cell": cell, "facing": "down", "sprite": "pokemon/lugia",
						"dialogue": "whirl_lugia", "verb": "observe", "turn_to_player": False,
						"if": ["johto_lugia_emerged"], "unless": ["johto_lugia_resolved"]}
				elif species == "lapras":
					npcs["lokhlass"] = {"cell": cell, "facing": "left", "sprite": "pokemon/lapras",
						"dialogue": "whirl_lapras", "verb": "observe", "turn_to_player": False,
						"if_weekday": ["friday"],
						"unless": ["week_friday_lapras", "johto_lapras_caught"]}
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
		if map_id in ENCOUNTERS:
			tables = {}
			for table_id, terrain, periods, rate, levels, slots in ENCOUNTERS[map_id]:
				table = {"maps": [map_id], "terrain": terrain}
				if periods:
					table["period"] = periods
				table["rate"] = rate
				if terrain == "rubble":
					table["ramp"] = {"from_step": 15, "max_steps": 20}
				table["slots"] = [{"species": s, "levels": list(levels), "weight": w}
					for s, w in slots]
				tables[table_id] = table
			write_json(os.path.join(DATA, "encounters", map_id + ".json"), tables)

	# Cenere.
	trainers[CENERE_ID] = {"name": "Cenere", "class": "sbire_rocket_f", "ai": "smart",
		"can_lose": False, "heal_after": False, "gives_exp": True, "prize_money": 0,
		"prize_per_level": 60, "start_message": False, "end_message": False, "switch": True,
		"team": [{"species": s, "level": lv} for s, lv in CENERE_TEAM]}

	for ident, (speaker, pages) in DIALOGUES.items():
		dialogues[ident] = dialogue(speaker, pages)
	# Suicune : M-13 avant Cenere ; ensuite, le combat.
	dialogues["whirl_suicune"] = {"narration": True, "variants": [
		{"unless": ["johto_cenere_defeated_2"], "pages": M13},
		{"if": ["johto_cenere_defeated_2"], "cutscene": "whirl_suicune_battle"},
	]}
	dialogues["whirl_lugia"] = {"narration": True, "variants": [
		{"cutscene": "whirl_lugia_battle"}]}
	dialogues["whirl_lapras"] = {"narration": True, "variants": [
		{"cutscene": "whirl_lapras_battle"}]}
	# Courant violent de l'escalier du B2F : M-20 avant Suicune, M-21 une fois après (scène).
	dialogues["whirl_b2f_current_strong"] = dialogue(NARRATION, M20)
	dialogues["whirl_b2f_current_calm"] = dialogue(NARRATION, M21)
	# Examen du courant violent lui-même (cases (2, 4..5)) : M-20 avant Suicune, M-21 après.
	dialogues["whirl_b2f_current_examine"] = {"narration": True, "variants": [
		{"unless": ["johto_suicune_done"], "pages": M20},
		{"pages": M21},
	]}
	# Crique (M-26, M-27, M-33) : capturé → M-33 ; vendredi et Lokhlass là → M-26 ; autre jour →
	# M-27 ; vendredi après un K.O. → M-33 [D].
	dialogues["whirl_cove"] = {"narration": True, "variants": [
		{"if": ["johto_lapras_caught"], "pages": M33},
		{"if_weekday": ["friday"], "unless": ["week_friday_lapras"], "pages": M26},
		{"if_weekday": OTHER_DAYS, "pages": M27},
		{"pages": M33},
	]}
	# Oliville (M-1, M-29, M-30, M-31, M-32).
	dialogues["olivine_beach_sailor"] = {"speaker": "Marin", "variants": [
		{"if": ["johto_lugia_done"], "pages": M29},
		{"pages": M1},
	]}
	dialogues["olivine_orme_bell_tower"] = {"speaker": "Prof. Orme", "variants": [
		{"unless": ["johto_bell_tower_clue"], "set": ["johto_bell_tower_clue"], "pages": M31},
		{"pages": M32},
	]}
	dialogues["olivine_kid_sea"] = {"speaker": "Enfant", "pages": M30}

	cutscenes["whirl_suicune_seen"] = {"variants": [{"unless": ["johto_suicune_seen"], "steps": [
		{"set": ["johto_suicune_seen"]},
		{"face": "player", "to": "suicune"},
		{"dialogue": "whirl_suicune_seen"},
	]}]}
	# M-22 (« description de zone » du B2F) : narration au premier pas après l'échelle [D] (le B2F
	# fait partie de la zone « whirl_islands », décrite par M-9).
	cutscenes["whirl_b2f_heart"] = {"variants": [{"unless": ["johto_whirl_b2f_seen"], "steps": [
		{"set": ["johto_whirl_b2f_seen"]},
		{"dialogue": "whirl_b2f_heart"},
	]}]}
	cutscenes["whirl_cenere"] = cenere_scene()
	cutscenes["whirl_suicune_battle"] = suicune_scene()
	cutscenes["whirl_b2f_current"] = {"variants": [
		{"unless": ["johto_suicune_done"], "steps": [{"dialogue": "whirl_b2f_current_strong"}]},
		{"unless": ["johto_whirl_current_calm_seen"], "steps": [
			{"set": ["johto_whirl_current_calm_seen"]},
			{"dialogue": "whirl_b2f_current_calm"}]},
	]}
	cutscenes["whirl_cove"] = {"variants": [{"steps": [{"dialogue": "whirl_cove"}]}]}
	cutscenes["whirl_lapras_battle"] = lapras_scene()
	cutscenes["whirl_lugia_rise"] = lugia_rise_scene()
	cutscenes["whirl_lugia_battle"] = lugia_scene()

	write_json(os.path.join(DATA, "trainers", "joh7.json"), trainers)
	write_json(os.path.join(DATA, "dialogues", "joh7_whirl.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", "joh7_whirl.json"), cutscenes)
	write_fishing()
	write_olivine()


def write_fishing():
	"""Tables de pêche des Routes 40 et 41, ajoutées en fin de `data/fishing/water_rod.json` (seul
	fichier lu par `WaterRodTables`) : le texte existant n'est pas reformaté ; un nouveau passage
	remplace le bloc du JOH7."""
	path = os.path.join(DATA, "fishing", "water_rod.json")
	with open(path, encoding="utf-8") as handle:
		text = handle.read()
	start = text.find(FISHING_MARK)
	if start >= 0:
		# Bloc déjà écrit : on le retire (jusqu'à l'accolade finale) avant de le réécrire.
		text = text[:start].rstrip().rstrip(",") + "\n}\n"
	body = text.rstrip()
	assert body.endswith("}"), "water_rod.json : accolade finale attendue"
	body = body[:-1].rstrip()
	blocks = []
	for table_id, (rod, rate, slots) in FISHING.items():
		slot_text = ",\n".join('\t\t\t{ "species": "%s", "level": %d, "weight": %d }' % slot
			for slot in slots)
		blocks.append('\t"%s": {\n\t\t"maps": ["route_40", "route_41"], "terrain": "water_rod", '
			'"rod": "%s", "rate": %d,\n\t\t"slots": [\n%s\n\t\t]\n\t}' % (table_id, rod, rate, slot_text))
	text = body + ",\n" + ",\n".join(blocks) + "\n}\n"
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(text)
	print("écrit :", os.path.relpath(path, ROOT))


def write_olivine():
	"""Ajoute aux PNJ du JOH1 : le marin de la plage (M-1, M-29), l'enfant d'après (M-30), Orme au
	Centre (M-31, M-32). Sans les fichiers du JOH1 (pas encore fusionné) : rien."""
	plan = read_plan("oliville")
	sailor_cell = list(plan["marin_plage"][1][0])
	updates = {
		"olivine_city": ("marin_plage", {"cell": sailor_cell, "facing": "down", "sprite": "sailor",
			"dialogue": "olivine_beach_sailor"}),
		"olivine_center": ("orme_joh7", {"cell": ORME_CENTER_CELL, "facing": "down",
			"sprite": "researcher", "dialogue": "olivine_orme_bell_tower", "if": ["johto_lugia_done"]}),
	}
	for map_id, (ident, entry) in updates.items():
		path = os.path.join(DATA, "npcs", map_id + ".json")
		if not os.path.exists(path):
			print("absent (JOH1 pas fusionné) :", os.path.relpath(path, ROOT))
			continue
		with open(path, encoding="utf-8") as handle:
			npcs = json.load(handle)
		npcs[ident] = entry
		write_json(path, npcs)
	# Enfant (O-22) : après Lugia, M-30 (variante ajoutée à son dialogue du JOH1, `olivine_kid`).
	path = os.path.join(DATA, "npcs", "olivine_house_2.json")
	if os.path.exists(path):
		with open(path, encoding="utf-8") as handle:
			npcs = json.load(handle)
		if "enfant" in npcs:
			npcs["enfant_joh7"] = dict(npcs["enfant"], dialogue="olivine_kid_sea",
				**{"if": ["johto_lugia_done"]})
			npcs["enfant"]["unless"] = ["johto_lugia_done"]
			write_json(path, npcs)


if __name__ == "__main__":
	main()
