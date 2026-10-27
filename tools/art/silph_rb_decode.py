#!/usr/bin/env python3
"""Décodeur de la Sylphe SARL et de Safrania de Rouge/Bleu (jalon 26, T2) : géométrie de référence
des grilles `tools/plans/sylphe_*.txt` et graphe des salles.

**Lit un désassemblage `pokered` local passé en argument** (jamais embarqué dans le dépôt, données
non fiables : ce script ne fait que LIRE des fichiers, il n'exécute rien de ce qu'ils contiennent).
Le code ne dépend que de la bibliothèque standard ; à lancer avec `python3 -I`.

Fichiers lus : `maps/SilphCo{1..11}F.blk`, `maps/SilphCoElevator.blk`, `gfx/blocksets/facility.bst`
et `lobby.bst`, `data/tilesets/collision_tile_ids.asm` (`Facility_Coll`, `Lobby_Coll`,
`Overworld_Coll`), `data/maps/objects/SilphCo*.asm` (warps, objets, Dresseurs),
`scripts/SilphCo*F.asm` (portes à carte : blocs fermés `ReplaceTileBlock` et coordonnées
`dbmapcoord` ; en-têtes de Dresseurs `def_trainers` / `trainer … , <vue>` ; cases de déclenchement
du rival au 7F et de Giovanni au 11F), `data/events/hidden_events.asm` (objets cachés), et pour
Safrania `maps/SaffronCity.blk`, `gfx/blocksets/overworld.bst`, `data/maps/objects/SaffronCity.asm`.

Comment RB range une carte : des blocs de 2 × 2 « cases » de 16 px ; la collision d'une case est
celle de la **tuile en bas à gauche** de son carré de 2 × 2 tuiles (blocset : 16 octets par bloc,
4 par rangée). Une case est praticable si cette tuile est dans la liste `<Tileset>_Coll`.
**Portes à carte** (RB) : le `.blk` contient la porte OUVERTE ; à l'entrée de la carte, le script
remplace le bloc (coordonnées en blocs) par un bloc fermé (`$54` horizontal, `$5f` vertical, `$20`
au 11F) tant que l'événement `EVENT_SILPH_CO_<n>_UNLOCKED_DOOR<k>` n'est pas posé. Les cases de
la porte = cases praticables ouvertes et bloquées fermées (toujours 2 cases).

Sorties :
  python3 -I tools/art/silph_rb_decode.py <pokered>              les 11 étages et la cabine (RB brut)
  python3 -I tools/art/silph_rb_decode.py <pokered> --brouillon   les mêmes dans les caractères des
                                                                  grilles du projet, avec un brouillon
                                                                  de section POSITIONS (noms finals)
  python3 -I tools/art/silph_rb_decode.py <pokered> --ecarts      écarts case par case entre les
                                                                  grilles `sylphe_*.txt` et RB, et
                                                                  positions RB absentes des grilles
  python3 -I tools/art/silph_rb_decode.py <pokered> --graphe      graphe des salles RB (escaliers,
                                                                  téléporteurs, portes, ascenseur)
  python3 -I tools/art/silph_rb_decode.py <pokered> --safrania    Safrania RB brut (40 × 36) et liste
                                                                  des portes, panneaux, PNJ

Légende « RB brut » des étages : # mur · M mobilier (bloqué) · . sol · T dalle de téléportation
($20) · U / D escalier qui monte / descend · L porte de l'ascenseur · E sortie vers Safrania ·
K case de porte à carte (fermée) ; objets : R sbire Rocket · s Scientifique · J Jongleur · B rival ·
G Giovanni · e employé, hôtesse, président, infirmière · o objet au sol · c objet caché · = classeur.
Caractères du projet (brouillon) : les mêmes, sans les objets (qui vont dans POSITIONS).
"""
from __future__ import annotations

import re
import sys
from collections import defaultdict, deque
from pathlib import Path

Case = tuple[int, int]

# Étages : (fichier, largeur en blocs, hauteur en blocs).
ETAGES = {n: (f"SilphCo{n}F", w, h) for n, w, h in [
	(1, 15, 9), (2, 15, 9), (3, 15, 9), (4, 15, 9), (5, 15, 9), (6, 13, 9), (7, 13, 9),
	(8, 13, 9), (9, 13, 9), (10, 8, 9), (11, 9, 9)]}
