#!/usr/bin/env python3
"""Génère data/pokemon/species/johto.json (51 espèces de Johto, JOH0 T6) depuis des fichiers PokeAPI déjà
téléchargés, et liste les attaques des learnsets absentes des données.

Usage : python3 -I tools/gen_johto_data.py <dossier_pokeapi> [--fetch]
  <dossier_pokeapi> contient pokemon/<n>.json et species/<n>.json (et move/<id>.json, créé au besoin).
  --fetch : télécharge (curl) ce qui manque (pokemon, species).
Le fichier produit est ensuite relu à la main pour les attaques (data/pokemon/moves/johto.json),
les familles d'effets (data/battle/move_fx/johto.json) et les fiches du Pokédex."""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (numéro, identifiant, nom français)
SPECIES = [
    (152, "chikorita", "Germignon"), (153, "bayleef", "Macronium"), (154, "meganium", "Méganium"),
    (155, "cyndaquil", "Héricendre"), (156, "quilava", "Feurisson"), (157, "typhlosion", "Typhlosion"),
    (158, "totodile", "Kaiminus"), (159, "croconaw", "Crocrodil"), (160, "feraligatr", "Aligatueur"),
    (161, "sentret", "Fouinette"), (162, "furret", "Fouinar"), (163, "hoothoot", "Hoothoot"),
    (164, "noctowl", "Noarfang"), (179, "mareep", "Wattouat"), (180, "flaaffy", "Lainergie"),
    (181, "ampharos", "Pharamp"), (183, "marill", "Marill"), (184, "azumarill", "Azumarill"),
    (175, "togepi", "Togepi"), (176, "togetic", "Togetic"), (196, "espeon", "Mentali"),
    (197, "umbreon", "Noctali"), (199, "slowking", "Roigada"), (208, "steelix", "Steelix"),
    (212, "scizor", "Cizayox"), (214, "heracross", "Scarhino"), (215, "sneasel", "Farfuret"),
    (216, "teddiursa", "Teddiursa"), (217, "ursaring", "Ursaring"), (231, "phanpy", "Phanpy"),
    (232, "donphan", "Donphan"), (233, "porygon2", "Porygon2"), (198, "murkrow", "Cornèbre"),
    (228, "houndour", "Malosse"), (229, "houndoom", "Démolosse"), (202, "wobbuffet", "Qulbutoké"),
    (230, "kingdra", "Hyporoi"), (186, "politoed", "Tarpaud"), (242, "blissey", "Leuphorie"),
    (169, "crobat", "Nostenfer"), (246, "larvitar", "Embrylex"), (247, "pupitar", "Ymphect"),
    (248, "tyranitar", "Tyranocif"), (227, "skarmory", "Airmure"), (241, "miltank", "Écrémeuh"),
    (243, "raikou", "Raikou"), (244, "entei", "Entei"), (245, "suicune", "Suicune"),
    (249, "lugia", "Lugia"), (250, "ho_oh", "Ho-Oh"), (251, "celebi", "Celebi"),
]

# Évolutions d'Or/Argent adaptées au jeu (jalon-joh0.md §2.8).
EVOLUTIONS = {
    "chikorita": [{"into": "bayleef", "method": "level", "level": 16}],
    "bayleef": [{"into": "meganium", "method": "level", "level": 32}],
    "cyndaquil": [{"into": "quilava", "method": "level", "level": 14}],
    "quilava": [{"into": "typhlosion", "method": "level", "level": 36}],
    "totodile": [{"into": "croconaw", "method": "level", "level": 18}],
    "croconaw": [{"into": "feraligatr", "method": "level", "level": 30}],
    "sentret": [{"into": "furret", "method": "level", "level": 15}],
    "hoothoot": [{"into": "noctowl", "method": "level", "level": 20}],
    "mareep": [{"into": "flaaffy", "method": "level", "level": 15}],
    "flaaffy": [{"into": "ampharos", "method": "level", "level": 30}],
    "marill": [{"into": "azumarill", "method": "level", "level": 18}],
    "togepi": [{"into": "togetic", "method": "bond"}],
    "teddiursa": [{"into": "ursaring", "method": "level", "level": 30}],
    "phanpy": [{"into": "donphan", "method": "level", "level": 25}],
    "houndour": [{"into": "houndoom", "method": "level", "level": 24}],
    "larvitar": [{"into": "pupitar", "method": "level", "level": 30}],
    "pupitar": [{"into": "tyranitar", "method": "level", "level": 55}],
}

