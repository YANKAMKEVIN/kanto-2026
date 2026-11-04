#!/usr/bin/env python3
"""Données de jeu du jalon JOH5 (la Tour Radio de Doublonville), générées depuis les grilles.

Lit les positions de `tools/plans/radio_tower_1f.txt` … `radio_tower_5f.txt` (grilles validées
le 2026-11-02, elles font foi) et écrit, d'après `docs/design/dossier-joh-06-tour-radio.md`
(textes T-1 à T-38 et JH-40 à JH-43 validés le 2026-11-02 ; Dresseurs §5, objets §6) et le plan
`docs/tech/jalon-joh5.md` §2.2 à §2.5 :
  - `data/npcs/goldenrod_radio_tower_<n>f.json` (Dresseurs, PNJ, objets visibles) ;
  - `data/trainers/goldenrod_radio_tower.json` ;
  - `data/dialogues/joh5_radio_tower.json` ;
  - `data/cutscenes/joh5_radio_tower.json`.
Les textes absents du dossier sont marqués « draft » (relecture de Kevin) et listés dans
`tests/integration/test_no_draft_in_data.gd` (PENDING_DRAFTS).

Usage : python3 -I tools/gen_joh5_data.py   (relancer après un changement de grille ou de texte)
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANS = os.path.join(ROOT, "tools", "plans")
DATA = os.path.join(ROOT, "data")

FLOORS = [1, 2, 3, 4, 5]
MAP = "goldenrod_radio_tower_%df"
TRAINER_FILE = "goldenrod_radio_tower"

# Objets clés du JOH4 (dossier JOH-05) remis à l'Agente (T-33) (ids du JOH4, `data/items/items_joh4.json`).
ORDERS_ITEM = "mission_order"
PASS_ITEM = "radio_card"

NARRATION = None
GRUNT = "Sbire Rocket"

# Dresseurs (dossier §5) : id → (nom, classe, prix par niveau [D], sprite, équipe).
TRAINERS = {
	"goldenrod_radio_tower_impostor": ("Sbire Rocket", "sbire_rocket", 40, "rocket_grunt_m",
		[("arbok", 26), ("raticate", 26)]),
	"goldenrod_radio_tower_grunt_h": ("Sbire Rocket", "sbire_rocket", 40, "rocket_grunt_m",
		[("golbat", 26), ("koffing", 26)]),
	"goldenrod_radio_tower_grunt_i": ("Sbire Rocket", "sbire_rocket", 40, "rocket_grunt_m",
		[("houndour", 27), ("murkrow", 27)]),
	"goldenrod_radio_tower_grunt_j": ("Sbire Rocket", "sbire_rocket_f", 40, "rocket_grunt_f",
		[("magneton", 27)]),
	"goldenrod_radio_tower_grunt_k": ("Sbire Rocket", "sbire_rocket", 40, "rocket_grunt_m",
		[("muk", 28), ("ekans", 27)]),
	"goldenrod_radio_tower_grunt_l": ("Sbire Rocket", "sbire_rocket_f", 40, "rocket_grunt_f",
		[("raticate", 28), ("golbat", 28)]),
	"goldenrod_radio_tower_keeper": ("Sbire Rocket", "sbire_rocket", 40, "rocket_grunt_m",
		[("houndour", 28), ("koffing", 28), ("murkrow", 29)]),
	"goldenrod_radio_tower_grunt_m": ("Sbire Rocket", "sbire_rocket", 40, "rocket_grunt_m",
		[("arbok", 29), ("muk", 29)]),
	"goldenrod_radio_tower_grunt_n": ("Sbire Rocket", "sbire_rocket_f", 40, "rocket_grunt_f",
		[("magneton", 29), ("weezing", 29)]),
	"goldenrod_radio_tower_grunt_o": ("Sbire Rocket", "sbire_rocket", 40, "rocket_grunt_m",
		[("houndour", 30), ("golbat", 30)]),
	"goldenrod_radio_tower_admin_cenere": ("Cenere", "sbire_rocket_f", 60, "rocket_grunt_f",
		[("weezing", 33), ("wobbuffet", 33), ("sneasel", 35)]),
}
# Dresseurs combattus par une scène (pas de bloc « trainer » sur le PNJ).
SCENE_TRAINERS = {"goldenrod_radio_tower_impostor", "goldenrod_radio_tower_admin_cenere"}

# Répliques (T-6, T-7, T-8, T-12) : avant · défaite · après.
TRAINER_LINES = {
	"goldenrod_radio_tower_grunt_h": ("Les studios sont à nous !", "Coupez ! Coupez !",
		"Écoute bien la radio, gamin. Notre chef revient."),
	"goldenrod_radio_tower_grunt_i": ("Tu entends ? C'est l'appel de Giovanni !",
		"Giovanni ne sera pas content…", "Bientôt, toute la Team Rocket sera réunie."),
	"goldenrod_radio_tower_grunt_j": ("Mon Magnéton brouille tout, même tes ordres !",
		"Plus de signal.", "Les ordres arrivent par la radio. On ne voit jamais qui les donne."),
	"goldenrod_radio_tower_grunt_k": ("Les archives, c'est interdit !", "Bon, lis ce que tu veux.",
		"Il paraît que les vrais ordres viennent de très loin."),
	"goldenrod_radio_tower_grunt_l": ("Tu es le Maître de Kanto ? Sans tes Pokémon, tu n'es rien !",
		"… Tu n'en avais pas besoin, on dirait.",
		"Ils sont là-haut, tes Pokémon. Mais tu n'iras pas si loin."),
	"goldenrod_radio_tower_keeper": (
		"Personne ne touche à la réserve. Les employés restent dedans !",
		"D'accord, d'accord, je donne la clé !", "Cenere va me congeler sur place."),
	"goldenrod_radio_tower_grunt_m": ("La régie, c'est le cœur de la Tour. Tu ne passeras pas !",
		"Le cœur a lâché.", "Cenere règle tout à la seconde près. Toi, tu n'étais pas prévu."),
	"goldenrod_radio_tower_grunt_n": ("Le message passe sur toutes les ondes de Johto !",
		"Interférences…", "Si Giovanni l'entend, il viendra. Forcément."),
	"goldenrod_radio_tower_grunt_o": ("Dernier étage avant Cenere. Fais demi-tour !",
		"Tu es vraiment têtu.", "Vas-y. Elle t'attend, je crois."),
}

# Sprites provisoires [D] des PNJ par rôle.
ROLE_SPRITES = {
	"agente": "guard", "orme": "researcher", "employee": "hostess", "employe": "engineer",
	"raphael": "engineer", "directeur": "gentleman", "sbire": "rocket_grunt_m",
}

# Dialogues : id → (locuteur, pages[, brouillon]). « / » du dossier = page.
T = {
	# T-1 : haut-parleur du pupitre du 2F (le message de Cenere en boucle, dossier §3).
	"goldenrod_radio_loudspeaker": ("Haut-parleur", ["Ici Radio Rocket.",
		"À tous les membres de la Team Rocket, où que vous soyez :",
		"Giovanni, reviens ! La Team Rocket t'attend à Johto.",
		"Rassemblez-vous. Le grand retour approche."]),
	# T-2 à T-4 : le faux employé (JH-40).
	"goldenrod_radio_impostor_intro": ("Employé", ["Désolé, la Tour est fermée au…",
		"Une Carte d'accès ? Fais voir.", "…", "C'est la carte de Brace ! Comment tu l'as eue ?",
		"… Oups. Bon, tant pis. Tu ne monteras pas !"]),
	"goldenrod_radio_impostor_defeated": (GRUNT, ["Mon déguisement était parfait, pourtant…"]),
	"goldenrod_radio_impostor_after": (GRUNT, ["Le vrai personnel ? Enfermé là-haut. Bonne chance !"]),
	"goldenrod_radio_impostor_flees": (NARRATION,
		["Le faux employé arrache son uniforme et file dans l'escalier !"]),
	# D-18 (dossier JOH-04, JOH3) : le faux employé sans la Carte d'accès.
	"goldenrod_radio_impostor_closed": ("Employé", ["Désolé, la Tour est fermée au public.",
		"Travaux techniques.", "Revenez… plus tard. Beaucoup plus tard."]),
	# T-5 et D-19 (1F avant le faux employé) : l'ascenseur.
	"goldenrod_radio_elevator_broken": (NARRATION, ["L'ascenseur est en panne.",
		"Quelqu'un a coupé le courant."]),
	"goldenrod_radio_elevator_closed": (NARRATION, ["Un écriteau : « Étages fermés ».",
		"Des voix étouffées descendent de là-haut."]),
	# T-9 à T-11 : la réserve.
	"goldenrod_radio_reserve_opened": (NARRATION, ["{player} ouvre la porte de la réserve."]),
	"goldenrod_radio_reserve_locked": (NARRATION,
		["La porte de la réserve est fermée à clé.", "Des voix étouffées appellent à l'aide."],
		True),
	"goldenrod_radio_employee": ("Employée", ["Enfin ! Ils nous ont enfermés ici depuis des jours.",
		"Le directeur est resté là-haut, avec leur chef."]),
	"goldenrod_radio_employee_2": ("Employé", ["Enfin ! Ils nous ont enfermés ici depuis des jours.",
		"Le directeur est resté là-haut, avec leur chef."]),
	"goldenrod_radio_raphael_freed": ("Raphaël", ["Merci ! Je m'appelle Raphaël, je suis technicien.",
		"Trois jours dans le noir…",
		"Ma femme doit être morte d'inquiétude. Je rentre tout de suite !"]),
	# T-13 : le pupitre de la régie.
	"goldenrod_radio_console": (NARRATION,
		["Un écran affiche : « DIFFUSION EN COURS — TOUT JOHTO »."]),
	# T-15 à T-23 : Cenere, Dante, les Sbires.
	"goldenrod_radio_cenere_mic": ("Cenere", ["… Giovanni, reviens. La Team Rocket t'attend.", "…"]),
	"goldenrod_radio_cenere_early": ("Cenere", ["Tu es en avance.",
		"D'après mes calculs, tu ne devais pas arriver avant demain."]),
	"goldenrod_radio_cenere_intro": ("Cenere", ["Je suis Cenere.", "Brace fonce. Moi, je calcule.",
		"Et dans mes calculs, tu perds."]),
	"goldenrod_radio_cenere_defeated": ("Cenere", ["… Une erreur de calcul.",
		"Je n'aime pas les erreurs."]),
	"goldenrod_radio_cenere_after": ("Cenere", ["Tu crois que ce message était pour Giovanni ?",
		"Écoute. Quelqu'un veut te parler."]),
	"goldenrod_radio_dante_voice": ("Voix", ["Cenere. Coupe ce message, il a fait son travail.",
		"Membres de la Team Rocket, écoutez-moi.",
		"Vous attendez Giovanni. Giovanni ne viendra pas.",
		"Il vous a abandonnés, comme il a abandonné celui qui lui a tout appris.",
		"Je m'appelle Dante. Je dirigeais la Team Rocket bien avant lui.",
		"C'est moi qui vous ai réunis. C'est moi qui donne les ordres, depuis le début."]),
	"goldenrod_radio_dante_player": ("Dante", ["Et toi, le Maître de Kanto…",
		"Tes Pokémon, à Oliville, c'est moi qui les ai fait prendre.",
		"Un champion n'avait rien à faire sur mon chemin.", "Tu es venu quand même. Bien.",
		"Ce qui a brûlé une fois peut brûler encore.", "Nous nous reverrons quand tout sera cendres."]),
	"goldenrod_radio_dante_retreat": ("Dante", ["Cenere. Laisse tout. On part."]),
	"goldenrod_radio_grunt_1": (GRUNT, ["Dante ? C'est qui, ça ?"]),
	"goldenrod_radio_grunt_2": (GRUNT, ["Moi, je suis entré pour Giovanni… Je m'en vais."]),
	"goldenrod_radio_grunt_3": (GRUNT, ["Un chef qui gagne, c'est un chef. Je le suis."]),
	"goldenrod_radio_cenere_leaves": ("Cenere", ["Tu as entendu.",
		"Tes Pokémon sont dans le bureau. Garde-les bien.",
		"Ils ne te serviront à rien contre ce qui vient."]),
	"goldenrod_radio_cenere_exit": (NARRATION, ["Cenere s'en va par l'escalier de secours…"]),
	"goldenrod_radio_emergency_stairs": (NARRATION,
		["La porte de l'escalier de secours est fermée."], True),
	"goldenrod_radio_office_locked": (NARRATION,
		["La porte du bureau du directeur est fermée."], True),
	# T-24 à T-32 : le bureau et le retour de l'équipe.
	"goldenrod_radio_office_found": (NARRATION, ["La porte du bureau est ouverte.",
		"Sur la table : des Poké Balls. Et un sac.", "Ce sont les tiens !"]),
	"goldenrod_radio_director_bound": ("Directeur", ["Mmmh ! Mmmh !"]),
	"goldenrod_radio_director_untied": (NARRATION, ["{player} détache le directeur."]),
	"goldenrod_radio_director_freed": ("Directeur", [
		"Merci ! Ils m'ont enfermé dans mon propre bureau.",
		"Ces Poké Balls… ils les gardaient comme un trésor. Elles sont à toi ?"]),
	"goldenrod_radio_reunion": (NARRATION, [
		"{returning_pokemon} sort de sa Poké Ball et bondit vers {player} !",
		"{player} retrouve son équipe et son sac !"]),
	"goldenrod_radio_storage_back": (NARRATION, ["Connexion au réseau de Kanto…", "…",
		"Connexion rétablie ! Les autres Pokémon sont au Stockage."]),
	"goldenrod_radio_bags_merged": (NARRATION,
		["Les objets de ton ancien sac ont rejoint les nouveaux."]),
	"goldenrod_radio_director_gift": ("Directeur", ["Tu as sauvé la Tour, et toute la radio de Johto.",
		"La Radio de Doublonville t'offre ceci.",
		"Avec, tes nouveaux Pokémon apprendront vite auprès des anciens."]),
	"goldenrod_radio_exp_share_received": (NARRATION, ["{player} reçoit une Multi Exp !"]),
	"goldenrod_radio_director_candies": ("Directeur", ["Tu en as déjà une ? Alors prends ces bonbons."]),
	"goldenrod_radio_rare_candy_received": (NARRATION, ["{player} reçoit 3 Super Bonbons !"]),
	"goldenrod_radio_director_after": ("Directeur", [
		"L'ascenseur remarche. Les émissions reprendront dès ce soir.",
		"Reviens nous voir quand tu veux."]),
	# T-33, T-34 : l'Agente et Orme au hall.
	"goldenrod_radio_agent": ("Agente", ["C'est toi qui as libéré la Tour ? Bravo.",
		"Ces papiers… un ordre signé « D. ».", "D comme Dante, sans doute. Je les garde comme preuves."]),
	"goldenrod_radio_agent_given": (NARRATION,
		["{player} remet l'Ordre de mission et la Carte d'accès."]),
	"goldenrod_radio_elm": ("Prof. Orme", ["{player} ! J'ai tout entendu à la radio.",
		"Dante… Chen m'a parlé de lui, un jour. Il le croyait disparu depuis des années.",
		"« Quand tout sera cendres »… Ça ne me plaît pas.",
		"Les sages de Rosalia ont appelé ce matin. Ils veulent te voir.",
		"Je crois que c'est à propos de la Tour Cendrée."]),
	# T-38 : grotte marine, premier passage après le retour (variante de `sea_cave_current_back`,
	# scène du JOH1 dans `data/cutscenes/joh1.json`).
	"sea_cave_calm": (NARRATION, ["Le courant s'est calmé.", "On peut repartir vers Kanto."]),
}
# T-28 (écran du choix des 6) : titre et consigne de `TeamReturnOverlay` (JOH0), pas un dialogue.


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


def dialogue(speaker, pages, draft=False):
	entry = {}
	if speaker:
		entry["speaker"] = speaker
	else:
		entry["narration"] = True
	if draft:
		entry["draft"] = True
	entry["pages"] = pages
	return entry


def flag_lists(attrs):
	out = {}
	if "actif_avec" in attrs:
		out["if"] = attrs["actif_avec"].split(",")
	if "actif_sans" in attrs:
		out["unless"] = attrs["actif_sans"].split(",")
	return out


def item_scene(ident, item, count, flag, visible):
	steps = []
	if visible:
		steps.append({"despawn": ident})
	steps.append({"give": item, "count": count, "found": True})
	steps.append({"set": [flag]})
	return {"variants": [{"unless": [flag], "steps": steps}]}


def say(dialogue_id, **conditions):
	step = {"dialogue": dialogue_id}
	step.update(conditions)
	return step


# --- Scènes ---------------------------------------------------------------------------------


def impostor_scene():
	"""Faux employé (JH-40), déclencheur (3, 2) : avec la Carte d'accès (`johto_radio_pass`),
	T-2, combat obligatoire, T-3, T-4 et fuite par l'escalier ; sans, D-18 et un pas en arrière."""
	won = "johto_radio_impostor_defeated"
	return {"variants": [
		{"if": ["johto_radio_pass"], "unless": [won], "steps": [
			{"face": "faux_employe", "to": "player"},
			{"face": "player", "to": "faux_employe"},
			say("goldenrod_radio_impostor_intro"),
			{"battle": "goldenrod_radio_tower_impostor", "win": [won]},
			{"wait": 0.6, "if": [won]},
			say("goldenrod_radio_impostor_defeated", **{"if": [won]}),
			say("goldenrod_radio_impostor_after", **{"if": [won]}),
			say("goldenrod_radio_impostor_flees", **{"if": [won]}),
			{"move": "faux_employe", "to": [3, 1], "if": [won]},
			{"despawn": "faux_employe", "if": [won]},
			{"wake_up": True, "unless": [won]},
		]},
		{"unless": [won], "steps": [
			{"face": "faux_employe", "to": "player"},
			{"face": "player", "to": "faux_employe"},
			say("goldenrod_radio_impostor_closed"),
			{"set": ["johto_radio_tower_closed_seen"]},
			{"move": "player", "path": ["down"], "keep_facing": True},
		]},
	]}


