"""Voice for the devlog host (Piper neural TTS, offline, English).

    python3 tts.py script.json outdir [voice.onnx]

script.json = {"title": "...", "lines": [{"say": "...", "show": "robot" | "broll:a.mp4|b.mp4", "g": "point"|"open"}]}
Writes outdir/voice.wav, voice.json (line + estimated word times) and env.json
(20 values a second, 0..1, for the robot's visor in Studio). Runs where Piper
and its voice model are installed (the cloud workspace).
"""
import json, os, subprocess, sys, wave, re
import numpy as np

GAP = 0.22  # silence between lines (s)


def synth(text, model, out):
    subprocess.run([sys.executable, "-m", "piper", "-m", model, "-f", out], input=text.encode(), check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    with wave.open(out) as w:
        sr = w.getframerate(); a = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
    return a, sr


def words_timing(text, a0, a1):
    """Spread the line's duration over its words by length (punctuation adds a pause)."""
    toks = text.split()
    weights = [len(re.sub(r"[^\w']", "", t)) + 2 + (3 if re.search(r"[,.!?;:]$", t) else 0) for t in toks]
    tot = sum(weights); t = a0; out = []
    lead, tail = 0.08, 0.12
    span = max(0.1, (a1 - a0) - lead - tail); t = a0 + lead
    for tok, wgt in zip(toks, weights):
        d = span * wgt / tot
        out.append({"w": re.sub(r"[^\w'?!.,-]", "", tok), "a": round(t, 3), "b": round(t + d, 3)}); t += d
    return out


def main(script, outdir, model=None):
    model = model or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "..", "tts", "ryan", "en-us-ryan-high.onnx")
    model = os.environ.get("NDF_VOICE", model)
    sc = json.load(open(script)); os.makedirs(outdir, exist_ok=True)
    parts, lines, t, sr = [], [], 0.0, 22050
    for i, L in enumerate(sc["lines"]):
        a, sr = synth(L["say"], model, os.path.join(outdir, f"_line{i}.wav"))
        # trim silence at both ends
        nz = np.nonzero(np.abs(a) > 0.01)[0]
        a = a[max(0, nz[0] - int(0.03 * sr)): nz[-1] + int(0.06 * sr)] if len(nz) else a
        d = len(a) / sr
        lines.append({"say": L["say"], "show": L.get("show", "robot"), "g": L.get("g"), "start": round(t, 3), "end": round(t + d, 3),
                      "words": words_timing(L["say"], t, t + d)})
        parts += [a, np.zeros(int(GAP * sr), np.float32)]; t += d + GAP
        os.remove(os.path.join(outdir, f"_line{i}.wav"))
    v = np.concatenate(parts)
    raw = os.path.join(outdir, "_voice_raw.wav")
    with wave.open(raw, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes((np.clip(v, -1, 1) * 32767).astype(np.int16).tobytes())
    # a light "robot" colour: a short metallic comb + presence, still very clear
    fx = sc.get("fx", "aecho=0.8:0.5:7:0.35,highpass=f=110,equalizer=f=3000:t=q:w=1:g=3,acompressor=threshold=-18dB:ratio=3,loudnorm=I=-16:TP=-1.5")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", raw, "-af", fx, "-ar", "48000", "-ac", "2", os.path.join(outdir, "voice.wav")], check=True)
    os.remove(raw)
    # envelope for the visor
    hop = sr // 20
    env = [float(np.sqrt(np.mean(v[i:i + hop] ** 2))) for i in range(0, len(v), hop)]
    m = max(env) or 1; env = [round(min(1, e / (0.6 * m)), 3) for e in env]
    cues = [{"t": l["start"], "g": l["g"]} for l in lines if l.get("g")]
    json.dump({"file": "voice.wav", "dur": round(t, 3), "lines": lines, "title": sc.get("title")}, open(os.path.join(outdir, "voice.json"), "w"), indent=1)
    json.dump({"env": env, "rate": 20, "cues": cues}, open(os.path.join(outdir, "env.json"), "w"))
    print(json.dumps({"dur": round(t, 2), "lines": len(lines), "env": len(env)}))


if __name__ == "__main__":
    main(*sys.argv[1:])
