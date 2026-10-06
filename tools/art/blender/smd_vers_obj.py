#!/usr/bin/env python3
"""Convertit le maillage d'un fichier SMD (Source, pose de référence) en OBJ + MTL.

Blender 5 n'importe plus le Collada et refuse les FBX anciens (6100) des modèles extraits de
Pokémon X/Y ; le SMD, en texte, donne directement les triangles dans la pose de référence.
Chaque matériau du SMD porte le nom de sa texture (« pm0004_00_Body1.png ») : le MTL la
reprend en map_Kd (et map_d pour la transparence), cherchée dans le dossier --images.
Usage : tools/art/blender/smd_vers_obj.py modele.SMD sortie.obj --images dossier_images
"""
import argparse
import os


def lire_triangles(chemin):
	"""[(matériau, [(pos, normale, uv) × 3])] du bloc « triangles »."""
	triangles = []
	with open(chemin, encoding="utf-8", errors="replace") as f:
		lignes = [l.rstrip("\n") for l in f]
	i = lignes.index("triangles") + 1
	while i < len(lignes) and lignes[i].strip() != "end":
		materiau = lignes[i].strip()
		sommets = []
		for k in range(1, 4):
			v = lignes[i + k].split()
			pos = tuple(float(x) for x in v[1:4])
			nor = tuple(float(x) for x in v[4:7])
			uv = (float(v[7]), float(v[8]))
			sommets.append((pos, nor, uv))
		triangles.append((materiau, sommets))
		i += 4
	return triangles


def main():
	args = argparse.ArgumentParser()
	args.add_argument("smd")
	args.add_argument("obj")
	args.add_argument("--images", required=True)
	o = args.parse_args()
	triangles = lire_triangles(o.smd)
	mtl = os.path.splitext(o.obj)[0] + ".mtl"
	images = os.path.abspath(o.images)
	materiaux = sorted({m for m, _ in triangles})
	with open(mtl, "w", encoding="utf-8") as f:
		for m in materiaux:
			nom = os.path.splitext(m)[0]
			f.write(f"newmtl {nom}\nKd 1 1 1\nKs 0 0 0\nd 1\n")
			f.write(f"map_Kd {os.path.join(images, m)}\nmap_d {os.path.join(images, m)}\n\n")
	with open(o.obj, "w", encoding="utf-8") as f:
		f.write(f"mtllib {os.path.basename(mtl)}\n")
		n = 1
		for m in materiaux:
			f.write(f"usemtl {os.path.splitext(m)[0]}\n")
			for materiau, sommets in triangles:
				if materiau != m:
					continue
				for pos, nor, uv in sommets:
					f.write("v %f %f %f\nvn %f %f %f\nvt %f %f\n" % (*pos, *nor, *uv))
				f.write(f"f {n}/{n}/{n} {n + 1}/{n + 1}/{n + 1} {n + 2}/{n + 2}/{n + 2}\n")
				n += 3
	print(o.obj, len(triangles), "triangles,", len(materiaux), "matériaux")


if __name__ == "__main__":
	main()
