#!/usr/bin/env python3
"""Données de jeu du jalon JOHP1 (Ruines d'Alpha, arc des Pierres), générées depuis les grilles.

Lit les positions de `tools/plans/ruins_of_alph.txt`, `alph_tent.txt`, `alph_gallery.txt`,
`alph_chamber.txt` et de la variante ARC de `route_36.txt` (grilles validées le 2026-11-05, elles
font foi) et écrit, d'après `docs/design/dossier-joh-11-arc-pierres.md` (textes §17 validés le
2026-11-05, Dresseurs §10, rencontres §11, objets §12) et le plan `docs/tech/jalon-joh-pierres.md` §3 :
  - `data/npcs/<carte>.json` (Dresseurs, Héloïse, faux archéologue, objets visibles) ;
  - `data/trainers/ruins_of_alph.json` ; `data/encounters/ruins_of_alph.json`, `alph_gallery.json` ;
  - `data/dialogues/johp1_alph.json`, `data/cutscenes/johp1_alph.json` ;
  - `data/items/items_johp.json` (les trois pierres, descriptions P-9) ;
  - et **complète** `data/npcs/route_36.json` (ouvrier, P-2, P-42) : relancer ce script après
    `tools/gen_joh3_data.py`.
Aucun texte hors du dossier : les répliques sont celles du §17, mot pour mot.

Usage : python3 -I tools/gen_johp1_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

MAPS = ["ruins_of_alph", "alph_tent", "alph_gallery", "alph_chamber"]
# Largeur d'une ligne de bulle (3 lignes au plus, `UiTokens.DIALOG_MAX_LINES`) [D].
WRAP = 36
N = None  # narration

# --- Drapeaux (dossier §7) ------------------------------------------------------------------------
QUEST = "johto_stones_quest"      # posé à la Tour Radio par la bascule du JOHP3
MET = "johto_alph_met"
TILES_DONE = "johto_alph_tiles_done"
STONE = "johto_stone_memory"
AWAKENED = "johto_stones_awakened"  # JOHP0, JOHP3 : P-57 après l'arc
ARRIVED = "johto_alph_arrived"      # grille (titre de zone, une fois)
GATE_PASSED = "johto_alph_gate_passed"  # [D] : P-2 une fois, au premier passage
FAKE_WON = "johto_alph_fake_defeated"   # [D] : le faux archéologue est parti
TILE_1 = "johto_alph_tile_1"        # [D] : drapeaux de rang des dalles (plan §3.2)
TILE_2 = "johto_alph_tile_2"        # [D]

FAKE_ID = "alph_fake_archeologist"
# Sprite provisoire du déguisement [D] (le faux employé de la Tour avait `engineer`).
FAKE_SPRITE = "fossil_researcher"

# --- Dresseurs (dossier §10) ; prize_per_level [D] : 40 ordinaires, 45 Sbires et Scientifique, ------
# 60 faux archéologue. id : (nom, orateur, classe, sprite, prix, équipe, (avant, défaite, après)).
TRAINERS = {
	"alph_researcher_agnes": ("Chercheuse Agnès", None, "topdresseuse", "maya", 40,
		[("kadabra", 31), ("golbat", 30)],
		("Une chercheuse doit tester ses hypothèses. Toi, par exemple.", "Hypothèse rejetée.",
			"Ces signes changent quand on ne les regarde pas. Je te jure.")),
	"alph_nerd_remi": ("Intello Rémi", None, None, "nerd", 40,
		[("magneton", 31), ("porygon", 30)],
		("J'ai calculé l'âge de ces murs. Veux-tu calculer ta défaite ?", "J'ai oublié une retenue.",
			"Personne n'a jamais compté toutes les dalles.")),
	"alph_medium_solange": ("Médium Solange", None, "exorciste", "channeler", 40,
		[("haunter", 31), ("kadabra", 31)],
		("Les ruines murmurent. Écoute-les avec moi.", "Elles murmuraient ton nom.",
			"La nuit, les signes bougent sur les murs.")),
	"alph_grunt_v": ("Sbire Rocket", "Sbire", "sbire_rocket", "rocket_grunt_m", 45,
		[("koffing", 31), ("raticate", 31)],
		("On creuse ! Dégage !", "Ma pelle…", "On cherche un caillou. Trois jours pour un caillou.")),
	"alph_grunt_w": ("Sbire Rocket", "Sbire", "sbire_rocket_f", "rocket_grunt_f", 45,
		[("arbok", 32)],
		("Pas de visite aujourd'hui !", "La visite est terminée.",
			"Le patron des fouilles porte une fausse barbe. Ne lui dis pas que ça se voit.")),
	"alph_grunt_x": ("Sbire Rocket", "Sbire", "sbire_rocket", "rocket_grunt_m", 45,
		[("houndour", 32), ("murkrow", 32)],
		("Tu ne passeras pas ce couloir !", "Bon, si.",
			"Personne ne comprend ces dalles. Elles nous renvoient toujours au début.")),
	"alph_scientist": ("Scientifique Rocket", "Scientifique", None, "researcher", 45,
		[("magneton", 33), ("electrode", 33)],
		("Ces signes sont du bruit. Mes machines le prouveront.", "Du bruit. Rien que du bruit.",
			"Comment peut-on lire ça ?")),
}
FAKE_TRAINER = {
	"name": "Faux archéologue", "class": "sbire_rocket", "ai": "random", "can_lose": False,
	"heal_after": False, "gives_exp": True, "prize_money": 0, "prize_per_level": 60,
	"team": [{"species": "arbok", "level": 34}, {"species": "raticate", "level": 34},
		{"species": "houndoom", "level": 35}],
}

# --- Textes (dossier §17) : identifiant → (orateur, bulles) ---------------------------------------
TEXTS = {
	# P-41, P-5
	"ruins_of_alph_panneau_ruines": (N, ["RUINES D'ALPHA", "Fouilles en cours. Ne rien emporter."]),
	"alph_gallery_mur_1": (N, ["Des signes gravés. Héloïse a noté en dessous :", "« celle qui se souvient »."]),
	"alph_gallery_mur_2": (N, ["Des signes gravés. Héloïse a noté en dessous :", "« celle qui revient »."]),
	"alph_gallery_mur_3": (N, ["Des signes gravés. Héloïse a noté en dessous :", "« celle qui respire »."]),
	# P-45
	"alph_tile_lit": (N, ["Le signe s'éclaire."]),
	"alph_tile_wrong": (N, ["Le sol gronde. {player} est {g:ramené|ramenée} à l'entrée de la salle."]),
	"alph_door_opens": (N, ["La porte du fond s'ouvre."]),
	# P-6, P-7
	"alph_fake_before": ("Faux archéologue", ["Halte ! Je suis un éminent savant !",
		"… Toi ? {g:Le gamin|La gamine} de la Tour Radio ?", "Mon déguisement était parfait, pourtant !"]),
	"alph_fake_defeated": ("Faux archéologue", ["La science a parlé. Elle a dit non."]),
	"alph_fake_after": ("Faux archéologue", ["Je vais en entendre parler, moi… Cenere va me faire recalculer."]),
	"alph_fake_flees": (N, ["Le faux archéologue arrache sa fausse barbe et s'enfuit !"]),
	# P-8
	"alph_chamber_stone": (N, ["Au centre de la salle, une pierre grise, tiède sous la main."]),
	"alph_chamber_stone_received": (N, ["{player} obtient la Pierre Mémoire !"]),
}
HELOISE_WELCOME = ["Orme m'a prévenue. Ne touche à rien.",
	"Des gens en noir fouillent ma galerie depuis trois jours. Ils disent qu'ils sont archéologues.",
	"Ils tiennent leurs pelles à l'envers."]
HELOISE_WALLS = ["La Pierre Mémoire est au fond. Personne n'y est jamais entré.",
	"Lis les murs. Ils disent dans quel ordre marcher.", "Les anciens n'écrivaient pas pour décorer."]
HELOISE_AFTER = ["Elle est tiède. C'est tout ce que je peux en dire.",
	"La deuxième est à Irisia, dans une grotte qui se noie à chaque marée.",
	"Il n'y a pas de route. Va voir le vieux Goulven, au port d'Oliville. Dis que c'est moi."]
HELOISE_END = ["Elles sont éteintes, donc.",
	"Je vais écrire trois cents pages là-dessus, et personne ne les lira."]
WORKER_OPEN = ["Le chantier des ruines ? Le Professeur Orme a appelé.", "Passe, c'est ouvert."]
WORKER_CLOSED = ["Chantier de fouilles.", "Entrée réservée au personnel."]

# --- Objets clés (dossier §12, P-9 ; icônes `assets/ui/items/`) -----------------------------------
ITEMS = {
	"stone_memory": ("Pierre Mémoire", "Pierres Mémoire", "Une pierre grise, tiède, couverte de signes."),
	"stone_tide": ("Pierre Marée", "Pierres Marée", "Une pierre bleue, toujours humide."),
	"stone_breath": ("Pierre Souffle", "Pierres Souffle",
		"Une pierre blanche qui semble se soulever, très lentement."),
}

# --- Rencontres (dossier §11) ---------------------------------------------------------------------
LEVELS_OUT = (27, 31)
LEVELS_IN = (28, 32)
ENCOUNTERS = {
	"ruins_of_alph": [
		("ruins_of_alph_grass_day", "grass", ["morning", "day"], 25, LEVELS_OUT, [("abra", 25),
			("kadabra", 15), ("psyduck", 20), ("geodude", 20), ("furret", 20)]),
		("ruins_of_alph_grass_night", "grass", ["night"], 25, LEVELS_OUT, [("hoothoot", 30),
			("noctowl", 15), ("gastly", 25), ("zubat", 30)]),
	],
	"alph_gallery": [
		("alph_gallery_rubble", "rubble", None, 25, LEVELS_IN, [("zubat", 35), ("golbat", 15),
			("geodude", 25), ("onix", 10), ("gastly", 15)]),
	],
}

CELL_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?,(\d+)(?:\.\.(\d+))?$")


def read_plan(name, section_name="POSITIONS"):
	"""Positions de la grille : id → (type, cases, attributs)."""
	positions = {}
	section = False
	with open(os.path.join(PLANS, name + ".txt"), encoding="utf-8") as handle:
		for raw in handle:
			line = raw.rstrip("\n")
			if line.strip() == section_name:
				section = True
				continue
			if line.startswith("FIN"):
				section = False
				continue
			if not section or not line.strip() or line.startswith("#"):
				continue
			body = line.partition("#")[0]
			words = body.split()
			attrs = {}
			for word in words[3:]:
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


def wrap(text):
	"""Retours à la ligne d'une bulle (au plus [WRAP] caractères par ligne, mots entiers)."""
	if len(text) <= WRAP:
		return text
	lines = []
	current = ""
	for word in text.split(" "):
		candidate = word if not current else current + " " + word
		if len(candidate) > WRAP and current:
			lines.append(current)
			current = word
		else:
			current = candidate
	lines.append(current)
	if len(lines) > 3:
		raise ValueError("bulle trop longue (%d lignes) : %s" % (len(lines), text))
	return "\n".join(lines)


