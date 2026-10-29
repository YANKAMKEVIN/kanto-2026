#!/usr/bin/env python3
"""Audit 32.0 : matrice d'obtention des 151 espèces (jalon 32, T1, `docs/tech/jalon-32.md`).

Lecture seule. L'outil lit les données de plusieurs branches git (ou d'un dossier) et dit, pour
chaque espèce 001–151, par quelles voies on l'obtient dans **une seule sauvegarde solo** :

- rencontres sauvages (`data/encounters/*.json`, `data/fishing/*.json`), en vérifiant que la
  carte existe (`game/world/maps/*.tscn`) sur la même branche ;
- starters (`data/pokemon/starters.json`, un seul choix) ;
- dons et rencontres fixes des scènes (`data/cutscenes/*.json` : étapes `gift_pokemon`,
  `wild_battle` ; `uncatchable` et `ghost` exclus) ;
- fossiles (`data/world/fossils.json` + étapes `give` de l'objet fossile) ;
- échanges PNJ (`data/trades/*.json`) ;
- évolutions (`data/pokemon/species/*.json` : niveau, pierre, échange).

Choix uniques (une seule récompense parmi plusieurs) : starters, fossile du Mont Sélénite,
Kicklee/Tygnon, et toute espèce à évolutions multiples obtenue en un seul exemplaire (Évoli).
Les manques renvoient aux arbitrages N-1 à N-16 validés par Kevin
(`docs/design/passes/j32-arbitrages-kevin.md`).

Usage :
    tools/audit_pokedex.py                       # branches par défaut (origin/main + jalons)
    tools/audit_pokedex.py --refs origin/main    # une seule branche
    tools/audit_pokedex.py --dir .               # copie de travail (sans git)
    tools/audit_pokedex.py --md docs/tech/jalon-32-matrice.md --csv build/audit_pokedex.csv

Tests : `python3 -m unittest tools/test_audit_pokedex.py`.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import subprocess
import sys
from dataclasses import dataclass, field

DEFAULT_REFS = [
    # Depuis le 2026-10-27, `main` contient toute l'aventure (J23 à J31) ; HEAD = `jalon-32`.
    "origin/main", "HEAD",
]

# Les 151 espèces de Kanto : identifiant du projet, nom français (repli si aucune donnée).
KANTO_151 = [
    ("bulbasaur", "Bulbizarre"), ("ivysaur", "Herbizarre"), ("venusaur", "Florizarre"),
    ("charmander", "Salamèche"), ("charmeleon", "Reptincel"), ("charizard", "Dracaufeu"),
    ("squirtle", "Carapuce"), ("wartortle", "Carabaffe"), ("blastoise", "Tortank"),
    ("caterpie", "Chenipan"), ("metapod", "Chrysacier"), ("butterfree", "Papilusion"),
    ("weedle", "Aspicot"), ("kakuna", "Coconfort"), ("beedrill", "Dardargnan"),
    ("pidgey", "Roucool"), ("pidgeotto", "Roucoups"), ("pidgeot", "Roucarnage"),
    ("rattata", "Rattata"), ("raticate", "Rattatac"), ("spearow", "Piafabec"),
    ("fearow", "Rapasdepic"), ("ekans", "Abo"), ("arbok", "Arbok"), ("pikachu", "Pikachu"),
    ("raichu", "Raichu"), ("sandshrew", "Sabelette"), ("sandslash", "Sablaireau"),
    ("nidoran_f", "Nidoran♀"), ("nidorina", "Nidorina"), ("nidoqueen", "Nidoqueen"),
    ("nidoran_m", "Nidoran♂"), ("nidorino", "Nidorino"), ("nidoking", "Nidoking"),
    ("clefairy", "Mélofée"), ("clefable", "Mélodelfe"), ("vulpix", "Goupix"),
    ("ninetales", "Feunard"), ("jigglypuff", "Rondoudou"), ("wigglytuff", "Grodoudou"),
    ("zubat", "Nosferapti"), ("golbat", "Nosferalto"), ("oddish", "Mystherbe"),
    ("gloom", "Ortide"), ("vileplume", "Rafflesia"), ("paras", "Paras"),
    ("parasect", "Parasect"), ("venonat", "Mimitoss"), ("venomoth", "Aéromite"),
    ("diglett", "Taupiqueur"), ("dugtrio", "Triopikeur"), ("meowth", "Miaouss"),
    ("persian", "Persian"), ("psyduck", "Psykokwak"), ("golduck", "Akwakwak"),
    ("mankey", "Férosinge"), ("primeape", "Colossinge"), ("growlithe", "Caninos"),
    ("arcanine", "Arcanin"), ("poliwag", "Ptitard"), ("poliwhirl", "Têtarte"),
    ("poliwrath", "Tartard"), ("abra", "Abra"), ("kadabra", "Kadabra"),
    ("alakazam", "Alakazam"), ("machop", "Machoc"), ("machoke", "Machopeur"),
    ("machamp", "Mackogneur"), ("bellsprout", "Chétiflor"), ("weepinbell", "Boustiflor"),
    ("victreebel", "Empiflor"), ("tentacool", "Tentacool"), ("tentacruel", "Tentacruel"),
    ("geodude", "Racaillou"), ("graveler", "Gravalanch"), ("golem", "Grolem"),
    ("ponyta", "Ponyta"), ("rapidash", "Galopa"), ("slowpoke", "Ramoloss"),
    ("slowbro", "Flagadoss"), ("magnemite", "Magnéti"), ("magneton", "Magnéton"),
    ("farfetchd", "Canarticho"), ("doduo", "Doduo"), ("dodrio", "Dodrio"), ("seel", "Otaria"),
    ("dewgong", "Lamantine"), ("grimer", "Tadmorv"), ("muk", "Grotadmorv"),
    ("shellder", "Kokiyas"), ("cloyster", "Crustabri"), ("gastly", "Fantominus"),
    ("haunter", "Spectrum"), ("gengar", "Ectoplasma"), ("onix", "Onix"),
    ("drowzee", "Soporifik"), ("hypno", "Hypnomade"), ("krabby", "Krabby"),
    ("kingler", "Krabboss"), ("voltorb", "Voltorbe"), ("electrode", "Électrode"),
    ("exeggcute", "Noeunoeuf"), ("exeggutor", "Noadkoko"), ("cubone", "Osselait"),
    ("marowak", "Ossatueur"), ("hitmonlee", "Kicklee"), ("hitmonchan", "Tygnon"),
    ("lickitung", "Excelangue"), ("koffing", "Smogo"), ("weezing", "Smogogo"),
    ("rhyhorn", "Rhinocorne"), ("rhydon", "Rhinoféros"), ("chansey", "Leveinard"),
    ("tangela", "Saquedeneu"), ("kangaskhan", "Kangourex"), ("horsea", "Hypotrempe"),
    ("seadra", "Hypocéan"), ("goldeen", "Poissirène"), ("seaking", "Poissoroy"),
    ("staryu", "Stari"), ("starmie", "Staross"), ("mr_mime", "M. Mime"),
    ("scyther", "Insécateur"), ("jynx", "Lippoutou"), ("electabuzz", "Élektek"),
    ("magmar", "Magmar"), ("pinsir", "Scarabrute"), ("tauros", "Tauros"),
    ("magikarp", "Magicarpe"), ("gyarados", "Léviator"), ("lapras", "Lokhlass"),
    ("ditto", "Métamorph"), ("eevee", "Évoli"), ("vaporeon", "Aquali"),
    ("jolteon", "Voltali"), ("flareon", "Pyroli"), ("porygon", "Porygon"),
    ("omanyte", "Amonita"), ("omastar", "Amonistar"), ("kabuto", "Kabuto"),
    ("kabutops", "Kabutops"), ("aerodactyl", "Ptéra"), ("snorlax", "Ronflex"),
    ("articuno", "Artikodin"), ("zapdos", "Électhor"), ("moltres", "Sulfura"),
    ("dratini", "Minidraco"), ("dragonair", "Draco"), ("dragonite", "Dracolosse"),
    ("mewtwo", "Mewtwo"), ("mew", "Mew"),
]
assert len(KANTO_151) == 151

# Évolutions de Rouge/Bleu (de, vers, méthode) : référence pour signaler une évolution absente
# des données. La résolution n'utilise **que** les données du projet.
RB_EVOLUTIONS = [tuple(e.split(":")) for e in """
bulbasaur:ivysaur:level ivysaur:venusaur:level charmander:charmeleon:level
charmeleon:charizard:level squirtle:wartortle:level wartortle:blastoise:level
caterpie:metapod:level metapod:butterfree:level weedle:kakuna:level kakuna:beedrill:level
pidgey:pidgeotto:level pidgeotto:pidgeot:level rattata:raticate:level spearow:fearow:level
ekans:arbok:level pikachu:raichu:thunder_stone sandshrew:sandslash:level
nidoran_f:nidorina:level nidorina:nidoqueen:moon_stone nidoran_m:nidorino:level
nidorino:nidoking:moon_stone clefairy:clefable:moon_stone vulpix:ninetales:fire_stone
jigglypuff:wigglytuff:moon_stone zubat:golbat:level oddish:gloom:level
gloom:vileplume:leaf_stone paras:parasect:level venonat:venomoth:level
diglett:dugtrio:level meowth:persian:level psyduck:golduck:level mankey:primeape:level
growlithe:arcanine:fire_stone poliwag:poliwhirl:level poliwhirl:poliwrath:water_stone
abra:kadabra:level kadabra:alakazam:trade machop:machoke:level machoke:machamp:trade
bellsprout:weepinbell:level weepinbell:victreebel:leaf_stone tentacool:tentacruel:level
geodude:graveler:level graveler:golem:trade ponyta:rapidash:level slowpoke:slowbro:level
magnemite:magneton:level doduo:dodrio:level seel:dewgong:level grimer:muk:level
shellder:cloyster:water_stone gastly:haunter:level haunter:gengar:trade drowzee:hypno:level
krabby:kingler:level voltorb:electrode:level exeggcute:exeggutor:leaf_stone
cubone:marowak:level koffing:weezing:level rhyhorn:rhydon:level horsea:seadra:level
goldeen:seaking:level staryu:starmie:water_stone magikarp:gyarados:level
eevee:vaporeon:water_stone eevee:jolteon:thunder_stone eevee:flareon:fire_stone
omanyte:omastar:level kabuto:kabutops:level dratini:dragonair:level
dragonair:dragonite:level
""".split()]

# Seconde chance d'après la Ligue (J32, N-7 et N-8) : un don de ces scènes lève le choix unique
# (le second fossile du chercheur, l'autre Poké Ball du Dojo).
SECOND_CHANCE_PREFIX = "j32_"

# Choix uniques connus (Rouge/Bleu et décisions du projet) : une seule espèce par sauvegarde.
# Les starters viennent de `starters.json` ; les évolutions multiples (Évoli) sont détectées.
FIXED_CHOICES = {
    "fossile_mt_moon": {"label": "fossile du Mont Sélénite (dossier 15 V-6)",
                        "fossil_items": ["dome_fossil", "helix_fossil"], "rule": "N-7"},
    "dojo": {"label": "Dojo de Safrania (J27)", "species": ["hitmonlee", "hitmonchan"],
             "rule": "N-8"},
}

# Voies prévues par les arbitrages validés (N-1 à N-16) pour chaque manque connu.
PLANNED = {
    "mew": ("N-1 à N-5", "rencontre secrète au camion du quai de Carmin, 150 capturées, N30"),
    "zapdos": ("N-11", "Centrale, lot 32G (Électhor N50)"),
    "magnemite": ("N-11", "Centrale, lot 32G (Magnéti, sauvage RB à la Centrale seulement)"),
    "electabuzz": ("N-11", "Centrale, lot 32G (union Rouge + Bleu)"),
    "dratini": ("N-12", "Super Canne RB au Parc Safari"),
    "porygon": ("N-13", "employé de Sylphe SARL après Giovanni"),
    "mr_mime": ("N-14", "échange PNJ Abra → M. Mime (Route 2)"),
    "jynx": ("N-14", "échange PNJ Têtarte → Lippoutou (Azuria)"),
    "farfetchd": ("N-14", "échange PNJ Piafabec → Canarticho (Carmin)"),
    "lickitung": ("N-14", "échange PNJ Flagadoss → Excelangue (Route 18)"),
}
CHOICE_RULES = {
    "starters": ("N-6", "Chen confie les deux autres après la Ligue"),
    "fossile_mt_moon": ("N-7", "le chercheur du Mont Sélénite confie l'autre fossile à Cramois'Île"),
    "dojo": ("N-8", "le Maître du Dojo offre l'autre Poké Ball après la Ligue"),
    "evolutions:eevee": ("N-9", "deux Évoli de plus sur le toit de Céladopole après la Ligue"),
}
TRADE_RULE = ("N-15 / T4, T5", "terminal d'échange local des Centres (écran fait, J32 T5)")

# Rencontres fixes dont la carte n'existe pas encore : la voie ne compte que si la carte existe.
STATIC_MAPS = {"zapdos": "power_plant"}

STATUS_OK = "obtenable"
STATUS_CHOICE = "choix unique"
STATUS_TRADE = "échange local"
STATUS_MISSING = "manque"
STATUS_ORDER = [STATUS_OK, STATUS_CHOICE, STATUS_TRADE, STATUS_MISSING]


# ---------------------------------------------------------------------------------------------
# Lecture des données (git ou dossier)

class DirSource:
    """Lit un dossier (copie de travail ou fixture de test)."""

    def __init__(self, root: str, label: str = "dossier") -> None:
        self.root = root
        self.label = label

    def list(self, directory: str) -> list[str]:
        base = os.path.join(self.root, directory)
        out = []
        for dirpath, _dirs, files in os.walk(base):
            for name in files:
                rel = os.path.relpath(os.path.join(dirpath, name), self.root)
                out.append(rel.replace(os.sep, "/"))
        return sorted(out)

    def read(self, path: str) -> str | None:
        full = os.path.join(self.root, path)
        if not os.path.isfile(full):
            return None
        with open(full, encoding="utf-8") as handle:
            return handle.read()


class GitSource:
    """Lit une révision git sans rien extraire sur le disque."""

    def __init__(self, repo: str, ref: str) -> None:
        self.repo = repo
        self.ref = ref
        self.label = short_ref(ref)

    def _git(self, *args: str) -> str:
        return subprocess.run(["git", "-C", self.repo, *args], check=True,
                              capture_output=True, text=True).stdout

    def list(self, directory: str) -> list[str]:
        try:
            out = self._git("ls-tree", "-r", "--name-only", self.ref, "--", directory)
        except subprocess.CalledProcessError:
            return []
        return sorted(line for line in out.splitlines() if line)

    def read(self, path: str) -> str | None:
        try:
            return self._git("show", f"{self.ref}:{path}")
        except subprocess.CalledProcessError:
            return None


def short_ref(ref: str) -> str:
    name = ref.split("/")[-1]
    if name.startswith("jalon-"):
        return "J" + name[len("jalon-"):]
    return name


def load_json(source, path: str):
    text = source.read(path)
    if text is None:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError as err:
        print(f"[{source.label}] JSON illisible : {path} ({err})", file=sys.stderr)
        return None


def json_files(source, directory: str) -> list[str]:
    return [p for p in source.list(directory) if p.endswith(".json")]


def walk_dicts(node):
    """Tous les dictionnaires d'un arbre JSON (étapes de scène imbriquées)."""
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from walk_dicts(value)
    elif isinstance(node, list):
        for value in node:
            yield from walk_dicts(value)