def elevator_scene():
	"""Examen de l'ascenseur en panne : D-19 au 1F tant que le faux employé garde le hall, T-5
	ensuite et aux autres étages."""
	return {"variants": [
		{"unless": ["johto_radio_impostor_defeated"], "steps": [
			say("goldenrod_radio_elevator_closed")]},
		{"steps": [say("goldenrod_radio_elevator_broken")]},
	]}


def reserve_door_scene():
	"""Porte de la réserve (17, 11) : la clé du gardien (T-8) l'ouvre (T-9)."""
	return {"variants": [
		{"if": ["johto_radio_reserve_key"], "unless": ["johto_radio_staff_freed"], "steps": [
			say("goldenrod_radio_reserve_opened"),
			{"set": ["johto_radio_staff_freed"]},
		]},
		{"unless": ["johto_radio_staff_freed"], "steps": [say("goldenrod_radio_reserve_locked")]},
	]}


def raphael_scene():
	"""T-11 : Raphaël remercie et rentre chez lui (il quitte la réserve en fondu) [D]."""
	return {"variants": [{"unless": ["johto_radio_staff_talked"], "steps": [
		{"face": "raphael", "to": "player"},
		say("goldenrod_radio_raphael_freed"),
		{"set": ["johto_radio_staff_talked"]},
		{"despawn": "raphael"},
	]}]}


