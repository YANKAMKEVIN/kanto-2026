#!/usr/bin/env python3
"""Retours de Kevin sur Johto (2026-11-27, RC 0.38.0 sur S24) : portes et panneaux.

1. Tour Radio, ascenseur en panne (erreur 2) : la porte `L` (18, 0) est praticable pour que la
   cabine s'ouvre après Cenere ; avant, on avançait d'une case dans le mur sans rien voir. Une
   [FlagGate] invisible bloque la case tant que `johto_cenere_defeated` est bas (même mécanisme
   que les portes à clé) : on reste devant, et EXAMINER joue T-5.
2. Portes peintes fermées sans retour (erreurs 1 et 4) : un point EXAMINER sur la porte de chaque
   façade de Johto sans intérieur qu'on peut aborder (gare de Doublonville, poste de péage de la
   Route 43 ; la fermière de la Route 39 se tient devant la porte de sa ferme et parle). Textes :
   `data/dialogues/johto_portes_fermees.json` [D].
3. Souterrain de Doublonville (erreur 7) : le panneau, coincé dans la niche (4, 4) entre deux
   rideaux, passe devant les boutiques du sud, en (4, 8), lisible de tous côtés.

Édite les scènes en texte (une réécriture par Godot renumérote les ressources de toute la scène),
comme `tools/route_23_pontons.py`. Idempotent : retire puis repose les nœuds `Kevin*`. Les plans
(`tools/plans/`) portent les mêmes changements ; un outil de construction relancé doit être suivi
de ce script.

    python3 tools/johto_portes_et_panneaux.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPS = ROOT / "game/world/maps"
TILE = 96
FLAG_GATE = "res://game/world/flag_gate.gd"
INTERACT = "res://game/world/interactions/interact_point.gd"
ELEVATOR_CELL = (18, 0)
ELEVATOR_FLAG = "johto_cenere_defeated"
## Portes fermées : carte → [(nœud, première case, largeur en cases, dialogue)].
CLOSED_DOORS = {
    "goldenrod_city": [("KevinPorteGare", (57, 45), 5, "goldenrod_city_gare_fermee")],
    "route_43": [("KevinPortePeage", (15, 24), 1, "route_43_peage_ferme")],
}
SIGN_MAP = "goldenrod_underground"
SIGN_CELL = (4, 8)
## unique_id stables (un par nœud posé) [D].
UID_BASE = 1927110000


def world(cell):
    return cell[0] * TILE + TILE / 2, (cell[1] + 1) * TILE


def strip_kevin(text):
    return re.sub(r'\n\[node name="Kevin[^"]*"[^\n]*\]\n(?:[^\[\n][^\n]*\n)*', "\n", text)


def ensure_ext(text, path, rid):
    found = re.search(r'\[ext_resource type="Script" path="%s" id="([^"]+)"\]' % re.escape(path),
        text)
    if found:
        return text, found.group(1)
    last = list(re.finditer(r'\[ext_resource [^\n]*\]\n', text))[-1]
    line = '[ext_resource type="Script" path="%s" id="%s"]\n' % (path, rid)
    return text[:last.end()] + line + text[last.end():], rid


def finish(text):
    return re.sub(r"\n{3,}", "\n\n", text).rstrip("\n") + "\n"


def radio_tower(uid):
    for floor in range(1, 6):
        scene = MAPS / ("goldenrod_radio_tower_%df.tscn" % floor)
        text = strip_kevin(scene.read_text())
        text, gate_id = ensure_ext(text, FLAG_GATE, "kv_flag_gate")
        x, y = ELEVATOR_CELL[0] * TILE, ELEVATOR_CELL[1] * TILE
        text = finish(text) + (
            f'\n[node name="KevinAscenseurEnPanne" type="Node2D" parent="Entities" '
            f'unique_id={uid}]\n'
            f'position = Vector2({x}, {y})\n'
            f'script = ExtResource("{gate_id}")\n'
            f'unless_flags = Array[StringName]([&"{ELEVATOR_FLAG}"])\n'
            f'blocking_cells = Array[Vector2i]([Vector2i({ELEVATOR_CELL[0]}, '
            f'{ELEVATOR_CELL[1]})])\n')
        uid += 1
        scene.write_text(text)
    return uid


def closed_doors(uid):
    for map_id, doors in CLOSED_DOORS.items():
        scene = MAPS / ("%s.tscn" % map_id)
        text = strip_kevin(scene.read_text())
        text, point_id = ensure_ext(text, INTERACT, "kv_interact_point")
        text = finish(text)
        for name, cell, width, dialogue in doors:
            x, y = world(cell)
            text += (f'\n[node name="{name}" type="Marker2D" parent="Interactables" '
                     f'unique_id={uid}]\n'
                     f'position = Vector2({x:g}, {y:g})\n'
                     f'script = ExtResource("{point_id}")\n'
                     f'dialogue_id = &"{dialogue}"\n')
            if width > 1:
                text += f"size = Vector2i({width}, 1)\n"
            uid += 1
        scene.write_text(text)
    return uid


def underground_sign():
    scene = MAPS / ("%s.tscn" % SIGN_MAP)
    text = scene.read_text()
    x, y = world(SIGN_CELL)
    for node in ("PanneauSouterrainSign", "PanneauSouterrain"):
        pattern = re.compile(r'(\[node name="%s"[^\n]*\]\nposition = )Vector2\([^)]*\)' % node)
        text, count = pattern.subn(lambda m: m.group(1) + "Vector2(%g, %g)" % (x, y), text)
        assert count == 1, node
    # Lisible de tous côtés (il n'est plus contre un mur nord).
    text = re.sub(r'(dialogue_id = &"goldenrod_underground_panneau_souterrain"\n)facing = [^\n]*\n',
        r"\1", text)
    scene.write_text(text)


uid = radio_tower(UID_BASE)
uid = closed_doors(uid)
underground_sign()
print("johto_portes_et_panneaux : OK")
