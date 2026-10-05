"""Rend un Pokémon (modèle 3D extrait, format SMD) de dos pour le combat, dans Blender 5.

Usage (sans ouvrir Blender) :
  blender -b --python tools/art/blender/rendre_pokemon.py -- modele.SMD dossier_images sortie.png
      [--azimut 35] [--elevation 12] [--taille 1024] [--pose bras=-55,avant=25]
      [--flamme Fire]

1. Import du SMD : squelette (pose de référence), maillage, UV, normales, poids des os.
   Blender 5 ne lit plus le Collada ni les FBX anciens de ces modèles.
2. Pose de combat : bras abaissés et ramenés vers l'avant (rotation monde autour de l'épaule).
3. Rendu « artwork officiel » : aplats à deux tons (lumière / ombre) sur la couleur de la
   texture, lumière neutre du haut à gauche, contour sombre par coque inversée.
   Les matériaux dont le nom contient --flamme (masques noir et blanc) deviennent une flamme
   émissive jaune-orange.
4. Caméra orthographique de dos, de trois quarts (azimut depuis l'arrière, élévation),
   fond transparent, Pokémon cadré à ~85 % de la hauteur.
"""
import math
import os
import sys

import bpy
from mathutils import Euler, Matrix, Vector

OMBRE = 0.64          # valeur de l'aplat d'ombre (1 = lumière)
SEUIL_OMBRE = 0.45    # seuil lumière / ombre du diffus
CONTOUR = (0.16, 0.10, 0.10)  # couleur du contour (brun très sombre, comme les artworks)
CONTOUR_EPAISSEUR = 0.016     # fraction de la hauteur du modèle
SATURATION = 1.12             # saturation des textures du corps


def arguments():
	a = sys.argv[sys.argv.index("--") + 1:]
	opts = {"azimut": 35.0, "elevation": 12.0, "taille": 1024, "pose": "bras=-55,avant=25",
		"flamme": "Fire"}
	positionnels = []
	i = 0
	while i < len(a):
		if a[i].startswith("--"):
			opts[a[i][2:]] = a[i + 1]
			i += 2
		else:
			positionnels.append(a[i])
			i += 1
	opts["smd"], opts["images"], opts["sortie"] = positionnels[:3]
	return opts


def lire_smd(chemin):
	lignes = open(chemin, encoding="utf-8", errors="replace").read().splitlines()
	noeuds, squelette, triangles = {}, {}, []
	i = 0
	while i < len(lignes):
		l = lignes[i].strip()
		if l == "nodes":
			i += 1
			while lignes[i].strip() != "end":
				p = lignes[i].split('"')
				noeuds[int(p[0])] = (p[1], int(p[2]))
				i += 1
		elif l == "skeleton":
			i += 2  # « time 0 »
			while lignes[i].strip() != "end" and not lignes[i].strip().startswith("time"):
				v = lignes[i].split()
				squelette[int(v[0])] = [float(x) for x in v[1:7]]
				i += 1
			while lignes[i].strip() != "end":
				i += 1
		elif l == "triangles":
			i += 1
			while lignes[i].strip() != "end":
				mat = lignes[i].strip()
				sommets = []
				for k in range(1, 4):
					v = lignes[i + k].split()
					liens = []
					if len(v) > 10:
						n = int(v[9])
						liens = [(int(v[10 + 2 * j]), float(v[11 + 2 * j])) for j in range(n)]
					else:
						liens = [(int(v[0]), 1.0)]
					sommets.append(([float(x) for x in v[1:4]], [float(x) for x in v[4:7]],
						(float(v[7]), float(v[8])), liens))
				triangles.append((mat, sommets))
				i += 4
		i += 1
	return noeuds, squelette, triangles


def matrices_monde(noeuds, squelette):
	monde = {}
	def calc(n):
		if n in monde:
			return monde[n]
		px, py, pz, rx, ry, rz = squelette.get(n, [0.0] * 6)
		local = Matrix.Translation((px, py, pz)) @ Euler((rx, ry, rz), "XYZ").to_matrix().to_4x4()
		parent = noeuds[n][1]
		monde[n] = (calc(parent) @ local) if parent >= 0 else local
		return monde[n]
	for n in noeuds:
		calc(n)
	return monde