# ---------------------------------------------------------------------------------------------
# Modèle

@dataclass
class Way:
    kind: str          # sauvage, starter, don, fixe, fossile, échange PNJ
    species: str
    detail: str        # texte court lisible
    key: str           # identité stable pour fusionner les branches
    choice: str = ""   # groupe de choix unique ("" = libre)
    wants: str = ""    # échange PNJ : espèce demandée
    one_shot: bool = True
    valid: bool = True
    note: str = ""
    refs: list[str] = field(default_factory=list)


@dataclass
class RefData:
    label: str
    species: dict = field(default_factory=dict)        # id → données espèce
    ways: list = field(default_factory=list)
    item_gives: dict = field(default_factory=dict)     # objet → nombre de dons uniques
    shop_items: set = field(default_factory=set)
    second_items: set = field(default_factory=set)     # objets redonnés après la Ligue (J32)
    starter_ids: list = field(default_factory=list)


def map_names(source) -> set[str]:
    names = set()
    for path in source.list("game/world/maps"):
        if path.endswith(".tscn"):
            names.add(os.path.basename(path)[:-len(".tscn")])
    return names


def collect(source) -> RefData:
    data = RefData(label=source.label)
    for path in json_files(source, "data/pokemon/species"):
        content = load_json(source, path)
        if isinstance(content, dict):
            for sid, entry in content.items():
                if isinstance(entry, dict) and "dex" in entry:
                    data.species.setdefault(sid, entry)

    maps = map_names(source)

    # Rencontres sauvages et pêche.
    for directory in ("data/encounters", "data/fishing"):
        for path in json_files(source, directory):
            content = load_json(source, path)
            if not isinstance(content, dict):
                continue
            for table_id, table in content.items():
                if not isinstance(table, dict) or "slots" not in table:
                    continue
                table_maps = table.get("maps", [])
                exists = "*" in table_maps or not maps or any(m in maps for m in table_maps)
                terrain = table.get("rod") or table.get("terrain", "?")
                where = ", ".join(table_maps[:3]) + ("…" if len(table_maps) > 3 else "")
                for slot in table.get("slots", []):
                    sid = slot.get("species")
                    if not sid:
                        continue
                    data.ways.append(Way(
                        kind="sauvage", species=sid, detail=f"{where} ({terrain})",
                        key=f"wild:{table_id}:{sid}", one_shot=False, valid=exists,
                        note="" if exists else "carte absente"))

    # Starters.
    starters = load_json(source, "data/pokemon/starters.json")
    if isinstance(starters, dict):
        for choice in starters.get("choices", []):
            sid = choice.get("species")
            if sid:
                data.starter_ids.append(sid)
                data.ways.append(Way(kind="starter", species=sid, detail="labo de Chen",
                                     key=f"starter:{sid}", choice="starters"))

    # Fossiles : objet → espèce, et dons de l'objet.
    fossils = load_json(source, "data/world/fossils.json") or {}
    fossil_species = {item: entry.get("species") for item, entry
                      in (fossils.get("fossils") or {}).items() if isinstance(entry, dict)}

    for path in json_files(source, "data/cutscenes"):
        content = load_json(source, path)
        name = os.path.basename(path)[:-len(".json")]
        for step in walk_dicts(content):
            if "give" in step and isinstance(step["give"], str):
                item = step["give"]
                data.item_gives[item] = data.item_gives.get(item, 0) + 1
                if name.startswith(SECOND_CHANCE_PREFIX):
                    data.second_items.add(item)
            if isinstance(step.get("gift_pokemon"), str):
                sid = step["gift_pokemon"]
                if sid in fossil_species.values():
                    continue  # rendu par le labo : compté comme voie « fossile »
                data.ways.append(Way(kind="don", species=sid, detail=f"{name} (N{step.get('level', '?')})",
                                     key=f"gift:{step.get('flag') or name}:{sid}"
                                     + (f":{name}" if name.startswith(SECOND_CHANCE_PREFIX) else "")))
            if isinstance(step.get("wild_battle"), str):
                if step.get("uncatchable") or step.get("ghost"):
                    continue
                sid = step["wild_battle"]
                needed = STATIC_MAPS.get(sid)
                exists = needed is None or not maps or needed in maps
                data.ways.append(Way(kind="fixe", species=sid,
                                     detail=f"{name} (N{step.get('level', '?')})",
                                     key=f"static:{name}:{sid}", valid=exists,
                                     note="" if exists else f"carte {needed} absente"))

    for path in json_files(source, "data/shops"):
        for node in walk_dicts(load_json(source, path)):
            for value in node.values():
                if isinstance(value, str):
                    data.shop_items.add(value)
                elif isinstance(value, list):
                    data.shop_items.update(v for v in value if isinstance(v, str))

    for item, sid in fossil_species.items():
        if not sid:
            continue
        choice = ""
        for group_id, group in FIXED_CHOICES.items():
            if item in group.get("fossil_items", []) and item not in data.second_items:
                choice = group_id
        given = data.item_gives.get(item, 0)
        data.ways.append(Way(kind="fossile", species=sid, detail=f"{item} → labo de Cramois'Île",
                             key=f"fossil:{item}", choice=choice, valid=given > 0,
                             note="" if given else "objet fossile jamais donné"))

    for path in json_files(source, "data/trades"):
        content = load_json(source, path) or {}
        for trade_id, trade in (content.get("trades") or {}).items():
            gives, wants = trade.get("gives"), trade.get("wants")
            if gives:
                data.ways.append(Way(kind="échange PNJ", species=gives,
                                     detail=f"{trade_id} (contre {wants})",
                                     key=f"trade:{trade_id}", wants=wants or ""))

    for way in data.ways:
        for group_id, group in FIXED_CHOICES.items():
            if way.species in group.get("species", []) and way.kind == "don" \
                    and not way.detail.startswith(SECOND_CHANCE_PREFIX):
                way.choice = group_id
    for way in data.ways:
        way.refs = [source.label]
    return data


