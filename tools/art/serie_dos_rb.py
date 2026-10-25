#!/usr/bin/env python3
"""Série « dos RB » — DAF.1, dos de combat en cadrage B « façon Rouge/Bleu » (décision de Kevin, 2026-10-25,
`docs/design/fiches-assets/dos-cadrage-rb/README.md`) : dos de trois quarts, en légère plongée, coupés net par
le bord BAS de l'image. Lus par `BattleArt` en priorité (`dos_rb_NNN.png` > `dos_ia` > `dos3d` > provisoire) et
posés par `BattleLayout` sur le bord bas de l'écran, sans enfoncement.

Périmètre : les 70 espèces sans dos peint (`docs/design/inventaire-art.md` §3) ; les 81 dos « corps entier » de
`main` restent, recadrés par le code (Kevin : « refaire en plongée seulement ceux qui rendent mal, au fil des
lots » : on les ajoute à ESPECES le moment venu).

Prompts : gabarit de l'essai du 2026-10-24 (`tools/art/prompts/dos_rb/`), sujet DÉCRIT SANS NOMMER l'espèce
(leçon d'Évoli). Règle de Kevin : AVEC image jointe d'abord, puis SANS.
  r1 : artwork officiel de face joint ;  r2 : aucune image ;  r3 : aucune image, « design original ».
Les refus sont consignés dans `$ART/refus_serie_dos_rb.log` ; les espèces refusées partout vont à Kevin (app
ChatGPT, `--ajouter`).

Usage :
  tools/art/serie_dos_rb.py --prompts              écrit les prompts versionnés (sans Codex)
  tools/art/serie_dos_rb.py --liste                espèces et état de chaque essai
  tools/art/serie_dos_rb.py [IDENT ...]            génère avec Codex (3 à la fois), r1 à r3 jusqu'au premier réussi
  tools/art/serie_dos_rb.py --preparer             essais retenus -> $ART/serie_dos_rb/dos_rb_NNN.png
  tools/art/serie_dos_rb.py --contact              planche $ART/SERIE_DOS_RB_CONTACT.png (face | dos RB)
  tools/art/serie_dos_rb.py --integrer             dos préparés -> assets/sprites/pokemon/dos/
  tools/art/serie_dos_rb.py --ajouter IDENT FICHIER  dos fait avec ChatGPT : dépose, prépare, intègre, planche
"""
from __future__ import annotations

import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[1]
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
SORTIE = ART / "serie_dos_rb"
PROMPTS = ICI / "prompts" / "serie_dos_rb"
OFFICIEL = RACINE / "assets/sprites/pokemon/official"
DOS_JEU = RACINE / "assets/sprites/pokemon/dos"
JOURNAL = ART / "refus_serie_dos_rb.log"