def construire(opts):
	noeuds, squelette, triangles = lire_smd(opts["smd"])
	monde = matrices_monde(noeuds, squelette)
	# Squelette.
	arm_data = bpy.data.armatures.new("os")
	arm = bpy.data.objects.new("squelette", arm_data)
	bpy.context.scene.collection.objects.link(arm)
	bpy.context.view_layer.objects.active = arm
	bpy.ops.object.mode_set(mode="EDIT")
	enfants = {n: [c for c, (_, p) in noeuds.items() if p == n] for n in noeuds}
	os_edit = {}
	for n, (nom, _p) in noeuds.items():
		b = arm_data.edit_bones.new(nom)
		b.head = monde[n].to_translation()
		suite = [monde[c].to_translation() for c in enfants[n]]
		longueur = max(1.0, max(((v - b.head).length for v in suite), default=1.0))
		b.tail = b.head + monde[n].to_3x3() @ Vector((0, longueur, 0))
		os_edit[n] = b
	for n, (_nom, p) in noeuds.items():
		if p >= 0:
			os_edit[n].parent = os_edit[p]
	bpy.ops.object.mode_set(mode="OBJECT")
	# Maillage : un sommet par coin de triangle (UV et normales du SMD gardées).
	verts, faces, uvs, normales, poids, mats = [], [], [], [], [], []
	noms_mats = sorted({t[0] for t in triangles})
	for mat, sommets in triangles:
		base = len(verts)
		for pos, nor, uv, liens in sommets:
			verts.append(pos)
			normales.append(nor)
			uvs.append(uv)
			poids.append(liens)
		faces.append((base, base + 1, base + 2))
		mats.append(noms_mats.index(mat))
	me = bpy.data.meshes.new("pokemon")
	me.from_pydata(verts, [], faces)
	couche = me.uv_layers.new(name="UV")
	for poly in me.polygons:
		poly.material_index = mats[poly.index]
		for li in poly.loop_indices:
			couche.data[li].uv = uvs[me.loops[li].vertex_index]
	me.normals_split_custom_set_from_vertices([Vector(n).normalized() for n in normales])
	obj = bpy.data.objects.new("pokemon", me)
	bpy.context.scene.collection.objects.link(obj)
	groupes = {}
	for vi, liens in enumerate(poids):
		for os_i, w in liens:
			if w <= 0.0 or os_i not in noeuds:
				continue
			nom = noeuds[os_i][0]
			if nom not in groupes:
				groupes[nom] = obj.vertex_groups.new(name=nom)
			groupes[nom].add([vi], w, "REPLACE")
	obj.parent = arm
	mod = obj.modifiers.new("os", "ARMATURE")
	mod.object = arm
	for nom in noms_mats:
		obj.data.materials.append(materiau(os.path.splitext(nom)[0], nom, opts))
	return arm, obj


