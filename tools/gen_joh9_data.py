#!/usr/bin/env python3
"""Données de jeu du jalon JOH9 (Mont Argenté, Route 28, épilogue), générées depuis les grilles.

Lit les positions de `tools/plans/silver_trail.txt`, `mt_silver_outside.txt`, `mt_silver_1f.txt`,
`mt_silver_2f.txt`, `mt_silver_3f.txt`, `mt_silver_summit.txt`, `route_28.txt`, `route_28_gate.txt`
(grilles validées le 2026-11-03, elles font foi) et écrit, d'après
`docs/design/dossier-joh-10-mont-argente.md` (textes A-1 à A-54 validés le 2026-11-02, Dresseurs §6,
rival §9, rencontres §5, drapeaux §12) et le plan `docs/tech/jalon-joh9.md` :
  - `data/npcs/<carte>.json` (Dresseurs, PNJ, intérieurs) ;
  - `data/trainers/joh9.json` (Dresseurs, Dante (2), rival final) ;
  - `data/encounters/<carte>.json` (tables par moment) ;
  - `data/dialogues/joh9_<lot>.json`, `data/cutscenes/joh9_<lot>.json`.
Les textes absents du dossier sont marqués « draft » et listés dans
`tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Usage : python3 -I tools/gen_joh9_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

NARRATION = None
RIVAL = "{rival}"

# Drapeaux du dossier §12, et deux drapeaux de travail [D] (plan §2.3).
RELAY = "johto_rival_relay"
HEALED = "johto_rival_healed"
DANTE_WON = "johto_dante_defeated_2"
GIOVANNI = "johto_giovanni_seen"
RIVAL_DONE = "johto_rival_final_done"
ROUTE28 = "johto_route28_open"
CHAPTER = "johto_chapter_done"
CELEBI = "johto_celebi_done"
SUMMIT_REACHED = "johto_summit_reached"      # [D] : A-23 et A-26 à A-28 une seule fois (A-25 ensuite)
RIVAL_MET = "johto_rival_final_met"          # [D] : A-40, A-41 une seule fois (A-45 ensuite)
GREEN_BALL = "johto_green_ball_received"     # [D] : la Balle Verte reçue (A-50)
WIND = "johto_mt_silver_wind_seen"           # [D] : A-22 une fois (entrée de la salle du vent)


def wrap(text, width=36):
	"""Bulle → lignes d'au plus [width] caractères (retours « \\n », comme le JOH2)."""
	words = text.split(" ")
	lines = []
	line = ""
	for word in words:
		if line and len(line) + 1 + len(word) > width:
			lines.append(line)
			line = word
		else:
			line = word if not line else line + " " + word
	if line:
		lines.append(line)
	return "\n".join(lines)


def pages(text):
	"""« / » du dossier = bulle."""
	return [wrap(part.strip()) for part in text.split(" / ")]


def dialogue(speaker, text, draft=False, **extra):
	entry = {}
	if speaker:
		entry["speaker"] = speaker
	else:
		entry["narration"] = True
	if draft:
		entry["draft"] = True
	entry.update(extra)
	entry["pages"] = pages(text) if isinstance(text, str) else text
	return entry


# --- Textes du dossier §16 (mot pour mot) ----------------------------------------------------