def merge(refs: list[RefData]) -> tuple[dict, list[Way], dict, set]:
    species: dict = {}
    ways: dict[str, Way] = {}
    item_gives: dict[str, int] = {}
    shop_items: set = set()
    for ref in refs:
        for sid, entry in ref.species.items():
            if sid not in species:
                species[sid] = {**entry, "evolutions": list(entry.get("evolutions") or [])}
                continue
            known = species[sid]["evolutions"]
            for evo in entry.get("evolutions") or []:
                if all(k.get("into") != evo.get("into") for k in known):
                    known.append(evo)
        for way in ref.ways:
            if way.key in ways:
                known = ways[way.key]
                if ref.label not in known.refs:
                    known.refs.append(ref.label)
                if way.valid and not known.valid:
                    known.valid, known.note = True, ""
                # J32 : une branche qui lève le choix unique (seconde chance) l'emporte.
                if not way.choice and known.choice:
                    known.choice = ""
            else:
                ways[way.key] = Way(**{**way.__dict__, "refs": list(way.refs)})
        for item, count in ref.item_gives.items():
            item_gives[item] = max(item_gives.get(item, 0), count)
        shop_items |= ref.shop_items
    return species, list(ways.values()), item_gives, shop_items


# ---------------------------------------------------------------------------------------------
# Résolution

