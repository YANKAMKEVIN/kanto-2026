#!/usr/bin/env python3
"""Données de jeu du jalon JOH6 (Tour Cendrée, Routes 42 et 43, Acajou, Lac Colère, repaire),
générées depuis les grilles.

Lit les positions de `tools/plans/burned_tower_1f.txt`, `burned_tower_b1f.txt`, `route_42.txt`,
`mahogany_town.txt`, `mahogany_souvenir_shop.txt`, `route_43.txt`, `lake_of_rage.txt`,
`mahogany_hideout_b1f.txt` à `b3f.txt` (grilles validées le 2026-11-03, elles font foi) et
écrit, d'après `docs/design/dossier-joh-07-acajou.md` (textes C-1 à C-46 §16 validés le
2026-11-02, Dresseurs §6, objets §7, rencontres §5, PNJ de la semaine §11) et le plan
`docs/tech/jalon-joh6.md` §2.3 à §2.5 :
  - `data/npcs/<carte>.json` (Dresseurs, PNJ, objets visibles, acteurs des scènes) ;
  - `data/trainers/<carte>.json` ;
  - `data/encounters/<carte>.json` (tables par moment, eau, cendres) ;
  - `data/dialogues/joh6_<carte>.json`, `joh6_week.json` ;
  - `data/cutscenes/joh6_<carte>.json`, `joh6_week.json` ;
  - `data/shops/mahogany_mart.json`.
Les dialogues et scènes d'HISTOIRE (`joh6_story.json` : chiens, Brace, Léviator rouge, alarmes,
souvenir, Raikou, déserteur…) sont écrits à la main par la session du jalon ; ici seulement les
entrées de PNJ qui les portent. Les textes absents du dossier sont marqués « draft » (relecture de
Kevin) et listés dans `tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Contrat d'identifiants : PNJ = id de la position de la grille ; Dresseur = `<carte>_<position>`
(dialogues `_before`, `_defeated`, `_after`) ; objet : dialogue et scène `<carte>_<position>`,
drapeau `got_<carte>_<position>` ; panneau, examen : dialogue `<carte>_<position>`.

Usage : python3 -I tools/gen_joh6_data.py   (relancer après un changement de grille ou de texte)
"""

import importlib.util
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("gen_joh2_data", os.path.join(HERE, "gen_joh2_data.py"))
J2 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(J2)

DATA = J2.DATA
WEEKDAYS = J2.WEEKDAYS
NARRATION = None

# Grille → identifiant de carte.
MAPS = [(name, name) for name in (
	"burned_tower_1f", "burned_tower_b1f", "route_42", "mahogany_town", "mahogany_souvenir_shop",
	"route_43", "lake_of_rage", "mahogany_hideout_b1f", "mahogany_hideout_b2f", "mahogany_hideout_b3f")]

# Types de position sans donnée ici (géométrie, décors, scènes d'histoire écrites à la main).
NO_DATA_KINDS = {"warp", "spawn", "escalier", "trou", "declencheur", "repere", "herbes", "rencontre",
	"decor", "statue", "dalle", "porte_cle", "interrupteur"}

WIDTH = 32
_AFTER_PUNCT = {"?", "!", ":", ";", "»"}


def wrap(text, width=WIDTH):
	"""Coupe `text` en lignes d'au plus `width` caractères (équilibrées si la dernière ligne est
	orpheline), sans ligne qui commence par « ? » ou « ! »."""
	lines = _greedy(text, width)
	if len(lines) > 1 and len(lines[-1]) < 12:  # dernière ligne orpheline : on équilibre
		while width > 8 and len(_greedy(text, width - 1)) == len(lines):
			width -= 1
		lines = _greedy(text, width)
	return lines


def _greedy(text, width):
	tokens = []
	for word in text.split(" "):
		if tokens and word in _AFTER_PUNCT:
			tokens[-1] += " " + word
		elif tokens and tokens[-1] == "«":
			tokens[-1] += " " + word
		else:
			tokens.append(word)
	lines = []
	current = ""
	for token in tokens:
		if current and len(current) + 1 + len(token) > width:
			lines.append(current)
			current = token
		else:
			current = current + " " + token if current else token
	if current:
		lines.append(current)
	return lines