def pages(lines):
	return [wrap(line) for line in lines]


def write_json(path, data):
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(json.dumps(data, ensure_ascii=False, indent="\t") + "\n")
	print("écrit :", os.path.relpath(path, ROOT))


def dialogue(speaker, lines):
	entry = {"speaker": speaker} if speaker else {"narration": True}
	entry["pages"] = pages(lines)
	return entry


def item_scene(ident, item, count, flag, visible):
	steps = [{"despawn": ident}] if visible else []
	steps += [{"give": item, "count": count, "found": True}, {"set": [flag]}]
	return {"variants": [{"unless": [flag], "steps": steps}]}


# --- Scènes ---------------------------------------------------------------------------------------
def worker_gate_scene():
	"""Barrière de chantier (variante ARC de la Route 36) : P-42 et un pas en arrière ; avec
	`johto_stones_quest`, P-2 au premier passage, et le chemin reste ouvert (dossier §6, étape 4)."""
	face = [{"face": "ouvrier", "to": "player"}, {"face": "player", "to": "ouvrier"}]
	return {"variants": [
		{"unless": [QUEST], "steps": face + [{"dialogue": "route_36_ouvrier"},
			{"move": "player", "path": ["up"], "keep_facing": True}]},
		{"if": [QUEST], "unless": [GATE_PASSED], "steps": face + [{"dialogue": "route_36_ouvrier"},
			{"set": [GATE_PASSED]}]},
	]}


