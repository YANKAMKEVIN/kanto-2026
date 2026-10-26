#!/usr/bin/env python3
"""Mesure des fichiers son du jalon Son (docs/tech/jalon-son.md §1.11, T8).

Pour chaque morceau présent de `data/audio/tracks.json` : poids, durée, volume perçu (LUFS
intégrés, ffmpeg `ebur128`), crête vraie, et **contrôle de la jointure** des morceaux en boucle :
le fichier OGG est décodé, la fin de la boucle est recollée au point de départ (`loop_offset`) et
le saut d'échantillon à la jointure est comparé aux sauts ordinaires du morceau (un clic donne un
saut bien plus grand que d'habitude).

Usage : python3 tools/audio/measure_audio.py [--json FICHIER]
Code de sortie 1 si un fichier manque, une jointure claque ou un volume sort de −16 ± 1 LUFS.
"""
import argparse
import json
import os
import re
import subprocess
import sys

import numpy as np

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
RATE = 44100
TARGET = -16.0
TOLERANCE = 1.0
# Saut à la jointure toléré : au plus ce multiple du 99,9e centile des sauts du morceau.
SEAM_FACTOR = 1.5


def decode(path):
	raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar",
		str(RATE), "-"], capture_output=True, check=True).stdout
	return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2)


def loudness(path, start=0.0):
	"""LUFS intégrés et crête ; un morceau en boucle est mesuré sur sa boucle (à partir de
	[param start]), comme à la normalisation (une intro plus calme ne compte pas)."""
	out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-ss", str(start), "-i", path,
		"-af",
		"ebur128=peak=true", "-f", "null", "-"], capture_output=True).stderr.decode()
	summary = out[out.rfind("Summary:"):]
	lufs = float(re.search(r"I:\s+(-?[\d.]+) LUFS", summary).group(1))
	peak = re.search(r"Peak:\s+(-?[\d.]+|-inf) dBFS", summary).group(1)
	return lufs, float(peak.replace("-inf", "-120"))


def seam(stereo, offset):
	"""(saut à la jointure, seuil) : différence entre le dernier échantillon et celui du départ."""
	start = int(round(offset * RATE))
	if start >= len(stereo) - 1:
		return None
	jump = float(np.abs(stereo[start] - stereo[-1]).max())
	diffs = np.abs(np.diff(stereo, axis=0)).max(axis=1)
	return jump, float(np.percentile(diffs, 99.9)) * SEAM_FACTOR


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("--json", default="")
	args = parser.parse_args()
	with open(os.path.join(RACINE, "data", "audio", "tracks.json"), encoding="utf-8") as f:
		tracks = json.load(f)["tracks"]
	rows, errors, total, seen = {}, [], 0, set()
	for tid, t in tracks.items():
		path = os.path.join(RACINE, t["file"][len("res://"):])
		if not os.path.isfile(path):
			if not t.get("expected"):
				errors.append(f"{tid} : fichier absent ({t['file']})")
			continue
		size = os.path.getsize(path)
		if path not in seen:
			total += size
			seen.add(path)
		stereo = decode(path)
		lufs, peak = loudness(path, t.get("loop_offset", 0.0) if t.get("loop") else 0.0)
		row = {"size_kb": round(size / 1024), "duration_s": round(len(stereo) / RATE, 2),
			"lufs": lufs, "peak_dbfs": peak}
		if abs(lufs - TARGET) > TOLERANCE and not t["kind"] == "jingle":
			errors.append(f"{tid} : {lufs} LUFS (attendu {TARGET} ± {TOLERANCE})")
		if t.get("loop"):
			result = seam(stereo, t.get("loop_offset", 0.0))
			if result is not None:
				jump, limit = result
				row["seam_jump"], row["seam_limit"] = round(jump, 4), round(limit, 4)
				if jump > limit:
					errors.append(f"{tid} : jointure qui claque (saut {jump:.3f} > {limit:.3f})")
		rows[tid] = row
		print(f"{tid:24} {row['size_kb']:6} Ko {row['duration_s']:7.2f} s {lufs:6.1f} LUFS "
			f"crête {peak:5.1f}  jointure {row.get('seam_jump', '-')}/{row.get('seam_limit', '-')}")
	print(f"Total : {total / 1024 / 1024:.1f} Mo, {len(seen)} fichiers.")
	if args.json:
		with open(args.json, "w", encoding="utf-8") as f:
			json.dump({"total_mb": round(total / 1024 / 1024, 2), "tracks": rows}, f,
				ensure_ascii=False, indent="\t")
	if errors:
		print("\n".join(errors))
		sys.exit(1)


if __name__ == "__main__":
	main()