def pages_of(text):
	"""Une bulle du dossier → pages de 2 lignes au plus (≈ 32 caractères), coupées de préférence
	entre deux phrases."""
	sentences = re.split(r"(?<=[.!?])\s+", text.strip())
	pages = []
	current = ""
	for sentence in sentences:
		candidate = current + " " + sentence if current else sentence
		if len(wrap(candidate)) <= 2:
			current = candidate
			continue
		if current:
			pages.append("\n".join(wrap(current)))
			current = ""
		lines = wrap(sentence)
		if len(lines) <= 2:
			current = sentence
		else:
			for i in range(0, len(lines), 2):
				pages.append("\n".join(lines[i:i + 2]))
	if current:
		pages.append("\n".join(wrap(current)))
	return pages


def bubbles(text):
	"""Texte du dossier (bulles séparées par « / ») → pages."""
	out = []
	for bubble in text.split(" / "):
		out.extend(pages_of(bubble))
	return out


def panel(title, rest):
	"""Panneau en grand : titre puis texte dans une seule page (comme au JOH2)."""
	return ["%s\n%s" % (title, "\n".join(wrap(rest, 30)))]


# --- Textes (dossier joh-07 §16, mot pour mot) ; C-1 à C-3, C-11 (fin) et C-12 : Rosalia, voir
# `gen_joh2_data.py` ---------------------------------------------------------------------------
C5 = bubbles("Le plancher a brûlé. / On voit une salle, en dessous.")
C13 = panel("ROUTE 42", "Rosalia — Acajou")
C14 = bubbles("Un éboulement bloque l'entrée. / Le passage est fermé.")
C16 = panel("ACAJOU", "La ville des montagnes et des vieux secrets")
C17 = bubbles("Tu as vu l'homme en noir, tout à l'heure ? Il traînait une cage qui crépitait. / Il est entré "
	"quelque part en ville, mais où ?")
C18 = bubbles("Au Lac Colère, au nord, les Magicarpe sont devenus fous. / Ils évoluent tous en Léviator, et "
	"ils sont furieux.")
C19 = bubbles("Bienvenue ! Des souvenirs d'Acajou ? / … Non ? Alors ne traîne pas, je ferme bientôt.")
C29 = bubbles("Hé ! Qui t'a permis de… / … Tant pis. De toute façon, Brace t'attend.")
C20 = panel("ROUTE 43", "Acajou — Lac Colère")
C24 = panel("LAC COLÈRE", "Ne pas déranger les Pokémon du lac")
C26 = bubbles("Tu l'as calmé ? Bravo ! / Ce Léviator était un Magicarpe, il y a dix jours. / Des ondes viennent "
	"d'Acajou et forcent les Magicarpe à évoluer. / J'ai vu une antenne sur le toit de la boutique de "
	"souvenirs. Drôle d'endroit pour une antenne, non ?")
LAKE_MAD = ["Le lac est fou."]  # texte de la grille lake_of_rage.txt (pêcheur, avant le Léviator rouge)
A1 = bubbles("La montagne est fermée. / Là-haut, la neige ne pardonne pas.")
A2 = bubbles("Le Mont Argenté ? Des hommes en noir y sont montés cette nuit. / Je n'ai pas pu les arrêter. "
	"Toi, peut-être. Passe.")
C39 = bubbles("Une énorme machine bourdonne. / Des câbles partent de la cage de Raikou. / Raikou sert de pile "
	"à la machine !")

# Textes [D] hors dossier (draft) : étagère de la boutique (sans le lac : rien à voir), habitants
# des maisons d'Acajou.
SHELF = ["Des cartes postales et des\nporte-clés d'Acajou."]
HOUSE_1 = bubbles("Depuis une semaine, la radio grésille toute la journée. / Ça vient de quelque part en "
	"ville, je crois.")