def cenere_scene():
	"""5F, déclencheur (12..13, 6) : T-15, T-16, combat obligatoire contre Cenere seule (JH-41),
	T-17, T-18, la voix de Dante (T-19 à T-21), les Sbires se divisent (T-22, JH-43), Cenere laisse
	tout (T-23, JH-42) et s'en va par l'escalier de secours ; `johto_dante_revealed`."""
	won = "johto_cenere_defeated"
	grunts = [("sbire_1", [4, 11], "right"), ("sbire_2", [18, 12], "left"),
		("sbire_3", [7, 8], "down")]
	steps = [
		say("goldenrod_radio_cenere_mic"),
		{"face": "cenere", "to": "player"},
		{"face": "player", "to": "cenere"},
		say("goldenrod_radio_cenere_early"),
		{"move": "cenere", "to": {"near": "player", "offsets": [[0, 1], [-1, 1], [1, 1]]}},
		{"face": "cenere", "to": "player"},
		{"face": "player", "to": "cenere"},
		say("goldenrod_radio_cenere_intro"),
		{"battle": "goldenrod_radio_tower_admin_cenere", "win": [won]},
		{"wake_up": True, "unless": [won]},
		{"wait": 0.6},
		say("goldenrod_radio_cenere_defeated"),
		say("goldenrod_radio_cenere_after"),
		{"wait": 0.8},
		{"react": "player"},
		say("goldenrod_radio_dante_voice"),
		say("goldenrod_radio_dante_player"),
		say("goldenrod_radio_dante_retreat"),
	]
	for ident, cell, facing in grunts:
		steps.append({"spawn": ident, "sprite": ROLE_SPRITES["sbire"], "cell": cell,
			"facing": facing})
	steps += [
		{"react": "sbire_1"},
		say("goldenrod_radio_grunt_1"),
		{"face": "sbire_2", "to": "player"},
		say("goldenrod_radio_grunt_2"),
		{"move": "sbire_2", "to": [20, 1], "background": True},
		say("goldenrod_radio_grunt_3"),
		{"face": "cenere", "to": "player"},
		say("goldenrod_radio_cenere_leaves"),
		say("goldenrod_radio_cenere_exit"),
		{"move": "cenere", "to": [22, 10], "background": True},
		{"move": "sbire_3", "to": [21, 10]},
		{"despawn": "sbire_2"},
		{"despawn": "cenere"},
		{"move": "sbire_3", "to": [22, 10]},
		{"despawn": "sbire_3"},
		{"set": ["johto_dante_revealed"]},
	]
	return {"variants": [{"unless": [won], "steps": steps}]}


