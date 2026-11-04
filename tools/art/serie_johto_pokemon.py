#!/usr/bin/env python3
"""Série Johto — art des Pokémon de Johto (fiche docs/design/fiches-assets/serie-johto-pokemon.md).

Trois sortes d'images peintes par Codex (`generer.sh`, abonnement ChatGPT, sans API) :
  - **dos de combat RB** (cadrage B) de chaque espèce : gabarit `DOS_RB` de `serie_dos_rb.py`, sujet
    DÉCRIT SANS NOMMER l'espèce (leçon d'Évoli) ; r1 avec l'artwork officiel joint, r2 sans image,
    r3 « design original » ; -> `assets/sprites/pokemon/dos/dos_rb_NNN.png` ;
  - **planche de marche** 4 × 4 (1024 × 1536) des Pokémon qui marchent dans le monde (compagnon, table
    d'Orme) : gabarit de `serie13.py`, ancres = héros validé + une planche de Pokémon validée ;
  - **feuille d'ambiance** 4 × 1 en boucle (1536 × 1024) des légendaires observés (JOH7, JOH8) :
    gabarit d'Artikodin (`serie27.py`) ;
  plus la planche des **icônes du Sac** des quatre objets d'évolution (gabarit de `menu_peint.py`).
Règle de Kevin : AVEC images jointes d'abord, puis SANS. Une révision = un nouveau fichier (jamais
d'écrasement). Refus consignés dans `$ART/refus_serie_johto.log`.

Usage :
  tools/art/serie_johto_pokemon.py --prompts            écrit les prompts (tools/art/prompts/serie_johto/)
  tools/art/serie_johto_pokemon.py --liste              état de chaque essai
  tools/art/serie_johto_pokemon.py [--pilote] [IDENT ...] [--dos|--monde|--objets]
                                                        génère avec Codex (3 à la fois), jusqu'au
                                                        premier essai réussi ; --pilote : la planche pilote
  tools/art/serie_johto_pokemon.py --preparer           dos retenus -> $ART/serie_johto/dos_rb_NNN.png
  tools/art/serie_johto_pokemon.py --integrer           dos préparés -> assets/sprites/pokemon/dos/ ;
                                                        icônes -> assets/ui/items/
  tools/art/serie_johto_pokemon.py --monde-integrer     planches du monde retenues -> manifeste.json,
                                                        painted/<id>_sheet.png, assets/world/catalogue.json
                                                        (puis tools/build_character_frames.gd)
  tools/art/serie_johto_pokemon.py --contact [--pilote] planche de contact
                                                        docs/design/fiches-assets/serie-johto/
"""
from __future__ import annotations

import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import serie_dos_rb as rb  # noqa: E402
import menu_peint  # noqa: E402
import preparer_menu  # noqa: E402

RACINE = ICI.parents[1]
ART = Path(os.environ.get("ART", RACINE / "build" / "art"))
## Ancres validées (héros, planches de Pokémon) : build/art du Mac de Kevin, dépôt principal.
ANCRES = Path(os.environ.get("ANCRES", Path.home() / "dev/kanto-2026/build/art"))
SORTIE = ART / "serie_johto"
PROMPTS = ICI / "prompts" / "serie_johto"
OFFICIEL = RACINE / "assets/sprites/pokemon/official"
PEINTS = RACINE / "assets/sprites/pokemon/painted"
DOS_JEU = RACINE / "assets/sprites/pokemon/dos"
ITEMS = RACINE / "assets/ui/items"
FICHE = RACINE / "docs/design/fiches-assets/serie-johto"
JOURNAL = ART / "refus_serie_johto.log"

PILOTE = ["GERMIGNON", "HERICENDRE", "KAIMINUS", "SUICUNE", "TYRANOCIF"]

## (identifiant, n°, nom français, id du jeu, sujet de dos SANS nom d'espèce).
ESPECES: list[tuple[str, int, str, str, str]] = [
	("GERMIGNON", 152, "Germignon", "chikorita",
		"petite créature quadrupède VERT PÂLE au corps rond, grosse tête ronde, une GRANDE FEUILLE vert tendre "
		"qui pousse au sommet du crâne et retombe vers l'arrière, un collier de petits BOURGEONS vert foncé "
		"autour du cou, courtes pattes"),
	("HERICENDRE", 155, "Héricendre", "cyndaquil",
		"petite créature quadrupède allongée, façon musaraigne, au DOS BLEU NUIT et au ventre CRÈME, long museau "
		"pointu ; sur le bas du dos, quatre petites taches ROUGES d'où jaillit une COLLERETTE DE FLAMMES "
		"orange et jaunes dressées"),
	("KAIMINUS", 158, "Kaiminus", "totodile",
		"petit crocodile bipède trapu à la peau BLEUE, grosse tête à grande mâchoire, une CRÊTE d'écailles ROUGES "
		"pointues sur le haut du dos et le long de la queue, courte queue épaisse, petits bras"),
	("SUICUNE", 245, "Suicune", "suicune",
		"grand quadrupède élégant et élancé, au pelage BLEU CIEL tacheté de LOSANGES BLANCS, une longue CRINIÈRE "
		"VIOLETTE en nuage qui flotte derrière la tête, DEUX longs RUBANS BLANCS ondulants qui partent du dos "
		"comme une écharpe de vent, un ornement de front en CRISTAL blanc, pattes fines"),
	("TYRANOCIF", 248, "Tyranocif", "tyranitar",
		"grand monstre reptilien bipède massif à la peau VERT-GRIS épaisse comme une ARMURE, rangées de "
		"grosses POINTES sur le dos et les épaules, une corne sur le front, plaques sombres, longue queue "
		"épaisse et lourde"),
]