HOUSE_2_A = bubbles("Acajou était un village bien tranquille. / Jusqu'à cette semaine.")
HOUSE_2_B = bubbles("Mon petit-fils dit que les Magicarpe sont furieux.")

# Textes à la place (carte, position) : (orateur, pages[, brouillon]).
TEXTS = {
	("burned_tower_1f", "plancher_effondre"): (NARRATION, C5),
	("route_42", "panneau"): (NARRATION, C13),
	("route_42", "porte_mont_creuset"): (NARRATION, C14),
	("mahogany_town", "panneau_ville"): (NARRATION, C16),
	("mahogany_town", "habitant"): ("Habitant", C17),
	("mahogany_town", "habitante"): ("Habitante", C18),
	("route_43", "panneau"): (NARRATION, C20),
	("lake_of_rage", "panneau"): (NARRATION, C24),
	("mahogany_hideout_b3f", "generateur"): (NARRATION, C39),
	("mahogany_souvenir_shop", "etagere"): (NARRATION, SHELF, True),
}
# Les textes de Rosalia (C-1 à C-3, C-11, C-12 : sage, doyen, panneau, garde) sont écrits par
# `gen_joh2_data.py`, qui génère la ville.

# --- Dresseurs (dossier §6 ; prize_per_level [D] : 40 ordinaires, 45 Sbires et Scientifique, 60 Brace) --