A = {
	"A-1": "La montagne est fermée. / Là-haut, la neige ne pardonne pas.",
	"A-2": "Le Mont Argenté ? Des hommes en noir y sont montés cette nuit. / Je n'ai pas pu les arrêter. Toi, peut-être. Passe.",
	"A-3": "MONT ARGENTÉ / Réservé aux Dresseurs confirmés.",
	"A-8": "Le revoilà, le gamin ! / Cette fois, tu ne passes pas. Le patron finit son œuvre là-haut.",
	"A-9": "Six contre un. J'ai refait le calcul trois fois. / Tu ne passeras pas.",
	"A-10a": "Six contre un ? Refais ton calcul.",
	"A-10b": "{rival} arrive en courant !",
	"A-11": "Chen m'a tout raconté. La radio, le vol, la tour. / Ne me regarde pas comme ça. Je ne fais pas ça pour toi. / Je fais ça parce que personne ne vole l'équipe du Maître de Kanto. Personne, à part moi, un jour.",
	"A-12": "Allez, {pokemon} ! On s'occupe d'eux. / {joueur}, monte. Va finir ça.",
	"A-13": "{joueur} entre dans la grotte. / Derrière, on entend les cris des Pokémon…",
	"A-15": "Un gros rocher. On pourrait le pousser.",
	"A-16": "Il fait noir comme dans un four.",
	"A-17": "{pokemon} éclaire la grotte avec Flash !",
	"A-19": "Quelqu'un court dans le noir… / {rival} rattrape {joueur} !",
	"A-20": "Pff… Pff… Tu marches vite. / L'impétueux, je l'ai coincé. L'Agente arrive pour lui. / La froide a filé. Elle monte, elle aussi. Fais attention.",
	"A-21a": "Tes Pokémon sont dans un état… Tiens. / Je ne veux pas que tu perdes avant notre combat.",
	"A-21b": "L'équipe de {joueur} est soignée.",
	"A-21c": "Je redescends surveiller l'entrée. Ne t'avise pas de tomber.",
	"A-22": "Un vent glacé souffle dans la grotte. / La lumière vient d'en haut.",
	"A-23": "Le ciel est immense. / Les nuages s'étendent sous les pieds de {joueur}. / Un homme attend au milieu des ruines.",
	"A-24": "De vieilles pierres noircies, à moitié enterrées sous la neige. / Un « R » est gravé sur l'une d'elles.",
	"A-25": "Encore toi. / Ici, on ne redescend qu'une fois.",
	"A-26": "Ici, il y a quarante ans, j'ai planté la première tente de la Team Rocket. / Trois hommes, une idée, et la neige. / C'est ici que tout a commencé. C'est ici que tout finira.",
	"A-27": "Ho-Oh m'a regardé, et il t'a choisi. / J'ai compris ce matin-là. Je n'ai plus de flamme à prendre. / Il ne me reste que la mienne.",
	"A-28": "Tu as tout ce que j'ai perdu, {joueur}. Des Pokémon qui te suivent. Un nom. Un avenir. / Alors montre-moi. / Montre-moi ce que vaut un cœur que personne n'a trahi.",
	"A-29": "… / Je vois. / Il n'y avait pas de feu assez grand pour toi.",
	"A-30": "Vingt ans à attendre ce jour. Vingt ans à brûler de l'intérieur. / Et c'est un enfant qui éteint tout. / … C'est peut-être mieux ainsi.",
	"A-31": "Des pas crissent dans la neige. / Un homme apparaît derrière les ruines.",
	"A-32": "Dante. / Je savais que tu reviendrais ici. Tout le monde finit par revenir ici.",
	"A-33": "… Giovanni. / Tu viens voir ton œuvre ? Regarde-moi bien. Tu as fait ça.",
	"A-34": "Oui. / Tu m'as appris que rien ne doit se mettre en travers. Pas même un maître. / J'ai bien appris. Je l'ai payé, moi aussi.",
	"A-35": "La Team Rocket est morte, Dante. Celle d'hier, et celle que tu as voulu ranimer. / Un enfant l'a battue deux fois. Il n'y en aura pas de troisième. / Je ne suis pas venu la reprendre. Ni te demander pardon.",
	"A-36": "Toi. / À Jadielle, je t'ai dit que nos chemins se croiseraient peut-être. / Je m'entraîne ici depuis. Seul. Un jour, je serai de nouveau digne d'un combat contre toi. Pas aujourd'hui.",
	"A-37": "Giovanni s'éloigne dans la neige, sans se retourner.",
	"A-38a": "Cenere arrive en courant.",
	"A-38b": "Maître… / … Je reste. Les calculs, c'est fini. Je reste.",
	"A-39": "Dante ne répond pas. Il regarde les nuages. / Cenere s'agenouille à côté de lui.",
	"A-40": "Ouf. J'ai cru que je n'arriverais jamais. / Alors ? C'est fini ? / … Bien.",
	"A-41": "Tu sais pourquoi je suis monté jusqu'ici ? / Pas pour lui. Pour toi. / Depuis la Ligue, je m'entraîne. Et j'ai trouvé de quoi faire évoluer mon Onix, à Johto. / Toi et moi, ce n'est pas fini.",
	"A-42": "… Encore. / Bon. Je crois que je commence à m'y faire.",
	"A-43": "Tu sais, à la Ligue, je t'en ai voulu. / Mais là, en bas, quand je retenais ces deux-là… / J'étais content que ce soit toi, là-haut. Ne le répète à personne.",
	"A-44": "L'Agente a embarqué l'impétueux, en bas. / Pour ces deux-là… Laissons-les. Ils n'iront plus nulle part.",
	"A-45": "Te revoilà. / On reprend. Et cette fois, pas d'excuse.",
	"A-46a": "On rentre ? Par l'ouest, la Route 28 mène tout droit chez nous. / Dernier arrivé à Bourg Palette paie le dîner !",
	"A-46b": "{rival} s'en va en courant.",
	"A-47": "La porte s'ouvre. / Devant {joueur}, la Route 22. Kanto !",
	"A-48": "Le col vers le Mont Argenté est fermé. / Trop dangereux.",
	"A-49": "{joueur} ! Te voilà rentré ! / Orme m'a tout raconté. Johto te doit beaucoup. / Moi, je savais que tu reviendrais. Tu reviens toujours.",
	"A-50a": "Le Maître de Kanto a sauvé Johto. Je l'écrirai dans mon prochain livre ! / J'ai quelque chose pour toi. Je l'ai trouvé chez un antiquaire d'Écorcia. / Une Balle Verte. Très ancienne. Les gens de là-bas disent qu'elle appartient au Bois aux Chênes.",
	"A-50b": "{joueur} reçoit la Balle Verte !",
	"A-50c": "Pose-la sur l'autel du bois. Qui sait ce qui viendra ?",
	"A-51": "Grand-père, il reste à manger ? / … Ah, {joueur} est arrivé avant moi. Je paie le dîner, alors.",
	"A-52": "Il n'y a plus personne. / Sur une pierre, une écharpe à moitié brûlée.",
	"A-53": "{joueur} pose la Balle Verte sur l'autel. / … / La forêt se tait. Les feuilles tremblent.",
	"A-54": "Un petit Pokémon vert apparaît au-dessus de l'autel ! / Celebi veut jouer avec {joueur} !",
}
# Dresseurs (A-4 à A-6, A-14, A-18) : avant · défaite · après.
TRAINER_LINES = {
	"silver_trail_hiker_baptiste": ("Personne ne monte ici sans se mesurer à moi !",
		"Tu as le pied montagnard.", "Au-dessus du Centre, la neige commence."),
	"silver_trail_cooltrainer_ines": ("Le Maître de Kanto ? J'attendais ce combat.",
		"On m'avait prévenue…",
		"Il paraît qu'un homme s'entraîne seul, tout en haut, depuis des mois."),
	"silver_trail_blackbelt_hugo": ("Mes poings ont brisé la glace du sentier !",
		"Et toi, tu m'as brisé.",
		"Des hommes en noir m'ont bousculé, cette nuit. Ils allaient vers la grotte."),
	"mt_silver_1f_grunt_x": ("Quelqu'un est passé ? Impossible !", "Bon, si, c'est possible.",
		"Ton copain, en bas, il est fou."),
	"mt_silver_1f_grunt_y": ("Je me suis glissé derrière toi. Le patron saura que je suis fidèle !",
		"Le patron ne saura rien…", "Va. Il t'attend, de toute façon."),
	"mt_silver_3f_hiker_lucas": ("Un rival de montagne ! Enfin !", "Je redescends m'entraîner.",
		"Au sommet, il y a déjà deux hommes. Je n'ose pas monter."),
}
# Textes [D] absents du dossier (brouillons à relire, PENDING_DRAFTS).
DRAFTS = {
	"route_28_topdresseur_jules": ("Le col de la Route 28 ne laisse passer que les meilleurs.",
		"Tu es des meilleurs, alors.", "Kanto est tout près, à l'ouest. On ne dirait pas, hein ?"),
	"route_28_gate_locked": "La porte est verrouillée.",
	"route_28_gate_guard_open": "Le col est rouvert. / Bonne route, de part et d'autre.",
	"route_28_gate_guard_johto": "La porte vers Kanto est verrouillée. / Il faut une raison de redescendre.",
	"route_28_house_gardien": "Je garde ce col depuis trente ans. / Les Dresseurs qui en reviennent ne sont jamais tout à fait les mêmes.",
	"mt_silver_summit_dante_after": "…",
}


