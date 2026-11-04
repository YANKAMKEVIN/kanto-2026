#!/usr/bin/env python3
"""Données de jeu du jalon JOH8 (Bois de la Tour, Tour Carillon, Dante (1), Entei, Ho-Oh),
générées depuis les grilles.

Lit les positions de `tools/plans/bell_tower_woods.txt`, `bell_tower_1f.txt`, `bell_tower_2f.txt`,
`bell_tower_roof.txt` (grilles validées le 2026-11-03, elles font foi) et écrit, d'après
`docs/design/dossier-joh-09-tour-carillon.md` (textes H-1 à H-38 validés le 2026-11-02 ; Dresseurs
§6, objets §7, ordre de jeu §4) et le plan `docs/tech/jalon-joh8.md` §2 :
  - `data/npcs/bell_tower_*.json` (Dresseurs, PNJ, objets visibles, Dante, Entei, Ho-Oh) ;
  - `data/trainers/bell_tower.json` ;
  - `data/dialogues/joh8_bell_tower.json`, `data/cutscenes/joh8_bell_tower.json` ;
  - `data/dialogues/joh8_ecruteak.json`, `data/cutscenes/joh8_ecruteak.json` (Rosalia : sage
    blessé, doyen, Orme, habitante, Diane) ;
  - et **complète** les fichiers de Rosalia du JOH2 (`data/npcs/ecruteak_city.json`,
    `ecruteak_elders_house.json`, `ecruteak_center.json`, dialogue du doyen dans
    `data/dialogues/joh2_ecruteak_interiors.json`) quand ils existent : relancer ce script après
    `tools/gen_joh2_data.py` (les entrées du JOH8 sont réécrites à l'identique, rien d'autre ne
    change ; `test_joh8_data` vérifie leur présence).
Les textes absents du dossier sont marqués « draft » et listés dans
`tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Usage : python3 -I tools/gen_joh8_data.py
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

MAPS = ["bell_tower_woods", "bell_tower_1f", "bell_tower_2f", "bell_tower_roof"]
N = None  # narration

# --- Drapeaux (dossier §11) -------------------------------------------------------------------
CLUE = "johto_bell_tower_clue"      # JOH7 (M-31)
OPEN = "johto_bell_tower_open"
MET = "johto_dante_met"
BEATEN = "johto_dante_defeated_1"
LOST = "johto_dante_lost_1"         # [D] : défaite du joueur (reprise H-17)
SEEN = "johto_ho_oh_seen"
FLED = "johto_dante_fled_1"
ENTEI_DONE = "johto_entei_done"
ENTEI_CAUGHT = "johto_entei_caught"  # [D]
ENTEI_GONE = "johto_entei_fled"      # [D] : le joueur a fui le combat (Entei disparaît aussi)
HO_OH_DONE = "johto_ho_oh_done"
HO_OH_CAUGHT = "johto_ho_oh_caught"  # [D]
HO_OH_GONE = "johto_ho_oh_fled"      # [D]
WING = "got_rainbow_wing"            # [D]
ACT3 = "johto_act3"
ORME_TOLD = "johto_orme_silver_told"  # [D]
CHAPTER_DONE = "johto_chapter_done"   # JOH9 : fin du chapitre (retour de Ho-Oh, cadre §4.5)
HO_OH_BACK_DONE = "johto_ho_oh_return_done"  # [D]

# --- Dresseurs (dossier §6) -------------------------------------------------------------------
# prize_per_level [D] : Sbires 40, Dante 120 (prize_money fixé par le niveau du dernier Pokémon).
TRAINERS = {
	"bell_tower_grunt_watch": {"name": "Sbire", "class": "sbire_rocket", "prize": 40,
		"team": [("weezing", 60), ("arbok", 60)]},
	"bell_tower_grunt_v": {"name": "Sbire", "class": "sbire_rocket", "prize": 40,
		"team": [("houndoom", 61), ("golbat", 61)]},
	"bell_tower_grunt_w": {"name": "Sbire", "class": "sbire_rocket_f", "prize": 40,
		"team": [("muk", 61), ("noctowl", 61), ("houndour", 60)]},
}
# Dante (1) : 5 Pokémon, sans Tyranocif (JH-54) ; IA « smart », changements permis, attaques
# choisies [D] (feu et ténèbres ; Cizayox contre les Psy et les Plante, Farfuret contre les Dragon
# et les Vol, dossier §6). Pas de bloc « card » : aucun portrait de Dante (phase DA, Reportés).
DANTE = {
	"name": "Dante", "class": "gentleman", "ai": "smart", "can_lose": False, "heal_after": False,
	"gives_exp": True, "prize_money": 0, "prize_per_level": 120, "start_message": False,
	"end_message": True, "bag": True, "switch": True,
	"team": [
		{"species": "houndoom", "level": 64, "moves": ["flamethrower", "crunch", "solar_beam", "feint_attack"]},
		{"species": "magmar", "level": 65, "moves": ["fire_blast", "thunder_punch", "psychic", "confuse_ray"]},
		{"species": "scizor", "level": 66, "moves": ["metal_claw", "wing_attack", "slash", "swords_dance"]},
		{"species": "sneasel", "level": 66, "moves": ["ice_beam", "feint_attack", "slash", "quick_attack"]},
		{"species": "arcanine", "level": 68, "moves": ["flamethrower", "crunch", "body_slam", "dig"]},
	],
}
TRAINER_OF = {
	("bell_tower_woods", "sbire_guet"): "bell_tower_grunt_watch",
	("bell_tower_1f", "sbire_v"): "bell_tower_grunt_v",
	("bell_tower_2f", "sbire_w"): "bell_tower_grunt_w",
}
TRAINER_SPRITES = {"bell_tower_grunt_watch": "rocket_grunt_m", "bell_tower_grunt_v": "rocket_grunt_m",
	"bell_tower_grunt_w": "rocket_grunt_f"}
# H-5, H-7, H-8 : avant · défaite · après.
TRAINER_LINES = {
	"bell_tower_grunt_watch": ("Personne ne monte !\nOrdre du patron !", "Le patron va me\nbrûler vif…",
		"Il est en haut.\nIl attend l'aube."),
	"bell_tower_grunt_v": ("L'escalier est à nous !", "Bon… monte,\nsi tu veux mourir.",
		"Toi, tu n'as jamais vu\nle patron en colère."),
	"bell_tower_grunt_w": ("À l'aube, tout le ciel\nsera à nous !", "Le ciel attendra.",
		"Le patron dit qu'un seul suffit.\nJe n'ai pas compris quoi."),
}

# --- Textes (dossier §15) : identifiant → (orateur, pages[, brouillon]) ----------------------------
TEXTS = {
	# Rosalia
	"joh8_sage_blesse": ("Sage", ["Il est venu cette nuit,\navec des hommes en noir.",
		"Un Pokémon rouge hurlait\ndans une cage de feu.", "Va voir le doyen. Vite."]),
	# Bois
	"bell_tower_woods_panneau": (N, ["TOUR CARILLON\nSes cloches appellent\nle gardien du ciel."]),
	# 1F
	"bell_tower_1f_sage_1": ("Sage", ["… Il nous a dit de dormir.\nEt nous avons dormi."]),
	"bell_tower_1f_sage_2": ("Sage", ["Ses yeux… Je n'avais jamais vu\nune telle haine."]),
	"bell_tower_1f_autel": (N, ["Un autel ancien.\nL'encens y brûle encore."], True),
	# 2F
	"bell_tower_2f_examen_planche": (N, ["Le bois craque sous les pieds."]),
	"bell_tower_2f_hiroshi_soin": (N, ["L'équipe de {player}\nest soignée."]),  # page d'Hiroshi
	"bell_tower_climb_1": (N, ["La montée est longue…"]),
	"bell_tower_climb_2": (N, ["Le ciel pâlit."]),
	# Sommet
	"bell_tower_roof_cloche": (N, ["La grande cloche de la tour.\nSon bronze est encore tiède."], True),
	"bell_tower_roof_rambarde": (N, ["Tout en bas, les toits de Rosalia\nsortent de la brume."], True),
	"bell_tower_arrival": (N, ["Un homme se tient\nsous la grande cloche.",
		"À ses pieds, une cage de flammes.\nUn Pokémon rouge s'y débat."]),
	"bell_tower_dante_welcome": ("Dante", ["Te voilà.",
		"Le déserteur t'a raconté mon histoire,\nje suppose. La porte, le feu.",
		"Il t'a dit que j'avais survécu.\nIl ne t'a pas dit ce qu'il en reste."]),
	"bell_tower_dante_plan": ("Dante", ["Les sages croient\nqu'il faut les trois.",
		"Ils se trompent.\nIl suffit qu'un seul souffre assez.",
		"Ho-Oh viendra pour lui. Et ce jour-là,\nsa flamme sera à moi."]),
	"bell_tower_dante_before": ("Dante", ["Tu as libéré les deux autres.\nCourageux. Inutile.",
		"Je ne te déteste pas, {player}.\nTu es seulement sur mon chemin.",
		"Comme moi, autrefois, j'étais\nsur celui de Giovanni."]),
	"bell_tower_dante_resume": ("Dante", ["Tu reviens déjà ?", "Le soleil, lui, n'attend pas."]),
	"bell_tower_dante_defeated": ("Dante", ["…", "Bien. Très bien.",
		"Tu te bats comme moi, quand j'avais\nencore quelque chose à protéger."]),
	"bell_tower_dante_bell": ("Dante", ["Mais tu arrives trop tard. Regarde."]),
	"bell_tower_bell_rings": (N, ["Dante frappe la grande cloche.",
		"Le son roule jusqu'à l'horizon."]),
	"bell_tower_descent": (N, ["Le soleil se lève.", "Un cri traverse le ciel.",
		"Un Pokémon aux mille couleurs\ndescend des nuages !"]),
	"bell_tower_refusal_1": (N, ["Ho-Oh se pose devant Dante.", "Il le regarde longtemps.", "…"]),
	"bell_tower_refusal_2": (N, ["Ses ailes s'embrasent !\nLa cage de feu vole en éclats !",
		"Ho-Oh s'envole et tourne\nau-dessus de la tour."]),
	"bell_tower_dante_refused": ("Dante", ["Non…", "Même lui.\nMême lui me tourne le dos."]),
	"bell_tower_dante_flight": ("Dante", ["Pas ici. Pas comme ça.",
		"Entei ! Tu es libre.\nMontre-leur ta colère."]),
	"bell_tower_entei_roar": (N, ["Entei pousse un rugissement !"]),
	"bell_tower_arcanine": (N, ["Dante saute sur le dos\nde son Arcanin !", "Ils bondissent de toit en toit…"]),
	"bell_tower_dante_promise": ("Dante", ["Je finirai là où\ntout a commencé.", "Au sommet du monde.",
		"Viens, si tu l'oses."]),
	"bell_tower_entei_turns": (N, ["Entei se tourne vers {player}.",
		"La colère brûle encore\ndans ses yeux !"]),
	"bell_tower_entei_gone": (N, ["Entei bondit par-dessus\nla rambarde et disparaît."]),
	"bell_tower_entei_calm": (N, ["Entei s'est calmé."]),
	"bell_tower_entei_caged": (N, ["À ses pieds, une cage de flammes.\nUn Pokémon rouge s'y débat."]),
	"bell_tower_ho_oh_lands": (N, ["Ho-Oh redescend.",
		"Il se pose sous la grande cloche,\nface à {player}.", "Il attend."]),
	"bell_tower_ho_oh_test": (N, ["Ho-Oh veut éprouver\nle cœur de {player} !"]),
	"bell_tower_ho_oh_gone": (N, ["Ho-Oh s'élève dans la lumière\ndu matin et disparaît."]),
	"bell_tower_feather_falls": (N, ["Une plume aux mille couleurs\ntombe doucement sur le toit."]),
	"bell_tower_feather_taken": (N, ["{player} ramasse\nla Plume Arc-en-ciel !",
		"Elle brille de toutes les couleurs."]),
	# Rosalia, après (H-34 à H-38)
	"joh8_doyen_after": ("Doyen", ["Les cloches ont sonné. Toute la ville\na vu le ciel s'ouvrir.",
		"Ho-Oh a choisi, {player}.\nEt ce n'est pas cet homme.",
		"« Le sommet du monde »… Il n'y a qu'un\nlieu qu'on appelle ainsi : le Mont Argenté.",
		"Les anciens disent que la Team Rocket\ny est née, il y a bien longtemps."]),
	"joh8_orme_silver": ("Orme", ["{player} ! J'ai vu la lumière\ndepuis Doublonville !",
		"Le Mont Argenté… C'est la montagne\nla plus dangereuse entre Johto et Kanto.",
		"Le chemin part d'Acajou, vers le nord.\nPrépare-toi bien."]),
	"joh8_orme_after": ("Orme", ["Raikou, Suicune, Entei libres.\nLugia et Ho-Oh sont apparus.",
		"Il ne reste plus que Dante.",
		"Je préviens Chen. Lui saura peut-être\nqui t'attend là-haut."]),
	"joh8_habitante_aube": ("Habitante", ["Ce matin, le ciel était\nplein de couleurs.",
		"Ma grand-mère pleurait. Elle disait\nqu'elle l'attendait depuis toujours."]),
	"joh8_diane_after": ("Diane", ["Ce matin, les cloches\nont sonné toutes seules.",
		"Je n'y ai même pas touché."]),
}
DOYEN_OPEN = ["Te voilà enfin.",
	"L'homme de la radio est monté dans\nla Tour Carillon. Avec le troisième.",
	"Mes sages ont voulu l'arrêter. Il a suffi\nd'un regard de son Pokémon.",
	"La tour attend un cœur pur\ndepuis trois cents ans.", "Ce n'est pas lui.",
	"C'est peut-être toi.\nMonte, {player}. Avant l'aube."]
HIROSHI = ["Tu es le Dresseur de Kanto ?",
	"Repose tes Pokémon. Ce qui t'attend\nlà-haut n'a pas de pitié."]
DESCRIPTIONS = {
	"bell_tower": "Une tour sacrée, où sonnent les cloches de l'aube.",
	"bell_tower_woods": "Un bois d'érables, au pied de la Tour Carillon.",
}

CELL_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?,(\d+)(?:\.\.(\d+))?$")


def read_plan(name):
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
			body, _, _comment = line.partition("#")
			words = body.split()
			attrs = {}
			for word in words[4:]:
				if "=" in word:
					key, _, value = word.partition("=")
					attrs[key] = value
			positions[words[0]] = (words[1], parse_cells(words[2]), attrs)
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
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(json.dumps(data, ensure_ascii=False, indent="\t") + "\n")
	print("écrit :", os.path.relpath(path, ROOT))


def load_json(path):
	with open(path, encoding="utf-8") as handle:
		return json.load(handle)


def dialogue(speaker, pages, draft=False):
	entry = {"speaker": speaker} if speaker else {"narration": True}
	if draft:
		entry["draft"] = True
	entry["pages"] = pages
	return entry


def text(ident):
	return dialogue(*TEXTS[ident])


def item_scene(ident, item, count, flag):
	return {"variants": [{"unless": [flag], "steps": [
		{"despawn": ident}, {"give": item, "count": count, "found": True}, {"set": [flag]}]}]}


# --- Scènes du sommet ---------------------------------------------------------------------------
# Le joueur se tient en (9, 7), deux cases sous Dante (9, 5) ; Ho-Oh descend en (9, 6), entre eux.
STAND = [9, 7]


def fight_steps():
	"""Étapes 5 et 6 : le combat (avant : H-14 à H-16 ; reprise : H-17), puis H-18 à la victoire ;
	défaite : drapeau de reprise, réveil au Centre de Rosalia (la scène s'arrête)."""
	return [
		{"dialogue": "bell_tower_dante_before", "unless": [LOST]},
		{"dialogue": "bell_tower_dante_resume", "if": [LOST]},
		{"battle": "bell_tower_dante_1", "win": [BEATEN], "lose": [LOST]},
		{"wake_up": True, "unless": [BEATEN]},
		{"wait": 0.6},
		{"dialogue": "bell_tower_dante_defeated"},
	]


def bell_steps():
	"""Étape 7 : la cloche (H-19), la descente (H-20), le refus (H-21, la cage brûle : FlagGate
	`unless johto_ho_oh_seen`), H-22."""
	return [
		{"dialogue": "bell_tower_dante_bell"},
		{"face": "dante", "to": "up"},
		{"dialogue": "bell_tower_bell_rings"},
		{"flash": 1},
		{"face": "dante", "to": "down"},
		{"dialogue": "bell_tower_descent"},
		{"spawn": "ho_oh_descente", "sprite": "pokemon/ho_oh", "cell": [9, 6], "facing": "up",
			"turn_to_player": False},
		{"face": "player", "to": "ho_oh_descente"},
		{"dialogue": "bell_tower_refusal_1"},
		{"flash": 2},
		{"set": [SEEN]},
		{"dialogue": "bell_tower_refusal_2"},
		{"despawn": "ho_oh_descente"},
		{"face": "player", "to": "dante"},
		{"dialogue": "bell_tower_dante_refused"},
	]


def flight_steps():
	"""Étape 8 : Dante ouvre la cage (H-23), Arcanin (H-24), la promesse (H-25), la fuite par les
	toits (marche jusqu'à la rambarde est, puis effacé) [D]."""
	return [
		{"dialogue": "bell_tower_dante_flight"},
		{"face": "entei", "to": "player"},
		{"dialogue": "bell_tower_entei_roar"},
		{"dialogue": "bell_tower_arcanine"},
		{"dialogue": "bell_tower_dante_promise"},
		{"move": "dante", "to": [17, 5]},
		{"despawn": "dante"},
		{"set": [FLED]},
	]


def entei_steps():
	"""Étape 9 : Entei (H-26 ; combat fixe N60 ; H-27 / H-28). Fuite du joueur = Entei disparaît
	aussi (dossier §6 [D] : « K.O. ou fuite »)."""
	return [
		{"face": "entei", "to": "player"},
		{"dialogue": "bell_tower_entei_turns"},
		{"wild_battle": "entei", "level": 60, "intro": "legendary", "actor": "entei",
			"flee": [ENTEI_GONE, ENTEI_DONE],
			"static": {"done": ENTEI_DONE, "caught": ENTEI_CAUGHT}},
		{"despawn": "entei", "if": [ENTEI_GONE]},
		{"dialogue": "bell_tower_entei_calm", "if": [ENTEI_CAUGHT]},
		{"dialogue": "bell_tower_entei_gone", "if": [ENTEI_DONE], "unless": [ENTEI_CAUGHT]},
	]


def ho_oh_steps(actor, inline):
	"""Étape 10 : Ho-Oh (H-29 s'il se pose pendant la scène, H-30 ; combat fixe N65 ; H-31), puis
	la plume (H-32, H-33)."""
	steps = []
	if inline:
		steps += [
			{"dialogue": "bell_tower_ho_oh_lands"},
			{"spawn": actor, "sprite": "pokemon/ho_oh", "cell": [9, 5], "facing": "down",
				"turn_to_player": False},
			{"face": "player", "to": actor},
		]
	# Dans la scène, on n'arrive ici qu'Entei affronté (défaite : réveil, la scène s'arrête).
	cond = {}
	steps += [
		dict({"dialogue": "bell_tower_ho_oh_test"}, **cond),
		dict({"wild_battle": "ho_oh", "level": 65, "intro": "legendary", "actor": actor,
			"flee": [HO_OH_GONE, HO_OH_DONE],
			"static": {"done": HO_OH_DONE, "caught": HO_OH_CAUGHT}}, **cond),
		{"despawn": actor, "if": [HO_OH_GONE]},
		{"dialogue": "bell_tower_ho_oh_gone", "if": [HO_OH_DONE], "unless": [HO_OH_CAUGHT]},
		{"dialogue": "bell_tower_feather_falls", "if": [HO_OH_DONE], "unless": [WING]},
		{"give": "rainbow_wing", "count": 1, "if": [HO_OH_DONE], "unless": [WING]},
		{"dialogue": "bell_tower_feather_taken", "if": [HO_OH_DONE], "unless": [WING]},
		{"set": [WING], "if": [HO_OH_DONE]},
	]
	return steps


def roof_scenes():
	arrival = [
		{"dialogue": "bell_tower_arrival", "unless": [MET]},
		{"move": "player", "to": STAND},
		{"face": "player", "to": "dante"},
		{"face": "dante", "to": "player"},
		{"dialogue": "bell_tower_dante_welcome", "unless": [MET]},
		{"dialogue": "bell_tower_dante_plan", "unless": [MET]},
		{"set": [MET]},
	]
	tail = bell_steps() + flight_steps() + entei_steps() + ho_oh_steps("ho_oh", True)
	return {
		# Déclencheur (3, 3), seule sortie du palier : H-13 à H-25 et les deux combats fixes.
		"bell_tower_summit": {"variants": [{"unless": [BEATEN], "steps": arrival + fight_steps() + tail}]},
		# Reprises (application coupée au milieu) : parler à Dante, Entei, Ho-Oh.
		"bell_tower_dante_resume_bell": {"variants": [
			{"if": [BEATEN], "unless": [SEEN], "steps": [{"face": "dante", "to": "player"}] + tail},
			{"if": [SEEN], "unless": [FLED], "steps": [{"face": "dante", "to": "player"}]
				+ [{"dialogue": "bell_tower_dante_refused"}] + flight_steps() + entei_steps()
				+ ho_oh_steps("ho_oh", True)},
			{"unless": [BEATEN], "steps": [{"move": "player", "to": STAND}, {"face": "player", "to": "dante"},
				{"face": "dante", "to": "player"}] + fight_steps() + tail},
		]},
		"bell_tower_entei": {"variants": [
			{"if": [FLED], "unless": [ENTEI_DONE], "steps": entei_steps() + ho_oh_steps("ho_oh", True)}]},
		"bell_tower_ho_oh": {"variants": [
			{"if": [ENTEI_DONE], "unless": [HO_OH_DONE], "steps": ho_oh_steps("ho_oh", False)}]},
		# Après le chapitre (cadre §4.5, dossier §6 [D]) : Ho-Oh revient au sommet s'il n'a pas été
		# capturé (JOH9 lève `johto_chapter_done`).
		"bell_tower_ho_oh_return": {"variants": [
			{"if": [CHAPTER_DONE, HO_OH_DONE], "unless": [HO_OH_CAUGHT, HO_OH_BACK_DONE], "steps": [
				{"dialogue": "bell_tower_ho_oh_test"},
				{"wild_battle": "ho_oh", "level": 65, "intro": "legendary", "actor": "ho_oh_retour",
					"static": {"done": HO_OH_BACK_DONE, "caught": HO_OH_CAUGHT}},
				{"dialogue": "bell_tower_ho_oh_gone", "if": [HO_OH_BACK_DONE], "unless": [HO_OH_CAUGHT]},
			]}]},
		"bell_tower_wing": item_scene_wing(),
		# H-12 : le long escalier en fondu (2F → sommet).
		"bell_tower_climb": {"steps": [
			{"dialogue": "bell_tower_climb_1"},
			{"change_map": "bell_tower_roof", "at": "from_2f", "facing": "down"},
			{"dialogue": "bell_tower_climb_2"},
		]},
	}


def item_scene_wing():
	return {"variants": [{"if": [HO_OH_DONE], "unless": [WING], "steps": [
		{"despawn": "plume"},
		{"give": "rainbow_wing", "count": 1},
		{"dialogue": "bell_tower_feather_taken"},
		{"set": [WING]},
	]}]}


def main():
	npcs_by_map = {}
	dialogues = {}
	cutscenes = {}
	for map_id in MAPS:
		positions = read_plan(map_id)
		npcs = {}
		for ident, (kind, cells, attrs) in positions.items():
			cell = list(cells[0])
			if kind == "dresseur" and attrs.get("role") == "sbire":
				tid = TRAINER_OF[(map_id, ident)]
				before, defeated, after = TRAINER_LINES[tid]
				for suffix, line in (("before", before), ("defeated", defeated), ("after", after)):
					dialogues["%s_%s" % (tid, suffix)] = dialogue("Sbire", [line])
				npcs[ident] = {"cell": cell, "facing": attrs["facing"], "sprite": TRAINER_SPRITES[tid],
					"dialogue": tid + "_after", "trainer": {"id": tid, "sight": int(attrs["sight"]),
						"before": tid + "_before", "defeated": tid + "_defeated"}}
			elif kind == "dresseur" and ident == "dante":
				# Dante : jamais de vue ; la scène du palier le fait parler. Lui parler reprend la
				# scène si l'application a été coupée (dossier §12).
				npcs[ident] = {"cell": cell, "facing": "down", "sprite": "gentleman",
					"dialogue": "bell_tower_roof_dante", "turn_to_player": False, "unless": [FLED]}
				dialogues["bell_tower_roof_dante"] = {"speaker": "Dante",
					"cutscene": "bell_tower_dante_resume_bell", "pages": ["…"]}
			elif kind == "pnj":
				entry = {"cell": cell, "facing": attrs.get("facing", "down"), "sprite": "channeler"}
				if ident == "hiroshi":
					entry["dialogue"] = "bell_tower_2f_hiroshi"
					# H-10 : soin à chaque passage [D] ; les deux bulles d'Hiroshi puis la ligne
					# système, le soin à la fin du dialogue.
					dialogues["bell_tower_2f_hiroshi"] = {"narration": True, "heal": True, "pages":
						[{"text": page, "speaker": "Hiroshi"} for page in HIROSHI]
						+ TEXTS["bell_tower_2f_hiroshi_soin"][1]}
				else:
					entry["dialogue"] = "%s_%s" % (map_id, ident)
					dialogues[entry["dialogue"]] = text(entry["dialogue"])
				npcs[ident] = entry
			elif kind in ("panneau", "examen"):
				did = "%s_%s" % (map_id, ident)
				dialogues[did] = text(did)
			elif kind == "objet_visible":
				if ident == "plume":
					npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
						"dialogue": "bell_tower_wing", "verb": "take", "turn_to_player": False,
						"if": [HO_OH_DONE], "unless": [WING]}
					dialogues["bell_tower_wing"] = {"cutscene": "bell_tower_wing"}
					continue
				flag = "got_%s_%s" % (map_id, ident)
				did = "%s_%s" % (map_id, ident)
				npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": did, "verb": "take", "turn_to_player": False, "unless": [flag]}
				dialogues[did] = {"cutscene": did}
				cutscenes[did] = item_scene(ident, attrs["item"], int(attrs.get("quantite", 1)), flag)
			elif kind == "pokemon":
				species = attrs["espece"]
				entry = {"cell": cell, "facing": "down", "sprite": "pokemon/" + species,
					"dialogue": "bell_tower_" + species, "verb": "observe", "turn_to_player": False}
				if species == "entei":
					entry["unless"] = [ENTEI_DONE]
					dialogues["bell_tower_entei"] = {"narration": True, "variants": [
						{"if": [FLED], "cutscene": "bell_tower_entei"},
						{"pages": TEXTS["bell_tower_entei_caged"][1]}]}
				else:
					entry["if"] = [ENTEI_DONE]
					entry["unless"] = [HO_OH_DONE]
					dialogues["bell_tower_ho_oh"] = {"cutscene": "bell_tower_ho_oh"}
				npcs[ident] = entry
		if map_id == "bell_tower_roof":
			# Retour de Ho-Oh après le chapitre (s'il n'a pas été capturé) [D].
			npcs["ho_oh_retour"] = {"cell": [9, 5], "facing": "down", "sprite": "pokemon/ho_oh",
				"dialogue": "bell_tower_ho_oh_return", "verb": "observe", "turn_to_player": False,
				"if": [CHAPTER_DONE, HO_OH_DONE], "unless": [HO_OH_CAUGHT, HO_OH_BACK_DONE]}
			dialogues["bell_tower_ho_oh_return"] = {"cutscene": "bell_tower_ho_oh_return"}
		npcs_by_map[map_id] = npcs
	for ident in TEXTS:
		if ident.startswith("bell_tower_") and ident not in dialogues and ident not in (
				"bell_tower_entei_caged", "bell_tower_2f_hiroshi_soin"):
			dialogues[ident] = text(ident)
	cutscenes.update(roof_scenes())
	for map_id, npcs in npcs_by_map.items():
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
	trainers = {}
	for tid, spec in TRAINERS.items():
		trainers[tid] = {"name": spec["name"], "class": spec["class"], "ai": "random",
			"can_lose": False, "heal_after": False, "gives_exp": True, "prize_money": 0,
			"prize_per_level": spec["prize"],
			"team": [{"species": s, "level": lv} for s, lv in spec["team"]]}
	trainers["bell_tower_dante_1"] = DANTE
	write_json(os.path.join(DATA, "trainers", "bell_tower.json"), trainers)
	write_json(os.path.join(DATA, "dialogues", "joh8_bell_tower.json"), dict(sorted(dialogues.items())))
	write_json(os.path.join(DATA, "cutscenes", "joh8_bell_tower.json"), cutscenes)
	write_rosalia()