def gift_steps(has_exp_all):
	if has_exp_all:
		return [
			say("goldenrod_radio_director_gift"),
			say("goldenrod_radio_director_candies"),
			{"give": "rare_candy", "count": 3},
			say("goldenrod_radio_rare_candy_received"),
			{"set": ["radio_exp_share_given"]},
			say("goldenrod_radio_director_after"),
		]
	return [
		say("goldenrod_radio_director_gift"),
		{"give": "exp_all", "count": 1},
		say("goldenrod_radio_exp_share_received"),
		{"set": ["radio_exp_share_given"]},
		say("goldenrod_radio_director_after"),
	]


def office_scene():
	"""Bureau du directeur (§7 du dossier, plan §2.5) : T-24 à T-27, `return_team` (choix des 6,
	T-28 sur l'écran), T-29 si des Pokémon sont allés au Stockage, T-30, **une seule écriture**,
	puis T-31 (Multi Exp ou 3 Super Bonbons) et T-32."""
	head = [
		say("goldenrod_radio_office_found"),
		{"move": "player", "to": {"near": "directeur", "offsets": [[1, 0], [0, 1]]}},
		{"face": "player", "to": "directeur"},
		say("goldenrod_radio_director_bound"),
		say("goldenrod_radio_director_untied"),
		{"face": "directeur", "to": "player"},
		say("goldenrod_radio_director_freed"),
		say("goldenrod_radio_reunion"),
		{"return_team": True},
		say("goldenrod_radio_storage_back", **{"if": ["johto_return_stored"]}),
		say("goldenrod_radio_bags_merged"),
		{"save": "retour de l'équipe (Tour Radio, JOH5)"},
		{"unset": ["johto_return_stored"]},
	]
	cond = {"if": ["johto_dante_revealed"], "unless": ["johto_team_returned"]}
	return {"variants": [
		dict(cond, if_items=["exp_all"], steps=head + gift_steps(True)),
		dict(cond, steps=head + gift_steps(False)),
	]}