# --- Dresseurs (§6, §9) ----------------------------------------------------------------------

# Identifiant de grille → (identifiant du Dresseur, nom, classe, sprite, prix par niveau [D], équipe).
TRAINERS = {
	("silver_trail", "baptiste"): ("silver_trail_hiker_baptiste", "Montagnard Baptiste",
		"montagnard", "mountaineer", 36, [("golem", 64), ("donphan", 64)]),
	("silver_trail", "ines"): ("silver_trail_cooltrainer_ines", "Topdresseuse Inès",
		"topdresseuse", "cooltrainer_f", 60, [("skarmory", 64), ("ampharos", 64), ("espeon", 65)]),
	("silver_trail", "hugo"): ("silver_trail_blackbelt_hugo", "Karatéka Hugo", "karateka",
		"blackbelt", 36, [("machamp", 65), ("ursaring", 65)]),
	("mt_silver_1f", "sbire_x"): ("mt_silver_1f_grunt_x", "Sbire", "sbire_rocket",
		"rocket_grunt_m", 32, [("houndoom", 66), ("muk", 66)]),
	("mt_silver_1f", "sbire_y"): ("mt_silver_1f_grunt_y", "Sbire", "sbire_rocket_f",
		"rocket_grunt_f", 32, [("sneasel", 66), ("weezing", 66), ("arbok", 66)]),
	("mt_silver_3f", "lucas"): ("mt_silver_3f_hiker_lucas", "Montagnard Lucas", "montagnard",
		"mountaineer", 36, [("steelix", 67), ("ursaring", 67)]),
	("route_28", "jules"): ("route_28_topdresseur_jules", "Topdresseur Jules", "topdresseur",
		"cooltrainer_m", 60, [("tyranitar", 68), ("skarmory", 66), ("arcanine", 66)]),
}
DANTE_TEAM = [("houndoom", 72), ("sneasel", 73), ("magmar", 74), ("scizor", 74), ("arcanine", 76),
	("tyranitar", 78)]
# §9 : rang 1 à 3 communs, 4 et 5 = les deux Pokémon de Ligue qui dépendent du starter
# (`rival_champion`), 6 = son starter (évolué). Clé = starter du JOUEUR (comme la Ligue).
RIVAL_COMMON = [("pidgeot", 75), ("alakazam", 76), ("steelix", 76)]
RIVAL_BY_STARTER = {
	"bulbasaur": [("exeggutor", 77), ("gyarados", 77), ("charizard", 80)],
	"charmander": [("arcanine", 77), ("exeggutor", 77), ("blastoise", 80)],
	"squirtle": [("gyarados", 77), ("arcanine", 77), ("venusaur", 80)],
}
# Nom affiché du starter du rival (A-12, « {pokemon} ») selon les drapeaux `taken_*` de la paire
# du labo (le joueur et le rival ont chacun le leur).
RIVAL_STARTER_NAMES = [
	(["taken_bulbasaur", "taken_charmander"], "Dracaufeu"),
	(["taken_charmander", "taken_squirtle"], "Tortank"),
	(["taken_squirtle", "taken_bulbasaur"], "Florizarre"),
]


# --- Rencontres (§5) -------------------------------------------------------------------------

DAY = ["morning", "day"]
NIGHT = ["night"]
ALL_DAY = None
ENCOUNTERS = {
	"silver_trail": [
		("silver_trail_grass_day", "grass", DAY, 20, 52, 56, [("teddiursa", 25), ("phanpy", 20),
			("skarmory", 15), ("golem", 20), ("machoke", 20)]),
		("silver_trail_grass_night", "grass", NIGHT, 20, 52, 56, [("houndoom", 25), ("sneasel", 20),
			("noctowl", 25), ("golem", 15), ("machoke", 15)]),
	],
	# « toute la journée » avec Farfuret plus fréquent la nuit et Démolosse la nuit seulement :
	# deux tables (règle du JOH0 : pas de mélange daté / toute la journée sur un terrain).
	"mt_silver_outside": [
		("mt_silver_outside_grass_day", "grass", DAY, 20, 56, 60, [("ursaring", 25), ("donphan", 25),
			("skarmory", 20), ("sneasel", 15)]),
		("mt_silver_outside_grass_night", "grass", NIGHT, 20, 56, 60, [("ursaring", 25),
			("donphan", 25), ("skarmory", 20), ("sneasel", 30), ("houndoom", 15)]),
	],
	"mt_silver_1f": [
		("mt_silver_1f_rubble", "rubble", ALL_DAY, 20, 58, 62, [("ursaring", 25), ("donphan", 20),
			("onix", 20), ("golbat", 25), ("machoke", 10)]),
		("mt_silver_1f_water", "water", ALL_DAY, 5, 58, 62, [("tentacruel", 30), ("gyarados", 20),
			("dewgong", 30), ("seel", 20)]),
	],
	"mt_silver_2f": [
		("mt_silver_2f_rubble", "rubble", ALL_DAY, 20, 60, 64, [("golbat", 30), ("ursaring", 25),
			("donphan", 20), ("onix", 20), ("larvitar", 5)]),
	],
	"mt_silver_3f": [
		("mt_silver_3f_rubble", "rubble", ALL_DAY, 20, 62, 65, [("ursaring", 30), ("donphan", 25),
			("golbat", 25), ("machamp", 15), ("pupitar", 5)]),
	],
	"route_28": [
		("route_28_grass_day", "grass", DAY, 20, 55, 60, [("phanpy", 30), ("donphan", 20),
			("skarmory", 20), ("ponyta", 15), ("rapidash", 15)]),
	],
}

