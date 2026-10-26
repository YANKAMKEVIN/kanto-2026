#!/usr/bin/env python3
"""Sons courts du jalon Son (cris SonB, bruitages SonC ; docs/tech/jalon-son.md §1.11) : un
fichier d'entrée (OGG, MP3, WAV, FLAC — le format réel est lu, pas l'extension) devient un OGG
Vorbis **mono q4**, silence de fin retiré, crête ramenée à PEAK_DB (un volume perçu intégré n'a
pas de sens sur moins d'une demi-seconde).

Usage : python3 tools/audio/prepare_sfx.py ENTRÉE SORTIE.ogg [--peak -3]
        python3 tools/audio/prepare_sfx.py --batch DOSSIER_ENTRÉE DOSSIER_SORTIE [--peak -3]
Les fichiers téléchargés restent dans leur dossier ; seuls les OGG produits vont dans `assets/`.
"""
import argparse
import os
import re
import subprocess
import sys

PEAK_DB = -3.0


def max_volume(path):
	out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af",
		"volumedetect", "-f", "null", "-"], capture_output=True).stderr.decode()
	found = re.search(r"max_volume:\s+(-?[\d.]+) dB", out)
	return float(found.group(1)) if found else None


def convert(src, dst, peak):
	level = max_volume(src)
	if level is None:
		raise RuntimeError(f"illisible : {src}")
	gain = peak - level
	tmp = dst + ".wav"
	subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-ac", "1", "-map_metadata", "-1",
		"-fflags", "+bitexact", "-af",
		f"volume={gain:.2f}dB,areverse,silenceremove=start_periods=1:start_threshold=-60dB,"
		"areverse", tmp], check=True)
	subprocess.run(["oggenc", "-Q", "-q", "4", "-o", dst, tmp], check=True)
	os.remove(tmp)
	return gain


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("src")
	parser.add_argument("dst")
	parser.add_argument("--batch", action="store_true")
	parser.add_argument("--peak", type=float, default=PEAK_DB)
	args = parser.parse_args()
	if not args.batch:
		convert(args.src, args.dst, args.peak)
		return
	os.makedirs(args.dst, exist_ok=True)
	failed = []
	for name in sorted(os.listdir(args.src)):
		base, _ = os.path.splitext(name)
		try:
			convert(os.path.join(args.src, name), os.path.join(args.dst, base + ".ogg"), args.peak)
		except (RuntimeError, subprocess.CalledProcessError) as error:
			failed.append(f"{name} : {error}")
	if failed:
		print("\n".join(failed))
		sys.exit(1)


if __name__ == "__main__":
	main()
