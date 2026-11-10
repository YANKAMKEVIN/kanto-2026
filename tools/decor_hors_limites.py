#!/usr/bin/env python3
"""Décor hors des limites des cartes plus petites que l'écran (demande de Kevin, 2026-11-09).

Quand une carte est moins large (ou moins haute) que la vue, la caméra la centre et le fond du
projet, noir, reste visible. On pose autour d'elle, hors de la grille, sans case ni collision :

- `FORETS` : sol, arbres de forêt, et les chemins de sortie prolongés jusqu'au bord de l'écran ;
- `BORDS` : pour un écart de quelques pixels, une bande du bord de la carte retournée en miroir
  (images de `tools/capture_bord_carte.gd`, à refaire si le bord de la carte change) ;
- `FONDS` : un paysage derrière les toits-terrasses.

Édition du texte des scènes, sans passer par Godot : un enregistrement par `godot -s`, sans
autoloads, peut dégrader une carte. Graine fixe, relance sans effet : les nœuds déjà posés sont
retirés puis réécrits à l'identique.

Contrôle : `tools/audit_bords_noirs.gd` balaie les extérieurs et compte le noir visible.

    python3 tools/decor_hors_limites.py
"""

import pathlib
import random
import re

from PIL import Image

ROOT = pathlib.Path(__file__).parent.parent
MAPS = ROOT / "game/world/maps"
TILE = 96
SEED = 20261109
PREFIX = "SideForest"
RES = "side_decor_"

COLOR_FLOOR = "Color(0.10, 0.26, 0.16, 1)"
TEX_PATH = "res://assets/world/ground/ground_chemin_01.png"
TEX_GRASS = "res://assets/world/ground/ground_herbe_01.png"
WIND = "res://game/world/lighting/materials/world_object_wind.tres"

# Écart entre colonnes et rangées d'arbres, en cases ; le feuillage fait ≈ 1,4 case de
# demi-largeur et 3 de haut.
ROW_STEP = 1.4
JITTER_X, JITTER_Y = 0.3, 0.25
SCALE_MIN, SCALE_MAX = 0.95, 1.2
CANOPY = 2.9

# Carte : colonnes d'arbres (distance au bord), largeur de sol, sol, chemins (côté, lignes).
FORETS = {
    "route_2_east": ([0.7, 2.2, 3.7], 6, "dark", [(-1, 43, 45)]),
    "route_22_west": ([0.7, 2.2], 4, "grass", [(1, 9, 12)]),
    "route_37": ([0.7, 2.2], 4, "dark", []),
}
# Carte : axe et épaisseur en pixels.
BORDS = {
    "route_34": ("x", 64),
    "route_35": ("x", 64),
    "route_39": ("x", 64),
    "route_40": ("x", 64),
    "route_43": ("x", 64),
    "silver_trail": ("x", 64),
    "bell_tower_woods": ("x", 64),
    "ss_anne_outer_deck": ("y", 32),
}
# Carte : image de fond.
FONDS = {
    "celadon_dept_roof": "res://assets/world/backdrops/backdrop_vue_ville_01.png",
    "celadon_mansion_roof": "res://assets/world/backdrops/backdrop_vue_ville_01.png",
    "goldenrod_dept_store_roof": "res://assets/world/backdrops/backdrop_vue_ville_01.png",
}
VIEW = (2500, 1300)  # un peu plus qu'un écran 20:9


def strip_previous(text: str) -> str:
    text = re.sub(r'\[ext_resource [^\n]*id="%s[^"]*"\]\n' % RES, "", text)
    return re.sub(r'\[node name="%s[^\n]*\n(?:[^\[\n][^\n]*\n)*\n' % PREFIX, "", text)


def map_size(text: str) -> tuple:
    match = re.search(r"size = Vector2i\((\d+), (\d+)\)", text)
    return int(match[1]), int(match[2])