## Les 46 autres espèces (sujets rédigés en regardant chaque artwork officiel ; même règle).
ESPECES_SUITE = [
	("MACRONIUM", 153, "Macronium", "bayleef",
		"quadrupède trapu à long cou, au corps CRÈME JAUNE PÂLE et à la peau claire, une GRANDE FEUILLE vert tendre "
		"pointue dressée sur l'arrière du crâne, une COLLERETTE de grandes feuilles vert foncé autour du cou et des "
		"épaules, dos rond et large, courte queue pointue crème, pattes courtes et épaisses"),
	("MEGANIUM", 154, "Méganium", "meganium",
		"grand quadrupède massif à la peau VERT TENDRE, long cou épais, deux ANTENNES fines à bout jaune sur la nuque, "
		"une grande COLLERETTE de pétales ROSE VIF bordés de blanc autour du cou, large dos vert, courte queue "
		"pointue, pattes épaisses à griffes claires"),
	("FEURISSON", 156, "Feurisson", "quilava",
		"quadrupède trapu au DOS BLEU-VERT SOMBRE et au ventre CRÈME, museau pointu, une GRANDE TOUFFE DE FLAMMES "
		"orange et jaunes qui jaillit de la nuque, et une seconde crinière de FLAMMES sur la croupe qui "
		"s'élève derrière, petites oreilles pointues"),
	("TYPHLOSION", 157, "Typhlosion", "typhlosion",
		"grand quadrupède massif debout, au DOS BLEU NUIT sombre, ventre CRÈME, une énorme COLLERETTE DE FLAMMES "
		"orange et jaunes en éventail qui jaillit de la nuque et des épaules, museau pointu, bras épais, "
		"croupe lourde, petite queue"),
	("CROCRODIL", 159, "Crocrodil", "croconaw",
		"crocodile bipède trapu à la peau BLEU TURQUOISE, grosse tête à gueule large surmontée de GRANDES POINTES "
		"ROUGES en crête, plus petites pointes rouges le long du dos, grosse queue épaisse terminée par une "
		"POINTE ROUGE en losange, bras écartés"),
	("ALIGUEUR", 160, "Aligatueur", "feraligatr",
		"grand crocodile bipède massif à la peau BLEUE, DEUX grandes CRÊTES de pointes ROUGES sur la tête, "
		"rangée de pointes rouges le long du dos, épaisses plaques d'armure bleu clair sur les bras, queue "
		"lourde et puissante, griffes blanches"),
	("FOUINETTE", 161, "Fouinette", "sentret",
		"petite créature BRUN CHOCOLAT debout sur ses pattes arrière, tête ronde dotée de deux OREILLES rondes à "
		"intérieur ROSE, un grand CERCLE crème sur le ventre, queue très LONGUE et épaisse à ANNEAUX bruns "
		"alternés, bout de queue en boule"),
	("FOUINAR", 162, "Fouinar", "furret",
		"créature allongée en forme de fouine, au pelage BRUN CLAIR rayé de bandes BRUN FONCÉ, ventre crème, "
		"corps très long et sinueux, énorme QUEUE touffue à ANNEAUX bruns terminée en pointe, petites oreilles "
		"pointues"),
	("HOOTHOOT", 163, "Hoothoot", "hoothoot",
		"petit oiseau rond de type chouette, au plumage BRUN CHAUD sur le dos, deux PLUMES NOIRES en pointes "
		"dressées sur le haut du crâne, petites ailes brunes courtes tenues le long du corps (non déployées), "
		"queue courte à plumes crème, pattes roses à serres"),
	("NOARFANG", 164, "Noarfang", "noctowl",
		"grande chouette dressée au plumage BRUN, deux grandes CORNES CRÈME en couronne de plumes autour de la "
		"tête, ailes brunes repliées marquées de TRIANGLES SOMBRES, courte queue en éventail brun foncé, serres "
		"claires"),
	("NOSTENFER", 169, "Nostenfer", "crobat",
		"chauve-souris à corps VIOLET SOMBRE, ailes membraneuses VERT-BLEU grandes ouvertes (DÉPLOYÉES) vues de dos, "
		"deux ailes inférieures supplémentaires plus petites, deux petites oreilles pointues sur la tête, courte queue violette en pointe"),
	("TOGEPI", 175, "Togepi", "togepi",
		"créature en forme d'ŒUF rond blanc cassé, crème, motifs de TRIANGLES colorés ROUGES et BLEUS sur la "
		"coquille, une coiffe de coquille crème en dents de scie sur le dessus de la tête, petits bras crème "
		"levés, petits pieds"),
	("TOGETIC", 176, "Togetic", "togetic",
		"petite créature blanche à reflets VERT PÂLE, corps en forme de goutte avec des TRIANGLES ROUGES et BLEUS "
		"sur le ventre, DEUX petites ailes blanches DÉPLOYÉES sur le dos, deux petites oreilles pointues, petits "
		"pieds crème"),
	("WATTOUAT", 179, "Wattouat", "mareep",
		"petit mouton quadrupède à épaisse TOISON de laine JAUNE PÂLE bouclée sur le dos, tête bleue marine "
		"coiffée d'une MÈCHE de laine, deux cornes spiralées à anneaux noirs et jaunes, pattes bleu foncé, "
		"longue queue à rayures noires et jaunes terminée par une BOULE ORANGE brillante"),
	("LAINERGIE", 180, "Lainergie", "flaaffy",
		"mouton bipède à peau ROSE, touffes de laine bouclée BLANC-GRIS sur la tête, le cou et le haut du dos, "
		"deux cornes noires recourbées, longue queue annelée de noir et rose terminée par une BOULE BLEUE "
		"brillante, dos rose rebondi"),
	("PHARAMP", 181, "Pharamp", "ampharos",
		"créature bipède à longue queue, au dos JAUNE VIF, au ventre blanc, long cou à ANNEAUX NOIRS, deux petites "
		"cornes à rayures noires et jaunes portant une BILLE ROUGE, longue queue annelée terminée par une "
		"BOULE ROUGE brillante, bras fins"),
	("MARILL", 183, "Marill", "marill",
		"petite créature BLEU VIF toute ronde à grandes oreilles rondes (intérieur ROUGE-ORANGÉ), ventre blanc, "
		"longue QUEUE noire en zigzag terminée par une GRANDE BOULE bleue ronde qui se dresse derrière le dos, "
		"petits pieds"),
	("AZUMARILL", 184, "Azumarill", "azumarill",
		"créature ovale BLEUE tachetée de pois BLANCS sur le dos, ventre blanc, DEUX LONGUES OREILLES de lapin "
		"dressées à l'intérieur ROSE, petite queue noire en zigzag terminée par une BOULE bleue, petits bras "
		"écartés"),
	("TARPAUD", 186, "Tarpaud", "politoed",
		"grenouille bipède trapue à peau VERT VIF, grosse bouche jaune, grande MÈCHE bleue spiralée sur le haut "
		"de la tête (boucle de cheveux), ventre jaune orné d'une SPIRALE, dos vert rebondi, doigts palmés "
		"jaunes"),
	("MENTALI", 196, "Mentali", "espeon",
		"félin élégant à fourrure LAVANDE rose-violet pâle, grandes oreilles pointues à intérieur bleu sombre, "
		"DEUX LONGUES queues fines fourchues qui se terminent en pointes jumelles, petit joyau rouge au front, "
		"dos souple"),
	("NOCTALI", 197, "Noctali", "umbreon",
		"quadrupède fin au pelage NOIR de charbon, des ANNEAUX JAUNES dorés lumineux sur le front, les oreilles "
		"pointues et les cuisses, queue noire pointue, oreilles dressées"),
	("CORNEBRE", 198, "Cornèbre", "murkrow",
		"petit oiseau BLEU NUIT sombre au dos arrondi, un grand CHAPEAU de plumes pointues sombres en forme de "
		"chapeau de sorcier sur le crâne, longue queue en touffe de plumes noires en éventail avec un petit "
		"cercle rouge, ailes repliées, pattes sombres"),
	("ROIGADA", 199, "Roigada", "slowking",
		"créature ROSE rondelette bipède, grosse COQUILLE BLANC-GRIS pointue en tiare posée sur le crâne, collerette "
		"ROUGE ORANGÉE en cape autour du cou, lourde queue rose épaisse qui se termine en pointe, dos rose"),
	("QULBUTOKE", 202, "Qulbutoké", "wobbuffet",
		"créature BLEU CIEL en forme de grosse goutte ou de poire, lisse et sans cou, bras courts levés, une "
		"petite QUEUE NOIRE courbée aux yeux dessinés dans le dos, petits pieds ronds"),
	("STEELIX", 208, "Steelix", "steelix",
		"immense serpent de roche métallique en SEGMENTS GRIS-ACIER bleutés, tête carrée en pierre dotée de "
		"mâchoires de rochers, corps divisé en blocs arrondis, deux grosses pointes sur la nuque, queue "
		"segmentée terminée en pointes de pierre"),
	("CIZAYOX", 212, "Cizayox", "scizor",
		"insecte humanoïde ROUGE métallique, DEUX énormes PINCES rouges aux bords noirs à la place des mains, "
		"petites ailes translucides tenues dans le dos, crête rouge pointue sur la tête, torse rouge à plaques "
		"gris sombre, fines jambes rouges"),
	("SCARHINO", 214, "Scarhino", "heracross",
		"gros scarabée BLEU roi massif, carapace dorsale bleue en deux demi-coques lisses, une longue CORNE "
		"fourchue sur la tête, grosses pinces blanches aux bras, petites ailes cachées sous la carapace, pattes "
		"épaisses à griffes"),
	("FARFURET", 215, "Farfuret", "sneasel",
		"créature souple BLEU-VERT SOMBRE, grandes OREILLES pointues roses, trois plumes ROSES effilées qui "
		"pendent du bas du dos comme une queue, de grosses GRIFFES blanches au bout de chaque membre, dos "
		"voûté et agile"),
	("TEDDIURSA", 216, "Teddiursa", "teddiursa",
		"petit ours en peluche ORANGE doré, grandes oreilles rondes à intérieur noir, un CROISSANT de lune "
		"crème sur le front, pelage rond et doux, dos rebondi, petites griffes blanches, queue minuscule"),
	("URSARING", 217, "Ursaring", "ursaring",
		"grand ours bipède massif au pelage BRUN, un grand ANNEAU crème jaune sur le ventre, épaisses touffes "
		"de poils en frange au col et aux épaules, museau clair, gros dos puissant, longues griffes blanches"),
	("AIRMURE", 227, "Airmure", "skarmory",
		"grand oiseau à plumage d'ACIER GRIS-BLEU argenté, ailes métalliques tranchantes en lames avec des plumes "
		"ROUGES à la bordure inférieure, ailes déployées en V, longue queue d'ailettes d'acier en rangée, bec "
		"crochu"),
	("MALOSSE", 228, "Malosse", "houndour",
		"jeune chien NOIR aux flancs et jambes sombres, museau ORANGE, bandes d'os blanc-gris autour "
		"des oreilles et sur le dos, bracelets d'os blanc aux pattes, queue noire pointue en pointe de flèche"),
	("DEMOLOSSE", 229, "Démolosse", "houndoom",
		"grand chien démoniaque NOIR aux flancs musclés, museau ORANGE, deux grandes cornes grises recourbées en "
		"arrière sur la tête, plaques d'os blanc-gris sur le dos, bracelets d'os aux pattes, longue queue fine "
		"noire terminée en pointe de flèche"),
	("HYPOROI", 230, "Hyporoi", "kingdra",
		"hippocampe dragon BLEU vif, ventre jaune orangé, longues nageoires rayonnantes sur le dos, nageoires "
		"claires en voiles gris-blanc, longues épines bleues en ramure au sommet de la tête, queue enroulée "
		"en spirale"),
	("PHANPY", 231, "Phanpy", "phanpy",
		"petit éléphanteau BLEU-VERT turquoise clair, trompe courte repliée, grandes oreilles ROUGES qui "
		"retombent des deux côtés de la tête, dos rond et lisse, petite queue, pattes courtes à sabots blancs"),
	("DONPHAN", 232, "Donphan", "donphan",
		"éléphant cuirassé GRIS bleuté, dos recouvert de plaques d'ARMURE ROULÉE gris sombre en bandes qui "
		"forment un arceau et se terminent en pointes, défenses blanches, oreilles aplaties vers l'arrière, "
		"pattes courtes"),
	("PORYGON2", 233, "Porygon2", "porygon2",
		"créature numérique en forme d'oiseau géométrique ROUGE vif, un grand BEC bleu plat, une queue BLEUE "
		"en lame levée, pattes en boudins BLEUS arrondis, corps lisse en tubes ronds rouges et bleus"),
	("ECREMEUH", 241, "Écrémeuh", "miltank",
		"vache quadrupède à peau ROSE tachée de NOIR sur le dos et la tête, cornes noires courtes, tête "
		"pointue, UN PIS crème rond sous le ventre, queue fine terminée par une touffe noire, sabots noirs"),
	("LEUPHORIE", 242, "Leuphorie", "blissey",
		"grande créature ROSE ronde et douce comme un ballon, une coiffure de grosses bouclettes roses, petites "
		"ailes DÉPLOYÉES plumeuses blanc-vert sur les côtés, une poche crème ovale au ventre, petits pieds "
		"roses"),
	("RAIKOU", 243, "Raikou", "raikou",
		"grand quadrupède félin élancé au pelage JAUNE vif marqué de grosses RAYURES NOIRES en éclair, un nuage "
		"VIOLET grisâtre en crinière qui retombe sur le dos, longue queue fine en ZIGZAG bleu clair "
		"étoilée, pattes puissantes à griffes crème"),
	("ENTEI", 244, "Entei", "entei",
		"grand quadrupède puissant au pelage BRUN, épaisse crinière brune hirsute, DEUX grandes pointes grises "
		"en lames qui s'élèvent du dos comme des cristaux, une fumée grise qui s'échappe de la croupe, "
		"bracelets noirs aux pattes, queue brune courte"),
	("EMBRYLEX", 246, "Embrylex", "larvitar",
		"petit reptile bipède trapu à peau VERT TERNE, une CORNE conique sur la tête, une rangée de petites "
		"pointes vert foncé le long du dos et de la courte queue, taches ROUGES et noires sur le ventre "
		"(peu visibles de dos), petits bras"),
	("YMPHECT", 247, "Ymphect", "pupitar",
		"créature en forme de COCON BLEU-GRIS dur comme une carapace de roche, lisse et blindée, avec de grandes "
		"PIQUES triangulaires qui hérissent le haut du dos et la tête, petite nageoire pointue sur le bas du "
		"corps"),
	("LUGIA", 249, "Lugia", "lugia",
		"grand oiseau-dragon à plumage BLANC argenté, ailes immenses aux grandes plumes digitées DÉPLOYÉES, "
		"ventre bleu pâle, rangée de PIQUES bleu foncé sur le dos, long cou et longue queue blanche à pointes "
		"bleu marine"),
	("HO_OH", 250, "Ho-Oh", "ho_oh",
		"majestueux grand oiseau au plumage ROUGE vif sur le corps et les ailes, ailes immenses DÉPLOYÉES aux "
		"plumes bordées de VERT, ventre blanc, crête dorée sur la tête, longue queue de plumes ORANGE doré "
		"et jaunes"),
	("CELEBI", 251, "Celebi", "celebi",
		"minuscule créature VERT TENDRE à tête en forme de goutte pointue vers l'arrière, deux petites ANTENNES "
		"courbes, petites ailes translucides transparentes sur le dos (légèrement déployées), bras fins, une "
		"petite jambe verte foncée"),
]
ESPECES = sorted(ESPECES + ESPECES_SUITE, key=lambda e: e[1])