CELL_RE = re.compile(r"^(\d+)(?:\.\.(\d+))?,(\d+)(?:\.\.(\d+))?$")


def read_plan(name):
	"""Positions de la grille : id → (type, cases, attributs)."""
	positions = {}
	section = None
	with open(os.path.join(PLANS, name + ".txt"), encoding="utf-8") as handle:
		for raw in handle:
			line = raw.rstrip("\n")
			if line.startswith("POSITIONS") and not line.startswith("POSITIONS_"):
				section = "pos"
				continue
			if line.startswith("FIN"):
				section = None
				continue
			if section != "pos" or not line.strip() or line.startswith("#"):
				continue
			body = line.partition("#")[0]
			words = body.split()
			ident, kind, cells_text = words[0], words[1], words[2]
			attrs = {}
			for word in words[3:]:
				if "=" in word:
					key, _, value = word.partition("=")
					attrs[key] = value
			positions[ident] = (kind, parse_cells(cells_text), attrs)
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
				cells.append([x, y])
	return cells


def write_json(path, data):
	text = json.dumps(data, ensure_ascii=False, indent="\t") + "\n"
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(text)
	print("écrit :", os.path.relpath(path, ROOT))


def player_text(text):
	"""Le dossier écrit {joueur} ; le jeu lit {player}."""
	return text.replace("{joueur}", "{player}")


def say(speaker, key, draft=False, **extra):
	return dialogue(speaker, player_text(A[key]), draft, **extra)


def flag_lists(attrs):
	out = {}
	if "actif_avec" in attrs:
		out["if"] = attrs["actif_avec"].split(",")
	if "actif_sans" in attrs:
		out["unless"] = attrs["actif_sans"].split(",")
	return out


def trainer_entry(name, klass, prize, team, **extra):
	entry = {"name": name, "class": klass, "ai": "random", "can_lose": False,
		"heal_after": False, "gives_exp": True, "prize_money": 0, "prize_per_level": prize,
		"team": [{"species": s, "level": l} for s, l in team]}
	entry.update(extra)
	return entry


def guard_back_scene(guard, dialogue_id, back, unless):
	steps = []
	if guard:
		steps += [{"face": guard, "to": "player"}, {"face": "player", "to": guard}]
	steps += [{"dialogue": dialogue_id}, {"move": "player", "path": [back], "keep_facing": True}]
	return {"variants": [{"unless": unless, "steps": steps}]}


# --- Scènes ------------------------------------------------------------------------------------


def relay_scene():
	"""A-8 à A-13 (extérieur, rangée y 14) : Brace et Cenere barrent la grotte, le rival arrive en
	courant par le chemin et les retient ; le joueur entre seul (on ne voit pas le combat, A-13).
	Le drapeau est posé en tête (scène interrompue = jouée : les admins s'effacent)."""
	return {"variants": [{"unless": [RELAY], "steps": [
		{"set": [RELAY]},
		{"face": "player", "to": "up"},
		{"emote": "brace", "kind": "exclamation"},
		{"dialogue": "mt_silver_brace_block"},
		{"dialogue": "mt_silver_cenere_block"},
		{"dialogue": "mt_silver_rival_offscreen"},
		{"spawn": "rival_relais", "sprite": "rival", "cell": [19, 22], "facing": "up"},
		{"dialogue": "mt_silver_rival_arrives"},
		{"move": "rival_relais", "to": {"near": "player", "offsets": [[1, 0], [-1, 0], [0, 1]]},
			"run": True},
		{"face": "rival_relais", "to": "player"},
		{"face": "player", "to": "rival_relais"},
		{"dialogue": "mt_silver_rival_relay"},
		{"face": "rival_relais", "to": "up"},
		{"dialogue": "mt_silver_rival_to_admins"},
		{"move": "player", "to": [19, 7]},
		{"face": "player", "to": "up"},
		{"dialogue": "mt_silver_enter_cave"},
		{"change_map": "mt_silver_1f", "at": "from_outside", "facing": "up"},
	]}]}


def heal_scene():
	"""A-19 à A-21 (2F, galerie) : le rival rattrape le joueur dans le noir, dit ce qu'il a fait des
	admins (JH-56), soigne l'équipe et repart par l'est [D]."""
	return {"variants": [{"unless": [HEALED], "steps": [
		{"set": [HEALED]},
		{"dialogue": "mt_silver_2f_footsteps"},
		{"spawn": "rival_2f", "sprite": "rival", "cell": [26, 11], "facing": "left"},
		{"move": "rival_2f", "to": {"near": "player", "offsets": [[1, 0], [1, -1], [1, 1], [0, 1]]},
			"run": True},
		{"face": "rival_2f", "to": "player"},
		{"face": "player", "to": "rival_2f"},
		{"dialogue": "mt_silver_2f_rival_news"},
		{"dialogue": "mt_silver_2f_rival_heal"},
		{"dialogue": "mt_silver_2f_healed"},
		{"dialogue": "mt_silver_2f_rival_leaves"},
		{"move": "rival_2f", "to": [28, 3], "run": True},
		{"despawn": "rival_2f"},
	]}]}