def tile_wrong_steps():
	"""P-45 : mauvaise dalle, les rangs retombent, retour à l'entrée de la salle (fondu)."""
	return [
		{"dialogue": "alph_tile_wrong"},
		{"unset": [TILE_1, TILE_2]},
		{"change_map": "alph_gallery", "at": "retour_dalles", "facing": "up"},
	]


def tile_scenes():
	"""Dalles (dossier §8.1, plan §3.2) : une scène par bonne dalle, une pour les mauvaises. Les
	drapeaux de rang disent où en est le joueur ; une dalle déjà éclairée reste muette."""
	return {
		"alph_tile_good_1": {"variants": [
			{"unless": [TILE_1, TILES_DONE], "steps": [{"dialogue": "alph_tile_lit"}, {"set": [TILE_1]}]}]},
		"alph_tile_good_2": {"variants": [
			{"if": [TILE_1], "unless": [TILE_2, TILES_DONE], "steps": [{"dialogue": "alph_tile_lit"},
				{"set": [TILE_2]}]},
			{"unless": [TILE_1, TILES_DONE], "steps": tile_wrong_steps()}]},
		"alph_tile_good_3": {"variants": [
			{"if": [TILE_2], "unless": [TILES_DONE], "steps": [{"dialogue": "alph_tile_lit"},
				{"flash": 1}, {"set": [TILES_DONE]}, {"dialogue": "alph_door_opens"}]},
			{"unless": [TILE_2, TILES_DONE], "steps": tile_wrong_steps()}]},
		"alph_tile_wrong": {"variants": [{"unless": [TILES_DONE], "steps": tile_wrong_steps()}]},
		# Barrière du fond (grille) : sans le dernier bon pas, pas de passage.
		"alph_gallery_door": {"variants": [{"unless": [TILES_DONE], "steps": [
			{"move": "player", "path": ["down"], "keep_facing": True}]}]},
	}