# id → (nom, classe de combat ou None, sprite, prix par niveau, IA, équipe, orateur, répliques)
# `répliques` = (avant, défaite, après), chacune au format du dossier (bulles séparées par « / »).
SBIRE_M, SBIRE_F = "rocket_grunt_m", "rocket_grunt_f"
SBIRE = "Sbire Rocket"
TRAINERS = {
	"burned_tower_1f": {
		"odile": ("Médium Odile", "exorciste", "channeler", 40, "random", [("haunter", 46), ("gengar", 48)],
			"Médium Odile", ("Les esprits de la tour n'aiment pas les visiteurs.",
				"Ils t'acceptent, finalement.", "En bas, quelque chose respire.")),
		"sbire_p": (SBIRE, "sbire_rocket", SBIRE_M, 45, "random", [("weezing", 48), ("raticate", 48)],
			"Sbire", ("Le patron veut ce qui dort en bas. Dégage !", "Le patron va être furieux.",
				"De toute façon, Brace est déjà en route.")),
	},
	"route_42": {
		"hector": ("Montagnard Hector", None, "mountaineer", 40, "random", [("golem", 48), ("onix", 47)],
			"Montagnard Hector", ("Les montagnes forgent les Pokémon !", "Ils étaient mal forgés.",
				"Le Mont Creuset est fermé depuis l'éboulement.")),
		"marcel": ("Pêcheur Marcel", None, "fisher_route_12", 40, "random",
			[("gyarados", 47), ("tentacruel", 46)], "Pêcheur Marcel",
			("Le lac est à moi aujourd'hui !", "Bon, partageons.", "À Acajou, les poissons deviennent bizarres.")),
		"coralie": ("Nageuse Coralie", None, "swimmer_f_water", 40, "random",
			[("azumarill", 48), ("staryu", 46)], "Nageuse Coralie",
			("Tu nages bien ? Voyons ça !", "Tu nages mieux que moi.", "Acajou est juste après le lac.")),
		"louis": ("Super Nerd Louis", "intello", "nerd", 40, "random",
			[("magneton", 47), ("electrode", 47)], "Super Nerd Louis",
			("Mes Pokémon captent des ondes étranges depuis une semaine !", "Les ondes m'ont déconcentré.",
				"Elles viennent de l'est. D'Acajou, peut-être.")),
	},
	"route_43": {
		"peager": ("Sbire péager", "sbire_rocket", SBIRE_M, 45, "random",
			[("houndoom", 54), ("weezing", 53)], "Sbire",
			("Tu veux passer sans payer ? Chez nous, ça se règle en combat.",
				"Le péage est fermé. Définitivement.",
				"Va voir le lac, si ça t'amuse. Les ondes, c'est notre œuvre.")),
		"sbire_q": (SBIRE, "sbire_rocket_f", SBIRE_F, 45, "random", [("arbok", 52), ("golbat", 52)],
			"Sbire", ("Péage ! 1 000 Pokédollars pour passer. Ou tes Pokémon.", "Bon, c'est gratuit aujourd'hui.",
				"Le péager, devant, ne rigole pas.")),
		"basile": ("Campeur Basile", None, "camper", 40, "random", [("nidoking", 52), ("fearow", 51)],
			"Campeur Basile", ("La route du lac est à moi !", "Elle est à toi.",
				"Au milieu du lac, il y a un Léviator rouge. Rouge !")),
	},
	"lake_of_rage": {
		"ludovic": ("Pêcheur Ludovic", None, "fisher_route_12", 40, "random",
			[("gyarados", 52), ("lapras", 51)], "Pêcheur Ludovic",
			("Le lac est calme, enfin. Un combat pour fêter ça ?", "Bien joué.",
				"Les Léviator reviendront à la normale, j'espère.")),
	},
	"mahogany_hideout_b1f": {
		"sbire_alarme_1": (SBIRE, "sbire_rocket", SBIRE_M, 45, "random", [("raticate", 55), ("arbok", 55)],
			"Sbire", ("Intrus ! Pas un pas de plus !", "Coupez l'alarme…", "Tu ne sortiras pas d'ici.")),
		"sbire_alarme_2": (SBIRE, "sbire_rocket_f", SBIRE_F, 45, "random", [("muk", 56)],
			"Sbire", ("Intrus ! Pas un pas de plus !", "Coupez l'alarme…", "Tu ne sortiras pas d'ici.")),
		"sbire_alarme_3": (SBIRE, "sbire_rocket", SBIRE_M, 45, "random", [("houndour", 55), ("golbat", 56)],
			"Sbire", ("Intrus ! Pas un pas de plus !", "Coupez l'alarme…", "Tu ne sortiras pas d'ici.")),
	},
	"mahogany_hideout_b2f": {
		"sbire_r": (SBIRE, "sbire_rocket", SBIRE_M, 45, "random", [("weezing", 57), ("magneton", 56)],
			"Sbire", ("Dante a dit : personne ne passe.", "Dante ne va pas aimer ça.",
				"Moi, j'ai choisi Dante. Les autres sont partis, les lâches.")),
		"sbire_s": (SBIRE, "sbire_rocket_f", SBIRE_F, 45, "random", [("houndoom", 57), ("murkrow", 56)],
			"Sbire", ("On n'est plus pour Giovanni. On est pour Dante !", "Pour Dante… aïe.",
				"Il a un plan. Un vrai.")),
		"scientifique": ("Scientifique Rocket", None, "researcher", 45, "random",
			[("electrode", 57), ("magneton", 57), ("porygon", 56)], "Scientifique",
			("Mes ondes sont parfaites ! Tu ne toucheras pas à la porte !", "Erreur de mesure.",
				"Le mot de passe ? Je ne le dirai jamais. Jamais !")),
	},
	"mahogany_hideout_b3f": {
		"brace": ("Brace", "sbire_rocket", "rocket_grunt_m", 60, "smart",
			[("fearow", 60), ("arbok", 60), ("weezing", 61), ("houndoom", 62)], "Brace",
			("Encore toi ! Tu me suis partout ! / Tant mieux. Au puits, tu avais des Pokémon de rien du "
				"tout. / Montre-moi tes vrais Pokémon. Je fonce !", "Non, non, non ! Pas encore !",
				"Ta victoire ne change rien.")),
	},
}
# Dresseurs déclenchés par une scène, pas par la vue (contrat) : alarme du B1F (sight 0, présents
# une fois l'alarme posée) ; Brace du B3F (pas de bloc « trainer » sur l'entrée de PNJ).
ALARM_FLAGS = {"sbire_alarme_1": "johto_alarm_1", "sbire_alarme_2": "johto_alarm_2",
	"sbire_alarme_3": "johto_alarm_3"}