@dataclass
class Row:
    dex: int
    sid: str
    name: str
    types: str
    has_data: bool
    ways: list = field(default_factory=list)     # textes « kind : détail [refs] »
    refs: set = field(default_factory=set)
    status: str = STATUS_MISSING
    choice: str = ""
    evolves_from: str = ""
    missing_evo: list = field(default_factory=list)   # évolutions RB absentes des données
    brought_by: str = ""   # branche qui apporte la voie (« main » si déjà sur main)
    gap: str = ""


def resolve(species: dict, ways: list[Way], item_gives: dict, shop_items: set) -> list[Row]:
    rows: dict[str, Row] = {}
    for index, (sid, fallback) in enumerate(KANTO_151, start=1):
        entry = species.get(sid, {})
        rows[sid] = Row(dex=index, sid=sid, name=entry.get("name", fallback),
                        types="/".join(entry.get("types", [])), has_data=bool(entry))

    # Pré-évolutions (une espèce peut évoluer vers plusieurs : Évoli).
    pre: dict[str, list[tuple[str, dict]]] = {}
    for sid, entry in species.items():
        for evo in entry.get("evolutions", []) or []:
            pre.setdefault(evo.get("into"), []).append((sid, evo))

    by_species: dict[str, list[Way]] = {}
    for way in ways:
        by_species.setdefault(way.species, []).append(way)

    status: dict[str, tuple[str, str]] = {}   # sid → (statut, groupe de choix)
    rank = {s: i for i, s in enumerate(STATUS_ORDER)}

    def better(a, b):
        return a if rank[a[0]] <= rank[b[0]] else b

    # Voies directes.
    for sid, row in rows.items():
        best = (STATUS_MISSING, "")
        for way in by_species.get(sid, []):
            row.ways.append(f"{way.kind} : {way.detail} [{', '.join(way.refs)}]"
                            + (f" ({way.note})" if way.note else ""))
            if not way.valid:
                continue
            row.refs.update(way.refs)
            if way.kind == "échange PNJ":
                continue  # résolu plus bas (dépend de l'espèce demandée)
            best = better(best, (STATUS_CHOICE, way.choice) if way.choice else (STATUS_OK, ""))
        status[sid] = best

    # Évolutions multiples d'une espèce reçue en peu d'exemplaires (Évoli) : choix unique.
    branch_choice: dict[str, str] = {}
    for sid, entry in species.items():
        targets = [e.get("into") for e in entry.get("evolutions", []) or []]
        if len(targets) < 2:
            continue
        sources = [w for w in by_species.get(sid, []) if w.valid]
        if not sources or any(not w.one_shot for w in sources):
            continue
        if len(sources) < len(targets):
            for target in targets:
                branch_choice[target] = f"evolutions:{sid}"

    # Propagation (évolutions, échanges PNJ) jusqu'au point fixe.
    changed = True
    while changed:
        changed = False
        for sid, row in rows.items():
            current = status.get(sid, (STATUS_MISSING, ""))
            candidate = current
            for way in by_species.get(sid, []):
                if way.kind == "échange PNJ" and way.valid:
                    wanted = status.get(way.wants, (STATUS_MISSING, ""))
                    if wanted[0] != STATUS_MISSING:
                        candidate = better(candidate, wanted)
            for parent, evo in pre.get(sid, []):
                parent_status = status.get(parent, (STATUS_MISSING, ""))
                if parent_status[0] == STATUS_MISSING:
                    continue
                method = evo.get("method")
                if method == "trade":
                    proposal = (STATUS_TRADE, parent_status[1])
                elif sid in branch_choice:
                    proposal = (STATUS_CHOICE, branch_choice[sid])
                else:
                    proposal = parent_status
                candidate = better(candidate, proposal)
            if candidate != current:
                status[sid] = candidate
                changed = True

    for sid, row in rows.items():
        row.status, row.choice = status.get(sid, (STATUS_MISSING, ""))
        for parent, evo in pre.get(sid, []):
            method = evo.get("method")
            if method == "level":
                how = f"niveau {evo.get('level')}"
            elif method == "item":
                item = evo.get("item")
                found = item in shop_items or item_gives.get(item, 0) > 0
                how = f"{item}" + ("" if found else " (introuvable)")
            else:
                how = method or "?"
            row.evolves_from = f"{rows[parent].name if parent in rows else parent} ({how})"
        declared = {parent for parent, _ in pre.get(sid, [])}
        row.missing_evo = [f"{a} → {b} ({m})" for a, b, m in RB_EVOLUTIONS
                           if b == sid and a not in declared]
    for sid, row in rows.items():
        row.gap = gap_for(row, rows, pre)
    return [rows[sid] for sid, _ in KANTO_151]


