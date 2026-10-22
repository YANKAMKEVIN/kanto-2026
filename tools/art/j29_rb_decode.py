#!/usr/bin/env python3
"""Décodeur des cartes du jalon 29 dans Rouge/Bleu : géométrie de référence des grilles (T1, T2).

**Lit un désassemblage `pokered` local passé en argument** (jamais embarqué dans le dépôt) :
`<pokered>/maps/*.blk`, `gfx/blocksets/*.bst`, `data/maps/objects/*.asm`,
`data/events/hidden_events.asm`. Bibliothèque standard seulement ; à lancer avec `python3 -I`.
Modèle : `seafoam_rb_decode.py` du J24 (une carte RB = blocs de 2 × 2 cases ; la collision d'une
case est celle de la tuile en bas à gauche de son carré de 2 × 2 tuiles).

Cartes : Route Victoire 1F (20 × 18), 2F et 3F (30 × 18), tileset `cavern` ; Route 23 (20 × 144)
et Plateau Indigo (20 × 18), tileset `plateau` ; poste de la Route 22 (10 × 8), tileset `gate`.

Adaptations de Kanto 2026 [D] (`docs/tech/jalon-29.md` §2.1, §2.4, §10) :
- **sans niveaux de sol** : RB sépare le sol bas (`$20`) du sol haut (`$05`) ; dans la Route
  Victoire, les deux ne se touchent jamais directement (contrôlé ici : `--niveaux`), une arête
  ou une falaise les sépare toujours, sauf aux escaliers (`$15`). Tous deviennent « . » ;
- **barrières** : les cases que l'interrupteur rend praticables (bloc remplacé par le script RB :
  `ReplaceTileBlock`) deviennent `|` (barrière ouverte par le drapeau de l'interrupteur) ;
- **rocher tombé du 3F** : le rocher n° 3 du 2F (RB : objet masqué, montré quand le rocher n° 4
  du 3F tombe dans le trou) n'apparaît que si le trou du 3F est bouché (`si=`).

Sorties :
  python3 -I tools/art/j29_rb_decode.py <pokered>            les cartes décodées (caractères du projet)
  python3 -I tools/art/j29_rb_decode.py <pokered> --niveaux  contacts directs sol bas / sol haut
  python3 -I tools/art/j29_rb_decode.py <pokered> --ecarts   écarts entre `tools/plans/` et RB
  python3 -I tools/art/j29_rb_decode.py <pokered> --ecrire   (ré)écrit les grilles tirées de RB
      (route_victoire_1f/2f/3f, route_23, plateau_indigo) : géométrie RB + positions de conception
      (table POSITIONS ci-dessous). La grille écrite fait foi ensuite (retouches à la main notées).

Grilles de la Route Victoire, sans caractère réservé (légende commune §1.3 de `systemes-2.md` :
positions seulement) : `#` mur, `.` sol bas, `:` sol haut, `=` escalier, `L` échelle (tout
niveau), `E` entrée. Les niveaux sont posés par la carte (`GameMap.low_cells`, `high_cells`,
`stairs_cells`) : on ne passe du sol bas au sol haut que par un escalier, un rocher ne change
jamais de niveau (`BoulderRules`, Refusal.LEVEL), comme dans RB.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

Case = tuple[int, int]

# Tuiles praticables par tileset (`data/tilesets/collision_tile_ids.asm`).
PRATICABLES_RB = {
	"cavern": {0x05, 0x15, 0x18, 0x1a, 0x20, 0x21, 0x22, 0x2a, 0x2d, 0x30},
	"plateau": {0x1b, 0x23, 0x2c, 0x2d, 0x3b, 0x45},
	"gate": {0x01, 0x12, 0x14, 0x1a, 0x1c, 0x37, 0x38, 0x3b, 0x3c, 0x5e},
}
EAU = 0x14
HERBE_PLATEAU = 0x45

# Cartes : nom RB, blockset, largeur et hauteur en blocs, grille du projet.
CARTES = {
	"victory_road_1f": ("VictoryRoad1F", "cavern", 10, 9, "route_victoire_1f"),
	"victory_road_2f": ("VictoryRoad2F", "cavern", 15, 9, "route_victoire_2f"),
	"victory_road_3f": ("VictoryRoad3F", "cavern", 15, 9, "route_victoire_3f"),
	"route_23": ("Route23", "plateau", 10, 72, "route_23"),
	"indigo_plateau": ("IndigoPlateau", "plateau", 10, 9, "plateau_indigo"),
	"route_22_gate": ("Route22Gate", "gate", 5, 4, "poste_ligue"),
}

# Interrupteurs et blocs remplacés (scripts RB `VictoryRoad*F.asm` : `dbmapcoord` de
# l'interrupteur, `lb bc, rangée, colonne` et bloc posé par `ReplaceTileBlock`).
INTERRUPTEURS = {
	"victory_road_1f": [((17, 13), (6, 4), 0x1d)],
	"victory_road_2f": [((1, 16), (4, 3), 0x15), ((9, 16), (7, 11), 0x1d)],
	"victory_road_3f": [((3, 5), (5, 3), 0x1d)],
}


class CarteRB:
	def __init__(self, ident: str, tuiles: list[list[int]], praticable: list[list[bool]]) -> None:
		self.ident = ident
		self.tuiles = tuiles
		self.praticable = praticable
		self.warps: list[tuple[int, int, str, int]] = []
		self.objets: list[tuple[int, int, str, str, str]] = []  # x, y, sprite, direction, texte
		self.panneaux: list[Case] = []
		self.caches: list[tuple[int, int, str]] = []
		self.barrieres: list[list[Case]] = []
		self.niveaux_ouverts: list[dict[Case, str]] = []

	@property
	def largeur(self) -> int:
		return len(self.tuiles[0])

	@property
	def hauteur(self) -> int:
		return len(self.tuiles)


def _lire_carte(pokered: Path, rb: str, bst_nom: str, lb: int, hb: int,
		remplacements: list[tuple[tuple[int, int], int]] = ()) -> list[list[int]]:
	blk = bytearray((pokered / f"maps/{rb}.blk").read_bytes())
	assert len(blk) == lb * hb, (rb, len(blk), lb * hb)
	for (rangee, colonne), bloc in remplacements:
		blk[rangee * lb + colonne] = bloc
	bst = (pokered / f"gfx/blocksets/{bst_nom}.bst").read_bytes()

	def tuile(x: int, y: int) -> int:
		b = blk[(y // 2) * lb + x // 2]
		return bst[b * 16 + (2 * (y % 2) + 1) * 4 + 2 * (x % 2)]

	return [[tuile(x, y) for x in range(lb * 2)] for y in range(hb * 2)]


def _praticable(tileset: str, t: int) -> bool:
	return t in PRATICABLES_RB[tileset]


def decoder(pokered: Path) -> dict[str, CarteRB]:
	caches: dict[str, list[tuple[int, int, str]]] = {}
	texte = (pokered / "data/events/hidden_events.asm").read_text()
	for bloc in re.finditer(r"hidden_events_for (\w+)\n(.*?)db -1", texte, re.S):
		for m in re.finditer(r"hidden_event\s+(\d+),\s*(\d+),\s*HiddenItems,\s*(\w+)", bloc.group(2)):
			caches.setdefault(bloc.group(1), []).append((int(m.group(1)), int(m.group(2)),
				m.group(3)))
	cartes: dict[str, CarteRB] = {}
	for ident, (rb, bst, lb, hb, _) in CARTES.items():
		tuiles = _lire_carte(pokered, rb, bst, lb, hb)
		pr = [[_praticable(bst, t) for t in rang] for rang in tuiles]
		c = CarteRB(ident, tuiles, pr)
		src = (pokered / f"data/maps/objects/{rb}.asm").read_text()
		c.warps = [(int(x), int(y), d, int(k)) for x, y, d, k in re.findall(
			r"warp_event\s+(\d+),\s*(\d+),\s*(\w+),\s*(\d+)", src)]
		c.objets = [(int(x), int(y), s, d, t) for x, y, s, _, d, t in re.findall(
			r"object_event\s+(\d+),\s*(\d+),\s*(\w+),\s*(\w+),\s*(\w+),\s*(\w+)", src)]
		c.panneaux = [(int(x), int(y)) for x, y in re.findall(r"bg_event\s+(\d+),\s*(\d+)", src)]
		c.caches = caches.get(ident.upper(), [])
		for coord, bloc_pos, bloc in INTERRUPTEURS.get(ident, []):
			apres = _lire_carte(pokered, rb, bst, lb, hb, [(bloc_pos, bloc)])
			ouvertes = [(x, y) for y in range(hb * 2) for x in range(lb * 2)
				if _praticable(bst, apres[y][x]) and not pr[y][x]]
			c.barrieres.append(ouvertes)
			c.niveaux_ouverts.append({(x, y): ":" if apres[y][x] in NIVEAU_HAUT else "=" if
				apres[y][x] in NIVEAU_ESCALIER else "." for x, y in ouvertes})
		cartes[ident] = c
	return cartes


NIVEAU_HAUT = {0x05}
NIVEAU_ESCALIER = {0x15}
ECHELLES = {0x18, 0x1a}
ENTREES = {0x21}


def brouillon(c: CarteRB) -> list[str]:
	"""Caractères du projet : # mur, . sol, w eau surfable, h hautes herbes, B rocher (origine),
	S interrupteur, | barrière, U V échelles (warps intérieurs), E entrée."""
	g = []
	for y in range(c.hauteur):
		rang = []
		for x in range(c.largeur):
			t = c.tuiles[y][x]
			if c.ident.startswith("victory_road") and c.praticable[y][x]:
				rang.append(":" if t in NIVEAU_HAUT else "=" if t in NIVEAU_ESCALIER
					else "L" if t in ECHELLES else "E" if t in ENTREES else ".")
				continue
			if t == EAU and c.ident in ("route_23", "indigo_plateau"):
				rang.append("w")
			elif not c.praticable[y][x]:
				rang.append("#")
			elif t == HERBE_PLATEAU and c.ident in ("route_23", "indigo_plateau"):
				rang.append("h")
			else:
				rang.append(".")
		g.append(rang)
	for i, cases in enumerate(c.barrieres):
		# Case de barrière : sol du niveau qu'elle aura ouverte (bloc remplacé de RB).
		for x, y in cases:
			g[y][x] = c.niveaux_ouverts[i].get((x, y), ".")
	return ["".join(r) for r in g]


def contacts_niveaux(c: CarteRB) -> list[tuple[Case, Case]]:
	"""Cases praticables voisines dont l'une est sol bas ($20) et l'autre sol haut ($05) : RB les
	sépare ; une grille sans niveaux les relierait."""
	paires = []
	for y in range(c.hauteur):
		for x in range(c.largeur):
			for dx, dy in ((1, 0), (0, 1)):
				nx, ny = x + dx, y + dy
				if nx >= c.largeur or ny >= c.hauteur:
					continue
				a, b = c.tuiles[y][x], c.tuiles[ny][nx]
				if {a, b} in ({0x20, 0x05}, {0x05, 0x21}, {0x2a, 0x05}, {0x41, 0x05}):
					paires.append(((x, y), (nx, ny)))
	return paires


def _afficher(titre: str, rangs: list[str]) -> None:
	largeur = len(rangs[0])
	print(f"--- {titre}")
	print("     " + "".join(str(x // 10) for x in range(largeur)))
	print("     " + "".join(str(x % 10) for x in range(largeur)))
	for y, r in enumerate(rangs):
		print(f"{y:3d}  {r}")


def _ecarts(cartes: dict[str, CarteRB], plans: Path) -> int:
	sys.path.insert(0, str(Path(__file__).parent))
	from plan_grille import lire  # noqa: E402
	total = 0
	for ident, c in cartes.items():
		chemin = plans / f"{CARTES[ident][4]}.txt"
		if not chemin.exists():
			print(f"{ident} : {chemin.name} absent")
			continue
		plan = lire(chemin)
		ref = brouillon(c)
		diffs = []
		for y in range(min(c.hauteur, plan.height)):
			for x in range(min(c.largeur, plan.width)):
				a, b = ref[y][x], plan.rows[y][x]
				if a != b:
					diffs.append(f"({x},{y}) RB « {a} » → projet « {b} »")
		print(f"{ident} : {plan.width} × {plan.height} (RB {c.largeur} × {c.hauteur}), "
			f"{len(diffs)} case(s) qui diffèrent")
		for d in diffs:
			print("   " + d)
		total += len(diffs)
	return total


# --- Grilles du projet (--ecrire) -------------------------------------------------------------

# En-têtes des grilles écrites (légende propre à chaque carte).
EN_TETES = {
	"victory_road_1f": """# Route Victoire 1F — grille fonctionnelle (jalon 29, docs/tech/jalon-29.md §2.1, §2.4), ÉCRITE par