## Pokémon du monde qui marchent (planche 4 × 4) : identifiant -> (hauteur en jeu [D], ancre de forme,
## description du monde SANS nom, mouvement).
MARCHE: dict[str, tuple[int, str, str, str]] = {
	"GERMIGNON": (60, "POKE_BULBIZARRE_NE_r1.png",
		"petite créature quadrupède vert pâle au corps rond et doux, grosse tête ronde aux grands yeux rouges "
		"bienveillants, une GRANDE FEUILLE vert tendre plantée au sommet du crâne qui se balance, un collier de "
		"petits bourgeons vert foncé autour du cou, quatre courtes pattes. Allure douce et têtue.",
		"marche à quatre pattes en 4 images, petits pas réguliers, la feuille de la tête qui se balance"),
	"HERICENDRE": (58, "POKE_SALAMECHE_NE_r4.png",
		"petite créature allongée façon musaraigne qui marche à quatre pattes, DOS BLEU NUIT, ventre, pattes et "
		"long museau CRÈME, yeux mi-clos en petite fente, quatre petites taches ROUGES sur le bas du dos d'où "
		"sort une petite COLLERETTE DE FLAMMES orange (calme, basse). Allure timide.",
		"marche à quatre pattes en 4 images, petits pas rapides, les flammes du dos qui vacillent"),
	"KAIMINUS": (62, "POKE_CARAPUCE_NE_r1.png",
		"petit crocodile bipède BLEU au ventre jaune pâle marqué d'un motif en V, grosse tête à grande mâchoire "
		"souriante avec deux petites dents, yeux rouges vifs, une CRÊTE d'écailles ROUGES pointues sur le dos "
		"et la queue. Allure joueuse.",
		"marche debout en 4 images, petits pas sautillants, la queue qui se balance"),
}