# --- Rosalia (fichiers du JOH2) -----------------------------------------------------------------
# PNJ posés par le JOH8 dans Rosalia [D] : (fichier de PNJ, identifiant) → entrée.
ROSALIA_NPCS = {
	("ecruteak_city", "sage_blesse"): {"cell": [44, 13], "facing": "left", "sprite": "channeler",
		"dialogue": "joh8_sage_blesse", "if": [CLUE], "unless": [OPEN]},
	# H-37 : habitante sur la pelouse à l'est de l'avenue (case libre hors grille) [D].
	("ecruteak_city", "habitante_aube"): {"cell": [30, 18], "facing": "down", "sprite": "aoki",
		"dialogue": "joh8_habitante_aube", "if": [SEEN]},
	# H-35, H-36 : Orme au Centre de Rosalia après le sommet [D] (case libre de la salle).
	("ecruteak_center", "orme"): {"cell": [11, 6], "facing": "left", "sprite": "researcher",
		"dialogue": "joh8_orme", "if": [HO_OH_DONE]},
}


def doyen_variants():
	"""Variantes JOH8 du doyen, **en tête** de son dialogue : H-2 + H-3 (ouvre la tour) ; H-34
	après le sommet (lève `johto_act3`)."""
	return [
		{"if": [HO_OH_DONE], "set": [ACT3], "pages": TEXTS["joh8_doyen_after"][1], "joh8": True},
		{"if": [CLUE], "unless": [OPEN], "set": [OPEN], "pages": DOYEN_OPEN, "joh8": True},
	]


