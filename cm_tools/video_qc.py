#!/usr/bin/env python3
"""CM preflight for footage. Flags possible black/frozen frames and makes contact sheets.
THIS CANNOT DETECT BAD ANIMATION, WRONG COMBAT, ROBLOX ERRORS OR ART DIRECTION.
Always review full-speed footage with a human and verify actual gameplay in Studio.
Usage: python cm_tools/video_qc.py /path/to/clip.mp4
Requires installed ffmpeg + ffprobe; stdlib otherwise.
"""
import json, math, pathlib, re, subprocess, sys

def run(args):
    return subprocess.run(args, capture_output=True, text=True, check=False)

def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python cm_tools/video_qc.py CLIP.mp4")
    src = pathlib.Path(sys.argv[1]).resolve()
    if not src.is_file():
        raise SystemExit(f"Missing video: {src}")
    probe = run(["ffprobe", "-v", "error", "-show_format", "-show_streams",
                 "-of", "json", str(src)])
    if probe.returncode:
        raise SystemExit("ffprobe failed: " + probe.stderr[-500:])
    meta = json.loads(probe.stdout)
    video = next((s for s in meta.get("streams", []) if s.get("codec_type") == "video"), {})
    audio = next((s for s in meta.get("streams", []) if s.get("codec_type") == "audio"), None)
    seconds = float(meta.get("format", {}).get("duration") or 0)
    folder = src.parent / (src.stem + "_qc")
    folder.mkdir(exist_ok=True)
    # 20 thumbnails/sheet, one per second. At most ceil(duration/20) sheets.
    sheets = max(1, math.ceil(seconds / 20))
    contact = run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i",
                   str(src), "-vf", "fps=1,scale=240:-2,tile=5x4",
                   "-frames:v", str(sheets), str(folder / "sheet_%02d.jpg")])
    black = run(["ffmpeg", "-hide_banner", "-loglevel", "info", "-i", str(src),
                 "-vf", "blackdetect=d=0.08:pix_th=0.03",
                 "-an", "-f", "null", "-"])
    freeze = run(["ffmpeg", "-hide_banner", "-loglevel", "info", "-i", str(src),
                  "-vf", "freezedetect=n=-55dB:d=0.18",
                  "-an", "-f", "null", "-"])
    blacks = [line.strip() for line in black.stderr.splitlines() if "black_start:" in line]
    freezes = [line.strip() for line in freeze.stderr.splitlines()
               if "freeze_start:" in line or "freeze_end:" in line]
    report = {
        "file": str(src), "duration_s": seconds,
        "width": video.get("width"), "height": video.get("height"),
        "frame_rate": video.get("avg_frame_rate"),
        "codec": video.get("codec_name"), "audio_present": bool(audio),
        "black_candidates": blacks, "freeze_candidates": freezes,
        "contact_sheet_ok": contact.returncode == 0,
        "status": "HUMAN_VISUAL_REVIEW_REQUIRED",
        "limitations": "No automated check of limb animation, Roblox physics, spells, camera clipping or truthful match actions."
    }
    (folder / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print("QC assets:", folder)
    if contact.returncode:
        print("Contact sheet error:", contact.stderr[-500:])
    if not seconds or not video or contact.returncode:
        sys.exit(2)

if __name__ == "__main__":
    main()