class Scene:
    def __init__(self, map_id: str) -> None:
        self.path = MAPS / f"{map_id}.tscn"
        self.text = strip_previous(self.path.read_text())
        self.width, self.height = map_size(self.text)
        self.rng = random.Random(f"{SEED}-{map_id}")
        self.used = {int(x) for x in re.findall(r"unique_id=(\d+)", self.text)}
        self.resources = []

    def new_id(self) -> int:
        while True:
            value = self.rng.randint(100_000_000, 2_147_000_000)
            if value not in self.used:
                self.used.add(value)
                return value

    def resource(self, kind: str, path: str) -> str:
        res_id = f"{RES}{len(self.resources)}"
        self.resources.append(f'[ext_resource type="{kind}" path="{path}" id="{res_id}"]\n')
        return res_id

    def write(self, under: str, entities: str) -> None:
        text = self.text
        cut = min(i for i in (text.find("\n[sub_resource"), text.find("\n[node")) if i >= 0)
        text = text[:cut].rstrip("\n") + "\n" + "".join(self.resources) + text[cut:]
        # Sous tout le reste : juste après la racine et ses propriétés.
        root_end = text.index("\n[node", text.index("[node ")) + 1
        text = text[:root_end] + under + text[root_end:]
        if entities:
            header = re.search(r'\[node name="Entities"[^\n]*\n(?:[^\[\n][^\n]*\n)*\n?', text)
            text = text[:header.end()] + entities + text[header.end():]
        self.path.write_text(text)


def repeat_sprite(scene: Scene, name: str, res: str, rect: tuple) -> str:
    x, y, w, h = rect
    return (
        f'[node name="{PREFIX}{name}" type="Sprite2D" parent="." unique_id={scene.new_id()}]\n'
        "z_index = -3\ntexture_repeat = 2\n"
        f"position = Vector2({x}, {y})\n"
        f'texture = ExtResource("{res}")\n'
        "centered = false\nregion_enabled = true\n"
        f"region_rect = Rect2(0, 0, {w}, {h})\n\n"
    )


def build_forest(map_id: str, columns: list, floor_width: int, floor: str, paths: list) -> None:
    scene = Scene(map_id)
    rng = scene.rng
    wind = scene.resource("Material", WIND)
    trees = []
    for number in range(1, 9):
        file = f"assets/world/props/tree_foret_{number:02d}.png"
        width, height = Image.open(ROOT / file).size
        trees.append((scene.resource("Texture2D", "res://" + file), -width / 2, -height))

    def in_path(side: int, y: float) -> bool:
        return any(s == side and top - 0.2 < y < bottom + CANOPY for s, top, bottom in paths)

    feet = []
    for side in (-1, 1):
        for index, distance in enumerate(columns):
            row = 0.8 + (ROW_STEP / 2 if index % 2 else 0)
            while row <= scene.height + 3.0:
                base = -distance if side < 0 else scene.width + distance
                foot = (base + rng.uniform(-JITTER_X, JITTER_X),
                        row + rng.uniform(-JITTER_Y, JITTER_Y))
                if not in_path(side, foot[1]):
                    feet.append(foot)
                row += ROW_STEP
    # Deux rangées qui longent chaque chemin : elles comblent le sous-bois et cassent ses bords.
    for side, top, bottom in paths:
        for edge in (top - 0.05, bottom + 3.1):
            x = 0.6
            while x < floor_width:
                base = -x if side < 0 else scene.width + x
                feet.append((base + rng.uniform(-0.2, 0.2), edge + rng.uniform(-0.12, 0.12)))
                x += 1.15

    blocks = []
    for number, (x, y) in enumerate(feet):
        res, off_x, off_y = rng.choice(trees)
        scale = rng.uniform(SCALE_MIN, SCALE_MAX)
        value = rng.uniform(0.80, 0.92)
        flip = "flip_h = true\n" if rng.random() < 0.5 else ""
        blocks.append(
            f'[node name="{PREFIX}{number:03d}" type="Sprite2D" parent="Entities" '
            f"unique_id={scene.new_id()}]\n"
            f"modulate = Color({value * rng.uniform(0.96, 1.0):.4f}, {value:.4f}, "
            f"{value * rng.uniform(0.94, 1.02):.4f}, 1)\n"
            f'material = ExtResource("{wind}")\n'
            f"position = Vector2({x * TILE:.1f}, {y * TILE:.1f})\n"
            f"scale = Vector2({scale:.4f}, {scale:.4f})\n"
            f'texture = ExtResource("{res}")\n'
            "centered = false\n"
            f"offset = Vector2({off_x}, {off_y})\n"
            f"{flip}\n"
        )

    under = []
    width = floor_width * TILE
    top, height = -2 * TILE, (scene.height + 6) * TILE
    grass = scene.resource("Texture2D", TEX_GRASS) if floor == "grass" else None
    for name, left in (("West", -width), ("East", scene.width * TILE)):
        if grass:
            under.append(repeat_sprite(scene, f"Floor{name}", grass, (left, top, width, height)))
        else:
            under.append(
                f'[node name="{PREFIX}Floor{name}" type="Polygon2D" parent="." '
                f"unique_id={scene.new_id()}]\n"
                f"z_index = -3\ncolor = {COLOR_FLOOR}\n"
                f"polygon = PackedVector2Array({left}, {top}, {left + width}, {top}, "
                f"{left + width}, {top + height}, {left}, {top + height})\n\n"
            )
    if paths:
        path_res = scene.resource("Texture2D", TEX_PATH)
        for number, (side, row_top, row_bottom) in enumerate(paths):
            left = -width if side < 0 else scene.width * TILE
            rect = (left, row_top * TILE, width, (row_bottom - row_top) * TILE)
            under.append(repeat_sprite(scene, f"Path{number}", path_res, rect))
    scene.write("".join(under), "".join(blocks))
    print(f"{map_id} : {len(blocks)} arbres")