def exp_share_scene():
	"""Reprise (plan §2.5) : équipe rendue et écrite, Multi Exp pas encore donnée."""
	cond = {"if": ["johto_team_returned"], "unless": ["radio_exp_share_given"]}
	return {"variants": [
		dict(cond, if_items=["exp_all"], steps=[{"face": "directeur", "to": "player"}]
			+ gift_steps(True)),
		dict(cond, steps=[{"face": "directeur", "to": "player"}] + gift_steps(False)),
	]}


def exit_scene():
	"""1F, rangée y 12 : T-33 (l'Agente garde les preuves) puis T-34 (Orme), `johto_act2`."""
	return {"variants": [{"if": ["johto_team_returned"], "unless": ["johto_act2"], "steps": [
		{"face": "agente", "to": "player"},
		{"face": "player", "to": "agente"},
		say("goldenrod_radio_agent"),
		{"take": ORDERS_ITEM, "count": 1},
		{"take": PASS_ITEM, "count": 1},
		say("goldenrod_radio_agent_given"),
		{"face": "orme", "to": "player"},
		{"face": "player", "to": "orme"},
		say("goldenrod_radio_elm"),
		{"set": ["johto_act2"]},
		{"move": "orme", "to": [12, 15], "background": True},
		{"move": "agente", "to": [11, 15]},
		{"despawn": "orme"},
		{"despawn": "agente"},
	]}]}


