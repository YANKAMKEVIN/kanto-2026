#!/usr/bin/env python3
"""Contrôle des données audio (docs/tech/jalon-son.md §1.12).

- toute carte (`game/world/maps/*.tscn` et `data/world/zones.json`) a une musique : par carte,
  par zone, ou une exception explicite « silence » ;
- tout morceau, bruitage ou ambiance référencé existe dans `tracks.json`, `sfx.json`,
  `ambiences.json` (aucun identifiant inconnu) ;
- tout fichier référencé existe sur le disque **ou** est déclaré « expected » (attendu : le jeu
  reste muet tolérant) ; un fichier déclaré présent mais absent est une erreur ;
- avec `--branches` : les cartes des branches ouvertes (relues par `git show`, sans checkout)
  sont couvertes aussi, et chaque zone ou carte citée existe sur au moins une des références.

Usage : python3 tools/audio/check_audio_data.py [--branches [réf…]]
  (défaut des branches : origin/jalon-23, origin/jalon-26 à origin/jalon-31)
"""
import glob
import json
import os
import subprocess
import sys

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
AUDIO = os.path.join(RACINE, "data", "audio")
SILENCE = "silence"
AUCUNE = "none"
BRANCHES = ["origin/jalon-23"] + ["origin/jalon-%d" % n for n in range(26, 32)]
erreurs = []
notes = []


def lire(nom):
	with open(os.path.join(AUDIO, nom), encoding="utf-8") as f:
		return json.load(f)


def fichier_present(chemin):
	if not chemin.startswith("res://"):
		return False
	return os.path.isfile(os.path.join(RACINE, chemin[len("res://"):]))


def verifier_fichier(origine, chemin, attendu):
	if not chemin.startswith("res://"):
		erreurs.append(f"{origine} : chemin hors res:// : {chemin}")
	elif not fichier_present(chemin) and not attendu:
		erreurs.append(f"{origine} : fichier absent et non déclaré attendu : {chemin}")


def zones_de(ref):
	"""zone → cartes, lu dans data/world/zones.json de la référence (None = copie de travail)."""
	if ref is None:
		with open(os.path.join(RACINE, "data", "world", "zones.json"), encoding="utf-8") as f:
			texte = f.read()
	else:
		sortie = subprocess.run(["git", "-C", RACINE, "show", f"{ref}:data/world/zones.json"],
			capture_output=True, text=True)
		if sortie.returncode != 0:
			notes.append(f"{ref} : zones.json illisible ({sortie.stderr.strip()}), ignorée")
			return None
		texte = sortie.stdout
	return {z: list(v.get("maps", [])) for z, v in json.loads(texte)["zones"].items()}


tracks = lire("tracks.json")
zones_musique = lire("music_zones.json")
combats = lire("battle_music.json")
sfx = lire("sfx.json")
ambiances = lire("ambiences.json")

morceaux = tracks["tracks"]
for tid, t in morceaux.items():
	if tid == SILENCE:
		erreurs.append("tracks.json : « silence » est réservé")
	if t.get("kind") not in ("music", "jingle"):
		erreurs.append(f"tracks.json {tid} : kind « {t.get('kind')} » inconnu")
	verifier_fichier(f"tracks.json {tid}", t.get("file", ""), t.get("expected", False))


def morceau(origine, tid):
	if tid != SILENCE and tid not in morceaux:
		erreurs.append(f"{origine} : morceau inconnu « {tid} »")


for evt, tid in tracks.get("events", {}).items():
	morceau(f"tracks.json events.{evt}", tid)
for z, tid in zones_musique["zones"].items():
	morceau(f"music_zones.json zones.{z}", tid)
for m, tid in zones_musique["maps"].items():
	morceau(f"music_zones.json maps.{m}", tid)
for mode, tid in zones_musique.get("movement", {}).items():
	morceau(f"music_zones.json movement.{mode}", tid)
for i, regle in enumerate(zones_musique.get("flags", [])):
	morceau(f"music_zones.json flags[{i}]", regle["track"])
for cat, c in combats["categories"].items():
	morceau(f"battle_music.json {cat}.battle", c["battle"])
	morceau(f"battle_music.json {cat}.victory", c["victory"])
for nom, tid in combats["encounter_themes"].items():
	morceau(f"battle_music.json encounter_themes.{nom}", tid)