## (identifiant, n° du Pokédex, nom français pour la planche, sujet décrit sans le nommer).
ESPECES = [
	# --- refusés par Codex en corps entier (lot 2, série 28) : retentés en cadrage B ---
	("TORTANK", 9, "Tortank", "grande tortue bipède massive à peau bleue, lourde CARAPACE brune bordée de crème sur "
		"le dos, d'où sortent DEUX GROS CANONS d'eau gris, un au-dessus de chaque épaule, oreilles courtes"),
	("RONDOUDOU", 39, "Rondoudou", "petite créature toute RONDE comme un ballon, peau ROSE, grandes oreilles "
		"triangulaires à l'intérieur noir, une MÈCHE de cheveux bouclée sur le dessus de la tête, petits bras"),
	("KADABRA", 64, "Kadabra", "humanoïde JAUNE mince et debout, PLASTRON brun en forme d'armure sur le torse et "
		"les épaules, grandes oreilles pointues, longue queue épaisse jaune marquée d'une bande brune, tenant une "
		"CUILLÈRE d'argent dans une main"),
	("STAROSS", 121, "Staross", "créature en forme de DOUBLE ÉTOILE de mer violette à dix branches (deux étoiles "
		"superposées décalées), surface lisse, un JOYAU ROUGE rond au centre (de dos, à peine visible)"),
	("LEVIATOR", 130, "Léviator", "immense serpent de mer au corps long et sinueux BLEU, ventre crème, crête "
		"dorsale bleu foncé, grande tête au front bombé portant de courts barbillons blancs"),
	("VOLTALI", 135, "Voltali", "quadrupède fin au pelage JAUNE vif tout HÉRISSÉ en pointes acérées, comme des "
		"aiguilles, collerette de pointes blanches autour du cou, longues oreilles pointues"),
	("MAGMAR", 126, "Magmar", "bipède au corps JAUNE couvert de motifs de FLAMMES orange-rouge, petite tête "
		"au bec épais, dos marqué de bosses rondes, longue queue terminée par une FLAMME"),
	("PTERA", 142, "Ptéra", "reptile volant préhistorique à peau GRIS-VIOLET, deux GRANDES AILES membraneuses "
		"déployées, longue queue pointue en flèche, tête au museau allongé hérissé de crocs"),
	# --- conditionnels du lot 2 ---
	("OSSATUEUR", 105, "Ossatueur", "petit bipède BRUN trapu, la tête couverte d'un CRÂNE blanc porté comme un "
		"casque, tenant un gros OS blanc dans une main, courte queue"),
	("RHINOCORNE", 111, "Rhinocorne", "quadrupède massif à peau GRISE, grosse CORNE sur le museau, dos plaqué de "
		"plaques rugueuses, queue courte"),
	("SAQUEDENEU", 114, "Saquedeneu", "masse de LIANES BLEU FONCÉ enchevêtrées qui cachent tout le corps, deux "
		"petits pieds rouges dessous"),
	("KANGOUREX", 115, "Kangourex", "grand bipède BRUN à ventre crème, courts bras, fortes jambes, longue queue "
		"épaisse, une poche ventrale avec un petit"),
	# --- ajoutées aux données depuis le lot 2 ---
	("MIMITOSS", 48, "Mimitoss", "insecte rond et dodu au pelage VIOLET duveteux, deux petites antennes, gros "
		"yeux composés rouges, petites pattes"),
	("AEROMITE", 49, "Aéromite", "papillon de nuit LAVANDE aux quatre grandes AILES violet pâle couvertes de "
		"motifs de taches sombres, corps duveteux, antennes"),
	("PSYKOKWAK", 54, "Psykokwak", "canard JAUNE bipède dodu au bec crème large, trois petits cheveux noirs sur "
		"le dessus de la tête, se tenant la tête dans les mains"),
	("AKWAKWAK", 55, "Akwakwak", "grand canard humanoïde BLEU élancé au bec crème, un JOYAU rouge sur le front, "
		"mains et pieds palmés, longue queue fine"),
	("PTITARD", 60, "Ptitard", "petit têtard BLEU tout rond, ventre blanc marqué d'une SPIRALE noire, deux "
		"petits pieds, longue queue plate translucide"),
	("TETARTE", 61, "Têtarte", "créature ronde BLEUE sans cou, ventre blanc marqué d'une SPIRALE noire, bras "
		"blancs gantés, deux jambes courtes"),
	("TARTARD", 62, "Tartard", "créature ronde et musclée BLEU FONCÉ, ventre blanc marqué d'une SPIRALE noire, "
		"gros bras puissants gantés de blanc, fortes jambes"),
	("MACHOPEUR", 67, "Machopeur", "humanoïde très musclé à peau GRIS-BLEU, crête de trois arêtes sur le crâne, "
		"porte une CEINTURE de lutteur dorée, bras épais"),
	("TENTACRUEL", 73, "Tentacruel", "grande méduse au dôme BLEU translucide portant deux grosses GEMMES rouges "
		"et des pointes, une forêt de longs TENTACULES bleus dessous"),
	("PONYTA", 77, "Ponyta", "jeune cheval au pelage crème, CRINIÈRE et QUEUE de FLAMMES orange et jaunes, "
		"sabots gris"),
	("GALOPA", 78, "Galopa", "cheval élancé au pelage crème, longue CRINIÈRE et longue QUEUE de FLAMMES, une "
		"CORNE droite argentée sur le front"),
	("RAMOLOSS", 79, "Ramoloss", "quadrupède ROSE pataud au regard endormi, grosse tête ronde, ventre crème, "
		"longue queue rose terminée par une pointe blanche"),
	("FLAGADOSS", 80, "Flagadoss", "bipède ROSE pataud, sa queue serrée dans la gueule d'un gros COQUILLAGE en "
		"spirale gris qui y reste accroché"),
	("CANARTICHO", 83, "Canarticho", "canard sauvage au plumage BRUN, sourcils sombres, tenant dans son aile "
		"une longue tige de POIREAU vert"),
	("DODUO", 84, "Doduo", "oiseau coureur BRUN sans ailes à DEUX TÊTES sur deux longs cous, longues pattes "
		"fines"),
	("DODRIO", 85, "Dodrio", "oiseau coureur BRUN et noir sans ailes à TROIS TÊTES sur trois longs cous, "
		"longues pattes fines"),
	("OTARIA", 86, "Otaria", "phoque BLANC dodu au museau court, une petite CORNE sur la tête, nageoires, queue "
		"fine terminée en nageoire bleu pâle"),
	("LAMANTINE", 87, "Lamantine", "grand lion de mer BLANC élancé, une CORNE sur la tête, longue queue "
		"terminée en nageoire, nageoires latérales"),
	("TADMORV", 88, "Tadmorv", "flaque de BOUE VIOLETTE gluante et vivante, deux bras dégoulinants"),
	("GROTADMORV", 89, "Grotadmorv", "grosse masse de BOUE VIOLETTE gluante qui dégouline, bras épais et "
		"coulants"),
	("CRUSTABRI", 91, "Crustabri", "gros COQUILLAGE bivalve noir-violet hérissé de longues pointes, coque "
		"fermée bordée de crêtes"),
	("KRABBY", 98, "Krabby", "petit crabe ROUGE-ORANGE au dessous crème, deux PINCES, la droite plus grosse, "
		"deux pointes sur la tête"),
	("KRABBOSS", 99, "Krabboss", "grand crabe ROUGE-ORANGE au dessous crème, une PINCE ÉNORME, carapace "
		"hérissée de petites pointes"),
	("ELECTRODE", 101, "Électrode", "grosse BOULE parfaite à moitié ROUGE en haut, moitié BLANCHE en bas, "
		"surface lisse et brillante"),
	("SMOGOGO", 110, "Smogogo", "deux sphères VIOLETTES soudées, une grande et une petite, couvertes de "
		"bosses en cratère d'où sort de la fumée, motif de crâne beige"),
	("HYPOCEAN", 117, "Hypocéan", "hippocampe BLEU hérissé de nageoires pointues comme des épines, long museau "
		"tubulaire, queue enroulée"),
	("POISSOROY", 119, "Poissoroy", "grand poisson ORANGE et blanc aux longues nageoires en voile, une CORNE "
		"blanche sur le front, lèvres épaisses"),
	("AMONITA", 138, "Amonita", "petit mollusque fossile BLEU CLAIR dans une COQUILLE en spirale beige, "
		"tentacules dessous"),
	("AMONISTAR", 139, "Amonistar", "mollusque fossile BLEU dans une grande COQUILLE en spirale beige hérissée "
		"de pointes, tentacules dessous"),
	("KABUTO", 140, "Kabuto", "petit fossile vivant à CARAPACE brune bombée en dôme, petites pattes "
		"dessous"),
	("KABUTOPS", 141, "Kabutops", "humanoïde fossile BRUN à carapace segmentée, deux bras terminés en "
		"FAUX tranchantes"),
	("RONFLEX", 143, "Ronflex", "énorme créature ronde au corps BLEU-VERT foncé et au ventre crème, petites "
		"oreilles pointues, gros pieds"),
	("ARTIKODIN", 144, "Artikodin", "grand oiseau majestueux BLEU GLACE aux longues ailes déployées, longue "
		"queue de plumes ondulantes, petite crête"),
	# --- pas encore dans les données (J23 à J32) ---
	("ALAKAZAM", 65, "Alakazam", "humanoïde JAUNE mince à longue MOUSTACHE, plastron brun sur le torse, grandes "
		"oreilles pointues, une CUILLÈRE d'argent dans chaque main"),
	("MACKOGNEUR", 68, "Mackogneur", "humanoïde musclé à peau GRIS-BLEU et à QUATRE BRAS puissants, crête de "
		"trois arêtes sur le crâne, ceinture de lutteur dorée"),
	("ECTOPLASMA", 94, "Ectoplasma", "spectre rond et trapu VIOLET SOMBRE, dos hérissé de petites pointes, "
		"courtes jambes, petits bras"),
	("NOADKOKO", 103, "Noadkoko", "grand arbre-palmier vivant au tronc brun écailleux, petits pieds, plusieurs "
		"têtes rondes parmi de grandes feuilles vertes de palmier"),
	("KICKLEE", 106, "Kicklee", "humanoïde BRUN sans tête distincte, corps ovale, longues jambes puissantes à "
		"ressort, bras fins"),
	("TYGNON", 107, "Tygnon", "humanoïde BRUN au corps ovale vêtu d'une sorte de tunique, bras terminés par de "
		"gros GANTS de boxe rouges"),
	("EXCELANGUE", 108, "Excelangue", "bipède ROSE dodu au ventre rayé crème, très longue LANGUE, courte queue "
		"épaisse"),
	("RHINOFEROS", 112, "Rhinoféros", "bipède massif à peau GRISE caparaçonnée, une grosse CORNE en vrille sur "
		"le museau, longue queue épaisse"),
	("LEVEINARD", 113, "Leveinard", "créature ROSE tout ovale et douce, petites mèches sur les côtés de la tête, "
		"un OEUF blanc dans une poche du ventre, petite queue"),
	("M_MIME", 122, "M. Mime", "humanoïde au corps ROSE et blanc, grosses mains blanches gantées, cheveux "
		"bleus en pointes, ronds rouges aux épaules"),
	("INSECATEUR", 123, "Insécateur", "grand insecte VERT bipède aux bras terminés par de grandes FAUX "
		"tranchantes, petites ailes translucides sur le dos"),
	("LIPPOUTOU", 124, "Lippoutou", "humanoïde en longue robe ROUGE, longue chevelure BLONDE qui descend dans "
		"le dos, bras violets"),
	("ELEKTEK", 125, "Élektek", "humanoïde JAUNE rayé de bandes NOIRES, deux antennes sur la tête, bras "
		"épais, queue courte"),
	("SCARABRUTE", 127, "Scarabrute", "grand coléoptère BRUN bipède portant sur la tête deux grandes CORNES-"
		"pinces hérissées de pointes"),
	("TAUROS", 128, "Tauros", "taureau au pelage BRUN, crinière brun foncé, deux cornes recourbées, TROIS "
		"QUEUES terminées en touffe"),
	("LOKHLASS", 131, "Lokhlass", "grande créature marine BLEUE au ventre crème, une lourde CARAPACE grise "
		"hérissée de bosses sur le dos, long cou, tête à petite corne"),
	("METAMORPH", 132, "Métamorph", "petite masse VIOLET PÂLE molle et informe comme une gelée, deux petits "
		"bras"),
	("PORYGON", 137, "Porygon", "créature faite de polygones anguleux ROSES et BLEUS, comme un modèle en 3D "
		"simplifié, queue anguleuse"),
	("ELECTHOR", 145, "Électhor", "grand oiseau JAUNE aux longues ailes hérissées de plumes en ÉCLAIRS "
		"pointus, plumes noires au bout, crête en pointes"),
	("SULFURA", 146, "Sulfura", "grand oiseau ORANGE-JAUNE aux longues ailes ardentes, ailes, crête et queue "
		"faites de FLAMMES"),
	("MINIDRACO", 147, "Minidraco", "petit serpent-dragon BLEU au long corps sinueux et au ventre blanc, petites "
		"ailes blanches en éventail sur les côtés de la tête"),
	("DRACO", 148, "Draco", "long dragon serpentin BLEU élégant au ventre blanc, petites ailes blanches sur la "
		"tête, une corne blanche, deux perles bleues sur le cou et la queue"),
	("DRACOLOSSE", 149, "Dracolosse", "grand dragon bipède massif ORANGE au ventre crème, petites ailes vert-"
		"bleu dans le dos, deux antennes sur la tête, queue épaisse"),
	("MEWTWO", 150, "Mewtwo", "humanoïde félin à peau GRIS-BLANC et au ventre violet, tube reliant l'arrière "
		"du crâne au dos, longue queue épaisse violette"),
	("MEW", 151, "Mew", "petite créature féline ROSE PÂLE flottante, grosse tête aux oreilles rondes, très "
		"longue queue fine terminée par un renflement"),
]

