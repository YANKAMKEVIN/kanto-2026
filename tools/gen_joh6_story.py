#!/usr/bin/env python3
"""Scènes d'histoire du jalon JOH6 (« les cendres »), plan `docs/tech/jalon-joh6.md` §2.5 à §2.7.

Écrit `data/dialogues/joh6_story.json`, `data/cutscenes/joh6_story.json` et les PNJ du décor du
souvenir (`data/npcs/dante_flashback_hq.json`), d'après `docs/design/dossier-joh-07-acajou.md`
(textes C-5 à C-11, C-25, C-28, C-30, C-32 à C-38, C-42 à C-45 validés par Kevin le 2026-11-02,
**mot pour mot** ; « / » = page). Les PNJ, Dresseurs, objets et textes simples des cartes sont
écrits par `tools/gen_joh6_data.py` (contrat d'identifiants du plan §2.3). Textes absents du
dossier : « draft » (PENDING_DRAFTS).

Usage : python3 -I tools/gen_joh6_story.py
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")

BRACE = "Brace"
DOYEN = "Doyen"
DESERTER = "Déserteur"
HIDEOUT_B1F = "mahogany_hideout_b1f"
HIDEOUT_B3F = "mahogany_hideout_b3f"
BRACE_TRAINER = "mahogany_hideout_b3f_brace"
# Sbires d'alarme du B1F : (statue, case de leur porte dérobée, regard), grille
# `mahogany_hideout_b1f.txt` ; Dresseurs `mahogany_hideout_b1f_sbire_alarme_N` (gen_joh6_data).
ALARMS = {
	1: ([10, 1], "down", "rocket_grunt_m"),
	2: ([19, 13], "up", "rocket_grunt_f"),
	3: ([24, 1], "down", "rocket_grunt_m"),
}


def say(speaker, pages, draft=False):
	entry = {}
	if speaker:
		entry["speaker"] = speaker
	else:
		entry["narration"] = True
	if draft:
		entry["draft"] = True
	entry["pages"] = pages
	return entry


def narration(pages, draft=False):
	return say(None, pages, draft)


def beaten(trainer_id):
	return "beaten_" + trainer_id


DIALOGUES = {
	# --- Tour Cendrée B1F : les trois chiens et Brace (C-6 à C-9) ---
	"joh6_beasts_sleep": narration(["Trois Pokémon dorment au milieu des cendres.", "…"]),
	"joh6_beasts_wake": narration(["Ils ouvrent les yeux !"]),
	"joh6_beasts_flee": narration(["Ils bondissent hors de la tour, chacun dans une direction !"]),
	"joh6_brace_arrives": say(BRACE, ["Ha ! Je savais que tu les réveillerais pour moi !",
		"Merci du coup de main, le gamin !"]),
	"joh6_brace_cage_thrown": narration(["Brace lance une cage métallique !"]),
	"joh6_brace_cage_caught": narration(["Raikou est pris dans un filet d'éclairs !"]),
	"joh6_brace_leaves_tower": say(BRACE, ["Un sur trois, c'est déjà pas mal.",
		"Le patron s'occupera des deux autres.", "À plus, le gamin !"]),
	# --- Rosalia : le doyen à la sortie de la tour (C-10, C-11) ---
	"joh6_doyen_plan": say(DOYEN, [
		"Ils sont réveillés… et l'un d'eux est captif.",
		"Écoute. La légende dit que Ho-Oh veille sur ces trois-là.",
		"Si un homme les tient tous les trois, Ho-Oh descendra à la Tour Carillon pour les sauver.",
		"C'est donc ça, son plan : forcer Ho-Oh à descendre.",
		"Et s'emparer de sa flamme. La flamme qui a fait renaître la tour…",
		"Entre de mauvaises mains, elle peut tout réduire en cendres.",
		"L'homme qui a pris Raikou est parti vers l'est. Vers Acajou."]),
	# --- Lac Colère : le Léviator rouge (C-25) ---
	"joh6_red_gyarados": {"narration": True, "variants": [
		{"unless": ["johto_red_gyarados_done"], "cutscene": "lake_red_gyarados",
			"pages": ["Un Léviator rouge surgit des eaux !", "Il est furieux !"]},
	]},
	# --- Boutique de souvenirs : l'escalier caché (C-28) ---
	"joh6_shop_stairs": narration(["Un courant d'air froid sort de sous une étagère.", "…",
		"Un escalier !"]),
	# --- Repaire B1F : statues de Persian (C-30) ---
	"joh6_hideout_alarm": narration(["Les yeux de la statue s'allument !",
		"Une alarme retentit !"]),
	# --- Repaire B2F : levier, déserteur, souvenir, mot de passe (C-32 à C-38) ---
	"mahogany_hideout_b2f_levier": {"narration": True, "variants": [
		{"unless": ["johto_cell_opened"], "cutscene": "hideout_lever",
			"pages": ["Un levier. Il commande les grilles des cellules."], "draft": True},
	]},
	"joh6_lever_pulled": narration(["Le levier bascule.",
		"La grille de la cellule du milieu s'ouvre !"], True),
	"joh6_deserter": {"speaker": DESERTER, "variants": [
		{"unless": ["johto_cell_opened"], "pages": ["Hé, toi ! Le gamin de la radio ! Sors-moi de là.",
			"Je ne suis pas avec eux. Plus maintenant."]},
		{"unless": ["johto_dante_flashback_seen"], "cutscene": "hideout_deserter",
			"pages": ["Merci.",
				"Après la Tour Radio, j'ai dit non. Je suis venu pour Giovanni, pas pour lui.",
				"Brace m'a jeté ici.",
				"Tu veux savoir qui est Dante ? J'étais là, moi. Il y a vingt ans."]},
		{"pages": ["La porte du fond a un mot de passe.",
			"Avant, c'était « Vive Giovanni ». Maintenant, c'est « Gloire à Dante ».",
			"Ça me brûle la langue de le dire."]},
	]},
	"joh6_deserter_story": say(DESERTER, ["Dante était notre chef. Le premier.",
		"Giovanni était son bras droit. Son élève. Presque son fils.",
		"Et puis il y a eu l'incendie…"]),
	"joh6_flashback_dante": say("Dante", ["Giovanni ! La porte est bloquée ! Ouvre !"]),
	"joh6_flashback_silence": narration(["…"]),
	"joh6_flashback_giovanni": say("Giovanni", ["Tu m'as tout appris, Dante.",
		"Même ça. Surtout ça."]),
	"joh6_flashback_leaves": narration(["(Giovanni s'éloigne avec Persian. Les flammes montent.)"]),
	"joh6_deserter_after": say(DESERTER, ["Tout le monde l'a cru mort. Giovanni a pris la Team Rocket.",
		"Mais Dante a survécu. Brûlé, défiguré.",
		"Il a attendu vingt ans. Et maintenant, il veut tout brûler à son tour."]),
	"joh6_deserter_password": say(DESERTER, ["La porte du fond a un mot de passe.",
		"Avant, c'était « Vive Giovanni ». Maintenant, c'est « Gloire à Dante ».",
		"Ça me brûle la langue de le dire."]),
	"mahogany_hideout_b2f_porte_mdp": {"narration": True, "variants": [
		{"unless": ["johto_dante_flashback_seen"], "pages": ["« Mot de passe ? »"]},
		{"unless": ["johto_password_said"], "cutscene": "hideout_password",
			"pages": ["« Mot de passe ? »"]},
	]},
	"joh6_password": narration(["{player} : Gloire à Dante.", "La porte s'ouvre."]),
	# --- Repaire B3F : Brace, générateur, Raikou (C-42 à C-44) ---
	"joh6_brace_leaves": say(BRACE, ["Ta victoire ne change rien.",
		"Cenere est déjà partie chercher le deuxième.",
		"Et le patron ira chercher le troisième lui-même.",
		"On se reverra au sommet, le gamin !"]),
	"joh6_brace_escape": narration(["Brace s'enfuit par un passage secret !"]),
	"mahogany_hideout_b3f_arret_generateur": {"narration": True, "variants": [
		{"unless": ["johto_generator_off"], "cutscene": "hideout_generator_off",
			"pages": ["{player} coupe le générateur.", "…",
				"Le bourdonnement s'arrête. La cage s'ouvre !"]},
	]},
	"joh6_raikou": {"narration": True, "variants": [
		{"unless": ["johto_generator_off"], "pages": ["Raikou sert de pile à la machine !"]},
		{"unless": ["johto_raikou_done"], "cutscene": "hideout_raikou",
			"pages": ["Raikou rugit !"]},
	]},
	# --- Acajou : le déserteur au Centre (C-45) ---
	"joh6_deserter_center": {"speaker": DESERTER, "variants": [
		{"unless": ["johto_whirl_clue"], "set": ["johto_whirl_clue"],
			"pages": ["Le lac est calme, la machine est morte. Merci.",
				"Écoute : Cenere est partie vers la mer, à l'ouest.",
				"Le Pokémon bleu, celui qui court sur l'eau…",
				"Elle le cherche aux Îles Tourbillon. Les Sbires en parlaient."]},
		{"pages": ["Elle le cherche aux Îles Tourbillon. Les Sbires en parlaient."]},
	]},
}


def guard_back(guard, dialogue_id, flag, back):
	return {"variants": [{"unless": [flag], "steps": [
		{"face": guard, "to": "player"},
		{"face": "player", "to": guard},
		{"dialogue": dialogue_id},
		{"move": "player", "path": [back], "keep_facing": True},
	]}]}


def alarm_scene(number):
	"""C-30 puis le Sbire appelé sort de sa porte dérobée et vient au joueur (combat obligatoire,
	une fois par statue ; il vient même si le joueur recule, dossier §13). Les PNJ du fichier ne
	changent qu'à l'arrivée sur la carte : le Sbire de cette visite est créé par la scène ; le PNJ
	`sbire_alarme_N` (présent avec `johto_alarm_N`) prend le relais aux visites suivantes."""
	cell, facing, sprite = ALARMS[number]
	trainer = "%s_sbire_alarme_%d" % (HIDEOUT_B1F, number)
	actor = "sbire_alarme_%d_appel" % number
	flag = "johto_alarm_%d" % number
	return {"variants": [{"unless": [flag], "steps": [
		{"set": [flag]},
		{"flash": 1},
		{"dialogue": "joh6_hideout_alarm"},
		{"spawn": actor, "sprite": sprite, "cell": cell, "facing": facing,
			"dialogue": trainer + "_after"},
		{"emote": actor, "kind": "exclamation"},
		{"move": actor,
			"to": {"near": "player", "offsets": [[0, -1], [0, 1], [-1, 0], [1, 0]]}},
		{"face": "player", "to": actor},
		{"face": actor, "to": "player"},
		{"dialogue": trainer + "_before"},
		{"battle": trainer, "win": [beaten(trainer)]},
		{"dialogue": trainer + "_defeated", "if": [beaten(trainer)]},
		{"wake_up": True, "unless": [beaten(trainer)]},
	]}]}


CUTSCENES = {
	# C-5 : une fois, en approchant de la bande effondrée (texte : gen_joh6_data).
	"burned_tower_floor": {"variants": [{"unless": ["johto_burned_floor_seen"], "steps": [
		{"set": ["johto_burned_floor_seen"]},
		{"dialogue": "burned_tower_1f_plancher_effondre"},
	]}]},
	# C-6 à C-9 : réveil et fuite, Brace et la cage à ondes, départ vers l'est. Drapeaux posés à
	# la fin (scène interrompue = rejouée, les chiens sont encore là au rechargement).
	"burned_tower_beasts": {"variants": [{"unless": ["johto_beasts_awakened"], "steps": [
		{"face": "player", "to": "entei"},
		{"dialogue": "joh6_beasts_sleep"},
		{"react": "raikou"},
		{"react": "entei"},
		{"react": "suicune"},
		{"dialogue": "joh6_beasts_wake"},
		{"dialogue": "joh6_beasts_flee"},
		# Planches provisoires sans marche [D] : Suicune et Entei s'effacent d'un bond ; Raikou
		# reste pour la cage.
		{"despawn": "suicune"},
		{"despawn": "entei"},
		{"spawn": "brace", "sprite": "rocket_civilian", "cell": [18, 8], "facing": "left"},
		{"move": "brace", "to": [13, 8]},
		{"face": "player", "to": "brace"},
		{"dialogue": "joh6_brace_arrives"},
		{"dialogue": "joh6_brace_cage_thrown"},
		{"flash": 2},
		{"react": "raikou"},
		{"dialogue": "joh6_brace_cage_caught"},
		{"face": "brace", "to": "player"},
		{"dialogue": "joh6_brace_leaves_tower"},
		{"despawn": "raikou"},
		{"move": "brace", "to": [18, 8]},
		{"despawn": "brace"},
		{"set": ["johto_beasts_awakened", "johto_raikou_taken"]},
	]}]},
	# C-10, C-11 : le doyen attend à la sortie de la tour (Rosalia, plan §2.5).
	"ecruteak_dante_plan": {"variants": [{"if": ["johto_raikou_taken"],
		"unless": ["johto_dante_plan_known"], "steps": [
			{"spawn": "doyen_parvis", "sprite": "mr_fuji", "cell": [12, 15], "facing": "left"},
			{"move": "doyen_parvis",
				"to": {"near": "player", "offsets": [[1, 0], [0, 1], [-1, 0], [1, 1]]}},
			{"face": "player", "to": "doyen_parvis"},
			{"face": "doyen_parvis", "to": "player"},
			{"dialogue": "joh6_doyen_plan"},
			{"set": ["johto_dante_plan_known"]},
			{"move": "doyen_parvis", "to": [21, 13]},
			{"despawn": "doyen_parvis"},
		]}]},
	# C-25 : combat fixe (JH-46), variante rouge, capture possible ; K.O. ou capture : il ne
	# revient pas (rencontre fixe) ; fuite : il reste.
	"lake_red_gyarados": {"variants": [{"unless": ["johto_red_gyarados_done"], "steps": [
		{"wild_battle": "gyarados", "level": 50, "variant": "red", "actor": "leviator_rouge",
			"static": {"done": "johto_red_gyarados_done", "caught": "johto_red_gyarados_caught"}},
	]}]},
	# C-28, C-29 : après le lac seulement ; l'étagère s'efface (FlagGate), le vendeur réagit.
	"souvenir_shop_stairs": {"variants": [{"if": ["johto_red_gyarados_done"],
		"unless": ["johto_hideout_found"], "steps": [
			{"face": "player", "to": "up"},
			{"dialogue": "joh6_shop_stairs"},
			{"set": ["johto_hideout_found"]},
			{"emote": "vendeur", "kind": "exclamation"},
			{"face": "player", "to": "vendeur"},
			{"dialogue": "mahogany_souvenir_shop_vendeur"},
		]}]},
	"hideout_alarm_1": alarm_scene(1),
	"hideout_alarm_2": alarm_scene(2),
	"hideout_alarm_3": alarm_scene(3),
	"hideout_lever": {"variants": [{"unless": ["johto_cell_opened"], "steps": [
		{"dialogue": "joh6_lever_pulled"},
		{"set": ["johto_cell_opened"]},
	]}]},
	# C-33 à C-37 et le souvenir sépia (plan §2.7) ; drapeau posé à la fin.
	"hideout_deserter": {"variants": [{"unless": ["johto_dante_flashback_seen"], "steps": [
		{"dialogue": "joh6_deserter_story"},
		{"flashback": "start"},
		{"change_map": "dante_flashback_hq", "at": "vue", "facing": "up"},
		{"wait": 0.6},
		{"dialogue": "joh6_flashback_dante"},
		{"face": "giovanni_jeune", "to": "up"},
		{"dialogue": "joh6_flashback_silence"},
		{"dialogue": "joh6_flashback_giovanni"},
		{"face": "giovanni_jeune", "to": "down"},
		{"move": "giovanni_jeune", "to": [7, 8]},
		{"despawn": "persian"},
		{"flash": 2},
		{"dialogue": "joh6_flashback_leaves"},
		{"despawn": "giovanni_jeune"},
		{"wait": 0.8},
		{"change_map": "mahogany_hideout_b2f", "at": "devant_deserteur", "facing": "down"},
		{"flashback": "end"},
		{"face": "deserteur", "to": "player"},
		{"dialogue": "joh6_deserter_after"},
		{"dialogue": "joh6_deserter_password"},
		{"set": ["johto_dante_flashback_seen"]},
	]}]},
	# C-38 : la porte s'efface (FlagGate) avec `johto_password_said`.
	"hideout_password": {"variants": [{"if": ["johto_dante_flashback_seen"],
		"unless": ["johto_password_said"], "steps": [
			{"dialogue": "joh6_password"},
			{"set": ["johto_password_said"]},
		]}]},
	# C-40 à C-42 : combat obligatoire ; défaite : Centre d'Acajou, Brace reste.
	"hideout_brace": {"variants": [{"unless": ["johto_brace_defeated_2"], "steps": [
		{"emote": "brace", "kind": "exclamation"},
		{"move": "brace", "to": {"near": "player", "offsets": [[1, 0], [1, -1], [1, 1]]}},
		{"face": "player", "to": "brace"},
		{"face": "brace", "to": "player"},
		{"dialogue": BRACE_TRAINER + "_before"},
		{"battle": BRACE_TRAINER, "win": [beaten(BRACE_TRAINER)]},
		{"dialogue": BRACE_TRAINER + "_defeated", "if": [beaten(BRACE_TRAINER)]},
		{"dialogue": "joh6_brace_leaves", "if": [beaten(BRACE_TRAINER)]},
		{"move": "brace", "to": [22, 12], "if": [beaten(BRACE_TRAINER)]},
		{"dialogue": "joh6_brace_escape", "if": [beaten(BRACE_TRAINER)]},
		{"despawn": "brace", "if": [beaten(BRACE_TRAINER)]},
		# Posé après le départ (le PNJ de Brace en dépend) ; défaite : Centre, Brace reste.
		{"set": ["johto_brace_defeated_2"], "if": [beaten(BRACE_TRAINER)]},
		{"wake_up": True, "unless": [beaten(BRACE_TRAINER)]},
	]}]},
	"hideout_generator_off": {"variants": [{"if": ["johto_brace_defeated_2"],
		"unless": ["johto_generator_off"], "steps": [
			{"flash": 1},
			{"set": ["johto_generator_off"]},
		]}]},
	# C-44 : combat et capture, niv. 60 ; capture ou K.O. : rencontre consommée ; fuite aussi
	# (dossier §6 : Raikou reviendra à la Tour Cendrée après le chapitre) ; défaite : il reste.
	"hideout_raikou": {"variants": [{"if": ["johto_generator_off"],
		"unless": ["johto_raikou_done"], "steps": [
			{"wild_battle": "raikou", "level": 60, "intro": "legendary", "actor": "raikou",
				"static": {"done": "johto_raikou_done", "caught": "johto_raikou_caught"},
				"flee": ["johto_raikou_done", "johto_raikou_fled"]},
			# Fuite : l'étape ne retire l'acteur que sur capture ou K.O. ; Raikou part aussi.
			{"despawn": "raikou", "if": ["johto_raikou_fled"]},
		]}]},
	# Sentier du Mont Argenté : fermé pendant l'acte 2 (texte du garde : gen_joh6_data).
	"lake_trail_guard": guard_back("garde_forestier", "lake_of_rage_garde_forestier",
		"johto_act3", "left"),
}

# Décor du souvenir (plan §2.7) : Dante jeune derrière la porte en feu, Giovanni jeune et Persian.
FLASHBACK_NPCS = {
	"dante_jeune": {"cell": [7, 3], "facing": "down", "sprite": "gentleman",
		"turn_to_player": False},
	"giovanni_jeune": {"cell": [7, 5], "facing": "up", "sprite": "giovanni",
		"turn_to_player": False},
	"persian": {"cell": [8, 5], "facing": "up", "sprite": "pokemon/persian",
		"turn_to_player": False},
}


def write_json(path, data):
	text = json.dumps(data, ensure_ascii=False, indent="\t") + "\n"
	with open(path, "w", encoding="utf-8") as handle:
		handle.write(text)
	print("écrit :", os.path.relpath(path, ROOT))


def main():
	for number in ALARMS:
		assert ("hideout_alarm_%d" % number) in CUTSCENES
	write_json(os.path.join(DATA, "dialogues", "joh6_story.json"), DIALOGUES)
	write_json(os.path.join(DATA, "cutscenes", "joh6_story.json"), CUTSCENES)
	write_json(os.path.join(DATA, "npcs", "dante_flashback_hq.json"), FLASHBACK_NPCS)


if __name__ == "__main__":
	main()
