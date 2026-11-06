#!/usr/bin/env python3
"""Montage de la bande-annonce v2 (J34) à partir des scènes rendues par `render.sh`.

Lit `tools/trailer/cuts.json` (plans dans l'ordre : source, point d'entrée, durée, zoom lent,
fondu enchaîné, niveau du son) et produit :
  - build/trailer/pokemake-trailer.mp4 : le master H.264 2340 × 1080 (à partager) ;
  - assets/ui/opening/trailer.ogv : la vidéo Theora (Vorbis) lue par l'ident dans le jeu ;
  - data/opening/trailer.json : la durée exacte, pour la partition de l'ident.

    python3 tools/trailer/assemble.py [--only-master] [--width 1560]
    python3 tools/trailer/assemble.py --cuts tools/trailer/cuts_v3_kanto.json --tag v3

`--tag` (bande-annonce v3) : le montage garde son propre fichier
(build/trailer/pokemake-trailer-<tag>.mp4), ne touche ni à la vidéo du jeu ni à ses données, et
lit ses scènes dans build/trailer/raw_<tag>/ : deux versions se comparent sans s'écraser.
`--game` avec `--tag` : écrit au contraire la vidéo du jeu et ses données, sans le logo de fin.

Format d'un plan de cuts.json :
  { "id": "01_chambre", "src": "depart", "in": 4.2, "dur": 4.5,
    "zoom": [1.0, 1.06],        # poussée lente (facultatif ; un seul nombre : zoom fixe)
    "xfade": 0.7,               # fondu enchaîné avec le plan précédent (défaut : coupe franche)
    "audio": 1.0,               # gain du son propre du plan (0 : muet)
    "focus": [0.5, 0.5] }       # centre du zoom en fraction de l'image (défaut : le centre)
`beds` : nappes sonores posées par-dessus la piste montée ({ "src", "in", "at", "dur", "gain",
"fade_in", "fade_out" }) : une musique qui court sous une série de coupes rapides.
`music` : un seul morceau du jeu sous toute la bande-annonce ({ "track": "res://assets/audio/music/…",
"start", "gain", "fade_in", "fade_out" }) ; `default_audio` : gain par défaut des sons propres ;
`gain` : gain global avant le limiteur (v2.1 : la vidéo jouait ≈ 6 dB sous le jeu).
Un plan `{ "card": "Texte du carton", "dur": 1.5 }` est un carton doré sur le fond de l'ident.
`tail_black` : secondes de noir (silence) ajoutées à la fin.
Un plan `{ "logo": "assets/…png", "dur": 3 }` : le logo sur le fond de l'ident, en fondu.
Un plan `{ "black": 0.5 }` est un noir muet au milieu du montage.
Un plan `{ "id", "split": [{ "src", "in" }, …], "dur" }` montre plusieurs scènes en colonnes.
`"title": { "text", "pos": "top|mid|low", "size", "dur", "align": "right" }` sur un plan : texte posé sur l'image,
en fondu, à partir du début de ce plan (`dur` : défaut, la durée du plan ; il peut en couvrir plusieurs).
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

from PIL import Image, ImageDraw, ImageFont

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
# Par défaut : celui compilé dans build/trailer/ (docs/tech/jalon-34.md), sinon le PATH.
_LOCAL_ENCODER = ROOT / "build/trailer/theora_encoder"
THEORA_ENCODER = os.environ.get("THEORA_ENCODER",
                                str(_LOCAL_ENCODER) if _LOCAL_ENCODER.exists() else "theora_encoder")
# Cartons entre les scènes (v2.1, demande de Kevin : « des textes entre les vidéos ») : mêmes
# couleurs et même police que le carton « Les studios Kevin & Co » de l'ident (UiTokens).
CARD_BG = (0x14, 0x0F, 0x0B)
CARD_TEXT = (0xF3, 0xD3, 0x7C)
CARD_FONT = ROOT / "assets/fonts/cinzel/Cinzel.ttf"
CARD_FONT_SIZE = 88
CARD_FADE = 0.4
TITLE_STROKE = 7


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


def split_clip(index: int, cut: dict, tmp: Path) -> Path:
    """Plusieurs scènes côte à côte : la bande centrale de chacune, séparée par un filet noir."""
    parts = cut["split"]
    dur = float(cut["dur"])
    width = W // len(parts)
    inputs: list[str] = []
    chains: list[str] = []
    for i, part in enumerate(parts):
        inputs += ["-ss", f"{float(part['in']):.3f}", "-t", f"{dur:.3f}", "-i", str(RAW / f"{part['src']}.avi")]
        chains.append(f"[{i}:v]crop={width - 6}:{H}:{(W - width) // 2 + 3}:0,pad={width}:{H}:3:0:black,"
                      f"fps={FPS},setpts=PTS-STARTPTS[c{i}]")
    labels = "".join(f"[c{i}]" for i in range(len(parts)))
    # `mask` : [y, h] : bande recouverte (phrases du jeu trop longues pour une colonne).
    mask = ""
    if cut.get("mask"):
        mask = f"drawbox=x=0:y={cut['mask'][0]}:w={W}:h={cut['mask'][1]}:color=0x070A16:t=fill,"
    chains.append(f"{labels}hstack=inputs={len(parts)},scale={W}:{H},{mask}format=yuv420p[v]")
    gain = float(cut.get("audio", 1.0))
    chains.append(f"[0:a]volume={gain},asetpts=PTS-STARTPTS[a]")
    out = tmp / f"cut_{index:02d}.mkv"
    run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", ";".join(chains), "-map", "[v]",
         "-map", "[a]", "-c:v", "libx264", "-preset", "fast", "-crf", "12", "-c:a", "pcm_s16le",
         "-ar", "48000", "-ac", "2", str(out)])
    return out


def title_image(index: int, text: str, size: int, tmp: Path) -> tuple[Path, int, int]:
    """Texte doré, contour sombre : reste lisible sur tout décor, à la taille d'un téléphone."""
    font = ImageFont.truetype(str(CARD_FONT), size)
    font.set_variation_by_axes([700])
    probe = ImageDraw.Draw(Image.new("RGBA", (8, 8)))
    box = probe.textbbox((0, 0), text, font=font, stroke_width=TITLE_STROKE)
    w, h = box[2] - box[0] + 40, box[3] - box[1] + 40
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(image).text((20 - box[0], 20 - box[1]), text, font=font, fill=CARD_TEXT + (255,),
                               stroke_width=TITLE_STROKE, stroke_fill=(0x14, 0x0F, 0x0B, 255))
    png = tmp / f"title_{index:02d}.png"
    image.save(png)
    return png, w, h