def materiau(nom, image, opts):
	m = bpy.data.materials.new(nom)
	m.use_nodes = True
	nt = m.node_tree
	nt.nodes.clear()
	sortie = nt.nodes.new("ShaderNodeOutputMaterial")
	tex = nt.nodes.new("ShaderNodeTexImage")
	tex.image = bpy.data.images.load(os.path.join(opts["images"], image))
	emission = nt.nodes.new("ShaderNodeEmission")
	transparent = nt.nodes.new("ShaderNodeBsdfTransparent")
	melange = nt.nodes.new("ShaderNodeMixShader")
	if opts["flamme"] in nom:
		# Masque noir et blanc → flamme jaune-orange émissive, transparente hors du masque.
		rampe = nt.nodes.new("ShaderNodeValToRGB")
		rampe.color_ramp.elements[0].color = (0.85, 0.12, 0.02, 1)
		rampe.color_ramp.elements[1].position = 1.0
		rampe.color_ramp.elements[1].color = (1.0, 0.8, 0.22, 1)
		milieu = rampe.color_ramp.elements.new(0.85)
		milieu.color = (1.0, 0.45, 0.05, 1)
		nt.links.new(tex.outputs["Color"], rampe.inputs["Fac"])
		nt.links.new(rampe.outputs["Color"], emission.inputs["Color"])
		emission.inputs["Strength"].default_value = 1.0
		# Transparence : seules les zones claires du masque sont de la flamme.
		alpha = nt.nodes.new("ShaderNodeMapRange")
		alpha.inputs["From Min"].default_value = 0.35
		alpha.inputs["From Max"].default_value = 0.7
		alpha.clamp = True
		nt.links.new(tex.outputs["Color"], alpha.inputs["Value"])
		nt.links.new(alpha.outputs["Result"], melange.inputs["Fac"])
	else:
		# Aplats à deux tons : diffus seuillé → lumière (1) ou ombre (OMBRE), × couleur.
		diffus = nt.nodes.new("ShaderNodeBsdfDiffuse")
		vers_rgb = nt.nodes.new("ShaderNodeShaderToRGB")
		rampe = nt.nodes.new("ShaderNodeValToRGB")
		rampe.color_ramp.interpolation = "CONSTANT"
		rampe.color_ramp.elements[0].color = (OMBRE, OMBRE, OMBRE * 1.04, 1)
		rampe.color_ramp.elements[1].position = SEUIL_OMBRE
		rampe.color_ramp.elements[1].color = (1, 1, 1, 1)
		produit = nt.nodes.new("ShaderNodeMix")
		produit.data_type = "RGBA"
		produit.blend_type = "MULTIPLY"
		produit.inputs["Factor"].default_value = 1.0
		nt.links.new(diffus.outputs["BSDF"], vers_rgb.inputs["Shader"])
		nt.links.new(vers_rgb.outputs["Color"], rampe.inputs["Fac"])
		# Couleurs des textures du jeu 3DS un peu ternes : saturation relevée (artworks).
		teinte = nt.nodes.new("ShaderNodeHueSaturation")
		teinte.inputs["Saturation"].default_value = SATURATION
		nt.links.new(tex.outputs["Color"], teinte.inputs["Color"])
		nt.links.new(teinte.outputs["Color"], produit.inputs["A"])
		nt.links.new(rampe.outputs["Color"], produit.inputs["B"])
		nt.links.new(produit.outputs["Result"], emission.inputs["Color"])
		nt.links.new(tex.outputs["Alpha"], melange.inputs["Fac"])
	nt.links.new(transparent.outputs["BSDF"], melange.inputs[1])
	nt.links.new(emission.outputs["Emission"], melange.inputs[2])
	nt.links.new(melange.outputs["Shader"], sortie.inputs["Surface"])
	m.surface_render_method = "BLENDED" if opts["flamme"] in nom else "DITHERED"
	return m


def poser(arm, pose):
	"""Bras : rotation monde autour de l'épaule (abaisser, ramener vers l'avant)."""
	reglages = dict(p.split("=") for p in pose.split(",") if "=" in p)
	bas = math.radians(float(reglages.get("bras", -55)))
	avant = math.radians(float(reglages.get("avant", 25)))
	bpy.context.view_layer.objects.active = arm
	bpy.ops.object.mode_set(mode="POSE")
	for cote, signe in (("L", 1.0), ("R", -1.0)):
		pb = arm.pose.bones.get(cote + "Arm")
		if pb is None:
			continue
		# Le Pokémon regarde vers -Y ; son bras gauche part vers +X : abaisser = rotation
		# autour de Y, ramener vers l'avant = rotation autour de Z.
		r = (Matrix.Rotation(signe * avant, 4, "Z") @ Matrix.Rotation(-signe * bas, 4, "Y"))
		tete = pb.head.copy()
		pb.matrix = Matrix.Translation(tete) @ r @ Matrix.Translation(-tete) @ pb.matrix
		bpy.context.view_layer.update()
	bpy.ops.object.mode_set(mode="OBJECT")


