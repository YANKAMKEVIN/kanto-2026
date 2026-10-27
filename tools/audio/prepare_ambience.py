#!/usr/bin/env python3
"""Boucles d'ambiance du jalon Son (SonC, T12 ; docs/tech/jalon-son.md §1.6, §3.4) : un fichier
CC0 (OpenGameArt, accord de Kevin du 2026-10-25) devient une boucle **sans couture** : sa fin
est fondue dans son début (FADE_S), le fichier raccourci d'autant boucle depuis 0. Mono, volume
perçu ramené à −16 LUFS comme la musique (`ambiences.json` le joue −18 dB plus bas), OGG q3.

Usage : python3 tools/audio/prepare_ambience.py ENTRÉE SORTIE.ogg [--max 60]
  --max : durée maximale gardée (secondes), pour le poids de l'APK.
"""
import argparse
import os
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import prepare_music  # noqa: E402

RATE = 44100
FADE_S = 1.5
TARGET = -16.0


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("src")
	parser.add_argument("dst")
	parser.add_argument("--max", type=float, default=60.0)
	args = parser.parse_args()
	stereo = prepare_music.decode(args.src)[: int(args.max * RATE)]
	# Fondu de FADE_S, au plus un quart du fichier (une vague de 4 s boucle sur 1 s).
	fade = min(int(FADE_S * RATE), len(stereo) // 4)
	if fade < RATE // 4:
		raise SystemExit(f"trop court pour boucler : {args.src}")
	w = np.linspace(0.0, 1.0, fade)[:, None]
	# Fin fondue dans le début : la jointure (fin → 0) joue la suite naturelle du début.
	looped = stereo[: len(stereo) - fade].copy()
	looped[:fade] = stereo[len(stereo) - fade:] * (1 - w) + stereo[:fade] * w
	mono = looped.mean(axis=1, keepdims=True).repeat(2, axis=1)
	lufs, peak = prepare_music.measure(mono)
	gain = min(TARGET - lufs, -1.0 - peak)
	mono = mono * (10 ** (gain / 20))
	tmp = args.dst + ".wav"
	prepare_music.write_wav(tmp, mono)
	subprocess.run(["oggenc", "-Q", "-q", "3", "--downmix", "-o", args.dst, tmp], check=True)
	os.remove(tmp)
	print(f"{os.path.basename(args.dst)} : {len(mono) / RATE:.1f} s, {lufs:.1f} → "
		f"{lufs + gain:.1f} LUFS")


if __name__ == "__main__":
	main()