def apply_titles(assembled: Path, titles: list[dict], tmp: Path) -> Path:
    """Pose les textes sur le montage, chacun en fondu, sans toucher au son."""
    if not titles:
        return assembled
    inputs: list[str] = ["-i", str(assembled)]
    chains: list[str] = []
    prev = "[0:v]"
    total = probe_duration(assembled)
    for i, title in enumerate(titles):
        png, w, h = title_image(i, title["text"], int(title.get("size", 92)), tmp)
        at, dur = float(title["at"]), float(title["dur"])
        y = {"top": 70, "mid": (H - h) // 2, "low": H - h - 90}[title.get("pos", "low")]
        fade = min(0.25, dur / 3)
        inputs += ["-loop", "1", "-framerate", str(FPS), "-t", f"{total:.3f}", "-i", str(png)]
        chains.append(f"[{i + 1}:v]format=rgba,fade=t=in:st={at:.3f}:d={fade}:alpha=1,"
                      f"fade=t=out:st={at + dur - fade:.3f}:d={fade}:alpha=1[t{i}]")
        x = W - w - 110 if title.get("align") == "right" else (W - w) // 2
        chains.append(f"{prev}[t{i}]overlay=x={x}:y={y}:enable='between(t,{at:.3f},{at + dur:.3f})'[o{i}]")
        prev = f"[o{i}]"
    out = tmp / "titled.mkv"
    run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", ";".join(chains), "-map", prev,
         "-map", "0:a", "-c:v", "libx264", "-preset", "fast", "-crf", "14", "-c:a", "copy", str(out)])
    return out


