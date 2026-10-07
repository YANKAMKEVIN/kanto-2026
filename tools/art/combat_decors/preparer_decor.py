#!/usr/bin/env python3
"""Prépare un décor peint de combat (CB.3) : master en résolution native et calque de premier plan.

Codex sort au plus ≈ 1,6 Mpx (≈ 1846 × 852 au rapport 2,17 : 1) : trop petit pour 2340 × 1080, et
on n'agrandit jamais un petit fichier. Recette :
1. composition : `COMBAT_DECOR_<LIEU>_rN` (Codex, ≈ 1846 × 852) ;
2. deux TUILES qui se chevauchent (moitié gauche et moitié droite + 154 px), chacune repeinte par
   Codex en plus grand (≈ 1359 × 1158, prompt COMBAT_DECOR_TUILE) : la résolution vient de la
   peinture, pas d'un agrandissement ;
3. ici : recalage de chaque tuile sur sa portion (recaler.py), couture par le chemin de moindre
   différence dans le chevauchement (fondu étroit), puis RÉDUCTION à la taille finale ;
4. premier plan : plantes sur fond magenta pur (Codex), détourées ici (clé magenta, débord de
   couleur retiré), mises à la taille finale puis floutées (profondeur de champ : le flou rend
   l'agrandissement invisible, c'est la seule image agrandie).

  python3 tools/art/combat_decors/preparer_decor.py route_1_chemin
Les sources viennent de build/art/ (manifeste : tools/art/combat_decors/decors.json) ; sorties
dans assets/battle/decors/<id>_back.webp et <id>_front.webp, aperçus dans build/art/combat_decors/.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
from recaler import recaler  # noqa: E402

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
MANIFESTE = os.path.join(os.path.dirname(__file__), "decors.json")
ART = os.path.join(RACINE, "build", "art")
SORTIE = os.path.join(RACINE, "assets", "battle", "decors")
APERCUS = os.path.join(ART, "combat_decors")


def chemin(nom):
    return nom if os.path.isabs(nom) else os.path.join(ART, nom)


def couture(a, b):
    """Colonne de couture (une par ligne) dans le chevauchement : chemin vertical de moindre
    différence entre a et b (tableaux H x W x 3 alignés), programmation dynamique."""
    diff = np.abs(a.astype(np.float32) - b.astype(np.float32)).sum(axis=2)
    noyau = np.ones(5, dtype=np.float32) / 5.0
    diff = np.apply_along_axis(lambda v: np.convolve(v, noyau, mode="same"), 1, diff)
    diff = np.apply_along_axis(lambda v: np.convolve(v, noyau, mode="same"), 0, diff)
    h, w = diff.shape
    marge = max(8, w // 8)
    diff[:, :marge] += 1e6
    diff[:, w - marge:] += 1e6
    cout = diff.copy()
    for y in range(1, h):
        prec = cout[y - 1]
        gauche = np.concatenate(([np.inf], prec[:-1]))
        droite = np.concatenate((prec[1:], [np.inf]))
        cout[y] += np.minimum(np.minimum(gauche, prec), droite)
    seam = np.zeros(h, dtype=np.int32)
    seam[-1] = int(np.argmin(cout[-1]))
    for y in range(h - 2, -1, -1):
        x = seam[y + 1]
        lo, hi = max(0, x - 1), min(w, x + 2)
        seam[y] = lo + int(np.argmin(cout[y, lo:hi]))
    return seam


def master(entree, taille):
    source = Image.open(chemin(entree["composition"])).convert("RGB")
    tuiles = entree["tuiles"]
    poses = []
    for t in tuiles:
        crop = tuple(t["portion"])
        s, sx, sy, tx, ty = recaler(chemin(entree["composition"]), crop, chemin(t["image"]))
        print("  tuile %s : score %.3f, échelle %.4f × %.4f, décalage %.1f, %.1f"
              % (t["image"], s, sx, sy, tx, ty))
        poses.append((t, crop, sx, sy, tx, ty))
    k = float(np.mean([p[2] for p in poses] + [p[3] for p in poses]))
    largeur = int(round(source.size[0] * k))
    hauteur = int(round(source.size[1] * k))
    calques = []
    for t, crop, sx, sy, tx, ty in poses:
        tuile = Image.open(chemin(t["image"])).convert("RGB")
        # Portion source (px source) -> canevas (px source * k) ; la tuile la couvre en
        # (p - crop0) * s + t : on rééchantillonne la tuile à l'échelle k commune.
        w = int(round((crop[2] - crop[0]) * k))
        h = int(round((crop[3] - crop[1]) * k))
        box = (tx, ty, tx + (crop[2] - crop[0]) * sx, ty + (crop[3] - crop[1]) * sy)
        part = tuile.transform((w, h), Image.EXTENT, box, Image.BICUBIC)
        calques.append((int(round(crop[0] * k)), np.asarray(part)))
    canevas = np.zeros((hauteur, largeur, 3), dtype=np.uint8)
    (x_a, a), (x_b, b) = calques
    canevas[: a.shape[0], x_a: x_a + a.shape[1]] = a[:hauteur]
    debut, fin = x_b, x_a + a.shape[1]
    zone_a = a[:hauteur, debut - x_a: fin - x_a]
    zone_b = b[:hauteur, : fin - debut]
    seam = couture(zone_a, zone_b)
    fondu = 12
    xs = np.arange(fin - debut)[None, :]
    poids = np.clip((xs - seam[:, None] + fondu) / (2.0 * fondu), 0.0, 1.0)[..., None]
    melange = zone_a * (1.0 - poids) + zone_b * poids
    canevas[:, x_b: x_b + b.shape[1]] = b[:hauteur, : largeur - x_b]
    canevas[:, debut:fin] = melange.astype(np.uint8)
    image = Image.fromarray(canevas)
    print("  canevas natif %d × %d (×%.3f de la composition)" % (largeur, hauteur, k))
    if largeur < taille[0] or hauteur < taille[1]:
        sys.exit("canevas plus petit que la cible : pas d'agrandissement")
    # Réduction seulement, au rapport exact de la cible (recadrage centré si besoin).
    cible = taille[0] / taille[1]
    if largeur / hauteur > cible:
        w = int(round(hauteur * cible))
        image = image.crop(((largeur - w) // 2, 0, (largeur - w) // 2 + w, hauteur))
    else:
        h = int(round(largeur / cible))
        image = image.crop((0, 0, largeur, h))
    return image.resize(taille, Image.LANCZOS), seam + debut


def avant_plan(entree, taille):
    image = Image.open(chemin(entree["avant_plan"])).convert("RGB")
    a = np.asarray(image).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # Clé magenta : distance au magenta pur (fort R et B, G faible).
    magenta = np.minimum(r, b) - g
    alpha = np.clip(1.0 - (magenta - 60.0) / 90.0, 0.0, 1.0)
    # Débord de couleur : là où il reste du magenta, on le retire (R et B ramenés vers G).
    spill = np.clip(magenta, 0, None) * np.clip(1.0 - alpha, 0, 1)
    r = r - spill * 0.9
    b = b - spill * 0.9
    rgb = np.clip(np.stack([r, g, b], axis=-1), 0, 255)
    # Dégagement : au-dessus de la bande du bas, rien entre les touffes des coins (là où se
    # tient ton Pokémon) ; seuls les brins du tout dernier bord restent devant ses pieds.
    deg = entree.get("degagement")
    if deg:
        h, w = alpha.shape
        xs = np.arange(w)[None, :] / w
        ys = np.arange(h)[:, None] / h
        x0, x1, y_bas, doux = deg
        dedans = np.clip(np.minimum(xs - x0, x1 - xs) / doux, 0.0, 1.0)
        haut = np.clip((y_bas - ys) / doux, 0.0, 1.0)
        alpha = alpha * (1.0 - dedans * haut)
    rgba = np.dstack([rgb, alpha * 255.0]).astype(np.uint8)
    calque = Image.fromarray(rgba)
    # Érosion légère de l'alpha (liseré), puis taille finale et flou de profondeur.
    a_ch = calque.getchannel("A").filter(ImageFilter.MinFilter(3))
    calque.putalpha(a_ch)
    calque = calque.resize(taille, Image.LANCZOS)
    flou = float(entree.get("flou_avant_plan", 7.0))
    # Flou en alpha prémultiplié (pas de halo sombre ni magenta).
    p = np.asarray(calque).astype(np.float32)
    al = p[..., 3:4] / 255.0
    pre = Image.fromarray(np.dstack([p[..., :3] * al, al[..., 0] * 255.0]).astype(np.uint8))
    canaux = [c.filter(ImageFilter.GaussianBlur(flou)) for c in pre.split()]
    q = np.dstack([np.asarray(c).astype(np.float32) for c in canaux])
    al2 = np.clip(q[..., 3:4] / 255.0, 1e-4, 1.0)
    rgb2 = np.clip(q[..., :3] / al2, 0, 255)
    return Image.fromarray(np.dstack([rgb2, q[..., 3]]).astype(np.uint8))


def main():
    ident = sys.argv[1]
    entree = json.load(open(MANIFESTE))[ident]
    taille = tuple(entree["taille"])
    os.makedirs(SORTIE, exist_ok=True)
    os.makedirs(APERCUS, exist_ok=True)
    print("décor %s" % ident)
    fond, _ = master(entree, taille)
    fond.save(os.path.join(APERCUS, ident + "_back.png"))
    dest = os.path.join(SORTIE, ident + "_back.webp")
    fond.save(dest, "WEBP", quality=int(entree.get("qualite", 90)), method=6)
    print("  %s : %d × %d, %.0f Ko" % (dest, fond.size[0], fond.size[1],
                                       os.path.getsize(dest) / 1024))
    if entree.get("avant_plan"):
        avant = avant_plan(entree, taille)
        avant.save(os.path.join(APERCUS, ident + "_front.png"))
        dest = os.path.join(SORTIE, ident + "_front.webp")
        avant.save(dest, "WEBP", quality=int(entree.get("qualite", 90)), method=6)
        print("  %s : %d × %d, %.0f Ko" % (dest, avant.size[0], avant.size[1],
                                           os.path.getsize(dest) / 1024))
        apercu = fond.convert("RGBA")
        apercu.alpha_composite(avant)
        apercu.convert("RGB").save(os.path.join(APERCUS, ident + "_composite.png"))


if __name__ == "__main__":
    main()