# tools/art/j29_rb_decode.py --ecrire depuis Rouge/Bleu (VictoryRoad1F, 20 × 18, coordonnées RB 1:1).
# Contrôle : tools/art/plan_check_j29.py (anti-blocage de la Force sur les trois étages ensemble).
#
# Puzzle RB : le rocher poussé sur l'interrupteur (17, 13) ouvre la barrière (9, 12) pour toujours
# (drapeau `victory_road_1f_switch_1`, RB : EVENT_VICTORY_ROAD_1_BOULDER_ON_SWITCH) ; les rochers
# libres reviennent à leur origine à chaque entrée sur la carte (passe systèmes 2, §2.7.4).
#
# Légende : # mur · . sol bas · : sol haut · = escalier (seul passage entre les deux niveaux)
#   L échelle (warp, tout niveau) · E entrée (warp PUSH ↓ vers la Route 23)
# Rochers, interrupteur, barrière : POSITIONS seulement (légende commune, systemes-2.md §1.3).
""",
	"victory_road_2f": """# Route Victoire 2F — grille fonctionnelle (jalon 29, §2.1, §2.4), ÉCRITE par
# tools/art/j29_rb_decode.py --ecrire depuis Rouge/Bleu (VictoryRoad2F, 30 × 18, coordonnées RB 1:1).
# Contrôle : tools/art/plan_check_j29.py.
#
# Puzzles RB : interrupteur 1 (1, 16) → barrière (7, 8..9) ; interrupteur 2 (9, 16) → barrière
# (23, 14), devant l'échelle (25, 14). Le rocher n° 3 (23, 16) est celui du 3F tombé par le trou
# (23, 15) du 3F : présent seulement quand ce trou est bouché (si=victory_road_3f_hole_1_filled,
# RB : objet masqué montré par le script du 3F). Le joueur qui tombe du 3F arrive en (22, 16).
# Sulfura (11, 5), rencontre unique (S2G). Sortie est (29, 7..8) : Route 23, au nord.
#
# Légende : # mur · . sol bas · : sol haut · = escalier · L échelle · E sortie (warp PUSH →)
""",
	"victory_road_3f": """# Route Victoire 3F — grille fonctionnelle (jalon 29, §2.1, §2.4), ÉCRITE par