def dante_steps():
	"""A-23, A-26 à A-28 (première fois) ou A-25 (retour après une défaite), combat."""
	return [
		{"dialogue": "mt_silver_summit_arrival", "unless": [SUMMIT_REACHED]},
		{"move": "player", "to": [10, 8]},
		{"face": "player", "to": "dante"},
		{"face": "dante", "to": "player"},
		{"dialogue": "mt_silver_dante_welcome", "unless": [SUMMIT_REACHED]},
		{"dialogue": "mt_silver_dante_ho_oh", "unless": [SUMMIT_REACHED]},
		{"dialogue": "mt_silver_dante_return", "if": [SUMMIT_REACHED]},
		{"set": [SUMMIT_REACHED]},
		{"dialogue": "mt_silver_dante_before"},
		{"battle": "mt_silver_dante_2", "win": [DANTE_WON]},
		{"wake_up": True, "unless": [DANTE_WON]},
		{"dialogue": "mt_silver_dante_defeated"},
		{"dialogue": "mt_silver_dante_after"},
	]


def giovanni_steps():
	"""A-31 à A-39 (JH-56 à JH-58) : Giovanni, sans combat, puis Cenere reste auprès de Dante."""
	return [
		{"dialogue": "mt_silver_giovanni_steps"},
		{"spawn": "giovanni", "sprite": "giovanni", "cell": [9, 1], "facing": "down"},
		{"move": "giovanni", "to": [9, 5]},
		{"face": "dante", "to": "giovanni"},
		{"face": "player", "to": "giovanni"},
		{"dialogue": "mt_silver_giovanni_hello"},
		{"dialogue": "mt_silver_dante_to_giovanni"},
		{"dialogue": "mt_silver_giovanni_learned"},
		{"dialogue": "mt_silver_giovanni_rocket_dead"},
		{"face": "giovanni", "to": "player"},
		{"dialogue": "mt_silver_giovanni_to_player"},
		{"dialogue": "mt_silver_giovanni_leaves"},
		{"move": "giovanni", "to": [9, 1]},
		{"despawn": "giovanni"},
		{"set": [GIOVANNI]},
		{"move": "player", "path": ["right", "right"], "keep_facing": True},
		{"dialogue": "mt_silver_cenere_arrives"},
		{"spawn": "cenere_sommet", "sprite": "rocket_grunt_f", "cell": [16, 6], "facing": "left"},
		{"move": "cenere_sommet", "to": [10, 8], "run": True},
		{"face": "cenere_sommet", "to": "dante"},
		{"dialogue": "mt_silver_cenere_stays"},
		{"face": "dante", "to": "down"},
		{"dialogue": "mt_silver_dante_silent"},
		{"save": "johto_giovanni_seen"},
	]


def rival_steps(approach):
	"""A-40, A-41 (première fois) ou A-45 (retour), combat final, A-42 à A-44, A-46."""
	steps = []
	if approach == "arrive":
		steps += [
			{"spawn": "rival_sommet", "sprite": "rival", "cell": [16, 6], "facing": "left"},
			{"move": "rival_sommet", "to": [14, 8], "run": True},
		]
	elif approach == "walk":
		steps += [{"move": "player", "to": {"near": "rival_sommet", "offsets": [[-1, 0], [0, 1],
			[0, -1]]}}]
	steps += [
		{"face": "rival_sommet", "to": "player"},
		{"face": "player", "to": "rival_sommet"},
		{"dialogue": "mt_silver_rival_arrives_summit", "unless": [RIVAL_MET]},
		{"dialogue": "mt_silver_rival_why", "unless": [RIVAL_MET]},
		{"dialogue": "mt_silver_rival_return", "if": [RIVAL_MET]},
		{"set": [RIVAL_MET]},
		{"battle": "mt_silver_rival_final", "win": [RIVAL_DONE]},
		{"wake_up": True, "unless": [RIVAL_DONE]},
		{"dialogue": "mt_silver_rival_defeated"},
		{"dialogue": "mt_silver_rival_after"},
		{"dialogue": "mt_silver_rival_agente"},
		{"dialogue": "mt_silver_rival_race"},
		{"dialogue": "mt_silver_rival_runs"},
		{"move": "rival_sommet", "to": [16, 3], "run": True},
		{"despawn": "rival_sommet"},
	]
	return steps


def summit_scene():
	"""Déclencheur du palier (16, 5), seule sortie : Dante (puis Giovanni, Cenere, le rival) ;
	Giovanni seul si la partie a été reprise entre les deux ; le rival seul au retour d'une
	défaite contre lui (A-45). Aucune scène rejouée en double (dossier §13)."""
	return {"variants": [
		{"unless": [DANTE_WON], "steps": dante_steps() + giovanni_steps() + rival_steps("arrive")},
		{"if": [DANTE_WON], "unless": [GIOVANNI], "steps": giovanni_steps() + rival_steps("arrive")},
		{"if": [GIOVANNI], "unless": [RIVAL_DONE], "steps": rival_steps("walk")},
	]}


def rival_talk_scene():
	"""Le rival du sommet, si on lui parle (reprise entre Giovanni et lui : il attend devant le
	joueur, dossier §13)."""
	return {"variants": [{"if": [GIOVANNI], "unless": [RIVAL_DONE], "steps": rival_steps("")}]}


def gate_scene():
	"""A-47 : la porte de la Route 22 s'ouvre, une fois."""
	return {"variants": [{"if": [RIVAL_DONE], "unless": [ROUTE28], "steps": [
		{"set": [ROUTE28]},
		{"dialogue": "route_28_gate_opens"},
	]}]}


