#!/usr/bin/env python3
"""Finitions de l'entrée des combats de Dresseur (fiche docs/design/fiches-assets/entree-dresseurs.md
§13) : le joueur sur la monture de Surf en mer (héros et joueuse, de dos, pose prête et lancer), les
Nageurs dans l'eau, et la feuille du monde des Karatékas et du Maître du Dojo.

  tools/art/entree_finitions.py refs                 # références → build/art/finitions/
  tools/art/entree_finitions.py prompts              # prompts → tools/art/entree_dresseurs/finitions/
  tools/art/entree_finitions.py generer heros_surf [r]
  tools/art/entree_finitions.py exporter [image ...] # détourage, toiles, WebP, mains (trainer_intro.json)

Images (une génération Codex chacune) : `heros_surf` (le héros sur la monture, de dos), `joueuse_surf`
(la joueuse, d'après le héros obtenu), `nageurs_eau` (Nageur et Nageuse dans l'eau, debout dans l'eau
jusqu'à la poitrine), `karateka_monde` et `maitre_dojo_monde` (planches de marche 4 × 4, modèle des
PNJ du monde, série 25).

Toiles du combat : comme les autres sprites de dos et de face (§1), **bas de la toile = ligne d'eau**
(le Pokémon de Surf et le nageur sont coupés par l'eau ; c'est leur « sol »), milieu de la ligne
d'eau au centre de la toile.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import entree_dresseurs as ed  # noqa: E402
import entree_ordinaires as eo  # noqa: E402
from serie12 import MODELE_MARCHE  # noqa: E402
from serie25 import INTERDITS_PNJ  # noqa: E402

RACINE = ed.RACINE
FI = ed.ART / "finitions"
PROMPTS = Path(__file__).resolve().parent / "entree_dresseurs" / "finitions"
MONDE = RACINE / "assets" / "sprites" / "characters" / "painted"
INTRO = RACINE / "data" / "battle" / "trainer_intro.json"

STYLE = ("STYLE (impératif) : exactement la main des sprites de dos du héros joints (IMAGE 1) : "
	"illustration 2D HD « anime peint », contours fins et doux brun foncé (jamais de trait noir "
	"épais), aplats peints avec ombres douces et deux ou trois valeurs par matériau, légère granularité "
	"de pinceau, proportions réalistes-stylisées (PAS chibi), lumière neutre et douce venant de la gauche.")
FOND = ("FOND : TRANSPARENT (vrai canal alpha), aucun damier dessiné, aucun décor, aucune mer au loin, "
	"aucun ciel, aucun texte, aucune lettre, aucun cadre, aucune Poké Ball. Seule l'eau qui touche le "
	"personnage est peinte (voir EAU).")
EAU = ("EAU : la ligne d'eau est HORIZONTALE et forme le BAS de chaque pose : au ras de l'eau, une "
	"couronne d'écume blanche et de petites vaguelettes bleu turquoise translucides, étroite (au plus "
	"40 px de haut), qui entoure ce qui émerge ; rien n'est dessiné sous la ligne d'eau. Les deux poses "
	"ont leur ligne d'eau à la même hauteur.")

MONTURE = ("la MONTURE DE SURF du jeu (IMAGE 2, son design fait foi) : grosse créature marine BLEU CIEL "
	"lisse et ronde, type petit cétacé dodu, museau CRÈME, petits yeux noirs ronds et doux, deux "
	"nageoires latérales arrondies, queue en éventail à deux lobes ; assez GRANDE pour porter le "
	"personnage (son dos est environ deux fois plus large que les épaules du personnage)")

SURF = """{ident} — sprites de combat de Kanto 2026 (jeu 2D HD) : {qui} sur sa monture de Surf, vu DE DOS, au premier plan d'un combat en mer. Images jointes : IMAGE 1 = les sprites de combat VALIDÉS du héros de dos (à gauche debout prêt, à droite pose de lancer) : CIBLE EXACTE du rendu, de la vue de dos de trois-quarts et du geste de lancer ; IMAGE 2 = la monture de Surf du jeu (planche du monde, 4 directions) : son design fait foi ; IMAGE 3 = {ref3}{ref4}.

