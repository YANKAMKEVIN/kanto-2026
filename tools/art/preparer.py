#!/usr/bin/env python3
"""Prépare tout l'art validé du monde (séries 01 à 06) pour le jeu.

Successeur de preparer_proto.py. Lit `tools/art/manifeste.json` et les images validées de
`build/art/` (non versionné ; sur le Mac de Kevin, jamais nécessaire au cloud), recadre chaque
objet sur sa silhouette, le ramène à sa taille en jeu (1 case = 96 px) et écrit dans `assets/` :
  - les textures à 1:1 (sols, objets, bâtiments, intérieurs, relief, fond du Plateau Indigo) ;
  - pour chaque objet qui en a, l'ombre portée pré-floutée `<id>_shadow.png` et l'ombre de contact
    `<id>_contact.png` (alpha seul : RVB blanc, la couleur et l'opacité viennent du jeu) ;
  - la moitié basse des herbes hautes (cache-jambes) ;
  - les planches de personnages et de Pokémon (4 × 4, via decouper_perso.py) ;
  - `assets/world/catalogue.json` : tailles et décalages (par rapport au pied de l'objet : milieu
    du bas de l'image) de chaque ombre, pour les outils de construction des scènes.
Les ombres reproduisent le prototype (ombre.gdshader, contact.gdshader), calculées une fois ici
au lieu de 25 à 60 lectures de texture par pixel à chaque image.
Usage : tools/art/preparer.py [--source DOSSIER]
"""
import argparse
import importlib.util
import json
import math
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter

RACINE = Path(__file__).resolve().parents[2]
ICI = Path(__file__).resolve().parent


def _decoupeur():
    spec = importlib.util.spec_from_file_location("decouper_perso", ICI / "decouper_perso.py")
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
            image = _silhouette(Image.open(self.source / e["source"]).convert("RGBA"))
            image = _mettre_a_taille(image, e["axe"], e["cases"], self.case)
            _ecrire(image, self._sortie(e["sortie"]))
            entree = {"fichier": self._res(e["sortie"]), "taille": list(image.size)}
            chemin = Path(e["sortie"])
            if e["ombre"]:
                ombre, decalage, red = ombre_portee(image, self.m["ombre_portee"])
                nom = str(chemin.with_name(chemin.stem + "_shadow.png"))
                _ecrire(ombre, self._sortie(nom))
                entree["ombre"] = {"fichier": self._res(nom), "decalage": list(decalage),
                                   "echelle": red, "taille": list(ombre.size)}
            if e["contact"] is not None:
                contact, decalage, red = ombre_contact(image, e["contact"],
                                                       self.m["ombre_contact"])
                nom = str(chemin.with_name(chemin.stem + "_contact.png"))
                _ecrire(contact, self._sortie(nom))
                entree["contact"] = {"fichier": self._res(nom), "decalage": list(decalage),
                                     "echelle": red, "taille": list(contact.size)}
            self.catalogue["objets"][e["id"]] = entree
            print(f"{e['id']} : {image.width} × {image.height}")

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

    def pieces(self) -> None:
        for e in self.m["pieces"]:
            taille = (e["cases"][0] * self.case, e["cases"][1] * self.case)
            image = Image.open(self.source / e["source"]).convert("RGB").resize(taille,
                                                                                Image.LANCZOS)
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

    def heros_images(self) -> None:
        for e in self.m["heros_images"]:
            image = _silhouette(Image.open(self.source / e["source"]).convert("RGBA"))
            echelle = e["hauteur"] / image.height
            image = image.resize((round(image.width * echelle), e["hauteur"]), Image.LANCZOS)
            _ecrire(image, self._sortie(e["sortie"]))
            self.catalogue["images"][e["id"]] = {"fichier": self._res(e["sortie"]),
                                                 "taille": list(image.size)}
            print(f"{e['id']} : {image.width} × {image.height}")

    def ecrire_catalogue(self) -> None:
        chemin = RACINE / "assets" / "world" / "catalogue.json"
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
    options = arguments.parse_args()
    manifeste = json.loads((ICI / "manifeste.json").read_text())
    p = Preparateur(manifeste, Path(options.source))
    p.objets()
    p.hautes_herbes()
    p.pieces()
    p.decor()
    p.sols()
    p.bordures()
    p.personnages()
    p.heros_images()
    p.ecrire_catalogue()
    reglages_import(manifeste)


if __name__ == "__main__":
    main()