def fake_scene():
	"""P-6, combat obligatoire, P-7 ; défaite du joueur : réveil au dernier Centre, la scène se
	rejoue (dossier §6, étape 7)."""
	return {"variants": [{"unless": [FAKE_WON, STONE], "steps": [
		{"face": "faux_archeologue", "to": "player"},
		{"face": "player", "to": "faux_archeologue"},
		{"dialogue": "alph_fake_before"},
		{"battle": FAKE_ID, "win": [FAKE_WON]},
		{"wake_up": True, "unless": [FAKE_WON]},
		{"wait": 0.6},
		{"dialogue": "alph_fake_defeated"},
		{"dialogue": "alph_fake_after"},
		{"dialogue": "alph_fake_flees"},
		{"despawn": "faux_archeologue"},
	]}]}


def stone_scene():
	"""P-8 : la Pierre Mémoire, sur le socle (son examen n'existe plus une fois prise)."""
	return {"variants": [{"unless": [STONE], "steps": [
		{"dialogue": "alph_chamber_stone"},
		{"give": "stone_memory", "count": 1},
		{"dialogue": "alph_chamber_stone_received"},
		{"set": [STONE]},
	]}]}


def trainer_entry(name, klass, prize, team):
	entry = {"name": name}
	if klass:
		entry["class"] = klass
	entry.update({"ai": "random", "can_lose": False, "heal_after": False, "gives_exp": True,
		"prize_money": 0, "prize_per_level": prize,
		"team": [{"species": s, "level": lv} for s, lv in team]})
	return entry