DOS_RB = """POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel, non distribué). {nom}

{ancres}

SUJET : {sujet}.

VUE : de DOS, de trois quarts, en LÉGÈRE PLONGÉE : la caméra est juste derrière et un peu au-dessus de l'épaule gauche de la créature, comme le dresseur qui se tient derrière elle. Elle regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant). Aucun œil, aucune bouche, aucun visage dessiné sur le dos ou la nuque : le visage est tourné vers l'avant, hors de vue (au plus, le bout du museau ou la joue en profil perdu).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire de face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun fond coloré, aucun sol, aucune ombre portée.
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage.
CADRAGE : image CARRÉE 1024 × 1024, cadrage SERRÉ comme dans les jeux de combat des années 90 vus de dos : on voit la tête et le haut du corps, GRANDS ; le bas du corps est franchement COUPÉ par le bord BAS de l'image (environ le tiers inférieur hors champ, la coupe est nette, sans fondu). Rien n'est coupé en haut, à gauche ni à droite. Une seule image fixe."""

NOM = ("La créature est un animal fantastique de jeu vidéo.",
	"La créature est un animal fantastique de jeu vidéo.",
	"La créature est un personnage original d'un jeu vidéo d'aventure, inspiré des animaux réels.")
ANCRES = ("Image jointe : une illustration de face de la créature, comme référence de forme, de couleurs et de "
	"style seulement (on veut l'arrière).", "Aucune image jointe.", "Aucune image jointe.")