def gap_for(row: Row, rows: dict, pre: dict | None = None) -> str:
    if row.status == STATUS_OK:
        return ""
    if row.status == STATUS_TRADE:
        rule, text = TRADE_RULE
        return f"{rule} : {text}"
    if row.status == STATUS_CHOICE:
        rule, text = CHOICE_RULES.get(row.choice, ("?", "choix unique sans règle"))
        return f"{rule} : {text}"
    if row.sid in PLANNED:
        rule, text = PLANNED[row.sid]
        return f"{rule} : {text}"
    # Hérite de la règle d'un ancêtre (Draco, Dracolosse ← Minidraco), par les données ou RB.
    parents = {}
    for child, edges in (pre or {}).items():
        parents.setdefault(child, set()).update(p for p, _ in edges)
    for a, b, _m in RB_EVOLUTIONS:
        parents.setdefault(b, set()).add(a)
    seen, todo = set(), list(parents.get(row.sid, ()))
    while todo:
        parent = todo.pop()
        if parent in seen:
            continue
        seen.add(parent)
        if parent in PLANNED:
            rule, text = PLANNED[parent]
            return f"{rule} (par évolution de {rows[parent].name}) : {text}"
        todo += list(parents.get(parent, ()))
    if row.missing_evo:
        text = "données : évolution absente de `species/` (" + ", ".join(row.missing_evo) + ")"
        if any(e.endswith("(trade)") for e in row.missing_evo):
            text += f", puis {TRADE_RULE[0]}"
        return text
    return "aucune voie ni règle : à trancher"