## Révisions des planches de marche (r3 avec ancres, r4 sans ; puis r5, r6…) : (ancre de forme,
## description). Elles priment sur les essais précédents.
MARCHE_REVISIONS: dict[str, list[tuple[str, str]]] = {
	"HERICENDRE": [("POKE_BULBIZARRE_NE_r1.png",
		"petite créature POTELÉE en forme de poire qui marche à quatre pattes, DOS BLEU NUIT lisse, ventre, museau "
		"et pattes CRÈME, museau court et arrondi pointé vers l'avant, yeux fermés en deux petits traits, et sur le "
		"bas du dos quatre petites taches ROUGES d'où sortent de petites FLAMMES orange et jaunes, visibles dans "
		"toutes les poses. Allure timide, ronde et douce (pas une musaraigne, pas un fourmilier).")],
}
## Essais relus et écartés (jamais retenus).
ECARTES: set[str] = {"JOHTO_MONDE_HERICENDRE_r2", "JOHTO_MONDE_HERICENDRE_r4"}

## Pokémon d'ambiance en boucle (feuille 4 × 1) : identifiant -> (hauteur en jeu [D], description, pose).
BOUCLE: dict[str, tuple[int, str, str]] = {
	"SUICUNE": (190,
		"un grand quadrupède légendaire élégant et calme, au pelage BLEU CIEL tacheté de LOSANGES BLANCS, une "
		"longue CRINIÈRE VIOLETTE en nuage derrière la tête, DEUX longs RUBANS BLANCS ondulants qui partent "
		"du dos, un ornement de front en CRISTAL blanc, yeux rouges calmes, pattes fines et longues",
		"DEBOUT sur ses quatre pattes, de FACE (tourné vers le bas de l'écran), la tête haute, digne"),
	"ENTEI": (190,
		"un grand quadrupède légendaire massif et puissant, au pelage BRUN ROUX, une épaisse CRINIÈRE GRISE "
		"fumante comme un nuage de cendre sur le dos, un masque facial BLANC à pointes et un plastron doré "
		"sur le front, des MANCHETTES grises aux pattes, des pointes jaunes sur les flancs, yeux rouges",
		"DEBOUT sur ses quatre pattes, de FACE (tourné vers le bas de l'écran), la tête haute, imposant"),
	"LUGIA": (260,
		"un très grand oiseau-dragon légendaire au corps BLANC ARGENTÉ lisse, grandes ailes dont les plumes du "
		"bout sont comme des MAINS, des plaques BLEU MARINE sur le dos, sous les yeux et au bout de la queue, "
		"longue queue fine, cou long, yeux calmes",
		"en VOL STATIONNAIRE au-dessus de l'eau, de FACE, les grandes ailes à demi déployées, le bas du corps à "
		"environ 40 px au-dessus de la ligne des pieds (rien ne touche cette ligne)"),
	"HO_OH": (240,
		"un très grand oiseau légendaire au plumage ROUGE vif, ventre BLANC, une ligne VERTE au bord des ailes, "
		"une longue QUEUE de plumes dorées et vertes, une crête de plumes JAUNES sur la tête, bec jaune, "
		"pattes grises",
		"POSÉ debout, de FACE, les grandes ailes à demi ouvertes, la tête haute, majestueux"),
}