ESSAIS = (1, 2, 3)

## Essais retenus après relecture de la planche (clé : identifiant, valeur : nom de l'essai).
## Par défaut : le plus petit r disponible.
RETENUS: dict[str, str] = {}


def jointes(num: int, r: int) -> list[Path]:
	return [OFFICIEL / f"{num:03d}.png"] if r == 1 else []


def images() -> list[dict]:
	liste = []
	for ident, num, _fr, sujet in ESPECES:
		for r in ESSAIS:
			liste.append({"ident": ident, "num": num, "r": r, "nom": f"DOSRB_{ident}_r{r}",
				"fichier": PROMPTS / f"DOSRB_{ident}_r{r}.txt", "jointes": jointes(num, r),
				"texte": DOS_RB.format(nom=NOM[r - 1], ancres=ANCRES[r - 1], sujet=sujet)})
	return liste


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for im in images():
		im["fichier"].write_text(im["texte"] + "\n", encoding="utf-8")
	print(len(images()), "prompts dans", PROMPTS)


def _journal(ligne: str) -> None:
	ART.mkdir(parents=True, exist_ok=True)
	with JOURNAL.open("a", encoding="utf-8") as f:
		f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + ligne + "\n")


def _essai(im: dict) -> bool:
	if (ART / f"{im['nom']}.png").exists():
		return True
	env = dict(os.environ, CODEX=os.environ.get("CODEX", str(Path.home() / ".local/bin/codex")))
	cmd = [str(ICI / "generer.sh"), im["nom"], str(im["fichier"])] + [str(j) for j in im["jointes"]]
	p = subprocess.run(cmd, cwd=RACINE, env=env, capture_output=True, text=True)
	ok = p.returncode == 0 and (ART / f"{im['nom']}.png").exists()
	if not ok:
		cause = "moderation_blocked" if "moderation_blocked" in p.stderr else p.stderr.strip()[-160:]
		_journal(f"REFUS {im['nom']} ({'avec' if im['jointes'] else 'sans'} jointe) : {cause}")
	print(("OK    " if ok else "REFUS "), im["nom"], flush=True)
	return ok