# ---------------------------------------------------------------------------------------------
# Sorties

def summary(rows: list[Row]) -> dict:
    counts = {s: 0 for s in STATUS_ORDER}
    for row in rows:
        counts[row.status] += 1
    groups: dict[str, list[str]] = {}
    for row in rows:
        if row.status == STATUS_CHOICE:
            groups.setdefault(row.choice, []).append(row.name)
    return {"counts": counts, "groups": groups,
            "no_data": [r.name for r in rows if not r.has_data]}


def write_csv(rows: list[Row], path: str) -> None:
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["numero", "id", "nom", "types", "evolution_de", "voies", "branches",
                         "apportee_par", "statut", "choix", "manque", "donnees"])
        for r in rows:
            writer.writerow([f"{r.dex:03d}", r.sid, r.name, r.types, r.evolves_from,
                             " | ".join(r.ways), " ".join(sorted(r.refs)), r.brought_by, r.status, r.choice,
                             r.gap, "oui" if r.has_data else "non"])


def write_md(rows: list[Row], path: str, ref_labels: list[str], item_gives: dict,
             species: dict, shop_items: set) -> None:
    info = summary(rows)
    c = info["counts"]
    lines = [
        "# Jalon 32 — matrice d'obtention des 151 espèces (audit 32.0)",
        "",
        "> **Généré par `tools/audit_pokedex.py` — ne pas éditer à la main.** Lecture seule des "
        f"données des branches : {', '.join(f'`{r}`' for r in ref_labels)}. "
        "Règles : arbitrages N-1 à N-16 validés par Kevin "
        "(`docs/design/passes/j32-arbitrages-kevin.md`). Une voie compte si elle existe sur **au "
        "moins une** branche ; tant que ces branches ne sont pas fusionnées dans `main`, la matrice "
        "décrit le jeu « une fois tout fusionné ».",
        "",
        "## Résumé",
        "",
        f"- **{c[STATUS_OK]} / 151** obtenables dans une seule sauvegarde solo, sans choix unique "
        "ni échange local.",
        f"- **{c[STATUS_CHOICE]}** seulement par un choix unique (une seule par sauvegarde) ; "
        f"**{c[STATUS_TRADE]}** seulement par évolution par échange (terminal local des Centres, T4 et T5) ; "
        f"**{c[STATUS_MISSING]}** sans aucune voie.",
        f"- Espèces sans données sur aucune branche : {', '.join(info['no_data']) or 'aucune'}.",
        "",
        "### Choix uniques (une espèce par groupe et par sauvegarde)",
        "",
    ]
    for group, names in info["groups"].items():
        rule, text = CHOICE_RULES.get(group, ("?", ""))
        lines.append(f"- `{group}` : {', '.join(names)} → **{rule}** ({text}).")
    lines += ["", "### Par branche (statut atteint grâce à cette branche)", ""]
    by_ref: dict[str, list[str]] = {}
    for r in rows:
        if r.brought_by:
            by_ref.setdefault(r.brought_by, []).append(r.name)
    for label, names in by_ref.items():
        listed = f" : {', '.join(names)}" if len(names) <= 40 else ""
        lines.append(f"- **{label}** ({len(names)}){listed}")
    lines += ["", "### Sans voie, ou seulement par le terminal d'échange local", ""]
    for r in rows:
        if r.status in (STATUS_MISSING, STATUS_TRADE):
            lines.append(f"- {r.dex:03d} {r.name} ({r.status}) → {r.gap}.")
    missing_evo = [e for r in rows for e in r.missing_evo]
    lines += ["", "### Évolutions de Rouge/Bleu absentes des données", ""]
    lines += [f"- {e}" for e in missing_evo] or ["- aucune"]
    lines += ["", "### Pierres d'évolution", "",
              "Boutiques et dons uniques des scènes (union des branches, maximum par branche), "
              "face au besoin du Pokédex (une pierre par évolution) :", ""]
    need: dict[str, int] = {}
    for entry in species.values():
        for evo in entry.get("evolutions", []) or []:
            if evo.get("method") == "item":
                need[evo["item"]] = need.get(evo["item"], 0) + 1
    for item in sorted(need):
        shop = "en boutique" if item in shop_items else "**absente des boutiques**"
        lines.append(f"- `{item}` : {shop}, {item_gives.get(item, 0)} don(s) unique(s) ; "
                     f"{need[item]} évolution(s) au Pokédex.")
    lines += ["", "## Matrice", "",
              "| N° | Espèce | Types | Évolution de | Voies (branches) | Apportée par | Statut | Manque → règle |",
              "|---|---|---|---|---|---|---|---|"]
    for r in rows:
        ways = "<br>".join(r.ways) if r.ways else "—"
        evo = r.evolves_from or "—"
        if r.missing_evo:
            evo += " ; absente des données : " + ", ".join(r.missing_evo)
        lines.append(f"| {r.dex:03d} | {r.name} (`{r.sid}`) | {r.types or '—'} | "
                     f"{evo} | {ways} | {r.brought_by or '—'} | {r.status} | {r.gap or '—'} |")
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def attribute(rows: list[Row], refs: list[RefData]) -> None:
    """Quelle branche apporte la meilleure voie : la première seule, ou la première plus une."""
    if not refs:
        return
    rank = {s: i for i, s in enumerate(STATUS_ORDER)}
    base = {r.sid: r.status for r in resolve(*merge(refs[:1]))}
    extra = {ref.label: {r.sid: r.status for r in resolve(*merge([refs[0], ref]))}
             for ref in refs[1:]}
    for row in rows:
        if row.status == STATUS_MISSING:
            continue
        if rank[base[row.sid]] <= rank[row.status]:
            row.brought_by = refs[0].label
            continue
        bringers = [label for label, st in extra.items() if rank[st[row.sid]] <= rank[row.status]]
        row.brought_by = ", ".join(bringers) if bringers else "union"