categories = combats["categories"]
if combats["default_category"] not in categories:
	erreurs.append("battle_music.json : default_category inconnue")
for tr, cat in combats["trainers"].items():
	if cat not in categories:
		erreurs.append(f"battle_music.json trainers.{tr} : catégorie inconnue « {cat} »")
themes = combats["encounter_themes"]
for origine, table in (("encounter_trainers", combats["encounter_trainers"]),
		("encounter_prefixes", combats["encounter_prefixes"])):
	for cle, theme in table.items():
		if theme not in themes:
			erreurs.append(f"battle_music.json {origine}.{cle} : thème inconnu « {theme} »")
if combats["default_encounter"] not in themes:
	erreurs.append("battle_music.json : default_encounter inconnu")

bruitages = sfx["sfx"]
for sid, s in bruitages.items():
	if not s.get("files"):
		erreurs.append(f"sfx.json {sid} : aucun fichier")
	for chemin in s.get("files", []):
		verifier_fichier(f"sfx.json {sid}", chemin, s.get("expected", False))
	if int(s.get("max_polyphony", 1)) < 1:
		erreurs.append(f"sfx.json {sid} : max_polyphony < 1")
sons = sfx["move_sounds"]
references = list(sons["moves"].items()) + list(sons["by_category"].items())
for ty, par_cat in sons["by_type"].items():
	references += [(f"{ty}.{c}", v) for c, v in par_cat.items()]
for cle, sid in references:
	if sid not in bruitages:
		erreurs.append(f"sfx.json move_sounds {cle} : bruitage inconnu « {sid} »")
for cat in ("physical", "special", "status"):
	if cat not in sons["by_category"]:
		erreurs.append(f"sfx.json move_sounds.by_category : « {cat} » manque")

boucles = ambiances["ambiences"]
for aid, a in boucles.items():
	verifier_fichier(f"ambiences.json {aid}", a.get("file", ""), a.get("expected", False))
for origine in ("zones", "maps", "weather"):
	for cle, aid in ambiances.get(origine, {}).items():
		if aid != AUCUNE and aid not in boucles:
			erreurs.append(f"ambiences.json {origine}.{cle} : ambiance inconnue « {aid} »")


def couverture(nom_ref, zones):
	"""Chaque carte de [zones] a une musique (carte, puis zone)."""
	manquantes = []
	for z, cartes in zones.items():
		for carte in cartes:
			if carte not in zones_musique["maps"] and z not in zones_musique["zones"]:
				manquantes.append(f"{carte} (zone {z})")
	for carte in manquantes:
		erreurs.append(f"{nom_ref} : carte sans musique : {carte}")
	return sum(len(c) for c in zones.values())


zones_main = zones_de(None)
cartes_main = {c for cartes in zones_main.values() for c in cartes}
total = couverture("copie de travail", zones_main)
for scene in sorted(glob.glob(os.path.join(RACINE, "game", "world", "maps", "*.tscn"))):
	carte = os.path.splitext(os.path.basename(scene))[0]
	if carte not in cartes_main and carte not in zones_musique["maps"]:
		erreurs.append(f"game/world/maps/{carte}.tscn : carte hors zones.json et sans musique")
connues_zones = set(zones_main)
connues_cartes = set(cartes_main)

args = sys.argv[1:]
if args and args[0] == "--branches":
	refs = args[1:] or BRANCHES
	for ref in refs:
		zones = zones_de(ref)
		if zones is None:
			continue
		n = couverture(ref, zones)
		notes.append(f"{ref} : {n} cartes couvertes")
		connues_zones |= set(zones)
		connues_cartes |= {c for cartes in zones.values() for c in cartes}
	for z in zones_musique["zones"]:
		if z not in connues_zones:
			erreurs.append(f"music_zones.json zones.{z} : zone inconnue sur toutes les références")
	for m in zones_musique["maps"]:
		if m not in connues_cartes:
			erreurs.append(f"music_zones.json maps.{m} : carte inconnue sur toutes les références")

attendus = sum(1 for t in morceaux.values() if not fichier_present(t["file"]))
print("\n".join(notes))
if erreurs:
	print("\n".join(erreurs))
	sys.exit(1)
print(f"Audio : {total} cartes couvertes, {len(morceaux)} morceaux ({attendus} attendus), "
	f"{len(bruitages)} bruitages, {len(boucles)} ambiances.")