## Ce que le vent fait onduler (image 3 de la boucle) ; défaut : celui de Suicune.
VENT: dict[str, str] = {"ENTEI": "la crinière de fumée grise", "LUGIA": "le bout des ailes et la queue",
	"HO_OH": "les plumes de la queue et de la crête"}

## Icônes du Sac (une planche, gabarit de menu_peint).
OBJETS = ("UI_OBJETS_JOHTO_EVOLUTION", [
	("kings_rock", "la ROCHE ROYALE : une petite pierre GRIS-ARGENT taillée en forme de COURONNE à trois "
		"pointes arrondies, un anneau doré sombre à la base, surface minérale facettée"),
	("metal_coat", "la PEAU MÉTAL : une fine pellicule de MÉTAL ARGENTÉ souple, repliée en un petit coussin "
		"carré ondulé aux plis doux, reflets froids bleutés"),
	("dragon_scale", "l'ÉCAILLE DRACO : une grande ÉCAILLE ovale et épaisse, BLEU-VERT irisé, à nervures "
		"concentriques, bord plus clair, brillante"),
	("up_grade", "l'AMÉLIORATOR : un petit APPAREIL électronique arrondi, coque translucide ROUGE et BLEUE "
		"laissant voir un circuit, deux petites diodes vertes"),
], [f"{menu_peint._I}moon_stone.webp", f"{menu_peint._I}nugget.webp"], "objet")

HEROS = "PERSO_P2_PEINT_r1.png"
PROMPT_MONDE_SANS = "Aucune image n'est jointe."


def _espece(ident: str) -> tuple[str, int, str, str, str]:
	return next(e for e in ESPECES if e[0] == ident)


# --- Prompts -------------------------------------------------------------------------------------

## Révisions du sujet de dos après trois refus (r4 à r6, puis r7 à r9…) : elles priment.
REVISIONS: dict[str, list[str]] = {
	"GERMIGNON": ["petit dinosaure herbivore de dessin animé à quatre pattes, peau VERT PÂLE lisse, tête ronde "
		"portant UNE LARGE FEUILLE vert tendre en forme de goutte, dressée puis courbée vers l'arrière, un collier "
		"de petites boules VERT FONCÉ autour du cou, dos rond et lisse, très petite queue"],
}