SCENE_TRAINERS = {("mahogany_hideout_b3f", "brace")}

# --- Rencontres (dossier §5) : (identifiant, moments, terrain, taux, rampe, créneaux) -----------

RAMP = {"from_step": 15, "max_steps": 20}
ENCOUNTERS = {
	"burned_tower_1f": [
		("burned_tower_1f_floor", None, "floor", 15, False, [("raticate", 40, 44, 30),
			("golbat", 40, 44, 25), ("weezing", 40, 44, 20), ("haunter", 40, 44, 15), ("magmar", 40, 44, 10)]),
	],
	"route_42": [
		("route_42_grass_day", ["morning", "day"], "grass", 25, True, [("furret", 40, 45, 30),
			("pidgeotto", 40, 45, 20), ("gloom", 40, 45, 20), ("marill", 40, 45, 15), ("fearow", 40, 45, 15)]),
		("route_42_grass_night", ["night"], "grass", 25, True, [("noctowl", 40, 45, 35),
			("golbat", 40, 45, 25), ("gloom", 40, 45, 20), ("marill", 40, 45, 20)]),
		("route_42_water", None, "water", 10, False, [("marill", 40, 45, 60), ("azumarill", 40, 45, 10),
			("tentacruel", 40, 45, 30)]),
	],
	"route_43": [
		("route_43_grass_day", ["morning", "day"], "grass", 25, True, [("furret", 44, 48, 25),
			("nidorino", 44, 48, 20), ("nidorina", 44, 48, 20), ("pidgeotto", 44, 48, 15),
			("venomoth", 44, 48, 20)]),
		("route_43_grass_night", ["night"], "grass", 25, True, [("noctowl", 44, 48, 30),
			("houndoom", 44, 48, 20), ("nidorino", 44, 48, 15), ("nidorina", 44, 48, 15),
			("venomoth", 44, 48, 20)]),
	],
	"lake_of_rage": [
		("lake_of_rage_grass_day", ["morning", "day"], "grass", 25, True, [("nidorino", 45, 50, 25),
			("nidorina", 45, 50, 25), ("furret", 45, 50, 25), ("pidgeotto", 45, 50, 25)]),
		("lake_of_rage_grass_night", ["night"], "grass", 25, True, [("sneasel", 45, 50, 20),
			("noctowl", 45, 50, 30), ("houndoom", 45, 50, 20), ("venomoth", 45, 50, 30)]),
		("lake_of_rage_water", None, "water", 10, False, [("magikarp", 45, 50, 50), ("marill", 45, 50, 20),
			("azumarill", 45, 50, 10), ("gyarados", 45, 50, 20)]),
	],
}

# --- PNJ de la semaine (dossier §11, C-46) ----------------------------------------------------

WEEK = {
	# id : (orateur, drapeau, jour, objet, nombre, pages avant, ligne système, page après)
	"week_saturday_samuel": ("Samuel", "week_saturday_gift", "saturday", "hyper_potion", 3,
		bubbles("Le samedi, je guide les randonneurs dans la montagne. / Tiens, en montagne, on n'en a "
			"jamais trop."),
		"{player} reçoit 3 Hyper Potions !", "À samedi, sur les sentiers !"),
	"week_sunday_diane": ("Diane", "week_sunday_gift", "sunday", "max_revive", 1,
		bubbles("Le dimanche, je sonne les cloches de Rosalia. / Elles réveillent les cœurs endormis. "
			"Prends ceci."),
		"{player} reçoit un Rappel Max !", "Reviens un dimanche écouter les cloches."),
}

# Boutique de souvenirs d'Acajou [D] (dossier : « Boutique » non détaillée).
MART_STOCK = ["ultra_ball", "hyper_potion", "max_potion", "full_heal", "revive", "max_repel", "escape_rope"]

