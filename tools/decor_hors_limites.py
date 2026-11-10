#!/usr/bin/env python3
"""Forêt décorative de part et d'autre de la Route 2 est (demande de Kevin, 2026-11-09).

La carte fait 16 cases de large et l'écran du S24 en montre 24,4 : la caméra la centre et le
fond du projet (noir) restait visible sur les côtés. On pose, hors des limites de la carte, un
sol sombre et des arbres de forêt : aucune case, aucune collision, la grille ne change pas.

Édition du texte de la scène, sans passer par Godot (voir la mémoire « outils sans autoload ») :
un enregistrement par `godot -s` pourrait dégrader la carte. Graine fixe, relance sans effet :
les nœuds déjà posés sont retirés puis réécrits à l'identique.

    python3 tools/route_2_east_foret_laterale.py
"""

import pathlib
import random
import re

SCENE = pathlib.Path(__file__).parent.parent / "game/world/maps/route_2_east.tscn"
TILE = 96
MAP_W, MAP_H = 16, 48
SEED = 20261109

# Distance du pied des arbres au bord de la carte, en cases : le feuillage (≈ 1,4 case de
# demi-largeur) couvre jusqu'à 5 cases, soit plus que les 4,5 d'un écran 20:9.
COLUMNS = [0.7, 2.2, 3.7]
ROW_STEP = 1.4
JITTER_X, JITTER_Y = 0.3, 0.25
SCALE_MIN, SCALE_MAX = 0.95, 1.2
FIRST_ROW, LAST_ROW = 0.8, MAP_H + 3.0
FLOOR_WIDTH = 6
FLOOR_COLOR = "Color(0.10, 0.26, 0.16, 1)"
# Identifiant de ressource de chaque arbre déjà utilisé par la scène, avec son décalage.
TREES = {
    "42_oanpj": -142.0,
    "43_ta48i": -140.5,
    "44_l0jbh": None,
    "45_mb514": None,
    "46_1xug8": None,
    "47_4auyq": None,
    "48_npro2": None,
    "49_gri40": None,
}
MATERIAL = "41_si0kw"
PREFIX = "SideForest"
# Le chemin sort à l'ouest sur les lignes 43 et 44 (passage vers la Route 2) : pas de pied
# d'arbre dont le feuillage (3 cases vers le nord) le couvrirait, et le chemin se prolonge.
PATH_ROWS = (43, 45)
PATH_RES = "side_forest_path"
PATH_TEXTURE = "res://assets/world/ground/ground_chemin_01.png"


def strip_previous(text: str) -> str:
    text = re.sub(r'\[ext_resource [^\n]*id="%s"\]\n' % PATH_RES, "", text)
    return re.sub(r'\[node name="%s[^\n]*\n(?:[^\[\n][^\n]*\n)*\n' % PREFIX, "", text)


def offsets_from_scene(text: str) -> dict:
    """Décalage de chaque texture, repris des arbres déjà dans la scène."""
    found = {}
    for block in re.findall(r'texture = ExtResource\("([^"]+)"\)\ncentered = false\noffset = '
                            r"(Vector2\([^)]*\))", text):
        found.setdefault(block[0], block[1])
    return {key: found[key] for key in TREES}


