#!/usr/bin/env python3
"""Notebook Google Colab v2 : dos 3D repeints en illustrations, poussés plus loin.

Par rapport à la v1 (creer_notebook_colab.py) :
- l'artwork officiel de face du même Pokémon guide le style et les couleurs (IP-Adapter) ;
- agrandissement repeint : le résultat 512 px est agrandi à 1024 px puis repeint légèrement
  (même guidage), pour un trait et un modelé nets au premier plan ;
- tous les Pokémon dont les passes existent (dos3d_NNN.png et dos3d_NNN_profondeur.png).
Les entrées sont incluses dans le notebook (base64) ; à la fin, kanto_dos_ia_v2.zip se
télécharge (images 1024 découpées + planche). Relancer la dernière cellule reprend sans refaire
les images déjà produites.
Usage : tools/art/ia/creer_notebook_colab_v2.py dossier_passes dossier_artworks sortie.ipynb
"""
import base64
import glob
import io
import json
import os
import sys

from PIL import Image, ImageFilter

TAILLE = 512
NOMS = {"001": "bulbasaur", "004": "charmander", "007": "squirtle", "012": "butterfree",
	"016": "pidgey", "025": "pikachu", "041": "zubat", "072": "tentacool", "081": "magnemite",
	"093": "haunter", "095": "onix", "109": "koffing", "129": "magikarp"}


def b64(im):
	tampon = io.BytesIO()
	im.save(tampon, "PNG")
	return base64.b64encode(tampon.getvalue()).decode()


def entrees(dossier, artworks, num):
	c = Image.open(f"{dossier}/dos3d_{num}.png").convert("RGBA").resize((TAILLE, TAILLE),
		Image.LANCZOS)
	blanc = Image.new("RGBA", c.size, (255, 255, 255, 255))
	blanc.alpha_composite(c)
	depart = blanc.convert("RGB")
	prof = Image.open(f"{dossier}/dos3d_{num}_profondeur.png").convert("RGB").resize(
		(TAILLE, TAILLE), Image.LANCZOS)
	traits = depart.convert("L").point(lambda v: 255 if v < 110 else 0) \
		.filter(ImageFilter.MaxFilter(3)).convert("RGB")
	art = Image.open(f"{artworks}/{num}.png").convert("RGBA")
	fond = Image.new("RGBA", art.size, (255, 255, 255, 255))
	fond.alpha_composite(art)
	return {"nom": NOMS.get(num, "pokemon"), "depart": b64(depart), "profondeur": b64(prof),
		"traits": b64(traits), "alpha": b64(c.getchannel("A")),
		"artwork": b64(fond.convert("RGB").resize((384, 384), Image.LANCZOS))}


def cellule(type_, source):
	c = {"cell_type": type_, "metadata": {}, "source": source}
	if type_ == "code":
		c.update({"execution_count": None, "outputs": []})
	return c


INSTRUCTIONS = """# Kanto 2026 — dos des Pokémon repeints, v2

1. **Exécution → Modifier le type d'exécution** : **GPU T4**, Enregistrer.
2. **Exécution → Tout exécuter** (accepter l'avertissement).
3. Environ **25 à 35 minutes** (13 Pokémon × 4 variantes, chacune repeinte puis agrandie).
   Garder l'onglet ouvert.
4. À la fin, **kanto_dos_ia_v2.zip** se télécharge : le laisser dans **Téléchargements**.

Si la session s'interrompt : **Exécution → Tout exécuter** à nouveau ; les images déjà
produites sont gardées tant que la session n'a pas été réinitialisée.

Nouveautés : l'artwork officiel de face guide le style (IP-Adapter) ; agrandissement repeint en
1024 px."""

INSTALLER = """!nvidia-smi -L
!pip -q install -U diffusers transformers accelerate peft safetensors"""

CHARGER = """import torch
from diffusers import (ControlNetModel, DPMSolverMultistepScheduler,
    StableDiffusionControlNetImg2ImgPipeline)

controlnets = [
    ControlNetModel.from_pretrained("lllyasviel/control_v11f1p_sd15_depth",
        torch_dtype=torch.float16, variant="fp16"),
    ControlNetModel.from_pretrained("lllyasviel/control_v11p_sd15s2_lineart_anime",
        torch_dtype=torch.float16, variant="fp16"),
]
pipe = StableDiffusionControlNetImg2ImgPipeline.from_pretrained("Lykon/AnyLoRA",
    controlnet=controlnets, torch_dtype=torch.float16, safety_checker=None,
    requires_safety_checker=False).to("cuda")
pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config,
    use_karras_sigmas=True)
try:
    pipe.load_lora_weights("juliensimon/stable-diffusion-v1-5-pokemon-lora",
        weight_name="pytorch_lora_weights.safetensors", adapter_name="pokemon")
    pipe.set_adapters(["pokemon"], adapter_weights=[0.7])
    LORA = True
except Exception as erreur:
    print("Style Pokémon (LoRA) non chargé :", erreur)
    LORA = False
try:
    pipe.load_ip_adapter("h94/IP-Adapter", subfolder="models",
        weight_name="ip-adapter_sd15.safetensors")
    IPA = True
except Exception as erreur:
    print("IP-Adapter non chargé :", erreur)
    IPA = False
print("Prêt. Style Pokémon :", LORA, "· artwork en référence :", IPA)"""