def main():
	dialogues = {}
	cutscenes = {}
	for ident, (speaker, lines) in TEXTS.items():
		dialogues[ident] = dialogue(speaker, lines)
	trainers = {FAKE_ID: FAKE_TRAINER}
	for tid, (name, speaker, klass, _sprite, prize, team, lines) in TRAINERS.items():
		trainers[tid] = trainer_entry(name, klass, prize, team)
		for suffix, line in zip(("before", "defeated", "after"), lines):
			dialogues["%s_%s" % (tid, suffix)] = dialogue(speaker or name, [line])
	for map_id in MAPS:
		npcs = {}
		for ident, (kind, cells, attrs) in read_plan(map_id).items():
			cell = list(cells[0])
			if kind == "dresseur" and attrs["trainer"] == FAKE_ID:
				# Jamais de vue : la scène de la rangée 7 le fait parler.
				npcs[ident] = {"cell": cell, "facing": attrs["facing"], "sprite": FAKE_SPRITE,
					"turn_to_player": False, "unless": [FAKE_WON, STONE]}
			elif kind == "dresseur":
				tid = attrs["trainer"]
				npcs[ident] = {"cell": cell, "facing": attrs["facing"], "sprite": TRAINERS[tid][3],
					"dialogue": tid + "_after", "trainer": {"id": tid, "sight": int(attrs["sight"]),
						"before": tid + "_before", "defeated": tid + "_defeated"}}
			elif kind == "pnj":
				npcs[ident] = {"cell": cell, "facing": attrs["facing"], "sprite": "heloise",
					"dialogue": "alph_tent_heloise"}
			elif kind == "objet_visible":
				flag = "got_" + ident
				npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": ident, "verb": "take", "turn_to_player": False, "unless": [flag]}
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = item_scene(ident, attrs["item"], int(attrs.get("count", 1)), flag, True)
			elif kind == "cache":
				flag = "got_" + ident
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = item_scene(ident, attrs["item"], 1, flag, False)
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
	dialogues["alph_tent_heloise"] = {"speaker": "Héloïse", "variants": [
		{"if": [AWAKENED], "pages": pages(HELOISE_END)},
		{"if": [STONE], "set": [MET], "pages": pages(HELOISE_AFTER)},
		{"if": [MET], "pages": pages(HELOISE_WALLS)},
		{"set": [MET], "pages": pages(HELOISE_WELCOME + HELOISE_WALLS)},
	]}
	dialogues["alph_chamber_socle"] = {"cutscene": "alph_chamber_stone"}
	dialogues["route_36_ouvrier"] = {"speaker": "Ouvrier", "variants": [
		{"if": [QUEST], "pages": pages(WORKER_OPEN)}, {"pages": pages(WORKER_CLOSED)}]}
	cutscenes["route_36_ruins_gate"] = worker_gate_scene()
	cutscenes["ruins_of_alph_arrival"] = {"variants": [{"unless": [ARRIVED], "steps": [{"set": [ARRIVED]}]}]}
	cutscenes.update(tile_scenes())
	cutscenes["alph_chamber_fake"] = fake_scene()
	cutscenes["alph_chamber_stone"] = stone_scene()
	write_json(os.path.join(DATA, "trainers", "ruins_of_alph.json"), trainers)
	write_json(os.path.join(DATA, "dialogues", "johp1_alph.json"), dict(sorted(dialogues.items())))
	write_json(os.path.join(DATA, "cutscenes", "johp1_alph.json"), cutscenes)
	write_items()
	write_encounters()
	write_route_36()


def write_items():
	items = {}
	for ident, (name, plural, text) in ITEMS.items():
		items[ident] = {"name": name, "plural": plural, "feminine": True, "category": "key",
			"description": text}
	write_json(os.path.join(DATA, "items", "items_johp.json"), items)


def write_encounters():
	for group, tables in ENCOUNTERS.items():
		out = {}
		for table_id, terrain, periods, rate, (low, high), slots in tables:
			table = {"maps": [group], "terrain": terrain}
			if periods:
				table["period"] = periods
			table["rate"] = rate
			table["ramp"] = {"from_step": 15, "max_steps": 20}
			table["slots"] = [{"species": s, "levels": [low, high], "weight": w} for s, w in slots]
			out[table_id] = table
		write_json(os.path.join(DATA, "encounters", group + ".json"), out)


def write_route_36():
	"""L'ouvrier de la variante ARC (P-42, P-2) rejoint les PNJ de la Route 36 (JOH3)."""
	path = os.path.join(DATA, "npcs", "route_36.json")
	with open(path, encoding="utf-8") as handle:
		npcs = json.load(handle)
	kind, cells, attrs = read_plan("route_36", "POSITIONS_ARC")["ouvrier"]
	npcs["ouvrier"] = {"cell": list(cells[0]), "facing": attrs["facing"], "sprite": "engineer",
		"dialogue": "route_36_ouvrier"}
	write_json(path, npcs)


if __name__ == "__main__":
	main()
