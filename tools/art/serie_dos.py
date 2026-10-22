#!/usr/bin/env python3
"""Série « dos » — lot 2 de l'art (inventaire `docs/design/inventaire-art.md` §2) : dos de combat peints
des espèces de `data/pokemon/species/*.json` qui n'ont AUCUN dos peint (ni `battle_proto/dos_ia_NNN.png`
ni `dos3d_NNN.png`), Voltali et Pyroli compris (Q-4, Kevin 2026-10-21).

Méthode de la série 22 (`serie22.py`, voie de Fantominus et d'Hypno) : dos provisoires peints par Codex au
format de `battle_proto/dos_ia_NNN.png` (1024 × 1024 RGBA, sujet <= 870 px de haut, bas à 120 px).
Leçon d'Évoli (série 22 bis) : Codex refuse quand le prompt nomme l'espèce ou la licence ; chaque prompt de
cette série DÉCRIT l'animal SANS LE NOMMER (« petite créature quadrupède au pelage... »).

Règle de Kevin pour Codex : AVEC images jointes d'abord (2 essais), puis SANS (2 essais).
  r1 : artwork officiel de face + dos de référence (angle) ;  r2 : artwork de face seul ;
  r3 : aucune image ;  r4 : aucune image, formulation « design original ».
Une révision = un nouveau fichier `_r5`, `_r6` (jamais d'écrasement). Les refus sont consignés dans
`$ART/refus_serie_dos.log`. RIEN n'est branché dans le jeu (ni BattleArt, ni manifeste) : Kevin valide
d'abord la planche de contact.

Usage :
  tools/art/serie_dos.py --prompts              écrit les prompts versionnés (sans Codex)
  tools/art/serie_dos.py --commandes            liste les commandes generer.sh (sans Codex)
  tools/art/serie_dos.py --preparer             essais retenus -> $ART/serie_dos/dos_ia_NNN.png (sans Codex)
  tools/art/serie_dos.py --contact              planche de contact $ART/SERIE_DOS_CONTACT.png (sans Codex)
  tools/art/serie_dos.py --liste                liste des espèces et de l'état de chaque essai
  tools/art/serie_dos.py [IDENT ...]            génère avec Codex (3 à la fois), essais r1 à r4 dans l'ordre,
                                                en s'arrêtant au premier qui réussit ; sans argument : tout
                                                sauf les conditionnels (jamais lancés sans leur nom)
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
SORTIE = ART / "serie_dos"
PROMPTS = ICI / "prompts" / "serie_dos"
OFFICIEL = RACINE / "assets/sprites/pokemon/official"
PROTO = RACINE / "assets/sprites/pokemon/battle_proto"
ANGLE = PROTO / "dos_ia_025.png"  # trois quarts dos, regard vers le haut à droite (lot pilote)
JOURNAL = ART / "refus_serie_dos.log"

FIN_DETOURE = ("FOND : PNG avec une vraie transparence (canal alpha), aucun damier dessiné, aucun "
	"fond coloré, aucun sol, aucune ombre portée.")

## (identifiant, numéro, nom français, priorité, sujet de dos SANS nom d'espèce). Priorité 3 = conditionnel :
## espèce jamais affichée de dos (adversaires seulement) ou absente du jeu ; jamais lancée sans son nom.
ESPECES = [
	("HERBIZARRE", 2, "Herbizarre", 1,
		"quadrupède trapu au pelage vert-bleu tacheté de vert plus foncé, courtes pattes épaisses, et sur le dos un "
		"GRAND BOURGEON ROSE FERMÉ aux pétales serrés, gros comme la moitié du corps, portant une pointe verte"),
	("FLORIZARRE", 3, "Florizarre", 1,
		"quadrupède massif et très large au pelage vert-bleu tacheté de vert foncé, pattes épaisses et courtes ; sur le "
		"dos une ÉNORME FLEUR à grands pétales ROSES bordés de crème, au cœur jaune, qui couvre tout le dos"),
	("REPTINCEL", 5, "Reptincel", 1,
		"reptile bipède fin au dos ROUGE-ORANGÉ, une longue CORNE courbe pointant vers l'arrière sur le crâne, griffes "
		"blanches, longue queue épaisse dont le bout porte une FLAMME vive"),
	("DRACAUFEU", 6, "Dracaufeu", 1,
		"grand dragon bipède au dos ORANGE, DEUX GRANDES AILES à membrane bleu-vert aux bords orange dressées derrière "
		"lui, deux petites cornes, longue queue dont le bout porte une FLAMME vive"),
	("CARABAFFE", 8, "Carabaffe", 1,
		"tortue bipède trapue à peau BLEUE avec une CARAPACE BRUNE sur le dos, de grandes oreilles de fourrure "
		"BLANC-BLEUTÉ en panache sur les côtés de la tête et une grosse QUEUE TOUFFUE blanc-bleuté, épaisse, relevée"),
	("TORTANK", 9, "Tortank", 1,
		"grande tortue bipède massive à peau BLEUE, CARAPACE BRUNE à bords crème couvrant le dos, avec DEUX gros TUBES "
		"MÉTALLIQUES blancs et gris qui dépassent de la carapace au-dessus des épaules, courtes queue et pattes"),
	("CHENIPAN", 10, "Chenipan", 1,
		"petite chenille VERTE ronde et dodue à segments, grosse tête ronde portant deux antennes rouges courtes, petits "
		"pieds beiges, dos vert clair rayé de segments plus foncés"),
	("CHRYSACIER", 11, "Chrysacier", 1,
		"cocon d'insecte en forme d'ovale haut, à coque VERTE lisse et dure marquée de côtes de segments, petite "
		"pointe au sommet, posé droit ; aucun membre visible"),
	("ASPICOT", 13, "Aspicot", 1,
		"petite larve de guêpe BEIGE-JAUNE ronde et dodue, tête ronde portant UN PETIT DARD pointu sur le front, petits "
		"pieds roses, dos à segments"),
	("COCONFORT", 14, "Coconfort", 1,
		"cocon d'insecte en forme d'ovale haut, à coque JAUNE vif lisse et dure à côtes de segments, petite pointe "
		"au sommet, posé droit ; aucun membre visible"),
	("DARDARGNAN", 15, "Dardargnan", 1,
		"insecte-guêpe bipède fin, corps JAUNE à bandes NOIRES, quatre ailes transparentes dans le dos, longs DARDS "
		"pointus à la place des mains, abdomen rayé terminé par un dard"),
	("ROUCOUPS", 17, "Roucoups", 1,
		"oiseau BRUN à ventre crème, crête de plumes crème et brun dressée sur la tête, ailes brun foncé, longue queue "
		"aux plumes ROUGES et crème, serres fines"),
	("ROUCARNAGE", 18, "Roucarnage", 1,
		"grand oiseau BRUN, grande CRÊTE de plumes rouge, orange et jaune qui retombe en panache derrière la tête, "
		"ailes brun foncé, très longue queue de plumes rouges et jaunes"),
	("RATTATA", 19, "Rattata", 1,
		"petit rongeur quadrupède au pelage VIOLET, ventre crème, grandes oreilles rondes, longue queue rose fine "
		"en boucle, deux grandes incisives, moustaches"),
	("RATTATAC", 20, "Rattatac", 1,
		"rongeur quadrupède dressé au pelage BRUN, ventre crème, grandes oreilles, longue queue rose épaisse, grandes "
		"incisives et moustaches blanches"),
	("PIAFABEC", 21, "Piafabec", 1,
		"petit oiseau BRUN aux ailes courtes, ventre crème, bec pointu rose, queue courte rousse, fines pattes roses"),
	("RAPASDEPIC", 22, "Rapasdepic", 1,
		"oiseau BRUN élancé à long bec fin pointu et fine crête rousse sur la tête, ailes brun foncé aux bouts "
		"crème, queue rousse en éventail, pattes fines"),
	("ABO", 23, "Abo", 1,
		"petit serpent VIOLET enroulé sur lui-même, ventre jaune crème, le haut du corps dressé ; de dos on voit "
		"surtout le dos violet marqué de bandes plus sombres et le bout de la queue"),
	("ARBOK", 24, "Arbok", 1,
		"grand cobra VIOLET dressé, large CAPUCHON déployé derrière la tête marqué d'un dessin en losange pâle et sombre, "
		"ventre jaune crème, queue enroulée à la base"),
	("RAICHU", 26, "Raichu", 1,
		"rongeur quadrupède robuste au pelage ORANGE, ventre crème, grandes oreilles pointues brunes, longue queue "
		"fine terminée par un ÉCLAIR jaune en pointe de flèche, deux bandes brunes dans le dos"),
	("SABELETTE", 27, "Sabelette", 1,
		"petit rongeur-tatou JAUNE-BEIGE, dos recouvert de plaques lisses comme une cuirasse, ventre crème, petites "
		"griffes, petites oreilles rondes, courte queue"),
	("SABLAIREAU", 28, "Sablaireau", 1,
		"rongeur-tatou dressé BRUN-JAUNE, dos hérissé de PIQUANTS et de plaques brunes, ventre crème, longues griffes, "
		"courte queue"),
	("NIDORAN_F", 29, "Nidoran♀", 1,
		"petite créature quadrupède BLEU-GRIS à petites oreilles rondes, dos parsemé de petits PIQUANTS pâles, "
		"moustaches, petite queue"),
	("NIDORINA", 30, "Nidorina", 1,
		"créature quadrupède BLEU-GRIS plus grande, oreilles larges, dos hérissé de PIQUANTS pâles, queue épaisse, "
		"petites griffes"),
	("NIDOQUEEN", 31, "Nidoqueen", 1,
		"grande créature bipède lourde et dressée, BLEU-GRIS, ventre crème, dos hérissé de gros PIQUANTS, queue "
		"épaisse et forte, petites oreilles"),
	("NIDORAN_M", 32, "Nidoran♂", 1,
		"petite créature quadrupède VIOLETTE aux grandes oreilles pointues dressées, une petite CORNE sur le front, dos "
		"hérissé de petits piquants sombres, petite queue"),
	("NIDORINO", 33, "Nidorino", 1,
		"créature quadrupède VIOLETTE plus grande, grandes oreilles pointues, une CORNE sur le front, dos hérissé de "
		"piquants sombres, queue épaisse"),
	("NIDOKING", 34, "Nidoking", 1,
		"grande créature bipède lourde et puissante, VIOLETTE, dos hérissé de piquants sombres, grandes oreilles, "
		"CORNE sur le front, queue très épaisse et forte"),
	("MELOFEE", 35, "Mélofée", 1,
		"petite créature ROSE clair ronde et dodue, grandes oreilles pointues aux bouts bruns, petites ailes "
		"blanches dans le dos, queue en boucle à bout brun, petits pieds"),
	("MELODELFE", 36, "Mélodelfe", 1,
		"créature ROSE clair dodue et dressée, grandes oreilles pointues aux bouts bruns, petites ailes blanches "
		"dans le dos, longue queue en boucle terminée de brun"),
	("RONDOUDOU", 39, "Rondoudou", 1,
		"petite créature ROSE parfaitement ronde comme un ballon, une MÈCHE frisée sur le front, deux oreilles "
		"pointues, petite queue en boucle, minuscules pieds"),
	("GRODOUDOU", 40, "Grodoudou", 1,
		"créature ROSE et crème ronde et douce, grandes oreilles pointues, grosse MÈCHE frisée, longue queue "
		"touffue enroulée, petits pieds"),
	("NOSFERALTO", 42, "Nosferalto", 1,
		"grande chauve-souris BLEU-VIOLET, ailes membraneuses largement ouvertes derrière elle, oreilles pointues, "
		"minuscules pattes ; sans visage visible de dos"),
	("MYSTHERBE", 43, "Mystherbe", 1,
		"petite créature BLEU-VIOLET ronde et dodue, CINQ FEUILLES VERTES pointues en couronne sur la tête, "
		"petits pieds"),
	("ORTIDE", 44, "Ortide", 1,
		"créature BLEU-VIOLET dodue, sur la tête une GRANDE FLEUR à larges pétales pâles tachetés de rose, "
		"petits bras, petits pieds"),
	("PARAS", 46, "Paras", 1,
		"petite créature-crabe ORANGE, sur le dos DEUX CHAMPIGNONS rouges tachetés de crème, pinces avant à griffes, "
		"six petites pattes"),
	("PARASECT", 47, "Parasect", 1,
		"grande créature-crabe ORANGE ; un ÉNORME CHAMPIGNON ROUGE tacheté de crème recouvre tout son dos et sa tête ; "
		"pinces avant larges, pattes fines"),
	("MIAOUSS", 52, "Miaouss", 1,
		"chat quadrupède au pelage CRÈME avec les oreilles et les pattes brunes, grandes oreilles pointues, longue "
		"queue fine recourbée en point d'interrogation"),
	("PERSAN", 53, "Persan", 1,
		"chat quadrupède élancé et élégant au pelage CRÈME, oreilles noires pointues, longue queue fine recourbée vers "
		"le haut, pattes fines"),
	("FEROSINGE", 56, "Férosinge", 1,
		"petit singe-cochon bipède au pelage BLANC-CRÈME hérissé, museau rose, bras et jambes musclés, "
		"queue frisée, petits poings"),
	("COLOSSINGE", 57, "Colossinge", 1,
		"singe bipède musclé au pelage BLANC-CRÈME hérissé, bracelets sombres aux poignets et aux chevilles, "
		"queue frisée, grands poings"),
	("ABRA", 63, "Abra", 1,
		"humanoïde fin au corps JAUNE-BRUN assis, long museau, grandes oreilles pointues, épaules et ceinture "
		"brunes, longue queue brune qui traîne"),
	("KADABRA", 64, "Kadabra", 1,
		"humanoïde fin JAUNE-BRUN debout, longues MOUSTACHES, une étoile rouge sur le torse (invisible de dos), "
		"grandes oreilles pointues, longue queue brune, épaules brunes en plastron"),
	("MACHOC", 66, "Machoc", 1,
		"petit humanoïde trapu à peau BLEU-GRIS, très musclé, grande CEINTURE rouge-violet, petites oreilles pointues, "
		"large dos, bras puissants"),
	("CHETIFLOR", 69, "Chétiflor", 1,
		"petite plante vivante : fine TIGE JAUNE-VERT surmontée d'une grande FEUILLE verte en forme de cloche "
		"retombante, deux petites feuilles en guise de bras, petits pieds"),
	("BOUSTIFLOR", 70, "Boustiflor", 1,
		"plante vivante : longue tige JAUNE-VERT, grande tête en CLOCHE JAUNE retombante, deux feuilles vertes en "
		"guise de bras, grandes feuilles à la base"),
	("RACAILLOU", 74, "Racaillou", 1,
		"roche grise arrondie et rugueuse, deux gros bras de pierre musclés posés au sol, aspect de gros galet ; "
		"rien d'autre"),
	("GRAVALANCH", 75, "Gravalanch", 1,
		"roche grise arrondie et rugueuse, QUATRE bras de pierre musclés, aspect de gros bloc ; rien d'autre"),
	("GROLEM", 76, "Golem", 1,
		"créature de pierre massive : grande CARAPACE ronde de roc BRUN-GRIS couvrant tout le dos, quatre membres "
		"épais, tête et bras de pierre claire"),
	("MAGNETON", 82, "Magnéton", 1,
		"trois petites boules d'ACIER gris-bleu agglomérées, chacune coiffée d'aimants rouge et bleu en forme de fer à "
		"cheval, flottant en triangle ; de dos on voit surtout les aimants et les dos des boules"),
	("KOKIYAS", 90, "Kokiyas", 1,
		"grand coquillage bivalve VIOLET clair aux côtes rayonnantes et aux pointes, posé droit, fermé à demi ; de "
		"dos, uniquement la grande coquille bombée"),
	("VOLTORBE", 100, "Voltorbe", 1,
		"sphère lisse dont la moitié haute est ROUGE et la moitié basse BLANCHE, séparées par une fine ligne sombre ; "
		"aucun membre, aucun visage visible de dos, seulement la sphère"),
	("NOEUNOEUF", 102, "Noeunoeuf", 1,
		"grappe de SIX gros oeufs rosés à reflets crème, serrés les uns contre les autres, aux petites taches "
		"foncées ; vue arrière de la grappe"),
	("HYPOTREMPE", 116, "Hypotrempe", 1,
		"petit hippocampe BLEU clair, ventre crème, queue enroulée, nageoires dorsales en éventail, museau "
		"tubulaire ; vu de dos, dressé"),
	("POISSIRENE", 118, "Poissirène", 1,
		"poisson de rivière BLANC marqué de ROUGE-ORANGE, longue CORNE pointue sur le front, grande queue en voile "
		"orange et blanche, nageoires rouges"),
	("STARI", 120, "Stari", 1,
		"créature marine en forme d'ÉTOILE à cinq branches, BRUN-DORÉ ; un joyau ROUGE rond au centre du corps ; vue "
		"de dessus et un peu de côté"),
	("STAROSS", 121, "Staross", 1,
		"créature marine formée de DEUX étoiles à cinq branches superposées, VIOLET ; un joyau ROUGE-VIOLET au centre ; "
		"vue de dessus et un peu de côté"),
	("LEVIATOR", 130, "Léviator", 1,
		"grand SERPENT MARIN BLEU à ventre crème, longue crête à nageoires, grande gueule, écailles ; de dos, "
		"on voit le corps bleu en S et la grande nageoire de la queue"),
	("VOLTALI", 135, "Voltali", 1,
		"quadrupède fin au pelage JAUNE vif tout HÉRISSÉ en PIQUANTS pointus (surtout le dos, la croupe et la queue), "
		"COLLERETTE blanche en pointes autour du cou, grandes oreilles pointues jaunes"),
	("PYROLI", 136, "Pyroli", 1,
		"quadrupède trapu au pelage ROUGE-ORANGÉ, très grosse COLLERETTE de fourrure JAUNE CRÈME duveteuse autour du "
		"cou, touffe jaune sur le front, longues oreilles rouges, grosse QUEUE touffue jaune crème en panache"),
	# Conditionnels : adversaires seulement (Erika, Giovanni, Saquedeneu) ou absents du jeu (Ossatueur, J21).
	("OSSATUEUR", 105, "Ossatueur", 3,
		"petit bipède brun portant un CRÂNE d'os blanc en casque sur la tête, tenant un long os dans une main, "
		"queue courte"),
	("RHINOCORNE", 111, "Rhinocorne", 3,
		"quadrupède massif à peau GRISE, grosse CORNE sur le museau, dos plaqué de plaques rugueuses, queue courte"),
	("SAQUEDENEU", 114, "Saquedeneu", 3,
		"masse de LIANES BLEU FONCÉ enchevêtrées qui cachent tout le corps, deux petits pieds roses dessous"),
	("KANGOUREX", 115, "Kangourex", 3,
		"grand bipède BRUN à ventre crème, courts bras, fortes jambes, longue queue épaisse, une poche ventrale avec "
		"un petit"),
]

DOS = """POKÉMON DE DOS POUR UN ÉCRAN DE COMBAT (Kanto 2026, projet personnel). {nom}