def main() -> None:
    text = strip_previous(SCENE.read_text())
    offsets = offsets_from_scene(text)
    rng = random.Random(SEED)
    used_ids = {int(x) for x in re.findall(r"unique_id=(\d+)", text)}

    def new_id() -> int:
        while True:
            value = rng.randint(100_000_000, 2_147_000_000)
            if value not in used_ids:
                used_ids.add(value)
                return value

    feet = []
    for side in (-1, 1):
        for index, distance in enumerate(COLUMNS):
            row = FIRST_ROW + (ROW_STEP / 2 if index % 2 else 0)
            while row <= LAST_ROW:
                base = -distance if side < 0 else MAP_W + distance
                foot = (base + rng.uniform(-JITTER_X, JITTER_X),
                        row + rng.uniform(-JITTER_Y, JITTER_Y))
                if side > 0 or not PATH_ROWS[0] - 0.2 < foot[1] < PATH_ROWS[1] + 2.9:
                    feet.append(foot)
                row += ROW_STEP
    # Deux rangées qui longent le chemin : elles comblent le sous-bois et cassent ses bords droits.
    for edge in (PATH_ROWS[0] - 0.05, PATH_ROWS[1] + 3.1):
        x = 0.6
        while x < FLOOR_WIDTH:
            feet.append((-x + rng.uniform(-0.2, 0.2), edge + rng.uniform(-0.12, 0.12)))
            x += 1.15

    blocks = []
    for number, (x, y) in enumerate(feet):
        texture = rng.choice(list(TREES))
        scale = rng.uniform(SCALE_MIN, SCALE_MAX)
        value = rng.uniform(0.80, 0.92)
        flip = "flip_h = true\n" if rng.random() < 0.5 else ""
        blocks.append(
            f'[node name="{PREFIX}{number:03d}" type="Sprite2D" parent="Entities" '
            f"unique_id={new_id()}]\n"
            f"modulate = Color({value * rng.uniform(0.96, 1.0):.4f}, {value:.4f}, "
            f"{value * rng.uniform(0.94, 1.02):.4f}, 1)\n"
            f'material = ExtResource("{MATERIAL}")\n'
            f"position = Vector2({x * TILE:.1f}, {y * TILE:.1f})\n"
            f"scale = Vector2({scale:.4f}, {scale:.4f})\n"
            f'texture = ExtResource("{texture}")\n'
            "centered = false\n"
            f"offset = {offsets[texture]}\n"
            f"{flip}\n"
        )

    floors = []
    top, bottom = -2 * TILE, (MAP_H + 4) * TILE
    for name, left in (("West", -FLOOR_WIDTH * TILE), ("East", MAP_W * TILE)):
        right = left + FLOOR_WIDTH * TILE
        floors.append(
            f'[node name="{PREFIX}Floor{name}" type="Polygon2D" parent="." '
            f"unique_id={new_id()}]\n"
            "z_index = -3\n"
            f"color = {FLOOR_COLOR}\n"
            f"polygon = PackedVector2Array({left}, {top}, {right}, {top}, "
            f"{right}, {bottom}, {left}, {bottom})\n\n"
        )

    width = FLOOR_WIDTH * TILE
    path_y = PATH_ROWS[0] * TILE
    path_h = (PATH_ROWS[1] - PATH_ROWS[0]) * TILE
    floors.append(
        f'[node name="{PREFIX}PathWest" type="Sprite2D" parent="." unique_id={new_id()}]\n'
        "z_index = -3\n"
        "texture_repeat = 2\n"
        f"position = Vector2({-width}, {path_y})\n"
        f'texture = ExtResource("{PATH_RES}")\n'
        "centered = false\n"
        "region_enabled = true\n"
        f"region_rect = Rect2(0, 0, {width}, {path_h})\n\n"
    )
    resource = f'[ext_resource type="Texture2D" path="{PATH_TEXTURE}" id="{PATH_RES}"]\n'
    first_node = text.index("\n[sub_resource") if "\n[sub_resource" in text else text.index("\n[node")
    text = text[:first_node].rstrip("\n") + "\n" + resource + text[first_node:]

    anchor = '[node name="GroundDecals"'
    if text.count(anchor) != 1:
        raise SystemExit("GroundDecals introuvable")
    text = text.replace(anchor, "".join(floors) + anchor)

    last = list(re.finditer(r'\[node name="Forest\d+"', text))[-1]
    end = text.index("\n[node", last.end()) + 1
    text = text[:end] + "".join(blocks) + text[end:]
    SCENE.write_text(text)
    print(f"{len(blocks)} arbres, sol et chemin posés dans {SCENE.name}")


if __name__ == "__main__":
    main()