def _espece(ident: str) -> bool:
	return any(_essai(im) for im in images() if im["ident"] == ident)


def generer(noms: list[str]) -> None:
	prompts()
	idents = [e[0] for e in ESPECES if not noms or e[0] in noms]
	with ThreadPoolExecutor(3) as ex:
		res = dict(zip(idents, ex.map(_espece, idents)))
	print("réussis :", sum(res.values()), "/", len(res), "; refusés :", [k for k, v in res.items() if not v])


# --- Préparation ----------------------------------------------------------------------

def retenu(ident: str) -> Path | None:
	chat = ART / f"DOSRB_{ident}_chatgpt.png"
	if chat.exists():
		return chat
	if ident in RETENUS:
		return ART / f"{RETENUS[ident]}.png"
	for r in ESSAIS:
		p = ART / f"DOSRB_{ident}_r{r}.png"
		if p.exists():
			return p
	return None


def _propre(im: Image.Image) -> Image.Image:
	"""Détourage : alpha binarisé puis érodé d'un pixel (frange du détourage de Codex)."""
	a = im.getchannel("A").point(lambda v: 255 if v > 96 else 0).filter(ImageFilter.MinFilter(3))
	a = a.filter(ImageFilter.GaussianBlur(0.7))
	out = im.copy()
	out.putalpha(a)
	return out


def _recadrer(im: Image.Image, seuil: int = 8) -> Image.Image:
	boite = im.getchannel("A").point(lambda a: 255 if a > seuil else 0).getbbox()
	return im.crop(boite) if boite else im