# Habitants des maisons d'Acajou ([D], grilles de Lavanville réutilisées) : texte en draft.
# Centre : infirmière devant la machine, déserteur (C-45) à une case libre de la salle [D].
CENTER_DESERTER_CELL = [11, 5]


def trainer_json(name, cls, prize, ai, team):
	entry = {"name": name}
	if cls:
		entry["class"] = cls
	entry.update({"ai": ai, "can_lose": False, "heal_after": False, "gives_exp": True,
		"prize_money": 0, "prize_per_level": prize,
		"team": [{"species": species, "level": level} for species, level in team]})
	return entry


def lines_dialogues(tid, speaker, lines):
	"""Dialogues `_before`, `_defeated`, `_after` d'un Dresseur."""
	out = {}
	for suffix, text in zip(("before", "defeated", "after"), lines):
		out["%s_%s" % (tid, suffix)] = J2.dialogue(speaker, bubbles(text))
	return out


def main():
	for plan, map_id in MAPS:
		positions = J2.read_plan(plan)
		npcs = {}
		dialogues = {}
		cutscenes = {}
		trainers = {}
		for ident, (kind, cells, attrs, comment) in positions.items():
			cell = list(cells[0])
			key = (map_id, ident)
			if kind == "dresseur":
				name, cls, sprite, prize, ai, team, speaker, lines = TRAINERS[map_id][ident]
				tid = "%s_%s" % (map_id, ident)
				trainers[tid] = trainer_json(name, cls, prize, ai, team)
				dialogues.update(lines_dialogues(tid, speaker, lines))
				if key in SCENE_TRAINERS:
					# Brace (B3F) : l'entrée de PNJ n'a pas de bloc « trainer » (scène `hideout_brace`).
					npcs[ident] = {"cell": cell, "facing": attrs["facing"], "sprite": sprite,
						"unless": ["johto_brace_defeated_2"], "dialogue": tid + "_after"}
					continue
				entry = {"cell": cell, "facing": attrs["facing"], "sprite": sprite}
				if ident in ALARM_FLAGS:
					entry["if"] = [ALARM_FLAGS[ident]]
				entry["dialogue"] = tid + "_after"
				entry["trainer"] = {"id": tid, "sight": int(attrs["sight"]), "before": tid + "_before",
					"defeated": tid + "_defeated"}
				npcs[ident] = entry
			elif kind == "objet_visible":
				flag = "got_%s_%s" % (map_id, ident)
				sid = "%s_%s" % (map_id, ident)
				npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": sid, "verb": "take", "turn_to_player": False, "unless": [flag]}
				dialogues[sid] = {"cutscene": sid}
				cutscenes[sid] = J2.item_scene(ident, attrs["item"], int(attrs.get("quantite", 1)),
					flag, True)
			elif kind == "cache":
				flag = "got_%s_%s" % (map_id, ident)
				sid = "%s_%s" % (map_id, ident)
				dialogues[sid] = {"cutscene": sid}
				cutscenes[sid] = J2.item_scene(ident, attrs["item"], int(attrs.get("quantite", 1)),
					flag, False)
			elif kind in ("panneau", "examen"):
				dialogues["%s_%s" % (map_id, ident)] = J2.dialogue(*TEXTS[key])
			elif kind in ("pnj", "pokemon"):
				handle_npc(map_id, ident, cell, attrs, npcs, dialogues, cutscenes)
			elif kind == "declencheur" and key in TEXTS:
				# Déclencheur à texte seul (C-5 : plancher effondré, scène écrite à la main).
				dialogues["%s_%s" % (map_id, ident)] = J2.dialogue(*TEXTS[key])
			elif kind == "declencheur" and map_id == "lake_of_rage" and ident == "barriere_sentier":
				pass  # scène `lake_trail_guard` (tools/gen_joh6_story.py)
			elif kind not in NO_DATA_KINDS:
				raise ValueError("type de position non géré : %s %s %s" % (map_id, ident, kind))
		# Péage (C-22, dossier §4 étape 7) : la défaite du péager pose `johto_toll_cleared`.
		toll = dialogues.get("route_43_peager_defeated")
		if toll is not None:
			dialogues["route_43_peager_defeated"] = {"speaker": toll["speaker"], "variants": [
				{"set": ["johto_toll_cleared"], "pages": toll["pages"]}]}
		J2.write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)
		if dialogues:
			J2.write_json(os.path.join(DATA, "dialogues", "joh6_%s.json" % map_id), dialogues)
		if cutscenes:
			J2.write_json(os.path.join(DATA, "cutscenes", "joh6_%s.json" % map_id), cutscenes)
		if trainers:
			J2.write_json(os.path.join(DATA, "trainers", map_id + ".json"), trainers)
		if map_id in ENCOUNTERS:
			write_encounters(map_id)
	write_interiors()
	write_week()
	write_shop()