GENERER = """import base64, io, os, zipfile
from PIL import Image, ImageDraw, ImageFilter
from IPython.display import display

def image(b):
    return Image.open(io.BytesIO(base64.b64decode(b)))

POSITIF = ("official artwork of {nom} pokemon seen from behind, back view, ken sugimori style, "
    "clean lineart, cel shading, soft shading, vibrant colors, white background, "
    "high quality illustration")
NEGATIF = ("front view, facing viewer, face, 3d render, cgi, plastic, blurry, low quality, "
    "text, watermark, signature, extra limbs, deformed, human, background scenery, "
    "shadow on ground")
FORCE = 0.6           # part repeinte de la première passe (0,6 = meilleur essai v1)
FORCE_AGRANDI = 0.35  # part repeinte de la passe agrandie (1024 px)
VARIANTES = [(0.35, 7), (0.35, 21), (0.55, 7), (0.55, 21)]  # (poids de l'artwork, graine)
os.makedirs("sorties", exist_ok=True)

def peindre(depart, controles, artwork, nom, force, ipa, graine, taille):
    args = dict(prompt=POSITIF.format(nom=nom), negative_prompt=NEGATIF, image=depart,
        control_image=controles, strength=force, num_inference_steps=28, guidance_scale=7.0,
        controlnet_conditioning_scale=[0.8, 0.6], control_guidance_end=[1.0, 0.8],
        height=taille, width=taille, generator=torch.Generator("cuda").manual_seed(graine))
    if IPA:
        pipe.set_ip_adapter_scale(ipa)
        args["ip_adapter_image"] = artwork
    return pipe(**args).images[0]

lignes = []
for num, e in ENTREES.items():
    depart, prof, traits = image(e["depart"]), image(e["profondeur"]), image(e["traits"])
    artwork = image(e["artwork"])
    alpha = image(e["alpha"]).convert("L")
    alpha_hd = alpha.resize((1024, 1024), Image.LANCZOS).filter(ImageFilter.MinFilter(5)) \\
        .filter(ImageFilter.GaussianBlur(1.0))
    ligne = [depart.convert("RGBA")]
    for ipa, graine in VARIANTES:
        sortie = f"sorties/{num}_ipa{int(ipa*100)}_g{graine}.png"
        if not os.path.exists(sortie):
            base = peindre(depart, [prof, traits], artwork, e["nom"], FORCE, ipa, graine, 512)
            grand = base.resize((1024, 1024), Image.LANCZOS)
            ctrl = [prof.resize((1024, 1024), Image.LANCZOS),
                traits.resize((1024, 1024), Image.LANCZOS)]
            fin = peindre(grand, ctrl, artwork, e["nom"], FORCE_AGRANDI, ipa, graine, 1024)
            fin = fin.convert("RGBA"); fin.putalpha(alpha_hd)
            fin.save(sortie)
            print(num, e["nom"], ipa, graine, "ok")
        ligne.append(Image.open(sortie))
    lignes.append((num, ligne))

T = 220
planche = Image.new("RGB", (T * 5, T * len(lignes) + 30), (235, 240, 232))
d = ImageDraw.Draw(planche)
for i, titre in enumerate(["rendu 3D"] + [f"artwork {int(a*100)} % · g{g}" for a, g in VARIANTES]):
    d.text((i * T + 6, 8), titre, fill=(0, 0, 0))
for r, (num, ligne) in enumerate(lignes):
    for i, im in enumerate(ligne):
        fond = Image.new("RGBA", im.size, (235, 240, 232, 255)); fond.alpha_composite(im.convert("RGBA"))
        planche.paste(fond.convert("RGB").resize((T, T)), (i * T, 30 + r * T))
    d.text((4, 30 + r * T + 4), num, fill=(0, 0, 0))
planche.save("sorties/planche.png")
display(planche)
with zipfile.ZipFile("kanto_dos_ia_v2.zip", "w") as z:
    for f in os.listdir("sorties"):
        z.write(os.path.join("sorties", f), f)
from google.colab import files
files.download("kanto_dos_ia_v2.zip")"""


def main():
	dossier, artworks, sortie = sys.argv[1:4]
	nums = sorted(os.path.basename(f)[6:9] for f in glob.glob(f"{dossier}/dos3d_???.png"))
	donnees = {n: entrees(dossier, artworks, n) for n in nums}
	nb = {"nbformat": 4, "nbformat_minor": 5, "metadata": {"accelerator": "GPU",
		"colab": {"gpuType": "T4", "provenance": []},
		"kernelspec": {"name": "python3", "display_name": "Python 3"}},
		"cells": [
			cellule("markdown", INSTRUCTIONS),
			cellule("code", INSTALLER),
			cellule("code", CHARGER),
			cellule("code", "# Passes des dos 3D et artworks officiels, inclus.\n"
				"ENTREES = " + json.dumps(donnees)),
			cellule("code", GENERER),
		]}
	json.dump(nb, open(sortie, "w", encoding="utf-8"), ensure_ascii=False)
	print(sortie, len(donnees), "Pokémon :", " ".join(nums))


if __name__ == "__main__":
	main()