def epilogue_scene():
	"""JH-60, A-49 à A-51 : à l'entrée du labo de Chen, une fois ; Orme en visite, la Balle Verte,
	le rival passe la tête à la porte, petit générique de Johto, sauvegarde."""
	return {"variants": [{"if": [GIOVANNI, RIVAL_DONE], "unless": [CHAPTER], "steps": [
		{"spawn": "orme", "sprite": "researcher", "cell": [9, 5], "facing": "left"},
		{"move": "player", "to": [8, 5]},
		{"face": "player", "to": "up"},
		{"face": "oak", "to": "player"},
		{"dialogue": "johto_epilogue_chen"},
		{"face": "orme", "to": "player"},
		{"dialogue": "johto_epilogue_orme"},
		{"give": "green_ball", "count": 1, "set": [GREEN_BALL]},
		{"dialogue": "johto_epilogue_green_ball"},
		{"dialogue": "johto_epilogue_orme_altar"},
		{"spawn": "rival_epilogue", "sprite": "rival", "cell": [7, 9], "facing": "up"},
		{"face": "player", "to": "rival_epilogue"},
		{"dialogue": "johto_epilogue_rival"},
		{"set": [CHAPTER]},
		{"credits": "johto"},
		{"save": "johto_chapter_done"},
	]}]}


def celebi_scene():
	"""A-53, A-54 (post-game, JH-16) : la Balle Verte posée sur l'autel du Bois aux Chênes, Celebi
	niv. 60, sauvage, capturable ; K.O. ou fuite : il revient au prochain passage [D]."""
	return {"variants": [{"if": [CHAPTER], "unless": [CELEBI], "steps": [
		{"dialogue": "ilex_altar_green_ball"},
		{"dialogue": "ilex_altar_celebi"},
		{"wild_battle": "celebi", "level": 60, "intro": "legendary", "catch": [CELEBI]},
	]}]}


# --- Écriture ----------------------------------------------------------------------------------


def trainer_npc(ident, cell, attrs, trainer_id, sprite):
	entry = {
		"cell": cell, "facing": attrs["facing"], "sprite": sprite,
		"dialogue": trainer_id + "_after",
		"trainer": {"id": trainer_id, "sight": int(attrs["sight"]),
			"before": trainer_id + "_before", "defeated": trainer_id + "_defeated"},
	}
	entry.update(flag_lists(attrs))
	return entry