def handle_npc(map_id, ident, cell, attrs, npcs, dialogues, cutscenes):
	"""PNJ simples et acteurs d'histoire (positions `pnj` et `pokemon` des grilles)."""
	key = (map_id, ident)
	facing = attrs.get("facing", "down")
	did = "%s_%s" % (map_id, ident)
	if key == ("burned_tower_b1f", "brace"):
		return  # surgit pendant la scène (étape `spawn`) : aucune entrée de PNJ
	if map_id == "burned_tower_b1f" and ident in ("raikou", "entei", "suicune"):
		npcs[ident] = {"cell": cell, "facing": "down", "sprite": "pokemon/" + ident,
			"turn_to_player": False, "unless": ["johto_beasts_awakened"]}
	elif key == ("mahogany_town", "samuel"):
		npcs[ident] = {"cell": cell, "facing": facing, "sprite": "mountaineer",
			"dialogue": "week_saturday_samuel", "if_weekday": ["saturday"]}
	elif key in (("mahogany_town", "habitant"), ("mahogany_town", "habitante")):
		npcs[ident] = {"cell": cell, "facing": facing,
			"sprite": "old_man" if ident == "habitant" else "beauty", "dialogue": did}
		dialogues[did] = J2.dialogue(*TEXTS[key])
	elif key == ("mahogany_souvenir_shop", "vendeur"):
		npcs[ident] = {"cell": cell, "facing": facing, "sprite": "clerk", "dialogue": did}
		dialogues[did] = {"speaker": "Vendeur", "variants": [
			{"unless": ["johto_hideout_found"], "pages": C19, "action": "open_shop", "shop": "mahogany_mart"},
			{"if": ["johto_hideout_found"], "pages": C29},
		]}
	elif key == ("lake_of_rage", "leviator_rouge"):
		npcs[ident] = {"cell": cell, "facing": "down", "sprite": "pokemon/gyarados_red",
			"dialogue": "joh6_red_gyarados", "turn_to_player": False, "unless": ["johto_red_gyarados_done"]}
	elif key == ("lake_of_rage", "pecheur"):
		npcs[ident] = {"cell": cell, "facing": facing, "sprite": "fisher_fuchsia", "dialogue": did}
		dialogues[did] = {"speaker": "Pêcheur", "variants": [
			{"if": ["johto_red_gyarados_done"], "pages": C26},
			{"pages": LAKE_MAD},
		]}
	elif key == ("lake_of_rage", "garde_forestier"):
		npcs[ident] = {"cell": cell, "facing": facing, "sprite": "guard", "dialogue": did}
		dialogues[did] = {"speaker": "Garde forestier", "variants": [
			{"unless": ["johto_act3"], "pages": A1},
			{"if": ["johto_act3"], "pages": A2},
		]}
	elif key == ("mahogany_hideout_b2f", "deserteur"):
		npcs[ident] = {"cell": cell, "facing": facing, "sprite": "rocket_grunt_m",
			"dialogue": "joh6_deserter", "unless": ["johto_raikou_done"]}
	elif key == ("mahogany_hideout_b3f", "raikou"):
		npcs[ident] = {"cell": cell, "facing": "down", "sprite": "pokemon/raikou",
			"dialogue": "joh6_raikou", "turn_to_player": False, "unless": ["johto_raikou_done"]}
	else:
		raise ValueError("PNJ non géré : %s %s" % (map_id, ident))