CABINE = ("SilphCoElevator", 2, 2)
CARTE = {n: f"silph_co_{n}f" for n in ETAGES}
CARTE_CABINE = "silph_co_elevator"
FICHIER_GRILLE = {n: f"sylphe_{n}f.txt" for n in ETAGES}
FICHIER_CABINE = "sylphe_ascenseur.txt"
NOM_RB = {f"SILPH_CO_{n}F": n for n in ETAGES}
# Jeux de tuiles : (blocset, liste de collision, tuile de la dalle de téléportation, tuiles bloquées
# dessinées comme murs — le reste des tuiles bloquées est du mobilier « M »). Le 11F est en
# tileset INTERIOR (salle du conseil), les autres étages en FACILITY.
TILESETS = {
	"FACILITY": ("facility", "Facility", 0x20, {0x0d, 0x2b, 0x3a, 0x3b, 0x4c, 0x59, 0x19, 0x12, 0x14}),
	"INTERIOR": ("interior", "Interior", 0x55, {0x59, 0x10, 0x5b, 0x58, 0x2f, 0x57, 0x2d, 0x44}),
}
CLASSES = {"OPP_ROCKET": ("R", "Rocket"), "OPP_SCIENTIST": ("s", "Scientifique"),
	"OPP_JUGGLER": ("J", "Jongleur"), "OPP_GIOVANNI": ("G", "Giovanni")}
DIRECTIONS = {"UP": "up", "DOWN": "down", "LEFT": "left", "RIGHT": "right", "NONE": "down",
	"ANY_DIR": "down", "LEFT_RIGHT": "down", "UP_DOWN": "down"}
VOISINS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
# Objets RB → identifiants du projet ; (id, repli si l'objet n'existe pas dans data/items).
OBJETS = {"HYPER_POTION": ("hyper_potion", "super_potion"), "FULL_HEAL": ("full_heal", "super_potion"),
	"MAX_REVIVE": ("max_revive", "revive"), "ESCAPE_ROPE": ("escape_rope", ""),
	"TM_TAKE_DOWN": ("tm09", "nugget"), "PROTEIN": ("protein", "rare_candy"),
	"CARD_KEY": ("card_key", ""), "HP_UP": ("hp_up", "rare_candy"),
	"X_ACCURACY": ("x_accuracy", ""), "CALCIUM": ("calcium", "rare_candy"),
	"TM_SWORDS_DANCE": ("tm03", "nugget"), "TM_EARTHQUAKE": ("tm26", "nugget"),
	"RARE_CANDY": ("rare_candy", ""), "CARBOS": ("carbos", "rare_candy"),
	"ELIXER": ("elixir", "revive"), "MAX_POTION": ("max_potion", "super_potion"),
	"NUGGET": ("nugget", "")}


def _coll(pokered: Path, nom: str) -> set[int]:
	texte = (pokered / "data/tilesets/collision_tile_ids.asm").read_text()
	m = re.search(nom + r"_Coll::\s*(?:\w+_Coll::\s*)*coll_tiles ([^\n]*)", texte)
	assert m, nom
	return {int(v.strip().lstrip("$"), 16) for v in m.group(1).split(",")}


def _tuile(blk: bytes, bst: bytes, w: int, x: int, y: int, remplace: dict | None = None) -> int:
	bx, by = x // 2, y // 2
	bloc = (remplace or {}).get((bx, by), blk[by * w + bx])
	return bst[bloc * 16 + (2 * (y % 2) + 1) * 4 + 2 * (x % 2)]


class Objet:
	def __init__(self, rang: int, x: int, y: int, sprite: str, mouvement: str, facing: str,
			texte: str, extra: list[str]) -> None:
		self.rang, self.x, self.y, self.sprite = rang, x, y, sprite
		self.mouvement, self.facing, self.texte, self.extra = mouvement, facing, texte, extra
		self.classe = extra[0] if len(extra) == 2 and extra[0].startswith("OPP_") else ""
		self.equipe = int(extra[1]) if self.classe else 0
		self.item = extra[0] if len(extra) == 1 else ""
		self.vue = 0          # portée de vue (en-tête de Dresseur)
		self.k = 0            # rang du Dresseur sur l'étage (1, 2, 3…)

	@property
	def case(self) -> Case:
		return (self.x, self.y)