def main():
	trainers = {}
	dialogues = {}   # lot → {id: entrée}
	cutscenes = {}   # lot → {id: scène}
	npcs = {}        # carte → {id: entrée}

	def lot(name):
		dialogues.setdefault(name, {})
		cutscenes.setdefault(name, {})
		return dialogues[name], cutscenes[name]

	# Dresseurs ordinaires (§6).
	for (map_id, ident), (tid, name, klass, sprite, prize, team) in TRAINERS.items():
		lines = TRAINER_LINES.get(tid) or DRAFTS[tid]
		draft = tid not in TRAINER_LINES
		dlg, _ = lot(map_id if map_id != "mt_silver_3f" and map_id != "mt_silver_1f" else "mt_silver")
		dlg[tid + "_before"] = dialogue(name, [wrap(lines[0])], draft)
		dlg[tid + "_defeated"] = dialogue(name, [wrap(lines[1])], draft)
		dlg[tid + "_after"] = dialogue(name, [wrap(lines[2])], draft)
		trainers[tid] = trainer_entry(name, klass, prize, team)

	# Dante (2) et le rival final : combats de scène (obligatoires, grands combats).
	trainers["mt_silver_dante_2"] = trainer_entry("Dante", "dante", 99, DANTE_TEAM,
		ai="smart", start_message=False, end_message=False, bag=True, switch=True)
	trainers["mt_silver_dante_2"].pop("class")
	rival = trainer_entry(RIVAL, "", 99, [], ai="smart", start_message=False, end_message=False,
		bag=True, switch=True)
	rival.pop("class")
	rival.pop("team")
	rival["card"] = {"name": RIVAL, "title": "Rival", "title_rivale": "Rivale", "portrait": "rival"}
	rival["team_by_starter"] = {starter: [{"species": s, "level": l} for s, l in RIVAL_COMMON + rest]
		for starter, rest in RIVAL_BY_STARTER.items()}
	trainers["mt_silver_rival_final"] = rival

	# --- Sentier ---
	dlg, cut = lot("silver_trail")
	positions = read_plan("silver_trail")
	npcs["silver_trail"] = {}
	for ident, (kind, cells, attrs) in positions.items():
		if kind == "dresseur":
			tid, _n, _k, sprite, _p, _t = TRAINERS[("silver_trail", ident)]
			npcs["silver_trail"][ident] = trainer_npc(ident, cells[0], attrs, tid, sprite)
	dlg["silver_trail_panneau"] = dialogue(NARRATION, player_text(A["A-3"]))
	# Garde forestier du Lac Colère (carte du JOH6) : A-1 avant l'acte 3, A-2 ensuite.
	dlg["lake_of_rage_forest_ranger"] = {"speaker": "Garde forestier", "variants": [
		{"unless": ["johto_act3"], "pages": pages(A["A-1"])},
		{"if": ["johto_act3"], "pages": pages(A["A-2"])},
	]}
	dlg["lake_of_rage_trail_closed"] = dialogue("Garde forestier", A["A-1"])
	cut["lake_of_rage_trail_guard"] = guard_back_scene("garde_forestier",
		"lake_of_rage_trail_closed", "left", ["johto_act3"])

	# --- Extérieur, grotte ---
	dlg, cut = lot("mt_silver")
	positions = read_plan("mt_silver_outside")
	npcs["mt_silver_outside"] = {}
	admin_sprites = {"brace": "rocket_grunt_m", "cenere": "rocket_grunt_f"}
	for ident, (kind, cells, attrs) in positions.items():
		if kind == "pnj" and ident != "rival_relais":
			sprite = admin_sprites.get(ident, "rocket_grunt_m" if ident in ("sbire_1", "sbire_3")
				else "rocket_grunt_f")
			entry = {"cell": cells[0], "facing": attrs.get("facing", "down"), "sprite": sprite}
			entry.update(flag_lists(attrs))
			npcs["mt_silver_outside"][ident] = entry
	dlg["mt_silver_brace_block"] = say("Brace", "A-8")
	dlg["mt_silver_cenere_block"] = say("Cenere", "A-9")
	dlg["mt_silver_rival_offscreen"] = say(RIVAL, "A-10a")
	dlg["mt_silver_rival_arrives"] = say(NARRATION, "A-10b")
	dlg["mt_silver_rival_relay"] = say(RIVAL, "A-11")
	relay_pages = [wrap(p) for p in pages(player_text(A["A-12"]))]
	dlg["mt_silver_rival_to_admins"] = {"speaker": RIVAL, "variants": [
		{"if": flags, "pages": [relay_pages[0].replace("{pokemon}", name)] + relay_pages[1:]}
		for flags, name in RIVAL_STARTER_NAMES] + [{"pages": relay_pages[1:]}]}
	dlg["mt_silver_enter_cave"] = say(NARRATION, "A-13")
	cut["mt_silver_relay"] = relay_scene()

	positions = read_plan("mt_silver_1f")
	npcs["mt_silver_1f"] = {}
	for ident, (kind, cells, attrs) in positions.items():
		if kind == "dresseur":
			tid, _n, _k, sprite, _p, _t = TRAINERS[("mt_silver_1f", ident)]
			npcs["mt_silver_1f"][ident] = trainer_npc(ident, cells[0], attrs, tid, sprite)
	dlg["mt_silver_boulder"] = say(NARRATION, "A-15")

	dlg["mt_silver_2f_dark"] = say(NARRATION, "A-16")
	dlg["mt_silver_2f_footsteps"] = say(NARRATION, "A-19")
	dlg["mt_silver_2f_rival_news"] = say(RIVAL, "A-20")
	dlg["mt_silver_2f_rival_heal"] = say(RIVAL, "A-21a", heal=True)
	dlg["mt_silver_2f_healed"] = say(NARRATION, "A-21b")
	dlg["mt_silver_2f_rival_leaves"] = say(RIVAL, "A-21c")
	cut["mt_silver_2f_rival"] = heal_scene()
	npcs["mt_silver_2f"] = {}

	positions = read_plan("mt_silver_3f")
	npcs["mt_silver_3f"] = {}
	for ident, (kind, cells, attrs) in positions.items():
		if kind == "dresseur":
			tid, _n, _k, sprite, _p, _t = TRAINERS[("mt_silver_3f", ident)]
			npcs["mt_silver_3f"][ident] = trainer_npc(ident, cells[0], attrs, tid, sprite)
	dlg["mt_silver_3f_wind"] = say(NARRATION, "A-22")
	cut["mt_silver_3f_wind"] = {"variants": [{"unless": [WIND], "steps": [
		{"set": [WIND]}, {"dialogue": "mt_silver_3f_wind"}]}]}

	# --- Sommet ---
	dlg, cut = lot("mt_silver_summit")
	positions = read_plan("mt_silver_summit")
	attrs_of = {ident: attrs for ident, (_k, _c, attrs) in positions.items()}
	npcs["mt_silver_summit"] = {
		# Dante : à genoux après sa défaite (JH-58) ; parti après le chapitre (A-52).
		"dante": {"cell": [9, 8], "facing": "right", "sprite": "gentleman",
			"dialogue": "mt_silver_summit_dante_talk", "unless": [CHAPTER]},
		"cenere_sommet": {"cell": [10, 8], "facing": "left", "sprite": "rocket_grunt_f",
			"dialogue": "mt_silver_summit_cenere_talk", "if": [GIOVANNI], "unless": [CHAPTER]},
		"rival_sommet": {"cell": [14, 8], "facing": "left", "sprite": "rival",
			"dialogue": "mt_silver_summit_rival_talk", "if": [GIOVANNI], "unless": [RIVAL_DONE]},
	}
	dlg["mt_silver_summit_arrival"] = say(NARRATION, "A-23")
	dlg["mt_silver_summit_ruines"] = say(NARRATION, "A-24")
	dlg["mt_silver_summit_echarpe"] = say(NARRATION, "A-52")
	dlg["mt_silver_dante_return"] = say("Dante", "A-25")
	dlg["mt_silver_dante_welcome"] = say("Dante", "A-26")
	dlg["mt_silver_dante_ho_oh"] = say("Dante", "A-27")
	dlg["mt_silver_dante_before"] = say("Dante", "A-28")
	dlg["mt_silver_dante_defeated"] = say("Dante", "A-29")
	dlg["mt_silver_dante_after"] = say("Dante", "A-30")
	dlg["mt_silver_giovanni_steps"] = say(NARRATION, "A-31")
	dlg["mt_silver_giovanni_hello"] = say("Giovanni", "A-32")
	dlg["mt_silver_dante_to_giovanni"] = say("Dante", "A-33")
	dlg["mt_silver_giovanni_learned"] = say("Giovanni", "A-34")
	dlg["mt_silver_giovanni_rocket_dead"] = say("Giovanni", "A-35")
	dlg["mt_silver_giovanni_to_player"] = say("Giovanni", "A-36")
	dlg["mt_silver_giovanni_leaves"] = say(NARRATION, "A-37")
	dlg["mt_silver_cenere_arrives"] = say(NARRATION, "A-38a")
	dlg["mt_silver_cenere_stays"] = say("Cenere", "A-38b")
	dlg["mt_silver_dante_silent"] = say(NARRATION, "A-39")
	# Après la scène : Dante ne dit plus rien au joueur (JH-58) ; A-39 rejouée en examen [D].
	dlg["mt_silver_summit_dante_talk"] = {"narration": True, "pages": [pages(A["A-39"])[0]]}
	dlg["mt_silver_summit_cenere_talk"] = {"narration": True, "pages": [pages(A["A-39"])[1]]}
	dlg["mt_silver_summit_rival_talk"] = {"cutscene": "mt_silver_rival_talk"}
	dlg["mt_silver_rival_arrives_summit"] = say(RIVAL, "A-40")
	dlg["mt_silver_rival_why"] = say(RIVAL, "A-41")
	dlg["mt_silver_rival_return"] = say(RIVAL, "A-45")
	dlg["mt_silver_rival_defeated"] = say(RIVAL, "A-42")
	dlg["mt_silver_rival_after"] = say(RIVAL, "A-43")
	dlg["mt_silver_rival_agente"] = say(RIVAL, "A-44")
	dlg["mt_silver_rival_race"] = say(RIVAL, "A-46a")
	dlg["mt_silver_rival_runs"] = say(NARRATION, "A-46b")
	cut["mt_silver_summit"] = summit_scene()
	cut["mt_silver_rival_talk"] = rival_talk_scene()

	# --- Route 28, poste, maison ---
	dlg, cut = lot("route_28")
	positions = read_plan("route_28")
	npcs["route_28"] = {}
	for ident, (kind, cells, attrs) in positions.items():
		if kind == "dresseur":
			tid, _n, _k, sprite, _p, _t = TRAINERS[("route_28", ident)]
			npcs["route_28"][ident] = trainer_npc(ident, cells[0], attrs, tid, sprite)
	npcs["route_28_gate"] = {"garde": {"cell": [6, 2], "facing": "left", "sprite": "guard",
		"dialogue": "route_28_gate_guard"}}
	dlg["route_28_gate_guard"] = {"speaker": "Garde", "variants": [
		{"if": [ROUTE28], "draft": True, "pages": pages(DRAFTS["route_28_gate_guard_open"])},
		{"if": [RIVAL_DONE], "pages": pages(A["A-48"])},
		{"pages": pages(A["A-48"])},
	]}
	dlg["route_28_gate_check"] = dialogue("Garde", A["A-48"])
	dlg["route_28_gate_locked"] = dialogue(NARRATION, DRAFTS["route_28_gate_locked"], True)
	dlg["route_28_gate_opens"] = say(NARRATION, "A-47")
	cut["route_28_gate_check"] = guard_back_scene("garde", "route_28_gate_check", "down", [ROUTE28])
	# Rangée (4..5, 6), en descendant (depuis Johto) : verrouillée et recul avant le rival final,
	# puis A-47 une fois (`johto_route28_open`).
	south = guard_back_scene("", "route_28_gate_locked", "up", [RIVAL_DONE])
	south["variants"].append(gate_scene()["variants"][0])
	cut["route_28_gate_south"] = south
	# Porte neuve de la Route 22 (variante JOH9, côté Kanto) : vers le poste, avec `johto_arrived`.
	cut["route_22_route_28_door"] = {"variants": [{"if": ["johto_arrived"], "steps": [
		{"change_map": "route_28_gate", "at": "from_route_22", "facing": "up"}]}]}
	npcs["route_28_house"] = {"gardien": {"cell": [12, 6], "facing": "left", "sprite": "old_man",
		"dialogue": "route_28_house_gardien"}}
	dlg["route_28_house_gardien"] = dialogue("Gardien", DRAFTS["route_28_house_gardien"], True)

	# --- Centre du Mont Argenté (Centre + comptoir de Boutique) ---
	npcs["mt_silver_center"] = {
		"nurse": {"cell": [7, 3], "facing": "down", "sprite": "nurse"},
		"clerk": {"cell": [13, 5], "facing": "left", "sprite": "clerk", "dialogue": "clerk"},
	}

	# --- Épilogue, Celebi ---
	dlg, cut = lot("epilogue")
	dlg["johto_epilogue_chen"] = say("Prof. Chen", "A-49")
	dlg["johto_epilogue_orme"] = say("Prof. Orme", "A-50a")
	dlg["johto_epilogue_green_ball"] = say(NARRATION, "A-50b")
	dlg["johto_epilogue_orme_altar"] = say("Prof. Orme", "A-50c")
	dlg["johto_epilogue_rival"] = say(RIVAL, "A-51")
	dlg["ilex_altar_green_ball"] = say(NARRATION, "A-53")
	dlg["ilex_altar_celebi"] = say(NARRATION, "A-54")
	cut["johto_epilogue"] = epilogue_scene()
	cut["ilex_altar_celebi"] = celebi_scene()

	for map_id, entries in npcs.items():
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), entries)
	for name, entries in dialogues.items():
		if entries:
			write_json(os.path.join(DATA, "dialogues", "joh9_%s.json" % name), entries)
	for name, entries in cutscenes.items():
		if entries:
			write_json(os.path.join(DATA, "cutscenes", "joh9_%s.json" % name), entries)
	write_json(os.path.join(DATA, "trainers", "joh9.json"), trainers)
	for map_id, tables in ENCOUNTERS.items():
		out = {}
		for table_id, terrain, periods, rate, low, high, slots in tables:
			entry = {"maps": [map_id], "terrain": terrain}
			if periods:
				entry["period"] = periods
			entry["rate"] = rate
			entry["ramp"] = {"from_step": 15, "max_steps": 20}
			entry["slots"] = [{"species": s, "levels": [low, high], "weight": w} for s, w in slots]
			out[table_id] = entry
		write_json(os.path.join(DATA, "encounters", map_id + ".json"), out)


if __name__ == "__main__":
	main()
