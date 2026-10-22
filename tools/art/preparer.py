#!/usr/bin/env python3
"""Prépare tout l'art validé du monde (séries 01 à 12) pour le jeu.

Successeur de preparer_proto.py. Lit `tools/art/manifeste.json` et les images validées de
`build/art/` (non versionné ; sur le Mac de Kevin, jamais nécessaire au cloud), recadre chaque
objet sur sa silhouette, le ramène à sa taille en jeu (1 case = 96 px) et écrit dans `assets/` :
  - les textures à 1:1 (sols, objets, bâtiments, intérieurs, relief, fond du Plateau Indigo) ;
  - pour chaque objet qui en a, l'ombre portée pré-floutée `<id>_shadow.png` et l'ombre de contact
    `<id>_contact.png` (alpha seul : RVB blanc, la couleur et l'opacité viennent du jeu) ;
  - la moitié basse des herbes hautes (cache-jambes), et leurs variantes recolorées (herbes
    jaune-vert de la Route 1 : une image de plus, aucune teinte au lancement) ;
  - les arbres de forêt, découpés dans des planches 2 × 2 (`planches_arbres`), et les meubles
    des planches C × L (`planches_objets`, série 12) ;
  - les décalcomanies : bordures (planche 4 × 3) et fleurs (planches 4 × 2) ;
  - les planches de personnages et de Pokémon (4 × 4, via decouper_perso.py) et leurs planches
    d'attente (pieds joints, 4 × 1, via decouper_attente.py) ;
  - `assets/world/catalogue.json` : tailles et décalages (par rapport au pied de l'objet : milieu
    du bas de l'image) de chaque ombre, pour les outils de construction des scènes.
Les ombres reproduisent le prototype (ombre.gdshader, contact.gdshader), calculées une fois ici
au lieu de 25 à 60 lectures de texture par pixel à chaque image.
Usage : tools/art/preparer.py [--source DOSSIER] [--attentes-seulement | --personnages-seulement
        | --images-seulement]
"""
from __future__ import annotations

import argparse
import colorsys
import importlib.util
import json
import math
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

RACINE = Path(__file__).resolve().parents[2]
ICI = Path(__file__).resolve().parent