{ancres}

SUJET : {sujet}.

VUE : de DOS, de trois quarts, légèrement par-dessus l'épaule gauche ; la créature regarde vers le HAUT À DROITE de l'image (son adversaire est loin devant elle). On voit surtout son dos, sa nuque, l'arrière de la tête et la queue ; le visage est tourné vers l'avant, hors de vue (au plus, le bord d'une joue ou d'un œil de profil).

STYLE : celui des artworks officiels de face (même trait fin et doux, même ombrage en aplats nuancés, même palette) : le dos et l'adversaire en face doivent paraître venir du même jeu. Pas de pixel art, pas de 3D, pas de rendu photo.
LUMIÈRE : neutre (milieu de journée, diffuse, légèrement du haut à gauche) ; le jeu ajoute l'ambiance.
CADRAGE : image CARRÉE 1024 × 1024, la créature ENTIÈRE (queues, oreilles et pattes comprises), centrée, qui occupe environ 80 % de la hauteur ; rien n'est coupé par les bords. Une seule image fixe, une seule créature.
{fin}
INTERDITS : texte, lettres, chiffres, signature, cadre, sol, décor, ombre portée, autre créature, personnage."""

NOM = ("La créature est un animal fantastique de jeu vidéo.",
	"La créature est un animal fantastique de jeu vidéo.",
	"La créature est un animal fantastique de jeu vidéo.",
	"La créature est un personnage original d'un jeu vidéo d'aventure, inspiré des animaux réels.")
ANCRES = (
	"IMAGE 1 : une illustration de face de la créature : couleurs, proportions et style (pas la pose).\n"
	"IMAGE 2 : une autre créature vue de dos dans ce jeu : reprends son ANGLE de vue et son cadrage, pas sa forme.",
	"IMAGE 1 : une illustration de face de la créature : couleurs, proportions et style (pas la pose). "
	"Reprends son anatomie, vue de l'autre côté.",
	"Aucune image jointe.",
	"Aucune image jointe.")
ESSAIS = (1, 2, 3, 4)

## Révisions après relecture de la planche (2026-10-22) : sujet corrigé -> nouveaux fichiers _r5 à _r8
## (même règle : r5 et r6 AVEC images jointes, r7 et r8 SANS ; les prompts r1 à r4 restent tels quels).
REVISIONS = {
	"MIAOUSS": ("petit chat beige debout sur ses deux pattes arrière, petit museau, longues MOUSTACHES fines, "
		"oreilles pointues NOIRES à l'intérieur brun, une petite PIÈCE DORÉE ovale sur le front (de dos, on n'en "
		"voit au plus que le bord), pattes courtes, queue fine à BOUT ENROULÉ brun"),
	"KADABRA": ("humanoïde JAUNE mince et debout, PLASTRON brun en forme d'armure sur le torse et les épaules, "
		"grandes oreilles pointues, longues MOUSTACHES blanches, longue queue épaisse jaune marquée d'une bande "
		"brune, tenant une CUILLÈRE d'argent dans une main"),
	"NIDORINA": ("petite créature quadrupède dodue BLEU PÂLE (bleu-gris clair) comme un gros lapin, de grandes oreilles "
		"rondes à l'intérieur turquoise, dos tacheté de taches bleu plus foncé et orné de quelques petits PIQUANTS "
		"crème, pattes courtes, queue fine"),
	"RACAILLOU": ("grosse BOULE de roche grise rugueuse, SANS AUCUNE JAMBE ni pied, flottant juste au-dessus du sol ; "
		"seulement DEUX BRAS de pierre musclés, de part et d'autre de la boule, terminés par des poings de roche ; "
		"de dos : la boule ronde au centre et les deux bras"),
}


def jointes(num: int, r: int) -> list[Path]:
	if r == 1:
		return [OFFICIEL / f"{num:03d}.png", ANGLE]
	if r == 2:
		return [OFFICIEL / f"{num:03d}.png"]
	return []


def images() -> list[dict]:
	liste = []
	for ident, num, _fr, prio, sujet in ESPECES:
		rev = REVISIONS.get(ident)
		for r in ESSAIS + ((5, 6, 7, 8) if rev else ()):
			k = (r - 1) % 4 + 1  # motif de l'essai (avec / sans images)
			liste.append({"ident": ident, "num": num, "r": r, "prio": prio, "nom": f"DOS_{ident}_r{r}",
				"fichier": PROMPTS / f"DOS_{ident}_r{r}.txt", "jointes": jointes(num, k),
				"texte": DOS.format(nom=NOM[k - 1], ancres=ANCRES[k - 1], fin=FIN_DETOURE,
					sujet=rev if (rev and r > 4) else sujet)})
	return liste


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for im in images():
		im["fichier"].write_text(im["texte"] + "\n", encoding="utf-8")
	print(len(images()), "prompts dans", PROMPTS)


def _commande(im: dict) -> list[str]:
	return [str(ICI / "generer.sh"), im["nom"], str(im["fichier"])] + [str(j) for j in im["jointes"]]


def commandes() -> None:
	for im in images():
		print("CODEX=$HOME/.local/bin/codex " + " ".join(_commande(im)))


def _journal(ligne: str) -> None:
	ART.mkdir(parents=True, exist_ok=True)
	with JOURNAL.open("a", encoding="utf-8") as f:
		f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + ligne + "\n")


def _essai(im: dict) -> bool:
	if (ART / f"{im['nom']}.png").exists():
		return True
	env = dict(os.environ, CODEX=os.environ.get("CODEX", str(Path.home() / ".local/bin/codex")))
	p = subprocess.run(_commande(im), cwd=RACINE, env=env, capture_output=True, text=True)
	ok = p.returncode == 0 and (ART / f"{im['nom']}.png").exists()
	if not ok:
		cause = "moderation_blocked" if "moderation_blocked" in p.stderr else p.stderr.strip()[-160:]
		_journal(f"REFUS {im['nom']} ({'avec' if im['jointes'] else 'sans'} jointes) : {cause}")
	print(("OK    " if ok else "REFUS "), im["nom"], flush=True)
	return ok


def _espece(ident: str) -> bool:
	"""Essais r1 à r4 dans l'ordre jusqu'au premier qui réussit."""
	for im in (i for i in images() if i["ident"] == ident and (i["r"] > 4 or ident not in REVISIONS)):
		if _essai(im):
			return True
	return False


def generer(noms: list[str]) -> None:
	prompts()
	idents = [e[0] for e in ESPECES if (e[0] in noms if noms else e[3] != 3)]
	with ThreadPoolExecutor(3) as ex:
		res = dict(zip(idents, ex.map(_espece, idents)))
	print("réussis :", sum(res.values()), "/", len(res), "; refusés :", [k for k, v in res.items() if not v])


# --- Préparation ----------------------------------------------------------------------
## Essais retenus après relecture (Kevin, ou ma relecture de la nuit) : clé = identifiant, valeur = essai.
## Par défaut : le plus petit r disponible.
RETENUS: dict[str, str] = {  # relecture de la planche, 2026-10-22 (révisions r5 à r8)
	"MIAOUSS": "DOS_MIAOUSS_r6", "KADABRA": "DOS_KADABRA_r7", "RACAILLOU": "DOS_RACAILLOU_r5",
	"NIDORINA": "DOS_NIDORINA_r6",
}


def retenu(ident: str) -> Path | None:
	if ident in RETENUS:
		return ART / f"{RETENUS[ident]}.png"
	for r in range(1, 12):
		p = ART / f"DOS_{ident}_r{r}.png"
		if p.exists():
			return p
	return None


def _recadrer(im: Image.Image, seuil: int = 8) -> Image.Image:
	boite = im.getchannel("A").point(lambda a: 255 if a > seuil else 0).getbbox()
	return im.crop(boite) if boite else im


def _propre(im: Image.Image) -> Image.Image:
	"""Détourage : alpha binarisé puis érodé d'un pixel (retire la frange jaune/rouge du détourage de Codex)."""
	a = im.getchannel("A").point(lambda v: 255 if v > 96 else 0).filter(ImageFilter.MinFilter(3))
	a = a.filter(ImageFilter.GaussianBlur(0.7))
	out = im.copy()
	out.putalpha(a)
	return out