def _poser(sujet: Image.Image, cote: int = 1024, utile: int = 1000) -> Image.Image:
	"""Sujet centré, bas de sa boîte (la coupe) sur le bord bas de l'image : le jeu pose ce bord sur
	le bord bas de l'écran."""
	k = min(utile / sujet.width, utile / sujet.height)
	s = sujet.resize((round(sujet.width * k), round(sujet.height * k)), Image.LANCZOS)
	out = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
	out.alpha_composite(s, ((cote - s.width) // 2, cote - s.height))
	return out


def preparer() -> None:
	SORTIE.mkdir(parents=True, exist_ok=True)
	n = 0
	for ident, num, *_ in ESPECES:
		p = retenu(ident)
		if not p or not p.exists():
			continue
		im = Image.open(p).convert("RGBA")
		if im.getchannel("A").getextrema()[0] > 250:
			print("SANS ALPHA (fond opaque), ignoré :", p.name)
			continue
		_poser(_recadrer(_propre(im))).save(SORTIE / f"dos_rb_{num:03d}.png")
		n += 1
	print(n, "dos préparés dans", SORTIE)


def integrer() -> None:
	"""Dos préparés -> assets/sprites/pokemon/dos/ ; importer ensuite en headless (`.import`)."""
	DOS_JEU.mkdir(parents=True, exist_ok=True)
	n = 0
	for ident, num, *_ in ESPECES:
		src = SORTIE / f"dos_rb_{num:03d}.png"
		if src.exists() and retenu(ident):
			(DOS_JEU / src.name).write_bytes(src.read_bytes())
			n += 1
	print(n, "dos copiés dans", DOS_JEU)


def ajouter(ident: str, fichier: str) -> None:
	ident = ident.upper()
	if ident not in {e[0] for e in ESPECES}:
		sys.exit(f"{ident} : espèce inconnue de la série")
	src = Path(fichier).expanduser()
	if not src.exists():
		sys.exit(f"introuvable : {src}")
	ART.mkdir(parents=True, exist_ok=True)
	(ART / f"DOSRB_{ident}_chatgpt.png").write_bytes(src.read_bytes())
	preparer()
	integrer()
	contact(ART / "SERIE_DOS_RB_CONTACT.png")


def liste() -> None:
	for ident, num, fr, _s in ESPECES:
		etat = " ".join(f"r{r}:{'ok' if (ART / f'DOSRB_{ident}_r{r}.png').exists() else '--'}" for r in ESSAIS)
		print(f"{num:03d} {fr:<12} {etat}  retenu={retenu(ident).name if retenu(ident) else '-'}")


def _police(taille: int) -> ImageFont.ImageFont:
	for p in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(p).exists():
			return ImageFont.truetype(p, taille)
	return ImageFont.load_default()


def contact(sortie: Path) -> None:
	"""Une case par espèce : face officielle | dos RB préparé (ou case vide)."""
	case, cols = 220, 6
	especes = ESPECES
	rangs = (len(especes) + cols - 1) // cols
	W = Image.new("RGB", (cols * case * 2, rangs * (case + 28)), (236, 233, 226))
	d = ImageDraw.Draw(W)
	f = _police(18)
	for i, (ident, num, fr, _s) in enumerate(especes):
		x, y = (i % cols) * case * 2, (i // cols) * (case + 28)
		for j, src in enumerate((OFFICIEL / f"{num:03d}.png", SORTIE / f"dos_rb_{num:03d}.png")):
			if src.exists():
				im = Image.open(src).convert("RGBA")
				im.thumbnail((case - 8, case - 8))
				fond = Image.new("RGBA", (case, case), (200, 214, 190, 255) if j else (236, 233, 226, 255))
				fond.alpha_composite(im, ((case - im.width) // 2, case - im.height if j else (case - im.height) // 2))
				W.paste(fond.convert("RGB"), (x + j * case, y + 28))
		d.text((x + 6, y + 4), f"{num:03d} {fr}", fill=(40, 40, 40), font=f)
	sortie.parent.mkdir(parents=True, exist_ok=True)
	W.save(sortie)
	print("planche :", sortie)


def main() -> None:
	args = sys.argv[1:]
	if args[:1] == ["--prompts"]:
		prompts()
	elif args[:1] == ["--liste"]:
		liste()
	elif args[:1] == ["--preparer"]:
		preparer()
	elif args[:1] == ["--integrer"]:
		integrer()
	elif args[:1] == ["--contact"]:
		contact(ART / "SERIE_DOS_RB_CONTACT.png")
	elif args[:1] == ["--ajouter"] and len(args) == 3:
		ajouter(args[1], args[2])
	else:
		generer([a.upper() for a in args])


if __name__ == "__main__":
	main()
