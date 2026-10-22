#!/usr/bin/env python3
"""Décodeur des salles de la Ligue dans Rouge/Bleu : géométrie de référence des grilles (J30, T2).

**Lit un désassemblage `pokered` local passé en argument** (jamais embarqué dans le dépôt) :
`<pokered>/maps/*.blk`, `gfx/blocksets/*.bst`. Bibliothèque standard seulement ; à lancer avec
`python3 -I`. Modèle : `j29_rb_decode.py` (une carte RB = blocs de 2 × 2 cases ; la collision
d'une case est celle de la tuile en bas à gauche de son carré de 2 × 2 tuiles ; collisions de
`data/tilesets/collision_tile_ids.asm`).

Salles (`docs/tech/jalon-30.md` §2.1, 1:1 [D]) : Olga (10 × 12), Aldo (10 × 12), Agatha
(10 × 12, tileset `cemetery`), Peter (26 × 26), Champion (8 × 8), Panthéon (10 × 8).

Adaptations de Kanto 2026 [D] :
- **portes** : les portes nord et sud (`warp_event` RB) deviennent `X` (praticables, warps) ; RB
  ferme la porte nord par des blocs tant que le membre n'est pas battu, le projet par un warp
  conditionnel (`si=league_stage_<k>_cleared`) ; la porte sud est fermée pendant la tentative
  (`unless=league_attempt_active`, RB : la porte se referme derrière le joueur) ;
- **passages** : la tuile `$30` (passage fermé ou ouvert par les scripts RB) devient du sol ;
- **appel du membre** : RB amène le joueur devant le membre dès l'entrée (`*EntranceCoords`,
  marche forcée) ; le projet pose un déclencheur `appel_<membre>` en travers du chemin [D] (rangée
  au-dessus de l'entrée ; passage du couloir chez Peter ; rangée 5 chez le Champion) ;
- **nettoyage** : le pourtour devient mur (sauf les portes), et toute case de sol que l'on ne
  peut pas atteindre depuis l'entrée devient mur (îlots décoratifs de RB : coin nord-est de la
  salle de Peter, recoins de la salle d'Aldo). `--ecarts` liste ces retouches ;
- **Panthéon** : pas de porte de sortie jouable (RB : la cérémonie enchaîne sur le générique) ;
  la porte sud reste un décor (`#`).

Sorties :
  python3 -I tools/art/j30_rb_decode.py <pokered>            les salles décodées (avant retouche)
  python3 -I tools/art/j30_rb_decode.py <pokered> --ecarts   retouches et écarts avec tools/plans/
  python3 -I tools/art/j30_rb_decode.py <pokered> --ecrire   (ré)écrit les six grilles
"""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

Case = tuple[int, int]
RACINE = Path(__file__).resolve().parents[2]
PLANS = RACINE / "tools" / "plans"

# Tuiles praticables par tileset (`data/tilesets/collision_tile_ids.asm` : Gym_Coll, Dojo_Coll
# identiques ; Cemetery_Coll).
PRATICABLES_RB = {
	"gym": {0x11, 0x16, 0x19, 0x2B, 0x3C, 0x3D, 0x3F, 0x4A, 0x4C, 0x4D, 0x03},
	"cemetery": {0x01, 0x10, 0x13, 0x1B, 0x22, 0x42, 0x52},
}

# Tuile « passage fermé » des salles (bloc posé ou retiré par les scripts RB : porte nord d'Olga,
# passage du couloir de Peter, fermé derrière le joueur) : sol pour le projet, les fermetures
# passant par des warps conditionnels.
PASSAGE_RB = 0x30

# Carte du jeu → (nom RB, blockset, largeur et hauteur en blocs, grille, nom affiché, étape).
SALLES = {
	"league_lorelei": ("LoreleisRoom", "gym", 5, 6, "ligue_olga", "Olga", 0),
	"league_bruno": ("BrunosRoom", "gym", 5, 6, "ligue_aldo", "Aldo", 1),
	"league_agatha": ("AgathasRoom", "cemetery", 5, 6, "ligue_agatha", "Agatha", 2),
	"league_lance": ("LancesRoom", "gym", 13, 13, "ligue_peter", "Peter", 3),
	"league_champion": ("ChampionsRoom", "gym", 4, 4, "ligue_champion", "Champion", 4),
	"hall_of_fame": ("HallOfFame", "gym", 5, 4, "pantheon", "Panthéon", 5),
}
ORDRE = list(SALLES)