def _poser(sujet: Image.Image, cote: int, utile: int, bas: int) -> Image.Image:
	k = min(utile / sujet.width, utile / sujet.height)
	s = sujet.resize((round(sujet.width * k), round(sujet.height * k)), Image.LANCZOS)
	out = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
	out.alpha_composite(s, ((cote - s.width) // 2, cote - bas - s.height))
	return out


def preparer() -> None:
	"""Dos retenus -> $ART/serie_dos/dos_ia_NNN.png (format de dos_ia_093 : 1024², sujet <= 870, bas à 120)."""
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
		_poser(_recadrer(_propre(im)), 1024, 870, 120).save(SORTIE / f"dos_ia_{num:03d}.png")
		print("dos", ident, p.name)
		n += 1
	print(n, "dos préparés dans", SORTIE)


def liste() -> None:
	for ident, num, fr, prio, _s in ESPECES:
		etat = []
		for r in ESSAIS:
			etat.append(f"r{r}" if (ART / f"DOS_{ident}_r{r}.png").exists() else "--")
		print(f"{num:03d} {fr:12s} prio {prio}  {' '.join(etat)}")


# --- Planche de contact -----------------------------------------------------------------
def _police(taille: int) -> ImageFont.ImageFont:
	for c in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial.ttf"):
		if Path(c).exists():
			return ImageFont.truetype(c, taille)
	return ImageFont.load_default()


def contact(sortie: Path) -> None:
	"""Une case par espèce : artwork officiel de face (gauche) et dos préparé (droite) sur fond gris-bleu
	neutre ; case vide marquée « refusé » quand aucun dos n'a abouti."""
	cote, texte = 240, 30
	col = 4
	lignes = (len(ESPECES) + col - 1) // col
	pl = Image.new("RGB", (col * (2 * cote + 12) + 12, lignes * (cote + texte + 12) + 60), (40, 44, 54))
	d = ImageDraw.Draw(pl)
	d.text((14, 12), "Série dos — dos de combat (Codex, provisoires peints) : face officielle | dos proposé. "
		"Non intégré : à valider par Kevin.", fill=(230, 230, 190), font=_police(20))
	for i, (ident, num, fr, prio, _s) in enumerate(ESPECES):
		x, y = 12 + (i % col) * (2 * cote + 12), 60 + (i // col) * (cote + texte + 12)
		d.rectangle((x, y, x + 2 * cote, y + cote + texte), fill=(58, 64, 78))
		f = OFFICIEL / f"{num:03d}.png"
		if f.exists():
			im = Image.open(f).convert("RGBA")
			im.thumbnail((cote - 8, cote - 8), Image.LANCZOS)
			pl.paste(im, (x + (cote - im.width) // 2, y + texte + (cote - im.height) // 2), im)
		dos = SORTIE / f"dos_ia_{num:03d}.png"
		if dos.exists():
			im = _recadrer(Image.open(dos).convert("RGBA"))
			im.thumbnail((cote - 8, cote - 8), Image.LANCZOS)
			pl.paste(im, (x + cote + (cote - im.width) // 2, y + texte + (cote - im.height) // 2), im)
			r = retenu(ident)
			etat = r.stem.rsplit("_", 1)[1] if r else ""
		else:
			d.text((x + cote + 70, y + texte + cote // 2 - 12), "pas de dos" + (" (cond.)" if prio == 3 else ""),
				fill=(220, 120, 120), font=_police(20))
			etat = "refusé" if prio != 3 else "non lancé"
		d.text((x + 8, y + 4), f"{fr} ({num})  {etat}", fill="white", font=_police(18))
	pl.save(sortie)
	print(sortie, pl.size)


def main() -> None:
	args = sys.argv[1:]
	ART.mkdir(parents=True, exist_ok=True)
	if args and args[0] in ("-h", "--help"):
		sys.exit(__doc__)
	if args and args[0] == "--prompts":
		prompts()
	elif args and args[0] == "--commandes":
		commandes()
	elif args and args[0] == "--preparer":
		preparer()
	elif args and args[0] == "--contact":
		contact(ART / "SERIE_DOS_CONTACT.png")
	elif args and args[0] == "--liste":
		liste()
	else:
		generer(args)


if __name__ == "__main__":
	main()
