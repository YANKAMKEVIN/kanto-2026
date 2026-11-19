#!/usr/bin/env python3
"""Route 23 : un petit ponton en bois sous les deux gardes des Badges postés sur l'eau.

Rouge / Bleu laissait les gardes du Badge Marais (8, 85) et du Badge Âme (11, 96) debout au
milieu de l'eau ; décision de Kevin du 2026-11-19 : « fais le ponton en bois ». Image : le ponton
peint du Bourg Palette (`prop_ponton_01`, 480 × 357), en entier et réduit (SCALE), posé à plat
dans `GroundDecals` (sous les personnages). Le plan ne change pas : le garde bloque sa case, l'eau
autour reste surfable.

Édite la scène en texte (une réécriture par Godot renumérote les ressources de toute la scène).
Idempotent : retire puis repose les nœuds `PontonGarde*` et leur ressource. Les passes DAF.4
(`build_daf4_exterieurs.gd`, préfixe `Daf4Ext`) ne les touchent pas.

    python3 tools/route_23_pontons.py
"""
import re
from pathlib import Path

SCENE = Path(__file__).resolve().parent.parent / "game/world/maps/route_23.tscn"
TEXTURE_ID = "pg_ponton01"
MATERIAL_ID = "21_4e2bq"  # world_object.tres, déjà dans la scène
TILE = 96
GUARD_CELLS = [(8, 85), (11, 96)]  # data/npcs/route_23.json
SCALE = 0.32  # ≈ 1,6 case de large, plancher d'à peine plus d'une case [D]
IMAGE_W, IMAGE_H = 480, 357
FEET_IN_IMAGE = 170  # pieds du garde sur le plancher (20 à 235 px dans l'image) [D]
UNIQUE_IDS = [1923400851, 1923400852]

text = SCENE.read_text()
assert f'id="{MATERIAL_ID}"' in text and "world_object.tres" in text
text = re.sub(r'\[ext_resource [^\n]*id="%s"\]\n' % TEXTURE_ID, "", text)
text = re.sub(r'\n\[node name="PontonGarde\d+"[^\n]*\]\n(?:[^\[\n][^\n]*\n)*', "\n", text)
text = text.rstrip("\n") + "\n"
ext = ('[ext_resource type="Texture2D" path="res://assets/world/props/prop_ponton_01.png" '
       f'id="{TEXTURE_ID}"]\n')
last_ext = list(re.finditer(r'\[ext_resource [^\n]*\]\n', text))[-1]
text = text[:last_ext.end()] + ext + text[last_ext.end():]
for i, ((cx, cy), uid) in enumerate(zip(GUARD_CELLS, UNIQUE_IDS), start=1):
    x = cx * TILE + TILE / 2
    y = (cy + 1) * TILE + (IMAGE_H - FEET_IN_IMAGE) * SCALE
    text += (f'\n[node name="PontonGarde{i}" type="Sprite2D" parent="GroundDecals" '
             f'unique_id={uid}]\n'
             f'material = ExtResource("{MATERIAL_ID}")\n'
             f'position = Vector2({x:g}, {y:g})\n'
             f'scale = Vector2({SCALE:g}, {SCALE:g})\n'
             f'texture = ExtResource("{TEXTURE_ID}")\n'
             'centered = false\n'
             f'offset = Vector2({-IMAGE_W / 2:g}, {-IMAGE_H:g})\n')
SCENE.write_text(text)
print("route_23_pontons : OK")