def write_encounters(map_id):
	tables = {}
	for table_id, periods, terrain, rate, ramp, slots in ENCOUNTERS[map_id]:
		table = {"maps": [map_id], "terrain": terrain}
		if periods:
			table["period"] = periods
		table["rate"] = rate
		if ramp:
			table["ramp"] = dict(RAMP)
		table["slots"] = [{"species": s, "levels": [lo, hi], "weight": w} for s, lo, hi, w in slots]
		tables[table_id] = table
	J2.write_json(os.path.join(DATA, "encounters", map_id + ".json"), tables)


def write_interiors():
	"""Centre d'Acajou (infirmière, déserteur de C-45 après Raikou) et maisons [D]."""
	J2.write_json(os.path.join(DATA, "npcs", "mahogany_center.json"), {
		"nurse": {"cell": [7, 3], "facing": "down", "sprite": "nurse"},
		"deserteur": {"cell": list(CENTER_DESERTER_CELL), "facing": "left", "sprite": "rocket_grunt_m",
			"dialogue": "joh6_deserter_center", "if": ["johto_raikou_done"]},
	})
	J2.write_json(os.path.join(DATA, "npcs", "mahogany_house_1.json"), {
		"habitante": {"cell": [12, 6], "facing": "left", "sprite": "beauty",
			"dialogue": "mahogany_house_1_habitante"},
	})
	J2.write_json(os.path.join(DATA, "dialogues", "joh6_mahogany_house_1.json"), {
		"mahogany_house_1_habitante": J2.dialogue("Habitante", HOUSE_1, True)})
	J2.write_json(os.path.join(DATA, "npcs", "mahogany_house_2.json"), {
		"habitant_1": {"cell": [4, 5], "facing": "right", "sprite": "old_man",
			"dialogue": "mahogany_house_2_habitant_1"},
		"habitant_2": {"cell": [5, 6], "facing": "left", "sprite": "old_man",
			"dialogue": "mahogany_house_2_habitant_2"},
	})
	J2.write_json(os.path.join(DATA, "dialogues", "joh6_mahogany_house_2.json"), {
		"mahogany_house_2_habitant_1": J2.dialogue("Habitant", HOUSE_2_A, True),
		"mahogany_house_2_habitant_2": J2.dialogue("Habitant", HOUSE_2_B, True)})


def write_week():
	"""Samuel (samedi, Acajou) et Diane (dimanche, Rosalia) : textes et scènes ici, PNJ posés par les
	cartes (`data/npcs/mahogany_town.json`, `ecruteak_city.json`). Don une seule fois."""
	dialogues = {}
	cutscenes = {}
	for did, (speaker, flag, _day, item, count, before, system, after) in WEEK.items():
		received_id = flag.replace("_gift", "_received")
		dialogues[did] = {"speaker": speaker, "variants": [
			{"unless": [flag], "cutscene": flag, "pages": before},
			{"if": [flag], "pages": bubbles(after)},
		]}
		dialogues[received_id] = J2.dialogue(NARRATION, [system])
		cutscenes[flag] = J2.week_scene(flag, item, count, received_id)
	J2.write_json(os.path.join(DATA, "dialogues", "joh6_week.json"), dialogues)
	J2.write_json(os.path.join(DATA, "cutscenes", "joh6_week.json"), cutscenes)


def write_shop():
	J2.write_json(os.path.join(DATA, "shops", "mahogany_mart.json"), {
		"mahogany_mart": {"stock": [{"item": item} for item in MART_STOCK]}})


if __name__ == "__main__":
	main()