class EtageRB:
	"""Un étage (ou la cabine) : tuiles, praticabilité, warps, objets, portes à carte."""

	def __init__(self, n: int, w: int, h: int) -> None:
		self.n, self.w, self.h = n, w * 2, h * 2
		self.mur: list[list[bool]] = []
		self.praticable: list[list[bool]] = []
		self.tuiles: list[list[int]] = []
		self.warps: list[tuple[int, int, str, int]] = []  # (x, y, carte RB, n° de warp)
		self.objets: list[Objet] = []
		self.portes: list[list[Case]] = []  # cases fermées de chaque porte, dans l'ordre RB
		self.portes_blocs: list[tuple[int, int, int]] = []  # (bx, by, bloc fermé)
		self.caches: list[tuple[int, int, str]] = []
		self.panneaux: list[Case] = []
		self.declencheurs: list[Case] = []  # rival (7F) ou Giovanni (11F)
		self.pad = 0x20  # tuile de la dalle de téléportation du jeu de tuiles

	def dresseurs(self) -> list[Objet]:
		return [o for o in self.objets if o.classe and o.classe != "OPP_GIOVANNI"]

	def cible(self, i: int) -> tuple[str, int]:
		x, y, carte, k = self.warps[i]
		return carte, k


def _warps(src: str) -> list[tuple[int, int, str, int]]:
	return [(int(x), int(y), d, int(k)) for x, y, d, k in re.findall(
		r"warp_event\s+(\d+),\s*(\d+),\s*(\w+),\s*(\d+)", src)]


def _objets(src: str) -> list[Objet]:
	objets = []
	for i, m in enumerate(re.finditer(r"object_event\s+(\d+),\s*(\d+),\s*(\w+),\s*(\w+),\s*(\w+),"
			r"\s*(\w+)((?:,\s*\w+)*)", src), start=1):
		x, y, sprite, mouv, facing, texte, reste = m.groups()
		extra = [v.strip() for v in reste.split(",") if v.strip()]
		objets.append(Objet(i, int(x), int(y), sprite, mouv, facing, texte, extra))
	return objets


def _caches(pokered: Path) -> dict[str, list[tuple[int, int, str]]]:
	caches: dict[str, list[tuple[int, int, str]]] = defaultdict(list)
	carte = ""
	for ligne in (pokered / "data/events/hidden_events.asm").read_text().splitlines():
		m = re.match(r"\s*hidden_events_for (\w+)", ligne)
		if m:
			carte = m.group(1)
			continue
		m = re.match(r"\s*hidden_event\s+(\d+),\s*(\d+),\s*HiddenItems,\s*(\w+)", ligne)
		if m and carte:
			caches[carte].append((int(m.group(1)), int(m.group(2)), m.group(3)))
	return caches


def _script_portes(src: str) -> list[tuple[int, int, int]]:
	"""(bx, by, bloc fermé) de chaque porte, dans l'ordre des événements UNLOCKED_DOOR<k>."""
	m = re.search(r"GateCallbackScript:(.*?)dbmapcoord", src, re.S)
	corps = m.group(1) if m else ""
	portes = []
	for bloc, by, bx in re.findall(r"ld a, \$([0-9a-fA-F]+)\s*\n\s*ld \[wNewTileBlockID\], a\s*\n"
			r"\s*lb bc, (\d+), (\d+)", corps):
		portes.append((int(bx), int(by), int(bloc, 16)))
	return portes


def _vues(src: str) -> tuple[int, list[int]]:
	m = re.search(r"def_trainers\s*(\d*)", src)
	debut = int(m.group(1)) if m and m.group(1) else 1
	return debut, [int(v) for v in re.findall(r"trainer EVENT_BEAT_\w+, (\d+),", src)]


