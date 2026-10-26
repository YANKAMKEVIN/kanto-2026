#!/usr/bin/env python3
"""Lot musique du jalon Son (T8, docs/tech/jalon-son.md §1.11) : des FLAC de l'album Let's Go
fournis par Kevin (`~/Music/kanto-lets-go/`, noms d'origine) aux fichiers prêts à encoder.

Pour chaque morceau de `data/audio/tracks.json` :
1. retrouve son fichier par le titre (correspondance tolérante : « Vermillion », « From » au lieu
   de « Leaving », « (Boy's Version) »…) ;
2. morceau en boucle : les pistes d'album jouent la boucle deux fois puis finissent en fondu.
   La période P est la plus longue répétition presque exacte du spectre (au moins 80 % de P
   identique) ; la boucle commence peu après la fin de l'intro (A). Le fichier est coupé à
   A + P (intro + un tour) et `loop_offset` = A. P est affiné à l'échantillon près par
   corrélation ; l'écart résiduel à la jointure est mesuré (contrôle des clics) ;
3. jingle ou morceau sans boucle : silence final retiré ;
4. volume perçu ramené à −16 LUFS intégrés (gain simple, crête vraie ≤ −1 dBTP), mesuré par le
   filtre `ebur128` de ffmpeg ;
5. écrit un WAV 16 bits par identifiant et un rapport JSON (`loop_offset`, durées, LUFS, gain,
   qualité de la jointure).

Usage : python3 tools/audio/prepare_music.py [--src DOSSIER] [--out DOSSIER] [--only id,id]
  (défauts : ~/Music/kanto-lets-go, build/audio/music_wav ; rapport : <out>/report.json)
Rien n'est téléchargé : les fichiers sont ceux de Kevin (KHInsider, décision du 2026-10-25).
"""
import argparse
import json
import os
import re
import subprocess
import sys
import unicodedata

import numpy as np

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
RATE = 44100
TARGET_LUFS = -16.0
MAX_TRUE_PEAK = -1.0
HOP = 512
WIN = 2048
BANDS = 32
MIN_LOOP_S = 3.0
## Similarité lissée sur 2 s ; au-dessus de MATCH, deux passages sont « les mêmes ».
SMOOTH_S = 2.0
MATCH = 0.82
## Corrélation au-dessus de laquelle les deux tours sont identiques ; recherche ± 0,1 s.
EXACT = 0.98
SEARCH = 4410
## Périodes candidates évaluées à l'échantillon près.
## Points de mesure (part de la durée de la piste).
PROBES = (0.2, 0.3, 0.4, 0.5)
## Sous-échantillonnage du balayage des périodes.
DOWN = 4
PROBES_SLOW = (0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6)
## Fondu de la jointure : court si la répétition est exacte, plus long sinon.
FADE_EXACT_S = 0.02
FADE_LOOSE_S = 0.35
SILENCE_DB = -60.0

# Variantes de titres entre la table (MusicBrainz) et les noms des fichiers de Kevin.
EQUIVALENCES = [
	("vermillion", "vermilion"), ("to bill's", "to bill"), (" - from ", " leaving "),
	(": leaving", " leaving"), ("team rocket hideout", "rocket hideout"),
	("(boy's version)", "(boy version)"), ("! (girl's version)", " (girl version)"),
	("! (bad guys)", " (bad guy version)"), ("(gym leader)", "(gym leader battle)"),
]


def norm(title):
	t = unicodedata.normalize("NFKD", title).encode("ascii", "ignore").decode().lower()
	t = re.sub(r"^\d-\d\d\.\s*", "", t)
	t = re.sub(r"\.flac$", "", t)
	for a, b in EQUIVALENCES:
		t = t.replace(a, b)
	return re.sub(r"[^a-z0-9]+", " ", t).strip()


def match_files(tracks, src):
	files = {norm(f): f for f in os.listdir(src) if f.lower().endswith(".flac")}
	result = {}
	for tid, t in tracks.items():
		key = norm(t["title"])
		found = files.get(key)
		if found is None:
			close = [f for k, f in files.items() if key in k or k in key]
			found = close[0] if len(close) == 1 else None
		result[tid] = found
	return result


def decode(path):
	raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar",
		str(RATE), "-"], capture_output=True, check=True).stdout
	return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).copy()