def prompt_dos(ident: str, r: int) -> str:
	k = (r - 1) % 3 + 1
	sujet = REVISIONS[ident][(r - 1) // 3 - 1] if r > 3 else _espece(ident)[4]
	return rb.DOS_RB.format(nom=rb.NOM[k - 1], ancres=rb.ANCRES[k - 1], sujet=sujet) \
		.replace("Kanto 2026", "Pokemake")


def prompt_marche(ident: str, avec: bool, revision: int = 0) -> str:
	hauteur, ancre, description, mouvement = MARCHE[ident]
	if revision:
		ancre, description = MARCHE_REVISIONS[ident][revision - 1]
	ancres = (f"Images jointes : le héros du jeu ({HEROS.removesuffix('.png')}) = ancre de STYLE ; "
		f"{ancre.removesuffix('.png')} = une autre créature du jeu déjà validée : même rendu, même finesse, "
		"même gabarit de planche, garde ses proportions comme repère de taille (celle-ci est de taille "
		"comparable).") if avec else PROMPT_MONDE_SANS
	return f"""MONDE_{ident} — planche d'animation d'une créature du monde d'un jeu d'aventure 2D peint (elle suit le héros).
{ancres}
Style : créature peinte simplifiée, même finesse que le héros du jeu, contour fin coloré sans trait noir, volumes peints doux. Ni pixel art, ni 3D, ni anime aux contours noirs.
LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; volumes conservés par un ombrage doux ; aucune teinte dorée ou orangée, aucun liseré chaud ; ombres propres neutres, légèrement bleutées.

CRÉATURE (identique dans toutes les images) : {description}

PLANCHE D'ANIMATION (spritesheet) : image portrait 1024 × 1536, fond avec une vraie transparence (canal alpha, aucun damier dessiné). Grille invisible de 4 colonnes × 4 lignes ; chaque cellule fait 256 × 384 px et contient UNE pose de la créature, entière, centrée horizontalement, les pieds posés sur la même ligne horizontale à 60 px du bas de la cellule, à la même taille dans toutes les cellules (environ 170 px de haut). Aucune pose ne déborde de sa cellule.
- Ligne 1 : de face (vers le bas de l'écran).
- Ligne 2 : de profil, vers la gauche.
- Ligne 3 : de profil, vers la droite.
- Ligne 4 : de dos (vers le haut de l'écran).
- Colonnes : {mouvement}.
Vue : la même vue de dessus de trois quarts que le jeu (caméra un peu au-dessus, on voit un peu le dessus de la créature). Pas de perspective, pas d'ombre au sol, pas de sol, pas de texte, pas de numéros, pas de cadres autour des cellules.
Les couleurs, les proportions et la tête doivent être EXACTEMENT les mêmes dans les 16 poses.
"""


def prompt_boucle(ident: str, avec: bool) -> str:
	_h, description, pose = BOUCLE[ident]
	mouvant = VENT.get(ident, "la crinière et les rubans")
	ancres = ("Images jointes : l'illustration officielle de la créature (anatomie, couleurs et proportions "
		"seulement, PAS son rendu ni sa pose) ; artikodin_sheet et evoli_sheet = créatures déjà peintes pour le "
		"monde du jeu : même rendu peint simplifié, même contour fin coloré, même finesse, même angle de vue.") \
		if avec else PROMPT_MONDE_SANS
	return f"""MONDE_{ident} — planche d'animation d'une créature du monde d'un jeu d'aventure 2D peint : une créature légendaire POSÉE, que le joueur découvre.
{ancres}
Style : créature peinte simplifiée comme les planches du jeu, formes rondes et douces, peu de détails, contour fin coloré sans trait noir, volumes doux. Ni pixel art, ni 3D, ni anime aux contours noirs.
LUMIÈRE NE (neutre) : lumière de milieu de journée, diffuse et blanche, venant légèrement du haut à gauche ; aucune teinte dorée ; ombres propres neutres.

CRÉATURE (identique dans toutes les images) : {description}.
POSE : {pose}. Strictement de face et presque symétrique. Vue de dessus de trois quarts comme le jeu (caméra un peu au-dessus).

PLANCHE D'ANIMATION : image paysage 1536 × 1024, fond avec une vraie transparence (canal alpha, aucun damier dessiné). UNE seule ligne de 4 images, de gauche à droite, chacune dans une colonne invisible de 384 px, à la MÊME échelle (environ 330 px de haut), les pattes de toutes les images sur une même ligne horizontale à 170 px du bas de l'image :
- Image 1 : au repos.
- Image 2 : elle INSPIRE (la poitrine se gonfle un peu, la tête monte légèrement).
- Image 3 : un léger souffle de VENT fait onduler {mouvant}.
- Image 4 : retour au repos.
Aucune ombre portée, aucun sol, aucun décor, aucune lueur, aucun texte, aucun chiffre.
"""


def images() -> list[dict]:
	"""Tous les essais : {ident, sorte, r, nom, fichier, jointes, texte}."""
	liste = []
	for ident, num, *_ in ESPECES:
		for r in range(1, 3 * len(REVISIONS.get(ident, [])) + 4):
			liste.append({"ident": ident, "sorte": "dos", "r": r, "nom": f"JOHTO_DOSRB_{ident}_r{r}",
				"jointes": [OFFICIEL / f"{num:03d}.png"] if r % 3 == 1 else [], "texte": prompt_dos(ident, r)})
		if ident in MARCHE:
			for r in range(1, 2 * len(MARCHE_REVISIONS.get(ident, [])) + 3):
				avec, revision = r % 2 == 1, (r - 1) // 2
				ancre = MARCHE_REVISIONS[ident][revision - 1][0] if revision else MARCHE[ident][1]
				liste.append({"ident": ident, "sorte": "monde", "r": r, "nom": f"JOHTO_MONDE_{ident}_r{r}",
					"jointes": [ANCRES / HEROS, ANCRES / ancre] if avec else [],
					"texte": prompt_marche(ident, avec, revision)})
		if ident in BOUCLE:
			for r, avec in ((1, True), (2, False)):
				liste.append({"ident": ident, "sorte": "monde", "r": r, "nom": f"JOHTO_MONDE_{ident}_r{r}",
					"jointes": [OFFICIEL / f"{num:03d}.png", PEINTS / "artikodin_sheet.png",
						PEINTS / "evoli_sheet.png"] if avec else [],
					"texte": prompt_boucle(ident, avec)})
	ident, objets, ancres, categorie = OBJETS
	liste.append({"ident": ident, "sorte": "objets", "r": 1, "nom": f"{ident}_r1",
		"jointes": [RACINE / a for a in ancres],
		"texte": menu_peint._prompt(ident, objets, ancres, categorie).replace("Kanto 2026", "Pokemake")})
	for im in liste:
		im["fichier"] = PROMPTS / f"{im['nom']}.txt"
	return liste


def prompts() -> None:
	PROMPTS.mkdir(parents=True, exist_ok=True)
	for im in images():
		im["fichier"].write_text(im["texte"] + "\n", encoding="utf-8")
	print(len(images()), "prompts dans", PROMPTS.relative_to(RACINE))


# --- Génération ----------------------------------------------------------------------------------

def _journal(ligne: str) -> None:
	ART.mkdir(parents=True, exist_ok=True)
	with JOURNAL.open("a", encoding="utf-8") as f:
		f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + ligne + "\n")