# Portes (cases RB des `warp_event`), entrée (spawn) et membre (`object_event`), par salle.
# sud : porte d'entrée (retour vers la salle d'avant) ; nord : porte de sortie.
CONCEPTION: dict[str, dict] = {
	"league_lorelei": {
		"sud": [(4, 11), (5, 11)], "nord": [(4, 0), (5, 0)], "entree": (4, 10),
		"membre": ("olga", (5, 2), "league_lorelei"), "declencheur": [(4, 9), (5, 9)],
		"depuis": ("indigo_plateau_lobby", "from_league"),
	},
	"league_bruno": {
		"sud": [(4, 11), (5, 11)], "nord": [(4, 0), (5, 0)], "entree": (4, 10),
		"membre": ("aldo", (5, 2), "league_bruno"), "declencheur": [(4, 9), (5, 9)],
	},
	"league_agatha": {
		"sud": [(4, 11), (5, 11)], "nord": [(4, 0), (5, 0)], "entree": (4, 10),
		"membre": ("agatha", (5, 2), "league_agatha"), "declencheur": [(4, 9), (5, 9)],
	},
	"league_lance": {
		# RB : on arrive sur (24, 16), bord est du couloir ; l'entrée du projet est la case à
		# l'ouest, la porte reste sur la case d'arrivée RB.
		"sud": [(24, 16)], "nord": [(5, 0), (6, 0)], "entree": (23, 16),
		"membre": ("peter", (6, 1), "league_lance"), "declencheur": [(5, 12), (6, 12)],
	},
	"league_champion": {
		"sud": [(3, 7), (4, 7)], "nord": [(3, 0), (4, 0)], "entree": (4, 6),
		"membre": ("rival", (4, 2), "rival_champion"),
		"declencheur": [(x, 5) for x in range(1, 7)],
		"chen": (3, 7),
	},
	"hall_of_fame": {
		"sud": [], "nord": [], "entree": (4, 6), "chen": (5, 2),
	},
}