def write_rosalia():
	dialogues = {
		"joh8_sage_blesse": text("joh8_sage_blesse"),
		"joh8_habitante_aube": text("joh8_habitante_aube"),
		"joh8_diane_after": text("joh8_diane_after"),
		"joh8_orme": {"speaker": "Orme", "variants": [
			{"unless": [ORME_TOLD], "set": [ORME_TOLD, ACT3], "pages": TEXTS["joh8_orme_silver"][1]},
			{"pages": TEXTS["joh8_orme_after"][1]},
		]},
	}
	write_json(os.path.join(DATA, "dialogues", "joh8_ecruteak.json"), dialogues)
	for (map_id, ident), entry in ROSALIA_NPCS.items():
		path = os.path.join(DATA, "npcs", map_id + ".json")
		if not os.path.exists(path):
			print("absent (JOH2 pas encore fusionné) :", os.path.relpath(path, ROOT))
			continue
		npcs = load_json(path)
		npcs[ident] = entry
		write_json(path, npcs)
	# Garde R-20 : il s'efface avec l'ouverture de la tour.
	path = os.path.join(DATA, "npcs", "ecruteak_city.json")
	if os.path.exists(path):
		npcs = load_json(path)
		if "garde_carillon" in npcs:
			npcs["garde_carillon"]["unless"] = [OPEN]
			write_json(path, npcs)
	# Doyen : variantes du JOH8 en tête (réécrites à l'identique à chaque passage).
	path = os.path.join(DATA, "dialogues", "joh2_ecruteak_interiors.json")
	if os.path.exists(path):
		data = load_json(path)
		doyen = data.get("ecruteak_elders_house_doyen")
		if doyen is not None:
			variants = [v for v in doyen.get("variants", []) if not is_joh8_variant(v)]
			fresh = doyen_variants()
			for v in fresh:
				v.pop("joh8")
			doyen["variants"] = fresh + variants
			write_json(path, data)


def is_joh8_variant(variant):
	return variant.get("set") in ([ACT3], [OPEN]) and (
		variant.get("if") in ([HO_OH_DONE], [CLUE]))


if __name__ == "__main__":
	main()