def _essai(im: dict) -> bool:
	if (ART / f"{im['nom']}.png").exists():
		return True
	manquantes = [str(j) for j in im["jointes"] if not Path(j).exists()]
	if manquantes:
		print("ANCRE ABSENTE", im["nom"], manquantes, flush=True)
		return False
	cmd = [str(ICI / "generer.sh"), im["nom"], str(im["fichier"])] + [str(j) for j in im["jointes"]]
	p = subprocess.run(cmd, cwd=RACINE, capture_output=True, text=True)
	ok = p.returncode == 0 and (ART / f"{im['nom']}.png").exists()
	if not ok:
		cause = "moderation_blocked" if "moderation_blocked" in p.stderr else p.stderr.strip()[-160:]
		_journal(f"REFUS {im['nom']} ({'avec' if im['jointes'] else 'sans'} jointe) : {cause}")
	print(("OK    " if ok else "REFUS "), im["nom"], flush=True)
	return ok


def _lot(cle: tuple[str, str]) -> bool:
	"""Essais de la dernière révision seulement (les précédents sont faits ou refusés), dans l'ordre,
	jusqu'au premier réussi ; rien à faire si un essai retenu existe déjà dans cette révision."""
	ident, sorte = cle
	essais = [im for im in images() if im["ident"] == ident and im["sorte"] == sorte]
	pas = 3 if sorte == "dos" else 2
	derniers = essais[-pas:] if sorte != "objets" else essais
	return any(_essai(im) for im in derniers if im["nom"] not in ECARTES)


def generer(idents: list[str], sortes: set[str]) -> None:
	prompts()
	cles = []
	for im in images():
		cle = (im["ident"], im["sorte"])
		if (not idents or im["ident"] in idents) and (not sortes or im["sorte"] in sortes) and cle not in cles:
			cles.append(cle)
	with ThreadPoolExecutor(3) as ex:
		res = dict(zip(cles, ex.map(_lot, cles)))
	print("réussis :", sum(res.values()), "/", len(res), "; refusés :", [k for k, v in res.items() if not v])


def retenu(ident: str, sorte: str) -> Path | None:
	"""Le dernier essai réussi et non écarté (une révision prime sur les essais d'avant)."""
	choix = None
	for im in images():
		if im["ident"] == ident and im["sorte"] == sorte and (ART / f"{im['nom']}.png").exists() \
				and im["nom"] not in ECARTES:
			choix = ART / f"{im['nom']}.png"
	return choix
	return None


def liste() -> None:
	for im in images():
		print(f"{im['nom']:<40} {'ok' if (ART / (im['nom'] + '.png')).exists() else '--'}")


# --- Préparation ---------------------------------------------------------------------------------

def preparer() -> None:
	SORTIE.mkdir(parents=True, exist_ok=True)
	n = 0
	for ident, num, *_ in ESPECES:
		p = retenu(ident, "dos")
		if p is None:
			continue
		im = Image.open(p).convert("RGBA")
		if im.getchannel("A").getextrema()[0] > 250:
			im = menu_peint._transparente(im)
		rb._poser(rb._recadrer(rb._propre(im))).save(SORTIE / f"dos_rb_{num:03d}.png")
		n += 1
	print(n, "dos préparés dans", SORTIE)
	source = retenu(OBJETS[0], "objets")
	if source:
		propre = SORTIE / f"{OBJETS[0]}_alpha.png"
		menu_peint._transparente(Image.open(source)).save(propre)
		SORTIE_ITEMS = SORTIE / "items"
		SORTIE_ITEMS.mkdir(exist_ok=True)
		preparer_menu._objets(propre, SORTIE_ITEMS, [i for i, _ in OBJETS[1]])
		print("icônes préparées dans", SORTIE_ITEMS)


def integrer() -> None:
	n = 0
	for _ident, num, *_ in ESPECES:
		src = SORTIE / f"dos_rb_{num:03d}.png"
		if src.exists():
			(DOS_JEU / src.name).write_bytes(src.read_bytes())
			n += 1
	print(n, "dos copiés dans", DOS_JEU.relative_to(RACINE))
	for ident, _t in OBJETS[1]:
		src = SORTIE / "items" / f"{ident}.webp"
		if src.exists():
			(ITEMS / src.name).write_bytes(src.read_bytes())
			print("icône", src.name)


# --- Monde : manifeste, feuilles, catalogue -----------------------------------------------------

## Identifiant de catalogue (planche, en français comme les fiches) de chaque Pokémon du monde.
def id_monde(ident: str) -> str:
	return ident.lower()