# tools/art/j29_rb_decode.py --ecrire depuis Rouge/Bleu (VictoryRoad3F, 30 × 18, coordonnées RB 1:1).
# Contrôle : tools/art/plan_check_j29.py.
#
# Puzzles RB : interrupteur (3, 5) → barrière (7, 10) ; le rocher n° 4 (22, 15) poussé dans le trou
# (23, 15) tombe au 2F (rocher n° 3 du 2F). Le joueur qui marche sur le trou ouvert tombe au 2F
# (22, 16) ; une fois le trou bouché, on passe dessus [D] (RB : le trou reste).
#
# Légende : # mur · . sol bas · : sol haut · = escalier · L échelle
""",
	"route_23": """# Route 23 — grille fonctionnelle (jalon 29, §2.1, §2.2), ÉCRITE par tools/art/j29_rb_decode.py
# --ecrire depuis Rouge/Bleu (Route23, 20 × 144, coordonnées RB 1:1). Contrôle : plan_check_j29.py.
#
# Du sud au nord : le poste de la Ligue (porte (7..8, 139)), sept contrôles de Badge (rangées RB du
# script Route23 : 136 Cascade, 119 Foudre, 105 Prisme, 96 Âme, 85 Marais, 56 Volcan, 35 Terre, ce
# dernier seulement à l'ouest de x 14), l'eau surfable (Surf : CS03 + Pokémon + Badge Âme), l'entrée
# de la Route Victoire (4, 31), sa sortie (14, 31) et le Plateau Indigo au nord (9..10, 0). Rien ne
# relie l'ouest (x < 14, rangées 32..71) au nord-est sans passer par la Route Victoire.
# Chaque contrôle : déclencheur sur la rangée (pas vers le nord), garde à côté (positions `garde_N`).
#
# Légende : # falaise, rochers (bloqué) · . sol · h hautes herbes · w eau surfable
""",
	"indigo_plateau": """# Plateau Indigo — grille fonctionnelle (jalon 29, §2.5), ÉCRITE par tools/art/j29_rb_decode.py