def features(mono):
	"""Spectre en bandes logarithmiques, normalisé par trame (une trame = HOP échantillons)."""
	count = max(1, (len(mono) - WIN) // HOP)
	idx = np.arange(WIN)[None, :] + HOP * np.arange(count)[:, None]
	frames = mono[idx] * np.hanning(WIN)[None, :]
	mag = np.abs(np.fft.rfft(frames, axis=1))
	edges = np.unique(np.geomspace(2, mag.shape[1] - 1, BANDS + 1).astype(int))
	bands = np.stack([mag[:, a:b].sum(axis=1) for a, b in zip(edges[:-1], edges[1:])], axis=1)
	f = np.log1p(bands * 10.0)
	f -= f.mean(axis=1, keepdims=True)
	f /= np.linalg.norm(f, axis=1, keepdims=True) + 1e-9
	return f


def longest_run(mask):
	best, start, cur, cur_start = 0, 0, 0, 0
	for i, v in enumerate(mask):
		if v:
			if cur == 0:
				cur_start = i
			cur += 1
			if cur > best:
				best, start = cur, cur_start
		else:
			cur = 0
	return best, start


def find_loop(stereo):
	"""Balayage rapide (11 025 Hz), puis lent à pleine résolution avec plus de points s'il échoue."""
	return _scan(stereo, DOWN, PROBES) or _scan(stereo, 1, PROBES_SLOW)


def _scan(stereo, down, probe_parts):
	"""(A, P, fidélité) en échantillons, ou None si aucune boucle exacte.

	Balaye les périodes de MIN_LOOP_S à la moitié de la piste (pas de 0,15 s, chaque mesure
	cherche ± SEARCH autour) ; une période est exacte si, en au moins deux points de mesure, la
	suite se retrouve à l'identique avec le même décalage. La plus courte gagne (les multiples
	d'une boucle se répètent aussi). Le départ A est le premier point d'où tout se répète."""
	mono = stereo.mean(axis=1)
	length = len(mono)
	# Balayage sur un signal 4 fois plus court (11 025 Hz), affinage à 44 100 Hz.
	small = mono[: length // down * down].reshape(-1, down).mean(axis=1)
	rate = RATE // down
	step = int(0.15 * rate)
	for coarse in range(int(MIN_LOOP_S * rate), len(small) // 2 + rate, step):
		probes = [p for p in (int(len(small) * x) for x in probe_parts)
			if p + coarse + rate + SEARCH // down < len(small)]
		if len(probes) < 2:
			break
		hits = [(p,) + _best_shift(small, p, coarse, rate) for p in probes]
		good = [(p, shift) for p, ncc, shift in hits if ncc > EXACT - 0.01]
		if len(good) < 2:
			continue
		shifts = [shift for p, shift in good]
		shift = max(set(shifts), key=lambda x: sum(abs(x - y) <= 1 for y in shifts))
		if sum(abs(shift - y) <= 1 for y in shifts) < 2:
			continue
		probe = next(p for p, sh in good if abs(sh - shift) <= 1)
		ncc, fine = _best_shift(mono, probe * down, (coarse + shift) * down, RATE, down * 4)
		if ncc <= EXACT:
			continue
		period = (coarse + shift) * down + fine
		# Premier départ exact : par pas d'un quart de seconde depuis le début.
		for pos in range(int(0.25 * RATE), length - period - RATE, RATE // 4):
			ncc, d = _best_shift(mono, pos, period, RATE, 64)
			if ncc > EXACT and abs(d) <= 2:
				begin = pos + int(0.25 * RATE)
				if begin + period <= length:
					return begin, period + d, round(float(ncc), 4)
		return None
	return None


def _best_shift(mono, pos, coarse, rate=RATE, search=None):
	"""(corrélation normalisée, décalage) de mono[pos:pos+1 s] autour de pos + coarse, cherché
	à ± search échantillons (défaut : SEARCH ramené à rate)."""
	if search is None:
		search = SEARCH * rate // RATE
	w = rate
	ref = mono[pos: pos + w]
	lo = pos + coarse - search
	if lo < 0:
		return -1.0, 0
	seg = mono[lo: lo + w + 2 * search]
	if len(ref) < w or len(seg) < w + 2 * search:
		return -1.0, 0
	n = len(seg) + w
	size = 1 << (n - 1).bit_length()
	corr = np.fft.irfft(np.fft.rfft(seg, size) * np.conj(np.fft.rfft(ref, size)), size)
	corr = corr[: len(seg) - w + 1]
	energy = np.convolve(seg ** 2, np.ones(w), mode="valid")
	norm = corr / (np.sqrt(energy * np.dot(ref, ref)) + 1e-12)
	i = int(np.argmax(norm))
	return float(norm[i]), lo + i - pos - coarse


def seam_crossfade(cut, begin, fade):
	"""Fond la fin de la boucle dans ce qui précède son départ : la jointure (fin → begin) est
	continue même si les deux tours de l'album ne sont pas identiques."""
	n = min(fade, begin)
	if n <= 0:
		return cut
	w = np.linspace(0.0, 1.0, n)[:, None]
	out = cut.copy()
	out[len(cut) - n:] = cut[len(cut) - n:] * (1 - w) + cut[begin - n: begin] * w
	return out


def trim_silence(stereo):
	level = np.abs(stereo).max(axis=1)
	loud = np.nonzero(level > 10 ** (SILENCE_DB / 20))[0]
	if len(loud) == 0:
		return stereo
	return stereo[: min(len(stereo), loud[-1] + int(0.05 * RATE))]


def measure(stereo):
	"""(LUFS intégrés, crête vraie dBTP) par ffmpeg ebur128."""
	pcm = (np.clip(stereo, -1, 1) * 32767).astype("<i2").tobytes()
	out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-f", "s16le", "-ar", str(RATE),
		"-ac", "2", "-i", "-", "-af", "ebur128=peak=true", "-f", "null", "-"], input=pcm,
		capture_output=True).stderr.decode()
	summary = out[out.rfind("Summary:"):]
	lufs = float(re.search(r"I:\s+(-?[\d.]+) LUFS", summary).group(1))
	peak = float(re.search(r"Peak:\s+(-?[\d.]+|-inf) dBFS", summary).group(1)
		.replace("-inf", "-120"))
	return lufs, peak


def write_wav(path, stereo):
	import wave
	pcm = (np.clip(stereo, -1, 1) * 32767).round().astype("<i2")
	with wave.open(path, "wb") as w:
		w.setnchannels(2)
		w.setsampwidth(2)
		w.setframerate(RATE)
		w.writeframes(pcm.tobytes())


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("--src", default=os.path.expanduser("~/Music/kanto-lets-go"))
	parser.add_argument("--out", default=os.path.join(RACINE, "build", "audio", "music_wav"))
	parser.add_argument("--only", default="")
	args = parser.parse_args()
	with open(os.path.join(RACINE, "data", "audio", "tracks.json"), encoding="utf-8") as f:
		tracks = json.load(f)["tracks"]
	matches = match_files(tracks, args.src)
	missing = [tid for tid, f in matches.items() if f is None]
	if missing:
		print("Pistes introuvables :", ", ".join(missing))
		sys.exit(1)
	os.makedirs(args.out, exist_ok=True)
	report_path = os.path.join(args.out, "report.json")
	report = {}
	if os.path.isfile(report_path):
		with open(report_path, encoding="utf-8") as f:
			report = json.load(f)
	only = [x for x in args.only.split(",") if x]
	done = {}
	for tid, t in tracks.items():
		if only and tid not in only:
			continue
		name = os.path.basename(t["file"])[: -len(".ogg")]
		if name in done:
			report[tid] = dict(report[done[name]], shared_with=done[name])
			continue
		stereo = decode(os.path.join(args.src, matches[tid]))
		entry = {"source": matches[tid], "source_s": round(len(stereo) / RATE, 3)}
		if t.get("loop", False):
			found = find_loop(stereo)
			if found is None:
				entry["loop"] = "aucune boucle nette : piste entière, boucle depuis le début"
				cut = trim_silence(stereo)
				entry["loop_offset"] = 0.0
			else:
				begin, period, ncc = found
				fade = FADE_EXACT_S if ncc > EXACT else FADE_LOOSE_S
				cut = seam_crossfade(stereo[: begin + period], begin, int(fade * RATE))
				entry.update(loop_offset=round(begin / RATE, 6), loop_s=round(period / RATE, 3),
					loop_match=ncc, exact=ncc > EXACT)
		else:
			cut = trim_silence(stereo)
		lufs, peak = measure(cut if not t.get("loop") or "loop_s" not in entry
			else cut[int(entry["loop_offset"] * RATE):])
		gain = TARGET_LUFS - lufs
		if peak + gain > MAX_TRUE_PEAK:
			gain = MAX_TRUE_PEAK - peak
			entry["peak_limited"] = True
		cut = cut * (10 ** (gain / 20))
		write_wav(os.path.join(args.out, name + ".wav"), cut)
		entry.update(duration_s=round(len(cut) / RATE, 3), lufs_before=lufs,
			gain_db=round(gain, 2), peak_before=peak)
		report[tid] = entry
		done[name] = tid
		print(f"{tid:24} {entry['duration_s']:7.2f} s  boucle {entry.get('loop_offset', '-')}"
			f"  fidélité {entry.get('loop_match', '-')}  gain {gain:+.1f} dB")
	with open(report_path, "w", encoding="utf-8") as f:
		json.dump(report, f, ensure_ascii=False, indent="\t")
	print("Rapport :", report_path)


if __name__ == "__main__":
	main()