def _lire(pokered: Path, rb: str, bst_nom: str, lb: int, hb: int) -> list[list[bool]]:
	blk = (pokered / f"maps/{rb}.blk").read_bytes()
	assert len(blk) == lb * hb, (rb, len(blk), lb * hb)
	bst = (pokered / f"gfx/blocksets/{bst_nom}.bst").read_bytes()
	sol = PRATICABLES_RB[bst_nom]

	def praticable(x: int, y: int) -> bool:
		b = blk[(y // 2) * lb + x // 2]
		tuile = bst[b * 16 + (2 * (y % 2) + 1) * 4 + 2 * (x % 2)]
		return tuile in sol or (bst_nom == "gym" and tuile == PASSAGE_RB)

	return [[praticable(x, y) for x in range(lb * 2)] for y in range(hb * 2)]


def decoder(pokered: Path) -> dict[str, list[str]]:
	"""Salles RB brutes : « . » sol, « # » mur."""
	return {ident: ["".join("." if p else "#" for p in rangee)
		for rangee in _lire(pokered, rb, bst, lb, hb)]
		for ident, (rb, bst, lb, hb, *_reste) in SALLES.items()}


def nettoyer(ident: str, brut: list[str]) -> tuple[list[str], list[Case]]:
	"""Grille du projet : portes « X », pourtour en mur, sol inaccessible en mur. Rend aussi les
	cases retouchées (sol RB devenu mur)."""
	conc = CONCEPTION[ident]
	h, w = len(brut), len(brut[0])
	portes = set(conc["sud"]) | set(conc["nord"])
	grille = [list(r) for r in brut]
	for y in range(h):
		for x in range(w):
			if (x, y) in portes:
				grille[y][x] = "X"
			elif x in (0, w - 1) or y in (0, h - 1):
				grille[y][x] = "#"
	# Sol atteignable depuis l'entrée (portes comprises).
	vu = {conc["entree"]}
	file = deque([conc["entree"]])
	while file:
		x, y = file.popleft()
		for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
			n = (x + dx, y + dy)
			if 0 <= n[0] < w and 0 <= n[1] < h and n not in vu and grille[n[1]][n[0]] in ".X":
				vu.add(n)
				file.append(n)
	retouches: list[Case] = []
	for y in range(h):
		for x in range(w):
			if grille[y][x] in ".X" and (x, y) not in vu:
				grille[y][x] = "#"
			if brut[y][x] == "." and grille[y][x] == "#":
				retouches.append((x, y))
	return ["".join(r) for r in grille], retouches


def _plage(cases: list[Case]) -> str:
	xs = sorted({c[0] for c in cases})
	ys = sorted({c[1] for c in cases})
	fx = f"{xs[0]}..{xs[-1]}" if len(xs) > 1 else str(xs[0])
	fy = f"{ys[0]}..{ys[-1]}" if len(ys) > 1 else str(ys[0])
	return f"{fx},{fy}"


def positions(ident: str) -> list[str]:
	conc = CONCEPTION[ident]
	etape = SALLES[ident][6]
	i = ORDRE.index(ident)
	lignes = []
	ex, ey = conc["entree"]
	if conc["sud"]:
		if i == 0:
			carte, spawn = conc["depuis"]
		else:
			carte, spawn = ORDRE[i - 1], "from_north"
		lignes.append(f"{'porte_sud':<20} {'warp':<14} {_plage(conc['sud']):<12} libre   "
			f"vers={carte}:{spawn} unless=league_attempt_active  # fermée pendant la tentative")
	sens = "←" if ident == "league_lance" else "↑"
	lignes.append(f"{'from_south':<20} {'spawn':<14} {f'{ex},{ey}':<12} libre   # tourné {sens}")
	if conc["nord"]:
		suivante = ORDRE[i + 1]
		nx = min(c[0] for c in conc["nord"])
		lignes.append(f"{'porte_nord':<20} {'warp':<14} {_plage(conc['nord']):<12} libre   "
			f"vers={suivante}:from_south si=league_stage_{etape}_cleared  # ouverte après la victoire")
		lignes.append(f"{'from_north':<20} {'spawn':<14} {f'{nx},1':<12} libre   "
			f"# tourné ↓ (hors tentative : retour depuis la salle suivante)")
	if "membre" in conc:
		nom, (mx, my), dresseur = conc["membre"]
		lignes.append(f"{nom:<20} {'dresseur':<14} {f'{mx},{my}':<12} bloque  facing=down "
			f"sight=4 trainer={dresseur}  # vaincu : reste en place, réplique « vaincu »")
	if "declencheur" in conc:
		nom, _case, dresseur = conc["membre"]
		lignes.append(f"{'appel_' + nom:<20} {'declencheur':<14} {_plage(conc['declencheur']):<12} "
			f"libre   combat={dresseur} unless=league_stage_{etape}_cleared  # RB : EntranceCoords, "
			f"le joueur est amené devant le membre")
	if "chen" in conc:
		cx, cy = conc["chen"]
		if ident == "league_champion":
			suite = "facing=up si=league_stage_4_cleared  # arrive pour la cérémonie (league_victory)"
		else:
			suite = "facing=down  # cérémonie, puis générique et Bourg Palette (scène, pas de porte)"
		lignes.append(f"{'chen':<20} {'pnj':<14} {f'{cx},{cy}':<12} bloque  {suite}")
	return lignes


def ecrire(pokered: Path) -> None:
	salles = decoder(pokered)
	for ident, brut in salles.items():
		rb, _bst, _lb, _hb, grille_nom, nom, etape = SALLES[ident]
		grille, retouches = nettoyer(ident, brut)
		h, w = len(grille), len(grille[0])
		tete = [
			f"# {nom} — grille fonctionnelle de `{ident}` (jalon 30, T2, `docs/tech/jalon-30.md` §2.1).",
			f"# ÉCRITE par tools/art/j30_rb_decode.py --ecrire depuis Rouge/Bleu ({rb}, {w} × {h},",
			"# coordonnées RB 1:1 [D]). Contrôle : tools/art/plan_check_j30.py. Proposée par Claude le",
			"# 2026-10-22, à valider par Kevin sur planche (sous-jalon 30.0).",
			f"# Retouches [D] : {len(retouches)} case(s) de sol RB inaccessibles ou au pourtour → mur"
			+ (" (îlots décoratifs)." if retouches else "."),
			"# Toutes les salles de la Ligue : no_fly, no_teleport (pas de grotte : ni Tunnel ni Corde).",
			"#",
			"# Légende : # mur · . sol · X porte (warp, praticable ; conditions dans POSITIONS)",
			"",
			"PRATICABLES .X",
			"",
			f"GRILLE {w} {h}",
		]
		corps = [f"{y:02d} {r}" for y, r in enumerate(grille)]
		pos = ["FIN", "", "POSITIONS", *positions(ident), "FIN", ""]
		(PLANS / f"{grille_nom}.txt").write_text("\n".join(tete + corps + pos), encoding="utf-8")
		print(f"écrit : tools/plans/{grille_nom}.txt ({len(retouches)} retouche(s))")


def ecarts(pokered: Path) -> int:
	code = 0
	for ident, brut in decoder(pokered).items():
		grille_nom = SALLES[ident][4]
		grille, retouches = nettoyer(ident, brut)
		print(f"{ident} : {len(retouches)} retouche(s) {retouches}")
		chemin = PLANS / f"{grille_nom}.txt"
		if not chemin.exists():
			print(f"  {chemin.name} absente")
			code = 1
			continue
		lignes = chemin.read_text(encoding="utf-8").splitlines()
		debut = next(i for i, l in enumerate(lignes) if l.startswith("GRILLE"))
		actuelle = [l[3:] for l in lignes[debut + 1: debut + 1 + len(grille)]]
		for y, (a, b) in enumerate(zip(actuelle, grille)):
			if a != b:
				print(f"  rangée {y:02d} : plan {a} ≠ RB {b}")
				code = 1
	return code


def main(argv: list[str]) -> int:
	if len(argv) < 2:
		print(__doc__)
		return 2
	pokered = Path(argv[1])
	if "--ecrire" in argv:
		ecrire(pokered)
		return 0
	if "--ecarts" in argv:
		return ecarts(pokered)
	for ident, brut in decoder(pokered).items():
		print(f"== {ident} ({SALLES[ident][0]})")
		for y, r in enumerate(brut):
			print(f"{y:02d} {r}")
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