# --ecrire depuis Rouge/Bleu (IndigoPlateau, 20 × 18, coordonnées RB 1:1). Contrôle : plan_check_j29.py.
# Porte du hall (9..10, 5) → indigo_plateau_lobby ; sud (9..10, 17) → Route 23 (9..10, 0).
#
# Légende : # bâtiment, falaise · . sol
""",
}

# Positions de conception (identifiant, type, cases, bloque|libre, attributs, commentaire).
POSITIONS = {
	"victory_road_1f": [
		("entree", "warp", "8..9,17", "libre", "vers=route_23:from_victory_road_w", "PUSH ↓"),
		("from_route_23", "spawn", "8,17", "libre", "", "arrivée depuis la Route 23, tourné ↑"),
		("echelle_2f", "echelle", "1,1", "libre", "vers=victory_road_2f:from_1f", ""),
		("from_2f", "spawn", "2,1", "libre", "", "à côté de l'échelle"),
		("dresseuse_1", "pnj", "7,5", "bloque", "role=D facing=right trainer=victory_road_1f_cooltrainer_f", "RB OPP_COOLTRAINER_F 5"),
		("dresseur_1", "pnj", "3,2", "bloque", "role=D facing=down trainer=victory_road_1f_cooltrainer_m", "RB OPP_COOLTRAINER_M 5"),
		("objet_1", "objet_visible", "11,0", "bloque", "objet=tm43", "CT43 Piqué"),
		("objet_2", "objet_visible", "9,2", "bloque", "objet=rare_candy", "Super Bonbon"),
		("rocher_1", "rocher", "5,15", "bloque", "ordre=1", ""),
		("rocher_2", "rocher", "14,2", "bloque", "ordre=2", ""),
		("rocher_3", "rocher", "2,10", "bloque", "ordre=3", ""),
		("interrupteur_1", "interrupteur", "17,13", "libre", "drapeau=victory_road_1f_switch_1", ""),
		("barriere_1", "barriere", "9,12", "bloque", "ouverte_si=victory_road_1f_switch_1", ""),
	],
	"victory_road_2f": [
		("echelle_1f", "echelle", "0,8", "libre", "vers=victory_road_1f:from_2f", ""),
		("from_1f", "spawn", "0,9", "libre", "", ""),
		("sortie", "warp", "29,7..8", "libre", "vers=route_23:from_victory_road_e", "PUSH →"),
		("from_route_23", "spawn", "29,7", "libre", "", "arrivée depuis la Route 23, tourné ←"),
		("echelle_3f_a", "echelle", "23,7", "libre", "vers=victory_road_3f:from_2f_a", ""),
		("from_3f_a", "spawn", "23,8", "libre", "", ""),
		("echelle_3f_b", "echelle", "27,7", "libre", "vers=victory_road_3f:from_2f_b", ""),
		("from_3f_b", "spawn", "27,8", "libre", "", ""),
		("echelle_3f_c", "echelle", "25,14", "libre", "vers=victory_road_3f:from_2f_c", ""),
		("from_3f_c", "spawn", "24,14", "libre", "", ""),
		("echelle_3f_d", "echelle", "1,1", "libre", "vers=victory_road_3f:from_2f_d", ""),
		("from_3f_d", "spawn", "2,1", "libre", "", ""),
		("chute_joueur_1", "chute_joueur", "22,16", "libre", "depuis=victory_road_3f:1", "chute du trou du 3F"),
		("karateka", "pnj", "12,9", "bloque", "role=D facing=left trainer=victory_road_2f_blackbelt", "RB OPP_BLACKBELT 9"),
		("jongleur_1", "pnj", "21,13", "bloque", "role=D facing=left trainer=victory_road_2f_juggler_1", "RB OPP_JUGGLER 2"),
		("dompteur", "pnj", "19,8", "bloque", "role=D facing=down trainer=victory_road_2f_tamer", "RB OPP_TAMER 5"),
		("pokemaniac", "pnj", "4,2", "bloque", "role=D facing=down trainer=victory_road_2f_pokemaniac", "RB OPP_POKEMANIAC 6"),
		("jongleur_2", "pnj", "26,3", "bloque", "role=D facing=left trainer=victory_road_2f_juggler_2", "RB OPP_JUGGLER 5"),
		("sulfura", "pnj", "11,5", "bloque", "role=L facing=up", "Sulfura N50 (S2G), RB 11,5"),
		("moltres_front", "spawn", "11,6", "libre", "", "devant Sulfura (départ de débogage `moltres`)"),
		("objet_1", "objet_visible", "27,5", "bloque", "objet=tm17", "CT17 Sacrifice"),
		("objet_2", "objet_visible", "18,9", "bloque", "objet=full_heal", "Total Soin"),
		("objet_3", "objet_visible", "9,11", "bloque", "objet=tm05", "CT05 Ultimapoing"),
		("objet_4", "objet_visible", "11,0", "bloque", "objet=rare_candy", "RB : Défense Spéc. (pas d effet au moteur) → Super Bonbon [D]"),
		("cache_1", "objet_cache", "5,2", "libre", "objet=ultra_ball", "RB caché"),
		("cache_2", "objet_cache", "26,7", "libre", "objet=full_restore", "RB caché"),
		("rocher_1", "rocher", "4,14", "bloque", "ordre=1", ""),
		("rocher_2", "rocher", "5,5", "bloque", "ordre=2", ""),
		("rocher_3", "rocher", "23,16", "bloque", "ordre=3 si=victory_road_3f_hole_1_filled", "tombé du 3F"),
		("interrupteur_1", "interrupteur", "1,16", "libre", "drapeau=victory_road_2f_switch_1", ""),
		("interrupteur_2", "interrupteur", "9,16", "libre", "drapeau=victory_road_2f_switch_2", ""),
		("barriere_1", "barriere", "7,8..9", "bloque", "ouverte_si=victory_road_2f_switch_1", ""),
		("barriere_2", "barriere", "23,14", "bloque", "ouverte_si=victory_road_2f_switch_2", ""),
	],
	"victory_road_3f": [
		("echelle_2f_a", "echelle", "23,7", "libre", "vers=victory_road_2f:from_3f_a", ""),
		("from_2f_a", "spawn", "23,8", "libre", "", ""),
		("echelle_2f_b", "echelle", "26,8", "libre", "vers=victory_road_2f:from_3f_b", ""),
		("from_2f_b", "spawn", "26,9", "libre", "", ""),
		("echelle_2f_c", "echelle", "27,15", "libre", "vers=victory_road_2f:from_3f_c", ""),
		("from_2f_c", "spawn", "27,14", "libre", "", ""),
		("echelle_2f_d", "echelle", "2,0", "libre", "vers=victory_road_2f:from_3f_d", ""),
		("from_2f_d", "spawn", "2,1", "libre", "", ""),
		("dresseur_1", "pnj", "28,5", "bloque", "role=D facing=left trainer=victory_road_3f_cooltrainer_m_1", "RB OPP_COOLTRAINER_M 2"),
		("dresseuse_1", "pnj", "7,13", "bloque", "role=D facing=right trainer=victory_road_3f_cooltrainer_f_1", "RB OPP_COOLTRAINER_F 2"),
		("dresseur_2", "pnj", "6,14", "bloque", "role=D facing=left trainer=victory_road_3f_cooltrainer_m_2", "RB OPP_COOLTRAINER_M 3"),
		("dresseuse_2", "pnj", "13,3", "bloque", "role=D facing=right trainer=victory_road_3f_cooltrainer_f_2", "RB OPP_COOLTRAINER_F 3"),
		("objet_1", "objet_visible", "26,5", "bloque", "objet=max_revive", "Rappel Max"),
		("objet_2", "objet_visible", "7,7", "bloque", "objet=tm47", "CT47 Explosion"),
		("rocher_1", "rocher", "22,3", "bloque", "ordre=1", ""),
		("rocher_2", "rocher", "13,12", "bloque", "ordre=2", ""),
		("rocher_3", "rocher", "24,10", "bloque", "ordre=3", ""),
		("rocher_4", "rocher", "22,15", "bloque", "ordre=4 trou=1", "tombe au 2F"),
		("trou_1", "trou", "23,15", "libre", "n=1 drapeau=victory_road_3f_hole_1_filled chute=victory_road_2f", ""),
		("interrupteur_1", "interrupteur", "3,5", "libre", "drapeau=victory_road_3f_switch_1", ""),
		("barriere_1", "barriere", "7,10", "bloque", "ouverte_si=victory_road_3f_switch_1", ""),
	],
	"route_23": [
		("depuis_poste", "warp", "7..8,139", "libre", "vers=route_22_gate:from_route_23", "STEP_ON ↓ (porte nord du poste)"),
		("from_gate", "spawn", "7,138", "libre", "", "tourné ↑"),
		("entree_victoire", "warp", "4,31", "libre", "vers=victory_road_1f:from_route_23", "STEP_ON ↑"),
		("from_victory_road_w", "spawn", "4,32", "libre", "", "tourné ↓"),
		("sortie_victoire", "warp", "14,31", "libre", "vers=victory_road_2f:from_route_23", "STEP_ON ↑"),
		("from_victory_road_e", "spawn", "14,32", "libre", "", "tourné ↓"),
		("vers_plateau", "warp", "9..10,0", "libre", "vers=indigo_plateau:from_route_23", "PUSH ↑"),
		("from_plateau", "spawn", "9,0", "libre", "", "tourné ↓"),
		("panneau", "panneau", "3,33", "bloque", "texte=route_23_victory_road_sign", "T29-06"),
		("garde_1", "pnj", "4,35", "bloque", "role=G badge=badge_earth facing=down", "rangée 35, x < 14"),
		("controle_1", "controle", "0..3,35;5..7,35", "libre", "badge=badge_earth", ""),
		("garde_2", "pnj", "10,56", "bloque", "role=G badge=badge_volcano facing=down", ""),
		("controle_2", "controle", "6..9,56;11..13,56", "libre", "badge=badge_volcano", ""),
		("garde_3", "pnj", "8,85", "bloque", "role=G badge=badge_marsh facing=down surf=oui", "sur l'eau (RB : Nageur)"),
		("controle_3", "controle", "4..7,85;9..13,85", "libre", "badge=badge_marsh", "en Surf"),
		("garde_4", "pnj", "11,96", "bloque", "role=G badge=badge_soul facing=down surf=oui", "sur l'eau (RB : Nageur)"),
		("controle_4", "controle", "8..10,96;12..13,96", "libre", "badge=badge_soul", "en Surf"),
		("garde_5", "pnj", "12,105", "bloque", "role=G badge=badge_rainbow facing=down", ""),
		("controle_5", "controle", "10..11,105;13..15,105", "libre", "badge=badge_rainbow", ""),
		("garde_6", "pnj", "8,119", "bloque", "role=G badge=badge_thunder facing=down", ""),
		("controle_6", "controle", "1..6,119;9,119;11..14,119;16..18,119", "libre", "badge=badge_thunder", ""),
		("garde_7", "pnj", "8,136", "bloque", "role=G badge=badge_cascade facing=down", ""),
		("controle_7", "controle", "6..7,136;9,136", "libre", "badge=badge_cascade", ""),
		("cache_1", "objet_cache", "9,44", "libre", "objet=full_restore", "RB caché"),
		("cache_2", "objet_cache", "19,70", "libre", "objet=ultra_ball", "RB caché"),
		("cache_3", "objet_cache", "8,90", "libre", "objet=max_potion", "RB : Huile Max (pas de PP au moteur) → Potion Max [D]"),
	],
	"indigo_plateau": [
		("porte_hall", "warp", "9..10,5", "libre", "vers=indigo_plateau_lobby:entrance", "STEP_ON ↑"),
		("from_lobby", "spawn", "9,6", "libre", "", "tourné ↓"),
		("from_center", "spawn", "10,6", "libre", "", "Vol (fly_points.json), tourné ↓"),
		("vers_route_23", "warp", "9..10,17", "libre", "vers=route_23:from_plateau", "PUSH ↓"),
		("from_route_23", "spawn", "9,17", "libre", "", "tourné ↑"),
	],
}


def ecrire(cartes: dict[str, CarteRB], plans: Path) -> None:
	for ident, en_tete in EN_TETES.items():
		c = cartes[ident]
		rangs = brouillon(c)
		praticables = ".:=LE" if ident.startswith("victory_road") else ".hw"
		lignes = [en_tete.rstrip("\n"), "", f"PRATICABLES {praticables}", "",
			f"GRILLE {c.largeur} {c.hauteur}"]
		chiffres = 3 if c.hauteur > 100 else 2
		for y, r in enumerate(rangs):
			lignes.append(f"{y:0{chiffres}d} {r}")
		lignes += ["FIN", "", "POSITIONS"]
		for ident_p, kind, cases, etat, attrs, note in POSITIONS[ident]:
			ligne = f"{ident_p:<20} {kind:<15} {cases:<16} {etat:<7} {attrs}".rstrip()
			if note:
				ligne += f"  # {note}"
			lignes.append(ligne)
		lignes.append("FIN")
		(plans / f"{CARTES[ident][4]}.txt").write_text("\n".join(lignes) + "\n", encoding="utf-8")
		print(f"{CARTES[ident][4]}.txt écrite")


def main(argv: list[str]) -> int:
	if len(argv) < 2:
		print(__doc__)
		return 2
	cartes = decoder(Path(argv[1]))
	if "--ecarts" in argv:
		_ecarts(cartes, Path(__file__).resolve().parents[2] / "tools" / "plans")
		return 0
	if "--ecrire" in argv:
		ecrire(cartes, Path(__file__).resolve().parents[2] / "tools" / "plans")
		return 0
	if "--niveaux" in argv:
		for ident, c in cartes.items():
			if ident.startswith("victory_road"):
				print(ident, contacts_niveaux(c) or "aucun contact direct")
		return 0
	for ident, c in cartes.items():
		_afficher(ident, brouillon(c))
		print("  warps :", c.warps)
		for o in c.objets:
			print("  objet :", o)
		print("  panneaux :", c.panneaux, "· cachés :", c.caches)
		print("  barrières :", c.barrieres)
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