def run(sources, md: str | None, csv_path: str | None, quiet: bool = False) -> list[Row]:
    refs = [collect(s) for s in sources]
    species, ways, item_gives, shop_items = merge(refs)
    rows = resolve(species, ways, item_gives, shop_items)
    attribute(rows, refs)
    if csv_path:
        write_csv(rows, csv_path)
    if md:
        write_md(rows, md, [getattr(s, "ref", s.label) for s in sources], item_gives, species,
                 shop_items)
    if not quiet:
        info = summary(rows)
        print(" · ".join(f"{k} : {v}" for k, v in info["counts"].items()))
    return rows


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--repo", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    parser.add_argument("--refs", default=",".join(DEFAULT_REFS),
                        help="révisions git, séparées par des virgules")
    parser.add_argument("--dir", help="lire un dossier au lieu de git")
    parser.add_argument("--md", help="sortie Markdown (ex. docs/tech/jalon-32-matrice.md)")
    parser.add_argument("--csv", default="build/audit_pokedex.csv")
    args = parser.parse_args(argv)
    if args.dir:
        sources = [DirSource(args.dir)]
    else:
        sources = [GitSource(args.repo, ref.strip()) for ref in args.refs.split(",") if ref.strip()]
    run(sources, args.md, args.csv)
    return 0


if __name__ == "__main__":
    sys.exit(main())