def logo_clip(index: int, cut: dict, tmp: Path) -> Path:
    """Le logo sur le fond de l'ident, en fondu, légère poussée : le point final de la vidéo."""
    logo = Image.open(ROOT / cut["logo"]).convert("RGBA")
    logo.thumbnail((int(W * 0.5), int(H * 0.62)), Image.LANCZOS)
    image = Image.new("RGB", (W, H), CARD_BG)
    image.paste(logo, ((W - logo.width) // 2, (H - logo.height) // 2), logo)
    png = tmp / f"logo_{index:02d}.png"
    image.save(png)
    seconds = float(cut["dur"])
    out = tmp / f"cut_{index:02d}.mkv"
    z = f"(1+0.05*t/{seconds})"
    run(["ffmpeg", "-v", "error", "-y", "-loop", "1", "-framerate", str(FPS), "-i", str(png),
         "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", f"{seconds:.3f}", "-vf",
         f"scale=w='trunc(iw*{z}/2)*2':h='trunc(ih*{z}/2)*2':eval=frame:flags=bicubic,"
         f"crop={W}:{H},fade=t=in:d=0.6,fade=t=out:st={seconds - 0.6:.3f}:d=0.6,format=yuv420p",
         "-c:v", "libx264", "-preset", "fast", "-crf", "12", "-c:a", "pcm_s16le", "-shortest", str(out)])
    return out


def card_clip(index: int, text: str, seconds: float, tmp: Path, fade_max: float = CARD_FADE) -> Path:
    """Carton de texte doré sur le fond de l'ident, entrée et sortie en fondu, muet."""
    png = tmp / f"card_{index:02d}.png"
    image = Image.new("RGB", (W, H), CARD_BG)
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(str(CARD_FONT), CARD_FONT_SIZE)
    lines = text.split("\n")
    heights = [draw.textbbox((0, 0), line, font=font) for line in lines]
    gap = 24
    total = sum(b[3] - b[1] for b in heights) + gap * (len(lines) - 1)
    y = (H - total) / 2
    for line, box in zip(lines, heights):
        width = box[2] - box[0]
        draw.text(((W - width) / 2 - box[0], y - box[1]), line, font=font, fill=CARD_TEXT)
        y += box[3] - box[1] + gap
    image.save(png)
    out = tmp / f"card_{index:02d}.mkv"
    fade = min(fade_max, seconds / 2)
    run(["ffmpeg", "-v", "error", "-y", "-loop", "1", "-framerate", str(FPS), "-i", str(png),
         "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", f"{seconds:.3f}",
         "-vf", f"fade=t=in:d={fade},fade=t=out:st={seconds - fade:.3f}:d={fade},format=yuv420p",
         "-c:v", "libx264", "-preset", "fast", "-crf", "12", "-c:a", "pcm_s16le", "-shortest", str(out)])
    return out


def music_path(track: str) -> Path:
    """Chemin local d'un morceau du jeu (`res://…`)."""
    return ROOT / track.removeprefix("res://")


def black_clip(seconds: float, tmp: Path, name: str = "black") -> Path:
    out = tmp / f"{name}.mkv"
    run(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", f"color=c=black:s={W}x{H}:r={FPS}",
         "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", f"{seconds:.3f}",
         "-c:v", "libx264", "-preset", "fast", "-crf", "12", "-c:a", "pcm_s16le", str(out)])
    return out


def assemble(clips: list[tuple[Path, float, float]], beds: list[dict], tmp: Path,
             music: dict | None = None, gain: float = 1.0) -> Path:
    """Enchaîne les plans : fondu enchaîné (xfade / acrossfade) quand le plan en a un, sinon coupe
    franche ; `clips` = (fichier, durée, xfade avec le précédent). `music` : un seul morceau du jeu
    sous toute la bande-annonce ({ "track", "start", "gain", "fade_in", "fade_out" }), comme une
    nappe qui court du début à la fin."""
    inputs: list[str] = []
    for path, _d, _x in clips:
        inputs += ["-i", str(path)]
    bed_offset = len(clips)
    for bed in beds:
        inputs += ["-ss", f"{float(bed['in']):.3f}", "-t", f"{float(bed['dur']):.3f}",
                   "-i", str(RAW / f"{bed['src']}.avi")]
    total_duration = sum(d for _p, d, _x in clips) - sum(max(x, 0.0) for _p, _d, x in clips[1:])
    if music:
        beds = list(beds) + [{"_music": True, "in": float(music.get("start", 0.0)),
                              "dur": float(music.get("end_at", total_duration)), "at": 0.0,
                              "gain": float(music.get("gain", 0.8)),
                              "fade_in": float(music.get("fade_in", 0.5)),
                              "fade_out": float(music.get("fade_out", 1.5))}]
        inputs += ["-stream_loop", "-1", "-ss", f"{float(music.get('start', 0.0)):.3f}",
                   "-t", f"{float(music.get('end_at', total_duration)):.3f}",
                   "-i", str(music_path(music["track"]))]
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
    filters.append(f"{a_prev}volume={gain},alimiter=limit=0.95[aout]")
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
    global RAW, MASTER, SHARE
    parser = argparse.ArgumentParser()
    parser.add_argument("--only-master", action="store_true", help="pas de Theora ni de données")
    parser.add_argument("--width", type=int, default=1920, help="largeur de la vidéo du jeu [D] (v2.1 : plus nette)")
    parser.add_argument("--quality", type=int, default=4, help="qualité Theora (0 à 10) [D] : 4 ≈ 24 Mo à 1920 × 886 (5 : 34 Mo, sans différence visible)")
    parser.add_argument("--from-master", action="store_true",
                        help="ne refait que la vidéo du jeu (Theora + données) depuis le master")
    parser.add_argument("--cuts", type=Path, default=CUTS, help="fichier de montage")
    parser.add_argument("--tag", default="", help="version à part : jamais de vidéo du jeu")
    parser.add_argument("--game", action="store_true",
                        help="avec --tag : vidéo du jeu, sans le logo de fin (les lettres de l'ident prennent sa place)")
    parser.add_argument("--raw", default="", help="dossier des scènes (défaut : raw_<tag>)")
    args = parser.parse_args()
    if args.tag:
        args.only_master = not args.game
        RAW = OUT / (args.raw or f"raw_{args.tag}")
        MASTER = OUT / f"pokemake-trailer-{args.tag}.mp4"
        SHARE = OUT / f"pokemake-trailer-{args.tag}-720p.mp4"
        if args.game:
            MASTER = OUT / f"pokemake-trailer-{args.tag}-jeu.mp4"
            SHARE = OUT / f"pokemake-trailer-{args.tag}-jeu-720p.mp4"
    spec = json.loads(args.cuts.read_text())
    cuts = [c for c in spec["cuts"] if not (args.game and "logo" in c)]
    OUT.mkdir(parents=True, exist_ok=True)
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
        titles: list[dict] = []
        default_audio = float(spec.get("default_audio", 1.0))
        for i, cut in enumerate(cuts):
            if "card" in cut:
                print(f"[{i + 1}/{len(cuts)}] carton « {cut['card']} » ({cut['dur']} s)")
                clips.append((card_clip(i, cut["card"], float(cut["dur"]), tmp,
                                        float(spec.get("card_fade", CARD_FADE))), float(cut["dur"]),
                              float(cut.get("xfade", 0.0))))
                continue
            if "title" in cut:
                # Chaque raccord recouvre au moins une image (voir `assemble`).
                at = sum(d for _p, d, _x in clips) - sum(max(x, 1.0 / FPS) for _p, _d, x in clips[1:]) \
                    - (1.0 / FPS if clips else 0.0)
                titles.append({"dur": float(cut.get("dur", cut.get("black", 1.0))), **cut["title"], "at": at})
            if "logo" in cut:
                clips.append((logo_clip(i, cut, tmp), float(cut["dur"]), 0.0))
                continue
            if "split" in cut:
                clips.append((split_clip(i, cut, tmp), float(cut["dur"]), 0.0))
                continue
            if "black" in cut:
                clips.append((black_clip(float(cut["black"]), tmp, f"black_{i:02d}"),
                              float(cut["black"]), 0.0))
                continue
            cut.setdefault("audio", default_audio)
            print(f"[{i + 1}/{len(cuts)}] {cut['id']} ({cut['src']} @ {cut['in']} s, {cut['dur']} s)")
            clips.append((render_cut(i, cut, tmp), float(cut["dur"]), float(cut.get("xfade", 0.0))))
        tail = float(spec.get("tail_black", 0.0))
        if tail > 0:
            clips.append((black_clip(tail, tmp), tail, 0.0))
        assembled = assemble(clips, spec.get("beds", []), tmp, spec.get("music"),
                             float(spec.get("gain", 1.0)))
        assembled = apply_titles(assembled, titles, tmp)
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
