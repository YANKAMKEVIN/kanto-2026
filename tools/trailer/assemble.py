#!/usr/bin/env python3
"""Montage de la bande-annonce v2 (J34) à partir des scènes rendues par `render.sh`.

Lit `tools/trailer/cuts.json` (plans dans l'ordre : source, point d'entrée, durée, zoom lent,
fondu enchaîné, niveau du son) et produit :
  - build/trailer/pokemake-trailer.mp4 : le master H.264 2340 × 1080 (à partager) ;
  - assets/ui/opening/trailer.ogv : la vidéo Theora (Vorbis) lue par l'ident dans le jeu ;
  - data/opening/trailer.json : la durée exacte, pour la partition de l'ident.

    python3 tools/trailer/assemble.py [--only-master] [--width 1560]

Format d'un plan de cuts.json :
  { "id": "01_chambre", "src": "depart", "in": 4.2, "dur": 4.5,
    "zoom": [1.0, 1.06],        # poussée lente (facultatif ; un seul nombre : zoom fixe)
    "xfade": 0.7,               # fondu enchaîné avec le plan précédent (défaut : coupe franche)
    "audio": 1.0,               # gain du son propre du plan (0 : muet)
    "focus": [0.5, 0.5] }       # centre du zoom en fraction de l'image (défaut : le centre)
`beds` : nappes sonores posées par-dessus la piste montée ({ "src", "in", "at", "dur", "gain",
"fade_in", "fade_out" }) : une musique qui court sous une série de coupes rapides.
`tail_black` : secondes de noir (silence) ajoutées à la fin.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "build/trailer/raw"
OUT = ROOT / "build/trailer"
CUTS = ROOT / "tools/trailer/cuts.json"
MASTER = OUT / "pokemake-trailer.mp4"
SHARE = OUT / "pokemake-trailer-720p.mp4"
OGV = ROOT / "assets/ui/opening/trailer.ogv"
DATA = ROOT / "data/opening/trailer.json"
FPS = 30
W, H = 2340, 1080
# Encodeur Theora compilé depuis les exemples de libtheora (voir docs/tech/jalon-34.md).
THEORA_ENCODER = os.environ.get("THEORA_ENCODER", "theora_encoder")


def run(cmd: list[str], **kw) -> None:
    print("  $", " ".join(str(c) for c in cmd)[:400])
    subprocess.run(cmd, check=True, **kw)


def probe_duration(path: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of",
                          "default=nw=1:nk=1", str(path)], check=True, capture_output=True, text=True)
    return float(out.stdout.strip())


def zoom_filter(zoom, focus) -> str:
    """Poussée lente : mise à l'échelle par image (z(t) linéaire sur la durée, `D` remplacé par
    l'appelant) puis rognage fixe W × H centré sur `focus` (fraction de l'image)."""
    if zoom is None:
        return ""
    if isinstance(zoom, (int, float)):
        z0 = z1 = float(zoom)
    else:
        z0, z1 = float(zoom[0]), float(zoom[1])
    fx, fy = (focus or [0.5, 0.5])
    z = f"({z0}+({z1}-{z0})*t/D)"
    return (f"scale=w='trunc(iw*{z}/2)*2':h='trunc(ih*{z}/2)*2':eval=frame:flags=bicubic,"
            f"crop={W}:{H}:x='(iw-{W})*{fx}':y='(ih-{H})*{fy}',")


def render_cut(index: int, cut: dict, tmp: Path) -> Path:
    src = RAW / f"{cut['src']}.avi"
    if not src.exists():
        sys.exit(f"source absente : {src}")
    out = tmp / f"cut_{index:02d}.mkv"
    dur = float(cut["dur"])
    vf = zoom_filter(cut.get("zoom"), cut.get("focus")).replace("/D", f"/{dur}")
    vf += f"scale={W}:{H},fps={FPS},format=yuv420p,setpts=PTS-STARTPTS"
    gain = float(cut.get("audio", 1.0))
    af = f"volume={gain},afade=t=in:d=0.04,afade=t=out:st={max(dur - 0.04, 0):.3f}:d=0.04,asetpts=PTS-STARTPTS"
    run(["ffmpeg", "-v", "error", "-y", "-ss", f"{float(cut['in']):.3f}", "-t", f"{dur:.3f}",
         "-i", str(src), "-vf", vf, "-af", af, "-c:v", "libx264", "-preset", "fast", "-crf", "12",
         "-c:a", "pcm_s16le", "-ar", "48000", "-ac", "2", str(out)])
    return out


def black_clip(seconds: float, tmp: Path) -> Path:
    out = tmp / "black.mkv"
    run(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", f"color=c=black:s={W}x{H}:r={FPS}",
         "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", f"{seconds:.3f}",
         "-c:v", "libx264", "-preset", "fast", "-crf", "12", "-c:a", "pcm_s16le", str(out)])
    return out


def assemble(clips: list[tuple[Path, float, float]], beds: list[dict], tmp: Path) -> Path:
    """Enchaîne les plans : fondu enchaîné (xfade / acrossfade) quand le plan en a un, sinon coupe
    franche ; `clips` = (fichier, durée, xfade avec le précédent)."""
    inputs: list[str] = []
    for path, _d, _x in clips:
        inputs += ["-i", str(path)]
    bed_offset = len(clips)
    for bed in beds:
        inputs += ["-ss", f"{float(bed['in']):.3f}", "-t", f"{float(bed['dur']):.3f}",
                   "-i", str(RAW / f"{bed['src']}.avi")]
    filters: list[str] = []
    # Vidéo : chaîne de xfade (une coupe franche = un fondu d'une image).
    v_prev, a_prev = "[0:v]", "[0:a]"
    timeline = clips[0][1]
    for i in range(1, len(clips)):
        _path, d, x = clips[i]
        x = max(float(x), 1.0 / FPS)
        offset = timeline - x
        vo, ao = f"[v{i}]", f"[a{i}]"
        filters.append(f"{v_prev}[{i}:v]xfade=transition=fade:duration={x:.3f}:offset={offset:.3f}{vo}")
        filters.append(f"{a_prev}[{i}:a]acrossfade=d={x:.3f}:c1=tri:c2=tri{ao}")
        v_prev, a_prev = vo, ao
        timeline = offset + d
    # Nappes : mixées par-dessus, placées à `at`.
    if beds:
        mix_inputs = a_prev
        for j, bed in enumerate(beds):
            label = f"[bed{j}]"
            d = float(bed["dur"])
            fi, fo = float(bed.get("fade_in", 0.5)), float(bed.get("fade_out", 1.0))
            delay = int(float(bed["at"]) * 1000)
            filters.append(
                f"[{bed_offset + j}:a]volume={float(bed.get('gain', 0.8))},afade=t=in:d={fi},"
                f"afade=t=out:st={max(d - fo, 0):.3f}:d={fo},adelay={delay}|{delay}{label}")
            mix_inputs += label
        filters.append(f"{mix_inputs}amix=inputs={len(beds) + 1}:duration=first:normalize=0[amix]")
        a_prev = "[amix]"
    filters.append(f"{a_prev}alimiter=limit=0.95[aout]")
    out = tmp / "assembled.mkv"
    run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", ";".join(filters),
         "-map", v_prev, "-map", "[aout]", "-c:v", "libx264", "-preset", "slow", "-crf", "14",
         "-c:a", "pcm_s16le", "-ar", "48000", str(out)])
    return out


def encode_master(assembled: Path) -> None:
    MASTER.parent.mkdir(parents=True, exist_ok=True)
    run(["ffmpeg", "-v", "error", "-y", "-i", str(assembled), "-c:v", "libx264", "-preset", "slow",
         "-crf", "17", "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-c:a", "aac", "-b:a", "192k",
         str(MASTER)])
    # Copie légère à partager (téléphone, Telegram).
    run(["ffmpeg", "-v", "error", "-y", "-i", str(assembled), "-vf", "scale=1560:720:flags=lanczos",
         "-c:v", "libx264", "-preset", "slow", "-crf", "21", "-pix_fmt", "yuv420p", "-movflags",
         "+faststart", "-c:a", "aac", "-b:a", "160k", str(SHARE)])


def encode_theora(assembled: Path, width: int, quality: int, tmp: Path) -> None:
    """Theora + Vorbis par l'encodeur d'exemple de libtheora (ffmpeg d'Homebrew n'a pas
    libtheora) : y4m et wav intermédiaires."""
    height = int(round(width * H / W / 2)) * 2
    y4m = tmp / "video.y4m"
    wav = tmp / "audio.wav"
    # Plage vidéo limitée (16-235) : le décodeur Theora de Godot convertit en BT.601 studio ;
    # les captures Movie Maker (MJPEG) sont en plage pleine.
    # L'étiquette « XCOLORRANGE=LIMITED » de l'en-tête y4m fait perdre le cadrage à l'encodeur
    # d'exemple : l'en-tête est réécrit sans elle (les données restent en plage limitée).
    cmd = ["ffmpeg", "-v", "error", "-i", str(assembled), "-an", "-vf",
           f"scale={width}:{height}:flags=lanczos:in_range=pc:out_range=tv", "-pix_fmt", "yuv420p",
           "-color_range", "tv", "-f", "yuv4mpegpipe", "-"]
    print("  $", " ".join(cmd)[:400])
    with subprocess.Popen(cmd, stdout=subprocess.PIPE) as proc, open(y4m, "wb") as out:
        header = proc.stdout.readline()
        out.write(b" ".join(t for t in header.split(b" ") if not t.startswith(b"XCOLORRANGE")).rstrip(b"\n") + b"\n")
        shutil.copyfileobj(proc.stdout, out, 1 << 22)
    if proc.returncode != 0:
        sys.exit("ffmpeg y4m : échec")
    # WAV nu (en-tête « fmt » de 16 octets, sans métadonnées) : le lecteur de l'encodeur d'exemple
    # ne connaît pas les blocs LIST.
    run(["ffmpeg", "-v", "error", "-y", "-i", str(assembled), "-vn", "-ac", "2", "-ar", "44100",
         "-c:a", "pcm_s16le", "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
         "-rf64", "never", str(wav)])
    OGV.parent.mkdir(parents=True, exist_ok=True)
    encoder = shutil.which(THEORA_ENCODER) or THEORA_ENCODER
    run([encoder, "-v", str(quality), "-a", "3", "-o", str(OGV), str(wav), str(y4m)])
    print(f"  {OGV.relative_to(ROOT)} : {OGV.stat().st_size / 1e6:.1f} Mo, {width} × {height}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only-master", action="store_true", help="pas de Theora ni de données")
    parser.add_argument("--width", type=int, default=1560, help="largeur de la vidéo du jeu")
    parser.add_argument("--quality", type=int, default=5, help="qualité Theora (0 à 10) [D] : 5 ≈ 17 Mo à 1560 × 720")
    parser.add_argument("--from-master", action="store_true",
                        help="ne refait que la vidéo du jeu (Theora + données) depuis le master")
    args = parser.parse_args()
    spec = json.loads(CUTS.read_text())
    cuts = spec["cuts"]
    with tempfile.TemporaryDirectory(prefix="trailer_", dir=OUT) as tmpdir:
        tmp = Path(tmpdir)
        if args.from_master:
            total = probe_duration(MASTER)
            encode_theora(MASTER, args.width, args.quality, tmp)
            DATA.write_text(json.dumps({"video": "res://" + OGV.relative_to(ROOT).as_posix(),
                "seconds": round(total, 2), "letterbox": spec.get("letterbox", 0.07)},
                ensure_ascii=False, indent=1) + "\n")
            return
        clips: list[tuple[Path, float, float]] = []
        for i, cut in enumerate(cuts):
            print(f"[{i + 1}/{len(cuts)}] {cut['id']} ({cut['src']} @ {cut['in']} s, {cut['dur']} s)")
            clips.append((render_cut(i, cut, tmp), float(cut["dur"]), float(cut.get("xfade", 0.0))))
        tail = float(spec.get("tail_black", 0.0))
        if tail > 0:
            clips.append((black_clip(tail, tmp), tail, 0.0))
        assembled = assemble(clips, spec.get("beds", []), tmp)
        total = probe_duration(assembled)
        print(f"durée montée : {total:.2f} s")
        encode_master(assembled)
        print(f"  {MASTER.relative_to(ROOT)} : {MASTER.stat().st_size / 1e6:.1f} Mo ; "
              f"{SHARE.relative_to(ROOT)} : {SHARE.stat().st_size / 1e6:.1f} Mo")
        if args.only_master:
            return
        encode_theora(assembled, args.width, args.quality, tmp)
        data = {"video": "res://" + OGV.relative_to(ROOT).as_posix(), "seconds": round(total, 2),
                "letterbox": spec.get("letterbox", 0.07)}
        DATA.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n")
        print(f"  {DATA.relative_to(ROOT)} : {data}")


if __name__ == "__main__":
    main()