def contour(obj, hauteur, flamme):
	"""Contour par coque inversée : copie aux sommets fusionnés (sinon chaque triangle aurait
	sa coque), sans la flamme, épaissie vers l'extérieur, faces retournées, couleur sombre,
	faces arrière seules visibles."""
	import bmesh
	me = obj.data.copy()
	bm = bmesh.new()
	bm.from_mesh(me)
	flammes = {i for i, m in enumerate(obj.data.materials) if flamme in m.name}
	bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index in flammes],
		context="FACES")
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=hauteur * 0.0005)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(me)
	bm.free()
	m = bpy.data.materials.new("contour")
	m.use_nodes = True
	m.use_backface_culling = True
	nt = m.node_tree
	nt.nodes.clear()
	e = nt.nodes.new("ShaderNodeEmission")
	e.inputs["Color"].default_value = (*CONTOUR, 1)
	s = nt.nodes.new("ShaderNodeOutputMaterial")
	nt.links.new(e.outputs["Emission"], s.inputs["Surface"])
	me.materials.clear()
	me.materials.append(m)
	for poly in me.polygons:
		poly.material_index = 0
	coque = bpy.data.objects.new("contour", me)
	bpy.context.scene.collection.objects.link(coque)
	# Les poids sont portés par le maillage copié : on redonne seulement les noms, dans le
	# même ordre (vider la liste effacerait les poids).
	for g in obj.vertex_groups:
		coque.vertex_groups.new(name=g.name)
	coque.parent = obj.parent
	coque.modifiers.new("os", "ARMATURE").object = obj.modifiers["os"].object
	solid = coque.modifiers.new("contour", "SOLIDIFY")
	solid.thickness = hauteur * CONTOUR_EPAISSEUR
	solid.offset = 1.0
	solid.use_flip_normals = True
	solid.use_rim = False
	return coque


def cadrer(objs, opts):
	sc = bpy.context.scene
	bpy.context.view_layer.update()
	deps = bpy.context.evaluated_depsgraph_get()
	pts = []
	for o in objs:
		ev = o.evaluated_get(deps)
		pts += [ev.matrix_world @ v.co for v in ev.to_mesh().vertices]
		ev.to_mesh_clear()
	az = math.radians(float(opts["azimut"]))
	el = math.radians(float(opts["elevation"]))
	# De dos : la caméra est du côté +Y (le Pokémon regarde -Y), décalée de l'azimut.
	direction = Vector((-math.sin(az) * math.cos(el), math.cos(az) * math.cos(el), math.sin(el)))
	cam = bpy.data.objects.new("camera", bpy.data.cameras.new("camera"))
	sc.collection.objects.link(cam)
	sc.camera = cam
	cam.data.type = "ORTHO"
	centre = sum(pts, Vector()) / len(pts)
	cam.location = centre + direction * 500
	cam.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
	bpy.context.view_layer.update()
	inv = cam.matrix_world.inverted()
	loc = [inv @ p for p in pts]
	xs, ys = [p.x for p in loc], [p.y for p in loc]
	larg, haut = max(xs) - min(xs), max(ys) - min(ys)
	cam.data.ortho_scale = max(larg, haut) / 0.85
	cam.data.shift_x = ((max(xs) + min(xs)) / 2) / cam.data.ortho_scale
	cam.data.shift_y = ((max(ys) + min(ys)) / 2) / cam.data.ortho_scale
	return direction


def eclairer(direction):
	sc = bpy.context.scene
	soleil = bpy.data.objects.new("soleil", bpy.data.lights.new("soleil", "SUN"))
	sc.collection.objects.link(soleil)
	# Lumière neutre du haut à gauche de l'image (côté caméra, un peu au-dessus).
	gauche = -Vector((-direction.y, direction.x, 0)).normalized()
	vers = (direction * 0.6 + gauche * 0.5 + Vector((0, 0, 0.9))).normalized()
	soleil.rotation_euler = (-vers).to_track_quat("-Z", "Y").to_euler()
	soleil.data.energy = 3.0
	soleil.data.use_shadow = False  # aplats seulement : pas d'ombre portée sur soi
	monde = bpy.data.worlds.new("monde")
	sc.world = monde
	monde.use_nodes = True
	monde.node_tree.nodes["Background"].inputs["Color"].default_value = (0.5, 0.5, 0.5, 1)


def main():
	opts = arguments()
	bpy.ops.wm.read_factory_settings(use_empty=True)
	arm, obj = construire(opts)
	poser(arm, opts["pose"])
	hauteur = obj.dimensions.z or 60.0
	contour(obj, hauteur, opts["flamme"])
	direction = cadrer([obj], opts)
	eclairer(direction)
	sc = bpy.context.scene
	for moteur in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
		try:
			sc.render.engine = moteur
			break
		except TypeError:
			continue
	sc.render.film_transparent = True
	sc.render.resolution_x = sc.render.resolution_y = int(opts["taille"])
	sc.view_settings.view_transform = "Standard"
	sc.render.filepath = os.path.abspath(opts["sortie"])
	bpy.ops.render.render(write_still=True)
	print("RENDU", opts["sortie"])


main()
