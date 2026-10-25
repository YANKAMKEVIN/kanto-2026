#!/usr/bin/env python3
"""Planche de validation de DAF.7 « Identité » (DA-6) :
icône aux tailles réelles (lanceur du S24 : 48 dp ≈ 144 px), masques rond et carré arrondi,
icône thématique (monochrome), écran de démarrage système d'Android 12+ (K sur fond sombre),
image de démarrage de Godot (logo), écran titre (capture Mac en 2340 × 1080).

Usage : python3 tools/art/planche_daf7.py [capture_titre.png]
  (défaut : build/captures/daf7/title_valid.png, produite par tools/capture_title_ouv1.gd)
Sortie : docs/design/fiches-assets/daf-7-identite/planche.png
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
ICONES = RACINE / "assets/ui/icon"
SORTIE = RACINE / "docs/design/fiches-assets/daf-7-identite/planche.png"
POLICE = "/System/Library/Fonts/Supplemental/Arial.ttf"
POLICE_G = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FOND = (24, 22, 28)
TEXTE = (236, 230, 220)
GRIS = (160, 152, 140)
SPLASH_BG = (20, 16, 11)  # boot_splash/bg_color du projet


def police(taille: int, grasse: bool = False) -> ImageFont.FreeTypeFont:
	return ImageFont.truetype(POLICE_G if grasse else POLICE, taille)


def adaptive(masque: str, cote: int) -> Image.Image:
	img = Image.open(ICONES / "icon_fond_432.png").convert("RGBA")
	img.alpha_composite(Image.open(ICONES / "icon_premier_plan_432.png"))
	vue = img.crop((72, 72, 360, 360)).resize((cote * 4, cote * 4), Image.LANCZOS)
	m = Image.new("L", vue.size, 0)
	d = ImageDraw.Draw(m)
	if masque == "rond":
		d.ellipse((0, 0, vue.width - 1, vue.height - 1), fill=255)
	else:
		d.rounded_rectangle((0, 0, vue.width - 1, vue.height - 1), radius=vue.width * 0.3, fill=255)
	vue.putalpha(m)
	return vue.resize((cote, cote), Image.LANCZOS)


def monochrome(cote: int, fond: tuple, encre: tuple) -> Image.Image:
	mono = Image.open(ICONES / "icon_monochrome_432.png").crop((72, 72, 360, 360))
	base = Image.new("RGBA", mono.size, fond + (255,))
	teinte = Image.new("RGBA", mono.size, encre + (255,))
	base.paste(teinte, (0, 0), mono.split()[3])
	m = Image.new("L", mono.size, 0)
	ImageDraw.Draw(m).ellipse((0, 0, 287, 287), fill=255)
	base.putalpha(m)
	return base.resize((cote, cote), Image.LANCZOS)


def ecran_systeme(largeur: int, hauteur: int) -> Image.Image:
	"""Démarrage système d'Android 12+ : icône (premier plan) centrée, 240 dp ≈ 720 px sur S24."""
	ecran = Image.new("RGBA", (2340, 1080), (16, 16, 16, 255))
	k = Image.open(RACINE / "assets/ui/icon/icon_premier_plan_432.png").resize((720, 720), Image.LANCZOS)
	ecran.alpha_composite(k, ((2340 - 720) // 2, (1080 - 720) // 2))
	return ecran.resize((largeur, hauteur), Image.LANCZOS)


def main() -> None:
	capture = Path(sys.argv[1]) if len(sys.argv) > 1 else RACINE / "build/captures/daf7/title_valid.png"
	L = 2400
	planche = Image.new("RGBA", (L, 2200), FOND + (255,))
	d = ImageDraw.Draw(planche)
	d.text((60, 40), "DAF.7 « Identité » — planche de validation", font=police(54, True), fill=TEXTE)
	d.text((60, 110), "Icône : « K » du logo validé (OUV.1) sur un paysage peint à l'heure dorée (Codex). "
		"Aucune marque Nintendo ni Pokémon.", font=police(30), fill=GRIS)

	# 1. Icône aux tailles réelles, sur fond d'écran sombre et clair.
	y = 190
	d.text((60, y), "1. Icône du lanceur — tailles réelles en pixels (S24 : 48 dp ≈ 144 px)", font=police(36, True), fill=TEXTE)
	y += 60
	for i, (fond, nom) in enumerate((((32, 44, 70), "fond d'écran sombre"), ((214, 222, 230), "fond d'écran clair"))):
		x0, y0 = 60 + i * 1170, y
		d.rounded_rectangle((x0, y0, x0 + 1110, y0 + 330), radius=24, fill=fond)
		encre = (240, 240, 240) if i == 0 else (30, 30, 30)
		d.text((x0 + 24, y0 + 16), nom, font=police(26), fill=encre)
		x = x0 + 30
		for cote in (48, 96, 144, 192):
			planche.alpha_composite(adaptive("rond", cote), (x, y0 + 70 + (192 - cote)))
			d.text((x, y0 + 275), f"{cote}", font=police(24), fill=encre)
			x += cote + 40
		x += 20
		for cote in (144, 192):
			planche.alpha_composite(adaptive("carre", cote), (x, y0 + 70 + (192 - cote)))
			d.text((x, y0 + 275), f"{cote} (carré arrondi)", font=police(22), fill=encre)
			x += cote + 60
	y += 360

	# 2. Icône thématique et icône classique.
	d.text((60, y), "2. Icône thématique d'Android 13+ (monochrome) et icône classique (Android < 8, 192 px)", font=police(36, True), fill=TEXTE)
	y += 60
	x = 60
	for fond, encre in (((214, 227, 255), (40, 60, 110)), ((40, 52, 40), (190, 225, 180)), ((60, 40, 30), (250, 210, 170))):
		planche.alpha_composite(monochrome(144, fond, encre), (x, y))
		x += 184
	planche.alpha_composite(Image.open(ICONES / "icon_192.png").convert("RGBA"), (x + 60, y))
	planche.alpha_composite(Image.open(RACINE / "assets/ui/icon.png").convert("RGBA").resize((192, 192)), (x + 300, y))
	d.text((x + 300, y + 200), "icône du projet (512)", font=police(22), fill=GRIS)
	y += 260

	# 3. Démarrage : système puis Godot.
	d.text((60, y), "3. Démarrage sur le S24 (paysage) : écran système d'Android 12+, puis image de démarrage du jeu", font=police(36, True), fill=TEXTE)
	y += 60
	lw, lh = 1110, 512
	planche.alpha_composite(ecran_systeme(lw, lh), (60, y))
	splash = Image.new("RGBA", (2340, 1080), SPLASH_BG + (255,))
	img = Image.open(RACINE / "assets/ui/opening/splash_kanto_2026.png").convert("RGBA")
	img = img.resize((round(img.width * 1080 / img.height), 1080), Image.LANCZOS)
	splash.alpha_composite(img, ((2340 - img.width) // 2, 0))
	planche.alpha_composite(splash.resize((lw, lh), Image.LANCZOS), (60 + lw + 60, y))
	d.text((60, y + lh + 10), "a. système (Android 12+) : le K remplace le logo « GODOT » (fond : à voir sur S24)", font=police(26), fill=GRIS)
	d.text((60 + lw + 60, y + lh + 10), "b. boot_splash du jeu (inchangé depuis OUV.1)", font=police(26), fill=GRIS)
	y += lh + 70

	# 4. Écran titre.
	d.text((60, y), "4. Écran titre (capture Mac 2340 × 1080, sauvegarde valide)", font=police(36, True), fill=TEXTE)
	y += 60
	if capture.exists():
		titre = Image.open(capture).convert("RGBA").resize((lw, lh), Image.LANCZOS)
		planche.alpha_composite(titre, (60, y))
	notes = [
		"Écarts relevés (non corrigés, à trancher) :",
		"• Le décor n'est pas à l'heure dorée (dossier 13) :",
		"  Bourg Palette est rendu en lumière de jour.",
		"• Le logo n'a pas d'ombre douce propre (dossier 13) : son halo",
		"  seul le pose sur le décor ; « 2026 » se lit mal sur",
		"  les toits et le PNJ derrière lui.",
		"• Carte Continuer conforme (prénom, lieu, temps,",
		"  captures ; badges absents si 0). Boutons conformes.",
	]
	for i, ligne in enumerate(notes):
		d.text((60 + lw + 60, y + 10 + i * 46), ligne, font=police(28, i == 0), fill=TEXTE if i == 0 else GRIS)
	SORTIE.parent.mkdir(parents=True, exist_ok=True)
	planche.convert("RGB").save(SORTIE, optimize=True)
	print(SORTIE.relative_to(RACINE))


if __name__ == "__main__":
	main()
