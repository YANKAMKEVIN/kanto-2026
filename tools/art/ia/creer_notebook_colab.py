#!/usr/bin/env python3
"""Crée le notebook Google Colab qui repeint des dos 3D en illustrations (carte graphique
gratuite de Colab, le Mac de Kevin n'ayant que 8 Go de mémoire).

Entrées : pour chaque Pokémon, la passe couleur et la passe de profondeur de
tools/art/blender/rendre_pokemon.py (512 px). Elles sont incluses dans le notebook (base64) :
rien à téléverser. Le notebook télécharge à la fin kanto_dos_ia.zip (variantes + planche).
Usage : tools/art/ia/creer_notebook_colab.py dossier_passes sortie.ipynb
        nom_fichier:nom_anglais [...]   (ex. sal:charmander → sal_couleur.png, sal_profondeur.png)
"""
import base64
import io
import json
import sys

from PIL import Image, ImageFilter

TAILLE = 512


def b64(im):
	tampon = io.BytesIO()
	im.save(tampon, "PNG")
	return base64.b64encode(tampon.getvalue()).decode()


def entrees(dossier, cle):
	c = Image.open(f"{dossier}/{cle}_couleur.png").convert("RGBA").resize((TAILLE, TAILLE),
		Image.LANCZOS)
	blanc = Image.new("RGBA", c.size, (255, 255, 255, 255))
	blanc.alpha_composite(c)
	depart = blanc.convert("RGB")
	prof = Image.open(f"{dossier}/{cle}_profondeur.png").convert("RGB").resize((TAILLE, TAILLE),
		Image.LANCZOS)
	traits = depart.convert("L").point(lambda v: 255 if v < 110 else 0) \
		.filter(ImageFilter.MaxFilter(3)).convert("RGB")
	return {"depart": b64(depart), "profondeur": b64(prof), "traits": b64(traits),
		"alpha": b64(c.getchannel("A"))}


def cellule(type_, source):
	c = {"cell_type": type_, "metadata": {}, "source": source}
	if type_ == "code":
		c.update({"execution_count": None, "outputs": []})
	return c


INSTRUCTIONS = """# Kanto 2026 — dos des Pokémon repeints (essai)

1. Menu **Exécution → Modifier le type d'exécution** : choisir **GPU T4**, puis Enregistrer.
2. Menu **Exécution → Tout exécuter** (accepter l'avertissement « notebook non créé par Google »).
3. Patienter environ 5 à 8 minutes (installation, téléchargement des modèles, puis environ
   30 s par image).
4. À la fin, **kanto_dos_ia.zip** se télécharge tout seul : le laisser dans **Téléchargements**.

Ce que fait le notebook : chaque dos rendu en 3D sert de point de départ ; sa profondeur et ses
traits imposent la forme (ControlNet) ; un style entraîné sur les artworks officiels Pokémon
(LoRA) donne le rendu « illustration » ; le résultat est découpé à la silhouette exacte."""

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
    pipe.set_adapters(["pokemon"], adapter_weights=[0.75])
    LORA = True
except Exception as erreur:
    print("Style Pokémon (LoRA) non chargé :", erreur)
    LORA = False
print("Prêt. Style Pokémon :", LORA)"""

GENERER = """import base64, io, os, zipfile
from PIL import Image, ImageDraw, ImageFilter
from IPython.display import display

def image(b):
    return Image.open(io.BytesIO(base64.b64decode(b)))

POSITIF = ("official artwork of {nom} pokemon seen from behind, back view, ken sugimori style, "
    "clean lineart, flat cel shading, soft shadows, vibrant colors, white background, "
    "high quality illustration")
NEGATIF = ("front view, face, 3d render, cgi, plastic, blurry, low quality, text, watermark, "
    "signature, extra limbs, deformed, human, background scenery, shadow on ground")
FORCES = [0.45, 0.6, 0.75]   # part de l'image repeinte (0 = rendu 3D intact)
GRAINES = [7, 21]
os.makedirs("sorties", exist_ok=True)
vignettes = []
for cle, e in ENTREES.items():
    depart, prof, traits = image(e["depart"]), image(e["profondeur"]), image(e["traits"])
    alpha = image(e["alpha"]).convert("L").filter(ImageFilter.MaxFilter(3))
    ligne = [depart.convert("RGBA")]
    for force in FORCES:
        for graine in GRAINES:
            res = pipe(prompt=POSITIF.format(nom=e["nom"]), negative_prompt=NEGATIF,
                image=depart, control_image=[prof, traits], strength=force,
                num_inference_steps=28, guidance_scale=7.0,
                controlnet_conditioning_scale=[0.8, 0.6], control_guidance_end=[1.0, 0.8],
                generator=torch.Generator("cuda").manual_seed(graine)).images[0]
            res.save(f"sorties/{cle}_f{int(force*100)}_g{graine}_brut.png")
            decoupe = res.convert("RGBA"); decoupe.putalpha(alpha)
            decoupe.save(f"sorties/{cle}_f{int(force*100)}_g{graine}.png")
            ligne.append(decoupe)
            print(cle, force, graine, "ok")
    vignettes.append((cle, ligne))

T = 256
planche = Image.new("RGB", (T * 7, T * len(vignettes) + 30), (235, 240, 232))
d = ImageDraw.Draw(planche)
for i, titre in enumerate(["rendu 3D"] + [f"{int(f*100)} % · g{g}" for f in FORCES for g in GRAINES]):
    d.text((i * T + 6, 8), titre, fill=(0, 0, 0))
for r, (cle, ligne) in enumerate(vignettes):
    for i, im in enumerate(ligne):
        fond = Image.new("RGBA", im.size, (235, 240, 232, 255)); fond.alpha_composite(im)
        planche.paste(fond.convert("RGB").resize((T, T)), (i * T, 30 + r * T))
planche.save("sorties/planche.png")
display(planche)
with zipfile.ZipFile("kanto_dos_ia.zip", "w") as z:
    for f in os.listdir("sorties"):
        z.write(os.path.join("sorties", f), f)
from google.colab import files
files.download("kanto_dos_ia.zip")"""


def main():
	dossier, sortie = sys.argv[1], sys.argv[2]
	donnees = {}
	for paire in sys.argv[3:]:
		cle, nom = paire.split(":")
		donnees[cle] = {"nom": nom, **entrees(dossier, cle)}
	nb = {"nbformat": 4, "nbformat_minor": 5, "metadata": {"accelerator": "GPU",
		"colab": {"gpuType": "T4", "provenance": []},
		"kernelspec": {"name": "python3", "display_name": "Python 3"}},
		"cells": [
			cellule("markdown", INSTRUCTIONS),
			cellule("code", INSTALLER),
			cellule("code", CHARGER),
			cellule("code", "# Passes des dos 3D (Blender), incluses : rien à téléverser.\n"
				"ENTREES = " + json.dumps(donnees)),
			cellule("code", GENERER),
		]}
	json.dump(nb, open(sortie, "w", encoding="utf-8"), ensure_ascii=False)
	print(sortie, ", ".join(donnees))


if __name__ == "__main__":
	main()