def build_edges(map_id: str, axis: str, thickness: int) -> None:
    scene = Scene(map_id)
    width, height = scene.width * TILE, scene.height * TILE
    if axis == "x":
        places = {"west": (-thickness, 0), "east": (width, 0)}
    else:
        places = {"north": (0, -thickness), "south": (0, height)}
    under = []
    for side, (x, y) in places.items():
        res = scene.resource("Texture2D", f"res://assets/world/maps/bords/{map_id}_{side}.png")
        under.append(
            f'[node name="{PREFIX}Edge{side.title()}" type="Sprite2D" parent="." '
            f"unique_id={scene.new_id()}]\n"
            f"z_index = -3\nposition = Vector2({x}, {y})\n"
            f'texture = ExtResource("{res}")\ncentered = false\n\n'
        )
    scene.write("".join(under), "")
    print(f"{map_id} : bords {axis}")


def build_backdrop(map_id: str, path: str) -> None:
    scene = Scene(map_id)
    image = Image.open(ROOT / path.removeprefix("res://"))
    scale = max(VIEW[0] / image.width, VIEW[1] / image.height)
    res = scene.resource("Texture2D", path)
    center = (scene.width * TILE / 2, scene.height * TILE / 2)
    under = (
        f'[node name="{PREFIX}Backdrop" type="Sprite2D" parent="." unique_id={scene.new_id()}]\n'
        f"z_index = -4\nposition = Vector2({center[0]}, {center[1]})\n"
        f"scale = Vector2({scale:.4f}, {scale:.4f})\n"
        f'texture = ExtResource("{res}")\n\n'
    )
    scene.write(under, "")
    print(f"{map_id} : fond")


def main() -> None:
    for map_id, config in FORETS.items():
        build_forest(map_id, *config)
    for map_id, config in BORDS.items():
        if (ROOT / f"assets/world/maps/bords/{map_id}_{'west' if config[0] == 'x' else 'north'}.png").exists():
            build_edges(map_id, *config)
        else:
            print(f"{map_id} : images de bord absentes, ignorée")
    for map_id, path in FONDS.items():
        if (ROOT / path.removeprefix("res://")).exists():
            build_backdrop(map_id, path)
        else:
            print(f"{map_id} : fond absent, ignorée")


if __name__ == "__main__":
    main()