def decoder(pokered: Path) -> dict[int, EtageRB]:
	"""Les 11 étages (clés 1..11) et la cabine (clé 0)."""
	caches = _caches(pokered)
	etages: dict[int, EtageRB] = {}
	for n, (fichier, w, h) in ETAGES.items():
		blk = (pokered / f"maps/{fichier}.blk").read_bytes()
		assert len(blk) == w * h, fichier
		entete = (pokered / f"data/maps/headers/{fichier}.asm").read_text()
		jeu = re.search(r"map_header\s+\w+,\s*\w+,\s*(\w+)", entete).group(1)
		nom_bst, nom_coll, pad, murs = TILESETS[jeu]
		bst = (pokered / f"gfx/blocksets/{nom_bst}.bst").read_bytes()
		coll = _coll(pokered, nom_coll)
		e = EtageRB(n, w, h)
		e.pad = pad
		obj = (pokered / f"data/maps/objects/{fichier}.asm").read_text()
		scr = (pokered / f"scripts/{fichier}.asm").read_text()
		e.warps = _warps(obj)
		e.objets = _objets(obj)
		e.panneaux = [(int(x), int(y)) for x, y in re.findall(r"bg_event\s+(\d+),\s*(\d+)", obj)]
		e.portes_blocs = _script_portes(scr)
		fermes = {(bx, by): b for bx, by, b in e.portes_blocs}
		e.tuiles = [[_tuile(blk, bst, w, x, y) for x in range(e.w)] for y in range(e.h)]
		e.praticable = [[t in coll for t in rang] for rang in e.tuiles]
		e.mur = [[t in murs for t in rang] for rang in e.tuiles]
		for bx, by, _ in e.portes_blocs:
			cases = [(x, y) for y in (2 * by, 2 * by + 1) for x in (2 * bx, 2 * bx + 1)
				if e.praticable[y][x] and _tuile(blk, bst, w, x, y, fermes) not in coll]
			e.portes.append(cases)
		debut, vues = _vues(scr)
		dresseurs = [o for o in e.objets if o.classe and o.rang >= debut and o.classe != "OPP_GIOVANNI"]
		assert len(dresseurs) == len(vues), (n, len(dresseurs), vues)
		for k, (o, v) in enumerate(zip(dresseurs, vues), start=1):
			o.vue, o.k = v, k
		e.caches = caches.get(f"SILPH_CO_{n}F", [])
		bloc_coord = re.search(r"\.(?:RivalEncounterCoordinates|PlayerCoordsArray):(.*?)db -1", scr, re.S)
		if bloc_coord:
			e.declencheurs = [(int(x), int(y)) for x, y in
				re.findall(r"dbmapcoord\s+(\d+),\s*(\d+)", bloc_coord.group(1))]
		etages[n] = e
	fichier, w, h = CABINE
	blk = (pokered / f"maps/{fichier}.blk").read_bytes()
	lbst = (pokered / "gfx/blocksets/lobby.bst").read_bytes()
	lcoll = _coll(pokered, "Lobby")
	c = EtageRB(0, w, h)
	obj = (pokered / f"data/maps/objects/{fichier}.asm").read_text()
	c.warps = _warps(obj)
	c.panneaux = [(int(x), int(y)) for x, y in re.findall(r"bg_event\s+(\d+),\s*(\d+)", obj)]
	c.tuiles = [[_tuile(blk, lbst, w, x, y) for x in range(c.w)] for y in range(c.h)]
	# La cabine RB : les portes (1..2, 3) sont praticables (warps) ; le reste par Lobby_Coll.
	c.praticable = [[t in lcoll for t in rang] for rang in c.tuiles]
	c.mur = [[not p for p in rang] for rang in c.praticable]
	etages[0] = c
	return etages


# --- Lecture des warps : escaliers, téléporteurs, ascenseur, sortie -------------------------------

def nature_warp(e: EtageRB, i: int) -> str:
	"""« U », « D », « L », « T », « E » (sortie) ou « X » (warp RB inaccessible, ignoré)."""
	x, y, carte, k = e.warps[i]
	if carte == "SILPH_CO_ELEVATOR":
		return "L"
	if carte == "LAST_MAP":
		return "E" if e.n == 1 else "X"
	if e.tuiles[y][x] == e.pad:
		return "T"
	m = NOM_RB.get(carte)
	if m is None:
		return "X"
	if e.n == 1 and (x, y) == (16, 10):
		return "X"
	return "U" if m > e.n else "D"


def arrivee_escalier(e: EtageRB, x: int, y: int) -> Case:
	"""Case de pose devant un escalier ou une porte du mur nord (une case plus bas)."""
	return (x, y + 1)


def nom_spawn(e: EtageRB, i: int, etages: dict[int, EtageRB]) -> str:
	x, y, carte, k = e.warps[i]
	nat = nature_warp(e, i)
	if nat == "L":
		return "from_elevator"
	if nat == "E":
		return "from_city"
	if nat == "T":
		return f"tp_{i + 1}"
	return f"from_{NOM_RB[carte]}f"


def _cle_paire(a: tuple[int, int], b: tuple[int, int]) -> str:
	(na, ka), (nb, kb) = sorted([a, b])
	return f"t{na}f{ka}_{nb}f{kb}"


def liaisons(etages: dict[int, EtageRB]) -> list[dict]:
	"""Toutes les liaisons RB utiles, une par warp de départ (escaliers, téléporteurs, ascenseur,
	sortie), avec le nom du point d'apparition visé et la paire."""
	out = []
	for n in ETAGES:
		e = etages[n]
		for i, (x, y, carte, k) in enumerate(e.warps):
			nat = nature_warp(e, i)
			if nat == "X":
				continue
			d = {"etage": n, "rb": i + 1, "case": (x, y), "nature": nat}
			if nat == "L":
				d.update(vers=f"{CARTE_CABINE}", spawn="", paire="ascenseur")
			elif nat == "E":
				d.update(vers="saffron_city", spawn="from_silph", paire="safrania")
			else:
				m = NOM_RB[carte]
				autre = etages[m]
				j = k - 1
				if nat == "T":
					d.update(vers=CARTE[m], spawn=f"tp_{k}", paire=_cle_paire((n, i + 1), (m, k)))
				else:
					d.update(vers=CARTE[m], spawn=f"from_{n}f", paire=f"e{min(n, m)}_{max(n, m)}")
				d["case_arrivee"] = autre.warps[j][:2]
			out.append(d)
	return out