# --- Assemblage -----------------------------------------------------------------------------


def main():
	dialogues = {}
	cutscenes = {}
	trainers = {}
	for trainer_id, (name, klass, prize, _sprite, team) in TRAINERS.items():
		entry = {"name": name, "class": klass, "ai": "random", "can_lose": False,
			"heal_after": False, "gives_exp": True, "prize_money": 0, "prize_per_level": prize,
			"team": [{"species": s, "level": lv} for s, lv in team]}
		if trainer_id == "goldenrod_radio_tower_admin_cenere":
			# Comme Brace (JOH4) : IA « smart », ni séquence « VS » ni changement de Pokémon [D].
			entry["ai"] = "smart"
		trainers[trainer_id] = entry
		if trainer_id in TRAINER_LINES:
			before, defeated, after = TRAINER_LINES[trainer_id]
			dialogues[trainer_id + "_before"] = dialogue(GRUNT, [before])
			dialogues[trainer_id + "_defeated"] = dialogue(GRUNT, [defeated])
			dialogues[trainer_id + "_after"] = dialogue(GRUNT, [after])
	# T-8 : le gardien vaincu donne la clé de la réserve.
	dialogues["goldenrod_radio_tower_keeper_defeated"]["set"] = ["johto_radio_reserve_key"]
	for ident, value in T.items():
		dialogues[ident] = dialogue(*value)

	for floor in FLOORS:
		map_id = MAP % floor
		npcs = {}
		for ident, (kind, cells, attrs, _comment) in read_plan("radio_tower_%df" % floor).items():
			cell = list(cells[0])
			if kind == "dresseur":
				trainer_id = attrs["trainer"]
				sprite = TRAINERS[trainer_id][3]
				entry = {"cell": cell, "facing": attrs["facing"], "sprite": sprite}
				entry.update(flag_lists(attrs))
				if trainer_id in SCENE_TRAINERS:
					if trainer_id == "goldenrod_radio_tower_impostor":
						entry["sprite"] = "engineer"  # déguisé [D]
						entry["dialogue"] = "goldenrod_radio_impostor"
						dialogues["goldenrod_radio_impostor"] = {"cutscene": "goldenrod_radio_impostor"}
					else:
						entry["dialogue"] = "goldenrod_radio_cenere"
						dialogues["goldenrod_radio_cenere"] = {"cutscene": "goldenrod_radio_cenere"}
				else:
					entry["dialogue"] = trainer_id + "_after"
					entry["trainer"] = {"id": trainer_id, "sight": int(attrs["sight"]),
						"before": trainer_id + "_before", "defeated": trainer_id + "_defeated"}
				npcs[ident] = entry
			elif kind == "pnj":
				role = attrs.get("role", "")
				entry = {"cell": cell, "facing": attrs.get("facing", "down"),
					"sprite": ROLE_SPRITES[role]}
				entry.update(flag_lists(attrs))
				if role == "sbire":
					if ident != "sbire_1":
						continue  # T-22 : Sbires 2 et 3 partent avec la scène (JH-43) [D]
					entry["if"] = ["johto_dante_revealed"]
					entry["dialogue"] = "goldenrod_radio_grunt_1"
				elif role == "employee":
					entry["dialogue"] = "goldenrod_radio_employee"
				elif role == "employe":
					entry["dialogue"] = "goldenrod_radio_employee_2"
				elif role == "raphael":
					entry["dialogue"] = "goldenrod_radio_raphael"
					dialogues["goldenrod_radio_raphael"] = {"cutscene": "goldenrod_radio_raphael"}
					cutscenes["goldenrod_radio_raphael"] = raphael_scene()
				elif role == "directeur":
					entry["dialogue"] = "goldenrod_radio_director"
					dialogues["goldenrod_radio_director"] = {"speaker": "Directeur", "variants": [
						{"if": ["johto_dante_revealed"], "unless": ["johto_team_returned"],
							"cutscene": "goldenrod_radio_office"},
						{"if": ["johto_team_returned"], "unless": ["radio_exp_share_given"],
							"cutscene": "goldenrod_radio_exp_share"},
						{"if": ["johto_team_returned"],
							"pages": T["goldenrod_radio_director_after"][1]},
						{"pages": ["Mmmh ! Mmmh !"]},
					]}
				elif role == "agente":
					entry["dialogue"] = "goldenrod_radio_exit"
				elif role == "orme":
					entry["dialogue"] = "goldenrod_radio_exit"
				npcs[ident] = entry
			elif kind == "objet_visible":
				flag = "got_" + ident
				npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"dialogue": ident, "verb": "take", "turn_to_player": False, "unless": [flag]}
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = item_scene(ident, attrs["item"], int(attrs.get("count", 1)),
					flag, True)
			elif kind == "cache":
				flag = "got_" + ident
				dialogues[ident] = {"cutscene": ident}
				cutscenes[ident] = item_scene(ident, attrs["item"], 1, flag, False)
			elif kind == "decor" and attrs.get("role") == "poke_balls_et_sac":
				# Les Poké Balls de l'équipe sur le bureau (T-24), jusqu'au retour.
				npcs[ident] = {"cell": cell, "facing": "down", "sprite": "object/poke_ball_ground",
					"unless": ["johto_team_returned"]}
		write_json(os.path.join(DATA, "npcs", map_id + ".json"), npcs)

	dialogues["goldenrod_radio_exit"] = {"cutscene": "goldenrod_radio_exit"}
	for ident in ("goldenrod_radio_elevator", "goldenrod_radio_reserve_door",
			"goldenrod_radio_office", "goldenrod_radio_exp_share"):
		dialogues[ident] = {"cutscene": ident}
	cutscenes.update({
		"goldenrod_radio_impostor": impostor_scene(),
		"goldenrod_radio_elevator": elevator_scene(),
		"goldenrod_radio_reserve_door": reserve_door_scene(),
		"goldenrod_radio_cenere": cenere_scene(),
		"goldenrod_radio_office": office_scene(),
		"goldenrod_radio_exp_share": exp_share_scene(),
		"goldenrod_radio_exit": exit_scene(),
	})
	write_json(os.path.join(DATA, "trainers", TRAINER_FILE + ".json"), trainers)
	write_json(os.path.join(DATA, "dialogues", "joh5_radio_tower.json"), dialogues)
	write_json(os.path.join(DATA, "cutscenes", "joh5_radio_tower.json"), cutscenes)


if __name__ == "__main__":
	main()
