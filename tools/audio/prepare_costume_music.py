#!/usr/bin/env python3
"""Musiques des costumes (docs/design/dossier-costumes.md §2 ter, CO-16 à CO-20) : des fichiers
fournis par Kevin (`~/Downloads/PokeMakeThemes/`, noms d'origine) aux OGG du jeu.

Pour chaque morceau `costume_*` de `data/audio/tracks.json` :
1. retrouve son fichier par un extrait de son nom (table SOURCES) ;
2. combat : silence initial retiré, coupé à MAX_BATTLE_S au plus avec un fondu final, bouclé
   depuis le début (`loop_offset` 0 : ces fichiers ne sont pas des pistes d'album à deux tours) ;
3. jingle : JINGLE_S secondes à partir du premier passage franc (le volume atteint la moitié de
   son niveau courant, ce qui saute un silence ou une intro parlée), fondu de sortie ;
4. volume ramené à −16 LUFS (filtre `loudnorm` de ffmpeg), puis OGG q3 (oggenc).
Sortie : assets/audio/music/costumes/<id>.ogg, **ignoré par Git** (CO-19) : les fichiers restent
sur le Mac tant que le Go juridique n'est pas étendu et que le dépôt est public.
Usage : python3 tools/audio/prepare_costume_music.py [--src DOSSIER] [--only id,id]
Rien n'est téléchargé.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

import numpy as np

RACINE = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(RACINE, "assets", "audio", "music", "costumes")
TARGET_LUFS = -16.0
MAX_BATTLE_S = 240.0
BATTLE_FADE_S = 3.0
JINGLE_S = 5.0
JINGLE_FADE_S = 1.0
ANALYSIS_RATE = 8000
## Extrait du nom de fichier → identifiant (sans « costume_ »).
SOURCES = {
    "boulder_battle": "Gurenge (Instrumental)",
    "boulder_town": "Kamado Tanjirou",
    "cascade_battle": "Overtaken",
    "cascade_town": "We Are!",
    "thunder_battle": "Driving With The Top Down",
    "thunder_town": "IRON MAN TRIBUTE",
    "rainbow_battle": "Hyrule Field",
    "rainbow_town": "Zelda's Lullaby",
    "soul_battle": "Strong and Strike",
    "soul_battle_2": "Girei",
    "soul_town": "Blue Bird",
    "soul_town_2": "Naruto Shippuden Op",
    "marsh_battle": "YOU SAY RUN",
    "marsh_town": "Peace Sign",
    "volcano_battle": "Ultimate Battle 22",
    "volcano_battle_2": "Dragon ball Z soundtrack 3",
    "volcano_town": "CHA-LA",
    "earth_battle": "Molossus",
    "earth_town": "The Batman Theme",
}


def find_source(src: str, needle: str) -> str:
    matches = [f for f in sorted(os.listdir(src)) if needle.lower() in f.lower()]
    if len(matches) != 1:
        sys.exit("« %s » : %d fichiers trouvés dans %s" % (needle, len(matches), src))
    return os.path.join(src, matches[0])


def mono(path: str) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar",
                          str(ANALYSIS_RATE), "-f", "f32le", "-"], capture_output=True,
                         check=True).stdout
    return np.frombuffer(raw, dtype=np.float32)


def first_strong(samples: np.ndarray) -> float:
    """Début (s) du premier passage franc : RMS sur 0,25 s ≥ la moitié du 75e centile."""
    win = ANALYSIS_RATE // 4
    count = len(samples) // win
    rms = np.sqrt(np.mean(samples[: count * win].reshape(count, win) ** 2, axis=1))
    level = np.percentile(rms, 75)
    loud = np.nonzero(rms >= level * 0.5)[0]
    return float(loud[0] * win / ANALYSIS_RATE) if len(loud) else 0.0


def leading_silence(samples: np.ndarray) -> float:
    loud = np.nonzero(np.abs(samples) > 10 ** (-50 / 20))[0]
    return float(loud[0] / ANALYSIS_RATE) if len(loud) else 0.0


def prepare(track_id: str, src_path: str, jingle: bool) -> dict:
    samples = mono(src_path)
    total = len(samples) / ANALYSIS_RATE
    if jingle:
        start = first_strong(samples)
        length = min(JINGLE_S, total - start)
        fade = JINGLE_FADE_S
    else:
        start = leading_silence(samples)
        length = min(MAX_BATTLE_S, total - start)
        fade = BATTLE_FADE_S if length < total - start else 0.5
    filters = "atrim=start=%.3f:duration=%.3f,asetpts=PTS-STARTPTS,afade=t=in:d=0.05," \
        "afade=t=out:st=%.3f:d=%.3f,loudnorm=I=%.1f:TP=-1.0:LRA=11" % (
            start, length, max(length - fade, 0.0), fade, TARGET_LUFS)
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, track_id + ".ogg")
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, track_id + ".wav")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src_path, "-af", filters, "-ar",
                        "44100", "-ac", "2", "-c:a", "pcm_s16le", wav], check=True)
        subprocess.run(["oggenc", "-Q", "-q", "3", "-o", out, wav], check=True)
    return {"source": os.path.basename(src_path), "start_s": round(start, 2),
            "length_s": round(length, 2), "kb": os.path.getsize(out) // 1024}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", default=os.path.expanduser("~/Downloads/PokeMakeThemes"))
    parser.add_argument("--only", default="")
    args = parser.parse_args()
    tracks = json.load(open(os.path.join(RACINE, "data", "audio", "tracks.json"),
                            encoding="utf-8"))["tracks"]
    only = [s for s in args.only.split(",") if s]
    report = {}
    for key, needle in SOURCES.items():
        track_id = "costume_" + key
        if track_id not in tracks or (only and key not in only):
            continue
        jingle = tracks[track_id]["kind"] == "jingle"
        report[key] = prepare(key, find_source(args.src, needle), jingle)
        print("%-18s %s" % (key, report[key]))
    with open(os.path.join(OUT, "report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
