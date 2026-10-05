"""Rend un Pokémon (modèle 3D extrait de Pokémon X/Y) de dos pour le combat, dans Blender 5.

Usage (sans ouvrir Blender) :
  blender -b --python tools/art/blender/rendre_pokemon.py -- modele dossier_images sortie.png
      [--azimut 35] [--elevation 12] [--taille 1024] [--pose bras=-55,avant=25]
      [--os LWing:Y:30,RWing:Y:-30] [--tourner 0] [--redresser 0] [--flamme Fire] [--vues 1]
      [--saturation 1.12] [--valeur 1.0] [--passe couleur|profondeur]
--passe profondeur : carte de profondeur (proche = blanc, fond noir, sans contour) pour guider
un générateur d'images (ControlNet) ; même cadrage que la passe couleur.

modele : .SMD ou .DAE (importeurs maison : Blender 5 ne lit plus le Collada ni les FBX 6100
de ces modèles), .FBX récent (7100+) ou .glb.
--tourner / --redresser : rotation (degrés) autour de Z / de X pour que le Pokémon soit debout
et regarde vers -Y ; --vues 1 rend quatre vues (0, 90, 180, 270°) pour le vérifier.

1. Import : squelette (pose de référence), maillage, UV, normales, poids des os.
2. Pose de combat : --pose (bras des bipèdes : abaisser, ramener vers l'avant) et --os
   (os:axe monde:degrés, rotation autour de la tête de l'os).
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
FLAMME_PAR_DEFAUT = "Fire"    # matériaux d'effet (flamme) : exclus de la passe de profondeur


def arguments():
	a = sys.argv[sys.argv.index("--") + 1:]
	opts = {"azimut": 35.0, "elevation": 12.0, "taille": 1024, "pose": "bras=-55,avant=25",
		"flamme": "Fire", "os": "", "tourner": 0, "redresser": 0, "vues": 0,
		"saturation": SATURATION, "valeur": 1.0, "passe": "couleur"}
	positionnels = []
	i = 0
	while i < len(a):
		if a[i].startswith("--"):
			opts[a[i][2:]] = a[i + 1]
			i += 2
		else:
			positionnels.append(a[i])
			i += 1
	opts["modele"], opts["images"], opts["sortie"] = positionnels[:3]
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


def lire_dae(chemin):
	"""Collada (1.4) → mêmes données que le SMD : {indice: (nom, parent)}, {indice: matrice
	monde de liaison}, [(matériau, [(pos, normale, uv, [(os, poids)]) × 3])], et
	{matériau: chemin de sa texture de couleur}. Positions × bind_shape_matrix ; os placés à
	l'inverse de leur INV_BIND_MATRIX (sinon à leur matrice de scène)."""
	import xml.etree.ElementTree as ET
	ns = {"c": "http://www.collada.org/2005/11/COLLADASchema"}
	racine = ET.parse(chemin).getroot()
	dossier = os.path.dirname(chemin)
	def floats(el):
		return [float(x) for x in el.text.split()] if el is not None and el.text else []
	def matrice(valeurs):
		return Matrix([valeurs[0:4], valeurs[4:8], valeurs[8:12], valeurs[12:16]])
	sources = {}
	for src in racine.iter("{%s}source" % ns["c"]):
		fa = src.find("c:float_array", ns)
		na = src.find("c:Name_array", ns)
		acc = src.find(".//c:accessor", ns)
		pas = int(acc.get("stride", "1")) if acc is not None else 1
		if fa is not None:
			v = floats(fa)
			sources[src.get("id")] = [v[i:i + pas] for i in range(0, len(v), pas)]
		elif na is not None:
			sources[src.get("id")] = na.text.split()
	# Os : hiérarchie et matrices de la scène.
	noeuds, monde_scene, par_nom = {}, {}, {}
	def parcourir(node, parent, m_parent):
		m = node.find("c:matrix", ns)
		local = matrice(floats(m)) if m is not None else Matrix.Identity(4)
		m_monde = m_parent @ local
		if node.get("type") == "JOINT":
			import re
			i = len(noeuds)
			# Nom lisible (« _50_LArm » → « LArm ») ; la peau désigne l'os par sid ou nom.
			nom = re.sub(r"^_\d+_", "", node.get("name") or node.get("sid"))
			noeuds[i] = (nom, parent)
			monde_scene[i] = m_monde
			for cle in (node.get("sid"), node.get("name"), nom):
				if cle:
					par_nom.setdefault(cle, i)
			parent = i
		for enfant in node.findall("c:node", ns):
			parcourir(enfant, parent, m_monde)
	for scene in racine.iter("{%s}visual_scene" % ns["c"]):
		for node in scene.findall("c:node", ns):
			parcourir(node, -1, Matrix.Identity(4))
	monde = dict(monde_scene)
	# Matériaux : symbole → texture (material → effect → sampler → surface → image).
	images = {im.get("id"): im.find("c:init_from", ns).text for im in racine.iter(
		"{%s}image" % ns["c"]) if im.find("c:init_from", ns) is not None}
	effets = {}
	for eff in racine.iter("{%s}effect" % ns["c"]):
		params = {p.get("sid"): p for p in eff.iter("{%s}newparam" % ns["c"])}
		tex = eff.find(".//c:diffuse/c:texture", ns)
		if tex is None:
			continue
		cible = tex.get("texture")
		if cible in params:
			src = params[cible].find(".//c:source", ns)
			if src is not None and src.text in params:
				init = params[src.text].find(".//c:init_from", ns)
				cible = init.text if init is not None else cible
		effets[eff.get("id")] = images.get(cible, cible)
	materiaux = {}
	for mat in racine.iter("{%s}material" % ns["c"]):
		ie = mat.find("c:instance_effect", ns)
		if ie is not None:
			materiaux[mat.get("id")] = effets.get(ie.get("url").lstrip("#"))
	symboles = {}
	for im in racine.iter("{%s}instance_material" % ns["c"]):
		symboles[im.get("symbol")] = materiaux.get(im.get("target").lstrip("#"))
	textures = {}
	for symbole, fichier in symboles.items():
		if fichier:
			fichier = fichier.replace("file://", "")
			for cand in (os.path.join(dossier, fichier),
					os.path.join(dossier, os.path.basename(fichier)),
					os.path.join(dossier, "Textures", os.path.basename(fichier)),
					os.path.join(dossier, "images", os.path.basename(fichier)),
					os.path.join(dossier, "Images", os.path.basename(fichier))):
				if os.path.exists(cand):
					textures[symbole] = cand
					break
	# Contrôleurs (peau) : géométrie → (bind shape, poids par sommet, os).
	peaux = {}
	for ctrl in racine.iter("{%s}controller" % ns["c"]):
		skin = ctrl.find("c:skin", ns)
		if skin is None:
			continue
		bsm = skin.find("c:bind_shape_matrix", ns)
		bsm = matrice(floats(bsm)) if bsm is not None else Matrix.Identity(4)
		ent = {i.get("semantic"): i.get("source").lstrip("#") for i in skin.find("c:joints", ns)}
		noms = sources[ent["JOINT"]]
		inv = sources.get(ent.get("INV_BIND_MATRIX"), [])
		for k, nom in enumerate(noms):
			if nom in par_nom and k < len(inv):
				monde[par_nom[nom]] = matrice(inv[k]).inverted()
		vw = skin.find("c:vertex_weights", ns)
		entrees = {i.get("semantic"): (int(i.get("offset")), i.get("source").lstrip("#"))
			for i in vw.findall("c:input", ns)}
		nb = len(entrees)
		vcount = [int(x) for x in vw.find("c:vcount", ns).text.split()]
		v = [int(x) for x in vw.find("c:v", ns).text.split()]
		poids_src = sources[entrees["WEIGHT"][1]]
		poids, pos = [], 0
		for n in vcount:
			liens = []
			for _ in range(n):
				j = v[pos + entrees["JOINT"][0]]
				w = poids_src[v[pos + entrees["WEIGHT"][0]]][0]
				if 0 <= j < len(noms) and noms[j] in par_nom:
					liens.append((par_nom[noms[j]], w))
				pos += nb
			poids.append(liens)
		peaux[skin.get("source").lstrip("#")] = (bsm, poids)
	# Triangles.
	triangles = []
	for geo in racine.iter("{%s}geometry" % ns["c"]):
		mesh = geo.find("c:mesh", ns)
		if mesh is None:
			continue
		bsm, poids = peaux.get(geo.get("id"), (Matrix.Identity(4), None))
		rot = bsm.to_3x3()
		verts = {v.get("id"): v.find("c:input[@semantic='POSITION']", ns).get(
			"source").lstrip("#") for v in mesh.findall("c:vertices", ns)}
		for prim in mesh:
			balise = prim.tag.split("}")[1]
			if balise not in ("triangles", "polylist"):
				continue
			entrees = {}
			for i in prim.findall("c:input", ns):
				sem = i.get("semantic")
				if sem == "TEXCOORD" and "TEXCOORD" in entrees:
					continue
				src = i.get("source").lstrip("#")
				entrees[sem] = (int(i.get("offset")), verts.get(src, src))
			nb = max(o for o, _ in entrees.values()) + 1
			idx = [int(x) for x in prim.find("c:p", ns).text.split()]
			vc = prim.find("c:vcount", ns)
			tailles = [int(x) for x in vc.text.split()] if vc is not None else \
				[3] * (len(idx) // (3 * nb))
			mat = prim.get("material") or "defaut"
			pos = 0
			for t in tailles:
				coins = []
				for _ in range(t):
					vi = idx[pos + entrees["VERTEX"][0]]
					p = bsm @ Vector(sources[entrees["VERTEX"][1]][vi][:3])
					n = (rot @ Vector(sources[entrees["NORMAL"][1]][idx[pos + entrees["NORMAL"][0]]][:3])
						) if "NORMAL" in entrees else Vector((0, 0, 1))
					uv = tuple(sources[entrees["TEXCOORD"][1]][idx[pos + entrees["TEXCOORD"][0]]][:2]
						) if "TEXCOORD" in entrees else (0.0, 0.0)
					liens = poids[vi] if poids is not None and vi < len(poids) else []
					coins.append((list(p), list(n), uv, liens))
					pos += nb
				for k in range(1, t - 1):
					triangles.append((mat, [coins[0], coins[k], coins[k + 1]]))
	return noeuds, monde, triangles, textures


def construire(noeuds, monde, triangles, textures, opts):
	"""Squelette + maillage pondéré dans Blender. [textures] : {matériau: chemin}."""
	# Squelette.
	arm_data = bpy.data.armatures.new("os")
	arm = bpy.data.objects.new("squelette", arm_data)
	bpy.context.scene.collection.objects.link(arm)
	bpy.context.view_layer.objects.active = arm
	bpy.ops.object.mode_set(mode="EDIT")
	enfants = {n: [c for c, (_, p) in noeuds.items() if p == n] for n in noeuds}
	# Longueur minimale d'un os : relative à la taille du modèle (les unités varient).
	tous = [Vector(c[0]) for _m, sommets in triangles for c in sommets]
	etendue = max((max(v[i] for v in tous) - min(v[i] for v in tous)) for i in range(3)) \
		if tous else 60.0
	echelle_os = etendue * 0.01
	os_edit = {}
	for n, (nom, _p) in noeuds.items():
		b = arm_data.edit_bones.new(nom)
		b.head = monde[n].to_translation()
		suite = [monde[c].to_translation() for c in enfants[n]]
		longueur = max(echelle_os, max(((v - b.head).length for v in suite), default=echelle_os))
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
		chemin = textures.get(nom) or os.path.join(opts["images"], nom)
		image = bpy.data.images.load(chemin) if os.path.exists(chemin) else None
		if image is None:
			print("TEXTURE ABSENTE", nom)
		obj.data.materials.append(materiau(os.path.splitext(nom)[0], image, opts))
	return arm, [obj]


def importer(opts):
	"""[squelette, maillages] : SMD par l'importeur maison, FBX / glTF par Blender ; les
	matériaux d'origine sont remplacés par les aplats (texture de couleur gardée)."""
	chemin = opts["modele"]
	ext = os.path.splitext(chemin)[1].lower()
	if ext == ".smd":
		noeuds, squelette, triangles = lire_smd(chemin)
		arm, objs = construire(noeuds, matrices_monde(noeuds, squelette), triangles, {}, opts)
	elif ext == ".dae":
		arm, objs = construire(*lire_dae(chemin), opts)
	else:
		if ext == ".fbx":
			bpy.ops.import_scene.fbx(filepath=chemin)
		else:
			bpy.ops.import_scene.gltf(filepath=chemin)
		arm = next((o for o in bpy.data.objects if o.type == "ARMATURE"), None)
		objs = [o for o in bpy.data.objects if o.type == "MESH"]
		for o in objs:
			for slot in o.material_slots:
				if slot.material is not None:
					slot.material = materiau(slot.material.name, image_couleur(slot.material,
						opts), opts)
	racines = [o for o in bpy.data.objects if o.parent is None]
	r = Matrix.Rotation(math.radians(float(opts["tourner"])), 4, "Z") \
		@ Matrix.Rotation(math.radians(float(opts["redresser"])), 4, "X")
	for o in racines:
		o.matrix_world = r @ o.matrix_world
	bpy.context.view_layer.update()
	return arm, objs


def image_couleur(mat, opts):
	"""Texture de couleur d'un matériau importé : la première image qui n'est ni une normale,
	ni un masque d'identifiants, ni une seconde couche (…Nor, …Id, …Mask, …2)."""
	images = [n.image for n in mat.node_tree.nodes if n.type == "TEX_IMAGE" and n.image] \
		if mat.use_nodes else []
	def ok(im):
		nom = os.path.splitext(im.name)[0]
		return not any(k in nom for k in ("Nor", "Id", "Mask")) and not nom.endswith("2")
	choix = next((im for im in images if ok(im)), images[0] if images else None)
	if choix is None:
		# Pas de nœud image : chercher un PNG du nom du matériau dans le dossier d'images.
		candidat = os.path.join(opts["images"], mat.name + ".png")
		choix = bpy.data.images.load(candidat) if os.path.exists(candidat) else None
	return choix


def materiau(nom, image, opts):
	"""Aplats « artwork » sur [image] (bpy.types.Image, ou None : blanc)."""
	m = bpy.data.materials.new(nom)
	m.use_nodes = True
	nt = m.node_tree
	nt.nodes.clear()
	sortie = nt.nodes.new("ShaderNodeOutputMaterial")
	tex = nt.nodes.new("ShaderNodeTexImage")
	tex.image = image
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
		teinte.inputs["Saturation"].default_value = float(opts["saturation"])
		teinte.inputs["Value"].default_value = float(opts["valeur"])
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


def poser(arm, pose, rotations):
	"""Bras : rotation monde autour de l'épaule (abaisser, ramener vers l'avant) ; puis chaque
	« os:axe:degrés » de [rotations] (axe monde X, Y ou Z, autour de la tête de l'os)."""
	if arm is None:
		return
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
	for regle in filter(None, rotations.split(",")):
		nom, axe, degres = regle.split(":")
		pb = arm.pose.bones.get(nom)
		if pb is None:
			print("OS ABSENT", nom)
			continue
		# Axe monde ramené dans l'espace du squelette.
		axe_arm = (arm.matrix_world.inverted().to_3x3() @ Vector(
			{"X": (1, 0, 0), "Y": (0, 1, 0), "Z": (0, 0, 1)}[axe])).normalized()
		r = Matrix.Rotation(math.radians(float(degres)), 4, axe_arm)
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
	coque.matrix_world = obj.matrix_world
	arm_mod = next((m for m in obj.modifiers if m.type == "ARMATURE"), None)
	if arm_mod is not None:
		coque.modifiers.new("os", "ARMATURE").object = arm_mod.object
	solid = coque.modifiers.new("contour", "SOLIDIFY")
	solid.thickness = hauteur * CONTOUR_EPAISSEUR
	solid.offset = 1.0
	solid.use_flip_normals = True
	solid.use_rim = False
	return coque


def cadrer(objs, opts, azimut=None):
	sc = bpy.context.scene
	bpy.context.view_layer.update()
	deps = bpy.context.evaluated_depsgraph_get()
	pts = []
	for o in objs:
		ev = o.evaluated_get(deps)
		pts += [ev.matrix_world @ v.co for v in ev.to_mesh().vertices]
		ev.to_mesh_clear()
	az = math.radians(float(opts["azimut"] if azimut is None else azimut))
	el = math.radians(float(opts["elevation"]))
	# De dos : la caméra est du côté +Y (le Pokémon regarde -Y), décalée de l'azimut.
	direction = Vector((-math.sin(az) * math.cos(el), math.cos(az) * math.cos(el), math.sin(el)))
	cam = sc.camera
	if cam is None:
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


def passe_profondeur(objs, direction):
	"""Remplace tous les matériaux par la profondeur vue de la caméra (proche = blanc)."""
	bpy.context.view_layer.update()
	cam = bpy.context.scene.camera
	inv = cam.matrix_world.inverted()
	deps = bpy.context.evaluated_depsgraph_get()
	zs = []
	for o in objs:
		ev = o.evaluated_get(deps)
		zs += [-(inv @ (ev.matrix_world @ v.co)).z for v in ev.to_mesh().vertices]
		ev.to_mesh_clear()
	proche, loin = min(zs), max(zs)
	m = bpy.data.materials.new("profondeur")
	m.use_nodes = True
	nt = m.node_tree
	nt.nodes.clear()
	camera = nt.nodes.new("ShaderNodeCameraData")
	plage = nt.nodes.new("ShaderNodeMapRange")
	plage.inputs["From Min"].default_value = proche
	plage.inputs["From Max"].default_value = loin
	plage.inputs["To Min"].default_value = 1.0
	plage.inputs["To Max"].default_value = 0.12
	e = nt.nodes.new("ShaderNodeEmission")
	s = nt.nodes.new("ShaderNodeOutputMaterial")
	nt.links.new(camera.outputs["View Z Depth"], plage.inputs["Value"])
	nt.links.new(plage.outputs["Result"], e.inputs["Color"])
	nt.links.new(e.outputs["Emission"], s.inputs["Surface"])
	noir = bpy.data.materials.new("hors_profondeur")
	noir.use_nodes = True
	noir.node_tree.nodes.clear()
	e2 = noir.node_tree.nodes.new("ShaderNodeEmission")
	e2.inputs["Color"].default_value = (0, 0, 0, 1)
	s2 = noir.node_tree.nodes.new("ShaderNodeOutputMaterial")
	noir.node_tree.links.new(e2.outputs["Emission"], s2.inputs["Surface"])
	for o in objs:
		for slot in o.material_slots:
			# Les effets (flamme : volume en forme d'œuf, masqué par sa texture) restent noirs.
			effet = slot.material is not None and FLAMME_PAR_DEFAUT in slot.material.name
			slot.material = noir if effet else m
	bpy.context.scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = \
		(0, 0, 0, 1)


def main():
	opts = arguments()
	bpy.ops.wm.read_factory_settings(use_empty=True)
	arm, objs = importer(opts)
	poser(arm, opts["pose"], opts["os"])
	bpy.context.view_layer.update()
	zs = [(o.matrix_world @ Vector(c)).z for o in objs for c in o.bound_box]
	hauteur = (max(zs) - min(zs)) or 60.0
	profondeur = opts["passe"] == "profondeur"
	if not profondeur:
		for o in list(objs):
			contour(o, hauteur, opts["flamme"])
	direction = cadrer(objs, opts)
	eclairer(direction)
	if profondeur:
		passe_profondeur(objs, direction)
	sc = bpy.context.scene
	for moteur in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
		try:
			sc.render.engine = moteur
			break
		except TypeError:
			continue
	sc.render.film_transparent = not profondeur
	sc.render.resolution_x = sc.render.resolution_y = int(opts["taille"])
	sc.view_settings.view_transform = "Standard"
	if int(opts["vues"]):
		# Vérification d'orientation : 0 = de dos (attendu), 180 = de face.
		sc.render.resolution_x = sc.render.resolution_y = 320
		for az in (0, 90, 180, 270):
			cadrer(objs, opts, az)
			sc.render.filepath = os.path.abspath(opts["sortie"].replace(".png", f"_vue{az}.png"))
			bpy.ops.render.render(write_still=True)
		print("VUES", opts["sortie"])
		return
	sc.render.filepath = os.path.abspath(opts["sortie"])
	bpy.ops.render.render(write_still=True)
	print("RENDU", opts["sortie"])


main()