GROWTH = {"slow": "slow", "medium": "medium_fast", "fast": "fast", "medium-slow": "medium_slow",
          "slow-then-very-fast": "erratic", "fast-then-very-slow": "fluctuating"}


def load(folder, kind, number, fetch):
    path = os.path.join(folder, kind, "%d.json" % number)
    if not os.path.exists(path) or os.path.getsize(path) < 100:
        if not fetch:
            raise SystemExit("fichier absent : " + path)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        url = "https://pokeapi.co/api/v2/%s/%d" % ("pokemon" if kind == "pokemon" else "pokemon-species", number)
        subprocess.run(["curl", "-s", "-m", "60", "-o", path, url], check=True)
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def learnset(pokemon):
    entries = []
    for move in pokemon["moves"]:
        for detail in move["version_group_details"]:
            if detail["version_group"]["name"] == "gold-silver" \
                    and detail["move_learn_method"]["name"] == "level-up":
                entries.append((max(detail["level_learned_at"], 1), move["move"]["name"].replace("-", "_")))
    entries.sort(key=lambda e: e[0])  # tri stable : l'ordre alphabétique de PokeAPI reste dans un même niveau
    unique = []
    for entry in entries:
        if entry not in unique:
            unique.append(entry)
    return unique


def fmt_list(items, indent, width=100):
    lines, current = [], ""
    for item in items:
        piece = item + ","
        if current and len(indent.expandtabs(4)) + len(current) + 1 + len(piece) > width:
            lines.append(current)
            current = piece
        else:
            current = (current + " " + piece) if current else piece
    if current:
        lines.append(current)
    lines[-1] = lines[-1].rstrip(",")
    return lines


def fmt_species(sid, name, dex, pokemon, species):
    types = [t["type"]["name"] for t in sorted(pokemon["types"], key=lambda t: t["slot"])]
    stats = {s["stat"]["name"]: s["base_stat"] for s in pokemon["stats"]}
    gender = species["gender_rate"]
    male = -1 if gender == -1 else round(1 - gender / 8, 3)
    male_text = "-1" if male == -1 else ("%g" % male if male not in (0, 1) else "%.1f" % male)
    out = ['\t"%s": {' % sid,
           '\t\t"dex": %d, "name": "%s", "types": [%s],' % (dex, name, ", ".join('"%s"' % t for t in types)),
           '\t\t"base_stats": { "hp": %d, "atk": %d, "def": %d, "spa": %d, "spd": %d, "spe": %d },' % (
               stats["hp"], stats["attack"], stats["defense"], stats["special-attack"],
               stats["special-defense"], stats["speed"]),
           '\t\t"male_ratio": %s, "growth_rate": "%s", "base_exp": %d, "catch_rate": %d,' % (
               male_text, GROWTH[species["growth_rate"]["name"]], pokemon["base_experience"],
               species["capture_rate"]),
           '\t\t"learnset": [']
    moves = learnset(pokemon)
    out += ["\t\t\t" + line for line in fmt_list(['[%d, "%s"]' % m for m in moves], "\t\t\t")]
    if sid in EVOLUTIONS:
        out.append("\t\t],")
        rules = []
        for rule in EVOLUTIONS[sid]:
            rules.append("{ " + ", ".join('"%s": %s' % (k, json.dumps(v, ensure_ascii=False))
                                         for k, v in rule.items()) + " }")
        out.append('\t\t"evolutions": [' + ", ".join(rules) + "]")
    else:
        out.append("\t\t]")
    out.append("\t}")
    return "\n".join(out), moves


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    fetch = "--fetch" in sys.argv
    if len(args) != 1:
        raise SystemExit(__doc__)
    folder = args[0]
    if len(SPECIES) != 51:
        raise SystemExit("la liste doit compter 51 espèces")
    blocks, all_moves = [], {}
    for dex, sid, name in sorted(SPECIES):
        pokemon = load(folder, "pokemon", dex, fetch)
        species = load(folder, "species", dex, fetch)
        assert pokemon["name"].replace("-", "_") == sid, (pokemon["name"], sid)
        block, moves = fmt_species(sid, name, dex, pokemon, species)
        blocks.append(block)
        for _level, move in moves:
            all_moves.setdefault(move, []).append(sid)
    target = os.path.join(ROOT, "data", "pokemon", "species", "johto.json")
    with open(target, "w", encoding="utf-8") as handle:
        handle.write("{\n" + ",\n".join(blocks) + "\n}\n")
    json.load(open(target, encoding="utf-8"))  # JSON valide
    print("%d espèces écrites ; %d attaques distinctes dans les learnsets." % (len(blocks), len(all_moves)))


if __name__ == "__main__":
    main()