def entrees_monde() -> tuple[list[dict], list[dict]]:
	"""Entrées « pokemon » (marche) et « pokemon_boucles » (ambiance) des planches retenues."""
	marche, boucles = [], []
	for ident, (hauteur, *_r) in MARCHE.items():
		source = retenu(ident, "monde")
		if source:
			marche.append({"id": id_monde(ident), "source": source.name,
				"sortie": f"assets/sprites/pokemon/painted/{id_monde(ident)}_sheet.png", "hauteur": hauteur,
				"nettoyer": True, "note": "série Johto (art des Pokémon de Johto, 2026-11-04)"})
	for ident, (hauteur, *_r) in BOUCLE.items():
		source = retenu(ident, "monde")
		if source:
			boucles.append({"id": id_monde(ident), "source": source.name,
				"sortie": f"assets/sprites/pokemon/painted/{id_monde(ident)}_sheet.png", "hauteur": hauteur,
				"colonnes": 4, "seuil_alpha": 24, "ordre_colonnes": ["repos", "inspire", "vent", "repos_2"],
				"note": "série Johto (art des Pokémon de Johto, 2026-11-04), une direction, 4 images en boucle"})
	return marche, boucles


def monde_integrer() -> None:
	"""Ajoute (ou remplace) les entrées de la série dans manifeste.json, puis découpe SEULEMENT ces
	planches avec le Preparateur (catalogue existant conservé ; les autres planches ne sont pas
	recoupées)."""
	import json
	import preparer
	marche, boucles = entrees_monde()
	chemin = ICI / "manifeste.json"
	manifeste = json.loads(chemin.read_text())
	for section, entrees in (("pokemon", marche), ("pokemon_boucles", boucles)):
		ids = {e["id"] for e in entrees}
		manifeste[section] = [e for e in manifeste[section] if e.get("id") not in ids] + entrees
	chemin.write_text(json.dumps(manifeste, ensure_ascii=False, indent=1) + "\n")
	partiel = dict(manifeste, personnages=[], pokemon=marche, attentes=[], pokemon_fixes=[],
		pokemon_boucles=boucles)
	p = preparer.Preparateur(partiel, ART)
	p.catalogue = json.loads((RACINE / "assets/world/catalogue.json").read_text())
	p.personnages()
	p.pokemon_boucles()
	p.ecrire_catalogue()
	print(len(marche), "planche(s) de marche,", len(boucles), "feuille(s) d'ambiance ; lancer ensuite :",
		"godot --headless --path . -s res://tools/build_character_frames.gd")


# --- Planche de contact --------------------------------------------------------------------------

def _case(im: Image.Image, cote: int, fond=None) -> Image.Image:
	im = im.convert("RGBA")
	boite = im.getchannel("A").getbbox()
	if boite:
		im = im.crop(boite)
	im.thumbnail((cote - 16, cote - 16), Image.LANCZOS)
	out = Image.new("RGBA", (cote, cote), fond or (0, 0, 0, 0))
	out.alpha_composite(im, ((cote - im.width) // 2, cote - 8 - im.height))
	return out


def contact(pilote: bool) -> Path:
	"""Une ligne par espèce : artwork officiel | dos RB préparé | planche du monde (brute) ; puis les
	icônes du Sac."""
	FICHE.mkdir(parents=True, exist_ok=True)
	idents = PILOTE if pilote else [e[0] for e in ESPECES]
	case, fond = 300, (236, 233, 226, 255)
	f, g = rb._police(26), rb._police(20)
	largeur = max(40 + case * 2 + 760, 40 + 4 * 360)
	hauteur = 30 + len(idents) * (case + 50) + case + 90
	W = Image.new("RGBA", (largeur, hauteur), fond)
	d = ImageDraw.Draw(W)
	y = 20
	for ident in idents:
		_i, num, fr, _id, _s = _espece(ident)
		d.text((20, y), f"{num} {fr}", font=f, fill=(30, 30, 30))
		y += 34
		W.alpha_composite(_case(Image.open(OFFICIEL / f"{num:03d}.png"), case), (20, y))
		dos = SORTIE / f"dos_rb_{num:03d}.png"
		if dos.exists():
			W.alpha_composite(_case(Image.open(dos), case, (205, 214, 200, 255)), (20 + case, y))
		else:
			d.text((40 + case, y + 140), "dos : absent", font=g, fill=(190, 40, 40))
		monde = retenu(ident, "monde")
		if monde:
			planche = Image.open(monde).convert("RGBA")
			planche.thumbnail((740, case), Image.LANCZOS)
			W.alpha_composite(planche, (40 + 2 * case, y))
		elif ident in MARCHE or ident in BOUCLE:
			d.text((60 + 2 * case, y + 140), "monde : absent", font=g, fill=(190, 40, 40))
		y += case + 16
	d.text((20, y), "Icônes du Sac (256 px et 112 px, taille de la liste)", font=f, fill=(30, 30, 30))
	y += 40
	for k, (ident, _t) in enumerate(OBJETS[1]):
		p = SORTIE / "items" / f"{ident}.webp"
		x = 20 + k * 360
		if not p.exists():
			d.text((x, y + 100), f"{ident} : absent", font=g, fill=(190, 40, 40))
			continue
		icone = Image.open(p).convert("RGBA")
		W.alpha_composite(icone.resize((220, 220), Image.LANCZOS), (x, y))
		W.alpha_composite(icone.resize((112, 112), Image.LANCZOS), (x + 225, y + 100))
	sortie = FICHE / ("planche-pilote.jpg" if pilote else "planche-complete.jpg")
	W.convert("RGB").save(sortie, quality=88)
	print(sortie.relative_to(RACINE))
	return sortie


if __name__ == "__main__":
	args = sys.argv[1:]
	pilote = "--pilote" in args
	sortes = {s for s, o in (("dos", "--dos"), ("monde", "--monde"), ("objets", "--objets")) if o in args}
	noms = [a for a in args if not a.startswith("--")]
	if "--prompts" in args:
		prompts()
	elif "--liste" in args:
		liste()
	elif "--preparer" in args:
		preparer()
	elif "--integrer" in args:
		integrer()
	elif "--monde-integrer" in args:
		monde_integrer()
	elif "--contact" in args:
		contact(pilote)
	else:
		if pilote and not noms:
			noms = PILOTE + ([OBJETS[0]] if not sortes or "objets" in sortes else [])
		generer(noms, sortes)
