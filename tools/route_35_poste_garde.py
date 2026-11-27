#!/usr/bin/env python3
"""Route 35 : le poste de garde a un intérieur (choix de Kevin du 2026-11-27, retour sur la 0.38.0).

La façade du poste (`JohAmbPosteGarde`, porte en (16, 39)) donnait sur la forêt, sans intérieur.
Le plan (`tools/plans/route_35.txt`) ouvre la porte `D` (16, 39) et un bout de chemin (13..16, 40)
qui part du chemin principal sous la clôture ; cette passe porte le même changement dans la scène,
sans la reconstruire (une reconstruction par Godot renumérote les ressources de toute la scène et
perd les passes posées après elle) :

- couche logique `Ground` : chemin (DIRT) sur la porte et le bout de chemin ;
- sol peint : canal vert (chemin) du masque `assets/world/maps/route_35_ground.png` ;
- sous-bois (`JohAmbForestFloor`) : retiré du bout de chemin ;
- arbres peints dont le feuillage couvrait le chemin et la porte : retirés (`FOREST_REMOVED`) ;
- passage `PortePoste` (STEP_ON ↑ → `route_35_guard_post`, `entrance`) et arrivée `retour_poste`.

L'intérieur se construit par `build_painted_interiors.gd --rooms=route_35_guard_post`.
Idempotent. Après `build_joh3_maps.gd --maps=route_35` (puis la passe d'ambiance), relancer ce
script.

    python3 tools/route_35_poste_garde.py
"""
import base64
import re
import struct
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SCENE = ROOT / "game/world/maps/route_35.tscn"
GROUND_MASK = ROOT / "assets/world/maps/route_35_ground.png"
TILE = 96
WIDTH = 24
DOOR = (16, 39)
PATH = [(13, 40), (14, 40), (15, 40), (16, 40)]
SPAWN = (16, 40)
## Atlas de `overworld.tres` : rangée 2 = DIRT (deux variantes, en damier comme le chemin).
DIRT_ROW = 2
## Arbres de la passe d'ambiance plantés au pied de la façade (feuillage sur la rangée 40).
FOREST_REMOVED = ["JohAmbForest025", "JohAmbForest050", "JohAmbForest051", "JohAmbForest057",
                  "JohAmbForest068"]
WARP_SCRIPT = "res://game/world/warp_point.gd"
UID_WARP = 1927110100
UID_SPAWN = 1927110101


def world(cell):
    return cell[0] * TILE + TILE // 2, (cell[1] + 1) * TILE


def remove_node(text, name):
    return re.sub(r'\n\[node name="%s"[^\n]*\]\n(?:[^\[\n][^\n]*\n)*' % re.escape(name), "\n",
                  text)


def set_ground_tiles(text):
    pattern = re.compile(r'(\[node name="Ground"[^\n]*\]\nvisible = false\n'
                         r'tile_map_data = PackedByteArray\(")([^"]+)("\))')
    found = pattern.search(text)
    assert found, "Ground"
    data = bytearray(base64.b64decode(found.group(2)))
    wanted = {cell: (cell[0] + cell[1]) % 2 for cell in PATH + [DOOR]}
    seen = set()
    for offset in range(2, len(data), 12):
        x, y, source, _ax, _ay, alt = struct.unpack_from("<hhHHHH", data, offset)
        if (x, y) in wanted:
            struct.pack_into("<hhHHHH", data, offset, x, y, source, wanted[(x, y)], DIRT_ROW, alt)
            seen.add((x, y))
    assert seen == set(wanted), sorted(set(wanted) - seen)
    encoded = base64.b64encode(bytes(data)).decode()
    return text[:found.start(2)] + encoded + text[found.end(2):]


def clear_forest_floor(text):
    mask_id = re.search(r'\[node name="JohAmbForestFloor"[^\n]*\]\n(?:[^\[\n][^\n]*\n)*?'
                        r'mask = SubResource\("([^"]+)"\)', text).group(1)
    image_id = re.search(r'\[sub_resource type="ImageTexture" id="%s"\]\nimage = '
                         r'SubResource\("([^"]+)"\)' % re.escape(mask_id), text).group(1)
    pattern = re.compile(r'(\[sub_resource type="Image" id="%s"\]\ndata = \{\n"data": '
                         r'PackedByteArray\(")([^"]*)("\))' % re.escape(image_id))
    found = pattern.search(text)
    data = bytearray(base64.b64decode(found.group(2)))
    assert len(data) == WIDTH * 44, len(data)
    for x, y in PATH:
        data[y * WIDTH + x] = 0
    encoded = base64.b64encode(bytes(data)).decode()
    return text[:found.start(2)] + encoded + text[found.end(2):]


def paint_ground_mask():
    image = Image.open(GROUND_MASK).convert("RGB")
    for cell in PATH:
        image.putpixel(cell, (0, 255, 0))
    image.save(GROUND_MASK)


def warp_and_spawn(text):
    script_id = re.search(r'\[ext_resource type="Script" path="%s" id="([^"]+)"\]'
                          % re.escape(WARP_SCRIPT), text).group(1)
    text = remove_node(remove_node(text, "PortePoste_0"), "retour_poste")
    text = re.sub(r"\n{3,}", "\n\n", text).rstrip("\n") + "\n"
    wx, wy = world(DOOR)
    sx, sy = world(SPAWN)
    return text + (
        f'\n[node name="PortePoste_0" type="Marker2D" parent="Warps" unique_id={UID_WARP}]\n'
        f"position = Vector2({wx}, {wy})\n"
        f'script = ExtResource("{script_id}")\n'
        "direction = Vector2i(0, -1)\n"
        'target_map = &"route_35_guard_post"\n'
        'target_spawn = &"entrance"\n'
        "arrival_facing = Vector2i(0, -1)\n"
        f'\n[node name="retour_poste" type="Marker2D" parent="Spawns" unique_id={UID_SPAWN}]\n'
        f"position = Vector2({sx}, {sy})\n")


text = SCENE.read_text()
text = set_ground_tiles(text)
text = clear_forest_floor(text)
for tree in FOREST_REMOVED:
    text = remove_node(text, tree)
text = warp_and_spawn(text)
SCENE.write_text(text)
paint_ground_mask()
print("route_35_poste_garde : OK")