# --- Brouillons -----------------------------------------------------------------------------------

def brut(e: EtageRB, avec_objets: bool = True) -> list[str]:
	g = [["." if p else ("#" if m else "M") for p, m in zip(rp, rm)]
		for rp, rm in zip(e.praticable, e.mur)]
	if e.n:
		for i, (x, y, _, _) in enumerate(e.warps):
			nat = nature_warp(e, i)
			if nat != "X":
				g[y][x] = nat
			elif e.tuiles[y][x] == e.pad:
				g[y][x] = "T"
		for porte in e.portes:
			for x, y in porte:
				g[y][x] = "K"
	else:
		for x, y, _, _ in e.warps:
			g[y][x] = "L"
		for x, y in e.panneaux:
			g[y][x] = "P"
	if avec_objets:
		for o in e.objets:
			if o.classe:
				c = CLASSES[o.classe][0]
			elif o.sprite == "SPRITE_POKE_BALL":
				c = "o"
			elif o.sprite == "SPRITE_BLUE":
				c = "B"
			elif o.sprite == "SPRITE_CLIPBOARD":
				c = "="
			else:
				c = "e"
			g[o.y][o.x] = c
		for x, y, _ in e.caches:
			g[y][x] = "c"
	return ["".join(r) for r in g]


def _afficher(titre: str, rangs: list[str]) -> None:
	w = len(rangs[0])
	print(f"--- {titre}")
	print("    " + "".join(str(x // 10) for x in range(w)))
	print("    " + "".join(str(x % 10) for x in range(w)))
	for y, r in enumerate(rangs):
		print(f"{y:2d}  {r}")


def _face(o: Objet) -> str:
	return DIRECTIONS.get(o.facing, "down")


def _depuis(e: EtageRB, x: int, y: int) -> tuple[Case, str]:
	"""Case praticable voisine d'où lire un objet caché, et la direction à regarder."""
	for (dx, dy), face in [((0, 1), "N"), ((-1, 0), "E"), ((1, 0), "O"), ((0, -1), "S")]:
		nx, ny = x + dx, y + dy
		if 0 <= nx < e.w and 0 <= ny < e.h and e.praticable[ny][nx]:
			return (nx, ny), face
	return (x, y), "N"


def role_pnj(n: int, o: Objet) -> tuple[str, str]:
	"""(identifiant de position, rôle) d'un PNJ qui ne combat pas."""
	if n == 1:
		return "hotesse", "silph_co_1f_receptionist"
	if n == 11 and o.sprite == "SPRITE_SILPH_PRESIDENT":
		return "president", "silph_co_president"
	if n == 11 and o.sprite == "SPRITE_BEAUTY":
		return "secretaire", "silph_co_11f_secretary"
	if n == 9 and o.sprite == "SPRITE_NURSE":
		return "infirmiere", "silph_co_9f_nurse"
	if n == 7 and o.rang == 1:
		return "employe_lokhlass", "silph_co_7f_lapras_giver"
	if o.sprite == "SPRITE_CLIPBOARD":
		return f"rapport_{o.rang}", f"silph_co_{n}f_report_{o.rang}"
	return f"employe_{o.rang}", f"silph_co_{n}f_worker_{o.rang}"


def positions(e: EtageRB, etages: dict[int, EtageRB]) -> list[str]:
	"""Brouillon de section POSITIONS (noms finals) d'un étage."""
	lignes = []
	n = e.n
	for d in [d for d in liaisons(etages) if d["etage"] == n]:
		x, y = d["case"]
		i = d["rb"] - 1
		nat = d["nature"]
		if nat in "UD":
			m = int(d["vers"].split("_")[2].rstrip("f"))
			sens = "monte" if nat == "U" else "descend"
			lignes.append(f"vers_{m}f escalier {x},{y} libre vers={d['vers']}:{d['spawn']} "
				f"paire={d['paire']} sens={sens}  # RB warp {d['rb']} → {CARTE[m]} warp "
				f"{e.warps[i][3]} {d['case_arrivee']}")
			ax, ay = arrivee_escalier(e, x, y)
			lignes.append(f"from_{m}f spawn {ax},{ay} libre paire={d['paire']} facing=down  "
				f"# arrivée depuis le {m}F, une case devant l'escalier")
		elif nat == "L":
			lignes.append(f"ascenseur ascenseur {x},{y} libre etage={n}F vers={CARTE_CABINE}:entrance  "
				f"# porte de l'ascenseur (RB warp {d['rb']})")
			lignes.append(f"from_elevator spawn {x},{y + 1} libre paire=ascenseur etage={n}F "
				f"facing=down  # sortie de la cabine, une case devant la porte")
		elif nat == "E":
			pass
		elif nat == "T":
			m = int(d["vers"].split("_")[2].rstrip("f"))
			lignes.append(f"teleporteur_{d['rb']} teleporteur {x},{y} libre "
				f"vers={d['vers']}:{d['spawn']} paire={d['paire']}  # RB warp {d['rb']} → "
				f"{m}F warp {e.warps[i][3]} {d['case_arrivee']}")
			lignes.append(f"tp_{d['rb']} spawn {x},{y} libre  # arrivée sur la dalle "
				f"(ne la déclenche pas) ; orientation conservée")
	for k, porte in enumerate(e.portes, start=1):
		bx, by, bloc = e.portes_blocs[k - 1]
		for lettre, (x, y) in zip("ab", porte):
			lignes.append(f"porte_d{k}_{lettre} porte_carte {x},{y} bloque id=d{k} cle=card_key  "
				f"# RB bloc ({bx}, {by}) fermé par ${bloc:02x}, EVENT_SILPH_CO_{n}_UNLOCKED_DOOR"
				+ (str(k) if len(e.portes) > 1 else ""))
	for o in e.objets:
		if o.classe == "OPP_GIOVANNI":
			lignes.append(f"giovanni giovanni {o.x},{o.y} bloque trainer=silph_co_giovanni "
				f"facing={_face(o)} inevitable=oui scene=oui  # RB {o.classe}, {o.equipe}")
		elif o.classe:
			nom = CLASSES[o.classe][1]
			lignes.append(f"dresseur_{o.k} dresseur {o.x},{o.y} bloque "
				f"trainer=silph_co_{n}f_{o.k} facing={_face(o)} sight={o.vue} classe={nom.lower()}  "
				f"# RB objet {o.rang} : {o.classe}, {o.equipe}")
		elif o.sprite == "SPRITE_BLUE":
			lignes.append(f"rival rival {o.x},{o.y} bloque trainer=rival_silph facing={_face(o)} "
				f"inevitable=oui scene=oui  # RB SPRITE_BLUE (OPP_RIVAL2, 7 à 9 selon le starter)")
		elif o.sprite == "SPRITE_CLIPBOARD":
			lignes.append(f"rapport_{o.rang} examen {o.x},{o.y} bloque texte=silph_co_{n}f_report_"
				f"{o.rang}  # RB SPRITE_CLIPBOARD : rapport Pokémon posé sur un bureau")
		elif o.sprite == "SPRITE_POKE_BALL":
			ident, repli = OBJETS[o.item]
			nom = "silph_co_5f_card_key" if o.item == "CARD_KEY" else f"silph_co_{n}f_item_{o.rang}"
			attrs = f"item={ident}" + (f" fallback={repli}" if repli else "")
			lignes.append(f"{nom} objet_visible {o.x},{o.y} bloque {attrs}  # RB {o.item}")
		else:
			ident, role = role_pnj(n, o)
			lignes.append(f"{ident} pnj {o.x},{o.y} bloque role={role} facing={_face(o)}  "
				f"# RB {o.sprite}, {o.mouvement}")
	for j, (x, y, item) in enumerate(e.caches, start=1):
		ident, repli = OBJETS[item]
		(dx, dy), face = _depuis(e, x, y)
		attrs = f"item={ident}" + (f" fallback={repli}" if repli else "")
		lignes.append(f"silph_co_{n}f_hidden_{j} objet_cache {x},{y} bloque {attrs} "
			f"depuis={dx},{dy} face={face}  # RB hidden_event {item}")
	for j, (x, y) in enumerate(e.declencheurs, start=1):
		quoi = "rival" if n == 7 else "giovanni"
		lignes.append(f"declencheur_{quoi}_{j} declencheur {x},{y} libre scene={quoi}  "
			f"# RB : le pas sur cette case lance la scène")
	return lignes


def projet(e: EtageRB) -> list[str]:
	"""L'étage dans les caractères des grilles du projet (sans objets)."""
	return brut(e, avec_objets=False)


# --- Graphe des salles RB -------------------------------------------------------------------------

def graphe(etages: dict[int, EtageRB]) -> list[str]:
	"""Salles = composantes de cases praticables (portes fermées, dalles et escaliers à part) ;
	arêtes = escaliers, téléporteurs, ascenseur, portes à carte."""
	salle: dict[tuple[int, Case], int] = {}
	noms: dict[int, str] = {}
	nb = 0
	pads: dict[tuple[int, Case], tuple[str, int]] = {}
	portes: dict[tuple[int, Case], int] = {}
	for n in ETAGES:
		e = etages[n]
		for i, (x, y, _, _) in enumerate(e.warps):
			if nature_warp(e, i) != "X":
				pads[(n, (x, y))] = (nature_warp(e, i), i)
		for k, porte in enumerate(e.portes, start=1):
			for c in porte:
				portes[(n, c)] = k
	for n in ETAGES:
		e = etages[n]
		compte = 0
		for y in range(e.h):
			for x in range(e.w):
				c = (x, y)
				if (n, c) in salle or not e.praticable[y][x] or (n, c) in pads or (n, c) in portes:
					continue
				compte += 1
				salle[(n, c)] = nb
				noms[nb] = f"{n}F-{chr(64 + compte)}"
				file = deque([c])
				while file:
					cx, cy = file.popleft()
					for dx, dy in VOISINS:
						v = (cx + dx, cy + dy)
						if 0 <= v[0] < e.w and 0 <= v[1] < e.h and e.praticable[v[1]][v[0]] \
								and (n, v) not in salle and (n, v) not in pads and (n, v) not in portes:
							salle[(n, v)] = nb
							file.append(v)
				nb += 1

	def salle_de(n: int, c: Case) -> int | None:
		if (n, c) in salle:
			return salle[(n, c)]
		for dx, dy in VOISINS:
			v = (c[0] + dx, c[1] + dy)
			if (n, v) in salle:
				return salle[(n, v)]
		return None

	arcs: dict[int, list[str]] = defaultdict(list)
	for d in liaisons(etages):
		a = salle_de(d["etage"], d["case"])
		if d["nature"] == "L":
			arcs[a].append(f"ascenseur (cabine : tous les étages) depuis {d['case']}")
			continue
		if d["nature"] == "E":
			arcs[a].append(f"sortie {d['case']} → Safrania")
			continue
		m = int(d["vers"].split("_")[2].rstrip("f"))
		b = salle_de(m, d["case_arrivee"])
		quoi = {"U": "escalier ↑", "D": "escalier ↓", "T": "téléporteur"}[d["nature"]]
		arcs[a].append(f"{quoi} {d['case']} → {noms.get(b, '?')} {d['case_arrivee']}")
	for (n, c), k in sorted(portes.items()):
		vs = sorted({salle[(n, (c[0] + dx, c[1] + dy))] for dx, dy in VOISINS
			if (n, (c[0] + dx, c[1] + dy)) in salle})
		for a in vs:
			for b in vs:
				if a != b:
					t = f"porte à carte d{k} {c} → {noms[b]}"
					if t not in arcs[a]:
						arcs[a].append(t)
	contenu: dict[int, list[str]] = defaultdict(list)
	for n in ETAGES:
		e = etages[n]
		for o in e.objets:
			s = salle_de(n, o.case)
			if s is None:
				continue
			if o.classe == "OPP_GIOVANNI":
				contenu[s].append("GIOVANNI")
			elif o.classe:
				contenu[s].append(f"{CLASSES[o.classe][1]} {n}F-{o.k}")
			elif o.sprite == "SPRITE_BLUE":
				contenu[s].append("RIVAL")
			elif o.item == "CARD_KEY":
				contenu[s].append("CARTE MAGNÉTIQUE")
			elif o.sprite == "SPRITE_POKE_BALL":
				contenu[s].append(o.item.lower())
			elif o.sprite == "SPRITE_SILPH_PRESIDENT":
				contenu[s].append("président")
	lignes = []
	for i in sorted(noms, key=lambda k: (int(noms[k].split("F")[0]), noms[k])):
		taille = sum(1 for v in salle.values() if v == i)
		lignes.append(f"{noms[i]} ({taille} cases) : {', '.join(contenu[i]) or '—'}")
		for t in arcs[i]:
			lignes.append(f"    -> {t}")
	return lignes


# --- Écarts avec les grilles du projet ------------------------------------------------------------

def _ecarts(etages: dict[int, EtageRB], plans: Path) -> int:
	sys.path.insert(0, str(Path(__file__).parent))
	from plan_grille import lire  # noqa: E402
	total = 0
	for n in list(ETAGES) + [0]:
		e = etages[n]
		chemin = plans / (FICHIER_GRILLE[n] if n else FICHIER_CABINE)
		if not chemin.exists():
			print(f"{chemin.name} : absent")
			total += 1
			continue
		plan = lire(chemin)
		ref = projet(e)
		diffs = []
		if (plan.width, plan.height) != (e.w, e.h):
			diffs.append(f"taille {plan.width} × {plan.height} ≠ RB {e.w} × {e.h}")
		else:
			for y in range(e.h):
				for x in range(e.w):
					a, b = ref[y][x], plan.rows[y][x]
					if a != b:
						diffs.append(f"({x},{y}) RB « {a} » → projet « {b} »")
		attendues = {line.split()[0]: line for line in positions(e, etages)} if n else {}
		for ident, line in attendues.items():
			mots = line.split()
			p = plan.positions.get(ident)
			cases = mots[2]
			if p is None:
				diffs.append(f"position {ident} absente ({cases})")
				continue
			x, y = map(int, cases.split(","))
			if p.cells != [(x, y)]:
				diffs.append(f"position {ident} en {p.cells} au lieu de RB ({x}, {y})")
		print(f"{chemin.name} : {e.w} × {e.h}, {len(diffs)} écart(s)")
		for d in diffs:
			print("   " + d)
		total += len(diffs)
	return total


# --- Safrania ------------------------------------------------------------------------------------

def safrania(pokered: Path) -> None:
	bst = (pokered / "gfx/blocksets/overworld.bst").read_bytes()
	coll = _coll(pokered, "Overworld")
	blk = (pokered / "maps/SaffronCity.blk").read_bytes()
	w, h = 20, 18
	assert len(blk) == w * h
	tuiles = [[_tuile(blk, bst, w, x, y) for x in range(2 * w)] for y in range(2 * h)]
	src = (pokered / "data/maps/objects/SaffronCity.asm").read_text()
	warps = _warps(src)
	g = [["." if t in coll else "#" for t in r] for r in tuiles]
	for x, y, _, _ in warps:
		g[y][x] = "D"
	panneaux = [(int(x), int(y)) for x, y in re.findall(r"bg_event\s+(\d+),\s*(\d+)", src)]
	for x, y in panneaux:
		g[y][x] = "n"
	objets = _objets(src)
	for o in objets:
		g[o.y][o.x] = "R" if o.sprite == "SPRITE_ROCKET" else "h"
	_afficher("Safrania RB (40 × 36) : # bloqué · . praticable · D porte · n panneau · R sbire · h "
		"habitant", ["".join(r) for r in g])
	print("portes :", [(x, y, d) for x, y, d, _ in warps])
	print("panneaux :", panneaux)
	for o in objets:
		print(f"  objet {o.rang} : {o.sprite} ({o.x}, {o.y}) {o.mouvement} {o.facing} {o.texte}")


def main(argv: list[str]) -> int:
	if len(argv) < 2 or argv[1].startswith("--"):
		print(__doc__)
		return 2
	pokered = Path(argv[1])
	if "--safrania" in argv:
		safrania(pokered)
		return 0
	etages = decoder(pokered)
	if "--ecarts" in argv:
		total = _ecarts(etages, Path(__file__).resolve().parents[2] / "tools" / "plans")
		print("Aucun écart." if not total else f"{total} écart(s) au total.")
		return 0
	if "--graphe" in argv:
		print("Graphe des salles de la Sylphe SARL (Rouge/Bleu ; portes à carte fermées) :")
		for ligne in graphe(etages):
			print(ligne)
		return 0
	for n in list(ETAGES) + [0]:
		e = etages[n]
		titre = f"{n}F ({e.w} × {e.h})" if n else f"cabine ({e.w} × {e.h})"
		if "--brouillon" in argv:
			_afficher(titre + " — caractères du projet", projet(e))
			if n:
				print("POSITIONS (brouillon)")
				for ligne in positions(e, etages):
					print("  " + ligne)
		else:
			_afficher(titre, brut(e))
			for i, (x, y, d, k) in enumerate(e.warps):
				print(f"  warp {i + 1} ({x}, {y}) → {d} {k} [{nature_warp(e, i) if n else 'L'}]")
			for o in e.dresseurs():
				print(f"  Dresseur {n}F-{o.k} : {CLASSES[o.classe][1]} ({o.x}, {o.y}) {o.facing} "
					f"vue {o.vue} — {o.classe}, {o.equipe}")
			if e.portes:
				print("  portes :", e.portes)
			if e.caches:
				print("  cachés :", e.caches)
			if e.declencheurs:
				print("  déclencheurs :", e.declencheurs)
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