def _decoupeur():
    spec = importlib.util.spec_from_file_location("decouper_perso", ICI / "decouper_perso.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _attente():
    import sys
    sys.path.insert(0, str(ICI))  # decouper_attente importe decouper_perso
    spec = importlib.util.spec_from_file_location("decouper_attente", ICI / "decouper_attente.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _profil_course():
    import sys
    sys.path.insert(0, str(ICI))  # remplacer_profil_course importe decouper_perso
    spec = importlib.util.spec_from_file_location(
        "remplacer_profil_course", ICI / "remplacer_profil_course.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _silhouette(image: Image.Image) -> Image.Image:
    masque = image.getchannel("A").point(lambda a: 255 if a > 32 else 0)
    return image.crop(masque.getbbox())


def _mettre_a_taille(image: Image.Image, axe: str, cases: float, case: int) -> Image.Image:
    largeur, hauteur = image.size
    echelle = cases * case / (hauteur if axe == "h" else largeur)
    taille = (round(largeur * echelle), round(hauteur * echelle))
    return image.resize(taille, Image.LANCZOS)


def _recadrer(image: Image.Image, entree: dict) -> Image.Image:
    """Options d'un objet (série 10) : « recadrage » [x0, y0, x1, y1] en pixels de la source,
    appliqué avant la silhouette (un morceau d'un asset validé : clôture à 3 cases) ; « masque »
    « disque » : cercle inscrit dans le recadrage, bord adouci (Poké Ball détachée d'un meuble)."""
    if "recadrage" in entree:
        image = image.crop(tuple(entree["recadrage"]))
    if entree.get("masque") == "disque":
        grand = Image.new("L", (image.width * 4, image.height * 4), 0)
        ImageDraw.Draw(grand).ellipse((0, 0, grand.width - 1, grand.height - 1), fill=255)
        masque = grand.resize(image.size, Image.LANCZOS)
        image = image.copy()
        image.putalpha(ImageChops.multiply(image.getchannel("A"), masque))
    return image


def _alpha_blanc(alpha: Image.Image) -> Image.Image:
    blanc = Image.new("L", alpha.size, 255)
    return Image.merge("RGBA", (blanc, blanc, blanc, alpha))


def _pair(valeur: int) -> int:
    return valeur + (valeur % 2)


def _smoothstep(t: float) -> float:
    t = min(1.0, max(0.0, t))
    return t * t * (3.0 - 2.0 * t)


def ombre_portee(objet: Image.Image, reglages: dict) -> tuple[Image.Image, tuple[int, int], int]:
    """Silhouette floutée, retournée, écrasée et inclinée vers le bas à droite (soleil en haut
    à gauche), plus dense au pied qu'à l'extrémité. Renvoie (image alpha seul à demi-résolution,
    décalage du coin haut gauche en pixels de jeu par rapport au pied, facteur de réduction)."""
    flou = reglages["flou"]
    ecrasement = reglages["ecrasement"]
    angle = math.radians(reglages["inclinaison_deg"])
    fondu = reglages["fondu_pied"]
    reduction = reglages["reduction"]
    largeur, hauteur = objet.size
    marge = int(flou * 3)
    lp, hp = largeur + 2 * marge, hauteur + 2 * marge
    base = Image.new("L", (lp, hp), 0)
    base.paste(objet.getchannel("A"), (marge, marge))
    base = base.filter(ImageFilter.GaussianBlur(flou))
    # Fondu vertical (1 au pied, `fondu` en haut), comme mix(0.25, 1, smoothstep(UV.y)).
    degrade = Image.new("L", (lp, hp))
    degrade.putdata([round(255 * (fondu + (1 - fondu) * _smoothstep((r - marge) / hauteur)))
                     for r in range(hp) for _ in range(lp)])
    base = ImageChops.multiply(base, degrade)
    cx, fy = marge + largeur / 2.0, marge + hauteur
    kx, ky = math.sin(angle) * ecrasement, math.cos(angle) * ecrasement
    u_min = -cx - kx * marge
    u_max = lp - cx + kx * (hauteur + marge)
    v_min = -ky * marge
    v_max = ky * (hauteur + marge)
    ou, ov = math.floor(u_min), math.floor(v_min)
    ow, oh = _pair(math.ceil(u_max) - ou), _pair(math.ceil(v_max) - ov)
    rapport = kx / ky
    donnees = (1.0, -rapport, ou - rapport * ov + cx, 0.0, -1.0 / ky, fy - ov / ky)
    ombre = base.transform((ow, oh), Image.AFFINE, donnees, resample=Image.BILINEAR)
    ombre = ombre.resize((ow // reduction, oh // reduction), Image.LANCZOS)
    return _alpha_blanc(ombre), (ou, ov), reduction


def ombre_contact(objet: Image.Image, part_base: float, reglages: dict
                  ) -> tuple[Image.Image, tuple[int, int], int]:
    """Base de la silhouette (`part_base` du bas) étirée vers le bas et floutée : ce qui pose
    l'objet au sol. Renvoie (image alpha seul à demi-résolution, décalage, réduction)."""
    etendue = reglages["etendue"]
    reduction = reglages["reduction"]
    largeur, hauteur = objet.size
    bande_h = max(1, round(part_base * hauteur))
    marge = 8
    lc, hc = _pair(largeur + 2 * marge), _pair(bande_h + etendue + 2)
    bande = Image.new("L", (lc, hc), 0)
    bande.paste(objet.getchannel("A").crop((0, hauteur - bande_h, largeur, hauteur)),
                (marge, 0))
    # Flou horizontal : 5 prises espacées de 3 px.
    flou = Image.new("L", (lc, hc), 0)
    for dx in (-6, -3, 0, 3, 6):
        flou = ImageChops.add(flou, ImageChops.offset(bande, dx, 0).point(lambda v: v / 5.0))
    total = Image.new("L", (lc, hc), 0)
    for i in range(12):
        dy = etendue * (i + 0.5) / 12.0
        poids = 1.0 - dy / etendue
        couche = ImageChops.offset(flou, 0, round(dy)).point(lambda v, p=poids: v * p / 3.0)
        total = ImageChops.add(total, couche)
    total = total.resize((lc // reduction, hc // reduction), Image.LANCZOS)
    # Comme le prototype (contact.gdshader posé `etendue` px plus bas que l'objet) : l'ombre
    # descend de `chute` px, seule la frange sous la base reste visible (J7 T3b).
    chute = reglages.get("chute", 0)
    return _alpha_blanc(total), (-(marge + largeur // 2), -bande_h + chute), reduction


def _coupe_la_plus_vide(image: Image.Image) -> tuple[int, int]:
    """Colonne et rangée les plus vides (moins de pixels opaques) entre 30 et 70 % de l'image."""
    alpha = image.getchannel("A").point(lambda a: 1 if a > 32 else 0)
    largeur, hauteur = image.size
    colonnes = [sum(alpha.crop((x, 0, x + 1, hauteur)).getdata()) for x in range(largeur)]
    rangees = [sum(alpha.crop((0, y, largeur, y + 1)).getdata()) for y in range(hauteur)]
    x = min(range(int(largeur * 0.3), int(largeur * 0.7)), key=lambda i: colonnes[i])
    y = min(range(int(hauteur * 0.3), int(hauteur * 0.7)), key=lambda i: rangees[i])
    return x, y


def _taches(image: Image.Image, reduction: int = 4, part_min: float = 0.02
            ) -> list[tuple[tuple[int, int, int, int], Image.Image]]:
    """Éléments séparés d'une planche : composantes connexes de la silhouette (alpha > 32),
    calculées au quart de la résolution après une dilatation de 4 px (les petits
    détails détachés restent dans leur élément). Écarte les miettes (moins de `part_min` de la
    plus grande). Renvoie (boîte en pixels de l'image, masque L de l'élément à pleine taille)."""
    largeur, hauteur = image.width // reduction, image.height // reduction
    petit = image.getchannel("A").point(lambda a: 255 if a > 32 else 0)
    petit = petit.resize((largeur, hauteur), Image.BOX).point(lambda a: 255 if a else 0)
    petit = petit.filter(ImageFilter.MaxFilter(3))
    pixels = petit.load()
    etiquettes = [[0] * largeur for _ in range(hauteur)]
    composantes: list[list[tuple[int, int]]] = []
    for y0 in range(hauteur):
        for x0 in range(largeur):
            if not pixels[x0, y0] or etiquettes[y0][x0]:
                continue
            numero = len(composantes) + 1
            pile, cases = [(x0, y0)], []
            etiquettes[y0][x0] = numero
            while pile:
                x, y = pile.pop()
                cases.append((x, y))
                for vx, vy in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if (0 <= vx < largeur and 0 <= vy < hauteur and pixels[vx, vy]
                            and not etiquettes[vy][vx]):
                        etiquettes[vy][vx] = numero
                        pile.append((vx, vy))
            composantes.append(cases)
    plus_grande = max(len(c) for c in composantes)
    taches = []
    for cases in composantes:
        if len(cases) < part_min * plus_grande:
            continue
        masque = Image.new("L", (largeur, hauteur), 0)
        for x, y in cases:
            masque.putpixel((x, y), 255)
        masque = masque.resize(image.size, Image.NEAREST)
        taches.append((masque.getbbox(), masque))
    return taches


def nettoyer_halos(image: Image.Image, coeur: int = 235, portee: int = 4, bas: int = 170
                   ) -> Image.Image:
    """Retire le halo lumineux laissé par certains fonds (série 17) : on garde l'alpha à moins de
    `portee` px d'un pixel presque opaque (≥ `coeur`), et ailleurs seulement ce qui dépasse `bas`.
    Les bords francs de l'objet (lisse sur 1-2 px) ne bougent pas."""
    alpha = image.getchannel("A")
    proche = np.asarray(alpha.point(lambda v: 255 if v >= coeur else 0)
                        .filter(ImageFilter.MaxFilter(2 * portee + 1))) > 0
    a = np.asarray(alpha).astype(np.uint8)
    sortie = np.where(proche | (a >= bas), a, 0).astype(np.uint8)
    image = image.copy()
    image.putalpha(Image.fromarray(sortie))
    return image


def recolorer(image: Image.Image, reglages: dict) -> Image.Image:
    """Variante de couleur (TSV) : teinte décalée, valeur relevée par un gamma, saturation
    multipliée puis réduite dans les hautes lumières (`lumieres` = [début, fin, force]).
    Reproduit les herbes jaune-vert de la session de la forêt serrée (écart moyen 2,6 / 255)."""
    debut, fin, force = reglages["lumieres"]
    pixels = []
    for r, g, b, a in image.getdata():
        h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        h = (h + reglages["teinte"]) % 1.0
        v = v ** reglages["gamma_valeur"]
        s = min(1.0, s * reglages["saturation"]
                * (1.0 - force * _smoothstep((v - debut) / (fin - debut))))
        r, g, b = colorsys.hsv_to_rgb(h, s, v)
        pixels.append((round(r * 255), round(g * 255), round(b * 255), a))
    sortie = Image.new("RGBA", image.size)
    sortie.putdata(pixels)
    return sortie


def _flou_gaussien(tableau, sigma: float, enroule: bool = False):
    """Flou gaussien séparable d'un tableau numpy (H × L [× canaux]) ; `enroule` : bords
    raccordés (texture répétée), sinon prolongés."""
    import numpy as np
    rayon = max(1, int(sigma * 3))
    noyau = np.exp(-0.5 * (np.arange(-rayon, rayon + 1) / sigma) ** 2)
    noyau /= noyau.sum()
    mode = "wrap" if enroule else "edge"
    for axe in (0, 1):
        largeurs = [(0, 0)] * tableau.ndim
        largeurs[axe] = (rayon, rayon)
        etendu = np.pad(tableau, largeurs, mode=mode)
        tableau = np.apply_along_axis(lambda v: np.convolve(v, noyau, mode="valid"), axe, etendu)
    return tableau


def raccorder(image: Image.Image, bande: int) -> Image.Image:
    """Texture répétée (série 14, T6) : l'écart de valeur entre deux bords opposés (lissé le
    long du bord, σ 6 px : seules les différences de teinte et de lumière, pas le détail) est
    réparti sur `bande` px de chaque côté (rampe en cosinus) ; les deux bords se rejoignent
    à la moyenne. Le motif n'est pas déplacé."""
    import numpy as np
    a = np.asarray(image.convert("RGB")).astype(np.float64)
    hauteur, largeur = a.shape[:2]
    poids = 0.5 * (1.0 + np.cos(np.pi * np.arange(bande) / bande))
    # Bords gauche / droit (écart par rangée), puis haut / bas (écart par colonne).
    ecart = _flou_gaussien((a[:, 0, :] - a[:, -1, :])[:, None, :], 6.0, True)[:, 0, :]
    for x in range(min(bande, largeur // 2)):
        a[:, x, :] -= ecart / 2 * poids[x]
        a[:, largeur - 1 - x, :] += ecart / 2 * poids[x]
    ecart = _flou_gaussien((a[0, :, :] - a[-1, :, :])[None, :, :], 6.0, True)[0, :, :]
    for y in range(min(bande, hauteur // 2)):
        a[y, :, :] -= ecart / 2 * poids[y]
        a[hauteur - 1 - y, :, :] += ecart / 2 * poids[y]
    return Image.fromarray(np.clip(np.rint(a), 0, 255).astype(np.uint8), "RGB")


def adoucir(image: Image.Image, facteur: float, flou: float) -> Image.Image:
    """Décalcomanie de lumière (puits de jour, série 14, T6) : bordure floutée de `flou` px
    (alpha flouté ; couleurs moyennées pondérées par l'alpha, ce qui efface les franges
    sombres ou colorées laissées par l'extraction d'alpha), puis alpha × `facteur`."""
    import numpy as np
    a = np.asarray(image.convert("RGBA")).astype(np.float64)
    rgb, alpha = a[:, :, :3], a[:, :, 3:] / 255.0
    if flou > 0:
        large = 3.0 * flou
        couleur = _flou_gaussien(rgb * alpha, large) / np.maximum(
            _flou_gaussien(alpha, large), 1e-4)
        rgb = np.where(alpha > 0.9, rgb, couleur)
        alpha = _flou_gaussien(alpha, flou)
    alpha = alpha * facteur
    sortie = np.concatenate([rgb, alpha * 255.0], axis=2)
    return Image.fromarray(np.clip(np.rint(sortie), 0, 255).astype(np.uint8), "RGBA")


def retoucher_coque(image: Image.Image, retouche: dict) -> Image.Image:
    """Retouche d'une coque déjà à sa taille de jeu (série 18 : sorties trop étroites, escalier
    trop large, porte décalée), en pixels du jeu. `zone` [x0, y0, x1, y1] ; `dx` : la zone glisse
    de `dx` px à l'horizontale ; ou `largeur` : elle est ramenée à cette largeur, calée à gauche.
    La bande libérée est remplie par les colonnes `remplir` [sx0, sx1] de la même hauteur,
    répétées (sol, mur uni)."""
    x0, y0, x1, y1 = retouche["zone"]
    sx0, sx1 = retouche["remplir"]
    zone = image.crop((x0, y0, x1, y1))
    if "dx" in retouche:
        dx = retouche["dx"]
        libre = (x1 + dx, x1) if dx < 0 else (x0, x0 + dx)
        cible = x0 + dx
    else:
        zone = zone.resize((retouche["largeur"], y1 - y0), Image.LANCZOS)
        libre = (x0 + retouche["largeur"], x1)
        cible = x0
    motif = image.crop((sx0, y0, sx1, y1))
    sortie = image.copy()
    x = libre[0]
    while x < libre[1]:
        largeur = min(motif.width, libre[1] - x)
        sortie.paste(motif.crop((0, 0, largeur, motif.height)), (x, y0))
        x += largeur
    sortie.paste(zone, (cible, y0))
    return sortie


def _ecrire(image: Image.Image, chemin: Path) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    image.save(chemin, optimize=True)


class Preparateur:
    def __init__(self, manifeste: dict, source: Path) -> None:
        self.m = manifeste
        self.source = source
        self.case = manifeste["case"]
        self.catalogue: dict = {"case": self.case, "objets": {}, "personnages": {}, "images": {}}

    def _sortie(self, relatif: str) -> Path:
        return RACINE / relatif

    def _res(self, relatif: str) -> str:
        return "res://" + relatif

    def objets(self) -> None:
        for e in self.m["objets"]:
            image = _recadrer(Image.open(self.source / e["source"]).convert("RGBA"), e)
            if e.get("nettoyer"):
                image = nettoyer_halos(image)
            if "taille_cases" in e:
                # Taille imposée en cases (largeur, hauteur) : étirement non uniforme, borné par
                # le manifeste (superstructure du pont extérieur, série 18).
                largeur, hauteur = e["taille_cases"]
                image = _silhouette(image).resize(
                    (round(largeur * self.case), round(hauteur * self.case)), Image.LANCZOS)
            else:
                image = _mettre_a_taille(_silhouette(image), e["axe"], e["cases"], self.case)
            if "alpha" in e or "flou_bord" in e:
                image = adoucir(image, e.get("alpha", 1.0), e.get("flou_bord", 0))
            self._objet(e["id"], e["sortie"], image, e["ombre"], e["contact"])

    def _objet(self, ident: str, sortie: str, image: Image.Image, ombre: bool,
               contact: float | None) -> None:
        """Écrit l'objet déjà à sa taille, ses ombres demandées et son entrée du catalogue."""
        _ecrire(image, self._sortie(sortie))
        entree = {"fichier": self._res(sortie), "taille": list(image.size)}
        chemin = Path(sortie)
        if ombre:
            image_ombre, decalage, red = ombre_portee(image, self.m["ombre_portee"])
            nom = str(chemin.with_name(chemin.stem + "_shadow.png"))
            _ecrire(image_ombre, self._sortie(nom))
            entree["ombre"] = {"fichier": self._res(nom), "decalage": list(decalage),
                               "echelle": red, "taille": list(image_ombre.size)}
        if contact is not None:
            image_contact, decalage, red = ombre_contact(image, contact, self.m["ombre_contact"])
            nom = str(chemin.with_name(chemin.stem + "_contact.png"))
            _ecrire(image_contact, self._sortie(nom))
            entree["contact"] = {"fichier": self._res(nom), "decalage": list(decalage),
                                 "echelle": red, "taille": list(image_contact.size)}
        self.catalogue["objets"][ident] = entree
        print(f"{ident} : {image.width} × {image.height}")

    def planches_arbres(self) -> None:
        """Arbres de forêt (série 08) : planche 2 × 2 coupée à la colonne et à la rangée les
        plus vides entre 30 et 70 % (les arbres débordent de leur quart : une coupe au milieu
        les tranchait), chaque arbre recadré sur sa silhouette puis mis à sa hauteur."""
        for planche in self.m.get("planches_arbres", []):
            image = Image.open(self.source / planche["source"]).convert("RGBA")
            x, y = _coupe_la_plus_vide(image)
            quarts = [(0, 0, x, y), (x, 0, image.width, y), (0, y, x, image.height),
                      (x, y, image.width, image.height)]
            for ident, hauteur, quart in zip(planche["ids"], planche["hauteurs_px"], quarts):
                arbre = _silhouette(image.crop(quart))
                taille = (round(arbre.width * hauteur / arbre.height), hauteur)
                self._objet(ident, planche["dossier"] + ident + ".png",
                            arbre.resize(taille, Image.LANCZOS), False, planche["contact"])

    def planches_objets(self) -> None:
        """Planches de meubles et d'objets (série 12 : Musée, Arène). Le générateur ne respecte
        pas la grille demandée (des éléments débordent de leur cellule) : chaque élément est donc
        une **tache** de la silhouette ([func _taches]), rangée en `lignes` de `colonnes` dans
        l'ordre de lecture, puis mise à sa largeur en cases (`cases`, une valeur par élément).
        Ombre de contact préparée, jamais d'ombre portée (mobilier)."""
        for planche in self.m.get("planches_objets", []):
            image = Image.open(self.source / planche["source"]).convert("RGBA")
            if planche.get("nettoyer"):
                image = nettoyer_halos(image)
            colonnes, lignes = planche["colonnes"], planche["lignes"]
            if "boites" in planche:
                # Découpe explicite (éléments trop proches pour être séparés par `_taches`).
                taches = []
                for boite in planche["boites"]:
                    masque = Image.new("L", image.size, 0)
                    masque.paste(255, tuple(boite))
                    taches.append((tuple(boite), masque))
            else:
                taches = _taches(image)
            # Nombre d'éléments = celui des identifiants (une planche 3 × 2 peut n'en porter
            # que 5 : cellule vide, série 15).
            if len(taches) != len(planche["ids"]):
                raise SystemExit(f"{planche['source']} : {len(taches)} éléments trouvés, "
                                 f"{len(planche['ids'])} attendus")
            taches.sort(key=lambda tache: tache[0][1] + tache[0][3])
            ordre = []
            for ligne in range(lignes):
                rangee = taches[ligne * colonnes:(ligne + 1) * colonnes]
                ordre += sorted(rangee, key=lambda tache: tache[0][0] + tache[0][2])
            for ident, cases, (boite, masque) in zip(planche["ids"], planche["cases"], ordre):
                element = image.copy()
                element.putalpha(ImageChops.multiply(image.getchannel("A"), masque))
                element = _mettre_a_taille(_silhouette(element.crop(boite)), "w", cases,
                                           self.case)
                self._objet(ident, planche["dossier"] + ident + ".png", element, False,
                            planche["contact"])

    def effets(self) -> None:
        """Effets image par image (série 18 : Coupe) : chaque image = une **cellule fixe** de la
        planche (`boites`, sans recadrage sur la silhouette : les feuilles détachées restent, et
        le trait ne saute pas d'une image à l'autre), toutes à la même `echelle`. Écrit
        `<dossier>/<id>.png` et une entrée « images » du catalogue par image."""
        for e in self.m.get("effets", []):
            image = Image.open(self.source / e["source"]).convert("RGBA")
            if e.get("nettoyer"):
                image = nettoyer_halos(image)
            for ident, boite in zip(e["ids"], e["boites"]):
                cellule = image.crop(tuple(boite))
                taille = (_pair(round(cellule.width * e["echelle"])),
                          _pair(round(cellule.height * e["echelle"])))
                cellule = cellule.resize(taille, Image.LANCZOS)
                sortie = e["dossier"] + ident + ".png"
                _ecrire(cellule, self._sortie(sortie))
                self.catalogue["images"][ident] = {"fichier": self._res(sortie),
                                                   "taille": list(cellule.size)}
                print(f"{ident} : {cellule.width} × {cellule.height}")

    def hautes_herbes(self) -> None:
        e = self.m["hautes_herbes"]
        image = _silhouette(Image.open(self.source / e["source"]).convert("RGBA"))
        image = _mettre_a_taille(image, e["axe"], e["cases"], self.case)
        _ecrire(image, self._sortie(e["sortie"]))
        haut = round(image.height * (1.0 - e["part_basse"]))
        bas = image.crop((0, haut, image.width, image.height))
        _ecrire(bas, self._sortie(e["sortie_bas"]))
        self.catalogue["objets"][e["id"]] = {
            "fichier": self._res(e["sortie"]), "taille": list(image.size),
            "bas": {"fichier": self._res(e["sortie_bas"]), "taille": list(bas.size)}}
        print(f"{e['id']} : {image.width} × {image.height} (moitié basse {bas.height} px)")
        for v in self.m.get("hautes_herbes_variantes", []):
            variante = recolorer(image, v["recoloration"])
            _ecrire(variante, self._sortie(v["sortie"]))
            bas_v = variante.crop((0, haut, variante.width, variante.height))
            _ecrire(bas_v, self._sortie(v["sortie_bas"]))
            self.catalogue["objets"][v["id"]] = {
                "fichier": self._res(v["sortie"]), "taille": list(variante.size),
                "bas": {"fichier": self._res(v["sortie_bas"]), "taille": list(bas_v.size)}}
            print(f"{v['id']} : {variante.width} × {variante.height} (recolorée)")

    def pieces(self) -> None:
        for e in self.m["pieces"]:
            taille = (e["cases"][0] * self.case, e["cases"][1] * self.case)
            image = Image.open(self.source / e["source"]).convert("RGB")
            if e.get("boite"):  # bande dans un cadre (couloir du S.S. Anne, série 18)
                image = image.crop(tuple(e["boite"]))
            image = image.resize(taille, Image.LANCZOS)
            for retouche in e.get("retouches", []):
                image = retoucher_coque(image, retouche)
            _ecrire(image, self._sortie(e["sortie"]))
            self.catalogue["images"][e["id"]] = {"fichier": self._res(e["sortie"]),
                                                 "taille": list(image.size)}
            print(f"{e['id']} : {image.width} × {image.height}")

    def decor(self) -> None:
        for e in self.m["decor"]:
            image = Image.open(self.source / e["source"]).convert("RGB")
            _ecrire(image, self._sortie(e["sortie"]))
            self.catalogue["images"][e["id"]] = {"fichier": self._res(e["sortie"]),
                                                 "taille": list(image.size)}
            print(f"{e['id']} : {image.width} × {image.height}")

    def sols(self) -> None:
        for e in self.m["sols"]:
            image = Image.open(self.source / e["source"]).convert("RGB")
            image = image.resize((e["taille"], e["taille"]), Image.LANCZOS)
            if e["contraste"] != 1.0:
                image = ImageEnhance.Contrast(image).enhance(e["contraste"])
            if e["couleur"] != 1.0:
                # Terre trop orangée à la génération : ramenée vers l'ocre clair.
                image = ImageEnhance.Color(image).enhance(e["couleur"])
            if e.get("luminosite", 1.0) != 1.0:
                # Planches du quai éclaircies en pont de teck (série 18).
                image = ImageEnhance.Brightness(image).enhance(e["luminosite"])
            if e.get("raccord"):
                image = raccorder(image, e["raccord"])
            if e.get("rotation"):  # quarts de tour (platelage des pontons nord-sud, série 17)
                image = image.rotate(e["rotation"], expand=True)
            _ecrire(image, self._sortie(e["sortie"]))
            self.catalogue["images"][e["id"]] = {"fichier": self._res(e["sortie"]),
                                                 "taille": list(image.size)}
            print(f"{e['id']} : {image.width} × {image.height}")

    def bordures(self) -> None:
        b = self.m["bordures"]
        planche = Image.open(self.source / b["source"]).convert("RGBA")
        largeur, hauteur = planche.width // b["colonnes"], planche.height // b["lignes"]
        echelle = self.case / b["case_planche"]
        for ligne, famille in enumerate(b["familles"]):
            for colonne in range(b["colonnes"]):
                cellule = planche.crop((colonne * largeur, ligne * hauteur,
                                        (colonne + 1) * largeur, (ligne + 1) * hauteur))
                element = _silhouette(cellule)
                taille = (max(1, round(element.width * echelle)),
                          max(1, round(element.height * echelle)))
                nom = f"{b['prefixe']}{famille}_{colonne + 1}"
                chemin = b["dossier"] + nom + ".png"
                _ecrire(element.resize(taille, Image.LANCZOS), self._sortie(chemin))
                self.catalogue["images"][nom] = {"fichier": self._res(chemin),
                                                 "taille": list(taille)}
                print(f"{nom} : {taille[0]} × {taille[1]}")

    def decalcomanies(self) -> None:
        """Planches de fleurs (série 06B) : chaque élément recadré, `largeur_cases` de large."""
        for p in self.m.get("decalcomanies", []):
            planche = Image.open(self.source / p["source"]).convert("RGBA")
            largeur, hauteur = planche.width // p["colonnes"], planche.height // p["lignes"]
            for i in range(p["colonnes"] * p["lignes"]):
                colonne, ligne = i % p["colonnes"], i // p["colonnes"]
                element = _silhouette(planche.crop((colonne * largeur, ligne * hauteur,
                                                    (colonne + 1) * largeur,
                                                    (ligne + 1) * hauteur)))
                echelle = p["largeur_cases"] * self.case / element.width
                taille = (round(element.width * echelle), round(element.height * echelle))
                nom = f"{p['prefixe']}{i + 1}"
                chemin = p["dossier"] + nom + ".png"
                _ecrire(element.resize(taille, Image.LANCZOS), self._sortie(chemin))
                self.catalogue["images"][nom] = {"fichier": self._res(chemin),
                                                 "taille": list(taille)}
                print(f"{nom} : {taille[0]} × {taille[1]}")

    def personnages(self) -> None:
        decoupeur = _decoupeur()
        for groupe in ("personnages", "pokemon"):
            for e in self.m[groupe]:
                sortie = self._sortie(e["sortie"])
                sortie.parent.mkdir(parents=True, exist_ok=True)
                largeur, hauteur = decoupeur.decouper(
                    str(self.source / e["source"]), str(sortie), e["hauteur"],
                    rebond_passage=e.get("rebond_passage"))
                profil = e.get("profil_course")
                if profil:  # rangées de profil remplacées (cycle de course lisible)
                    largeur, hauteur = _profil_course().remplacer(
                        str(self.source / profil["source"]), str(sortie),
                        profil.get("rebond", 3), profil.get("jambe_lointaine"))
                self.catalogue["personnages"][e["id"]] = {
                    "fichier": self._res(e["sortie"]), "cellule": [largeur, hauteur],
                    "hauteur": e["hauteur"], "colonnes": 4, "lignes": 4,
                    "ordre_lignes": ["bas", "gauche", "droite", "haut"]}
                print(f"{e['id']} : cellule {largeur} × {hauteur}")

    def attentes(self) -> None:
        """Planches d'attente (pieds joints, 4 colonnes bas / gauche / droite / haut × 1 ligne),
        calées sur la planche de marche déjà écrite (`marche` = identifiant du catalogue)."""
        for e in self.m.get("attentes", []):
            marche = self.catalogue["personnages"][e["marche"]]
            sortie = self._sortie(e["sortie"])
            largeur, hauteur = _attente().decouper(
                str(self.source / e["source"]), str(RACINE / marche["fichier"][6:]),
                str(sortie), e.get("miroir"), e.get("rapport_hauteur"))
            self.catalogue["personnages"][e["id"]] = {
                "fichier": self._res(e["sortie"]), "cellule": [largeur, hauteur],
                "hauteur": marche["hauteur"], "colonnes": 4, "lignes": 1,
                "ordre_colonnes": e.get("ordre_colonnes", ["bas", "gauche", "droite", "haut"])}

    def pokemon_fixes(self) -> None:
        """Pokémon d'ambiance immobiles (série 11, jalon 9 §2.8.5) : une planche source = une ligne
        de 4 poses (repos de face, réaction de face, repos de profil gauche, réaction de profil
        gauche). Une seule échelle (hauteur = la pose de repos de face ; une réaction plus haute
        n'est pas réduite), pieds alignés sur le bas de la cellule. Feuille de jeu 6 × 1 : face,
        face réaction, gauche, gauche réaction, droite, droite réaction (les deux dernières =
        miroirs). Une source absente (planche refusée par le générateur) est signalée et sautée."""
        for e in self.m.get("pokemon_fixes", []):
            source = self.source / e["source"]
            if not source.exists():
                print(f"{e['id']} : source absente ({e['source']}), sautée")
                continue
            poses = _attente()._poses_bande(Image.open(source).convert("RGBA"))
            echelle = e["hauteur"] / poses[0].height
            reduites = [p.resize((max(1, round(p.width * echelle)), max(1, round(p.height * echelle))),
                                 Image.LANCZOS) for p in poses]
            ordre = [reduites[0], reduites[1], reduites[2], reduites[3],
                     reduites[2].transpose(Image.FLIP_LEFT_RIGHT),
                     reduites[3].transpose(Image.FLIP_LEFT_RIGHT)]
            largeur = max(p.width for p in ordre) + 4
            largeur += largeur % 2
            hauteur = max(p.height for p in ordre) + 2
            feuille = Image.new("RGBA", (largeur * 6, hauteur), (0, 0, 0, 0))
            for colonne, pose in enumerate(ordre):
                feuille.alpha_composite(pose, (colonne * largeur + (largeur - pose.width) // 2,
                                               hauteur - pose.height))
            sortie = self._sortie(e["sortie"])
            sortie.parent.mkdir(parents=True, exist_ok=True)
            feuille.save(sortie, optimize=True)
            self.catalogue["personnages"][e["id"]] = {
                "fichier": self._res(e["sortie"]), "cellule": [largeur, hauteur],
                "hauteur": e["hauteur"], "colonnes": 6, "lignes": 1,
                "ordre_colonnes": ["bas", "bas_reaction", "gauche", "gauche_reaction",
                                   "droite", "droite_reaction"]}
            print(f"{e['id']} : cellule {largeur} × {hauteur}")

    def heros_images(self) -> None:
        # « images_objets » (série 10) : objets fixes affichés comme des personnages (Poké Ball
        # posée au sol, `build_character_frames.gd`), mis à leur hauteur comme les images du héros.
        for e in self.m["heros_images"] + self.m.get("images_objets", []):
            image = _recadrer(Image.open(self.source / e["source"]).convert("RGBA"), e)
            if not e.get("sans_silhouette"):  # halo : fondu jusqu'au bord, rien à rogner
                image = _silhouette(image)
            echelle = e["hauteur"] / image.height
            image = image.resize((round(image.width * echelle), e["hauteur"]), Image.LANCZOS)
            _ecrire(image, self._sortie(e["sortie"]))
            self.catalogue["images"][e["id"]] = {"fichier": self._res(e["sortie"]),
                                                 "taille": list(image.size)}
            print(f"{e['id']} : {image.width} × {image.height}")

    def ecrire_catalogue(self) -> None:
        chemin = RACINE / "assets" / "world" / "catalogue.json"
        # Ordre stable : celui du fichier existant (les entrées nouvelles à la fin, dans l'ordre
        # du manifeste). Relancer le script, entier ou partiel, ne réordonne plus rien.
        if chemin.exists():
            ancien = json.loads(chemin.read_text())
            for section, entrees in self.catalogue.items():
                if isinstance(entrees, dict) and isinstance(ancien.get(section), dict):
                    connus = [k for k in ancien[section] if k in entrees]
                    nouveaux = [k for k in entrees if k not in ancien[section]]
                    self.catalogue[section] = {k: entrees[k] for k in connus + nouveaux}
        chemin.write_text(json.dumps(self.catalogue, ensure_ascii=False, indent=1) + "\n")


def reglages_import(manifeste: dict) -> None:
    """Mipmaps pour les sols répétés (réglage du .import, que Godot crée à l'import)."""
    for e in manifeste["sols"]:
        fichier = RACINE / (e["sortie"] + ".import")
        if fichier.exists():
            texte = fichier.read_text()
            nouveau = re.sub(r"mipmaps/generate=false", "mipmaps/generate=true", texte)
            if nouveau != texte:
                fichier.write_text(nouveau)
                print(f"mipmaps activés : {e['sortie']}")


def main() -> None:
    arguments = argparse.ArgumentParser()
    arguments.add_argument("--source", default=str(RACINE / "build" / "art"))
    arguments.add_argument("--attentes-seulement", action="store_true",
                           help="seulement les planches d'attente (catalogue existant conservé)")
    arguments.add_argument("--personnages-seulement", action="store_true",
                           help="planches de personnages, de Pokémon et d'attente seulement "
                                "(catalogue existant conservé ; DA.3)")
    arguments.add_argument("--images-seulement", action="store_true",
                           help="images du héros et portraits en pied seulement (catalogue "
                                "existant conservé ; OUV.2)")
    options = arguments.parse_args()
    manifeste = json.loads((ICI / "manifeste.json").read_text())
    p = Preparateur(manifeste, Path(options.source))
    if options.attentes_seulement:
        chemin = RACINE / "assets" / "world" / "catalogue.json"
        p.catalogue = json.loads(chemin.read_text())
        p.attentes()
        p.ecrire_catalogue()
        return
    if options.images_seulement:
        chemin = RACINE / "assets" / "world" / "catalogue.json"
        p.catalogue = json.loads(chemin.read_text())
        p.heros_images()
        p.ecrire_catalogue()
        return
    if options.personnages_seulement:
        chemin = RACINE / "assets" / "world" / "catalogue.json"
        p.catalogue = json.loads(chemin.read_text())
        p.personnages()
        p.attentes()
        p.pokemon_fixes()
        p.ecrire_catalogue()
        return
    p.objets()
    p.planches_arbres()
    p.planches_objets()
    p.effets()
    p.hautes_herbes()
    p.pieces()
    p.decor()
    p.sols()
    p.bordures()
    p.decalcomanies()
    p.personnages()
    p.attentes()
    p.pokemon_fixes()
    p.heros_images()
    p.ecrire_catalogue()
    reglages_import(manifeste)


if __name__ == "__main__":
    main()