PERSONNAGE : {perso}
MONTURE : {monture}.

À FAIRE : UNE image PAYSAGE 1536 × 1024 avec DEUX poses côte à côte, bien séparées (au moins 100 px de vide entre elles), grandes (environ 760 px de haut chacune, du haut de la casquette à la ligne d'eau), rien de coupé par les bords. Dans les deux poses, la même vue que IMAGE 1 : {qui_court} DE DOS, de trois-quarts, tourné vers la DROITE et le haut de l'image (l'adversaire est en haut à droite) ; {qui_court} est ASSIS À CALIFOURCHON sur le dos de la monture, les jambes de part et d'autre de son corps ; la monture, vue de dos de trois-quarts, nage vers la droite et le haut de l'image : on voit son dos rond et le haut de sa tête tournée vers la droite, l'arrière de son corps et sa queue s'enfoncent dans l'eau ; seul le haut de son corps émerge.
- À GAUCHE : pose PRÊTE : une main posée à plat sur le dos de la monture, l'autre poing serré devant la poitrine, le buste tourné vers la droite, la tête vers l'adversaire.
- À DROITE : pose de LANCER comme IMAGE 1 à droite : toujours assis sur la monture, le buste qui pivote, le bras droit tendu loin vers la DROITE et vers le haut, main ouverte doigts écartés, la Ball VIENT DE PARTIR (main vide, pas de Ball dessinée), l'autre main agrippée au dos de la monture.
Même personnage, même tenue, même monture et mêmes proportions dans les deux poses. Mains à cinq doigts correctes.

{eau}

{style}

{fond}
"""

HEROS = ("le HÉROS du jeu, EXACTEMENT celui de IMAGE 1 (même casquette rouge à visière blanche, mêmes "
	"cheveux bruns, même t-shirt blanc à manches rouges, même sac à dos jaune et bleu marine, même jean "
	"bleu, mêmes baskets rouges et blanches)")
JOUEUSE = ("la JOUEUSE du jeu (fille d'environ 11 ans, IMAGE 3 : son apparence fait foi) : longs cheveux "
	"CHÂTAINS ondulés jusqu'aux épaules qui dépassent de la casquette, CASQUETTE ROUGE à visière BLANCHE "
	"et rond blanc, T-SHIRT BLANC, SAC À DOS JAUNE et BLEU MARINE, SHORT EN JEAN, chaussettes blanches, "
	"baskets ROUGES et BLANCHES ; même gabarit que le héros d'IMAGE 4, même main")

NAGEURS = """ES_NAGEURS_EAU — sprites de combat de Kanto 2026 (jeu 2D HD), DEUX classes de Dresseurs DANS L'EAU (combat en mer). Images jointes : IMAGE 1 = le NAGEUR, sprites de combat VALIDÉS (à gauche debout prêt, à droite pose de lancer) : CIBLE EXACTE du rendu, du personnage et du geste ; IMAGE 2 = la NAGEUSE, sprites de combat VALIDÉS (même chose) ; IMAGE 3 = les mêmes personnages dans l'eau dans le monde du jeu (petite planche) : ils nagent, l'eau coupe le corps.

PERSONNAGE DU HAUT : le NAGEUR d'IMAGE 1 (homme d'environ 20 ans, athlétique, bronzé, cheveux CHÂTAINS en bataille mouillés, LUNETTES DE NATATION bleues relevées sur le front, torse nu ; pas de serviette dans l'eau).
PERSONNAGE DU BAS : la NAGEUSE d'IMAGE 2 (jeune femme d'environ 19 ans, cheveux CHÂTAINS en chignon haut, LUNETTES DE NATATION bleues relevées sur le front, MAILLOT une pièce TURQUOISE ; pas de paréo dans l'eau).

À FAIRE : UNE image PORTRAIT 1024 × 1536 en DEUX RANGÉES séparées par une large bande vide (au moins 120 px) : le personnage du HAUT dans la moitié haute, celui du BAS dans la moitié basse. Dans chaque rangée, DEUX poses du même personnage côte à côte, bien séparées (au moins 80 px de vide), rien de coupé par les bords. Le personnage est DANS L'EAU PROFONDE, il nage sur place : l'eau le coupe à hauteur du NOMBRIL (on voit la tête, les épaules, les bras et le torse) ; la partie visible fait environ 400 px de haut, du haut de la tête à la ligne d'eau, à la même taille réelle qu'IMAGES 1 et 2.
- À GAUCHE : pose PRÊTE : de trois-quarts face, tourné vers la GAUCHE de l'image, une main qui écarte l'eau, l'autre poing serré levé, sourire sportif.
- À DROITE : pose de LANCER comme IMAGE 1 à droite : de trois-quarts face tourné vers la gauche, le buste qui pivote, un bras tendu loin vers la GAUCHE à hauteur d'épaule, main ouverte doigts écartés, la Ball VIENT DE PARTIR (main vide, pas de Ball dessinée), l'autre bras en arrière qui éclabousse un peu.
Mains à cinq doigts correctes, même personnage et mêmes proportions dans les deux poses d'une rangée.

{eau}

STYLE (impératif) : exactement la main d'IMAGES 1 et 2 : illustration 2D HD « anime peint », contours fins et doux brun foncé (jamais de trait noir épais), aplats peints avec ombres douces, légère granularité de pinceau, proportions réalistes-stylisées (PAS chibi), lumière neutre et douce venant de la gauche.

{fond}
"""

# Feuilles du monde (modèle des PNJ du monde, série 25 ; 128 px comme le Loubard).
MONDE_TENUES = {
	"karateka": ("PNJ_KARATEKA", "karateka",
		"un KARATÉKA d'environ 28 ans, très MUSCLÉ et carré (épaules larges, gros bras), air décidé : "
		"cheveux NOIRS courts en épis, BANDEAU BLANC noué au front dont les pans flottent derrière la tête, "
		"KARATÉGI BLANC cassé un peu ouvert sur le torse, manches au coude, CEINTURE NOIRE nouée devant, "
		"pantalon de karatégi blanc, PIEDS NUS. Taille d'un adulte, plus large que les autres PNJ. "
		"Différent du héros et du loubard joint (ni crâne rasé, ni barbe, ni gilet de cuir) ; aucun "
		"texte, aucun écusson, aucune arme."),
	"maitre_dojo": ("PNJ_MAITRE_DOJO", "maitre_dojo",
		"le MAÎTRE DU DOJO de Safrania, environ 50 ans, TRAPU, très fort et digne : CRÂNE RASÉ, épaisse "
		"MOUSTACHE et BARBICHE GRISES, sourcils gris broussailleux, KARATÉGI BLANC à REVERS NOIRS, vieille "
		"CEINTURE NOIRE effilochée, pantalon de karatégi blanc, PIEDS NUS. Taille d'un adulte, plus large "
		"que les autres PNJ. Différent du héros, du loubard joint (ni barbe noire, ni gilet de cuir) et du "
		"karatéka (ni bandeau, ni cheveux) ; aucun texte, aucune arme."),
}

IMAGES = ("heros_surf", "joueuse_surf", "nageurs_eau", "karateka_monde", "maitre_dojo_monde")


def _cote(fichiers: list[Path], ecart: int = 60) -> Image.Image:
	ims = [Image.open(f).convert("RGBA") for f in fichiers]
	h = max(i.height for i in ims)
	t = Image.new("RGBA", (sum(i.width for i in ims) + ecart * (len(ims) - 1), h), (0, 0, 0, 0))
	x = 0
	for i in ims:
		t.alpha_composite(i, (x, h - i.height))
		x += i.width + ecart
	return t


def refs() -> None:
	FI.mkdir(parents=True, exist_ok=True)
	_cote([ed.SPR / "dos_hero.webp", ed.SPR / "dos_hero_lancer.webp"]).save(FI / "ref_dos_hero.png")
	for c in ("nageur", "nageuse", "karateka", "maitre_dojo"):
		_cote([ed.SPR / f"{c}.webp", ed.SPR / f"{c}_lancer.webp"]).save(FI / f"ref_{c}_poses.png")
	joueuse = Image.open(MONDE / "joueuse_portrait.png").convert("RGBA")
	joueuse.save(FI / "ref_joueuse.png")
	# Planche du Loubard (adulte costaud du monde, même main) agrandie à la taille d'une planche Codex.
	lou = Image.open(MONDE / "loubard_sheet.png").convert("RGBA")
	lou.resize((lou.width * 3, lou.height * 3), Image.LANCZOS).save(FI / "ref_loubard_monde.png")


def _surf(ident: str, qui: str, qui_court: str, perso: str, ref3: str, ref4: str) -> str:
	return SURF.format(ident=ident, qui=qui, qui_court=qui_court, perso=perso, monture=MONTURE,
		ref3=ref3, ref4=ref4, eau=EAU, style=STYLE, fond=FOND)


def _marche(nom: str, combat: str, tenue: str) -> str:
	ref = (" ; LOUBARD (planche jointe 2) = même main et même finesse pour un adulte costaud (à NE PAS "
		f"copier : autre visage, autre tenue) ; {combat.upper()}_COMBAT (image jointe 3) = le MÊME "
		"personnage peint pour l'écran de combat : sa tenue, sa coiffure, sa carrure et ses couleurs font "
		"foi (son rendu détaillé est à NE PAS copier : dans le monde il est chibi comme le héros)")
	return MODELE_MARCHE.format(ident=nom, ref=ref, tenue=tenue) + INTERDITS_PNJ + "\n"


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	textes = {
		"heros_surf": _surf("ES_HEROS_SURF", "le HÉROS (le joueur)", "le héros", HEROS,
			"le héros sur la monture dans le monde du jeu (petite planche) : la posture assise à "
			"califourchon fait foi", ""),
		"joueuse_surf": _surf("ES_JOUEUSE_SURF", "la JOUEUSE (le joueur, apparence féminine)", "la joueuse",
			JOUEUSE, "la JOUEUSE en pied (portrait validé) : son visage, ses cheveux et sa tenue font foi",
			" ; IMAGE 4 = le HÉROS sur la même monture, sprites de combat de dos (prête et lancer) : CIBLE "
			"EXACTE de la composition, de la monture, de la taille et des deux poses, à reprendre à "
			"l'identique avec la joueuse à la place du héros"),
		"nageurs_eau": NAGEURS.format(eau=EAU, fond=FOND),
	}
	for c, (nom, combat, tenue) in MONDE_TENUES.items():
		textes[f"{c}_monde"] = _marche(nom, combat, tenue)
	for ident, texte in textes.items():
		(PROMPTS / f"{ident}.txt").write_text(texte, encoding="utf-8")


def jointes(ident: str) -> list[Path]:
	return {
		"heros_surf": [FI / "ref_dos_hero.png", FI / "SURF_MONTURE_NE_r1.png", FI / "HEROS_SURF_NE_r1.png"],
		"joueuse_surf": [FI / "ref_dos_hero.png", FI / "SURF_MONTURE_NE_r1.png", FI / "ref_joueuse.png",
			ed.ART / "ES_heros_surf_r1.png"],
		"nageurs_eau": [FI / "ref_nageur_poses.png", FI / "ref_nageuse_poses.png",
			FI / "PNJ_NAGEUR_EAU_NE_r1.png"],
		"karateka_monde": [FI / "PERSO_P2_PEINT_r1.png", FI / "ref_loubard_monde.png",
			FI / "ref_karateka_poses.png"],
		"maitre_dojo_monde": [FI / "PERSO_P2_PEINT_r1.png", FI / "ref_loubard_monde.png",
			FI / "ref_maitre_dojo_poses.png"],
	}[ident]


def generer(ident: str, rev: str = "1") -> int:
	cmd = [str(RACINE / "tools" / "art" / "generer.sh"), f"ES_{ident}_r{rev}",
		str(PROMPTS / f"{ident}.txt"), *[str(p) for p in jointes(ident)]]
	return subprocess.call(cmd, cwd=RACINE)


# --- Export --------------------------------------------------------------------------------------

# Taille de la partie visible par rapport à la classe debout [D] : nageur coupé au nombril
# (≈ 0,45 de la hauteur debout) ; joueur assis sur la monture, casquette → ligne d'eau (≈ 0,9 du
# joueur debout).
PART_NAGEUR = 0.45
SURF_JOUEUR = 0.9
TOILE_SURF = (960, 960)


def _visible(toile: Image.Image) -> int:
	"""Hauteur visible comme le jeu la mesure (TrainerIntroStage.visible_height) : du haut des
	pixels opaques au bas de la toile."""
	return toile.height - toile.getbbox()[1]


def main(lancer: Image.Image, vers_la_droite: bool) -> tuple[float, float]:
	"""Bout des doigts du bras tendu (pixel opaque le plus à gauche, ou à droite pour le joueur,
	dans la moitié haute) + décalage de la règle des grands combats (vers la paume), en part de la
	hauteur VISIBLE depuis le milieu de la ligne d'eau (centre bas de la toile)."""
	a = np.asarray(lancer)[..., 3] > 96
	haut = int(np.where(a.any(1))[0][0])
	a[haut + int((a.shape[0] - haut) * 0.55):] = False
	xs = np.where(a.any(0))[0]
	x0 = xs[-1] - 5 if vers_la_droite else xs[0]
	ys = np.where(a[:, x0:x0 + 6].any(1))[0]
	hv = _visible(lancer)
	dx = (x0 + (5 if vers_la_droite else 0) - lancer.width / 2) / hv
	dx += -eo.MAIN_DECALAGE[0] if vers_la_droite else eo.MAIN_DECALAGE[0]
	return (round(dx, 3), round((ys.mean() - lancer.height) / hv + eo.MAIN_DECALAGE[1], 3))


def _deux_poses(chemin: Path) -> list[Image.Image]:
	im = ed._nettoyer(Image.open(chemin).convert("RGBA"))
	return eo._poses_rangee(im)


def _separer_eau(rangee: Image.Image) -> list[Image.Image]:
	"""Deux poses reliées par des gouttes ou dont le bras passe au-dessus de l'autre : chaque pose =
	composante connexe qui contient la colonne la plus pleine de sa moitié de l'image."""
	import entree_grands_combats as eg  # noqa: E402
	arr = np.asarray(rangee)
	a = arr[..., 3] > 96
	sorties = []
	for x0, x1 in ((0, a.shape[1] // 2), (a.shape[1] // 2, a.shape[1])):
		x = x0 + int(np.argmax(a[:, x0:x1].sum(0)))
		ys = np.where(a[:, x])[0]
		c = eg._composante(arr[..., 3] > 8, int(ys[len(ys) // 2]), x)
		p = arr.copy()
		p[..., 3] = np.where(c, p[..., 3], 0)
		im = Image.fromarray(p)
		sorties.append(im.crop(im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()))
	return sorties


def exporter() -> dict:
	"""Sprites de combat → assets/sprites/trainers/battle/ ; renvoie le bloc « surf » de
	trainer_intro.json (tailles et mains)."""
	intro = json.loads(INTRO.read_text(encoding="utf-8"))
	bloc: dict = {"suffix": "_surf", "player": {}, "classes": {}}
	for ident, look in (("heros_surf", "hero"), ("joueuse_surf", "heroine")):
		p = ed.ART / f"ES_{ident}_r1.png"
		if not p.exists():
			continue
		poses = _deux_poses(p)
		print(ident, [i.size for i in poses])
		debout, lancer = ed.poses_en_toile(poses[0], poses[-1], TOILE_SURF, 16)
		ed._webp(debout, ed.SPR / f"dos_{look}_surf.webp")
		ed._webp(lancer, ed.SPR / f"dos_{look}_surf_lancer.webp")
		if look == "hero":
			bloc["player"] = {"scale": round(intro.get("player_scale", 1.0) * SURF_JOUEUR, 3),
				"hand": list(main(lancer, True))}
	p = ed.ART / "ES_nageurs_eau_r1.png"
	if p.exists():
		im = ed._nettoyer(Image.open(p).convert("RGBA"))
		masque = np.asarray(im)[..., 3] > 96
		rangees = [im.crop((0, y0, im.width, y1)) for y0, y1 in eo._rangees(masque)]
		for classe, rangee in zip(("nageur", "nageuse"), rangees):
			poses = _separer_eau(rangee)
			print(classe, [i.size for i in poses])
			debout, lancer = ed.poses_en_toile(poses[0], poses[-1], (512, 768), 16)
			ed._webp(debout, ed.SPR / f"{classe}_surf.webp")
			ed._webp(lancer, ed.SPR / f"{classe}_surf_lancer.webp")
			bloc["classes"][classe] = {
				"scale": round(intro["classes"][classe]["scale"] * PART_NAGEUR, 3),
				"hand": list(main(lancer, False))}
	return bloc


def ecrire_surf(bloc: dict) -> None:
	"""Bloc « surf » de trainer_intro.json, inséré (ou remplacé) avant « classes »."""
	lignes = INTRO.read_text(encoding="utf-8").split("\n")
	lignes = [ligne for ligne in lignes if not ligne.startswith('\t"surf": ')]
	i = next(k for k, ligne in enumerate(lignes) if ligne.startswith('\t"classes": '))
	lignes.insert(i, f'\t"surf": {json.dumps(bloc, ensure_ascii=False)},')
	INTRO.write_text("\n".join(lignes), encoding="utf-8")


# --- Feuilles du monde -------------------------------------------------------------------------

## (identifiant de planche, apparence du monde, image Codex) ; 128 px comme le Loubard [D].
MONDE_FEUILLES = [("karateka", "blackbelt", "ES_karateka_monde_r1.png"),
	("maitre_dojo", "karate_master", "ES_maitre_dojo_monde_r1.png")]


def monde() -> None:
	"""Entrées du manifeste (idempotent) puis découpe de ces planches seulement (catalogue gardé) ;
	ensuite : `godot --headless --path . --script tools/build_character_frames.gd`."""
	import preparer  # noqa: E402
	chemin = Path(__file__).resolve().parent / "manifeste.json"
	m = json.loads(chemin.read_text())
	entrees = [{"id": ident, "source": source,
		"sortie": f"assets/sprites/characters/painted/{ident}_sheet.png", "hauteur": 128,
		"nettoyer": True, "note": f"finitions de l'entrée des Dresseurs (fiche §13) ; {look}"}
		for ident, look, source in MONDE_FEUILLES]
	connus = {e["id"] for e in m["personnages"]}
	m["personnages"] += [e for e in entrees if e["id"] not in connus]
	chemin.write_text(json.dumps(m, ensure_ascii=False, indent=1) + "\n")
	sous = {k: ([] if isinstance(v, list) else v) for k, v in m.items()}
	sous["personnages"] = entrees
	p = preparer.Preparateur(sous, ed.ART)
	cat = RACINE / "assets/world/catalogue.json"
	p.catalogue = json.loads(cat.read_text())
	p.personnages()
	cat.write_text(json.dumps(p.catalogue, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
	act = sys.argv[1]
	if act == "refs":
		refs()
	elif act == "prompts":
		prompts()
	elif act == "generer":
		sys.exit(generer(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "1"))
	elif act == "exporter":
		b = exporter()
		ecrire_surf(b)
		print(json.dumps(b))
	elif act == "monde":
		monde()
