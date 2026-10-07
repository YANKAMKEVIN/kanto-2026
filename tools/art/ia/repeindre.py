#!/usr/bin/env python3
"""Repeint un rendu 3D de dos en illustration « artwork officiel » avec ComfyUI (local).

Le rendu couleur (tools/art/blender/rendre_pokemon.py) sert d'image de départ ; la passe de
profondeur et les traits du rendu guident la forme (ControlNet) ; un style Pokémon (LoRA
entraîné sur les artworks officiels) donne le rendu ; le résultat est découpé selon la
silhouette exacte du rendu (canal alpha).

Usage : tools/art/ia/repeindre.py couleur.png profondeur.png sortie.png --nom "charmander"
        [--debruitage 0.6] [--graine 7] [--lora 0.7] [--serveur http://127.0.0.1:8188]
ComfyUI doit tourner (~/dev/comfyui : venv/bin/python main.py --port 8188).
"""
import argparse
import json
import os
import shutil
import time
import urllib.request
import uuid

from PIL import Image, ImageFilter

COMFY = os.path.expanduser("~/dev/comfyui")
MODELE = "AnyLoRA_bakedVae_blessed_fp16.safetensors"
LORA = "pokemon_sugimori_sd15.safetensors"
CN_PROFONDEUR = "control_v11f1p_sd15_depth_fp16.safetensors"
CN_TRAITS = "control_v11p_sd15s2_lineart_anime_fp16.safetensors"
POSITIF = ("official artwork of {nom} pokemon seen from behind, back view, ken sugimori style, "
	"clean lineart, flat cel shading, soft shadows, vibrant colors, white background, "
	"high quality illustration")
NEGATIF = ("front view, face, 3d render, cgi, plastic, blurry, low quality, text, watermark, "
	"signature, extra limbs, deformed, human, background scenery, shadow on ground")
TAILLE = 512


def preparer(couleur, profondeur, dossier):
	"""Images d'entrée de ComfyUI : départ sur fond blanc, profondeur, traits (blanc sur noir)."""
	c = Image.open(couleur).convert("RGBA").resize((TAILLE, TAILLE), Image.LANCZOS)
	blanc = Image.new("RGBA", c.size, (255, 255, 255, 255))
	blanc.alpha_composite(c)
	depart = blanc.convert("RGB")
	p = Image.open(profondeur).convert("RGB").resize((TAILLE, TAILLE), Image.LANCZOS)
	# Traits : pixels sombres du rendu (contour, yeux, plis) en blanc sur noir.
	gris = depart.convert("L")
	traits = gris.point(lambda v: 255 if v < 110 else 0).filter(ImageFilter.MaxFilter(3))
	noms = {}
	for cle, im in (("depart", depart), ("profondeur", p), ("traits", traits.convert("RGB"))):
		nom = f"kanto_{uuid.uuid4().hex[:8]}_{cle}.png"
		im.save(os.path.join(dossier, nom))
		noms[cle] = nom
	return noms, c.getchannel("A")


def graphe(noms, o):
	g = _graphe(noms, o)
	if o.traits <= 0:
		# Mémoire limitée : un seul guidage (profondeur), le second est retiré.
		for cle in ("8", "10", "12"):
			del g[cle]
		g["13"]["inputs"]["positive"] = ["11", 0]
		g["13"]["inputs"]["negative"] = ["11", 1]
	return g


def _graphe(noms, o):
	pos = POSITIF.format(nom=o.nom)
	return {
		"1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": MODELE}},
		"2": {"class_type": "LoraLoader", "inputs": {"lora_name": LORA, "strength_model": o.lora,
			"strength_clip": o.lora, "model": ["1", 0], "clip": ["1", 1]}},
		"3": {"class_type": "CLIPTextEncode", "inputs": {"text": pos, "clip": ["2", 1]}},
		"4": {"class_type": "CLIPTextEncode", "inputs": {"text": NEGATIF, "clip": ["2", 1]}},
		"5": {"class_type": "LoadImage", "inputs": {"image": noms["depart"]}},
		"6": {"class_type": "VAEEncode", "inputs": {"pixels": ["5", 0], "vae": ["1", 2]}},
		"7": {"class_type": "LoadImage", "inputs": {"image": noms["profondeur"]}},
		"8": {"class_type": "LoadImage", "inputs": {"image": noms["traits"]}},
		"9": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN_PROFONDEUR}},
		"10": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": CN_TRAITS}},
		"11": {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": ["3", 0],
			"negative": ["4", 0], "control_net": ["9", 0], "image": ["7", 0],
			"strength": o.profondeur, "start_percent": 0.0, "end_percent": 1.0}},
		"12": {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": ["11", 0],
			"negative": ["11", 1], "control_net": ["10", 0], "image": ["8", 0],
			"strength": o.traits, "start_percent": 0.0, "end_percent": 0.8}},
		"13": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "seed": o.graine,
			"steps": o.pas, "cfg": 6.5, "sampler_name": "dpmpp_2m", "scheduler": "karras",
			"positive": ["12", 0], "negative": ["12", 1], "latent_image": ["6", 0],
			"denoise": o.debruitage}},
		"14": {"class_type": "VAEDecode", "inputs": {"samples": ["13", 0], "vae": ["1", 2]}},
		"15": {"class_type": "SaveImage", "inputs": {"images": ["14", 0],
			"filename_prefix": "kanto_dos"}},
	}


def executer(serveur, g):
	donnees = json.dumps({"prompt": g, "client_id": "kanto"}).encode()
	req = urllib.request.Request(serveur + "/prompt", data=donnees,
		headers={"Content-Type": "application/json"})
	ident = json.load(urllib.request.urlopen(req))["prompt_id"]
	while True:
		time.sleep(2)
		hist = json.load(urllib.request.urlopen(f"{serveur}/history/{ident}"))
		if ident in hist:
			etat = hist[ident].get("status", {})
			if etat.get("status_str") == "error":
				raise RuntimeError(json.dumps(etat)[:800])
			for sortie in hist[ident]["outputs"].values():
				for im in sortie.get("images", []):
					return os.path.join(COMFY, "output", im.get("subfolder", ""), im["filename"])


def main():
	a = argparse.ArgumentParser()
	a.add_argument("couleur")
	a.add_argument("carte_profondeur")
	a.add_argument("sortie")
	a.add_argument("--nom", required=True)
	a.add_argument("--debruitage", type=float, default=0.6)
	a.add_argument("--graine", type=int, default=7)
	a.add_argument("--lora", type=float, default=0.7)
	a.add_argument("--profondeur", type=float, default=0.8, help="force du guidage de profondeur")
	a.add_argument("--traits", type=float, default=0.6,
		help="force du guidage des traits (0 : retiré, moins de mémoire)")
	a.add_argument("--pas", type=int, default=26)
	a.add_argument("--serveur", default="http://127.0.0.1:8188")
	o = a.parse_args()
	noms, alpha = preparer(o.couleur, o.carte_profondeur, os.path.join(COMFY, "input"))
	t0 = time.time()
	fichier = executer(o.serveur, graphe(noms, o))
	image = Image.open(fichier).convert("RGBA").resize(alpha.size, Image.LANCZOS)
	# Silhouette exacte du rendu, à peine élargie pour garder le contour peint.
	image.putalpha(alpha.filter(ImageFilter.MaxFilter(3)))
	image.save(o.sortie)
	shutil.copy(fichier, o.sortie.replace(".png", "_brut.png"))
	print("REPEINT", o.sortie, f"{time.time() - t0:.0f} s")


if __name__ == "__main__":
	main()
